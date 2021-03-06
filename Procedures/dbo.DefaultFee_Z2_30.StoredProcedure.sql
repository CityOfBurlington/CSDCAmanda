USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z2_30]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z2_30]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @BaseFee float
DECLARE @ECCRate float
DECLARE @FilingFee float
DECLARE @EstConCost float
DECLARE @CalculatedFee float

SELECT @BaseFee = ValidLookup.LookupFee
FROM ValidLookup 
WHERE ValidLookup.LookupCode = 14 
AND ValidLookup.Lookup1 = 1 

SELECT @ECCRate = ValidLookup.LookupFee
FROM ValidLookup 
WHERE ValidLookup.LookupCode = 14 
AND ValidLookup.Lookup1 = 2 

SELECT @FilingFee = ValidLookup.LookupFee
FROM ValidLookup 
WHERE ValidLookup.LookupCode = 3 
AND ValidLookup.Lookup1 = 2 

SELECT @EstConCost = FolderInfo.InfoValueNumeric 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 10000

SELECT @CalculatedFee = @BaseFee + ( @EstConCost * @ECCRate )

/* Insert Amend Permit Review Fee and Filing Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 147, 'Y', 
         @CalculatedFee, 
         0, 0, getdate(), @UserId )

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @FilingFee, 
         0, 0, getdate(), @UserId ) 

GO
