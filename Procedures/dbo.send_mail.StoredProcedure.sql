USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[send_mail]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*  Procedure send_mail modified to send emails using EAI with the PullRDBMS method, and there is no support for using direct call to smtp server */

CREATE PROCEDURE [dbo].[send_mail] (@p_from VARCHAR(255), @p_to VARCHAR(500), @p_cc VARCHAR(500), @p_subject VARCHAR(500), 
@p_message VARCHAR(2000), @UserId VARCHAR(128)  = Null) 
AS 

--  4.4.29b: Anthony - Implemented send_mail using EAI using the PullRDBMS method.  Currently there is no support for using direct call to smtp server 

DECLARE @l_mailhost VarChar(255),
	@l_EaiURL VarChar(255),
	@l_HeartbeatType varchar(16),
	@EaiXml VarChar(4000),
	@out varchar(4000),
	@MaxRSN int

BEGIN 

   SELECT  @l_mailhost = EmailHost, @l_EaiURL = EaiURL , @l_HeartbeatType=HeartbeatType
         FROM ValidSite; 

   IF (@l_EaiURL IS NULL)
      BEGIN
         RAISERROR('Email via direct access SMTP is not supported in MSSQL, please configure EAI',16,-1);
      END
   ELSE 
      BEGIN
         SET @EaiXml = '<AmandaEai>' 
                  + ' <FromSystem>Email</FromSystem>' 
                  + ' <ToSystem>Email</ToSystem>' 
                  + ' <Email>' 
                  + '  <To>' + @p_to + '</To>' 
                  + '  <From>' + @p_from + '</From>' 
                  + '  <CC>' + @p_cc + '</CC>' 
                  + '  <Subject>' + @p_subject + '</Subject>' 
                  + '  <Body>' + @p_message + '</Body>' 
                  + ' </Email>' 
                  + '</AmandaEai>'; 
      END


      SELECT @MaxRSN = IsNull(MAX(RSN),0) + 1 FROM FifoEai

      INSERT INTO FifoEai (RSN, XML, StampDate, StampUser)
         VALUES (@MaxRSN , @EaiXml, GetDate(), @UserID)

END

GO
