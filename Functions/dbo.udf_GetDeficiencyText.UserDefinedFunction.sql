USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDeficiencyText]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetDeficiencyText](@ProcessRSN INT) RETURNS VARCHAR(2000)
AS
BEGIN
	DECLARE @DefText VARCHAR(500)
	DECLARE @RetVal VARCHAR(2000)
	DECLARE @i INT

	SET @i = 0

	DECLARE curDeficienies CURSOR FOR 
	SELECT FolderProcessDeficiency.DeficiencyText
	FROM FolderProcessDeficiency
	WHERE FolderProcessDeficiency.ProcessRSN = @ProcessRSN

	OPEN curDeficienies

	FETCH NEXT FROM curDeficienies INTO @DefText

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @i = @i + 1
		SET @RetVal = ISNULL(@RetVal, '') + '» ' + @DefText + CHAR(10)
		FETCH NEXT FROM curDeficienies INTO @DefText
	END

	CLOSE curDeficienies
	DEALLOCATE curDeficienies

	SET @RetVal = SUBSTRING(@RetVal, 1, LEN(@RetVal) - 1)

	RETURN @RetVal
END


GO
