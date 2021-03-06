USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010018]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010018]
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
   
/* Appeal Clock (10018) version 2 */

/* Used for appellant actions that effect folder clocks. The statutory clock starts 
   when the appeal is received. There is no complete/incomplete trigger authorized 
   in the 2008 ordinance as with permit applications. */
/* Added for DRB appeals only, but is functional for other appeal bodies. */
/* Version 2 incorporates functions. */
/* Withdraw Permit attempt result added Sep 6, 2012. */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @NextStatusCode int
DECLARE @InDate datetime
DECLARE @ExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @FolderCondition varchar(2000)
DECLARE @APDRBProcess int
DECLARE @APVECProcess int
DECLARE @AppealDecisionProcessCode int
DECLARE @DecisionProcessCode int
DECLARE @DecisionProcess int
DECLARE @PermitDecision int
DECLARE @PreReleaseCondStatus int
DECLARE @PermitPickedUp varchar(3)
DECLARE @ClockStatusScheduler varchar(12)
DECLARE @ProcessComment varchar(80)

/* Get Attempt Result, Folder Status, In Date, Appeal Period expiration date, Conditions */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode, 
       @AttemptDate = FolderProcessAttempt.AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType,
       @FolderStatus = Folder.StatusCode, 
       @InDate = Folder.InDate,
       @ExpiryDate = Folder.ExpiryDate,
       @SubCode = Folder.SubCode, 
       @WorkCode = Folder.WorkCode, 
       @FolderCondition = Folder.FolderCondition
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @ClockStatusScheduler  = ISNULL(FolderClock.Status, 'Not Started')
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

/* Check for existence of Appeal to DRB and Appeal to VEC processes. */

SELECT @APDRBProcess = COUNT(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10002               /* Appeal to DRB */

SELECT @APVECProcess = COUNT(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10003               /* Appeal to VEC */

IF @APVECProcess > 0 SELECT @AppealDecisionProcessCode = 10003
ELSE SELECT @AppealDecisionProcessCode = 10002

/* Check for decision process existence; get decision process code, 
   Pre-Release Conditions process status, Permit Picked Up Info value. */ 

SELECT @DecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@FolderRSN)

SELECT @DecisionProcess = COUNT(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = @DecisionProcessCode

SELECT @PreReleaseCondStatus = ISNULL(FolderProcess.StatusCode,0)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10006     

SELECT @PermitPickedUp = UPPER(FolderInfo.InfoValue)
  FROM FolderInfo
 WHERE FolderInfo.InfoCode = 10023
   AND FolderInfo.FolderRSN = @FolderRSN

/* If the Folder.FolderCondition is null, i.e. Review Path has not been run, record when 
   the application was accepted. */

IF @FolderCondition IS NULL AND @FolderType = 'ZL' 
BEGIN
   UPDATE Folder
      SET Folder.FolderCondition = 'Appeal Received ('+ CONVERT(char(11), @InDate) + ')'
    WHERE Folder.FolderRSN = @FolderRSN
END

/* Staff has requested additional information from the appellant. */

IF @AttemptResult = 10014             /* Waiting for Appellant Info */
BEGIN
	IF @FolderStatus IN(10009, 10017, 10021)    /* Appealed to DRB, Appeal to VEC, Appeal Postponed */
	BEGIN
		SELECT @ProcessComment = 'More Info Requested for Appeal'
	
		UPDATE Folder
		SET Folder.StatusCode = 10020, 
			Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> ' + @ProcessComment + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
		WHERE Folder.FolderRSN = @FolderRSN

		IF @ClockStatusScheduler = 'Running'
		BEGIN
			UPDATE FolderClock
			SET FolderClock.Status = 'Paused' 
			WHERE FolderClock.FolderRSN = @FolderRSN
			AND FolderClock.FolderClock = 'Scheduler'
		END

		UPDATE FolderProcess
		SET FolderProcess.ProcessComment = @ProcessComment
		WHERE FolderProcess.FolderRSN = @FolderRSN
		AND FolderProcess.ProcessRSN = @ProcessRSN 
   END
END     /* End of Attempt Result 10014 */

/* Appellant postpones review and stops the clock. */

IF @AttemptResult = 10026             /* Postpone Request */
BEGIN
	SELECT @ProcessComment = 'Appeal Postponed'
	
	IF @FolderStatus IN(10009, 10017, 10020)       /* Appealed to DRB, Appealed to VEC, Appeal Waiting */
	BEGIN
		UPDATE Folder
		SET Folder.StatusCode = 10021, 
			Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> ' + @ProcessComment + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
		WHERE Folder.FolderRSN = @FolderRSN

		IF @ClockStatusScheduler = 'Running'
		BEGIN
			UPDATE FolderClock
			SET FolderClock.Status = 'Paused' 
			WHERE FolderClock.FolderRSN = @FolderRSN
			AND FolderClock.FolderClock = 'Scheduler'
		END

		UPDATE FolderProcess
		SET FolderProcess.ProcessComment = @ProcessComment
		WHERE FolderProcess.FolderRSN = @FolderRSN
		AND FolderProcess.ProcessRSN = @ProcessRSN 
	END
END     /* End of Attempt Result 10026 */

/* Appellant is ready, and restarts review or appeal. */

IF @AttemptResult = 10027                    /* Restart Clock */
BEGIN
	IF @APVECProcess > 0 SELECT @NextStatusCode = 10017 
	ELSE SELECT @NextStatusCode = 10009 
	SELECT @ProcessComment = 'Restarted Appeal'

	IF @FolderStatus IN(10020, 10021)           /* Appeal Waiting, Appeal Postponed */
	BEGIN
		UPDATE Folder
		SET Folder.StatusCode = @NextStatusCode, 
			Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> ' + @ProcessComment + ' (' + CONVERT(char(11), @AttemptDate) + ')' ))
		WHERE Folder.FolderRSN = @FolderRSN

		IF @ClockStatusScheduler = 'Paused'
		BEGIN
			UPDATE FolderClock
			SET FolderClock.Status = 'Running', 
				FolderClock.StartDate = getdate() 
			WHERE FolderClock.FolderRSN = @FolderRSN
			AND FolderClock.FolderClock = 'Scheduler'
		END

		UPDATE FolderProcess
		SET FolderProcess.ProcessComment = @ProcessComment
		WHERE FolderProcess.FolderRSN = @FolderRSN
		AND FolderProcess.ProcessRSN = @ProcessRSN 
	END
END     /* End of Attempt Result 10027 */

/* Appellant withdraws appeal (10004), or Appeal Incomplete (10075). */

IF @AttemptResult IN (10004, 10075)     /* Withdraw Appeal, Appeal Incomplete */
BEGIN
	IF @AttemptResult = 10004 SELECT @ProcessComment = 'Appeal Withdrawn'
	IF @AttemptResult = 10075 SELECT @ProcessComment = 'Appeal Incomplete and Deemed Invalid'

	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = @ProcessComment
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessRSN = @ProcessRSN 

	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 2, FolderProcess.ProcessComment = NULL
        WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessCode IN (10002, 10003)  /* Appeal to DRB and VEC */
	AND FolderProcess.StatusCode = 1

	IF @ExpiryDate > getdate()          /* In appeal period - open Initiate Appeal */
	BEGIN
		UPDATE FolderProcess
		SET FolderProcess.StatusCode = 1, FolderProcess.ProcessComment = NULL, 
			FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
			FolderProcess.ScheduleDate = getdate(), 
			FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
		WHERE FolderProcess.FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = 10008       /* Initiate Appeal */
	END

	IF @FolderType = 'ZL'      /* End of ZL Folder lifecycle */
	BEGIN
		UPDATE Folder
		SET Folder.StatusCode = 10010, 
			Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> ' + @ProcessComment + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
		WHERE Folder.FolderRSN = @FolderRSN

		UPDATE FolderProcess
		SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate(), 
			FolderProcess.ScheduleDate = null
		WHERE FolderProcess.FolderRSN = @FolderRSN
		AND FolderProcess.StatusCode = 1

		UPDATE FolderProcess
		SET FolderProcess.StartDate = @InDate, FolderProcess.EndDate = getdate()
		WHERE FolderProcess.FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = 10002      /* Appeal to DRB */
	END
	ELSE                /* Other FolderTypes */
	BEGIN
		SELECT @PermitDecision = dbo.udf_GetZoningDecisionAttemptCode(@FolderRSN)
		SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @PermitDecision)

		UPDATE Folder
		SET Folder.StatusCode = @NextStatusCode, 
			Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> ' + @ProcessComment + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
		WHERE Folder.FolderRSN = @FolderRSN

		IF @ExpiryDate < getdate()          /* Appeal Period is over */
		BEGIN
			SELECT @NextStatusCode = dbo.udf_ZoningAppealPeriodEndFolderStatus(@FolderRSN)

			UPDATE Folder
			SET Folder.StatusCode = @NextStatusCode 
			WHERE Folder.FolderRSN = @FolderRSN
		END
	END       /* End of other FolderTypes */
END          /* End of Attempt Result 10004 */

/* Applicant pulls the plug on the permit, thus pulling the rug out from underneath 
   the appellants. */

IF @AttemptResult = 10078                    /* Withdraw Permit */
BEGIN
	SELECT @NextStatusCode = 10010 
	SELECT @ProcessComment = 'Applicant Withdrew Permit and Ends Appeal'

	UPDATE Folder
	SET Folder.StatusCode = @NextStatusCode, 
		Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> ' + @ProcessComment + ' (' + CONVERT(char(11), @AttemptDate) + ')' ))
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = @ProcessComment
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessRSN = @ProcessRSN 

	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 2 
        WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.StatusCode = 1
END

/* Stop clocks */

IF @AttemptResult IN (10004, 10075, 10078)
BEGIN
	UPDATE FolderClock
	SET FolderClock.Status = 'Stopped' 
	WHERE FolderClock.FolderRSN = @FolderRSN
	AND FolderClock.FolderClock = 'Scheduler'

        UPDATE FolderClock
        SET FolderClock.Status = 'Stopped'
        WHERE FolderClock.FolderRSN = @FolderRSN
        AND FolderClock.FolderClock = 'Appeal Fdngs'
        AND FolderClock.Status = 'Running'
END


/* Update Project Manager Info field */

IF @AttemptResult = 10004 
	EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Re-open process for all attempt results, except Withdraw Appeal (10004)
   Appeal Incomplete (10075), and Withdraw Permit (10078). */

IF @AttemptResult NOT IN (10004, 10075, 10078)
BEGIN
	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 1, 
		FolderProcess.ScheduleDate = getdate(),
		FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
		FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL
	WHERE FolderProcess.ProcessRSN = @ProcessRSN
	AND FolderProcess.FolderRSN = @FolderRSN
END

GO
