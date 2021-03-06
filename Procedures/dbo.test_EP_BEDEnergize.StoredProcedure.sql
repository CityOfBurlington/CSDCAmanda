USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[test_EP_BEDEnergize]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[test_EP_BEDEnergize] AS
BEGIN

DECLARE @intFolderRSN INT
DECLARE @strFolderRSN VARCHAR(10)
DECLARE @strSavePath VARCHAR(100)
DECLARE @intCOMSuccess INT
DECLARE @strReportTemplate VARCHAR(400)
DECLARE @intResultCode INT

DECLARE @strDate VARCHAR(10)
DECLARE @strTime VARCHAR (8)
DECLARE @strScheduleDate VARCHAR (30)
DECLARE @strScheduleEndDate VARCHAR(30)

SET @intFolderRSN = 220278


SET @strFolderRSN = CAST(@intFolderRSN AS VARCHAR(10))
SET @strSavePath = '\\Patriot\CSDC\Docs\dbaron\EP_BED_Energize_' + @strFolderRSN + '.doc'
SET @strReportTemplate = '\\Patriot\CSDC\Docs\Template\CrystalReportTemplates\EP_BEDEnergize.rpt'


EXEC @intCOMSuccess = webservices_ExportCrystalReport @strReportTemplate, @strSavePath, 10, 20, @strFolderRSN,'','','','','' 
Print @intCOMSuccess

END
GO
