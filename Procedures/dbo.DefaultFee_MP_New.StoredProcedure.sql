USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_MP_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_MP_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @CalculatedFee float
DECLARE @CalculatedFilingFee float
SET @CalculatedFee = 0
SET @CalculatedFilingFee = 0

DECLARE @Estimated_Cost_of_Const float 
SELECT @Estimated_Cost_of_Const = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30006 )

DECLARE @SubCode int 
SELECT @SubCode = Folder.SubCode
FROM Folder 
WHERE ( Folder.FolderRSN = @FolderRSN ) 

DECLARE @Building_Fees float 
SELECT @Building_Fees = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 1 ) 
   AND ( ValidLookup.Lookup1 = 1 )

DECLARE @FilingFeeRate float 
SELECT @FilingFeeRate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 1 ) 
   AND ( ValidLookup.Lookup1 = 2 )

DECLARE @MinimumFee float 
SELECT @MinimumFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 1 ) 
   AND ( ValidLookup.Lookup1 = 3 )

SET @CalculatedFee = @Building_Fees*@Estimated_Cost_of_Const

IF @CalculatedFee < @MinimumFee 
BEGIN SET @CalculatedFee = @MinimumFee END


SET @CalculatedFilingFee = @FilingFeeRate

/* Clerks Filing Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @CalculatedFilingFee, 
         0, 0, getdate(), @UserId )


/* Mechanical Permit Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 55, 'Y', 
         @CalculatedFee, 
         0, 0, getdate(), @UserId )

COMMIT TRAN

BEGIN TRAN
EXECUTE DEFAULTFee_BP_10 @FolderRSN, @UserID





GO
