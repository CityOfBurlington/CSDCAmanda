USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_MH_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_MH_Folder]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @PropertyRSN INT
DECLARE @NumberOfRentalUnits INT
DECLARE @InspAssigned VARCHAR(128)
DECLARE @InspName VARCHAR(128)
DECLARE @NextProcessRSN int

SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

SELECT @PropertyRSN = Folder.PropertyRSN, @InspAssigned = Folder.IssueUser, 
@NumberOfRentalUnits = dbo.f_info_numeric_property(Folder.PropertyRSN, 20)
FROM Folder 
WHERE FolderRSN = @FolderRSN

SELECT @InspName = UserName FROM ValidUser WHERE UserId = @InspAssigned

/* Update FolderInfo field 20031 (Number of Rental Units) with value from PropertyInfo 20 */
UPDATE FolderInfo
SET InfoValue = @NumberOfRentalUnits,
InfoValueNumeric = @NumberOfRentalUnits
WHERE FolderRSN = @FolderRSN
AND InfoCode = 20031

/* Update FolderInfo field 20009 (Inspector Assigned) with value from Folder.IssueUser (entered by user) */
UPDATE FolderInfo
SET InfoValue = @InspName,
InfoValueUpper = UPPER(@InspAssigned)
WHERE FolderRSN = @FolderRSN
AND InfoCode = 20009

/* Insert People into folder: 75 = Property Manager, 80 = Emergency Contact, 125 = Code Owner, 322 = Primary Code Owner */
INSERT INTO FolderPeople (FolderRSN, PeopleRSN, PeopleCode, StampDate, StampUser)
SELECT DISTINCT @FolderRSN, PropertyPeople.PeopleRSN, PropertyPeople.PeopleCode, getdate(), @UserId
FROM PropertyPeople
WHERE PropertyPeople.PropertyRSN = @PropertyRSN 
AND PropertyPeople.PeopleCode in (125, 80, 75, 322)

/* Insert Folder Process 20028 (Initial Contact) */
SELECT @NextProcessRSN = MAX(ProcessRSN) + 1 FROM FolderProcess
INSERT INTO FolderProcess 
(ProcessRSN, FolderRSN, ProcessCode, AssignedUser, DisciplineCode, DisplayOrder, PrintFlag, StatusCode, StampDate, StampUser) 
VALUES ( @NextProcessRSN, @FolderRSN, 20028, @InspAssigned, 0, 0, 'Y', 1, GetDate(), @UserId) 

/* Make sure all necessary Property Info fields exist */
/* Check for COC Issue Date (30) */
IF NOT EXISTS (SELECT PropertyRSN FROM PropertyInfo WHERE PropertyInfo.PropertyRSN = @PropertyRSN AND PropertyInfoCode = 30)
BEGIN
	INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode)
	VALUES(@PropertyRSN, 30)
END

/* Check for COC Expiration Date (35) */
IF NOT EXISTS (SELECT PropertyRSN FROM PropertyInfo WHERE PropertyInfo.PropertyRSN = @PropertyRSN AND PropertyInfoCode = 35)
BEGIN
	INSERT INTO PropertyInfo (PropertyRSN, PropertyInfoCode)
	VALUES(@PropertyRSN, 35)
END

GO
