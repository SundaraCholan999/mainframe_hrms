       IDENTIFICATION DIVISION.
      ******************************************************************
      * PROGRAM : HRMSUI.CBL                                           *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * FUNCTION: CICS PSEUDOCONVERSATIONAL ONLINE EMPLOYEE CRUD UI    *
      * TARGET  : IBM z/OS CICS TRANSACTION SERVER & IBM DB2           *
      * TRANS ID: HR01                                                 *
      * MAPSET  : HRMSSET  /  MAP: HRMSMAP                             *
      ******************************************************************
       PROGRAM-ID. HRMSUI.
       AUTHOR. MAINFRAME EXPERT.
       DATE-WRITTEN. 2026-10-15.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      ******************************************************************
      * CICS RESPONSE AND CONTROL VARIABLES                            *
      ******************************************************************
       01  WS-CICS-RESP                PIC S9(8) COMP VALUE 0.
       01  WS-CICS-RESP2               PIC S9(8) COMP VALUE 0.

      ******************************************************************
      * SYSTEM CONSTANTS & MESSAGES                                    *
      ******************************************************************
       01  WS-EXIT-MSG.
           05  FILLER                  PIC X(45) VALUE
               'HRMS TRANSACTION TERMINATED. HAVE A NICE DAY!'.
       01  WS-MAP-FAIL-MSG.
           05  FILLER                  PIC X(45) VALUE
               'PLEASE ENTER AN ACTION CODE (S, I, U, D, C, X)'.

      ******************************************************************
      * NUMERIC EDITING & PARSING VARIABLES FOR SALARY                 *
      ******************************************************************
       01  WS-SALARY-NUM               PIC 9(7)V99 VALUE 0.
       01  WS-SALARY-EDIT              PIC Z,ZZZ,ZZ9.99.
       01  WS-SALARY-ALPHA             PIC X(10).
       01  WS-RATING-CHAR              PIC X(1).

      ******************************************************************
      * SQL COMMUNICATION AREA (SQLCA)                                 *
      * Mainframe DB2 automatically reports return codes into SQLCODE: *
      *   000 = Success                                                *
      *  +100 = Row Not Found / End of Result Set                      *
      *  -803 = Duplicate Primary Key violation                        *
      ******************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.

      ******************************************************************
      * DB2 DCLGEN HOST VARIABLES FOR EMP_MASTER TABLE                 *
      ******************************************************************
           EXEC SQL INCLUDE EMPDCL END-EXEC.

      ******************************************************************
      * CICS BMS MAP STRUCTURES & ATTRIBUTES                           *
      ******************************************************************
           COPY HRMSMAP.
           COPY DFHAID.
           COPY DFHBMSCA.

      ******************************************************************
      * COMMUNICATION AREA (COMMAREA) FOR PSEUDOCONVERSATION           *
      * Carries conversation state across successive terminal I/O      *
      ******************************************************************
       01  WS-COMMAREA.
           05  WS-CA-STATUS            PIC X(1) VALUE '0'.
               88  FIRST-TIME-ENTRY    VALUE '0'.
               88  CONTINUATION-CALL   VALUE '1'.
           05  WS-CA-LAST-ACTION       PIC X(1) VALUE SPACES.
           05  WS-CA-LAST-EMPID        PIC X(5) VALUE SPACES.

       LINKAGE SECTION.
      ******************************************************************
      * DFHCOMMAREA is passed automatically by CICS to the program     *
      ******************************************************************
       01  DFHCOMMAREA.
           05  LK-CA-STATUS            PIC X(1).
           05  LK-CA-LAST-ACTION       PIC X(1).
           05  LK-CA-LAST-EMPID        PIC X(5).

      ******************************************************************
      * PROCEDURE DIVISION - APPLICATION LOGIC                         *
      ******************************************************************
       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
      *----------------------------------------------------------------*
      * STEP 1: Determine if this is first execution or continuation.  *
      * If EIBCALEN = 0, user typed 'HR01' on blank terminal.          *
      *----------------------------------------------------------------*
           IF EIBCALEN = 0
               PERFORM 1000-SEND-FRESH-MAP
               PERFORM 9999-RETURN-TO-CICS
           END-IF.

      *----------------------------------------------------------------*
      * STEP 2: Restore Commarea state for active transaction          *
      *----------------------------------------------------------------*
           MOVE DFHCOMMAREA TO WS-COMMAREA.

      *----------------------------------------------------------------*
      * STEP 3: Evaluate Terminal Attention Keys (AID)                 *
      * DFHPF3 / DFHCLEAR / DFHPA1 allows user to abort or exit.       *
      *----------------------------------------------------------------*
           EVALUATE EIBAID
               WHEN DFHPF3
               WHEN DFHPA1
               WHEN DFHCLEAR
                   PERFORM 8000-EXIT-PROGRAM
               WHEN DFHENTER
                   PERFORM 2000-PROCESS-ENTER-KEY
               WHEN OTHER
                   MOVE 'INVALID KEY PRESSED. USE ENTER OR PF3=EXIT'
                       TO MSGO
                   PERFORM 7000-REDISPLAY-MAP
           END-EVALUATE.

           PERFORM 9999-RETURN-TO-CICS.

      *----------------------------------------------------------------*
      * 1000-SEND-FRESH-MAP: Clears screen, displays blank initial map *
      *----------------------------------------------------------------*
       1000-SEND-FRESH-MAP.
           MOVE LOW-VALUES TO HRMSMAPO.
           MOVE 'WELCOME TO HRMS. ENTER ACTION AND EMP ID TO BEGIN.'
               TO MSGO.
           SET FIRST-TIME-ENTRY TO TRUE.

           EXEC CICS SEND
               MAP('HRMSMAP')
               MAPSET('HRMSSET')
               FROM(HRMSMAPO)
               ERASE
               FREEKB
               RESP(WS-CICS-RESP)
           END-EXEC.

      *----------------------------------------------------------------*
      * 2000-PROCESS-ENTER-KEY: Receives user input & routes by ACTION *
      *----------------------------------------------------------------*
       2000-PROCESS-ENTER-KEY.
           MOVE LOW-VALUES TO HRMSMAPI.

           EXEC CICS RECEIVE
               MAP('HRMSMAP')
               MAPSET('HRMSSET')
               INTO(HRMSMAPI)
               RESP(WS-CICS-RESP)
           END-EXEC.

           IF WS-CICS-RESP = DFHRESP(MAPFAIL)
               MOVE LOW-VALUES TO HRMSMAPO
               MOVE WS-MAP-FAIL-MSG TO MSGO
               PERFORM 7000-REDISPLAY-MAP
               EXIT PARAGRAPH
           END-IF.

      *    Convert Action character to uppercase
           MOVE FUNCTION UPPER-CASE(ACTNI) TO ACTNI.

      *    Dispatch business logic based on user Action
           EVALUATE ACTNI
               WHEN 'S'
                   PERFORM 3000-SELECT-EMPLOYEE
               WHEN 'I'
                   PERFORM 4000-INSERT-EMPLOYEE
               WHEN 'U'
                   PERFORM 5000-UPDATE-EMPLOYEE
               WHEN 'D'
                   PERFORM 6000-SOFT-DELETE-EMPLOYEE
               WHEN 'C'
                   PERFORM 1000-SEND-FRESH-MAP
               WHEN 'X'
                   PERFORM 8000-EXIT-PROGRAM
               WHEN OTHER
                   MOVE 'INVALID ACTION! VALID: S=SEL, I=INS, U=UPD, D='
                       & 'DEL, C=CLR, X=EXIT' TO MSGO
                   PERFORM 7000-REDISPLAY-MAP
           END-EVALUATE.

      *----------------------------------------------------------------*
      * 3000-SELECT-EMPLOYEE: Queries DB2 for Employee record          *
      *----------------------------------------------------------------*
       3000-SELECT-EMPLOYEE.
           IF EMPIDI = SPACES OR EMPIDI = LOW-VALUES
               MOVE 'ERROR: PLEASE SPECIFY AN EMPLOYEE ID TO QUERY.'
                   TO MSGO
               PERFORM 7000-REDISPLAY-MAP
               EXIT PARAGRAPH
           END-IF.

           MOVE EMPIDI TO EMP-ID.

           EXEC SQL
               SELECT EMP_NAME,
                      DEPARTMENT,
                      DESIGNATION,
                      STATUS,
                      CURRENT_SALARY,
                      RATING,
                      BANK_ACCT
               INTO   :EMP-NAME,
                      :EMP-DEPT,
                      :EMP-DESIG,
                      :EMP-STATUS,
                      :BASE-SALARY,
                      :EMP-RATING,
                      :BANK-ACCT
               FROM   EMP_MASTER
               WHERE  EMP_ID = :EMP-ID
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   MOVE EMP-ID      TO EMPIDO
                   MOVE EMP-NAME    TO NAMEO
                   MOVE EMP-DEPT    TO DEPTO
                   MOVE EMP-DESIG   TO DESIGO
                   MOVE EMP-STATUS  TO STATUSO
                   MOVE BASE-SALARY TO WS-SALARY-EDIT
                   MOVE WS-SALARY-EDIT TO SALARYO
                   MOVE BANK-ACCT   TO BANKO
                   MOVE EMP-RATING  TO WS-RATING-CHAR
                   MOVE WS-RATING-CHAR TO RATINGO
                   MOVE 'RECORD RETRIEVED SUCCESSFULLY.' TO MSGO
               WHEN 100
                   MOVE SPACES TO NAMEO DEPTO DESIGO SALARYO BANKO
                   MOVE 'EMPLOYEE RECORD NOT FOUND IN DB2.' TO MSGO
               WHEN OTHER
                   STRING 'SQL ERROR ON SELECT! CODE: ' SQLCODE
                       DELIMITED BY SIZE INTO MSGO
           END-EVALUATE.

           PERFORM 7000-REDISPLAY-MAP.

      *----------------------------------------------------------------*
      * 4000-INSERT-EMPLOYEE: Adds a new Employee to DB2 EMP_MASTER    *
      *----------------------------------------------------------------*
       4000-INSERT-EMPLOYEE.
           IF EMPIDI = SPACES OR NAMEI = SPACES OR SALARYI = SPACES
               MOVE 'ERROR: EMP ID, NAME, AND SALARY ARE MANDATORY!'
                   TO MSGO
               PERFORM 7000-REDISPLAY-MAP
               EXIT PARAGRAPH
           END-IF.

      *    Validate numeric salary
           IF SALARYI IS NOT NUMERIC
               MOVE 'ERROR: CURRENT SALARY MUST BE NUMERIC DIGITS.'
                   TO MSGO
               PERFORM 7000-REDISPLAY-MAP
               EXIT PARAGRAPH
           END-IF.

           MOVE EMPIDI  TO EMP-ID.
           MOVE NAMEI   TO EMP-NAME.
           MOVE DEPTI   TO EMP-DEPT.
           MOVE DESIGI  TO EMP-DESIG.
           MOVE BANKI   TO BANK-ACCT.
           MOVE FUNCTION NUMVAL(SALARYI) TO BASE-SALARY.

           EXEC SQL
               INSERT INTO EMP_MASTER (
                   EMP_ID,
                   EMP_NAME,
                   DEPARTMENT,
                   DESIGNATION,
                   STATUS,
                   JOINING_DATE,
                   LAST_WORKING_DAY,
                   CURRENT_SALARY,
                   RATING,
                   BANK_ACCT
               ) VALUES (
                   :EMP-ID,
                   :EMP-NAME,
                   :EMP-DEPT,
                   :EMP-DESIG,
                   'A',
                   CURRENT DATE,
                   '9999-12-31',
                   :BASE-SALARY,
                   0,
                   :BANK-ACCT
               )
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   MOVE 'EMPLOYEE INSERTED SUCCESSFULLY (STATUS=A).'
                       TO MSGO
               WHEN -803
                   MOVE 'ERROR: EMP ID ALREADY EXISTS (DUPLICATE KEY)!'
                       TO MSGO
               WHEN OTHER
                   STRING 'SQL ERROR ON INSERT! CODE: ' SQLCODE
                       DELIMITED BY SIZE INTO MSGO
           END-EVALUATE.

           PERFORM 7000-REDISPLAY-MAP.

      *----------------------------------------------------------------*
      * 5000-UPDATE-EMPLOYEE: Updates active Employee record in DB2    *
      *----------------------------------------------------------------*
       5000-UPDATE-EMPLOYEE.
           IF EMPIDI = SPACES
               MOVE 'ERROR: ENTER EMPLOYEE ID TO UPDATE.' TO MSGO
               PERFORM 7000-REDISPLAY-MAP
               EXIT PARAGRAPH
           END-IF.

           MOVE EMPIDI  TO EMP-ID.
           MOVE NAMEI   TO EMP-NAME.
           MOVE DEPTI   TO EMP-DEPT.
           MOVE DESIGI  TO EMP-DESIG.
           MOVE BANKI   TO BANK-ACCT.

           IF SALARYI IS NUMERIC
               MOVE FUNCTION NUMVAL(SALARYI) TO BASE-SALARY
           END-IF.

           EXEC SQL
               UPDATE EMP_MASTER
               SET    EMP_NAME       = :EMP-NAME,
                      DEPARTMENT     = :EMP-DEPT,
                      DESIGNATION    = :EMP-DESIG,
                      CURRENT_SALARY = :BASE-SALARY,
                      BANK_ACCT      = :BANK-ACCT
               WHERE  EMP_ID         = :EMP-ID
                 AND  STATUS         = 'A'
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   MOVE 'EMPLOYEE RECORD UPDATED SUCCESSFULLY.' TO MSGO
               WHEN 100
                   MOVE 'UPDATE FAILED: ACTIVE EMPLOYEE RECORD NOT FOUN'
                       & 'D.' TO MSGO
               WHEN OTHER
                   STRING 'SQL ERROR ON UPDATE! CODE: ' SQLCODE
                       DELIMITED BY SIZE INTO MSGO
           END-EVALUATE.

           PERFORM 7000-REDISPLAY-MAP.

      *----------------------------------------------------------------*
      * 6000-SOFT-DELETE-EMPLOYEE: Executes audit-safe Soft Delete     *
      * Sets STATUS='I' (Inactive) and LAST_WORKING_DAY=CURRENT DATE   *
      * Never executes raw SQL DELETE, ensuring audit integrity.       *
      *----------------------------------------------------------------*
       6000-SOFT-DELETE-EMPLOYEE.
           IF EMPIDI = SPACES
               MOVE 'ERROR: ENTER EMPLOYEE ID TO DELETE.' TO MSGO
               PERFORM 7000-REDISPLAY-MAP
               EXIT PARAGRAPH
           END-IF.

           MOVE EMPIDI TO EMP-ID.

           EXEC SQL
               UPDATE EMP_MASTER
               SET    STATUS           = 'I',
                      LAST_WORKING_DAY = CURRENT DATE
               WHERE  EMP_ID           = :EMP-ID
                 AND  STATUS           = 'A'
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   MOVE 'EMPLOYEE SOFT-DELETED (STATUS CHANGED TO I).'
                       TO MSGO
                   MOVE 'I' TO STATUSO
               WHEN 100
                   MOVE 'DELETE FAILED: ACTIVE EMPLOYEE RECORD NOT FOUN'
                       & 'D.' TO MSGO
               WHEN OTHER
                   STRING 'SQL ERROR ON SOFT-DELETE! CODE: ' SQLCODE
                       DELIMITED BY SIZE INTO MSGO
           END-EVALUATE.

           PERFORM 7000-REDISPLAY-MAP.

      *----------------------------------------------------------------*
      * 7000-REDISPLAY-MAP: Sends map data back to user terminal       *
      *----------------------------------------------------------------*
       7000-REDISPLAY-MAP.
           EXEC CICS SEND
               MAP('HRMSMAP')
               MAPSET('HRMSSET')
               FROM(HRMSMAPO)
               DATAONLY
               CURSOR
               FREEKB
               RESP(WS-CICS-RESP)
           END-EXEC.

      *----------------------------------------------------------------*
      * 8000-EXIT-PROGRAM: Terminates CICS session gracefully          *
      *----------------------------------------------------------------*
       8000-EXIT-PROGRAM.
           EXEC CICS SEND TEXT
               FROM(WS-EXIT-MSG)
               LENGTH(LENGTH OF WS-EXIT-MSG)
               ERASE
               FREEKB
           END-EXEC.

           EXEC CICS RETURN END-EXEC.

      *----------------------------------------------------------------*
      * 9999-RETURN-TO-CICS: Transfers control back to CICS with TRANSID*
      * This maintains the pseudoconversational state.                 *
      *----------------------------------------------------------------*
       9999-RETURN-TO-CICS.
           SET CONTINUATION-CALL TO TRUE.
           MOVE ACTNI  TO WS-CA-LAST-ACTION.
           MOVE EMPIDI TO WS-CA-LAST-EMPID.

           EXEC CICS RETURN
               TRANSID('HR01')
               COMMAREA(WS-COMMAREA)
               LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.
