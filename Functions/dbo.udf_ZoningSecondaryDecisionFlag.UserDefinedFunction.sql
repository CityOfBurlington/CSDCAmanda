USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningSecondaryDecisionFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningSecondaryDecisionFlag](@intFolderRSN INT)
RETURNS VARCHAR(2)
AS
BEGIN 
   /* Returns Y/N for whether or not a decision is a Primary decision (decision 
      on the permit application itself), or is a Secondary decision (e.g. Extend 
      the permit expiration date). Driven off of Appeal Period status codes. 
      Called by dbo.udf_ZoningAppealPeriodEndFolderStatus. 
      This is setup to accomodate future Secondary decision options, such as 
      acceptance of as-built plans. */

   DECLARE @intFolderStatus int
   DECLARE @varSecondaryFlag varchar(2)

   SELECT @intFolderStatus = Folder.StatusCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SET @varSecondaryFlag = '?'

   SELECT @varSecondaryFlag = 
     CASE @intFolderStatus 
        WHEN 10044 THEN 'Y'   /* Appeal Period - GTEX (Grant Time Extension) */
        WHEN 10045 THEN 'Y'   /* Appeal Period - DTEX (Deny Time Extension) */
        ELSE 'N'
     END

   RETURN @varSecondaryFlag
END

GO
