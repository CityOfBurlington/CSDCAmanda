USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Owners_Copy_From_AssessPro]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Owners_Copy_From_AssessPro] (@ParcelID VARCHAR(20))
AS
BEGIN
	/*Make any current owners previous owners*/
	UPDATE PropertyPeople
	SET PropertyPeople.PeopleCode = 200 /*Previous Owner*/
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	INNER JOIN Property ON PropertyPeople.PropertyRSN = Property.PropertyRSN
	WHERE Property.PropertyRoll = @ParcelID
	AND PropertyPeople.PeopleCode = 2 /*Owner*/

	DECLARE @AssessProOwnerCode INT
	DECLARE @PropertyRSN	INT
	DECLARE @FirstName1		VARCHAR(100)
	DECLARE @LastName1		VARCHAR(100)
	DECLARE @FirstName2		VARCHAR(100) 
	DECLARE @LastName2		VARCHAR(100)
	DECLARE @FirstName3		VARCHAR(100)
	DECLARE @LastName3		VARCHAR(100)
	DECLARE @Address1		VARCHAR(100)
 	DECLARE @Address2		VARCHAR(100) 
	DECLARE @Address3		VARCHAR(200)
 	DECLARE @SaleDate		DATETIME

	SELECT @PropertyRSN = ISNULL(PropertyRSN, 0)
	FROM Property
	WHERE PropertyRoll = @ParcelID

	IF @PropertyRSN > 0 BEGIN
		SELECT 
		@AssessProOwnerCode = O.Code,
		@FirstName1 = RTRIM(LTRIM(ISNULL(O.CuO1FirstName, ''))),
		@LastName1 = RTRIM(LTRIM(ISNULL(O.Description, ''))),
		@FirstName2 = RTRIM(LTRIM(ISNULL(O.CuO2FirstName, ''))),
		@LastName2 = RTRIM(LTRIM(ISNULL(O.CuO2LastName, ''))),
		@FirstName3 = RTRIM(LTRIM(ISNULL(O.CuO3FirstName, ''))),
		@LastName3 = RTRIM(LTRIM(ISNULL(O.CuO3LastName, ''))),
		@Address1 = RTRIM(LTRIM(ISNULL(O.CuOStreet1, ''))),
 		@Address2 = RTRIM(LTRIM(ISNULL(O.CuOStreet2, ''))),
		@Address3 = RTRIM(LTRIM(ISNULL(O.CuOCity + ', ', ''))) + ' ' + RTRIM(LTRIM(ISNULL(O.CuOState, ''))) + ' ' + RTRIM(LTRIM(ISNULL(O.CuOPostal, ''))),
		@SaleDate = CuOSaleDate
		FROM AssessPro.dbo.DataProperty P 
		INNER JOIN AssessPro.dbo.TableOwnership O ON P.OwnerLookUp = O.Code
		WHERE P.CardNumber = 1
		AND P.ParcelID = @ParcelID

		DECLARE @NextPeopleRSN INT
		SELECT @NextPeopleRSN = MAX(People.PeopleRSN) + 1 
		FROM People

		DELETE FROM PeopleInfo 
		WHERE (InfoCode = 10  OR InfoCode = 15)
		AND PeopleRSN IN(SELECT PeopleRSN FROM PropertyPeople WHERE PropertyRSN = @PropertyRSN)

		INSERT INTO People (PeopleCode, PeopleRSN, NameFirst, NameLast, StampDate, StampUser, AddressLine1, AddressLine2, AddressLine3 )
		VALUES(2, @NextPeopleRSN, @FirstName1, @LastName1, GetDate(), 'sa', @Address1, @Address2, @Address3)

		INSERT INTO PropertyPeople (PropertyRSN, PeopleCode, PeopleRSN, StartDate, StampUser, StampDate)
		VALUES(@PropertyRSN, 2, @NextPeopleRSN, @SaleDate, 'sa', GetDate())

		INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
		VALUES(@NextPeopleRSN, 10, @AssessProOwnerCode, @AssessProOwnerCode, GetDate(), 'sa', @AssessProOwnerCode)

		INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
		VALUES(@NextPeopleRSN, 15, '1', '1', GetDate(), 'sa', '1')

		IF @FirstName2 + @LastName2 <> '' BEGIN
			SELECT @NextPeopleRSN = MAX(People.PeopleRSN) + 1 
			FROM People

			INSERT INTO People (PeopleCode, PeopleRSN, NameFirst, NameLast, StampDate, StampUser, AddressLine1, AddressLine2, AddressLine3 )
			VALUES(2, @NextPeopleRSN, @FirstName2, @LastName2, GetDate(), 'sa', @Address1, @Address2, @Address3)

			INSERT INTO PropertyPeople (PropertyRSN, PeopleCode, PeopleRSN, StartDate, StampUser, StampDate)
			VALUES(@PropertyRSN, 2, @NextPeopleRSN, @SaleDate, 'sa', GetDate())

			INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
			VALUES(@NextPeopleRSN, 10, @AssessProOwnerCode, @AssessProOwnerCode, GetDate(), 'sa', @AssessProOwnerCode)

			INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
			VALUES(@NextPeopleRSN, 15, '2', '2', GetDate(), 'sa', '2')
		END

		IF @FirstName3 + @LastName3 <> '' BEGIN
			SELECT @NextPeopleRSN = MAX(People.PeopleRSN) + 1 
			FROM People

			INSERT INTO People (PeopleCode, PeopleRSN, NameFirst, NameLast, StampDate, StampUser, AddressLine1, AddressLine2, AddressLine3 )
			VALUES(2, @NextPeopleRSN, @FirstName3, @LastName3, GetDate(), 'sa', @Address1, @Address2, @Address3)

			INSERT INTO PropertyPeople (PropertyRSN, PeopleCode, PeopleRSN, StartDate, StampUser, StampDate)
			VALUES(@PropertyRSN, 2, @NextPeopleRSN, @SaleDate, 'sa', GetDate())

			INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
			VALUES(@NextPeopleRSN, 10, @AssessProOwnerCode, @AssessProOwnerCode, GetDate(), 'sa', @AssessProOwnerCode)

			INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
			VALUES(@NextPeopleRSN, 15, '3', '3', GetDate(), 'sa', '2')
		END
	END
END


GO
