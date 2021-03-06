USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDRBAppealDecisionText]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDRBAppealDecisionText](@intFolderRSN INT)
RETURNS VARCHAR(60)
AS
BEGIN
/* For Appeal to DRB (10002) attempt results only */
DECLARE @intAppealAttemptResult int
DECLARE @intDecisionProcessCode int
DECLARE @intDecisionAttemptResult int
DECLARE @intDecisionOverturnAttemptText int 
DECLARE @varDRBAppealDecisionText varchar(50)

SET @varDRBAppealDecisionText = 'x'

SELECT @intAppealAttemptResult = dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10002)

SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intDecisionAttemptResult = dbo.udf_GetProcessAttemptCode(@intFolderRSN, @intDecisionProcessCode)

IF @intAppealAttemptResult = 10006         /* Uphold Admin Decision */
BEGIN
   SELECT @varDRBAppealDecisionText = 
   CASE @intDecisionAttemptResult
      WHEN 10002 THEN 'Permit Denial Upheld upon Appeal'
      WHEN 10003 THEN 'Permit Approval Upheld upon Appeal'
      WHEN 10006 THEN 'Administrative Decision Upheld upon Appeal'
      WHEN 10011 THEN 'Permit Approval Upheld upon Appeal'
      WHEN 10020 THEN 'Permit Denial Upheld upon Appeal'
      WHEN 10017 THEN 'Permit Not Required Upheld upon Appeal'
      WHEN 10018 THEN 'Permit Required Upheld upon Appeal'
      WHEN 10046 THEN 'Determination Affirmative Upheld upon Appeal'
      WHEN 10047 THEN 'Determination Adverse Upheld upon Appeal'
      ELSE 'Unknown Decision Attempt Result'
   END
END

IF @intAppealAttemptResult = 10007         /* Overturn Admin Decision */
BEGIN
   SELECT @varDRBAppealDecisionText = 
   CASE @intDecisionAttemptResult
      WHEN 10002 THEN 'Overturned and Permit Approved upon Appeal'
      WHEN 10003 THEN 'Overturned and Permit Denied upon Appeal'
      WHEN 10007 THEN 'Administrative Decision Overturned upon Appeal'
      WHEN 10011 THEN 'Overturned and Permit Denied upon Appeal'
      WHEN 10020 THEN 'Overturned and Permit Approved upon Appeal'
      WHEN 10017 THEN 'Overturned and Permit Required upon Appeal'
      WHEN 10018 THEN 'Overturned and Permit Not Required upon Appeal'
      WHEN 10046 THEN 'Overturned and Determination Adverse upon Appeal'
      WHEN 10047 THEN 'Overturned and Determination Affirmative upon Appeal'
      ELSE 'Unknown Decision Attempt Result'
   END
END
RETURN @varDRBAppealDecisionText
END

GO
