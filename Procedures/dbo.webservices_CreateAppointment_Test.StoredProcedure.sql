USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[webservices_CreateAppointment_Test]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[webservices_CreateAppointment_Test](@emailSubject VARCHAR(400), @emailBody VARCHAR(8000), 
@FromAddress VARCHAR(400), @FromDescription VARCHAR(400), 
@ToAddress VARCHAR(2000), @Attachments VARCHAR(2000),
@StartDate VARCHAR(60), @EndDate VARCHAR(60), @AppointmentLocation VARCHAR(400))
AS
BEGIN
	DECLARE @error VARCHAR(8000)
	DECLARE @response varchar(8000) 

	SET @emailSubject = ISNULL(REPLACE(@emailSubject, '&', '+'), '')
	SET @emailBody = ISNULL(REPLACE(@emailBody, '&', '+'), '')
	SET @FromAddress = ISNULL(REPLACE(@FromAddress, '&', '+'), '')
	SET @FromDescription = REPLACE(@FromDescription, '&', '+')
	SET @ToAddress = REPLACE(@ToAddress, '&', '+')
	SET @Attachments = REPLACE(@Attachments, '&', '+')
	SET @AppointmentLocation = REPLACE(@AppointmentLocation, '&', '+')
	SET @EndDate = ISNULL(@EndDate, '')
	
	DECLARE @SQL nVARCHAR(4000)
	DECLARE @ShowSQL nVARCHAR(4000)

	SET @SQL = REPLACE('http://cobintranet:81/WebServices.aspx?Action=CreateAppointment&Subject=' + @emailSubject + '&Body=' + @emailBody + '&FromAddress=' + @FromAddress + '&FromDescription=' + @FromDescription + '&ToAddress=' + @ToAddress + '&Attachments='
 + @Attachments + '&StartDate=' + @StartDate + '&EndDate=' + @EndDate + '&Location=' + @AppointmentLocation, ' ', '%20')

--	RAISERROR (@SQL ,16,-1) 
	EXEC HTTP_POST @SQL, @response, @error
	--RAISERROR (@Response ,16,-1) 

	
END

GO
