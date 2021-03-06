USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_julian_date]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_julian_date](@InDate datetime) 
        RETURNS int
AS
BEGIN
   DECLARE @JulianDate int
   SELECT @JulianDate = 
   ( DATEPART(year, @InDate)*10000 ) + 
   ( DATEPART(month, @InDate)*100 ) + 
   ( DATEPART(day, @InDate) ) 
   RETURN @JulianDate
END


GO
