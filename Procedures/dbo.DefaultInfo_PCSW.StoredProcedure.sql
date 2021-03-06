USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_PCSW]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_PCSW]
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

/* Minor Project SWM Plan required? (35350)    */
/* Insert Info Fields 35380-35400              */
IF @InfoCode = 35350 AND @InfoValue = 'Yes'
BEGIN
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35380)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35380)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35390)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35390)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35400)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35400)
    END
END

/* Major Project SWM Plan required? (35360)    */
/* Insert Info Fields 35450-35560              */
IF @InfoCode = 35360 AND @InfoValue = 'Yes'
BEGIN
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35450)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35450)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35460)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35460)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35470)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35470)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35480)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35480)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35490)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35490)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35500)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35500)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35510)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35510)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35520)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35520)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35530)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35530)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35540)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35540)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35550)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35550)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35560)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35560)
    END
END

/* Other Reason for SWM Review? (35370)    */
/* Insert Info Fields 35400 and 35440      */
IF @InfoCode = 35370 AND @InfoValue = 'Yes'
BEGIN
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35400)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35400)
    END
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35440)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35440)
    END
END

/* Access Agreement Required? (35410)           */
/* Insert Easement Filed (35140) process        */
/* and Easement Filed Date (35590) info field   */ 
IF @InfoCode = 35410 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35140, @UserID, 60, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35590)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35590)
    END
END

/* Initial Compliance Designers Certification Required? (35570) */
/* Insert Initial Compliance Cert (35150) process               */
/* and Initial Compliance Certificate Date (35600) info field   */ 
IF @InfoCode = 35570 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35150, @UserID, 70, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35600)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35600)
    END
END

/* Initial Compliance Inspection Required? (35420) */
/* Insert Initial Compliance Inspection (35160) process         */
/* and Initial Compliance Certificate Date (35660) info field   */ 
IF @InfoCode = 35420 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35160, @UserID, 80, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35660)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35660)
    END
END

/* As-Built/GIS submittal Required? (35580) */
/* Insert As-Built Plans (35170) process         */
/* and As-Built Plans Received Date (35610) info field   */ 
IF @InfoCode = 35580 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35170, @UserID, 90, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35610)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35610)
    END
END

/* Annual Inspection Required? (35430) */
/* Insert Annual Inspections (35190) process             */
/* and Most Recent Inspection Date (35630) info field    */ 
IF @InfoCode = 35430 AND @InfoValue = 'Yes'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35190, @UserID, 100, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35630)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35630)
    END
END

/* Annual Inspection Required? (35430) */
/* Insert Other Inspections (35200) process             */
/* and Most Recent Inspection Date (35630) info field    */ 
IF @InfoCode = 35430 AND @InfoValue = 'No'
BEGIN
    EXEC TK_PROCESS_INSERT @FolderRSN, 35200, @UserID, 100, NULL, NULL, NULL, NULL
    IF NOT EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 35630)
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode)
        VALUES(@FolderRSN, 35630)
    END
END

GO
