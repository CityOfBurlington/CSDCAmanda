USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_TestEmail]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_TestEmail] (@ProfileName VARCHAR(30), @Recipients VARCHAR(400), @Subject varchar(400), @Body varchar(400))
AS
BEGIN
/*
Amanda
EmailAutomation
NoReply
RFS
*/

EXEC msdb.dbo.sp_send_dbmail
@profile_name = @ProfileName,
@recipients = @Recipients,
@copy_recipients = '',
@subject = @Subject,
@body_format = 'HTML',
@body = @Body


END

GO
