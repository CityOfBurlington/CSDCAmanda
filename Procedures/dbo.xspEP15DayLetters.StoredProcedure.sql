USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspEP15DayLetters]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspEP15DayLetters] AS
BEGIN

DECLARE @intFolderRSN INT
DECLARE @strFolderRSN VARCHAR(10)
DECLARE @strEmailTo VARCHAR(255)
DECLARE @strFolderName VARCHAR(400)
DECLARE @strSavePath VARCHAR(100)
DECLARE @intCOMEmailSuccess INT
DECLARE @intCOMSuccess INT
DECLARE @strReportTemplate VARCHAR(400)
DECLARE @intResultCode INT
DECLARE @strBody VARCHAR(800)
DECLARE @strSubject VARCHAR(800)
DECLARE @intOwnerRSN INT

DECLARE @strDate VARCHAR(10)
DECLARE @strTime VARCHAR (8)
DECLARE @strScheduleDate VARCHAR (30)
DECLARE @strScheduleEndDate VARCHAR(30)

DECLARE @strReminderDate VARCHAR(30)

DECLARE curFolders CURSOR FOR 
SELECT Folder.FolderRSN, 
ValidUser.EmailAddress, 
Folder.FolderName,
dbo.FormatDateTime(FolderInfo.InfoValueDateTime, 'MM/DD/YYYY') AS ReminderDate,
FolderProcessAttempt.ResultCode
FROM Folder
INNER JOIN FolderInfo ON Folder.FolderRSN = FolderInfo.FolderRSN
INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
INNER JOIN ValidUser ON FolderProcessAttempt.AttemptBy = ValidUser.UserId
WHERE Folder.FolderType = 'EP'
AND FolderInfo.InfoCode = 1000
AND FolderProcess.ProcessCode = 30007 /*Final EP*/
AND FolderProcess.StatusCode = 1
AND FolderProcessAttempt.ResultCode IN(20200 /*Reinspection*/, 20201/*Send Back Completion Form*/)
AND FolderInfo.InfoValueDateTime < GetDate()

OPEN curFolders

FETCH NEXT FROM curFolders INTO @intFolderRSN, @strEmailTo, @strFolderName, @strReminderDate, @intResultCode


WHILE @@FETCH_STATUS = 0 BEGIN
	SET @strFolderRSN = CAST(@intFolderRSN AS VARCHAR(10))
	SET @strSavePath = '\\Patriot\CSDC\Docs\Savepath\EP\EP_15_Day_' + @strFolderRSN + '.pdf'
	SET @strBody = 'The 15 day period for RSN #' + @strFolderRSN + ' (' + @strFolderName + '), expired on ' + @strReminderDate
	SET @strSubject = '15 day EP notice'
	SELECT @intOwnerRSN = dbo.udf_GetFirstPeopleRSNByPeopleCode(2, @intFolderRSN)

	IF @intResultCode = 20201 BEGIN/*Send Back Completion Form*/
		SET @strReportTemplate = '\\Patriot\CSDC\Docs\Template\CrystalReportTemplates\EP_15DayCompletionForm.rpt'
		END
	ELSE/*Reinspection*/
		BEGIN
		SET @strReportTemplate = '\\Patriot\CSDC\Docs\Template\CrystalReportTemplates\EP_15DayReinspection.rpt'
	END

	SET @strDate = CONVERT(varchar(10), getdate(), 101)
	Set @strTime = CONVERT(varchar(8), getdate(), 108)
	SET @strScheduleDate = @strDate + ' ' + @strTime

	SET @strDate = CONVERT(varchar(10), getdate(), 101)
	Set @strTime = CONVERT(varchar(8), DATEADD(mi, 15, getdate()), 108)
	SET @strScheduleEndDate = @strDate + ' ' + @strTime

	EXEC @intCOMSuccess = webservices_ExportCrystalReport @strReportTemplate, @strSavePath, 20, 20, @strFolderRSN, '', '', '', '', ''

	IF @intCOMSuccess = 0 BEGIN
		EXEC webservices_SendEmail @strSubject, @strBody, 'amanda@ci.burlington.vt.us', 'EP Scheduler', @strEmailTo, @strSavePath
	END

	DELETE FROM FolderInfo
	WHERE FolderRSN = @intFolderRSN 
	AND InfoCode = 1000

	IF @intResultCode = 20201 BEGIN/*Send Back Completion Form*/
		UPDATE FolderDocument
		SET DosPath = REPLACE(@strSavePath, '\\Patriot\CSDC', 'W:'),
		DateGenerated = GetDate(),
		DocumentComment = 'Auto-generated: 15 day period expired',
		PeopleRSN = @intOwnerRSN,
		PeopleCode = 2,
		LinkCode = 1
		WHERE FolderRSN = @intFolderRSN
		AND DocumentCode = 30009/*EP 15 Day Violation Confirmation*/
		AND DateGenerated IS NULL
		END
	ELSE/*Reinspection*/
		BEGIN
		UPDATE FolderDocument
		SET DosPath = REPLACE(@strSavePath, '\\Patriot\CSDC', 'W:'),
		DateGenerated = GetDate(),
		DocumentComment = 'Auto-generated: 15 day period expired',
		PeopleRSN = @intOwnerRSN,
		PeopleCode = 2,
		LinkCode = 1
		WHERE FolderRSN = @intFolderRSN
		AND DocumentCode = 30008/*EP 15 Day Violation Reinspect*/
		AND DateGenerated IS NULL
	END

	FETCH NEXT FROM curFolders INTO @intFolderRSN, @strEmailTo, @strFolderName, @strReminderDate, @intResultCode
END

CLOSE curFolders
DEALLOCATE curFolders

END






GO
