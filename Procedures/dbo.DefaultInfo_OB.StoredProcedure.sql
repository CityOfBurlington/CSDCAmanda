USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_OB]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_OB]
@FolderRSN int, @UserId char(10), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @N_Est_No_Of_Weeks float 

SELECT @N_Est_No_Of_Weeks = FolderInfo.InfoValueNumeric 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30051 )

DECLARE @D_Construction_Start_Date datetime 

SELECT @D_Construction_Start_Date = FolderInfo.InfoValueDateTime 
  FROM FolderInfo 
 WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
   AND ( FolderInfo.InfoCode = 30129 )


UPDATE Folder 
SET ExpiryDate = DateAdd(d, 7 * @N_Est_No_Of_Weeks, @D_Construction_Start_Date)
WHERE FolderRSN = @FolderRSN

GO
