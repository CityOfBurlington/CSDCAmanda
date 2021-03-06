USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitDecisionCode]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetZoningPermitDecisionCode](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
   /* Use this to determine what decision was made on the application */
   /* Used by Infomaker forms, pz_director_reports.pbl */
   DECLARE @intDecisionAttemptCode int

	SELECT @intDecisionAttemptCode = ResultCode 
	FROM Folder F
	JOIN FolderProcess FP ON F.FolderRSN = FP.FolderRSN
	JOIN FolderProcessAttempt FPA ON FP.ProcessRSN = FPA.ProcessRSN
	WHERE FP.ProcessCode = 10005
	AND F.FolderRSN = @intFolderRSN

   RETURN @intDecisionAttemptCode
END


GO
