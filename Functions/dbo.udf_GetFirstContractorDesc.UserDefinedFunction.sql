USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstContractorDesc]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFirstContractorDesc](@FolderRSN INT) RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @RetVal VARCHAR(200)

	SELECT TOP 1 @RetVal = RTRIM(LTRIM(ISNULL(ValidPeople.PeopleDesc, '')))
	FROM FolderPeople
	INNER JOIN ValidPeople ON FolderPeople.PeopleCode = ValidPeople.PeopleCode
	WHERE FolderPeople.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode IN(10, 12, 13, 18, 31, 115, 135, 140, 210, 220, 230, 235, 240, 250, 260, 270, 280)

	RETURN @RetVal	
END
GO
