USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_LR_Update_Owners]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LR_Update_Owners](@FolderRSN INT) 
AS
BEGIN

	DECLARE @i INT
	DECLARE @Grantee INT
	DECLARE @Grantor INT

	SET @i = 0
	SET @Grantee = 95
	SET @Grantor = 90

	DECLARE @PeopleRSN		INT
	DECLARE @FirstName		VARCHAR(100)
	DECLARE @LastName		VARCHAR(100)
	DECLARE	@OrgName		VARCHAR(100)
	DECLARE @A_OwnerCode	INT
	DECLARE @AddressPrefix  VARCHAR(100)

	DECLARE @PropertyRSN	INT
	DECLARE @ParcelID		VARCHAR(20)
	DECLARE @Book			VARCHAR(10)
	DECLARE @Page			VARCHAR(10)
	DECLARE @DocumentType	VARCHAR(2)	
	DECLARE @DateRecorded	DATETIME	
	DECLARE @DateExecuted	DATETIME
	DECLARE @SalePrice		FLOAT
	DECLARE @CuOStreet1		VARCHAR(100)
	DECLARE @CuOCity		VARCHAR(100)
	DECLARE @CuOState		VARCHAR(100)
	DECLARE @CuOPostal		VARCHAR(100)
	DECLARE @GrantorName	VARCHAR(100)
	DECLARE @PDF			VARCHAR(500)
	DECLARE @intNumberOfGrantees INT

	DECLARE @CuO1LastName	VARCHAR(30)
	DECLARE @CuO1FirstName	VARCHAR(25)
	DECLARE @CuO2LastName	VARCHAR(30)
	DECLARE @CuO2FirstName	VARCHAR(25)
	DECLARE @CuO3LastName	VARCHAR(30)
	DECLARE @CuO3FirstName	VARCHAR(25)

	DECLARE @PropertyKey	INT
	DECLARE @BillFlag		CHAR(1)

	DECLARE @OwnerStat CHAR(1)
	DECLARE @AccountNumber INT
	DECLARE @NextSaleID	INT
	DECLARE @Notes VARCHAR(50)
	DECLARE @strSQL NVARCHAR(2000)

	SELECT @PropertyRSN = FolderProperty.PropertyRSN, @PDF = ISNULL(dbo.f_info_alpha(Folder.FolderRSN, 2030), ''), 
	@Notes = 'Updated from AMANDA on ' + dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY'), 
	@i = 0, @ParcelID = Property.PropertyRoll, @Book = dbo.f_info_numeric(Folder.FolderRSN, 2000),
	@Page = dbo.f_info_numeric(Folder.FolderRSN, 2001), @DateRecorded = dbo.f_info_date(Folder.FolderRSN, 2002),
	@DateExecuted = dbo.f_info_date(Folder.FolderRSN, 2003), @SalePrice = dbo.f_info_numeric(Folder.FolderRSN, 2006),
	@DocumentType = CASE 
	WHEN Folder.WorkCode = 1521 THEN 'MH'
	WHEN Folder.WorkCode = 1527 THEN 'QC'
	WHEN Folder.WorkCode = 1531 THEN 'TD' 
	WHEN Folder.WorkCode = 1532 THEN 'WD' 
	END
	FROM Folder
	INNER JOIN FolderProperty ON Folder.FolderRSN = FolderProperty.FolderRSN
	INNER JOIN Property ON FolderProperty.PropertyRSN = Property.PropertyRSN
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE Folder
	SET ReferenceFile = CAST(@Book AS VARCHAR(20)) + '-' + CAST(@Page AS VARCHAR(20))
	WHERE FolderRSN = @FolderRSN

	SELECT TOP 1 @CuOStreet1 = RTRIM(LTRIM(ISNULL(People.AddrHouse + ' ', '') + People.AddrStreet + ' ' + ISNULL(People.AddrStreetType, '') + ISNULL(' ' + People.AddrUnitType + ' ', '') + ISNULL(People.AddrUnit, ''))),
	@CuOCity = People.AddrCity, @CuOState = People.AddrProvince, @CuOPostal = People.AddrPostal, @AddressPrefix = People.AddrPrefix
	FROM FolderPeople
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	WHERE FolderPeople.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = @Grantee 

	SELECT @intNumberOfGrantees = SUM(1)
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	WHERE Folder.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = @Grantee

	SELECT @LastName = RTRIM(LTRIM(ISNULL(People.NameLast, ''))), 
		@FirstName = RTRIM(LTRIM(ISNULL(People.NameFirst, ''))), 
		@OrgName = RTRIM(LTRIM(ISNULL(People.OrganizationName, '')))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	WHERE Folder.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = @Grantor

	IF LEN(@OrgName) > 0
		SET @GrantorName = @OrgName
	ELSE
		SET @GrantorName = @LastName + ', ' + @FirstName

	/*Update Amanda*/
	DECLARE @strComment		VARCHAR(200)
	DECLARE @strToday		VARCHAR(30)

	SELECT @strComment = dbo.FormatDateTime(@DateExecuted, 'MM/DD/YYYY'), @strToday = dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY')
    SET @strComment = 'Ownership Transfer ' + @strComment+ ', Recorded ' + @strToday

 EXEC usp_UpdateFolderCondition @FolderRSN, @strComment
	/*
    UPDATE Property
    SET PropComment = @strComment
    WHERE PropertyRSN = @PropertyRSN
	*/
	DELETE FROM PropertyPeople
	WHERE PeopleCode = 200
	AND PropertyRSN = @PropertyRSN
	AND PeopleRSN IN(SELECT PeopleRSN 
	FROM FolderPeople 
	WHERE FolderRSN = @FolderRSN 
	AND PeopleCode IN(2/*Owner*/, @Grantor, @Grantee))
			
	--IF NOT EXISTS (SELECT PeopleRSN FROM PropertyPeople WHERE PropertyRSN = @PropertyRSN AND 

    UPDATE PropertyPeople
    SET PeopleCode = 200 /*PREVIOUS OWNER*/
    WHERE PeopleCode = 2 /*OWNER*/
    AND PropertyRSN = @PropertyRSN

	DECLARE @UserID VARCHAR(20)
	SELECT @UserID = current_user

    INSERT INTO PropertyPeople (PropertyRSN, PeopleCode, PeopleRSN, StartDate, StampDate, StampUser)
    SELECT @PropertyRSN, 2, PeopleRSN, @DateExecuted, GetDate(), @UserID
    FROM FolderPeople 
    WHERE FolderRSN = @FolderRSN
    AND PeopleCode = @Grantee

	/*Pente has a prop key as well as parcel id*/
	SELECT @PropertyKey = prop_key
	FROM COB005.pstax.dbo.r_property
	WHERE property_id = @ParcelID

/*

	SET @strSQL = 'UPDATE COB005.pstax.dbo.r_owner
	SET owner_stat = ''X'', bill_flag = ''N''
	WHERE property_id = ''' + @ParcelID + ''''

	EXEC COB005.master.dbo.sp_executesql @strSQL


	UPDATE COB005.pstax.dbo.r_owner
	SET owner_stat = 'X', bill_flag = 'N'
	WHERE property_id = @ParcelID
*/
	DECLARE @NextOwnerCode INT
	DECLARE @LUC VARCHAR(2)

	DECLARE @NextPreviousOwnerCode INT

	SELECT @NextOwnerCode =  MAX(Code) + 1 
	FROM AssessPro.dbo.TableOwnership

	SELECT @NextPreviousOwnerCode = MAX(Code) + 1 
	FROM AssessPro.dbo.TablePreviousOwnership

	INSERT INTO AssessPro.dbo.TablePreviousOwnership
	(Code, Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
	CuO3LastName, CuO3FirstName, CuOStreet1, CuOStreet2, CuOCity, CuOState, CuOPostal, CuOLegalRef,
	CuOSaleDate, UpdtDate, UpdtUser, CuO1OwnerType, CuO1Title, CuO2OwnerType, CuO3OwnerType,
	CuO2Title, CuO3Title, CuOCountyCode, guid)
	SELECT CAST(@NextPreviousOwnerCode AS VARCHAR(10)), Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
	CuO3LastName, CuO3FirstName, CuOStreet1, CuOStreet2, CuOCity, CuOState, CuOPostal, CuOLegalRef,
	CuOSaleDate, UpdtDate, UpdtUser, CuO1OwnerType, CuO1Title, CuO2OwnerType, CuO3OwnerType,
	CuO2Title, CuO3Title, CuOCountyCode, guid
	FROM cobdb.AssessPro.dbo.TableOwnership
	WHERE Code = (SELECT TOP 1 OwnerLookup 
	FROM cobdb.AssessPro.dbo.DataProperty 
	WHERE ParcelID = @ParcelID)

/*
	SET @strSQL =
	'INSERT INTO AssessPro.dbo.TablePreviousOwnership
	(Code, Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
	CuO3LastName, CuO3FirstName, CuOStreet1, CuOStreet2, CuOCity, CuOState, CuOPostal, CuOLegalRef,
	CuOSaleDate, UpdtDate, UpdtUser, CuO1OwnerType, CuO1Title, CuO2OwnerType, CuO3OwnerType,
	CuO2Title, CuO3Title, CuOCountyCode, guid)
	SELECT ''' + CAST(@NextPreviousOwnerCode AS VARCHAR(10)) + ''', Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
	CuO3LastName, CuO3FirstName, CuOStreet1, CuOStreet2, CuOCity, CuOState, CuOPostal, CuOLegalRef,
	CuOSaleDate, UpdtDate, UpdtUser, CuO1OwnerType, CuO1Title, CuO2OwnerType, CuO3OwnerType,
	CuO2Title, CuO3Title, CuOCountyCode, guid
	FROM cobdb.AssessPro.dbo.TableOwnership
	WHERE Code = (SELECT TOP 1 OwnerLookup 
	FROM cobdb.AssessPro.dbo.DataProperty 
	WHERE ParcelID = ''' + @ParcelID + ''')'

	EXEC master.dbo.sp_executesql @strSQL
*/

	DELETE FROM AssessPro.dbo.TableOwnership 
	WHERE Code = (SELECT TOP 1 OwnerLookup 
	FROM AssessPro.dbo.DataProperty 
	WHERE ParcelID = @ParcelID)

	DECLARE curGrantees CURSOR FOR 
		SELECT People.PeopleRSN, People.NameFirst, People.NameLast, People.OrganizationName
		FROM Folder
		INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
		INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
		WHERE Folder.FolderRSN = @FolderRSN
		AND FolderPeople.PeopleCode = @Grantee 

	OPEN curGrantees

	FETCH NEXT FROM curGrantees INTO @PeopleRSN, @FirstName, @LastName, @OrgName

	WHILE @@FETCH_STATUS = 0
		BEGIN
		/*We're limited to 3 owners in AssessPro - break if > 3*/
		SET @i = @i + 1
		SET @BillFlag = 'N'
		SET @OwnerStat = 'R'

		IF EXISTS(SELECT * FROM PeopleInfo WHERE PeopleRSN = @PeopleRSN AND InfoCode = 10/*AssessPro Owner Code*/)
			BEGIN
			UPDATE PeopleInfo 
			SET InfoValue = CAST(@NextOwnerCode AS VARCHAR(50)), 
			InfoValueNumeric = @NextOwnerCode,
			StampDate = GetDate(), StampUser = @UserID, 
			InfoValueUpper = CAST(@NextOwnerCode AS VARCHAR(50))
			WHERE PeopleRSN = @PeopleRSN
			AND InfoCode = 10
			END
		ELSE
			BEGIN
			INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
			SELECT @PeopleRSN, 10, CAST(@NextOwnerCode AS VARCHAR(50)), @NextOwnerCode, GetDate(), @UserID, CAST(@NextOwnerCode AS VARCHAR(50))
		END

		IF EXISTS(SELECT * FROM PeopleInfo WHERE PeopleRSN = @PeopleRSN AND InfoCode = 15/*AssessPro Owner Index*/)
			BEGIN
			UPDATE PeopleInfo 
			SET InfoValue = CAST(@i AS VARCHAR(50)), InfoValueNumeric = @i,
			StampDate = GetDate(), StampUser = @UserID, 
			InfoValueUpper = CAST(@i AS VARCHAR(50))
			WHERE PeopleRSN = @PeopleRSN
			AND InfoCode = 15
			END
		ELSE
			BEGIN
			INSERT INTO PeopleInfo (PeopleRSN, InfoCode, InfoValue, InfoValueNumeric, StampDate, StampUser, InfoValueUpper)
			SELECT @PeopleRSN, 15, CAST(@i AS VARCHAR(50)), @i, GetDate(), @UserID, CAST(@i AS VARCHAR(50))
		END

		IF @i = 1
			BEGIN		
			--PRINT 'OWNER 1: ' + ISNULL(@LastName, '')
			SET @BillFlag = 'Y'
			SET @OwnerStat = 'B'
			SET @CuO1LastName	= @LastName
			SET @CuO1FirstName	= @FirstName
			IF RTRIM(LTRIM(ISNULL(@LastName, '') + ISNULL(@FirstName, ''))) = ''
				BEGIN
				SET @LastName = ISNULL(@OrgName, '')
				SET @FirstName = ''
				SET @OrgName = ''
				SET @CuO1LastName	= @LastName
				SET @CuO1FirstName	= @FirstName
			END
		END 

		IF @i = 2
			BEGIN
			SET @CuO2LastName	= @LastName
			SET @CuO2FirstName	= @FirstName
			IF RTRIM(LTRIM(ISNULL(@LastName, '') + ISNULL(@FirstName, ''))) = ''
				BEGIN
				SET @LastName = ISNULL(@OrgName, '')
				SET @FirstName = ''
				SET @OrgName = ''
				SET @CuO2LastName	= @LastName
				SET @CuO2FirstName	= @FirstName
			END
		END

		IF @i = 3
			BEGIN
			SET @CuO3LastName	= @LastName
			SET @CuO3FirstName	= @FirstName
			IF RTRIM(LTRIM(ISNULL(@LastName, '') + ISNULL(@FirstName, ''))) = ''
				BEGIN
				SET @LastName = ISNULL(@OrgName, '')
				SET @FirstName = ''
				SET @OrgName = ''
				SET @CuO3LastName	= @LastName
				SET @CuO3FirstName	= @FirstName
			END
		END

		IF @i > 3
			BEGIN
			BREAK
		END

		IF ISNULL(@PropertyKey, 0) > 0 
			BEGIN
			IF RTRIM(LTRIM(ISNULL(@AddressPrefix, ''))) <> '' 
				BEGIN
				SET @strSQL = 'INSERT INTO COB005.pstax.dbo.r_owner (property_id, prop_key,
				owner_stat, number, owner_idx, effec_date, l_name, f_name, 
				pid, ssn, attn, addr1, addr2, city, state_abr, zip, country, phone, 
				fax, email, bill_flag, user01, user02)
				VALUES(''' + @ParcelID + ''', ''' + CAST(@PropertyKey AS VARCHAR(20)) + ''', ''' + @OwnerStat + ''', 1, ' + CAST(@i AS VARCHAR(10)) + ', ''' + CAST(ISNULL(@DateExecuted, GetDate()) AS VARCHAR(50)) + ''', ''' + ISNULL(UPPER(REPLACE(@LastName, '''''', '

				''''''')), '') + ''', ''' + ISNULL(UPPER(@FirstName), '') + ''', 
				'''', '''', ''' + ISNULL(UPPER(@OrgName), '') + ''', ''' + ISNULL(UPPER(@AddressPrefix), '''') + ''', ''' + ISNULL(UPPER(@CuOStreet1), '') + ''', ''' + ISNULL(UPPER(@CuOCity), 'BURLINGTON') + ''', ''' + ISNULL(@CuOState, 'VT') + ''', ''' + 
				ISNULL(@CuOPostal, '05401') + ''', '''', '''', '''', '''', ''' + ISNULL(@BillFlag, 'Y') + ''', ''' + CAST(@NextOwnerCode AS VARCHAR(20)) + ''', ''' + CAST(@i AS VARCHAR(10)) + ''')'

				END
			ELSE
				BEGIN
				SET @strSQL = 'INSERT INTO COB005.pstax.dbo.r_owner (property_id, prop_key,
				owner_stat, number, owner_idx, effec_date, l_name, f_name, 
				pid, ssn, 
				attn, addr1, addr2, city, state_abr, zip, 
				country, phone, fax, email, 
				bill_flag, user01, user02)
				VALUES(''' + @ParcelID + ''', ''' + CAST(@PropertyKey AS VARCHAR(20)) + ''', 
				''' + @OwnerStat + ''', 1, ' + CAST(@i AS VARCHAR(10)) + ', ''' + CAST(ISNULL(@DateExecuted, GetDate()) AS VARCHAR(50)) + ''', ''' + ISNULL(UPPER(REPLACE(@LastName, '''', '''''')), '') + ''', ''' + ISNULL(UPPER(@FirstName), '') + ''', 
				'''', '''', 
				''' + ISNULL(UPPER(@OrgName), '') + ''', ''' + ISNULL(UPPER(@CuOStreet1), '') + ''', '''', ''' + ISNULL(UPPER(@CuOCity), 'BURLINGTON') + ''', ''' + ISNULL(@CuOState, 'VT') + ''', ''' + ISNULL(@CuOPostal, '05401') + ''', 
				'''', '''', '''', '''',  
				''' + ISNULL(@BillFlag, 'Y') + ''', ''' + CAST(@NextOwnerCode AS VARCHAR(20)) + ''', ''' + CAST(@i AS VARCHAR(10)) + ''')'

			END
			EXEC COB005.master.dbo.sp_executesql @strSQL
		END

		FETCH NEXT FROM curGrantees INTO @PeopleRSN, @FirstName, @LastName, @OrgName
	END

	CLOSE curGrantees
	DEALLOCATE curGrantees

	IF RTRIM(LTRIM(ISNULL(@AddressPrefix, ''))) <> '' 
		BEGIN
		INSERT INTO AssessPro.dbo.TableOwnership
		(Code, Description, CuO1FirstName, CuO2LastName, CuO2FirstName, CuO3LastName, CuO3FirstName, CuOStreet1, CuOStreet2, 
		CuOCity, CuOState, CuOPostal, CuOLegalRef, CuOSaleDate, UpdtDate, UpdtUser)
		VALUES(@NextOwnerCode, UPPER(ISNULL(@CuO1LastName,'')),UPPER(ISNULL(@CuO1FirstName,'')), UPPER(ISNULL(@CuO2LastName,' ')),
		UPPER(ISNULL(@CuO2FirstName,'')), UPPER(ISNULL(@CuO3LastName,'')), UPPER(ISNULL(@CuO3FirstName,'')),
		UPPER(ISNULL(@AddressPrefix,'')), UPPER(ISNULL(@CuOStreet1,'')), UPPER(ISNULL(@CuOCity,'Burlington')),  
		UPPER(ISNULL(@CuOState, 'VT')), UPPER(ISNULL(@CuOPostal, '05401')), @Book + '-' + @Page, 
		@DateExecuted, GetDate(), 'ct')
/*
		SET @strSQL =  
		'INSERT INTO AssessPro.dbo.TableOwnership(Code, Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
		CuO3LastName, CuO3FirstName, CuOStreet1, CuOStreet2, CuOCity, CuOState, CuOPostal, CuOLegalRef,
		CuOSaleDate, UpdtDate, UpdtUser)
		VALUES(' + CAST(@NextOwnerCode AS VARCHAR(10)) + ',  ''' + UPPER(ISNULL(@CuO1LastName,'')) + ''', ''' + 
		UPPER(ISNULL(@CuO1FirstName,'')) + ''', ''' + UPPER(ISNULL(@CuO2LastName,' '))+ ''', ''' + 
		UPPER(ISNULL(@CuO2FirstName,'')) + ''', ''' + UPPER(ISNULL(@CuO3LastName,'')) + ''', ''' + 
		UPPER(ISNULL(@CuO3FirstName,'')) + ''', ''' + UPPER(ISNULL(@AddressPrefix,'')) + ''', ''' + 
		UPPER(ISNULL(@CuOStreet1,'')) + ''', ''' + UPPER(ISNULL(@CuOCity,'Burlington')) + ''', ''' + 
		UPPER(ISNULL(@CuOState, 'VT')) + ''', ''' + UPPER(ISNULL(@CuOPostal, '05401')) + ''', ''' +
		+ @Book + '-' + @Page + ''', ''' + CAST(dbo.FormatDateTime(@DateExecuted, 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''' + 
		CAST(dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''ct'')'
*/
		END
	ELSE
		BEGIN
		INSERT INTO AssessPro.dbo.TableOwnership(Code, Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
		CuO3LastName, CuO3FirstName, CuOStreet1, CuOCity, CuOState, CuOPostal, CuOLegalRef, CuOSaleDate, UpdtDate, UpdtUser)
		VALUES(@NextOwnerCode, UPPER(ISNULL(@CuO1LastName,'')), UPPER(ISNULL(@CuO1FirstName,'')), UPPER(ISNULL(@CuO2LastName,' ')),
		UPPER(ISNULL(@CuO2FirstName,'')), UPPER(ISNULL(@CuO3LastName,'')), UPPER(ISNULL(@CuO3FirstName,'')), 
		UPPER(ISNULL(@CuOStreet1,'')), UPPER(ISNULL(@CuOCity,'Burlington')), UPPER(ISNULL(@CuOState, 'VT')), 
		UPPER(ISNULL(@CuOPostal, '05401')),	@Book + '-' + @Page, @DateExecuted, GetDate(), 'ct')
/*
		SET @strSQL =  
		'INSERT INTO AssessPro.dbo.TableOwnership(Code, Description, CuO1FirstName, CuO2LastName, CuO2FirstName,
		CuO3LastName, CuO3FirstName, CuOStreet1, CuOCity, CuOState, CuOPostal, CuOLegalRef,
		CuOSaleDate, UpdtDate, UpdtUser)
		VALUES(' + CAST(@NextOwnerCode AS VARCHAR(10)) + ',  ''' + UPPER(ISNULL(@CuO1LastName,'')) + ''', ''' + 
		UPPER(ISNULL(@CuO1FirstName,'')) + ''', ''' + UPPER(ISNULL(@CuO2LastName,' '))+ ''', ''' + 
		UPPER(ISNULL(@CuO2FirstName,'')) + ''', ''' + UPPER(ISNULL(@CuO3LastName,'')) + ''', ''' + 
		UPPER(ISNULL(@CuO3FirstName,'')) + ''', ''' + UPPER(ISNULL(@CuOStreet1,'')) + ''', ''' +
		UPPER(ISNULL(@CuOCity,'Burlington')) + ''', ''' + UPPER(ISNULL(@CuOState, 'VT')) + ''', ''' + 
		UPPER(ISNULL(@CuOPostal, '05401')) + ''', ''' +
		+ @Book + '-' + @Page + ''', ''' + CAST(dbo.FormatDateTime(@DateExecuted, 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''' + 
		CAST(dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''ct'')'
*/
	END
	--EXEC master.dbo.sp_executesql @strSQL

	SELECT @AccountNumber = DP.AccountNumber, @LUC = DL.LUC
	FROM cobdb.AssessPro.dbo.DataProperty DP INNER JOIN
	cobdb.AssessPro.dbo.DataLand DL ON DL.AccountNumber = DP.AccountNumber 
	WHERE ParcelID = @ParcelID
	AND DP.CardNumber = 1 AND DL.SeqNumber = 1

	UPDATE AssessPro.dbo.DataProperty SET OwnerLookup = @NextOwnerCode WHERE ParcelID = @ParcelID
/*
	SET @strSQL =  
	'UPDATE AssessPro.dbo.DataProperty
	SET OwnerLookup = ' + CAST(@NextOwnerCode AS VARCHAR(10)) + 
	' WHERE ParcelID = ''' + @ParcelID + ''''
	EXEC master.dbo.sp_executesql @strSQL
*/

	UPDATE AssessPro.dbo.DataSales SET SeqNumber = SeqNumber + 1 WHERE AccountNumber = @AccountNumber
/*
	SET @strSQL =  
	'UPDATE AssessPro.dbo.DataSales 
	SET SeqNumber = SeqNumber + 1 
	WHERE AccountNumber = ' + CAST(@AccountNumber AS VARCHAR(10))
	EXEC master.dbo.sp_executesql @strSQL
*/

	INSERT INTO AssessPro.dbo.DataSales (AccountNumber, CardNumber, SaleDate, SeqNumber, SalePrice, Book, Page, 
	LegalReference, LUCatsale, RecordingDate, DeedType, UpdtDate, UpdtUser, GrantorLastName, GrantOwnerLookup, Notes)
	VALUES(@AccountNumber, 1, @DateExecuted, 0, @SalePrice, @Book, @Page, @Book + '-' + @Page, @LUC, @DateRecorded, 
	@DocumentType, GetDate(), 'ct', @GrantorName, @NextPreviousOwnerCode, @Notes)
/*
	SET @strSQL =  
	'INSERT INTO AssessPro.dbo.DataSales (AccountNumber, CardNumber, SaleDate, SeqNumber, SalePrice, Book, Page, 
	LegalReference, LUCatsale, RecordingDate, DeedType, UpdtDate, UpdtUser, GrantorLastName, GrantOwnerLookup, Notes)
	VALUES(' + CAST(@AccountNumber AS VARCHAR(10)) + ', 1, ''' + 
	CAST(dbo.FormatDateTime(@DateExecuted, 'MM/DD/YYYY') AS VARCHAR(20)) + ''', 0, ' + 
	CAST(@SalePrice AS VARCHAR(15)) + ', ''' + @Book + ''', ''' + @Page + ''', ''' + @Book + '-' + @Page + ''', ''' + 
	@LUC + ''', ''' + CAST(dbo.FormatDateTime(@DateRecorded, 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''' + 
	@DocumentType + ''', ''' + CAST(dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''ct'', ''' + 
	@GrantorName + ''',' + CAST(@NextPreviousOwnerCode AS VARCHAR(10)) + ', ''' +	@Notes + ''')'
	EXEC master.dbo.sp_executesql @strSQL
*/
	IF @PDF <> ''
		BEGIN
		UPDATE AssessPro.dbo.DataLinks SET SeqNumber = SeqNumber + 1 WHERE AccountNumber = @AccountNumber
/*
		SET @strSQL =  
		'UPDATE AssessPro.dbo.DataLinks SET SeqNumber = SeqNumber + 1 
		WHERE AccountNumber = ' + CAST(@AccountNumber AS VARCHAR(10)) + ')'
		EXEC master.dbo.sp_executesql @strSQL
*/
		INSERT INTO AssessPro.dbo.DataLinks (AccountNumber, CardNumber, SeqNumber, ObjectName, Filename, Description, 
		UpdtDate, UpdtUser)
		VALUES(@AccountNumber, 1, 0, 'SHELL', 'http://Patriot/PropertyTransfers/' + @PDF, 'Property Transfer', GetDate(), 'ct')
/*
		SET @strSQL =  
		'INSERT INTO AssessPro.dbo.DataLinks (AccountNumber, CardNumber, SeqNumber, ObjectName, Filename, 
		Description, UpdtDate, UpdtUser)
		VALUES(' + CAST(@AccountNumber  AS VARCHAR(10)) + ', 1, 0, ''SHELL'', ''http://Patriot/PropertyTransfers/' + @PDF + 
		''', ''Property Transfer'', ' + CAST(dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY') AS VARCHAR(20)) + ''', ''ct'')'
		EXEC master.dbo.sp_executesql @strSQL
*/
	END

END


GO
