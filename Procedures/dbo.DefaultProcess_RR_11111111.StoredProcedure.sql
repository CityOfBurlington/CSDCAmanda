USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_RR_11111111]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_RR_11111111]
@ProcessRSN int, @FolderRSN int, @UserId char(8)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
-- Sangeet 2nd Aug 2004
-- to insert 'Code Owners', 'Emergency Contact' and 'property Managers 
-- from RR into the calling folder.

/*
SD
Modified 20050414 to get people from the most recent RB folder for property
*/

DECLARE @RRProperty int

SELECT @RRProperty = Folder.PropertyRSN
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

INSERT INTO FolderPeople (FolderRSN, PeopleRSN, PeopleCode, StampDate, StampUser)
SELECT distinct @FolderRSN, FolderPeople.PeopleRSN, FolderPeople.PeopleCode, getdate(), @UserId
FROM Folder
INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
WHERE Folder.FolderType = 'RB'
AND Folder.FolderRSN = (SELECT MAX(Folder.FolderRSN) FROM Folder WHERE FolderType = 'RB' AND Folder.PropertyRSN = @RRProperty)
AND FolderPeople.PeopleCode in (75, 80, 85, 322, 125)




GO
