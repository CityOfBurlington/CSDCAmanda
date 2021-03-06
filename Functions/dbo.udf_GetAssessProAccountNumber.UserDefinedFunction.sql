USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetAssessProAccountNumber]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetAssessProAccountNumber](@PropertyRSN int) 
	RETURNS VARCHAR(6)
AS
BEGIN
	DECLARE @strRetVal VARCHAR(6)

	SET @strRetVal = NULL
	IF EXISTS (SELECT PropInfoValue FROM PropertyInfo WHERE PropertyRSN = @PropertyRSN AND PropertyInfoCode = 500)
	BEGIN 
		SELECT @strRetVal = PropInfoValue FROM PropertyInfo WHERE PropertyRSN = @PropertyRSN AND PropertyInfoCode = 500
	END

	RETURN @strRetVal

END



GO
