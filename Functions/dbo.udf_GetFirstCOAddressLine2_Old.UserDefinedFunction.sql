USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstCOAddressLine2_Old]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFirstCOAddressLine2_Old](@intFolderRSN INT) 
RETURNS varchar(255)
AS
BEGIN
	DECLARE @intPeopleCORequesterCount int
    DECLARE @intPeopleCode int
    DECLARE @varAddrLine2 varchar(255)
    DECLARE @varAddrLine3 varchar(255)
	DECLARE @varAddressLine2 varchar(255)

	SELECT @intPeopleCORequesterCount = COUNT(*)
      FROM FolderPeople
     WHERE FolderPeople.FolderRSN = @intFolderRSN
       AND FolderPeople.PeopleCode = 325          /* CO Requester */

	IF @intPeopleCORequesterCount > 0 SELECT @intPeopleCode = 325
	ELSE SELECT @intPeopleCode = 2                /* Owner */

    SELECT TOP 1 @varAddrLine2 = LTRIM(RTRIM(NULLIF(People.AddressLine2, ' '))),
                 @varAddrLine3 = LTRIM(RTRIM(NULLIF(People.AddressLine3, ' ')))
          FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN 
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN 
	     WHERE Folder.FolderRSN = @intFolderRSN 
	       AND FolderPeople.PeopleCode = @intPeopleCode 
	  ORDER BY FolderPeople.PeopleRSN;

    IF (@varAddrLine3 IS NULL) OR (@varAddrLine3 = 'US') OR (@varAddrLine3 = 'USA') 
         SELECT @varAddressLine2 = @varAddrLine2
    ELSE SELECT @varAddressLine2 = @varAddrLine3

	RETURN @varAddressLine2 
END

GO
