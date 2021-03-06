USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ISD_Folder_AdminFees]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ISD_Folder_AdminFees](@FolderRSN INT) RETURNS MONEY
AS BEGIN
	DECLARE @dblRetVal MONEY


	SELECT @dblRetVal = SUM(AccountBillFee.FeeAmount)
	FROM AccountBillFee
	INNER JOIN AccountBill ON AccountBillFee.BillNumber = AccountBill.BillNumber
	WHERE AccountBillFee.FeeCode IN(31, 172, 225)
	AND AccountBill.PaidInFullFlag IN('Y', 'N')
	AND AccountBillFee.FolderRSN = @FolderRSN

	RETURN ISNULL(@dblRetVal, 0)
END


GO
