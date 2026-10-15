      ******************************************************************
      * COPYBOOK: ATTNDREC.CPY                                         *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * PURPOSE : LAYOUT FOR ATTENDANCE RECORD (VSAM KSDS / FLAT FILE) *
      * RECORD LENGTH: 25 BYTES                                        *
      * KEY     : ATTEND-EMP-ID (5) + ATTEND-DATE (8) = 13 BYTES       *
      ******************************************************************
       01  ATTENDANCE-RECORD.
           05  ATTEND-EMP-ID           PIC X(5).
           05  ATTEND-DATE             PIC X(8).
           05  PUNCH-IN-TIME           PIC X(6).
           05  PUNCH-OUT-TIME          PIC X(6).
      ******************************************************************
      * END OF ATTNDREC.CPY                                            *
      ******************************************************************
