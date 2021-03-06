USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningWebFolderType]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningWebFolderType](@intFolderRSN INT) 
RETURNS VARCHAR(60)
AS
BEGIN
     /* Returns a more complete permit/request type description for daily web site report */

     DECLARE @FolderType varchar(4)
     DECLARE @FolderDesc varchar(60)
     DECLARE @WorkCode int
     DECLARE @ProjectType varchar(30)
     DECLARE @COAPermit varchar(35)
	 
     SELECT @FolderType = Folder.FolderType, 
            @WorkCode = Folder.WorkCode
       FROM Folder
      WHERE Folder.FolderRSN = @intFolderRSN
	 
	 SELECT @ProjectType = FolderInfo.InfoValue
	    FROM FolderInfo
	   WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode = 10015 

	 IF @FolderType IN ('Z3', 'ZD', 'ZH', 'ZL', 'ZN', 'ZP') 
     BEGIN
		 SELECT @FolderDesc = 
	     CASE @WorkCode
             WHEN 10000 THEN 'Conditional Use Permit'
             WHEN 10001 THEN 'Home Occupation Permit'
             WHEN 10002 THEN 'Conditional Use Permit' 
             WHEN 10003 THEN 'Variance'
             WHEN 10004 THEN 'Code Enforcement Appeal'
             WHEN 10005 THEN 'Misc Zoning Appeal'
             WHEN 10006 THEN 'Master Plan Review - Parking'
             WHEN 10007 THEN 'Master Plan Review - Signs'
             WHEN 10008 THEN 'Master Plan Review - Tree Maintenance'
             WHEN 10009 THEN @ProjectType + ' - Preliminary Plat'
			 WHEN 10010 THEN @ProjectType + ' - Final Plat'
             WHEN 10011 THEN @ProjectType + ' - Final Plat'
		     WHEN 10012 THEN 'Permit Not Required - Other'
			 WHEN 10013 THEN 'Permit Not Required - As-Built'
			 WHEN 10014 THEN 'Permit Not Required - Repair and Maintenance'
			 WHEN 10015 THEN 'Permit Not Required - Handicapped Access'
			 WHEN 10016 THEN 'Permit Not Required - No Change in Use'
			 WHEN 10017 THEN 'Permit Not Required - Work in Right-of-Way'
			 WHEN 10018 THEN 'Permit Not Required - Interior Work'
			 WHEN 10028 THEN 'Determination - Functional Family'
			 WHEN 10029 THEN 'Determination - Other' 
			 WHEN 10030 THEN 'Determination - Parking' 
			 WHEN 10031 THEN 'Determination - Separate Lot'
			 WHEN 10032 THEN 'Determination - Small Lot'
			 WHEN 10033 THEN 'Determination - Existing Use'
			 WHEN 10034 THEN 'Determination - Proposed Use'
			 WHEN 10045 THEN 'Permit Not Required - Exempt from Design Review' 
			 WHEN 10046 THEN 'Permit Not Required - Exempt Vent or HVAC' 
			 ELSE 'Unknown WorkCode'
		 END
	 END

	 IF @FolderType = 'ZC' 
     BEGIN
		 SELECT @FolderDesc = 
	     CASE @WorkCode
             WHEN 10000 THEN 'Certificate of Appropriateness and Conditional Use'
             WHEN 10001 THEN 'Certificate of Appropriateness and Home Occupation'
             WHEN 10002 THEN 'Certificate of Appropriateness and Conditional Use' 
             WHEN 10003 THEN 'Certificate of Appropriateness and Variance' 
             ELSE 'Unknown WorkCode'
         END
     END
	 
	 IF @FolderType NOT IN ('Z3', 'ZC', 'ZD', 'ZH', 'ZL', 'ZN', 'ZP') 
	 BEGIN
         SELECT @FolderDesc = 
         CASE @FolderType
             WHEN 'Z1' THEN 'Certificate of Appropriateness'
             WHEN 'Z2' THEN 'Certificate of Appropriateness'
             WHEN 'ZA' THEN 'Sign and/or Awning Permit'
             WHEN 'ZB' THEN 'Basic Permit'
             WHEN 'ZF' THEN 'Fence Permit'
             WHEN 'ZS' THEN 'Sketch Plan Review'
             ELSE 'Unknown FolderType'
         END
	 END
RETURN @FolderDesc
END

GO
