USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Gis_Neighbourhood]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure Gis_Neighbourhood created for AMANDA Browser Version */

CREATE PROCEDURE [dbo].[Gis_Neighbourhood] @argQueryRSN INT, @argFolderRSN INT, @argDocumentRSN INT, @argBufferWidth INT AS
BEGIN

-- AMANDA 4.4.27a: Hongli Oct 2009

DECLARE @n_PropertyRSN INT,
        @n_PeopleRSN INT,
        @n_DocumentCode INT,
        @n_Count INT,
        @n_InsertedCount INT,
        @n_ExistCount INT,
        @c_Message VARCHAR(400)

DECLARE  Property_Cur CURSOR FOR
SELECT Property.PropertyRSN 
  FROM Property, CSDC_QUERY_NUMBER 
 WHERE CSDC_QUERY_NUMBER.QueryRSN = @argQueryRSN
  AND  Property.PropGISID1 = CSDC_QUERY_NUMBER.StringVal

SET @n_InsertedCount = 0
SET @n_ExistCount = 0

SELECT @n_DocumentCode = DocumentCode FROM FolderDocument WHERE DocumentRSN = @argDocumentRSN

OPEN Property_Cur

FETCH Property_Cur INTO @n_PropertyRSN

WHILE @@FETCH_STATUS = 0
  BEGIN -- 1
    DECLARE  PropertyOwner_Cur CURSOR FOR
      SELECT PropertyPeople.PeopleRSN 
        FROM PropertyPeople, Property
       WHERE PropertyPeople.PropertyRSN = @n_PropertyRSN
    	AND  PropertyPeople.PropertyRSN = Property.PropertyRSN
    	AND  PropertyPeople.PeopleCode =  2

    OPEN PropertyOwner_Cur

    FETCH PropertyOwner_Cur INTO @n_PeopleRSN
    WHILE @@FETCH_STATUS = 0
      BEGIN -- 2
        SELECT @n_Count = COUNT(*)
	    FROM FolderDocumentTo
	   WHERE FolderDocumentTo.FolderRSN   = @argFolderRSN
	    AND  FolderDocumentTo.DocumentRSN = @argDocumentRSN
	    AND  FolderDocumentTo.PeopleRSN   = @n_PeopleRSN
	    AND  FolderDocumentTo.PropertyRSN = @n_PropertyRSN
    
        IF (@n_Count = 0)
          BEGIN -- 3
		INSERT INTO FolderDocumentTo
			(DocumentRSN,
			 FolderRSN,
			 DocumentCode,
			 PropertyRSN,
			 PeopleRSN)
		VALUES(@argDocumentRSN,
			 @argFolderRSN,
			 @n_DocumentCode,
			 @n_PropertyRSN,
			 @n_PeopleRSN)

		COMMIT

		SET @n_InsertedCount = @n_InsertedCount + 1
          END -- 3
	  ELSE
	    SET @n_ExistCount = @n_ExistCount + 1

        FETCH PropertyOwner_Cur INTO @n_PeopleRSN
      END -- 2

    CLOSE PropertyOwner_Cur
    DEALLOCATE PropertyOwner_Cur

    FETCH Property_Cur INTO @n_PropertyRSN
  END -- 1

CLOSE Property_Cur
DEALLOCATE Property_Cur

IF (@n_InsertedCount = 0)
	SET @c_Message = 'Completed, but no Send To records were inserted. '
ELSE IF (@n_InsertedCount = 1)
	SET @c_Message = 'Completed Successfully. One Send To record was inserted. '
ELSE
	SET @c_Message = 'Completed Successfully. ' + @n_InsertedCount + ' Send To record was inserted. '

IF (@n_ExistCount = 1)
	SET @c_Message = @c_Message + 'One Send To record was not inserted because it was already there. '
ELSE IF (@n_ExistCount > 1)
	SET @c_Message = @c_Message + @n_ExistCount + ' Send To records were not inserted because they were already there. '

IF (@n_InsertedCount = 0)
	SET @c_Message = @c_Message + 'Neighbourhood Search found no properties. '
ELSE IF (@n_InsertedCount = 1)
	SET @c_Message = @c_Message + 'Neighbourhood Search found one property. '
ELSE
	SET @c_Message = @c_Message + 'Neighbourhood Search found ' + @n_InsertedCount + ' properties . '

RAISERROR(@c_Message, 16, -1)

END


GO
