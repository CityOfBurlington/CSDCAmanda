USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFolderPeople_CBC]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultFolderPeople_CBC]
@FolderRSN int, @UserId char(128), @PeopleRSN int, @PeopleCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

DECLARE @intFolderStatus int
DECLARE @intSubCode int 
DECLARE @varSubDesc varchar(30)
DECLARE @varPeopleTypeDesc varchar(20)
DECLARE @intBoardPeopleRSN int 
DECLARE @intPeopleBoardSeatFilledCount int
DECLARE @intSeatNumericTest int 
DECLARE @intTotalPeopleBoardSeats int
DECLARE @intTotalFolderPeopleSeats int
DECLARE @intSeatNumber int 
DECLARE @intSeatNumberMin int
DECLARE @intSeatNumberMax int
DECLARE @intSeatLinkCount int 
DECLARE @intSeatFolderPeopleCount int
DECLARE @intNewMemberSeatPeopleRSN int 
DECLARE @varPeopleCodeDesc varchar(50) 
DECLARE @varMemberCodeDesc varchar(50)
DECLARE @varMemberName varchar(100) 
DECLARE @intMemberCodePeopleGroup int 
DECLARE @intMemberCodePeopleBoardSeat int
DECLARE @varErrorMessage varchar(200) 
DECLARE @dtSeatStartDate datetime 
DECLARE @dtSeatEndDate datetime 
DECLARE @intNewPeopleCode int 
DECLARE @intNewMemberCode int 
DECLARE @intPeopleBoardSeatRSN int
DECLARE @dtMemberStartDate datetime 
DECLARE @dtMemberEndDate datetime
DECLARE @intServedYears int 
DECLARE @intPeopleBoardLogRSN int 
DECLARE @intReportBoardSeatVacantCount int 
DECLARE @intNextFolderStatusCode int
DECLARE @intPeopleInfoWardCount int
DECLARE @intPeopleInfoPartyCount int
DECLARE @intFolderPeopleInsertFlag int

/* Performs updates to the CBC folder, and associated tables: PeopleGroup, PeopleBoardSeat, and PeopleBoardLog. JA 8/2013 */

/* Test for errors. */

IF @PeopleCode NOT BETWEEN 40000 AND 40012		/* Valid PeopleCodes for CBC folder */
BEGIN
	ROLLBACK TRANSACTION
	RAISERROR ('Invalid People Type. Valid People Types are Member, New Member, Reappointed, Retired, Resigned, Chair, Vice Chair, Secretary, Alternate, and Youth.', 16, -1)
	RETURN
END

SELECT @intFolderStatus = Folder.StatusCode, @intSubCode = Folder.SubCode, @varSubDesc = ValidSub.SubDesc 
FROM Folder, ValidSub 
WHERE Folder.FolderRSN = @FolderRSN 
AND Folder.SubCode = ValidSub.SubCode 

SELECT @varPeopleTypeDesc = ValidPeople.PeopleDesc 
FROM ValidPeople 
WHERE ValidPeople.PeopleCode = @PeopleCode 

SELECT @intBoardPeopleRSN = dbo.udf_GetCBCBoardPeopleRSNFromSubCode(@intSubCode) 

IF @PeopleRSN = @intBoardPeopleRSN
BEGIN
	SELECT @varErrorMessage = 'The People Type for the Commission/Board People record may not be changed. Please update a member.'
	ROLLBACK TRANSACTION
	RAISERROR (@varErrorMessage, 16, -1)
	RETURN 
END 

IF @intFolderStatus = 40001 AND @PeopleCode IN (40007, 40008)
BEGIN
	SELECT @varErrorMessage = 'There are no open seats on the ' + @varSubDesc + ' for New Members or Reappointing members.'
	ROLLBACK TRANSACTION
	RAISERROR (@varErrorMessage, 16, -1)
	RETURN 
END 

/* Make darn sure that the proper seat number was selected by the user. */

SELECT @intTotalPeopleBoardSeats = COUNT(*)
FROM PeopleBoardSeat 
WHERE PeopleBoardSeat.SubCode = @intSubCode 

SELECT @intTotalFolderPeopleSeats = COUNT(*)
FROM FolderPeople 
WHERE FolderPeople.FolderRSN = @FolderRSN 
AND FolderPeople.PeopleCode NOT IN (40000, 40007, 40011)

SELECT @intPeopleBoardSeatFilledCount = COUNT(*)
FROM PeopleBoardSeat 
WHERE PeopleBoardSeat.SubCode = @intSubCode 
AND PeopleBoardSeat.PeopleRSN <> 0 

SELECT @intSeatNumericTest = ISNUMERIC(FolderPeople.Comments)
FROM FolderPeople 
WHERE FolderPeople.FolderRSN = @FolderRSN 
AND FolderPeople.PeopleRSN = @PeopleRSN 

IF @intSeatNumericTest = 0 
BEGIN
	SELECT @varErrorMessage = 'Please enter a Seat Number in Comments as a number, and only the number.'
	ROLLBACK TRANSACTION
	RAISERROR (@varErrorMessage, 16, -1)
	RETURN 
END

SELECT @intSeatNumber = CAST(FolderPeople.Comments AS INT) 
FROM FolderPeople 
WHERE FolderPeople.FolderRSN = @FolderRSN 
AND FolderPeople.PeopleRSN = @PeopleRSN 

SELECT @intSeatNumberMin = MIN(PeopleBoardSeat.SeatID), @intSeatNumberMax = MAX(PeopleBoardSeat.SeatID)
FROM PeopleBoardSeat 
WHERE PeopleBoardSeat.SubCode = @intSubCode 

SELECT @varMemberName = dbo.udf_GetPeopleName(@PeopleRSN) 

SELECT @intSeatLinkCount = COUNT(*)
FROM PeopleBoardSeat 
WHERE PeopleBoardSeat.SeatID = @intSeatNumber 
AND PeopleBoardSeat.SubCode = @intSubCode 

IF @intSeatLinkCount = 0 
BEGIN
	SELECT @varErrorMessage = 'The Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + ' for ' + @varSubDesc + 
		' is invalid. Valid Seat numbers are ' + RTRIM(CAST(@intSeatNumberMin AS CHAR)) + ' to ' + 
		RTRIM(CAST(@intSeatNumberMax AS CHAR)) + '. Please enter a valid open Seat Number or exit.' 
	ROLLBACK TRANSACTION
	RAISERROR (@varErrorMessage, 16, -1)
	RETURN 
END 

SELECT @intSeatFolderPeopleCount = COUNT(*) 
FROM FolderPeople
WHERE FolderPeople.FolderRSN = @FolderRSN 
AND CAST(FolderPeople.Comments AS INT) = @intSeatNumber 

IF @intSeatFolderPeopleCount > 1
BEGIN
	SELECT @varErrorMessage = 'Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + ' for ' + @varSubDesc + 
	' already has a member. If the member is Pending, Retire or Resign the member first. Otherwise, enter an open seat number.'  
	ROLLBACK TRANSACTION
	RAISERROR (@varErrorMessage, 16, -1)
	RETURN 
END 

/* Now that the proper seat number is established, get the PeopleBoardSeat.SeatRSN (primary key) for easier linking,  
   as well as other stuff. */

SELECT @intPeopleBoardSeatRSN = PeopleBoardSeat.SeatRSN,		/* Primary key  - for ease of queries below */
	@intMemberCodePeopleBoardSeat = PeopleBoardSeat.MemberCode 
FROM PeopleBoardSeat 
WHERE PeopleBoardSeat.SeatID = @intSeatNumber 
AND PeopleBoardSeat.SubCode = @intSubCode 

SELECT @intMemberCodePeopleGroup = PeopleGroup.MemberCode 
FROM PeopleGroup 
WHERE PeopleGroup.PeopleRSN = @PeopleRSN 
AND PeopleGroup.GroupRSN = @intBoardPeopleRSN 

SELECT @varPeopleCodeDesc = ValidPeople.PeopleDesc
FROM ValidPeople 
WHERE ValidPeople.PeopleCode = @PeopleCode 

SELECT @dtMemberStartDate = FolderPeople.FromDate, @dtMemberEndDate = FolderPeople.ToDate, 
	   @intServedYears = ISNULL(DATEDIFF(YEAR, FolderPeople.FromDate, FolderPeople.ToDate), 0) 
FROM FolderPeople 
WHERE FolderPeople.FolderRSN = @FolderRSN 
AND FolderPeople.PeopleRSN = @PeopleRSN 

SELECT @dtSeatStartDate = PeopleBoardSeat.StartDate, @dtSeatEndDate = PeopleBoardSeat.EndDate, 
	   @intNewPeopleCode = dbo.udf_GetCBCPeopleCodeFromMemberCode(PeopleBoardSeat.MemberCode) 
FROM PeopleBoardSeat
WHERE PeopleBoardSeat.SeatRSN = @intPeopleBoardSeatRSN 

SELECT @intNewMemberSeatPeopleRSN = ISNULL(PeopleBoardSeat.PeopleRSN, 0) 
FROM PeopleBoardSeat
WHERE PeopleBoardSeat.SeatRSN = @intPeopleBoardSeatRSN 

SELECT @intNewMemberCode = dbo.udf_GetCBCMemberCodeFromPeopleCode(@intNewPeopleCode) 

SELECT @intFolderPeopleInsertFlag = COUNT(*)		/* Zero (0) if New Member, and one (1) if Reappointing */
FROM PeopleGroup
WHERE PeopleGroup.PeopleRSN = @PeopleRSN 
AND PeopleGroup.GroupRSN = @intBoardPeopleRSN 

/* Alternate, Youth - these PeopleCodes go with the seat and do not change */

IF @PeopleCode IN (40004, 40005)
BEGIN
	IF @PeopleCode <> @intMemberCodePeopleBoardSeat 
	BEGIN
		SELECT @varErrorMessage = 'Seat ' + RTRIM(CAST(@intSeatNUMBER AS CHAR)) + ' is not a designated ' + 
			@varPeopleCodeDesc + ' seat. Please choose an eligible People Type.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
	RETURN 
	END 
END

/* Retired or Resigned Members:  
   Write membership info to PeopleBoardLog. The member's term end date written 
   to PeopleBoardLog is the only difference between Retired and Resigned.   
   Set PeopleBoardSeat.PeopleRSN to zero (0) - already done if term has passed. 
   Delete member record from FolderPeople and PeopleGroup. */

IF @PeopleCode IN (40009, 40010)		/* Retired (40009) or Resigned (40010 */
BEGIN 
	IF @intFolderPeopleInsertFlag = 0 
	BEGIN
		SELECT @varErrorMessage = 'A member can not Retire or Resign from a vacant seat (Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + 
			'). Please choose New Member or Reappointed instead.'
 
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 

	IF @intNewMemberSeatPeopleRSN <> 0 AND @PeopleCode = 40009
	BEGIN
		SELECT @varErrorMessage = 'Seat ' + RTRIM(CAST(@intSeatNUMBER AS CHAR)) + ' not yet vacant. Resign the seat instead.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 
	
	IF @intNewMemberSeatPeopleRSN = 0 AND @PeopleCode = 40010
	BEGIN
		SELECT @varErrorMessage = 'A member can not Resign from a seat that is vacant (Seat ' + RTRIM(CAST(@intSeatNUMBER AS CHAR)) + 
			'). Retire the member from the seat instead.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 

	SELECT @intPeopleBoardLogRSN = ISNULL(MAX(PeopleBoardLog.LogRSN), 0) + 1 
	FROM PeopleBoardLog 
	
	IF @PeopleCode = 40010 SELECT @dtMemberEndDate = GETDATE()
	
	SELECT @varMemberCodeDesc = ValidPeopleMember.MemberDesc
	FROM ValidPeopleMember 
	WHERE ValidPeopleMember.MemberCode = @intMemberCodePeopleBoardSeat
	
 	INSERT INTO PeopleBoardLog 
		( LogRSN, SeatRSN, SubCode, PeopleRSN, Name, ServedYears, StartDate, EndDate, Comment, StampDate, StampUser )
	VALUES 
		( @intPeopleBoardLogRSN, @intPeopleBoardSeatRSN, @intSubCode, @PeopleRSN, @varMemberName, 
		  @intServedYears, @dtMemberStartDate, @dtMemberEndDate, @varMemberCodeDesc, GETDATE(), @UserId )
	
	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.PeopleRSN = 0			/* Indicates an Open Seat */
	WHERE PeopleBoardSeat.SeatRSN = @intPeopleBoardSeatRSN 

	DELETE FROM FolderPeople 
	WHERE FolderPeople.FolderRSN = @FolderRSN 
	AND FolderPeople.PeopleRSN = @PeopleRSN 

	DELETE FROM PeopleGroup
	WHERE PeopleGroup.GroupRSN = @intBoardPeopleRSN 
	AND PeopleGroup.PeopleRSN = @PeopleRSN 
END

/* Member (40006) */

IF @PeopleCode = 40006
BEGIN
	IF @intNewMemberSeatPeopleRSN = 0 
	BEGIN
		SELECT @varErrorMessage = 'Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + ' for ' + @varSubDesc + 
			' is a vacant seat. You may want to set the People Type to New Member or Reappointed instead.' 
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 
	
	SELECT @intMemberCodePeopleGroup = dbo.udf_GetCBCMemberCodeFromPeopleCode(@PeopleCode)
	
	UPDATE PeopleGroup 
	SET PeopleGroup.MemberCode = @intMemberCodePeopleGroup 
	WHERE PeopleGroup.GroupRSN = @intBoardPeopleRSN 
	AND PeopleGroup.PeopleRSN = @PeopleRSN 
END

/* New Member (40007) */

IF @PeopleCode = 40007 
BEGIN
	IF @intNewMemberSeatPeopleRSN <> 0 
	BEGIN
		SELECT @varErrorMessage = 'Seat Number ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + ' for ' + @varSubDesc + ' is not vacant. You may need to Retire or Resign the Seat first.' 
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 
	
	IF @intFolderPeopleInsertFlag > 0		/* Returns gt 0 if the @PeopleRSN is in PeopleGroup */
	BEGIN
		SELECT @varErrorMessage = @varMemberName + ' has been in Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + 
			' until now. Please Reappoint instead.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 

	IF @intNewMemberSeatPeopleRSN = 0		/* Seat is vacant */
	BEGIN
		UPDATE PeopleBoardSeat 
		SET PeopleBoardSeat.PeopleRSN = @PeopleRSN 
		WHERE PeopleBoardSeat.SeatRSN = @intPeopleBoardSeatRSN 
		
		INSERT INTO PeopleGroup 
			( PeopleRSN, GroupRSN, MemberCode, StartDate, EndDate, Comment1, StampDate, StampUser )
		VALUES 
			( @PeopleRSN, @intBoardPeopleRSN, @intNewMemberCode, @dtSeatStartDate, @dtSeatEndDate, 
				RTRIM(CAST(@intSeatNumber AS CHAR)), GETDATE(), @UserId )
		
		/* Insert PeopleInfo fields for Ward and Party if needed */
		
		SELECT @intPeopleInfoWardCount = dbo.udf_PeopleInfoFieldExists(@PeopleRSN, 40011)
		SELECT @intPeopleInfoPartyCount = dbo.udf_PeopleInfoFieldExists(@PeopleRSN, 40013)
		
		IF @intPeopleInfoWardCount = 0
		BEGIN
			INSERT INTO PeopleInfo 
				( PeopleRSN, InfoCode, DisplayOrder, StampDate, StampUser )
			VALUES 
				( @PeopleRSN, 40011, 110, GETDATE(), @UserId )
		END

		IF @intPeopleInfoPartyCount = 0
		BEGIN
			INSERT INTO PeopleInfo 
				( PeopleRSN, InfoCode, DisplayOrder, StampDate, StampUser )
			VALUES 
				( @PeopleRSN, 40013, 120, GETDATE(), @UserId )
		END
	END
		
	UPDATE FolderPeople
	SET FolderPeople.PeopleCode = @intNewPeopleCode, 
		FolderPeople.FromDate = @dtSeatStartDate, 
		FolderPeople.ToDate = @dtSeatEndDate, 
		FolderPeople.GroupRSN = @intBoardPeopleRSN, 
		FolderPeople.StampDate = GETDATE(), FolderPeople.StampUser = @UserId 
	WHERE FolderPeople.FolderRSN = @FolderRSN 
	AND FolderPeople.PeopleRSN = @PeopleRSN
END 

/* Reappointed  - FolderPeople.PeopleCode and PeopleGroup.MemberCodes are Pending (40011) */

IF @PeopleCode = 40008
BEGIN 
	IF @intNewMemberSeatPeopleRSN > 0 
	BEGIN
		SELECT @varErrorMessage = 'Seat Number ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + ' for ' + @varSubDesc + ' is not vacant. Can not Reappoint.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 
		
	IF @intFolderPeopleInsertFlag = 0 
	BEGIN
		SELECT @varErrorMessage = 'Can not Reappoint ' + @varMemberName + ' because he/she did not hold Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + 
			' previously. Please choose New Member instead.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN 
	END 
	
	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.PeopleRSN = @PeopleRSN 
	WHERE PeopleBoardSeat.SeatRSN = @intPeopleBoardSeatRSN 

	UPDATE PeopleGroup 
	SET PeopleGroup.MemberCode = @intNewMemberCode, PeopleGroup.EndDate = @dtSeatEndDate  
	WHERE PeopleGroup.GroupRSN = @intBoardPeopleRSN 
	AND PeopleGroup.PeopleRSN = @PeopleRSN 
	
	UPDATE FolderPeople
	SET FolderPeople.ToDate = @dtSeatEndDate, FolderPeople.PeopleCode = @intNewPeopleCode, 
		FolderPeople.StampDate = GETDATE(), FolderPeople.StampUser = @UserId 
	WHERE FolderPeople.FolderRSN = @FolderRSN 
	AND FolderPeople.PeopleRSN = @PeopleRSN 
END

/* Chair, Vice Chair, Secretary */

IF @PeopleCode IN (40001, 40002, 40003)
BEGIN
	IF @intNewMemberSeatPeopleRSN = 0 
	BEGIN
		SELECT @varErrorMessage = 'Seat Number ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + 
			' is vacant. Please choose New Member or Reappointed instead.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
	END

	SELECT @intMemberCodePeopleGroup = dbo.udf_GetCBCMemberCodeFromPeopleCode(@PeopleCode)
	
	UPDATE PeopleGroup 
	SET PeopleGroup.MemberCode = @intMemberCodePeopleGroup 
	WHERE PeopleGroup.GroupRSN = @intBoardPeopleRSN 
	AND PeopleGroup.PeopleRSN = @PeopleRSN 
END

/* Pending (40011)
   NOTE: dbo.usp_CBC_UpdateSeatTermDates is set up to run daily, which in turn calls dbo.usp_CBC_UpdateSeatTermDateSeat.
   Jay decided to leave this interactive option in place in case the daily procedure stops executing. The difference is 
   that dbo.usp_CBC_UpdateSeatTermDates steps through all seats in PeopleBoardSeat (cursor) and sets the People Type to 
   Pending, whereas here this process processes only the one seat. */

IF @PeopleCode = 40011
BEGIN
	IF @dtSeatEndDate > GETDATE()
	BEGIN
		SELECT @varErrorMessage = 'Seat ' + RTRIM(CAST(@intSeatNumber AS CHAR)) + 
			' is not vacant (Term end date not passed). The system should be checking for Pending seats this daily, so contact the Amanda Administrator if it is not.'  
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
	END
	ELSE EXECUTE dbo.usp_CBC_UpdateSeatTermDateSeat @intPeopleBoardSeatRSN, @intSubCode, @PeopleRSN 
END

/* Check for vacant seats, set Folder.StatusCode accordingly, and write membership report to Folder.FolderDescription. */

SELECT @intReportBoardSeatVacantCount = dbo.udf_GetCBCVacantSeatCount(@intSubCode)

IF @intReportBoardSeatVacantCount = 0 SELECT @intNextFolderStatusCode = 40001	/* Full */
ELSE SELECT @intNextFolderStatusCode = 40000	/* Vacancy */

UPDATE Folder 
SET Folder.StatusCode = @intNextFolderStatusCode 
WHERE Folder.FolderRSN = @FolderRSN 

EXECUTE dbo.usp_CBC_UpdateFolderLog @FolderRSN

GO
