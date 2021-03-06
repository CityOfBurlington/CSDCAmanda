USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_RPF_00036000]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_RPF_00036000]
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
DECLARE @AttemptResult int
DECLARE @FolderStatus int
DECLARE @FeeCk int
DECLARE @ShortDateTime VARCHAR(50)

SELECT @ShortDateTime=dbo.FormatDateTime(GETDATE(), 'SHORTDATEANDTIME')

SELECT @AttemptResult = Resultcode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 10 /*Completed*/
BEGIN
   UPDATE Folder 
   SET StatusCode=2,
   FolderCondition=CAST(FolderCondition AS VARCHAR(4000)) + ' >> Process completed ' + @ShortDateTime
   WHERE FolderRSN=@FolderRSN
END

IF @AttemptResult = 5016
BEGIN
   UPDATE Folder
   SET StatusCode=55,
   FolderCondition=CAST(FolderCondition AS VARCHAR(4000)) + ' >> Process cancelled ' + @ShortDateTime
   WHERE FolderRSN=@FolderRSN
END
GO
