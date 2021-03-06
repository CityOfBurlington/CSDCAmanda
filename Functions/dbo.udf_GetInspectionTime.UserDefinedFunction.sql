USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetInspectionTime]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetInspectionTime](@pUnits INT, @pInspectionAttempt INT) RETURNS INT
AS 
BEGIN
	DECLARE @RetVal INT
	DECLARE @strSQL VARCHAR(1000)
	DECLARE @RentalUnits INT
	DECLARE @InspectionAttempt INT
	DECLARE @MaxRentalUnits INT
	
	SELECT @MaxRentalUnits = MAX(Lookup1)
	FROM ValidLookup
	WHERE LookupCode = 20 /*Code Enforcement Inspection Schedule*/

	SET @RentalUnits = ISNULL(@pUnits, 0)

	IF @RentalUnits > @MaxRentalUnits
		BEGIN
		SET @RentalUnits = @MaxRentalUnits
	END

	SET @InspectionAttempt = ISNULL(@pInspectionAttempt, 0)

	IF @InspectionAttempt > 3
		BEGIN
		SET @InspectionAttempt = 3
	END

	IF @RentalUnits = 0 
		BEGIN
		SELECT @RetVal = CASE @InspectionAttempt
		WHEN 1 THEN 
			MIN(Lookup2)
		WHEN 2 THEN 
			MIN(LookupFee)
		ELSE
			MIN(CAST(LookupString AS INT))
		END
		FROM ValidLookup 
		WHERE LookupCode = 20 /*Code Enforcement Inspection Schedule*/
		END

	ELSE
		BEGIN
		SELECT @RetVal = CASE @InspectionAttempt
		WHEN 1 THEN 
			Lookup2
		WHEN 2 THEN 
			LookupFee
		ELSE
			CAST(LookupString AS INT)
		END
		FROM ValidLookup 
		WHERE LookupCode = 20 /*Code Enforcement Inspection Schedule*/
		AND Lookup1 = @RentalUnits
		END 

	
	RETURN @RetVal
END


GO
