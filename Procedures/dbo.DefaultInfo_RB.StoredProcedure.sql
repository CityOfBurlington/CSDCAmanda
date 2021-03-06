USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_RB]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_RB]
@FolderRSN int, @UserId char(10), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @strReferenceFile AS VARCHAR(20)

SELECT @strReferenceFile = CAST(PeopleRSN AS VARCHAR(20))
FROM FolderPeople
WHERE FolderRSN = @FolderRSN
AND PeopleCode = 322

SET @strReferenceFile = ISNULL(@strReferenceFile, 'XXXXXXXX')

UPDATE Folder 
SET ReferenceFile = @strReferenceFile 
WHERE FolderRSN = @FolderRSN
GO
