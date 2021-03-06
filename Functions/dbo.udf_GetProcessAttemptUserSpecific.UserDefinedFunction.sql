USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAttemptUserSpecific]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetProcessAttemptUserSpecific](@intFolderRSN INT, @intProcessCode INT, @intResultCode INT)
RETURNS VARCHAR(60)
AS
BEGIN
   DECLARE @varAttemptUser VARCHAR(60)
      SET @varAttemptUser = ' '

   SELECT @varAttemptUser = ValidUser.UserName + ', ' + ValidUser.UserTitle 
     FROM Folder, FolderProcess, FolderProcessAttempt, ValidUser
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcess.ProcessCode = @intProcessCode
      AND Folder.FolderRSN = @intFolderRSN
      AND FolderProcessAttempt.AttemptBy = ValidUser.UserID 
      AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcess, FolderProcessAttempt
          WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
            AND FolderProcess.ProcessCode = @intProcessCode
            AND FolderProcessAttempt.ResultCode = @intResultCode
            AND FolderProcessAttempt.FolderRSN = @intFolderRSN )

   RETURN @varAttemptUser
END





GO
