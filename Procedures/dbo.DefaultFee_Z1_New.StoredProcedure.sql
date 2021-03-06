USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z1_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z1_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Z1_Base_Rate float      /* Level 1 base rate */ 
DECLARE @Z1_Filing_Fee float     /* Clerk's Filing Fee */
DECLARE @Violation varchar(3) 
DECLARE @CalculatedFee float 

SELECT @Z1_Base_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 15 

SELECT @Z1_Filing_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3  
   AND ValidLookup.Lookup1 = 2 

SELECT @Violation = UPPER(FolderInfo.InfoValue) 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10043

SELECT @CalculatedFee = @Z1_Base_Rate

IF @Violation = 'YES' SELECT @CalculatedFee = @CalculatedFee * 2

/* Insert Fees */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 90, 'Y', 
         @CalculatedFee, 
         0, 0, getdate(), @UserId )

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @Z1_Filing_Fee, 
         0, 0, getdate(), @UserId )

GO
