USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TestAppointments]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[TestAppointments]
@ProcessRSN INT, @FolderRSN INT, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN INT 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN INT 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN INT 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 

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
DECLARE @Condition VARCHAR(2000)

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

SELECT @strSubject = @strFolderType + ' - ' + @strFolderName + ' - FolderRSN ' + @strSubject

--IF @AttemptResult = 20045 /*Inspection Scheduled*/
    BEGIN

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

    SET @strEmailFromAddress = @strFolderType + '_Scheduler'
    SET @strEmailFromDisplay = @strFolderType + ' Scheduler'

	SET @strDate = CONVERT(varchar(10), @dtmScheduleDate, 101)
	Set @strTime = CONVERT(varchar(8), @dtmScheduleDate, 108)
	SET @strScheduleDate = @strDate + ' ' + @strTime

	SET @strDate = CONVERT(varchar(10), @dtmScheduleEndDate, 101)
	Set @strTime = CONVERT(varchar(8), @dtmScheduleEndDate, 108)
	SET @strScheduleEndDate = @strDate + ' ' + @strTime

	SELECT @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate
	EXEC xspScheduleInspection @UserID, @FolderRSN, @ProcessRSN, 1, 1, 20

 --@strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, @strFolderName, @strScheduleDate, @strScheduleEndDate
    /*Reopen process*/
    --UPDATE FolderProcess
    --SET StatusCode = 1
    --WHERE ProcessRSN = @ProcessRSN
END



GO
