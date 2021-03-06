USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_AC]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_AC]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ParcelID VARCHAR(20)
DECLARE @strSQL NVARCHAR(2000)
DECLARE @PropertyRSN INT


SELECT @ParcelID = Property.PropertyRoll, @PropertyRSN = Folder.PropertyRSN
FROM Property
INNER JOIN Folder ON Property.PropertyRSN = Folder.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN

DECLARE @OwnerCode INT

SELECT @OwnerCode = O.Code
FROM AssessPro.dbo.TableOwnership O
INNER JOIN AssessPro.dbo.DataProperty P ON O.Code = P.OwnerLookup
WHERE P.ParcelID = @ParcelID

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


SELECT @Address1 = dbo.f_info_alpha(Folder.FolderRSN, 4000),
@Address2  = dbo.f_info_alpha(Folder.FolderRSN, 4001),
@City  = dbo.f_info_alpha(Folder.FolderRSN, 4002),
@State  = dbo.f_info_alpha(Folder.FolderRSN, 4003),
@ZIP  = dbo.f_info_alpha(Folder.FolderRSN, 4004),
@CountryCode  = dbo.f_info_alpha(Folder.FolderRSN, 4005),
@Owner1LastName  = dbo.f_info_alpha(Folder.FolderRSN, 4007),
@Owner1FirstName  = dbo.f_info_alpha(Folder.FolderRSN, 4008),
@Owner2LastName  = dbo.f_info_alpha(Folder.FolderRSN, 4009),
@Owner2FirstName  = dbo.f_info_alpha(Folder.FolderRSN, 4010),
@Owner3LastName  = dbo.f_info_alpha(Folder.FolderRSN, 4011),
@Owner3FirstName = dbo.f_info_alpha(Folder.FolderRSN, 4012)
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN


UPDATE AssessPro.dbo.TableOwnership
SET 
CuOStreet1 = @Address1, 
CuOStreet2 = @Address2,
CuOCity = @City, 
CuOState = @State, 
CuOPostal = @ZIP, 
CuOCountyCode = @CountryCode, 
Description = @Owner1LastName, 
CuO1FirstName = @Owner1FirstName, 
CuO2LastName = @Owner2LastName, 
CuO2FirstName = @Owner2FirstName, 
CuO3LastName = @Owner3LastName, 
CuO3FirstName = @Owner3FirstName,
UpdtDate = GetDate(),
UpdtUser = @UserId
WHERE Code = @OwnerCode

UPDATE People
SET AddressLine1 = NULL,
AddressLine2 = NULL,
AddressLine3 = NULL,
AddressLine4 = NULL,
AddressLine5 = NULL
WHERE PeopleRSN IN(SELECT PeopleRSN 
FROM PropertyPeople 
WHERE PeopleCode = 2 
AND PropertyRSN = @PropertyRSN)

UPDATE People
SET AddressLine1 = @Address1,
AddressLine2 = @Address2,
AddressLine3 = ISNULL(@City + ', ', '') + ISNULL(@State + ' ', '') + @ZIP, 
AddressLine4 = NULL,
AddressLine5 = NULL
WHERE PeopleRSN IN(SELECT PeopleRSN 
FROM PropertyPeople 
WHERE PeopleCode = 2 
AND PropertyRSN = @PropertyRSN)

COMMIT TRANSACTION
BEGIN TRANSACTION


DECLARE @intCOMReturnValue  INT

EXEC @intCOMReturnValue = xspInsertOwnerIntoNemrc @ParcelID

IF @intCOMReturnValue = 1 
BEGIN
    RAISERROR('Failed to update NEMRC tax database(1)', 16, -1)

END

GO
