USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[xspLogEvent]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[xspLogEvent](@EventNumber INT, @Message VARCHAR(100)) AS
BEGIN
EXEC master.dbo.xp_logevent @EventNumber, @Message, informational
END

GO
