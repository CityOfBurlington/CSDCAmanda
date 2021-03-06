USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDRBReviewType]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetZoningDRBReviewType](@intFolderRSN INT)
RETURNS VARCHAR(60)
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports.pbl */
   DECLARE @varReviewType varchar(60)
   DECLARE @varFolderType varchar(2)
   DECLARE @intSubCode int
   DECLARE @intWorkCode int

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode,
          @intWorkCode = Folder.WorkCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SET @varReviewType = 'Not Reviewed by DRB'

   IF @intSubCode = 10041 AND dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10002) IN (10006, 10007)
   BEGIN
      SELECT @varReviewType = 'Appeal of Zoning Permit Administrative Decision'
   END 

   IF @intSubCode = 10042 AND @varFolderType NOT IN ('Z3', 'ZC', 'ZH', 'ZL')
   BEGIN
      SELECT @varReviewType = 
      CASE @varFolderType
         WHEN 'Z1' THEN 'Site Plan COA'
         WHEN 'Z2' THEN 'Site Plan COA'
         WHEN 'ZA' THEN 'Signs and Awnings' 
         WHEN 'ZB' THEN 'Site Plan Basic'
         WHEN 'ZD' THEN 'Determination'
         WHEN 'ZF' THEN 'Fence'
         WHEN 'ZP' THEN 'Master Plan'
         WHEN 'ZS' THEN 'Sketch Plan'
         ELSE 'Unknown FolderType'
      END
   END

   IF @intSubCode = 10042 AND @varFolderType = 'Z3'
   BEGIN
      SELECT @varReviewType = 
      CASE @intWorkCode
         WHEN 10009 THEN 'Preliminary Plat'
         WHEN 10010 THEN 'Final Plat'
         WHEN 10011 THEN 'Preliminary and Final Plat'
         ELSE 'Unknown WorkCode'
      END
   END

   IF @varFolderType = 'ZC'
   BEGIN
      SELECT @varReviewType = 
      CASE @intWorkCode
         WHEN 10000 THEN 'Site Plan COA and Conditional Use'
         WHEN 10001 THEN 'Site Plan COA and Home Occupation'
         WHEN 10002 THEN 'Site Plan COA and Major Impact Review'
         WHEN 10003 THEN 'Site Plan COA and Variance'
         ELSE 'Unknown WorkCode'
      END
   END

   IF @varFolderType IN ('ZH', 'ZL')
   BEGIN
      SELECT @varReviewType = 
      CASE @intWorkCode
         WHEN 10000 THEN 'Conditional Use'
         WHEN 10001 THEN 'Home Occupation'
         WHEN 10002 THEN 'Major Impact Review with Site Plan'
         WHEN 10003 THEN 'Variance'
         WHEN 10004 THEN 'Appeal of Code Enforcement Decision'
         WHEN 10005 THEN 'Appeal of Misc Zoning Decision'
         ELSE 'Unknown WorkCode'
      END
   END

   RETURN @varReviewType
END

GO
