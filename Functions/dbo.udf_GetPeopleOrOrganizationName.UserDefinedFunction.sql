USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeopleOrOrganizationName]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dana Baron
-- Create date: 4/18/2008
-- Description:	Takes PeopleRSN and finds either the People Name or 
--				if the Organization Name (if people is blank or NULL)
-- =============================================
CREATE FUNCTION [dbo].[udf_GetPeopleOrOrganizationName]
(
	@intPeopleRSN INT
)
RETURNS VARCHAR(200)
AS
BEGIN

	-- Declare the return variable here
	DECLARE @varRetVal VARCHAR(200)

	-- Add the T-SQL statements to compute the return value here
	SELECT @varRetVal = 
	    CASE WHEN 
		    (dbo.udf_GetPeopleName(PeopleRSN)) IS NULL OR (LEN(dbo.udf_GetPeopleName(PeopleRSN))=0) 
			THEN dbo.udf_GetPeopleOrganizationName(PeopleRSN)
		ELSE
			dbo.udf_GetPeopleName(PeopleRSN) 
		END 
	FROM People WHERE PeopleRSN = @intPeopleRSN

	-- Return the result of the function
	RETURN UPPER(@varRetVal)
END


GO
