USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesPermitApplicationNoFF]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesPermitApplicationNoFF](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
    /* Totals Zoning Permit application fees, excluding the Filing Fee. 
       Used by Infomaker zoning permit forms. */
	DECLARE @moneyPermitFeesPaid MONEY

	SELECT @moneyPermitFeesPaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode IN (85,86,90,95,100,105,130,135,136,147,150))
	AND (Folder.FolderRSN = @intFolderRSN);

	RETURN @moneyPermitFeesPaid
END

GO
