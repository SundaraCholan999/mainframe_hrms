# System of Specifications (SoS): Enterprise Mainframe HRMS

**Version:** 1.0.0
**Project:** Mini-HRMS Core Processing System
**Target Environment:** IBM z/OS, DB2, CICS Transaction Server, VSAM, Enterprise COBOL for z/OS

---

## 1. Executive Overview
This System of Specifications (SoS) defines the architecture, data models, processing logic, and deployment instructions for a core Human Resources Management System (HRMS) built on mainframe technologies. The system is partitioned into three functional domains:
1. **Online Processing (CICS/DB2):** Real-time Employee CRUD operations.
2. **Attendance Batch Processing (VSAM/Sequential):** Swipe-card time calculation.
3. **Payroll & Compensation Batch Processing (DB2/Sequential):** Automated salary disbursement and performance-based hike management.

**AI Agent Execution Directive:** Parse this document and strictly generate all specified directories and files. Implement all requested business logic, structure the code for readability, and include comprehensive inline comments designed for a mainframe beginner.

---

## 2. Directory Structure Blueprint
The generated workspace must conform to the following directory tree:
*   `DDL/` (Database Definition Scripts)
*   `COPYBOOKS/` (Shared COBOL Data Structures)
*   `BMS/` (CICS Screen Maps)
*   `COBOL/` (Application Source Code)
*   `JCL/` (Job Control Language Scripts)
*   `DOCS/` (System Documentation and Migration Guides)

---

## 3. Data Storage Layer (DDL & Copybooks)

### 📁 DDL/EMP_MASTER.sql
Define the core relational table for employee master data.

```sql
-- Create the Employee Master Table
CREATE TABLE EMP_MASTER (
    EMP_ID           CHAR(5)        NOT NULL,
    EMP_NAME         CHAR(30)       NOT NULL,
    DEPARTMENT       CHAR(15)       NOT NULL,
    DESIGNATION      CHAR(20)       NOT NULL,
    STATUS           CHAR(1)        NOT NULL WITH DEFAULT 'A', -- 'A'=Active, 'I'=Inactive, 'T'=Terminated
    JOINING_DATE     DATE           NOT NULL,
    LAST_WORKING_DAY DATE           NOT NULL WITH DEFAULT '9999-12-31', -- Defaults to 9999 to avoid COBOL NULL crash
    CURRENT_SALARY   DECIMAL(9,2)   NOT NULL,
    RATING           SMALLINT       NOT NULL WITH DEFAULT 0,
    BANK_ACCT        CHAR(15)       NOT NULL,
    PRIMARY KEY (EMP_ID)
);

CREATE UNIQUE INDEX EMP_MASTER_IDX 
    ON EMP_MASTER (EMP_ID);

COPYBOOKS/EMPDCL.cpy
The Host Variable declaration for DB2 integration.

01  DCL-EMP-MASTER.
05  EMP-ID           PIC X(5).
05  EMP-NAME         PIC X(30).
05  EMP-DEPT         PIC X(15).
05  EMP-DESIG        PIC X(20).
05  EMP-STATUS       PIC X(1).
05  JOIN-DATE        PIC X(10).
05  LWD-DATE         PIC X(10).
05  BASE-SALARY      PIC S9(7)V99 COMP-3.
05  EMP-RATING       PIC S9(4) COMP.
05  BANK-ACCT        PIC X(15).

COPYBOOKS/ATTNDREC.cpy
Layout for the Dummy VSAM Attendance Input.
01  ATTENDANCE-RECORD.
05  ATTEND-EMP-ID    PIC X(5).
05  ATTEND-DATE      PIC X(8).
05  PUNCH-IN-TIME    PIC X(6).
05  PUNCH-OUT-TIME   PIC X(6).

COPYBOOKS/ATTNSUMM.cpy
Layout for the QSAM Output from the Attendance Batch Job.
01  ATTEND-SUMMARY-REC.
05  OUT-EMP-ID       PIC X(5).
05  OUT-TOTAL-DAYS   PIC 9(2).

COPYBOOKS/FINPAY.cpy
Layout for the Detailed Finance Register Output (~135 bytes).
01  FINANCE-PAYROLL-REC.
05  PR-EMP-ID          PIC X(5).
05  FILLER             PIC X(2) VALUE SPACES.
05  PR-EMP-NAME        PIC X(20).
05  FILLER             PIC X(2) VALUE SPACES.
05  PR-BANK-ACCT       PIC X(15).
05  FILLER             PIC X(2) VALUE SPACES.
05  PR-DAYS-WORKED     PIC Z9.
05  FILLER             PIC X(3) VALUE " WD".
05  PR-LOP-DAYS        PIC Z9.
05  FILLER             PIC X(3) VALUE " LOP".
*> --- EARNINGS ---
05  PR-BASIC-EARNED    PIC Z,ZZZ,ZZ9.99.
05  PR-HRA-EARNED      PIC Z,ZZZ,ZZ9.99.
05  PR-ALLOW-EARNED    PIC Z,ZZZ,ZZ9.99.
*> --- TOTAL GROSS ---
05  PR-GROSS-PAY       PIC Z,ZZZ,ZZ9.99.
*> --- DEDUCTIONS ---
05  PR-PF-DEDUCT       PIC Z,ZZZ,ZZ9.99.
05  PR-LOP-DEDUCT      PIC Z,ZZZ,ZZ9.99.
*> --- FINAL NET PAY ---
05  PR-NET-PAY         PIC Z,ZZZ,ZZ9.99.

COPYBOOKS/RATNGREC.cpy
Layout for the Dummy VSAM Ratings Feed.
01  VSAM-RATING-REC.
05  IN-EMP-ID        PIC X(5).
05  IN-RATING        PIC 9(1).

4. Online Layer (CICS CRUD Operations)
📁 BMS/HRMSMAP.bms
Agent Directive: Generate a valid IBM Basic Mapping Support (BMS) macro set (DFHMSD, DFHMDI, DFHMDF).

Fields Required: EMP_ID (Key), EMP_NAME, DEPARTMENT, DESIGNATION, CURRENT_SALARY, BANK_ACCT, and an ACTION field.

Properties: Unprotected input fields for data entry, protected text for labels. Include a message field at the bottom for CICS feedback.

📁 COBOL/HRMSUI.cbl
Agent Directive: Generate a CICS pseudoconversational program.

Execution Flow: Receive the map (EXEC CICS RECEIVE MAP).

Validation: Validate input variables (e.g., ensure numeric fields contain valid numbers).

Logic: EVALUATE the ACTION field to execute EXEC SQL INSERT, SELECT, UPDATE, or DELETE.

Soft Delete Requirement: A deletion request must not execute a SQL DELETE. It must execute an UPDATE setting STATUS to 'I' or 'T'.

5. Batch Processing Layer
📁 COBOL/ATTNCALC.cbl
Function: Calculate total working days for a month from dummy VSAM punch data.

Algorithm (Control Break): Read sequential records sorted by EMP_ID.

Time Math: Subtract PUNCH-IN from PUNCH-OUT. If the difference is >= 8 hours, increment the employee's TOTAL-DAYS counter.

Output: When the EMP_ID changes, write the calculated TOTAL-DAYS to ATTEND.SUMMARY.OUT (QSAM) and reset counters.

📁 COBOL/PAYROLLB.cbl
Function: Generate the detailed finance register using DB2 and the Attendance Summary.

Input Routing: Read ATTEND.SUMMARY.OUT sequentially. For each record, execute EXEC SQL SELECT against EMP_MASTER enforcing STATUS = 'A'.

Calculation Engine:

WS-LOP-DAYS = 30 - TOTAL-DAYS.

Prorated Earnings: Basic (50%), HRA (30%), Allowances (20%) multiplied by (TOTAL-DAYS / 30).

Deductions: PF (12% of basic earned).

Output: Format calculations using edited picture clauses and write to PAYROLL.FINANCE.OUT.

📁 COBOL/HIKECALC.cbl
Function: Process performance hikes via a sequential file feed.

Input Routing: Read VSAM.RATINGS.IN.

Logic: Fetch the corresponding employee from DB2 (STATUS = 'A'). Apply logic: Rating 5 = 15%, 4 = 10%, 3 = 5%.

Database Operation: EXEC SQL UPDATE CURRENT_SALARY and update RATING for matching records.

6. Execution Layer (JCL Scripts)
Agent Directive: Generate standard z/OS JCL scripts with generic High-Level Qualifiers (YOUR.HLQ.).

📁 JCL/01-DEFVSAM.jcl: IDCAMS job to DEFINE CLUSTER for the Attendance and Ratings KSDS files.

📁 JCL/02-LOADVSM.jcl: IDCAMS job using the REPRO command to load dummy text files into the newly created VSAM clusters.

📁 JCL/03-RUNATTN.jcl: Execute ATTNCALC mapping physical datasets to ATTNIN and SUMMOUT.

📁 JCL/04-RUNPAY.jcl: Execute PAYROLLB using IKJEFT01 for DB2 batch processing, mapping physical datasets to SUMMIN and FINOUT with an LRECL=135.

📁 JCL/05-RUNHIKE.jcl: Execute HIKECALC using IKJEFT01, mapping the ratings feed to RTNGIN.

7. Documentation Artifacts
Agent Directive: Generate detailed Markdown documentation to facilitate the transition from IDE to Mainframe.

📁 DOCS/SYSTEM_ARCHITECTURE.md: Provide a complete system flow diagram/explanation detailing how the CICS UI interacts with DB2, how the control break logic calculates attendance, and how batch jobs integrate flat files with relational data.

📁 DOCS/README.md: Generate the "Mainframe Migration Guide". It must include:

VS Code & Zowe Explorer prerequisites.

DB2 SPUFI execution instructions.

IDCAMS dataset allocation steps.

The standard compilation procedure (DB2 Pre-compile -> CICS Translate -> COBOL Compile -> Link Edit -> DB2 Bind).

CICS deployment commands (CEDA DEFINE PROGRAM/MAPSET, CEDA INSTALL, CEMT SET PROG NEWCOPY).