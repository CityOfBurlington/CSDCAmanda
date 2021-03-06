USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCOTotalAmountPaid]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetCOTotalAmountPaid](@intFolderRSN INT) RETURNS MONEY
AS 
BEGIN
    /* Used by Infomaker ZOning Fee Report form - called by 
       dbo.GetCO TotalAmount Due */
    /* No longer used - replaced by dbo.udf_GetZoningFeesCOFolderDue */
	DECLARE @dblRetVal MONEY

	SET @dblRetVal = 0

	SELECT @dblRetVal = @dblRetVal + SUM(ISNULL(AccountPaymentDetail.PaymentAmount,0))
	FROM AccountPaymentDetail
	WHERE BillNumber IN
          (SELECT AccountBillFee.BillNumber
	   FROM Folder, AccountBill, AccountBillFee
	   WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	   AND (Folder.FolderRSN = AccountBill.FolderRSN)
	   AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
           AND (AccountBill.PaidInFullFlag <> 'C') 
	   AND (AccountBillFee.FeeCode IN (160, 162, 304))
	   AND (Folder.FolderRSN = @intFolderRSN))
	
	RETURN ISNULL(@dblRetVal, 0)
END

GO
