
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If GetFunctionalOption("BaseVersion") Then
		AutoTitle = False;
		Title = NStr("vi = 'Biên bản đối chiếu công nợ';
					|ru = 'Сверка взаиморасчетов';
					|en = 'AR/AP reconciliation'; fa = 'تطبیق دریافتنی/پرداختنی';
					|it = 'Сверка взаиморасчетов';
					|pl = 'Weryfikacja wzajemnych rozliczeń';
					|tr = 'Alacak/Borç mutabakatı'");
	EndIf;
	
	ThisIsReconciliationBetweenOrganizations = TypeOf(Object.Counterparty) = Type("CatalogRef.Companies");
	If Not ValueIsFilled(Object.ContactPerson) Then
		Object.ContactPerson = ?(
			ThisIsReconciliationBetweenOrganizations, 
			Catalogs.Users.EmptyRef(),
			Catalogs.ContactPersonsForPartners.EmptyRef());
	EndIf;
	
	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	Documents.ARAPReconciliation2_4.InitializeSettingsComposer(LinkerSelection, UUID);
	Try
		Filter_Settings = FormAttributeToValue("Object").Filter_Settings.Get();
	Except
		// We don't do anything. The selection settings are updated before recording.
	EndTry;
	If ValueIsFilled(Filter_Settings) Then
		DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			Documents.ARAPReconciliation2_4.CompletePartnerSelectionByCounterparty(LinkerSelection.Settings.Filter);
		EndIf;
	EndIf;
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	Items.TotalDebtRegl.Visible = UseMultipleCurrencies;
	Items.SummaryOfAdvanceRegl.Visible = UseMultipleCurrencies;
	
	FinancialInstrumentsAvailable = GetFunctionalOption("UseLoanAndDepositContracts");
	FinancialInstrumentsAvailable = FinancialInstrumentsAvailable Or NonCurrentAssets.VNAManagementIsUsed();
	If Not FinancialInstrumentsAvailable Or ThisIsReconciliationBetweenOrganizations Then
		Items.FinancialInstrumentsPage.Visible = False;
	EndIf;
	
	ShowGroupingsCalculations = True;
	ShowGroupingsOfFinancialInstruments = True;
	SummaryOfDetailedRecords.Add();
	Items.EmployeeInCharge_.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.Director);
	Items.EmployeeInCharge_.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	Items.CounterpartyCompanyPersonResponsible.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.Director);
	Items.CounterpartyCompanyPersonResponsible.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	If Not ValueIsFilled(Object.Counterparty) Then
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	Items.Counterparty.ChooseType = UseMultipleCompanies;
	ChoiceList = Items.GroupingsARAPPaymentType_.ChoiceList;
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	
	ChoiceList = Items.GroupingsFinancialInstrumentsPaymentType_.ChoiceList;
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	SetVisibilityOfReconciliationPages();
	If Not ValueIsFilled(Object.Ref) Then
		FormItemsManagement();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "CounterpartyDataPartnerDebt", NStr("vi = 'Công nợ đối tác';
														|ru = 'Долг контрагента';
														|en = 'Counterparty debt'; fa = 'بدهی طرف حساب';
														|it = 'Долг контрагента';
														|pl = 'Zobowiązanie kontrahenta';
														|tr = 'Cari hesabın borcu'"));

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	Partner = CounterpartySPartner(Object.Counterparty);
	ShowGroupingsCalculations = True;
	ShowGroupingsOfFinancialInstruments = True;
	ThisIsReconciliationBetweenOrganizations = TypeOf(Object.Counterparty) = Type("CatalogRef.Companies");
	FormItemsManagement();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatus();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.ContactPersonsForPartners") Then
		If CurrentItem <> Undefined Then
			If CurrentItem.Name = "ContactPerson" Then
				Object.ContactPerson = ValueSelected;
			ElsIf CurrentItem.Name = "FullNameOfCounterpartyExecutive" Then
				Object.FullNameOfCounterpartyExecutive = String(ValueSelected);
				FillPositionBySelectedValue(ValueSelected)
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.Filter_Settings = New ValueStorage(LinkerSelection.GetSettings());
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContactPersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ThisIsReconciliationBetweenOrganizations Then
		
		StandardProcessing = False;
		
		ManagerSFullNameContactPersonStartOfSelection();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	SetAvailabilityOfItemsByStatus();
	
EndProcedure

&AtClient
Procedure FullNameOfCounterpartyExecutiveStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ManagerSFullNameContactPersonStartOfSelection();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCounterpartyData

&AtClient
Procedure CounterpartyDataARAPDocumentOnChange(Item)

	CurrentData = Items.CounterpartyData.CurrentData;
	
	If ValueIsFilled(CurrentData.ARAPDocument) Then
		
		FillInLineForSettlementDocumentServer(CurrentData.ARAPDocument,
												CurrentData.DocumentDetails,
												CurrentData.ARAPCurrency);

	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersBookmarksSettlements

&AtClient
Procedure ShowCalculationsWhenChanged(Item)
	
	If ShowGroupingsCalculations 
		And Items.GroupingsARAP.CurrentData = Undefined Then
		For Each String In Object.GroupingsARAP Do
			If String.ARAPObject = FilterCalculations Then
				Items.GroupingsARAP.CurrentRow = String.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Object.GroupingsARAP.Count() > 0
		And Items.GroupingsARAP.CurrentData <> Undefined
		And ValueIsFilled(Items.GroupingsARAP.CurrentData.PaymentType_)
		And ValueIsFilled(Items.GroupingsARAP.CurrentData.ARAPObject)
		And ValueIsFilled(Items.GroupingsARAP.CurrentData.Partner)
		And ValueIsFilled(Items.GroupingsARAP.CurrentData.Currency) Then
	
		FilterParameters = DetailSelectionParameters("Calculations");
		SwitchToDetail(FilterParameters);
		
		ARAPAccountingClientServer.CalculateFinalBalanceOnMutualSettlements(
			Items.GroupingsARAP.CurrentData,
			Object.DetailedRecordsARAPAccounting);
			
		ARAPAccountingClientServer.CalculateFinalBalanceOnMutualSettlements(
			Items.GroupingsARAP.CurrentData,
			Object.DetailedRecordsARAPAccounting,
			True);
		
	Else
		ShowGroupingsCalculations = Not ShowGroupingsCalculations;
		If Items.GroupingsARAP.SelectedRows.Count() 
			And Items.GroupingsARAP.CurrentData <> Undefined
			And Not ValueIsFilled(Items.GroupingsARAP.CurrentData.ARAPObject) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa điền đối tượng hạch toán';
					|ru = 'Не заполнен объект расчетов';
					|en = 'AR/AP object is not filled in'; fa = 'AR/AP object is not filled in';
					|it = 'Не заполнен объект расчетов';
					|pl = 'Nie wypełniono obiektu rozliczeń';
					|tr = 'Alacak/Borç nesnesi doldurulmamış'"),
				,
				StrTemplate("Object.GroupingsARAP[%1].ARAPObject", Format(Items.GroupingsARAP.CurrentRow, "NZ=0; NG=0")),
				"Object");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupingsARAPOpeningBalanceOnChange(Item)
	
	ARAPAccountingClientServer.CalculateFinalBalanceOnMutualSettlements(
		Items.GroupingsARAP.CurrentData,
		Object.DetailedRecordsARAPAccounting);
	
EndProcedure
	
&AtClient
Procedure GroupingsCalculationsInitialBalanceAdvanceReglOnChange(Item)
	
	ARAPAccountingClientServer.CalculateFinalBalanceOnMutualSettlements(
		Items.GroupingsARAP.CurrentData,
		Object.DetailedRecordsARAPAccounting,
		True);
	
EndProcedure

&AtClient
Procedure GroupingsARAPARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	TableRow = Items.GroupingsARAP.CurrentData;
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", TableRow.PaymentType_);
	FilterValues.Insert("Organization", Object.Organization);
	FilterValues.Insert("Counterparty",  Object.Counterparty);
	FilterValues.Insert("PaymentsAsPer275FZ" , False);
	
	If TypeOf(FilterValues.Counterparty) = Type("CatalogRef.Companies") Then
		FilterValues.Insert("Partner", PredefinedValue("Catalog.Partners.OurEnterprise"));
	Else
		FilterValues.Insert("Partner", TableRow.Partner);
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectingThePaymentBasis", False);
	SelectionSettings_.Insert("EditableDocument", Object.Ref);
	SelectionSettings_.Insert("Sum", 0);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("SelectAccountsReceivable", True);
	SelectionSettings_.Insert("ReturnStructure", True);
	SelectionSettings_.Insert("CurrentRow", TableRow.ARAPObject);
	
	OpenForm("Catalog.ARAPObjects.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

&AtClient
Procedure GroupingsARAPARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.GroupingsARAP.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		CurrentData.ARAPObject = ValueSelected.ARAPObject;
		CurrentData.Partner = ValueSelected.Partner;
		CurrentData.Contract = ValueSelected.Contract;
		CurrentData.Currency = ValueSelected.ARAPCurrency;
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupingsARAPBeforeDeleteRow(Item, Cancel)
	
	If Item.CurrentData <> Undefined Then
		CurrentData = Item.CurrentData;
		IndexOf = 0;
		While IndexOf < Object.DetailedRecordsARAPAccounting.Count() Do
			Record = Object.DetailedRecordsARAPAccounting[0];
			If CurrentData.PaymentType_ = Record.PaymentType_ 
				And CurrentData.ARAPObject = Record.ARAPObject Then
				Object.DetailedRecordsARAPAccounting.Delete(Record);
				Continue;
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterCalculationsClearing(Item, StandardProcessing)
	
	Items.DetailedRecordsARAPAccounting.ChangeRowSet = False;
	Items.DetailedRecordsARAPAccounting.RowFilter = Undefined;
	DetailsOfTheCalculationObject = "";
	TotalsAreAvailable = CalculationsTotalsAreAvailableWithoutFilterByARAPObject();
	Items.GroupTotalSettlement.Visible = TotalsAreAvailable;
	If TotalsAreAvailable Then
		NamesOfTotalsFields = "DebtAmount_,DebtAmountLocal,AmountPrepayment,PrepaymentAmountLocal_";
		Filter = New Structure;
		RecalculateResultsForObjectOfCalculationsOnClient("DetailedRecordsARAPAccounting", Filter, NamesOfTotalsFields);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterCalculationsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If Object.GroupingsARAP.Count() > 0 Then
		EnableSelectionOfDetailedRecords("Calculations", "ARAPObject", ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingOnChange(Item)
	If Item.CurrentData <> Undefined And Item.RowFilter <> Undefined Then
		Item.CurrentData.ARAPObject = Item.RowFilter.ARAPObject;
		Item.CurrentData.PaymentType_ = Item.RowFilter.PaymentType_;
		Item.CurrentData.Partner = Item.RowFilter.Partner;
		Item.CurrentData.Contract = Item.RowFilter.Contract;
	EndIf;
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingAfterDeleteRow(Item)
	NamesOfTotalsFields = "DebtAmount_,DebtAmountLocal,AmountPrepayment,PrepaymentAmountLocal_";
	Filter = New Structure("ARAPObject", FilterCalculations);
	RecalculateResultsForObjectOfCalculationsOnClient("DetailedRecordsARAPAccounting", Filter, NamesOfTotalsFields);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingDebtAmount_OnChange(Item)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingDebtAmountLocalOnChange(Item)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingDebtAmount_Clearing(Item, StandardProcessing)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingAmountPrepaymentOnChange(Item)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingPrepaymentAmountLocal_OnChange(Item)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingAmountPrepaymentClearing(Item, StandardProcessing)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingDebtAmountCounterpartyOnChange(Item)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData, "Counterparty");
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingDebtAmountCounterpartyClearing(Item, StandardProcessing)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData, "Counterparty");
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingAmountPrepaymentCounterpartyOnChange(Item)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData, "Counterparty");
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingAmountPrepaymentCounterpartyClearing(Item, StandardProcessing)
	CalculateAmountOfSettlements(Items.DetailedRecordsARAPAccounting.CurrentData, "Counterparty");
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Type") Then
		DocumentData = SettlementDocumentSelectionProcessingOnSevrer(ValueSelected);
		CurrentData = Items.DetailedRecordsARAPAccounting.CurrentData;
		FillPropertyValues(CurrentData, DocumentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingContractStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ContractStartChoice(Item);
EndProcedure

&AtClient
Procedure GroupingsARAPContractStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ContractStartChoice(Item);
EndProcedure

&AtClient
Procedure GroupingsARAPContractAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	DataGetParameters.Filter = SelectingContractSearch();
EndProcedure

&AtClient
Procedure GroupingsARAPContractTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	DataGetParameters.Filter = SelectingContractSearch();
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingContractAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	DataGetParameters.Filter = SelectingContractSearch();
EndProcedure

&AtClient
Procedure DetailedRecordsARAPAccountingContractTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	DataGetParameters.Filter = SelectingContractSearch();
EndProcedure

#EndRegion

#Region EventHandlersBookmarksFinancialInstruments

&AtClient
Procedure ShowFinancialInstrumentsWhenChanged(Item)
	
	If ShowGroupingsOfFinancialInstruments 
		And Items.GroupingsFinancialInstruments.CurrentData = Undefined Then
		For Each String In Object.GroupingsFinancialInstruments Do
			If String.Contract = FilterFinancialInstruments Then
				Items.GroupingsFinancialInstruments.CurrentRow = String.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Object.GroupingsFinancialInstruments.Count() > 0
		And Items.GroupingsFinancialInstruments.CurrentData <> Undefined
		And ValueIsFilled(Items.GroupingsFinancialInstruments.CurrentData.Currency) Then
		
		FilterParameters = DetailSelectionParameters("FinancialInstruments");
		SwitchToDetail(FilterParameters);
		
		ARAPAccountingClientServer.CalculateFinalBalanceOnFinancialInstruments(
			Items.GroupingsFinancialInstruments.CurrentData,
			Object.DetailedRecordsFinancialInstruments);
	Else
		ShowGroupingsOfFinancialInstruments = Not ShowGroupingsOfFinancialInstruments;
		If Items.GroupingsFinancialInstruments.SelectedRows.Count() 
			And Items.GroupingsFinancialInstruments.CurrentData <> Undefined
			And Not ValueIsFilled(Items.GroupingsFinancialInstruments.CurrentData.Contract) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa điền hợp đồng';
					|ru = 'Не заполнен договор';
					|en = 'Contract is required'; fa = 'قرارداد الزامی است';
					|it = 'Не заполнен договор';
					|pl = 'Nie wypełniono kontraktu';
					|tr = 'Sözleşme doldurulmamış'"),
				,
				StrTemplate("Object.GroupingsFinancialInstruments[%1].Contract", Format(Items.GroupingsFinancialInstruments.CurrentRow, "NZ=0; NG=0")),
				"Object");
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure GroupingsFinancialInstrumentsOpeningBalanceDrOnChange(Item)
	
	ARAPAccountingClientServer.CalculateFinalBalanceOnFinancialInstruments(
		Items.GroupingsFinancialInstruments.CurrentData,
		Object.DetailedRecordsFinancialInstruments);
	
EndProcedure

&AtClient
Procedure GroupingsFinancialInstrumentsOpeningBalanceCrOnChange(Item)
	
	ARAPAccountingClientServer.CalculateFinalBalanceOnFinancialInstruments(
		Items.GroupingsFinancialInstruments.CurrentData,
		Object.DetailedRecordsFinancialInstruments);
	
EndProcedure

&AtClient
Procedure GroupingsFinancialInstrumentsContractChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Type") Then
		ContractData = TreatyOfChoiceOnSevrera(ValueSelected);
		CurrentData = Items.GroupingsFinancialInstruments.CurrentData;
		FillPropertyValues(CurrentData, ContractData);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterFinancialInstrumentsClearing(Item, StandardProcessing)
	
	Items.DetailedRecordsLoans.ChangeRowSet = False;
	Items.DetailedRecordsLoans.RowFilter = Undefined;
	Items.DetailedLeasingRecords.ChangeRowSet = False;
	Items.DetailedLeasingRecords.RowFilter = Undefined;
	DetailsOfTheContract = "";
	
EndProcedure

&AtClient
Procedure FilterFinancialInstrumentsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If Object.GroupingsFinancialInstruments.Count() > 0 Then
		EnableSelectionOfDetailedRecords("FinancialInstruments", "Contract", ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupingsFinancialInstrumentsBeforeDeleteRow(Item, Cancel)
	
	If Item.CurrentData <> Undefined Then
		CurrentData = Item.CurrentData;
		IndexOf = 0;
		While IndexOf < Object.DetailedRecordsFinancialInstruments.Count() Do
			Record = Object.DetailedRecordsFinancialInstruments[0];
			If CurrentData.Contract = Record.Contract Then
				Object.DetailedRecordsFinancialInstruments.Delete(Record);
				Continue;
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailedRecordsLoansOnChange(Item)
	If Item.CurrentData <> Undefined Then
		Item.CurrentData.Contract = FilterFinancialInstruments;
	EndIf;
EndProcedure

&AtClient
Procedure DetailedLeasingRecordsOnChange(Item)
	If Item.CurrentData <> Undefined Then
		Item.CurrentData.Contract = FilterFinancialInstruments;
	EndIf;
EndProcedure

&AtClient
Procedure DetailedRecordsLoansARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Type") Then
		DocumentData = SettlementDocumentSelectionProcessingOnSevrer(ValueSelected);
		CurrentData = Items.DetailedRecordsLoans.CurrentData;
		FillPropertyValues(CurrentData, DocumentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailedLeasingRecordsARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Type") Then
		DocumentData = SettlementDocumentSelectionProcessingOnSevrer(ValueSelected);
		CurrentData = Items.DetailedLeasingRecords.CurrentData;
		FillPropertyValues(CurrentData, DocumentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	
	ClearMessages();
	If Not NewOnlineARAPAccounting Then
		If ThereAreTasksForDistribution() Then
			AttachIdleHandler("Attachable_CheckTaskCompletion", 0.1, True);
			Return;
		EndIf;
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("DistributionByDocumentsCompletion", ThisObject);
	RunCallback(CallbackOnCompletion, True);
	
EndProcedure

&AtClient
Procedure AdvancedFilter(Command)
	
	OpeningParameters = ParametersOfExtendedSelectionForm();
	
	CloseHandler = New CallbackDescription("SetAdvancedSelectionCompletion", ThisObject);
	OpenForm("Document.ARAPReconciliation2_4.Form.AdvancedFilter",
	            OpeningParameters,
	            ThisForm,
	            ,
	            ,
	            , 
	            CloseHandler,
                FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DistributionByDocumentsCompletion(Result, AdditionalParameters) Export
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	If ValueIsFilled(Object.CounterpartyData) Then
		CheckParameters.TabularSection          = Object.CounterpartyData;
		CheckParameters.TitleOfTablePart = NStr("vi = 'Nợ theo đối tác';
												|ru = 'Задолженность по данным контрагента';
												|en = 'Debt amount by counterparty data'; fa = 'Debt amount by counterparty data';
												|it = 'Задолженность по данным контрагента';
												|pl = 'Zobowiązanie według danych kontrahenta';
												|tr = 'Cari hesap verilerine göre borçluluk durumu'");
	ElsIf Not ValueIsFilled(Object.GroupingsARAP) And ValueIsFilled(Object.GroupingsFinancialInstruments) Then
		CheckParameters.TabularSection          = Object.GroupingsFinancialInstruments;
		CheckParameters.TitleOfTablePart = NStr("vi = 'Hạch toán theo các công cụ tài chính';
												|ru = 'Расчеты по финансовым инструментам';
												|en = 'Financial instruments AR/AP'; fa = 'دریافتنی/پرداختنی ابزارهای مالی';
												|it = 'Расчеты по финансовым инструментам';
												|pl = 'Obliczenia według instrumentów finansowych';
												|tr = 'Finansal araçların mutabakatı'");
	Else
		CheckParameters.TabularSection          = Object.GroupingsARAP;
		CheckParameters.TitleOfTablePart = NStr("vi = 'Hạch toán công nợ';
												|ru = 'Взаиморасчеты';
												|en = 'AR/AP accounting'; fa = 'حسابداری دریافتنی/پرداختنی';
												|it = 'Взаиморасчеты';
												|pl = 'AR/AP accounting';
												|tr = 'Alacak/Borç muhasebesi'");
	EndIf;
	If UseMultipleCompanies Then
		CheckParameters.CheckedAttributes.Insert("Organization",  NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Организация';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	EndIf;
	CheckParameters.CheckedAttributes.Insert("Counterparty",   NStr("vi = 'Đối tác';
																	|ru = 'Контрагент';
																	|en = 'Counterparty'; fa = 'طرف حساب';
																	|it = 'Контрагент';
																	|pl = 'Kontrahent';
																	|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("EndOfPeriod", NStr("vi = 'Cuối kỳ';
																|ru = 'Конец периода';
																|en = 'Period end'; fa = 'پایان دوره';
																|it = 'Конец периода';
																|pl = 'Koniec okresu';
																|tr = 'Dönem sonu'"));
	
	Notification = New CallbackDescription("FillInByBalanceCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInByBalanceCompletion(Result, AdditionalParameters) Export 
	
	Object.CounterpartyData.Clear();
	Object.GroupingsARAP.Clear();
	Object.DetailedRecordsARAPAccounting.Clear();
	Object.GroupingsFinancialInstruments.Clear();
	Object.DetailedRecordsFinancialInstruments.Clear();
	FillInByBalanceServer();
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure CopyDocument(Command)
	
	ReconciliationFields = "BeginOfPeriod,EndOfPeriod,Organization,Counterparty,ContactPerson";
	StructureFilter = New Structure(ReconciliationFields);
	FillPropertyValues(StructureFilter,Object);
	
	ParametersStructure1 = New Structure("Basis", StructureFilter);
	OpenForm("Document.ARAPReconciliation2_5_11.ObjectForm", ParametersStructure1, ThisObject);

EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PreviousCalculationObject(Command)
	
	If Object.GroupingsARAP.Count() > 0 Then
		FilterParameters = DetailSelectionParameters("Calculations");
		SetFollowingObject(FilterParameters, True)
	EndIf;

EndProcedure

&AtClient
Procedure NextCalculationObject(Command)
	
	If Object.GroupingsARAP.Count() > 0 Then
		FilterParameters = DetailSelectionParameters("Calculations");
		SetFollowingObject(FilterParameters)
	EndIf;

EndProcedure

&AtClient
Procedure SelectByCalculationObject(Command)
	
	If Object.GroupingsARAP.Count() > 0 
		And Items.DetailedRecordsARAPAccounting.CurrentData <> Undefined Then
		ValueSelected = Items.DetailedRecordsARAPAccounting.CurrentData.ARAPObject;
		EnableSelectionOfDetailedRecords("Calculations", "ARAPObject", ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure PreviousAgreement(Command)
	
	If Object.GroupingsFinancialInstruments.Count() > 0 Then
		FilterParameters = DetailSelectionParameters("FinancialInstruments");
		SetFollowingObject(FilterParameters, True)
	EndIf;

EndProcedure

&AtClient
Procedure NextAgreement(Command)
	
	If Object.GroupingsFinancialInstruments.Count() > 0 Then
		FilterParameters = DetailSelectionParameters("FinancialInstruments");
		SetFollowingObject(FilterParameters)
	EndIf;

EndProcedure

&AtClient
Procedure SelectByAgreement_(Command)
	
	If Object.GroupingsFinancialInstruments.Count() > 0 
		And Items[CurrentItem.Name].CurrentData <> Undefined Then
		ValueSelected = Items[CurrentItem.Name].CurrentData.Contract;
		EnableSelectionOfDetailedRecords("FinancialInstruments", "Contract", ValueSelected);
	EndIf;
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ThisIsReconciliationBetweenOrganizations = TypeOf(Object.Counterparty) = Type("CatalogRef.Companies");
	Partner = CounterpartySPartner(Object.Counterparty);
	
	Object.CounterpartyCompanyManager = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	Object.ChiefAccountantOfCounterpartyCompany = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	If Not ThisIsReconciliationBetweenOrganizations Then
		
		If ValueIsFilled(Object.Counterparty) Then
			
			DocumentData = Documents.ARAPReconciliation2_4.DetailsOfLastDocument(Object.Counterparty);
			FillPropertyValues(Object, DocumentData, , "FullNameOfCounterpartyExecutive, JobTitleOfCounterpartyExecutive,ContactPerson");
			If Not ValueIsFilled(Object.FullNameOfCounterpartyExecutive)
			 And Not ValueIsFilled(Object.JobTitleOfCounterpartyExecutive) Then
			 	FillPropertyValues(Object, DocumentData, "FullNameOfCounterpartyExecutive, JobTitleOfCounterpartyExecutive");
			EndIf;
			If Not ValueIsFilled(Object.ContactPerson)
				Or Common.ObjectAttributeValue(Object.ContactPerson,"Owner") <> Partner Then
				
				If ValueIsFilled(DocumentData.ContactPerson) Then
					Object.ContactPerson = DocumentData.ContactPerson;
				Else
					Object.ContactPerson = PartnersAndCounterparties.GetDefaultPartnerContactPerson(Partner);
				EndIf;
			EndIf;
			Object.ContactPerson = Catalogs.ContactPersonsForPartners.EmptyRef();
			
			FormItemsManagement();
			
		Else
			
			Object.ContactPerson = Catalogs.ContactPersonsForPartners.EmptyRef();
			
		EndIf;
		
	Else
		
		If ValueIsFilled(Object.Counterparty) Then
			
			ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Object.Counterparty, Object.Date);
			Object.CounterpartyCompanyManager = ResponsiblePersons.DirectorRef;
			Object.ChiefAccountantOfCounterpartyCompany = ResponsiblePersons.ChiefAccountantRef;
			Object.ContactPerson = Catalogs.Users.EmptyRef();
			FormItemsManagement();
			
		EndIf;
		
	EndIf;
	
	If String(Object.ContactPerson) <> Object.FullNameOfCounterpartyExecutive 
		Or ThisIsReconciliationBetweenOrganizations Then
		Object.FullNameOfCounterpartyExecutive = Undefined;
		Object.JobTitleOfCounterpartyExecutive = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ThisIsReconciliationBetweenOrganizations = TypeOf(Object.Counterparty) = Type("CatalogRef.Companies");
	If ThisIsReconciliationBetweenOrganizations 
		And ValueIsFilled(Object.Counterparty) Then
		ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Object.Counterparty, Object.Date);
		Object.CounterpartyCompanyManager = ResponsiblePersons.DirectorRef;
		Object.ChiefAccountantOfCounterpartyCompany = ResponsiblePersons.ChiefAccountantRef;
	ElsIf Not ThisIsReconciliationBetweenOrganizations Then
		Object.CounterpartyCompanyManager = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
		Object.ChiefAccountantOfCounterpartyCompany = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	Object.CounterpartyCompanyManager = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	Object.ChiefAccountantOfCounterpartyCompany = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	
EndProcedure

&AtClient
Procedure EmployeeInCharge_OnChange(Item)
	
	ShowChiefAccountant = Object.EmployeeInCharge_ = PredefinedValue("Enum.PersonsResponsibleAndCompanies.ChiefAccountant");
	Items.ChiefAccountant.Visible = ShowChiefAccountant;
	Items.Director.Visible = Not Items.ChiefAccountant.Visible;
	
EndProcedure

&AtClient
Procedure CounterpartyCompanyPersonResponsibleOnChange(Item)
	
	ShowChiefAccountant = Object.CounterpartyCompanyPersonResponsible = PredefinedValue("Enum.PersonsResponsibleAndCompanies.ChiefAccountant");
	Items.ChiefAccountantOfCounterpartyCompany.Visible = ShowChiefAccountant;
	Items.CounterpartyCompanyManager.Visible = Not Items.ChiefAccountantOfCounterpartyCompany.Visible;
	
EndProcedure

&AtClient
Procedure ThereAreDiscrepanciesOnChange(Item)
	ThereAreDiscrepanciesWhenChangingOnServer();
EndProcedure

&AtClient
Procedure CalculateAmountOfSettlements(CurrentData, Suffix = "")
	
	If Suffix = "Counterparty" Then
		ColumnNameAmountDebt           = "DebtAmountCounterparty";
		ColumnNameAmountAdvance          = "AmountPrepaymentCounterparty";
		NameOfSettlementAmountColumn = "AmountARAPCounterparty";
	Else
		ColumnNameAmountDebt           = "DebtAmount_";
		ColumnNameAmountAdvance          = "AmountPrepayment";
		NameOfSettlementAmountColumn = "AmountARAP";			
	EndIf;
	
	
	Debt  = CurrentData[ColumnNameAmountDebt];
	Prepayment_ = CurrentData[ColumnNameAmountAdvance];
	CurrentData[NameOfSettlementAmountColumn] = Max(Debt, -Debt) + Max(Prepayment_, -Prepayment_);
	
	NamesOfTotalsFields = "DebtAmount_,DebtAmountLocal,AmountPrepayment,PrepaymentAmountLocal_";
	Filter = New Structure("ARAPObject", FilterCalculations);
	RecalculateResultsForObjectOfCalculationsOnClient("DetailedRecordsARAPAccounting", Filter, NamesOfTotalsFields);
	
EndProcedure

&AtClient
Procedure RecalculateResultsForObjectOfCalculationsOnClient(TabularSectionName, Filter, NamesOfTotalsFields)
	
	SummaryFields = StrSplit(NamesOfTotalsFields, ",");
	CalculationObjectStrings = Object[TabularSectionName].FindRows(Filter);
	For Each TotalField In SummaryFields Do
		SummaryOfDetailedRecords[0][TotalField] = 0;
		For Each String In CalculationObjectStrings Do
			SummaryOfDetailedRecords[0][TotalField] = SummaryOfDetailedRecords[0][TotalField] + String[TotalField];
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function SettlementDocumentSelectionProcessingOnSevrer(ValueSelected)
	
	DocumentData = Documents.ARAPReconciliation2_4.SettlementDocumentData(ValueSelected);
	DocumentData.Insert("DocumentCurrency", DocumentData.Currency);
	DocumentDetails = Documents.ARAPReconciliation2_4.DescriptionOfSettlementDocument(DocumentData);
	DocumentData.Insert("DocumentDetails", DocumentDetails);
	
	Return DocumentData;
	
EndFunction

&AtServer
Function TreatyOfChoiceOnSevrera(ValueSelected)
	
	ContractDetails_ = Common.ObjectAttributesValues(ValueSelected, "Partner, ARAPCurrency, ContractKind");
	ContractDetails_.Insert("Currency", ContractDetails_.ARAPCurrency);
	PaymentType_ = Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting;
	If ContractDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.Deposit
		Or ContractDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing Then
		PaymentType_ = Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting;
		
	ElsIf ContractDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.Lease Then
		PaymentType_ = Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor;
		
	EndIf;
	ContractDetails_.Insert("PaymentType_", PaymentType_);
	
	Return ContractDetails_;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Function CalculationsTotalsAreAvailableWithoutFilterByARAPObject()
	PaymentType_ = Undefined;
	Currency = Undefined;
	For Each DimensionString In Object.GroupingsARAP Do
		If PaymentType_ = Undefined Then
			PaymentType_ = DimensionString.PaymentType_;
		ElsIf PaymentType_ <> DimensionString.PaymentType_ Then
			Return False;
		EndIf;
		If Currency = Undefined Then
			Currency = DimensionString.Currency;
		ElsIf Currency <> DimensionString.Currency Then
			Return False;
		EndIf;
	EndDo;
	Return True;
EndFunction

&AtClient
Procedure ContractStartChoice(Item)
	Cancel = False;
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
				|it = 'Поле ""Организация"" не заполнено';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"),
			,
			"Organization",
			"Object",
			Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Counterparty) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Đối tác""';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = 'The ""Counterparty"" field is required'; fa = 'The ""Counterparty"" field is required';
				|it = 'Поле ""Контрагент"" не заполнено';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			,
			"Counterparty",
			"Object",
			Cancel);
	EndIf;
	If Not Cancel Then
		Filter = SelectingContractSearch();
		If ThisIsReconciliationBetweenOrganizations Then
			OpenForm(
				"Catalog.IntercompanyContracts.ChoiceForm",
				New Structure("Filter", Filter),
				Item);
		Else
			OpenForm(
				"Catalog.CounterpartyContracts.ChoiceForm",
				New Structure("Filter", Filter),
				Item);
		EndIf;
	EndIf; 
EndProcedure

&AtClient
Function SelectingContractSearch()
	Filter = New Structure;
	Filter.Insert("Organization", Object.Organization);
	If ThisIsReconciliationBetweenOrganizations Then
		Filter.Insert("CompanyRecipient", Object.Counterparty);
	Else
		Filter.Insert("Counterparty", Object.Counterparty);
	EndIf;
	Return Filter;
EndFunction

#Region MaintenanceOfLongOperations

&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	If ValueIsFilled(JobID) And JobCompleted(JobID) Then 
		IdleParameters.OutputIdleWindow = False;
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("DistributionByDocumentsCompletion", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

&AtServer
Procedure CancelJobExecution(JobID)
	
	If ValueIsFilled(JobID) Then
		TimeConsumingOperations.CancelJobExecution(JobID);
		JobID = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
#Region DetailedCalculationRecords

	#Region ThereAreDiscrepancies
	#Region DocumentAmountCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingDocumentAmountCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DocumentAmountCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DocumentAmount");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region DocumentAmountCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingAmountARAPCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountARAPCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountARAP");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region DebtAmountCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingDebtAmountCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DebtAmountCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DebtAmount_");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region AmountPrepaymentCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingAmountPrepaymentCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountPrepaymentCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountPrepayment");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region AmountARAPCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingAmountARAPCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountARAPCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountARAP");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	#EndRegion

	#Region DecorationBlueTextDr
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingDebitCredit.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	#Region FilterCustomersDr
	SelectionGroupClients = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupClients.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupClients.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.PaymentType_");
	ItemFilter.RightValue = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ItemFilter = SelectionGroupClients.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DebtAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountPrepayment");
	#EndRegion
	
	#Region FilterVendorsDr
	SelectionGroupSuppliers = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupSuppliers.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupSuppliers.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.PaymentType_");
	ItemFilter.RightValue = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ItemFilter = SelectionGroupSuppliers.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DebtAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountPrepayment");
	#EndRegion
	
	SetupAppearanceDrCr(Item, "Dr");
	#EndRegion

	#Region DecorationRedTextCr
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsARAPAccountingDebitCredit.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	#Region FilterCustomersCr
	SelectionGroupClients = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupClients.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupClients.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.PaymentType_");
	ItemFilter.RightValue = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ItemFilter = SelectionGroupClients.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DebtAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountPrepayment");
	#EndRegion
	
	#Region FilterVendorsCr
	SelectionGroupSuppliers = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupSuppliers.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupSuppliers.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.PaymentType_");
	ItemFilter.RightValue = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ItemFilter = SelectionGroupSuppliers.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.DebtAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsARAPAccounting.AmountPrepayment");
	#EndRegion
	
	SetupAppearanceDrCr(Item, "Cr");
	#EndRegion

#EndRegion


#Region DetailedRecordsOfFinancialInstruments

	#Region ThereAreDiscrepancies
	#Region PrincipalDebtCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLoansAmountCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebtCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region InterestCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLoansAmountInterestCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.InterestCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region FeeCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLoansAmountCommissionCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.FeeCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region LeaseObligationsCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLeasingLeaseObligationsCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligationsCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region DepositPaymentCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLeasingSecurityPaymentCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPaymentCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region RentalServiceCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLeasingRentalServiceCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalServiceCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	#Region BuyoutValueCounterparty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLeasingPurchasePriceCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValueCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	#EndRegion

	#Region DecorationBlueTextDr
	
	#Region SelectingAllSumsGreaterThanZero
	
	#Region LoansDebitCredit
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLoansDebitCredit.Name);
	
	// Creditdeposits >= 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	// Leasing = 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	SetupAppearanceDrCr(Item, "Dr");
	#EndRegion
	
	#Region LeasingDebitCredit
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedLeasingRecordsDebitCredit.Name);
	
	// Creditdeposits = 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	// Rent >= 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	SetupAppearanceDrCr(Item, "Dr");
	#EndRegion
	
	#EndRegion
	
	SetupAppearanceDrCr(Item, "Dr");
	#EndRegion
	
	#Region DecorationRedTextCr
	
	#Region SelectingAllSumsLessThanZero
	
	#Region LoansDebitCredit
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLoansDebitCredit.Name);
	
	// Creditdeposits <= 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	// Rent = 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	SetupAppearanceDrCr(Item, "Cr");
	#EndRegion
	
	#Region LeasingDebitCredit
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedLeasingRecordsDebitCredit.Name);
	
	// Creditdeposits = 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	// Rent <= 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;
	
	SetupAppearanceDrCr(Item, "Cr");
	#EndRegion
	
	#EndRegion
	
	#EndRegion

	#Region DesignBlackTextDrCR
	
	#Region SelectingAllSumsGreaterAndLessThanZero
	
	#Region LoansDebitCredit
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedRecordsLoansDebitCredit.Name);
	
	// Creditdeposits > 0
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	 // And creditdeposits < 0
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	// Rent = 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	SetupAppearanceDrCr(Item, "DrCr");
	#EndRegion
	
	#Region LeasingDebitCredit
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailedLeasingRecordsDebitCredit.Name);
	
	// Creditdeposits = 0
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.PrincipalDebt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Interests");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.Fee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	// Rent > 0
	SelectionGroupOr = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	// And Rent < 0
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.LeaseObligations");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.DepositPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.RentalService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecordsFinancialInstruments.BuyoutValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	SetupAppearanceDrCr(Item, "DrCr");
	#EndRegion
	
	#EndRegion
	
	#EndRegion

#EndRegion

EndProcedure

&AtServer
Procedure SetupAppearanceDrCr(Item, Var_AccountType)
	
	If Var_AccountType = "Dr" Then
		FieldText = NStr("vi = 'Nợ';
						|ru = 'Дт';
						|en = 'Dr'; fa = 'بد';
						|it = 'Дт';
						|pl = 'Wn';
						|tr = 'Borç'");
		TextColor = StyleColors.DebitTextColor;
		HorizontalPositionOfText =  HorizontalAlign.Left;
	ElsIf Var_AccountType = "Cr" Then
		FieldText = NStr("vi = 'Có';
						|ru = 'Кт';
						|en = 'Cr'; fa = 'بس';
						|it = 'Кт';
						|pl = 'Ma';
						|tr = 'Alacak'");
		TextColor = StyleColors.CreditTextColor;
		HorizontalPositionOfText =  HorizontalAlign.Right;
	ElsIf Var_AccountType = "DrCr" Then
		FieldText = NStr("vi = 'Nợ/Có';
						|ru = 'Дт/Кт';
						|en = 'Dr/Cr'; fa = 'بد/بس';
						|it = 'Дт/Кт';
						|pl = 'Dr/Cr';
						|tr = 'Borç/Alacak'");
		TextColor = Undefined;
		HorizontalPositionOfText =  HorizontalAlign.Center;
	EndIf;
	
	Item.Appearance.SetParameterValue("Text", FieldText);
	Item.Appearance.SetParameterValue("TextColor", TextColor);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalPositionOfText);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatus()
	
	OnlyViewItems = (Object.Status = Enums.StatusesOfARAPReconciliation.Reconciled);
	
	ItemArray = New Array();
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Organization");
	ItemArray.Add("BeginOfPeriod");
	ItemArray.Add("EndOfPeriod");
	ItemArray.Add("Counterparty");
	ItemArray.Add("ThereAreDiscrepancies");
	ItemArray.Add("FilterSettings_2");
	ItemArray.Add("FormFillInByBalance");
		
	// Groups of controls
	ItemArray.Add("HeaderDetailedRecords");
	ItemArray.Add("RecordsCalculations");
	ItemArray.Add("FinancialInstrumentsDetailedRecordsHeader");
	ItemArray.Add("RecordsFinancialInstruments");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", OnlyViewItems);
	
	ItemArray = New Array();             
	
	// Header Controls
	ItemArray.Add("SetDateInterval");
	ItemArray.Add("CounterpartyDataMustBeFilledInByBalances");
	ItemArray.Add("CalculationsCommandFillInOnBalances");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Not OnlyViewItems);

EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Items.HeaderDetailedRecords.Visible = Not ShowGroupingsCalculations;
	Items.FinancialInstrumentsDetailedRecordsHeader.Visible = Not ShowGroupingsOfFinancialInstruments;
	
	If ShowGroupingsCalculations Then
		Items.RecordsCalculations.CurrentPage = Items.TheCalculationsGroupingPage;
	Else
		Items.RecordsCalculations.CurrentPage = Items.PageDetailedRecordsCalculations;
	EndIf;
	
	ThereIsACommission = ThereAreSums("DetailedRecordsFinancialInstruments", "Fee");
	ThereIsBuyoutOfLeasedAssets = ThereAreSums("DetailedRecordsFinancialInstruments", "BuyoutValue");
	If ShowGroupingsOfFinancialInstruments Then
		Items.RecordsFinancialInstruments.CurrentPage = Items.FinancialInstrumentsGroupingPage;
	Else
		Items.RecordsFinancialInstruments.CurrentPage = Items.DetailedRecordsPageFinancialInstruments;
		If TypeOf(FilterFinancialInstruments) = Type("CatalogRef.LoanAndDepositContracts") Then
			Items.PagesDetailedRecordsLoansLeasing.CurrentPage = Items.PageDetailedRecordsLoans;
			Items.TheResultOfTheCommission.Visible = ThereIsACommission;
		Else
			Items.PagesDetailedRecordsLoansLeasing.CurrentPage = Items.PageDetailedRecordsLeasing;
			Items.TotalPurchasePrice_3.Visible = ThereIsBuyoutOfLeasedAssets;
		EndIf;
	EndIf;
	
	Items.DetailedRecordsARAPAccountingDocumentAmount.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsARAPAccountingDocumentAmountCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsCalculationsSettlements.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordingOfLoansAmount.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLoansAmountCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLoansAmountInterest.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLoansAmountInterestCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordingOfTheLoanAmountCommission.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLoansAmountCommissionCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLeasingLeaseObligations.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLeasingLeaseObligationsCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordingOfTheLeaseSecurityPayment.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLeasingSecurityPaymentCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLeasingRentalService.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLeasingRentalServiceCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordingOfTheLeaseTheResidualValue.ShowInHeader = Object.ThereAreDiscrepancies;
	Items.DetailedRecordsLeasingPurchasePriceCounterparty.ShowInHeader = Object.ThereAreDiscrepancies;
	
	Items.ChiefAccountant.Visible = Object.EmployeeInCharge_ = Enums.PersonsResponsibleAndCompanies.ChiefAccountant;
	Items.Director.Visible = Not Items.ChiefAccountant.Visible;
	Items.ChiefAccountantOfCounterpartyCompany.Visible = Object.CounterpartyCompanyPersonResponsible = Enums.PersonsResponsibleAndCompanies.ChiefAccountant;
	Items.CounterpartyCompanyManager.Visible = Not Items.ChiefAccountantOfCounterpartyCompany.Visible;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ShowCalculationType", Not Object.SplitByARAPTypes);
	ParametersStructure.Insert("ShowPartner", Not Object.SplitByPartners);
	ParametersStructure.Insert("ShowContract", Not Object.SplitByContracts);
	ParametersStructure.Insert("ThereAreDiscrepancies", Object.ThereAreDiscrepancies);
	ParametersStructure.Insert("ThereIsACommission", ThereIsACommission);
	ParametersStructure.Insert("ThereIsBuyoutOfLeasedAssets", ThereIsBuyoutOfLeasedAssets);
	
	Documents.ARAPReconciliation2_4.FillInNamesOfBusinessTransactionDetails(
		ParametersStructure, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	SetVisibility1();
	SetAvailabilityOfItemsByStatus();
	
	Items.GroupCounterpartyData.Visible = Not ThisIsReconciliationBetweenOrganizations;
	Items.GroupDataOfCounterpartySOrganization.Visible = ThisIsReconciliationBetweenOrganizations;
	Items.FinancialInstrumentsPage.Visible = Not ThisIsReconciliationBetweenOrganizations;
	
	If ThisIsReconciliationBetweenOrganizations Then
		Items.ContactPerson.ChoiceParameterLinks = New FixedArray(New Array);
		Items.GroupingsARAPContract.TypeRestriction = New TypeDescription("CatalogRef.IntercompanyContracts");
		Items.DetailedRecordsARAPAccountingContract.TypeRestriction = New TypeDescription("CatalogRef.IntercompanyContracts");
	Else
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Partner"));
		Items.ContactPerson.ChoiceParameterLinks = New FixedArray(ParametersArray);
		Items.GroupingsARAPContract.TypeRestriction = New TypeDescription("CatalogRef.CounterpartyContracts");
		Items.DetailedRecordsARAPAccountingContract.TypeRestriction = New TypeDescription("CatalogRef.CounterpartyContracts");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByBalanceServer()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Filter_Settings = New ValueStorage(LinkerSelection.GetSettings());
	Documents.ARAPReconciliation2_4.FillInCalculationData(DocumentObject);
	ValueToFormAttribute(DocumentObject, "Object");
	
	SetVisibilityOfReconciliationPages();

EndProcedure

&AtServer
Procedure FillInLineForSettlementDocumentServer(DocumentRef, DocumentDetails, ARAPCurrency)
	
	SetPrivilegedMode(True);
	
	CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(Object.Organization, Object.Date);
	RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation, 
								"FullDescr");
	CounterpartyInformation_  = PrintFormGeneration.InformationAboutLegalEntity(Object.Counterparty,  Object.Date);
	CounterpartyName_ = PrintFormGeneration.OrganizationDescription(CounterpartyInformation_, 
							  "FullDescr");
	
	StructureOfParticipantsPresentations = New Structure;
	StructureOfParticipantsPresentations.Insert("RepresentationOfTheOrganization", RepresentationOfTheOrganization);
	StructureOfParticipantsPresentations.Insert("CounterpartyName_", CounterpartyName_);
	
	ThisIsIncomingDocument = DocumentRef.Metadata().Attributes.Find("IncomingDocumentNumber") <> Undefined;
	ThisIsIntercampanyDocument = TypeOf(DocumentRef) = Type("DocumentRef.CustomerInvoiceIntercompany")
		Or TypeOf(DocumentRef) = Type("DocumentRef.CommissionReportIntercompany");
	ThisIsContract = TypeOf(DocumentRef) = Type("CatalogRef.CounterpartyContracts")
		Or TypeOf(DocumentRef) = Type("CatalogRef.IntercompanyContracts");
	
	AttributesRow = "Number, Date, " + ?(ThisIsContract,"ARAPCurrency","Currency");
	
	If ThisIsIncomingDocument Then
		
		AttributesRow = AttributesRow + ", IncomingDocumentNumber, IncomingDocumentDate, ExternalDocumentName";
		If ThisIsIntercampanyDocument Then
			AttributesRow = AttributesRow + "Organization";
		EndIf;
		
	EndIf;
	
	AttributesValues = Common.ObjectAttributesValues(DocumentRef, AttributesRow);
	PresentationOfDocument = "";
	If ValueIsFilled(AttributesValues.Number) Then
		
		If ThisIsIncomingDocument Then
			PresentationOfDocument = AttributesValues.ExternalDocumentName;
			If Not ThisIsIntercampanyDocument
				Or (TypeOf(DocumentRef) = Type("DocumentRef.CommissionReportIntercompany")
					And AttributesValues.Organization = Object.Organization)
				Or (TypeOf(DocumentRef) = Type("DocumentRef.CustomerInvoiceIntercompany")
					And AttributesValues.Organization <> Object.Organization) Then
				
				AttributesValues.Number = AttributesValues.IncomingDocumentNumber;
				AttributesValues.Date  = AttributesValues.IncomingDocumentDate;
				
			EndIf;
			
		EndIf;
		
		DocumentData = Documents.ARAPReconciliation2_4.DocumentData();
		DocumentData.ARAPDocument = DocumentRef;
		DocumentData.DocumentNumber = AttributesValues.Number;
		DocumentData.DocumentDate = AttributesValues.Date;
		DocumentData.SourceDocumentName = PresentationOfDocument;
		DocumentDetails = Documents.ARAPReconciliation2_4.DescriptionOfSettlementDocument(DocumentData);
		ARAPCurrency = ?(ThisIsContract,AttributesValues.ARAPCurrency,AttributesValues.Currency);
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf; 
	
EndProcedure

&AtServerNoContext
Function CounterpartySPartner(Counterparty)
	
	If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		Return Catalogs.Partners.OurEnterprise;
	ElsIf ValueIsFilled(Counterparty) Then 
		Return Common.ObjectAttributeValue(Counterparty, "Partner");
	Else
		Return Catalogs.Partners.EmptyRef();
	EndIf;
	
EndFunction

&AtClient
Procedure ManagerSFullNameContactPersonStartOfSelection()
	
	If ValueIsFilled(Object.Counterparty) Then
		Filter = New Structure("Owner", Partner);
		OpenForm("Catalog.ContactPersonsForPartners.ChoiceForm",
			New Structure("Filter", Filter),
			ThisForm);
	Else
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Đối tác""';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = 'The ""Counterparty"" field is required'; fa = 'The ""Counterparty"" field is required';
				|it = 'Поле ""Контрагент"" не заполнено';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			,
			"Counterparty",
			"Object");
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillPositionBySelectedValue(ContactPerson)
	Object.JobTitleOfCounterpartyExecutive = Common.ObjectAttributeValue(ContactPerson,"JobTitleOnBusinessCard");
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Function DetailSelectionParameters(ARAPType)
	
	TheseAreCalculations = Items.GroupPages.CurrentPage = Items.PageSettlements;
	
	If ARAPType = "Calculations" Then
		NameOfTablePartDetailedRecords = "DetailedRecordsARAPAccounting";
		NameOfTabularPartOfDimension     = "GroupingsARAP";
		PropsNameShowDimensions  = "ShowGroupingsCalculations";
	ElsIf ARAPType = "FinancialInstruments" Then
		NameOfTablePartDetailedRecords = "DetailedRecordsFinancialInstruments";
		NameOfTabularPartOfDimension     = "GroupingsFinancialInstruments";
		PropsNameShowDimensions  = "ShowGroupingsOfFinancialInstruments";
	EndIf;
	
	FilterParameters = New Structure;
	
	FilterParameters.Insert("TabularSection", NameOfTablePartDetailedRecords);
	FilterParameters.Insert("FormTable",   NameOfTablePartDetailedRecords);
	FilterParameters.Insert("FilterField", "ARAPObject");
	FilterParameters.Insert("GroupingDetails_1", "DetailsOfTheCalculationObject");
	FilterParameters.Insert("FilterValue", Undefined);
	FilterParameters.Insert("SelectionValueField", "FilterCalculations");
	FilterParameters.Insert("SummaryFields", "DebtAmount_,DebtAmountLocal,AmountPrepayment,PrepaymentAmountLocal_");
	FilterParameters.Insert("Contract", Object.Contract);
	If Not TheseAreCalculations Then
		FilterParameters.Insert("FormTable", "DetailedRecordsLoans");
		FilterParameters.Insert("FilterField", "Contract");
		FilterParameters.Insert("SelectionValueField", "FilterFinancialInstruments");
		FilterParameters.Insert("GroupingDetails_1", "DetailsOfTheContract");
		FilterParameters.Insert("SummaryFields", "PrincipalDebt,Interests,Fee");
	EndIf;
	
	If Items[NameOfTabularPartOfDimension].CurrentData = Undefined Then
		Items[NameOfTabularPartOfDimension].CurrentRow = Object[NameOfTabularPartOfDimension][0].GetID();
	EndIf;
	FilterParameters.Insert("GroupingTable", NameOfTabularPartOfDimension);
	CurrentData = Items[NameOfTabularPartOfDimension].CurrentData;
	If CurrentData <> Undefined Then
		FilterParameters.Insert("Filter", New Structure);
		If TheseAreCalculations Then
			FilterParameters.Filter.Insert("ARAPObject", CurrentData.ARAPObject);
			FilterParameters.Filter.Insert("PaymentType_", CurrentData.PaymentType_);
			FilterParameters.Filter.Insert("Partner", CurrentData.Partner);
			FilterParameters.Filter.Insert("Contract", CurrentData.Contract);
			FilterParameters.Insert("FilterValue", CurrentData.ARAPObject);
		Else
			FilterParameters.Filter.Insert("Contract", CurrentData.Contract);
			FilterParameters.Insert("FilterValue", CurrentData.Contract);
			If ValueIsFilled(Object.Contract) Then
				FilterParameters.Insert("FilterValue", Object.Contract);
			EndIf;
			If TypeOf(FilterParameters.FilterValue) = Type("CatalogRef.LeaseContract") Then
				FilterParameters.Insert("FormTable", "DetailedLeasingRecords");
				FilterParameters.Insert("SummaryFields", "LeaseObligations,DepositPayment,RentalService,BuyoutValue");
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(Object.PaymentType_) Then
			FilterParameters.Insert("PaymentType_", CurrentData.PaymentType_);
		EndIf;
		If Not ValueIsFilled(Object.Partner) Then
			FilterParameters.Insert("Partner", CurrentData.Partner);
		EndIf;
		If Not ValueIsFilled(Object.Contract) Then
			FilterParameters.Insert("Contract", CurrentData.Contract);
		EndIf;
	Else

		ThisForm[PropsNameShowDimensions] = Not ThisForm[PropsNameShowDimensions];
		
		TextNoCalculationObjectSelected = NStr("vi = 'Chưa chọn đối tượng hạch toán trên thẻ ""Đối tượng hạch toán""';
												|ru = 'Не выбран объект расчетов на закладке ""Объекты расчетов""';
												|en = 'No AR/AP object is selected on the ""AR/AP objects"" tab'; fa = 'No AR/AP object is selected on the ""AR/AP objects"" tab';
												|it = 'Не выбран объект расчетов на закладке ""Объекты расчетов""';
												|pl = 'Nie wybrano obiektu rozliczeń na karcie ""Obiekty rozliczeń""';
												|tr = '""Alacak/borç nesneleri"" sekmesinde alacak nesnesi seçili değil'");
		TextIsNotSelectedContract = NStr("vi = 'Chưa chọn hợp đồng trên thẻ ""Hợp đồng""';
										|ru = 'Не выбран договор на закладке ""Договоры""';
										|en = 'The contract is not selected on the ""Contracts"" tab'; fa = 'The contract is not selected on the ""Contracts"" tab';
										|it = 'Не выбран договор на закладке ""Договоры""';
										|pl = 'Nie wybrano umowy na karcie ""Umowy""';
										|tr = '""Sözleşmeler"" sekmesinde sözleşme seçilmemiş'");
		CommonClient.MessageToUser(
			?(TheseAreCalculations, TextNoCalculationObjectSelected, TextIsNotSelectedContract),
			,
			NameOfTabularPartOfDimension,
			"Object");
		FilterParameters = Undefined;
	EndIf;

	Return FilterParameters;
	
EndFunction

&AtServer
Procedure SwitchToDetail(FilterParameters)
	
	If FilterParameters = Undefined Then
		Return;
	EndIf;
	
	AllSelectionObjects = Object[FilterParameters.GroupingTable].Unload();
	AllSelectionObjects.GroupBy(FilterParameters.FilterField);
	AllSelectionObjects.Sort(FilterParameters.FilterField);
	AllSelectionObjects = AllSelectionObjects.UnloadColumn(FilterParameters.FilterField);
	ChoiceList = Items[FilterParameters.SelectionValueField].ChoiceList;
	ChoiceList.Clear();
	ChoiceList.LoadValues(AllSelectionObjects);
	
	SetDetailSelection(FilterParameters);
	
EndProcedure

&AtClient
Procedure EnableSelectionOfDetailedRecords(ARAPType, FilterField, FilterValue)
	
	FilterParameters = DetailSelectionParameters(ARAPType);
	If FilterParameters = Undefined Then
		Return;
	EndIf;
	
	FilterParameters.FilterValue = FilterValue;
	FilterParameters.Filter = New Structure(FilterField, FilterValue);
	SetFollowingObject(FilterParameters, Undefined);
	
	If ARAPType = "Calculations" Then
		Items.DetailedRecordsARAPAccounting.ChangeRowSet = True;
	Else
		Items.DetailedRecordsLoans.ChangeRowSet = True;
		Items.DetailedLeasingRecords.ChangeRowSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDetailSelection(FilterParameters)
	
	If FilterParameters = Undefined Then
		Return;
	EndIf;
	
	ThisForm[FilterParameters.SelectionValueField] = FilterParameters.FilterValue;
	Items[FilterParameters.FormTable].RowFilter = New FixedStructure(FilterParameters.Filter);
	
	ObjectDetails_ = New Structure("PaymentType_, Partner, Contract");
	FillPropertyValues(ObjectDetails_, FilterParameters.Filter);
	If ValueIsFilled(Object.PaymentType_) Then
		ObjectDetails_.Insert("PaymentType_", Object.PaymentType_);
	EndIf;
	If ValueIsFilled(Object.Partner) Then
		ObjectDetails_.Insert("Partner", Object.Partner);
	EndIf;
	If ValueIsFilled(Object.Contract) Then
		ObjectDetails_.Insert("Contract", Object.Contract);
	EndIf;
	
	TheseAreCalculations = Items.GroupPages.CurrentPage = Items.PageSettlements;
	GroupingDetails_1 = String(ObjectDetails_.Partner);
	If ValueIsFilled(ObjectDetails_.Contract) And TheseAreCalculations Then
		GroupingDetails_1 = GroupingDetails_1 + ?(Not IsBlankString(GroupingDetails_1),"; ","") + String(ObjectDetails_.Contract);
	EndIf;
	ThisForm[FilterParameters.GroupingDetails_1] = GroupingDetails_1;
	
	RecalculateResultsForCalculationObjectOnServer(FilterParameters.TabularSection, FilterParameters.Filter, FilterParameters.SummaryFields);
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure SetFollowingObject(CurrentFilter, InOppositeDirection = False)
	
	If CurrentFilter = Undefined Then
		Return;
	EndIf;
	
	Items.GroupTotalSettlement.Visible = True;
	UBound = Object[CurrentFilter.GroupingTable].Count() - 1;
	FoundRows = Object[CurrentFilter.GroupingTable].FindRows(CurrentFilter.Filter);
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;
	IndexOf = Object[CurrentFilter.GroupingTable].IndexOf(FoundRows[0]);
	
	NewIndex = IndexOf;
	If InOppositeDirection <> Undefined Then
		NewIndex = ?(InOppositeDirection, IndexOf-1, IndexOf+1);
	EndIf;
	If NewIndex < 0 Then
		NewIndex = UBound;
	EndIf;
	If NewIndex > UBound Then
		NewIndex = 0;
	EndIf;
	
	NewData = Object[CurrentFilter.GroupingTable][NewIndex];
	CurrentFilter.Filter[CurrentFilter.FilterField] = NewData[CurrentFilter.FilterField];
	CurrentFilter.FilterValue = NewData[CurrentFilter.FilterField];
	If NewData <> Undefined Then
		FormTable = Items[CurrentFilter.GroupingTable]; // FormTable -
		FormTable.CurrentRow = NewData.GetID();
		
		If TypeOf(CurrentFilter.FilterValue) = Type("CatalogRef.LoanAndDepositContracts") Then
			CurrentFilter.FormTable = "DetailedRecordsLoans";
			CurrentFilter.SummaryFields = "PrincipalDebt,Interests,Fee";
		EndIf;
		If TypeOf(CurrentFilter.FilterValue) = Type("CatalogRef.LeaseContract") Then
			CurrentFilter.FormTable = "DetailedLeasingRecords";
			CurrentFilter.SummaryFields = "LeaseObligations,DepositPayment,RentalService,BuyoutValue";
		EndIf;
		//Add selections on the current line if there is no selection in general for the entire document
		If CurrentFilter.TabularSection <> "DetailedRecordsFinancialInstruments" Then
			If Not ValueIsFilled(Object.PaymentType_) Then
				CurrentFilter.Filter.Insert("PaymentType_", NewData.PaymentType_);
			EndIf;
			If Not ValueIsFilled(Object.Partner) Then
				CurrentFilter.Filter.Insert("Partner", NewData.Partner);
			EndIf;
		EndIf;
		If Not ValueIsFilled(Object.Contract) Then
			CurrentFilter.Filter.Insert("Contract", NewData.Contract);
		EndIf;
		
		SetDetailSelection(CurrentFilter);
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfExtendedSelectionForm()
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
	If FilterContractsWithoutTurnover = Undefined Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover", True);
		FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
		FilterContractsWithoutTurnover.Presentation = NStr("vi = 'Bao gồm các hợp đồng không có phát sinh trong kỳ';
															|ru = 'Включать договора без оборотов в периоде';
															|en = 'Include contracts without cash transactions during the given period'; fa = 'Include contracts without cash transactions during the given period';
															|it = 'Включать договора без оборотов в периоде';
															|pl = 'Uwzględnij umowy bez obrotu w tym okresie';
															|tr = 'Cirosu olmayan sözleşmeleri döneme dahil edin'");
	EndIf;
	
	Equal = DataCompositionComparisonType.Equal;
	FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Organization", Object.Organization, Equal);
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		If TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
			Partner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Partner", Partner, Equal);
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "CompanyCounterparty",,, False);
		Else
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "CompanyCounterparty", Object.Counterparty, Equal);
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Partner",,, False);
		EndIf;
	Else
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Counterparty", Object.Counterparty, Equal);
	EndIf;
	If Object.SplitByARAPTypes Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "PaymentType_", Object.PaymentType_, Equal);
	EndIf;
	If Object.SplitByPartners Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Partner", Object.Partner, Equal);
	EndIf;
	If Object.SplitByContracts Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Contract", Object.Contract, Equal);
	EndIf;
	
	OpeningParameters = New Structure("Filter_Settings", LinkerSelection.GetSettings());
	
	Return OpeningParameters;
	
EndFunction

&AtClient
Procedure SetAdvancedSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	InstallSelectionsOnServer(Result.Filter_Settings);
	
EndProcedure

&AtServer
Procedure InstallSelectionsOnServer(Val Filter_Settings)
	
	Modified = Not DataCompositionClientServer.SelectionsUsedAreEqual(LinkerSelection.Settings, Filter_Settings);
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	
	SetPropsBySelectionValue("PaymentType_", Filter_Settings);
	SetPropsBySelectionValue("Partner", Filter_Settings);
	SetPropsBySelectionValue("Contract", Filter_Settings);
	If UseMultipleCompanies Then
		SetPropsBySelectionValue("Organization", Filter_Settings);
	EndIf;
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter,"Partner",,DataCompositionComparisonType.Equal);
		If FilterElement <> Undefined And FilterElement.Use Then
			Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FilterElement.RightValue);
			Object.Counterparty = Counterparty; 
		Else
			FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter,"CompanyCounterparty",,DataCompositionComparisonType.Equal);
			If FilterElement <> Undefined And FilterElement.Use Then
				Object.Counterparty = FilterElement.RightValue;
			EndIf;
		EndIf;
	Else
		SetPropsBySelectionValue("Counterparty", Filter_Settings);
	EndIf;
	
	LinkerSelection.LoadSettings(Filter_Settings);
	
	If TheCounterpartyPriorToTheChange <> Object.Counterparty Then
		CounterpartyOnChangeServer();
	EndIf;
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure SetPropsBySelectionValue(Var_AttributeName, Filter_Settings)
	
	Object[Var_AttributeName] = Undefined;
	If Var_AttributeName = "PaymentType_" Then
		Object["SplitByARAPTypes"] = False;
		
	ElsIf Var_AttributeName = "Partner" Then
		Object["SplitByPartners"] = False;
		
	ElsIf Var_AttributeName = "Contract" Then
		Object["SplitByContracts"] = False;
		
	EndIf;
	
	FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter,Var_AttributeName,,DataCompositionComparisonType.Equal);
	If FilterElement = Undefined Then
		Return;
	EndIf;
	
	If Var_AttributeName = "PaymentType_" Then
		Object["SplitByARAPTypes"] = FilterElement.Use;
		
	ElsIf Var_AttributeName = "Partner" Then
		Object["SplitByPartners"] = FilterElement.Use;
		
	ElsIf Var_AttributeName = "Contract" Then
		Object["SplitByContracts"] = FilterElement.Use;
		
	EndIf;
		
	If FilterElement.Use Then
		Object[Var_AttributeName] = FilterElement.RightValue;
	Else
		FilterElement.RightValue = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateResultsForCalculationObjectOnServer(TabularSectionName, Filter, NamesOfTotalsFields)
	
	SummaryFields = StrSplit(NamesOfTotalsFields, ",");
	CalculationObjectData = Object[TabularSectionName].Unload().Copy(Filter);
	For Each TotalField In SummaryFields Do
		SummaryOfDetailedRecords[0][TotalField] = CalculationObjectData.Total(TotalField);
	EndDo;
	
EndProcedure

&AtServer
Procedure ThereAreDiscrepanciesWhenChangingOnServer()
	
	SetVisibility1();
	For Each String In Object.DetailedRecordsARAPAccounting Do
		String["DocumentAmountCounterparty"] = ?(Object.ThereAreDiscrepancies, String["DocumentAmount"], 0);
		String["DebtAmountCounterparty"] = ?(Object.ThereAreDiscrepancies, String["DebtAmount_"], 0);
		String["AmountPrepaymentCounterparty"] = ?(Object.ThereAreDiscrepancies, String["AmountPrepayment"], 0);
		String["AmountARAPCounterparty"] = ?(Object.ThereAreDiscrepancies, String["AmountARAP"], 0);
	EndDo;
	For Each String In Object.DetailedRecordsFinancialInstruments Do
		String["PrincipalDebtCounterparty"] = ?(Object.ThereAreDiscrepancies, String["PrincipalDebt"], 0);
		String["InterestCounterparty"] = ?(Object.ThereAreDiscrepancies, String["Interests"], 0);
		String["FeeCounterparty"] = ?(Object.ThereAreDiscrepancies, String["PrincipalDebt"], 0);
		String["LeaseObligationsCounterparty"] = ?(Object.ThereAreDiscrepancies, String["LeaseObligations"], 0);
		String["DepositPaymentCounterparty"] = ?(Object.ThereAreDiscrepancies, String["DepositPayment"], 0);
		String["RentalServiceCounterparty"] = ?(Object.ThereAreDiscrepancies, String["RentalService"], 0);
		String["BuyoutValueCounterparty"] = ?(Object.ThereAreDiscrepancies, String["BuyoutValue"], 0);
	EndDo;
	
EndProcedure

&AtServer
Function ThereAreTasksForDistribution()
	
	DimensionToCalculation = Documents.ARAPReconciliation2_4.DimensionToCalculation(
							Object.Organization, Object.Counterparty, Object.PaymentType_, Object.EndOfPeriod);
	HasJobs = DimensionToCalculation.Count() > 0;
	If HasJobs Then
		CancelJobExecution(JobID);
		
		JobDescription = NStr("vi = 'Phân bổ thanh toán theo các chứng từ được thực hiện.';
								|ru = 'Выполняется распределение расчетов по документам.';
								|en = 'Allocating settlements by documents...'; fa = 'Allocating settlements by documents...';
								|it = 'Выполняется распределение расчетов по документам.';
								|pl = 'Jest wykonywany podział rozliczeń według dokumentów.';
								|tr = 'Hesaplamaların belgeler üzerinde dağıtımını gerçekleştirir.'");
		ProcedureName        = "Documents.ARAPReconciliation2_4.DistributionOfCalculationsByDocuments";
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.RunInBackground = True;
		
		StructureOfCalculations = ARAPAllocationServerCall.CalculationAnalysts();
		StructureOfCalculations.AccountingAnalyticsForPartners = DimensionToCalculation;
		StructureOfCalculations.Companies = CommonClientServer.ValueInArray(Object.Organization);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("CalculationAnalysts", StructureOfCalculations);
		MethodParameters.Insert("EndOfPeriod", EndOfDay(Object.EndOfPeriod));
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, MethodParameters, ExecutionParameters);
		
		JobID = TimeConsumingOperation.JobID;
	EndIf;
	
	Return HasJobs;
	
EndFunction

&AtServer
Function ThereAreSums(TabularSectionName, ColumnName)
	
	For Each Record In Object[TabularSectionName] Do
		If Record[ColumnName] <> 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure SetVisibilityOfReconciliationPages()
	
	If Object.GroupingsARAP.Count() = 0
		And Object.GroupingsFinancialInstruments.Count() > 0 Then
		Items.GroupPages.CurrentPage = Items.FinancialInstrumentsPage;
	Else
		Items.GroupPages.CurrentPage = Items.PageSettlements;
	EndIf;
	
EndProcedure

#EndRegion

#Region OutdatedReconciliation

&AtClient
Procedure MutualSettlementsDetailsClick(Item, StandardProcessing)
	
	Return;
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
