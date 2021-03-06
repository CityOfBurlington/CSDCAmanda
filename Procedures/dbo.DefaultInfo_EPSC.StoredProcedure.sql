USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_EPSC]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_EPSC]
@FolderRSN numeric(10), @UserId char(128), @InfoCode int
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Info Validation will add processes and additional Info Fields based
   on responses to boolean info fields inserted at folder initialization */

DECLARE @InfoValue varchar(2000)
DECLARE @DateInfoValue DATETIME
DECLARE @NumInfoValue FLOAT
DECLARE @TotalImperv FLOAT
DECLARE @ExistImperv FLOAT
DECLARE @NetNewImperv FLOAT
DECLARE @PropertyRSN INT
DECLARE @strMessage VARCHAR(100)

SELECT @InfoValue = FolderInfo.InfoValue,
   @DateInfoValue = FolderInfo.InfoValueDateTime,
   @NumInfoValue = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = @InfoCode

/* Existing Impervious Surface(35010)       */
/* When this field is updated, re-calculate */
/* Net New Impervious Surface (35030)       */
If @InfoCode = 35010
BEGIN
	SELECT @TotalImperv=ISNULL(InfoValueNumeric,0) FROM FolderInfo WHERE FolderRSN = @FolderRSN and InfoCode = 35020
	SET @NetNewImperv = @TotalImperv - @NumInfoValue
	UPDATE FolderInfo SET InfoValue = @NetNewImperv, InfoValueNumeric = @NetNewImperv, StampDate = getdate(), StampUser = @UserID 
	   WHERE FolderRSN = @FolderRSN and InfoCode = 35030
END

/* Total Impervious Surface(35020)          */
/* When this field is updated, re-calculate */
/* Net New Impervious Surface (35030)       */
If @InfoCode = 35020
BEGIN
	SELECT @ExistImperv=ISNULL(InfoValueNumeric,0) FROM FolderInfo WHERE FolderRSN = @FolderRSN and InfoCode = 35010
	SET @NetNewImperv = @NumInfoValue - @ExistImperv
	UPDATE FolderInfo SET InfoValue = @NetNewImperv, InfoValueNumeric = @NetNewImperv, StampDate = getdate(), StampUser = @UserID 
	   WHERE FolderRSN = @FolderRSN and InfoCode = 35030
END

 
/* Additional Information Required? (35190)    */
/* Insert SW Additional Info (35010) process   */
/* and Addl Info Requested Date (35310) and    */
/* Addl Info Received Date (35320) info fields */
IF @InfoCode = 35190 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35010, @UserID, 10, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35310)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35310)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35320)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35320)
    END
END

/* Site Visit Required? (35200)           */
/* Insert SW Site Visit (35020) process   */
/* and Site Visit Date (35090) info field */ 
IF @InfoCode = 35200 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35020, @UserID, 20, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35090)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35090)
    END
END

/* Tech Assistance Meeting Required? (35210)   */
/* Insert SW Tech Meeting (35030) process      */
/* and SW Tech Meeting Date (35100) info field */ 
IF @InfoCode = 35210 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35030, @UserID, 30, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35100)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35100)
    END
END

/* Pre-construction Meeting Required? (35220)           */
/* Insert SW Pre-construction Meeting (35040) process   */
/* and Pre-construction Meeting Date (35110) info field */ 
IF @InfoCode = 35220 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35040, @UserID, 40, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35110)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35110)
    END
END

/* Installation Measures Required? (35230)           */
/* Insert SW Installation of measures (35070) process   */
/* and Required Measures (35150) info field */ 
IF @InfoCode = 35230 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35070, @UserID, 110, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35150)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35150)
    END
END

/* General Inspection Required? (35240)           */
/* Insert SW General Inspection (35080) process   */
/* and General Inspection Date (35140) info field */ 
IF @InfoCode = 35240 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35080, @UserID, 120, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35140)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35140)
    END
END

/* Winter Stabilization Inspection Required? (35250)           */
/* Insert SW Winter Stbl Inspection (35090) process            */
/* and Winter Stabilization Inspection Date (35160) info field */ 
IF @InfoCode = 35250 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35090, @UserID, 130, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35160)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35160)
    END
END

/* PCSW Required? (35260)           */
/* Insert new PCSW Folder           */
   IF @InfoCode = 35260 AND @InfoValue = 'Yes'
   BEGIN

       SELECT @PropertyRSN = PropertyRSN FROM Folder WHERE FolderRSN = @FolderRSN
       --EXEC usp_CreatePCSWFolder @PropertyRSN, @FolderRSN
 
   END


GO
