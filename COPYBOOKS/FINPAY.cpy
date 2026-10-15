      ******************************************************************
      * COPYBOOK: FINPAY.CPY                                           *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * PURPOSE : LAYOUT FOR DETAILED FINANCE PAYROLL REGISTER REPORT  *
      * PRODUCED BY: PAYROLLB.CBL                                      *
      * RECORD LENGTH: 135 BYTES (RECFM=FB, LRECL=135)                 *
      ******************************************************************
       01  FINANCE-PAYROLL-REC.
           05  PR-EMP-ID               PIC X(5).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  PR-EMP-NAME             PIC X(20).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  PR-BANK-ACCT            PIC X(15).
           05  FILLER                  PIC X(2) VALUE SPACES.
           05  PR-DAYS-WORKED          PIC Z9.
           05  PR-WD-TAG               PIC X(3) VALUE " WD".
           05  PR-LOP-DAYS             PIC Z9.
           05  PR-LOP-TAG              PIC X(3) VALUE " LP".
      *    --- EARNINGS BREAKDOWN ---
           05  PR-BASIC-EARNED         PIC Z,ZZZ,ZZ9.99.
           05  PR-HRA-EARNED           PIC Z,ZZZ,ZZ9.99.
           05  PR-ALLOW-EARNED         PIC Z,ZZZ,ZZ9.99.
      *    --- TOTAL GROSS PAY ---
           05  PR-GROSS-PAY            PIC Z,ZZZ,ZZ9.99.
      *    --- DEDUCTIONS ---
           05  PR-PF-DEDUCT            PIC Z,ZZZ,ZZ9.99.
           05  PR-LOP-DEDUCT           PIC Z,ZZZ,ZZ9.99.
      *    --- FINAL NET DISBURSEMENT ---
           05  PR-NET-PAY              PIC Z,ZZZ,ZZ9.99.
      ******************************************************************
      * END OF FINPAY.CPY                                              *
      ******************************************************************
