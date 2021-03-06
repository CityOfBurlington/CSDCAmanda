USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Property_ZoneType_Recode]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Property_ZoneType_Recode]
AS
BEGIN 
	UPDATE Property
	SET Property.ZoneType1 = zbdparcel$.ZoneType1, 
		Property.ZoneType2 = zbdparcel$.ZoneType2, 
		Property.ZoneType3 = zbdparcel$.ZoneType3, 
		StampDate = getdate() 
	FROM Property, zbdparcel$
	WHERE Property.PropGISID1 = zbdparcel$.pin 
	AND Property.StatusCode IN (1, 3, 4)
	AND Property.PropCode < 100    /* All Property Types */
END


GO
