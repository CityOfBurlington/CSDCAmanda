USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningLevel3ReviewType]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningLevel3ReviewType](@intFolderRSN INT) 
RETURNS varchar(4)
AS
BEGIN
   /* Used by Infomaker permit forms */
   DECLARE @varFolderType varchar(3)
   DECLARE @varLevel3Review varchar(30)
   DECLARE @varLevel3Abbrev varchar(4)
  
   SELECT @varFoldertype = Folder.FolderType
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varLevel3Review = ISNULL(FolderInfo.InfoValueUpper, 'X')
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 10015

   IF @varFolderType <> 'Z3' SELECT @varLevel3Abbrev = 'NA'
   ELSE
   BEGIN
      SELECT @varLevel3Abbrev = 
        CASE @varLevel3Review 
           WHEN 'LOT LINE ADJUSTMENT' THEN 'LLA' 
           WHEN 'LOT MERGER' THEN 'LM'
           WHEN 'PLANNED UNIT DEVELOPMENT' THEN 'PUD' 
           WHEN 'SUBDIVISION' THEN 'SD' 
           ELSE 'X' 
        END
   END 

   RETURN @varLevel3Abbrev 
END

GO
