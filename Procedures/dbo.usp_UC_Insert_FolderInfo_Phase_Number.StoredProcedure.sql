USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_UC_Insert_FolderInfo_Phase_Number]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_UC_Insert_FolderInfo_Phase_Number]
@intPermitFolderRSNValue int, @intUCFolderRSNValue int, @varUserID varchar(30)
AS

DECLARE @intUCPhaseNumberInfoCount int
DECLARE @intZPPhaseNumberInfoCount int
DECLARE @intZPPhaseNumberInfoValue int
DECLARE @intUCPhaseNumberDefault int

SELECT @intUCPhaseNumberInfoCount = COUNT(*)
FROM FolderInfo
WHERE FolderInfo.InfoCode = 23035
AND FolderInfo.FolderRSN = @intUCFolderRSNValue

SELECT @intZPPhaseNumberInfoCount = COUNT(*)
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @intPermitFolderRSNValue
AND FolderInfo.InfoCode = 10081    /* Number of Phases */

IF @intZPPhaseNumberInfoCount > 0
BEGIN
	SELECT @intZPPhaseNumberInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0) 
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intPermitFolderRSNValue
	AND FolderInfo.InfoCode = 10081 
END
ELSE SELECT @intZPPhaseNumberInfoValue = 0

IF @intUCPhaseNumberInfoCount = 0 AND @intZPPhaseNumberInfoValue > 1
BEGIN
	SELECT @intUCPhaseNumberDefault = dbo.udf_GetUCOPhaseNumberActive(@intPermitFolderRSNValue)
 
	INSERT INTO FolderInfo
		( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
		  InfoValue, InfoValueNumeric, 
		  StampDate, StampUser, Mandatory, ValueRequired )
	VALUES ( @intUCFolderRSNValue, 23035,  305, 'Y', 
			 @intUCPhaseNumberDefault, @intUCPhaseNumberDefault, 
			 getdate(), @varUserID, 'N', 'N' )
END

GO
