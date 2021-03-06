USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_ATTEMPTDETAILS_SELECT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[TK_ATTEMPTDETAILS_SELECT]
@argProcessRSN INT, 
@argAttemptRSN INT, 
@argResultCode INT OUTPUT,
@argAttemptComment varchar(4000) OUTPUT,
@argProcessComment varchar(4000) OUTPUT,
@argHourSpent float OUTPUT, 
@argOverTime float OUTPUT,
@argTimeUnit varchar(10) OUTPUT, 
@argMileageAmount float OUTPUT,
@argExpenseAmount float OUTPUT
/******************************************************************************
NAME: ATTEMPTDETAILS_SELECT
PURPOSE: Retrieve all user columns from an attempt result, returned in output parameters, this is meant to be used in Attempt Procedures
REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0        09/01/2008  Kevin Westoby    Created procedure

NOTES:

******************************************************************************/
AS

DECLARE @v_errMsg varchar(1000)

BEGIN

	SELECT @argResultCode = resultCode, 
	@argAttemptComment = attemptComment, 
	@argProcessComment = processComment, 
	@argHourSpent = hourSpent, 
	@argOverTime = overTime, 
	@argTimeUnit = timeUnit, 
	@argMileageAmount = mileageAmount, 
	@argExpenseAmount = expenseAmount
	FROM folderProcess fp, folderProcessAttempt fpa
	WHERE fp.processRSN = @argProcessRSN
	AND fp.processRSN = fpa.processRSN
	AND attemptRSN = @argAttemptRSN
END








GO
