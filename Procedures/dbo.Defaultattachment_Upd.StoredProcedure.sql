USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Defaultattachment_Upd]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Modified for populating the column for AttachmentInfoDateTime, AttachmentInfoNumeric and AttachmentInfoUpper 
of the AttachmentInfo table with respect to the AttachmentInfoValue, when the attachment info is inserted with the default value
as set in AttachmentDefaultInfo.AttachmentInfoValue */

CREATE PROCEDURE [dbo].[Defaultattachment_Upd] @argAttachmentCode NUMERIC, @argAttachmentRSN NUMERIC, @DUserId VARCHAR
AS

/* Amanda 44.26: ESS March 17, 2009
ESS Feb 02, 2009:
Modified for populating the column for AttachmentInfoDateTime, AttachmentInfoNumeric and AttachmentInfoUpper 
of the AttachmentInfo table with respect to the AttachmentInfoValue.
when the attachment info is inserted with the default value
With the Default Value set-up in  AttachmentDefaultInfo.AttachmentInfoValue, 
(i.e.  insert on default or using the Re-Default button)

*/

BEGIN  

DELETE FROM AttachmentInfo
 WHERE AttachmentRSN = @argAttachmentRSN
   AND AttachmentInfoValue IS NULL
   AND AttachmentInfoCode NOT IN
     ( SELECT AttachmentInfoCode
      FROM DefaultAttachmentInfo
     WHERE AttachmentCode = @argAttachmentCode );
/*
INSERT INTO AttachmentInfo (AttachmentRSN, AttachmentInfoCode, AttachmentInfoValue, DisplayOrder, StampDate, StampUser )
SELECT @argAttachmentRSN, DefaultAttachmentInfo.AttachmentInfoCode, DefaultAttachmentInfo.AttachmentInfoValue, DefaultAttachmentInfo.DisplayOrder, GETDATE(), @DUserId
  FROM DefaultAttachmentInfo
 WHERE AttachmentCode = @argAttachmentCode
   AND AttachmentInfoCode NOT IN
     ( SELECT AttachmentInfoCode FROM AttachmentInfo WHERE AttachmentRSN = @argAttachmentRSN ) ;
*/

DECLARE @v_infotype varchar(2)
DECLARE @v_infocode INT
DECLARE @v_infovalue varchar(2000)
DECLARE @v_disporder INT
DECLARE @DefAttachment_Upd CURSOR 
SET @DefAttachment_Upd = CURSOR FOR
(SELECT VALIDATTACHMENTINFO.ATTACHMENTINFOTYPE,DEFAULTATTACHMENTINFO.AttachmentInfoCode, DEFAULTATTACHMENTINFO.AttachmentInfoValue, DEFAULTATTACHMENTINFO.DisplayOrder 
		     FROM DEFAULTATTACHMENTINFO, VALIDATTACHMENTINFO
		     WHERE DEFAULTATTACHMENTINFO.ATTACHMENTINFOCODE = VALIDATTACHMENTINFO.ATTACHMENTINFOCODE 
			 AND DEFAULTATTACHMENTINFO.AttachmentCode = @argAttachmentCode
			 AND DEFAULTATTACHMENTINFO.AttachmentInfoCode NOT IN
			 ( SELECT AttachmentInfoCode FROM ATTACHMENTINFO WHERE AttachmentRSN = @argAttachmentRSN ))
OPEN @DefAttachment_Upd
FETCH NEXT FROM @DefAttachment_Upd INTO @v_infotype,@v_infocode,@v_infovalue,@v_disporder
WHILE @@FETCH_STATUS = 0
BEGIN
IF @v_infotype = 'N' BEGIN	

	INSERT INTO ATTACHMENTINFO ( AttachmentRSN, AttachmentInfoCode, AttachmentInfoValue,AttachmentInfoNumeric,DisplayOrder, StampDate, StampUser ,AttachmentInfoUpper)
	VALUES (@argAttachmentRSN, @v_infocode, @v_infovalue, CAST( REPLACE( @v_infovalue,',','') AS FLOAT),@v_disporder,GETDATE(),@DUserId,UPPER(@v_infovalue))
END 
ELSE IF @v_infotype = 'D'  BEGIN	

	INSERT INTO ATTACHMENTINFO ( AttachmentRSN, AttachmentInfoCode, AttachmentInfoValue,AttachmentInfoDateTime,DisplayOrder, StampDate, StampUser,AttachmentInfoUpper )
	VALUES (@argAttachmentRSN, @v_infocode, @v_infovalue, CONVERT( DATETIME, @v_infovalue),@v_disporder,GETDATE(),@DUserId,UPPER(@v_infovalue)) 
END 
ELSE  BEGIN 	

	INSERT INTO ATTACHMENTINFO ( AttachmentRSN, AttachmentInfoCode, AttachmentInfoValue,AttachmentInfoUpper,DisplayOrder, StampDate, StampUser )
	VALUES (@argAttachmentRSN, @v_infocode, @v_infovalue, UPPER(@v_infovalue),@v_disporder,GETDATE(),@DUserId) 
	
END 
 
FETCH NEXT FROM @DefAttachment_Upd INTO @v_infotype,@v_infocode,@v_infovalue,@v_disporder
END
CLOSE @DefAttachment_Upd
DEALLOCATE @DefAttachment_Upd 

END


GO
