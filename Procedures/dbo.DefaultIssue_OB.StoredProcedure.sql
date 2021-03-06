USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_OB]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_OB]
@FolderRSN int, @UserId char(10)
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


DECLARE @StartDate Datetime
DECLARE @EndDate Datetime

SELECT @StartDate = dbo.f_info_date(@FolderRSN, 30129),
@EndDate = DateAdd(d, 7 * @N_Est_No_Of_Weeks, dbo.f_info_date(@FolderRSN, 30129))


UPDATE Folder
SET FinalDate = @EndDate,
ExpiryDate = @EndDate,
FolderCondition = Cast(FolderCondition AS Varchar(4000)) 
+ char(13)
+ 'Work to commence ' 
+ Cast(DatePart(Month, @StartDate) AS Varchar(2)) + '/'
+ Cast(DatePart(Day, @StartDate) AS Varchar(2)) + '/'
+ Cast(DatePart(Year, @StartDate) AS Varchar(4))
+ ', permit expires on ' 
+ Cast(DatePart(Month, @EndDate) AS Varchar(2)) + '/'
+ Cast(DatePart(Day, @EndDate) AS Varchar(2)) + '/'
+ Cast(DatePart(Year, @EndDate) AS Varchar(4))
WHERE FolderRSN = @FolderRSN



GO
