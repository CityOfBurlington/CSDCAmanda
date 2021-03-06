USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetInitialQCEvaluationDate]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetInitialQCEvaluationDate](@FolderRSN INT) RETURNS Datetime
AS
BEGIN

/* Get the Date for the first inspection on the folder. 
	- Find the ScheduleDate for the process with ProcessCode 20018 (Code Complaint Evaluation)
*/
DECLARE @datRetVal DATETIME

	Select @datRetVal = ScheduleDate
		FROM  FolderProcess, ValidProcess
		WHERE FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = 20018

RETURN @datRetVal

END

GO
