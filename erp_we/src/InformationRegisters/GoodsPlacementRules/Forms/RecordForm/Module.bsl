#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	ItemsType = Common.ObjectAttributeValue(Record.WarehouseGroupOfProducts, "ItemsType");

	If ItemsType = Enums.ItemsTypes.OwnGoods
		And Not ValueIsFilled(Record.WarehouseGroupOfPackages) Then
		Location = "StorageUnits";
		Items.WarehouseGroupOfPackages.Enabled = False;
	Else ValueIsFilled(Record.WarehouseGroupOfPackages); 
		Location = "Packages";
		Items.WarehouseGroupOfPackages.Enabled = True;
	EndIf;
	
	If Record.SourceRecordKey.IsEmpty() Then
		OnReadCreateAtServer();
	Else
		SetAvailability();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	OnReadCreateAtServer();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If ItemsType = Enums.ItemsTypes.OwnGoods
		And Location = "Packages"
		And Not ValueIsFilled(Record.WarehouseGroupOfPackages) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Nhóm đóng gói""';
							|ru = 'Поле ""Складская группа упаковок"" не заполнено';
							|en = '""Warehouse group of packaging units"" is not filled in'; fa = '""Warehouse group of packaging units"" is not filled in';
							|it = 'Il campo ""Gruppo di imballaggio del magazzino ""non è compilato';
							|pl = 'Pole ""Grupa magazynowa opakowań"" nie jest wypełnione';
							|tr = '""Paketleme ünitesi ambar grubu"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(MessageText,,"WarehouseGroupOfPackages","Record",Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_GoodsPlacementRules", WriteParameters);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Record.Warehouse,Record.Premise));
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Record.Warehouse,Record.Premise));

EndProcedure

&AtClient
Procedure WarehouseGroupOfProductsOnChange(Item)
	SetAvailability();
	
	If Not Items.WarehouseGroupOfPackages.Enabled Then
		Record.WarehouseGroupOfPackages = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	SetAvailability();
	If Not Items.WarehouseGroupOfPackages.Enabled Then
		Record.WarehouseGroupOfPackages = Undefined;
	EndIf;
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Record.Warehouse,Record.Premise));
	SetAvailability();
EndProcedure

&AtServer
Procedure SetAvailability()
	
	SetPrivilegedMode(True);
	ItemsType = Common.ObjectAttributeValue(Record.WarehouseGroupOfProducts, "ItemsType");
	SetPrivilegedMode(False);
	Items.WarehouseGroupOfPackages.Enabled = ItemsType = Enums.ItemsTypes.OwnGoods And Location = "Packages";
	Items.Location.Enabled = (ItemsType = Enums.ItemsTypes.OwnGoods)
		And AccessRight("Update", Metadata.InformationRegisters.GoodsPlacementRules);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WarehouseGroupOfPackages.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Location");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Packages";

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	                                                                      
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Record.WarehouseGroupOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.WarehousePackageGroups.EmptyRef();
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

#EndRegion
