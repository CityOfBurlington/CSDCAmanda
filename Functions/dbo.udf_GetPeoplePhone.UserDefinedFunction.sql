USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeoplePhone]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPeoplePhone](@intPeopleRSN int, @varNumberType varchar(30)) 
RETURNS VARCHAR(30)
AS
BEGIN
	/* Number Types are usually Home, Work, Mobile, and Primary   JA 8/2013*/

	DECLARE @varPhoneNumber varchar(30)
	
	SET @varPhoneNumber = 'none'

	SELECT @varPhoneNumber = People.Phone1
	FROM People
	WHERE People.PeopleRSN = @intPeopleRSN 
	AND UPPER(People.Phone1Desc) = UPPER(@varNumberType)
	
	IF @varPhoneNumber = 'none'
	BEGIN
		SELECT @varPhoneNumber = People.Phone2
		FROM People
		WHERE People.PeopleRSN = @intPeopleRSN 
		AND UPPER(People.Phone2Desc) = UPPER(@varNumberType)
	END

	IF @varPhoneNumber = 'none'
	BEGIN
		SELECT @varPhoneNumber = People.Phone3
		FROM People
		WHERE People.PeopleRSN = @intPeopleRSN 
		AND UPPER(People.Phone3Desc) = UPPER(@varNumberType) 
	END

	IF @varPhoneNumber = 'none' SELECT @varPhoneNumber = NULL
	ELSE SELECT @varPhoneNumber = SUBSTRING(@varPhoneNumber, 1, 3) + '-' + 
								  SUBSTRING(@varPhoneNumber, 4, 3) + '-' + 
								  SUBSTRING(@varPhoneNumber, 7, 4)
	
	RETURN @varPhoneNumber 
END
GO
