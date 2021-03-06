USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_LL_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_LL_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @NextBillRSN INT
SELECT @NextBillRSN = MAX(AccountBillFeeRSN)
FROM AccountBillFee

DECLARE @i_SubCode int 
DECLARE @i_WorkCode int 
SELECT @i_SubCode = Folder.SubCode, 
       @i_WorkCode = Folder.WorkCode 
  FROM Folder 
 WHERE ( Folder.FolderRSN = @FolderRSN )

DECLARE @A_DBA_Name varchar(127) 
SELECT @A_DBA_Name = FolderInfo.InfoValue 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 7004 )

UPDATE Folder 
SET FolderName = @A_DBA_Name
WHERE FolderRSN = @FolderRSN


IF @i_SubCode = 7001 /*First Class*/
    BEGIN
        SET @NextBillRSN = @NextBillRSN + 1 

        INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser) 
        VALUES(@NextBillRSN, @FolderRSN, 701, 'Y', 100, 0, 0, getdate(), @UserId)

        SET @NextBillRSN = @NextBillRSN + 1 

        INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser) 
        VALUES(@NextBillRSN, @FolderRSN, 702, 'Y', 100, 0, 0, getdate(), @UserId)
    END 
ELSE /*Second Class*/
    BEGIN
        SET @NextBillRSN = @NextBillRSN + 1 

        INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser) 
        VALUES(@NextBillRSN, @FolderRSN, 703, 'Y', 50, 0, 0, getdate(), @UserId)

        SET @NextBillRSN = @NextBillRSN + 1 

        INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser) 
        VALUES(@NextBillRSN, @FolderRSN, 704, 'Y', 50, 0, 0, getdate(), @UserId)

    END
GO
