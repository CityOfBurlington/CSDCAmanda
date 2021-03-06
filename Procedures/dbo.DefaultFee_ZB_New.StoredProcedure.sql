USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZB_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZB_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Basic application fee calculation and insertion.  */
/* July 1, 2009 - The two tier Basic fee structure based upon estimated construction 
   cost ($22,000) discontinued. Flat fee reimplemented. */  

DECLARE @FeeCode int
DECLARE @Zoning_Permit_Fee1 float                     /* Basic Level 1 */
DECLARE @Zoning_Permit_Fee2 float                     /* Basic Level 2 */
DECLARE @Zoning_Permit_Filing_Fee float               /* Filing Fee */
DECLARE @Estimated_Construction_Cost float            /* Cost of Construction */
DECLARE @Double_Fees_Violation varchar(3)             /* Violation = doubled fees */
DECLARE @ApplicationFee float

SELECT @Zoning_Permit_Fee1 = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 7 )

SELECT @Zoning_Permit_Fee2 = ValidLookup.LookupFee   
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 8 )

SELECT @Zoning_Permit_Filing_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 2 )

SELECT @Estimated_Construction_Cost = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 10000 )

SELECT @Double_Fees_Violation = FolderInfo.InfoValue 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 10043 )

SELECT @ApplicationFee = @Zoning_Permit_Fee1
SELECT @FeeCode = 85

IF @Double_Fees_Violation = 'Yes'
BEGIN
   SELECT @ApplicationFee = @ApplicationFee * 2
END

/* Insert Basic Permit Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, @FeeCode, 'Y', 
         @ApplicationFee, 
         0, 0, getdate(), @UserId )

/* Insert Clerks Filing Fee */

SELECT @NextRSN= @NextRSN + 1 
INSERT INTO AccountBillFee 
  ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @Zoning_Permit_Filing_Fee, 
   0, 0, getdate(), @UserId )

GO
