USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeeCodeApplication]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeeCodeApplication](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
	/* Returns ValidAccountFee.FeeCode for applications by Zoning FolderType. */
	/* Used for insertion of Time Extension fees, but could be expanded for 
		use in all fee insertions. JA 7/2012 */

	DECLARE @varFolderType varchar(4)
	DECLARE @intWorkCode int
	DECLARE @intFeeCode int
	
	SET @intFeeCode = 0
	
	SELECT @varFolderType = Folder.FolderType, 
			@intWorkCode = Folder.WorkCode 
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @intFeeCode = 
	CASE @varFolderType
		WHEN 'Z1' THEN 90
		WHEN 'Z2' THEN 95
		WHEN 'Z3' THEN 100
		WHEN 'ZA' THEN 105
		WHEN 'ZB' THEN 85
		WHEN 'ZD' THEN 150
		WHEN 'ZF' THEN 130
		WHEN 'ZL' THEN 137 
		WHEN 'ZP' THEN 110
		WHEN 'ZS' THEN 140 		
	END

	IF @varFolderType = 'ZH' 
	BEGIN
		SELECT @intFeeCode = 
		CASE @intWorkCode 
			WHEN 10002 THEN 136		/* Major Impact */
			ELSE 135
		END
	END

	IF @varFolderType = 'ZC' 
	BEGIN
		IF dbo.udf_ZoningDevReviewFeeFlag(@intFolderRSN) = 'Y'
			SELECT @intFeeCode = 95
		ELSE SELECT @intFeeCode = 90
	END
	
	RETURN @intFeeCode
END

GO
