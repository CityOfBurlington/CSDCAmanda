USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAttemptDesc]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      FUNCTION [dbo].[udf_GetProcessAttemptDesc](@intFolderRSN INT, @intProcessCode INT)
RETURNS VARCHAR(50)
AS
BEGIN
DECLARE @strAttemptRes VARCHAR(50)
SET @strAttemptRes = 'x'
SELECT @strAttemptRes = ValidProcessAttemptResult.ResultDesc
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
RETURN @strAttemptRes
END

GO
