#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") 
		 And FillingData.Property("RegistrationPeriod") Then
		Date = FillingData.RegistrationPeriod;
	EndIf;
	
	FillDefaultAttributes();
	
	If TypeOf(FillingData) = Type("DocumentRef.VATAllocation") Then 
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	VATAllocationLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	RevenueDetails = Documents.VATAllocation.ComplianceOfRevenueDetailsWithVATTaxationTypes();
	For Each KeyAndValue In RevenueDetails Do
		ThisObject[KeyAndValue.Value] = 0;
	EndDo;
	
	DocumentsExport.Clear();
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
	VATAllocationLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckDuplicateDocuments(Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	VATDistributionIsRequired = Documents.VATAllocation.VATDistributionIsRequired(Organization, Date);
	
	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	DatabaseIsFull = False;
	RevenueDetails = Documents.VATAllocation.ComplianceOfRevenueDetailsWithVATTaxationTypes();
	For Each KeyAndValue In RevenueDetails Do
		If ThisObject[KeyAndValue.Value] <> 0 Then
			DatabaseIsFull = True;
			Break;
		EndIf;
	EndDo;
	
	If VATDistributionIsRequired And Not DatabaseIsFull Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa xác định cơ sở để phân bổ Thuế GTGT. Không thể thực hiện phân bổ.';
				|ru = 'Не определена база распределения НДС. Распределение не может быть выполнено.';
				|en = 'VAT allocation base is not determined. Cannot allocate.'; fa = 'VAT allocation base is not determined. Cannot allocate.';
				|it = 'Non è definita la base di ripartizione IVA. Ripartizione non può essere eseguita.';
				|pl = 'Nie jest określona baza VAT. Podział nie może być dokonany.';
				|tr = 'KDV tahsisat tabanı belirlenmedi. Tahsisat gerçekleştirilemez.'"), ThisObject, , , Cancel);
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	VATAllocationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not AllocationBaseIsSetManually Then
		
		AdditionalRevenueGenerationParameters = New Structure();
		AdditionalRevenueGenerationParameters.Insert("DateOfDistribution", Date);
				
		Result = Documents.VATAllocation.GetVATDistributionBase(
						?(Patch, Common.ObjectAttributeValue(CorrectedDocument, "Date"), Date),
						BeginOfPeriod,
						Organization,
						AdditionalRevenueGenerationParameters);
		Documents.VATAllocation.FillInDistributionDatabase(ThisObject, Result);
			
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	VATAllocationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	VATAllocationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	If AdditionalProperties.Property("TTRegisterCacheManager") Then
		AddlParameters.Insert("TTRegisterCacheManager", AdditionalProperties.TTRegisterCacheManager);
		AddlParameters.Insert("BatchCalculationPeriod", AdditionalProperties.BatchCalculationPeriod);
	EndIf;
	If AdditionalProperties.Property("RoutineOperations") Then 
		AddlParameters.Insert("RoutineOperations", AdditionalProperties.RoutineOperations);
	EndIf;
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel, AddlParameters);
	
	If Not Cancel Then
		DocumentsArray = New Array;
		DocumentsArray.Add(Ref);
		VATAccountingERP.GenerateTasksBasedOnDocuments(DocumentsArray);
	EndIf;
	
	VATAllocationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	VATAllocationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#Region FillingInDocument_

Procedure FillDefaultAttributes()

	EmployeeResponsible	= Users.CurrentUser();
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	
	RulesForDebiting = Documents.VATAllocation.FillInRulesForDebitingVAT(Organization);
	FillPropertyValues(ThisObject, RulesForDebiting);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CheckDuplicateDocuments(Cancel)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	VATAllocation.Ref AS Ref
		|FROM
		|	Document.VATAllocation AS VATAllocation
		|WHERE
		|	VATAllocation.Posted
		|	AND VATAllocation.Organization = &Organization
		|	AND VATAllocation.Date BETWEEN &PeriodBeginning AND &PeriodEnd
		|	AND NOT VATAllocation.Patch
		|	AND NOT &Patch
		|	AND NOT VATAllocation.Ref = &CurrentDocument");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("PeriodBeginning", BegOfMonth(Date));
	Query.SetParameter("PeriodEnd", EndOfMonth(Date));
	Query.SetParameter("CurrentDocument", Ref);
	Query.SetParameter("Patch", Patch);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		PeriodPresentation = PeriodPresentation(BegOfMonth(Date), EndOfMonth(Date), "DLF=D");

		TextTemplate1 = NStr("vi = 'Trong kỳ ""%1"" đã có một chứng từ đã kết chuyển ""Phân bổ thuế GTGT"" cho doanh nghiệp %2';
							|ru = 'В  периоде ""%1"" уже есть проведенный документ ""Распределение НДС"" для организации %2';
							|en = 'Period ""%1"" already has a posted document ""VAT allocation"" for company %2'; fa = 'Period ""%1"" already has a posted document ""VAT allocation"" for company %2';
							|it = 'Nel periodo ""%1"" esiste già il documento registrato ""Ripartizione IVA"" per l''azienda %2';
							|pl = 'W okresie ""%1"" już jest zaksięgowany dokument ""Przydział VAT"" dla firmy %2';
							|tr = '""%1"" döneminde %2 iş yeri için zaten bir ""KDV dağıtımı"" belgesi bulunmaktadır'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, PeriodPresentation, Organization);
		
		CommonClientServer.MessageToUser(ErrorText, ThisObject, "Date", , Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
