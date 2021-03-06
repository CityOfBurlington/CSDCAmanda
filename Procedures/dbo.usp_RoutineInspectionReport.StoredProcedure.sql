USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RoutineInspectionReport]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_RoutineInspectionReport](@pintFolderRSN int)
AS
Select Folder.FolderRSN, Folder.FolderName, 
FolderProcessDeficiency.DeficiencyText, LocationDesc, SubLocationDesc,
Convert(Char(12),Complybydate) AS ComplyBy, RemedyText, CategoryDesc,
Convert(Char(12),dbo.f_info_alpha(Folder.FolderRSN, 20030)) AS LastInspDate,
FolderProcessAttempt.AttemptBy, FolderProcessDeficiency.StatusCode, ClauseText
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
