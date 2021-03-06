USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspRestoreProductionToDevelopment]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspRestoreProductionToDevelopment]
AS
BEGIN

RESTORE DATABASE [AMANDA_Development] FROM  
DISK = N'D:\MSSQL\Backup\Amanda_Production\AMANDA_Production_db_200707122102.BAK' 
WITH  FILE = 1,  
MOVE N'AMANDA_Data' TO N'E:\MSSQL\Data\AMANDA_Development.mdf',  
MOVE N'AMANDA_Log' TO N'E:\MSSQL\Log\AMANDA_Development_log.LDF',  
NOUNLOAD,  REPLACE,  STATS = 10

END
GO
