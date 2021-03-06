USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_OnlyChars]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_OnlyChars] (@StrVal AS VARCHAR(8000))
RETURNS VARCHAR(8000)
AS
BEGIN
      WHILE PATINDEX('%[^A-Z]%', @StrVal) > 0
            SET @StrVal = REPLACE(@StrVal,
                SUBSTRING(@StrVal,PATINDEX('%[^A-Z]%', @StrVal),1), '')
      RETURN @StrVal
END
GO
