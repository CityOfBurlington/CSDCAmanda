USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesFolderDue]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesFolderDue] (@intFolderRSN INT)
   RETURNS MONEY
AS
BEGIN
   /* Returns Application and Development Review Fee amounts. Used by Infomaker zoning permit forms. */

   DECLARE @SumFeeDue MONEY
   DECLARE @SumPaymentAmount MONEY
   DECLARE @SumRefundAmount MONEY
   DECLARE @NetFeeDue MONEY

   SELECT @SumFeeDue = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
     FROM AccountBillFee ,  AccountBill 
    WHERE ( AccountBillFee.FolderRSN = @intFolderRSN ) 
      AND ( AccountBillFee.FeeCode IN (80,85,86,90,95,100,105,110,130,135,136,145,146,147,150)) 
      AND ( AccountBillFee.FeeAmount IS NOT NULL ) 
      AND ( AccountBill.BillNumber = AccountBillFee.BillNumber ) 
      AND ( AccountBill.PaidInFullFlag <> 'C')

   SELECT @SumPaymentAmount = SUM(AccountPaymentDetail.PaymentAmount) 
     FROM AccountPaymentDetail
    WHERE BillNumber IN
          ( SELECT AccountBillFee.BillNumber
              FROM Folder, AccountBill, AccountBillFee
             WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
               AND (Folder.FolderRSN = AccountBill.FolderRSN)
               AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
               AND (AccountBill.PaidInFullFlag <> 'C') 
               AND (AccountBillFee.FeeCode IN (80,85,86,90,95,100,105,110,130,135,136,145,146,147,150)) 
               AND (Folder.FolderRSN = @intFolderRSN) )

   /* Get any refunds - not sure if this is the correct methodology 8/2010 */

   SELECT @SumRefundAmount =  ISNULL(SUM(AccountPayment.AmountRefunded), 0)
     FROM AccountPayment
    WHERE ( AccountPayment.FolderRSN = @intFolderRSN ) 
      AND ( AccountPayment.NSFFlag  IS NULL OR AccountPayment.NSFFlag = 'N' ) 
      AND ( AccountPayment.VoidFlag IS NULL OR AccountPayment.VoidFlag = 'N' ) 
      AND ( AccountPayment.PaymentAmount IS NOT NULL ) 

   /* Converted data do not have AccountPaymentDetail records, so use 
      AccountPayment, but there is no way to narrow select by FeeCode 
      via BillNumber. */

   IF @SumPaymentAmount IS NULL
   BEGIN
      SELECT @SumPaymentAmount = ISNULL(SUM(AccountPayment.PaymentAmount), 0),
             @SumRefundAmount =  ISNULL(SUM(AccountPayment.AmountRefunded), 0)
     	 FROM AccountPayment
        WHERE ( AccountPayment.FolderRSN = @intFolderRSN ) 
          AND ( AccountPayment.NSFFlag  IS NULL OR AccountPayment.NSFFlag = 'N' ) 
          AND ( AccountPayment.VoidFlag IS NULL OR AccountPayment.VoidFlag = 'N' ) 
          AND ( AccountPayment.PaymentAmount IS NOT NULL ) 
   END

   SELECT @NetFeeDue = ( @SumFeeDue - ( @SumPaymentAmount + @SumRefundAmount ))

   /* For converted data folders that have some, but not all AccountPaymentDetail 
      records, the Net feeDue will be negative, so assume zero is owed. */

   IF ( @NetFeeDue < 0 AND @intFolderRSN < 105535 ) SELECT @NetFeeDue = 0

   RETURN @NetFeeDue
END
GO
