USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesDevelopmentReviewDue]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesDevelopmentReviewDue](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @moneyDRFDue money
	
	SET @moneyDRFDue = 0 

	SELECT @moneyDRFDue = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
	  FROM Folder, AccountBill, AccountBillFee
	 WHERE Folder.FolderRSN = AccountBillFee.FolderRSN 
       AND Folder.FolderRSN = AccountBill.FolderRSN 
	   AND AccountBillFee.BillNumber = AccountBill.BillNumber 
       AND AccountBill.PaidInFullFlag = 'N' 
	   AND AccountBillFee.FeeCode IN (145,146) 
	   AND Folder.FolderRSN = @intFolderRSN 

	RETURN @moneyDRFDue 
END

GO
