USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetAmountPaid]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetAmountPaid](@intBillNumber INT) RETURNS MONEY
AS 
BEGIN
	DECLARE @dblRetVal MONEY

	SET @dblRetVal = 0

	SELECT @dblRetVal = @dblRetVal + SUM(ISNULL(PaymentAmount, 0))
	FROM AccountPaymentDetail
	WHERE BillNumber = @intBillNumber
	
	RETURN ISNULL(@dblRetVal, 0)
END

GO
