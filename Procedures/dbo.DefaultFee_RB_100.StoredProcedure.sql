USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_100]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_100]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DELETE
FROM Rental_RegistrationsSingle

DECLARE @OwnerID VarChar(20)

SELECT @OwnerID = Folder.ReferenceFile
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

DECLARE @PropertyID int
DECLARE @RBCounter int

DECLARE OwnerId_Cur Cursor For
SELECT FolderPeople.PeopleRSN, Folder.PropertyRSN
FROM Folder, FolderPeople

WHERE FolderPeople.FolderRSN = Folder.FolderRSN
AND Folder.FolderType = 'RB'
AND Folder.ReferenceFile = @OwnerID
AND FolderPeople.PeopleCode = 126

Group By FolderPeople.PeopleRSN, Folder.PropertyRSN

OPEN OwnerID_Cur
FETCH OwnerID_Cur INTO
@OwnerID, @PropertyID

SET @RBCounter = 1

WHILE @@Fetch_Status = 0

BEGIN

Insert INTO
Rental_RegistrationsSingle
(RBNo,PeopleRSN, Place,PeopleDesc,PeopleCode,Phone,PhoneDesc,Email, 
OwnerID,PropertyID,PropHouse,PropStreet,PropStreetType,PropUnit, FName,LName,
OrgName, Addr1, Addr2, Addr3, TotalResUnits, RentalUnits)


SELECT @RBCounter, People.PeopleRSN,'1' Place, ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress, @OwnerID 'OwnerId',Folder.PropertyRSN, Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3, 
dbo.f_info_numeric_property(Folder.PropertyRSN, 15) 'ResUnit', dbo.f_info_numeric_property(Folder.PropertyRSN, 20) 'RentalUnits' 

FROM Folder, FolderPeople, People, ValidPeople,Property

WHERE  FolderPeople.PeopleRSN = People.PeopleRSN
AND FolderPeople.FolderRSN = Folder.FolderRSN
AND Folder.PropertyRSN = Property.PropertyRSN
AND Folder.FolderType = 'RR'
AND ValidPeople.PeopleCode = FolderPeople.PeopleCode
AND FolderPeople.PeopleCode = 125
AND Folder.PropertyRSN = @PropertyID

Group By People.PeopleRSN,ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress,Folder.PropertyRSN, Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3

UNION
SELECT @RBCounter,People.PeopleRSN, '2' Place, ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress, @OwnerID,Folder.PropertyRSN, Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3,dbo.f_info_numeric_property(Folder.PropertyRSN, 15) 'ResUnit', dbo.f_info_numeric_property(Folder.PropertyRSN, 20) 'RentalUnits' 


FROM Folder, FolderPeople, People, ValidPeople, Property

WHERE  FolderPeople.PeopleRSN = People.PeopleRSN
AND FolderPeople.FolderRSN = Folder.FolderRSN
AND Folder.PropertyRSN = Property.PropertyRSN
AND Folder.FolderType = 'RR'
AND ValidPeople.PeopleCode = FolderPeople.PeopleCode
AND FolderPeople.PeopleCode = 75
AND Folder.PropertyRSN = @PropertyID

Group By People.PeopleRSN,ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress,Folder.PropertyRSN, Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3

UNION
SELECT @RBCounter,People.PeopleRSN, '3' Place, ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress,@OwnerID,Folder.PropertyRSN,  Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3, 
dbo.f_info_numeric_property(Folder.PropertyRSN, 15) 'ResUnit', dbo.f_info_numeric_property(Folder.PropertyRSN, 20) 'RentalUnits' 

FROM Folder, FolderPeople, People, ValidPeople, Property

WHERE  FolderPeople.PeopleRSN = People.PeopleRSN
AND FolderPeople.FolderRSN = Folder.FolderRSN
AND Folder.PropertyRSN = Property.PropertyRSN
AND Folder.FolderType = 'RR'
AND ValidPeople.PeopleCode= FolderPeople.PeopleCode
AND FolderPeople.PeopleCode = 85
AND Folder.PropertyRSN = @PropertyID

Group By People.PeopleRSN,ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress,Folder.PropertyRSN, Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3

UNION
SELECT @RBCounter, People.PeopleRSN,'4' Place,ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress, @OwnerID,Folder.PropertyRSN,  Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3,
dbo.f_info_numeric_property(Folder.PropertyRSN, 15) 'ResUnit', dbo.f_info_numeric_property(Folder.PropertyRSN, 20) 'RentalUnits' 

FROM Folder, FolderPeople, People, ValidPeople, Property

WHERE  FolderPeople.PeopleRSN = People.PeopleRSN
AND FolderPeople.FolderRSN = Folder.FolderRSN
AND Folder.PropertyRSN = Property.PropertyRSN
AND Folder.FolderType = 'RR'
AND ValidPeople.PeopleCode = FolderPeople.PeopleCode
AND FolderPeople.PeopleCode = 80
AND Folder.PropertyRSN = @PropertyID

Group By People.PeopleRSN,ValidPeople.PeopleDesc, FolderPeople.PeopleCode, Phone1, Phone1Desc, 
People.EmailAddress,Folder.PropertyRSN, Property.PropHouse, Property.PropStreet, Property.PropStreetType,Property.PropUnit,
NameFirst, NameLast, OrganizationName, AddressLine1, AddressLine2, AddressLine3

Order by  Ownerid, Folder.PropertyRSN, Place

FETCH OwnerID_Cur INTO
@OwnerID, @PropertyID

SET @RBCounter = @RBCounter + 1

END
CLOSE OwnerID_Cur
DEALLOCATE OwnerID_Cur

GO
