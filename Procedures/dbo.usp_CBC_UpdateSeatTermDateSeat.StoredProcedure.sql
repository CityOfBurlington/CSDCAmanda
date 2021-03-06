USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CBC_UpdateSeatTermDateSeat]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CBC_UpdateSeatTermDateSeat] (@intSeatRSN int, @intSubCode int, @intPeopleRSN int)
AS 
BEGIN
	DECLARE @intBoardFolderRSN int 

	UPDATE PeopleBoardSeat
	SET PeopleBoardSeat.StartDate = DATEADD(YEAR, PeopleBoardSeat.TermYears, PeopleBoardSeat.StartDate), 
		PeopleBoardSeat.EndDate = DATEADD(YEAR, PeopleBoardSeat.TermYears, PeopleBoardSeat.EndDate), 
		PeopleBoardSeat.PeopleRSN = 0 
	WHERE PeopleBoardSeat.SeatRSN = @intSeatRSN 
		
/*	Looks like this is not needed  JA 23-Aug-13

	DECLARE @dtNewStartDate datetime
	DECLARE @dtNewEndDate datetime
	DECLARE @intBoardPeopleRSN int 
	
	SELECT @dtNewStartDate = PeopleBoardSeat.StartDate, @dtNewEndDate = PeopleBoardSeat.EndDate 
	FROM PeopleBoardSeat 
	WHERE PeopleBoardSeat.SeatRSN = @intSeatRSN 
		
	SELECT @intBoardPeopleRSN = dbo.udf_GetCBCBoardPeopleRSNFromSubCode(@intSubCode) */
		
	SELECT @intBoardFolderRSN = dbo.udf_GetCBCBoardFolderRSNFromSubCode(@intSubCode) 
		
	UPDATE FolderPeople 
	SET FolderPeople.PeopleCode = 40011					/* Pending */
	WHERE FolderPeople.FolderRSN = @intBoardFolderRSN 
	AND FolderPeople.PeopleRSN = @intPeopleRSN 
		
	UPDATE PeopleGroup 
	SET PeopleGroup.MemberCode = 40011					/* Pending */
	FROM PeopleGroup, FolderPeople 
	WHERE PeopleGroup.PeopleRSN = @intPeopleRSN
	AND PeopleGroup.GroupRSN = FolderPeople.PeopleRSN 
	AND FolderPeople.PeopleCode = 40000					/* Commission, Board, Committee */
	AND FolderPeople.FolderRSN = @intBoardFolderRSN 
		
	UPDATE Folder 
	SET Folder.StatusCode = 40000		/* Vacancy */
	WHERE Folder.FolderRSN = @intBoardFolderRSN 
END
GO
