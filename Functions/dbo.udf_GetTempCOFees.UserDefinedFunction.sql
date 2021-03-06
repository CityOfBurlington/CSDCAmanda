USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetTempCOFees]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetTempCOFees](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
    /* Replaced by dbo.udf_GetZoningFeesTempCO(@intFolderRSN) */

	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountBillFee.FeeAmount)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode = 162)
	AND (Folder.FolderRSN = @intFolderRSN);

	RETURN @varRetVal
END

GO
