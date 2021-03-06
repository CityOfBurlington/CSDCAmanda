USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZN_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZN_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @FeeCode int
DECLARE @Zoning_Permit_Filing_Fee float               /* Filing Fee */
DECLARE @FilingFeeOption varchar(3)

/* Set Filing Fee - it is $14 because permits are two pages, however the 
   non-applicablity form is one page, so half the fee. */

SELECT @Zoning_Permit_Filing_Fee = ValidLookup.LookupFee * 0.5
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 2 )

/* Get Filing Fee Option */

SELECT @FilingFeeOption = FolderInfo.InfoValue
  FROM FolderInfo
 WHERE FolderRSN = @folderRSN
   AND InfoCode = 10066

/* Clerks Filing Fee */

IF @FilingFeeOption = 'Yes'
BEGIN
   SELECT @NextRSN= @NextRSN + 1 
   INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, 
            BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
            @Zoning_Permit_Filing_Fee, 
            0, 0, getdate(), @UserId )
END
GO
