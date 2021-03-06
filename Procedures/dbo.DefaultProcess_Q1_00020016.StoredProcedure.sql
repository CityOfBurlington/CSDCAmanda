USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_Q1_00020016]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_Q1_00020016]
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
DECLARE @AttemptResult int
DECLARE @CheckInfo float
DECLARE @Inspector varchar(30)
DECLARE @InspectorID varchar(8)
DECLARE @NextFolderRSN int
DECLARE @SeqNo int
DECLARE @Seq char(6)
DECLARE @SeqLength int
DECLARE @TheYear char(2)
DECLARE @FolderType char(2)
DECLARE @SubCode int
DECLARE @ChecklistCode int
DECLARE @Description varchar(2000)
DECLARE @Sub INT
DECLARE @dtmExpiryDate DATETIME
DECLARE @CName VARCHAR(255)
DECLARE @CAddress VARCHAR(1200)
DECLARE @CPhone VARCHAR(255)
DECLARE @InspectorEmail VARCHAR(300)
DECLARE @AdminEmail varchar(300)
DECLARE @SendAckLetterYN VARCHAR(1)
DECLARE @FolderName VARCHAR(400)
DECLARE @HousingOrZoning VARCHAR(1)
DECLARE @ZoningAdminUser VARCHAR(30)

SELECT @ZoningAdminUser = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderRSN = (SELECT MAX(FolderRSN) FROM Folder WHERE FolderType = 'AA')
AND InfoCode = 30208

SELECT @HousingOrZoning = UPPER(RTRIM(LTRIM(SUBSTRING(ValidSub.SubDesc, 1, 1))))
FROM Folder
INNER JOIN ValidSub ON Folder.SubCode = ValidSub.SubCode
WHERE FolderRSN = @FolderRSN

SELECT @FolderName = Folder.FolderName, 
@Sub = Folder.SubCode 
FROM Folder 
WHERE FolderRSN = @FolderRSN

SELECT @CName = dbo.udf_GetFirstPeopleName(7, @FolderRSN),
@CAddress = dbo.udf_GetFirstPeopleAddressLine1(7, @FolderRSN) + ' ' + dbo.udf_GetFirstPeopleAddressLine2(7, @FolderRSN)  + ' ' + dbo.udf_GetFirstPeopleAddressLine3(7, @FolderRSN)  + ' ' + dbo.udf_GetFirstPeopleAddressLine4(7, @FolderRSN) ,
@CPhone = dbo.udf_GetFirstPeoplePhone1(7, @FolderRSN)

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT max(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @CheckInfo = count(*)
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20009
AND FolderInfo.InfoValue IS NULL

IF @AttemptResult = 20037 /*START INVESTIGATION*/
BEGIN
   IF @Sub = 700 /*HOUSING COMPLAINT*/
   BEGIN
      SELECT @dtmExpiryDate = DATEADD(D, 5, GetDate())
   END

   IF @Sub = 701 /*ZONING COMPLAINT*/
   BEGIN
      SELECT @dtmExpiryDate = DATEADD(D, 30, GetDate())
   END
END
ELSE /* @AttemptResult <> 20037 - Start Investigation */
BEGIN
   SET @dtmExpiryDate = GetDate()
END 

IF @AttemptResult IN (20037, 30110) /* Start Investigation or Priority Investigation */
BEGIN
   IF @CheckInfo <> 0 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR('YOU MUST ASSIGN AN INSPECTOR IN THE INFOFIELD', 16, -1)
   END
   ELSE /* @CheckInfo = 0 */
      SELECT @Inspector = FolderInfo.InfoValue
      FROM FolderInfo
      WHERE FolderInfo.FolderRSN = @FolderRSN AND FolderInfo.InfoCode = 20009

      SELECT @InspectorID = ValidUser.UserID, @InspectorEmail = ValidUser.EmailAddress
      FROM ValidUser
      WHERE ValidUser.UserName = @Inspector

      SELECT @Description = RTRIM(LTRIM(CAST(ISNULL(FolderDescription, '') AS VARCHAR(2000))))
      FROM Folder
      WHERE Folder.FolderRSN = @FolderRSN

      SELECT @NextFolderRSN =  max(FolderRSN + 1)
      FROM  Folder
	 
      SELECT @TheYear = substring(convert( char(4),DATEPART(year, getdate())),3,2)

      SELECT @SeqNo = convert(int,max(FolderSequence)) + 1
      FROM Folder
      WHERE FolderYear = @TheYear

      IF @SeqNo IS NULL
      BEGIN
         SELECT @SeqNo = 100000
      END

      SELECT @SeqLength = datalength(convert(varchar(6),@SeqNo))

      IF @SeqLength < 6
      BEGIN
         SELECT @Seq = substring('000000',1,(6 - @SeqLength)) + convert(varchar(6), @SeqNo)
      END

      IF @SeqLength = 6
      BEGIN
         SELECT @Seq = convert(varchar(6),@SeqNo)
      END

      IF @Description = '' 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR('YOU MUST PROVIDE A DESCRIPTION ON THE FRONT OF THE FOLDER', 16, -1)
      END

   ELSE /* @AttemptResult NOT IN (20037, 30110) */
   BEGIN
        
      /* Create the QC Folder */
      INSERT INTO FOLDER
      (FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
      FolderType, StatusCode, SubCode, WorkCode, FolderDescription, PropertyRSN, Indate,
      ParentRSN, CopyFlag, FolderName, StampDate, StampUser, ExpiryDate, IssueUser)
      SELECT @NextFolderRSN, 20, @TheYear, @Seq, '000', '00',
      'QC', 150, SubCode, WorkCode, @Description, PropertyRSN, getdate(),
      @FolderRSN, 'DDDDD', FolderName, getdate(), User, @dtmExpiryDate, @InspectorID 
      FROM Folder
      WHERE FolderRSN = @FolderRSN

      DECLARE @QCFolderRSN INT
      SET @QCFolderRSN = @NextFolderRSN

      SET @NextProcessRSN = @NextProcessRSN + 1

      /* Insert people records from this folder into the QC */
      INSERT INTO FolderPeople (FolderRSN, PeopleRSN, PeopleCode, StampDate, StampUser)
      SELECT DISTINCT @QCFolderRSN, FolderPeople.PeopleRSN, FolderPeople.PeopleCode, getdate(), @UserId
      FROM Folder
      INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
      WHERE Folder.FolderRSN = @FolderRSN
      AND FolderPeople.PeopleCode IN(322, 75, 80, 125)
      /*75=Property Manager 80=Emergency Contact 125=Code Owner*/

      UPDATE FolderInfo
      SET FolderInfo.InfoValue = @Inspector
      WHERE FolderInfo.InfoCode = 20009
      AND FolderInfo.FolderRSN = @QCFolderRSN

      UPDATE FolderProcess
      SET FolderProcess.AssignedUser = @InspectorID
      WHERE FolderProcess.FolderRSN = @QCFolderRSN
      AND FolderProcess.ProcessCode = 20018

      UPDATE Folder
      SET Folder.StatusCode = 150, Folder.FinalDate = @dtmExpiryDate
      WHERE Folder.FolderRSN = @QCFolderRSN

      IF @HousingOrZoning <> 'H' 
      BEGIN
         /*It's not Housing must be a Zoning Complaint - Delete the Complaint Evaluation process from QC Folder*/
         DELETE FROM FolderProcess 
         WHERE FolderRSN = @QCFolderRSN
         AND ProcessCode = 20018

         SELECT @NextProcessRSN = MAX(ProcessRSN) + 1 FROM FolderProcess

         INSERT INTO FolderProcess 
         (FolderRSN, ProcessRSN, ProcessCode, DisciplineCode, 
         PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, ScheduleDate, ScheduleEndDate) 
         VALUES (@QCFolderRSN, @NextProcessRSN, 20060/*Admin Review*/, 80, 
         'Y', 1, GetDate(), @UserId, @ZoningAdminUser, GetDate(), DATEADD(D, 5, GetDate()))
      END

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

      SELECT @FolderName = FolderName
      FROM Folder
      WHERE FolderRSN = @FolderRSN

      SELECT @DateComplaintReceived = dbo.FormatDateTime(DateComplaintReceived, 'MM/DD/YYYY'),
      @CompleteSiteVisitBy = CompleteSiteVisitBy,
      @CompletePaperworkBy = CompletePaperworkBy
      FROM uvw_Q1_InspectorWorkorder
      WHERE FolderRSN = @FolderRSN

      SELECT @CName = ISNULL(dbo.udf_GetFirstPeopleName(7, @FolderRSN), ''),
      @CAddress = ISNULL(dbo.udf_GetFirstPeopleAddressLine1(7, @FolderRSN), ''),
      @CPhone = ISNULL(dbo.udf_GetFirstPeoplePhone1(7, @FolderRSN), '')

      IF @AttemptResult <> 30110 /*PRIORITY COMPLAINT*/
      BEGIN
         SET @BodyText = 'Complaint Investigation' + CHAR(10) + 'Complaint Received: ' + @DateComplaintReceived + CHAR(10) + 'Complete Site Visit By' + @CompleteSiteVisitBy + CHAR(10) + 'Paperwork Due By: ' + @CompletePaperworkBy + CHAR(10) + 'FolderRSN: ' + CAST(@NextFolderRSN AS VARCHAR(20)) + CHAR(10) + 'Location: ' + @FolderName + CHAR(10) + 'Compainant: ' + @CName + CHAR(10) + 'Complainant Name: ' + @CAddress + CHAR(10) + 'Complainant Phone: ' + @CPhone + CHAR(10) + CHAR(10) + 'Complaint Description' + CHAR(10) + @Description 
         SET @Subject = 'Complaint Workorder ' + @FolderName
      END
      ELSE
      BEGIN
         SET @BodyText = 'PRIORITY COMPAINT INVESTIGATION' + CHAR(10) + 'Complaint Received: ' + @DateComplaintReceived + CHAR(10) + 'Complete Site Visit By' + @CompleteSiteVisitBy + CHAR(10) + 'Paperwork Due By: ' + @CompletePaperworkBy + CHAR(10) + 'FolderRSN: ' + CAST(@NextFolderRSN AS VARCHAR(20)) + CHAR(10) + 'Location: ' + @FolderName + CHAR(10) + 'Compainant: ' + @CName + CHAR(10) + 'Complainant Name: ' + @CAddress + CHAR(10) + 'Complainant Phone: ' + @CPhone + CHAR(10) + CHAR(10) + 'Complaint Description' + CHAR(10) + @Description 
         SET @Subject = 'PRIORITY COMPAINT WORKORDER ' + UPPER(@FolderName)
      END 

      SELECT @SendAckLetterYN = SUBSTRING(RTRIM(LTRIM(UPPER(ISNULL(dbo.f_info_boolean(@FolderRSN, 30207), 'NO')))), 1, 1)

      SELECT @AdminEmail = ValidUser.EmailAddress 
      FROM ValidUser
      WHERE UserId = @UserId

      COMMIT TRANSACTION
      BEGIN TRANSACTION

      EXEC @intCOMReturnValue = xspQ1InvestigationAssignment @FolderRSN, @QCFolderRSN, @UserId, @FolderName, @BodyText, @InspectorEmail, @AdminEmail, @SendAckLetterYN

   END
END

IF @AttemptResult = 20036 /*cancelled*/
BEGIN
	UPDATE Folder
	SET StatusCode = 2/*Closed*/, FinalDate = getdate()
	WHERE Folder.FolderRSN = @FolderRSN
END

GO
