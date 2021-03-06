USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_RB_00020027]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_RB_00020027]
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
DECLARE @AttemptResult  Int
DECLARE @AttemptDate    DateTime
DECLARE @PropertyID     Int
DECLARE @BalanceDue     Money
DECLARE @intCOMReturnValue INT
DECLARE @FeeAmount float 
DECLARE @FeeComment VARCHAR(100)

SELECT @BalanceDue = SUM(AccountBill.BillAmount) - SUM(ISNULL(AccountPaymentDetail.PaymentAmount, 0))
FROM AccountBill
LEFT OUTER JOIN AccountPaymentDetail ON AccountBill.BillNumber = AccountPaymentDetail.BillNumber
WHERE AccountBill.PaidInFullFlag <> 'C'
AND AccountBill.FolderRSN = @FolderRSN

SET @BalanceDue = ISNULL(@BalanceDue, 0)

SELECT @AttemptResult = ResultCode, @AttemptDate = AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


UPDATE FolderProcessAttempt
SET AttemptComment = 'Owner Code ' + Folder.ReferenceFile
FROM FolderProcessAttempt
INNER JOIN Folder ON FolderProcessAttempt.FolderRSN = Folder.FolderRSN
WHERE Folder.FolderRSN = @FolderRSN
AND FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)



IF @AttemptResult = 20063          /*Transfer of Ownership*/
BEGIN

     UPDATE Folder
     --SET Folder.StatusCode = 2,
     SET Folder.FolderDescription = CAST(Folder.FolderDescription AS VARCHAR(4000)) + ' Property Sold and Transferred - ' + Convert(Char(11), @AttemptDate)
     WHERE Folder.FolderRSN = @FolderRSN

     EXEC usp_UpdateFolderCondition @FolderRSN, 'Property Transferred'

     /* Apply Transfer of Ownership Fee (203) */
     SELECT @FeeAmount = ValidLookup.LookupFee 
       FROM ValidLookup 
   WHERE ( ValidLookup.LookupCode = 16 ) 
        AND (  ValidLookup.Lookup1 =5)

     SET @FeeComment = 'Transfer Fees'
     EXEC TK_FEE_INSERT @FolderRSN, 203, @FeeAmount, @UserID, @FeeComment, 1, 1

     /* Re-open process */
     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN
END

IF @AttemptResult = 20052          /*No Longer Rental*/
     BEGIN

     UPDATE Folder
     SET Folder.StatusCode = 2,
     Folder.FolderDescription = CAST(Folder.FolderDescription AS VARCHAR(4000)) + ' Property No Longer Rental - ' + Convert(Char(11), @AttemptDate)
     WHERE Folder.FolderRSN = @FolderRSN

     EXEC usp_UpdateFolderCondition @FolderRSN, 'Property No Longer Rental'
END

IF @AttemptResult = 20100               /*Rental Registration Fees Applied*/
     BEGIN

     EXEC usp_UpdateFolderCondition @FolderRSN, 'Applied Rental Registration Fee'

     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN

     EXECUTE DefaultFee_RB_10  @FolderRSN, @UserID

     /* Re-open process */
     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN

END

IF @AttemptResult = 20123               /*Late Fees Applied*/
     BEGIN

     EXEC usp_UpdateFolderCondition @FolderRSN, 'Applied Late Fee'

     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN

     /* Insert Late Fee */
     SELECT @FeeAmount = ValidLookup.LookupFee 
       FROM ValidLookup 
      WHERE ( ValidLookup.LookupCode = 16 ) 
        AND ValidLookup.Lookup1 =7

     SET @FeeComment = 'Rental Late Charges'
     EXEC TK_FEE_INSERT @FolderRSN, 209, @FeeAmount, @UserID, @FeeComment, 1, 1

     /* Re-open process */
     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN

END

IF @AttemptResult = 20068                /*Lien Attached*/
     BEGIN
     
     EXEC usp_UpdateFolderCondition @FolderRSN, 'Lien Attached'

	/* Create the Fee and Bill from lookup and insert to folder */
	SELECT @FeeAmount = LookupFee FROM ValidLookup 
	  WHERE LookupCode = 16 AND Lookup1 = 2 AND Lookup2 = 2
	EXEC TK_FEE_INSERT @FolderRSN, 204, @FeeAmount, @UserID, 'Lien Fee', 1, 1

     /* Re-open process */
     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN
END

IF @AttemptResult = 20069                /*Lien Released*/
     BEGIN
     
     EXEC usp_UpdateFolderCondition @FolderRSN, 'Lien Released'

     /* Re-open process */
     UPDATE FolderProcess
     SET StatusCode = 1, EndDate = NULL, BaseLineEndDate = NULL
     WHERE FolderRSN = @FolderRSN
END


GO
