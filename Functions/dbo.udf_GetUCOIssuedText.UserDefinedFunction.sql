USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOIssuedText]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOIssuedText](@intFolderRSN INT) 
RETURNS VARCHAR(500)
AS
BEGIN
    /* Returns summary text statement above signatures on the UCO Infomaker form. */

   DECLARE @intFolderStatus int
   DECLARE @varPropertyAddress varchar(100)
   DECLARE @varIssueDate varchar(50)
   DECLARE @intBPFolderCount int
   DECLARE @intZPFolderCount int
   DECLARE @varIssuedText1 varchar(200)
   DECLARE @varIssuedText2 varchar(50)
   DECLARE @varIssuedText3 varchar(50)
   DECLARE @varIssuedText  varchar(300)

   SELECT @intFolderStatus = Folder.StatusCode 
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varPropertyAddress = dbo.udf_GetPropertyAddressLongMixed(@intFolderRSN) 

   SELECT @varIssueDate = dbo.udf_GetIssueDateVeryLong(@intFolderRSN) 

   SELECT @intBPFolderCount = dbo.udf_GetUCOCountBuildingPermits(@intFolderRSN) 
   SELECT @intZPFolderCount = dbo.udf_GetUCOCountZoningPermits(@intFolderRSN) 

   SELECT @varIssuedText1 = ' ' 
   SELECT @varIssuedText2 = ' ' 
   SELECT @varIssuedText3 = ' ' 

   IF @intFolderStatus = 23005 
   BEGIN
      SELECT @varIssuedText1 = 'This Certificate of Occupancy for ' + 
                               @varPropertyAddress + ' was issued on ' + 
                               @varIssueDate +  ' by the City of Burlington, Vermont, for the'  

      IF @intZPFolderCount = 1 
      BEGIN 
         IF @intBPFolderCount = 0 SELECT @varIssuedText2 = ' Zoning permit listed above.'
         ELSE SELECT @varIssuedText2 = ' Zoning permit and '
      END

      IF @intZPFolderCount > 1
      BEGIN 
         IF @intBPFolderCount = 0 SELECT @varIssuedText2 = CAST(@intZPFolderCount AS VARCHAR) + ' Zoning permits listed above.'
         ELSE SELECT @varIssuedText2 = ' ' + CAST(@intZPFolderCount AS VARCHAR) + ' Zoning permits and '
      END

      IF @intBPFolderCount > 0 
      BEGIN 
         IF @intBPFolderCount = 1 SELECT @varIssuedText3 = 'Building permit listed above.'
         ELSE SELECT @varIssuedText3 = CAST(@intBPFolderCount AS VARCHAR) + ' Building permits listed above.'
      END

      SELECT @varIssuedText = @varIssuedText1 + @varIssuedText2 + @varIssuedText3 
   END 
   ELSE SELECT @varIssuedText = 'This Certificate of Occupancy has NOT been issued.'

   RETURN ISNULL(@varIssuedText, ' ')
END

GO
