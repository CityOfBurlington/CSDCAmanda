USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_Check_Privileges_Folder]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure modified to handle error message to support Bilingual implemetation */

CREATE PROCEDURE [dbo].[p_Check_Privileges_Folder]
	(
		@argFolderRSN	INT, 
		@argStatusCode	INT, 
		@argFolderType	VARCHAR(4), 
		@argUser		VARCHAR(128), 
		@argIsInsert	VARCHAR(1) = 'N'
	)  
AS  
DECLARE  
        @authorization	INT,  
        @errormessage	VARCHAR(4000)  
BEGIN  
      /** Amanda 44.28: 21-Aug-2009: ESS- Modified for Bilingual Implementation*/
      /* ESS: 09-Feb-2010 - Code Refactored to support the changes made in f_GetAmandaMessage.*/
      
      SELECT @authorization = dbo.f_Check_Privileges_Folder (@argFolderRSN, @argStatusCode, @argFolderType, @argUser, @argIsInsert)  
		IF @authorization > 0  
		BEGIN  
			IF @authorization = 4   
			BEGIN            
				SET @errormessage = ( SELECT dbo.f_getAmandaMessage('F_CHECKPREV_UNAUTHORIZED_DELUPD',(@argFolderType + '|' + @argUser),@argUser) )
				RAISERROR(@errormessage ,16,-1)  
			END  
			ELSE IF @authorization = 12   
			BEGIN               
				SET @errormessage = ( SELECT dbo.f_getAmandaMessage('F_CHECKPREV_UNAUTHORIZED_DELUPD_ISSUEDFOLDER',(@argFolderType + '|' + @argUser),@argUser) )
				RAISERROR(@errormessage ,16,-1)  
			END  
			ELSE IF @authorization = 100   
			BEGIN  
				SET @errormessage = ( SELECT dbo.f_getAmandaMessage('F_CHECKPREV_UNAUTHORIZED_UPDATE_ISSUEDFOLDER',(@argFolderType + '|' + @argUser),@argUser) )
				RAISERROR(@errormessage ,16,-1)  
			END  
			ELSE IF @authorization = 13   
			BEGIN  
				SET @errormessage = ( SELECT dbo.f_getAmandaMessage('F_CHECKPREV_UNAUTHORIZED_INSERT',(@argFolderType + '|' + @argUser),@argUser) )
				RAISERROR(@errormessage ,16,-1)  
			END  
			ELSE IF @authorization = 101   
            BEGIN  
				SET @errormessage = ( SELECT dbo.f_getAmandaMessage('F_CHECKPREV_ARCHIEVED',(@argFolderType + '|' + @argUser),@argUser) )
				RAISERROR(@errormessage ,16,-1)  
            END  
			ELSE  
            BEGIN  
				SET @errormessage = ( SELECT dbo.f_getAmandaMessage('F_CHECKPREV_UNAUTHORIZED_DELUPD_CLOSEDFOLDER',(@argFolderType + '|' + @argUser),@argUser) )
				RAISERROR(@errormessage ,16,-1)  
            END  
		END  
  
END  

GO
