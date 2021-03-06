USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_RemoveSpecialChars]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   function [dbo].[udf_RemoveSpecialChars](@strInputString text)
returns varchar(4000)
as
begin
	DECLARE @RetVal VARCHAR(4000)

	SET @RetVal = Replace(Replace(Replace(Replace(Convert(Varchar(4000), SubString(@strInputString, 1, 4000)), '"', '""'), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ')

	RETURN @RetVal
end

GO
