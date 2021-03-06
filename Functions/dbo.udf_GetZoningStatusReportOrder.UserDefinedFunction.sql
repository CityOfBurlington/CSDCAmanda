USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningStatusReportOrder]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetZoningStatusReportOrder](@intFolderRSN int)
RETURNS INT
AS
BEGIN
   /* Called by Infomaker forms - sets a display order reflecting general 
      zoning review process order.
      An xls version (sortable) is u:\amanda\infomaker_forms\folder_status_order.xls.  */

   DECLARE @intFolderStatus int
   DECLARE @intPhaseCOProcessStatus int
   DECLARE @intStatusOrder int

   SELECT @intFolderStatus = Folder.StatusCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intFolderStatus = 10047   /* Return CO processing status codes for phased projects */
   BEGIN
      SELECT @intPhaseCOProcessStatus = ISNULL(FolderProcess.StatusCode, 0)
        FROM FolderProcess
       WHERE FolderProcess.ProcessRSN = 
             ( SELECT MAX(FolderProcess.ProcessRSN) 
                 FROM FolderProcess
                WHERE FolderProcess.FolderRSN = @intFolderRSN
                  AND FolderProcess.ProcessCode = 10030
                  AND FolderProcess.StatusCode IN (10001, 10002, 10003, 10004, 10005) )

      IF @intPhaseCOProcessStatus > 2 
      BEGIN
         SELECT @intFolderStatus = 
         CASE @intPhaseCOProcessStatus
            WHEN 10001 THEN 10011   /* CO Requested */
            WHEN 10002 THEN 10026   /* Incomplete CO App */
            WHEN 10003 THEN 10035   /* CO Noncompliant */
            WHEN 10004 THEN 10007   /* Temp CO Issued */
            WHEN 10005 THEN 10013   /* Temp CO Expired */
         END
      END
   END

   SELECT @intStatusOrder = 
   CASE @intFolderStatus
      WHEN 10000 THEN 1          /* Application Accepted */
      WHEN 10001 THEN 2          /* In Review */
      WHEN 10002 THEN 6          /* Appeal Period - APP */
      WHEN 10003 THEN 8          /* Appeal Period - DEN */
      WHEN 10004 THEN 7          /* Appeal Period - PRC */
      WHEN 10005 THEN 14         /* Ready to Release */
      WHEN 10006 THEN 16         /* Released */
      WHEN 10007 THEN 37         /* Temp CO Issued */
      WHEN 10008 THEN 40         /* Final CO Issued */
      WHEN 10009 THEN 20         /* Appealed to DRB */
      WHEN 10010 THEN 41         /* Withdrawn */
      WHEN 10011 THEN 32         /* C of O Requested */
      WHEN 10012 THEN 39         /* FCO Pending */
      WHEN 10013 THEN 38         /* Temp CO Expired */
      WHEN 10014 THEN 3          /* Incomplete Application */
      WHEN 10015 THEN 5          /* Review Postponed */
      WHEN 10016 THEN 9          /* Appeal Period - DWP */
      WHEN 10017 THEN 21         /* Appealed to VSCED */
      WHEN 10018 THEN 15         /* Pre-Release Conditions */
      WHEN 10019 THEN 4          /* Review Waiting */
      WHEN 10020 THEN 24         /* Appeal Waiting */
      WHEN 10021 THEN 25         /* Appeal Postponed */
      WHEN 10022 THEN 10         /* Appeal Period - RVK */
      WHEN 10023 THEN 46         /* Permit Revoked */
      WHEN 10024 THEN 45         /* Permit Relinquished */
      WHEN 10025 THEN 36         /* TCO Pending */
      WHEN 10026 THEN 33         /* Incomplete CO App */
      WHEN 10027 THEN 11         /* Appeal Period - Determination */
      WHEN 10028 THEN 42         /* Superseded */
      WHEN 10029 THEN 47         /* Permit Indeterminate */
      WHEN 10030 THEN 98         /* Converted Data */
      WHEN 10031 THEN 17         /* Review Complete */
      WHEN 10032 THEN 19         /* Request Denied */
      WHEN 10033 THEN 26         /* Enforcement Upheld */
      WHEN 10034 THEN 27         /* Enforcement Overturned */
      WHEN 10035 THEN 34         /* CO Noncompliant */
      WHEN 10036 THEN 22         /* Appealed to VTSC */
      WHEN 10037 THEN 44         /* Permit Expired */
      WHEN 10038 THEN 28         /* Misc Admin Upheld */
      WHEN 10039 THEN 29         /* Misc Admin Overturned */
      WHEN 10040 THEN 35         /* CO Not Applicable */
      WHEN 10041 THEN 18         /* Master Plan Approved */
      WHEN 10042 THEN 43         /* Master Plan Expired */
      WHEN 10043 THEN 30         /* Permit Extension Requested */
      WHEN 10044 THEN 12         /* Appeal Period - GTEX */
      WHEN 10045 THEN 13         /* Appeal Period - DTEX */
      WHEN 10046 THEN 23         /* Appealed to USSC */
      WHEN 10047 THEN 31         /* Project Phasing */
      WHEN 10048 THEN 48         /* Permit Indeterminant */
      WHEN 10099 THEN 99         /* Dummy Status */
      ELSE 0
   END

   RETURN @intStatusOrder
END

GO
