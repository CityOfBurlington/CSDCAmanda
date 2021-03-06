USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyImperviousSurfaceUpdate]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_PropertyImperviousSurfaceUpdate] (@intFolderRSN int)
AS
BEGIN 
	/* Calculates property impervious surface sq ft from zoning permit folder coverage (Info Field) */

	DECLARE @varFolderType varchar(4)
	DECLARE @dtIssueDate datetime
	DECLARE @intPropertyRSN int
	DECLARE @intLandPropertyRSN int
	DECLARE @intPropertyType int
	DECLARE @fltFolderLotSize float
	DECLARE @fltPropertyLotSize float
	DECLARE @fltPermitCoverage float
	DECLARE @fltLotSize float
	DECLARE @fltImpSurface float

	SELECT @varFolderType = Folder.FolderType, @dtIssueDate = Folder.IssueDate
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	IF ( @varFolderType IN('Z1', 'Z2', 'Z3', 'ZB', 'ZC') AND @dtIssueDate > '3/31/2004' ) 
	BEGIN 
		SELECT @intPropertyRSN = Folder.PropertyRSN
		FROM Folder 
		WHERE Folder.FolderRSN = @intFolderRSN
		
		SELECT @intLandPropertyRSN = dbo.udf_GetPropertyLandRSN(@intPropertyRSN)

		SELECT @fltPropertyLotSize = Property.PropArea, 
			   @intPropertyType = Property.PropCode
		FROM Property
		WHERE Property.PropertyRSN = @intLandPropertyRSN

		IF @intPropertyType IN (10, 11, 12, 13, 14, 15, 22)
		BEGIN 
			SELECT @fltFolderLotSize = ISNULL(FolderInfo.InfoValueNumeric, 0)
			FROM FolderInfo
			WHERE FolderInfo.InfoCode = 10047
			AND FolderInfo.FolderRSN = @intFolderRSN
      
			SELECT @fltPermitCoverage = ISNULL(FolderInfo.InfoValueNumeric, 0)
			FROM FolderInfo
			WHERE FolderInfo.InfoCode = 10006
			AND FolderInfo.FolderRSN = @intFolderRSN
 
			IF @fltFolderLotSize = 0 SELECT @fltLotSize = @fltPropertyLotSize
			ELSE SELECT @fltLotSize = @fltFolderLotSize 

			IF @fltPermitCoverage > 0 
			BEGIN
				SELECT @fltImpSurface = @fltLotSize * ( @fltPermitCoverage * 0.01 )

				UPDATE Property
				SET Property.PropDepth = CAST(ROUND(@fltImpSurface, 0) AS INT)
				WHERE Property.PropertyRSN = @intLandPropertyRSN
			END
		END
	END
END

GO
