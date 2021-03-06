USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PopulateProcessChildren]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure PopulateProcessChildren modified to get the related children for PriorProcessCode */

CREATE PROCEDURE [dbo].[PopulateProcessChildren] (@p_processCode INT , @FolderType VARCHAR(4)  ,@p_lvl INT out)
AS
-- 5.4.4.31a: ESS

DECLARE @v_ProcessCode INT
DECLARE @v_FolderType VARCHAR(4)
DECLARE @v_path VARCHAR(2000)
DECLARE @v_currentCode INT

BEGIN            
	SET @v_FolderType = @FolderType
	SET @v_currentCode = @p_processCode
   SET @v_path = @v_currentCode

	

	DECLARE c_crs CURSOR LOCAL FOR
 		SELECT PriorProcessCode FROM DefaultProcessDependent
		WHERE FolderType = @v_FolderType AND ProcessCode = @p_processCode
	OPEN c_crs
	FETCH NEXT FROM c_crs INTO @v_ProcessCode
	WHILE @v_currentCode IS NOT NULL
    BEGIN  

      SELECT  @v_currentCode = ProcessCode					
		FROM DefaultProcessDependent WHERE FolderType = @v_FolderType and PriorProcessCode = @v_currentCode         

		IF @@RowCount = 0
			BEGIN
				--SET @v_path = --replace(@v_path, CAST(@v_currentCode as VARCHAR) + '.', '')  
				SET @v_currentCode = null	
			END 
		IF (@v_currentCode IS NOT NULL)
			BEGIN
				SET @v_path = CAST(@v_currentCode as VARCHAR) + '.' + @v_path
			END 
      END	

	WHILE @@FETCH_STATUS = 0
	BEGIN


		SET @p_lvl = @p_lvl+1;
		INSERT INTO #temp_ProcessDependency
		SELECT DPD.ProcessCode, VP1.ProcessDesc, VP1.ProcessDesc2 ProcessDesc2, DPD.PriorProcessCode, VP2.ProcessDesc, VP2.ProcessDesc2 ProcessDesc3, @v_path
				FROM ValidProcess VP1, ValidProcess VP2, DefaultProcessDependent DPD 
				WHERE DPD.FolderType = @v_FolderType AND DPD.ProcessCode = @p_processCode AND
				VP1.ProcessCode = DPD.ProcessCode AND DPD.PriorProcessCode = @v_ProcessCode AND VP2.ProcessCode = DPD.PriorProcessCode				
				

		EXEC PopulateProcessChildren @v_ProcessCode, @FolderType,@p_lvl OUT
	   	FETCH NEXT FROM c_crs INTO @v_ProcessCode
	END

	CLOSE c_crs
	DEALLOCATE c_crs
END

GO
