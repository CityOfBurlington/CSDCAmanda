USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[webservices_SendEmailWithCc]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[webservices_SendEmailWithCc](@emailSubject VARCHAR(400), @emailBody VARCHAR(8000), 
	@FromAddress VARCHAR(400), @FromDescription VARCHAR(400), @ToAddress VARCHAR(2000), 
	@CcAddress VARCHAR(2000), @BccAddress VARCHAR(2000), @Attachments VARCHAR(2000))
AS
BEGIN
	DECLARE @error VARCHAR(8000)
	DECLARE @response varchar(8000) 

	DECLARE @SQL nVARCHAR(4000)
	DECLARE @MessageId INT

	SET @emailSubject = REPLACE(@emailSubject, '&', '+')
	SET @emailBody = REPLACE(@emailBody, '&', '+')
	SET @FromAddress = REPLACE(@FromAddress, '&', '+')
	SET @FromDescription = REPLACE(@FromDescription, '&', '+')
	SET @ToAddress = REPLACE(@ToAddress, '&', '+')
	SET @CcAddress = REPLACE(@CcAddress, '&', '+')
	SET @BccAddress = REPLACE(@BccAddress, '&', '+')
	SET @Attachments = REPLACE(@Attachments, '&', '+')

	INSERT INTO [IntranetApplications].[dbo].[EmailMessages] ([EmailSubject],[EmailBody],[FromAddress],[FromDescription],[ToAddress],[CcAddress],[BccAddress],[Attachments])
    VALUES (@emailSubject, @emailBody, @FromAddress, @FromDescription, @ToAddress, @CcAddress, @BccAddress, @Attachments)

	SELECT @MessageId=@@IDENTITY

	SET @SQL = 'http://cobintranet:81/WebServices.aspx?Action=SendEmailId&MessageId=' + CAST( @MessageId AS VARCHAR(20))

	EXEC HTTP_POST @SQL, @response, @error

END










GO
