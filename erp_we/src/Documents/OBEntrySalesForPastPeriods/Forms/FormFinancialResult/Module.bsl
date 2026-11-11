
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseOtherExpenseAccounting = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	If Not UseOtherExpenseAccounting Then
		Return;
	EndIf;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CurrencyRow = String(ManagementAccountingCurrency);

	TitleLine = "%1 (%2)";
	HeaderAmount = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Số tiền chi phí';
																							|ru = 'Сумма расходов';
																							|en = 'Expense amount'; fa = 'مبلغ هزینه';
																							|it = 'Importo totale delle spese';
																							|pl = 'Suma kosztów';
																							|tr = 'Gider tutarı'"), CurrencyRow);
	Items.FinancialResultExpensesExpenseAmount.Title = HeaderAmount;
	HeaderAmount = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Số tiền thu nhập';
																							|ru = 'Сумма доходов';
																							|en = 'Income amount'; fa = 'مبلغ درآمد';
																							|it = 'Importo totale dei ricavi';
																							|pl = 'Suma wpływów';
																							|tr = 'Gelir tutarı'"), CurrencyRow);
	Items.FinancialResultIncomeIncomeAmount.Title = HeaderAmount;
	
	MultipleOrganizationsAreUsed = GetFunctionalOption("UseMultipleCompanies");
	
	If Not (MultipleOrganizationsAreUsed Or ValueIsFilled(Object.Organization)) Then
		Object.Organization = SettingsValueCached.GetDefaultOrganization();
	EndIf;
	
	SetTitleOfThisForm();
	SetAvailabilityOfClipboardCommands();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntrySalesForPastPeriods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntrySalesForPastPeriods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetTitleOfThisForm();
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
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
Procedure InsertRows(Command)
	
	If Items.OperationTypesGroup.CurrentPage = Items.GroupFinancialResultExpenses Then
		NumberOfRowsBeforeInsertion = Object.FinancialResultExpenses.Count();
		GetLinesFromClipboard(Items.FinancialResultExpenses.Name);
		NumberOfInserted = Object.FinancialResultExpenses.Count()-NumberOfRowsBeforeInsertion;
	Else
		NumberOfRowsBeforeInsertion = Object.FinancialResultIncome.Count();
		GetLinesFromClipboard(Items.FinancialResultIncome.Name);
		NumberOfInserted = Object.FinancialResultIncome.Count()-NumberOfRowsBeforeInsertion;
	EndIf;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If Items.OperationTypesGroup.CurrentPage = Items.GroupFinancialResultExpenses Then
		FormTable = Items.FinancialResultExpenses;
	Else
		FormTable = Items.FinancialResultIncome;
	EndIf;
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormTable) Then
		CopyLinesOnServer(FormTable.Name);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(FormTable.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.Department.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", Enums.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods);

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()

	If ValueIsFilled(Object.Organization) Then
		AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Object.Organization, Object.Date);
		Object.VATTaxation = AccountingParametersForOrganization.BasicTaxationVATSales;
	EndIf;

EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(FormTableName)
	
	TabularSection = ?(FormTableName = Items.FinancialResultExpenses.Name, Object.FinancialResultExpenses,
		Object.FinancialResultIncome);
	
	ProcessingOfTabularForms.CopyRowsToClipboard(TabularSection, Items[FormTableName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(FormTableName)
	
	If FormTableName = Items.FinancialResultExpenses.Name Then
		Columns = "LineOfBusiness, ExpenseItem, ExpenseAmount, DateRecord";
		TabularSection = Object.FinancialResultExpenses;
	Else
		Columns = "LineOfBusiness, IncomeItem, IncomeAmount, DateRecord";
		TabularSection = Object.FinancialResultIncome;
	EndIf;
	
	TableOfRows = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfRows) Then
		Return;
	EndIf;
	
	For Each String In TableOfRows Do
		CurrentRow = TabularSection.Add();
		FillPropertyValues(CurrentRow, String);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("FinancialResultExpensesInsertRows");
	ItemArray.Add("FinancialResultIncomeInsertRows");
	ItemArray.Add("FinancialResultExpensesContextMenuInsertRows");
	ItemArray.Add("FinancialResultIncomeContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("FinancialResultExpensesInsertRows");
	ItemArray.Add("FinancialResultIncomeInsertRows");
	ItemArray.Add("FinancialResultExpensesContextMenuInsertRows");
	ItemArray.Add("FinancialResultIncomeContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtClient
Procedure FinancialResultExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure FinancialResultExpensesOnStartEdit(Item, NewRow, Copy)
	TableRow = Items.FinancialResultExpenses.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.FinancialResultExpenses");
EndProcedure

&AtClient
Procedure FinancialResultIncomeIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure FinancialResultIncomeIncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
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
