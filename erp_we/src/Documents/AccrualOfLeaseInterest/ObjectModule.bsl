
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFillingItOut();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	CheckDuplicates(Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GenerateTasksForMonthEndTransactionsOnPosting();
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CreateTasksForEndOfMonthWhenEventIsCanceled();
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure CheckDuplicates(Cancel)

	If Not ValueIsFilled(Organization) 
		Or Not ValueIsFilled(Date) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	DocumentData.Ref
	|FROM
	|	Document.AccrualOfLeaseInterest AS DocumentData
	|WHERE
	|	DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.BusinessOperation = &BusinessOperation
	|	AND DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("BegOfMonth", BegOfMonth(Date));
	Query.SetParameter("EndOfMonth", EndOfMonth(Date));
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		TextTemplate1 = NStr("vi = 'Trong %1 đã có chứng từ kết chuyển với doanh nghiệp được chọn.';
							|ru = 'За %1 уже есть проведенный документ для выбранной организации.';
							|en = 'There already exists a posted document for the selected company for %1.'; fa = 'There already exists a posted document for the selected company for %1.';
							|it = 'Per %1 vi è già un documento pubblicato per l''organizzazione selezionata.';
							|pl = 'Za %1 jest już zatwierdzony dokument dla wybranej firmy.';
							|tr = '%1 kapsamında seçilen iş yeri için zaten kaydedilen belge mevcut.'");
		MessageText = StrTemplate(TextTemplate1, Format(Date, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																	|ru = 'ДФ=''ММММ гггг ""г.""''';
																	|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																	|it = 'ДФ=''ММММ гггг ""a.""''';
																	|pl = 'DF=''ММММ yyyy ""r.""''';
																	|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
		Common.MessageToUser(MessageText, ThisObject, "PackageNumber",, Cancel); 
	EndIf; 
	
EndProcedure

Procedure CreateTasksForEndOfMonthWhenEventIsCanceled()

	If AdditionalProperties.Property("CleaningForLaterUse") 
		And AdditionalProperties.CleaningForLaterUse Then
		Return;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.AccrualOfLeaseInterest Then
		If Documents.AccrualOfLeaseInterest.RentalInterestIsRequired(BegOfMonth(Date), Organization) Then
			
			InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
				BegOfMonth(Date), 
				Ref, 
				Organization, 
				Catalogs.MonthEndClosingOperations.AccrualOfLeaseInterest);
				
			EndIf;
	Else
		If Documents.AccrualOfLeaseInterest.AccrualOfInterestOnProfitableLeasesIsRequired(BegOfMonth(Date), Organization, False) Then
			
			InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
				BegOfMonth(Date), 
				Ref, 
				Organization, 
				Catalogs.MonthEndClosingOperations.AccrueProfitableRentalInterest);
				
			EndIf;
	EndIf;
		
EndProcedure

// Generate tasks for the end of the month when conducting.
// Creates tasks for the next month.
Procedure GenerateTasksForMonthEndTransactionsOnPosting()
	
	BeginningOfNextMonth = AddMonth(BegOfMonth(Date),1);
	If BusinessOperation = Enums.BusinessTransactions.AccrualOfLeaseInterest Then
		If Documents.AccrualOfLeaseInterest.RentalInterestIsRequired(BeginningOfNextMonth, Organization) Then
			
			InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
				BeginningOfNextMonth,
				Ref,
				Organization,
				Catalogs.MonthEndClosingOperations.AccrualOfLeaseInterest);
				
		EndIf;
	Else
		If Documents.AccrualOfLeaseInterest.AccrualOfInterestOnProfitableLeasesIsRequired(BeginningOfNextMonth, Organization, False) Then
			
			InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
				BeginningOfNextMonth,
				Ref,
				Organization,
				Catalogs.MonthEndClosingOperations.AccrueProfitableRentalInterest);
				
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
