USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDateChar11NotApp]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetDateChar11NotApp](@dtDate datetime) 
RETURNS varchar(30)
AS
BEGIN
	/* If date is null, return Not Applicable. Otherwise return short date. JA 9/2012 */

	DECLARE @varDate varchar(20)
	SET @varDate = ' '

	IF @dtDate IS NULL SELECT @varDate = 'Not Applicable'
	ELSE
	SELECT @varDate = CONVERT(CHAR(11), @dtDate)

	RETURN @varDate
END

GO
