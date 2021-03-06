USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCOTotalAmountDue]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetCOTotalAmountDue](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @FCOApplicationFee money
	DECLARE @FCOFeePaid money
	DECLARE @TotalCOPaid money
	DECLARE @TotalCOFees money
	DECLARE @varRetVal money

	SELECT @FCOApplicationFee = dbo.udf_GetZnCOApplicationFee(@intFolderRSN)
	SELECT @TotalCOPaid = dbo.udf_GetCOTotalAmountPaid(@intFolderRSN)
	SELECT @TotalCOFees = dbo.udf_GetCOTotalFees(@intFolderRSN)

	SELECT @FCOFeePaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
          FROM Folder, AccountBill, AccountBillFee
         WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
           AND Folder.FolderRSN = AccountBill.FolderRSN
           AND AccountBillFee.BillNumber = AccountBill.BillNumber
           AND AccountBill.PaidInFullFlag <> 'C'
           AND AccountBillFee.FeeCode IN(160, 304)
           AND Folder.FolderRSN = @intFolderRSN

	IF @FCOFeePaid = 0 
	   SELECT @varRetVal = @FCOApplicationFee
	ELSE 
	   SELECT @varRetVal = @TotalCOFees - @TotalCOPaid

	RETURN @varRetVal
END

GO
