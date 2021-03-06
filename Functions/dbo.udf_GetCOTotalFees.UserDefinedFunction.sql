USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCOTotalFees]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetCOTotalFees](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
    /* Used by Infomaker ZOning Fee Report form - called by 
       dbo.GetCO TotalAmount Due */
    /* No longer used - replaced by dbo.udf_GetZoningFeesCOFolderDue */
    /* Also the logic is incorrect as it mixes TCO and FCO fees */

	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(ISNULL(AccountBillFee.FeeAmount,0))
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode IN (160, 162, 304))
	AND (Folder.FolderRSN = @intFolderRSN);

	RETURN ISNULL(@varRetVal,0)
END

GO
