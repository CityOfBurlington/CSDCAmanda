USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZB_10]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZB_10]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @FeeLookup1 int
DECLARE @TrafficRate float
DECLARE @FireRate Float
DECLARE @PoliceRate Float
DECLARE @ParksRate Float
DECLARE @LibraryRate Float
DECLARE @SchoolsRate Float
DECLARE @TrafficFee float
DECLARE @FireFee Float
DECLARE @PoliceFee Float
DECLARE @ParksFee Float
DECLARE @LibraryFee Float
DECLARE @SchoolsFee Float
DECLARE @FeeType varchar(1000)
DECLARE @Feesqftg int

SELECT @FeeType = FolderInfo.InfoValue   /* Industrial, Office, Residential, or Retail */
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode = 10059 

SELECT @Feesqftg = FolderInfo.InfoValueNumeric
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10060

SELECT @FeeLookup1 = 
CASE @FeeType 
   WHEN 'Industrial' THEN 2
   WHEN 'Office' THEN 3
   WHEN 'Residential' THEN 1
   WHEN 'Retail' THEN 4
END

/* Calculate Impact Fees by Department */

SELECT @TrafficRate = ISNULL(ValidLookup.LookupFee, 0) 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 2 
   AND ValidLookup.Lookup1 = @FeeLookup1
   AND ValidLookup.Lookup2 = 1

SELECT @TrafficFee = @TrafficRate * @Feesqftg

SELECT @FireRate = ISNULL(ValidLookup.LookupFee, 0)
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 2 
   AND ValidLookup.Lookup1 = @FeeLookup1
   AND ValidLookup.Lookup2 = 2

SELECT @FireFee = @FireRate * @Feesqftg

SELECT @PoliceRate = ISNULL(ValidLookup.LookupFee, 0)
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 2 
   AND ValidLookup.Lookup1 = @FeeLookup1
   AND ValidLookup.Lookup2 = 3

SELECT @PoliceFee = @PoliceRate * @Feesqftg

SELECT @ParksRate = ISNULL(ValidLookup.LookupFee, 0) 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 2 
   AND ValidLookup.Lookup1 = @FeeLookup1
   AND ValidLookup.Lookup2 = 4

SELECT @ParksFee = @ParksRate * @Feesqftg

SELECT @LibraryRate = ISNULL(ValidLookup.LookupFee, 0)
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 2 
   AND ValidLookup.Lookup1 = @FeeLookup1
   AND ValidLookup.Lookup2 = 5

SELECT @LibraryFee = @LibraryRate * @Feesqftg

SELECT @SchoolsRate = ISNULL(ValidLookup.LookupFee, 0)
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 2 
   AND ValidLookup.Lookup1 = @FeeLookup1
   AND ValidLookup.Lookup2 = 6

SELECT @SchoolsFee = @SchoolsRate * @Feesqftg

/* Insert Traffic Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 190, 'Y', 
         @Trafficfee, 
         0, 0, getdate(), @UserId )

/* Insert Fire Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 191, 'Y', 
         @Firefee, 
         0, 0, getdate(), @UserId )

/* Insert Police Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 192, 'Y', 
         @Policefee, 
         0, 0, getdate(), @UserId )

/* Insert Parks Fee */

SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 193, 'Y', 
         @Parksfee, 
         0, 0, getdate(), @UserId )

/* Insert Library and Schools Fees for Residential-based projects */

IF @FeeType = 'Residential' 
BEGIN
   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, 
            BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 194, 'Y', 
            @Libraryfee, 
            0, 0, getdate(), @UserId )

   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
          ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
            FeeAmount, 
            BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 195, 'Y', 
            @Schoolsfee, 
            0, 0, getdate(), @UserId )
END


GO
