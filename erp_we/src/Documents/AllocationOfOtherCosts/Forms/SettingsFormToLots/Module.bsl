#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var AttributeCache;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, 
		Documents.AllocationOfOtherCosts.ItemsAndDimensionsSelectionParameters());
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, 
		Documents.AllocationOfOtherCosts.AccountingAccountSettings_());
	If Not ValueIsFilled(Object.Ref) Then
		If Object.LocalAccounting Then
			SynchronizeTypesOfAccountingBUAndTa("LocalAccounting");
		ElsIf Object.TaxAccounting Then
			SynchronizeTypesOfAccountingBUAndTa("TaxAccounting");
		EndIf;
		OnReadCreateAtServer();
	EndIf;
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases);
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases);
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases);
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases);		
	Items.DecorationSaveDistributionSetting.Visible = 
		Not CostAllocationFromCostCenter And AccessRight("Update", Metadata.InformationRegisters.SettingsOfItemizedExpensesAllocation);
	Items.GroupCheckBoxKindOfAccounting.Enabled = CalculationOfCostCached.BatchAccountingVersion22(Object.Date);
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, 
		Documents.AllocationOfOtherCosts.ItemsAndDimensionsSelectionParameters());
	GLAccountSettingsServer.OnReadAtServer(ThisObject, 
		Documents.AllocationOfOtherCosts.AccountingAccountSettings_());
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfForm();
	FillInServiceDetailsOfTS();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.SettingsOfBaseOfAllocationByLotsChanged Then
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(
			SettingsOfBaseOfAllocationByLots.GetSettings());
	Else
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(Undefined);
	EndIf;
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);

	If Object.AllocationDirectionSettingsChanged Then
		CurrentObject.AllocationDirectionSettings = New ValueStorage(
			AllocationDirectionSettings.GetSettings());
	Else
		CurrentObject.AllocationDirectionSettings = New ValueStorage(Undefined);
	EndIf;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCaptionPeriod();
	
	AttributeCache = New Structure;
	AttributeCache.Insert("ManagementAccounting", Object.ManagementAccounting);
	AttributeCache.Insert("LocalAccounting", Object.LocalAccounting);

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
		

	Object.ToAnyLinesOfBusiness = ForAllAreasOfActivity;
	Object.BaseOfAllocationByBusinessUnits = Undefined;
	Object.BusinessUnitsAreSpecifiedManually = False;
	
	If MethodOfDivisionDistribution = "ByIndicator" Then
		Object.BaseOfAllocationByBusinessUnits = 
			GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Factor, "AllocationBase");
	ElsIf MethodOfDivisionDistribution = "Manually" Then
		Object.BusinessUnitsAreSpecifiedManually = True;
	ElsIf ValueIsFilled(MethodOfDivisionDistribution) Then
		
		Base = PredefinedValue("Enum.TypesOfCostAllocatingBase." + MethodOfDivisionDistribution);
		Object.BaseOfAllocationByBusinessUnits = Base;
		
	EndIf;
			
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	CheckFillingOfTabularPartOfIssueWithoutOrdering(Cancel);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TransferParameters = Undefined;
	
	If FormOwner <> Undefined And FormOwner.Name = "ExpenseItems" Then
		
		TransferParameters = New Structure();
		TransferParameters.Insert("Organization", Object.Organization);
		TransferParameters.Insert("Department", Object.Department);
		TransferParameters.Insert("ExpenseItem", Object.ExpenseItem);
		TransferParameters.Insert("DimensionOfExpenses", Object.DimensionOfExpenses);
		TransferParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
		
		If Object.Posted Then
			
			DocumentTransfers_ = Object.Ref;
			State = PredefinedValue("Enum.CostAllocationStates.ReadyForAllocation");
				
		Else
			
			DocumentTransfers_ = Undefined;
			State = PredefinedValue("Enum.CostAllocationStates.DocumentGenerationIsRequired");
				
		EndIf;
		
		If Object.ManagementAccounting Or AttributeCache.ManagementAccounting Then
			
			If Not Object.ManagementAccounting And AttributeCache.ManagementAccounting Then
				
				TransferParameters.Insert("DocumentMan", Undefined);				
				TransferParameters.Insert("UPRStatus", 
					PredefinedValue("Enum.CostAllocationStates.DocumentGenerationIsRequired"));
				
			Else
				
				TransferParameters.Insert("DocumentMan", DocumentTransfers_);				
				TransferParameters.Insert("UPRStatus", State);
				
			EndIf;
			
		EndIf;
		
		If Object.LocalAccounting Or AttributeCache.LocalAccounting Then
			
			If Not Object.LocalAccounting And AttributeCache.LocalAccounting Then
				
				TransferParameters.Insert("DocumentCompl", Undefined);				
				TransferParameters.Insert("ReglStatus", 
					PredefinedValue("Enum.CostAllocationStates.DocumentGenerationIsRequired"));
				
			Else
				
				TransferParameters.Insert("DocumentCompl", DocumentTransfers_);				
				TransferParameters.Insert("ReglStatus", State);
				
			EndIf;
			
		EndIf;
		

	EndIf;
	
	Notify("Write_AllocationOfOtherCosts", TransferParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UnavailableElementsByFederalDistrict(Object.Date);
	SetVisibilityOfElementsByFO("GroupLeaveGNZP");
	UpdateCaptionPeriod();
	
EndProcedure

&AtClient
Procedure DecorationSaveDistributionSettingClick(Item)
	If Not Object.Posted Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Trước khi lưu cài đặt, cần kết chuyển một chứng từ.';
				|ru = 'Перед сохранением настройки документ требуется провести.';
				|en = 'Post the document before saving the setting.'; fa = 'Post the document before saving the setting.';
				|it = 'Prima di salvare le impostazioni è necessario registrare il documento.';
				|pl = 'Przed zapisaniem ustawień należy zaksięgować dokument.';
				|tr = 'Ayarları kaydetmeden önce belgenin tutulması gerekmektedir.'"));
		Return;
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExpenseItem", Object.ExpenseItem);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Department", Object.Department);
	If Object.ManagementAccounting Then
		FormParameters.Insert("SettingsManAccounting", Object.Ref);
	EndIf;
	If Object.LocalAccounting Then
		FormParameters.Insert("SettingsLocal", Object.Ref);
	EndIf;
		
	OpenForm("InformationRegister.SettingsOfItemizedExpensesAllocation.Form.RecordForm", 
		FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure TypeOfAccountingForChanges(Item)
	SynchronizeTypesOfAccountingBUAndTa(Item.Name);
	SetAvailabilityOfAccountingTypes();
EndProcedure

#EndRegion

#Region EventHandlersDistributionRules

&AtClient
Procedure AllocateByLotsOnChange(Item)
	
	If Not Object.AllocateByLots Then
		SpecifyChangingBankingDetails("AllocateByLots");
	Else
		ProcessChangeDistributeItInBatches();
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsAreSpecifiedManuallyOnChange(Item)
	
	SpecifyChangingBankingDetails("LotsAreSpecifiedManually")
	
EndProcedure

&AtClient
Procedure AllocateToExpenseItemsOnChange(Item)
	
	If Not Object.AllocateToExpenseItems Then
		SpecifyChangingBankingDetails("AllocateToExpenseItems");
	Else
		ProcessChangeDistributeToArticles();
	EndIf;
	
EndProcedure

&AtClient
Procedure LeaveAsWIPOnChange(Item)
	
	If Not Object.LeaveAsWIP Then
		Object.CostShareOfWIP = 0;
	EndIf;
	
	SetItemsAvailability(ThisForm, "LeaveAsWIP");
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtClient
Procedure CostShareForProductionOnChange(Item)
	
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtClient
Procedure AllocationDirectionOnChange(Item)
	
	HandleChangeOfDistributionDirection();
	
EndProcedure

&AtClient
Procedure MethodOfDivisionDistributionOnChange(Item)
	
	HandleChangingDistributionMethod();
	
EndProcedure

&AtClient
Procedure UseAllocationByDepartmentsOnChange(Item)
	
	ProcessChangeUseDivisionAllocation();
	
EndProcedure

&AtClient
Procedure BaseOfAllocationByLotsOnChange(Item)
	
	ProcessChangeInDistributionBaseByBatch();
	
EndProcedure

&AtClient
Procedure TextAddEditSelectionOfTheBatchDistributionDatabaseClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.BaseOfAllocationByLots) Then
		CommonClient.MessageToUser(NStr("vi = 'Trước khi thêm bộ lọc, cần chọn cơ sở phân bổ.';
										|ru = 'Перед добавлением отбора необходимо выбрать базу распределения.';
										|en = 'Select allocation base before adding a filter.'; fa = 'Select allocation base before adding a filter.';
										|it = 'Prima di aggiungere la selezione è necessario scegliere la base di ripartizione.';
										|pl = 'Przed dodaniem wyboru należy wybrać podstawę podziału.';
										|tr = 'Filtre eklemeden önce tahsisat tabanını seçmeniz gerekmektedir.'"),,
			"Object.BaseOfAllocationByLots");
		Return;
	EndIf;
		OpeningParameters = ParametersForOpeningSelectionSettings();
		OpeningParameters.SchemaName = NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots);
		OpeningParameters.NameOfComposerSettings = "SettingsOfBaseOfAllocationByLots";
		If OpeningParameters.SchemaName = "MaterialCosts"
			Or OpeningParameters.SchemaName = "MaterialAndLaborCosts" Then
			OpeningParameters.DoNotConfigureSettings = False;
		EndIf;
	
		OpenSelectionSettingsForm(OpeningParameters, NStr("vi = 'Tùy chỉnh bộ lọc cơ sở phân bổ';
															|ru = 'Настройка отбора базы распределения';
															|en = 'Allocation base filter settings'; fa = 'Allocation base filter settings';
															|it = 'Impostare la selezione della base di ripartizione';
															|pl = 'Ustawienie wyboru podstawy podziału';
															|tr = 'Tahsisat tabanının filtre ayarı'"));

EndProcedure

&AtClient
Procedure TextAddEditSelectionDistributionDirectionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
		OpeningParameters = ParametersForOpeningSelectionSettings();
		OpeningParameters.SchemaName = "AllocationDirection";
		OpeningParameters.NameOfComposerSettings = "AllocationDirectionSettings";
		
		OpenSelectionSettingsForm(OpeningParameters, NStr("vi = 'Tùy chỉnh lọc bộ phận';
															|ru = 'Настройка отбора подразделений';
															|en = 'Operating units filter settings'; fa = 'Operating units filter settings';
															|it = 'Impostazione della selezione di reparti';
															|pl = 'Ustawienie wyboru działów';
															|tr = 'Departman filtre ayarı'"));
	
EndProcedure

&AtClient
Procedure TextAddChangeFilterByManufacturedProductsBatchesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepartments

&AtClient
Procedure DepartmentsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		If Not Copy Then
			Items.Departments.CurrentData.ProductCostElement = Object.ProductCostElement;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DepartmentsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		UpdateCostShares(ThisForm);
	EndIf;

EndProcedure

&AtClient
Procedure DepartmentsAfterDeleteRow(Item)
	
	UpdateCostShares(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManualSteps

&AtClient
Procedure ManualStepsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	If Not Copy Then
		Cancel = True;
		OpenSelectionByStagesForm(False);
	EndIf;
	Return; // In KA, the handler is empty
	
EndProcedure

&AtClient
Procedure ManualStepsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False; 
	FillInSelection(ValueSelected.AddressInStorage, "Manually");
	Return; // In KA, the handler is empty
	
EndProcedure

&AtClient
Procedure ManualStepsOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		If Not Copy Then
			Items.ManualSteps.CurrentData.ProductCostElement = Object.ProductCostElement;
		EndIf;
	EndIf;
	Return; // In KA, the handler is empty
	
EndProcedure

&AtClient
Procedure ManualStepsOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		UpdateCostShares(ThisForm);
	EndIf;
	Return; // In KA, the handler is empty

EndProcedure

&AtClient
Procedure ManualStepsAfterDeleteRow(Item)
	UpdateCostShares(ThisForm);
	Return; // In KA, the handler is empty
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductionLots

&AtClient
Procedure ProductionLotsOnChange(Item)
	UpdateCostShares(ThisForm);
EndProcedure

&AtClient
Procedure ProductionLotsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	OpenSelectionByStagesForm(True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductionIssueWithoutReferences

&AtClient
Procedure ProductionIssueWithoutReferencesOnChange(Item)
	
	CostSharesAmountInclReleasesWithoutOrders = ProductionIssueWithoutReferences.Total("CostShare");
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessingProductSelectionFromOrder(ValueSelected);
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesCostShareOnChange(Item)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If ExpandReleasesWithoutReferences Then
		UpdateObjectTable("ProductionIssueWithoutReferences", CurrentData.GetID());
	Else
		DistributeShareOfCost(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		If Not Copy Then
			Items.ProductionIssueWithoutReferences.CurrentData.ProductCostElement = Object.ProductCostElement;
		EndIf;
	EndIf;
	SaveRowData(Items.ProductionIssueWithoutReferences.CurrentData);
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If Not ExpandReleasesWithoutReferences Then
		FilterStructure1 = New Structure("Products, Characteristic, ProductCostElement");
	Else
		FilterStructure1 = New Structure("DocumentOfProductionIssue, RowCode");
	EndIf;
	
	FillPropertyValues(FilterStructure1, CurrentData);
	FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
	
	For Each String In FoundRows Do
		Object.ProductionIssueWithoutReferences.Delete(String);
	EndDo;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If Field.Name = "ProductionIssueWithoutReferencesDocumentOfProductionIssue" Then
		StandardProcessing = False;
		ShowValue(, CurrentData.DocumentOfProductionIssue);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesProductCostElementOnChange(Item)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If ExpandReleasesWithoutReferences Then
		UpdateObjectTable("ProductionIssueWithoutReferences", CurrentData.GetID());
	Else
		SetCalculationArticleByLine(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		UpdateCostShares(ThisForm);
	EndIf;

EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesAfterDeleteRow(Item)
	
	UpdateCostShares(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWriteOff

&AtClient
Procedure WriteOffSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return; // In the UT, the handler is empty.
	
EndProcedure

&AtClient
Procedure WriteOffExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WriteOffExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WriteOffOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.WriteOff.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.WriteOff");
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Procedure WriteOffOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		UpdateCostShares(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteOffAfterDeleteRow(Item)
	
	UpdateCostShares(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure ExpandReleasesWithoutReferences(Command)
	
	ExpandReleasesWithoutReferences = Not ExpandReleasesWithoutReferences;
	Items.IssuesWithoutOrdersExpandByOrders.Check = ExpandReleasesWithoutReferences;
	CollapseExpandTS(ExpandReleasesWithoutReferences);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItem(Command)
	
	If Items.GroupPages.CurrentPage		= Items.ByDepartmentsManually Then
		TabPart = Object.ByInfobase;
		SelectedRows = Items.Departments.SelectedRows;
	ElsIf Items.GroupPages.CurrentPage	= Items.ForIssuesWithoutOrders Then
		TabPart = ProductionIssueWithoutReferences;
		SelectedRows = Items.ProductionIssueWithoutReferences.SelectedRows;
	ElsIf Items.GroupPages.CurrentPage	= Items.ByStagesManually Then
		TabPart = Object.Manually;
		SelectedRows = Items.ManualSteps.SelectedRows;
	ElsIf Items.GroupPages.CurrentPage	= Items.ByProductionBatches Then
		TabPart = Object.ProductionLots;
		SelectedRows = Items.ProductionLots.SelectedRows;
	EndIf;
	
	OpenForm("Catalog.ProductCostElements.ChoiceForm", , 
					ThisForm,,,, 
					New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, New Structure("SelectedRows, TabPart", SelectedRows, TabPart)),
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#Region BSP

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Pickup

&AtClient
Procedure OpenSelectionByStagesForm(NewProduction)
	
	If NewProduction Then
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Department",           Object.Department);
		FilterStructure1.Insert("LineOfBusiness", Object.LineOfBusiness);
		FilterStructure1.Insert("Organization",             Object.Organization);
		FilterStructure1.Insert("EnableRecyclingOnSide", True);
		
		FormParameters = New Structure;
		FormParameters.Insert("BeginOfPeriod",            BegOfMonth(Object.Date));
		FormParameters.Insert("PeriodEnding",         EndOfMonth(Object.Date));
		FormParameters.Insert("FilterStructure1",          FilterStructure1);
		
		Notification = New CallbackDescription("OpenBatchSelectionFormCompletion", ThisForm);
		
		OpenForm("CommonForm.SelectProductionLots",
			FormParameters,
			Items.ProductionLots,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
		

	EndIf;
	
EndProcedure

&AtClient
Procedure OpenBatchSelectionFormCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInSelection(Result, "ProductionLots");
	
EndProcedure

&AtServer
Procedure FillInSelection(AddressInStorage, TSName)
	
	CalculationResult1	= GetFromTempStorage(AddressInStorage);
	Modified	= True;
	ObjectTable = Object[TSName]; // FormDataCollection
	
	For Each SelectedString_ In CalculationResult1 Do
		
		LineOfATabularSection = ObjectTable.Add();
		FillPropertyValues(LineOfATabularSection, SelectedString_);
		
		If ValueIsFilled(Object.ProductCostElement) Then
			LineOfATabularSection.ProductCostElement = Object.ProductCostElement;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DetailsChangeHandlers

&AtClient
Procedure ProcessChangeDistributeItInBatches()
	
	If Not Object.AllocateByLots Then
		ClearDependentProps("AllocateByLots");
	Else
		CustomizeFieldDesign(ThisForm);
	EndIf;
	
	SetItemsAvailability(ThisForm, "AllocateByLots");
	
EndProcedure

&AtClient
Procedure ProcessBatchChangeSpecifiedManually()
	
	ClearDependentProps("LotsAreSpecifiedManually");
	
	SetPageVisibility(ThisForm, "LotsAreSpecifiedManually");
	SetItemsVisibility(ThisForm, "LotsAreSpecifiedManually");
	EstablishAvailabilityOfShareOfCostOfProduction(ThisForm);
	CustomizeFieldDesign(ThisForm);
	ConfigureFieldHeaders(ThisForm, "LotsAreSpecifiedManually");
	
EndProcedure

&AtClient
Procedure ProcessChangeUseDivisionAllocation()

	Object.AllocateToBusinessUnits = Not IsBlankString(UseAllocationByDepartments);
	If Not Object.AllocateToBusinessUnits Then
		ClearDependentProps("UseAllocationByDepartments");
	EndIf;
	
	SetItemsAvailability(ThisForm, "UseAllocationByDepartments");
	CustomizeFieldDesign(ThisForm);
		
EndProcedure

&AtClient
Procedure ProcessChangeDistributeToArticles()
	
	If Not Object.AllocateToExpenseItems Then
		ClearDependentProps("AllocateToExpenseItems");
	EndIf;
	
	SetItemsAvailability(ThisForm, "AllocateToExpenseItems");
	EstablishAvailabilityOfShareOfCostOfProduction(ThisForm);
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtClient
Procedure HandleChangeOfDistributionDirection()
	
	ClearDependentProps("AllocationDirection");
	
	If (Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit")
		Or Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Superior"))
		And Object.AllocateToBusinessUnits Then
		
		UseAllocationByDepartments = "";
		ProcessChangeUseDivisionAllocation();
		
	EndIf;
	
	SetPageVisibility(ThisForm, "AllocationDirection");
	SetItemsAvailability(ThisForm, "AllocationDirection");
	SetItemsVisibility(ThisForm, "AllocationDirection");
	
EndProcedure

&AtClient
Procedure ProcessChangeInDistributionBaseByBatch()
	
	If Not NameOfDistributionBaseSchema(CacheBaseOfAllocationByBatches) = 
		NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots) Then
		ClearDependentProps("BaseOfAllocationByLots");
	EndIf;
	
	CacheBaseOfAllocationByBatches = Object.BaseOfAllocationByLots;
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtServer
Procedure ProcessChangesToDistributionDatabaseSettingsByBatch()

		Object.SettingsOfBaseOfAllocationByLotsChanged = FilterIs_Specified(
			SettingsOfBaseOfAllocationByLots);

	Modified = Max(Modified, Object.SettingsOfBaseOfAllocationByLotsChanged);
	ConfigureFieldHeaders(ThisForm, "SelectionOfDistributionBaseByParty");

EndProcedure

&AtServer
Procedure HandleChangesToDistributionDirectionSettings()
	
		Object.AllocationDirectionSettingsChanged = FilterIs_Specified(
			AllocationDirectionSettings);

	Modified = Max(Modified, Object.AllocationDirectionSettingsChanged);
	ConfigureFieldHeaders(ThisForm, "SelectionOfDistributionDirection");

EndProcedure


&AtClient
Procedure HandleChangingDistributionMethod()
	
	Object.BusinessUnitsAreSpecifiedManually = MethodOfDivisionDistribution = "Manually";
	
	ClearDependentProps("MethodOfDivisionDistribution");		
	
	SetItemsVisibility(ThisForm, "MethodOfDivisionDistribution");
	SetPageVisibility(ThisForm, "MethodOfDivisionDistribution");
	CustomizeFieldDesign(ThisForm);
		
EndProcedure

#EndRegion

#Region BSP

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

#EndRegion

#Region FormControl

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WriteOffLineOfBusiness.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPageVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Or AttributeName = "MethodOfDivisionDistribution" Then
		Items.ByDepartmentsManually.Visible = 
			Form.MethodOfDivisionDistribution = "Manually";
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "LotsAreSpecifiedManually" Then
		
		Items.ByStagesManually.Visible = Object.LotsAreSpecifiedManually
			And (Form.UnavailableItems.FindByValue("ByStagesManually") = Undefined);
		Items.ByProductionBatches.Visible = Object.LotsAreSpecifiedManually
			And (Form.UnavailableItems.FindByValue("ByProductionBatches") = Undefined);			
		Items.ForIssuesWithoutOrders.Visible = Object.LotsAreSpecifiedManually
			And (Form.UnavailableItems.FindByValue("ForIssuesWithoutOrders") = Undefined);
		Items.DescriptionOfTheRuleForProductionCosts.Visible = Not Object.LotsAreSpecifiedManually;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.GroupExpenseByItem.Visible = Not Form.CostAllocationFromCostCenter;
	Items.LineOfBusiness.Visible = Not Form.CostAllocationFromCostCenter;
	Items.GroupHIAExpense.Visible = Form.CostAllocationFromCostCenter;
	Items.FieldOfActivityOfHIA.Visible = Form.CostAllocationFromCostCenter;
	
	If AttributeName = "MethodOfDivisionDistribution" Or AttributeName = Undefined Then
		
		Items.Factor.Visible = Form.MethodOfDivisionDistribution = "ByIndicator";
		Items.ProductCostElement.Visible = Not Object.BusinessUnitsAreSpecifiedManually;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Or AttributeName = "AllocateByLots" Then
		
		Items.DescriptionOfTheRuleForProductionCosts.Enabled = Object.AllocateByLots;
		Items.LotsAreSpecifiedManually.Enabled = Object.AllocateByLots;
		
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "UseAllocationByDepartments" Then
		Items.MethodOfDivisionDistribution.ReadOnly = 
			Not Object.AllocateToBusinessUnits;
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "AllocationDirection" Then
		
		Items.UseAllocationByDepartments.ReadOnly = 
			Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit")
			Or Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Superior");
		
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "AllocateToExpenseItems" Then
		Items.ToOtherItems.Enabled = Object.AllocateToExpenseItems;
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "LeaveAsWIP" Then
		Items.CostShareOfWIP.Enabled = Object.LeaveAsWIP;
	EndIf;
	
	EstablishAvailabilityOfShareOfCostOfProduction(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfShareOfCostOfProduction(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Object.AllocateByLots 
		And (Object.AllocateToExpenseItems Or Object.LeaveAsWIP)
		And Not (Form.MethodOfDivisionDistribution = "Manually" Or Object.LotsAreSpecifiedManually) Then
		Items.CostShareForProduction.ReadOnly = False;
	Else
		Items.CostShareForProduction.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfAccountingTypes()
	
	Documents.AllocationOfOtherCosts.SetAvailabilityOfAccountingTypes(ThisForm);
	
EndProcedure

&AtServer
Procedure SynchronizeTypesOfAccountingBUAndTa(AccountingKind)
	
	Documents.AllocationOfOtherCosts.SynchronizeTypesOfAccountingBUAndTa(ThisForm, AccountingKind);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeFieldDesign(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.BaseOfAllocationByLots.MarkIncomplete = Object.AllocateByLots 
		And Not ValueIsFilled(Object.BaseOfAllocationByLots);
		
	Items.MethodOfDivisionDistribution.MarkIncomplete = Object.AllocateToBusinessUnits 
		And Not ValueIsFilled(Form.MethodOfDivisionDistribution);
				
	Items.CostShareForProduction.MarkIncomplete = Not Items.CostShareForProduction.ReadOnly
		And Not ValueIsFilled(Object.CostShareForProduction);
		
	Items.CostShareOfWIP.MarkIncomplete = Not Items.CostShareOfWIP.ReadOnly
		And Not ValueIsFilled(Object.CostShareOfWIP);
		
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFieldHeaders(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = "LotsAreSpecifiedManually" Or AttributeName = Undefined Then
		
		If Object.LotsAreSpecifiedManually Then
			Items.BaseOfAllocationByLots.Title = NStr("vi = 'Giữa xuất xưởng và SXDD';
														|ru = 'Между выпуском и НЗП';
														|en = 'Between release and WIP'; fa = 'Between release and WIP';
														|it = 'Tra emissione e Produzione Incompleta (lavori/prodotti in corso di fabbricazione)';
														|pl = 'Między produkcją a produkcją niezakończoną';
														|tr = 'Ürün çıkışı ve devam eden imalat arasında'");
		Else
			Items.BaseOfAllocationByLots.Title = NStr("vi = 'Giữa các lô theo cơ sở';
														|ru = 'Между партиями по базе';
														|en = 'Between lots by base'; fa = 'بین بچ‌ها بر اساس مبنا';
														|it = 'Tra lotti per base';
														|pl = 'Między partiami według bazy';
														|tr = 'Tabana göre lotlar arasında'");
		EndIf;
		
	EndIf;
	
	PresentationOfHyperlinks = New Map();
	PresentationOfHyperlinks.Insert(True, NStr("vi = 'Đã đặt bộ lọc, thay đổi';
												|ru = 'Отбор установлен, изменить';
												|en = 'Filter is set, change'; fa = 'Filter is set, change';
												|it = 'Selezione impostata, modificare';
												|pl = 'Ustawiono filtr, zmień';
												|tr = 'Filtre ayarlandı, değiştir'"));
	PresentationOfHyperlinks.Insert(False, NStr("vi = 'Chưa đặt lọc, thêm';
												|ru = 'Отбор не установлен, добавить';
												|en = 'Filter not set, add'; fa = 'Filter not set, add';
												|it = 'La selezione non è impostata, aggiungere';
												|pl = 'Nie ustawiono filtru, dodaj';
												|tr = 'Filtre ayarlanmadı, ekle'"));
	
	If AttributeName = "SelectionOfDistributionDirection" 
		Or AttributeName = Undefined Then
		If Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Specified") Then
			Form.TextAddEditSelectionDistributionDirection = 
				PresentationOfHyperlinks.Get(Object.AllocationDirectionSettingsChanged);
		Else
			Form.TextAddEditSelectionDistributionDirection = "";
		EndIf;

	EndIf;
	
	If AttributeName = "SelectionOfDistributionBaseByParty" 
		Or AttributeName = Undefined Then
		
			Form.TextAddEditSelectionOfTheBatchDistributionDatabase = 
				PresentationOfHyperlinks.Get(Object.SettingsOfBaseOfAllocationByLotsChanged);
		
	EndIf;
		
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByFO(Var_AttributeName = Undefined)
	
	If Var_AttributeName = "GroupLeaveGNZP"
		Or Var_AttributeName = Undefined Then
		Items.GroupLeaveGNZP.Visible = 
			(UnavailableItems.FindByValue("GroupLeaveGNZP") = Undefined);
	EndIf;
	
	
EndProcedure


#EndRegion

#Region InitializeForm

&AtServer
Procedure OnReadCreateAtServer()
	
	Items.ForAllAreasOfActivity.Visible = ValueIsFilled(Object.LineOfBusiness);

	CostAllocationFromCostCenter = Not ValueIsFilled(Object.ExpenseItem);
	
	DetermineVisibilityAndAmountOfExpensesForArticle();
	
	FillInServiceDetailsOfForm();
	
	SetPageVisibility(ThisForm);
	SetVisibilityOfElementsByFO();
	SetItemsVisibility(ThisForm);
	SetItemsAvailability(ThisForm);
	CustomizeFieldDesign(ThisForm);
	ConfigureFieldHeaders(ThisForm);
	SetAvailabilityOfAccountingTypes();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	SetFormHeader();
		
	If Object.BusinessUnitsAreSpecifiedManually Then
		MethodOfDivisionDistribution = "Manually";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis
		Or Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand Then
		MethodOfDivisionDistribution = "ByIndicator";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount Then
		MethodOfDivisionDistribution = "MaterialCostsAmount";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses Then
		MethodOfDivisionDistribution = "TotalPayrollExpenses";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts Then
		MethodOfDivisionDistribution = "AmountOfMaterialAndLaborCosts";
	EndIf;
	
	If Object.AllocateToBusinessUnits Then
		UseAllocationByDepartments = "UseDifferentBases";
	EndIf;
	
	ForAllAreasOfActivity = Object.ToAnyLinesOfBusiness;
	CostSharesAmountInclReleasesWithoutOrders = ProductionIssueWithoutReferences.Total("CostShare");
	FillInServiceDetailsOfTS();
	
	CacheBaseOfAllocationByBatches = Object.BaseOfAllocationByLots;
	LoadBasicComposerSettings();
	
	ComposerSettings = Undefined;
	If Parameters.Property("Basis") And TypeOf(Parameters.Basis) = Type("Structure")
		And Parameters.Basis.Property("SettingsOfBaseOfAllocationByLots", ComposerSettings)
		And Not ComposerSettings = Undefined Then
		SettingsOfBaseOfAllocationByLots.LoadSettings(ComposerSettings);
	EndIf;
	
	ComposerSettings = Undefined;
	If Parameters.Property("Basis") And TypeOf(Parameters.Basis) = Type("Structure")
		And Parameters.Basis.Property("AllocationDirectionSettings", ComposerSettings)
		And Not ComposerSettings = Undefined Then
		AllocationDirectionSettings.LoadSettings(ComposerSettings);
	EndIf;
		
	
	DocumentObject = FormAttributeToValue("Object");
	RestoreComposerSettings("SettingsOfBaseOfAllocationByLots", DocumentObject);
	RestoreComposerSettings("AllocationDirectionSettings", DocumentObject);
	
	UnavailableItems = UnavailableElementsByFederalDistrict(Object.Date);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()
	
	CostsServer.FillInCharacteristicsOfProductsByBatchOfProduction(Object.ProductionLots);
	
	FillInServiceDetailsForProductRange("ProductionIssueWithoutReferences");
	CollapseExpandTS(ExpandReleasesWithoutReferences);
	
EndProcedure

&AtClient
Procedure UpdateCaptionPeriod()

	LabelPeriod = PeriodPresentation(BegOfMonth(Object.Date), EndOfMonth(Object.Date), "DLF=D");
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	ObjectPresentation = Metadata.Documents.AllocationOfOtherCosts.Synonym;
	ObjectPresentationClarification = NStr("vi = 'giữa các lô sản xuất';
											|ru = 'между партиями производства';
											|en = 'between production lots'; fa = 'between production lots';
											|it = 'tra i lotti della produzione';
											|pl = 'między partiami produkcyjnymi';
											|tr = 'üretim lotları arasında'");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		TitleTemplate1 = NStr("vi = '%1 %2 (tạo)';
								|ru = '%1 %2 (создание)';
								|en = '%1 %2 (generation)'; fa = '%1 %2 (generation)';
								|it = '%1 %2 (сreazione)';
								|pl = '%1 %2 (tworzenie)';
								|tr = '%1 %2 (oluşturma)'");
		Title = StrTemplate(TitleTemplate1, ObjectPresentation, ObjectPresentationClarification);
		
	Else
		
		TitleTemplate1 = NStr("vi = '%1 %2 số %3 ngày %4';
								|ru = '%1 %2 №%3 от %4';
								|en = '%1 %2 No.%3 dated %4'; fa = '%1 %2 No.%3 dated %4';
								|it = '%1 %2 n.%3 del %4';
								|pl = '%1 %2 Nr%3 od %4';
								|tr = '%4 itibarıyla %3 numaralı %2 %1'");
		Title = StrTemplate(TitleTemplate1, ObjectPresentation, 
								ObjectPresentationClarification,
								Object.Number,
								Format(Object.Date, "DLF=DT"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Filters


&AtServer
Procedure LoadBasicComposerSettings(Var_AttributeName = "")
	
	If Var_AttributeName = "AllocationDirectionSettings" 
		Or Var_AttributeName = "" Then
		
		CompositionSchema = Catalogs.CostAllocationRules.GetTemplate("AllocationDirection");
		AllocationDirectionSettings.LoadSettings(CompositionSchema.DefaultSettings);
	
	EndIf;
	
	If Var_AttributeName = "SettingsOfBaseOfAllocationByLots" 
		Or Var_AttributeName = "" Then
		
		SchemaName = Enums.TypesOfCostAllocatingBase.NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots);
		
		If Not IsBlankString(SchemaName) Then
			
			CompositionSchema = Enums.TypesOfCostAllocatingBase.GetTemplate(SchemaName);
			SettingsOfBaseOfAllocationByLots.LoadSettings(CompositionSchema.DefaultSettings);
			
		EndIf;
	
	EndIf;
	
	
EndProcedure

&AtServer
Procedure RestoreComposerSettings(PropsNameWithSettings, DocObject = Undefined)
	
	SettingsModifier = StrTemplate("%1Changed", PropsNameWithSettings);
	If Not Object[SettingsModifier] Then
		Return;
	EndIf;
	
	If DocObject = Undefined Then
		DocObject = FormAttributeToValue("Object");
	EndIf;

	AttributesWithComposerSettings = DocObject[PropsNameWithSettings]; // ValueStorage
	ComposerSettings = AttributesWithComposerSettings.Get();
	If Not ComposerSettings = Undefined Then
		ThisForm[PropsNameWithSettings].LoadSettings(ComposerSettings);
	EndIf;

EndProcedure

&AtClient
Function ParametersForOpeningSelectionSettings()
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("SchemaName", "");
	OpeningParameters.Insert("NameOfComposerSettings", "");
	OpeningParameters.Insert("DoNotConfigureSettings", True);
	
	Return OpeningParameters;
	
EndFunction

// Opens the selection settings form.
// Parameters:
//	OpeningParameters - Structure - Description of the structure in the parametersoptionsadjustmentsreferences
&AtClient
Procedure OpenSelectionSettingsForm(OpeningParameters, FormCaption = "")

	Addresses = GetAddressesOfDataLayoutSchemeInTemporaryStorage(OpeningParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", True);
	FormParameters.Insert("DoNotConfigureSettings", OpeningParameters.DoNotConfigureSettings);
	FormParameters.Insert("NotEditDataCompositionSchema", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormParameters.Insert("Title", FormCaption);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("EditDataCompositionSchemaCompletion",
			ThisObject,
			OpeningParameters),
		FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtServer
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(Var_Parameters)
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings");
	If Var_Parameters.SchemaName = "AllocationDirection" Then
		Schema = Catalogs.CostAllocationRules.GetTemplate(Var_Parameters.SchemaName);
	Else
		Schema = Enums.TypesOfCostAllocatingBase.GetTemplate(Var_Parameters.SchemaName);
	EndIf;
	
	If Not GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
		
		ProductGroupField = Schema.DataSets[0].Fields.Find("ProductsGroup"); // DataCompositionSchemaDataSetField
		If Not ProductGroupField = Undefined Then
			
			ProductGroupField.UseRestriction.Condition = True;
			ProductGroupField.AttributeUseRestriction.Condition = True;
			
		EndIf;
		
	EndIf;

	Addresses.DataCompositionSchema = PutToTempStorage(Schema, UUID);
	
	Settings = ThisForm[Var_Parameters.NameOfComposerSettings].GetSettings();
	If ValueIsFilled(Settings) Then
		Addresses.DataCompositionSettings = PutToTempStorage(Settings, UUID);
	EndIf;
	
	Return Addresses;
	
EndFunction

&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export

	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ThisForm[AdditionalParameters.NameOfComposerSettings].LoadSettings(
		GetFromTempStorage(Result));
	
	ProcessChangesToBankingDetails(AdditionalParameters.NameOfComposerSettings);

EndProcedure

&AtServerNoContext
Function FilterIs_Specified(NewSettings1)
	
	FilterIs_Specified = False;
	ComposerSettings = NewSettings1.GetSettings();
	For Each FilterElement In ComposerSettings.Filter.Items Do
		If FilterElement.Use Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
	EndDo;
	
	If FilterIs_Specified Then
		Return FilterIs_Specified;
	EndIf;
	
	For Each DataParameter In ComposerSettings.DataParameters.Items Do
		If DataParameter.Value Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
	EndDo;
	
	Return FilterIs_Specified;
	
EndFunction

#EndRegion

#Region UserInteraction

&AtClient
Procedure SpecifyChangingBankingDetails(Var_AttributeName, NeedToAskQuestion = False)
	
	If Not NeedToAskQuestion Then
		
		// The parameter is not passed. So you need to determine whether you need to ask a question or not.
		
		StructureOfDependentProps = DependentDetails(Var_AttributeName);
		
		For Each FormAttribute In StructureOfDependentProps.FormAttributes Do
			
			If TypeOf(ThisForm[FormAttribute]) = Type("Boolean") And ThisForm[FormAttribute] = True
				Or Not TypeOf(ThisForm[FormAttribute]) = Type("Boolean") And ValueIsFilled(ThisForm[FormAttribute]) Then
				
				NeedToAskQuestion = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If Not NeedToAskQuestion Then
			For Each ObjectAttribute In StructureOfDependentProps.ObjectAttributes Do
				
				If TypeOf(Object[ObjectAttribute]) = Type("Boolean") And Object[ObjectAttribute] = True
					Or Not TypeOf(Object[ObjectAttribute]) = Type("Boolean") And ValueIsFilled(Object[ObjectAttribute]) Then
					
					NeedToAskQuestion = True;
					Break;
					
				EndIf;
				
			EndDo;
		EndIf;
				
	EndIf;
	
	If NeedToAskQuestion Then
		
		If Var_AttributeName = "AllocateToBusinessUnits" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ theo bộ phận sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения по подразделениям будут очищены. Продолжить?';
							|en = 'Settings of allocation to business units will be cleared. Continue?'; fa = 'Settings of allocation to business units will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione per reparto verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia według działów zostaną wyczyszczone. Kontynuować?';
							|tr = 'Departman göre dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		ElsIf Var_AttributeName = "AllocateByLots" Or Var_AttributeName = "LotsAreSpecifiedManually" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения будут очищены. Продолжить?';
							|en = 'Allocation settings will be cleared. Continue?'; fa = 'Allocation settings will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia zostaną wyczyszczone. Kontynuować?';
							|tr = 'Dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		ElsIf Var_AttributeName = "AllocateToExpenseItems" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ cho các dạng khác sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения на другие статьи будут очищены. Продолжить?';
							|en = 'Settings of allocation to other items will be cleared. Continue?'; fa = 'Settings of allocation to other items will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione su altri articoli verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia na inne pozycje zostaną wyczyszczone. Kontynuować?';
							|tr = 'Diğer kalemlere dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		EndIf;
		
		NotificationParameters = New Structure("AttributeName", Var_AttributeName);
		
		ShowQueryBox(New CallbackDescription("SpecifyChangingBankingDetailsCompletion", ThisForm, NotificationParameters),
						QueryText,
						QuestionDialogMode.YesNo);
						
		Return;
		
	EndIf;
		
	ProcessChangesToBankingDetails(Var_AttributeName);
	
EndProcedure

&AtClient
Procedure SpecifyChangingBankingDetailsCompletion(QuestionResult, AdditionalParameters) Export
	
	AttributeName = AdditionalParameters.AttributeName;
	
	If QuestionResult = DialogReturnCode.Yes Then
		ProcessChangesToBankingDetails(AttributeName);
	Else
		If AttributeName = "AllocateByLots"
			Or AttributeName = "AllocateToExpenseItems"
			Or AttributeName = "LotsAreSpecifiedManually" Then
			Object[AttributeName] = Not Object[AttributeName];
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithDatabaseTypes

&AtClientAtServerNoContext
Function NameOfDistributionBaseSchema(AllocationBase)
	
	DistributionBasesByGroups = DistributionBasesByGroups();
	
	If Not DistributionBasesByGroups.UsedMaterials.Find(AllocationBase) = Undefined Then
		Return "MaterialCosts";
	ElsIf Not DistributionBasesByGroups.LaborCosts.Find(AllocationBase) = Undefined Then
		Return "LaborCosts";
	ElsIf Not DistributionBasesByGroups.ManufacturedProduct.Find(AllocationBase) = Undefined Then
		Return "ManufacturedProduct";
	ElsIf Not DistributionBasesByGroups.MaterialAndLaborCosts.Find(AllocationBase) = Undefined Then
		Return "MaterialAndLaborCosts";
	EndIf;
	
	Return "";
	
EndFunction

&AtClientAtServerNoContext
Function DistributionBasesByGroups()
	
	UsedMaterials = New Array;
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.MaterialCostsAmount"));
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials"));
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials"));
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials"));
	
	LaborCosts = New Array;
	LaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses"));
	LaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel"));
	LaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds"));
	
	ManufacturedProduct = New Array;
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCost"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantity"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeight"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolume"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases"));
	ManufacturedProduct.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases"));

	MaterialAndLaborCosts = New Array;
	MaterialAndLaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts"));
	
	DatabaseGroups = New Structure;
	DatabaseGroups.Insert("UsedMaterials", UsedMaterials);
	DatabaseGroups.Insert("LaborCosts", LaborCosts);
	DatabaseGroups.Insert("ManufacturedProduct", ManufacturedProduct);
	DatabaseGroups.Insert("MaterialAndLaborCosts", MaterialAndLaborCosts);
	
	Return DatabaseGroups;
	
EndFunction

#EndRegion

#Region ControlOfChangesInBankingDetails

&AtClient
Procedure ProcessChangesToBankingDetails(Var_AttributeName)
	
	If Var_AttributeName = "UseAllocationByDepartments" Then
		ProcessChangeUseDivisionAllocation();
	ElsIf Var_AttributeName = "AllocateByLots" Then
		ProcessChangeDistributeItInBatches();
	ElsIf Var_AttributeName = "LotsAreSpecifiedManually" Then
		ProcessBatchChangeSpecifiedManually();
	ElsIf Var_AttributeName = "AllocateToExpenseItems" Then
		ProcessChangeDistributeToArticles();
	ElsIf Var_AttributeName = "AllocationDirection" Then
		HandleChangeOfDistributionDirection();
	ElsIf Var_AttributeName = "MethodOfDivisionDistribution" Then
		HandleChangingDistributionMethod();
	ElsIf Var_AttributeName = "SettingsOfBaseOfAllocationByLots" Then
		ProcessChangesToDistributionDatabaseSettingsByBatch();
	ElsIf Var_AttributeName = "AllocationDirectionSettings" Then
		HandleChangesToDistributionDirectionSettings();
	EndIf;
	
EndProcedure

&AtClient
Function ClearDependentProps(Var_AttributeName)
	
	StructureOfDependentProps = DependentDetails(Var_AttributeName);
	
	For Each FormAttribute In StructureOfDependentProps.FormAttributes Do
		
		If TypeOf(ThisForm[FormAttribute]) = Type("FormDataCollection") Then
			ThisForm[FormAttribute].Clear();
		ElsIf TypeOf(ThisForm[FormAttribute]) = Type("DataCompositionSettingsComposer") Then
			LoadBasicComposerSettings(FormAttribute);
		Else
			ThisForm[FormAttribute] = Undefined;
		EndIf;
		
		ProcessChangesToBankingDetails(FormAttribute);
		
	EndDo;
	
	For Each ObjectAttribute In StructureOfDependentProps.ObjectAttributes Do
		
		If TypeOf(Object[ObjectAttribute]) = Type("FormDataCollection") Then
			Object[ObjectAttribute].Clear();
		Else
			Object[ObjectAttribute] = Undefined;
		EndIf;
		
		ProcessChangesToBankingDetails(ObjectAttribute);
		
	EndDo;
	
	Return StructureOfDependentProps;
	
EndFunction

&AtClient
Function DependentDetails(Attribute)
	
	FormAttributes = New Array;
	ObjectAttributes = New Array;
	
	If Attribute = "AllocationDirection" Then
		
		FormAttributes.Add("AllocationDirectionSettings");
		
	ElsIf Attribute = "LotsAreSpecifiedManually" Then
		
		ObjectAttributes.Add("BaseOfAllocationByLots");
		ObjectAttributes.Add("AllocationDirection");
		ObjectAttributes.Add("ProductionLots");
		FormAttributes.Add("UseAllocationByDepartments");
		FormAttributes.Add("ForAllAreasOfActivity");
		
	ElsIf Attribute = "BaseOfAllocationByLots" Then
		
		FormAttributes.Add("SettingsOfBaseOfAllocationByLots");
			
	ElsIf Attribute = "AllocateByLots" Then
		
		ObjectAttributes.Add("LotsAreSpecifiedManually");
		ObjectAttributes.Add("ProductCostElement");
		ObjectAttributes.Add("ProductionLots");
		
	ElsIf Attribute = "AllocateToExpenseItems" Then
		
		If Not (Object.AllocateToExpenseItems Or Object.BusinessUnitsAreSpecifiedManually) Then
			ObjectAttributes.Add("CostShareForProduction");
		EndIf;
		
		ObjectAttributes.Add("WriteOff");
		ObjectAttributes.Add("CostShareToExpenseItems");
		
	ElsIf Attribute = "UseAllocationByDepartments" Then
		
		ObjectAttributes.Add("AllocateToBusinessUnits");
		FormAttributes.Add("MethodOfDivisionDistribution");
		
	ElsIf Attribute = "MethodOfDivisionDistribution" Then
		
		ObjectAttributes.Add("Factor");
		ObjectAttributes.Add("ByInfobase");
		ObjectAttributes.Add("CostShareForProduction");
				
	EndIf;
	
	Return New Structure("FormAttributes, ObjectAttributes", FormAttributes, ObjectAttributes);
		
EndFunction

#EndRegion

#Region Other

&AtServerNoContext
Function UnavailableElementsByFederalDistrict(Period)
	
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22(Period);
	
	UnavailableItems = New ValueList;
		
	ByStagesManually = UnavailableItems.Add("ByStagesManually");
	If Not ProductionSettings.ProductionIsUsed21 Then
		UnavailableItems.Add("ForIssuesWithoutOrders");
	Else
		UnavailableItems.Delete(ByStagesManually);
	EndIf;
		
	If Not ProductionSettings.ProductionIsUsed22
		And Not (BatchAccountingVersion22
			And ProductionSettings.ProductionIsUsed21
			And ProductionSettings.ProductionByThirdPartyIsUsed2_5)
		Then
		UnavailableItems.Add("ByProductionBatches");
	EndIf;
	
	If Not BatchAccountingVersion22 Then
		UnavailableItems.Add("GroupLeaveGNZP");
	EndIf;
	
	Return UnavailableItems;
	
EndFunction

&AtServer
Procedure CheckFillingOfTabularPartOfIssueWithoutOrdering(Cancel)
	
	CheckedAttributes = New ValueList;
	CheckedAttributes.Add("CostShare", NStr("vi = 'Tỷ lệ giá trị';
											|ru = 'Доля стоимости';
											|en = 'Cost share'; fa = 'سهم بها';
											|it = 'Quota del costo';
											|pl = 'Udział kosztów';
											|tr = 'Maliyet payı'"));
	CheckedAttributes.Add("ProductCostElement", NStr("vi = 'Dạng tính giá thành';
													|ru = 'Статья калькуляции';
													|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
													|it = 'Voce di calcolo';
													|pl = 'Rodzaj kosztu';
													|tr = 'Ürün maliyet kalemi'"));
	
	MessageTemplate = NStr("vi = 'Chưa điền trường %1 trong dòng %2 của danh sách ""Xuất xưởng không có lệnh""';
							|ru = 'Не заполнено поле %1 в строке %2 списка ""На выпуски без распоряжений""';
							|en = '%1 is required in line %2 of the ""To releases without references"" list'; fa = '%1 is required in line %2 of the ""To releases without references"" list';
							|it = 'Non è stato compilato il campo %1 nella riga %2 dell''elenco ""Per produzioni senza disposizioni""';
							|pl = 'Nie wypełniono pole %1 w wierszu %2 listy ""Do produkcji bez zamówień""';
							|tr = '""Talimatsız Ürün Çıkışı"" listesinin %2 satırındaki %1 alanı doldurulmadı'");
	MessageTemplateWithoutNumber = NStr("vi = 'Chưa điền trường %1 của danh sách ""Xuất xưởng không có lệnh""';
										|ru = 'Не заполнено поле %1 в списке ""На выпуски без распоряжений""';
										|en = '%1 is required in the ""To releases without references"" list'; fa = '%1 is required in the ""To releases without references"" list';
										|it = 'Non è stato compilato il campo %1 nell''elenco ""Per produzioni senza disposizioni""';
										|pl = 'Nie wypełniono pole %1 listy ""Do produkcji bez zamówień""';
										|tr = '""Talimatsız Ürün Çıkışı"" listesinde %1 alanı doldurulmadı'");
	
	For Each String In Object.ProductionIssueWithoutReferences Do
		
		For Each Attribute In CheckedAttributes Do
			
			If Not ValueIsFilled(String[Attribute.Value]) Then
				
				If ExpandReleasesWithoutReferences Then
					FilterStructure1 = New Structure("DocumentOfProductionIssue, RowCode");
				Else
					FilterStructure1 = New Structure("Products, Characteristic, Purpose, Series");
				EndIf;
				
				FillPropertyValues(FilterStructure1, String);
				FoundRows = ProductionIssueWithoutReferences.FindRows(FilterStructure1);
				
				If FoundRows.Count() > 0 Then
					
					MessageLineNumber = FoundRows[0].LineNumber;
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
						Attribute.Presentation,
						MessageLineNumber);
					
					CommonClientServer.MessageToUser(
						MessageText,
						,
						CommonClientServer.PathToTabularSection("ProductionIssueWithoutReferences", MessageLineNumber, Attribute.Value),
						,
						Cancel);
					
				Else
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplateWithoutNumber,
						Attribute.Presentation);
						
					CommonClientServer.MessageToUser(
						MessageText,
						,
						"ProductionIssueWithoutReferences",
						,
						Cancel);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateCostShares(Form)
	
	Object = Form.Object;
	
	If Object.BusinessUnitsAreSpecifiedManually Or Object.LotsAreSpecifiedManually Then
		
		Object.CostShareForProduction = Object.Manually.Total("CostShare")
			+ Object.ProductionLots.Total("CostShare")
			+ Form.ProductionIssueWithoutReferences.Total("CostShare")
			+ Object.ByInfobase.Total("CostShare");
		
	EndIf;
		
	Object.CostShareToExpenseItems = Object.WriteOff.Total("CostShare");
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(ValueSelected)
	
	ExpandReleasesWithoutReferences = ValueSelected.ExpandReleasesWithoutReferences;
	
	StructureOfData = GetFromTempStorage(ValueSelected.AddressInStorage);
	TheStructureOfTheSearch = New Structure("Products, Characteristic, DocumentOfProductionIssue, RowCode");
	
	For Each DataElement In StructureOfData.Goods Do
		
		FillPropertyValues(TheStructureOfTheSearch, DataElement);
		StringsTSGoods = Object.ProductionIssueWithoutReferences.FindRows(TheStructureOfTheSearch);
		If StringsTSGoods.Count() = 0 Then
			
			TSRow = Object.ProductionIssueWithoutReferences.Add();
			
		ElsIf StringsTSGoods.Count() = 1 Then
			
			TSRow = StringsTSGoods[0];
			
		Else
			
			For Each RowOfGoods In StringsTSGoods Do
				Object.ProductionIssueWithoutReferences.Delete(RowOfGoods);
			EndDo;
			
			TSRow = Object.ProductionIssueWithoutReferences.Add();
			
		EndIf;
		
		FillPropertyValues(TSRow, DataElement);
		Modified = True;
		
	EndDo;
	
	CollapseExpandTS(ExpandReleasesWithoutReferences);
	
EndProcedure

&AtServer
Procedure CollapseExpandTS(Expand = False)
	
	If Not Expand Then
		
		GroupingColumns = "Products, Characteristic, ProductCostElement, Series, Package, Purpose";
		TotalingColumns = "NumberOfPackages, Count, CostShare";
		
		ValueTable = Object.ProductionIssueWithoutReferences.Unload(,GroupingColumns + ", " + TotalingColumns); // ValueTable
		ValueTable.GroupBy(GroupingColumns, TotalingColumns);
		
		ProductionIssueWithoutReferences.Load(ValueTable);
		
		FilterStructure1 = New Structure(GroupingColumns);
		TemplateOfPresentation = NStr("vi = 'Tổng chứng từ: %1';
										|ru = 'Всего документов: %1';
										|en = 'Total documents: %1'; fa = 'Total documents: %1';
										|it = 'Totale documenti: %1';
										|pl = 'Razem dokumentów: %1';
										|tr = 'Toplam belgeler: %1'");
		
		For Each String In ProductionIssueWithoutReferences Do
			FillPropertyValues(FilterStructure1, String);
			FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
			String.SubmissionOfOrders = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateOfPresentation,
				FoundRows.Count());
			
		EndDo;
	Else
		ProductionIssueWithoutReferences.Load(Object.ProductionIssueWithoutReferences.Unload());
	EndIf;
	
	FillInServiceDetailsForProductRange("ProductionIssueWithoutReferences");
	CostSharesAmountInclReleasesWithoutOrders = ProductionIssueWithoutReferences.Total("CostShare");
	
	LineNumber = 1;
	For Each String In ProductionIssueWithoutReferences Do
		String.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange(TSName)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	If TSName = "ProductionIssueWithoutReferences" Then
		ProductsServer.FillInServiceDetailsForProductInCollection(ThisForm[TSName], ParametersForFillingInBankingDetails);
		ProductsServer.FillInServiceDetailsForProductInCollection(Object[TSName], ParametersForFillingInBankingDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure DistributeShareOfCost(Id)
	
	CurrentData = ProductionIssueWithoutReferences.FindByID(Id);
	
	FilterStructure1 = New Structure("Products, Characteristic, ProductCostElement, Series, Package, Purpose");
	FillPropertyValues(FilterStructure1, CurrentData);
	
	FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
	
	Coefficients = New Array;
	For Each String In FoundRows Do
		Coefficients.Add(String.NumberOfPackages);
	EndDo;
	
	AllocationResult = Common.DistributeAmountInProportionToCoefficients(CurrentData.CostShare, Coefficients);
	
	If AllocationResult = Undefined Then
		Return;
	EndIf;
	
	IndexOf = 0;
	For Each ZoomRatio In AllocationResult Do
		FoundRows[IndexOf].CostShare = ZoomRatio;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateObjectTable(TSName, Id)
	
	CurrentData = ThisForm[TSName].FindByID(Id);
	
	If ExpandReleasesWithoutReferences Then
		FilterStructure1 = New Structure("DocumentOfProductionIssue, RowCode");
		FillPropertyValues(FilterStructure1, CurrentData);
	Else
		If TSName = "ProductionIssueWithoutReferences" Then
			FilterStructure1 = New Structure("Products, Characteristic, Series, Purpose, ProductCostElement");
		EndIf;
		FillPropertyValues(FilterStructure1, SavedData);
	EndIf;
	
	FoundRows = Object[TSName].FindRows(FilterStructure1);
	
	If FoundRows.Count() > 0 Then
		FillPropertyValues(FoundRows[0], CurrentData, ,"DocumentOfProductionIssue,RowCode");
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveRowData(RowData)
	
	SavedData = New Structure("Products, Characteristic, ProductCostElement");
	FillPropertyValues(SavedData, RowData);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	TabPart = AdditionalParameters.TabPart;
	CalculationArticleToFillIn = Result;

	If Not ValueIsFilled(CalculationArticleToFillIn) Then
		Return;
	EndIf;

	For Each String In SelectedRows Do
		TableRow = TabPart.FindByID(String);
		If TableRow <> Undefined Then
			SaveRowData(TableRow);
			TableRow.ProductCostElement = CalculationArticleToFillIn;
			If TabPart = ProductionIssueWithoutReferences Then
				If ExpandReleasesWithoutReferences Then
					UpdateObjectTable("ProductionIssueWithoutReferences", TableRow.GetID());
				Else
					SetCalculationArticleByLine(TableRow.GetID());
				EndIf;
			EndIf;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure SetCalculationArticleByLine(Id)
	
	CurrentData = ProductionIssueWithoutReferences.FindByID(Id);
	
	FilterStructure1 = New Structure("Products, Characteristic");
	FillPropertyValues(FilterStructure1, CurrentData);
	FilterStructure1.Insert("ProductCostElement", SavedData.ProductCostElement);
	
	FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
	
	For Each String In FoundRows Do
		String.ProductCostElement = CurrentData.ProductCostElement;
	EndDo;
	
EndProcedure

&AtServer
Procedure DetermineVisibilityAndAmountOfExpensesForArticle()
	
	Query = New Query("
		|SELECT TOP 1
		|	*
		|FROM
		|	AccumulationRegister.RegisterRecordsProductsIncomeExpenses.Turnovers(
		|			&StartDate,
		|			&EndDate,
		|			,
		|			IncomeAndExpenseItem = &AssetRef
		|				AND DimensionOfExpenses = &Dimension) AS RegisterRecords");
	
	Query.SetParameter("AssetRef", Object.ExpenseItem);
	Query.SetParameter("Dimension", Object.DimensionOfExpenses);
	Query.SetParameter("StartDate", BegOfMonth(Object.Date));
	Query.SetParameter("EndDate", EndOfMonth(Object.Date));
	
	SetPrivilegedMode(True);
	
	ThereAreRevolutionsOnArticle = Not Query.Execute().IsEmpty();
	If Not ThereAreRevolutionsOnArticle Then
		Items.AmountsGroup.Visible = True;
		Items.GroupWithoutAmounts.Visible = False;
	Else
		Items.AmountsGroup.Visible = False;
		Items.GroupWithoutAmounts.Visible = True;
	EndIf;
	
	If ThereAreRevolutionsOnArticle Then
		Return;
	EndIf;
	
	SupportedDistributionOptions = New Array();
	SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
	SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	
	Query = New Query;
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextReceivedOtherExpenses() + "
		|SELECT
		|	T.Sum,
		|	T.SumCompl,
		|	T.CostTD
		|FROM
		|	ExpenseForAllocation AS T
		|WHERE
		|	T.ExpenseItem = &AssetRef
		|	AND T.DimensionOfExpenses = &Dimension
		|	AND T.LineOfBusiness = &LineOfBusiness";
	
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Object.Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Object.Date));
	Query.SetParameter("BorderEndOfPeriod", New Boundary(EndOfMonth(Object.Date), BoundaryType.Including));
	Query.SetParameter("CompanyArray", Object.Organization);
	Query.SetParameter("DepartmentList", Object.Department);
	Query.SetParameter("ByAllCompanies", False);
	Query.SetParameter("ByAllBusinessUnits", False);
	Query.SetParameter("AssetRef", Object.ExpenseItem);
	Query.SetParameter("Dimension", Object.DimensionOfExpenses);
	Query.SetParameter("LineOfBusiness", Object.LineOfBusiness);
	Query.SetParameter("CostAllocationOptions", SupportedDistributionOptions);
	
	Selection = Query.Execute().Select();
	
	TemplateOfPresentation = NStr("vi = '%1 (%2)';
									|ru = '%1 (%2)';
									|en = '%1 (%2)'; fa = '%1 (%2)';
									|it = '%1 (%2)';
									|pl = '%1 (%2)';
									|tr = '%1 (%2)'");
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If Selection.Next() Then
		Sum = Selection.Sum;
		SumCompl = Selection.SumCompl;
		CostTD = Selection.CostTD;
	EndIf;
	
	Items.Sum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation,
		Sum,
		CurrencyOfMan);
	Items.SumCompl.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation,
		SumCompl,
		ComplCurrency);
	Items.AmountTemporaryDifferences.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation,
		CostTD,
		ComplCurrency);
		
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False;
	Items.ReglGroup.Visible = (Not SumCompl = 0);
	Items.BPGroup.Visible = (CalculationOfPermanentAndTemporaryDifferencesIsKept And Not CostTD = 0);
		
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
		DateOnChange(Items.DateByDatabase);
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
