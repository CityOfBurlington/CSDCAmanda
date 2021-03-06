USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_RR_00020022]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_RR_00020022]
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
DECLARE @PropertyRSN int
DECLARE @OtherRRFolderRSN int
DECLARE @AttemptDate datetime
DECLARE @RRProcessRSN int
DECLARE @ProcessAttemptRSN int
DECLARE @OwnerID varchar(20)

SELECT @AttemptResult = ResultCode, @AttemptDate = AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


IF @AttemptResult = 20053 /*Form Received*/

BEGIN

SELECT @ProcessAttemptRSN = Max(AttemptRSN)
FROM FolderProcessAttempt

SELECT @PropertyRSN = Folder.PropertyRSN
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

DECLARE @FolderAttemptResult int
SELECT @FolderAttemptResult = FolderProcessAttempt.AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

UPDATE Folder
  SET Folder.StatusCode = 20015 /*Registration Filed*/
  WHERE Folder.PropertyRSN = @PropertyRSN
  AND Folder.FolderType = 'RR'

DELETE FolderProcessAttempt
WHERE FolderProcessAttempt.FolderRSN = @FolderRSN
AND FolderProcessAttempt.AttemptRSN = @FolderAttemptResult


SELECT @ProcessAttemptRSN = Max(AttemptRSN)
FROM FolderProcessAttempt

SELECT @OwnerID = Folder.ReferenceFile
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

DECLARE RelatedRR_Cur CURSOR FOR


SELECT Folder.FolderRSN, FolderProcess.ProcessRSN
FROM Folder, FolderProcess
WHERE Folder.FolderType = 'RR'
AND Folder.PropertyRSN = @PropertyRSN
AND FolderProcess.ProcessCode = 20022
AND FolderProcess.FolderRSN = Folder.FolderRSN


OPEN RelatedRR_Cur 
FETCH RelatedRR_Cur INTO
@OtherRRFolderRSN, @RRProcessRSN

WHILE @@Fetch_Status = 0
BEGIN

SELECT @ProcessAttemptRSN = @ProcessAttemptRSN + 1

INSERT
FolderProcessAttempt
(AttemptRSN, AttemptDate, AttemptBy, ResultCode,StampDate,StampUser,
 AttemptComment,FolderRSN, ProcessRSN)

VALUES (@ProcessAttemptRSN, @AttemptDate, @UserID, 20053, getdate(),@UserID,
'OwnerCode ' + @OwnerID,@OtherRRFolderRSN,@RRProcessRSN)

UPDATE FolderProcess
SET FolderProcess.StatusCode = 1, enddate = Null
WHERE FolderProcess.FolderRSN = @OtherRRFolderRSN
AND FolderProcess.ProcessRSN = @RRProcessRSN


FETCH RelatedRR_Cur INTO
@OtherRRFolderRSN, @RRProcessRSN


END
CLOSE RelatedRR_Cur
DEALLOCATE RelatedRR_Cur

END


IF @AttemptResult = 20052 /*Mark Property Inactive*/

BEGIN
SELECT @PropertyRSN = Folder.PropertyRSN
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

UPDATE Folder
  SET Folder.StatusCode = 2 /*Closed*/, FinalDate = @AttemptDate,
 Folder.FolderDescription = 'Property No Longer Rental - ' + Convert(Char(11),@AttemptDate)
  WHERE Folder.PropertyRSN = @PropertyRSN
  AND Folder.FolderType = 'RR'

DELETE FolderProcessAttempt
WHERE FolderProcessAttempt.FolderRSN = @FolderRSN
AND FolderProcessAttempt.ResultCode = 20052


SELECT @ProcessAttemptRSN = Max(AttemptRSN)
FROM FolderProcessAttempt

DECLARE RelatedRR_Cur CURSOR FOR

SELECT Folder.FolderRSN, FolderProcess.ProcessRSN
FROM Folder, FolderProcess
WHERE Folder.FolderType = 'RR'
AND Folder.PropertyRSN = @PropertyRSN
AND FolderProcess.ProcessCode = 20022
AND FolderProcess.FolderRSN = Folder.FolderRSN


OPEN RelatedRR_Cur 
FETCH RelatedRR_Cur INTO
@OtherRRFolderRSN, @RRProcessRSN

WHILE @@Fetch_Status = 0
BEGIN

SELECT @ProcessAttemptRSN = @ProcessAttemptRSN + 1

INSERT
FolderProcessAttempt
(AttemptRSN, AttemptDate, AttemptBy, ResultCode,StampDate,StampUser,
 FolderRSN, ProcessRSN)

VALUES (@ProcessAttemptRSN, @AttemptDate, @UserID, 20052, getdate(),@UserID,
@OtherRRFolderRSN,@RRProcessRSN)

UPDATE FolderProcess
SET FolderProcess.StatusCode = 2, enddate = @AttemptDate
WHERE FolderProcess.FolderRSN = @OtherRRFolderRSN
AND FolderProcess.ProcessRSN = @RRProcessRSN


FETCH RelatedRR_Cur INTO
@OtherRRFolderRSN, @RRProcessRSN


END
CLOSE RelatedRR_Cur
DEALLOCATE RelatedRR_Cur

END


IF @AttemptResult = 20054 /*Mark Unit Inactive*/

BEGIN
UPDATE Folder
  SET Folder.StatusCode = 2 /*Closed*/, FinalDate = @AttemptDate, 
  Folder.FolderDescription = 'Unit No Longer Rental - ' + Convert(Char(11),@AttemptDate)
  WHERE Folder.FolderRSN = @FolderRSN

END


GO
