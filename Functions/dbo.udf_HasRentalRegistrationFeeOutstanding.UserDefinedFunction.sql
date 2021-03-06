USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_HasRentalRegistrationFeeOutstanding]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_HasRentalRegistrationFeeOutstanding](@intFolderRSN INT) RETURNS INT
AS 
BEGIN
	DECLARE @intRetVal INT

	SET @intRetVal = 0
	
	SELECT @intRetVal = 
	CASE 
	WHEN SUM(AccountBill.BillAmount - AccountBill.TotalPaid) > 0 THEN 1
	ELSE 0 END
	FROM AccountBill
	INNER JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
	WHERE AccountBill.FolderRSN = @intFolderRSN
	AND AccountBillFee.FolderRSN = @intFolderRSN
	AND AccountBillFee.FeeCode = 180
	AND AccountBill.FolderRSN NOT IN(SELECT FolderRSN FROM AccountBillFee WHERE FolderRSN = @intFolderRSN AND AccountBillFee.FeeCode = 209)

	RETURN @intRetVal
END


GO
