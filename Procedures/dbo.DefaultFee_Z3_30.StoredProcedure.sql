USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z3_30]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z3_30]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @BaseFee float
DECLARE @ECCRate float
DECLARE @EstConCost float
DECLARE @CalculatedFee float

SELECT @BaseFee = ValidLookup.LookupFee
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 14 ) 
   AND ( ValidLookup.Lookup1 = 3 )

SELECT @ECCRate = ValidLookup.LookupFee
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 14 ) 
   AND ( ValidLookup.Lookup1 = 4 )

SELECT @EstConCost = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10000

SELECT @CalculatedFee = @BaseFee + ( @EstConCOst * @ECCRate )

/* Insert Amend Permit Review Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 147, 'Y', 
         @CalculatedFee, 
         0, 0, getdate(), @UserId )

GO
