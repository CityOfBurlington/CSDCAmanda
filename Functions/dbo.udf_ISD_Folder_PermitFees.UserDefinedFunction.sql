USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ISD_Folder_PermitFees]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ISD_Folder_PermitFees](@FolderRSN INT) RETURNS MONEY
AS BEGIN
	DECLARE @dblRetVal MONEY

	SELECT @dblRetVal = SUM(AccountBillFee.FeeAmount)
	FROM AccountBillFee
	INNER JOIN AccountBill ON AccountBillFee.BillNumber = AccountBill.BillNumber
	WHERE AccountBillFee.FeeCode IN(25, 30, 55, 60, 65, 70, 75, 170, 171, 175, 300, 302)
	AND AccountBill.PaidInFullFlag IN('Y', 'N')
	AND AccountBillFee.FolderRSN = @FolderRSN

	RETURN ISNULL(@dblRetVal, 0)
END


GO
