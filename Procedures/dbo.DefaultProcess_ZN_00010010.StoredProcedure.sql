USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZN_00010010]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZN_00010010]
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
/* Non-Applicability Request (10010) */

DECLARE @AttemptResult int
DECLARE @AdminDecisionDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime
DECLARE @InDate datetime
DECLARE @varFolderCondition varchar(2000)
DECLARE @varDecisionText varchar(200)
DECLARE @varLogText varchar(2000)
DECLARE @NextStatusCode int
DECLARE @PermitPickedupInfoOrder int
DECLARE @PermitPickedupInfoField int
DECLARE @PermitPickedupInfoValue varchar(10)

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

/* Get decision date, and set appeal period expiration date. */

SELECT @AdminDecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10055               /* Admin Decision Date */

IF @AdminDecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Admin Decision Date (Info) to proceed', 16, -1)
   RETURN
END

SELECT @InDate = Folder.InDate,
       @varFolderCondition = Folder.FolderCondition
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

IF @InDate > @AdminDecisionDate 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('The In Date is greater than the Admin Decision Date. Please correct to proceed.', 16, -1)
   RETURN
END

SELECT @DecisionDate = @AdminDecisionDate
SELECT @ExpiryDate = DATEADD(Day, 15, @DecisionDate)   /* Appeal period for administrative review */

/* Set next Folder.StatusCode according to attempt result. */

SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @AttemptResult)

/* Set up text for log in FolderCondition */

SET @varDecisionText = 'Error'

IF @AttemptResult = 10017 
   SELECT @varDecisionText = 'Decision: Request Does Not Require a Zoning Permit (' + CONVERT(CHAR(11), @DecisionDate) + ')'

IF @AttemptResult = 10018
   SELECT @varDecisionText = 'Decision: Request Requires a Zoning Permit (' + CONVERT(CHAR(11), @DecisionDate) + ')'

IF @varFolderCondition IS NULL
   SELECT @varLogText = @varDecisionText
ELSE 
   SELECT @varLogText = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),@varFolderCondition)) + @varDecisionText))

/* Request is determined to be non-applicable (permit not required), update folder 
   status */

IF @AttemptResult = 10017                    /* Permit Not Required i.e. Approved */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = @varLogText
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Non-App Form Issued',
          FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
      WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

END

/* Request is determined to be applicable (permit required), update folder status */

IF @AttemptResult = 10018                    /* Permit Required i.e. Denied */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = @varLogText
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Non-App Form Not Issued',
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = @UserID
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN
END

/* Update Project Manager Info field. */

EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Check for existence of FolderInfo Permit Picked Up (10023), insert if needed, 
   and code. */

SELECT @PermitPickedupInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10023) 
SELECT @PermitPickedupInfoOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10023)
SELECT @PermitPickedupInfoValue = dbo.udf_GetZoningPermitPickedUp(@FolderRSN)

IF @PermitPickedupInfoField = 0 
BEGIN
   INSERT INTO FolderInfo
             ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
               InfoValue, InfoValueUpper, 
               StampDate, StampUser, Mandatory, ValueRequired )
      VALUES ( @FolderRSN, 10023,  @PermitPickedupInfoOrder, 'Y', 
               @PermitPickedupInfoValue, UPPER(@PermitPickedupInfoValue), 
               getdate(), @UserID, 'N', 'N' )
END
ELSE
BEGIN
   UPDATE FolderInfo
      SET FolderInfo.InfoValue = @PermitPickedupInfoValue, 
          FolderInfo.InfoValueUpper = UPPER(@PermitPickedupInfoValue) 
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10023
END 

/* Insert a BP folder when Non-App is approved (Permit Not Required) */

IF ( @PermitPickedupInfoValue IN ('Mailed', 'Yes') AND @AttemptResult = 10017 ) 
   EXECUTE dbo.usp_Zoning_Insert_BP_Folder @FolderRSN, @UserID 


GO
