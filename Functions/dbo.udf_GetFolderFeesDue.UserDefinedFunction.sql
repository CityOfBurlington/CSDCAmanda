USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderFeesDue]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFolderFeesDue](@intFolderRSN INT) RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountBill.BillAmount) - SUM(AccountBill.TotalPaid)
	FROM AccountBill 
	WHERE (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBill.FolderRSN = @intFolderRSN)

	SET @varRetVal = ISNULL(@varRetVal, 0)

	RETURN @varRetVal
END

GO
