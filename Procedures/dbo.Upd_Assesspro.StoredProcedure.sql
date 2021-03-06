USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_Assesspro]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Upd_Assesspro]
AS
begin

DECLARE @Propinfovalue varchar(100),
	@Issuedate   varchar(100),
	@Folderdescription   varchar(8000),
	@foldertype	varchar(10),
	@InfovalueNumeric	varchar(100),
	@referencefile	varchar(100),
	@FoldRSN varchar(100),
@MaxRSN  int
DECLARE cu_updassesspro CURSOR FOR
select Propinfovalue, isnull(Issuedate,indate),Folderdescription,foldertype,
 InfovalueNumeric,referencefile,F.FolderRSN
from Folder F, Propertyinfo PRI, Folderinfo FI
where F.folderrsn = FI.Folderrsn
and F.Propertyrsn = PRI.Propertyrsn
and PRI.PropertyInfoCode = 500
and FI.Infocode = 10000
and F.Indate >'12/31/2003'
and Foldertype in ('Z1','Z2','Z3','ZB','ZA','ZF','ZC','ZH','ZD')
and F.Folderrsn not in(select amount2 from assesspro.dbo.databuildpermit where amount2 is not null)
and F.StatusCode = 10006
order by F.Folderrsn

OPEN cu_updassesspro
FETCH cu_updassesspro INTO
	@Propinfovalue,
	@Issuedate,
	@Folderdescription,
	@foldertype,
	@InfovalueNumeric,
	@referencefile,
	@FoldRSN
WHILE @@FETCH_STATUS = 0

BEGIN
	SELECT @MaxRSN = isnull(max(seqnumber),1)+1 FROM assesspro.dbo.databuildpermit
	
	INSERT INTO assesspro.dbo.databuildpermit(aCCOUNTNUMBER,CARDnumber,permitdate,seqnumber,notes1,statuscode,
	description,amount,permitnumber,updtdate,amount2)
	VALUES(@Propinfovalue,1,@Issuedate,@MaxRSN,substring(@Folderdescription,1,255),'A',
	@foldertype,@InfovalueNumeric,@referencefile,getdate(),@FoldRSN)
	
		
FETCH cu_updassesspro INTO
	@Propinfovalue,
	@Issuedate,
	@Folderdescription,
	@foldertype,
	@InfovalueNumeric,
	@referencefile,
	@FoldRSN
END

CLOSE   cu_updassesspro
DEALLOCATE   cu_updassesspro
END

GO
