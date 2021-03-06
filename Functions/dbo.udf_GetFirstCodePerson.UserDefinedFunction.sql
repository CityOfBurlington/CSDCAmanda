USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstCodePerson]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFirstCodePerson](@intBillingRecipient INT, @intPeopleCode INT) RETURNS INT
AS
BEGIN
	DECLARE @varRetVal INT

	SELECT TOP 1 @varRetVal = FolderPeople.PeopleRSN
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	INNER JOIN ValidPeople ON FolderPeople.PeopleCode = ValidPeople.PeopleCode
	WHERE CAST(Folder.ReferenceFile AS INT) = @intBillingRecipient
	AND Folder.FolderType = 'RB'
	AND Folder.FolderYear = '05'	
	AND FolderPeople.PeopleCode = @intPeopleCode
	ORDER BY 1 DESC

        RETURN @varRetVal
END


GO
