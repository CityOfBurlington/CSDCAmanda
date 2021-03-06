USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CBC_ResetDRBTermDates]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CBC_ResetDRBTermDates] 
AS 
BEGIN
	/* Procedure for testing CBC folder programming.  Delete once testing is complete.  JA 8-2013*/
	
	/* First is PeopleBoardSeat */
	
	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2012 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2016 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 1
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2010 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2014 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 2
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2011 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2015 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 3
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2010 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2014 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 4
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2011 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2015 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 5
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2011 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2015 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 6
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2012 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2016 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 7
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2011 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2015 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 8
	AND PeopleBoardSeat.SubCode = 40012 

	UPDATE PeopleBoardSeat 
	SET PeopleBoardSeat.StartDate = '07-01-2011 00:00:00.000', PeopleBoardSeat.EndDate = '06-30-2015 23:59:59.990'
	WHERE PeopleBoardSeat.SeatID = 9
	AND PeopleBoardSeat.SubCode = 40012 

	/* Next is PeopleGroup */
	
	UPDATE PeopleGroup
	SET PeopleGroup.StartDate = PeopleBoardSeat.StartDate, PeopleGroup.EndDate = PeopleBoardSeat.EndDate
	FROM PeopleGroup, PeopleBoardSeat 
	WHERE PeopleGroup.GroupRSN = 184512 
	AND CAST(PeopleGroup.Comment1 AS INT) = PeopleBoardSeat.SeatID 
	AND PeopleBoardSeat.SubCode = 40012

	/* And last is FolderPeople */
	
	UPDATE FolderPeople 
	SET FolderPeople.FromDate = PeopleBoardSeat.StartDate, FolderPeople.ToDate = PeopleBoardSeat.EndDate, 
		FolderPeople.GroupRSN = 184512 
	FROM FolderPeople, PeopleBoardSeat 
	WHERE FolderPeople.FolderRSN = 252532 
	AND CAST(FolderPeople.Comments AS INT) = PeopleBoardSeat.SeatID 
	AND PeopleBoardSeat.SubCode = 40012 
	
END

GO
