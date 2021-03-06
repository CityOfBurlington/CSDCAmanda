USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZConStartDateLong]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetZConStartDateLong](@intFolderRSN int) RETURNS varchar(30)
AS
BEGIN
   DECLARE @DateValue datetime
   DECLARE @strDateLong varchar(30)
   SET @strDateLong = ' '

   SELECT @DateValue = DATEADD(year, -1, FolderInfo.InfoValueDateTime)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 10024

   SELECT @strDateLong = RTRIM(DATENAME(MONTH, @DateValue) + ' ' + DATENAME(DAY, @DateValue) + ', ' + DATENAME(YEAR, @DateValue))

   RETURN @strDateLong
END

GO
