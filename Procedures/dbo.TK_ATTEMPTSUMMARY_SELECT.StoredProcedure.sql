USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_ATTEMPTSUMMARY_SELECT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TK_ATTEMPTSUMMARY_SELECT]
@argProcessRSN INT, 
@argAttemptRSN INT, 
@argResultCode INT OUTPUT,
@argAttemptComment varchar(4000) OUTPUT,
@argProcessComment varchar(4000) OUTPUT
/******************************************************************************
NAME: ATTEMPTSUMMARY_SELECT
PURPOSE: Retrieves result code and comments from an attempt result returned in output parameters
REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0        09/01/2008  Kevin Westoby    1. Created procedure

NOTES:

******************************************************************************/
AS

BEGIN

	SELECT @argResultCode = resultCode, 
	@argAttemptComment = attemptComment, 
	@argProcessComment = processComment
	FROM folderProcess fp, folderProcessAttempt fpa
	WHERE fp.processRSN = @argProcessRSN
	AND fp.processRSN = fpa.processRSN
	AND attemptRSN = @argAttemptRSN

END





GO
