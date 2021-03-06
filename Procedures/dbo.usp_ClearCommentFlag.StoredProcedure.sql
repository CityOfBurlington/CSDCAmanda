USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ClearCommentFlag]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_ClearCommentFlag](@strUserName VARCHAR(128))
AS
BEGIN

	/* This is a stored procedure to clear comments off users' To Do Lists. Comments appear on the list if the 
		field IncludeOnToDo is set to 'Y', which is the default on Comments. So, most users have lots of comments.
		This procedure will set all comments to not appear on the to list for the given user.
	*/ 

	IF @strUserName IS NULL OR LEN(@strUserName) < 1
	BEGIN
		RAISERROR ('You gotta give me a username to work with!', 16, -1)
		RETURN
	END

	/* Disable Button Permission check on FolderComment. Without this, the update fails due to security check. */
	UPDATE ValidSiteOption SET OptionValue = 'Yes' WHERE OptionKey = 'FolderComment-DoNotCheckButtonPermission-SameAsIn43'

	/* Update the FolderComments */
	UPDATE FolderComment SET IncludeOnToDo = 'N' WHERE CommentUser = @strUserName

	/* Re-enable Button Permissions */
	UPDATE ValidSiteOption SET OptionValue = 'NO' WHERE OptionKey = 'FolderComment-DoNotCheckButtonPermission-SameAsIn43'

END
GO
