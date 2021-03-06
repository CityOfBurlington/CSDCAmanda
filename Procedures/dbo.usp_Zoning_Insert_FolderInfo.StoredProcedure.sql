USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_FolderInfo]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_FolderInfo] (@intFolderRSN int, @intInfoCode int, @varUserID varchar(20))
AS
BEGIN 
   DECLARE @intInfoFieldExists int 
   DECLARE @intDisplayOrder int 

   SELECT @intInfoFieldExists = dbo.udf_FolderInfoFieldExists(@intFolderRSN, @intInfoCode) 
   SELECT @intDisplayOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, @intInfoCode) 

   IF @intInfoFieldExists = 0 
   BEGIN 
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, 
                  PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @intFolderRSN, @intInfoCode,  @intDisplayOrder, 
                  'Y', getdate(), @varUserID, 'N', 'N' ) 
   END 
END


GO
