USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[UpdateFolderSeq00]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.UpdateFolderSeq00    Script Date: 11/10/00 10:24:19 AM ******/
create procedure [dbo].[UpdateFolderSeq00] as 
DECLARE @c_Seq varchar(6)
DECLARE @n_Seq int
DECLARE @FolderRSN int 
DECLARE FolderSeq_Cursor CURSOR FOR 
	SELECT FolderRSN FROM Folder 
	WHERE FolderYear = '00'

begin tran
SELECT @n_Seq = 1

OPEN FolderSeq_Cursor 
FETCH FolderSeq_Cursor INTO @FolderRSN 
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @c_Seq = ltrim(str(@n_Seq))
	UPDATE Folder 
	SET FolderSequence = substring('100000', 1, 6 -
datalength(@c_Seq)) + @c_Seq 
	WHERE FolderRSN = @FolderRSN 

	SELECT @n_Seq = @n_Seq +1
	FETCH FolderSeq_Cursor INTO @FolderRSN 
END /* WHILE */
CLOSE FolderSeq_Cursor
DEALLOCATE FolderSeq_Cursor

commit tran

GO
