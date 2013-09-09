USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNextPeopleRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetNextPeopleRSN]() RETURNS INT
AS
BEGIN
	DECLARE @RetVal INT

	SELECT @RetVal = MAX(PeopleRSN) + 1
	FROM People

	RETURN @RetVal
END
GO
