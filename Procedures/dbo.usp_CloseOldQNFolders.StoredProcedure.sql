USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CloseOldQNFolders]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================
-- Author:		Dana Baron
-- Create date: 21-April-2011
-- Description:	This stored procedure runs as an automatic job from //intranet.
--				It finds all QN folders with InDate more than 730 days ago and
--				changes the status to Closed (2).
-- ===============================================================================

CREATE PROCEDURE [dbo].[usp_CloseOldQNFolders] AS
BEGIN

	UPDATE Folder SET StatusCode = 2 
	WHERE Folder.FolderType = 'QN' AND DATEDIFF(day, InDate, GETDATE()) > 730 AND StatusCode <> 2

END





GO
