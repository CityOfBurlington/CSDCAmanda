USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOCountBuildingPermits]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOCountBuildingPermits](@intFolderRSN INT) 
RETURNS INT 
AS
BEGIN
    /* Counts number of zoning permits in a UCO. Used by UCO Infomaker forms. */
   DECLARE @intInfoFieldCount int
   DECLARE @intZPFolderCount int
   DECLARE @intBPFolderCount int
   DECLARE @intPermitFolderRSN int
   DECLARE @varFolderType varchar(4)
   DECLARE @intCounter int

   SELECT @intInfoFieldCount = COUNT(*)
     FROM FolderInfo
    WHERE FolderInfo.InfoCode BETWEEN 23001 AND 23020
      AND FolderInfo.FolderRSN = @intFolderRSN

   SELECT @intZPFolderCount = 0 
   SELECT @intBPFolderCount = 0 

   IF @intInfoFieldCount > 0 
   BEGIN
      SELECT @intCounter = 1

      WHILE @intCounter < ( @intInfoFieldCount + 1 ) 
      BEGIN
         SELECT @intPermitFolderRSN = FolderInfo.InfoValueNumeric
           FROM FolderInfo
          WHERE FolderInfo.InfoCode = ( 23000 + @intCounter )
            AND FolderInfo.FolderRSN = @intFolderRSN

         SELECT @varFolderType = Folder.FolderType
           FROM Folder
          WHERE Folder.FolderRSN = @intPermitFolderRSN

         IF @varFolderType LIKE 'Z%' SELECT @intZPFolderCount = @intZPFolderCount + 1

         IF @varFolderType = 'BP' SELECT @intBPFolderCount = @intBPFolderCount + 1

         SELECT @intCounter = @intCounter + 1

      END  /* End of InfoCode loop */
   END

	RETURN @intBPFolderCount 
END

GO
