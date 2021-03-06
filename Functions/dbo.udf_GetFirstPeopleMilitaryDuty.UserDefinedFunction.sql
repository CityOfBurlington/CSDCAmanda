USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPeopleMilitaryDuty]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFirstPeopleMilitaryDuty](@PeopleCode int, @intFolderRSN int) 
	RETURNS VARCHAR(3)
AS
BEGIN
	DECLARE @varRetVal VARCHAR(3)

	SELECT TOP 1 @varRetVal = CASE WHEN ISNULL(dbo.f_info_alpha_people(People.PeopleRSN, 25), '') = 'Yes' THEN 'Yes' ELSE 'No ' END
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = @PeopleCode
	ORDER BY FolderPeople.PeopleRSN;

	RETURN @varRetVal
END




GO
