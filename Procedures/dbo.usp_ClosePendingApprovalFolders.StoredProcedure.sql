USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ClosePendingApprovalFolders]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_ClosePendingApprovalFolders] AS
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================
-- Author:		Dana Baron
-- Create date: 30-August-2012
-- Description:	This stored procedure runs as an automatic job from //intranet.
--				It finds all BP folders in Pending Approval status and creates
--				a new ProcessAttempt with a Result Code = 30155
--10-Dec-12
-- Scott Duck
-- Added FinalDate=GetDate() to Update Folder Statement
-- ===============================================================================

BEGIN

	DECLARE @ParentRSN int
	DECLARE @CCounter int
	DECLARE @EPCount int
	DECLARE @AttemptRSN int
	DECLARE @ProcessRSN int
	DECLARE @Statement VarChar(2000)

	DECLARE ParentFolders_CUR CURSOR FOR
	SELECT Folder.FolderRSN FROM Folder
	WHERE StatusCode = 30019 /* Pending Approval */
	AND FolderType = 'BP'
	AND (SELECT count(*) FROM Folder F1 WHERE ParentRSN = Folder.FolderRSN AND StatusCode <> 2 AND Folder.StatusCode NOT IN (2, 30005)) = 0
	ORDER BY FolderRSN
	
	SELECT @CCounter = 0

	OPEN ParentFolders_CUR
	FETCH NEXT FROM ParentFolders_CUR INTO @ParentRSN

	WHILE @@Fetch_Status = 0
	BEGIN

		/* Find process 30003 (Final Building) */
		SELECT @ProcessRSN = ProcessRSN FROM FolderProcess WHERE FolderRSN = @ParentRSN and ProcessCode = 30003

		SELECT @AttemptRSN = ISNULL(MAX(AttemptRSN), 0) FROM FolderProcessAttempt
		WHERE folderProcessAttempt.FolderRSN = @ParentRSN
		AND FolderProcessAttempt.ProcessRSN = @ProcessRSN

		INSERT INTO	FolderProcessAttempt
		(ProcessRSN, FolderRSN, AttemptRSN, AttemptDate,AttemptBy, StampDate, ResultCode)
		VALUES (@ProcessRSN, @ParentRSN, @AttemptRSN + 1, GETDATE(),'sa', GETDATE(), 30155)

		SELECT @Statement = ClauseText FROM ValidClause	WHERE ClauseRSN = 466

		UPDATE FolderProcess
		SET FolderProcess.ProcessComment=@Statement, EndDate=GETDATE(), StatusCode=2
		WHERE FolderProcess.FolderRSN=@ParentRSN
		AND FolderProcess.ProcessRSN=@ProcessRSN
		
		UPDATE Folder
		SET StatusCode=2, FinalDate=GETDATE()
		WHERE FolderRSN=@ParentRSN

		FETCH NEXT FROM ParentFolders_CUR INTO @ParentRSN

	END

	CLOSE ParentFolders_CUR
	DEALLOCATE ParentFolders_CUR
END



GO
