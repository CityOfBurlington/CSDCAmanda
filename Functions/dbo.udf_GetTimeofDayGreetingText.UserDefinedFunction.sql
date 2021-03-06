USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetTimeofDayGreetingText]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetTimeofDayGreetingText]()
RETURNS varchar(20)
AS 
BEGIN
	DECLARE @intHourofDay int
	DECLARE @varGreeting varchar(20)
	
	SET @varGreeting = 'Good Day'

	SELECT @intHourofDay = DATEPART(HOUR, getdate())
		
	IF @intHourofDay BETWEEN 0  AND 11 SELECT @varGreeting = 'Good Morning'
	IF @intHourofDay BETWEEN 12 AND 18 SELECT @varGreeting = 'Good Afternoon'
	IF @intHourofDay BETWEEN 18 AND 24 SELECT @varGreeting = 'Good Evening'

	RETURN ISNULL(@varGreeting, ' ')
END

GO
