USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspScheduleCodeEnforcementInspection]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[xspScheduleCodeEnforcementInspection](@FolderRSN INT, @ProcessRSN INT, @AttemptRSN INT, @InspectionCount INT)
AS
BEGIN
/*
	This procedure gathers the data necessary to create an Outlook calendar entry for an inspection related to a QC folder. 
	It then calls stored procedure xspSendEmailAppointment to handle the actual scheduling.

	Called From: DefaultProcess_MH_00020028, DefaultProcess_MH_00020030, DefaultProcess_MH_00020034, 
				 DefaultProcess_MH_00020037 and DefaultProcess_MH_00020028

	DatabaseEnum Values
		10 = Amanda_Development
		20 = Amanda_Production

*/
DECLARE @intReturnVal INT

DECLARE @strFolderType CHAR(2)
DECLARE @strPermitNo VARCHAR(20)
DECLARE @strDate VARCHAR(10)
DECLARE @strTime VARCHAR(8)
DECLARE @dtmScheduleDate DATETIME
DECLARE @dtmScheduleEndDate DATETIME
DECLARE @strEmailFromAddress VARCHAR(30)
DECLARE @strEmailFromDisplay VARCHAR(30)
DECLARE @strEmailTo Varchar(400)
DECLARE @strSubject VARCHAR(100)
DECLARE @strBody VARCHAR(4000)
DECLARE @strFolderName VARCHAR(200)
DECLARE @strScheduleDate NVARCHAR(20)
DECLARE @strScheduleEndDate NVARCHAR(20)
DECLARE @RentalUnits INT
DECLARE @intScheduleMinutes INT
DECLARE @PropertyRSN INT
DECLARE @YearBuilt AS VARCHAR(4)

SELECT @strFolderType = Folder.FolderType, 
	   @strPermitNo = Folder.FolderYear + '-' + Folder.FolderSequence, 
       @strEmailTo = ValidUser.EmailAddress,
       @dtmScheduleDate = FolderProcess.ScheduleDate,
       @strFolderName = Folder.FolderName,
       @strSubject = CAST(Folder.FolderRSN AS VARCHAR(20)),
	   @PropertyRSN = Folder.PropertyRSN
FROM Folder 
	 INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
	 INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
	 INNER JOIN ValidUser ON FolderProcessAttempt.AttemptBy = ValidUser.UserId
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	  AND FolderProcessAttempt.AttemptRSN = @AttemptRSN

SET @RentalUnits = CAST(dbo.f_info_numeric_property(@PropertyRSN, 15) AS INT)
SET @YearBuilt = ISNULL(dbo.f_info_alpha_property(@PropertyRSN, 60), '')


--SET @strEmailTo = 'dbaron@ci.burlington.vt.us'

	/* Gather information to create the calendar entry */
    SET @strEmailFromAddress = 'amanda@ci.burlington.vt.us'
    SET @strEmailFromDisplay = @strFolderType + ' Scheduler'
	-- strEmailTo is set in the Select statement above
	SELECT @strSubject = @strFolderType + ' - ' + @strFolderName + ' - FolderRSN ' + @strSubject

	/* Build the body of the e-mail to accompany the calendar entry */
    SELECT @strBody = 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20)) 
    + '   ' + 'Permit No: ' + @strPermitNo
    + '   ' + 'Location: ' + @strFolderName
    + '   ' + 'Year Built: ' + @YearBuilt
    + '   ' + 'Num Units: ' + CAST(@RentalUnits AS VARCHAR(3))
    + '   ' + 'Owner: ' + ISNULL(dbo.udf_GetFirstPeopleName(2, @FolderRSN),' ')
    + '   ' + 'Owner Phone: ' + ISNULL(dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(2, @FolderRSN)),' ')
    + '   ' + 'Owner Email: ' + ISNULL(dbo.udf_GetFirstPeopleEmail(2, @FolderRSN),' ')
    + '   ' + 'Property Mgr: ' + ISNULL(dbo.udf_GetFirstPeopleName(75, @FolderRSN),' ')
    + '   ' + 'Mgr Phone: ' + ISNULL(dbo.udf_FormatPhoneNumber(dbo.udf_GetFirstPeoplePhone1(75, @FolderRSN)),' ')
    + '   ' + 'Mgr Email: ' + ISNULL(dbo.udf_GetFirstPeopleEmail(75, @FolderRSN),' ')

	-- strFolderName is set in the main Select statement

	/* Set schedule start and end date/time and convert to string format:

		Schedule start date and time come from the AMANDA Process 
		Schedule end date and time depend on folder type, number of units to inspect, and number of prior inspections

		For VB Folders:
		Vacant Building inspections are always 1 hour, so number of minutes is set to 60.

		For MH Folders:
		Schedule end date and time are calculated by finding the number of 15 minute intervals for the inspection based on 
		number of units and what the inspection stage is (initial, 1st follow-up, etc). The number of intervals is found in
		a lookup table, then muliplied by 15 to arrive at the number of minutes to add to the scheduled start time. 

		Number of Units comes from PropertyInfo where InfoCode = 15
		Inspection Count is passed in from the calling routine and is based on the ProcessCode:
		ProcessCode = 20028 (Initial Contact) -> InspectionCount = 1
		ProcessCode = 20030 (Code Initial Inspection) -> InspectionCount = 2
		ProcessCode = 20034	(1st Followup Inspection) -> InspectionCount = 3 
		ProcessCode = 20037 (2nd Followup Inspection) -> InspectionCount = 3
		ProcessCode = 20040 (3rd Followup Inspection) -> InspectionCount = 3 

		For other folder types:
		Number of units is assumed to be 1. Inspection count is determined as for MH folders.
	*/

	SET @strScheduleDate = dbo.FormatDateTime(@dtmScheduleDate, 'MM/DD/YYYY HH:MM 12')

	IF @strFolderType = 'MH'
		BEGIN
			/* MH Folders: find number of rental units, then use formula in GetInspectionTime function to convert to minutes */
			SET @intScheduleMinutes = 15 * dbo.udf_GetInspectionTime(@RentalUnits, @InspectionCount)
		END
	ELSE IF @strFolderType = 'VB'
		BEGIN
			/* VB Folders: Vacant Building inspections are always 1 hour. */
			SET @intScheduleMinutes = 60
		END
	ELSE
		BEGIN
			/* Other Folder Types assume one rental unit and convert to time using GetInspectionTime function */
			SET @RentalUnits = 1
			SET @intScheduleMinutes = 15 * dbo.udf_GetInspectionTime(@RentalUnits, @InspectionCount)
		END

    SET @dtmScheduleEndDate = DATEADD(n, @intScheduleMinutes, @dtmScheduleDate)
    SET @strScheduleEndDate = dbo.FormatDateTime(@dtmScheduleEndDate, 'MM/DD/YYYY HH:MM 12')

/*
	SET @strDate = CONVERT(varchar(10), @dtmScheduleEndDate, 101)
	Set @strTime = CONVERT(varchar(8), @dtmScheduleEndDate, 108)
	SET @strScheduleEndDate = @strDate + ' ' + @strTime
*/

/* For debugging
SELECT 'From Address = ', @strEmailFromAddress,
	'From Display = ', @strEmailFromDisplay, 
	'Email To = ', @strEmailTo, 
	'Subject = ', @strSubject, 
	'Body = ', @strBody, 
	'Folder Name = ', @strFolderName, 
	'Schedule start = ', @strScheduleDate, 
	'Schedule end = ', @strScheduleEndDate
*/

	EXEC xspSendEmailAppointment @strEmailFromAddress, @strEmailFromDisplay, @strEmailTo, @strSubject, @strBody, 
	@strFolderName, @strScheduleDate, @strScheduleEndDate

END


GO
