USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetYearSequence]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetYearSequence](@intFolderRSN INT) RETURNS VARCHAR(20)
AS
BEGIN
	/* Complaint number (Year-Sequence number) used by Code Enforcement */

	DECLARE @varYearSequence varchar(20)
	
	SET @varYearSequence = '-'

	SELECT @varYearSequence = RTRIM(CAST(Folder.FolderCentury AS CHAR)) + Folder.FolderYear + '-' + Folder.FolderSequence 
	FROM Folder 
	WHERE FOlder.FolderRSN = @intFolderRSN

	RETURN @varYearSequence
END

GO
