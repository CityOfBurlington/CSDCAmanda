USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetValidFeeAmount]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[udf_GetValidFeeAmount] (@argLookupCode int, @argLookup1 int, @argLookup2 int) RETURNS MONEY
AS
BEGIN 

DECLARE @FeeAmount money

SELECT @FeeAmount = ValidLookUp.LookupFee
FROM ValidLookup
WHERE ValidLookup.LookupCode = @argLookupCode
AND ValidLookup.Lookup1 = @argLookup1
AND ValidLookup.Lookup2 = @argLookup2

	RETURN ISNULL(@FeeAmount, 0)
END

GO
