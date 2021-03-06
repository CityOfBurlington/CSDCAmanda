USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_Assesspro_4]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Upd_Assesspro_4]
AS
BEGIN

/*SET ANSI_WARNINGS OFF*/

DECLARE @FinalDate	Varchar(100),
	@FolderRSN	Varchar(100)

DECLARE curUpdateAssessPro CURSOR FOR
SELECT ISNULL(FinalDate, GETDATE()), F.FolderRSN
FROM Folder F
WHERE F.InDate > '12/31/2003'
AND FolderType IN('BP', 'EP', 'MP', 'PP', 'SS', 'SU')
AND F.Folderrsn IN(select Amount2 from AssessPro.dbo.DataBuildPermit WHERE Amount2 IS NOT NULL AND DatePaid IS NULL)
AND F.StatusCode IN(30003, 30004, 2)
ORDER BY F.Folderrsn

OPEN curUpdateAssessPro
FETCH curUpdateAssessPro INTO
	@Finaldate,
	@FolderRSN 
WHILE @@FETCH_STATUS = 0

BEGIN

	UPDATE AssessPro.dbo.DataBuildPermit SET DatePaid = @Finaldate
	WHERE Amount2 = @FolderRSN 

		
FETCH curUpdateAssessPro INTO
        @FinalDate, 
	@FolderRSN
END


CLOSE curUpdateAssessPro
DEALLOCATE curUpdateAssessPro

/*SET ANSI_WARNINGS ON*/

END








GO
