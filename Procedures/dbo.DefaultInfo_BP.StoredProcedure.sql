USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_BP]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_BP]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
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

DECLARE @RPF VARCHAR(3)
SELECT @RPF = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN=@FolderRSN
AND FolderInfo.InfoCode=31060

IF @ATFO = 'Yes' AND @ATFC = 'Yes'
BEGIN
    ROLLBACK TRANSACTION
    SET @ErrorMsg = 'Sorry. Both ATFO and ATFC are set to Yes. You will have to choose one or the other.'
    RAISERROR (@ErrorMsg, 16, -1)
    RETURN
END

DECLARE @NextFolderRSN INT
DECLARE @strCurrentYear CHAR(4)

SELECT @strCurrentYear = SUBSTRING(CONVERT(CHAR(4), DATEPART(YEAR, GetDate())), 3, 2)

IF NOT EXISTS(SELECT FolderRSN FROM Folder WHERE FolderType='RPF' AND ParentRSN=@FolderRSN)
BEGIN
IF @RPF='Yes'
BEGIN
	
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder

	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		WorkCode, FolderType, StatusCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear,  dbo.udf_GetNextFolderSeq(), '000', '00',
		30160, 'RPF', 30021, PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
/*
                INSERT INTO FolderPeople (FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampDate, StampUser)
                SELECT @NextFolderRSN, PeopleCode, PeopleRSN, PrintFlag, GetDate(), User
                FROM FolderPeople 
                WHERE FolderRSN=@FolderRSN
                AND PeopleCode=2
*/



	COMMIT TRAN

	BEGIN TRAN

                DECLARE @ECC FLOAT

                SELECT @ECC=InfoValue
                FROM FolderInfo
                WHERE FolderRSN=@FolderRSN
                AND InfoCode=30006

                UPDATE FolderInfo 
                SET InfoValue=@ECC, InfoValueNumeric=@ECC
                WHERE FolderRSN=@NextFolderRSN
                AND InfoCode=31065

	COMMIT TRAN

END
END

GO
