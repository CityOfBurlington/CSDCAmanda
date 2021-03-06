USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyNoOwner]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyNoOwner](@intPropertyRSN INT) 
RETURNS varchar(3)
AS
BEGIN
   /* Returns 'N' if PropertyPeople.PeopleCode = 2 (Owner) exists for a PropertyRSN, 
      and 'Y' if there is not one.  JA 11/2010 */

   DECLARE @intOwnerCount int
   DECLARE @varNoOwner varchar(3)

   SET @varNoOwner = 'N' 
   SET @intOwnerCount = 0

   SELECT @intOwnerCount = COUNT(*)
     FROM PropertyPeople 
    WHERE PropertyPeople.PropertyRSN = @intPropertyRSN 
      AND PropertyPeople.PeopleCode = 2   /* Owner */ 

   IF @intOwnerCount > 0 SELECT @varNoOwner = 'Y' 

   RETURN @varNoOwner
END

GO
