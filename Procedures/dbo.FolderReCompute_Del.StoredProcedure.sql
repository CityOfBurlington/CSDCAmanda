USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[FolderReCompute_Del]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



/* Deletes the record from Folder computed table when ever a Folder is being deleted */

CREATE PROCEDURE [dbo].[FolderReCompute_Del]
	@argFolderRSN INT
AS
DECLARE @theCount NUMERIC(10)
BEGIN
   SELECT @theCount =COUNT(*) FROM FolderComputed WHERE FolderRSN = @argFolderRSN;
   IF @theCount > 0 
	 BEGIN
       DELETE FROM FolderComputed WHERE FolderRSN = @argFolderRSN;
    END;
END

GO
