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
	InitializeDynamicListOfMetricValues();
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

	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UpdateCaptionPeriod();

	AttributeCache = New Structure;
	AttributeCache.Insert("LocalAccounting", Object.LocalAccounting);
	AttributeCache.Insert("ManagementAccounting", Object.ManagementAccounting);

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

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
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

	TransferParameters = New Structure;
	TransferParameters.Insert("Organization", Object.Organization);
	TransferParameters.Insert("Department", Object.Department);
	TransferParameters.Insert("ExpenseItem", Object.ExpenseItem);
	TransferParameters.Insert("DimensionOfExpenses", Object.DimensionOfExpenses);
	TransferParameters.Insert("LineOfBusiness", Object.LineOfBusiness);

	If Object.Posted Then

		DocumentTransfers_ = Object.Ref;
		State = PredefinedValue(
				"Enum.CostAllocationStates.ReadyForAllocation");

	Else

		DocumentTransfers_ = Undefined;
		State = PredefinedValue(
				"Enum.CostAllocationStates.DocumentGenerationIsRequired");

	EndIf;

	If Object.ManagementAccounting Or AttributeCache.ManagementAccounting Then

		If Not Object.ManagementAccounting And AttributeCache.ManagementAccounting Then

			TransferParameters.Insert("DocumentMan", Undefined);
			TransferParameters.Insert("UPRStatus", PredefinedValue(
					"Enum.CostAllocationStates.DocumentGenerationIsRequired"));

		Else

			TransferParameters.Insert("DocumentMan", DocumentTransfers_);
			TransferParameters.Insert("UPRStatus", State);

		EndIf;

	EndIf;

	If Object.LocalAccounting Or AttributeCache.LocalAccounting Then

		If Not Object.LocalAccounting And AttributeCache.LocalAccounting Then

			TransferParameters.Insert("DocumentCompl", Undefined);
			TransferParameters.Insert("ReglStatus", PredefinedValue(
					"Enum.CostAllocationStates.DocumentGenerationIsRequired"));

		Else

			TransferParameters.Insert("DocumentCompl", DocumentTransfers_);
			TransferParameters.Insert("ReglStatus", State);

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
	SetParametersForListOfMetricValues();

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
	SetAvailabilityOfAccountingTypes();
	SynchronizeTypesOfAccountingBUAndTa(Item.Name);
EndProcedure

#EndRegion

#Region EventHandlersDistributionRules

&AtClient
Procedure DecorationOpenTheFormForEnteringIndicatorValuesClick(Item)

	FormParameters = New Structure;
	FormParameters.Insert("Factor", Object.Factor);
	FormParameters.Insert("Period", BegOfMonth(Object.Date));
	FormParameters.Insert("AssignRule", PredefinedValue(
		"Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter"));

	OpenForm("Catalog.CostAllocationRules.Form.ListFormManually", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure AllocateToCostCenterOnChange(Item)

	If Not Object.AllocateToCostCenter Then
		SpecifyChangingBankingDetails("AllocateToCostCenter");
	Else
		ProcessAndDistributeToHIA();
	EndIf;

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
Procedure CostShareToCostCentersOnChange(Item)

	CustomizeFieldDesign(ThisForm);

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
Procedure WriteOffDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
	StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData,
		DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData,
		DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure WriteOffOnStartEdit(Item, NewRow, Copy)

	CurrentData = Items.WriteOff.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.WriteOff");

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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined,
	StandardProcessing = Undefined)
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

#Region DetailsChangeHandlers

&AtClient
Procedure ProcessAndDistributeToHIA()

	If Not Object.AllocateToCostCenter Then
		ClearDependentProps("AllocateToCostCenter");
	Else
		CustomizeFieldDesign(ThisForm);
	EndIf;

	SetItemsAvailability(ThisForm, "AllocateToCostCenter");

EndProcedure

&AtClient
Procedure ProcessChangeDistributeToArticles()

	If Not Object.AllocateToExpenseItems Then
		ClearDependentProps("AllocateToExpenseItems");
	EndIf;

	SetItemsAvailability(ThisForm, "AllocateToExpenseItems");
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
Procedure SetItemsVisibility(Form, AttributeName = Undefined)

	Items = Form.Items;
	Object = Form.Object;

EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Form, AttributeName = Undefined)

	Items = Form.Items;
	Object = Form.Object;

	If AttributeName = Undefined Or AttributeName = "AllocateToCostCenter" Then

		Items.DescriptionOfTheRuleForProductionCosts.Enabled = Object.AllocateToCostCenter;

	EndIf;

	If AttributeName = Undefined Or AttributeName = "AllocateToExpenseItems" Then
		Items.ToOtherItems.Enabled = Object.AllocateToExpenseItems;
	EndIf;

	If AttributeName = Undefined Or AttributeName = "LeaveAsWIP" Then
		Items.CostShareOfWIP.Enabled = Object.LeaveAsWIP;
	EndIf;

	EstablishAvailabilityOfShareOfCostOfHIA(Form);

EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfShareOfCostOfHIA(Form)

	Items = Form.Items;
	Object = Form.Object;

	If Object.AllocateToCostCenter And (Object.AllocateToExpenseItems Or Object.LeaveAsWIP) Then
		Items.CostShareToCostCenters.ReadOnly = False;
	Else
		Items.CostShareToCostCenters.ReadOnly = True;
	EndIf;

EndProcedure

&AtServer
Procedure SetAvailabilityOfAccountingTypes()
	
	Documents.AllocationOfOtherCosts.SetAvailabilityOfAccountingTypes(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeFieldDesign(Form)

	Items = Form.Items;
	Object = Form.Object;

	Items.CostShareToCostCenters.MarkIncomplete = Not Items.CostShareToCostCenters.ReadOnly
		And Not ValueIsFilled(Object.CostShareToCostCenters);

	Items.CostShareOfWIP.MarkIncomplete = Not Items.CostShareOfWIP.ReadOnly
		And Not ValueIsFilled(Object.CostShareOfWIP);

EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByFO(Var_AttributeName = Undefined)

	If Var_AttributeName = "GroupLeaveGNZP" Or Var_AttributeName = Undefined Then
		Items.GroupLeaveGNZP.Visible = (UnavailableItems.FindByValue("GroupLeaveGNZP")
			= Undefined);
	EndIf;

EndProcedure

&AtServer
Procedure SynchronizeTypesOfAccountingBUAndTa(AccountingKind)
	
	Documents.AllocationOfOtherCosts.SynchronizeTypesOfAccountingBUAndTa(ThisForm, AccountingKind);
	
EndProcedure


#EndRegion

#Region InitializeForm

&AtServer
Procedure OnReadCreateAtServer()

	IncomeAndExpensesServer.OnReadAtServer(ThisObject,
		Documents.AllocationOfOtherCosts.ItemsAndDimensionsSelectionParameters());
	GLAccountSettingsServer.OnReadAtServer(ThisObject,
		Documents.AllocationOfOtherCosts.AccountingAccountSettings_());
	DetermineVisibilityAndAmountOfExpensesForArticle();

	FillInServiceDetailsOfForm();

	SetVisibilityOfElementsByFO();
	SetItemsVisibility(ThisForm);
	SetItemsAvailability(ThisForm);
	SetAvailabilityOfAccountingTypes();
	CustomizeFieldDesign(ThisForm);

	SetParametersForListOfMetricValues();

EndProcedure

&AtServer
Procedure SetParametersForListOfMetricValues()

	CommonClientServer.SetDynamicListParameter(IndicatorValues_2, "Date", BegOfMonth(
		Object.Date));
	CommonClientServer.SetDynamicListFilterItem(IndicatorValues_2, "Factor",
		Object.Factor, DataCompositionComparisonType.Equal);

EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()

	SetFormHeader();

	UnavailableItems = UnavailableElementsByFederalDistrict(Object.Date);

EndProcedure
&AtClient
Procedure UpdateCaptionPeriod()

	LabelPeriod = PeriodPresentation(BegOfMonth(Object.Date), EndOfMonth(Object.Date), "DLF=D");

EndProcedure

&AtServer
Procedure SetFormHeader()

	ObjectPresentation = Metadata.Documents.AllocationOfOtherCosts.Synonym;
	ObjectPresentationClarification = NStr("vi = 'giữa các đối tượng phát sinh chi phí';
											|ru = 'между объектами возникновения затрат';
											|en = 'between cost centers'; fa = 'between cost centers';
											|it = 'tra i centri di costo';
											|pl = 'między obiektami tworzenia się rozchodów';
											|tr = 'gider oluşumu nesneleri arasında'");

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
		Title = StrTemplate(TitleTemplate1, ObjectPresentation, ObjectPresentationClarification, Object.Number,
			Format(Object.Date, "DLF=DT"));

	EndIf;

EndProcedure

&AtServer
Procedure InitializeDynamicListOfMetricValues()
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast";
	ListProperties.DynamicDataRead = False;
	ListProperties.QueryText = QueryTextIndicatorValues_2();
	Common.SetDynamicListProperties(Items.IndicatorValues_2, ListProperties);
EndProcedure

&AtServer
Function QueryTextIndicatorValues_2()
	Return "
			|SELECT
			|	SliceLast.Period,
			|	SliceLast.Factor,
			|	SliceLast.ConstCenter AS ConstCenter,
			|	SliceLast.IndicatorValue
			|FROM
			|	InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(&Date,) AS SliceLast
			|WHERE
			|	CASE
			|		WHEN SliceLast.Factor.AllocationBase IN
			|		(VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis),
			|			VALUE(Enum.TypesOfCostAllocatingBase.AutofillOnMonthlyBasis))
			|		AND SliceLast.Period = BEGINOFPERIOD(&Date, MONTH)
			|			THEN TRUE
			|		ELSE CASE
			|			WHEN
			|				SliceLast.Factor.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
			|				THEN TRUE
			|			ELSE FALSE
			|		END
			|	END
			|AND NOT ISNULL(SliceLast.IndicatorValue, 0) = 0";
EndFunction

#EndRegion

#Region UserInteraction

&AtClient
Procedure SpecifyChangingBankingDetails(Var_AttributeName, NeedToAskQuestion = False)

	If Not NeedToAskQuestion Then
		
		// The parameter is not passed. So you need to determine whether you need to ask a question or not.

		StructureOfDependentProps = DependentDetails(Var_AttributeName);

		For Each FormAttribute In StructureOfDependentProps.FormAttributes Do

			If TypeOf(ThisForm[FormAttribute]) = Type("Boolean") And ThisForm[FormAttribute] = True Or Not TypeOf(
				ThisForm[FormAttribute]) = Type("Boolean") And ValueIsFilled(ThisForm[FormAttribute]) Then

				NeedToAskQuestion = True;
				Break;

			EndIf;

		EndDo;

		If Not NeedToAskQuestion Then
			For Each ObjectAttribute In StructureOfDependentProps.ObjectAttributes Do

				If TypeOf(Object[ObjectAttribute]) = Type("Boolean") And Object[ObjectAttribute] = True Or Not TypeOf(
					Object[ObjectAttribute]) = Type("Boolean") And ValueIsFilled(Object[ObjectAttribute]) Then

					NeedToAskQuestion = True;
					Break;

				EndIf;

			EndDo;
		EndIf;

	EndIf;

	If NeedToAskQuestion Then

		If Var_AttributeName = "AllocateToExpenseItems" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ cho các dạng khác sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения на другие статьи будут очищены. Продолжить?';
							|en = 'Settings of allocation to other items will be cleared. Continue?'; fa = 'Settings of allocation to other items will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione su altri articoli verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia na inne pozycje zostaną wyczyszczone. Kontynuować?';
							|tr = 'Diğer kalemlere dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		EndIf;

		NotificationParameters = New Structure("AttributeName", Var_AttributeName);

		ShowQueryBox(New CallbackDescription("SpecifyChangingBankingDetailsCompletion", ThisForm, NotificationParameters),
			QueryText, QuestionDialogMode.YesNo);

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
		If AttributeName = "AllocateToCostCenter" Or AttributeName = "AllocateToExpenseItems" Then
			Object[AttributeName] = Not Object[AttributeName];
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region ControlOfChangesInBankingDetails

&AtClient
Procedure ProcessChangesToBankingDetails(Var_AttributeName)

	If Var_AttributeName = "AllocateToCostCenter" Then
		ProcessAndDistributeToHIA();
	ElsIf Var_AttributeName = "AllocateToExpenseItems" Then
		ProcessChangeDistributeToArticles();
	EndIf;

EndProcedure

&AtClient
Function ClearDependentProps(Var_AttributeName)

	StructureOfDependentProps = DependentDetails(Var_AttributeName);

	For Each FormAttribute In StructureOfDependentProps.FormAttributes Do

		If TypeOf(ThisForm[FormAttribute]) = Type("FormDataCollection") Then
			ThisForm[FormAttribute].Clear();
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

	If Attribute = "AllocateToExpenseItems" Then

		If Not Object.AllocateToExpenseItems Then
			ObjectAttributes.Add("CostShareToCostCenters");
		EndIf;

		ObjectAttributes.Add("WriteOff");
		ObjectAttributes.Add("CostShareToExpenseItems");

	EndIf;

	Return New Structure("FormAttributes, ObjectAttributes", FormAttributes, ObjectAttributes);

EndFunction

#EndRegion
#Region Other

&AtServerNoContext
Function UnavailableElementsByFederalDistrict(Period)

	BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22(Period);

	UnavailableItems = New ValueList;

	If Not BatchAccountingVersion22 Then
		UnavailableItems.Add("GroupLeaveGNZP");
	EndIf;

	Return UnavailableItems;

EndFunction

&AtClientAtServerNoContext
Procedure UpdateCostShares(Form)

	Object = Form.Object;

	Object.CostShareToExpenseItems = Object.WriteOff.Total("CostShare");

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
						  |			DimensionOfExpenses = &Dimension) AS RegisterRecords");

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

	SupportedDistributionOptions = New Array;
	SupportedDistributionOptions.Add(
		Enums.CostAllocationOptions.ToCostCenters);
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
																							   |	T.DimensionOfExpenses = &Dimension
																							   |	AND T.LineOfBusiness = &LineOfBusiness";

	Query.SetParameter("BeginOfPeriod", BegOfMonth(Object.Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Object.Date));
	Query.SetParameter("BorderEndOfPeriod", New Boundary(EndOfMonth(Object.Date), BoundaryType.Including));
	Query.SetParameter("CompanyArray", Object.Organization);
	Query.SetParameter("DepartmentList", Object.Department);
	Query.SetParameter("ByAllCompanies", False);
	Query.SetParameter("ByAllBusinessUnits", False);
	//Request.Set the parameter("Article", Object.Expense articles);
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
		TemplateOfPresentation, Sum, CurrencyOfMan);
	Items.SumCompl.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation, SumCompl, ComplCurrency);
	Items.AmountTemporaryDifferences.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation, CostTD, ComplCurrency);

	PBU18IsApplied = False;
	Items.ReglGroup.Visible = (Not SumCompl = 0);
	Items.BPGroup.Visible = (PBU18IsApplied And Not CostTD = 0);

EndProcedure

//-- Outdated_Production21

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
