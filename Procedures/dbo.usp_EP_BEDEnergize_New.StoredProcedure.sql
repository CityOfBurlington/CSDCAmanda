USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_EP_BEDEnergize_New]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[usp_EP_BEDEnergize_New] AS
BEGIN

DECLARE @intFolderRSN INT
DECLARE @strFolderRSN VARCHAR(10)
DECLARE @PermitNum VARCHAR(10)
DECLARE @strFolderName VARCHAR(400)
DECLARE @intBEDNum INT
DECLARE @intInfoCode INT
DECLARE @intDocCode INT
DECLARE @strOwner VARCHAR(40)
DECLARE @strContractor VARCHAR(40)
DECLARE @strNotifyDate VARCHAR(30)
DECLARE @intProcessRSN INT
DECLARE @intDocumentRSN INT

DECLARE @strSavePath VARCHAR(100)
DECLARE @intCOMEmailSuccess INT
DECLARE @intCOMSuccess INT
DECLARE @strReportTemplate VARCHAR(400)
DECLARE @intResultCode INT
DECLARE @strBody VARCHAR(800)
DECLARE @strSubject VARCHAR(50)
DECLARE @intOwnerRSN INT

DECLARE @strDate VARCHAR(10)
DECLARE @strTime VARCHAR (8)
DECLARE @strScheduleDate VARCHAR (30)
DECLARE @strScheduleEndDate VARCHAR(30)

DECLARE @strEmailTo VARCHAR(400)
DECLARE @strEmailAddr VARCHAR(40)

SELECT @intDocumentRSN  = dbo.udf_GetNextDocumentRSN()

SET @strEmailTo = 'swarren@ci.burlington.vt.us'
DECLARE Lookup_Cursor CURSOR FOR

/* Lookup the email addresses for the people who will get these notices. */
SELECT LookupString FROM ValidLookup WHERE LookupCode = 30000
OPEN Lookup_Cursor;
FETCH NEXT FROM Lookup_Cursor INTO @strEmailAddr;
IF @@FETCH_STATUS = 0 SET @strEmailTo = @strEmailTo + '; ' + @strEmailAddr
WHILE @@FETCH_STATUS = 0
   BEGIN
 	  FETCH NEXT FROM Lookup_Cursor INTO @strEmailAddr
 	  IF @@FETCH_STATUS = 0 SET @strEmailTo = @strEmailTo + '; ' + @strEmailAddr
   END
CLOSE Lookup_Cursor;
DEALLOCATE Lookup_Cursor;

DECLARE curFolders CURSOR FOR 

SELECT Folder.FolderRSN, Folder.FolderYear + '-' + Folder.FolderSequence AS PermitNo, Folder.FolderName, 
  dbo.udf_GetFirstOwner(dbo.Folder.FolderRSN) AS Owner, 
  dbo.udf_GetFirstContractorName(dbo.Folder.FolderRSN) AS Contractor, FolderProcessAttempt.ResultCode, 
  dbo.FormatDateTime(FolderProcessAttempt.AttemptDate, 'LONGDATE') AS NotifyDate, FolderProcess.ProcessRSN, 
  FolderInfo.InfoValue AS BEDNumber, FolderInfo.InfoCode AS InfoCode
FROM Folder 
INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
INNER JOIN FolderInfo ON Folder.FolderRSN = FolderInfo.FolderRSN AND InfoCode IN(30220,30221,30222,30223,30224,30225,30226,30227,30228,30229)
WHERE Folder.FolderType = 'EP'
AND FolderProcess.ProcessCode = 30103 /*Service*/
--AND FolderProcess.StatusCode = 1
AND FolderProcessAttempt.ResultCode = 30115 /*Send to BED*/
AND FolderInfo.InfoValue IS NOT Null
AND NOT EXISTS (SELECT * FROM FolderProcessInfo WHERE InfoCode = 30005 AND FolderProcess.ProcessRSN = FolderProcessInfo.ProcessRSN)
ORDER BY Folder.FolderRSN, InfoCode
OPEN curFolders

FETCH NEXT FROM curFolders INTO @intFolderRSN, @PermitNum, @strFolderName, @strOwner, @strContractor, 
	@intResultCode, @strNotifyDate, @intProcessRSN, @intBEDNum, @intInfoCode

WHILE @@FETCH_STATUS = 0 BEGIN
	SET @strFolderRSN = CAST(@intFolderRSN AS VARCHAR(10))
	SET @strSavePath = '\\Patriot\CSDC\Docs\Savepath\EP\EP_BED_Energize_' + @strFolderRSN + '.doc'
	SET @strBody = 'Following an inspection on ' + @strNotifyDate + ', ' + @strFolderName + ' has been approved for electric service.'
	SET @strSubject = 'Energize Notice for ' + @strFolderName
	SELECT @intOwnerRSN = dbo.udf_GetFirstPeopleRSNByPeopleCode(2, @intFolderRSN)
	SET @intDocCode = @intInfoCode - 210

	SET @strReportTemplate = '\\Patriot\CSDC\Docs\Template\CrystalReportTemplates\EP_BEDEnergize.rpt'

	SET @strDate = CONVERT(varchar(10), getdate(), 101)
	Set @strTime = CONVERT(varchar(8), getdate(), 108)
	SET @strScheduleDate = @strDate + ' ' + @strTime

	SET @strDate = CONVERT(varchar(10), getdate(), 101)
	Set @strTime = CONVERT(varchar(8), DATEADD(mi, 15, getdate()), 108)
	SET @strScheduleEndDate = @strDate + ' ' + @strTime

	EXEC @intCOMSuccess = webservices_ExportCrystalReport @strReportTemplate, @strSavePath, 10, 20, @intFolderRSN,'','','','','' 

	IF @intCOMSuccess = 0 BEGIN
		EXEC webservices_SendEmail @strSubject, @strBody, 'amanda@ci.burlington.vt.us', 'AMANDA', @strEmailTo, @strSavePath
	END

	INSERT INTO FolderProcessInfo (ProcessRSN, InfoCode, InfoValue, InfoValueDatetime, FolderRSN) 
		VALUES (@intProcessRSN, 30005, getdate(), getdate(), @intFolderRSN)

	IF EXISTS (SELECT DocumentRSN FROM FolderDocument WHERE FolderDocument.FolderRSN = @intFolderRSN AND DocumentCode = @intDocCode)
	BEGIN
		UPDATE FolderDocument
		SET DosPath = REPLACE(@strSavePath, '\\Patriot\CSDC', 'W:'),
		DateGenerated = GetDate(),
		DocumentComment = 'Auto-generated: BED Energize Notice',
		PeopleRSN = @intOwnerRSN,
		PeopleCode = 2,
		LinkCode = 1
		WHERE FolderRSN = @intFolderRSN
		AND DocumentCode = @intDocCode/*EP 15 Day Violation Confirmation*/
		AND DateGenerated IS NULL
	END
	ELSE
	BEGIN
		INSERT INTO FolderDocument (DocumentRSN, FolderRSN, DocumentCode, PeopleCode, PeopleRSN, DateGenerated, DateSent,
			DocumentStatus, DosPath, DocumentComment, LinkCode) 
			VALUES (@intDocumentRSN, @intFolderRSN, @intDocCode, 2, @intOwnerRSN, GetDate(), GetDate(), 2, 
			REPLACE(@strSavePath, '\\Patriot\CSDC', 'W:'), 'Auto-generated: BED Energize Notice', 1)
	END

	FETCH NEXT FROM curFolders INTO @intFolderRSN, @PermitNum, @strFolderName, @strOwner, @strContractor, @intResultCode, 
		@strNotifyDate, @intProcessRSN, @intBEDNum, @intInfoCode
END

CLOSE curFolders
DEALLOCATE curFolders

END

GO
