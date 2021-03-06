USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspScheduleInspection]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[xspScheduleInspection](@pUserID VARCHAR(8), @pFolderRSN INT, @pProcessRSN INT, @pAttemptRSN INT, @pAttemptCount INT, @pDatabase INT)
AS
BEGIN
/*
	DatabaseEnum Values
		10 = Amanda_Development
		20 = Amanda_Production

	Return Values
		0 = Success
		1 = Failed to create document
		2 = Failed to attach document to folder
		3 = Could not access Calendar
		4 = Could not create Crystal object
*/
DECLARE @intInvokeSuccess INT
DECLARE @intComHandle INT
DECLARE @strErrorSource VARCHAR(8000)
DECLARE @strErrorDescription VARCHAR(8000)
DECLARE @intReturnVal INT

/*Invoke component*/
EXEC @intInvokeSuccess = sp_OACreate 'AmandaActiveX.CodeEnforcement', @intComHandle OUTPUT

IF (@intInvokeSuccess <> 0)
	BEGIN
	/*Trap errors if any*/
	EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
	SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
	RETURN
END

/*Call a method from the component*/
EXEC @intInvokeSuccess = sp_OAMethod @intComHandle, 'ScheduleInspection', @intReturnVal OUTPUT, @pUserID=@pUserID, @pFolderRSN=@pFolderRSN, @pProcessRSN=@pProcessRSN, @pAttemptRSN=@pAttemptRSN, @pAttemptCount=@pAttemptCount, @pDatabase=@pDatabase

IF (@intInvokeSuccess <> 0)
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
