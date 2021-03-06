USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[copy_property]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [dbo].[copy_property]
	@argOldPropertyRSN int,
	@argNewPropertyRSN int,
	@ArgUserId char(128)
AS

/* Amanda 4.3V14: Subhash December 21, 2004:
	SecurityCode added while copying PropertyPeople table
	StampUser, StampDate, SecurityCode, InfoValueUpper, PropertyInfoValueCrypt, PropertyInfoValueDateTime, PropertyInfoValueNumeric, DisplayOrder columns added while copying PropertyInfo
*/
	DECLARE @SYSDATE datetime

	SELECT @SYSDATE = getdate()
	/* copy people */
	INSERT INTO PropertyPeople
		(PropertyRSN, PeopleCode, PeopleRSN, PeopleRSNCrypt,
		 PrintFlag, StartDate, EndDate, StampUser,StampDate, SecurityCode)
	SELECT @argNewPropertyRSN, PeopleCode, PeopleRSN, PeopleRSNCrypt,
		 PrintFlag, StartDate, EndDate, @ArgUserId, @SYSDATE, SecurityCode
  	FROM PropertyPeople
 	WHERE PropertyRSN = @argOldPropertyRSN

	/* copy info */
	INSERT INTO PropertyInfo
		(PropertyRSN, PropertyInfoCode, PropInfoValue, StampUser, StampDate, SecurityCode,
		 InfoValueUpper, PropertyInfoValueCrypt, PropertyInfoValueDateTime, PropertyInfoValueNumeric, DisplayOrder)
	SELECT @argNewPropertyRSN, PropertyInfoCode, PropInfoValue, @ArgUserId, @SYSDATE, SecurityCode,
		 InfoValueUpper, PropertyInfoValueCrypt, PropertyInfoValueDateTime, PropertyInfoValueNumeric, DisplayOrder
  	FROM PropertyInfo
 	WHERE PropertyRSN = @argOldPropertyRSN

	/* copy comment */
	INSERT INTO PropertyComment
		(PropertyRSN, CommentDate, Comments, StampUser, StampDate)
	SELECT @argNewPropertyRSN, CommentDate, Comments, @ArgUserId, @SYSDATE
  	FROM PropertyComment
 	WHERE PropertyRSN = @argOldPropertyRSN

	/* copy parcel */
	INSERT INTO PropertyParcel
		(ParcelRSN, PropertyRSN, ParcelCode, ParcelNumber,
		 LotBlockCode, LotBlockNumber, StampUser, StampDate)
	SELECT ParcelRSN, @argNewPropertyRSN, ParcelCode, ParcelNumber,
		 LotBlockCode, LotBlockNumber, @ArgUserId, @SYSDATE
  	FROM PropertyParcel
 	WHERE PropertyRSN = @argOldPropertyRSN

	/* copy survey */
	INSERT INTO PropertySurvey
		(PropertyRSN, SurveyDate, PeopleRSN, SurveyFeePaid,
		 SurveyReceiptNumber, SurveyComplianceType, SurveyComment)
	SELECT @argNewPropertyRSN, SurveyDate, PeopleRSN, SurveyFeePaid,
		 SurveyReceiptNumber, SurveyComplianceType, SurveyComment
  	FROM PropertySurvey
 	WHERE PropertyRSN = @argOldPropertyRSN

GO
