USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_CBC_00040001]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_CBC_00040001]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 

/* Commissions,Boards, and Committees - Other Member Contacts (40001) */

DECLARE @intAttemptResult int
DECLARE @intLastDefaultDisplayOrder int
DECLARE @varProcessComment varchar(100)
DECLARE @intInfo40007Count int		/* Intern Name */
DECLARE @intInfo40008Count int		/* Intern Phone */
DECLARE @intInfo40009Count int		/* Intern Email */
DECLARE @intInfo40014Count int		/* Ex-Officio Name */
DECLARE @intInfo40015Count int		/* Ex-Officio Phone */
DECLARE @intInfo40016Count int		/* Ex-Officio Email */
DECLARE @intInfo40017Count int		/* Ex-Officio Designate Name */
DECLARE @intInfo40018Count int		/* Ex-Officio Designate Phone */
DECLARE @intInfo40019Count int		/* Ex-Officio Designate Email */

/* Get Attempt Result */

SELECT @intAttemptResult = FolderProcessAttempt.ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
	( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
	  FROM FolderProcessAttempt 
	  WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @intLastDefaultDisplayOrder = ISNULL(FolderInfo.DisplayOrder, 90) 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 40006			/* Lead Staff Email */ 

IF @intAttemptResult = 40001		/* Add Intern Info Fields */
BEGIN
	SELECT @varProcessComment = 'Intern Info fields already present'

	SELECT @intInfo40007Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40007) 
	SELECT @intInfo40008Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40008) 
	SELECT @intInfo40009Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40009) 

	IF @intInfo40007Count = 0
	BEGIN
		SELECT @varProcessComment = 'Intern Info fields added'

		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40007, ( @intLastDefaultDisplayOrder + 10 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END

	IF @intInfo40008Count = 0
	BEGIN
		SELECT @varProcessComment = 'Intern Info fields added'
	
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40008, ( @intLastDefaultDisplayOrder + 20 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END

	IF @intInfo40009Count = 0
	BEGIN
		SELECT @varProcessComment = 'Intern Info fields added'
		
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40009, ( @intLastDefaultDisplayOrder + 30 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END
END

IF @intAttemptResult = 40002		/* Add Ex-Officio Member Info Fields */
BEGIN
	SELECT @varProcessComment = 'Ex-Officio Member Info fields already present'

	SELECT @intInfo40014Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40014) 
	SELECT @intInfo40015Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40015) 
	SELECT @intInfo40016Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40016) 

	IF @intInfo40014Count = 0
	BEGIN
		SELECT @varProcessComment = 'Ex-Officio Member Info fields added'
	
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40014, ( @intLastDefaultDisplayOrder + 40 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END

	IF @intInfo40015Count = 0
	BEGIN
		SELECT @varProcessComment = 'Ex-Officio Member Info fields added'
		
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40015, ( @intLastDefaultDisplayOrder + 50 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END

	IF @intInfo40016Count = 0
	BEGIN
		SELECT @varProcessComment = 'Ex-Officio Member Info fields added'
	
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40016, ( @intLastDefaultDisplayOrder + 60 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END
END

IF @intAttemptResult = 40003		/* Add Ex-Officio Designate Info Fields */
BEGIN
	SELECT @varProcessComment = 'Ex-Officio Designate Info fields already present'

	SELECT @intInfo40017Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40017) 
	SELECT @intInfo40018Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40018) 
	SELECT @intInfo40019Count = dbo.udf_FolderInfoFieldExists(@FolderRSN, 40019) 

	IF @intInfo40017Count = 0
	BEGIN
		SELECT @varProcessComment = 'Ex-Officio Designate Info fields added'
	
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40017, ( @intLastDefaultDisplayOrder + 70 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END

	IF @intInfo40018Count = 0
	BEGIN
		SELECT @varProcessComment = 'Ex-Officio Designate Info fields added'
		
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40018, ( @intLastDefaultDisplayOrder + 80 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END

	IF @intInfo40019Count = 0
	BEGIN
		SELECT @varProcessComment = 'Ex-Officio Designate Info fields added'
		
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, Mandatory, ValueRequired, StampDate, StampUser ) 
		VALUES 
			( @FolderRSN, 40019, ( @intLastDefaultDisplayOrder + 90 ), 'Y', 'N', 'N', GETDATE(), @UserId ) 
	END
END

/* Reopen Process */

UPDATE FolderProcess 
SET FolderProcess.StatusCode = 1, FolderProcess.ProcessComment = @varProcessComment, 
	FolderProcess.EndDate = NULL, FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL
WHERE FolderProcess.ProcessRSN = @ProcessRSN 
AND FolderProcess.FolderRSN = @FolderRSN 

GO
