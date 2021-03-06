USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddressChangeSetup]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_AddressChangeSetup]
@FolderRSN numeric(10), @UserId char(128)
as

DECLARE @PeopleRSN INT
DECLARE @ParcelID VARCHAR(20)
DECLARE @strSQL NVARCHAR(2000)
DECLARE @PropertyRSN INT
DECLARE @strMessage VARCHAR(256)

DECLARE @AddrPrefix VARCHAR(64)
DECLARE @AddrHouse VARCHAR(20)
DECLARE @AddrStreetPrefix VARCHAR(2)
DECLARE @AddrStreet VARCHAR(40)
DECLARE @AddrStreetType VARCHAR(10)
DECLARE @AddrStreetDirection CHAR(2)
DECLARE @AddrUnitType CHAR(5)
DECLARE @AddrUnit VARCHAR(10)
DECLARE @AddrCity VARCHAR(40)
DECLARE @AddrState VARCHAR(2)
DECLARE @AddrZip VARCHAR(40)
DECLARE @AddrCountry VARCHAR(12)
DECLARE @WorkCode INT
DECLARE @NextRowNumber INT

DECLARE @StreetAddr VARCHAR(100)
DECLARE @CSZAddr VARCHAR(100)

DECLARE @Address1 VARCHAR(100)
DECLARE @Address2 VARCHAR(100)
DECLARE @Address3 VARCHAR(100)
DECLARE @City VARCHAR(100)
DECLARE @State VARCHAR(100)
DECLARE @ZIP VARCHAR(100)
DECLARE @CountryCode VARCHAR(100)

DECLARE @APDescription VARCHAR(30)
DECLARE @APOwner1FirstName VARCHAR(25)
DECLARE @APOwner2LastName VARCHAR(30)
DECLARE @APOwner2FirstName VARCHAR(25)
DECLARE @AProAddress1 VARCHAR(40)
DECLARE @AProAddress2 VARCHAR(40)

DECLARE @Owner1LastName VARCHAR(100)
DECLARE @Owner1FirstName VARCHAR(100)
DECLARE @Owner2LastName VARCHAR(100)
DECLARE @Owner2FirstName VARCHAR(100)
DECLARE @Owner3LastName VARCHAR(100)
DECLARE @Owner3FirstName VARCHAR(100)
DECLARE @OrganizationName VARCHAR(50)

DECLARE @OwnerCode INT

SELECT TOP 1 @PeopleRSN = PeopleRSN 
FROM FolderPeople 
WHERE PeopleCode = 2 AND FolderRSN = @FolderRSN

SELECT @ParcelID = Property.PropertyRoll, @PropertyRSN = Folder.PropertyRSN
FROM Property
INNER JOIN Folder ON Property.PropertyRSN = Folder.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN

--SET @strMessage = 'OwnerCode is ' + str(@OwnerCode)
--RAISERROR(@strMessage, 16, -1)

SELECT @AddrPrefix = dbo.f_info_alpha(Folder.FolderRSN, 4100),
@AddrHouse  = dbo.f_info_alpha(Folder.FolderRSN, 4102),
@AddrStreetPrefix = dbo.f_info_alpha(Folder.FolderRSN, 4104),
@AddrStreet = dbo.f_info_alpha(Folder.FolderRSN, 4106),
@AddrStreetType = dbo.f_info_alpha(Folder.FolderRSN, 4108),
@AddrStreetDirection = dbo.f_info_alpha(Folder.FolderRSN, 4110),
@AddrUnitType = dbo.f_info_alpha(Folder.FolderRSN, 4112),
@AddrUnit = dbo.f_info_alpha(Folder.FolderRSN, 4114),
@AddrCity  = dbo.f_info_alpha(Folder.FolderRSN, 4116),
@AddrState  = dbo.f_info_alpha(Folder.FolderRSN, 4118),
@AddrCountry = dbo.f_info_alpha(Folder.FolderRSN, 4120),
@AddrZip  = dbo.f_info_alpha(Folder.FolderRSN, 4122),
@Owner1LastName  = LEFT(dbo.f_info_alpha(Folder.FolderRSN, 4007),30),
@Owner1FirstName  = dbo.f_info_alpha(Folder.FolderRSN, 4008),
@Owner2LastName  = dbo.f_info_alpha(Folder.FolderRSN, 4009),
@Owner2FirstName  = dbo.f_info_alpha(Folder.FolderRSN, 4010),
@OrganizationName  = LEFT(dbo.f_info_alpha(Folder.FolderRSN, 4015),30),
@WorkCode = WorkCode 
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

IF @AddrHouse IS NOT NULL SET @StreetAddr = @AddrHouse + ' ' 
IF LEN(LTRIM(@AddrStreetPrefix)) > 0 SET @StreetAddr = @StreetAddr + @AddrStreetPrefix + ' '
IF @AddrStreet IS NOT NULL SET @StreetAddr = @StreetAddr + @AddrStreet + ' '
IF @AddrStreetType IS NOT NULL SET @StreetAddr = @StreetAddr + @AddrStreetType + ' '
IF @AddrStreetDirection IS NOT NULL SET @StreetAddr = @StreetAddr + @AddrStreetDirection + ' '
IF @AddrUnitType IS NOT NULL SET @StreetAddr = @StreetAddr + @AddrUnitType + ' '
IF @AddrUnit IS NOT NULL SET @StreetAddr = @StreetAddr + @AddruNIT

SET @CSZAddr = @AddrCity + ' ' + @AddrState + '  ' + @AddrZip

IF LEN(@AddrPrefix) > 0
BEGIN
    SET @Address1 = @AddrPrefix
    SET @AProAddress1 = @AddrPrefix
END

IF LEN(@StreetAddr) > 0
BEGIN
    IF @Address1 IS NULL
    BEGIN
        SET @Address1 = @StreetAddr
        SET @AProAddress1 = @StreetAddr
    END
    ELSE
    BEGIN
        SET @Address2 = @StreetAddr
        SET @AProAddress2 = @StreetAddr
    END
END

IF LEN(@CSZAddr) > 0
BEGIN
    IF @Address1 IS NULL 
    BEGIN
        SET @Address1 = @CSZAddr
        SET @AProAddress1 = ''
        SET @AProAddress2 = ''
    END
    ELSE
    BEGIN
        IF @Address2 IS NULL 
        BEGIN
            SET @Address2 = @CSZAddr
            SET @AProAddress2 = ''
        END
        ELSE
        BEGIN
            SET @Address3 = @CSZAddr
        END
     END
END

UPDATE People
SET AddrPrefix =  NULL,
    AddrHouse = NULL,
    AddrStreetPrefix = NULL,
    AddrStreet = NULL,
    AddrStreetType = NULL,
    AddrStreetDirection = NULL,
    AddrUnitType = NULL,
    AddrUnit = NULL,
    AddrCity = NULL,
    AddrProvince = NULL,
    AddrCountry = NULL,
    AddrPostal = NULL,
    AddressLine1 = NULL,
    AddressLine2 = NULL,
    AddressLine3 = NULL,
    AddressLine4 = NULL,
    AddressLine5 = NULL
WHERE PeopleRSN IN (SELECT PeopleRSN 
FROM FolderPeople  WHERE PeopleCode = 2 AND FolderRSN = @FolderRSN)

UPDATE People
SET AddrPrefix =  @AddrPrefix,
    AddrHouse = @AddrHouse,
    AddrStreetPrefix = @AddrStreetPrefix,
    AddrStreet = @AddrStreet,
    AddrStreetType = @AddrStreetType,
    AddrStreetDirection = @AddrStreetDirection,
    AddrUnitType = @AddrUnitType,
    AddrUnit = @AddrUnit,
    AddrCity = @AddrCity,
    AddrProvince = @AddrState,
    AddrCountry = @AddrCountry,
    AddrPostal = @AddrZip,
    AddressLine1 = @Address1,
    AddressLine2 = @Address2,
    AddressLine3 = @Address3
WHERE PeopleRSN IN (SELECT PeopleRSN 
FROM FolderPeople  WHERE PeopleCode = 2 AND FolderRSN = @FolderRSN)

/* Work Code is 4005 (Name Change ONLY) or 4010 (Name Change AND Address Change */
IF @WorkCode IN (4005, 4010)
BEGIN
	UPDATE People
	SET NameFirst =  NULL,
		NameLast = NULL,
		OrganizationName = NULL
	WHERE PeopleRSN IN (SELECT PeopleRSN 
	FROM FolderPeople  WHERE PeopleCode = 2 AND FolderRSN = @FolderRSN)

	UPDATE People
	SET NameFirst = @Owner1FirstName,
		NameLast = @Owner1LastName,
		OrganizationName = @OrganizationName
	WHERE PeopleRSN IN (SELECT PeopleRSN 
	FROM FolderPeople  WHERE PeopleCode = 2 AND FolderRSN = @FolderRSN)
END

--COMMIT TRANSACTION
--BEGIN TRANSACTION

/* Update AssessPro interface table (tblAPTableOwnership) */
/* Work Code is 4000 (Address Change Only) */
IF @WorkCode = 4000
BEGIN

	SELECT @NextRowNumber = MAX(RowNumber)+1 FROM tblAPTableOwnership
	INSERT INTO tblAPTableOwnership
		(RowNumber, ParcelID, FolderRSN, OrganizationName, Owner1LastName, Owner1FirstName, Owner2LastName, Owner2FirstName, 
		AddrStreet1, AddrStreet2, AddrCity, AddrState, AddrPostal, AddrCountyCode, WorkCode, UpdtDate, UpdtUser, 
		SentToAProDate)
	VALUES(@NextRowNumber, @ParcelID, @FolderRSN, NULL, NULL, NULL, NULL, NULL, @AProAddress1, @AProAddress2, 
		@AddrCity, @AddrState, @AddrZIP, @AddrCountry, @WorkCode, Getdate(), @UserID, NULL)

END
/* Work Code is 4005 (Name Change Only) */
IF @WorkCode = 4005
BEGIN
	SELECT @NextRowNumber = MAX(RowNumber)+1 FROM tblAPTableOwnership
	INSERT INTO tblAPTableOwnership
		(RowNumber, ParcelID, FolderRSN, OrganizationName, Owner1LastName, Owner1FirstName, Owner2LastName, Owner2FirstName, 
		AddrStreet1, AddrStreet2, AddrCity, AddrState, AddrPostal, AddrCountyCode, WorkCode, UpdtDate, UpdtUser, 
		SentToAProDate)
	VALUES(@NextRowNumber, @ParcelID, @FolderRSN, @OrganizationName, @Owner1LastName, @Owner1FirstName, @Owner2LastName, @Owner2FirstName,
		NULL, NULL, NULL, NULL, NULL, NULL, @WorkCode, Getdate(), @UserID, NULL)
END 

/* Work Code 4010 (Address Change AND Name Change) */
IF @WorkCode = 4010
BEGIN
	SELECT @NextRowNumber = MAX(RowNumber)+1 FROM tblAPTableOwnership
	INSERT INTO tblAPTableOwnership
		(RowNumber, ParcelID, FolderRSN, OrganizationName, Owner1LastName, Owner1FirstName, Owner2LastName, Owner2FirstName, 
		AddrStreet1, AddrStreet2, AddrCity, AddrState, AddrPostal, AddrCountyCode, WorkCode, UpdtDate, UpdtUser, 
		SentToAProDate)
	VALUES(@NextRowNumber, @ParcelID, @FolderRSN, @OrganizationName, @Owner1LastName, @Owner1FirstName, @Owner2LastName, @Owner2FirstName, 
		@AProAddress1, @AProAddress2, @AddrCity, @AddrState, @AddrZIP, @AddrCountry, @WorkCode, Getdate(), @UserID, NULL)
END 

/* Update NEMRC 
DECLARE @intCOMReturnValue  INT

EXEC @intCOMReturnValue = xspInsertOwnerIntoNemrc @ParcelID

IF @intCOMReturnValue = 1 
BEGIN
    RAISERROR('Failed to update NEMRC tax database(1)', 16, -1)
END
*/

GO
