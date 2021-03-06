USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPayments]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderPayments](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountPayment.PaymentAmount)
	FROM AccountPayment 
	WHERE AccountPayment.FolderRSN = @intFolderRSN
	AND ISNULL(AccountPayment.VoidFlag, 'N') = 'N'

	SET @varRetVal = ISNULL(@varRetVal, 0)

	RETURN @varRetVal
END

GO
