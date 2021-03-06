USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastInspector]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetLastInspector](@FolderRSN INT) RETURNS VARCHAR(10)
AS
BEGIN

/* Get the ProcessRSN for the most recent inspection on the folder. 
	- Find the maximum ScheduleDate among processes in ProcessGroup 75 (inspections)
	- Get the ProcessRSN from this process
*/
DECLARE @strRetVal VARCHAR(10)

SELECT @strRetVal = FolderProcess.AssignedUser
  FROM FolderProcess
  WHERE ProcessRSN = (dbo.udf_GetLastInspectionRSN(@FolderRSN))

RETURN @strRetVal

END


GO
