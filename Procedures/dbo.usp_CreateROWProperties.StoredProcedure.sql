USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateROWProperties]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CreateROWProperties]
AS
BEGIN

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure uses the list of Burlington streets in ValidStreet */
	/* to create new properties of type Street Right-of-Way. These properties   */
	/* can then be used in folders referencing work anywhere in the street ROW  */

	DECLARE @PropCity VARCHAR(40)
	DECLARE @PropStreet VARCHAR(40)
	DECLARE @PropStreetType VARCHAR(10)
	DECLARE @NextPropertyRSN INT
			
	/* Select all ValidStreet records to use to insert new ROW properties */
	DECLARE curStreets CURSOR FOR
		SELECT PropCity, PropStreet, PropStreetType
		FROM ValidStreet

	/* Create a cursor to process selected folders */
	OPEN curStreets
	FETCH NEXT FROM curStreets INTO @PropCity, @PropStreet, @PropStreetType
	WHILE @@FETCH_STATUS = 0
		BEGIN

		/* Insert new ROW record into Property table */

		SELECT @NextPropertyRSN = dbo.GetNextPropertyRSN()
		INSERT INTO Property
		(PropertyRSN, PropCode, PropHouse, PropStreet, PropStreetType, PropCity, PropProvince, PropStreetUpper)
		SELECT @NextPropertyRSN,200, 'ROW', @PropStreet, @PropStreetType, @PropCity, 'VT', @PropStreet 

		FETCH NEXT FROM curStreets INTO @PropCity, @PropStreet, @PropStreetType
	END

	CLOSE curStreets
	DEALLOCATE curStreets

END


GO
