USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RV_10]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RV_10]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Insert one vacant building fee - assumes one fee per property - and set 
   folder status to Active as a stop-gap measure to add proceses until 
   folder is revised. JA */

DECLARE @vacant_building_fee float 

SELECT @vacant_building_fee = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 16
   AND ValidLookup.Lookup1 = 1

SELECT @NextRSN = @NextRSN + 1 

INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 202, 'Y', 
         @vacant_building_fee, 
         0, 0, getdate(), @UserId )

UPDATE Folder
  SET Folder.StatusCode = 305
WHERE Folder.FolderRSN = @folderRSN
GO
