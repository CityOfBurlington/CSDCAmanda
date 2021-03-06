USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_UC_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_UC_Folder]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
  
/* UC Folder Initialization */

DECLARE @InDate datetime
DECLARE @intParentRSN int
DECLARE @varParentFolderType varchar(4)
DECLARE @intBPChildCount int 
DECLARE @intBPChildRSN int
DECLARE @intInfoCode23001Count int
DECLARE @intInfoCode23002Count int

/* Get folder values. */

SELECT @InDate = Folder.InDate, @intParentRSN = ISNULL(Folder.ParentRSN, 0)
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

/* If the UC folder was created by the Create Child button, Folder.ParentRSN is populated at initialization.  
   If Folder.ParentRSN is populated, check to see if it is for a zoning folder. 
   If so, then check to see if the zoning folder has a child, and if the child is a BP folder.
   Both the zoning folder FolderRSN, and the BP FolderRSN will be coded to the first two 
   FolderInfo fields below. */

SELECT @intBPChildCount = 0

IF @intParentRSN > 0
BEGIN
	SELECT @varParentFolderType = Folder.FolderType 
	FROM Folder 
	WHERE Folder.FolderRSN = @intParentRSN
	
	IF @varParentFolderType LIKE 'Z%' 
	BEGIN
		SELECT @intBPChildCount = COUNT(*)
		FROM Folder
		WHERE Folder.ParentRSN = @intParentRSN 
		AND Folder.FolderType = 'BP'
		
		IF @intBPChildCount > 0
		BEGIN
			SELECT @intBPChildRSN = Folder.FolderRSN
			FROM Folder
			WHERE Folder.ParentRSN = @intParentRSN 
			AND Folder.FolderType = 'BP'
		END
	END
END

/* Insert first two Permit FolderRSN info fields, code FolderRSN values if applicable. */

SELECT @intInfoCode23001Count = COUNT(*)
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 23001

IF @intInfoCode23001Count = 0
BEGIN
	IF @intParentRSN > 0		/* No FolderType check allows for BP-only projects */
	BEGIN
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, InfoValue, InfoValueNumeric, 
			  PrintFlag, ValueRequired, Mandatory, StampDate, StampUser )
		VALUES (@FolderRSN, 23001, 10, @intParentRSN, @intParentRSN, 'Y', 'N', 'N', getdate(), @UserID)
	END
	ELSE
		BEGIN
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, InfoValue, InfoValueNumeric, 
			  PrintFlag, ValueRequired, Mandatory, StampDate, StampUser )
		VALUES (@FolderRSN, 23001, 10, NULL, 0, 'Y', 'N', 'N', getdate(), @UserID)
	END
END
ELSE
BEGIN
	UPDATE FolderInfo
	SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueNumeric = 0
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 23001
END

SELECT @intInfoCode23002Count = COUNT(*)
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 23002

IF @intInfoCode23002Count = 0
BEGIN
	IF @intBPChildRSN > 0 
	BEGIN
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, InfoValue, InfoValueNumeric, 
			  PrintFlag, ValueRequired, Mandatory, StampDate, StampUser )
		VALUES (@FolderRSN, 23002, 20, @intBPChildRSN, @intBPChildRSN, 'Y', 'N', 'N', getdate(), @UserID)
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo 
			( FolderRSN, InfoCode, DisplayOrder, InfoValue, InfoValueNumeric, 
			  PrintFlag, ValueRequired, Mandatory, StampDate, StampUser )
		VALUES (@FolderRSN, 23002, 20, NULL, 0, 'Y', 'N', 'N', getdate(), @UserID)
	END
END
ELSE
BEGIN
	UPDATE FolderInfo
	SET FolderInfo.InfoValue = NULL, FolderINfo.InfoValueNumeric = 0
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 23002
END

/* Insert FolderInfo Construction Phase Number (23035) when applicable. */

IF @intParentRSN > 0 AND @varParentFolderType LIKE 'Z%' 
	EXECUTE dbo.usp_UC_Insert_FolderInfo_Phase_Number @intParentRSN, @FolderRSN, @UserID

/* Add initialization time to Folder.InDate */

UPDATE Folder
SET Folder.InDate = DATEADD(hour, datepart(hour, getdate()), Folder.InDate)
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

UPDATE Folder
SET Folder.InDate = DATEADD(minute, datepart(minute, getdate()), Folder.InDate)
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN 

/* Set Folder.FolderName (street address) to full address (no street type abbreviation) in upper case. */

UPDATE Folder 
SET Folder.FolderName = dbo.udf_GetPropertyAddressLong(@FolderRSN)
WHERE Folder.FolderRSN = @FolderRSN 

/* Null out Folder.FolderCondition - By default at initialization, 
   Property.PropComment is written to Folder.FolderCondition. */

UPDATE Folder
SET Folder.FolderCondition = NULL
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

GO
