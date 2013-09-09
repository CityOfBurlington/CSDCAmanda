USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeopleAddressZip]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPeopleAddressZip](@intPeopleRSN INT)
RETURNS varchar(255)
AS
BEGIN
   DECLARE @varRetVal VARCHAR(255)

   SELECT @varRetVal = People.AddrPostal
     FROM People
    WHERE People.PeopleRSN = @intPeopleRSN

   RETURN UPPER(@varRetVal)
END



GO
