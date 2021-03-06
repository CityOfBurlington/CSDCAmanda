USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFeeCodeForPayment]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFeeCodeForPayment](@TransactionRSN INT) RETURNS INT
AS
BEGIN
	DECLARE @intPaymentNumber INT
	DECLARE @intBillNumber INT
	DECLARE @intRetVal INT

	SELECT @intPaymentNumber = PaymentNumber
	FROM AccountGL
	WHERE TransactionRSN = @TransactionRSN

	SELECT @intBillNumber = BillNumber
	FROM AccountPaymentDetail
	WHERE PaymentNumber = @intPaymentNumber

	SELECT @intRetVal = FeeCode
	FROM AccountBillFee
	WHERE BillNumber = @intBillNumber

	RETURN @intRetVal
END


GO
