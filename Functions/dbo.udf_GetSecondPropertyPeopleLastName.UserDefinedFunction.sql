USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetSecondPropertyPeopleLastName]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetSecondPropertyPeopleLastName](@intPropertyRSN INT, @intPeopleCode INT) RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @strRetVal VARCHAR(100)
	DECLARE @strSecondPerson VARCHAR(100)
	DECLARE @intPeopleCount INT
	DECLARE @i INT

	SET @i = 0
	SELECT @intPeopleCount = SUM(1)
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = @intPeopleCode

	IF @intPeopleCount > 1
		BEGIN
		
		DECLARE curPeople CURSOR FOR

		SELECT RTRIM(ISNULL(People.NameLast, ''))
		FROM People
		INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
		WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
		AND PropertyPeople.PeopleCode = @intPeopleCode
		ORDER BY People.PeopleRSN

		OPEN curPeople
		FETCH NEXT FROM curPeople INTO @strRetVal

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @i = @i + 1

			IF @i = 2
				BEGIN
				SET @strSecondPerson = @strRetVal
			END

			FETCH NEXT FROM curPeople INTO @strRetVal
		END

		CLOSE curPeople
		DEALLOCATE curPeople
	END	


	RETURN ISNULL(@strSecondPerson, '')
END



GO
