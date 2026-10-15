//COMPBMS  JOB (ACCT),'COMPILE BMS MAP',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: COMPBMS.jcl                                                   *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: TWO-STAGE COMPILATION OF BMS MAPSET (HRMSMAP.bms)        *
//*   STAGE 1: GENERATE SYMBOLIC DSECT COPYBOOK (HRMSMAP.cpy)          *
//*   STAGE 2: ASSEMBLE & LINK PHYSICAL MAP LOAD MODULE (HRMSSET)      *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Set 'DFH.SDFHMAC' to your site's CICS macro library.            *
//* 3. Stage 1 writes the copybook to YOUR.HLQ.COPYLIB(HRMSMAP).       *
//* 4. Stage 2 writes the physical map load module to YOUR.HLQ.LOADLIB.*
//* 5. Expected Return Code: RC <= 0004.                               *
//*====================================================================*
//* STAGE 1: ASSEMBLE SYMBOLIC DSECT (COPYBOOK GENERATION)             *
//*--------------------------------------------------------------------*
//DSECT    EXEC PGM=ASMA90,
//            PARM='SYSPARM(DSECT),DECK,NOOBJECT'
//SYSLIB   DD DSN=DFH.SDFHMAC,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSPUNCH DD DSN=YOUR.HLQ.COPYLIB(HRMSMAP),DISP=SHR
//SYSIN    DD DSN=YOUR.HLQ.BMS(HRMSMAP),DISP=SHR
//*--------------------------------------------------------------------*
//* STAGE 2: ASSEMBLE & LINK PHYSICAL MAP LOAD MODULE                  *
//*--------------------------------------------------------------------*
//MAPASM   EXEC PGM=ASMA90,
//            PARM='SYSPARM(MAP),OBJECT,NODECK'
//SYSLIB   DD DSN=DFH.SDFHMAC,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSLIN   DD DSN=&&MAPOBJ,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(2,1))
//SYSIN    DD DSN=YOUR.HLQ.BMS(HRMSMAP),DISP=SHR
//*
//MAPLINK  EXEC PGM=IEWL,
//            PARM='LIST,LET,XREF',
//            COND=(4,GE,MAPASM)
//SYSLIN   DD DSN=&&MAPOBJ,DISP=(OLD,DELETE)
//SYSLMOD  DD DSN=YOUR.HLQ.LOADLIB(HRMSSET),DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//
