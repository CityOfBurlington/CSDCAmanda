USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesCOFolderDue]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesCOFolderDue](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
   /* Used by Infomaker Zoning Fee Report */
   /* All FCO-related fees must be billed. */

   DECLARE @FCOFeeExists int 
   DECLARE @FCOFilingFeeExists int
   DECLARE @TCOFeeExists int
   DECLARE @ATFFeeExists int 
   DECLARE @FCOApplicationFee money
   DECLARE @FCOFilingFee money 
   DECLARE @ATFFee money
   DECLARE @TCOFee money 
   DECLARE @FCOFeePaid money
   DECLARE @BalanceDue money

   SELECT @FCOFeeExists = COUNT(*)  
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 160 
         AND Folder.FolderRSN = @intFolderRSN

   SELECT @TCOFeeExists = COUNT(*)  
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 162 
         AND Folder.FolderRSN = @intFolderRSN

   SELECT @FCOFilingFeeExists = COUNT(*)  
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 304 
         AND Folder.FolderRSN = @intFolderRSN

   SELECT @ATFFeeExists = COUNT(*)  
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 166 
         AND Folder.FolderRSN = @intFolderRSN

   IF @FCOFeeExists = 0 
      SELECT @FCOApplicationFee = dbo.udf_GetZoningFeeCalcFinalCO(@intFolderRSN)
   ELSE 
   BEGIN
      SELECT @FCOApplicationFee = SUM(AccountBillFee.FeeAmount) 
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 160 
         AND Folder.FolderRSN = @intFolderRSN
   END

   IF @FCOFilingFeeExists = 0 
      SELECT @FCOFilingFee = dbo.udf_GetZoningFeeCalcFinalCOFilingFee(@intFolderRSN)
   ELSE 
   BEGIN
      SELECT @FCOFilingFee = SUM(AccountBillFee.FeeAmount) 
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 304 
         AND Folder.FolderRSN = @intFolderRSN
   END

   IF @ATFFeeExists = 0 
      SELECT @ATFFee = dbo.udf_GetZoningFeeCalcFinalCOAfterTheFact(@intFolderRSN) 
   ELSE
   BEGIN
      SELECT @ATFFee = SUM(AccountBillFee.FeeAmount) 
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 166 
         AND Folder.FolderRSN = @intFolderRSN
   END 

   IF @TCOFeeExists = 0 SELECT @TCOFee = 0
   ELSE 
   BEGIN
      SELECT @TCOFee = SUM(AccountBillFee.FeeAmount) 
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 162 
         AND Folder.FolderRSN = @intFolderRSN
   END 

   SELECT @FCOFeePaid = ISNULL(SUM(AccountPaymentDetail.PaymentAmount), 0) 
     FROM AccountPaymentDetail
    WHERE BillNumber IN
          ( SELECT AccountBillFee.BillNumber
              FROM Folder, AccountBill, AccountBillFee
             WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
               AND (Folder.FolderRSN = AccountBill.FolderRSN)
               AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
               AND (AccountBill.PaidInFullFlag <> 'C') 
               AND (AccountBillFee.FeeCode IN (160, 162, 166, 304)) 
               AND (Folder.FolderRSN = @intFolderRSN) )

   SELECT @BalanceDue = ( @FCOApplicationFee + @FCOFilingFee + @ATFFee + @TCOFee ) - @FCOFeePaid 
   IF @BalanceDue < 0 SELECT @BalanceDue = 0

   RETURN @BalanceDue
END

GO
