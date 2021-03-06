USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetTotalBilledByRef]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetTotalBilledByRef] (@argFolderRSN VARCHAR(30)) RETURNS FLOAT AS
BEGIN 
DECLARE 
@SumTotalBilled FLOAT, 
@varRetVal Decimal (12,2)

	SELECT @SumTotalBilled = SUM(AccountBillFee.FeeAmount)
	FROM AccountBill
	INNER JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
 	WHERE (AccountBillFee.FolderRSN IN(SELECT FolderRSN FROM Folder WHERE ReferenceFile = @argFolderRSN)) 
	AND (AccountBillFee.FeeAmount IS NOT NULL) 
	AND (AccountBill.PaidInFullFlag <> 'C') 

	SET @SumTotalBilled = ISNULL(@SumTotalBilled, 0)
	SET @varRetVal = @SumTotalBilled

RETURN @varRetVal
END 


GO
