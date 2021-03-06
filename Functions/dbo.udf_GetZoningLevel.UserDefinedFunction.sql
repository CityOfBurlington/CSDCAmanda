USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningLevel]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningLevel](@intFolderRSN INT) 
RETURNS int
AS
BEGIN
   /* Used by Infomaker permit forms */
   DECLARE @intLevel int 
   DECLARE @varFolderType varchar(3)
   DECLARE @intEstConstructionCost int

   SET @intLevel  = 0
  
   SELECT @varFoldertype = Folder.FolderType
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @intEstConstructionCost = ISNULL(CAST(FolderInfo.InfoValueNumeric AS INT), 0)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 10000

   IF @varFolderType = 'Z3' SELECT @intLevel = 3
   ELSE
   BEGIN
      IF @intEstConstructionCost > 21000 SELECT @intLevel = 2
      ELSE SELECT @intLevel = 1 
   END 

   RETURN @intLevel 
END

GO
