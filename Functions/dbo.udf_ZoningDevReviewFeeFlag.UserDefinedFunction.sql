USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningDevReviewFeeFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningDevReviewFeeFlag](@intFolderRSN INT)
RETURNS varchar(2)
AS
BEGIN
   /* Returns 'Y' if the Development Review fee is applicable, and 
      'N' if it is not. */

   DECLARE @varFolderType varchar(4)
   DECLARE @varLevel3Review varchar(4)
   DECLARE @fltConstructionCost float 
   DECLARE @varDRFFlag varchar(2)
   
   SELECT @varFolderType = Folder.FolderType
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varLevel3Review = dbo.udf_GetZoningLevel3ReviewType(@intFolderRSN) 

   SET @varDRFFlag = 'N' 

   /* > $23000 triggers the DRF */
   SELECT @fltConstructionCost = ISNULL(FolderInfo.InfoValueNumeric, 0) 
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10000 

   IF ( @varFolderType = 'ZC' AND @fltConstructionCost > 23000 ) SELECT @varDRFFlag = 'Y' 

   IF @varFolderType = 'Z2' SELECT @varDRFFlag  = 'Y'

   IF ( @varFolderType = 'Z3' AND @varLevel3Review IN ('PUD', 'SD') ) SELECT @varDRFFlag  = 'Y' 

   RETURN @varDRFFlag 
END
GO
