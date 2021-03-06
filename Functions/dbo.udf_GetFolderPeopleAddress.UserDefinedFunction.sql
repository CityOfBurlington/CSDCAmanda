USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPeopleAddress]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetFolderPeopleAddress](@intFolderRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN

   DECLARE @varRetVal varchar(255)
   DECLARE @AddrLine1 varchar(255)
   DECLARE @AddrLine2 varchar(255)
   DECLARE @AddrLine3 varchar(255)

   SELECT @AddrLine1 = LTRIM(RTRIM(NULLIF(People.AddressLine1, ' '))),
          @AddrLine2 = LTRIM(RTRIM(NULLIF(People.AddressLine2, ' '))),
          @AddrLine3 = LTRIM(RTRIM(NULLIF(People.AddressLine3, ' ')))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN =  People.PeopleRSN
	WHERE Folder.FolderRSN = @intFolderRSN
	AND FolderPeople.PeopleCode = @intPeopleCode
	ORDER BY People.PeopleRSN

	SET @varRetVal = ''
	
	IF @AddrLine1 IS NOT NULL SET @VarRetVal = @AddrLine1

	IF @AddrLine2 IS NOT NULL SET @VarRetVal = LTRIM(RTRIM(@VarRetVal + ' ' + @AddrLine2))
	
	IF @AddrLine3 IS NOT NULL SET @VarRetVal = LTRIM(RTRIM(@VarRetVal + ' ' + @AddrLine3))

	RETURN UPPER(@varRetVal)

END




GO
