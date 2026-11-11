#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = Not Users.IsFullUser();
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "ProductionOrder", ProductionOrder, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "BillOfMaterials", BillOfMaterials, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Products", Products, QuickFilterStructure); 
	
	Items.FormGroupServiceTeams.Visible = Not ReadOnly;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "ProductionOrder", ProductionOrder, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "BillOfMaterials", BillOfMaterials, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Products", Products, QuickFilterStructure, Settings);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionOrderSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductionOrder", ProductionOrder, DataCompositionComparisonType.Equal,, ValueIsFilled(ProductionOrder));

EndProcedure

&AtClient
Procedure SpecificationSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "BillOfMaterials", BillOfMaterials, DataCompositionComparisonType.Equal,, ValueIsFilled(BillOfMaterials));

EndProcedure

&AtClient
Procedure NomenclatureSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Products", Products, DataCompositionComparisonType.Equal,, ValueIsFilled(Products));

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MinimizeRegisteredRecords(Command)
	
	MinimizeTrafficOnServer();
	
EndProcedure

&AtServer
Procedure MinimizeTrafficOnServer()
	
	OrderStructureInternal.RegisterConvolution();
	Items.List.Refresh();
	
EndProcedure

&AtClient
Async Procedure DeleteEntriesBasedOnSetSelection(Command)
	
	If Not (ValueIsFilled(ProductionOrder) Or ValueIsFilled(BillOfMaterials) Or ValueIsFilled(Products)) Then
		ShowMessageBox(,NStr("vi = 'Chưa thiết lập bộ lọc. Không thể tiếp tục giao dịch.';
							|ru = 'Не установлен отбор. Продолжение операции недоступно.';
							|en = 'No filter is set. Cannot continue the operation.'; fa = 'No filter is set. Cannot continue the operation.';
							|it = 'No filter is set. Cannot continue the operation.';
							|pl = 'No filter is set. Cannot continue the operation.';
							|tr = 'Filtre ayarlanmadı. İşleme devam edilemiyor.'"));
		Return;
	EndIf;
	
	Response = Await DoQueryBoxAsync(NStr("vi = 'Tiếp tục thực hiện giao dịch?';
											|ru = 'Продолжить выполнение операции?';
											|en = 'Continue the operation?'; fa = 'Continue the operation?';
											|it = 'Continue the operation?';
											|pl = 'Continue the operation?';
											|tr = 'İşlem yapılmaya devam edilsin mi?'"), QuestionDialogMode.YesNo);
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	DeleteRecordsBySetSelectionAtServer();
	
EndProcedure

&AtServer
Procedure DeleteRecordsBySetSelectionAtServer()
	
	Query = New Query();
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("Products", Products);
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	Query.Text = 
	"SELECT DISTINCT
	|	OrderStructure.KeySet AS KeySet
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|WHERE
	|	&ProductionOrder IN (OrderStructure.ProductionOrder, VALUE(Document.ProductionOrder2_2.EmptyRef))
	|	AND &Products IN (OrderStructure.Products, VALUE(Catalog.Products.EmptyRef))
	|	AND &BillOfMaterials IN (OrderStructure.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef))";
	
	OrderStructureInternal.RemoveBatchesFromStructureBySetKeys(Query.Execute().Unload());
	Items.List.Refresh();
	
EndProcedure

#EndRegion
