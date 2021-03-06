USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_proppeople_rsn]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[Upd_proppeople_rsn] 
AS
begin

DECLARE @propertyrsn int,
	@peoplersn   int,
	@startdate   varchar(100)

DECLARE cu_updpeoplersn CURSOR FOR
select propertyrsn,peoplersn,startdate from propertypeople
where peoplecode = 200
and startdate is not null

OPEN cu_updpeoplersn
FETCH cu_updpeoplersn INTO
	@propertyrsn,
	@peoplersn,
	@startdate
	
WHILE @@FETCH_STATUS = 0

BEGIN
	
	UPDATE PropertyPeople set startdate = @startdate
	WHERE PropertyRSN = @propertyrsn
	AND peoplersn = @peoplersn
	AND peoplecode = 2 
	
FETCH cu_updpeoplersn INTO
	@propertyrsn,
	@peoplersn,
	@startdate
END

CLOSE   cu_updpeoplersn
DEALLOCATE   cu_updpeoplersn
END

GO
