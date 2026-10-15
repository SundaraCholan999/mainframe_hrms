//LOADVSM  JOB (ACCT),'LOAD HRMS VSAM',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: 02-LOADVSM.jcl                                                *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: STAGE IN-STREAM DATA AND LOAD (REPRO) INTO VSAM KSDS     *
//* UTILITIES: IEBGENER (DATA STAGING) & IDCAMS (REPRO & VERIFY)       *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your High-Level Qualifier.              *
//* 2. Submit this job after '01-DEFVSAM' finishes with MAXCC=0.       *
//* 3. Expected Return Code: MAXCC=0000.                               *
//*====================================================================*
//* STEP 1: STAGE ATTENDANCE SWIPES INTO TEMPORARY FLAT FILE (LRECL=25)*
//*--------------------------------------------------------------------*
//STGATTN  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&TMPATTN,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=25,BLKSIZE=0)
//SYSUT1   DD *
E000120261001090000173000
E000120261002090000174500
E000120261003091500180000
E000120261004090000173000
E000120261005084500173000
E000220261001090000173000
E000220261002090000140000
E000220261003090000173000
E000220261004090000173000
E000220261005090000173000
E000320261001090000173000
E000320261002090000180000
E000320261003090000173000
E000420261001090000173000
E000420261002090000173000
E000520261001083000173000
E000520261002083000173000
E000520261003083000173000
E000520261004083000173000
E000520261005083000173000
/*
//*--------------------------------------------------------------------*
//* STEP 2: REPRO ATTENDANCE DATA INTO ATTEND.KSDS CLUSTER             *
//*--------------------------------------------------------------------*
//LODATTN  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//INDD     DD DSN=&&TMPATTN,DISP=(OLD,DELETE)
//SYSIN    DD *
  REPRO INFILE(INDD) -
        OUTDATASET(YOUR.HLQ.ATTEND.KSDS)
/*
//*--------------------------------------------------------------------*
//* STEP 3: STAGE RATINGS FEED INTO TEMPORARY FLAT FILE (LRECL=6)      *
//*--------------------------------------------------------------------*
//STGRTNG  EXEC PGM=IEBGENER,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT2   DD DSN=&&TMPRTNG,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=6,BLKSIZE=0)
//SYSUT1   DD *
E00014
E00025
E00033
E00042
E00055
/*
//*--------------------------------------------------------------------*
//* STEP 4: REPRO RATINGS DATA INTO RATINGS.KSDS CLUSTER               *
//*--------------------------------------------------------------------*
//LODRTNG  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//INDD     DD DSN=&&TMPRTNG,DISP=(OLD,DELETE)
//SYSIN    DD *
  REPRO INFILE(INDD) -
        OUTDATASET(YOUR.HLQ.RATINGS.KSDS)
/*
//*--------------------------------------------------------------------*
//* STEP 5: VERIFY LOAD BY PRINTING TOP RECORDS TO SYSPRINT            *
//*--------------------------------------------------------------------*
//VRFYALL  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  PRINT INDATASET(YOUR.HLQ.ATTEND.KSDS) COUNT(5) CHAR
  PRINT INDATASET(YOUR.HLQ.RATINGS.KSDS) COUNT(5) CHAR
/*
//
