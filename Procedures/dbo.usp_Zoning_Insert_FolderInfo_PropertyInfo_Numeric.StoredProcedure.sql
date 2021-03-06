USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_FolderInfo_PropertyInfo_Numeric]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_FolderInfo_PropertyInfo_Numeric] (@intFolderRSN int, @intFolderInfoCode int, @intPropertyInfoCode int, @varUserID varchar(20))
AS
BEGIN 
	/* Used to insert or update FolderInfo fields with PropertyInfo data. 
	   Called at Folder initialization as of 7/2011. 
	   Inserts PropertyInfo data into FolderInfo where the PropertyInfo field exists 
	   with data and the FolderInfo field does not exist. If the subject FolderInfo 
	   field exists, update it. JA 7/2011 */

	DECLARE @intPropertyInfoCount int
	DECLARE @intFolderInfoCount int
	DECLARE @intFolderInfoDisplayOrder int
	DECLARE @fltPropInfoValue float

	SELECT @intPropertyInfoCount = COUNT(*)
	  FROM PropertyInfo, Folder
	 WHERE PropertyInfo.PropertyInfoCode = @intPropertyInfoCode 
	   AND PropertyInfo.PropertyRSN = Folder.PropertyRSN
	   AND Folder.FolderRSN = @intFolderRSN

	SELECT @intFolderInfoCount = COUNT(*) 
	  FROM FolderInfo 
	 WHERE FolderInfo.FolderRSN = @intFolderRSN 
	   AND FolderInfo.InfoCode = @intFolderInfoCode 

	IF @intPropertyInfoCount > 0
	BEGIN 
		IF @intFolderInfoCount = 0
		BEGIN 
			SELECT @intFolderInfoDisplayOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10033)

			INSERT INTO FolderInfo
				(FolderInfo.FolderRSN, FolderInfo.InfoCode, FolderInfo.DisplayOrder, 
				 FolderInfo.InfoValue, FolderInfo.InfoValueNumeric, 
				 FolderInfo.PrintFlag, FolderInfo.Mandatory, FolderInfo.ValueRequired, 
		 		 FolderInfo.StampDate,  FolderInfo.StampUser)
			SELECT @intFolderRSN, @intFolderInfoCode, @intFolderInfoDisplayOrder, 
				   PropertyInfo.PropInfoValue, PropertyInfo.PropertyInfoValueNumeric,  
				   'Y', 'N', 'N', getdate(), @varUserID
			  FROM Folder, PropertyInfo
			 WHERE Folder.FolderRSN = @intFolderRSN
			   AND Folder.PropertyRSN = PropertyInfo.PropertyRSN
			   AND PropertyInfo.PropertyInfoCode = @intPropertyInfoCode
			   AND PropertyInfo.PropInfoValue IS NOT NULL
		END 
		ELSE 
		BEGIN 
			SELECT @fltPropInfoValue = PropertyInfo.PropertyInfoValueNumeric 
			  FROM Folder, PropertyInfo
			 WHERE Folder.FolderRSN = @intFolderRSN
			   AND Folder.PropertyRSN = PropertyInfo.PropertyRSN
			   AND PropertyInfo.PropertyInfoCode = @intPropertyInfoCode

			UPDATE FolderInfo 
			   SET FolderInfo.InfoValue = @fltPropInfoValue, 
				   FolderInfo.InfoValueNumeric = @fltPropInfoValue  
			 WHERE FolderInfo.FolderRSN = @intFolderRSN 
			   AND FolderInfo.InfoCode = @intFolderInfoCode
		END
	END
END


GO
