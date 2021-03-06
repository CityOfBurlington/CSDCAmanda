USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RentalProperty_No_InspectionFolder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_RentalProperty_No_InspectionFolder]
AS
BEGIN
/*
MH
-------------------
Canceled
Closed
In Process
Inspection Due
Preliminary

RI
-------------------
Closed
Extension Granted
Inspection Due
Inspection Scheduled
Open
Violation
*/
DECLARE @PropertyRSN INT

DECLARE curProperty CURSOR FOR
SELECT PropertyRSN
FROM uvw_RentalPropertyRSNs 

OPEN curProperty

FETCH NEXT FROM curProperty INTO @PropertyRSN

WHILE @@FETCH_STATUS = 0 
	BEGIN

	IF EXISTS(SELECT * FROM uvw_RI WHERE FolderStatus <> 'Closed')
		BEGIN
		PRINT @PropertyRSN
	END

	FETCH NEXT FROM curProperty INTO @PropertyRSN
END

CLOSE curProperty
DEALLOCATE curProperty

END


GO
