USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010030]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010030]
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

/* Phase Certificate of Occupancy (10030) version 1 */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @AttemptNumber int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @IssueDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @ZPNumber varchar(15)
DECLARE @ParentRSN int
DECLARE @PropertyRSN int
DECLARE @intNumberofPhases int
DECLARE @intPhaseAbandoned int
DECLARE @intNetPhases int
DECLARE @PhaseNumberCount int
DECLARE @PhaseNumber int
DECLARE @NextProcessStatusCode int
DECLARE @OwnerPeopleRSN int
DECLARE @CORequester int
DECLARE @ZZProjectDecisionAttempt int
DECLARE @RequestSignedBy varchar(50)
DECLARE @PCOSitePlanValue varchar(20)
DECLARE @PCODecDateValue datetime
DECLARE @PCOFeeText varchar(120)
DECLARE @TCOTermValue int
DECLARE @TCODecDateValue datetime
DECLARE @TCOExpiryDateValue datetime
DECLARE @TCODoc int
DECLARE @TCODocNotGenerated int
DECLARE @TCODocDisplayOrder int
DECLARE @TCOFee float
DECLARE @PhaseNumberText varchar(10)
DECLARE @PhaseFeeComment varchar(10)
DECLARE @PCOFeeExists int 
DECLARE @PCOFilingFeeExists int 
DECLARE @PCOFee float
DECLARE @PCOFilingFee float
DECLARE @NumberPCOProcesses int 
DECLARE @NumberPCOApproved int
DECLARE @ClosedPCOProcesses int
DECLARE @intPCOAttemptCount int
DECLARE @intPCOAttemptRSNSecondtoLast int 
DECLARE @intPCOAttemptCodeSecondtoLast int

/* Since FolderProcess.ProcessComment contains the Project Phase description
   which is shown on CO documents, attempt results must not record the action 
   in FolderProcess.ProcessComment. */

/* Get attempt result and number of attempt results for this process. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode, @AttemptDate = FolderProcessAttempt.AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
	(SELECT max(FolderProcessAttempt.AttemptRSN) 
	FROM FolderProcessAttempt
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @AttemptNumber = COUNT(*)
FROM FolderProcessAttempt, FolderProcess
WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessRSN = @ProcessRSN

/* Get Folder Type, Folder Status, Application Date, ZP Number, SubCode, WorkCode, 
   Parent RSN, and PropertyRSN. */

SELECT @FolderType = Folder.FolderType, @FolderStatus = Folder.StatusCode,
	@InDate = Folder.InDate, @IssueDate = Folder.IssueDate,
	@ZPNumber = Folder.ReferenceFile, @SubCode = Folder.SubCode,
	@WorkCode = Folder.WorkCode, @ParentRSN = Folder.ParentRSN, @PropertyRSN = Folder.PropertyRSN
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

/* Check to make sure C of O Requested or Abandon Phase is the first attempt result. */

IF @AttemptNumber = 1 AND @AttemptResult NOT IN(10001, 10067)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please select C of O Requested or Abandon Phase in order to proceed.', 16, -1)
   RETURN
END

/* Check Folder Status to insure permit has been Released, and that any Pre-Release Conditions have been met. */

IF @AttemptNumber = 1 AND @FolderStatus NOT IN (10006, 10047, 10048) AND @AttemptResult <> 10067 
BEGIN
   IF @FolderStatus IN (10002, 10003, 10004, 10016, 10022, 10044, 10045)
   BEGIN 
      ROLLBACK TRANSACTION
      RAISERROR ('Zoning permit is still in an appeal period: CO can not be started.', 16, -1)
      RETURN
   END
   IF @FolderStatus = 10018
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Zoning permit has unmet Pre-Release Conditions: CO can not be started.', 16, -1)
      RETURN
   END
   IF @FolderStatus = 10005
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Zoning permit has not been Picked Up from P+Z: CO can not be started.', 16, -1)
      RETURN
   END
   IF @FolderStatus NOT IN (10002, 10003, 10004, 10005, 10016, 10018, 10022, 10044, 10045)
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Something is amiss: CO can not be started.', 16, -1)
      RETURN
   END
END

/* Get Phase Number. */

SELECT @PhaseNumberCount = COUNT(*) 
FROM FolderProcessInfo
WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
AND FolderProcessInfo.InfoCode = 10010

IF @PhaseNumberCount > 0
BEGIN
	SELECT @PhaseNumber = ISNULL(FolderProcessInfo.InfoValueNumeric, 1)
	FROM FolderProcessInfo
	WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
	AND FolderProcessInfo.InfoCode = 10010
END
ELSE SELECT @PhaseNumber = 1 

SELECT @PhaseNumberText = RTRIM('Phase ' + CAST(@PhaseNumber as VARCHAR))

SELECT @PhaseFeeComment = RTRIM('Phase ' + CAST(@PhaseNumber AS CHAR(2)))

/* Certificate of Occupancy Requested attempt result */
/* Notes:  
	1) - The process has checklists to assign an inspector as ther AssignUser to the this process. Their use is optional. 
		If no inspector is chosen, the AssignedUser is null.
	2) - As the result of the Bianchi decision, starting on July 1, 1998, filing fees started being charged - one page for the 
		permit, and one page for the CO. 
	3) - Process Info has a field for the name of the person requesting the CO. It is required as backup documentation. 
	4) - The current owner of the property is inserted in FolderPeople as PeopleCode CO Requester. This will be pulled for the Final CO form. */

IF @AttemptResult = 10001               /* C of O Requested */
BEGIN
/* SELECT @RequestSignedBy = FolderProcessInfo.InfoValue
     FROM FolderProcessInfo
   WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
      AND FolderProcessInfo.InfoCode = 10001

   IF @RequestSignedBy IS NULL
   BEGIN
     ROLLBACK TRANSACTION
      RAISERROR ('Please enter the name of the person who signed the C of O request form in Process Info', 16, -1)
      RETURN
   END  */

	UPDATE Folder
	SET Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @PhaseNumberText + ' CO Requested (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
	WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'CO Requested for ' + @PhaseNumberText + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   /* Insert current property owner as PeopleCode CO Requester (325). */

   SELECT TOP 1 @OwnerPeopleRSN = PropertyPeople.PeopleRSN
     FROM PropertyPeople
    WHERE PropertyPeople.PropertyRSN = @PropertyRSN 
      AND PropertyPeople.PeopleCode = 2

   IF @OwnerPeopleRSN IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('There is not an Owner for the property record. An owner is required for CO issuance.', 16, -1)
      RETURN
   END

   SELECT @CORequester = COUNT(*) 
     FROM FolderPeople
    WHERE FolderPeople.PeopleRSN = @OwnerPeopleRSN 
      AND FolderPeople.FolderRSN = @FolderRSN 
      AND FolderPeople.PeopleCode = 325

   IF @CORequester = 0
   BEGIN
      INSERT INTO FolderPeople
                 (FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampUser, StampDate, 
                  Comments) 
          VALUES (@FolderRSN, 325, @OwnerPeopleRSN, 'Y', @UserID, getdate(), 
                  'Property Owner at CO Request')
   END
END      /* end of CO Requested attempt result */

/* Submission Incomplete attempt result */

IF @AttemptResult = 10000     /* Submission Incomplete */
BEGIN
	UPDATE Folder
	SET Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @PhaseNumberText + ' Submission for C of O Incomplete (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
	WHERE Folder.FolderRSN = @FolderRSN
	
	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = 'Submission Incomplete for ' + @PhaseNumberText + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Site Inspection Failed attempt result */

IF @AttemptResult = 10042              /* Site Inspection - Failed */
BEGIN
	UPDATE Folder
	SET Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Site Inspection for ' + @PhaseNumberText + ' CO - Phase does not Comply with Permit (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = 'Site Inspection - Failed for ' + @PhaseNumberText + ' (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @processRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Approved for Temporary CO attempt result */

IF @AttemptResult = 10029              /* Approved for TCO */
BEGIN
	SELECT @TCOTermValue = ISNULL(dbo.udf_GetFolderProcessInfo_Numeric(@ProcessRSN, 10013), 0) 
	SELECT @TCODecDateValue =     dbo.udf_GetFolderProcessInfo_Date(@ProcessRSN, 10014)

	IF @TCOTermValue <= 0 
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Please enter Number of Days for TCO to be valid', 16, -1)
		RETURN
	END

	IF @TCODecDateValue IS NULL
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Please enter Temp CO Decision Date', 16, -1)
		RETURN
	END

	SELECT @TCOExpiryDateValue = DATEADD(DAY, @TCOTermValue, @TCODecDateValue) 

	UPDATE FolderProcessInfo
	SET FolderProcessInfo.InfoValue = @TCOExpiryDateValue, FolderProcessInfo.InfoValueDateTime = @TCOExpiryDateValue
	WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
	AND FolderProcessInfo.InfoCode = 10015

	UPDATE Folder
	SET Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Approved for ' + @PhaseNumberText + ' Temporary Certificate of Occupancy (' + CONVERT(CHAR(11), @TCODecDateValue) + ')'))
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = 'Approved for TCO for ' + @PhaseNumberText + ' (' + CONVERT(CHAR(11), @TCODecDateValue) + ')', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = (
		SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

	SELECT @TCODoc = COUNT(*)
	FROM FolderDocument
	WHERE FolderDocument.FolderRSN = @FolderRSN
	AND FolderDocument.DocumentCode = 20000

	SELECT @TCODocDisplayOrder = 70 + @TCODoc

	SELECT @TCODocNotGenerated = COUNT(*)
	FROM FolderDocument
	WHERE FolderDocument.FolderRSN = @FolderRSN
	AND FolderDocument.DocumentCode = 20000
	AND FolderDocument.DateGenerated IS NULL

	IF @TCODocNotGenerated = 0 
	BEGIN
		SELECT @NextDocumentRSN = @NextDocumentRSN + 1
		INSERT INTO FolderDocument
			( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
			DisplayOrder, StampDate, StampUser, LinkCode )
		VALUES ( @FolderRSN, 20000, 1, @NextDocumentRSN, @TCODocDisplayOrder, getdate(), @UserID, 1 )
	END
END

/* Approved for Phase CO attempt result. */
/* Gross review time is recorded in FolderProcess.StartDate and FolderProcess.EndDate. */

IF @AttemptResult = 10066              /* Approved for Phase CO */
BEGIN
	/* Make sure the PCO fee has been added because this attempt result will close the process. */
	
	SELECT @PCOFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 160
	AND Folder.FolderRSN = @FolderRSN
	AND AccountBillFee.FeeComment LIKE @PhaseNumberText

	IF @PCOFeeExists = 0
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Please run the Add Phase CO Fee attempt result first, OR bill the Phase CO fee.', 16, -1)
		RETURN
	END

	SELECT @PCOSitePlanValue = dbo.udf_GetFolderProcessInfo_Alpha(@ProcessRSN, 10012)  
	SELECT @PCODecDateValue  = dbo.udf_GetFolderProcessInfo_Date(@ProcessRSN, 10011) 
   
	IF @PCOSitePlanValue IS NULL
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Please enter Phase CO Site Plan Type', 16, -1)
		RETURN
	END

	IF @PCODecDateValue IS NULL
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('Please enter Phase CO Decision Date', 16, -1)
		RETURN
	END

	UPDATE Folder
	SET Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Approved for ' + @PhaseNumberText + ' Certificate of Occupancy (' + CONVERT(CHAR(11), @PCODecDateValue) + ')'))
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = 'Approved for PCO for ' + @PhaseNumberText + ' (' + CONVERT(CHAR(11), @PCODecDateValue) + ')', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Add Phase CO Fee attempt result. Differentiating between phases for fee addition is accomplished in a clunky fashion with 
   AccountBillFee.FeeComment.  */

IF @AttemptResult = 10074
BEGIN
	SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 10081

	SELECT @intPhaseAbandoned = dbo.udf_CountProcessAttemptResultSpecific(@FolderRSN, 10030, 10067)

	SELECT @intNetPhases = @intNumberofPhases - @intPhaseAbandoned 
	IF @intNetPhases < 1 SELECT @intNetPhases = 1

	SELECT @PCOFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 160
	AND Folder.FolderRSN = @FolderRSN
	AND AccountBillFee.FeeComment LIKE @PhaseNumberText

	SELECT @PCOFilingFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 304
	AND Folder.FolderRSN = @FolderRSN
	AND AccountBillFee.FeeComment LIKE @PhaseNumberText

	/* The below two functions return either the calculated amount if does not exist, or the billed amount if exists. */
	
	SELECT @PCOFee = dbo.udf_GetZoningFeeCalcFinalCOPhase(@FolderRSN) 

	SELECT @PCOFilingFee = dbo.udf_GetZoningFeeCalcFinalCOFilingFee(@FolderRSN)
	
	SELECT @PCOFeeText = 'No fees'

	IF ( @PCOFilingFeeExists < @intNetPhases AND @PCOFilingFee > 0 ) 
	BEGIN
		SELECT @NextRSN = @NextRSN + 1 
		INSERT INTO AccountBillFee 
			( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
			FeeComment, 
			FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
		VALUES ( @NextRSN, @FolderRSN, 304, 'Y', @PhaseNumberText, @PCOFilingFee, 0, 0, getdate(), @UserId )
	END

	IF @PCOFeeExists < @intNetPhases
	BEGIN
		SELECT @NextRSN = @NextRSN + 1 
		INSERT INTO AccountBillFee 
			( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
			FeeComment,
			FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
		VALUES ( @NextRSN, @FolderRSN, 160, 'Y', @PhaseNumberText, @PCOFee, 0, 0, getdate(), @UserId ) 
				  
		SELECT @PCOFeeText = '$' + CAST((  CAST(@PCOFee + @PCOFilingFee AS NUMERIC(10,2))) AS VARCHAR) + ' PCO fee' 
	END

	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment =  @PhaseNumberText + ' ' + @PCOFeeText + ' added', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
 END 
 
 /* Add Temporary CO Fee attempt result - No checks on previous TCO bills.  Filing Fee not charged for TCO's. */

IF @AttemptResult = 10073              /* Add Temporary CO Fee */
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
	  
	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = @PhaseNumberText + ' $' + CAST(@TCOFee AS VARCHAR) + ' TCO fee added', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Abandon Phase */

IF @AttemptResult = 10067
BEGIN 
	UPDATE Folder
	SET Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @PhaseNumberText + ' Abandoned (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = @PhaseNumberText + ' Abandoned (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Update FolderProcess.StatusCode or close the process.  Note: This took some time to get right. */

/* First, get the second-to-last attempt result.  The existing FolderProcess.StatusCode can not be used because at the time a procedure 
	is executed, the StatusCode is actually 2. Therefore to look back, count current process attempt results, and get the ResultCode for 
	second too last one. AttemptRSN is used because it is unique, whereas ResultCode may not be unique. IF logic to assign next process 
	StatusCode uses explicit AttemptCode values (no ELSE's). */

SELECT @intPCOAttemptCount = dbo.udf_GetProcessAttemptCount(@FolderRSN, @ProcessRSN)

IF @intPCOAttemptCount = 1 SELECT @intPCOAttemptCodeSecondtoLast = 10001
ELSE
BEGIN
	SELECT TOP 1 @intPCOAttemptRSNSecondtoLast = FolderProcessAttempt.AttemptRSN
	FROM FolderProcessAttempt
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.FolderRSN = @FolderRSN
	AND FolderProcessAttempt.AttemptRSN NOT IN (
		SELECT TOP ( @intPCOAttemptCount - 2 ) FolderProcessAttempt.AttemptRSN
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
		AND FolderProcessAttempt.FolderRSN = @FolderRSN 
		ORDER BY FolderProcessAttempt.AttemptRSN )
	ORDER BY FolderProcessAttempt.AttemptRSN 
	
	SELECT @intPCOAttemptCodeSecondtoLast = FolderProcessAttempt.ResultCode
	FROM FolderProcessAttempt
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = @intPCOAttemptRSNSecondtoLast
	AND FolderProcessAttempt.FolderRSN = @FolderRSN 
END

SELECT @TCOExpiryDateValue = FolderProcessInfo.InfoValueDateTime
FROM FolderProcessInfo
WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
AND FolderProcessInfo.InfoCode = 10015

SELECT @NextProcessStatusCode = 1 

IF @AttemptResult IN (10066, 10067) SELECT @NextProcessStatusCode = 2
ELSE 
BEGIN
	IF @TCOExpiryDateValue IS NOT NULL 
	BEGIN 
		IF @TCOExpiryDateValue > getdate() SELECT @NextProcessStatusCode = 10004		/* Temp CO Issued */
		ELSE SELECT @NextProcessStatusCode = 10005														/* Temp CO Expired */
	END
	ELSE 
	BEGIN
		SELECT @NextProcessStatusCode = 
		CASE @intPCOAttemptCodeSecondtoLast
			WHEN 10000 THEN 10002
			WHEN 10001 THEN 10001
			WHEN 10029 THEN 10004
			WHEN 10042 THEN 10003
			WHEN 10073 THEN 1
			WHEN 10074 THEN 1
			ELSE 1
		END
	END
END

/* Finally update FolderProcess.StatusCode. */

IF @NextProcessStatusCode = 2
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = @NextProcessStatusCode, 
          FolderProcess.EndDate = getdate()
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN
END
ELSE 
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = @NextProcessStatusCode, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN
END

/* Phasing Over Checker: If at the end, close any open processes and set Folder.StatusCode. */

IF @NextProcessStatusCode = 2
BEGIN
   SELECT @NumberPCOProcesses = dbo.udf_CountProcesses(@FolderRSN, 10030)
   SELECT @NumberPCOApproved  = dbo.udf_CountProcessAttemptResultSpecific(@FolderRSN, 10030, 10066)

   SELECT @ClosedPCOProcesses = ISNULL(COUNT(*), 0)
      FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessCode = 10030
       AND FolderProcess.StatusCode = 2 

   /* When all PCO processes are closed: 
      If any PCOs were approved, set Folder.StatusCode = 10008, and update property record impervious surface area using approved coverage percent. 
      If no PCOs were approved (i.e. all phases were abandonned), set Folder.StatusCode = 10040 (CO Not Applicable) which triggers addition 
      of the Abandon Permit process (10019). */

   IF @ClosedPCOProcesses = @NumberPCOProcesses 
   BEGIN
      IF @NumberPCOApproved > 0
      BEGIN 
         UPDATE Folder
            SET Folder.StatusCode = 10008, Folder.FinalDate = getdate(), 
                Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Phasing Complete -> Project Approved for Final Certificate of Occupancy (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
          WHERE Folder.FolderRSN = @FolderRSN

         EXEC dbo.usp_PropertyImperviousSurfaceUpdate @FolderRSN 
      END
      ELSE
      BEGIN
		UPDATE Folder
		SET Folder.StatusCode = 10040,   /* CO Not Applicable */
			Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Phased C of Os Not Applicable (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
		WHERE Folder.FolderRSN = @FolderRSN
      END
   END
END

GO
