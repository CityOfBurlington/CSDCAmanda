USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CloseOldIssuedFolders]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CloseOldIssuedFolders]
AS
BEGIN

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure closes BP folders that are Issued but not closeed */ 
	/* with WorkCodes of Siding (30017), Roofing (30019), or Fences (30007)    */
	/* with IssuedDate more than 2 months ago                                  */

	DECLARE @CutOffDate DATETIME
	DECLARE @FolderRSN INT
	DECLARE @ProcessRSN INT
	DECLARE @NextAttemptRSN INT
	DECLARE @UserID VARCHAR(10)
	DECLARE @ValidClause VARCHAR(300)

	/* Figure out the date was 2 months ago. */
	SET @CutOffDate = DATEADD(month, -2, getdate())
	--SET @CutOffDate = '8/1/2010'

	/* Get the User Id to use for the process and attempt result (currently NHolt) */
	SELECT @UserID = LookupString FROM ValidLookup WHERE LookupCode = 30010
	
	/* Select Folders to copy to new quarter: All VB folders from previous quarter that aren't Closed */
	DECLARE curOld CURSOR FOR
		SELECT F.FolderRSN --, AB.BillNumber, AB.PaidInFullFlag, BillAmount, TotalPaid
		FROM Folder F
		JOIN AccountBill AB ON F.FolderRSN = AB.FolderRSN
		WHERE FolderType = 'BP' 
		AND WorkCode IN (30007, 30017, 30019)
		AND StatusCode = 30002
		AND IssueDate <= @CutOffDate
		AND PaidInFullFlag <> 'N'

	/* Open the cursor to process selected folders */
	OPEN curOld
	FETCH NEXT FROM curOld INTO @FolderRSN
	WHILE @@FETCH_STATUS = 0
		BEGIN

		IF NOT EXISTS (SELECT ProcessRSN FROM FolderProcess WHERE FolderRSN = @FolderRSN AND ProcessCode = 30003)
		BEGIN
			EXEC TK_PROCESS_INSERT @FolderRSN, 30510, @UserID, 40, NULL, NULL, NULL, NULL
		END

		SELECT @ProcessRSN = ProcessRSN FROM FolderProcess WHERE FolderRSN = @FolderRSN  AND ProcessCode = 30003
		SELECT @NextAttemptRSN = ISNULL(MAX(AttemptRSN),0)+1 FROM FolderProcessAttempt WHERE ProcessRSN = @ProcessRSN

		INSERT INTO FolderProcessAttempt (ProcessRSN, FolderRSN, AttemptRSN, AttemptDate, AttemptBy, AttemptComment, 
			StampDate, StampUser, ResultCode)
		VALUES (@ProcessRSN, @FolderRSN, @NextAttemptRSN, getdate(), @UserID, 'Closing old issued folders',
			getdate(), @UserID, 30150)

	    UPDATE Folder
		SET Folder.StatusCode = 2, FinalDate = GetDate()
	    WHERE Folder.FolderRSN = @FolderRSN

		SELECT @ValidClause = ValidClause.ClauseText
		FROM ValidClause
		WHERE ClauseRSN = 439

	    UPDATE FolderProcess /*add a comment*/
		SET Enddate=getdate(), StatusCode = 2, ProcessComment = @ValidClause
		    WHERE FolderProcess.ProcessRSN = @ProcessRSN

		FETCH NEXT FROM curOld INTO @FolderRSN
	END

	CLOSE curOld
	DEALLOCATE curOld

END


GO
