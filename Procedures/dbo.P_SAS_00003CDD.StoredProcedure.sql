USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_SAS_00003CDD]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[P_SAS_00003CDD] AS
/* Procedure Altered Dated : 2001.05.01 */
BEGIN
Insert into Property_SAS_DD Select * from X_DD (index=XDDPrimKey) 
END

GO
