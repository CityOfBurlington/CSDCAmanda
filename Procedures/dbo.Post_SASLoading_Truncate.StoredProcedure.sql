USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Post_SASLoading_Truncate]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[Post_SASLoading_Truncate] AS
/* Procedure Altered Dated : 2001.05.01 */
truncate table X_Property
truncate table x_aa
truncate table x_bb
truncate table x_cc
truncate table x_dd
truncate table x_gg
truncate table x_hh
truncate table x_jj
truncate table x_kk
truncate table x_ll
truncate table x_mm
truncate table x_pa
truncate table x_pb
truncate table x_pc
truncate table x_pd
truncate table  X_SAS_Property
truncate table  X_SAS_StreetType
truncate table  X_SAS_StreetDirection

GO
