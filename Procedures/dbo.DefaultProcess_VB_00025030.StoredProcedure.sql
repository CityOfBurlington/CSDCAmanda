USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VB_00025030]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VB_00025030]  @ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128) as  exec RsnSetLock DECLARE @NextRSN numeric(10) SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0)
 FROM AccountBillFee
 DECLARE @NextProcessRSN numeric(10)
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0)
 FROM FolderProcess
 DECLARE @NextDocumentRSN numeric(10)
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0)
 FROM FolderDocument
BEGIN 
/* VB Schedule Inspection*/ 
 
DECLARE @AttemptDate DATETIME 
DECLARE @AttemptResult int 
DECLARE @AttemptComment varchar(1000) 
DECLARE @strEmailTo Varchar(400) 
DECLARE @strDate VARCHAR(10) 
DECLARE @strTime VARCHAR(8) 
DECLARE @dtmAttemptDate DATETIME 
DECLARE @dtmScheduleDate DATETIME 
DECLARE @dtmScheduleEndDate DATETIME 
DECLARE @strScheduleDate NVARCHAR(20) 
DECLARE @strConditionText VARCHAR(50) 
DECLARE @strScheduleEndDate NVARCHAR(20) 
DECLARE @strFolderName VARCHAR(200) 
DECLARE @strSubject VARCHAR(100) 
DECLARE @strBody VARCHAR(4000) 
DECLARE @strFolderType CHAR(2) 
DECLARE @strEmailFromAddress VARCHAR(30) 
DECLARE @strEmailFromDisplay VARCHAR(30) 
DECLARE @Condition VARCHAR(2000) 
DECLARE @intDeficiencies INT 
DECLARE @strText VARCHAR(100) 
DECLARE @intCOMReturnValue INT 
DECLARE @AttemptRSN int 
DECLARE @AttemptCount int 
 
SELECT  
	@strFolderType = Folder.FolderType, 
	@AttemptResult = FolderProcessAttempt.Resultcode, 
        @AttemptRSN = FolderProcessAttempt.AttemptRSN, 
 	@AttemptComment = FolderProcessAttempt.AttemptComment, 
	@strEmailTo = ValidUser.EmailAddress, 
	@dtmAttemptDate = FolderProcessAttempt.AttemptDate, 
	@dtmScheduleDate = FolderProcess.ScheduleDate, 
	@dtmScheduleEndDate = FolderProcess.ScheduleEndDate, 
	@strFolderName = Folder.FolderName, 
	@strSubject = CAST(Folder.FolderRSN AS VARCHAR(20)) 
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
 
SELECT @intDeficiencies = SUM(1) FROM FolderProcessDeficiency  
	WHERE FolderRSN = @FolderRSN AND ProcessRSN = @ProcessRSN AND StatusCode = 1 /*Non-Complied*/ 
SET @intDeficiencies = ISNULL(@intDeficiencies, 0) 
 
IF @AttemptResult = 25070 /*Inspection Scheduled  */ 
    BEGIN 
	COMMIT TRANSACTION 
	BEGIN TRANSACTION 
 
       SELECT @strBody = 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20))   
       + CHAR(10) + 'Location: ' + @strFolderName  
       + CHAR(10) + CHAR(10)  
       + 'Owner: ' + ISNULL(dbo.udf_GetFirstPeopleName(2, @FolderRSN),'') 
       + CHAR(10) + 'Phone: ' + ISNULL(dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(2, @FolderRSN)), '') + CHAR(10) + CHAR(10) + CHAR(10) + '[DefaultProcess_VB_00025030]' 
 
 	SET @strEmailFromAddress = 'amanda@burlingtonvt.gov' 
	SET @strEmailFromDisplay = @strFolderType + ' Scheduler' 
 
	SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101) 
	Set @strTime = CONVERT(varchar(8), @dtmScheduleDate, 108) 
	SET @strScheduleDate = @strDate + ' ' + @strTime 
 
        SET @strDate = ISNULL(CONVERT(varchar(10), @dtmScheduleEndDate, 101),'')  
        SET @strTime = ISNULL(CONVERT(varchar(8), @dtmScheduleEndDate, 108),'')  
	SET @strScheduleEndDate = @strDate + ' ' + @strTime 
 
 
	IF LEN(@strScheduleEndDate) < 2 
	BEGIN 
 		SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101) 
		Set @strTime = CONVERT(varchar(8), DATEADD(hour, 1, @dtmScheduleDate), 108) 
		SET @strScheduleEndDate = @strDate + ' ' + @strTime 
	END 
 
--RAISERROR('Calling webservice to schedule inspection', 16, -1) 
 
        /* Create appointment on Outlook calendar */ 
	EXEC webservices_CreateAppointment @strSubject, @strBody, @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, '', @strScheduleDate, @strScheduleEndDate, @strFolderName 
 	--EXEC xspSendEmailAppointment @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate 
	COMMIT TRANSACTION 
	BEGIN TRANSACTION 
 
        /* Create workorder and email it to inspector */ 
	EXEC usp_SendInspectionWorkorder @FolderRSN, @ProcessRSN 
  
 /*Reopen process*/ 
        UPDATE FolderProcess SET StatusCode = 1, StartDate = NULL, EndDate = NULL 
          WHERE FolderProcess.ProcessRSN = @ProcessRSN 
 
        SET @strConditionText = 'VB Inspection Scheduled for ' + @strScheduleDate 
        EXEC usp_UpdateFolderCondition @FolderRSN, @strConditionText 
  
    END 
 
IF @AttemptResult = 25080 /*Deficiencies Found*/ 
	BEGIN 
 
 
	/*Check to make sure there are actually deficiencies in this process*/ 
	IF @intDeficiencies = 0 
		BEGIN 
		ROLLBACK TRANSACTION 
		RAISERROR('You must insert deficiencies before attempt result', 16, -1) 
		RETURN 
		END 
	ELSE 
		BEGIN 
		--RAISERROR('Processing deficiencies', 16, -1) 
 
		EXEC usp_UpdateFolderCondition @FolderRSN, 'Deficiencies Found' 
 
		UPDATE FolderProcess SET ProcessComment = 'Deficiencies Found' WHERE ProcessRSN = @ProcessRSN 
 
		UPDATE FolderProcessDeficiency SET ComplyByDate = DateAdd(D, 35, @AttemptDate) WHERE ProcessRSN = @ProcessRSN AND ComplyByDate IS NULL  
                EXEC usp_UpdateFolderCondition @FolderRSN, 'Deficiencies Found' 
 
            /*Reopen process*/ 
                UPDATE FolderProcess  /* re-open this process */ 
                  SET StatusCode = 1, StartDate = NULL, EndDate = NULL 
                  WHERE FolderProcess.ProcessRSN = @ProcessRSN 
		END  
 
	END 
	 
IF @AttemptResult = 25090 /*Found in Compliance*/ 
BEGIN 
	/*Check to make sure there are no remaining non-complied deficiencies in this process*/ 
	IF @intDeficiencies > 0 
		BEGIN 
		ROLLBACK TRANSACTION 
		RAISERROR('There are still non-complied deficiencies in this process.', 16, -1) 
		RETURN 
		END 
	ELSE 
		BEGIN 
		EXEC usp_UpdateFolderCondition @FolderRSN, 'Found in Compliance' 
		END 
END 
 
IF @AttemptResult = 25150 /*Inspection Rescheduled*/ 
    BEGIN 
	--COMMIT TRANSACTION 
	--BEGIN TRANSACTION 
 
	SELECT @strBody = 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20))  
	+ CHAR(10) + 'Location: ' + @strFolderName 
	+ CHAR(10)  + CHAR(10) 
	+ CHAR(10) + 'Organization: ' + dbo.udf_GetFirstContractorOrgName(@FolderRSN)  
	+ CHAR(10) + 'Phone: ' + dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstContractorPhone(@FolderRSN)) 
	+ CHAR(10) + CHAR(10)  
	+ 'Owner: ' + dbo.udf_GetFirstPeopleName(2, @FolderRSN) 
	+ CHAR(10) + 'Phone: ' + dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(2, @FolderRSN)) + CHAR(10) + CHAR(10) + CHAR(10) + '[DefaultProcess_VB_00025030]' 
  
 	SET @strEmailFromAddress = 'amanda@burlingtonvt.gov' 
	SET @strEmailFromDisplay = @strFolderType + ' Scheduler' 
 
	SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101) 
	Set @strTime = CONVERT(varchar(8), @dtmScheduleDate, 108) 
	SET @strScheduleDate = @strDate + ' ' + @strTime 
 
	SET @strDate = CONVERT(varchar(10), @dtmScheduleEndDate, 101) 
	Set @strTime = CONVERT(varchar(8), @dtmScheduleEndDate, 108) 
	SET @strScheduleEndDate = @strDate + ' ' + @strTime 
 
 
	IF LEN(@strScheduleEndDate) < 2 
	BEGIN 
 		SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101) 
		Set @strTime = CONVERT(varchar(8), DATEADD(hour, 1, @dtmScheduleDate), 108) 
		SET @strScheduleEndDate = @strDate + ' ' + @strTime 
	END 
 
 
        /* Create appointment on Outlook calendar */ 
	EXEC webservices_CreateAppointment @strSubject, @strBody, @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, '', @strScheduleDate, @strScheduleEndDate, @strFolderName 
  
        /* Create workorder and email it to inspector */ 
	EXEC usp_SendInspectionWorkorder @FolderRSN, @ProcessRSN 
  
 /*Reopen process*/ 
        UPDATE FolderProcess SET StatusCode = 1, StartDate = NULL, EndDate = NULL 
          WHERE FolderProcess.ProcessRSN = @ProcessRSN 
 
        SET @strConditionText = 'VB Inspection rescheduled for ' + @strScheduleDate 
        EXEC usp_UpdateFolderCondition @FolderRSN, @strConditionText 
  
    END 
  
END
GO
