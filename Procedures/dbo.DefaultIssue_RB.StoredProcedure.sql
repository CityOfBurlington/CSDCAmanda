USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_RB]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_RB]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
COMMIT TRANSACTION
BEGIN TRANSACTION

DECLARE @intCOMReturnValue INT
EXEC @intCOMReturnValue = xspGenerateRBPacketAndAttachToFolder @FolderRSN

IF @intCOMReturnValue = 1
   BEGIN
        COMMIT TRANSACTION
        BEGIN TRANSACTION

        DECLARE @PeopleRSN VARCHAR(30)
        DECLARE @strMessage VARCHAR(200)

        SET @strMessage = 'Past Due Bill Generated: W:\Docs\RB2007\PastDue_' + @PeopleRSN + '.pdf'

        SELECT @PeopleRSN = ReferenceFile FROM Folder WHERE FolderRSN = @FolderRSN

        EXEC usp_UpdateFolderCondition @FolderRSN, @strMessage

   END


IF @intCOMReturnValue = 2
   BEGIN
      RAISERROR('Failed to Create RB Packet (Crystal Crash Error: 2)', 16, -1)
   END

IF @intCOMReturnValue = 3
   BEGIN
      RAISERROR('Non-numeric Reference File Number (Error: 3)', 16, -1)
   END

IF @intCOMReturnValue = 4
   BEGIN
      RAISERROR('Generic Packet Failure, Check \\Patriot\c$\Temp for File (SQL Crash Error: 4)', 16, -1)
   END

IF @intCOMReturnValue = 5
   BEGIN
      RAISERROR('Failed to Attach RB Packet to Folder, Check \\Patriot\c$\Temp for File (SQL Crash Error: 5)', 16, -1)
   END

IF @intCOMReturnValue = 6
   BEGIN
      RAISERROR('Failed to Attach RB Packet to Folder (SQL Crash Error: 6)', 16, -1)
   END

IF @intCOMReturnValue = 8
   BEGIN
      RAISERROR('Failed to Create RB Folder for Folder Year (FSO Crash Error: 8)', 16, -1)
   END
GO
