USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[FolderCompute_Migration]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


/* Migration Script to insert the record into FolderComputed table from pre-existing Folder Table */

CREATE PROCEDURE [dbo].[FolderCompute_Migration]
AS
DECLARE
  @theCount INT,
  @v_FolderRSN INT,
  @v_PropertyRSN INT,
  @v_StatusCode INT

  DECLARE
  cur_Folder CURSOR LOCAL FOR 
  SELECT FolderRSN, PropertyRSN, StatusCode
  FROM Folder;

BEGIN

     SELECT @theCount = COUNT(*) FROM Folder;
     IF @theCount > 0 
	 BEGIN 
	     OPEN cur_Folder;
		FETCH NEXT FROM cur_Folder INTO @v_FolderRSN, @v_PropertyRSN, @v_StatusCode;
		WHILE (@@fetch_status = 0)
			BEGIN
				INSERT INTO FolderComputed(FolderRSN, ViolationFlag, PrimaryPeople, PrimaryPeopleRSN) 
				VALUES(@v_FolderRSN, dbo.f_getviolationflag(@v_PropertyRSN, @v_FolderRSN), dbo.f_primaryPeople(@v_FolderRSN), dbo.f_primaryPeopleRSN(@v_FolderRSN));
				FETCH NEXT FROM cur_Folder INTO @v_FolderRSN, @v_PropertyRSN, @v_StatusCode;
			END
	     CLOSE cur_Folder;
	     DEALLOCATE cur_Folder;
     END
END

GO
