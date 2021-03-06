USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZZ_00010014]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZZ_00010014]
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
/* Project Decision - Historic (10014) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @InDate datetime
DECLARE @ZPNUmber varchar(10)
DECLARE @ProjectUseInfoValue varchar(30)
DECLARE @ProjectTypeInfoValue varchar(30)
DECLARE @AdminDecisionDate datetime
DECLARE @COADecisionDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime
DECLARE @intNextStatusCode int

/* Get Attempt Result, and other folder values. Get Folder Type for the parent folder, 
   if it exists. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType,
       @InDate = Folder.InDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode,
       @ZPNUmber = Folder.ReferenceFile
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

/* Get decision dates(s), and Project Use and Type */

SELECT @AdminDecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10055         /* Admin Decision Date */

SELECT @COADecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10052         /* COA Decision Date */

SELECT @ProjectUseInfoValue = FolderInfo.InfoValue
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10019         /* Project Use */

SELECT @ProjectTypeInfoValue = FolderInfo.InfoValue
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10021         /* Project Type */

/* Check for required entry info */

IF @ZPNUmber IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Zoning Permit Number (Reference File #) to proceed', 16, -1)
   RETURN
END

IF @ProjectUseInfoValue IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Project Use (info) to proceed', 16, -1)
   RETURN
END

IF @ProjectTypeInfoValue IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Project Type (info) to proceed', 16, -1)
   RETURN
END

/* Check for consistency between decision dates and Sub and Work codes. */

IF @AdminDecisionDate IS NULL AND @COADecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter Decision Date(s) (Info) to proceed', 16, -1)
   RETURN
END

/* Set decision date and appeal period expiry date. */

IF ( @AdminDecisionDate IS NOT NULL AND @COADecisionDate IS NULL ) 
   SELECT @DecisionDate = @AdminDecisionDate

IF ( @COADecisionDate IS NOT NULL AND @AdminDecisionDate IS NULL ) 
   SELECT @DecisionDate = @COADecisionDate

IF ( @AdminDecisionDate IS NOT NULL AND @COADecisionDate IS NOT NULL )
BEGIN 
   IF ( @COADecisionDate <  @AdminDecisionDate )  SELECT @DecisionDate = @AdminDecisionDate

   IF ( @COADecisionDate >= @AdminDecisionDate )  SELECT @DecisionDate = @COADecisionDate 
END

IF @SubCode = 10041 SELECT @ExpiryDate = DATEADD(day, 15, @DecisionDate) 

IF @SubCode = 10042 SELECT @ExpiryDate   = DATEADD(day, 30, @DecisionDate) 

/* Set permit expiry dates to 3 years (InfoCode 10024) */

UPDATE FolderInfo
   SET FolderInfo.InfoValue = CONVERT (char(11), DATEADD(year, 3, @DecisionDate)), 
       FolderInfo.InfoValueDateTime = DATEADD(year, 3, @DecisionDate)
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10024

/* Set next Folder StatusCode. Appeal period is skipped as these are old permits. 
   Variances do not receive Certificates of Occupancy, hence status becomes 
   Review Complete.
   For permits issued prior to July 13, 1989, that did not include public 
   infrastructure, Certificates of Occupancy are not required.  Hence for attempt 
   result 10076, the status becomes Review Complete so the CO process is not added. */

IF @WorkCode = 10003       /* Variance */
BEGIN
   SELECT @intNextStatusCode =
   CASE @AttemptResult
      WHEN 10002 THEN 10032   /* Request Denied */
      WHEN 10003 THEN 10031   /* Review Complete */
      WHEN 10011 THEN 10031   /* Reveiw Complete */
      WHEN 10020 THEN 10032   /* Request Denied */
      WHEN 10076 THEN 10031   /* Review Complete */
   END
END
ELSE
BEGIN
   SELECT @intNextStatusCode =
   CASE @AttemptResult
      WHEN 10002 THEN 10032   /* Request Denied */
      WHEN 10003 THEN 10006   /* Released */
      WHEN 10011 THEN 10006   /* Released */
      WHEN 10020 THEN 10032   /* Request Denied */
      WHEN 10076 THEN 10031   /* Review Complete */
   END
END

/* Set review decision, update folder status to Released */

IF @AttemptResult = 10003                   /* Decision: Approved */
BEGIN
  UPDATE Folder
      SET Folder.StatusCode = @intNextStatusCode, 
     Folder.IssueDate = @DecisionDate, Folder.ExpiryDate = @ExpiryDate, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + 'Historic Permit -> Decision: Approved (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'APP (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

IF @AttemptResult = 10011                  /* Decision: Approved with Pre-Release Conditions*/
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @intNextStatusCode, 
          Folder.IssueDate = @DecisionDate, Folder.ExpiryDate = @ExpiryDate, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + 'Historic Permit -> Decision: Approved with Pre-Release Conditions (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP-PRC',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'APP-PRC (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
           WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

IF @AttemptResult = 10076                   /* Decision: Approved Prior to 7/13/1989 */
BEGIN
  UPDATE Folder
      SET Folder.StatusCode = @intNextStatusCode, 
          Folder.IssueDate = @DecisionDate, Folder.ExpiryDate = @ExpiryDate, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + 'Historic Permit -> Decision: Approved (' + CONVERT(char(11), @DecisionDate) + ') -> CO Not Required for Approvals prior to 7/13/1989'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP Pre-1989',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'APP Pre-1989 (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

IF @AttemptResult = 10002                     /* Decision: Denied */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @intNextStatusCode, 
          Folder.IssueDate = @DecisionDate, Folder.ExpiryDate = @ExpiryDate, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + 'Historic Permit -> Decision: Denied (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'DEN',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'DEN (' + CONVERT(char(11), @DecisionDate) + ')', 
 FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

IF @AttemptResult = 10020                  /* Decision: Denied w/o Prejudice */
BEGIN
  UPDATE Folder
     SET Folder.StatusCode = @intNextStatusCode, 
         Folder.IssueDate = @DecisionDate, Folder.ExpiryDate = @ExpiryDate, 
         Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + 'Historic Permit -> Decision: Denied without Prejudice (' + CONVERT(char(11), @DecisionDate) + ')'))
   WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'DWP',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
   SET FolderProcessAttempt.AttemptComment = 'DWP (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
        ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )
END

/* Set permit expiry dates to 3 years (InfoCode 10024) */

IF @AttemptResult IN (10003, 10011)
BEGIN
   UPDATE FolderInfo
      SET FolderInfo.InfoValue = CONVERT(CHAR(11), DATEADD(year, 2, @DecisionDate)), 
          FolderInfo.InfoValueDateTime = DATEADD(year, 2, @DecisionDate)
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode = 10127     /* COnstruction Start Deadline */

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = CONVERT(CHAR(11), DATEADD(year, 3, @DecisionDate)), 
          FolderInfo.InfoValueDateTime = DATEADD(year, 3, @DecisionDate)
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode = 10024     /* Permit Expiration Date */
END

/* Decision Rendered:
   Record Appeal period start and end in both the Project Decision (10005) process. */

UPDATE FolderProcess
   SET FolderProcess.Startdate = @DecisionDate,
       FolderProcess.EndDate = @ExpiryDate
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessRSN = @ProcessRSN

/* To make the default folder view sort in the proper chronological order, 
   code FolderCentury and FolderYear to reflect Folder.IssueDate. */

UPDATE Folder
SET Folder.FolderCentury = SUBSTRING(STR(DATEPART(yyyy, @DecisionDate), 4, 0), 1, 2), 
    Folder.FolderYear =    SUBSTRING(STR(datePart(yyyy, @DecisionDate), 4, 0), 3, 2)
WHERE Folder.FolderRSN = @FolderRSN


GO
