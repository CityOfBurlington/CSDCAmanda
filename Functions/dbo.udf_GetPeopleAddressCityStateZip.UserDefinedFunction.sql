USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeopleAddressCityStateZip]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetPeopleAddressCityStateZip](@intPeopleRSN INT)
RETURNS varchar(255)
AS
BEGIN
   DECLARE @varRetVal varchar(255)
   DECLARE @AddrLine2 varchar(255)
   DECLARE @AddrLine3 varchar(255)

   SELECT @AddrLine2 = LTRIM(RTRIM(NULLIF(People.AddressLine2, ' '))),
          @AddrLine3 = LTRIM(RTRIM(NULLIF(People.AddressLine3, ' ')))
     FROM People
    WHERE People.PeopleRSN = @intPeopleRSN

   IF @AddrLine3 IS NULL SELECT @varRetVal = @AddrLine2
   ELSE SELECT @varRetVal = @AddrLine3
   RETURN UPPER(@varRetVal)
END

GO
