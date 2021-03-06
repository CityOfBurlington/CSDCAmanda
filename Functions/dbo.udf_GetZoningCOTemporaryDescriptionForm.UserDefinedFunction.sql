USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCOTemporaryDescriptionForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCOTemporaryDescriptionForm](@intFolderRSN INT) 
RETURNS varchar(500)
AS
BEGIN
   /* Returns the project description for Temporary Certificate of Occupancy issuance. 
      Returns the description for the highest phase where the CO was requested. 
      Used by Infomaker zoning_certificate_of_occupancy form. */

   DECLARE @intNumberofPhases int
   DECLARE @varCOProjectDesc varchar(500)

   SET @intNumberofPhases = 1 

   SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10081 

   IF @intNumberofPhases > 1     /* Phased Projects */
   BEGIN
      SELECT @varCOProjectDesc = FolderProcess.ProcessComment 
        FROM FolderProcess 
       WHERE FolderProcess.FolderRSN = @intFolderRSN
         AND FolderProcess.ProcessRSN = 
             ( SELECT MAX(FolderProcess.ProcessRSN) 
                 FROM FolderProcess, FolderProcessAttempt 
                WHERE FolderProcess.FolderRSN = @intFolderRSN 
                  AND FolderProcess.ProcessCode = 10030 
                  AND FolderProcess.StatusCode = 10004  
                  AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
                  AND FolderProcessAttempt.ResultCode = 10029 )  /* Approved for Temp CO */
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
