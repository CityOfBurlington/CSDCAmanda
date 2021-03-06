USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyWithNoOwners]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_PropertyWithNoOwners] AS
BEGIN

DECLARE @PropertyRSN VARCHAR(15)

DECLARE curProperties CURSOR FOR 
SELECT DISTINCT PropertyRSN
FROM Property
WHERE ISNULL(PropertyRoll, '') <> ''

OPEN curProperties

FETCH NEXT FROM curProperties INTO @PropertyRSN

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS(SELECT PeopleRSN
			FROM PropertyPeople
			WHERE PropertyPeople.PeopleCode = 2
			AND PropertyRSN = @PropertyRSN)
		BEGIN
		PRINT @PropertyRSN
	END


	FETCH NEXT FROM curProperties INTO @PropertyRSN
END

CLOSE curProperties
DEALLOCATE curProperties

END
GO
