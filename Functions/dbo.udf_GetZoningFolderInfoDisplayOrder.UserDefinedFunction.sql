USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFolderInfoDisplayOrder]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFolderInfoDisplayOrder](@intFolderRSN INT, @intFolderInfoCode INT)
RETURNS INT
AS
BEGIN

	/* Sets Zoning FolderInfo DisplayOrders. As new FolderInfo fields are 
	   added, this must also be updated. */
	/* If specification of FolderRSN is not needed, enter zero for FolderRSN. */

	DECLARE @intDisplayOrder int
	DECLARE @varFolderType varchar(4)
	DECLARE @intDefaultCount int

	SET @intDisplayOrder = 0
	
	IF @intFolderRSN = 0 SELECT @intDefaultCount = 0
	ELSE
	BEGIN
		SELECT @varFolderType = Folder.FolderType 
		  FROM Folder
		 WHERE Folder.FolderRSN = @intFolderRSN
	
		SELECT @intDefaultCount = COUNT(*)
		  FROM DefaultInfo
		 WHERE DefaultInfo.InfoCode = @intFolderInfoCode 
		   AND DefaultInfo.FolderType = @varFolderType 
	END

	/* If there is an entry in DefaultInfo for an InfoCode, use it. */

	IF @intDefaultCount > 0    /* Folder default DisplayOrders */
	BEGIN
		SELECT @intDisplayOrder = DefaultInfo.DisplayOrder 
		  FROM DefaultInfo
		 WHERE DefaultInfo.InfoCode = @intFolderInfoCode 
		   AND DefaultInfo.FolderType = @varFolderType 
	END
	ELSE	/* Otherwise use the below - Note: All zoning ValidInfo fields are listed */
			/* Use U:\Amanda\folderinfo\zoning\zoning_folderinfo.xlsx to update. */ 
	BEGIN
		SELECT @intDisplayOrder = 
		CASE @intFolderInfoCode
WHEN 10019 THEN 102         /* Project Use */
WHEN 10021 THEN 104         /* Project Type */
WHEN 10015 THEN 106         /* Project Type (COA 3) */
WHEN 10044 THEN 108         /* Number of Signs - No Master Plan */
WHEN 10129 THEN 110         /* Number of Signs - Master Plan */
WHEN 10062 THEN 112         /* Type of Sign */
WHEN 10063 THEN 114         /* Sign Materials */
WHEN 10045 THEN 116         /* Number of Awnings */
WHEN 10064 THEN 118         /* Awning with Lettering */
WHEN 10065 THEN 120         /* Awning Materials */
WHEN 10041 THEN 122         /* Illumination */
WHEN 10000 THEN 124         /* Estimated Construction Cost */
WHEN 10008 THEN 126         /* Net New Habitable Sq. Ft. */
WHEN 10016 THEN 128         /* Net Lot/Housing Units Created */
WHEN 10043 THEN 130         /* Violation Flag */
WHEN 10040 THEN 132         /* Grading Change */
WHEN 10077 THEN 134         /* Erosion Control Plan Required */
WHEN 10018 THEN 136         /* Existing Use of Property */
WHEN 10020 THEN 138         /* Proposed Use of Property */
WHEN 10130 THEN 140         /* Owner Email Address */
WHEN 10131 THEN 142         /* Applicant Email Address */
WHEN 10004 THEN 144         /* Existing Lot Coverage % */
WHEN 10006 THEN 146         /* Proposed Lot Coverage % */
WHEN 10010 THEN 148         /* Existing Parking Spaces */
WHEN 10012 THEN 150         /* Proposed Parking Spaces */
WHEN 10014 THEN 152         /* Required Parking Spaces */
WHEN 10046 THEN 154         /* Waived Parking Spaces */
WHEN 10025 THEN 156         /* Existing Building Height */
WHEN 10026 THEN 158         /* Proposed Building Height */
WHEN 10066 THEN 160         /* File in Land Records */
WHEN 10005 THEN 202         /* Project File */
WHEN 10068 THEN 204         /* Project Manager */
WHEN 10055 THEN 206         /* Admin Decision Date */
WHEN 10042 THEN 208         /* Non Applicability Released */
WHEN 10007 THEN 210         /* CB Meeting Date */
WHEN 10003 THEN 212         /* DAB Meeting Date */
WHEN 10001 THEN 214         /* DRB Meeting Date */
WHEN 10061 THEN 216         /* Public Hearing Type */
WHEN 10009 THEN 218         /* DRB Public Hearing Closed Date */
WHEN 10017 THEN 220         /* DRB Deliberative Meeting Date */
WHEN 10036 THEN 222         /* DRB Deliberative Decision */
WHEN 10049 THEN 224         /* DRB Decision Date */
WHEN 10056 THEN 226         /* DRB Appeal Decision Date */
WHEN 10038 THEN 228         /* VEC Appeal Date */
WHEN 10069 THEN 230         /* VEC Docket Number */
WHEN 10057 THEN 232         /* VEC Appeal Decision Date */
WHEN 10079 THEN 234         /* SC Docket Number */
WHEN 10080 THEN 236         /* SC Appeal Decision Date */
WHEN 10013 THEN 238         /* Historic COA Review */
WHEN 10050 THEN 240         /* COA Number */
WHEN 10052 THEN 242         /* COA Decision Date */
WHEN 10048 THEN 244         /* DRB Number (Legacy) */
WHEN 10127 THEN 246         /* Construction Start Deadline */
WHEN 10024 THEN 248         /* Permit Expiration Date */
WHEN 10023 THEN 250         /* Permit Picked Up */
WHEN 10027 THEN 252         /* Act 250 Review */
WHEN 10028 THEN 254         /* Act 250 Decision Date */
WHEN 10081 THEN 302         /* Number of Phases */
WHEN 10128 THEN 304         /* Expiration Notification Generated */
WHEN 10070 THEN 306         /* Temp C of O Term */
WHEN 10071 THEN 308         /* Temp C of O Decision Date */
WHEN 10072 THEN 310         /* Temp C of O Expiration Date */
WHEN 10073 THEN 312         /* Final C of O Decision Date */
WHEN 10074 THEN 314         /* Final C of O Site Plan Type */
WHEN 10078 THEN 402         /* Extend Permit Expiration */
WHEN 10002 THEN 502         /* Current Zoning */
WHEN 10011 THEN 504         /* Historic Zoning */
WHEN 10031 THEN 506         /* Design Review by Geography */
WHEN 10125 THEN 508         /* Parking District */
WHEN 10032 THEN 510         /* Historic Resource */
WHEN 10030 THEN 512         /* Institutional Core Campus */
WHEN 10035 THEN 514         /* RH Density Bonus */
WHEN 10037 THEN 516         /* RL Larger Lot */
WHEN 10034 THEN 518         /* NRP: Wetland */
WHEN 10126 THEN 520         /* NRP: Vernal Pool */
WHEN 10033 THEN 522         /*  NRP: Special Flood Hazard Area */
WHEN 10051 THEN 524         /* NRP: Riparian and Littoral Zone */
WHEN 10076 THEN 526         /* NRP: Natural Area */
WHEN 10123 THEN 528         /* Mouth of the River */
WHEN 10124 THEN 530         /* Centennial Woods */
WHEN 10047 THEN 602         /* Lot Size (Sq Ft) */
WHEN 10022 THEN 604         /* Corner Lot */
WHEN 10029 THEN 606         /* Year Built */
WHEN 10039 THEN 608         /* Easements or Right-of-Ways */
WHEN 10075 THEN 610         /* Street Status (DPW) */
WHEN 10067 THEN 612         /* Ward */
WHEN 10053 THEN 702         /* Zoning Application Fee */
WHEN 10054 THEN 704         /* Development Review Fee */
WHEN 10058 THEN 706         /* Impact Fees */
WHEN 10059 THEN 708         /* Impact Fee Rate Applied */
WHEN 10060 THEN 710         /* Impact Fee Sq Footage */
		END
	END

	RETURN @intDisplayOrder
END

GO
