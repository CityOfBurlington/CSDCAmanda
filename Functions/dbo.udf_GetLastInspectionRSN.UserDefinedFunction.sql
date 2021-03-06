USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastInspectionRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetLastInspectionRSN](@FolderRSN INT) RETURNS INT
AS
BEGIN

/* Get the ProcessRSN for the most recent inspection on the folder. 
	- Find the maximum ScheduleDate among processes in ProcessGroup 75 (inspections)
	- Get the ProcessRSN from this process
*/
DECLARE @intRetVal INT

	Select @intRetVal = ProcessRSN from FolderProcess where ScheduleDate IN
		(SELECT MAX(ScheduleDate)
		FROM  FolderProcess, ValidProcess
		WHERE FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = ValidProcess.ProcessCode
		AND ValidProcess.ProcessGroupCode = 75) -- Inspections

RETURN @intRetVal

END

GO
