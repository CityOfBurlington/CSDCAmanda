USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningPermitExpirationDateFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningPermitExpirationDateFlag](@intFolderRSN INT)
RETURNS VARCHAR(2)
AS
BEGIN 
   /* Returns Y/N for whether or not a permit expires (a expiration date 
      (InfoCode 10024) is calculated for the folder). 
      No permit expiration dates for Code Enforcement Appeals, Misc Zoning 
      Appeals, Determinations, Nonapplicabilities, Sketch Plan Review, all 
      Master Plan Reviews except Parking. A time limit on a Variance may or 
      may not be imposed (sec. 12.1.3), so default to calculating one.*/

   DECLARE @varFolderType varchar(4)
   DECLARE @intSubCode int
   DECLARE @intWorkCode int
   DECLARE @varExpiryFlag varchar(2)

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode, 
          @intWorkCode = Folder.WorkCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SET @varExpiryFlag = '?'

   IF @varFolderType = 'ZP'      /* Master Plan Review */
   BEGIN 
      SELECT @varExpiryFlag = 
        CASE @intWorkCode
           WHEN 10006 THEN 'Y'   /* Parking Plan */
           WHEN 10008 THEN 'Y'   /* Tree Maintenance Plan */
           ELSE 'N'
        END
   END

   IF @varFolderType <> 'ZP'
   BEGIN 
      SELECT @varExpiryFlag = 
        CASE @varFolderType 
           WHEN 'ZD' THEN 'N'    /* Determination */
           WHEN 'ZL' THEN 'N'    /* Misc Appeals */
           WHEN 'ZN' THEN 'N'    /* Nonapplicability */
           WHEN 'ZS' THEN 'N'    /* Sketch Plan Review */
           ELSE 'Y'
        END
   END

   RETURN @varExpiryFlag
END

GO
