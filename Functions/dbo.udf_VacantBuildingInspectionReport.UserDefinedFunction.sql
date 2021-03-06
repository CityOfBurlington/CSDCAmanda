USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_VacantBuildingInspectionReport]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_VacantBuildingInspectionReport](@pintFolderRSN INT) 
RETURNS @BVT TABLE (FolderRSN INT PRIMARY KEY, Name VARCHAR(100), AddressLine1 VARCHAR(100), AddressLine2 VARCHAR(100),
		AddressLine3 VARCHAR(100), PeopleDesc VARCHAR(100), FolderName VARCHAR(100), 
		OpeningsFindings VARCHAR(1000), OpeningsRemedy VARCHAR(1000), OpeningsComplyBy VARCHAR (64), OpeningsStatus VARCHAR(50),
		RoofsFindings VARCHAR(1000), RoofsRemedy VARCHAR(1000), RoofsComplyBy VARCHAR (64), RoofsStatus VARCHAR(50),
		DrainageFindings VARCHAR(1000), DrainageRemedy VARCHAR(1000), DrainageComplyBy VARCHAR (64), DrainageStatus VARCHAR(50),
		StructureFindings VARCHAR(1000), StructureRemedy VARCHAR(1000), StructureComplyBy VARCHAR (64), StructureStatus VARCHAR(50),
		MembersFindings VARCHAR(1000), MembersRemedy VARCHAR(1000), MembersComplyBy VARCHAR (64), MembersStatus VARCHAR(50),
		FndWallsFindings VARCHAR(1000), FndWallsRemedy VARCHAR(1000), FndWallsComplyBy VARCHAR (64), FndWallsStatus VARCHAR(50),
		ExtWallsFindings VARCHAR(1000), ExtWallsRemedy VARCHAR(1000), ExtWallsComplyBy VARCHAR (64), ExtWallsStatus VARCHAR(50),
		DecorativeFindings VARCHAR(1000), DecorativeRemedy VARCHAR(1000), DecorativeComplyBy VARCHAR (64), DecorativeStatus VARCHAR(50),
		OverhangFindings VARCHAR(1000), OverhangRemedy VARCHAR(1000), OverhangComplyBy VARCHAR (64), OverhangStatus VARCHAR(50),
		ChimneysFindings VARCHAR(1000), ChimneysRemedy VARCHAR(1000), ChimneysComplyBy VARCHAR (64), ChimneysStatus VARCHAR(50),
		WalkwaysFindings VARCHAR(1000), WalkwaysRemedy VARCHAR(1000), WalkwaysComplyBy VARCHAR (64), WalkwaysStatus VARCHAR(50),
		AccessoryFindings VARCHAR(1000), AccessoryRemedy VARCHAR(1000), AccessoryComplyBy VARCHAR (64), AccessoryStatus VARCHAR(50),
		PremisesFindings VARCHAR(1000), PremisesRemedy VARCHAR(1000), PremisesComplyBy VARCHAR (64), PremisesStatus VARCHAR(50)
)
AS BEGIN

/*
Deficiency Codes:
Code	Desc									Variable
----	----									--------
25000	Building								Openings
25020	Roofs									Roofs
25040	Drainage								Drainage
25060	Building Structure						Structure
25080	Structural Members						Members
25100	Foundation Walls						FndWalls
25120	Exterior Walls							ExtWalls
25140	Decorative features						Decorative
25160	Overhanging extensions					Overhang
25180	Chimneys and Towers						Chimneys
25200	Walkways								Walkways
25240	Accessory and appurtenant structures	Accessory
25260	Premises								Premises
*/

DECLARE @Name					VARCHAR(100)
DECLARE @AddressLine1			VARCHAR(100)
DECLARE @AddressLine2			VARCHAR(100)
DECLARE @AddressLine3			VARCHAR(100)
DECLARE @PeopleDesc				VARCHAR(100)
DECLARE @FolderName				VARCHAR(100)

DECLARE @OpeningsFindings		VARCHAR(1000)
DECLARE @OpeningsRemedy		VARCHAR(1000)
DECLARE @OpeningsComplyByDate	DATE
DECLARE @OpeningsComplyBy		VARCHAR(64)
DECLARE @OpeningsStatus		VARCHAR(50)

DECLARE @RoofsFindings			VARCHAR(1000)
DECLARE @RoofsRemedy			VARCHAR(1000)
DECLARE @RoofsComplyByDate		DATE
DECLARE @RoofsComplyBy			VARCHAR(64)
DECLARE @RoofsStatus			VARCHAR(50)

DECLARE @DrainageFindings			VARCHAR(1000)
DECLARE @DrainageRemedy			VARCHAR(1000)
DECLARE @DrainageComplyByDate		DATE
DECLARE @DrainageComplyBy			VARCHAR(64)
DECLARE @DrainageStatus			VARCHAR(50)

DECLARE @StructureFindings			VARCHAR(1000)
DECLARE @StructureRemedy			VARCHAR(1000)
DECLARE @StructureComplyByDate		DATE
DECLARE @StructureComplyBy			VARCHAR(64)
DECLARE @StructureStatus			VARCHAR(50)

DECLARE @MembersFindings			VARCHAR(1000)
DECLARE @MembersRemedy			VARCHAR(1000)
DECLARE @MembersComplyByDate		DATE
DECLARE @MembersComplyBy			VARCHAR(64)
DECLARE @MembersStatus			VARCHAR(50)

DECLARE @FndWallsFindings			VARCHAR(1000)
DECLARE @FndWallsRemedy			VARCHAR(1000)
DECLARE @FndWallsComplyByDate		DATE
DECLARE @FndWallsComplyBy			VARCHAR(64)
DECLARE @FndWallsStatus			VARCHAR(50)

DECLARE @ExtWallsFindings			VARCHAR(1000)
DECLARE @ExtWallsRemedy			VARCHAR(1000)
DECLARE @ExtWallsComplyByDate		DATE
DECLARE @ExtWallsComplyBy			VARCHAR(64)
DECLARE @ExtWallsStatus			VARCHAR(50)

DECLARE @DecorativeFindings			VARCHAR(1000)
DECLARE @DecorativeRemedy			VARCHAR(1000)
DECLARE @DecorativeComplyByDate		DATE
DECLARE @DecorativeComplyBy			VARCHAR(64)
DECLARE @DecorativeStatus			VARCHAR(50)

DECLARE @OverhangFindings			VARCHAR(1000)
DECLARE @OverhangRemedy			VARCHAR(1000)
DECLARE @OverhangComplyByDate		DATE
DECLARE @OverhangComplyBy			VARCHAR(64)
DECLARE @OverhangStatus			VARCHAR(50)

DECLARE @ChimneysFindings			VARCHAR(1000)
DECLARE @ChimneysRemedy			VARCHAR(1000)
DECLARE @ChimneysComplyByDate		DATE
DECLARE @ChimneysComplyBy			VARCHAR(64)
DECLARE @ChimneysStatus			VARCHAR(50)

DECLARE @WalkwaysFindings			VARCHAR(1000)
DECLARE @WalkwaysRemedy			VARCHAR(1000)
DECLARE @WalkwaysComplyByDate		DATE
DECLARE @WalkwaysComplyBy			VARCHAR(64)
DECLARE @WalkwaysStatus			VARCHAR(50)

DECLARE @AccessoryFindings			VARCHAR(1000)
DECLARE @AccessoryRemedy			VARCHAR(1000)
DECLARE @AccessoryComplyByDate		DATE
DECLARE @AccessoryComplyBy			VARCHAR(64)
DECLARE @AccessoryStatus			VARCHAR(50)

DECLARE @PremisesFindings			VARCHAR(1000)
DECLARE @PremisesRemedy			VARCHAR(1000)
DECLARE @PremisesComplyByDate		DATE
DECLARE @PremisesComplyBy			VARCHAR(64)
DECLARE @PremisesStatus			VARCHAR(50)

SELECT TOP 1 @Name = UPPER(dbo.TK_PEOPLE_NAMEORG(FolderPeople.PeopleRSN)), 
@AddressLine1 = UPPER(dbo.TK_PEOPLE_FREEFORMADDRESSLINE(FolderPeople.PeopleRSN, 1)),
@AddressLine2 = UPPER(dbo.TK_PEOPLE_FREEFORMADDRESSLINE(FolderPeople.PeopleRSN, 2)),
@AddressLine3 = UPPER(dbo.TK_PEOPLE_FREEFORMADDRESSLINE(FolderPeople.PeopleRSN, 3)),
@FolderName = FolderName,
@PeopleDesc = PeopleDesc
FROM Folder F, FolderPeople, People, ValidPeople
WHERE F.FolderRSN = FolderPeople.FolderRSN
AND FolderPeople.PeopleRSN = People.PeopleRSN
AND FolderPeople.PeopleCode = ValidPeople.PeopleCode
AND FolderPeople.PeopleCode = 322
AND F.FolderRSN =  @pintFolderRSN

--SET Buildings Variables 
--Openings:
SET @OpeningsFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25000 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @OpeningsRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25000 ORDER BY DeficiencyID DESC),
	'N/A')

SET @OpeningsComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25000 ORDER BY DeficiencyID DESC),
	'')
IF @OpeningsComplyByDate > '1/1/2000' SET @OpeningsComplyBy = dbo.FormatDateTime(@OpeningsComplyByDate,'LONGDATE')
ELSE SET @OpeningsComplyBy = 'N/A'

SET @OpeningsStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25000 ORDER BY DeficiencyID DESC),
	'N/A')

--Roofs:
SET @RoofsFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25020 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @RoofsRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25020 ORDER BY DeficiencyID DESC),
	'N/A')

SET @RoofsComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25020 ORDER BY DeficiencyID DESC),
	'')
IF @RoofsComplyByDate > '1/1/2000' SET @RoofsComplyBy = dbo.FormatDateTime(@RoofsComplyByDate,'LONGDATE')
ELSE SET @RoofsComplyBy = 'N/A'

SET @RoofsStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25020 ORDER BY DeficiencyID DESC),
	'N/A')

--Drainage:
SET @DrainageFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25040 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @DrainageRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25040 ORDER BY DeficiencyID DESC),
	'N/A')

SET @DrainageComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25040 ORDER BY DeficiencyID DESC),
	'')
IF @DrainageComplyByDate > '1/1/2000' SET @DrainageComplyBy = dbo.FormatDateTime(@DrainageComplyByDate,'LONGDATE')
ELSE SET @DrainageComplyBy = 'N/A'

SET @DrainageStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25040 ORDER BY DeficiencyID DESC),
	'N/A')

--Structure:
SET @StructureFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25060 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @StructureRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25060 ORDER BY DeficiencyID DESC),
	'N/A')

SET @StructureComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25060 ORDER BY DeficiencyID DESC),
	'')
IF @StructureComplyByDate > '1/1/2000' SET @StructureComplyBy = dbo.FormatDateTime(@StructureComplyByDate,'LONGDATE')
ELSE SET @StructureComplyBy = 'N/A'

SET @StructureStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25060 ORDER BY DeficiencyID DESC),
	'N/A')

--Members:
SET @MembersFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25080 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @MembersRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25080 ORDER BY DeficiencyID DESC),
	'N/A')

SET @MembersComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25080 ORDER BY DeficiencyID DESC),
	'')
IF @MembersComplyByDate > '1/1/2000' SET @MembersComplyBy = dbo.FormatDateTime(@MembersComplyByDate,'LONGDATE')
ELSE SET @MembersComplyBy = 'N/A'

SET @MembersStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25080 ORDER BY DeficiencyID DESC),
	'N/A')

--FndWalls:
SET @FndWallsFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25100 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @FndWallsRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25100 ORDER BY DeficiencyID DESC),
	'N/A')

SET @FndWallsComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25100 ORDER BY DeficiencyID DESC),
	'')
IF @FndWallsComplyByDate > '1/1/2000' SET @FndWallsComplyBy = dbo.FormatDateTime(@FndWallsComplyByDate,'LONGDATE')
ELSE SET @FndWallsComplyBy = 'N/A'

SET @FndWallsStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25100 ORDER BY DeficiencyID DESC),
	'N/A')

--ExtWalls:
SET @ExtWallsFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25120 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @ExtWallsRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25120 ORDER BY DeficiencyID DESC),
	'N/A')

SET @ExtWallsComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25120 ORDER BY DeficiencyID DESC),
	'')
IF @ExtWallsComplyByDate > '1/1/2000' SET @ExtWallsComplyBy = dbo.FormatDateTime(@ExtWallsComplyByDate,'LONGDATE')
ELSE SET @ExtWallsComplyBy = 'N/A'

SET @ExtWallsStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25120 ORDER BY DeficiencyID DESC),
	'N/A')

--Decorative:
SET @DecorativeFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25140 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @DecorativeRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25140 ORDER BY DeficiencyID DESC),
	'N/A')

SET @DecorativeComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25140 ORDER BY DeficiencyID DESC),
	'')
IF @DecorativeComplyByDate > '1/1/2000' SET @DecorativeComplyBy = dbo.FormatDateTime(@DecorativeComplyByDate,'LONGDATE')
ELSE SET @DecorativeComplyBy = 'N/A'

SET @DecorativeStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25140 ORDER BY DeficiencyID DESC),
	'N/A')

--Overhang:
SET @OverhangFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25160 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @OverhangRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25160 ORDER BY DeficiencyID DESC),
	'N/A')

SET @OverhangComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25160 ORDER BY DeficiencyID DESC),
	'')
IF @OverhangComplyByDate > '1/1/2000' SET @OverhangComplyBy = dbo.FormatDateTime(@OverhangComplyByDate,'LONGDATE')
ELSE SET @OverhangComplyBy = 'N/A'

SET @OverhangStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25160 ORDER BY DeficiencyID DESC),
	'N/A')

--Chimneys:
SET @ChimneysFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25180 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @ChimneysRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25180 ORDER BY DeficiencyID DESC),
	'N/A')

SET @ChimneysComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25180 ORDER BY DeficiencyID DESC),
	'')
IF @ChimneysComplyByDate > '1/1/2000' SET @ChimneysComplyBy = dbo.FormatDateTime(@ChimneysComplyByDate,'LONGDATE')
ELSE SET @ChimneysComplyBy = 'N/A'

SET @ChimneysStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25180 ORDER BY DeficiencyID DESC),
	'N/A')

--Walkways:
SET @WalkwaysFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25200 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @WalkwaysRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25200 ORDER BY DeficiencyID DESC),
	'N/A')

SET @WalkwaysComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25200 ORDER BY DeficiencyID DESC),
	'')
IF @WalkwaysComplyByDate > '1/1/2000' SET @WalkwaysComplyBy = dbo.FormatDateTime(@WalkwaysComplyByDate,'LONGDATE')
ELSE SET @WalkwaysComplyBy = 'N/A'

SET @WalkwaysStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25200 ORDER BY DeficiencyID DESC),
	'N/A')

--Accessory:
SET @AccessoryFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25240 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @AccessoryRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25240 ORDER BY DeficiencyID DESC),
	'N/A')

SET @AccessoryComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25240 ORDER BY DeficiencyID DESC),
	'')
IF @AccessoryComplyByDate > '1/1/2000' SET @AccessoryComplyBy = dbo.FormatDateTime(@AccessoryComplyByDate,'LONGDATE')
ELSE SET @AccessoryComplyBy = 'N/A'

SET @AccessoryStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25240 ORDER BY DeficiencyID DESC),
	'N/A')

--Premises:
SET @PremisesFindings = ISNULL(
	(SELECT TOP 1 FPD.DeficiencyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25260 ORDER BY DeficiencyID DESC),
	'No Violation Noted')

SET @PremisesRemedy = ISNULL(
	(SELECT TOP 1 FPD.RemedyText FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25260 ORDER BY DeficiencyID DESC),
	'N/A')

SET @PremisesComplyByDate = ISNULL(
	(SELECT TOP 1 FPD.ComplyByDate FROM FolderProcessDeficiency FPD 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25260 ORDER BY DeficiencyID DESC),
	'')
IF @PremisesComplyByDate > '1/1/2000' SET @PremisesComplyBy = dbo.FormatDateTime(@PremisesComplyByDate,'LONGDATE')
ELSE SET @PremisesComplyBy = 'N/A'

SET @PremisesStatus = ISNULL(
	(SELECT TOP 1 VDS.StatusDesc 
	 FROM FolderProcessDeficiency FPD JOIN ValidDeficiencyStatus VDS ON FPD.StatusCode = VDS.StatusCode 
	 WHERE FPD.FolderRSN = @pintFolderRSN AND DeficiencyCode = 25260 ORDER BY DeficiencyID DESC),
	'N/A')

/*
Deficiency Codes:
Code	Desc									Variable
----	----									--------
25000	Building								Openings
25020	Roofs									Roofs
25040	Drainage								Drainage
25060	Building Structure						Structure
25080	Structural Members						Members
25100	Foundation Walls						FndWalls
25120	Exterior Walls							ExtWalls
25140	Decorative features						Decorative
25160	Overhanging extensions					Overhang
25180	Chimneys and Towers						Chimneys
25200	Walkways								Walkways
25240	Accessory and appurtenant structures	Accessory
25260	Premises								Premises
*/

INSERT @BVT
	(FolderRSN, Name, AddressLine1, AddressLine2, AddressLine3, PeopleDesc, FolderName, 
		OpeningsFindings, OpeningsRemedy, OpeningsComplyBy, OpeningsStatus,
		RoofsFindings, RoofsRemedy, RoofsComplyBy, RoofsStatus,
		DrainageFindings, DrainageRemedy, DrainageComplyBy, DrainageStatus,
		StructureFindings, StructureRemedy, StructureComplyBy, StructureStatus,
		MembersFindings, MembersRemedy, MembersComplyBy, MembersStatus,
		FndWallsFindings, FndWallsRemedy, FndWallsComplyBy, FndWallsStatus,
		ExtWallsFindings, ExtWallsRemedy, ExtWallsComplyBy, ExtWallsStatus,
		DecorativeFindings, DecorativeRemedy, DecorativeComplyBy, DecorativeStatus,
		OverhangFindings, OverhangRemedy, OverhangComplyBy, OverhangStatus,
		ChimneysFindings, ChimneysRemedy, ChimneysComplyBy, ChimneysStatus,
		WalkwaysFindings, WalkwaysRemedy, WalkwaysComplyBy, WalkwaysStatus,
		AccessoryFindings, AccessoryRemedy, AccessoryComplyBy, AccessoryStatus,
		PremisesFindings, PremisesRemedy, PremisesComplyBy, PremisesStatus)

	SELECT @pintFolderRSN, @Name, @AddressLine1, @AddressLine2, @AddressLine3, @PeopleDesc, @FolderName, 
		@OpeningsFindings, @OpeningsRemedy, @OpeningsComplyBy, @OpeningsStatus,
		@RoofsFindings, @RoofsRemedy, @RoofsComplyBy, @RoofsStatus,
		@DrainageFindings, @DrainageRemedy, @DrainageComplyBy, @DrainageStatus,
		@StructureFindings, @StructureRemedy, @StructureComplyBy, @StructureStatus,
		@MembersFindings, @MembersRemedy, @MembersComplyBy, @MembersStatus,
		@FndWallsFindings, @FndWallsRemedy, @FndWallsComplyBy, @FndWallsStatus,
		@ExtWallsFindings, @ExtWallsRemedy, @ExtWallsComplyBy, @ExtWallsStatus,
		@DecorativeFindings, @DecorativeRemedy, @DecorativeComplyBy, @DecorativeStatus,
		@OverhangFindings, @OverhangRemedy, @OverhangComplyBy, @OverhangStatus,
		@ChimneysFindings, @ChimneysRemedy, @ChimneysComplyBy, @ChimneysStatus,
		@WalkwaysFindings, @WalkwaysRemedy, @WalkwaysComplyBy, @WalkwaysStatus,
		@AccessoryFindings, @AccessoryRemedy, @AccessoryComplyBy, @AccessoryStatus,
		@PremisesFindings, @PremisesRemedy, @PremisesComplyBy, @PremisesStatus


RETURN;
END

GO
