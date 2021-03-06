USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_zoning_folder_fees_due]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_zoning_folder_fees_due] (@argFolderRSN INT)
RETURNS FLOAT
AS
BEGIN
	DECLARE @SumFeeDue NUMERIC(18,2)
	DECLARE @SumPaymentAmount NUMERIC(18,2)
	DECLARE @SumRefundAmount  NUMERIC(18,2)
	DECLARE @NetFeeDue NUMERIC(18,2)

	SELECT @SumFeeDue = SUM( AccountBillFee.FeeAmount ) 
     	FROM AccountBillFee ,  AccountBill 
    	WHERE ( AccountBillFee.FolderRSN = @argFolderRSN ) 
          AND ( AccountBillFee.FeeCode IN (80,85,86,90,95,100,105,130,135,136,145,146,147,150,155)) 
          AND ( AccountBillFee.FeeAmount IS NOT NULL ) 
          AND ( AccountBill.BillNumber = AccountBillFee.BillNumber ) 
          AND ( AccountBill.PaidInFullFlag <> 'C')

	SELECT @SumPaymentAmount = SUM( AccountPaymentDetail.PaymentAmount )
	FROM AccountPaymentDetail
	WHERE BillNumber IN
             (SELECT AccountBillFee.BillNumber
	      FROM Folder, AccountBill, AccountBillFee
              WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	      AND (Folder.FolderRSN = AccountBill.FolderRSN)
	      AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
              AND (AccountBill.PaidInFullFlag <> 'C') 
	      AND (AccountBillFee.FeeCode IN (80,85,86,90,95,100,105,130,135,136,145,146,147,150,155))
	      AND (Folder.FolderRSN = @argFolderRSN))

        /* Converted data do not have AccountPaymentDetail records so use 
           AccountPayment, but there is no way to narrow select by FeeCode 
           via BillNumber. */

        IF @SumPaymentAmount IS NULL
        BEGIN
           SELECT @SumPaymentAmount = SUM(AccountPayment.PaymentAmount),
          	  @SumRefundAmount = SUM(AccountPayment.AmountRefunded)
     	   FROM AccountPayment
    	   WHERE ( AccountPayment.FolderRSN = @argFolderRSN ) 
           AND ( AccountPayment.NSFFlag is null or AccountPayment.NSFFlag = 'N' ) 
           AND ( AccountPayment.VoidFlag is null or AccountPayment.VoidFlag = 'N' ) 
           AND ( AccountPayment.PaymentAmount IS NOT NULL ) 
        END

   	SET @SumFeeDue = ISNULL(@SumFeeDue,0)
   	SET @SumPaymentAmount = ISNULL(@SumPaymentAmount,0)
   	SET @SumRefundAmount = ISNULL(@SumRefundAmount,0)

        SELECT @NetFeeDue = ( @SumFeeDue - ( @SumPaymentAmount + @SumRefundAmount ))

        /* For converted data folders that have some, but not all 
           AccountPaymentDetail records, the Net feeDue will be 
           negative, so assume zero is owed. */

        IF ( @NetFeeDue < 0 AND @argFolderRSN < 105535 ) 
           SELECT @NetFeeDue = 0

   	RETURN @NetFeeDue
END

GO
