USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_SendInspectionWorkorder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SendInspectionWorkorder] (@pFolderRSN INT, @pProcessRSN INT)
AS
BEGIN

DECLARE @strFolderRSN VARCHAR(10)
DECLARE @strProcessRSN VARCHAR(10)
DECLARE @strFolderName VARCHAR(400)
DECLARE @strFolderType VARCHAR(4)
DECLARE @strUserID VARCHAR(10)
DECLARE @strTime VARCHAR(20)

DECLARE @strSavePath VARCHAR(100)
DECLARE @strFileName VARCHAR(50)
DECLARE @strReportTemplate VARCHAR(400)
DECLARE @strSubject VARCHAR(40)
DECLARE @strBody VARCHAR(800)
DECLARE @strEmailTo VARCHAR(400)
DECLARE @intCOMSuccess INT

	SELECT @strFolderName = Folder.FolderName, @strFolderType = Folder.FolderType
	FROM Folder 
	WHERE Folder.FolderRSN = @pFolderRSN

	SELECT @strUserID = FolderProcess.AssignedUser
	FROM FolderProcess
	WHERE FolderProcess.ProcessRSN = @pProcessRSN

	SELECT @strEmailTo = ValidUser.EmailAddress
	FROM ValidUser
	WHERE UserID = @strUserID

	SET @strFolderRSN = CAST(@pFolderRSN AS VARCHAR(10))
	SET @strProcessRSN = CAST(@pProcessRSN AS VARCHAR(10))

	SET @strTime = dbo.udf_GetTimeAsString(getdate())
	SET @strReportTemplate = '\\Patriot\CSDC\Docs\Template\CrystalReportTemplates\' + @strFolderType + 'InspectorWorkorder.rpt'
	SET @strFileName = @strFolderType + 'InspectorWorkorder_' + @strFolderRSN + '_' + @strProcessRSN + '_' + @strTime + '.pdf'
	SET @strSavePath = '\\Patriot\CSDC\Docs\Savepath\' + @strFolderType + '\' + @strFileName
	SET @strSubject = @strFolderType + ' Inspection Workorder'
	SET @strBody = 'Inspection workorder for ' + @strFolderName + ' attached. ' 
--RAISERROR (@strProcessRSN, 16, -1)

	EXEC @intCOMSuccess = webservices_ExportCrystalReport @strReportTemplate, @strSavePath, 20, 20, @strFolderRSN, @strProcessRSN, '', '', '', ''

	--SET @strEmailTo = 'dbaron@ci.burlington.vt.us'
	IF @intCOMSuccess = 0 BEGIN
		EXEC webservices_SendEmail @strSubject, @strBody, 'amanda@ci.burlington.vt.us', 'AMANDA', @strEmailTo, @strSavePath
	END

	INSERT INTO Attachment (AttachmentRSN, TableName, TableRSN, AttachmentFileSuffix, AttachmentDesc, AttachmentDetail, 
	   AttachmentFileAlias, StampDate, StampUser, DateGenerated, DosPath, OldDosPath, AttachmentCode) 
	VALUES (dbo.udf_GetNextAttachmentRSN(), 'Folder', @pFolderRSN, 'PDF', @strSubject, @strFolderName,
	   @strFileName, GetDate(), 'sa', GetDate(), @strSavePath, @strSavePath, 4)

END

GO
