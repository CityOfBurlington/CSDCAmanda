USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFolderPeople_MH]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFolderPeople_MH]
@FolderRSN int, @UserId char(10), @PeopleRSN int, @PeopleCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/*
DECLARE @PrimaryOwners INT

SELECT @PrimaryOwners = SUM(1) 
FROM FolderPeople
WHERE FolderRSN = @FolderRSN
AND PeopleCode = @PeopleCode

IF @PeopleCode = 322 AND ISNULL(@PrimaryOwners, 0) > 0
    BEGIN

         RAISERROR('You cannot have more than one Primary Code Owner per folder', 16, -1)

    END
*/
GO
