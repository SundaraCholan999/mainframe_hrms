//RUNATTN  JOB (ACCT),'RUN ATTNCALC',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: 03-RUNATTN.jcl                                                *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: EXECUTES ATTNCALC TO SUMMARIZE MONTHLY ATTENDANCE        *
//* INPUT   : ATTNIN  - YOUR.HLQ.ATTEND.KSDS (VSAM KSDS)               *
//* OUTPUT  : SUMMOUT - YOUR.HLQ.ATTEND.SUMMARY (QSAM FLAT FILE)       *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Ensure ATTNCALC has been compiled into YOUR.HLQ.LOADLIB.        *
//* 3. Ensure 01-DEFVSAM and 02-LOADVSM have executed successfully.    *
//* 4. Expected Return Code: RC=0000.                                  *
//*====================================================================*
//* STEP 1: CLEANUP PRIOR OUTPUT DATASET TO PREVENT NOT CATLGD 2 ERROR *
//*--------------------------------------------------------------------*
//CLEANUP  EXEC PGM=IEFBR14
//DELDSN   DD DSN=YOUR.HLQ.ATTEND.SUMMARY,
//            DISP=(MOD,DELETE),
//            SPACE=(TRK,(1,1))
//*--------------------------------------------------------------------*
//* STEP 2: EXECUTE ATTNCALC PROGRAM                                   *
//*--------------------------------------------------------------------*
//EXECATTC EXEC PGM=ATTNCALC
//STEPLIB  DD DSN=YOUR.HLQ.LOADLIB,DISP=SHR
//ATTNIN   DD DSN=YOUR.HLQ.ATTEND.KSDS,DISP=SHR
//SUMMOUT  DD DSN=YOUR.HLQ.ATTEND.SUMMARY,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(TRK,(2,1),RLSE),
//            DCB=(RECFM=FB,LRECL=7,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//
