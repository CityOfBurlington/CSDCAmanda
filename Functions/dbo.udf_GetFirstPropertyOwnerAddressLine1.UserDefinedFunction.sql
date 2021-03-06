USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPropertyOwnerAddressLine1]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetFirstPropertyOwnerAddressLine1](@intPropertyRSN int) 
	RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @varRetVal VARCHAR(255)

	SELECT TOP 1 @varRetVal = People.AddressLine1
	             FROM Property, PropertyPeople, People
                            WHERE People.PeopleRSN = PropertyPeople.PeopleRSN
                                  AND PropertyPeople.PropertyRSN = Property.PropertyRSN
                                  AND Property.PropertyRSN = @intPropertyRSN 
                                  AND PropertyPeople.PeopleCode = 2
	    ORDER BY People.PeopleRSN;

	RETURN @varRetVal
END

GO
