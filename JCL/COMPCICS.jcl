//COMPCICS JOB (ACCT),'COMP CICS DB2',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: COMPCICS.jcl                                                  *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: COMPILE, LINK-EDIT & BIND CICS ONLINE DB2 PROGRAM (HRMSUI)*
//* STAGES  : 1. COBOL COMPILER WITH INTEGRATED CICS & DB2 COPROCESSOR *
//*           2. PROGRAM BINDER (LINKS CICS DFHELII & DB2 DSNCLI STUBS)*
//*           3. DB2 BIND PACKAGE & PLAN FOR CICS ATTACHMENT           *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Set 'IGY.SIGYCOMP' to your Enterprise COBOL compiler library.   *
//* 3. Set 'DFH.SDFHLOAD' and 'DFH.SDFHCOB' to your CICS libraries.    *
//* 4. Set 'DSN.SDSNLOAD' to your DB2 subsystem load library.          *
//* 5. Generates load module: YOUR.HLQ.LOADLIB(HRMSUI).                *
//* 6. Expected Return Code: RC <= 0004 for all steps.                 *
//*====================================================================*
//   SET MEM=HRMSUI
//   SET DB2SYS=DSN1
//   SET PLAN=HRMSCICS
//   SET COLL=HRMSCOLL
//*--------------------------------------------------------------------*
//* STEP 1: COMPILE COBOL WITH INTEGRATED CICS & DB2 COPROCESSORS      *
//*--------------------------------------------------------------------*
//COBCICS  EXEC PGM=IGYCRCTL,
//            PARM='CICS,SQL,LIST,MAP,SOURCE,XREF(SHORT),NODYNAM'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DFH.SDFHLOAD,DISP=SHR
//         DD DSN=DSN.SDSNLOAD,DISP=SHR
//SYSLIB   DD DSN=YOUR.HLQ.COPYLIB,DISP=SHR
//         DD DSN=DFH.SDFHCOB,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT5   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//DBRMLIB  DD DSN=YOUR.HLQ.DBRMLIB(&MEM),DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,
//            DISP=(MOD,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(3,3))
//SYSIN    DD DSN=YOUR.HLQ.COBOL(&MEM),DISP=SHR
//*--------------------------------------------------------------------*
//* STEP 2: LINK-EDIT LOAD MODULE WITH CICS & DB2 INTERFACE STUBS      *
//*--------------------------------------------------------------------*
//BINDLNK  EXEC PGM=IEWBLINK,
//            PARM='LIST,LET,MAP,XREF',
//            COND=(4,GE,COBCICS)
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DFH.SDFHLOAD,DISP=SHR
//         DD DSN=DSN.SDSNLOAD,DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD *
  INCLUDE SYSLIB(DFHELII)
  INCLUDE SYSLIB(DSNCLI)
  NAME &MEM(R)
/*
//SYSLMOD  DD DSN=YOUR.HLQ.LOADLIB(&MEM),DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//*--------------------------------------------------------------------*
//* STEP 3: DB2 BIND PACKAGE & PLAN FOR CICS RUNTIME                   *
//*--------------------------------------------------------------------*
//DB2BIND  EXEC PGM=IKJEFT01,COND=(4,GE,BINDLNK)
//STEPLIB  DD DSN=DSN.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=YOUR.HLQ.DBRMLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2SYS)
  BIND PACKAGE(&COLL) MEMBER(&MEM) -
       ACTION(REP) ISOLATION(CS) VALIDATE(BIND)
  BIND PLAN(&PLAN) PKLIST(&COLL.*) -
       ACTION(REP) ISOLATION(CS) VALIDATE(BIND)
  END
/*
//
