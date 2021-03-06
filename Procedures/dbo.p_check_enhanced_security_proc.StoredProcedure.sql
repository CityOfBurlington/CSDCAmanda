USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_check_enhanced_security_proc]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure modified for AMANDA Browser Version for bilingual implementation */

CREATE PROCEDURE [dbo].[p_check_enhanced_security_proc] @argProcessRSN INT, @argAssignedUser VARCHAR(128), @argUser VARCHAR(128)  
AS  
  
DECLARE  
        @v_AssignedUser VARCHAR(128),  
        @ErrorMessage  VARCHAR(4000)   
           
BEGIN  
   -- Amanda 44.28a: ESS Feb,17, 2010: Modified for bilingual implementation. The 'f_GetAmandaMessage' function has been implemented. 
   /* 44.21 Subhash July 26, 2007: Rollback done before error is raised to avoid database lock */
	/** 21-Aug-2009: ESS- Modified for Bilingual Implementation*/
	/* ESS: 09-Feb-2010 - Code Refactored to support the changes made in f_GetAmandaMessage.*/
	SELECT @v_AssignedUser = dbo.f_check_enhanced_security_proc (@argProcessRSN, @argAssignedUser, @argUser)  
  
	IF @v_AssignedUser IS NOT NULL  
		BEGIN  
		     SET @ErrorMessage = ( SELECT dbo.f_getAmandaMessage('PROCESS_NOT_TRUSTEDUSER',@v_AssignedUser,@argUser) )
		     ROLLBACK -- Subhash July 26, 2007  
		     RAISERROR ( @ErrorMessage,16,-1)  
		END  
END  

GO
