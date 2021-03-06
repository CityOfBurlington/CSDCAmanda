USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_UpdNewFolderRSN]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[p_UpdNewFolderRSN]
AS

DECLARE @n_FolderRSN INT,
	@n_oldFolderRSN INT

DECLARE Folder_Cursor CURSOR FOR
	SELECT Folder.FolderRSN, OldFolderRSN FROM Folder WHERE ISNULL(OldFOlderRSN,0) > 0

BEGIN

	OPEN Folder_Cursor
	
	FETCH Folder_Cursor INTO @n_FolderRSN, @n_OldFolderRSN

	WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Folder
			   Set NewFolderRSN = @n_FolderRSN
			 WHERE FolderRSN = @n_oldFolderRSN

			COMMIT

			FETCH Folder_Cursor INTO @n_FolderRSN, @n_OldFolderRSN
		END


	CLOSE Folder_Cursor

	DEALLOCATE Folder_Cursor

END


GO
