USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_DF_00000777]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_DF_00000777]
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
DECLARE @ResultCode INT
DECLARE @PropertyRSN INT
DECLARE @ExportFormat INT
DECLARE @intCOMReturnValue INT
DECLARE @intAddlTime INT
DECLARE @FeeAmount float 
DECLARE @FeeComment VARCHAR(100)
DECLARE @FeeRate Float

SELECT TOP 1 @ResultCode = FolderProcessAttempt.ResultCode,
@PropertyRSN = Folder.PropertyRSN
FROM Folder
INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN =  FolderProcessAttempt.ProcessRSN
WHERE FolderProcess.ProcessRSN = @ProcessRSN
ORDER BY AttemptRSN DESC


IF @ResultCode = 777 /*PDF*/
    BEGIN
        SET @ExportFormat = 40
    END
IF @ResultCode = 778 /*DOC*/
    BEGIN
        SET @ExportFormat = 10
    END
IF @ResultCode = 779
    BEGIN
        SET @ExportFormat = 0
    END

IF @ExportFormat > 0 /* Bianchi Form and Fees */
BEGIN
    SELECT @FeeAmount = ValidLookup.LookupFee 
      FROM ValidLookup 
     WHERE ( ValidLookup.LookupCode = 30030 ) 
       AND ( ValidLookup.Lookup1 = 1)

    SET @FeeComment = 'Bianchi Initial Research Fees'

    /* Bianchi Initial Research Fees */
    EXEC TK_FEE_INSERT @FolderRSN, 1000, @FeeAmount, @UserID, @FeeComment, 1, 0

    COMMIT TRANSACTION
    BEGIN TRANSACTION
    EXEC @intCOMReturnValue = xspGenerateBianchi @FolderRSN, @PropertyRSN, @UserId, 20, @ExportFormat
END
ELSE /* Result Code = 779 - Additional Fees */
BEGIN
    IF NOT EXISTS(SELECT InfoValue FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30020)
    BEGIN
        RAISERROR('Additional research time (in minutes) must be entered', 16, -1)
        RETURN
    END
    ELSE
    BEGIN
        SELECT @intAddlTime = InfoValue FROM FolderProcessInfo WHERE ProcessRSN = @ProcessRSN AND InfoCode = 30020
    END

    SELECT @FeeRate = ValidLookup.LookupFee 
      FROM ValidLookup 
     WHERE ( ValidLookup.LookupCode = 30030 ) 
       AND ( ValidLookup.Lookup1 = 2)

    SET @FeeAmount = @FeeRate * @intAddlTime
    SET @FeeComment = 'Bianchi Additional Research Fees'

    /* Bianchi Additional Research Fees */
    EXEC TK_FEE_INSERT @FolderRSN, 1005, @FeeAmount, @UserID, @FeeComment, 1, 0

END
/* Reopen process */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, 
       FolderProcess.AssignedUser = Null, 
       FolderProcess.SignOffUser = Null, 
       FolderProcess.EndDate = Null
 WHERE FolderProcess.ProcessRSN = @ProcessRSN

GO
