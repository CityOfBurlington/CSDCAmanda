USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeopleRSN]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeopleRSN](@intFolderRSN INT, @intPeopleCode INT) RETURNS INT
AS
BEGIN
	DECLARE @strRetVal INT

	SELECT TOP 1 @strRetVal = People.PeopleRSN
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
	WHERE Folder.FolderRSN = @intFolderRSN
	AND FolderPeople.PeopleCode = @intPeopleCode
	ORDER BY People.PeopleRSN DESC

	RETURN ISNULL(@strRetVal, 0)
END




GO
