USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCORequestDateForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCORequestDateForm](@intFolderRSN INT) 
RETURNS datetime
AS
BEGIN
   /* Returns the initial request date for Certificate of Occupancy processing. 
      Returns the date for the highest phase where the CO was requested. 
      Used by Infomaker CO report form. */

   DECLARE @intFolderStatusCode int
   DECLARE @intPCOProcessRSN int 
   DECLARE @dtCORequestDate datetime

   SET @intFolderStatusCode = 0

   SELECT @intFolderStatusCode = Folder.StatusCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intFolderStatusCode = 10047     /* Project Phasing */
   BEGIN
      SELECT @intPCOProcessRSN = MAX(FolderProcess.ProcessRSN) 
        FROM FolderProcess
       WHERE FolderProcess.FolderRSN = @intFolderRSN
         AND FolderProcess.ProcessCode = 10030
         AND FolderProcess.StatusCode IN (10001, 10002, 10003, 10004, 10005) 

      SELECT @dtCORequestDate = FolderProcessAttempt.AttemptDate
        FROM FolderProcessAttempt
       WHERE FolderProcessAttempt.ProcessRSN = @intPCOProcessRSN
         AND FolderProcessAttempt.AttemptRSN = 
            ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
                FROM FolderProcessAttempt
               WHERE FolderProcessAttempt.ProcessRSN = @intPCOProcessRSN
                 AND FolderProcessAttempt.ResultCode = 10001 )
   END
   ELSE       /* Single Phase Projects */
   BEGIN
      SELECT @dtCORequestDate = dbo.udf_GetProcessAttemptDateSpecific(@intFolderRSN, 10001, 10001)
   END

   RETURN @dtCORequestDate
END

GO
