USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VB_00025020]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VB_00025020]
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
/* VB Fee Waiver */

DECLARE @AttemptResult INT
DECLARE @AttemptDate DATETIME
DECLARE @AttemptRSN INT
DECLARE @FeeAmt FLOAT

SELECT @AttemptResult = ResultCode, 
@AttemptDate = AttemptDate,
@AttemptRSN = AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
    (SELECT max(FolderProcessAttempt.AttemptRSN) 
     FROM FolderProcessAttempt
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

/*VB Fee Waiver Granted */
IF @AttemptResult = 25050 
BEGIN

	/* Get Fee Waiver amount from lookup and insert to folder */
	SELECT @FeeAmt = LookupFee FROM ValidLookup 
	  WHERE LookupCode = 16 AND Lookup1 = 10 AND Lookup2 = 10
	EXEC PC_FEE_INSERT @FolderRSN, 222, @FeeAmt, @UserID, 1, 'VB Fee Waiver Refund', 1, 0

	/* Set VB Fee Waiver Date (date of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25025)
	BEGIN
		/* Set VB Fee Waiver Date (date of decision)  */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 25025 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 25025, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set VB Fee Waiver Result (text of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25020)
	BEGIN
		/* Set VB Fee Waiver Result (text of decision)  */
		UPDATE FolderInfo
		SET InfoValue = 'Granted', InfoValueUpper = 'GRANTED'
		WHERE infocode = 25020 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueUpper, StampDate, StampUser)
		VALUES(@FolderRSN, 25020, 'Granted', 'GRANTED', getdate(), @UserID)
	END

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Fee Waiver Granted'

	/* Set Process status code to Waiver Granted */
        UPDATE FolderProcess  
        SET StatusCode = 25050, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

END

/*VB Fee Waiver Not Requested */
IF @AttemptResult = 25055
BEGIN

	/* Set VB Fee Waiver Date (date of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25025)
	BEGIN
		/* Set VB Fee Waiver Date (date of decision)  */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 25025 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 25025, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set VB Fee Waiver Result (text of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25020)
	BEGIN
		/* Set VB Fee Waiver Result (text of decision)  */
		UPDATE FolderInfo
		SET InfoValue = 'Not Requested', InfoValueUpper = 'NOT REQUESTED'
		WHERE infocode = 25020 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueUpper, StampDate, StampUser)
		VALUES(@FolderRSN, 25020, 'Not Requested', 'NOT REQUESTED', getdate(), @UserID)
	END

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Fee Waiver Not Requested'

	/* Set Process status code to Waiver Not Requested */
        UPDATE FolderProcess  
        SET StatusCode = 25055, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

END

/* VB Fee Waiver Denied */
IF @AttemptResult = 25060 
BEGIN

	/* Set VB Fee Waiver Date (date of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25025)
	BEGIN
		/* Set VB Fee Waiver Date (date of decision)  */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 25025 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 25025, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set VB Fee Waiver Result (text of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25020)
	BEGIN
		/* Set VB Fee Waiver Result (text of decision)  */
		UPDATE FolderInfo
		SET InfoValue = 'Denied', InfoValueUpper = 'DENIED'
		WHERE infocode = 25020 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueUpper, StampDate, StampUser)
		VALUES(@FolderRSN, 25020, 'Denied', 'DENIED', getdate(), @UserID)
	END

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Fee Waiver Denied'

	/* Set Process status code to Waiver Denied */
        UPDATE FolderProcess  
        SET StatusCode = 25060, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

END

/* Appealed */
IF @AttemptResult = 25062 
BEGIN

	/* Set VB Fee Waiver Date (date of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25025)
	BEGIN
		/* Set VB Fee Waiver Date (date of decision)  */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 25025 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 25025, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set VB Fee Waiver Result (text of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25020)
	BEGIN
		/* Set VB Fee Waiver Result (text of decision)  */
		UPDATE FolderInfo
		SET InfoValue = 'Appealed', InfoValueUpper = 'APPEALED'
		WHERE infocode = 25020 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueUpper, StampDate, StampUser)
		VALUES(@FolderRSN, 25020, 'Appealed', 'APPEALED', getdate(), @UserID)
	END

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Fee Waiver Appealed'

	/* Set Process status code to Waiver Appealed */
        UPDATE FolderProcess  
        SET StatusCode = 25062, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

END

/*VB Fee Waiver Appeal Denied */
IF @AttemptResult = 25064
BEGIN

	/* Set VB Fee Waiver Date (date of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25025)
	BEGIN
		/* Set VB Fee Waiver Date (date of decision)  */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 25025 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 25025, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set VB Fee Waiver Result (text of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25020)
	BEGIN
		/* Set VB Fee Waiver Result (text of decision)  */
		UPDATE FolderInfo
		SET InfoValue = 'Appeal Denied', InfoValueUpper = 'APPEAL DENIED'
		WHERE infocode = 25020 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueUpper, StampDate, StampUser)
		VALUES(@FolderRSN, 25020, 'Appeal Denied', 'APPEAL DENIED', getdate(), @UserID)
	END

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Fee Waiver Appeal Denied'

	/* Set Process status code to Appeal Denied */
        UPDATE FolderProcess  
        SET StatusCode = 25064, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

END

/*VB Fee Waiver Appeal Granted */
IF @AttemptResult = 25066
BEGIN

	/* Set VB Fee Waiver Date (date of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25025)
	BEGIN
		/* Set VB Fee Waiver Date (date of decision)  */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 25025 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 25025, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set VB Fee Waiver Result (text of decision) */
	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25020)
	BEGIN
		/* Set VB Fee Waiver Result (text of decision)  */
		UPDATE FolderInfo
		SET InfoValue = 'Appeal Granted', InfoValueUpper = 'APPEAL GRANTED'
		WHERE infocode = 25020 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueUpper, StampDate, StampUser)
		VALUES(@FolderRSN, 25020, 'Appeal Granted', 'APPEAL GRANTED', getdate(), @UserID)
	END

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Fee Waiver Appeal Granted'

	/* Set Process status code to Waiver Appeal Granted */
        UPDATE FolderProcess  
        SET StatusCode = 25066, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

END


GO
