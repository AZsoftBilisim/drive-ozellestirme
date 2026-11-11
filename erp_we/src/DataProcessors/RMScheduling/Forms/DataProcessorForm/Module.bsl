
#Region Variables

&AtClient
Var ValuesInCache;

&AtClient
Var CachedValues;

&AtClient
Var CurObjectForOrderSelectionList;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseOfSubclasses = Common.ObjectAttributeValue(FilterClass, "UseOfSubclasses");
	Items.Subclass.Enabled = (UseOfSubclasses <> Undefined And UseOfSubclasses);
	
	CurrentRepairOrderRepairSelections = 0;
	CurrentRepairOrderOrderSelections = 0;
	
	MaterialsAndWorks.Parameters.SetParameterValue("RMType", Catalogs.RMTypes.EmptyRef());
	LaborCosts.Parameters.SetParameterValue("RMType", Catalogs.RMTypes.EmptyRef());
	WorkCenters.Parameters.SetParameterValue("Asset", Catalogs.Assets.EmptyRef());
	
	CreatedRepairOrders.Parameters.SetParameterValue("AnArrayOfOrders", New Array);
	
	Items.RepairDetailsPage.Visible = False;
	
	Query = New Query(
		"SELECT
		|	GeneralRMTypes.Ref AS GeneralRMType,
		|	TRUE AS Marked
		|FROM
		|	Catalog.GeneralRMTypes AS GeneralRMTypes
		|WHERE
		|	NOT GeneralRMTypes.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RMPlanningFrequency.Ref AS PlanningFrequency,
		|	TRUE AS Marked
		|FROM
		|	Enum.RMPlanningFrequency AS RMPlanningFrequency");
	
	Package = Query.ExecuteBatch();
	FilterGeneralRMTypes.Load(Package[0].Unload());
	FilterSchedulingFrequencies.Load(Package[1].Unload());
	
	InitializeSettingsComposerForSelections();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DecorationSimpleSelectionsClick(Item)
	Items.SelectionPages.CurrentPage = Items.SimpleFilterPage;
EndProcedure

&AtClient
Procedure DecorationRandomSelectionsClick(Item)
	Items.SelectionPages.CurrentPage = Items.CustomFilterPage;
EndProcedure

&AtClient
Procedure ClassOnChange(Item)
	ReflectSimpleSelectionInLayoutSelections("Class", FilterClass);
	
	ClassWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure ClassWhenModifiedOnServer()
	
	UseOfSubclasses = Common.ObjectAttributeValue(FilterClass, "UseOfSubclasses");
	Items.Subclass.Enabled = (UseOfSubclasses <> Undefined And UseOfSubclasses);
	
EndProcedure

&AtClient
Procedure SubclassOnChange(Item)
	ReflectSimpleSelectionInLayoutSelections("Subclass", FilterSubclass);
EndProcedure

&AtClient
Procedure OperatingBusinessUnitOnChange(Item)
	ReflectSimpleSelectionInLayoutSelections("OperatingBusinessUnit", FilterOperatingBusinessUnit);
EndProcedure

&AtClient
Procedure RMBusinessUnitOnChange(Item)
	ReflectSimpleSelectionInLayoutSelections("RMBusinessUnit", FilterRMBusinessUnit);
EndProcedure

&AtClient
Procedure RepairDetailHyperlink(Item)
	
	Items.RepairDetailsPage.Visible = Not Items.RepairDetailsPage.Visible;
	If Items.RepairDetailsPage.Visible Then
		Items.RepairDetailHyperlink.Title = NStr("vi = 'Ẩn chi tiết lệnh sửa chữa';
												|ru = 'Скрыть детали распоряжения на ремонт';
												|en = 'Hide R&M request details'; fa = 'Hide R&M request details';
												|it = 'Nascondere i dettagli della disposizione per manutenzione';
												|pl = 'Ukryj szczegóły zamówienia na naprawę';
												|tr = 'Onarım Siparişi Ayrıntılarını Gizle'");
	Else
		Items.RepairDetailHyperlink.Title = NStr("vi = 'Hiển thị chi tiết lệnh sửa chữa';
												|ru = 'Показать детали распоряжения на ремонт';
												|en = 'Show R&M request details'; fa = 'نمایش جزئیات درخواست تعمیر و نگهداری';
												|it = 'Visualizzare i dettagli della disposizione per manutenzione';
												|pl = 'Pokaż szczegóły zamówienia na remont';
												|tr = 'Onarım siparişinin ayrıntılarını göster'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRM

&AtClient
Procedure RMOnActivateRow(Item)
	
	AvailabilityOfChangeCommands = False;
	
	If Items.RM.SelectedRows.Count() = 0 Then
		
		Items.MaterialsAndWorksPages.CurrentPage = Items.MaterialsAndWorksListPage;
		Items.LaborCostsPages.CurrentPage = Items.LaborCostsListPage;
		Items.WorkCentersPages.CurrentPage = Items.WorkCentersListPage;
		
		MaterialsAndWorks.Parameters.SetParameterValue("RMType", PredefinedValue("Catalog.RMTypes.EmptyRef"));
		LaborCosts.Parameters.SetParameterValue("RMType", PredefinedValue("Catalog.RMTypes.EmptyRef"));
		WorkCenters.Parameters.SetParameterValue("Asset", PredefinedValue("Catalog.Assets.EmptyRef"));
		
		CurrentRepairOrderOrderSelections = 0;
		
	Else
		
		CurrentData = Items.RM.CurrentData;
		
		CurrentRepairOrderOrderSelections = CurrentData.RMOrderCode;
		
		If CurrentData.MaterialsAndWorksWereChanged Then
			Items.MaterialsAndWorksPages.CurrentPage = Items.MaterialsAndWorksTablePage;
			Items.MaterialsAndWorks.RowFilter = New FixedStructure("RMCode", CurrentData.RMCode);
		Else
			Items.MaterialsAndWorksPages.CurrentPage = Items.MaterialsAndWorksListPage;
			MaterialsAndWorks.Parameters.SetParameterValue("RMType", CurrentData.RMType);
		EndIf;
		
		If CurrentData.LaborCostsWereChanged Then
			Items.LaborCostsPages.CurrentPage = Items.LaborCostsTablePage;
			Items.LaborCosts.RowFilter = New FixedStructure("RMCode", CurrentData.RMCode);
		Else
			Items.LaborCostsPages.CurrentPage = Items.LaborCostsListPage;
			LaborCosts.Parameters.SetParameterValue("RMType", CurrentData.RMType);
		EndIf;
		
		If CurrentData.WorkCentersWereChanged Then
			Items.WorkCentersPages.CurrentPage = Items.WorkCentersTablePage;
			Items.WorkCenters.RowFilter = New FixedStructure("RMCode", CurrentData.RMCode);
		Else
			Items.WorkCentersPages.CurrentPage = Items.WorkCentersListPage;
			WorkCenters.Parameters.SetParameterValue("Asset", CurrentData.Asset);
		EndIf;
		
		AvailabilityOfChangeCommands = CurrentData.ItIsARepairKindLine;
		
	EndIf;
	
	Items.MaterialsAndWorksChange.Enabled = AvailabilityOfChangeCommands;
	Items.TheEffortToChange.Enabled = AvailabilityOfChangeCommands;
	Items.ChangeWorkCenters.Enabled = AvailabilityOfChangeCommands;
	
EndProcedure

&AtClient
Procedure RMRMOrderCodeOnChange(Item)
	
	ResetRepairOrderData = True;
	CurrentData = Items.RM.CurrentData;
	If CurrentData.RMOrderCode <> 0 Then
		
		If CurrentData.RMOrderCode = 1 Then
			
			NewOrder = Object.RMOrders.Add();
			NewOrder.RMOrderCode = MaximumRepairOrderCode;
			NewOrder.Presentation = GetOrderPresentation(NewOrder.RMOrderCode);
			FillPropertyValues(NewOrder, CurrentData, "Asset, StartDate, Duration, UnitOfMeasureOfDuration, Department");
			
			CurrentData.RMOrderCode = NewOrder.RMOrderCode;
			CurrentData.StartDateOfTheRepairOrder = CurrentData.StartDate;
			CurrentData.DurationOfTheRepairOrder = CurrentData.Duration;
			CurrentData.UnitOfMeasurementForTheDurationOfARepairOrder = CurrentData.UnitOfMeasureOfDuration;
			CurrentData.TheDivisionOrderForTheRepair = CurrentData.Department;
			CurrentData.SubmittingARepairOrder = NewOrder.Presentation;
			
			MaximumRepairOrderCode = MaximumRepairOrderCode + 1;
			
			Items.RMRMOrderCode.ChoiceList.Add(NewOrder.RMOrderCode, NewOrder.Presentation);
			
			ResetRepairOrderData = False;
			
		Else
			
			FoundRows = Object.RMOrders.FindRows(New Structure("RMOrderCode", CurrentData.RMOrderCode));
			If FoundRows.Count() <> 0 Then
				OrderLine = FoundRows[0];
				CurrentData.SubmittingARepairOrder = Items.RMRMOrderCode.ChoiceList.FindByValue(CurrentData.RMOrderCode).Presentation;
				CurrentData.StartDateOfTheRepairOrder = OrderLine.StartDate;
				CurrentData.DurationOfTheRepairOrder = OrderLine.Duration;
				CurrentData.UnitOfMeasurementForTheDurationOfARepairOrder = OrderLine.UnitOfMeasureOfDuration;
				CurrentData.TheDivisionOrderForTheRepair = OrderLine.Department;
				ResetRepairOrderData = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ResetRepairOrderData Then
		CurrentData.SubmittingARepairOrder = "";
		CurrentData.StartDateOfTheRepairOrder = Date(1,1,1);
		CurrentData.DurationOfTheRepairOrder = 0;
		CurrentData.TheDivisionOrderForTheRepair = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	EndIf;
	
	CurrentRepairOrderOrderSelections = CurrentData.RMOrderCode;
	
EndProcedure

&AtClient
Procedure RMOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.RM.CurrentData;
	
	If CurrentData.Asset <> CurObjectForOrderSelectionList Then
		
		List = Items.RMRMOrderCode.ChoiceList;
		List.Clear();
		List.Add(1, NStr("vi = '<phiếu yêu cầu sửa chữa mớii>';
						|ru = '<новый заказ>';
						|en = '<new order>'; fa = '<new order>';
						|it = '<ordine nuovo>';
						|pl = '<nowe zamówienie>';
						|tr = '<Yeni düzen>'"));
		
		FoundRows = Object.RMOrders.FindRows(New Structure("Asset", CurrentData.Asset));
		For Each String In FoundRows Do
			List.Add(String.RMOrderCode, String.Presentation);
		EndDo;
		
		CurObjectForOrderSelectionList = CurrentData.Asset;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RMMarkedOnChange(Item)
	
	CurrentData = Items.RM.CurrentData;
	If Not CurrentData.Marked And CurrentData.RMOrderCode <> 0 Then
		CurrentData.RMOrderCode = 0;
		CurrentData.SubmittingARepairOrder = "";
		CurrentData.StartDateOfTheRepairOrder = Date(1,1,1);
		CurrentData.DurationOfTheRepairOrder = 0;
		CurrentData.TheDivisionOrderForTheRepair = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	EndIf;
	
	CurrentRepairOrderOrderSelections = CurrentData.RMOrderCode;
	
EndProcedure

&AtClient
Procedure RMSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.RMPresentation Then
		StandardProcessing = False;
		CurrentData = Items.RM.CurrentData;
		If CurrentData.PictureIndex = 1 Then
			ShowValue(, CurrentData.Asset);
		ElsIf CurrentData.PictureIndex = 2 Then
			ShowValue(, CurrentData.Node);
		Else
			ShowValue(, CurrentData.RMType);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRMOrders

&AtClient
Procedure RMOrdersOnActivateRow(Item)
	
	If Items.RMOrders.CurrentData = Undefined Then
		CurrentRepairOrderRepairSelections = 0;
	Else
		CurrentRepairOrderRepairSelections = Items.RMOrders.CurrentData.RMOrderCode;
	EndIf;
	
EndProcedure

&AtClient
Procedure RMOrdersOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		CurrentData = Items.RMOrders.CurrentData;
		CurrentData.RMOrderCode = RepairOrdersMaximumCode;
		CurrentData.Presentation = GetOrderPresentation(CurrentData.RMOrderCode);
		RepairOrdersMaximumCode = RepairOrdersMaximumCode + 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure RMOrdersStartDateOnChange(Item)
	
	CurrentData = Items.RMOrders.CurrentData;
	
	CompleteSelectionRepairs(
		New Structure("RMOrderCode", CurrentData.RMOrderCode),
		New Structure("StartDateOfTheRepairOrder", CurrentData.StartDate));
	
EndProcedure

&AtClient
Procedure RMOrdersDurationOnChange(Item)
	
	RepairOrdersAreExecutedWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure RMOrdersUnitOfMeasureOfDurationOnChange(Item)
	
	CurrentData = Items.RMOrders.CurrentData;
	
	Filter = New Structure("RMOrderCode", CurrentData.RMOrderCode);
	
	FillingValues = New Structure;
	FillingValues.Insert("DurationOfTheRepairOrder", CurrentData.Duration);
	FillingValues.Insert("UnitOfMeasurementForTheDurationOfARepairOrder", CurrentData.UnitOfMeasureOfDuration);
	
	CompleteSelectionRepairs(Filter, FillingValues);

EndProcedure

&AtClient
Procedure RMOrdersDepartmentOnChange(Item)
	
	CurrentData = Items.RMOrders.CurrentData;
	
	CompleteSelectionRepairs(
		New Structure("RMOrderCode", CurrentData.RMOrderCode),
		New Structure("TheDivisionOrderForTheRepair", CurrentData.Department));
	
EndProcedure

&AtClient
Procedure RMOrdersBeforeDeleteRow(Item, Cancel)
	
	If Items.RMOrders.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	RepairOrdersBeforeRemovalOnServer();
	
	CurObjectForOrderSelectionList = Undefined;
	
EndProcedure

&AtServer
Procedure RepairOrdersBeforeRemovalOnServer()
	
	StructureOfEmptyRepairFields = New Structure;
	StructureOfEmptyRepairFields.Insert("Marked", False);
	StructureOfEmptyRepairFields.Insert("RMOrderCode", 0);
	StructureOfEmptyRepairFields.Insert("SubmittingARepairOrder", "");
	StructureOfEmptyRepairFields.Insert("StartDateOfTheRepairOrder", Date(1, 1, 1));
	StructureOfEmptyRepairFields.Insert("DurationOfTheRepairOrder", 0);
	StructureOfEmptyRepairFields.Insert("UnitOfMeasurementForTheDurationOfARepairOrder", Enums.TimeMeasureUnits.Day);
	StructureOfEmptyRepairFields.Insert("TheDivisionOrderForTheRepair", Catalogs.BusinessStructure.EmptyRef());
	
	For Each CurrentRow In Items.RMOrders.SelectedRows Do
		
		CurrentData = Object.RMOrders.FindByID(CurrentRow);
		CompleteSelectionRepairs(
			New Structure("ItIsARepairKindLine, RMOrderCode", True, CurrentData.RMOrderCode),
			StructureOfEmptyRepairFields);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	AssetMaintenance = Items.RM.CurrentData;
	
	If NewRow Then
		CurrentData = Items.MaterialsAndWorks.CurrentData;
		CurrentData.RMCode = AssetMaintenance.RMCode;
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductsOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPackageOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	AssetMaintenance = Items.RM.CurrentData;
	
	If NewRow Then
		CurrentData = Items.LaborCosts.CurrentData;
		CurrentData.RMCode = AssetMaintenance.RMCode;
	EndIf;
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure WorkCentersOnStartEdit(Item, NewRow, Copy)
	
	AssetMaintenance = Items.RM.CurrentData;
	
	If NewRow Then
		CurrentData = Items.WorkCenters.CurrentData;
		CurrentData.RMCode = AssetMaintenance.RMCode;
	EndIf;
	
EndProcedure

#Region FormNavigationCommandHandlers

&AtClient
Procedure NavigateNext(Command)
	
	FormNavigation(True);
	
EndProcedure

&AtClient
Procedure NavigationBack(Command)
	
	FormNavigation(False);
	
EndProcedure

&AtClient
Procedure NavigationContinueWithOtherSelections(Command)
	
	FormNavigation(True);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkOrdersToRemove(Command)
	SetRowMarkOfRepairTree(False);
EndProcedure

&AtClient
Procedure MarkOrdersSet(Command)
	SetRowMarkOfRepairTree(True);
EndProcedure

&AtClient
Procedure RepairsRepairsToUniteIntoOneOrder(Command)
	
	SelectedRows = Items.RM.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	// Defining an operation object common to the selected lines
	Asset = RM.FindByID(SelectedRows[0]).Asset;
	For Each RowID In SelectedRows Do
		RepairLine = RM.FindByID(RowID);
		If RepairLine.ItIsARepairKindLine And Asset <> RepairLine.Asset Then
			ShowMessageBox(Undefined, NStr("vi = 'Các lệnh được đánh dấu được đưa ra cho các đối tượng sửa chữa khác nhau, 
			|và không thể được thực hiện trong cùng một lệnh sửa chữa';
			|ru = 'Выделенные распоряжения оформляются на разные объекты ремонта,
			|и не могут быть выполнены в рамках одного заказа на ремонт';
			|en = 'Selected references are registered for different R&M objects
			|and cannot be executed within a single R&M order'; fa = 'Selected references are registered for different R&M objects
			|and cannot be executed within a single R&M order';
			|it = 'Le disposizioni selezionate vengono emesse per diversi oggetti di manutenzione,
			|e non possono essere eseguite all''interno dello stesso ordine di manutenzione';
			|pl = 'Wyróżnione zamówienia są wystawiane na różne obiekty naprawy,
			|i nie mogą być wykonane w ramach jednego zlecenia naprawy';
			|tr = 'Özel siparişler farklı onarım nesneleri için verilir 
			|ve tek bir onarım siparişi içinde yürütülemez'"));
			Return;
		EndIf;
	EndDo;
	
	ChoiceList = New ValueList;
	ChoiceList.Add(1, NStr("vi = '<đơn hàng mới>';
							|ru = '<новый заказ>';
							|en = '<new order>'; fa = '<new order>';
							|it = '<ordine nuovo>';
							|pl = '<nowe zamówienie>';
							|tr = '<Yeni düzen>'"));
	
	FoundRows = Object.RMOrders.FindRows(New Structure("Asset", Asset));
	For Each String In FoundRows Do
		ChoiceList.Add(String.RMOrderCode, String.Presentation);
	EndDo;
	
	AddlParameters = New Structure("SelectedRows, FoundRows, Asset", SelectedRows, FoundRows, Asset);
	CallbackDescription = New CallbackDescription("RepairsRepairsToUniteIntoOneOrderCompletion", ThisObject, AddlParameters);
	ChoiceList.ShowChooseItem(CallbackDescription, NStr("vi = 'Chọn phiếu yêu cầu sửa chữa';
														|ru = 'Выберите заказ на ремонт';
														|en = 'Select R&M order'; fa = 'Select R&M order';
														|it = 'Selezionare l''ordine di manutenzione';
														|pl = 'Wybierz zlecenie naprawy';
														|tr = 'Bir onarım siparişi seçin'"));
	
EndProcedure

&AtClient
Procedure RepairsRepairsToUniteIntoOneOrderCompletion(SelectedElement1, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    FoundRows = AdditionalParameters.FoundRows;
    Asset = AdditionalParameters.Asset;
    
    
    SelectedElement = SelectedElement1;
    
    If SelectedElement <> Undefined Then
        
        FillingStructure = New Structure;
        FillingStructure.Insert("Marked");
        FillingStructure.Insert("RMOrderCode");
        FillingStructure.Insert("SubmittingARepairOrder");
        FillingStructure.Insert("StartDateOfTheRepairOrder");
        FillingStructure.Insert("DurationOfTheRepairOrder");
        FillingStructure.Insert("UnitOfMeasurementForTheDurationOfARepairOrder");
        FillingStructure.Insert("TheDivisionOrderForTheRepair");
        
        FillingStructure.Marked = True;
        
        If SelectedElement.Value = 1 Then
            CurrentData =  Items.RM.CurrentData;
            
            NewOrder = Object.RMOrders.Add();
            NewOrder.RMOrderCode = MaximumRepairOrderCode;
            NewOrder.Presentation = GetOrderPresentation(NewOrder.RMOrderCode);
            NewOrder.Asset = Asset;
            FillPropertyValues(NewOrder, CurrentData, "StartDate, Duration, UnitOfMeasureOfDuration, Department");
            
            CurrentData.RMOrderCode = NewOrder.RMOrderCode;
            CurrentData.StartDateOfTheRepairOrder = CurrentData.StartDate;
            CurrentData.DurationOfTheRepairOrder = CurrentData.Duration;
            CurrentData.UnitOfMeasurementForTheDurationOfARepairOrder = CurrentData.UnitOfMeasureOfDuration;
            CurrentData.TheDivisionOrderForTheRepair = CurrentData.Department;
            CurrentData.SubmittingARepairOrder = NewOrder.Presentation;
            
            MaximumRepairOrderCode = MaximumRepairOrderCode + 1;
            CurObjectForOrderSelectionList = Undefined;
            
            FillPropertyValues(FillingStructure, CurrentData);
            
        Else
            
            FoundRows = Object.RMOrders.FindRows(New Structure("RMOrderCode", SelectedElement.Value));
            If FoundRows.Count() = 0 Then
                Return;
            Else
                OrderLine = FoundRows[0];
                FillingStructure.RMOrderCode = SelectedElement.Value;
                FillingStructure.SubmittingARepairOrder = OrderLine.Presentation;
                FillingStructure.StartDateOfTheRepairOrder = OrderLine.StartDate;
                FillingStructure.DurationOfTheRepairOrder = OrderLine.Duration;
                FillingStructure.UnitOfMeasurementForTheDurationOfARepairOrder = OrderLine.UnitOfMeasureOfDuration;
                FillingStructure.TheDivisionOrderForTheRepair = OrderLine.Department;
                
            EndIf;
            
        EndIf;
        
        For Each RowID In SelectedRows Do
            RepairLine = RM.FindByID(RowID);
            If RepairLine.ItIsARepairKindLine Then
                FillPropertyValues(RepairLine, FillingStructure);
            EndIf;
        EndDo;
        
    EndIf;

EndProcedure

&AtClient
Procedure RepairsCollapse(Command)
	ExpandTheTree(0);
EndProcedure

&AtClient
Procedure RepairsToDeployObjects(Command)
	ExpandTheTree(1);
EndProcedure

&AtClient
Procedure RepairsToExpandNodes(Command)
	ExpandTheTree(2);
EndProcedure

&AtClient
Procedure ExpandTheTree(levels, TreeRows=Undefined)
	
	If TreeRows = Undefined Then
		TreeRows = RM.GetItems();
	EndIf;
	
	Collapse = (levels = 0);
	
	For Each TreeRow In TreeRows Do
		If Collapse Then
			Items.RM.Collapse(TreeRow.GetID());
		Else
			Items.RM.Expand(TreeRow.GetID());
			ExpandTheTree(levels-1, TreeRow.GetItems());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksChange(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	CurrentData.MaterialsAndWorksWereChanged = True;
	
	Items.MaterialsAndWorksPages.CurrentPage = Items.MaterialsAndWorksTablePage;
	Items.MaterialsAndWorks.RowFilter = New FixedStructure("RMCode", CurrentData.RMCode);
	
	FillInMaterialsAndWorkOnTypeOfRepair(CurrentData.RMType, CurrentData.RMCode);
	
EndProcedure

&AtClient
Procedure TheEffortToChange(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	CurrentData.LaborCostsWereChanged = True;
	
	Items.LaborCostsPages.CurrentPage = Items.LaborCostsTablePage;
	Items.LaborCosts.RowFilter = New FixedStructure("RMCode", CurrentData.RMCode);
	
	FillInLaborCostsByRepairType(CurrentData.RMType, CurrentData.RMCode);
	
EndProcedure

&AtClient
Procedure ChangeWorkCenters(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	CurrentData.WorkCentersWereChanged = True;
	
	Items.WorkCentersPages.CurrentPage = Items.WorkCentersTablePage;
	Items.WorkCenters.RowFilter = New FixedStructure("RMCode", CurrentData.RMCode);
	
	FillInWorkCentersForObject(CurrentData.Asset, CurrentData.RMCode);
	
EndProcedure

&AtClient
Procedure TheMaterialsAndWorkToClose(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	CurrentData.MaterialsAndWorksWereChanged = False;
	DeleteRelatedData("MaterialsAndWorks", CurrentData.RMCode);
	
	Items.MaterialsAndWorksPages.CurrentPage = Items.MaterialsAndWorksListPage;
	MaterialsAndWorks.Parameters.SetParameterValue("RMType", CurrentData.RMType);
	
EndProcedure

&AtClient
Procedure LaborCostsClose(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	CurrentData.LaborCostsWereChanged = False;
	DeleteRelatedData("LaborCosts", CurrentData.RMCode);
	
	Items.LaborCostsPages.CurrentPage = Items.LaborCostsListPage;
	LaborCosts.Parameters.SetParameterValue("RMType", CurrentData.RMType);
	
EndProcedure

&AtClient
Procedure CloseWorkCenters(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	CurrentData.WorkCentersWereChanged = False;
	DeleteRelatedData("WorkCenters", CurrentData.RMCode);
	
	Items.WorkCentersPages.CurrentPage = Items.WorkCentersListPage;
	WorkCenters.Parameters.SetParameterValue("Asset", CurrentData.Asset);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorkToFillInByTypeOfRepair(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	
	FillInMaterialsAndWorkOnTypeOfRepair(CurrentData.RMType, CurrentData.RMCode);
	
EndProcedure

&AtClient
Procedure FillInLaborCostsByTypeOfRepair(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	
	FillInLaborCostsByRepairType(CurrentData.RMType, CurrentData.RMCode);
	
EndProcedure

&AtClient
Procedure FillInWorkCentersByObject(Command)
	
	If Items.RM.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.RM.CurrentData;
	
	FillInWorkCentersForObject(CurrentData.Asset, CurrentData.RMCode);
	
EndProcedure

&AtClient
Procedure RepairOrdersFillOutTheEvent(Command)
	
	CallbackDescription = New CallbackDescription("RepairOrdersFillOutTheEventCompletion", ThisObject);
	
	OpenForm("Catalog.RMActivities.ChoiceForm",,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RepairOrdersFillOutTheEventCompletion(Result, AdditionalParameters) Export
    
    RMActivity = Result;
    If ValueIsFilled(RMActivity) Then
        For Each String In Items.RMOrders.SelectedRows Do
            If TypeOf(String) <> Type("DynamicListGroupRow") Then
                Object.RMOrders.FindByID(String).RMActivity = RMActivity;
            EndIf;
        EndDo;
    EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMMarked.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMStartDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMRMOrderCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.RMOrderCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", "");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMOrdersAsset.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMOrders.Asset");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksListItemUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "MaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMSubmittingARepairOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Marked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có kế hoạch>';
													|ru = '<не планируется>';
													|en = '<not planned>'; fa = '<not planned>';
													|it = '<non viene programmato>';
													|pl = '<nie planowane>';
													|tr = '<planlı değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMSubmittingARepairOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Marked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.RMOrderCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMRMOrderCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Marked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMPresentation.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMStartDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMDuration.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMUnitOfMeasureOfDuration.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Marked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, True, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMStartDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMStartDateOfTheRepairOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("RM.StartDateOfTheRepairOrder");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMDepartment.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMTheDivisionOrderForTheRepair.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("RM.TheDivisionOrderForTheRepair");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMDuration.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMUnitOfMeasureOfDuration.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheDurationOfTheRepairsOnARepairOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMUnitOfMeasurementForTheDurationOfARepairOrder.Name);

	ElementSelectionGroup_ = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup_.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = ElementSelectionGroup_.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Duration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("RM.DurationOfTheRepairOrder");

	ItemFilter = ElementSelectionGroup_.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.UnitOfMeasureOfDuration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("RM.UnitOfMeasurementForTheDurationOfARepairOrder");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterGeneralRMTypesGeneralRMType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterGeneralRMTypes.GeneralRMType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa điền>';
													|ru = '<не заполнен>';
													|en = '<Not filled in>'; fa = '<Not filled in>';
													|it = '<non compilato>';
													|pl = '<nie wypełniony>';
													|tr = '<doldurulmadı>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RM.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.RMOrderCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("CurrentRepairOrderRepairSelections");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Marked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMOrders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMOrders.RMOrderCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("CurrentRepairOrderOrderSelections");

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMStartDateOfTheRepairOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMUnitOfMeasurementForTheDurationOfARepairOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMTheDivisionOrderForTheRepair.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.Marked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", "");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMOrdersStartDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMOrders.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMOrdersUnitOfMeasureOfDuration.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMOrders.UnitOfMeasureOfDuration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMOrdersDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMOrders.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMDuration.Name);
	ItemField.Field = New DataCompositionField(Items.TheDurationOfTheRepairsOnARepairOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RM.PictureIndex");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = New ValueList();
	ItemFilter.RightValue.Add(1);
	ItemFilter.RightValue.Add(2);
	Item.Appearance.SetParameterValue("Show", False);

EndProcedure

// Returns a view of the repair order
//
&AtClientAtServerNoContext
Function GetOrderPresentation(Code)
	
	OrderPresentation = NStr("vi = 'Số %Code%';
							|ru = '№ %Code%';
							|en = 'No. %Code%'; fa = 'No. %Code%';
							|it = '№ %Code%';
							|pl = 'Nr. %Code%';
							|tr = 'No %Code%'");
	OrderPresentation = StrReplace(OrderPresentation, "%Code%", Format(Code-1, "NG=0"));
	
	Return OrderPresentation;
	
EndFunction

// Processing recursive traversal of the "Repairs" tree to set the passed mark value.
//
&AtClient
Procedure SetRowMarkOfRepairTree(Mark, Val Rows = Undefined)
	
	If Rows = Undefined Then
		Rows = RM.GetItems();
	EndIf;
	
	FillingStructure = New Structure("Marked", Mark);
	If Not Mark Then
		FillingStructure.Insert("RMOrderCode", 0);
		FillingStructure.Insert("SubmittingARepairOrder", "");
	EndIf;
	For Each String In Rows Do
		
		If String.ItIsARepairKindLine Then
			FillPropertyValues(String, FillingStructure);
		Else
			SetRowMarkOfRepairTree(Mark, String.GetItems());
		EndIf;
		
	EndDo;
	
EndProcedure

// Handler for changing the form navigation page
//
// Parameters:
// 		Pagename-String - the Text name of the page control.
//
&AtClient
Procedure FormNavigation(NextCommand=True)
	
	TransitionStructure = New Structure(
		"CurrentPage, NextPage, VisibilityOfBackNavigationCommand, VisibilityOfNextNavigationCommand");
	
	TransitionStructure.CurrentPage = Items.FormNavigationPages.CurrentPage;
	TransitionStructure.NextPage = TransitionStructure.CurrentPage;
	
	TransitionStructure.VisibilityOfNextNavigationCommand = True;
	TransitionStructure.VisibilityOfBackNavigationCommand = True;
	
	If NextCommand Then
		
		If TransitionStructure.CurrentPage = Items.NavigationOptionsPage_ Then
			
			CurObjectForOrderSelectionList = Undefined;
			TransitionStructure.NextPage = Items.OrderNavigationPage;
			
			ChangeFormNavigationPage("PerformRepairPlanning", TransitionStructure);
			
		ElsIf TransitionStructure.CurrentPage = Items.OrderNavigationPage Then
			
			TransitionStructure.VisibilityOfNextNavigationCommand = False;
			TransitionStructure.NextPage = Items.NavigationPageRepairOrders;
			ChangeFormNavigationPage("CreateRepairOrders", TransitionStructure);
			
		ElsIf TransitionStructure.CurrentPage = Items.NavigationPageRepairOrders Then
			
			TransitionStructure.VisibilityOfBackNavigationCommand = False;
			TransitionStructure.NextPage = Items.NavigationOptionsPage_;
			ChangeFormNavigationPage(Undefined, TransitionStructure);
		EndIf;
		
	Else
		
		If TransitionStructure.CurrentPage = Items.NavigationOptionsPage_ Then
			
			TransitionStructure.NextPage = Items.NavigationOptionsPage_;
			TransitionStructure.VisibilityOfBackNavigationCommand = False;
			ChangeFormNavigationPage(Undefined, TransitionStructure);
			
		ElsIf TransitionStructure.CurrentPage = Items.OrderNavigationPage Then
			
			TransitionStructure.NextPage = Items.NavigationOptionsPage_;
			TransitionStructure.VisibilityOfBackNavigationCommand = False;
			ChangeFormNavigationPage(Undefined, TransitionStructure);
			
		ElsIf TransitionStructure.CurrentPage = Items.NavigationPageRepairOrders Then
			
			TransitionStructure.NextPage = Items.OrderNavigationPage;
			TransitionStructure.VisibilityOfNextNavigationCommand = True;
			
			If CreatedOrders.Count() = 0 Then
				
				ChangeFormNavigationPage(Undefined, TransitionStructure);
				
			Else
				
				QueryText = NStr("vi = 'Ở bước xử lý hiện tại, các chứng từ đặt hàng sửa chữa đã được tạo';
								|ru = 'На текущем шаге обработки были созданы документы заказов на ремонт';
								|en = 'R&M order documents were created on the current step'; fa = 'R&M order documents were created on the current step';
								|it = 'Nella fase di elaborazione corrente, sono stati creati i documenti degli ordini di manutenzione';
								|pl = 'Na obecnym etapie przetwarzania zostały stworzone dokumenty zleceń naprawy';
								|tr = 'Geçerli işleme adımında, onarım siparişi belgeleri oluşturuldu'");
				AnswersOptions = New ValueList;
				AnswersOptions.Add("MarkTheOrdersForDeletion", NStr("vi = 'Đánh dấu để xóa các đơn hàng';
																	|ru = 'Пометить заказы на удаление';
																	|en = 'Mark the orders for deletion'; fa = 'Mark the orders for deletion';
																	|it = 'Contrassegnare gli ordini per l''eliminazione';
																	|pl = 'Oznaczaj zlecenia do usuwania';
																	|tr = 'Siparişleri silinmek üzere işaretleme'"));
				AnswersOptions.Add("CancelTransition", NStr("vi = 'Hủy bỏ quay lại';
															|ru = 'Отменить переход назад';
															|en = 'Cancel going back'; fa = 'Cancel going back';
															|it = 'Annullare il passaggio indietro';
															|pl = 'Anulować przejście z powrotem';
															|tr = 'Geriye Dönük Geçişi Geri Al'"));
				ShowQueryBox(
					New CallbackDescription("ChangeFormNavigationPage", ThisForm, TransitionStructure),
					QueryText,
					AnswersOptions);
				
			EndIf;
			
			CurObjectForOrderSelectionList = Undefined;
			
		EndIf;
		
	EndIf;
	
	
EndProcedure

&AtClient
Procedure ChangeFormNavigationPage(Actions=Undefined, AdditionalParameters=Undefined) Export
	
	StructureOfActions = New Structure(Actions);
	
	If StructureOfActions.Property("CreateRepairOrders") Then
		HasErrors = False;
		CreateRepairOrders(HasErrors);
		
		If HasErrors Then
			StructureOfActions.Insert("CancelTransition");
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("PerformRepairPlanning") Then
		
		PerformRepairPlanning();
		
	EndIf;
	
	If StructureOfActions.Property("MarkTheOrdersForDeletion") Then
		HasErrors = False;
		DeleteRepairOrders(HasErrors);
		
		If HasErrors Then
			StructureOfActions.Insert("CancelTransition");
		EndIf;
		
	EndIf;
	
	If Not StructureOfActions.Property("CancelTransition") Then
		
		Items.NavigationBack.Visible = AdditionalParameters.VisibilityOfBackNavigationCommand;
		Items.NavigateNext.Visible = AdditionalParameters.VisibilityOfNextNavigationCommand;
		Items.NavigationContinueWithOtherSelections.Visible = Not AdditionalParameters.VisibilityOfNextNavigationCommand;
		Items.FormNavigationPages.CurrentPage = AdditionalParameters.NextPage;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReflectSimpleSelectionInLayoutSelections(FieldName, Value)
	
	IsList = (TypeOf(Value) = Type("ValueList"));
	
	SearchValue = New DataCompositionField(FieldName);
	For Each FilterElement In FilterSettingsComposer.Settings.Filter.Items Do
		
		If FilterElement.LeftValue = SearchValue Then
			
			UserSettingItem = FilterSettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
			If Not UserSettingItem = Undefined Then
				
				ValueIsFilled = ?(IsList, Value.Count()<>0, Not Value.IsEmpty());
				UserSettingItem.Use = (Value <> Undefined) And ValueIsFilled;
				If UserSettingItem.Use Then
					
					VariantOfComparisonType = DataCompositionComparisonType.Equal;
					
					If IsList Then
						VariantOfComparisonType = DataCompositionComparisonType.InListByHierarchy;
					EndIf;
					
					UserSettingItem.ComparisonType  = VariantOfComparisonType;
					UserSettingItem.RightValue = Value;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the request text obtained from the layout of the processing layout data
//
&AtServer
Function GetRequestWithDataLayoutSelections()
	
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	
	DataProcessor = FormAttributeToValue("Object");
	DataCompositionSchema = DataProcessor.GetTemplate("DataLayoutForServerFilters");
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, FilterSettingsComposer.GetSettings(), , , , False, );
	
	Query = New Query(DataCompositionTemplate.DataSets.RequestForItemsUnderRepair.Query);
	
	For Each LayoutParameter In DataCompositionTemplate.ParameterValues Do
		
		Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
		
	EndDo;
	
	Return Query;
	
EndFunction

// Initializes the custom selection settings linker
//
&AtServer
Procedure InitializeSettingsComposerForSelections()
	
	DataProcessor = FormAttributeToValue("Object");
	DataCompositionSchema = DataProcessor.GetTemplate("DataLayoutForServerFilters");
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	FilterSettingsComposer.Initialize(SettingsSource);
	FilterSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	
EndProcedure

// Performs repair planning for objects selected on the parameters page
//
&AtServer
Procedure PerformRepairPlanning()
	
	FillInPlannedObjectsBySpecifiedSelection();
	
	DataProcessorObject2 = FormAttributeToValue("Object");
	DataProcessorObject2.CalculateRepairPlan();
	ValueToFormAttribute(DataProcessorObject2, "Object");
	
	FillInRepairsBasedOnProcessingData();
	
EndProcedure

// Fills in the table part of the "repair Objects" processing for the selection set on the parameters page.
//
&AtServer
Procedure FillInPlannedObjectsBySpecifiedSelection()
	
	// Filling in repair facilities for planning
	Object.ObjectsForRMScheduling.Clear();
	
	Query = GetRequestWithDataLayoutSelections();
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Object.ObjectsForRMScheduling.Load(Result.Unload());
	
	// Filling in general types of repairs for planning
	Object.GeneralRMTypesForPlanning.Load(
		FilterGeneralRMTypes.Unload(
			FilterGeneralRMTypes.FindRows(
				New Structure("Marked", True)
			),
			"GeneralRMType"));
	
	// Filling in the frequencies for planning
	Object.PlanningFrequency_.Load(
		FilterSchedulingFrequencies.Unload(
			FilterSchedulingFrequencies.FindRows(
				New Structure("Marked", True)
			),
			"PlanningFrequency"));
	
EndProcedure

// Fills in the tree of the "Repairs" form according to the data in the "Repairs" tabular part of the processing"
//
&AtServer
Procedure FillInRepairsBasedOnProcessingData()
	
	FillOutPresentationTableOfRepairOrders();
	
	TreeItems = RM.GetItems();
	TreeItems.Clear();
	
	AddedObjects = New Map;
	
	OrderSelectionList = Items.RMRMOrderCode.ChoiceList;
	OrderSelectionList.Clear();
	
	MatchingOrderPresentations = New Map;
	
	MaximumRepairOrderCode = 2;
	
	For Each ProcessingString In Object.RM Do
		
		ObjectUnderRepair = ?(ValueIsFilled(ProcessingString.Node), ProcessingString.Node, ProcessingString.Asset);
		
		ObjectStrings = AddedObjects.Get(ProcessingString.Asset);
		If ObjectStrings = Undefined Then
			TreeRow = TreeItems.Add();
			TreeRow.PictureIndex = 1;
			TreeRow.Asset = ProcessingString.Asset;
			TreeRow.Presentation = String(ProcessingString.Asset);
			
			ObjectStrings = TreeRow.GetItems();
			AddedObjects.Insert(ProcessingString.Asset, ObjectStrings);
		EndIf;
		
		NodeLines = AddedObjects.Get(ObjectUnderRepair);
		If NodeLines = Undefined Then
			TreeRow = ObjectStrings.Add();
			TreeRow.PictureIndex = 2;
			TreeRow.Node = ProcessingString.Node;
			TreeRow.Presentation = String(ProcessingString.Node);
			
			NodeLines = TreeRow.GetItems();
			AddedObjects.Insert(ObjectUnderRepair, NodeLines);
		EndIf;
		
		RepairLine = NodeLines.Insert(0);
		RepairLine.Marked = True;
		RepairLine.PictureIndex = ?(ProcessingString.RMCycle, 4, 3);
		RepairLine.Presentation = String(ProcessingString.RMType);
		RepairLine.ItIsARepairKindLine = True;
		FillPropertyValues(RepairLine, ProcessingString);
		
		OrderPresentation = MatchingOrderPresentations.Get(RepairLine.RMOrderCode);
		If OrderPresentation = Undefined Then
			OrderPresentation = GetOrderPresentation(RepairLine.RMOrderCode);
			MatchingOrderPresentations.Insert(RepairLine.RMOrderCode, OrderPresentation);
		EndIf;
		RepairLine.SubmittingARepairOrder = OrderPresentation;
		
	EndDo;
	
	TreeObject_ = FormAttributeToValue("RM");
	TreeObject_.Rows.Sort("ItIsARepairKindLine Desc, StartDate", True);
	ValueToFormAttribute(TreeObject_, "RM");
	
	FilterStructure1 = New Structure("RMOrderCode");
	FillingStructure = New Structure("StartDateOfTheRepairOrder, DurationOfTheRepairOrder, UnitOfMeasurementForTheDurationOfARepairOrder, TheDivisionOrderForTheRepair");
	
	MaximumRepairOrderCode = 2;
	For Each OrderLine In Object.RMOrders Do
		
		FillPropertyValues(FilterStructure1, OrderLine);
		
		FillingStructure.StartDateOfTheRepairOrder = OrderLine.StartDate;
		FillingStructure.DurationOfTheRepairOrder = OrderLine.Duration;
		FillingStructure.UnitOfMeasurementForTheDurationOfARepairOrder = OrderLine.UnitOfMeasureOfDuration;
		FillingStructure.TheDivisionOrderForTheRepair = OrderLine.Department;
		CompleteSelectionRepairs(FilterStructure1, FillingStructure);
		
		MaximumRepairOrderCode = Max(MaximumRepairOrderCode, OrderLine.RMOrderCode);
		
	EndDo;
	
	MaximumRepairOrderCode = MaximumRepairOrderCode + 1;
	
EndProcedure

// Fills in the "Repairs" processing table by recursively traversing the data in the "Repairs" tree of the form.
//
&AtServer
Procedure CompleteRepairs(CurrentObject, TreeRows=Undefined)
	
	If TreeRows = Undefined Then
		CurrentObject.RM.Clear();
		TreeRows = RM.GetItems();
	ElsIf TreeRows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TreeRow In TreeRows Do
		
		If TreeRow.ItIsARepairKindLine Then
			NewRow = CurrentObject.RM.Add();
			FillPropertyValues(NewRow, TreeRow);
		Else
			CompleteRepairs(CurrentObject, TreeRow.GetItems());
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the "View" column in the "repair Orders" processing table"
//
&AtServer
Procedure FillOutPresentationTableOfRepairOrders()
	
	RepairOrdersMaximumCode = 0;
	For Each RMOrder In Object.RMOrders Do
		RMOrder.Presentation = GetOrderPresentation(RMOrder.RMOrderCode);
		If RepairOrdersMaximumCode < RMOrder.RMOrderCode Then
			RepairOrdersMaximumCode = RMOrder.RMOrderCode;
		EndIf;
	EndDo;
	
	RepairOrdersMaximumCode = RepairOrdersMaximumCode + 1;
	
EndProcedure // Fill in the representation of the table of the order of the repair()

// Fills in the rows of the selection repair tree with the passed values
//
&AtServer
Procedure CompleteSelectionRepairs(Filter, FillingValues, Val Rows=Undefined)
	
	If Rows = Undefined Then
		
		TreeObject_ = FormAttributeToValue("RM");
		If TreeObject_.Rows.FindRows(Filter, True).Count() = 0 Then
			Return;
		EndIf;
		
		Rows = RM.GetItems();
	EndIf;
	
	For Each String In Rows Do
		
		If String.ItIsARepairKindLine Then
			
			If MatchesFilter(String, Filter) Then
				FillPropertyValues(String, FillingValues);
			EndIf;
			
		Else
			CompleteSelectionRepairs(Filter, FillingValues, String.GetItems());
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks whether the values of the tree string match the values of the passed structure
//
&AtServer
Function MatchesFilter(Data, FilterStructure1)
	
	For Each KeyValue In FilterStructure1 Do
		If Data[KeyValue.Key] <> KeyValue.Value Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Fills in the "Materials and works" table part for the current repair line
//
&AtServer
Procedure FillInMaterialsAndWorkOnTypeOfRepair(RMType, RMCode)
	
	// Clear Selection lines
	DeleteRelatedData("MaterialsAndWorks", RMCode);
	
	// Fill in according to the type of repair
	Query = New Query(
		"SELECT
		|	RMTypesMaterialsAndWorks.Products AS Products,
		|	RMTypesMaterialsAndWorks.Characteristic AS Characteristic,
		|	RMTypesMaterialsAndWorks.Package AS Package,
		|	RMTypesMaterialsAndWorks.NumberOfPackages AS NumberOfPackages,
		|	RMTypesMaterialsAndWorks.Count AS Count,
		|	&RMCode AS RMCode,
		|	CASE
		|		WHEN RMTypesMaterialsAndWorks.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|				OR RMTypesMaterialsAndWorks.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|				OR RMTypesMaterialsAndWorks.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed
		|FROM
		|	Catalog.RMTypes.MaterialsAndWorks AS RMTypesMaterialsAndWorks
		|WHERE
		|	RMTypesMaterialsAndWorks.Ref = &RMType");
	
	Query.SetParameter("RMType", RMType);
	Query.SetParameter("RMCode", RMCode);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		FillPropertyValues(Object.MaterialsAndWorks.Add(), Selection);
	EndDo;
	
EndProcedure

// Fills in the "Labor costs" table part for the current repair line
//
&AtServer
Procedure FillInLaborCostsByRepairType(RMType, RMCode)
	
	// Clear Selection lines
	DeleteRelatedData("LaborCosts", RMCode);
	
	// Fill in according to the type of repair
	Query = New Query(
		"SELECT
		|	&RMCode AS RMCode,
		|	RMTypesLaborCosts.WorkKind AS WorkKind,
		|	RMTypesLaborCosts.Count AS Count
		|FROM
		|	Catalog.RMTypes.LaborCosts AS RMTypesLaborCosts
		|WHERE
		|	RMTypesLaborCosts.Ref = &RMType");
	
	Query.SetParameter("RMType", RMType);
	Query.SetParameter("RMCode", RMCode);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		FillPropertyValues(Object.LaborCosts.Add(), Selection);
	EndDo;
	
EndProcedure

// Fills in the "Work centers" table part for the current repair line
//
&AtServer
Procedure FillInWorkCentersForObject(Asset, RMCode)
	
	// Clear Selection lines
	DeleteRelatedData("WorkCenters", RMCode);
	
	// Fill in according to the data of the repair object
	Query = New Query(
		"SELECT
		|	&RMCode AS RMCode,
		|	WorkCenters.WorkCenter AS WorkCenter
		|FROM
		|	Catalog.Assets.WorkCenters AS WorkCenters
		|WHERE
		|	WorkCenters.Ref = &Asset");
	
	Query.SetParameter("Asset", Asset);
	Query.SetParameter("RMCode", RMCode);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		FillPropertyValues(Object.WorkCenters.Add(), Selection);
	EndDo;
	
EndProcedure

// Deletes the associated data from the specified table
//
&AtServer
Procedure DeleteRelatedData(TableName, RMCode)
	
	Table = Object[TableName];
	For Each String In Table.FindRows(New Structure("RMCode", RMCode)) Do
		Table.Delete(String);
	EndDo;
	
EndProcedure

// Creates repair orders based on processing data
//
&AtServer
Procedure CreateRepairOrders(Cancel = False)
	
	ComplianceWithCurrentCodes = New Map;
	CheckFillingOfRepairs(Cancel, ComplianceWithCurrentCodes);
	CheckCompletionOfRepairOrders(Cancel, ComplianceWithCurrentCodes);
	
	If Cancel Then
		Return;
	EndIf;
	
	CreatedOrders.Clear();
	
	DataProcessorObject2 = FormAttributeToValue("Object");
	
	CompleteRepairs(DataProcessorObject2);
	
	ArrayOfOrdersMarkedForDeletion = TheOrdersToBeDeleted.UnloadValues();
	ExecutionStructure = DataProcessorObject2.GenerateRepairOrders(ArrayOfOrdersMarkedForDeletion);
	
	TheOrdersToBeDeleted.LoadValues(ArrayOfOrdersMarkedForDeletion);
	CreatedOrders.LoadValues(ExecutionStructure.ArrayOfRepairOrders);
	
	CreatedRepairOrders.Parameters.SetParameterValue("AnArrayOfOrders", ExecutionStructure.ArrayOfRepairOrders);
	
	ErrorTemplate = NStr("vi = 'Khi kết chuyển chứng từ %OrderDocument% có lỗi - %ErrorsCount% lỗi.
	|Chứng từ không được kết chuyển';
	|ru = 'При проведении документа %OrderDocument% обнаружены ошибки - %ErrorsCount% шт.
	|Документ не проведен';
	|en = 'Errors are detected while posting document %OrderDocument% - %ErrorsCount%.
	|The document is not posted'; fa = 'Errors are detected while posting document %OrderDocument% - %ErrorsCount%.
	|The document is not posted';
	|it = 'Durante l''immissione del documento %OrderDocument% si sono verificati gli errori - %ErrorsCount%pz.
	|Documento non è registrato';
	|pl = 'Podczas zatwierdzania dokumenty %OrderDocument% wynikły błędy - %ErrorsCount% szt.
	|Dokument nie został zatwierdzony';
	|tr = '%OrderDocument% belgesinde hatalar bulundu -%ErrorsCount% prç
	| Belge yürütülmedi'");
	
	For Each KeyAndValue In ExecutionStructure.OverriddenMessages Do
		
		RepairOrderLink = KeyAndValue.Key;
		ErrorsArray = KeyAndValue.Value;
		If ErrorsArray.Count() <> 0 Then
			
			ErrorText = StrReplace(ErrorTemplate, "%OrderDocument%", RepairOrderLink);
			ErrorText = StrReplace(ErrorText, "%ErrorsCount%", ErrorsArray.Count());
			
			CommonClientServer.MessageToUser(
				ErrorText,
				RepairOrderLink);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes created repair orders
//
&AtServer
Procedure DeleteRepairOrders(Cancel=False)
	
	ArrayOfDeletedItems = New Array;
	
	BeginTransaction();
	Try
		
		For Each ListItem In CreatedOrders Do
			
			Ref = ListItem.Value;
			DocumentObject_ = Ref.GetObject();
			DocumentObject_.SetDeletionMark(True);
			Try
				DocumentObject_.Write();
			Except
				Cancel = True;
				Raise;
			EndTry;
			ArrayOfDeletedItems.Add(Ref);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		EventName = 
			NStr("vi = 'Kế hoạch sửa chữa';
				|ru = 'Планирование ремонтных работ';
				|en = 'Create planned R&M orders'; fa = 'ایجاد سفارش‌های برنامه‌ریزی‌شده تعمیر و نگهداری';
				|it = 'Pianificazione dei lavori di riparazione';
				|pl = 'Planowanie prac remontowych';
				|tr = 'Onarım çalışmalarını planlama'", Common.DefaultLanguageCode())
			+ "."
			+ NStr("vi = 'Xóa các chứng từ đã tạo từ trước';
					|ru = 'Удаление ранее созданных документов';
					|en = 'Deleting previously created documents'; fa = 'Deleting previously created documents';
					|it = 'Cancellazione dei documenti precedentemente creati';
					|pl = 'Usunięcie wcześniej utworzonych dokumentów';
					|tr = 'Önceden oluşturulmuş belgeleri silme'", Common.DefaultLanguageCode());
			
		WriteLogEvent(
			EventName,
			EventLogLevel.Error,,,
			ErrorText);
			
		Raise ErrorText;
		
	EndTry;
	
	For Each OrderDocument In ArrayOfDeletedItems Do
		TheOrdersToBeDeleted.Add(OrderDocument);
	EndDo;
	
EndProcedure

// Checks whether repairs are filled in correctly
//
&AtServer
Procedure CheckFillingOfRepairs(Cancel, CurrentCodesForRepairOrders, Rows=Undefined)
	
	If Rows = Undefined Then
		Rows = RM.GetItems();
	EndIf;
	
	ErrorTemplate = NStr("vi = 'Trường ""%Field%"" trong dòng của bảng ""Phiếu yêu cầu sửa chữa"" không được điền';
						|ru = 'Не заполнено поле ""%Field%"" в строке таблицы ""Распоряжения на ремонт""';
						|en = '""%Field%"" is required in the ""R&M requests"" table'; fa = '""%Field%"" is required in the ""R&M requests"" table';
						|it = 'Il campo ""%Field%"" nella riga della tabella ""Disposizioni di manutenzione"" non è compilato';
						|pl = 'Nie jest wypełnione pole ""%Field%"" w wierszu tabeli ""Zamówienia na naprawę""';
						|tr = '""Onarım Siparişleri"" tablosunun satırındaki ""%Field%"" alanı doldurulmuyor'");
	
	For Each RepairLine In Rows Do
		
		If RepairLine.ItIsARepairKindLine Then
			
			If RepairLine.Marked Then
				
				If ValueIsFilled(RepairLine.RMOrderCode) And RepairLine.RMOrderCode <> 1 Then
					CurrentCodesForRepairOrders.Insert(RepairLine.RMOrderCode, True);
				Else
					CommonClientServer.MessageToUser(
						StrReplace(ErrorTemplate, "%Field%", NStr("vi = 'Đơn hàng sửa chữa';
																	|ru = 'Заказ на ремонт';
																	|en = 'R&M order'; fa = 'سفارش تعمیر و نگهداری';
																	|it = 'Ordine di manutenzione';
																	|pl = 'Zamówienie naprawy';
																	|tr = 'Bakım-onarım siparişi'")),,
						"RM",,
						Cancel);
					
				EndIf;
				
			EndIf;
			
		Else
			
			CheckFillingOfRepairs(Cancel, CurrentCodesForRepairOrders, RepairLine.GetItems());
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks whether repair orders are filled in correctly
//
&AtServer
Procedure CheckCompletionOfRepairOrders(Cancel, CurrentCodesForRepairOrders)
	
	ErrorTemplate = NStr("vi = 'Trường ""%Field%"" không được điền';
						|ru = 'Не заполнено поле ""%Field%""';
						|en = '""%Field%"" is required'; fa = '""%Field%"" is required';
						|it = 'Il campo ""%Field%"" non è compilato';
						|pl = 'Nie jest wypełnione pole ""%Field%""';
						|tr = '""%Field%"" alanı doldurulmadı'");
	ErrorAddressTemplate = NStr("vi = 'trong dòng %LineNumber% của bảng ""Đơn sửa chữa""';
								|ru = 'в строке %LineNumber% таблицы ""Заказы на ремонт""';
								|en = 'in line %LineNumber% of the ""R&M orders"" table'; fa = 'in line %LineNumber% of the ""R&M orders"" table';
								|it = 'nella riga %LineNumber% della tabella ""Ordini di manutenzione""';
								|pl = 'w wierszu %LineNumber% tabeli ""Zlecenia naprawy""';
								|tr = '""Onarım Emirleri"" tablosunun %LineNumber% satırında'");
	
	For Each RMOrder In Object.RMOrders Do
		
		If CurrentCodesForRepairOrders.Get(RMOrder.RMOrderCode) <> Undefined Then // There are repairs for this order
			
			ErrorAddress = StrReplace(ErrorAddressTemplate, "%LineNumber%", RMOrder.LineNumber);
			
			If Not ValueIsFilled(RMOrder.StartDate) Then
				
				CommonClientServer.MessageToUser(
					StrReplace(ErrorTemplate, "%Field%", NStr("vi = 'Ngày bắt đầu';
																|ru = 'Дата начала';
																|en = 'Start date'; fa = 'تاریخ شروع';
																|it = 'Data di inizio';
																|pl = 'Data rozpoczęcia';
																|tr = 'Başlangıç tarihi'")) + ErrorAddress,,
					CommonClientServer.PathToTabularSection("Object.RMOrders", RMOrder.LineNumber, "StartDate"),,
					Cancel);
				
			EndIf;
			
			If Not ValueIsFilled(RMOrder.UnitOfMeasureOfDuration) Then
				
				CommonClientServer.MessageToUser(
					StrReplace(ErrorTemplate, "%Field%", NStr("vi = 'Đơn vị tính thời lượng';
																|ru = 'Ед. изм. длительности';
																|en = 'Duration Unit'; fa = 'واحد مدت';
																|it = 'Unità di misura di durata';
																|pl = 'Jednostka miary długotrwałości';
																|tr = 'Süre birimi'")) + ErrorAddress,,
					CommonClientServer.PathToTabularSection("Object.RMOrders", RMOrder.LineNumber, "UnitOfMeasureOfDuration"),,
					Cancel);
				
			EndIf;
			
			If Not ValueIsFilled(RMOrder.Department) Then
				
				CommonClientServer.MessageToUser(
					StrReplace(ErrorTemplate, "%Field%", NStr("vi = 'Bộ phận';
																|ru = 'Подразделение';
																|en = 'Business unit'; fa = 'Business unit';
																|it = 'Reparto';
																|pl = 'Business unit';
																|tr = 'Departman'")) + ErrorAddress,,
					CommonClientServer.PathToTabularSection("Object.RMOrders", RMOrder.LineNumber, "Department"),,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RepairOrdersAreExecutedWhenChangesAreMadeOnServer()

	CurrentData = Object.RMOrders.FindByID(Items.RMOrders.CurrentRow);
	
	Filter = New Structure("RMOrderCode", CurrentData.RMOrderCode);
	
	FillingValues = New Structure;
	FillingValues.Insert("DurationOfTheRepairOrder", CurrentData.Duration);
	FillingValues.Insert("UnitOfMeasurementForTheDurationOfARepairOrder", CurrentData.UnitOfMeasureOfDuration);
	
	CompleteSelectionRepairs(Filter, FillingValues);
	
EndProcedure

#EndRegion
