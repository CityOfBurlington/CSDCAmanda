USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_RV_00020026]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_RV_00020026]
@ProcessRSN int, @FolderRSN int, @UserId char(8)
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
DECLARE @AttemptResult int
DECLARE @AttemptDate datetime


/* Get Attempt Result */

SELECT @AttemptResult = ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

IF @AttemptResult = 20050 /*Fee Waived*/

BEGIN
  UPDATE FolderInfo
  SET FolderInfo.InfoValue = 'Yes', FolderInfo.InfoValueUpper = 'YES'
  WHERE FolderInfo.FolderRSN =@FolderRSN
  AND FolderInfo.InfoCode = 20041
END

IF @AttemptResult = 20051 /*Fee Reinstated*/

BEGIN
  UPDATE FolderInfo
  SET FolderInfo.InfoValue = 'No', FolderInfo.InfoValueUpper = 'NO'
  WHERE FolderInfo.FolderRSN = @FolderRSN
  AND FolderInfo.InfoCode = 20041
END



GO
