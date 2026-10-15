//COMPDB2  JOB (ACCT),'COMPILE BATCH DB2',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: COMPDB2.jcl                                                   *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: COMPILE, LINK-EDIT & BIND BATCH DB2 COBOL (PAYROLLB)     *
//* STAGES  : 1. COBOL COMPILATION WITH INTEGRATED DB2 SQL COPROCESSOR *
//*           2. PROGRAM BINDER (LINK-EDIT WITH DB2 INTERFACE DSNELI)  *
//*           3. DB2 BIND PACKAGE & BIND PLAN VIA IKJEFT01             *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Set 'IGY.SIGYCOMP' to your Enterprise COBOL compiler library.   *
//* 3. Set 'DSN.SDSNLOAD' to your DB2 subsystem load library.          *
//* 4. Set 'CEE.SCEELKED' to your Language Environment library.        *
//* 5. To compile HIKECALC instead, change MEM=PAYROLLB to HIKECALC.   *
//* 6. Expected Return Code: RC <= 0004 for all steps.                 *
//*====================================================================*
//   SET MEM=PAYROLLB
//   SET DB2SYS=DSN1
//   SET PLAN=HRMSPLAN
//   SET COLL=HRMSCOLL
//*--------------------------------------------------------------------*
//* STEP 1: COMPILE COBOL WITH INTEGRATED DB2 SQL COPROCESSOR          *
//*--------------------------------------------------------------------*
//COBDB2   EXEC PGM=IGYCRCTL,
//            PARM='SQL,LIST,MAP,SOURCE,XREF(SHORT),NODYNAM'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DSN.SDSNLOAD,DISP=SHR
//SYSLIB   DD DSN=YOUR.HLQ.COPYLIB,DISP=SHR
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
//* STEP 2: LINK-EDIT LOAD MODULE WITH BATCH DB2 INTERFACE (DSNELI)    *
//*--------------------------------------------------------------------*
//BINDLNK  EXEC PGM=IEWBLINK,
//            PARM='LIST,LET,MAP,XREF',
//            COND=(4,GE,COBDB2)
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DSN.SDSNLOAD,DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD *
  INCLUDE SYSLIB(DSNELI)
  NAME &MEM(R)
/*
//SYSLMOD  DD DSN=YOUR.HLQ.LOADLIB(&MEM),DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//*--------------------------------------------------------------------*
//* STEP 3: DB2 BIND PACKAGE AND PLAN VIA TSO TMP                      *
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
