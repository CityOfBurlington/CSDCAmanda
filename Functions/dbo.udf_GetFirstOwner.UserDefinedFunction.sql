USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstOwner]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    FUNCTION [dbo].[udf_GetFirstOwner](@intFolderRSN INT) 
	RETURNS varchar(255)
AS
BEGIN
	DECLARE @varRetVal varchar(255)
        DECLARE @PFirstName varchar(255)
        DECLARE @PLastName varchar(255)
        DECLARE @PFullName varchar(255)
        DECLARE @OrgName varchar(255)

	SELECT TOP 1 @PFirstName = People.NameFirst,
                     @PLastName = People.NameLast,
                     @OrgName = LTRIM(RTRIM(People.OrganizationName))
	FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = 2 
	ORDER BY FolderPeople.PeopleRSN;

        IF @PFirstName IS NOT NULL OR @PLastName IS NOT NULL
           SELECT @PFullName = LTRIM(RTRIM(@PFirstName + ' ' + @PLastName))

        IF @OrgName IS NULL SELECT @varRetVal = @PFullName
        ELSE SELECT @varRetVal = @OrgName

        RETURN @varRetVal
END

GO
