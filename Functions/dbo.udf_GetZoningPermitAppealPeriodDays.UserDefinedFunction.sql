USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitAppealPeriodDays]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetZoningPermitAppealPeriodDays](@intFolderRSN INT)
RETURNS INT
AS
BEGIN 
	/* Looks back to returns the length of the appeal period for the last application decision in a folder. 
	   Administrative decisions are 15 days, and all others (DRB and the courts) are 30 days. 
	   The Folder SubCode stays Administrative Review (10041) for applications that were initially reviewed 
	   administratively, regardless of any subsequent appeals. */

	DECLARE @intAppealPeriodDays int
	DECLARE @intSubCode int
	DECLARE @intAppealtoDRBProcessRSN int 
	DECLARE @intAppealtoDRBAttemptCount int
	
	SET @intAppealPeriodDays = 0 
	SET @intAppealtoDRBProcessRSN = 0
	
	SELECT @intSubCode = Folder.SubCode 
	FROM Folder 
	WHERE Folder.FolderRSN = @intFolderRSN 
	
	IF @intSubCode = 10041		/* Administrative Review */
	BEGIN
		SELECT @intAppealtoDRBProcessRSN = ISNULL(FolderProcess.ProcessRSN, 0) 
		FROM FolderProcess 
		WHERE FolderProcess.FolderRSN = @intFolderRSN 
		AND FolderProcess.ProcessCode = 10002 
		
		SELECT @intAppealtoDRBAttemptCount = dbo.udf_GetProcessAttemptCount(@intFolderRSN, @intAppealtoDRBProcessRSN)
		
		IF @intAppealtoDRBAttemptCount = 0 SELECT @intAppealPeriodDays = 15 
		ELSE SELECT @intAppealPeriodDays = 30 
	END
	ELSE SELECT @intAppealPeriodDays = 30 

	RETURN @intAppealPeriodDays
END


GO
