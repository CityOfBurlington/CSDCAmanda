USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PC_FEE_SELECT]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PC_FEE_SELECT]
(@argInfoCode int, @argFeeAmount float OUTPUT, @argEffectiveDate datetime=NULL)
--WITH 
--EXECUTE AS CALLER
AS
BEGIN
	
	DECLARE @v_errorDesc varchar(1000)
	DECLARE @n_feeAmount float
	DECLARE @v_feeAmount varchar(1000)

	IF @argEffectiveDate IS NULL 
		SET @argEffectiveDate = getDate()

	SELECT @n_feeAmount = lookupFee
	FROM validLookup
	WHERE lookupCode = 100
	AND lookup2 = @argInfoCode
	AND @argEffectiveDate BETWEEN lookupDate AND lookupDate2

	IF @n_feeAmount IS NULL
	BEGIN
		SET @v_errorDesc = 'There was no fee found for Fee Code '+ cast(@argInfoCode as varchar)+' please contact your AMANDA Administrator'
		RAISERROR(@v_errorDesc,16,-1);
	END	

	SET @argFeeAmount = @n_feeAmount

END

GO
