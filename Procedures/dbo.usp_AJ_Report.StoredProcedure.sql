USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AJ_Report]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AJ_Report] @JobDetailID INT
AS
BEGIN

DECLARE @ReportName VARCHAR(100)
DECLARE @ReportDesc VARCHAR(1000)
DECLARE @ReportPath VARCHAR(100)
DECLARE @FullFilePath VARCHAR(200)
DECLARE @FileExtension VARCHAR(5)
DECLARE @TemplatePath VARCHAR(200)
DECLARE @BaseFileName VARCHAR(100)
DECLARE @ExportFormat INT
DECLARE @DatabaseEnum INT
DECLARE @strDateTime VARCHAR(14)
DECLARE @ToList VARCHAR(500)
DECLARE @DotPos INT
DECLARE @SlashPos INT
DECLARE @Ptr INT

SET @strDateTime = dbo.udf_GetDateTimeAsString(GETDATE())
SET @ReportPath = '\\cobintranet\temp\'

SELECT @ReportName = AJD.DetailDescription, @ExportFormat = AJD.ExportFormatEnum, @DatabaseEnum = AJD.DatabaseEnum, @TemplatePath = CR.TemplatePath
FROM IntranetApplications.dbo.AutomatedJobDetails AJD
INNER JOIN IntranetApplications.dbo.ReportTemplates CR ON AJD.ReportID = CR.ReportID
WHERE AJD.JobDetailID = @JobDetailID

SELECT @FileExtension = FileExtension FROM IntranetApplications.dbo.CrystalExportFormats WHERE ExportFormatID = @ExportFormat

/* Find the base file name from the Template Path */
SET @DotPos = CHARINDEX('.rpt',@TemplatePath)
SET @SlashPos = 0
SET @Ptr = 1
WHILE @Ptr <> 0
BEGIN
	SET @Ptr = CHARINDEX('\', @TemplatePath, @SlashPos)
	IF @Ptr <> 0 SET @SlashPos = @Ptr + 1
END
SET @BaseFileName = SUBSTRING(@TemplatePath, @SlashPos, @DotPos - @SlashPos)

SET @ReportDesc = 'The report named ' + @ReportName + ' run at ' + dbo.FormatDateTime(getdate(),'SHORTDATEANDTIME') + ' is attached.'
SET @FullFilePath = @ReportPath + @BaseFileName + '_' + @strDateTime + '.' + @FileExtension 

EXEC dbo.webservices_ExportCrystalReport @TemplatePath, @FullFilePath, @ExportFormat, @DatabaseEnum, '', '', '', '', '', ''

DECLARE CurGeneral CURSOR FOR
	SELECT AJC.EmailAddress 
	FROM IntranetApplications.dbo.AutomatedJobDistribution AJD
	INNER JOIN  IntranetApplications.dbo.AutomatedJobContacts AJC ON AJD.ContactID = AJC.ContactID
	WHERE AJD.JobDetailID = @JobDetailID

	OPEN curGeneral
	FETCH NEXT FROM curGeneral INTO @ToList
	WHILE @@FETCH_STATUS = 0
		BEGIN
		EXEC dbo.webservices_SendEmail @ReportName, @ReportDesc, 'emailautomation@burlingtonvt.gov', 'Automated Jobs', 
			@ToList, @FullFilePath

		FETCH NEXT FROM curGeneral INTO @ToList
	END

	/* Close the cursor */
	CLOSE curGeneral

	/* Deallocate the cursor */
	DEALLOCATE curGeneral

END



GO
