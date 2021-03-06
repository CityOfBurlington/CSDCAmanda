USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZP_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZP_New]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Inserts Master Plan Review fee and Clerk's filing fee. */

DECLARE @intFeeCode int
DECLARE @fltZPApplicationFee float        /* Master Plan flat fee */

SELECT @fltZPApplicationFee = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE ValidLookup.LookupCode = 3 
AND ValidLookup.Lookup1 = 25

SELECT @intFeeCode = 110

/* Insert Master Plan Review Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, @intFeeCode, 'Y', 
         @fltZPApplicationFee, 0, 0, getdate(), @UserId )

/* Insert Clerks Filing Fee */

EXECUTE dbo.usp_Zoning_Insert_Fee_Filing  @FolderRSN, @UserID

GO
