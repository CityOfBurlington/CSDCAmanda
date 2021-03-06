USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010012]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010012]
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

/* Mr. Fixit (10012) */

/* 10033 - Roll folder status back to In Review */

/* 10037 - Roll folder status back into Appeal Period - APP, DEN, PRC, DWP */

/* 10038 - Roll folder status back to Appealed to DRB */

/* 10039 - Roll folder status back to Appealed to VEC */

/* 10077 - Roll back ZS folder to In Review */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @SubCode int
DECLARE @WorkCode int 
DECLARE @APDRBProcess int
DECLARE @APVECProcess int
DECLARE @DecisionProcessCode int
DECLARE @DecisionDateInfoCode int
DECLARE @PreviousDecisionDateInfoCode int
DECLARE @PreviousDecisionDate datetime
DECLARE @PreviousAppealPeriodDays int
DECLARE @PreviousExpiryDate datetime

DECLARE @DecisionAttemptResult int
DECLARE @AppealStatusCode int

/* Get Attempt Result and Folder info */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode, 
       @SubCode = Folder.SubCode, 
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @APDRBProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10002               /* Appeal to DRB */

SELECT @APVECProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10003               /* Appeal to VEC */

SELECT @DecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@FolderRSN)

/* Roll back application review decisions to In Review. */
/* Application decisions or appeals of CE or misc zoning decisions. */

IF ( @AttemptResult = 10033 AND 
     @FolderStatus IN(10002, 10003, 10004, 10005, 10016, 10018, 10027, 10032) )
BEGIN

   IF ( @APDRBProcess = 0 AND @APVECProcess = 0 ) OR 
      ( @FolderType = 'ZL' AND @APVECProcess = 0 ) 
   BEGIN
      IF @FolderType = 'ZL' SELECT @DecisionDateInfoCode = 10056
      ELSE
      BEGIN
         SELECT @DecisionDateInfoCode = 
         CASE @SubCode
            WHEN 10041 THEN 10055
            WHEN 10042 THEN 10049
            ELSE 0
         END
      END

      UPDATE FolderProcess
      SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10000         /* Review Path */
         AND FolderProcess.FolderRSN = @folderRSN

      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10007         /* Review Clock */
         AND FolderProcess.FolderRSN = @folderRSN

      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = @DecisionProcessCode
         AND FolderProcess.FolderRSN = @folderRSN

      DELETE FROM FolderProcessAttempt                 /* Delete attempt results */
       WHERE FolderProcessAttempt.ProcessRSN = 
             (SELECT FolderProcess.ProcessRSN 
                FROM FolderProcess
               WHERE FolderProcess.FolderRSN  = @folderRSN
                 AND FolderProcess.ProcessCode = @DecisionProcessCode) 

      DELETE FROM FolderProcess
       WHERE FolderProcess.ProcessCode = 10008         /* Initiate Appeal */
         AND FolderProcess.FolderRSN = @folderRSN

      UPDATE Folder
         SET Folder.StatusCode = 10001, 
             Folder.IssueDate = NULL, Folder.ExpiryDate = NULL
       WHERE Folder.FolderRSN = @FolderRSN

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
       WHERE FolderInfo.FolderRSN = @FolderRSN
         AND FolderInfo.InfoCode = @DecisionDateInfoCode

    UPDATE FolderInfo
         SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
       WHERE FolderInfo.FolderRSN = @FolderRSN
         AND FolderInfo.InfoCode = 10024               /* Permit Expiration Date */

   END
END

/* Put folder back into its appeal period. Use when an appeal is not logged  */
/* before the login procedure removes the folder from its appeal period. */

IF ( @AttemptResult = 10037 AND @FolderStatus IN(10005, 10018, 10032) )
BEGIN

   SELECT @DecisionAttemptResult = ISNULL(FolderProcessAttempt.ResultCode, 0)
     FROM Folder, FolderProcess, FolderProcessAttempt
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcess.ProcessCode = @DecisionProcessCode
      AND Folder.FolderRSN = @folderRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcess, FolderProcessAttempt
             WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
               AND FolderProcess.ProcessCode = @DecisionProcessCode
               AND FolderProcessAttempt.FolderRSN = @folderRSN )

   SELECT @AppealStatusCode = 
   CASE @DecisionAttemptResult
      WHEN 10002 THEN 10003
      WHEN 10003 THEN 10002
      WHEN 10011 THEN 10004
      WHEN 10020 THEN 10016
      WHEN 10017 THEN 10002
      WHEN 10018 THEN 10003
      WHEN 10046 THEN 10027
      WHEN 10047 THEN 10027
      ELSE 0
   END

   UPDATE Folder
      SET Folder.StatusCode = @AppealStatusCode
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET StatusCode = 1, EndDate = NULL
    WHERE FolderProcess.ProcessCode = 10008
      AND FolderProcess.FolderRSN = @folderRSN

END

/* Roll back from DRB appeal decisions */

IF ( @AttemptResult = 10038 AND 
     @FolderStatus IN(10002, 10003, 10004, 10005, 10016, 10018, 10027, 10032) )
BEGIN
   IF ( @APDRBProcess = 1 AND @APVECProcess = 0 ) 
   BEGIN

      SELECT @DecisionDateInfoCode = 10056

      SELECT @PreviousDecisionDateInfoCode = 
      CASE @SubCode
         WHEN 10041 THEN 10055
         ELSE 10049
      END

      SELECT @PreviousAppealPeriodDays = 
      CASE @SubCode
         WHEN 10041 THEN 15
         WHEN 10043 THEN 15
         WHEN 10044 THEN 15
         ELSE 30
      END
      IF @SubCode IN(10041, 10042, 10045, 10046, 10047, 10048) 
      BEGIN
         SELECT @PreviousDecisionDate = FolderInfo.InfoValueDateTime
           FROM FolderInfo
          WHERE FolderInfo.InfoCode = @PreviousDecisionDateInfoCode
            AND FolderInfo.FolderRSN = @folderRSN

         SELECT @PreviousExpiryDate = DATEADD(day, @PreviousAppealPeriodDays, @PreviousDecisionDate)
      END
      ELSE
      BEGIN
         SELECT @PreviousDecisionDate = NULL, @PreviousExpiryDate = NULL
      END

      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10007         /* Review Clock */
         AND FolderProcess.FolderRSN = @folderRSN

      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10002         /* Appeal to DRB */
         AND FolderProcess.FolderRSN = @folderRSN

      DELETE FROM FolderProcessAttempt                 /* Delete attempt results */
       WHERE FolderProcessAttempt.ProcessRSN = 
             (SELECT FolderProcess.ProcessRSN 
                FROM FolderProcess
               WHERE FolderProcess.FolderRSN  = @folderRSN
                 AND FolderProcess.ProcessCode = 10002) 

      UPDATE Folder
         SET Folder.StatusCode = 10009, Folder.IssueDate = @PreviousDecisionDate, 
             Folder.ExpiryDate = @PreviousExpiryDate
       WHERE Folder.FolderRSN = @folderRSN

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
 WHERE FolderInfo.FolderRSN = @folderRSN
         AND FolderInfo.InfoCode = @DecisionDateInfoCode

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = CONVERT(char(11), dbo.udf_ZoningPermitExpirationDate(@folderRSN, @PreviousDecisionDate)),
             FolderInfo.InfoValueDateTime = dbo.udf_ZoningPermitExpirationDate(@folderRSN, @PreviousDecisionDate)
       WHERE FolderInfo.FolderRSN = @folderRSN 
         AND FolderInfo.InfoCode = 10024

   END
END

/* Roll back from VEC appeal decisions */

IF ( @AttemptResult = 10039 AND 
     @FolderStatus IN(10002, 10003, 10004, 10005, 10016, 10018, 10027, 10032) )
BEGIN

   IF @APVECProcess = 1 
   BEGIN

      SELECT @DecisionDateInfoCode = 10057

      SELECT @PreviousDecisionDateInfoCode = 10056

      SELECT @PreviousAppealPeriodDays = 30

      SELECT @PreviousDecisionDate = FolderInfo.InfoValueDateTime
        FROM FolderInfo
       WHERE FolderInfo.InfoCode = @PreviousDecisionDateInfoCode
         AND FolderInfo.FolderRSN = @folderRSN

      SELECT @PreviousExpiryDate = DATEADD(day, @PreviousAppealPeriodDays, @PreviousDecisionDate)

      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10007         /* Review Clock */
         AND FolderProcess.FolderRSN = @folderRSN

      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10003         /* Appeal to VEC */
         AND FolderProcess.FolderRSN = @folderRSN

      DELETE FROM FolderProcessAttempt         /* Delete attempt results */
       WHERE FolderProcessAttempt.ProcessRSN = 
             (SELECT FolderProcess.ProcessRSN 
                FROM FolderProcess
               WHERE FolderProcess.FolderRSN  = @folderRSN
     AND FolderProcess.ProcessCode = 10003) 

      UPDATE Folder
         SET Folder.StatusCode = 10017, Folder.IssueDate = @PreviousDecisionDate, 
            Folder.ExpiryDate = @PreviousExpiryDate
       WHERE Folder.FolderRSN = @folderRSN

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
       WHERE FolderInfo.FolderRSN = @folderRSN
         AND FolderInfo.InfoCode = @DecisionDateInfoCode

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = CONVERT(char(11), dbo.udf_ZoningPermitExpirationDate(@folderRSN, @PreviousDecisionDate)),
             FolderInfo.InfoValueDateTime = dbo.udf_ZoningPermitExpirationDate(@folderRSN, @PreviousDecisionDate)
       WHERE FolderInfo.FolderRSN = @folderRSN 
         AND FolderInfo.InfoCode = 10024

   END
END

/* Reopen Sketch Plan folderto In Review: Null out meeting dates and reopen processes. */

IF ( @AttemptResult = 10077 AND @FolderStatus = 10031 )
BEGIN
	UPDATE Folder
	SET Folder.StatusCode = 10001, Folder.IssueDate = NULL, 
		Folder.ExpiryDate = NULL, Folder.FinalDate = NULL
	WHERE Folder.FolderRSN = @FolderRSN

/*	UPDATE FolderInfo
	SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode IN (10001, 10003, 10007) */

	UPDATE FolderProcess
	SET StatusCode = 1, EndDate = NULL
	WHERE FolderProcess.ProcessCode = 10000         /* Review Path */
	AND FolderProcess.FolderRSN = @FolderRSN

	UPDATE FolderProcess
	SET StatusCode = 1, EndDate = NULL
	WHERE FolderProcess.ProcessCode = 10007         /* Review Clock */
	AND FolderProcess.FolderRSN = @FolderRSN
END

/* Re-open this process for reuse. */
/* Process is closed when appeal period becomes expired. */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, FolderProcess.DisplayOrder = 9999, 
       FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
       FolderProcess.ScheduleDate = NULL,
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL
 WHERE FolderProcess.ProcessRSN = @processRSN

GO
