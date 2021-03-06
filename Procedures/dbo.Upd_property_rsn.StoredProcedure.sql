USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_property_rsn]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Upd_property_rsn] 
AS
begin

DECLARE @propertylocation   varchar(255),
        @propertyrsn   int

DECLARE cu_updfolderrsn CURSOR FOR 
	SELECT  rtrim(ltrim(propertylocation)),propertyrsn
	FROM RR_Property_link

OPEN cu_updfolderrsn
FETCH cu_updfolderrsn INTO
	@propertylocation,
	@propertyrsn

WHILE @@FETCH_STATUS = 0

BEGIN
	UPDATE folder
	SET Propertyrsn = @propertyrsn
	WHERE rtrim(ltrim(propertylocation)) = @propertylocation
	and foldertype = 'RR'
	and propertyrsn is null
	
FETCH cu_updfolderrsn INTO
	@propertylocation,
	@propertyrsn

END

CLOSE   cu_updfolderrsn
DEALLOCATE   cu_updfolderrsn
END

GO
