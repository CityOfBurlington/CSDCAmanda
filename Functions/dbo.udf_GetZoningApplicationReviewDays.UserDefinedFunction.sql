USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningApplicationReviewDays]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningApplicationReviewDays](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports.pbl */
   DECLARE @varFolderType varchar(2)
   DECLARE @intSubCode int
   DECLARE @dateInDate datetime
   DECLARE @dateIssueDate datetime
   DECLARE @AdminDecisionDate datetime
   DECLARE @DRBDecisionDate datetime
   DECLARE @DRBAppealDecisionDate datetime
   DECLARE @intReviewDays int

   SET @intReviewDays = NULL

   SELECT @varFolderType = Folder.FolderType, @intSubCode = Folder.SubCode, 
          @dateInDate = Folder.InDate, @dateIssueDate = Folder.IssueDate 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @AdminDecisionDate = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 10055

   IF @varFolderType = 'ZL'
   BEGIN 
      SELECT @DRBDecisionDate = FolderInfo.InfoValueDateTime
        FROM FolderInfo
       WHERE FolderInfo.FolderRSN = @intFolderRSN
         AND FolderInfo.InfoCode = 10056
   END 
   ELSE 
   BEGIN
      SELECT @DRBDecisionDate = FolderInfo.InfoValueDateTime
        FROM FolderInfo
       WHERE FolderInfo.FolderRSN = @intFolderRSN
         AND FolderInfo.InfoCode = 10049
   END

   IF @intSubCode = 10041             /* Administrative Review */
      SELECT @intReviewDays = DATEDIFF(DAY, @dateInDate, @AdminDecisionDate)
 
   IF @intSubCode = 10042             /* DRB Review */
      SELECT @intReviewDays = DATEDIFF(DAY, @dateInDate, @DRBDecisionDate) 

   IF @intSubCode IN (10020, 10021)   /* ZZ Folders */
      SELECT @intReviewDays = DATEDIFF(DAY, @dateInDate, @dateIssueDate) 

   RETURN @intReviewDays
END

GO
