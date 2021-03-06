USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_EP]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_EP]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ElecControlReq   char(3)
DECLARE @EnergPermitReq   char(3)
DECLARE @ErrorMsg VARCHAR(100)
DECLARE @ATFO VARCHAR(3)
DECLARE @ATFC VARCHAR(3)

SELECT @ElecControlReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30127

SELECT @EnergPermitReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30077

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

IF @EnergPermitReq ='Yes'
BEGIN
    /* Insert BED Energize Number info field (allow for up to 10 numbers) */
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30220)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30220, 100)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30221)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30221, 101)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30222)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30222, 102)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30223)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30223, 103)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30224)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30224, 104)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30225)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30225, 105)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30226)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30226, 106)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30227)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30227, 107)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30228)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30228, 108)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 30229)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder)
	    VALUES(@FolderRSN, 30229, 109)
    END
END

GO
