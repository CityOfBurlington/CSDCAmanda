USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ADDR_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ADDR_Folder]
@FolderRSN INT, @UserId char(128)
as
DECLARE @NextRSN INT
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
   FROM AccountBillFee
 
 DECLARE @PropertyRSN int
 DECLARE @PeopleRSN int
 DECLARE @ParcelID VARCHAR(20)
 
 DECLARE @NameFirst VARCHAR(25)
 DECLARE @NameLast VARCHAR(25)
 DECLARE @OrganizationName VARCHAR(50)
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
 
 DECLARE @Address1 VARCHAR(100)
 DECLARE @Address2 VARCHAR(100)
 DECLARE @City VARCHAR(100)
 DECLARE @State VARCHAR(100)
 DECLARE @ZIP VARCHAR(100)
 DECLARE @CountryCode VARCHAR(100)

DECLARE @Owner1LastName VARCHAR(100)
DECLARE @Owner1FirstName VARCHAR(100)
DECLARE @Owner2LastName VARCHAR(100)
DECLARE @Owner2FirstName VARCHAR(100)
DECLARE @Owner3LastName VARCHAR(100)
DECLARE @Owner3FirstName VARCHAR(100)

DECLARE @strMessage VARCHAR(50)

SELECT @PropertyRSN = Property.PropertyRSN, @ParcelID = Property.PropertyRoll
FROM Property
INNER JOIN Folder ON Property.PropertyRSN = Folder.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN

SELECT TOP 1 @PeopleRSN = PropertyPeople.PeopleRSN
FROM PropertyPeople 
WHERE PropertyPeople.PropertyRSN = @PropertyRSN AND PropertyPeople.PeopleCode = 2
ORDER BY PropertyPeople.PeopleRSN

--SET @strMessage = str(@PeopleRSN)
--RAISERROR(@strMessage, 16, -1)

SELECT @ParcelID = Property.PropertyRoll
FROM Property
INNER JOIN Folder ON Property.PropertyRSN = Folder.PropertyRSN

SELECT @NameFirst = PPL.NameFirst, @NameLast = PPL.NameLast, @OrganizationName = PPL.OrganizationName, 
@AddrPrefix = PPL.AddrPrefix, @AddrHouse = PPL.AddrHouse, @AddrStreetPrefix = PPL.AddrStreetPrefix,
@AddrStreet = PPL.AddrStreet, @AddrStreetType = PPL.AddrStreetType, @AddrStreetDirection = PPL.AddrStreetDirection,
@AddrUnitType = PPL.AddrUnitType, @AddrUnit = PPL.AddrUnit, @AddrCity = PPL.AddrCity, @AddrState = PPL.AddrProvince,
@AddrZip = PPL.AddrPostal, @AddrCountry = PPL.AddrCountry
FROM People PPL WHERE PPL.PeopleRSN = @PeopleRSN

/*
SELECT @Address1 = O.CuOStreet1, @Address2 = O.CuOStreet2, @City = O.CuOCity, 
@State = O.CuOState, @ZIP = O.CuOPostal, @CountryCode = O.CuOCountyCode, 
@Owner1LastName = O.Description, @Owner1FirstName = O.CuO1FirstName, 
@Owner2LastName = O.CuO2LastName, @Owner2FirstName = O.CuO2FirstName, 
@Owner3LastName = O.CuO3LastName, @Owner3FirstName = O.CuO3FirstName
AssessPro.dbo.TableOwnership O
INNER JOIN AssessPro.dbo.DataProperty P ON O.Code = P.OwnerLookup
WHERE P.ParcelID = @ParcelID
AND P.CardNumber = 1
*/

UPDATE FolderInfo
SET InfoValue = @AddrPrefix,
InfoValueUpper = @AddrPrefix
WHERE infocode = 4100
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrHouse,
InfoValueUpper = @AddrHouse
WHERE infocode = 4102
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrStreetPrefix,
InfoValueUpper = @AddrStreetPrefix
WHERE infocode = 4104
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrStreet,
InfoValueUpper = @AddrStreet
WHERE infocode = 4106
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrStreetType,
InfoValueUpper = @AddrStreetType
WHERE infocode = 4108
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrStreetDirection,
InfoValueUpper = @AddrStreetDirection
WHERE infocode = 4110
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrUnitType,
InfoValueUpper = @AddrUnitType
WHERE infocode = 4112
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrUnit,
InfoValueUpper = @AddrUnit
WHERE infocode = 4114
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrCity,
InfoValueUpper = @AddrCity
WHERE infocode = 4116
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrState,
InfoValueUpper = @AddrState
WHERE infocode = 4118
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrZip,
InfoValueUpper = @AddrZip
WHERE infocode = 4122
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @AddrCountry,
InfoValueUpper = @AddrCountry
WHERE infocode = 4120
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @NameLast,
InfoValueUpper = @NameLast
WHERE infocode = 4007
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @NameFirst,
InfoValueUpper = @NameFirst
WHERE infocode = 4008
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @OrganizationName,
InfoValueUpper = @OrganizationName
WHERE infocode = 4015
AND FolderRSN = @FolderRSN


GO
