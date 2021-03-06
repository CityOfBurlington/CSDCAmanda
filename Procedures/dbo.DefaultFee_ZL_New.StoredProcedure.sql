USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZL_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZL_New]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Fees for appeals of Code Enforcement and Misc Zoning decisions. */

DECLARE @WorkCode int
DECLARE @AppealDRBFee float
DECLARE @ClerkFee Float

SELECT @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @AppealDRBFee = ValidLookup.LookupFee       /* Appeal to DRB */
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 13 ) 
   AND ( ValidLookup.Lookup1 = 1 )

SELECT @ClerkFee = ValidLookup.LookupFee           /* Filing Fee */
  FROM ValidLookup
 WHERE (ValidLookup.LookupCode = 3)
   AND (ValidLookup.Lookup1 = 2)

/* Insert Fees  */

IF @WorkCode IN(10004, 10005)
BEGIN
   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, 
            BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 135, 'Y', 
            @AppealDRBFee, 
            0, 0, getdate(), @UserId )

     SELECT @NextRSN = @NextRSN + 1 
     INSERT INTO AccountBillFee 
            ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
              FeeAmount, 
              BillNumber, BillItemSequence, StampDate, StampUser ) 
     VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
              @ClerkFee, 
              0, 0, getdate(), @UserId )
END

GO
