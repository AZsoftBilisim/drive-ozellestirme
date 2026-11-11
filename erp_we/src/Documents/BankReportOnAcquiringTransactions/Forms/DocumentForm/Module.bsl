#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankReportOnAcquiringTransactions.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	FormItemsManagement();
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.BankReportOnAcquiringTransactions.Form.PaymentChoiceForm" Then
		GetPaymentsFromVault(SelectionResult.SelectIncomingPayments, SelectionResult.AddressOfPaymentsInTheStorage);
		CalculateDocumentAmount();
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankReportOnAcquiringTransactions.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BankReportOnAcquiringTransactions", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	PerformVerificationOfFillingOutContractOfCommission = (Object.RecordCommission And Object.FeeAmount <> 0
		And Object.KeepRecordsOfCommissionInARAPAccounting);
		
	ExcludeVerificationOfFillingInARAPObjectOfFee = False;
	If Not PerformVerificationOfFillingOutContractOfCommission Then
		NotCheckedAttributeArray.Add("CommissionAgreement");
		ExcludeVerificationOfFillingInARAPObjectOfFee = True;
	EndIf;
	
	If Not ValueIsFilled(CommissionAgreement) Then
		ExcludeVerificationOfFillingInARAPObjectOfFee = True; 
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If ExcludeVerificationOfFillingInARAPObjectOfFee Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExcludeVerificationOfFillingInARAPObjectOfFee", True);
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		ObjectAttributesToBeChecked = CheckedAttributes.Find("Object");
		If ObjectAttributesToBeChecked <> Undefined Then
			CheckedAttributes.Delete(ObjectAttributesToBeChecked);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AcquiringContractOnChange(Item)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Purchases;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("AcquiringContractOnChangeCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
	AcquiringContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure AcquiringContractOnChangeCompletion(Result, AdditionalParameters) Export 
	
	Object.Returns.Clear();
	Object.AmountOfPurchases = 0;
	Object.AmountOfReturns = 0;
	Object.FeeAmount = 0;
	Object.DocumentAmount = 0;
	
EndProcedure

&AtServer
Procedure AcquiringContractOnChangeServer()
	
	AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(Object.AcquiringContract);
	
	POSTerminalsAreUsed = AttributesValues.POSTerminalsAreUsed;
	FixedFeeRate = AttributesValues.FixedFeeRate;
	MakingPaymentMethod = AttributesValues.MakingPaymentMethod;
	
	Object.Organization    = AttributesValues.Organization;
	Object.Currency         = AttributesValues.Currency;
	
	Object.DetailedTransactionReconciliation = AttributesValues.DetailedTransactionReconciliation;
	Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.InReport);
	
	If Object.RecordCommission Then
		
		If AttributesValues.FixedFeeRate Then
			CommissionRate = AttributesValues.CommissionRate;
		Else
			CommissionRate = 0;
		EndIf;
		
		Object.ExpenseItem    = AttributesValues.ExpenseItem;
		Object.DimensionOfExpenses = AttributesValues.DimensionOfExpenses;
		Object.Department     = AttributesValues.ExpensesBusinessUnit;
		Object.KeepRecordsOfCommissionInARAPAccounting = AttributesValues.KeepRecordsOfCommissionInARAPAccounting;
		Object.CommissionARAPObject = AttributesValues.CommissionARAPObject;
		CommissionAgreement = ContractARAPObjectOfFee(Object.CommissionARAPObject);
	Else
		Object.FeeAmount = 0;
		Object.KeepRecordsOfCommissionInARAPAccounting = False;
		Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	If Not Object.DetailedTransactionReconciliation And Not Object.RecordCommission Then
		Common.MessageToUser(
			NStr("vi = 'Hợp đồng kết nối được chọn đến hệ thống thanh toán không xem xét việc nhập báo cáo của ngân hàng theo dịch vụ thanh toán thẻ.';
				|ru = 'Выбранный договор подключения к платежной системе не предусматривает ввод отчетов банка по эквайрингу.';
				|en = 'The selected payment system contract does not provide for the input of bank acquiring reports.'; fa = 'The selected payment system contract does not provide for the input of bank acquiring reports.';
				|it = 'Выбранный договор подключения к платежной системе не предусматривает ввод отчетов банка по эквайрингу.';
				|pl = 'The selected payment system contract does not provide for the input of bank acquiring reports.';
				|tr = 'Seçilen ödeme sistemi bağlantı sözleşmesi, işyeri ekstrelerinin girişini sağlamamaktadır.'"));
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure FeeOnChange(Item)
	
	CalculateDocumentAmount();
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemStartListChoice(Item, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChange(Item)
	
	KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure CommissionAgreementOnChange(Item)
	
	ContractFeesOnChangesATServer();
	
EndProcedure

&AtClient
Procedure CommissionAgreementStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
	StructureOfSelectionParameters.Insert("Filter", ValuesOfSelectionOfContractFee());
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", StructureOfSelectionParameters, Item, Item);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPurchases

&AtClient
Procedure PurchasesOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateDocumentAmount();
	
EndProcedure

&AtClient
Procedure PurchasesAfterDeleteRow(Item)
	
	CalculateDocumentAmount();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReturns

&AtClient
Procedure ReturnsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateDocumentAmount();
	
EndProcedure

&AtClient
Procedure ReturnsAfterDeleteRow(Item)
	
	CalculateDocumentAmount();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheSelectionInTheReturnsTabularSection(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("AcquiringContract", NStr("vi = 'Hợp đồng kết nối đến hệ thống thanh toán';
																		|ru = 'Договор подключения к платежной системе';
																		|en = 'Payment system contract'; fa = 'قرارداد سیستم پرداخت';
																		|it = 'Contratto di connessione a un sistema di pagamento';
																		|pl = 'Umowa o podłączenie do systemu płatniczego';
																		|tr = 'Ödeme sistemine bağlama sözleşmesi'"));
	Notification = New CallbackDescription("OpenTheSelectionInTheReturnsTabularSectionCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure OpenTheSelectionInTheReturnsTabularSectionCompletion(Result, AdditionalParameters) Export
	
	AddressOfPaymentsInTheStorage = AutoTest_PutRefundsInStorage();
	
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressOfPaymentsInTheStorage", AddressOfPaymentsInTheStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Currency", Object.Currency);
	PickingParameters.Insert("AcquiringContract", Object.AcquiringContract);
	PickingParameters.Insert("POSTerminalsAreUsed", POSTerminalsAreUsed);
	PickingParameters.Insert("Date", Object.Date);
	
	OpenForm("Document.BankReportOnAcquiringTransactions.Form.PaymentChoiceForm", PickingParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheSelectionInTheTabularPartOfThePurchase(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("AcquiringContract", NStr("vi = 'Hợp đồng kết nối đến hệ thống thanh toán';
																		|ru = 'Договор подключения к платежной системе';
																		|en = 'Payment system contract'; fa = 'قرارداد سیستم پرداخت';
																		|it = 'Contratto di connessione a un sistema di pagamento';
																		|pl = 'Umowa o podłączenie do systemu płatniczego';
																		|tr = 'Ödeme sistemine bağlama sözleşmesi'"));
	Notification = New CallbackDescription("OpenTheSelectionInTheTabularPartOfThePurchaseCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure OpenTheSelectionInTheTabularPartOfThePurchaseCompletion(Result, AdditionalParameters) Export
	
	AddressOfPaymentsInTheStorage = AutoTest_PutPurchasesInStorage();
	
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressOfPaymentsInTheStorage", AddressOfPaymentsInTheStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Currency", Object.Currency);
	PickingParameters.Insert("AcquiringContract", Object.AcquiringContract);
	PickingParameters.Insert("POSTerminalsAreUsed", POSTerminalsAreUsed);
	PickingParameters.Insert("SelectIncomingPayments", True);
	PickingParameters.Insert("Date", Object.Date);
	
	OpenForm("Document.BankReportOnAcquiringTransactions.Form.PaymentChoiceForm", PickingParameters, ThisForm);
	
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region SelectionAndProcessingOfQuantityVerification

// This function is used in the AutoTest of the sales process.
//
// Returns:
//	String - the address string in the temporary storage containing the result of unloading the tabular part of the Purchase.
//
&AtServer
Function AutoTest_PutPurchasesInStorage() Export 

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Object.Purchases.Unload(,"PaymentDate, POSTerminal, AuthorizationCode, PaymentCardNumber, Sum"),
		UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

// This function is used in the AutoTest of the sales process.
//
// Returns:
//	String - the address string in the temporary storage containing the result of unloading the table part Returns.
//
&AtServer
Function AutoTest_PutRefundsInStorage() Export 

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Object.Returns.Unload(,"PaymentDate, POSTerminal, AuthorizationCode, PaymentCardNumber, Sum"),
		UUID);
	
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Procedure GetPaymentsFromVault(SelectIncomingPayments, AddressOfPaymentsInTheStorage)

	If SelectIncomingPayments Then
		Object.Purchases.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	Else
		Object.Returns.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	
	If ValueIsFilled(Object.AcquiringContract) Then
		
		AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(Object.AcquiringContract);
		
		POSTerminalsAreUsed = AttributesValues.POSTerminalsAreUsed;
		FixedFeeRate = AttributesValues.FixedFeeRate;
		MakingPaymentMethod = AttributesValues.MakingPaymentMethod;
		
		If Object.RecordCommission Then
			If (Object.AmountOfPurchases - Object.AmountOfReturns) <> 0 Then
				CommissionRate = CashClientServer.CalculateCommissionRate(
					Object.AmountOfPurchases - Object.AmountOfReturns, Object.FeeAmount)
			Else
				
				If FixedFeeRate Then
					CommissionRate = AttributesValues.CommissionRate;
				Else
					CommissionRate = 0;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.CommissionARAPObject) Then
		CommissionAgreement = ContractARAPObjectOfFee(Object.CommissionARAPObject);
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	TitleLine = StrTemplate(NStr("vi = 'Số tiền (%1)';
								|ru = 'Сумма (%1)';
								|en = 'Amount (%1)'; fa = 'Amount (%1)';
								|it = 'Totale (%1)';
								|pl = 'Wartość (%1)';
								|tr = 'Tutar (%1)'"), String(Object.Currency));
	Items.PurchasesSum.Title = TitleLine;
	Items.ReturnsSum.Title = TitleLine;	
	Items.LabelCurrencyCommission.Title = String(Object.Currency);	
	
	ConfigureDependentFormElementsOnServer();
	
	NumberOfVisiblePages = 0;
	For Each Page In Items.Pages.ChildItems Do
		If Page.Visible Then
			NumberOfVisiblePages = NumberOfVisiblePages + 1;
		EndIf;
	EndDo;
	
	If NumberOfVisiblePages < 2 Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	Else
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("POSTerminalsAreUsed");
	FormAttributes.Insert("MakingPaymentMethod");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtClient
Procedure CalculateDocumentAmount()
	
	Object.AmountOfPurchases = Object.Purchases.Total("Sum");
	Object.AmountOfReturns = Object.Returns.Total("Sum");
	
	If Object.RecordCommission Then
		
		If FixedFeeRate 
			And CommissionRate <> 0 Then			
			If Object.DetailedTransactionReconciliation Then
				Object.FeeAmount = (Object.AmountOfPurchases - Object.AmountOfReturns) / 100 * CommissionRate;
			EndIf;
		Else
		
			If Object.AmountOfPurchases - Object.AmountOfReturns <> 0 Then
				CommissionRate = CashClientServer.CalculateCommissionRate(
						Object.AmountOfPurchases - Object.AmountOfReturns, Object.FeeAmount);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Object.DetailedTransactionReconciliation Then
		Object.DocumentAmount = Object.AmountOfPurchases - Object.AmountOfReturns - Object.FeeAmount;
	Else
		Object.DocumentAmount = Object.FeeAmount;
	EndIf;
	
EndProcedure

&AtServer
Function ValuesOfSelectionOfContractFee()
	
	ContractDetails_ = Catalogs.AcquiringContracts.ContractDetails_(Object.AcquiringContract);
	
	FilterValues = New Structure;
	FilterValues.Insert("Organization", Object.Organization);
	FilterValues.Insert("Partner", ContractDetails_.Partner);
	FilterValues.Insert("Counterparty", ContractDetails_.Acquirer);
	FilterValues.Insert("ARAPCurrency", Object.Currency);
	FilterValues.Insert("ARAPObjectSettings", Enums.ARAPObjectSettings.ByCounterpartyContracts);
	
	Return FilterValues;
	
EndFunction

// The Contract of the fee settlement object.
// 
// Parameters:
//  ARAPObject - CatalogRef.ARAPObjects
// 
// Returns:
//  CatalogRef.CounterpartyContracts
//
&AtServerNoContext
Function ContractARAPObjectOfFee(Val ARAPObject)

	Return Common.ObjectAttributeValue(ARAPObject, "Contract");
	
EndFunction

&AtServer
Procedure ContractFeesOnChangesATServer()
	
	Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
	
	If ValueIsFilled(CommissionAgreement) Then
		Object.CommissionARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement);
	EndIf;
	
EndProcedure

&AtServer
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer()
	
	Object.KeepRecordsOfCommissionInARAPAccounting = KeepRecordsOfCommissionInMutualSettlementsSwitch;
	
	If Not Object.KeepRecordsOfCommissionInARAPAccounting Then
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
		Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	ItemsAndDimensionsSelectionParameters = Documents.BankReportOnAcquiringTransactions.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	ConfigureDependentFormElementsOnServer("KeepRecordsOfCommissionInARAPAccounting");
	
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
