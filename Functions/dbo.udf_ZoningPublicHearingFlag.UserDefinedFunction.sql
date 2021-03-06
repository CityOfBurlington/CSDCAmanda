USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningPublicHearingFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningPublicHearingFlag](@intFolderRSN INT)
RETURNS VARCHAR(2)
AS
BEGIN 
   /* Returns Y if a public hearing is required, or N. Not for use 
      for appeals of administrative decisions (to DRB). */

   DECLARE @varFolderType varchar(4)
   declare @intStatusCode int
   DECLARE @intWorkCode int 
   DECLARE @varLevel3Type varchar(30)
   DECLARE @varPHFlag varchar(4)

   SET @varPHFlag = 'N'

   SELECT @varFolderType = Folder.FolderType, 
          @intStatusCode = Folder.StatusCode, 
          @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   /* Conditional Use, some Home Occupations, Major Impact Review, Variance, Misc Appeals */
   IF @varFolderType IN ('ZC', 'ZH', 'ZL') SELECT @varPHFlag = 'Y'

   /* Parking Master Plans - On-the-Record review does not require Public Hearing warning */
   IF ( @varFolderType = 'ZP' AND @intWorkcode = 10006 ) SELECT @varPHFlag = 'Y' 

   /* COA Level 3 PUDs and Subdivision */
   IF @varFolderType = 'Z3' 
   BEGIN
      SELECT @varLevel3Type = FolderInfo.InfoValueUpper 
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode = 10015 

      IF @varLevel3Type IN ('PLANNED UNIT DEVELOPMENT', 'SUBDIVISION') SELECT @varPHFlag = 'Y' 
   END

   /* Appeals to DRB */ 
   IF @intStatusCode IN (10009, 10020, 10021)  SELECT @varPHFlag = 'Y' 

   RETURN @varPHFlag
END
GO
