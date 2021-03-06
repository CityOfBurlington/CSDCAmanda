USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[f_GetNextWorkingDayXT]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[f_GetNextWorkingDayXT]
   (    @TheProcessCode int,
	@TheDay         datetime,
	@TheOffset	smallint,
	@TheType	char,
	@TheEndOffset	smallint,
	@TheEndType	char,
	@ret_date	datetime output,
	@ret_DueEndDate	datetime output)
AS

/* Amanda 43V08: Subhash June 6, 2006: Removed time part from @TheDay to compare it agains ValidHolidayOffset */


DECLARE @TheNextDate datetime,
	@ProcessDate datetime,
	@AfterDate datetime,
        @ReturnCode smallint

BEGIN


	SET @TheDay = CONVERT(DATETIME, CONVERT(CHAR(10), @TheDay, 101)) 	-- Subhash June 6, 2006 - Remove time part

	IF @TheDay IS NULL OR @TheOffset IS NULL
	BEGIN
		SELECT @ret_date = NULL
		SELECT @ReturnCode = 1
	END

	IF @TheType = 'A'
	BEGIN
		SELECT @ret_date = dateadd(day, @TheOffset, @TheDay)
		SELECT @ReturnCode = 3
		GOTO SecondPart
	END
	ELSE
	IF @TheType = 'W'
	BEGIN /* Working days */
		SELECT  @TheNextDate = ByDays.Today
			FROM ValidHolidayOffset ByDays,
				ValidHolidayOffset ByDate
		WHERE ByDays.JulianDay = ByDate.JulianDay + @TheOffset
			AND ByDate.Today = @TheDay
			AND ByDays.TodayOffset = 0
		IF @@rowcount = 0
		BEGIN
			SELECT @ret_date= dateadd(day, @TheOffset, @TheDay)
			SELECT @ReturnCode = 2
			GOTO SecondPart
		END
	END
	ELSE
	BEGIN
	/* By Calendar Days, get the first working day after x days */
		SELECT
			@TheNextDate = dateadd(day, TodayOffset, Today)
		FROM
			ValidHolidayOffset
		WHERE
			Today = dateadd(day,  @TheOffset, @TheDay)
		IF @@rowcount = 0
		BEGIN
			SELECT @ret_date = dateadd(day, @TheOffset, @TheDay)
			SELECT @ReturnCode = 3
			GOTO SecondPart
		END
	END

	SELECT @ReturnCode = 4
	IF @TheNextDate IS not NULL AND @TheProcessCode > 0
	BEGIN
		SELECT @ProcessDate =  MIN(DateStart) FROM ValidProcessDate
		WHERE ProcessCode = @TheProcessCode AND
		      DateStart >= @AfterDate
		if @ProcessDate is not NULL
		BEGIN
			SELECT @TheNextDate = @ProcessDate
		END
	END

	SELECT @ret_date =  @TheNextDate

SecondPart:
	IF @ret_date IS NULL OR @TheEndOffset IS NULL
	BEGIN
		SELECT @ret_DueEndDate = NULL
		SELECT @ReturnCode = 1
	END

	IF @TheType = 'A'
	BEGIN
			SELECT @ret_DueEndDate = dateadd(day, @TheEndOffset,
@ret_date)
			SELECT @ReturnCode = 3
			GOTO EndProc
	END
	ELSE
	IF @TheEndType = 'W'
	BEGIN /* Working days */
		SELECT  @TheNextDate = ByDays.Today
			FROM ValidHolidayOffset ByDays,
				ValidHolidayOffset ByDate
		WHERE ByDays.JulianDay = ByDate.JulianDay + @TheEndOffset
			AND ByDate.Today = @ret_date
			AND ByDays.TodayOffset = 0
		IF @@rowcount = 0
		BEGIN
			SELECT @ret_DueEndDate= dateadd(day, @TheEndOffset, @ret_date)
			SELECT @ReturnCode = 2
			GOTO EndProc
		END
	END
	ELSE
	BEGIN
	/* By Calendar Days, get the first working day after x days */
		SELECT
			@TheNextDate = dateadd(day, TodayOffset, Today)
		FROM
			ValidHolidayOffset
		WHERE
			Today = dateadd(day,  @TheEndOffset, @ret_date)
		IF @@rowcount = 0
		BEGIN
			SELECT @ret_DueEndDate = dateadd(day, @TheEndOffset,
@ret_date)
			SELECT @ReturnCode = 3
			GOTO EndProc
		END
	END

	SELECT @ReturnCode = 4

	SELECT @ret_DueEndDate =  @TheNextDate
EndProc:
	RETURN @ReturnCode
END



GO
