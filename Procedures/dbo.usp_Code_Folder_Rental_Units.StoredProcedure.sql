USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Code_Folder_Rental_Units]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Code_Folder_Rental_Units](@Year CHAR(2)) 
AS
BEGIN

DECLARE @PropertyRSN INT
DECLARE @Units INT
DECLARE @TotalUnits INT
SET @TotalUnits = 0

DECLARE curUnits CURSOR FOR
	SELECT DISTINCT Folder.PropertyRSN, dbo.f_info_numeric(Folder.FolderRSN, 20031) AS NumberOfUnits
	FROM Folder
	WHERE Folder.FolderYear = @Year
	AND ((Folder.FolderType = 'RB' AND Folder.StatusCode = 1)
	OR (Folder.FolderType = 'MH' AND Folder.StatusCode IN(2/*Closed*/, 20023 /*In Process*/)))
	/*Total the values in the NumberOfUnits Column*/

OPEN curUnits
FETCH NEXT FROM curUnits INTO @PropertyRSN, @Units
WHILE @@FETCH_STATUS = 0 
    BEGIN

	SET @TotalUnits = @TotalUnits + ISNULL(@Units, 0)
	FETCH NEXT FROM curUnits INTO @PropertyRSN, @Units
END

CLOSE curUnits
DEALLOCATE curUnits

SELECT @TotalUnits
END

GO
