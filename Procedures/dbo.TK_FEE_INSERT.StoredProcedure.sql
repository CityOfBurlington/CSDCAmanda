USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_FEE_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TK_FEE_INSERT]
@argFolderRSN int, 
@argFeeCode int, 
@argFeeAmount float, 
@DUserID varchar(1000), 
@argFeeComment varchar(1000) = NULL,
@argBilLFlag int = 0,
@argExportFlag int = 0

AS

DECLARE @accountBillFeeRSN int
DECLARE @n_billNumber int
DECLARE @BillDate DATETIME

BEGIN
	SELECT @accountBillFeeRSN = ISNULL(max(accountBillFeeRSN),0)+1
	FROM accountBillFee

	INSERT INTO AccountBillFee
	(AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag,
	FeeAmount,FeeComment,
	BillNumber, BillItemSequence, StampDate, StampUser )
	VALUES 
	(@accountBillFeeRSN, @argFolderRSN, @argFeeCode, 'Y',
	@argfeeAmount, @argFeeComment,
	0, 0, getDate(), @DuserID );

	IF @argBilLFlag = 1
	BEGIN
	
		SELECT @n_billNumber = ISNULL(max(billNumber),0)+1
		FROM accountBill
		SET @BillDate = getdate()
		INSERT INTO AccountBill(billnumber, folderRSN, dateGenerated, billAmount, totalPaid, paidInFullFlag, billDesc, stampDate, stampUser)
		VALUES(@n_billNumber,@argFolderRSN, getdate(), @argfeeAmount , 0, 'N',dbo.f_FolderNumber(@argFolderRSN),getdate(), @DUserID);

		UPDATE accountBillFee
		SET billNumber = @n_BillNumber
		WHERE folderRSN = @argFolderRSN
		AND accountBillFeeRSn = @accountBillFeeRSN

		/* NOTE: Only allow fee to be exported if it has been billed. */
		IF @argExportFlag = 1
		BEGIN
			EXEC usp_ExportFee @AccountBillFeeRSN, @argFolderRSN, @argFeeCode, @argFeeAmount, @argFeeComment, @n_billNumber, @BillDate
		END
	END
END
GO
