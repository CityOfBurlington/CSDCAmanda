USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddInfoFieldsToMHFolders]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_AddInfoFieldsToMHFolders]
AS
BEGIN

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure adds Property Info fields to properties associated with MH folders.         */ 
	/*   - If the property has a Last MH Inspection (25) info field, get the date from that.             */
	/*	 - If the property doesn't have a COC Issue Date (30), add it and fill it with Last MH Insp date */
	/*   - If the property doesn't have a COC Expiration Date field, add it and leave it balnk.          */

	DECLARE @CutOffDate DATETIME
	DECLARE @FolderRSN INT
	DECLARE @PropertyRSN INT
	DECLARE @ProcessRSN INT
	DECLARE @NextAttemptRSN INT
	DECLARE @UserID VARCHAR(10)
	DECLARE @LastMHInspection VARCHAR(20)

	/* Figure out the date was 2 months ago. */
	SET @CutOffDate = DATEADD(month, -2, getdate())
	--SET @CutOffDate = '8/1/2010'

	/* Select Folders to copy to new quarter: All VB folders from previous quarter that aren't Closed */
	DECLARE curMH CURSOR FOR
		SELECT PropertyRSN FROM Folder WHERE FolderType = 'MH' 
			--AND FolderRSN IN (202658,202657,202583,202281)
			/* 202658 - Has no COC fields or Last MH Inspection             */
			/* 202657 - Has COC fields but no Last MH Inspection            */
			/* 202583 - Has Last MH Inspection (08/26/05) AND COC fields    */
			/* 202281 - Has Last MH Inspection (06/18/07) but no COC fields */
	/* Open the cursor to process selected folders */
	OPEN curMH
	FETCH NEXT FROM curMH INTO @PropertyRSN
	WHILE @@FETCH_STATUS = 0
		BEGIN
		/* Get Last MH Inspection Date (25) if it exists */
		IF NOT EXISTS (SELECT PropInfoValue FROM PropertyInfo WHERE PropertyRSN = @PropertyRSN AND PropertyInfoCode = 25)
		BEGIN
			SET @LastMHInspection = NULL
		END
		ELSE
		BEGIN
			SELECT @LastMHInspection = PropInfoValue 
				FROM PropertyInfo WHERE PropertyRSN = @PropertyRSN AND PropertyInfoCode = 25
		END

		/* Check if COC Issue Date (30) exists. If not add it and fill it with Last MH Inspection Date */
		IF NOT EXISTS (SELECT PropInfoValue FROM PropertyInfo WHERE PropertyRSN = @PropertyRSN AND PropertyInfoCode = 30)
		BEGIN
			INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode, PropInfoValue, PropertyInfoValueDateTime,
				StampDate, StampUser)
			VALUES(@PropertyRSN, 30, @LastMHInspection, @LastMHInspection, getdate(), 'ddalton')
		END

		/* Check if COC Expiration Date (35) exists. If not add it but don't fill it. */
		IF NOT EXISTS (SELECT PropInfoValue FROM PropertyInfo WHERE PropertyRSN = @PropertyRSN AND PropertyInfoCode = 35)
		BEGIN
			INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode, PropInfoValue, PropertyInfoValueDateTime,
				StampDate, StampUser)
			VALUES(@PropertyRSN, 35, NULL, NULL, getdate(), 'ddalton')
		END

		FETCH NEXT FROM curMH INTO @PropertyRSN
	END

	CLOSE curMH
	DEALLOCATE curMH

END

GO
