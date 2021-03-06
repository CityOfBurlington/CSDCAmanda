USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZH_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZH_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Public Hearing Fees for Conditional Use, Home Occupation, 
   Major Impact Review, and Variance. */

DECLARE @FolderType varchar(4)
DECLARE @WorkCode int
DECLARE @AVCFee float
DECLARE @MIPFee float
DECLARE @MIPRate1 float
DECLARE @MIPRate2 float
DECLARE @EstConstCost int
DECLARE @NewSQFt int
DECLARE @CalculatedFee float
DECLARE @SqftFee float
DECLARE @CostFee Float
DECLARE @ClerkFee Float

SELECT @FolderType = Folder.FolderType, 
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @EstConstCost= FolderInfo.InfoValueNumeric
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10000

SELECT @AVCFee = ValidLookup.LookupFee       /* Appeal, CU, HO, Variance */
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 3 ) 
   AND ( ValidLookup.Lookup1 =19 )

SELECT @MIPFee= ValidLookup.LookupFee        /* Base Rate for Major Impact */
  FROM ValidLookup
 WHERE (ValidLookup.LookupCode = 3)
   AND (ValidLookup.Lookup1 = 20)

SELECT @MIPRate1 = ValidLookup.LookupFee     /* Major Impact based upon ECC */
  FROM ValidLookup
  WHERE (ValidLookup.LookupCode = 3)
    AND (ValidLookup.Lookup1 = 21)

SELECT @MIPRate2 = ValidLookup.LookupFee     /* Major Impact based upon sq ft */
  FROM ValidLookup
 WHERE (ValidLookup.LookupCode = 3)
   AND (ValidLookup.Lookup1 = 4)

SELECT @ClerkFee = ValidLookup.LookupFee     /* Filing Fee */
  FROM ValidLookup
 WHERE (ValidLookup.LookupCode = 3)
   AND (ValidLookup.Lookup1 = 2)

/* Calculate and Insert Major Impact Review Fee */

IF @WorkCode = 10002  
BEGIN
   SELECT @NewSqFt = FolderInfo.InfoValueNumeric
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10008

   SELECT @CostFee = @MIPRate1 * @EstConstCost
   SELECT @SqFtFee = @MIPRate2 * @NewSqFt

   IF @CostFee >= @SqftFee SELECT @CalculatedFee = @MIPFee + @CostFee
   ELSE SELECT @CalculatedFee = @MIPFee + @SqFtFee

   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
             ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
               FeeAmount, 
               BillNumber, BillItemSequence, StampDate, StampUser ) 
      VALUES ( @NextRSN, @FolderRSN, 136, 'Y', 
               @CalculatedFee, 
               0, 0, getdate(), @UserId )
END

/* Calculate and Insert other Public Hearing Fees - Conditional Use, 
   Home Occupation, Variance */

IF @WorkCode IN(10000, 10001, 10003)
BEGIN
   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, 
            BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 135, 'Y', 
            @AVCFee, 
            0, 0, getdate(), @UserId )
END

/* Insert Clerk's Filing Fee. 
   For Combined Review (ZC) folders, the Clerk Filing Fee is added twice - one 
   for the COA and the other for conditional use, variance, etc.  This may change 
   to one filing fee, in which case insert for ZH folders only. */

   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
             ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
               FeeAmount, 
               BillNumber, BillItemSequence, StampDate, StampUser ) 
      VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
               @ClerkFee, 
               0, 0, getdate(), @UserId )


GO
