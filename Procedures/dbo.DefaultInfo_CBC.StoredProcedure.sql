USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_CBC]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultInfo_CBC]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
  
/* Set Term Length (40002), Number of Members (40003), and Appointed By (40012) to values in PeopleBoardSeat. 
   If the values are changed by City Council action, then PeopleBoardSeat must be updated manually, but such 
   changes are expected to be rare. This should keep users out of trouble as Term Length and Number of Members (Seats) 
   values are used in numerous places. This info is in the folder for easy reference only.  */

IF @InfoCode IN (40002, 40003, 40012)
BEGIN
	DECLARE @intSubCode INT
	DECLARE @intBoardPeopleRSN INT
	DECLARE @varAppointedBy VARCHAR(60)
	DECLARE @intTermYears INT
	DECLARE @intSeatCount INT
	
	SELECT @intSubCode = Folder.SubCode
	FROM Folder
	WHERE Folder.FolderRSN = @FolderRSN

	SELECT TOP 1 @intTermYears = PeopleBoardSeat.TermYears, @varAppointedBy = PeopleBoardSeat.AppointedBy 
	FROM PeopleBoardSeat 
	WHERE PeopleBoardSeat.SubCode = @intSubCode 

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = @intTermYears, FolderInfo.InfoValueNumeric = @intTermYears
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = 40002			/* Member Term Length */

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = @varAppointedBy, FolderInfo.InfoValueUpper = UPPER(@varAppointedBy) 
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = 40012			/* Appointed By */

	SELECT @intSeatCount = COUNT(*)
	FROM PeopleBoardSeat 
	WHERE PeopleBoardSeat.SubCode = @intSubCode 

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = @intSeatCount, FolderInfo.InfoValueNumeric = @intSeatCount
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = 40003			/* Number of Members Appointed */
END

GO
