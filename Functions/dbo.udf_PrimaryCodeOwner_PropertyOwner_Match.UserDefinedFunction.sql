USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_PrimaryCodeOwner_PropertyOwner_Match]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_PrimaryCodeOwner_PropertyOwner_Match](@PropertyRSN INT, @PCOLastName VARCHAR(100)) RETURNS BIT
AS
BEGIN
	DECLARE @RetVal INT
	SET @RetVal = 0

	DECLARE @OwnerLastName VARCHAR(100)

	DECLARE curOwners CURSOR FOR
	SELECT People.NameLast
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	WHERE PropertyPeople.PeopleCode = 2
    AND PropertyPeople.PropertyRSN = @PropertyRSN

	OPEN curOwners

	FETCH NEXT FROM curOwners INTO @OwnerLastName
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @RetVal = @RetVal + dbo.FuzzyMatch(@PCOLastName, @OwnerLastName) + dbo.FuzzyMatch(@OwnerLastName, @PCOLastName)

		FETCH NEXT FROM curOwners INTO @OwnerLastName
	END

	CLOSE curOwners
	DEALLOCATE curOwners
	DECLARE @bitVal BIT
	IF @RetVal > 0 
	BEGIN
		SET @bitVal = 1
	END
	ELSE
	BEGIN
		SET @bitVal = 0
	END
	RETURN @bitVal
END


GO
