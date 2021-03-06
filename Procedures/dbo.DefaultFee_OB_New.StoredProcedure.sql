USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_OB_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_OB_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @CalculatedFee float
DECLARE @NoofWks float
DECLARE @CalculatedObsFee float

BEGIN
SET @CalculatedFee = 0
SET @CalculatedObsFee = 0
END

SELECT @NoOfWks = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30051 )


SELECT @CalculatedFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookUp.LookUp1 = 7 )


DECLARE @ConstructionStartDate DATETIME

SELECT @ConstructionStartDate = FolderInfo.InfoValueDateTime
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30129

/*Use Info Field to Update Folder Expiration Date*/
UPDATE Folder
SET ExpiryDate = DATEADD(d, (7 * @NoOfWks), @ConstructionStartDate) 
WHERE FolderRSN = @FolderRSN


BEGIN
       SET @CalculatedObsFee = @CalculatedFee * @NoOfWks
END


/* Excavation Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 175, 'Y', 
         @CalculatedObsFee, 
         0, 0, getdate(), @UserId )

GO
