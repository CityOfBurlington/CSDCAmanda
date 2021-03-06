USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_BP_00030130]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_BP_00030130]
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
/* This Process will cancel a permit/application as follows: */
/* If the folder is in Application status AND no there are no fees, */
/*    set the folder status to "Ready to Delete" (30100)             */
/* If the folder is not in Application status OR there are fees,    */
/*    set the folder status to Canceled (30005)                     */

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

IF @AttemptResult = 120 /* Cancel Permit */
BEGIN

     SELECT @FolderStatus = Folder.StatusCode FROM Folder 
     WHERE Folder.FolderRSN = @FolderRSN

     SELECT @FeeCk = Count(*)
     FROM AccountBillFee
     WHERE AccountBillFee.FolderRSN = @FolderRSN
 
     IF @FolderStatus = 30000 AND @FeeCk < 1 /* Application Status AND No fees */
     BEGIN
          UPDATE Folder
          SET Folder.StatusCode = 30100 /* Read to Delete */
          WHERE Folder.FolderRSN = @FolderRSN

     END
     ELSE
     BEGIN

          UPDATE Folder /*change folder status to canceled */
          SET Folder.StatusCode = 30005, Folder.Finaldate = getdate(), 
          Folder.FolderDescription = 'PERMIT CANCELED'
          WHERE Folder.FolderRSN = @FolderRSN

          UPDATE FolderProcess /*close any open processes*/
          SET StatusCode = 2, EndDate = getdate(), ProcessComment = 'Permit Cancelled'
          WHERE FolderProcess.FolderRSN = @FolderRSN
          AND FolderProcess.ProcessRSN <> @ProcessRSN
          AND FolderProcess.EndDate IS NULL

          /* Set this Process Status to Application/Permit Canceled */
          UPDATE FolderProcess 
          SET FolderProcess.StatusCode = 30130
          WHERE FolderProcess.processRSN = @processRSN
     
     END
END

GO
