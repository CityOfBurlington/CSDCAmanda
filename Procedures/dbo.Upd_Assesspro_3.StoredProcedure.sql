USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_Assesspro_3]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Upd_Assesspro_3]
AS
BEGIN

/*SET ANSI_WARNINGS OFF*/

DECLARE @FinalDate	Varchar(100),
	@FolderRSN	Varchar(100)
DECLARE curUpdateAssessPro CURSOR FOR
SELECT ISNULL(FinalDate, GetDate()), F.FolderRSN
from Folder F
where F.InDate >'12/31/2003'
and FolderType IN('Z1','Z2','Z3','ZB')
and F.Folderrsn IN(SELECT Amount2 FROM AssessPro.dbo.DataBuildPermit WHERE Amount2 IS NOT NULL AND DatePaid IS NULL)
and F.StatusCode IN(10007, 10008)
ORDER BY F.FolderRSN

OPEN curUpdateAssessPro
FETCH curUpdateAssessPro INTO
	@FinalDate,
	@FolderRSN 
WHILE @@FETCH_STATUS = 0

BEGIN

	UPDATE AssessPro.dbo.DataBuildPermit SET DatePaid = @FinalDate
	WHERE Amount2 = @FolderRSN

FETCH curUpdateAssessPro INTO
        @FinalDate ,
	@FolderRSN
END

CLOSE curUpdateAssessPro
DEALLOCATE curUpdateAssessPro

/*SET ANSI_WARNINGS ON*/

END



GO
