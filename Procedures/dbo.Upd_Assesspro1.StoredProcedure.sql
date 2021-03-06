USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_Assesspro1]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Upd_Assesspro1]
	AS
	BEGIN

	DECLARE @intMaxRSN	int

	SELECT @intMaxRSN = IsNull(MAX(SeqNumber), 1) + 1 FROM Assesspro.dbo.DataBuildPermit

	CREATE TABLE #tempPermits1(
		TableID			int identity primary key not null,
		PropInfoValue		Varchar(100),
		IssueDate		Varchar(100),
		FolderDescription	Varchar(2000),
		FolderType		Varchar(10),
		InfoValueNumeric	Varchar(100),
		ReferenceFile		Varchar(100),
		FolderRSN		Varchar(100),
		MaxRSN			Int
	)

	INSERT INTO #tempPermits1
	(PropInfoValue, IssueDate, FolderDescription, FolderType,
	InfoValueNumeric, ReferenceFile, FolderRSN, MaxRSN)
	SELECT PropInfoValue, 
		IsNull(IssueDate, InDate) AS IssueDate, 
		SubString(FolderDescription, 1, 2000) AS FolderDescription, 
		FolderType,
		InfoValueNumeric,
		ReferenceFile,
		F.FolderRSN,
		1 AS MaxRSN
	FROM Folder F
	INNER JOIN Folderinfo FI ON F.FolderRSN = FI.FolderRSN
	INNER JOIN PropertyInfo PRI ON F.PropertyRSN = PRI.PropertyRSN
	WHERE PRI.PropertyInfoCode = 500
		AND FI.InfoCode = 10000
		AND F.InDate >'12/31/2003'
		AND FolderType IN('Z1', 'Z2', 'Z3', 'ZB', 'ZA', 'ZF')
		AND F.FolderRSN NOT IN(SELECT Amount2 FROM AssessPro.dbo.DataBuildPermit WHERE Amount2 IS NOT NULL)
		AND F.StatusCode = 10006
	ORDER BY 7

	--UPDATE #tempPermits1 SET TempPermitID = TempPermitID + @intMaxRSN


	SELECT * FROM #tempPermits1


END


GO
