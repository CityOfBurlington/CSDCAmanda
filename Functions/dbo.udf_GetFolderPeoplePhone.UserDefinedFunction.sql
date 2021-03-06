USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeoplePhone]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeoplePhone](@intFolderRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN

	DECLARE @strRetVal VARCHAR(150)

	SELECT @strRetVal = 
				RTRIM(LTRIM(ISNULL(People.Phone1Desc + ':', ''))) +
				ISNULL(People.Phone1 + '  ', '') +
				RTRIM(LTRIM(ISNULL(People.Phone2Desc + ':', ''))) +
				ISNULL(People.Phone2 + '  ', '') +
				RTRIM(LTRIM(ISNULL(People.Phone3Desc + ':', ''))) +
				ISNULL(People.Phone3 + '  ', '') 
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
	WHERE Folder.FolderRSN = @intFolderRSN
	AND FolderPeople.PeopleCode = @intPeopleCode
	ORDER BY People.PeopleRSN

	RETURN ISNULL(@strRetVal, '')
END




GO
