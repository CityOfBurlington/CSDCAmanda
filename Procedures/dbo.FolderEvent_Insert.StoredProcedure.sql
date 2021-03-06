USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[FolderEvent_Insert]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.FolderEvent_Insert    Script Date: 11/10/00 10:24:18 AM ******/
CREATE PROC [dbo].[FolderEvent_Insert] @argFolderRSN int, @argStampUser varchar(8), 
@argNumberOfEvent int, @argFrequency varchar(30), @argStartDate datetime,
@argStartTime varchar(10), @argEndTime varchar(10), @argFlag char(1) 

AS 

/*******************************************************
* Procedure	:	FolderEvent_Insert
* File		:	p_eventi.sql
* Paremeters:  argFolderRSN, argStampUser, argNumberOfEvent,
*	argFrequency, argStartDate, argStartTime, argEndTime, 
*	argFlag ('N' for 'New', 'R' for 'Re-default')
*********************************************************/

DECLARE @i int 
DECLARE @EventDate datetime 
DECLARE @NumberOfEvent int 
DECLARE @MyCount int 

DECLARE @NextDay int
DECLARE @NextMonth int
DECLARE @NextYear int

DECLARE @StartDay int
DECLARE @StartMonth int
DECLARE @StartYear int
DECLARE @TempMonth int
DECLARE @LAST_DAY datetime

IF ( upper(@argFrequency) <> 'ONCE' AND upper(@argFrequency) <> 'DAILY' AND upper(@argFrequency) <> 'WEEKLY' AND upper(@argFrequency) <> 'MONTHLY' AND upper(@argFrequency) <> 'YEARLY' AND upper(@argFrequency) <> 'BI-MONTHLY' AND upper(@argFrequency) <> 'BI-WEEKLY'  ) RETURN

SELECT @i = 0 

IF upper(@argFrequency) = 'Once' 
	SELECT @NumberOfEvent = 1 
ELSE 
	SELECT @NumberOfEvent = @argNumberOfEvent 

IF @NumberOfEvent is not NULL AND @argFrequency is not NULL AND @argStartDate is not NULL AND @argStartTime is not NULL 
BEGIN
	WHILE @i < @NumberOfEvent  
	BEGIN
		IF upper(@argFrequency) = 'DAILY' 
			SELECT @EventDate = DATEADD(day, @i, @argStartDate)

		IF upper(@argFrequency) = 'WEEKLY' 
			SELECT @EventDate = DATEADD(week, @i, @argStartDate)

		IF upper(@argFrequency) = 'MONTHLY' 
			SELECT @EventDate = DATEADD(month, @i, @argStartDate) 

		IF upper(@argFrequency) = 'YEARLY' 
			SELECT @EventDate = DATEADD(year, @i, @argStartDate) 

		IF upper(@argFrequency) = 'ONCE' 
			SELECT @EventDate = @argStartDate 
			
		IF upper(@argFrequency) = 'BI-MONTHLY' 
		BEGIN
			SELECT @StartDay   = DATEPART(day, @argStartDate)
			SELECT @StartMonth = DATEPART(month, @argStartDate)
			SELECT @StartYear  = DATEPART(year, @argStartDate)
            			IF (@i % 2) = 0 
			BEGIN
            				SELECT @NextMonth = (@StartMonth + FLOOR(@i/2) - 1) % 12  + 1
				SELECT @NextYear  = @StartYear + FLOOR((@StartMonth + FLOOR(@i/2) - 1)/12)
                  			IF @StartDay > 15 
				BEGIN
					IF @NextMonth = 12
						SELECT @TempMonth = 1
					ELSE
						SELECT @TempMonth = @NextMonth + 1 
					SELECT @LAST_DAY = DATEADD(day, -1, CONVERT(datetime, RTRIM(CONVERT(char(2), @TempMonth)) + '/01/' + CONVERT(char(4), @NextYear)))
                     				SELECT @NextDay = DATEPART(day, @LAST_DAY)
				END
                  			ELSE
                     				SELECT @NextDay = 15
			END
               		ELSE
			BEGIN
                  			IF @StartDay > 15 
				BEGIN
                     				SELECT @NextDay   = 15
                     				SELECT @NextMonth = (@StartMonth + FLOOR(@i/2)) % 12 + 1
                     				SELECT @NextYear  = @StartYear + FLOOR((@StartMonth + FLOOR(@i/2)) / 12)
				END
                  			ELSE
				BEGIN
                     				SELECT @NextMonth = (@StartMonth + FLOOR(@i/2) - 1) % 12 + 1
                     				SELECT @NextYear  = @StartYear + FLOOR((@StartMonth + FLOOR(@i/2) - 1) / 12) 
					IF @NextMonth = 12
						SELECT @TempMonth = 1
					ELSE
						SELECT @TempMonth = @NextMonth + 1
					SELECT @LAST_DAY = DATEADD(day, -1, CONVERT(datetime, RTRIM(CONVERT(char(2), @TempMonth)) + '/01/' + CONVERT(char(4), @NextYear)))
                     				SELECT @NextDay = DATEPART(day, @LAST_DAY)
				END
			END
              		SELECT @EventDate = CONVERT(datetime, RTRIM(CONVERT(char(2), @NextMonth)) + '/' + RTRIM(CONVERT(char(2), @NextDay)) +'/' + CONVERT(char(4), @NextYear))
		END

		IF upper(@argFrequency) = 'BI-WEEKLY' 
			SELECT @EventDate = DATEADD(week, @i * 2, @argStartDate)

		IF @argFlag = 'N'
			SELECT @MyCount = 0
		ELSE
			SELECT @MyCount = ( SELECT count(*) FROM FolderEvent 
 					WHERE FolderEvent.FolderRSN = @argFolderRSN 
   					AND FolderEvent.EventDate = @EventDate ) 

		IF @MyCount < 1 
			INSERT INTO FolderEvent ( FolderRSN, EventDate, StartTime,
				EndTime, Attendance, GrossIncome, Prizes, Expenses, 	
				SumGrossIncome, SumPrizes, SumExpenses, Proceeds, 					ExpensePercent, NetProceedPercent, IncomePerCapita,
				MaxPrize, StampDate, StampUser ) 
			VALUES ( @argFolderRSN, @EventDate, @argStartTime, 
				@argEndTime,
				0, 0.00, 0.00, 0.00, 0.00, 0.00, 
				0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
				GetDate(), @argStampUser )  

		SELECT @i = @i + 1  
	END
END



GO
