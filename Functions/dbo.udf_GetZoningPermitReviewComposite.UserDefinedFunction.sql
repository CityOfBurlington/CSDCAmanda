USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitReviewComposite]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitReviewComposite](@intFolderRSN INT) 
RETURNS varchar(80)
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports.pbl */
   DECLARE @varFolderType varchar(2)
   DECLARE @intSubCode int
   DECLARE @intWorkCode int
   DECLARE @varPermitType varchar(50)
   DECLARE @varReviewType varchar (30)
   DECLARE @varPermitComposite varchar(80)

   SET @varFolderType = 'x'
   SET @varReviewType = 'y'

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode, 
          @intWorkCode = Folder.WorkCode
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN

    SET @varPermitType = '?'

    SELECT @varPermitType = 
    CASE @varFolderType
       WHEN 'ZA' THEN 'Signs and Awnings'
       WHEN 'ZB' THEN 'Basic'
       WHEN 'ZD' THEN 'Determination'
       WHEN 'ZF' THEN 'Fence'
       WHEN 'ZN' THEN 'Nonapplicability'
       WHEN 'ZZ' THEN 'Permit (pre-1991)' 
       WHEN 'Z1' THEN 'COA I'
       WHEN 'Z2' THEN 'COA II'
    END

    IF @varFolderType IN ('Z3', 'ZH', 'ZL', 'ZP') 
    BEGIN
       SELECT @varPermitType = 
       CASE @intWorkCode
          WHEN 10000 THEN 'Conditional Use'
          WHEN 10001 THEN 'Home Occupation' 
          WHEN 10002 THEN 'Conditional Use (Major Impact)'
          WHEN 10003 THEN 'Variance' 
          WHEN 10004 THEN 'Misc Appeal - Code Enforcement'
          WHEN 10005 THEN 'Misc Appeal - Zoning'
          WHEN 10006 THEN 'Master Plan - Parking'
          WHEN 10007 THEN 'Master Plan - Signs'
          WHEN 10008 THEN 'Master Plan - Tree Maintenance'
          WHEN 10009 THEN 'COA III Preliminary Plat'
          WHEN 10010 THEN 'COA III Final Plat'
          WHEN 10011 THEN 'COA III Combination Plat'
       END
    END

    IF @varFolderType = 'ZC' 
    BEGIN
       SELECT @varPermitType = 
       CASE @intWorkCode
          WHEN 10000 THEN 'COA and Conditional Use'
          WHEN 10001 THEN 'COA and Home Occupation' 
          WHEN 10002 THEN 'COA and Conditional Use (Major Impact)'
          WHEN 10003 THEN 'COA and Variance' 
       END
    END

    SELECT @varReviewType = 
    CASE @intSubCode
       WHEN 10020 THEN 'Admin or ZBA'
       WHEN 10021 THEN 'Admin'
       WHEN 10041 THEN 'Admin'
       WHEN 10042 THEN 'DRB'
       ELSE 'DRB'
    END

    SELECT @varPermitComposite = @varPermitType + ' - ' + @varReviewType

    RETURN @varPermitComposite
END

GO
