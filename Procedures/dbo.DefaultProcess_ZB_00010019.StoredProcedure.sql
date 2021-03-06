USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010019]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010019]
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
   
/* Abandon Permit (10019) version 1 */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @NextStatusCode int
DECLARE @InDate datetime
DECLARE @IssueDate datetime
DECLARE @ZPNumber varchar(10)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @NextWorkCode int
DECLARE @ParentRSN int
DECLARE @PropertyRSN int
DECLARE @ConstructionStartDeadline datetime
DECLARE @PermitExpirationDate datetime
DECLARE @DRFCount int

/* Get attempt result. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode, 
       @AttemptDate = FolderProcessAttempt.AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       (SELECT max(FolderProcessAttempt.AttemptRSN) 
          FROM FolderProcessAttempt
         WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

/* Get Folder Type, Folder Status, Application Date, ZP Number, SubCode, WorkCode. 
   Get Permit Expiration date*/

SELECT @FolderType = Folder.FolderType, @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate, @IssueDate = Folder.IssueDate,
       @ZPNumber = Folder.ReferenceFile, @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode 
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @ConstructionStartDeadline = ISNULL(FolderInfo.InfoValueDateTime, '1909-09-09 00:00:00.000')
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10127

SELECT @PermitExpirationDate = ISNULL(FolderInfo.InfoValueDateTime, '1909-09-09 00:00:00.000')
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10024

/* Owner does not intend to build project but permit expiration date has not passed. 
   It is not clear how to handle Variances. The Permit Expiration Date is used for 
   the validity test because the City does not check projects to determine if the 
   Construction Start Deadline was met. */

IF @AttemptResult = 10041                   /* Relinquish Permit */
BEGIN
   IF @PermitExpirationDate < getdate() 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR('Only valid (not expired) permits may be Relinquished. Choose Permit Expired instead.', 16, -1)
      RETURN
   END

   UPDATE Folder
      SET Folder.StatusCode = 10024, Folder.FinalDate = getdate(), Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Permit Relinquished by Owner (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Relinquished',
           FolderProcess.ScheduleDate = getdate(),FolderProcess.StartDate = NULL, 
           FolderProcess.EndDate = NULL, FolderProcess.AssignedUser = @UserID
  WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Relinquished (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
   ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Permit is superseded by another: Update folder status, and close everything out. */
/* Jun 30, 2009 - Improvement:  Add a ProcessInfo field for the FolderRSN of the 
   permit that is superseding the current one, force its entry, and then code that 
   value to Folder.ParentRSN. */ 

IF @AttemptResult = 10049                   /* Supersede Permit */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10028, Folder.FinalDate = getdate(), Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Permit Superseded by a Subsequent Permit (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Superseded',
           FolderProcess.ScheduleDate = getdate(), FolderProcess.StartDate = NULL, 
           FolderProcess.EndDate = NULL, FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Superseded (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Permit Expired - Permit expiration date has passed and project not built. */

IF @AttemptResult = 10050             /* Permit Expired */
BEGIN
   IF @PermitExpirationDate > getdate() 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR('Permit is still valid: Expiration date has not passed. Owner may want it Relinquished.', 16, -1)
      RETURN
   END

   UPDATE Folder
      SET Folder.StatusCode = 10037, Folder.FinalDate = getdate(), Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Project Not Built and Permit Expired (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Permit Expired on ' + CONVERT(char(11), @PermitExpirationDate),
           FolderProcess.ScheduleDate = getdate(), FolderProcess.StartDate = NULL, 
           FolderProcess.EndDate = NULL, FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* Cancel any unpaid Development Review Fees where appropriate. */

IF @AttemptResult IN (10041, 10050)     /* Relinquish and Expired */
BEGIN
   SELECT @DRFCount = COUNT(*)
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBillFee.FeeCode IN (145, 146)
      AND AccountBill.PaidInFullFlag = 'N'
      AND Folder.FolderRSN = @FolderRSN

   IF @DRFCount > 0 
   BEGIN 
      UPDATE AccountBill
         SET AccountBill.PaidInFullFlag = 'C'
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBillFee.FeeCode IN (145, 146)
         AND AccountBill.PaidInFullFlag = 'N'
         AND Folder.FolderRSN = @FolderRSN
   END
END

/* Close any open processes. */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.StatusCode = 1 


GO
