USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspBushorQCReport]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspBushorQCReport](@StartDate datetime, @EndDate datetime)
AS
BEGIN

	DECLARE @AllFoldersCount		INT
	DECLARE @AllProcessAttempts		INT
	DECLARE @AllInspProcessAttempts INT
	DECLARE @AllAdminProcessAttempts INT
	DECLARE @NoActionRecorded		INT
	DECLARE @FoldersNotClosed		INT
	DECLARE @FoldersClosed			INT
	DECLARE	@AvgDaysToClose			INT
	DECLARE @InitContactCount		INT
	DECLARE @InitContactNumUnits	INT
	DECLARE @InitContactAvgHomeAge	REAL
	DECLARE @InitInspectionCount	INT
	DECLARE @InitInspectionNumUnits	INT
	DECLARE @InitInspectionAvgHomeAge	REAL
	DECLARE @1stFollowupCount		INT
	DECLARE @1stFollowupNumUnits	INT
	DECLARE @1stFollowupAvgHomeAge	REAL
	DECLARE @2ndFollowupCount		INT
	DECLARE @2ndFollowupNumUnits	INT
	DECLARE @2ndFollowupAvgHomeAge	REAL
	DECLARE @3rdFollowupCount		INT
	DECLARE @3rdFollowupNumUnits	INT
	DECLARE @3rdFollowupAvgHomeAge	REAL
	DECLARE @OtherProcessCount		INT
	DECLARE @OtherProcessNumUnits	INT
	DECLARE @OtherProcessAvgHomeAge	REAL

	DECLARE @intPageSize		INT
	DECLARE @intMinPageCount	INT
	DECLARE @intTotalPageCount	INT
	DECLARE @intTotalRecords	INT

DECLARE @pintFolderRSN INT

	/* Count All QC Folders */
	SELECT @AllFoldersCount = COUNT(FolderRSN) FROM dbo.Folder 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate

	/* Count All QC Process Attempts */
	SELECT @AllProcessAttempts = COUNT(dbo.Folder.FolderRSN)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.FolderProcessAttempt ON dbo.FolderProcess.ProcessRSN = dbo.FolderProcessAttempt.ProcessRSN
	WHERE dbo.Folder.FolderType = 'QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode <> 999999

	/* Count Inspection QC Process Attempts */
	SELECT @AllInspProcessAttempts = COUNT(dbo.Folder.FolderRSN)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN
	LEFT JOIN dbo.FolderProcessAttempt ON dbo.FolderProcess.ProcessRSN = dbo.FolderProcessAttempt.ProcessRSN
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode
	LEFT JOIN dbo.ValidProcessGroup ON dbo.ValidProcess.ProcessGroupCode = dbo.ValidProcessGroup.ProcessGroupCode
	WHERE dbo.Folder.FolderType = 'QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode <> 999999 AND dbo.ValidProcessGroup.ProcessGroupCode <> 15

	/* Count Admin QC Process Attempts */
	SELECT @AllAdminProcessAttempts = COUNT(dbo.Folder.FolderRSN)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN
	LEFT JOIN dbo.FolderProcessAttempt ON dbo.FolderProcess.ProcessRSN = dbo.FolderProcessAttempt.ProcessRSN
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode
	LEFT JOIN dbo.ValidProcessGroup ON dbo.ValidProcess.ProcessGroupCode = dbo.ValidProcessGroup.ProcessGroupCode
	WHERE dbo.Folder.FolderType = 'QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode <> 999999 AND dbo.ValidProcessGroup.ProcessGroupCode = 15

	/* Count No Action Recorded (inspection processes with no attempt results) */
	SELECT @NoActionRecorded = SUM(1) 
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.FolderProcessAttempt ON dbo.FolderProcess.ProcessRSN = dbo.FolderProcessAttempt.ProcessRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode
	LEFT JOIN dbo.ValidProcessGroup ON dbo.ValidProcess.ProcessGroupCode = dbo.ValidProcessGroup.ProcessGroupCode 
	WHERE dbo.Folder.FolderType = 'QC' 
	AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.Folder.StatusCode <> 2 AND dbo.FolderProcess.ProcessCode <> 999999 
	AND dbo.ValidProcessGroup.ProcessGroupCode <> 15 AND dbo.FolderProcessAttempt.ResultCode Is Null

	/* Count folders not closed */
	SELECT @FoldersNotClosed  = SUM(1) 
	FROM dbo.Folder 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.Folder.StatusCode <> 2

	/* Count Folders Closed and find Average Days to Close */
	SELECT @FoldersClosed = SUM(1), @AvgDaysToClose = AVG(DATEDIFF(day, dbo.Folder.InDate, dbo.Folder.FinalDate))
	FROM dbo.Folder 
	WHERE dbo.Folder.FolderType = 'QC' 
	AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.Folder.FinalDate > dbo.Folder.InDate
	AND dbo.Folder.StatusCode = 2

	/* For Folders with Initial Contact Process, count, add up the number of units, and find average home age */
	SELECT @InitContactCount = COUNT(dbo.Folder.FolderRSN), 
	@InitContactNumUnits = SUM(dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 15)), 
	@InitContactAvgHomeAge = AVG(CASE WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) <= 0 THEN NULL 
		 WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) > 0 THEN DATEPART(year,GETDATE()) - dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) END)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode 
	LEFT JOIN dbo.Property ON dbo.Folder.PropertyRSN = dbo.Property.PropertyRSN 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode = 20028

	/* For Folders with Initial Inspection Process, count, add up the number of units, and find average home age */
	SELECT @InitInspectionCount = COUNT(dbo.Folder.FolderRSN), 
	@InitInspectionNumUnits = SUM(dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 15)), 
	@InitInspectionAvgHomeAge = AVG(CASE WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) <= 0 THEN NULL 
		 WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) > 0 THEN DATEPART(year,GETDATE()) - dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) END)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode 
	LEFT JOIN dbo.Property ON dbo.Folder.PropertyRSN = dbo.Property.PropertyRSN 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode = 20030

	/* For Folders with 1st Followup Inspection Process, count, add up the number of units, and find average home age */
	SELECT @1stFollowupCount = COUNT(dbo.Folder.FolderRSN), 
	@1stFollowupNumUnits = SUM(dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 15)), 
	@1stFollowupAvgHomeAge = AVG(CASE WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) <= 0 THEN NULL 
		 WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) > 0 THEN DATEPART(year,GETDATE()) - dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) END)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode 
	LEFT JOIN dbo.Property ON dbo.Folder.PropertyRSN = dbo.Property.PropertyRSN 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode = 20034

	/* For Folders with 2nd Followup Inspection Process, count, add up the number of units, and find average home age */
	SELECT @2ndFollowupCount = COUNT(dbo.Folder.FolderRSN), 
	@2ndFollowupNumUnits = SUM(dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 15)), 
	@2ndFollowupAvgHomeAge = AVG(CASE WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) <= 0 THEN NULL 
		 WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) > 0 THEN DATEPART(year,GETDATE()) - dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) END)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode 
	LEFT JOIN dbo.Property ON dbo.Folder.PropertyRSN = dbo.Property.PropertyRSN 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode = 20037

	/* For Folders with 3rd Followup Inspection Process, count, add up the number of units, and find average home age */
	SELECT @3rdFollowupCount = COUNT(dbo.Folder.FolderRSN), 
	@3rdFollowupNumUnits = SUM(dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 15)), 
	@3rdFollowupAvgHomeAge = AVG(CASE WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) <= 0 THEN NULL 
		 WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) > 0 THEN DATEPART(year,GETDATE()) - dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) END)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode 
	LEFT JOIN dbo.Property ON dbo.Folder.PropertyRSN = dbo.Property.PropertyRSN 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode = 20040

	/* For Folders with other Processes, count, add up the number of units, and find average home age */
	SELECT @OtherProcessCount = COUNT(dbo.Folder.FolderRSN), 
	@OtherProcessNumUnits = SUM(dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 15)), 
	@OtherProcessAvgHomeAge = AVG(CASE WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) <= 0 THEN NULL 
		 WHEN dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) > 0 THEN DATEPART(year,GETDATE()) - dbo.f_info_numeric_property(dbo.Property.PropertyRSN, 60) END)
	FROM dbo.Folder LEFT JOIN dbo.FolderProcess ON dbo.Folder.FolderRSN = dbo.FolderProcess.FolderRSN 
	LEFT JOIN dbo.ValidProcess ON dbo.FolderProcess.ProcessCode = dbo.ValidProcess.ProcessCode 
	LEFT JOIN dbo.ValidProcessGroup ON dbo.ValidProcess.ProcessGroupCode = dbo.ValidProcessGroup.ProcessGroupCode
	LEFT JOIN dbo.Property ON dbo.Folder.PropertyRSN = dbo.Property.PropertyRSN 
	WHERE dbo.Folder.FolderType='QC' AND dbo.Folder.InDate Between @StartDate And @EndDate 
	AND dbo.FolderProcess.ProcessCode Not In (20018,20028,20030,20034,20037,20040)
	AND dbo.ValidProcessGroup.ProcessGroupCode <> 15

	INSERT INTO tblBushorQCReport 
		(ReportDate, BeginDate, EndDate, AllFoldersCount, AllProcessAttemptsCount, AdminProcessAttemptsCount, InspProcessAttemptsCount, 
		 NoActionRecordedCount, FolderNotClosedCount, FolderClosedCount, AvgDaysToClose, InitialContactCount, InitialInspectionCount, 
		 InitialInspectionNumUnits, InitialInspectionAvgHomeAge, FirstFollowupCount, FirstFollowupNumUnits, FirstFollowupAvgHomeAge, 
		 SecondFollowupCount, SecondFollowupNumUnits, SecondFollowupAvgHomeAge, ThirdFollowupCount, ThirdFollowupNumUnits, 
		 ThirdFollowupAvgHomeAge, AppealCount, AppealNumUnits, AppealAvgHomeAge)
	VALUES (GETDATE(), @StartDate, @EndDate, @AllFoldersCount, @AllProcessAttempts, @AllAdminProcessAttempts, @AllInspProcessAttempts, 
		 @NoActionRecorded, @FoldersNotClosed, @FoldersClosed, @AvgDaysToClose, @InitContactCount, @InitInspectionCount, 
		 @InitInspectionNumUnits, @InitInspectionAvgHomeAge, @1stFollowupCount, @1stFollowupNumUnits, @1stFollowupAvgHomeAge, 
		 @2ndFollowupCount, @2ndFollowupNumUnits, @2ndFollowupAvgHomeAge, @3rdFollowupCount, @3rdFollowupNumUnits, @3rdFollowupAvgHomeAge, 
		 @OtherProcessCount, @OtherProcessNumUnits, @OtherProcessAvgHomeAge)

END







GO
