USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EP_00030103]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EP_00030103]
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
DECLARE @AttemptResultCode INT
DECLARE @LastBEDEnergizeNumber INT
DECLARE @NextBEDEnergizeNumber INT
DECLARE @DocumentRSN INT
DECLARE @intInfoValue INT
DECLARE @BEDEnergNumber INT

SELECT @DocumentRSN  = dbo.udf_GetNextDocumentRSN()

SELECT @AttemptResultCode = Resultcode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

INSERT INTO tblBEDAttemptResult Values(@AttemptResultCode, @FolderRSN, @ProcessRSN)


IF @AttemptResultCode = 30115  /*Send to BED*/
BEGIN

  /* Check that everything is ready to go: */
  /* Is the Folder Info field 30016 (Fault Current Number) filled in? */
  SELECT @intInfoValue = ISNULL(InfoValue,0) FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30016
  IF @intInfoValue = 0
  BEGIN
     RAISERROR('Please fill folder info value Fault Current Number before proceeding.', 16, -1)
  END
  /* Is the Folder Info field 30220 (BED Energize Number) filled in? */
  SELECT @intInfoValue = ISNULL(InfoValue,0) FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30220
  IF @BEDEnergNumber = 0
  BEGIN
     RAISERROR('Please fill folder info value BED Energize Number before proceeding.', 16, -1)
  END
  /* Is the Process Info field 30010 (Number of Meters) filled in? */
  SELECT @intInfoValue = ISNULL(InfoValue,0) FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30010
  IF @intInfoValue = 0
  BEGIN
     RAISERROR('Please fill Process info value Number of Meters before proceeding.', 16, -1)
  END

  INSERT INTO tblBEDEnergizeNumber Values(@BEDEnergNumber, @FolderRSN, @ProcessRSN)

  IF NOT EXISTS (SELECT DocumentRSN FROM FolderDocument WHERE FolderDocument.FolderRSN = @FolderRSN AND DocumentCode = 30010)
    BEGIN
      INSERT INTO FolderDocument (DocumentRSN, FolderRSN, DocumentCode, DocumentStatus, LinkCode) 
	VALUES (@DocumentRSN, @FolderRSN, 30010, 1, 1)
    END


  /*RAISERROR('Testing Pending Approval',16,-1)*/

  UPDATE FolderProcess /*reopen this process*/
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
  WHERE FolderProcess.processRSN = @ProcessRSN

END
GO
