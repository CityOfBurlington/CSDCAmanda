USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[SEND_SMS]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure SEND_SMS modified to make is same as oracle */

CREATE Procedure [dbo].[SEND_SMS](@argMobileNumber VARCHAR(32), @argText VARCHAR(2000), @argUserId VARCHAR(128))
AS
DECLARE @v_xml varChar(4000),
        @MessageRSN INT,
        @x_RequestXML XML
BEGIN 
    /* 5.4.4.31: YuMing 2011/12/01 added escape for constructing XML  */
    /* YuMing 2011/06/29  Converted from Oracle procedure  */
	/* Venkat Modified 2011/06/10 - based on the new SMS adaptor this procedure modified to insert the value in Messaging table */
	/* ESS Created 2008/06/11: To Send SMS On Process Assign During Insert/Update*/
	SET @x_RequestXML = (SELECT 
		(SELECT @argMobileNumber 'To', @argText 'Text' FOR XML PATH('SMS'), type)
		FOR XML PATH('Command'))

	SELECT @v_xml = CAST(@x_RequestXML as varchar(max))
    SELECT  @MessageRSN = MAX(MessageRSN) FROM Message
    SELECT  @MessageRSN  = ISNULL(@MessageRSN ,0) + 1  
	INSERT INTO Message (MessageRSN, CommandXml, StatusCode, StampDate, StampUser)
		VALUES(@MessageRSN, @v_xml, 0, getdate(), @argUserId);
END


GO
