USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Build_Amanda_APro_Compare]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Build_Amanda_APro_Compare]
AS
BEGIN 

DECLARE @PropertyRSN int
DECLARE @AM_ParcelID varchar(30)
DECLARE @AM_APAccountNumber int
DECLARE @AM_Owner1RSN int
DECLARE @AM_Owner2RSN int
DECLARE @AM_Owner3RSN int
DECLARE @AM_APOwnerLookup1 int
DECLARE @AM_APOwnerIndex1 int
DECLARE @AM_APOwnerLookup2 int
DECLARE @AM_APOwnerIndex2 int
DECLARE @AM_APOwnerLookup3 int
DECLARE @AM_APOwnerIndex3 int
DECLARE @AM_Description varchar(30)
DECLARE @AM_CuO1FirstName varchar(25)
DECLARE @AM_CuO2LastName varchar(30)
DECLARE @AM_CuO2FirstName varchar(25)
DECLARE @AM_CuO3LastName varchar(30)
DECLARE @AM_CuO3FirstName varchar(25)
DECLARE @AM_CuOStreet1 varchar(40)
DECLARE @AM_CuOStreet2 varchar(40)
DECLARE @AM_CuOStreet3 varchar(40)
DECLARE @AM_CuOCity varchar(25)
DECLARE @AM_CuOState varchar(10)
DECLARE @AM_CuOPostal varchar(16)
DECLARE @AP_APAccountNumber int
DECLARE @AP_APOwnerLookup int
DECLARE @AP_Description varchar(30)
DECLARE @AP_CuO1FirstName varchar(25)
DECLARE @AP_CuO2LastName varchar(30)
DECLARE @AP_CuO2FirstName varchar(25)
DECLARE @AP_CuO3LastName varchar(30)
DECLARE @AP_CuO3FirstName varchar(25)
DECLARE @AP_CuOStreet1 varchar(40)
DECLARE @AP_CuOStreet2 varchar(40)
DECLARE @AP_CuOCity varchar(25)
DECLARE @AP_CuOState varchar(10)
DECLARE @AP_CuOPostal varchar(16)

TRUNCATE TABLE tblAmanda_Apro_Compare

INSERT INTO tblAmanda_Apro_Compare
SELECT A.PropertyRSN AS AM_PropertyRSN, A.ParcelID AS AM_ParcelID, A.AProAccount AS AM_APAccountNumber, A.Owner1 AS AM_Owner1RSN,
	A.Owner2 AS AM_Owner2RSN, A.Owner3 AS AM_Owner3RSN, dbo.f_info_numeric_people(Owner1,10) AS AM_APOwnerLookup1, 
	dbo.f_info_numeric_people(Owner1,15) AS AM_APOwnerIndex1, dbo.f_info_numeric_people(Owner2,10) AS AM_APOwnerLookup2,
	dbo.f_info_numeric_people(Owner2,15) AS AM_APOwnerIndex2, dbo.f_info_numeric_people(Owner3,10) AS AM_APOwnerLookup3,
	dbo.f_info_numeric_people(Owner3,15) AS AM_APOwnerIndex3,
	ISNULL((SELECT NameLast FROM People WHERE PeopleRSN = Owner1),dbo.udf_GetPeopleOrOrganizationName(Owner1)) AS AM_Description,
	dbo.udf_GetPeopleFirstName(Owner1) AS AM_CuO1FirstName,
	ISNULL((SELECT NameLast FROM People WHERE PeopleRSN = Owner2),dbo.udf_GetPeopleOrOrganizationName(Owner2)) AS AM_CuO2LastName,
	dbo.udf_GetPeopleFirstName(Owner2) AS AM_CuO2FirstName,
	ISNULL((SELECT NameLast FROM People WHERE PeopleRSN = Owner3),dbo.udf_GetPeopleOrOrganizationName(Owner3)) AS AM_CuO3LastName,
	dbo.udf_GetPeopleFirstName(Owner3) AS AM_CuO3FirstName,
	dbo.udf_GetPeopleAddressLine1(Owner1) AS AM_CuOStreet1, dbo.udf_GetPeopleAddressLine2(Owner1) AS AM_CuOStreet2, 
	dbo.udf_GetPeopleAddressLine3(Owner1) AS AM_CuOStreet3, dbo.udf_GetPeopleAddressCity(Owner1) AS AM_CuOCity, 
	dbo.udf_GetPeopleAddressState(Owner1) AS AM_CuOState,dbo.udf_GetPeopleAddressZip(Owner1) AS AM_CuOPostal,'','','','','','','','','','','','',''
	FROM uvw_CompareAmandaAProOwners A
--WHERE ParcelID <> '000-0-000-000')
--WHERE ParcelID = '024-2-033-000'
	--ORDER BY ParcelID

DECLARE CurGeneral CURSOR FOR
SELECT AM_ParcelID FROM tblAmanda_Apro_Compare

	OPEN curGeneral
	FETCH NEXT FROM curGeneral INTO @AM_ParcelID
	WHILE @@FETCH_STATUS = 0
		BEGIN

		SET @AP_APAccountNumber = 0 
		SET @AP_APOwnerLookup = 0
		SET @AP_Description = ''
		SET @AP_CuO1FirstName = ''
		SET @AP_CuO2LastName = ''
		SET @AP_CuO2FirstName = ''
		SET @AP_CuO3LastName = ''
		SET @AP_CuO3FirstName = ''
		SET @AP_CuOStreet1 = ''
		SET @AP_CuOStreet2 = '' 
		SET @AP_CuOCity = ''
		SET @AP_CuOState = ''
		SET @AP_CuOPostal = ''

		SELECT @AP_APAccountNumber = DP.AccountNumber, @AP_APOwnerLookup = DP.OwnerLookup, @AP_Description = TOwn.Description,
		@AP_CuO1FirstName = TOwn.CuO1FirstName, @AP_CuO2LastName = TOwn.CuO2LastName, @AP_CuO2FirstName = TOwn.CuO2FirstName,
		@AP_CuO3LastName = TOwn.CuO3LastName, @AP_CuO3FirstName = TOwn.CuO3FirstName, @AP_CuOStreet1 = TOwn.CuOStreet1,
		@AP_CuOStreet2 = TOwn.CuOStreet2, @AP_CuOCity = TOwn.CuOCity, @AP_CuOState = TOwn.CuOState, @AP_CuOPostal = TOwn.CuOPostal
		FROM AssessPro.dbo.DataProperty DP 
		JOIN AssessPro.dbo.TableOwnership TOwn ON DP.OwnerLookUp = TOwn.Code 
		WHERE CardNumber = 1 AND DP.ParcelID = @AM_ParcelID

		UPDATE tblAmanda_Apro_Compare
		SET AP_APAccountNumber = @AP_APAccountNumber, AP_APOwnerLookup = @AP_APOwnerLookup, AP_Description = @AP_Description, 
		AP_Cuo1FirstName = @AP_CuO1FirstName, AP_CuO2LastName = @AP_CuO2LastName, AP_CuO2FirstName = @AP_CuO2FirstName, 
		AP_CuO3LastName = @AP_CuO3LastName, AP_CuO3FirstName = @AP_CuO3FirstName, AP_CuOStreet1 = @AP_CuOStreet1,
		AP_CuOStreet2 = @AP_CuOStreet2, AP_CuOCity = @AP_CuOCity, AP_CuOState = @AP_CuOState, AP_CuOPostal = @AP_CuOPostal
		WHERE AM_ParcelID = @AM_ParcelID

		FETCH NEXT FROM curGeneral INTO @AM_ParcelID

	END

	/* Close the cursor */
	CLOSE curGeneral

	/* Deallocate the cursor */
	DEALLOCATE curGeneral

END
GO
