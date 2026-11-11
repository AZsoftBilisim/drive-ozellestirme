#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Parameters.Property("Basis", Request);
	Parameters.Property("BankAccount", BankAccount);
	
	Organization = Common.ObjectAttributeValue(Request, "Organization");
	
	InitializeComposer();
	SetConditionalAppearance();
	FormItemsManagement();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	GenerateTreeOfRequestsForPayment(Undefined);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WriteOffFormationModeOnChange(Item)

	ClearMessages();
	GenerateTreeOfRequestsForPayment(Undefined);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPersonalAccountsOfIndividualsForPayment

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentMarkOnChange(Item)

	TreeRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	SetValueToSubordinateStrings(TreeRow.GetItems(), "Mark", TreeRow.Mark);

EndProcedure

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentCompanyBankAccountStartChoice(Item,
														ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	
	FilterParameters = New Structure;
	If WriteOffFormationMode = 1 Then
		FilterParameters.Insert("Bank", TableRow.Bank);
	EndIf;
	FilterParameters.Insert("Owner", Organization);
	FilterParameters.Insert("CashCurrency", TableRow.Currency);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CloseOnChoice", True);
	OpeningParameters.Insert("Filter", FilterParameters);
	OpeningParameters.Insert("CurrentRow", TableRow.CompanyBankAccount);
	
	OpenForm("Catalog.CompaniesBankAccounts.ChoiceForm",
					OpeningParameters,
					Item,
					UUID, , , ,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentCompanyBankAccountChoiceProcessing(Item,
													ValueSelected, StandardProcessing)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	TreeRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	TreeRow.CompanyBankAccount = ValueSelected;
	
	SetValueToSubordinateStrings(TreeRow.GetItems(), "CompanyBankAccount", ValueSelected);
	
EndProcedure

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentAmountToBeDebitedWhenChanging(Item)
	
	CurRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	
	If CurRow = Undefined Then
		Return;
	EndIf;
	
	If CurRow.Sum > CurRow.SumBalance Then
		CurRow.Sum = CurRow.SumBalance;
	EndIf;
	
	If CurRow.Sum <> 0 Then
		
		CurRow.Mark = True;
		SetValueToSubordinateStrings(CurRow.GetItems(), "Mark", CurRow.Mark);
		
	Else
		
		CurRow.Mark = False;
		SetValueToSubordinateStrings(CurRow.GetItems(), "Mark", CurRow.Mark);
		
	EndIf;
	
	DistributeAmountOfWriteOff(CurRow);
	
EndProcedure

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccountStartChoice(Item,
															ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	
	Filter = New Structure;
	Filter.Insert("Bank", Items.PersonalAccountsOfIndividualsForPayment.CurrentData.Bank);
	Filter.Insert("OwnerOfLegalEntityIsNaturalPerson", PredefinedValue("Enum.LegalEntityIndividual.Entity"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("CloseOnChoice", True);
	FormParameters.Insert("CurrentRow", TableRow.BankAccount);
	
	Result = OpenForm("Catalog.CounterpartyBankAccounts.Form.ChoiceForm",
								FormParameters,
								Item, , , , ,
								FormWindowOpeningMode.LockOwnerWindow);
	
	GroupingList = Result.List.Group;
	GroupingField = GroupingList.Items.Add(Type("DataCompositionGroupField"));
	GroupingField.Field = New DataCompositionField("Owner");
	
EndProcedure

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccountChoiceProcessing(Item,
															ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	TreeRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	TreeRow.BankAccount = ValueSelected;
	TreeRow.PresentationBankBankAccount = RegistryView(TreeRow.Bank, TreeRow.BankAccount);
	
	ItemsCollection = TreeRow.GetItems();
	SetValueToSubordinateStrings(ItemsCollection, "BankAccount", TreeRow.BankAccount);
	SetValueToSubordinateStrings(ItemsCollection,
											"PresentationBankBankAccount",
											TreeRow.PresentationBankBankAccount);
	
EndProcedure

&AtClient
Procedure PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccountOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TreeRow = Items.PersonalAccountsOfIndividualsForPayment.CurrentData;
	ShowValue(, TreeRow.BankAccount);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)

	SetValueToSubordinateStrings(PersonalAccountsOfIndividualsForPayment.GetItems(), "Mark", True);

EndProcedure

&AtClient
Procedure UncheckAll(Command)

	SetValueToSubordinateStrings(PersonalAccountsOfIndividualsForPayment.GetItems(), "Mark", False);

EndProcedure

&AtClient
Procedure CreateDocuments(Command)

	ClearMessages();
	PerformanceMeasurement = PerformanceMonitorClient.StartTimeConsumingOperationMeasurement(
			"Document.BankAccountIssue.Form.WizardFormForWriteOffToPersonalAccounts.CreateDocuments");
		
	Job = CreatingDocumentsOnServer();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PerformanceMeasurement", PerformanceMeasurement);
	CallbackOnCompletion = New CallbackDescription("CompletionOfFormationOfDocuments", ThisObject, AdditionalParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(Job, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtClient
Procedure RefreshTree(Command)
	
	GenerateTreeOfRequestsForPayment(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeComposer()

	DataCompositionSchema = LayoutOfWriteOffDocument("PaymentRequestsForPersonalAccounts");
	SchemaURL = PutToTempStorage(DataCompositionSchema, UUID);
	AvailableSettings = New DataCompositionAvailableSettingsSource(SchemaURL);
	TreeSettingsComposer.Initialize(AvailableSettings);
	
	TreeSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	TreeSettingsComposer.Refresh();

EndProcedure

&AtServerNoContext
Function LayoutOfWriteOffDocument(TemplateName)

	Return Documents.BankAccountIssue.GetTemplate(TemplateName);

EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	Setting = ConditionalAppearance.Items;
	TypeOfSelectionGroup = Type("DataCompositionFilterItemGroup");
	
	// Recipient Bank account
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.BankAccount", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.SumBalance", 0, ,
											DataCompositionComparisonType.NotEqual);
	SettingItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Registry view
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.Filled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", True);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccount");
	FinancialReportingServer.NewFilter(SettingItem.Filter, "WriteOffFormationMode", 0);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentPresentationBankBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.BankAccount", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.SumBalance", 0, ,
											DataCompositionComparisonType.NotEqual);
	SettingItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Employee representation
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentRepresentationOfIndividualPersonalAccount");
	FinancialReportingServer.NewFilter(SettingItem.Filter, "WriteOffFormationMode", 0);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentRepresentationOfIndividualPersonalAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	// A natural person
	SettingItem = Setting.Add();
	Fields = SettingItem.Fields.Items;
	NewField = Fields.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentIndividual");
	FinancialReportingServer.NewFilter(SettingItem.Filter, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	// Personal account
	SettingItem = Setting.Add();
	Fields = SettingItem.Fields.Items;
	NewField = Fields.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentPersonalAccount");
	FinancialReportingServer.NewFilter(SettingItem.Filter, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	// Organization's Bank account
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentCompanyBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.CompanyBankAccount", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.SumBalance", 0, ,
											DataCompositionComparisonType.NotEqual);
	SettingItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentBankAccountOfOrganization_ByIndividuals");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.Filled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 0);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.CompanyBankAccount", , ,
											DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.SumBalance", 0, ,
											DataCompositionComparisonType.NotEqual);
	SettingItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentBankAccountOfOrganization_ByIndividuals");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentCompanyBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 0);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	SettingItem = Setting.Add();
	NewField = SettingItem.Fields.Items.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentCompanyBankAccount");
	AndGroup = FinancialReportingServer.NewFilter(SettingItem.Filter, Undefined, , TypeOfSelectionGroup);
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "PersonalAccountsOfIndividualsForPayment.Individual", , ,
											DataCompositionComparisonType.Filled);
	FinancialReportingServer.NewFilter(AndGroup, "WriteOffFormationMode", 1);
	SettingItem.Appearance.SetParameterValue("Visible", False);
	
	// Mark
	SettingItem = Setting.Add();
	Fields = SettingItem.Fields.Items;
	NewField = Fields.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentMark");
	NewField = Fields.Add();
	NewField.Field = New DataCompositionField("PersonalAccountsOfIndividualsForPaymentSum");
	FinancialReportingServer.NewFilter(SettingItem.Filter, "PersonalAccountsOfIndividualsForPayment.SumBalance", 0);
	SettingItem.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure GenerateTreeOfRequestsForPayment(Result, AdditionalParameters = Undefined) Export

	CustomizeDisplayOfFormElements();
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BankAccountIssue.Form.WizardFormForWriteOffToPersonalAccounts.WithdrawApplicationsForPayment");
	WithdrawApplicationsForPayment();
	
	ExpandLevelsOfTree();

EndProcedure

&AtServer
Procedure WithdrawApplicationsForPayment()

	SourceDataTreeForApplications = GetPersonalAccountsOnApplications();
	TopUpTreeRows(SourceDataTreeForApplications);
	
	ValueToFormAttribute(SourceDataTreeForApplications, "PersonalAccountsOfIndividualsForPayment");

EndProcedure

&AtServer
Function GetPersonalAccountsOnApplications()

	DataCompositionSchema = LayoutOfWriteOffDocument("PaymentRequestsForPersonalAccounts");
	SettingsByOption = DataCompositionSchema.SettingVariants[String(WriteOffFormationMode)].Settings;
	TreeSettingsComposer.LoadSettings(SettingsByOption);
	
	ComposerSettings = TreeSettingsComposer.GetSettings();
	
	RequestArrayParameter = New DataCompositionParameter("ArrayOfRequests");
	ValueArrayOfApplications = ComposerSettings.DataParameters.FindParameterValue(RequestArrayParameter);
	
	If ValueArrayOfApplications <> Undefined Then
		
		ValueArrayOfApplications.Value = Request;
		ValueArrayOfApplications.Use = True;
		
	EndIf;
	
	ParameterByRegistry = New DataCompositionParameter("ByRegistry");
	ValueByRegistry = ComposerSettings.DataParameters.FindParameterValue(ParameterByRegistry);
	
	If ValueByRegistry <> Undefined Then
		
		ValueByRegistry.Value = WriteOffFormationMode;
		ValueByRegistry.Use = True;
		
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	TypeOfLayoutGenerator = Type("DataCompositionValueCollectionTemplateGenerator");
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, , , TypeOfLayoutGenerator);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	TreeToBePaid = New ValueTree;
	OutputProcessor.SetObject(TreeToBePaid);
	OutputProcessor.Output(DataCompositionProcessor, True);
	
	Return TreeToBePaid;

EndFunction

&AtClient
Procedure ExpandLevelsOfTree()

	TreeItems = PersonalAccountsOfIndividualsForPayment.GetItems();
	
	For Each TreeItem In TreeItems Do
		Items.PersonalAccountsOfIndividualsForPayment.Expand(TreeItem.GetID());
	EndDo;

EndProcedure

&AtClient
Procedure SetValueToSubordinateStrings(TreeItems, Column, Value)

	For Each TreeItem In TreeItems Do
		
		If TreeItem.SumBalance > 0 Then
			
			TreeItem[Column] = Value;
			SetValueToSubordinateStrings(TreeItem.GetItems(), Column, Value);
			
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure SelectedLinesCheck(Error)

	PersonalInvoicesForPayment = FormAttributeToValue("PersonalAccountsOfIndividualsForPayment");
	
	FilterParameters = New Structure("Mark", True);
	MarkedLines = PersonalInvoicesForPayment.Rows.FindRows(FilterParameters, True);
	
	If MarkedLines.Count() = 0 Then
		
		Error = True;
		MessageText = NStr("vi = 'Cần chọn ít nhất một dòng (đặt dấu hộp kiểm)';
							|ru = 'Необходимо выбрать хотя бы одну строку (установить флажок)';
							|en = 'Select at least one line (select check box)'; fa = 'Select at least one line (select check box)';
							|it = 'È necessario selezionare almeno una riga (impostare contrassegno)';
							|pl = 'Należy wybrać co najmniej jeden wiersz (zaznaczyć pole wyboru)';
							|tr = 'En azından bir satırın seçilmesi gerekiyor (onay kutusunu seç)'");
		Common.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	TableOfSelectedRows = RowsSelected(PersonalInvoicesForPayment, MarkedLines);
	
	If WriteOffFormationMode = 1 Then
		
		Filter = New Structure("BankAccount", Catalogs.CounterpartyBankAccounts.EmptyRef());
		UnfilledInvoices = TableOfSelectedRows.FindRows(Filter);
		
		If UnfilledInvoices.Count() > 0 Then
			
			Error = True;
			MessageText = NStr("vi = 'Cần điền tài khoản nhận';
								|ru = 'Необходимо заполнить счет-получатель.';
								|en = 'Fill the beneficiary account.'; fa = 'Fill the beneficiary account.';
								|it = 'È necessario compilare il conto destinatario.';
								|pl = 'Należy wypełnić rachunek-odbiorcę.';
								|tr = 'Alıcı-hesap doldurulması gerekiyor'");
			Common.MessageToUser(MessageText);
			
		EndIf;
		
	EndIf;
	
	Filter = New Structure("CompanyBankAccount", Catalogs.CompaniesBankAccounts.EmptyRef());
	OrganizationSUnfilledInvoices = TableOfSelectedRows.FindRows(Filter);
	
	If OrganizationSUnfilledInvoices.Count() > 0 Then
		
		Error = True;
		MessageText = NStr("vi = 'Cần điền tài khoản ngân hàng của doanh nghiệp.';
							|ru = 'Необходимо заполнить банковский счет организации.';
							|en = 'Fill the company bank account.'; fa = 'Fill the company bank account.';
							|it = 'È necessario compilare il conto bancario dell''azienda.';
							|pl = 'Należy wypełnić rachunek bankowy firmy.';
							|tr = 'İş yerinin banka hesabın doldurulması gerekmektedir.'");
		Common.MessageToUser(MessageText);
		
	EndIf;
	
	If Error Then
		Return;
	EndIf;
	
	ValueToFormAttribute(TableOfSelectedRows, "SelectedPersonalAccountLines");

EndProcedure

&AtServer
Function CreatingDocumentsOnServer()

	HasErrors = False;
	SelectedLinesCheck(HasErrors);
	
	If HasErrors Then
		Raise NStr("vi = 'Đã tìm thấy lỗi trong dữ liệu đầu ra';
					|ru = 'Обнаружены ошибки в исходных данных';
					|en = 'Errors are detected in the initial data'; fa = 'Errors are detected in the initial data';
					|it = 'Sono stati rilevati errori nei dati fonte';
					|pl = 'Wykryto błędy w danych źródłowych';
					|tr = 'Kaynak verilerde hatalar bulundu'");
	EndIf;
	
	TableOfSelectedRows = FormAttributeToValue("SelectedPersonalAccountLines");
	
	ArrayOfPaymentDocumentData = FillingInThesePaymentDocuments(WriteOffFormationMode,
																			TableOfSelectedRows);
	
	Return StartingDocumentCreation(ArrayOfPaymentDocumentData);

EndFunction

&AtServerNoContext
Function RowsSelected(ValueTree, RowsArray)

	Table = New ValueTable;
	
	For Each TreeColumn In ValueTree.Columns Do
		Table.Columns.Add(TreeColumn.Name, TreeColumn.ValueType);
	EndDo;
	
	For Each ArrayRow In RowsArray Do
		
		If ValueIsFilled(ArrayRow.Individual) Then
			NewRow = Table.Add();
			FillPropertyValues(NewRow, ArrayRow);
		EndIf;
		
	EndDo;
	
	Return Table;

EndFunction

&AtServerNoContext
Function FillingInThesePaymentDocuments(WriteOffFormationMode, DataTable)

	If WriteOffFormationMode = 1 Then
		SelectionByMode = New Structure("Bank, CompanyBankAccount");
	Else
		SelectionByMode = New Structure("RowID");
	EndIf;
	
	DetailsOfPaymentDocuments = New Array;
	
	While DataTable.Count() > 0 Do
		
		TableRow = DataTable.Get(0);
		FillPropertyValues(SelectionByMode, TableRow);
		
		PaymentTable = DataTable.Copy(SelectionByMode);
		
		DocumentFillingData = DataForCreatingDocuments(WriteOffFormationMode, PaymentTable);
		
		DocumentData = New Structure;
		DocumentData.Insert("DocumentType", "BankAccountIssue");
		DocumentData.Insert("FillingData", DocumentFillingData);
		DetailsOfPaymentDocuments.Add(DocumentData);
		
		DeleteRowsBySelection(DataTable, SelectionByMode);
		
	EndDo;
	
	Return DetailsOfPaymentDocuments;

EndFunction

&AtServerNoContext
Function DataForCreatingDocuments(Mode, RawData)

	DataString1 = RawData.Get(0);
	
	FillingData = New Structure;
	
	ApplicationRequestData = Common.ObjectAttributesValues(DataString1.Request, 
					"Organization, Department, CashFlowItem,
					|ExpenseReportDate, TransferToEmployeeViaABank");
	
	FillingData.Insert("PaymentRequest", DataString1.Request);
	FillingData.Insert("DocumentBasis", DataString1.Request);
	FillingData.Insert("Organization", ApplicationRequestData.Organization);
	FillingData.Insert("BusinessOperation", 
								Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	FillingData.Insert("BankAccount", DataString1.CompanyBankAccount);
	FillingData.Insert("CashFlowItem", ApplicationRequestData.CashFlowItem);
	FillingData.Insert("ExpenseReportDate", ApplicationRequestData.ExpenseReportDate);
	FillingData.Insert("Department", ApplicationRequestData.Department);
	FillingData.Insert("Currency", DataString1.Currency);
	FillingData.Insert("Sum", RawData.Total("Sum"));
	FillingData.Insert("DocumentAmount", RawData.Total("Sum"));
	FillingData.Insert("TransferToEmployeeViaABank", False);
	FillingData.Insert("PaymentByRequests", True);
	
	If Mode = 1 Then
		
		FillingData.Insert("PersonsList", True);
		
		PersonalAccounts = RawData.Copy(, "Individual, PersonalAccount, Sum, CashFlowItem");
		FillingData.Insert("PersonalAccountsOfStaff", PersonalAccounts);
		
		FillingData.Insert("TransferToEmployeeViaABank", True);
		FillingData.Insert("RankingInPriorityOfPayment", 3);
		
		If ValueIsFilled(DataString1.BankAccount) Then
			
			FillingData.Insert("CounterpartyBankAccount", DataString1.BankAccount);
			
			Counterparty = Common.ObjectAttributeValue(DataString1.BankAccount, "Owner");
			FillingData.Insert("Counterparty", Counterparty);
			
		EndIf;
		
	Else
		
		FillingData.Insert("AdvanceHolder", DataString1.Individual);
		FillingData.Insert("CashFlowItem", DataString1.CashFlowItem);
		
		If Not ApplicationRequestData.TransferToEmployeeViaABank Then
			FillingData.Insert("CounterpartyBankAccount", DataString1.PersonalAccount);
		EndIf;
		
	EndIf;
	
	Return FillingData;

EndFunction

&AtServerNoContext
Function StartingDocumentCreation(DocumentsArray)

	ExportProcedureParameters = New Structure("DocumentsToCreate", DocumentsArray);
	JobParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	
	NameOfProcedure = "CashServer.CreatePayments";
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(NameOfProcedure, ExportProcedureParameters, JobParameters);
	
	Return BackgroundJob;

EndFunction

&AtServerNoContext
Procedure TopUpTreeRows(Tree)

	Tree.Columns.Add("RowID", New TypeDescription("UUID"));
	Tree.Columns.Add("PresentationBankBankAccount",
							New TypeDescription("String", New StringQualifiers(250)));
	Tree.Columns.Add("RepresentationOfIndividualPersonalAccount",
							New TypeDescription("String", New StringQualifiers(500)));
	
	AddTreeLine(Tree.Rows);

EndProcedure

&AtServerNoContext
Procedure AddTreeLine(TreeRows)

	For Each TreeRow In TreeRows Do
		
		TreeRow.RowID = New UUID;
		TreeRow.PresentationBankBankAccount = RegistryView(TreeRow.Bank, TreeRow.BankAccount);
		TreeRow.RepresentationOfIndividualPersonalAccount = EmployeeRepresentation(TreeRow.Individual,
																				TreeRow.PersonalAccount);
		
		AddTreeLine(TreeRow.Rows);
		
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Function RegistryView(Bank, BankAccount)

	InvoiceLine_ = ?(BankAccount = PredefinedValue("Catalog.CounterpartyBankAccounts.EmptyRef"),
					"<...>",
					BankAccount);
	Return StrTemplate("%1 / %2", Bank, InvoiceLine_);

EndFunction

&AtClientAtServerNoContext
Function EmployeeRepresentation(Person, PersonalAccount)

	Return StrTemplate("%1 (%2)", Person, PersonalAccount);

EndFunction

&AtServerNoContext
Procedure DeleteRowsBySelection(DataTable, Filter)

	RowsToDelete = DataTable.FindRows(Filter);
	
	For Each CurrentRow In RowsToDelete Do
		DataTable.Delete(CurrentRow);
	EndDo;

EndProcedure

&AtServer
Procedure FormItemsManagement()

	InCommandBar = ButtonLocationInCommandBar.InCommandBar;
	InAdditionalSubmenu = ButtonLocationInCommandBar.InAdditionalSubmenu;
	
	Items.PersonalAccountsOfIndividualsForPaymentCheckAll.LocationInCommandBar = InCommandBar;
	Items.PersonalAccountsOfIndividualsForPaymentUncheckAll.LocationInCommandBar = InCommandBar;
	Items.PersonalAccountsOfIndividualsForPaymentRefreshTree.LocationInCommandBar = InAdditionalSubmenu;

EndProcedure

&AtClient
Procedure CustomizeDisplayOfFormElements()
	
	Items.PersonalAccountsOfIndividualsForPayment.UseAlternationRowColor = Not (WriteOffFormationMode = 1);
	
EndProcedure

&AtClient
Procedure CompletionOfFormationOfDocuments(Result, AdditionalParameters) Export

	If Result.Status = "Completed2" Then
		
		DocumentsArray = GetFromTempStorage(Result.ResultAddress);
		
		PerformanceMonitorClient.EndTimeConsumingOperationMeasurement(AdditionalParameters.PerformanceMeasurement,
																		DocumentsArray.Count());
		GenerateTreeOfRequestsForPayment(Undefined);
		
		NameOfForm = "Document.BankAccountIssue.ListForm";
		
		Filter = New Structure;
		Filter.Insert("Ref", DocumentsArray);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter);
		
		ClosingNotification1 = New CallbackDescription("GenerateTreeOfRequestsForPayment", ThisObject);
		
		OpenForm(NameOfForm, FormParameters, ThisObject, , , , 
						ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Result.Status = "Error" Then
		
		PerformanceMonitorClient.SetMeasurementErrorFlag(AdditionalParameters.PerformanceMeasurement, False);
		CommonClient.MessageToUser(Result.BriefErrorDescription, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DistributeAmountOfWriteOff(TreeRow)
	
	SubordinateRows = TreeRow.GetItems();
	
	If SubordinateRows.Count() = 0 Then
		
		Parent = TreeRow.GetParent();
		
		If Parent <> Undefined Then
			
			Parent.Sum = AmountOfDeductionOfSubordinateLines(Parent.GetItems());
			Parent.Mark = True;
			
		EndIf;
		
	Else
		
		Allocate = TreeRow.Sum;
		
		For Each SubordinateRow In SubordinateRows Do
			
			SubordinateRow.Sum = Min(SubordinateRow.SumBalance, Allocate);
			
			If SubordinateRow.Sum > 0 Then
				SubordinateRow.Mark = True;
			Else
				SubordinateRow.Mark = False;
			EndIf;
			
			Allocate = Allocate - SubordinateRow.Sum;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Function AmountOfDeductionOfSubordinateLines(TreeRows)
	
	TotalAmount_ = 0;
	
	For Each TreeRow In TreeRows Do
		TotalAmount_ = TotalAmount_ + TreeRow.Sum;
	EndDo;
	
	Return TotalAmount_;
	
EndFunction

#EndRegion
