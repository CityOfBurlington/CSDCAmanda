USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_PP_00030010]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_PP_00030010]  @ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128) as  exec RsnSetLock DECLARE @NextRSN numeric(10) SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0)
 FROM AccountBillFee
 DECLARE @NextProcessRSN numeric(10)
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0)
 FROM FolderProcess
 DECLARE @NextDocumentRSN numeric(10)
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0)
 FROM FolderDocument
BEGIN 
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
DECLARE @int15Minutes INT 
DECLARE @strPermitNo VARCHAR(20) 
DECLARE @strFolderType CHAR(2) 
DECLARE @strEmailFromAddress VARCHAR(30) 
DECLARE @strEmailFromDisplay VARCHAR(30) 
 
DECLARE @attemptCk int 
DECLARE @Rough VarChar(3) 
DECLARE @Underground VarChar(3) 
DECLARE @AttemptRSN int 
DECLARE @AttemptCount int 
DECLARE @BalDue Money 
DECLARE @StatusCode INT 
 
SELECT  
       @strFolderType = Folder.FolderType, 
       @strPermitNo = Folder.FolderYear + '-' + Folder.FolderSequence,  
       @AttemptResult = FolderProcessAttempt.Resultcode,  
       @AttemptComment = FolderProcessAttempt.AttemptComment, 
       @strEmailTo = ValidUser.EmailAddress, 
       @dtmAttemptDate = FolderProcessAttempt.AttemptDate, 
       @dtmScheduleDate = FolderProcess.ScheduleDate, 
       @dtmScheduleEndDate = FolderProcess.ScheduleEndDate, 
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
 
SELECT @Rough = InfoValue 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30053 
 
SELECT @Underground = InfoValue 
From FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30072 
 
SELECT @AttemptResult = Resultcode, @AttemptRSN = AttemptRSN 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN 
AND FolderProcessAttempt.AttemptRSN =  
(SELECT MAX(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN) 
 
SELECT @AttemptCount = count(*) 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN 
 
IF @AttemptResult = 20045 /*Inspection Scheduled*/ 
 
    BEGIN 
    COMMIT TRANSACTION 
    BEGIN TRANSACTION 
 
	SELECT @strSubject = @strFolderType + ' - ' + @strFolderName + ' - FolderRSN ' + @strSubject 
 
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
 
    SET @strEmailFromAddress = 'amanda@ci.burlington.vt.us' 
    SET @strEmailFromDisplay = @strFolderType + ' Scheduler' 
 
	SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101) 
	Set @strTime = CONVERT(varchar(8), @dtmScheduleDate, 108) 
	SET @strScheduleDate = @strDate + ' ' + @strTime 
 
	SET @strDate = CONVERT(varchar(10), @dtmScheduleEndDate, 101) 
	Set @strTime = CONVERT(varchar(8), @dtmScheduleEndDate, 108) 
	SET @strScheduleEndDate = @strDate + ' ' + @strTime 
 
	IF LEN(@strScheduleEndDate) < 1 
	BEGIN 
		SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101) 
		Set @strTime = CONVERT(varchar(8), DATEADD(hour, 1, @dtmScheduleDate), 108) 
		SET @strScheduleEndDate = @strDate + ' ' + @strTime 
	END 
 
 
	EXEC xspSendEmailAppointment @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate 
 
END 
 
 
IF @AttemptResult = 70 /*Stop Work Order Issued*/ 
BEGIN 
 
     SELECT @attemptCk = Count(*) 
     FROM FolderProcessattempt 
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN 
     AND FolderProcessattempt.Resultcode = 125 
 
     IF @attemptCk <1 
 
     BEGIN 
     ROLLBACK TRANSACTION 
     RAISERROR('You must issue an Order to Comply prior to issuing a Stop Work Order',16,-1) 
     RETURN 
     END 
 
     ELSE 
 
     BEGIN 
     UPDATE Folder 
     SET Folder.StatusCode = 30007 /*Stop Work Order*/ 
     WHERE Folder.FolderRSN = @FolderRSN 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
      
     END 
END 
 
IF @AttemptResult = 130 /*Stop Work Order Lifted*/ 
BEGIN 
 
	SET @StatusCode = 30002 /* Default Status to Issued */ 
	SELECT @BalDue = dbo.udf_GetFolderFeesDue(@FolderRSN) 
	IF ISNULL(@BalDue, 0.0) = 0.0 SET @StatusCode = 30022 /* If not paid in full, Status is "Awaiting Payment" */ 
 
     UPDATE Folder 
     SET Folder.StatusCode = @StatusCode 
     WHERE Folder.FolderRSN = @FolderRSN 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30010 
     END 
 
     IF @Underground = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode = 30020 
     END 
 
END 
 
IF @AttemptResult = 35 /*Legal Action*/ 
BEGIN 
 
     UPDATE Folder 
     SET Folder.StatusCode = 30008 /*Legal Action*/ 
     WHERE Folder.FolderRSN = @FolderRSN 
      
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
END 
 
IF @AttemptResult = 135 /*Legal Action Resolved*/ 
BEGIN 
 
	SET @StatusCode = 30002 /* Default Status to Issued */ 
	SELECT @BalDue = dbo.udf_GetFolderFeesDue(@FolderRSN) 
	IF ISNULL(@BalDue, 0.0) = 0.0 SET @StatusCode = 30022 /* If not paid in full, Status is "Awaiting Payment" */ 
 
     UPDATE Folder 
     SET Folder.StatusCode = @StatusCode 
     WHERE Folder.FolderRSN = @FolderRSN 
      
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30010 
     END 
 
     IF @Underground = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode = 30020 
     END 
END 
 
IF @AttemptResult = 20 /*Not Required*/ 
BEGIN 
    UPDATE FolderProcess 
    SET ProcessComment = 'Not Required' 
    WHERE FolderProcess.processRSN = @processRSN 
 
END 
 
IF @AttemptResult = 30108  /*limited approval*/ 
BEGIN 
 
  /*RAISERROR('Testing Pending Approval',16,-1)*/ 
 
/* This logic removed per Ned Holt - 12/15/2010  
  UPDATE Folder /*change folder status to Pending Approval */ 
  SET Folder.StatusCode = 30019 
  WHERE Folder.FolderRSN = @FolderRSN 
*/ 
  UPDATE FolderProcess /*reopen this process*/ 
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
  WHERE FolderProcess.processRSN = @processRSN 
 
END  
END
GO
