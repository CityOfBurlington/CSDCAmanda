USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PC_FolderChild_Insert]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PC_FolderChild_Insert]
(@argParentRSN int, @argFolderType varchar(10), @DUserID varchar(1000), @argStatusCode int=NULL, @argSubCode int=NULL, @argWorkCode int=NULL)
--WITH 
--EXECUTE AS CALLER
AS
DECLARE @n_newStatusCode int;
DECLARE @FolderRSN int
DECLARE @folderSequence varchar(1000)
DECLARE @folderYear varchar(10)
/*
CURSOR InfoList IS
SELECT fi.infoCode, fi.infoValue, fi.infoValueUpper, fi.infoValueDateTime, fi.infoValueNumeric
FROM folderInfo fi, folderInfo fi1
WHERE fi.folderRSN = argParentRSN
AND fi1.folderRSN = argFolderRSN
AND fi.infoCode = fi1.infoCode;
*/
BEGIN

	--get the folderRSN
	SELECT @FolderRSN = max(folderRSN)+ 1
	FROM folder

	
	--get the folder sequence
	--SET @folderYear = datePart(yy,getDate())
	
	SET @folderYear = SUBSTRING(Cast(datePart(yy, getdate()) AS VARCHAR(2000)), 3, 2)
	
	SELECT @folderSequence = max(folderSequence)+1
	FROM folder
	WHERE folderYear = @folderYear

  IF @folderSequence IS NULL
	BEGIN
	
	       SELECT @folderSequence = 100001
				 
	END
	
	--get the default statusCode for this group
	SELECT @n_newStatusCode = max(newStatusCode)
	FROM validFolder vf, validFolderGroup vg
	WHERE vf.folderType = @argFolderType
	AND vf.folderGroupCode = vg.folderGroupCode

	INSERT INTO Folder
	(FolderRSN, FolderSequence, FolderCentury, FolderYear, FolderSection, FolderRevision, FolderType, StatusCode,
	InDate, SubCode, WorkCode, CopyFlag, StampDate, StampUser, PropertyRSN, ParentRSN, ReferenceFile, FolderName, propertyLocation)
	SELECT @FolderRSN, @FolderSequence, FolderCentury, @folderYear, '000', FolderRevision, @argFolderType, ISNULL(@argStatusCode, @n_newStatusCode),
	getDate(), @argSubCode, @argWorkCode, 'DDDDD', getDate(), @DUserID, PropertyRSN, @argParentRSN, NULL, folderName, propertyLocation
	FROM folder
	WHERE folderRSn = @argParentRSN;

	--copy any folder info that matches info Code
	UPDATE folderInfo
	SET infoValue = fi2.infoValue,
	infoValueNumeric = fi2.infoValueNumeric,
	infoValueUpper = fi2.infoValueUpper,
	infoValueDateTime = fi2.infoValueDateTime
	FROM folderInfo, folderInfo fi2
	WHERE folderInfo.folderRSN = @FolderRSN
	AND fi2.folderRSN = @argParentRSN
	AND folderInfo.infoCode = fi2.infoCode

	--copy the properties

	INSERT INTO folderProperty (folderRSN, propertyRSN)
	SELECT @FolderRSN, propertyRSN
	FROM folderProperty
	WHERE folderRSN = @argParentRSN
	AND propertyRSN NOT IN (SELECT propertyRSN FROM folderProperty WHERE folderRSN = @FolderRSN)

	--copy the people records
	DELETE FROM folderPeople
	WHERE folderRSn = @FolderRSN

	INSERT INTO folderPeople(folderRSN, peopleRSN, peopleCode)
	SELECT @FolderRSN, peopleRSN, peopleCode
	FROm folderPeople
	WHERE folderRSN = @argParentRSN


	--return the new folderRSN
	RETURN @FolderRSN
	
END

GO
