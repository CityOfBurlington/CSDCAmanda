USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_MP]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_MP]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ElecControlReq   char(3)

DECLARE @ErrorMsg VARCHAR(100)
DECLARE @ATFO VARCHAR(3)
DECLARE @ATFC VARCHAR(3)

SELECT @ATFO = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30078

SELECT @ATFC = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30095

IF @ATFO = 'Yes' AND @ATFC = 'Yes'
BEGIN
    ROLLBACK TRANSACTION
    SET @ErrorMsg = 'Sorry. Both ATFO and ATFC are set to Yes. You will have to choose one or the other.'
    RAISERROR (@ErrorMsg, 16, -1)
    RETURN
END

SELECT @ElecControlReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30127

DECLARE @NextFolderRSN INT

SELECT @NextFolderRSN = MAX(FolderRSN) + 1
FROM Folder

DECLARE @ChildRSN INT

SELECT @ChildRSN = FolderRSN 
FROM Folder
WHERE FolderType = 'EC'
AND ParentRSN = @FolderRSN

IF @ElecControlReq ='Yes' AND @ChildRSN IS NULL
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT TOP 1 @NextFolderRSN, 20, FolderYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		'EC', '30000', SubCode, 30023, PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
	COMMIT TRAN
END
GO
