USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOPhaseNumberText]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOPhaseNumberText](@intFolderRSN INT) 
RETURNS varchar(10)
AS
BEGIN
	/* Returns Phase Number text from UCO FolderInfo Phase Number for use in mailmerge 
	   documents. */

	DECLARE @intPhaseNumber int
	DECLARE @varPhaseNumberText varchar(10)

	SELECT @intPhaseNumber = ISNULL(FolderInfo.InfoValueNumeric, 0)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intFolderRSN
	AND FolderInfo.InfoCode = 23035
	
	IF @intPhaseNumber > 0 SELECT @varPhaseNumberText = 'Phase ' + CAST(@intPhaseNumber AS VARCHAR)
	ELSE SELECT @varPhaseNumberText = ''

	RETURN @varPhaseNumberText
END

GO
