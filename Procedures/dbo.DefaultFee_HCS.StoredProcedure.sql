USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_HCS]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_HCS]
@FolderRSN int, @UserId char(10), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @N_Starting_Tag_Number float 
SELECT @N_Starting_Tag_Number = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30200 )

DECLARE @N_Ending_Tag_Number float 
SELECT @N_Ending_Tag_Number = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30201 )


IF @N_Starting_Tag_Number > @N_Ending_Tag_Number 
    BEGIN
        RAISERROR('Ending Tag Number Must Be Equal To or Greater Than Starting Tag Number', 16, -1)
    END
GO
