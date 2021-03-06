USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCODescriptionForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCODescriptionForm](@intFolderRSN INT) 
RETURNS varchar(500)
AS
BEGIN
   /* Returns the project description for Certificate of Occupancy processing. 
      Returns the description for the highest phase where the CO was requested. 
      Used by Infomaker CO report form. */

   DECLARE @intFolderStatusCode int
   DECLARE @varCOProjectDesc varchar(500)

   SET @intFolderStatusCode = 0

   SELECT @intFolderStatusCode = Folder.StatusCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intFolderStatusCode = 10047     /* Project Phasing */
   BEGIN
      SELECT @varCOProjectDesc = FolderProcess.ProcessComment
        FROM FolderProcess
       WHERE FolderProcess.ProcessRSN IN  
             ( SELECT MAX(FolderProcess.ProcessRSN) 
                 FROM FolderProcess
                WHERE FolderProcess.FolderRSN = @intFolderRSN
                  AND FolderProcess.ProcessCode = 10030
                  AND FolderProcess.StatusCode IN (10001, 10002, 10003, 10004, 10005) )
   END
   ELSE       /* Single Phase Projects */
   BEGIN
      SELECT @varCOProjectDesc = Folder.FolderDescription
        FROM Folder
       WHERE Folder.FolderRSN = @intFolderRSN
   END

   RETURN @varCOProjectDesc 
END

GO
