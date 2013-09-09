USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPeopleDOB]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  FUNCTION [dbo].[udf_GetFirstPeopleDOB](@PeopleCode int, @intFolderRSN int) 
	RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @varRetVal VARCHAR(255)

	SELECT TOP 1 @varRetVal = RTRIM(LTRIM(ISNULL(dbo.FormatDateTime(People.BirthDate, 'MM/DD/YYYY'), '')))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = @PeopleCode
	ORDER BY FolderPeople.PeopleRSN;

	RETURN @varRetVal
END



GO
