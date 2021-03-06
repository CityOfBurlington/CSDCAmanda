USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010020]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010020]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
   
/* Extend Permit Expiration (10020) version 1 */

/* Sec 3.2.9(d) enables property owners to request a 1 year extension of the permit 
   expiration date for approved permits. The extension can be granted administratively, 
   except for Conditional Uses and Variances, which must be reviewed by the DRB. */

/* The extension is one-year only, so it is calculated off of the existing 
   Permit Expiration Date (InfoCode 10024). */

/* This process is added by setting FolderInfo field Extend Permit Expiration (10078) 
   to Yes. Illogical use to extend the expiration date (i.e. denials, permits or 
   decision that do not expire) are rolled back by Info Validation. */ 

/* Subsequent time extensions requests are allowed by Info Validation when the 
   extension appeal period expiration date (ProcessInfo) is less than the 
   current date. */

/* The folder will go into an appeal period upon decision, and come out when appeal 
   period ends, reverting to the Folder Status for the permit. The appeal period is 
   controlled through FolderProcessInfo. This is the model that differentiates 
   Primary (permit application) decisions, from Secondary decisions such as this. */

/* Use a Zoning Miscellaneous Appeal (ZL) folder to track a subsequent appeal. 
   The process, Initiate Appeal, is not enabled as it is currently tailored to 
   appeals of primary decisions. While appeals of permit expiration time extensions 
   are unlikely, appeals of this and other secondary decisions may occur. If needed, 
   the solution is probably a new process, Initiate Secondary Appeal. This process 
   can then have logic for putting a folder back into its pre-secondary decision 
   status when done. */ 

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @StatusCode int
DECLARE @ExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @AdminChecklistPass varchar(1)
DECLARE @DRBChecklistPass varchar(1)

DECLARE @AdminDecDateCount int
DECLARE @AdminDecDateOrder int
DECLARE @DRBMeetingDateCount int
DECLARE @DRBMeetingDateOrder int
DECLARE @DRBPHClosedDateCount int
DECLARE @DRBPHClosedDateOrder int
DECLARE @DRBDelibMeetingDateCount int
DECLARE @DRBDelibMeetingDateOrder int
DECLARE @DRBDelibDecisionCount int
DECLARE @DRBDelibDecisionOrder int
DECLARE @DRBDecisonDateCount int
DECLARE @DRBDecisonDateOrder int
DECLARE @AppealExpiryDateCount int
DECLARE @AppealExpiryDateOrder int

DECLARE @EPEAttemptCount int
DECLARE @intEPEAttemptResultPrevious int
DECLARE @ConstructionStartDate datetime
DECLARE @ConstructionStartDateNew datetime
DECLARE @PermitExpiryDate datetime 
DECLARE @PermitExpiryDateNew datetime
DECLARE @NextStatusCode int
DECLARE @FolderCommentText varchar(50)
DECLARE @ProcessCommentText varchar(50)
DECLARE @dtAdminDecisionDate datetime
DECLARE @dtDRBDecisionDate datetime
DECLARE @dtDecisionDate datetime
DECLARE @dtExpiryDate datetime

DECLARE @fltPublicHearingFee float
DECLARE @fltOtherDRBFee float
DECLARE @varPublicHearingFlag varchar(2)
DECLARE @fltTimeExtensionFee float
DECLARE @intFeeCode int

DECLARE @intExpiryLetterDoc int
DECLARE @dtExpiryLetterGen datetime

/* Get attempt result, and other folder values. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType, 
       @StatusCode = Folder.StatusCode, 
       @ExpiryDate = Folder.ExpiryDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @ConstructionStartDate = dbo.f_info_date(@FolderRSN, 10127) 
SELECT @PermitExpiryDate = dbo.f_info_date(@FolderRSN, 10024)  

SELECT @EPEAttemptCount = COUNT(*)
  FROM FolderProcessAttempt, FolderProcess
 WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
   AND FolderProcessAttempt.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10020 

IF @EPEAttemptCount = 1 AND @AttemptResult <> 10059
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('The first attempt result must be Setup for Time Extension.', 16, -1)
   RETURN
END 

IF @EPEAttemptCount > 1		/* Subsequent extension resquests */
BEGIN
	SELECT @intEPEAttemptResultPrevious = FolderProcessAttempt.ResultCode
	FROM FolderProcessAttempt, FolderProcess
	WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
	AND FolderProcessAttempt.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessCode = 10020 
	AND FolderProcessAttempt.AttemptRSN = 
	(	SELECT MAX(FolderProcessAttempt.AttemptRSN) - 1
		FROM FolderProcessAttempt, FolderProcess
		WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
		AND FolderProcessAttempt.FolderRSN = @FolderRSN
		AND FolderProcess.ProcessCode = 10020  )

	IF @intEPEAttemptResultPrevious <> 10059 AND @AttemptResult <> 10059
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR ('PLease run Setup for Time Extension prior to Granting or Denying the request.', 16, -1)
		RETURN
	END
END 

SELECT @AdminChecklistPass = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @ProcessRSN
   AND FolderProcessChecklist.ChecklistCode = 10000       /* Administrative Review */

SELECT @DRBChecklistPass = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @ProcessRSN
   AND FolderProcessChecklist.ChecklistCode = 10003       /* DRB Review */

IF @AdminChecklistPass <> 'Y' AND @DRBChecklistPass <> 'Y'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please choose Admin or DRB review (Checklist) in order to proceed.', 16, -1)
   RETURN
END

IF @AdminChecklistPass = 'Y' AND @DRBChecklistPass = 'Y'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('The checklist shows both Admin and DRB review. Please set one to No.', 16, -1)
   RETURN
END

IF @DRBChecklistPass <> 'Y' AND @WorkCode IN (10000, 10002, 10003)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('The DRB is required to review requests for Conditional Use, Major Impact, and Variance. Please correct.', 16, -1)
   RETURN
END

/* Set ProcessInfo field parameters. */

SELECT @AdminDecDateCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10003) 
SELECT @DRBMeetingDateCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10004) 
SELECT @DRBPHClosedDateCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10005) 
SELECT @DRBDelibMeetingDateCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10006) 
SELECT @DRBDelibDecisionCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10007) 
SELECT @DRBDecisonDateCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10008) 
SELECT @AppealExpiryDateCount = dbo.udf_ProcessInfoFieldExists(@ProcessRSN, 10009) 

SELECT @AdminDecDateOrder = 10
SELECT @DRBMeetingDateOrder = 20 
SELECT @DRBPHClosedDateOrder = 30
SELECT @DRBDelibMeetingDateOrder = 40
SELECT @DRBDelibDecisionOrder = 50
SELECT @DRBDecisonDateOrder = 60
SELECT @AppealExpiryDateOrder = 70

/* Setup for Time Extension attempt result. */

IF @AttemptResult = 10059
BEGIN
   UPDATE Folder 
      SET Folder.StatusCode = 10043, 
		  Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Permit Expiration Extension Requested (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN 

    /* If a permit was reviewed by the DRB, any time extensions must also be considered by the DRB. 
	Insert public hearing fee for Conditional Use, Major Impact, and Variance permits, or insert the DRB Other Matters fee;  insert filing fee. 
	In the case of separate but paired permits for a project, e.g. conditional use and COA, the CU/Var fee is inserted in the ZH folder. */  
 
	IF @SubCode = 10042		/* DRB Review */
	BEGIN
		SELECT @fltPublicHearingFee = ValidLookup.LookupFee	/* CU/Var Fee */
		FROM ValidLookup 
		WHERE ValidLookup.LookupCode = 3 
		AND ValidLookup.Lookup1 = 19 
	  
		SELECT @fltOtherDRBFee = ValidLookup.LookupFee			/* Other Matters DRB Hearing */  
		FROM ValidLookup 
		WHERE ValidLookup.LookupCode = 3 
		AND ValidLookup.Lookup1 = 28 
		
		SELECT @varPublicHearingFlag = dbo.udf_ZoningPublicHearingFlag(@FolderRSN)
		
		IF @varPublicHearingFlag = 'Y' SELECT @fltTimeExtensionFee = @fltPublicHearingFee 
		ELSE SELECT @fltTimeExtensionFee = @fltOtherDRBFee
		
		SELECT @intFeeCode = dbo.udf_GetZoningFeeCodeApplication(@FolderRSN)
		
		SELECT @NextRSN = @NextRSN + 1 
		INSERT INTO AccountBillFee 
			( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
				FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
			VALUES ( @NextRSN, @FolderRSN, @intFeeCode, 'Y', 
							@fltTimeExtensionFee, 0, 0, getdate(), @UserId )

		EXECUTE dbo.usp_Zoning_Insert_Fee_Filing  @FolderRSN, @UserID
   END 

   IF @AdminChecklistPass = 'Y' SELECT @ProcessCommentText = 'Admin' 
   IF @DRBChecklistPass = 'Y' SELECT @ProcessCommentText = 'DRB' 

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = @ProcessCommentText 
    WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
      AND FolderProcessAttempt.AttemptRSN = 
        ( SELECT max(FolderProcessAttempt.AttemptRSN) 
         FROM FolderProcessAttempt
           WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   IF @AppealExpiryDateCount = 0 
   BEGIN
      INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
         VALUES ( @ProcessRSN, 10009, @AppealExpiryDateOrder, @FolderRSN )
   END

   IF @AppealExpiryDateCount > 0 AND @AdminChecklistPass = 'N' AND @DRBChecklistPass = 'N' 
   BEGIN
   DELETE FROM FolderProcessInfo 
       WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
         AND FolderProcessInfo.InfoCode= 10009 
   END

   IF @AppealExpiryDateCount > 0 
   BEGIN
      UPDATE FolderProcessInfo 
         SET FolderProcessInfo.InfoValue = NULL, 
             FolderProcessInfo.InfoValueDateTime = NULL, 
             FolderProcessInfo.StampDate = getdate(), 
             FolderProcessInfo.StampUser = @UserID 
       WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
         AND FolderProcessInfo.InfoCode = 10009 
   END

   IF @AdminChecklistPass = 'Y' AND @AdminDecDateCount = 0 
   BEGIN
      INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
      VALUES ( @ProcessRSN, 10003, @AdminDecDateOrder, @FolderRSN )
   END 

   IF @AdminChecklistPass = 'Y' AND @AdminDecDateCount > 0 
   BEGIN
      UPDATE FolderProcessInfo 
         SET FolderProcessInfo.InfoValue = NULL, 
             FolderProcessInfo.InfoValueDateTime = NULL, 
             FolderProcessInfo.StampDate = getdate(), 
             FolderProcessInfo.StampUser = @UserID 
       WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
         AND FolderProcessInfo.InfoCode = 10003 
   END

   IF @AdminChecklistPass = 'N' AND @AdminDecDateCount > 0 
   BEGIN
      DELETE FROM FolderProcessInfo 
       WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
         AND FolderProcessInfo.InfoCode= 10003 
   END

   IF @DRBChecklistPass = 'Y' 
   BEGIN
      IF @DRBMeetingDateCount = 0 
      BEGIN
         INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
         VALUES ( @ProcessRSN, 10004, @DRBMeetingDateOrder, @FolderRSN ) 
      END

      IF @DRBMeetingDateCount > 0 
      BEGIN
         UPDATE FolderProcessInfo 
            SET FolderProcessInfo.InfoValue = NULL, 
                FolderProcessInfo.InfoValueDateTime = NULL, 
                FolderProcessInfo.StampDate = getdate(), 
                FolderProcessInfo.StampUser = @UserID 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
            AND FolderProcessInfo.InfoCode = 10004 
      END

      IF @DRBPHClosedDateCount = 0 
      BEGIN
         INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
         VALUES ( @ProcessRSN, 10005, @DRBPHClosedDateOrder, @FolderRSN ) 
      END

      IF @DRBPHClosedDateCount > 0 
      BEGIN
         UPDATE FolderProcessInfo 
            SET FolderProcessInfo.InfoValue = NULL, 
                FolderProcessInfo.InfoValueDateTime = NULL, 
                FolderProcessInfo.StampDate = getdate(), 
                FolderProcessInfo.StampUser = @UserID 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
            AND FolderProcessInfo.InfoCode = 10005 
      END

      IF @DRBDelibMeetingDateCount = 0 
      BEGIN
         INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
         VALUES ( @ProcessRSN, 10006, @DRBDelibMeetingDateOrder, @FolderRSN ) 
      END

      IF @DRBDelibMeetingDateCount > 0 
      BEGIN
         UPDATE FolderProcessInfo 
            SET FolderProcessInfo.InfoValue = NULL, 
                FolderProcessInfo.InfoValueDateTime = NULL, 
                FolderProcessInfo.StampDate = getdate(), 
                FolderProcessInfo.StampUser = @UserID 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
            AND FolderProcessInfo.InfoCode = 10006 
      END

      IF @DRBDelibDecisionCount = 0 
      BEGIN
         INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
         VALUES ( @ProcessRSN, 10007, @DRBDelibDecisionOrder, @FolderRSN ) 
      END

      IF @DRBDelibDecisionCount > 0 
      BEGIN
         UPDATE FolderProcessInfo 
            SET FolderProcessInfo.InfoValue = NULL, 
                FolderProcessInfo.InfoValueDateTime = NULL, 
                FolderProcessInfo.StampDate = getdate(), 
                FolderProcessInfo.StampUser = @UserID 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
            AND FolderProcessInfo.InfoCode = 10007 
      END

      IF @DRBDecisonDateCount = 0 
      BEGIN
         INSERT INTO FolderProcessInfo ( ProcessRSN, InfoCode, DisplayOrder, FolderRSN )
         VALUES ( @ProcessRSN, 10008, @DRBDecisonDateOrder, @FolderRSN ) 
      END

      IF @DRBDecisonDateCount > 0 
      BEGIN
         UPDATE FolderProcessInfo 
            SET FolderProcessInfo.InfoValue = NULL, 
                FolderProcessInfo.InfoValueDateTime = NULL, 
                FolderProcessInfo.StampDate = getdate(), 
                FolderProcessInfo.StampUser = @UserID 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
            AND FolderProcessInfo.InfoCode = 10008 
      END
   END

   IF @DRBChecklistPass = 'N' 
   BEGIN
      IF @DRBMeetingDateCount > 0 
      BEGIN
         DELETE FROM FolderProcessInfo 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
            AND FolderProcessInfo.InfoCode= 10004 
      END
      IF @DRBPHClosedDateCount > 0 
      BEGIN
         DELETE FROM FolderProcessInfo 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
            AND FolderProcessInfo.InfoCode= 10005 
      END
      IF @DRBDelibMeetingDateCount > 0 
      BEGIN
         DELETE FROM FolderProcessInfo 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
            AND FolderProcessInfo.InfoCode= 10006 
      END
      IF @DRBDelibDecisionCount > 0 
      BEGIN
         DELETE FROM FolderProcessInfo 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
            AND FolderProcessInfo.InfoCode= 10007 
      END
 IF @DRBDecisonDateCount > 0 
      BEGIN
         DELETE FROM FolderProcessInfo 
          WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN 
        AND FolderProcessInfo.InfoCode= 10008 
  END
 END
END

/* Grant and Deny Extension attempt results. Puts folder into appeal period. 
   The current time is added to the decision date so folder comes out of its 
   appeal period on the correct day (not a day early). 
   One year is automatically added to the Permit Expiration Date with the 
   Grant Appeal attempt result. If a subsequent appeal overturned that decision, 
   then the Permit Expiration Date would have to manually set back one year. 
   Extend Permit Expiration (FolderInfo 10078) is set back to No for reuse. */

IF @AttemptResult IN (10060, 10061) 
BEGIN

   SELECT @dtAdminDecisionDate = FolderProcessInfo.InfoValueDateTime
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
  AND FolderProcessInfo.InfoCode = 10003

   SELECT @dtDRBDecisionDate = FolderProcessInfo.InfoValueDateTime
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
      AND FolderProcessInfo.InfoCode = 10008

   IF @AdminChecklistPass = 'Y'
   BEGIN
      IF @dtAdminDecisionDate IS NULL 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Please enter the Admin Decision Date (ProcessInfo) to proceed', 16, -1)
         RETURN
      END
      ELSE EXECUTE dbo.usp_FolderProcessInfo_Date_Add_Time @ProcessRSN, 10003 

      SELECT @dtDecisionDate = FolderProcessInfo.InfoValueDateTime
        FROM FolderProcessInfo
       WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
         AND FolderProcessInfo.InfoCode = 10003

      SELECT @dtExpiryDate = DATEADD(day, 15, @dtDecisionDate) 
   END

   IF @DRBChecklistPass = 'Y' 
   BEGIN
      IF @dtDRBDecisionDate IS NULL
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Please enter the DRB Decision Date (ProcessInfo) to proceed', 16, -1)
         RETURN
      END
      ELSE EXECUTE dbo.usp_FolderProcessInfo_Date_Add_Time @ProcessRSN, 10008 

      SELECT @dtDecisionDate = FolderProcessInfo.InfoValueDateTime
       FROM FolderProcessInfo
       WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
         AND FolderProcessInfo.InfoCode = 10008

      SELECT @dtExpiryDate = DATEADD(day, 30, @dtDecisionDate) 
   END 

   UPDATE FolderProcessInfo 
      SET FolderProcessInfo.InfoValue = CONVERT(CHAR(11), @dtExpiryDate), 
          FolderProcessInfo.InfoValueDateTime = @dtExpiryDate, 
          FolderProcessInfo.FolderRSN = @FolderRSN, 
          FolderProcessInfo.StampDate = getdate(), 
          FolderProcessInfo.StampUser = @UserID 
    WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
      AND FolderProcessInfo.InfoCode = 10009 

   SELECT @FolderCommentText = 
   CASE @AttemptResult 
      WHEN 10060 THEN ' -> Decision: Time Extension Granted (' + CONVERT(CHAR(11), @dtDecisionDate) + ')' 
      WHEN 10061 THEN ' -> Decision: Time Extension Denied (' + CONVERT(CHAR(11), @dtDecisionDate) + ')' 
      ELSE ' -> unknown attempt result (' 
   END

   SELECT @ProcessCommentText = 
   CASE @AttemptResult 
      WHEN 10060 THEN 'Granted ('  + CONVERT(CHAR(11), @dtDecisionDate) + ')'
      WHEN 10061 THEN 'Denied (' + CONVERT(CHAR(11), @dtDecisionDate) + ')'
      ELSE ' -> unknown attempt result' 
   END 

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = @ProcessCommentText 
    WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
      AND FolderProcessAttempt.AttemptRSN = 
        ( SELECT max(FolderProcessAttempt.AttemptRSN) 
            FROM FolderProcessAttempt
           WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @AttemptResult)

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, 
          Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + @FolderCommentText)) 
    WHERE Folder.FolderRSN = @FolderRSN 

   IF @AttemptResult = 10060      /* Grant Extension */
   BEGIN
      SELECT @ConstructionStartDateNew = DATEADD(year, 1, @ConstructionStartDate)
      SELECT @PermitExpiryDateNew = DATEADD(year, 1, @PermitExpiryDate) 

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = CONVERT(CHAR(11), @ConstructionStartDateNew), 
             FolderInfo.InfoValueDateTime = @ConstructionStartDateNew, 
             FolderInfo.StampDate = getdate(), FolderInfo.StampUser = @UserID 
       WHERE FolderInfo.FolderRSN = @FolderRSN 
         AND FolderInfo.InfoCode = 10127 

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = CONVERT(CHAR(11), @PermitExpiryDateNew), 
             FolderInfo.InfoValueDateTime = @PermitExpiryDateNew, 
             FolderInfo.StampDate = getdate(), FolderInfo.StampUser = @UserID 
       WHERE FolderInfo.FolderRSN = @FolderRSN 
         AND FolderInfo.InfoCode = 10024 

      UPDATE Folder
         SET Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Permit Expiration Extended to ' + CONVERT(CHAR(11), @PermitExpiryDateNew))) 
       WHERE Folder.FolderRSN = @FolderRSN 

      UPDATE FolderInfo
         SET FolderInfo.InfoValue = 'No', FolderInfo.InfoValueUpper = 'NO', 
             FolderInfo.StampDate = getdate(), FolderInfo.StampUser = @UserID 
       WHERE FolderInfo.FolderRSN = @FolderRSN 
         AND FolderInfo.InfoCode = 10078
   END
END

/* Re-open process for Setup for Time Extension attempt result. */

IF @AttemptResult = 10059
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN
END

/* For subsequent time extensions, null out Checklist values for Grant and Deny 
   attempt results. Add Expiration Letter document (which is worded for approvals). */

IF @AttemptResult IN (10060, 10061)
BEGIN
   UPDATE FolderProcessChecklist
      SET FolderProcessChecklist.Passed = NULL, 
          FolderProcessChecklist.StartDate = NULL, 
          FolderProcessChecklist.EndDate = NULL
    WHERE FolderProcessChecklist.ProcessRSN = @ProcessRSN
      AND FolderProcessChecklist.ChecklistCode = 10000 /* Administrative Review */

   UPDATE FolderProcessChecklist
      SET FolderProcessChecklist.Passed = NULL, 
          FolderProcessChecklist.StartDate = NULL, 
          FolderProcessChecklist.EndDate = NULL
    WHERE FolderProcessChecklist.ProcessRSN = @ProcessRSN
      AND FolderProcessChecklist.ChecklistCode = 10003       /* DRB Review */

   SELECT @intExpiryLetterDoc = COUNT(*)
   FROM FolderDocument
   WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10009

   SELECT @dtExpiryLetterGen = FolderDocument.DateGenerated
   FROM FolderDocument
   WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10009

   IF @intExpiryLetterDoc = 0 OR @dtExpiryLetterGen IS NOT NULL
   BEGIN 
      SELECT @NextDocumentRSN = @NextDocumentRSN + 1
      INSERT INTO FolderDocument
         ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
           DisplayOrder, StampDate, StampUser, LinkCode )
      VALUES ( @FolderRSN, 10009, 1, @NextDocumentRSN, 80, getdate(), @UserID, 1 )  
   END
END

GO
