/* ============================================================================
   Airport Management Database  -  Security of Databases, PART 1 implementation
   University of Luxembourg  -  Master in Cybersecurity
   ----------------------------------------------------------------------------
   00_database.sql : create the database and the five business schemas.
   Run as a sysadmin (sa) on SQL Server 2019.
   ============================================================================ */
USE master;
GO

IF DB_ID('AirportDB') IS NULL
BEGIN
    CREATE DATABASE AirportDB;
END
GO

ALTER DATABASE AirportDB SET RECOVERY FULL;
GO
ALTER DATABASE AirportDB SET PAGE_VERIFY CHECKSUM;
GO

USE AirportDB;
GO

IF SCHEMA_ID('Personal')    IS NULL EXEC('CREATE SCHEMA Personal    AUTHORIZATION dbo;');
IF SCHEMA_ID('Operational') IS NULL EXEC('CREATE SCHEMA Operational AUTHORIZATION dbo;');
IF SCHEMA_ID('Commercial')  IS NULL EXEC('CREATE SCHEMA Commercial  AUTHORIZATION dbo;');
IF SCHEMA_ID('Security')    IS NULL EXEC('CREATE SCHEMA Security    AUTHORIZATION dbo;');
IF SCHEMA_ID('Workforce')   IS NULL EXEC('CREATE SCHEMA Workforce   AUTHORIZATION dbo;');
GO
