USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[EmailToDo_SendComment]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure EmailToDo_SendComment modified to send emails in a new way using Message table */

CREATE PROCEDURE [dbo].[EmailToDo_SendComment]
    @argFolderRSN              INT,
    @argReminderDate           DATETIME, 
    @argCommentDate            DATETIME, 
    @argStampUser              varchar(128), 
    @V_Email                   varchar(60),
    @argCommentUser            varchar (128) = NULL
AS	

/* 5.4.4.31: Modified Anthony: to send email in the new way using Message table
             Modified ESS : Issue Id - 22560 and 22561 */

/* Amanda 44.27: ESS:Manjit 2009.07.22 : To avoid inserting into table Fifo_Auto_Web for AMANDAi(web) */
/* Version 4.4.26a: YUMING August 24, 2009: Changed data type to Integer from Numeric for @n_AutoRSN , @argFolderRSN */ 
/* v 4.3.12 Aug 24, 2004, For EmailToDO */


--   DECLARE @EaiURL                       VARCHAR(256)
--   DECLARE @EaiUserid                    VARCHAR(128)
--   DECLARE @EaiPassword                  VARCHAR(128)
--   DECLARE @EaiSystem                    VARCHAR(64)
--   DECLARE @EaiQueueFlag                 CHAR(1)
--   DECLARE @HeartbeatType                VARCHAR(16)
--   DECLARE @EmailAddress                 VARCHAR(256)
     DECLARE @Email_Notification_UseEAI    VARCHAR(64)
--   DECLARE @StampUser                    VARCHAR(128)
--   DECLARE @MaxRSN                       INT
--   DECLARE @Out                          VARCHAR(2000)
--   DECLARE @EaiXml                       VARCHAR(4000)
     DECLARE @n_maxRSN                     INT
     DECLARE @c_xml                        VARCHAR(4000)


BEGIN

    DECLARE    
     @c_FolderName	VARCHAR(64),
     @n_AutoRSN 		INT,
     @c_Subject		VARCHAR(255)

/* -- Commented out for 22560 implementation
    
    SELECT @EaiURL = IsNull(EaiURL,''), @EaiUserid = IsNull(EaiUserid,''), @EaiPassword = IsNull(EaiPassword,''),           
           @EaiSystem = IsNull(EaiSystem,''), @EaiQueueFlag = IsNull(EaiQueueFlag,''), 
           @HeartbeatType = IsNull(HeartbeatType,''), @StampUser = StampUser
    FROM  ValidSite;
-- */

    SELECT @Email_Notification_UseEAI = OptionValue 
    FROM ValidsiteOption
    WHERE OptionKey = 'Email-Notification-UseEAI'


    IF LOWER(@Email_Notification_UseEAI) = 'yes' 
        BEGIN -- 1

	  /* -- Commented out for 22560 implementation
          IF @EaiURL = '' return

          SET @EaiXml =  '<AmandaEai>' 
	          + ' <FromSystem>' + @EaiSystem + '</FromSystem>'
	          + ' <ToSystem>' + @EaiSystem + '</ToSystem>'
	          + ' <ToUserid>' + @EaiUserid + '</ToUserid>'
	          + ' <ToPassword key="EaiKey">' + @EaiPassword + '</ToPassword>'
          IF (IsNull(@EaiQueueFlag, 'N') = 'Y')
	    BEGIN
              SET @EaiXML = @EaiXML + '  <Queue>Yes</Queue>'
	    END
	  SET @EaiXml = @EaiXML 
	          + ' <FolderCommentEmail>'
	          + '  <FolderRSN>' + CAST(@argFolderRSN AS VARCHAR(10)) + '</FolderRSN>'
	          + '  <CommentUser>' + @argCommentUser + '</CommentUser>'
	          + '  <ReminderDate>' + CONVERT(VARCHAR(20), @argReminderDate, 20) + '</ReminderDate>'
	          + '  <CommentDate>' + CONVERT(VARCHAR(20),@argCommentDate,20) + '</CommentDate>'
	          + '  <StampUser>' + @argStampUser + '</StampUser>'
	          + ' </FolderCommentEmail>'
	          + '</AmandaEai>'

          SELECT @MaxRSN = IsNull(MAX(RSN),0) + 1 FROM FifoEai

          INSERT INTO FifoEai (RSN, XML, StampDate, StampUser)
                VALUES (@MaxRSN , @EaiXml, GetDate(), @StampUser)
 	  -- */

		SET @c_xml = '<command> <FolderCommentEmail>'
	          + '  <FolderRSN>' + CAST(@argFolderRSN AS VARCHAR(10)) + '</FolderRSN>'
	          + '  <CommentUser>' + @argCommentUser + '</CommentUser>'
	          + '  <ReminderDate>' + CONVERT(VARCHAR(20), @argReminderDate, 20) + '</ReminderDate>'
	          + '  <CommentDate>' + CONVERT(VARCHAR(20),@argCommentDate,20) + '</CommentDate>'
	          + '  <StampUser>' + @argStampUser + '</StampUser>'
	          + ' </FolderCommentEmail> </command>'

		SELECT @n_maxRSN = Max(MessageRSN) from Message

		IF @n_maxRSN > ''
			SET @n_maxRSN = @n_maxRSN + 1
		ELSE
			SET @n_maxRSN = 1


		INSERT INTO MESSAGE 
		(
			MessageRSN,
			CommandXml,
			StatusCode,
			StampDate,
			StampUser
		) 
		VALUES 
		(
			@n_maxRSN,
			@c_xml,
			0,
			GETDATE(),
			USER
		)


       END -- 1
    ELSE
        BEGIN -- 2	
			SET @c_Subject = 'AMANDA Comment'
   			IF @c_FolderName > '' 
     				SET @c_Subject = 'AMANDA Comment' + ' ' + @c_FolderName
		 	
     			SELECT  @n_AutoRSN = ISNULL(Max(AutoRSN),0)
     			FROM 	FIFO_Auto_Web
			IF @n_AutoRSN = 0 
				SET @n_AutoRSN = 1
			ELSE
				SET @n_AutoRSN = @n_AutoRSN + 1

			/*	Using  send_mail ('amandai@CityOfDallas.com', EmailAddress, '', msg_subject, msg_body) procedure  */
			/*	to replace insert if sending directly from SMTP server--see IreView 				*/
			INSERT INTO FIFO_Auto_Web
			(
				AutoRSN,
	       		StartAfterDate,
	       		Priority,
				ProcessingType,
				WindowName,
				FolderRSN,
				AttachmentRSN,
				EmailAddress,
				messagesubject ,
				messagebody ,
				ccemailaddress ,
				fromemailaddress ,
				CommentDate,
				StampDate,
				StampUser
			)
			VALUES
			(
				@n_AutoRSN,
				GETDATE(),
				2,
				'EmailToDo-Comm',
				'w_auto_web__send_email',
					@argFolderRSN,
				NULL,
				@v_Email,
				@c_subject,
				NULL,
				'',
				'',
				@argCommentDate,
				GETDATE(),
				@argStampUser
       			)
     END -- 2
		

     
END

GO
