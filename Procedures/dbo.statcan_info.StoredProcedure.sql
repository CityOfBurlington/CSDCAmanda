USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[statcan_info]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure StatCan_Info modifed to store area in float data type */

CREATE PROCEDURE [dbo].[statcan_info] @FolderRSN INT, @Flag INT
AS

-- 5.4.31: ESS

BEGIN
DECLARE @Valuation int
DECLARE @theArea float--ESS:Pankaj Issue ID:-23115
DECLARE @Units int
DECLARE @UnitsCreated int
DECLARE @UnitsLost int

DECLARE @OrgName varchar(50)
DECLARE @NameFirst varchar(25)
DECLARE @NameLast varchar(25)

DECLARE @BuilderName varchar(105)
DECLARE @BuilderAddr varchar(80)
DECLARE @BuilderAddr1 varchar(80)
DECLARE @OwnerName varchar(105)
DECLARE @OwnerAddr varchar(80)
DECLARE @OwnerAddr1 varchar(80)

DECLARE @BuilderCode int
DECLARE @OwnerCode int
DECLARE @ValueCode int
DECLARE @AreaCode int
DECLARE @UnitsCode int
DECLARE @UnitsCreatedCode int
DECLARE @UnitsLostCode int
DECLARE @StatOverCode int
DECLARE @StatOver varchar(20)

DECLARE @the_name varchar(60)
DECLARE @whole_addr varchar(80)
DECLARE @whole_addr1 varchar(80)

SELECT @Valuation = 0
SELECT @theArea = 0
SELECT @Units = 0
SELECT @UnitsCreated = 0
SELECT @UnitsLost = 0
SELECT @StatOver = ''
SELECT @whole_addr = ''
SELECT @the_name  = ''

SELECT 	@BuilderCode = BuilderCode,
	@OwnerCode = OwnerCode,
	@ValueCode = ConstructionValueCode,
	@AreaCode = BuildingAreaCode,
	@UnitsCode = DwellingUnitsCode,
	@UnitsCreatedCode = DwellingUnitsCreatedCode,
	@UnitsLostCode = DwellingUnitsLostCode,
	@StatOverCode = StatOverCode
FROM ValidStatCan

IF @Flag = 1
BEGIN
	DECLARE @location varchar(80)
	DECLARE @location1 varchar(80)
	SELECT  @location = IsNull(Property.PropHouse + ' ', '' ) +
			IsNull(Property.PropStreet + ' ', '' ) +
			IsNull(Property.PropStreetType + ' ', '' ) +
			IsNull(Property.PropUnitType + ' ', '') +
			IsNull(Property.PropUnit  + ' ', '') ,
		@location1 =
			IsNull(Property.PropCity + ' ', '' ) +
			IsNull(Property.PropProvince  + ' ', '') +
			IsNull(Property.PropPostal + ' ', '')
	FROM Folder, Property
	WHERE ( Folder.FolderRSN = @FolderRSN ) AND
		( Property.PropertyRSN = Folder.PropertyRSN )

	DECLARE @i int
	DECLARE @owner_or_builder int
	SELECT @i = 1
	WHILE @i < 3
	BEGIN
		IF @i = 1
			SELECT @owner_or_builder = @OwnerCode
		ELSE
			SELECT @owner_or_builder = @BuilderCode

		SELECT @NameFirst = People.NameFirst,
		       @NameLast = People.NameLast,
			@the_name = People.OrganizationName,
			@whole_addr = IsNull(People.AddrHouse + ' ', '' ) +
				IsNull(People.AddrStreet + ' ', '' ) +
				IsNull(People.AddrStreetType + ' ', '' ) +
				IsNull(People.AddrUnitType + ' ', '') +
				IsNull(People.AddrUnit  + ' ', ''),
			@whole_addr1 =
				IsNull(People.AddrCity + ' ', '' ) +
				IsNull(People.AddrProvince  + ' ', '') +
				IsNull(People.AddrPostal + ' ', '')
		FROM FolderPeople, People
		WHERE ( FolderPeople.FolderRSN = @FolderRSN ) AND
			( People.PeopleRSN = FolderPeople.PeopleRSN ) AND
			( FolderPeople.PeopleCode = @owner_or_builder )

		IF @the_name > ''
		BEGIN
			IF @NameFirst > '' AND @NameLast > ''
				SELECT @the_name = @the_name + ' (' + @NameFirst + ' ' + @NameLast + ')'
		END
		ELSE
		BEGIN
			IF @NameFirst > '' AND @NameLast > ''
				SELECT @the_name = @NameFirst + ' ' + @NameLast
			ELSE
				SELECT @the_name = ''
		END

		IF (@i = 1)
		BEGIN
			SELECT @OwnerAddr = @whole_addr
			SELECT @OwnerAddr1 = @whole_addr1
			SELECT @OwnerName = @the_name
		END
		ELSE
		BEGIN
			SELECT @BuilderAddr = @whole_addr
			SELECT @BuilderAddr1 = @whole_addr1
			SELECT @BuilderName = @the_name
		END

		SELECT @i = @i + 1
	END
END

SELECT @Valuation = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN AND
	FolderInfo.InfoCode = @ValueCode

SELECT @theArea = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN AND
	FolderInfo.InfoCode = @AreaCode

SELECT @UnitsCreated = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN AND
	FolderInfo.InfoCode = @UnitsCreatedCode
SELECT @Units = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN AND
	FolderInfo.InfoCode = @UnitsCode

SELECT @UnitsLost = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN AND
	FolderInfo.InfoCode = @UnitsLostCode

SELECT @StatOver = IsNull(FolderInfo.InfoValue, '')
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN AND
	FolderInfo.InfoCode = @StatOverCode

IF @Flag = 1
	SELECT @Valuation, @theArea, @Units, @UnitsCreated,
		@UnitsLost, @StatOver, @OwnerName, @OwnerAddr, @OwnerAddr1,
		@BuilderName, @BuilderAddr, @BuilderAddr1, @location, @location1
ELSE
	SELECT @Valuation, @theArea, @Units, @UnitsCreated,
		@UnitsLost, @StatOver
END

GO
