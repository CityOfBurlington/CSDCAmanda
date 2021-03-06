USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFolderPeople_LL]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFolderPeople_LL]
@FolderRSN int, @UserId char(10), @PeopleRSN int, @PeopleCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
IF @PeopleCode = 700 /*ESTABLISHMENT*/
    BEGIN

    DECLARE @GrossReceiptID VARCHAR(20)
    DECLARE @BusinessPPID VARCHAR(20)
    DECLARE @CommonAreaID VARCHAR(20)

    DECLARE @DBAName VARCHAR(100)
    DECLARE @BusinessName VARCHAR(100)

    SELECT @DBAName = dbo.f_info_alpha_people(PeopleRSN, 7004), 
    @BusinessName = OrganizationName,
    @GrossReceiptID = dbo.f_info_alpha_people(PeopleRSN, 7001),
    @BusinessPPID = dbo.f_info_alpha_people(PeopleRSN, 7002),
    @CommonAreaID = dbo.f_info_alpha_people(PeopleRSN, 7003)
    FROM People
    WHERE PeopleRSN = @PeopleRSN    


    UPDATE FolderInfo
    SET InfoValue = @GrossReceiptID,
    InfoValueUpper = UPPER(@GrossReceiptID)
    WHERE FolderRSN = @FolderRSN
    AND InfoCode = 7001

    UPDATE FolderInfo
    SET InfoValue = @BusinessPPID,
    InfoValueUpper = UPPER(@BusinessPPID)
    WHERE FolderRSN = @FolderRSN
    AND InfoCode = 7002

    UPDATE FolderInfo
    SET InfoValue = @CommonAreaID,
    InfoValueUpper = UPPER(@CommonAreaID)
    WHERE FolderRSN = @FolderRSN
    AND InfoCode = 7003

    UPDATE FolderInfo
    SET InfoValue = @DBAName,
    InfoValueUpper = UPPER(@DBAName)
    WHERE FolderRSN = @FolderRSN
    AND InfoCode = 7004

    UPDATE FolderInfo
    SET InfoValue = @BusinessName,
    InfoValueUpper = UPPER(@BusinessName)
    WHERE FolderRSN = @FolderRSN
    AND InfoCode = 7005

END
GO
