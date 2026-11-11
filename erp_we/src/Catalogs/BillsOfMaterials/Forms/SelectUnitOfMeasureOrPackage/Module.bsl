
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("PackagingUnitOfMeasure", PackagingUnitOfMeasure);
	
	FillPackingTree();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPackagesAndUnitsOfMeasure

&AtClient
Procedure PackagesAndUnitsOfMeasureSelection(Item, RowSelected, Field, StandardProcessing)
	
	CheckCompleteSelection(RowSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	CheckCompleteSelection(Items.PackagesAndUnitsOfMeasure.CurrentRow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillPackingTree()
	
	PackagesAndUnitsOfMeasure.GetItems().Clear();
	
	Query = New Query;
	Query.Text = Catalogs.BillsOfMaterials.RequestTextAvailablePackagingSpecificationsForProductType();
	Query.SetParameter("UseItemPackages", GetFunctionalOption("UseItemPackages"));
	
	QueryResults = Query.ExecuteBatch();
	
	// Unit
	If Not QueryResults[0].IsEmpty() Then
		
		UnitString_ = PackagesAndUnitsOfMeasure.GetItems().Add();
		UnitString_.Ref = NStr("vi = 'Đơn vị tính';
								|ru = 'Единицы измерения';
								|en = 'Units of measure'; fa = 'واحدهای اندازه‌گیری';
								|it = 'Unità di misura';
								|pl = 'Jednostki miary';
								|tr = 'Ölçü birimleri'");
		
		SelectingUnitOfMeasurement = QueryResults[0].Select();
		While SelectingUnitOfMeasurement.Next() Do
			NewRow = UnitString_.GetItems().Add();
			NewRow.Ref = SelectingUnitOfMeasurement.Ref;
			SetCurTreeLine(NewRow);
		EndDo;
	
	EndIf;
	
	// Packages
	If Not QueryResults[1].IsEmpty() Then
	
		PackingString = PackagesAndUnitsOfMeasure.GetItems().Add();
		PackingString.Ref = NStr("vi = 'Bộ đóng gói';
								|ru = 'Упаковки';
								|en = 'Packaging units'; fa = 'واحدهای بسته‌بندی';
								|it = 'Imballaggi';
								|pl = 'Packaging units';
								|tr = 'Paketleme ünitesi'");
		
		PackagingGroups = New Map;
		PackageSelection = QueryResults[1].Select(QueryResultIteration.ByGroupsWithHierarchy);
		While PackageSelection.Next() Do
			
			PackagingGroup = PackagingGroups.Get(PackageSelection.PackagingGroup);
			If PackagingGroup = Undefined Then
				PackagingGroup = PackingString.GetItems().Add();
				PackagingGroup.Ref = PackageSelection.PackagingGroup;
				PackagingGroups.Insert(PackageSelection.PackagingGroup, PackagingGroup);
			EndIf;
			AddEntryToPackingTree(PackagingGroup, PackageSelection);
			
		EndDo;
	
	EndIf;
	
EndProcedure

// Adds an entry to the package tree
// 
// Parameters:
// 	ParentRow - FormDataTreeItem - parent string:
// 	Selection - QueryResultSelection - Selection:
//
&AtServer
Procedure AddEntryToPackingTree(ParentRow, Selection)
	
	NewRow = ParentRow.GetItems().Add();
	
	FillPropertyValues(NewRow, Selection);
	
	SetCurTreeLine(NewRow);
	
	NestedSelection_ = Selection.Select(QueryResultIteration.ByGroupsWithHierarchy);
	While NestedSelection_.Next() Do
		AddEntryToPackingTree(NewRow, NestedSelection_);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetCurTreeLine(NewRow)
	
	If PackagingUnitOfMeasure.IsEmpty() Then
		Return;
	EndIf;
	
	If NewRow.Ref = PackagingUnitOfMeasure Then
		Items.PackagesAndUnitsOfMeasure.CurrentRow = NewRow.GetID();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckCompleteSelection(RowSelected)
	
	CurrentData = PackagesAndUnitsOfMeasure.FindByID(RowSelected);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(CurrentData.Ref) = Type("String")
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.PackagingGroups") Then
		Return;
	EndIf;
	
	Close(CurrentData.Ref);
	
EndProcedure

#EndRegion