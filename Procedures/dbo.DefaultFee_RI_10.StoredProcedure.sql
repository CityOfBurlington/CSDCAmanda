USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RI_10]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RI_10]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Reinspections int
DECLARE @Reinspectfee float
DECLARE @FeeAmount float
DECLARE @NoOfUnits int


SELECT @Reinspections = Count(FolderProcessAttempt.Resultcode)-1
FROM FolderProcessAttempt, FolderProcess
WHERE FolderProcessAttempt.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode = 20020
AND FolderProcess.FolderRSN = FolderProcessAttempt.FolderRSN
and FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcessAttempt.ResultCode = 20047


SELECT @NoOfUnits = InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20032

IF @Reinspections > 2

SELECT @ReinspectFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 9 ) 
   AND  ValidLookup.Lookup1 = 1
   AND ValidLookup.Lookup2 = 3

IF @Reinspections = 2

SELECT @ReinspectFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 9 ) 
   AND  ValidLookup.Lookup1 = 1
   AND ValidLookup.Lookup2 = 2

IF @Reinspections = 1

SELECT @ReinspectFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 9 ) 
   AND  ValidLookup.Lookup1 = 1
   AND ValidLookup.Lookup2 = 1

SET @Feeamount = @NoOfUnits * @ReinspectFee

/* Reinspection Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 200, 'Y', 
         @Feeamount, 
         0, 0, getdate(), @UserId )

GO
