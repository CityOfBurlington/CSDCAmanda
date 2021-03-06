USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QC_00020080]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QC_00020080]
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
DECLARE @ParentRSN INT
DECLARE @AttemptResult INT
DECLARE @dtmExpiryDate DATETIME
DECLARE @CName VARCHAR(255)
DECLARE @CAddress VARCHAR(1200)
DECLARE @CPhone VARCHAR(255)
DECLARE @Inspector VARCHAR(100)
DECLARE @InspectorId INT
DECLARE @InspectorEmail VARCHAR(300)
DECLARE @AdminEmail varchar(300)
DECLARE @SendAckLetterYN VARCHAR(1)
DECLARE @HousingOrZoning VARCHAR(1)
DECLARE @ZoningAdminUser VARCHAR(30)
DECLARE @Description varchar(2000)
DECLARE @FolderName VARCHAR(400)


      /*email inspector*/
      /*@Inspector*/

      DECLARE @intCOMReturnValue  INT
      DECLARE @BodyText VARCHAR(3000)
      DECLARE @Subject VARCHAR(400)
      DECLARE @ExportFile VARCHAR(200)
      DECLARE @AmandaPath VARCHAR(200)
      DECLARE @BaseFileName VARCHAR(200)

      DECLARE @DateComplaintReceived VARCHAR(20)
      DECLARE @CompleteSiteVisitBy VARCHAR(20)
      DECLARE @CompletePaperworkBy VARCHAR(20)



SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @ParentRSN = ParentRSN 
FROM Folder 
WHERE FolderRSN = @FolderRSN

      SELECT @FolderName = FolderName
      FROM Folder
      WHERE FolderRSN = @ParentRSN

      SELECT @DateComplaintReceived = dbo.FormatDateTime(DateComplaintReceived, 'MM/DD/YYYY'),
      @CompleteSiteVisitBy = CompleteSiteVisitBy,
      @CompletePaperworkBy = CompletePaperworkBy
      FROM uvw_Q1_InspectorWorkorder
      WHERE FolderRSN = @ParentRSN

      SELECT @CName = ISNULL(dbo.udf_GetFirstPeopleName(7, @ParentRSN), ''),
      @CAddress = ISNULL(dbo.udf_GetFirstPeopleAddressLine1(7, @ParentRSN), ''),
      @CPhone = ISNULL(dbo.udf_GetFirstPeoplePhone1(7, @ParentRSN), '')

      IF @AttemptResult <> 30110 /*PRIORITY COMPLAINT*/
      BEGIN
         SET @BodyText = 'Complaint Investigation' + CHAR(10) + 'Complaint Received: ' + @DateComplaintReceived + CHAR(10) + 'Complete Site Visit By' + @CompleteSiteVisitBy + CHAR(10) + 'Paperwork Due By: ' + @CompletePaperworkBy + CHAR(10) + 'FolderRSN: ' + CAST(@FolderRSN AS VARCHAR(20)) + CHAR(10) + 'Location: ' + @FolderName + CHAR(10) + 'Compainant: ' + @CName + CHAR(10) + 'Complainant Name: ' + @CAddress + CHAR(10) + 'Complainant Phone: ' + @CPhone + CHAR(10) + CHAR(10) + 'Complaint Description' + CHAR(10) + @Description 
         SET @Subject = 'Complaint Workorder ' + @FolderName
      END
      ELSE
      BEGIN
         SET @BodyText = 'PRIORITY COMPAINT INVESTIGATION' + CHAR(10) + 'Complaint Received: ' + @DateComplaintReceived + CHAR(10) + 'Complete Site Visit By' + @CompleteSiteVisitBy + CHAR(10) + 'Paperwork Due By: ' + @CompletePaperworkBy + CHAR(10) + 'FolderRSN: ' + CAST(@ParentRSN AS VARCHAR(20)) + CHAR(10) + 'Location: ' + @FolderName + CHAR(10) + 'Compainant: ' + @CName + CHAR(10) + 'Complainant Name: ' + @CAddress + CHAR(10) + 'Complainant Phone: ' + @CPhone + CHAR(10) + CHAR(10) + 'Complaint Description' + CHAR(10) + @Description 
         SET @Subject = 'PRIORITY COMPAINT WORKORDER ' + UPPER(@FolderName)
      END 

      SELECT @SendAckLetterYN = SUBSTRING(RTRIM(LTRIM(UPPER(ISNULL(dbo.f_info_boolean(@ParentRSN, 30207), 'NO')))), 1, 1)

      SELECT @AdminEmail = ValidUser.EmailAddress 
      FROM ValidUser
      WHERE UserId = @UserId


      SELECT @Inspector = FolderInfo.InfoValue
      FROM FolderInfo
      WHERE FolderInfo.FolderRSN = @ParentRSN AND FolderInfo.InfoCode = 20009

      SELECT @InspectorID = ValidUser.UserID, @InspectorEmail = ValidUser.EmailAddress
      FROM ValidUser
      WHERE ValidUser.UserName = @Inspector



      EXEC @intCOMReturnValue = xspQ1InvestigationAssignment @ParentRSN, @FolderRSN, @UserId, @FolderName, @BodyText, 'ddalton@burlingtonvt.gov', @AdminEmail, @SendAckLetterYN


GO
