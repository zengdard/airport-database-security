/* ============================================================================
   05_tde_audit_backup.sql : encryption at rest, auditing and a backup chain.
   Must run as sysadmin. The certificate backup is what allows a restore on
   another server - keep it with the backups, never inside the database.
   ============================================================================ */
USE master;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ------------------------- TRANSPARENT DATA ENCRYPTION ------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Airport#2026!TDE';
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'AirportTDECert')
    CREATE CERTIFICATE AirportTDECert WITH SUBJECT = 'AirportDB TDE certificate';
GO

USE AirportDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID())
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE AirportTDECert;
GO

IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys
           WHERE database_id = DB_ID() AND encryption_state = 1)
    ALTER DATABASE AirportDB SET ENCRYPTION ON;
GO

/* Keep an off-server copy of the certificate and its private key. */
USE master;
GO
DECLARE @certExists INT;
EXEC master.dbo.xp_fileexist '/var/opt/mssql/data/AirportTDECert.cer', @certExists OUTPUT;
IF @certExists = 0
    BACKUP CERTIFICATE AirportTDECert
        TO FILE = '/var/opt/mssql/data/AirportTDECert.cer'
        WITH PRIVATE KEY (
            FILE = '/var/opt/mssql/data/AirportTDECert.key',
            ENCRYPTION BY PASSWORD = 'Airport#2026!CertBackup');
GO

/* ------------------------------- AUDITING -------------------------------- */
USE AirportDB;
GO
IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'AirportDbAudit')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION AirportDbAudit WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION AirportDbAudit;
END
GO

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'AirportAudit')
BEGIN
    ALTER SERVER AUDIT AirportAudit WITH (STATE = OFF);
    DROP SERVER AUDIT AirportAudit;
END
GO

CREATE SERVER AUDIT AirportAudit
    TO FILE (FILEPATH = '/var/opt/mssql/data/',
             MAXSIZE = 100 MB,
             MAX_ROLLOVER_FILES = 5,
             RESERVE_DISK_SPACE = OFF)
    WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
GO

ALTER SERVER AUDIT AirportAudit WITH (STATE = ON);
GO

USE AirportDB;
GO

CREATE DATABASE AUDIT SPECIFICATION AirportDbAudit
    FOR SERVER AUDIT AirportAudit
    ADD (SELECT, UPDATE, DELETE ON Personal.Passport BY public),
    ADD (SELECT, INSERT, UPDATE, DELETE ON Security.BanList BY public)
WITH (STATE = ON);
GO

/* -------------------------------- BACKUPS -------------------------------- */
USE master;
GO
EXEC master.dbo.xp_create_subdir '/var/opt/mssql/data/backups';
GO

BACKUP DATABASE AirportDB
    TO DISK = '/var/opt/mssql/data/backups/AirportDB_full.bak'
    WITH FORMAT, INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO

BACKUP DATABASE AirportDB
    TO DISK = '/var/opt/mssql/data/backups/AirportDB_diff.bak'
    WITH DIFFERENTIAL, INIT, COMPRESSION, CHECKSUM;
GO

BACKUP LOG AirportDB
    TO DISK = '/var/opt/mssql/data/backups/AirportDB_log.trn'
    WITH FORMAT, INIT, COMPRESSION, CHECKSUM;
GO

/* Restore drill (run on a test instance, never over the live database):
   RESTORE DATABASE AirportDB_Test FROM DISK = '.../AirportDB_full.bak'
     WITH MOVE 'AirportDB'     TO '/var/opt/mssql/data/AirportDB_Test.mdf',
          MOVE 'AirportDB_log' TO '/var/opt/mssql/data/AirportDB_Test.ldf',
          NORECOVERY, REPLACE;
   RESTORE DATABASE AirportDB_Test FROM DISK = '.../AirportDB_diff.bak' WITH NORECOVERY;
   RESTORE LOG      AirportDB_Test FROM DISK = '.../AirportDB_log.trn'  WITH RECOVERY;
*/
GO

PRINT 'TDE enabled, audit started, backups written to /var/opt/mssql/data/backups.';
GO
