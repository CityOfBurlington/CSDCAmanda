USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_SendAddressToAssessPro]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_SendAddressToAssessPro]
(@ParcelID VARCHAR(20), @Action INT)
as

/* Call this procedue passing the Parcel ID for the property whose data will change and the Action you wish to perform:
	Action = 1	Change address data only
	Action = 2	Change name data only
	Action = 3	Change both name and address data
*/

DECLARE @PropertyRSN int
DECLARE @AM_ParcelID varchar(30)
DECLARE @AM_APAccountNumber int
DECLARE @AM_Owner1RSN int
DECLARE @AM_Owner2RSN int
DECLARE @AM_Owner3RSN int
DECLARE @AM_APOwnerLookup1 int
DECLARE @AM_APOwnerIndex1 int
DECLARE @AM_APOwnerLookup2 int
DECLARE @AM_APOwnerIndex2 int
DECLARE @AM_APOwnerLookup3 int
DECLARE @AM_APOwnerIndex3 int
DECLARE @AM_Description varchar(30)
DECLARE @AM_CuO1FirstName varchar(25)
DECLARE @AM_CuO2LastName varchar(30)
DECLARE @AM_CuO2FirstName varchar(25)
DECLARE @AM_CuO3LastName varchar(30)
DECLARE @AM_CuO3FirstName varchar(25)
DECLARE @AM_CuOStreet1 varchar(40)
DECLARE @AM_CuOStreet2 varchar(40)
DECLARE @AM_CuOStreet3 varchar(40)
DECLARE @AM_CuOCity varchar(25)
DECLARE @AM_CuOState varchar(10)
DECLARE @AM_CuOPostal varchar(16)
DECLARE @AP_APAccountNumber int
DECLARE @AP_Owner1RSN int
DECLARE @AP_Owner2RSN int
DECLARE @AP_Owner3RSN int
DECLARE @AP_APOwnerLookup int
DECLARE @AP_APOwnerIndex1 int
DECLARE @AP_APOwnerIndex2 int
DECLARE @AP_APOwnerIndex3 int
DECLARE @AP_Description varchar(30)
DECLARE @AP_CuO1FirstName varchar(25)
DECLARE @AP_CuO2LastName varchar(30)
DECLARE @AP_CuO2FirstName varchar(25)
DECLARE @AP_CuO3LastName varchar(30)
DECLARE @AP_CuO3FirstName varchar(25)
DECLARE @AP_CuOStreet1 varchar(40)
DECLARE @AP_CuOStreet2 varchar(40)
DECLARE @AP_CuOCity varchar(25)
DECLARE @AP_CuOState varchar(10)
DECLARE @AP_CuOPostal varchar(16)
DECLARE @intCOMReturnValue  INT

SELECT @PropertyRSN = A.PropertyRSN, 
       @AM_APAccountNumber = A.AProAccount, 
       @AM_Owner1RSN = A.Owner1,
       @AM_Owner2RSN = A.Owner2, 
       @AM_Owner3RSN = A.Owner3, 
       @AM_APOwnerLookup1 = dbo.f_info_numeric_people(Owner1,10), 
       @AM_APOwnerIndex1 = dbo.f_info_numeric_people(Owner1,15), 
       @AM_APOwnerLookup2 = dbo.f_info_numeric_people(Owner2,10),
       @AM_APOwnerIndex2 = dbo.f_info_numeric_people(Owner2,15), 
       @AM_APOwnerLookup3 = dbo.f_info_numeric_people(Owner3,10),
       @AM_APOwnerIndex3 = dbo.f_info_numeric_people(Owner3,15),
       @AM_Description = ISNULL((SELECT NameLast FROM People WHERE PeopleRSN = Owner1),dbo.udf_GetPeopleOrOrganizationName(Owner1)),
       @AM_CuO1FirstName = dbo.udf_GetPeopleFirstName(Owner1),
       @AM_CuO2LastName = ISNULL((SELECT NameLast FROM People WHERE PeopleRSN = Owner2),dbo.udf_GetPeopleOrOrganizationName(Owner2)),
       @AM_CuO2FirstName = dbo.udf_GetPeopleFirstName(Owner2),
       @AM_CuO3LastName = ISNULL((SELECT NameLast FROM People WHERE PeopleRSN = Owner3),dbo.udf_GetPeopleOrOrganizationName(Owner3)),
       @AM_CuO3FirstName = dbo.udf_GetPeopleFirstName(Owner3),
       @AM_CuOStreet1 = dbo.udf_GetPeopleAddressLine1(Owner1), 
       @AM_CuOStreet2 = dbo.udf_GetPeopleAddressLine2(Owner1), 
       @AM_CuOStreet3 = dbo.udf_GetPeopleAddressLine3(Owner1), 
       @AM_CuOCity = dbo.udf_GetPeopleAddressCity(Owner1), 
       @AM_CuOState = dbo.udf_GetPeopleAddressState(Owner1),
       @AM_CuOPostal = dbo.udf_GetPeopleAddressZip(Owner1)
	FROM uvw_CompareAmandaAProOwners A
    WHERE ParcelID = @ParcelID

	SELECT @AP_APAccountNumber = ISNULL(DP.AccountNumber,0),
	       @AP_APOwnerLookup = ISNULL(DP.OwnerLookUp,0)
	FROM AssessPro.dbo.DataProperty DP
	WHERE DP.ParcelID = @ParcelID

	IF @Action = 1 OR @Action = 3 /* Update address data */
	BEGIN
		UPDATE cobdb.AssessPro.dbo.TableOwnership
		SET CuOStreet1 = @AM_CuOStreet1, CuOStreet2 = @AM_CuOStreet2, CuOCity = @AM_CuOCity, CuOState = @AM_CuOState, CuOPostal = @AM_CuOPostal
		WHERE Code = @AP_APOwnerLookup
	END
	
	IF @Action = 1 OR @Action = 3
	BEGIN
		UPDATE cobdb.AssessPro.dbo.TableOwnership
		SET Description = @AM_Description, 
		Cuo1FirstName = @AM_CuO1FirstName, CuO2LastName = @AM_CuO2LastName, CuO2FirstName = @AM_CuO2FirstName, 
		CuO3LastName = @AM_CuO3LastName, CuO3FirstName = @AM_CuO3FirstName
		WHERE Code = @AP_APOwnerLookup
	END
	
	EXEC @intCOMReturnValue = xspInsertOwnerIntoNemrc @ParcelID
	IF @intCOMReturnValue = 1 
	BEGIN
	    RAISERROR('Failed to update NEMRC tax database(1)', 16, -1)
	END

GO
