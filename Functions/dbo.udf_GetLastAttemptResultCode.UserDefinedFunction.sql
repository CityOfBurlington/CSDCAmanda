USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastAttemptResultCode]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetLastAttemptResultCode](@FolderRSN INT, @ProcessCode INT) 
RETURNS INT
AS
BEGIN
   DECLARE @intResultCode INT
   
   SET @intResultCode = 0

   SELECT @intResultCode = ISNULL(FolderProcessAttempt.ResultCode, 0)
     FROM Folder, FolderProcess, FolderProcessAttempt
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcess.ProcessCode = @ProcessCode
      AND Folder.FolderRSN = @FolderRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcess, FolderProcessAttempt
             WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
               AND FolderProcess.ProcessCode = @ProcessCode
               AND FolderProcessAttempt.FolderRSN = @FolderRSN )

   RETURN @intResultCode
END

GO
