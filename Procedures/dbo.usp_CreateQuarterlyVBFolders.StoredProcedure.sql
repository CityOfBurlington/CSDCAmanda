USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateQuarterlyVBFolders]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CreateQuarterlyVBFolders]
AS
BEGIN

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure processes quarterly Vacant Building (RB) folders */
	/* Other stored procedures that work with this are:                       */
	/*	usp_CreateQuarterlyVBFolders (this sp)                                */
	/*	usp_CreateVBFolder                                                    */
	/*	DefaultFee_VB_10                                                      */
	/*	uv_VB														          */

	DECLARE @FolderRSN INT
	DECLARE @PropertyRSN INT
	--DECLARE @PriorYear INT
	--DECLARE @strPriorYear VARCHAR(4)

	DECLARE @TodayQuarter INT
	DECLARE @TodayYear INT

	DECLARE @CurrSubCode INT
	DECLARE @CurrQuarter INT
	DECLARE @CurrYear INT
	DECLARE @CurrFolderQuarter INT
	DECLARE @CurrFolderYear CHAR(2)

	DECLARE @NewSubCode INT
	DECLARE @NewQuarter INT
	DECLARE @NewYear INT
	DECLARE @NewFolderQuarter INT
	DECLARE @NewFolderYear CHAR(2)

	/* Figure out FolderQuarter and FolderYear. Since we're converting calendar year to fiscal year, this
	   is a little complicated. But it works. */
	SET @TodayQuarter = DATEPART(q, getdate())				/* Calendar Quarter for date procedure runs */
	SET @TodayYear = RIGHT(STR(DATEPART(yyyy,getdate())),2)	/* Calendar Year for date procedure runs */
	IF @TodayQuarter = 1
	BEGIN
		SET @CurrFolderQuarter = 3
		SET @CurrFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @CurrSubCode = 25003
		SET @NewFolderQuarter = 4
		SET @NewFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @NewSubCode = 25004
	END
	IF @TodayQuarter = 2
	BEGIN
		SET @CurrFolderQuarter = 4
		SET @CurrFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @CurrSubCode = 25004
		SET @NewFolderQuarter = 1
		SET @NewFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @NewSubCode = 25001
	END
	IF @TodayQuarter = 3
	BEGIN
		SET @CurrFolderQuarter = 1
		SET @CurrFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @CurrSubCode = 25001
		SET @NewFolderQuarter = 2
		SET @NewFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @NewSubCode = 25002
	END
	IF @TodayQuarter = 4
	BEGIN
		SET @CurrFolderQuarter = 2
		SET @CurrFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @CurrSubCode = 25002
		SET @NewFolderQuarter = 3
		SET @NewFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @NewSubCode = 25003
	END
		
	/* Select Folders to copy to new quarter: All VB folders from previous quarter that aren't Closed */
	DECLARE curVB CURSOR FOR
		SELECT Folder.FolderRSN, Folder.PropertyRSN
		FROM Folder 
		WHERE FolderType = 'VB' 
		AND SubCode = @CurrSubCode
		AND FolderYear = @CurrFolderYear
		AND StatusCode <> 2


	/* Create a cursor to process selected folders */
	OPEN curVB
	FETCH NEXT FROM curVB INTO @FolderRSN, @PropertyRSN
	WHILE @@FETCH_STATUS = 0
		BEGIN

		/*Call stored procedure to create a new RB Folder from this one */
		EXEC usp_CreateVBFolder @PropertyRSN, @FolderRSN, @NewFolderYear, @NewFolderQuarter, @NewSubCode	

		FETCH NEXT FROM curVB INTO @FolderRSN, @PropertyRSN
	END

	CLOSE curVB
	DEALLOCATE curVB

END


GO
