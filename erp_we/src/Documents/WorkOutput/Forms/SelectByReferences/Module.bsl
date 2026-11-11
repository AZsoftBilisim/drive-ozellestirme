
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("FilterStructure1") Then
		FilterStructure1 = Parameters.FilterStructure1;
	Else
		FilterStructure1 = New Structure;
	EndIf;
	
	Parameters.Property("AddressInStorage", AddressInStorage);
	
	FilterStructure1.Property("Team", Team);
	FilterStructure1.Property("Department", Department);
	FilterStructure1.Property("WorkOrderKind", WorkOrderKind);
	
	Items.Team.Visible = WorkOrderKind <> Enums.TeamWorkOrderKinds.Personal;
	
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Ref);
	
	FillInTable();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure QuantityTableOnChange(Item)
	CurrentData = Items.Table.CurrentData;
	CurrentData.Selected = CurrentData.AmountDueForPayment > 0;
	If CurrentData.AmountDueForPayment > CurrentData.QuantityToRegister Then
		CurrentData.AmountDueForPayment = CurrentData.QuantityToRegister;
	EndIf;
	CurrentData.Sum = CurrentData.AmountDueForPayment * CurrentData.Rate_;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	PutTableInStorage(ThisForm.FormOwner.UUID);
	ValueSelected = New Structure("AddressInStorage", AddressInStorage);
	
	NotifyChoice(ValueSelected);
	
EndProcedure

&AtClient
Procedure SelectRowsExecute()
	
	MarkLines(True);
	
EndProcedure

&AtClient
Procedure ClearRowsExecute()
	
	MarkLines(False);
	
EndProcedure

&AtClient
Procedure SelectSelectedRows(Command)
	
	RowsArray = Items.Table.SelectedRows;
	MarkLines(True, RowsArray);
	
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	
	RowsArray = Items.Table.SelectedRows;
	MarkLines(False, RowsArray);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableReflectionMethod.Name);
	
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkOrderKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TeamWorkOrderKinds.Repair;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableProductCostElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkOrderKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TeamWorkOrderKinds.Repair;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableEmployee_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkOrderKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TeamWorkOrderKinds.Personal;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure PutTableInStorage(Id)
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each TableRow In Table Do
		
		If Not TableRow.Selected Then
			ArrayOfRowsToDelete_1.Add(TableRow);
		EndIf;
		
	EndDo;
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		Table.Delete(TableRow);
	EndDo;
	
	AddressInStorage = PutToTempStorage(Table.Unload(), Id);
	
EndProcedure

&AtServer
Procedure FillInTable()
	
	TempTablesManager = New TempTablesManager;
	Documents.WorkOutput.LaborCostsToRegister(FilterStructure1, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.QuantityToRegister AS QuantityToRegister,
	|	DD.AmountDueForPayment AS AmountDueForPayment
	|INTO Selected
	|FROM
	|	&ActivityKinds AS DD
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ExecutionDate AS Date,
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	DD.WorkKind AS WorkKind,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.Employee_
	|	END AS Employee_,
	|	DD.QuantityToRegister - ISNULL(Selected.QuantityToRegister, 0) AS QuantityToRegister,
	|	DD.AmountDueForPayment - ISNULL(Selected.AmountDueForPayment, 0) AS AmountDueForPayment,
	|	DD.Rate_ AS Rate_,
	|	(DD.AmountDueForPayment - ISNULL(Selected.AmountDueForPayment, 0)) * DD.Rate_ AS Sum,
	|	DD.Organization AS Organization,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.ProductsGroup AS ProductsGroup,
	|	DD.ProductCostElement AS ProductCostElement
	|FROM
	|	ActivityKinds AS DD
	|	
	|	LEFT JOIN Selected AS Selected
	|	ON DD.ReferenceOrder = Selected.ReferenceOrder
	|		AND DD.ReferenceRowCode = Selected.ReferenceRowCode
	|
	|WHERE
	|	NOT (DD.QuantityToRegister - ISNULL(Selected.QuantityToRegister, 0)) = 0
	|";
	
	SelectedTypesOfWork =  GetFromTempStorage(AddressInStorage); // ValueTable
	SelectedTypesOfWork.GroupBy("ReferenceOrder,ReferenceRowCode","QuantityToRegister,AmountDueForPayment");
	
	Query.SetParameter("ActivityKinds", SelectedTypesOfWork);
	
	Table.Load(Query.Execute().Unload());
	
	Table.Sort("Date,WorkKind,ReferenceOrder");
	
EndProcedure

&AtClient
Procedure MarkLines(Value, RowsArray = Undefined)
	
	If RowsArray = Undefined Then
		
		For Each TableRow In Table Do
			TableRow.Selected = Value;
		EndDo;
		
	Else
		
		For Each LineNumber In RowsArray Do
			TableRow = Table.FindByID(LineNumber);
			If TableRow <> Undefined Then
				TableRow.Selected = Value;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion
