USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020051]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020051]
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
/* Municipal Complaint Ticket (20051) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @ExpiryDate datetime

DECLARE @AppealableDecisionInfoOrder int
DECLARE @DRBAppealDateInfoOrder int
DECLARE @VECAppealDateInfoOrder int
DECLARE @MuniTicket1DateInfoOrder int
DECLARE @MuniTicket1DateInfoField int
DECLARE @MuniTicket1DateInfoValue datetime
DECLARE @MuniTicket2DateInfoOrder int
DECLARE @MuniTicket2DateInfoField int
DECLARE @MuniTicket2DateInfoValue datetime
DECLARE @MuniTicket3DateInfoOrder int
DECLARE @MuniTicket3DateInfoField int
DECLARE @MuniTicket3DateInfoValue datetime

DECLARE @TicketingStep int

/* Get Attempt Result */

SELECT @AttemptResult = ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode, WorkCode values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Set Info field display orders, check for existence, set ticketing step. */

SELECT @AppealableDecisionInfoOrder = ISNULL(FolderInfo.DisplayOrder, 200)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

SELECT @DRBAppealDateInfoOrder   = @AppealableDecisionInfoOrder + 10
SELECT @VECAppealDateInfoOrder   = @AppealableDecisionInfoOrder + 20
SELECT @MuniTicket1DateInfoOrder = @AppealableDecisionInfoOrder + 30
SELECT @MuniTicket2DateInfoOrder = @AppealableDecisionInfoOrder + 40
SELECT @MuniTicket3DateInfoOrder = @AppealableDecisionInfoOrder + 50

SELECT @MuniTicket1DateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20060

SELECT @MuniTicket2DateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20069

SELECT @MuniTicket3DateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20070

SELECT @TicketingStep = 
CASE
   WHEN @MuniTicket2DateInfoField = 0 THEN 1
   WHEN @MuniTicket2DateInfoField > 0 AND @MuniTicket3DateInfoField = 0 THEN 2
   WHEN @MuniTicket3DateInfoField > 0 THEN 3
   ELSE 1
END

/* Issue First Ticket attempt result. */

IF @AttemptResult = 20096
BEGIN

   IF @TicketingStep <> 1
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose a different attempt result to continue.', 16, -1)
      RETURN
   END

   SELECT @MuniTicket1DateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20060

   IF @MuniTicket1DateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Municipal Complaint Ticket 1 Date Info field to continue.', 16, -1)
      RETURN
   END

   SELECT @ExpiryDate = @MuniTicket1DateInfoValue + 5

   UPDATE Folder
      SET Folder.WorkCode = 20113, Folder.IssueDate = @MuniTicket1DateInfoValue, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> First Municipal Complaint Ticket Issued (' + CONVERT(char(11), @MuniTicket1DateInfoValue) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'First Municipal Complaint Ticket Issued',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'First Municipal Complaint Ticket Issued (' + CONVERT(char(11), @MuniTicket1DateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @MuniTicket2DateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20069, @MuniTicket2DateInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

END     /* end of Issue First Ticket attempt result */

/* Issue Second Ticket attempt result. */

IF @AttemptResult = 20114
BEGIN

   IF @TicketingStep <> 2
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose a different attempt result to continue.', 16, -1)
      RETURN
   END

   SELECT @MuniTicket2DateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20069

   IF @MuniTicket2DateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Municipal Complaint Ticket 2 Date Info field to continue.', 16, -1)
      RETURN
   END

   SELECT @ExpiryDate = @MuniTicket2DateInfoValue + 5

   UPDATE Folder
      SET Folder.WorkCode = 20113, Folder.IssueDate = @MuniTicket2DateInfoValue, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Second Municipal Complaint Ticket Issued (' + CONVERT(char(11), @MuniTicket2DateInfoValue) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Second Municipal Complaint Ticket Issued',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Second Municipal Complaint Ticket Issued (' + CONVERT(char(11), @MuniTicket2DateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @MuniTicket3DateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20070, @MuniTicket3DateInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

END     /* end of Issue Second Ticket attempt result */

/* Issue Third Ticket attempt result. */

IF @AttemptResult = 20115
BEGIN

   IF @TicketingStep <> 3
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose a different attempt result to continue.', 16, -1)
      RETURN
   END

   SELECT @MuniTicket3DateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20070

   IF @MuniTicket3DateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Municipal Complaint Ticket 3 Date Info field to continue.', 16, -1)
 RETURN
   END

   SELECT @ExpiryDate = @MuniTicket3DateInfoValue + 5

   UPDATE Folder
      SET Folder.WorkCode = 20113, Folder.IssueDate = @MuniTicket3DateInfoValue, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Third Municipal Complaint Ticket Issued (' + CONVERT(char(11), @MuniTicket3DateInfoValue) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Third Municipal Complaint Ticket Issued',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Third Municipal Complaint Ticket Issued (' + CONVERT(char(11), @MuniTicket3DateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END     /* end of Issue Third Ticket attempt result */

/* Reopen process for first and second tickets. */

IF @AttemptResult IN(20096, 20114)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, 
          FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessCode = 20051
      AND FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN
END

GO
