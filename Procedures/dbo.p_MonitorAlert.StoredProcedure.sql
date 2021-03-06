USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_MonitorAlert]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- New alert will be inserted to MonitorAlert table and we can get the inserted MonitorAlertRSN by out parameter MonitorAlertRSN 

CREATE PROCEDURE [dbo].[p_MonitorAlert] @argPriorityCode INT, @argAlertDesc VARCHAR(128), @argAlertText VARCHAR(4000), @argColor VARCHAR(32), @argDrillDown VARCHAR(128), @argDrillDownParameters VARCHAR(4000), @MonitorAlertRSN INT OUTPUT
AS
BEGIN
	exec RsnSetLock
	SELECT @MonitorAlertRSN = ISNULL(MAX(MonitorAlertRSN),0) FROM MonitorAlert
	SET @MonitorAlertRSN = @MonitorAlertRSN + 1

	INSERT INTO MONITORALERT (MonitorAlertRSN, PriorityCode, AlertDesc, AlertText,
		Color, DrillDown, DrillDownParameters, AlertDate, StampDate, StampUser)
	VALUES (@MonitorAlertRSN, @argPriorityCode, @argAlertDesc, @argAlertText,
		@argColor, @argDrillDown, @argDrillDownParameters, GETDATE(), GETDATE(), System_User);
END

GO
