USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB_Late_Charges]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RB_Late_Charges](@FolderYear CHAR(2), @LateFeeComment VARCHAR(100), @DueDate DATETIME, @LateFeeCutoffDate DATETIME) As
BEGIN

/* NOTE: No longer used. Beginning with year 2010, Fee balances are managed through NEMRC. */

DECLARE @FolderRSN INT
DECLARE @BillNumber INT
DECLARE @FeeCode INT
DECLARE @BalanceDue MONEY
DECLARE @AmountPaid MONEY

DECLARE @intNextAccountBillFeeRSN INT
DECLARE @intNextBillNumber INT
DECLARE @dblRentalLateFee FLOAT

DECLARE curFolderBills CURSOR FOR
SELECT DISTINCT Folder.FolderRSN, AccountBill.BillNumber, AccountBillFee.FeeCode 
FROM AccountBill
INNER JOIN Folder ON AccountBill.FolderRSN = Folder.FolderRSN
INNER JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
WHERE ISNULL(AccountBill.PaidInFullFlag, 'N') <> 'Y'
AND Folder.FolderType = 'RB'
AND Folder.FolderYear = @FolderYear

OPEN curFolderBills

FETCH NEXT FROM curFolderBills INTO @FolderRSN, @BillNumber, @FeeCode 

WHILE @@FETCH_STATUS = 0 BEGIN
	/*2010 Rental Reg Fee*/
	IF @FeeCode = 905 BEGIN

		/*Check for Balance Due*/
		SELECT @AmountPaid = SUM(ISNULL(PaymentAmount, 0.00))
		FROM AccountPayment
		WHERE FolderRSN = @FolderRSN
		AND BillToRSN = @BillNumber
		AND ISNULL(VoidFlag, 'N') <> 'Y'

		SELECT @BalanceDue = ISNULL(BillAmount, 0.00) - ISNULL(@AmountPaid, 0.00)
		FROM AccountBill
		WHERE BillNumber = @BillNumber

		IF @BalanceDue > 0 BEGIN

			/*Only if no 2007 Late Charge exists*/ 
			IF NOT EXISTS(SELECT * FROM AccountBillFee WHERE FolderRSN = @FolderRSN AND FeeCode = 209 /*Late Charge*/ AND StampDate > @LateFeeCutoffDate) BEGIN
				SELECT @intNextAccountBillFeeRSN = MAX(AccountBillFee.AccountBillFeeRSN) + 1 FROM AccountBillFee

				SELECT @intNextBillNumber = MAX(AccountBill.BillNumber) + 1 FROM AccountBill

				SELECT @dblRentalLateFee = ValidLookup.LookupFee 
				FROM ValidLookup 
				WHERE (ValidLookup.LookupCode = 16) 
				AND (ValidLookup.Lookup1 = 7)

				INSERT INTO AccountBill
				SELECT 
				@intNextBillNumber, /*BillNumber*/
				GETDATE(), /*DateGenerated*/
				@FolderRSN, /*RB Folder*/
				@dblRentalLateFee, /*Late Fee Amount*/
				0,/*Amount Paid*/
				'N',/*Paid In Full Flag*/
				@LateFeeComment, /*Bill Comment*/
				@DueDate, /*Due Date*/
				GETDATE(), /*Stamp Date*/
				'sa' /*Stamp User*/

				INSERT INTO AccountBillFee 
				(AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
				FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser, FeeComment)
				VALUES
				(@intNextAccountBillFeeRSN, @FolderRSN, 209, 'Y', 
				@dblRentalLateFee, @intNextBillNumber, 0, GETDATE(), 'sa', @LateFeeComment) 

				PRINT CAST(@FolderRSN AS VARCHAR(20)) + ' CHARGED LATE FEE'
				END
			ELSE BEGIN
				PRINT CAST(@FolderRSN AS VARCHAR(20)) + ' ALREADY HAS LATE FEE'
			END

		END

	END

	/*Reset Vars*/
	SET @BalanceDue = 0.00
	SET @AmountPaid = 0.00
	FETCH NEXT FROM curFolderBills INTO @FolderRSN, @BillNumber, @FeeCode 
END

CLOSE curFolderBills
DEALLOCATE curFolderBills

END
GO
