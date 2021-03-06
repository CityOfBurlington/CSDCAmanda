USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstAddressLine2]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[udf_GetFirstAddressLine2](@intFolderRSN INT) 
	RETURNS varchar(255)
AS
BEGIN
	DECLARE @varRetVal varchar(255)
        DECLARE @AddrLine2 varchar(255)
        DECLARE @AddrLine3 varchar(255)

        SELECT TOP 1 @AddrLine2 = LTRIM(RTRIM(NULLIF(People.AddressLine2, ' '))),
                     @AddrLine3 = LTRIM(RTRIM(NULLIF(People.AddressLine3, ' ')))
	FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = 2 
	ORDER BY FolderPeople.PeopleRSN;

        IF (@AddrLine3 IS NULL) OR (@AddrLine3 = 'US') OR (@AddrLine3 = 'USA') SELECT @varRetVal = @AddrLine2
        ELSE SELECT @varRetVal = @AddrLine3

	RETURN @varRetVal
END



GO
