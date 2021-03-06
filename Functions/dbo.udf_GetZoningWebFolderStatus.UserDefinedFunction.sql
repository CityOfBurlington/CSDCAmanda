USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningWebFolderStatus]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningWebFolderStatus](@intFolderRSN INT) 
   RETURNS VARCHAR(70)
AS
BEGIN
   /* Returns a more complete folder status description for web site report */

   DECLARE @intStatusCode int
   DECLARE @varStatusDesc varchar(70)

   SELECT @intStatusCode = Folder.StatusCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN
 
   SELECT @varStatusDesc = 
     CASE @intStatusCode
     WHEN 10000 THEN 'Application Received'
     WHEN 10001 THEN 'In Review'
     WHEN 10002 THEN 'Appeal Period - Approved'
     WHEN 10003 THEN 'Appeal Period - Denied'
     WHEN 10004 THEN 'Appeal Period - Approved'
     WHEN 10005 THEN 'Permit Ready to Pick up'
     WHEN 10006 THEN 'Permit Picked Up'
     WHEN 10007 THEN 'Temporary Certificate of Occupancy Issued'
     WHEN 10008 THEN 'Final Certificate of Occupancy Issued'
     WHEN 10009 THEN 'Decision Appealed to Development Review Board'
     WHEN 10010 THEN 'Application Withdrawn'
     WHEN 10011 THEN 'Certificate of Occupancy Requested'
     WHEN 10012 THEN 'Final Certificate of Occupancy Pending'
     WHEN 10013 THEN 'Temporary Certificate of Occupancy Expired'
     WHEN 10014 THEN 'Application for Permit is Incomplete'
     WHEN 10015 THEN 'Review Postponed by Applicant'
     WHEN 10016 THEN 'Appeal Period - Denied'
     WHEN 10017 THEN 'Decision Appealed to VT Superior Court Environmental Division'
     WHEN 10018 THEN 'Permit has Pre-Release Conditions'
     WHEN 10019 THEN 'Review is Waiting for Information from Applicant'
     WHEN 10020 THEN 'Appeal is Waiting for Information from Applicant'
     WHEN 10021 THEN 'Appeal Postponed by Applicant'
     WHEN 10022 THEN 'Appeal Period - Permit Revoked'
     WHEN 10023 THEN 'Permit Revoked'
     WHEN 10024 THEN 'Permit Relinquished'
     WHEN 10025 THEN 'Temporary Certificate of Occupancy Pending'
     WHEN 10026 THEN 'Application for Certificate of Occupancy is Incomplete'
     WHEN 10027 THEN 'Appeal Period - Determination'
     WHEN 10028 THEN 'Permit Superceded by Another'
     WHEN 10029 THEN 'Permit Issued But Project Status is Unknown'
     WHEN 10030 THEN 'Converted Data from Access'
     WHEN 10031 THEN 'Review Complete'
     WHEN 10032 THEN 'Permit Request Denied'
     WHEN 10033 THEN 'Enforcement Upheld by Development Review Board'
     WHEN 10034 THEN 'Enforcement Overturned by Development Review Board'
     WHEN 10035 THEN 'Certificate of Occupancy Can Not Be Issued'
     WHEN 10036 THEN 'Decision Appealed to VT Supreme Court'
     WHEN 10037 THEN 'Permit Expired'
     WHEN 10038 THEN 'Misc Administrative Decision Upheld by Development Review Board'
     WHEN 10039 THEN 'Misc Administrative Decision Overturned by Development Review Board'
     WHEN 10040 THEN 'Certificate of Occupancy Can Not be Issued' 
     WHEN 10041 THEN 'Master Plan Approved by Development Review Board'
     WHEN 10042 THEN 'Master Plan Approval Expired'
     WHEN 10043 THEN 'Extension of Permit Expiration Requested' 
     WHEN 10044 THEN 'Appeal Period - Permit Expiration Extension Granted'
     WHEN 10045 THEN 'Appeal Period - Permit Expiration Extension Denied'
     WHEN 10046 THEN 'Decision Appealed to US Supreme Court'
     WHEN 10047 THEN 'Project Construction in Phases'
     WHEN 10048 THEN 'Permit Issued But Project Status is Unknown'
     ELSE 'Unknown Status'
     END
   RETURN @varStatusDesc
END
GO
