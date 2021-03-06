USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_CBC_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultFee_CBC_Folder]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
  
/* CBC Folder Initialize */

DECLARE @intSubCode INT
DECLARE @intWorkCode INT
DECLARE @varBoardName VARCHAR(60)
DECLARE @intBoardFolderCount INT
DECLARE @varErrorText VARCHAR(200)
DECLARE @intInTime INT
DECLARE @intBoardPeopleRSN INT
DECLARE @varAppointedBy VARCHAR(60)
DECLARE @intTermYears INT
DECLARE @intSeatCount INT

/* Check for duplicate initialization */

SELECT @intSubCode = Folder.SubCode, @intWorkCode = Folder.WorkCode
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

SELECT @varBoardName = ValidSub.SubDesc
FROM ValidSub
WHERE ValidSub.SubCode = @intSubCode

SELECT @intBoardFolderCount = COUNT(*)
FROM Folder
WHERE Folder.FolderType = 'CBC' 
AND Folder.SubCode = @intSubCode

IF @intBoardFolderCount > 1
BEGIN
  SELECT @VarErrorText = 'A folder for ' + @varBoardName + ' has already been created. Please exit and use that one.'

  ROLLBACK TRANSACTION
  RAISERROR (@VarErrorText, 16,-1)
  RETURN
END

/* Set Folder.StatusCode to Vacancy, and Folder.FolderName to board name. */

UPDATE Folder
SET Folder.StatusCode = 40000, Folder.FolderName = @varBoardName 
WHERE Folder.FolderRSN = @FolderRSN 

/* Add initialization time to Folder.InDate */
/* NOTE: AMANDA Browser Version (AMANDA 5) includes the time as part of InDate.
         AMANDA Desktop Version does NOT inlcude the time as of InDate.
         The code below tests to see if time is included and tacks on the time if not.  */ 

SELECT @intInTime = DATEPART(HOUR,Indate) FROM Folder WHERE FolderRSN = @FolderRSN

IF @intInTime = 0
BEGIN
   UPDATE Folder
      SET Folder.InDate = DATEADD(hour, datepart(hour, getdate()), Folder.InDate)
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE Folder
      SET Folder.InDate = DATEADD(minute, datepart(minute, getdate()), Folder.InDate)
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN
END

/* Insert People record for the Commission or Board.  Entry of SubCode is required at initialization. */

SELECT @intBoardPeopleRSN = dbo.udf_GetCBCBoardPeopleRSNFromSubCode(@intSubCode) 

IF @intBoardPeopleRSN > 0
BEGIN
	INSERT INTO FolderPeople 
		( FolderRSN, PeopleRSN, PeopleCode, PrintFlag, StampDate, StampUser )
	VALUES ( @FolderRSN, @intBoardPeopleRSN, 40000, 'Y', getdate(), @UserID )
END

/* Populate FolderInfo fields with values from PeopleBoardSeat */

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

GO
