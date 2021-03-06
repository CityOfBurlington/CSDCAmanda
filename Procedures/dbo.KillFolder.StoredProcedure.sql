USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[KillFolder]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[KillFolder](@intFolderRSN INT)
AS
BEGIN

	ALTER Table FolderProcess DISABLE Trigger FolderProcess_Del

	--DROP TRIGGER FolderProcess_Del 

	DELETE FROM Attachment WHERE TableRSN = @intFolderRSN AND TableName = 'Folder'

	DELETE FROM AccountGL WHERE FolderRSN = @intFolderRSN

	DELETE FROM AccountPaymentDetail WHERE FolderRSN = @intFolderRSN

	DELETE FROM AccountPayment WHERE FolderRSN = @intFolderRSN

	DELETE FROM AccountBill WHERE FolderRSN = @intFolderRSN

	DELETE FROM AccountBillFee WHERE FolderRSN = @intFolderRSN
	
	DELETE FROM FolderInfo WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderProcessChecklist WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderProcessInfo WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderProcessDeficiency WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderProcessAttempt WHERE FolderRSN = @intFolderRSN
	
	DELETE FROM FolderProcess WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderInspectionRequest WHERE FolderRSN = @intFolderRSN

	DELETE FROM AccountBillFee WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderPeople WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderProperty WHERE FolderRSN = @intFolderRSN

	DELETE FROM FolderComment WHERE FolderRSN = @intFolderRSN

	DELETE FROM Folder WHERE FolderRSN = @intFolderRSN

	ALTER Table FolderProcess ENABLE Trigger FolderProcess_Del

/* Attempting to disable/enable trigger rather than deleting and re-creating 
	D Baron - 30-November-2011
	
	/*Trigger cleans up folder*/
	DECLARE @SQL nvarchar(4000)

	SET @SQL = '
	CREATE TRIGGER FolderProcess_Del ON FolderProcess FOR DELETE
	AS
	BEGIN

	/* version 4.3.9 V2 - Reordered and added other applicable tables.*/

	/****** Object:  Trigger dbo.FolderProcess_Del    Script Date: 11/10/00 10:24:58 AM ******/
	/* Table    : FolderProcess (Sybase)
	 * Trigger  : delete
	 * Comments : with security check
	 * Date     : Nov. 8, 1996
	 */

		DECLARE @ArgUser Char(128)

	SELECT @ArgUser=user
	IF @ArgUser = ''dbo''
		SELECT @ArgUser=''sa''

	/* check IF security features need to be implemented */

	IF exists (SELECT * FROM ValidSite WHERE EnhancedSecurity = ''Y'' and SystemId = ''IBCS'' 
	and @@NESTLEVEL = 1 )
	BEGIN
		SELECT	ProcessRSN INTO #RSN_LIST	FROM	deleted	
		WHERE
			(
			AssignedUser <>  @ArgUser
			AND
			rtrim(AssignedUser) IS NOT NULL
			AND
			AssignedUser NOT IN
				(
				SELECT UserId
				FROM ValidUserTrusted
				WHERE TrustedUserId = @ArgUser
				)
			)
		IF exists ( SELECT * FROM #RSN_LIST )
		BEGIN
			ROLLBACK TRAN
			RAISERROR(''You are not in the Trusted Users List of the process(es) assigned user.'', 16, -1)
			RETURN
		END
	END


	DELETE FolderProcessAttempt
	WHERE  FolderProcessAttempt.ProcessRSN IN (SELECT ProcessRSN FROM DELETED)

	DELETE FolderProcessChecklist
	WHERE  FolderProcessChecklist.ProcessRSN IN(SELECT ProcessRSN FROM DELETED)

	/* On Delete Parent, Delete FolderProcessDeficiency -New to 4.0 */
	DELETE FolderProcessDeficiency
	WHERE (FolderProcessDeficiency.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 

	/* On Delete Parent, Delete FIFO_RemoteInspector -New to 4.0 */
	DELETE FIFO_RemoteInspector
	WHERE (FIFO_RemoteInspector.ProcessRSN IN (SELECT ProcessRSN FROM DELETED))

	/* 4.3.9 V2 - Subhash July 29, 2004: Following tables added in delete list*/
	DELETE FIFO_AUTO_WEB
	WHERE (FIFO_AUTO_WEB.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 

	DELETE FolderProcessClock
	WHERE (FolderProcessClock.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 

	DELETE FolderProcessClockAudit
	WHERE (FolderProcessClockAudit.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 

	DELETE FolderProcessInfo
	WHERE (FolderProcessInfo.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 

	DELETE FolderProcessInspDetail
	WHERE (FolderProcessInspDetail.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 

	DELETE FolderProcessPeople
	WHERE (FolderProcessPeople.ProcessRSN IN (SELECT ProcessRSN FROM DELETED) ) 
	/* End Subhash July 29, 2004 */



	DECLARE
	 @n_count   NUMERIC(10),
	 @v_OldEmail VARCHAR(60),
	 @c_OldEmailToDo char(1),
	 @c_OldInspectorFlag char(1),
	 @c_oldInspectorDevice VARCHAR(12),
	 @D_n_Processrsn INT,
	 @D_d_schduledate datetime,
	 @D_c_AssignFlag char(1),
	 @D_d_enddate datetime

	SELECT  @D_n_Processrsn = ProcessRSN,
		@D_d_schduledate = ScheduleDate,
		@D_c_AssignFlag = Assignflag,
		@D_d_enddate = EndDate
	FROM 	deleted
	WHERE 	EndDate is null
	and 	AssignedUser is not null 

	 SELECT	@v_OldEmail=ISNULL(EmailAddress, '' ''), @c_OldEmailToDo = ISNULL(EmailToDo, ''N''), @c_OldInspectorFlag = ISNULL(InspectorFlag, ''N''), @c_oldInspectorDevice = ISNULL(InspectorDevice, '''')
	 FROM	ValidUser
	 WHERE	UserId = (SELECT AssignedUser FROM DELETED)
	IF @c_oldInspectorDevice = ''Computer'' or @c_oldInspectorDevice = ''Handheld'' 
	 BEGIN
		 if (@D_d_enddate is null)  and @v_OldEmail >'' '' 
			and @c_OldEmailToDo=''Y'' and @c_OldInspectorFlag=''Y'' and  (@D_d_schduledate<= ( getdate() + 1) or
			@d_c_AssignFlag = ''*'') 
			INSERT INTO FIFO_RemoteInspector
				(EmailAddress, ProcessRSN,
				OldEmailAddress, ScheduleDate,
				AssignFlag, OldScheduleDate, OldAssignFlag, InspectorDevice)
				VALUES ('' '', @D_n_Processrsn, @v_OldEmail,
				null, null,  @D_d_schduledate, @D_c_AssignFlag, @c_oldInspectorDevice)
		
	 END

	/*Jean end*/
	END'

	EXEC sp_executesql @SQL
*/

END







GO
