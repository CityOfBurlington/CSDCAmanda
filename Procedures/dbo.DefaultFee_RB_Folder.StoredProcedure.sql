USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_Folder]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @RentalUnits int
DECLARE @PropertyRSN int
 
DECLARE @LastMHInspection DATETIME  /*PropInfo 25*/
DECLARE @COCIssueDate DATETIME      /*PropInfo 30*/
DECLARE @COCExpirationDate DATETIME /*PropInfo 35*/

SELECT @PropertyRSN = Folder.PropertyRSN 
FROM Folder 
WHERE FolderRSN = @FolderRSN

UPDATE Folder 
SET StatusCode = 1
WHERE FolderRSN = @FolderRSN

SELECT @RentalUnits = PropertyInfo.PropertyInfoValueNumeric
FROM PropertyInfo, Folder
WHERE PropertyInfo.PropertyInfoCode = 20
AND PropertyInfo.PropertyRSN = Folder.PropertyRSN
AND Folder.FolderRSN = @FolderRSN

UPDATE FolderInfo
SET FolderInfo.InfoValue = @RentalUnits, FolderInfo.InfoValueNumeric = @RentalUnits
WHERE FolderInfo.InfoCode = 20020
AND FolderInfo.FolderRSN = @FolderRSN

UPDATE FolderInfo
SET FolderInfo.InfoValue = @RentalUnits, FolderInfo.InfoValueNumeric = @RentalUnits
WHERE FolderInfo.InfoCode = 20031
AND FolderInfo.FolderRSN = @FolderRSN

/*Copy People From PropertyPeople into FolderPeople for People Types Property Manager (75), */
/* Emergency Contact (80), Service of Process (85) and Primary Code Owner (322) */

INSERT INTO FolderPeople
(FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampDate, StampUser, PeopleRSNCrypt, SecurityCode)
SELECT @FolderRSN, PeopleCode, PeopleRSN, PrintFlag, GetDate(), @UserID, PeopleRSNCrypt, SecurityCode
FROM PropertyPeople
WHERE PropertyRSN = @PropertyRSN
AND PropertyPeople.PeopleCode IN (75, 80, 85, 322)


SELECT @LastMHInspection = dbo.f_info_date_property(@PropertyRSN, 25)
SELECT @COCIssueDate = dbo.f_info_date_property(@PropertyRSN, 30)
SELECT @COCExpirationDate = dbo.f_info_date_property(@PropertyRSN, 35)

IF NOT EXISTS (SELECT * FROM PropertyInfo WHERE PropertyRSN=@PropertyRSN AND PropertyInfoCode=25) 
BEGIN
IF @LastMHInspection IS NULL
BEGIN
    INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode, StampUser, StampDate)
    VALUES(@PropertyRSN, 25, @UserId, GETDATE())
END
END

IF NOT EXISTS (SELECT * FROM PropertyInfo WHERE PropertyRSN=@PropertyRSN AND PropertyInfoCode=30) 
BEGIN
IF @COCIssueDate IS NULL
BEGIN
    INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode, StampUser, StampDate)
    VALUES(@PropertyRSN, 30, @UserId, GETDATE())
END
END


IF NOT EXISTS (SELECT * FROM PropertyInfo WHERE PropertyRSN=@PropertyRSN AND PropertyInfoCode=35) 
BEGIN
IF @COCExpirationDate IS NULL
BEGIN
    INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode, StampUser, StampDate)
    VALUES(@PropertyRSN, 35, @UserId, GETDATE())
END
END

GO
