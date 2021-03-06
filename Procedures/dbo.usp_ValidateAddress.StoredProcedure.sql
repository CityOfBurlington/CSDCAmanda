USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ValidateAddress]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ValidateAddress](@StreetAddress VARCHAR(255), @PercentMatch FLOAT OUTPUT)
AS
BEGIN
SET @PercentMatch = 0.0

IF EXISTS(
		SELECT TOP 1 *
		FROM Property
		WHERE @StreetAddress LIKE ISNULL(PropHouse + ' ', '') + ISNULL(PropStreet + ' ', '') + '%'
	)
	BEGIN
		SET @PercentMatch = 1.0
	END
ELSE
	BEGIN
		IF EXISTS(
			SELECT TOP 1 *
			FROM Property
			WHERE DIFFERENCE(dbo.udf_OnlyChars(@StreetAddress), ISNULL(PropStreet + ' ', '') ) = 4
			)
			BEGIN
				SET @PercentMatch = 8.0
		END
	END
END


GO
