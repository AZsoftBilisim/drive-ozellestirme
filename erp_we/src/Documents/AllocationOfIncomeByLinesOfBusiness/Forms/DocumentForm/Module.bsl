#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	SetConditionalAppearance();
	
	// Control of document creation in a subordinate RIB node with filters
	DataExchangeTMERP.ControlOfCreationOfDocumentsInDistributedInformationSecurity(Object, Cancel);
	
	// Handler of the subsystem "Versioning of objects"
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
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	Items.IncomeSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán quản trị có Thuế GTGT (%1)';
			|ru = 'Упр. учет с НДС (%1)';
			|en = 'Management accounting including VAT (%1)'; fa = 'Management accounting including VAT (%1)';
			|it = 'Contabilità gestionale con IVA (%1)';
			|pl = 'Ewid. administr. z VAT (%1)';
			|tr = 'KDV dahil yönetim muhasebesi (%1)'"),
		ManagementAccountingCurrency);
	Items.IncomeSumMan.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán quản trị không có Thuế GTGT (%1)';
			|ru = 'Упр. учет без НДС (%1)';
			|en = 'Management accounting excluding VAT (%1)'; fa = 'Management accounting excluding VAT (%1)';
			|it = 'Contabilità gestionale IVA esclusa (%1)';
			|pl = 'Ewid. administr. bez VAT (%1)';
			|tr = 'KDV hariç yönetim muhasebesi (%1)'"),
		ManagementAccountingCurrency);
		
	Items.ExpensesSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán quản trị có Thuế GTGT (%1)';
			|ru = 'Упр. учет с НДС (%1)';
			|en = 'Management accounting including VAT (%1)'; fa = 'Management accounting including VAT (%1)';
			|it = 'Contabilità gestionale con IVA (%1)';
			|pl = 'Ewid. administr. z VAT (%1)';
			|tr = 'KDV dahil yönetim muhasebesi (%1)'"),
		ManagementAccountingCurrency);
	Items.ExpensesSumMan.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kế toán quản trị không có Thuế GTGT (%1)';
			|ru = 'Упр. учет без НДС (%1)';
			|en = 'Management accounting excluding VAT (%1)'; fa = 'Management accounting excluding VAT (%1)';
			|it = 'Contabilità gestionale IVA esclusa (%1)';
			|pl = 'Ewid. administr. bez VAT (%1)';
			|tr = 'KDV hariç yönetim muhasebesi (%1)'"),
		ManagementAccountingCurrency);
		
	FillInDetailsInTablePart_();
	Items.GroupExpenses.Visible = Object.Expenses.Count();	
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocationOfIncomeByLinesOfBusiness.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);	

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocationOfIncomeByLinesOfBusiness.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AllocationOfIncomeByLinesOfBusiness");

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInDetailsInTablePart_();
	IncomeAndExpensesServer.AfterWriteAtServer(ThisForm);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

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
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DistributionOptionForAllOrganizationsOnChange(Item)
	
	DistributionOptionForOrganizationsInCaseOfChanges();
	
EndProcedure

&AtClient
Procedure DistributionOptionForSelectedOrganizationsOnChange(Item)
	
	DistributionOptionForOrganizationsInCaseOfChanges();
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsIncomings

&AtClient
Procedure IncomeOnStartEdit(Item, NewRow, Copy)
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.Income");
EndProcedure

&AtClient
Procedure IncomeOnActivateRow(Item)
	
	CurrentData = Items.Income.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.LocalAccountingCurrency) Then
		Items.IncomeSumCompl.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kế toán doanh nghiệp (%1)';
				|ru = 'Бухгалтерский учет (%1)';
				|en = 'Local accounting (%1):'; fa = 'Local accounting (%1):';
				|it = 'Contabilità (%1)';
				|pl = 'Ewidencja księgowa (%1)';
				|tr = 'Genel muhasebe (%1)'"),
			CurrentData.LocalAccountingCurrency);
	Else
		Items.IncomeSumCompl.Title = NStr("vi = 'Kế toán doanh nghiệp';
											|ru = 'Бухгалтерский учет';
											|en = 'Local accounting'; fa = 'حسابداری محلی';
											|it = 'Contabilità';
											|pl = 'Księgowość';
											|tr = 'Genel muhasebe'");
	EndIf;
	
EndProcedure

&AtClient
Procedure IncomeLineOfBusinessOnChange(Item)
	
	TableRow = Items.Income.CurrentData;
	If ValueIsFilled(TableRow.LineOfBusiness) Then
		TableRow.AllocationMethodIsRequired = False;
	ElsIf ValueIsFilled(TableRow.IncomeItem) Then
		IncomeItemOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure IncomeOrganizationOnChange(Item)
	IncomeOrganizationOnChangeServer();
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsCosts

&AtClient
Procedure ExpensesOnStartEdit(Item, NewRow, Copy)
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject,Item.CurrentData, "Object.Expenses");
EndProcedure

&AtClient
Procedure ExpensesOnActivateRow(Item)
	
	CurrentData = Items.Expenses.CurrentData;
	
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.LocalAccountingCurrency) Then
		Items.ExpensesSumCompl.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kế toán doanh nghiệp (%1)';
				|ru = 'Бухгалтерский учет (%1)';
				|en = 'Local accounting (%1):'; fa = 'Local accounting (%1):';
				|it = 'Contabilità (%1)';
				|pl = 'Ewidencja księgowa (%1)';
				|tr = 'Genel muhasebe (%1)'"),
			CurrentData.LocalAccountingCurrency);
		Items.ExpensesAmountFA.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kế toán thuế (%1)';
				|ru = 'Налоговый учет (%1)';
				|en = 'Tax accounting (%1)'; fa = 'Tax accounting (%1)';
				|it = 'Contabilità fiscale (%1)';
				|pl = 'Ewidencja podatkowa (%1)';
				|tr = 'Vergi muhasebesi (%1)'"),
			CurrentData.LocalAccountingCurrency);
		Items.ExpensesPermanentDifference.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chênh lệch vĩnh viễn (%1)';
				|ru = 'Постоянная разница (%1)';
				|en = 'Permanent difference (%1)'; fa = 'Permanent difference (%1)';
				|it = 'Differenza costante (%1)';
				|pl = 'Stała różnica (%1)';
				|tr = 'Kalıcı fark (%1)'"),
			CurrentData.LocalAccountingCurrency);
		Items.ExpensesCostTD.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chênh lệch tạm thời (%1)';
				|ru = 'Временная разница (%1)';
				|en = 'Temporary difference (%1)'; fa = 'Temporary difference (%1)';
				|it = 'Differenza temporanea (%1)';
				|pl = 'Tymczasowa różnica (%1)';
				|tr = 'Geçici fark (%1)'"),
			CurrentData.LocalAccountingCurrency);
	Else
		Items.ExpensesSumCompl.Title = NStr("vi = 'Kế toán doanh nghiệp';
											|ru = 'Бухгалтерский учет';
											|en = 'Local accounting'; fa = 'حسابداری محلی';
											|it = 'Contabilità';
											|pl = 'Księgowość';
											|tr = 'Genel muhasebe'");
		Items.ExpensesAmountFA.Title = NStr("vi = 'Kế toán thuế';
											|ru = 'Налоговый учет';
											|en = 'Tax accounting'; fa = 'حسابداری مالیاتی';
											|it = 'Contabilità fiscale';
											|pl = 'Ewidencja podatkowa';
											|tr = 'Vergi muhasebesi'");
		Items.ExpensesPermanentDifference.Title = NStr("vi = 'Chênh lệch vĩnh viễn';
														|ru = 'Постоянная разница';
														|en = 'Permanent difference'; fa = 'تفاوت دائم';
														|it = 'Differenza costante';
														|pl = 'Różnica trwała';
														|tr = 'Sabit fark'");
		Items.ExpensesCostTD.Title = NStr("vi = 'Chênh lệch tạm thời';
											|ru = 'Временная разница';
											|en = 'Temporary difference'; fa = 'تفاوت موقت';
											|it = 'Differenza temporanea';
											|pl = 'Różnica tymczasowa';
											|tr = 'Geçici fark'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesLineOfBusinessOnChange(Item)
	
	TableRow = Items.Expenses.CurrentData;
	If ValueIsFilled(TableRow.LineOfBusiness) Then
		TableRow.AllocationMethodIsRequired = False;
	ElsIf ValueIsFilled(TableRow.ExpenseItem) Then
		ExpenseItemOnChangeServer(CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesOrganizationOnChange(Item)
	ExpensesOrganizationOnChangeServer();
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	TableRow = Items.Expenses.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
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
Procedure FillInIncomeExecute(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Income;
	If Not Object.AllocationByAllCompanies Then
		CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Azienda';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	EndIf;
	Notification = New CallbackDescription("FillInIncomeExecuteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInIncomeExecuteCompletion(Result, AdditionalParameters) Export
	
	FillInIncomeOnBalances();
	
EndProcedure

&AtClient
Procedure FillInExpensesExecute(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Expenses;
	If Not Object.AllocationByAllCompanies Then
		CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Azienda';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	EndIf;
	Notification = New CallbackDescription("FillInExpensesExecuteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInExpensesExecuteCompletion(Result, AdditionalParameters) Export
	
	FillInExpensesOnBalances();
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Expenses;
	If Not Object.AllocationByAllCompanies Then
		CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Azienda';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	EndIf;
	Notification = New CallbackDescription("FillCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillCompletion(Result, AdditionalParameters) Export
	
	If Object.Income.Count() > 0 Then
		Object.Income.Clear();
	EndIf;
	FillInIncomeOnBalances();
	FillInExpensesOnBalances();
	
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

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpensesLineOfBusinessAllocationMethod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Expenses.AllocationMethodIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Expenses.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Expenses.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không cần';
													|ru = 'Не требуется';
													|en = 'Not required'; fa = 'لازم نیست';
													|it = 'Non è richiesto';
													|pl = 'Nie jest wymagane';
													|tr = 'Gerekli değil'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeLineOfBusinessAllocationMethod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Income.AllocationMethodIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Income.DimensionOfRevenue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Income.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không cần';
													|ru = 'Не требуется';
													|en = 'Not required'; fa = 'لازم نیست';
													|it = 'Non è richiesto';
													|pl = 'Nie jest wymagane';
													|tr = 'Gerekli değil'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure DistributionOptionForOrganizationsInCaseOfChanges()
	
	Object.AllocationByAllCompanies = (CompanyAllocationOption = 1);
	FormItemsManagement();
	
	If Object.AllocationByAllCompanies
	 And ValueIsFilled(Object.Organization) Then
	 
		For Each TableRow In Object.Income Do
			If Not ValueIsFilled(TableRow.Organization) Then
				TableRow.Organization = Object.Organization;
			EndIf;
		EndDo;
		For Each TableRow In Object.Expenses Do
			If Not ValueIsFilled(TableRow.Organization) Then
				TableRow.Organization = Object.Organization;
			EndIf;
		EndDo;
	 
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	FormItemsManagement();
EndProcedure

&AtServer
Procedure IncomeOrganizationOnChangeServer()
	
	TableRow = Object.Income.FindByID(Items.Income.CurrentRow);
	TableRow.LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(TableRow.Organization);
	
EndProcedure

&AtServer
Procedure ExpensesOrganizationOnChangeServer()
	
	TableRow = Object.Expenses.FindByID(Items.Expenses.CurrentRow);
	TableRow.LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(TableRow.Organization);
	
EndProcedure

&AtServer
Procedure IncomeItemOnChangeServer()
	
	TableRow = Object.Income.FindByID(Items.Income.CurrentRow);
	
	Attributes = ChartsOfCharacteristicTypes.IncomeItems.GetDetailsOfIncomeItem(TableRow.IncomeItem);
	FillPropertyValues(TableRow, Attributes, "LineOfBusinessAllocationMethod, AllocationMethodIsRequired");
	
EndProcedure

&AtServer
Procedure ExpenseItemOnChangeServer(CachedValues)
	
	TableRow = Object.Expenses.FindByID(Items.Expenses.CurrentRow);
	
	Attributes = ChartsOfCharacteristicTypes.ExpenseItems.GetDetailsOfExpenseItem(TableRow.ExpenseItem);
	TableRow.LineOfBusinessAllocationMethod = Attributes.LineOfBusinessAllocationMethod;
	TableRow.AllocationMethodIsRequired = Attributes.AllocationMethodIsRequired;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	If Object.AllocationByAllCompanies Then
		CompanyAllocationOption = 1;
	Else
		CompanyAllocationOption = 0;
	EndIf;
	
	FillInCurrencyOfRegulatedAccounting(Object.Income);
	FillInCurrencyOfRegulatedAccounting(Object.Expenses);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.Organization.Enabled = Not Object.AllocationByAllCompanies;
	Items.IncomeOrganization.Visible = Object.AllocationByAllCompanies;
	Items.ExpensesOrganization.Visible = Object.AllocationByAllCompanies;
	DifferenceFields = New Map;
	DifferenceFields.Insert(Items.ExpensesCostTD,  "TD");
	DifferenceFields.Insert(Items.ExpensesPermanentDifference, "PD");
	LocalAccntingServer.ConfigureVisibilityOfTaxAccountingAndDifferencesFields(
		DifferenceFields, Object.Date, Object.Organization);
EndProcedure

&AtServer
Procedure FillInIncomeOnBalances()

	DocumentDistributions = FormAttributeToValue("Object");
	DocumentDistributions.FillInIncomeOnBalances();
	ValueToFormAttribute(DocumentDistributions, "Object");
	FillInCurrencyOfRegulatedAccounting(Object.Income);
EndProcedure

&AtServer
Procedure FillInExpensesOnBalances()

	DocumentDistributions = FormAttributeToValue("Object");
	DocumentDistributions.FillInExpensesOnBalances();
	ValueToFormAttribute(DocumentDistributions, "Object");
	FillInCurrencyOfRegulatedAccounting(Object.Expenses);
	FillInDetailsInTablePart_();
EndProcedure

&AtServer
Procedure FillInDetailsInTablePart_()
	For Each String In Object.Expenses Do
		String.AmountFA = String.SumCompl - String.PermanentDifference - String.CostTD;
	EndDo;
	TotalExpensesAmountTA = Object.Expenses.Total("AmountFA");
EndProcedure

#EndRegion

&AtClient
Procedure ExpensesSumComplOnChange(Item)
	TableRow = Items.Expenses.CurrentData;
	TableRow.AmountFA = TableRow.SumCompl - TableRow.PermanentDifference;
	ExpensesAmountFAOnChange(Item);
EndProcedure

&AtClient
Procedure ExpensesAmountFAOnChange(Item)
	TableRow = Items.Expenses.CurrentData;
	TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;
	TotalExpensesAmountTA = Object.Expenses.Total("AmountFA");
EndProcedure

&AtClient
Procedure ExpensesPermanentDifferenceOnChange(Item)
	ExpensesSumComplOnChange(Item);
EndProcedure

&AtServer
Procedure FillInCurrencyOfRegulatedAccounting(FormTable)
	For Each String In FormTable Do
		String.LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(String.Organization);
	EndDo;
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
