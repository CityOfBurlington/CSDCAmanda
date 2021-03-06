USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[sp_pbtable]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.sp_pbtable    Script Date: 11/10/00 10:24:18 AM ******/
/****** Object:  Stored Procedure dbo.sp_pbtable    Script Date: 11/18/1997 3:06:38 PM ******/
/*
**  2 - PB stored procedure that retrieves table info
**     from the catalog
*/

create procedure [dbo].[sp_pbtable]
	  @tblname varchar(60) = NULL as
	  declare @objid int

	  if @tblname = null
		select name, id, type, uid, user_name(uid) from sysobjects where
		   (type = 'S' or type = 'U' or type = 'V')
	  else
		begin
		  select @objid = object_id(@tblname)
		  select name, id, type, uid, user_name(uid) from sysobjects
			 where id = @objid
		end
	  return



GO
