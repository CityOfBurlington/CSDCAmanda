USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZNShowCauseText1]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_ZNShowCauseText1](@intFolderRSN INT) RETURNS VARCHAR(1000)
AS
BEGIN
   DECLARE @FolderRSN int
   DECLARE @ComplaintType varchar(50)
   DECLARE @SCMemoText1 varchar(1000)

   SELECT @FolderRSN = Folder.FolderRSN, 
          @ComplaintType = dbo.f_info_alpha(Folder.FolderRSN, 20048)
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @ComplaintType = 'Parking' 
   BEGIN
      SELECT @SCMemoText1 = 'Removing the violation (see attached photo indicating location of alleged violation), installing  barriers around the parking area recognized by the City to be reviewed and approved by this office, and re-seed any damaged lawn areas (including greenbelts)'
   END
   ELSE
   BEGIN
      SELECT @SCMemoText1 = 'Removing the violation, restoring the Premises to its prior state and informing this office that the violation has been removed so our office may verify compliance'
   END
   RETURN @SCMemoText1
END

GO
