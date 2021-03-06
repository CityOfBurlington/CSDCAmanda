USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_VB_215]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_VB_215]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Vacant Building Admin Fee */

DECLARE @VB_Fee FLOAT
DECLARE @FeeComment VARCHAR(100)

SET @FeeComment = 'Vacant Building Admin Fee'
SELECT @VB_Fee = ValidLookup.LookupFee 
    FROM ValidLookup 
    WHERE (ValidLookup.LookupCode = 16) 
    AND (ValidLookUp.LookUp1 = 11)

EXEC TK_FEE_INSERT @FolderRSN, 215, @VB_Fee, @UserID, @FeeComment, 1, 0
GO
