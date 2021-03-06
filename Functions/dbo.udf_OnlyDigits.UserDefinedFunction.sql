USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_OnlyDigits]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_OnlyDigits] (@StrVal AS VARCHAR(8000))
RETURNS VARCHAR(8000)
AS
BEGIN
      WHILE PATINDEX('%[^0-9]%', @StrVal) > 0
            SET @StrVal = REPLACE(@StrVal,
                SUBSTRING(@StrVal,PATINDEX('%[^0-9]%', @StrVal),1), '')
      RETURN @StrVal
END
GO
