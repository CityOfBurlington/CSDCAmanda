USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_FolderProcessInfo_Date_Add_Time]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_FolderProcessInfo_Date_Add_Time] (@intProcessRSN int, @intInfoCode int)
AS
BEGIN 

   UPDATE FolderProcessInfo
      SET FolderProcessInfo.InfoValueDateTime = DATEADD(hour, datepart(hour, getdate()), FolderProcessInfo.InfoValueDateTime)
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN
      AND FolderProcessInfo.InfoCode = @intInfoCode

   UPDATE FolderProcessInfo
      SET FolderProcessInfo.InfoValueDateTime = DATEADD(minute, datepart(minute, getdate()), FolderProcessInfo.InfoValueDateTime)
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN
      AND FolderProcessInfo.InfoCode = @intInfoCode

END

GO
