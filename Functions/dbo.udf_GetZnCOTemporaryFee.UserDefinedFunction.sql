USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZnCOTemporaryFee]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZnCOTemporaryFee](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
    /* Used by Infomaker Zoning Fee Report */
    /* Replaced by standard naming convention functions 9/2/2010) */

	DECLARE @TCOBaseFee float
	DECLARE @TCOFee money
	DECLARE @TCOFeePaid money
	DECLARE @varRetVal money

	SELECT @TCOBaseFee = ValidLookup.LookupFee
	  FROM ValidLookup 
	 WHERE ValidLookup.LookupCode = 15
	   AND ValidLookup.Lookup1 = 1

	SELECT @TCOFeePaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
          FROM Folder, AccountBill, AccountBillFee
         WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
           AND Folder.FolderRSN = AccountBill.FolderRSN
           AND AccountBillFee.BillNumber = AccountBill.BillNumber
           AND AccountBill.PaidInFullFlag <> 'C'
           AND AccountBillFee.FeeCode = 162
           AND Folder.FolderRSN = @intFolderRSN

	SELECT @varRetVal = @TCOFeePaid
	RETURN @varRetVal
END

GO
