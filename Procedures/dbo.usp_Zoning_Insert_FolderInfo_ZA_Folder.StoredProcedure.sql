USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_FolderInfo_ZA_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_FolderInfo_ZA_Folder] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
   /* Adds Sign and Awning related Info fields (ZA Folder). 
      Called by Folder Initialize (DefaultFee_ZB_Folder), and Review Path 
     (DefaultProcess_ZB_00010000). The Awning Lettering Y/N Info field (10064) 
      is redundant with WorkCode 10037, and is discontinued 8/20/2010. */

   DECLARE @varFolderType varchar(4)
   DECLARE @intWorkCode int
   DECLARE @SignNumberNMPOrder int
   DECLARE @SignNumberNMPInfoField int
   DECLARE @SignNumberMPOrder int
   DECLARE @SignNumberMPInfoField int
   DECLARE @SignTypeOrder int
   DECLARE @SignTypeInfoField int
   DECLARE @SignMaterialsOrder int
   DECLARE @SignMaterialsInfoField int
   DECLARE @AwningNumberOrder int
   DECLARE @AwningNumberInfoField int
   DECLARE @AwningMaterialsOrder int
   DECLARE @AwningMaterialsInfoField int
   DECLARE @IlluminationOrder int
   DECLARE @IlluminationInfoField int 

   SELECT @varFolderType = Folder.FolderType, @intWorkCode = Folder.WorkCode
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @SignNumberNMPOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10044)
   SELECT @SignNumberNMPInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10044)

   SELECT @SignNumberMPOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10129)
   SELECT @SignNumberMPInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10129)

   SELECT @SignTypeOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10062)
   SELECT @SignTypeInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10062)

   SELECT @SignMaterialsOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10063)
   SELECT @SignMaterialsInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10063)

   SELECT @AwningNumberOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10045)
   SELECT @AwningNumberInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10045)

   SELECT @AwningMaterialsOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10065)
   SELECT @AwningMaterialsInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10065) 

   SELECT @IlluminationOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10041)
   SELECT @IlluminationInfoField = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10041)

   IF @IlluminationInfoField = 0     /* For both Sign(s) and Awning(s) */
   BEGIN 
      INSERT INTO FolderInfo 
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @intFolderRSN, 10041, @IlluminationOrder, 'Y', 
                  getdate(), @varUserID, 'N', 'N' ) 
   END

   IF @intWorkCode = 10035      /* Sign(s) */
   BEGIN
      IF @SignNumberNMPInfoField = 0 
      BEGIN
         INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     StampDate, StampUser, Mandatory, ValueRequired )
            VALUES ( @intFolderRSN, 10044,  @SignNumberNMPOrder, 'Y', 
                     getdate(), @varUserID, 'N', 'Y' )
      END

      IF @SignNumberMPInfoField = 0 
      BEGIN
         INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     StampDate, StampUser, Mandatory, ValueRequired )
            VALUES ( @intFolderRSN, 10129,  @SignNumberMPOrder, 'Y', 
                     getdate(), @varUserID, 'N', 'Y' )
      END
      IF @SignTypeInfoField = 0 
      BEGIN
        INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     StampDate, StampUser, Mandatory, ValueRequired )
               VALUES ( @intFolderRSN, 10062,  @SignTypeOrder, 'Y', 
                  getdate(), @varUserID, 'N', 'N' )
      END
      IF @SignMaterialsInfoField = 0 
      BEGIN
         INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     StampDate, StampUser, Mandatory, ValueRequired )
            VALUES ( @intFolderRSN, 10063,  @SignMaterialsOrder, 'Y', 
                     getdate(), @varUserID, 'N', 'N' )
      END
   END

   IF @intWorkCode IN (10036, 10037)     /* Awning(s) */
   BEGIN
      IF @AwningNumberInfoField = 0 
      BEGIN
         INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     StampDate, StampUser, Mandatory, ValueRequired )
            VALUES ( @intFolderRSN, 10045, @AwningNumberOrder, 'Y', 
                     getdate(), @varUserID, 'N', 'Y' )
      END
      IF @AwningMaterialsInfoField = 0 
      BEGIN
         INSERT INTO FolderInfo
                   ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                     StampDate, StampUser, Mandatory, ValueRequired )
            VALUES ( @intFolderRSN, 10065,  @AwningMaterialsOrder, 'Y', 
                     getdate(), @varUserID, 'N', 'N' )
      END
   END
END

GO
