USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddressChangeAssessPro]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_AddressChangeAssessPro]
as

DECLARE @ParcelID VARCHAR(20)
DECLARE @strSQL NVARCHAR(2000)
DECLARE @AddrCity VARCHAR(40)
DECLARE @AddrState VARCHAR(2)
DECLARE @AddrZip VARCHAR(40)
DECLARE @AddrCountry VARCHAR(12)
DECLARE @WorkCode INT
DECLARE @UpdtUser VARCHAR(30)
DECLARE @UpdtDate SMALLDATETIME

DECLARE @APDescription VARCHAR(100)
DECLARE @APOwner1FirstName VARCHAR(100)
DECLARE @APOwner2LastName VARCHAR(100)
DECLARE @APOwner2FirstName VARCHAR(100)

DECLARE @Owner1FirstName VARCHAR(100)
DECLARE @Owner1LastName VARCHAR(100)
DECLARE @Owner2LastName VARCHAR(100)
DECLARE @Owner2FirstName VARCHAR(100)
DECLARE @AProAddress1 VARCHAR(100)
DECLARE @AProAddress2 VARCHAR(100)

DECLARE @OrganizationName VARCHAR(100)
DECLARE @AddrStreet1 VARCHAR(100)
DECLARE @AddrStreet2 VARCHAR(100)

DECLARE @OwnerCode INT
DECLARE @RowNumber INT


	DECLARE curAP CURSOR FOR
		SELECT RowNumber, ParcelID, OrganizationName, Owner1LastName, Owner1FirstName, Owner2LastName, Owner2FirstName, 
		AddrStreet1, AddrStreet2, AddrCity, AddrState, AddrPostal, AddrCountyCode, WorkCode, UpdtDate, UpdtUser
		FROM tblAPTableOwnership
		WHERE SentToAProDate IS NULL 
		
	OPEN curAP
	FETCH NEXT FROM curAP INTO @RowNumber, @ParcelID, @OrganizationName, @Owner1LastName, @Owner1FirstName, @Owner2LastName, @Owner2FirstName,
		@AddrStreet1, @AddrStreet2, @AddrCity, @AddrState, @AddrZIP, @AddrCountry, @WorkCode, @UpdtDate, @UpdtUser

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @OwnerCode = O.Code FROM cobdb.AssessPro.dbo.TableOwnership O
		INNER JOIN cobdb.AssessPro.dbo.DataProperty P ON O.Code = P.OwnerLookup
		WHERE P.ParcelID = @ParcelID

		IF @WorkCode = 4000 /* Address Change ONLY */
		BEGIN
			SET @strSQL = 'UPDATE cobdb.AssessPro.dbo.TableOwnership
			 SET 
			 CuOStreet1 = ''' + RTRIM(LTRIM(UPPER(@AddrStreet1))) + ''', 
			 CuOStreet2 = ''' + RTRIM(LTRIM(UPPER(@AddrStreet2))) + ''',
			 CuOCity = ''' + RTRIM(LTRIM(UPPER(@AddrCity))) + ''', 
			 CuOState = ''' + RTRIM(LTRIM(UPPER(@AddrState))) + ''', 
			 CuOPostal = ''' + RTRIM(LTRIM(UPPER(@AddrZIP))) + ''', 
			 CuOCountyCode = ''' + RTRIM(LTRIM(UPPER(@AddrCountry))) + ''', 
			 UpdtDate = ''' + CAST(ISNULL(@UpdtDate, GetDate()) AS VARCHAR(20)) + ''',
			 UpdtUser = ''' + RTRIM(LTRIM(@UpdtUser)) + '''
			 WHERE Code = ' + RTRIM(LTRIM(STR(@OwnerCode))) + ''
		     
			EXEC cobdb.master.dbo.sp_executesql @strSQL
		END

		IF @WorkCode = 4005 /* Name Change ONLY */
		BEGIN

			SELECT @APDescription = Description, @APOwner1FirstName = CuO1FirstName,
			@APOwner2LastName = CuO2LastName , @APOwner2FirstName = CuO2FirstName
			FROM cobdb.AssessPro.dbo.TableOwnership
			WHERE Code = @OwnerCode

			IF LEN(@OrganizationName) > 0
			BEGIN
				IF @OrganizationName <> @APDescription SET @APDescription = @OrganizationName
				IF @Owner1FirstName IS NOT NULL
				BEGIN
					IF @Owner1FirstName <> @APOwner1FirstName SET @APOwner1FirstName = @Owner1FirstName
				END
			END
			ELSE
			BEGIN
				SET @OrganizationName = NULL

				IF LEN(@Owner1LastName) > 0
				BEGIN
					IF @Owner1LastName <> @APDescription SET @APDescription = @Owner1LastName
				END
				IF LEN(@Owner1FirstName) > 0
				BEGIN
					IF @Owner1FirstName <> @APOwner1FirstName SET @APOwner1FirstName = @Owner1FirstName
				END
				IF LEN(@Owner2LastName) > 0
				BEGIN
					IF @Owner2LastName <> @APOwner2LastName SET @APOwner2LastName = @Owner2LastName
				END
				IF LEN(@Owner2FirstName) > 0
				BEGIN
					IF @Owner2FirstName <> @APOwner2FirstName SET @APOwner2FirstName = @Owner2FirstName
				END
			END

			SET @strSQL = 'UPDATE cobdb.AssessPro.dbo.TableOwnership
			 SET 
			 Description = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APDescription,'')))) + ''', 
			 CuO1FirstName = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APOwner1FirstName,'')))) + ''', 
			 CuO2FirstName = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APOwner2FirstName,'')))) + ''', 
			 CuO2LastName = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APOwner2LastName,'')))) + ''',
			 UpdtDate = ''' + CAST(ISNULL(@UpdtDate, GetDate()) AS VARCHAR(20)) + ''',
			 UpdtUser = ''' + RTRIM(LTRIM(@UpdtUser)) + '''
			 WHERE Code = ' + RTRIM(LTRIM(STR(@OwnerCode))) + ''
		     
			EXEC cobdb.master.dbo.sp_executesql @strSQL

		END

		IF @WorkCode = 4010 /* Name Change AND Address Change */
		BEGIN
			SET @strSQL = 'UPDATE cobdb.AssessPro.dbo.TableOwnership
			 SET 
			 Description = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APDescription,'')))) + ''', 
			 CuO1FirstName = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APOwner1FirstName,'')))) + ''', 
			 CuO2FirstName = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APOwner2FirstName,'')))) + ''', 
			 CuO2LastName = ''' + RTRIM(LTRIM(UPPER(ISNULL(@APOwner2LastName,'')))) + ''',
			 CuOStreet1 = ''' + RTRIM(LTRIM(UPPER(@AddrStreet1))) + ''', 
			 CuOStreet2 = ''' + RTRIM(LTRIM(UPPER(@AddrStreet2))) + ''',
			 CuOCity = ''' + RTRIM(LTRIM(UPPER(@AddrCity))) + ''', 
			 CuOState = ''' + RTRIM(LTRIM(UPPER(@AddrState))) + ''', 
			 CuOPostal = ''' + RTRIM(LTRIM(UPPER(@AddrZIP))) + ''', 
			 CuOCountyCode = ''' + RTRIM(LTRIM(UPPER(@AddrCountry))) + ''', 
			 UpdtDate = ''' + CAST(ISNULL(@UpdtDate, GetDate()) AS VARCHAR(20)) + ''',
			 UpdtUser = ''' + RTRIM(LTRIM(@UpdtUser)) + '''
			 WHERE Code = ' + RTRIM(LTRIM(STR(@OwnerCode))) + ''
		     
			EXEC cobdb.master.dbo.sp_executesql @strSQL

		END
		UPDATE tblAPTableOwnership SET SentToAProDate = getdate() WHERE RowNumber = @RowNumber

	FETCH NEXT FROM curAP INTO @RowNumber, @ParcelID, @OrganizationName, @Owner1LastName, @Owner1FirstName, @Owner2LastName, @Owner2FirstName,
		@AddrStreet1, @AddrStreet2, @AddrCity, @AddrState, @AddrZIP, @AddrCountry, @WorkCode, @UpdtDate, @UpdtUser
		
	END

	CLOSE curAP
	DEALLOCATE curAP

GO
