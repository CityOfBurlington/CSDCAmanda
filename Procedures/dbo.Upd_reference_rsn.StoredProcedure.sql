USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_reference_rsn]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Upd_reference_rsn] 
AS
begin

DECLARE @propertylocation   varchar(255),
        @referencefile   int

DECLARE cu_updfolderrsn CURSOR FOR 
	SELECT  rtrim(ltrim(propertylocation)),referencefile
	FROM RR_reference_link

OPEN cu_updfolderrsn
FETCH cu_updfolderrsn INTO
	@propertylocation,
	@referencefile

WHILE @@FETCH_STATUS = 0

BEGIN
	UPDATE folder
	SET referencefile = @referencefile
	WHERE rtrim(ltrim(propertylocation)) = @propertylocation
	and foldertype = 'RR'
	and referencefile is null
	
FETCH cu_updfolderrsn INTO
	@propertylocation,
	@referencefile
END

CLOSE   cu_updfolderrsn
DEALLOCATE   cu_updfolderrsn
END

GO
