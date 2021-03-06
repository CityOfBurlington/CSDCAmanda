USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_DuplicateOwnersProcess]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DuplicateOwnersProcess]
AS

BEGIN

DECLARE @DupGroup INT
DECLARE @KeepRSN INT
DECLARE @FolderRSN INT

/* DECLARE the cursor */
DECLARE CurGeneral CURSOR FOR
--SELECT DupGroup FROM tblDuplicateRSN GROUP BY DupGroup HAVING Sum(Owner) = 0 AND Count(DISTINCT APCode) = 1 AND Count(DISTINCT APIndex) = 1
SELECT DupGroup FROM tblDuplicateRSN GROUP BY DupGroup HAVING Count(DISTINCT APCode) = 1 AND Count(DISTINCT APIndex) = 1
ORDER BY DupGroup
/* Can select multiple fields, but must fetch the same number in the FETCH statement(s) */

	/* Open the cursor */
	OPEN curGeneral
	/* Fetch the first value */
	FETCH NEXT FROM curGeneral INTO @DupGroup
	/* Loop through the cursor */
	WHILE @@FETCH_STATUS = 0
		BEGIN

		--SELECT DupGroup, PeopleRSN, Owner, APCode, APIndex FROM tblDuplicateRSN WHERE DupGroup = @DupGroup
		--SELECT DupGroup, PeopleRSN, APCode, APIndex FROM tblDuplicateRSN 
		--WHERE DupGroup = @DupGroup  
		--AND (SELECT Count(DISTINCT APCode) FROM tblDuplicateRSN WHERE DupGroup = @DupGroup) = 1 
		--AND (SELECT Count(DISTINCT APIndex) FROM tblDuplicateRSN WHERE DupGroup = @DupGroup) = 1 
		
		/* Find the highest PeopleRSN in the dup group. This is the one we're keeping */
		SELECT TOP 1 @KeepRSN = PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		ORDER BY PeopleRSN DESC

		--SELECT PeopleRSN FROM tblDuplicateRSN 
		--WHERE DupGroup = @DupGroup  
		--AND (SELECT Count(DISTINCT APCode) FROM tblDuplicateRSN WHERE DupGroup = @DupGroup) = 1 
		--AND (SELECT Count(DISTINCT APIndex) FROM tblDuplicateRSN WHERE DupGroup = @DupGroup) = 1
		--AND PeopleRSN <> @KeepRSN 
		--ORDER BY PeopleRSN DESC

		--SELECT Count(PeopleRSN) FROM tblDuplicateRSN 
		--WHERE DupGroup = @DupGroup
		--AND (SELECT Count(DISTINCT APCode) FROM tblDuplicateRSN WHERE DupGroup = @DupGroup) = 1 
		--AND (SELECT Count(DISTINCT APIndex) FROM tblDuplicateRSN WHERE DupGroup = @DupGroup) = 1 


		/* AccountPayment */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE AccountPayment SET BillToRSN = @KeepRSN WHERE BillToRSN in 
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* DefaultDocument */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE DefaultDocument SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* FolderDocument */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderDocument SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* FolderDocumentTo */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderDocumentTo SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderInspectionRequest SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* FolderPeople: */
		/* Delete records for folders with multiple duplicates */
		DELETE FROM FolderPeople 
		WHERE FolderRSN IN (SELECT FolderRSN FROM FolderPeople WHERE PeopleRSN = @KeepRSN) 
		AND PeopleRSN IN (SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Replace outgoing PeopleRSN with PeopleRSN we're keeping */
		UPDATE FolderPeople SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* FolderProcessPeople */
		/* Replace outgoing PeopleRSN with the PeopleRSN we're keeping */
		UPDATE FolderProcessPeople SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* PropertyPeople: */
		/* Delete records for folders with multiple duplicates */
		DELETE FROM PropertyPeople 
		WHERE PropertyRSN IN (SELECT PropertyRSN FROM PropertyPeople WHERE PeopleRSN = @KeepRSN) 
		AND PeopleRSN IN (SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)


		/* Replace outgoing PeopleRSN with PeopleRSN we're keeping */
		UPDATE PropertyPeople SET PeopleRSN = @KeepRSN WHERE PeopleRSN in
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Now delete the duplicate people records from the People table */
		DELETE FROM People WHERE PeopleRSN IN 
		(SELECT PeopleRSN FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup  
		AND PeopleRSN <> @KeepRSN)

		/* Delete the duplicate group we just processed from tblDuplicateRSN */
		DELETE FROM tblDuplicateRSN 
		WHERE DupGroup = @DupGroup

		/* Fetch the next value till done */
		FETCH NEXT FROM curGeneral INTO @DupGroup
	END

	/* Close the cursor */
	CLOSE curGeneral

	/* Deallocate the cursor */
	DEALLOCATE curGeneral

END
GO
