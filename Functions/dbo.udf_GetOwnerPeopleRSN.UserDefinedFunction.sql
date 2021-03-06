USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetOwnerPeopleRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetOwnerPeopleRSN](@intPropertyRSN INT, @intPosition INT) RETURNS INT
AS
BEGIN
	DECLARE @intRetVal INT
	DECLARE @intPeopleRSN INT
	DECLARE @intPeopleCount INT
	DECLARE @i INT

	SET @i = 0
	SELECT @intPeopleCount = SUM(1)
	FROM PropertyPeople
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = 2 /* gettting only owners */

	IF @intPeopleCount < @intPosition 
	BEGIN
		SET @intRetVal = NULL
	END


	IF @intPeopleCount >= @intPosition
		BEGIN
		
		DECLARE curPeople CURSOR FOR

		SELECT PropertyPeople.PeopleRSN	FROM PropertyPeople
		WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
		AND PropertyPeople.PeopleCode = 2
		ORDER BY PropertyPeople.PeopleRSN

		OPEN curPeople
		FETCH NEXT FROM curPeople INTO @intPeopleRSN

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @i = @i + 1

			IF @i = @intPosition
			BEGIN
				SET @intRetVal = @intPeopleRSN
			END
			
			FETCH NEXT FROM curPeople INTO @intPeopleRSN
		END

		CLOSE curPeople
		DEALLOCATE curPeople

		END
	RETURN ISNULL(@intRetVal, NULL)
END


GO
