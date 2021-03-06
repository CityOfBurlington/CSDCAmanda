USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZB_Folder]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZB_Folder]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Folder Initialization */

/* Call this procedure with EXECUTE DefaultFee_ZB_Folder @folderRSN, @UserID */

DECLARE @FolderType varchar(4)
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @intPropertyStatus int
DECLARE @YearBuilt int
DECLARE @ZnDistrict  varchar(20)
DECLARE @ZnDistrict1 varchar(8)
DECLARE @ZnDistrict2 varchar(8)
DECLARE @ZnDistrict3 varchar(8)
DECLARE @LotSize int
DECLARE @Ward int
DECLARE @intSFHAPropInfoCount int
DECLARE @intSFHAFolderInfoDisplayOrder int
DECLARE @varProjectNumber varchar(20)
DECLARE @intProjectNumberYear int
DECLARE @ZPNumber varchar(20)
DECLARE @ZPNumberCount int
DECLARE @intStreetNumber int
DECLARE @varStreetStatus varchar(20)
DECLARE @ReviewClockProcess int
DECLARE @AppealClockProcess int
DECLARE @NextProcessRSN int
DECLARE @SignNumberOrder int
DECLARE @SignTypeOrder int
DECLARE @SignMaterialsOrder int
DECLARE @AwningNumberOrder int
DECLARE @AwningMaterialsOrder int
DECLARE @IlluminationOrder int
DECLARE @InTime AS INT

/* Get folder type and other values. */

SELECT @FolderType = Folder.FolderType, 
       @InDate = Folder.InDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode 
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

/* Add initialization time to Folder.InDate */
/* NOTE: AMANDA Browser Version (AMANDA 5) includes the time as part of InDate.
         AMANDA Desktop Version does NOT inlcude the time as of InDate.
         The code below tests to see if time is included and tacks on the time if not.
*/ 
SELECT @InTime = DatePart(HOUR,Indate) FROM Folder WHERE FolderRSN = @FolderRSN
IF @InTime = 0
BEGIN
   UPDATE Folder
      SET Folder.InDate = DATEADD(hour, datepart(hour, getdate()), Folder.InDate)
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN

   UPDATE Folder
      SET Folder.InDate = DATEADD(minute, datepart(minute, getdate()), Folder.InDate)
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN
END
/* Null out Folder.FolderCondition - By default at initialization, 
   Property.PropComment is written to Folder.FolderCondition. */

UPDATE Folder
   SET Folder.FolderCondition = NULL
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

/* Generate the next Project Number and code to Folder.ReferenceFile, and for 
   ZZ folders, check to insure the first two characters of Folder.ReferenceFile 
   are numeric (fiscal year). */

IF @FolderType <> 'ZZ'
BEGIN
   SELECT @varProjectNumber = dbo.udf_GetProjectNumberNext(@FolderRSN, getdate())

   UPDATE Folder
      SET Folder.ReferenceFile = @varProjectNumber
     FROM Folder 
    WHERE Folder.FolderRSN = @FolderRSN
END
ELSE
BEGIN
   SELECT @intProjectNumberYear = ISNUMERIC(SUBSTRING(Folder.ReferenceFile, 1, 2))
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN 

   IF @intProjectNumberYear <> 1
   BEGIN 
     RAISERROR ('Alas, the first two characters of the Project Number must be numeric (fiscal year). Your desire for precise record keeping can not be fulfilled. Please re-enter.', 16,-1)
     RETURN
   END
END

/* Set Folder.FolderName (street address) to full address (no street type abbreviation) 
   in upper case. */

UPDATE Folder 
   SET Folder.FolderName = dbo.udf_GetPropertyAddressLong(@FolderRSN)
 WHERE Folder.FolderRSN = @FolderRSN 

/* For ZZ folders, null out Folder.IssueUser. */

IF @FolderType = 'ZZ'
BEGIN 
   UPDATE Folder 
      SET Folder.IssueUser = NULL
    WHERE Folder.FolderRSN = @FolderRSN 
END

/* Check to insure an Historic Property is not being used for a new non-ZZ folder. 
   Check for valid Property status. */

SELECT @intPropertyStatus = Property.StatusCode
  FROM Property, Folder
 WHERE Property.PropertyRSN = Folder.PropertyRSN
   AND Folder.FolderRSN = @FolderRSN 

IF @FolderType <> 'ZZ' AND @intPropertyStatus = 2
BEGIN
  RAISERROR ('A permit may not be issued for an Inactive status Property. Please choose an Active or Pending Property.', 16,-1)
  RETURN
END

IF @intPropertyStatus > 3
BEGIN
  RAISERROR ('Invalid Property status. Please choose an Active or Pending status Property.', 16,-1)
  RETURN
END

/* Check Folder.ReferenceFile entry, and if not unique or null, issue warning.
   Make the entry upper case. Discontinued Nov 16, 2010 at 16:00.  

SELECT @ZPNumber = Folder.ReferenceFile
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

IF @ZPNumber = NULL 
BEGIN
  RAISERROR ('A ZP Number (Reference File) is required for initialization. Please enter the Zoning Permit number.', 16,-1)
  RETURN
END
ELSE
BEGIN
   UPDATE Folder
      SET Folder.ReferenceFile = UPPER(@ZPNumber)
    WHERE Folder.FolderRSN = @FolderRSN
END  */

/* Check for unique value entry - discontinued July 1, 2010 

SELECT @ZPNumberCount = COUNT(*)
  FROM Folder
 WHERE Folder.FolderType IN('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZD', 'ZF', 'ZH', 'ZL', 'ZN', 'ZP', 'ZS', 'ZZ') 
   AND Folder.ReferenceFile = 
     ( SELECT Folder.ReferenceFile FROM Folder WHERE Folder.FolderRSN = @FolderRSN )

IF @ZPNumberCount > 1 
BEGIN
  RAISERROR ('This ZP Number is already in the system. Make sure folder has not been previously initialized', 16,-1)
  RETURN
END   */

/* Code info fields Year Built, Zoning District, Design Review, DPW Street Status.  
   Not applicable for ZZ folders. */

IF @FolderType <> 'ZZ'
BEGIN

   /* Retrieve Year Built from Property, and code to Info. */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10029, 60, @UserID 

   /* Retrieve Zoning District and code to Info. */

   SELECT @ZnDistrict1 = Property.ZoneType1, 
          @ZnDistrict2 = Property.ZoneType2, 
          @ZnDistrict3 = Property.ZoneType3
     FROM Property, Folder
    WHERE Property.PropertyRSN = Folder.PropertyRSN
      AND Folder.FolderRSN = @FolderRSN

   IF NULLIF(@ZnDistrict3, ' ') IS NOT NULL 
      SELECT @ZnDistrict = @ZnDistrict1 + '/' + @ZnDistrict2 + '/' + @ZnDistrict3
   ELSE
   BEGIN 
      IF NULLIF(@ZnDistrict2, ' ') IS NOT NULL 
         SELECT @ZnDistrict = @ZnDistrict1 + '/' + @ZnDistrict2
      ELSE SELECT @ZnDistrict = @ZnDistrict1
   END

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = @ZnDistrict,
          FolderInfo.InfoValueUpper = UPPER(@ZnDistrict)
    WHERE FolderInfo.InfoCode = 10002
      AND FolderInfo.FolderRSN = @folderRSN

   /* Insert FolderInfo NRP: Wetland */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10034, 90, @UserID 

   /* Insert FolderInfo NRP: Natural Area */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10076, 95, @UserID 

   /* Insert FolderInfo Design Review Geographic */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10031, 121, @UserID 

   /* Insert FolderInfo Institutional Core Campus */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10030, 122, @UserID 

   /* Insert FolderInfo RH Density Bonus */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10035, 123, @UserID 

   /* Insert FolderInfo NRP: Riparian and Littoral Zone */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10051, 124, @UserID 

   /* Insert FolderInfo RL Larger Lot */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10037, 125, @UserID 

   /* Insert FolderInfo Mouth of the River */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10123, 126, @UserID 

   /* Insert FolderInfo Centennial Woods */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10124, 127, @UserID 

   /* Insert FolderInfo Parking District */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10125, 128, @UserID 

   /* Insert FolderInfo NRP: Vernal Pool */

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10126, 129, @UserID 

END   /* End of FolderType <> 'ZZ' */

/* Retrieve DPW Street Status from Street type Property, and code to Info. */

SELECT @intStreetNumber = dbo.udf_GetStreetIDNumberFromFolder(@FolderRSN)

SELECT @varStreetStatus = PropertyInfo.PropInfoValue
  FROM PropertyInfo, Property 
 WHERE Property.PropCode = 200             /* Street */
   AND Property.Prop116 = @intStreetNumber
   AND Property.PropertyRSN = PropertyInfo.PropertyRSN
   AND PropertyInfo.PropertyInfoCode = 300

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @varStreetStatus, 
       Folderinfo.InfoValueUpper =UPPER(@varStreetStatus)
 WHERE FolderInfo.InfoCode = 10075
  AND FolderInfo.FolderRSN = @FolderRSN

/* Retrieve Lot Size in square feet from Property, and code to Info. */

SELECT @LotSize = Property.PropArea
  FROM Folder, Property
 WHERE Folder.PropertyRSN = Property.PropertyRSN
   AND Folder.FolderRSN = @FolderRSN

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @LotSize, 
       Folderinfo.InfoValueNumeric = @LotSize
 WHERE FolderInfo.InfoCode = 10047
 AND FolderInfo.FolderRSN = @FolderRSN

/* Retrieve Ward from Property, and code to Info. */

SELECT @Ward = Property.PropPlan
  FROM Property, Folder
 WHERE Property.PropertyRSN = Folder.PropertyRSN
   AND Folder.FolderRSN = @FolderRSN

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @Ward,
       FolderInfo.InfoValueNumeric =@Ward
 WHERE FolderInfo.InfoCode = 10067
   AND FolderInfo.FolderRSN =@FolderRSN

/* Insert FolderInfo Special Flood Hazard Area */

EXECUTE dbo.usp_Zoning_Insert_FolderInfo_PropertyInfo_Alpha @FolderRSN, 10033, 85, @UserID 

/* For ZL folders, set Folder.StatusCode to Appealed to DRB for appeals of 
   Code Enforcement and misc zoning decisions. Add Appeal Clock process. */

IF @FolderType = 'ZL' 
BEGIN
 UPDATE Folder
      SET Folder.StatusCode = 10009 
    WHERE Folder.FolderRSN = @FolderRSN

   SELECT @ReviewClockProcess = COUNT(*)
     FROM FolderProcess
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode = 10007

   SELECT @AppealClockProcess = COUNT(*)
     FROM FolderProcess
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode = 10018

   IF @ReviewClockProcess > 0
   BEGIN
      DELETE FROM FolderProcess
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessCode = 10007
   END

   IF @AppealClockProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
                ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
            ScheduleDate, BaselineStartDate, DisplayOrder,
                  PrintFlag, MandatoryFlag, StampDate, StampUser )
         VALUES ( @NextProcessRSN, @FolderRSN, 10018, 45, 1,
                  getdate(), getdate(), 100, 
                  'Y', 'Y', getdate(), @UserID )
   END
END

/* Insert Folder Clock - Counter is in Days. */

IF @FolderType IN('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZD', 'ZF', 'ZH', 'ZP') 
BEGIN
   INSERT INTO FolderClock  
      (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
   VALUES 
      (@FolderRSN, 'Admin Review', 30, getdate(), 0, 'Not Started', 'Green')
END

IF @FolderType = 'ZL'     /* Misc Appeals */
BEGIN
 INSERT INTO FolderClock  
      (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
   VALUES 
      (@FolderRSN, 'Admin Review', 30, getdate(), 0, 'Running', 'Green')

   INSERT INTO FolderClock  
  (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
   VALUES 
      (@FolderRSN, 'Scheduler', 60, getdate(), 0, 'Running', 'Yellow')
END

/* Add Sign and Awning related Info fields (ZA Folder). */

IF @FolderType = 'ZA' 
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_ZA_Folder @FolderRSN, @UserID 


GO
