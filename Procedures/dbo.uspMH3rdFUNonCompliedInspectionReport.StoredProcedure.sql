USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspMH3rdFUNonCompliedInspectionReport]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[uspMH3rdFUNonCompliedInspectionReport] (@pintFolderRSN int)
AS
BEGIN
	DECLARE @intPageSize		Int
	DECLARE @intMinPageCount	Int
	DECLARE @intTotalPageCount	Int
	DECLARE @intTotalRecords	Int

	SET @intPageSize = 3

	SELECT @intTotalRecords = SUM(1)
	FROM Folder
	INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
	INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
	INNER JOIN FolderProcessDeficiency ON FolderProcess.ProcessRSN = FolderProcessDeficiency.ProcessRSN
	INNER JOIN ValidDeficiency ON FolderProcessDeficiency.DeficiencyCode = ValidDeficiency.DeficiencyCode
	INNER JOIN ValidDeficiencyCategory ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
	INNER JOIN ValidClause ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder
	WHERE Folder.FolderRSN = @pintFolderRSN
	AND FolderProcess.ProcessCode = 20040
	 /*1st FU Inspection, 20034, 20037, 20040) */
	AND FolderProcessAttempt.ResultCode IN(20046, 20075) /*Continued Violation(s), Found In Compliance*/


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
		ValidDeficiencyStatus.StatusDesc AS DeficiencyStatus,
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.DeficiencyText), 
		FolderProcessDeficiency.LocationDesc, 
		FolderProcessDeficiency.SubLocationDesc,
		dbo.FormatDateTime(Complybydate, 'SHORTDATE') AS ComplyBy, 
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.RemedyText),
		ValidDeficiencyCategory.CategoryDesc,
		dbo.FormatDateTime(FolderProcessAttempt.AttemptDate, 'SHORTDATE') AS LastInspDate,
		ValidUser.UserName AS AttemptBy,
		FolderProcessDeficiency.StatusCode, 
		dbo.udf_RemoveSpecialChars(ValidClause.ClauseText)
	FROM Folder 
	INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
	INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
	INNER JOIN FolderProcessDeficiency ON FolderProcess.ProcessRSN = FolderProcessDeficiency.ProcessRSN
	INNER JOIN ValidDeficiency ON FolderProcessDeficiency.DeficiencyCode = ValidDeficiency.DeficiencyCode
	INNER JOIN ValidDeficiencyCategory ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
	INNER JOIN ValidClause ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder
	INNER JOIN ValidDeficiencyStatus ON FolderProcessDeficiency.StatusCode = ValidDeficiencyStatus.StatusCode
	INNER JOIN ValidUser ON FolderProcessAttempt.AttemptBy = ValidUser.UserID
	WHERE Folder.FolderRSN = @pintFolderRSN
	AND FolderProcess.ProcessCode = 20040 /*Initial Inspection, 20034, 20037, 20040) */
	AND FolderProcessAttempt.ResultCode IN(20046, 20075) /*Continued Violation(s), Found In Compliance*/
	ORDER BY LocationDesc, SubLocationDesc

	SELECT CASE 
		WHEN RowNum/3 = 0 THEN 1 
		ELSE (RowNum/3) + 1 
		END AS PageNumber,
		TotalPages,  FolderRSN, FolderName, DeficiencyText, LocationDesc, SubLocationDesc,
		ComplyBy, RemedyText, CategoryDesc, LastInspDate, AttemptBy, 
		/*CASE WHEN StatusCode = 1 THEN 'Status of Deficiency:   No Compliance' 
		WHEN StatusCode = 2 THEN 'Status of Deficiency:   Compliance' 
		ELSE 'Status of Deficiency: ' END*/
'Status of Deficiency:   ' + ISNULL(DeficiencyStatus, 'Non Complied')
		AS StatusCode, 
		ClauseText, RowNum, (SELECT MAX(RowNUM) FROM #Temp) AS TotalItems
	FROM #temp
	WHERE DeficiencyStatus <> 'Complied'
END



GO
