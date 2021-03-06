USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZnDecisionLetterText]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZnDecisionLetterText](@intFolderRSN INT) 
RETURNS varchar(4000)
AS
BEGIN
   /* Functionality for ZL folders is not implemented */
   DECLARE @FolderRSN int
   DECLARE @FolderType varchar(2)
   DECLARE @FolderName varchar(100)
   DECLARE @ZPNumber varchar(10)
   DECLARE @SubCode int
   DECLARE @SubDesc varchar(30)
   DECLARE @WorkCode int
   DECLARE @WorkDesc varchar(30)
   DECLARE @ReviewBody varchar(30)
   DECLARE @DecisionDate datetime
   DECLARE @DRBDelibDate datetime
   DECLARE @ExpiryDate datetime
   DECLARE @ResultCode int
   DECLARE @Decision varchar(40)
   DECLARE @DecisionZH varchar(40)
   DECLARE @ProposalType varchar(70)
   DECLARE @BalanceDue numeric
   DECLARE @LetterText1 varchar(1000)
   DECLARE @LetterText2 varchar(1000)
   DECLARE @LetterText3 varchar(1000)
   DECLARE @LetterText4 varchar(1000)
   DECLARE @LetterText varchar(4000)

   SELECT @FolderRSN = Folder.FolderRSN, 
          @FolderType = Folder.FolderType,
          @FolderName = Folder.FolderName,
          @SubCode = Folder.SubCode,
          @SubDesc = ValidSub.SubDesc,
          @WorkCode = Folder.WorkCode,
          @WorkDesc = ValidWork.WorkDesc,  
          @DecisionDate = Folder.IssueDate, 
          @ExpiryDate = Folder.ExpiryDate,
          @ZPNumber = Folder.ReferenceFile,
          @ResultCode = dbo.udf_GetProcessAttemptCode(Folder.FolderRSN, 10005),
          @Decision = dbo.udf_GetProcessAttemptDesc(Folder.FolderRSN, 10005),
          @DRBDelibDate = dbo.f_info_date(Folder.FolderRSN, 10017), 
          @DecisionZH = dbo.f_info_alpha(Folder.FolderRSN, 10036), 
          --@BalanceDue = CONVERT(DECIMAL(12,2),dbo.udf_GetPermitTotalFees(Folder.FolderRSN) - dbo.udf_GetPermitTotalAmountPaid(Folder.FolderRSN))
          @BalanceDue = CONVERT(DECIMAL(12,2),dbo.udf_GetPermitFees(Folder.FolderRSN) - dbo.udf_GetPermitAmountPaid(Folder.FolderRSN))
    FROM Folder, ValidSub, ValidWork
    WHERE Folder.SubCode = ValidSub.SubCode
      AND Folder.WorkCode = ValidWork.WorkCode
      AND Folder.FolderRSN = @intFolderRSN

   IF @SubCode = 10041 SELECT @ReviewBody = 'Zoning Administrator'
   ELSE SELECT @ReviewBody = 'Development Review Board'

   IF @FolderType IN('ZA', 'ZB', 'ZF', 'Z1', 'Z2') SELECT @ProposalType = ' your proposal for '
   IF @FolderType = 'Z3' SELECT @ProposalType = ' your ' + @WorkDesc + ' proposal for '
   IF @FolderType = 'ZC' SELECT @ProposalType = ' your ' + @WorkDesc + ' proposal for '
   IF @FolderType = 'ZH' SELECT @ProposalType = ' your ' + @WorkDesc + ' proposal for '

   IF @FolderType = 'ZL' 
   BEGIN
      IF @WorkCode = 10004 SELECT @ProposalType = ' your Appeal of Code Enforcement Determination for '
      IF @WorkCode = 10005 SELECT @ProposalType = ' your Appeal of Zoning Decision for '
   END

   IF @FolderType IN ('ZC', 'ZH') AND @ResultCode = 0
   BEGIN
      SELECT @ResultCode = 
      CASE
         WHEN @DecisionZH = 'Denied' THEN 10002
         WHEN @DecisionZH = 'Denied Without Prejudice' THEN 10020
         WHEN @DecisionZH = 'Approved' THEN 10003
         WHEN @DecisionZH = 'Approved with Pre-Release Conditions' THEN 10011
         ELSE 0
      END
   END

   IF @ResultCode = 10002  /* Denied */
   BEGIN
      IF @FolderType IN ('ZC', 'ZH') 
      BEGIN
         SELECT @LetterText1 = 'This is to inform you that the ' + @ReviewBody + ' ' + @DecisionZH + 
                @ProposalType + @FolderName + ' at its deliberative session on ' + 
                CONVERT(CHAR(11), @DRBDelibDate) + '. '
      END
      ELSE
      BEGIN
         SELECT @LetterText1 = 'This is to inform you that the ' + @ReviewBody + ' ' + @Decision + 
                @ProposalType + @FolderName + ' on ' + CONVERT(CHAR(11), @DecisionDate) + 
                '. Please see enclosed Reasons for Denial. '
      END
   END

   IF @ResultCode = 10020  /* Denied without Prejudice */
   BEGIN
      IF @FolderType IN ('ZC', 'ZH') 
      BEGIN
         SELECT @LetterText1 = 'This is to inform you that the ' + @ReviewBody + ' ' + @DecisionZH + 
                @ProposalType + @FolderName + ' at its deliberative session on ' + 
                CONVERT(CHAR(11), @DRBDelibDate) + 
                '. Denial without Prejudice allows you to return to the Development Review Board, with no additional fees, in order to address the specific reasons as adopted. '
      END
      ELSE
      BEGIN
         SELECT @LetterText1 = 'This is to inform you that the ' + @ReviewBody + ' ' + @Decision + 
                @ProposalType + @FolderName + ' on ' + CONVERT(CHAR(11), @DecisionDate) + 
                '. Please see enclosed Reasons for Denial. Denial without Prejudice allows you to return to the Development Review Board, with no additional fees, in order to address the specific reasons as adopted. '
      END
   END

   IF @ResultCode = 10003  /* Approved */
   BEGIN
      IF @FolderType IN ('ZC', 'ZH') 
      BEGIN
         SELECT @LetterText1 = 'Congratulations, the ' + @ReviewBody + ' ' + @DecisionZH + 
                @ProposalType + @FolderName + ' at its deliberative session on ' + 
                CONVERT(CHAR(11), @DRBDelibDate) + '. ' + 'You may pick up your permit after ' 
                + CONVERT(CHAR(11), @ExpiryDate) + '. '
      END
      ELSE
      BEGIN
         SELECT @LetterText1 = 'Congratulations, the ' + @ReviewBody + ' ' + @Decision + 
                @ProposalType + @FolderName + ' on ' + CONVERT(CHAR(11), @DecisionDate) + 
                '. Please see attached Conditions of Approval. You may pick up your permit after ' 
                + CONVERT(CHAR(11), @ExpiryDate) + '. '
      END
   END

   IF @ResultCode = 10011  /* Approved with PRC */
   BEGIN
      IF @FolderType IN ('ZC', 'ZH') 
      BEGIN
         SELECT @LetterText1 = 'Congratulations, the ' + @ReviewBody + ' ' + @DecisionZH + 
                @ProposalType + @FolderName + ' at its deliberative session on ' + 
                CONVERT(CHAR(11), @DRBDelibDate) + 
                '. This means that certain Conditions must be met before you can pick up your permit. '
      END
      ELSE
      BEGIN
      SELECT @LetterText1 = 'Congratulations, the ' + @ReviewBody + ' ' + @Decision + 
             @ProposalType + @FolderName + ' on ' + CONVERT(CHAR(11), @DecisionDate) + 
             '. Please see attached Conditions of Approval.  Note that certain Conditions must be met before you can pick up your permit. Your permit becomes eligible to pick up after ' 
             + CONVERT(CHAR(11), @ExpiryDate) + '. '
      END
   END

   IF @BalanceDue > 0 AND @ResultCode IN(10003, 10011)
   BEGIN
      SELECT @LetterText2 = 'A fee balance of $' + CAST(ROUND(@BalanceDue, 2) AS varchar(20)) + 
             ' is due at that time. '
   END
   ELSE SELECT @LetterText2 = NULL

   IF @Subcode = 10041
   BEGIN
      SELECT @LetterText3 = 'Decisions of the Zoning Administrator may be appealed to the Development Review Board within 15 days of the decision.  You must submit a notice of appeal to the Planning and Zoning office by ' + CONVERT(CHAR(11), @ExpiryDate) + '. '
   END
   ELSE
   BEGIN
      IF @FolderType IN('ZA', 'ZB', 'ZF', 'Z1', 'Z2', 'Z3')
      BEGIN
         SELECT @LetterText3 = 'Decisions of the Development Review Board may be appealed to the Vermont Superior Court Environmental Division within 30 days of the decision.  You must submit a notice of appeal to the Vermont Superior Court Environmental Division by ' + CONVERT(CHAR(11), @ExpiryDate) + '. '
         IF @WorkCode IN(10024, 10025, 10026, 10027)
         BEGIN
            SELECT @LetterText4 = 'Your project included ' + @WorkDesc + 
                   ' review. This constitutes a separate permit. The Findings of Fact containing the decision for the ' 
                   + @WorkDesc + 
                   ' is enclosed. The signature of the Chair constitutes the official decision date. Decisions of the Development Review Board regarding the ' 
                   + @WorkDesc + ' may be appealed to the Vermont Superior Court Environmental Division within 30 days of the signature date, and you must submit a notice of appeal to the Vermont Superior Court Environmental Division by ' + CONVERT(CHAR(11), @ExpiryDate) + '. '
         END
         ELSE 
         BEGIN
            SELECT @LetterText4 = NULL
         END
      END
      IF @FolderType IN ('ZC', 'ZH')
      BEGIN
         SELECT @LetterText3 = 'The Findings of Fact containing the ' + @WorkDesc + ' decision is enclosed. The signature of the Chair constitutes the official decision date.  Decisions of the Development Review Board may be appealed to the Vermont Superior Court Environmental Division within 30 days of the signature date, and you must submit a notice of appeal to the Vermont Superior Court Environmental Division by ' + CONVERT(CHAR(11), @ExpiryDate) + '. '
         SELECT @LetterText4 = NULL
      END
   END

   SELECT @LetterText = dbo.udf_RemoveSpecialChars(RTRIM(ISNULL(@LetterText1, '') + ' ' + ISNULL(@LetterText2, '') + ' ' + ISNULL(@LetterText3, '') + ' ' + ISNULL(@LetterText4, '')))

  RETURN @LetterText
END


GO
