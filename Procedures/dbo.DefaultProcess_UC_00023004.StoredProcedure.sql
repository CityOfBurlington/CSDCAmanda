USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_UC_00023004]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_UC_00023004]
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
   
/* Temp Certificate of Occupancy - Unified (version 1) */

DECLARE @AttemptResult int
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @TCOTermInfoCode int
DECLARE @TCOTermInfoValue int
DECLARE @TCODecisionDateInfoCode int
DECLARE @TCODecisionDateInfoValue datetime
DECLARE @TCOExpiryDateInfoCode int
DECLARE @TCOExpiryDateInfoValue datetime
DECLARE @TCOConditionsDateInfoCode int
DECLARE @TCOConditionsDateInfoValue datetime
DECLARE @TCOFee float

/* Get attempt result. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       (SELECT MAX(FolderProcessAttempt.AttemptRSN) 
          FROM FolderProcessAttempt
         WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

/* Check to make sure any building permits are ready for UCO issuance. */

SELECT @SubCode = Folder.SubCode, 
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

IF @SubCode = NULL OR @WorkCode = NULL 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Run the Permit Status Report in order to proceed.', 16, -1)
   RETURN
END

IF @WorkCode = 23002		/* Building Not Ready */
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please run Permit Status Check to proceed, or if it has been run, Building Permit(s) must be Ready for UCO Issuance in order to issue a TCO.', 16, -1)
   RETURN
END

IF @SubCode <> 23004		/* Zoning TCO Ready */
BEGIN
	ROLLBACK TRANSACTION
	RAISERROR ('Please run Permit Status Check to proceed, or if it has been run, no Zoning Permits are ready for a TCO.', 16, -1)
	RETURN
END

/* Check TCO Info fields, get values. */

SELECT @TCOTermInfoCode = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.InfoCode = 23031
   AND FolderInfo.FolderRSN = @FolderRSN

SELECT @TCODecisionDateInfoCode = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.InfoCode = 23032
   AND FolderInfo.FolderRSN = @FolderRSN

SELECT @TCOExpiryDateInfoCode = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.InfoCode = 23033
   AND FolderInfo.FolderRSN = @FolderRSN

SELECT @TCOConditionsDateInfoCode = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.InfoCode = 23034
   AND FolderInfo.FolderRSN = @FolderRSN

IF @TCOTermInfoCode = 0 OR @TCODecisionDateInfoCode = 0 OR @TCOExpiryDateInfoCode = 0 OR @TCOConditionsDateInfoCode = 0 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please use Setup Info -> Setup for TCO to proceed.', 16, -1)
 RETURN
END

SELECT @TCOTermInfoValue = FolderInfo.InfoValueNumeric 
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 23031

SELECT @TCODecisionDateInfoValue = FolderInfo.InfoValueDateTime 
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 23032

SELECT @TCOConditionsDateInfoValue = FolderInfo.InfoValueDateTime 
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 23034

IF @AttemptResult = 23007       /* Issue TCO */
BEGIN
   IF ( @TCOTermInfoValue IS NULL ) OR ( @TCOTermInfoValue <= 0 ) 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter Number of Days for TCO to be valid', 16, -1)
      RETURN
   END

   IF @TCODecisionDateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter TCO Decision Date', 16, -1)
      RETURN
   END

   IF @TCOConditionsDateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter TCO Conditions Date', 16, -1)
      RETURN
   END

   SELECT @TCOExpiryDateInfoValue = DATEADD(DAY, @TCOTermInfoValue, @TCODecisionDateInfoValue)

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = @TCOExpiryDateInfoValue, 
          FolderInfo.InfoValueDateTime = @TCOExpiryDateInfoValue
     FROM FolderInfo
     WHERE FolderInfo.FolderRSN = @FolderRSN
       AND FolderInfo.InfoCode = 23033

   UPDATE Folder
      SET Folder.IssueDate = @TCODecisionDateInfoValue, 
          Folder.ExpiryDate = @TCOExpiryDateInfoValue, Folder.IssueUser = @UserID, 
          Folder.StatusCode = 23007, 
          Folder.FolderCondition = 
             CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),FolderCondition)) + 
             ' -> Temporary UCO Issued (' + 
             CONVERT(CHAR(11), @TCODecisionDateInfoValue) + ')' ))
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'TCO Issued',
           FolderProcess.SignOffUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'TCO Issued (' + CONVERT(char(11), @TCODecisionDateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Add Temporary CO Fee attempt result - No checks on previous TCO bills.  Filing Fee not charged for TCO's. */
/* Disabled 12-Feb-2013. Use the zoning folder for money instead. - JA */
/*
IF @AttemptResult = 23013              /* Add Temporary CO Fee */
BEGIN
	SELECT @TCOFee = ValidLookup.LookupFee
	FROM ValidLookup 
	WHERE ValidLookup.LookupCode = 15
	AND ValidLookup.Lookup1 = 1
	
	SELECT @NextRSN = @NextRSN + 1 
	INSERT INTO AccountBillFee 
		( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
		  FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
	VALUES ( @NextRSN, @FolderRSN, 162, 'Y', @TCOFee, 0, 0, getdate(), @UserId )

	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = '$' + CAST(@TCOFee AS VARCHAR) + ' TCO fee added (' + CONVERT(CHAR(11), getdate()) + ')' 
	WHERE FolderProcess.ProcessRSN = @ProcessRSN
	AND FolderProcess.FolderRSN = @FolderRSN
	  
	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment =  '$' + CAST(@TCOFee AS VARCHAR) + ' TCO fee added', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END */

/* Reopen process.  Could allow process to close, and then use Login procedure 
   to reopen it when status becomes TCO Expired. If more attempt results are added, 
   then null out SignOffUser for those addtional attempt results only. */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, 
       FolderProcess.ScheduleDate = getdate(),
       FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = @UserID  
 WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN

GO
