USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020046]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020046]
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
/* Zoning Investigation (20046) version 2 */

/* Process sets up the folder using attempt results. 
   Appeals are enabled for the Complaint Unfounded (20089) and Send Notice of 
   Violation (20095) attempt results. */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @FolderConditions varchar(2000)
DECLARE @InspectorInfoValue varchar(30)

DECLARE @SCMemoTermInfoValue int
DECLARE @SCMemoDateInfoValue datetime
DECLARE @ShowCauseProcess int
DECLARE @ShowCauseProcessOrder int
DECLARE @ShowCauseDoc int
DECLARE @ShowCauseDocDisplayOrder int
DECLARE @ShowCauseDocNotGenerated int
DECLARE @ReviewRequestsProcess int
DECLARE @ReviewRequestsProcessOrder int

DECLARE @InvestigationFormDoc int
DECLARE @InvestigationFormDocDisplayOrder int
DECLARE @InvestigationFormDocNotGenerated int

DECLARE @ComplainantLetterAcknowledgeDoc int
DECLARE @ComplainantLetterAcknowledgeDocDisplayOrder int
DECLARE @ComplainantLetterAcknowledgeDocNotGenerated int

DECLARE @ComplainantLetterUnfoundedDoc  int
DECLARE @ComplainantLetterUnfoundedDocDisplayOrder int
DECLARE @ComplainantLetterUnfoundedDocNotGenerated int

DECLARE @NoticeofViolationDoc int
DECLARE @NoticeofViolationDocDisplayOrder int
DECLARE @NoticeofViolationDocNotGenerated int

DECLARE @IVDecisionDateInfoValue datetime
DECLARE @ExpiryDate datetime

DECLARE @AppealableDecisionInfoOrder int
DECLARE @InvestigationProcessOrder int
DECLARE @DRBAppealDateInfoOrder int
DECLARE @VECAppealDateInfoOrder int
DECLARE @MuniTicket1DateInfoOrder int
DECLARE @MuniTicket1DateInfoField int
DECLARE @MuniTicketProcess int
DECLARE @MuniTicketProcessOrder int
DECLARE @ViolationProcess int
DECLARE @ViolationProcessOrder int

DECLARE @AddInitiateAppealProcess varchar(1)
DECLARE @InitiateAppealProcess int
DECLARE @InitiateAppealProcessOrder int
DECLARE @InitiateAppealProcessAttempt int

DECLARE @AttemptFolderNote varchar(100)

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode, WorkCode, and 
   Condition values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode,
       @FolderConditions = Folder.FolderCondition
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Set which attempt results may be appealed (adds Initiate Appeal). */

SELECT @AddInitiateAppealProcess = 
  CASE @AttemptResult
     WHEN 20089 THEN 'Y'       /* Complaint Unfounded */
     WHEN 20095 THEN 'Y'       /* Send Notice of Violation */
     WHEN 20090 THEN 'N'       /* Complaint Rectified */
     WHEN 20097 THEN 'N'       /* Issue Municipal Complaint Ticket */
     WHEN 20106 THEN 'N'       /* Send Show Cause Memo */
     WHEN 20107 THEN 'N'       /* Complaint Unsubstantiated */
     WHEN 20134 THEN 'N'       /* Send Complaintant Letter */
  END

/* Get Investigation Decision Date Info field value, set expiry date to plus 15 days 
   for all attempt results except for Send Show Cause Memo (20106), and 
   Send Complainant Letter (20134) */

IF @AttemptResult IN(20089, 20090, 20095, 20107)
BEGIN
   SELECT @IVDecisionDateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20059

   IF @IVDecisionDateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Investigation Decision Date Info field to continue.', 16, -1)
      RETURN
   END

   SELECT @ExpiryDate = @IVDecisionDateInfoValue + 15
END

IF @AttemptResult = 20106            /* Send Show Cause Memo */
BEGIN
   SELECT @SCMemoDateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20052

   SELECT @SCMemoTermInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 10)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20064

   IF @SCMemoDateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Show Cause Memo Date Info field to continue.', 16, -1)
      RETURN
   END

   SELECT @ExpiryDate = @SCMemoDateInfoValue + @SCMemoTermInfoValue
END

/* Check for Info field existence, set Info field display orders */

SELECT @AppealableDecisionInfoOrder = ISNULL(FolderInfo.DisplayOrder, 200)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

SELECT @DRBAppealDateInfoOrder   = @AppealableDecisionInfoOrder + 10
SELECT @VECAppealDateInfoOrder   = @AppealableDecisionInfoOrder + 20
SELECT @MuniTicket1DateInfoOrder = @AppealableDecisionInfoOrder + 30

SELECT @MuniTicket1DateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20060

/* Set Show Cause Memo Response, Initiate Appeal, and other process orders, and 
   check for their existence */

SELECT @InvestigationProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20046

SELECT @ShowCauseProcessOrder      = @InvestigationProcessOrder + 10
SELECT @ReviewRequestsProcessOrder = @InvestigationProcessOrder + 20
SELECT @InitiateAppealProcessOrder = @InvestigationProcessOrder + 60
SELECT @MuniTicketProcessOrder     = @InvestigationProcessOrder + 80
SELECT @ViolationProcessOrder      = @InvestigationProcessOrder + 90

SELECT @ShowCauseProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20042

SELECT @ReviewRequestsProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20052

SELECT @InitiateAppealProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20050

SELECT @MuniTicketProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20051

SELECT @ViolationProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20047

/* Get and set Investigation Form, Show Cause Memo, Complainant Letter, and Notice of Violation 
   document info. */

SELECT @InvestigationFormDoc = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20005

SELECT @ComplainantLetterAcknowledgeDoc  = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20004

SELECT @ShowCauseDoc = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20001

SELECT @ComplainantLetterUnfoundedDoc  = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20002

SELECT @NoticeofViolationDoc = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20003

SELECT @ShowCauseDocNotGenerated = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20001
   AND FolderDocument.DateGenerated IS NULL

SELECT @ComplainantLetterAcknowledgeDocNotGenerated = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20004
   AND FolderDocument.DateGenerated IS NULL

SELECT @ComplainantLetterUnfoundedDocNotGenerated = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20002
   AND FolderDocument.DateGenerated IS NULL

SELECT @NoticeofViolationDocNotGenerated = ISNULL(count(*), 0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20003
   AND FolderDocument.DateGenerated IS NULL

SELECT @InvestigationFormDocDisplayOrder = ISNULL(FolderDocument.DisplayOrder, 10)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20005

SELECT @ComplainantLetterAcknowledgeDocDisplayOrder =  10 + @InvestigationFormDocDisplayOrder
SELECT @ShowCauseDocDisplayOrder = 20 + @InvestigationFormDocDisplayOrder
SELECT @ComplainantLetterUnfoundedDocDisplayOrder = 30 + @InvestigationFormDocDisplayOrder
SELECT @NoticeofViolationDocDisplayOrder = 40 + @InvestigationFormDocDisplayOrder

/* Send Complainant Letter attempt result */

IF @AttemptResult = 20134 
BEGIN

   SELECT @InspectorInfoValue = FolderInfo.InfoValue
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20009

   IF  @InspectorInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please assign an Inspector from Info to continue.', 16, -1)
      RETURN
   END

   IF @FolderConditions IS NULL 
      SELECT @AttemptFolderNote = 'Complaint Received -> Send Acknowledgement Letter (' + CONVERT(char(11), getdate()) + ')'
   ELSE
      SELECT @AttemptFolderNote = ' -> Send Acknowledgement Letter (' + CONVERT(char(11), getdate()) + ')'

   UPDATE Folder
          SET Folder.WorkCode = 20132, 
                 Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Send Complaint Acknowledgement Letter',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Send Acknowledgement Letter (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
             FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @ReviewRequestsProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
            ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20052, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @ReviewRequestsProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @ReviewRequestsProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20052
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @ComplainantLetterAcknowledgeDoc = 0 OR @ComplainantLetterAcknowledgeDocNotGenerated = 0
  BEGIN
      SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
        FROM FolderDocument
      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
          DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 20004, 1, @NextDocumentRSN, @ComplainantLetterAcknowledgeDocDisplayOrder, getdate(), @UserID, 1 )  
   END

END

/* Send Show Cause Memo attempt result */

IF @AttemptResult = 20106 
BEGIN

   IF @FolderConditions IS NULL 
      SELECT @AttemptFolderNote = 'Complaint Received -> Send Show Cause Memo (' + CONVERT(char(11), @SCMemoDateInfoValue) + ')'
   ELSE
      SELECT @AttemptFolderNote = ' -> Send Show Cause Memo (' + CONVERT(char(11), @SCMemoDateInfoValue) + ')'

   UPDATE Folder
      SET Folder.WorkCode = 20100, 
          Folder.IssueDate = @SCMemoDateInfoValue, Folder.ExpiryDate = @ExpiryDate, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
  WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Send Show Cause Memo',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Send Show Cause Memo (' + CONVERT(char(11), @SCMemoDateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
             FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @ShowCauseProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
      ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20042, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @ShowCauseProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @ShowCauseProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
  WHERE FolderProcess.ProcessCode = 20042
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @ReviewRequestsProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
            ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20052, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @ReviewRequestsProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @ReviewRequestsProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20052
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @ShowCauseDoc = 0 OR @ShowCauseDocNotGenerated = 0
   BEGIN
      SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
        FROM FolderDocument
      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
          DisplayOrder, StampDate, StampUser, LinkCode )
     VALUES ( @FolderRSN, 20001, 1, @NextDocumentRSN, @ShowCauseDocDisplayOrder, getdate(), @UserID, 1 )  
   END

END    /* end of Show Cause Memo Sent attempt result */

/* Complaint Unfounded attempt result. Decision enables appeal. */

IF @AttemptResult = 20089
BEGIN
   IF @FolderConditions IS NULL 
      SELECT @AttemptFolderNote = 'Complaint Received -> Decision: Complaint Unfounded (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'
   ELSE 
      SELECT @AttemptFolderNote = ' -> Decision: Complaint Unfounded (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'

   IF @SubCode = 20059       /* For Initial Assessment stage */
   BEGIN
      UPDATE Folder
         SET Folder.SubCode = 20060, Folder.WorkCode = 20119,
             Folder.IssueDate = @IVDecisionDateInfoValue, Folder.ExpiryDate = @ExpiryDate, 
             Folder.IssueUser = @UserId,
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
       WHERE Folder.FolderRSN = @folderRSN
   END
   ELSE                      /* Formal investigation stage */
   BEGIN
      UPDATE Folder
         SET Folder.SubCode = 20064, Folder.WorkCode = 20119,
             Folder.IssueDate = @IVDecisionDateInfoValue, Folder.ExpiryDate = @ExpiryDate, 
             Folder.IssueUser = @UserId,
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
       WHERE Folder.FolderRSN = @folderRSN
   END

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Complaint Unfounded',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Complaint Unfounded (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
             FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = 'Investigation - Complaint Unfounded', 
          FolderInfo.InfoValueUpper = UPPER('Investigation - Complaint Unfounded')
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20068

   IF @ComplainantLetterUnfoundedDoc  = 0 OR @ComplainantLetterUnfoundedDocNotGenerated = 0
   BEGIN
      SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
        FROM FolderDocument
      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                  DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 20002, 1, @NextDocumentRSN, 
                  @ComplainantLetterUnfoundedDocDisplayOrder, getdate(), @UserID, 1 )  
   END

END    /* end of Complaint Unfounded attempt result */

/* Complaint Unsubstantiated attempt result. This is where staff can not determine 
   whether a violation does, or does not, exist. */

IF @AttemptResult = 20107
BEGIN
   IF @FolderConditions IS NULL 
      SELECT @AttemptFolderNote = 'Complaint Received -> Complaint Unsubstantiated (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'
   ELSE 
      SELECT @AttemptFolderNote = ' -> Complaint Unsubstantiated (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'

   IF @SubCode = 20059       /* For Initial Assessment stage - no appeal period */
   BEGIN
      UPDATE Folder
         SET Folder.SubCode = 20060, Folder.WorkCode = 20118,
             Folder.IssueDate = @IVDecisionDateInfoValue, 
             Folder.ExpiryDate = @IVDecisionDateInfoValue, 
             Folder.IssueUser = @UserId,
  Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
       WHERE Folder.FolderRSN = @folderRSN
   END
   ELSE   /* Formal investigation stage - no appeal period */
   BEGIN
      UPDATE Folder
         SET Folder.SubCode = 20064, Folder.WorkCode = 20118,
             Folder.IssueDate = @IVDecisionDateInfoValue, Folder.ExpiryDate = @IVDecisionDateInfoValue, 
             Folder.FinalDate = getdate(), Folder.IssueUser = @UserId,
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
       WHERE Folder.FolderRSN = @folderRSN
   END

    UPDATE FolderProcess
     SET FolderProcess.ProcessComment = 'Complaint Unsubstantiated',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Complaint Unsubstantiated (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
             FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of Complaint Unsubstantiated attempt result */

/* Complaint Rectified attempt result. This closes everything out. */

IF @AttemptResult = 20090
BEGIN
   IF @FolderConditions IS NULL 
      SELECT @AttemptFolderNote = 'Complaint Received -> Complaint Rectified (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'
   ELSE 
      SELECT @AttemptFolderNote = ' -> Complaint Rectified (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'

   IF @SubCode = 20059       /* For Initial Assessment stage - no appeal period */
   BEGIN
      UPDATE Folder
         SET Folder.SubCode = 20060, Folder.WorkCode = 20108,
             Folder.IssueDate = @IVDecisionDateInfoValue, Folder.ExpiryDate = @IVDecisionDateInfoValue, 
             Folder.FinalDate = getdate(), Folder.IssueUser = @UserId,
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
       WHERE Folder.FolderRSN = @folderRSN
   END
   ELSE                      /* Formal investigation stage - no appeal period */
   BEGIN
      UPDATE Folder
         SET Folder.SubCode = 20064, Folder.WorkCode = 20108, 
             Folder.IssueDate = @IVDecisionDateInfoValue, 
             Folder.ExpiryDate = @IVDecisionDateInfoValue, 
             Folder.IssueUser = @UserId,
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
       WHERE Folder.FolderRSN = @folderRSN
   END

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Complaint Rectified',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Complaint Rectified (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')', 
       FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of Complaint Rectified attempt result */

/* Send Notice of Violation attempt result. Enables appeal. Adds Violation process. */

IF @AttemptResult = 20095
BEGIN
   IF @FolderConditions IS NULL 
      SELECT @AttemptFolderNote = 'Complaint Received -> Complaint Verified -> Send Notice of Violation (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'
   ELSE 
      SELECT @AttemptFolderNote = ' -> Complaint Verified -> Send Notice of Violation (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')'

   UPDATE Folder
      SET Folder.SubCode = 20064, Folder.WorkCode = 20120,
          Folder.IssueDate = @IVDecisionDateInfoValue, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + @AttemptFolderNote))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Complaint Verified -> Send Notice of Violation',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Send Notice of Violation (' + CONVERT(char(11), @IVDecisionDateInfoValue) + ')', 
       FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
   ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = 'Investigation - Notice of Violation', 
          FolderInfo.InfoValueUpper = UPPER('Investigation - Notice of Violation')
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20068

   IF @ViolationProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
            ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20047, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @ViolationProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @ViolationProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20047
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @ReviewRequestsProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
            ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20052, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @ReviewRequestsProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @ReviewRequestsProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20052
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @NoticeofViolationDoc = 0 OR @NoticeofViolationDocNotGenerated = 0
   BEGIN
      SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
        FROM FolderDocument
      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                  DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 20003, 1, @NextDocumentRSN, @NoticeofViolationDocDisplayOrder, getdate(), @UserID, 1 )  
   END

END    /* end of Send Notice of Violation attempt result */

/* Issue Municipal Complaint Ticket attempt result (20097) removed  - see version 1.  */

/* Add Initiate Appeal process where appropriate. */

IF @AddInitiateAppealProcess = 'Y'
BEGIN
   IF @InitiateAppealProcess = 0
   BEGIN
  SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
            ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20050, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @InitiateAppealProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @InitiateAppealProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20050
         AND FolderProcess.FolderRSN = @folderRSN
   END
END

/* Close this process for Complaint Unfounded, Send NOV attempt results.
   Close everything out for Complaint Unsubstantiated, Complaint Rectified attempt 
   results. 
   Re-open for Send Show Cause Memo, Send Complainant Letter, and 
   Issue Municipal Complaint Ticket attempt results. */

IF @AttemptResult IN(20089, 20095)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), 
          FolderProcess.BaseLineEndDate = getdate(), 
          FolderProcess.SignOffUser = @UserID
    WHERE FolderProcess.ProcessCode IN(20042, 20046, 20043, 20044, 20045, 20052)
      AND FolderProcess.FolderRSN = @folderRSN
END

IF @AttemptResult IN(20090, 20107)
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 2, Folder.FinalDate = getdate()
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), 
          FolderProcess.BaseLineEndDate = getdate(), 
          FolderProcess.SignOffUser = @UserID
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.FolderRSN = @folderRSN
END

IF @AttemptResult IN(20097, 20106, 20134)
BEGIN
 UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, 
          FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessCode IN(20042, 20046, 20051, 20052)
      AND FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN
END

GO
