USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningNoticeOfViolation]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_ZoningNoticeOfViolation](@FolderRSN INT)
RETURNS @BVT TABLE (FolderRSN INT PRIMARY KEY, PropertyAddress VARCHAR(100), ViolationDescription TEXT, TodayDate DATE,
					ExpiryDate VARCHAR(50), MapLotNo VARCHAR(15), UserName VARCHAR(40), UserTitle VARCHAR(50),
					UserPhone VARCHAR(20), NOVDecisionDate VARCHAR(50), ComplaintType VARCHAR(50), RemedyText1 TEXT,
					RemedyText2 TEXT, OwnerNameList TEXT,
					Owner1Name VARCHAR(50), Owner1Addr1 VARCHAR(50), Owner1Addr2 VARCHAR(50), Owner1Addr3 VARCHAR(50),
					Owner2Name VARCHAR(50), Owner2Addr1 VARCHAR(50), Owner2Addr2 VARCHAR(50), Owner2Addr3 VARCHAR(50),
					Owner3Name VARCHAR(50), Owner3Addr1 VARCHAR(50), Owner3Addr2 VARCHAR(50), Owner3Addr3 VARCHAR(50),
					Owner4Name VARCHAR(50), Owner4Addr1 VARCHAR(50), Owner4Addr2 VARCHAR(50), Owner4Addr3 VARCHAR(50),
					Owner5Name VARCHAR(50), Owner5Addr1 VARCHAR(50), Owner5Addr2 VARCHAR(50), Owner5Addr3 VARCHAR(50),
					Owner6Name VARCHAR(50), Owner6Addr1 VARCHAR(50), Owner6Addr2 VARCHAR(50), Owner6Addr3 VARCHAR(50)
)
AS BEGIN

INSERT INTO @BVT
(FolderRSN, PropertyAddress, ViolationDescription, TodayDate, ExpiryDate, MapLotNo, UserName, UserTitle, UserPhone, 
	NOVDecisionDate, ComplaintType, RemedyText1, RemedyText2, OwnerNameList) 

SELECT TOP 1 Folder.FolderRSN AS FolderRSN, Folder.FolderName AS PropertyAddress, 
	CAST(dbo.udf_RemoveSpecialChars(Folder.FolderDescription) AS TEXT) AS ViolationDescription, 
	CONVERT(CHAR(11), getdate()) AS TodayDate,
	dbo.udf_GetFolderDateLong(Folder.ExpiryDate, Folder.FolderRSN) AS ExpiryDate,
	Property.PropertyRoll AS MapLotNo, ValidUser.UserName, ValidUser.UserTitle,	ValidUser.UserPhone, 
	dbo.f_info_date_long(Folder.FolderRSN, 20059) AS NOVDecisionDate,
	dbo.f_info_alpha(Folder.FolderRSN, 20048) AS ComplaintType,
	CAST(dbo.udf_ZNShowCauseText1(Folder.FolderRSN) AS Text)  AS RemedyText1, 
	CAST(dbo.udf_ZNShowCauseText2(Folder.FolderRSN) AS Text)  AS RemedyText2,
	UPPER(dbo.udf_GetOwnerNameList(Folder.PropertyRSN)) AS OwnerList
FROM Folder, ValidUser, Property
WHERE  ValidUser.UserID = 'jfrancis'
	AND Folder.PropertyRSN = Property.PropertyRSN
	AND Folder.FolderRSN = @FolderRSN

-- Get owner names and addresses for all owners

	DECLARE @Owner1Name varchar(255)
	DECLARE @Owner1Addr1 varchar(255)
	DECLARE @Owner1Addr2 varchar(255)
	DECLARE @Owner1Addr3 varchar(255)

	DECLARE @Owner2Name varchar(255)
	DECLARE @Owner2Addr1 varchar(255)
	DECLARE @Owner2Addr2 varchar(255)
	DECLARE @Owner2Addr3 varchar(255)

	DECLARE @Owner3Name varchar(255)
	DECLARE @Owner3Addr1 varchar(255)
	DECLARE @Owner3Addr2 varchar(255)
	DECLARE @Owner3Addr3 varchar(255)

	DECLARE @Owner4Name varchar(255)
	DECLARE @Owner4Addr1 varchar(255)
	DECLARE @Owner4Addr2 varchar(255)
	DECLARE @Owner4Addr3 varchar(255)

	DECLARE @Owner5Name varchar(255)
	DECLARE @Owner5Addr1 varchar(255)
	DECLARE @Owner5Addr2 varchar(255)
	DECLARE @Owner5Addr3 varchar(255)

	DECLARE @Owner6Name varchar(255)
	DECLARE @Owner6Addr1 varchar(255)
	DECLARE @Owner6Addr2 varchar(255)
	DECLARE @Owner6Addr3 varchar(255)

	DECLARE @Count INT
	DECLARE @PeopleRSN INT
	DECLARE @PropertyRSN INT

	SET @Count = 1
	SELECT @PropertyRSN = PropertyRSN FROM Folder WHERE Folder.FolderRSN = @FolderRSN

	DECLARE CurGeneral CURSOR FOR
	SELECT PeopleRSN FROM PropertyPeople 
	WHERE PropertyPeople.PropertyRSN = @PropertyRSN 
	AND PropertyPeople.PeopleCode = 2 
	ORDER BY PeopleRSN

	OPEN curGeneral
	FETCH NEXT FROM curGeneral INTO @PeopleRSN
	WHILE @@FETCH_STATUS = 0
		BEGIN

		IF @Count = 1 BEGIN
			--UPDATE @BVT
			SET @Owner1Name = dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)
			SET @Owner1Addr1 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 1)
			SET @Owner1Addr2 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 2)
			SET @Owner1Addr3 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 3)
		END

		IF @Count = 2 BEGIN
			--UPDATE @BVT
			SET @Owner2Name = dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)
			SET @Owner2Addr1 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 1)
			SET @Owner2Addr2 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 2)
			SET @Owner2Addr3 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 3)
		END

		IF @Count = 3 BEGIN
			--UPDATE @BVT
			SET @Owner3Name = dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)
			SET @Owner3Addr1 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 1)
			SET @Owner3Addr2 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 2)
			SET @Owner3Addr3 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 3)
		END

		IF @Count = 4 BEGIN
			--UPDATE @BVT
			SET @Owner4Name = dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)
			SET @Owner4Addr1 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 1)
			SET @Owner4Addr2 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 2)
			SET @Owner4Addr3 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 3)
		END

		IF @Count = 5 BEGIN
			--UPDATE @BVT
			SET @Owner5Name = dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)
			SET @Owner5Addr1 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 1)
			SET @Owner5Addr2 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 2)
			SET @Owner5Addr3 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 3)
		END

		IF @Count = 6 BEGIN
			--UPDATE @BVT
			SET @Owner1Name = dbo.TK_PEOPLE_NAMEORG(@PeopleRSN)
			SET @Owner6Addr1 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 1)
			SET @Owner6Addr2 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 2)
			SET @Owner6Addr3 = dbo.TK_PEOPLE_FREEFORMADDRESSLINE(@PeopleRSN, 3)
		END

		SET @Count = @Count + 1
		FETCH NEXT FROM curGeneral INTO @PeopleRSN

	END
	CLOSE curGeneral
	DEALLOCATE curGeneral

	UPDATE @BVT
		SET Owner1Name = @Owner1Name, Owner1Addr1 = @Owner1Addr1, Owner1Addr2 = @Owner1Addr2, Owner1Addr3 = @Owner1Addr3,
		    Owner2Name = @Owner2Name, Owner2Addr1 = @Owner2Addr1, Owner2Addr2 = @Owner2Addr2, Owner2Addr3 = @Owner2Addr3,
		    Owner3Name = @Owner3Name, Owner3Addr1 = @Owner3Addr1, Owner3Addr2 = @Owner3Addr2, Owner3Addr3 = @Owner3Addr3,
		    Owner4Name = @Owner4Name, Owner4Addr1 = @Owner4Addr1, Owner4Addr2 = @Owner4Addr2, Owner4Addr3 = @Owner4Addr3,
		    Owner5Name = @Owner5Name, Owner5Addr1 = @Owner5Addr1, Owner5Addr2 = @Owner5Addr2, Owner5Addr3 = @Owner5Addr3,
		    Owner6Name = @Owner6Name, Owner6Addr1 = @Owner6Addr1, Owner6Addr2 = @Owner6Addr2, Owner6Addr3 = @Owner6Addr3
		WHERE FolderRSN = @FolderRSN

RETURN;
END

GO
