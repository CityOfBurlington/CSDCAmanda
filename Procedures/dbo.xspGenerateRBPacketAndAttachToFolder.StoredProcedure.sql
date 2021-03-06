USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspGenerateRBPacketAndAttachToFolder]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[xspGenerateRBPacketAndAttachToFolder](@FolderRSN INT)
AS
BEGIN
DECLARE @intInvokeSuccess INT
DECLARE @intComHandle INT
DECLARE @strErrorSource VARCHAR(8000)
DECLARE @strErrorDescription VARCHAR(8000)
DECLARE @intReturnVal INT

/*Invoke component*/
/*
EXEC @intInvokeSuccess = sp_OACreate 'AmandaActiveX.RentalRegistration', @intComHandle OUTPUT
*/

DECLARE @PeopleRSN INT

SELECT @PeopleRSN = CAST(ReferenceFile AS INT) FROM Folder WHERE FolderRSN = @FolderRSN

EXEC @intInvokeSuccess = sp_OACreate 'RentalBilling.RBBill', @intComHandle OUTPUT


IF (@intInvokeSuccess <> 0)
	BEGIN
	/*Trap errors if any*/
	EXEC sp_OAGetErrorInfo @intComHandle, @strErrorSource OUTPUT, @strErrorDescription OUTPUT
	SELECT [Error Source] = @strErrorSource, [Description] = @strErrorDescription
	RETURN
END

/*Call a method from the component*/
EXEC @intInvokeSuccess = sp_OAMethod @intComHandle, 'GenerateInvoice', @intReturnVal OUTPUT, @pPeopleRSN=@PeopleRSN

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
