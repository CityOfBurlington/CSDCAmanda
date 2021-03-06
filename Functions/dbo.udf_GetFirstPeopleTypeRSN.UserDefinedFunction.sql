USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPeopleTypeRSN]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFirstPeopleTypeRSN](@PeopleCode int, @intFolderRSN int) 
	RETURNS INT
AS
BEGIN
	DECLARE @RetVal INT

	SELECT TOP 1 @RetVal = FolderPeople.PeopleRSN
	FROM FolderPeople 
	WHERE FolderPeople.FolderRSN = @intFolderRSN 
	AND FolderPeople.PeopleCode = @PeopleCode 
	ORDER BY FolderPeople.PeopleRSN

	RETURN @RetVal
END



GO
