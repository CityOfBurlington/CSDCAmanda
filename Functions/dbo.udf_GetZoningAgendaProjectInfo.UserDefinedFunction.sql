USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaProjectInfo]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaProjectInfo](@intAgendaFolderRSN INT, @intApplicationFolderRSN INT) 
RETURNS varchar(400)
AS 
BEGIN
   /* Creates first line of a zoning agenda item for Infomaker meeting_agenda */

   DECLARE @varAgendaItemOrder varchar(3)
   DECLARE @varProjectNumber varchar(15)
   DECLARE @varPropertyAddress varchar(100)
   DECLARE @varZoningDistrict varchar(10)
   DECLARE @varWard varchar(10)
   DECLARE @varPropertyOwner varchar(100)
   DECLARE @varProjectInfo varchar(400)

   IF @intAgendaFolderRSN <> @intApplicationFolderRSN 
   BEGIN
      SELECT @varAgendaItemOrder = CAST(ISNULL(FolderInfo.DisplayOrder, 0) AS VARCHAR)
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intAgendaFolderRSN 
         AND FolderInfo.InfoValueNumeric = @intApplicationFolderRSN 

      SELECT @varProjectNumber = Folder.ReferenceFile 
        FROM Folder 
       WHERE Folder.FolderRSN = @intApplicationFolderRSN

      SELECT @varPropertyAddress = dbo.udf_GetPropertyAddressLong(@intApplicationFolderRSN)

      SELECT @varZoningDistrict = dbo.f_info_alpha(@intApplicationFolderRSN, 10002) 

      SELECT @varWard = 'Ward ' + CAST(dbo.f_info_numeric(@intApplicationFolderRSN, 10067) AS VARCHAR)

      SELECT @varPropertyOwner = dbo.udf_GetFirstOwner(@intApplicationFolderRSN) 

      SELECT @varProjectInfo = @varAgendaItemOrder        + '. ' +
                               RTRIM(@varProjectNumber)   + ': '  + 
                               RTRIM(@varPropertyAddress) + ' (' + 
                               RTRIM(@varZoningDistrict)  + ', '  +
                               RTRIM(@varWard)            + ') '  + 
                               RTRIM(@varPropertyOwner) 
   END

   RETURN ISNULL(@varProjectInfo, ' ')
END

GO
