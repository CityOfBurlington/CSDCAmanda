USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultPropertyInfo_Upd]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultPropertyInfo_Upd]
@PropertyRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
/* Sets up default PropertyInfo fields.  
   For rental properties, checks to see if an inspector has been assigned. */
/* Runs at update, or with the Property Redefault button. */

EXECUTE dbo.usp_PropertyInfoDefault @PropertyRSN, @UserID

/* Check to insure an inspector has been assigned  where rental units exist. */

DECLARE @intRentalUnits int
DECLARE @strInspectorAssigned varchar(30)

SELECT @intRentalUnits = ISNULL(PropInfoValue, 0)
FROM PropertyInfo
WHERE PropertyInfoCode = 20                      /*No of Res Rental Units*/
AND PropertyRSN = @PropertyRSN
/*
IF @intRentalUnits > 0
BEGIN
      SELECT @strInspectorAssigned = PropInfoValue
      FROM PropertyInfo
      WHERE PropertyInfoCode = 600            /*Code Inspector Assigned*/
      AND PropertyRSN = @PropertyRSN

      IF RTRIM(LTRIM(ISNULL(@strInspectorAssigned, ''))) = ''
      BEGIN
           RAISERROR('Error! A Minimum Housing inspector must be assigned to this property', 16, -1)
      END
END
*/
GO
