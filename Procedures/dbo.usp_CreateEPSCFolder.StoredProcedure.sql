USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateEPSCFolder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CreateEPSCFolder](
@intPropertyRSN INT, 
@intOldFolderRSN INT, 
@FolderYear CHAR(2))
AS
BEGIN	

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure creates a new EPSC folder using mostly default values  */
	/* Creation of EPSC folders is triggered when a zoning folder has an info field */
	/* "Erosion Control Plan Required" (10077) answered as "Yes"                    */

	DECLARE @intNextFolderRSN INT
	DECLARE @strPropertyAddress VARCHAR(200)
	DECLARE @strFolderDesc VARCHAR(100)
	DECLARE @strReference VARCHAR(100)
	DECLARE @intFolderYear INT
	DECLARE @StatusCode INT
	DECLARE @PrimaryCodeOwnerRSN VARCHAR(20)
	DECLARE @NextProcessRSN INT
	DECLARE @NextDocumentRSN INT
	DECLARE @PeopleCode INT
	DECLARE @DisplayOrder INT
	DECLARE @strUserID VARCHAR(8)

	/* Get the User Id to use for the process and attempt result (currently mmoir) */
	SELECT @strUserID = LookupString FROM ValidLookup WHERE LookupCode = 35000

	SET @strFolderDesc = 'Erosion Control'
	SELECT @strPropertyAddress = dbo.udf_GetPropertyAddress(@intPropertyRSN),
	@intNextFolderRSN  = dbo.udf_GetNextFolderRSN()

	/* Set StatusCode to C26 Initialized (35000) */
	SET @StatusCode = 35000 

	/* FOLDER: Create new EPSC Folder. */
	INSERT INTO Folder
	(FolderRSN, IssueUser, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
	FolderType, StatusCode, PropertyRSN, Indate, FolderDescription, ReferenceFile, CopyFlag,  StampDate, StampUser, FolderName)
	SELECT @intNextFolderRSN, @strUserID, 20, @FolderYear, dbo.udf_GetNextFolderSeq(), '000', '00',
	'EPSC', @StatusCode, @intPropertyRSN, GETDATE(), @strFolderDesc, @strReference, 'DDDD',  GETDATE(), @strUserID, @strPropertyAddress

	/* PEOPLE: Copy ALL People From prior folder (Owner (2) is copied in automatically*/
	--INSERT INTO FolderPeople
	--(FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampDate, StampUser, PeopleRSNCrypt, GroupRSN, SecurityCode, Comments)
	--SELECT @intNextFolderRSN, PeopleCode, PeopleRSN, PrintFlag, GetDate(), @strUserID, PeopleRSNCrypt, GroupRSN, SecurityCode, Comments
	--FROM FolderPeople
	--WHERE FolderRSN = @intOldFolderRSN AND PeopleCode <> 2

	/* INFO: Create some FolderInfo fields with empty values */
	INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired)
	SELECT @intNextFolderRSN, InfoCode, DisplayOrder, PrintFlag, getdate(), @strUserID, Mandatory, RequiredForInitialSetup 
	FROM DefaultInfo WHERE FolderType = 'EPSC' and InfoCode IN (35000, 35010, 35020, 35030, 35040, 35050, 35060, 35070, 35080, 35120, 35130, 35170, 35180, 35190, 35200, 35210, 35220, 35230, 35240, 35250, 35260, 35270, 35280)
	/* Info Codes: 
		35000	Area of Disturbance
		35010	Existing Impervious Surface
		35020	Total Proposed Impervious
		35030	Net New Impervious Surface
		35040	Redeveloped Impervious
		35050	Receiving Water System
		35060	Site Concerns
		35070	Anticipated Construction Start
		35080	Anticipated Construction End
		35120	Construction Start Notification
		35130	Construction Start
		35170	Final Stabilization Inspection
		35180	One-year Stabilization Inspection
		35190	Additional Info Required?
		35200	Site Visit Required?
		35210	SW Tech Assist Meeting Required?
		35220	Pre-construction Meeting Required?
		35230	Installation Measures Required?
		35240	General Inspection Required?
		35250	Winter Stabilization Inspection Required?
		35260	PCSW Required?
		35270	Winter Construction?
		35280	Neighborhood Runoff Issues?	*/

	/* PROCESS: FolderProcess entries for all default processes inserted automatically */

	/* DOCUMENT: FolderDocument entries for all default documents inserted automatically */

END

GO
