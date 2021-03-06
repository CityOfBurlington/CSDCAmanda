USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PC_FEE_INSERT]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PC_FEE_INSERT]
(@argFolderRSN int, 
@argFeeCode int, 
@argFeeAmount float, 
@DUserID varchar(1000), 
@argNewFeeFlag int=0, 
@argFeeComment varchar(1000)=NULL, 
@argBillFlag int=0, 
@argExportFlag int = 0)


/* 

argNewFeeFlag:
   1 = always insert new fee regardless if the fee already exists.
   otherwise = check first to see if the fee is already on the folder.

argBillFlag (passed to TK_INSERT_FEE):
   1 = create a bill for the fee
   otherwise = don't create bill
   
argExportFlag (passed to TK_INSERT_Fee):
   1 = Export the fee to AP
   otherwise = don't export the fee.

*/
AS
BEGIN

DECLARE @accountBillFeeRSN int
DECLARE @v_errrorDesc varchar(2000)
DECLARE @n_feeCount int
DECLARE @v_feeDesc varchar(1000)
DECLARE @n_feeRSN int
DECLARE @n_amountPaid float
DECLARE @n_feeAmt float

DECLARE @i_amountPaid int

IF @argFeeAmount IS NULL
BEGIN
	SET @v_errrorDesc = 'A NULL Fee Amount has been calculated for Fee Code '+ cast(@argFeeCode as varchar)+' Please Contact your AMANDA Administrator'
	RAISERROR(@v_errrorDesc,16,-1)
END

IF @argNewFeeFlag = 1 --we always insert a new row regardless if the fee already exists on the folder
BEGIN
	exec tk_fee_insert @argFolderRSn, @argFeeCode, @argFeeAmount, @DUserID, @argFeeComment, @argBillFlag, @argExportFlag
END

ELSE --need to check to see if the fee is already on the folder
BEGIN

	SELECT @n_feeCount = count(*)
	FROM accountBIllFee
	WHERE folderRSN = @argFolderRSN
	AND feeCode = @argFeeCode
	AND billNumber = 0

	IF @n_feeCount > 1
	BEGIN
		SELECT @v_feeDesc =validAccountFee.feeDesc
		FROM validAccountFee
		WHERE feeCode = @argFeeCode

		SET @v_errrorDesc = 'You can only have one unbilled '+ @v_feeDesc+' per Folder, please update the Folder Fees'
		RAISERROR(@v_errrorDesc,16,-1)
	END

	SELECT @n_feeRSN = max(accountBillFeeRSN)
	FROM accountBillFee
	WHERE folderRSN = @argFolderRSN
	AND feeCode = @argFeeCode
	AND billNumber = 0
	
	--get the total of what has been billed and not cancelled
	SELECT @n_amountPaid = ISNULL(sum(accountBillFee.feeAmount),0)
	FROM accountBillFee, accountBill
	WHERE accountBill.folderRSN = @argFolderRSN
	AND accountBill.billNumber = accountBillFee.billNumber
	AND accountBill.paidInFullFlag <> 'C'
	AND accountBillFee.feeCode = @argFeeCode
	
	IF @n_amountPaid = 0 AND @n_feeRSN IS NULL --insert new fee
	BEGIN
		IF @argFeeAmount != 0  --do not insert fees that are for $0
		BEGIN
			exec tk_fee_insert @argFolderRSn, @argFeeCode, @argFeeAmount, @DUserID, @argFeeComment, @argBillFlag, @argExportFlag
		END
	END 

	ELSE IF @n_amountPaid = 0 AND @n_feeRSN IS NOT NULL --update fee
	BEGIN
  
		IF @argFeeAmount = 0 --remove fee if it is $0
		BEGIN				 
			DELETE FROM accountBillFee WHERE accountBillFeeRSN = @n_feeRSN;
		END
		ELSE
		BEGIN
			exec tk_fee_Update @n_feeRSN, @argFeeAmount
		END
	END
	
	ELSE IF @n_amountPaid != 0 AND @n_feeRSN IS NULL -- insert new fee for adj amt
	BEGIN
		SET @n_feeAmt =  -1*(@n_amountPaid - @argFeeAmount)

		IF @n_feeAmt !=0
		BEGIN
			exec tk_fee_insert @argFolderRSn, @argFeeCode, @n_feeAmt, @DUserID, @argFeeComment, @argBillFlag, @argExportFlag
		END
	END
	
	ELSE -- update existing fee with the adjusted amt
	BEGIN
		SET @n_feeAmt =  -1*(@n_amountPaid - @argFeeAmount)

		IF @n_feeAmt !=0
		BEGIN
			exec tk_fee_Update @n_feeRSN, @n_feeAmt
		END
		ELSE
		BEGIN
			DELETE FROM accountBillFee
			WHERE folderRSN = @argFolderRSN
			AND billNumber = 0
			AND feeCode = @argFeeCode
		END
	END

END

END

GO
