USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstCOAddressLine3]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFirstCOAddressLine3](@intFolderRSN INT) 
RETURNS varchar(255)
AS
BEGIN
	DECLARE @intPeopleCORequestorCount int
    DECLARE @intPeopleCode int
	DECLARE @varAddressLine3 varchar(255)

	SELECT @intPeopleCORequestorCount = COUNT(*)
      FROM FolderPeople
     WHERE FolderPeople.FolderRSN = @intFolderRSN
       AND FolderPeople.PeopleCode = 325          /* CO Requester */

	IF @intPeopleCORequestorCount > 0 SELECT @intPeopleCode = 325
	ELSE SELECT @intPeopleCode = 2                /* Owner */

	SELECT TOP 1 @varAddressLine3 = LTRIM(RTRIM(NULLIF(People.AddressLine3, ' ')))
	      FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	     WHERE Folder.FolderRSN = @intFolderRSN 
	       AND FolderPeople.PeopleCode = @intPeopleCode 
	  ORDER BY FolderPeople.PeopleRSN;

	RETURN @varAddressLine3 
END

GO
