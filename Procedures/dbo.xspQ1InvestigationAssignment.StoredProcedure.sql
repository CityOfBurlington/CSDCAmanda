USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspQ1InvestigationAssignment]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[xspQ1InvestigationAssignment]
	(@FolderRSN INT, 
	@QCFolderRSN INT, 
	@UserID VARCHAR(128), 
	@Location VARCHAR(400), 
	@Body VARCHAR(2000), 
	@InspectorEmail VARCHAR(500), 
	@AdminEmail VARCHAR(500), 
	@ComplaintAckLetterYN VARCHAR(1))
AS
BEGIN

	DECLARE @intInvokeSuccess INT
	DECLARE @UserPath VARCHAR(100)
	DECLARE @BaseFileName VARCHAR(100)
	DECLARE @FullFileName VARCHAR(100)
	DECLARE @FullFilePath VARCHAR(200)
	DECLARE @FileExtension VARCHAR(5)
	DECLARE @AttachmentCode INT
	DECLARE @ExportFormat INT
	DECLARE @DatabaseEnum INT
	DECLARE @Subject VARCHAR(40)
	
	/* If an acknowledgement letter is to be generated, the Q1 Folder must have a complainant among the Folder People */
	IF @ComplaintAckLetterYN = 'Y'
	BEGIN
		IF NOT EXISTS (SELECT PeopleRSN FROM FolderPeople WHERE FolderRSN = @FolderRSN AND PeopleCode = 7)
		BEGIN
			RAISERROR ('The Folder must have a Complainant to send the Acknowledgement Letter to.', 16, -1)
			RETURN
		END
	END
	
	/* @ExportFormat: 10 = Word (.doc); 20 = Pdf (.pdf)
	   @DatabaseEnum: 20 = AMANDA_Production 
	   @AttachmentCode: 1 = Word; 4 = PDF	*/

	SET @DatabaseEnum = 20
		
	/* Create, send and attach the Work Order (as .pdf) */
	/* File Path is \\Patriot\csdc\docs\<username>\Q1WorkOrder_<folderRsn>.pdf */
	SET @ExportFormat = 20
	SET @AttachmentCode = 4
	--SET @UserPath = '\\Patriot\csdc\docs\'+@UserID+'\'
	
	SET @UserPath = '\\Patriot\csdc\docs\'+LTrim(Rtrim(convert(varchar,@UserID)))+'\'
	
	SET @BaseFileName = 'Q1WorkOrder_'+Cast(@FolderRSN AS VARCHAR(8))
	SET @FileExtension = 'pdf'
	SET @FullFileName = @BaseFileName + '.' + @FileExtension
	SET @FullFilePath = @UserPath + @FullFileName
	SET @intInvokeSuccess = 0

	/* Create and export the Crystal Report */
	EXEC @intInvokeSuccess = dbo.webservices_ExportCrystalReport '\\Patriot\c$\ActiveX\Amanda\Crystal\Q1\ComplaintWorkorder.rpt', 
		@FullFilePath, @ExportFormat, @DatabaseEnum, @FolderRSN, '', '', '', '', ''

	/* Attach the Work Order to the QC Folder */
	INSERT INTO Attachment (AttachmentRSN, TableName, TableRSN, AttachmentFileSuffix, AttachmentDesc, AttachmentDetail, 
		AttachmentFileAlias, StampDate, StampUser, DateGenerated, DosPath, OldDosPath, AttachmentCode) 
	VALUES (dbo.udf_GetNextAttachmentRSN(), 'Folder', @QCFolderRSN, @FileExtension, 'Work Order', CAST(@QCFolderRSN AS VARCHAR(8)), 
		@BaseFileName, GetDate(), 'sa', GetDate(), @FullFilePath, @FullFilePath, @AttachmentCode)

	/* Email the Work Order to the Inspector */
	SET @Subject = 'Q1 Inspection Work Order for ' + @Location
	IF @intInvokeSuccess = 0 BEGIN
		EXEC webservices_SendEmail @Subject, @Body, 'amanda@ci.burlington.vt.us', 'AMANDA', @InspectorEmail, @FullFilePath
	END

	/* If called for, create and attach the Acknowledgement letter (as Word document) */
	/* File Path is \\Patriot\csdc\docs\<username>\Q1AcknowledgeLetter_<folderRsn>.doc */
	IF @ComplaintAckLetterYN = 'Y'
	BEGIN
		-- Having trouble with Word version of this letter wanting to print to legal size. Let's try .pdf
		--SET @ExportFormat = 10
		--SET @AttachmentCode = 1
		SET @ExportFormat = 20
		SET @AttachmentCode = 4
		--SET @UserPath = '\\Patriot\csdc\docs\'+@UserID+'\'
		
		SET @UserPath = '\\Patriot\csdc\docs\'+LTrim(Rtrim(convert(varchar,@UserID)))+'\'
		
		SET @BaseFileName = 'Q1AcknowledgeLetter_'+Cast(@FolderRSN AS VARCHAR(8))
		SET @FileExtension = 'pdf'
		SET @FullFileName = @BaseFileName + '.' + @FileExtension
		SET @FullFilePath = @UserPath + @FullFileName
		SET @intInvokeSuccess = 0

		/* Create and export the Crystal Report */
		EXEC @intInvokeSuccess = dbo.webservices_ExportCrystalReport '\\Patriot\c$\ActiveX\Amanda\Crystal\Q1\ComplaintAcknowledgementLetter.rpt', 
			@FullFilePath, @ExportFormat, @DatabaseEnum, @FolderRSN, '', '', '', '', ''

		/* Attach the Work Order to the Folder */
		INSERT INTO Attachment (AttachmentRSN, TableName, TableRSN, AttachmentFileSuffix, AttachmentDesc, AttachmentDetail, 
			AttachmentFileAlias, StampDate, StampUser, DateGenerated, DosPath, OldDosPath, AttachmentCode) 
		VALUES (dbo.udf_GetNextAttachmentRSN(), 'Folder', @FolderRSN, @FileExtension, 'Complaint Acknowledgement Letter', 
			CAST(@FolderRSN AS VARCHAR(8)), @BaseFileName, GetDate(), 'sa', GetDate(), @FullFilePath, @FullFilePath, @AttachmentCode)
	END
END




GO
