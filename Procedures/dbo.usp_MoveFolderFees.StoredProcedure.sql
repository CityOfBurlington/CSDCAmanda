USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_MoveFolderFees]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_MoveFolderFees](@FromFolderRSN INT, @ToFolderRSN INT)
AS
BEGIN
DECLARE @BillNumber INT
DECLARE @PaymentNumber INT
DECLARE @AccountBillFeeRSN INT

/*Get unpaid bills for the folder*/
DECLARE curBills CURSOR FOR
SELECT BillNumber 
FROM AccountBill 
WHERE FolderRSN = @FromFolderRSN 
AND ISNULL(PaidinFullFlag, 'N') = 'N'

OPEN curBills

/*loop through unpaid bills in the old folder*/
FETCH NEXT FROM curBills INTO @BillNumber

WHILE @@FETCH_STATUS = 0
	BEGIN
	/*Get the AccountBillFeeRSN to update AccountGL*/
	SELECT @AccountBillFeeRSN = AccountBillFeeRSN
	FROM AccountBillFee
	WHERE @BillNumber = @BillNumber
	AND FolderRSN= @FromFolderRSN

	/*Get the PaymentNumber to update AccountPayment*/
	SELECT @PaymentNumber = PaymentNumber
	FROM AccountPaymentDetail
	WHERE FolderRSN = @FromFolderRSN
	AND BillNumber = @BillNumber  

	/*Move any payments to the new Folder*/
	UPDATE AccountPayment
	SET FolderRSN =	@ToFolderRSN
	WHERE FolderRSN = @FromFolderRSN
	AND PaymentNumber = @PaymentNumber

	UPDATE AccountPaymentDetail
	SET FolderRSN =	@ToFolderRSN
	WHERE FolderRSN = @FromFolderRSN
	AND PaymentNumber = @PaymentNumber
	AND BillNumber = @BillNumber

	/*Move the bill with any unpaid fees to the new Folder*/
	UPDATE AccountBill 
	SET FolderRSN = @ToFolderRSN 
	WHERE FolderRSN = @FromFolderRSN 
	AND BillNumber = @BillNumber

	UPDATE AccountBillFee
	SET FolderRSN = @ToFolderRSN 
	WHERE FolderRSN = @FromFolderRSN 
	AND BillNumber = @BillNumber

	/*Update the GL*/
	UPDATE AccountGL 
	SET FolderRSN = @ToFolderRSN
	WHERE FolderRSN = @FromFolderRSn
	AND AccountBillFeeRSN = @AccountBillFeeRSN

	/*Reset these in the loop before the next bill number*/
	SET @AccountBillFeeRSN = NULL
	SET @PaymentNumber = NULL

	FETCH NEXT FROM curBills INTO @BillNumber
END

CLOSE curBills
DEALLOCATE curBills

END

GO
