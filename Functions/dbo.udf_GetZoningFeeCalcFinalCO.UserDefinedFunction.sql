USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeeCalcFinalCO]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeeCalcFinalCO](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
   /* Calculates a Zoning Final CO application fee, or returns the existing 
      and billed FCO fee amount.*/
   /* All FCO-related fees must be billed. */
   /* The Final CO Filing Fee is calculated by dbo.udf_GetZoningFeeCalcFinalCOFilingFee */

   DECLARE @FolderType varchar(4)
   DECLARE @InDate datetime
   DECLARE @FCOBaseFee float
   DECLARE @FCOFeeRate float
   DECLARE @varCOFlag varchar(2) 
   DECLARE @FCOFeeExists int
   DECLARE @PermitApplicationFee money 
   DECLARE @FCOFee money 
   
   SET @FCOFee = 0

   SELECT @FolderType = Folder.FolderType, 
          @InDate = Folder.Indate 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @FCOBaseFee = ValidLookup.LookupFee
     FROM ValidLookup 
    WHERE ValidLookup.LookupCode = 15
      AND ValidLookup.Lookup1 = 2

   SELECT @FCOFeeRate = ValidLookup.LookupFee
     FROM ValidLookup 
    WHERE ValidLookup.LookupCode = 15
      AND ValidLookup.Lookup1 = 3

   SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intFolderRSN)

   SELECT @FCOFeeExists = COUNT(*)  
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBill.PaidInFullFlag <> 'C'
      AND AccountBillFee.FeeCode = 160 
      AND Folder.FolderRSN = @intFolderRSN

   IF @FCOFeeExists > 0
   BEGIN
      SELECT @FCOFee = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C'
         AND AccountBillFee.FeeCode = 160 
         AND Folder.FolderRSN = @intFolderRSN
   END
   ELSE
   BEGIN
      IF @FolderType = 'ZZ'       /* Historic fees are not billed */
      BEGIN 
         SELECT @PermitApplicationFee = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
           FROM AccountBillFee
          WHERE AccountBillFee.FolderRSN = @intFolderRSN
            AND AccountBillFee.FeeCode = 155
      END
      ELSE
      BEGIN
         SELECT @PermitApplicationFee = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
           FROM Folder, AccountBill, AccountBillFee
          WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
            AND Folder.FolderRSN = AccountBill.FolderRSN
            AND AccountBillFee.BillNumber = AccountBill.BillNumber
            AND AccountBill.PaidInFullFlag <> 'C'
            AND AccountBillFee.FeeCode IN(85, 86, 90, 95, 100, 105, 130, 135, 136, 147)
            AND Folder.FolderRSN = @intFolderRSN
      END

      /* Data imported into Amanda:  Starting or after 7/1/1998 (FY99), the 
         CO filing fee was charged at permit application. This practice was 
         discontinued starting July 1, 2009 (FY10), and the filing fee was 
         charged at CO request. 
         For permits converted from Access/DBase, filing fees were added to the 
         application fee field (there was not a separate filing fee field). 
         During this time the filing fee was $7 per page. Therefore a total of 
         $14 should be subtracted from the application fee for the purpose of 
         calculating the CO request fee. 
         The benchmark Amanda zoning folder (first one initialized) is RSN 105535. */

      IF @intFolderRSN < 105535 AND @InDate >= '7/1/1998 00:00:00'
         SELECT @PermitApplicationFee = @PermitApplicationFee - 14

      IF @varCOFlag = 'N' SELECT @FCOFee = 0
      ELSE SELECT @FCOFee = @FCOBaseFee + ( @PermitApplicationFee * @FCOFeeRate )
   END

   RETURN @FCOFee
END


GO
