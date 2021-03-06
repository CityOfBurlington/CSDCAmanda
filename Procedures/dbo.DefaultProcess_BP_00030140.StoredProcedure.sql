USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_BP_00030140]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_BP_00030140]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/* This Process is used when it is determined that a permit is not required. */
/* The process does the following:                                           */
/*    - change the Work Proposed to "Not Required" (30110)                   */
/*    - change the folder status to Permit Not Required (30030)              */

DECLARE @AttemptResult int
DECLARE @FolderStatus int
DECLARE @FeeCk int

SELECT @AttemptResult = Resultcode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 30180 /* Permit Not Required */
BEGIN

     UPDATE Folder
     SET Folder.StatusCode = 30030, /* Permit Not Required */
         Folder.WorkCode = 30110    /* Not Required        */
     WHERE Folder.FolderRSN = @FolderRSN

          /* Set this Process Status to Application/Permit Canceled */
          --UPDATE FolderProcess 
          --SET FolderProcess.StatusCode = 30130
          --WHERE FolderProcess.processRSN = @processRSN
     
END

GO
