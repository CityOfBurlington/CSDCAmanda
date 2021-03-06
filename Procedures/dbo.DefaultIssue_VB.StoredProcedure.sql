USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_VB]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_VB]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Issue Permit */ 
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

IF @FeeWaiver IS NULL SET @FeeWaiver = 'Empty'
IF @FeeWaiver <> 'Empty' AND @FeeWaiver <> 'Appealed'
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

/* Set Folder Status to VB Permit Pending (25010) */
UPDATE Folder SET StatusCode = 25020 WHERE FolderRSN = @FolderRSN
	EXEC usp_UpdateFolderCondition @FolderRSN, 'VB Permit Issued'

GO
