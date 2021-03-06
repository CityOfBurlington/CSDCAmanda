USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_FEE_UPDATE]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TK_FEE_UPDATE]
@argAccountBillFeeRSN int, 
@argFeeAmount float
AS

DECLARE @n_billNumber int
BEGIN
	SELECT @n_billNumber = max(billNumber) 
	FROM accountBillFee
	WHERE accountBillFeeRSN = @argAccountBillFeeRSN
	
	IF @n_billNumber = 0
	BEGIN
	 	UPDATE accountBillFee
	 	SET feeAmount = @argFeeAmount
	 	WHERE accountBillFeeRSN = @argAccountBillFeeRSN;
	END

END;





GO
