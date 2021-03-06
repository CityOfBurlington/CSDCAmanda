USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitDecisionReport]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      FUNCTION [dbo].[udf_GetZoningPermitDecisionReport](@intFolderRSN INT)
RETURNS VARCHAR(40)
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports */
   DECLARE @strAttemptDesc varchar(40)
   DECLARE @intAttemptCode int

   SET @strAttemptDesc = 'x'

   SELECT @intAttemptCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)

   SELECT @strAttemptDesc = 
   CASE @intAttemptCode
      WHEN 10002 THEN 'Permit Application Denied'
      WHEN 10003 THEN 'Permit Application Approved'
      WHEN 10006 THEN 'Misc Admin Decision Upheld on Appeal'
      WHEN 10007 THEN 'Misc Admin Decision Overturned on Appeal'
      WHEN 10011 THEN 'Permit Application Approved'
      WHEN 10017 THEN 'NonApplicability Affirmative'
      WHEN 10018 THEN 'NonApplicablity Adverse'
      WHEN 10020 THEN 'Permit Application Denied'
      WHEN 10046 THEN 'Determination Affirmative'
      WHEN 10047 THEN 'Determination Adverse'
      ELSE 'Unknown Outcome'
   END

   RETURN @strAttemptDesc
END

GO
