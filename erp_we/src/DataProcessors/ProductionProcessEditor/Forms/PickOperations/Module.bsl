#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CatalogName = Parameters.CatalogName;
	CloseOnChoice = False;
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision();
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Or CurrentData.IsFolder Then
		Return;
	EndIf;
	
	AttachIdleHandler("Attachable_ListOnActivateRow", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionTable

&AtClient
Procedure TransactionTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	TransferSelectedOperations();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveSelected(Command)
	
	TransferSelectedOperations();
	
EndProcedure

&AtClient
Procedure TransferAll(Command)
	
	RescheduleOperations();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	List.ConditionalAppearance.Items.Clear();
	
	If ByRouteMap(Parameters) Then
		Catalogs.RouteSheets.SetConditionalAppearanceOfRouteMapList(
			List.ConditionalAppearance);
	Else
		Catalogs.TechnologicalProcesses.EstablishConditionalAppearanceOfListOfTechnologicalProcesses(
			List.ConditionalAppearance);
	EndIf;

EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	QueryText = StrReplace("
	|SELECT
	|	TableOverridable.Ref          AS Ref,
	|	TableOverridable.DeletionMark AS DeletionMark,
	|	TableOverridable.Parent        AS Parent,
	|	TableOverridable.IsFolder       AS IsFolder,
	|	TableOverridable.Code             AS Code,
	|	TableOverridable.Description    AS Description,
	|	TableOverridable.Status          AS Status,
	|	TableOverridable.Department   AS Department,
	|	TableOverridable.ForFinishedProductsKind  AS ForFinishedProductsKind
	|FROM 
	|	&CatalogName AS TableOverridable", "&CatalogName", CatalogName);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText    = QueryText;
	ListProperties.MainTable = CatalogName;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	If Parameters.Property("Department", FilterDepartment) Then
		SetSelectionByDivision();
		If Parameters.Property("UnitViewOnly") Then
			Items.FilterDepartment.ReadOnly = True;
		EndIf;
	EndIf;
	
	If ByRouteMap(ThisObject) Then
		Items.FilterStatus.TypeRestriction = New TypeDescription("EnumRef.StatusesOfRouteSheets");
	Else
		Items.FilterStatus.TypeRestriction = New TypeDescription("EnumRef.TechnologicalProcessStatuses");
	EndIf;
	
	If Parameters.Property("Status", FilterStatus) Then
		SetSelectionByStatus(ThisObject);
		If Parameters.Property("StatusViewOnly") Then
			Items.FilterStatus.ReadOnly = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Status",
		Form.FilterStatus,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.FilterStatus));

EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	FilterIs_Specified = ValueIsFilled(FilterDepartment);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Department",
		FilterDepartment,
		DataCompositionComparisonType.Equal,
		,
		FilterIs_Specified);
	
	Items.TransactionTableProductionArea.Visible = ?(FilterIs_Specified,
		ProductionServer.ProductionBusinessUnitDescription(FilterDepartment).UseAreas,
		True);
	
EndProcedure

&AtServer
Procedure SetSelectionByProductRange()
	
	If ByRouteMap(ThisObject) Then
		ProductDataManagementClientServer.SetSelectionByProductInRouteMapList(
			List, FilterProducts);
	Else
		Catalogs.TechnologicalProcesses.SetSelectionByProductInListOfTechnologicalProcesses(
			List, FilterProducts);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	ListWhenActivatingLineOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Function ByRouteMap(Form)
	
	Return StrFind(Form.CatalogName,"RouteSheets") > 0;
	
EndFunction

&AtServer
Procedure ListWhenActivatingLineOnServer()
	
	FillInOFOperationsTable();
	
EndProcedure

&AtServer
Procedure FillInOFOperationsTable()
	
	TransactionTable.Clear();
	
	CurrentRow = Items.List.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If ByRouteMap(ThisObject) Then
		Operations = Catalogs.RouteSheets.RouteMapData(
			CurrentRow, 1, Undefined, Undefined, "Operations").Operations;
	Else
		Operations = Catalogs.TechnologicalProcesses.ProcessData_(
			CurrentRow, Catalogs.TechnologicalProcesses.DataSamplingParameters("Operations")).Operations;
	EndIf;
	
	For Each String In Operations Do
		FillPropertyValues(TransactionTable.Add(), String);
	EndDo;
	
EndProcedure

&AtClient
Procedure TransferSelectedOperations()
	
	OperationArray = New Array;
	For Each RowID In Items.TransactionTable.SelectedRows Do
		OperationArray.Add(TransactionTable.FindByID(RowID).Operation);
	EndDo;
	
	RescheduleOperations(OperationArray);
	
EndProcedure

&AtClient
Procedure RescheduleOperations(OperationArray = Undefined)
	
	Result = New Structure("TechnologicalProcess,Operations");
	
	Result.TechnologicalProcess = Items.List.CurrentRow;
	If ValueIsFilled(OperationArray) Then
		Result.Operations = OperationArray;
	EndIf;
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion