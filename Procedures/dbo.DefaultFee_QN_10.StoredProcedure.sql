USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_QN_10]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_QN_10]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @m_Code_Enforcement_Fees float 
SELECT @m_Code_Enforcement_Fees = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 16 ) 
   AND ( ValidLookup.Lookup1 = 9)





/* Compliance Memo Fees */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 207, 'Y', 
         @m_Code_Enforcement_Fees, 
         0, 0, getdate(), @UserId )


GO
