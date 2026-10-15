-- ==============================================================================
-- DDL/EMP_MASTER.sql
-- Project: Enterprise Mainframe HRMS (Mini-HRMS Core Processing System)
-- Target RDBMS: IBM DB2 for z/OS
-- Description: Creates the core relational table for Employee Master records,
--              defines the unique primary index, and seeds initial test data.
-- ==============================================================================
-- INSTRUCTIONS FOR MAINFRAME BEGINNERS:
-- 1. In ISPF / TSO, access DB2 SPUFI (Option D -> S or DSNTEP2 batch utility).
-- 2. Ensure your Target Database and TableSpace are set according to your
--    installation standards (or use standard defaults provided below).
-- 3. Execute this SQL script. Ensure SQLCODE 000 is returned.
-- ==============================================================================

-- Optional: Drop table if already exists during re-runs
-- DROP TABLE EMP_MASTER;
-- COMMIT;

-- Create the Employee Master Table
CREATE TABLE EMP_MASTER (
    EMP_ID           CHAR(5)        NOT NULL,
    EMP_NAME         CHAR(30)       NOT NULL,
    DEPARTMENT       CHAR(15)       NOT NULL,
    DESIGNATION      CHAR(20)       NOT NULL,
    STATUS           CHAR(1)        NOT NULL WITH DEFAULT 'A', -- 'A'=Active, 'I'=Inactive, 'T'=Terminated
    JOINING_DATE     DATE           NOT NULL,
    LAST_WORKING_DAY DATE           NOT NULL WITH DEFAULT '9999-12-31', -- Default prevents COBOL NULL crash
    CURRENT_SALARY   DECIMAL(9,2)   NOT NULL,
    RATING           SMALLINT       NOT NULL WITH DEFAULT 0,
    BANK_ACCT        CHAR(15)       NOT NULL,
    PRIMARY KEY (EMP_ID)
);

-- Unique index to enforce primary key and accelerate lookups by EMP_ID
CREATE UNIQUE INDEX EMP_MASTER_IDX 
    ON EMP_MASTER (EMP_ID);

-- Grant appropriate permissions to CICS transaction ID and Batch Auth IDs
-- GRANT SELECT, INSERT, UPDATE, DELETE ON EMP_MASTER TO PUBLIC;

-- ==============================================================================
-- INITIAL SEED DATA FOR TESTING AND VERIFICATION
-- ==============================================================================
INSERT INTO EMP_MASTER (
    EMP_ID, EMP_NAME, DEPARTMENT, DESIGNATION, STATUS, 
    JOINING_DATE, LAST_WORKING_DAY, CURRENT_SALARY, RATING, BANK_ACCT
) VALUES 
('E0001', 'ALICE SMITH                  ', 'ENGINEERING    ', 'SR COBOL DEVELOPER  ', 'A', '2021-01-15', '9999-12-31', 75000.00, 4, 'ACCT-9876543210');

INSERT INTO EMP_MASTER (
    EMP_ID, EMP_NAME, DEPARTMENT, DESIGNATION, STATUS, 
    JOINING_DATE, LAST_WORKING_DAY, CURRENT_SALARY, RATING, BANK_ACCT
) VALUES 
('E0002', 'BOB JOHNSON                  ', 'FINANCE        ', 'FINANCIAL ANALYST   ', 'A', '2020-06-01', '9999-12-31', 62000.00, 5, 'ACCT-1234567890');

INSERT INTO EMP_MASTER (
    EMP_ID, EMP_NAME, DEPARTMENT, DESIGNATION, STATUS, 
    JOINING_DATE, LAST_WORKING_DAY, CURRENT_SALARY, RATING, BANK_ACCT
) VALUES 
('E0003', 'CAROL WILLIAMS               ', 'HUMAN RESOURCES', 'HR SPECIALIST       ', 'A', '2022-03-10', '9999-12-31', 54000.00, 3, 'ACCT-5556667770');

INSERT INTO EMP_MASTER (
    EMP_ID, EMP_NAME, DEPARTMENT, DESIGNATION, STATUS, 
    JOINING_DATE, LAST_WORKING_DAY, CURRENT_SALARY, RATING, BANK_ACCT
) VALUES 
('E0004', 'DAVID BROWN                  ', 'OPERATIONS     ', 'SYSADMIN            ', 'A', '2019-11-20', '9999-12-31', 68000.00, 2, 'ACCT-3334445550');

INSERT INTO EMP_MASTER (
    EMP_ID, EMP_NAME, DEPARTMENT, DESIGNATION, STATUS, 
    JOINING_DATE, LAST_WORKING_DAY, CURRENT_SALARY, RATING, BANK_ACCT
) VALUES 
('E0005', 'EVA MARTINEZ                 ', 'ENGINEERING    ', 'DB2 DBA SPECIALIST  ', 'A', '2018-08-05', '9999-12-31', 82000.00, 5, 'ACCT-7778889990');

COMMIT;

-- Verification Query: Check that test records are loaded
SELECT EMP_ID, EMP_NAME, DEPARTMENT, CURRENT_SALARY, STATUS, RATING 
FROM EMP_MASTER;
