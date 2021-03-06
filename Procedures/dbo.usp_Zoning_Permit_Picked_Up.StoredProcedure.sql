USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Permit_Picked_Up]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Permit_Picked_Up] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
	/* Called by InfoValidation for FolderInfo.InfoCode = 10023 */

	/* Permit Pick Up is a watershed step in the review process as it means that the permit becomes 
	   officially valid, and review is complete. For programming this step is the best place to put 
	   in place components for ensuing steps. */

	DECLARE @varFolderType varchar(4)
	DECLARE @intWorkCode int
	DECLARE @varZPNumber varchar(20)
	DECLARE @varPropertyAddress varchar(100)
	DECLARE @varPermitPickedUp varchar(10)
	DECLARE @intNextStatusCode int
	DECLARE @intDecisionAttemptCode int
	DECLARE @varDecisionText varchar(60) 
	DECLARE @varPUMeans varchar(10)
	DECLARE @varLogText varchar(400)
	DECLARE @intAppealPeriodWaived int
	DECLARE @intNumberofPhasesInfoCount int 
	DECLARE @intNumberofPhases int 
	DECLARE @intDecisionProcessCode int
	DECLARE @varEmailSubject varchar(400) 
	DECLARE @varEmailBody varchar(8000) 
	DECLARE @varFromDescription varchar(400) 
	DECLARE @varProjectManagerName varchar(60)
	DECLARE @varProjectManagerFirstName varchar(20)
	DECLARE @varToAddress varchar(2000)
	DECLARE @varEmailGreeting varchar(20)

	SELECT @varFolderType = Folder.FolderType, @intWorkCode = Folder.WorkCode, @varZPNumber = Folder.ReferenceFile 
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN
	
	SET @varPermitPickedUp = 'No'

	SELECT @varPermitPickedUp = ISNULL(FolderInfo.InfoValue, 'No')
	FROM FolderInfo 
	WHERE FolderInfo.FolderRSN = @intFolderRSN
	AND FolderInfo.InfoCode = 10023

	/* Set review log text */
		
	SELECT @intDecisionAttemptCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)
	
	SELECT @varDecisionText = dbo.udf_GetZoningPermitPickedUpText(@intFolderRSN, @intDecisionAttemptCode)

	SELECT @varPUMeans = 
	CASE @varPermitPickedUp 
		WHEN 'Yes' THEN ' Picked Up'
		WHEN 'Mailed' THEN ' Mailed'
		ELSE NULL
	END

	SELECT @varLogText = ' -> ' + @varDecisionText + @varPUMeans + ' (' + CONVERT(char(11), getdate()) + ')'

	/*	Set next Folder.StatusCode and update review log. 
		COA Level 3 (Z3 folders): Preliminary Plats do not receive CO's, so StatusCode becomes 10031 (Review Complete). 
		For the same reason Determinations (ZD folders) become Review Complete.  
		StatusCode 10006 (Released) triggers insertion of the Certificate of Occupancy process (10001).  */

	IF @varPermitPickedUp IN ('Yes', 'Mailed') 
	BEGIN
		EXECUTE dbo.usp_Zoning_Update_FolderCondition_Log @intFolderRSN, @varLogText
		
		IF ( @varFolderType = 'Z3' AND @intWorkCode = 10009 ) OR @varFolderType = 'ZD' 
				SELECT @intNextStatusCode = 10031 
		ELSE SELECT @intNextStatusCode = 10006
		
		/* ZL - Findings of Fact are mailed immediately after decision is made.  */
		/* ZN - Applicant walks out the door with the Nonapp decision. */
	
		IF @varFolderType NOT IN ('ZL', 'ZN')
		BEGIN
			UPDATE Folder
			SET Folder.StatusCode = @intNextStatusCode
			WHERE Folder.FolderRSN = @intFolderRSN 
		END
	
		/* Send reminder email for Phased CO setup to Project Manager. */
		
		SELECT @intNumberofPhasesInfoCount = COUNT (*)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN 
		AND FolderInfo.InfoCode = 10081

		IF @intNumberofPhasesInfoCount > 0
		BEGIN
			SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
			FROM FolderInfo
			WHERE FolderInfo.FolderRSN = @intFolderRSN 
			AND FolderInfo.InfoCode = 10081
		END
		ELSE SELECT @intNumberofPhases = 0
		
		IF @intNumberofPhases > 1
		BEGIN
			SELECT @varemailSubject = 'CO Phasing for ZP# ' + @varZPNumber 
		
			SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)
				
			SELECT @varToAddress = ValidUser.EmailAddress, @varProjectManagerName = ValidUser.UserName
			FROM ValidUser
			WHERE ValidUser.UserID = (
					SELECT FolderProcess.SignOffUser
					FROM FolderProcess
					WHERE FolderProcess.FolderRSN = @intFolderRSN
					AND FolderProcess.ProcessCode = @intDecisionProcessCode )
			
			SELECT @varProjectManagerFirstName = SUBSTRING(@varProjectManagerName, 1, (CHARINDEX(' ', @varProjectManagerName + ' ') - 1))
		
			SELECT @varPropertyAddress = dbo.udf_GetPropertyAddressLongMixed(@intFolderRSN) 
			
			SELECT @varEmailGreeting = dbo.udf_GetTimeofDayGreetingText() 
		
			SELECT @varEmailBody = '<p>' + @varEmailGreeting + ', ' + @varProjectManagerFirstName + '.</p>
				   <p>Zoning Permit ' + @varZPNumber + ' at ' + @varPropertyAddress + ' has been Released.</p>
				   <p>Please complete the set up for Phased CO issuance by entering a description of each of the ' + 
				   RTRIM(CAST(@intNumberofPhases  AS CHAR(4)))+ ' phases. See <b>FolderRSN ' + 
				   RTRIM(CAST(@intFolderRSN AS CHAR(10))) + '</b>. TX - <i>Amanda</i></p>'
		
			INSERT INTO InternetApplications.dbo.EmailMessages 
				( ProfileName, ToAddress, CcAddress, BccAddress, EmailSubject, Body, Attachments, FolderGroupCode )
			VALUES 
				( 'NoReply', @varToAddress, NULL, NULL, @varemailSubject, @varEmailBody, NULL, 40 ) 		
		END
	END 
END
GO
