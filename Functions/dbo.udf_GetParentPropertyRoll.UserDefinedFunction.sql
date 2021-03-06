USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetParentPropertyRoll]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetParentPropertyRoll](@ParentPropertyRSN AS INT) RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @RetVal VARCHAR(20)
	
	SELECT @RetVal = PropertyRoll
	FROM Property
	WHERE PropertyRSN = @ParentPropertyRSN
	
	RETURN @RetVal
END

GO
