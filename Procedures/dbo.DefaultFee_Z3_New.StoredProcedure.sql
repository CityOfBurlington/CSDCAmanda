USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z3_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z3_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Z3 Permit Application Fee */

/* Runs at initialization */

DECLARE @Z3_Unit_Rate float               /* Rate per Lot or Unit */
DECLARE @Z3_Base_Rate float               /* Level 3 Base rate */
DECLARE @Z3_ECC_Rate float                /* Rate per $1000 Const Cost */
DECLARE @Z3_SqFt_Rate float               /* Rate per square foot */
DECLARE @Z3_Lot_Line float                /* Flat fee for lot line adjustments and mergers */
DECLARE @Z3_Filing_Fee float              /* Clerk Filing Fee */
DECLARE @WorkCode int
DECLARE @DevelopmentReviewFlag varchar(2)
DECLARE @Level3ReviewType varchar(4)
DECLARE @Estimated_Construction_Cost float 
DECLARE @Estimated_Construction_Cost_Fee float
DECLARE @Net_New_Sq_Ft float 
DECLARE @Net_New_Sq_Ft_Fee float 
DECLARE @Net_New_Units float
DECLARE @Net_New_Units_Fee float
DECLARE @Violation varchar(3)
DECLARE @Calculated_Fee_1 float
DECLARE @Calculated_Fee_2 float

/* Get review type, fee base, fee rates, filing fee */

SELECT @WorkCode = Folder.WorkCode              /* Prelim, Final, Combo Plats */
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN 

SELECT @Level3ReviewType = dbo.udf_GetZoningLevel3ReviewType(@FolderRSN)

SELECT @Z3_Base_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 5

SELECT @Z3_Unit_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 3

SELECT @Z3_SqFt_Rate = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3
   AND ValidLookup.Lookup1 = 4

SELECT @Z3_Lot_Line = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3
   AND ValidLookup.Lookup1 = 24

IF @WorkCode = 10011              /* Preliminary and Final Plat Combination */
BEGIN
   SELECT @Z3_ECC_Rate = ValidLookup.LookupFee
     FROM Validlookup
    WHERE ValidLookup.LookupCode = 3
      AND ValidLookup.Lookup1 = 12
END
ELSE
BEGIN
   SELECT @Z3_ECC_Rate = ValidLookup.LookupFee
     FROM Validlookup
    WHERE ValidLookup.LookupCode = 3 
      AND ValidLookup.Lookup1 = 6 
END

SELECT @Z3_Filing_Fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 2 

/* Preliminary Plat does not get a Certificate of Occupancy, so the filing fee is 
   for one page only. */

IF @WorkCode = 10009 SELECT @Z3_Filing_Fee = @Z3_Filing_Fee * 0.5

/* Get project info */

SELECT @Estimated_Construction_Cost = ISNULL(FolderInfo.InfoValueNumeric, 0)
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10000

SELECT @Net_New_Units = ISNULL(FolderInfo.InfoValueNumeric, 0)
  FROM FolderInfo
 WHERE Folderinfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10016

SELECT @Net_New_Sq_Ft = ISNULL(FolderInfo.InfoValueNumeric, 0)
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10008 

SELECT @Violation = UPPER(FolderInfo.InfoValue) 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10043 

/* Calculate fees */

IF @Level3ReviewType IN ('LLA', 'LM') SELECT @Calculated_Fee_2 = @Z3_Lot_Line
ELSE 
BEGIN
   SELECT @Net_New_Units_Fee = ( @Net_New_Units * @Z3_Unit_Rate )

   SELECT @Estimated_Construction_Cost_Fee = ( @Estimated_Construction_Cost * @Z3_ECC_Rate ) + @Z3_Base_Rate

   SELECT @Net_New_Sq_Ft_Fee = ( @Net_New_Sq_Ft * @Z3_SqFt_Rate ) + @Z3_Base_Rate

   IF @Estimated_Construction_Cost_Fee >= @Net_New_Sq_Ft_Fee 
      SELECT @Calculated_Fee_1 = @Estimated_Construction_Cost_Fee
   ELSE 
      SELECT @Calculated_Fee_1 = @Net_New_Sq_Ft_Fee

   IF @Calculated_Fee_1 >= @Net_New_Units_Fee 
      SELECT @Calculated_Fee_2 = @Calculated_Fee_1
   ELSE 
      SELECT @Calculated_Fee_2 = @Net_New_Units_Fee
END

IF @Violation = 'YES' SELECT @Calculated_Fee_2 = @Calculated_Fee_2 * 2

/* Insert COA Level 3 Application Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 100, 'Y', 
         @Calculated_Fee_2, 
         0, 0, getdate(), @UserId )

/* Insert Clerks Filing Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
         @Z3_Filing_Fee, 
         0, 0, getdate(), @UserId )

/* Insert Level 3 Development Review Fee as appropriate */

SELECT @DevelopmentReviewFlag = dbo.udf_ZoningDevReviewFeeFlag(@FolderRSN) 

IF @DevelopmentReviewFlag = 'Y' EXECUTE DefaultFee_Z3_10 @FolderRSN, @UserID


GO
