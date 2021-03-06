USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Notification_Permit_Ready_to_Release]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Notification_Permit_Ready_to_Release] (@intFolderRSN int)
AS 
BEGIN 	
	/* Generates and sends an email to owner and applicants whose permits are ready to pick up. */
	
	DECLARE @varEmailAddressOwner varchar(100)
	DECLARE @varEmailAddressApplicant varchar(100)
	DECLARE @varZPNumber varchar(20) 
	DECLARE @dtIssueDate datetime 
	DECLARE @intDaysSinceAppealEnded int
	DECLARE @varPropertyAddress varchar(100)
	DECLARE @varApplicationDecision varchar(40) 
	DECLARE @varProjectDescription varchar(1000) 
	declare @varPermitTypeText varchar(80)
	DECLARE @varProjectManagerName varchar(100)
	DECLARE @varProjectManagerEmailAddress varchar(100)
	DECLARE @intAppealPeriodDays int
	DECLARE @varReadytoPickUpText varchar(500)
	DECLARE @varPreReleaseConditionsFlag varchar(2) 
	DECLARE @varPreReleaseConditionsText varchar(500)
	DECLARE @moneyDevelopmentReviewFeeDue money
	DECLARE @varDevelopmentReviewFeeText varchar(200) 
	DECLARE @varEmailSubject varchar(400) 
	DECLARE @varEmailBody varchar(8000) 

	SELECT @varEmailAddressOwner = dbo.f_info_alpha_null (@intFolderRSN, 10130)
	SELECT @varEmailAddressApplicant = dbo.f_info_alpha_null (@intFolderRSN, 10131)
	
	SELECT @varZPNumber = Folder.ReferenceFile, 
		@dtIssueDate = Folder.IssueDate, 
		@intDaysSinceAppealEnded = DATEDIFF(DAY, Folder.ExpiryDate, GETDATE()), 
		@varProjectDescription = Folder.FolderDescription 
	FROM Folder 
	WHERE Folder.FolderRSN = @intFolderRSN 
	
	SELECT @varPermitTypeText = dbo.udf_GetZoningPermitTypeText(@intFolderRSN) 
	
	SELECT @varPropertyAddress = dbo.udf_GetPropertyAddressLongMixed(@intFolderRSN) 
	
	SELECT @varApplicationDecision = dbo.udf_GetZoningPermitDecision(@intFolderRSN) 
	
	SELECT @intAppealPeriodDays = dbo.udf_GetZoningPermitAppealPeriodDays(@intFolderRSN) 
	
	SELECT @varProjectManagerName = dbo.udf_GetZoningProjectManagerName(@intFolderRSN)
	
	SELECT @varProjectManagerEmailAddress = dbo.udf_GetZoningProjectManagerEmailAddress(@intFolderRSN) 
		
	IF @intDaysSinceAppealEnded > 1
	BEGIN
		SELECT @varReadytoPickUpText = '<p>The permit has been ready for you to pick up at the Planning and Zoning office 
			in City Hall for ' + RTRIM(CAST(@intDaysSinceAppealEnded AS CHAR)) + 
			' days. This is a reminder to pick it up, which is a required step in the permitting process.'
		SELECT @varemailSubject = 'Reminder: Zoning Permit # ' + @varZPNumber + ' Ready to Pick Up' 
	END
	ELSE 
	BEGIN 
		SELECT @varReadytoPickUpText = '<p>The permit is <u>now ready for you to pick up</u> at the Planning and Zoning office in City Hall.'
		SELECT @varemailSubject = 'Zoning Permit # ' + @varZPNumber + ' Ready to Pick Up' 
	END

	/* Below returns Y if PreRelease Conditions are applicable, have not been met, and if the PRC process status is Open. */
	
	SELECT @varPreReleaseConditionsFlag = dbo.udf_ZoningPreReleaseConditionsFlag(@intFolderRSN) 
	
	IF @varPreReleaseConditionsFlag = 'Y' 
		SELECT @varPreReleaseConditionsText = '<p>Your zoning permit has Pre-Release Conditions, meaning that certain 
		permit requirements must be met before the office can release your permit. For more information, please email 
		the Project Manager, ' + @varProjectManagerName + ', at ' + @varProjectManagerEmailAddress + '.</p>'
	ELSE SELECT @varPreReleaseConditionsText = ''
	
	SELECT @moneyDevelopmentReviewFeeDue = dbo.udf_GetZoningFeesDevelopmentReviewDue(@intFolderRSN) 
	
	IF @moneyDevelopmentReviewFeeDue > 0 
		SELECT @varDevelopmentReviewFeeText = 'A Development Review fee of $' + RTRIM(CAST(@moneyDevelopmentReviewFeeDue AS VARCHAR)) + 
		' is due at this time.'
	ELSE SELECT @varDevelopmentReviewFeeText = ''
	
	/* Assemble email body text. */
	
	SELECT @varEmailBody = '<p>This is an electronically-generated notification from the Burlington Department of Planning and Zoning.</p>
		<p>Your zoning permit application for a ' + @varPermitTypeText + ' at ' + @varPropertyAddress + ' was ' + 
		@varApplicationDecision + ' on ' + CONVERT(CHAR(11), @dtIssueDate) + ', and has completed its State-required ' +  
		RTRIM(CAST(@intAppealPeriodDays AS CHAR)) + '-day appeal period.</p> 
		<p>Project Description: <i>' + @varProjectDescription + '</i></p>' + 
		@varReadytoPickUpText + ' The office is open Monday - Friday from 8 am to 4 pm.</p>' + 
		@varPreReleaseConditionsText + 
		'<p>You will need to sign for your permit and review the Conditions of Approval when you pick it up. ' + 
		@varDevelopmentReviewFeeText + '</p> 
		<p>Finally, you will receive paperwork necessary to complete the remaining steps in Burlington&#039;s permitting process. 
		These include, but are not limited to:</p>
		<ul>
		<li>Obtaining a Building Permit and other applicable construction permits (electrical, plumbing, mechanical, etc), and 
		<li>Closing out the zoning permit after the project is completed by obtaining the Unified Certificate of Occupancy.
		</ul>
		<p>Thank you for your prompt attention to this matter. We appreciate it.</p>
		<p>Burlington Department of Planning and Zoning<br>149 Church Street<br>Burlington, VT 05401<br>802-865-7188<br>
		<a href="http://www.burlingtonvt.gov/pz">http://www.burlingtonvt.gov/pz</a></p>
		<p><small><i>Note: This is an electronically generated email. Please do not reply to this email as the From: email address 
		is not for a human.</i></small></p>' 	
		
	/* Send the email */ 
	
	IF CHARINDEX('@', @varEmailAddressOwner) > 1
	BEGIN 
		INSERT INTO InternetApplications.dbo.EmailMessages 
			( ProfileName, ToAddress, CcAddress, BccAddress, EmailSubject, Body, Attachments, FolderGroupCode )
		VALUES( 'NoReply', @varEmailAddressOwner, NULL, 'nanderson@burlingtonvt.gov', @varEmailSubject, @varEmailBody, NULL, 2 ) 
	END

	IF CHARINDEX('@', @varEmailAddressApplicant) > 1
	BEGIN
		INSERT INTO InternetApplications.dbo.EmailMessages 
			( ProfileName, ToAddress, CcAddress, BccAddress, EmailSubject, Body, Attachments, FolderGroupCode )
		VALUES( 'NoReply', @varEmailAddressApplicant, NULL, 'nanderson@burlingtonvt.gov', @varEmailSubject, @varEmailBody, NULL, 2 )
	END
END


GO
