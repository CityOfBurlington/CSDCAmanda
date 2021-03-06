USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPermitAmountPaid]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetPermitAmountPaid](@intFolderRSN INT) RETURNS MONEY
AS 
BEGIN
	DECLARE @dblRetVal MONEY

	SET @dblRetVal = 0

	SELECT @dblRetVal = @dblRetVal + SUM(ISNULL(PaymentAmount, 0))
	FROM AccountPaymentDetail
	WHERE BillNumber IN
          (SELECT AccountBillFee.BillNumber
	   FROM Folder, AccountBill, AccountBillFee
	   WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	   AND (Folder.FolderRSN = AccountBill.FolderRSN)
	   AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
           AND (AccountBill.PaidInFullFlag <> 'C') 
	   AND (AccountBillFee.FeeCode IN (80,85,86,90,95,100,105,130,135,136,147))
	   AND (Folder.FolderRSN = @intFolderRSN))
	
	RETURN ISNULL(@dblRetVal, 0)
END


GO
