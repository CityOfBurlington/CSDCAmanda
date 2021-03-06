USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspInspectionDueLetter]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspInspectionDueLetter](@FolderRSN INT, @PeopleType INT, @UserId VARCHAR(30), @DatabaseEnum INT, @PrinterEnum INT)
AS
BEGIN

	DECLARE @Template VARCHAR(40)
	DECLARE @SQL varchar(80)
	DECLARE	@BaseFileName VARCHAR(80)
	DECLARE @Filename VARCHAR(80)
	DECLARE @AmandaPath VARCHAR(80)
	DECLARE @SavePath VARCHAR(80)
	DECLARE @DateStamp VARCHAR(10)
	DECLARE @ErrorCode INT

	SET @SavePath = '\\Patriot\E$\CSDC\Docs\' + LOWER(@UserID)
	SET @DateStamp = dbo.udf_GetDateAsString(GETDATE())
    
	SET @BaseFileName = 'InspectionDueLetter_' + @FolderRSN + '_' + @DateStamp
	SET @Template = '\\Patriot\C$\ActiveX\Amanda\Crystal\MH\InspectionDueLetter.rpt'
	SET @Filename = @SavePath + '\' + @BaseFileName + '.pdf'
	SET @AmandaPath = 'W:\Docs\' + LOWER(@UserID) + '\' + @BaseFileName + '.pdf'
    
	EXEC @ErrorCode = dbo.webservices_ExportCrystalReport @Template, @Filename, 20, 20, @FolderRSN, @PeopleType, '','','',''

	INSERT INTO Attachment (AttachmentRSN, TableName, TableRSN, AttachmentFileSuffix, AttachmentDesc, AttachmentDetail, 
		AttachmentFileAlias, StampDate, StampUser, DateGenerated, DosPath, OldDosPath, AttachmentCode)
	VALUES (dbo.udf_GetNextAttachmentRSN(), 'Folder', @FolderRSN, 'PDF', 'Inspection Due Letter',CAST(@FolderRSN AS VARCHAR(8)),  
		@BaseFileName, GetDate(), 'sa', GetDate(), @AmandaPath, @AmandaPath, 4)

END



GO
