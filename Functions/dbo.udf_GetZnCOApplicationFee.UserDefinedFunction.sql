USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZnCOApplicationFee]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetZnCOApplicationFee](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
    /* Used by Infomaker Zoning Fee Report */
    /* Replaced by standard naming convention function 
       dbo.udf_GetZoningFeeCalcFinalCO (9/2/2010) */
	DECLARE @InDate datetime
	DECLARE @IssueDate datetime
	DECLARE @FCOBaseFee float
	DECLARE @FCOFeeRate float
	DECLARE @FCOFilingFee float 
	DECLARE @FCOFee money
	DECLARE @ApplicationFee money
	DECLARE @FCOFeePaid money
	DECLARE @varRetVal money

	SELECT @InDate = Folder.Indate, 
	       @IssueDate = Folder.IssueDate
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

	SELECT @FCOFilingFee = ValidLookup.LookupFee
	  FROM ValidLookup 
	 WHERE ValidLookup.LookupCode = 15
	   AND ValidLookup.Lookup1 = 4

	SELECT @ApplicationFee = SUM(AccountBillFee.FeeAmount)
          FROM Folder, AccountBill, AccountBillFee
         WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
           AND Folder.FolderRSN = AccountBill.FolderRSN
           AND AccountBillFee.BillNumber = AccountBill.BillNumber
           AND AccountBill.PaidInFullFlag <> 'C'
           AND AccountBillFee.FeeCode IN(85,86,90,95,100,105,130,135,136,147)
           AND Folder.FolderRSN = @intFolderRSN

	SELECT @FCOFeePaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
          FROM Folder, AccountBill, AccountBillFee
         WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
           AND Folder.FolderRSN = AccountBill.FolderRSN
           AND AccountBillFee.BillNumber = AccountBill.BillNumber
           AND AccountBill.PaidInFullFlag <> 'C'
           AND AccountBillFee.FeeCode IN(160, 304)
           AND Folder.FolderRSN = @intFolderRSN

	/* Zoning permits converted from the previous Access database 
	   issued after July 1, 1998, have a $14 filing fee included in 
	   application fee. */

	IF @intFolderRSN < 105535 AND @InDate >= '7/1/1998'
	SELECT @ApplicationFee = @ApplicationFee - 14

	IF @FCOFeePaid > 0 
	   SELECT @varRetVal = @FCOFeePaid
	ELSE
	BEGIN
	   SELECT @FCOFee = @FCOBaseFee + ( @ApplicationFee * @FCOFeeRate )
	   IF ( @InDate < '7/1/1998 00:00:00' OR @InDate > '7/1/2009 00:00:00' )
	      SELECT @varRetVal = @FCOFee + @FCOFilingFee
	   ELSE SELECT @varRetVal = @FCOFee
	END
	RETURN @varRetVal
END


GO
