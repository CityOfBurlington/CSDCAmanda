USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetImpactFees]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetImpactFees](@intFolderRSN int)
	RETURNS MONEY
AS
BEGIN
	DECLARE @ImpactFees MONEY

	SELECT @ImpactFees = SUM(AccountBillFee.FeeAmount)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode IN (190,191,192,193,194,195))
	AND (Folder.FolderRSN = @intFolderRSN);

	RETURN ISNULL(@ImpactFees, 0)
END


GO
