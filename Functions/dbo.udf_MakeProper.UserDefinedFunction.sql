USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_MakeProper]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_MakeProper]( @str VARCHAR(8000) )
RETURNS varchar(8000)
AS
BEGIN
	DECLARE @Words VARCHAR(8000), 
		@ReturnString VARCHAR(8000), 
		@Pos INT, 
		@x INT, 
		@newstr VARCHAR(8000), 
		@Word VARCHAR(100),
		@Space CHAR(1)

	
	SELECT @Words = '', @Pos = 1, @x = -1, @Space = ' '
	
	IF LEN(@str) = 0 
		BEGIN
		SET @ReturnString = ' '
		END
	IF LEN(@str) > 0 
	BEGIN
	
		SET @x = CHARINDEX(@Space, @str, @Pos)
	
		IF @x > 0 
		BEGIN
			SELECT @Word = SUBSTRING(@str, 1, @x-1)
			WHILE (@x <> 0)
				BEGIN
					SELECT @Words = @Words + ' ' + UPPER(SUBSTRING(@Word, 1, 1)) + LOWER(SUBSTRING(@Word, 2, LEN(@Word) - 1))
					SET @Pos = @x + 1
					SET @x = CHARINDEX(@Space, @str, @Pos)
					IF @x <> 0 
						SELECT @Word = SUBSTRING(@str,@Pos,@x-@Pos)
				END
			SELECT @Word = REVERSE(SUBSTRING(REVERSE(@str), 1, CHARINDEX(' ', REVERSE(@str), 1)-1))
			SELECT @Words = @Words + ' ' + UPPER(SUBSTRING(@Word, 1, 1)) + LOWER(SUBSTRING(@Word, 2, LEN(@Word) - 1))
			SET @ReturnString = SUBSTRING(@Words, 2, LEN(@Words))
		END
		ELSE
		BEGIN
			SET @ReturnString = UPPER(SUBSTRING(@str, 1, 1)) + LOWER(SUBSTRING(@str, 2, LEN(@str) - 1))
		END

	END
	
	RETURN @ReturnString
END





GO
