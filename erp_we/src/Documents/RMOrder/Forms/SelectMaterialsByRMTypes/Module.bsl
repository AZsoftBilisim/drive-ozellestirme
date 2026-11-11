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
	
	GetOrderData();
	FillInMaterialsAndWorks();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And ThereIsDataToTransfer() Then
		
		SaveAndCloseNotification = New CallbackDescription(
			"BeforeClosingMoveAndClose", ThisObject);
	
		CommonClient.ShowFormClosingConfirmation(
			SaveAndCloseNotification,
			Cancel,
			Exit,
			NStr("vi = 'Dữ liệu đã được thay đổi. Chuyển vào chứng từ?';
				|ru = 'Данные были изменены. Перенести в документ?';
				|en = 'Data has changed. Transfer to the document?'; fa = 'Data has changed. Transfer to the document?';
				|it = 'I dati sono stati modificati. Trasferirli nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść do dokumentu?';
				|tr = 'Veriler değiştirildi. Belgeye aktarılsın mı?'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure UsedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If Field = Items.UsedMaterialsProducts And ValueIsFilled(CurrentData.Products) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf Field = Items.UsedMaterialsRMType And ValueIsFilled(CurrentData.RMType) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.RMType);
		
	EndIf;

EndProcedure

&AtClient
Procedure UsedMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	If ThereIsDataToTransfer() Then
		
		TransferContentToDocument();
		
	Else
		
		ClearMessages();
		
		CommonClient.MessageToUser(
			NStr("vi = 'Cần chỉ định số lượng của mặt hàng';
				|ru = 'Необходимо указать количество номенклатуры';
				|en = 'Specify the amount of products'; fa = 'Specify the amount of products';
				|it = 'È necessario indicare la quantità dell''articolo';
				|pl = 'Należy wskazać ilość towarów';
				|tr = 'Öğe miktarını belirtmek gerekmektedir'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectRows(Command)
	SetStringSelection(True);
EndProcedure

&AtClient
Procedure ClearRows(Command)
	SetStringSelection(False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UsedMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "UsedMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "UsedMaterialsCharacteristic", "UsedMaterials.ItemVariantsAreUsed");

EndProcedure

&AtServer
Procedure FillInMaterialsAndWorks()
	
	Modified = False;
	
	UsedMaterials.Clear();
	
	QueryText = 
	"SELECT
	|	OrderRepairs.RMType AS RMType,
	|	OrderRepairs.RMCode AS RMCode
	|INTO OrderRepairs
	|FROM
	|	&OrderRepairs AS OrderRepairs
	|
	|INDEX BY
	|	RMType
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndWorksOfTheOrder.RMCode,
	|	MaterialsAndWorksOfTheOrder.Products,
	|	MaterialsAndWorksOfTheOrder.Characteristic,
	|	MaterialsAndWorksOfTheOrder.Package,
	|	MaterialsAndWorksOfTheOrder.NumberOfPackages,
	|	MaterialsAndWorksOfTheOrder.Count
	|INTO MaterialsAndWorksOfTheOrder
	|FROM
	|	&MaterialsAndWorksOfTheOrder AS MaterialsAndWorksOfTheOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderRepairs.RMCode AS RMCode,
	|	MaterialsAndWorks.Ref AS RMType,
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic,
	|	MaterialsAndWorks.Package,
	|	SUM(MaterialsAndWorks.Count) AS Count,
	|	SUM(MaterialsAndWorks.NumberOfPackages) AS NumberOfPackages
	|INTO MaterialsAndWorksOnTypesOfRepairs
	|FROM
	|	Catalog.RMTypes.MaterialsAndWorks AS MaterialsAndWorks
	|		INNER JOIN OrderRepairs AS OrderRepairs
	|		ON OrderRepairs.RMType = MaterialsAndWorks.Ref
	|
	|GROUP BY
	|	OrderRepairs.RMCode,
	|	MaterialsAndWorks.Ref,
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic,
	|	MaterialsAndWorks.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndWorksOnTypesOfRepairs.RMCode AS RMCode,
	|	MaterialsAndWorksOnTypesOfRepairs.RMType AS RMType,
	|	MaterialsAndWorksOnTypesOfRepairs.Products AS Products,
	|	MaterialsAndWorksOnTypesOfRepairs.Characteristic AS Characteristic,
	|	MaterialsAndWorksOnTypesOfRepairs.Package AS Package,
	|
	|	TRUE AS RowIsSelected,
	|	MaterialsAndWorksOnTypesOfRepairs.Count AS Count,
	|	MaterialsAndWorksOnTypesOfRepairs.NumberOfPackages AS NumberOfPackages,
	|
	|	ISNULL(MaterialsAndWorksOfTheOrder.NumberOfPackages, 0) AS PackagingQuantityInTheOrder,
	|	MaterialsAndWorksOnTypesOfRepairs.NumberOfPackages AS NumberOfPackagesInTheFormOfRepairs
	|
	|FROM
	|	MaterialsAndWorksOnTypesOfRepairs AS MaterialsAndWorksOnTypesOfRepairs
	|
	|		LEFT JOIN MaterialsAndWorksOfTheOrder AS MaterialsAndWorksOfTheOrder
	|		ON MaterialsAndWorksOfTheOrder.Products = MaterialsAndWorksOnTypesOfRepairs.Products
	|			AND MaterialsAndWorksOfTheOrder.Characteristic = MaterialsAndWorksOnTypesOfRepairs.Characteristic
	|			AND MaterialsAndWorksOfTheOrder.Package = MaterialsAndWorksOnTypesOfRepairs.Package
	|			AND MaterialsAndWorksOfTheOrder.RMCode = MaterialsAndWorksOnTypesOfRepairs.RMCode
	|
	|WHERE
	|	ISNULL(MaterialsAndWorksOfTheOrder.Count, 0) <> MaterialsAndWorksOnTypesOfRepairs.Count
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialsAndWorksOfTheOrder.RMCode AS RMCode,
	|	OrderRepairs.RMType AS RMType,
	|	MaterialsAndWorksOfTheOrder.Products AS Products,
	|	MaterialsAndWorksOfTheOrder.Characteristic AS Characteristic,
	|	MaterialsAndWorksOfTheOrder.Package AS Package,
	|
	|	TRUE AS RowIsSelected,
	|	0 AS Count,
	|	0 AS NumberOfPackages,
	|
	|	MaterialsAndWorksOfTheOrder.NumberOfPackages AS PackagingQuantityInTheOrder,
	|	0 AS NumberOfPackagesInTheFormOfRepairs
	|
	|FROM
	|	MaterialsAndWorksOfTheOrder AS MaterialsAndWorksOfTheOrder
	|
	|		INNER JOIN OrderRepairs AS OrderRepairs
	|		ON OrderRepairs.RMCode = MaterialsAndWorksOfTheOrder.RMCode
	|
	|		LEFT JOIN MaterialsAndWorksOnTypesOfRepairs AS MaterialsAndWorksOnTypesOfRepairs
	|		ON MaterialsAndWorksOnTypesOfRepairs.Products = MaterialsAndWorksOfTheOrder.Products
	|			AND MaterialsAndWorksOnTypesOfRepairs.Characteristic = MaterialsAndWorksOfTheOrder.Characteristic
	|			AND MaterialsAndWorksOnTypesOfRepairs.Package = MaterialsAndWorksOfTheOrder.Package
	|			AND MaterialsAndWorksOnTypesOfRepairs.RMCode = MaterialsAndWorksOfTheOrder.RMCode
	|
	|WHERE
	|	MaterialsAndWorksOnTypesOfRepairs.Products IS NULL";
	
	Query = New Query(QueryText);
	Query.SetParameter("OrderRepairs", OrderRepairs.Unload());
	Query.SetParameter("MaterialsAndWorksOfTheOrder", MaterialsAndWorksOfTheOrder.Unload());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	LineNumber = 1;
	While Selection.Next() Do
	
		NewRow = UsedMaterials.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.LineNumber = LineNumber;
		
		LineNumber = LineNumber + 1;
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	StructureOfActions.Insert(
		"FillInArticleAttribute",
		New Structure("Products", "SKU"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(UsedMaterials, StructureOfActions);
	
EndProcedure

&AtServer
Procedure GetOrderData()

	AddressOrderDetails = Parameters.AddressOrderDetails;
	OrderData = GetFromTempStorage(AddressOrderDetails);
	
	TMCommonUseClientServer.SupplementTable(OrderData.RM, OrderRepairs);
	
	SourceTable = OrderData.MaterialsAndWorks; // ValueTable - 
	SourceTable.GroupBy("Products,Characteristic,Package,RMCode", "Count,NumberOfPackages");
	TMCommonUseClientServer.SupplementTable(SourceTable, MaterialsAndWorksOfTheOrder);
	
EndProcedure

&AtClient
Function ThereIsDataToTransfer()
	
	For Each String In UsedMaterials Do
		
		If String.RowIsSelected Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure BeforeClosingMoveAndClose(QuestionResult, AdditionalParameters) Export
	
	TransferContentToDocument();
	
EndProcedure

&AtClient
Procedure TransferContentToDocument()
	
	Modified = False;
	
	PrepareDataForSelectionOfMaterialsForTypesOfRepairs();
	
	Close(AddressOrderDetails);
	
EndProcedure

&AtServer
Procedure PrepareDataForSelectionOfMaterialsForTypesOfRepairs()
	
	TableOfSelectedMaterials = UsedMaterials.Unload(New Structure("RowIsSelected", True));
	PutToTempStorage(TableOfSelectedMaterials, AddressOrderDetails);
	
EndProcedure

&AtClient
Procedure SetStringSelection(SelectionValue)
	
	For Each LineNumber In Items.UsedMaterials.SelectedRows Do
		TSRow = UsedMaterials.FindByID(LineNumber);
		TSRow.RowIsSelected = SelectionValue;        
	EndDo;
	
EndProcedure

#EndRegion
