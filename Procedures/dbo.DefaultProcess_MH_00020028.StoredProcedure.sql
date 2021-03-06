USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_MH_00020028]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_MH_00020028]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/*
MH Pre-Inspection ProcessCode 20028
DefaultProcess_MH_00020028
*/

DECLARE @RentalUnits INT
DECLARE @AttemptResult int
DECLARE @AttemptDate DateTime
DECLARE @AttemptCount int
DECLARE @AttemptRSN int
DECLARE @Inspector varchar(8)
DECLARE @ScheduleDate DATETIME
DECLARE @ScheduleEndDate DATETIME
DECLARE @strScheduledDate VARCHAR(100)
DECLARE @intCOMReturnValue INT
DECLARE @intFolderProcessInfo20001 INT

SET @AttemptCount = 1 /*Initial Inspection*/

SELECT @RentalUnits = CAST(dbo.f_info_numeric_property(PropertyRSN, 15) AS INT)
FROM Folder 
WHERE FolderRSN = @FolderRSN

SELECT @AttemptDate = FolderProcess.ScheduleDate
FROM FolderProcess
WHERE ProcessRSN = @ProcessRSN

SELECT @AttemptResult = ResultCode, 
@AttemptRSN = AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT MAX(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @ScheduleDate = ScheduleDate 
FROM FolderProcess 
WHERE ProcessRSN = @ProcessRSN

IF @AttemptResult = 20045 /*Inspection Scheduled*/
    BEGIN

	IF @ScheduleDate IS NULL
            BEGIN
            RAISERROR('Schedule date must be entered', 16, -1)
            ROLLBACK TRANSACTION
        END

    SELECT @Inspector = IssueUser 
    FROM Folder
    WHERE FolderRSN = @FolderRSN 

    /* Routine Inspection, Inspections */ 
    SELECT @NextProcessRSN = @NextProcessRSN + 1 

    SELECT @ScheduleEndDate = DATEADD(n, dbo.udf_GetInspectionTime(@RentalUnits, 1/* Inspection # */) * 15, @ScheduleDate)

    INSERT INTO FolderProcess 
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
    PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
    ScheduleDate, ScheduleEndDate) 
    VALUES ( @NextProcessRSN, @FolderRSN, 20030, 90, 
    'Y', 1, GetDate(), @UserId, @Inspector, 
    @ScheduleDate, @ScheduleEndDate) 

    /*Update Process with number of non-complied units for billing */
	SELECT @intFolderProcessInfo20001 = COUNT(*) FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN and InfoCode = 20001
	IF @intFolderProcessInfo20001 > 0
	BEGIN
		UPDATE FolderProcessInfo SET InfoValue = CAST(@RentalUnits AS VARCHAR(20)), 
			InfoValueNumeric = @RentalUnits,
			StampDate = GetDate(), StampUser = @UserID
		WHERE ProcessRSN = @ProcessRSN and InfoCode = 20001
	END
	ELSE
	BEGIN
        INSERT INTO FolderProcessInfo (ProcessRSN,
	        InfoCode, InfoValue, InfoValueNumeric, DisplayOrder, StampDate, StampUser, FolderRSN)
		VALUES (@NextProcessRSN, 20001, CAST(@RentalUnits AS VARCHAR(20)), @RentalUnits, 10, GetDate(),
			@UserID, @FolderRSN)
	END

    UPDATE Folder
    SET WorkCode = 20066 /*Routine Insp Scheduled*/,
    ExpiryDate = @AttemptDate
    WHERE FolderRSN = @FolderRSN

    UPDATE FolderProcess
    SET ScheduleEndDate = @ScheduleEndDate 
    WHERE ProcessRSN = @NextProcessRSN

    UPDATE FolderProcess
    SET ScheduleEndDate = @ScheduleEndDate 
    WHERE ProcessRSN = @ProcessRSN

    SELECT @strScheduledDate = dbo.FormatDateTime(@ScheduleDate, 'MM/DD/YYYY HH:MM 12')

    SET @strScheduledDate = 'Inspection Scheduled for ' + @strScheduledDate

    EXEC usp_UpdateFolderCondition @FolderRSN, @strScheduledDate

    COMMIT TRANSACTION
    BEGIN TRANSACTION

    EXEC @intCOMReturnValue = xspScheduleCodeEnforcementInspection @FolderRSN, @ProcessRSN, @AttemptRSN, 1
    IF @intCOMReturnValue > 0
    BEGIN
        RAISERROR('Failed to create workorder calendar item', 16, -1)    
	END

    EXEC @intCOMReturnValue = xspSendInspectionWorkOrder @UserId, @FolderRSN, @ProcessRSN, @AttemptRSN, @AttemptCount, 20
    IF @intCOMReturnValue > 0
    BEGIN
        RAISERROR('Failed to create workorder', 16, -1)
    END


END

IF @AttemptResult = 20072 /*2nd Routine Insp Due Ltr Sent*/
 BEGIN

 COMMIT TRANSACTION
    BEGIN TRANSACTION

    /*
    xspInspectionDueLetter Params: 
    FolderRSN
    PeopleCode (322=PrimaryCodeOwner)
    UserID 
    DatabaseEnum (10=Dev 20=Prod)
    PrinterEnum (10=ClerkTreasurer 20=CodeAdmin 30=LandRecords)
    */

    EXEC @intCOMReturnValue = xspInspectionDueLetter @FolderRSN, 322/*Primary Code Owner*/, @UserId, 10, 80

    IF @intCOMReturnValue = 0
        BEGIN

        EXEC usp_UpdateFolderCondition @FolderRSN, 'Second Inspection Due Letter Sent'

        UPDATE Folder
        SET WorkCode = 20068 /*2nd Routine Insp Due Ltr Sent*/,
        ExpiryDate = DateAdd(d, 12, @AttemptDate)
        WHERE FolderRSN = @FolderRSN

        --Reopen process
        Update FolderProcess
        Set StatusCode = 1, EndDate = NULL, 
        SignOffUser = NULL,   
        ScheduleEndDate = DateAdd(d, 12, @AttemptDate)
        WHERE ProcessRSN = @ProcessRSN
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

END



GO
