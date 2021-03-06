USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDateLong]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetDateLong](@Date datetime) 
RETURNS varchar(30)
AS
BEGIN
   DECLARE @strDateLong varchar(30)
   SET @strDateLong = ' '

   SELECT @strDateLong = RTRIM(DATENAME(MONTH, @Date) + ' ' + DATENAME(DAY, @Date) + ', ' + DATENAME(YEAR, @Date))

   RETURN @strDateLong
END




GO
