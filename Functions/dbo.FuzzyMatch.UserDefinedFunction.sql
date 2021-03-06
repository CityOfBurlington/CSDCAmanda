USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[FuzzyMatch]    Script Date: 9/9/2013 9:43:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FuzzyMatch](@String1 VARCHAR(100), @String2 VARCHAR(100)) RETURNS BIT
AS
BEGIN
	DECLARE @i INT
	DECLARE @RetVal BIT

	SET @i = CHARINDEX(@String1, @String2) + CHARINDEX(@String2, @String1)

	IF @i > 0 BEGIN
		SET @RetVal = 1
		END
	ELSE
		BEGIN
		SET @RetVal = 0
	END 

	RETURN @RetVal	
END
GO
