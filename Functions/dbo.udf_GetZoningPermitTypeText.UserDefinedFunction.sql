USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitTypeText]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitTypeText](@intFolderRSN int) 
RETURNS VARCHAR(80)
AS
BEGIN
	/* Used for email notifications  JA 8/2013 */
   
	DECLARE @varPermitTypeText varchar(80)
	DECLARE @varFolderType varchar(6)
	DECLARE @intWorkCode int
	DECLARE @varLevel3Type varchar(30)

	SET @varPermitTypeText = 'Unknown Permit Type'

	SELECT @varFolderType = Folder.Foldertype, @intWorkCode = Folder.WorkCode
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	IF @varFolderType IN ('ZA', 'ZH', 'ZL', 'ZP')
	BEGIN
	SELECT @varPermitTypeText = 
		CASE @intWorkCode
			WHEN 10000 THEN 'Conditional Use'
			WHEN 10001 THEN 'Home Occupation'
			WHEN 10002 THEN 'Conditoional Use'
			WHEN 10003 THEN 'Variance'
			WHEN 10004 THEN 'Appeal of Enforcement Decision'
			WHEN 10005 THEN 'Appeal of Zoning Decision'
			WHEN 10006 THEN 'Master Parking Plan'
			WHEN 10007 THEN 'Master Sign Plan'
			WHEN 10008 THEN 'Master Tree Maintenance Plan'
			WHEN 10035 THEN 'Sign(s)'
			WHEN 10036 THEN 'Awning(s)'
			WHEN 10037 THEN 'Awning(s)'
			ELSE 'Unknown ' + @varFolderType + ' WorkCode'
		END
	END
	ELSE
	BEGIN
		IF @varFolderType = 'Z3'
		BEGIN
			SELECT @varLevel3Type = ISNULL(FolderInfo.InfoValue, '')
			FROM FolderInfo
			WHERE FolderInfo.FolderRSN = @intFolderRSN
			AND FolderInfo.InfoCode = 10015

			SELECT @varPermitTypeText = 
				CASE @intWorkCode
					WHEN 10009 THEN @varLevel3Type + ' Preliminary Plat'
					WHEN 10010 THEN @varLevel3Type + ' Final Plat'
					WHEN 10011 THEN @varLevel3Type + ' Preliminary and Final Plat' 
					ELSE 'Unknown ' + @varFolderType + ' WorkCode'
				END
		END 
		ELSE
		BEGIN
			SELECT @varPermitTypeText = 
				CASE @varFolderType
					WHEN 'ZB' THEN 'Basic' 
					WHEN 'ZC' THEN 'Certificate of Appropriateness'
					WHEN 'ZF' THEN 'Fence'
					WHEN 'ZZ' THEN 'Paper-Based Record'
					WHEN 'Z1' THEN 'Certificate of Appropriateness'
					WHEN 'Z2' THEN 'Certificate of Appropriateness'
					WHEN 'Z3' THEN 'Certificate of Appropriateness'
					ELSE @varFolderType + ' is an Unknown Folder Type'
				END
		END
	END 
	RETURN @varPermitTypeText
END


GO
