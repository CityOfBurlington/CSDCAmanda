USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyInfo_DisplayOrder_Recode]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_PropertyInfo_DisplayOrder_Recode]
AS
BEGIN 
UPDATE PropertyInfo SET DisplayOrder = 102, StampDate = getdate() WHERE PropertyInfoCode = 140
UPDATE PropertyInfo SET DisplayOrder = 202, StampDate = getdate() WHERE PropertyInfoCode = 150
UPDATE PropertyInfo SET DisplayOrder = 302, StampDate = getdate() WHERE PropertyInfoCode = 80
UPDATE PropertyInfo SET DisplayOrder = 304, StampDate = getdate() WHERE PropertyInfoCode = 87
UPDATE PropertyInfo SET DisplayOrder = 306, StampDate = getdate() WHERE PropertyInfoCode = 88
UPDATE PropertyInfo SET DisplayOrder = 308, StampDate = getdate() WHERE PropertyInfoCode = 89
UPDATE PropertyInfo SET DisplayOrder = 402, StampDate = getdate() WHERE PropertyInfoCode = 15
UPDATE PropertyInfo SET DisplayOrder = 404, StampDate = getdate() WHERE PropertyInfoCode = 20
UPDATE PropertyInfo SET DisplayOrder = 406, StampDate = getdate() WHERE PropertyInfoCode = 22
UPDATE PropertyInfo SET DisplayOrder = 407, StampDate = getdate() WHERE PropertyInfoCode = 23
UPDATE PropertyInfo SET DisplayOrder = 408, StampDate = getdate() WHERE PropertyInfoCode = 25
UPDATE PropertyInfo SET DisplayOrder = 410, StampDate = getdate() WHERE PropertyInfoCode = 30
UPDATE PropertyInfo SET DisplayOrder = 412, StampDate = getdate() WHERE PropertyInfoCode = 35
UPDATE PropertyInfo SET DisplayOrder = 414, StampDate = getdate() WHERE PropertyInfoCode = 40
UPDATE PropertyInfo SET DisplayOrder = 416, StampDate = getdate() WHERE PropertyInfoCode = 600
UPDATE PropertyInfo SET DisplayOrder = 502, StampDate = getdate() WHERE PropertyInfoCode = 610
UPDATE PropertyInfo SET DisplayOrder = 602, StampDate = getdate() WHERE PropertyInfoCode = 10
UPDATE PropertyInfo SET DisplayOrder = 604, StampDate = getdate() WHERE PropertyInfoCode = 50
UPDATE PropertyInfo SET DisplayOrder = 606, StampDate = getdate() WHERE PropertyInfoCode = 60
UPDATE PropertyInfo SET DisplayOrder = 608, StampDate = getdate() WHERE PropertyInfoCode = 70
UPDATE PropertyInfo SET DisplayOrder = 610, StampDate = getdate() WHERE PropertyInfoCode = 500
UPDATE PropertyInfo SET DisplayOrder = 702, StampDate = getdate() WHERE PropertyInfoCode = 200
UPDATE PropertyInfo SET DisplayOrder = 810, StampDate = getdate() WHERE PropertyInfoCode = 65
UPDATE PropertyInfo SET DisplayOrder = 820, StampDate = getdate() WHERE PropertyInfoCode = 100
UPDATE PropertyInfo SET DisplayOrder = 830, StampDate = getdate() WHERE PropertyInfoCode = 121
UPDATE PropertyInfo SET DisplayOrder = 832, StampDate = getdate() WHERE PropertyInfoCode = 128
UPDATE PropertyInfo SET DisplayOrder = 834, StampDate = getdate() WHERE PropertyInfoCode = 122
UPDATE PropertyInfo SET DisplayOrder = 836, StampDate = getdate() WHERE PropertyInfoCode = 123
UPDATE PropertyInfo SET DisplayOrder = 838, StampDate = getdate() WHERE PropertyInfoCode = 125
UPDATE PropertyInfo SET DisplayOrder = 840, StampDate = getdate() WHERE PropertyInfoCode = 90
UPDATE PropertyInfo SET DisplayOrder = 842, StampDate = getdate() WHERE PropertyInfoCode = 129
UPDATE PropertyInfo SET DisplayOrder = 844, StampDate = getdate() WHERE PropertyInfoCode = 85
UPDATE PropertyInfo SET DisplayOrder = 846, StampDate = getdate() WHERE PropertyInfoCode = 124
UPDATE PropertyInfo SET DisplayOrder = 848, StampDate = getdate() WHERE PropertyInfoCode = 95
UPDATE PropertyInfo SET DisplayOrder = 850, StampDate = getdate() WHERE PropertyInfoCode = 126
UPDATE PropertyInfo SET DisplayOrder = 852, StampDate = getdate() WHERE PropertyInfoCode = 127
UPDATE PropertyInfo SET DisplayOrder = 860, StampDate = getdate() WHERE PropertyInfoCode = 130
END


GO
