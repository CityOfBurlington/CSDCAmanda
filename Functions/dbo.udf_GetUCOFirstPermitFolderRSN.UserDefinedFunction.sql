USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOFirstPermitFolderRSN]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOFirstPermitFolderRSN](@intFolderRSN INT) 
RETURNS INT
AS
BEGIN
   /* Returns the first permit FolderRSN in a UC folder. First is defined as 
      the earliest Folder.IssueDate of the permits listed in FolderInfo. */

   DECLARE @intCountInfoCodes int
   DECLARE @intCounter int
   DECLARE @intPermitFolderRSN int
   DECLARE @varFolderType varchar(4)
   DECLARE @dtFolderIssueDate datetime
   DECLARE @varCOFlag varchar(2)
   DECLARE @dtFirstIssueDate datetime
   DECLARE @intZoningFolderRSN int
   DECLARE @intBuildingFolderRSN int
   DECLARE @intFirstFolderRSN int 

   SET @intZoningFolderRSN = 0
   SET @intBuildingFolderRSN = 0
   SET @intFirstFolderRSN = 0

   SELECT @intCountInfoCodes = COUNT(*)
     FROM FolderInfo
    WHERE FolderInfo.InfoCode BETWEEN 23001 AND 23020
      AND FolderInfo.FolderRSN = @intFolderRSN

   SELECT @intCounter = 1

   WHILE @intCounter < ( @intCountInfoCodes + 1 ) 
   BEGIN
      SELECT @intPermitFolderRSN = FolderInfo.InfoValueNumeric
        FROM FolderInfo
       WHERE FolderInfo.InfoCode = ( 23000 + @intCounter )
         AND FolderInfo.FolderRSN = @intFolderRSN

      SELECT @varFolderType = Folder.FolderType, 
             @dtFolderIssueDate = Folder.IssueDate
        FROM Folder
       WHERE Folder.FolderRSN = @intPermitFolderRSN
       
      SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intPermitFolderRSN) 

      IF @varFolderType LIKE 'Z%' AND @varCOFlag = 'Y'
      BEGIN
         IF @dtFirstIssueDate IS NULL
         BEGIN 
            SELECT @dtFirstIssueDate = @dtFolderIssueDate 
            SELECT @intZoningFolderRSN = @intPermitFolderRSN
         END
         ELSE 
         IF @dtFolderIssueDate < @dtFirstIssueDate 
         BEGIN 
            SELECT @dtFirstIssueDate = @dtFolderIssueDate 
            SELECT @intZoningFolderRSN = @intPermitFolderRSN
         END
      END

      IF @varFolderType IN ('BP','EP','MP') AND @dtFolderIssueDate IS NOT NULL
      BEGIN
         IF @dtFirstIssueDate IS NULL
         BEGIN 
            SELECT @dtFirstIssueDate = @dtFolderIssueDate 
            SELECT @intBuildingFolderRSN = @intPermitFolderRSN
         END
         ELSE 
         IF @dtFolderIssueDate < @dtFirstIssueDate 
         BEGIN 
            SELECT @dtFirstIssueDate = @dtFolderIssueDate 
            SELECT @intBuildingFolderRSN = @intPermitFolderRSN
         END
      END

      SELECT @intCounter = @intCounter + 1

   END  /* End of InfoCode loop */

   IF @intZoningFolderRSN = 0 
        SELECT @intFirstFolderRSN = @intBuildingFolderRSN 
   ELSE SELECT @intFirstFolderRSN = @intZoningFolderRSN     

   RETURN @intFirstFolderRSN 
END
GO
