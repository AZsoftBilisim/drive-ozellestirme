
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		FillInAddedAttributesInDocumentTables();
	EndIf;
	
	FormControl();
	
	SetupParameters = Documents.PostingPayrollExpensesInFinancialAccounting2_5.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", Items.GroupAdditionalAttributes.Name);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	If Object.Patch Then
		Items.ToFillOfTheChargesOnTheDevelopment.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	//++ WE
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject);
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);

	//-- WE

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	FillInAddedAttributesInDocumentTables();
	
	SetupParameters = Documents.PostingPayrollExpensesInFinancialAccounting2_5.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PostingPayrollExpensesInFinancialAccounting2_5", WriteParameters, Object.Ref);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInAddedAttributesInDocumentTables();
	
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PresentationOfTheSettlementPeriod = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.CalculationsPeriod);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettlementPeriodCleaningUp(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SettlementPeriodRegulation(Item, Direction, StandardProcessing)
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing,
		Object.CalculationsPeriod, PresentationOfTheSettlementPeriod);
	Object.CalculationsPeriod = BegOfMonth(Object.CalculationsPeriod);
EndProcedure

&AtClient
Procedure CalculationPeriodStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("CalculationPeriodStartOfSelectionCompletion", ThisObject);
	FormParameters = New Structure("Value, PeriodSelectionMode", Object.CalculationsPeriod, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection", FormParameters, ThisObject, UUID, , ,
		CloseHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculationPeriodStartOfSelectionCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	Object.CalculationsPeriod = BegOfMonth(SelectedPeriod);
	PresentationOfTheSettlementPeriod = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.CalculationsPeriod);
	
EndProcedure

&AtClient
Procedure ARAPTypeOnChange(Item)
	FormControl();
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	FormControl();
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = LocalAccountingCurrency;
	EndIf;
	
EndProcedure

&AtClient
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
//++ WE
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", Object.CalculationsPeriod);
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	

//-- WE
	Return;
		
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);
EndProcedure
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.AccrualsSettingUpAccountingRecords Then
		EditReflectionSettings(OptionsForReflectingAccruals, Item);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If NewRow Then
		If Copy Then
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item,, "Object.Accruals");
		Else
			CurrentData.PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
			FillPropertyValues(CurrentData, Object, "Department, ARAPType");
			CurrentData.ExpenseItem = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
			CurrentData.RecordingSettingPresentation = PresentationOfReflectionSettingsFillIn();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsPostingOptionOnChange(Item)
	UpdateAddedAttributesInTableRowOfDocumentWhenReflectionOptionChanges(Items.Accruals.Name, OptionsForReflectingAccruals);
EndProcedure

&AtClient
Procedure AccrualsBeforeDeleteRow(Item, Cancel)
	//++ WE       
	AccrualsBeforeDeleteRowServer(Cancel);
	//-- WE
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPayrollTaxes

&AtClient
Procedure PayrollTaxesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.TaxesContributionsOfOrganizationSettingUpReflectionInAccounting Then
		EditReflectionSettings(OptionsForReflectingAccruals, Item);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PayrollTaxesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If NewRow Then
		If Copy Then
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item,, "Object.PayrollTaxes");
		Else
			CurrentData.PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
			FillPropertyValues(CurrentData, Object, "Department");
			CurrentData.ExpenseItem = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
			CurrentData.RecordingSettingPresentation = PresentationOfReflectionSettingsFillIn();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PayrollTaxesPostingOptionOnChange(Item)
	UpdateAddedAttributesInTableRowOfDocumentWhenReflectionOptionChanges(Items.PayrollTaxes.Name, OptionsForReflectingAccruals);
EndProcedure

&AtClient
Procedure PayrollTaxesBeforeDeleteRow(Item, Cancel)
//++ WE  
	PayrollTaxesBeforeDeleteRowServer(Cancel);
//-- WE  	
	Return;
	
EndProcedure                                        

#EndRegion

#Region FormTableItemsEventHandlersDutiesOfTaxAgent

&AtClient
Procedure DutiesOfTaxAgentOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If NewRow And Not Copy Then
		FillPropertyValues(CurrentData, Object, "Department, ARAPType");
	EndIf;
	
EndProcedure

&AtClient
Procedure DutiesOfTaxAgentBeforeDeleteRow(Item, Cancel)
//++ WE

	DutiesOfTaxAgentBeforeDeleteRowServer(Cancel);

//-- WE
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDeductions

&AtClient
Procedure DeductionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.DeductionsSettingUpReflectionInAccounting Then
		EditReflectionSettings(OptionsForReflectingDeductions, Item);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DeductionsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If NewRow Then
		If Copy Then
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item,, "Object.Deductions");
		Else
			CurrentData.PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome");
			FillPropertyValues(CurrentData, Object, "Department, ARAPType");
			CurrentData.IncomeItem = PredefinedValue("ChartOfCharacteristicTypes.IncomeItems.EmptyRef");
			CurrentData.RecordingSettingPresentation = PresentationOfReflectionSettingsFillIn();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DeductionsPostingOptionOnChange(Item)
	UpdateAddedAttributesInTableRowOfDocumentWhenReflectionOptionChanges(Items.Deductions.Name, OptionsForReflectingDeductions);
EndProcedure

&AtClient
Procedure DeductionsBeforeDeleteRow(Item, Cancel)
//++ WE
	
	DeductionsBeforeDeleteRowServer(Cancel);	

//-- WE
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

#Region ImportDataFromFile

&AtClient
Procedure DownloadFromTheAccrualFile(Command)
	LoadDataIntoTableFromFile(Items.Accruals, ValueIsFilled(Object.Accruals));
EndProcedure

&AtClient
Procedure DownloadFromTheFileTaxesContributionsOfTheOrganization(Command)
	LoadDataIntoTableFromFile(Items.PayrollTaxes, ValueIsFilled(Object.PayrollTaxes));
EndProcedure

&AtClient
Procedure DownloadFromTheFileTaxesEmployeeContributions(Command)
	LoadDataIntoTableFromFile(Items.DutiesOfTaxAgent, ValueIsFilled(Object.DutiesOfTaxAgent));
EndProcedure

&AtClient
Procedure LoadFromAHoldFile(Command)
	LoadDataIntoTableFromFile(Items.Deductions, ValueIsFilled(Object.Deductions));
EndProcedure

#EndRegion

#Region CopyPasteLines

&AtClient
Procedure CopyTheAccrualLines(Command)
	CopyRows(Items.Accruals);
EndProcedure

&AtClient
Procedure CopyTheLinesTaxesContributionsOfTheOrganization(Command)
	CopyRows(Items.PayrollTaxes);
EndProcedure

&AtClient
Procedure CopyTheLinesTaxesEmployeeContributions(Command)
	CopyRows(Items.DutiesOfTaxAgent);
EndProcedure

&AtClient
Procedure CopyHoldLines(Command)
	CopyRows(Items.Deductions);
EndProcedure

&AtClient
Procedure InsertAccrualLines(Command)
	InsertRows(Items.Accruals);
EndProcedure

&AtClient
Procedure InsertTheLinesTaxesContributionsOfTheOrganization(Command)
	InsertRows(Items.PayrollTaxes);
EndProcedure

&AtClient
Procedure InsertTheLinesTaxesEmployeeContributions(Command)
	InsertRows(Items.DutiesOfTaxAgent);
EndProcedure

&AtClient
Procedure InsertHoldLines(Command)
	InsertRows(Items.Deductions);
EndProcedure

#EndRegion

&AtClient
Procedure SupplementTheAccrualsForTheDevelopmentOf(Command)
	
	FillInDocument("WorkOutput");
	
EndProcedure

&AtClient
Procedure ChangeTheAccrualDivision(Command)
	FillInDivisionInTablePart(Object.Accruals, Items.Accruals);
EndProcedure

&AtClient
Procedure ChangeTheDivisionTaxesContributionsOfTheOrganization(Command)
	FillInDivisionInTablePart(Object.PayrollTaxes, Items.PayrollTaxes);
EndProcedure

&AtClient
Procedure ChangeTheDivisionTaxesEmployeeContributions(Command)
	FillInDivisionInTablePart(Object.DutiesOfTaxAgent, Items.DutiesOfTaxAgent);
EndProcedure

&AtClient
Procedure ChangeTheRetentionDivision(Command)
	FillInDivisionInTablePart(Object.Deductions, Items.Deductions);
EndProcedure

&AtClient
Procedure ChangeTheTypeOfAccrualCalculations(Command)
	FillInARAPTypeInTabularPart(Object.Accruals, Items.Accruals);
EndProcedure

&AtClient
Procedure ChangeTheTypeOfCalculationsTaxesEmployeeContributions(Command)
	FillInARAPTypeInTabularPart(Object.DutiesOfTaxAgent, Items.DutiesOfTaxAgent);
EndProcedure

&AtClient
Procedure ChangeTheTypeOfDeductionCalculations(Command)
	FillInARAPTypeInTabularPart(Object.Deductions, Items.Deductions);
EndProcedure

&AtClient
Procedure ChangeTheAccrualReflectionSettings(Command)
	EditReflectionSettings(OptionsForReflectingAccruals, Items.Accruals);
EndProcedure

&AtClient
Procedure ChangeTheOrganizationSTaxesContributionsReflectionSettings(Command)
	EditReflectionSettings(OptionsForReflectingAccruals, Items.PayrollTaxes);
EndProcedure

&AtClient
Procedure ChangeTheHoldReflectionSettings(Command)
	EditReflectionSettings(OptionsForReflectingDeductions, Items.Deductions);
EndProcedure

&AtClient
Procedure CalculateTaxesContributions(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedLinesOnly", Items.Accruals.SelectedRows.Count() > 1);
	
	ClosingNotification1 = New CallbackDescription("CalculateTaxesContributionsCompletion", ThisObject);
	
	OpenForm("Document.PostingPayrollExpensesInFinancialAccounting2_5.Form.FormOfTaxFilling",
		FormParameters, , , , , ClosingNotification1);
	
EndProcedure

&AtClient
Procedure RecalculateTaxesOrganizationContributions(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Taxpayer", "Organization");
	FormParameters.Insert("SelectedLinesOnly", Items.PayrollTaxes.SelectedRows.Count() > 1);
	
	ClosingNotification1 = New CallbackDescription("RecalculateTaxesContributionsEnd", ThisObject, Items.PayrollTaxes);
	
	OpenForm("Document.PostingPayrollExpensesInFinancialAccounting2_5.Form.FormOfTaxFilling",
		FormParameters, , , , , ClosingNotification1);
	
EndProcedure

&AtClient
Procedure RecalculateTaxesEmployeeContributions(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Taxpayer", "Employee");
	FormParameters.Insert("SelectedLinesOnly", Items.DutiesOfTaxAgent.SelectedRows.Count() > 1);
	
	ClosingNotification1 = New CallbackDescription("RecalculateTaxesContributionsEnd", ThisObject, Items.DutiesOfTaxAgent);
	
	OpenForm("Document.PostingPayrollExpensesInFinancialAccounting2_5.Form.FormOfTaxFilling",
		FormParameters, , , , , ClosingNotification1);
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

//++ WE       
&AtServer
Procedure AccrualsBeforeDeleteRowServer(Cancel)
	
	DocumentsPayrollAndHumanResourcesServer.CheckPossibilityOfDeletingRowsInTable(
							Items.AccrualGroup.Title, Cancel, ThisObject);
	
EndProcedure

&AtServer
Procedure DeductionsBeforeDeleteRowServer(Cancel)

	DocumentsPayrollAndHumanResourcesServer.CheckPossibilityOfDeletingRowsInTable(
						Items.RetentionGroup.Title, Cancel, ThisObject);
	
EndProcedure

&AtServer
Procedure DutiesOfTaxAgentBeforeDeleteRowServer(Cancel)

	DocumentsPayrollAndHumanResourcesServer.CheckPossibilityOfDeletingRowsInTable(
				Items.EmployeeTaxesGroup.Title, Cancel, ThisObject);

EndProcedure	

&AtServer
Procedure PayrollTaxesBeforeDeleteRowServer(Cancel)
	
	DocumentsPayrollAndHumanResourcesServer.CheckPossibilityOfDeletingRowsInTable(
					Items.GroupTaxesTheOrganization.Title, Cancel, ThisObject);
	
EndProcedure	

//-- WE

&AtServer
Procedure OnReadCreateAtServer()
	
	Items.AccrualsPostingOption.ChoiceList.Clear();
	Items.PayrollTaxesPostingOption.ChoiceList.Clear();
	Items.DeductionsPostingOption.ChoiceList.Clear();
	
	OptionsForReflectingAccruals = Documents.PostingPayrollExpensesInFinancialAccounting2_5.OptionsForReflectingAccruals();
	For Each PostingOption In OptionsForReflectingAccruals Do
		
		If Not PostingOption.Value.Used Then
			Continue;
		EndIf;
		
		Items.AccrualsPostingOption.ChoiceList.Add(PostingOption.Key);
		Items.PayrollTaxesPostingOption.ChoiceList.Add(PostingOption.Key);
		
	EndDo;
	
	OptionsForReflectingDeductions = Documents.PostingPayrollExpensesInFinancialAccounting2_5.OptionsForReflectingDeductions();
	For Each PostingOption In OptionsForReflectingDeductions Do
		
		If Not PostingOption.Value.Used Then
			Continue;
		EndIf;
		
		Items.DeductionsPostingOption.ChoiceList.Add(PostingOption.Key);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FormControl()
	
	DivisionInHeader = ValueIsFilled(Object.Department);
	Items.ChangeTheAccrualDivision.Visible = Not DivisionInHeader;
	Items.ChangeTheDivisionTaxesContributionsOfTheOrganization.Visible = Not DivisionInHeader;
	Items.ChangeTheDivisionTaxesEmployeeContributions.Visible = Not DivisionInHeader;
	Items.ChangeTheRetentionDivision.Visible = Not DivisionInHeader;
	
	TypeOfCalculationsInHeader = ValueIsFilled(Object.ARAPType);
	Items.ChangeTheTypeOfAccrualCalculations.Visible = Not TypeOfCalculationsInHeader;
	Items.ChangeTheTypeOfCalculationsTaxesEmployeeContributions.Visible = Not TypeOfCalculationsInHeader;
	Items.ChangeTheTypeOfDeductionCalculations.Visible = Not TypeOfCalculationsInHeader;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Departments
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsDepartment.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PayrollTaxesDepartment.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DutiesOfTaxAgentDepartment.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeductionsDepartment.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Type of payments
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsARAPType.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DutiesOfTaxAgentARAPType.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeductionsARAPType.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// An individual in a consolidated reflection
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsIndividual.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PayrollTaxesIndividual.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DutiesOfTaxAgentIndividual.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccrualsAndTaxesDetailedByPersons");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Accruals - The color of hyperlinks
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsSettingUpAccountingRecords.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Accruals.ReflectionSettingIsCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);
	
	// Taxes of the organization - The color of hyperlinks
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TaxesContributionsOfOrganizationSettingUpReflectionInAccounting.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PayrollTaxes.ReflectionSettingIsCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);
	
	// Retention - The color of hyperlinks
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeductionsSettingUpReflectionInAccounting.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Deductions.ReflectionSettingIsCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);
	
EndProcedure

&AtServerNoContext
Function SettingUpReflectionInAccounting(TableRow, ReflectionParameters)
	
	If ReflectionParameters <> Undefined Then
		RecordingSetting = New Structure("PostingOption," + ReflectionParameters.Attributes);
	Else
		RecordingSetting = New Structure("PostingOption");
	EndIf;
	FillPropertyValues(RecordingSetting, TableRow);
	
	Return RecordingSetting;
	
EndFunction

&AtServer
Procedure UpdateAddedAttributesInTableRowOfDocumentWhenReflectionOptionChanges(TableName, ReflectionOptions)
	
	FormTable = Items[TableName];
	PathParts = StrSplit(FormTable.DataPath, ".");
	DataTable = Object[PathParts.Get(1)];
	
	TableRow = DataTable.FindByID(FormTable.CurrentRow);
	ReflectionParameters = ReflectionOptions[TableRow.PostingOption];
	RecordingSetting = SettingUpReflectionInAccounting(TableRow, ReflectionParameters);
	
	If ThisIsArticleByArticleReflection(TableRow.PostingOption) Then
		BringArticleToReflectionOption(TableRow, RecordingSetting);
	EndIf;
	
	FillInAddedAttributesInRowOfDocumentTable(TableRow, ReflectionParameters);
	
EndProcedure

&AtServer
Procedure FillInAddedAttributesInDocumentTables()
	
	FillInAddedAttributesInDocumentTable(Object.Accruals,              OptionsForReflectingAccruals);
	FillInAddedAttributesInDocumentTable(Object.PayrollTaxes, OptionsForReflectingAccruals);
	FillInAddedAttributesInDocumentTable(Object.Deductions,               OptionsForReflectingDeductions);
	
EndProcedure

&AtServer
Procedure FillInAddedAttributesInDocumentTable(DocumentTable, ReflectionOptions)
	
	For Each TableRow In DocumentTable Do
		ReflectionParameters = ReflectionOptions[TableRow.PostingOption];
		FillInAddedAttributesInRowOfDocumentTable(TableRow, ReflectionParameters);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAddedAttributesInRowOfDocumentTable(TableRow, ReflectionParameters)
	
	RecordingSetting = SettingUpReflectionInAccounting(TableRow, ReflectionParameters);
	
	TableRow.RecordingSettingPresentation = ReflectionSettingPresentation(
		ReflectionParameters.TemplateOfPresentation, ReflectionParameters.AttributeProperties, RecordingSetting);
	TableRow.ReflectionSettingIsCorrect = CheckCorrectReflectionSettings(
		ReflectionParameters.AttributeProperties, RecordingSetting);
	
EndProcedure

&AtClientAtServerNoContext
Function PresentationOfReflectionSettingsFillIn()
	Return NStr("vi = 'Điền tham số định khoản...';
				|ru = 'Заполнить параметры отражения...';
				|en = 'Fill in accounting attributes...'; fa = 'Fill in accounting attributes...';
				|it = 'Compilare i parametri di visualizzazione...';
				|pl = 'Wypełnij parametry odzwierciedlenia...';
				|tr = 'Yansıma parametrelerini doldur...'");
EndFunction

&AtServerNoContext
Function ReflectionSettingPresentation(Val Template, Attributes, RecordingSetting)
	
	TemplateParameters = New Structure;
	For Each ListItem In Attributes Do
		
		Name = ListItem.Key;
		Attribute = ListItem.Value;
		Value = Undefined;
		
		If RecordingSetting.Property(Name, Value) And ValueIsFilled(Value) Then
			TemplateParameters.Insert(Name, Value);
			Continue;
		ElsIf Not Attribute.Used Then
			Template = StrReplace(Template, "[" + Name + "]", "");
			Continue;
		ElsIf Name = "GLAccountSettings" Then
			Template = StrReplace(Template, "[" + Name + "]", "");
			Continue;
		EndIf;
		
		If Attribute.Main Then
			// The main Attributes are not filled in
			Return PresentationOfReflectionSettingsFillIn();
		EndIf;
		
		// Presentation of blank fields
		
		If Name = "ProductCostElement" Then
			TemplateParameters.Insert(Name, NStr("vi = '<theo sản lượng tính>';
												|ru = '<по выработке>';
												|en = '<by output>'; fa = '<by output>';
												|it = '<по выработке>';
												|pl = '<by output>';
												|tr = '<çıktıya göre>'"));
		ElsIf Name = "IssuancePurpose" Then
			TemplateParameters.Insert(Name, NStr("vi = '<chưa chỉ ra>';
												|ru = '<не указана>';
												|en = '<not specified>'; fa = '<مشخص نشده>';
												|it = '<non indicata>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'"));
		ElsIf Name = "ARAPObject" Then
			TemplateParameters.Insert(Name, NStr("vi = '<chưa chỉ ra>';
												|ru = '<не указана>';
												|en = '<not specified>'; fa = '<مشخص نشده>';
												|it = '<non indicata>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'"));
		ElsIf StrStartsWith(Name, "Dimension") And ThisIsArticleByArticleReflection(RecordingSetting.PostingOption) Then
			
			AssetRef = ArticleOfReflectionInAccounting(RecordingSetting);
			ArticleSettings = Documents.PostingPayrollExpensesInFinancialAccounting2_5.PropertiesOfReflectionArticle(AssetRef);
			
			If ArticleSettings.AutocompletionIsAvailable Then
				TemplateParameters.Insert(Name, NStr("vi = '<được chọn tự động>';
													|ru = '<подбирается автоматически>';
													|en = '<picked automatically>'; fa = '<picked automatically>';
													|it = '<viene selezionato automaticamente>';
													|pl = '<wybierane automatycznie>';
													|tr = '<otomatik olarak seçilir>'"));
			EndIf;
			
		EndIf;
		
		If Not TemplateParameters.Property(Name) Then
			TemplateParameters.Insert(Name, NStr("vi = '<...>';
												|ru = '<...>';
												|en = '<...>'; fa = '<...>';
												|it = '<...>';
												|pl = '<...>';
												|tr = '<...>'"));
		EndIf;
		
	EndDo;
	
	If Not IsBlankString(Template) Then
		Template = StrReplace(Template, "][", "], [");
		Presentation = StringFunctionsClientServer.InsertParametersIntoString(Template, TemplateParameters);
	Else
		Presentation = NStr("vi = '<Không bắt buộc>';
							|ru = '<не требуется>';
							|en = '<not required>'; fa = '<الزامی نیست>';
							|it = '<non richiesto>';
							|pl = '<nie jest wymagane>';
							|tr = '<gerekli değil>'");
	EndIf;
	
	Return Presentation;
	
EndFunction

&AtServerNoContext
Function CheckCorrectReflectionSettings(Attributes, RecordingSetting)
	
	Result = True;
	
	For Each ListItem In Attributes Do
		
		Name = ListItem.Key;
		Attribute = ListItem.Value;
		Value = Undefined;
		
		If Not Attribute.Used Or Not Attribute.AttributeIsRequired Then
			Continue;
		ElsIf RecordingSetting.Property(Name, Value) And ValueIsFilled(Value) Then
			Continue;
		EndIf;
		
		// Additional verification of required but blank fields
		
		If StrStartsWith(Name, "Dimension") And ThisIsArticleByArticleReflection(RecordingSetting.PostingOption) Then
			
			AssetRef = ArticleOfReflectionInAccounting(RecordingSetting);
			ArticleSettings = Documents.PostingPayrollExpensesInFinancialAccounting2_5.PropertiesOfReflectionArticle(AssetRef);
			
			If ArticleSettings.WithoutDimension Then
				Continue;
			ElsIf Not ArticleSettings.ControlDimensionFilling Then
				Continue;
			ElsIf ArticleSettings.AutocompletionIsAvailable Then
				Continue;
			EndIf;
			
		ElsIf Name = "GLAccountSettings" Then
			
			AssetRef = ArticleOfReflectionInAccounting(RecordingSetting);
			ArticleSettings = Documents.PostingPayrollExpensesInFinancialAccounting2_5.PropertiesOfReflectionArticle(AssetRef);
			
			If Not ArticleSettings.YouCanConfigureAccountingAccounts Then
				Continue;
			EndIf;
			
		EndIf;
		
		Result = False;
		Break;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function BringArticleToReflectionOption(TableRow, RecordingSetting)
	
	CitedArticle = ArticleOfReflectionInAccounting(RecordingSetting);
	If RecordingSetting.Property("ExpenseItem") And TableRow.ExpenseItem <> CitedArticle Then
		TableRow.ExpenseItem = CitedArticle;
		Return True;
	ElsIf RecordingSetting.Property("IncomeItem") And TableRow.IncomeItem <> CitedArticle Then
		TableRow.IncomeItem = CitedArticle;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function ArticleOfReflectionInAccounting(RecordingSetting)
	
	AssetRef = Undefined;
	If Not (RecordingSetting.Property("ExpenseItem", AssetRef) Or RecordingSetting.Property("IncomeItem", AssetRef)) Then
		Return Undefined;
	EndIf;
	
	ReflectionOptions = Enums.AccrualsDeductionsRecordOptions;
	If RecordingSetting.PostingOption = ReflectionOptions.RecogniseAsOtherExpenses Then
		ArticleType = New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems");
	ElsIf RecordingSetting.PostingOption = ReflectionOptions.RecogniseAsOtherIncome Then
		ArticleType = New TypeDescription("ChartOfCharacteristicTypesRef.IncomeItems");
	ElsIf RecordingSetting.PostingOption = ReflectionOptions.RecognizeAsOtherAssetsLiabilities Then
		ArticleType = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
	Else
		ArticleType = Undefined;
	EndIf;
	
	If ArticleType = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ArticleType.AdjustValue(AssetRef);
	
EndFunction

&AtClient
Procedure EditReflectionSettings(ReflectionOptions, FormTable)
	
	If FormTable.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = FormTable.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization",     Object.Organization);
	FormParameters.Insert("DocumentDate",   Object.Date);
	FormParameters.Insert("DocumentCurrency", Object.Currency);
	FormParameters.Insert("ReflectionOptions", ReflectionOptions);
	FormParameters.Insert("PurposeUseKey", FormTable.Name);
	
	ReflectionOptionParameters = ReflectionOptions[CurrentData.PostingOption];
	If ReflectionOptionParameters <> Undefined Then
		FormParameters.Insert("FillingValues",
			New Structure("PostingOption," + ReflectionOptionParameters.Attributes));
		FillPropertyValues(FormParameters.FillingValues, CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ReflectionOptions", ReflectionOptions);
	AdditionalParameters.Insert("SelectedRows", FormTable.SelectedRows);
	AdditionalParameters.Insert("TableName", FormTable.Name);
	
	ClosingNotification1 = New CallbackDescription("EditReflectionSettingsCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("Document.PostingPayrollExpensesInFinancialAccounting2_5.Form.SettingsFormOfPostingInAccounting",
		FormParameters, ThisObject, , , , ClosingNotification1);
	
EndProcedure

&AtClient
Procedure EditReflectionSettingsCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		EditReflectionSettingsOnServer(Result, AdditionalParameters);
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure EditReflectionSettingsOnServer(Result, AdditionalParameters)
	
	ReflectionParameters = AdditionalParameters.ReflectionOptions[Result.PostingOption];
	
	ReflectionSettingPresentation = ReflectionSettingPresentation(
		ReflectionParameters.TemplateOfPresentation, ReflectionParameters.AttributeProperties, Result);
	ReflectionSettingIsCorrect = CheckCorrectReflectionSettings(
		ReflectionParameters.AttributeProperties, Result);
	
	FormTable = Items[AdditionalParameters.TableName];
	SelectedRows = AdditionalParameters.SelectedRows;
	
	PathParts = StrSplit(FormTable.DataPath, ".");
	DataTable = Object[PathParts.Get(1)];
	
	For Each RowID In SelectedRows Do
		
		TableRow = DataTable.FindByID(RowID);
		FillPropertyValues(TableRow, Result);
		TableRow.RecordingSettingPresentation = ReflectionSettingPresentation;
		TableRow.ReflectionSettingIsCorrect = ReflectionSettingIsCorrect;
		
	EndDo;
	
	GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, FormTable.DataPath, SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInDivisionInTablePart(DataTable, Item)
	
	ClosingNotification1 = New CallbackDescription("FillInDetailsInTablePart", ThisObject,
		New Structure("DataTable, AttributeName, SelectedRows", DataTable, "Department", Item.SelectedRows));
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", , Item, , , , ClosingNotification1);
	
EndProcedure

&AtClient
Procedure FillInARAPTypeInTabularPart(DataTable, Item)
	
	ClosingNotification1 = New CallbackDescription("FillInDetailsInTablePart", ThisObject,
		New Structure("DataTable, AttributeName, SelectedRows", DataTable, "ARAPType", Item.SelectedRows));
	
	OpenForm("Catalog.TypesOfEmployeeCompensations.ChoiceForm", , Item, , , , ClosingNotification1);
	
EndProcedure

&AtClient
Procedure FillInDetailsInTablePart(Result, FillParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	FillingValues = New Structure(FillParameters.AttributeName, Result);
	
	DataTable = FillParameters.DataTable;
	For Each IdentifierOfString In FillParameters.SelectedRows Do
		TableRow = DataTable.FindByID(IdentifierOfString);
		FillPropertyValues(TableRow, FillingValues);
	EndDo;
	
EndProcedure

&AtClient
Procedure CalculateTaxesContributionsCompletion(Result, AdditionalParameters = Undefined) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Result.TaxesKinds) Then
		Return;
	EndIf;
	
	CalculateTaxContributionsOnServer(Result);
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure CalculateTaxContributionsOnServer(PopulationSettings)
	
	If PopulationSettings.SelectedLinesOnly Then
		RowsCollection = New Array;
		For Each RowID In Items.Accruals.SelectedRows Do
			RowsCollection.Add(Object.Accruals.FindByID(RowID));
		EndDo;
	Else
		RowsCollection = Object.Accruals;
	EndIf;
	
	If Not ValueIsFilled(RowsCollection) Then
		Return;
	EndIf;
	
	TaxesOfOrganization = Items.PayrollTaxes;
	EmployeeTaxes = Items.DutiesOfTaxAgent;
	
	// Clearing the selected lines
	
	TaxesOfOrganization.SelectedRows.Clear();
	EmployeeTaxes.SelectedRows.Clear();
	
	// Resetting the current line
	
	TaxesOfOrganization.CurrentRow = Undefined;
	EmployeeTaxes.CurrentRow = Undefined;
	
	For Each ListItem In PopulationSettings.TaxesKinds Do
		
		TaxKind        = ListItem.Key;
		CalculationParameters = ListItem.Value;
		
		CalculateTaxContributionsOnAccruals(RowsCollection, TaxKind, CalculationParameters);
		
	EndDo;
	
	// If new lines have been added, select them and switch the Cur page
	// If no new lines have been added, then I will select the Cur line if there is one
	
	If TaxesOfOrganization.SelectedRows.UBound() >= 0 Then
		Items.Pages.CurrentPage = Items.GroupTaxesTheOrganization;
	ElsIf TaxesOfOrganization.CurrentRow <> Undefined Then
		TaxesOfOrganization.SelectedRows.Add(TaxesOfOrganization.CurrentRow);
	EndIf;
	
	If EmployeeTaxes.SelectedRows.UBound() >= 0 Then
		Items.Pages.CurrentPage = Items.EmployeeTaxesGroup;
	ElsIf EmployeeTaxes.CurrentRow <> Undefined Then
		EmployeeTaxes.SelectedRows.Add(EmployeeTaxes.CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateTaxContributionsOnAccruals(Accruals, TaxKind, CalculationParameters)
	
	If CalculationParameters.EmployeeTax Then
		FormTable = Items.DutiesOfTaxAgent;
		DataTable = Object.DutiesOfTaxAgent;
	Else
		FormTable = Items.PayrollTaxes;
		DataTable = Object.PayrollTaxes;
	EndIf;
	
	For Each TableRow In Accruals Do
		
		NewRow = DataTable.Add();
		
		FillPropertyValues(NewRow, TableRow,, "Sum");
		NewRow.TaxBase = TableRow.Sum;
		NewRow.TaxKind     = TaxKind;
		
		NewRow.Sum = CalculateTaxAmountByParameters(TableRow.Sum, CalculationParameters);
		
		RowID = NewRow.GetID();
		If FormTable.CurrentRow = Undefined Then
			FormTable.CurrentRow = RowID;
		EndIf;
		FormTable.SelectedRows.Add(RowID);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RecalculateTaxesContributionsEnd(Result, Item) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Result.TaxesKinds) Then
		Return;
	EndIf;
	
	If Item = Items.PayrollTaxes Then
		RecalculateTaxContributionsOfOrganizationOnServer(Result);
	ElsIf Item = Items.DutiesOfTaxAgent Then
		RecalculateEmployeeTaxContributionsOnServer(Result);
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure RecalculateTaxContributionsOfOrganizationOnServer(RecalculationSettings)
	RecalculateTaxContributionsOnServer(RecalculationSettings, Object.PayrollTaxes, Items.PayrollTaxes.SelectedRows);
EndProcedure

&AtServer
Procedure RecalculateEmployeeTaxContributionsOnServer(RecalculationSettings)
	RecalculateTaxContributionsOnServer(RecalculationSettings, Object.DutiesOfTaxAgent, Items.DutiesOfTaxAgent.SelectedRows);
EndProcedure

&AtServer
Procedure RecalculateTaxContributionsOnServer(RecalculationSettings, DataTable, SelectedRows)
	
	If RecalculationSettings.SelectedLinesOnly Then
		RowsCount = SelectedRows.Count();
	Else
		RowsCount = DataTable.Count();
	EndIf;
	
	For IndexOf = 0 To RowsCount - 1 Do
		
		If RecalculationSettings.SelectedLinesOnly Then
			TableRow = DataTable.FindByID(SelectedRows[IndexOf]);
		Else
			TableRow = DataTable[IndexOf];
		EndIf;
		
		CalculationParameters = RecalculationSettings.TaxesKinds.Get(TableRow.TaxKind);
		If CalculationParameters = Undefined Then
			Continue;
		EndIf;
		
		TableRow.Sum = CalculateTaxAmountByParameters(TableRow.TaxBase, CalculationParameters);
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function CalculateTaxAmountByParameters(TaxBase, CalculationParameters)
	
	Result = 0;
	If CalculationParameters.CalculationMethod_2 = "AsAPercent" Then
		Result = TaxBase / 100 * CalculationParameters.Value;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure HighlightAddedLines(FormTable, RowsArray)
	
	If Not ValueIsFilled(RowsArray) Then
		Return;
	EndIf;
	
	FormTable.CurrentRow = RowsArray[0];
	FormTable.SelectedRows.Clear();
	For Each RowID In RowsArray Do
		FormTable.SelectedRows.Add(RowID);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ThisIsArticleByArticleReflection(PostingOption)
	
	Return PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses
			Or PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome
			Or PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
	
EndFunction

#Region FillingInDocument_

&AtClient
Procedure FillInDocument(FillInSources)
	
	TimeConsumingOperation = FillInDocumentInBackgroundOnServer(FillInSources);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	CallbackOnCompletion = New CallbackDescription("FillInDocumentCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure FillInDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInDocumentOnServer(Result);
	
EndProcedure

&AtServer
Function FillInDocumentInBackgroundOnServer(FillInSources)
	
	FillParameters = Documents.PostingPayrollExpensesInFinancialAccounting2_5.DocumentFillingParameters();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.BeginOfPeriod = BegOfMonth(Object.CalculationsPeriod);
	FillParameters.EndOfPeriod  = EndOfMonth(Object.CalculationsPeriod);
	FillParameters.IndividualsInDetail = Object.AccrualsAndTaxesDetailedByPersons;
	If ValueIsFilled(Object.Department) Then
		FillParameters.Department = Object.Department;
	EndIf;
	
	If Not IsBlankString(FillInSources) Then
		CommonClientServer.SupplementStructure(FillParameters.Sources, New Structure(FillInSources));
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền chứng từ ""Phản ánh tiền lương vào kế toán tài chính""';
														|ru = 'Заполнение документа «Отражение зарплаты в финансовом учете»';
														|en = 'Fill the ""Post payroll expenses to accounting"" document'; fa = 'Fill the ""Post payroll expenses to accounting"" document';
														|it = 'Заполнение документа «Отражение зарплаты в финансовом учете»';
														|pl = 'Fill the ""Post payroll expenses to accounting"" document';
														|tr = '""Finansal muhasebede maaşın yansıması"" belgesinin doldurulması'");
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters,
		"Documents.PostingPayrollExpensesInFinancialAccounting2_5.PrepareFillingData",
		New FixedStructure(FillParameters));
	
EndFunction

&AtServer
Procedure FillInDocumentOnServer(Result)
	
	FillingData = GetFromTempStorage(Result.ResultAddress);
	If TypeOf(FillingData) <> Type("Structure") Then
		Return;
	EndIf;
	
	If FillingData.Property("WorkOutput") Then
		
		If Not ValueIsFilled(Object.ARAPType) Then
			ARAPType = Catalogs.TypesOfEmployeeCompensations.Payroll;
		Else
			ARAPType = Object.ARAPType;
		EndIf;
		
		PostingOption = Enums.AccrualsDeductionsRecordOptions.AllocateToProduction;
		ReflectionParameters = OptionsForReflectingAccruals[PostingOption];
		RecordingSetting = New Structure(ReflectionParameters.Attributes);
		RecordingSetting.Insert("PostingOption", PostingOption);
		RecordingSetting.Insert("AllocationBaseType",
			Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel);
		
		ReflectionSettingPresentation = ReflectionSettingPresentation(
			ReflectionParameters.TemplateOfPresentation, ReflectionParameters.AttributeProperties, RecordingSetting);
		ReflectionSettingIsCorrect = CheckCorrectReflectionSettings(
			ReflectionParameters.AttributeProperties, RecordingSetting);
		
		For Each OutputLine In FillingData.WorkOutput Do
			
			NewRow = Object.Accruals.Add();
			
			NewRow.ARAPType          = ARAPType;
			NewRow.AccrualKind        = Catalogs.AccrualAndDeductionKinds.Wage;
			
			NewRow.Department        = OutputLine.Department;
			NewRow.Individual       = OutputLine.Individual;
			NewRow.Sum                = OutputLine.Sum;
			
			FillPropertyValues(NewRow, RecordingSetting);
			
			NewRow.RecordingSettingPresentation = ReflectionSettingPresentation;
			NewRow.ReflectionSettingIsCorrect = ReflectionSettingIsCorrect;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Async Procedure LoadDataIntoTableFromFile(FormTable, HasData = False)
	
	If HasData And Await DoQueryBoxAsync(StrTemplate(
		NStr("vi = 'Bảng ""%1"" sẽ bị xóa. Tiếp tục?';
			|ru = 'Таблица ""%1"" будет очищена. Продолжить?';
			|en = 'The ""%1"" table will be cleared. Continue?'; fa = 'The ""%1"" table will be cleared. Continue?';
			|it = 'Таблица ""%1"" будет очищена. Продолжить?';
			|pl = 'The ""%1"" table will be cleared. Continue?';
			|tr = '""%1"" tablosu temizlenecektir. Devam edilsin mi?'"), FormTable.Title),
		QuestionDialogMode.YesNo) <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowImportForm(FormTable);
	
EndProcedure

&AtClient
Procedure ShowImportForm(FormTable)
	
	HeaderOfUploadForm = StrTemplate(
		NStr("vi = 'Đang tải bảng ''''%1'''' từ tệp';
			|ru = 'Загрузка таблицы ""%1"" из файла';
			|en = 'Download the table ""%1"" from the file'; fa = 'Download the table ""%1"" from the file';
			|it = 'Download della tabella ""%1"" dal file';
			|pl = 'Wczytywanie tabeli „%1” z pliku';
			|tr = 'Dosyadan ""%1"" tablosunun yüklenmesi'"),
		FormTable.Parent.Title);
	
	If FormTable = Items.Deductions Then
		ReflectionOptions = OptionsForReflectingDeductions;
	Else
		ReflectionOptions = OptionsForReflectingAccruals;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Organization", Object.Organization);
	AdditionalParameters.Insert("AvailableReflectionOptions", New Array);
	For Each Variant In ReflectionOptions Do
		AdditionalParameters.AvailableReflectionOptions.Add(Variant.Key);
	EndDo;
	
	DataImportParameters = ImportDataFromFileClient.DataImportParameters();
	DataImportParameters.Title = HeaderOfUploadForm;
	DataImportParameters.FullTabularSectionName =
		"PostingPayrollExpensesInFinancialAccounting2_5." + FormTable.Name;
	DataImportParameters.TemplateColumns =
		DescriptionOfTemplateColumnsToLoadFromFile(FormTable.Name);
	DataImportParameters.AdditionalParameters = AdditionalParameters;
	
	Notification = New CallbackDescription("ShowImportFormCompletion", ThisObject, FormTable.Name);
	ImportDataFromFileClient.ShowImportForm(DataImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowImportFormCompletion(ImportedDataAddress, TableName) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress, TableName);
	
EndProcedure

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress, FormTableName)
	
	FormTable = Items[FormTableName];
	
	PathParts = StrSplit(FormTable.DataPath, ".");
	DataTable = Object[PathParts.Get(1)];
	
	DataTable.Clear();
	
	HeaderAttributes = New Structure;
	If ValueIsFilled(Object.Department) Then
		HeaderAttributes.Insert("Department", Object.Department);
	EndIf;
	If ValueIsFilled(Object.ARAPType) Then
		HeaderAttributes.Insert("ARAPType", Object.ARAPType);
	EndIf;
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	RecordingSetting = New Structure;
	RecordingSetting.Insert("RecordingSettingPresentation", PresentationOfReflectionSettingsFillIn());
	
	For Each TableRow In ImportedData Do
		
		NewRow = DataTable.Add();
		FillPropertyValues(NewRow, TableRow);
		FillPropertyValues(NewRow, HeaderAttributes);
		FillPropertyValues(NewRow, RecordingSetting);
		
	EndDo;
	
	If ValueIsFilled(DataTable) Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function DescriptionOfTemplateColumnsToLoadFromFile(TabularSectionName)
	
	TypesOfCalculationsRequired   = Not ValueIsFilled(Object.ARAPType);
	UnitsRequired  = Not ValueIsFilled(Object.Department);
	IndividualsAreRequired = Object.AccrualsAndTaxesDetailedByPersons;
	
	TemplateColumns = Documents.PostingPayrollExpensesInFinancialAccounting2_5.DescriptionOfTemplateColumnsToLoadFromFile(
		TabularSectionName, UnitsRequired, IndividualsAreRequired, TypesOfCalculationsRequired);
	
	Return TemplateColumns;
	
EndFunction

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyRows(FormTable)
	
	If Not ValueIsFilled(FormTable.SelectedRows) Then
		ShowMessageBox(, NStr("vi = 'Để sao chép, bạn cần chọn các hàng của phần bảng.';
								|ru = 'Для копирования требуется выбрать строки табличной части.';
								|en = 'Select lines of the table to copy.'; fa = 'Select lines of the table to copy.';
								|it = 'Per copiare è necessario selezionare le righe della tabella.';
								|pl = 'W celu kopiowania należy wybrać wiersze sekcji tabelarycznej.';
								|tr = 'Kopyalamak için tablo bölümünün satırlarının seçilmesi gerekir.'"));
		Return;
	EndIf;
	
	CopyLinesOnServer(FormTable.Name);
	
	TitleText = NStr("vi = 'Đã sao chép dòng';
					|ru = 'Строки скопированы';
					|en = 'Lines are copied'; fa = 'Lines are copied';
					|it = 'Righe copiate';
					|pl = 'Wiersze są skopiowane';
					|tr = 'Satırlar kopyalandı'");
	MessageText = NStr("vi = 'Số lượng hàng: %1';
						|ru = 'Количество строк: %1';
						|en = 'Line quantity: %1'; fa = 'Line quantity: %1';
						|it = 'Numero di righe: %1';
						|pl = 'Ilość wierszy: %1';
						|tr = 'Satır miktarı: %1'");
	
	ShowUserNotification(TitleText,,
		StrTemplate(MessageText, FormTable.SelectedRows.Count()),
		PictureLib.Information32,
		UserNotificationStatus.Information);
	
	Notify("CopyingSalaryReflectionLinesToClipboard");
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer(TableName)
	
	FormTable = Items[TableName];
	TabularSection = Object[TableName];
	
	ProcessingOfTabularForms.CopyRowsToClipboard(TabularSection, FormTable.SelectedRows);
	
EndProcedure

&AtClient
Procedure InsertRows(FormTable)
	
	NewLines = InsertRowsOnServer(FormTable.Name);
	
	HighlightAddedLines(FormTable, NewLines);
	
	TitleText = NStr("vi = 'Đã chèn dòng';
					|ru = 'Строки вставлены';
					|en = 'Lines are inserted'; fa = 'Lines are inserted';
					|it = 'Righe inserite';
					|pl = 'Wiersze są wstawione';
					|tr = 'Satırlar eklendi'");
	MessageText = NStr("vi = 'Số lượng hàng: %1';
						|ru = 'Количество строк: %1';
						|en = 'Line quantity: %1'; fa = 'Line quantity: %1';
						|it = 'Numero di righe: %1';
						|pl = 'Ilość wierszy: %1';
						|tr = 'Satır miktarı: %1'");
	
	ShowUserNotification(TitleText,,
		StrTemplate(MessageText, NewLines.Count()),
		PictureLib.Information32,
		UserNotificationStatus.Information);
	
EndProcedure

&AtServer
Function InsertRowsOnServer(TableName)
	
	NewLines = New Array;
	FilterParameters = New Map;
	
	If TableName = Items.Accruals.Name Then
		FilterParameters.Insert("AccrualKind.ItIsADeduction", False);
	ElsIf TableName = Items.Deductions.Name Then
		FilterParameters.Insert("DeductionKind.ItIsADeduction", True);
	Else
		FilterParameters.Insert("TaxKind.DeductedFromEmployeeWages",
			TableName = Items.DutiesOfTaxAgent.Name);
	EndIf;
	
	TableFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters);
	If Not ValueIsFilled(TableFromBuffer) Then
		Return NewLines;
	EndIf;
	
	Table = Object[TableName]; // FormDataCollection - tabular part of the document
	
	For Each TableRow In TableFromBuffer Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, TableRow);
		NewLines.Add(NewRow.GetID());
	EndDo;
	
	Return NewLines;
	
EndFunction

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

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
