USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z2_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z2_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Z2 Permit Application Fee */

/* Runs at initialization */

DECLARE @Z2_Base_Rate float      /* Level 2 base rate */
DECLARE @Z2_ECC_Rate float       /* rate per $1000 construction cost */
DECLARE @Z2_SqFt_Rate float      /* rate per square foot */
DECLARE @Z2_Filing_Fee float     /* Clerk's Filing Fee */
DECLARE @Estimated_Construction_Cost  float 
DECLARE @Estimated_Construction_Cost_Fee float
DECLARE @Net_New_Sq_Ft float
DECLARE @Net_New_Sq_Ft_Fee float
DECLARE @Violation varchar(3) 
DECLARE @CalculatedFee float
DECLARE @DevelopmentReviewFlag varchar(2)

SELECT @Z2_Base_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3
   AND ValidLookup.Lookup1 = 16

SELECT @Z2_ECC_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3
   AND ValidLookup.Lookup1 = 6

SELECT @Z2_SqFt_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3
   AND ValidLookup.Lookup1 = 4

SELECT @Z2_Filing_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3
   AND ValidLookup.Lookup1 = 2

SELECT @Estimated_Construction_Cost = ISNULL(FolderInfo.InfoValueNumeric, 0)
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10000

SELECT @Net_New_Sq_Ft = ISNULL(FolderInfo.InfoValueNumeric, 0) 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10008

SELECT @Violation = UPPER(FolderInfo.InfoValue) 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10043

SELECT  @Estimated_Construction_Cost_Fee = @Estimated_Construction_Cost  * @Z2_ECC_Rate

SELECT  @Net_New_Sq_Ft_Fee = @Net_New_Sq_Ft * @Z2_SqFt_Rate

SELECT @CalculatedFee  = @Estimated_Construction_Cost_Fee

IF @Net_New_Sq_Ft_Fee > @CalculatedFee SELECT @CalculatedFee = @Net_New_Sq_Ft_Fee

/* Add base level fee to the greater of est const cost or sq ft calc*/

SELECT @CalculatedFee = @CalculatedFee  + @Z2_Base_Rate 

IF @Violation = 'YES' SELECT @CalculatedFee = @CalculatedFee  * 2

/* Insert COA Level 2 Application Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 95, 'Y', 
         @CalculatedFee , 
         0, 0, getdate(), @UserId )

/* Insert Clerks Filing Fee*/

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @Z2_Filing_Fee, 
         0, 0, getdate(), @UserId ) 

/* Insert Level 2 Development Review Fee */

SELECT @DevelopmentReviewFlag = dbo.udf_ZoningDevReviewFeeFlag(@FolderRSN) 

IF @DevelopmentReviewFlag = 'Y' EXECUTE DefaultFee_Z2_10 @folderRSN, @UserID



GO
