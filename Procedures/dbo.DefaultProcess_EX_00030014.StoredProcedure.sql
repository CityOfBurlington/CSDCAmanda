USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EX_00030014]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EX_00030014]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
DECLARE @AttemptResult INT

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT MAX(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 40 /*Approved*/ 
    BEGIN

    SET @NextProcessRSN = @NextProcessRSN + 1

    DECLARE @ConstructionEndDate DATETIME
    SELECT @ConstructionEndDate = FolderInfo.InfoValueDateTime 
    FROM FolderInfo 
    WHERE ( FolderInfo.FolderRSN = @FolderRSN ) 
    AND ( FolderInfo.InfoCode = 30144 )

    INSERT INTO FolderProcess 
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
    PrintFlag, StatusCode, StampDate, StampUser, AssignedUser,
    ScheduleDate, ScheduleEndDate )  
    VALUES ( @NextProcessRSN, @FolderRSN, 30104, 75, 
    'Y', 1, GetDate(), @UserId, @UserId, GetDate(), @ConstructionEndDate) 

    DECLARE @SubCode int
    SELECT @SubCode = Folder.SubCode
    FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN

    DECLARE @Info30041 float
    SELECT @Info30041 = ISNULL(FolderInfo.InfoValue,0)
    FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
    AND FolderInfo.InfoCode = 30041

    DECLARE @Info30042 float
    SELECT @Info30042 = ISNULL(FolderInfo.InfoValue,0)
    FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
    AND FolderInfo.InfoCode = 30042

    DECLARE @Info30043 float
    SELECT @Info30043 = ISNULL(FolderInfo.InfoValue,0)
    FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
    AND FolderInfo.InfoCode = 30043

    UPDATE Folder
    SET StatusCode = 30090
    WHERE Folder.FolderRSN = @FolderRSN


    IF @SubCode = 30021 /*Sidewalk*/
        BEGIN
    
        IF @Info30042 <> 0
            BEGIN
            
            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
            SET ScheduleDate = getdate() + 365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
         END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS', 16, -1)
            RETURN
        END 
    END
    
    IF @SubCode = 30022 /*Greenbelt*/
        BEGIN
    
        IF @Info30043 <> 0
  BEGIN
            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
            SET ScheduleDate = getdate() + 365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
            END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS', 16, -1)
            RETURN
        END 
    END
    
    IF @SubCode = 30023 /*Roadway*/
        BEGIN
    
        IF @Info30041 <> 0
            BEGIN
            
            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
            SET ScheduleDate = getdate() + 365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
            END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS', 16, -1)
            RETURN
        END 
    END
    
    IF @SubCode = 30024 /*Sidewalk & Greenbelt*/
        BEGIN
    
        IF @Info30042 <> 0 AND @Info30043 <> 0
            BEGIN
            
            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
        SET ScheduleDate = getdate() + 365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
            END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS', 16, -1)
            RETURN
        END 
    END
    
    IF @SubCode = 30025 /*Sidewalk & Roadway*/
        BEGIN
    
        IF @Info30042<>0 AND @Info30041<>0
            BEGIN

            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
            SET ScheduleDate = getdate()+365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
            END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS', 16, -1)
            RETURN
        END 
    END


    IF @SubCode = 30026 /*Sidewalk, Greenbelt & Roadway*/
        BEGIN
    
        IF @Info30042 <> 0 AND @Info30043 <> 0 AND @Info30041 <> 0
            BEGIN
            
            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
            SET ScheduleDate = getdate() + 365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
            END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS',16,-1)
            RETURN
        END 
    END


    IF @SubCode = 30027 /*Greenbelt & Roadway*/
        BEGIN
    
        IF @Info30041 <> 0 AND @Info30043 <> 0
         BEGIN
            
            UPDATE FolderProcess /*schedule 1 year warranty inspection*/
            SET ScheduleDate = getdate() + 365
            WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 30015
            
            END
        ELSE
            BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('YOU MUST COMPLETE SQ. FT. EXCAVATION IN INFOFIELDS',16,-1)
            RETURN
        END 
    END
END


IF @AttemptResult = 140 /*City Crew Repair*/
    BEGIN
    UPDATE Folder
    SET StatusCode = 2, FinalDate = getdate()
    WHERE Folder.FolderRSN = @FolderRSN
END


IF @AttemptResult = 175 /*Legal Action*/
    BEGIN
    UPDATE Folder
    SET StatusCode = 30008 /*Legal Action*/
    WHERE Folder.FolderRSN = @FolderRSN
    
    UPDATE FolderProcess
    SET StatusCode = 1, EndDate = Null
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
END


IF @AttemptResult = 180 /*Legal Action Resolved*/
    BEGIN
    UPDATE Folder
    SET StatusCode = 30002 /*Issued*/
    WHERE Folder.FolderRSN = @FolderRSN
    
    UPDATE FolderProcess
    SET StatusCode = 1, EndDate = Null
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

IF @AttemptResult = 60 /*canceled*/
BEGIN
    UPDATE Folder
    SET Folder.StatusCode = 30005, FinalDate = GetDate()
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess /*add a comment*/
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = 'Process canceled'
    WHERE FolderProcess.processRSN = @processRSN
END


GO
