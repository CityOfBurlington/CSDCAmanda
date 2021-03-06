USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_MH_00020030]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_MH_00020030]
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
MH Routine Inspection ProcessCode 20030
DefaultProcess_MH_00020030
*/
DECLARE @AttemptRSN INT
DECLARE @AttemptCount INT
DECLARE @intCOMReturnValue INT
DECLARE @AttemptResult int
DECLARE @AttemptDate DateTime
DECLARE @Inspector varchar(10) 
DECLARE @intDeficiencies INT
DECLARE @MHAdminUser Varchar(30)
DECLARE @ScheduleDate DATETIME
DECLARE @ScheduleEndDate DATETIME
DECLARE @strScheduledDate VARCHAR(100)
DECLARE @RentalUnits INT
DECLARE @strMessage VARCHAR(400)
DECLARE @intNonCompliedUnits INT
DECLARE @dblFeeAmount MONEY
DECLARE @intNextAccountBillFeeRSN INT
DECLARE @dblFeeMultiplier MONEY
DECLARE @FeeComment VARCHAR(35)

SELECT @RentalUnits = CAST(dbo.f_info_numeric_property(PropertyRSN, 15) AS INT)
FROM Folder 
WHERE FolderRSN = @FolderRSN

SELECT @AttemptDate = FolderProcess.ScheduleDate, 
@ScheduleDate = ScheduleDate
FROM FolderProcess
WHERE ProcessRSN = @ProcessRSN

SELECT TOP 1 @MHAdminUser = dbo.f_info_alpha(FolderRSN, 30141 /*MH Admin Process User*/)
FROM Folder
WHERE FolderType = 'AA'
ORDER BY FolderRSN DESC

SELECT @intDeficiencies = SUM(1)
FROM FolderProcessDeficiency
WHERE FolderRSN = @FolderRSN
AND ProcessRSN = @ProcessRSN
AND StatusCode = 1 /*Non-Complied*/

SET @intDeficiencies = ISNULL(@intDeficiencies, 0)

SELECT @AttemptResult = ResultCode, @AttemptDate = AttemptDate, @AttemptRSN = AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 20010 /*No Show at Inspection*/
BEGIN

/* No Show at Inspection */
/* Insert re-inspection fee: Get the Number of Non-Complied Units, then get Reinspection Fee multiplier, then multiply, then insert fee */

    /* Get Number of Non-complied Units from Process Info field (30001) */
    --SELECT @intNonCompliedUnits = ISNULL(InfoValueNumeric, 0) FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30001

    /* Always use 1 as number of non-complied units for no-shows at first inspection */
    SET @intNonCompliedUnits = 1

    /* Get fee multiplier from ValidLookup table. Lookup code = 9 for reinspection fees */ 
    SELECT @dblFeeMultiplier = LookupFee FROM ValidLookup WHERE LookupCode = 9 AND Lookup1 = 1 AND Lookup2 = 1

    /* Reinspection Fee = FeeMultiplier * Number of Non-complied Units */
    SET @dblFeeAmount = @dblFeeMultiplier * @intNonCompliedUnits
    SET @FeeComment = 'No-show at Inspection'
			
    EXEC PC_FEE_INSERT @FolderRSN, 231, @dblFeeAmount, @UserID, 1, @FeeComment, 1, 1

    /*Insert reinspection fees*/
    SET @strMessage = 'No Show at Inspection. Charged Reinspection Fee of ' + CAST(@dblFeeAmount AS VARCHAR(20)) + ' for ' + CAST(@intNonCompliedUnits AS VARCHAR(10)) + ' Non-Complied Units'

    EXEC usp_UpdateFolderCondition @FolderRSN, @strMessage

    /*Reopen process*/
    UPDATE FolderProcess
    SET StatusCode = 1, 
    SignOffUser = Null, 
    EndDate = Null
    WHERE ProcessRSN = @ProcessRSN

END


IF @AttemptResult = 20046 /*Found in Compliance*/
BEGIN
    IF @intDeficiencies > 0
        BEGIN
             /*CANT MARK COMPLY WITH DEFICIENCIES*/
             RAISERROR('Error!   Deficiencies must be marked as Complied', 16, -1)
        END
    ELSE
        BEGIN
          Update Folder
          SET WorkCode = 20074, /*Compliance PW to Admin*/
          FinalDate = GetDate()
          WHERE FolderRSN = @FolderRSN 

          EXEC usp_UpdateFolderCondition @FolderRSN, 'Inspection Complete, Found in Compliance'

          UPDATE FolderProcess 
          SET ProcessComment = 'Found in Compliance'
          WHERE ProcessRSN = @ProcessRSN

          /* Administrative Routine, Administration */           
          SELECT @NextProcessRSN = @NextProcessRSN + 1

          INSERT INTO FolderProcess 
          ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
          PrintFlag, StatusCode, StampDate, StampUser, 
          ScheduleDate, ScheduleEndDate ) 
          VALUES ( @NextProcessRSN, @FolderRSN, 20032, 90, 
          'Y', 1, getdate(), @UserId, 
          @AttemptDate, @AttemptDate) 
    END
END 

IF @AttemptResult = 20047 --Deficiencies Found 
BEGIN
/*Check to make sure there are actually deficiencies in this process*/
   IF @intDeficiencies = 0
		BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('You must insert deficiencies before attempt result', 16, -1)
		RETURN
       END
   ELSE
       BEGIN
			--RAISERROR('Processing deficiencies', 16, -1)
			UPDATE Folder
			SET WorkCode = 20072 /*Routine Order to Admin*/,
			ExpiryDate = DateAdd(D, 35, @AttemptDate)
			WHERE FolderRSN = @FolderRSN

			EXEC usp_UpdateFolderCondition @FolderRSN, 'Deficiencies Found'
			UPDATE FolderProcess 
			SET ProcessComment = 'Deficiencies Found'
			WHERE ProcessRSN = @ProcessRSN

			UPDATE FolderProcessDeficiency
			SET ComplyByDate = DateAdd(D, 35, @AttemptDate)
			WHERE ProcessRSN = @ProcessRSN 
			AND ComplyByDate IS NULL 

			SELECT @Inspector = IssueUser 
			FROM Folder
			WHERE FolderRSN = @FolderRSN 

			/* First Follow-up Inspection, Inspections */ 
			SELECT @NextProcessRSN = @NextProcessRSN + 1 
			INSERT INTO FolderProcess 
			(ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
			PrintFlag, StatusCode, StampDate, StampUser, AssignedUser)
			VALUES ( @NextProcessRSN, @FolderRSN, 20034, 90, 
			'Y', 1, getdate(), @UserId, @Inspector) 

			/* Insert Process Info fields for Code Units Inspected (20001) and Code Non-complied Units (30001) */
			IF NOT EXISTS (Select ProcessRSN FROM FolderProcessInfo WHERE ProcessRSN = @NextProcessRSN AND InfoCode = 20001)
			BEGIN
				INSERT INTO FolderProcessInfo 
				(ProcessRSN, FolderRSN, InfoCode, StampDate, StampUser) 
				VALUES (@NextProcessRSN, @FolderRSN, 20001, getdate(), @UserId) 
			END
			/* Insert Process Info fields for Code Units Inspected (20001) and Code Non-complied Units (30001) */
			IF NOT EXISTS (Select ProcessRSN FROM FolderProcessInfo WHERE ProcessRSN = @NextProcessRSN AND InfoCode = 30001)
			BEGIN
				INSERT INTO FolderProcessInfo 
				(ProcessRSN, FolderRSN, InfoCode, StampDate, StampUser) 
				VALUES (@NextProcessRSN, @FolderRSN, 30001, getdate(), @UserId) 
			END

			/* Copy Deficiency from Routine to 1st Follow-Up*/
			INSERT INTO FolderProcessDeficiency
			(ProcessRSN, DeficiencyCode, FolderRSN, DeficiencyText, RemedyText, AssignedUser, StatusCode, SeverityCode, 
			ComplyByDate, OccuranceCount, InsertDate, StampDate, StampUser, DateComplied, SubLocationDesc, ActionCode, ReferenceNum,
			LocationDesc)
			SELECT @NextProcessRSN, DeficiencyCode, FolderRSN, DeficiencyText, RemedyText, AssignedUser, StatusCode, SeverityCode, 
			ComplyByDate, OccuranceCount, InsertDate, StampDate, StampUser, DateComplied, SubLocationDesc, ActionCode, ReferenceNum,
			LocationDesc
			FROM FolderProcessDeficiency
			WHERE ProcessRSN = @ProcessRSN 

			/* Administrative Routine, Administration */ 
			SELECT @NextProcessRSN = @NextProcessRSN + 1 
			INSERT INTO FolderProcess 
			(ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
			PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
			ScheduleDate, ScheduleEndDate ) 
			VALUES (@NextProcessRSN, @FolderRSN, 20032, 90, 
			'Y', 1, getdate(), @UserId, @MHAdminUser, 
			@AttemptDate, @AttemptDate)
		END
END 


IF @AttemptResult = 20150 /*Routine Schedule*/
BEGIN
    IF @ScheduleDate IS NULL
    BEGIN
        RAISERROR('Schedule date must be entered', 16, -1)
        ROLLBACK TRANSACTION
    END

    SELECT @Inspector = IssueUser 
    FROM Folder
    WHERE FolderRSN = @FolderRSN 

    SELECT @ScheduleEndDate = DATEADD(n, dbo.udf_GetInspectionTime(@RentalUnits, 1 /* Inspection # */) * 15, @ScheduleDate)

    UPDATE FolderProcess
    SET ScheduleEndDate = @ScheduleEndDate 
    WHERE ProcessRSN = @ProcessRSN

    SELECT @strScheduledDate = dbo.FormatDateTime(@ScheduleDate, 'MM/DD/YYYY HH:MM 12')

    SET @strScheduledDate = 'Inspection Re-Scheduled for ' + @strScheduledDate

    EXEC usp_UpdateFolderCondition @FolderRSN, @strScheduledDate

    COMMIT TRANSACTION
    BEGIN TRANSACTION

    EXEC @intCOMReturnValue = xspScheduleCodeEnforcementInspection @FolderRSN, @ProcessRSN, @AttemptRSN, 1
    IF @intCOMReturnValue > 0
     BEGIN
          RAISERROR('Failed to create calendar item', 16, -1)
        END

    EXEC @intCOMReturnValue = xspSendInspectionWorkOrder @UserId, @FolderRSN, @ProcessRSN, 1, 1, 20
    IF @intCOMReturnValue > 0
        BEGIN
            RAISERROR('Failed to create send workdorder', 16, -1)
        END

    /*Reopen process*/
    UPDATE FolderProcess
    SET StatusCode = 1, 
    SignOffUser = Null, 
    EndDate = Null
    WHERE ProcessRSN = @ProcessRSN
END


GO
