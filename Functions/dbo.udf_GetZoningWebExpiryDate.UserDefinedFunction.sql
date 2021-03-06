USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningWebExpiryDate]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningWebExpiryDate](@intFolderRSN INT) 
RETURNS VARCHAR(12)
AS
BEGIN
   /* Uses Folder Status to determine what should be returned for 
      Folder.ExpiryDate zoning permit status reports on the web site. */

   DECLARE @intStatusCode int
   DECLARE @varFolderType varchar(2)
   DECLARE @dtExpiryDate datetime
   DECLARE @varWebDate varchar(12)

   SELECT @intStatusCode = Folder.StatusCode,
          @varFolderType = Folder.FolderType, 
          @dtExpiryDate = Folder.ExpiryDate
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN
 
   IF @intStatusCode IN(10009, 10017, 10020, 10021, 10036, 10046)  /* Permit under appeal */
        SELECT @varWebDate = 'TBD'
   ELSE SELECT @varWebDate = ISNULL(CONVERT(CHAR(11), @dtExpiryDate), 'TBD')  

   RETURN @varWebDate
END

GO
