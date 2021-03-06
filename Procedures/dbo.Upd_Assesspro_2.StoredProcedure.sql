USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_Assesspro_2]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Upd_Assesspro_2]
AS
BEGIN

SET ANSI_WARNINGS ON
DECLARE @Propinfovalue		Varchar(100),
	@IssueDate		Varchar(100),
	@FolderDescription	Varchar(2000),
	@FolderType		Varchar(10),
	@EstCost		Decimal(20,5),
	@ReferenceFile		Varchar(100),
	@FolderRSN		Varchar(100),
	@MaxRSN			int

DECLARE curUpdateAssessPro CURSOR FOR

SELECT PropInfoValue, 
	ISNULL(Issuedate, InDate) AS IssueDate, 
	SUBSTRING(FolderDescription, 1, 255) AS FolderDescription,  
	SUBSTRING(FolderType, 1, 4) AS FolderType,
	CONVERT(Decimal(20,5),InfoValueNumeric), 
	SUBSTRING((CONVERT(CHAR(2), FolderCentury)+ FolderYear + ' ' + FolderSequence + ' ' + FolderSection + FolderRevision + ' ' + FolderType), 1, 20) AS ReferenceFile,
	F.FolderRSN
FROM Folder F
INNER JOIN PropertyInfo PRI ON F.PropertyRSN = PRI.PropertyRSN
INNER JOIN FolderInfo FI ON F.folderRSN = FI.FolderRSN
WHERE PRI.PropertyInfoCode = 500 AND PropInfoValue IS NOT NULL
	AND FI.InfoCode = 30006
	AND F.InDate >'12/31/2003'
	AND FolderType IN('BP', 'EP', 'MP', 'PP', 'SS', 'SU')
	AND F.FolderRSN NOT IN(SELECT Amount2 FROM AssessPro.dbo.DataBuildPermit WHERE Amount2 IS NOT NULL)
	AND F.StatusCode = 30002
ORDER BY F.FolderRSN

OPEN curUpdateAssessPro
FETCH curUpdateAssessPro INTO
	@Propinfovalue,
	@Issuedate,
	@Folderdescription,
	@FolderType,
	@EstCost,
	@ReferenceFile,
	@FolderRSN
WHILE @@FETCH_STATUS = 0

BEGIN
	SELECT @MaxRSN = ISNULL(MAX(SeqNumber), 1) + 1 FROM Assesspro.dbo.DataBuildPermit WHERE AccountNumber = @PropInfoValue

	INSERT INTO Assesspro.dbo.DataBuildPermit
	(AccountNumber, CardNumber, PermitDate, SeqNumber, Notes1, StatusCode,
	Description, Amount, PermitNumber, UpdtDate, Amount2)
	VALUES(@PropInfoValue, 1, @IssueDate, @MaxRSN, @FolderDescription, 'A',
	@FolderType, @EstCost, @ReferenceFile, GETDATE(), @FolderRSN)
	
		
FETCH curUpdateAssessPro INTO
	@Propinfovalue,
	@Issuedate,
	@Folderdescription,
	@FolderType,
	@EstCost,
	@ReferenceFile,
	@FolderRSN
END

CLOSE curUpdateAssessPro
DEALLOCATE curUpdateAssessPro
SET ANSI_WARNINGS ON

END


GO
