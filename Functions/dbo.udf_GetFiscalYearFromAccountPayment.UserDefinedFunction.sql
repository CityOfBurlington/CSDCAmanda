USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearFromAccountPayment]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetFiscalYearFromAccountPayment](@intPaymentNumber INT) RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @intPaymentDateYear int
	DECLARE @intPaymentDateMonth int
	DECLARE @intYrDiff int
	DECLARE @intCenturyDiff int
        DECLARE @intFY int
	DECLARE @varRetVal varchar(10)

	SELECT @intPaymentDateYear  = ISNULL(DATEPART(yy, AccountPayment.PaymentDate), 0), 
	       @intPaymentDateMonth = ISNULL(DATEPART(mm, AccountPayment.PaymentDate), 0)
	  FROM AccountPayment
	 WHERE AccountPayment.PaymentNumber = @intPaymentNumber

	IF @intPaymentDateMonth > 6 SELECT @intYrDiff = 1
	ELSE SELECT @intYrDiff = 0

	IF @intPaymentDateYear < 2000 SELECT @intCenturyDiff = 1900
	ELSE SELECT @intCenturyDiff = 2000

        SELECT @intFY = ((@intPaymentDateYear - @intCenturyDiff) + @intYrDiff)

	IF @intFY = 100 SELECT @intFY = 0

	IF @intFY < 10
	SELECT @varRetVal = 'FY0' + CAST(@intFY AS VARCHAR(4))

	ELSE 
	SELECT @varRetVal = 'FY' + CAST(@intFY AS VARCHAR(4))

	RETURN @varRetVal
END

GO
