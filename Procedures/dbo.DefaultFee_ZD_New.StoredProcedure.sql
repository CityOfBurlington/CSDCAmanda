USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZD_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZD_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @LookupCode int
DECLARE @DeterminationType int                       /* Folder.Workcode */
DECLARE @Zoning_Determination_Fee float              /* Determination Fee */
DECLARE @Zoning_Determination_Filing_Fee float       /* Filing Fee */

SELECT @DeterminationType = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @LookupCode = 
  CASE @DeterminationType
    WHEN 10028 THEN 2         /* Functional Family */
    ELSE 1
  END

SELECT @Zoning_Determination_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 17 ) 
   AND ( ValidLookup.Lookup1 = @LookupCode )

SELECT @Zoning_Determination_Filing_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 = 2 )

/* Insert Determination Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 150, 'Y', 
         @Zoning_Determination_Fee, 
         0, 0, getdate(), @UserId )

/* Insert Clerks Filing Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @Zoning_Determination_Filing_Fee, 
         0, 0, getdate(), @UserId )

GO
