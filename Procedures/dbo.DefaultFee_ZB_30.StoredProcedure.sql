USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZB_30]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZB_30]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @TempCofOFee float

SELECT @TempCofOFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 15 ) 
   AND ( ValidLookup.Lookup1 = 1 )


/* Temporary C of O Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 162, 'Y', 
         @TempCofOFee, 
         0, 0, getdate(), @UserId )

GO
