USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeopleFirstName]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPeopleFirstName](@PeopleRSN INT) RETURNS VARCHAR(400)
AS
BEGIN
	DECLARE @RetVal VARCHAR(400)

	SELECT @RetVal = People.NameFirst 
	FROM People
	WHERE People.PeopleRSN = @PeopleRSN

	RETURN @RetVal
END
GO
