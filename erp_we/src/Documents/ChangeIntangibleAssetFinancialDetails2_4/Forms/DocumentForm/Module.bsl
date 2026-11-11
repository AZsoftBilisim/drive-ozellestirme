
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ChangeIntangibleAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.ChangeIntangibleAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ChangeIntangibleAssetFinancialDetails2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();

	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
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
	
	FillInInformationInBasement();
	FillInCurParameterValues();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ChangeIntangibleAssetFinancialDetails2_4" Then
		FillInInformationInBasement();
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure AccountingProcedureACFlagOnChange(Item)

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure UsefulLifeAccountingFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure DepreciationAccrualFactorFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure AccountingProcedureFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure LineOfBusinessFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("Basis", Object.Ref);
		OpenForm("Document.ChangeIntangibleAssetFinancialDetails2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure AccelerationFactorManagementAccountingFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure ResidualValueLocalFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure ResidualValueManFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure FinancialAccountingGroupFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure EstimatedRunningTimeFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure DepreciationExpenseRecordingIsChangedOnChange(Item)
	
	If Object.DepreciationExpenseRecordingIsChanged
		And Object.Depreciation.Count() <> 1 Then
			
		Object.Depreciation.Clear();
		NewRow = Object.Depreciation.Add();
		NewRow.ZoomRatio = 1;
		
		Items.Depreciation.CurrentRow = NewRow.GetID();
		
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure SwitchDepreciationWithoutSplittingOnChange(Item)
	
	If SwitchDepreciationWithoutSplitting
		And Object.Depreciation.Count() > 1 Then
			
		For IndexOf = -Object.Depreciation.Count() To -2 Do
			Object.Depreciation.Delete(-IndexOf - 1);
		EndDo;
		
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure ExpensesPostingMethodOnChange(Item)
	
	ChangedBankingDetails = "ExpensesPostingMethod,DepreciationIsExpenseItemWithoutDivision,DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpensesPostingMethod, 
		Object.Depreciation[0].ExpenseItem, 
		Object.Depreciation[0].DimensionOfExpenses, 
		Object.Depreciation[0].Department, 
		Object.Depreciation[0].LineOfBusiness, 
		Object.Depreciation[0].BusinessUnitAndLineOfBusinessMatchAccountingData);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.DepreciationIsExpenseItemWithoutDivision);
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure DepreciationIsExpenseItemWithoutDivisionOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod= PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,DepreciationIsExpenseItemWithoutDivision");
	
EndProcedure

&AtClient
Procedure DepreciationExpenseAnalyticsWithoutPartitioningOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod= PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure DepreciationDivisionWithoutDivisionOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure DepreciationLineOfBusinessWithoutDivisionOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	CurrentData = Items.Depreciation.CurrentData;
	If CurrentData <> Undefined 
		And CurrentData.BusinessUnitAndLineOfBusinessMatchAccountingData Then
			
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		CurrentData.LineOfBusiness = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision");
	
EndProcedure

&AtClient
Procedure DepreciationTransferExpensesToAnotherCompanyWithoutSplittingOnChange(Item)

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	ChangeIntangibleAssetFinancialDetailsClientLocalization.OnChangeAttribute(Item.Name, ThisObject);

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected).Count() <> 0 Then
		WhenChangingIAOnServer();
	EndIf; 
	
EndProcedure

&AtClient
Procedure IAIntangibleAssetOnChange(Item)
	
	WhenChangingIAOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepreciation

&AtClient
Procedure DepreciationExpenseItemOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DepreciationExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDivisionAndLineOfBusinessCoincideWithAccountingDataOnChange(Item)
	
	CurrentData = Items.Depreciation.CurrentData;
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	If CurrentData.BusinessUnitAndLineOfBusinessMatchAccountingData Then
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		CurrentData.LineOfBusiness = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationDepartmentOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationLineOfBusinessOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationTransferExpensesToAnotherCompanyOnChange(Item)
	
	TableRow = Items.Depreciation.CurrentData;
	If Not TableRow.TransferExpensesToAnotherCompany Then
		TableRow.CompanyRecipientOfExpenses = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisObject);
	OpenForm(
		"Catalog.IntangibleAssets.ChoiceForm",
		PickingParameters,
		Items.IA,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ShowTheCurrentValues(Command)
	
	ShowTheCurrentValues = Not ShowTheCurrentValues;
	Items.IAShowTheCurrentValues.Check = ShowTheCurrentValues;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ShowTheCurrentValues");
	
EndProcedure

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

#Region AttachableCommands

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region DepreciationDepartment
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.BusinessUnitAndLineOfBusinessMatchAccountingData");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Vị trí của tài sản vô hình>';
													|ru = '<Местонахождение НМА>';
													|en = '<Intangible assets location>'; fa = '<Intangible assets location>';
													|it = '<Sede dei beni immateriali>';
													|pl = '<Lokacja wartości niematerialnych>';
													|tr = '<GMA''nın Yeri>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.BusinessUnitAndLineOfBusinessMatchAccountingData");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Vị trí của tài sản vô hình>';
													|ru = '<Местонахождение НМА>';
													|en = '<Intangible assets location>'; fa = '<Intangible assets location>';
													|it = '<Sede dei beni immateriali>';
													|pl = '<Lokacja wartości niematerialnych>';
													|tr = '<GMA''nın Yeri>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	#EndRegion
	
	#Region DepreciationLineOfBusiness
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationLineOfBusiness.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.BusinessUnitAndLineOfBusinessMatchAccountingData");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Lĩnh vực hoạt động TSCĐVH>';
													|ru = '<Направление деятельности НМА>';
													|en = '<Intangible asset line of business>'; fa = '<Intangible asset line of business>';
													|it = '<Направление деятельности НМА>';
													|pl = '<Intangible asset line of business>';
													|tr = '<GMA iş kolu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion

	#Region NotAccepted_Local
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IADepreciationAccrualTaxAccounting.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IASpecialFactorTaxAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IA.RecognizedCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принят к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<Dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
			
	#Region NotRegistered_Man
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAAccountingProcedureMA.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IADepreciationAccrualMethodManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAUsefulLifeManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAAccelerationFactorManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAResidualValueMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAResidualValueLocal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IA.RecognizedManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принят к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<Dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	#Region NotAccepted__
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAFinancialAccountingGroup.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAEstimatedRunningTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IA.RecognizedManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IA.RecognizedCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принят к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<Dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	#Region DepreciationCompanyRecipientOfExpenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationCompanyRecipientOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.TransferExpensesToAnotherCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInCurParameterValues();
	
	SwitchDepreciationWithoutSplitting = Object.Depreciation.Count() < 2;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	Items.IAResidualValueLocal.Title = StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
														|ru = 'Ликвидационная стоимость (%1)';
														|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
														|it = 'Costo di liquidazione (%1)';
														|pl = 'Wartość likwidacyjna (%1)';
														|tr = 'Artık değer (%1)'"), String(ComplCurrency));
	Items.IAResidualValueMan.Title = StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
														|ru = 'Ликвидационная стоимость (%1)';
														|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
														|it = 'Costo di liquidazione (%1)';
														|pl = 'Wartość likwidacyjna (%1)';
														|tr = 'Artık değer (%1)'"), String(CurrencyOfMan));
	
	Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);
	
	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
	
	FillInInformationInBasement();

	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ActionParameters);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedDetailsOrElement = "")
	
	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ChangingIAParameters(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "IA,Depreciation");
	EndIf;

	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or StructureOfChangedProps.Property("UsefulLifeAccountingFlag")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeAccounting);
		
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or StructureOfChangedProps.Property("UsefulLifeTaxAccountingFlag")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeManagementAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Items.LiquidationValueReglCurrency.Visible = Items.ResidualValueLocal.Visible;
		Items.LiquidationValueCurrency.Visible = Items.ResidualValueMan.Visible;
			
	EndIf;

	#EndRegion
	
	#Region DepreciationPage
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged") 
		Or StructureOfChangedProps.Property("ExpensesPostingMethod") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpensesPostingMethod, 
			Form,
			"DepreciationIsExpenseItemWithoutDivision,DepreciationExpenseAnalyticsWithoutPartitioning,DepreciationDivisionWithoutDivision,DepreciationLineOfBusinessWithoutDivision,DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision");
	
	EndIf;

	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or StructureOfChangedProps.Property("SwitchDepreciationWithoutSplitting")
		Or StructureOfChangedProps.Property("DepreciationTransferExpensesToAnotherCompanyWithoutSplitting")
		Or StructureOfChangedProps.Property("DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision")
		Or UpdateAll Then
			
		Items.PagesReflectingDepreciationExpenses.CurrentPage =
			?(Form.SwitchDepreciationWithoutSplitting, 
			Items.PageReflectionOfDepreciationExpensesWithoutSplitting,
			Items.PageReflectsDepreciationExpensesAsList);
	
		If Form.SwitchDepreciationWithoutSplitting
			And Object.Depreciation.Count() <> 0 Then
			Items.Depreciation.CurrentRow = Object.Depreciation[0].GetID();
		EndIf;
	
		CurrentData = ?(Object.Depreciation.Count() <> 0, Object.Depreciation[0], Undefined);
		If CurrentData <> Undefined 
			And CurrentData.BusinessUnitAndLineOfBusinessMatchAccountingData Then
			Items.DepreciationLineOfBusinessWithoutDivision.InputHint = NStr("vi = '<Lĩnh vực hoạt động TSCĐVH>';
																			|ru = '<Направление деятельности НМА>';
																			|en = '<Intangible asset line of business>'; fa = '<Intangible asset line of business>';
																			|it = '<Направление деятельности НМА>';
																			|pl = '<Intangible asset line of business>';
																			|tr = '<GMA iş kolu>'");
		Else
			Items.DepreciationLineOfBusinessWithoutDivision.InputHint = "";
		EndIf;
		
	EndIf;
	
	#EndRegion
		
	ImpairmentFAClientServer.CGUVisibilityManagement(Form, "CGUFlag");

	SetVisibilityOfCurValues(Form, UpdateAll, StructureOfChangedProps);
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_ChangeIAParameters(
		Form, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInInformationInBasement()
	
	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object, False);

	ChangeIntangibleAssetFinancialDetailsLocalization.CompleteInformationInBasement(Object, LabelTitle);
	
	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInCurParameterValues();

	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfCurValues(Form, UpdateAll, StructureOfChangedProps)

	Items = Form.Items; 
	Object = Form.Object;
	
	BUProperties  = New Array;
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("AccountingProcedureAC", "AccountingProcedureACFlag"));
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationAccrualFactor", "DepreciationAccrualFactorFlag"));
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("UsefulLifeAccounting", "UsefulLifeAccountingFlag"));
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationMethodAccounting", "DepreciationMethodAccountingFlag"));
	
	PropertiesOfMa  = New Array;
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("AccountingProcedureMA", "AccountingProcedureMAFlag"));
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationAccrualMethodManagementAccounting", "DepreciationAccrualMethodManagementAccountingFlag"));
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("UsefulLifeManagementAccounting", "UsefulLifeManagementAccountingFlag"));
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("AccelerationFactorManagementAccounting", "AccelerationFactorManagementAccountingFlag"));
	
	GeneralProperties = New Array;
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("FinancialAccountingGroup", "FinancialAccountingGroupFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("EstimatedRunningTime", "EstimatedRunningTimeFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("LineOfBusiness","LineOfBusinessFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("ResidualValueMan", "ResidualValueManFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("ResidualValueLocal", "ResidualValueLocalFlag"));
	
	PropertiesCountLocalization = 0;
	NumberOfBUProperties = 0;
	NumberOfMaProperties = 0;
	NumberOfPropertiesShared = 0;
	
	For Each ArrayElement In BUProperties Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, Undefined, ArrayElement, "IA", StructureOfChangedProps);
			
		NumberOfBUProperties = NumberOfBUProperties + ?(Object[ArrayElement.AttributeNameFlag], 1, 0);
		
	EndDo;

	For Each ArrayElement In PropertiesOfMa Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, Undefined, ArrayElement, "IA", StructureOfChangedProps);
			
		NumberOfMaProperties = NumberOfMaProperties + ?(Object[ArrayElement.AttributeNameFlag], 1, 0);
		
	EndDo;
	
	For Each ArrayElement In GeneralProperties Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, Undefined, ArrayElement, "IA", StructureOfChangedProps);
			
		NumberOfPropertiesShared = NumberOfPropertiesShared + ?(Object[ArrayElement.AttributeNameFlag], 1, 0);
		
	EndDo;
	
	NonCurrentAssetsClientServerLocalization.SetVisibilityOfCurValues_ChangeIAParameters(
		Form, NumberOfMaProperties + NumberOfBUProperties, NumberOfPropertiesShared, PropertiesCountLocalization, StructureOfChangedProps);
	
	If Form.ShowTheCurrentValues Then
		
		ShowInHeader = PropertiesCountLocalization <> 0;
		If Items.NirupaUU.ShowInHeader <> ShowInHeader Then
			Items.NirupaUU.ShowInHeader = ShowInHeader;
		EndIf;
		
		If Items.NirupaTotal.ShowInHeader <> ShowInHeader Then
			Items.NirupaTotal.ShowInHeader = ShowInHeader;
		EndIf;
		
	EndIf;

	Form.NumberOfChangedProperties = PropertiesCountLocalization + NumberOfMaProperties + NumberOfBUProperties + NumberOfPropertiesShared;

	If Form.ShowTheCurrentValues 
		And Form.NumberOfChangedProperties > 0
		And Items.IAIntangibleAsset.FixingInTable <> FixingInTable.Left Then
		
		Items.IAIntangibleAsset.FixingInTable = FixingInTable.Left;
		
	ElsIf (Not Form.ShowTheCurrentValues 
				Or Form.NumberOfChangedProperties = 0)
		And Items.IAIntangibleAsset.FixingInTable <> FixingInTable.None Then
		
		Items.IAIntangibleAsset.FixingInTable = FixingInTable.None;
		
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillInCurParameterValues()
	
	If Object.IA.Count() = 0 Then
		Return;
	EndIf;

	QueryText = ChangeIntangibleAssetFinancialDetailsLocalization.RequestTextForFillingInCurParameterValues();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	IntangibleAssets.Ref AS IntangibleAsset,
		|	ISNULL(IntangibleAssetsAccountingProcedure.FinancialAccountingGroup, UNDEFINED) AS FinancialAccountingGroup,
		|	ISNULL(IntangibleAssetsAccountingProcedure.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
		|	ISNULL(IntangibleAssetsAccountingProcedure.EstimatedRunningTime, UNDEFINED) AS EstimatedRunningTime,
		|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
		|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting,
		|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.AccelerationFactor, 0) AS AccelerationFactorManagementAccounting,
		|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod, UNDEFINED) AS DepreciationAccrualMethodManagementAccounting,
		|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
		|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan, 0) AS ResidualValueLocal,
		|	CASE 
		|		WHEN ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization, FALSE) 
		|			THEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|		ELSE VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|	END AS AccountingProcedureMA,
		|	CASE 
		|		WHEN ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.DepreciationAccrualAccounting, FALSE) 
		|			THEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|		ELSE VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|	END AS AccountingProcedureAC,
		|	ISNULL(InitialIntangibleAssetsInformation.DocumentOfRecognitionManagementAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecognizedManag,
		|	ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.DepreciationAccrualFactor, 0) AS DepreciationAccrualFactor,
		|	ISNULL(InitialIntangibleAssetsInformation.DepreciationMethodAccounting, 0) AS DepreciationMethodAccounting,
		|	ISNULL(InitialIntangibleAssetsInformation.DocumentOfRecognitionAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecognizedCompl
		|
		|FROM
		|	Catalog.IntangibleAssets AS IntangibleAssets
		|
		|		LEFT JOIN InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|					AND Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IADepreciationParametersBookkeepingAndTaxAccounting
		|		ON (IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|					AND Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetAmortizationParametersManagementAccounting
		|		ON (IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND Organization = &Organization
		|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAccountingProcedure
		|		ON (IntangibleAssetsAccountingProcedure.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|					AND Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAccountingProcedureManagementAccounting
		|		ON (IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|					AND Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
		|		ON (IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
		|				,
		|				Organization = &Organization
		|					AND IntangibleAsset IN (&ListOfIA)) AS InitialIntangibleAssetsInformation
		|		ON (InitialIntangibleAssetsInformation.IntangibleAsset = IntangibleAssets.Ref)";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfIA", Object.IA.Unload().UnloadColumn("IntangibleAsset"));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", EndOfDay(?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate())));
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	For Each RowData In Object.IA Do
		CurrentValues = Result.Find(RowData.IntangibleAsset, "IntangibleAsset");
		If CurrentValues <> Undefined Then
			FillPropertyValues(RowData, CurrentValues);
		Else
			RowData.RecognizedCompl = False;
			RowData.RecognizedManag = False;
		EndIf; 
	EndDo; 
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
		
	FillInInformationInBasement();
	FillInCurParameterValues();

	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure WhenChangingIAOnServer()
	
	FillInHeaderForSelectedIA();
	FillInCurParameterValues();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedIA()

	ChangedBankingDetails = "IntangibleAsset";
	NonCurrentAssetsInternal.FillInHeaderForSelectedIA(
		"Organization", 
		Object.IA, 
		Object, 
		ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
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
