USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Permit_Expiration_Date_From_Decision]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Permit_Expiration_Date_From_Decision] (@intFolderRSN int, @intInfoCode int)
AS
BEGIN 
   /* Calculates Zoning Permit expiration date from specified Decision Date. */
   /* Run manually one folder at a time when things get confused. */

   DECLARE @dtPermitDecisionDate datetime
   DECLARE @dtPermitExpiryDate datetime

   SELECT @dtPermitDecisionDate = FolderInfo.InfoValueDatetime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = @intInfoCode

   IF @dtPermitDecisionDate IS NOT NULL
   BEGIN
      SELECT @dtPermitExpiryDate = dbo.udf_ZnPermitExpirationDate(@intFolderRSN, @dtPermitDecisionDate) 

      UPDATE FolderInfo 
         SET FolderInfo.InfoValue = CONVERT(CHAR(11), @dtPermitExpiryDate), 
             FolderInfo.InfoValueDateTime = @dtPermitExpiryDate
       WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode = 10024
   END
END
GO
