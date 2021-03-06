USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_PROPERTYINFO_UPDATE]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TK_PROPERTYINFO_UPDATE]
@argPropertyRSN int, 
@argInfoCode int, 
@argInfoValue varchar(1000), 
@DUserID varchar(1000), 
@argDateMask varchar(100) = 'mm/dd/yyyy'
/******************************************************************************
NAME: TOOLKIT.PROPERTYINFO_UPDATE
PURPOSE: Update a property info value.  It will read the valid info definition and update the required date, numeric, upper fields
		 based on the type

REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0		   09/30/2008  Kevin Westoby    Created procedure

NOTES: If date is not mm/dd/yyyy format you must pass the dateMask

******************************************************************************/
AS

DECLARE @v_infoType varchar(1000)
DECLARE @v_errormsg varchar(1000)
DECLARE @v_infoCode varchar (200)

BEGIN

	 SELECT @v_infoType = max(propertyInfoType)
	 FROM validPropertyInfo
	 WHERE propertyinfoCode = @argInfoCode;

	 IF @v_infoType IS NULL
	 BEGIN
		SET @v_infoCode = CAST(@argInfoCode as varchar)
		SET @v_errormsg= @v_infoCode + ' is not a Valid Info Code, please contact your AMANDA Administrator'
		RAISERROR (@v_errormsg ,16  , -1   ) 
	 END

	 IF @v_infoType IN ('A','B','P','C','U') --alpha, boolean, pick, choose and URL are all the same
	 BEGIN

		UPDATE propertyInfo
		SET propinfoValue = @argInfoValue,
		infoValueUpper = UPPER(@argInfoValue),
		stampUser = @DUserID,	
		stampDate = GETDATE()
		WHERE propertyRSN = @argPropertyRSN
		AND propertyinfoCode = @argInfoCode;
	 END

	 ELSE IF @v_infoType = 'D' --date
	 BEGIN

	        UPDATE propertyInfo
		SET propinfoValue = CONVERT(VARCHAR(23), CONVERT(DATETIME, @argInfoValue, 101), 107),	
		infoValueUPPER = UPPER(CONVERT(VARCHAR(23), CONVERT(DATETIME, @argInfoValue, 101), 107)),	
		propertyinfoValueDateTime = CONVERT(DATETIME, @argInfoValue, 101),	
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE propertyRSN = @argPropertyRSN
		AND propertyinfoCode = @argInfoCode;

	 END	

	 ELSE IF @v_infoType = 'N' --numeric
	 BEGIN

	        UPDATE propertyInfo
		SET propinfoValue = @argInfoValue,
		propertyinfoValueNumeric = CAST(@argInfoValue as float),
		stampUser = @DUserID,	
		stampDate = GETDATE() 
		WHERE propertyRSN = @argPropertyRSN
		AND propertyinfoCode = @argInfoCode;
	 END
	 ELSE
	 BEGIN 
		SET @v_infoCode = CAST(@argInfoCode as varchar)
		SET @v_errormsg= @v_infoCode + ' is not a Valid Info Type, please contact your AMANDA Administrator'
		RAISERROR (@v_errormsg ,16  , -1   ) 
	 END

END;




GO
