USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProperty_Upd]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProperty_Upd]
@PropertyRSN int, @UserId varchar(128)
as
DECLARE @NextRSN int

exec RsnSetLock

-- Clamp down on who can change property fields.  

IF @UserID NOT IN ('jappleton', 'jay', 'nholt', 'nanderson', 'jpoulin', 'sschrader', 'knosek', 'sa')
BEGIN
         RAISERROR('You are not allowed to change property records.',16,-1)
END 

DELETE FROM PropertyInfo 
WHERE PropertyRSN = @PropertyRSN 
AND PropInfoValue is null 
AND PropertyInfoCode not in 
    ( SELECT PropertyInfoCode 
      FROM ValidPropertyInfo, Property 
      WHERE ValidPropertyInfo.PropCode = Property.PropCode 
      AND Property.PropertyRSN = @PropertyRSN )  

INSERT INTO PropertyInfo ( PropertyRSN, PropertyInfoCode ) 
SELECT @PropertyRSN, ValidPropertyInfo.PropertyInfoCode 
FROM ValidPropertyInfo, Property 
WHERE Property.PropertyRSN = @PropertyRSN 
AND ValidPropertyInfo.PropCode = Property.PropCode 
AND ValidPropertyInfo.PropertyInfoCode not in 
    ( SELECT PropertyInfo.PropertyInfoCode 
      FROM PropertyInfo 
      WHERE PropertyInfo.PropertyRSN = @PropertyRSN ) 


GO
