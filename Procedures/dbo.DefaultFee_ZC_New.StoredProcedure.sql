USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZC_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZC_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @varDevelopmentReviewFeeFlag varchar(2)

SELECT @varDevelopmentReviewFeeFlag = dbo.udf_ZoningDevReviewFeeFlag(@FolderRSN) 

IF @varDevelopmentReviewFeeFlag = 'Y'
   EXECUTE DefaultFee_Z2_New @FolderRSN, @UserID    /* Z2 Application Fee */
ELSE 
   EXECUTE DefaultFee_Z1_New @FolderRSN, @UserID    /* Z1 Application Fee */

EXECUTE DefaultFee_ZH_New @FolderRSN, @UserID       /* CU, HO, MI, or Variance Fee */
GO
