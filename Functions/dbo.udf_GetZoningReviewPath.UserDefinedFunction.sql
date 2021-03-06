USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningReviewPath]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningReviewPath](@intFolderRSN INT)
RETURNS VARCHAR(40)
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports, and PZ web site reports */
   DECLARE @varReviewPath varchar(40)
   DECLARE @varFolderType varchar(4)
   DECLARE @intSubCode int

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SET @varReviewPath = '?'

   SELECT @varReviewPath = 
   CASE @intSubCode
      WHEN 10020 THEN 'Pre-1991 Permit Data'
      WHEN 10021 THEN 'Pre-1991 Permit Data'
      WHEN 10041 THEN 'Zoning Staff (Administrative)'
      WHEN 10042 THEN 'Development Review Board'
      ELSE 'TBD'
   END

   RETURN @varReviewPath
END
GO
