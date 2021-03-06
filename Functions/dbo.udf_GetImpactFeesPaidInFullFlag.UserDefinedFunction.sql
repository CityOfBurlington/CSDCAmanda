USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetImpactFeesPaidInFullFlag]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetImpactFeesPaidInFullFlag](@intFolderRSN INT)
	RETURNS VARCHAR
AS
BEGIN
	DECLARE @varRetVal VARCHAR(10)

	SELECT @varRetVal = MIN(AccountBill.PaidInFullFlag)
	FROM Folder
	INNER JOIN AccountBillFee ON Folder.FolderRSN = AccountBillFee.FolderRSN
	INNER JOIN AccountBill ON AccountBillFee.BillNumber = AccountBill.BillNumber
	WHERE (AccountBill.PaidInFullFlag <> 'C')
	AND (AccountBillFee.FeeCode BETWEEN 190 AND 195)
	AND (Folder.FolderRSN = @intFolderRSN)

	RETURN @varRetVal
END

GO
