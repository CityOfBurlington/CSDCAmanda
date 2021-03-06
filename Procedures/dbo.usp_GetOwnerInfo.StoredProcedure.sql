USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetOwnerInfo]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetOwnerInfo](@intFolderRSN INT, @varField VARCHAR(50)) 
AS
BEGIN
	--DECLARE @varRetVal VARCHAR(255)
	DECLARE @strSQL NVARCHAR(500)

	SET @strSQL = 'SELECT TOP 1 ' + @varField + ' FROM Folder ' +
	'INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN ' +
	'INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN ' +
	'WHERE Folder.FolderRSN = 121783 ' +
	'AND FolderPeople.PeopleCode = 2 ' +
	'ORDER BY FolderPeople.PeopleRSN';

	EXEC sp_ExecuteSQL @strSQL
END

GO
