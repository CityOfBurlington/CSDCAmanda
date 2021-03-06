USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_Get1PercentOfRB]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_Get1PercentOfRB](@intFolderRSN INT) RETURNS MONEY
AS
BEGIN
	DECLARE @dblRetVal MONEY

	SELECT @dblRetVal = SUM(FeeAmount) * .01
	FROM AccountBillFee
	WHERE ISNULL(FeeLeft, FeeAmount) = FeeAmount
	AND FeeCode IN(180, 209)
	AND FolderRSN = @intFolderRSN

	RETURN ISNULL(@dblRetVal, 0)
END

GO
