USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFees]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFees](@intFolderRSN INT, @intFeeCode INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountBillFee.FeeAmount)
	FROM AccountBill 
	INNER JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
	WHERE (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode = @intFeeCode)
	AND (AccountBill.FolderRSN = @intFolderRSN)

	SET @varRetVal = ISNULL(@varRetVal, 0)

	RETURN @varRetVal
END



GO
