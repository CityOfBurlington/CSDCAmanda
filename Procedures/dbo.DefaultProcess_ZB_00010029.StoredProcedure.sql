USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010029]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010029]
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
/* Appeal to VT Supreme Court (10029) version 1 */

DECLARE @AttemptResult int
DECLARE @DecisionDate datetime
DECLARE @FolderType varchar(2)
DECLARE @StatusCode int
DECLARE @InDate datetime
DECLARE @ExpiryDate datetime
DECLARE @PermitExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @NextStatusCode int
DECLARE @DecisionProcessRSN int
DECLARE @DecisionProcessCode int
DECLARE @DecisionAttemptResult int
DECLARE @DecisionOverturnAttemptResult int
DECLARE @DecisionOverturnProcessText varchar(40)
DECLARE @NextDecisionAttemptRSN int
DECLARE @DecisionText varchar(100)
DECLARE @PermitPickedupInfoOrder int
DECLARE @PermitPickedupInfoField int
DECLARE @InitiateAppealAttemptResult int

/* Get Attempt Result, Folder and Parent folder info */

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

SELECT @PermitPickedupInfoOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10023)

SELECT @PermitPickedupInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10023) 

/* Folder status must be Appealed to SC for process to run. */

IF @StatusCode <> 10036
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Folder status must be Appealed to SC in order to proceed.', 16, -1)
   RETURN
END

/* Get Decision process attempt result. Set a reversed Decision process attempt 
   result code. The reversed decision code will be inserted into the decision 
   process by the Grant Appeal (overturn) attempt result. */

SELECT @DecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@FolderRSN)

SELECT @DecisionAttemptResult = dbo.udf_GetZoningDecisionAttemptCode(@FolderRSN)

SELECT @DecisionText = dbo.udf_GetZoningDecisionAttemptText(@FolderRSN, @DecisionAttemptResult)

SELECT @NextDecisionAttemptRSN = dbo.udf_GetZoningDecisionNextAttemptRSN(@FolderRSN) 

SELECT @DecisionProcessRSN = dbo.udf_GetZoningDecisionProcessRSN(@FolderRSN)

SELECT @DecisionOverturnAttemptResult = dbo.udf_GetZoningDecisionOverturnAttemptResult(@FolderRSN)

SELECT @DecisionOverturnProcessText = dbo.udf_GetZoningDecisionOverturnAttemptText(@FolderRSN)

/* Check to make sure the Info field Supreme Court Appeal Decision Date has 
   been entered. If it is null, issue error message and end processing. */

SELECT @DecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10080                 /* SC Appeal Decision Date */

IF @DecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Supreme Court Appeal Decision Date (Info) to proceed', 16, -1)
   RETURN
END

/* Set appeal period expiration date (30 days for SC decisions). */

SELECT @ExpiryDate = DATEADD(day, 30, @DecisionDate)

/* Update FolderInfo Permit Expiration Date and Construction Start Deadline 
   where applicable. */

   EXECUTE dbo.usp_Zoning_Permit_Expiration_Dates @FolderRSN, @DecisionDate

/* Record review decision, and update folder status */

IF @AttemptResult = 10062        /* Uphold VEC Decision */
BEGIN
   IF @FolderType = 'ZL' SELECT @NextStatusCode = 10003
   ELSE SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @DecisionAttemptResult)

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Decision: Uphold VEC ' + RTRIM(@DecisionText) + ' (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderProcess
          SET FolderProcess.ProcessComment = RTRIM(@DecisionText) + ' Decision Upheld',
              FolderProcess.StartDate = @DecisionDate,
              FolderProcess.EndDate = @ExpiryDate
        WHERE FolderProcess.FolderRSN = @FolderRSN
          AND FolderProcess.ProcessRSN = @ProcessRSN
END

IF @AttemptResult = 10063        /* Overturn VEC Decision */
BEGIN
   IF @FolderType = 'ZL' SELECT @NextStatusCode = 10002
   ELSE SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @DecisionOverturnAttemptResult)

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Decision: Overturn VEC ' + rtrim(@DecisionText) + ' (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = RTRIM(@DecisionText) + ' Decision Overturned',
          FolderProcess.StartDate = @DecisionDate,
          FolderProcess.EndDate = @ExpiryDate
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN

   IF @DecisionOverturnAttemptResult > 0 AND @FolderType <> 'ZL'
   BEGIN
      INSERT INTO FolderProcessAttempt
                ( AttemptRSN, FolderRSN, ProcessRSN, 
                  ResultCode, 
                  AttemptComment, 
          AttemptBy, AttemptDate, StampUser, StampDate )
         VALUES ( @NextDecisionAttemptRSN, @folderRSN, @DecisionProcessRSN, 
                  @DecisionOverturnAttemptResult, 
                  'Overturned on Supreme Court Appeal (' + CONVERT(CHAR(11), @DecisionDate) + ')', 
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
            SET StatusCode = 2, EndDate = getdate() 
          WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 10006
            AND FolderProcess.StatusCode = 1 
      END

      IF @PermitPickedupInfoField = 0 AND @DecisionOverturnAttemptResult IN(10003, 10011, 10046)
      BEGIN
         INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     InfoValue, InfoValueUpper, 
                     StampDate, StampUser, Mandatory, ValueRequired )
            VALUES ( @FolderRSN, 10023,  @PermitPickedupInfoOrder, 'Y', 
                     'No', 'NO', 
                     getdate(), @UserID, 'N', 'N' )
      END

      IF @PermitPickedupInfoField > 0 AND @DecisionOverturnAttemptResult IN(10002, 10020, 10047)
      BEGIN
         DELETE FROM FolderInfo
               WHERE FolderInfo.FolderRSN = @FolderRSN
                 AND FolderInfo.InfoCode = 10023
      END
   END
END

/* Update Project Manager Info field. */

EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Record gross review time in Appeal to SC process. 
   Reopen Initiate Appeal (10008) process. */

UPDATE FolderProcess
   SET FolderProcess.Startdate = @InDate,
       FolderProcess.EndDate = @DecisionDate
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessRSN = @ProcessRSN

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
       FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = NULL, 
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
       FolderProcess.ProcessComment = NULL
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10008       /* Initiate Appeal */


GO
