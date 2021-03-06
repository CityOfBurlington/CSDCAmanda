USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitDecisionReportOrder]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitDecisionReportOrder](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports */
   DECLARE @intReportOrder int
   DECLARE @intAttemptCode int

   SET @intReportOrder = 0

   SELECT @intAttemptCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)

   SELECT @intReportOrder = 
   CASE @intAttemptCode
      WHEN 10002 THEN 2      /* Permit Application Denied */
      WHEN 10003 THEN 1      /* Permit Application Approved */
      WHEN 10006 THEN 7      /* Misc Admin Decision Upheld on Appeal */
      WHEN 10007 THEN 8      /* Misc Admin Decision Overturned on Appeal */
      WHEN 10011 THEN 1      /* Permit Application Approved */
      WHEN 10017 THEN 3      /* NonApplicability Affirmative */
      WHEN 10018 THEN 4      /* NonApplicablity Adverse */
      WHEN 10020 THEN 2      /* Permit Application Denied */
      WHEN 10046 THEN 5      /* Determination Affirmative */
      WHEN 10047 THEN 6      /* Determination Adverse */
      ELSE 9                 /* Unknown Outcome */
   END

   RETURN @intReportOrder
END


GO
