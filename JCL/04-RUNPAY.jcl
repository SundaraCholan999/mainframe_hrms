//RUNPAY   JOB (ACCT),'RUN PAYROLLB',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: 04-RUNPAY.jcl                                                 *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: EXECUTE PAYROLLB BATCH DB2 CALCULATION VIA IKJEFT01      *
//* INPUT   : SUMMIN - YOUR.HLQ.ATTEND.SUMMARY (LRECL=7)               *
//*           DB2    - SUBSYSTEM DSN1 (TABLE EMP_MASTER)               *
//* OUTPUT  : FINOUT - YOUR.HLQ.PAYROLL.FINANCE (LRECL=135)            *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Set 'DSN.SDSNLOAD' to your site's DB2 Subsystem library name    *
//*    (e.g., DSN910.SDSNLOAD, DSNB10.SDSNLOAD, or SYS1.DB2.SDSNLOAD). *
//* 3. Replace 'DSN1' with your active DB2 Subsystem ID (e.g., DB2P).  *
//* 4. Ensure PLAN 'HRMSPLAN' has been bound (see DOCS/README.md).     *
//* 5. Expected Return Code: RC=0000.                                  *
//*====================================================================*
//* STEP 1: CLEANUP PRIOR FINANCE REGISTER DATASET                     *
//*--------------------------------------------------------------------*
//CLEANUP  EXEC PGM=IEFBR14
//DELDSN   DD DSN=YOUR.HLQ.PAYROLL.FINANCE,
//            DISP=(MOD,DELETE),
//            SPACE=(TRK,(1,1))
//*--------------------------------------------------------------------*
//* STEP 2: EXECUTE DB2 BATCH PROGRAM VIA TSO TMP (IKJEFT01)           *
//*--------------------------------------------------------------------*
//EXECPAY  EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=YOUR.HLQ.LOADLIB,DISP=SHR
//         DD DSN=DSN.SDSNLOAD,DISP=SHR
//SUMMIN   DD DSN=YOUR.HLQ.ATTEND.SUMMARY,DISP=SHR
//FINOUT   DD DSN=YOUR.HLQ.PAYROLL.FINANCE,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,2),RLSE),
//            DCB=(RECFM=FB,LRECL=135,BLKSIZE=0)
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DSN1)
  RUN PROGRAM(PAYROLLB) PLAN(HRMSPLAN) -
      LIBRARY('YOUR.HLQ.LOADLIB')
  END
/*
//
