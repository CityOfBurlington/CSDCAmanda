USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_MH_00020034]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_MH_00020034]
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
MH First FU Inspection ProcessCode 20034
DefaultProcess_MH_00020034
*/

DECLARE @AttemptResult int
DECLARE @AttemptDate DateTime
DECLARE @Inspector varchar(10) 
DECLARE @MHAdminUser Varchar(30)
DECLARE @intCOMReturnValue  INT
DECLARE @AttemptCount int
DECLARE @AttemptRSN int
DECLARE @intDeficiencies INT
DECLARE @Is_First_FU_Scheduled INT
DECLARE @Is_AdminRoutine_Open INT

DECLARE @Is_SelfCertOnly INT

DECLARE @ScheduleDate DATETIME
DECLARE @ScheduleEndDate DATETIME

DECLARE @strScheduledDate VARCHAR(100)
DECLARE @InfoValue INT
DECLARE @RentalUnits INT
DECLARE @InspectedUnits INT
DECLARE @strMessage VARCHAR(400)
DECLARE @intNonCompliedUnits INT
DECLARE @dblFeeAmount MONEY
DECLARE @intNextAccountBillFeeRSN INT
DECLARE @dblFeeMultiplier MONEY
DECLARE @FeeComment VARCHAR(35)

SELECT @RentalUnits = CAST(dbo.f_info_numeric_property(PropertyRSN, 15) AS INT)
FROM Folder 
WHERE FolderRSN = @FolderRSN

SET @InspectedUnits = ISNULL(dbo.f_info_numeric_process(@ProcessRSN, 20001),0)
IF @InspectedUnits = 0
BEGIN
     RAISERROR('Number of Units Inspected must be entered', 16, -1)
END


SELECT @Is_AdminRoutine_Open = StatusCode - 1 /*1=Open 2=Closed*/
FROM FolderProcess
WHERE FolderRSN = @FolderRSN
AND ProcessCode = 20032 /*Admin Routine*/

SET @Is_AdminRoutine_Open = ISNULL(@Is_AdminRoutine_Open, 0)

SELECT @ScheduleDate = ScheduleDate
FROM FolderProcess
WHERE ProcessRSN = @ProcessRSN

SELECT @Is_First_FU_Scheduled = SUM(1)
FROM FolderProcessAttempt 
WHERE ResultCode = 20076 /*1st F/U Insp Scheduled*/
AND FolderRSN = @FolderRSN

SET @Is_First_FU_Scheduled = ISNULL(@Is_First_FU_Scheduled, 0)

DECLARE @Is_Self_Cert INT

SELECT @Is_Self_Cert = SUM(1)
FROM FolderProcessAttempt
WHERE FolderRSN = @FolderRSN
AND ResultCode = 20133 /*Routine Order w/Self Cert*/

IF ISNULL(@Is_Self_Cert, 0) > 0
     BEGIN
     SET @Is_First_FU_Scheduled = 1
END

SELECT @intDeficiencies = SUM(1)
FROM FolderProcessDeficiency
WHERE FolderRSN = @FolderRSN
AND ProcessRSN = @ProcessRSN
AND StatusCode = 1 /*Non-Complied*/

SET @intDeficiencies = ISNULL(@intDeficiencies, 0)
IF @intDeficiencies > 0
BEGIN
    IF NOT EXISTS(SELECT InfoValue FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30001)
    BEGIN
	RAISERROR('Number of Non-complied Units must be entered', 16, -1)
	RETURN
    END
END

SELECT @Is_SelfCertOnly = SUM(1)
FROM FolderProcessDeficiency
WHERE FolderRSN = @FolderRSN
AND ProcessRSN = @ProcessRSN
AND StatusCode = 6 /*Self Cert*/

SET @Is_SelfCertOnly = ISNULL(@Is_SelfCertOnly, 0)

IF @Is_SelfCertOnly = @intDeficiencies
    SET @Is_SelfCertOnly = 1
ELSE
    SET @Is_SelfCertOnly = 0

SET @AttemptCount = 2 /*1st FU aka 2nd Inspection*/

SELECT TOP 1 @MHAdminUser = dbo.f_info_alpha(FolderRSN, 30141) /*MH Admin Process User*/
FROM Folder
WHERE FolderType = 'AA'
ORDER BY FolderRSN DESC

SELECT @AttemptResult = ResultCode, 
@AttemptDate = AttemptDate,
@AttemptRSN = AttemptRSN
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
        SELECT @intNonCompliedUnits = ISNULL(InfoValueNumeric, 0) FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30001

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

IF @AttemptResult = 20076 /*First FU Scheduled*/
    BEGIN

		IF @ScheduleDate IS NULL
		BEGIN
			RAISERROR('Schedule date must be entered', 16, -1)
		END

		SELECT @ScheduleEndDate = DATEADD(n, dbo.udf_GetInspectionTime(@RentalUnits, 2/* Inspection # */) * 15, @ScheduleDate)
		UPDATE FolderProcess SET ScheduleEndDate = @ScheduleEndDate WHERE ProcessRSN = @ProcessRSN

		SELECT @strScheduledDate = dbo.FormatDateTime(@ScheduleDate, 'MM/DD/YYYY HH:MM 12')
		SET @strScheduledDate = '1st F/U Inspection Scheduled for ' + @strScheduledDate

		EXEC usp_UpdateFolderCondition @FolderRSN, @strScheduledDate

		UPDATE FolderProcess
		SET ProcessComment = '1st F/U Scheduled'
		WHERE ProcessRSN = @ProcessRSN

		UPDATE Folder
		SET WorkCode = 20084 /*First FU Scheduled*/
		WHERE FolderRSN = @FolderRSN

		COMMIT TRANSACTION
		BEGIN TRANSACTION

		EXEC @intCOMReturnValue = xspScheduleCodeEnforcementInspection @FolderRSN, @ProcessRSN, @AttemptRSN, 2
		IF @intCOMReturnValue > 0
		BEGIN
			RAISERROR('Failed to create calendar item', 16, -1)
		END

		EXEC @intCOMReturnValue = xspSendInspectionWorkOrder @UserId, @FolderRSN, @ProcessRSN, @AttemptRSN, @AttemptCount, 20
		IF @intCOMReturnValue > 0
		BEGIN
			RAISERROR('Failed to send workdorder', 16, -1)
		END

		/*Reopen process*/
		UPDATE FolderProcess
		SET StatusCode = 1, 
		SignOffUser = Null, 
		EndDate = Null
		WHERE ProcessRSN = @ProcessRSN

		IF @intCOMReturnValue > 0
			BEGIN
			RAISERROR('Failed to create workorder calendar item', 16, -1)
		END
	END

IF @AttemptResult = 20046 /*Found in Compliance*/
    BEGIN
		IF @intDeficiencies > 0
			BEGIN
		  /*CANT MARK COMPLY WITH DEFICIENCIES*/
				 RAISERROR('Error!   Deficiencies must be marked as Complied', 16, -1)
			END
		ELSE
			IF @Is_AdminRoutine_Open = 0
				BEGIN
					/*CANT COMPLY WITHOUT ADMIN ROUTINE*/
					RAISERROR('Error!  Admin Routine Process Must be Closed', 16, -1)
				END
			ELSE
                BEGIN
                    IF @Is_First_FU_Scheduled = 0 AND @Is_SelfCertOnly = 0
                        BEGIN
                             /*CANT COMPLY WITHOUT A FU SCHEDULED*/
							RAISERROR('Error!   Follow-Up Inspection was not scheduled', 16, -1)
						END
				ELSE
                    BEGIN
                        UPDATE Folder
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
						PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
						ScheduleDate, ScheduleEndDate ) 
						VALUES ( @NextProcessRSN, @FolderRSN, 20036, 90, 
						'Y', 1, getdate(), @UserId, @MHAdminUser, 
						@AttemptDate, @AttemptDate) 
                    END
				END

	END 

IF @AttemptResult = 20075 /*Continued Violations*/
BEGIN
    IF @Is_First_FU_Scheduled = 0 
	BEGIN        
        /*CANT COMPLY WITHOUT A FU SCHEDULED*/
		RAISERROR('Error!   Follow-Up Inspection was not scheduled', 16, -1)
	END
    ELSE
		IF @Is_AdminRoutine_Open = 0
		BEGIN
            /*CANT COMPLY WITHOUT ADMIN ROUTINE*/
			RAISERROR('Error!  Admin Routine Process Must be Closed', 16, -1)
		END
        ELSE
		BEGIN

            UPDATE Folder
            SET WorkCode = 21007 /*Continued Violation 1st FU*/,
            ExpiryDate = DateAdd(D, 35, @AttemptDate)
            WHERE FolderRSN = @FolderRSN 

            EXEC usp_UpdateFolderCondition @FolderRSN, 'Continued Deficiencies Found During 1st F/U'

            UPDATE FolderProcess
            SET ProcessComment = 'Continued Deficiencies'
            WHERE ProcessRSN = @ProcessRSN

            SELECT @Inspector = IssueUser 
            FROM Folder
            WHERE FolderRSN = @FolderRSN

	    /* Get Number of Non-complied Units from Process Info field (30001) */
            SELECT @intNonCompliedUnits = ISNULL(InfoValueNumeric, 0)
              FROM FolderProcessInfo 
              WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30001

	    /* Get fee multiplier from ValidLookup table. Lookup code = 9 for reinspection fees */ 
	    SELECT @dblFeeMultiplier = LookupFee FROM ValidLookup WHERE LookupCode = 9 AND Lookup1 = 1 AND Lookup2 = 1

	    /* Reinspection Fee = FeeMultiplier * Number of Non-complied Units */
	    SET @dblFeeAmount = @dblFeeMultiplier * @intNonCompliedUnits
	    SET @FeeComment = 'First Follow-Up Inspection'
			
	    EXEC PC_FEE_INSERT @FolderRSN, 231, @dblFeeAmount, @UserID, 1, @FeeComment, 1, 1

            /*Insert reinspection fees*/
            SET @strMessage = 'Reinspection Fee ' + CAST(@dblFeeAmount AS VARCHAR(20)) + ' Charged for ' + CAST(@intNonCompliedUnits AS VARCHAR(10)) + ' Non-Complied Units'

            EXEC usp_UpdateFolderCondition @FolderRSN, @strMessage

            /* Second Follow-up Inspection, Inspections */ 
            SET @NextProcessRSN = @NextProcessRSN + 1

            INSERT INTO FolderProcess 
            (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
            PrintFlag, StatusCode, StampDate, StampUser, AssignedUser)
            VALUES ( @NextProcessRSN, @FolderRSN, 20037, 90, 
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

           /* Copy Deficiency from Routine to 2nd Follow-Up*/
            INSERT INTO FolderProcessDeficiency
            (ProcessRSN, DeficiencyCode, FolderRSN, DeficiencyText, RemedyText, AssignedUser, StatusCode, SeverityCode, 
            ComplyByDate, OccuranceCount, InsertDate, StampDate, StampUser, DateComplied, SubLocationDesc, ActionCode, ReferenceNum,
            LocationDesc)
            SELECT @NextProcessRSN, DeficiencyCode, FolderRSN, DeficiencyText, RemedyText, AssignedUser, StatusCode, SeverityCode, 
			ComplyByDate, OccuranceCount, InsertDate, StampDate, StampUser, DateComplied, SubLocationDesc, ActionCode, ReferenceNum,
            LocationDesc
            FROM FolderProcessDeficiency
			WHERE ProcessRSN = @ProcessRSN 

            UPDATE FolderProcessDeficiency
            SET ComplyByDate = DateAdd(D, 35, @AttemptDate)
           WHERE ProcessRSN = @NextProcessRSN
            AND ComplyByDate = NULL

            /* Administrative Routine, Administration */ 
            SELECT @NextProcessRSN = @NextProcessRSN + 1 

            INSERT INTO FolderProcess
            (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
            PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
			ScheduleDate, ScheduleEndDate ) 
            VALUES (@NextProcessRSN, @FolderRSN, 20036, 90, 
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

    SELECT @ScheduleEndDate = DATEADD(n, dbo.udf_GetInspectionTime(@RentalUnits, 2/* Inspection # */) * 15, @ScheduleDate)

    UPDATE FolderProcess
    SET ScheduleEndDate = @ScheduleEndDate 
    WHERE ProcessRSN = @ProcessRSN

    SELECT @strScheduledDate = dbo.FormatDateTime(@ScheduleDate, 'MM/DD/YYYY HH:MM 12')

    SET @strScheduledDate = '1st F/U Inspection Re-Scheduled for ' + @strScheduledDate

    EXEC usp_UpdateFolderCondition @FolderRSN, @strScheduledDate

    COMMIT TRANSACTION
    BEGIN TRANSACTION

    EXEC @intCOMReturnValue = xspScheduleCodeEnforcementInspection @FolderRSN, @ProcessRSN, @AttemptRSN, 2

    IF @intCOMReturnValue > 0
        BEGIN
            RAISERROR('Failed to create workorder calendar item', 16, -1)
        END

    /*Reopen process*/
    UPDATE FolderProcess
    SET StatusCode = 1, 
    SignOffUser = Null, 
    EndDate = Null
    WHERE ProcessRSN = @ProcessRSN
END

GO
