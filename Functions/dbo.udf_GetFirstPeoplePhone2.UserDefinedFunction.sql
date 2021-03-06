USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPeoplePhone2]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  FUNCTION [dbo].[udf_GetFirstPeoplePhone2](@PeopleCode int, @intFolderRSN int) 
	RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @varRetVal VARCHAR(255)

	SELECT TOP 1 @varRetVal = RTRIM(LTRIM(ISNULL(People.Phone2, '')))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = @PeopleCode
	ORDER BY FolderPeople.PeopleRSN;

	RETURN @varRetVal
END



GO
