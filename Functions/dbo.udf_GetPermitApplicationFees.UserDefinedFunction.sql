USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPermitApplicationFees]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetPermitApplicationFees](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountBillFee.FeeAmount)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode IN (85,86,90,95,100,105,130,135,136,140,142,150))
	AND (Folder.FolderRSN = @intFolderRSN);

	RETURN @varRetVal
END


GO
