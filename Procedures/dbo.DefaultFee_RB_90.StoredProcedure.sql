USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_90]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_90]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @FeeAmount float 
DECLARE @FeeComment VARCHAR(100)
DECLARE @RBFeeFolderRSN int

/* Find unbilled, unpaid Rental Fees and add penalty to RB Folder */

--SELECT * FROM AccountBillFee Where FolderRSN = 136915

SET @FeeAmount = 13.00
SET @FeeComment = 'Rental Registration Late Fee'

DECLARE RBLateFee_Cur CURSOR FOR
SELECT  DISTINCT FolderRSN
FROM AccountBillFee
WHERE AccountBillFee.FeeCode IN(180, 181)
AND AccountBillFee.BillNumber > 0
AND AccountBillFee.FeeAmount > 0
AND AccountBillFee.StampDate < '2006-03-07'
AND AccountBillFee.BillNumber IN (SELECT BillNumber FROM AccountBill WHERE ISNULL(PaidInFullFlag , 'N') = 'N')
AND AccountBillFee.FolderRSN IN (SELECT FolderRSN FROM Folder WHERE FolderType = 'RB' AND Folderyear = '06')
Order by AccountBillFee.FolderRSN

OPEN RBLateFee_Cur
FETCH RBLateFee_Cur INTO
@RBFeefolderRSN

WHILE @@Fetch_Status = 0
	
	BEGIN

	EXEC PC_FEE_INSERT @FolderRSN, 209, @FeeAmount, @UserID, 1, @FeeComment, 1, 1
	   
	FETCH RBLateFee_Cur INTO
	@RBFeefolderRSN

END

CLOSE RBLateFee_CUR
DEALLOCATE RBLateFee_CUR




GO
