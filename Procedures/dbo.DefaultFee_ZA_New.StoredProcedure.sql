USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZA_New]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZA_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
EXEC RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

/* Add Sign and/or Awning Permit Application Fee(s) */

DECLARE @PerSignAwningFee float
DECLARE @PerSignFeeDiscount float
DECLARE @AwningFee float
DECLARE @ClerkFilingFee float
DECLARE @WorkCode int
DECLARE @SignNumberNMP int
DECLARE @SignNumberMP int
DECLARE @AwningNumber int
DECLARE @ViolationFlag varchar(4) 
DECLARE @SignNMPFee float
DECLARE @SignMPFee float
DECLARE @TotalFee float

SELECT @PerSignAwningFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 10 

SELECT @PerSignFeeDiscount = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 26 

SELECT @AwningFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 27 

SELECT @ClerkFilingFee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 2 

SELECT @WorkCode = Folder.WorkCode 
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @SignNumberNMP = ISNULL(FolderInfo.InfoValueNumeric, 0) 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10044 

SELECT @SignNumberMP = ISNULL(FolderInfo.InfoValueNumeric, 0) 
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10129

SELECT @AwningNumber = ISNULL(FolderInfo.InfoValueNumeric, 0)
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN  
   AND FolderInfo.InfoCode = 10045 

SELECT @ViolationFlag = FolderInfo.InfoValueUpper
  FROM FolderInfo 
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10043 

/* Sign(s) */

IF @WorkCode = 10035 
BEGIN
	SELECT @SignNMPFee = @PerSignAwningFee * @SignNumberNMP
	SELECT @SignMPFee =  ( @PerSignAwningFee * @PerSignFeeDiscount ) * @SignNumberMP 
	SELECT @TotalFee = @SignNMPFee + @SignMPFee
END

/* Awning(s) without Lettering */

IF @WorkCode = 10036 SELECT @TotalFee = @AwningFee 

/* Awning(s) with Lettering */

IF @WorkCode = 10037 SELECT @TotalFee = @PerSignAwningFee * @AwningNumber

/* Violations */

IF @ViolationFlag = 'YES' SELECT @TotalFee = @TotalFee * 2

/* Insert fees */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 105, 'Y', 
            @TotalFee, 0, 0, getdate(), @UserId )

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 80, 'Y', 
            @ClerkFilingFee, 0, 0, getdate(), @UserId )

GO
