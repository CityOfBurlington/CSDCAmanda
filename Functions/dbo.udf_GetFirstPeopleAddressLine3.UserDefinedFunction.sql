USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPeopleAddressLine3]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFirstPeopleAddressLine3](@PeopleCode int, @intFolderRSN int) 
	RETURNS varchar(255)
AS
BEGIN
	DECLARE @varRetVal varchar(255)
        DECLARE @AddrLine3 varchar(255)

        SELECT TOP 1 @AddrLine3 = LTRIM(RTRIM(People.AddressLine3))
	FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = @PeopleCode
	ORDER BY FolderPeople.PeopleRSN;

        SET @varRetVal = ISNULL(@AddrLine3, ' ')

	RETURN @varRetVal
END


GO
