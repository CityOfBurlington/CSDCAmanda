USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Null_PeopleUpdate]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Null_PeopleUpdate]
AS
BEGIN

UPDATE tblPeopleUpdate SET NameTitle = NULL WHERE NameTitle = ''
UPDATE tblPeopleUpdate SET NameFirst = NULL WHERE NameFirst = ''
UPDATE tblPeopleUpdate SET NameLast = NULL WHERE NameLast = ''
UPDATE tblPeopleUpdate SET OrganizationName = NULL WHERE OrganizationName = ''
UPDATE tblPeopleUpdate SET AddrHouse = NULL WHERE AddrHouse = ''
UPDATE tblPeopleUpdate SET AddrStreet = NULL WHERE AddrStreet = ''
UPDATE tblPeopleUpdate SET AddrStreetType = NULL WHERE AddrStreetType = ''
UPDATE tblPeopleUpdate SET AddrStreetDirection = NULL WHERE AddrStreetDirection = ''
UPDATE tblPeopleUpdate SET AddrUnitType = NULL WHERE AddrUnitType = ''
UPDATE tblPeopleUpdate SET AddrUnit = NULL WHERE AddrUnit = ''
UPDATE tblPeopleUpdate SET AddrCity = NULL WHERE AddrCity = ''
UPDATE tblPeopleUpdate SET AddrProvince = NULL WHERE AddrProvince = ''
UPDATE tblPeopleUpdate SET AddrCountry = NULL WHERE AddrCountry = ''
UPDATE tblPeopleUpdate SET AddrPostal = NULL WHERE AddrPostal = ''
UPDATE tblPeopleUpdate SET Phone1 = NULL WHERE Phone1 = ''
UPDATE tblPeopleUpdate SET Phone1Desc = NULL WHERE Phone1Desc = ''
UPDATE tblPeopleUpdate SET Phone2 = NULL WHERE Phone2 = ''
UPDATE tblPeopleUpdate SET Phone2Desc = NULL WHERE Phone2Desc = ''
UPDATE tblPeopleUpdate SET LicenceNumber = NULL WHERE LicenceNumber = ''
UPDATE tblPeopleUpdate SET ContactSex = NULL WHERE ContactSex = ''
UPDATE tblPeopleUpdate SET Birthdate = DateAdd(year, -100, Birthdate) WHERE Birthdate > '9/1/2011'
UPDATE tblPeopleUpdate SET BirthDate = NULL WHERE BirthDate <= '12/31/1899'
UPDATE tblPeopleUpdate SET Comments = NULL WHERE Comments = ''
UPDATE tblPeopleUpdate SET StampDate = getdate()
UPDATE tblPeopleUpdate SET StampUser = 'sa'
UPDATE tblPeopleUpdate SET AddrPrefix = NULL WHERE AddrPrefix = ''
UPDATE tblPeopleUpdate SET AddressLine1 = NULL WHERE AddressLine1 = ''
UPDATE tblPeopleUpdate SET AddressLine2 = NULL WHERE AddressLine2 = ''
UPDATE tblPeopleUpdate SET AddressLine3 = NULL WHERE AddressLine3 = ''
UPDATE tblPeopleUpdate SET AddressLine4 = NULL WHERE AddressLine4 = ''
UPDATE tblPeopleUpdate SET AddressLine5 = NULL WHERE AddressLine5 = ''
UPDATE tblPeopleUpdate SET AddressLine6 = NULL WHERE AddressLine6 = ''
UPDATE tblPeopleUpdate SET Phone3 = NULL WHERE Phone3 = ''
UPDATE tblPeopleUpdate SET Phone3Desc = NULL WHERE Phone3Desc = ''
UPDATE tblPeopleUpdate SET EmailAddress = NULL WHERE EmailAddress = ''
UPDATE tblPeopleUpdate SET NameFirstUpper = NULL WHERE NameFirstUpper = ''
UPDATE tblPeopleUpdate SET NameLastUpper = NULL WHERE NameLastUpper = ''
UPDATE tblPeopleUpdate SET OrgNameUpper = NULL WHERE OrgNameUpper = ''
UPDATE tblPeopleUpdate SET AddrStreetUpper = NULL WHERE AddrStreetUpper = ''
UPDATE tblPeopleUpdate SET AddrStreetPrefix = NULL WHERE AddrStreetPrefix = ''
UPDATE tblPeopleUpdate SET Nearby = NULL WHERE Nearby = ''
UPDATE tblPeopleUpdate SET Community = NULL WHERE Community = ''
UPDATE tblPeopleUpdate SET Phone4 = NULL WHERE Phone4 = ''
UPDATE tblPeopleUpdate SET Phone4Desc = NULL WHERE Phone4Desc = ''
UPDATE tblPeopleUpdate SET StatusType = NULL WHERE StatusType = ''
UPDATE tblPeopleUpdate SET HealthCard = NULL WHERE HealthCard = ''
UPDATE tblPeopleUpdate SET ReferenceFile = NULL WHERE ReferenceFile = ''
UPDATE tblPeopleUpdate SET InternetPassword = NULL WHERE InternetPassword = ''
UPDATE tblPeopleUpdate SET InternetAccess = NULL WHERE InternetAccess = ''
UPDATE tblPeopleUpdate SET InternetQuestion = 'Reviewed'
UPDATE tblPeopleUpdate SET InternetAnswer = NULL WHERE InternetAnswer = ''
UPDATE tblPeopleUpdate SET CreditCardProcessingFlag = NULL WHERE CreditCardProcessingFlag = ''
UPDATE tblPeopleUpdate SET InternetRegistrationDate = NULL WHERE InternetRegistrationDate <= '12/31/1899'

END

GO
