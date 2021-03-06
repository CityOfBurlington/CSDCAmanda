USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFolderFreeform_Upd]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure DefaultFolderFreeform_Upd created to update FolderDescription to 'FolderFreeform: DefaultFolderFreeform_UPD.' */

CREATE PROCEDURE [dbo].[DefaultFolderFreeform_Upd] @argFolderRSN INT, @argTabOrder INT, @argFreeformCode INT, @DUserId VARCHAR(128)
AS

/* 44.28b: ESS: 24/06/2010 :Added for Multiple tabs Folder Customization Enhancement */

BEGIN 
Update Folder 
Set FolderDescription = 'FolderFreeform: DefaultFolderFreeform_UPD.' 
where Folder.FolderRSN = @argFolderRSN; 
END

GO
