USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesDevelopmentReview]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesDevelopmentReview](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
    /* Used by Infomaker zoning permit forms */
	DECLARE @moneyDRFFeesPaid MONEY

	SELECT @moneyDRFFeesPaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
	  FROM Folder, AccountBill, AccountBillFee
	 WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
       AND (Folder.FolderRSN = AccountBill.FolderRSN)
	   AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
       AND (AccountBill.PaidInFullFlag <> 'C') 
	   AND (AccountBillFee.FeeCode IN (145,146))
	   AND (Folder.FolderRSN = @intFolderRSN);

	RETURN @moneyDRFFeesPaid
END


GO
