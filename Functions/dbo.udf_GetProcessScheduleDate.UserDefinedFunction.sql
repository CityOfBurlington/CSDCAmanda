USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessScheduleDate]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetProcessScheduleDate](@FolderRSN INT, @ProcessCode INT) RETURNS DATETIME
AS
BEGIN
	DECLARE @dtmRetVal DATETIME

	SELECT @dtmRetVal = FolderProcess.ScheduleDate
	FROM FolderProcess
	WHERE FolderRSN = @FolderRSN
	AND ProcessCode = @ProcessCode

	RETURN @dtmRetVal
END


GO
