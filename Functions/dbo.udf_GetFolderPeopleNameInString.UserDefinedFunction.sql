USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeopleNameInString]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeopleNameInString](@PeopleCode INT, @FolderRSN INT) RETURNS VARCHAR(1000)
AS
BEGIN

	DECLARE @RetVal VARCHAR(1000)
	DECLARE @FirstName VARCHAR(200)
	DECLARE @LastName VARCHAR(200)
	DECLARE @OrgName VARCHAR(200)

	SET @RetVal = ''

	DECLARE curPeople CURSOR FOR
	SELECT People.NameFirst, People.NameLast, People.OrganizationName
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	WHERE Folder.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = @PeopleCode
	
	
	OPEN curPeople
	
	FETCH NEXT FROM curPeople INTO @FirstName, @LastName, @OrgName

	WHILE @@FETCH_STATUS = 0 BEGIN
		IF @RetVal <> '' BEGIN
			SET @RetVal = @RetVal + ', '
		END

		SET @RetVal = @RetVal + ISNULL(@FirstName + ' ', '') + ISNULL(@LastName, '') + ISNULL(' (' + @orgName + ')', '')

		FETCH NEXT FROM curPeople INTO @FirstName, @LastName, @OrgName
	END
	
	CLOSE curPeople
	DEALLOCATE curPeople
	
	SET @RetVal = RTRIM(LTRIM(@RetVal))
	
	IF substring(@RetVal, 1, 1) = '(' AND substring(@RetVal, LEN(@RetVal), 1) = ')' BEGIN
		SET @RetVal = substring(@RetVal, 2, LEN(@RetVal) - 2)
	END
	
	RETURN @RetVal
END

GO
