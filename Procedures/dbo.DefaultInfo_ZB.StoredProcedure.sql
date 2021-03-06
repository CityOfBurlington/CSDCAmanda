USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_ZB]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[DefaultInfo_ZB]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

/* Info Validation */
/* Call this with: EXECUTE DefaultInfo_ZB @FolderRSN, @UserID, @InfoCode */

/* Declare variables that are used by more than one Info field */

DECLARE @FolderStatus int
DECLARE @FolderType varchar(2)
DECLARE @InDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @DRBMeetingDateTime datetime
DECLARE @DRBDelibMeetingDateTime datetime
DECLARE @DABMeetingDateTime datetime
DECLARE @NextProcessRSN int
DECLARE @DRBFindingsClock int
DECLARE @AppealFindingsClock int
DECLARE @SchedulerClock int

SELECT @FolderType = Folder.FolderType,
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @DecisionDate = Folder.IssueDate,
       @ExpiryDate = Folder.ExpiryDate, 
       @SubCode = Folder.SubCode, 
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @DRBFindingsClock = COUNT(*)
 FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'DRB Findings'

SELECT @AppealFindingsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Appeal Fdngs'

SELECT @SchedulerClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'
   
/******************************************************************************/

/* Add current time to date fields that are or may be hand-entered: 

	DRB Meeting Date (10001)
	DAB Board Meeting Date (10003)
	CB Board Meeting Date (10007)
	DRB Public Hearing Closed Date (10009)
	DRB Deliberative Meeting Date (10017)
	Permit Expiration Date (10024)
	Other State/Federal Decision Date (10028)
	VSCED Appeal Decision Date (10038)
	DRB Decision Date (10049)
	COA Decision Date - Historic Permits (10052) 
	Administrative Decision Date (10055)
	DRB Appeal Decision Date (10056) 
	VSCED Appeal Decision Date (10057) 
	TCO Decision Date (10071) 
	FCO Decision Date (10073) 
	Supreme Court Appeal Decision Date (10080) 
	Construction Start Deadline (10127)
*/

IF @InfoCode IN (10001, 10003, 10007, 10009, 10017, 10024, 10028, 10038, 10049, 10052, 10055, 10056, 10057, 10071, 10073, 10080, 10127)
	EXECUTE dbo.usp_Zoning_FolderInfo_Add_Time @FolderRSN, @InfoCode

/******************************************************************************/

/* Permit Picked Up (10023) - Permit pick up is a watershed step in zoning permit processing. 
   Perform checks, set Folder.StatusCode, write to log, set up for Phased CO processing if 
   applicable, and insert a BP folder where appropriate. */

IF @InfoCode = 10023
BEGIN
	DECLARE @intExpiryYD int
	DECLARE @intCurrentYD int
	DECLARE @intDepartmentCode int
	DECLARE @intAppealPeriodWaived int
	DECLARE @varPickedUpValue varchar(10)
	
	SET @varPickedUpValue = 'NO'

	SELECT @varPickedUpValue = ISNULL(FolderInfo.InfoValueUpper, 'NO') 
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = @InfoCode 
	
	/* The variables @intExpiryYD and @intCurrentYD are integer treatments of dates to 
	   allow release of permits on the final day of their appeal periods after 4 pm. */

	SELECT @intExpiryYD  = ( (DATEPART(year,   @ExpiryDate) * 100000) +
							 (DATEPART(dayofyear, @ExpiryDate) * 100) + 16 )

	SELECT @intCurrentYD = ( (DATEPART(year, getdate())   * 100000) +
							 (DATEPART(dayofyear, getdate()) * 100) +
							 (DATEPART(hour, getdate())) )

	/* Perform checks */
	
	SELECT @intDepartmentCode = ValidUser.DepartmentCode
	FROM ValidUser
	WHERE ValidUser.UserID = @UserID

	IF @intDepartmentCode NOT IN (0, 7)     /* Admin, Planning and Zoning */
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Only Planning and Zoning staff may release permits. So sorry.', 16,-1)
		RETURN
	END

	IF @FolderStatus IN (10004, 10018)    /* Check for Pre-Release conditions */
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Permit is Not Ready to Release until Pre-Release Conditions are Met',16,-1)
		RETURN
	END
		
	SELECT @intAppealPeriodWaived = dbo.udf_GetLastAttemptResultCode (@FolderRSN, 10028)   /* Waive Right to Appeal */

	IF ( @intAppealPeriodWaived <> 10058 AND @FolderStatus NOT IN (10005, 10029) AND 
		 @intCurrentYD < @intExpiryYD AND @varPickedUpValue <> 'NO' )
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Permit is Not Ready to Release. Change entry back to "No", or exit without Saving.', 16,-1)
		RETURN
	END

	/* Below checks discontinued so can relaease old permits.  18-NOV-11 

	IF @intFolderStatus = 10049   /* Permit Indeterminate 1 */
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('The one-year time limit to start construction has passed: Permit can not be released.',16,-1)
		RETURN
	END

	IF @intFolderStatus IN (10029, 10048)   /* Permit Indeterminate 2 and 3 */
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Permit has expired and is invalid. It can not be released.',16,-1)
		RETURN
	END  */ 

	IF @varPickedUpValue IN ('MAILED', 'YES')
	BEGIN 
		/* Update Folder.StatusCode and write log to FolderConditions */
		EXECUTE dbo.usp_Zoning_Permit_Picked_Up @FolderRSN, @UserID
		
		/* Set up for Phased CO processing: Procedure does the setup only when 
		   Folder.StatusCode is Released (10006) or Project Phasing (10047). */
		EXECUTE dbo.usp_Zoning_Insert_Phased_CO_Processes @FolderRSN, @UserID

		/* Insert child BP folder when applicable */
		EXECUTE dbo.usp_Zoning_Insert_BP_Folder @FolderRSN, @UserID 
	END
END 

/******************************************************************************/

/* Project Type (COA 3) (10015) */

/* Completes the Project Number entry (Folder.ReferenceFile) */

IF @InfoCode = 10015
BEGIN

   DECLARE @varZ3ProjectType varchar(50)
   DECLARE @varPermitTypeAbbrev varchar(10)
   DECLARE @varProjectNumber varchar(15)

  SELECT @varProjectNumber = SUBSTRING(Folder.ReferenceFile, 1, 7)
    FROM Folder
   WHERE Folder.FolderRSN = @FolderRSN

   SELECT @varZ3ProjectType = ISNULL(FolderInfo.InfoValueUpper, 'NONE') 
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   SELECT @varPermitTypeAbbrev = 
   CASE @varZ3ProjectType 
      WHEN 'LOT LINE ADJUSTMENT' THEN 'LL'
      WHEN 'LOT MERGER' THEN 'LL'
      WHEN 'PLANNED UNIT DEVELOPMENT' THEN 'PD'
      WHEN 'SUBDIVISION' THEN 'SD'
      WHEN 'NONE' THEN '??'
   END

   UPDATE Folder
      SET Folder.ReferenceFile = @varProjectNumber + @varPermitTypeAbbrev
    WHERE Folder.FolderRSN = @FolderRSN
END

/******************************************************************************/

/* DRB Board Meeting Date */

/* For Sketch Plan (ZS) folders, set the Folder.IssueDate to be the meeting date, 
   and Folder.ExpiryDate to be the meeting date plus one day. Then the daily 
   procedure will close ZS folders after the expiry date has passed. */

IF @InfoCode = 10001
BEGIN
   DECLARE @InitiateAppealAttemptResult int
   DECLARE @SchedulerClockStartDate datetime
   DECLARE @DayDiff int

   SELECT @DRBMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   IF @FolderStatus IN(10009, 10020, 10021)     /* Appeal to DRB statuses */
   BEGIN
      UPDATE Folder
         SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),ISNULL(foldercondition,''))) + ' -> Appeal Scheduled for DRB on ' + CONVERT(char(11), @DRBMeetingDateTime)))
       WHERE Folder.FolderRSN = @FolderRSN
   END
   ELSE
   BEGIN
      UPDATE Folder
         SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),ISNULL(foldercondition,''))) + ' -> Scheduled for DRB on ' + CONVERT(char(11), @DRBMeetingDateTime)))
       WHERE Folder.FolderRSN = @FolderRSN
   END

   IF @DRBFindingsClock > 0 AND @Foldertype NOT IN ('ZH', 'ZL')
   BEGIN
      UPDATE FolderClock
         SET FolderClock.Status = 'Set to Start', 
             FolderClock.MaxCounter = 45, 
             FolderClock.StartDate = @DRBMeetingDateTime
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'DRB Findings'
   END

   SELECT @InitiateAppealAttemptResult = dbo.udf_GetProcessAttemptCode(@FolderRSN, 10008)

   IF @InitiateAppealAttemptResult = 10015
      SELECT @SchedulerClockStartDate = dbo.udf_GetProcessAttemptDate(@FolderRSN, 10008)
   ELSE 
      SELECT @SchedulerClockStartDate = @InDate

   IF @SchedulerClock > 0 
   BEGIN
      SELECT @DayDiff = DATEDIFF(day, @SchedulerClockStartDate, @DRBMeetingDateTime)

   UPDATE FolderClock
         SET FolderClock.Status = 'Stopped', 
             FolderClock.Counter = @DayDiff, 
             FolderClock.StartDate= @DRBMeetingDateTime
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'Scheduler'
   END

   IF @FolderType = 'ZS'
   BEGIN
      SELECT @DABMeetingDateTime = FolderInfo.InfoValueDateTime
        FROM FolderInfo
       WHERE FolderInfo.FolderRSN =@FolderRSN
         AND FolderInfo.InfoCode = 10003

      IF @DRBMeetingDateTime < @DABMeetingDateTime 
      BEGIN
         UPDATE Folder
   SET Folder.IssueDate  = @DABMeetingDateTime, 
                Folder.ExpiryDate = DATEADD(DAY, 1, @DABMeetingDateTime)
        WHERE Folder.FolderRSN = @FolderRSN
      END
      ELSE
      BEGIN
         UPDATE Folder
            SET Folder.IssueDate  = @DRBMeetingDateTime, 
                Folder.ExpiryDate = DATEADD(DAY, 1, @DRBMeetingDateTime)
          WHERE Folder.FolderRSN = @FolderRSN
      END
   END
END /* End of DRB Meeting Date Info field */

/******************************************************************************/

/* DRB Public Hearing Closed Date */

IF @InfoCode = 10009
BEGIN
   DECLARE @DRBPHClosedDateTime datetime

   SELECT @DRBPHClosedDateTime = FolderInfo.InfoValueDateTime 
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   UPDATE Folder
      SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),ISNULL(foldercondition,''))) + ' -> DRB Closed Public Hearing on ' + CONVERT(char(11),@DRBPHClosedDateTime)))
    WHERE Folder.FolderRSN = @FolderRSN

   IF @DRBFindingsClock > 0
   BEGIN
      UPDATE FolderClock
         SET FolderClock.Status = 'Running', 
             FolderClock.MaxCounter = 45, 
             FolderClock.StartDate = @DRBPHClosedDateTime
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'DRB Findings'
   END

   IF @AppealFindingsClock > 0
   BEGIN
      UPDATE FolderClock
         SET FolderClock.Status = 'Running', 
             FolderClock.MaxCounter = 45, 
             FolderClock.StartDate= @DRBPHClosedDateTime
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'Appeal Fdngs'
   END
END   /* End of DRB Public Hearing Closed Date Info field */

/******************************************************************************/

/* DRB Deliberative Meeting Date */

IF @InfoCode = 10017
BEGIN
   SELECT @DRBDelibMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   UPDATE Folder
      SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),ISNULL(foldercondition,''))) + ' -> Scheduled for DRB Deliberation on ' + CONVERT(char(11), @DRBDelibMeetingDateTime)))
    WHERE Folder.FolderRSN = @FolderRSN
END   /* End of DRB Deliberative Meeting Date Info field */

/******************************************************************************/

/* DAB Board Meeting Date */

IF @InfoCode = 10003
BEGIN
   SELECT @DABMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   UPDATE Folder
      SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),ISNULL(foldercondition,''))) + ' -> Scheduled for DAB on ' + CONVERT(char(11), @DABMeetingDateTime)))
    WHERE Folder.FolderRSN = @FolderRSN

   IF @FolderType = 'ZS'
   BEGIN
      SELECT @DRBMeetingDateTime = FolderInfo.InfoValueDateTime
        FROM FolderInfo
       WHERE FolderInfo.FolderRSN =@folderRSN
         AND FolderInfo.InfoCode = 10001

      IF @DRBMeetingDateTime < @DABMeetingDateTime
      BEGIN
         UPDATE Folder
            SET Folder.IssueDate  = @DABMeetingDateTime, 
                Folder.ExpiryDate = DATEADD(DAY, 1, @DABMeetingDateTime)
          WHERE Folder.FolderRSN = @FolderRSN
      END
      ELSE
      BEGIN
         UPDATE Folder
            SET Folder.IssueDate  = @DRBMeetingDateTime, 
                Folder.ExpiryDate = DATEADD(DAY, 1, @DRBMeetingDateTime) 
          WHERE Folder.FolderRSN = @FolderRSN
      END
   END
END   /* End of DAB Meeting Date Info field */

/******************************************************************************/

/* CB Board Meeting Date */

IF @InfoCode = 10007
BEGIN
   DECLARE @CBMeetingDateTime datetime

   SELECT @CBMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode= @InfoCode

   UPDATE Folder
      SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),ISNULL(foldercondition,''))) + ' -> Scheduled for CB on ' + CONVERT(char(11), @CBMeetingDateTime)))
    WHERE Folder.FolderRSN = @FolderRSN
END /* End of CB Meeting Date Info field */

/******************************************************************************/

/* Administrative Decision Date */

IF @InfoCode = 10055
BEGIN
	DECLARE @AdminDecisionDateTime datetime 

	SELECT @AdminDecisionDateTime = FolderInfo.InfoValueDateTime
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 10055
	
	IF @FolderType = 'ZN'
	BEGIN
		IF @AdminDecisionDateTime < @InDate
				BEGIN
			ROLLBACK TRANSACTION
			RAISERROR ('Admin Decision date is prior to Application date. Please try again', 16, -1)
			RETURN
		END
	END
	ELSE
	BEGIN
		IF DATEADD(DAY, 1, @AdminDecisionDateTime) < @InDate
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR ('Admin Decision date is prior to Application date. Please try again', 16, -1)
			RETURN
		END
	END
END   /* End of Admin Decision Date Info field */

/******************************************************************************/

/* DRB Decision Date */

IF @InfoCode = 10049
BEGIN
   DECLARE @DRBDecisionDateTime datetime

   SELECT @DRBDecisionDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   SELECT @DRBMeetingDateTime = FolderInfo.InfoValueDateTime
  FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10001

   SELECT @DRBDelibMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10017

   IF DATEADD(DAY, 1, @DRBDecisionDateTime) < @InDate
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('DRB Decision date is prior to Application date. Please try again', 16, -1)
     RETURN
   END

   IF ( DATEADD(DAY, 1, @DRBDecisionDateTime) < @DRBMeetingDateTime ) OR 
      ( DATEADD(DAY, 1, @DRBDecisionDateTime) < @DRBDelibMeetingDateTime )
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('DRB Decision date is prior to the meeting date. Please try again', 16, -1)
      RETURN
   END

END   /* End of DRB Decision Date Info field */

/******************************************************************************/

/* DRB Appeal Decision Date */

IF @InfoCode = 10056
BEGIN
   DECLARE @DRBAppealDecisionDateTime datetime

   SELECT @DRBAppealDecisionDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   SELECT @DRBMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10001

   SELECT @DRBDelibMeetingDateTime = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10017

   IF DATEADD(DAY, 1, @DRBAppealDecisionDateTime) < @InDate
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('DRB Appeal Decision date is prior to Application date. Please try again', 16, -1)
  RETURN
   END

   IF ( DATEADD(DAY, 1, @DRBAppealDecisionDateTime) < @DRBMeetingDateTime ) OR 
      ( DATEADD(DAY, 1, @DRBAppealDecisionDateTime) < @DRBDelibMeetingDateTime )
   BEGIN
      ROLLBACK TRANSACTION
    RAISERROR ('DRB Appeal Decision date is prior to the meeting date. Please try again', 16, -1)
 RETURN
   END

END   /* End of DRB Appeal Decision Date Info field */

/******************************************************************************/

/* Other State/Federal Review  - inserts Other State/Federal Review Decision Date */

IF @InfoCode = 10027
BEGIN

   DECLARE @OSFRValue varchar(20)
   DECLARE @OSFDecDateOrder int
   DECLARE @OSFDecDateInfoField int

   SELECT @OSFRValue = FolderInfo.InfoValue
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN =@FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   SELECT @OSFDecDateOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10028)

   SELECT @OSFDecDateInfoField = COUNT(*)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10028

   IF @OSFRValue <> 'None' AND @OSFDecDateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
             ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
               StampDate, StampUser, Mandatory, ValueRequired )
      VALUES ( @FolderRSN, 10028, @OSFDecDateOrder, 'Y', getdate(), @UserID, 'N', 'N')
   END

   IF @OSFRValue = 'None' AND @OSFDecDateInfoField > 0
   BEGIN
      DELETE FROM FolderInfo
      WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10028
   END

END /* End of Other State/Federal Review Info field */

/******************************************************************************/

/* Other State/Federal Decision Date - reset Construction Start Deadline and Permit Expiration Date. 
   Dates reset when Folder Status is Ready to Release, Released, Pre-Release Conditions, 
   Project Phasing, Permit Indeterminate 1, Permit Indeterminate 2, or Permit Indeterminate 3. 
   Checks insure the Permit Expiration Date is not reset to prior than existing. */

IF @InfoCode = 10028
BEGIN
	DECLARE @dtOSFDecisionDateTime datetime
	DECLARE @varOSFAgency varchar(50)
	DECLARE @intStatusCode int
	DECLARE @dtIssueDate datetime
	DECLARE @dtCurrentPermitExpiryDate datetime
	DECLARE @dtNewPermitExpiryDate datetime

	SELECT @dtOSFDecisionDateTime = FolderInfo.InfoValueDateTime
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = @InfoCode

	SELECT @varOSFAgency = FolderInfo.InfoValue
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 10027

	SELECT @intStatusCode = Folder.StatusCode, @dtIssueDate = Folder.IssueDate
	FROM Folder
	WHERE Folder.FolderRSN = @FolderRSN
	
	SELECT @dtCurrentPermitExpiryDate = FolderInfo.InfoValueDateTime
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 10024
	
	SELECT @dtNewPermitExpiryDate = dbo.udf_ZoningPermitExpirationDate (@FolderRSN, @dtOSFDecisionDateTime) 

	/* In order to not reset expiration dates to sooner than current, the OSF decision date must be after the existing decision date. 
	Next, in cases where the expiration dates were lengthened by the DRB beyond defaults, the current Permit Expiration Date must 
	be less than the expiration date set from the OSF decision date. The same check is for any 1-year permit extensions. */ 
	
	IF @intStatusCode IN (10005, 10006, 10018, 10029, 10047, 10048, 10055) 
	BEGIN
	   IF ( @dtNewPermitExpiryDate > @dtCurrentPermitExpiryDate AND @dtOSFDecisionDateTime > @dtIssueDate ) 
		BEGIN
			EXECUTE dbo.usp_Zoning_Permit_Expiration_Dates @FolderRSN, @dtOSFDecisionDateTime 
			EXECUTE dbo.usp_Zoning_Permit_Status_Rollback @FolderRSN 

			UPDATE Folder
			SET Folder.FolderCondition = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),ISNULL(Folder.FolderCondition,''))) + ' -> Subsequent ' + @varOSFAgency + ' Permit Approval on ' + CONVERT(CHAR(11), @dtOSFDecisionDateTime) + ' Extended Time Limits'))
			WHERE Folder.FolderRSN = @FolderRSN
		END

	END
	ELSE
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Permit must be in a post-appeal period status for date entry. Ski you later.', 16, -1)
		RETURN
	END
   
END   /* End of Other State/Federal Decision Date Info field */

/******************************************************************************/

/* DRB Deliberative Decision (10036). Add Zoning Decision Letter - PH document.  */

IF @InfoCode= 10036
BEGIN

  DECLARE @DecisionLetterDoc int
   DECLARE @NextDocumentRSN int

   SELECT @DecisionLetterDoc = count(*)
     FROM FolderDocument
    WHERE FolderDocument.FolderRSN = @FolderRSN
      AND FolderDocument.DocumentCode = 10012

   IF @DecisionLetterDoc = 0
   BEGIN 
    SELECT @NextDocumentRSN = MAX(FolderDocument.DocumentRSN) + 1
        FROM FolderDocument

      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                  DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 10012, 1, @NextDocumentRSN, 40, getdate(), @UserID, 1 )  
   END

END

/******************************************************************************/

/* Impact Fees Yes/No (10058). Adds Permit Conditions with Impact Fees (10006) 
   document, and deletes the Permit Conditions (10008) document if it has 
   not been generated. */

IF @InfoCode = 10058
BEGIN
   DECLARE @ImpactFeesApplied varchar(4)
   DECLARE @PermitConditionsDoc int
   DECLARE @PermitConditionsDocNotGenerated int
   DECLARE @PermitConditionsImpactDoc int
   DECLARE @PermitConditionsImpactDocNotGenerated int

   SELECT @PermitConditionsDoc = count(*)
     FROM FolderDocument
    WHERE FolderDocument.FolderRSN = @FolderRSN
     AND FolderDocument.DocumentCode = 10008

   SELECT @PermitConditionsDocNotGenerated = count(*)
     FROM FolderDocument
    WHERE FolderDocument.FolderRSN = @FolderRSN
      AND FolderDocument.DocumentCode = 10008
      AND FolderDocument.DateGenerated IS NULL

   SELECT @PermitConditionsImpactDoc = count(*)
     FROM FolderDocument
    WHERE FolderDocument.FolderRSN = @FolderRSN
      AND FolderDocument.DocumentCode = 10006

   SELECT @PermitConditionsImpactDocNotGenerated = count(*)
     FROM FolderDocument
    WHERE FolderDocument.FolderRSN = @FolderRSN
      AND FolderDocument.DocumentCode = 10006
      AND FolderDocument.DateGenerated IS NULL

   SELECT @ImpactFeesApplied = ISNULL(UPPER(FolderInfo.InfoValue), 'NO')
     FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 10058

   IF @ImpactFeesApplied = 'YES'
   BEGIN
      IF @PermitConditionsImpactDoc = 0
      BEGIN
         SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
           FROM FolderDocument

     INSERT INTO FolderDocument
                   ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                  DisplayOrder, StampDate, StampUser, LinkCode )
            VALUES ( @FolderRSN, 10006, 1, @NextDocumentRSN, 13, getdate(), @UserID, 1 ) 
      END

      IF @PermitConditionsDoc > 0 AND @PermitConditionsDocNotGenerated > 0
      BEGIN
        DELETE FROM FolderDocument
              WHERE FolderDocument.FolderRSN = @FolderRSN
                AND FolderDocument.DocumentCode = 10008
      END
   END

  IF @ImpactFeesApplied = 'NO'
   BEGIN
      IF @PermitConditionsDoc = 0
      BEGIN
         SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
           FROM FolderDocument

       INSERT INTO FolderDocument
                   ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
  DisplayOrder, StampDate, StampUser, LinkCode )
      VALUES ( @FolderRSN, 10008, 1, @NextDocumentRSN, 10, getdate(), @UserID, 1 ) 
      END

   IF @PermitConditionsImpactDoc > 0 AND @PermitConditionsImpactDocNotGenerated > 0
      BEGIN
         DELETE FROM FolderDocument
               WHERE FolderDocument.FolderRSN = @FolderRSN
                 AND FolderDocument.DocumentCode = 10006
    END
   END
END

/******************************************************************************/

/* Extend Permit Expiration Yes/ No (10078). */

IF @InfoCode = 10078
BEGIN
   EXECUTE dbo.usp_Zoning_Insert_Extend_Permit_Expiration_Process @FolderRSN, @UserID
END

/******************************************************************************/

/* Number of Phases - Version 2 3/2013 - Entry of Number of Phases can be done at 
   any time and the phasing setup is executed by other processes. */

IF @InfoCode = 10081
BEGIN
	DECLARE @intPermitDecision int
	DECLARE @intPhaseCOFlag int
	DECLARE @intNumberofPhasesCount int
	DECLARE @intNumberofPhasesValue int 

	SELECT @intPermitDecision = dbo.udf_GetZoningDecisionAttemptCode(@FolderRSN)
	SELECT @intPhaseCOFlag = dbo.udf_CountProcessAttemptResults(@FolderRSN, 10030) 
   
	SELECT @intNumberofPhasesCount = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = @InfoCode

	IF @intNumberofPhasesCount > 0
	BEGIN
		SELECT @intNumberofPhasesValue = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @FolderRSN 
		AND FolderInfo.InfoCode = @InfoCode
	END
	ELSE SELECT @intNumberofPhasesValue = 0

	IF @intPhaseCOFlag > 0
	BEGIN  
		ROLLBACK TRANSACTION
		RAISERROR ('Phase Certificate of Occupancy issuance has commenced: The number of phases can no longer be altered. So sorry.', 16, -1)
		RETURN
	END

	IF @intPermitDecision IN (10002, 10020)     /* Denials */
	BEGIN  
		ROLLBACK TRANSACTION
		RAISERROR ('The permit application was denied so there is nothing to phase. So sorry.', 16, -1)
		RETURN
	END

	IF @intNumberofPhasesValue > 99
	BEGIN  
		ROLLBACK TRANSACTION
		RAISERROR ('A lovely project from hell, but the maximum number of phases allowed is 99.', 16, -1)
		RETURN
	END

	/* Insert or delete Phased CO processes when applicable. */

	EXECUTE dbo.usp_Zoning_Insert_Phased_CO_Processes @FolderRSN, @UserID
END 

/******************************************************************************/



GO
