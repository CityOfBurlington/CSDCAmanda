USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningAppealPeriodEndFolderStatus]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningAppealPeriodEndFolderStatus](@intFolderRSN INT)
RETURNS INT
AS
BEGIN 
   /* Called by dbo.uspZoningFolderCleanup, and other processes. 
      Passes the next Folder.StatusCode value for folders whose appeal periods 
      have ended. 
      Functionality for Secondary Decisions (as opposed to Primary Decisions 
      on permit applications), is done using dbo.udf_ZoningSecondaryDecisionFlag 
      and FolderInfo Permit Picked Up. */

   DECLARE @varFolderType varchar(2)
   DECLARE @intStatusCode int
   DECLARE @intSubCode int
   DECLARE @intWorkCode int
   DECLARE @intNextStatusCode int
   DECLARE @varPermitPickedUp varchar(10)
   DECLARE @varSecondaryFlag varchar(2)
   DECLARE @intPermitDecision int

   SELECT @varFolderType = Folder.FolderType, 
          @intSubCode = Folder.SubCode,
          @intWorkCode = Folder.WorkCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varSecondaryFlag = dbo.udf_ZoningSecondaryDecisionFlag(@intFolderRSN)

   SELECT @varPermitPickedUp = ISNULL(FolderInfo.InfoValue, 'No')
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10023

   SET @intNextStatusCode = 10099       /* dummy status */

   /* For Secondary Decisions (post-permit-issuance), set @intStatusCode according 
      to the Primary Decision. */ 

   IF @varSecondaryFlag = 'Y'
   BEGIN
      SELECT @intPermitDecision = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)
      SELECT @intStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@intFolderRSN, @intPermitDecision)
   END
   ELSE   /* Primary Decisions on permit applications */
   BEGIN
      SELECT @intStatusCode = Folder.StatusCode 
        FROM Folder
       WHERE Folder.FolderRSN = @intFolderRSN 
   END

   IF @varFolderType = 'ZL'    /* Misc Appeals */
   BEGIN 
     IF @intWorkCode = 10004            /* Code Enforcement Appeal */
      BEGIN
         SELECT @intNextStatusCode = 
           CASE @intStatusCode
              WHEN 10002 THEN 10034     /* APP -> Enforcement Overturned */
              WHEN 10003 THEN 10033     /* DEN -> Enforcement Upheld */
           END
      END

      IF @intWorkCode = 10005            /* Misc Zoning Appeal */
      BEGIN
         SELECT @intNextStatusCode = 
           CASE @intStatusCode
              WHEN 10002 THEN 10039     /* APP -> Misc Admin Overturned */
              WHEN 10003 THEN 10038     /* DEN -> Misc Admin Upheld */
           END
      END
   END  

   IF @varFolderType = 'ZN'             /* Nonapplicabilities */
   BEGIN 
      SELECT @intNextStatusCode = 
      CASE @intStatusCode
         WHEN 10002 THEN 10031     /* APP -> Review Complete */
         WHEN 10003 THEN 10032     /* DEN -> Request Denied */
         WHEN 10004 THEN 10018     /* PRC -> Pre-Release Conditions */
         WHEN 10016 THEN 10032     /* DWP -> Request Denied */
         WHEN 10022 THEN 10023     /* RVK -> Permit Revoked */
      END
   END    /* End of ZN folders */

   IF @varFolderType = 'ZS'          /* Sketch Plan Review */
   BEGIN 
      SELECT @intNextStatusCode = 
        CASE @intStatusCode
           WHEN 10001 THEN 10031     /* In Review -> Review Complete */
        END
   END 

   IF @varFolderType = 'ZP'          /* Master Plan Review */
   BEGIN 
      SELECT @intNextStatusCode = 
        CASE @intStatusCode
           WHEN 10002 THEN 10041     /* APP -> Master Plan Approved */
           WHEN 10003 THEN 10032     /* DEN -> Request Denied */
           WHEN 10004 THEN 10018     /* PRC -> Pre-Release Conditions */
           WHEN 10016 THEN 10032     /* DWP -> Request Denied */
           WHEN 10022 THEN 10023     /* RVK -> Permit Revoked */
        END
   END 

   /* Other zoning folders */

   IF @varFolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZD', 'ZF', 'ZH') 
   BEGIN 
      SELECT @intNextStatusCode = 
        CASE @intStatusCode
           WHEN 10002 THEN 10005     /* APP -> Ready to Release */
           WHEN 10003 THEN 10032     /* DEN -> Request Denied */
           WHEN 10004 THEN 10018     /* PRC -> Pre-Release Conditions */
           WHEN 10016 THEN 10032     /* DWP -> Request Denied */
           WHEN 10022 THEN 10023     /* RVK -> Permit Revoked */
           WHEN 10027 THEN 10005     /* Determination -> Ready to Release */
        END

      IF ( @varSecondaryFlag = 'Y' AND @intNextStatusCode = 10005 AND @varPermitPickedUp <> 'No' )
         SELECT @intNextStatusCode = 10006 

   END    /* End of Z1, Z2, Z3, ZA, ZB, ZC, ZD, ZF, ZH folders */

   RETURN @intNextStatusCode
END

GO
