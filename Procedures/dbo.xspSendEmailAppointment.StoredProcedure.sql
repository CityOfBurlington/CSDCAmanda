USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspSendEmailAppointment]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspSendEmailAppointment](
	@FromEmailAddress		VARCHAR(100),
	@FromDiplayName			VARCHAR(500),
	@ToAttendeeEmail		VARCHAR(100),
	@Subject      			VARCHAR(1000),
	@Body					VARCHAR(2000),
	@apptLocation			VARCHAR(200), 
	@startDateTime			VARCHAR(20),
	@endDateTime			VARCHAR(20)
)
AS
BEGIN

DECLARE @intInvokeSuccess INT
DECLARE @intComHandle INT
DECLARE @strErrorSource VARCHAR(8000)
DECLARE @strErrorDescription VARCHAR(8000)
DECLARE @intReturnVal INT

SET @intInvokeSuccess = 0

/* Email doesn't go if the Body has an ampersand (&) in it. So replace it with '+'. Do the same for Subject, just in case...*/
SET @Body = REPLACE(@Body, '&', '+')
SET @Subject = REPLACE(@Subject, '&', '+')

--Invoke component
EXEC @intInvokeSuccess = sp_OACreate 'CityActiveX.VBFunctions', @intComHandle OUTPUT

IF (@intInvokeSuccess <> 0)
BEGIN
	-- Trap errors if any
	EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
	SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
	RETURN
END

-- Call a method from the component
-- DB - 9/10/2009 - Created to call new method for MS Exchange version.
	EXEC @intInvokeSuccess = sp_OAMethod @intComHandle, 'SendEmailAppointment', @intReturnVal OUTPUT, 
	@fromEmailAddress=@FromEmailAddress,
	@fromDisplayName=@FromDiplayName,
	@toAttendeeEmail=@ToAttendeeEmail,
	@subject=@Subject,
	@body=@Body,
	@apptLocation=@apptLocation,
	@startDateTime=@startDateTime,
	@endDateTime=@endDateTime

IF (@intInvokeSuccess <> 0)
	BEGIN
	-- Trap errors if any
	EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
	SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
	RETURN
END

--Destroy the object from server memory
EXEC sp_OADestroy @intComHandle

--Return method output
SELECT @intReturnVal
END














GO
