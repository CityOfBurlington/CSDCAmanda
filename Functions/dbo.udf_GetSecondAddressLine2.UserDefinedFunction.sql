USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetSecondAddressLine2]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[udf_GetSecondAddressLine2](@intFolderRSN INT) 
	RETURNS varchar(255)
AS
BEGIN
	DECLARE @varRetVal varchar(255)
        DECLARE @AddrLine2 varchar(255)
        DECLARE @AddrLine3 varchar(255)

    SELECT TOP 1 @AddrLine2 = LTRIM(RTRIM(NULLIF(People.AddressLine2, ' ')))
	FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = 2 
	ORDER BY FolderPeople.PeopleRSN;

	SELECT @AddrLine3 = dbo.udf_GetFirstAddressLine2(@intFolderRSN)
        IF (@AddrLine2 = @AddrLine3) SELECT @varRetVal = NULL
        ELSE SELECT @varRetVal = @AddrLine2

	RETURN @varRetVal
END



GO
