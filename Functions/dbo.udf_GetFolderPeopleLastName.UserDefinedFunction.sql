USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeopleLastName]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeopleLastName](@intFolderRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @strRetVal VARCHAR(50)

	SELECT @strRetVal = RTRIM(ISNULL(People.NameLast, ''))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
	WHERE Folder.FolderRSN = @intFolderRSN
	AND FolderPeople.PeopleCode = @intPeopleCode

	IF @strRetVal = ''
		BEGIN
		
		SELECT @strRetVal = RTRIM(LTRIM(ISNULL(People.OrganizationName, '')))
		FROM Folder
		INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
		INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
		WHERE Folder.FolderRSN = @intFolderRSN
		AND FolderPeople.PeopleCode = @intPeopleCode
	END


	RETURN ISNULL(@strRetVal, '')
END





GO
