USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFolderPeople_RB]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFolderPeople_RB]
@FolderRSN int, @UserId char(10), @PeopleRSN int, @PeopleCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
IF @PeopleCode = 322 /*Primary code owner*/
    BEGIN
    
    UPDATE Folder 
    SET ReferenceFile = CAST(@PeopleRSN AS VARCHAR(20))
    WHERE FolderRSN = @FolderRSN
END
GO
