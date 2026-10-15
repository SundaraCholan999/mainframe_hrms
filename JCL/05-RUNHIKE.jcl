//RUNHIKE  JOB (ACCT),'RUN HIKECALC',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: 05-RUNHIKE.jcl                                                *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: EXECUTE HIKECALC PERFORMANCE HIKE BATCH VIA IKJEFT01     *
//* INPUT   : RTNGIN - YOUR.HLQ.RATINGS.KSDS (VSAM KSDS, LRECL=6)      *
//*           DB2    - SUBSYSTEM DSN1 (UPDATES EMP_MASTER TABLE)       *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Set 'DSN.SDSNLOAD' to your DB2 Subsystem library name.          *
//* 3. Replace 'DSN1' with your active DB2 Subsystem ID.               *
//* 4. Ensure PLAN 'HRMSPLAN' has been bound.                          *
//* 5. Expected Return Code: RC=0000.                                  *
//*====================================================================*
//EXECHIKE EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=YOUR.HLQ.LOADLIB,DISP=SHR
//         DD DSN=DSN.SDSNLOAD,DISP=SHR
//RTNGIN   DD DSN=YOUR.HLQ.RATINGS.KSDS,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DSN1)
  RUN PROGRAM(HIKECALC) PLAN(HRMSPLAN) -
      LIBRARY('YOUR.HLQ.LOADLIB')
  END
/*
//
