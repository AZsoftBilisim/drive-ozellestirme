#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		Raise Documents.ARAPReconciliation2_4.MessageTextIsOutdatedDocument();
	EndIf;
	
	// Let's clear the tabular parts of the document.
	CounterpartyData.Clear();
	GroupingsARAP.Clear();
	DetailedRecordsARAPAccounting.Clear();
	GroupingsFinancialInstruments.Clear();
	DetailedRecordsFinancialInstruments.Clear();
	
	Status = Enums.StatusesOfARAPReconciliation.CreatedOn_;
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Manager = Users.CurrentUser();
	Author = Users.CurrentUser();
	
	StructureOfData = New Structure;
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		Documents.ARAPReconciliation2_4.StructureAttributesResponsiblePersons());
	StructureOfData.Insert(
		"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
		Documents.ARAPReconciliation2_4.StructureAttributesResponsiblePersonsOfCounterpartyOrganization());
	
	AdditionalProperties.Insert("ResponsiblePersons", StructureOfData);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	ThereAreDiscrepancies = False;
	If TypeOf(FillingData) = Type("Structure") Then
		FillInDocumentAccordingToAssistant(FillingData);
	EndIf;
	InitializeDocument(FillingData);
	
	StructureOfData = New Structure;
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		Documents.ARAPReconciliation2_4.StructureAttributesResponsiblePersons());
	StructureOfData.Insert(
		"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
		Documents.ARAPReconciliation2_4.StructureAttributesResponsiblePersonsOfCounterpartyOrganization());
	
	AdditionalProperties.Insert("ResponsiblePersons", StructureOfData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckIfPeriodIsCorrect(Cancel);
	
	NotCheckedAttributeArray = New Array;
	If ValueIsFilled(PaymentType_) Then
		NotCheckedAttributeArray.Add("GroupingsARAP.PaymentType_");
	EndIf;
	
	If ValueIsFilled(Partner) Then
		NotCheckedAttributeArray.Add("GroupingsARAP.Partner");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
	StructureOfData = New Structure;
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		Documents.ARAPReconciliation2_4.StructureAttributesResponsiblePersons());
	StructureOfData.Insert(
		"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
		Documents.ARAPReconciliation2_4.StructureAttributesResponsiblePersonsOfCounterpartyOrganization());
	
	AdditionalProperties.Insert("ResponsiblePersons", StructureOfData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf; 

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	SetPropertiesForChangingBankingDetails(ThisObject, AdditionalProperties);
	
	DeleteHungSubdividedLines("GroupingsARAP", "DetailedRecordsARAPAccounting", "ARAPObject");
	DeleteHungSubdividedLines("GroupingsFinancialInstruments", "DetailedRecordsFinancialInstruments", "Contract");
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined) Export
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.StatusesOfARAPReconciliation.CreatedOn_;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = CurrentSessionDate();
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(ContactPerson) Then
		ContactPerson = PartnersAndCounterparties.GetDefaultCounterpartyPartnerContactPerson(Counterparty);
	EndIf;
	
EndProcedure

Procedure FillInDocumentAccordingToAssistant(FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	FillingData.Insert("Date", Date);
	
	DocumentData = Documents.ARAPReconciliation2_4.DetailsOfLastDocument(Counterparty);
	FillPropertyValues(ThisObject, DocumentData, "FullNameOfCounterpartyExecutive, JobTitleOfCounterpartyExecutive");
	
	If FillingData.Property("Filter_Settings") Then
		SetSelectionsForEquality(FillingData);
		Filter_Settings = New ValueStorage(FillingData.Filter_Settings);
	EndIf;
	
	Documents.ARAPReconciliation2_4.FillInCalculationData(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders.
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.StatusesOfARAPReconciliation[NewStatus];
	
	Return CheckFilling();
	
EndFunction

Procedure CheckIfPeriodIsCorrect(Cancel)
	
	If ValueIsFilled(BeginOfPeriod)
	 And ValueIsFilled(EndOfPeriod)
	 And BeginOfPeriod > EndOfPeriod Then
	 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ngày đầu kỳ không được lớn hơn ngày cuối kỳ %1';
				|ru = 'Дата начала периода не должна быть больше окончания периода %1';
				|en = 'Period start date cannot exceed period end date %1'; fa = 'Period start date cannot exceed period end date %1';
				|it = 'Дата начала периода не должна быть больше окончания периода %1';
				|pl = 'Data rozpoczęcia okresu nie może być większa niż koniec okresu %1';
				|tr = 'Dönemin başlangıç tarihi, %1dönemin bitiş tarihinden sonra olmamalıdır'"),
			Format(EndOfPeriod, "DLF=DD"));
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"BeginOfPeriod",
			, // DataPath
			Cancel);
	 
	EndIf;
	
EndProcedure

Procedure SetSelectionsForEquality(FillingData)
	
	FilterFields = New Array();
	FilterFields.Add("PaymentType_");
	FilterFields.Add("Partner");
	FilterFields.Add("Contract");
	If GetFunctionalOption("UseMultipleCompanies") Then
		FilterFields.Add("Organization");
	EndIf;
	FilterFields.Add("Counterparty");
	
	Filter = FillingData.Filter_Settings.Filter;
	For Each FilterField In FilterFields Do
		SplitDocuments = True;
		If FilterField = "PaymentType_" Then
			SplitDocuments = FillingData.SplitByARAPTypes;
			
		ElsIf FilterField = "Partner" Then
			SplitDocuments = FillingData.SplitByPartners;
			
		ElsIf FilterField = "Contract" Then
			SplitDocuments = FillingData.SplitByContracts;
			
		EndIf;
		If SplitDocuments Then
			FinancialReportingServer.SetFilter(Filter, FilterField, FillingData[FilterField], DataCompositionComparisonType.Equal, SplitDocuments);
		EndIf;
	EndDo;
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(Filter, "ContractsWithoutTurnover");
	FilterContractsWithoutTurnover.Use = FillingData.ContractsWithoutTurnover;
	
EndProcedure

Procedure SetPropertiesForChangingBankingDetails(Object, Var_AdditionalProperties)
		
	OnlyVerifiedOnReconciliationStatusHasChanged = False;
	
	If Object.Posted Then
		
		AttributesNotToCheck = New Structure;
		AttributesNotToCheck.Insert("Comment");
		AttributesNotToCheck.Insert("Filter_Settings");
		
		DocumentChanges = TMCommonUse.DocumentChanges(Object, AttributesNotToCheck);
		
		OtherDetailsChanged = False;
		ChangedStatus_ = False;
		
		If DocumentChanges.Property("TabularSections") Then
			OtherDetailsChanged = True;
		EndIf;                                  
		
		If DocumentChanges.Property("Attributes") Then
			If DocumentChanges.Attributes.Find("Status", "Name") <> Undefined Then
				ChangedStatus_ = True;
			EndIf;
			For Each Attribute In DocumentChanges.Attributes Do
				If Attribute.Name <> "Status" Then
					OtherDetailsChanged = True;
					Break;
				EndIf;
			EndDo;
		EndIf;                                    
		
		OnlyVerifiedOnReconciliationStatusHasChanged = ChangedStatus_ And Not OtherDetailsChanged;
		
	EndIf;
	
	Var_AdditionalProperties.Insert("OnlyVerifiedOnReconciliationStatusHasChanged", OnlyVerifiedOnReconciliationStatusHasChanged);
	
EndProcedure

Procedure DeleteHungSubdividedLines(TSGroups, TSDetailedRecords, LinksField)
	
	Documents.ARAPReconciliation2_4.DeleteHungSubdividedLines(ThisObject, TSGroups, TSDetailedRecords, LinksField);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
