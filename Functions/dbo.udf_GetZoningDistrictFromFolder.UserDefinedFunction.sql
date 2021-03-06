USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDistrictFromFolder]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDistrictFromFolder](@intFolderRSN INT) 
RETURNS varchar(10)
AS
BEGIN
	/* Returns the primary base zoning district abbreviation from a zonging folder. 
	   The primary district is the one that covers the largest percentage of a parcel. */

	DECLARE @varFolderDistrict varchar(20)
	DECLARE @intCompositeFlag int
	DECLARE @varZnDistrict varchar(10)

	SELECT @varFolderDistrict = ISNULL(FolderInfo.InfoValue, 'missing'), 
		   @intCompositeFlag = PATINDEX('%/%', FolderInfo.InfoValue) 
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intFolderRSN
	AND FolderInfo.InfoCode = 10002
		
	IF @intCompositeFlag > 1
		SELECT @varZnDistrict = LEFT(@varFolderDistrict, (@intCompositeFlag - 1))
	ELSE 
		SELECT @varZnDistrict = @varFolderDistrict

	RETURN @varZnDistrict
END

GO
