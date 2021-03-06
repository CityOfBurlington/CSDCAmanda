USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CountProcessAttemptResultSpecific]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_CountProcessAttemptResultSpecific](@intFolderRSN INT, @intProcessCode INT, @intAttemptCode INT)
   RETURNS INT
AS
BEGIN
   DECLARE @AttemptCount int

   SET @AttemptCount = 0

   SELECT @AttemptCount = COUNT(*)
     FROM FolderProcess, FolderProcessAttempt
    WHERE FolderProcess.FolderRSN = @intFolderRSN
      AND FolderProcess.ProcessCode = @intProcessCode
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcessAttempt.ResultCode = @intAttemptCode

   RETURN @AttemptCount
END


GO
