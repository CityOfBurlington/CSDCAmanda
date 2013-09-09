USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_Trunc]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[udf_Trunc](@Date datetime)
Returns Varchar(10)
AS
BEGIN
	RETURN CONVERT(VarChar(10), @Date, 101) 
END


GO
