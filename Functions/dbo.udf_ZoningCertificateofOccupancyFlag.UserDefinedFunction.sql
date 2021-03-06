USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningCertificateofOccupancyFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningCertificateofOccupancyFlag](@intFolderRSN INT)
RETURNS VARCHAR(2)
AS
BEGIN 
   /* Returns Y if CO is required, or N. */

   DECLARE @varFolderType varchar(4)
   DECLARE @intWorkCode int
   DECLARE @intDecisionCode int
   DECLARE @varCOFlag varchar(4)

   SET @varCOFlag = 'N'

   SELECT @varFolderType = Folder.FolderType, 
          @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @intDecisionCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)

   IF @intDecisionCode IN(10003, 10011) 
   BEGIN 
      IF @varFolderType IN('Z1', 'Z2', 'ZA', 'ZB', 'ZC', 'ZF', 'ZH', 'ZZ') 
         SELECT @varCOFlag = 'Y'

      IF @varFolderType = 'Z3' AND @intWorkCode IN (10010, 10011) 
         SELECT @varCOFlag = 'Y' 
   END

   RETURN @varCOFlag
END

GO
