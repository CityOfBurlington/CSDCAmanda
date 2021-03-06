USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_150]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_150]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Find billed, unpaid Rental Fees and Penalties and add Interest to RB Folder*/

DECLARE @RBFeeFolderRSN int
DECLARE @RBFeeAmount float


DECLARE RBInterestFee_Cur CURSOR FOR
SELECT  Accountbill.FolderRSN, Sum(BillAmount - TotalPaid)
FROM AccountBillFee, AccountBill
WHERE AccountBillFee.FeeCode In (180, 209)
AND AccountBillFee.BillNumber = AccountBill.BillNumber
AND AccountBill.PaidInfullFlag = 'N'

Group By AccountBill.FolderRSN

Having Sum(BillAmount - TotalPaid)<>0


OPEN RBInterestFee_Cur
FETCH RBInterestFee_Cur INTO
@RBFeefolderRSN, @RBFeeAmount

WHILE @@Fetch_Status = 0

BEGIN

DECLARE @RBInterestCharge float
DECLARE @NextFeeRSN int
DECLARE @RBInterestAmount float
DECLARE @FeeComment varchar(256)
DECLARE @BillNumber int

SELECT @RBInterestCharge = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 16 ) 
   AND ValidLookup.Lookup1 =8

SELECT @RBInterestAmount = @RBInterestCharge * @RBFeeAmount

SELECT @FeeComment = ValidAccountFee.FeeDesc
from ValidAccountFee
WHERE ValidAccountFee.FeeCode = 210

SELECT @NextFeeRSN = Max(AccountBillFeeRSN)
FROM AccountBillFee


SELECT @BillNumber = Max(BillNumber)
From AccountBill

SELECT @NextFeeRSN = @NextFeeRSN + 1 
  INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate ,FeeComment) 
  VALUES ( @NextFeeRSN, @RBFeeFolderRSN, 210, 'Y', 
         @RBInterestAmount, 
         0, 0, getdate(), @FeeComment )


SELECT @BillNumber = @BillNumber + 1
INSERT INTO AccountBill
       (BillNumber, DateGenerated, DueDate, FolderRSN,BillAmount,TotalPaid,
        PaidinFullFlag, BillDesc, StampDate)
        VALUES (@Billnumber, getdate(), getdate(), @RBFeeFolderRSN, 
        @RBInterestAmount, 0,'N', @FeeComment, getdate())
       

UPDATE AccountBillFee
		   SET BillNumber = @BillNumber,
		   StampDate = getdate()
		   where FolderRSN = @RBFeeFolderRSN
		   and isnull(BillNumber, 0) = 0 
			and feecode = 210
                        and accountbillfee.accountbillfeersn = @NextFeeRSN
   
FETCH RBInterestFee_Cur INTO
@RBFeefolderRSN, @RBFeeAmount

END

CLOSE RBInterestFee_CUR
DEALLOCATE RBInterestFee_CUR


GO
