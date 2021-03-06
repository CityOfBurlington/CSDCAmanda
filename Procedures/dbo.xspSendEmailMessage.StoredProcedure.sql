USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspSendEmailMessage]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspSendEmailMessage] (@fromAddress VARCHAR(100),
	@fromDescription VARCHAR(500),
	@toEmailRecipients VARCHAR(1000),
	@Subject VARCHAR(200), 
	@Body VARCHAR(2000),
	@emailAttachments VARCHAR(200))
AS
BEGIN

	/*
		Return Values
			0 = Success
			1 = Failed
	*/
	DECLARE @intInvokeSuccess INT
	DECLARE @intComHandle INT
	DECLARE @strErrorSource VARCHAR(8000)
	DECLARE @strErrorDescription VARCHAR(8000)
	DECLARE @intReturnVal BIT

	/*Invoke component*/
	EXEC @intInvokeSuccess = sp_OACreate 'CityActiveX.VBFunctions', @intComHandle OUTPUT

	IF (@intInvokeSuccess <> 0)
		BEGIN
		/*Trap errors if any*/
		EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
		SET @strErrorDescription = 'Invoke Method ' + @strErrorDescription
		SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
		RETURN
	END

	/*Call a method from the component*/
	EXEC @intInvokeSuccess = sp_OAMethod @intComHandle, 'SendEmailMessage', @intReturnVal OUTPUT, 
	@fromAddress=@fromAddress, 
	@fromDescription=@fromDescription,
	@toEmailRecipients=@toEmailRecipients, 
	@Subject=@Subject, 
	@Body=@Body,
	@emailAttachments = @emailAttachments

	IF (@intInvokeSuccess <> 1)
		BEGIN
		/*Trap errors if any*/
		EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
		SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
		RETURN
	END

	/*Destroy the object from server memory*/
	EXEC sp_OADestroy @intComHandle

	/*Return method output*/
	SELECT @intReturnVal

END



GO
