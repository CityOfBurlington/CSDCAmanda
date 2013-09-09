USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[RsnSetLock]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Modified to better handle the database locking */

CREATE PROCEDURE [dbo].[RsnSetLock] AS
   UPDATE z_RsnLock  WITH (TabLockX, HoldLock) SET Spid = @@spid
   DECLARE @spid int
   SELECT @spid = Spid FROM z_RsnLock WITH (TabLockX, HoldLock)
   

GO
