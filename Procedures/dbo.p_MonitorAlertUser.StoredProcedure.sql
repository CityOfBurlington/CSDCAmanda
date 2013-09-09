USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_MonitorAlertUser]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[p_MonitorAlertUser]
	@MonitorAlertRSN int, @UserId varchar(128)
AS
BEGIN
	INSERT INTO MonitorAlertUser(MonitorAlertRSN, UserId, SnoozeDate, StampDate, StampUser) 
	Values (@MonitorAlertRSN, @UserId, GETDATE(), GETDATE(), @UserId)
END

GO
