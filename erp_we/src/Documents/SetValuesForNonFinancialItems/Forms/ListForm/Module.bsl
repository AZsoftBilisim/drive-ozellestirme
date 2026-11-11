
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SavedIndicatorCheckBoxes.Load(
		Common.FormDataSettingsStorageLoad(
			"Document.SetValuesForNonFinancialItems.ListForm",
			"SelectedIndicators", SavedIndicatorCheckBoxes.Unload(New Array))
			);
			
	SavedTemplateCheckBoxes.Load(
		Common.FormDataSettingsStorageLoad(
			"Document.SetValuesForNonFinancialItems.ListForm",
			"SelectedTemplates", SavedTemplateCheckBoxes.Unload(New Array))
			);
			
	Items.PanelFilter.CurrentPage = Items[
		Common.FormDataSettingsStorageLoad(
			"Document.SetValuesForNonFinancialItems.ListForm",
			"FilterOption_", "ByIndicators")
			];
			
	FillInMetricsTemplates(False);
	
	Items.IndicatorTreeByIndicators.Check = True;
	Items.TemplateTreeByTemplates.Check = True;
	
	SetListFilters();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_SettingNFPValues" Then
		SetListFilters();
		Items.List.CurrentRow = Parameter;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByIndicators(Command)
	
	Items.PanelFilter.CurrentPage = Items.ByIndicators;
	SetListFilters(True,3);
	
EndProcedure

&AtClient
Procedure ByTemplates(Command)
	
	Items.PanelFilter.CurrentPage = Items.ByTemplates;
	SetListFilters(True,3);
	
EndProcedure

&AtClient
Procedure IndicatorTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = IndicatorTree.FindByID(RowSelected);
	OpeningParameters = New Structure("Key", CurrentData.Ref);
	OpenForm("Catalog.NonFinancialItemsOfBudgets.Form.ItemForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure TemplateTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = TemplateTree.FindByID(RowSelected);
	OpeningParameters = New Structure("Key", CurrentData.Ref);
	OpenForm("Catalog.NonFinancialItemProfiles.Form.ItemForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure IndicatorTreeFlagOnChange(Item)
	
	CurrentData = Items.IndicatorTree.CurrentData;
	If Items.IndicatorTree.CurrentData.IsFolder Then
		SetStringFlagsRecursively(CurrentData, CurrentData.Flag);
	EndIf;
	SetListFilters(True,1);
	
EndProcedure

&AtClient
Procedure TemplateTreeFlagOnChange(Item)
	
	CurrentData = Items.TemplateTree.CurrentData;
	If Items.TemplateTree.CurrentData.IsFolder Then
		SetStringFlagsRecursively(CurrentData, CurrentData.Flag);
	EndIf;
	SetListFilters(True,2);
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	SetListFilters();
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleFilterOnChange(Item)
	
	SetListFilters();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Return;
	EndIf;
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		CurrentData = Items.IndicatorTree.CurrentData;
	Else
		CurrentData = Items.TemplateTree.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.IsFolder Then
		Return;
	EndIf;
	
	Cancel = True;
	
	Ref = CurrentData.Ref;
	
	InstallationParameters = New Structure();
	If TypeOf(Ref) = Type("CatalogRef.NonFinancialItemProfiles") Then
		FillingValues = New Structure("InputTemplate, OperationKind", Ref, 
			PredefinedValue("Enum.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate"));
	Else
		FillingValues = New Structure("OperationKind",
				PredefinedValue("Enum.OperationKindsOfSettingOfNonFinancialItemValues.EnterIndicatorValue"));
		Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(Ref, "ImportFromOtherSubsystems, ByScenarios");
		InputUnavailable = Attributes.ImportFromOtherSubsystems And Not Attributes.ByScenarios;
		If Not InputUnavailable Then
			FillingValues.Insert("NonFinancialItem", Ref);
		EndIf;
	EndIf;
	
	InstallationParameters.Insert("FillingValues", FillingValues);
	OpenForm("Document.SetValuesForNonFinancialItems.Form.DocumentForm", InstallationParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Refresh(Command)
	
	FillInMetricsTemplates();
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		TreeRows = IndicatorTree.GetItems();
	Else
		TreeRows = TemplateTree.GetItems();
	EndIf;
	
	For Each TreeRow In TreeRows Do
		TreeRow.Flag = True;
		SetStringFlagsRecursively(TreeRow, True);
	EndDo;
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		SetListFilters(True,1);
	Else
		SetListFilters(True,2);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		TreeRows = IndicatorTree.GetItems();
	Else
		TreeRows = TemplateTree.GetItems();
	EndIf;
	
	For Each TreeRow In TreeRows Do
		TreeRow.Flag = False;
		SetStringFlagsRecursively(TreeRow, False);
	EndDo;
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		SetListFilters(True,1);
	Else
		SetListFilters(True,2);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		TreeRows = IndicatorTree.GetItems();
		TagName = "IndicatorTree";
	Else
		TreeRows = TemplateTree.GetItems();
		TagName = "TemplateTree";
	EndIf;
	
	For Each TreeRow In TreeRows Do
		Items[TagName].Expand(TreeRow.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		TreeRows = IndicatorTree.GetItems();
		TagName = "IndicatorTree";
	Else
		TreeRows = TemplateTree.GetItems();
		TagName = "TemplateTree";
	EndIf;
	
	For Each TreeRow In TreeRows Do
		FormItem = Items[TagName]; // FormTable -
		FormItem.Collapse(TreeRow.GetID());
	EndDo;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure ShouldSaveSettings(SettingNumber=0)
	
	If SettingNumber < 3 Then 
		SaveFlags();
	EndIf;
	
	If SettingNumber = 0 Or SettingNumber = 1 Then 
		Common.FormDataSettingsStorageSave(
			"Document.SetValuesForNonFinancialItems.ListForm",
			"SelectedIndicators", SavedIndicatorCheckBoxes.Unload());
	EndIf;
	If SettingNumber = 0 Or SettingNumber = 2 Then
		Common.FormDataSettingsStorageSave(
			"Document.SetValuesForNonFinancialItems.ListForm",
			"SelectedTemplates", SavedTemplateCheckBoxes.Unload());
	EndIf;
	If SettingNumber = 0 Or SettingNumber = 3 Then
		Common.FormDataSettingsStorageSave(
			"Document.SetValuesForNonFinancialItems.ListForm",
			"FilterOption_", Items.PanelFilter.CurrentPage.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetStringFlagsRecursively(CurrentData, Flag)
	
	SubordinateRows = CurrentData.GetItems();
	For Each TreeRow In SubordinateRows Do
		TreeRow.Flag = Flag;
		SetStringFlagsRecursively(TreeRow, Flag);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInMetricsTemplates(SaveFlags_ = True)
	
	If SaveFlags_ Then
		SaveFlags();
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	List.Flag,
		|	List.Ref
		|INTO StoredValues
		|FROM
		|	&List AS List
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	NonFinancialItemsOfBudgets.Ref AS Ref,
		|	CASE
		|		WHEN StoredValues.Ref IS NULL
		|				OR StoredValues.Flag = TRUE
		|			THEN TRUE
		|	END AS Flag,
		|	CASE
		|		WHEN NonFinancialItemsOfBudgets.IsFolder
		|			THEN 42
		|		ELSE 50
		|	END AS PictureIndex,
		|	NonFinancialItemsOfBudgets.IsFolder
		|FROM
		|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
		|		LEFT JOIN StoredValues AS StoredValues
		|		ON (StoredValues.Ref = NonFinancialItemsOfBudgets.Ref)
		|WHERE
		|	(NOT NonFinancialItemsOfBudgets.ImportFromOtherSubsystems
		|			OR NonFinancialItemsOfBudgets.ImportFromOtherSubsystems IS NULL)
		|
		|ORDER BY
		|	Ref HIERARCHY
		|AUTOORDER";

	Query.SetParameter("List", SavedIndicatorCheckBoxes.Unload());
	
	QueryResult = Query.Execute();
	Tree = FormAttributeToValue("IndicatorTree");
	Tree.Rows.Clear();
	FinancialReportingServer.QueryResultInTree(QueryResult, Tree);
	ValueToFormAttribute(Tree, "IndicatorTree");
	
	Query.Text = 
		"SELECT
		|	List.Flag,
		|	List.Ref
		|INTO StoredValues
		|FROM
		|	&List AS List
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NonFinancialItemProfiles.Ref AS Ref,
		|	CASE
		|		WHEN StoredValues.Ref IS NULL
		|				OR StoredValues.Flag = TRUE
		|			THEN TRUE
		|	END AS Flag,
		|	CASE
		|		WHEN NonFinancialItemProfiles.IsFolder
		|			THEN 42
		|		ELSE 50
		|	END AS PictureIndex,
		|	NonFinancialItemProfiles.IsFolder
		|FROM
		|	Catalog.NonFinancialItemProfiles AS NonFinancialItemProfiles
		|		LEFT JOIN StoredValues AS StoredValues
		|		ON (StoredValues.Ref = NonFinancialItemProfiles.Ref)
		|WHERE
		|	NOT NonFinancialItemProfiles.TemplateIndicators.Factor.ImportFromOtherSubsystems
		|
		|ORDER BY
		|	Ref HIERARCHY
		|AUTOORDER";

	Query.SetParameter("List", SavedTemplateCheckBoxes.Unload());
	
	QueryResult = Query.Execute();
	Tree = FormAttributeToValue("TemplateTree");
	Tree.Rows.Clear();
	FinancialReportingServer.QueryResultInTree(QueryResult, Tree);
	ValueToFormAttribute(Tree, "TemplateTree");
	
EndProcedure

&AtServer
Procedure SelectMetrics(Query, HasFilter)
	
	If Items.PanelFilter.CurrentPage = Items.ByIndicators Then
		Tree = FormAttributeToValue("IndicatorTree");
		ByIndicators = True;
	Else
		Tree = FormAttributeToValue("TemplateTree");
		ByIndicators = False;
	EndIf;
	
	FoundRows = Tree.Rows.FindRows(New Structure("IsFolder, Flag", False, True), True);
	
	If FoundRows.Count() = 
		Tree.Rows.FindRows(New Structure("IsFolder", False), True).Count() Then
		Return;
	EndIf;
	
	SelectionList = New ValueList;
	For Each FoundRow In FoundRows Do
		SelectionList.Add(FoundRow.Ref);
	EndDo;
	
	HasFilter = True;
	
	Query.Text =
	"SELECT ALLOWED
	|	NonFinancialItemsOfBudgets.Ref AS Ref
	|INTO SelectedIndicators_
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|WHERE
	|	(&ByIndicators
	|				AND NonFinancialItemsOfBudgets.Ref IN (&List)
	|			OR NOT &ByIndicators
	|				AND NonFinancialItemsOfBudgets.Ref IN
	|					(SELECT DISTINCT
	|						IndicatorsTemplateIndicators.Factor
	|					FROM
	|						Catalog.NonFinancialItemProfiles.TemplateIndicators AS IndicatorsTemplateIndicators
	|					WHERE
	|						IndicatorsTemplateIndicators.Ref IN (&List)))
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	SetValuesForNonFinancialItemsIndicatorValues.Ref
	|INTO RegistrarsByIndicators
	|FROM
	|	Document.SetValuesForNonFinancialItems.IndicatorValues AS SetValuesForNonFinancialItemsIndicatorValues
	|		INNER JOIN SelectedIndicators_ AS SelectedIndicators_
	|		ON SetValuesForNonFinancialItemsIndicatorValues.Factor = SelectedIndicators_.Ref
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	SetValuesForNonFinancialItemsDocumentColumns.Ref
	|FROM
	|	Document.SetValuesForNonFinancialItems.DocumentColumns AS SetValuesForNonFinancialItemsDocumentColumns
	|		INNER JOIN SelectedIndicators_ AS SelectedIndicators_
	|		ON SetValuesForNonFinancialItemsDocumentColumns.NonFinancialItem = SelectedIndicators_.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RegistrarsByIndicators.Ref AS Recorder
	|INTO SelectedRegistrars
	|FROM
	|	RegistrarsByIndicators AS RegistrarsByIndicators
	|
	|INDEX BY
	|	RegistrarsByIndicators.Ref";
	
	Query.SetParameter("List", SelectionList);
	Query.SetParameter("ByIndicators", ByIndicators);
	
	Query.Execute();
	
EndProcedure

&AtServer
Procedure SelectPeriodDocuments(Query, HasFilter)
	
	If Not ValueIsFilled(Period) Then
		Return;
	EndIf;
	
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	NonFinancialItemValuesSliceLast.Recorder
	|INTO AllRegistrars
	|FROM
	|	InformationRegister.NonFinancialItemValues.SliceLast(&BeginOfPeriod, ) AS NonFinancialItemValuesSliceLast
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	NonFinancialItemValues.Recorder
	|FROM
	|	InformationRegister.NonFinancialItemValues AS NonFinancialItemValues
	|WHERE
	|	NonFinancialItemValues.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|" + ?(HasFilter, "
	|SELECT DISTINCT
	|	TableOfIndicators.Recorder
	|INTO RegistrarsByPeriod
	|FROM
	|	AllRegistrars AS TableOfIndicators
	|		INNER JOIN SelectedRegistrars AS SelectedRegistrars
	|		ON (SelectedRegistrars.Recorder = TableOfIndicators.Recorder)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SelectedRegistrars
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegistrarsByPeriod.Recorder
	|INTO SelectedRegistrars
	|FROM
	|	RegistrarsByPeriod AS RegistrarsByPeriod", "
	|
	|SELECT DISTINCT
	|	TableOfIndicators.Recorder
	|INTO SelectedRegistrars
	|FROM
	|	AllRegistrars AS TableOfIndicators
	|");
	
	Query.SetParameter("BeginOfPeriod", Period.StartDate);
	Query.SetParameter("EndOfPeriod", Period.EndDate);
	
	Query.Execute();
	
	HasFilter = True;
	
EndProcedure

&AtServer
Procedure SetListFilters(SaveSettings2=False,SettingNumber=0)
	
	If SaveSettings2 Then
		ShouldSaveSettings(SettingNumber);
	EndIf;
	
	ListSelectionsClientServer.DeleteListSelectionItem(List, "Ref");
	ListSelectionsClientServer.DeleteListSelectionItem(List, "EmployeeResponsible");
	
	If ValueIsFilled(EmployeeResponsible) Then
		ListSelectionsClientServer.SetListSelectionElement(List, "EmployeeResponsible", EmployeeResponsible);
	EndIf;
	
	HasFilter = False;
	
	Manager = New TempTablesManager;
	Query = New Query();
	Query.TempTablesManager = Manager;
	
	SelectMetrics(Query, HasFilter);
	SelectPeriodDocuments(Query, HasFilter);
	
	If Not HasFilter Then
		Return;
	EndIf;
	
	Query.Text = "SELECT Recorder FROM SelectedRegistrars";
	
	Selection = Query.Execute().Select();
	DocumentsList = New ValueList;
	While Selection.Next() Do
		DocumentsList.Add(Selection.Recorder);
	EndDo;
	
	ListSelectionsClientServer.SetListSelectionElement(List, "Ref", DocumentsList, DataCompositionComparisonType.InList);
		
EndProcedure

&AtServer
Procedure SaveFlags()
	
	SavedTemplateCheckBoxes.Clear();
	Tree = FormAttributeToValue("TemplateTree");
	FoundItems1 = Tree.Rows.FindRows(New Structure("IsFolder", False), True);
	For Each ElementString In FoundItems1 Do
		NewRow = SavedTemplateCheckBoxes.Add();
		FillPropertyValues(NewRow, ElementString);
	EndDo;
	
	SavedIndicatorCheckBoxes.Clear();
	Tree = FormAttributeToValue("IndicatorTree");
	FoundItems1 = Tree.Rows.FindRows(New Structure("IsFolder", False), True);
	For Each ElementString In FoundItems1 Do
		NewRow = SavedIndicatorCheckBoxes.Add();
		FillPropertyValues(NewRow, ElementString);
	EndDo;
	
EndProcedure

#EndRegion

