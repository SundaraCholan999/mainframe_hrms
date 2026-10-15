//DEFVSAM  JOB (ACCT),'DEF HRMS VSAM',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*====================================================================*
//* JCL: 01-DEFVSAM.jcl                                                *
//* PROJECT: ENTERPRISE MAINFRAME HRMS                                 *
//* FUNCTION: ALLOCATE VSAM KSDS DATASETS FOR ATTENDANCE & RATINGS     *
//* UTILITY: IDCAMS (ACCESS METHOD SERVICES)                           *
//*====================================================================*
//* INSTRUCTIONS FOR BEGINNERS:                                        *
//* 1. Replace 'YOUR.HLQ' with your personal High-Level Qualifier      *
//*    (e.g., IBMUSER, TSOUSER, or ZWEUSER).                           *
//* 2. Replace 'VOL001' with your DASD volume serial if SMS is not     *
//*    active (or remove VOLUMES parameter if SMS manages storage).    *
//* 3. Expected Return Code: MAXCC=0000.                               *
//*====================================================================*
//CLEANUP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  /* DELETE EXISTING CLUSTERS IF RERUNNING JOB. PURGE ERASES DATA */
  DELETE YOUR.HLQ.ATTEND.KSDS CLUSTER PURGE
  DELETE YOUR.HLQ.RATINGS.KSDS CLUSTER PURGE
  SET MAXCC = 0
/*
//*--------------------------------------------------------------------*
//* DEFINE CLUSTER FOR ATTENDANCE KSDS (KEY: EMP_ID + DATE = 13 BYTES) *
//*--------------------------------------------------------------------*
//DEFATTN  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DEFINE CLUSTER ( -
         NAME(YOUR.HLQ.ATTEND.KSDS) -
         INDEXED -
         RECORDSIZE(25 25) -
         KEYS(13 0) -
         TRACKS(5 2) -
         CISZ(4096) -
         FREESPACE(10 10) -
         SHAREOPTIONS(2 3) -
         REUSE -
         ) -
         DATA (NAME(YOUR.HLQ.ATTEND.KSDS.DATA)) -
         INDEX (NAME(YOUR.HLQ.ATTEND.KSDS.INDEX))
/*
//*--------------------------------------------------------------------*
//* DEFINE CLUSTER FOR RATINGS KSDS (KEY: EMP_ID = 5 BYTES AT OFFSET 0)*
//*--------------------------------------------------------------------*
//DEFRTNG  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DEFINE CLUSTER ( -
         NAME(YOUR.HLQ.RATINGS.KSDS) -
         INDEXED -
         RECORDSIZE(6 6) -
         KEYS(5 0) -
         TRACKS(2 1) -
         CISZ(4096) -
         FREESPACE(10 10) -
         SHAREOPTIONS(2 3) -
         REUSE -
         ) -
         DATA (NAME(YOUR.HLQ.RATINGS.KSDS.DATA)) -
         INDEX (NAME(YOUR.HLQ.RATINGS.KSDS.INDEX))
/*
//
