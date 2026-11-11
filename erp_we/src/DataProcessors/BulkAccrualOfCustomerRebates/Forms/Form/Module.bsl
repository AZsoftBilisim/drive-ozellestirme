//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Basis.IsEmpty() Then
		
		URBDocument = Parameters.Basis;
		URBData = Common.ObjectAttributesValues(URBDocument, "Patch, CorrectedDocument");
		
		If URBData.Patch Then
			Object.TermDocument = URBData.CorrectedDocument;
		Else
			Object.TermDocument = URBDocument;
		EndIf;
		
		FillInDetailsAccordingToCondition();
		
		CurrentStartDate = Object.BeginOfPeriod;
		CurrentEndDate = Object.PeriodEnding;
		CurrentCurrency = Object.Currency;
		
	EndIf;
	
	FillInDataOfLastAdjustment();
	SetTitleOfSceneryFixingComposition();
	UpdateFlagForPossibilityOfChangingURB();
	ConfigureFormVisibilityAccessibility();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TermDocumentOnChange(Item)
	
	ClearMessages();
	TermDocumentOnChangeServer();
	CurrentStartDate = Object.BeginOfPeriod;
	CurrentEndDate = Object.PeriodEnding;
	CurrentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure TermDocumentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.TermDocument = PredefinedValue("Document.ConditionsOfCustomerRebates.EmptyRef");
	ClearDetailsByCondition(ThisObject);
	ConfigureFormVisibilityAccessibility();
	
	CurrentStartDate = Object.BeginOfPeriod;
	CurrentEndDate = Object.PeriodEnding;
	CurrentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Async Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Cancel = False;
	If Object.BeginOfPeriod <> CurrentStartDate
	   And Object.AccrualDocuments.Count() > 0 Then
		
		ContinueOperation = Await ContinueOfOperationWithClearingAccrualDocuments();
		If Not ContinueOperation Then
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	If Cancel Then
		
		Object.BeginOfPeriod = CurrentStartDate;
		
	Else
		
		Object.AccrualDocuments.Clear();
		CalculateTotals_(ThisObject);
		CurrentStartDate = Object.BeginOfPeriod;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Cancel = False;
	If Object.PeriodEnding <> CurrentEndDate
	   And Object.AccrualDocuments.Count() > 0 Then
		
		ContinueOperation = Await ContinueOfOperationWithClearingAccrualDocuments();
		If Not ContinueOperation Then
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	If Cancel Then
		
		Object.PeriodEnding = CurrentEndDate;
		
	Else
		
		Object.AccrualDocuments.Clear();
		CalculateTotals_(ThisObject);
		CurrentEndDate = Object.PeriodEnding;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CurrencyOnChange(Item)
	
	Cancel = False;
	If Object.Currency <> CurrentCurrency
	   And Object.AccrualDocuments.Count() > 0 Then
		
		ContinueOperation = Await ContinueOfOperationWithClearingAccrualDocuments();
		If Not ContinueOperation Then
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	If Cancel Then
		
		Object.Currency = CurrentCurrency;
		
	Else
		
		Object.AccrualDocuments.Clear();
		CalculateTotals_(ThisObject);
		CurrentCurrency = Object.Currency;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationFixCompositionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	RefToProcess = "Commit";
	
	If FormattedStringURL = RefToProcess Then
		FixCompositionOfConditionsDocument();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccrualDocuments

&AtClient
Procedure AccrualDocumentsCounterpartyOnChange(Item)
	
	FillInDataOfAccrualDocumentInLine();
	
EndProcedure

&AtClient
Procedure AccrualDocumentsPartnerOnChange(Item)
	
	FillInDataOfAccrualDocumentInLine();
	
EndProcedure

&AtClient
Procedure AccrualDocumentsAmountToAccrueOnChange(Item)
	
	CurrentData = Items.AccrualDocuments.CurrentData;
	
	If CurrentData.AmountToAccrue <> 0 Then
		
		CurrentData.Check = True;
		
	ElsIf CurrentData.Check Then
		
		CurrentData.Check = False;
		
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AccrualDocumentsAfterDeleteRow(Item)
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AccrualDocumentsOnChange(Item)
	
	CurrentData = Items.AccrualDocuments.CurrentData;
	If CurrentData <> Undefined
	   And Not ValueIsFilled(CurrentData.DocumentAccruals) Then
		CurrentData.PictureIndex = -1;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.AccrualDocuments.CurrentItem = Items.AccrualDocumentsDocumentAccruals Then
		
		StandardProcessing = False;
		RowData = Items.AccrualDocuments.CurrentData;
		
		If RowData <> Undefined
		   And Not RowData.DocumentAccruals.IsEmpty() Then
			
			OpenValueAsync(RowData.DocumentAccruals);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDateInterval(Command)
	
	CallbackOnCompletion = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	PeriodParameters_ = New Structure("StartDate, EndDate", "BeginOfPeriod", "PeriodEnding");
	
	TMCommonUseClient.EditPeriod(Object, PeriodParameters_, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure SelectAllItems(Command)
	
	FillInMarkInLines(True);
	
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	
	FillInMarkInLines(False);
	
EndProcedure

&AtClient
Procedure GenerateDocuments(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	FillInCheckPassed = CheckFilling();
	If Not FillInCheckPassed Then
		Cancel = True;
	Else
		
		CheckNotes(Cancel);
		CheckWhetherCompositionOfConditionsDocumentHasBeenFixed(Cancel);
		
	EndIf;
	
	If Not Cancel Then
		CheckDuplicatesOfParticipants(Cancel);
	EndIf;
	
	If Not Cancel Then
		
		AddressOfDataToGenerate = DataOfDocumentsToBeGenerated();
		CalculationParameters = RebatesCalculationParameters();
		GenerationParameters = DocumentGenerationParameters();
		
		CallbackOnCompletion = New CallbackDescription("GenerateDocumentsCompletion", ThisObject);
		
		CommonClientServer.SetFormItemProperty(
			Items,
			Items.FormGenerateDocuments.Name,
			"Enabled",
			False);
		
		RebatesClient.GenerateAccrualDocuments(
			AddressOfDataToGenerate,
			CalculationParameters,
			GenerationParameters,
			ThisObject,
			CallbackOnCompletion);
			
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

&AtClient
Async Procedure FillInAccordingToConditions(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.TermDocument) Then
		
		FieldPresentation = NStr("vi = 'Chứng từ điều kiện';
								|ru = 'Документ условий';
								|en = 'Condition document'; fa = 'سند شرایط';
								|it = 'Документ условий';
								|pl = 'Condition document';
								|tr = 'Koşullar Belgesi'");
		MessageText = CommonClientServer.FillingErrorText(,, FieldPresentation);
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	Else
		
		CheckHeaderFilling(Cancel);
		CheckPeriodsByTimeFence(Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		CheckWhetherCompositionOfConditionsDocumentHasBeenFixed(Cancel);
		
	EndIf;
	
	If Not Cancel
	   And Object.AccrualDocuments.Count() > 0 Then
		
		QueryText = NStr("vi = 'Phần bảng sẽ bị xóa.
								  |Tiếp tục?';
								  |ru = 'Табличная часть будет очищена.
								  |Продолжить?';
								  |en = 'The table will be cleared.
								  |Continue?'; fa = 'The table will be cleared.
								  |Continue?';
								  |it = 'Табличная часть будет очищена.
								  |Продолжить?';
								  |pl = 'The table will be cleared.
								  |Continue?';
								  |tr = 'Tablo kısmı temizlenecektir. 
								  |Devam?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		CalculationParameters = RebatesCalculationParameters();
		CallbackOnCompletion = New CallbackDescription("FillInAccrualsAccordingToEndConditions", ThisObject);
		
		CommonClientServer.SetFormItemProperty(
			Items,
			Items.AccrualDocumentsFillInAccordingToConditions.Name,
			"Enabled",
			False);
		
		RebatesClient.RebatesForPeriodAccordingToSalesDocuments(
			CalculationParameters,
			ThisObject,
			CallbackOnCompletion);
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDetailsAccordingToCondition()
	
	If ValueIsFilled(Object.TermDocument) Then
		
		Object.AccrualDocuments.Clear();
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.TermDocument);
		
		Object.Organization = TermsAndConditionsAttributes.Organization;
		Object.BeginOfPeriod = TermsAndConditionsAttributes.ValidOnDate;
		Object.PeriodEnding = TermsAndConditionsAttributes.ValidTo;
		Object.Currency = TermsAndConditionsAttributes.Currency;
		
		If Not ValueIsFilled(Object.Currency)
		   And TermsAndConditionsAttributes.SalesCalculationBase = Enums.RebateCalculationBases.RevenueARAPAccounting
		   And Not GetFunctionalOption("UseMultipleCurrencies") Then
			
			Object.Currency = Catalogs.Currencies.GetDefaultCurrency();
			CurrentCurrency = Object.Currency;
			
		Else
			
			CurrentCurrency = TermsAndConditionsAttributes.Currency;
			
		EndIf;
		
		WithoutCalculation = TermsAndConditionsAttributes.WithoutCalculation;
		AccrualFrequency = TermsAndConditionsAttributes.AccrualFrequency;
		PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
		SalesCalculationBase = TermsAndConditionsAttributes.SalesCalculationBase;
		CurrentStartDate = TermsAndConditionsAttributes.ValidOnDate;
		CurrentEndDate = TermsAndConditionsAttributes.ValidTo;
		StartDateOfCondition = TermsAndConditionsAttributes.ValidOnDate;
		EndDateOfCondition = TermsAndConditionsAttributes.ValidTo;
		ConsiderVAT = TermsAndConditionsAttributes.ConsiderVAT;
		
		UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes);
		CompositionOfSegmentsIsFixed = TermsAndConditionsAttributes.RecordingIsCompleted;
		
		UpdateFlagForPossibilityOfChangingURB();
		CalculateTotals_(ThisObject);
		
	Else
		
		ClearDetailsByCondition(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormVisibilityAccessibility()
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	ElementNamesVisibilityAll = New Array; // Array of String
	ElementNamesVisibilityAll.Add(Items.AccrualDocumentsCounterparty.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualDocumentsPartner.Name);
	ElementNamesVisibilityAll.Add(Items.BeginOfPeriod.Name);
	ElementNamesVisibilityAll.Add(Items.PeriodEnding.Name);
	ElementNamesVisibilityAll.Add(Items.SetDateInterval.Name);
	ElementNamesVisibilityAll.Add(Items.DecorationFixComposition.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualDocumentsFillInAccordingToConditions.Name);
	ElementNamesVisibilityAll.Add(Items.Currency.Name);
	
	ItemNamesOnlyViewAll = New Array; // Array of String
	ItemNamesOnlyViewAll.Add(Items.BeginOfPeriod.Name);
	ItemNamesOnlyViewAll.Add(Items.PeriodEnding.Name);
	ItemNamesOnlyViewAll.Add(Items.Currency.Name);
	
	NamesOfVisibleElements = New Array; // Array of String
	If Not Object.TermDocument.IsEmpty() Then
		
		NamesOfVisibleElements.Add(Items.BeginOfPeriod.Name);
		NamesOfVisibleElements.Add(Items.PeriodEnding.Name);
		NamesOfVisibleElements.Add(Items.Currency.Name);
		
		If AccrualFrequency <> Enums.RebatesFrequencies.Single Then
			NamesOfVisibleElements.Add(Items.SetDateInterval.Name);
		EndIf;
		
	EndIf;
	
	If PartyCountDetails = Detailing.ByCounterparty Then
		
		NamesOfVisibleElements.Add(Items.AccrualDocumentsCounterparty.Name);
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		NamesOfVisibleElements.Add(Items.AccrualDocumentsPartner.Name);
		
	ElsIf PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		NamesOfVisibleElements.Add(Items.AccrualDocumentsCounterparty.Name);
		NamesOfVisibleElements.Add(Items.AccrualDocumentsPartner.Name);
		
	EndIf;
	
	If CompositionFixationIsAvailable 
	   And Not CompositionOfSegmentsIsFixed Then
		
		NamesOfVisibleElements.Add(Items.DecorationFixComposition.Name);
		
	EndIf;
	
	If Not WithoutCalculation Then
		
		NamesOfVisibleElements.Add(Items.AccrualDocumentsFillInAccordingToConditions.Name);
		
	EndIf;
	
	ItemNamesAreViewOnly = New Array; // Array of String
	If AccrualFrequency = Enums.RebatesFrequencies.Single Then
		
		ItemNamesAreViewOnly.Add(Items.BeginOfPeriod.Name);
		ItemNamesAreViewOnly.Add(Items.PeriodEnding.Name);
		
	EndIf;
	
	If SalesCalculationBase <> Enums.RebateCalculationBases.RevenueARAPAccounting
	 Or WithoutCalculation Then
		
		ItemNamesAreViewOnly.Add(Items.Currency.Name);
		
	EndIf;
	
	Items.DecorationFixComposition.Enabled = ThereIsRightToChangeURB;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items, ElementNamesVisibilityAll, NamesOfVisibleElements);
	
	RebatesClientServer.SetOnlyViewOfElementsByArray(
		Items, ItemNamesOnlyViewAll, ItemNamesAreViewOnly);
	
EndProcedure

&AtServer
Procedure CheckRebateKindOfTermsAndConditionsDocument()
	
	AllowedToUse = True;
	If ValueIsFilled(Object.TermDocument) Then
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.TermDocument);
		ContentOfGoods = TermsAndConditionsAttributes.ContentOfGoods;
		IDOfAttribute = TermsAndConditionsAttributes.ProductItemProperty;
		
		If ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
		
			CheckResult = RebatesServer.ItemPropertyVerificationData(IDOfAttribute);
			AllowedToUse = CheckResult.AllowedToUse;
			If Not AllowedToUse Then
				
				FieldName = "TermDocument";
				RebatesServer.ReportItemPropertiesError(CheckResult, FieldName);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		Items.FormGenerateDocuments.Name,
		"Enabled",
		AllowedToUse);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearDetailsByCondition(Form)
	
	DateEmpty = Date(1, 1, 1);
	
	Object = Form.Object;
	Object.AccrualDocuments.Clear();
	
	Object.BeginOfPeriod = DateEmpty;
	Form.CurrentStartDate = DateEmpty;
	Form.StartDateOfCondition = DateEmpty;
	Object.PeriodEnding = DateEmpty;
	Form.CurrentEndDate = DateEmpty;
	Form.EndDateOfCondition = DateEmpty;
	Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	Form.CurrentCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
	
	Form.WithoutCalculation = False;
	Form.PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef");
	Form.AccrualFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef");
	Form.SalesCalculationBase = PredefinedValue("Enum.RebateCalculationBases.EmptyRef");
	Form.CompositionFixationIsAvailable = False;
	Form.CompositionOfSegmentsIsFixed = False;
	Form.ThereIsRightToChangeURB = False;
	Form.ConsiderVAT = False;
	
	CalculateTotals_(Form);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CompanyIsSpecified = Not Object.Organization.IsEmpty();
	
	If CompanyIsSpecified Then
		
		If Not Object.TermDocument.IsEmpty() Then
			
			DocumentOrganization = Common.ObjectAttributeValue(Object.TermDocument, "Organization");
			If DocumentOrganization <> Object.Organization Then
				
				Object.TermDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
				ClearDetailsByCondition(ThisObject);
				ConfigureFormVisibilityAccessibility();
				
			EndIf;
			
		EndIf;
		
	Else
		
		Object.TermDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
		ClearDetailsByCondition(ThisObject);
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	EstablishRelationshipsBetweenParametersForSelectingConditionDocument();
	
EndProcedure

&AtServer
Procedure EstablishRelationshipsBetweenParametersForSelectingConditionDocument()
	
	ChoiceParameterLinks = New Array(); // Array of ChoiceParameterLink
	
	If Not Object.Organization.IsEmpty() Then
		
		NewLink = New ChoiceParameterLink(
			"Filter.Organization",
			"Object.Organization",
			LinkedValueChangeMode.DontChange);
		
		ChoiceParameterLinks.Add(NewLink);
		
	EndIf;
	
	Items.TermDocument.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
EndProcedure

&AtClient
Procedure FillInMarkInLines(Check)
	
	For Each DocumentLine In Object.AccrualDocuments Do
		
		DocumentLine.Check = Check;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInDataOfAccrualDocumentInLine()
	
	CurrentData = Items.AccrualDocuments.CurrentData;
	RowData = DataStructureOfAccrualLine(CurrentData);
	
	FillInDataOfAccrualDocumentInLineData(RowData);
	
	CurrentData.DocumentAccruals = RowData.DocumentAccruals;
	CurrentData.AmountAccrued = RowData.AmountAccrued;
	If ValueIsFilled(CurrentData.DocumentAccruals) Then
		CurrentData.PictureIndex = 1;
	Else
		CurrentData.PictureIndex = 0;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInDataOfAccrualDocumentInLineData(RowData)
	
	RowData.DocumentAccruals = Documents.AccrualOfCustomerRebates.EmptyRef();
	RowData.AmountAccrued = 0;
	
	Query = New Query;
	Query.Text = QueryTextForReceiptOfAccrualDocuments();
	Query.SetParameter("TermDocument", Object.TermDocument);
	Query.SetParameter("Counterparty", RowData.Counterparty);
	Query.SetParameter("Partner", RowData.Partner);
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", Object.PeriodEnding);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(RowData, Selection);
		
	EndIf;
	
EndProcedure

&AtServer
Function QueryTextForReceiptOfAccrualDocuments()
	
	QueryText =
	"SELECT DISTINCT
	|	CAST(CustomerRebatesTurnovers.Recorder AS Document.AccrualOfCustomerRebates) AS DocumentAccruals,
	|	CustomerRebatesTurnovers.AmountBonusTurnover AS AmountAccrued
	|FROM
	|	AccumulationRegister.CustomerRebates.Turnovers(,, Recorder,
	|		TermDocument = &TermDocument
	|		AND &ConditionCounterpartyPartner
	|		AND Currency = &Currency
	|		AND BeginOfPeriod = &BeginOfPeriod
	|		AND PeriodEnding = &PeriodEnding) AS CustomerRebatesTurnovers
	|WHERE
	|	VALUETYPE(CustomerRebatesTurnovers.Recorder) = TYPE(Document.AccrualOfCustomerRebates)";
	
	If PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCustomer Then
		
		ConditionText = "Partner = &Partner";
		
	ElsIf PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty Then
		
		ConditionText = "Counterparty = &Counterparty";
		
	ElsIf PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterpartyAndCustomer Then
		
		ConditionText = "Counterparty = &Counterparty
					   |AND Partner = &Partner";
		
	Else
		
		ConditionText = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionCounterpartyPartner", ConditionText);
	Return QueryText;
	
EndFunction

// Parameters:
//  RowData - FormDataCollectionItem:
//  * Counterparty - CatalogRef.Counterparties
//  * Partner - CatalogRef.Partners
//  * DocumentAccruals - DocumentRef.AccrualOfCustomerRebates
//  * AmountAccrued - Number
// 
// Returns:
//  Structure - Data Structure of the Accrual Line:
//  * Counterparty - CatalogRef.Counterparties
//  * Partner - CatalogRef.Partners
//  * DocumentAccruals - DocumentRef.AccrualOfCustomerRebates
//  * AmountAccrued - Number
//
&AtClient
Function DataStructureOfAccrualLine(RowData)
	
	Result = New Structure;
	Result.Insert(
		"Counterparty",
		PredefinedValue("Catalog.Counterparties.EmptyRef"));
	Result.Insert(
		"Partner",
		PredefinedValue("Catalog.Partners.EmptyRef"));
	Result.Insert(
		"DocumentAccruals",
		PredefinedValue("Document.AccrualOfCustomerRebates.EmptyRef"));
	Result.Insert(
		"AmountAccrued",
		0);
	
	FillPropertyValues(Result, RowData);
	
	Return Result;
	
EndFunction

&AtServer
Procedure UpdateFlagForPossibilityOfChangingURB()
	
	If ValueIsFilled(Object.TermDocument) Then
		ThereIsRightToChangeURB = AccessManagement.EditionAllowed(Object.TermDocument);
	Else
		ThereIsRightToChangeURB = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccrualsAccordingToServerConditions(ResultAddress)
	
	Object.AccrualDocuments.Clear();
	
	DocumentsTable = TableOfAccrualDocumentsAccordingToSystemData(ResultAddress);
	
	For Each DataOfSystem In DocumentsTable Do
		
		NewRow = Object.AccrualDocuments.Add();
		FillPropertyValues(NewRow, DataOfSystem);
		If Not ValueIsFilled(DataOfSystem.DocumentAccruals) Then
			
			NewRow.PictureIndex = -1;
			
		ElsIf DataOfSystem.Posted Then
			
			NewRow.PictureIndex = 1;
			
		Else
			
			NewRow.PictureIndex = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function TableOfAccrualDocumentsAccordingToSystemData(ResultAddress)
	
	FillParameters = DataProcessors.BulkAccrualOfCustomerRebates.ParametersForFillingInAccrualTable();
	FillParameters.BonusTable = RebatesBasedOnSalesDocuments(ResultAddress);
	FillParameters.TermDocument = Object.TermDocument;
	FillParameters.Currency = Object.Currency;
	FillParameters.BeginOfPeriod = Object.BeginOfPeriod;
	FillParameters.PeriodEnding = Object.PeriodEnding;
	FillParameters.PartyCountDetails = PartyCountDetails;
	
	DocumentsTable = DataProcessors.BulkAccrualOfCustomerRebates.TableOfAccrualDocumentsAccordingToSystemData(FillParameters);
	
	Return DocumentsTable;
	
EndFunction

&AtServer
Function RebatesCalculationParameters()
	
	CalculationParameters = Reports.CalculateCustomerRebates.RebatesCalculationParameters();
	CalculationParameters.TermDocument = Object.TermDocument;
	CalculationParameters.Organization = Object.Organization;
	CalculationParameters.StartDate = Object.BeginOfPeriod;
	CalculationParameters.EndDate = Object.PeriodEnding;
	CalculationParameters.Currency = Object.Currency;
	If ValueIsFilled(Object.DocumentsCreationDate) Then
		CalculationParameters.DocumentsCreationDate = Object.DocumentsCreationDate;
	Else
		CalculationParameters.DocumentsCreationDate = CurrentSessionDate();
	EndIf;
	Return CalculationParameters;
	
EndFunction

&AtServer
Function DocumentGenerationParameters()
	
	GenerationParameters = DataProcessors.BulkAccrualOfCustomerRebates.DocumentGenerationParameters();
	GenerationParameters.PartyCountDetails = PartyCountDetails;
	GenerationParameters.WithoutCalculation = WithoutCalculation;
	GenerationParameters.PostWithoutRebateBalanceCheck =
		SessionParameters.PostWithoutRebateBalanceCheck;
	
	If SalesCalculationBase = Enums.RebateCalculationBases.RevenueARAPAccounting
	 Or SalesCalculationBase = Enums.RebateCalculationBases.RevenueLocalAccounting
	 Or SalesCalculationBase = Enums.RebateCalculationBases.RevenueManagementAccounting Then
		
		If ConsiderVAT Then
			
			GenerationParameters.RevenueColumnName = "RevenueAmount";
			
		Else
			
			GenerationParameters.RevenueColumnName = "RevenueAmountExcludingVAT";
			
		EndIf;
		
	ElsIf SalesCalculationBase = Enums.RebateCalculationBases.RevenueBasePrices Then
		
		GenerationParameters.RevenueColumnName = "AmountInBasePrices";
		
	ElsIf Not WithoutCalculation
	        And Not SalesCalculationBase.IsEmpty() Then
		
		ExceptionPattern = NStr("vi = 'Đối với cơ sở tính toán ""%1"" chưa xác định quy tắc điền số tiền doanh thu';
								|ru = 'Для базы расчета ""%1"" не определены правила заполнения суммы выручки';
								|en = 'Rules for filling the revenue amount are not defined for the ""%1"" calculation base'; fa = 'Rules for filling the revenue amount are not defined for the ""%1"" calculation base';
								|it = 'Для базы расчета ""%1"" не определены правила заполнения суммы выручки';
								|pl = 'Rules for filling the revenue amount are not defined for the ""%1"" calculation base';
								|tr = 'Gelir miktarının doldurulmasına ilişkin kurallar “%1” hesaplama tabanı için tanımlanmamıştır'");
		BasePresentation = Common.RefsPresentations(SalesCalculationBase);
		
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionPattern,
			BasePresentation[SalesCalculationBase]);
		
		Raise ExceptionText;
		
	EndIf;
	
	Return GenerationParameters;
	
EndFunction

// Parameters:
//  ResultAddress - String
// 
// Returns:
//  ValueTable:
//  * Currency - CatalogRef.Currencies
//  * DocumentSales - DocumentRef.CustomerInvoice, DocumentRef.SaleAdjustment, DocumentRef.CustomerInvoiceServices, DocumentRef.ReturnOfGoodsFromCustomer -
//  * Counterparty - CatalogRef.Counterparties
//  * Organization - CatalogRef.Companies
//  * Partner - CatalogRef.Partners
//  * CalculationBase - Number
//  * AmountBonus - Number
//  * AmountInBasePrices - Number
//  * RevenueAmount - Number
//  * RevenueAmountExcludingVAT - Number
//
&AtServerNoContext
Function RebatesBasedOnSalesDocuments(ResultAddress)
	
	BonusTable = GetFromTempStorage(ResultAddress);
	
	Return BonusTable;
	
EndFunction

&AtClient
Procedure CheckHeaderFilling(Cancel)
	
	ListOfVerifiedDetails = New ValueList; // ValueList of String
	PresentationBeginningOfPeriod = NStr("vi = 'Đầu kỳ';
										|ru = 'Начало периода';
										|en = 'Period start'; fa = 'شروع دوره';
										|it = 'Начало периода';
										|pl = 'Początek okresu';
										|tr = 'Dönem başı'");
	ListOfVerifiedDetails.Add("BeginOfPeriod", PresentationBeginningOfPeriod);
	PresentationEndOfPeriod = NStr("vi = 'Kết thúc kỳ';
									|ru = 'Окончание периода';
									|en = 'Period end'; fa = 'پایان دوره';
									|it = 'Окончание периода';
									|pl = 'Koniec okresu';
									|tr = 'Dönem sonu'");
	ListOfVerifiedDetails.Add("PeriodEnding", PresentationEndOfPeriod);
	ListOfVerifiedDetails.Add("Currency");
	
	For Each AttributeData In ListOfVerifiedDetails Do
		
		AttributeName = AttributeData.Value;
		If ValueIsFilled(AttributeData.Presentation) Then
			AttributeSynonym = AttributeData.Presentation; // String
		Else
			AttributeSynonym = AttributeName; // String
		EndIf; 
		
		If Not ValueIsFilled(Object[AttributeName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(,, AttributeSynonym);
			CommonClient.MessageToUser(ErrorText,, AttributeName, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckWhetherCompositionOfConditionsDocumentHasBeenFixed(Cancel)
	
	UpdateDataAboutFixationOfComposition();
	ItIsNecessaryToFixComposition = (CompositionFixationIsAvailable And Not CompositionOfSegmentsIsFixed);
	
	If Not TermsDocumentHasBeenAgreed Then
		
		MessageText = NStr("vi = 'Chưa thống nhất chứng từ điều kiện';
							|ru = 'Документ условий не согласован';
							|en = 'The condition document is not approved'; fa = 'The condition document is not approved';
							|it = 'Документ условий не согласован';
							|pl = 'The condition document is not approved';
							|tr = 'Koşullar belgesi kabul edilmemiş'");
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	ElsIf ItIsNecessaryToFixComposition Then
		
		MessageText = NStr("vi = 'Chưa ghi nhận thành phần chứng từ điều kiện';
							|ru = 'Не зафиксирован состав документа условий';
							|en = 'Condition document is not recorded'; fa = 'Condition document is not recorded';
							|it = 'Condition document is not recorded';
							|pl = 'Condition document is not recorded';
							|tr = 'Şartlar belgesinin içeriği sabitlenmedi'");
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FillInAccrualsAccordingToEndConditions(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			
			StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
			UpdateDataAboutFixationOfComposition();
			
		Else
			
			FillInAccrualsAccordingToServerConditions(Result.ResultAddress);
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		Items.AccrualDocumentsFillInAccordingToConditions.Name,
		"Enabled",
		True);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form);
	
	CollectionOfAccruals = Form.Object.AccrualDocuments;
	
	Form.TotalSettlementAmount = CollectionOfAccruals.Total("SettlementAmount_");
	Form.TotalAmountAccrued = CollectionOfAccruals.Total("AmountAccrued");
	Form.TotalAmountToAccrual = CollectionOfAccruals.Total("AmountToAccrue");
	
EndProcedure

// Parameters:
//  Result - StandardPeriod, Undefined -
//  AdditionalParameters - Undefined
//
&AtClient
Async Procedure SetDateIntervalCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		Cancel = False;
		
		If Object.AccrualDocuments.Count() > 0
		   And (Object.BeginOfPeriod <> CurrentStartDate
		  Or Object.PeriodEnding <> CurrentEndDate) Then
			
			ContinueOperation = Await ContinueOfOperationWithClearingAccrualDocuments();
			If Not ContinueOperation Then
				
				Cancel = True;
				
			EndIf;
			
		EndIf;
		
		If Cancel Then
			
			Object.BeginOfPeriod = CurrentStartDate;
			Object.PeriodEnding = CurrentEndDate;
			
		Else
			
			Object.AccrualDocuments.Clear();
			CalculateTotals_(ThisObject);
			
			CurrentStartDate = Object.BeginOfPeriod;
			CurrentEndDate = Object.PeriodEnding;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Async Function ContinueOfOperationWithClearingAccrualDocuments()
	
	QueryText = NStr("vi = 'Chứng từ tính toán sẽ bị xóa. Tiếp tục?';
					|ru = 'Документы начисления будут очищены. Продолжить?';
					|en = 'Accrual documents will be cleared. Continue?'; fa = 'Accrual documents will be cleared. Continue?';
					|it = 'Документы начисления будут очищены. Продолжить?';
					|pl = 'Accrual documents will be cleared. Continue?';
					|tr = 'Tahakkuk belgeleri temizlenecektir. Devam mı?'");
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	ContinueOperation = (Response = DialogReturnCode.Yes);
	
	Return ContinueOperation;
	
EndFunction

&AtServer
Procedure SetTitleOfSceneryFixingComposition()
	
	If ThereIsAdjustmentOnApproval Then
		
		FixText = NStr("vi = 'Đã nhập điều chỉnh có trạng thái ""Cần thống nhất"", cấm ghi nhận thành phần chứng từ';
						|ru = 'Введена корректировка в статусе ""На согласовании"", фиксация состава документа запрещена';
						|en = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document'; fa = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document';
						|it = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document';
						|pl = 'Adjustment is entered in the ""Pending approval"" status. Cannot record the document';
						|tr = '""Onay bekliyor"" durumuna düzeltme yapıldı, belgenin içeriğinin sabitlenmesi yasaktır'");
		
	Else
		
		FixTemplate = NStr("vi = 'Chưa ghi nhận thành phần chứng từ. <a href=""%1"">Ghi nhận</a>.';
							|ru = 'Состав документа не зафиксирован. <a href=""%1"">Зафиксировать</a>.';
							|en = 'The document content is not recorded. <a href=""%1"">Record</a>.'; fa = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|it = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|pl = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|tr = 'Belgenin içeriği sabitlenmedi. <a href=""%1"">Sabitle</a>.'");
		FixText = StringFunctionsClientServer.SubstituteParametersToString(
			FixTemplate, "Commit");
		
	EndIf;
	
	Items.DecorationFixComposition.Title = StringFunctions.FormattedString(FixText);
	
EndProcedure

&AtServer
Procedure FillInDataOfLastAdjustment()
	
	ThereIsAdjustmentOnApproval = False;
	If Not Object.TermDocument.IsEmpty() Then
		
		ThereIsAdjustmentOnApproval = RebatesServer.ThereIsAdjustmentOnApproval(Object.TermDocument);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TermDocumentOnChangeServer()
	
	FillInDataOfLastAdjustment();
	SetTitleOfSceneryFixingComposition();
	FillInDetailsAccordingToCondition();
	EstablishRelationshipsBetweenParametersForSelectingConditionDocument();
	ConfigureFormVisibilityAccessibility();
	CheckRebateKindOfTermsAndConditionsDocument();
	
EndProcedure

&AtServer
Procedure UpdateDataBeforeFixingComposition()
	
	FillInDataOfLastAdjustment();
	If ThereIsAdjustmentOnApproval Then
		
		SetTitleOfSceneryFixingComposition();
		
	EndIf;
	UpdateDataAboutFixationOfComposition();
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes)
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		CompositionFixationIsAvailable = False;
		
	ElsIf TermsAndConditionsAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments
		  Or TermsAndConditionsAttributes.PartyList = Enums.RebatesParticipants.PartnersSegments
		  Or Not IsBlankString(TermsAndConditionsAttributes.ProductItemProperty) Then
		
		CompositionFixationIsAvailable = True;
		
	Else
		
		CompositionFixationIsAvailable = False;
		
	EndIf;
	
EndProcedure

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtClient
Async Procedure FixCompositionOfConditionsDocument()
	
	UpdateDataBeforeFixingComposition();
	If Not ThereIsAdjustmentOnApproval
	   And Not CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Ghi nhận thành phần của chứng từ điều kiện?';
						|ru = 'Зафиксировать состав документа условий?';
						|en = 'Do you want to record the condition document?'; fa = 'Do you want to record the condition document?';
						|it = 'Do you want to record the condition document?';
						|pl = 'Do you want to record the condition document?';
						|tr = 'Şartlar belgesinin içeriği sabitlensin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			CallbackOnCompletion = New CallbackDescription("FixCompositionOfConditionsDocumentCompletion", ThisObject);
			NotificationOfOperationIsInProgress = New CallbackDescription(
				"OfOperationsArePerformedToFixCompositionOfConditionsDocument",
				ThisObject);
			
			CommonClientServer.SetFormItemProperty(
				Items,
				Items.DecorationFixComposition.Name,
				"Enabled",
				False);
			
			RebatesClient.FixCompositionOfConditionsDocument(
				Object.TermDocument,
				ThisObject,
				CallbackOnCompletion,
				NotificationOfOperationIsInProgress);
			
		EndIf;
	
	Else
		
		If ThereIsAdjustmentOnApproval Then
			MessageText = NStr("vi = 'Không thể ghi nhận thành phần chứng từ điều kiện: đã nhập điều chỉnh với trạng thái ""Cần thống nhất""';
								|ru = 'Невозможно зафиксировать состав документа условий: введена корректировка в статусе ""На согласовании""';
								|en = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.'; fa = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.';
								|it = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.';
								|pl = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.';
								|tr = 'Şartlar belgesinin içeriği sabitlenemiyor: ""Onay bekliyor"" durumunda düzeltme yapıldı'");
		Else
			MessageText = NStr("vi = 'Đã ghi nhận thành phần chứng từ điều kiện';
								|ru = 'Состав документа условий уже зафиксирован';
								|en = 'Condition document content is already recorded'; fa = 'Condition document content is already recorded';
								|it = 'Condition document content is already recorded';
								|pl = 'Condition document content is already recorded';
								|tr = 'Belge içeriği hâlihazırda sabitlendi'");
		EndIf;
		
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object");
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FixCompositionOfConditionsDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And Result.Status = "Error" Then
		
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		
	EndIf;
	
	UpdateDataBeforeFixingComposition();
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OfOperationsArePerformedToFixCompositionOfConditionsDocument(Result, AdditionalParameters) Export
	
	MessageText =
		NStr("vi = 'Theo chứng từ điều kiện, đã thực hiện các giao dịch ghi nhận thành phần. Hãy thử lại sau';
			|ru = 'По документу условий уже выполняются операции по фиксации состава. Попробуйте позже';
			|en = 'Recording operations for the condition document are already in process. Try again later'; fa = 'Recording operations for the condition document are already in process. Try again later';
			|it = 'Recording operations for the condition document are already in process. Try again later';
			|pl = 'Recording operations for the condition document are already in process. Try again later';
			|tr = 'Şartlar belgesi kapsamında içerik düzeltme işlemleri hâlihazırda gerçekleştirilmektedir. Daha sonra tekrar deneyin'");
	
	CommonClient.MessageToUser(MessageText);
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

&AtServer
Procedure CheckPeriodsByTimeFence(Cancel)
	
	If Not Cancel
	   And (Object.BeginOfPeriod > EndDateOfCondition
	  Or Object.PeriodEnding < StartDateOfCondition) Then
		
		ErrorText = NStr("vi = 'Chứng từ điều kiện không có hiệu lực trong kỳ tính toán đã chỉ định';
						|ru = 'Документ условия не действует в указанном периоде начисления';
						|en = 'The condition document is not available for the specified accrual period'; fa = 'The condition document is not available for the specified accrual period';
						|it = 'Документ условия не действует в указанном периоде начисления';
						|pl = 'The condition document is not available for the specified accrual period';
						|tr = 'Şartlar belgesi mevcut tahakkuk döneminde aktif değildir'");
		Common.MessageToUser(ErrorText,, "TermDocument", "Object", Cancel);
		
	EndIf;
		
	If Not Cancel Then
		
		CheckResult = RebatesServer.CheckPeriodsByTimeFence(
			AccrualFrequency,
			Object.BeginOfPeriod,
			Object.PeriodEnding,
			True);
			
		If CheckResult.ThereIsViolationOfBeginning Then
			
			Common.MessageToUser(
				CheckResult.TextOfStartError,
				,
				"BeginOfPeriod",
				"Object",
				Cancel);
			
		EndIf;
		
		If CheckResult.ThereIsViolationOfEnding Then
			
			Common.MessageToUser(
				CheckResult.TextOfEndingError,
				,
				"PeriodEnding",
				"Object",
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function DataOfDocumentsToBeGenerated()
	
	Filter = New Structure("Check", True);
	DocumentsData = Object.AccrualDocuments.Unload(Filter);
	
	TempTablesManager = New TempTablesManager;
	
	DataToBeGeneratedWithoutConducting =
		DataForFormationOfDocumentsWithoutConducting(DocumentsData, TempTablesManager);
	DataToBeGeneratedWithFollowing =
		DataForFormationOfDocumentsWithImplementationOf(DocumentsData, TempTablesManager);
	
	DataToBeGenerated = New Structure;
	DataToBeGenerated.Insert("DataToBeGeneratedWithoutConducting", DataToBeGeneratedWithoutConducting);
	DataToBeGenerated.Insert("DataToBeGeneratedWithFollowing", DataToBeGeneratedWithFollowing);
	
	Address = PutToTempStorage(DataToBeGenerated, New UUID());
	
	Return Address;
	
EndFunction

&AtServer
Function DataForFormationOfDocumentsWithoutConducting(DocumentsData, TempTablesManager)
	
	DataToBeGenerated =
		DataProcessors.BulkAccrualOfCustomerRebates.NewDataForGeneratingAccrualDocumentsWithoutConducting();
		
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextForGeneratingDocumentsWithoutConducting();
	Query.SetParameter("DocumentsData", DocumentsData);
	
	QueryResults = Query.ExecuteBatch();
	ResultIndex = 2;
	For Each KeyAndValue In DataToBeGenerated Do
		
		QueryResult = QueryResults[ResultIndex];
		DataTable = KeyAndValue.Value; // See DataProcessors.BulkAccrualOfCustomerRebates.NewTableOfAccrualDocuments
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			NewRow = DataTable.Add();
			FillPropertyValues(NewRow, Selection);
			
		EndDo;
		
		ResultIndex = ResultIndex + 1;
		
	EndDo;
	
	Return DataToBeGenerated;
	
EndFunction

&AtServer
Function DataForFormationOfDocumentsWithImplementationOf(DocumentsData, TempTablesManager)
	
	DataToBeGenerated =
		DataProcessors.BulkAccrualOfCustomerRebates.NewDataForGeneratingAccrualDocumentsWithConducting();
		
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextOfDocumentGenerationWithImplementationOf();
	Query.SetParameter("DocumentsData", DocumentsData);
	
	QueryResults = Query.ExecuteBatch();
	ResultIndex = 0;
	For Each KeyAndValue In DataToBeGenerated Do
		
		QueryResult = QueryResults[ResultIndex];
		DataTable = KeyAndValue.Value; // See DataProcessors.BulkAccrualOfCustomerRebates.NewTableOfAccrualDocuments
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			NewRow = DataTable.Add();
			FillPropertyValues(NewRow, Selection);
			
		EndDo;
		
		ResultIndex = ResultIndex + 1;
		
	EndDo;
	
	Return DataToBeGenerated;
	
EndFunction

&AtServer
Function QueryTextForGeneratingDocumentsWithoutConducting()
	
	QueryText =
	"SELECT
	|	DocumentsData.Counterparty AS Counterparty,
	|	DocumentsData.Partner AS Partner,
	|	DocumentsData.DocumentAccruals AS DocumentAccruals,
	|	DocumentsData.AmountToAccrue AS AmountToAccrue,
	|	DocumentsData.AmountAccrued AS AmountAccrued,
	|	DocumentsData.SettlementAmount_ AS SettlementAmount_
	|INTO TT_DataToBeGeneratedPreparation
	|FROM
	|	&DocumentsData AS DocumentsData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsData.Counterparty AS Counterparty,
	|	DocumentsData.Partner AS Partner,
	|	DocumentsData.DocumentAccruals AS DocumentAccruals,
	|	CASE
	|		WHEN DocumentsData.DocumentAccruals = VALUE(Document.AccrualOfCustomerRebates.EmptyRef)
	|			THEN FALSE
	|		ELSE CAST(DocumentsData.DocumentAccruals AS Document.AccrualOfCustomerRebates).Posted
	|	END AS Posted,
	|	DocumentsData.AmountToAccrue AS AmountToAccrue,
	|	DocumentsData.AmountAccrued AS AmountAccrued,
	|	DocumentsData.SettlementAmount_ AS SettlementAmount_
	|INTO TT_DataToBeGenerated
	|FROM
	|	TT_DataToBeGeneratedPreparation AS DocumentsData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	NOT DataToBeGenerated.Posted
	|	AND DataToBeGenerated.SettlementAmount_ <> 0
	|	AND DataToBeGenerated.AmountToAccrue = DataToBeGenerated.SettlementAmount_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	NOT DataToBeGenerated.Posted
	|	AND DataToBeGenerated.SettlementAmount_ <> 0
	|	AND DataToBeGenerated.AmountToAccrue <> 0
	|	AND DataToBeGenerated.AmountToAccrue <> DataToBeGenerated.SettlementAmount_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	NOT DataToBeGenerated.Posted
	|	AND DataToBeGenerated.SettlementAmount_ = 0
	|	AND DataToBeGenerated.AmountToAccrue <> 0";
	
	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextOfDocumentGenerationWithImplementationOf()
	
	QueryText =
	"SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	DataToBeGenerated.Posted
	|	AND DataToBeGenerated.SettlementAmount_ <> 0
	|	AND DataToBeGenerated.AmountToAccrue = DataToBeGenerated.SettlementAmount_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	DataToBeGenerated.Posted
	|	AND DataToBeGenerated.SettlementAmount_ <> 0
	|	AND DataToBeGenerated.AmountToAccrue <> 0
	|	AND DataToBeGenerated.AmountToAccrue <> DataToBeGenerated.SettlementAmount_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	DataToBeGenerated.Posted
	|	AND DataToBeGenerated.SettlementAmount_ = 0
	|	AND DataToBeGenerated.AmountToAccrue <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToBeGenerated.Counterparty AS Counterparty,
	|	DataToBeGenerated.Partner AS Partner,
	|	DataToBeGenerated.DocumentAccruals AS DocumentAccruals,
	|	DataToBeGenerated.AmountToAccrue AS AmountToAccrue,
	|	DataToBeGenerated.AmountAccrued AS AmountAccrued,
	|	DataToBeGenerated.SettlementAmount_ AS SettlementAmount_
	|FROM
	|	TT_DataToBeGenerated AS DataToBeGenerated
	|WHERE
	|	DataToBeGenerated.AmountToAccrue = 0";
	
	Return QueryText;
	
EndFunction

&AtClient
Procedure CheckNotes(Cancel)
	
	ThereAreNotes = False;
	For Each DocumentLine In Object.AccrualDocuments Do
		
		If DocumentLine.Check Then
			
			ThereAreNotes = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not ThereAreNotes Then
		
		MessageText = NStr("vi = 'Chưa đánh dấu dòng nào để lập chứng từ';
							|ru = 'Не отмечено ни одной строки для формирования документов';
							|en = 'No line is selected for document generation'; fa = 'No line is selected for document generation';
							|it = 'Не отмечено ни одной строки для формирования документов';
							|pl = 'No line is selected for document generation';
							|tr = 'Belge oluşturma için hiçbir satır işaretlenmemiş'");
		CommonClient.MessageToUser(MessageText,, "AccrualsDocuments", "Object", Cancel);
		
	EndIf;
		
EndProcedure

&AtServer
Procedure CheckDuplicatesOfParticipants(Cancel)
	
	Filter = New Structure("Check", True);
	GroupingOfParticipants = "";
	If PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCustomer Then
		GroupingOfParticipants = "Partner";
	ElsIf PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty Then
		GroupingOfParticipants = "Counterparty";
	ElsIf PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterpartyAndCustomer Then
		GroupingOfParticipants = "Counterparty, Partner";
	EndIf;
	
	Attendees = Object.AccrualDocuments.Unload(Filter, GroupingOfParticipants);
	OriginalQuantity = Attendees.Count();
	Attendees.GroupBy(GroupingOfParticipants);
	NumberOfOriginal = Attendees.Count();
	
	If OriginalQuantity <> NumberOfOriginal Then
		
		MessageText = NStr("vi = 'Dữ liệu của chứng từ tính toán có chứa người tham gia bị trùng';
							|ru = 'Данные документов начислений содержат дубли участников';
							|en = 'Data of accrual documents contains participant duplicates'; fa = 'Data of accrual documents contains participant duplicates';
							|it = 'Данные документов начислений содержат дубли участников';
							|pl = 'Data of accrual documents contains participant duplicates';
							|tr = 'Tahakkuk belgesi verileri mükerrer katılımcılar içeriyor'");
		Common.MessageToUser(MessageText,, "AccrualsDocuments", "Object", Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDataAboutFixationOfComposition()
	
	TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.TermDocument);
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		TermsDocumentHasBeenAgreed = False;
		TermsDocumentHasBeenAgreed = False;
		CompositionOfSegmentsIsFixed = False;
		
	Else
		
		TermsDocumentHasBeenAgreed = True;
		UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes);
		
		CompositionOfSegmentsIsFixed = TermsAndConditionsAttributes.RecordingIsCompleted;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure GenerateDocumentsCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			
			StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
			
		Else
			
			FillInDataOfCreatedDocuments(Result.ResultAddress)
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		Items.FormGenerateDocuments.Name,
		"Enabled",
		True);
	
	CalculateTotals_(ThisObject);
	NotifyChanged(Type("DocumentRef.AccrualOfCustomerRebates"));
	
EndProcedure

&AtServer
Procedure FillInDataOfCreatedDocuments(Val ResultAddress)
	
	CreatedDocuments = GetFromTempStorage(ResultAddress); // See DataProcessors.BulkAccrualOfCustomerRebates.NewTableOfAccrualDocuments
	
	For LineNumber = 1 To Object.AccrualDocuments.Count() Do
		
		DocumentLine = Object.AccrualDocuments[LineNumber - 1];
		
		Filter = New Structure;
		Filter.Insert("Counterparty", DocumentLine.Counterparty);
		Filter.Insert("Partner", DocumentLine.Partner);
		
		DataOfCreatedDocuments = CreatedDocuments.FindRows(Filter);
		
		If DataOfCreatedDocuments.Count() > 0 Then
			
			DocumentData = DataOfCreatedDocuments[0];
			FillPropertyValues(DocumentLine, DocumentData);
			
			Field = CommonClientServer.PathToTabularSection(
				"Object.AccrualDocuments",
				LineNumber,
				"DocumentAccruals");
			
			If Not IsBlankString(DocumentData.ErrorDescription) Then
				
				Common.MessageToUser(DocumentData.ErrorDescription,, Field);
				
			EndIf;
			
			For Each Message In DocumentData.Messages Do
				
				Common.MessageToUser(Message,, Field);
				
			EndDo;
			
			If DocumentData.Posted Then
				PictureIndex = 1;
			ElsIf DocumentData.DeletionMark Then 
				PictureIndex = 3;
			Else
				PictureIndex = 0;
			EndIf;
			
			DocumentLine.PictureIndex = PictureIndex;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
