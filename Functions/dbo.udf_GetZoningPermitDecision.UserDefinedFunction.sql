USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitDecision]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitDecision](@intFolderRSN INT)
RETURNS VARCHAR(40)
AS
BEGIN
   DECLARE @varAttemptDesc varchar(40)
   DECLARE @varFolderType varchar(3)
   DECLARE @intStatusCode int
   DECLARE @intWorkCode int
   DECLARE @intProcessCode int

   SELECT @varFolderType = Folder.FolderType, 
		  @intStatusCode = Folder.StatusCode, 
          @intWorkCode = Folder.WorkCode
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @intProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

   SET @varAttemptDesc = 'None Yet'

   SELECT @varAttemptDesc = ValidProcessAttemptResult.ResultDesc
     FROM Folder, FolderProcess, FolderProcessAttempt, ValidProcessAttemptResult
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcessAttempt.ResultCode = ValidProcessAttemptResult.ResultCode
      AND FolderProcess.ProcessCode = @intProcessCode
      AND Folder.FolderRSN = @intFolderRSN
      AND FolderProcessAttempt.AttemptRSN = 
        ( SELECT max(FolderProcessAttempt.AttemptRSN) 
            FROM FolderProcess, FolderProcessAttempt
           WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
             AND FolderProcess.ProcessCode = @intProcessCode
             AND FolderProcessAttempt.FolderRSN = @intFolderRSN )

   IF @varFolderType = 'ZL' AND @varAttemptDesc = 'None Yet'
      SELECT @varAttemptDesc = 
      CASE @intWorkCode 
         WHEN 10004 THEN 'Enforcement Decision'
         WHEN 10005 THEN 'Misc Zoning Decision'
         ELSE 'Unknown ZL WorkCode'
      END

	IF @intStatusCode = 10010 SELECT @varAttemptDesc = 'Not Applicable'

   RETURN @varAttemptDesc
END

GO
