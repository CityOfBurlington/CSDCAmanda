USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateVBFolder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_CreateVBFolder](
@intPropertyRSN INT, 
@intOldFolderRSN INT, 
@FolderYear CHAR(2),
@FolderQuarter INT, 
@SubCode INT)
AS
BEGIN	

	/* DATE: 2/24/2009	Dana Baron  */
	/*                              */
	/* This stored procedure creates a new VB folder with all required elements including People, Info, */ 
	/* Process, and Fee. It is called from:                                                             */
	/*	  usp_CreateQuarterlyVBFolders - when rolling VB folders forward to a new fiscal quarter.       */
	/*    DefaultProcess_QC_00020018 - when a new VB folder is created from a QC Folder.                */

	DECLARE @intNextFolderRSN INT
	DECLARE @strPropertyAddress VARCHAR(200)
	DECLARE @strFolderDesc VARCHAR(100)
	DECLARE @strFolderQuarter VARCHAR(100)
	DECLARE @strReference VARCHAR(100)
	DECLARE @intFolderYear INT
	DECLARE @StatusCode INT
	DECLARE @PrimaryCodeOwnerRSN VARCHAR(20)
	DECLARE @NextProcessRSN INT
	DECLARE @NextDocumentRSN INT
	DECLARE @NextFeeRSN INT
	DECLARE @DocumentCode INT
	DECLARE @PeopleCode INT
	DECLARE @DisplayOrder INT
	DECLARE @VB_Fee FLOAT
	DECLARE @strUserID VARCHAR(8)
	DECLARE @FolderType VARCHAR(4)

	/* Lookup userID of Vacant Buildings Administrator */
	SELECT @strUserID = LookupString FROM ValidLookup WHERE LookupCode = 25000 AND Lookup1 = 1
	
	SET @strReference = 'Qtr ' + CAST(@FolderQuarter AS CHAR(1)) + ', 20' + @FolderYear
	SET @strFolderQuarter = 'Quarter ' + CAST(@FolderQuarter AS CHAR(1)) + ', FY20' + @FolderYear
	SET @strFolderDesc = @strFolderQuarter + ' Vacant Building'
	SELECT @strPropertyAddress = dbo.udf_GetPropertyAddress(@intPropertyRSN),
	@intNextFolderRSN  = dbo.udf_GetNextFolderRSN()

	/* If we're creating a new VB from an RB folder, set the StatusCode to VB Permit Pending (25010) */
	/* If we're rolling over existing VB Folders, then: */
	/* If StatusCode is VB Tracking (25005) or VB Investigation (25000), keep it. */
	/* Otherwise, change StatusCode to VB Permit Pending (25010) */
	SELECT @StatusCode = StatusCode, @FolderType = FolderType FROM Folder WHERE FolderRSN = @intOldFolderRSN
	IF (@FolderType = 'QC') OR (@FolderType = 'VB' AND @StatusCode >= 25010) BEGIN SET @StatusCode = 25010 END

	/* FOLDER: Create new VB Folder from prior quarter folder. */
	INSERT INTO Folder
	(FolderRSN, IssueUser, FolderCentury, FolderYear, SubCode, FolderSequence, FolderSection, FolderRevision,
	FolderType, StatusCode, PropertyRSN, Indate, FolderDescription, ReferenceFile, CopyFlag,  StampDate, StampUser, FolderName)
	SELECT @intNextFolderRSN, @strUserID, 20, @FolderYear, @SubCode, dbo.udf_GetNextFolderSeq(), '000', '00',
	'VB', @StatusCode, @intPropertyRSN, GETDATE(), @strFolderDesc, @strReference, 'DDDD',  GETDATE(), @strUserID, @strPropertyAddress

	/* PEOPLE: Copy ALL People From prior folder (Owner (2) is copied in automatically*/
	INSERT INTO FolderPeople
	(FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampDate, StampUser, PeopleRSNCrypt, GroupRSN, SecurityCode, Comments)
	SELECT @intNextFolderRSN, PeopleCode, PeopleRSN, PrintFlag, GetDate(), @strUserID, PeopleRSNCrypt, GroupRSN, SecurityCode, Comments
	FROM FolderPeople
	WHERE FolderRSN = @intOldFolderRSN AND PeopleCode <> 2

	/* INFO: Clean out any leftover folder info */
	DELETE FROM FolderInfo WHERE FolderRSN = @intNextFolderRSN

	/* INFO: Create Folder Quarter FolderInfo field with value for current quarter */
	INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired)
	SELECT @intNextFolderRSN, 25050, @strFolderQuarter, DisplayOrder, PrintFlag, getdate(), @strUserID, Mandatory, RequiredForInitialSetup 
	FROM DefaultInfo WHERE FolderType = 'VB' and InfoCode = 25050

	/* INFO: Copy some FolderInfo field values from prior folder */
	INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, InfoValueCrypt, InfoValueNumeric, DisplayOrder, PrintFlag, 
	StampDate, StampUser, InfoValueDateTime, Mandatory, ValueRequired, InfoValueUpper, SecurityCode, WebDisplayFlag)
	SELECT @intNextFolderRSN, InfoCode, InfoValue, InfoValueCrypt, InfoValueNumeric, DisplayOrder, PrintFlag, 
	GetDate(), StampUser, InfoValueDateTime, Mandatory, ValueRequired, InfoValueUpper, SecurityCode, WebDisplayFlag
	FROM FolderInfo 
	WHERE FolderRSN = @intOldFolderRSN
	AND InfoCode IN (20034,20035,20038,20039,20040,25040,25070)
	/* Info Codes: 20034 = VB Most Recent Use of Building
		20035 = VB Proposed Use of Building
		20038 = VB Date of Vacancy
		20039 = VB Expected Occupancy Date
		20040 = VB Plan for Building
		25040 = VB Declared Vacant Building Date
		25070 = VB Num of Tickets Last 12 Months
	*/

	/* INFO: Create some FolderInfo fields with empty values */
	INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired)
	SELECT @intNextFolderRSN, InfoCode, DisplayOrder, PrintFlag, getdate(), @strUserID, Mandatory, RequiredForInitialSetup 
	FROM DefaultInfo WHERE FolderType = 'VB' and InfoCode IN (20042,25090,25000,25010,25020,25030,25080,25100,25110)
	/* Info Codes: 
		20042 = VB Variances
		25000 = VB Application Recd Date
		25010 = VB Application Complete Date
		25020 = VB Fee Waiver Request
		25030 = VB Fee Waiver Reason
		25080 = VB No Longer Vacant Date
		25090 = VB Application Sent Date
		25100 = VB PWC Appeal
		25110 = VB PWC Appeal Decision
	*/

	/* PROCESS: FolderProcess entries for all default processes inserted automatically */

	/* FEE: Insert Vacant Building Fee (Fee Code = 202) if new status is VB Permit Pending */
	IF @StatusCode = 25010 /* VB Permit Pending */
	BEGIN
		SELECT @VB_Fee = ValidLookup.LookupFee FROM ValidLookup WHERE (ValidLookup.LookupCode = 16) AND (ValidLookUp.LookUp1 = 1)
		EXEC PC_FEE_INSERT @intNextFolderRSN, 202, @VB_Fee, @strUserID, 1, 'Vacant Building Fee', 1, 0

	END

	/* DOCUMENT: FolderDocument entries for all default documents inserted automatically */

END

GO
