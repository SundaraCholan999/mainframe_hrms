       IDENTIFICATION DIVISION.
      ******************************************************************
      * PROGRAM : HIKECALC.CBL                                         *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * FUNCTION: ANNUAL PERFORMANCE HIKE & APPRAISAL BATCH PROCESSING *
      * INPUT   : RTNGIN   - RATINGS FEED (VSAM KSDS / SEQUENTIAL)     *
      *           DB2 TABLE- EMP_MASTER (RELATIONAL DB2)               *
      * TARGET  : IBM z/OS BATCH DB2 (EXECUTED VIA IKJEFT01)           *
      ******************************************************************
       PROGRAM-ID. HIKECALC.
       AUTHOR. MAINFRAME EXPERT.
       DATE-WRITTEN. 2026-10-15.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RATINGS-FILE ASSIGN TO RTNGIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RTNG-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  RATINGS-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 6 CHARACTERS.
           COPY RATNGREC.

       WORKING-STORAGE SECTION.
      ******************************************************************
      * FILE STATUS AND CONTROL FLAGS                                  *
      ******************************************************************
       01  WS-RTNG-STATUS              PIC X(2) VALUE SPACES.
       01  WS-EOF-RATINGS              PIC X(1) VALUE 'N'.
           88  END-OF-RATINGS-FILE     VALUE 'Y'.
           88  NOT-END-OF-RATINGS-FILE VALUE 'N'.

      ******************************************************************
      * DB2 SQL COMMUNICATION AREA & HOST VARIABLES                    *
      ******************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE EMPDCL END-EXEC.

      ******************************************************************
      * HIKE ARITHMETIC WORK VARIABLES                                 *
      ******************************************************************
       01  WS-HIKE-VARS.
           05  WS-HIKE-PCT             PIC V99 VALUE 0.
           05  WS-HIKE-PCT-DISP        PIC Z9.
           05  WS-OLD-SALARY           PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-HIKE-AMOUNT          PIC S9(7)V99 COMP-3 VALUE 0.
           05  WS-NEW-SALARY           PIC S9(7)V99 COMP-3 VALUE 0.

      ******************************************************************
      * DISPLAY-EDITED VARIABLES FOR LOGGING                           *
      ******************************************************************
       01  WS-DISP-OLD                 PIC Z,ZZZ,ZZ9.99.
       01  WS-DISP-HIKE                PIC Z,ZZZ,ZZ9.99.
       01  WS-DISP-NEW                 PIC Z,ZZZ,ZZ9.99.

      ******************************************************************
      * AUDIT STATISTICS COUNTERS                                      *
      ******************************************************************
       01  WS-COUNTERS.
           05  WS-RECS-READ            PIC 9(5) VALUE 0.
           05  WS-RECS-UPDATED         PIC 9(5) VALUE 0.
           05  WS-ZERO-HIKES           PIC 9(5) VALUE 0.
           05  WS-NOT-FOUND-COUNT      PIC 9(5) VALUE 0.

      ******************************************************************
      * PROCEDURE DIVISION                                             *
      ******************************************************************
       PROCEDURE DIVISION.
       0000-MAINLINE.
           PERFORM 1000-INITIALIZATION.
           PERFORM 2000-PROCESS-HIKE UNTIL END-OF-RATINGS-FILE.
           PERFORM 3000-TERMINATION.
           STOP RUN.

      *----------------------------------------------------------------*
      * 1000-INITIALIZATION: Open ratings feed, display header         *
      *----------------------------------------------------------------*
       1000-INITIALIZATION.
           DISPLAY '=================================================='.
           DISPLAY 'HIKECALC: STARTING PERFORMANCE HIKE PROCESSING...'.
           DISPLAY '=================================================='.

           OPEN INPUT RATINGS-FILE.
           IF WS-RTNG-STATUS NOT = '00'
               DISPLAY 'FATAL: UNABLE TO OPEN RTNGIN! STATUS='
                       WS-RTNG-STATUS
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

           PERFORM 1500-READ-RATING-RECORD.

      *----------------------------------------------------------------*
      * 1500-READ-RATING-RECORD: Reads a single employee rating entry  *
      *----------------------------------------------------------------*
       1500-READ-RATING-RECORD.
           READ RATINGS-FILE
               AT END
                   SET END-OF-RATINGS-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-RECS-READ
           END-READ.

      *----------------------------------------------------------------*
      * 2000-PROCESS-HIKE: Evaluates rating, calculates hike, updates  *
      *----------------------------------------------------------------*
       2000-PROCESS-HIKE.
           MOVE IN-EMP-ID TO EMP-ID.

      *    Check if active employee exists in DB2
           EXEC SQL
               SELECT CURRENT_SALARY,
                      RATING
               INTO   :BASE-SALARY,
                      :EMP-RATING
               FROM   EMP_MASTER
               WHERE  EMP_ID = :EMP-ID
                 AND  STATUS = 'A'
           END-EXEC.

           EVALUATE SQLCODE
               WHEN 0
                   PERFORM 2200-CALCULATE-AND-UPDATE
               WHEN 100
                   DISPLAY 'WARNING: ACTIVE EMP ' IN-EMP-ID
                           ' NOT FOUND IN DB2. SKIPPING HIKE.'
                   ADD 1 TO WS-NOT-FOUND-COUNT
               WHEN OTHER
                   DISPLAY 'DB2 SQL ERROR ON SELECT FOR EMP ' IN-EMP-ID
                           ' SQLCODE=' SQLCODE
                   MOVE 8 TO RETURN-CODE
           END-EVALUATE.

           PERFORM 1500-READ-RATING-RECORD.

      *----------------------------------------------------------------*
      * 2200-CALCULATE-AND-UPDATE: Applies hike percentage matrix      *
      * Policy:                                                        *
      *   Rating 5: 15% Hike                                           *
      *   Rating 4: 10% Hike                                           *
      *   Rating 3:  5% Hike                                           *
      *   Others  :  0% Hike                                           *
      *----------------------------------------------------------------*
       2200-CALCULATE-AND-UPDATE.
           MOVE BASE-SALARY TO WS-OLD-SALARY.

           EVALUATE IN-RATING
               WHEN 5
                   MOVE .15 TO WS-HIKE-PCT
                   MOVE 15  TO WS-HIKE-PCT-DISP
               WHEN 4
                   MOVE .10 TO WS-HIKE-PCT
                   MOVE 10  TO WS-HIKE-PCT-DISP
               WHEN 3
                   MOVE .05 TO WS-HIKE-PCT
                   MOVE 05  TO WS-HIKE-PCT-DISP
               WHEN OTHER
                   MOVE .00 TO WS-HIKE-PCT
                   MOVE 00  TO WS-HIKE-PCT-DISP
           END-EVALUATE.

           COMPUTE WS-HIKE-AMOUNT ROUNDED =
               WS-OLD-SALARY * WS-HIKE-PCT.
           COMPUTE WS-NEW-SALARY =
               WS-OLD-SALARY + WS-HIKE-AMOUNT.

      *    Assign to DB2 Host Variables
           MOVE WS-NEW-SALARY TO BASE-SALARY.
           MOVE IN-RATING     TO EMP-RATING.

      *    Execute Relational Database Update
           EXEC SQL
               UPDATE EMP_MASTER
               SET    CURRENT_SALARY = :BASE-SALARY,
                      RATING         = :EMP-RATING
               WHERE  EMP_ID         = :EMP-ID
                 AND  STATUS         = 'A'
           END-EXEC.

           IF SQLCODE = 0
               ADD 1 TO WS-RECS-UPDATED
               IF WS-HIKE-PCT = 0
                   ADD 1 TO WS-ZERO-HIKES
               END-IF

               MOVE WS-OLD-SALARY  TO WS-DISP-OLD
               MOVE WS-HIKE-AMOUNT TO WS-DISP-HIKE
               MOVE WS-NEW-SALARY  TO WS-DISP-NEW

               DISPLAY 'EMP ' EMP-ID
                       ' | RATING: ' IN-RATING
                       ' | HIKE: ' WS-HIKE-PCT-DISP '%'
                       ' | OLD: ' WS-DISP-OLD
                       ' | INCR: ' WS-DISP-HIKE
                       ' | NEW: ' WS-DISP-NEW
                       ' [UPDATED]'
           ELSE
               DISPLAY 'ERROR UPDATING DB2 FOR EMP ' EMP-ID
                       ' SQLCODE=' SQLCODE
               MOVE 8 TO RETURN-CODE
           END-IF.

      *----------------------------------------------------------------*
      * 3000-TERMINATION: Commits DB2 transaction & displays summary   *
      *----------------------------------------------------------------*
       3000-TERMINATION.
           CLOSE RATINGS-FILE.

      *    Commit the batch updates to DB2
           EXEC SQL COMMIT END-EXEC.

           DISPLAY '--------------------------------------------------'.
           DISPLAY 'HIKECALC EXECUTION SUMMARY:'.
           DISPLAY '  RATINGS RECORDS READ        : ' WS-RECS-READ.
           DISPLAY '  EMPLOYEES UPDATED IN DB2    : ' WS-RECS-UPDATED.
           DISPLAY '  ZERO-HIKE EMPLOYEES         : ' WS-ZERO-HIKES.
           DISPLAY '  EMPLOYEES NOT FOUND/SKIPPED : '
                   WS-NOT-FOUND-COUNT.
           DISPLAY '--------------------------------------------------'.
           DISPLAY 'HIKECALC COMPLETED SUCCESSFULLY WITH COMMIT.'.
