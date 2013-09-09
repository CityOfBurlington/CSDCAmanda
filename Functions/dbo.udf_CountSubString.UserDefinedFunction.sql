USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CountSubString]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_CountSubString](@strFullText varchar(2000), @strTextToFind varchar(200))
RETURNS INT
AS
BEGIN
DECLARE @intRetVal INT
SELECT @intRetVal = (LEN(@strFullText) - LEN(REPLACE(@strFullText, @strTextToFind, '' ) ) ) / LEN(@strTextToFind)
RETURN @intRetVal
END 



GO
