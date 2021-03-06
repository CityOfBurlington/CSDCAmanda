USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAppealFiledReport]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAppealFiledReport](@intResultCode INT)
RETURNS VARCHAR(60)
AS
BEGIN
   /* Used by Infomaker forms, pz_director_reports */
   DECLARE @strAttemptDesc varchar(60)

   SET @strAttemptDesc = 'x'

   SELECT @strAttemptDesc = 
   CASE @intResultCode
      WHEN 10015 THEN 'Administrative Decision Appealed to DRB'
      WHEN 10016 THEN 'DRB Decision Appealed to VSCED'
      WHEN 10064 THEN 'VSCED Decision Appealed to VT Supreme Court'
      WHEN 10065 THEN 'VT Supreme Court Decision Appealed to US Supreme Court'
      ELSE 'Unknown Appeal'
   END

   RETURN @strAttemptDesc
END
GO
