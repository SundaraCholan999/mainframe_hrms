       IDENTIFICATION DIVISION.
      ******************************************************************
      * PROGRAM : ATTNCALC.CBL                                         *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * FUNCTION: ATTENDANCE BATCH PROCESSING & WORK-DAY CALCULATION   *
      * INPUT   : ATTNIN  - SEQUENTIAL/VSAM ATTENDANCE SWIPE RECORDS   *
      * OUTPUT  : SUMMOUT - QSAM MONTHLY ATTENDANCE SUMMARY FILE       *
      * TARGET  : IBM z/OS BATCH COBOL                                 *
      ******************************************************************
       PROGRAM-ID. ATTNCALC.
       AUTHOR. MAINFRAME EXPERT.
       DATE-WRITTEN. 2026-10-15.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      ******************************************************************
      * FILE-CONTROL: ASSIGNS LOGICAL COBOL FILES TO JCL DD STATEMENTS *
      ******************************************************************
           SELECT ATTN-FILE ASSIGN TO ATTNIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ATTN-STATUS.

           SELECT SUMM-FILE ASSIGN TO SUMMOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SUMM-STATUS.

       DATA DIVISION.
       FILE SECTION.
      ******************************************************************
      * FD: FILE DESCRIPTIONS FOR INPUT AND OUTPUT                     *
      ******************************************************************
       FD  ATTN-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 25 CHARACTERS.
           COPY ATTNDREC.

       FD  SUMM-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 7 CHARACTERS.
           COPY ATTNSUMM.

       WORKING-STORAGE SECTION.
      ******************************************************************
      * FILE STATUS CODES                                              *
      * '00' = Success, '10' = End of File (EOF)                       *
      ******************************************************************
       01  WS-ATTN-STATUS              PIC X(2) VALUE SPACES.
       01  WS-SUMM-STATUS              PIC X(2) VALUE SPACES.

      ******************************************************************
      * CONTROL BREAK TRACKING VARIABLES                               *
      * A Control Break detects when the sorted key (EMP-ID) changes,  *
      * triggering summary output calculation and counter reset.       *
      ******************************************************************
       01  WS-PREV-EMP-ID              PIC X(5) VALUE SPACES.
       01  WS-EMP-WORK-DAYS            PIC 9(2) VALUE 0.
       01  WS-FIRST-REC-FLAG           PIC X(1) VALUE 'Y'.
           88  IS-FIRST-RECORD         VALUE 'Y'.
           88  NOT-FIRST-RECORD        VALUE 'N'.

       01  WS-EOF-FLAG                 PIC X(1) VALUE 'N'.
           88  END-OF-FILE             VALUE 'Y'.
           88  NOT-END-OF-FILE         VALUE 'N'.

      ******************************************************************
      * TIME ARITHMETIC WORK VARIABLES                                 *
      ******************************************************************
       01  WS-TIME-WORK.
           05  IN-HH                   PIC 9(2) VALUE 0.
           05  IN-MM                   PIC 9(2) VALUE 0.
           05  IN-SS                   PIC 9(2) VALUE 0.
           05  OUT-HH                  PIC 9(2) VALUE 0.
           05  OUT-MM                  PIC 9(2) VALUE 0.
           05  OUT-SS                  PIC 9(2) VALUE 0.
           05  TOTAL-IN-MINS           PIC 9(4) VALUE 0.
           05  TOTAL-OUT-MINS          PIC 9(4) VALUE 0.
           05  ELAPSED-MINS            PIC S9(4) VALUE 0.

      ******************************************************************
      * REPORTING COUNTERS FOR AUDIT LOG                               *
      ******************************************************************
       01  WS-COUNTERS.
           05  WS-TOTAL-RECORDS-READ   PIC 9(5) VALUE 0.
           05  WS-VALID-DAYS-COUNT     PIC 9(5) VALUE 0.
           05  WS-SUMM-RECORDS-WRITTEN PIC 9(5) VALUE 0.

      ******************************************************************
      * PROCEDURE DIVISION                                             *
      ******************************************************************
       PROCEDURE DIVISION.
       0000-MAINLINE.
           PERFORM 1000-INITIALIZATION.
           PERFORM 2000-PROCESS-ATTENDANCE UNTIL END-OF-FILE.
           PERFORM 3000-TERMINATION.
           STOP RUN.

      *----------------------------------------------------------------*
      * 1000-INITIALIZATION: Opens files, validates readiness          *
      *----------------------------------------------------------------*
       1000-INITIALIZATION.
           DISPLAY '=================================================='.
           DISPLAY 'ATTNCALC: STARTING ATTENDANCE BATCH CALCULATION...'.
           DISPLAY '=================================================='.

           OPEN INPUT  ATTN-FILE.
           IF WS-ATTN-STATUS NOT = '00'
               DISPLAY 'FATAL ERROR: UNABLE TO OPEN ATTNIN! STATUS='
                       WS-ATTN-STATUS
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

           OPEN OUTPUT SUMM-FILE.
           IF WS-SUMM-STATUS NOT = '00'
               DISPLAY 'FATAL ERROR: UNABLE TO OPEN SUMMOUT! STATUS='
                       WS-SUMM-STATUS
               CLOSE ATTN-FILE
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

      *    Prime the read pump
           PERFORM 1500-READ-ATTEND-RECORD.

      *----------------------------------------------------------------*
      * 1500-READ-ATTEND-RECORD: Reads a single attendance swipe row   *
      *----------------------------------------------------------------*
       1500-READ-ATTEND-RECORD.
           READ ATTN-FILE
               AT END
                   SET END-OF-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-TOTAL-RECORDS-READ
           END-READ.

      *----------------------------------------------------------------*
      * 2000-PROCESS-ATTENDANCE: Main control break loop               *
      *----------------------------------------------------------------*
       2000-PROCESS-ATTENDANCE.
      *    Check for first record setup
           IF IS-FIRST-RECORD
               MOVE ATTEND-EMP-ID TO WS-PREV-EMP-ID
               MOVE 0             TO WS-EMP-WORK-DAYS
               SET NOT-FIRST-RECORD TO TRUE
           END-IF.

      *    CONTROL BREAK: Did EMP-ID change?
           IF ATTEND-EMP-ID NOT = WS-PREV-EMP-ID
               PERFORM 2500-WRITE-SUMMARY-RECORD
               MOVE ATTEND-EMP-ID TO WS-PREV-EMP-ID
               MOVE 0             TO WS-EMP-WORK-DAYS
           END-IF.

      *    Evaluate shift duration for current swipe
           PERFORM 2200-CALCULATE-TIME-DIFFERENCE.

      *    Read next record
           PERFORM 1500-READ-ATTEND-RECORD.

      *----------------------------------------------------------------*
      * 2200-CALCULATE-TIME-DIFFERENCE:                                *
      * Deconstructs HHMMSS into minutes, calculates elapsed time.     *
      * If elapsed time >= 480 mins (8 hours), employee gets 1 day.    *
      *----------------------------------------------------------------*
       2200-CALCULATE-TIME-DIFFERENCE.
           MOVE PUNCH-IN-TIME(1:2)  TO IN-HH.
           MOVE PUNCH-IN-TIME(3:2)  TO IN-MM.
           MOVE PUNCH-IN-TIME(5:2)  TO IN-SS.

           MOVE PUNCH-OUT-TIME(1:2) TO OUT-HH.
           MOVE PUNCH-OUT-TIME(3:2) TO OUT-MM.
           MOVE PUNCH-OUT-TIME(5:2) TO OUT-SS.

      *    Convert punch in/out to absolute minutes from midnight
           COMPUTE TOTAL-IN-MINS  = (IN-HH * 60) + IN-MM.
           COMPUTE TOTAL-OUT-MINS = (OUT-HH * 60) + OUT-MM.

           IF TOTAL-OUT-MINS >= TOTAL-IN-MINS
               COMPUTE ELAPSED-MINS = TOTAL-OUT-MINS - TOTAL-IN-MINS
           ELSE
      *        Handle midnight wrap-around (e.g. night shifts)
               COMPUTE ELAPSED-MINS = (1440 - TOTAL-IN-MINS)
                                    + TOTAL-OUT-MINS
           END-IF.

      *    Criterion: >= 8 hours (480 minutes) counts as 1 full work day
           IF ELAPSED-MINS >= 480
               ADD 1 TO WS-EMP-WORK-DAYS
               ADD 1 TO WS-VALID-DAYS-COUNT
           END-IF.

      *----------------------------------------------------------------*
      * 2500-WRITE-SUMMARY-RECORD: Emits aggregated days for employee  *
      *----------------------------------------------------------------*
       2500-WRITE-SUMMARY-RECORD.
           MOVE WS-PREV-EMP-ID   TO OUT-EMP-ID.
           MOVE WS-EMP-WORK-DAYS TO OUT-TOTAL-DAYS.

           WRITE ATTEND-SUMMARY-REC.
           IF WS-SUMM-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING SUMM-FILE! STATUS=' WS-SUMM-STATUS
               MOVE 8 TO RETURN-CODE
           ELSE
               ADD 1 TO WS-SUMM-RECORDS-WRITTEN
           END-IF.

      *----------------------------------------------------------------*
      * 3000-TERMINATION: Emits final control break and closes files   *
      *----------------------------------------------------------------*
       3000-TERMINATION.
      *    Emit the very last employee group summary upon hitting EOF
           IF NOT-FIRST-RECORD
               PERFORM 2500-WRITE-SUMMARY-RECORD
           END-IF.

           CLOSE ATTN-FILE.
           CLOSE SUMM-FILE.

           DISPLAY '--------------------------------------------------'.
           DISPLAY 'ATTNCALC EXECUTION SUMMARY:'.
           DISPLAY '  TOTAL SWIPE RECORDS READ    : '
                   WS-TOTAL-RECORDS-READ.
           DISPLAY '  QUALIFYING WORK DAYS (>=8H) : '
                   WS-VALID-DAYS-COUNT.
           DISPLAY '  EMPLOYEE SUMMARIES WRITTEN  : '
                   WS-SUMM-RECORDS-WRITTEN.
           DISPLAY '--------------------------------------------------'.
           DISPLAY 'ATTNCALC COMPLETED SUCCESSFULLY.'
           DISPLAY 'RETURN CODE: 0.'.
           MOVE 0 TO RETURN-CODE.
