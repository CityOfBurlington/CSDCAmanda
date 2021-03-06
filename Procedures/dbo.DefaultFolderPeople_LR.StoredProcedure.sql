USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFolderPeople_LR]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFolderPeople_LR]
@FolderRSN int, @UserId char(10), @PeopleRSN int, @PeopleCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @intPeopleGrantee INT
DECLARE @intPeopleGrantor INT

DECLARE @intGrantors INT
DECLARE @intGrantees INT

SET @intPeopleGrantor = 90
SET @intPeopleGrantee = 95

DECLARE @FirstName VARCHAR(100)
DECLARE @LastName VARCHAR(100)
DECLARE @OrganizationName VARCHAR(200)
DECLARE @intInfoCode INT
DECLARE @strInfoValue VARCHAR(500)
DECLARE @intDisplayOrder SMALLINT

SET @intDisplayOrder = 80

DECLARE curGrantors CURSOR FOR
SELECT People.NameFirst, People.NameLast, People.OrganizationName 
FROM Folder
INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
WHERE FolderPeople.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = @intPeopleGrantor
AND Folder.ExpiryDate IS NULL

SET @intInfoCode = 2010 /*first grantor*/

OPEN curGrantors
FETCH NEXT FROM curGrantors INTO @FirstName, @LastName, @OrganizationName

WHILE @@FETCH_STATUS = 0 
    
        BEGIN
            SET @strInfoValue = ISNULL(@LastName, '')
			IF LEN(@strInfoValue) > 0 SET @strInfoValue = @strInfoValue + ', '
            SET @strInfoValue = @strInfoValue + RTRIM(LTRIM(ISNULL(@FirstName, '') + ISNULL(' ' + @OrganizationName, '')))

            INSERT INTO FolderInfo
            (FolderRSN, InfoCode, InfoValue, DisplayOrder, StampDate, StampUser, InfoValueUpper, PrintFlag)
            VALUES(@FolderRSN, @intInfoCode, @strInfoValue, @intDisplayOrder, GetDate(), @UserID, UPPER(@strInfoValue), 'Y')

            SET @intInfoCode = @intInfoCode + 1
            SET @intDisplayOrder = @intDisplayOrder + 1

            FETCH NEXT FROM curGrantors INTO @FirstName, @LastName, @OrganizationName
        END

CLOSE curGrantors
DEALLOCATE curGrantors



DECLARE curGrantees CURSOR FOR
SELECT People.NameFirst, People.NameLast, People.OrganizationName 
FROM Folder
INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
WHERE FolderPeople.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = @intPeopleGrantee
AND Folder.ExpiryDate IS NULL

SET @intDisplayOrder = 90
SET @intInfoCode = 2020 /*first grantee*/

OPEN curGrantees
FETCH NEXT FROM curGrantees INTO @FirstName, @LastName, @OrganizationName

WHILE @@FETCH_STATUS = 0 
    
        BEGIN
            SET @strInfoValue = ISNULL(@LastName, '')
			IF LEN(@strInfoValue) > 0 SET @strInfoValue = @strInfoValue + ', '
            SET @strInfoValue = @strInfoValue + RTRIM(LTRIM(ISNULL(@FirstName, '') + ISNULL(' ' + @OrganizationName, '')))

            INSERT INTO FolderInfo
            (FolderRSN, InfoCode, InfoValue, DisplayOrder, StampDate, StampUser, InfoValueUpper, PrintFlag)
            VALUES(@FolderRSN, @intInfoCode, @strInfoValue, @intDisplayOrder, GetDate(), @UserID, UPPER(@strInfoValue), 'Y')

            SET @intInfoCode = @intInfoCode + 1
            SET @intDisplayOrder = @intDisplayOrder + 1

            FETCH NEXT FROM curGrantees INTO @FirstName, @LastName, @OrganizationName
        END

CLOSE curGrantees
DEALLOCATE curGrantees

DECLARE @intWorkCode INT

SELECT @intWorkCode = WorkCode
FROM Folder
WHERE FolderRSN = @FolderRSN

IF @intWorkCode = 1532
    BEGIN
        UPDATE FolderInfo
        SET InfoValue = 'Yes',
        InfoValueUpper = 'YES'
        WHERE FolderRSN = @FolderRSN
        AND InfoCode = 2007
    END

/*populate expirydate so this only runs once*/
UPDATE Folder 
SET ExpiryDate = GetDate()
WHERE FolderRSN = @FolderRSN


GO
