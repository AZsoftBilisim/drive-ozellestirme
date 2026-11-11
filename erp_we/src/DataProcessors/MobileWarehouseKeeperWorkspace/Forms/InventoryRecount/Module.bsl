
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Ref = Parameters.Ref;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;
	
	FillForm();
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
		
		StandardProcessing = False;   
		Cancel = True;
		Items.GroupPages.CurrentPage = Items["PageToReceive"];
		
	EndIf;
	
EndProcedure  

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then 
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
				
				Data = MobileWarehouseKeeperWorkspaceClient.ConvertDataFromScannerToStructure(Parameter);
				
				ProcessBarcode(Data);

			EndIf;
		EndIf;
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Information(Command)
	
	Items.GroupPages.CurrentPage = Items["InformationPage"];
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackagesReal);
	FormParameters.Insert("Mode", "EditingRecalculation");
	FormParameters.Insert("LineNumber", Item.CurrentRow);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("Cell", Item.CurrentData.Cell);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure FinishRecalculation(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Kết thúc';
									|ru = 'Завершить';
									|en = 'Finish'; fa = 'پایان';
									|it = 'Completare';
									|pl = 'Zakończ';
									|tr = 'Tamamla'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Kontynuuj';
									|tr = 'Devam et'"));
	
	Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Kết thúc kiểm đếm?';
									|ru = 'Закончить пересчет?';
									|en = 'Finish recount?'; fa = 'Finish recount?';
									|it = 'Terminare il ricalcolo?';
									|pl = 'Zakończyć przeliczenie?';
									|tr = 'Yeniden hesaplamayı bitir?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("DocumentRef", Ref);
	FormParameters.Insert("Mode", "Recalculate");
	
	If UseBinLocationWarehousing Then 
		
		FormParameters.Insert("FindType", "CellSearch");
		LongDesc = New CallbackDescription("CellScanResult", ThisObject);
		
	Else
		
		FormParameters.Insert("FindType", "ProductItemsSearch");
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		
	EndIf;
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
		ThisObject,,,, LongDesc,
		FormWindowOpeningMode.Independent);
	Else
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode",FormParameters,
		ThisObject,,,, LongDesc,
		FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesIsDifference.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackagesIsDifference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue);
	
	Items.GoodsCell.Visible = UseBinLocationWarehousing;
	
	Items.GoodsNumberOfPackages.Visible = PrintQuantityByRecords;
	Items.GoodsNumberOfPackagesIsDifference.Visible = PrintQuantityByRecords;
	
EndProcedure

&AtServer
Procedure FillForm()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	InventoryRecount.Number AS Number,
		|	InventoryRecount.Date AS Date,
		|	InventoryRecount.Performer AS Performer,
		|	InventoryRecount.Comment AS Comment,
		|	InventoryRecount.Premise AS Premise,
		|	InventoryRecount.Warehouse AS Warehouse,
		|	InventoryRecount.PrintQuantityByRecords AS PrintQuantityByRecords,
		|	CASE
		|		WHEN InventoryRecount.Warehouse.UseWarerooms
		|			THEN InventoryRecount.Premise.UseBinLocationWarehousing
		|		ELSE InventoryRecount.Warehouse.UseBinLocationWarehousing
		|	END AS UseBinLocationWarehousing,
		|	InventoryRecount.Goods.(
		|		Count AS Count,
		|		CountReal AS CountReal,
		|		NumberOfPackages AS NumberOfPackages,
		|		NumberOfPackagesReal AS NumberOfPackagesReal,
		|		Products AS Products,
		|		Products.SKU AS SKU,
		|		CASE
		|			WHEN Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				THEN Products.UnitOfMeasure
		|			ELSE Package
		|		END AS Package,
		|		Characteristic AS Characteristic,
		|		Purpose AS Purpose,
		|		Cell AS Cell,
		|		Series AS Series,
		|		BatchesIndicationStatus AS BatchesIndicationStatus,
		|		NumberOfPackagesReal - NumberOfPackages AS NumberOfPackagesIsDifference,
		|		CountReal - Count AS QuantityDifference
		|	) AS GoodsTable
		|FROM
		|	Document.InventoryRecount AS InventoryRecount
		|WHERE
		|	InventoryRecount.Ref = &Ref";
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();
	FillPropertyValues(ThisObject, SelectionDetailRecords);
	
	Goods.Load(SelectionDetailRecords.GoodsTable.Unload());
	
EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateFormOnServer(Result);
	If ValueIsFilled(Result.DataOfFollowingItem) Then
		ResultOfScanningItem(Result.DataOfFollowingItem);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFormOnServer(Result)
	
	PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(Result.Package, Result.Products);
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Result.Products);
	TheStructureOfTheSearch.Insert("Characteristic", Result.Characteristic);
	TheStructureOfTheSearch.Insert("Series", Result.Series);
	TheStructureOfTheSearch.Insert("Package", Result.Package);
	TheStructureOfTheSearch.Insert("Purpose", Result.Purpose);
	TheStructureOfTheSearch.Insert("Cell", Result.Cell);
			
	SearchResult = Goods.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		
		If Result.Mode = "EditingRecalculation" Then
			SearchResult[0].NumberOfPackagesReal = Result.NumberOfPackages;
		Else
			SearchResult[0].NumberOfPackagesReal = SearchResult[0].NumberOfPackagesReal + Result.NumberOfPackages;
		EndIf;

		SearchResult[0].CountReal = SearchResult[0].NumberOfPackagesReal * PackagingFactor;
		
		SearchResult[0].NumberOfPackagesIsDifference = SearchResult[0].NumberOfPackagesReal - SearchResult[0].NumberOfPackages;
		SearchResult[0].QuantityDifference = SearchResult[0].NumberOfPackagesIsDifference * PackagingFactor;
		
	Else
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, Result,,"NumberOfPackages");
		NewRow.NumberOfPackagesReal = Result.NumberOfPackages;
		NewRow.CountReal = Result.NumberOfPackages * PackagingFactor;
		NewRow.NumberOfPackagesIsDifference = NewRow.NumberOfPackagesReal;
		NewRow.QuantityDifference = NewRow.NumberOfPackagesIsDifference * PackagingFactor;
		
	EndIf;
	
EndProcedure

&AtServer
Function FinishRecalculationOnServer()
	
	WriteErrorTemplate = NStr("vi = 'Không thể ghi lại %1. %2';
								|ru = 'Не удалось записать %1. %2';
								|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
								|it = 'Impossibile registrare %1. %2';
								|pl = 'Nie udało się zapisać %1. %2';
								|tr = '%1 kaydedilemedi. %2'");
	
	DocumentObject = Ref.GetObject();
	
	DocumentObject.Status      = Enums.InventoryRecountStatuses.Completed2;
	DocumentObject.Premise   = Premise;
	DocumentObject.Comment = Comment;
	DocumentObject.Performer = Performer;
	
	DocumentObject.Goods.Clear();
	
	If MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Warehouse, "UseWarerooms")
		And Premise.IsEmpty() Then
		
		ErrorText = NStr("vi = 'Chưa chọn nhà kho';
						|ru = 'Не выбрано помещение';
						|en = 'Wareroom is not selected'; fa = 'Wareroom is not selected';
						|it = 'Locale non selezionato';
						|pl = 'Nie wybrano pomieszczenia';
						|tr = 'Alan seçilmedi'");
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return False;
		
	EndIf;
		
	For Each String In Goods Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, String);
		If String.NumberOfPackagesIsDifference <> 0 Then
			NewRow.SurplusDamage = True;
		EndIf;
		
	EndDo;
	
	SeriesSpecificationParameters = Documents.InventoryRecount.SeriesSpecificationParameters(DocumentObject);
	MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
	Except
		DocumentObject.Write(DocumentWriteMode.Write);
		
		ErrorText = StrTemplate(WriteErrorTemplate, Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

&AtServer
Function CellDataByWK(Val Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.CellDataByWK(Warehouse, Premise, Barcode);
	
EndFunction 

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		AcceptanceIsComplete = FinishRecalculationOnServer();
		
		If AcceptanceIsComplete Then
			Close();
		Else
			Status(ErrorText);
		EndIf;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1);
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
	If Barcode = BarcodeData_1.Barcode Then  
				
		RecalculationCompleted = FinishRecalculationOnServer();
		
		If RecalculationCompleted Then
			Close();
		Else
			Status(ErrorText);
		EndIf;
		
		Return;
	EndIf;
	
	CellSearchFirst = (ScanningProcedure = "FirstScanCell");

	If UseBinLocationWarehousing Then
	
		If CellSearchFirst Then
			
			CellData = CellDataByWK(BarcodeData_1.Barcode); 
			
			If ValueIsFilled(CellData.Cell) Then
				CellScanResult(CellData);
				Return;
			EndIf;
					
			Status(NStr("vi = 'Không tìm thấy ô theo mã vạch';
						|ru = 'Ячейка по штрихкоду не найдена';
						|en = 'Storage bin is not found by barcode'; fa = 'Storage bin is not found by barcode';
						|it = 'Storage bin is not found by barcode';
						|pl = 'Storage bin is not found by barcode';
						|tr = 'Barkod ile depo yeri bulunamadı'"));
		Else
			ProductData_9 = ItemDataBySchool(BarcodeData_1.Barcode); 
		
			If ValueIsFilled(ProductData_9) Then
				ResultOfScanningItem(ProductData_9);
				Return;
			EndIf;
			
			Status(NStr("vi = 'Không tìm thấy mặt hàng theo mã vạch';
						|ru = 'Номенклатура по штрихкоду не найдена';
						|en = 'Item is not found by barcode'; fa = 'Item is not found by barcode';
						|it = 'Item is not found by barcode';
						|pl = 'Item is not found by barcode';
						|tr = 'Barkod ile öğe bulunamadı'"));
		EndIf; 
		
	Else 
		
		ProductData_9 = ItemDataBySchool(BarcodeData_1.Barcode);
			
		If ValueIsFilled(ProductData_9) Then
			ResultOfScanningItem(ProductData_9);
			Return;
		EndIf;
		
		Status(NStr("vi = 'Không tìm thấy mặt hàng theo mã vạch';
					|ru = 'Номенклатура по штрихкоду не найдена';
					|en = 'Item is not found by barcode'; fa = 'Item is not found by barcode';
					|it = 'Item is not found by barcode';
					|pl = 'Item is not found by barcode';
					|tr = 'Barkod ile öğe bulunamadı'"));
			
	EndIf;
			
EndProcedure

&AtClient
Procedure ResultOfScanningItem(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Count() > 1 Then 
		
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		
		FillingValues = New Structure;		
		FillingValues.Insert("Goods", Result);
		FillingValues.Insert("Mode", "SelectItems");
		FillingValues.Insert("Barcode", "");
		
		FormParameters = New Structure;
		FormParameters.Insert("ScanningResult", FillingValues);
		
		OpenForm(
			"DataProcessor.MobileWarehouseKeeperWorkspace.Form.ScanSelectionForm", FormParameters,
			ThisObject,,,,LongDesc, FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ProductData_8 = Result[0];
		
		If ScanningProcedure = "FirstScanCell" Then
			LongDesc = New CallbackDescription("UpdateForm", ThisObject);
		Else
			LongDesc = New CallbackDescription("AddProduct", ThisObject);
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("Products", ProductData_8.Products);
		FormParameters.Insert("Characteristic", ProductData_8.Characteristic);
		FormParameters.Insert("Series", ProductData_8.Series);
		FormParameters.Insert("Package", ProductData_8.Package);
		FormParameters.Insert("Count", ProductData_8.Count);
		FormParameters.Insert("Mode", "Recalculate");
		FormParameters.Insert("LineNumber", 0);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise); 
		FormParameters.Insert("Source", Ref);
		FormParameters.Insert("PackageBarcode", ProductData_8.PackageBarcode);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("DocumentBarcode", Barcode);
		FormParameters.Insert("ScanningProcedure", ScanningProcedure);

		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent); 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CellScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("CompleteRecalculationInCell", ThisObject);
	
	ProductsInCell = New Array;
	
	For Each String In Goods Do
		
		If String.Cell = Result.Cell Then
			
			Structure = StructureOfGoods();
			FillPropertyValues(Structure, String);
			Structure.NumberOfPackagesPlaced = String.NumberOfPackagesReal;
			
			ProductsInCell.Add(Structure);
			
		EndIf;
		
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell",      Result.Cell);
	FormParameters.Insert("Goods",      ProductsInCell);
	FormParameters.Insert("Warehouse",       Warehouse);
	FormParameters.Insert("Premise",   Premise);
	FormParameters.Insert("OperationType", 4);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("Ref", Ref);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("CellBarcode", Result.Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);
	FormParameters.Insert("Mode", "EditingRecalculation");
	FormParameters.Insert("PrintQuantityByRecords", PrintQuantityByRecords);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PlacementIntoBins",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure AddProduct(Result = Undefined, AdditionalParameters = Undefined) Export
	
	AddItemATServer(Result);
	
	If Result = Undefined Then		
		Return;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then 
		Status(ErrorText); 
	EndIf;

	If ValueIsFilled(Result.DataOfFollowingItem) Then
		ResultOfScanningItem(Result.DataOfFollowingItem);
	EndIf;
	
EndProcedure 

&AtServer
Procedure AddItemATServer(Val Result)
	
	TheStructureOfTheSearch = New Structure;
	
	If Result = Undefined Then
		
		TheStructureOfTheSearch.Insert("Cell", Catalogs.StorageBins.EmptyRef());		
		SearchResult = Goods.FindRows(TheStructureOfTheSearch);
		For Each String In SearchResult Do
			Goods.Delete(String);
		EndDo;
		
		Return;
	EndIf; 
		
	If Not ValueIsFilled(Result.Cell) And Not ValueIsFilled(Result.NextCellData) Then
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, Result); 
		Return;
	EndIf;
	
	RecalculationArray = New Array; 
	
	If ValueIsFilled(Result.Cell) Then
		Cell = Result.Cell;		
	ElsIf ValueIsFilled(Result.NextCellData) Then
		Cell = Result.NextCellData.Cell;
	EndIf;

	Structure = StructureOfItemsOfRecalculation();
	FillPropertyValues(Structure, Result);
	Structure.Cell = Cell;
	RecalculationArray.Add(Structure); 
	
	If Not ValueIsFilled(Result.DataOfFollowingItem) Then
		TheStructureOfTheSearch.Insert("Cell", Catalogs.StorageBins.EmptyRef());		
		SearchResult = Goods.FindRows(TheStructureOfTheSearch); 
			
		For Each String In SearchResult Do
			Structure = StructureOfItemsOfRecalculation();
			String.Cell = Cell;
			FillPropertyValues(Structure, String); 
			RecalculationArray.Add(Structure);
		EndDo;
			
		For Each String In SearchResult Do
			Goods.Delete(String);
		EndDo;
	EndIf;
		 
	For Each CellRow In RecalculationArray Do
		
		CellRow.Insert("Mode", Result.Mode);
		UpdateFormOnServer(CellRow);
		
	EndDo;
		
EndProcedure

&AtClient
Procedure CompleteRecalculationInCell(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each CellRow In Result.ArrayOfPlacements Do
		
		CellRow.Insert("Mode", Result.Mode);
		UpdateFormOnServer(CellRow);
		
	EndDo;
	
	If ValueIsFilled(Result.NextCellData) Then
		CellScanResult(Result.NextCellData);
	EndIf;

EndProcedure

&AtClient
Function StructureOfGoods()
	
	Structure = New Structure;
	Structure.Insert("Products","");
	Structure.Insert("Characteristic","");
	Structure.Insert("Series","");
	Structure.Insert("Package","");
	Structure.Insert("NumberOfPackages","");
	Structure.Insert("Purpose","");
	Structure.Insert("NumberOfPackagesPlaced","");
	
	Return Structure;
	
EndFunction

&AtServer
Function StructureOfItemsOfRecalculation()
	
	Structure = New Structure;
	Structure.Insert("Products","");
	Structure.Insert("Characteristic","");
	Structure.Insert("Series","");
	Structure.Insert("Purpose","");
	Structure.Insert("Package","");
	Structure.Insert("PackagePlaced","");
	Structure.Insert("NumberOfPackages","");
	Structure.Insert("NumberOfPackagesPlaced","");
	Structure.Insert("Cell","");
	Structure.Insert("ReplacementCell","");
	Structure.Insert("LineNumber","");
	
	Return Structure;
	
EndFunction 

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
