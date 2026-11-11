
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	ItemsAndDimensionsSelectionParameters = Documents.PhysicalCountOfCashAccounts.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If Object.Patch Then
		Items.CashAccountsFillOnCashAccounts.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.PhysicalCountOfCashAccounts.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
			
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
		
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	Object.CashAccounts.Clear();
	Object.LastNumberOfCashAccountReceiptNote = "";
	Object.LastNumberOfCashAccountIssueNote = "";
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	
EndProcedure

&AtClient
Procedure CashBookStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure


&AtClient
Procedure CashBookClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

&AtClient
Procedure CashBookChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	ClearMessages();
	
	
	Return;
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElements_

&AtClient
Procedure CashAccountsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.CashAccounts.CurrentData;
	
	If NewRow And Not Copy Then
		If Not UseMultipleCashAccounts Then
			If Not ValueIsFilled(CashAccount) Then
				GetCheckoutByDefault();
			EndIf;
			TableRow.CashAccount = CashAccount;
		EndIf;
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.CashAccounts");
	EndIf;
	
EndProcedure

&AtClient
Procedure CashAccountsCashAccountOnChange(Item)
	
	CurrentRow = Items.CashAccounts.CurrentData;
	CurrentRow.AccountInAccounting = BalanceInCashRegisterForAccounting(CurrentRow.CashAccount);
	
EndProcedure

&AtClient
Procedure CashAccountsAccountInAccountingOnChange(Item)

	CalculateDiscrepanciesInRow(Items.CashAccounts.CurrentData);
	
EndProcedure

&AtClient
Procedure TheCashAmountOfFactWhenYouChange(Item)
	
	CalculateDiscrepanciesInRow(Items.CashAccounts.CurrentData);
	
EndProcedure

&AtClient
Procedure CashAccountsIncomeAndExpenseItemOnChange(Item)
	
	CashAccountsIncomeAndExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtServer
Procedure CashAccountsIncomeAndExpenseItemOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

&AtClient
Procedure CashAccountsIncomeAndExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.CashAccounts.CurrentData;
	
	TypesArray = New Array;
	If CurrentRow.DiscrepancyAmount > 0 Then
		TypesArray.Add(Type("ChartOfCharacteristicTypesRef.IncomeItems"));
		Item.TypeRestriction = New TypeDescription(TypesArray, , );
	ElsIf CurrentRow.DiscrepancyAmount < 0 Then
		TypesArray.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
		Item.TypeRestriction = New TypeDescription(TypesArray, , );
	EndIf;

	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CashAccountsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure CashAccountsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure CashAccountsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillOnCashAccounts(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.CashAccounts;
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Company';
																	|tr = 'İş yeri'"));
	Notification = New CallbackDescription("FillOnCashAccountsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillOnCashAccountsCompletion(Result, AdditionalParameters) Export
	
	FillOnCashAccountsServer();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure OnReadCreateAtServer()
	
	UseMultipleCashAccounts = GetFunctionalOption("UseMultipleCashAccounts");
	
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Prompt for entering the amount after the fact
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashAccountsActualDataAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashAccounts.ActualDataAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<để nhập kết quả>';
													|ru = '<для внесения результата>';
													|en = '<for entering result>'; fa = '<for entering result>';
													|it = '<per inserire il risultato>';
													|pl = '<dla wprowadzenia wyniku>';
													|tr = '<sonucu girmek için>'"));
	
	// Discrepancy field - shortage
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusShortfall.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashAccounts.DiscrepancyAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thiếu';
													|ru = 'Недостача';
													|en = 'Shortage'; fa = 'کسری';
													|it = 'Quantità mancante';
													|pl = 'Shortage';
													|tr = 'Eksiklik'"));
	
	// Discrepancy field - excess
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SurplusShortfall.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashAccounts.DiscrepancyAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thừa';
													|ru = 'Излишек';
													|en = 'Surplus'; fa = 'مازاد';
													|it = 'Eccedenza';
													|pl = 'Surplus';
													|tr = 'Fazlalık'"));
	
	// 
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashAccountsIncomeAndExpenseItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashAccounts.DiscrepancyAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure


&AtServer
Procedure FillOnCashAccountsServer()
	
	Object.CashAccounts.Clear();
	Object.LastNumberOfCashAccountReceiptNote = "";
	Object.LastNumberOfCashAccountIssueNote = "";
	
	QueryText = "
	|SELECT
	|	CashAccounts.Ref AS CashAccount,
	|	CashAccounts.CashCurrency AS Currency,
	|	ISNULL(CashAccountBalance.SumBalance, 0) AS AccountInAccounting,
	|	CASE WHEN ISNULL(CashAccountBalance.SumBalance, 0) > 0 THEN
	|		-ISNULL(CashAccountBalance.SumBalance, 0)
	|	ELSE
	|		0
	|	END AS DiscrepancyAmount
	|	
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|	
	|	LEFT JOIN
	|		AccumulationRegister.CashAccountBalance.Balance(&InventoryDate, Organization = &Organization) AS CashAccountBalance
	|	ON
	|		CashAccountBalance.CashAccount = CashAccounts.Ref
	|		AND CashAccountBalance.Organization = &Organization
	|	
	|WHERE
	|	CashAccounts.Owner = &Organization
	|	AND CashAccounts.CashBook = &CashBook
	|	AND NOT CashAccounts.DeletionMark
	|	
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("CashBook", Object.CashBook);
	Query.SetParameter("InventoryDate", New Boundary(EndOfDay(Object.Date)));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không có quỹ tiền mặt để điền.';
												|ru = 'Отсутствуют кассы для заполнения.';
												|en = 'No cash accounts for population.'; fa = 'No cash accounts for population.';
												|it = 'I conti di cassa per la compilazione sono assenti.';
												|pl = 'Brak kasy do wypełnienia.';
												|tr = 'Doldurma için kasa mevcut değil.'"));
		Return;
	Else
		TableOfCashRegisters = QueryResult.Unload();
		InventoriedCashRegisters = TableOfCashRegisters.UnloadColumn("CashAccount");
		Object.CashAccounts.Load(TableOfCashRegisters);
	EndIf;
	
	// Maximum order numbers
	QueryText = "
	|SELECT TOP 1
	|	CashAccountReceiptNote.Number AS ICONumber
	|FROM
	|	Document.CashAccountReceiptNote AS CashAccountReceiptNote
	|WHERE
	|	CashAccountReceiptNote.Posted
	|	AND CashAccountReceiptNote.CashAccount IN (&CashAccounts)
	|	AND CashAccountReceiptNote.Date <= &InventoryDate
	|ORDER BY
	|	CashAccountReceiptNote.Date DESC
	|;
	|/////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	CashVoucher.Number AS ACWNumber
	|FROM
	|	Document.CashVoucher AS CashVoucher
	|WHERE
	|	CashVoucher.Posted
	|	AND CashVoucher.CashAccount IN (&CashAccounts)
	|	AND CashVoucher.Date <= &InventoryDate
	|ORDER BY
	|	CashVoucher.Date DESC
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("CashAccounts", InventoriedCashRegisters);
	Query.SetParameter("InventoryDate", EndOfDay(Object.Date));
	
	QueryResult = Query.ExecuteBatch();
	If Not QueryResult[0].IsEmpty() Then
		Selection = QueryResult[0].Select();
		Selection.Next();
		Object.LastNumberOfCashAccountReceiptNote = Selection.ICONumber;
	EndIf;
	If Not QueryResult[1].IsEmpty() Then
		Selection = QueryResult[1].Select();
		Selection.Next();
		Object.LastNumberOfCashAccountIssueNote = Selection.ACWNumber;
	EndIf;
	
	For Each String In Object.CashAccounts Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisForm, String, "Object.CashAccounts");	
	EndDo;
	
EndProcedure

&AtServerNoContext
Function BalanceInCashRegisterForAccounting(CheckoutLink)
	
	Query = New Query("
	|SELECT
	|	CashAccountBalance.SumBalance AS AccountInAccounting
	|FROM
	|	AccumulationRegister.CashAccountBalance.Balance(,CashAccount = &CashAccount) AS CashAccountBalance
	|");
	
	Query.SetParameter("CashAccount", CheckoutLink);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.AccountInAccounting;
	
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure GetCheckoutByDefault()
	
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister();
	
EndProcedure

&AtClient
Procedure CalculateDiscrepanciesInRow(String)
	
	String.DiscrepancyAmount = String.ActualDataAmount - String.AccountInAccounting;
	If String.DiscrepancyAmount <= 0 
		 And TypeOf(String.IncomeAndExpenseItem) <> Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		String.IncomeAndExpenseItem = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.CashAccountsIncomeAndExpenseItem);
	ElsIf TypeOf(String.IncomeAndExpenseItem) <> Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		String.IncomeAndExpenseItem = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.CashAccountsIncomeAndExpenseItem);		
	EndIf;
	
EndProcedure

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
