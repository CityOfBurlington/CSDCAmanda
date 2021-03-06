USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreatePCSWFolder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_CreatePCSWFolder](
@intPropertyRSN INT, 
@intEPSCFolderRSN INT)
AS
BEGIN	

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure creates a PCSW Folder */

	DECLARE @intNextFolderRSN INT
	DECLARE @strPropertyAddress VARCHAR(200)
	DECLARE @FolderYear INT
	DECLARE @StatusCode INT
	--DECLARE @NextFeeRSN INT
	--DECLARE @DocumentCode INT
	--DECLARE @PeopleCode INT
	--DECLARE @DisplayOrder INT
	--DECLARE @VB_Fee FLOAT
	DECLARE @strUserID VARCHAR(8)
	DECLARE @InfoValue VARCHAR(4000)
	DECLARE @strMessage VARCHAR(100)


	SET @strUserID = user
	SET @FolderYear = CAST(RIGHT(STR(DATEPART(yyyy,getdate())),2) AS CHAR(2))	
	SET @StatusCode = 35000 /* C26 Initialized */

	SELECT @strPropertyAddress = dbo.udf_GetPropertyAddress(@intPropertyRSN),
	@intNextFolderRSN  = dbo.udf_GetNextFolderRSN()

	--SET @strMessage = CAST(@intNextFolderRSN AS VARCHAR(10))
	--RAISERROR(@strMessage, 16, -1)
	
	/* FOLDER: Create new PCSW Folder. */
	INSERT INTO Folder
	(FolderRSN, IssueUser, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
	FolderType, StatusCode, PropertyRSN, Indate, CopyFlag,  StampDate, StampUser, FolderName)
	SELECT @intNextFolderRSN, @strUserID, 20, @FolderYear, dbo.udf_GetNextFolderSeq(), '000', '00',
	'PCSW', @StatusCode, @intPropertyRSN, GETDATE(), 'DDDD',  GETDATE(), @strUserID, @strPropertyAddress

	/* PEOPLE: Copy ALL People From prior folder (Owner (2) is copied in automatically*/
	INSERT INTO FolderPeople
	(FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampDate, StampUser, PeopleRSNCrypt, GroupRSN, SecurityCode, Comments)
	SELECT @intNextFolderRSN, PeopleCode, PeopleRSN, PrintFlag, GetDate(), @strUserID, PeopleRSNCrypt, GroupRSN, SecurityCode, Comments
	FROM FolderPeople
	WHERE FolderRSN = @intEPSCFolderRSN AND PeopleCode <> 2

	/* INFO: Put EPSC FolderRSN in FolderInfo field 35640.                               */
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35640, @intEPSCFolderRSN, @strUserID

	/* INFO: 35010 = Existing Impervious                                                 */
	SELECT @InfoValue = InfoValue FROM FolderInfo WHERE FolderRSN = @intEPSCFolderRSN AND InfoCode = 35010
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35010, @InfoValue, @strUserID

	/* INFO: 35020 = Total Proposed Impervious                                           */
	SELECT @InfoValue = InfoValue FROM FolderInfo WHERE FolderRSN = @intEPSCFolderRSN AND InfoCode = 35020
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35020, @InfoValue, @strUserID

	/* INFO: 35040 = Redeveloped Impervious                                              */
	SELECT @InfoValue = InfoValue FROM FolderInfo WHERE FolderRSN = @intEPSCFolderRSN AND InfoCode = 35040
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35040, @InfoValue, @strUserID

	/* INFO: 35050 = Receiving Water System                                              */
	SELECT @InfoValue = InfoValue FROM FolderInfo WHERE FolderRSN = @intEPSCFolderRSN AND InfoCode = 35050
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35050, @InfoValue, @strUserID

	/* INFO: 35070 = Anticipated Construction Start Date                                 */
	SELECT dbo.FormatDateTime(InfoValueDateTime, 'MM/DD/YYYY') FROM FolderInfo WHERE FolderRSN = @intEPSCFolderRSN AND InfoCode = 35070
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35070, @InfoValue, @strUserID

	/* INFO: 35080 = Anticipated Construction End Date                                   */
	SELECT dbo.FormatDateTime(InfoValueDateTime, 'MM/DD/YYYY') FROM FolderInfo WHERE FolderRSN = @intEPSCFolderRSN AND InfoCode = 35080
	EXEC TK_FOLDERINFO_UPDATE @intNextFolderRSN, 35080, @InfoValue, @strUserID

	/* FEE: Insert Vacant Building Fee (Fee Code = 202) if new status is VB Permit Pending */

	/* DOCUMENT: FolderDocument entries for all default documents inserted automatically */

END

GO
