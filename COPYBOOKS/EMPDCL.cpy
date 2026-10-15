      ******************************************************************
      * COPYBOOK: EMPDCL.CPY                                           *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * PURPOSE : DB2 DCLGEN HOST VARIABLE DECLARATION FOR EMP_MASTER   *
      * NOTE    : MATCHES RELATIONAL TABLE 'EMP_MASTER' IN DB2         *
      *           USED BY CICS (HRMSUI) AND BATCH (PAYROLLB, HIKECALC) *
      ******************************************************************
       01  DCL-EMP-MASTER.
           05  EMP-ID                  PIC X(5).
           05  EMP-NAME                PIC X(30).
           05  EMP-DEPT                PIC X(15).
           05  EMP-DESIG               PIC X(20).
           05  EMP-STATUS              PIC X(1).
           05  JOIN-DATE               PIC X(10).
           05  LWD-DATE                PIC X(10).
           05  BASE-SALARY             PIC S9(7)V99 COMP-3.
           05  EMP-RATING              PIC S9(4) COMP.
           05  BANK-ACCT               PIC X(15).
      ******************************************************************
      * END OF EMPDCL.CPY                                              *
      ******************************************************************
