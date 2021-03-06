USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCurrentPage]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetCurrentPage](@pintPageSize int, @pintTotalRecords int)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @strReturnString	Varchar(100)
	DECLARE @intMinPageCount	Int
	DECLARE @intTotalPageCount	Int

	IF @pintTotalRecords <= @pintPageSize
		BEGIN
			SET @strReturnString = '1'
		END
	IF @pintTotalRecords > @pintPageSize
		BEGIN
			SET @intMinPageCount = @pintTotalRecords / @pintPageSize

			IF @pintTotalRecords % @pintPageSize > 0
				BEGIN
					SET @intTotalPageCount = @intMinPageCount + 1
				END

			SET @strReturnString = Cast(@intTotalPageCount as Varchar(10))
		END

	RETURN @strReturnString
END


GO
