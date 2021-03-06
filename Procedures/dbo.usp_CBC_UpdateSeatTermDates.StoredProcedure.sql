USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CBC_UpdateSeatTermDates]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CBC_UpdateSeatTermDates] (@dtReferenceDate datetime)
AS 
BEGIN
	/* Daily procedure that checks term end dates in Amanda_Production.PeopleBoardSeat for the CBC Folder. 
	   For members whose terms have expired, calls dbo.usp_CBC_UpdateSeatTermDateSeat to: 
			- Advance the term dates in PeopleBoardSeat
			- Set PeopleBoardSeat.PeopleRSN to zero (0) to flag the seat as open 
			- Set FolderPeople.PeopleCode and GroupGroup.MemberCode to Pending 
			- Set CBC Folder.StatusCode to Vacancy			JA 8/2013 */
	
	/* Currently in test mode for the DRB only. The clause to delete for going live is noted below. JA 8/21/2013 */
	
	DECLARE @intSeatRSN int
	DECLARE @intSubCode int
	DECLARE @intPeopleRSN int 
	DECLARE @intBoardFolderRSN int 

	DECLARE UpdateSeats CURSOR FOR
	SELECT PeopleBoardSeat.SeatRSN, PeopleBoardSeat.SubCode, PeopleBoardSeat.PeopleRSN 
	FROM PeopleBoardSeat
	WHERE PeopleBoardSeat.EndDate < @dtReferenceDate 
	AND PeopleBoardSeat.SubCode = 40012			/* DRB - DELETE this clause when done with testing */

	OPEN UpdateSeats
	FETCH NEXT FROM UpdateSeats INTO @intSeatRSN, @intSubCode, @intPeopleRSN
	WHILE @@Fetch_Status = 0 
	BEGIN
		EXECUTE dbo.usp_CBC_UpdateSeatTermDateSeat @intSeatRSN, @intSubCode, @intPeopleRSN 
		
		EXECUTE dbo.usp_CBC_UpdateFolderLog @intBoardFolderRSN
		
		FETCH NEXT FROM UpdateSeats INTO @intSeatRSN, @intSubCode, @intPeopleRSN 
	END    
	CLOSE UpdateSeats
	DEALLOCATE UpdateSeats 
END

GO
