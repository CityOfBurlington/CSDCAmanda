USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCOTemporaryExpiryDateForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCOTemporaryExpiryDateForm](@intFolderRSN INT) 
RETURNS datetime 
AS
BEGIN
   /* Returns the TCO Expiration Date for Certificate of Occupancy processing. 
      Returns the date for the highest phase where the TCO was issued. 
      Used by Infomaker CO report form. */

   DECLARE @intNumberofPhases int
   DECLARE @dtTCOExpiryDate datetime

   SET @intNumberofPhases = 1 

   SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10081 

   IF @intNumberofPhases > 1     /* Phased Projects */
   BEGIN
      SELECT @dtTCOExpiryDate = FolderProcessInfo.InfoValueDateTime
        FROM FolderProcessInfo
       WHERE FolderProcessInfo.FolderRSN = @intFolderRSN 
         AND FolderProcessInfo.InfoCode = 10015   /* Temp CO Expiration Date */
         AND FolderProcessInfo.ProcessRSN = 
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
      SELECT @dtTCOExpiryDate = dbo.f_info_date(@intFolderRSN, 10072)  /* Temp CO Expiration Date */
   END

   RETURN @dtTCOExpiryDate 
END

GO
