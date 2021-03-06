USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_Sort_Mixed_Values]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_Sort_Mixed_Values](@ColValue VARCHAR(20))
RETURNS VARCHAR(80)
AS

BEGIN
	/* Code taken from http://www.sqlteam.com/forums/topic.asp?TOPIC_ID=74699 */
	/* Sorts varchar column data, which is a mix of numbers and letters, logically in ascending order */
	/* Used for sorting Property.PropUnit */
	
	DECLARE @p1 VARCHAR(20)
	DECLARE @p2 VARCHAR(20)
	DECLARE @p3 VARCHAR(20)
	DECLARE @p4 VARCHAR(20)
	DECLARE @Index TINYINT

	IF @ColValue LIKE '[a-z]%'
		SELECT	@Index = PATINDEX('%[0-9]%', @ColValue),
			@p1 = LEFT(CASE WHEN @Index = 0 THEN @ColValue ELSE LEFT(@ColValue, @Index - 1) END + REPLICATE(' ', 20), 20),
			@ColValue = CASE WHEN @Index = 0 THEN '' ELSE SUBSTRING(@ColValue, @Index, 20) END
	ELSE
		SELECT	@p1 = REPLICATE(' ', 20)

	SELECT	@Index = PATINDEX('%[^0-9]%', @ColValue)

	IF @Index = 0
		SELECT	@p2 = RIGHT(REPLICATE(' ', 20) + @ColValue, 20),
			@ColValue = ''
	ELSE
		SELECT	@p2 = RIGHT(REPLICATE(' ', 20) + LEFT(@ColValue, @Index - 1), 20),
			@ColValue = SUBSTRING(@ColValue, @Index, 20)

	SELECT	@Index = PATINDEX('%[0-9,a-z]%', @ColValue)

	IF @Index = 0
		SELECT	@p3 = REPLICATE(' ', 20)
	ELSE
		SELECT	@p3 = LEFT(REPLICATE(' ', 20) + LEFT(@ColValue, @Index - 1), 20),
			@ColValue = SUBSTRING(@ColValue, @Index, 20)

	IF PATINDEX('%[^0-9]%', @ColValue) = 0
		SELECT	@p4 = RIGHT(REPLICATE(' ', 20) + @ColValue, 20)
	ELSE
		SELECT	@p4 = LEFT(@ColValue + REPLICATE(' ', 20), 20)

	RETURN	@p1 + @p2 + @p3 + @p4

END
GO
