USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningBuildingPermitFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningBuildingPermitFlag](@intFolderRSN INT)
RETURNS VARCHAR(15)
AS
BEGIN 
   /* Returns Yes or No for whether a building permit may be required for 
      the project. Used on zoning permit forms. */

   DECLARE @varFolderType varchar(4)
   DECLARE @intSubCode int
   DECLARE @intWorkCode int
   DECLARE @intDecisionCode int
   DECLARE @varZ3ProjectType varchar(20)
   DECLARE @varBuildingPermitFlag varchar(15)

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode, 
          @intWorkCode = Folder.WorkCode 
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @intDecisionCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)

   SELECT @varZ3ProjectType = FolderInfo.InfoValue 
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10015

   SET @varBuildingPermitFlag = 'Yes'

   IF @intDecisionCode IN (10002, 10020)    /* Permit Application Denials */
      SELECT @varBuildingPermitFlag = 'Not Applicable' 

   ELSE      /* Approvals and other types of decisions */
   BEGIN
      IF @varFolderType IN ('ZD', 'ZL', 'ZP', 'ZS') 
         SELECT @varBuildingPermitFlag = 'No'

      IF @varFolderType = 'Z3'
      BEGIN
         SELECT @varBuildingPermitFlag = 
           CASE @varZ3ProjectType  
              WHEN 'Lot Line Adjustment' THEN 'Yes'   
              WHEN 'Lot Merger' THEN 'Yes' 
              WHEN 'Subdivision' THEN 'Yes'
              ELSE 'Yes'
           END
      END
   END    /* End of approval and other decisions */

   RETURN @varBuildingPermitFlag
END

GO
