USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_FOLDERINFO_UPDATE]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TK_FOLDERINFO_UPDATE]
@argFolderRSN INTEGER,
@argInfoCode INTEGER,
@argInfoValue VARCHAR (4000),
@DUserID VARCHAR(4000) 
AS 

/******************************************************************************
NAME: TOOLKIT.FOLDERINFO_UPDATE
PURPOSE: Update a folder info value.  It will read the valid info definition and update the required date, numeric, upper fields
based on the type

REVISIONS:

Ver			Date        Author			Description
---------	----------  --------------	------------------------------------
1.0						Shraddha		Created procedure
			2/28/2011	Dana Baron		Added check if folderinfo exists and INSERT if it does not

NOTES: If you are passing a date the string value of the date must be in mm/dd/yyyy format

******************************************************************************/

DECLARE @v_infoType VARCHAR (128)
DECLARE @v_errormsg varchar(2000)
DECLARE @v_infocode varchar(100)

BEGIN

	SELECT @v_infoType  =  MAX(infoType)
	FROM validInfo 
	WHERe infoCode  = @argInfoCode

	IF @v_infoType IS NULL 
	BEGIN
		SET @v_infocode = Cast(@argInfoCode as varchar)
		SET @v_errormsg = @v_infocode +' is not a Valid Info Code, please contact your AMANDA Administrator'
		
	END

	IF LEN(@v_errormsg) > 0 
	BEGIN
		RAISERROR (@v_errormsg, 16, -1) 
	END

	IF NOT EXISTS (SELECT * FROM FolderInfo WHERE InfoCode = @argInfoCode AND FolderRSN = @argFolderRSN)
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode) VALUES (@argFolderRSN, @argInfoCode)
	END

	IF @v_infoType IN ( 'A' , 'B' , 'P' , 'C' , 'U' ) 
	BEGIN 

		UPDATE folderinfo   
		SET infoValue = @argInfoValue,	
		infoValueUpper = UPPER(@argInfoValue),	
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE  folderRSN  = @argFolderRSN
		AND infoCode  = @argInfoCode 
	END
	ELSE IF @v_infoType = 'D'
	BEGIN 

		UPDATE folderinfo   
		SET infoValue = CONVERT(VARCHAR(23), CONVERT(DATETIME, @argInfoValue, 101), 107),	
		infoValueUPPER = UPPER(CONVERT(VARCHAR(23), CONVERT(DATETIME, @argInfoValue, 101), 107)),	
		infoValueDateTime = CONVERT(DATETIME, @argInfoValue, 101),	
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE folderRSN  = @argFolderRSN
		AND infoCode  = @argInfoCode 
	END
	ELSE IF @v_infoType = 'N'
	BEGIN 

		UPDATE folderinfo   
		SET infoValue = @argInfoValue,	
		infoValueNumeric = CAST(@argInfoValue as float),	
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE folderRSN = @argFolderRSN
		AND infoCode = @argInfoCode 
	END
	ELSE
	BEGIN
		SET @v_errormsg = @v_infoType +' is not supported for updating folderInfo, please contact your AMANDA Administrator'
		RAISERROR ( @v_errormsg , 16  , -1   ) 
	END

END
GO
