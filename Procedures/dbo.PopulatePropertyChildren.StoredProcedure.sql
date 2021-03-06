USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PopulatePropertyChildren]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE  [dbo].[PopulatePropertyChildren] (@p_parentRSN INT, @p_lvl INT out)
AS
DECLARE @v_PropertyRSN INT
	DECLARE @v_path VARCHAR(2000)
BEGIN
	/* Version 44.25: ESS Modified:2008.09.19:New column FamilyRSN added from #temp_Property */
	/*
	Name of Person: ESS
	Date : March 28 2006
	Version: 4.4.6

	Procedure PopulatePropertyChildren is used in AMANDAi for generating the related Children for Property Parent RSN
	*/
              
	DECLARE c_crs CURSOR LOCAL FOR
 		Select PropertyRSN,dbo.f_getRelatedPath(PropertyRSN,'Property') path From Property
		Where ParentPropertyRSN  = @p_parentRSN AND PropertyRSN != @p_parentRSN
		AND Not Exists (Select PropertyRSN From #temp_Property Where PropertyRSN = Property.PropertyRSN)
        ORDER BY PropStreet ASC, PropStreetType ASC, PropHouseNumeric ASC, PropStreetDirection ASC, PropUnitType ASC, PropUnit ASC, PropertyRSN ASC
	OPEN c_crs
	FETCH NEXT FROM c_crs INTO @v_PropertyRSN,@v_path
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @p_lvl = @p_lvl+1;
		INSERT INTO #temp_Property
		SELECT ParentPropertyRSN,PropertyRSN,@v_path,@p_lvl,PropHouseNumeric,PropHouse,PropStreetPrefix,PropStreet,PropStreetType,
			PropStreetDirection,PropUnitType,PropUnit,PropCity, PropProvince, PropPostal, PropCode, PropertyName, StatusCode,FamilyRSN
		FROM Property WHERE PropertyRSN = @v_PropertyRSN 
        
		EXEC PopulatePropertyChildren @v_PropertyRSN,@p_lvl OUT
	   	FETCH NEXT FROM c_crs INTO @v_PropertyRSN,@v_path
	END

	CLOSE c_crs
	DEALLOCATE c_crs
END

GO
