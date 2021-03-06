USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_BP_00030000]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_BP_00030000]
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
DECLARE @f_SubCode int 
DECLARE @f_WorkCode int 
DECLARE @ClauseCode int
DECLARE @AttemptResult int
DECLARE @AttemptComment varchar(1000)
DECLARE @strEmailTo Varchar(400)
DECLARE @strDate VARCHAR(10)
DECLARE @strTime VARCHAR(8)
DECLARE @dtmAttemptDate DATETIME
DECLARE @dtmScheduleDate DATETIME
DECLARE @dtmScheduleEndDate DATETIME
DECLARE @strScheduleDate NVARCHAR(20)
DECLARE @strScheduleEndDate NVARCHAR(20)
DECLARE @strFolderName VARCHAR(200)
DECLARE @strSubject VARCHAR(100)
DECLARE @strBody VARCHAR(4000)
DECLARE @Condition VARCHAR(2000)
DECLARE @int15Minutes INT
DECLARE @strPermitNo VARCHAR(20)
DECLARE @strFolderType CHAR(2)
DECLARE @strEmailFromAddress VARCHAR(30)
DECLARE @strEmailFromDisplay VARCHAR(30)

SELECT @strFolderType = Folder.FolderType,
       @strPermitNo = Folder.FolderYear + '-' + Folder.FolderSequence, 
       @AttemptResult = FolderProcessAttempt.Resultcode, 
       @AttemptComment = FolderProcessAttempt.AttemptComment,
       @strEmailTo = ValidUser.EmailAddress,
       @dtmAttemptDate = FolderProcessAttempt.AttemptDate,
       @dtmScheduleDate = FolderProcess.ScheduleDate,
       @strFolderName = Folder.FolderName,
       @strSubject = CAST(Folder.FolderRSN AS VARCHAR(20)),
       @int15Minutes = FolderProcess.DisplayOrder
FROM Folder
INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
INNER JOIN ValidUser ON FolderProcessAttempt.AttemptBy = ValidUser.UserId
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @strSubject = @strFolderType + ' - ' + @strFolderName + ' - FolderRSN ' + @strSubject

IF @AttemptResult = 20045   /* Inspection Scheduled */
    BEGIN
    COMMIT TRANSACTION
    BEGIN TRANSACTION

    SELECT @strBody = 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20)) 
    + CHAR(10) + 'Permit No: ' + @strPermitNo
    + CHAR(10) + 'Location: ' + @strFolderName
    + CHAR(10) + CHAR(10)
    + 'Contractor: ' + dbo.udf_GetFirstContractorName(@FolderRSN) 
    + CHAR(10) + 'Organization: ' + dbo.udf_GetFirstContractorOrgName(@FolderRSN) 
    + CHAR(10) + 'Phone: ' + dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstContractorPhone(@FolderRSN))
    + CHAR(10) + CHAR(10) 
    + 'Owner: ' + dbo.udf_GetFirstPeopleName(2, @FolderRSN)
    + CHAR(10) + 'Phone: ' + dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(2, @FolderRSN))

    SET @strEmailFromAddress = 'amanda@burlingtonvt.gov'
    SET @strEmailFromDisplay = @strFolderType + ' Scheduler'

	SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101)
	Set @strTime = CONVERT(varchar(8), @dtmScheduleDate, 108)
	SET @strScheduleDate = @strDate + ' ' + @strTime

	SET @strDate = CONVERT(varchar(10), @dtmScheduleEndDate, 101)
	Set @strTime = CONVERT(varchar(8), @dtmScheduleEndDate, 108)
	SET @strScheduleEndDate = @strDate + ' ' + @strTime

	IF @strScheduleEndDate IS NULL
	BEGIN
		SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101)
		Set @strTime = CONVERT(varchar(8), DATEADD(hour, 1, @dtmScheduleDate), 108)
		SET @strScheduleEndDate = @strDate + ' ' + @strTime
	END

	EXEC xspSendEmailAppointment @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate

    /*Reopen process*/
    UPDATE FolderProcess
    SET StatusCode = 1
    WHERE ProcessRSN = @ProcessRSN

  UPDATE Folder
     SET Folder.StatusCode = 30000      /* Application */
   WHERE Folder.FolderRSN = @FolderRSN

END


IF @AttemptResult = 10    /* Completed */
BEGIN
  UPDATE FolderProcess /* open process*/
  SET FolderProcess.EndDate = getDate()
  WHERE FolderProcess.FolderRSN = @FolderRSN 
  And FolderProcess.ProcessRSN = @ProcessRSN 


  SELECT @f_WorkCode = Folder.WorkCode 
    FROM Folder 
    WHERE ( Folder.FolderRSN = @FolderRSN ) 

	IF @f_WorkCode = 30001 SET @ClauseCode = 393
	IF @f_WorkCode = 30002 SET @ClauseCode = 399
	IF @f_WorkCode = 30018 SET @ClauseCode = 400
	IF @f_WorkCode = 30019 SET @ClauseCode = 398
	IF @f_WorkCode = 30098 SET @ClauseCode = 405
	IF @f_WorkCode = 30099 SET @ClauseCode = 406
	IF @f_WorkCode = 30100 SET @ClauseCode = 407
        IF @f_WorkCode = 30101 SET @ClauseCode = 468 
	IF @f_WorkCode = 30105 SET @ClauseCode = 432
	IF @f_WorkCode = 30110 SET @ClauseCode = 418
        IF @f_WorkCode = 30155 SET @ClauseCode = 467

  SELECT @Condition = ValidClause.ClauseText
  FROM ValidClause
  WHERE ClauseRSN = @ClauseCode

  UPDATE Folder
     SET Folder.FolderDescription = @Condition
   WHERE Folder.FolderRSN = @FolderRSN

END 

IF @AttemptResult = 120  /* Cancel Permit */
BEGIN

  UPDATE Folder /*change folder status to closed */
  SET Folder.StatusCode = 30005, Folder.Finaldate = getdate(), 
      Folder.FolderDescription = 'PERMIT CANCELLED: ' + @AttemptComment
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess /*close any open processes*/
  SET StatusCode = 2, EndDate = getdate(), ProcessComment = 'Permit Cancelled'
  WHERE FolderProcess.FolderRSN = @FolderRSN 
  AND FolderProcess.EndDate IS NULL
END

IF @AttemptResult = 30108  /* Limited Approval*/
BEGIN

  /*RAISERROR('Testing Pending Approval',16,-1)*/

  UPDATE Folder /*change folder status to Pending Approval */
  SET Folder.StatusCode = 30019,
      Folder.FolderDescription = 'PENDING APPROVAL: ' + @AttemptComment
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess /*reopen this process*/
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
  WHERE FolderProcess.processRSN = @processRSN

END

GO
