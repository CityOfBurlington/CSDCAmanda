USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010017]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010017]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/* CO Request at P+Z (10017) version 1 */

/* Probably a temporary process for P+Z to log a CO request, and add dummy 
   fees to document money that was received. This process repeats code from 
   the Certificate of Occupancy process (10001), and 10001 remains 
   unaltered. To remove this process (10017): Delete entries for 10017 and 
   set process 10001) as the Process Default for FolderStatus Released. */

/* Process runs once, add the real Certificate of Occupancy process (10001) 
   and closes. */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @AttemptNumber int

DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @IssueDate datetime

DECLARE @COProcess int
DECLARE @COProcessOrder int
DECLARE @PZCOProcessOrder int

DECLARE @ApplicationFee float
DECLARE @RequestSignedBy varchar(50)
DECLARE @TCOFee float
DECLARE @FCOBaseFee float
DECLARE @FCOFeeRate float
DECLARE @FCOFee float
DECLARE @FCOFilingFee float
DECLARE @FilingFeeHistoric float

/* Get attempt result and number of attempt results for this process. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode, 
       @AttemptDate = FolderProcessAttempt.AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       (SELECT max(FolderProcessAttempt.AttemptRSN) 
          FROM FolderProcessAttempt
         WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @AttemptNumber = count(*)
  FROM FolderProcessAttempt, FolderProcess
 WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
   AND FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 10017

/* Get Application Date and Permit Decision Date. */

SELECT @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @IssueDate = Folder.IssueDate
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Set display order for adding the Certificate of Occupancy process based upon 
   the order of this process. Check for existence of Certificate of Occupancy 
   process. */

SELECT @PZCOProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 10017

SELECT @COProcessOrder = @PZCOProcessOrder + 10

SELECT @COProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 10001

/* Check Folder Status to insure permit is out of its appeal period, and that any 
   pre-release conditions have been met. (This check is here in case user manually 
   adds the C of O process.) */

IF @FolderStatus IN(10002, 10003, 10004, 10016)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Folder status indicates that the zoning permit is still in its appeal period.', 16, -1)
   RETURN
END

IF @FolderStatus = 10018
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Folder status indicates that the zoning permit has pre-release conditions that have not been met.', 16, -1)
   RETURN
END

/* Certificate of Occupancy Requested attempt result */
/* Notes:  
   2) - As the result of the Bianchi decision, starting on July 1, 1998, filing fees 
        started being charged - one page for the permit, and one page for the CO. 
   3) - Process Info has a field for the name of the person requesting the CO. 
        It is required as backup documentation.*/

IF @AttemptResult = 10001               /* C of O Requested */
BEGIN

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

   UPDATE Folder
      SET Folder.StatusCode = 10011, 
     Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> C of O Request Logged at P+Z (' + CONVERT(CHAR(11), @AttemptDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'C of O Requested (' + CONVERT(CHAR(11), @AttemptDate) + ')'
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'C of O Requested (' + CONVERT(CHAR(11), @AttemptDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   /* FilingFeeHistoric for documentation purposes only - not used */

   SELECT @FilingFeeHistoric = 
   CASE
      WHEN @InDate <  '7/1/1997' THEN 6
      WHEN @InDate >= '7/1/1997' AND @InDate < '7/1/2003' THEN 7
      WHEN @InDate >= '7/1/2003' THEN 7.50
   END

   SELECT @FCOBaseFee = ValidLookup.LookupFee
     FROM ValidLookup 
    WHERE ValidLookup.LookupCode = 15
      AND ValidLookup.Lookup1 = 2

   SELECT @FCOFeeRate = ValidLookup.LookupFee
     FROM ValidLookup 
    WHERE ValidLookup.LookupCode = 15
      AND ValidLookup.Lookup1 = 3
   
   SELECT @ApplicationFee = SUM(AccountBillFee.FeeAmount)
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBill.PaidInFullFlag <> 'C'
      AND AccountBillFee.FeeCode IN(85,86,90,95,100,105,130,135,136,147)
      AND Folder.FolderRSN = @FolderRSN

   /* For permits converted from Access/DBase issued after 7/1/1998, the filing 
      fees were coded in the application fee. These were a total of $14, 
      and are subtracted from the application fee. The benchmark Amanda 
      zoning folder (first one used) is RSN 105535. */

   IF @FolderRSN < 105535 AND @InDate >= '7/1/1998' 
      SELECT @ApplicationFee = @ApplicationFee - 14

   SELECT @FCOFee = @FCOBaseFee + ( @ApplicationFee * @FCOFeeRate )

   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
             ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
               FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
      VALUES ( @NextRSN, @FolderRSN, 163, 'Y', 
               @FCOFee, 0, 0, getdate(), @UserId )

   IF @IssueDate < '7/1/1998'
   BEGIN
      SELECT @FCOFilingFee = ValidLookup.LookupFee
        FROM ValidLookup 
       WHERE ValidLookup.LookupCode = 15
         AND ValidLookup.Lookup1 = 4

      SELECT @NextRSN = @NextRSN + 1 
      INSERT INTO AccountBillFee 
                ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
                  FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
         VALUES ( @NextRSN, @FolderRSN, 164, 'Y', 
                  @FCOFilingFee, 0, 0, getdate(), @UserId )
   END

   IF @COProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
             ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
               ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
               DisplayOrder, PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 10001, 45, 1,
                getdate(), (getdate() + 30), getdate(), (getdate() + 30), 
                @COProcessOrder, 'Y', 'Y', getdate(), @UserID )
   END

   IF @COProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, FolderProcess.EndDate = NULL
       WHERE FolderProcess.ProcessCode = 10001
         AND FolderProcess.FolderRSN = @folderRSN
   END

END
GO
