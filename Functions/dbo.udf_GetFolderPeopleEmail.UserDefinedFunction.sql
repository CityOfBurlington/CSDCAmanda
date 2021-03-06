USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeopleEmail]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeopleEmail](@intFolderRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN

   DECLARE @varRetVal varchar(255)
   DECLARE @EmailAddr varchar(255)

   SELECT @EmailAddr = LTRIM(RTRIM(NULLIF(People.EmailAddress, '')))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
	WHERE Folder.FolderRSN = @intFolderRSN
	AND FolderPeople.PeopleCode = @intPeopleCode
	ORDER BY People.PeopleRSN

	SET @varRetVal = ''
	
	IF @EmailAddr IS NOT NULL SET @VarRetVal = @EmailAddr

	RETURN @varRetVal

END




GO
