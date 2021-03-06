USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZNShowCauseText2]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_ZNShowCauseText2](@intFolderRSN INT) RETURNS VARCHAR(1000)
AS
BEGIN
   DECLARE @FolderRSN int
   DECLARE @ComplaintType varchar(50)
   DECLARE @SCMemoText2 varchar(1000)

   SELECT @FolderRSN = Folder.FolderRSN, 
          @ComplaintType = dbo.f_info_alpha(Folder.FolderRSN, 20048)
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @ComplaintType = 'Parking' 
   BEGIN
      SELECT @SCMemoText2 = 'Submitting a complete application to the Burlington Department of Planning and Zoning (located in City Hall) to cure the alleged violation. If the application or the portion of the application that deals with the alleged violation is Denied, you have Ten (10) Calendar Days from the application denial date to remove the violation and comply with number 1 above.'
   END
   ELSE
   BEGIN
      SELECT @SCMemoText2 = 'Submitting a complete application to the Burlington Department of Planning and Zoning (located in City Hall) to cure the alleged violation. If the application or the portion of the application that deals with the alleged violation is Denied, you have Ten (10) Calendar Days from the application denial date to remove the alleged violation and restore the Premises to its prior state.'
   END
   RETURN @SCMemoText2
END

GO
