USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Code_Units_Inspected]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Code_Units_Inspected](@Year CHAR(2))
AS
BEGIN

DECLARE @PropertyRSN INT
DECLARE @Units INT
DECLARE @TotalProperties INT
DECLARE @TotalUnits INT

SET @TotalProperties = 0
SET @TotalUnits = 0

DECLARE curRBUnits CURSOR FOR
	SELECT DISTINCT Folder.PropertyRSN, dbo.f_info_numeric(Folder.FolderRSN, 20031) AS NumberOfUnits
	FROM Folder
	WHERE Folder.FolderYear = @Year
	AND Folder.FolderType = 'RB'
	AND Folder.FolderRSN NOT IN(
				SELECT FolderRSN FROM FolderProcessAttempt WHERE ResultCode = 20052/*Property No Longer Rental*/
			)

OPEN curRBUnits

FETCH NEXT FROM curRBUnits INTO @PropertyRSN, @Units
WHILE @@FETCH_STATUS = 0 
    BEGIN

	SET @TotalProperties = @TotalProperties + 1
	SET @TotalUnits = @TotalUnits + ISNULL(@Units, 0)

	FETCH NEXT FROM curRBUnits INTO @PropertyRSN, @Units
END

CLOSE curRBUnits
DEALLOCATE curRBUnits

DECLARE curMHUnits CURSOR FOR
	SELECT DISTINCT Folder.PropertyRSN, dbo.f_info_numeric(Folder.FolderRSN, 20031) AS NumberOfUnits
	FROM Folder
	WHERE Folder.FolderYear = @Year
	AND Folder.FolderType = 'MH'
	AND Folder.StatusCode IN(2/*Closed*/, 20023 /*In Process*/)
	AND Folder.FolderRSN NOT IN(
					SELECT FolderRSN FROM Folder WHERE StatusCode = 55/*Canceled*/
				)

OPEN curMHUnits

FETCH NEXT FROM curMHUnits INTO @PropertyRSN, @Units
WHILE @@FETCH_STATUS = 0 
    BEGIN

	SET @TotalProperties = @TotalProperties + 1
	SET @TotalUnits = @TotalUnits + ISNULL(@Units, 0)

	FETCH NEXT FROM curMHUnits INTO @PropertyRSN, @Units
END

CLOSE curMHUnits
DEALLOCATE curMHUnits

SELECT @TotalProperties AS Properties, @TotalUnits AS RentalUnits

END

GO
