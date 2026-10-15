      ******************************************************************
      * COPYBOOK: RATNGREC.CPY                                         *
      * PROJECT : ENTERPRISE MAINFRAME HRMS                            *
      * PURPOSE : LAYOUT FOR PERFORMANCE RATINGS FEED (VSAM / FLAT)    *
      * RECORD LENGTH: 6 BYTES                                         *
      * KEY     : IN-EMP-ID (5 BYTES, OFFSET 0)                        *
      ******************************************************************
       01  VSAM-RATING-REC.
           05  IN-EMP-ID               PIC X(5).
           05  IN-RATING               PIC 9(1).
      ******************************************************************
      * END OF RATNGREC.CPY                                            *
      ******************************************************************
