USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_UC_00023003]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_UC_00023003]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/* Unified Certificate of Occupancy 23003 (version 1) */

/* Checks that all associated permits have individual CO's and adds UCO Document. */
/* The total processing time is recorded in FolderProcess.StartDate and EndDate. */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @StatusCode int
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @InDate datetime
DECLARE @IssueDate datetime

/* Get attempt result and folder values, and do some error checking.  */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType, 
       @StatusCode = Folder.StatusCode, 
       @InDate = Folder.InDate, 
       @IssueDate = Folder.IssueDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

IF @AttemptResult = 23004     /* Issue UCO */
BEGIN
   IF @SubCode = 23002 OR @WorkCode = 23002
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Associated permits are not all ready for UCO issuance. UCO can not be issued.', 16, -1)
      RETURN
   END

   UPDATE Folder
      SET Folder.IssueDate = getdate(), Folder.ExpiryDate = NULL, 
          Folder.FinalDate = getdate(), Folder.IssueUser = @UserID, 
          Folder.StatusCode = 23005, 
          Folder.FolderCondition = 
             CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),FolderCondition)) + 
             ' -> Project Approved for UCO Issuance (' + 
             CONVERT(CHAR(11), getdate()) + ')' ))
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'UCO Issued',
           FolderProcess.StartDate = @InDate, FolderProcess.EndDate = getdate(), 
           FolderProcess.SignOffUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Issued (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Close all open processes. */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2, FolderProcess.SignOffUser = @UserID
 WHERE FolderProcess.StatusCode = 1
   AND FolderProcess.ProcessCode IN (23001, 23002, 23003, 23004, 23005)
   AND FolderProcess.FolderRSN = @FolderRSN

GO
