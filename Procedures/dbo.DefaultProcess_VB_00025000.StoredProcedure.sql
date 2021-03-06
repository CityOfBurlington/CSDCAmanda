USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VB_00025000]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VB_00025000]  @ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128) as  exec RsnSetLock DECLARE @NextRSN numeric(10) SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0)
 FROM AccountBillFee
 DECLARE @NextProcessRSN numeric(10)
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0)
 FROM FolderProcess
 DECLARE @NextDocumentRSN numeric(10)
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0)
 FROM FolderDocument
BEGIN 
/* VB Investigation, Building Inspection */  
 
DECLARE @AttemptDate DATETIME 
DECLARE @AttemptResult int 
DECLARE @strEmailTo Varchar(400) 
DECLARE @strDate VARCHAR(10) 
DECLARE @strTime VARCHAR(8) 
DECLARE @dtmScheduleDate DATETIME 
DECLARE @dtmScheduleEndDate DATETIME 
DECLARE @strScheduleDate NVARCHAR(20) 
DECLARE @strScheduleEndDate NVARCHAR(20) 
DECLARE @strFolderName VARCHAR(200) 
DECLARE @strSubject VARCHAR(100) 
DECLARE @strBody VARCHAR(4000) 
DECLARE @strFolderType CHAR(2) 
DECLARE @strEmailFromAddress VARCHAR(30) 
DECLARE @strEmailFromDisplay VARCHAR(30) 
DECLARE @AttemptRSN int 
DECLARE @AttemptCount int 
DECLARE @VB_Fee FLOAT 
DECLARE @FeeComment VARCHAR(100) 
 
SELECT @AttemptResult = ResultCode,  
@AttemptDate = AttemptDate, 
@AttemptRSN = AttemptRSN 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN 
AND FolderProcessAttempt.AttemptRSN =  
    (SELECT max(FolderProcessAttempt.AttemptRSN)  
     FROM FolderProcessAttempt 
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN) 
 
IF @AttemptResult = 25000 /*VB Confirmed*/ 
BEGIN 
 
	/* Set VB Confirmed Date Info field */ 
	UPDATE FolderInfo 
	  SET InfoValue = getdate(), 
		  InfoValueDateTime = getdate() 
	  WHERE infocode = 25000 
	  AND FolderRSN = @FolderRSN 
 
 
	/* Set Folder Status to VB Permit Pending (25010) */ 
	UPDATE Folder SET StatusCode = 25010 WHERE FolderRSN = @FolderRSN 
 
	EXEC usp_UpdateFolderCondition @FolderRSN, 'VB Confirmed' 
 
	/* Insert Vacant Building Fee */ 
	SET @FeeComment = 'Vacant Building Fee' 
 
	SELECT @VB_Fee = ValidLookup.LookupFee  
	FROM ValidLookup  
	WHERE (ValidLookup.LookupCode = 16)  
	AND (ValidLookUp.LookUp1 = 1) 
 
	EXEC TK_FEE_INSERT @FolderRSN, 202, @VB_Fee, @UserID, @FeeComment, 1, 0 
 
/* Generate Letter to send to owner */ 
/* Coming soon! */ 
 
END 
 
IF @AttemptResult = 25005 /*VB Tracking*/ 
BEGIN 
 
 
	/* Set Folder Status to VB Tracking (25005) */ 
	UPDATE Folder SET StatusCode = 25005 WHERE FolderRSN = @FolderRSN 
 
	EXEC usp_UpdateFolderCondition @FolderRSN, 'Tracking VB' 
 
        UPDATE FolderProcess  /* re-open this process */ 
        SET StatusCode = 1, StartDate = NULL, EndDate = NULL 
        WHERE FolderProcess.ProcessRSN = @ProcessRSN 
 
 
END 
 
IF @AttemptResult = 25070 /*Inspection Scheduled*/ 
    BEGIN 
	COMMIT TRANSACTION 
	BEGIN TRANSACTION 
 
	SELECT @strBody = 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20))  
	+ CHAR(10) + 'Location: ' + @strFolderName 
	+ CHAR(10) + CHAR(10) 
	+ CHAR(10) + 'Organization: ' + dbo.udf_GetFirstContractorOrgName(@FolderRSN)  
	+ CHAR(10) + 'Phone: ' + dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstContractorPhone(@FolderRSN)) 
	+ CHAR(10) + CHAR(10)  
	+ 'Owner: ' + dbo.udf_GetFirstPeopleName(2, @FolderRSN) 
	+ CHAR(10) + 'Phone: ' + dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(2, @FolderRSN)) + CHAR(10) + CHAR(10) + '[DefaultProcess_VB_00025000]' 
  
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
	--EXEC xspSendEmailAppointment @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate 
	EXEC webservices_CreateAppointment @strSubject, @strBody, @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, '', @strScheduleDate, @strScheduleEndDate, @strFolderName 
 
        /* Create workorder and email it to inspector */ 
	EXEC usp_SendInspectionWorkorder @FolderRSN, @ProcessRSN 
  
        /*Reopen process*/ 
        UPDATE FolderProcess SET StatusCode = 1, StartDate = NULL, EndDate = NULL 
          WHERE FolderProcess.ProcessRSN = @ProcessRSN 
 
        --SELECT @strScheduledDate = dbo.FormatDateTime(@ScheduleDate, 'MM/DD/YYYY HH:MM 12') 
 
        SET @strScheduleDate = 'Inspection Scheduled for ' + @strScheduleDate 
 
        EXEC usp_UpdateFolderCondition @FolderRSN, @strScheduleDate 
 
    END 
 
IF @AttemptResult = 25010 /*Not VB*/ 
BEGIN 
 
	/* Set Folder Status to Close (2) */ 
	UPDATE Folder SET StatusCode = 2 WHERE FolderRSN = @FolderRSN 
 
	EXEC usp_UpdateFolderCondition @FolderRSN, 'Not VB' 
 
END 
  
END
GO
