USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ImportPaymentByBill]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ImportPaymentByBill]--(@BillNumber INT, @PaymentAmount MONEY, @PaymentDate DATETIME, @PaymentType VARCHAR(10), @UserID VARCHAR(8))
AS
BEGIN	

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure creates AccountPayment and AccountPaymentDetail entries */

	DECLARE @dt_BillDate DATETIME
	DECLARE @PaidInFullFlag CHAR(1)
	DECLARE @d_ReceiptDate DATETIME
	DECLARE @BillNumber INT
	DECLARE @PaymentAmount MONEY
	DECLARE @PaymentDate DATETIME
	DECLARE @PaymentType VARCHAR(10)
	DECLARE @UserID VARCHAR(10)
	DECLARE @n_TotalPaidAmount Float
	DECLARE @n_BillBalanceAmount Float
	DECLARE @n_AppliedAmount Float
	DECLARE @n_AmountTendered Float
	DECLARE @n_NextReceiptNumber INT
	DECLARE @n_NextPaymentNumber INT
	DECLARE @PeopleRSN INT
	DECLARE @FolderRSN INT
	DECLARE @PaymentComment VARCHAR(100)
	DECLARE @FeeCode VARCHAR(10)
	DECLARE @QuitProcessing INT

	SET @UserID = 'sa'

	DECLARE ImportFile_Cur CURSOR FOR
		SELECT BillNumber, PaymentAmount, PaymentType, PaymentComment, PaymentDate, FeeCode
		  FROM tblImportPayments WHERE ImportedFlag IS NULL AND ImportNote IS NULL

	OPEN ImportFile_Cur
	FETCH ImportFile_Cur INTO
		@BillNumber,
		@PaymentAmount,
		@PaymentType,
		@PaymentComment,
		@PaymentDate,
		@FeeCode

	WHILE @@FETCH_STATUS = 0 
	BEGIN

		SET @QuitProcessing = 0

		IF NOT EXISTS
				(SELECT FolderRSN FROM AccountBill WHERE AccountBill.BillNumber = @BillNumber)
		BEGIN 
			UPDATE tblImportPayments SET ImportNote = ISNULL(ImportNote, '') + 'Bill Not Found' WHERE BillNumber = @BillNumber
			SET @QuitProcessing = 1
		END
		ELSE
		BEGIN
			SELECT @dt_BillDate = AccountBill.DateGenerated,
			  @FolderRSN = FolderRSN, 
			  @PaidInFullFlag = PaidInFullFlag,
			  @n_TotalPaidAmount= ISNULL(AccountBill.TotalPaid, 0),
			  @n_BillBalanceAmount = ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0)
			  FROM AccountBill
			  WHERE AccountBill.BillNumber = @BillNumber
		END

		/* Check for canceled or paid bills */
		IF @PaidInFullFlag = 'Y'
		BEGIN
			UPDATE tblImportPayments SET ImportNote = ISNULL(ImportNote, '') + 'Bill Already Paid' WHERE BillNumber = @BillNumber
			SET @QuitProcessing = 1
		END
		IF @PaidInFullFlag = 'C'
		BEGIN
			UPDATE tblImportPayments SET ImportNote = ISNULL(ImportNote, '') + 'Bill Canceled' WHERE BillNumber = @BillNumber
			SET @QuitProcessing = 1
		END

		IF @QuitProcessing = 0
			BEGIN
			SET @n_AmountTendered = @PaymentAmount
			SET @d_ReceiptDate = getdate()

			SELECT @PeopleRSN = PeopleRSN FROM FolderPeople WHERE FolderRSN = @FolderRSN AND PeopleCode = 322
			SELECT @n_NextReceiptNumber = MAX(ReceiptNumber) + 1 FROM AccountPayment
			SELECT @n_NextPaymentNumber = MAX(PaymentNumber) + 1 FROM AccountPayment

			IF @PaymentAmount > @n_BillBalanceAmount
					/* if the paymentamount is greater then
					apply it into the bill and reduce the payment amount */
			BEGIN
				SELECT @n_AppliedAmount = @n_BillBalanceAmount
				SELECT @PaymentAmount = @PaymentAmount - @n_AppliedAmount
			END
			ELSE
			BEGIN
				SELECT @n_AppliedAmount = @PaymentAmount
				SELECT @PaymentAmount = 0
			END

				/* Insert AppliedAmount with bill details Into AccountPaymentDetail */
			INSERT INTO AccountPaymentDetail
						(BillNumber,
						PaymentNumber,
						DateGenerated,
						PaymentAmount,
						FolderRSN,
						ReverseEntryFlag,
						StampDate,
						StampUser)
			VALUES (
						@BillNumber,
						@n_NextPaymentNumber,
						@d_ReceiptDate,
						@n_AppliedAmount,
						@FolderRSN,
						'N',
						getdate(),
						@UserID)

			INSERT INTO AccountPayment
						(PaymentNumber,
						 PaymentType,
						 PaymentDate,
						 PaymentAmount,
						 PaymentComment,
						 FolderRSN,
						 ReceiptNumber,
						 DateReceiptPrinted,
						 AmountApplied,
						 AmountRefunded,
						 StampDate,
						 StampUser,
						 BillToRSN,
						 NSFFlag,
						 NSFServiceChargeFlag,
						 VoidFlag,
						 CurrencyRate,
						 AmountTendered)
			VALUES (
						 @n_NextPaymentNumber,
						 @PaymentType,
						 @d_ReceiptDate,
						 @n_AmountTendered,
						 @PaymentComment,
						 @FolderRSN,
						 @n_NextReceiptNumber,
						 NULL,
						 @n_AppliedAmount,
						 0.00,
						 getdate(),
						 @UserID,
						 @PeopleRSN,
						 'N',
						 'N',
						 'N',
						 1,
						 @n_AmountTendered)

			Exec DefaultPayment_RB @FolderRSN, @UserID, @n_NextPaymentNumber, NULL

			UPDATE tblImportPayments
			SET ImportedFlag = 'Y',
				ImportedDate = getdate()
			WHERE BillNumber = @BillNumber
		END

		FETCH ImportFile_Cur INTO
			@BillNumber,
			@PaymentAmount,
			@PaymentType,
			@PaymentComment,
			@PaymentDate,
			@FeeCode
	END

	CLOSE ImportFile_Cur
	DEALLOCATE ImportFile_Cur

END
GO
