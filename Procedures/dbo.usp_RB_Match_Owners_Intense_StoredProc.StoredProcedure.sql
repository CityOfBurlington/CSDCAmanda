USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB_Match_Owners_Intense_StoredProc]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RB_Match_Owners_Intense_StoredProc]
AS
BEGIN

DECLARE @PropertyRSN INT
DECLARE @PCOName VARCHAR(100)
DECLARE @Match BIT

CREATE TABLE #tempOwnerMismatch(
	PropertyRSN		INT
)

DECLARE curPCO CURSOR FOR
SELECT uvw_RB.PropertyRSN,
UPPER(dbo.udf_GetPeopleLastName(CAST(uvw_RB.ReferenceFile AS INT))) AS PCO
FROM uvw_RB
WHERE FolderStatus = 'Open'
AND FolderYear = '10'

DECLARE @i INT
SET @i = 0

OPEN curPCO

FETCH NEXT FROM curPCO INTO @PropertyRSN, @PCOName

WHILE @@FETCH_STATUS = 0 
BEGIN
	SET @Match = 0
	SET @i = @i + 1

	SELECT @Match = dbo.udf_PrimaryCodeOwner_PropertyOwner_Match(@PropertyRSN, @PCOName) 

	IF @Match = 0 BEGIN
		INSERT INTO #tempOwnerMismatch(PropertyRSN) VALUES(@PropertyRSN) 
	END

	IF @i % 100 = 0 BEGIN
		PRINT @i
	END

	FETCH NEXT FROM curPCO INTO @PropertyRSN, @PCOName
END

CLOSE curPCO
DEALLOCATE curPCO

SELECT * 
FROM #tempOwnerMismatch

END


GO
