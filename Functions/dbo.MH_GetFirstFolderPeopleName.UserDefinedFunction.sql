USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[MH_GetFirstFolderPeopleName]    Script Date: 9/9/2013 9:43:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[MH_GetFirstFolderPeopleName](@intFolderRSN INT, @PeopleCode INT) RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @varRetVal varchar(255)
	DECLARE @PFirstName varchar(255)
	DECLARE @PLastName varchar(255)
	DECLARE @OrgName varchar(255)

	SELECT TOP 1 @PFirstName = People.NameFirst,
                 @PLastName = People.NameLast,
                 @OrgName = LTRIM(RTRIM(People.OrganizationName))
	FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = @PeopleCode 
	ORDER BY FolderPeople.PeopleRSN

	
        IF @PFirstName IS NULL AND @PLastName IS NULL
           SELECT @varRetVal = ISNULL(@OrgName, '')
		ELSE
			SELECT @varRetVal = ISNULL(@PFirstName + ' ', '') + ISNULL(@PLastName, '')

        RETURN @varRetVal
END



GO
