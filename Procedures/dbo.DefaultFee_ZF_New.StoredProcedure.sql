USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZF_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZF_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @m_Zoning_Permit_Fees1 float                    /* Fence */
SELECT @m_Zoning_Permit_Fees1 = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 9 )

DECLARE @m_Zoning_Permit_Filing_Fee float               /* Filing Fee */
SELECT @m_Zoning_Permit_Filing_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 2 )

DECLARE @B_Double_Fees__Violation varchar(3)            /* Violation = doubled fees */
SELECT @B_Double_Fees__Violation = FolderInfo.InfoValue 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 10043 )

DECLARE @calculatedfee float

SELECT @calculatedfee = @m_Zoning_Permit_Fees1

IF @B_Double_Fees__Violation = 'Yes'
BEGIN
   SELECT @calculatedfee = @calculatedfee * 2
   SELECT @m_Zoning_Permit_Filing_Fee = @m_Zoning_Permit_Filing_Fee * 2
END

/* Fence Permit Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 130, 'Y', 
         @calculatedfee, 
         0, 0, getdate(), @UserId )

/* Clerks Filing Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
  ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @m_Zoning_Permit_Filing_Fee, 
   0, 0, getdate(), @UserId )

GO
