USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFirstPropertyOwnerAddressLine2]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFirstPropertyOwnerAddressLine2](@intPropertyRSN int) 
RETURNS varchar(255)
AS
BEGIN
        DECLARE @varRetVal varchar(255)
        DECLARE @AddrLine2 varchar(255)
        DECLARE @AddrLine3 varchar(255)

        SELECT TOP 1 @AddrLine2 = LTRIM(RTRIM(NULLIF(People.AddressLine2, ' '))), 
                     @AddrLine3 = LTRIM(RTRIM(NULLIF(People.AddressLine3, ' ')))
	            FROM Property, PropertyPeople, People
               WHERE People.PeopleRSN = PropertyPeople.PeopleRSN
                     AND PropertyPeople.PropertyRSN = Property.PropertyRSN
                     AND Property.PropertyRSN = @intPropertyRSN 
                     AND PropertyPeople.PeopleCode = 2
            ORDER BY People.PeopleRSN;

        IF @AddrLine3 IS NULL SELECT @varRetVal = @AddrLine2
        ELSE SELECT @varRetVal = @AddrLine3

	RETURN @varRetVal
END


GO
