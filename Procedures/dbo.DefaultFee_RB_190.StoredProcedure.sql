USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_190]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_190]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @FeeAmount float 
DECLARE @FeeComment VARCHAR(100)

SELECT @FeeComment = FeeDesc
From ValidAccountFee
WHERE FeeCode = 200

SELECT @FeeAmount = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 9 ) 
   AND (ValidLookup.Lookup2 = 1 )

/* Code Re-Inspection Fee */
EXEC PC_FEE_INSERT @FolderRSN, 200, @FeeAmount, @UserID, 1, @FeeComment, 1, 1

GO
