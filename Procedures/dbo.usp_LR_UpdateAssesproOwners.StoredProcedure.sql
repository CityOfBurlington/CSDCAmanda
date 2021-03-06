USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_LR_UpdateAssesproOwners]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_LR_UpdateAssesproOwners](@FolderRSN INT) 
AS
BEGIN
	DECLARE @i INT

	DECLARE @PeopleRSN INT
	DECLARE @FirstName VARCHAR(100)
	DECLARE @LastName VARCHAR(100)
	DECLARE @A_OwnerCode INT

	DECLARE @ParcelID VARCHAR(20)
	DECLARE @Book VARCHAR(10)
	DECLARE @Page VARCHAR(10)
	DECLARE @DateRecorded DATETIME	
	DECLARE @DateExecuted DATETIME
	DECLARE @SalePrice FLOAT

	SELECT @i = 0, @ParcelID = Property.PropertyRoll, @Book = dbo.f_info_numeric(Folder.FolderRSN, 2000),
	@Page = dbo.f_info_numeric(Folder.FolderRSN, 2001), @DateRecorded = dbo.f_info_date(Folder.FolderRSN, 2002),
	@DateExecuted = dbo.f_info_date(Folder.FolderRSN, 2003), @SalePrice = dbo.f_info_numeric(Folder.FolderRSN, 2006)
	FROM Folder
	INNER JOIN FolderProperty ON Folder.FolderRSN = FolderProperty.FolderRSN
	INNER JOIN Property ON FolderProperty.PropertyRSN = Property.PropertyRSN
	WHERE Folder.FolderRSN = @FolderRSN

	DECLARE curGrantees CURSOR FOR 
		SELECT People.PeopleRSN, People.NameFirst, People.NameLast
		FROM Folder
		INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
		INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
		WHERE Folder.FolderRSN = @FolderRSN
		AND FolderPeople.PeopleCode = 95

	OPEN curGrantees

	FETCH NEXT FROM curGrantees INTO @PeopleRSN, @FirstName, @LastName

	WHILE @@FETCH_STATUS = 0
		BEGIN

		SET @i = @i + 1

		IF @i = 1 
			BEGIN
			PRINT '1'
		END

		IF @i = 2 
			BEGIN
			PRINT '2'
		END

		IF @i = 3 
			BEGIN
			PRINT '3'
		END

		IF @i = 4
			BEGIN
			BREAK
		END

		FETCH NEXT FROM curGrantees INTO @PeopleRSN, @FirstName, @LastName
	END

	CLOSE curGrantees
	DEALLOCATE curGrantees
END



GO
