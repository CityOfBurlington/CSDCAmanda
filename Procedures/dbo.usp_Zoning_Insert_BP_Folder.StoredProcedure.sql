USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_BP_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_BP_Folder] (@intZoningFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
	/* Inserts a BP folder when a zoning permit is picked up. Called by Info 
	   Validation or ZN Non-Applicability Request for the zoning folder.  
	   BP folder status at auto-initialization is Application Pending (30021). 
	   Auto-created BP Folder.ReferenceFile2 is populated with the zoning folder's 
	   permit number (Folder.ReferenceFile). This tags auto-initialized BP folders, 
	   and serves as a check against duplicate initialization.  JA 12/2010 */

	DECLARE @varBuildingPermitFlag varchar(15)
	DECLARE @intPrimaryPropertyRSN int
	DECLARE @varPermitNumber varchar(15) 
	DECLARE @varZoningDescription varchar(500)
	DECLARE @intZoningPropertyCount int 
	DECLARE @intZoningPropertyRSN int
	DECLARE @intBPFolderCount int
	DECLARE @varProjectNumber varchar(15) 
	DECLARE @varPropertyAddressShort varchar(100)
	DECLARE @varPropertyAddressLong varchar(100)
	DECLARE @intNextFolderRSN int
	DECLARE @varFolderSequence varchar(10)
	DECLARE @varInfo10019ProjectUse varchar(50)
	DECLARE @varInfo10021ProjectType varchar(50)
	DECLARE @varInfo10024ExpiryDate varchar(20)
	DECLARE @intRecCounter int
	DECLARE @intRowNumber int 
	DECLARE @varCommentText varchar(1000)

	SELECT @varBuildingPermitFlag = dbo.udf_ZoningBuildingPermitFlag(@intZoningFolderRSN) 

	SELECT @intPrimaryPropertyRSN = Folder.PropertyRSN, 
		   @varPermitNumber = Folder.ReferenceFile, 
		   @varZoningDescription = Folder.FolderDescription 
	FROM Folder 
	WHERE Folder.FolderRSN = @intZoningFolderRSN 
	
	SELECT @intZoningPropertyCount = COUNT(*)
	FROM FolderProperty
	WHERE FolderProperty.FolderRSN = @intZoningFolderRSN

	SELECT @intBPFolderCount = COUNT(*) 
	FROM Folder 
	WHERE Folder.ParentRSN = @intZoningFolderRSN 
	AND Folder.ReferenceFile2 = @varPermitNumber 
	AND Folder.FolderType = 'BP' 

	IF ( UPPER(@varBuildingPermitFlag) = 'YES' AND @intBPFolderCount = 0 )
	BEGIN
		SELECT @varProjectNumber = dbo.udf_GetProjectNumberYearSequence(@intZoningFolderRSN)

		SELECT @varPropertyAddressShort = dbo.udf_GetPropertyAddressShort(@intPrimaryPropertyRSN)
		SELECT @varPropertyAddressLong =  dbo.udf_GetPropertyAddress(@intPrimaryPropertyRSN)
   
		SELECT @intNextFolderRSN = ( MAX(Folder.FolderRSN) + 1 ), 
			   @varFolderSequence = dbo.udf_GetNextFolderSeq() 
		FROM Folder 

		INSERT INTO Folder 
			( FolderRSN, FolderType, ReferenceFile, ReferenceFile2, 
			  FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision, 
			  StatusCode, PropertyRSN, ParentRSN, InDate, FolderName, 
			  CopyFlag, StampDate, StampUser )
		VALUES ( @intNextFolderRSN, 'BP', @varProjectNumber, @varPermitNumber, 
				 SUBSTRING(CAST(YEAR(getdate()) AS VARCHAR), 1, 2), 
				 SUBSTRING(CAST(YEAR(getdate()) AS VARCHAR), 3, 2), 
				 @varFolderSequence, '000', '00', 
				 30021, @intPrimaryPropertyRSN, @intZoningFolderRSN, getdate(), @varPropertyAddressLong, 
				 'DDDDD', getdate(), @varUserID ) 

		/* Insert other property records into FolderProperty from zoning folder */

		IF @intZoningPropertyCount > 1
		BEGIN
			INSERT INTO FolderProperty (FolderRSN, PropertyRSN, StampDate, StampUser)
			SELECT @intNextFolderRSN, FolderProperty.PropertyRSN, GETDATE(), @varUserID 
			FROM FolderProperty
			WHERE FolderProperty.FolderRSN = @intZoningFolderRSN
			AND FolderProperty.PropertyRSN <> @intPrimaryPropertyRSN 
		END

		/* Create permit summary in FolderComment - Not wanted per Ned Holt 12/27/2010
   
		SELECT @varInfo10019ProjectUse = FolderInfo.InfoValue
		FROM FolderInfo 
		WHERE FolderInfo.FolderRSN = @intZoningFolderRSN 
		AND FolderInfo.InfoCode = 10019

		SELECT @varInfo10021ProjectType = FolderInfo.InfoValue
		FROM FolderInfo 
		WHERE FolderInfo.FolderRSN = @intZoningFolderRSN 
		AND FolderInfo.InfoCode = 10021

		SELECT @varInfo10024ExpiryDate = CONVERT(CHAR(11), FolderInfo.InfoValueDateTime) 
		FROM FolderInfo 
		WHERE FolderInfo.FolderRSN = @intZoningFolderRSN 
		AND FolderInfo.InfoCode = 10024

		SELECT @varCommentText = 
		'Zoning Permit Summary' + CHAR(13) + CHAR(10) + 
		'=====================' + CHAR(13) + CHAR(10) + 
		'Address: ' + @varPropertyAddressLong + CHAR(13) + CHAR(10) + 
		'Project Use: ' + @varInfo10019ProjectUse + CHAR(13) + CHAR(10) + 
		'Project Type: ' + @varInfo10021ProjectType + CHAR(13) + CHAR(10) + 
		'Permit Released: ' + CONVERT(CHAR(11), getdate()) + CHAR(13) + CHAR(10) + 
		'Permit Expires: ' + @varInfo10024ExpiryDate + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
		'Description: ' + @varZoningDescription 
                            
		INSERT INTO FolderComment 
			( FolderRSN, CommentDate, CommentUser, IncludeonToDo, 
			  Comments, StampDate, StampUser )
		VALUES ( @intNextFolderRSN, getdate(), NULL, 'N', 
				 @varCommentText,   getdate(), @varUserID ) */
	END
END

GO
