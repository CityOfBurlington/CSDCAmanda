USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VB_00025040]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VB_00025040]
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
/* Issue Permit, VB Process */ 
DECLARE @StatusCode INT
DECLARE @PaidFlag CHAR(1)
DECLARE @FeeWaiver VARCHAR(10)
DECLARE @FeeSettled CHAR(1)

/* Get Status of Application Process - Must be closed to issue permit */
SELECT @StatusCode = StatusCode FROM FolderProcess 
   WHERE FolderRSN = @FolderRSN AND ProcessCode = 25010
IF @StatusCode <> 2
BEGIN
	RAISERROR('Application process must be closed to issue a VB permit.', 16, -1)
	RETURN
END

/* Get Status of Inspection Process - Must be closed to issue permit */
SELECT @StatusCode = StatusCode FROM FolderProcess WHERE FolderRSN = @FolderRSN AND ProcessCode = 25030
IF @StatusCode <> 2
BEGIN
	RAISERROR('Inspection process must be closed to issue a VB permit.', 16, -1)
	RETURN
END

/* Check that the Vacant Building Fee is settled (paid in full or waived) */
SET @FeeSettled = 'N'

SELECT @FeeWaiver = dbo.f_info_alpha(FolderRSN, 25020 /*VB Fee Waiver Request*/)
   FROM Folder
   WHERE FolderRSN = @FolderRSN

IF @FeeWaiver = 'Granted' 
BEGIN
	SET @FeeSettled = 'Y'
END
ELSE
BEGIN
	SELECT @PaidFlag = AccountBill.PaidInFullFlag FROM AccountBillFee, AccountBill
	   WHERE AccountBill.FolderRSN = @FolderRSN 
	   AND FeeCode = 202 
	   AND AccountBillFee.BillNumber = AccountBill.BillNumber
	IF @PaidFlag = 'Y' SET @FeeSettled = 'Y'
END

IF @FeeSettled = 'N'
	BEGIN
	RAISERROR('The VB Fee must be settled to issue a VB permit.', 16, -1)
	RETURN
	END

/* Set Folder Status to VB Permit Issued (25020) */
UPDATE Folder SET StatusCode = 25020 WHERE FolderRSN = @FolderRSN

EXEC usp_UpdateFolderCondition @FolderRSN, 'VB Permit Issued'


GO
