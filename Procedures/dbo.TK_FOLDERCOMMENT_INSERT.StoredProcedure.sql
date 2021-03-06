USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_FOLDERCOMMENT_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TK_FOLDERCOMMENT_INSERT] @argFolderRSN int, @argComments varchar(2000),
@argRemindDate datetime, @argRemindUser varchar(1000), @argToDoFlag varchar(10), @DUserID varchar(1000)

AS

BEGIN

	INSERT INTO folderComment (folderRSN, commentDate, commentUser, reminderDate, comments, stampDate, stampUser, includeOnToDo)
	VALUES(@argFolderRSN, getDate(), @argRemindUser, @argRemindDate, @argComments, getDate(), @DUserID, @argToDoFlag)
END




GO
