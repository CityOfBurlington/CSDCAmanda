USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_BPWithoutChildFolders]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_BPWithoutChildFolders]
AS
	DECLARE @FolderType		VARCHAR(4)
	DECLARE @FolderRSN		INT
	DECLARE @ParentRSN		INT

	DECLARE @ElectricalRequired			VARCHAR(3)
	DECLARE @PlumbingRequired			VARCHAR(3)
	DECLARE @MechanicalRequired			VARCHAR(3)
	DECLARE @FireAlarmRequired			VARCHAR(3)
	DECLARE @SprinklerSystemRequired	VARCHAR(3)
	DECLARE @SuppressionSystemRequired	VARCHAR(3)

	DECLARE @i INT
	SET @i=0

	CREATE TABLE #Temp (
	FolderRSN					INT,
	ElectricalRequired			VARCHAR(3),
	PlumbingRequired			VARCHAR(3),
	MechanicalRequired			VARCHAR(3),
	FireAlarmRequired			VARCHAR(3),
	SprinklerSystemRequired		VARCHAR(3),
	SuppressionSystemRequired	VARCHAR(3)
	)

	DECLARE curTrades CURSOR FOR
	SELECT F.FolderRSN, 
	dbo.f_info_boolean(F.FolderRSN, 30000) AS ElectricalRequired,
	dbo.f_info_boolean(F.FolderRSN, 30001) AS PlumbingRequired,
	dbo.f_info_boolean(F.FolderRSN, 30002) AS MechanicalRequired,
	dbo.f_info_boolean(F.FolderRSN, 30003) AS FireAlarmRequired,
	dbo.f_info_boolean(F.FolderRSN, 30004) AS SprinklerSystemRequired,
	dbo.f_info_boolean(F.FolderRSN, 30005) AS SuppressionSystemRequired 
	FROM Folder F
	INNER JOIN ValidFolder VF ON F.FolderType = VF.FolderType
	INNER JOIN ValidFolderGroup VFG ON VF.FolderGroupCode=VFG.FolderGroupCode
	WHERE VFG.FolderGroupDesc='Construction Permits'
	AND F.FolderType ='BP'
	AND (
	dbo.f_info_boolean(F.FolderRSN, 30000)='Yes' OR 
	dbo.f_info_boolean(F.FolderRSN, 30001)='Yes' OR 
	dbo.f_info_boolean(F.FolderRSN, 30002)='Yes' OR 
	dbo.f_info_boolean(F.FolderRSN, 30003)='Yes' OR 
	dbo.f_info_boolean(F.FolderRSN, 30004)='Yes' OR 
	dbo.f_info_boolean(F.FolderRSN, 30005)='Yes' 
	)
	
	/*
	SELECT ValidInfo.InfoCode, ValidInfo.InfoDesc 
	FROM DefaultInfo
	INNER JOIN ValidInfo ON DefaultInfo.InfoCode=ValidInfo.InfoCode
	WHERE DefaultInfo.FolderType='BP'
	*/

	OPEN curTrades

	FETCH NEXT FROM curTrades INTO @FolderRSN,@ElectricalRequired,@PlumbingRequired,@MechanicalRequired,@FireAlarmRequired,@SprinklerSystemRequired,@SuppressionSystemRequired

	SET NOCOUNT ON

	WHILE @@FETCH_STATUS=0 BEGIN
	
		IF NOT EXISTS (SELECT FolderRSN FROM Folder WHERE ParentRSN=ISNULL(@FolderRSN,0))
		BEGIN
			INSERT INTO #Temp SELECT @FolderRSN,@ElectricalRequired,@PlumbingRequired,@MechanicalRequired,@FireAlarmRequired,@SprinklerSystemRequired,@SuppressionSystemRequired
		END

		FETCH NEXT FROM curTrades INTO @FolderRSN,@ElectricalRequired,@PlumbingRequired,@MechanicalRequired,@FireAlarmRequired,@SprinklerSystemRequired,@SuppressionSystemRequired
	END

	CLOSE curTrades
	DEALLOCATE curTrades

	SET NOCOUNT OFF

	SELECT F.FolderRSN, F.FolderName, F.FolderYear, F.InDate, F.SubDesc, F.WorkDesc, F.PropHouse, F.PropStreet, 
	F.PropStreetType, T.ElectricalRequired, T.PlumbingRequired, T.MechanicalRequired, T.FireAlarmRequired,
	T.SprinklerSystemRequired, T.SuppressionSystemRequired
	FROM #Temp T
	INNER JOIN uvw_FolderDetails F ON T.FolderRSN = F.FolderRSN 

	ORDER BY T.FolderRSN DESC

GO
