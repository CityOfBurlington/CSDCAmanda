USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspGenerateBianchi]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[xspGenerateBianchi](@FolderRSN INT, @PropertyRSN INT, @UserId VARCHAR(30), @DatabaseEnum INT, @ExportFormat INT)
AS
BEGIN

DECLARE @UserPath VARCHAR(100)
DECLARE @BaseFileName VARCHAR(100)
DECLARE @FullFileName VARCHAR(100)
DECLARE @FullFilePath VARCHAR(200)
DECLARE @FileExtension VARCHAR(5)
DECLARE @AttachmentCode INT

DECLARE @strYear CHAR(4)
DECLARE @strMonth CHAR(2)
DECLARE @strDay CHAR(2)
DECLARE @strDate CHAR(8)

SET @strYear = YEAR(GETDATE())
SET @strMonth = CAST(MONTH(GETDATE()) AS CHAR(2))
SET @strDay = CAST(DAY(GETDATE()) AS CHAR(2))
IF LEN(@strDay) = 1 SET @strDay = '0' + @strDay
IF LEN(@strMonth) = 1 SET @strMonth = '0' + @strMonth
SET @strDate = @strYear+@strMonth+@strDay

If @ExportFormat = 10
BEGIN
	SET @FileExtension = 'doc'
    SET @AttachmentCode = 1
END
Else
BEGIN
	SET @FileExtension = 'pdf'
    SET @AttachmentCode = 4
End

/* File Path is \\Patriot\csdc\docs\<username>\Bianchi_<folderRsn>_<yyyymmdd>.doc */
SET @UserPath = '\\Patriot\csdc\docs\'+LTrim(Rtrim(convert(varchar,@UserID)))+'\'
SET @BaseFileName = 'Bianchi_'+Cast(@FolderRSN AS VARCHAR(8))+'_'+@strDate
SET @FullFileName = @BaseFileName + '.doc'
SET @FullFilePath = @UserPath + @FullFileName

EXEC dbo.webservices_ExportCrystalReport '\\Patriot\c$\ActiveX\Amanda\Crystal\Bianchi.rpt', @FullFilePath, @ExportFormat, 
	@DatabaseEnum, @PropertyRSN, '', '', '', '', ''

INSERT INTO Attachment (AttachmentRSN, TableName, TableRSN, AttachmentFileSuffix, AttachmentDesc, AttachmentDetail, 
	AttachmentFileAlias, StampDate, StampUser, DateGenerated, DosPath, OldDosPath, AttachmentCode) 
VALUES (dbo.udf_GetNextAttachmentRSN(), 'Folder', @FolderRSN, @FileExtension, 'Bianchi Form', CAST(@FolderRSN AS VARCHAR(8)), 
	@BaseFileName, GetDate(), 'sa', GetDate(), @FullFilePath, @FullFilePath, @AttachmentCode)

END

GO
