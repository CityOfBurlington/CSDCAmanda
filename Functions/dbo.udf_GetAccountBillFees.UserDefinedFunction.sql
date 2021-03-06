USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetAccountBillFees]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetAccountBillFees](@intFolderRSN INT, @intFeeCode INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountBillFee.FeeAmount)
	FROM AccountBillFee, AccountBill
	WHERE (AccountBillFee.FeeCode = @intFeeCode)
	AND (AccountBillFee.FolderRSN = @intFolderRSN)
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInfullFlag <> 'C'

	SET @varRetVal = ISNULL(@varRetVal, 0)

	RETURN @varRetVal
END

GO
