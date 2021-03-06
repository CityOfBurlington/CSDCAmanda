USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_PROCESS_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[TK_PROCESS_INSERT]
@argFolderRSN int, 
@argProcessCode int, 
@DUserID varchar(1000), 
@argDisplayOrder int = NULL, 
@argAssignedUser varchar(1000) = NULL, 
@argScheduleDate datetime = NULL, 
@argScheduleEndDate datetime = NULL, 
@argMandatoryFlag varchar(10) = NULL
AS

DECLARE @n_processRSN int
DECLARE @n_disciplineCode int
DECLARE @n_DisplayOrder int

BEGIN
	
	SELECT @n_disciplineCode = max(disciplineCode)
	FROM validProcess
	WHERE processCode = @argProcessCode

	IF @argDisplayOrder IS NULL
	BEGIN
		SELECT @n_DisplayOrder = max(displayOrder)
		FROM folderProcess
		WHERE folderRSN = @argFOlderRSN
	END
	ELSE
	BEGIN
		SET @n_displayOrder = @argDisplayOrder
	END

	SELECT @n_processRSN = ISNULL(max(processRSN),0)+1
	FROM folderProcess

	INSERT INTO FolderProcess
	(ProcessRSN, FolderRSN, ProcessCode, DisciplineCode,
	PrintFlag, StatusCode, StampDate, StampUser, DisplayOrder, MandatoryFlag, ScheduleDate, ScheduleEndDate, AssignedUser )
	VALUES 
	(@n_ProcessRSN, @argFolderRSN, @argProcessCode, @n_disciplineCode,
	'N', 1, getDate(), @DUserId, @n_DisplayOrder, @argMandatoryFlag, @argScheduleDate, @argScheduleEndDate, @argAssignedUser)

	RETURN @n_processRSN
END;

GO
