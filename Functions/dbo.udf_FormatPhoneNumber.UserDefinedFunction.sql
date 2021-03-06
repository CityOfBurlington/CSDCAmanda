USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_FormatPhoneNumber]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_FormatPhoneNumber](@PhoneNumber VARCHAR(30)) RETURNS VARCHAR(30)
AS
BEGIN

DECLARE @RetVal VARCHAR(30)
DECLARE @intPhoneNumberLength INT
DECLARE @IsFormattedNumber BIT
DECLARE @HasAreaCode BIT
DECLARE @HasExtQualifier BIT

SET @IsFormattedNumber = 0
SET @HasAreaCode = 0
SET @HasExtQualifier = 0
SET @intPhoneNumberLength = LEN(ISNULL(@PhoneNumber, ''))

IF CHARINDEX('x', LOWER(ISNULL(@PhoneNumber, ''))) > 0 
	BEGIN
	SET @HasExtQualifier = 1
END

IF CHARINDEX('(', ISNULL(@PhoneNumber, '')) = 1 AND CHARINDEX(')', ISNULL(@PhoneNumber, '')) = 5 
	BEGIN
	SET @HasAreaCode = 1
END

IF CHARINDEX('-', ISNULL(@PhoneNumber, '')) > 0 
	BEGIN
	SET @IsFormattedNumber = 1
END

SET @RETVAL = 
CASE
WHEN @IsFormattedNumber = 1 AND @HasAreaCode = 1 THEN
	@PhoneNumber
	/*Already formatted*/
WHEN @IsFormattedNumber = 1 AND @HasAreaCode = 0 THEN
	CASE
	WHEN @intPhoneNumberLength > 9 THEN
		@PhoneNumber
		/*Already formatted*/
	WHEN @intPhoneNumberLength = 8 THEN
		'(802)' + @PhoneNumber
		/*Formatted 555-5555*/
	ELSE
		@PhoneNumber
		/*Who knows what this looks like?*/
	END
WHEN @IsFormattedNumber = 0 AND @HasAreaCode = 1 THEN
	CASE
	WHEN @intPhoneNumberLength = 12 THEN
		SUBSTRING(@PhoneNumber, 1, 8) + '-' + SUBSTRING(@PhoneNumber, 9, 4)
		/*Formatted (802)5555555*/
	ELSE
		@PhoneNumber
		/*Who knows what this looks like?*/
	END
WHEN @IsFormattedNumber = 0 AND @HasAreaCode = 0 THEN
	CASE
	WHEN @intPhoneNumberLength = 10 THEN
		'(' + SUBSTRING(@PhoneNumber, 1, 3) + ')' + SUBSTRING(@PhoneNumber, 4, 3) + '-' + SUBSTRING(@PhoneNumber, 7, 4)
		/*Formatted 8025551212*/
	WHEN @intPhoneNumberLength = 7 THEN
		'(802)' + SUBSTRING(@PhoneNumber, 1, 3) + '-' + SUBSTRING(@PhoneNumber, 4, 4)
		/*Formatted 5551212*/
	WHEN @intPhoneNumberLength > 10 THEN
		CASE 
		WHEN @HasExtQualifier = 1 THEN
			'(' + SUBSTRING(@PhoneNumber, 1, 3) + ')' + SUBSTRING(@PhoneNumber, 4, 3) + '-' + SUBSTRING(@PhoneNumber, 7, 4) + ' ' + SUBSTRING(@PhoneNumber, 11, @intPhoneNumberLength - 10)
			/*Formatted 8025551212 ext123*/
		ELSE
			'(' + SUBSTRING(@PhoneNumber, 1, 3) + ')' + SUBSTRING(@PhoneNumber, 4, 3) + '-' + SUBSTRING(@PhoneNumber, 7, 4) + ' x' + SUBSTRING(@PhoneNumber, 11, @intPhoneNumberLength - 10)
		END
	ELSE
		@PhoneNumber
	END
END

RETURN @RetVal

END



GO
