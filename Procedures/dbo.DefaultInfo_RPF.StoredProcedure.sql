USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_RPF]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_RPF]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ECC FLOAT
DECLARE @ActualCost FLOAT
DECLARE @Difference FLOAT
DECLARE @Refund INT

SET @Refund=0

SELECT @ECC = InfoValue
FROM FolderInfo 
WHERE InfoCode =31065
AND FolderRSN=@FolderRSN


SELECT @ActualCost = InfoValue
FROM FolderInfo 
WHERE InfoCode =35670
AND FolderRSN=@FolderRSN

SELECT @Difference =@ActualCost-@ECC

IF @Difference <0 
BEGIN
SET @Difference =@Difference * -1
SET @Refund=1
END

UPDATE FolderInfo
SET InfoValue=@Difference , InfoValueNumeric=@Difference 
WHERE InfoCode=31070
AND FolderRSN=@FolderRSN

DECLARE @Building_Fee_Rate FLOAT 
DECLARE @FilingFeeRate FLOAT
DECLARE @CalculatedBuildingFee FLOAT

SET @CalculatedBuildingFee = 0

SELECT @Building_Fee_Rate = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE (ValidLookup.LookupCode = 1) 
AND (ValidLookUp.LookUp1 = 1)

SELECT @FilingFeeRate = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE (ValidLookup.LookupCode = 1) 
AND (ValidLookup.Lookup1 = 2)

DECLARE @NextBillRSN INT
SELECT @NextBillRSN=MAX(AccountBillFeeRSN) + 1 FROM AccountBillFee

SELECT @CalculatedBuildingFee = @Building_Fee_Rate * @Difference 

INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser) 
VALUES(@NextBillRSN, @FolderRSN, 80, 'Y', @FilingFeeRate, 0, 0, getdate(), @UserId)

SELECT @NextBillRSN=@NextBillRSN+1

/* Building Permit Fee */
INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser)
VALUES (@NextBillRSN, @FolderRSN, 25, 'Y', @CalculatedBuildingFee, 0, 0, getdate(), @UserId)


GO
