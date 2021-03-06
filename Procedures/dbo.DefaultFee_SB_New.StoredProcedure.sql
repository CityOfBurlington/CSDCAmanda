USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_SB_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_SB_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @AppFee float
DECLARE @FeeMonths float
DECLARE @MonthFee float
DECLARE @NoofMonths int


SELECT @AppFee = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1 = 9
         AND ValidLookup.Lookup2 = 1 )

SELECT @NextRSN = @NextRSN + 1 


   INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 300, 'Y', 
         @AppFee, 
         0, 0, getdate(), @UserId )


COMMIT Transaction
BEGIN Transaction

SELECT @NoofMonths = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.InfoCode = 30119
AND FolderInfo.FolderRSN = @FolderRSN

SELECT @MonthFee = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1 = 9
         AND ValidLookup.Lookup2 = 2 )

SELECT @NextRSN = @NextRSN + 1 

SELECT @FeeMonths = @NoofMonths * @MonthFee

INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 302, 'Y', 
         @FeeMonths, 
         0, 0, getdate(), @UserId )




GO
