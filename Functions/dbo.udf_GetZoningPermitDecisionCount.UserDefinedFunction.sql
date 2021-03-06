USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitDecisionCount]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetZoningPermitDecisionCount](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
   /* Use this to determine whether a decision was made on the application */
   /* Used by Infomaker forms, pz_director_reports.pbl */
   DECLARE @intDecisionAttemptCount int
   DECLARE @strFolderType varchar(3)
   DECLARE @intSubCode int
   DECLARE @intProcessCode int

   SELECT @intProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

   SELECT @intDecisionAttemptCount = COUNT(*) 
     FROM Folder, FolderProcess, FolderProcessAttempt 
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcess.ProcessCode = @intProcessCode
      AND Folder.FolderRSN = @intFolderRSN

   RETURN @intDecisionAttemptCount
END

GO
