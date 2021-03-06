USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetTempCOPaidInFullFlag]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetTempCOPaidInFullFlag](@intFolderRSN INT)
	RETURNS VARCHAR
AS
BEGIN
	DECLARE @varRetVal VARCHAR(10)

	SELECT @varRetVal = MIN(AccountBill.PaidInFullFlag)
	FROM Folder, FolderProcess, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (Folder.FolderRSN = FolderProcess.FolderRSN)
	AND (FolderProcess.ProcessCode = 10005)
	AND (AccountBill.PaidInFullFlag <> 'C')
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
	AND (AccountBillFee.FeeCode = 162)
	AND (Folder.FolderRSN = @intFolderRSN)

	RETURN @varRetVal
END

GO
