USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_LR]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_LR]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
SET ANSI_WARNINGS ON

SET ANSI_NULLS ON

DECLARE @AddrPrefix    VARCHAR(100)
DECLARE @AddrHouse     VARCHAR(10)
DECLARE @AddrStreet    VARCHAR(40)
DECLARE @AddrCity      VARCHAR(20)
DECLARE @AddrProvince  VARCHAR(2)
DECLARE @AddrPostal    VARCHAR(12)
DECLARE @ParcelID      VARCHAR(20)
DECLARE @ValidPeople   INT
DECLARE @WorkCode      INT

SET @ValidPeople = 1

UPDATE Property
SET Property.StatusCode = 1                 /* Active */
FROM Folder
INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN
AND Property.StatusCode = 3                 /* Pending */

SELECT @ParcelID = Property.PropertyRoll, @WorkCode = Folder.WorkCode
FROM Folder
INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN

DECLARE curPeople CURSOR FOR
SELECT People.AddrPrefix, People.AddrHouse, People.AddrStreet, 
People.AddrCity, People.AddrProvince, People.AddrPostal
FROM Folder
INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
WHERE FolderPeople.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = 95 /*Grantee*/

OPEN curPeople

FETCH NEXT FROM curPeople INTO
@AddrPrefix, @AddrHouse, @AddrStreet, @AddrCity, @AddrProvince, @AddrPostal

WHILE @@FETCH_STATUS = 0
    BEGIN
      IF  RTRIM(LTRIM(ISNULL(@AddrHouse, ''))) 
                + RTRIM(LTRIM(ISNULL(@AddrStreet, ''))) 
                + RTRIM(LTRIM(ISNULL(@AddrPrefix, ''))) = ''
       OR (RTRIM(LTRIM(ISNULL(@AddrCity, ''))) = '')
       OR (RTRIM(LTRIM(ISNULL(@AddrProvince, ''))) = '')
       OR (RTRIM(LTRIM(ISNULL(@AddrPostal, ''))) = '') BEGIN

       SET @ValidPeople = 0

    END

    FETCH NEXT FROM curPeople INTO
    @AddrPrefix, @AddrHouse, @AddrStreet, @AddrCity, @AddrProvince, @AddrPostal
END 

CLOSE curPeople
DEALLOCATE curPeople

IF @ValidPeople = 0 AND @WorkCode <> 1533
    BEGIN
    RAISERROR('One or more people are missing a valid address', 16, -1)
END

IF @ValidPeople= 1
BEGIN
    COMMIT TRANSACTION
    BEGIN TRANSACTION
    EXEC usp_LR_Update_Owners @FolderRSN
    COMMIT TRANSACTION

    BEGIN TRANSACTION
        EXEC xspInsertOwnerIntoNemrc @ParcelID
END
GO
