USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_Check_Privileges]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Function P_Check_Privileges modified for displaying message correctly */

CREATE  PROCEDURE [dbo].[p_Check_Privileges]( @argFolderRSN INT, @argUser VARCHAR(128), @argIsInsert VARCHAR(1) = 'N')
AS

-- 44.28b: ESS 1st Feb 2011 Fixed Issue Id(20957)
-- 44.28:ESS :06th JAN 2010 : Code Refactored the function to get the Language Code.
-- 44.28: ESS Sep 01, 2009: Modified for Bilingual Implementation

DECLARE
    @authorization INT,
    @ErrorMessage  Varchar(4000)
    
BEGIN
    SELECT @authorization = dbo.f_Check_Privileges (@argFolderRSN, @argUser, @argIsInsert)
    

    IF @authorization > 0
          BEGIN
             IF @authorization = 4
                  BEGIN
		  	SET @ErrorMessage = dbo.f_GetAmandaMessage('FOLDERRSN_UNAUTHORIZED_DELUPD',(CONVERT(VARCHAR, @argFolderRSN) + '|' + @argUser),@argUser);
	             	RAISERROR(@errormessage ,16,-1) 
                  END
             ELSE IF @authorization = 12 
                  BEGIN
		  	SET @errormessage = dbo.f_GetAmandaMessage('FOLDERRSN_UNAUTHORIZED_DELUPD_ISSUEDFOLDER',(CONVERT(VARCHAR, @argFolderRSN) + '|' + @argUser),@argUser);
	             	RAISERROR(@errormessage ,16,-1)
                  END
             ELSE IF @authorization = 100 
                  BEGIN
		  	SET @errormessage = dbo.f_GetAmandaMessage('FOLDERRSN_UNAUTHORIZED_UPDATE_ISSUEDFOLDER',(CONVERT(VARCHAR, @argFolderRSN) + '|' + @argUser),@argUser);
	             	RAISERROR(@errormessage ,16,-1)
                  END

             ELSE IF @authorization = 13
                  BEGIN
		  	SET @errormessage = dbo.f_GetAmandaMessage('FOLDERRSN_UNAUTHORIZED_INSERT',(CONVERT(VARCHAR, @argFolderRSN) + '|' + @argUser),@argUser);
	             	RAISERROR(@errormessage ,16,-1)
                  END
             ELSE IF @authorization = 101 
                  BEGIN
		  	SET @errormessage = dbo.f_GetAmandaMessage('FOLDERRSN_ARCHIVED',(CONVERT(VARCHAR, @argFolderRSN) + '|' + @argUser),@argUser);
	             	RAISERROR(@errormessage ,16,-1)
                  END
             ELSE
                  BEGIN
		  	SET @errormessage = dbo.f_GetAmandaMessage('FOLDERRSN_UNAUTHORIZED_DELUPD_CLOSEDFOLDER',(CONVERT(VARCHAR, @argFolderRSN) + '|' + @argUser),@argUser);
	             	RAISERROR(@errormessage ,16,-1)
                  END
          END

END

GO
