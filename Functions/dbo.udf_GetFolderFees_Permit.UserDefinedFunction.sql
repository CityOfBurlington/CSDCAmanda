USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderFees_Permit]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderFees_Permit](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
    AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
	AND (AccountBillFee.FeeCode IN (25,30,35,50,55,60,65,70,75))
	AND (Folder.FolderRSN = @intFolderRSN)

	RETURN @varRetVal
END

GO
