USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_VB_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_VB_New]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @VB_Fee FLOAT
DECLARE @FeeComment VARCHAR(100)

SET @FeeComment = 'Vacant Building Fee'

SELECT @VB_Fee = ValidLookup.LookupFee 
    FROM ValidLookup 
    WHERE (ValidLookup.LookupCode = 16) 
    AND (ValidLookUp.LookUp1 = 1)

--RAISERROR('Testing!   Does the Add Fee button call this procedure?', 16, -1)

/* Vacant Building Fee */
--EXEC TK_FEE_INSERT @FolderRSN, 202, @VB_Fee, @UserID, @FeeComment, 0, 1

GO
