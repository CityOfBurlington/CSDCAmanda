USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspDocRoutineInspectionReport]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[uspDocRoutineInspectionReport](@pintFolderRSN int)
AS

Select 
Folder.FolderRSN, Folder.FolderName, 
FolderProcessDeficiency.DeficiencyText, 
FolderProcessDeficiency.LocationDesc, 
FolderProcessDeficiency.SubLocationDesc,
Convert(Char(12), Complybydate) AS ComplyBy, 
FolderProcessDeficiency.RemedyText, 
ValidDeficiencyCategory.CategoryDesc,
Convert(Char(12), dbo.f_info_alpha(Folder.FolderRSN, 20030)) AS LastInspDate,
FolderProcessAttempt.AttemptBy, 
FolderProcessDeficiency.StatusCode, 
ValidClause.ClauseText,
(SELECT SUM(1) FROM Folder, FolderProcessDeficiency, ValidDeficiencyCategory, ValidDeficiency,
FolderProcess, ValidClause, FolderInfo, FolderProcessAttempt
WHERE Folder.FolderRSN = FolderProcessDeficiency.FolderRSN
AND ValidDeficiencyCategory.CategoryCode = ValidDeficiency.CategoryCode
AND ValidDeficiency.DeficiencyCode = FolderProcessDeficiency.DeficiencyCode
AND FolderProcess.FolderRSN = Folder.FolderRSN
AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcessAttempt.FolderRSN = Folder.FolderRSN
AND Convert(Char(11),FolderProcessAttempt.AttemptDate) = FolderInfo.InfoValue
AND FolderProcess.ProcessCode IN (20015, 20020)
AND FolderInfo.FolderRSN = Folder.FolderRSN
AND ValidClause.DisplayOrder = FolderProcessDeficiency.DeficiencyCode
AND Folder.FolderRSN = @pintFolderRSN) AS TotalRecs

FROM Folder, FolderProcessDeficiency, ValidDeficiencyCategory, ValidDeficiency,
FolderProcess, ValidClause, FolderInfo, FolderProcessAttempt

WHERE Folder.FolderRSN = FolderProcessDeficiency.FolderRSN
AND ValidDeficiencyCategory.CategoryCode = ValidDeficiency.CategoryCode
AND ValidDeficiency.DeficiencyCode = FolderProcessDeficiency.DeficiencyCode
AND FolderProcess.FolderRSN = Folder.FolderRSN
AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcessAttempt.FolderRSN = Folder.FolderRSN
AND Convert(Char(11),FolderProcessAttempt.AttemptDate) = FolderInfo.InfoValue
AND FolderProcess.ProcessCode IN (20015, 20020)
AND FolderInfo.FolderRSN = Folder.FolderRSN
AND ValidClause.DisplayOrder = FolderProcessDeficiency.DeficiencyCode
AND Folder.FolderRSN = @pintFolderRSN

Order By  LocationDesc, sublocationdesc

GO
