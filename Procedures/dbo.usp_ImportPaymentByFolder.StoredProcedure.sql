USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ImportPaymentByFolder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ImportPaymentByFolder](@FolderRSN INT, @PaymentAmount MONEY, @PaymentType VARCHAR(10), @UserID VARCHAR(8))
AS
BEGIN	

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure creates AccountPayment and AccountPaymentDetail entries */

	DECLARE @dt_BillDate DATETIME
	DECLARE @d_ReceiptDate DATETIME
	DECLARE @n_BillNumber INT
	DECLARE @n_TotalPaidAmount Float
	DECLARE @n_BillBalanceAmount Float
	DECLARE @n_AppliedAmount Float
	DECLARE @f_AppliedAmount_Sum Float
	DECLARE @n_AmountTendered Float
	DECLARE @n_NextReceiptNumber INT
	DECLARE @n_NextPaymentNumber INT
	DECLARE @PeopleRSN INT
	DECLARE @s_PaymentComment VARCHAR(100)

	SET @FolderRSN = 176619
	SET @PaymentAmount = 50
	SET @PaymentType = 'check'
	SET @UserID = 'dbaron'

	SET @n_AmountTendered = @PaymentAmount
	SET @s_PaymentComment = 'This is a test of the payment comment.'
	SET @d_ReceiptDate = getdate()
	SET @f_AppliedAmount_Sum = 0

	SELECT @PeopleRSN = PeopleRSN FROM FolderPeople WHERE FolderRSN = @FolderRSN AND PeopleCode = 322
	SELECT @n_NextReceiptNumber = MAX(ReceiptNumber) + 1 FROM AccountPayment
	SELECT @n_NextPaymentNumber = MAX(PaymentNumber) + 1 FROM AccountPayment

	DECLARE AccountBill_Cur CURSOR FOR
	    SELECT AccountBill.DateGenerated,
		  AccountBill.BillNumber,
		  ISNULL(AccountBill.TotalPaid, 0),
		  ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0)
	      FROM AccountBill
	      WHERE AccountBill.FolderRSN = 176619
		  AND AccountBill.PaidInFullFlag <> 'Y'
		  AND AccountBill.PaidInFullFlag <> 'C'
		  AND ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0) <> 0.00
		  ORDER BY AccountBill.DateGenerated asc

    OPEN AccountBill_Cur
    FETCH AccountBill_Cur INTO
          @dt_BillDate,
          @n_BillNumber,
          @n_TotalPaidAmount,
          @n_BillBalanceAmount

		WHILE @@FETCH_STATUS = 0
		BEGIN
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
          -- Subhash January 20, 2006: DateGenerated is populated from @d_ReceiptDate, rather than GetDate() to match with AccountPayment.PaymentDate
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
				   @n_BillNumber,
                   @n_NextPaymentNumber,
                   @d_ReceiptDate,
                   @n_AppliedAmount,
                   @FolderRSN,
                   'N',
                   getdate(),
                   @UserID)

          /* For Storing Applied Amount in Account Payment */

          SELECT @f_AppliedAmount_Sum = @f_AppliedAmount_Sum + @n_AppliedAmount

          IF @PaymentAmount <= 0
          BEGIN
              BREAK
          END

        FETCH AccountBill_Cur INTO
                @dt_BillDate,
                @n_BillNumber,
                @n_TotalPaidAmount,
                @n_BillBalanceAmount
    END

    CLOSE AccountBill_Cur
    DEALLOCATE AccountBill_Cur

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
                 @s_PaymentComment,
                 @FolderRSN,
                 @n_NextReceiptNumber,
                 NULL,
                 @f_AppliedAmount_Sum,
                 0.00,
                 getdate(),
                 @UserID,
                 @PeopleRSN,
                 'N',
                 'N',
                 'N',
                 1,
                 @n_AmountTendered)

END
GO
