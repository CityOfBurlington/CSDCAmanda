USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010003]    Script Date: 9/9/2013 9:56:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010003]
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
/* Appeal to VSCED (10003) version 4 */

DECLARE @AttemptResult int
DECLARE @InDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime
DECLARE @PermitExpiryDate datetime
DECLARE @FolderType varchar(4)
DECLARE @StatusCode int
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @NextStatusCode int
DECLARE @DecisionProcessRSN int
DECLARE @DecisionProcessCode int
DECLARE @DecisionAttemptResult int
DECLARE @DecisionOverturnAttemptResult int
DECLARE @DecisionOverturnProcessText varchar(40)
DECLARE @NextDecisionAttemptRSN int
DECLARE @AppealDecisionText varchar(120)
DECLARE @ProcessCommentText varchar(60)
DECLARE @PermitPickedupInfoOrder int
DECLARE @PermitPickedupInfoField int

/* Get Attempt result, folder type, sub and work codes, VEC decision date. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType,
       @StatusCode = Folder.StatusCode, 
       @InDate = Folder.InDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder 
 WHERE Folder.FolderRSN = @FolderRSN

/* Check for valid attempt result by folder type, and check for VEC decision date.  */

IF @FolderType = 'ZN' AND @AttemptResult IN (10008, 10009, 10010, 10030, 10053, 10054, 10055)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Use ZN Permit Not Required, or ZN Permit Required for Nonapplicabilities. Please re-enter.', 16, -1)
   RETURN
END

IF @FolderType <> 'ZN' AND @AttemptResult IN (10056, 10057)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Attempt result is valid only for Nonapplicabilities (ZN). Please re-enter.', 16, -1)
   RETURN
END

IF @FolderType = 'ZL' AND @AttemptResult IN (10008, 10009, 10010, 10030, 10056, 10057)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Use ZH Upheld Misc Admin Decision, or ZH Overturned Misc Admin Decision, for appeals of Notices of Violations, and of misc zoning decisions. Please re-enter.', 16, -1)
   RETURN
END

IF @FolderType <> 'ZL' AND @AttemptResult IN (10054, 10055)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Attempt result is valid only for appeals of Notices of Violations, and of misc zoning decisions. Please re-enter.', 16, -1)
   RETURN
END

IF @FolderType IN ('ZD', 'ZN') AND @AttemptResult = 10053
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Stipulation Agreement is an invalid outcome for this folder. Please re-enter.', 16, -1)
   RETURN
END

SELECT @DecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10057             /* VEC Appeal Decision Date */

IF @DecisionDate IS NULL AND @AttemptResult NOT IN (10004, 10052) /* Withdraw Appeal, Dismissed as Moot */
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the VEC Appeal Decision Date (Info) to proceed', 16, -1)
   RETURN
END

SELECT @PermitPickedupInfoOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10023)

SELECT @PermitPickedupInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10023) 

/* Get Decision process attempt result, and other parameters. 
   Set a reversed Decision process attempt result code. The reversed decision code 
   will be inserted into the decision process for VEC decision that reverse DRB decisions. */

SELECT @DecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@FolderRSN)

SELECT @DecisionProcessRSN = dbo.udf_GetZoningDecisionProcessRSN(@FolderRSN)

SELECT @DecisionAttemptResult = dbo.udf_GetZoningDecisionAttemptCode(@FolderRSN)

SELECT @NextDecisionAttemptRSN = dbo.udf_GetZoningDecisionNextAttemptRSN(@FolderRSN) 

SELECT @DecisionOverturnAttemptResult = dbo.udf_GetZoningDecisionOverturnAttemptResult(@FolderRSN)

SELECT @DecisionOverturnProcessText = dbo.udf_GetZoningDecisionOverturnAttemptText(@FolderRSN)

/* Set appeal (to VT Supreme Court) expiration date (30 days). */

SELECT @ExpiryDate = DATEADD(DAY, 30, @DecisionDate)

/* Update FolderInfo Permit Expiration Date and Construction Start Deadline 
	for all attempt results except Withdraw Appeal and Dismissed. 
	CHECK THIS LOGIC - MAY NEED TO GET TH EXISTING EXPIRY DATES FOR WITHDRAW AND DISMISSED. */

SELECT @PermitExpiryDate = dbo.udf_ZoningPermitExpirationDate(@FolderRSN, @DecisionDate)

IF @AttemptResult NOT IN (10004, 10052) 

   EXECUTE dbo.usp_Zoning_Permit_Expiration_Dates @FolderRSN, @DecisionDate

/* Set Next Folder.StatusCode. */

IF @AttemptResult IN (10004, 10052)     /* Withdraw Appeal or Dismissed */       
	SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @DecisionAttemptResult)
ELSE
BEGIN
	IF @FolderType = 'ZD' SELECT @NextStatusCode = 10027
	ELSE SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @AttemptResult)
END

/* VEC denies application. */

IF @AttemptResult IN ( 10008, 10057 )                   /* VEC Denied Permit */
BEGIN
  IF @FolderType = 'ZN' SELECT @AppealDecisionText = ' -> Decision: Permit Required by VEC ('
   ELSE SELECT @AppealDecisionText = ' -> Decision: Permit Application Denied by VEC ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'DEN',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* VEC approves application */        /* VEC Approved Permit */

IF @AttemptResult IN ( 10009, 10056)          
BEGIN
   IF @FolderType = 'ZN' SELECT @AppealDecisionText = ' -> Decision: Permit Not Required by VEC ('
   ELSE SELECT @AppealDecisionText = ' -> Decision: Permit Application Approved by VEC ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP',
           FolderProcess.StartDate = @DecisionDate,
         FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* VEC approves application, but modifies original DRB decision */

IF @AttemptResult = 10010                    /* VEC Modified Permit */

BEGIN
   SELECT @AppealDecisionText = ' -> Decision: Permit Application Approved by VEC with Modifications to DRB Decision ('

   UPDATE Folder
   SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP-MOD',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* VEC denies-without-prejudice application. Since the judge has left the door open 
   to rehear the case, this process could be reopened, but for now it closes. */

IF @AttemptResult = 10030    /* VEC Denies w/o Prejudice Permit */
BEGIN
   SELECT @AppealDecisionText = ' -> Decision: Permit Application Denied without Prejudice by VEC ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
           SET FolderProcess.ProcessComment = 'DWP',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* VEC Upholds Misc Administrative Decision. 
   Allowed via previous error checks for ZL folders only. */ 

IF @AttemptResult  = 10054                       /* VEC Upheld Misc Admin Decision */
BEGIN
   IF @WorkCode = 10004 SELECT @AppealDecisionText = ' -> Decision: Misc Code Enforcement Decision Upheld by VEC ('
   IF @WorkCode = 10005 SELECT @AppealDecisionText = ' -> Decision: Misc Zoning Admin Decision Upheldd by VEC ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Appeal Denied',
           FolderProcess.StartDate = @DecisionDate,
  FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* VEC Overturns Misc Administrative Decision. 
   Allowed via previous error checks for ZL folders only. */ 

IF @AttemptResult  = 10055                       /* VEC Overturned Misc Admin Decision */
BEGIN
   IF @WorkCode = 10004 SELECT @AppealDecisionText = ' -> Decision: Misc Code Enforcement Decision Overturned by VEC ('
   IF @WorkCode = 10005 SELECT @AppealDecisionText = ' -> Decision: Misc Zoning Admin Decision Overturned by VEC ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Appeal Granted',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* VEC Remands review of permit back to the City with some orders.  Folder and 
   processes are closed out and superseded by a new folder linked as a child. */

IF @AttemptResult = 10048                    /* VEC Remanded to City */
BEGIN
   SELECT @AppealDecisionText = ' -> Decision: Review Remanded Back to City by VEC ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ') -> Review to be Continued with New Folder'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Remanded',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* City and Appellant enter into a Stipulation Agreement.  This equates to approval. */

IF @AttemptResult = 10053                             /* Stipulation Agreement Reached */
BEGIN
   SELECT @AppealDecisionText = ' -> VEC Outcome: Stipulation Agreement Reached by City and Appellant ('

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Stipulation Agreement',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* Appellant withdraws the appeal (10004) or VEC dismisses the appeal as moot or 
   for some other reason (10052 - no grounds for appeal). 
   Put folder status back into appeal period for last decision, and nightly status 
   update procedure will flip status to what it should be. */

IF @AttemptResult IN (10004, 10052)     /* Withdraw Appeal or Dismissed */       
BEGIN
   SELECT @AppealDecisionText = 
   CASE @AttemptResult
      WHEN 10004 THEN ' -> Appeal Withdrawn by Appellant ('
      WHEN 10052 THEN ' -> Decision: Appeal Dismissed by VEC ('
   ELSE ' -> ? ('
  END

   SELECT @ProcessCommentText = 
   CASE @AttemptResult
      WHEN 10004 THEN 'Appeal Withdrawn'
      WHEN 10052 THEN 'Dismissed'
      ELSE '?'
   END

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, 
   Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AppealDecisionText + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ProcessCommentText
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* For reversed decisions, insert attempt result into the original decision process for the VEC decision. 
	Insert or delete Permit Picked Up info field. */

IF @AttemptResult IN (10009, 10010, 10053, 10055, 10056) AND @DecisionAttemptResult IN (10002, 10006, 10018, 10020)
BEGIN
   INSERT INTO FolderProcessAttempt
             ( AttemptRSN, FolderRSN, ProcessRSN, 
               ResultCode, 
               AttemptComment, 
               AttemptBy, AttemptDate, StampUser, StampDate )
      VALUES ( @NextDecisionAttemptRSN, @FolderRSN, @DecisionProcessRSN, 
               @DecisionOverturnAttemptResult, 
               'Overturned on VEC Appeal (' + CONVERT(CHAR(11), @DecisionDate) + ')', 
               @UserID, getdate(), @UserID, getdate() )

     UPDATE FolderProcess
        SET FolderProcess.ProcessComment = @DecisionOverturnProcessText
       FROM FolderProcess
      WHERE FolderProcess.FolderRSN = @FolderRSN
        AND FolderProcess.ProcessRSN = @DecisionProcessRSN
        AND FolderProcess.ProcessCode = @DecisionProcessCode
END

IF @AttemptResult IN(10008, 10030, 10054, 10057) AND @DecisionAttemptResult IN(10003, 10007, 10011, 10017)
BEGIN
   INSERT INTO FolderProcessAttempt
             ( AttemptRSN, FolderRSN, ProcessRSN, 
    ResultCode, AttemptComment, 
               AttemptBy, AttemptDate, StampUser, StampDate )
     VALUES ( @NextDecisionAttemptRSN, @FolderRSN, @DecisionProcessRSN, 
               @DecisionOverturnAttemptResult, 
               'Overturned on VEC Appeal (' + CONVERT(CHAR(11), @DecisionDate) + ')', 
               @UserID, getdate(), @UserID, getdate() )

     UPDATE FolderProcess
        SET FolderProcess.ProcessComment = @DecisionOverturnProcessText
       FROM FolderProcess
      WHERE FolderProcess.FolderRSN = @FolderRSN
        AND FolderProcess.ProcessRSN = @DecisionProcessRSN
        AND FolderProcess.ProcessCode = @DecisionProcessCode

     IF @DecisionAttemptResult = 10011   /* App with Pre-Release Conditions */
     BEGIN
        UPDATE FolderProcess
               SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate() 
         WHERE FolderProcess.FolderRSN = @FolderRSN
              AND FolderProcess.ProcessCode = 10006
              AND FolderProcess.StatusCode = 1 
     END
END

/* Update Project Manager Info field */ 

EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Set up Permit Picked Up Info field */

IF @PermitPickedupInfoField = 0 AND @AttemptResult IN (10009, 10010, 10053)
BEGIN
   INSERT INTO FolderInfo
             ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                InfoValue, InfoValueUpper, 
                StampDate, StampUser, Mandatory, ValueRequired )
      VALUES ( @FolderRSN, 10023,  @PermitPickedupInfoOrder, 'Y', 
               'No', 'NO', 
               getdate(), @UserID, 'N', 'N' )
END

IF @PermitPickedupInfoField > 0 AND @AttemptResult IN(10008, 10030)
BEGIN
   DELETE FROM FolderInfo
         WHERE FolderInfo.FolderRSN = @folderRSN
           AND FolderInfo.InfoCode = 10023
END

/* Decision Rendered:
   Record gross review period start and end of Appeal to VEC process. 
   Close Appeal Clock (10018). Open Initiate Appeal (10008). 
   Closee all processes upon Remand. */

UPDATE FolderProcess
   SET FolderProcess.Startdate = @InDate,
       FolderProcess.EndDate = @DecisionDate
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessRSN = @ProcessRSN

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10018             /* Appeal Clock */
   AND FolderProcess.StatusCode = 1

   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
          FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = NULL, 
          FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
          FolderProcess.ProcessComment = NULL
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode = 10008       /* Initiate Appeal */

IF @AttemptResult = 10048
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.StatusCode = 1
END

GO
