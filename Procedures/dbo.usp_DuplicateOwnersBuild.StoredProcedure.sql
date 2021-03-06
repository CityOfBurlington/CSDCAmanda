USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_DuplicateOwnersBuild]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DuplicateOwnersBuild]
AS

BEGIN

/* Summary: This stored procedure builds a table of all people that have duplicate records in the AMANDA People table. The 
   definition of "duplicate" can be as broad or as narrow as needed. After the list of duplicate names is built, as second 
   table is populated grouping together all the PeopleRSNs for people identified as having duplicates. 
   
Step 1 - Initialize tables: All data is deleted from tblDuplicateData and tblDuplicateRSN
Step 2 - Identify duplicate people: Run a query to insert one record for each person or organization identified as having at 
         least one duplicate
Step 3 - Build a list of duplicate group members: Using a cursor, select all the individuals who match each duplicate group
         in tblDuplicateData. The list includes the PeopleRSN and DupGroup (an arbitrary group number for each duplicate
         grouping). I also add a couple of other fields import to us, such as an indication of whether each People owns
         property anywhere in the city.   
*/

DECLARE @PeopleRSN INT
DECLARE @NameTitle char(4) 
DECLARE @NameFirst VARCHAR(25)
DECLARE @NameLast VARCHAR(25)
DECLARE @OrganizationName VARCHAR(50)
DECLARE @AddrHouse VARCHAR(20)
DECLARE @AddrStreet VARCHAR(40)
DECLARE @AddrStreetType VARCHAR(10)
DECLARE @AddrStreetDirection CHAR(2)
DECLARE @AddrUnitType CHAR(5)
DECLARE @AddrUnit VARCHAR(10)
DECLARE @AddrCity VARCHAR(40)
DECLARE @AddrProvince CHAR(2)
DECLARE @AddrCountry VARCHAR(40)
DECLARE @AddrPostal VARCHAR(12)
DECLARE @Phone1 VARCHAR(32)
DECLARE @Phone1Desc CHAR(8)
DECLARE @Phone2 VARCHAR(32)
DECLARE @Phone2Desc CHAR(8)
DECLARE @LicenceNumber VARCHAR(25)
DECLARE @PeopleCode INT
DECLARE @ContactSex CHAR(1) 
DECLARE @BirthDate DATETIME  
DECLARE @FamilyRSN INT  
DECLARE @Comments VARCHAR(255)
DECLARE @StampDate DATETIME  
DECLARE @StampUser VARCHAR(128) 
DECLARE @AddrPrefix VARCHAR(64) 
DECLARE @AddressLine1 VARCHAR(60) 
DECLARE @AddressLine2 VARCHAR(60) 
DECLARE @AddressLine3 VARCHAR(60) 
DECLARE @AddressLine4 VARCHAR(60) 
DECLARE @AddressLine5 VARCHAR(60) 
DECLARE @AddressLine6 VARCHAR(60) 
DECLARE @AddrHouseNumeric INT  
DECLARE @Phone3 VARCHAR(32) 
DECLARE @Phone3Desc VARCHAR(8) 
DECLARE @EmailAddress VARCHAR(128) 
DECLARE @NameFirstUpper VARCHAR(25) 
DECLARE @NameLastUpper VARCHAR(25) 
DECLARE @OrgNameUpper VARCHAR(50) 
DECLARE @AddrStreetUpper VARCHAR(40) 
DECLARE @ParentRSN INT  
DECLARE @AddrStreetPrefix VARCHAR(2) 
DECLARE @Nearby VARCHAR(40) 
DECLARE @Community VARCHAR(60) 
DECLARE @Phone4 VARCHAR(32) 
DECLARE @Phone4Desc VARCHAR(8) 
DECLARE @StatusType VARCHAR(10) 
DECLARE @HealthCard VARCHAR(15) 
DECLARE @StatusCode INT  
DECLARE @SecurityCode INT  
DECLARE @ReferenceFile VARCHAR(20) 
DECLARE @InternetPassword VARCHAR(64) 
DECLARE @InternetAccess CHAR(1) 
DECLARE @InternetQuestion VARCHAR(255) 
DECLARE @InternetAnswer VARCHAR(255) 
DECLARE @CreditCardProcessingFlag CHAR(1) 
DECLARE @InternetRegistrationDate DATETIME 
DECLARE @intGroup INT

/*
DROP TABLE tblDuplicateData
CREATE TABLE tblDuplicateData
(NameFirst VARCHAR(25)
,NameLast VARCHAR(25)
,OrganizationName VARCHAR(50)
,AddrHouse VARCHAR(20)
,AddrStreet VARCHAR(40)
,AddrStreetType VARCHAR(10)
,AddrStreetDirection CHAR(2)
,AddrUnitType CHAR(5)
,AddrUnit VARCHAR(10)
,AddrCity VARCHAR(40)
,AddrProvince CHAR(2)
,AddrCountry VARCHAR(40)
,AddrPostal VARCHAR(12)
,Phone1 VARCHAR(32)
,Phone1Desc CHAR(8)
,Phone2 VARCHAR(32)
,Phone2Desc CHAR(8)
--,LicenceNumber VARCHAR(25)
,BirthDate DATETIME  
,AddrPrefix VARCHAR(64) 
,AddressLine1 VARCHAR(60) 
,AddressLine2 VARCHAR(60) 
,AddressLine3 VARCHAR(60) 
,AddressLine4 VARCHAR(60) 
--,Phone3 VARCHAR(32) 
--,Phone3Desc VARCHAR(8) 
--,EmailAddress VARCHAR(128) 
--,ParentRSN INT
--,AddrStreetPrefix VARCHAR(2)  
--,StatusCode INT  
--,ReferenceFile VARCHAR(20) 
)
*/

/* Step 1: All data is deleted from tblDuplicateData and tblDuplicateRSN */
DELETE FROM tblDuplicateData
DELETE FROM tblDuplicateRSN

/* Step 2: Run a query to insert one record for each person or organization identified as having at least one duplicate */
INSERT INTO tblDuplicateData
SELECT NameFirst,NameLast,OrganizationName,AddrHouse,AddrStreet,AddrStreetType,AddrStreetDirection,AddrUnitType,AddrUnit,AddrCity,
   AddrProvince,AddrCountry,AddrPostal,Phone1,Phone1Desc,Phone2,Phone2Desc,BirthDate,
   AddrPrefix,AddressLine1,AddressLine2,AddressLine3,AddressLine4
FROM People
/* The GROUP BY below is where you can define what fields records must match on to be considered duplicates. A narrow definition
   of "duplicate" would require that records match on a lot of fields. A wide definition would only require matches on few 
   fields. Its possible to go to wide. You wouldn't want to only use NameFirst and consider anyone who matches on only this
   field to be duplicate (all Aarons, all Adams, etc). I chose to start with a narrow definition and gradually tighten it. */
GROUP BY NameFirst,NameLast,OrganizationName,AddrHouse,AddrStreet,AddrStreetType,AddrStreetDirection,AddrUnitType,AddrUnit,AddrCity,
   AddrProvince,AddrCountry,AddrPostal,Phone1,Phone1Desc,Phone2,Phone2Desc,LicenceNumber,BirthDate,
   AddrPrefix,AddressLine1,AddressLine2,AddressLine3,AddressLine4
HAVING COUNT(*) > 1
ORDER BY OrganizationName
--ORDER BY COUNT(*)

/*
CREATE TABLE tblDuplicateRSN
(DupGroup INT
 ,PeopleRSN INT
 ,Owner INT
 ,APCode VARCHAR(8)
 ,APIndex INT)
*/

/* Step 3 - Build a list of duplicate group members: Using a cursor, Work through all the duplicate data and find and save the 
            PeopleRSN for each along with an indicator (DupGroup) of which RSNs group together.
            
            I also add a couple of other fields import to us: the count from PropertyPeople on which the PeopleRSN is entered 
            as owner (PeopleCode = 2) indicating they own property somewhere in the city and and the AssessPro owner code 
            (InfoCode = 10) and AssessPro owner index (InfoCode = 15), if any, found in the PeopleInfo table. (AssessPro is 
            our mass appraisal software and these info codes link Amanda People records to owner records in AssessPro).
*/
   
/* DECLARE the cursor and select all the tmpDuplicateData records into it. */
DECLARE CurGeneral CURSOR FOR
SELECT ISNULL(NameFirst,''),ISNULL(NameLast,''),ISNULL(OrganizationName,''),ISNULL(AddrHouse,''),ISNULL(AddrStreet,''),
	ISNULL(AddrStreetType,''),ISNULL(AddrStreetDirection,''),ISNULL(AddrUnitType,''),ISNULL(AddrUnit,''),ISNULL(AddrCity,''),
	ISNULL(AddrProvince,''),ISNULL(AddrCountry,''),ISNULL(AddrPostal,''),ISNULL(Phone1,''),ISNULL(Phone1Desc,''),ISNULL(Phone2,''),
	ISNULL(Phone2Desc,''),ISNULL(BirthDate,''),ISNULL(AddrPrefix,''),ISNULL(AddressLine1,''),ISNULL(AddressLine2,''),
	ISNULL(AddressLine3,''),ISNULL(AddressLine4,'')
FROM tblDuplicateData

	/* Open the cursor */
	OPEN curGeneral

	/* Fetch the first value */
	FETCH NEXT FROM curGeneral INTO @NameFirst,@NameLast,@OrganizationName,@AddrHouse,@AddrStreet,@AddrStreetType,@AddrStreetDirection,
	@AddrUnitType,@AddrUnit,@AddrCity,@AddrProvince,@AddrCountry,@AddrPostal,@Phone1,@Phone1Desc,@Phone2,@Phone2Desc,
	@BirthDate,@AddrPrefix,@AddressLine1,@AddressLine2,@AddressLine3,@AddressLine4
	
	SET @intGroup = 0
	/* Loop through the cursor */
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @intGroup = @intGroup + 1

			/* Find and save the PeopleRSN and group number for all duplicate records. */
			INSERT INTO tblDuplicateRSN SELECT @intGroup, PeopleRSN, 
			(SELECT count(*) FROM PropertyPeople PP WHERE People.PeopleRSN = PP.PeopleRSN AND PeopleCode = 2) AS Owner, 
			ISNULL(dbo.udf_GetAssessProOwnerCode(PeopleRSN),'') AS APCode, 
			ISNULL(dbo.udf_GetAssessProOwnerIndex(PeopleRSN),0) AS APIndex 
			FROM People WHERE
			ISNULL(NameFirst,'') = @NameFirst AND ISNULL(NameLast,'') = @NameLast AND ISNULL(OrganizationName,'') = @OrganizationName AND
			ISNULL(AddrHouse,'') = @AddrHouse AND ISNULL(AddrStreet,'') = @AddrStreet AND ISNULL(AddrStreetType,'') = @AddrStreetType AND 
			ISNULL(AddrStreetDirection,'') = @AddrStreetDirection AND ISNULL(AddrUnitType,'') = @AddrUnitType AND ISNULL(AddrUnit,'') = @AddrUnit AND 
			ISNULL(AddrCity,'') = @AddrCity AND ISNULL(AddrProvince,'') = @AddrProvince AND ISNULL(AddrCountry,'') = @AddrCountry AND 
			ISNULL(AddrPostal,'') = @AddrPostal AND ISNULL(Phone1,'') = @Phone1 AND ISNULL(Phone1Desc,'') = @Phone1Desc AND
			ISNULL(Phone2,'') = @Phone2 AND ISNULL(Phone2Desc,'') = @Phone2Desc AND 
			ISNULL(BirthDate,'') = @BirthDate AND ISNULL(AddrPrefix,'') = @AddrPrefix AND ISNULL(AddressLine1,'') = @AddressLine1 AND 
			ISNULL(AddressLine2,'') = @AddressLine2 AND ISNULL(AddressLine3,'') = @AddressLine3 AND ISNULL(AddressLine4,'') = @AddressLine4

		/* Fetch the next value till done */
		FETCH NEXT FROM curGeneral INTO @NameFirst,@NameLast,@OrganizationName,@AddrHouse,@AddrStreet,@AddrStreetType,@AddrStreetDirection,
		@AddrUnitType,@AddrUnit,@AddrCity,@AddrProvince,@AddrCountry,@AddrPostal,@Phone1,@Phone1Desc,@Phone2,@Phone2Desc,
		@BirthDate,@AddrPrefix,@AddressLine1,@AddressLine2,@AddressLine3,@AddressLine4
	END

	/* Close the cursor */
	CLOSE curGeneral

	/* Deallocate the cursor */
	DEALLOCATE curGeneral

	/* Display the results */
	SELECT * FROM tblDuplicateData
	SELECT * FROM tblDuplicateRSN  ORDER BY DupGroup

END

GO
