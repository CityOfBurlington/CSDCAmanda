USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GIS_FolderInfo]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure created to update FolderInfo from GIS in Amandai */

CREATE PROCEDURE [dbo].[GIS_FolderInfo] @argFolderRSN INT, @argQueryRSN INT
as 

-- Amanda 44.27: Hongli July 10, 2009: Procedure created to update FolderInfo from GIS in Amandai

 DECLARE @n_InfoCode INT
 DECLARE @v_InfoValue VARCHAR(2000)

begin	
	DECLARE Info_Cur CURSOR FOR
          SELECT ValidInfo.InfoCode, CSDC_Query_Number.Roll
            FROM ValidInfo, FolderInfo, CSDC_Query_Number
           WHERE FolderInfo.FolderRSN = @argFolderRSN
            and  FolderInfo.InfoCode = ValidInfo.InfoCode
            and  ValidInfo.InfoDesc = CSDC_Query_Number.StringVal
            and  CSDC_Query_Number.QueryRSN = @argQueryRSN

	OPEN Info_Cur


	FETCH NEXT FROM Info_Cur INTO @n_InfoCode, @v_InfoValue
	WHILE @@FETCH_STATUS = 0
	BEGIN   	
           UPDATE FolderInfo
              SET InfoValue = @v_InfoValue
            WHERE FolderRSN = @argFolderRSN and InfoCode = @n_InfoCode

	   FETCH NEXT FROM Info_Cur INTO @n_InfoCode, @v_InfoValue
	END

	CLOSE Info_Cur 
	DEALLOCATE Info_Cur

   COMMIT

   RAISERROR('CSDCWARNING:Updating FolderInfo is done. Please refresh to see the changes.', 16, -1)        

end


GO
