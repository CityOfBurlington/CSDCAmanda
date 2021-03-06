USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Q1_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Q1_Folder]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @PropertyRSN INT

UPDATE FolderPeople
SET FolderPeople.PeopleRSNCrypt = 58
WHERE FolderPeople.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = 7

SELECT @PropertyRSN = Folder.PropertyRSN
FROM Folder
WHERE FolderRSN = @FolderRSN

/* Insert People into folder: 75 = Property Manager, 80 = Emergency Contact, 125 = Code Owner, 322 = Primary Code Owner */
INSERT INTO FolderPeople (FolderRSN, PeopleRSN, PeopleCode, StampDate, StampUser)
SELECT DISTINCT @FolderRSN, PropertyPeople.PeopleRSN, PropertyPeople.PeopleCode, getdate(), @UserId
FROM PropertyPeople
WHERE PropertyPeople.PropertyRSN = @PropertyRSN 
AND PropertyPeople.PeopleCode in (125, 80, 75, 322)
GO
