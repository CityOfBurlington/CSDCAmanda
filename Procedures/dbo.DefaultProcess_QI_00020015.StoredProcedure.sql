USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QI_00020015]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QI_00020015]
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
DECLARE @AttemptResult	INT
DECLARE @Inspectiondate DATETIME
DECLARE @NonComplyCount INT
DECLARE @Complybydate	DATETIME
DECLARE @NoofUnits	INT
DECLARE @Desc		VARCHAR(2000)
DECLARE @reinspect	DATETIME
DECLARE @Extensiondays	INT
DECLARE @ExtendedDate	DATETIME 

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @InspectionDate = AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @ComplyByDate = (SELECT MAX(FolderProcessDeficiency.ComplyByDate)
FROM FolderProcessDeficiency
WHERE FolderProcessDeficiency.ProcessRSN = @ProcessRSN)

SELECT @NonComplyCount = Count(LocationDesc)
FROM FolderProcessDeficiency
WHERE FolderPRocessDeficiency.StatusCode = 1
AND FolderProcessDeficiency.FolderRSN = @FolderRSN
GROUP BY LocationDesc

SELECT @NoofUnits = @@RowCount

IF @AttemptResult = 20047 /*Deficiencies Found*/
BEGIN
	DECLARE @new_count1 int
	DECLARE @severity_code int

	DECLARE Upd_comply_by_date CURSOR FOR
	SELECT ISNULL(FolderProcessDeficiency.SeverityCode,-1)
	FROM FolderProcessDeficiency
	WHERE FolderProcessDeficiency.ProcessRSN = @ProcessRSN 
	AND FolderProcessDeficiency.StatusCode = 1

	OPEN Upd_comply_by_date

	FETCH NEXT FROM Upd_comply_by_date INTO @severity_code

	WHILE @@FETCH_STATUS = 0 
	BEGIN
		SELECT @new_count1 = DefaultDaysToComply 
		FROM ValidProcessSeverity 
		WHERE SeverityCode = @severity_code

		UPDATE FolderProcessDeficiency
		SET ComplyByDate = dateadd(day,@new_count1,getdate())
		WHERE ProcessRSN = @ProcessRSN
		AND SeverityCode = @severity_code
		AND Statuscode = 1

		FETCH NEXT FROM Upd_comply_by_date INTO @severity_code
	END

	CLOSE Upd_comply_by_date
	DEALLOCATE Upd_comply_by_date

	UPDATE Folder
	SET Folder.StatusCode = 20014 /*Violation*/,Folder.ExpiryDate =@complybydate
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcess
	SET FolderProcess.ScheduleDate = @complybydate, EndDate = NULL, StatusCode = 1,
	ProcessComment = 'Schedule a Reinspection'
	WHERE FolderProcess.ProcessRSN = @ProcessRSN

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = CONVERT(CHAR(11),@InspectionDate)
	WHERE FolderInfo.InfoCode = 20030
	AND FolderInfo.FolderRSN = @FolderRSN

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = CONVERT(CHAR(11),@ComplyByDate)
	WHERE FolderInfo.InfoCode = 20001
	AND FolderInfo.FolderRSN = @FolderRSN

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = @NoofUnits, FolderInfo.InfoValueNumeric= @NoofUnits
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 20032

	SELECT @reinspect = MAX(Complybydate)
	FROM FolderProcessdeficiency
	WHERE FolderProcessdeficiency.ProcessRSN = @ProcessRSN
	AND FolderProcessDeficiency.FolderRSN = @FolderRSN

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = CONVERT(CHAR(11),@reinspect), 
	FolderInfo.InfoValueUpper = UPPER(CONVERT(CHAR(11),@reinspect)), 
	FolderInfo.InfoValueDatetime = @reinspect
	WHERE FolderInfo.FolderRSN =@FolderRSN
	AND FolderInfo.InfoCode = 20001

END

IF @AttemptResult = 20008 /*Refer to Zoning*/
BEGIN
	INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
	FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
	VALUES(GETDATE(), 'REVIEW PROGRESS OF ZONING EVALUATION', 'KBUTLER',
	@FolderRSN, 'Y', GETDATE() + 10, GETDATE(), @userID)

	UPDATE FolderProcess
	SET ScheduleDate = NULL, StatusCode = 1, EndDate = NULL
	WHERE FolderProcess.ProcessRSN = @ProcessRSN

	SELECT @Desc = Folder.FolderDescription
	FROM Folder
	WHERE Folder.FolderRSN = @FolderRSN

	/*Insert Child Folder*/
	DECLARE @NextFolderRSN int
	DECLARE @SeqNo int
	DECLARE @Seq char(6)
	DECLARE @SeqLength int
	DECLARE @TheYear char(2)
	DECLARE @TheCentury char(2)

	SELECT @NextFolderRSN =  max(FolderRSN + 1) FROM  Folder

	SELECT @TheYear = substring(convert(char(4),DATEPART(year, getdate())),3,2)

	SELECT @TheCentury = substring(convert( char(4),DATEPART(year, getdate())),1,2)

	SELECT @SeqNo = convert(int,max(FolderSequence)) + 1
	FROM Folder
	WHERE FolderYear = @TheYear

	IF @SeqNo IS NULL
	BEGIN
		SELECT @SeqNo = 100000
	END

	SELECT @SeqLength = datalength(convert(varchar(6),@SeqNo))

	IF @SeqLength < 6
	BEGIN
		SELECT @Seq = substring('000000',1,(6 - @SeqLength)) + convert(varchar(6), @SeqNo)
	END

	IF @SeqLength = 6
	BEGIN
		SELECT @Seq = convert(varchar(6),@SeqNo)
	END

	INSERT INTO FOLDER
	(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
	FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate, FolderDescription,
	ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
	SELECT @NextFolderRSN, @TheCentury, @TheYear, @Seq, '000', '00',
	'Q2', '150', SubCode, WorkCode, PropertyRSN, getdate(), @Desc,
	@FolderRSN, 'DDDDD', FolderName, getdate(), User
	FROM Folder
	WHERE FolderRSN = @FolderRSN 

	UPDATE FolderProcess
	SET AssignedUser = 'JFrancis', ScheduleDate = getdate()
	WHERE FolderProcess.FolderRSN = @NextFolderRSN
	and FolderProcess.ProcessCode = 5003

	UPDATE FolderInfo
	SET InfoValue = 'Departmental Referral'
	WHERE FolderInfo.FolderRSN = @NextFolderRSN
	AND FolderInfo.InfoCode = 20008
END

IF @AttemptResult = 20046 /*Found In Compliance*/
BEGIN
	UPDATE Folder
	SET StatusCode = 2, FinalDate = GETDATE()
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcess  /*close any open processes*/
	SET FolderProcess.EndDate = GETDATE(), FolderProcess.StatusCode = 2
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.EndDate IS NULL

	INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
	FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
	VALUES(GETDATE(), 'REVIEW COMPLIANCE', 'KBUTLER',
	@FolderRSN, 'Y', GETDATE(), GETDATE(), @userID)

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = @NoofUnits, FolderInfo.InfoValueNumeric= @NoofUnits
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 20032

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = Convert(Char(11),@InspectionDate)
	WHERE FolderInfo.InfoCode = 20030
	AND FolderInfo.FolderRSN = @FolderRSN
END


IF @AttemptResult = 20011 /*Legal Action Required*/
BEGIN
   INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
   FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
   VALUES(GETDATE(), 'REVIEW PROGRESS OF LEGAL ACTION', 'KBUTLER',
   @FolderRSN, 'Y', GETDATE()+30, GETDATE(), @userID)

   UPDATE Folder
   SET StatusCode = 110 /*Legal Action*/
   WHERE Folder.FolderRSN = @FolderRSN
END

IF @attemptresult = 20005 /*Ticket Issued*/
BEGIN
	UPDATE FolderProcess
	SET StatusCode = 1, SignOffUser = Null, EndDate=Null
	WHERE ProcessRSN = @ProcessRSN
END

   
     
IF @AttemptResult = 20061 /*Hold Folder Open*/
BEGIN
	UPDATE Folder
	SET Folder.StatusCode = 1 /*Open*/
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcess
	SET StatusCode = 1, SignOffUser = Null, EndDate=Null
	WHERE ProcessRSN = @ProcessRSN
END



GO
