USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCOStatusForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCOStatusForm](@intFolderRSN INT) 
RETURNS varchar(30)
AS
BEGIN
   /* Returns the status description for Certificate of Occupancy processing. 
      Used by Infomaker CO report form. */

   DECLARE @intFolderStatusCode int
   DECLARE @varCOStatusDesc varchar(20)

   SET @intFolderStatusCode = 0

   SELECT @intFolderStatusCode = Folder.StatusCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intFolderStatusCode = 10047     /* Project Phasing */
   BEGIN
      SELECT @varCOStatusDesc = ValidProcessStatus.StatusDesc 
        FROM ValidProcessStatus, FolderProcess
       WHERE ValidProcessStatus.StatusCode = FolderProcess.StatusCode
         AND FolderProcess.ProcessRSN IN  
             ( SELECT MAX(FolderProcess.ProcessRSN) 
                 FROM FolderProcess
                WHERE FolderProcess.FolderRSN = @intFolderRSN
                  AND FolderProcess.ProcessCode = 10030
                  AND FolderProcess.StatusCode IN (10001, 10002, 10003, 10004, 10005) )
   END
   ELSE       /* Single Phase Projects */
   BEGIN
      SELECT @varCOStatusDesc = ValidStatus.StatusDesc 
        FROM ValidStatus, Folder
       WHERE ValidStatus.StatusCode = Folder.StatusCode
         AND Folder.FolderRSN = @intFolderRSN
   END

   RETURN @varCOStatusDesc 
END

GO
