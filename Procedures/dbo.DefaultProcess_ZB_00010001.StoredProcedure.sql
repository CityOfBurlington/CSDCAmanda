USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010001]    Script Date: 9/9/2013 9:56:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010001]
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
   
/* Certificate of Occupancy (10001) version 4 */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @AttemptNumber int
DECLARE @InspectorCheck int
DECLARE @Inspector varchar(10)
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @NextStatusCode int
DECLARE @InDate datetime
DECLARE @IssueDate datetime
DECLARE @ZPNumber varchar(10)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @NextWorkCode int
DECLARE @ParentRSN int
DECLARE @PropertyRSN int
DECLARE @varPreReleaseConditionsFlag varchar(2)
DECLARE @PermitPickedUp varchar(10)
DECLARE @OwnerPeopleRSN int
DECLARE @CORequester int
DECLARE @ZZProjectDecisionAttempt int
DECLARE @RequestSignedBy varchar(50)
DECLARE @FCOSitePlanOrder int
DECLARE @FCOSitePlanInfoField int
DECLARE @FCOSitePlanValue varchar(20)
DECLARE @FCODecDateOrder int
DECLARE @FCODecDateInfoField int
DECLARE @FCODecDateValue datetime
DECLARE @FCOFeeText1 varchar(60)
DECLARE @FCOFeeText2 varchar(60)
DECLARE @FCOFeeText varchar(120)
DECLARE @TCOTermOrder int
DECLARE @TCOTermInfoField int
DECLARE @TCOTermValue int
DECLARE @TCODecDateOrder int
DECLARE @TCODecDateInfoField int
DECLARE @TCODecDateValue datetime
DECLARE @TCOExpiryDateOrder int
DECLARE @TCOExpiryDateInfoField int
DECLARE @TCOExpiryDateValue datetime
DECLARE @TCODoc int
DECLARE @TCODocNotGenerated int
DECLARE @TCODocDisplayOrder int
DECLARE @ApplicationFee float
DECLARE @TCOFee float
DECLARE @FCOFeeExists int 
DECLARE @FCOFilingFeeExists int 
DECLARE @FCOFee float
DECLARE @FCOFilingFee float
DECLARE @FilingFeeHistoric float
DECLARE @ATFCOFeeExists int
DECLARE @ATFCOFee float

/* Get attempt result and number of attempt results for this process. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode, 
       @AttemptDate = FolderProcessAttempt.AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       (SELECT max(FolderProcessAttempt.AttemptRSN) 
          FROM FolderProcessAttempt
         WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @AttemptNumber = COUNT(*)
  FROM FolderProcessAttempt, FolderProcess
 WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10001

/* Get Folder Type, Folder Status, Application Date, ZP Number, SubCode, WorkCode, 
   Parent RSN, and PropertyRSN. */

SELECT @FolderType = Folder.FolderType, @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate, @IssueDate = Folder.IssueDate,
       @ZPNumber = Folder.ReferenceFile, @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode, @ParentRSN = Folder.ParentRSN, @PropertyRSN = Folder.PropertyRSN
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

/* For ZZ folders, check to make sure the Project Decision - Historic process has been run */

IF @FolderType = 'ZZ'
BEGIN
   SELECT @ZZProjectDecisionAttempt = count(*)
     FROM FolderProcessAttempt, FolderProcess
    WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.ProcessCode = 10014
      AND FolderProcess.FolderRSN = @FolderRSN

   IF @ZZProjectDecisionAttempt = 0 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR('Please enter the decision using the Project Decision Historic process in order to proceed.', 16, -1)
      RETURN
   END
END

/* Check to make sure C of O Requested or CO Not Applicable is the first attempt result. */

IF @AttemptNumber = 1 AND @AttemptResult NOT IN(10001, 10023)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please select C of O Requested or CO Not Appliable in order to proceed.', 16, -1)
   RETURN
END

/* Check Folder Status to insure permit has been released, and that any Pre-Release 
   Conditions have been met. Checks apply for CO Requested only. */

IF @AttemptResult = 10001
BEGIN
   SELECT @varPreReleaseConditionsFlag = dbo.udf_ZoningPreReleaseConditionsFlag(@FolderRSN)

   IF ( @FolderStatus = 10018 OR @varPreReleaseConditionsFlag = 'Y' ) 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Zoning permit has unmet Pre-Release Conditions: CO can not be started.', 16, -1)
      RETURN
   END

   SELECT @PermitPickedUp = FolderInfo.InfoValueUpper
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10023

   IF @PermitPickedUp NOT IN ('MAILED', 'YES')
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Zoning permit has not been Picked Up from P+Z: CO can not be started.', 16, -1)
      RETURN
   END
END

/* Get Info field information for Temp and Final CO; and Temp CO document. */

SELECT @TCOTermOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10070)
SELECT @TCOTermInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10070) 
SELECT @TCOTermValue = dbo.f_info_numeric_null(@FolderRSN, 10070)

SELECT @TCODecDateOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10071)
SELECT @TCODecDateInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10071) 
SELECT @TCODecDateValue = dbo.f_info_date(@FolderRSN, 10071)

SELECT @TCOExpiryDateOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10072)
SELECT @TCOExpiryDateInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10072) 
SELECT @TCOExpiryDateValue = dbo.f_info_date(@FolderRSN, 10072)

SELECT @FCODecDateOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10073)
SELECT @FCODecDateInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10073) 
SELECT @FCODecDateValue = dbo.f_info_date(@FolderRSN, 10073)

SELECT @FCOSitePlanOrder   = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10074)
SELECT @FCOSitePlanInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10074) 
SELECT @FCOSitePlanValue = UPPER(dbo.f_info_alpha_null(@FolderRSN, 10074))

SELECT @TCODoc = COUNT(*) 
FROM FolderDocument 
WHERE FolderDocument.FolderRSN = @FolderRSN 
AND FolderDocument.DocumentCode = 20000 

SELECT @TCODocNotGenerated = COUNT(*)
FROM FolderDocument 
WHERE FolderDocument.FolderRSN = @FolderRSN 
AND FolderDocument.DocumentCode = 20000 
AND FolderDocument.DateGenerated IS NULL 

SELECT @TCODocDisplayOrder = 70 + @TCODoc

/* Certificate of Occupancy Requested attempt result */
/* Notes:  
   1) - The process has checklists to assign an inspector as ther AssignUser to the 
        this process. Their use is optional. If no inspector is chosen, the AssignedUser is null.
   2) - As the result of the Bianchi decision, starting on July 1, 1998, filing fees 
        started being charged - one page for the permit, and one page for the CO. 
   3) - Process Info has a field for the name of the person requesting the CO. It is required as backup documentation. 
        NOTE: This requirement was removed per request of Code Enforcement on 9/7/2012 - Dana Baron
   4) - The current owner of the property is inserted in FolderPeople as PeopleCode CO Requester. This will be pulled for the Final CO form. 
*/

IF @AttemptResult = 10001               /* C of O Requested */
BEGIN
/* - Removed 9/7/2012 - Dana Baron
   SELECT @RequestSignedBy = FolderProcessInfo.InfoValue
     FROM FolderProcessInfo
   WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
      AND FolderProcessInfo.InfoCode = 10001

   IF @RequestSignedBy IS NULL
   BEGIN
     ROLLBACK TRANSACTION
      RAISERROR ('Please enter the name of the person who signed the C of O request form in Process Info', 16, -1)
      RETURN
   END
*/
   SELECT @InspectorCheck = count(*) 
     FROM FolderProcessCheckList, FolderProcess
    WHERE FolderProcess.ProcessRSN = FolderProcessCheckList.ProcessRSN 
      AND FolderProcessCheckList.FolderRSN = @FolderRSN 
      AND FolderProcess.ProcessCode = 10001
      AND FolderProcessCheckList.Passed = 'Y'

   IF @InspectorCheck > 1 
   BEGIN
      ROLLBACK TRANSACTION
  RAISERROR('Please select only one inspector from checklist', 16, -1)
      RETURN
   END

   IF @InspectorCheck = 0 SELECT @Inspector = NULL
   IF @InspectorCheck = 1
   BEGIN
      SELECT @Inspector = ValidUser.UserId
 FROM FolderProcessCheckList, FolderProcess, ValidCheckList, ValidUser 
       WHERE FolderProcess.ProcessRSN = FolderProcessCheckList.ProcessRSN 
         AND FolderProcessCheckList.CheckListCode = ValidCheckList.CheckListCode
         AND ValidCheckList.CheckListDesc = ValidUser.UserName
         AND FolderProcessCheckList.FolderRSN = @FolderRSN 
         AND FolderProcess.ProcessCode = 10001
         AND FolderProcessCheckList.Passed = 'Y'
   END

   UPDATE FolderProcess
      SET FolderProcess.AssignedUser = @Inspector, 
          FolderProcess.StartDate = @AttemptDate
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

   UPDATE Folder
      SET Folder.StatusCode = 10011, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> C of O Requested (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'C of O Requested (' + CONVERT(CHAR(11), @AttemptDate) + ')'
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'C of O Requested (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   /* Insert current property owner as PeopleCode CO Requester (325). */

   SELECT TOP 1 @OwnerPeopleRSN = PropertyPeople.PeopleRSN
     FROM PropertyPeople
  WHERE PropertyPeople.PropertyRSN = @PropertyRSN 
      AND PropertyPeople.PeopleCode = 2

   IF @OwnerPeopleRSN IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('There is not an Owner for the property record. An owner is required for CO issuance.', 16, -1)
      RETURN
   END

   SELECT @CORequester = COUNT(*) 
  FROM FolderPeople
    WHERE FolderPeople.PeopleRSN = @OwnerPeopleRSN 
      AND FolderPeople.FolderRSN = @FolderRSN 
      AND FolderPeople.PeopleCode = 325

   IF @CORequester = 0
   BEGIN
      INSERT INTO FolderPeople
                 (FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampUser, StampDate, 
                  Comments) 
          VALUES (@FolderRSN, 325, @OwnerPeopleRSN, 'Y', @UserID, getdate(), 
                  'Property Owner at CO Request')
   END

END      /* end of CO Requested attempt result */

/* Submission Incomplete attempt result */

IF @AttemptResult = 10000     /* Submission Incomplete */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10026,
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Submission for C of O Incomplete (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Submission Incomplete (' + CONVERT(CHAR(11), @AttemptDate) + ')'
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Submission Incomplete (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Site Inspection Failed attempt result */

IF @AttemptResult = 10042              /* Site Inspection - Failed */
BEGIN
	SELECT @NextStatusCode = 
	CASE @FolderStatus
		WHEN 10011 THEN 10035			/* CO Noncompliant */
		WHEN 10026 THEN 10035
		WHEN 10025 THEN 10035
		WHEN 10012 THEN 10035
		WHEN 10007 THEN 10007			/* Temp CO Issued */
		WHEN 10013 THEN 10013			/* Temp CO Expired */
		ELSE 10035
	END

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Site Inspection for CO - Project does not Comply with Permit (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Site Inspection - Failed (' + CONVERT(CHAR(11), @AttemptDate) + ')'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Site Inspection - Failed (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Site Inspection Set Up for TCO attempt result */
/* Disabled and replaced by UC folder Temp CO  18-Dec-2012 JA */
/* Re-enabled 12-Feb-13 JA */ 

IF @AttemptResult = 10043              /* Site Inspection - Set Up for TCO */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10025,
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Site Inspection for CO (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Site Inspection - Set Up for Temp C of O (' + CONVERT(CHAR(11), @AttemptDate) + ')'
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Site Inspection - Set Up for TCO (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   IF @TCOTermInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 10070,  @TCOTermOrder, 'Y', getdate(), @UserID, 'N', 'N' )
  END
  ELSE
  BEGIN
		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueNumeric = NULL
		WHERE FolderInfo.FolderRSN = @FolderRSN
		AND FolderInfo.InfoCode = 10070
   END

   IF @TCODecDateInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
      ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 10071,  @TCODecDateOrder, 'Y', getdate(), @UserID, 'N', 'N' )
   END
   ELSE
   BEGIN
		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
		WHERE FolderInfo.FolderRSN = @FolderRSN
		AND FolderInfo.InfoCode = 10071
   END

   IF @TCOExpiryDateInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 10072,  @TCOExpiryDateOrder, 'Y', getdate(), @UserID, 'N', 'N' )
   END
   ELSE
   BEGIN
		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
		WHERE FolderInfo.FolderRSN = @FolderRSN
		AND FolderInfo.InfoCode = 10072
   END

   IF @TCODocNotGenerated = 0 
   BEGIN
      SELECT @NextDocumentRSN = @NextDocumentRSN + 1
      INSERT INTO FolderDocument
                  ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
         DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 20000, 1, @NextDocumentRSN, @TCODocDisplayOrder, getdate(), @UserID, 1 )
   END

   IF @FCODecDateInfoField > 0 AND @FCODecDateValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @FolderRSN
            AND FolderInfo.InfoCode = 10073
   END

   IF @FCOSitePlanInfoField > 0 AND @FCOSitePlanValue IS NULL
   BEGIN
          DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @FolderRSN
          AND FolderInfo.InfoCode = 10074
   END
END  

/* Site Inspection Set Up for FCO attempt result */

IF @AttemptResult = 10044              /* Site Inspection - Set Up for FCO */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10012,
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Site Inspection for CO (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Site Inspection - Set Up for Final C of O (' + CONVERT(CHAR(11), @AttemptDate) + ')'
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Site Inspection - Set Up for FCO (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
         FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   IF @FCOSitePlanInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 10074,  @FCOSitePlanOrder, 'Y', getdate(), @UserID, 'N', 'N' )
   END

   IF @FCODecDateInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 10073,  @FCODecDateOrder, 'Y', getdate(), @UserID, 'N', 'N' )
   END

   IF @TCOTermInfoField > 0 AND @TCOTermValue IS NULL
   BEGIN
 DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @FolderRSN
              AND FolderInfo.InfoCode = 10070
 END

   IF @TCODecDateInfoField > 0 AND @TCODecDateValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @FolderRSN
            AND FolderInfo.InfoCode = 10071
   END

   IF @TCOExpiryDateInfoField > 0 AND @TCOExpiryDateValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
         WHERE FolderInfo.FolderRSN = @FolderRSN
              AND FolderInfo.InfoCode = 10072
   END

   IF @TCODoc > 0 AND @TCODocNotGenerated > 0
   BEGIN
      DELETE FROM FolderDocument
            WHERE FolderDocument.FolderRSN = @FolderRSN
              AND FolderDocument.DocumentCode = 20000
              AND FolderDocument.DateGenerated IS NULL
   END
END

/* Approved for Temporary CO attempt result */
/* Disabled and replaced by UC folder Temp CO  18-Dec-2012 JA */
/* Re-enabled 12-Feb-13 JA */ 

IF @AttemptResult = 10029              /* Approved for TCO */
BEGIN
   IF @TCODecDateInfoField = 0
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose Site Inspection - Set Up for TCO to proceed.', 16, -1)
      RETURN
   END

   IF ( @TCOTermValue IS NULL ) OR ( @TCOTermValue <= 0 )
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter Number of Days for TCO to be valid', 16, -1)
      RETURN
   END

   IF @TCODecDateValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
    RAISERROR ('Please enter TCO Decision Date', 16, -1)
      RETURN
   END

   SELECT @TCOExpiryDateValue = @TCODecDateValue + @TCOTermValue

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = @TCOExpiryDateValue, 
          FolderInfo.InfoValueDateTime = @TCOExpiryDateValue
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10072

   UPDATE Folder
      SET Folder.StatusCode = 10007, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Approved for Temporary Certificate of Occupancy (' + CONVERT(CHAR(11), @TCODecDateValue) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
    SET FolderProcess.ProcessComment = 'Approved for TCO (' + CONVERT(CHAR(11), @TCODecDateValue) + ')'
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Approved for TCO (' + CONVERT(CHAR(11), @TCODecDateValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END 

/* Approved for Final CO attempt result. */
/* Gross review time is recorded in FolderProcess.StartDate and FolderProcess.EndDate. */

IF @AttemptResult = 10022              /* Approved for FCO */
BEGIN
   IF @FCODecDateInfoField = 0
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose Site Inspection - Set Up for FCO to proceed.', 16, -1)
      RETURN
   END

   IF @FCOSitePlanValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter FCO Site Plan Type', 16, -1)
      RETURN
   END

   IF @FCODecDateValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter FCO Decision Date', 16, -1)
      RETURN
   END

   UPDATE Folder
      SET Folder.StatusCode = 10008, Folder.FinalDate = @FCODecDateValue, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Approved for Final Certificate of Occupancy (' + CONVERT(CHAR(11), @FCODecDateValue) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Approved for FCO (' + CONVERT(CHAR(11), @FCODecDateValue) + ')', 
          FolderProcess.EndDate = @FCODecDateValue 
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

    UPDATE FolderProcessAttempt
    SET FolderProcessAttempt.AttemptComment = 'Approved for FCO (' + CONVERT(CHAR(11), @FCODecDateValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
         ( SELECT max(FolderProcessAttempt.AttemptRSN) 
             FROM FolderProcessAttempt
            WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   /* Update property record impervious surface area using approved coverage percent. */

   EXEC dbo.usp_PropertyImperviousSurfaceUpdate @FolderRSN
END

/* Add Final CO Fee(s) attempt result. If applicable, adds After The Fact fee. */

IF @AttemptResult = 10072              /* Add Final CO Fee(s) */
BEGIN
	SELECT @FCOFeeExists = COUNT(*)
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 160
	AND Folder.FolderRSN = @FolderRSN

	SELECT @FCOFilingFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 304
	AND Folder.FolderRSN = @FolderRSN
	
	SELECT @ATFCOFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 166 
	AND Folder.FolderRSN = @FolderRSN

	/* The below three functions return either the calculated amount if does not exist, or the billed amount if exists. */

	SELECT @FCOFee = dbo.udf_GetZoningFeeCalcFinalCO(@FolderRSN) 

	SELECT @FCOFilingFee = dbo.udf_GetZoningFeeCalcFinalCOFilingFee(@FolderRSN) 

	SELECT @ATFCOFee = dbo.udf_GetZoningFeeCalcFinalCOAfterTheFact(@FolderRSN)  
	
	SELECT @FCOFeeText1 = NULL
	SELECT @FCOFeeText2 = NULL
   
	IF ( @FCOFilingFeeExists = 0 AND @FCOFilingFee > 0 ) 
	BEGIN
		SELECT @NextRSN = @NextRSN + 1 
		INSERT INTO AccountBillFee 
			( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
			FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
		VALUES ( @NextRSN, @FolderRSN, 304, 'Y', @FCOFilingFee, 0, 0, getdate(), @UserId )
	END

	IF @FCOFeeExists = 0 
	BEGIN
		SELECT @NextRSN = @NextRSN + 1 
		INSERT INTO AccountBillFee 
			( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
			FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
		VALUES ( @NextRSN, @FolderRSN, 160, 'Y', @FCOFee, 0, 0, getdate(), @UserId ) 
				  
		SELECT @FCOFeeText1 = '$' + CAST(CAST(@FCOFee + @FCOFilingFee AS NUMERIC(10,2)) AS VARCHAR) + ' FCO fee' 
	END

	IF @ATFCOFeeExists = 0  AND @ATFCOFee > 0
	BEGIN
		SELECT @NextRSN = @NextRSN + 1 
		INSERT INTO AccountBillFee 
			( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
			FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
		VALUES ( @NextRSN, @FolderRSN, 166, 'Y', @ATFCOFee, 0, 0, getdate(), @UserId ) 
		
		IF @FCOFeeExists = 0 SELECT @FCOFeeText2 = ' and $' + CAST(CAST(@ATFCOFee AS NUMERIC(10,2)) AS VARCHAR) + ' ATF fee' 
		ELSE SELECT @FCOFeeText2 = '$' + CAST(CAST(@ATFCOFee AS NUMERIC(10,2)) AS VARCHAR) + ' ATF fee'  
	END 
   
   IF ( @FCOFeeText1 IS NULL  AND @FCOFeeText2 IS NULL ) SELECT @FCOFeeText = 'No fees' 
   ELSE SELECT @FCOFeeText = @FCOFeeText1 + @FCOFeeText2
   
	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = @FCOFeeText + ' added (' + CONVERT(CHAR(11), getdate()) + ')' 
	WHERE FolderProcess.ProcessRSN = @ProcessRSN
	AND FolderProcess.FolderRSN = @FolderRSN
	
	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment =  @FCOFeeText + ' added', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   /* FilingFeeHistoric for documentation purposes only - not used */

	SELECT @FilingFeeHistoric = 
	CASE
		WHEN @InDate <  '7/1/1997' THEN 6.00
		WHEN @InDate >= '7/1/1997' AND @InDate < '7/1/2003' THEN 7.00
		WHEN @inDate >= '7/1/2003' AND @InDate < '7/1/2007' THEN 7.50
		WHEN @InDate >= '7/1/2007' AND @InDate < '7/1/2009' THEN 8.50
		WHEN @InDate >= '7/1/2009' THEN 10.00 
	END

END

/* Add Temporary CO Fee attempt result - No checks on previous TCO bills.  Filing Fee not charged for TCO's. */
/* Disabled and replaced by UC folder Temp CO  18-Dec-2012 JA */
/* Re-enabled 12-Feb-13 JA */ 

IF @AttemptResult = 10073              /* Add Temporary CO Fee */
BEGIN
   SELECT @TCOFee = ValidLookup.LookupFee
     FROM ValidLookup 
    WHERE ValidLookup.LookupCode = 15
      AND ValidLookup.Lookup1 = 1
	  
    SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
             ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
      FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
      VALUES ( @NextRSN, @FolderRSN, 162, 'Y', 
               @TCOFee, 0, 0, getdate(), @UserId )

	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = '$' + CAST(@TCOFee AS VARCHAR) + ' TCO fee added (' + CONVERT(CHAR(11), getdate()) + ')' 
	WHERE FolderProcess.ProcessRSN = @ProcessRSN
	AND FolderProcess.FolderRSN = @FolderRSN
	  
	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment =  '$' + CAST(@TCOFee AS VARCHAR) + ' TCO fee added', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT max(FolderProcessAttempt.AttemptRSN) 
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END 

/* CO is Not Applicable  - adds the Abandon Permit process for Relinquish, Supersede, Expired Permits */

IF @AttemptResult = 10023
BEGIN 
   UPDATE Folder
      SET Folder.StatusCode = 10040, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> C of O Not Applicable (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

 UPDATE FolderProcess
    SET FolderProcess.ProcessComment = 'CO Not Applicable (' + CONVERT(CHAR(11), @AttemptDate) + '). Use Abandon Permit to document reason.'
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = 'CO Not Applicable (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
          FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
      AND FolderProcessAttempt.AttemptRSN = 
        ( SELECT max(FolderProcessAttempt.AttemptRSN) 
            FROM FolderProcessAttempt
           WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Close out open processes for below attempt results. */

IF @AttemptResult = 10022          /* Approved for Final CO */
BEGIN
    UPDATE FolderProcess
       SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.StatusCode = 1 
END

IF @AttemptResult = 10023          /* CO Not Applicable */
BEGIN
    UPDATE FolderProcess
       SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.StatusCode = 1 
       AND FolderProcess.ProcessCode <> 10019    /* Abandon Permit */
END

/* Re-open this process for below attempt results. */

IF @AttemptResult IN(10000, 10001, 10029, 10042, 10043, 10044, 10072, 10073)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN
END


GO
