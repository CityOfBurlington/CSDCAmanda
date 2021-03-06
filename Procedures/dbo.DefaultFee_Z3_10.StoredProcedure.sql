USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z3_10]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z3_10]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Z3 Development Review Fee */

/* Called from Application Fee procedure at folder initialization. */

DECLARE @Estimated_Construction_Cost float 
DECLARE @Net_New_Sq_Ft float   
DECLARE @Z3_DRF_ECC_Rate float      /* fee rate per $1000 estimated construction cost */
DECLARE @Z3_DRF_SqFt_Rate float     /* fee rate per net new square foot */
DECLARE @Estimated_Construction_Cost_Fee float /* Fee on construction cost */
DECLARE @Net_New_Sq_Ft_Fee float               /* Fee on square feet */
DECLARE @CalculatedFee float

SELECT @Z3_DRF_ECC_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 11 
   AND ValidLookup.Lookup2 = 3             /* construction cost rate */

SELECT @Z3_DRF_SqFt_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 11 
   AND ValidLookup.Lookup2 = 4             /* square foot rate */

SELECT @Estimated_Construction_Cost = ISNULL(FolderInfo.InfoValueNumeric,0)
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10000

SELECT @Net_New_Sq_Ft = ISNULL(FolderInfo.InfoValueNumeric,0)
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10008

SELECT @Estimated_Construction_Cost_Fee = @Estimated_Construction_Cost * @Z3_DRF_ECC_Rate

SELECT @Net_New_Sq_Ft_Fee = @Net_New_Sq_Ft * @Z3_DRF_SqFt_Rate

IF @Estimated_Construction_Cost_Fee >= @Net_New_Sq_Ft_Fee 
   SELECT @CalculatedFee = @Estimated_Construction_Cost_Fee

ELSE SELECT @CalculatedFee = @Net_New_Sq_Ft_Fee

/* Insert Development Review Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, 
            BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 146, 'Y', 
            @calculatedfee, 
            0, 0, getdate(), @UserId )

GO
