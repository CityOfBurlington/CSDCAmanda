USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Web_InspectionRequest]    Script Date: 9/9/2013 9:56:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure created for scheduling an inspection from public portal for bilingual implementation */

CREATE PROCEDURE [dbo].[Web_InspectionRequest]  
  @ArgPeopleRSN  int,  
  @ArgProcessRSNList  varchar(4000),  
  @ArgRequestedForDateList  varchar(4000),  
  @ArgTimeIndicatorList  varchar(4000),  
  @ArgCommentList  varchar(4000)  
AS  

-- Amanda 44.28a: ESS Feb,17, 2010: Modified for bilingual implementation. The 'f_GetAmandaMessage' function has been implemented.    
  
Declare @n_ptr Int  
Declare @n1_ptr Int  
Declare @n2_ptr Int  
Declare @n3_ptr Int  
Declare @n_ProcessRSN int  
Declare @n_FolderRSN int  
Declare @n_ProcessCode int  
Declare @n_RequestedForDate varchar(256)  
Declare @n_ScheduledForDate dateTime  
Declare @n_TimeIndicator VarChar(4000)  
Declare @n_Comment VarChar(4000)  
Declare @c_FolderType VarChar(10)  
Declare @c_ProcessRsnList VarChar(4000)  
Declare @c_TimeIndicatorList VarChar(4000)  
Declare @c_RequestedForDateList VarChar(4000)  
Declare @c_CommentList VarChar(4000)  
DECLARE @c_passedFlag varchar(10)  
Declare @TheError VarChar(4000)  
Declare @d_EndDate  datetime
  
BEGIN  
exec Rsnsetlock  
  
Set @c_ProcessRsnList = @ArgProcessRsnList  
Set @c_RequestedForDateList = @ArgRequestedForDateList  
Set @c_TimeIndicatorList = @ArgTimeIndicatorList  
Set @c_CommentList = @ArgCommentList  
  
WHILE @c_ProcessRsnList > ' '   
Begin   
 /* Get the ProcessRSN */  
 Set @n_ptr = CharIndex (',',  @c_ProcessRsnList)  
 if @n_Ptr > 0   
 begin  
  Set @n_ProcessRSN = SubString(@c_ProcessRsnList, 1, @n_Ptr - 1)  
  Set @c_ProcessRsnList = SubString(@c_ProcessRsnList, @n_Ptr + 1, 1999)  
 end  
 else  
 begin  
  Set @n_ProcessRSN = @c_ProcessRsnList  
  Set @c_ProcessRsnList = ' '   
 end  
  
 SELECT @c_FolderType=Folder.FolderType,   
 @n_FolderRSN=FOLDERPROCESS.FolderRSN,   
 @n_ProcessCode=FOLDERPROCESS.ProcessCode,  
 @c_passedFlag = folderProcess.passedFlag   
 FROM FOLDERPROCESS, FOLDER  
 WHERE ProcessRSN = @n_ProcessRSN  
 AND folderProcess.folderRSN = folder.folderRSN  
  
 -- stop scheduling if passedFlag = 'Y'  
   
 IF @c_passedFlag = 'Y'  
   BEGIN
  SET @TheError = (SELECT dbo.f_GetAmandaMessage('WEB_INSPECTION_REQUEST_ALREADY_SCHEDULED',NULL,NULL))  
  RAISERROR(@TheError,16,-1)  
  RETURN  
   END  
  
 Set @n1_ptr = CharIndex (',',  @c_RequestedForDateList)  
  
 if @n1_Ptr > 0   
   begin  
  Set @n_RequestedForDate = SubString(@c_RequestedForDateList, 1, @n1_Ptr - 1)  
  Set @c_RequestedForDateList = SubString(@c_RequestedForDateList, @n1_Ptr + 1, 1999)  
   end  
 else  
   begin  
  Set @n_RequestedForDate = @c_RequestedForDateList  
  Set @c_RequestedForDateList = ' '   
   end  
   
 Set @n2_ptr = CharIndex (',',  @c_TimeIndicatorList)  
  
 if @n2_Ptr > 0   
   begin  
  Set @n_TimeIndicator = SubString(@c_TimeIndicatorList, 1, @n2_Ptr - 1)  
  Set @c_TimeIndicatorList = SubString(@c_TimeIndicatorList, @n2_Ptr + 1, 1999)  
   end  
 else  
   begin  
  Set @n_TimeIndicator = @c_TimeIndicatorList  
  Set @c_TimeIndicatorList = ' '   
   end  
   
 Set @n3_ptr = CharIndex ('//',  @c_CommentList)  
  
 if @n3_Ptr > 0   
   begin  
  Set @n_Comment = SubString(@c_CommentList, 1, @n3_Ptr - 1)  
  Set @c_CommentList = SubString(@c_CommentList, @n3_Ptr + 1, 1999)  
   end  
 else  
   begin  
  Set @n_Comment = @c_CommentList  
  Set @c_CommentList = ' '   
   end  
  
 SELECT @d_EndDate = FolderProcess.EndDate  
 FROM FolderProcess, Folder  
 WHERE FolderProcess.ProcessRSN = @n_ProcessRSN  
 AND Folder.FolderRSN = FolderProcess.FolderRSN  
  
   /* Do not allow inspection to be scheduled if there is an EndDate */  
 IF @d_EndDate IS NOT NULL   
   BEGIN
  SET @TheError = (SELECT dbo.f_GetAmandaMessage('WEB_INSPECTION_REQUEST_ALREADY_COMPLETED',NULL,NULL))  
  RAISERROR(@TheError,16,-1)  
   END  
  
 /* INSERT a row into the FolderInspectionRequest table */  
  
    INSERT INTO FolderInspectionRequest (StampDate, StampUser, FolderRSN, ProcessRSN, CallReceivedDate, ContactName, ProcessCode, RequestedForDate, TimeIndicator, ScheduledDate, Comments)  
 VALUES (getdate(), 'INTERNET', @n_FolderRSN, @n_ProcessRSN, getdate(), 'INTERNET', @n_ProcessCode, @n_RequestedForDate, LOWER(@n_TimeIndicator), @n_RequestedForDate, 'REQUESTED BY: INTERNET   COMMENTS: ' + @n_Comment);  
  
 UPDATE FolderProcess   
 SET ScheduleDate =@n_RequestedForDate,   
 ScheduleEndDate =@n_RequestedForDate,    
 EndDate =null ,   
 SignOffUser =null ,   
 AssignedUser =null ,   
 StampDate =getDate(),   
 StampUser ='INTERNET',   
 TimeIndicator =LOWER(@n_TimeIndicator),   
 PassedFlag ='Y'   
 WHERE FolderProcess.ProcessRSN = @n_ProcessRSN  
  
End  
END  

GO
