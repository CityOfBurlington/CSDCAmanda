USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PC_PROCESS_INSERT]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[PC_PROCESS_INSERT] 
@argFolderRSN INT,
@argProcessCode int, 
@DUserID varchar(1000), 
@newProcess int = 0

/******************************************************************************
NAME: PC_PROCESS_INSERT
PURPOSE: Insert a folder process, it will pick up all defaults from default process if it exists for the folder. The new processRSN
		 is returned as an output parameter

REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0        09/01/2008  Kevin Westoby    Created procedure
2.2		   09/22/2008  Kevin Westoby	Changed input parameters to include a newProcessFlag 2, removed dispOrder argument

NOTES: If you want to always insert a new process use the newProcess parameter = 1, if left to 0 then the process will be reopened if it
	   already exists on the folder, 2 will only insert if the process does not exist on the folder

******************************************************************************/
AS

DECLARE @v_UserID varchar(1000)
DECLARE @v_FolderType varchar(100)
DECLARE @v_mandatoryFlag varchar(100)
DECLARE @n_DisplayOrder int
DECLARE @d_scheduleDate datetime
DECLARE @d_scheduleEndDate datetime
DECLARE @n_disciplineCode int
DECLARE @n_processCount int
DECLARE @n_processRSN int
DECLARE @n_folderStage int

BEGIN

	SELECT @n_processCount = count(*)
	FROM folderProcess
	WHERE folderRSN = @argFolderRSN
	AND processcode = @argProcessCode
	AND endDate IS NULL


IF @n_processCount = 0 OR @newProcess = 1
	BEGIN

		SELECT @v_FolderType = folderType
		FROM folder
		WHERE folderRSN = @argFolderRSN

		SELECT @n_processCount = count(*)
		FROM defaultProcess dp
		WHERE folderType = @v_FolderType
		AND dp.processCode = @argProcessCode

		IF @n_processCount > 0
		BEGIN
	
			SELECT @n_folderStage = max(folderStage) 
			FROM defaultProcess 
			WHERE folderType = @v_folderType 
			AND processCode = @argProcessCode

			SELECT @v_UserID = UserID, 
			@n_displayOrder = displayOrder*10, 
			@n_disciplineCode = disciplineCode,
			@v_mandatoryFlag = mandatoryFlag, 
			@d_scheduleDate = dbo.f_GetNextWorkingDay(@argProcessCode, getDate(), dueDateCalc, dueDateCalcType), 
			@d_scheduleEndDate = dbo.f_GetNextWorkingDay(@argProcessCode, getDate(), completionDays, completionDaysType)
			FROM defaultProcess dp, validProcess vp
			WHERE folderType = @v_FolderType
			AND dp.processCode = @argProcessCode
			AND vp.processCode = @argProcessCode
			AND dp.folderStage = @n_folderStage

			exec @n_processRSN = TK_PROCESS_INSERT @argFolderRSN, @argProcessCode, @DUserID, @n_DisplayOrder, @v_UserID, @d_scheduleDate, @d_scheduleEndDate, @v_mandatoryFlag
		END
		ELSE
		BEGIN
	
			SELECT @n_disciplineCode = disciplineCode
			FROM validProcess
			WHERE processCode = @argProcessCode

			SELECT @n_DisplayOrder = max(ISNULL(displayOrder,0))+1
			FROM folderProcess
			WHERE folderRSN = @argFolderRSN

			exec @n_processRSN = TK_PROCESS_INSERT @argFolderRSN, @argProcessCode, @DUserID, @n_DisplayOrder, @v_UserID
		END
	END
	ELSE IF @newProcess = 1 --we will reopen the last process on this folder
	BEGIN
		SELECT @n_processRSN = max(processRSN) 
		FROM folderProcess
		WHERE folderRSN = @argFolderRSN
		AND processCode = @argProcessCode

		IF @n_processRSN IS NOT NULL
		BEGIN
			exec dbo.PC_Process_Update @n_processRSN, 1, @DUserID
		END

	END
	
	RETURN @n_processRSN

END









GO
