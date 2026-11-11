
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If ValueIsFilled(Object.DocumentBasis)
		And Object.Posted Then
		Items.Organization.ReadOnly           = True;
		Items.Counterparty.ReadOnly            = True;
		Items.CompanyRecipient.ReadOnly = True;
		Items.ARAPDocument.ReadOnly     = True;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ARAPAccountingScheduleAdjustment", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	If ValueIsFilled(Object.DocumentBasis) Then
		Items.Organization.ReadOnly           = Object.Posted;
		Items.Counterparty.ReadOnly            = Object.Posted;
		Items.CompanyRecipient.ReadOnly = Object.Posted;
		Items.ARAPDocument.ReadOnly     = Object.Posted;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	AllocateBalance(Object.NewSchedule_, BalanceTable);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ARAPDocumentOnChange(Item)
	
	ARAPDocumentOnChangeATServer();;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	FillByBalancesOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	Object.ARAPDocument = Undefined;
	Object.DocumentBasis = Undefined;
	OriginalGraph.Clear();
	Object.NewSchedule_.Clear();
	Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	
	Object.ARAPDocument = Undefined;
	Object.DocumentBasis = Undefined;
	OriginalGraph.Clear();
	Object.NewSchedule_.Clear();
	Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	Object.ARAPDocument = Undefined;
	Object.DocumentBasis = Undefined;
	OriginalGraph.Clear();
	Object.NewSchedule_.Clear();
	Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	
EndProcedure

&AtClient
Procedure ARAPDocumentStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	ARAPDocumentBeginningOfSelectionATServer();
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region FormTableItemsEventHandlersNewSchedule_

&AtClient
Procedure NewSchedule_OnChange(Item)
	
	SumOfNewSchedule = ?(MultiCurrencyTable(Object.NewSchedule_), 0, Object.NewSchedule_.Total("Sum"));
	AllocateBalance(Object.NewSchedule_, BalanceTable);
	BalanceOfNewSchedule = ?(MultiCurrencyTable(Object.NewSchedule_), 0, Object.NewSchedule_.Total("Balance"));
	
EndProcedure

&AtClient
Procedure NewSchedule_ARAPObjectOnChange(Item)
	
	CurrentData = Items.NewSchedule_.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	LinesOfOriginalGraph = OriginalGraph.FindRows(New Structure("ARAPObject", CurrentData.ARAPObject));
	If LinesOfOriginalGraph.Count() > 0 Then
		FillPropertyValues(CurrentData, LinesOfOriginalGraph[0], , "Date, Sum");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

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

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ThisIsDocumentBetweenOrganizations = ValueIsFilled(Object.CompanyRecipient) And Not ValueIsFilled(Object.Counterparty);
	
	SumOfNewSchedule = ?(MultiCurrencyTable(Object.NewSchedule_), 0, Object.NewSchedule_.Total("Sum"));
	FillGraphWithOriginalData(OriginalGraph);
	FillBalance();
	AllocateBalance(OriginalGraph, BalanceTable);
	AllocateBalance(Object.NewSchedule_, BalanceTable);
	BalanceOfNewSchedule = ?(MultiCurrencyTable(Object.NewSchedule_), 0, Object.NewSchedule_.Total("Balance"));
	BalanceOfOriginalGraph = ?(MultiCurrencyTable(OriginalGraph), 0, OriginalGraph.Total("Balance"));
	SumOfOriginalGraph = ?(MultiCurrencyTable(OriginalGraph), 0, OriginalGraph.Total("Sum"));
	Object.DocumentAmount = ?(MultiCurrencyTable(Object.NewSchedule_), 0, Object.NewSchedule_.Total("Sum"));
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure ARAPDocumentOnChangeATServer()
	
	If Not ValueIsFilled(Object.ARAPDocument) Then
		Return;
	EndIf;
	Object.NewSchedule_.Clear();
	Object.Currency = Catalogs.Currencies.EmptyRef();
	Query = New Query;
	Query.Text = Documents.ARAPAccountingScheduleAdjustment.QueryTextOfDocumentsBasedOn();
	Query.SetParameter("ARAPDocumentOfAdjustment", Object.ARAPDocument);
	Query.SetParameter("Ref", Object.Ref);
	EnteredDocuments = Query.Execute().Unload();
	RowsOfEnteredAdjustments = EnteredDocuments.FindRows(New Structure("BusinessOperation", Object.BusinessOperation));
	DocumentLine = Documents.ARAPAccountingScheduleAdjustment.LastAdjustment(RowsOfEnteredAdjustments);
	Object.DocumentBasis = Object.ARAPDocument;
	If DocumentLine <> Undefined Then
		Object.DocumentBasis = DocumentLine.Ref;
	EndIf;
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.AdditionalProperties.Insert("SelectARAPDocument", True);
	DocumentObject.Fill(Object.ARAPDocument);
	ValueToFormAttribute(DocumentObject, "Object");
	OnReadCreateAtServer();
	CustomizeFormElements();
	
EndProcedure

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

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
Procedure FillGraphWithOriginalData(Table)
	
	Table.Clear();
	AvailableCalculationObjects.Clear();
	Items.BusinessOperation.ChoiceList.Clear();
	If Not ValueIsFilled(Object.DocumentBasis) Then
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.AdjustCustomerPaymentSchedule);
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.AdjustVendorPaymentSchedule);
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule);
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule);
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
		Object.BusinessOperation = Common.ObjectAttributeValue(Object.DocumentBasis, "BusinessOperation");
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ARAPDocument", Object.DocumentBasis);
	SelectionByPrimaryDocument = TypeOf(Object.DocumentBasis) = Type("DocumentRef.SourceDocument");
	Query.Text = Documents.ARAPAccountingScheduleAdjustment.QueryTextForFillingData(SelectionByPrimaryDocument);
	ARAPCurrencies = New Array;
	
	SamplingByHouseholdOfOperation = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingByHouseholdOfOperation.Next() Do
		Items.BusinessOperation.ChoiceList.Add(SamplingByHouseholdOfOperation.BusinessOperation);
		If SamplingByHouseholdOfOperation.BusinessOperation <> Object.BusinessOperation Then
			Continue;
		EndIf;
		
		Selection = SamplingByHouseholdOfOperation.Select();
		While Selection.Next() Do
			FillPropertyValues(Table.Add(), Selection);
			AvailableCalculationObjects.Add(Selection.ARAPObject);
			If ValueIsFilled(Selection.Currency) Then
				ARAPCurrencies.Add(Selection.Currency);
			EndIf;
		EndDo;
		
	EndDo;
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
		Items.BusinessOperation.ChoiceList.Clear();
		Items.BusinessOperation.ChoiceList.Add(Object.BusinessOperation);
	EndIf;
	
	ARAPCurrencies = CommonClientServer.CollapseArray(ARAPCurrencies);
	Object.DocumentAmount = Table.Total("Sum");
	If ARAPCurrencies.Count() = 1 Then
		Object.Currency = ARAPCurrencies[0];
	ElsIf ARAPCurrencies.Count() > 1 Then 
		Object.DocumentAmount = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillBalance()
	
	BalanceTable.Clear();
	
	Query = New Query;
	Query.SetParameter("ARAPDocument", Object.ARAPDocument);
	Query.Text = "
		|SELECT
		|	DimensionKeysOfAccountingByPartners.Partner                  AS Partner,
		|	DimensionKeysOfAccountingByPartners.Contract                  AS Contract,
		|	DimensionKeysOfAccountingByPartners.LineOfBusiness  AS LineOfBusiness,
		|	CalculationsByTermsBalance.ARAPObject                   AS ARAPObject,
		|	CalculationsByTermsBalance.Currency                           AS Currency,
		|	CalculationsByTermsBalance.DebtBalance                      AS Balance
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance AS CalculationsByTermsBalance
		|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|		ON CalculationsByTermsBalance.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	CalculationsByTermsBalance.ARAPDocument = &ARAPDocument
		|";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule Then
		Query.Text = StrReplace(
			Query.Text,
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Debt.Name,
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Prepayment.Name);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule Then
		Query.Text = StrReplace(
			Query.Text,
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Debt.Name,
			Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Resources.Prepayment.Name);
		Query.Text = StrReplace(
			Query.Text,
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name,
			Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.AdjustVendorPaymentSchedule Then
		Query.Text = StrReplace(
			Query.Text,
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name,
			Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FillPropertyValues(BalanceTable.Add(), Selection);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AllocateBalance(Table, BalanceTable)
	
	KeyFields = "Partner, Contract, LineOfBusiness, ARAPObject, Currency";
	PropertiesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(KeyFields,,True,True);
	
	For Each PlotLine In Table Do
		PlotLine.Balance = 0;
	EndDo;
	
	For Each RemainderLine In BalanceTable Do
		
		LinesOfGraphInDescendingOrderOfDates = New Array;
		
		For Each PlotLine In Table Do
			If TMCommonUseClientServer.StructuresAreEqual(PlotLine, RemainderLine, PropertiesArray) Then
				IndexOf = 0;
				While IndexOf < LinesOfGraphInDescendingOrderOfDates.Count()
					And LinesOfGraphInDescendingOrderOfDates[IndexOf].Date > PlotLine.Date Do
					IndexOf = IndexOf + 1;
				EndDo;
				LinesOfGraphInDescendingOrderOfDates.Insert(IndexOf, PlotLine)
			EndIf;
		EndDo;
		
		Amount_Balance = RemainderLine.Balance;
		IndexOf = 0;
		While IndexOf < LinesOfGraphInDescendingOrderOfDates.Count() Do
			LinesOfGraphInDescendingOrderOfDates[IndexOf].Balance = Min(LinesOfGraphInDescendingOrderOfDates[IndexOf].Sum, Amount_Balance);
			Amount_Balance = Amount_Balance - LinesOfGraphInDescendingOrderOfDates[IndexOf].Balance;
			Amount_Balance = Max(Amount_Balance, 0);
			IndexOf = IndexOf + 1;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Text color of the original graph
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OriginalGraph.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OriginalGraph.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Text color NewgrAphics
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NewSchedule_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.NewSchedule_.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Only viewing the original graphics
	
	Item = ConditionalAppearance.Items.Add();
	
	For Each TableColumn2 In Items.OriginalGraph.ChildItems Do
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(TableColumn2.Name);
	EndDo;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Only view NewgrAphics.Balance
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NewSchedule_Balance.Name);
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	FillByBalancesOnServer();
EndProcedure

&AtServer
Procedure FillByBalancesOnServer()
	
	If Not ValueIsFilled(Object.ARAPDocument) Then
		Return;
	EndIf;
	
	FillGraphWithOriginalData(OriginalGraph);
	FillGraphWithOriginalData(Object.NewSchedule_);
	For Each TableRow In Object.NewSchedule_ Do
		If Not ValueIsFilled(TableRow.Date) Then
			TableRow.Date = CurrentSessionDate();
		EndIf;
	EndDo;
	SumOfNewSchedule = ?(MultiCurrencyTable(Object.NewSchedule_), 0, Object.NewSchedule_.Total("Sum"));
	FillBalance();
	AllocateBalance(OriginalGraph, BalanceTable);
	AllocateBalance(Object.NewSchedule_, BalanceTable);
	BalanceOfNewSchedule = ?(MultiCurrencyTable(Object.NewSchedule_), 0,  Object.NewSchedule_.Total("Balance"));
	BalanceOfOriginalGraph = ?(MultiCurrencyTable(OriginalGraph), 0, OriginalGraph.Total("Balance"));
	SumOfOriginalGraph = ?(MultiCurrencyTable(OriginalGraph), 0, OriginalGraph.Total("Sum"));
	Object.DocumentAmount = ?(MultiCurrencyTable(Object.NewSchedule_), 0,  Object.NewSchedule_.Total("Sum"));
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	RecipientCompanyVisibility = GetFunctionalOption("UseMultipleCompanies")
		And (ThisIsDocumentBetweenOrganizations Or ValueIsFilled(Object.CompanyRecipient));
	
	Items.Organization.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.CompanyRecipient.Visible = RecipientCompanyVisibility;
	Items.Organization.Title = ?(
		RecipientCompanyVisibility,
		NStr("vi = 'Doanh nghiệp-người gửi';
			|ru = 'Организация-отправитель';
			|en = 'Shipping company'; fa = 'شرکت ارسال‌کننده';
			|it = 'Azienda-mittente';
			|pl = 'Shipping company';
			|tr = 'Gönderici iş yeri'"),
		NStr("vi = 'Doanh nghiệp';
			|ru = 'Организация';
			|en = 'Company'; fa = 'Company';
			|it = 'Azienda';
			|pl = 'Company';
			|tr = 'İş yeri'"));
	Items.Counterparty.Visible = Not ThisIsDocumentBetweenOrganizations;
	
	Items.BusinessOperation.ReadOnly = Items.BusinessOperation.ChoiceList.Count() = 1;
	
	If ReadOnly Then
		Items.NewSchedule_FillInByBalance.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ARAPDocumentBeginningOfSelectionATServer()
	
	ArrayOfSelections = New Array;
	
	If ValueIsFilled(Object.Counterparty) Then
		If TypeOf(Object.ARAPDocument) = Type("DocumentRef.ElectronicTicketTransaction") Then
			ArrayOfSelections.Add(New ChoiceParameterLink("Filter.CounterpartyCarrier", "Object.Counterparty"));
		Else
			ArrayOfSelections.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty"));
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		ArrayOfSelections.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	EndIf;
	
	If ValueIsFilled(Object.CompanyRecipient) Then
		If TypeOf(Object.ARAPDocument) = Type("DocumentRef.CommissionReportIntercompany")
			Or TypeOf(Object.ARAPDocument) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
			ArrayOfSelections.Add(New ChoiceParameterLink("Filter.Consignee", "Object.CompanyRecipient"));
		Else
			ArrayOfSelections.Add(New ChoiceParameterLink("Filter.CompanyRecipient", "Object.CompanyRecipient"));
		EndIf;
	EndIf;
	
	Items.ARAPDocument.ChoiceParameterLinks = New FixedArray(ArrayOfSelections);
	
EndProcedure

&AtClientAtServerNoContext
Function MultiCurrencyTable(Table)
	
	Currency = Undefined;
	For Each TableRow In Table Do
		If Not ValueIsFilled(TableRow.Currency) Then
			Continue;
		EndIf;
		If Currency = Undefined Then 
			Currency = TableRow.Currency
		ElsIf Currency <> TableRow.Currency Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

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
