USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PC_PROCESS_UPDATE]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE    PROCEDURE [dbo].[PC_PROCESS_UPDATE]
@argProcessRSN INT, 
@argReopenFlag int,
@DUserID varchar(1000), 
@argStatusCode int = NULL,
@argAssignedUser varchar(1000) = 'None',
@argScheduleDate datetime = '01-JAN-00'

/******************************************************************************
NAME: PC_Process_Update
PURPOSE: Update process status, the argReopen flag indicates if process should be reopened or not.  Can optionally pass an assigneduser
		 or schedule date
REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0        09/01/2008  Kevin Westoby    1. Created procedure

NOTES:

******************************************************************************/

AS
BEGIN

	IF @argReopenFlag = 1--reopen the process
	BEGIN

		UPDATE folderProcess
		SET StatusCode = ISNULL(@argStatusCode,1), 
		signOffUser = NULL, 
		endDate = NULL,
		assignedUser = CASE WHEN @argAssignedUser = 'None' THEN assignedUser ELSE @argAssignedUser END,
		scheduleDate = CASE WHEN @argScheduleDate = '01-JAN-00' THEN scheduleDate ELSE @argScheduleDate END
		WHERE processRSN = @argProcessRSN
	END

	ELSE IF @argReopenFlag = 0 --close the process, we are going to set the assigned user to be the sign off user
	BEGIN
		UPDATE folderProcess
		SET StatusCode = ISNULL(@argStatusCode, statusCode), 
		signOffUser = @DUserID, 
		endDate = getDate(),
		assignedUser = @DUserID,
		scheduleDate = CASE WHEN @argScheduleDate = '01-JAN-00' THEN scheduleDate ELSE @argScheduleDate END
		WHERE processRSN = @argprocessRSN

	END

END








GO
