USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFCOPaidInFullFlag]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFCOPaidInFullFlag](@intFolderRSN INT)
	RETURNS VARCHAR
AS
BEGIN
    /* Used by Infomkaer forms */
    /* Replaced by standard naming convention function, 
       dbo.udf_GetZoningFeesFCOPaidInFullFlag */
	DECLARE @varRetVal VARCHAR(10)

	SELECT @varRetVal = ISNULL(MIN(AccountBill.PaidInFullFlag), 'N')
	FROM Folder, FolderProcess, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (Folder.FolderRSN = FolderProcess.FolderRSN)
	AND (FolderProcess.ProcessCode IN(10001, 10017))
	AND (AccountBill.PaidInFullFlag <> 'C')
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
	AND (AccountBillFee.FeeCode IN (160, 304))
	AND (Folder.FolderRSN = @intFolderRSN)

	RETURN @varRetVal
END

GO
