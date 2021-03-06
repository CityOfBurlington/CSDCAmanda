USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_BP_10]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_BP_10]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ATFO VarChar (3)
DECLARE @ATFC VarChar (3)

SELECT @ATFO = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30078

SELECT @ATFC = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30095

DECLARE @ATFfEE Float
SELECT @ATFFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 1 ) 
   AND ( ValidLookup.Lookup1 = 4)

DECLARE @Estimated_Cost_of_Construction float 
SELECT @Estimated_Cost_of_Construction = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30006 )

DECLARE @ATFPenalty Float 
IF @Estimated_Cost_of_Construction <= 3000
SET @ATFPenalty = 30
ELSE
SET @ATFPenalty = @ATFFee * @Estimated_Cost_of_Construction


IF @ATFO = 'Yes' OR @ATFC = 'Yes'
BEGIN
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 225, 'Y', 
         @ATFPenalty, 
         0, 0, getdate(), @UserId )
END

GO
