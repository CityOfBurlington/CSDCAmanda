USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetInitialInspectionDate]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetInitialInspectionDate](@FolderRSN INT) RETURNS Datetime
AS
BEGIN

/* Get the Date for the first inspection on the folder. 
	- Find the minimum ScheduleDate among processes in ProcessGroup 75 (inspections)
*/
DECLARE @datRetVal DATETIME

	Select @datRetVal = MIN(ScheduleDate)
		FROM  FolderProcess, ValidProcess
		WHERE FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = ValidProcess.ProcessCode
		AND ValidProcess.ProcessGroupCode = 75 -- Inspections

RETURN @datRetVal

END
GO
