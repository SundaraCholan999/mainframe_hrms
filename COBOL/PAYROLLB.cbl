       IDENTIFICATION DIVISION.
      ******************************************************************
      * PROGRAM : PAYROLLB.CBL                                         *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * FUNCTION: PAYROLL DISBURSEMENT CALCULATION BATCH ENGINE        *
      * INPUT   : SUMMIN   - ATTENDANCE SUMMARY FILE (QSAM)            *
      *           DB2 TABLE- EMP_MASTER (RELATIONAL DB2)               *
      * OUTPUT  : FINOUT   - DETAILED FINANCE REGISTER REPORT (QSAM)   *
      * TARGET  : IBM z/OS BATCH DB2 (EXECUTED VIA IKJEFT01)           *
      ******************************************************************
       PROGRAM-ID. PAYROLLB.
       AUTHOR. MAINFRAME EXPERT.
       DATE-WRITTEN. 2026-10-15.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SUMM-FILE ASSIGN TO SUMMIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SUMM-STATUS.

           SELECT FIN-FILE ASSIGN TO FINOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FIN-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  SUMM-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 7 CHARACTERS.
           COPY ATTNSUMM.

       FD  FIN-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 135 CHARACTERS.
           COPY FINPAY.

       WORKING-STORAGE SECTION.
      ******************************************************************
      * FILE STATUS TRACKING                                           *
      ******************************************************************
       01  WS-SUMM-STATUS              PIC X(2) VALUE SPACES.
       01  WS-FIN-STATUS               PIC X(2) VALUE SPACES.
       01  WS-EOF-SUMM                 PIC X(1) VALUE 'N'.
           88  END-OF-SUMM-FILE        VALUE 'Y'.
           88  NOT-END-OF-SUMM-FILE    VALUE 'N'.

      ******************************************************************
      * DB2 SQL COMMUNICATION AREA & HOST VARIABLES                    *
      ******************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE EMPDCL END-EXEC.

      ******************************************************************
      * PAYROLL CALCULATION ENGINE WORK VARIABLES                      *
      * Using high-precision packed decimals (COMP-3) for finance      *
      ******************************************************************
       01  WS-CALC-FIELDS.
           05  WS-DAYS-WORKED          PIC 9(2) VALUE 0.
           05  WS-LOP-DAYS             PIC 9(2) VALUE 0.
           05  WS-WORK-RATIO           PIC 9V9(5) VALUE 0.
           05  WS-LOP-RATIO            PIC 9V9(5) VALUE 0.

           05  WS-BASIC-FULL           PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-HRA-FULL             PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-ALLOW-FULL           PIC S9(7)V99 COMP-3 VALUE 0.

           05  WS-BASIC-EARNED-NUM     PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-HRA-EARNED-NUM       PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-ALLOW-EARNED-NUM     PIC S9(7)V99 COMP-3 VALUE 0.

           05  WS-GROSS-PAY-NUM        PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-PF-DEDUCT-NUM        PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-LOP-DEDUCT-NUM       PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-NET-PAY-NUM          PIC S9(7)V99 COMP-3 VALUE 0.

      ******************************************************************
      * GRAND TOTAL ACCUMULATORS FOR REPORT SUMMARY                    *
      ******************************************************************
       01  WS-TOTALS.
           05  WS-RECS-READ            PIC 9(5) VALUE 0.
           05  WS-EMP-PROCESSED        PIC 9(5) VALUE 0.
           05  WS-EMP-NOT-ACTIVE       PIC 9(5) VALUE 0.
           05  WS-TOTAL-GROSS-PAY      PIC S9(9)V99 COMP-3 VALUE 0.
           05  WS-TOTAL-NET-PAY        PIC S9(9)V99 COMP-3 VALUE 0.

      ******************************************************************
      * FORMATTED TOTALS FOR SYSOUT DISPLAY                            *
      ******************************************************************
       01  WS-DISP-GROSS               PIC $,$$$,$$$,$$9.99.
       01  WS-DISP-NET                 PIC $,$$$,$$$,$$9.99.

      ******************************************************************
      * PROCEDURE DIVISION                                             *
      ******************************************************************
       PROCEDURE DIVISION.
       0000-MAINLINE.
           PERFORM 1000-INITIALIZATION.
           PERFORM 2000-PROCESS-PAYROLL UNTIL END-OF-SUMM-FILE.
           PERFORM 3000-TERMINATION.
           STOP RUN.

      *----------------------------------------------------------------*
      * 1000-INITIALIZATION: Open datasets, display job banner         *
      *----------------------------------------------------------------*
       1000-INITIALIZATION.
           DISPLAY '=================================================='.
           DISPLAY 'PAYROLLB: ENTERPRISE PAYROLL CALCULATION STARTED'.
           DISPLAY '=================================================='.

           OPEN INPUT  SUMM-FILE.
           IF WS-SUMM-STATUS NOT = '00'
               DISPLAY 'FATAL: UNABLE TO OPEN SUMMIN! STATUS='
                       WS-SUMM-STATUS
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

           OPEN OUTPUT FIN-FILE.
           IF WS-FIN-STATUS NOT = '00'
               DISPLAY 'FATAL: UNABLE TO OPEN FINOUT! STATUS='
                       WS-FIN-STATUS
               CLOSE SUMM-FILE
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

           PERFORM 1500-READ-SUMMARY.

      *----------------------------------------------------------------*
      * 1500-READ-SUMMARY: Reads single record from attendance summary *
      *----------------------------------------------------------------*
       1500-READ-SUMMARY.
           READ SUMM-FILE
               AT END
                   SET END-OF-SUMM-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-RECS-READ
           END-READ.

      *----------------------------------------------------------------*
      * 2000-PROCESS-PAYROLL: Coordinates DB2 lookup and calculations  *
      *----------------------------------------------------------------*
       2000-PROCESS-PAYROLL.
           MOVE OUT-EMP-ID TO EMP-ID.

      *    Query DB2 for Active Employee record
           EXEC SQL
               SELECT EMP_NAME,
                      BANK_ACCT,
                      CURRENT_SALARY
               INTO   :EMP-NAME,
                      :BANK-ACCT,
                      :BASE-SALARY
               FROM   EMP_MASTER
               WHERE  EMP_ID = :EMP-ID
                 AND  STATUS = 'A'
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 2200-CALCULATE-COMPONENTS
                   PERFORM 2400-FORMAT-AND-WRITE-RECORD
                   ADD 1 TO WS-EMP-PROCESSED
               WHEN 100
                   DISPLAY 'WARNING: ACTIVE EMP NOT FOUND FOR ID: '
                           OUT-EMP-ID ' - SKIPPED FROM PAYROLL.'
                   ADD 1 TO WS-EMP-NOT-ACTIVE
               WHEN OTHER
                   DISPLAY 'DB2 SQL ERROR ON EMP: ' OUT-EMP-ID
                           ' SQLCODE=' SQLCODE
                   MOVE 8 TO RETURN-CODE
           END-EVALUATE.

           PERFORM 1500-READ-SUMMARY.

      *----------------------------------------------------------------*
      * 2200-CALCULATE-COMPONENTS: Executes salary formula logic       *
      * Formula:                                                       *
      *   Working Days capped at 30. LOP Days = 30 - Working Days.     *
      *   Basic = 50% of Base, HRA = 30%, Allowances = 20%.            *
      *   Prorated by (Days Worked / 30).                              *
      *   Deductions: PF = 12% of Basic Earned.                        *
      *----------------------------------------------------------------*
       2200-CALCULATE-COMPONENTS.
           MOVE OUT-TOTAL-DAYS TO WS-DAYS-WORKED.
           IF WS-DAYS-WORKED > 30
               MOVE 30 TO WS-DAYS-WORKED
           END-IF.

           COMPUTE WS-LOP-DAYS = 30 - WS-DAYS-WORKED.

           COMPUTE WS-WORK-RATIO = WS-DAYS-WORKED / 30.0.
           COMPUTE WS-LOP-RATIO  = WS-LOP-DAYS / 30.0.

      *    Full month components before proration
           COMPUTE WS-BASIC-FULL = BASE-SALARY * 0.50.
           COMPUTE WS-HRA-FULL   = BASE-SALARY * 0.30.
           COMPUTE WS-ALLOW-FULL = BASE-SALARY * 0.20.

      *    Prorated earned components based on days worked
           COMPUTE WS-BASIC-EARNED-NUM ROUNDED =
               WS-BASIC-FULL * WS-WORK-RATIO.
           COMPUTE WS-HRA-EARNED-NUM ROUNDED =
               WS-HRA-FULL * WS-WORK-RATIO.
           COMPUTE WS-ALLOW-EARNED-NUM ROUNDED =
               WS-ALLOW-FULL * WS-WORK-RATIO.

      *    Calculate Gross Pay
           COMPUTE WS-GROSS-PAY-NUM =
               WS-BASIC-EARNED-NUM +
               WS-HRA-EARNED-NUM   +
               WS-ALLOW-EARNED-NUM.

      *    Calculate Deductions
      *    PF = 12% of Basic Earned
           COMPUTE WS-PF-DEDUCT-NUM ROUNDED =
               WS-BASIC-EARNED-NUM * 0.12.

      *    Loss of Pay (LOP) deduction representation
           COMPUTE WS-LOP-DEDUCT-NUM ROUNDED =
               BASE-SALARY * WS-LOP-RATIO.

      *    Net Pay Calculation: Gross Pay minus PF deduction
           COMPUTE WS-NET-PAY-NUM =
               WS-GROSS-PAY-NUM - WS-PF-DEDUCT-NUM.

      *    Accumulate grand totals
           ADD WS-GROSS-PAY-NUM TO WS-TOTAL-GROSS-PAY.
           ADD WS-NET-PAY-NUM   TO WS-TOTAL-NET-PAY.

      *----------------------------------------------------------------*
      * 2400-FORMAT-AND-WRITE-RECORD: Builds 135-byte register line    *
      *----------------------------------------------------------------*
       2400-FORMAT-AND-WRITE-RECORD.
           INITIALIZE FINANCE-PAYROLL-REC.

           MOVE EMP-ID               TO PR-EMP-ID.
           MOVE EMP-NAME(1:20)       TO PR-EMP-NAME.
           MOVE BANK-ACCT            TO PR-BANK-ACCT.
           MOVE WS-DAYS-WORKED       TO PR-DAYS-WORKED.
           MOVE " WD"                TO PR-WD-TAG.
           MOVE WS-LOP-DAYS          TO PR-LOP-DAYS.
           MOVE " LP"                TO PR-LOP-TAG.

           MOVE WS-BASIC-EARNED-NUM  TO PR-BASIC-EARNED.
           MOVE WS-HRA-EARNED-NUM    TO PR-HRA-EARNED.
           MOVE WS-ALLOW-EARNED-NUM  TO PR-ALLOW-EARNED.
           MOVE WS-GROSS-PAY-NUM     TO PR-GROSS-PAY.
           MOVE WS-PF-DEDUCT-NUM     TO PR-PF-DEDUCT.
           MOVE WS-LOP-DEDUCT-NUM    TO PR-LOP-DEDUCT.
           MOVE WS-NET-PAY-NUM       TO PR-NET-PAY.

           WRITE FINANCE-PAYROLL-REC.
           IF WS-FIN-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING TO FINOUT! STATUS=' WS-FIN-STATUS
               MOVE 8 TO RETURN-CODE
           END-IF.

      *----------------------------------------------------------------*
      * 3000-TERMINATION: Print audit statistics and close files       *
      *----------------------------------------------------------------*
       3000-TERMINATION.
           CLOSE SUMM-FILE.
           CLOSE FIN-FILE.

           MOVE WS-TOTAL-GROSS-PAY TO WS-DISP-GROSS.
           MOVE WS-TOTAL-NET-PAY   TO WS-DISP-NET.

           DISPLAY '--------------------------------------------------'.
           DISPLAY 'PAYROLLB EXECUTION SUMMARY:'.
           DISPLAY '  ATTENDANCE RECORDS READ     : ' WS-REcs-READ.
           DISPLAY '  ACTIVE EMPLOYEES PROCESSED  : ' WS-EMP-PROCESSED.
           DISPLAY '  INACTIVE/UNMATCHED EMPLOYEES: ' WS-EMP-NOT-ACTIVE.
           DISPLAY '  TOTAL GROSS DISBURSEMENT    : ' WS-DISP-GROSS.
           DISPLAY '  TOTAL NET DISBURSEMENT      : ' WS-DISP-NET.
           DISPLAY '--------------------------------------------------'.
           DISPLAY 'PAYROLLB COMPLETED SUCCESSFULLY.'.
