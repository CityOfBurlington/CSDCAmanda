USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionNextAttemptRSN]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionNextAttemptRSN](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
DECLARE @intDecisionProcessCode int
DECLARE @intDecisionNextAttemptRSN int 

SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intDecisionNextAttemptRSN = FolderProcessAttempt.AttemptRSN + 1
     FROM Folder, FolderProcess, FolderProcessAttempt
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcess.ProcessCode = @intDecisionProcessCode
      AND Folder.FolderRSN = @intFolderRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcess, FolderProcessAttempt
             WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
               AND FolderProcess.ProcessCode = @intDecisionProcessCode
               AND FolderProcessAttempt.FolderRSN = @intFolderRSN )

RETURN @intDecisionNextAttemptRSN
END
GO
