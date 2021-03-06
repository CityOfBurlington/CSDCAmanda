USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Complete_PeopleUpdate]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Complete_PeopleUpdate]
AS

/* Save a copy of the People table (just in case) */
--DELETE FROM tblPeopleSave
--INSERT INTO tblPeopleSave SELECT * FROM People

/* Turn off the People table triggers */
ALTER TABLE People DISABLE TRIGGER People_Upd
ALTER TABLE People DISABLE TRIGGER People_Upd_Log
ALTER TABLE People DISABLE TRIGGER People_Upd_StampDate

/* Now save all the tblPeopleUpdate data into the People table */
UPDATE [AMANDA_Production].[dbo].[People]
   SET [NameTitle] = T.NameTitle
      ,[NameFirst] = T.NameFirst
      ,[NameLast] = T.NameLast
      ,[OrganizationName] = T.OrganizationName
      ,[AddrHouse] = T.AddrHouse
      ,[AddrStreet] = T.AddrStreet
      ,[AddrStreetType] = T.AddrStreetType
      ,[AddrStreetDirection] = T.AddrStreetDirection
      ,[AddrUnitType] = T.AddrUnitType
      ,[AddrUnit] = T.AddrUnit
      ,[AddrCity] = T.AddrCity
      ,[AddrProvince] = T.AddrProvince
      ,[AddrCountry] = T.AddrCountry
      ,[AddrPostal] = T.AddrPostal
      ,[Phone1] = T.Phone1
      ,[Phone1Desc] = T.Phone1Desc
      ,[Phone2] = T.Phone2
      ,[Phone2Desc] = T.Phone2Desc
      ,[LicenceNumber] = T.LicenceNumber
      ,[PeopleCode] = T.PeopleCode
      ,[ContactSex] = T.ContactSex
      ,[BirthDate] = T.BirthDate
      ,[FamilyRSN] = T.FamilyRSN
      ,[Comments] = T.Comments
      ,[StampDate] = T.StampDate
      ,[StampUser] = T.StampUser
      ,[AddrPrefix] = T.AddrPrefix
      ,[AddressLine1] = T.AddressLine1
      ,[AddressLine2] = T.AddressLine2
      ,[AddressLine3] = T.AddressLine3
      ,[AddressLine4] = T.AddressLine4
      ,[AddressLine5] = T.AddressLine5
      ,[AddressLine6] = T.AddressLine6
      ,[AddrHouseNumeric] = T.AddrHouseNumeric
      ,[Phone3] = T.Phone3
      ,[Phone3Desc] = T.Phone3Desc
      ,[EmailAddress] = T.EmailAddress
      ,[NameFirstUpper] = T.NameFirstUpper
      ,[NameLastUpper] = T.NameLastUpper
      ,[OrgNameUpper] = T.OrgNameUpper
      ,[AddrStreetUpper] = T.AddrStreetUpper
      ,[ParentRSN] = T.ParentRSN
      ,[AddrStreetPrefix] = T.AddrStreetPrefix
      ,[Nearby] = T.Nearby
      ,[Community] = T.Community
      ,[Phone4] = T.Phone4
      ,[Phone4Desc] = T.Phone4Desc
      ,[StatusType] = T.StatusType
      ,[HealthCard] = T.HealthCard
      ,[StatusCode] = T.StatusCode
      ,[SecurityCode] = T.SecurityCode
      ,[ReferenceFile] = T.ReferenceFile
      ,[InternetPassword] = T.InternetPassword
      ,[InternetAccess] = T.InternetAccess
      ,[InternetQuestion] = T.InternetQuestion
      ,[InternetAnswer] = T.InternetAnswer
      ,[CreditCardProcessingFlag] = T.CreditCardProcessingFlag
      ,[InternetRegistrationDate] = T.InternetRegistrationDate
 FROM People P
Join tblPeopleUpdate T ON P.PeopleRSN = T.PeopleRSN
--WHERE P.StampDate < '11/1/2011' OR P.StampDate IS NULL

/* Turn off the People table triggers */
ALTER TABLE People ENABLE TRIGGER People_Upd
ALTER TABLE People ENABLE TRIGGER People_Upd_Log
ALTER TABLE People ENABLE TRIGGER People_Upd_StampDate



GO
