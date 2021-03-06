USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAttemptDateFirst]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetProcessAttemptDateFirst](@intFolderRSN INT, @intProcessCode INT)
RETURNS DATETIME
AS
BEGIN
DECLARE @dateAttemptDate datetime
SELECT @dateAttemptDate = FolderProcessAttempt.AttemptDate
FROM Folder, FolderProcess, FolderProcessAttempt
WHERE Folder.FolderRSN = FolderProcess.FolderRSN
AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcess.ProcessCode = @intProcessCode
AND Folder.FolderRSN = @intFolderRSN
AND FolderProcessAttempt.AttemptRSN = 
    ( SELECT MIN(FolderProcessAttempt.AttemptRSN) 
        FROM FolderProcess, FolderProcessAttempt
       WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
         AND FolderProcess.ProcessCode = @intProcessCode
         AND FolderProcessAttempt.FolderRSN = @intFolderRSN )
RETURN @dateAttemptDate
END


GO
