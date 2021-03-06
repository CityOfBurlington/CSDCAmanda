USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_MH]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_MH]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @intCOMReturnValue INT

IF NOT EXISTS (SELECT * FROM FolderInfo WHERE InfoCode = 4020 AND FolderRSN = @FolderRSN) BEGIN

    INSERT INTO FolderInfo 
    (FolderRSN, InfoValue, InfoValueUpper, InfoCode) 
    VALUES (@FolderRSN, @UserId, UPPER(@UserId), 4020)
END


COMMIT TRANSACTION
BEGIN TRANSACTION

DECLARE @PrinterCode INT

SELECT @PrinterCode = ISNULL(ValidUser.CashDrawerCode, 80)
FROM ValidUser
WHERE UserId = @UserId

IF @PrinterCode <> 20 BEGIN
    SET @PrinterCode = 80
END
/*
xspInspectionDueLetter Params:

FolderRSN
PeopleCode (322=Primary Code Owner; 75=Property Manager)
UserID
DatabaseEnum (10=Dev 20=Prod)
PrinterEnum (10=ClerkTreasurer 20=CodeAdmin 30=LandRecords 80=CodeInspectors)
*/


EXEC @intCOMReturnValue = xspInspectionDueLetter @FolderRSN, 322, @UserId, 20, @PrinterCode
IF EXISTS (SELECT * FROM FolderPeople WHERE FolderRSN = @FolderRSN and PeopleCode = 75) BEGIN
EXEC @intCOMReturnValue = xspInspectionDueLetter @FolderRSN, 75, @UserId, 20, @PrinterCode
END

/* SET @intCOMReturnValue = 0 */
IF @intCOMReturnValue = 0
    BEGIN
        UPDATE FolderProcess 
        SET AssignedUser = @UserId
        WHERE FolderRSN = @FolderRSN
        AND ProcessCode = 20028

        UPDATE Folder
        SET WorkCode = 20060,
        ExpiryDate = DateAdd(d, 19, GetDate())
        WHERE FolderRSN = @FolderRSN

        EXEC usp_UpdateFolderCondition @FolderRSN, 'Folder Issued/Inspection Due Letter Sent'
    END

IF @intCOMReturnValue = 1
    BEGIN
        RAISERROR('Failed to Create Inspection Due Letter (1)', 16, -1)
    END

IF @intCOMReturnValue = 2
    BEGIN
        RAISERROR('Failed to Create Inspection Due Letter (2)', 16, -1)
    END

IF @intCOMReturnValue = 3
    BEGIN
        RAISERROR('Could not access File System on Patriot Server', 16, -1)
    END

IF @intCOMReturnValue = 4
    BEGIN
        RAISERROR('Could not create/access User directory on Patriot Server', 16, -1)
    END

IF @intCOMReturnValue = 5
    BEGIN
        RAISERROR('Failed to insert record to Attachment table in Amanda', 16, -1)
    END

IF @intCOMReturnValue = 6
    BEGIN
        RAISERROR('Failed to Print Inspection Due Letter', 16, -1)
    END


GO
