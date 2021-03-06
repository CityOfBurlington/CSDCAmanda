USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_QC_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_QC_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
IF NOT EXISTS(SELECT ParentRSN FROM Folder WHERE FolderType = 'Q1' AND FolderRSN = (SELECT ParentRSN FROM Folder WHERE FolderRSN = @FolderRSN)) BEGIN
      EXEC KillFolder @FolderRSN
      COMMIT TRANSACTION
      
      RAISERROR('YOU MUST CREATE A Q1 FOLDER FIRST !!!!!!!!!!!!!!!!!!', 16, -1)
      RETURN
END

UPDATE FolderPeople
SET FolderPeople.PeopleRSNCrypt = 58
WHERE FolderPeople.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = 7

/* to insert people records from RB */
INSERT INTO FolderPeople (FolderRSN, PeopleRSN, PeopleCode, StampDate, StampUser)
SELECT DISTINCT @FolderRSN, FolderPeople.PeopleRSN, FolderPeople.PeopleCode, getdate(), @UserId
FROM Folder, FolderPeople
WHERE FolderPeople.FolderRSN = Folder.FolderRSN
AND Folder.FolderType = 'RB'
AND Folder.FolderRSN = (SELECT MAX(Folder.FolderRSN) 
FROM Folder 
WHERE FolderType = 'RB' 
AND Folder.PropertyRSN = (SELECT PropertyRSN 
FROM Folder 
WHERE FolderRSN = @FolderRSN))
/* 75 = Property Manager, 80 = Emergency Contact, 125 = Code Owner */
AND FolderPeople.PeopleCode in (322, 75, 80, 125)


GO
