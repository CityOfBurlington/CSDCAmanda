USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[FolderReCompute]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



/* Inserts/Updates the records of the table FolderCompted. */

CREATE PROCEDURE [dbo].[FolderReCompute]
	@argFolderRSN INT, 
	@argPropertyRSN INT, 
	@argPeopleRSN INT, 
	@argFolderType VARCHAR(4), 
	@argPeopleCode INT, 
	@argStatusCode INT, 
	@argOperationName VARCHAR(10)
AS

DECLARE
  @theCount INT

BEGIN

   SELECT @theCount = COUNT(*) FROM FolderComputed WHERE FolderRSN = @argFolderRSN;
  
   IF @argOperationName = 'Folder' OR @argOperationName = ''
   BEGIN
--RAISERROR('FolderComputed',16,-1);
        IF @theCount > 0 --Do the update
            UPDATE FolderComputed             
            SET ViolationFlag = dbo.f_GetViolationFlag_Recompute(@argPropertyRSN, @argFolderRSN, @argFolderType, @argStatusCode, @argOperationName), 
                PrimaryPeople = dbo.f_primaryPeople_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName),
                PrimaryPeopleRSN = dbo.f_primaryPeopleRSN_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName)
            WHERE FolderRSN = @argFolderRSN;
        ELSE    --Insert Operation
            INSERT INTO FolderComputed(FolderRSN, ViolationFlag, PrimaryPeople, PrimaryPeopleRSN) 
            VALUES(@argFolderRSN, dbo.f_GetViolationFlag_Recompute(@argPropertyRSN, @argFolderRSN, @argFolderType, @argStatusCode, @argOperationName),
				 dbo.f_primaryPeople_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName),
				 dbo.f_primaryPeopleRSN_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName));
   END
   
   IF @argOperationName = 'People'
   BEGIN
   
        IF @theCount > 0  --Do the update
            UPDATE FolderComputed             
            SET ViolationFlag = dbo.f_GetViolationFlag_Recompute(@argPropertyRSN, @argFolderRSN, @argFolderType, @argStatusCode, @argOperationName), 
                PrimaryPeople = dbo.f_primaryPeople_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName),
                PrimaryPeopleRSN = dbo.f_primaryPeopleRSN_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName)
            WHERE FolderRSN = @argFolderRSN;
        ELSE    --Insert Operation
            INSERT INTO FolderComputed(FolderRSN, ViolationFlag, PrimaryPeople, PrimaryPeopleRSN) 
            VALUES(@argFolderRSN, dbo.f_GetViolationFlag_Recompute(@argPropertyRSN, @argFolderRSN, @argFolderType, @argStatusCode, @argOperationName),
				 dbo.f_primaryPeople_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName),
				 dbo.f_primaryPeopleRSN_Recompute(@argFolderRSN, @argPeopleRSN, @argFolderType, @argPeopleCode, @argOperationName));
   END
     
   IF @argOperationName = 'Property'
   BEGIN
        
        IF @theCount > 0    --Do the update
            UPDATE FolderComputed             
            SET ViolationFlag = dbo.f_GetViolationFlag_Recompute(@argPropertyRSN, @argFolderRSN, @argFolderType, @argStatusCode, @argOperationName)
            WHERE FolderRSN = @argFolderRSN;
        ELSE    --Insert Operation
            INSERT INTO FolderComputed(FolderRSN, ViolationFlag) 
            VALUES(@argFolderRSN, dbo.f_GetViolationFlag_Recompute(@argPropertyRSN, @argFolderRSN, @argFolderType, @argStatusCode, @argOperationName));
   END

END

GO
