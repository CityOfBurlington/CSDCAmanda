USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOAdministratorForm]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOAdministratorForm](@intFolderRSN int)
RETURNS VARCHAR(60)
AS
BEGIN
   /* Used by UCO mailmerge forms. Set ValidUser.UserID to be the person in charge 
      of processing UCO's. FolderRSN is intentionally not used. */

   DECLARE @varUCOUser varchar(60)

   SET @varUCOUser = ' '

   SELECT @varUCOUser = ValidUser.UserName + ', ' + ValidUser.UserTitle 
     FROM ValidUser
    WHERE ValidUser.UserID = 'COrton' 

   RETURN @varUCOUser
END
GO
