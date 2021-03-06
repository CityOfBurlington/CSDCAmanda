USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_Logon_Warning]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[p_Logon_Warning] @argUserId VARCHAR(128)
AS

BEGIN
	DECLARE @MaxRSN INT
	
	SELECT @MaxRSN = MAX(ProcessRSN) FROM FolderProcess
	SET @MaxRSN = ISNULL(@MaxRSN,0) + 1

	  INSERT INTO FolderProcess
        	  ( ProcessRSN,
	            FolderRSN,
        	    ProcessCode,
	            ScheduleDate,
        	    StartDate,
	            AssignedUser,
        	    AssignFlag,
	            StampDate,
        	    StampUser)
   VALUES ( @MaxRSN,
            0,
            0,
            GETDATE(),
            GETDATE(),
            @argUserId,
            '*',
            GETDATE(),
            USER)
END


GO
