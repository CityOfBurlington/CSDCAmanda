USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningCertificateofOccupancyRequestedFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningCertificateofOccupancyRequestedFlag](@intFolderRSN INT)
RETURNS VARCHAR(2)
AS
BEGIN 
   /* Returns Y if CO processing is underway, or N. */

   DECLARE @intFolderStatusCode int
   DECLARE @intPhasedCOProcessing int
   DECLARE @varCOProcessingFlag varchar(4)

   SET @varCOProcessingFlag = 'N'

   SELECT @intFolderStatusCode = Folder.StatusCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intFolderStatusCode IN (10007, 10011, 10012, 10013, 10025, 10026, 10035, 10040)
      SELECT @varCOProcessingFlag = 'Y'

   IF @intFolderStatusCode = 10047       /* Project Phasing */
   BEGIN
      SELECT @intPhasedCOProcessing = COUNT(*)
        FROM FolderProcess
       WHERE FolderProcess.FolderRSN = @intFolderRSN
         AND FolderProcess.ProcessCode = 10030 
         AND FolderProcess.StatusCode IN (10001, 10002, 10003, 10004, 10005)

      IF @intPhasedCOProcessing > 0 SELECT @varCOProcessingFlag = 'Y'
   END
   
   RETURN @varCOProcessingFlag
END

GO
