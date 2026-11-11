#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Cell                = Parameters.Cell;
	Warehouse                 = Parameters.Warehouse;
	Premise             = Parameters.Premise;
	OperationType           = Parameters.OperationType;
	Organization           = Parameters.Organization;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	DocumentBarcode     = Parameters.DocumentBarcode;
	CellBarcode        = Parameters.CellBarcode;
	ScanningProcedure   = Parameters.ScanningProcedure;
	
	If Parameters.Property("Mode") Then
		Mode = Parameters.Mode;
	EndIf;
	
	If Parameters.Property("Ref") Then
		Ref = Parameters.Ref;
	EndIf;
	
	If Parameters.Property("PrintQuantityByRecords") Then
		PrintQuantityByRecords = Parameters.PrintQuantityByRecords;
	EndIf;
	
	If Parameters.Property("SelectionOrder_") Then
		SelectionOrder_ = Parameters.SelectionOrder_;
	EndIf;
	
	If Parameters.Property("Goods") Then
		
		ProductsInCell = Parameters.Goods;
		
		For Each String In ProductsInCell Do
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, String);
			If OperationType = 1 Then
				NewRow.TitleActual = NStr("vi = 'Đã xếp vào';
											|ru = 'Размещено';
											|en = 'Put away'; fa = 'جای‌گذاری';
											|it = 'Размещено';
											|pl = 'Put away';
											|tr = 'Yerleştirildi'");
			ElsIf OperationType = 2 Then
				NewRow.TitleActual = NStr("vi = 'Đã lấy ra';
											|ru = 'Отобрано';
											|en = 'Picked'; fa = 'برداشت‌شده';
											|it = 'Отобрано';
											|pl = 'Picked';
											|tr = 'Toplanan'");
			EndIf;
			NewRow.Cell = Cell;
			
		EndDo;
		
	EndIf;
	
	If OperationType = 3 Then
		
		If Mode = "EditingMoving" Then
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, Parameters);
		EndIf;
		
		If Parameters.Property("ReplacementCell") Then
			ReplacementCell = Parameters.ReplacementCell;
		EndIf;
		
	EndIf;
	
	SetConditionalAppearance();
	
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
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateForm", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackages);
	If OperationType = 1 Then
		FormParameters.Insert("Mode", "EditingPlacementByCells");
	ElsIf OperationType = 2 Then
		FormParameters.Insert("Mode", "EditingSelectionFromShipmentCell"); 
	ElsIf OperationType = 3 And Mode <> "EditingMoving" Then
		FormParameters.Insert("Mode", "Move");
	ElsIf OperationType = 4 Then
		FormParameters.Insert("Mode", "EditingRecalculation");
		FormParameters.Insert("Count", Item.CurrentData.NumberOfPackagesPlaced);
	Else
		FormParameters.Insert("Mode", "View");
	EndIf;
	FormParameters.Insert("LineNumber", Goods.IndexOf(Items.Goods.CurrentData));
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	If Item.CurrentData.ReplacementCell.IsEmpty() Then
		FormParameters.Insert("Cell", Item.CurrentData.Cell);
	Else
		FormParameters.Insert("Cell", Item.CurrentData.ReplacementCell);
	EndIf;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("DocumentSource", Ref);
	FormParameters.Insert("DocumentBarcode", DocumentBarcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Confirm(Command)
		
	CloseForm();
	
EndProcedure

&AtClient
Procedure CloseForm(NextCellData = Undefined)
	
	If OperationType = 3 And Not ValueIsFilled(ReplacementCell) Then
		ErrorText = NStr("vi = 'Hãy chỉ ra ô để sắp xếp';
						|ru = 'Укажите ячейку для размещения';
						|en = 'Specify a storage bin to put away'; fa = 'Specify a storage bin to put away';
						|it = 'Indicare la cella per lo spostamento';
						|pl = 'Podaj komórkę do rozmieszczenia';
						|tr = 'Yerleşim için hücre belirt'");
		Status(ErrorText);
		Return;
	EndIf;

	ArrayOfPlacements = New Array;
	
	For Each String In Goods Do
		
		Structure = StructureOfGoods();
		
		FillPropertyValues(Structure, String);
		
		Structure.Insert("NumberOfPackages", String.NumberOfPackagesPlaced);
		
		ArrayOfPlacements.Add(Structure);
		
	EndDo;
	
	BuildResult = New Structure;
	BuildResult.Insert("Cell", Cell);
	BuildResult.Insert("ArrayOfPlacements", ArrayOfPlacements);
	BuildResult.Insert("Mode", Mode);
	BuildResult.Insert("PackageBarcodes", PackageBarcodes);
	BuildResult.Insert("NextCellData", NextCellData);
	
	Close(BuildResult);
	
EndProcedure

&AtClient
Procedure Block(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell", Cell);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.StorageBinLock",FormParameters,
	ThisObject,,,,,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	ValueList = New ValueList;
	ValueList.Add("Cell", NStr("vi = 'Ô hàng';
								|ru = 'Ячейку';
								|en = 'Storage bin'; fa = 'محل نگهداری';
								|it = 'Cella';
								|pl = 'Storage bin';
								|tr = 'Hücrenin'"));
	ValueList.Add("OwnGoods", NStr("vi = 'Hàng hóa';
									|ru = 'Товар';
									|en = 'Item'; fa = 'قلم';
									|it = 'Merce';
									|pl = 'Item';
									|tr = 'Ürün'"));
	ValueList.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Cancel';
								|tr = 'İptal'"));
	
	Notification = New CallbackDescription("AfterClosingQuestionChoice", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Scan';
									|ru = 'Сканировать';
									|en = 'Scan'; fa = 'اسکن';
									|it = 'Scansionare';
									|pl = 'Scan';
									|tr = 'Tara'"), ValueList, 0);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	If OperationType = 1 Then
		UpdateHint();
		Items.Confirm.Title = NStr("vi = 'Kết thúc xếp vào';
									|ru = 'Закончить размещение';
									|en = 'Finish put-away'; fa = 'پایان جای‌گذاری';
									|it = 'Concludere inserimento';
									|pl = 'Zakończ rozmieszczenie';
									|tr = 'Yerleşimi bitir'");
		Title = NStr("vi = 'Xếp vào ô hàng';
					|ru = 'Размещение в ячейку';
					|en = 'Put away to storage bin'; fa = 'جای‌گذاری در محل نگهداری';
					|it = 'Inserimento nella cella';
					|pl = 'Przemieszczenie do komórki';
					|tr = 'Hücreye yerleştirme'");
	ElsIf OperationType = 2 Then
		UpdateHint();
		Items.Confirm.Title = NStr("vi = 'Kết thúc lấy ra';
									|ru = 'Закончить отбор';
									|en = 'Finish picking'; fa = 'پایان برداشت';
									|it = 'Concludere filtro';
									|pl = 'Zakończ wybór';
									|tr = 'Filtreyi bitir'");
		Title             = NStr("vi = 'Lọc từ ô';
								|ru = 'Отбор из ячейки';
								|en = 'Picking from storage bin'; fa = 'Picking from storage bin';
								|it = 'Filtro dalle celle';
								|pl = 'Wybór z komórki';
								|tr = 'Hücreden filtre'");
	ElsIf OperationType = 3 Then
		UpdateHint();
		Items.Confirm.Title             = NStr("vi = 'Điều chuyển';
												|ru = 'Переместить';
												|en = 'Move'; fa = 'انتقال';
												|it = 'Spostare';
												|pl = 'Move';
												|tr = 'Transfer et'");
		Title                         = NStr("vi = 'Điều chuyển';
											|ru = 'Перемещение';
											|en = 'Move'; fa = 'انتقال';
											|it = 'Spostamento';
											|pl = 'Move';
											|tr = 'Transfer'");
		Items.ReplacementCell.Visible            = True;
		Items.TooltipGroup.Visible         = False;
		Items.GoodsTitleActual.Visible     = False;
		Items.GoodsPackagePlaced.Visible = True;
		Items.Cell.Title                  = NStr("vi = 'Ô hàng lấy ra';
												|ru = 'Ячейка отбор';
												|en = 'Storage bin picking'; fa = 'محل نگهداری برداشت';
												|it = 'Cella filtro';
												|pl = 'Komórka filtr';
												|tr = 'Hücre filtre'");
		Items.ReplacementCell.Title            = NStr("vi = 'Ô hàng xếp vào';
														|ru = 'Ячейка размещение';
														|en = 'Storage bin put-away'; fa = 'محل نگهداری جای‌گذاری';
														|it = 'Cella spostamento';
														|pl = 'Komórka rozmieszczenie';
														|tr = 'Hücre yerleşim'");
	ElsIf OperationType = 4 Then
		UpdateHint();
		Items.Confirm.Title = NStr("vi = 'Kết thúc kiểm đếm';
									|ru = 'Закончить пересчет';
									|en = 'Finish recalculation'; fa = 'Finish recalculation';
									|it = 'Concludere ricalcolo';
									|pl = 'Zakończ przeliczenie';
									|tr = 'Yeniden hesaplamayı bitir'");
		Title             = NStr("vi = 'Tính lại trong ô';
								|ru = 'Пересчет в ячейке';
								|en = 'Recalculation in a cell'; fa = 'Recalculation in a cell';
								|it = 'Пересчет в ячейке';
								|pl = 'Recalculation in a cell';
								|tr = 'Hücrede yeniden hesaplama'");
	EndIf;
	
	If OperationType = 4 And Not PrintQuantityByRecords Then
		Items.GoodsNumberOfPackagesPlaced.TextColor = StyleColors.TextColorIssue;
		Items.GoodsNumberOfPackages.Visible = False;
	Else
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
		FormattedField.Field = New DataCompositionField("GoodsNumberOfPackagesPlaced");
		
		FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("Goods.NumberOfPackages");
		FilterElement.ComparisonType = DataCompositionComparisonType.NotEqual;
		FilterElement.RightValue = New DataCompositionField("Goods.NumberOfPackagesPlaced");
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue);
	EndIf;
	
EndProcedure

&AtClient
Function StructureOfGoods()
	
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

&AtServer
Procedure UpdateHint()
	
	If OperationType = 1 Then
		Items.TitleHint1.Title = NStr("vi = 'Sắp xếp dòng';
										|ru = 'Размещено строк';
										|en = 'Lines placed'; fa = 'Lines placed';
										|it = 'Размещено строк';
										|pl = 'Lines placed';
										|tr = 'Yerleştirilen satırlar'");
	ElsIf OperationType = 4 Then
		Items.TitleHint1.Title = NStr("vi = 'Tính lại';
										|ru = 'Пересчитано';
										|en = 'Recalculated'; fa = 'Recalculated';
										|it = 'Пересчитано';
										|pl = 'Recalculated';
										|tr = 'Yeniden hesaplandı'");
	Else
		Items.TitleHint1.Title = NStr("vi = 'Đã xử lý dòng';
										|ru = 'Отобрано строк';
										|en = 'Lines selected'; fa = 'Lines selected';
										|it = 'Отобрано строк';
										|pl = 'Lines selected';
										|tr = 'Seçilen satırlar'");
	EndIf;
	
	Plan = Goods.Count();
	CompletedLinesWithoutErrors = 0;
	For Each String In Goods Do
		If String.NumberOfPackages = String.NumberOfPackagesPlaced Then
			CompletedLinesWithoutErrors = CompletedLinesWithoutErrors + 1;
		EndIf;
	EndDo;
		
	Items.TitleHintFact.Title = CompletedLinesWithoutErrors;
	Items.TitleHintPlan.Title = Plan;
	Items.TitleHintDifference.Title = Plan - CompletedLinesWithoutErrors;

EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ConfirmQuantity(Result);
	If ValueIsFilled(Result.DataOfFollowingItem) Then
		ResultOfScanningItem(Result.DataOfFollowingItem);
	ElsIf ValueIsFilled(Result.NextCellData) Then
		CellScanResult(Result.NextCellData);	
	EndIf;
		
	If Result.CloseCard And IsOpen() Then
		CloseForm();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfirmQuantity(Result = Undefined, AdditionalParameters = Undefined)
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Result.Products);
	TheStructureOfTheSearch.Insert("Characteristic", Result.Characteristic);
	TheStructureOfTheSearch.Insert("Package", Result.Package);
	TheStructureOfTheSearch.Insert("Series", Result.Series); 
	TheStructureOfTheSearch.Insert("Purpose", Result.Purpose);

	If Result.Mode = "EditingPlacementByCells"
		Or Result.Mode = "EditingSelectionFromShipmentCell" Then
			
		Literal = "LineNumber";
		LineNumber = Result[Literal];
		
		SeriesOnShipment = SeriesOfItemsForShipment(Result.Products);
		
		If Result.Mode = "EditingSelectionFromShipmentCell"
			And Not ValueIsFilled(Goods[LineNumber].Series) 
			And SeriesOnShipment.SpecifyByPickingResult 
			And SeriesOnShipment.AccountForRemainingSeries Then 
			TheStructureOfTheSearch.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
			SearchResult = Goods.FindRows(TheStructureOfTheSearch);
			If SearchResult.Count() > 0 Then  
				SubtractedValue = Min(SearchResult[0].NumberOfPackages, Result.NumberOfPackages);
				SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages - SubtractedValue; 
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, Result,,"NumberOfPackages");
				NewRow.NumberOfPackages = SubtractedValue;
				NewRow.NumberOfPackagesPlaced = Result.NumberOfPackages;

				If SearchResult[0].NumberOfPackages <= 0 Then
					Goods.Delete(SearchResult[0])
				EndIf;
			UpdateHint();
			Return;
			EndIf;
		EndIf;

		Goods[LineNumber].NumberOfPackagesPlaced = Result.NumberOfPackages;
		If Goods[LineNumber].Cell <> Result.Cell Then
			Goods[LineNumber].ReplacementCell = Result.Cell;
		EndIf;
		Goods[LineNumber].Series = Result.Series;
		
	Else
		
		SearchResult = Goods.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() > 0 Then
			If Result.Mode = "EditingRecalculation" Then
				SearchResult[0].NumberOfPackagesPlaced = Result.NumberOfPackages;
			Else
				SearchResult[0].NumberOfPackagesPlaced = SearchResult[0].NumberOfPackagesPlaced + Result.NumberOfPackages;
			EndIf;
			SearchResult[0].Series = Result.Series;
		ElsIf Result.NumberOfPackages > 0 Then
			
			If Result.Mode = "SelectionFromShipmentCell" Then
				TheStructureOfTheSearch.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
				SearchResult = Goods.FindRows(TheStructureOfTheSearch);
				If SearchResult.Count() > 0 Then  
					SubtractedValue = Min(SearchResult[0].NumberOfPackages, Result.NumberOfPackages);
					SearchResult[0].NumberOfPackages = SearchResult[0].NumberOfPackages - SubtractedValue; 
					NewRow = Goods.Add();
					FillPropertyValues(NewRow, Result,,"NumberOfPackages");
					NewRow.NumberOfPackages = SubtractedValue;
					NewRow.NumberOfPackagesPlaced = Result.NumberOfPackages;

					If SearchResult[0].NumberOfPackages <= 0 Then
						Goods.Delete(SearchResult[0])
					EndIf; 
				UpdateHint();
				Return;
				EndIf;
			EndIf;
					
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, Result,,"NumberOfPackages");
			NewRow.NumberOfPackagesPlaced = Result.NumberOfPackages;
			
			If Result.Mode = "Move" Then
				NewRow.Cell             = Cell;
				NewRow.ReplacementCell       = ReplacementCell;
				NewRow.NumberOfPackages = NewRow.NumberOfPackagesPlaced;
				NewRow.PackagePlaced  = NewRow.Package;
			ElsIf Result.Mode = "PlacementInCell" Then
				NewRow.TitleActual = NStr("vi = 'Đã xếp vào';
											|ru = 'Размещено';
											|en = 'Put away'; fa = 'جای‌گذاری';
											|it = 'Размещено';
											|pl = 'Put away';
											|tr = 'Yerleştirildi'");
			ElsIf Result.Mode = "SelectionFromShipmentCell" Then
				NewRow.TitleActual = NStr("vi = 'Đã lấy ra';
											|ru = 'Отобрано';
											|en = 'Picked'; fa = 'برداشت‌شده';
											|it = 'Отобрано';
											|pl = 'Picked';
											|tr = 'Toplanan'");
			EndIf;
		EndIf;
		
	EndIf;
	
	For Each LineMarkingCode In Result.PackageBarcodes Do
			
		NewRow = PackageBarcodes.Add();
		FillPropertyValues(NewRow, LineMarkingCode);
			
	EndDo;
		
	UpdateHint();
	
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1);
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
	Barcode = BarcodeData_1.Barcode;
	
	If DocumentBarcode = Barcode Then 
		CloseForm();
		Return;
	EndIf;
	
	If CellBarcode = Barcode Then
		CloseForm();
		Return;
	EndIf;

	CellData = CellDataByWK(Barcode); 
		
	If ValueIsFilled(CellData.Cell) Then  
		CellScanResult(CellData);
		Return;
	EndIf;

	ProductData_9 = ItemDataBySchool(BarcodeData_1.Barcode);
			
	If ValueIsFilled(ProductData_9) Then	
		ResultOfScanningItem(ProductData_9);
		Return;
	EndIf;
	
	Status(NStr("vi = 'Không tìm thấy mặt hàng hoặc ô hàng theo mã vạch';
				|ru = 'Номенклатура или ячейка по штрихкоду не найдена';
				|en = 'Item or storage bin is not found by barcode'; fa = 'Item or storage bin is not found by barcode';
				|it = 'Item or storage bin is not found by barcode';
				|pl = 'Item or storage bin is not found by barcode';
				|tr = 'Barkod ile ürün veya depo yeri bulunamadı'"));
	
EndProcedure

&AtServerNoContext
Function ItemDataBySchool(Barcode)
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.ItemDataBySchool(Barcode);
	
EndFunction

&AtServer
Function CellDataByWK(Val Barcode) 
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.CellDataByWK(Warehouse, Premise, Barcode);
	
EndFunction

&AtClient
Procedure AfterClosingQuestionChoice(Result, Var_Parameters) Export
	
	If Result = Undefined 
		Or Result = "Cancel" Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("DocumentRef", Ref);
		
	If Result = "Cell" Then
		
		LongDesc = New CallbackDescription("CellScanResult", ThisObject);
		FormParameters.Insert("FindType", "CellSearch");
		
	ElsIf Result = "OwnGoods" Then
		
		LongDesc = New CallbackDescription("ResultOfScanningItem", ThisObject);
		FormParameters.Insert("FindType", "ProductItemsSearch");
		FormParameters.Insert("Organization", Organization);
		
	EndIf;
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	Else
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode",FormParameters,
		ThisObject,,,,LongDesc,
		FormWindowOpeningMode.Independent);
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
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products",   ProductData_8.Products);
		TheStructureOfTheSearch.Insert("Characteristic", ProductData_8.Characteristic);
		TheStructureOfTheSearch.Insert("Package",       ProductData_8.Package);
		
		LongDesc = New CallbackDescription("UpdateForm", ThisObject);
		
		FormParameters = New Structure;
			
		SearchResult = Goods.FindRows(TheStructureOfTheSearch);
		
		If Not OperationType = 3 Or Mode = "EditingMoving" Then
			
			If SearchResult.Count() > 0 Then
						
				FormParameters.Insert("Products",   SearchResult[0].Products);
				FormParameters.Insert("Characteristic", SearchResult[0].Characteristic);
				FormParameters.Insert("Series",          SearchResult[0].Series);
				FormParameters.Insert("Purpose",     SearchResult[0].Purpose);
				FormParameters.Insert("Package",       SearchResult[0].Package);
				FormParameters.Insert("LineNumber",    Goods.IndexOf(Items.Goods.CurrentData));
						
				If OperationType = 1 Then
					FormParameters.Insert("Mode", "PlacementInCell");
				ElsIf OperationType = 2 Then
					FormParameters.Insert("Mode", "SelectionFromShipmentCell");
					FormParameters.Insert("SelectionOrder_", SelectionOrder_);
				ElsIf OperationType = 4 Then
					FormParameters.Insert("Mode", "Recalculate");
				Else
					FormParameters.Insert("Mode", "View");
				EndIf;
				
				If SearchResult[0].ReplacementCell.IsEmpty() Then
					FormParameters.Insert("Cell", SearchResult[0].Cell);
				Else
					FormParameters.Insert("Cell", SearchResult[0].ReplacementCell);
				EndIf;
			
			Else
				
				If OperationType = 1 Then
					OperationText = NStr("vi = 'xếp vào';
										|ru = 'размещение';
										|en = 'put-away'; fa = 'put-away';
										|it = 'put-away';
										|pl = 'put-away';
										|tr = 'Yerleşim'");
				ElsIf OperationType = 2 Then
					OperationText = NStr("vi = 'lấy ra';
										|ru = 'отбор';
										|en = 'picking'; fa = 'picking';
										|it = 'selezione';
										|pl = 'filtr';
										|tr = 'filtre'");	
				ElsIf OperationType = 3 Then	
					OperationText = NStr("vi = 'điều chuyển';
										|ru = 'перемещение';
										|en = 'transfer'; fa = 'transfer';
										|it = 'transfer';
										|pl = 'transfer';
										|tr = 'transfer'");	
				Else
					OperationText = NStr("vi = 'kiểm đếm';
										|ru = 'пересчет';
										|en = 'physical count'; fa = 'physical count';
										|it = 'physical count';
										|pl = 'physical count';
										|tr = 'yeniden hesaplama'");
				EndIf;
				
				ErrorText = StrTemplate(NStr("vi = 'Không cần %1 mặt hàng %2 có bộ đóng gói %3';
											|ru = 'Не требуется %1 номенклатуры %2 в упаковке %3';
											|en = '%1 of the %2 items in the %3 packaging unit are not required'; fa = '%1 of the %2 items in the %3 packaging unit are not required';
											|it = 'Non necessita di %1 di articoli %2 nell''imballaggio %3';
											|pl = 'Nie jest wymagany %1 produkt %2 w opakowaniu %3';
											|tr = 'Paketleme ünitesinde %1 ürün gamı %2 gerekmiyor %3'"), OperationText, 
					ProductData_8.Products, ProductData_8.Package);
					
				Status(ErrorText); 
				Return;
				
			EndIf;
			
		Else
			
			FormParameters.Insert("Products", ProductData_8.Products);
			FormParameters.Insert("Characteristic", ProductData_8.Characteristic);
			FormParameters.Insert("Package",       ProductData_8.Package);
			FormParameters.Insert("Series", ProductData_8.Series);
			If OperationType = 3 Then
				FormParameters.Insert("Mode", "Move");
			Else
				FormParameters.Insert("Mode", "View");
			EndIf;
			FormParameters.Insert("LineNumber", 0);
			
			If ReplacementCell.IsEmpty() Then
				FormParameters.Insert("Cell", Cell);
			Else
				FormParameters.Insert("Cell", ReplacementCell);
			EndIf;

		EndIf;
			
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise); 
		FormParameters.Insert("Count", ProductData_8.Count);
		FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		FormParameters.Insert("Source", Ref);
		FormParameters.Insert("DocumentBarcode", DocumentBarcode);
		FormParameters.Insert("PackageBarcode", ProductData_8.PackageBarcode);
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
	
	If Result.Cell = Cell
		Or Result.Cell = ReplacementCell Then
		CloseForm();
	ElsIf OperationType = 3 And Not ValueIsFilled(ReplacementCell) Then	
		SetCell(Result.Cell);
	Else
		CloseForm(Result);
	EndIf;

EndProcedure

&AtClient
Procedure SetCell(Result) 
		
	ReplacementCell = Result;
	
	For Each String In Goods Do
		String.ReplacementCell = ReplacementCell;
	EndDo;
	
EndProcedure 

&AtServer
Function SeriesOfItemsForShipment(Val Products)
	
	ProductKind =  MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Products, "ProductKind");
	BatchAccountingPolicy = DataProcessors.MobileWarehouseKeeperWorkspace.BatchAccountingPolicy(ProductKind, Warehouse);
	If ValueIsFilled(BatchAccountingPolicy) Then
		SeriesOnShipment = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(BatchAccountingPolicy, "SpecifyByPickingResult,
		|	AccountForRemainingSeries");
	Else
		SeriesOnShipment = New Structure("SpecifyByPickingResult,
		|	AccountForRemainingSeries", False, False);
	EndIf;
	
	Return SeriesOnShipment;
	
EndFunction
#EndRegion