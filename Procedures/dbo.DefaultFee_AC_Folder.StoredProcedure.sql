USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_AC_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_AC_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ParcelID VARCHAR(20)

SELECT @ParcelID = Property.PropertyRoll
FROM Property
INNER JOIN Folder ON Property.PropertyRSN = Folder.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN

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

SELECT @Address1 = O.CuOStreet1, @Address2 = O.CuOStreet2, @City = O.CuOCity, 
@State = O.CuOState, @ZIP = O.CuOPostal, @CountryCode = O.CuOCountyCode, 
@Owner1LastName = O.Description, @Owner1FirstName = O.CuO1FirstName, 
@Owner2LastName = O.CuO2LastName, @Owner2FirstName = O.CuO2FirstName, 
@Owner3LastName = O.CuO3LastName, @Owner3FirstName = O.CuO3FirstName
FROM AssessPro.dbo.TableOwnership O
INNER JOIN AssessPro.dbo.DataProperty P ON O.Code = P.OwnerLookup
WHERE P.ParcelID = @ParcelID
AND P.CardNumber = 1

UPDATE FolderInfo
SET InfoValue = @Address1,
InfoValueUpper = @Address1
WHERE infocode = 4000
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Address2,
InfoValueUpper = @Address2
WHERE infocode = 4001
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @City,
InfoValueUpper = @City
WHERE infocode = 4002
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @State,
InfoValueUpper = @State
WHERE infocode = 4003
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @ZIP,
InfoValueUpper = @ZIP
WHERE infocode = 4004
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @CountryCode,
InfoValueUpper = @CountryCode
WHERE infocode = 4005
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Owner1LastName,
InfoValueUpper = @Owner1LastName
WHERE infocode = 4007
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Owner1FirstName,
InfoValueUpper = @Owner1FirstName
WHERE infocode = 4008
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Owner2LastName,
InfoValueUpper = @Owner2LastName
WHERE infocode = 4009
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Owner2FirstName,
InfoValueUpper = @Owner2FirstName
WHERE infocode = 4010
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Owner3LastName,
InfoValueUpper = @Owner3LastName
WHERE infocode = 4011
AND FolderRSN = @FolderRSN

UPDATE FolderInfo
SET InfoValue = @Owner3FirstName,
InfoValueUpper = @Owner3FirstName
WHERE infocode = 4012
AND FolderRSN = @FolderRSN


GO
