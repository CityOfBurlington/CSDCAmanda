USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_DuplicatePeoplePurge]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DuplicatePeoplePurge]
AS

BEGIN

/* Summary: This stored procedure builds a table of all people that have duplicate records in the AMANDA People table. The 
   definition of "duplicate" can be as broad or as narrow as needed. After the list of duplicate names is built, a second 
   table is populated grouping together all the PeopleRSNs for people identified as having duplicates. Once all duplicates
   have been identified, a new cursor is created to work through the groups. For each group, the highest peopleRSN in the 
   group is identified, then all instances of the other PeopleRSNs are replaced in all tables by the highest RSN. This
   mimics the logic for "Replace Marked by Unmarked", using the highest PeopleRSN in the group as the "Unmarked".
   
Step 1 - Initialize tables: All data is deleted from tblDuplicateData and tblDuplicateRSN
Step 2 - Identify duplicate people: Run a query to insert one record for each person or organization identified as having at 
         least one duplicate
Step 3 - Build a list of duplicate group members: Using a cursor, select all the individuals who match each duplicate group
         in tblDuplicateData. The list includes the PeopleRSN and DupGroup (an arbitrary group number for each duplicate
         grouping). I also add a couple of other fields import to us, such as an indication of whether each People owns
         property anywhere in the city.
Step 4 - Create a cursor to purge records: cursor is based on the duplicate group number as build above.
Step 5 - Find the highest PeopleRSN in the dup group: this is the one we're keeping 
Step 6 - "Replace Marked by Unmarked": in all tables, replace outgoing PeopleRSN with the PeopleRSN we're keeping
Step 7 - Delete from People table: mow delete all the duplicate people records from the People table 
Step 8 - Delete the DupGroup: delete the group just processed from tblDuplicateRSN
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
,EmailAddress VARCHAR(128) 
,ParentRSN INT
,AddrStreetPrefix VARCHAR(2)  
,StatusCode INT  
,ReferenceFile VARCHAR(20) 
)
*/

/* Step 1: All data is deleted from tblDuplicateData and tblDuplicateRSN */
DELETE FROM tblDuplicateData
DELETE FROM tblDuplicateRSN

/* Step 2: Run a query to insert one record for each person or organization identified as having at least one duplicate */
INSERT INTO tblDuplicateData
SELECT NameFirst,NameLast,OrganizationName,AddrHouse,AddrStreet,AddrStreetType,AddrStreetDirection,AddrUnitType,AddrUnit,AddrCity,
   AddrProvince,AddrCountry,AddrPostal,Phone1,Phone1Desc,Phone2,Phone2Desc,BirthDate,
   AddrPrefix,AddressLine1,AddressLine2,AddressLine3,AddressLine4,
   EmailAddress,ParentRSN,AddrStreetPrefix,StatusCode,ReferenceFile
FROM People
/* The GROUP BY below is where you can define what fields records must match on to be considered duplicates. A narrow definition
   of "duplicate" would require that records match on a lot of fields. A wide definition would only require matches on few 
   fields. Its possible to go to wide. You wouldn't want to only use NameFirst and consider anyone who matches on only this
   field to be duplicate (all Aarons, all Adams, etc). I chose to start with a narrow definition and gradually tighten it. */
GROUP BY NameFirst,NameLast,OrganizationName,AddrHouse,AddrStreet,AddrStreetType,AddrStreetDirection,AddrUnitType,AddrUnit,AddrCity,
   AddrProvince,AddrCountry,AddrPostal,Phone1,Phone1Desc,Phone2,Phone2Desc,LicenceNumber,BirthDate,
   AddrPrefix,AddressLine1,AddressLine2,AddressLine3,AddressLine4,Phone3,Phone3Desc,
   EmailAddress,ParentRSN,AddrStreetPrefix,StatusCode,ReferenceFile
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
	ISNULL(AddressLine3,''),ISNULL(AddressLine4,''),ISNULL(EmailAddress,''),ISNULL(ParentRSN,0),
	ISNULL(AddrStreetPrefix,''),ISNULL(StatusCode,0),ISNULL(ReferenceFile,'')
FROM tblDuplicateData

	/* Open the cursor */
	OPEN curGeneral

	/* Fetch the first value */
	FETCH NEXT FROM curGeneral INTO @NameFirst,@NameLast,@OrganizationName,@AddrHouse,@AddrStreet,@AddrStreetType,@AddrStreetDirection,
	@AddrUnitType,@AddrUnit,@AddrCity,@AddrProvince,@AddrCountry,@AddrPostal,@Phone1,@Phone1Desc,@Phone2,@Phone2Desc,
	@BirthDate,@AddrPrefix,@AddressLine1,@AddressLine2,@AddressLine3,@AddressLine4,@EmailAddress,@ParentRSN,
	@AddrStreetPrefix,@StatusCode,@ReferenceFile

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
			ISNULL(AddressLine2,'') = @AddressLine2 AND ISNULL(AddressLine3,'') = @AddressLine3 AND ISNULL(AddressLine4,'') = @AddressLine4 AND 
			ISNULL(EmailAddress,'') = @EmailAddress AND
			ISNULL(ParentRSN,0) = @ParentRSN AND ISNULL(AddrStreetPrefix,'') = @AddrStreetPrefix AND ISNULL(StatusCode,0) = @StatusCode AND 
			ISNULL(ReferenceFile,'') = @ReferenceFile

		/* Fetch the next value till done */
		FETCH NEXT FROM curGeneral INTO @NameFirst,@NameLast,@OrganizationName,@AddrHouse,@AddrStreet,@AddrStreetType,@AddrStreetDirection,
		@AddrUnitType,@AddrUnit,@AddrCity,@AddrProvince,@AddrCountry,@AddrPostal,@Phone1,@Phone1Desc,@Phone2,@Phone2Desc,
		@BirthDate,@AddrPrefix,@AddressLine1,@AddressLine2,@AddressLine3,@AddressLine4,@EmailAddress,@ParentRSN,
		@AddrStreetPrefix,@StatusCode,@ReferenceFile
	END

	/* Close the cursor */
	CLOSE curGeneral

	/* Deallocate the cursor */
	DEALLOCATE curGeneral

	/* Display the results */
	SELECT * FROM tblDuplicateData
	SELECT * FROM tblDuplicateRSN  ORDER BY DupGroup


DECLARE @DupGroup INT
DECLARE @KeepRSN INT
DECLARE @FolderRSN INT

/* Step 4 - Create a cursor to purge records: the cursor is based on the duplicate group number as built above. For each group in
            the cursor, all but one People record will ultimately be deleted. The cursor can include all duplicate groups
            or can be limited by select criteria. For example, property owners could be excluded from the purge.
*/

/* DECLARE the cursor and select the groups to work on purging into it */
DECLARE CurGeneral CURSOR FOR
--SELECT DupGroup FROM tblDuplicateRSN GROUP BY DupGroup HAVING Sum(Owner) = 0 AND Count(DISTINCT APCode) = 1 AND Count(DISTINCT APIndex) = 1
SELECT DupGroup FROM tblDuplicateRSN GROUP BY DupGroup HAVING Count(DISTINCT APCode) = 1 AND Count(DISTINCT APIndex) = 1
ORDER BY DupGroup

	/* Open the cursor */
	OPEN curGeneral

	/* Fetch the first value */
	FETCH NEXT FROM curGeneral INTO @DupGroup

	/* Loop through the cursor */
	WHILE @@FETCH_STATUS = 0
		BEGIN

		/* Step 5 - Find the highest PeopleRSN in the dup group: this is the one we're keeping */
		SELECT TOP 1 @KeepRSN = PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		ORDER BY PeopleRSN DESC

		/* Step 6 - "Replace Marked by Unmarked": in all tables, replace outgoing PeopleRSN with the PeopleRSN we're keeping */

		/* AccountPayment */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE AccountPayment SET BillToRSN = @KeepRSN WHERE BillToRSN in 
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* DefaultDocument */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE DefaultDocument SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* FolderDocument */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderDocument SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* FolderDocumentTo */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderDocumentTo SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* FolderInspectionRequest */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderInspectionRequest SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* FolderPeople: */
		/* Delete records for folders with multiple duplicates */
		DELETE FROM FolderPeople 
		WHERE FolderRSN IN (SELECT FolderRSN FROM FolderPeople WHERE PeopleRSN = @KeepRSN) 
		AND PeopleRSN IN (SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Replace outgoing PeopleRSN with PeopleRSN we're keeping */
		UPDATE FolderPeople SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* FolderProcessPeople */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderProcessPeople SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* PropertyPeople: */
		/* Delete records for folders with multiple duplicates */
		DELETE FROM PropertyPeople 
		WHERE PropertyRSN IN (SELECT PropertyRSN FROM PropertyPeople WHERE PeopleRSN = @KeepRSN) 
		AND PeopleRSN IN (SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Replace outgoing PeopleRSN with PeopleRSN we're keeping */
		UPDATE PropertyPeople SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Step 7 - Delete from People table: mow delete all the duplicate people records from the People table */
		DELETE FROM People WHERE PeopleRSN IN 
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Step 8 - Delete the DupGroup: delete the group just processed from tblDuplicateRSN */
		DELETE FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup

		/* Fetch the next value till done */
		FETCH NEXT FROM curGeneral INTO @DupGroup
	END

	/* Close the cursor */
	CLOSE curGeneral

	/* Deallocate the cursor */
	DEALLOCATE curGeneral

END

GO
