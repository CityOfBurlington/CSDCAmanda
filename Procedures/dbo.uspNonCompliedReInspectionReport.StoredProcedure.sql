USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspNonCompliedReInspectionReport]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[uspNonCompliedReInspectionReport](@pintFolderRSN int)
AS
BEGIN
	DECLARE @intPageSize		Int
	DECLARE @intMinPageCount	Int
	DECLARE @intTotalPageCount	Int
	DECLARE @intTotalRecords	Int

	SET @intPageSize = 3

	SELECT @intTotalRecords = SUM(1) 
	FROM Folder
	INNER JOIN FolderProcessDeficiency ON Folder.FolderRSN = FolderProcessDeficiency.FolderRSN
	INNER JOIN FolderProcess ON FolderProcess.FolderRSN = Folder.FolderRSN
	INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN AND Folder.FolderRSN = FolderProcessAttempt.FolderRSN 
	INNER JOIN ValidDeficiency ON ValidDeficiency.DeficiencyCode = FolderProcessDeficiency.DeficiencyCode
	INNER JOIN ValidDeficiencyCategory ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
	INNER JOIN FolderInfo ON Convert(Char(11), FolderProcessAttempt.AttemptDate) = FolderInfo.InfoValue AND Folder.FolderRSN = FolderInfo.FolderRSN
	INNER JOIN ValidClause ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder

	WHERE 
	/*FolderProcessDeficiency.StatusCode = 1 Non-Complied*/
	FolderProcessDeficiency.StatusCode <> 2 /*Complied*/
	AND Folder.FolderRSN = @pintFolderRSN
	AND (
		(FolderProcess.ProcessCode IN (20015, 20020) AND Folder.FolderType = 'RI')
		OR
		(FolderProcessAttempt.ResultCode = 20047 AND Folder.FolderType = 'QI')
	)

	IF @intTotalRecords <= @intPageSize
		BEGIN
			SET @intTotalPageCount = 1
		END
	IF @intTotalRecords > @intPageSize
		BEGIN
			SET @intMinPageCount = @intTotalRecords / @intPageSize

			IF @intTotalRecords % @intPageSize > 0
				BEGIN
					SET @intTotalPageCount = @intMinPageCount + 1
				END
			ELSE
				BEGIN
					SET @intTotalPageCount = @intMinPageCount
				END

		END


	CREATE TABLE #temp(
		RowNum INT PRIMARY KEY IDENTITY,
		TotalPages	int null,
		FolderRSN	int null,
		FolderName	varchar(80) null,
		DeficiencyStatus  varchar(100) null,
		DeficiencyText	text null,
		LocationDesc	varchar(64) null,
		SubLocationDesc	varchar(64) null,
		ComplyBy	char(12) null,
		RemedyText	text null,
		CategoryDesc	varchar(64) null,
		LastInspDate	Char(12) null,
		AttemptBy	varchar(40) null,
		StatusCode	smallint null,
		ClauseText	text null
	)

	INSERT INTO #temp 
	(TotalPages, FolderRSN, FolderName, DeficiencyStatus, DeficiencyText, LocationDesc, SubLocationDesc, ComplyBy,
	RemedyText, CategoryDesc, LastInspDate, AttemptBy, StatusCode, ClauseText)
	SELECT @intTotalPageCount AS TotalPages,
		Folder.FolderRSN, 
		Folder.FolderName, 
		ValidDeficiencyStatus.StatusDesc,
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.DeficiencyText), 
		FolderProcessDeficiency.LocationDesc, 
		FolderProcessDeficiency.SubLocationDesc,
		Convert(Char(12), Complybydate) AS ComplyBy, 
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.RemedyText),
		ValidDeficiencyCategory.CategoryDesc,
		Convert(Char(12), dbo.f_info_alpha(Folder.FolderRSN, 20030)) AS LastInspDate,
		ValidUser.UserName AS AttemptBy,
		FolderProcessDeficiency.StatusCode, 
		dbo.udf_RemoveSpecialChars(ValidClause.ClauseText)
	FROM Folder, FolderProcessDeficiency, ValidDeficiencyCategory, ValidDeficiency,
		FolderProcess, ValidClause, FolderInfo, FolderProcessAttempt, ValidUser, ValidDeficiencyStatus
	WHERE Folder.FolderRSN = FolderProcessDeficiency.FolderRSN
		AND ValidDeficiencyCategory.CategoryCode = ValidDeficiency.CategoryCode
		AND ValidDeficiency.DeficiencyCode = FolderProcessDeficiency.DeficiencyCode
		AND FolderProcess.FolderRSN = Folder.FolderRSN
		AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
		AND FolderProcessAttempt.AttemptBy = ValidUser.UserID
		AND FolderProcessAttempt.FolderRSN = Folder.FolderRSN
		AND FolderProcessDeficiency.StatusCode = ValidDeficiencyStatus.StatusCode
		AND Convert(Char(11), FolderProcessAttempt.AttemptDate) = FolderInfo.InfoValue
		AND FolderProcess.ProcessCode IN (20015, 20020)


	/*AND FolderProcessDeficiency.StatusCode = 1 Non-Complied*/
	AND FolderProcessDeficiency.StatusCode <> 2 /*Complied*/


		AND FolderInfo.FolderRSN = Folder.FolderRSN
		AND ValidClause.DisplayOrder = FolderProcessDeficiency.DeficiencyCode
		AND Folder.FolderRSN = @pintFolderRSN 
		AND (
			(FolderProcess.ProcessCode IN (20015, 20020) AND Folder.FolderType = 'RI')
			OR
			(FolderProcessAttempt.ResultCode = 20047 AND Folder.FolderType = 'QI')
			)
	ORDER BY LocationDesc, sublocationdesc

	SELECT CASE
		WHEN RowNum/3 = 0 THEN 1 
		ELSE (RowNum/3) + 1 
		END AS PageNumber,
		TotalPages,  FolderRSN, FolderName, DeficiencyText, LocationDesc, SubLocationDesc,
		ComplyBy, RemedyText, CategoryDesc, LastInspDate, AttemptBy, 
		'Status of Deficiency:   ' + ISNULL(DeficiencyStatus, 'Non Complied') AS StatusCode, 
		ClauseText, RowNum, (SELECT MAX(RowNUM) FROM #Temp) AS TotalItems
	FROM #temp
END







GO
