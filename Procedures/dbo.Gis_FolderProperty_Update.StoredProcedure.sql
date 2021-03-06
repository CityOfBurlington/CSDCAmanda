USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Gis_FolderProperty_Update]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure created to delete the existing rows and insert rows in FolderProperty table from GIS in Amandai */

CREATE PROCEDURE [dbo].[Gis_FolderProperty_Update] @argFolderRSN INT, @argQueryRSN INT
as 

-- Amanda 44.27: Hongli July 10, 2009: Procedure created to delete the existing rows and insert rows in FolderProperty table from GIS in Amandai

 DECLARE @n_PropertyRSN INT
 DECLARE @n_NumericVal INT

begin	
	DECLARE Property_Cur CURSOR FOR
         SELECT Property.PropertyRSN, CSDC_QUERY_NUMBER.NumericVal
           FROM Property, CSDC_QUERY_NUMBER 
          WHERE CSDC_QUERY_NUMBER.QueryRSN = @argQueryRSN AND  Property.PropGISID1 = CSDC_QUERY_NUMBER.StringVal
           ORDER BY CSDC_QUERY_NUMBER.NumericVal ASC

        DELETE FROM FolderProperty WHERE FolderRSN = @argFolderRSN

	OPEN Property_Cur


	FETCH NEXT FROM Property_Cur INTO @n_PropertyRSN, @n_NumericVal
	WHILE @@FETCH_STATUS = 0
	BEGIN
           IF @n_NumericVal = 1
             UPDATE Folder SET PropertyRSN = @n_PropertyRSN WHERE FolderRSN = @argFolderRSN;

           INSERT INTO FolderProperty (FolderRSN, PropertyRSN)
                VALUES (@argFolderRSN, @n_PropertyRSN);

	   FETCH NEXT FROM Property_Cur INTO @n_PropertyRSN, @n_NumericVal
	END

	CLOSE Property_Cur 
	DEALLOCATE Property_Cur

end


GO
