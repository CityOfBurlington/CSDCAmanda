USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZNCOFees]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_ZNCOFees](@FolderRSN INT) RETURNS MONEY
AS BEGIN
	DECLARE @dblRetVal MONEY

	SELECT @dblRetVal = SUM(AccountBillFee.FeeAmount)
	FROM AccountBillFee
	INNER JOIN AccountBill ON AccountBillFee.BillNumber = AccountBill.BillNumber
	WHERE AccountBillFee.FeeCode IN(160, 162)
	AND AccountBill.PaidInFullFlag IN('Y', 'N')
	AND AccountBillFee.FolderRSN = @FolderRSN

	RETURN ISNULL(@dblRetVal, 0)
END

GO
