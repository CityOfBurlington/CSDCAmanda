USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReOpenProcess]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ReOpenProcess](@ProcessRSN INT)
AS
BEGIN
    UPDATE FolderProcess
    SET StatusCode = 1, 
    SignOffUser = Null, 
    EndDate = Null
    WHERE ProcessRSN = @ProcessRSN
END
GO
