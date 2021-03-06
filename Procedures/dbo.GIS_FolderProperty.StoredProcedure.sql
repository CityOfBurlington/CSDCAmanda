USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GIS_FolderProperty]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure created to insert rows in FolderProperty table from GIS in Amandai */

CREATE PROCEDURE [dbo].[GIS_FolderProperty] @argFolderRSN INT, @argQueryRSN INT
as 

-- Amanda 44.27: Hongli July 10, 2009: Procedure created to insert rows in FolderProperty table from GIS in Amandai

DECLARE @n_PropertyRSN INT

begin	
	DECLARE Property_Cur CURSOR FOR
         SELECT Property.PropertyRSN 
           FROM Property, CSDC_QUERY_NUMBER 
          WHERE CSDC_QUERY_NUMBER.QueryRSN = @argQueryRSN
           AND  Property.PropGISID1 = CSDC_QUERY_NUMBER.StringVal
           AND  Property.PropertyRSN NOT IN (SELECT PropertyRSN FROM FolderProperty WHERE FolderRSN = @argFolderRSN)

	OPEN Property_Cur


	FETCH NEXT FROM Property_Cur INTO @n_PropertyRSN
	WHILE @@FETCH_STATUS = 0
	BEGIN   	
           INSERT INTO FolderProperty (FolderRSN, PropertyRSN)
                VALUES (@argFolderRSN, @n_PropertyRSN);

	   FETCH NEXT FROM Property_Cur INTO @n_PropertyRSN
	END

	CLOSE Property_Cur 
	DEALLOCATE Property_Cur

end

GO
