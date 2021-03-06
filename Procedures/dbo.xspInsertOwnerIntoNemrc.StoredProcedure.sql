USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspInsertOwnerIntoNemrc]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspInsertOwnerIntoNemrc](@strParcelID VARCHAR(20))
AS
BEGIN
/*
	Return Values
		1 = Success
		0 = Failed
*/
DECLARE @intInvokeSuccess INT
DECLARE @intComHandle INT
DECLARE @strErrorSource VARCHAR(8000)
DECLARE @strErrorDescription VARCHAR(8000)
DECLARE @intReturnVal VARCHAR(1000)

/*Invoke component*/
EXEC @intInvokeSuccess = sp_OACreate 'AmandaActiveX.NEMRC', @intComHandle OUTPUT

IF (@intInvokeSuccess <> 0)
	BEGIN
	/*Trap errors if any*/
	EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
	SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
	RETURN
END

/*Call a method from the component*/
EXEC @intInvokeSuccess = sp_OAMethod @intComHandle, 'InsertToNemrcFromAssessPro', @intReturnVal OUTPUT, @pParcelID=@strParcelID

IF (@intInvokeSuccess <> 0)
	BEGIN
	/*Trap errors if any*/
	EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
	SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
	RETURN
END

/*Destroy the object from server memory*/
EXEC sp_OADestroy @intComHandle

END
GO
