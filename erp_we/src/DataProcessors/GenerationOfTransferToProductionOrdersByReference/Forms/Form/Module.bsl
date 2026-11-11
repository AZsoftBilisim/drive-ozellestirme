#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("ComplexAutomation") Then
		Items.SemiFinishedProductsAndMaterialsProducedInProcess.Visible = False;
		Items.SemiFinishedProductsAndMaterialsGroupSpecification.Title = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
																				|ru = 'Спецификация';
																				|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																				|it = 'Specifica';
																				|pl = 'Bill of materials';
																				|tr = 'Ürün reçetesi'");
	EndIf;
	
	If Not Parameters.Property("OrderDocument", OrderDocument) Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'This data processor is not intended for manual use.'; fa = 'This data processor is not intended for manual use.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Veri işlemcisi, doğrudan kullanıma yönelik değildir.'");
	EndIf;
	
	If Not Common.ObjectAttributeValue(OrderDocument, "Posted") Then
		ErrorText = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Lập trên cơ sở bị cấm.';
						|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
						|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
						|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
						|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
						|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belge temelinde giriş yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", OrderDocument);
		
		Raise ErrorText;
	EndIf;
	
	ProductionManagement2_2 = GetFunctionalOption("UseProductionManagement2_2");
	Items.UsedMaterialsDepartment.Visible = Not ProductionManagement2_2;
	Items.UsedMaterialsShopFloorStockroom.Visible = ProductionManagement2_2;
	
	CurrentDayStart = BegOfDay(CurrentSessionDate());
	
	Title = OrderDocument;
	CurrentPageName = "ProductsPage";
	SetVisibilityAndAvailability(CurrentPageName);
	TakeIntoAccountExistingOrders = True;
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, DataProcessors.GenerationOfTransferToProductionOrdersByReference);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.SemiFinishedProductsAndMaterialsBillOfMaterials, BOMSelectionParameters);
	
	FillInProductionTableOnServer();
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Ref",
		GeneratedDocuments,
		DataCompositionComparisonType.InList,
		,
		True);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TabsOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "PageMaterials" Then
		ClearMessages();
	EndIf;
	
	Result = WhenChangingPageOnServer(CurrentPageName, CurrentPage.Name);
	
	If Result <> Undefined Then
		ShowUserNotification(Result.NotificationText1, , Result.NotificationComment);
	EndIf;
	
	CurrentPageName = CurrentPage.Name
	
EndProcedure

&AtClient
Procedure ToConsiderThePastOrdersOnChange(Item)
	
	TakeIntoAccountPastOrdersWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSemiFinishedProductsAndMaterials

&AtClient
Procedure SemiFinishedProductsAndMaterialsBeforeExpand(Item, String, Cancel)
	
	CurrentData = SemiFinishedProductsAndMaterials.FindByID(String);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.BillOfMaterials) And Not CurrentData.Exploded Then
		
		Cancel = True;
		
		BuildProductTreeAndFillInServiceDetails(CurrentData.GetID());
		
		Items.SemiFinishedProductsAndMaterials.Expand(CurrentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsAndMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.SemiFinishedProductsAndMaterials.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If CurrentData.RowType = 1 Then
		CurrentData.Selected = False;
		BuildProductTreeAndFillInServiceDetails(CurrentData.GetID());
		CurrentData.Exploded = True;
		TakeIntoAccountExistingOrders = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsAndMaterialsProducedInProcessOnChange(Item)
	
	CurrentData = Items.SemiFinishedProductsAndMaterials.CurrentData;
	
	If CurrentData.ProducedInProcess Then
		CurrentData.PictureNumber = 6;
	Else
		CurrentData.BillOfMaterials = PredefinedValue("Catalog.BillsOfMaterials.EmptyRef");
		CurrentData.PictureNumber = 0;
		CurrentData.GetItems().Clear();
	EndIf;
	
	If Not CurrentData.ProducedInProcess Then
		
		If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
		Else
			CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsAndMaterialsBillOfMaterialsOnChange(Item)
	
	CurrentData = Items.SemiFinishedProductsAndMaterials.CurrentData;
	
	If ValueIsFilled(CurrentData.BillOfMaterials) Then
		
		If CurrentData.Selected > 0 Then
			CurrentData.Selected = 1;
		EndIf;
		
		BuildProductTreeAndFillInServiceDetails(CurrentData.GetID());
		CurrentData.Exploded = True;
		
		Items.SemiFinishedProductsAndMaterials.Expand(CurrentData.GetID(), True);
		
	Else
		CurrentData.ProducedInProcess = False;
		CurrentData.GetItems().Clear();
	EndIf;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsAndMaterialsSelectedOnChange(Item)
	
	CurrentData = Items.SemiFinishedProductsAndMaterials.CurrentData;
	
	If CurrentData.Selected = 2 Then
		CurrentData.Selected = 0;
	EndIf;
	
	SelectedWhenChangingOnServer(CurrentData.GetID());
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsAndMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name <> "SemiFinishedProductsAndMaterialsProducts" Then
		Return;
	EndIf;
	
	CurrentData = Items.SemiFinishedProductsAndMaterials.CurrentData;
	
	If CurrentData = Undefined Or CurrentData.PictureNumber <> 6 Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.BillOfMaterials) And Not CurrentData.Exploded Then
		
		BuildProductTreeAndFillInServiceDetails(CurrentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsAndMaterialsOnChange(Item)
	
	UpdateMaterials = True;
	UpdateOrders = True;
	
	If OrdersAreGenerated Then
		DeleteGeneratedDocuments();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure UsedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "UsedMaterialsProducts" Then
		ShowValue(, CurrentData.Products);
	ElsIf Field.Name = "UsedMaterialsOrderDocument" Then
		ShowValue(, CurrentData.OrderDocument);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsOnChange(Item)
	
	UpdateOrders = True;
	If OrdersAreGenerated Then
		DeleteGeneratedDocuments();
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsSelectedOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData.Selected Then
		CurrentData.NumberOfPackagesToOrder = CurrentData.NumberOfPackages - CurrentData.NumberOfPackagesOrdered;
		CurrentData.QuantityOrderedStorageUoM = CurrentData.Count - CurrentData.QuantityOrderedInStorageUnits;
	Else
		CurrentData.NumberOfPackagesToOrder = 0;
		CurrentData.QuantityOrderedStorageUoM = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsNumberOfPackagesToOrderOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Order");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If CurrentData.NumberOfPackagesToOrder = 0 Then
		CurrentData.Selected = False;
	Else
		CurrentData.Selected = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsShipmentStartOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData.ShipmentStart < CurrentDayStart Then
		CurrentData.ShipmentStart = CurrentDayStart;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRows(Command)
	
	Rows = SemiFinishedProductsAndMaterials.GetItems();
	If Rows.Count() > 0 Then
		UpdateMaterials = True;
		SelectExcludeSelectedLines(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearRows(Command)
	
	Rows = SemiFinishedProductsAndMaterials.GetItems();
	If Rows.Count() > 0 Then
		UpdateMaterials = True;
		SelectExcludeSelectedLines(0);
	EndIf;
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If CurrentPageName = "ProductsPage" Then
		NewPage = Items.PageMaterials;
	Else
		NewPage = Items.PageDocuments;
	EndIf;
	
	Result = WhenChangingPageOnServer(CurrentPageName, NewPage.Name);
	
	If Result <> Undefined Then
		
		Items.Tabs.CurrentPage = NewPage;
		CurrentPageName = NewPage.Name;
		ShowUserNotification(Result.NotificationText1, , Result.NotificationComment);
		
	ElsIf NewPage.Name = "PageMaterials" And Not UpdateMaterials
				Or NewPage.Name = "PageDocuments" And Not UpdateOrders Then
				
				Items.Tabs.CurrentPage = NewPage;
				CurrentPageName = NewPage.Name;
				
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If CurrentPageName = "PageDocuments" Then
		NewPage = Items.PageMaterials;
	Else
		NewPage = Items.ProductsPage;
	EndIf;
	
	Items.Tabs.CurrentPage = NewPage;
	
	Result = WhenChangingPageOnServer(CurrentPageName, NewPage.Name);
	
	If Result <> Undefined Then
		ShowUserNotification(Result.NotificationText1, , Result.NotificationComment);
	EndIf;

	CurrentPageName = NewPage.Name
	
EndProcedure

&AtClient
Procedure GenerateAgain(Command)
	
	NewPage = Items.ProductsPage;
	
	Items.Tabs.CurrentPage = NewPage;
	
	GeneratedDocuments.Clear();
	
	UpdateMaterials = True;
	UpdateOrders = True;
	OrdersAreGenerated = False;
	
	WhenChangingPageOnServer(CurrentPageName, NewPage.Name);
	
	CurrentPageName = NewPage.Name
	
EndProcedure

&AtClient
Procedure MaterialsMarkForOrder(Command)
	
	SelectedRows = Items.UsedMaterials.SelectedRows;
	MarkMaterialsForOrder(True, SelectedRows);
	
EndProcedure

&AtClient
Procedure MaterialsClearMarkForOrder(Command)
	
	SelectedRows = Items.UsedMaterials.SelectedRows;
	MarkMaterialsForOrder(False, SelectedRows);
	
EndProcedure

&AtClient
Procedure UpdateMaterials(Command)
	
	FillInMaterialsOnServer();
	
EndProcedure

&AtClient
Procedure DeleteDocuments(Command)
	DeleteDocumentsOnServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Disabling the visibility of the service line.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsSelected.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsPictureNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsNumberOfPackages.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsDepartment.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsProducedInProcess.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsBillOfMaterials.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsGroupNomenclature.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsGroupPackagingUnitOfMeasurement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = -1;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SemiFinishedProductsAndMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "SemiFinishedProductsAndMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UsedMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.UsedMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
	"SemiFinishedProductsAndMaterialsCharacteristic",
	"SemiFinishedProductsAndMaterials.ItemVariantsAreUsed");
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
	"UsedMaterialsCharacteristic",
	"Object.UsedMaterials.ItemVariantsAreUsed");
	
	// The subdivision is not required to be filled in if the product or semi-finished product.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.ProducedInProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// The picture is not displayed if it is not a semi-finished product.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsPictureNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.PictureNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 6;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Specification for semi-finished products.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsBillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.ProducedInProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// A warehouse is not required for semi-finished products.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.ProducedInProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));

	// If we do not take into account past orders, then we do not display the columns.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsNumberOfPackages.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsNumberOfPackagesOrdered.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TakeIntoAccountExistingOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The transfer order is displayed as a hyperlink.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsOrderDocument.Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// Explanation for the transfer order, if not created or created earlier.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsOrderDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrdersAreGenerated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UsedMaterials.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa được tạo hoặc tạo trước đó>';
													|ru = '<еще не создан или создан ранее>';
													|en = '<not created yet or have been created earlier>'; fa = '<not created yet or have been created earlier>';
													|it = '<non ancora creato o creato prima>';
													|pl = '<jeszcze nie utworzono lub utworzono wcześniej>';
													|tr = '<henüz oluşturulmamış veya daha önce oluşturulmuş>'"));
	
	// If the orders are not formed, then the column with the order is not displayed.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsOrderDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrdersAreGenerated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// A warehouse is not required for work.
	
	TypeOfItemsWork = New ValueList;
	TypeOfItemsWork.LoadValues(ProductsClientServer.JobSelection(False));
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.SemiFinishedProductsAndMaterialsWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "SemiFinishedProductsAndMaterials.ItemsType";
	ConditionalDesignParameters.TypeOfComparisonOfItemTypes = DataCompositionComparisonType.InList;
	ConditionalDesignParameters.ItemsTypes = TypeOfItemsWork;
	ConditionalDesignParameters.TextColor = StyleColors.InaccessibleCellTextColor;
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	// For non-selected lines, the warehouse is not required
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsAndMaterialsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.ProducedInProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SemiFinishedProductsAndMaterials.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#Region ShopPantry_Text
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListShopFloorStockroom.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.ProductionManagement2_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
EndProcedure

&AtServer
Function WhenChangingPageOnServer(OldPage, NewPage)
	
	Result = Undefined;
	
	If NewPage = "PageMaterials" And UpdateMaterials Then
		
		FillInMaterialsOnServer();
		
		If Object.UsedMaterials.Count() > 0 Then
			NotificationText1 = NStr("vi = 'Nguyên vật liệu điền';
									|ru = 'Материалы заполнены';
									|en = 'Materials are filled in'; fa = 'Materials are filled in';
									|it = 'I materiali sono compilati';
									|pl = 'Materiały są wypełnione';
									|tr = 'Malzemeler dolduruldu'");
			NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng số đơn hàng: %1';
					|ru = 'Всего к заказу позиций: %1';
					|en = 'Total items to order: %1'; fa = 'Total items to order: %1';
					|it = 'Totale articoli per l''ordine: %1';
					|pl = 'Łącznie pozycji do zamówienia: %1';
					|tr = 'Toplam sipariş pozisyonlarına: %1'"),
				Object.UsedMaterials.FindRows(New Structure("Selected", True)).Count());
			
			Result = New Structure("NotificationText1, NotificationComment", NotificationText1, NotificationComment);
		EndIf;
		
	EndIf;
	
	If NewPage = "PageDocuments" And UpdateOrders Then
		
		GenerateOrdersOnServer();
		
		If GeneratedDocuments.Count() > 0 Then
			
			NotificationText1 = NStr("vi = 'Đơn hàng được tạo';
									|ru = 'Заказы созданы';
									|en = 'Orders created'; fa = 'Orders created';
									|it = 'Gli ordini sono creati';
									|pl = 'Zamówienia zostały utworzone';
									|tr = 'Siparişler oluşturuldu'");
			NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng số đơn hàng đã tạo: %1';
					|ru = 'Всего сформировано заказов: %1';
					|en = 'Total generated orders: %1'; fa = 'Total generated orders: %1';
					|it = 'Totale ordini generati: %1';
					|pl = 'Łącznie utworzono zamówień: %1';
					|tr = 'Toplam oluşturulan siparişler: %1'"),
				GeneratedDocuments.Count());
			
			Result = New Structure("NotificationText1, NotificationComment", NotificationText1, NotificationComment);
			
		EndIf;
		
	EndIf;
	
	SetVisibilityAndAvailability(NewPage);
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetVisibilityAndAvailability(NewPage)
	
	If NewPage = "ProductsPage" Then
		Items.PagesBack.CurrentPage = Items.BackHide;
	Else
		Items.PagesBack.CurrentPage = Items.BackVisibility;
	EndIf;
	
	If NewPage = "PageDocuments" Then
		Items.PagesNext.CurrentPage = Items.NextFinish;
		Items.Done.DefaultButton = True;
	Else
		Items.PagesNext.CurrentPage = Items.NextNext;
		Items.Next.DefaultButton = True;
	EndIf;
	
EndProcedure

#Region BuildingAndMaintainingTree

&AtServer
Procedure FillInProductionTableOnServer()
	
	Query = New Query(
	"SELECT
	|	CustomerOrderGoods.Products,
	|	CustomerOrderGoods.Characteristic,
	|	CustomerOrderGoods.Package,
	|	CustomerOrderGoods.NumberOfPackages,
	|	CustomerOrderGoods.Count,
	|	CustomerOrderGoods.Warehouse,
	|	CustomerOrderGoods.DateOfShipment AS ShipmentStart,
	|	CustomerOrderGoods.Ref.Purpose,
	|	CustomerOrderGoods.Ref.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials
	|INTO TTOrderProducts
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref = &OrderDocument
	|	AND NOT CustomerOrderGoods.Canceled
	|
	|
	|UNION ALL
	|
	|SELECT
	|	GiverSOrder2_5Products.Products,
	|	GiverSOrder2_5Products.Characteristic,
	|	GiverSOrder2_5Products.Package,
	|	GiverSOrder2_5Products.NumberOfPackages,
	|	GiverSOrder2_5Products.Count,
	|	GiverSOrder2_5Products.Warehouse,
	|	GiverSOrder2_5Products.DateOfShipment,
	|	GiverSOrder2_5Products.Ref.AssignmentMaterials,
	|	GiverSOrder2_5Products.Ref.LineOfBusiness,
	|	GiverSOrder2_5Products.BillOfMaterials
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GiverSOrder2_5Products
	|WHERE
	|	GiverSOrder2_5Products.Ref = &OrderDocument
	|	AND NOT GiverSOrder2_5Products.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	OrderOfMaterialsForProductionGoods.Products,
	|	OrderOfMaterialsForProductionGoods.Characteristic,
	|	OrderOfMaterialsForProductionGoods.Package,
	|	OrderOfMaterialsForProductionGoods.NumberOfPackages,
	|	OrderOfMaterialsForProductionGoods.Count,
	|	OrderOfMaterialsForProductionGoods.Ref.Warehouse,
	|	OrderOfMaterialsForProductionGoods.ShipmentStart,
	|	CASE
	|		WHEN OrderOfMaterialsForProductionGoods.WithAssignment
	|			THEN
	|				CASE 
	|					WHEN OrderOfMaterialsForProductionGoods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|						THEN OrderOfMaterialsForProductionGoods.Ref.Purpose
	|					ELSE OrderOfMaterialsForProductionGoods.Purpose
	|				END
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	OrderOfMaterialsForProductionGoods.Ref.LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS OrderOfMaterialsForProductionGoods
	|WHERE
	|	OrderOfMaterialsForProductionGoods.Ref = &OrderDocument
	|	AND NOT OrderOfMaterialsForProductionGoods.Canceled
	|
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryConsumptionOrderGoods.Products,
	|	InventoryConsumptionOrderGoods.Characteristic,
	|	InventoryConsumptionOrderGoods.Package,
	|	InventoryConsumptionOrderGoods.NumberOfPackages,
	|	InventoryConsumptionOrderGoods.Count,
	|	InventoryConsumptionOrderGoods.Ref.Warehouse,
	|	InventoryConsumptionOrderGoods.DateOfShipment,
	|	CASE
	|		WHEN InventoryConsumptionOrderGoods.WithAssignment
	|			THEN InventoryConsumptionOrderGoods.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	InventoryConsumptionOrderGoods.Ref.LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|FROM
	|	Document.InventoryConsumptionOrder.Goods AS InventoryConsumptionOrderGoods
	|WHERE
	|	InventoryConsumptionOrderGoods.Ref = &OrderDocument
	|	AND NOT InventoryConsumptionOrderGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	OrderToMoveGoods.Products,
	|	OrderToMoveGoods.Characteristic,
	|	OrderToMoveGoods.Package,
	|	OrderToMoveGoods.NumberOfPackages,
	|	OrderToMoveGoods.Count,
	|	OrderToMoveGoods.Ref.SourceWarehouse,
	|	OrderToMoveGoods.ShipmentStart,
	|	CASE
	|		WHEN OrderToMoveGoods.WithAssignment
	|			THEN OrderToMoveGoods.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	OrderToMoveGoods.Ref.LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|FROM
	|	Document.TransferOrder.Goods AS OrderToMoveGoods
	|WHERE
	|	OrderToMoveGoods.Ref = &OrderDocument
	|	AND NOT OrderToMoveGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	ByAssemblyDisassemblyOrderGoods.Products,
	|	ByAssemblyDisassemblyOrderGoods.Characteristic,
	|	ByAssemblyDisassemblyOrderGoods.Package,
	|	ByAssemblyDisassemblyOrderGoods.NumberOfPackages,
	|	ByAssemblyDisassemblyOrderGoods.Count,
	|	ByAssemblyDisassemblyOrderGoods.Ref.Warehouse,
	|	ByAssemblyDisassemblyOrderGoods.Ref.AssemblyDisassemblyStart,
	|	ByAssemblyDisassemblyOrderGoods.Purpose,
	|	ByAssemblyDisassemblyOrderGoods.Ref.LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS ByAssemblyDisassemblyOrderGoods
	|WHERE
	|	ByAssemblyDisassemblyOrderGoods.Ref = &OrderDocument
	|	AND ByAssemblyDisassemblyOrderGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND NOT ByAssemblyDisassemblyOrderGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	ByAssemblyDisassemblyOrder.Products,
	|	ByAssemblyDisassemblyOrder.Characteristic,
	|	ByAssemblyDisassemblyOrder.Package,
	|	ByAssemblyDisassemblyOrder.NumberOfPackages,
	|	ByAssemblyDisassemblyOrder.Count,
	|	ByAssemblyDisassemblyOrder.Warehouse,
	|	ByAssemblyDisassemblyOrder.AssemblyDisassemblyStart,
	|	ByAssemblyDisassemblyOrder.Purpose,
	|	ByAssemblyDisassemblyOrder.LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
	|WHERE
	|	ByAssemblyDisassemblyOrder.Ref = &OrderDocument
	|	AND ByAssemblyDisassemblyOrder.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|
	|UNION ALL
	|
	|SELECT
	|	RMOrderMaterialsAndWorks.Products,
	|	RMOrderMaterialsAndWorks.Characteristic,
	|	RMOrderMaterialsAndWorks.Package,
	|	RMOrderMaterialsAndWorks.NumberOfPackages,
	|	RMOrderMaterialsAndWorks.Count,
	|	RMOrderMaterialsAndWorks.Warehouse,
	|	RMOrderMaterialsAndWorks.Ref.StartDate,
	|	CASE
	|		WHEN RMOrderMaterialsAndWorks.WithAssignment
	|			THEN RMOrderMaterialsAndWorks.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	RMOrderMaterialsAndWorks.Ref.LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|FROM
	|	Document.RMOrder.MaterialsAndWorks AS RMOrderMaterialsAndWorks
	|WHERE
	|	RMOrderMaterialsAndWorks.Ref = &OrderDocument
	|	AND NOT RMOrderMaterialsAndWorks.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse          AS Warehouse
	|INTO TTProducts_1
	|FROM
	|	TTOrderProducts AS Table
	|;
	|
	|/////////////////////////////////////
	|" + InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE") + "
	|;
	|
	|////////////////////////////////////
	|SELECT TOP 0
	|	NULL AS Products,
	|	NULL AS Characteristic,
	|	NULL AS Warehouse,
	|	NULL AS Department
	|INTO GoodsProcurementStrategy
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsProcurementStrategy.Products,
	|	GoodsProcurementStrategy.Characteristic,
	|	GoodsProcurementStrategy.Warehouse,
	|	GoodsProcurementStrategy.ProcurementStrategy.SourceOfDemandSupply
	|FROM
	|	TTWaysToEnsure AS GoodsProcurementStrategy
	|WHERE
	|	GoodsProcurementStrategy.ProcurementStrategy.SupplyType = VALUE(Enum.SupplyTypes.Production)
	|
	|INDEX BY
	|	Products, 
	|	Characteristic, 
	|	Warehouse
	|;
	|
	|/////////////////////////////////////
	|SELECT
	|	TTOrderProducts.Products,
	|	TTOrderProducts.Characteristic,
	|	TTOrderProducts.Count,
	|	TTOrderProducts.NumberOfPackages,
	|	TTOrderProducts.Package,
	|	TTOrderProducts.Warehouse,
	|	ISNULL(GoodsProcurementStrategy.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	TTOrderProducts.Purpose,
	|	TTOrderProducts.LineOfBusiness,
	|	TTOrderProducts.BillOfMaterials,
	|	TTOrderProducts.Products.ItemsType AS ItemsType,
	|	TTOrderProducts.Products.AnalyticalGroup AS ProductsGroup
	|FROM
	|	TTOrderProducts AS TTOrderProducts
	|		LEFT JOIN GoodsProcurementStrategy AS GoodsProcurementStrategy
	|		ON GoodsProcurementStrategy.Products   = TTOrderProducts.Products
	|		 AND GoodsProcurementStrategy.Characteristic = TTOrderProducts.Characteristic
	|		 AND GoodsProcurementStrategy.Warehouse          = TTOrderProducts.Warehouse
	|WHERE
	|	TTOrderProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.Work_5))
	|	AND (NOT GoodsProcurementStrategy.Products IS NULL
	|			OR &ByOrderOfGiver)
	|	AND (
	|		TRUE
	|			OR
	|		TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.ProductsBOM AS ProductsBOM
	|				WHERE
	|					ProductsBOM.Products     = TTOrderProducts.Products
	|					AND ProductsBOM.Characteristic IN (VALUE(Catalog.ItemsCharacteristics.EmptyRef), TTOrderProducts.Characteristic)
	|					AND ProductsBOM.SideExit = FALSE
	|					AND ProductsBOM.Status  = VALUE(Enum.BOMStatuses.Valid)))
	|");
	
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter(
		"ByOrderOfGiver",
		TypeOf(OrderDocument) = Type("DocumentRef.MaterialProviderOrder2_5")
			Or False);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Raise NStr("vi = 'Không có sản phẩm nào có thể lập các đơn đặt hàng để chuyển nguyên liệu sang sản xuất.';
					|ru = 'Отсутствует товар, для которого возможно формирование заказов на передачу материалов в производство.';
					|en = 'No goods for which orders of material transfer to production can be generated.'; fa = 'No goods for which orders of material transfer to production can be generated.';
					|it = 'Non esiste un prodotto per il quale sia possibile generare ordini di trasferimento materiali in produzione.';
					|pl = 'Brak towaru, dla którego jest możliwe utworzenie zamówień na przekazanie materiałów do produkcji.';
					|tr = 'Malzemelerin üretime transferi için siparişlerin düzenlenebileceği bir ürün bulunmamaktadır.'");
	EndIf;
	
	Selection = Result.Select();
	
	CurElements = SemiFinishedProductsAndMaterials.GetItems();
	
	ProductData_2 = New Array;
	
	ProductionStart = BegOfDay(CurrentSessionDate());
	
	While Selection.Next() Do
		
		NewRow = CurElements.Add();
		FillPropertyValues(NewRow, Selection);
		
		ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		
		ProductData.Products            = Selection.Products;
		ProductData.Characteristic          = Selection.Characteristic;
		ProductData.ProductionStart      = ProductionStart;
		ProductData.LineOfBusiness = Selection.LineOfBusiness;
		
		ProductData_2.Add(ProductData);
		
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(CurElements, ProductData_2, BOMSelectionParameters,, True);
	
	For Each String In CurElements Do
		If ValueIsFilled(String.BillOfMaterials) Then
			BuildProductTree(String);
			String.Exploded = True;
		EndIf;
		String.ProducedInProcess = True;
		String.RowType = 1;
	EndDo;
	FillInServiceDetailsSemiFinishedProducts(SemiFinishedProductsAndMaterials);
	
EndProcedure

&AtServer
Procedure BuildProductTreeAndFillInServiceDetails(Val Parent)
	
	BuildProductTree(Parent);
	FillInServiceDetailsSemiFinishedProducts(Parent);
	
EndProcedure

&AtServer
Procedure BuildProductTree(Val Parent)
	
	If Not TypeOf(Parent) = Type("FormDataTreeItem") Then
		Parent = SemiFinishedProductsAndMaterials.FindByID(Parent);
	EndIf;
	
	If Not ValueIsFilled(Parent.BillOfMaterials) Then
		Return;
	EndIf;
	
	NodulationParameters = New Structure("BillOfMaterials, Products, Characteristic, Count, DemandDate, Purpose, LineOfBusiness");
	FillPropertyValues(NodulationParameters, Parent);
	
	TableOfMaterials = SpecificationMaterials_(NodulationParameters);
	
	MaterialsOfShopStorerooms = TableOfMaterials.Copy(New Structure("ThisIsWorkshopPantry, ProducedInProcess", True, False), "Products,Characteristic,Warehouse");
	MaterialsOfShopStorerooms.GroupBy("Products,Characteristic,Warehouse");
	
	SampleWarehousesPantries = SampleWarehousesPantries(MaterialsOfShopStorerooms);
	
	SelectionOfWarehousesOfShopStorerooms = New Structure("Products,Characteristic,Warehouse");
	
	CurElements = Parent.GetItems();
	CurElements.Clear();
	
	TableOfMaterials.Columns.Add("ShopFloorStockroom");
	For Each String In TableOfMaterials Do
		
		If String.ProductionByThirdParty Then
			Continue;
		EndIf;
		
		ProduceAtStage = String.ProducedInProcess
			And String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage;
		
		If String.ItemsType = Enums.ItemsTypes.Work_5
			Or ProduceAtStage Then
			Continue;
		EndIf;
		
		NewRow = CurElements.Add();
		FillPropertyValues(NewRow, String);
		NewRow.ProductsGroup = Parent.ProductsGroup;
		
		NewRow.Selected = Parent.Selected;
		NewRow.LineOfBusiness = Parent.LineOfBusiness;
		
		If NewRow.WithAssignment Or ValueIsFilled(String.SourceOfSemiFinishedProduct)
			Or ValueIsFilled(String.SourceOfSemiFinishedProduct) Then
			NewRow.Purpose = Parent.Purpose;
		EndIf;
		
		If ValueIsFilled(String.SourceOfSemiFinishedProduct) Then
			NewRow.BillOfMaterials = String.SourceOfSemiFinishedProduct;
			NewRow.PictureNumber = 6;
			IsBlankString = NewRow.GetItems().Add();
			IsBlankString.RowType = -1;
		EndIf;
		
		If String.ThisIsWorkshopPantry Then
			NewRow.ShopFloorStockroom = String.Warehouse;
			NewRow.Warehouse = Catalogs.Warehouses.EmptyRef();
			FillPropertyValues(SelectionOfWarehousesOfShopStorerooms, String);
			If SampleWarehousesPantries.FindNext(SelectionOfWarehousesOfShopStorerooms) Then
				NewRow.Warehouse = SampleWarehousesPantries.SourceWarehouse;
				SampleWarehousesPantries.Reset();
			EndIf;
		EndIf;
		
	EndDo;
	
	Parent.Exploded = True;
	
EndProcedure

&AtServer
Function SampleWarehousesPantries(ProductMatrix)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ProductMatrix", ProductMatrix);
	Query.Text = "
	|SELECT
	|	T.Products,
	|	T.Characteristic,
	|	T.Warehouse
	|INTO TTProducts_1
	|FROM
	|	&ProductMatrix AS T
	|
	|;
	|" + InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE") + "
	|;
	|
	|////////////////////////////////////
	|SELECT DISTINCT
	|	T.Products,
	|	T.Characteristic,
	|	T.Warehouse,
	|	Attributes.SourceOfDemandSupply AS SourceWarehouse
	|FROM
	|	TTWaysToEnsure AS T
	|	INNER JOIN Catalog.ProcurementStrategies AS Attributes
	|	ON T.ProcurementStrategy = Attributes.Ref
	|WHERE
	|	Attributes.SupplyType = VALUE(Enum.SupplyTypes.Move)";
	
	Return Query.Execute().Select();
	
EndFunction

&AtServer
Procedure SelectedWhenChangingOnServer(Id)
	
	CurrentData = SemiFinishedProductsAndMaterials.FindByID(Id);
	Parent = CurrentData.GetParent();
	
	SelectExcludeLines(CurrentData.Selected, CurrentData.GetID());
	
	If Parent <> Undefined Then
		UpdateParentRowSelection(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectExcludeLines(Select, Id = Undefined)
	
	If Id = Undefined Then
		CurElements = SemiFinishedProductsAndMaterials.GetItems();
	Else
		
		CurrentRow = SemiFinishedProductsAndMaterials.FindByID(Id);
		
		If CurrentRow.ProducedInProcess And ValueIsFilled(CurrentRow.BillOfMaterials) And Not CurrentRow.Exploded Then
			BuildProductTreeAndFillInServiceDetails(CurrentRow);
		EndIf;
		
		CurElements = CurrentRow.GetItems();
		
	EndIf;
	
	For Each String In CurElements Do
		String.Selected = Select;
		SelectExcludeLines(Select, String.GetID());
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateParentRowSelection(Id)
	
	CurrentData = SemiFinishedProductsAndMaterials.FindByID(Id);
	Parent = CurrentData.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	CurElements = Parent.GetItems();
	
	SelectedLines = 0;
	ThereArePartiallySelectedRows = False;
	For Each String In CurElements Do
		If String.Selected = 1 Then
			SelectedLines = SelectedLines + 1;
		ElsIf String.Selected = 2 Then
			ThereArePartiallySelectedRows = True;
		EndIf;
	EndDo;
	
	If SelectedLines = CurElements.Count() Then
		Parent.Selected = 1;
	ElsIf SelectedLines = 0 And Not ThereArePartiallySelectedRows Then
		Parent.Selected = 0;
	Else
		Parent.Selected = 2;
	EndIf;
	
	UpdateParentRowSelection(Parent.GetID());
	
EndProcedure

&AtServer
Function SpecificationMaterials_(Var_Parameters) Export
	
	ItemData_3 = Catalogs.BillsOfMaterials.MainProductSpecificationData(
		Var_Parameters.BillOfMaterials,
		Var_Parameters.Products,
		Var_Parameters.Characteristic);
		
	ItemData_3.Count = Var_Parameters.Count;
	ItemData_3.Insert("ProductionStart", Var_Parameters.DemandDate);
	ItemData_3.Insert("Purpose", Var_Parameters.Purpose);
	ItemData_3.Insert("LineOfBusiness", Var_Parameters.LineOfBusiness);
	
	TempTablesManager = New TempTablesManager;
	If TypeOf(OrderDocument) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		Documents.MaterialProviderOrder2_5.CreateTTWaysToReceiveMaterialsForOrder(TempTablesManager, OrderDocument);
	EndIf;
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(
		"MaterialsAndServices",
		TempTablesManager,
		ProductionSupply.SoftwareOptionAccordingToProductionVersion(ProductionManagement2_2));
	
	SelectionParameters.GetAutoSelectionInformation = False;
	SelectionParameters.GetPresentations      = False;
	
	MaterialsAndServices = Catalogs.BillsOfMaterials.SpecificationDataByProducts(ItemData_3, SelectionParameters).MaterialsAndServices;
	MaterialsAndServices.Columns.StageSubdivision.Name = "Department";
	
	For IndexOf = -MaterialsAndServices.Count()+1 To 0 Do
		CurrentRow = MaterialsAndServices[-IndexOf];
		If CurrentRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess
			Or CurrentRow.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess Then
			MaterialsAndServices.Delete(CurrentRow);
		EndIf;
	EndDo;
	
	Return MaterialsAndServices;
	
EndFunction

&AtServer
Procedure SelectExcludeSelectedLines(Selected)
	
	Rows = SemiFinishedProductsAndMaterials.GetItems();
	
	For Each String In Rows Do
		
		String.Selected = Selected;
		
		SelectExcludeLines(Selected, String.GetID());
		UpdateParentRowSelection(String.GetID());
		
	EndDo;
	
	UpdateOrders = True;
	If OrdersAreGenerated Then
		DeleteGeneratedDocuments();
	EndIf;
	
EndProcedure

#Region FillingInServiceDetailsTree

&AtServer
Procedure FillInServiceDetailsSemiFinishedProducts(Parent)
	
	If Not TypeOf(Parent) = Type("FormDataTreeItem")
			And Not TypeOf(Parent) = Type("FormDataTree") Then
		Parent = SemiFinishedProductsAndMaterials.FindByID(Parent);
	EndIf;
	
	AttributesTable = New ValueTable();
	AttributesTable.Columns.Add("Id", New TypeDescription("Number"));
	AttributesTable.Columns.Add("LineNumber", New TypeDescription("Number"));
	For Counter = 1 To AttributesTable.Count() Do
		AttributesTable[Counter - 1].LineNumber = Counter;
	EndDo;
	
	AttributesTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	AttributesTable.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	AttributesTable.Columns.Add("ItemVariantsAreUsed", New TypeDescription("Boolean"));
	
	AddingTreeToTableRecursively(Parent.GetItems(), AttributesTable);
	
	Actions = New Structure();
	Actions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	Actions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(AttributesTable, Actions);
	
	FillInDetailsOfTreeOnTable("ItemsType,ItemVariantsAreUsed", AttributesTable, SemiFinishedProductsAndMaterials);
	
EndProcedure

&AtServerNoContext
Procedure FillInDetailsOfTreeOnTable(AttributesAsString, Table, Tree)
	
	For Each String In Table Do
		
		FillPropertyValues(Tree.FindByID(String.Id), String, AttributesAsString);
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure AddingTreeToTableRecursively(TreeItems, Table)
	
	For Each TreeItem In TreeItems Do
		
		NewRow = Table.Add();
		FillPropertyValues(NewRow, TreeItem);
		NewRow.Id = TreeItem.GetID();
		NextLevel = TreeItem.GetItems();
		AddingTreeToTableRecursively(NextLevel, Table);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region MaintenanceOfMaterialList

&AtServer
Procedure FillInMaterialsOnServer()
	
	Object.UsedMaterials.Clear();
	TableOfMaterials = Object.UsedMaterials.Unload();
	
	Cancel = False;
	AddLevelMaterials(SemiFinishedProductsAndMaterials, TableOfMaterials, Cancel);
	
	If Cancel Then
		Object.UsedMaterials.Clear();
		Return;
	EndIf;
	
	UpdateMaterials = False;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfMaterials.Products        AS Products,
	|	TableOfMaterials.Characteristic      AS Characteristic,
	|	TableOfMaterials.Package            AS Package,
	|	TableOfMaterials.NumberOfPackages  AS NumberOfPackages,
	|	TableOfMaterials.Count          AS Count,
	|	TableOfMaterials.Department       AS Department,
	|	TableOfMaterials.DaysFromDemand   AS DaysFromDemand,
	|	TableOfMaterials.WithAssignment         AS WithAssignment,
	|	TableOfMaterials.SupplyOption  AS SupplyOption,
	|	TableOfMaterials.Warehouse               AS Warehouse,
	|	TableOfMaterials.ShopFloorStockroom     AS ShopFloorStockroom,
	|	TableOfMaterials.DemandDate     AS DemandDate,
	|	TableOfMaterials.Purpose          AS Purpose,
	|	TableOfMaterials.ProductsGroup     AS ProductsGroup
	|INTO TTMaterials
	|FROM
	|	&TableOfMaterials AS TableOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTMaterials.Products              AS Products,
	|	TTMaterials.Characteristic            AS Characteristic,
	|	TTMaterials.Package                  AS Package,
	|	SUM(TTMaterials.NumberOfPackages) AS NumberOfPackages,
	|	SUM(TTMaterials.Count)         AS Count,
	|	TTMaterials.Department             AS Department,
	|	TTMaterials.ProductsGroup           AS ProductsGroup,
	|	MIN(CASE
	|			WHEN BEGINOFPERIOD(DATEADD(TTMaterials.DemandDate, DAY, TTMaterials.DaysFromDemand), DAY) > &CurrentDayStart
	|				THEN BEGINOFPERIOD(DATEADD(TTMaterials.DemandDate, DAY, TTMaterials.DaysFromDemand), DAY)
	|			ELSE &CurrentDayStart
	|		END)                            AS ShipmentStart,
	|	TTMaterials.Warehouse                     AS Warehouse,
	|	TTMaterials.ShopFloorStockroom           AS ShopFloorStockroom,
	|	TTMaterials.WithAssignment               AS WithAssignment,
	|	TTMaterials.SupplyOption        AS SupplyOption,
	|	CASE
	|		WHEN TTMaterials.WithAssignment
	|			THEN TTMaterials.Purpose
	|	END                                 AS Purpose,
	|	0                                     AS NumberOfPackagesOrdered,
	|	0                                     AS QuantityOrderedInStorageUnits,
	|	SUM(TTMaterials.NumberOfPackages) AS NumberOfPackagesToOrder,
	|	SUM(TTMaterials.Count)         AS QuantityOrderedStorageUoM,
	|	TRUE                                AS Selected
	|FROM
	|	TTMaterials AS TTMaterials
	|
	|GROUP BY
	|	TTMaterials.Products,
	|	TTMaterials.Characteristic,
	|	TTMaterials.Package,
	|	TTMaterials.Department,
	|	TTMaterials.ProductsGroup,
	|	TTMaterials.Warehouse,
	|	TTMaterials.ShopFloorStockroom,
	|	TTMaterials.WithAssignment,
	|	TTMaterials.SupplyOption,
	|	CASE
	|		WHEN TTMaterials.WithAssignment
	|			THEN TTMaterials.Purpose
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Products           AS Products,
	|	TableOfGoods.Characteristic         AS Characteristic,
	|	DocumentsTable.Department       AS Department,
	|	TableOfGoods.ProductsGroup        AS ProductsGroup,
	|	SUM(TableOfGoods.Count)      AS Count
	|FROM
	|	Document.OrderOfMaterialsForProduction AS DocumentsTable
	|		INNER JOIN Document.OrderOfMaterialsForProduction.Goods AS TableOfGoods
	|		ON DocumentsTable.Ref = TableOfGoods.Ref
	|WHERE
	|	DocumentsTable.Posted
	|	AND DocumentsTable.DocumentBasis = &OrderDocument
	|	AND NOT DocumentsTable.Ref IN (&OrderList)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTMaterials AS TTMaterials
	|			WHERE
	|				TTMaterials.Products      = TableOfGoods.Products
	|				AND TTMaterials.Characteristic  = TableOfGoods.Characteristic
	|				AND TTMaterials.Department   = DocumentsTable.Department
	|				AND TTMaterials.ProductsGroup = TableOfGoods.ProductsGroup)
	|	AND (&TakeIntoAccountExistingOrders)
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	DocumentsTable.Department,
	|	TableOfGoods.ProductsGroup";
	
	Query.SetParameter("TableOfMaterials",           TableOfMaterials);
	Query.SetParameter("OrderDocument",                       OrderDocument);
	Query.SetParameter("OrderList",               GeneratedDocuments.UnloadValues());
	Query.SetParameter("TakeIntoAccountExistingOrders", TakeIntoAccountExistingOrders);
	Query.SetParameter("CurrentDayStart",           CurrentDayStart);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TableOfMaterials = ResultsArray[ResultsArray.UBound() - 1].Unload();
	TheOrdersTable    = ResultsArray[ResultsArray.UBound()].Unload();
	
	If TheOrdersTable.Count() > 0 Then
		
		FilterFields      = "Products, Characteristic, Department, ProductsGroup";
		FilterStructure1 = New Structure(FilterFields);
		
		TableOfMaterials.Indexes.Add(FilterFields);
		
		For Each OrdersRow In TheOrdersTable Do
			
			FillPropertyValues(FilterStructure1, OrdersRow);
			
			RowsArray = TableOfMaterials.FindRows(FilterStructure1);
			If RowsArray.Count() > 0 Then
				
				For Each ContentLine In RowsArray Do
					
					ContentLine.QuantityOrderedInStorageUnits = Min(OrdersRow.Count, ContentLine.Count);
					ContentLine.QuantityOrderedStorageUoM = ContentLine.Count - ContentLine.QuantityOrderedInStorageUnits;
					
					If ContentLine.QuantityOrderedInStorageUnits = ContentLine.Count Then
						
						ContentLine.NumberOfPackagesOrdered	= ContentLine.NumberOfPackages;
						ContentLine.NumberOfPackagesToOrder = 0;
						ContentLine.Selected                     = False;
						
					Else
						
						CachedValues = New Structure("PackingFactors, VolumeOfPackages, PackageWeight_",
															   New Map, New Map, New Map);
															   
						PackagingFactor  = BatchProcessingOfTablePartClientServer.GetPackingRatio(
													ContentLine.Package, CachedValues, ContentLine.Products).ZoomRatio;
													
						ContentLine.NumberOfPackagesOrdered	= ContentLine.QuantityOrderedInStorageUnits / PackagingFactor;							
						ContentLine.NumberOfPackagesToOrder = ContentLine.NumberOfPackages - ContentLine.NumberOfPackagesOrdered;
						
					EndIf;	
					
					OrdersRow.Count = OrdersRow.Count - ContentLine.QuantityOrderedInStorageUnits;
					If OrdersRow.Count = 0 Then
						Break;
					EndIf;	
					
				EndDo;
				
				If OrdersRow.Count > 0 Then
					
					ContentLine.QuantityOrderedInStorageUnits = ContentLine.QuantityOrderedInStorageUnits + OrdersRow.Count;
					ContentLine.QuantityOrderedStorageUoM = ContentLine.Count         - ContentLine.QuantityOrderedInStorageUnits;
					
					CachedValues = New Structure("PackingFactors, VolumeOfPackages, PackageWeight_",
						New Map, New Map, New Map);
					PackagingFactor  = BatchProcessingOfTablePartClientServer.GetPackingRatio(
												ContentLine.Package, CachedValues, ContentLine.Products).ZoomRatio;
												
					ContentLine.NumberOfPackagesOrdered	= ContentLine.QuantityOrderedInStorageUnits / PackagingFactor;							
					ContentLine.NumberOfPackagesToOrder = ContentLine.NumberOfPackages - ContentLine.NumberOfPackagesOrdered;
					
				EndIf;	
			
			EndIf;
			
		EndDo;	
		
	EndIf;	
	
	Object.UsedMaterials.Load(TableOfMaterials);
	If ProductionManagement2_2 Then
		For Each RowData In Object.UsedMaterials Do
			RowData.ShopFloorStockroom = SettingsValueCached.GetDefaultShopPantry(RowData.Department);
		EndDo; 
	EndIf; 
	Actions = New Structure();
	Actions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	Actions.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.UsedMaterials,
		Actions);
	
EndProcedure

&AtServer
Procedure AddLevelMaterials(TreeRow, TableOfMaterials, Cancel = False)
	
	CurLines_ = TreeRow.GetItems();
	
	For Each String In CurLines_ Do
		
		If String.Selected > 0 Then
			
			If String.ProducedInProcess And Not ValueIsFilled(String.BillOfMaterials) Then
				
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền trường Bảng kê chi tiết các nguồn lực sản xuất';
						|ru = 'Поле Спецификация не заполнено';
						|en = '""Bill of materials"" is not filled in'; fa = '""Bill of materials"" is not filled in';
						|it = 'Il campo Specifica non è compilato';
						|pl = 'Nie wypełniono pola Specyfikacja materiałowa';
						|tr = 'Ürün Reçetesi Alanı doldurulmadı'"),
					,
					"SemiFinishedProductsAndMaterials",
					,
					Cancel);
				
			EndIf;
			
			If Not String.ProducedInProcess Then
				
				If Not ValueIsFilled(String.Warehouse) Then
					
					CommonClientServer.MessageToUser(
						NStr("vi = 'Trường Kho bãi trống';
							|ru = 'Поле Склад не заполнено';
							|en = '""Warehouse"" is not filled in'; fa = '""Warehouse"" is not filled in';
							|it = 'Il campo Magazzino non è compilato';
							|pl = 'Nie wypełniono pola Magazyn';
							|tr = 'Ambar Alanı doldurulmadı'"),
						,
						"SemiFinishedProductsAndMaterials",
						,
						Cancel);
					
				EndIf;
				
				If Not ValueIsFilled(String.Department) Then
					
					CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền trường Bộ phận';
						|ru = 'Поле Подразделение не заполнено';
						|en = '""Business unit"" is not filled in'; fa = '""Business unit"" is not filled in';
						|it = 'Il campo Reparto non è compilato';
						|pl = 'Nie wypełniono pola Dział';
						|tr = 'Departman alanı doldurulmadı'"),
					,
					"SemiFinishedProductsAndMaterials",
					,
					Cancel);
					
				EndIf;
			
				NewRow = TableOfMaterials.Add();
				FillPropertyValues(NewRow, String);
			EndIf;
			
		EndIf;
		
		AddLevelMaterials(String, TableOfMaterials, Cancel);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure MarkMaterialsForOrder(Notice, RowsArray)
	
	For Each String In RowsArray Do
		
		RowData = Object.UsedMaterials.FindByID(String);
		RowData.Selected = Notice;
		
		If RowData.Selected Then
			RowData.NumberOfPackagesToOrder = RowData.NumberOfPackages - RowData.NumberOfPackagesOrdered;
			RowData.QuantityOrderedStorageUoM = RowData.Count - RowData.QuantityOrderedInStorageUnits;
		Else
			RowData.NumberOfPackagesToOrder = 0;
			RowData.QuantityOrderedStorageUoM = 0;
		EndIf;

		
	EndDo;
	
	UpdateOrders = True;
	
	If OrdersAreGenerated Then
		DeleteGeneratedDocuments();
	EndIf;
	
EndProcedure

&AtServer
Procedure TakeIntoAccountPastOrdersWhenChangingOnServer()
	
	DeleteGeneratedDocuments();
	
	If TakeIntoAccountExistingOrders Then
		FillInMaterialsOnServer();
	Else
		
		For Each String In Object.UsedMaterials Do
			
			String.NumberOfPackagesOrdered = 0;
			String.QuantityOrderedInStorageUnits = 0;
			
			String.NumberOfPackagesToOrder = String.NumberOfPackages;
			String.QuantityOrderedStorageUoM = String.Count;
			
			String.Selected = String.NumberOfPackagesToOrder > 0;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DocumentGeneration

&AtServer
Procedure GenerateOrdersOnServer()
	
	Var CurWarehouse, CurDivision, CurPantry, DocObject, DateOfShipment, NotShipInInstallments;
	
	DeleteGeneratedDocuments();
	
	TableOfMaterials = Object.UsedMaterials.Unload(New Structure("Selected", True));
	TableOfMaterials.Sort("Warehouse, Department");
	
	HeaderAttributes = New Structure("Date, Organization, Department, ShopFloorStockroom, LineOfBusiness,
		|Warehouse, BusinessOperation, DateOfShipment, DocumentBasis, NotShipInInstallments, DonTFillOutDefaultCollateralOption");
	
	GoodsTable = TableOfMaterials.CopyColumns("Products, Characteristic, Purpose,
		|Package, NumberOfPackages, Count, ShipmentStart, WithAssignment, SupplyOption, ProductsGroup");
	GoodsTable.Columns.Add("ReceiptEnd", Common.DateTypeDetails(DateFractions.Date));
	
	ErrorsMessages = New Array;
	MatchingOrders = New Map;
	
	DateOfNewDocuments = CurrentSessionDate();
	
	For Each String In TableOfMaterials Do
		
		If CurWarehouse <> String.Warehouse 
			Or CurDivision <> String.Department 
				And Not ProductionManagement2_2
			Or CurPantry <> String.ShopFloorStockroom
				And ProductionManagement2_2 Then
			
			If DocObject <> Undefined Then
				
				HeaderAttributes.DateOfShipment         = DateOfShipment;
				HeaderAttributes.NotShipInInstallments   = NotShipInInstallments;
				
				GoodsTable.Sort("Products, ShipmentStart");
				FillingData = New Structure("HeaderAttributes, Goods", HeaderAttributes, GoodsTable);
				DocObject.Fill(FillingData);
				WriteDocument(DocObject, ErrorsMessages);
				
				GeneratedDocuments.Add(DocObject.Ref);
				
			EndIf;
			
			DateOfShipment = Undefined;
			NotShipInInstallments = True;
			
			GoodsTable.Clear();
			
			DocObject = Documents.OrderOfMaterialsForProduction.CreateDocument();
			DocObject.SetNewObjectRef(Documents.OrderOfMaterialsForProduction.GetRef(New UUID));
			
			FillPropertyValues(HeaderAttributes, Common.ObjectAttributesValues(OrderDocument, "Organization, LineOfBusiness"));
			FillPropertyValues(HeaderAttributes, String, "Department, Warehouse, ShopFloorStockroom");
			HeaderAttributes.Date                  = DateOfNewDocuments;
			If ProductionManagement2_2 Then
				HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
			Else
				HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.TransferToProduction;
			EndIf;
			
			HeaderAttributes.DocumentBasis     = OrderDocument;
			
			CurWarehouse         = String.Warehouse;
			CurDivision = String.Department;
			CurPantry      = String.ShopFloorStockroom;
			
		EndIf;
		
		NewRow = GoodsTable.Add();
		FillPropertyValues(NewRow, String);
		NewRow.ReceiptEnd = String.ShipmentStart;
		
		NewRow.Count = String.QuantityOrderedStorageUoM;
		NewRow.NumberOfPackages = String.NumberOfPackagesToOrder;
		
		If DateOfShipment = Undefined Then
			DateOfShipment = String.ShipmentStart;
		EndIf;
		
		If DateOfShipment <> String.ShipmentStart Then
			NotShipInInstallments = False;
		EndIf;
		
		MatchingOrders.Insert(String.LineNumber, DocObject.GetNewObjectRef());
		
	EndDo;
	
	If DocObject <> Undefined Then
		
		If GetFunctionalOption("UseProductionManagement2_2") Then
			HeaderAttributes.DateOfShipment         = '00010101';
			HeaderAttributes.NotShipInInstallments   = False;
		Else
			HeaderAttributes.DateOfShipment         = DateOfShipment;
			HeaderAttributes.NotShipInInstallments   = NotShipInInstallments;
		EndIf;
		
		GoodsTable.Sort("Products, ShipmentStart");
		FillingData = New Structure("HeaderAttributes, Goods", HeaderAttributes, GoodsTable);
		DocObject.Fill(FillingData);
		WriteDocument(DocObject, ErrorsMessages);
		
		GeneratedDocuments.Add(DocObject.Ref);
		
	EndIf;
	
	If GeneratedDocuments.Count() > 0 Then
		OrdersAreGenerated = True;
		UpdateOrders = False;
	EndIf;
	
	For Each Message In ErrorsMessages Do
		Message.Message();
	EndDo;
	
	For Each String In Object.UsedMaterials Do
		
		String.OrderDocument = MatchingOrders[String.LineNumber];
		
		String.NumberOfPackagesOrdered = String.NumberOfPackagesOrdered + String.NumberOfPackagesToOrder;
		String.QuantityOrderedInStorageUnits = String.QuantityOrderedInStorageUnits + String.QuantityOrderedStorageUoM;
		
		String.NumberOfPackagesToOrder = 0;
		String.QuantityOrderedStorageUoM = 0;
		
		String.Selected = False;
		
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Ref",
		GeneratedDocuments,
		DataCompositionComparisonType.InList,
		,
		True);
	
EndProcedure

&AtServer
Procedure WriteDocument(DocObject, ErrorsMessages)
	
	If DocObject.CheckFilling() Then
		Try
			DocObject.Write(DocumentWriteMode.Posting);
		Except
			DocObject.Write(DocumentWriteMode.Write);
			WriteLogEvent(NStr("vi = 'Tạo đơn hàng chuyển nhượng cho sản xuất';
								|ru = 'Создание заказов на передачу в производство';
								|en = 'Create orders of transfer to production'; fa = 'Create orders of transfer to production';
								|it = 'Creazione degli ordini di trasferimento in produzione';
								|pl = 'Tworzenie zamówień przekazania do produkcji';
								|tr = 'Üretime aktarılacak siparişlerin oluşturulması'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else
		DocObject.Write(DocumentWriteMode.Write);
	EndIf;
	
	Errors = GetUserMessages(True);
	
	For Each Error In Errors Do
		
		Error.DataKey = DocObject.Ref;
		ErrorsMessages.Add(Error);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteGeneratedDocuments()
	
	ArrayOfDeleteLinks = GeneratedDocuments.UnloadValues();
	ErrorList           = TMCommonUse.SetMarkForDeletingDocuments(ArrayOfDeleteLinks);
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
	OrdersAreGenerated = False;
	UpdateOrders = True;
	
	GeneratedDocuments.Clear();
	
EndProcedure

&AtServer
Procedure DeleteDocumentsOnServer()
	DeleteGeneratedDocuments();
	FillInMaterialsOnServer();
	Items.DocumentsList.Refresh();
EndProcedure

#EndRegion

#EndRegion
