USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ConvertProcessScheduleDate]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ConvertProcessScheduleDate](@ScheduleDate DATETIME, @TimeIndicator VARCHAR(4)) RETURNS DATETIME
AS
BEGIN
	DECLARE @Hour INT
	DECLARE @RetVal DATETIME

	IF @TimeIndicator = 'a.m' BEGIN
			SELECT @RetVal = 
			CASE WHEN DATEPART(HOUR, @ScheduleDate) < 7 THEN
			DATEADD(HOUR, 12, @ScheduleDate)
			WHEN DATEPART(HOUR, @ScheduleDate) + DATEPART(MINUTE, @ScheduleDate)/*12+0*/ = 12 THEN
			DATEADD(HOUR, 12, @ScheduleDate)
			ELSE
			@ScheduleDate
			END
		END
	ELSE
		BEGIN
		SET @RetVal = @ScheduleDate
	END

	RETURN @RetVal
END




GO
