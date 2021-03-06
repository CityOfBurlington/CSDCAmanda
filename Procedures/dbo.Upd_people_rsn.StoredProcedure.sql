USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_people_rsn]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Upd_people_rsn] 
AS
begin

DECLARE @folderrsn   int,
	@peoplersn   int,
	@peoplecode   int,
        @MaxRSN int

DECLARE cu_updfolderrsn CURSOR FOR

select f.folderrsn,peoplersn,peoplecode 
from RR_People_link r,folder f where 
f.folderrsn not in (select Folderrsn from RR_People_link)
and f.propertylocation = r.propertylocation
order by f.propertylocation


OPEN cu_updfolderrsn
FETCH cu_updfolderrsn INTO
	@folderrsn,
	@peoplersn,
	@peoplecode

WHILE @@FETCH_STATUS = 0

BEGIN
	INSERT INTO FolderPeople (FolderRSN,PeopleRSN,PeopleCode,PrintFlag,StampUser,StampDate)
			VALUES (@folderrsn,@peoplersn,@peoplecode,'Y','DATACONV','06-27-2003')
	
FETCH cu_updfolderrsn INTO
	@folderrsn,
	@peoplersn,
	@peoplecode

END

CLOSE   cu_updfolderrsn
DEALLOCATE   cu_updfolderrsn
END

GO
