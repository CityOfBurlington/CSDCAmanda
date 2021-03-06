USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[iReviewSendEmail]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROCEDURE [dbo].[iReviewSendEmail] (@argProcessRSN int)
  as
/* Version 43.14:
		Robb :	
*/
 BEGIN
   declare @msg_body VarChar(4000)
   declare @msg_subject VarChar(4000)
   declare @EmailAddress VarChar(60)
 
   SELECT @msg_body = dbo.f_iReviewMessageBody(@argProcessRSN), 
          @EmailAddress = ValidUser.EmailAddress
     FROM FolderProcess, ValidUser
    WHERE FolderProcess.ProcessRSN = @argProcessRSN
      and ValidUser.UserId = FolderProcess.AssignedUser;

   EXEC master.dbo.xp_sendmail @recipients = @EmailAddress, @message = 'Dallas Process for your iReview', @subject = @msg_subject
 END

GO
