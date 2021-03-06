USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[send_mail_text]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure send_mail_text modified to make is same as oracle */

CREATE PROCEDURE [dbo].[send_mail_text] (@p_from VARCHAR(255), @p_to VARCHAR(500),@p_cc VARCHAR(500), @p_subject VARCHAR(500), @p_message VARCHAR(2000),@argUserId VARCHAR(128))
 AS
  DECLARE  @v_xml VARCHAR(4000),
           @MaxRSN int, 
           @x_RequestXML XML
  BEGIN  
    /* 5.4.4.31: YuMing 2011/12/01 Created from Oracle for SMS-EMAIL Feature */ 
    SET @x_RequestXML = ( SELECT (SELECT @p_to 'To', @p_from 'From', @p_cc 'CC', @p_subject 'Subject',  @p_message 'Body' FOR XML PATH('Email'), type) FOR XML PATH('Command'))
	
    SELECT @v_xml = CAST(@x_RequestXML as varchar(max))
    SELECT @MaxRSN = IsNull(MAX(MessageRSN),0) + 1 FROM Message
    INSERT INTO Message (MessageRSN, CommandXml, StatusCode, StampDate, StampUser)
        VALUES(@MaxRSN, @v_xml, 0, GETDATE(), @argUserId)               
END


GO
