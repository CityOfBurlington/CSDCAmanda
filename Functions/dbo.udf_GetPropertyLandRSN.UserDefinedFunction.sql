USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyLandRSN]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyLandRSN](@intPropertyRSN INT) 
RETURNS INT
AS
BEGIN
	/* Searches for and loops through Parent Properties, to get the 
	   PropertyRSN for a Property Type with Land. 
	   Returns PropertyRSN for Property.PropCode IN (10, 11, 12, 13, 14 ,15, 22).
	   Called by usp_PropertyImperviousSurfaceUpdate  JA 6/2012 */

	DECLARE @intLandPropertyRSN int
	DECLARE @intParentPropertyRSN int
	DECLARE @intPropertyType int
	DECLARE @varParentFlag varchar(2)
	
	SET @intLandPropertyRSN = 0
	SET @intParentPropertyRSN = 0
	SET @intPropertyType = 0
	SET @varParentFlag = 'N'

	SELECT @intParentPropertyRSN = ISNULL(Property.ParentPropertyRSN, 0)
	FROM Property
	WHERE Property.PropertyRSN = @intPropertyRSN

	/* If Property.ParentPropertyRSN is null, there is nothing more to do. */

	IF @intParentPropertyRSN = 0
		SELECT @intLandPropertyRSN = @intPropertyRSN, @varParentFlag = 'Y'
	
	WHILE @varParentFlag = 'N' 
	BEGIN
		SELECT @intParentPropertyRSN = ISNULL(Property.ParentPropertyRSN, 0), 
			@intPropertyType = ISNULL(Property.PropCode, 0)
		FROM Property
		WHERE Property.PropertyRSN = @intPropertyRSN

		IF @intParentPropertyRSN > 0 
		BEGIN
			SELECT @intPropertyType = ISNULL(Property.PropCode, 0)
			FROM Property
			WHERE Property.PropertyRSN = @intParentPropertyRSN
			
			IF @intPropertyType IN (10, 11, 12, 13, 14 ,15, 22)		/* Land types */
				SELECT @intLandPropertyRSN = @intParentPropertyRSN, @varParentFlag = 'Y'
			ELSE 
				SELECT @intPropertyRSN = @intParentPropertyRSN
		END
	END

	RETURN @intLandPropertyRSN
END

GO
