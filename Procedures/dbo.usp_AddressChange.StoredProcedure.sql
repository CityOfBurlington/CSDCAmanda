USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddressChange]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_AddressChange]
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

DECLARE @StreetAddr VARCHAR(100)
DECLARE @CSZAddr VARCHAR(100)

DECLARE @Address1 VARCHAR(100)
DECLARE @Address2 VARCHAR(100)
DECLARE @Address3 VARCHAR(100)
DECLARE @City VARCHAR(100)
DECLARE @State VARCHAR(100)
DECLARE @ZIP VARCHAR(100)
DECLARE @CountryCode VARCHAR(100)

DECLARE @APDescription VARCHAR(100)
DECLARE @APOwner1FirstName VARCHAR(100)
DECLARE @APOwner2LastName VARCHAR(100)
DECLARE @APOwner2FirstName VARCHAR(100)
DECLARE @AProAddress1 VARCHAR(100)
DECLARE @AProAddress2 VARCHAR(100)

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
@Owner1LastName  = dbo.f_info_alpha(Folder.FolderRSN, 4007),
@Owner1FirstName  = dbo.f_info_alpha(Folder.FolderRSN, 4008),
@Owner2LastName  = dbo.f_info_alpha(Folder.FolderRSN, 4009),
@Owner2FirstName  = dbo.f_info_alpha(Folder.FolderRSN, 4010),
@OrganizationName  = dbo.f_info_alpha(Folder.FolderRSN, 4015),
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

COMMIT TRANSACTION
BEGIN TRANSACTION

/* Work Code is NULL or 4000 (Address Change Only) or 4010 (Address Change AND Name Change) */
IF @WorkCode <> 4005
BEGIN
	SELECT @OwnerCode = O.Code
	FROM cobdb.AssessPro.dbo.TableOwnership O
	INNER JOIN cobdb.AssessPro.dbo.DataProperty P ON O.Code = P.OwnerLookup
	WHERE P.ParcelID = @ParcelID

	--SET @strMessage = 'OwnerCode is ' + str(@OwnerCode)
	--RAISERROR(@strMessage, 16, -1)

    SET @strSQL = 'UPDATE AssessPro.dbo.TableOwnership
     SET 
     CuOStreet1 = ''' + UPPER(RTRIM(LTRIM(@AProAddress1))) + ''', 
     CuOStreet2 = ''' + UPPER(RTRIM(LTRIM(@AProAddress2))) + ''',
     CuOCity = ''' + UPPER(RTRIM(LTRIM(@AddrCity))) + ''', 
     CuOState = ''' + UPPER(RTRIM(LTRIM(@AddrState))) + ''', 
     CuOPostal = ''' + UPPER(RTRIM(LTRIM(@AddrZIP))) + ''', 
     CuOCountyCode = ''' + UPPER(RTRIM(LTRIM(@AddrCountry))) + ''', 
     UpdtDate = GetDate(),
     UpdtUser = ''' + RTRIM(LTRIM(@UserId)) + '''
     WHERE Code = ' + RTRIM(LTRIM(STR(@OwnerCode))) + ''
     
	EXEC master.dbo.sp_executesql @strSQL

END

/* Work Code is 4005 (Name Change ONLY) or 4010 (Name Change AND Address Change */
IF @WorkCode IN (4005, 4010)
BEGIN

   SELECT @APDescription = Description, @APOwner1FirstName = CuO1FirstName,
	@APOwner2LastName = CuO2LastName , @APOwner2FirstName = CuO2FirstName
	FROM cobdb.AssessPro.dbo.TableOwnership
	WHERE Code = @OwnerCode

	IF LEN(@OrganizationName) > 0
	BEGIN
		IF @OrganizationName <> @APDescription SET @APDescription = @OrganizationName
		IF @Owner1FirstName IS NOT NULL
		BEGIN
			IF @Owner1FirstName <> @APOwner1FirstName SET @APOwner1FirstName = @Owner1FirstName
		END
	END
	ELSE
	BEGIN
        SET @OrganizationName = NULL

		IF LEN(@Owner1LastName) > 0
		BEGIN
			IF @Owner1LastName <> @APDescription SET @APDescription = @Owner1LastName
		END
		IF LEN(@Owner1FirstName) > 0
		BEGIN
			IF @Owner1FirstName <> @APOwner1FirstName SET @APOwner1FirstName = @Owner1FirstName
		END
		IF LEN(@Owner2LastName) > 0
		BEGIN
			IF @Owner2LastName <> @APOwner2LastName SET @APOwner2LastName = @Owner2LastName
		END
		IF LEN(@Owner2FirstName) > 0
		BEGIN
			IF @Owner2FirstName <> @APOwner2FirstName SET @APOwner2FirstName = @Owner2FirstName
		END
	END
	SET @strSQL = 'UPDATE AssessPro.dbo.TableOwnership
	  SET 
	  Description = ''' + UPPER(RTRIM(LTRIM(ISNULL(@APDescription,'')))) + ''', 
	  CuO1FirstName = ''' + UPPER(RTRIM(LTRIM(ISNULL(@APOwner1FirstName,'')))) + ''', 
	  CuO2FirstName = ''' + UPPER(RTRIM(LTRIM(ISNULL(@APOwner2FirstName,'')))) + ''', 
	  CuO2LastName = ''' + UPPER(RTRIM(LTRIM(ISNULL(@APOwner2LastName,'')))) + ''',
	  UpdtDate = GetDate(),
	  UpdtUser = ''' + RTRIM(LTRIM(@UserId)) + '''
	  WHERE Code = ' + RTRIM(LTRIM(STR(@OwnerCode))) + ''

	EXEC master.dbo.sp_executesql @strSQL

END

DECLARE @intCOMReturnValue  INT

EXEC @intCOMReturnValue = xspInsertOwnerIntoNemrc @ParcelID

IF @intCOMReturnValue = 1 
BEGIN
    RAISERROR('Failed to update NEMRC tax database(1)', 16, -1)
END


GO
