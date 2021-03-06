USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha] (@intFolderRSN int, @intFolderInfoCode int, @intPropertyInfoCode int, @varUserID varchar(20))
AS
BEGIN 
	/* Used to insert FolderInfo fields with PropertyInfo data. 
	   Called at Folder initialization as of 7/2011. 
	   Inserts PropertyInfo data into FolderInfo where the PropertyInfo field exists 
	   with data and the FolderInfo field does not exist. At initialization the 
	   subject FolderInfo field should not exist, but if it does, update it. JA 7/2011 */

	DECLARE @intPropertyInfoCount int
	DECLARE @intFolderInfoCount int
	DECLARE @intFolderInfoDisplayOrder int
	DECLARE @varPropInfoValue varchar(50)

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
				 FolderInfo.InfoValue, FolderInfo.InfoValueUpper, 
				 FolderInfo.PrintFlag, FolderInfo.Mandatory, FolderInfo.ValueRequired, 
		 		 FolderInfo.StampDate,  FolderInfo.StampUser)
			SELECT @intFolderRSN, @intFolderInfoCode, @intFolderInfoDisplayOrder, 
				   PropertyInfo.PropInfoValue, PropertyInfo.InfoValueUpper,  
				   'Y', 'N', 'N', getdate(), @varUserID
			  FROM Folder, PropertyInfo
			 WHERE Folder.FolderRSN = @intFolderRSN
			   AND Folder.PropertyRSN = PropertyInfo.PropertyRSN
			   AND PropertyInfo.PropertyInfoCode = @intPropertyInfoCode
			   AND PropertyInfo.PropInfoValue IS NOT NULL
		END 
		ELSE 
		BEGIN 
			SELECT @varPropInfoValue = PropertyInfo.PropInfoValue 
			  FROM Folder, PropertyInfo
			 WHERE Folder.FolderRSN = @intFolderRSN
			   AND Folder.PropertyRSN = PropertyInfo.PropertyRSN
			   AND PropertyInfo.PropertyInfoCode = @intPropertyInfoCode

			UPDATE FolderInfo 
			   SET FolderInfo.InfoValue = @varPropInfoValue, 
				   FolderInfo.InfoValueUpper = UPPER(@varPropInfoValue) 
			 WHERE FolderInfo.FolderRSN = @intFolderRSN 
			   AND FolderInfo.InfoCode = @intFolderInfoCode
		END
	END
END


GO
