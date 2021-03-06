USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_PROCESSINFO_UPDATE]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/******************************************************************************
NAME: TOOLKIT.PROCESSINFO_UPDATE
PURPOSE: Update a process info value.  It will read the valid info definition and update the required date, numeric, upper fields
based on the type

REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0                        Shraddha    converted oracle proc to mssql

NOTES: If you are passing a date the string value of the date must be in mm/dd/yyyy format

******************************************************************************/

CREATE PROCEDURE [dbo].[TK_PROCESSINFO_UPDATE]
@argProcessRSN INT,
@argInfoCode INT,
@argInfoValue VARCHAR(1000),
@DUserID VARCHAR(1000) 
AS

DECLARE @v_infoType VARCHAR(100)
DECLARE @v_errormsg varchar (2000)
DECLARE @v_infoCode varchar (200)
		
BEGIN
	SELECT @v_infoType = MAX(infoType)
	FROM validProcessInfo 
	WHERE infoCode = @argInfoCode
		
	IF @v_infoType IS NULL 
	BEGIN 
        	SET @v_infoCode = CAST(@argInfoCode as varchar)
           	SET @v_errormsg = @v_infoCode + ' is not a Valid Info Code, please contact your AMANDA Administrator'
		RAISERROR (@v_errormsg ,16  , -1   ) 	
	END
   	
	IF LEN(@v_errormsg) > 0 
	BEGIN
		RAISERROR (@v_errormsg, 16, -1) 
	END

	IF @v_infoType IN ( 'A' , 'B' , 'P' , 'C' , 'U' ) 
	BEGIN 

		UPDATE folderProcessInfo   
		SET infoValue = @argInfoValue,	
		infoValueUpper = UPPER(@argInfoValue),	
		stampUser = @DUserID,		
		stampDate = GETDATE() 
		WHERE processRSN  = @argProcessRSN
		AND infoCode  = @argInfoCode 
	END
	ELSE IF @v_infoType = 'D'
	BEGIN 
--SET @v_errormsg = cast(@argInfoCode as varchar)+' '+@argInfoValue
	--RAISERROR(@v_errormsg,16,-1)
		UPDATE folderProcessInfo   
		SET infoValue = CONVERT(VARCHAR(23), CONVERT(DATETIME, @argInfoValue, 101), 107),	
		infoValueUPPER = UPPER(CONVERT(VARCHAR(23), CONVERT(DATETIME, @argInfoValue, 101), 107)),	
		--infoValueDateTime = CONVERT(DATETIME, @argInfoValue, 101),	
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE processRSN = @argProcessRSN
		AND infoCode = @argInfoCode 
	END
	ELSE IF @v_infoType = 'N'
	BEGIN 
	
		UPDATE folderProcessInfo   
		SET infoValue = @argInfoValue,	
		infoValueNumeric = CAST(@argInfoValue as float),	
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE processRSN = @argProcessRSN
		AND infoCode = @argInfoCode 
	END
	ELSE
	BEGIN 
		SET @v_infoCode = CAST(@argInfoCode as varchar)
		SET @v_errormsg= @v_infoCode + ' is not a Valid Info Code, please contact your AMANDA Administrator'
		RAISERROR (@v_errormsg ,16  , -1   ) 
	END

END






GO
