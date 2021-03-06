USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningStaffReviewRating]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningStaffReviewRating](@intFolderRSN INT)
RETURNS VARCHAR(20)
AS
BEGIN
   /* Ranks folders by review difficulty for staff to process */

   DECLARE @varFolderType varchar(4)
   DECLARE @intSubCode int
   DECLARE @intAppealtoDRB int
   DECLARE @intFolderRatingCode int
   DECLARE @varFolderRating varchar(20)

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @intAppealtoDRB = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10002)

   /* All DRB Review */

   IF @intSubCode = 10042 SELECT @intFolderRatingCode = 3 

   IF ( @intSubCode = 10041 AND @intAppealtoDRB = 0 )
   BEGIN
      IF @varFolderType IN ('ZA', 'ZF', 'ZN', 'ZS') SELECT @intFolderRatingCode = 1 
      ELSE SELECT @intFolderRatingCode = 2 
   END
   IF @intSubCode = 10041 AND @intAppealtoDRB > 0 SELECT @intFolderRatingCode = 3 

   SELECT @varFolderRating = 
   CASE @intFolderRatingCode 
      WHEN 1 THEN 'Easy' 
      WHEN 2 THEN 'More Difficult' 
      WHEN 3 THEN 'Most Difficult' 
      ELSE 'Unknown'
   END

   RETURN @varFolderRating
END
GO
