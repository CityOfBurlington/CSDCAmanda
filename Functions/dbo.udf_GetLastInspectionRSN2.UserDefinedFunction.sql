USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastInspectionRSN2]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetLastInspectionRSN2](@FolderRSN INT) RETURNS INT
AS
BEGIN

/* Get the ProcessRSN for the most recent inspection on the folder. 
	- Find the maximum ScheduleDate among processes in ProcessGroup 75 (inspections)
	- Get the ProcessRSN from this process
*/
DECLARE @intRetVal INT

SELECT @intRetVal = ProcessRSN 
FROM FolderProcess 
WHERE FolderProcess.FolderRSN = @FolderRSN
AND ScheduleDate =
		(SELECT MAX(ScheduleDate)
		FROM  FolderProcess, ValidProcess
		WHERE FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = ValidProcess.ProcessCode
		AND ValidProcess.ProcessGroupCode <> 15) -- Inspections

RETURN @intRetVal

END



GO
