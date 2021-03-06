USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_MH3rdFUInspectionReport]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_MH3rdFUInspectionReport](@pintFolderRSN INT) 
RETURNS @BVT TABLE (RowNum INT PRIMARY KEY IDENTITY, TotalPages	INT,
					FolderRSN INT, FolderName VARCHAR(1000),
					DefStatusCode  VARCHAR(1000),DeficiencyText	VARCHAR(1000), 
					Location VARCHAR(1000), SubLocation VARCHAR(1000),
					ComplyBy CHAR(1000),RemedyText VARCHAR(1000), Category	CHAR(1000),
					LID CHAR(1000), Inspector CHAR(1000), StatusCode INT,
					OrdText VARCHAR(1000))
AS BEGIN

DECLARE @intPageSize		INT;
DECLARE @intMinPageCount	INT;
DECLARE @intTotalPageCount	INT;
DECLARE @intTotalRecords	INT;
DECLARE @intMaxProcessRSN	INT;

SET @intPageSize = 3;

SELECT @intMaxProcessRSN = Max(ProcessRSN) 
FROM FolderProcess
WHERE FolderRSN = @pintFolderRSN 
AND ProcessCode = 20040

SELECT @intTotalRecords = SUM(1) 
FROM Folder
INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN 
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
INNER JOIN FolderProcessDeficiency ON FolderProcess.ProcessRSN = FolderProcessDeficiency.ProcessRSN 
INNER JOIN ValidDeficiency ON FolderProcessDeficiency.DeficiencyCode = ValidDeficiency.DeficiencyCode
INNER JOIN ValidDeficiencyCategory ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
INNER JOIN ValidClause ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder
WHERE Folder.FolderRSN = @pintFolderRSN
AND FolderProcessDeficiency.StatusCode <> 2
AND FolderProcess.ProcessCode = 20040
AND FolderProcess.ProcessRSN = @intMaxProcessRSN
AND FolderProcessAttempt.ProcessRSN = @intMaxProcessRSN
 /* 20030 = Code Initial Inspection 
    20034 = 1st FU Inspection
    20037 = 2nd FU Inspection
    20040 = 3rd FU Inspection) */
--AND FolderProcessAttempt.ResultCode IN (20046, 20075) /*Continued Violation(s), Found In Compliance*/


IF @intTotalRecords <= @intPageSize
	BEGIN
		SET @intTotalPageCount = 1;
	END
IF @intTotalRecords > @intPageSize
	BEGIN
		SET @intMinPageCount = @intTotalRecords / @intPageSize;

		IF @intTotalRecords % @intPageSize > 0
			BEGIN
				SET @intTotalPageCount = @intMinPageCount + 1;
			END
		ELSE
			BEGIN
				SET @intTotalPageCount = @intMinPageCount;
			END

	END

INSERT @BVT
	(TotalPages, FolderRSN, FolderName, DefStatusCode, DeficiencyText, Location, SubLocation, ComplyBy,
	RemedyText, Category, LID, Inspector, StatusCode, OrdText)
	SELECT @intTotalPageCount AS TotalPages,
		Folder.FolderRSN, 
		Folder.FolderName, 
		ValidDeficiencyStatus.StatusDesc AS DefStatusCode,
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.DeficiencyText), 
		FolderProcessDeficiency.LocationDesc, 
		FolderProcessDeficiency.SubLocationDesc,
		dbo.FormatDateTime(Complybydate, 'SHORTDATE') AS ComplyBy, 
		dbo.udf_RemoveSpecialChars(FolderProcessDeficiency.RemedyText),
		ValidDeficiencyCategory.CategoryDesc,
		dbo.FormatDateTime(FolderProcessAttempt.AttemptDate, 'SHORTDATE') AS LID,
		ValidUser.UserName AS Inspector,
		FolderProcessDeficiency.StatusCode, 
		dbo.udf_RemoveSpecialChars(ValidClause.ClauseText)
	FROM Folder 
	INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN AND FolderProcess.ProcessRSN = @intMaxProcessRSN
	INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN AND FolderProcessAttempt.ProcessRSN = @intMaxProcessRSN
	INNER JOIN FolderProcessDeficiency ON FolderProcess.ProcessRSN = FolderProcessDeficiency.ProcessRSN AND FolderProcessDeficiency.ProcessRSN = @intMaxProcessRSN
	INNER JOIN ValidDeficiency ON FolderProcessDeficiency.DeficiencyCode = ValidDeficiency.DeficiencyCode
	INNER JOIN ValidDeficiencyCategory ON ValidDeficiency.CategoryCode = ValidDeficiencyCategory.CategoryCode
	INNER JOIN ValidClause ON FolderProcessDeficiency.DeficiencyCode = ValidClause.DisplayOrder
	INNER JOIN ValidDeficiencyStatus ON FolderProcessDeficiency.StatusCode = ValidDeficiencyStatus.StatusCode
	INNER JOIN ValidUser ON FolderProcessAttempt.AttemptBy = ValidUser.UserID
	WHERE Folder.FolderRSN = @pintFolderRSN
	AND FolderProcessDeficiency.StatusCode <> 2
	AND FolderProcess.ProcessCode = 20040
    AND FolderProcess.ProcessRSN = @intMaxProcessRSN
    AND FolderProcessAttempt.ProcessRSN = @intMaxProcessRSN
 /* 20030 = Code Initial Inspection 
    20034 = 1st FU Inspection
    20037 = 2nd FU Inspection
    20040 = 3rd FU Inspection) */
	--AND FolderProcessAttempt.ResultCode IN(20046, 20075) /*Continued Violation(s), Found In Compliance*/
	ORDER BY LocationDesc, SubLocationDesc;

RETURN;
END

GO
