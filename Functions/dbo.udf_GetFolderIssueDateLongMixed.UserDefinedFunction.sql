USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderIssueDateLongMixed]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderIssueDateLongMixed](@intFolderRSN int) 
RETURNS VARCHAR(30)
AS
BEGIN
   DECLARE @dtIssueDate datetime
   DECLARE @varDateLong varchar(30)

   SELECT @dtIssueDate = Folder.IssueDate
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @varDateLong = RTRIM(
   DATENAME(month, @dtIssueDate) + ' ' + 
   DATENAME(day,   @dtIssueDate) + ', ' + 
   DATENAME(year,  @dtIssueDate))
   RETURN @varDateLong
END

GO
