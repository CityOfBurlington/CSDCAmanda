USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[gettablesize2]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[gettablesize2] as
Begin
Select 
obj.name,(Select Sum(((used * 8192.00)/1024)) from sysindexes
where id in (select objChild.id from sysobjects objChild where objChild.name = obj.name)
and indid in(0,1) --> Only Table Size
) TableSizeKb,
(Select Sum(((used * 8192.00)/1024))from sysindexes
where id in (select objChild.id from sysobjects objChild where objChild.name = obj.name)
and indid = 255 --> Only Text and Image
) TextImageSizeKb,
(Select Sum(((used * 8192.00)/1024))from sysindexes
where id in (select objChild.id from sysobjects objChild where objChild.name = obj.name)
and indid not in (255,0,1) --> Only indexes
) IndexSizeKb
From sysobjects obj
Where type = 'U' --> only user tables
Order By TableSizeKb desc
End 


GO
