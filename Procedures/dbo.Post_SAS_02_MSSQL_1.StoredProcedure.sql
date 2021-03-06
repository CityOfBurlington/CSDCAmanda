USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Post_SAS_02_MSSQL_1]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure  [dbo].[Post_SAS_02_MSSQL_1] ( @ArgControlAssessmentRSN int)
AS
/* Procedure Altered Dated : 2001.05.01 */

/* Insert from property into x_property */
	DECLARE @n_PropertyRSN int
	DECLARE C_Prop CURSOR FOR
	SELECT  PropertyRSN 
	FROM     Property




/* X_Property  insert */
/* Start  CleanUp X_Property */
BEGIN

		OPEN C_Prop
		FETCH NEXT FROM C_Prop INTO @n_PropertyRSN
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			INSERT INTO X_Property  SELECt * FROM Property WHERE PropertyRSN = @n_PropertyRSN
					FETCH NEXT FROM C_Prop INTO @n_PropertyRSN
		END
		CLOSE C_Prop
		DEALLOCATE C_Prop

		
		

		UPDATE X_Property 
		SET  PropertyRoll = Null
		WHERE DATALENGTH(LTRIM(RTRIM(PropertyRoll))) > 19



		UPDATE X_Property 
		SET  PropertyRoll = Null
		WHERE DATALENGTH(LTRIM(RTRIM(PropertyRoll))) =  0



		UPDATE  X_Property 
		SET  PropertyRoll = Null
		WHERE SUBSTRING(LTRIM(RTRIM(PropertyRoll)),1,4) <> '4342'



		UPDATE X_Property
		SET  PropertyRoll = Null
		WHERE DATALENGTH(LTRIM(RTRIM(PropertyRoll))) < 19



		UPDATE X_Property
		SET  PropertyRoll = Null	WHERE CHARINDEX(' ',PropertyRoll) > 0


  		Insert Into X_SAS_StreetType Select LTRIM(RTRIM(PropStreetType)) From X_Property 
		Where LTRIM(RTRIM(PropStreetType)) is not null
		Group by LTRIM(RTRIM(PropStreetType)) 
		Order by LTRIM(RTRIM(PropStreetType))



		Insert Into X_SAS_StreetDirection Select LTRIM(RTRIM(PropStreetDirection)) From 		X_Property
		Where LTRIM(RTRIM(PropStreetDirection)) is not null
		Group by LTRIM(RTRIM(PropStreetDirection)) 
		Order by LTRIM(RTRIM(PropStreetDirection))


		UPDATE X_KK Set UnitNumber = Null where DATALENGTH(LTRIM(RTRIM(UnitNumber))) = 0
		

		UPDATE X_KK Set StreetNumber = Null where  DATALENGTH(LTRIM(RTRIM(STR(StreetNumber)))) = 0

END		
/* End CleanUp X_Property */

GO
