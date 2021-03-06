USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_EP_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_EP_Folder]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @EPLang Varchar(2000)
DECLARE @SubType varchar(25)
DECLARE @SubCode int
DECLARE @WorkCode int

SELECT @Subcode = Folder.Subcode
FROM Folder 
WHERE Folder.FolderRSN = @FolderRSN

SELECT @WorkCode = Folder.WorkCode
FROM folder
WHERE folder.FolderRSN = @FolderRSN

IF @WorkCode = 30115
BEGIN
SET @SubType = 'EP Alt Engy'
END


IF @Subcode = 30000
BEGIN
SET @SubType = 'EP SFH'
END

IF @Subcode = 30001
BEGIN
SET @SubType = 'EP Duplex'
END

IF @Subcode = 30005
BEGIN
SET @SubType = 'EP Multi'
END

IF @Subcode = 30009
BEGIN
SET @SubType = 'EP Commercial'
END

IF @Subcode = 30051
BEGIN
SET @SubType = 'EP Condo'
END

SELECT @EPLang = ValidClause.ClauseText
FROM ValidCLause
WHERE ValidClause.ClauseGroup = @SubType
AND ValidClause.DisplayOrder = @WorkCode


UPDATE Folder
SET Folder.FolderDescription = @EPLang
WHERE folder.FolderRSN = @FolderRSN
GO
