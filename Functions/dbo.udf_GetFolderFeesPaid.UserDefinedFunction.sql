USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderFeesPaid]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderFeesPaid](@intFolderRSN INT) RETURNS MONEY
AS 
BEGIN
	DECLARE @dblRetVal MONEY

	SET @dblRetVal = 0

	SELECT @dblRetVal = @dblRetVal + SUM(ISNULL(PaymentAmount, 0))
	FROM AccountPayment
	WHERE FolderRSN = @intFolderRSN
	AND ISNULL(VoidFlag, 'N') <> 'Y'
	
	RETURN ISNULL(@dblRetVal, 0)
END
GO
