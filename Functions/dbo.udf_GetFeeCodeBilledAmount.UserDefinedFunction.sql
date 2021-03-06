USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFeeCodeBilledAmount]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetFeeCodeBilledAmount](@intFolderRSN INT, @intFeeCode INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @BillAmount MONEY

	SELECT @BillAmount = (AccountBillFee.FeeAmount)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode = @intFeeCode)
	AND (Folder.FolderRSN = @intFolderRSN)

	RETURN ISNULL(@BillAmount,0)
END

GO
