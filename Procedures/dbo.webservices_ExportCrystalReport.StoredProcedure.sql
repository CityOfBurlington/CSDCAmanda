USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[webservices_ExportCrystalReport]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[webservices_ExportCrystalReport](@ReportTemplate VARCHAR(800), @FileNameWithPath VARCHAR(800),
@ExportFormat  VARCHAR(3), @DatabaseEnum VARCHAR(20), 
@Param1 VARCHAR(400), @Param2 VARCHAR(400), @Param3 VARCHAR(400), 
@Param4 VARCHAR(400), @Param5 VARCHAR(400), @Param6 VARCHAR(400))
AS
BEGIN

	/* @ExportFormat: 10 = Word (.doc); 20 = Pdf (.pdf)
	   @DatabaseEnum: 20 = AMANDA_Production */


	DECLARE @error VARCHAR(8000)
	DECLARE @response varchar(8000) 

	SET @ReportTemplate = REPLACE(@ReportTemplate, '&', '+')
	SET @FileNameWithPath = REPLACE(@FileNameWithPath, '&', '+')
	SET @ExportFormat = REPLACE(@ExportFormat, '&', '+')
	SET @DatabaseEnum = REPLACE(@DatabaseEnum, '&', '+')
	SET @Param1 = REPLACE(@Param1, '&', '+')
	SET @Param2 = REPLACE(@Param2, '&', '+')
	SET @Param3 = REPLACE(@Param3, '&', '+')
	SET @Param4 = REPLACE(@Param4, '&', '+')
	SET @Param5 = REPLACE(@Param5, '&', '+')
	SET @Param6 = REPLACE(@Param6, '&', '+')

	DECLARE @SQL nVARCHAR(4000)

	SET @SQL = replace('http://cobintranet:81/WebServices.aspx?Action=ExportCrystalReport&ReportTemplate=' + @ReportTemplate + '&FileNameWithPath=' + @FileNameWithPath + '&ExportFormat=' + @ExportFormat + '&DatabaseEnum=' + @DatabaseEnum + '&Param1=' + @Param1 + '&Param2=' + @Param2 + '&Param3=' + @Param3 + '&Param4=' + @Param4 + '&Param5=' + @Param5 + '&Param6=' + @Param6, ' ', '%20')

	EXEC HTTP_POST @SQL, @response, @error
END
GO
