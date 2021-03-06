USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CBC_UpdateFolderLog]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CBC_UpdateFolderLog] (@intFolderRSN int)
AS 
BEGIN
	/* Procedure checks for vacant seats, and updates Folder.FolderDescription with a summary  
	   on membership status.  JA 8/2013*/
	
	DECLARE @intSubCode int
	DECLARE @varSubDesc varchar(30)
	DECLARE @intReportBoardSeatCount int
	DECLARE @intReportBoardSeatVacantCount int	
	DECLARE @varReportVacantSeatText varchar(100)
	DECLARE @intReportSeatNumber int 
	DECLARE @varDateandTime varchar(30) 
	DECLARE @intLoopCounter int
	DECLARE @intPeopleBoardSeatPeopleRSN int

	SELECT @intSubCode = Folder.SubCode 
	FROM Folder 
	WHERE Folder.FolderRSN = @intFolderRSN 
	
	SELECT @varSubDesc = ValidSub.SubDesc 
	FROM ValidSub 
	WHERE ValidSub.SubCode = @intSubCode 
   
	SELECT @intReportBoardSeatCount = COUNT(*)
	FROM PeopleBoardSeat 
	WHERE PeopleBoardSeat.SubCode = @intSubCode 

	SELECT @intReportBoardSeatVacantCount = dbo.udf_GetCBCVacantSeatCount(@intSubCode)
   
	SET @intLoopCounter = 1 
	SET @varReportVacantSeatText = 'No Vacant Seats'
	
	WHILE @intLoopCounter < ( @intReportBoardSeatCount + 1 )
	BEGIN
		SELECT @intPeopleBoardSeatPeopleRSN = PeopleBoardSeat.PeopleRSN, 
			@intReportSeatNumber = PeopleBoardSeat.SeatID 
		FROM PeopleBoardSeat
		WHERE PeopleBoardSeat.SubCode = @intSubCode 
		AND PeopleBoardSeat.SeatID = @intLoopCounter 
		
 		IF @intPeopleBoardSeatPeopleRSN = 0 
		BEGIN
			IF @varReportVacantSeatText = 'No Vacant Seats' 
				SELECT @varReportVacantSeatText = 'Seat Number(s) Vacant: #' + RTRIM(CAST(@intReportSeatNumber AS CHAR))
			ELSE 
				SELECT @varReportVacantSeatText = @varReportVacantSeatText + ', ' + RTRIM(CAST(@intReportSeatNumber AS CHAR)) 
		END 
		
		SELECT @intLoopCounter = @intLoopCounter + 1 
	END
	
	IF @varReportVacantSeatText = 'No Vacant Seats' SELECT @varReportVacantSeatText = ' ' 
		
	SELECT @varDateandTime = CONVERT(CHAR(11), getdate()) + ' at ' + CONVERT(VARCHAR(8),GETDATE(),108) 
	
	/* SELECT @varDateandTime = CONVERT(CHAR(11), getdate()) + ' at ' + RTRIM(CAST(DATEPART(HOUR, GETDATE()) AS CHAR)) + ':' + 
		RTRIM(CAST(DATEPART(MINUTE, GETDATE()) AS CHAR)) + ':' + RTRIM(CAST(DATEPART(SECOND, GETDATE()) AS CHAR)) */
	
	UPDATE Folder
	SET Folder.FolderDescription =  'Status Date: ' + @varDateandTime + ' - ' + RTRIM(@varSubDesc) + CHAR(13) + 
									'Total Number of Seats: ' + RTRIM(CAST(@intReportBoardSeatCount AS CHAR)) + '     ' + 
									'Number of Vacant Seat(s): ' + RTRIM(CAST(@intReportBoardSeatVacantCount AS CHAR)) + CHAR(13) + 
									@varReportVacantSeatText 
	WHERE Folder.FolderRSN = @intFolderRSN 
END


GO
