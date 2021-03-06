USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyOwners]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_PropertyOwners]
AS
BEGIN


	DECLARE @PropertyRSN INT
	DECLARE @PropHouse VARCHAR(20)
	DECLARE @PropStreet VARCHAR(40)
	DECLARE @PropStreetType VARCHAR(10)
	DECLARE @PropUnitType VARCHAR(15)
	DECLARE @PropUnit VARCHAR(10)
	DECLARE @ParcelID VARCHAR(30)
	DECLARE @PeopleRSN INT
	DECLARE @NameFirst VARCHAR(25)
	DECLARE @NameLast VARCHAR(25)
	DECLARE @OrganizationName VARCHAR(50)
	DECLARE @AddrHouse VARCHAR(20)
	DECLARE @AddrStreet VARCHAR(40)
	DECLARE @AddrStreetType VARCHAR(10)
	DECLARE @AddrUnitType VARCHAR(5)
	DECLARE @AddrUnit VARCHAR(10)
	DECLARE @AddrCity VARCHAR(40)
	DECLARE @AddrState VARCHAR(2)
	DECLARE @AddrZip VARCHAR(12) 
	DECLARE @AddressLine1 VARCHAR(60)
	DECLARE @AddressLine2 VARCHAR(60)
	DECLARE @AddressLine3 VARCHAR(60)
	DECLARE @APCode INT
	DECLARE @APIndex INT
	DECLARE @APFirstName VARCHAR(25)
	DECLARE @APLastName VARCHAR(30)
	DECLARE @APAddress1 VARCHAR(40)
	DECLARE @APAddress2 VARCHAR(40)
	DECLARE @APCity VARCHAR(25)
	DECLARE @APState VARCHAR(10)
	DECLARE @APZip VARCHAR(16)

		--CLOSE curProperty
		--DEALLOCATE curProperty

	/* DECLARE the cursor */
	DECLARE curProperty CURSOR FOR
	/* SELECT FolderRSN FROM ... something for the cursor */
	/* Can select multiple fields, but must fetch the same number in the FETCH statement(s) */
	SELECT Property.PropertyRSN FROM Property

	/* Open the cursor */
	OPEN curProperty
	/* Fetch the first value */
	FETCH NEXT FROM curProperty INTO @PropertyRSN
	/* Loop through the cursor */
	WHILE @@FETCH_STATUS = 0
		BEGIN
		/*Do Some Work Here */
		SELECT @PropHouse = PropHouse, @PropStreet = PropStreet, @PropStreetType = PropStreetType, 
		@PropUnitType = PropUnitType, @PropUnit = PropUnit, @ParcelID = PropertyRoll
		FROM Property
		WHERE Property.PropertyRSN = @PropertyRSN

		DECLARE curPeople CURSOR FOR
		SELECT PeopleRSN FROM PropertyPeople WHERE PropertyRSN = @PropertyRSN AND PeopleCode = 2
		OPEN curPeople
		FETCH NEXT FROM curPeople INTO @PeopleRSN
		WHILE @@FETCH_STATUS = 0
			BEGIN
			SELECT @NameFirst = NameFirst, @NameLast = NameLast, @OrganizationName = OrganizationName, 
			@AddrHouse = AddrHouse,	@AddrStreet = AddrStreet, @AddrStreetType = AddrStreetType, 
			@AddrUnitType = AddrUnitType, @AddrUnit = AddrUnit, @AddrCity = AddrCity, @AddrState = AddrProvince, 
			@AddrZip = AddrPostal, @AddressLine1 = AddressLine1, @AddressLine2 = AddressLine2, 
			@AddressLine3 = AddressLine3,
			@APCode = ISNULL(dbo.udf_GetAssessProOwnerCode(People.PeopleRSN),0),
			@APIndex = ISNULL(dbo.udf_GetAssessProOwnerIndex(People.PeopleRSN),0)
			FROM People 
			WHERE PeopleRSN = @PeopleRSN
			
			SET @APLastName = ''
			SET @APFirstName = ''
			IF @APCode > 0
			BEGIN
				IF @APIndex < 2
				BEGIN
					SELECT @APLastName = Description, @APFirstName = CuO1FirstName, @APAddress1 =  CuOStreet1,
					@APAddress2 = CuOStreet2, @APCity = CuOCity, @APState = CuOState, @APZip = CuOPostal
					FROM cobdb.AssessPro.dbo.TableOwnership
					WHERE Code = @APCode
				END
				IF @APIndex = 2
				BEGIN
					SELECT @APLastName = CuO2LastName, @APFirstName = CuO2FirstName, @APAddress1 =  CuOStreet1,
					@APAddress2 = CuOStreet2, @APCity = CuOCity, @APState = CuOState, @APZip = CuOPostal 
					FROM cobdb.AssessPro.dbo.TableOwnership
					WHERE Code = @APCode
				END
				IF @APIndex = 3
				BEGIN
					SELECT @APLastName = CuO3LastName, @APFirstName = CuO3FirstName, @APAddress1 =  CuOStreet1,
					@APAddress2 = CuOStreet2, @APCity = CuOCity, @APState = CuOState, @APZip = CuOPostal 
					FROM cobdb.AssessPro.dbo.TableOwnership
					WHERE Code = @APCode
				END
			END

			INSERT INTO tblPropertyOwner(PropertyRSN, PropHouse, PropStreet, PropStreetType, PropUnitType, PropUnit, 
			ParcelID, PeopleRSN, NameFirst, NameLast, OrganizationName, AddrHouse, AddrStreet, AddrStreetType, 
			AddrUnitType, AddrUnit, AddrCity, AddrState, AddrZip, AddressLine1, AddressLine2, AddressLine3, 
			APCode, APIndex, APFirstName, APLastName, APAddress1, APAddress2, APCity, APState, APZip)
			VALUES (@PropertyRSN, @PropHouse, @PropStreet, @PropStreetType, @PropUnitType, @PropUnit, 
			@ParcelID, @PeopleRSN, @NameFirst, @NameLast, @OrganizationName, @AddrHouse, @AddrStreet, @AddrStreetType, 
			@AddrUnitType, @AddrUnit, @AddrCity, @AddrState, @AddrZip, @AddressLine1, @AddressLine2, @AddressLine3, 
			@APCode, @APIndex, @APFirstName, @APLastName, @APAddress1, @APAddress2, @APCity, @APState, @APZip)

/*
PRINT @PropertyRSN
PRINT @PropHouse
PRINT @PropStreet
PRINT @PropStreetType
PRINT @ParcelID
PRINT @PeopleRSN
PRINT @NameFirst
PRINT @NameLast
PRINT @OrganizationName
PRINT @AddrHouse
PRINT @AddrStreet
PRINT @AddrStreetType
PRINT @AddrCity
PRINT @AddrState
PRINT @AddrZip
PRINT @AddressLine1
PRINT @AddressLine2
PRINT @AddressLine3
PRINT @APCode
PRINT @APIndex
PRINT @APFirstName
PRINT @APLastName
PRINT @APAddress1
PRINT @APAddress2
PRINT @APCity
PRINT @APState
PRINT @APZip
PRINT '----------'
PRINT ''
*/
			FETCH NEXT FROM curPeople INTO @PeopleRSN
		END
		CLOSE curPeople
		DEALLOCATE curPeople
			
		/* Fetch the next value till done */
		FETCH NEXT FROM curProperty INTO @PropertyRSN
	END

	/* Close the cursor */
	CLOSE curProperty

	/* Deallocate the cursor */
	DEALLOCATE curProperty
	
END
GO
