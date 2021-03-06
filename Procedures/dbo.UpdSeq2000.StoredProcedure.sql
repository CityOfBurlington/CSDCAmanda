USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[UpdSeq2000]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.UpdSeq2000    Script Date: 11/10/00 10:24:19 AM ******/
CREATE Procedure [dbo].[UpdSeq2000] as
DECLARE @n_Min   int
DECLARE @n_Max   int
DECLARE @n_Seq   int
DECLARE @c_Seq   varchar(6)
DECLARE @n_fcount   int
DECLARE @n_count   int


Begin Tran
SELECT @n_Min = Min(FolderRSN) from Folder where FolderYear = '00'
SELECT @n_Max = Max(FolderRSN) from Folder where FolderYear = '00'
SELECT @n_Seq = 1
SELECT  @n_fCount = @n_min

While  @n_fCount <= @n_Max 
Begin
Select  @n_count = Count(*) from Folder where 
FolderRSN = @n_fcount
If @n_count > 0 
BEGIN
	SELECT @c_Seq = ltrim(str(@n_Seq))
	UPDATE Folder  SET FolderSequence = substring('000000', 1, 6 - datalength(@c_Seq)) + @c_Seq 
	WHERE FolderRSN = @n_fCount
	SELECT @n_Seq = @n_Seq + 1
	SELECT @n_fCount = @n_fCount + 1
	SELECT @n_count  = 0
END
ELSE
Begin
SELECT @n_Seq = @n_Seq + 1
SELECT @n_fCount = @n_fCount + 1
SELECT @n_count  = 0
End
END
Commit Tran










GO
