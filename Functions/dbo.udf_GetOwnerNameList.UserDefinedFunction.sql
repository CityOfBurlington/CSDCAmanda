USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetOwnerNameList]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetOwnerNameList](@intPropertyRSN INT) RETURNS VARCHAR(400)
AS

BEGIN
    DECLARE @POwnerName varchar(255)
	DECLARE @Owners VARCHAR(400)
	DECLARE @First INT
	DECLARE @PeopleRSN INT

	SET @Owners = ''
	SET @First = 1

	DECLARE CurGeneral CURSOR FOR
	SELECT PeopleRSN FROM PropertyPeople  
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN 
	AND PropertyPeople.PeopleCode = 2 
	ORDER BY People.PeopleRSN

	OPEN curGeneral
	FETCH NEXT FROM curGeneral INTO @PeopleRSN
	WHILE @@FETCH_STATUS = 0
		BEGIN

		IF @First = 0 SET @Owners = @Owners + '; '
		SET @POwnerName = RTRIM(LTRIM(dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)))
		SET @Owners = @Owners + @POwnerName
		SET @First = 0

		FETCH NEXT FROM curGeneral INTO @PeopleRSN
	END
	CLOSE curGeneral
	DEALLOCATE curGeneral

    RETURN @Owners

END


GO
