USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspCodeMainReInspRpt]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspCodeMainReInspRpt](@pintFolderRSN int)
AS
BEGIN
	DECLARE @intPageSize		Int
	DECLARE @intMinPageCount	Int
	DECLARE @intTotalPageCount	Int
	DECLARE @intTotalRecords	Int

	SET @intPageSize = 3

	SELECT @intTotalRecords = SUM(1)
	FROM Folder

	INNER JOIN FolderProcess 		ON Folder.FolderRSN = FolderProcess.FolderRSN 
	INNER JOIN FolderProcessAttempt		ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
	INNER JOIN ValidUser			ON FolderProcessAttempt.AttemptBy = ValidUser.UserID
	INNER JOIN FolderProcessDeficiency	ON Folder.FolderRSN = FolderProcessDeficiency.FolderRSN
	INNER JOIN ValidDeficiencyStatus	ON FolderProcessDeficiency.StatusCode = ValidDeficiencyStatus.StatusCode
	INNER JOIN ValidClause			ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder
	INNER JOIN ValidDeficiency		ON FolderProcessDeficiency.DeficiencyCode = ValidDeficiency.DeficiencyCode
	INNER JOIN ValidDeficiencyCategory	ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
	INNER JOIN FolderInfo			ON Folder.FolderRSN = FolderInfo.FolderRSN

	WHERE (Folder.FolderRSN = @pintFolderRSN)
	AND (Convert(Char(11), FolderProcessAttempt.AttemptDate) = FolderInfo.InfoValue)
	AND (ValidDeficiencyStatus.StatusDesc <> 'Complied')
	AND (	(FolderProcess.ProcessCode IN (20015, 20020) AND Folder.FolderType = 'RI')
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
		DeficiencyText	text null,
		LocationDesc	varchar(64) null,
		SubLocationDesc	varchar(64) null,
		ComplyBy	char(12) null,
		RemedyText	text null,
		CategoryDesc	varchar(64) null,
		LastInspDate	Char(12) null,
		AttemptBy	varchar(40) null,
		StatusCode	varchar(64) null,
		ClauseText	text null
	)

	INSERT INTO #temp 
	(TotalPages, FolderRSN, FolderName, DeficiencyText, LocationDesc, SubLocationDesc, ComplyBy,
	RemedyText, CategoryDesc, LastInspDate, AttemptBy, StatusCode, ClauseText)
	SELECT @intTotalPageCount AS TotalPages,
		Folder.FolderRSN, 
		Folder.FolderName, 
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.DeficiencyText), 
		FolderProcessDeficiency.LocationDesc, 
		FolderProcessDeficiency.SubLocationDesc,
		Convert(Char(12), Complybydate) AS ComplyBy, 
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.RemedyText),
		ValidDeficiencyCategory.CategoryDesc,
		Convert(Char(12), dbo.f_info_alpha(Folder.FolderRSN, 20030)) AS LastInspDate,
		ValidUser.UserName AS AttemptBy,
		ValidDeficiencyStatus.StatusDesc, 
		dbo.udf_RemoveSpecialChars(ValidClause.ClauseText)
	FROM Folder

	INNER JOIN FolderProcess 		ON Folder.FolderRSN = FolderProcess.FolderRSN 
	INNER JOIN FolderProcessAttempt		ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
	INNER JOIN ValidUser			ON FolderProcessAttempt.AttemptBy = ValidUser.UserID
	INNER JOIN FolderProcessDeficiency	ON Folder.FolderRSN = FolderProcessDeficiency.FolderRSN
	INNER JOIN ValidDeficiencyStatus	ON FolderProcessDeficiency.StatusCode = ValidDeficiencyStatus.StatusCode
	INNER JOIN ValidClause			ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder
	INNER JOIN ValidDeficiency		ON FolderProcessDeficiency.DeficiencyCode = ValidDeficiency.DeficiencyCode
	INNER JOIN ValidDeficiencyCategory	ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
	INNER JOIN FolderInfo			ON Folder.FolderRSN = FolderInfo.FolderRSN

	WHERE (Folder.FolderRSN = @pintFolderRSN)
	AND (Convert(Char(11), FolderProcessAttempt.AttemptDate) = FolderInfo.InfoValue)
	AND (ValidDeficiencyStatus.StatusDesc <> 'Complied')
	AND (	(FolderProcess.ProcessCode IN (20015, 20020) AND Folder.FolderType = 'RI')
		OR
		(FolderProcessAttempt.ResultCode = 20047 AND Folder.FolderType = 'QI')
	    )

	ORDER BY LocationDesc, SubLocationDesc



	SELECT CASE 
		WHEN RowNum/3 = 0 THEN 1 
		ELSE (RowNum/3) + 1 
		END AS PageNumber,
		TotalPages,  FolderRSN, FolderName, DeficiencyText, LocationDesc, SubLocationDesc,
		ComplyBy, RemedyText, CategoryDesc, LastInspDate, AttemptBy, 'Status: ' + StatusCode, 
		ClauseText, RowNum, (SELECT MAX(RowNUM) FROM #Temp) AS TotalItems
	FROM #temp
END





GO
