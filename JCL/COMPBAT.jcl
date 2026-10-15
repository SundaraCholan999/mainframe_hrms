//COMPBAT  JOB (ACCT),'COMPILE BATCH CBL',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: COMPBAT.jcl                                                   *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: COMPILE & LINK-EDIT STANDARD BATCH COBOL (ATTNCALC)      *
//* COMPILER: IBM ENTERPRISE COBOL FOR z/OS (IGYCRCTL)                 *
//* BINDER  : IBM PROGRAM BINDER / LINK-EDITOR (IEWBLINK)              *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Set 'IGY.SIGYCOMP' to your Enterprise COBOL compiler library.   *
//* 3. Set 'CEE.SCEELKED' to your Language Environment (LE) library.   *
//* 4. Generates executable module: YOUR.HLQ.LOADLIB(ATTNCALC).        *
//* 5. Expected Return Code: RC <= 0004.                               *
//*====================================================================*
//* STEP 1: COMPILE COBOL SOURCE PROGRAM                               *
//*--------------------------------------------------------------------*
//COBOL    EXEC PGM=IGYCRCTL,
//            PARM='LIST,MAP,SOURCE,XREF(SHORT),NODYNAM'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//SYSLIB   DD DSN=YOUR.HLQ.COPYLIB,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT5   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSLIN   DD DSN=&&LOADSET,
//            DISP=(MOD,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(3,3))
//SYSIN    DD DSN=YOUR.HLQ.COBOL(ATTNCALC),DISP=SHR
//*--------------------------------------------------------------------*
//* STEP 2: LINK-EDIT (BIND) INTO EXECUTABLE LOAD MODULE               *
//*--------------------------------------------------------------------*
//BIND     EXEC PGM=IEWBLINK,
//            PARM='LIST,LET,MAP,XREF',
//            COND=(4,GE,COBOL)
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD *
  NAME ATTNCALC(R)
/*
//SYSLMOD  DD DSN=YOUR.HLQ.LOADLIB(ATTNCALC),DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//
