USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyDesRev]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyDesRev](@PropertyRSN INT) RETURNS VARCHAR(20)
AS 
BEGIN
	DECLARE @intcharVal VARCHAR(20)

	SELECT @intcharVal = Property.ZoneType3
	FROM Property
	WHERE PropertyRSN = @PropertyRSN

        IF @intcharVal = 'NO DES REV' SELECT @intcharVal = 'No'
        ELSE SELECT @intcharVal = 'Yes'

	RETURN @intcharVal
END


GO
