USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCOFinalDecisionDateForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCOFinalDecisionDateForm](@intFolderRSN INT) 
RETURNS datetime
AS
BEGIN
   /* Returns the FCO Decision Date for Certificate of Occupancy processing. 
      Returns the date for the highest phase where the PCO was issued. 
      Used by Infomaker CO report form. 
      Can not use Folder.StatusCode to differentiate phasing because the 
      Folder.StatusCode becomes Final CO Issued (10008) upon issuance. */

   DECLARE @intNumberofPhases int
   DECLARE @dtFCODecisionDate datetime

   SET @intNumberofPhases = 1 

   SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10081 

   IF @intNumberofPhases > 1     /* Phased Projects */
   BEGIN
      SELECT @dtFCODecisionDate = FolderProcessInfo.InfoValueDateTime
        FROM FolderProcessInfo
       WHERE FolderProcessInfo.FolderRSN = @intFolderRSN 
         AND FolderProcessInfo.InfoCode = 10011   /* Phase CO Decision Date */
         AND FolderProcessInfo.ProcessRSN = 
             ( SELECT MAX(FolderProcess.ProcessRSN) 
                 FROM FolderProcess, FolderProcessAttempt 
                WHERE FolderProcess.FolderRSN = @intFolderRSN 
                  AND FolderProcess.ProcessCode = 10030 
                  AND FolderProcess.StatusCode = 2 
                  AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
                  AND FolderProcessAttempt.ResultCode = 10066 )  /* Approved for Phase CO */
   END
   ELSE       /* Single Phase Projects */
   BEGIN
      SELECT @dtFCODecisionDate = dbo.f_info_date(@intFolderRSN, 10073)
   END

   RETURN @dtFCODecisionDate 
END

GO
