USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_InStrRight]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_InStrRight] (
     @string VARCHAR(200),
     @delimiter VARCHAR(4)= '-',
     @fromLeft BIT = 1
)
RETURNS VARCHAR(200)
AS
BEGIN
RETURN LTRIM(RTRIM(
     CASE WHEN CHARINDEX(@delimiter, @string) = 0
          THEN @string
     ELSE 
          CASE WHEN @fromLeft = 1
               THEN SUBSTRING(@string, 1, CHARINDEX(@delimiter, @string) - 1)
          ELSE 
               RIGHT(@string, CHARINDEX(@delimiter, REVERSE(@string)) - 1)
          END --CASE
     END --CASE
))
END --FUNCTION


GO
