USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesTempCO]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesTempCO](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
   /* Returns TCO fees that are billed */
   /* Used by Infomaker Zoning Fee Report, and Temp CO Word Mailmerge document. */

   DECLARE @TCOBaseFee float
   DECLARE @moneyTotalTCOFees money

   SELECT @TCOBaseFee = ValidLookup.LookupFee
     FROM ValidLookup 
    WHERE ValidLookup.LookupCode = 15
      AND ValidLookup.Lookup1 = 1

   SELECT @moneyTotalTCOFees = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBill.PaidInFullFlag <> 'C'
      AND AccountBillFee.FeeCode = 162      /* Temp CO Fee */
      AND Folder.FolderRSN = @intFolderRSN

   RETURN @moneyTotalTCOFees
END

GO
