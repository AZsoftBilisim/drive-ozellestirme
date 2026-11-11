
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.Products) Then
		
		SetPrivilegedMode(True);
		ItemsType = Common.ObjectAttributeValue(Parameters.Products, "ItemsType");
		ThisIsWork = ItemsType = Enums.ItemsTypes.Work_5;
		SetPrivilegedMode(False);
		
	EndIf;
	
	// If a selection of groups and elements is used, then the form is called from the platform search.
	If Not Parameters.Property("Source")
		And Not Parameters.Property("ObjectName")
		And ValueIsFilled(Parameters.Products) Then
		Raise NStr("vi = 'Không chọn mục đích từ biểu mẫu. Cần tùy chỉnh liên kết tham số chọn';
					|ru = 'Не реализован выбор назначения из этой формы. Необходимо настроить связи параметров выбора';
					|en = 'Assignment is not selected from this form. Set up selection parameter links'; fa = 'Assignment is not selected from this form. Set up selection parameter links';
					|it = 'La scelta dell''assegnazione da questo modello non è implementata. È necessario impostare i collegamenti dei parametri di scelta';
					|pl = 'Wybór przeznaczenia z tego formularza nie jest zrealizowany. Należy ustawić połączenia parametrów wyboru';
					|tr = 'Bu formdan atama seçimi uygulanmadı. Seçim parametresi bağlantılarının ayarlanması gerekli'"); 	
	EndIf; 
	
	Parameters.Property("Source", Source);
	Parameters.Property("ObjectName", ObjectName);
	Parameters.Property("ReferenceOrder", ReferenceOrder);
	Parameters.Property("Cell", Cell);
	Parameters.Property("OperationKind", OperationKind);
	Parameters.Property("DestinationSelectionMode", ChoiceMode);
	
	If ValueIsFilled(ObjectName) Then
		If ObjectName = "DataProcessor.GoodsQuantityCheckInDocument" 
			Or ObjectName = "DataProcessor.GoodsQuantityCheckInGoodsReceiptNote" Then
			Items.Demand.Visible = False;
			Items.Supplied.Visible = False;
		EndIf;	
	ElsIf Source <> Undefined Then
		If TypeOf(Source) = Type("DocumentRef.GoodsReceiptNote") 
				And ValueIsFilled(ReferenceOrder)
			Or TypeOf(Source) = Type("DocumentRef.GoodsPickingPlacement") 
			Or TypeOf(Source) = Type("DocumentRef.GoodsIssueNote") Then
			Items.Demand.Visible = True;
		ElsIf TypeOf(Source) = Type("DocumentRef.InventoryRecount") 
			Or ChoiceMode = "All" Then
		Else
			Items.Demand.Visible = True;
			Items.Supplied.Visible = True;
		EndIf;	
	Else
		Items.Demand.Visible = False;
		Items.Supplied.Visible = False;
	EndIf;	
	
	ConfigureFormByParameters();
	SetDynamicListRequestText();
	SetDynamicListParameters(Parameters);
	
	SetFormHeader();
	SetLabelSelectedDestinations();
	
	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure SelectOptionsRadioButtonOnChange(Item)
	CustomizeFormByDestinationOption();
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  Var_Parameters - FormDataStructure:
//   * Source - DocumentRef - link to the document.
//   * CurrentRow - CatalogRef.Assignments - The destination to select as the current row.
&AtServer
Procedure SetDynamicListParameters(Var_Parameters)
	
	CommonClientServer.SetDynamicListParameter(List,
		"Warehouse",
		Var_Parameters.Warehouse);
		
	CommonClientServer.SetDynamicListParameter(List,
		"Products",
		Var_Parameters.Products);
	
	If Var_Parameters.Property("Source") 
		And TypeOf(Var_Parameters.Source) = Type("DocumentRef.InventoryRecount") Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	AnotherQualityGoods.Products AS Products
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|WHERE
		|	AnotherQualityGoods.OtherQualityGoods = &Products";
		Query.SetParameter("Products", Var_Parameters.Products);
		Products = Query.Execute().Unload().UnloadColumn("Products");
		Products.Add(Var_Parameters.Products);
		CommonClientServer.SetDynamicListParameter(List,
			"Products",
			Products);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List,
		"Characteristic",
		Var_Parameters.Characteristic);
		
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	RowOfProduct = TableOfGoods.Add();
	FillPropertyValues(RowOfProduct, Var_Parameters);
	
	CommonClientServer.SetDynamicListParameter(List,
		"TableOfGoods",
		TableOfGoods);
		
	CommonClientServer.SetDynamicListParameter(List,
		"Department",
		Var_Parameters.Department);
		
	CommonClientServer.SetDynamicListParameter(List,
		"Purpose",
		Var_Parameters.CurrentRow);
		
	If Var_Parameters.Filter.Property("RecordsInWarehouseRegisters") Then
		CommonClientServer.SetDynamicListParameter(List,
		"RecordsInWarehouseRegisters",
		Var_Parameters.Filter.RecordsInWarehouseRegisters);
	EndIf;
	
	WarehouseOnly = Var_Parameters.Property("WarehouseAssignmentsOnly");
	
	CommonClientServer.SetDynamicListParameter(List, "ByAllProducts", False);
	CommonClientServer.SetDynamicListParameter(List, "ByReference",     False);
	CommonClientServer.SetDynamicListParameter(List, "ReferenceOrder", ReferenceOrder);
	CommonClientServer.SetDynamicListParameter(List, "WarehouseAssignmentsOnly", WarehouseOnly);

EndProcedure

&AtServer
Procedure SetDynamicListRequestText()
	
	If TypeOf(Source) = Type("DocumentRef.GoodsReceiptNote")
		And ValueIsFilled(ReferenceOrder) And Parameters.Property("SelectionOptions") Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		FillPropertyValues(ListProperties, List);
		ListProperties.QueryText = AdvancedAssignmentRequestText();
		Common.SetDynamicListProperties(Items.List, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(List, "Recorder", Source);
		
		Return;
		
	EndIf;
	
	RequestFormationParameters = Catalogs.Assignments.ParametersForCreatingRequestForAvailableAssignments();
	RequestFormationParameters.ChoiceMode = ChoiceMode;
	RequestFormationParameters.OperationKind = OperationKind;
	RequestFormationParameters.Source = Source;
	If ValueIsFilled(ObjectName) Then
		QueryText = Common.ObjectManagerByFullName(ObjectName).RequestTextForAvailableAssignments(RequestFormationParameters);
	ElsIf Source <> Undefined Then
		QueryText = Common.ObjectManagerByRef(Source).RequestTextForAvailableAssignments(RequestFormationParameters);
	Else
		QueryText =
			"SELECT
			|	Assignments.Ref AS Purpose
			|FROM
			|	Catalog.Assignments AS Assignments
			|		LEFT JOIN Catalog.Partners AS Partners
			|		ON Partners.Ref = Assignments.Partner
			|{WHERE
			|	ISNULL(Partners.Ref, VALUE(Catalog.Partners.EmptyRef)) AS Partner}";
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	CommonClientServer.SetDynamicListParameter(List, "ReferenceOrder", ReferenceOrder);
	CommonClientServer.SetDynamicListParameter(List, "ByAllReferences", Not ValueIsFilled(ReferenceOrder));
	CommonClientServer.SetDynamicListParameter(List, "Recorder", Source);
	CommonClientServer.SetDynamicListParameter(List, "Cell", Cell);
	
	If Not ValueIsFilled(ObjectName)
			And Not Source <> Undefined Then
		
		FiltersStructure = New Structure();
		Catalogs.Assignments.AddPartnerExclusionSelection(FiltersStructure);
		If FiltersStructure.Property("Partner") Then
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"Partner",
				FiltersStructure.Partner,
				Undefined,
				True);
		EndIf;
		
	EndIf;
	
EndProcedure

#Region FormSettingsItem

&AtServer
Procedure CustomizeFormByDestinationOption()

	ByReference = TypeOf(Source) = Type("DocumentRef.GoodsReceiptNote") And ValueIsFilled(ReferenceOrder);
	ByAllProducts = SelectOptionsRadioButton = 5;
	
	CommonClientServer.SetDynamicListParameter(List, "ByReference",     ByReference);
	CommonClientServer.SetDynamicListParameter(List, "ByAllProducts", ByAllProducts);
	
	Items.Count.Visible  = False;
	Items.Supplied.Visible  = False;
	Items.Demand.Visible = False;
	
	If SelectOptionsRadioButton = 0 Then // the purpose of the goods by order
		
		Items.Count.Visible = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	Title = NStr("vi = 'Chọn mục đích';
				|ru = 'Выбор назначения';
				|en = 'Select assignment'; fa = 'انتخاب تخصیص';
				|it = 'Selezione di assegnazione';
				|pl = 'Wybór przeznaczenia';
				|tr = 'Atama seçimi'");
	If ValueIsFilled(Parameters.Products) Then
		TextProducts = StrReplace(NStr("vi = 'Mặt hàng: %1';
										|ru = 'Номенклатура: %1';
										|en = 'Items: %1'; fa = 'Items: %1';
										|it = 'Articolo: %1';
										|pl = 'Towary: %1';
										|tr = 'Öğe: %1'"), "%1", Parameters.Products);
		If ValueIsFilled(Parameters.Characteristic) Then
			TextProducts = TextProducts + ", "
				+ StrReplace(NStr("vi = 'Đặc tính: %1';
									|ru = 'Характеристика: %1';
									|en = 'Variant: %1'; fa = 'Variant: %1';
									|it = 'Caratteristica: %1';
									|pl = 'Charakterystyka: %1';
									|tr = 'Varyant: %1'"), "%1", Parameters.Characteristic);
		EndIf;
		Title = Title + " (" + TextProducts + ")";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetLabelSelectedDestinations()
	
	Items.LabelSelectedAssignments.Visible = False;
	
EndProcedure

&AtServer
Function AdvancedAssignmentRequestText()
	
	QueryText =
		// The remnants of the destination of the goods by order.
		"SELECT
		|	Table.Purpose                AS Purpose,
		|	Table.GoodsReceiptNotesToRegisterBalance AS Count,
		|	Table.GoodsReceiptNotesToRegisterBalance AS Demand,
		|	Table.GoodsReceiptNotesToRegisterBalance AS ToOrder
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,
		|		DocumentInflow = &ReferenceOrder
		|		AND(&ByAllProducts OR(
		|			Products     = &Products
		|			AND Characteristic = &Characteristic))
		|		AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS Table
		|		
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|		ON Table.Purpose = CatAssignments.Ref
		|		 AND (NOT &WarehouseAssignmentsOnly OR CatAssignments.RecordsInWarehouseRegisters)
		|WHERE
		|	NOT CatAssignments.Ref IS NULL
		|		AND Table.GoodsReceiptNotesToRegisterBalance > 0";
		
	Return QueryText;
	
EndFunction

&AtServer
Procedure ConfigureFormByParameters()
	
	SelectOptionsRadioButton = 2; // needs of the receiving warehouse
	
	UsePushingDirections = GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
		And (Not ValueIsFilled(Parameters.LineOfBusiness)
			Or Common.ObjectAttributeValue(Parameters.LineOfBusiness, "CostAccounting"));
	
	If Parameters.DestinationSelectionMode = "Advanced" Then
		Items.SelectOptionsRadioButton.Visible = True;
		Items.AvailableSender.Visible = ValueIsFilled(Parameters.SourceWarehouse);
	Else
		Items.SelectOptionsRadioButton.Visible = False;
		Items.AvailableSender.Visible = False;
	EndIf;
	
	If UsePushingDirections Then
		
		ModeListItem = Items.SelectOptionsRadioButton.ChoiceList.FindByValue(4); // the value of "All separate orders"
		
		ModeListItem.Presentation = NStr("vi = 'Tất cả ấn định';
										|ru = 'Все назначения';
										|en = 'All assignments'; fa = 'All assignments';
										|it = 'Tutte le assegnazioni';
										|pl = 'Wszystkie przeznaczenia';
										|tr = 'Tüm atamalar'");
		
	EndIf;
	
	CustomizeFormByDestinationOption();
	
	ModeListItem = Items.SelectOptionsRadioButton.ChoiceList.FindByValue(3); // the value "For all warehouses"
	Items.SelectOptionsRadioButton.ChoiceList.Delete(ModeListItem);
	
EndProcedure

#EndRegion

#EndRegion
