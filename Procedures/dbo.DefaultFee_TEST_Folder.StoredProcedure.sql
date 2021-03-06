USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_TEST_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultFee_TEST_Folder] @FolderRSN numeric(10), @UserId varchar(128) as DECLARE @NextRSN numeric(10) exec RsnSetLock SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) FROM AccountBillFee 
BEGIN 
DECLARE @ProcessRSN INT 
 
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
 
SET @FolderRSN = 237069 
SET @UserID = 'dbaron' 
SET @ProcessRSN = 16146469 
  
SELECT @strFolderType = Folder.FolderType,  
	   @AttemptResult = FolderProcessAttempt.Resultcode,  
       @AttemptRSN = FolderProcessAttempt.AttemptRSN,  
 	   @AttemptComment = FolderProcessAttempt.AttemptComment,  
	   @strEmailTo = 'dbaron@ci.burlington.vt.us; ' + ValidUser.EmailAddress,  
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
  
COMMIT TRANSACTION  
BEGIN TRANSACTION  
  
SELECT @strBody = 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20))   
       + CHAR(10) + 'Location: ' + @strFolderName  
       + CHAR(10) + CHAR(10)  
       + 'Owner: ' + ISNULL(dbo.udf_GetFirstPeopleName(2, @FolderRSN),'') 
       + CHAR(10) + 'Phone: ' + ISNULL(dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(2, @FolderRSN)), '') 
   
SET @strEmailFromAddress = 'amanda@ci.burlington.vt.us'  
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
  
--RAISERROR('Calling webservice to schedule inspection', 16, -1)  
  
/* Create appointment on Outlook calendar */  
EXEC webservices_CreateAppointment_Test @strSubject, @strBody, @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, '', @strScheduleDate, @strScheduleEndDate, @strFolderName  
--EXEC xspSendEmailAppointment @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate  
 
COMMIT TRANSACTION  
BEGIN TRANSACTION  
  
END
GO
