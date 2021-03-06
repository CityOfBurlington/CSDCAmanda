USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstContractorAddr2]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFirstContractorAddr2](@FolderRSN INT) RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @RetVal VARCHAR(200)

	SELECT TOP 1 @RetVal = RTRIM(LTRIM(ISNULL(People.AddressLine2, '')))
	FROM FolderPeople
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	WHERE FolderPeople.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode IN(10, 12, 13, 18, 31, 115, 135, 140, 210, 220, 230, 235, 240, 250, 260, 270, 280)

	RETURN @RetVal	
END
GO
