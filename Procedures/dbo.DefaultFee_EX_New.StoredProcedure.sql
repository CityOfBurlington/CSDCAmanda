USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_EX_New]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_EX_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @strHasAdminFee           Varchar(3)
DECLARE @strHasDoubleFees         Varchar(3)
DECLARE @varAdminRate             Money

DECLARE @Sidewalk_Excavated_sqft float 
DECLARE @GreenbeltCurb_Excavated_sqft float 
DECLARE @Road_Excavated_sqft float 
DECLARE @RateForRoad float 
DECLARE @RateForSidewalk float 
DECLARE @RateForGreenbelt float 
DECLARE @CalculatedFee float

SELECT @strHasDoubleFees = ISNULL(FolderInfo.InfoValueUpper, 'NO')
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30135

SELECT @strHasAdminFee = ISNULL(FolderInfo.InfoValueUpper, 'NO')
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30134

SELECT @Sidewalk_Excavated_sqft = ISNULL(FolderInfo.InfoValueNumeric,0) 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30042 )

SELECT @GreenbeltCurb_Excavated_sqft = ISNULL(FolderInfo.InfoValueNumeric,0)
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30043 )

SELECT @Road_Excavated_sqft = ISNULL(FolderInfo.InfoValueNumeric,0)
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30041 )

SELECT @RateForRoad = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1 = 1 )

SELECT @RateForSidewalk = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1 = 2 )

SELECT @RateForGreenbelt = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1 = 3 )

DECLARE @intFeeCode INT

IF @strHasAdminFee = 'YES'
	BEGIN	
		SELECT @varAdminRate = ValidLookup.LookupFee
		FROM ValidLookup 
		WHERE (ValidLookup.LookupCode = 6) 
		AND (ValidLookup.Lookup1 = 10)

		SET @CalculatedFee = (@Sidewalk_Excavated_sqft * @varAdminRate) + 
                (@GreenbeltCurb_Excavated_sqft * @varAdminRate) + 
                (@Road_Excavated_sqft * @varAdminRate)

                SET @intFeeCode = 172

                IF @strHasDoubleFees = 'YES'
                           BEGIN
                           SET @CalculatedFee = @CalculatedFee * 2
                END
	END
ELSE
	BEGIN
		SET @CalculatedFee = (@Sidewalk_Excavated_sqft * @RateForSidewalk)+
		(@GreenbeltCurb_Excavated_sqft * @RateForGreenbelt) +
		(@Road_Excavated_sqft * @RateForRoad)

                SET @intFeeCode = 170

                IF @strHasDoubleFees = 'YES'
                           BEGIN
                           SET @CalculatedFee = @CalculatedFee * 2
                END
	END


/* Excavation Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, @intFeeCode, 'Y', 
         @CalculatedFee, 
         0, 0, getdate(), @UserId )


GO
