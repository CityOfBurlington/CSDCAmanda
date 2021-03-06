USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetDependencyRelatedView]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure GetDependencyRelatedView modified to get dependent processes for related view */

CREATE PROCEDURE [dbo].[GetDependencyRelatedView] (@ProcessCode INT, @FolderType VARCHAR(4))
AS
--5.4.4.31a: ESS

	DECLARE @v_currentCode INT
	DECLARE @v_NextCode INT
	DECLARE @v_lvl INT
	DECLARE @v_FolderType VARCHAR(4)
BEGIN
	
	CREATE TABLE #temp_ProcessDependency
	(
		
        ProcessCode      INT           ,		
		ProcessDesc      VARCHAR(80)   ,
		ProcessDesc2     VARCHAR(80)   ,
		PriorProcessCode INT           ,
		ProcessDesc1     VARCHAR(80)   ,
		ProcessDesc3     VARCHAR(80)   ,
		Path             VARCHAR(2000) 
		          
	)
	SET @v_FolderType  =  @FolderType
	SET @v_currentCode = @ProcessCode

	 SELECT @v_NextCode = PriorProcessCode				
	 FROM DefaultProcessDependent WHERE  FolderType = @FolderType AND ProcessCode = @v_currentCode
	
	    
	SET @v_lvl = 1			
	INSERT INTO #temp_ProcessDependency
		SELECT	DPD.ProcessCode, 
				VP1.ProcessDesc,VP1.ProcessDesc2 ProcessDesc2,DPD.PriorProcessCode, 
				VP2.ProcessDesc ProcessDesc1,VP2.ProcessDesc2 ProcessDesc3,
				CAST(DPD.ProcessCode AS VARCHAR(2000))
		FROM ValidProcess VP1, ValidProcess VP2, DefaultProcessDependent DPD 
		WHERE DPD.FolderType = @v_FolderType AND DPD.ProcessCode = @v_currentCode AND
		DPD.ProcessCode = VP1.ProcessCode AND VP2.ProcessCode = DPD.PriorProcessCode	

	EXEC PopulateProcessChildren  @v_NextCode , @v_FolderType , @v_lvl OUT		 
       
	SELECT Path, ProcessCode, ProcessDesc , ProcessDesc2, PriorProcessCode, ProcessDesc1, ProcessDesc3 FROM #temp_ProcessDependency

END

GO
