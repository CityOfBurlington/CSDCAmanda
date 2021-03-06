USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFolderInfoZoningDistrict]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFolderInfoZoningDistrict](@intFolderRSN INT)
RETURNS varchar(10)
AS
BEGIN
/* Returns the Zoning District from FolderInfo. */

DECLARE @varFolderType varchar(4)
DECLARE @intInfoCode int
DECLARE @varZoningDistrict varchar(10)

SELECT @varFolderType = Folder.FolderType
  FROM Folder 
 WHERE Folder.FolderRSN = @intFolderRSN 

IF @varFolderType = 'ZZ' SELECT @intInfoCode = 10011   /* Historic Zoning District */
ELSE SELECT @intInfoCode = 10002                       /* Current Zoning District */

SELECT @varZoningDistrict = FolderInfo.InfoValueUpper
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @intFolderRSN
   AND FolderInfo.InfoCode = @intInfoCode

RETURN @varZoningDistrict 
END
GO
