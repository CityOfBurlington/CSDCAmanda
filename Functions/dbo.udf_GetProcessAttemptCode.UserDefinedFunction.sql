USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAttemptCode]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[udf_GetProcessAttemptCode](@intFolderRSN INT, @intProcessCode INT)
RETURNS INT
AS
BEGIN
DECLARE @intAttemptResCode INT
SET @intAttemptResCode = 0
SELECT @intAttemptResCode = FolderProcessAttempt.ResultCode
FROM Folder, FolderProcess, FolderProcessAttempt
WHERE Folder.FolderRSN = FolderProcess.FolderRSN
AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcess.ProcessCode = @intProcessCode
AND Folder.FolderRSN = @intFolderRSN
AND FolderProcessAttempt.AttemptRSN = 
    ( SELECT max(FolderProcessAttempt.AttemptRSN) 
        FROM FolderProcess, FolderProcessAttempt
       WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
         AND FolderProcess.ProcessCode = @intProcessCode
         AND FolderProcessAttempt.FolderRSN = @intFolderRSN )
RETURN @intAttemptResCode
END


GO
