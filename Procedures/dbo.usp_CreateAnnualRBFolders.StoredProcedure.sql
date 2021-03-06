USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateAnnualRBFolders]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    PROCEDURE [dbo].[usp_CreateAnnualRBFolders](@NewYear INT, @UserName VARCHAR(8))
AS
BEGIN

	/* DATE: 1/19/2011	Dana Baron  */
	/* This Stored Procedure processes annual Rental Billing (RB) folders */
	/* Other stored procedures that work with this are:                   */
	/*	usp_CreateAnnualRBFolders (this sp)                               */
	/*	usp_CreateRBFolder                                                */
	/*	uv_RB															  */

	DECLARE @PropertyRSN INT
	DECLARE @PriorYear INT
	DECLARE @strPriorYear VARCHAR(4)

	SELECT @PriorYear = @NewYear - 1,
	@strPriorYear = RIGHT(CAST(@NewYear - 1 AS VARCHAR(4)), 2)

	SET @strPriorYear = RIGHT('0' + @strPriorYear, 2)

	/* Select Folders to copy to new year: Open RB folders from previous year */
	DECLARE curRB CURSOR FOR
		SELECT DISTINCT Property.PropertyRSN
		FROM Property
		JOIN PropertyInfo ON Property.PropertyRSN = PropertyInfo.PropertyRSN
		WHERE PropertyInfoCode = 20 AND PropInfoValue > 0
		AND Property.PropertyRSN NOT IN 
		(SELECT PropertyRSN FROM Folder WHERE FolderType = 'RB' AND FolderDescription LIKE '2013 Rental Billing%')
		/* These were created before the routine blew up */

	/* Create a cursor to process selected folders */
	OPEN curRB
	FETCH NEXT FROM curRB INTO @PropertyRSN
	WHILE @@FETCH_STATUS = 0
		BEGIN

		/*Call stored procedure to create a new RB Folder from this one */
		EXEC usp_CreateRBFolder @PropertyRSN, @NewYear, @UserName		

		/*Close Old RB Folder*/
		UPDATE Folder SET StatusCode = 55 /*Cancelled (use cancelled to distinguish from closed) */
		 WHERE FolderRSN IN 
		 (SELECT FolderRSN FROM Folder F1 
		   WHERE F1.PropertyRSN = @PropertyRSN AND F1.FolderYear = @strPriorYear AND F1.FolderType = 'RB')

		FETCH NEXT FROM curRB INTO @PropertyRSN
	END

	CLOSE curRB
	DEALLOCATE curRB

END



GO
