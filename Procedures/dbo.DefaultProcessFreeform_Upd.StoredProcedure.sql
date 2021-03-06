USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcessFreeform_Upd]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure DefaultProcessFreeform_Upd created to update ProcessComment to 'FolderProcessFreeform: DefaultProcessFreeform_UPD.' */

CREATE PROCEDURE [dbo].[DefaultProcessFreeform_Upd]  @argProcessRSN INT, @argTabOrder INT, @argFreeformCode INT,@DUserId VARCHAR(128) 
AS

/* 44.28b: ESS: 24/06/2010 :Added for Multiple tabs Process Customization Enhancement */

BEGIN 
Update FolderProcess 
Set ProcessComment = 'FolderProcessFreeform: DefaultProcessFreeform_UPD.' 
where FolderProcess.ProcessRSN = @argProcessRSN;
END

GO
