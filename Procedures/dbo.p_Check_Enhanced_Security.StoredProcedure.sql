USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_Check_Enhanced_Security]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure modified for AMANDA Browser Version for bilingual implementation */

CREATE PROCEDURE [dbo].[p_Check_Enhanced_Security] @argProcessRSN Int, @argUser VARCHAR(128) 
AS  
-- Amanda 44.28a: ESS Feb,17, 2010: Modified for bilingual implementation. The 'f_GetAmandaMessage' function has been implemented.   
/* 44.21 Subhash July 26, 2007: Rollback done before error is raised to avoid database lock */  
  
DECLARE @AssignedUser VARCHAR(128),  
        @ErrorMessage Varchar(2000)  
BEGIN  
      SELECT @AssignedUser = dbo.f_Check_Enhanced_Security(@argProcessRSN, @argUser)  
  
      IF @AssignedUser IS NOT NULL  
     BEGIN  
               SET @ErrorMessage = (SELECT dbo.f_GetAmandaMessage('PROCESS_NOT_TRUSTEDSYSTEM_USER', @AssignedUser, @argUser)) 
               ROLLBACK -- Subhash July 26, 2007  
               raiserror( @ErrorMessage,16,-1)  
     END   
END  

GO
