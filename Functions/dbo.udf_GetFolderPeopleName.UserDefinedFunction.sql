USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeopleName]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeopleName](@intFolderRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @strRetVal VARCHAR(50)

	SELECT TOP 1 @strRetVal = RTRIM(LTRIM(ISNULL(People.NameFirst, '') + ' ' + ISNULL(People.NameLast, '')))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
	WHERE Folder.FolderRSN = @intFolderRSN
	AND FolderPeople.PeopleCode = @intPeopleCode
	ORDER BY People.PeopleRSN DESC

	IF @strRetVal = ''
		BEGIN
		
		SELECT TOP 1 @strRetVal = RTRIM(LTRIM(ISNULL(People.OrganizationName, '')))
		FROM Folder
		INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
		INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
		WHERE Folder.FolderRSN = @intFolderRSN
		AND FolderPeople.PeopleCode = @intPeopleCode
		ORDER BY People.PeopleRSN DESC
	END


	RETURN ISNULL(@strRetVal, '')
END




GO
