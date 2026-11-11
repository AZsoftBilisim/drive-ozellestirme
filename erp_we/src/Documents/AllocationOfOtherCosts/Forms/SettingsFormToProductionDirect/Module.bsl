#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var AttributeCache;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Utbazovaya = GetFunctionalOption("BaseVersion");
	
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
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If Object.SettingsOfBaseOfAllocationByLotsChanged Then
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(
			SettingsOfBaseOfAllocationByLots.GetSettings());
	Else
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(Undefined);
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
		State = PredefinedValue("Enum.CostAllocationStates.ReadyForAllocation");

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
	
	UpdateCaptionPeriod();
	
EndProcedure

&AtClient
Procedure TypeOfAccountingForChanges(Item)
	SetAvailabilityOfAccountingTypes();
	SynchronizeTypesOfAccountingBUAndTa(Item.Name);
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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

#EndRegion

#EndRegion

#Region Private

#Region DetailsChangeHandlers

&AtClient
Procedure ProcessChangeDistributeToArticles()
	
	If Not Object.AllocateToExpenseItems Then
		ClearDependentProps("AllocateToExpenseItems");
	EndIf;
	
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

&AtClientAtServerNoContext
Procedure SetPageVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Then
		
		Items.BaseOfAllocationByLots.Visible = Not Form.AllocationSettingIsNotRequired;
			
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
	
	Items.CostShareForProduction.MarkIncomplete = Not Items.CostShareForProduction.ReadOnly
		And Not ValueIsFilled(Object.CostShareForProduction);
		
	Items.CostShareOfWIP.MarkIncomplete = Not Items.CostShareOfWIP.ReadOnly
		And Not ValueIsFilled(Object.CostShareOfWIP);
		
EndProcedure


#EndRegion

#Region InitializeForm

&AtServer
Procedure OnReadCreateAtServer()

	DetermineVisibilityAndAmountOfExpensesForArticle();
	DetermineNeedToConfigureDistribution();
	
	FillInServiceDetailsOfForm();
	
	SetPageVisibility(ThisForm);
	SetItemsVisibility(ThisForm);
	SetAvailabilityOfAccountingTypes();
		
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	SetFormHeader();
	FillInSelectionListOfDistributionBasesByBatch();
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	ObjectPresentation = Metadata.Documents.AllocationOfOtherCosts.Synonym;
	ObjectPresentationClarification = NStr("vi = ' giá thành sản xuất';
											|ru = ' на себестоимость производства';
											|en = ' to production cost'; fa = ' to production cost';
											|it = ' per costo di produzione';
											|pl = ' na koszt własny produkcji';
											|tr = ' stok maliyetine'");
	
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

&AtClient
Procedure UpdateCaptionPeriod()

	LabelPeriod = PeriodPresentation(BegOfMonth(Object.Date), EndOfMonth(Object.Date), "DLF=D");
	
EndProcedure

#EndRegion

#Region ControlOfChangesInBankingDetails

&AtClient
Procedure ProcessChangesToBankingDetails(Var_AttributeName)
	
	If Var_AttributeName = "AllocateToExpenseItems" Then
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
			ObjectAttributes.Add("CostShareForProduction");
		EndIf;
		
		ObjectAttributes.Add("WriteOff");
		ObjectAttributes.Add("CostShareToExpenseItems");
		
	EndIf;
	
	Return New Structure("FormAttributes, ObjectAttributes", FormAttributes, ObjectAttributes);
		
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure DetermineNeedToConfigureDistribution()

	AllocationSettingIsNotRequired = 
		TypeOf(Object.DimensionOfExpenses) = Type("CatalogRef.ProductionLots") Or
		True;
	
EndProcedure

&AtServer
Procedure FillInSelectionListOfDistributionBasesByBatch()
	SupportedTypes = Enums.TypesOfCostAllocatingBase.TypesOfDirectCostAllocationBases();
	Items.BaseOfAllocationByLots.ChoiceList.LoadValues(SupportedTypes);
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
	Sum = 0;
	SumCompl = 0;
	CostTD = 0;
	
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

	Items.ReglGroup.Visible = (Not SumCompl = 0);
	Items.BPGroup.Visible = 
		AccountingPoliciesTaxSettingsLocalization.CalculationOfPermanentAndTemporaryDifferencesIsKept(Object.Organization, Object.Date)
		And Not CostTD = 0;
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
