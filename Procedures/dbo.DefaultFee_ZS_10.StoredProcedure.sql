USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZS_10]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZS_10]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* ZS Sketch Plan Additional Board Review Fee Procedure */

/* Assumes one additional board, which is almost always the case, if it occurs */

DECLARE @SketchPlan_Fee1 float    
DECLARE @SketchPlan_Fee2 float    
DECLARE @CalculatedFee float
DECLARE @FeeCode1 int
DECLARE @FeeCode2 int

/* This part is the initialization - not used here */

SELECT @SketchPlan_Fee1 = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3  
   AND ValidLookup.Lookup1 = 18              /* Initial fee - 1 board */

SELECT @FeeCode1 = 140

/* This part for additional board review */

SELECT @SketchPlan_Fee2 = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 17             /* Additional board fee rate */

SELECT @FeeCode2 = 142

/* Set and insert the additional board review fee */
 
SELECT @CalculatedFee = @SketchPlan_Fee2

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, @FeeCode2, 'Y', 
         @CalculatedFee, 
         0, 0, getdate(), @UserId )

GO
