#Region Public

#Region ProcessingWithExcel

// Reads an excel file and adds an additional table.
//
// Parameters:
//  AdditionalParameters - Structure - a set of additional parameters
//  TempFileName - String - the path to the temporary file
//
// Returns:
//  RepresentableDocumentBatch - A table with two sheets:
//
Function AddAdditionalData(AdditionalParameters, TempFileName) Export

	PrintParameters = AdditionalParameters.PrintParameters;
	MainTableDocument = New SpreadsheetDocument;
	
	OutputCodes = ?(ValueIsFilled(AdditionalParameters.AdditionalColumnName), True, False);
	UsePriceManagementSystem25 = AdditionalParameters.UsePriceManagementSystem25;

	DocumentsPackage = New RepresentableDocumentBatch;
	
	FileName = TempFileName;
	
	Try
		
		ColumnNumber = ?(UsePriceManagementSystem25, 7, 5) + ?(OutputCodes,1,0);
		LineNumber  = 1;
		
		MainTableDocument.Read(FileName, SpreadsheetDocumentValuesReadingMode.Value);
		
		// Hiding columns with nomenclature and characteristics identifiers
		VisibilityOfTDColumn(MainTableDocument, 2 + ?(OutputCodes,1,0), False);
		VisibilityOfTDColumn(MainTableDocument, 3 + ?(OutputCodes,1,0), False);
		
		If UsePriceManagementSystem25 Then
			VisibilityOfTDColumn(MainTableDocument, 4 + ?(OutputCodes,1,0), False);
			VisibilityOfTDColumn(MainTableDocument, 5 + ?(OutputCodes,1,0), False);
		EndIf;
		
		// Creating a service table for backloading
		AdditionalTabularDocument = New SpreadsheetDocument;  
		
		SetCellText(AdditionalTabularDocument, LineNumber, 1, NStr("vi = 'Mã định danh duy nhất';
																	|ru = 'Уникальный идентификатор';
																	|en = 'UUID'; fa = 'UUID';
																	|it = 'Уникальный идентификатор';
																	|pl = 'Unikalny identyfikator';
																	|tr = 'Benzersiz tanımlayıcı'"));
		SetCellText(AdditionalTabularDocument, LineNumber, 2, NStr("vi = 'Dạng giá';
																	|ru = 'Вид цены';
																	|en = 'Price type'; fa = 'نوع قیمت';
																	|it = 'Вид цены';
																	|pl = 'Rodzaj ceny';
																	|tr = 'Fiyat türü'"));
		SetCellText(AdditionalTabularDocument, LineNumber, 3, NStr("vi = 'Số cột ""Đơn giá trước đây""';
																	|ru = 'Номер колонки ""Старая цена""';
																	|en = 'The ""Old price"" column number'; fa = 'The ""Old price"" column number';
																	|it = 'Номер колонки ""Старая цена""';
																	|pl = 'Numer kolumny ""Stara cena""';
																	|tr = '""Eski fiyat"" sütun numarası'"));
		SetCellText(AdditionalTabularDocument, LineNumber, 4, NStr("vi = 'Số cột ""Phần trăm thay đổi""';
																	|ru = 'Номер колонки ""Процент изменения""';
																	|en = 'The ""Change percentage"" column number'; fa = 'The ""Change percentage"" column number';
																	|it = 'Номер колонки ""Процент изменения""';
																	|pl = 'Numer kolumny ""Zmiana procentowa""';
																	|tr = '""Yüzde değişimi"" sütun numarası'"));
		SetCellText(AdditionalTabularDocument, LineNumber, 5, NStr("vi = 'Số cột ""Đơn giá""';
																	|ru = 'Номер колонки ""Цена""';
																	|en = 'The ""Price"" column number'; fa = 'The ""Price"" column number';
																	|it = 'Номер колонки ""Цена""';
																	|pl = 'Numer kolumny ""Cena""';
																	|tr = '""Fiyat"" sütun numarası'"));
		SetCellText(AdditionalTabularDocument, LineNumber, 6, NStr("vi = 'Số cột ""Đơn vị tính""';
																	|ru = 'Номер колонки ""Единица измерения""';
																	|en = 'The ""Unit of measure"" column number'; fa = 'The ""Unit of measure"" column number';
																	|it = 'Номер колонки ""Единица измерения""';
																	|pl = 'Numer kolumny ""Jednostka miary""';
																	|tr = '""Ölçü birimi"" sütun numarası'"));
		SetCellText(AdditionalTabularDocument, LineNumber, 7, NStr("vi = 'Số cột ""Tên đơn trị""';
																	|ru = 'Номер колонки ""Уникальный идентификатор""';
																	|en = 'The ""UUID"" column number'; fa = 'The ""UUID"" column number';
																	|it = 'Номер колонки ""Уникальный идентификатор""';
																	|pl = 'Numer kolumny ""Unikalny identyfikator""';
																	|tr = '""UUID"" sütun numarası'"));
		
		VisibilityOfTDColumn(AdditionalTabularDocument, 1, False);
		VisibilityOfTDColumn(AdditionalTabularDocument, 2, False);
		VisibilityOfTDColumn(AdditionalTabularDocument, 3, False);
		VisibilityOfTDColumn(AdditionalTabularDocument, 4, False);
		VisibilityOfTDColumn(AdditionalTabularDocument, 5, False);
		VisibilityOfTDColumn(AdditionalTabularDocument, 6, False);
		VisibilityOfTDColumn(AdditionalTabularDocument, 7, False);
				
		LineNumber = LineNumber + 1;
		SettingsTree = GetFromTempStorage(PrintParameters.SettingsTreeForClient);
		For Each PriceKind In SettingsTree.Rows Do
			If PriceKind.Print Then
				
				DisplayOldPrice       = False;
				DisplayPercentageOfChange = False;
				WithdrawAmountOfChange   = False;
				For Each Column In PriceKind.Rows Do
					If Column.Parameter = "OldPrice" And Column.Print Then
						DisplayOldPrice = True;
					EndIf;
					If Column.Parameter = "ChangePercentage" And Column.Print Then
						DisplayPercentageOfChange = True;
					EndIf;
					If Column.Parameter = "AmountOfChange" And Column.Print Then
						WithdrawAmountOfChange = True;
					EndIf;
				EndDo;
				
				SetCellText(AdditionalTabularDocument, LineNumber, 1, String(PriceKind.Parameter.UUID()));
				SetCellText(AdditionalTabularDocument, LineNumber, 2, String(PriceKind.Parameter)); // Name of the type of price
				
				If DisplayOldPrice Then
					SetCellText(AdditionalTabularDocument, LineNumber, 3, ColumnNumber); // Old price
					ColumnNumber = ColumnNumber + 1;
				Else
					SetCellText(AdditionalTabularDocument, LineNumber, 3, 0);
				EndIf;
				
				If WithdrawAmountOfChange Then
					SetCellText(AdditionalTabularDocument, LineNumber, 4, ColumnNumber); // Amount of change
					ColumnNumber = ColumnNumber + 1;
				Else
					SetCellText(AdditionalTabularDocument, LineNumber, 4, 0);
				EndIf;
				
				If DisplayPercentageOfChange Then
					SetCellText(AdditionalTabularDocument, LineNumber, 4, ColumnNumber); // Percentage of change
					ColumnNumber = ColumnNumber + 1;
				Else
					SetCellText(AdditionalTabularDocument, LineNumber, 4, 0);
				EndIf;
				
				SetCellText(AdditionalTabularDocument, LineNumber, 5, ColumnNumber); // Price
				ColumnNumber = ColumnNumber + 1;
				
				SetCellText(AdditionalTabularDocument, LineNumber, 6, ColumnNumber); // Unit
				ColumnNumber = ColumnNumber + 1;
				
				VisibilityOfTDColumn(MainTableDocument, ColumnNumber, False);
				SetCellText(AdditionalTabularDocument, LineNumber, 7, ColumnNumber); // Unique identifier of the package
				ColumnNumber = ColumnNumber + 1;
				
				LineNumber = LineNumber + 1;
				
			EndIf;
		EndDo;
		
		TypesOfPrices = New Array;
		
		// Loading the service table
		LineNumber = 2;
		While ValueIsFilled(CellContent(AdditionalTabularDocument, LineNumber, 1)) Do
			
			NewRow = New Structure("ColumnNumberOldPrice, ColumnNumberPercentageOfChange, ColumnNumberPrice");
			NewRow.ColumnNumberOldPrice       = CellContent(AdditionalTabularDocument, LineNumber, 3);
			NewRow.ColumnNumberPercentageOfChange = CellContent(AdditionalTabularDocument, LineNumber, 4);
			NewRow.ColumnNumberPrice             = CellContent(AdditionalTabularDocument, LineNumber, 5);
			TypesOfPrices.Add(NewRow);
			
			LineNumber = LineNumber + 1;
			
		EndDo;

		If TypesOfPrices.Count() > 0 Then
			
			LineNumber = 3;
			While ValueIsFilled(CellContent(MainTableDocument, LineNumber, 3)) Do
				
				For Each TSRow In TypesOfPrices Do
					
					If TSRow.ColumnNumberOldPrice <> 0
						And TSRow.ColumnNumberPercentageOfChange <> 0
						And TSRow.ColumnNumberPrice <> 0 Then
						
						OldPrice = CellContent(AdditionalTabularDocument, LineNumber, TSRow.ColumnNumberOldPrice);
						Price = CellContent(AdditionalTabularDocument, LineNumber, TSRow.ColumnNumberPrice);
						
						OldPrice = ?(OldPrice = "", 0, Number(OldPrice)); 
						Price 	   = ?(Price = "", 0, Number(Price)); 
						
						If OldPrice <> 0 Then
							
							CellValue = Round(((Price-OldPrice)/OldPrice)*100 ,2);
							SetCellValue(MainTableDocument,LineNumber, TSRow.ColumnNumberPercentageOfChange, CellValue);
						Else
							
							SetCellValue(MainTableDocument,LineNumber, TSRow.ColumnNumberPercentageOfChange, 0);
						EndIf;	
						
					EndIf;
					
				EndDo;
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
		EndIf;

		NewSheet = DocumentsPackage.Content.Add();
		NewSheet.Title = NStr("vi = 'Bảng giá';
								|ru = 'Прайс-лист';
								|en = 'Price list'; fa = 'فهرست قیمت';
								|it = 'Прайс-лист';
								|pl = 'Price list';
								|tr = 'Fiyat listesi'");
		NewSheet.Data = PutToTempStorage(MainTableDocument);   

		NewSheet = DocumentsPackage.Content.Add();
		NewSheet.Title = " ";
		NewSheet.Data = PutToTempStorage(AdditionalTabularDocument);   
		
	Except
		ErrorMessage = NStr("vi = 'Không thể ghi lại dữ liệu vào tệp. Chi tiết:';
							|ru = 'Не удалось записать данные в файл. Подробности:';
							|en = 'Cannot save data to the file. Details:'; fa = 'Cannot save data to the file. Details:';
							|it = 'Не удалось записать данные в файл. Подробности:';
							|pl = 'Nie udało się zapisać danych do pliku. Szczegóły:';
							|tr = 'Dosyaya veriler kaydedilmedi. Ayrıntılar:'") + " "
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	Return DocumentsPackage;
	
EndFunction

// Handles uploading from an excel file.
//
// Parameters:
//  AddressOfBinaryData - String - Address of binary data
//  AdditionalParameters - Structure - Set of parameters
//
// Returns:
//  Structure - A set of spent data:
//		* OwnerForm - String- Owner
//		* TypesOfPrices - String -  Type of prices
//		* Goods - String - Goods
Function ProcessDownloadFromExcelPriceListOnServer(AddressOfBinaryData, AdditionalParameters) Export
	
	UsePriceManagementSystem25 = AdditionalParameters.UsePriceManagementSystem25;
    TabularDocumentWithSheets = New SpreadsheetDocument;
    AdditionalTabularDocument = New SpreadsheetDocument;
    MainTableDocument = New SpreadsheetDocument;
	
	FileName = GetTempFileName("xls");
	
	FileBinaryData = GetFromTempStorage(AddressOfBinaryData);
	FileBinaryData.Write(FileName);
	
	Try

	TabularDocumentWithSheets.Read(FileName, SpreadsheetDocumentValuesReadingMode.Value);

	If TabularDocumentWithSheets.Areas.Count() = 0 Then
		Raise(NStr("vi = 'Tệp trống!';
					|ru = 'Файл пустой!';
					|en = 'The file is empty.'; fa = 'The file is empty.';
					|it = 'Файл пустой!';
					|pl = 'The file is empty.';
					|tr = 'Dosya boş!'")) ;
	EndIf;	
	
		MainTableDocument = TabularDocumentWithSheets.GetArea(
													TabularDocumentWithSheets.Areas.Price_List_Leaf.Name);
													
		AdditionalTabularDocument = TabularDocumentWithSheets.GetArea(
													TabularDocumentWithSheets.Areas._.Name);

	Except
		ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể kết nhập tệp.
			           |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".
			           |Chi tiết: %1';
			           |ru = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |en = 'Cannot import the file.
			           |You can only import the files exported using the ""Excel -> Export..."" command.
			           |Details: %1'; fa = 'Cannot import the file.
			           |You can only import the files exported using the ""Excel -> Export..."" command.
			           |Details: %1';
			           |it = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |pl = 'Plik nie może być załadowany.
			           |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".
			           |Szczegóły:%1';
			           |tr = 'Dosya yüklenemez.
			           |Sadece ""Excel -> Yükle..."" komutuyla yüklenen dosyalar yüklenebilir.
			           |Detaylar: %1'"), BriefErrorDescription(ErrorInfo()));
		Raise ErrorMessage;
	EndTry;
	
	// Arrays of structures
	ArrayOfStructuresTypesOfPrices = New Array;
	ArrayOfDataStructures  = New Array;
	
	ThereIsAdditionalColumn = False;
	
	// Data loading
	Try
		
		// Loading the service table
		LineNumber = 2;      
		While ValueIsFilled(CellContent(AdditionalTabularDocument, LineNumber, 1)) Do
			
			NewRow = New Structure("PriceTypeId, ColumnNumberPrice, ColumnNumberPackaging");
			NewRow.PriceTypeId = CellContent(AdditionalTabularDocument, LineNumber, 1);
			NewRow.ColumnNumberPrice     = CellContent(AdditionalTabularDocument, LineNumber, 5);
			NewRow.ColumnNumberPackaging = CellContent(AdditionalTabularDocument, LineNumber, 7);
			ArrayOfStructuresTypesOfPrices.Add(NewRow);
			
			LineNumber = LineNumber + 1;
		EndDo;
		
		If ArrayOfStructuresTypesOfPrices.Count() > 0 Then
			
			// Loading item prices
			LineNumber = 3;              
			ThereIsAdditionalColumn = (StrLen(CellContent(MainTableDocument, LineNumber, 2)) <> 36);
			While ValueIsFilled(CellContent(MainTableDocument, 
								LineNumber, 2 + ?(ThereIsAdditionalColumn,1,0))) Do
				
				For Each TSRow In ArrayOfStructuresTypesOfPrices Do
					
					NewRow = New Structure(
						"ProductID_,
						|IdentifierCharacteristic,
						|IDSeriesOfDataCenters,
						|IDOfCentralDataCenter,
						|PackageIdentifier,
						|PriceTypeId,
						|Price");          
					
					NewRow.ProductID_   = CellContent(MainTableDocument, 
																				LineNumber,  2 + ?(ThereIsAdditionalColumn,1,0));
					NewRow.IdentifierCharacteristic = CellContent(MainTableDocument, 
																				LineNumber,  3 + ?(ThereIsAdditionalColumn,1,0));
					If UsePriceManagementSystem25 Then
						NewRow.IDSeriesOfDataCenters        = CellContent(MainTableDocument, 
																			LineNumber,  4 + ?(ThereIsAdditionalColumn,1,0));
						NewRow.IDOfCentralDataCenter     = CellContent(MainTableDocument, 
																			LineNumber,  5 + ?(ThereIsAdditionalColumn,1,0));
					EndIf;                            
					
					NewRow.PackageIdentifier       = CellContent(MainTableDocument, 
																			LineNumber, TSRow.ColumnNumberPackaging);
					NewRow.PriceTypeId        = TSRow.PriceTypeId;    
					NewRow.Price                        = CellContentValue(MainTableDocument, 
																			LineNumber, TSRow.ColumnNumberPrice);
					ArrayOfDataStructures.Add(NewRow);
					
				EndDo;
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
		EndIf;
		
	Except 
	
		ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể kết nhập tệp.
			           |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".
			           |Chi tiết: %1';
			           |ru = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |en = 'Cannot import the file.
			           |You can only import the files exported using the ""Excel -> Export..."" command.
			           |Details: %1'; fa = 'Cannot import the file.
			           |You can only import the files exported using the ""Excel -> Export..."" command.
			           |Details: %1';
			           |it = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |pl = 'Plik nie może być załadowany.
			           |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".
			           |Szczegóły:%1';
			           |tr = 'Dosya yüklenemez.
			           |Sadece ""Excel -> Yükle..."" komutuyla yüklenen dosyalar yüklenebilir.
			           |Detaylar: %1'"), BriefErrorDescription(ErrorInfo()));
		Raise ErrorMessage;
		
	EndTry;
	
	Data = New Structure(
		"OwnerForm, TypesOfPrices, Goods", 
		AdditionalParameters.UUID, ArrayOfStructuresTypesOfPrices, ArrayOfDataStructures);
		
	Return Data;  
	
EndFunction 

#EndRegion

// Generates a price table on the form
//
// Parameters:
//  Form - ClientApplicationForm - Form. May contain:
//    * Object - DataProcessorObject.PriceList, DocumentObject.PriceSetup - FormDataStructure
//    * SelectedPrices - ValueTable - with columns:
//      ** Ref - CatalogRef.TypesOfPrices, CatalogRef.VendorPriceTypes - Price types
//      ** Id - String - ID for formulas
//      ** Description - String - Name of price types
//    * SavedDocuments - ValueTable - (optional) with columns:
//      ** Ref - DocumentRef.VendorPriceList -
//    * Items - FormItems - May contain:
//      ** PriceTree - ValueTree, FormTable, FormDataTreeItem, FormDataTree - the main element of the form with the price tree
//    * PriceTree - ValueTree, FormTable, FormDataTreeItem, FormDataTree - the main element of the form with the price tree
//    * SettingsComposerFilter - DataCompositionSettingsComposer
//  Table name-Row-table Name
//
Procedure BuildPriceTree(Form) Export
	
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Form);
	
	PriceTableColumnsToAdd = New Array();
	DeletedPriceTableColumns   = New Array();
	ItemsToRemove            = New Array();
	ConditionalAppearances           = New Array();
	
	GroupingOption = Form.GroupingOption;
	
	If TypeOf(Form.PriceTree) = Type("FormDataCollection") Then
		ValueTree = New ValueTable;
	Else
		ValueTree = New ValueTree;
	EndIf;
	
	ValueTree.Columns.Add("Products",               New TypeDescription("CatalogRef.Products"));
	ValueTree.Columns.Add("Characteristic",             New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ValueTree.Columns.Add("PictureIndex",             New TypeDescription("Number"));
	ValueTree.Columns.Add("UnitOfMeasure",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	ValueTree.Columns.Add("SKU",                    New TypeDescription("String"));
	ValueTree.Columns.Add("ItemVariantsAreUsed", New TypeDescription("Boolean"));
	
	If ValueIsFilled(GroupingOption) Then
		ValueTree.Columns.Add("HierarchyIsGroup", New TypeDescription("Boolean"));
		ValueTree.Columns.Add("ThisIsHierarchy", New TypeDescription("Boolean"));
	EndIf; 
	
	If ThisIsVendorPriceRegistration Then
		
		ValueTree.Columns.Add("PartnerProducts",     New TypeDescription("CatalogRef.ProductCrossReferences"));
		
		If ThisIsDownloadingVendorPricesFromExternalFiles(Form) Then
			ValueTree.Columns.Add("Code",                                   New TypeDescription("String"));
			ValueTree.Columns.Add("NomenclatureName",              New TypeDescription("String"));
			ValueTree.Columns.Add("CharacteristicName",            New TypeDescription("String"));
			ValueTree.Columns.Add("SeriesName_",                     New TypeDescription("String"));
			ValueTree.Columns.Add("PackagingName_",                  New TypeDescription("String"));
			ValueTree.Columns.Add("ProductsMatchedAutomatically", New TypeDescription("Boolean"));
			ValueTree.Columns.Add("IsDuplicate",                              New TypeDescription("Boolean"));
			ValueTree.Columns.Add("RowMapped",                    New TypeDescription("Boolean"));
			ValueTree.Columns.Add("ProductsQuantityForSelection",       New TypeDescription("Number"));
			ValueTree.Columns.Add("TheCodeIsDifferent",                         New TypeDescription("Boolean"));
			ValueTree.Columns.Add("ProductIDIsDifferent",                     New TypeDescription("Boolean"));
			ValueTree.Columns.Add("ProductNameIsDifferent",    New TypeDescription("Boolean"));
			ValueTree.Columns.Add("PriceNotRecognized",                      New TypeDescription("Boolean"));
			ValueTree.Columns.Add("TheCostOfTheChanged",                          New TypeDescription("Boolean"));
			
			ValueTree.Columns.Add("Series",                                 New TypeDescription("CatalogRef.ItemsBatches"));
			ValueTree.Columns.Add("Package",                              New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		EndIf;
		
	Else
		ValueTree.Columns.Add("ProductKind",            New TypeDescription("CatalogRef.ItemKinds"));
		ValueTree.Columns.Add("PricingVariant",           New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		ValueTree.Columns.Add("PricingBatch",                    New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		ValueTree.Columns.Add("PricingPackage",                 New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		ValueTree.Columns.Add("SeriesAreUsed",          New TypeDescription("Boolean"));
		ValueTree.Columns.Add("PackagesAreUsed",       New TypeDescription("Boolean"));
		
		ValueTree.Columns.Add("PriceGroup",              New TypeDescription("CatalogRef.PriceGroups"));
		ValueTree.Columns.Add("SortingAttribute",         New TypeDescription("Number"));
	EndIf;
	
	For Each PriceKind In Form.SelectedPrices Do
		
		If PriceKind.Selected_5 Or PriceKind.Influences Then
			
			ColumnName = PriceKind.ColumnName;
			
			If ThisIsVendorPriceRegistration Then
				ValueTree.Columns.Add(                          ColumnName, TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative), PriceKind.Description);
				ValueTree.Columns.Add("OldPrice"              + ColumnName, TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative), PriceKind.Description);
				ValueTree.Columns.Add("ChangePercentage"        + ColumnName, New TypeDescription("Number", New NumberQualifiers(05, 2, AllowedSign.Any)),            PriceKind.Description);
				ValueTree.Columns.Add("AmountOfChange"          + ColumnName, New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Any)),            PriceKind.Description);
				ValueTree.Columns.Add("ChangedManually"         + ColumnName, New TypeDescription("Boolean"),                                                                  PriceKind.Description);
				ValueTree.Columns.Add("ChangedAutomatically"   + ColumnName, New TypeDescription("Boolean"),                                                                  PriceKind.Description);
				ValueTree.Columns.Add("NoEditingAllowed"    + ColumnName, New TypeDescription("Boolean"),                                                                  PriceKind.Description);
				ValueTree.Columns.Add("ImageChangedManually" + ColumnName, New TypeDescription("Number"),                                                                   PriceKind.Description);
				ValueTree.Columns.Add("MinimumDeliveryLot"+ ColumnName, New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)), PriceKind.Description);
				ValueTree.Columns.Add("SettingConditions"        + ColumnName, New TypeDescription("Boolean"), NStr("vi = 'Đặt điều kiện';
																													|ru = 'Установка условий';
																													|en = 'Setting conditions'; fa = 'تنظیم شرایط';
																													|it = 'Impostazione delle condizioni';
																													|pl = 'Ustawienie warunków';
																													|tr = 'Şartların yapılandırılması'"));
				
				If Form.UseItemPackages Then
					ValueTree.Columns.Add("Package" + ColumnName, New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"), "Package");
					ValueTree.Columns.Add("OrderPackage"   + ColumnName, New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"), NStr("vi = 'Đóng gói đơn hàng';
																																			|ru = 'Упаковка заказа';
																																			|en = 'Order packaging unit'; fa = 'واحد بسته‌بندی سفارش';
																																			|it = 'Imballaggio di ordine';
																																			|pl = 'Opakowanie zamówienia';
																																			|tr = 'Sipariş paketleme ünitesi'"));
					If Form.FormCode = "ImportVendorPricesFromFile" Then
						ValueTree.Columns.Add("PackageIsFilledIn" + ColumnName, New TypeDescription("Boolean"), NStr("vi = 'Đã điền đóng gói';
																													|ru = 'Упаковка заполнена';
																													|en = 'Packaging unit is filled in'; fa = 'Packaging unit is filled in';
																													|it = 'Imballaggio compilato';
																													|pl = 'Opakowanie jest wypełnione';
																													|tr = 'Paketleme ünitesi dolduruldu'"));
						ValueTree.Columns.Add("PackagingName" + ColumnName, New TypeDescription("String"), NStr("vi = 'Bộ đóng gói tên gọi';
																												|ru = 'Упаковка наименование';
																												|en = 'Packaging unit description'; fa = 'Packaging unit description';
																												|it = 'Imballaggio denominazione';
																												|pl = 'Opakowanie nazwa';
																												|tr = 'Paketleme ünitesi tanımı'"));
					EndIf;
				EndIf;
			Else
				ValueTree.Columns.Add(                          ColumnName, TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative), PriceKind.Description);
				ValueTree.Columns.Add("Currency"                  + ColumnName, New TypeDescription("CatalogRef.Currencies"), PriceKind.Description);
				ValueTree.Columns.Add("OldPrice"              + ColumnName, TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Nonnegative), PriceKind.Description);
				ValueTree.Columns.Add("Formula"                 + ColumnName, New TypeDescription("String"), PriceKind.Description);
				ValueTree.Columns.Add("ChangePercentage"        + ColumnName, New TypeDescription("Number", New NumberQualifiers(05, 2, AllowedSign.Any)), PriceKind.Description);
				ValueTree.Columns.Add("AmountOfChange"          + ColumnName, New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Any)), PriceKind.Description);
				ValueTree.Columns.Add("ChangedManually"         + ColumnName, New TypeDescription("Boolean"), PriceKind.Description);
				ValueTree.Columns.Add("FormulaChangedManually"  + ColumnName, New TypeDescription("Boolean"), PriceKind.Description);
				ValueTree.Columns.Add("ChangedAutomatically"   + ColumnName, New TypeDescription("Boolean"), PriceKind.Description);
				ValueTree.Columns.Add("ImageChangedManually" + ColumnName, New TypeDescription("Number"),  PriceKind.Description);
				ValueTree.Columns.Add("NoEditingAllowed"    + ColumnName, New TypeDescription("Boolean"), PriceKind.Description);
				
				If UsePriceManagementSystem25 Then
					ValueTree.Columns.Add("OptionForSpecifyingVATRates"			+ ColumnName, New TypeDescription("EnumRef.OptionsForSpecifyingVATRatesInPriceList"), PriceKind.Description);
					ValueTree.Columns.Add("Country"							+ ColumnName, New TypeDescription("CatalogRef.WorldCountries"), PriceKind.Description);
					ValueTree.Columns.Add("VATRate"							+ ColumnName, New TypeDescription("CatalogRef.VATRates"), NStr("ru = 'Ставка НДС';
																																				|vi = 'VAT rate';
																																				|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
																																				|it = 'Aliquota IVA';
																																				|pl = 'Stawka VAT';
																																				|tr = 'KDV oranı'"));
					ValueTree.Columns.Add("InitialVATRate"					+ ColumnName, New TypeDescription("CatalogRef.VATRates"), PriceKind.Description);
					ValueTree.Columns.Add("ManuallyChangedVATRate"			+ ColumnName, New TypeDescription("Boolean"), PriceKind.Description);
					ValueTree.Columns.Add("VATRateChangedAutomatically"	+ ColumnName, New TypeDescription("Boolean"), PriceKind.Description);
					ValueTree.Columns.Add("ImageWasChangedManuallyVATRate"	+ ColumnName, New TypeDescription("Number"),  PriceKind.Description);
				EndIf;
				
				If Form.UseItemPackages Then
					ValueTree.Columns.Add("Package" + ColumnName, New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"), "Package");
				EndIf;
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ColumnIndentation = ValueTree.Columns.Add("Indent", New TypeDescription("String"), NStr("vi = 'Cách lề';
																							|ru = 'Отступ';
																							|en = 'Indent'; fa = 'تورفتگی';
																							|it = 'Rientro';
																							|pl = 'Odstęp';
																							|tr = 'Girinti'"));
	
	If TypeOf(Form.PriceTree) = Type("FormDataTree") Or TypeOf(Form.PriceTree) = Type("FormDataCollection") Then
			
		DetailsOfPriceTable = Form.GetAttributes("PriceTree");
		For Each Attribute In DetailsOfPriceTable Do
			If StrFind(Attribute.Name, "PriceKind")
				Or StrFind(Attribute.Name, "Indent") Then
				DeletedPriceTableColumns.Add("PriceTree." + Attribute.Name);
			EndIf;
		EndDo;
		
		For Each Column In ValueTree.Columns Do
			If StrFind(Column.Name, "PriceKind") Then
				ColumnToDelete_ = DeletedPriceTableColumns.Find("PriceTree." + Column.Name);
				If ColumnToDelete_ <> Undefined Then
					DeletedPriceTableColumns.Delete(ColumnToDelete_);
				Else
					PriceTableColumnsToAdd.Add(New FormAttribute(Column.Name, Column.ValueType, "PriceTree", Column.Title, True));
				EndIf;
			EndIf;
		EndDo;
	
		PriceTableColumnsToAdd.Add(New FormAttribute(ColumnIndentation.Name, ColumnIndentation.ValueType, "PriceTree", ColumnIndentation.Title, True));
		
		If DeletedPriceTableColumns.Count() > 0 Or PriceTableColumnsToAdd.Count() > 0 Then
			Form.ChangeAttributes(PriceTableColumnsToAdd, DeletedPriceTableColumns);
		EndIf;
		
		SubordinateTableElements = Form.Items["PriceTree"].ChildItems; // FormItems
		For Each CurItem In SubordinateTableElements Do
			If StrFind(CurItem.Name, "PriceKind")
				Or StrFind(CurItem.Name, "Indent") Then
				ItemsToRemove.Add(CurItem);
			EndIf;
		EndDo;
		
		For Each ItemToRemove In ItemsToRemove Do
			Form.Items.Delete(ItemToRemove);
		EndDo;
		
		For Each Appearance In Form.ConditionalAppearance.Items Do
			If Appearance.Presentation = "CreatedProgrammatically" Then
				ConditionalAppearances.Add(Appearance);
			EndIf;
		EndDo;
		
		For Each Appearance In ConditionalAppearances Do
			Form.ConditionalAppearance.Items.Delete(Appearance);
		EndDo;
		
		For Each PriceKind In Form.SelectedPrices Do
			
			ColumnName = PriceKind.ColumnName;
			
			ShowInfluencingPrice = Form.ShowInfluencingPrices 
										And PriceKind.Influences
										And Not PriceKind.ProhibitedPriceType;
			
			If PriceKind.Selected_5
				Or ShowInfluencingPrice Then
				
				HeaderColor = Undefined;
				BackColor      = Undefined;
				HeaderPicture = Undefined;
				
				If PriceKind.PricingMethod = Enums.PriceSettingMethods.Manually 
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice Then
					
					HeaderPicture = PictureLib.MethodsOfPricesCalculationManually;
					
				ElsIf PriceKind.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
					
					HeaderPicture = PictureLib.MethodsOfPricesCalculationFillByInfobaseData;
					
				ElsIf PriceKind.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes
					Or PriceKind.PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup Then

					HeaderPicture = PictureLib.MethodsOfPricesCalculationByFormulasWithReferenceToOtherPriceTypes;
					
				EndIf;
				
				If ThisIsVendorPriceRegistration Then
		
					NewFolder = AddFormGroup(Form, "GroupPrices" + ColumnName, String(PriceKind.Ref) + ", " + String(PriceKind.Currency), True, HeaderPicture, ColumnsGroup.Horizontal, Undefined);
					
				Else
					
					NewFolder = AddFormGroup(Form, "GroupPrices" + ColumnName, ?(String(PriceKind.Id)=String(PriceKind.Ref), String(PriceKind.Ref), String(PriceKind.Ref) + " ["+ String(PriceKind.Id) +"]") + ", " + String(PriceKind.Currency), True, HeaderPicture, ColumnsGroup.Horizontal, Undefined);
					
				EndIf;
				
				If SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode)
					Or SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode) Then
					
					If ValueIsFilled(Form.ValidPriceDate) Then
						ValidPriceDate = EndOfDay(Form.ValidPriceDate);
					Else
						ValidPriceDate = BegOfDay(Form.Date)-1;
					EndIf;
					ColumnTitleOldPrice = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đơn giá %1';
																										|ru = 'Цена на %1';
																										|en = 'Price as of %1'; fa = 'Price as of %1';
																										|it = 'Prezzo di %1';
																										|pl = 'Cena na %1';
																										|tr = '%1 fiyatı'"), Format(ValidPriceDate, "DLF=D"));
					
				Else
					
					ColumnTitleOldPrice = ?(PriceKind.Selected_5, NStr("vi = 'Đơn giá hiện hành';
																		|ru = 'Действующая цена';
																		|en = 'Effective price'; fa = 'Effective price';
																		|it = 'Prezzo attuale';
																		|pl = 'Aktualna cena';
																		|tr = 'Geçerli fiyat'"), NStr("vi = 'Đơn giá';
																										|ru = 'Цена';
																										|en = 'Price'; fa = 'قیمت';
																										|it = 'Prezzo';
																										|pl = 'Cena';
																										|tr = 'Fiyat'"));
					
				EndIf;
				
				If PriceKind.Selected_5 Then
					NewTechnicalGroup = AddFormGroup(Form, "TechnicalGroup" + ColumnName, NStr("vi = 'Nhóm';
																								|ru = 'Группа';
																								|en = 'Group'; fa = 'گروه';
																								|it = 'Gruppo';
																								|pl = 'Grupa';
																								|tr = 'Grup'"), False, Undefined, ColumnsGroup.Horizontal, NewFolder);
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              ColumnTitleOldPrice);
					ParametersStructure.Insert("MarginWidth",             12);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewTechnicalGroup);
					ParametersStructure.Insert("FieldViewOnly",     True);
					
					NewField = AddFormField(Form, "OldPrice" + ColumnName, ParametersStructure);
					NewField.ToolTip = NStr("vi = 'Đơn giá đã thiết lập hiện tại';
											|ru = 'Текущая установленная цена';
											|en = 'Current set price'; fa = 'Current set price';
											|it = 'Prezzo attuale impostato';
											|pl = 'Bieżąca ustawiona cena';
											|tr = 'Mevcut ayarlanmış fiyat'");
					NewField.TextColor = WebColors.Gray;
					
					If Not ThisIsVendorPriceRegistration Then
						NewFormulaGroup = AddFormGroup(Form, "TechnicalFormulaGroup" + ColumnName, NStr("vi = 'Nhóm công thức';
																										|ru = 'Группа формула';
																										|en = 'Formula group'; fa = 'گروه فرمول';
																										|it = 'Gruppo formula';
																										|pl = 'Grupa formuła';
																										|tr = 'Grup formül'"), False, Undefined, ColumnsGroup.InCell, NewTechnicalGroup);
						
						NewField                     = Form.Items.Add("PriceTree" + "Formula" + "Picture" + ColumnName, Type("FormField"), NewFormulaGroup);
						NewField.DataPath         = "PriceTree.FormulaChangedManually" + ColumnName;
						NewField.Title           = "";
						NewField.TitleLocation  = FormItemTitleLocation.None;
						NewField.EditMode = ColumnEditMode.EnterOnInput;
						NewField.Type                 = FormFieldType.PictureField;
						NewField.ReadOnly      = True;
						NewField.Width              = 2;
						NewField.ShowInHeader    = False;
						NewField.ValuesPicture    = PictureLib.Attention16;
						NewField.Visible           = PriceKind.FormulaIsBeingEdited;
						NewField.HorizontalStretch = False;
						
						NewField.ToolTip = NStr("vi = 'Công thức đã thay đổi';
												|ru = 'Формула изменена';
												|en = 'The formula is changed'; fa = 'The formula is changed';
												|it = 'Формула изменена';
												|pl = 'The formula is changed';
												|tr = 'Formül değiştirildi'");

						ParametersStructure = New Structure();
						ParametersStructure.Insert("Title",              NStr("vi = 'Công thức';
																				|ru = 'Формула';
																				|en = 'Formula'; fa = 'فرمول';
																				|it = 'Formula';
																				|pl = 'Formula';
																				|tr = 'Formül'"));
						ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreeFormulaWhenChanging");
						ParametersStructure.Insert("HandlerStartChoice", "Attachable_PriceTreeFormulaBeginningOfChoice");
						ParametersStructure.Insert("MarginWidth",             12);
						ParametersStructure.Insert("BackColor",               BackColor);
						ParametersStructure.Insert("TitleBackColor",      HeaderColor);
						ParametersStructure.Insert("Parent",               NewFormulaGroup);
						ParametersStructure.Insert("Visible",              PriceKind.FormulaIsBeingEdited);
						ParametersStructure.Insert("FieldViewOnly",     Not PriceKind.Edit);
						ParametersStructure.Insert("HorizontalAlign", ItemHorizontalLocation.Right);
						ParametersStructure.Insert("TextEdit", False);
						
						NewField = AddFormField(Form, "Formula" + ColumnName, ParametersStructure);
						NewField.ToolTip = NStr("vi = 'Công thức để tính đơn giá';
												|ru = 'Формула для расчета цены';
												|en = 'Formula for price calculation'; fa = 'Formula for price calculation';
												|it = 'Formula per il calcolo del prezzo';
												|pl = 'Formuła do obliczenia ceny';
												|tr = 'Fiyat hesaplama formülü'");
						NewField.TextColor = WebColors.Gray;
						NewField.TextEdit = False;
						NewField.ClearButton = True;
						
					EndIf;
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Thay đổi';
																			|ru = 'Изменение';
																			|en = 'Update'; fa = 'به‌روزرسانی';
																			|it = 'Modifica';
																			|pl = 'Update';
																			|tr = 'Değişim'"));
					ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreePriceWhenChanged");
					ParametersStructure.Insert("MarginWidth",             12);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewTechnicalGroup);
					ParametersStructure.Insert("FieldViewOnly",     ?(ThisIsVendorPriceRegistration, False, Not PriceKind.Edit));
					
					NewField = AddFormField(Form, "AmountOfChange" + ColumnName, ParametersStructure);
					
					NewField.TextColor = WebColors.Gray;
					NewField.MarkNegatives = True;
					NewField.ToolTip = NStr("vi = 'Thay đổi đơn giá';
											|ru = 'Изменение цены';
											|en = 'Price change'; fa = 'تغییر قیمت';
											|it = 'Modifica prezzo';
											|pl = 'Zmiana ceny';
											|tr = 'Fiyat değişikliği'");
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              "%");
					ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreePriceWhenChanged");
					ParametersStructure.Insert("MarginWidth",             6);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewTechnicalGroup);
					ParametersStructure.Insert("FieldViewOnly",     ?(ThisIsVendorPriceRegistration, False, Not PriceKind.Edit));
					
					NewField = AddFormField(Form, "ChangePercentage" + ColumnName, ParametersStructure);
					NewField.TextColor = WebColors.Gray;
					NewField.MarkNegatives = True;
					NewField.ToolTip = NStr("vi = 'Phần trăm thay đổi đơn giá';
											|ru = 'Процент изменения цены';
											|en = 'Price change percentage'; fa = 'درصد تغییر قیمت';
											|it = 'Percentuale di modifica del prezzo';
											|pl = 'Procent zmiany ceny';
											|tr = 'Fiyat değişikliği yüzdesi'");
					
					NewPriceGroup = AddFormGroup(Form, "GroupPrice" + ColumnName, NStr("vi = 'Nhóm giá';
																						|ru = 'Группа цена';
																						|en = 'Group price'; fa = 'Group price';
																						|it = 'Gruppo prezzo';
																						|pl = 'Grupa cena';
																						|tr = 'Grup fiyat'"), False, Undefined, ColumnsGroup.InCell, NewFolder);
					
					NewField                     = Form.Items.Add("NoEditingAllowed" + ColumnName, Type("FormField"), NewPriceGroup);
					NewField.DataPath         = "PriceTree.NoEditingAllowed" + ColumnName;
					NewField.Title           = "Prohibition editing";
					NewField.TitleLocation  = FormItemTitleLocation.None;
					NewField.EditMode = ColumnEditMode.EnterOnInput;
					NewField.Type                 = FormFieldType.PictureField;
					NewField.ReadOnly      = True;
					NewField.Width              = 2;
					NewField.ShowInHeader    = False;
					NewField.ValuesPicture    = PictureLib.PriceTypesViewOnly;
					NewField.HeaderPicture       = PictureLib.PriceTypesViewOnly;
					NewField.Visible           = ?(ThisIsVendorPriceRegistration, False, Not PriceKind.Edit);
					NewField.HorizontalStretch = False;
					NewField.ToolTip = NStr("vi = 'Cấm soạn đơn giá';
											|ru = 'Запрет редактирования цены';
											|en = 'Disable price editing'; fa = 'غیرفعال کردن ویرایش قیمت';
											|it = 'Divieto modifica prezzi';
											|pl = 'Zakaz edycji ceny';
											|tr = 'Fiyat düzenleme yasağı'");
					
					NewField                     = Form.Items.Add("PriceTree" + "Picture" + ColumnName, Type("FormField"), NewPriceGroup);
					NewField.DataPath         = "PriceTree.ChangedManually" + ColumnName;
					NewField.Title           = "";
					NewField.TitleLocation  = FormItemTitleLocation.None;
					NewField.EditMode = ColumnEditMode.EnterOnInput;
					NewField.Type                 = FormFieldType.PictureField;
					NewField.ReadOnly      = True;
					NewField.Width              = 2;
					NewField.ShowInHeader    = False;
					NewField.ValuesPicture    = PictureLib.SetPrices;
					NewField.HeaderPicture       = PictureLib.SetPrices;
					NewField.Visible           = ?(ThisIsVendorPriceRegistration, True, PriceKind.Edit);
					NewField.HorizontalStretch = False;
					NewField.ToolTip = NStr("vi = 'Thay đổi đơn giá thủ công';
											|ru = 'Цена изменена вручную';
											|en = 'Price is changed manually'; fa = 'قیمت به‌صورت دستی تغییر کرده است';
											|it = 'Il prezzo è stato modificato manualmente';
											|pl = 'Cena zmieniona ręcznie';
											|tr = 'Fiyat manuel olarak değiştirildi'");

					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Đơn giá';
																			|ru = 'Цена';
																			|en = 'Price'; fa = 'قیمت';
																			|it = 'Prezzo';
																			|pl = 'Price';
																			|tr = 'Fiyat'"));
					ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreePriceWhenChanged");
					ParametersStructure.Insert("MarginWidth",             12);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewPriceGroup);
					ParametersStructure.Insert("FieldViewOnly",     ?(ThisIsVendorPriceRegistration, False, Not PriceKind.Edit));
					NewField = AddFormField(Form, ColumnName, ParametersStructure);
					NewField.ToolTip = NStr("vi = 'Đơn giá được thiết lập';
											|ru = 'Устанавливаемая цена';
											|en = 'Price to set'; fa = 'Price to set';
											|it = 'Prezzo impostabile';
											|pl = 'Ustawiana cena';
											|tr = 'Ayarlanan fiyat'");
					
					If Not ThisIsVendorPriceRegistration Then
						NewCurrencyGroup = AddFormGroup(Form, "CurrencyGroup_2" + ColumnName, NStr("vi = 'Nhóm tiền tệ';
																									|ru = 'Группа валюта';
																									|en = 'Currency group'; fa = 'گروه ارز';
																									|it = 'Gruppo valuta';
																									|pl = 'Grupa waluta';
																									|tr = 'Grup para birimi'"), False, Undefined, ColumnsGroup.Horizontal, NewTechnicalGroup);
	
						ParametersStructure = New Structure();
						ParametersStructure.Insert("Title",              NStr("vi = 'Tiền tệ';
																				|ru = 'Валюта';
																				|en = 'Currency'; fa = 'ارز';
																				|it = 'Valuta';
																				|pl = 'Waluta';
																				|tr = 'Para birimi'"));
						ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreeCurrencyWhenChanged");
						ParametersStructure.Insert("MarginWidth",             6);
						ParametersStructure.Insert("BackColor",               BackColor);
						ParametersStructure.Insert("TitleBackColor",      HeaderColor);
						ParametersStructure.Insert("Parent",               NewCurrencyGroup);
						ParametersStructure.Insert("FieldViewOnly",     ?(ThisIsVendorPriceRegistration, False, Not PriceKind.Edit));
						
						NewField = AddFormField(Form, "Currency" + ColumnName, ParametersStructure);
						NewField.ToolTip = NStr("vi = 'Tiền tệ đơn giá';
												|ru = 'Валюта цены';
												|en = 'Price currency'; fa = 'ارز قیمت';
												|it = 'Valuta del prezzo';
												|pl = 'Waluta ceny';
												|tr = 'Fiyat para birimi'");
						NewField.QuickChoice = False;
					EndIf;
					
				Else
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              ColumnTitleOldPrice);
					ParametersStructure.Insert("MarginWidth",             12);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewFolder);
					ParametersStructure.Insert("FieldViewOnly",     True);
					
					NewField = AddFormField(Form, "OldPrice" + ColumnName, ParametersStructure);
					
					NewField.TextColor = WebColors.Gray;
					
				EndIf;
				
				If Form.UseItemPackages Then
					NewPackingGroup = AddFormGroup(Form, "PackingGroup" + ColumnName, NStr("vi = 'Đơn vị tính';
																							|ru = 'Ед. изм.';
																							|en = 'Unit'; fa = 'واحد';
																							|it = 'Unità di misura';
																							|pl = 'J. m.';
																							|tr = 'Ölçü birimi'"), False, Undefined, ColumnsGroup.InCell, NewFolder);
					
					NewLink = New ChoiceParameterLink("Products", "Items.PriceTree.CurrentData.Products", LinkedValueChangeMode.DontChange);
					NewArray = New Array();
					NewArray.Add(NewLink);
					NewLinks = New FixedArray(NewArray);
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Đóng gói';
																			|ru = 'Упаковка';
																			|en = 'Packaging unit'; fa = 'واحد بسته‌بندی';
																			|it = 'Imballaggio';
																			|pl = 'Opakowanie';
																			|tr = 'Paket'"));
					ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreePackagingWhenChanging");
					ParametersStructure.Insert("HandlerStartChoice", "Attachable_PriceTreePackagingUnitsStartOfSelection");
					ParametersStructure.Insert("MarginWidth",             3);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewPackingGroup);
					ParametersStructure.Insert("ChoiceParameterLinks",  NewLinks);
					ParametersStructure.Insert("ShowInHeader",       False);
					ParametersStructure.Insert("FieldViewOnly",     ?(ThisIsVendorPriceRegistration, False, Not PriceKind.Edit));
					
					AddFormField(Form, "Package" + ColumnName, ParametersStructure);
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Đơn vị tính';
																			|ru = 'Ед. изм.';
																			|en = 'Unit'; fa = 'واحد';
																			|it = 'Unità di misura';
																			|pl = 'J. m.';
																			|tr = 'Ölçü birimi'"));
					ParametersStructure.Insert("MarginWidth",             3);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewPackingGroup);
					ParametersStructure.Insert("DataPath",            "PriceTree.Products.UnitOfMeasure");
					ParametersStructure.Insert("FieldViewOnly",     True);
				
					AddFormField(Form, "UnitOfMeasure" + ColumnName, ParametersStructure);

					If ThisIsVendorPriceRegistration Then
						
						ParametersStructure = New Structure();
						ParametersStructure.Insert("Title",              NStr("vi = 'Đóng gói đơn hàng';
																				|ru = 'Упаковка заказа';
																				|en = 'Order packaging unit'; fa = 'واحد بسته‌بندی سفارش';
																				|it = 'Imballaggio di ordine';
																				|pl = 'Opakowanie zamówienia';
																				|tr = 'Sipariş paketleme ünitesi'"));
						ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreeOrderPackagingWhenChanged");
						ParametersStructure.Insert("MarginWidth",             9);
						ParametersStructure.Insert("BackColor",               BackColor);
						ParametersStructure.Insert("TitleBackColor",      HeaderColor);
						ParametersStructure.Insert("Parent",               NewFolder);
						ParametersStructure.Insert("ChoiceParameterLinks",  NewLinks);
						ParametersStructure.Insert("ShowInHeader",       True);
						
						AddFormField(Form,"OrderPackage" + ColumnName, ParametersStructure);
						
						If Form.FormCode = "ImportVendorPricesFromFile" Then
							ParametersStructure = New Structure();
							ParametersStructure.Insert("Title",              NStr("vi = 'Đã điền đóng gói';
																					|ru = 'Упаковка заполнена';
																					|en = 'Packaging unit is filled in'; fa = 'Packaging unit is filled in';
																					|it = 'Imballaggio compilato';
																					|pl = 'Opakowanie jest wypełnione';
																					|tr = 'Paketleme ünitesi dolduruldu'"));
							ParametersStructure.Insert("MarginWidth",             9);
							ParametersStructure.Insert("BackColor",               BackColor);
							ParametersStructure.Insert("TitleBackColor",      HeaderColor);
							ParametersStructure.Insert("Parent",               NewFolder);
							ParametersStructure.Insert("ChoiceParameterLinks",  NewLinks);
							ParametersStructure.Insert("ShowInHeader",       True);
							ParametersStructure.Insert("Visible",              False);
							
							AddFormField(Form,"PackageIsFilledIn" + ColumnName, ParametersStructure);
							
							ParametersStructure = New Structure();
							ParametersStructure.Insert("Title",              NStr("vi = 'Tên gọi bộ đóng gói';
																					|ru = 'Наименование упак.';
																					|en = 'Packaging description'; fa = 'Packaging description';
																					|it = 'Denominazione imbal.';
																					|pl = 'Nazwa opak.';
																					|tr = 'Paketleme ünitesi tanımı.'"));
							ParametersStructure.Insert("MarginWidth",             9);
							ParametersStructure.Insert("BackColor",               BackColor);
							ParametersStructure.Insert("TitleBackColor",      HeaderColor);
							ParametersStructure.Insert("Parent",               NewFolder);
							ParametersStructure.Insert("ChoiceParameterLinks",  NewLinks);
							ParametersStructure.Insert("ShowInHeader",       True);
							ParametersStructure.Insert("Visible",              True);
							ParametersStructure.Insert("FieldViewOnly",     True);
							
							AddFormField(Form,"PackagingName" + ColumnName, ParametersStructure);
						EndIf;
					EndIf;
					
				Else
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Đơn vị tính';
																			|ru = 'Ед. изм.';
																			|en = 'Unit'; fa = 'واحد';
																			|it = 'Unità di misura';
																			|pl = 'J. m.';
																			|tr = 'Ölçü birimi'"));
					ParametersStructure.Insert("MarginWidth",             3);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewFolder);
					ParametersStructure.Insert("DataPath",            "PriceTree.Products.UnitOfMeasure");
					ParametersStructure.Insert("FieldViewOnly",     True);
					
					AddFormField(Form, "UnitOfMeasure" + ColumnName, ParametersStructure);
				EndIf;
				
				If Not ThisIsVendorPriceRegistration
					And UsePriceManagementSystem25 Then
					
					SpecifyVATRateForAllItems = PriceKind.OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems;
					SpecifiedVATRatesLineByLine = PriceKind.OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine;
					If SpecifyVATRateForAllItems Or SpecifiedVATRatesLineByLine Then
					
						NewVATRateGroup = AddFormGroup(Form, "GroupVATRate" + ColumnName, NStr("ru = 'Ставка НДС';
																								|vi = 'VAT rate';
																								|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
																								|it = 'Aliquota IVA';
																								|pl = 'Stawka VAT';
																								|tr = 'KDV oranı'"), False, Undefined, ColumnsGroup.InCell, NewFolder);
						
						If SpecifiedVATRatesLineByLine Then
							ParametersStructure = New Structure();
							ParametersStructure.Insert("MarginWidth",             2);
							ParametersStructure.Insert("Parent",               NewVATRateGroup);
							ParametersStructure.Insert("DataPath",            "PriceTree.ManuallyChangedVATRate" + ColumnName);
							ParametersStructure.Insert("FieldViewOnly",     True);
							ParametersStructure.Insert("ShowInHeader",       False);
							ParametersStructure.Insert("Kind",                    FormFieldType.PictureField);
							ParametersStructure.Insert("HeaderPicture",          PictureLib.SetPrices);
							ParametersStructure.Insert("ValuesPicture",       PictureLib.SetPrices);
							ParametersStructure.Insert("ToolTip",              NStr("ru = 'Ставка НДС изменена вручную';
																					|vi = 'VAT rate is changed manually';
																					|en = 'VAT rate is changed manually'; fa = 'VAT rate is changed manually';
																					|it = 'VAT rate is changed manually';
																					|pl = 'VAT rate is changed manually';
																					|tr = 'KDV oranı manuel olarak değiştirildi'"));
							ParametersStructure.Insert("Visible",              PriceKind.Edit);
							
							NewField = AddFormField(Form, "VATRateImage" + ColumnName, ParametersStructure);
							NewField.Title = "";
							NewField.TitleLocation  = FormItemTitleLocation.None;
						EndIf;
						
						NewLinks = Undefined;
						NewArray = New Array();
						NewArray.Add(New ChoiceParameterLink("Country", "Items.PriceTree.CurrentData.Country" + ColumnName, LinkedValueChangeMode.DontChange));
						
						If ThisIsPriceList(Form) Then
							
							NewArray.Add(New ChoiceParameterLink("BeginOfPeriod", "Date", LinkedValueChangeMode.DontChange));
							If ValueIsFilled(Form.EndDateOfThePricePeriod) Then
								NewArray.Add(New ChoiceParameterLink("EndOfPeriod", "EndDateOfThePricePeriod", LinkedValueChangeMode.DontChange));
							EndIf;
							
						ElsIf ThisIsSettingProductPrices(Form) Then
							
							NewArray.Add(New ChoiceParameterLink("BeginOfPeriod", "Object.Date", LinkedValueChangeMode.DontChange));
							
						EndIf;
						
						NewLinks = New FixedArray(NewArray);
						
						ParametersStructure = New Structure();
						ParametersStructure.Insert("Title",              NStr("ru = 'Ставка НДС';
																				|vi = 'VAT rate';
																				|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
																				|it = 'Aliquota IVA';
																				|pl = 'Stawka VAT';
																				|tr = 'KDV oranı'"));
						ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreeVATRateONChange");
						ParametersStructure.Insert("MarginWidth",             8);
						ParametersStructure.Insert("BackColor",               BackColor);
						ParametersStructure.Insert("TitleBackColor",      HeaderColor);
						ParametersStructure.Insert("Parent",               NewVATRateGroup);
						ParametersStructure.Insert("ChoiceParameterLinks",  NewLinks);
						ParametersStructure.Insert("DataPath",            "PriceTree.VATRate" + ColumnName);
						ParametersStructure.Insert("HorizontalAlign", ItemHorizontalLocation.Right);
						ParametersStructure.Insert("FieldViewOnly",     Not PriceKind.Edit Or Not SpecifiedVATRatesLineByLine);
					
						NewField = AddFormField(Form, "VATRate" + ColumnName, ParametersStructure);
					EndIf;
				EndIf;
				
				If ThisIsVendorPriceRegistration Then
					
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Lô hàng giao tối thiểu';
																			|ru = 'Мин. партия поставки';
																			|en = 'Min. delivery lot'; fa = 'Min. delivery lot';
																			|it = 'Lotto minimo di consegna';
																			|pl = 'Min. partia dostawy';
																			|tr = 'Min. tedarik lotu'"));
					ParametersStructure.Insert("HandlerOnChange", "Attachable_PriceTreeMinimumBatchWhenModified");
					ParametersStructure.Insert("MarginWidth",             8);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewFolder);
					ParametersStructure.Insert("ShowInHeader",       True);
				
					NewField = AddFormField(Form, "MinimumDeliveryLot" + ColumnName, ParametersStructure);
				
					ParametersStructure = New Structure();
					ParametersStructure.Insert("Title",              NStr("vi = 'Điều kiện';
																			|ru = 'Условия';
																			|en = 'Conditions'; fa = 'شرایط';
																			|it = 'Condizioni';
																			|pl = 'Conditions';
																			|tr = 'Şartlar'"));
					ParametersStructure.Insert("MarginWidth",             8);
					ParametersStructure.Insert("BackColor",               BackColor);
					ParametersStructure.Insert("TitleBackColor",      HeaderColor);
					ParametersStructure.Insert("Parent",               NewFolder);
					ParametersStructure.Insert("ShowInHeader",       True);
					ParametersStructure.Insert("Kind",                    FormFieldType.PictureField);
					ParametersStructure.Insert("FieldViewOnly",     False);
					ParametersStructure.Insert("ValuesPicture",       PictureLib.Change);
					ParametersStructure.Insert("HeaderPicture",          PictureLib.Change);
					ParametersStructure.Insert("Visible",              False);
					
					AddFormField(Form,"SettingConditions" + ColumnName, ParametersStructure);
				EndIf;
				
				If Not ThisIsVendorPriceRegistration Then
					If PriceKind.FormulaIsBeingEdited Then
							
						// Conditional formula changes
						NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
						NewElementOfConditionalAppearance.UserSettingID = "Formula"+ ColumnName;
						NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
						NewElementOfConditionalAppearance.Use = True;
						
						FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
						FilterElement.Use = True;
						FilterElement.LeftValue = New DataCompositionField("PriceTree.FormulaChangedManually"+ ColumnName);
						FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
						FilterElement.RightValue = True;
						
						NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
						NewField.Use = True;
						NewField.Field = New DataCompositionField("PriceTree" + "Formula"+ ColumnName);
						
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
			
						// Conditional formula changes
						NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
						NewElementOfConditionalAppearance.UserSettingID = "Formula"+ ColumnName;
						NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
						NewElementOfConditionalAppearance.Use = True;
						
						FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
						FilterElement.Use = True;
						FilterElement.LeftValue = New DataCompositionField("PriceTree.FormulaChangedManually"+ ColumnName);
						FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
						FilterElement.RightValue = False;
						
						NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
						NewField.Use = True;
						NewField.Field = New DataCompositionField("PriceTree" + "Formula"+ ColumnName);
						
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.Gray);
						
					Else
						// Conditional formula changes
						NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
						NewElementOfConditionalAppearance.UserSettingID = "Formula"+ ColumnName;
						NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
						NewElementOfConditionalAppearance.Use = True;
						
						NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
						NewField.Use = True;
						NewField.Field = New DataCompositionField("PriceTree" + "Formula"+ ColumnName);
						
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng công thức>';
																									|ru = '<формулы не используются>';
																									|en = '<formulas are not used>'; fa = '<formulas are not used>';
																									|it = '<Le formule non sono utilizzate>';
																									|pl = '<formuły nie są używane>';
																									|tr = '<formüller kullanılmamaktadır>'"));
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("ReadOnly", True);
						
					EndIf;
				EndIf;

				// Conditional registration of increased prices
				NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				NewElementOfConditionalAppearance.UserSettingID = ColumnName;
				NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
				NewElementOfConditionalAppearance.Use = True;
				
				FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.Use = True;
				FilterElement.LeftValue = New DataCompositionField("PriceTree." + ColumnName);
				FilterElement.ComparisonType = DataCompositionComparisonType.Greater;
				FilterElement.RightValue = New DataCompositionField("PriceTree.OldPrice" + ColumnName);
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + ColumnName);
				
				NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
				
				// Conditional registration of reduced prices
				NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				NewElementOfConditionalAppearance.UserSettingID = ColumnName;
				NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
				NewElementOfConditionalAppearance.Use = True;
				
				FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.Use = True;
				FilterElement.LeftValue = New DataCompositionField("PriceTree." + ColumnName);
				FilterElement.ComparisonType = DataCompositionComparisonType.Less;
				FilterElement.RightValue = New DataCompositionField("PriceTree.OldPrice" + ColumnName);
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + ColumnName);
				
				NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.DarkGreen);
				
				// Conditional design of units of measurement
				ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
				ConditionalDesignParameters.NameOfUnitField = "PriceTree" + "UnitOfMeasure" + ColumnName;
				ConditionalDesignParameters.PathToPackagingUnitField = "PriceTree.Package" + ColumnName;
				ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
				
				If Not ThisIsVendorPriceRegistration And UsePriceManagementSystem25 Then
					
					NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					NewElementOfConditionalAppearance.UserSettingID = ColumnName;
					NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
					NewElementOfConditionalAppearance.Use = True;
					
					FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.Use = True;
					FilterElement.LeftValue = New DataCompositionField("PriceTree.PackagesAreUsed");
					FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
					FilterElement.RightValue = True;
					
					NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
					NewField.Use = True;
					NewField.Field = New DataCompositionField("PriceTree" + "Package" + ColumnName);
					
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("ReadOnly", True);
					
					NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					NewElementOfConditionalAppearance.UserSettingID = ColumnName;
					NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
					NewElementOfConditionalAppearance.Use = True;
					
					CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.VATRate" + ColumnName,
							DataCompositionComparisonType.NotEqual, New DataCompositionField("PriceTree.InitialVATRate" + ColumnName));
					
					NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
					NewField.Use = True;
					NewField.Field = New DataCompositionField("PriceTree" + "VATRate" + ColumnName);
					
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.DarkGreen);
					
					// Conditional appearance of an unfilled VAT rate
					If ThisIsSettingProductPrices(Form) Then
						
						NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
						NewElementOfConditionalAppearance.UserSettingID = ColumnName;
						NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
						NewElementOfConditionalAppearance.Use = True;
						
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.VATRate" + ColumnName,
							DataCompositionComparisonType.NotFilled);
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.PictureIndex",
							DataCompositionComparisonType.Equal, 0);
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.ItemVariantsAreUsed",
							DataCompositionComparisonType.Equal, False);
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.SeriesAreUsed",
							DataCompositionComparisonType.Equal, False);
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.PackagesAreUsed",
							DataCompositionComparisonType.Equal, False);
						
						NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
						NewField.Use = True;
						NewField.Field = New DataCompositionField("PriceTree" + "VATRate" + ColumnName);
					
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("MarkIncomplete", True);
						
						// Used - Characteristics, Series, Packages
						NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
						NewElementOfConditionalAppearance.UserSettingID = ColumnName;
						NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
						NewElementOfConditionalAppearance.Use = True;
						
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.VATRate" + ColumnName,
							DataCompositionComparisonType.NotFilled);
						CommonClientServer.AddCompositionItem(NewElementOfConditionalAppearance.Filter, "PriceTree.PictureIndex",
							DataCompositionComparisonType.Equal, 2);
						
						FilterGroup = CommonClientServer.CreateFilterItemGroup(NewElementOfConditionalAppearance.Filter, "GroupWasCreatedProgrammatically",
							DataCompositionFilterItemsGroupType.OrGroup);
						CommonClientServer.AddCompositionItem(FilterGroup, "PriceTree.ItemVariantsAreUsed",
							DataCompositionComparisonType.Equal, True);
						CommonClientServer.AddCompositionItem(FilterGroup, "PriceTree.SeriesAreUsed",
							DataCompositionComparisonType.Equal, True);
						CommonClientServer.AddCompositionItem(FilterGroup, "PriceTree.PackagesAreUsed",
							DataCompositionComparisonType.Equal, True);
							
						SelectionGroupDoesNot = CommonClientServer.CreateFilterItemGroup(NewElementOfConditionalAppearance.Filter, "GroupWasNotCreatedProgrammatically",
							DataCompositionFilterItemsGroupType.NotGroup);
						CommonClientServer.AddCompositionItem(SelectionGroupDoesNot, "PriceTree.ItemVariantsAreUsed",
							DataCompositionComparisonType.Equal, True);
						CommonClientServer.AddCompositionItem(SelectionGroupDoesNot, "PriceTree.SeriesAreUsed",
							DataCompositionComparisonType.Equal, True);
						CommonClientServer.AddCompositionItem(SelectionGroupDoesNot, "PriceTree.PackagesAreUsed",
							DataCompositionComparisonType.Equal, True);
						SelectionGroupOr = CommonClientServer.CreateFilterItemGroup(SelectionGroupDoesNot, "GroupOrCreatedProgrammatically",
							DataCompositionFilterItemsGroupType.OrGroup);
						CommonClientServer.AddCompositionItem(SelectionGroupOr, "PriceTree.PricingVariant",
							DataCompositionComparisonType.NotFilled);
						CommonClientServer.AddCompositionItem(SelectionGroupOr, "PriceTree.PricingBatch",
							DataCompositionComparisonType.NotFilled);
						
						NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
						NewField.Use = True;
						NewField.Field = New DataCompositionField("PriceTree" + "VATRate" + ColumnName);
					
						NewElementOfConditionalAppearance.Appearance.SetParameterValue("MarkIncomplete", True);
					EndIf;
				EndIf;
				
				// Conditional execution of the editing ban
				NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				NewElementOfConditionalAppearance.UserSettingID = ColumnName;
				NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
				NewElementOfConditionalAppearance.Use = True;
				
				FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.Use = True;
				FilterElement.LeftValue = New DataCompositionField("PriceTree.NoEditingAllowed" + ColumnName);
				FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
				FilterElement.RightValue = True;
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + ColumnName);
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + "Formula" + ColumnName);
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + "AmountOfChange" + ColumnName);
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + "ChangePercentage" + ColumnName);
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree" + "Currency" + ColumnName);

				If Not ThisIsVendorPriceRegistration Then
					NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
					NewField.Use = True;
					NewField.Field = New DataCompositionField("PriceTree" + "Package" + ColumnName);
					
					If UsePriceManagementSystem25 Then
						NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
						NewField.Use = True;
						NewField.Field = New DataCompositionField("PriceTree" + "VATRate" + ColumnName);
					EndIf;
				EndIf;
				
				NewElementOfConditionalAppearance.Appearance.SetParameterValue("ReadOnly", True);
				NewElementOfConditionalAppearance.Appearance.SetParameterValue("Text", NStr("vi = '<Cấm chỉnh sửa>';
																							|ru = '<Запрет редактирования>';
																							|en = '<Editing restriction>'; fa = '<Editing restriction>';
																							|it = '<Divieto di modifica>';
																							|pl = '<Zakaz edycji>';
																							|tr = '<Düzenleme yasağı>'"));

				If ThisIsVendorPriceRegistration Then
					
					// In the registration of supplier prices - the empty price is not registered during the
					NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					NewElementOfConditionalAppearance.UserSettingID = ColumnName;
					NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
					NewElementOfConditionalAppearance.Use = True;
					
					FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.Use = True;
					FilterElement.LeftValue = New DataCompositionField("PriceTree." + ColumnName);
					FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
					FilterElement.RightValue = 0;
					
					FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.Use = True;
					FilterElement.LeftValue = New DataCompositionField("PriceTree.ItemVariantsAreUsed");
					FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
					FilterElement.RightValue = False;
					
					NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
					NewField.Use = True;
					NewField.Field = New DataCompositionField("PriceTree" + ColumnName);
					
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("Text", NStr("vi = '<Không thay đổi>';
																								|ru = '<Не изменяется>';
																								|en = '<Does not change>'; fa = '<Does not change>';
																								|it = '<Non modificare>';
																								|pl = '<Nie zmienia się>';
																								|tr = '<Değiştirilemiyor>'"));
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.Gray);
					
					//
					
					NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					NewElementOfConditionalAppearance.UserSettingID = ColumnName;
					NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
					NewElementOfConditionalAppearance.Use = True;
					
					FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.Use = True;
					FilterElement.LeftValue = New DataCompositionField("PriceTree." + ColumnName);
					FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
					FilterElement.RightValue = 0;
					
					FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.Use = True;
					FilterElement.LeftValue = New DataCompositionField("PriceTree.Characteristic");
					FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
					
					NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
					NewField.Use = True;
					NewField.Field = New DataCompositionField("PriceTree" + ColumnName);
					
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("Text", NStr("vi = '<Không thay đổi>';
																								|ru = '<Не изменяется>';
																								|en = '<Does not change>'; fa = '<Does not change>';
																								|it = '<Non modificare>';
																								|pl = '<Nie zmienia się>';
																								|tr = '<Değiştirilemiyor>'"));
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.Gray);
					
					// In the registration of supplier prices - the empty price is not registered during the
					NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
					NewElementOfConditionalAppearance.UserSettingID = ColumnName;
					NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
					NewElementOfConditionalAppearance.Use = True;
					
					FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.Use = True;
					FilterElement.LeftValue = New DataCompositionField("PriceTree." + ColumnName);
					FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
					FilterElement.RightValue = 0;
					
					NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
					NewField.Use = True;
					NewField.Field = New DataCompositionField("PriceTree" + "ChangePercentage" + ColumnName);
					
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("Text", "");
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("ReadOnly", True);
					NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", WebColors.Gray);
					
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(GroupingOption) Then
			
				ListOfElementImageIndexes = New ValueList;
				ListOfElementImageIndexes.Add(0);
				ListOfElementImageIndexes.Add(2);
				//
				
				NewElementOfConditionalAppearance = Form.ConditionalAppearance.Items.Add();
				NewElementOfConditionalAppearance.UserSettingID = "LinesOnlyView";
				NewElementOfConditionalAppearance.Presentation = "CreatedProgrammatically";
				NewElementOfConditionalAppearance.Use = True;
				
				FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.Use = True;
				FilterElement.LeftValue = New DataCompositionField("PriceTree.PictureIndex");
				FilterElement.ComparisonType = DataCompositionComparisonType.NotInList;
				FilterElement.RightValue = ListOfElementImageIndexes;
				
				NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
				NewField.Use = True;
				NewField.Field = New DataCompositionField("PriceTree");
				
				NewElementOfConditionalAppearance.Appearance.SetParameterValue("ReadOnly", True);
			
			EndIf; 
		EndDo;
		
		ParametersStructure = New Structure();
		ParametersStructure.Insert("MarginWidth",             30);
		ParametersStructure.Insert("FieldViewOnly",     True);
		
		NewField = AddFormField(Form, "Indent", ParametersStructure);
		NewField.TextColor = WebColors.Gray;
		NewField.Visible  = True;
		NewField.TitleLocation = FormItemTitleLocation.None;
		NewField.HorizontalStretch = True;
	
		PriceTreeValue = Form.FormAttributeToValue("PriceTree"); // ValueTree
		PriceTreeValue.Columns.Clear();
		
		For Each Column In ValueTree.Columns Do
			PriceTreeValue.Columns.Add(Column.Name);
		EndDo;
		
		Form.ValueToFormAttribute(PriceTreeValue, "PriceTree");
		If TMCommonUseClientServer.HasObjectAttribute(Form, "SelectedPricesWereChanged") Then
			Form.SelectedPricesWereChanged = False;
		EndIf;

		If Not ThisIsVendorPriceRegistration Then
			MarkModifiedFormulas(Form, PriceTreeValue);
		EndIf;
		
	Else
		
		Form["PriceTree"] = ValueTree.Copy();
		
	EndIf;
	
EndProcedure

// Initializes the data cache structure
//
// Parameters:
//  DataCache - Structure - the data cache.
//
// Returns:
//  Structure - structure with properties:
//   * TableOfCorrespondenceOfProductsToRowsInProductTree - ValueTable, Undefined - Matching the item.
//   * ExchangeRates - ValueTable, Undefined, Map - Exchange rate.
//   * MatchingPriceTypesToColumnNamesInProductTable - Map - Compliance with the types of prices the column names.
//
Function InitializeDataCacheStructure(DataCache = Undefined) Export
	
	If DataCache = Undefined Then
		DataCache = New Structure;
		// Cache used to quickly search for a tree line by item
		DataCache.Insert("TableOfCorrespondenceOfProductsToRowsInProductTree");
		// Currency exchange rate cache
		DataCache.Insert("ExchangeRates");
		// Cache of column names of price types
		DataCache.Insert("MatchingPriceTypesToColumnNamesInProductTable", New Map);
		// Cache of the supplier's price registration checkbox
		DataCache.Insert("ThisIsVendorPriceRegistration");
	EndIf;
	
	Return DataCache;
	
EndFunction

// Copies an item with characteristics from the price tree to the value table
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  AddAllLines - Boolean 
//
// Returns:
//  ValueTable - table with columns:
//   * PartnerProducts - CatalogRef.ProductCrossReferences - The nomenclature of the supplier.
//   * Products           - CatalogRef.Products - Nomenclature.
//   * Characteristic         - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//
Function CreateTableOfProductsOnPriceTree(Form, AddAllLines = True) Export
	
	ProductsTable = CreateProductTable(Form);
	
	Parameters = New Structure();
	Parameters.Insert("Operation", "AddRowToProductTable");
	Parameters.Insert("PriceTreeIsDataTreeOfForm", (TypeOf(Form.PriceTree) = Type("FormDataTree")));
	Parameters.Insert("UsePriceManagementSystem25", Form.UsePriceManagementSystem25);
	Parameters.Insert("AddAllLines", AddAllLines);
	
	ApplyChangesToTree(Parameters, Form.PriceTree, ProductsTable);

	Return ProductsTable;
	
EndFunction

// Returns an empty table for products (without prices and packages).
//
// Parameters:
//  Form - See BuildPriceTree.Form
//
// Returns:
//  ValueTable - table with columns:
//   * PartnerProducts - CatalogRef.ProductCrossReferences - The nomenclature of the supplier.
//   * Products           - CatalogRef.Products - Nomenclature.
//   * Characteristic         - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//
Function CreateProductTable(Form) Export
	ValueTable = New ValueTable();
	
	ValueTable.Columns.Add("PartnerProducts",   New TypeDescription("CatalogRef.ProductCrossReferences"));
	ValueTable.Columns.Add("Products",           New TypeDescription("CatalogRef.Products"));
	If Form.UsePriceManagementSystem25 Then
		ValueTable.Columns.Add("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
		ValueTable.Columns.Add("PricingVariant",   New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		ValueTable.Columns.Add("PricingBatch",            New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		ValueTable.Columns.Add("TSOSeriesForCommunication",    New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		ValueTable.Columns.Add("PricingPackage",         New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		ValueTable.Columns.Add("TsoPackagingForCommunication", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Else	
		ValueTable.Columns.Add("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	
	Return ValueTable;
	
EndFunction

// Returns an empty table for products (with prices and packages).
//
// Parameters:
//  ThisIsVendorPriceRegistration - Boolean - Indicates that the table is being created to register the supplier's prices.
//  UsePriceManagementSystem25 - Boolean - The truth is, you are using new pricing.
//
// Returns:
//  ValueTable - table with columns:
//   * PartnerProducts - CatalogRef.ProductCrossReferences - The nomenclature of the supplier.
//   * Products           - CatalogRef.Products - Nomenclature.
//   * Characteristic         - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//   * PriceKind                - CatalogRef.VendorPriceTypes,CatalogRef.TypesOfPrices - Type of price.
//   * Price                   - Number - Price.
//   * Package               - CatalogRef.PackagesAndUnitsOfMeasure - Packaging.
//
Function CreateProductsTable(ThisIsVendorPriceRegistration, UsePriceManagementSystem25 = False) Export
	
	ValueTable = New ValueTable();
	
	ValueTable.Columns.Add("PartnerProducts", New TypeDescription("CatalogRef.ProductCrossReferences"));
	ValueTable.Columns.Add("Products",           New TypeDescription("CatalogRef.Products"));
	If UsePriceManagementSystem25 Then 
		ValueTable.Columns.Add("PricingVariant",   New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));		
		ValueTable.Columns.Add("PricingBatch",            New TypeDescription("CatalogRef.ItemsBatchesForPricing"));		
		ValueTable.Columns.Add("TSOSeriesForCommunication",    New TypeDescription("CatalogRef.ItemsBatchesForPricing"));		
		ValueTable.Columns.Add("PricingPackage",         New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		ValueTable.Columns.Add("TsoPackagingForCommunication", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Else
		ValueTable.Columns.Add("Characteristic",         New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If ThisIsVendorPriceRegistration Then
		ValueTable.Columns.Add("PriceKind", New TypeDescription("CatalogRef.VendorPriceTypes"));
		ValueTable.Columns.Add("OrderPackage", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		ValueTable.Columns.Add("PackagingName", New TypeDescription("String"));
		ValueTable.Columns.Add("MinimumDeliveryLot", New TypeDescription("Number"));
		ValueTable.Columns.Add("SettingConditions", New TypeDescription("Boolean"));
	Else
		ValueTable.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
		ValueTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	EndIf;
	ValueTable.Columns.Add("Price",                   New TypeDescription("Number"));
	ValueTable.Columns.Add("Package",               New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	ValueTable.Columns.Add("Formula",                New TypeDescription("String"));
	
	Return ValueTable;
	
EndFunction

// Initialisere props Companionstar used in the mechanisms for the selection of goods.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//
Procedure LoadDefaultSelectionSettings(Form) Export
	
	If SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode) Then
		DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate("TemplatePartnerSProducts");
	Else
		DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate("Template");
	EndIf;
	
	Form.SettingsComposerFilter.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, Form.UUID)));
	Form.SettingsComposerFilter.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	Form.SettingsComposerFilter.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	UseProductRange = GetFunctionalOption("UseProductRange");
	If UseProductRange Then
		DataCompositionClientServer.SetParameter(Form.SettingsComposerFilter.Settings, "ProductRangeAsOfDate", CurrentSessionDate());
	EndIf;
	
EndProcedure

// Returns data about price types, calculation rules and selections, and user settings for calculation.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCompositionSettings - ValueTable - Table of values, custom data layout settings
//                                                saved in the document.
//  ArrayOfPriceTypes - Array of CatalogRef.TypesOfPrices - 
//                 - Array of CatalogRef.VendorPriceTypes -  
//  TableOfPriceTypeSettings - ValueTable - LongDesc See InitializeTableOfSelectedPrices
//
// Returns:
//  ValueTable - table with columns:
//   * Ref - CatalogRef.TypesOfPrices - Type of price
//   * Description - String - Name of the price type
//   * Status - EnumRef.StatusesOfPriceTypeValidity - Price type status
//   * DeletionMark - Boolean - Flag for deleting the price type
//   * AddlOrderingAttribute - Number - Additional ordering details
//   * SetPriceDuringGeneration - Boolean - Set the entry price based on
//   * PricingMethod - EnumRef.PriceSettingMethods - Method for setting the price
//   * Id - String - ID for formulas
//   * ThresholdOnPriceIncreaseFor - Number - Operating threshold
//   * PriceCurrency - CatalogRef.Currencies - Price currency
//   * Formula - String - Formula
//   * BasicPriceType - String - ID of the base price type
//   * Markup - Number - Markup
//   * DataCompositionSchema - String - Name of the predefined layout of the data layout scheme
//   * ProhibitedPriceType - Boolean - Indicates that the price type is prohibited
//   * PriceGroups - ValueTable - with columns:
//     ** PriceGroup - CatalogRef.PriceGroups - The price group for which the price calculation algorithm is defined
//     ** Formula - String - Defines the price calculation rules for the price group
//     ** BasicPriceType - String - ID of the base price type
//     ** Markup - Number - Markup
//   * Thresholds - ValueTable - with columns:
//     ** PriceGroup - CatalogRef.PriceGroups - The price group for which the price calculation algorithm is defined
//     ** ThresholdOnPriceIncreaseFor - DefinedType.MonetaryAmountNonNegative - Defines the price calculation rules for the price group
//   * InfluencingPriceTypes - ValueTable - with columns:
//     ** InfluencingPriceType - CatalogRef.TypesOfPrices - Influencing the kind of prices
//   * PriceRoundingRules - ValueTable - with columns:
//     ** LowerBoundOfPriceRange - DefinedType.MonetaryAmountNonNegative - Minimum price value starting from which the rounding rule is applied
//     ** RoundingPrecision - DefinedType.MonetaryAmountNonNegative - Determines the accuracy of price rounding
//     ** SmartRounding - DefinedType.MonetaryAmountNonNegative - Subtract from the result
//   * RoundOffOption - EnumRef.RoundingOptions - The option of rounding
//   * Level - Number - Level
//   * InfluencingPrices - ValueList - Influencing prices.
//   * DependentPrices - ValueList - Dependent prices.
//   * ColumnName - String - column name.
//   * AddressOfDataCompositionSchema - String - Address of the data layout scheme.
//   * AddressOfDataCompositionSchemaSettings - String - Address of the data layout scheme settings.
//   * RequiredParametersAreFound - Boolean - Found the required parameters.
//   * Parameters - String - Parameter description.
//
Function DownloadPriceCatalog(Form, DataCompositionSettings, ArrayOfPriceTypes = Undefined, TableOfPriceTypeSettings = Undefined) Export
	
	DataCache = InitializeDataCacheStructure();
	
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text =
	"SELECT ALLOWED
	|	TypesOfPrices.Ref AS Ref
	|INTO TableOfAllowed
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|";
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	MAX(ItemsPrices.Period) AS Period,
	|	ItemsPrices.PriceKind AS PriceKind
	|INTO PriceSettingDates
	|FROM
	|	&InformationRegisterItemPricesCrossSectionOfTheLatest AS ItemsPrices
	|GROUP BY
	|	ItemsPrices.PriceKind
	|;
	|////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfPrices.Ref AS Ref,
	|	TypesOfPrices.Description AS Description,
	|	TypesOfPrices.Status AS Status,
	|	TypesOfPrices.DeletionMark AS DeletionMark,
	|	&CatalogData1,
	|	&SettingsTableData1,
	|	TypesOfPrices.SetPriceDuringGeneration AS SetPriceDuringGeneration,
	|	TypesOfPrices.PricingMethod AS PricingMethod,
	|	TypesOfPrices.Id AS Id,
	|	TypesOfPrices.ThresholdOnPriceIncreaseFor AS ThresholdOnPriceIncreaseFor,
	|	TypesOfPrices.ThresholdOnPriceDecreaseBy AS ThresholdOnPriceDecreaseBy,
	|	TypesOfPrices.PriceCurrency AS Currency,
	|	TypesOfPrices.Formula AS Formula,
	|	TypesOfPrices.BasicPriceType.Id AS BasicPriceType,
	|	TypesOfPrices.Markup AS Markup,
	|	TypesOfPrices.OptionForSpecifyingVATRates AS OptionForSpecifyingVATRates,
	|	TypesOfPrices.Country AS Country,
	|	TypesOfPrices.VATRate AS VATRate,
	|	TypesOfPrices.DataCompositionSchema AS DataCompositionSchema,
	|	CASE
	|		WHEN TableOfAllowed.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ProhibitedPriceType,
	|	TRUE AS TypeOfPriceInArray,
	|	TypesOfPrices.PriceGroups.(
	|		PriceGroup AS PriceGroup,
	|		Formula AS Formula,
	|		BasicPriceType.Id AS BasicPriceType,
	|		Markup AS Markup),
	|	TypesOfPrices.Thresholds.(
	|		PriceGroup AS PriceGroup,
	|		ThresholdOnPriceIncreaseFor AS ThresholdOnPriceIncreaseFor,
	|		ThresholdOnPriceDecreaseBy AS ThresholdOnPriceDecreaseBy),
	|	TypesOfPrices.Currencies.(
	|		PriceGroup AS PriceGroup,
	|		PriceCurrency AS Currency),
	|	TypesOfPrices.InfluencingPriceTypes.(
	|		InfluencingPriceType AS InfluencingPriceType),
	|	TypesOfPrices.PriceRoundingRules.(
	|		ISNULL(LowerBoundOfPriceRange, 0) AS LowerBoundOfPriceRange,
	|		RoundingPrecision AS RoundingPrecision,
	|		SmartRounding AS SmartRounding),
	|	TypesOfPrices.RoundOffOption AS RoundOffOption,
	|	TypesOfPrices.DisablePriceEditingOutsideFilter AS DisablePriceEditingOutsideFilter,
	|	TypesOfPrices.StorageOfDataCompositionSchema AS StorageOfDataCompositionSchema,
	|	TypesOfPrices.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings,
	|	TypesOfPrices.StorageOfFilterByItemsDataCompositionSettings AS StorageOfFilterByItemsDataCompositionSettings,
	|	PriceSettingDates.Period AS DateOfTheLastPriceSetting
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|LEFT JOIN
	|	TableOfAllowed AS TableOfAllowed
	|ON
	|	TypesOfPrices.Ref = TableOfAllowed.Ref
	|LEFT JOIN
	|	 PriceSettingDates AS PriceSettingDates
	|ON
	|	PriceSettingDates.PriceKind = TypesOfPrices.Ref
	|	,&SettingsTableData2
	|WHERE
	|	NOT TypesOfPrices.IsFolder
	|ORDER BY
	|	&SettingsTableData3,
	|	&CatalogData2,
	|	LowerBoundOfPriceRange ASC
	|";
	
	If UsePriceManagementSystem25 Then
		Query.Text = StrReplace(Query.Text, "&InformationRegisterItemPricesCrossSectionOfTheLatest", 
		"InformationRegister.ItemsPrices25.SliceLast");
	Else
		Query.Text = StrReplace(Query.Text, "&InformationRegisterItemPricesCrossSectionOfTheLatest", 
		"InformationRegister.ItemsPrices.SliceLast");
	EndIf;
	
	If ArrayOfPriceTypes <> Undefined Then
		Query.Text = StrReplace(Query.Text, "TRUE AS TypeOfPriceInArray,", 
			"	CASE
			|		WHEN TypesOfPrices.Ref IN (&ArrayOfPriceTypes)
			|			THEN TRUE
			|		ELSE FALSE
			|	 END AS TypeOfPriceInArray,");
		Query.Parameters.Insert("ArrayOfPriceTypes", ArrayOfPriceTypes);
	EndIf;

	If TableOfPriceTypeSettings <> Undefined Then
		Query.Parameters.Insert("TableOfPriceTypeSettings", TableOfPriceTypeSettings);
		QueryTextFilterByTable = "SELECT
		|	TableOfPriceTypeSettings.PriceKind AS PriceKind,
		|	TableOfPriceTypeSettings.AddlOrderingAttribute AS AddlOrderingAttribute
		|INTO TableOfPriceTypeSettings
		|FROM &TableOfPriceTypeSettings AS TableOfPriceTypeSettings 
		|;
		|";	
		Query.Text = QueryTextFilterByTable + Query.Text;
		
		Query.Text = StrReplace(Query.Text, "&SettingsTableData1,", 
			"	CASE WHEN TableOfPriceTypeSettings.PriceKind IS NOT NULL
			|		THEN TableOfPriceTypeSettings.AddlOrderingAttribute 
			|		ELSE TypesOfPrices.AddlOrderingAttribute
			|	END AS AddlOrderingAttribute,");
		Query.Text = StrReplace(Query.Text, ",&SettingsTableData2", 
			"LEFT JOIN TableOfPriceTypeSettings
			|				ON TypesOfPrices.Ref = TableOfPriceTypeSettings.PriceKind");
		Query.Text = StrReplace(Query.Text, "&SettingsTableData3,", 
			"TableOfPriceTypeSettings.AddlOrderingAttribute,");

		Query.Text = StrReplace(Query.Text, "&CatalogData1,", "");
		Query.Text = StrReplace(Query.Text, "&CatalogData2,", "");
		
	Else
		
		Query.Text = StrReplace(Query.Text, "&SettingsTableData1,", "");
		Query.Text = StrReplace(Query.Text, ",&SettingsTableData2", "");
		Query.Text = StrReplace(Query.Text, "&SettingsTableData3,", "");
		
		Query.Text = StrReplace(Query.Text, "&CatalogData1,", 
			"TypesOfPrices.AddlOrderingAttribute AS AddlOrderingAttribute,");
		Query.Text = StrReplace(Query.Text, "&CatalogData2,", 
			"TypesOfPrices.AddlOrderingAttribute,");
		
	EndIf;
		
	SetPrivilegedMode(True);
	TableOfPriceTypes = Query.Execute().Unload(); // See DownloadPriceCatalog
	
	TableOfPriceTypes.Columns.Add("Level",       New TypeDescription("Number"));
	TableOfPriceTypes.Columns.Add("InfluencingPrices",  New TypeDescription("ValueList"));
	TableOfPriceTypes.Columns.Add("DependentPrices", New TypeDescription("ValueList"));
	TableOfPriceTypes.Columns.Add("ColumnName",    New TypeDescription("String"));
	// Service speakers for working with DCS settings
	TableOfPriceTypes.Columns.Add("AddressOfDataCompositionSchema",         New TypeDescription("String"));
	TableOfPriceTypes.Columns.Add("AddressOfDataCompositionSchemaSettings", New TypeDescription("String"));
	TableOfPriceTypes.Columns.Add("AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem", New TypeDescription("String"));
	TableOfPriceTypes.Columns.Add("RequiredParametersAreFound", New TypeDescription("Boolean"));
	TableOfPriceTypes.Columns.Add("Parameters",                    New TypeDescription("String"));
	// Indexing
	TableOfPriceTypes.Indexes.Add("Ref");
	
	ParametersOfLayoutSchemesForTheseTypesOfPrices = New ValueTable;
	ParametersOfLayoutSchemesForTheseTypesOfPrices.Columns.Add("Use");
	ParametersOfLayoutSchemesForTheseTypesOfPrices.Columns.Add("PriceKind");
	ParametersOfLayoutSchemesForTheseTypesOfPrices.Columns.Add("Name");
	ParametersOfLayoutSchemesForTheseTypesOfPrices.Columns.Add("Title");
	ParametersOfLayoutSchemesForTheseTypesOfPrices.Columns.Add("Value");
	ParametersOfLayoutSchemesForTheseTypesOfPrices.Columns.Add("AvailableValues");
	
	ArrayOfDeletedPriceTypes = New Array();
	
	For Each PriceViewString In TableOfPriceTypes Do
		
		FindDependentAndInfluencingPrices(TableOfPriceTypes, PriceViewString.Ref);
		
		PriceViewString.ColumnName = ColumnNameByPriceType(PriceViewString.Ref, DataCache);
		
		TemplateParameters1 = Catalogs.TypesOfPrices.InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName();
		TemplateParameters1.Ref 				= PriceViewString.Ref;
		TemplateParameters1.TemplateName 			= PriceViewString.DataCompositionSchema;
		TemplateParameters1.GetSettings 	= False;
		TemplateParameters1.StorageOfDataCompositionSchema 	= PriceViewString.StorageOfDataCompositionSchema;
		TemplateParameters1.StorageOfDataCompositionSettings 	= PriceViewString.StorageOfDataCompositionSettings;
		TemplateParameters1.StorageOfFilterByItemsDataCompositionSettings 	= PriceViewString.StorageOfFilterByItemsDataCompositionSettings;
		TemplateParameters1.UsePriceManagementSystem25 	= UsePriceManagementSystem25;
				
		SchemeAndSettings = Catalogs.TypesOfPrices.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1);
		
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
		
		If ValueIsFilled(SchemeAndSettings.ProductSelectionDataLayoutSettings)
			And ValueIsFilled(SchemeAndSettings.DataCompositionSettings) Then

			DataCompositionClientServer.CopyElements(
				SchemeAndSettings.DataCompositionSettings.Filter,
				SchemeAndSettings.ProductSelectionDataLayoutSettings.Filter,
				False
			);
			
		EndIf;
		
		// Parameters data layout scheme
		AllowedNames = PriceSetupServerCall.NamesOfAllowedDataLayoutSchemeParameters();
		For Each DataParameter In DataCompositionSchema.Parameters Do
			
			If AllowedNames.Find(DataParameter.Name) = Undefined Then
				If StrFind(DataCompositionSchema.DataSets[0].Query,"&"+DataParameter.Name) Then
					PriceViewString.RequiredParametersAreFound = True;
				EndIf;
			Else
				DataParameter.UseRestriction = True;
				DataParameter.IncludeInAvailableFields   = False;
			EndIf;
			
			FoundRows = ParametersOfLayoutSchemesForTheseTypesOfPrices.FindRows(
				New Structure("Name, PriceKind",DataParameter.Name, PriceViewString.Ref));
			If FoundRows.Count() = 0
				And AllowedNames.Find(DataParameter.Name) = Undefined
				And Not DataParameter.UseRestriction Then
				
				NewParameter1 = ParametersOfLayoutSchemesForTheseTypesOfPrices.Add();
				NewParameter1.PriceKind           = PriceViewString.Ref;
				NewParameter1.Name               = DataParameter.Name;
				NewParameter1.Title         = DataParameter.Title;
				NewParameter1.Value          = DataParameter.Value;
				NewParameter1.AvailableValues = DataParameter.GetAvailableValues();
				NewParameter1.Use     = DataParameter.Use;
				
			EndIf;
			
		EndDo;
		
		// customize the layout data
		UserSetting = DataCompositionSettings.Find(PriceViewString.Ref, "PriceKind");
		If UserSetting = Undefined
			And PriceViewString.RequiredParametersAreFound Then
			
			UserSetting = DataCompositionSettings.Add();
			UserSetting.PriceKind                   = PriceViewString.Ref;
			
			If Not ValueIsFilled(SchemeAndSettings.DataCompositionSettings) Then
				SettingsComposer = New DataCompositionSettingsComposer;
				SetPrivilegedMode(True);
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
				SetPrivilegedMode(False);
				
				SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
				
				DefaultSettings = SettingsComposer.GetSettings();
				SchemeAndSettings.DataCompositionSettings = DefaultSettings;
				If ValueIsFilled(SchemeAndSettings.ProductSelectionDataLayoutSettings) Then
					DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema,SchemeAndSettings.DataCompositionSettings, SchemeAndSettings.ProductSelectionDataLayoutSettings); 
				EndIf;
				UserSetting.DataCompositionSettings = SchemeAndSettings.DataCompositionSettings;
			Else
				UserSetting.DataCompositionSettings = SchemeAndSettings.DataCompositionSettings;
			EndIf;
			
			StructureOfData = PriceSetupServerCall.DescriptionOfDataLayoutSchemeParameters(
				PriceViewString.Ref,
				UserSetting.DataCompositionSettings,
				ParametersOfLayoutSchemesForTheseTypesOfPrices);
			
		ElsIf UserSetting = Undefined
			And Not PriceViewString.RequiredParametersAreFound Then
			
			If Not ValueIsFilled(SchemeAndSettings.DataCompositionSettings) Then
				
				DefaultSettings = New DataCompositionSettings;
				DataCompositionClientServer.CopyDataLayoutSettings(DefaultSettings, DataCompositionSchema.DefaultSettings); 
				
				SchemeAndSettings.DataCompositionSettings = DefaultSettings;
				If ValueIsFilled(SchemeAndSettings.ProductSelectionDataLayoutSettings) Then
					DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema,SchemeAndSettings.DataCompositionSettings, SchemeAndSettings.ProductSelectionDataLayoutSettings); 
				EndIf;
					
			EndIf;
			
			StructureOfData = PriceSetupServerCall.DescriptionOfDataLayoutSchemeParameters(
				PriceViewString.Ref,
				SchemeAndSettings.DataCompositionSettings,
				ParametersOfLayoutSchemesForTheseTypesOfPrices);
			
		Else
			
			StructureOfData = PriceSetupServerCall.DescriptionOfDataLayoutSchemeParameters(PriceViewString.Ref,
				UserSetting.DataCompositionSettings,
				ParametersOfLayoutSchemesForTheseTypesOfPrices);
			
		EndIf;
		
		PriceViewString.AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, Form.UUID);
		If ValueIsFilled(SchemeAndSettings.DataCompositionSettings) Then
			PriceViewString.AddressOfDataCompositionSchemaSettings = PutToTempStorage(
				SchemeAndSettings.DataCompositionSettings,
				Form.UUID);
		EndIf;
		
		If ValueIsFilled(SchemeAndSettings.ProductSelectionDataLayoutSettings) Then
			PriceViewString.AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem = PutToTempStorage(
				SchemeAndSettings.ProductSelectionDataLayoutSettings,
				Form.UUID);
		EndIf;
		
		PriceViewString.Parameters = StructureOfData.ParametersDetails;
		
	EndDo;
	
	Form.AddressOfTheStorageOfLayoutSchemeParametersByPriceType = PutToTempStorage(
		ParametersOfLayoutSchemesForTheseTypesOfPrices,
		Form.UUID);
		
	ThereAreAttributesPriceTypes = TMCommonUseClientServer.HasObjectAttribute(Form.Object, "TypesOfPrices");
	For Each PriceViewString In TableOfPriceTypes Do
		DeletePriceView = True;
		If PriceViewString.DeletionMark
			Or PriceViewString.ProhibitedPriceType
			Or Not PriceViewString.TypeOfPriceInArray Then
			
			If PriceViewString.DependentPrices.Count() <> 0 Then
				For Each PriceKind In PriceViewString.DependentPrices Do
					ValueFound = TableOfPriceTypes.Find(PriceKind.Value, "Ref");
					If ValueFound <> Undefined Then
						If Not ValueFound.DeletionMark
							Or PriceViewString.TypeOfPriceInArray Then
							DeletePriceView = False;
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
			If DeletePriceView
				And ArrayOfDeletedPriceTypes.Find(PriceViewString) = Undefined
				And (ThereAreAttributesPriceTypes
					And Form.Object.TypesOfPrices.FindRows(New Structure("PriceKind" , PriceViewString.Ref)).Count() = 0)
					Or Not ThereAreAttributesPriceTypes Then
				ArrayOfDeletedPriceTypes.Add(PriceViewString);
			EndIf;
			
		EndIf;
	EndDo;
	
	For Each PriceViewString In TableOfPriceTypes Do
		LinesToDelete = New Array;
		For Each PriceKind In PriceViewString.DependentPrices Do
			If ArrayOfDeletedPriceTypes.Find(TableOfPriceTypes.Find(PriceKind.Value, "Ref")) <> Undefined Then
				LinesToDelete.Add(PriceKind);
			EndIf;
		EndDo;
		For Each ArrayElement In LinesToDelete Do
			PriceViewString.DependentPrices.Delete(ArrayElement);
		EndDo;
	EndDo;
	
	For Each CurItem In ArrayOfDeletedPriceTypes Do
		TableOfPriceTypes.Delete(CurItem);
	EndDo;
	
	Return TableOfPriceTypes;
	
EndFunction

// Returns data about the supplier's price types.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//
// Returns:
//  ValueTable - Table of supplier price types:
//   * Ref - CatalogRef.VendorPriceTypes - Supplier's price type
//   * Description - String - Name of the price type
//   * DeletionMark - Boolean - Flag for deleting the price type
//   * Currency - CatalogRef.Currencies - Price currency
//   * PriceIncludesVAT - Boolean - Price includes VAT
//   * ProhibitedPriceType - Boolean - Indicates that the price type is prohibited
//   * ColumnName - See ColumnNameByPriceType
//
Function DownloadSupplierSPriceCatalog(Form) Export
	
	DataCache = InitializeDataCacheStructure();
	
	RequestPermittedTypesOfPrices = New Query(
	"SELECT ALLOWED
	|	TypesOfPrices.Ref
	|FROM
	|	Catalog.VendorPriceTypes AS TypesOfPrices");
	
	Query = New Query(
	"SELECT
	|	TypesOfPrices.Ref AS Ref,
	|	TypesOfPrices.Description AS Description,
	|	TypesOfPrices.DeletionMark AS DeletionMark,
	|	TypesOfPrices.Currency AS Currency,
	|	TypesOfPrices.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN NOT TypesOfPrices.Ref IN (&PermittedTypesOfPrices)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ProhibitedPriceType
	|FROM
	|	Catalog.VendorPriceTypes AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Owner = &Owner
	|
	|ORDER BY
	|	TypesOfPrices.AddlOrderingAttribute");
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Partner") Then
		Query.Parameters.Insert("Owner", Form.Object.Partner);
	Else
		Query.Parameters.Insert("Owner", Form.Partner);
	EndIf;
	
	Query.Parameters.Insert("PermittedTypesOfPrices", RequestPermittedTypesOfPrices.Execute().Unload().UnloadColumn("Ref"));
	
	SetPrivilegedMode(True);
	TableOfPriceTypes = Query.Execute().Unload(); // See DownloadSupplierSPriceCatalog
	
	TableOfPriceTypes.Columns.Add("ColumnName", New TypeDescription("String"));
	// Indexing
	TableOfPriceTypes.Indexes.Add("Ref");
	
	For Each PriceViewString In TableOfPriceTypes Do
		PriceViewString.ColumnName = ColumnNameByPriceType(PriceViewString.Ref, DataCache);
	EndDo;
	
	Return TableOfPriceTypes;
	
EndFunction

// Returns a table of data layout settings from the document.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//
// Returns:
//  ValueTable - customize the layout data:
//  * PriceKind - CatalogRef.TypesOfPrices - Price types
//  * DataCompositionSettings - DataCompositionSettings
//  * DataCompositionParameters - QuerySchemaTableDataCompositionParameters
//
Function LoadDataLayoutSettingsTable(Form) Export
	
	DataLayoutSettingsTable = New ValueTable;
	DataLayoutSettingsTable.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	DataLayoutSettingsTable.Columns.Add("DataCompositionSettings");
	DataLayoutSettingsTable.Columns.Add("DataCompositionParameters");
	
	// For an existing document, download the layout scheme settings.
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Ref")
		And ValueIsFilled(Form.Object.Ref) Then
		
		Query = New Query(
		"SELECT
		|	PriceSetupTypesOfPrices.PriceKind                   AS PriceKind,
		|	PriceSetupTypesOfPrices.DataCompositionSettings AS DataCompositionSettings
		|FROM
		|	Document.PriceSetup.TypesOfPrices AS PriceSetupTypesOfPrices
		|WHERE
		|	PriceSetupTypesOfPrices.Ref = &Ref");
		Query.SetParameter("Ref", Form.Object.Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			StorageForDataLayoutSettings = Selection.DataCompositionSettings;//ValueStorage
			DataCompositionSettings = StorageForDataLayoutSettings.Get();
			If DataCompositionSettings <> Undefined Then
				NewRow = DataLayoutSettingsTable.Add();
				NewRow.PriceKind                   = Selection.PriceKind;
				NewRow.DataCompositionSettings = DataCompositionSettings;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return DataLayoutSettingsTable;
	
EndFunction

// Initializes the "Selected prices" table on the form"
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ArrayOfPriceTypes - Array of CatalogRef.TypesOfPrices
//                 - Array of CatalogRef.VendorPriceTypes
//  TableOfPriceTypes - ValueTable - table of price types
//
Procedure InitializeSelectedPrices(Form, ArrayOfPriceTypes = Undefined, TableOfPriceTypes = Undefined) Export
	
	If ThisIsVendorPriceRegistration(Form) Then
		InitializeSelectedSupplierPrices(Form);
	Else
		InitializeSelectedProductPrices(Form, ArrayOfPriceTypes, TableOfPriceTypes);
	EndIf;
	
EndProcedure

// Re-read selected prices
//
// Parameters:
//  Form - See BuildPriceTree.Form
// 
Procedure ReReadSelectedPrices(Form) Export
	
	TypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(Form);
	
	InitializeSelectedPrices(Form);
	
	For Each TSRow In Form.SelectedPrices Do
		TSRow.Selected_5 = (TypesOfPrices.Find(TSRow.Ref) <> Undefined);
	EndDo;
	
EndProcedure

// Returns a table of data layout settings from the document
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  GoodsTable - ValueTable - table with added products
//  DataCache - See InitializeDataCacheStructure
//
// Returns:
//  ValueTable - matching the nomenclature and characteristics with the added line of the price tree.
//
Function AddSupplierProducts(Form, Val GoodsTable, DataCache) Export
	
	UseValueTableInsteadOfValueTree = UseValueTableInsteadOfValueTree(Form);
	
	TMCommonUse.NumberValueTable(GoodsTable, "IndexOf");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Table.IndexOf                 AS IndexOf,
	|	Table.PartnerProducts AS PartnerProducts,
	|	Table.Products           AS Products,
	|	Table.Characteristic         AS Characteristic
	|INTO TableOfProducts
	|FROM
	|	&Table AS Table
	|WHERE
	|	&ConditionForProducts
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|SELECT
	|	TableOfProducts.PartnerProducts              AS PartnerProducts,
	|	TableOfProducts.PartnerProducts.Description AS Description,
	|	TableOfProducts.Products                        AS Products,
	|	TableOfProducts.Products.SKU                AS SKU,
	|	TableOfProducts.Products.UnitOfMeasure       AS UnitOfMeasure,
	|	TableOfProducts.Products.PriceGroup          AS PriceGroup,
	|	TableOfProducts.Characteristic                      AS Characteristic,
	|	CASE
	|		WHEN TableOfProducts.Products.UseVariants IN 
	|			(VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|			 VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|			 VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|FROM
	|	TableOfProducts AS TableOfProducts
	|
	|ORDER BY
	|	TableOfProducts.IndexOf";
	
	If Not UseValueTableInsteadOfValueTree Then
		Query.Text = Query.Text + "
		|TOTALS
		|	CASE
		|		WHEN MAX(ItemVariantsAreUsed)
		|			THEN VALUE(Catalog.ProductCrossReferences.EmptyRef)
		|		ELSE MAX(PartnerProducts)
		|	END AS PartnerProducts,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic
		|BY
		|	Products
		|";
	EndIf;
	
	If Form.UseItemPackages Then
		Query.Text = Query.Text + "
		|;
		|SELECT ALLOWED
		|	ItemsPrices.Products      AS Products,
		|	ItemsPrices.Characteristic    AS Characteristic,
		|	ItemsPrices.Package          AS Package,
		|	ItemsPrices.VendorPriceKind AS PriceKind
		|FROM
		|	InformationRegister.ItemsPricesOfVendor.SliceLast(&DocumentDate, (Products, Characteristic) IN (SELECT T.Products, T.Characteristic FROM TableOfProducts AS T) AND VendorPriceKind IN (&TypesOfPrices)) AS ItemsPrices
		|";
	EndIf;

	Query.SetParameter("Table", GoodsTable);
	Query.SetParameter("TypesOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(Form));
	Query.SetParameter("DocumentDate", EndOfDay(DocumentDate(Form)));
	
	If ThisIsVendorPriceRegistration(Form, DataCache) Then
		Query.Text = StrReplace(Query.Text, "&ConditionForProducts", "True");
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionForProducts", "Table.Products <> VALUE(Catalog.Products.EmptyRef)");
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	
	SelectionOfProducts = QueryResult[1].Select(QueryResultIteration.ByGroups);
	
	If Form.UseItemPackages Then
		Packages = QueryResult[2].Unload(); // ValueTable
		Packages.Indexes.Add("Products, Characteristic");
	EndIf;
	
	ProductsTable = CreateProductTable(Form);
	ProductsTable.Columns.Add("PriceTreeString");
	
	If TypeOf(Form.PriceTree) = Type("FormDataCollection") Then
		ProductItems_ = Form.PriceTree;
	Else
		ProductItems_ = Form.PriceTree.GetItems(); // FormDataTreeItemCollection
	EndIf;
	
	While SelectionOfProducts.Next() Do
		
		ProductItem = Undefined;
		
		ProductsNotFilledIn = False;
		If ValueIsFilled(SelectionOfProducts.Products) Then
		
			FilterParameters = New Structure("Products, Characteristic");
			FillPropertyValues(FilterParameters, SelectionOfProducts);
			
			FoundRow = FindPriceTreeString(Form, FilterParameters, DataCache, False);
			
			If FoundRow <> Undefined
				Or ProductsTable.FindRows(FilterParameters).Count() Then
				
				ProductItem = FoundRow;
				
			Else
				
				ProductItem = ProductItems_.Add();
				FillPropertyValues(ProductItem, SelectionOfProducts);
				SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(ProductItem);
				
				NewLineOfVT = NewRowOfMatchingTable(DataCache, ProductItem, True);
				
				FillPropertyValues(ProductsTable.Add(), NewLineOfVT);
				
				If Form.UseItemPackages Then
					
					SearchParameters = New Structure;
					SearchParameters.Insert("Products", SelectionOfProducts.Products);
					If UseValueTableInsteadOfValueTree Then
						SearchParameters.Insert("Characteristic", SelectionOfProducts.Characteristic);
					Else
						SearchParameters.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
					EndIf;
					
					FoundRows = Packages.FindRows(SearchParameters);
					For Each PackageSelection In FoundRows Do
						ProductItem["Package" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
					EndDo;
					
				EndIf;
				
			EndIf;
		
		Else
			ProductsNotFilledIn = True;
		EndIf;
		
		If ProductsNotFilledIn
			Or (Not UseValueTableInsteadOfValueTree
		     And Form.UseItemVariants) Then
			
			FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
			
			If Not ProductsNotFilledIn Then
				FeatureElements = ProductItem.GetItems();
			EndIf;
			
			While FeatureSelection_.Next() Do
				
				If ValueIsFilled(FeatureSelection_.Characteristic) Or ProductsNotFilledIn Then
					
					FilterParameters = New Structure("Products, Characteristic");
					FillPropertyValues(FilterParameters, FeatureSelection_);
					FoundRow = FindPriceTreeString(Form, FilterParameters, DataCache, False);
					
					If FoundRow <> Undefined
						Or ProductsTable.FindRows(FilterParameters).Count() Then
						
						ElementCharacteristic = FoundRow;
						
					Else
						
						If Not ProductsNotFilledIn Then
							ElementCharacteristic = FeatureElements.Add();
						Else
							ElementCharacteristic = ProductItems_.Add();
						EndIf;
						
						FillPropertyValues(ElementCharacteristic, FeatureSelection_);
						SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(ElementCharacteristic);
						
						NewLineOfVT = NewRowOfMatchingTable(DataCache, ElementCharacteristic, True);
						
						FillPropertyValues(ProductsTable.Add(), NewLineOfVT);
						
						If Form.UseItemPackages Then
							
							SearchParameters = New Structure;
							SearchParameters.Insert("Products", ElementCharacteristic.Products);
							SearchParameters.Insert("Characteristic", ElementCharacteristic.Characteristic);
							
							FoundRows = Packages.FindRows(SearchParameters);
							For Each PackageSelection In FoundRows Do
								ElementCharacteristic["Package" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
							EndDo;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return ProductsTable;
	
EndFunction

// Returns a table of data layout settings from the document
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  GoodsTable - ValueTable - table with added products
//  DataCache - See InitializeDataCacheStructure
//
// Returns:
//  ValueTable - matching the nomenclature and characteristics with the added line of the price tree.
//
Function AddProducts_2(Form, Val GoodsTable, DataCache) Export
	
	If ThisIsVendorPriceRegistration(Form, DataCache) Then
		Return AddSupplierProducts(Form, GoodsTable, DataCache);
	Else
		If Form.UsePriceManagementSystem25 Then
			Return AddCompanyProducts2_5(Form, GoodsTable, DataCache);
		Else
			Return AddCompanyProducts(Form, GoodsTable, DataCache);
		EndIf;
	EndIf;
	
EndFunction

// Returns a table of data layout settings from the document
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  AddressInTempStorage - String - Address of the product table in temporary storage
//  GoodsTable - ValueTable - Added products
//  ToBeFilledInPriceType - CatalogRef.TypesOfPrices - A manual change flag will be added to the prices for this type of price
//  DataCache - See InitializeDataCacheStructure
//  UpdateOldPrices - Boolean - True, cause the old prices to be updated
Procedure AddGoodsByPicking(Form,
	                           AddressInTempStorage,
	                           Val GoodsTable = Undefined,
	                           ToBeFilledInPriceType = Undefined,
	                           DataCache = Undefined,
	                           UpdateOldPrices = True) Export
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Form, DataCache);
	
	If GoodsTable = Undefined Then
		GoodsTable = GetFromTempStorage(AddressInTempStorage);
	EndIf;
	
	TableOfUnavailableItems = ItemsThatAreNotAvailableForSettingPrices(GoodsTable);
	If TableOfUnavailableItems.Count() Then
		
		TextUnavailableItems = "";
		
		For Each UnavailableItemLine In TableOfUnavailableItems Do
			
			TextUnavailableItems = TextUnavailableItems
				+ StringFunctionsClientServer.SubstituteParametersToString("- %1 - %2",
					ProductsClientServer.ProductPresentation(
						UnavailableItemLine.Products,
						UnavailableItemLine.Characteristic),
					UnavailableItemLine.Cause)
				+ Chars.LF;
			
		EndDo;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đặt bảng giá đối với hàng hóa: 
				|%1';
				|ru = 'Установка цен недоступна для товаров:
				|%1';
				|en = 'Price setup is unavailable for goods:
				|%1'; fa = 'Price setup is unavailable for goods:
				|%1';
				|it = 'Price setup is unavailable for goods:
				|%1';
				|pl = 'Price setup is unavailable for goods:
				|%1';
				|tr = 'Fiyat yapılandırması şu ürünler için mevcut değildir:
				|%1'"),
			TrimAll(TextUnavailableItems));
		
		CommonClientServer.MessageToUser(
			MessageText);
		
	EndIf;
	
	If GoodsTable.Count() = 0 Then
		Return;
	EndIf;
	
	ProductsTable = AddProducts_2(Form, GoodsTable, DataCache);
	
	If UpdateOldPrices Then
		UpdateOldProductPrices(Form, DataCache, ProductsTable);
	EndIf;
	
	ArrayOfPriceTypeStrings = Undefined;
	
	// Fill in the prices for the selected type of prices
	If ValueIsFilled(ToBeFilledInPriceType) Then
		
		For Each TableRow In GoodsTable Do
			
			PriceTreeString = FindPriceTreeString(Form, TableRow, DataCache);
			
			NewPrice = TableRow.Price;
			NameOfPriceTypeColumn = ColumnNameByPriceType(ToBeFilledInPriceType, DataCache);
			
			UpdateDataInLineByPricesPackages(PriceTreeString, New Structure("UseItemPackages, NewPrice, Package, NameOfPriceTypeColumn", Form.UseItemPackages, NewPrice, TableRow.Package, NameOfPriceTypeColumn));
		EndDo;
		
		// we will exclude the set type of prices from the subsequent automatic calculation
		ArrayOfPriceTypeStrings = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
		
		IndexOfPriceTypeToFillIn = 0;
		For Each Item In ArrayOfPriceTypeStrings Do
			If Item.Ref = ToBeFilledInPriceType Then
				ArrayOfPriceTypeStrings.Delete(IndexOfPriceTypeToFillIn);
				Break;
			EndIf; 
			IndexOfPriceTypeToFillIn = IndexOfPriceTypeToFillIn + 1;
		EndDo;
		
	EndIf;
	
	// Automatic price calculation
	If Not ThisIsVendorPriceRegistration
		And Form.CalculateAutomatically Then
		
		ParametersStructure = New Structure();
		If ValueIsFilled(ToBeFilledInPriceType) And ArrayOfPriceTypeStrings <> Undefined Then
			ParametersStructure.Insert("ArrayOfPriceTypeStrings", ArrayOfPriceTypeStrings);
		Else
			ParametersStructure.Insert("ArrayOfPriceTypeStrings", SettingPricesClientServer.SelectedRowsInPriceViewTable(Form));
		EndIf;
		
		LoadBasePriceValues(
			Form,
			ProductsTable,
			DataCache,
			ParametersStructure);
			
		CalculatePricesBasedOnInformationSecurityData(Form, ProductsTable, ArrayOfPriceTypeStrings,, DataCache);
		
		CalculateCalculatedPrices(Form, ProductsTable, DataCache, ArrayOfPriceTypeStrings);
		
	EndIf;
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
	
		// Let's set the last added line to the current one
		If ProductsTable.Count() > 0 Then
			Form.Items.PriceTree.CurrentRow = ProductsTable[ProductsTable.Count()-1].PriceTreeString.GetID();
		EndIf;
		
		If Not ThisIsVendorPriceRegistration Then
			MarkModifiedFormulas(Form);
		EndIf;
	EndIf;
	
EndProcedure

Procedure UpdateDataInLineByPricesPackages(PriceTreeString, FillParameters)
	NameOfPriceTypeColumn = FillParameters.NameOfPriceTypeColumn;
	
	If PriceTreeString[NameOfPriceTypeColumn] <> FillParameters.NewPrice Then
		
		PriceTreeString[NameOfPriceTypeColumn] = FillParameters.NewPrice;
		PriceTreeString["ChangedManually"       + NameOfPriceTypeColumn] = True;
		PriceTreeString["ChangedAutomatically" + NameOfPriceTypeColumn] = False;
		
		If PriceTreeString["OldPrice"+NameOfPriceTypeColumn] <> 0 Then
			PriceTreeString["ChangePercentage"+NameOfPriceTypeColumn] = Round(100*(PriceTreeString[NameOfPriceTypeColumn] - PriceTreeString["OldPrice"+NameOfPriceTypeColumn])/PriceTreeString["OldPrice"+NameOfPriceTypeColumn],5,2);
			PriceTreeString["AmountOfChange"+NameOfPriceTypeColumn] = PriceTreeString[NameOfPriceTypeColumn] - PriceTreeString["OldPrice"+NameOfPriceTypeColumn];
		Else
			PriceTreeString["ChangePercentage"+NameOfPriceTypeColumn] = 0;
			PriceTreeString["AmountOfChange"+NameOfPriceTypeColumn] = 0;
		EndIf;
		
	EndIf;
	
	If FillParameters.UseItemPackages Then
		
		PriceTreeString["Package" + NameOfPriceTypeColumn] = FillParameters.Package;
		
	EndIf;
EndProcedure

// Calculates prices in a line by ID
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  RowID - Number - row ID
//  UploadPricesFromIB - Boolean - Indicates the need to load prices from the information database
//  ModifiedField - String - field where the price was changed
//  DataCache - See InitializeDataCacheStructure
Procedure CalculatePricesByRowId(Form,
	                                         RowID,
	                                         UploadPricesFromIB = False,
	                                         ModifiedField = Undefined,
                                             DataCache = Undefined) Export
	
	Form.Modified = True;
	
	DataCache = InitializeDataCacheStructure();
	
	PriceTableRow = Form.PriceTree.FindByID(RowID);
	
	ProductsTable = CreateProductTable(Form);
	
	FillPropertyValues(ProductsTable.Add(), PriceTableRow, "Products, Characteristic");
	
	FeatureElements = PriceTableRow.GetItems();
	
	If Form.UseItemVariants And FeatureElements.Count() > 0 Then
		For Each ElementCharacteristic In FeatureElements Do
			FillPropertyValues(ProductsTable.Add(), ElementCharacteristic, "Products, Characteristic");
		EndDo;
	EndIf;
	
	If Form.CalculateAutomatically Then
		
		If UploadPricesFromIB Then
			
			ParametersStructure = New Structure();
			ParametersStructure.Insert("ArrayOfPriceTypeStrings", SettingPricesClientServer.SelectedRowsInPriceViewTable(Form));
			
			LoadBasePriceValues(
				Form,
				ProductsTable,
				DataCache,
				ParametersStructure);
			CalculatePricesBasedOnInformationSecurityData(Form, ProductsTable,,,DataCache);
			
		EndIf;
		
		CalculateCalculatedPrices(Form, ProductsTable, DataCache,,,ModifiedField);
		
	Else
		
		SetFlagForManuallyChangingCalculatedPrices(Form, ProductsTable, ModifiedField, DataCache);
		
	EndIf;
	
EndProcedure

// Calculates prices in a line by ID
//
// Parameters:
//  Form - ClientApplicationForm - 
//  RowID - Number - 
//  UploadPricesFromIB - Boolean - Indicates the need to load prices from the information database
//  ModifiedField - String - the field where the price was changed.
//  DataCache - See SettingPricesServer.InitializeDataCacheStructure
//
Procedure CalculatePricesByRowId2_5(Form,
	                                         RowID,
	                                         UploadPricesFromIB = False,
	                                         ModifiedField = Undefined,
                                             DataCache = Undefined) Export
	
	Form.Modified = True;
	
	DataCache = InitializeDataCacheStructure();
	
	PriceTableRow = Form.PriceTree.FindByID(RowID);
	
	ProductsTable = CreateProductTable(Form);
	
	FillPropertyValues(ProductsTable.Add(), PriceTableRow, "Products, PricingVariant, PricingBatch, PricingPackage");
	
	AddSubordinateElements(ProductsTable, PriceTableRow);
	
	If Form.CalculateAutomatically Then
		
		If UploadPricesFromIB Then
			
			ParametersStructure = New Structure();
			ParametersStructure.Insert("ArrayOfPriceTypeStrings", SettingPricesClientServer.SelectedRowsInPriceViewTable(Form));
			
			LoadBasePriceValues(
				Form,
				ProductsTable,
				DataCache,
				ParametersStructure);
			
			CalculatePricesBasedOnInformationSecurityData(Form, ProductsTable,,,DataCache);
			
		EndIf;
		
		CalculateCalculatedPrices(Form, ProductsTable, DataCache,,,ModifiedField);
		
	Else
		
		SetFlagForManuallyChangingCalculatedPrices(Form, ProductsTable, ModifiedField, DataCache);
		
	EndIf;
	
EndProcedure

// Calculates prices in the price table
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  CalculationParameters - Structure - Calculation parameters
//  DataCache - See InitializeDataCacheStructure
//
Procedure CalculatePrices(Form, CalculationParameters, DataCache = Undefined) Export
	
	Form.Modified = True;
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	ArrayOfPriceTypes = New Array;
	For Each PriceKind In CalculationParameters.TypesOfPrices Do
		If TypeOf(PriceKind) = Type("Structure") Then
			ArrayOfPriceTypes.Add(SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, PriceKind.PriceKind));
		Else
			ArrayOfPriceTypes.Add(SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, PriceKind));
		EndIf;
	EndDo;
	
	If Not CalculationParameters.SelectedLinesOnly Then
		
		ProductsTable = CreateTableOfProductsOnPriceTree(Form, False);
		
	Else
		
		ProductsTable = CreateProductTable(Form);
		For Each SelectedRow In Form.Items.PriceTree.SelectedRows Do
			PriceTableRow           = Form.PriceTree.FindByID(SelectedRow);
			NewRow                = ProductsTable.Add();
			FillPropertyValues(NewRow, PriceTableRow);
			If Form.UsePriceManagementSystem25 Then
				NewRow.TsoPackagingForCommunication = ?(PriceTableRow.PricingPackage = PriceTableRow.UnitOfMeasure, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), PriceTableRow.PricingPackage);
				NewRow.TSOSeriesForCommunication    = ?(PriceTableRow.PricingBatch.Predefined, Catalogs.ItemsBatchesForPricing.EmptyRef(), PriceTableRow.PricingBatch);
			EndIf;
		EndDo;
		
	EndIf;
	
	FillInNDSBidInItemTable(Form, ProductsTable, ArrayOfPriceTypes);
	
	If CalculationParameters.ImportOldPrices Then
		
		ParametersStructure = New Structure();
		ParametersStructure.Insert("ArrayOfPriceTypeStrings",  ArrayOfPriceTypes);
		ParametersStructure.Insert("DocumentDate",        CalculationParameters.OldPriceDate);
		ParametersStructure.Insert("PriceChangePercentage", CalculationParameters.PriceChangePercentage);
		ParametersStructure.Insert("ApplyRounding",  CalculationParameters.ApplyRounding);
		ParametersStructure.Insert("OnlyEmpty",  CalculationParameters.OnlyEmpty);
	
		LoadBasePriceValues(
			Form,
			ProductsTable,
			DataCache,
			ParametersStructure);
			
	EndIf;
	
	If CalculationParameters.RoundingUpManualPrices Then
		ApplyRoundingToManualPrices(Form, ProductsTable, ArrayOfPriceTypes, DataCache);
	EndIf;
	
	If CalculationParameters.CalculationByFormulas Then
		
		If Not CalculationParameters.ImportOldPrices Then 
			LoadBasePriceValues(Form, ProductsTable, DataCache);
		EndIf;

		CalculatePricesBasedOnInformationSecurityData(Form, ProductsTable, ArrayOfPriceTypes, CalculationParameters.OnlyEmpty, DataCache);
		
		CalculateCalculatedPrices(
			Form,
			ProductsTable,
			DataCache,
			?(Not CalculationParameters.ImportOldPrices, ArrayOfPriceTypes, Undefined),
			CalculationParameters.OnlyEmpty,
			,
			CalculationParameters.TypesOfPrices);
		
	EndIf;
	
	If Form.CalculateAutomatically Then

		// List of types of prices that depend on the changeable
		DependentPrices = GetSettingsLinesForDependentPriceTypes(Form, ArrayOfPriceTypes);
	
		CalculateCalculatedPrices(
			Form,
			ProductsTable,
			DataCache,
			DependentPrices,
			CalculationParameters.OnlyEmpty);
			
	EndIf;
		
	If TypeOf(Form.PriceTree) = Type("FormDataTree") And CalculationParameters.CalculationByFormulas Then
		For Each TypeOfPriceForProcessing In ArrayOfPriceTypes Do //FormDataCollectionItem
			MarkModifiedFormulas(Form,,TypeOfPriceForProcessing.Ref);
		EndDo;
	EndIf;
EndProcedure

// Calculates prices in the price table
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  CalculationParameters - Structure
//  DataCache - See InitializeDataCacheStructure
//
Procedure FillInPricesFromDocuments(Form, CalculationParameters, DataCache = Undefined) Export
	
	Form.Modified = True;
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	ArrayOfPriceTypes = New Array;
	For Each PriceKind In CalculationParameters.TypesOfPrices Do
		ArrayOfPriceTypes.Add(SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, PriceKind));
	EndDo;
	
	ProductsTable = CreateTableOfProductsOnPriceTree(Form);
	
	LoadPriceValuesFromDocuments(
			Form,
			ProductsTable,
			ArrayOfPriceTypes,
			CalculationParameters.Documents,
			DataCache);
	
EndProcedure

// Loads the base price values in the table
//
// Parameters:
// 	Form - See BuildPriceTree.Form
// 	ProductsTable - ValueTable - Table where price values will be loaded
//  ArrayOfPriceTypeStrings - Array of CatalogRef.TypesOfPrices - 
//                      - Array of CatalogRef.VendorPriceTypes - 
//  PriceSettingDocuments - Array of DocumentRef.PriceSetup - 
// 	DataCache - See InitializeDataCacheStructure
//
Procedure LoadPriceValuesFromDocuments(Form,
	                                       ProductsTable,
	                                       ArrayOfPriceTypeStrings = Undefined,
	                                       PriceSettingDocuments,
	                                       DataCache = Undefined) Export
	
	If ArrayOfPriceTypeStrings = Undefined Then
		
		ArrayOfPriceTypeStrings = New Array();
		For Each PriceKind In Form.SelectedPrices Do
			If PriceKind.Influences Then
				ArrayOfPriceTypeStrings.Add(PriceKind);
			EndIf;
		EndDo;
		
	EndIf;
	
	ClearPrices(Form, ProductsTable, ArrayOfPriceTypeStrings, DataCache);
	
	If ArrayOfPriceTypeStrings.Count() > 0 Then
		
		Query = New Query("
			|SELECT
			|	ProductsTable.Products   AS Products,
			|	ProductsTable.Characteristic AS Characteristic
			|INTO ProductsTable
			|FROM
			|	&ProductsTable AS ProductsTable
			|INDEX BY Products, Characteristic
			|;
			|SELECT
			|	Goods.Products   AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Package       AS Package,
			|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
			|	Goods.PriceKind        AS PriceKind,
			|	MAX(Goods.Price) AS Price
			|FROM
			|	Document.PriceSetup.Goods AS Goods
			|WHERE
			|	(Products, Characteristic) IN
			|					(SELECT
			|						ProductsTable.Products   AS Products,
			|						ProductsTable.Characteristic AS Characteristic
			|					FROM
			|						ProductsTable AS ProductsTable)
			|	AND PriceKind IN (&TypesOfPrices)
			|	AND Goods.Ref IN (&Documents)
			|GROUP BY
			|	Products,
			|	Characteristic,
			|	Package,
			|	PriceKind
			|");
			
		Query.Text = StrReplace(Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
		
		Query.SetParameter("ProductsTable",  ProductsTable);
		
		TypesOfPrices = New Array;
		For Each PriceTypeLine In ArrayOfPriceTypeStrings Do
			TypesOfPrices.Add(PriceTypeLine.Ref);
		EndDo;
		Query.SetParameter("TypesOfPrices",   TypesOfPrices);
		Query.SetParameter("Documents", PriceSettingDocuments);
		
		SetPrivilegedMode(True);
		
		Upload0 = Query.Execute().Unload();
		
		If Form.UseItemPackages Then
			ComplianceOfFactorsOfPackagesOfProductRange = CoefficientsOfPackagesOfProductsTreeTree(Form);
		Else
			ComplianceOfFactorsOfPackagesOfProductRange = Undefined;
		EndIf;
		
		LoadPricesFromValueTable(Form, Upload0, ComplianceOfFactorsOfPackagesOfProductRange, DataCache);
		
		SetPrivilegedMode(False);

	EndIf;
	
EndProcedure

// Calculates the base prices that are filled in according to the information base data and calculated prices.
// 
// Parameters:
// 	Form - See BuildPriceTree.Form
// 	DataCache - See InitializeDataCacheStructure
Procedure CalculateAllPrices(Form, DataCache) Export
	
	Form.Modified = True;
	
	ProductsTable = CreateTableOfProductsOnPriceTree(Form);
	
	LoadBasePriceValues(Form, ProductsTable, DataCache);
	CalculatePricesBasedOnInformationSecurityData(Form, ProductsTable,,,DataCache);
	
	CalculateCalculatedPrices(Form, ProductsTable, DataCache);
	
EndProcedure

// Calculates calculated prices
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - FormDataCollection - Table where prices are calculated
//  DataCache - See InitializeDataCacheStructure
//  TypesOfPrices - Array of CatalogRef.TypesOfPrices - 
//          - Array of CatalogRef.VendorPriceTypes -  
//  OnlyEmpty - Boolean - Indicates that previously filled prices need to be calculated
//  ModifiedField - String - Name of the changed field
//  ArrayOfFormulas - Array - Data according to the formulas
//
Procedure CalculateCalculatedPrices(Form,
									ProductsTable,
									DataCache,
									TypesOfPrices = Undefined,
									OnlyEmpty = False,
									ModifiedField = Undefined,
									ArrayOfFormulas  = Undefined) Export

	Form.Modified = True;
	
	If Form.UseItemPackages Then
		TableOfCoefficientsOfProductPackages = CoefficientsOfPackagesOfProductsTreeTree(Form,ProductsTable,DataCache);
	Else
		TableOfCoefficientsOfProductPackages = Undefined;
	EndIf;
	
	If TypesOfPrices = Undefined Then
		If ModifiedField = Undefined Then
			TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
		Else
			ModifiedPriceViewLine = SettingPricesClientServer.PriceViewStringByFieldName(Form.SelectedPrices, ModifiedField);
			If ModifiedPriceViewLine <> Undefined Then
				TypesOfPrices = DependentOnTypeOfPriceTypesOfPrices(Form, ModifiedPriceViewLine);
			Else
				TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
			EndIf;
		EndIf;
	EndIf;
	
	ExchangeRates(Form, DataCache);

	FormulasForCalculation = NewTableOfFormulasForCalculation();

	For Each ItemItemPosition In ProductsTable Do
		
		PriceTableRow = FindPriceTreeString(Form, ItemItemPosition, DataCache);
		StructurePriceGroup = New Structure("PriceGroup", PriceTableRow.PriceGroup);
		For Each PriceKind In TypesOfPrices Do
			
			If Not PriceKind.FormulaIsBeingEdited Then
				Continue;
			EndIf;

			If Not OnlyEmpty Then
				PriceTableRow[PriceKind.ColumnName] = 0;
			EndIf;
			
			If PriceTableRow["NoEditingAllowed" + PriceKind.ColumnName] Then
				Continue;
			EndIf;
			
			CurPrice = PriceTableRow[PriceKind.ColumnName];
			If CurPrice = 0 Or Not OnlyEmpty Then
				
				Formula = "";
				DefaultFormulaIs = "";
				
				If ArrayOfFormulas <> Undefined And TypeOf(ArrayOfFormulas[0]) = Type("Structure") Then
					For Each It_ In ArrayOfFormulas Do
						If It_.PriceKind = PriceKind.Ref Then
							Formula = It_.Formula;
						EndIf;
					EndDo;
				Else
					Formula = PriceTableRow["Formula" + PriceKind.ColumnName];
				EndIf;
				
				PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
				If PriceGroupsOfAlgorithms.Count() > 0 Then
					DefaultFormulaIs = PriceGroupsOfAlgorithms[0].Formula;
				Else
					DefaultFormulaIs = PriceKind.Formula;
				EndIf;
				
				ThresholdPriceGroups = PriceKind.Thresholds.FindRows(StructurePriceGroup);
				If ThresholdPriceGroups.Count() > 0 Then
					ThresholdOnPriceIncreaseFor = ThresholdPriceGroups[0].ThresholdOnPriceIncreaseFor;
					ThresholdOnPriceDecreaseBy = ThresholdPriceGroups[0].ThresholdOnPriceDecreaseBy;
				Else
					ThresholdOnPriceIncreaseFor = PriceKind.ThresholdOnPriceIncreaseFor;
					ThresholdOnPriceDecreaseBy = PriceKind.ThresholdOnPriceDecreaseBy;
				EndIf;
				
				Formula = ?(Formula = "", DefaultFormulaIs, Formula);
				FormulaPresentation = Formula;
				DefaultFormulaPresentation = DefaultFormulaIs;
				
				If Formula = "" Then
					Continue;
				EndIf;

				FillInFormulaByDefault = DefaultFormulaIs <> Formula;
				For Each BasePrice In PriceKind.InfluencingPrices Do
					
					BasePriceLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, BasePrice.Value);
					BasePriceCurrency     =  ?(ValueIsFilled(PriceTableRow["Currency" + BasePriceLine.ColumnName]), PriceTableRow["Currency" + BasePriceLine.ColumnName], BasePriceLine.Currency);
					If ValueIsFilled(PriceTableRow["Currency" + PriceKind.ColumnName]) Then
						PriceCurrency = PriceTableRow["Currency" + PriceKind.ColumnName];
					Else
						CurrencyPriceGroups = PriceKind.Currencies.FindRows(New Structure("PriceGroup", PriceTableRow.PriceGroup));
						If CurrencyPriceGroups.Count() > 0 Then
							PriceCurrency = CurrencyPriceGroups[0].Currency;
						Else
							PriceCurrency = PriceKind.Currency;
						EndIf;
						PriceTableRow["Currency" + PriceKind.ColumnName] = PriceCurrency;
					EndIf;					
					CurrencyConversionLine   = SettingPricesClientServer.CurrencyConversionLine(BasePriceCurrency, PriceCurrency, DataCache.ExchangeRates);
					If Form.UseItemPackages Then
						LineForRecalculatingPackages = SettingPricesClientServer.LineForRecalculatingPackages(PriceTableRow, BasePriceLine, PriceKind, TableOfCoefficientsOfProductPackages);
					Else
						LineForRecalculatingPackages = "";
					EndIf;
					ReplacementString = " Parameters.PriceTableRow." + BasePriceLine.ColumnName + " " + LineForRecalculatingPackages + CurrencyConversionLine;
					Formula = StrReplace(Formula, "[" + BasePriceLine.Id + "]", ReplacementString);
					
					If FillInFormulaByDefault Then
						DefaultFormulaIs = StrReplace(DefaultFormulaIs, "[" + BasePriceLine.Id + "]", ReplacementString);
					EndIf;
					
				EndDo;
				
				If FillInFormulaByDefault And FormulaPresentation = Formula Then
					Formula = DefaultFormulaIs;
					FormulaPresentation = DefaultFormulaPresentation;
				EndIf;

				NewFormulaLine = FormulasForCalculation.Add();
				NewFormulaLine.PriceTableRow = PriceTableRow;
				NewFormulaLine.PriceKind = PriceKind;
				NewFormulaLine.Formula = Formula;
				NewFormulaLine.FormulaPresentation = FormulaPresentation;
				NewFormulaLine.DefaultFormulaPresentation = DefaultFormulaPresentation;
				NewFormulaLine.ThresholdOnPriceIncreaseFor = ThresholdOnPriceIncreaseFor;
				NewFormulaLine.ThresholdOnPriceDecreaseBy = ThresholdOnPriceDecreaseBy;
			EndIf;

		EndDo;

	EndDo;

	Parameters = New Structure();
	Parameters.Insert("FormulasForCalculation", FormulasForCalculation);
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Ref") Then
		Parameters.Insert("ObjectReference", Form.Object.Ref);
	Else
		Parameters.Insert("ObjectReference", Undefined);
	EndIf;
	Common.ExecuteInSafeMode("SettingPricesServer.CalculateFormulasInSafeMode(Parameters)", Parameters);

EndProcedure

// Procedure - Calculate formulas in safe mode
// Calculates formulas line by line for the transmitted table. Called with the safe mode pre-set.
// Parameters:
//  Parameters	 - Structure - Structure of parameters with required Attributes:
//	* FormulasForCalculation - ValueTable
//	* ObjectReference    - DocumentRef, Undefined - (in case the link is missing).
//
Procedure CalculateFormulasInSafeMode(Parameters) Export

	ObjectReference = Parameters.ObjectReference;
	FormulasForCalculation = Parameters.FormulasForCalculation;

	For Each FormulaForCalculation In FormulasForCalculation Do

		PriceTableRow = FormulaForCalculation.PriceTableRow;
		PriceKind = FormulaForCalculation.PriceKind;

		Try

			Parameters = New Structure("PriceTableRow", PriceTableRow);
			PriceValue = Eval(FormulaForCalculation.Formula);
			PriceValue = SettingPricesClientServer.RoundUpPrice(PriceValue, PriceKind);
			
			If PriceTableRow["OldPrice" + PriceKind.ColumnName] <> 0 Then
				ChangePercentage = Round(100*(PriceValue - PriceTableRow["OldPrice" + PriceKind.ColumnName])/PriceTableRow["OldPrice" + PriceKind.ColumnName],5,2);
			Else
				ChangePercentage = 0;
			EndIf;
			
			If (FormulaForCalculation.ThresholdOnPriceIncreaseFor = 0 And FormulaForCalculation.ThresholdOnPriceDecreaseBy = 0) 
				Or PriceTableRow["OldPrice" + PriceKind.ColumnName] = 0
				Or ?(ChangePercentage > 0, ChangePercentage >= FormulaForCalculation.ThresholdOnPriceIncreaseFor, -ChangePercentage >= FormulaForCalculation.ThresholdOnPriceDecreaseBy) Then
				
				PriceTableRow[PriceKind.ColumnName] = PriceValue;
				If PriceTableRow["OldPrice" + PriceKind.ColumnName] <> 0 Then
					PriceTableRow["ChangePercentage" + PriceKind.ColumnName] = ChangePercentage;
				Else
					PriceTableRow["ChangePercentage" + PriceKind.ColumnName] = 0;
				EndIf;
				
			Else
				PriceTableRow[PriceKind.ColumnName] = PriceTableRow["OldPrice" + PriceKind.ColumnName];
				PriceTableRow["ChangePercentage" + PriceKind.ColumnName] = 0;
			EndIf;
			
			PriceTableRow["AmountOfChange" + PriceKind.ColumnName] = PriceTableRow[PriceKind.ColumnName] - PriceTableRow["OldPrice" + PriceKind.ColumnName];
			PriceTableRow["Formula" + PriceKind.ColumnName] = FormulaForCalculation.FormulaPresentation;
			
			PriceTableRow["FormulaChangedManually" + PriceKind.ColumnName] = (FormulaForCalculation.FormulaPresentation <> FormulaForCalculation.DefaultFormulaPresentation);
			PriceTableRow["ChangedManually"        + PriceKind.ColumnName] = False;
			PriceTableRow["ChangedAutomatically"  + PriceKind.ColumnName] = True;
			
		Except
			
			If ValueIsFilled(PriceTableRow.Characteristic) Then
				MessageText = NStr("vi = 'Đối với mặt hàng ""%Products%"" có đặc tính ""%Characteristic%"" chưa tính đơn giá theo dạng giá ""%PriceKind%"" do nguyên nhân: %ErrorDescription%. Hãy kiểm tra chính xác công thức.';
									|ru = 'Для номенклатуры ""%Products%"" с характеристикой ""%Characteristic%"" не рассчитана цена по виду цен ""%PriceKind%"" по причине: %ErrorDescription%. Проверьте корректность формулы.';
									|en = 'The price is not calculated for the ""%Characteristic%"" variant of the ""%Products%"" item by the ""%PriceKind%"" price type. Reason: %ErrorDescription%. Check whether the formula is correct.'; fa = 'The price is not calculated for the ""%Characteristic%"" variant of the ""%Products%"" item by the ""%PriceKind%"" price type. Reason: %ErrorDescription%. Check whether the formula is correct.';
									|it = 'Для номенклатуры ""%Products%"" с характеристикой ""%Characteristic%"" не рассчитана цена по виду цен ""%PriceKind%"" по причине: %ErrorDescription%. Проверьте корректность формулы.';
									|pl = 'The price is not calculated for the ""%Characteristic%"" variant of the ""%Products%"" item by the ""%PriceKind%"" price type. Reason: %ErrorDescription%. Check whether the formula is correct.';
									|tr = '""%Characteristic%"" özelliğine sahip ""%Products%"" öğesi için ""%PriceKind%"" fiyat türü kapsamındaki fiyatı şu nedenle hesaplanamadı: %ErrorDescription%. Formülün doğruluğunu kontrol edin.'");
			Else
				MessageText = NStr("vi = 'Đối với mặt hàng ""%Products%"" chưa tính đơn giá theo dạng giá ""%PriceKind%"" do nguyên nhân: %ErrorDescription%. Hãy kiểm tra chính xác công thức.';
									|ru = 'Для номенклатуры ""%Products%"" не рассчитана цена по виду цен ""%PriceKind%"" по причине: %ErrorDescription%. Проверьте корректность формулы.';
									|en = 'The price is not calculated for the ""%Products%"" item by the ""%PriceKind%"" price type. Reason: %ErrorDescription%. Check whether the formula is correct.'; fa = 'The price is not calculated for the ""%Products%"" item by the ""%PriceKind%"" price type. Reason: %ErrorDescription%. Check whether the formula is correct.';
									|it = 'Для номенклатуры ""%Products%"" не рассчитана цена по виду цен ""%PriceKind%"" по причине: %ErrorDescription%. Проверьте корректность формулы.';
									|pl = 'The price is not calculated for the ""%Products%"" item by the ""%PriceKind%"" price type. Reason: %ErrorDescription%. Check whether the formula is correct.';
									|tr = '""%Products%"" öğesi için ""%PriceKind%"" fiyat türü kapsamındaki fiyatı şu nedenle hesaplanamadı: %ErrorDescription%. Formülün doğruluğunu kontrol edin.'");
			EndIf;
			
			MessageText = StrReplace(MessageText, "%PriceKind%"       , PriceKind.Ref);
			MessageText = StrReplace(MessageText, "%Products%"  , PriceTableRow.Products);
			MessageText = StrReplace(MessageText, "%Characteristic%", PriceTableRow.Characteristic);
			MessageText = StrReplace(MessageText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			If ObjectReference <> Undefined Then
				CommonClientServer.MessageToUser(
					MessageText,
					ObjectReference,
					"PriceTree");
			Else
				CommonClientServer.MessageToUser(
					MessageText,
					,
					"PriceTree");
			EndIf;
			
		EndTry;

	EndDo;

EndProcedure

// Computes of the price calculated according to the information base
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - ValueTable - Table where you need to fill in prices
//  ArrayOfPriceTypeStrings - Array of CatalogRef.TypesOfPrices - 
//                      - Array of CatalogRef.VendorPriceTypes -  
//  OnlyEmpty - Boolean - Indicates that only unfilled prices should be calculated.
//  DataCache - See InitializeDataCacheStructure
//
Procedure CalculatePricesBasedOnInformationSecurityData(Form,
	                              ProductsTable,
	                              ArrayOfPriceTypeStrings = Undefined,
	                              OnlyEmpty = False,
	                              DataCache) Export
	
	Form.Modified = True;
	
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	If ArrayOfPriceTypeStrings = Undefined Then
		
		TypesOfPricesAccordingToInformationSecurityData = New Array();
		For Each PriceTypeLine In Form.SelectedPrices Do
			If PriceTypeLine.Selected_5 
				And PriceTypeLine.Edit
				And (PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost) Then
				TypesOfPricesAccordingToInformationSecurityData.Add(PriceTypeLine);
			EndIf;
		EndDo;
		
	Else
		
		TypesOfPricesAccordingToInformationSecurityData = New Array(); // Array of CatalogRef.TypesOfPrices, CatalogRef.VendorPriceTypes
		For Each PriceTypeLine In ArrayOfPriceTypeStrings Do
			
			FoundRow = Undefined;
			For Each CurRow In Form.SelectedPrices Do
				FoundRow = CurRow;
				If CurRow.Ref = PriceTypeLine.Ref Then
					Break;
				EndIf;
			EndDo;
			
			If FoundRow <> Undefined Then
				If FoundRow.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
					Or FoundRow.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt
					Or FoundRow.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
					Or FoundRow.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors
					Or FoundRow.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors
					Or FoundRow.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
					TypesOfPricesAccordingToInformationSecurityData.Add(PriceTypeLine);
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Not OnlyEmpty Then
		ClearPrices(Form, ProductsTable, TypesOfPricesAccordingToInformationSecurityData, DataCache);
	EndIf;
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
	
		DataLayoutSettingsTable = GetFromTempStorage(Form.StorageAddressDataLayoutSettings);		
	
	ElsIf TypeOf(Form) = Type("Structure") Then
	
		DataLayoutSettingsTable = Form.DataLayoutSettingsTable;
	
	EndIf; 
		
	For Each TypeOfPriceAccordingToInformationSecurity In TypesOfPricesAccordingToInformationSecurityData Do
		FoundRow = DataLayoutSettingsTable.Find(TypeOfPriceAccordingToInformationSecurity.Ref);
		If UsePriceManagementSystem25 Then
			CalculatePriceValuesBasedOnInformationSecurityData2_5(Form, ProductsTable, TypeOfPriceAccordingToInformationSecurity, OnlyEmpty, ?(FoundRow <> Undefined,FoundRow.DataCompositionSettings,Undefined), DataCache);
		Else
			CalculatePriceValuesBasedOnInformationSecurityData(Form, ProductsTable, TypeOfPriceAccordingToInformationSecurity, OnlyEmpty, ?(FoundRow <> Undefined,FoundRow.DataCompositionSettings,Undefined), DataCache);
		EndIf;
	EndDo;
	
EndProcedure

// Removes items without changed prices from the price tree
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ByChangesPerDay - Boolean
//
Procedure DeleteProductsWithoutChangedPrices(Form, ByChangesPerDay = False) Export
	
	TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
	
	ItemsToDeleteProducts = New Array;
	FeatureElementsToDelete = New Array;
	
	SelectionOfProducts_ = Form.PriceTree.GetItems();
	For Each ProductItem In SelectionOfProducts_ Do
		
		FeatureElementsToDelete.Clear();
		
		SampleCharacteristics = ProductItem.GetItems();
		For Each ElementCharacteristic In SampleCharacteristics Do
			
			TheCostOfTheChanged = ThereArePriceChangesInLine(ElementCharacteristic, TypesOfPrices, ByChangesPerDay);
			If Not TheCostOfTheChanged Then
				FeatureElementsToDelete.Add(ElementCharacteristic);
			EndIf;
			
		EndDo;
		
		For Each ElementCharacteristic In FeatureElementsToDelete Do
			SampleCharacteristics.Delete(ElementCharacteristic);
		EndDo;
		
		TheCostOfTheChanged = ThereArePriceChangesInLine(ProductItem, TypesOfPrices, ByChangesPerDay);
		If Not TheCostOfTheChanged And SampleCharacteristics.Count() = 0 Then
			ItemsToDeleteProducts.Add(ProductItem);
		EndIf;
		
	EndDo;
	
	For Each ProductItem In ItemsToDeleteProducts Do
		SelectionOfProducts_.Delete(ProductItem);
	EndDo;
	
	MarkModifiedFormulas(Form);
	
EndProcedure

// Changes prices by percentage
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  CalculationParameters - Structure - Structure of calculation parameters
//  DataCache - See InitializeDataCacheStructure
//
Procedure ChangePricesByPercentage_2(Form, CalculationParameters, DataCache = Undefined) Export
	
	Form.Modified = True;
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	ProductsTable = CreateProductTable(Form);
	
	Parameters = New Structure();
	Parameters.Insert("Operation", 							"ChangePricesByPercentage_2");
	Parameters.Insert("PriceTreeIsDataTreeOfForm", 	(TypeOf(Form.PriceTree) = Type("FormDataTree")));
	Parameters.Insert("UsePriceManagementSystem25", 	Form.UsePriceManagementSystem25);
	Parameters.Insert("AddAllLines", 				False);
	Parameters.Insert("ChangeInRelationToOldPrice", 	CalculationParameters.ChangeInRelationToOldPrice);
	Parameters.Insert("TypesOfPrices", 							CalculationParameters.TypesOfPrices);
	
	If Not CalculationParameters.SelectedLinesOnly Then
		
		ApplyChangesToTree(Parameters, Form.PriceTree, ProductsTable,,DataCache);
		
	Else
		
		For Each SelectedRow In Form.Items.PriceTree.SelectedRows Do
			
			PriceTableRow = Form.PriceTree.FindByID(SelectedRow);
			
			ApplyChangesToTree(Parameters, PriceTableRow, ProductsTable,,DataCache);
			
		EndDo;
		
	EndIf;
	
	TypesOfPrices = New Array;
	For Each ArrayRow In CalculationParameters.TypesOfPrices Do
		TypesOfPrices.Add(SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, ArrayRow.PriceKind));
	EndDo;	
	
	If CalculationParameters.ApplyRounding Then
		ApplyRoundingToManualPrices(Form, ProductsTable, TypesOfPrices, DataCache);
	EndIf;
	
	// List of types of prices that depend on the changeable
	DependentPrices = GetSettingsLinesForDependentPriceTypes(Form, TypesOfPrices);
	
	If Form.CalculateAutomatically Then
		CalculateCalculatedPrices(Form, ProductsTable, DataCache, DependentPrices, False);
	Else
		SetManualChangeFlagForPriceTypes(Form, ProductsTable, DependentPrices, DataCache);
	EndIf;
	
EndProcedure

// Sets the specified prices for the selected lines 
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  CalculationParameters - Structure - Structure of calculation parameters
//  DataCache - See InitializeDataCacheStructure
//
Procedure ChangePrices(Form, CalculationParameters, DataCache = Undefined) Export
	
	Form.Modified = True;
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	ProductsTable = CreateProductTable(Form);
	
	Parameters = New Structure();
	Parameters.Insert("Operation", 							"ChangePrices");
	Parameters.Insert("PriceTreeIsDataTreeOfForm", 	(TypeOf(Form.PriceTree) = Type("FormDataTree")));
	Parameters.Insert("UsePriceManagementSystem25", 	Form.UsePriceManagementSystem25);
	Parameters.Insert("AddAllLines", 				False);
	Parameters.Insert("ChangeInRelationToOldPrice", 	CalculationParameters.ChangeInRelationToOldPrice);
	Parameters.Insert("TypesOfPrices", 							CalculationParameters.TypesOfPrices);
	
	If Not CalculationParameters.SelectedLinesOnly Then
		
		ApplyChangesToTree(Parameters, Form.PriceTree, ProductsTable,,DataCache);
		
	Else
		
		For Each SelectedRow In Form.Items.PriceTree.SelectedRows Do
			
			PriceTableRow = Form.PriceTree.FindByID(SelectedRow);
			
			ApplyChangesToTree(Parameters, PriceTableRow, ProductsTable,,DataCache);
			
		EndDo;
		
	EndIf;
	
	TypesOfPrices = New Array;
	For Each ArrayRow In CalculationParameters.TypesOfPrices Do
		TypesOfPrices.Add(SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, ArrayRow.PriceKind));
	EndDo;
	
	// List of types of prices that depend on the changeable
	DependentPrices = GetSettingsLinesForDependentPriceTypes(Form, TypesOfPrices);
	
	If Form.CalculateAutomatically Then
		CalculateCalculatedPrices(Form, ProductsTable, DataCache, DependentPrices, False);
	Else
		SetManualChangeFlagForPriceTypes(Form, ProductsTable, DependentPrices, DataCache);
	EndIf;
	
EndProcedure

// Re-download the base prices in the price schedule
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCache - See InitializeDataCacheStructure
// 
Procedure DownloadBasePrices(Form, DataCache) Export
	
	ProductsTable = CreateTableOfProductsOnPriceTree(Form);
	LoadBasePriceValues(Form, ProductsTable, DataCache);
	
EndProcedure

// Loads the base price values in the table
//
// Parameters:
//  Form - See BuildPriceTree.Form
// 	ProductsTable - ValueTable - Table where price values will be loaded
// 	DataCache - See InitializeDataCacheStructure
// 	AdditionalParameters - Structure - Contains:
// 	* ArrayOfPriceTypeStrings - Array of CatalogRef.TypesOfPrices - Array of price types
//                        - Array of CatalogRef.VendorPriceTypes -  
// 	* DocumentDate - Date - Price upload date
// 	* PriceChangePercentage - Number - The percentage by which you want to change the price
// 	* ApplyRounding - Boolean - Indicates that rounding should be applied.
//
Procedure LoadBasePriceValues(Form,
	                                  ProductsTable,
	                                  DataCache,
	                                  AdditionalParameters = Undefined) Export
	
	ParametersStructure = New Structure(); // See LoadBasePriceValues.AdditionalParameters
	ParametersStructure.Insert("ArrayOfPriceTypeStrings",  Undefined);
	ParametersStructure.Insert("DocumentDate",        Undefined);
	ParametersStructure.Insert("PriceChangePercentage", 0);
	ParametersStructure.Insert("ApplyRounding",  False);
	ParametersStructure.Insert("OnlyEmpty",  False);
	
	If AdditionalParameters <> Undefined Then
		FillPropertyValues(ParametersStructure , AdditionalParameters);
	EndIf;
	
	If ParametersStructure.ArrayOfPriceTypeStrings = Undefined Then
		
		ParametersStructure.ArrayOfPriceTypeStrings = New Array(); // Array of CatalogRef.TypesOfPrices, CatalogRef.VendorPriceTypes -
		For Each PriceKind In Form.SelectedPrices Do
			If PriceKind.Influences Then
				ParametersStructure.ArrayOfPriceTypeStrings.Add(PriceKind);
			EndIf;
		EndDo;
		
	EndIf;
	
	If ParametersStructure.ArrayOfPriceTypeStrings.Count() > 0 Then
		
		If Not ParametersStructure.OnlyEmpty Then
			ClearPrices(Form, ProductsTable, ParametersStructure.ArrayOfPriceTypeStrings, DataCache);
		EndIf;
	
		If Form.UsePriceManagementSystem25 Then
			Query = New Query("SELECT
			|	ProductsTable.Products AS Products,
			|	ProductsTable.PricingVariant AS PricingVariant,
			|	ProductsTable.PricingBatch AS PricingBatch,
			|	ProductsTable.TSOSeriesForCommunication AS TSOSeriesForCommunication,
			|	ProductsTable.PricingPackage AS PricingPackage,
			|	ProductsTable.TsoPackagingForCommunication AS TsoPackagingForCommunication
			|INTO ProductsTable
			|FROM
			|	&ProductsTable AS ProductsTable
			|
			|INDEX BY
			|	Products,
			|	PricingVariant,
			|	TSOSeriesForCommunication,
			|	TsoPackagingForCommunication
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	ItemPricesCrossSectionOfTheLatest.Products AS Products,
			|	ItemPricesCrossSectionOfTheLatest.PricingVariant AS PricingVariant,
			|	ProductsTable.PricingBatch AS PricingBatch,
			|	ProductsTable.PricingPackage AS PricingPackage,
			|	ItemPricesCrossSectionOfTheLatest.Package AS Package,
			|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
			|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
			|	ItemPricesCrossSectionOfTheLatest.Price + ItemPricesCrossSectionOfTheLatest.Price * &PriceChangePercentage / 100.00 AS Price,
			|	ItemPricesCrossSectionOfTheLatest.Currency AS Currency
			|FROM
			|	InformationRegister.ItemsPrices25.SliceLast(&DocumentDate, (Products, PricingVariant, PricingBatch,
			|		PricingPackage) IN
			|		(SELECT
			|			ProductsTable.Products AS Products,
			|			ProductsTable.PricingVariant AS PricingVariant,
			|			ProductsTable.TSOSeriesForCommunication AS TSOSeriesForCommunication,
			|			ProductsTable.TsoPackagingForCommunication AS TsoPackagingForCommunication
			|		FROM
			|			ProductsTable AS ProductsTable)
			|	AND PriceKind IN (&TypesOfPrices)) AS ItemPricesCrossSectionOfTheLatest
			|		LEFT JOIN ProductsTable AS ProductsTable
			|		ON ItemPricesCrossSectionOfTheLatest.Products = ProductsTable.Products
			|		AND ItemPricesCrossSectionOfTheLatest.PricingVariant = ProductsTable.PricingVariant
			|		AND ItemPricesCrossSectionOfTheLatest.PricingBatch = ProductsTable.TSOSeriesForCommunication
			|		AND ItemPricesCrossSectionOfTheLatest.PricingPackage = ProductsTable.TsoPackagingForCommunication");
		
		Else	
		
			Query = New Query("
				|SELECT
				|	ProductsTable.Products   AS Products,
				|	ProductsTable.Characteristic AS Characteristic
				|INTO ProductsTable
				|FROM
				|	&ProductsTable AS ProductsTable
				|INDEX BY Products, Characteristic
				|;
				|SELECT ALLOWED
				|	ItemPricesCrossSectionOfTheLatest.Products    AS Products,
				|	ItemPricesCrossSectionOfTheLatest.Characteristic  AS Characteristic,
				|	ItemPricesCrossSectionOfTheLatest.Package        AS Package,
				|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
				|	ItemPricesCrossSectionOfTheLatest.PriceKind         AS PriceKind,
				|	ItemPricesCrossSectionOfTheLatest.Price + ItemPricesCrossSectionOfTheLatest.Price * &PriceChangePercentage / 100.00 AS Price,
				|	ItemPricesCrossSectionOfTheLatest.Currency AS Currency
				|FROM
				|	InformationRegister.ItemsPrices.SliceLast(
				|			&DocumentDate,
				|			(Products, Characteristic) IN
				|					(SELECT
				|						ProductsTable.Products   AS Products,
				|						ProductsTable.Characteristic AS Characteristic
				|					FROM
				|						ProductsTable AS ProductsTable)
				|				AND PriceKind IN (&TypesOfPrices)) AS ItemPricesCrossSectionOfTheLatest");
			
		EndIf;
			
		Query.Text = StrReplace(Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
		
		Query.SetParameter("ProductsTable", ProductsTable);
		
		TypesOfPrices = New Array;
		For Each PriceTypeLine In ParametersStructure.ArrayOfPriceTypeStrings Do
			TypesOfPrices.Add(PriceTypeLine["Ref"]);
		EndDo;
		Query.SetParameter("TypesOfPrices",              TypesOfPrices);
		Query.SetParameter("PriceChangePercentage", ParametersStructure.PriceChangePercentage);
		Query.SetParameter("DocumentDate",        ?(ParametersStructure.DocumentDate = Undefined, DateForRequestingProductPrices(Form), ParametersStructure.DocumentDate));
		
		SetPrivilegedMode(True);
		
		Upload0 = Query.Execute().Unload();
		
		If Form.UseItemPackages Then
			ComplianceOfFactorsOfPackagesOfProductRange = CoefficientsOfPackagesOfProductsTreeTree(Form,ProductsTable,DataCache);
		Else
			ComplianceOfFactorsOfPackagesOfProductRange = Undefined;
		EndIf;
		
		Parameters = New Structure();
		Parameters.Insert("ApplyRounding_", ParametersStructure.ApplyRounding);
		Parameters.Insert("OnlyEmpty", ParametersStructure.OnlyEmpty);
		
		LoadPricesFromValueTable(Form, Upload0, ComplianceOfFactorsOfPackagesOfProductRange, DataCache,,Parameters);
		
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

// Updates the old item prices in the price tree
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCache - See InitializeDataCacheStructure
//  ProductsTable - ValueTable, Undefined - Data on added rows
//
Procedure UpdateOldProductPrices(Form, DataCache = Undefined, ProductsTable = Undefined) Export
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	If Form.SelectedPricesWereChanged Then
		
		Data = New Structure;
		Data.Insert("Form", Form);
		Data.Insert("Documents", New Array);
		Data.Insert("SaveBasic", False);
		Data.Documents.Add(Form.Object);
		
		PutPricesInTablePart(Data);
		
		BuildPriceTree(Form);
		
		DataCache.Insert("TableOfCorrespondenceOfProductsToRowsInProductTree", Undefined);
		Form.AddressOfDataCacheStorage = "";
		
		LoadTablePart(Form, DataCache);
	EndIf;
	
	ValueTable = GoodsTable(Form, DataCache, ,ProductsTable);
	
	LoadOldPricesOfProducts(Form, ValueTable, DataCache);
	
EndProcedure

// Gets a table of products (Nomenclature, Characteristics, view Prices, Packaging, Price) from the price tree.
//
// Parameters:
//  TableOfGoods - See CreateProductsTable
//
// Returns:
//  ValueTable - Expanded product table
//
Function AddProductsToTable(TableOfGoods) Export
	
	Query = New Query;
	Query.SetParameter("Goods", TableOfGoods);

	QueryText =
	"SELECT
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	CAST(Goods.PricingVariant AS Catalog.ItemsCharacteristicsForPricing) AS PricingVariant,
	|	CAST(Goods.PricingBatch AS Catalog.ItemsBatchesForPricing) AS PricingBatch,
	|	CAST(Goods.PricingPackage AS Catalog.PackagesAndUnitsOfMeasure) AS PricingPackage,
	|	Goods.Package AS Package,
	|	Goods.Price AS Price,
	|	Goods.PriceKind AS PriceKind
	|INTO DataTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.Products AS Products,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByItemVariant,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByPackage,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END AS ItemVariantsOwner
	|INTO ProductsTable
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON DataTable.Products.ProductKind = ItemKinds.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON DataTable.Products = CatProducts_.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.Products AS Products,
	|	ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
	|	DataTable.PricingVariant AS PricingVariant,
	|	DataTable.PricingBatch AS PricingBatch,
	|	DataTable.PricingPackage AS PricingPackage,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	DataTable.Package AS Package,
	|	DataTable.Price AS Price,
	|	DataTable.PriceKind AS PriceKind,
	|	ProductsTable.ByPackage AS ByPackage,
	|	ProductsTable.ByItemVariant AS ByItemVariant,
	|	ProductsTable.ByBatch AS ByBatch
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN ProductsTable AS ProductsTable
	|		ON DataTable.Products = ProductsTable.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON ProductsTable.ByItemVariant
	|		AND DataTable.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
	|		AND DataTable.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|		ON NOT ProductsTable.ByItemVariant
	|		AND ProductsTable.ItemVariantsOwner = ItemsCharacteristics1.Owner
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON ProductsTable.ByBatch
	|		AND DataTable.PricingBatch = ItemsBatches.ItemsBatchForPricing
	|		AND DataTable.PricingBatch <> VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|
	|ORDER BY
	|	DataTable.Products,
	|	PricingVariant,
	|	Characteristic,
	|	PricingBatch,
	|	PricingPackage";
		
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	TableOfGoodsSupplemented = Query.Execute().Unload();
	SetPrivilegedMode(False);

	Return TableOfGoodsSupplemented;
	
EndFunction

// Gets a table of products (Nomenclature, Characteristics, view Prices, Packaging, Price) from the price tree.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCache - See InitializeDataCacheStructure
//  Parameters - Structure - additional parameters:
//  * OnlyChangedItems - Boolean - only at changed prices.
//  * ByChangesPerDay - Boolean - at the changed prices for the day.
//  ProductsTable - ValueTable, Undefined - data on imported goods
//
// Returns:
//  See CreateProductsTable
//
Function GoodsTable(Form, DataCache = Undefined, Parameters = Undefined, ProductsTable = Undefined) Export
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	If DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree = Undefined Then
		ComplianceTable(Form, DataCache);
	EndIf;
	
	If Parameters = Undefined Then
		OnlyChangedItems = False;
		ByChangesPerDay = False;
	Else
		OnlyChangedItems = Parameters.OnlyChangedItems;
		ByChangesPerDay = Parameters.ByChangesPerDay;
	EndIf;
	
	HierarchicalList = True;
	If TypeOf(Form.PriceTree) = Type("FormDataCollection") Then
		HierarchicalList = False;
	Else
		PriceTreeIsDataTreeOfForm = (TypeOf(Form.PriceTree) = Type("FormDataTree"));
	EndIf;	
	
	// Loading old prices and percentage changes
	ValueTable = CreateProductsTable(ThisIsVendorPriceRegistration(Form, DataCache), Form.UsePriceManagementSystem25);
	ValueTable.Columns.Add("PriceIsChangedManually");
	
	SelectedPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
	SelectedAndInfluencingPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form, True);
	
	If ProductsTable = Undefined Then
		DataTable = DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree;
	Else
		DataTable = ProductsTable;
	EndIf;
	
	For Each SpecificationRow In DataTable Do

		PriceTreeString = SpecificationRow.PriceTreeString;

		If HierarchicalList Then
			If PriceTreeIsDataTreeOfForm And TypeOf(PriceTreeString) = Type("FormDataTreeItem") Then
				ThereAreSubLines = (PriceTreeString.GetItems().Count() > 0);
			ElsIf TypeOf(PriceTreeString) = Type("ValueTreeRow") Then
				ThereAreSubLines = (PriceTreeString.Rows.Count() > 0);
			Else
				ThereAreSubLines = False;
			EndIf;
			
			If ThereAreSubLines Then
				Continue;
			EndIf;
		EndIf;
		
		If OnlyChangedItems Then
			If Not ThereArePriceChangesInLine(PriceTreeString, SelectedPrices, ByChangesPerDay) Then
				Continue;
			EndIf;
		EndIf;
		
		For Each PriceTypeLine In SelectedAndInfluencingPrices Do
			
			ColumnName = PriceTypeLine.ColumnName;
			ColumnNamePackaging = "Package" + PriceTypeLine.ColumnName;
			ColumnNameOrderPackaging = "OrderPackage" + PriceTypeLine.ColumnName;
			ColumnNamePackagingName = "PackagingName" + PriceTypeLine.ColumnName;
			ColumnNameMinimumDeliveryLot = "MinimumDeliveryLot" +  PriceTypeLine.ColumnName;
			NameOfSettingConditionsColumn = "SettingConditions" +  PriceTypeLine.ColumnName;
			
			NewRow = ValueTable.Add();
			FillPropertyValues(NewRow, PriceTreeString);
			If Form.UsePriceManagementSystem25 Then
				NewRow.TsoPackagingForCommunication   = ?(PriceTreeString.PricingPackage = PriceTreeString.UnitOfMeasure, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), PriceTreeString.PricingPackage);
				NewRow.TSOSeriesForCommunication   = ?(PriceTreeString.PricingBatch.Predefined, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), PriceTreeString.PricingBatch);
			EndIf;	
			NewRow.PriceKind        = PriceTypeLine.Ref;
			NewRow.Price           = PriceTreeString[ColumnName];
			If Form.UseItemPackages And Not ValueIsFilled(NewRow.Package) Then
				NewRow.Package   = PriceTreeString[ColumnNamePackaging];
				If ThisIsVendorPriceRegistration(Form) Then
					NewRow.OrderPackage        = PriceTreeString[ColumnNameOrderPackaging];
					If PriceTreeString.Property(ColumnNamePackagingName) Then
						NewRow.PackagingName        = PriceTreeString[ColumnNamePackagingName];
					EndIf;
				EndIf;
			EndIf;
			If ThisIsVendorPriceRegistration(Form) Then
				NewRow.MinimumDeliveryLot = PriceTreeString[ColumnNameMinimumDeliveryLot];
				NewRow.SettingConditions          = PriceTreeString[NameOfSettingConditionsColumn];
			EndIf;
			NewRow.PriceIsChangedManually = PriceTreeString["ChangedManually" + ColumnName];
			
		EndDo;
		
	EndDo;
	
	Return ValueTable;
	
EndFunction

// Re-download old prices for table rows
// 
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - See CreateProductsTable
//  DataCache - See InitializeDataCacheStructure
//  TableOfProductsThatCannotBeEdited - ValueTable - Table of prohibited nomenlature editing
//
Procedure LoadOldPricesOfCompanyProducts(Form, ProductsTable, DataCache, TableOfProductsThatCannotBeEdited = Undefined) Export

	If ProductsTable.Count() = 0 Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	TemporaryTableOfGoods_.Price AS Price,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	TemporaryTableOfGoods_.Currency AS CurrencyOfChange
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&Goods AS TemporaryTableOfGoods_
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsThatAreNotAllowedToBeEdited.Products AS Products,
	|	GoodsThatAreNotAllowedToBeEdited.Characteristic AS Characteristic,
	|	GoodsThatAreNotAllowedToBeEdited.PriceKind AS PriceKind
	|INTO TemporaryTableProductsNotAllowedForEditing
	|FROM
	|	&ProductsThatCannotBeEdited AS GoodsThatAreNotAllowedToBeEdited
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	TemporaryTableOfGoods_.Price AS Price,
	|	CASE
	|		WHEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = TemporaryTableOfGoods_.Package
	|			THEN ISNULL(ItemsPrices.Price, 0)
	|		ELSE ISNULL(ItemsPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS EffectivePrice,
	|	CAST(CASE
	|			WHEN ISNULL(ItemsPrices.Price, 0) <> 0
	|				THEN 100 * (TemporaryTableOfGoods_.Price - CASE
	|						WHEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = TemporaryTableOfGoods_.Package
	|							THEN ISNULL(ItemsPrices.Price, 0)
	|						ELSE ISNULL(ItemsPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END) / CASE
	|						WHEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = TemporaryTableOfGoods_.Package
	|							THEN ISNULL(ItemsPrices.Price, 0)
	|						ELSE ISNULL(ItemsPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END
	|			ELSE 0
	|		END AS NUMBER(25, 2)) AS Percent,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	TemporaryTableOfGoods_.CurrencyOfChange AS CurrencyOfChange,
	|	ItemsPrices.Currency AS ActiveCurrency,
	|	NOT TemporaryTableProductsNotAllowedForEditing.Products IS NULL AS NoEditingAllowed
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				&DocumentDate,
	|				(Products, Characteristic, PriceKind) IN
	|					(SELECT
	|						T.Products,
	|						T.Characteristic,
	|						T.PriceKind
	|					FROM
	|						TemporaryTableOfGoods_ AS T)) AS ItemsPrices
	|		ON (ItemsPrices.Products = TemporaryTableOfGoods_.Products)
	|			AND (ItemsPrices.Characteristic = TemporaryTableOfGoods_.Characteristic)
	|			AND (ItemsPrices.PriceKind = TemporaryTableOfGoods_.PriceKind)
	|		LEFT JOIN TemporaryTableProductsNotAllowedForEditing AS TemporaryTableProductsNotAllowedForEditing
	|		ON (TemporaryTableProductsNotAllowedForEditing.Products = TemporaryTableOfGoods_.Products)
	|			AND (TemporaryTableProductsNotAllowedForEditing.Characteristic = TemporaryTableOfGoods_.Characteristic)
	|			AND (TemporaryTableProductsNotAllowedForEditing.PriceKind = TemporaryTableOfGoods_.PriceKind)
	|TOTALS BY
	|	Products,
	|	Characteristic";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
	Query.SetParameter("Goods",        ProductsTable);

	If TableOfProductsThatCannotBeEdited = Undefined Then
		TableOfProductsThatCannotBeEdited = New ValueTable();
		TableOfProductsThatCannotBeEdited.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		TableOfProductsThatCannotBeEdited.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));		
	EndIf;	
	Query.SetParameter("ProductsThatCannotBeEdited", TableOfProductsThatCannotBeEdited);
	
	If SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode) Then
		Query.SetParameter("DocumentDate", BegOfDay(Form.Date) - 1);
	Else
		Query.SetParameter("DocumentDate", DateForRequestingProductPrices(Form));
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionOfProducts.Next() Do
		
		FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While FeatureSelection_.Next() Do
			
			If ValueIsFilled(FeatureSelection_.Characteristic) Then
				
				ElementCharacteristic = FindPriceTreeString(Form, FeatureSelection_, DataCache);
		
				SamplingTypesOfPrices = FeatureSelection_.Select(QueryResultIteration.ByGroups);
				While SamplingTypesOfPrices.Next() Do
					
					If Not ValueIsFilled(SamplingTypesOfPrices.PriceKind) Then
						Continue;
					EndIf;
					
					ColumnName = ColumnNameByPriceType(SamplingTypesOfPrices.PriceKind, DataCache);
					
					If Not SamplingTypesOfPrices.CurrencyOfChange.IsEmpty() And SamplingTypesOfPrices.CurrencyOfChange <> SamplingTypesOfPrices.ActiveCurrency Then
						
						EffectivePrice = RecalculateCurrency(SamplingTypesOfPrices.ActiveCurrency, 
															SamplingTypesOfPrices.CurrencyOfChange, 
															SamplingTypesOfPrices.EffectivePrice, 
															DataCache.ExchangeRates);
					Else
						EffectivePrice = SamplingTypesOfPrices.EffectivePrice;
						ElementCharacteristic["Currency" + ColumnName] = SamplingTypesOfPrices.ActiveCurrency;
					EndIf;
					
					ElementCharacteristic["OldPrice"       + ColumnName] = EffectivePrice;
					ElementCharacteristic["ChangePercentage" + ColumnName] = SamplingTypesOfPrices.Percent;
					ElementCharacteristic["NoEditingAllowed" + ColumnName] = SamplingTypesOfPrices.NoEditingAllowed;
					
					If SamplingTypesOfPrices.NoEditingAllowed And EffectivePrice <> 0 Then
						ElementCharacteristic["ChangedAutomatically" + ColumnName] = True;
					EndIf;
					
				EndDo;
				
			Else
				
				ProductItem = FindPriceTreeString(Form, FeatureSelection_, DataCache);
				
				SamplingTypesOfPrices = FeatureSelection_.Select(QueryResultIteration.ByGroups);
				While SamplingTypesOfPrices.Next() Do
					
					If Not ValueIsFilled(SamplingTypesOfPrices.PriceKind) Then
						Continue;
					EndIf;
					
					ColumnName = ColumnNameByPriceType(SamplingTypesOfPrices.PriceKind, DataCache);
					
					If Not SamplingTypesOfPrices.CurrencyOfChange.IsEmpty() And SamplingTypesOfPrices.CurrencyOfChange <> SamplingTypesOfPrices.ActiveCurrency Then
						
						EffectivePrice = RecalculateCurrency(SamplingTypesOfPrices.ActiveCurrency, 
															SamplingTypesOfPrices.CurrencyOfChange, 
															SamplingTypesOfPrices.EffectivePrice, 
															DataCache.ExchangeRates);
					Else
						EffectivePrice = SamplingTypesOfPrices.EffectivePrice;
						ProductItem["Currency" + ColumnName] = SamplingTypesOfPrices.ActiveCurrency;
					EndIf;
					
					ProductItem["OldPrice"       + ColumnName] = EffectivePrice;
					ProductItem["ChangePercentage" + ColumnName] = SamplingTypesOfPrices.Percent;
					ProductItem["NoEditingAllowed" + ColumnName] = SamplingTypesOfPrices.NoEditingAllowed;
					
					If SamplingTypesOfPrices.NoEditingAllowed And SamplingTypesOfPrices.EffectivePrice <> 0 Then
						ProductItem["ChangedAutomatically" + ColumnName] = True;
					EndIf;

				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Re-download old prices for table rows
//
Procedure LoadOldPricesOfCompanyProducts2_5(Form, ProductsTable, DataCache, TableOfProductsThatCannotBeEdited = Undefined) Export

	If ProductsTable.Count() = 0 Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.PricingVariant AS PricingVariant,
	|	TemporaryTableOfGoods_.PricingBatch AS PricingBatch,
	|	TemporaryTableOfGoods_.TSOSeriesForCommunication AS TSOSeriesForCommunication,
	|	TemporaryTableOfGoods_.PricingPackage AS PricingPackage,
	|	TemporaryTableOfGoods_.TsoPackagingForCommunication AS TsoPackagingForCommunication,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	TemporaryTableOfGoods_.Price AS Price,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	TemporaryTableOfGoods_.Currency AS CurrencyOfChange
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&Goods AS TemporaryTableOfGoods_
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	TSOSeriesForCommunication,
	|	TsoPackagingForCommunication,
	|	PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsThatAreNotAllowedToBeEdited.Products AS Products,
	|	GoodsThatAreNotAllowedToBeEdited.PricingVariant AS PricingVariant,
	|	GoodsThatAreNotAllowedToBeEdited.PricingBatch AS PricingBatch,
	|	GoodsThatAreNotAllowedToBeEdited.PricingPackage AS PricingPackage,
	|	GoodsThatAreNotAllowedToBeEdited.PriceKind AS PriceKind
	|INTO TemporaryTableProductsNotAllowedForEditing
	|FROM
	|	&ProductsThatCannotBeEdited AS GoodsThatAreNotAllowedToBeEdited
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.PricingVariant AS PricingVariant,
	|	TemporaryTableOfGoods_.PricingBatch AS PricingBatch,
	|	TemporaryTableOfGoods_.PricingPackage AS PricingPackage,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	TemporaryTableOfGoods_.Price AS Price,
	|	CASE
	|		WHEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = TemporaryTableOfGoods_.Package
	|			THEN ISNULL(ItemsPrices.Price, 0)
	|		ELSE ISNULL(ItemsPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS EffectivePrice,
	|	CAST(CASE
	|			WHEN ISNULL(ItemsPrices.Price, 0) <> 0
	|				THEN 100 * (TemporaryTableOfGoods_.Price - CASE
	|						WHEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = TemporaryTableOfGoods_.Package
	|							THEN ISNULL(ItemsPrices.Price, 0)
	|						ELSE ISNULL(ItemsPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END) / CASE
	|						WHEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = TemporaryTableOfGoods_.Package
	|							THEN ISNULL(ItemsPrices.Price, 0)
	|						ELSE ISNULL(ItemsPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END
	|			ELSE 0
	|		END AS NUMBER(25, 2)) AS Percent,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	TemporaryTableOfGoods_.CurrencyOfChange AS CurrencyOfChange,
	|	ISNULL(ItemsPrices.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS ActiveCurrency,
	|	NOT TemporaryTableProductsNotAllowedForEditing.Products IS NULL AS NoEditingAllowed
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(
	|				&DocumentDate,
	|				(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
	|					(SELECT
	|						T.Products,
	|						T.PricingVariant,
	|						T.TSOSeriesForCommunication,
	|						T.TsoPackagingForCommunication,
	|						T.PriceKind
	|					FROM
	|						TemporaryTableOfGoods_ AS T)) AS ItemsPrices
	|		ON (ItemsPrices.Products = TemporaryTableOfGoods_.Products)
	|			AND (ItemsPrices.PricingVariant = TemporaryTableOfGoods_.PricingVariant)
	|			AND (ItemsPrices.PricingBatch = TemporaryTableOfGoods_.TSOSeriesForCommunication)
	|			AND (ItemsPrices.PricingPackage = TemporaryTableOfGoods_.TsoPackagingForCommunication)
	|			AND (ItemsPrices.PriceKind = TemporaryTableOfGoods_.PriceKind)
	|		LEFT JOIN TemporaryTableProductsNotAllowedForEditing AS TemporaryTableProductsNotAllowedForEditing
	|		ON (TemporaryTableProductsNotAllowedForEditing.Products = TemporaryTableOfGoods_.Products)
	|			AND (TemporaryTableProductsNotAllowedForEditing.PricingVariant = TemporaryTableOfGoods_.PricingVariant)
	|			AND (TemporaryTableProductsNotAllowedForEditing.PriceKind = TemporaryTableOfGoods_.PriceKind)
	|
	|ORDER BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
	Query.SetParameter("Goods",        ProductsTable);

	If TableOfProductsThatCannotBeEdited = Undefined Then
		TableOfProductsThatCannotBeEdited = New ValueTable();
		TableOfProductsThatCannotBeEdited.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingVariant", New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingBatch",          New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingPackage",       New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PriceKind",          New TypeDescription("CatalogRef.TypesOfPrices"));		
	EndIf;	
	Query.SetParameter("ProductsThatCannotBeEdited", TableOfProductsThatCannotBeEdited);
	
	If SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode) Then
		Query.SetParameter("DocumentDate", BegOfDay(Form.Date) - 1);
	Else
		Query.SetParameter("DocumentDate", DateForRequestingProductPrices(Form));
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select(QueryResultIteration.Linear);

	CurrentData = New Structure("PricesKind, Products, PricingVariant, PricingBatch, PricingPackage");
	
	While Selection.Next() Do
		
		If Not ValueIsFilled(Selection.PriceKind) Then
			Continue;
		EndIf;
		
		If CurrentData.PricesKind <> Selection.PriceKind Then
			CurrentData.PricesKind = Selection.PriceKind;
			ColumnName = ColumnNameByPriceType(Selection.PriceKind, DataCache);
		EndIf;
		
		If CurrentData.Products <> Selection.Products
			Or CurrentData.PricingVariant <> Selection.PricingVariant 
			Or CurrentData.PricingBatch <> Selection.PricingBatch 
			Or CurrentData.PricingPackage <> Selection.PricingPackage Then
			
			FillPropertyValues(CurrentData, Selection, "Products, PricingVariant, PricingBatch, PricingPackage");
			FoundRow = FindPriceTreeString(Form, Selection, DataCache);
			
		EndIf;
		
		If Not Selection.CurrencyOfChange.IsEmpty() And Selection.CurrencyOfChange <> Selection.ActiveCurrency Then
			
			EffectivePrice = RecalculateCurrency(Selection.ActiveCurrency, 
												Selection.CurrencyOfChange, 
												Selection.EffectivePrice, 
												DataCache.ExchangeRates);
		Else
			
			EffectivePrice = Selection.EffectivePrice;
			
			If ValueIsFilled(Selection.ActiveCurrency) Then
				CurrencyToFillIn = Selection.ActiveCurrency;
			ElsIf Not ValueIsFilled(Selection.PriceKind) Then
				CurrencyToFillIn = Catalogs.Currencies.EmptyRef();
			Else
				
				ProductPriceType = Selection.PriceKind; // CatalogRef.TypesOfPrices
				CurrencyToFillIn = Common.ObjectAttributeValue(
					ProductPriceType,
					"PriceCurrency");
				
			EndIf;
			
			FoundRow["Currency" + ColumnName] = CurrencyToFillIn;
			
		EndIf;
		
		FoundRow["OldPrice"           + ColumnName] = EffectivePrice;
		FoundRow["ChangePercentage"     + ColumnName] = Selection.Percent;
		FoundRow["NoEditingAllowed" + ColumnName] = Selection.NoEditingAllowed;
		
		If Selection.NoEditingAllowed And EffectivePrice <> 0 Then
			FoundRow["ChangedAutomatically" + ColumnName] = True;
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Re-download old prices for table rows
// 
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - See CreateProductsTable
//  DataCache - See InitializeDataCacheStructure
//
Procedure LoadOldPricesOfSupplierProducts(Form, ProductsTable, DataCache) Export

	If ProductsTable.Count() = 0 Then
		Return;
	EndIf;

	Query = New Query("
	|SELECT
	|	TemporaryTableOfGoods_.PartnerProducts AS PartnerProducts,
	|	TemporaryTableOfGoods_.Products           AS Products,
	|	TemporaryTableOfGoods_.Characteristic         AS Characteristic,
	|	CAST(TemporaryTableOfGoods_.PriceKind AS Catalog.VendorPriceTypes) AS PriceKind,
	|	TemporaryTableOfGoods_.Price                   AS Price,
	|	TemporaryTableOfGoods_.Package               AS Package
	|INTO
	|	TempTableGoodsPre
	|FROM
	|	&Goods AS TemporaryTableOfGoods_
	|;
	|/////////////////////////////////////////////////
	|SELECT
	|	Table.PartnerProducts  AS PartnerProducts,
	|	Table.Products          AS Products,
	|	Table.Characteristic        AS Characteristic,
	|	Table.Price                  AS Price,
	|	Table.Package              AS Package,
	|	Table.PriceKind               AS PriceKind,
	|	Table.PriceKind.Owner      AS Partner
	|INTO TemporaryTableOfGoods_
	|FROM
	|	TempTableGoodsPre AS Table
	|INDEX BY
	|	PartnerProducts,
	|	Products,
	|	Characteristic,
	|	PriceKind,
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseConditionsSliceLast.Products AS Products,
	|	PurchaseConditionsSliceLast.Characteristic AS Characteristic,
	|	PurchaseConditionsSliceLast.VendorPriceKind AS VendorPriceKind,
	|	PurchaseConditionsSliceLast.OrderPackage AS OrderPackage,
	|	PurchaseConditionsSliceLast.MinimumDeliveryLot AS MinimumDeliveryLot
	|INTO TTTermsOfPurchase
	|FROM
	|	InformationRegister.PurchaseConditions.SliceLast(
	|	&DocumentDate, 
	|	(Products, Characteristic, VendorPriceKind) IN
	|					(SELECT
	|						T.Products,
	|						T.Characteristic,
	|						T.PriceKind
	|					FROM
	|						TemporaryTableOfGoods_ AS T)) AS PurchaseConditionsSliceLast
	|INDEX BY Products, Characteristic, VendorPriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsPricesOfVendor.Products              AS Products,
	|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
	|	ItemsPricesOfVendor.VendorPriceKind         AS VendorPriceKind,
	|	ItemsPricesOfVendor.Currency                    AS Currency,
	|	ItemsPricesOfVendor.Package                  AS Package,
	|	ItemsPricesOfVendor.Price                      AS Price
	|INTO PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(
	|				&DocumentDate,
	|				(Products, Characteristic, VendorPriceKind, Partner) IN
	|					(SELECT
	|						T.Products,
	|						T.Characteristic,
	|						T.PriceKind,
	|						T.Partner
	|					FROM
	|						TemporaryTableOfGoods_ AS T)
	|) AS ItemsPricesOfVendor
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.PartnerProducts AS PartnerProducts,
	|	TemporaryTableOfGoods_.Products           AS Products,
	|	TemporaryTableOfGoods_.Characteristic         AS Characteristic,
	|	TemporaryTableOfGoods_.PriceKind                AS PriceKind,
	|	TemporaryTableOfGoods_.Price                   AS Price,
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN ItemsPrices.Price
	|		ELSE ItemsPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS EffectivePrice,
	|	CAST(CASE
	|			WHEN ItemsPrices.Price <> 0
	|				THEN 100 * (TemporaryTableOfGoods_.Price - CASE
	|						WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package
	|							THEN ItemsPrices.Price
	|						ELSE ItemsPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END) / CASE
	|						WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package
	|							THEN ItemsPrices.Price
	|						ELSE ItemsPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END
	|			ELSE 0
	|		END AS NUMBER(10, 2)) AS Percent,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	TTTermsOfPurchase.OrderPackage AS OrderPackage,
	|	TTTermsOfPurchase.MinimumDeliveryLot AS MinimumDeliveryLot
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN PricesOfSupplierNomenclatureCrossSectionOfTheLatest AS ItemsPrices
	|		ON (ItemsPrices.Products = TemporaryTableOfGoods_.Products)
	|			AND (ItemsPrices.Characteristic = TemporaryTableOfGoods_.Characteristic)
	|			AND (ItemsPrices.VendorPriceKind = TemporaryTableOfGoods_.PriceKind)
	|		LEFT JOIN TTTermsOfPurchase AS TTTermsOfPurchase
	|			ON (TTTermsOfPurchase.Products = TemporaryTableOfGoods_.Products)
	|			AND (TTTermsOfPurchase.Characteristic = TemporaryTableOfGoods_.Characteristic)
	|			AND (TTTermsOfPurchase.VendorPriceKind = TemporaryTableOfGoods_.PriceKind)
	|TOTALS
	|	CASE
	|		WHEN CASE
	|				WHEN MAX(ItemVariantsAreUsed)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|			THEN NULL
	|		ELSE MAX(PartnerProducts)
	|	END AS PartnerProducts
	|BY
	|	Products");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
	Query.SetParameter("Goods", ProductsTable);
	If SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode) Then
		Query.SetParameter("DocumentDate", BegOfDay(Form.Date) - 1);
	Else
		Query.SetParameter("DocumentDate", DateForRequestingProductPrices(Form));
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionOfProducts.Next() Do
		
		SamplingTypesOfPrices = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While SamplingTypesOfPrices.Next() Do
			
			ProductItem = FindPriceTreeString(Form, SamplingTypesOfPrices, DataCache);
			
			If Not ValueIsFilled(SamplingTypesOfPrices.PriceKind)
				Or ProductItem = Undefined Then
				Continue;
			EndIf;
			
			ColumnName = ColumnNameByPriceType(SamplingTypesOfPrices.PriceKind, DataCache);
			
			If Not ThisIsDownloadingVendorPricesFromExternalFiles(Form) Then
				ProductItem[ColumnName] = SamplingTypesOfPrices.Price;
				If Form.UseItemPackages Then
					ProductItem["OrderPackage" + ColumnName] = SamplingTypesOfPrices.OrderPackage;
				EndIf;
				ProductItem["MinimumDeliveryLot" + ColumnName] = SamplingTypesOfPrices.MinimumDeliveryLot;
			Else
				If ProductItem[ColumnName] <> ProductItem["OldPrice" + ColumnName] Then
					ProductItem["TheCostOfTheChanged"]	= True;
				EndIf;	
			EndIf;
			
			ProductItem["OldPrice"       + ColumnName] = SamplingTypesOfPrices.EffectivePrice;
			ProductItem["ChangePercentage" + ColumnName] = SamplingTypesOfPrices.Percent;
			
		EndDo;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Re-download old prices for table rows
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - See CreateProductsTable
//  DataCache - See InitializeDataCacheStructure
// 
Procedure LoadOldPricesOfProducts(Form, ProductsTable, DataCache) Export
	
	If ThisIsVendorPriceRegistration(Form, DataCache) Then
		LoadOldPricesOfSupplierProducts(Form, ProductsTable, DataCache);
	Else
		ExchangeRates(Form, DataCache);
		TableOfProductsThatCannotBeEdited = GetProductsThatAreNotAllowedToBeEdited(Form, ProductsTable);
		If Form.UsePriceManagementSystem25 Then
			LoadOldPricesOfCompanyProducts2_5(Form, ProductsTable, DataCache, TableOfProductsThatCannotBeEdited);
		Else
			LoadOldPricesOfCompanyProducts(Form, ProductsTable, DataCache, TableOfProductsThatCannotBeEdited);
		EndIf;
	EndIf;
	
EndProcedure

// Re-download old prices for table rows
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - See CreateProductsTable
//  DataCache - See InitializeDataCacheStructure
//  TableOfProductsThatCannotBeEdited - ValueTable - Table of prohibited nomenlature editing
// 
Procedure LoadOldPricesOfProductsPriceList(Form, ProductsTable, DataCache, TableOfProductsThatCannotBeEdited = Undefined) Export

	If ProductsTable.Count() = 0 Then
		Return;
	EndIf;

	Query = New Query("SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	TemporaryTableOfGoods_.Package AS Package
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&Goods AS TemporaryTableOfGoods_
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableProductsNotAllowedForEditing.Products AS Products,
	|	TemporaryTableProductsNotAllowedForEditing.Characteristic AS Characteristic,
	|	TemporaryTableProductsNotAllowedForEditing.PriceKind AS PriceKind,
	|	TRUE AS NoEditingAllowed
	|INTO TemporaryTableProductsNotAllowedForEditing
	|FROM
	|	&ProductsThatCannotBeEdited AS TemporaryTableProductsNotAllowedForEditing
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	CASE
	|		WHEN CurrentPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN ISNULL(CurrentPrices.Price, 0)
	|		ELSE ISNULL(CurrentPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) *
	|			ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS Price,
	|	CASE
	|		WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN ISNULL(OldPrices.Price, 0)
	|		ELSE ISNULL(OldPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor3, 1) *
	|			ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS OldPrice,
	|	CAST(CASE
	|		WHEN OldPrices.Price <> 0
	|			THEN 100 * (CASE
	|				WHEN CurrentPrices.Package = TemporaryTableOfGoods_.Package
	|					THEN CurrentPrices.Price
	|				ELSE CurrentPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) *
	|					ISNULL(&QueryTextPackagingFactor2, 1)
	|			END - CASE
	|				WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|					THEN OldPrices.Price
	|				ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) *
	|					ISNULL(&QueryTextPackagingFactor2, 1)
	|			END) / CASE
	|				WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|					THEN OldPrices.Price
	|				ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) *
	|					ISNULL(&QueryTextPackagingFactor2, 1)
	|			END
	|		ELSE 0.00
	|	END AS NUMBER(25, 2)) AS Percent,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	ISNULL(TypesOfPricesPriceGroups.Formula, TypesOfPrices.Formula) AS Formula,
	|	TypesOfPrices.PricingMethod,
	|	ISNULL(TypesOfPricesPriceGroups.BasicPriceType, TypesOfPrices.BasicPriceType) AS BasicPriceType,
	|	ISNULL(TypesOfPricesPriceGroups.Markup, TypesOfPrices.Markup) AS Markup,
	|	CurrentPrices.Formula AS ActiveFormula,
	|	ISNULL(TypesOfPricesCurrencies.PriceCurrency, TypesOfPrices.PriceCurrency) AS Currency,
	|	CurrentPrices.Currency AS CurrentCurrency_,
	|	ISNULL(TemporaryTableProductsNotAllowedForEditing.NoEditingAllowed, FALSE) AS NoEditingAllowed
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&DateInPast, (Products, Characteristic,
	|			PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.Characteristic,
	|				T.PriceKind
	|			FROM
	|				TemporaryTableOfGoods_ AS T)) AS OldPrices
	|		ON OldPrices.Products = TemporaryTableOfGoods_.Products
	|		AND OldPrices.Characteristic = TemporaryTableOfGoods_.Characteristic
	|		AND OldPrices.PriceKind = TemporaryTableOfGoods_.PriceKind
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&CurrentDate, (Products, Characteristic,
	|			PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.Characteristic,
	|				T.PriceKind
	|			FROM
	|				TemporaryTableOfGoods_ AS T)) AS CurrentPrices
	|		ON CurrentPrices.Products = TemporaryTableOfGoods_.Products
	|		AND CurrentPrices.Characteristic = TemporaryTableOfGoods_.Characteristic
	|		AND CurrentPrices.PriceKind = TemporaryTableOfGoods_.PriceKind
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
	|		ON TemporaryTableOfGoods_.PriceKind = TypesOfPrices.Ref
	|		LEFT JOIN TemporaryTableProductsNotAllowedForEditing AS
	|			TemporaryTableProductsNotAllowedForEditing
	|		ON TemporaryTableProductsNotAllowedForEditing.Products = TemporaryTableOfGoods_.Products
	|		AND TemporaryTableProductsNotAllowedForEditing.Characteristic = TemporaryTableOfGoods_.Characteristic
	|		AND TemporaryTableProductsNotAllowedForEditing.PriceKind = TemporaryTableOfGoods_.PriceKind
	|		LEFT JOIN Catalog.TypesOfPrices.PriceGroups AS TypesOfPricesPriceGroups
	|		ON (TemporaryTableOfGoods_.PriceKind = TypesOfPricesPriceGroups.Ref)
	|		AND (TemporaryTableOfGoods_.Products.PriceGroup = TypesOfPricesPriceGroups.PriceGroup)
	|		LEFT JOIN Catalog.TypesOfPrices.Currencies AS TypesOfPricesCurrencies
	|		ON (TemporaryTableOfGoods_.PriceKind = TypesOfPricesCurrencies.Ref)
	|		AND (TemporaryTableOfGoods_.Products.PriceGroup = TypesOfPricesCurrencies.PriceGroup)
	|TOTALS
	|BY
	|	Products,
	|	Characteristic");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CurrentPrices.Package",
		"CurrentPrices.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OldPrices.Package",
		"OldPrices.Products"));
		
	Query.SetParameter("Goods",       ProductsTable);
	Query.SetParameter("CurrentDate",  EndOfDay(Form.Date));
	If ValueIsFilled(Form.ValidPriceDate) Then
		Query.SetParameter("DateInPast", EndOfDay(Form.ValidPriceDate));
	Else
		Query.SetParameter("DateInPast", BegOfDay(Form.Date) - 1);
	EndIf;
	
	If TableOfProductsThatCannotBeEdited = Undefined Then
		TableOfProductsThatCannotBeEdited = New ValueTable();
		TableOfProductsThatCannotBeEdited.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		TableOfProductsThatCannotBeEdited.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));		
	EndIf;	
	Query.SetParameter("ProductsThatCannotBeEdited", TableOfProductsThatCannotBeEdited);
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionOfProducts.Next() Do
		
		FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While FeatureSelection_.Next() Do
			
			If ValueIsFilled(FeatureSelection_.Characteristic) Then
				
				ElementCharacteristic = FindPriceTreeString(Form, FeatureSelection_, DataCache);
		
				SamplingTypesOfPrices = FeatureSelection_.Select(QueryResultIteration.ByGroups);
				While SamplingTypesOfPrices.Next() Do
					
					If Not ValueIsFilled(SamplingTypesOfPrices.PriceKind) Then
						Continue;
					EndIf;
					
					ColumnName = ColumnNameByPriceType(SamplingTypesOfPrices.PriceKind, DataCache);
					ElementCharacteristic[ColumnName]                      = ?(SamplingTypesOfPrices.NoEditingAllowed, 0, SamplingTypesOfPrices.Price);
					ElementCharacteristic["OldPrice"       + ColumnName] = SamplingTypesOfPrices.OldPrice;
					ElementCharacteristic["ChangePercentage" + ColumnName] = SamplingTypesOfPrices.Percent;
					ElementCharacteristic["AmountOfChange"   + ColumnName] = SamplingTypesOfPrices.Price - SamplingTypesOfPrices.OldPrice;

					ElementCharacteristic["NoEditingAllowed"   + ColumnName] = SamplingTypesOfPrices.NoEditingAllowed;
					
					If ValueIsFilled(SamplingTypesOfPrices.CurrentCurrency_) Then
						ElementCharacteristic["Currency"   + ColumnName] = SamplingTypesOfPrices.CurrentCurrency_;
					Else
						ElementCharacteristic["Currency"   + ColumnName] = SamplingTypesOfPrices.Currency;
					EndIf;
						
					If Catalogs.TypesOfPrices.AllowChangingFormulas(SamplingTypesOfPrices.PricingMethod) Then
						Formula = ?(ValueIsFilled(SamplingTypesOfPrices.ActiveFormula),SamplingTypesOfPrices.ActiveFormula,SamplingTypesOfPrices.Formula);
						ElementCharacteristic["Formula"                + ColumnName] = Formula;
						ElementCharacteristic["FormulaChangedManually" + ColumnName] = (Formula <> SamplingTypesOfPrices.Formula);
					EndIf;
					
				EndDo;
				
			Else
				
				ProductItem = FindPriceTreeString(Form, FeatureSelection_, DataCache);
				
				SamplingTypesOfPrices = FeatureSelection_.Select(QueryResultIteration.ByGroups);
				While SamplingTypesOfPrices.Next() Do
					
					If Not ValueIsFilled(SamplingTypesOfPrices.PriceKind) Then
						Continue;
					EndIf;
					
					ColumnName = ColumnNameByPriceType(SamplingTypesOfPrices.PriceKind, DataCache);
					
					ProductItem[ColumnName]                      = ?(SamplingTypesOfPrices.NoEditingAllowed, 0, SamplingTypesOfPrices.Price);
					ProductItem["OldPrice"       + ColumnName] = SamplingTypesOfPrices.OldPrice;
					ProductItem["ChangePercentage" + ColumnName] = SamplingTypesOfPrices.Percent;
					ProductItem["AmountOfChange"   + ColumnName] = SamplingTypesOfPrices.Price - SamplingTypesOfPrices.OldPrice;

					ProductItem["NoEditingAllowed"   + ColumnName] = SamplingTypesOfPrices.NoEditingAllowed;
					
					If ValueIsFilled(SamplingTypesOfPrices.CurrentCurrency_) Then
						ProductItem["Currency"   + ColumnName] = SamplingTypesOfPrices.CurrentCurrency_;
					Else
						ProductItem["Currency"   + ColumnName] = SamplingTypesOfPrices.Currency;
					EndIf;
						
					If Catalogs.TypesOfPrices.AllowChangingFormulas(SamplingTypesOfPrices.PricingMethod) Then
						Formula = ?(ValueIsFilled(SamplingTypesOfPrices.ActiveFormula),SamplingTypesOfPrices.ActiveFormula,SamplingTypesOfPrices.Formula);
						ProductItem["Formula"                + ColumnName] = Formula;
						ProductItem["FormulaChangedManually" + ColumnName] = (Formula <> SamplingTypesOfPrices.Formula);
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Re-download old prices for table rows
//
Procedure LoadOldPricesOfProductsPriceList2_5(Form, ProductsTable, DataCache, TableOfProductsThatCannotBeEdited = Undefined) Export

	If ProductsTable.Count() = 0 Then
		Return;
	EndIf;

	Query = New Query("SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.PricingVariant AS PricingVariant,
	|	TemporaryTableOfGoods_.PricingBatch AS PricingBatch,
	|	TemporaryTableOfGoods_.TSOSeriesForCommunication AS TSOSeriesForCommunication,
	|	TemporaryTableOfGoods_.PricingPackage AS PricingPackage,
	|	TemporaryTableOfGoods_.TsoPackagingForCommunication AS TsoPackagingForCommunication,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	TemporaryTableOfGoods_.Package AS Package
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&Goods AS TemporaryTableOfGoods_
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TemporaryTableProductsNotAllowedForEditing.Products AS Products,
	|	TemporaryTableProductsNotAllowedForEditing.PricingVariant AS PricingVariant,
	|	TemporaryTableProductsNotAllowedForEditing.PricingBatch AS PricingBatch,
	|	TemporaryTableProductsNotAllowedForEditing.PricingPackage AS PricingPackage,
	|	TemporaryTableProductsNotAllowedForEditing.PriceKind AS PriceKind,
	|	TRUE AS NoEditingAllowed
	|INTO TemporaryTableProductsNotAllowedForEditing
	|FROM
	|	&ProductsThatCannotBeEdited AS TemporaryTableProductsNotAllowedForEditing
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.PricingVariant AS PricingVariant,
	|	TemporaryTableOfGoods_.PricingBatch AS PricingBatch,
	|	TemporaryTableOfGoods_.PricingPackage AS PricingPackage,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	CASE
	|		WHEN CurrentPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN ISNULL(CurrentPrices.Price, 0)
	|		ELSE ISNULL(CurrentPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) *
	|			ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS Price,
	|	CASE
	|		WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN ISNULL(OldPrices.Price, 0)
	|		ELSE ISNULL(OldPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor3, 1) *
	|			ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS OldPrice,
	|	CAST(CASE
	|		WHEN OldPrices.Price <> 0
	|			THEN 100 * (CASE
	|				WHEN CurrentPrices.Package = TemporaryTableOfGoods_.Package
	|					THEN CurrentPrices.Price
	|				ELSE CurrentPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) *
	|					ISNULL(&QueryTextPackagingFactor2, 1)
	|			END - CASE
	|				WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|					THEN OldPrices.Price
	|				ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) *
	|					ISNULL(&QueryTextPackagingFactor2, 1)
	|			END) / CASE
	|				WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|					THEN OldPrices.Price
	|				ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) *
	|					ISNULL(&QueryTextPackagingFactor2, 1)
	|			END
	|		ELSE 0.00
	|	END AS NUMBER(25, 2)) AS Percent,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	ISNULL(TypesOfPricesPriceGroups.Formula, TypesOfPrices.Formula) AS Formula,
	|	TypesOfPrices.PricingMethod,
	|	ISNULL(TypesOfPricesPriceGroups.BasicPriceType, TypesOfPrices.BasicPriceType) AS BasicPriceType,
	|	ISNULL(TypesOfPricesPriceGroups.Markup, TypesOfPrices.Markup) AS Markup,
	|	CurrentPrices.Formula AS ActiveFormula,
	|	ISNULL(TypesOfPricesCurrencies.PriceCurrency, TypesOfPrices.PriceCurrency) AS Currency,
	|	CurrentPrices.Currency AS CurrentCurrency_,
	|	ISNULL(TemporaryTableProductsNotAllowedForEditing.NoEditingAllowed, FALSE) AS NoEditingAllowed,
	|	TypesOfPrices.OptionForSpecifyingVATRates AS OptionForSpecifyingVATRates,
	|	TypesOfPrices.Country AS Country,
	|	CASE
	|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems)
	|			THEN TypesOfPrices.VATRate
	|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine)
	|			THEN CurrentPrices.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(&DateInPast, (Products, PricingVariant,
	|			PricingBatch, PricingPackage, PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.PricingVariant,
	|				T.TSOSeriesForCommunication,
	|				T.TsoPackagingForCommunication,
	|				T.PriceKind
	|			FROM
	|				TemporaryTableOfGoods_ AS T)) AS OldPrices
	|		ON OldPrices.Products = TemporaryTableOfGoods_.Products
	|		AND OldPrices.PricingVariant = TemporaryTableOfGoods_.PricingVariant
	|		AND OldPrices.PricingBatch = TemporaryTableOfGoods_.TSOSeriesForCommunication
	|		AND OldPrices.PricingPackage = TemporaryTableOfGoods_.TsoPackagingForCommunication
	|		AND OldPrices.PriceKind = TemporaryTableOfGoods_.PriceKind
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(&CurrentDate, (Products, PricingVariant,
	|			PricingBatch, PricingPackage, PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.PricingVariant,
	|				T.TSOSeriesForCommunication,
	|				T.TsoPackagingForCommunication,
	|				T.PriceKind
	|			FROM
	|				TemporaryTableOfGoods_ AS T)) AS CurrentPrices
	|		ON CurrentPrices.Products = TemporaryTableOfGoods_.Products
	|		AND CurrentPrices.PricingVariant = TemporaryTableOfGoods_.PricingVariant
	|		AND CurrentPrices.PricingBatch = TemporaryTableOfGoods_.TSOSeriesForCommunication
	|		AND CurrentPrices.PricingPackage = TemporaryTableOfGoods_.TsoPackagingForCommunication
	|		AND CurrentPrices.PriceKind = TemporaryTableOfGoods_.PriceKind
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
	|		ON TemporaryTableOfGoods_.PriceKind = TypesOfPrices.Ref
	|		LEFT JOIN TemporaryTableProductsNotAllowedForEditing AS
	|			TemporaryTableProductsNotAllowedForEditing
	|		ON TemporaryTableProductsNotAllowedForEditing.Products = TemporaryTableOfGoods_.Products
	|		AND TemporaryTableProductsNotAllowedForEditing.PricingVariant = TemporaryTableOfGoods_.PricingVariant
	|		AND TemporaryTableProductsNotAllowedForEditing.PriceKind = TemporaryTableOfGoods_.PriceKind
	|		LEFT JOIN Catalog.TypesOfPrices.PriceGroups AS TypesOfPricesPriceGroups
	|		ON TemporaryTableOfGoods_.PriceKind = TypesOfPricesPriceGroups.Ref
	|		AND TemporaryTableOfGoods_.Products.PriceGroup = TypesOfPricesPriceGroups.PriceGroup
	|		LEFT JOIN Catalog.TypesOfPrices.Currencies AS TypesOfPricesCurrencies
	|		ON TemporaryTableOfGoods_.PriceKind = TypesOfPricesCurrencies.Ref
	|		AND TemporaryTableOfGoods_.Products.PriceGroup = TypesOfPricesCurrencies.PriceGroup
	|ORDER BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CurrentPrices.Package",
		"CurrentPrices.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OldPrices.Package",
		"OldPrices.Products"));
		
	Query.SetParameter("Goods",       ProductsTable);
	Query.SetParameter("CurrentDate",  EndOfDay(DocumentDate(Form)));
	If ValueIsFilled(Form.ValidPriceDate) Then
		Query.SetParameter("DateInPast", EndOfDay(Form.ValidPriceDate));
	Else
		Query.SetParameter("DateInPast", BegOfDay(DocumentDate(Form)) - 1);
	EndIf;
	
	If TableOfProductsThatCannotBeEdited = Undefined Then
		TableOfProductsThatCannotBeEdited = New ValueTable();
		TableOfProductsThatCannotBeEdited.Columns.Add("Products",     New TypeDescription("CatalogRef.Products"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingVariant", New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingBatch",          New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingPackage",       New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PriceKind",          New TypeDescription("CatalogRef.TypesOfPrices"));		
	EndIf;	
	Query.SetParameter("ProductsThatCannotBeEdited", TableOfProductsThatCannotBeEdited);
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select(QueryResultIteration.Linear);

	CurrentData = New Structure("PricesKind, Products, PricingVariant, PricingBatch, PricingPackage");
	
	While Selection.Next() Do
		
		If Not ValueIsFilled(Selection.PriceKind) Then
			Continue;
		EndIf;
		
		If CurrentData.PricesKind <> Selection.PriceKind Then
			CurrentData.PricesKind = Selection.PriceKind;
		EndIf;
		
		If CurrentData.Products <> Selection.Products
			Or CurrentData.PricingVariant <> Selection.PricingVariant 
			Or CurrentData.PricingBatch <> Selection.PricingBatch 
			Or CurrentData.PricingPackage <> Selection.PricingPackage Then
			
			FillPropertyValues(CurrentData, Selection, "Products, PricingVariant, PricingBatch, PricingPackage");			
			FoundRow = FindPriceTreeString(Form, Selection, DataCache);
			
		EndIf;
		
		If FoundRow = Undefined Then
			Continue;
		EndIf;
		
		ColumnName = ColumnNameByPriceType(Selection.PriceKind, DataCache);
		FoundRow[ColumnName]                          = ?(Selection.NoEditingAllowed, 0, Selection.Price);
		FoundRow["OldPrice"           + ColumnName] = Selection.OldPrice;
		FoundRow["ChangePercentage"     + ColumnName] = Selection.Percent;
		FoundRow["AmountOfChange"       + ColumnName] = Selection.Price - Selection.OldPrice;
		FoundRow["NoEditingAllowed" + ColumnName] = Selection.NoEditingAllowed;
		
		If ValueIsFilled(Selection.CurrentCurrency_) Then
			FoundRow["Currency" + ColumnName] = Selection.CurrentCurrency_;
		Else
			FoundRow["Currency" + ColumnName] = Selection.Currency;
		EndIf;
			
		If Catalogs.TypesOfPrices.AllowChangingFormulas(Selection.PricingMethod) Then
			Formula = ?(ValueIsFilled(Selection.ActiveFormula),Selection.ActiveFormula,Selection.Formula);
			FoundRow["Formula"                + ColumnName] = Formula;
			FoundRow["FormulaChangedManually" + ColumnName] = (Formula <> Selection.Formula);
		EndIf;
		
		FoundRow["OptionForSpecifyingVATRates" + ColumnName] = Selection.OptionForSpecifyingVATRates;
		FoundRow["Country" + ColumnName] = Selection.Country;
		FoundRow["VATRate" + ColumnName] = Selection.VATRate;
		FoundRow["InitialVATRate" + ColumnName] = Selection.VATRate;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Re-download old prices for table rows
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable - See CreateProductsTable
//  DataCache - See InitializeDataCacheStructure
// 
Procedure LoadOldPricesOfSupplierProductsPriceList(Form, ProductsTable, DataCache) Export
	
	If ProductsTable.Count() = 0 Then
		Return;
	EndIf;

	Query = New Query("
	|SELECT
	|	TemporaryTableOfGoods_.PartnerProducts AS PartnerProducts,
	|	TemporaryTableOfGoods_.Products           AS Products,
	|	TemporaryTableOfGoods_.Characteristic         AS Characteristic,
	|	CAST(TemporaryTableOfGoods_.PriceKind AS Catalog.VendorPriceTypes) AS PriceKind,
	|	TemporaryTableOfGoods_.Package               AS Package
	|INTO
	|	TempTableGoodsPre
	|FROM
	|	&Goods AS TemporaryTableOfGoods_
	|;
	|/////////////////////////////////////////////////
	|SELECT
	|	Table.PartnerProducts  AS PartnerProducts,
	|	Table.Products          AS Products,
	|	Table.Characteristic        AS Characteristic,
	|	Table.Package              AS Package,
	|	Table.PriceKind               AS PriceKind,
	|	Table.PriceKind.Owner      AS Partner
	|INTO TemporaryTableOfGoods_
	|FROM
	|	TempTableGoodsPre AS Table
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind,
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseConditionsSliceLast.Products AS Products,
	|	PurchaseConditionsSliceLast.Characteristic AS Characteristic,
	|	PurchaseConditionsSliceLast.VendorPriceKind AS VendorPriceKind,
	|	PurchaseConditionsSliceLast.OrderPackage AS OrderPackage,
	|	PurchaseConditionsSliceLast.MinimumDeliveryLot AS MinimumDeliveryLot
	|INTO TTTermsOfPurchase
	|FROM
	|	InformationRegister.PurchaseConditions.SliceLast(
	|	&CurrentDate, 
	|	(Products, Characteristic, VendorPriceKind) IN
	|					(SELECT
	|						T.Products,
	|						T.Characteristic,
	|						T.PriceKind
	|					FROM
	|						TemporaryTableOfGoods_ AS T)) AS PurchaseConditionsSliceLast
	|INDEX BY Products, Characteristic, VendorPriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsPricesOfVendor.Products              AS Products,
	|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
	|	ItemsPricesOfVendor.VendorPriceKind         AS VendorPriceKind,
	|	ItemsPricesOfVendor.Currency                    AS Currency,
	|	ItemsPricesOfVendor.Package                  AS Package,
	|	ItemsPricesOfVendor.Price                      AS Price
	|INTO OldPrices
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(
	|				&DateInPast,
	|				(Products, Characteristic, VendorPriceKind, Partner) IN
	|					(SELECT
	|						T.Products,
	|						T.Characteristic,
	|						T.PriceKind,
	|						T.Partner
	|					FROM
	|						TemporaryTableOfGoods_ AS T)
	|) AS ItemsPricesOfVendor
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsPricesOfVendor.Products              AS Products,
	|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
	|	ItemsPricesOfVendor.VendorPriceKind         AS VendorPriceKind,
	|	ItemsPricesOfVendor.Currency                    AS Currency,
	|	ItemsPricesOfVendor.Package                  AS Package,
	|	ItemsPricesOfVendor.Price                      AS Price
	|INTO CurrentPrices
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(
	|				&CurrentDate,
	|				(Products, Characteristic, VendorPriceKind, Partner) IN
	|					(SELECT
	|						T.Products,
	|						T.Characteristic,
	|						T.PriceKind,
	|						T.Partner
	|					FROM
	|						TemporaryTableOfGoods_ AS T)
	|) AS ItemsPricesOfVendor
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.PartnerProducts AS PartnerProducts,
	|	TemporaryTableOfGoods_.Products           AS Products,
	|	TemporaryTableOfGoods_.Characteristic         AS Characteristic,
	|	TemporaryTableOfGoods_.PriceKind                AS PriceKind,
	|	CASE
	|		WHEN TemporaryTableOfGoods_.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN CurrentPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN CurrentPrices.Price
	|		ELSE CurrentPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS Price,
	|	CASE
	|		WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|			THEN OldPrices.Price
	|		ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|	END AS OldPrice,
	|	CAST(CASE
	|			WHEN OldPrices.Price <> 0
	|				THEN 100 * (CASE
	|						WHEN CurrentPrices.Package = TemporaryTableOfGoods_.Package
	|							THEN CurrentPrices.Price
	|						ELSE CurrentPrices.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END - CASE
	|						WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|							THEN OldPrices.Price
	|						ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END) / CASE
	|						WHEN OldPrices.Package = TemporaryTableOfGoods_.Package
	|							THEN OldPrices.Price
	|						ELSE OldPrices.Price / ISNULL(&QueryTextPackagingFactor3, 1) * ISNULL(&QueryTextPackagingFactor2, 1)
	|					END
	|			ELSE 0
	|		END AS NUMBER(10, 2)) AS Percent,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	FALSE AS SettingConditions,
	|	TTTermsOfPurchase.OrderPackage AS OrderPackage,
	|	TTTermsOfPurchase.MinimumDeliveryLot AS MinimumDeliveryLot
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN OldPrices AS OldPrices
	|		ON (OldPrices.Products = TemporaryTableOfGoods_.Products)
	|			AND (OldPrices.Characteristic = TemporaryTableOfGoods_.Characteristic)
	|			AND (OldPrices.VendorPriceKind = TemporaryTableOfGoods_.PriceKind)
	|		LEFT JOIN CurrentPrices AS CurrentPrices
	|		ON (CurrentPrices.Products = TemporaryTableOfGoods_.Products)
	|			AND (CurrentPrices.Characteristic = TemporaryTableOfGoods_.Characteristic)
	|			AND (CurrentPrices.VendorPriceKind = TemporaryTableOfGoods_.PriceKind)
	|		LEFT JOIN TTTermsOfPurchase AS TTTermsOfPurchase
	|		ON TemporaryTableOfGoods_.Products = TTTermsOfPurchase.Products
	|			AND TemporaryTableOfGoods_.Characteristic = TTTermsOfPurchase.Characteristic
	|			AND TemporaryTableOfGoods_.PriceKind = TTTermsOfPurchase.VendorPriceKind
	|TOTALS
	|	CASE
	|		WHEN CASE
	|				WHEN MAX(ItemVariantsAreUsed)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|			THEN NULL
	|		ELSE MAX(PartnerProducts)
	|	END AS PartnerProducts
	|BY
	|	Products");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CurrentPrices.Package",
		"CurrentPrices.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OldPrices.Package",
		"OldPrices.Products"));
		
	Query.SetParameter("Goods",      ProductsTable);
	Query.SetParameter("CurrentDate", EndOfDay(Form.Date));
	If ValueIsFilled(Form.ValidPriceDate) Then
		Query.SetParameter("DateInPast", EndOfDay(Form.ValidPriceDate));
	Else
		Query.SetParameter("DateInPast", BegOfDay(Form.Date) - 1);
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionOfProducts.Next() Do
		
		SamplingTypesOfPrices = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While SamplingTypesOfPrices.Next() Do
			
			If Not ValueIsFilled(SamplingTypesOfPrices.PriceKind) Then
				Continue;
			EndIf;

			ProductItem = FindPriceTreeString(Form, SamplingTypesOfPrices, DataCache);
			
			If ProductItem = Undefined Then
				Continue;
			EndIf;
			
			ColumnName = ColumnNameByPriceType(SamplingTypesOfPrices.PriceKind, DataCache);
			
			ProductItem[ColumnName]                      = SamplingTypesOfPrices.Price;
			ProductItem["OldPrice"       + ColumnName] = SamplingTypesOfPrices.OldPrice;
			ProductItem["ChangePercentage" + ColumnName] = SamplingTypesOfPrices.Percent;
			ProductItem["MinimumDeliveryLot" + ColumnName] = SamplingTypesOfPrices.MinimumDeliveryLot;
			If Form.UseItemPackages Then
				ProductItem["OrderPackage" + ColumnName]            = SamplingTypesOfPrices.OrderPackage;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Generates a price table on the form
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  RecalculatePrices_ - Boolean - Indicates that prices need to be recalculated.
//
Procedure ReformatPriceTable(Form, RecalculatePrices_ = False) Export
	
	DataCache = InitializeDataCacheStructure();
	
	Data = New Structure;
	Data.Insert("Form", Form);
	Data.Insert("Documents", New Array);
	Data.Insert("SaveBasic", True);
	Data.Documents.Add(Form.Object);
	
	Form.AddressOfDataCacheStorage = "";
	
	PutPricesInTablePart(Data);
	BuildPriceTree(Form);
	LoadTablePart(Form, DataCache);
	
	If Not ThisIsVendorPriceRegistration(Form) Then
		If RecalculatePrices_ Then
			CalculateAllPrices(Form, DataCache);
		Else
			DownloadBasePrices(Form, DataCache);
		EndIf;
		UpdateOldProductPrices(Form, DataCache);
	EndIf;

EndProcedure

// Copies prices on all types of tables form Derivaten in string table part a Goods of object.
//
// Parameters:
//  Parameters - Structure - Parameters for placing a row in the table part, includes:
//     * Form - See BuildPriceTree.Form
//     * TabularSections - Array of TabularSection
//  PriceString - FormDataCollectionItem - A line in the price tree that should be placed in the table part.
//
Procedure PutPriceStringInTablePart(Parameters, PriceString) Export
	
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Parameters.Form);
	
	For Each PriceKind In Parameters.Form.SelectedPrices Do
		
		If PriceKind.Selected_5 Or Parameters.SaveBasic And PriceKind.Influences Then
			
			ColumnName = PriceKind.ColumnName;
			ThereIsPriceColumn = ThereIs_Column(PriceString, ColumnName);
			
			If ThereIsPriceColumn Then
				Price = PriceString[ColumnName];
			EndIf;
			
			If ThisIsVendorPriceRegistration Then
				If Price = 0
					Or Not ThereIsPriceColumn Then
					Continue;
				EndIf;
			EndIf;
			
			NewRow                = Parameters.TabularSections[0].Add();
			NewRow.Products   = PriceString.Products;
			If Parameters.Form.UsePriceManagementSystem25 Then
				NewRow.PricingVariant = PriceString.PricingVariant;
				NewRow.PricingBatch          = PriceString.PricingBatch;
				NewRow.PricingPackage       = PriceString.PricingPackage;
			Else
				NewRow.Characteristic   = PriceString.Characteristic;
			EndIf; 
			If ThisIsVendorPriceRegistration Then
				NewRow.PartnerProducts = PriceString.PartnerProducts;
				NewRow.VendorPriceKind = PriceKind.Ref;

				ColumnNameOrderPackaging = "MinimumDeliveryLot" + PriceKind.ColumnName;
				NameOfSettingConditionsColumn = "SettingConditions" + PriceKind.ColumnName;
				If ThereIs_Column(PriceString, ColumnNameOrderPackaging) And ThereIs_Column(PriceString, NameOfSettingConditionsColumn) Then
					If PriceString[NameOfSettingConditionsColumn] Then
						NewRow.MinimumDeliveryLot   = PriceString[ColumnNameOrderPackaging];
						NewRow.SettingConditions   = PriceString[NameOfSettingConditionsColumn];
					EndIf;
				EndIf;
			Else
				NewRow.PriceKind = PriceKind.Ref;
			EndIf;
			
			If ThereIsPriceColumn Then
				NewRow.Price = Price;
				If Not ThisIsVendorPriceRegistration Then
					NewRow.PriceIsChangedManually = PriceString["ChangedManually" + ColumnName];
				EndIf;
			EndIf;
			
			If Parameters.Form.UseItemPackages Then
				If ThereIs_Column(PriceString, "Package" + ColumnName) Then
					NewRow.Package = PriceString["Package" + ColumnName];
				ElsIf Parameters.Form.UsePriceManagementSystem25 
					And PriceString.UnitOfMeasure <> PriceString.PricingPackage Then
						NewRow.Package = PriceString.PricingPackage;
				EndIf;
				
				If ThisIsVendorPriceRegistration Then
					ColumnNameOrderPackaging = "OrderPackage" + PriceKind.ColumnName;
					ColumnNamePackagingName = "PackagingName" + PriceKind.ColumnName;
					If ThereIs_Column(PriceString, ColumnNameOrderPackaging) And ThereIs_Column(PriceString, NameOfSettingConditionsColumn) Then
						If PriceString[NameOfSettingConditionsColumn] Then
							NewRow.OrderPackage = PriceString[ColumnNameOrderPackaging];
							NewRow.SettingConditions = PriceString[NameOfSettingConditionsColumn];
							If PriceString.Property(ColumnNamePackagingName) Then
								NewRow.PackagingName = PriceString[ColumnNamePackagingName];
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			If Not ThisIsVendorPriceRegistration Then
				If ThereIs_Column(PriceString, "Formula" + ColumnName) Then
					NewRow.Formula = PriceString["Formula" + ColumnName];
				EndIf;
				If ThereIs_Column(PriceString, "Currency" + ColumnName) Then
					NewRow.Currency  = PriceString["Currency" + ColumnName];
				EndIf;
				
				If	Parameters.Form.UsePriceManagementSystem25
						And ThereIs_Column(PriceString, "VATRate" + ColumnName) Then
					NewRow.VATRate  = PriceString["VATRate" + ColumnName];
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Copies the price types from the table of the form Selectedcenes to the table part of the item's price View.
// 
// Parameters:
//  Form - ClientApplicationForm - Form:
// * Object - DataProcessorObject.PriceList, DocumentObject.PriceSetup -
// * SelectedPrices - ValueTable -:
// ** Ref - CatalogRef.TypesOfPrices, CatalogRef.VendorPriceTypes -
// ** Id - String -
// ** Description - String -
// * SavedDocuments - ValueTable -:
// ** Ref - DocumentRef.VendorPriceList -
// * Items - FormItems -:
// ** PriceTree - ValueTree, FormTable, FormDataTreeItem, FormDataTree -
// * PriceTree - ValueTree, FormTable, FormDataTreeItem, FormDataTree -
// * SettingsComposerFilter - DataCompositionSettingsComposer -
//  TabularSection - DocumentTabularSection.PriceSetup.TypesOfPrices - Table part
//  SaveDataLayoutSettings - Boolean - Save Data Layout Settings
Procedure PutPriceTypesInTablePart(Form,
											TabularSection,
											SaveDataLayoutSettings = False) Export
	
	TabularSection.Clear();
	
	If TypeOf(Form) = Type("Structure") And Not Form.Property("StorageAddressDataLayoutSettings") Then
		SaveDataLayoutSettings = False;
	EndIf;
	
	If SaveDataLayoutSettings Then
		DataLayoutSettingsTable = GetFromTempStorage(Form.StorageAddressDataLayoutSettings);
	EndIf;
	
	ArrayOfSelectedPriceTypes = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
	For Each PriceTypeLine In ArrayOfSelectedPriceTypes Do
		
		NewRow = TabularSection.Add();
		NewRow.PriceKind = PriceTypeLine.Ref;
		
		If SaveDataLayoutSettings Then
			FoundRow = DataLayoutSettingsTable.Find(PriceTypeLine.Ref, "PriceKind");
			If FoundRow <> Undefined Then
				NewRow.DataCompositionSettings = New ValueStorage(FoundRow.DataCompositionSettings);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Download from excel
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ArrayOfStructuresTypesOfPrices	 - Array - Price types
//  ArrayOfDataStructures	 - Array - Goods
// 
// Returns:
//  Structure - The result of the download.
//
Function ImportFromExcel(Form, ArrayOfStructuresTypesOfPrices, ArrayOfDataStructures) Export
	
	ImportResult1 = New Structure;
	ImportResult1.Insert("Completed2",      True);
	ImportResult1.Insert("ErrorDescription", "");
	
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	DataCache = InitializeDataCacheStructure();
	
	If UsePriceManagementSystem25 Then
		GoodsTable = CreateProductsTable(False, UsePriceManagementSystem25);
	Else
		EmptyCharacteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	// Determining the types of prices
	TypesOfPrices = New ValueTable;
	TypesOfPrices.Columns.Add("PriceKind");
	TypesOfPrices.Columns.Add("PriceTypeId");
	TypesOfPrices.Columns.Add("ColumnName");
	TypesOfPrices.Columns.Add("ColumnNumberPrice");
	TypesOfPrices.Columns.Add("ColumnNumberPackaging");
	
	For Each StructureTypeOfPrice In ArrayOfStructuresTypesOfPrices Do
		
		Try
			
			PriceKind = Catalogs.TypesOfPrices.GetRef(New UUID(StructureTypeOfPrice.PriceTypeId));
			
			If Not ValueIsFilled(PriceKind) Then
				Continue;
			EndIf;
			
			PriceTypeLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, PriceKind);
			If PriceTypeLine.Selected_5 Then
				
				NewRow = TypesOfPrices.Add();
				NewRow.PriceKind              = PriceKind;
				NewRow.PriceTypeId = StructureTypeOfPrice.PriceTypeId;
				NewRow.ColumnNumberPrice     = StructureTypeOfPrice.ColumnNumberPrice;
				NewRow.ColumnNumberPackaging = StructureTypeOfPrice.ColumnNumberPackaging;
				NewRow.ColumnName           = PriceTypeLine.ColumnName;
				
			EndIf;
			
		Except
			ImportResult1.Completed2 = False;
			ImportResult1.ErrorDescription =
				NStr("vi = 'Không thể kết nhập tệp.
				            |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".';
				            |ru = 'Файл не может быть загружен.
				            |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".';
				            |en = 'The file cannot be imported.
				            |You may only import the files exported with command ""Excel -> Export..."".'; fa = 'The file cannot be imported.
				            |You may only import the files exported with command ""Excel -> Export..."".';
				            |it = 'Impossibile scaricare il file.
				            | Possono essere scaricati solo i file caricati tramite il comando ""Excel -> carica...""';
				            |pl = 'Plik nie może być załadowany.
				            |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".';
				            |tr = 'Dosya yüklenemez.
				            |Sadece ""Excel -> Yükle..."" komutu kullanılarak yüklenen dosyalar yüklenebilir.'");
			Return ImportResult1;
		EndTry;
		
	EndDo;
	TypesOfPrices.Indexes.Add("PriceTypeId");
	
	If TypesOfPrices.Count() = 0 Then
		ImportResult1.Completed2 = False;
		ImportResult1.ErrorDescription =
			NStr("vi = 'Không thể kết nhập tệp.
			            |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".';
			            |ru = 'Файл не может быть загружен.
			            |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".';
			            |en = 'The file cannot be imported.
			            |You may only import the files exported with command ""Excel -> Export..."".'; fa = 'The file cannot be imported.
			            |You may only import the files exported with command ""Excel -> Export..."".';
			            |it = 'Impossibile scaricare il file.
			            | Possono essere scaricati solo i file caricati tramite il comando ""Excel -> carica...""';
			            |pl = 'Plik nie może być załadowany.
			            |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".';
			            |tr = 'Dosya yüklenemez.
			            |Sadece ""Excel -> Yükle..."" komutu kullanılarak yüklenen dosyalar yüklenebilir.'");
		Return ImportResult1;
	EndIf;
	
	If SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode) Then
		For Each TSRow In Form.SelectedPrices Do
			TSRow.Selected_5 = False;
		EndDo;
		
		For Each TSRow In TypesOfPrices Do
			PriceViewString = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, TSRow.PriceKind);
			PriceViewString.Selected_5 = True;
		EndDo;
	EndIf;
	
	// Uploading prices to the DerewoCen
	For Each ProductStructure_1 In ArrayOfDataStructures Do
		
		PriceTypeLine = TypesOfPrices.Find(ProductStructure_1.PriceTypeId);
		If PriceTypeLine = Undefined Then
			Continue;
		EndIf;
		
		Try
			Products = Catalogs.Products.GetRef(New UUID(ProductStructure_1.ProductID_));
			If UsePriceManagementSystem25 Then
				If Not ValueIsFilled(Products) Then
					Continue;
				EndIf;
				
				NewRow = GoodsTable.Add();
				NewRow.Products   = Products;
				NewRow.PricingVariant = Catalogs.ItemsCharacteristicsForPricing.GetRef(New UUID(ProductStructure_1.IdentifierCharacteristic));
				NewRow.PricingBatch        = Catalogs.ItemsBatchesForPricing.GetRef(New UUID(ProductStructure_1.IDSeriesOfDataCenters));
				NewRow.PricingPackage     = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(ProductStructure_1.IDOfCentralDataCenter));
				NewRow.Package       = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(ProductStructure_1.PackageIdentifier));
				NewRow.TsoPackagingForCommunication = ?(NewRow.PricingPackage = Common.ObjectAttributeValue(Products, "UnitOfMeasure"), Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), NewRow.PricingPackage);
				TSOBatchPredefined = Common.ObjectAttributeValue(NewRow.PricingBatch, "Predefined");
				NewRow.TSOSeriesForCommunication    = ?((ValueIsFilled(TSOBatchPredefined) And TSOBatchPredefined), Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), NewRow.PricingBatch);
				NewRow.PriceKind        = PriceTypeLine.PriceKind;
				NewRow.Price           = ProductStructure_1.Price;
			Else
				Characteristic = Catalogs.ItemsCharacteristics.GetRef(New UUID(ProductStructure_1.IdentifierCharacteristic));
				Package       = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(ProductStructure_1.PackageIdentifier));
			EndIf;
		Except
			ImportResult1.Completed2 = False;
			ImportResult1.ErrorDescription =
				NStr("vi = 'Không thể kết nhập tệp.
				            |Có thể là cấu trúc cột của tệp đã bị hỏng.';
				            |ru = 'Файл не может быть загружен.
				            |Возможно, что структура колонок файла была повреждена.';
				            |en = 'The file cannot be imported.
				            |File column structure might have been corrupted.'; fa = 'The file cannot be imported.
				            |File column structure might have been corrupted.';
				            |it = 'Impossibile scaricare il file.
				            | Probabilmente la struttura delle colonne del file è danneggiata.';
				            |pl = 'Plik nie może być załadowany.
				            |Możliwe, że struktura kolumn pliku została uszkodzona.';
				            |tr = 'Dosya yüklenemedi.
				            |Dosyanın sütun yapısı bozuldu.'");
			Return ImportResult1;
		EndTry;
		
		If Not ValueIsFilled(Products) Then
			Continue;
		EndIf;
		
		If Not UsePriceManagementSystem25 Then
			PriceTreeString = FindPriceTreeString(
				Form,
				New Structure("Products, Characteristic", Products, Characteristic),
				DataCache);
			If PriceTreeString = Undefined Then
				
				PriceTreeString = FindPriceTreeString(
					Form,
					New Structure("Products, Characteristic", Products, EmptyCharacteristic),
					DataCache);
				If PriceTreeString = Undefined Then
					
					PriceTreeString = Form.PriceTree.GetItems().Add();
					PriceTreeString.Products = Products;
					
					NewRow = DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Add();
					NewRow.Products = Products;
					NewRow.PriceTreeString = PriceTreeString;
					NewRow.RowID = PriceTreeString.GetID();
					
				EndIf;
				
				If ValueIsFilled(Characteristic) Then
					
					PriceTreeString = PriceTreeString.GetItems().Add();
					PriceTreeString.Products   = Products;
					PriceTreeString.Characteristic = Characteristic;
					
					NewRow = DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Add();
					NewRow.Products    = Products;
					NewRow.Characteristic  = Characteristic;
					NewRow.PriceTreeString = PriceTreeString;
					NewRow.RowID = PriceTreeString.GetID();
					
				EndIf;
				
			EndIf;
			
			PriceTreeString[PriceTypeLine.ColumnName] = ProductStructure_1.Price;
			If Form.UseItemPackages Then
				PriceTreeString["Package"+PriceTypeLine.ColumnName] = Package;
			EndIf;
			PriceTreeString["ChangedManually"+PriceTypeLine.ColumnName] = True;
			
		EndIf;
		
	EndDo;
	
	If UsePriceManagementSystem25 Then
		ProductsTable = AddProducts_2(Form, GoodsTable, DataCache);

		For Each TableRow In GoodsTable Do
			
			PriceTreeString = FindPriceTreeString(Form, TableRow, DataCache);
			
			NewPrice = TableRow.Price;
			NameOfPriceTypeColumn = ColumnNameByPriceType(TableRow.PriceKind, DataCache);
			
			UpdateDataInLineByPricesPackages(PriceTreeString, New Structure("UseItemPackages, NewPrice, Package, NameOfPriceTypeColumn", Form.UseItemPackages, NewPrice, TableRow.Package, NameOfPriceTypeColumn));
		EndDo;

	EndIf;
	
	UpdateOldProductPrices(Form, DataCache, ProductsTable);
	
	// List of types of prices that depend on the changeable
	DependentPrices = New Array;
	For Each TSRow In TypesOfPrices Do
		ArrayOfDependentPriceStrings = DependentOnTypeOfPriceTypesOfPrices(
			Form,
			SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, TSRow.PriceKind));
		For Each PriceTypeLine In ArrayOfDependentPriceStrings Do
			If DependentPrices.Find(PriceTypeLine) = Undefined
				And TypesOfPrices.Find(PriceTypeLine.Ref) = Undefined Then
					DependentPrices.Add(PriceTypeLine);
			EndIf;
		EndDo;
	EndDo;
	
	If Form.CalculateAutomatically Then
		CalculateCalculatedPrices(
			Form,
			DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree,
			DataCache,
			DependentPrices,
			False);
	Else
		SetManualChangeFlagForPriceTypes(
			Form,
			DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree,
			DependentPrices,
			DataCache);
	EndIf;
	
	ReformatPriceTable(Form, False);
	
	Return ImportResult1;
	
EndFunction

// Set whether to manually change calculated prices
//
// Parameters:
//  Form 				- See BuildPriceTree.Form
//  ProductsTable	 - ValueTable - Item for which prices have been changed
//  ModifiedField		 - String - Name of the changed field
//  DataCache					 - Map - the data cache.
//
Procedure SetFlagForManuallyChangingCalculatedPrices(Form,
	                                                      ProductsTable,
	                                                      ModifiedField = Undefined,
	                                                      DataCache = Undefined) Export
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	ModifiedPriceViewLine = SettingPricesClientServer.PriceViewStringByFieldName(Form.SelectedPrices, ModifiedField);
	If ModifiedPriceViewLine <> Undefined Then
	
		ArrayOfRowsOfDependentPriceTypes = DependentOnTypeOfPriceTypesOfPrices(Form, ModifiedPriceViewLine);
		SetManualChangeFlagForPriceTypes(Form, ProductsTable, ArrayOfRowsOfDependentPriceTypes, DataCache);
	
	EndIf;
	
EndProcedure

// To set the sign manual changes to the types of prices
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ProductsTable	 - ValueTable - Item for which prices have been changed
//  ArrayOfRowsOfDependentPriceTypes - Array - Dependent types of prices
//  DataCache					 - Map - the data cache.
//
Procedure SetManualChangeFlagForPriceTypes(Form,
	                                                   ProductsTable,
	                                                   ArrayOfRowsOfDependentPriceTypes,
	                                                   DataCache = Undefined) Export
	
	DataCache = InitializeDataCacheStructure(DataCache);
	
	For Each ItemItemPosition In ProductsTable Do
		
		PriceTableRow = FindPriceTreeString(Form, ItemItemPosition, DataCache);
		
		For Each PriceTypeLine In ArrayOfRowsOfDependentPriceTypes Do
			
			If PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes
				Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup Then
				PriceTableRow["ChangedManually" + PriceTypeLine.ColumnName] = True;
				PriceTableRow["ChangedAutomatically" + PriceTypeLine.ColumnName] = False;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Puts the latest exchange rates in temporary storage.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCache - See InitializeDataCacheStructure
//
Procedure ExchangeRates(Form, DataCache) Export
	
	If DataCache.ExchangeRates = Undefined Then
		CorrespondenceOfExchangeRates(Form, DataCache);
	EndIf;
	
EndProcedure

// Returns a table with the Packing and Coefficient columns.
//
// Parameters:
// 	Form - See BuildPriceTree.Form
// 	ProductsTable - FormDataCollection - Table where prices are calculated
// 	DataCache - Structure - Data Cache
//
// Returns:
// 	See CoefficientsOfProductPackages
//
Function CoefficientsOfPackagesOfProductsTreeTree(Form, ProductsTable = Undefined, DataCache = Undefined) Export
	
	ArrayOfPriceTypes = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
	TableOfProductPackages = CreateTableOfProductPackages();
	
	If ProductsTable = Undefined Then
		
		AddPackagesFromTreeRecursively(
			Form.PriceTree,
			ArrayOfPriceTypes,
			TableOfProductPackages);
		
	Else
		
		If DataCache = Undefined Then 
			DataCache = InitializeDataCacheStructure();
		EndIf;
		
		For Each ItemItemPosition In ProductsTable Do
			
			PriceTableRow = FindPriceTreeString(Form, ItemItemPosition, DataCache);
			
			AddPackagingProductsRowsOfPriceTableToTable(
				PriceTableRow,
				ArrayOfPriceTypes,
				TableOfProductPackages);
			
		EndDo;
		
	EndIf;
	
	Return CoefficientsOfProductPackages(TableOfProductPackages);
	
EndFunction

// Returns a table with the item, Packaging, and Coefficient columns.
//
// Parameters:
//  TableOfProductPackages - ValueTable - contains the items and packaging that you want to obtain the coefficients.
//
// Returns:
//  Map - compliance of the nomenclature and coefficients of packages.
//
Function CoefficientsOfProductPackages(TableOfProductPackages) Export
	
	QueryText = 
	"SELECT
	|	CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(Table.Products AS Catalog.Products) AS Products
	|INTO PackingTable_
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackingTable_.Package AS Package,
	|	PackingTable_.Products AS Products,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio
	|FROM
	|	PackingTable_ AS PackingTable_";
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackingTable_.Package", "PackingTable_.Products"));
	
	Query = New Query(QueryText);
	
	Query.SetParameter("Table", TableOfProductPackages);
	
	Selection = Query.Execute().Select();
	
	ComplianceOfFactorsOfPackagesOfProductRange = New Map;
	
	While Selection.Next() Do
		
		ComplianceOfFactorsOfPackagesOfProductRange.Insert(String(Selection.Products.UUID()) + String(Selection.Package.UUID()), Selection.ZoomRatio);
		
	EndDo;
		
	Return ComplianceOfFactorsOfPackagesOfProductRange;	
	
EndFunction

// Loads prices for all rows in the products table part
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCache - See InitializeDataCacheStructure
// 
Procedure LoadTablePart(Form, DataCache) Export
	
	SetPrivilegedMode(True);
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Form, DataCache);
	
	If Not ThisIsVendorPriceRegistration Then
		
		If Form.UsePriceManagementSystem25 Then
		
			Query = New Query("
			|SELECT
			|	TemporaryTableOfGoods_.IndexOf              AS IndexOf,
			|	TemporaryTableOfGoods_.Products        AS Products,
			|	TemporaryTableOfGoods_.PricingVariant    AS PricingVariant,
			|	TemporaryTableOfGoods_.PricingBatch             AS PricingBatch,
			|	TemporaryTableOfGoods_.TSOSeriesForCommunication     AS TSOSeriesForCommunication,
			|	TemporaryTableOfGoods_.PricingPackage          AS PricingPackage,
			|	TemporaryTableOfGoods_.TsoPackagingForCommunication  AS TsoPackagingForCommunication,
			|	TemporaryTableOfGoods_.PriceKind             AS PriceKind,
			|	TemporaryTableOfGoods_.Price                AS Price,
			|	TemporaryTableOfGoods_.Package            AS Package,
			|	TemporaryTableOfGoods_.Formula             AS Formula,
			|	TemporaryTableOfGoods_.Currency              AS Currency,
			|	TemporaryTableOfGoods_.PriceIsChangedManually AS PriceIsChangedManually,
			|	TemporaryTableOfGoods_.VATRate           AS VATRate
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS TemporaryTableOfGoods_
			|INDEX BY Products, PricingVariant, PricingBatch,TSOSeriesForCommunication, PricingPackage, TsoPackagingForCommunication, PriceKind
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TemporaryTableProductsNotAllowedForEditing.Products     AS Products,
			|	TemporaryTableProductsNotAllowedForEditing.PricingVariant AS PricingVariant,
			|	TemporaryTableProductsNotAllowedForEditing.PricingBatch          AS PricingBatch,
			|	TemporaryTableProductsNotAllowedForEditing.PricingPackage       AS PricingPackage,
			|	TemporaryTableProductsNotAllowedForEditing.PriceKind          AS PriceKind,
			|	TRUE AS NoEditingAllowed
			|INTO TemporaryTableProductsNotAllowedForEditing
			|FROM
			|	&ProductsThatCannotBeEdited AS TemporaryTableProductsNotAllowedForEditing
			|
			|INDEX BY
			|	Products,
			|	PricingVariant,
			|	PricingBatch,
			|	PricingPackage,
			|	PriceKind
			|;
			|SELECT
			|	TemporaryTableOfGoods_.IndexOf              AS IndexOf,
			|	TemporaryTableOfGoods_.Products        AS Products,
			|	TemporaryTableOfGoods_.PricingVariant    AS PricingVariant,
			|	TemporaryTableOfGoods_.PricingBatch             AS PricingBatch,
			|	TemporaryTableOfGoods_.PricingPackage          AS PricingPackage,
			|	TemporaryTableOfGoods_.PriceKind             AS PriceKind,
			|	TemporaryTableOfGoods_.Price                AS Price,
			|	TemporaryTableOfGoods_.PriceIsChangedManually AS PriceIsChangedManually,
			|	
			|	CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
			|		ItemsPrices.Price
			|	ELSE
			|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
			|	END AS EffectivePrice,
			|	
			|	CAST(CASE WHEN ItemsPrices.Price <> 0 THEN 100*(TemporaryTableOfGoods_.Price - CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
			|		ItemsPrices.Price
			|	ELSE
			|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
			|	END)/ 
			|	
			|	CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
			|		ItemsPrices.Price
			|	ELSE
			|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
			|	END ELSE 0.00 END AS NUMBER(25,2)) AS Percent,
			|	
			|	TemporaryTableOfGoods_.Package                       AS Package,
			|	ISNULL(TemporaryTableProductsNotAllowedForEditing.NoEditingAllowed, FALSE) AS NoEditingAllowed,
			|	TemporaryTableOfGoods_.Formula                        AS Formula,
			|	ISNULL(TypesOfPricesPriceGroups.Formula, TypesOfPrices.Formula) AS DefaultFormulaIs,
			|	TemporaryTableOfGoods_.Currency                         AS Currency,
			|	CASE
			|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems)
			|				AND TemporaryTableOfGoods_.VATRate = VALUE(Catalog.VATRates.EmptyRef)
			|			THEN TypesOfPrices.VATRate
			|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine)
			|				AND TemporaryTableOfGoods_.VATRate = VALUE(Catalog.VATRates.EmptyRef)
			|			THEN ItemsPrices.VATRate
			|		ELSE TemporaryTableOfGoods_.VATRate
			|	END AS VATRate
			|FROM
			|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
			|	
			|	LEFT JOIN
			|		InformationRegister.ItemsPrices25.SliceLast(&Date, (Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN (SELECT Products, PricingVariant, TSOSeriesForCommunication, TsoPackagingForCommunication, PriceKind FROM TemporaryTableOfGoods_)) AS ItemsPrices
			|			ON ItemsPrices.Products     = TemporaryTableOfGoods_.Products
			|			 AND ItemsPrices.PricingVariant = TemporaryTableOfGoods_.PricingVariant
			|			 AND ItemsPrices.PricingBatch          = TemporaryTableOfGoods_.TSOSeriesForCommunication
			|			 AND ItemsPrices.PricingPackage       = TemporaryTableOfGoods_.TsoPackagingForCommunication
			|			 AND ItemsPrices.PriceKind          = TemporaryTableOfGoods_.PriceKind
			|		LEFT JOIN TemporaryTableProductsNotAllowedForEditing AS
			|			TemporaryTableProductsNotAllowedForEditing
			|		ON TemporaryTableProductsNotAllowedForEditing.Products    = TemporaryTableOfGoods_.Products
			|		AND TemporaryTableProductsNotAllowedForEditing.PricingVariant = TemporaryTableOfGoods_.PricingVariant
			|		AND TemporaryTableProductsNotAllowedForEditing.PriceKind          = TemporaryTableOfGoods_.PriceKind
			|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
			|		ON TemporaryTableOfGoods_.PriceKind = TypesOfPrices.Ref
			|		LEFT JOIN Catalog.TypesOfPrices.PriceGroups AS TypesOfPricesPriceGroups
			|		ON (TemporaryTableOfGoods_.PriceKind = TypesOfPricesPriceGroups.Ref)
			|		AND (TemporaryTableOfGoods_.Products.PriceGroup = TypesOfPricesPriceGroups.PriceGroup)
			|	
			|ORDER BY
			|	IndexOf
			|");
			
			TableOfGoods = Form.Object.Goods2_5.Unload();
			
			TableOfGoods.Columns.Add("TSOSeriesForCommunication",    New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
			TableOfGoods.Columns.Add("TsoPackagingForCommunication", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			
			ArrayOfTSOBatches = TableOfGoods.UnloadColumn("PricingBatch"); // Array of CatalogRef.ItemsBatchesForPricing 
			TSOBatchPredefined = Common.ObjectsAttributeValue(ArrayOfTSOBatches, "Predefined");
			
			For Each String In TableOfGoods Do
				LineBatchOfTCOPredefined = TSOBatchPredefined.Get(String.PricingBatch);
				String.TSOSeriesForCommunication   = ?((ValueIsFilled(LineBatchOfTCOPredefined) And LineBatchOfTCOPredefined), Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), String.PricingBatch);
				String.TsoPackagingForCommunication   = String.Package;
			EndDo;
			
		Else
		
			Query = New Query("
			|SELECT
			|	TemporaryTableOfGoods_.IndexOf                         AS IndexOf,
			|	TemporaryTableOfGoods_.Products                   AS Products,
			|	TemporaryTableOfGoods_.Characteristic                 AS Characteristic,
			|	TemporaryTableOfGoods_.PriceKind                        AS PriceKind,
			|	TemporaryTableOfGoods_.Price                           AS Price,
			|	TemporaryTableOfGoods_.Package                       AS Package,
			|	TemporaryTableOfGoods_.Formula                        AS Formula,
			|	TemporaryTableOfGoods_.Currency                         AS Currency,
			|	TemporaryTableOfGoods_.PriceIsChangedManually            AS PriceIsChangedManually
			|INTO
			|	TemporaryTableOfGoods_
			|FROM
			|	&Goods AS TemporaryTableOfGoods_
			|INDEX BY Products, Characteristic, PriceKind
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TemporaryTableProductsNotAllowedForEditing.Products AS Products,
			|	TemporaryTableProductsNotAllowedForEditing.Characteristic AS Characteristic,
			|	TemporaryTableProductsNotAllowedForEditing.PriceKind AS PriceKind,
			|	TRUE AS NoEditingAllowed
			|INTO TemporaryTableProductsNotAllowedForEditing
			|FROM
			|	&ProductsThatCannotBeEdited AS TemporaryTableProductsNotAllowedForEditing
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	PriceKind
			|;
			|SELECT
			|	TemporaryTableOfGoods_.IndexOf                         AS IndexOf,
			|	TemporaryTableOfGoods_.Products                   AS Products,
			|	TemporaryTableOfGoods_.Characteristic                 AS Characteristic,
			|	TemporaryTableOfGoods_.PriceKind                        AS PriceKind,
			|	TemporaryTableOfGoods_.Price                           AS Price,
			|	TemporaryTableOfGoods_.PriceIsChangedManually            AS PriceIsChangedManually,
			|	
			|	CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
			|		ItemsPrices.Price
			|	ELSE
			|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
			|	END AS EffectivePrice,
			|	
			|	CAST(CASE WHEN ItemsPrices.Price <> 0 THEN 100*(TemporaryTableOfGoods_.Price - CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
			|		ItemsPrices.Price
			|	ELSE
			|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
			|	END)/ 
			|	
			|	CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
			|		ItemsPrices.Price
			|	ELSE
			|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
			|	END ELSE 0.00 END AS NUMBER(25,2)) AS Percent,
			|	
			|	TemporaryTableOfGoods_.Package                       AS Package,
			|	ISNULL(TemporaryTableProductsNotAllowedForEditing.NoEditingAllowed, FALSE) AS NoEditingAllowed,
			|	TemporaryTableOfGoods_.Formula                        AS Formula,
			|	ISNULL(TypesOfPricesPriceGroups.Formula, TypesOfPrices.Formula) AS DefaultFormulaIs,
			|	TemporaryTableOfGoods_.Currency                         AS Currency
			|FROM
			|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
			|	
			|	LEFT JOIN
			|		InformationRegister.ItemsPrices.SliceLast(&Date, (Products, Characteristic, PriceKind) IN (SELECT Products, Characteristic, PriceKind FROM TemporaryTableOfGoods_)) AS ItemsPrices
			|			ON ItemsPrices.Products   = TemporaryTableOfGoods_.Products
			|			 AND ItemsPrices.Characteristic = TemporaryTableOfGoods_.Characteristic
			|			 AND ItemsPrices.PriceKind        = TemporaryTableOfGoods_.PriceKind
			|		LEFT JOIN TemporaryTableProductsNotAllowedForEditing AS
			|			TemporaryTableProductsNotAllowedForEditing
			|		ON TemporaryTableProductsNotAllowedForEditing.Products = TemporaryTableOfGoods_.Products
			|		AND TemporaryTableProductsNotAllowedForEditing.Characteristic = TemporaryTableOfGoods_.Characteristic
			|		AND TemporaryTableProductsNotAllowedForEditing.PriceKind = TemporaryTableOfGoods_.PriceKind
			|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
			|		ON TemporaryTableOfGoods_.PriceKind = TypesOfPrices.Ref
			|		LEFT JOIN Catalog.TypesOfPrices.PriceGroups AS TypesOfPricesPriceGroups
			|		ON (TemporaryTableOfGoods_.PriceKind = TypesOfPricesPriceGroups.Ref)
			|		AND (TemporaryTableOfGoods_.Products.PriceGroup = TypesOfPricesPriceGroups.PriceGroup)
			|	
			|ORDER BY
			|	IndexOf
			|");
			
			TableOfGoods = Form.Object.Goods.Unload(); // ValueTable
			
		EndIf;
		
	Else
		
		Query = New Query("
		|SELECT
		|	TemporaryTableOfGoods_.IndexOf                         AS IndexOf,
		|	TemporaryTableOfGoods_.PartnerProducts           AS PartnerProducts,
		|	TemporaryTableOfGoods_.Products                   AS Products,
		|	TemporaryTableOfGoods_.Characteristic                 AS Characteristic,
		|	CAST(TemporaryTableOfGoods_.VendorPriceKind AS Catalog.VendorPriceTypes) AS PriceKind,
		|	TemporaryTableOfGoods_.Package                       AS Package,
		|	TemporaryTableOfGoods_.Price                           AS Price,
		|	TemporaryTableOfGoods_.OrderPackage                 AS OrderPackage,
		|	TemporaryTableOfGoods_.MinimumDeliveryLot      AS MinimumDeliveryLot,
		|	TemporaryTableOfGoods_.SettingConditions               AS SettingConditions
		|INTO
		|	TempTableGoodsPre
		|FROM
		|	&Goods AS TemporaryTableOfGoods_
		|INDEX BY Products, Characteristic, PriceKind
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	Table.IndexOf                AS IndexOf,
		|	Table.PartnerProducts  AS PartnerProducts,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	Table.Price                  AS Price,
		|	Table.Package              AS Package,
		|	Table.OrderPackage        AS OrderPackage,
		|	Table.MinimumDeliveryLot AS MinimumDeliveryLot,
		|	Table.SettingConditions      AS SettingConditions,
		|	Table.PriceKind               AS PriceKind,
		|	Table.PriceKind.Owner      AS Partner
		|INTO TemporaryTableOfGoods_
		|FROM
		|	TempTableGoodsPre AS Table
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	PriceKind,
		|	Partner
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	ItemsPricesOfVendor.Products              AS Products,
		|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
		|	ItemsPricesOfVendor.VendorPriceKind         AS VendorPriceKind,
		|	ItemsPricesOfVendor.Currency                    AS Currency,
		|	ItemsPricesOfVendor.Package                  AS Package,
		|	ItemsPricesOfVendor.Price                      AS Price
		|INTO PricesOfSupplierNomenclatureCrossSectionOfTheLatest
		|FROM
		|	InformationRegister.ItemsPricesOfVendor.SliceLast(&Date, 
		|			(Products, Characteristic, VendorPriceKind, Partner) IN
		|			(SELECT
		|				T.Products,
		|				T.Characteristic,
		|				T.PriceKind,
		|				T.Partner
		|			FROM
		|				TemporaryTableOfGoods_ AS T)
		|) AS ItemsPricesOfVendor
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	VendorPriceKind
		|;
		|
		|SELECT
		|	TemporaryTableOfGoods_.IndexOf                         AS IndexOf,
		|	TemporaryTableOfGoods_.PartnerProducts         AS PartnerProducts,
		|	TemporaryTableOfGoods_.Products                   AS Products,
		|	TemporaryTableOfGoods_.Characteristic                 AS Characteristic,
		|	TemporaryTableOfGoods_.PriceKind                        AS PriceKind,
		|	TemporaryTableOfGoods_.Price                           AS Price,
		|	FALSE                                                  AS PriceIsChangedManually,
		|	
		|	CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
		|		ItemsPrices.Price
		|	ELSE
		|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
		|	END AS EffectivePrice,
		|	
		|	CAST(CASE WHEN ItemsPrices.Price <> 0 THEN 100*(TemporaryTableOfGoods_.Price - CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
		|		ItemsPrices.Price
		|	ELSE
		|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
		|	END)/ 
		|	
		|	CASE WHEN ItemsPrices.Package = TemporaryTableOfGoods_.Package THEN
		|		ItemsPrices.Price
		|	ELSE
		|		ItemsPrices.Price/ISNULL(&QueryTextPackagingFactor1,1)*ISNULL(&QueryTextPackagingFactor2,1)
		|	END ELSE 0.00 END AS NUMBER(25,2)) AS Percent,
		|	
		|	TemporaryTableOfGoods_.Package                       AS Package,
		|	TemporaryTableOfGoods_.OrderPackage                 AS OrderPackage,
		|	TemporaryTableOfGoods_.MinimumDeliveryLot      AS MinimumDeliveryLot,
		|	TemporaryTableOfGoods_.SettingConditions               AS SettingConditions
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|	
		|	LEFT JOIN
		|		PricesOfSupplierNomenclatureCrossSectionOfTheLatest AS ItemsPrices
		|			ON ItemsPrices.Products           = TemporaryTableOfGoods_.Products
		|			 AND ItemsPrices.Characteristic         = TemporaryTableOfGoods_.Characteristic
		|			 AND ItemsPrices.VendorPriceKind      = TemporaryTableOfGoods_.PriceKind
		|	
		|ORDER BY
		|	IndexOf
		|");
		
		TableOfGoods = Form.Object.Goods.Unload(); // ValueTable
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
	AddProducts_2(Form, TableOfGoods, DataCache);

	If TableOfGoods.Columns.Find("IndexOf") = Undefined Then
		TMCommonUse.NumberValueTable(TableOfGoods, "IndexOf");
	EndIf;
	
	Query.SetParameter("Goods", TableOfGoods);
	If SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode) Then
		Query.SetParameter("Date", BegOfDay(Form.Date) - 1);
	Else
		Query.SetParameter("Date", DateForRequestingProductPrices(Form));
	EndIf;

	If Not ThisIsVendorPriceRegistration Then
		TableOfProductsThatCannotBeEdited = GetProductsThatAreNotAllowedToBeEdited(Form, TableOfGoods);
		Query.SetParameter("ProductsThatCannotBeEdited", TableOfProductsThatCannotBeEdited);
	EndIf;
	
	QueryResult = Query.Execute();
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	UploadProductsToPriceTree(Form, SelectionOfProducts, DataCache);
	
	If Not ThisIsVendorPriceRegistration Then
		MarkModifiedFormulas(Form);
	EndIf;
	
EndProcedure

// Copies prices from a table-shaped Derivaten in a tabular part the Goods object
//
// Parameters:
// Parameters - Structure - Where:
//  * Form    - See BuildPriceTree.Form.
//  * SaveBasic - Boolean - indicates the need to place basic price types in the table part.
//
Procedure PutPricesInTablePart(Parameters) Export
	
	UsePriceManagementSystem25 = Parameters.Form.UsePriceManagementSystem25;
	
	TabularSections = New Array;
	
	If Not Parameters.Property("OnlyChangedItems") Then
		Parameters.Insert("OnlyChangedItems", False);
	EndIf;
	
	If TypeOf(Parameters.Documents) = Type("Array") Then
		For Each Document In Parameters.Documents Do
			If Parameters.Property("DetailsOfNewDocuments") Then
				FillPropertyValues(Document, Parameters.DetailsOfNewDocuments);
				If Not ThisIsVendorPriceRegistration(Parameters.Form) Then
					PutPriceTypesInTablePart(Parameters.Form, Document.TypesOfPrices, True);
				EndIf;
			EndIf;
			If UsePriceManagementSystem25 Then
				TabularSections.Add(Document.Goods2_5);
			Else
				TabularSections.Add(Document.Goods);
			EndIf;
		EndDo;
	Else
		If Parameters.Property("DetailsOfNewDocuments") Then
			FillPropertyValues(Parameters.Documents, Parameters.DetailsOfNewDocuments);
			If Not ThisIsVendorPriceRegistration(Parameters.Form) Then
				PutPriceTypesInTablePart(Parameters.Form, Parameters.Documents.TypesOfPrices, True);
			EndIf;
		EndIf;
		If UsePriceManagementSystem25 Then
			TabularSections.Add(Parameters.Documents.Goods2_5);
		Else
			TabularSections.Add(Parameters.Documents.Goods);
		EndIf;
		
	EndIf;
	
	For Each TabularSection In TabularSections Do
		TabularSection.Clear();
	EndDo;
	
	TypesOfPrices = New Array;
	For Each PriceKind In Parameters.Form.SelectedPrices Do
		If PriceKind.Selected_5 Or Parameters.SaveBasic And PriceKind.Influences Then
			TypesOfPrices.Add(PriceKind);
		EndIf;
	EndDo;
	Parameters.Insert("NumberOfPriceTypes", TypesOfPrices.Count());
	Parameters.Insert("TypesOfPrices",            TypesOfPrices);
	
	If TabularSections.Count() = 0 And Parameters.Property("DetailsOfNewDocuments") Then
		
		If ThisIsVendorPriceRegistration(Parameters.Form) Then
			Document = Documents.VendorPriceList.CreateDocument();
		Else
			Document = Documents.PriceSetup.CreateDocument();
		EndIf;
		
		FillPropertyValues(Document, Parameters.DetailsOfNewDocuments);
		
		If Not ThisIsVendorPriceRegistration(Parameters.Form) Then
			PutPriceTypesInTablePart(Parameters.Form, Document.TypesOfPrices, True);
		EndIf;
		
		Parameters.Documents.Add(Document);
		If UsePriceManagementSystem25 Then
			TabularSections.Add(Document.Goods2_5);
		Else
			TabularSections.Add(Document.Goods);
		EndIf;
		
	EndIf;
	Parameters.Insert("TabularSections", TabularSections);
	Parameters.Insert("RowsCount", 0);

	If CommonClientServer.HasAttributeOrObjectProperty(Parameters.Form,"Price_Table") 
		And TypeOf(Parameters.Form.Price_Table) = Type("ValueTable") Then
		
		Parameters.TabularSections[0].Load(Parameters.Form.Price_Table);
		
	Else
		
		PriceTreeIsDataTreeOfForm = (TypeOf(Parameters.Form.PriceTree) = Type("FormDataTree"));
		
		If Parameters.Form.GroupingOption = Enums.ItemFormNavigationOptions.ByHierarchy
			Or Parameters.Form.GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
			
			ProductItems_ = New Array;
			If PriceTreeIsDataTreeOfForm Then
				ProductsWithoutHierarchy(Parameters.Form.PriceTree.GetItems(),ProductItems_);
			Else
				ProductsWithoutHierarchy(Parameters.Form.PriceTree.Rows,ProductItems_);
			EndIf;
				
		EndIf; 
		
		AddRowToTablePart(PriceTreeIsDataTreeOfForm, 1, Parameters.Form.PriceTree, Parameters);
		
	EndIf;
	
EndProcedure

Procedure ProductsWithoutHierarchy(HierarchyRows,RowsArray)
	
	For Each HierarchyLine In HierarchyRows Do
		If HierarchyLine.ThisIsHierarchy Then
			If TypeOf(HierarchyLine) = Type("FormDataTreeItem") Then
				ProductsWithoutHierarchy(HierarchyLine.GetItems(),RowsArray)
			ElsIf TypeOf(HierarchyLine) = Type("ValueTreeRow") Then
				ProductsWithoutHierarchy(HierarchyLine.Rows,RowsArray)
			EndIf;
		Else
			RowsArray.Add(HierarchyLine);
		EndIf; 
	EndDo; 
	
EndProcedure

// Returns the unique name of the price tree column by reference to the price view
//
// Parameters:
//  PriceKind - CatalogRef.TypesOfPrices - Link to the price view
//  DataCache - See InitializeDataCacheStructure
//
// Returns:
//  String - The name of the price type column.
//
Function ColumnNameByPriceType(PriceKind, DataCache) Export
	
	Value = DataCache.MatchingPriceTypesToColumnNamesInProductTable.Get(PriceKind);
	If Value = Undefined Then
		Value = "PriceKind" + StrReplace(PriceKind.UUID(), "-", "");
		DataCache.MatchingPriceTypesToColumnNamesInProductTable.Insert(PriceKind, Value);
	EndIf;
	
	Return Value;
	
EndFunction

// Searches for a line in the price tree by fields (Item, Characteristic).
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  IncomingSearchData - Structure, QueryResultSelection - incoming search parameters
//  DataCache - See InitializeDataCacheStructure
//  UpdateComplianceTable - Boolean - True, if the line is not found, the table may be outdated, you need to try to update it
//
// Returns:
//  ValueTreeRow, FormDataCollectionItem - the found line of the price tree.
//
Function FindPriceTreeString(Form, IncomingSearchData, DataCache, UpdateComplianceTable = True) Export
	
	SearchData_ = New Structure;
	SearchData_.Insert("ProductKind");
	SearchData_.Insert("Products");
	SearchData_.Insert("Characteristic");
	SearchData_.Insert("PartnerProducts");
	SearchData_.Insert("PricingVariant");
	SearchData_.Insert("PricingBatch");
	SearchData_.Insert("PricingPackage");
	SearchData_.Insert("ProductKind");

	FillPropertyValues(SearchData_, IncomingSearchData);
	
	If DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree = Undefined Then
		ComplianceTable(Form, DataCache);
	EndIf;
	
	If ThisIsVendorPriceRegistration(Form, DataCache) Then
		
		Filter = New Structure;
		Filter.Insert("Products", SearchData_.Products);
		Filter.Insert("Characteristic", SearchData_.Characteristic);
		
		If Form.UsePartnersProducts
			And ValueIsFilled(SearchData_.PartnerProducts) Then
			
			Filter.Insert("PartnerProducts", SearchData_.PartnerProducts);
			
		EndIf;
		
	Else
		If Form.UsePriceManagementSystem25 Then
			Filter = New Structure(
				"Products, PricingVariant, PricingBatch, PricingPackage",
				SearchData_.Products, 
				?(Form.UseItemVariants And ValueIsFilled(SearchData_.PricingVariant), SearchData_.PricingVariant, Catalogs.ItemsCharacteristicsForPricing.EmptyRef()),
				?(Form.UseItemsBatch And ValueIsFilled(SearchData_.PricingBatch), SearchData_.PricingBatch, Catalogs.ItemsBatchesForPricing.EmptyRef()),
				?(Form.UseItemPackages And ValueIsFilled(SearchData_.PricingPackage), SearchData_.PricingPackage, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef())
				);
			
		Else
			If Form.UseItemVariants Then
				Filter = New Structure(
					"Products, Characteristic",
					SearchData_.Products, SearchData_.Characteristic);
			Else
				Filter = New Structure(
					"Products, Characteristic",
					SearchData_.Products, Catalogs.ItemsCharacteristics.EmptyRef());
			EndIf;
		EndIf;

		If Form.GroupingOption = Enums.ItemFormNavigationOptions.ByKinds
			And ValueIsFilled(SearchData_.ProductKind) Then
			
			Filter.Insert("ProductKind", SearchData_.ProductKind);
			
		EndIf; 
	EndIf;
	
	Return ReturnFoundPriceTreeString(Form, DataCache, Filter, UpdateComplianceTable);
	
EndFunction

Function ReturnFoundPriceTreeString(Form, DataCache, Filter, Val UpdateComplianceTable)

	FoundRow = Undefined;
	
	RowsArray = DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.FindRows(Filter);
	If RowsArray.Count() > 0 Then
		If (TypeOf(Form.PriceTree) = Type("FormDataTree")) Then
			FoundRow = Form.PriceTree.FindByID(RowsArray[0].RowID);
		Else
			FoundRow = RowsArray[0].PriceTreeString;
		EndIf;
	EndIf;

	If FoundRow = Undefined And UpdateComplianceTable Then
		ComplianceTable(Form, DataCache, True);
		Return ReturnFoundPriceTreeString(Form, DataCache, Filter, False);
	Else
		Return FoundRow;
	EndIf;
EndFunction

//Saves the selected price types to a table of values
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ForEditing - Boolean
//
// Returns:
//  ValueTable - See InitializeTableOfSelectedPrices
//
Function SelectedTypesOfPricesInTable(Form, ForEditing = False) Export
	
	TypesOfPrices = InitializeTableOfSelectedPrices();
	
	For Each CurRow In Form.SelectedPrices Do
		If (Not ForEditing And CurRow.Selected_5)
			Or (ForEditing And CurRow.Edit) Then
			RowNew_ = TypesOfPrices.Add();
			RowNew_.PriceKind = CurRow.Ref;
			RowNew_.AddlOrderingAttribute = CurRow.AddlOrderingAttribute;
		EndIf;
	EndDo;
	
	Return TypesOfPrices;
	
EndFunction

//Initializes a table of values for the selected prices
//
// Returns:
//  ValueTable - Table for storing selected prices
//
Function InitializeTableOfSelectedPrices() Export
	
	TableOfSelectedPriceTypes = New ValueTable();
	TableOfSelectedPriceTypes.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfSelectedPriceTypes.Columns.Add("AddlOrderingAttribute", New TypeDescription("Number"));
	
	Return TableOfSelectedPriceTypes;
EndFunction

// Returns price types that depend on the specified price type
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  PriceTypeLine - FormDataCollectionItem - A row in the Selected Prices table.
//
// Returns:
//  Array of CatalogRef.TypesOfPrices - Dependent types of prices
//
Function DependentOnTypeOfPriceTypesOfPrices(Form, PriceTypeLine) Export
	
	DependentTypesOfPrices = New ValueTable;
	DependentTypesOfPrices.Columns.Add("PriceKind");
	DependentTypesOfPrices.Columns.Add("AddlOrderingAttribute");
	
	For Each DependentPrice In PriceTypeLine.DependentPrices Do
		DependentPriceLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, DependentPrice.Value);
		If DependentPriceLine <> Undefined 
			And DependentPriceLine.Selected_5 
			And DependentPriceLine.Edit Then
			NewRow = DependentTypesOfPrices.Add();
			NewRow.PriceKind = DependentPriceLine;
			NewRow.AddlOrderingAttribute = Form.SelectedPrices.IndexOf(DependentPriceLine);
		EndIf;
	EndDo;
	
	FillIn = True;
	While FillIn Do
		
		FillIn = False;
		For Each CurRow In DependentTypesOfPrices Do
			
			For Each DependentPrice In CurRow.PriceKind.DependentPrices Do
				DependentPriceLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, DependentPrice.Value);
				If DependentPriceLine <> Undefined 
					And DependentPriceLine.Selected_5 
					And DependentPriceLine.Edit 
					And DependentTypesOfPrices.Find(DependentPriceLine, "PriceKind") = Undefined Then
					
					NewRow = DependentTypesOfPrices.Add();
					NewRow.PriceKind = DependentPriceLine;
					NewRow.AddlOrderingAttribute = Form.SelectedPrices.IndexOf(DependentPriceLine);
					
					FillIn = True;
				EndIf;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	DependentTypesOfPrices.Sort("AddlOrderingAttribute Asc");
	
	Return DependentTypesOfPrices.UnloadColumn("PriceKind");
	
EndFunction

// Handler for Changing the price tree
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  RowID - Number
//  CurColumnName - String
//  CheckString - String - packaging unit or currency
//
Procedure PriceTreePackageCurrencyOnChange(Form, RowID, CurColumnName, CheckString = "Package") Export
	
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Form);
	CurrentRow = Form.PriceTree.FindByID(RowID);
	
	If CheckString = "Package" 
		And ThisIsVendorPriceRegistration
		And Not ValueIsFilled(CurrentRow.PartnerProducts) Then
		
		Data = New Structure;
		Data.Insert("PartnerProducts", CurrentRow.PartnerProducts);
		Data.Insert("Products", CurrentRow.Products);
		Data.Insert("Characteristic", CurrentRow.Characteristic);
		Data.Insert("Package", CurrentRow[CurColumnName]);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Form.Object.Partner);
		BatchProcessingOfTablePartServer.ProcessTSString(Data, StructureOfActions, Undefined);
		
		FillPropertyValues(CurrentRow, Data, "PartnerProducts");
		
	EndIf;
	
	AddCurrentLine = False;
	ThereAreSubordinateLines = False;
	If Not ThisIsVendorPriceRegistration Then
		SubordinateRows = CurrentRow.GetItems();
		ThereAreSubordinateLines = SubordinateRows.Count() > 0;
	EndIf;
	
	AddCurrentLine = ThisIsVendorPriceRegistration 
								Or CurrentRow.PictureIndex = 2
								Or (CurrentRow.PictureIndex = 0 And Not ThereAreSubordinateLines);

	If AddCurrentLine And StrFind(CurColumnName, CheckString) > 0 Then
		
		ColumnNamePriceType = StrReplace(CurColumnName, CheckString, "");
		
		CurrentRow["ChangedManually"       + ColumnNamePriceType] = True;
		CurrentRow["ChangedAutomatically" + ColumnNamePriceType] = False;
		
	EndIf;
	
	// Loading old prices and percentage changes
	ValueTable = CreateProductsTable(ThisIsVendorPriceRegistration, Form.UsePriceManagementSystem25);
	For Each PriceTypeLine In Form.SelectedPrices Do
		
		If PriceTypeLine.Selected_5
			Or PriceTypeLine.Influences Then
			
			ColumnName = PriceTypeLine.ColumnName;
			ColumnNamePackaging = "Package" + ColumnName;
			ColumnNameCurrency = "Currency" + ColumnName;
			NameOfEditBanColumn = "NoEditingAllowed" + ColumnName;
			
			If Not ThisIsVendorPriceRegistration And CurrentRow[NameOfEditBanColumn] Then
				Continue
			EndIf;
			
			If AddCurrentLine Then
				NewRow = ValueTable.Add();
				FillPropertyValues(NewRow, CurrentRow);
				NewRow.PriceKind        = PriceTypeLine.Ref;
				NewRow.Price           = CurrentRow[ColumnName];
				If Form.UseItemPackages Then
					NewRow.Package   = CurrentRow[ColumnNamePackaging];
				EndIf;
				If CheckString = "Currency" Then
					NewRow.Currency     = CurrentRow[ColumnNameCurrency];
				EndIf;
			EndIf;
			
			If ThereAreSubordinateLines Then
				For Each SubordinateRow In SubordinateRows Do
					If SubordinateRow[NameOfEditBanColumn] Then
						Continue
					EndIf;
					
					NewRow = ValueTable.Add();
					FillPropertyValues(NewRow, SubordinateRow);
					NewRow.PriceKind        = PriceTypeLine.Ref;
					NewRow.Price           = SubordinateRow[ColumnName];
					If Form.UseItemPackages Then
						NewRow.Package   = CurrentRow[ColumnNamePackaging];
					EndIf;
					If CheckString = "Currency" Then
						NewRow.Currency     = CurrentRow[ColumnNameCurrency];
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	DataCache = InitializeDataCacheStructure();
	
	LoadOldPricesOfProducts(Form, ValueTable, DataCache);
	
	If Not ThisIsVendorPriceRegistration Then
		If Form.UsePriceManagementSystem25 Then
			CalculatePricesByRowId2_5(Form, RowID, , CurColumnName, DataCache);
		Else	
			CalculatePricesByRowId(Form, RowID,, CurColumnName, DataCache);
		EndIf;
	EndIf;
	
EndProcedure

// Handler for Changing the price tree
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  RowID - Number
//  CurColumnName - String
//
Procedure PriceTreeOrderPackagingWhenChanged(Form, RowID, CurColumnName) Export
	
	CurrentRow = Form.PriceTree.FindByID(RowID);
	
	StringPacking = "OrderPackage";
	If StrFind(CurColumnName, StringPacking) > 0 Then
		
		ColumnNamePriceType    = StrReplace(CurColumnName, StringPacking, "");
		
		CurrentRow["ChangedManually"       + ColumnNamePriceType] = True;
		CurrentRow["ChangedAutomatically" + ColumnNamePriceType] = False;
		CurrentRow["SettingConditions"      + ColumnNamePriceType] = True;
		
		If CurrentRow[ColumnNamePriceType] = 0 Then
			CurrentRow[ColumnNamePriceType] = CurrentRow["OldPrice" + ColumnNamePriceType];
		EndIf;
		
	EndIf;
	
	For Each SubordinateRow In CurrentRow.GetItems() Do
		
		If SubordinateRow[CurColumnName] <> CurrentRow[CurColumnName] Then
			
			SubordinateRow[CurColumnName] = CurrentRow[CurColumnName];
			SubordinateRow["ChangedManually"       + ColumnNamePriceType] = True;
			SubordinateRow["ChangedAutomatically" + ColumnNamePriceType] = False;
			SubordinateRow["SettingConditions"      + ColumnNamePriceType] = True;
			
			If SubordinateRow[ColumnNamePriceType] = 0 Then
				SubordinateRow[ColumnNamePriceType] = SubordinateRow["OldPrice" + ColumnNamePriceType];
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Handler for Changing the price tree
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  RowID - Number
//  CurColumnName - String
//
Procedure PriceTreeMinimumBatchWhenModified(Form, RowID, CurColumnName) Export
	
	CurrentRow = Form.PriceTree.FindByID(RowID);
	
	StringPacking = "MinimumDeliveryLot";
	If StrFind(CurColumnName, StringPacking) > 0 Then
		
		ColumnNamePriceType    = StrReplace(CurColumnName, StringPacking, "");
		
		CurrentRow["ChangedManually"       + ColumnNamePriceType] = True;
		CurrentRow["ChangedAutomatically" + ColumnNamePriceType] = False;
		CurrentRow["SettingConditions"      + ColumnNamePriceType] = True;
		
		If CurrentRow[ColumnNamePriceType] = 0 Then
			CurrentRow[ColumnNamePriceType] = CurrentRow["OldPrice" + ColumnNamePriceType];
		EndIf;
		
	EndIf;
	
	For Each SubordinateRow In CurrentRow.GetItems() Do
		
		If SubordinateRow[CurColumnName] <> CurrentRow[CurColumnName] Then
			
			SubordinateRow[CurColumnName] = CurrentRow[CurColumnName];
			SubordinateRow["ChangedManually"       + ColumnNamePriceType] = True;
			SubordinateRow["ChangedAutomatically" + ColumnNamePriceType] = False;
			SubordinateRow["SettingConditions"      + ColumnNamePriceType] = True;
			
			If SubordinateRow[ColumnNamePriceType] = 0 Then
				SubordinateRow[ColumnNamePriceType] = SubordinateRow["OldPrice" + ColumnNamePriceType];
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks whether the required parameters of data layout schemes are filled in for the selected price types.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  ReportErrorsToUser_ - Boolean - Issue a message to the user about each error found.
//
// Returns:
//  Boolean - Errors in filling in required parameters were found.
//
Function RequiredDataLayoutSchemaParametersFilledIn(Form, ReportErrorsToUser_ = True) Export
	
	TypesOfPrices = New Array;
	For Each PriceTypeLine In Form.SelectedPrices Do
		If PriceTypeLine.Selected_5 And PriceTypeLine.RequiredParametersAreFound Then
			TypesOfPrices.Add(PriceTypeLine.Ref);
		EndIf;
	EndDo;
	Errors = PriceSetupServerCall.CheckWhetherRequiredDataLayoutSchemaParametersAreFull(
		TypesOfPrices,
		Form.StorageAddressDataLayoutSettings,
		Form.AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
	If ReportErrorsToUser_ Then
		For Each ErrorStructure In Errors Do
			PriceTypeLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, ErrorStructure.PriceKind);
			
			If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Ref") Then
				CommonClientServer.MessageToUser(
					ErrorStructure.LongDesc,
					Form.Object.Ref,
					"SelectedPrices[" + Form.SelectedPrices.IndexOf(PriceTypeLine) + "].Parameters");
			Else
				CommonClientServer.MessageToUser(
					ErrorStructure.LongDesc,
					,
					"SelectedPrices[" + Form.SelectedPrices.IndexOf(PriceTypeLine) + "].Parameters");
			EndIf;
			
		EndDo;
	EndIf;
	
	Return Errors.Count() = 0;
	
EndFunction

// Checks whether the price setting document is filled in correctly
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  Cancel - Boolean - flag for refusing to write a document
//
Procedure CheckCorrectnessOfDocument(Form, Cancel) Export
	
	// For the correct construction of the price table for PM Goods, there should be no duplicates of goods and empty lines.
	PriceTreeToCheck = CreateProductTable(Form);
	PriceTreeToCheck.Columns.Add("LineNumber",    New TypeDescription("Number"));
	PriceTreeToCheck.Columns.Add("IsFolder",      New TypeDescription("Boolean"));
	
	ProductItems_ = Form.PriceTree.GetItems();
	LineNumber = 1;
	
	For Each CurElementProducts In ProductItems_ Do
		
		TableRow = PriceTreeToCheck.Add();
		FillPropertyValues(TableRow, CurElementProducts);
		TableRow.LineNumber = LineNumber;
		TableRow.IsFolder   = True;
		
		LineNumber = LineNumber + 1;
		
		If CurElementProducts.ItemVariantsAreUsed Then
			
			AddedFeatures = False;
			
			FeatureElements = CurElementProducts.GetItems();
			For Each CurElementCharacteristic In FeatureElements Do
				
				RowOfCharacteristicTable = PriceTreeToCheck.Add();
				FillPropertyValues(RowOfCharacteristicTable, CurElementCharacteristic);
				RowOfCharacteristicTable.LineNumber = LineNumber;
				RowOfCharacteristicTable.IsFolder   = False;
				
				LineNumber = LineNumber + 1;
				
				AddedFeatures = True;
				
			EndDo;
			
			If Not AddedFeatures Then
				ErrorText = NStr("vi = 'Đối với mặt hàng ""%1"" trong dòng %2 của danh sách ""Bảng đơn giá"" có bật sử dụng đặc tính, nhưng chưa chỉ ra đặc tính nào. Hãy thêm đặc tính và chỉ ra đơn giá hoặc xóa mặt hàng này khỏi danh sách.';
								|ru = 'Для номенклатуры ""%1"" в строке %2 списка ""Таблица цен"" включено использование характеристик, но характеристики не указаны. Добавьте характеристики и укажите их цены или удалите данную номенклатуру из списка.';
								|en = 'Variants are enabled for the ""%1"" item in line %2 of the ""Price table"" list, but variants are not specified. Add variants and specify their prices, or delete this item from the list.'; fa = 'Variants are enabled for the ""%1"" item in line %2 of the ""Price table"" list, but variants are not specified. Add variants and specify their prices, or delete this item from the list.';
								|it = 'Для номенклатуры ""%1"" в строке %2 списка ""Таблица цен"" включено использование характеристик, но характеристики не указаны. Добавьте характеристики и укажите их цены или удалите данную номенклатуру из списка.';
								|pl = 'Variants are enabled for the ""%1"" item in line %2 of the ""Price table"" list, but variants are not specified. Add variants and specify their prices, or delete this item from the list.';
								|tr = '""Fiyat Tablosu"" listesinin %2 satırındaki ""%1"" ürünü için varyantların kullanımı etkinleştirilmiş ancak varyant belirtilmemiş. Varyantları ekle ve fiyatlarını belirt veya bu ürünü listeden kaldır.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, TableRow.Products, Format(TableRow.LineNumber, "NG="));
				
				If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Ref") Then
					CommonClientServer.MessageToUser(
						ErrorText,
						Form.Object.Ref,
						CommonClientServer.PathToTabularSection("PriceTree", TableRow.LineNumber, "Products"),
						,
						Cancel);
				Else
					CommonClientServer.MessageToUser(
						ErrorText,
						,
						CommonClientServer.PathToTabularSection("PriceTree", TableRow.LineNumber, "Products"),
						,
						Cancel);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If PriceTreeToCheck.Count() > 0 Then
		If ThisIsVendorPriceRegistration(Form) Then
			
			DataCache = Undefined;
			GoodsTable = GoodsTable(Form, DataCache);
			TMCommonUse.NumberValueTable(GoodsTable, "LineNumber");
			
			PriceManagementSystem.CheckCorrectnessOfFillingInSupplierProductPriceSettingDocument(
				Form.Object, GoodsTable, Cancel);
			
		Else
			PriceManagementSystem.CheckCorrectnessOfProductPriceSettingDocument(
				Form.Object, PriceTreeToCheck, SettingPricesClientServer.SelectedTypesOfPrices(Form), Form.UsePriceManagementSystem25, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

// Saves the setting of the order of the supplier's price types.
//
// Parameters:
//  Form - See BuildPriceTree.Form
// Returns:
// 	Boolean - True - the elements are blocked
Function SaveSettingsForOrderOfSupplierPriceTypes(Form) Export
	
	IndexOf = 1;
	ItemsAreLocked = True;
	For Each TSRow In Form.SelectedPrices Do
		If TSRow.AddlOrderingAttribute <> IndexOf Then
			Try
				LockDataForEdit(TSRow.Ref,,Form.UUID);
			Except
				ItemsAreLocked = False;
				Break;
			EndTry;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	If ItemsAreLocked Then
		For Each TSRow In Form.SelectedPrices Do
			If TSRow.AddlOrderingAttribute <> IndexOf Then
				ItemPriceType = TSRow.Ref.GetObject();
				ItemPriceType.AddlOrderingAttribute = IndexOf;
				ItemPriceType.Write();
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
	EndIf;
	
	Return ItemsAreLocked;
	
EndFunction

// Clear the saved documents array.
//
// Parameters:
//  SavedDocuments - ValueTable - Save the document:
//     							* Ref - DocumentRef
//  					 - Array of DocumentRef - Save the document
//  FormIdentifier - UUID - the ID of the form.
//  DeleteDocuments - Boolean - If true, then delete the documents. If False, then unblock for editing.
//
Procedure ClearSavedDocuments(SavedDocuments, FormIdentifier, DeleteDocuments = False) Export
	
	For Each TSRow In SavedDocuments Do
		If Not DeleteDocuments Then
			UnlockDataForEdit(TSRow.Ref, FormIdentifier);
		Else
			DocumentObject = TSRow.Ref.GetObject();
			DocumentObject.Delete();
		EndIf;
	EndDo;
	
	SavedDocuments.Clear();
	
EndProcedure

// Searches for a row with a certain type of price in the tree
//
// Parameters:
//  Tree - ValueTree - The tree in which the search is performed
//  PriceKind - CatalogRef.TypesOfPrices - Link to the type of prices to find.
//
// Returns:
//  ValueTreeRow - the found type of price
//
Function FindPriceTypeStringInTree(Tree, PriceKind) Export
	
	TreeRow = Undefined;
	
	FoundRows = Tree.Rows.FindRows(New Structure("Ref", PriceKind),True);
	
	If FoundRows.Count()>0 Then
		TreeRow = FoundRows[0];
	EndIf;
	
	Return TreeRow;
	
EndFunction

Procedure AddProductsByDCSSelection(Form, ThisIsAutoUpdateOfPrices = False) Export
	
	Form.AddressOfDataCacheStorage = "";
	DataCache = InitializeDataCacheStructure();

	SetPrivilegedMode(True);
	
	DataLayoutSettingsTable = GetFromTempStorage(Form.StorageAddressDataLayoutSettings);

	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	TempTablesManager = Undefined;
	PlaceEmptyTableInTemporaryTableManager(TempTablesManager);
	
	For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(Form) Do
	
		// Copying the data layout scheme
		Schema = New ValueStorage(GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchema));
		DataCompositionSchema = Schema.Get();
	
		FoundRow = DataLayoutSettingsTable.Find(PriceTypeLine.Ref);
		If FoundRow <> Undefined Then
			DataCompositionSettings = FoundRow.DataCompositionSettings;
		Else
			
			If ValueIsFilled(PriceTypeLine.AddressOfDataCompositionSchemaSettings) Then
				DataCompositionSettings = GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchemaSettings);
			Else
				DataCompositionSettings = Undefined;
			EndIf;
			
		EndIf;
		
		If UsePriceManagementSystem25 And ThisIsAutoUpdateOfPrices Then
			
			DCSCheckPassed2_5 = PriceManagementSystem.CheckDataLayoutSchemeForRequiredFields(
				DataCompositionSchema,
				PriceSetupServerCall.GetRequiredDataLayoutSchemaFields(True),,
				False
			);
			
		Else
			DCSCheckPassed2_5 = False;
		EndIf;
		
		If PriceManagementSystem.CheckDataLayoutSchemeForRequiredFields(
			DataCompositionSchema,
			PriceSetupServerCall.GetRequiredDataLayoutSchemaFields(),
			StrReplace(NStr("vi = 'Dạng giá ""%PriceKind%""';
							|ru = 'Вид цены ""%PriceKind%""';
							|en = 'Price type ""%PriceKind%""'; fa = 'Price type ""%PriceKind%""';
							|it = 'Tipo di prezzo ""%PriceKind%""';
							|pl = 'Rodzaj ceny ""%PriceKind%""';
							|tr = 'Fiyat türü ""%PriceKind%""'"), "%PriceKind%", PriceTypeLine.Ref)) Then
			
			// Preparing a data layout layout builder, loading settings
			SettingsComposer = New DataCompositionSettingsComposer;
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
			
			If DataCompositionSettings <> Undefined Then
				SettingsComposer.LoadSettings(DataCompositionSettings);
				SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
			Else
				SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
			EndIf;
			
			// Filling in the report structure and selected fields.
			SettingsComposer.Settings.Structure.Clear();
			
			DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
			DetailedRecordsGroup.Use = True;
			
			SettingsComposer.Settings.Selection.Items.Clear();
			AddSelectedDCSField(DetailedRecordsGroup, "Products");
			
			If UsePriceManagementSystem25 And DCSCheckPassed2_5 Then

				If Form.UseItemVariants Then
					AddSelectedDCSField(DetailedRecordsGroup, "Characteristic");
					AddSelectedDCSField(DetailedRecordsGroup, "PricingVariant");
				EndIf;
				
				If Form.UseItemsBatch Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingBatch");
					AddSelectedDCSField(DetailedRecordsGroup, "TSOSeriesForCommunication");
				EndIf;
				
				If Form.UseItemPackages Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingPackage");
					AddSelectedDCSField(DetailedRecordsGroup, "TsoPackagingForCommunication");
				EndIf;
				
			Else
				
				If Form.UseItemVariants Then
					AddSelectedDCSField(DetailedRecordsGroup, "Characteristic");
				EndIf;
				
			EndIf;
			
			WorkingDataset = DataCompositionSchema.DataSets[0];
				
			QueryText = WorkingDataset.Query;
			
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor1", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package", 
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
			
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor2", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"DocumentGoods.Package", 
					"DocumentGoods.Products"));
					
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor3", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"GoodsDocumentInputBasedOn.Package", 
					"GoodsDocumentInputBasedOn.Products"));
				
			WorkingDataset.Query = QueryText;
			
			LayoutOptions = SettingsComposer.Settings.DataParameters.Items;

			Parameter = LayoutOptions.Find("Basis");
			If Parameter <> Undefined Then
				Parameter.Value = Form.Object.DocumentBasis;
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			
			Parameter = LayoutOptions.Find("DocumentDate");
			If Parameter <> Undefined Then
				Parameter.Value = DateForRequestingProductPrices(Form);
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			
			Parameter = LayoutOptions.Find("PriceKind");
			If Parameter <> Undefined Then
				Parameter.Value = PriceTypeLine.Ref;
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			
			Parameter = LayoutOptions.Find("ThisIsGenerationFromBaseDocuments");
			If Parameter <> Undefined Then
				Parameter.Value = ValueIsFilled(Form.Object.DocumentBasis);
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			
			Parameter = LayoutOptions.Find("ExcludedBusinessTransactions");
			If Parameter <> Undefined Then
				Parameter.Value = CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements();
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;

			// Layout layout and query execution.
			TemplateComposer = New DataCompositionTemplateComposer;
			SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
			CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
			
			CompositionProcessor = New DataCompositionProcessor;
			CompositionProcessor.Initialize(CompositionTemplate,,,True,, TempTablesManager);
			OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

			ReportData = New ValueTable();
			OutputProcessor.SetObject(ReportData);
			ReportData = OutputProcessor.Output(CompositionProcessor);
			
			If UsePriceManagementSystem25 Then
				
				If DCSCheckPassed2_5 Then
					
					ProductsTable = SettingPricesServer.CreateProductTable(Form);
					CommonClientServer.SupplementTable(ReportData, ProductsTable);
					SettingPricesServer.AddGoodsByPicking(Form, Undefined, ProductsTable,, DataCache);
					
				Else
					
					FilterValues = New Structure();
					FilterValues.Insert("ByArrayOfProducts", ReportData.UnloadColumn("Products"));
					
					Filter_Settings = SettingPricesServer.GetStructureOfDataSelectionByProduct();
					Filter_Settings.Insert("FilterValues", FilterValues);
					Filter_Settings.Insert("Value", );
					Filter_Settings.Insert("Date", CurrentSessionDate());
					
					FillPropertyValues(Filter_Settings, Form,"UsePriceManagementSystem25, UseItemVariants, UseItemsBatch, UseItemPackages");
					
					ProductsTable = SettingPricesServer.CreateProductTable(Form);
					SettingPricesServer.GetDataOnProducts(Filter_Settings, ProductsTable); // adding data on the nomenclature with data on pricing sections
					SettingPricesServer.AddGoodsByPicking(Form, Undefined, ProductsTable,, DataCache);
					
				EndIf;
				
			Else
				
				If ReportData.Columns.Find("Characteristic") = Undefined Then
					ReportData.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
				EndIf;
				
				SettingPricesServer.AddGoodsByPicking(Form, Undefined, ReportData,, DataCache);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddProductsToResetPricesForDCSSelections(Form) Export
	
	SetPrivilegedMode(True);
	
	For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(Form) Do
		If Not ValueIsFilled(PriceTypeLine.AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem) Then
			Continue;
		EndIf;
	
		// Copying the data layout scheme
		TemplateParameters1 = Catalogs.TypesOfPrices.InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName();
		TemplateParameters1.Ref 		= PriceTypeLine.Ref;
		If Form.UsePriceManagementSystem25 Then
			TemplateParameters1.TemplateName 	= "CurrentEnterprisePricesPredefined2_5";
		Else
			TemplateParameters1.TemplateName 	= "CurrentEnterprisePricesPredefined";
		EndIf;
		
		SchemeAndSettings = Catalogs.TypesOfPrices.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema; 
		DataCompositionSettings = GetFromTempStorage(PriceTypeLine.AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem);//DataCompositionSettings
		
		If DataCompositionSettings.Filter.Items.Count() > 0 Then
			
			// Preparing a data layout layout builder, loading settings
			SettingsComposer = New DataCompositionSettingsComposer;
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
			
			SettingsComposer.LoadSettings(DataCompositionSettings);
			// let's add the grouping "NOT", because we need to select those that are not included in the selection
			InvertSelection(DataCompositionSettings, SettingsComposer);
			SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
			
			// Filling in the report structure and selected fields.
			SettingsComposer.Settings.Structure.Clear();
			
			DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
			DetailedRecordsGroup.Use = True;
			
			SettingsComposer.Settings.Selection.Items.Clear();
			SettingPricesServer.AddSelectedDCSField(DetailedRecordsGroup, "Products");

			If Form.UsePriceManagementSystem25 Then
				If Form.UseItemVariants Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingVariant");
				EndIf;
				
				If Form.UseItemsBatch Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingBatch");
				EndIf;
				
				If Form.UseItemPackages Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingPackage");
					AddSelectedDCSField(DetailedRecordsGroup, "Package");
				EndIf;
				
			Else
					
				If GetFunctionalOption("UseItemVariants") Then
					SettingPricesServer.AddSelectedDCSField(DetailedRecordsGroup, "Characteristic");
				EndIf;
				
			EndIf;
			
			WorkingDataset = DataCompositionSchema.DataSets[0];
				
			QueryText = WorkingDataset.Query;
			
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor1", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package", 
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
			
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor2", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"DocumentGoods.Package", 
					"DocumentGoods.Products"));
					
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor3", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"GoodsDocumentInputBasedOn.Package", 
					"GoodsDocumentInputBasedOn.Products"));
				
			WorkingDataset.Query = QueryText;
			
			LayoutOptions = SettingsComposer.Settings.DataParameters.Items;
			
			Parameter = LayoutOptions.Find("DocumentDate");
			If Parameter <> Undefined Then
				Parameter.Value = DateForRequestingProductPrices(Form);
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			Parameter = LayoutOptions.Find("PriceKind");
			If Parameter <> Undefined Then
				Parameter.Value = PriceTypeLine.Ref;
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;

			// Layout layout and query execution.
			TemplateComposer = New DataCompositionTemplateComposer;
			SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
			CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
			
			CompositionProcessor = New DataCompositionProcessor;
			CompositionProcessor.Initialize(CompositionTemplate,,,True);
			OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

			ReportData = New ValueTable();
			OutputProcessor.SetObject(ReportData);
			ReportData = OutputProcessor.Output(CompositionProcessor);
			
			If Form.UsePriceManagementSystem25 Then
				
				If ReportData.Columns.Find("PricingVariant") = Undefined Then
					ReportData.Columns.Add("PricingVariant", New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
				EndIf;
				
				If ReportData.Columns.Find("PricingBatch") = Undefined Then
					ReportData.Columns.Add("PricingBatch", New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
				EndIf;
				
				If ReportData.Columns.Find("PricingPackage") = Undefined Then
					ReportData.Columns.Add("PricingPackage", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
				EndIf;
				
			Else
					
				If ReportData.Columns.Find("Characteristic") = Undefined Then
					ReportData.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
				EndIf;
				
			EndIf;
			
			SettingPricesServer.AddGoodsByPicking(Form, Undefined, ReportData);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns data for an item that is not allowed to be edited in the price list
// 
// Parameters:
//  ShapeStructure - Structure - advanced setting
//  ProductsTable - ValueTable - item data
// 
// Returns:
//  ValueTable - data on the item for which it is forbidden to edit data:
// * Products - CatalogRef.Products -
// * PricingVariant - CatalogRef.ItemsCharacteristicsForPricing -
// * PricingBatch - CatalogRef.ItemsBatchesForPricing -
// * PricingPackage - CatalogRef.PackagesAndUnitsOfMeasure -
// * Characteristic - CatalogRef.ItemsCharacteristics -
// * PriceKind - CatalogRef.TypesOfPrices -
Function GetProductsThatAreNotAllowedToBeEdited(
										 ShapeStructure,
										 ProductsTable
										) Export
	
	TableOfProductsThatCannotBeEdited = New ValueTable();
	TableOfProductsThatCannotBeEdited.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	If ShapeStructure.UsePriceManagementSystem25 Then	
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingVariant", New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingBatch", New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		TableOfProductsThatCannotBeEdited.Columns.Add("PricingPackage", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Else			
		TableOfProductsThatCannotBeEdited.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	TableOfProductsThatCannotBeEdited.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	
	For Each PriceTypeLine In ShapeStructure.SelectedPrices Do
		If (PriceTypeLine.Selected_5 Or PriceTypeLine.Influences)
			And PriceTypeLine.DisablePriceEditingOutsideFilter Then
	
			If ShapeStructure.UsePriceManagementSystem25 Then	
				TableOfPricesProhibitedForEditingByType = GetTableOfProhibitedProducts2_5(ShapeStructure, ProductsTable, PriceTypeLine);
			Else
				TableOfPricesProhibitedForEditingByType = GetTableOfProhibitedProducts(ShapeStructure, ProductsTable, PriceTypeLine);
			EndIf;
			If TableOfPricesProhibitedForEditingByType <> Undefined Then
				For Each SourceRow In TableOfPricesProhibitedForEditingByType Do
					DestinationRow = TableOfProductsThatCannotBeEdited.Add();
					DestinationRow.PriceKind	= PriceTypeLine.Ref;
					FillPropertyValues(DestinationRow, SourceRow);
				EndDo;
			EndIf;
			
		EndIf;
	EndDo;
	
	Return TableOfProductsThatCannotBeEdited;
	
EndFunction

// Get the structure of data selection by Product.
// 
// Returns:
//  Structure - Get The Structure Of Data Selection By Product:
// * FilterValues 
// * Date 
// * UsePriceManagementSystem25 
// * UseItemVariants 
// * UseItemsBatch 
// * UseItemPackages 
Function GetStructureOfDataSelectionByProduct() Export
	Filter_Settings = New Structure();
	Filter_Settings.Insert("FilterValues");
	Filter_Settings.Insert("Date");
	Filter_Settings.Insert("UsePriceManagementSystem25");
	Filter_Settings.Insert("UseItemVariants");
	Filter_Settings.Insert("UseItemsBatch");
	Filter_Settings.Insert("UseItemPackages");
	
	Return Filter_Settings;
EndFunction

Procedure GetDataOnProducts(Filter_Settings, ProductsTable) Export

	SettingsStructure = New Structure;
	SettingsStructure.Insert("RequiredFields"   , New Array);
	SettingsStructure.Insert("DataParameters"    , New Structure);
	SettingsStructure.Insert("SettingsComposer", Undefined);
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate" , Undefined);
	SettingsStructure.Insert("KeepRecordsOfQualityCertificates" , False);
	SettingsStructure.Insert("PricesAsOfDate",          EndOfDay(Filter_Settings.Date));
	SettingsStructure.Insert("DateOfReceiptOfBalances", Filter_Settings.Date);
	
	SettingsStructure.RequiredFields.Add("Products");
	If Filter_Settings.UsePriceManagementSystem25 Then
		If Filter_Settings.UseItemVariants Then
			SettingsStructure.RequiredFields.Add("PricingVariant");
		EndIf;
		If Filter_Settings.UseItemsBatch Then
			SettingsStructure.RequiredFields.Add("PricingBatch");
		EndIf;
		If Filter_Settings.UseItemPackages Then
			SettingsStructure.RequiredFields.Add("PricingPackage");
		EndIf;
	Else	
		If Filter_Settings.UseItemVariants Then
			SettingsStructure.RequiredFields.Add("Characteristic");
		EndIf;
	EndIf;
	
	SettingsComposerFilter = New DataCompositionSettingsComposer();
	
	FilterValue = Undefined;
		
	If Filter_Settings.FilterValues.Property("RemainingGoodsByShelfLives", FilterValue) Then

		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Products",
			DataCompositionComparisonType.Equal,
			FilterValue,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
	EndIf;
	
	If Filter_Settings.FilterValues.Property("ByArrayOfProducts", FilterValue) Then

		If TypeOf(FilterValue) = Type("Array") Then
			RightValue = New ValueList;
			RightValue.LoadValues(FilterValue);
		Else
			RightValue = FilterValue;
		EndIf;

		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Products",
			DataCompositionComparisonType.InList,
			RightValue,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	
	EndIf;
	
	If Filter_Settings.FilterValues.Property("ByArrayOfCharacteristics", FilterValue) Then

		If TypeOf(FilterValue) = Type("Array") Then
			RightValue = New ValueList;
			RightValue.LoadValues(FilterValue);
		Else
			RightValue = FilterValue;
		EndIf;

		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Characteristic",
			DataCompositionComparisonType.InList,
			RightValue,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	
	EndIf;
		
	If Filter_Settings.FilterValues.Property("BySeriesArray", FilterValue) Then

		If TypeOf(FilterValue) = Type("Array") Then
			RightValue = New ValueList;
			RightValue.LoadValues(FilterValue);
		Else
			RightValue = FilterValue;
		EndIf;

		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Series",
			DataCompositionComparisonType.InList,
			RightValue,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	
	EndIf;
		
	If Filter_Settings.FilterValues.Property("ByPriceGroups", FilterValue) Then
		
		CommonClientServer.AddCompositionItem(
			SettingsComposerFilter.Settings.Filter,
			"Products.PriceGroup",
			DataCompositionComparisonType.InList,
			FilterValue,
			Undefined,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
	
	SettingsStructure.SettingsComposer = New Structure("Settings", SettingsComposerFilter.Settings);
	If Filter_Settings.UsePriceManagementSystem25 Then
		SettingsStructure.NameOfDataLayoutSchemaTemplate = "Template2_5";
	Else	
		SettingsStructure.NameOfDataLayoutSchemaTemplate = "Template";
	EndIf;
	
	// Loading the generated list of products.
	ResultStructure1 = DataProcessors.GoodsSelectionByPicking.PrepareDataStructure(SettingsStructure);
	ThereIsColumnCharacteristic = ResultStructure1.TableOfGoods.Columns.Find("Characteristic") <> Undefined;
	ThereIsColumnCharacteristicsOfTSO = ResultStructure1.TableOfGoods.Columns.Find("PricingVariant") <> Undefined;
	For Each TSRow In ResultStructure1.TableOfGoods Do
		
		NewRow = ProductsTable.Add();
		NewRow.Products = TSRow.Products;
		
		If Filter_Settings.UsePriceManagementSystem25 Then
			If Filter_Settings.UseItemVariants Then
				PricingVariant = Catalogs.ItemsCharacteristicsForPricing.EmptyRef();
				If ThereIsColumnCharacteristicsOfTSO Then
					PricingVariant = TSRow.PricingVariant;
				ElsIf ThereIsColumnCharacteristic
					And ValueIsFilled(TSRow.Characteristic) Then
					PricingVariant = Common.ObjectAttributeValue(TSRow.Characteristic, "ItemsCharacteristicForPricing");
				EndIf;
				NewRow.PricingVariant = PricingVariant;
			EndIf;
			 
			If Filter_Settings.UseItemsBatch Then
				NewRow.PricingBatch = TSRow.PricingBatch;
			EndIf;
			 
			If Filter_Settings.UseItemPackages Then
				NewRow.PricingPackage = TSRow.PricingPackage;
			EndIf;
		Else
			If Filter_Settings.UseItemVariants Then
				NewRow.Characteristic = TSRow.Characteristic;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Mark the modified formulas.
// 
// Parameters:
//  Form - ClientApplicationForm -
//  PriceTree - ValueTree - Price value tree
//  PriceKind - CatalogRef.TypesOfPrices, Undefined - Type of price
Procedure MarkModifiedFormulas(Form, PriceTree = Undefined, PriceKind = Undefined) Export
	
	If PriceTree = Undefined Then
		
		If TypeOf(Form) = Type("Structure") Then
			PriceTree = Form.PriceTree;
		ElsIf TypeOf(Form) = Type("ClientApplicationForm") Then
			PriceTree = Form.FormAttributeToValue("PriceTree");
		EndIf;	

	EndIf;
	
	If Not PriceKind = Undefined Then
		ColumnName = "PriceKind" + StrReplace(PriceKind.UUID(), "-", "");
		MarkModifiedFormulasInColumn(Form, PriceTree, ColumnName);
	Else
		For Each PriceKind In Form.SelectedPrices Do
			If PriceKind.Selected_5 And PriceKind.FormulaIsBeingEdited Then
				ColumnName = PriceKind.ColumnName;
				MarkModifiedFormulasInColumn(Form, PriceTree, ColumnName);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure MarkModifiedFormulasInColumn(Form, PriceTree, Val ColumnName)
	
	ThereAreFormulaChanges = (PriceTree.Rows.Total("FormulaChangedManually" + ColumnName, True) > 0);
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		Form.Items["PriceTree" + "Formula" + "Picture" + ColumnName].HeaderPicture = 
			?(ThereAreFormulaChanges,PictureLib.Attention16, New Picture()
		);
	EndIf;

EndProcedure

// Sets the VAT rate for tree rows 
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  CalculationParameters - Structure - Structure of calculation parameters
//  DataCache - See InitializeDataCacheStructure
//
Procedure ChangeVATRates(Form, CalculationParameters, DataCache = Undefined) Export

	Parameters = New Structure();
	
	If ValueIsFilled(CalculationParameters.VATRate) Then
		MatchingPriceTypes = VATAccountingLocalization.GetVATRateByPriceType(CalculationParameters);
		If Not ValueIsFilled(MatchingPriceTypes) Then
			Return;
		EndIf;
		Parameters.Insert("Operation",	"ChangeVATRates");
		Parameters.Insert("TypesOfPrices",	MatchingPriceTypes);
	Else
		
		ProductPriceTable = GetBidForItem(Form, CalculationParameters);
		If Not ValueIsFilled(ProductPriceTable) Then
			Return;
		EndIf;
	
		Parameters.Insert("Operation",					"ChangeVATRatesFromItem");
		Parameters.Insert("TypesOfPrices",					CalculationParameters.SelectedTypesOfPrices);
		Parameters.Insert("ProductPriceTable",	ProductPriceTable);
	EndIf;
	
	Parameters.Insert("PriceTreeIsDataTreeOfForm", 	(TypeOf(Form.PriceTree) = Type("FormDataTree")));
	Parameters.Insert("UsePriceManagementSystem25", 	Form.UsePriceManagementSystem25);
	Parameters.Insert("AddAllLines", 				False);
	
	Form.Modified = True;
	DataCache = InitializeDataCacheStructure(DataCache);
	ProductsTable = CreateProductTable(Form);
	
	If Not CalculationParameters.SelectedLinesOnly Then
		ApplyChangesToTree(Parameters, Form.PriceTree, ProductsTable,,DataCache)
	Else
		For Each SelectedRow In Form.Items.PriceTree.SelectedRows Do
			PriceTableRow = Form.PriceTree.FindByID(SelectedRow);
			ApplyChangesToTree(Parameters, PriceTableRow, ProductsTable,,DataCache);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure VisibilityOfTDColumn(ExcelTabularDocument, Column, ColumnVisibility)	
	If Column = 0 Then
		Return ;
	EndIf;	
	
	ExcelTabularDocument.Area(,Column,,Column).Visible = ColumnVisibility;
	
EndProcedure

Procedure SetCellText(CurrentTabularDocument, String, Column, Text)	
	
	If Column = 0 Then
		Return ;
	EndIf;	
	
	CurrentTabularDocument.Area(String, Column, String, Column).Text = Text;	 
	
EndProcedure

Procedure SetCellValue(CurrentTabularDocument, String, Column, CellValue)	
	
	If Column = 0 Then
		Return ;
	EndIf;	    
	
	If ValueIsFilled(CurrentTabularDocument.Area(String, Column, String, Column).Text) Then
		CurrentTabularDocument.Area(String, Column, String, Column).Value = CellValue;	 
	Else
		CurrentTabularDocument.Area(String, Column, String, Column).Text = CellValue;	 
	EndIf;	
	
EndProcedure

Function CellContent(CurrentTabularDocument, String, Column)	
	If Column = 0 Then
		Return "";
	EndIf;	
	MeaningOfText = CurrentTabularDocument.Area(String, Column, String, Column).Text;	
	Return TrimAll(MeaningOfText);
EndFunction

Function CellContentValue(CurrentTabularDocument, String, Column)	
	If Column = 0 Then
		Return "";
	EndIf;
	
	CellValue = 0;
	If ValueIsFilled(CurrentTabularDocument.Area(String, Column, String, Column).Text) Then
		Try
			CellValue = CurrentTabularDocument.Area(String, Column, String, Column).Value;	
		Except   
			CellValue = 0;	
		EndTry	
	EndIf;
	
	Return TrimAll(CellValue);
EndFunction

#Region ScheduledJobs

// Runs the update of prices by type of prices
// 
// Parameters:
//   TypesOfPrices - Array - elements of the reference Link type.Price types - types of prices to update prices for.
//   PriceUpdateOptions - Structure - with properties. May contain:
//    * PriceUpdateOption - Number - option for forming price types (0 - all, 1 - only selected, 2 - Selected and dependent, 3 - All but selected).
//
Procedure PerformPriceUpdates(TypesOfPrices, PriceUpdateOptions) Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdatePrices);

	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	PriceUpdateOption = PriceUpdateOptions.PriceUpdateOption;
	
	If PriceUpdateOption <> 0 And Not ValueIsFilled(TypesOfPrices) Then
		Return;
	EndIf;

	ArrayOfPriceTypes = TypesOfPrices.UnloadColumn("PriceKind");   
	
	// initialization of structures for calculation
 	ShapeStructure = InitializeFormStructure();
	
	For Each CollectionItem In ArrayOfPriceTypes Do
		ValueTableRow = ShapeStructure.Object.TypesOfPrices.Add();
		ValueTableRow.PriceKind = CollectionItem;
	EndDo;
 	
	PriceSettingDocument = Documents.PriceSetup.EmptyRef();
	ShapeStructure.Object.Insert("Goods", PriceSettingDocument["Goods"]);
	ShapeStructure.Object.Insert("Goods2_5", PriceSettingDocument["Goods2_5"]);
	
	SettingPricesServer.InitializeSelectedPrices(ShapeStructure);
	ShapeStructure.DataLayoutSettingsTable = GetFromTempStorage(ShapeStructure.StorageAddressDataLayoutSettings);	

	ShapeStructure.SelectedPrices.Columns.Add("DataCompositionSchema");

	For Each LineViewPrices In ShapeStructure.SelectedPrices Do
		Schema = New ValueStorage(GetFromTempStorage(LineViewPrices.AddressOfDataCompositionSchema));
		LineViewPrices.DataCompositionSchema	= Schema.Get();
	EndDo; 
	
	// apply the settings of the price update option (0 - all prices; 1 - selected; 2 - selected and dependent; 3 - all except selected)
	If PriceUpdateOption = 0 Then
		// all prices
		SettingPricesClientServer.InvertSelectedPrices(ShapeStructure);
	ElsIf PriceUpdateOption = 1 Then 	
		// Only selected prices
		// We don't do anything extra
	ElsIf PriceUpdateOption = 2 Then 	
		// Selected and dependent prices
		SettingPricesClientServer.SelectAllDependentPrices_(ShapeStructure);
	ElsIf PriceUpdateOption = 3 Then 	
		// All except the selected prices
		SettingPricesClientServer.InvertSelectedPrices(ShapeStructure);
		SettingPricesClientServer.SelectAllInfluencingPricesWithoutCalculation(ShapeStructure);
	EndIf;	
	
	// 	fill in the items according to the selection of the nomenclature
	SettingPricesServer.BuildPriceTree(ShapeStructure);
	
	
	ArrayOfPriceTypes.Clear();
	For Each TSRow In ShapeStructure.SelectedPrices Do

		If TSRow.Selected_5
			And ArrayOfPriceTypes.Find(TSRow.Ref) = Undefined Then
			ArrayOfPriceTypes.Add(TSRow.Ref);
		EndIf;
		
	EndDo;

	For IndexOf = 1 To 2 Do
		ShapeStructure.PriceTree.Rows.Clear();
		ShapeStructure.AddressOfDataCacheStorage = "";
		SetPrices(ArrayOfPriceTypes, ShapeStructure, ?(IndexOf = 1, "RefreshEnabled", "ZeroingOut"));
	EndDo;

EndProcedure

Procedure SetPrices(Val ArrayOfPriceTypes, Val ShapeStructure, Val TypeOfPriceUpdate = "RefreshEnabled")
	
	LogParameters = New Structure("EventGroup_, Metadata, Data");
	TextEventGroup = NStr("vi = '%TypeOfPriceUpdate% đơn giá. Khởi động theo lịch biểu';
							|ru = '%TypeOfPriceUpdate% цен. Запуск по расписанию';
							|en = '%TypeOfPriceUpdate% of prices. Scheduled start'; fa = '%TypeOfPriceUpdate% of prices. Scheduled start';
							|it = '%TypeOfPriceUpdate% dei prezzi. Esecuzione pianificata';
							|pl = '%TypeOfPriceUpdate% cen. Uruchomienie wg harmonogramu';
							|tr = '%TypeOfPriceUpdate% fiyat. Programa göre başlatma'", Common.DefaultLanguageCode());	
	TextEventGroup = StrReplace(TextEventGroup, "%TypeOfPriceUpdate%", TypeOfPriceUpdate);
	
	LogParameters.EventGroup_ = TextEventGroup;
	LogParameters.Metadata    = Metadata.Documents.PriceSetup;	
	LogParameters.Data        = ArrayOfPriceTypes;
	
	LogRecord(LogParameters, EventLogLevel.Note, "", NStr("vi = 'Khởi động';
															|ru = 'Запуск';
															|en = 'Start'; fa = 'شروع';
															|it = 'Avvio';
															|pl = 'Start';
															|tr = 'Başlangıc'", Common.DefaultLanguageCode()));

	If TypeOfPriceUpdate = "RefreshEnabled" Then
		
		SettingPricesServer.AddProductsByDCSSelection(ShapeStructure, True);
	
		//	calculate prices
		CalculationParameters = New Structure();
		CalculationParameters.Insert("TypesOfPrices",				ArrayOfPriceTypes);
		CalculationParameters.Insert("SelectedLinesOnly",	False);
		CalculationParameters.Insert("OnlyEmpty",	False);
		CalculationParameters.Insert("ImportOldPrices",		False);
		CalculationParameters.Insert("RoundingUpManualPrices",	False);
		CalculationParameters.Insert("CalculationByFormulas",		True);
	
		SettingPricesServer.CalculatePrices(ShapeStructure, CalculationParameters);
		
	Else
		
		ShapeStructure.CalculateAutomatically = False;
		AddProductsToResetPricesForDCSSelections(ShapeStructure);
		
	EndIf;

	Try
		//	fill out and write down the document
		CommentText1 = NStr("vi = '%TypeOfPriceUpdate% đơn giá (tự động theo lịch biểu)';
							|ru = '%TypeOfPriceUpdate% цен (автоматическое по расписанию)';
							|en = '%TypeOfPriceUpdate% of prices (scheduled automatic)'; fa = '%TypeOfPriceUpdate% of prices (scheduled automatic)';
							|it = '%TypeOfPriceUpdate% dei prezzi (pianificato automaticamente)';
							|pl = '%TypeOfPriceUpdate% cen (automatycznie zgodnie z harmonogramem)';
							|tr = '%TypeOfPriceUpdate% fiyat (programa göre otomatik)'", Common.DefaultLanguageCode());
		CommentText1 = StrReplace(CommentText1, "%TypeOfPriceUpdate%", TypeOfPriceUpdate);
		
		Documents.PriceSetup.RecordPriceChangesOnServer(ShapeStructure, CommentText1, 1);
	Except
		
		LogRecord(LogParameters, 
		              EventLogLevel.Error,
		              "",
		              NStr("vi = 'Lỗi cập nhật đơn giá';
							|ru = 'Ошибка обновления цен';
							|en = 'Price update error'; fa = 'Price update error';
							|it = 'Errore di aggiornamento dei prezzi';
							|pl = 'Błąd aktualizacji cen';
							|tr = 'Fiyat güncelleme hatası'", Common.DefaultLanguageCode()) + " '"+ ArrayOfPriceTypes +"'",
		              ErrorInfo());
		
	EndTry;
	
	LogRecord(LogParameters, EventLogLevel.Note, "",NStr("vi = 'Kết thúc';
														|ru = 'Завершение';
														|en = 'Complete'; fa = 'تکمیل';
														|it = 'Completamento';
														|pl = 'Complete';
														|tr = 'Tamamlama'", Common.DefaultLanguageCode()));
EndProcedure

// Initialize the form structure.
// 
// Returns:
//  Structure - Initialize The Form Structure:
// * Date - Date -
// * Modified - Boolean -
// * Object - Structure -:
// ** TypesOfPrices - ValueTable -
// ** DocumentBasis - DocumentRef -
// * FormCode - String -
// * SelectedPrices - ValueTable -:
// ** Ref - CatalogRef.TypesOfPrices -
// ** PricingMethod - EnumRef.PriceSettingMethods -
// ** Selected_5 - Boolean -
// ** Edit - Boolean -
// ** Depends - Boolean -
// ** Influences - Boolean -
// ** Formula - String -
// ** Currency - CatalogRef.Currencies -
// ** Id - String -
// ** ColumnName - String -
// ** Description - String -
// ** RoundOffOption - EnumRef.RoundingOptions -
// ** ThresholdOnPriceIncreaseFor - Number
// ** Level - Number -
// ** ProhibitedPriceType - Boolean -
// ** BasicPriceType - String -
// ** Markup - Number -
// ** DeletionMark - Boolean -
// ** Parameters - String -
// ** InfluencingPriceTypes - ValueTable -
// ** InfluencingPrices - ValueList -
// ** DependentPrices - ValueList -
// ** SetPriceDuringGeneration - Boolean -
// ** ThresholdOnPriceDecreaseBy - Number -
// ** AddlOrderingAttribute - Number -
// ** DateOfTheLastPriceSetting - Date -
// ** AddressOfDataCompositionSchema - String -
// ** AddressOfDataCompositionSchemaSettings - String -
// ** AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem - String -
// ** RequiredParametersAreFound - Boolean -
// ** Thresholds - ValueTable -
// ** PriceRoundingRules - ValueTable -
// ** PriceGroups - ValueTable -
// ** DisablePriceEditingOutsideFilter - Boolean -
// * PriceTree - ValueTree -
// * UsePriceGroups - Boolean -
// * UseItemVariants - Boolean -
// * UseItemPackages - Boolean -
// * UseItemsBatch - Arbitrary -
// * UseSeveralPriceTypes - Boolean -
// * UsePriceManagementSystem25 - Boolean -
// * SelectedPricesWereChanged - Boolean -
// * CalculateAutomatically - Boolean -
// * UUID - UUID -
// * AddressOfTheStorageOfLayoutSchemeParametersByPriceType - String -
// * StorageAddressDataLayoutSettings - String -
// * DataLayoutSettingsTable - ValueTable
Function InitializeFormStructure()
	
	ShapeStructure = New Structure();
	ShapeStructure.Insert("Date",				EndOfDay(CurrentSessionDate()));
	ShapeStructure.Insert("Modified",			False);
	ShapeStructure.Insert("Object",			InitializeObject());
	ShapeStructure.Insert("FormCode",			"ProcessingPriceFilling_test");
	ShapeStructure.Insert("SelectedPrices",	InitializeSelectedPricesTable());
	ShapeStructure.Insert("PriceTree",		New ValueTree());
	ShapeStructure.Insert("UsePriceGroups", 				GetFunctionalOption("UsePriceGroups"));
	ShapeStructure.Insert("UseItemVariants", 	GetFunctionalOption("UseItemVariants"));
	ShapeStructure.Insert("UseItemPackages", 		GetFunctionalOption("UseItemPackages"));
	ShapeStructure.Insert("UseItemsBatch", 			GetFunctionalOption("UseItemsBatch"));
	ShapeStructure.Insert("UseSeveralPriceTypes", 			GetFunctionalOption("UseSeveralPriceTypes"));
	ShapeStructure.Insert("UsePriceManagementSystem25", 			PriceManagementSystemServerCall.UsePriceManagementSystem25(EndOfDay(CurrentSessionDate())));
	ShapeStructure.Insert("AddressOfDataCacheStorage", 				"");

	ShapeStructure.Insert("GroupingOption",			Undefined);
	ShapeStructure.Insert("SelectedPricesWereChanged",		False);
	ShapeStructure.Insert("CalculateAutomatically",	True);
	ShapeStructure.Insert("UUID", 		New UUID());
	ShapeStructure.Insert("AddressOfTheStorageOfLayoutSchemeParametersByPriceType",	"");
	ShapeStructure.Insert("StorageAddressDataLayoutSettings",	"");
	ShapeStructure.Insert("DataLayoutSettingsTable");
	
	Return ShapeStructure
	
EndFunction

// Initialize the selected prices table.
// 
// Returns:
//  ValueTable - Initialize The Selected Prices Table:
// * Ref - CatalogRef.TypesOfPrices -
// * PricingMethod - EnumRef.PriceSettingMethods -
// * Selected_5 - Boolean -
// * Edit - Boolean -
// * Depends - Boolean -
// * Influences - Boolean -
// * Formula - String -
// * Currency - CatalogRef.Currencies -
// * Id - String -
// * ColumnName - String -
// * Description - String -
// * RoundOffOption - EnumRef.RoundingOptions -
// * ThresholdOnPriceIncreaseFor - Number
// * Level - Number -
// * ProhibitedPriceType - Boolean -
// * BasicPriceType - String -
// * Markup - Number -
// * DeletionMark - Boolean -
// * Parameters - String -
// * InfluencingPriceTypes - ValueTable -
// * InfluencingPrices - ValueList -
// * DependentPrices - ValueList -
// * SetPriceDuringGeneration - Boolean -
// * ThresholdOnPriceDecreaseBy - Number -
// * AddlOrderingAttribute - Number -
// * DateOfTheLastPriceSetting - Date -
// * AddressOfDataCompositionSchema - String -
// * AddressOfDataCompositionSchemaSettings - String -
// * AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem - String -
// * RequiredParametersAreFound - Boolean -
// * Thresholds - ValueTable -
// * PriceRoundingRules - ValueTable -
// * PriceGroups - ValueTable -
// * Currencies - ValueTable -
// * DisablePriceEditingOutsideFilter - Boolean -
Function InitializeSelectedPricesTable()

	TableOfSelectedPrices = New ValueTable();
	TableOfSelectedPrices.Columns.Add("Ref",				New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfSelectedPrices.Columns.Add("PricingMethod",	New TypeDescription("EnumRef.PriceSettingMethods"));
	TableOfSelectedPrices.Columns.Add("Selected_5", 			New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Edit", 		New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Depends",			New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Influences", 			New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Formula",			New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("FormulaIsBeingEdited", New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Currency",				New TypeDescription("CatalogRef.Currencies"));
	TableOfSelectedPrices.Columns.Add("Id",		New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("ColumnName",			New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("Description",		New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("RoundOffOption",	New TypeDescription("EnumRef.RoundingOptions"));
	TableOfSelectedPrices.Columns.Add("ThresholdOnPriceIncreaseFor",	New TypeDescription(Metadata.DefinedTypes.MonetaryAmountNonNegative.Type));
	TableOfSelectedPrices.Columns.Add("Level",			New TypeDescription("Number"));
	TableOfSelectedPrices.Columns.Add("ProhibitedPriceType",	New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("BasicPriceType",		New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("Markup",			New TypeDescription("Number"));
	TableOfSelectedPrices.Columns.Add("DeletionMark",	New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Parameters",			New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("InfluencingPriceTypes",	New TypeDescription("ValueTable"));
	TableOfSelectedPrices.Columns.Add("InfluencingPrices",		New TypeDescription("ValueList"));
	TableOfSelectedPrices.Columns.Add("DependentPrices",		New TypeDescription("ValueList"));
	TableOfSelectedPrices.Columns.Add("SetPriceDuringGeneration",	New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("ThresholdOnPriceDecreaseBy",			New TypeDescription("Number"));
	TableOfSelectedPrices.Columns.Add("AddlOrderingAttribute",				New TypeDescription("Number"));
	TableOfSelectedPrices.Columns.Add("DateOfTheLastPriceSetting",				New TypeDescription("Date"));
	TableOfSelectedPrices.Columns.Add("AddressOfDataCompositionSchema",				New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("AddressOfDataCompositionSchemaSettings",		New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem",		New TypeDescription("String"));
	TableOfSelectedPrices.Columns.Add("RequiredParametersAreFound",			New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("Thresholds",						New TypeDescription("ValueTable"));
	TableOfSelectedPrices.Columns.Add("PriceRoundingRules",					New TypeDescription("ValueTable"));
	TableOfSelectedPrices.Columns.Add("PriceGroups",							New TypeDescription("ValueTable"));
	TableOfSelectedPrices.Columns.Add("Currencies",									New TypeDescription("ValueTable"));
	TableOfSelectedPrices.Columns.Add("DisablePriceEditingOutsideFilter",	New TypeDescription("Boolean"));
	TableOfSelectedPrices.Columns.Add("OptionForSpecifyingVATRates",						New TypeDescription("EnumRef.OptionsForSpecifyingVATRatesInPriceList"));
	TableOfSelectedPrices.Columns.Add("Country",											New TypeDescription("CatalogRef.WorldCountries"));
	TableOfSelectedPrices.Columns.Add("VATRate",										New TypeDescription("CatalogRef.VATRates"));
	
	Return TableOfSelectedPrices;
	
EndFunction

// Initialize the object.
// 
// Returns:
//  Structure - Initialize an object:
// * TypesOfPrices - ValueTable -
// * DocumentBasis - DocumentRef
Function InitializeObject()
	
	ObjectStructure = New Structure();
	ObjectStructure.Insert("TypesOfPrices", New ValueTable());
	ObjectStructure.Insert("DocumentBasis");
	
	ObjectStructure.TypesOfPrices.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	ObjectStructure.TypesOfPrices.Columns.Add("DataCompositionSettings", New TypeDescription("ValueStorage"));
	
	Return ObjectStructure;
EndFunction
#EndRegion

#Region TransitionWizard

Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.MigrationToPriceManagementSystemVersion25.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.UpdatePrices.MethodName);
	
EndProcedure

Procedure DisableTaskForSwitchingToPricingVersion25()
	
	Filter = New Structure();
	Filter.Insert("Metadata", "MigrationToPriceManagementSystemVersion25");
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	For Each SchedJob In Jobs Do
		If SchedJob.Parameters.Count() > 0 Then
			ScheduledJobsServer.DeleteJob(SchedJob);
		EndIf;
	EndDo;
	
EndProcedure

// Initializes the transition to pricing version 2.5.
//
// Parameters:
// MigrationParameters - See InitializeTransitionStateStructure
//
Procedure StartSwitchingToPricingVersion2_5(MigrationParameters) Export

	Filter = New Structure();
	Filter.Insert("Metadata", "MigrationToPriceManagementSystemVersion25");
	Jobs = ScheduledJobsServer.FindJobs(Filter);

	YouNeedToCreateTask = True;
	
	If Jobs.Count() > 0 Then
		For Each SchedJob In Jobs Do
			If SchedJob.Parameters.Count() > 0 Then
				If Not SchedJob.Use Then
					YouNeedToCreateTask = False;
					JobParameters = New Structure();
					JobParameters.Insert("Use", True);
					ScheduledJobsServer.ChangeJob(SchedJob, JobParameters);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Record = InformationRegisters.StatusOfMigrationToPriceManagementSystemVersion25.CreateRecordManager();
	Record.Read();
	If Record.Selected() Then
		Raise NStr("vi = 'Đã bắt đầu chuyển.';
					|ru = 'Переход уже начался.';
					|en = 'Migration has already started.'; fa = 'Migration has already started.';
					|it = 'La transizione è già iniziata.';
					|pl = 'Przejście zostało już rozpoczęte.';
					|tr = 'Transfer artık başladı.'");
	EndIf;

	BeginTransaction();
	Try
		
		Record = InformationRegisters.StatusOfMigrationToPriceManagementSystemVersion25.CreateRecordManager();
		Record.DateOfMigrationToPriceManagementSystem25 = MigrationParameters.DateOfMigrationToPriceManagementSystem25;
		Record.StartDate = CurrentSessionDate();
		Record.Step = 1;
		Record.State = Enums.JobsStates.Scheduled;
		
		Record.StepParameters1 = New ValueStorage(MigrationParameters.StepParameters1);
		Record.StepParameters2 = New ValueStorage(MigrationParameters.StepParameters2);
		Record.StepParameters3 = New ValueStorage(MigrationParameters.StepParameters3);
	
		Record.Initiator = Users.CurrentUser();
		Record.Write();
		
		Filter = New Structure();
		Filter.Insert("Metadata", "MigrationToPriceManagementSystemVersion25");
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		
		If YouNeedToCreateTask Then
			
			DefaultValues = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs.MigrationToPriceManagementSystemVersion25);
			
			JobParameters = New Structure;
			JobParameters.Insert("Metadata", Metadata.ScheduledJobs.MigrationToPriceManagementSystemVersion25);
			JobParameters.Insert("Use", True);
			JobParameters.Insert("Schedule", DefaultValues.Schedule);
			JobParameters.Insert("RestartCountOnFailure", DefaultValues.RestartCountOnFailure);
			JobParameters.Insert("RestartIntervalOnFailure", DefaultValues.RestartIntervalOnFailure);
			JobParameters.Insert("Key", DefaultValues.Key);
			
			ScheduledJobsServer.AddJob(JobParameters);
			
		EndIf;

		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;


EndProcedure

// Returns the status of switching to pricing version 2.5.
//
// Returns:
//   Structure - See InitializeTransitionStateStructure
//
Function StateOfTransitionToPricingVersion2_5() Export 
	
	TransitionState = InitializeTransitionStateStructure();

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	StatusOfMigrationToPriceManagementSystemVersion25.DateOfMigrationToPriceManagementSystem25,
	|	StatusOfMigrationToPriceManagementSystemVersion25.StartDate,
	|	StatusOfMigrationToPriceManagementSystemVersion25.CompletedOn,
	|	StatusOfMigrationToPriceManagementSystemVersion25.Step,
	|	StatusOfMigrationToPriceManagementSystemVersion25.State,
	|	StatusOfMigrationToPriceManagementSystemVersion25.StepParameters1,
	|	StatusOfMigrationToPriceManagementSystemVersion25.StepParameters2,
	|	StatusOfMigrationToPriceManagementSystemVersion25.StepParameters3,
	|	StatusOfMigrationToPriceManagementSystemVersion25.Initiator
	|FROM
	|	InformationRegister.StatusOfMigrationToPriceManagementSystemVersion25 AS StatusOfMigrationToPriceManagementSystemVersion25";
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return TransitionState;
	EndIf;
	
	FillPropertyValues(TransitionState, Selection, , "StepParameters1, StepParameters2, StepParameters3");
	
	StepParameters = Selection.StepParameters1; // ValueStorage
	For Each KeyAndValue In StepParameters.Get() Do
		TransitionState.StepParameters1.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	StepParameters = Selection.StepParameters2; // ValueStorage
	For Each KeyAndValue In StepParameters.Get() Do
		TransitionState.StepParameters2.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	StepParameters = Selection.StepParameters3; // ValueStorage
	For Each KeyAndValue In StepParameters.Get() Do
		TransitionState.StepParameters3.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;

	Return TransitionState;
EndFunction

Procedure FixStateOfTransitionToPricingVersion2_5(TransitionState) 
	
	Record = InformationRegisters.StatusOfMigrationToPriceManagementSystemVersion25.CreateRecordManager();
	Record.Read();
		
	Record.StartDate = CurrentUniversalDate();
	FillPropertyValues(Record, TransitionState, , "StepParameters1, StepParameters2, StepParameters3");
	
	Record.StepParameters1 = New ValueStorage(TransitionState.StepParameters1);
	Record.StepParameters2 = New ValueStorage(TransitionState.StepParameters2);
	Record.StepParameters3 = New ValueStorage(TransitionState.StepParameters3);

	Record.Write();
		
EndProcedure


// Procedure for switching to pricing version 2.5
//
Procedure SwitchToPricingVersion2_5() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.MigrationToPriceManagementSystemVersion25);

// 1. Get the current state of the transition
	TransitionState = StateOfTransitionToPricingVersion2_5();
	If Not ValueIsFilled(TransitionState.State) Or TransitionState.Step = 4 Then
		DisableTaskForSwitchingToPricingVersion25();
		Return;
	EndIf;
// 2. Set the necessary variables
// 3. Let's perform step 1 - creating an IPL

	If TransitionState.Step = 1 Then
		
		StepParameters = TransitionState.StepParameters1;
		TransitionState.State = Enums.JobsStates.Running;
		
		If StepParameters.State = Enums.JobsStates.Scheduled Then
			
			StepParameters.StartDate = CurrentSessionDate();
			
			StepParameters.State = Enums.JobsStates.Running;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
		EndIf;
		
		// initialization of structures for calculation
	 	ShapeStructure = InitializeFormStructure();
		ShapeStructure.UsePriceManagementSystem25 = True;
	
		For Each String In StepParameters.TableForProcessing Do
			// check the possibility of transfer
			If Not (String.State = Enums.JobsStates.Scheduled 
				Or String.State = Enums.JobsStates.Running) Then
				
				Continue;
					
			EndIf;
			
			String.State = Enums.JobsStates.Running;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
			TransferResult = CreateIPL(String.Ref, BegOfDay(TransitionState.DateOfMigrationToPriceManagementSystem25-1));
			
			// fix the transfer result
			If TransferResult.Result Then
				String.State = Enums.JobsStates.Completed;
				StepParameters.QuantityProcessed = StepParameters.QuantityProcessed + 1;
				
				NewPriceTransferLine = TransitionState.StepParameters3.TableForProcessing.Add();
				NewPriceTransferLine.Ref = TransferResult.Ref;
				NewPriceTransferLine.State = Enums.JobsStates.Scheduled;
				TransitionState.StepParameters3.TotalCount1 = TransitionState.StepParameters3.TableForProcessing.Count(); 
				
			Else
				
				String.State = Enums.JobsStates.ExecutionError;
				String.ErrorDescription = TransferResult.ErrorDescription;
				StepParameters.ErrorsCount = StepParameters.ErrorsCount + 1;
				
			EndIf;
	
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
		EndDo;

		StepParameters.CompletedOn = CurrentSessionDate();
		If StepParameters.ErrorsCount = 0 Then
			StepParameters.State = Enums.JobsStates.Completed;
		Else	
			StepParameters.State = Enums.JobsStates.ExecutionError;
		EndIf;
		
		TransitionState.Step = 2;
		FixStateOfTransitionToPricingVersion2_5(TransitionState);
		
	EndIf;

// 4. Let's perform step 2 - creating pricing sections

	If TransitionState.Step = 2 Then
		
		StepParameters = TransitionState.StepParameters2;
		
		If StepParameters.State = Enums.JobsStates.Scheduled Then
			
			StepParameters.StartDate = CurrentUniversalDate();
			StepParameters.State = Enums.JobsStates.Running;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
		EndIf;
		
		For Each String In StepParameters.TableForProcessing Do
			// check the possibility of transfer
			If Not (String.State = Enums.JobsStates.Scheduled 
				Or String.State = Enums.JobsStates.Running) Then
				
				Continue;
					
			EndIf;
			
			String.State = Enums.JobsStates.Running;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
			TransferResult = UpdateSpecificationsAndSeriesPricing(String.Ref);
			
			// fix the transfer result
			If TransferResult.Result Then
				
				String.State = Enums.JobsStates.Completed;
				StepParameters.QuantityProcessed = StepParameters.QuantityProcessed + 1;
				
			Else
				
				String.State = Enums.JobsStates.ExecutionError;
				String.ErrorDescription = TransferResult.ErrorDescription;
				StepParameters.ErrorsCount = StepParameters.ErrorsCount + 1;
				
			EndIf;
	
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
		EndDo;
	 
		StepParameters.CompletedOn = CurrentSessionDate();
		If StepParameters.ErrorsCount = 0 Then
			StepParameters.State = Enums.JobsStates.Completed;
		Else	
			StepParameters.State = Enums.JobsStates.ExecutionError;
		EndIf;

		TransitionState.Step = 3;
		FixStateOfTransitionToPricingVersion2_5(TransitionState);
		
	EndIf;

// 5. Let's perform step 3 - transfer of price types
	If TransitionState.Step = 3 Then
		
		StepParameters = TransitionState.StepParameters3;
		If StepParameters.State = Enums.JobsStates.Scheduled Then
			
			StepParameters.StartDate = CurrentSessionDate();
			StepParameters.State = Enums.JobsStates.Running;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
		EndIf;
		
		// initialization of structures for calculation
	 	ShapeStructure = InitializeFormStructure();
		ShapeStructure.UsePriceManagementSystem25 = True;
		ShapeStructure.Date = TransitionState.DateOfMigrationToPriceManagementSystem25;
		
		For Each String In StepParameters.TableForProcessing Do
			// check the possibility of transfer
			If Not (String.State = Enums.JobsStates.Scheduled 
				Or String.State = Enums.JobsStates.Running) Then
				
				Continue;
					
			EndIf;
			
			String.State = Enums.JobsStates.Running;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
			// transfer the type of prices
			ShapeStructure.Object.TypesOfPrices.Clear();
			LineViewPrices = ShapeStructure.Object.TypesOfPrices.Add();
			LineViewPrices.PriceKind = String.Ref;
	
			SettingPricesServer.InitializeSelectedPrices(ShapeStructure);
			ShapeStructure.DataLayoutSettingsTable = GetFromTempStorage(ShapeStructure.StorageAddressDataLayoutSettings);
			If ShapeStructure.SelectedPrices.Columns.Find("DataCompositionSchema") = Undefined Then
				ShapeStructure.SelectedPrices.Columns.Add("DataCompositionSchema");
			EndIf;
					
			For Each LineViewPrices In ShapeStructure.SelectedPrices Do		
				Schema = New ValueStorage(GetFromTempStorage(LineViewPrices.AddressOfDataCompositionSchema));
				LineViewPrices.DataCompositionSchema	= Schema.Get();
			EndDo;
	
			// 	fill in the items according to the selection of the nomenclature
			ShapeStructure.PriceTree.Rows.Clear();
			SettingPricesServer.BuildPriceTree(ShapeStructure);
			
			TransferResult = MovePriceViewToVersion2_5Pricing(ShapeStructure, String.Ref);
			
			// fix the transfer result
			If TransferResult.Result Then
				String.State = Enums.JobsStates.Completed;
				StepParameters.QuantityProcessed = StepParameters.QuantityProcessed + 1;
			Else
				String.State = Enums.JobsStates.ExecutionError;
				String.ErrorDescription = TransferResult.ErrorDescription;
				StepParameters.ErrorsCount = StepParameters.ErrorsCount + 1;
			EndIf;
	
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
			
		EndDo;
	 
	 	ErrorSettingConstants = False;
		TransitionState.Step = 4;
		StepParameters.CompletedOn = CurrentSessionDate();
		If StepParameters.ErrorsCount = 0 Then
			
			StepParameters.State = Enums.JobsStates.Completed;
			
		Else	
			StepParameters.State = Enums.JobsStates.ExecutionError;
		EndIf;
		
		Try
			SystemSettings.SetConstantValue(Constants.UsePriceManagementSystem25, True);
			SystemSettings.SetConstantValue(Constants.DateOfMigrationToPriceManagementSystem25, TransitionState.DateOfMigrationToPriceManagementSystem25);
		Except
			ErrorSettingConstants = True;
		EndTry;

		If Not ErrorSettingConstants Then
			DisableTaskForSwitchingToPricingVersion25();
			
			TransitionState.CompletedOn = CurrentSessionDate();
			TransitionState.State = Enums.JobsStates.Completed;
			FixStateOfTransitionToPricingVersion2_5(TransitionState);
		EndIf;
		
	EndIf;

EndProcedure

Function MovePriceViewToVersion2_5Pricing(Form, PricesKind)

	TransferResult = InitializeResultStructure();
	
	SetPrivilegedMode(True);
	
	DataCompositionSchema 	= DataProcessors.AssistantOfMigrationToPriceManagementSystemVersion25.GetTemplate("TransferPricesToPricing25Predefined");
	
	// Preparing a data layout layout builder, loading settings
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	// Filling in the report structure and selected fields.
	SettingsComposer.Settings.Structure.Clear();
	
	DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecordsGroup.Use = True;
	
	SettingsComposer.Settings.Selection.Items.Clear();
	AddSelectedDCSField(DetailedRecordsGroup, "Products", True);
	AddSelectedDCSField(DetailedRecordsGroup, "PriceKind", True);

	If Form.UseItemVariants Then
		AddSelectedDCSField(DetailedRecordsGroup, "PricingVariant", True);
	EndIf;
	
	If Form.UseItemsBatch Then
		AddSelectedDCSField(DetailedRecordsGroup, "PricingBatch", True);
	EndIf;
	
	If Form.UseItemPackages Then
		AddSelectedDCSField(DetailedRecordsGroup, "PricingPackage", True);
		AddSelectedDCSField(DetailedRecordsGroup, "Package", True);
	EndIf;
	
	AddSelectedDCSField(DetailedRecordsGroup, "Price");
	AddSelectedDCSField(DetailedRecordsGroup, "Currency", True);
	
	LayoutOptions = SettingsComposer.Settings.DataParameters.Items;
	
	Parameter = LayoutOptions.Find("DocumentDate");
	If Parameter <> Undefined Then
		Parameter.Value = DateForRequestingProductPrices(Form);
		Parameter.Use = ValueIsFilled(Parameter.Value);
	EndIf;
	Parameter = LayoutOptions.Find("PriceKind");
	If Parameter <> Undefined Then
		Parameter.Value = PricesKind;
		Parameter.Use = ValueIsFilled(Parameter.Value);
	EndIf;

	// Layout layout and query execution.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,,,True);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

	ReportData = New ValueTable();
	OutputProcessor.SetObject(ReportData);
	ReportData = OutputProcessor.Output(CompositionProcessor);
	
	If ReportData.Count() = 0 Then
		
		LogParameters = New Structure("EventGroup_, Metadata, Data");
		TextEventGroup = NStr("vi = 'Chuyển đơn giá sang thiết lập giá 2.5.';
								|ru = 'Перенос цен на ценообразование 2.5.';
								|en = 'Transfer of prices to pricing 2.5.'; fa = 'Transfer of prices to pricing 2.5.';
								|it = 'Trasferimento dei prezzi all''elaborazione di prezzo 2.5.';
								|pl = 'Przeniesienie cen do tworzenia cen 2.5.';
								|tr = 'Fiyatlandırmaya fiyat transferi 2.5.'", Common.DefaultLanguageCode());	
		
		LogParameters.EventGroup_ = TextEventGroup;
		LogParameters.Metadata    = Metadata.Catalogs.TypesOfPrices;
		LogParameters.Data        = PricesKind;

		ErrorText = NStr("vi = 'Lỗi cập nhật đơn giá. Không tìm thấy đơn giá';
						|ru = 'Ошибка обновления цен. Цены не найдены';
						|en = 'Price update error. Prices not found'; fa = 'Price update error. Prices not found';
						|it = 'Errore di aggiornamento dei prezzi. Prezzi non trovati';
						|pl = 'Błąd aktualizacji cen. Ceny nie są znalezione';
						|tr = 'Fiyatlar güncellenirken hata. Fiyatlar bulunamadı'", Common.DefaultLanguageCode()) + " '"+ PricesKind +"'";
		
		LogRecord(LogParameters, 
		              EventLogLevel.Error,
		              "",
		              ErrorText,
		              ErrorInfo());

		TransferResult.Result = False;
		TransferResult.ErrorDescription = ErrorText;
		
	Else
			
		//	fill out and write down the document
		CommentText1 = NStr("vi = 'Tự động chuyển đơn giá sang thiết lập giá 2.5 theo dạng đơn giá << %PricesKind% >>';
							|ru = 'Автоматический перенос цен на ценообразование 2.5 по виду цен << %PricesKind% >>';
							|en = 'Automatic transfer of prices to pricing 2.5 by price type << %PricesKind% >>'; fa = 'Automatic transfer of prices to pricing 2.5 by price type << %PricesKind% >>';
							|it = 'Trasferimento automatico dei prezzi all''elaborazione di prezzo 2.5 per tipo di prezzo <<%PricesKind%>>';
							|pl = 'Automatycznie przeniesienie cen do tworzenia cen 2.5 wg rodzaju cen << %PricesKind% >>';
							|tr = 'Fiyat Türüne göre fiyatlandırma 2.5''e otomatik fiyat aktarımı << %PricesKind% >>'", Common.DefaultLanguageCode());
		CommentText1 = StrReplace(CommentText1, "%PricesKind%", PricesKind);
		
		Form.Insert("Price_Table", ReportData);
		
		ResultOfSettingPrices = Documents.PriceSetup.RecordPriceChangesOnServer(Form, CommentText1, 1);
		If ResultOfSettingPrices = Undefined Then
			
			LogParameters = New Structure("EventGroup_, Metadata, Data");
			TextEventGroup = NStr("vi = 'Chuyển đơn giá sang thiết lập giá 2.5.';
									|ru = 'Перенос цен на ценообразование 2.5.';
									|en = 'Transfer of prices to pricing 2.5.'; fa = 'Transfer of prices to pricing 2.5.';
									|it = 'Trasferimento dei prezzi all''elaborazione di prezzo 2.5.';
									|pl = 'Przeniesienie cen do tworzenia cen 2.5.';
									|tr = 'Fiyatlandırmaya fiyat transferi 2.5.'", Common.DefaultLanguageCode());	
			
			LogParameters.EventGroup_ = "Transfer prices_";
			LogParameters.Metadata    = Metadata.Catalogs.TypesOfPrices;
			LogParameters.Data        = PricesKind;
							
			ErrorText = NStr("vi = 'Lỗi cập nhật đơn giá';
							|ru = 'Ошибка обновления цен';
							|en = 'Price update error'; fa = 'Price update error';
							|it = 'Errore di aggiornamento dei prezzi';
							|pl = 'Błąd aktualizacji cen';
							|tr = 'Fiyat güncelleme hatası'", Common.DefaultLanguageCode()) + " '"+ PricesKind +"'";
			
			LogRecord(LogParameters, 
			              EventLogLevel.Error,
			              "",
			              ErrorText,
			              "Error records document_ set prices_");
			
			TransferResult.Result = False;
			TransferResult.ErrorDescription = ErrorText;
			
		EndIf;
			
	EndIf;
			
	Return TransferResult;
	
EndFunction

// Creating a new individual price type and filling it with customer agreement data
// 
// Parameters:
// 	IPLOwner - CatalogRef.TermsOfSale, CatalogRef.Partners, CatalogRef.Warehouses, CatalogRef.StoreFormats, - Owner of the IPL
// 	Date - Date - Date for creating the document setting prices
// Returns:
// 	Structure - See SettingPricesServer.InitializeResultStructure
//
Function CreateIPL(IPLOwner, Date) Export

	TransferResult = InitializeResultStructure();
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Description");
	AttributesStructure1.Insert("SpecialPriceType");

	If TypeOf(IPLOwner) = Type("CatalogRef.TermsOfSale") Then 
		AttributesStructure1.Insert("PricesKind");
		AttributesStructure1.Insert("Goods");
		AttributesStructure1.Insert("PriceGroups");
		AttributesStructure1.Insert("Currency");
		AttributesStructure1.Insert("PriceIncludesVAT");
	ElsIf TypeOf(IPLOwner) = Type("CatalogRef.Partners") Then 
		AttributesStructure1.Insert("PricesKind");
	ElsIf TypeOf(IPLOwner) = Type("CatalogRef.Warehouses")
			Or TypeOf(IPLOwner) = Type("CatalogRef.StoreFormats") Then
		AttributesStructure1.Insert("RetailPriceType");
	EndIf;

	ObjectAttributes = Common.ObjectAttributesValues(IPLOwner, AttributesStructure1);
	
	SpecialPriceType = ObjectAttributes.SpecialPriceType;
	
	If TypeOf(IPLOwner) = Type("CatalogRef.TermsOfSale") Then
		 
		PriceGroups = ObjectAttributes.PriceGroups.Unload();
		Goods = ObjectAttributes.Goods.Unload();
		
	Else
		
		PriceGroups = New ValueTable();
		Goods = New ValueTable();
		
	EndIf;

	If Not ValueIsFilled(SpecialPriceType) Then
		// we create an individual view of prices
		ParametersForCreatingNewPriceView = Catalogs.TypesOfPrices.InitializeParametersForCreatingPriceView();
		ParametersForCreatingNewPriceView.Description = ObjectAttributes.Description;
		ParametersForCreatingNewPriceView.Status = Enums.StatusesOfPriceTypeValidity.Valid;
		ParametersForCreatingNewPriceView.UseForWholesaleToCustomers = True;
		ParametersForCreatingNewPriceView.UseWhileSellingToCustomers = True;
		
		If TypeOf(IPLOwner) = Type("CatalogRef.TermsOfSale") Then
		
			FillPropertyValues(ParametersForCreatingNewPriceView, ObjectAttributes, "PriceIncludesVAT");
			ParametersForCreatingNewPriceView.PriceCurrency = ObjectAttributes.Currency;
			ParametersForCreatingNewPriceView.Purpose = Enums.PriceTypesAssignment.SpecialForTermsOfSales;
			
		ElsIf TypeOf(IPLOwner) = Type("CatalogRef.Partners") Then 
			ParametersForCreatingNewPriceView.Purpose = Enums.PriceTypesAssignment.SpecialForPartner;
		ElsIf TypeOf(IPLOwner) = Type("CatalogRef.Warehouses") Then
			ParametersForCreatingNewPriceView.Purpose = Enums.PriceTypesAssignment.SpecialForWarehouse;
		ElsIf  TypeOf(IPLOwner) = Type("CatalogRef.StoreFormats") Then
			ParametersForCreatingNewPriceView.Purpose = Enums.PriceTypesAssignment.SpecialForStoreFormat;
		EndIf;
		
		ParametersForCreatingNewPriceView.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes;
		If ObjectAttributes.Property("PricesKind") And ValueIsFilled(ObjectAttributes.PricesKind) Then
			IDOfPriceType = Common.ObjectAttributeValue(ObjectAttributes.PricesKind, "Id");
			ParametersForCreatingNewPriceView.Formula = "[" + IDOfPriceType + "]";
		ElsIf ObjectAttributes.Property("RetailPriceType") And ValueIsFilled(ObjectAttributes.RetailPriceType) Then
			IDOfPriceType = Common.ObjectAttributeValue(ObjectAttributes.RetailPriceType, "Id");
			ParametersForCreatingNewPriceView.Formula = "[" + IDOfPriceType + "]";
		Else
			ParametersForCreatingNewPriceView.Formula = "0";
		EndIf;
		
		If PriceGroups.Count() Then
			
			For Each String In PriceGroups Do
				
				If ValueIsFilled(String.PricesKind) Then
					
					NewRow = ParametersForCreatingNewPriceView.PriceGroups.Add();
					NewRow.PriceGroup = String.PriceGroup;
					IDOfPriceType = Common.ObjectAttributeValue(String.PricesKind, "Id");
					NewRow.Formula = "[" + IDOfPriceType + "]";
					
				EndIf;

			EndDo;
			
		EndIf;

		BeginTransaction();
		Try
			CreationResult = Catalogs.TypesOfPrices.CreateNewPriceView(ParametersForCreatingNewPriceView);
	
			If CreationResult.Result Then
				SpecialPriceType = CreationResult.Ref;
	
				Catalogs.TermsOfSale.InstallIPL(IPLOwner, SpecialPriceType);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			LogParameters = New Structure("EventGroup_, Metadata, Data");
			TextEventGroup = NStr("vi = 'Tạo bảng giá riêng biệt.';
									|ru = 'Создание ИПЛ.';
									|en = 'Generating IPL.'; fa = 'Generating IPL.';
									|it = 'Creazione IPL.';
									|pl = 'Utworzenie Cennika indywidualnego.';
									|tr = 'ÖFL oluşturma.'", Common.DefaultLanguageCode());	
			
			LogParameters.EventGroup_ = TextEventGroup;
			LogParameters.Metadata    = Metadata.Catalogs.TermsOfSale;
			LogParameters.Data        = IPLOwner;
	
			ErrorText = NStr("vi = 'Lỗi tạo bảng giá riêng biệt. Theo đối tượng chủ';
							|ru = 'Ошибка создания ИПЛ. По владельцу';
							|en = 'Error creating IPL. By owner'; fa = 'Error creating IPL. By owner';
							|it = 'Errore di creazione IPL. Per proprietario';
							|pl = 'Błąd utworzenia Cennika indywidualnego. Wg właściciela';
							|tr = 'ÖFL oluşturma hatası. Sahibine göre'", Common.DefaultLanguageCode()) + " '"+ IPLOwner +"'";
			
			LogRecord(LogParameters, 
			              EventLogLevel.Error,
			              "",
			              ErrorText,
			              TransferResult.ErrorDescription);
	
			TransferResult.Result = False;
			TransferResult.ErrorDescription = ErrorText;

			Return TransferResult;
				
		EndTry;
		
	EndIf;
	
	If ValueIsFilled(SpecialPriceType) Then
		
		// initialization of structures for calculation
	 	ShapeStructure = InitializeFormStructure();
		ShapeStructure.UsePriceManagementSystem25 = False;
		ShapeStructure.Date = Date;
	
		LineViewPrices = ShapeStructure.Object.TypesOfPrices.Add();
		LineViewPrices.PriceKind = SpecialPriceType;

		SettingPricesServer.InitializeSelectedPrices(ShapeStructure);
		ShapeStructure.DataLayoutSettingsTable = GetFromTempStorage(ShapeStructure.StorageAddressDataLayoutSettings);
		If ShapeStructure.SelectedPrices.Columns.Find("DataCompositionSchema") = Undefined Then
			ShapeStructure.SelectedPrices.Columns.Add("DataCompositionSchema");
		EndIf;
				
		For Each LineViewPrices In ShapeStructure.SelectedPrices Do
			Schema = New ValueStorage(GetFromTempStorage(LineViewPrices.AddressOfDataCompositionSchema));
			LineViewPrices.DataCompositionSchema	= Schema.Get();
		EndDo;

		// 	fill in the items according to the selection of the nomenclature
		ShapeStructure.PriceTree.Rows.Clear();
		SettingPricesServer.BuildPriceTree(ShapeStructure);

		AddProductsByPriceGroupAndProduct(ShapeStructure, SpecialPriceType, PriceGroups, Goods);
	
		//	fill out and write down the document
		CommentText1 = NStr("vi = 'Tạo bảng giá riêng biệt trên cơ sở thỏa thuận với khách hàng. Đối tượng chủ << %IPLOwner% >>';
							|ru = 'Создание ИПЛ на основании соглашений с клиентами. Владелец << %IPLOwner% >>';
							|en = 'Creation of IPL based on agreements with clients. Owner << %IPLOwner% >>'; fa = 'Creation of IPL based on agreements with clients. Owner << %IPLOwner% >>';
							|it = 'Creazione IPL in base agli accordi con i clienti. Proprietario << %IPLOwner% >>';
							|pl = 'Utworzenie Cennika indywidualnego na podstawie umów z klientami. Właściciel << %IPLOwner% >>';
							|tr = 'İstemcilerle yapılan anlaşmalara dayalı olarak ÖFL''nin oluşturulması. Sahip << %IPLOwner% >>'", Common.DefaultLanguageCode());
		CommentText1 = StrReplace(CommentText1, "%IPLOwner%", IPLOwner);
		
		ResultOfSettingPrices = Documents.PriceSetup.RecordPriceChangesOnServer(ShapeStructure, CommentText1, 1);
		
		If ResultOfSettingPrices = Undefined Then
			
			LogParameters = New Structure("EventGroup_, Metadata, Data");
			TextEventGroup = NStr("vi = 'Tạo bảng giá riêng biệt.';
									|ru = 'Создание ИПЛ.';
									|en = 'Generating IPL.'; fa = 'Generating IPL.';
									|it = 'Creazione IPL.';
									|pl = 'Utworzenie Cennika indywidualnego.';
									|tr = 'ÖFL oluşturma.'", Common.DefaultLanguageCode());	
			
			LogParameters.EventGroup_ = TextEventGroup;
			LogParameters.Metadata    = Metadata.Catalogs.TypesOfPrices;
			LogParameters.Data        = IPLOwner;
							
			ErrorText = NStr("vi = 'Lỗi cập nhật đơn giá';
							|ru = 'Ошибка обновления цен';
							|en = 'Price update error'; fa = 'Price update error';
							|it = 'Errore di aggiornamento dei prezzi';
							|pl = 'Błąd aktualizacji cen';
							|tr = 'Fiyat güncelleme hatası'", Common.DefaultLanguageCode()) + " '"+ SpecialPriceType +"'";
			
			LogRecord(LogParameters, 
			              EventLogLevel.Error,
			              "",
			              ErrorText,
			              "Error records document_ set prices_");
			
			TransferResult.Result = False;
			TransferResult.ErrorDescription = ErrorText;
		
		Else
			
			TransferResult.Insert("Ref", SpecialPriceType);
			
		EndIf;
		
	Else
		
		FillPropertyValues(TransferResult, CreationResult);
		
		LogParameters = New Structure("EventGroup_, Metadata, Data");
		TextEventGroup = NStr("vi = 'Tạo bảng giá riêng biệt.';
								|ru = 'Создание ИПЛ.';
								|en = 'Generating IPL.'; fa = 'Generating IPL.';
								|it = 'Creazione IPL.';
								|pl = 'Utworzenie Cennika indywidualnego.';
								|tr = 'ÖFL oluşturma.'", Common.DefaultLanguageCode());	
		
		LogParameters.EventGroup_ = TextEventGroup;
		LogParameters.Metadata    = Metadata.Catalogs.TermsOfSale;
		LogParameters.Data        = IPLOwner;

		ErrorText = StrTemplate(NStr("vi = 'Lỗi tạo IPL. Theo đối tượng chủ ""%1""';
									|ru = 'Ошибка создания ИПЛ. По владельцу ""%1""';
									|en = 'Error creating IPL. By the ""%1"" owner'; fa = 'Error creating IPL. By the ""%1"" owner';
									|it = 'Ошибка создания ИПЛ. По владельцу ""%1""';
									|pl = 'Error creating IPL. By the ""%1"" owner';
									|tr = 'ÖFL oluşturma hatası. ""%1"" sahibine göre'", Common.DefaultLanguageCode()), IPLOwner);
		
		LogRecord(LogParameters, 
		              EventLogLevel.Error,
		              "",
		              ErrorText,
		              TransferResult.ErrorDescription);

		Return TransferResult;
		
	EndIf;
	
	Return TransferResult;
	
EndFunction

// Description: this Update features and / or series pricing
// 
// Parameters:
// 	ProductKind - CatalogRef.ItemKinds - Type of nomenclature for which you need to make a refillingtn
// 	AdditionalParameters - Structure - prameters for specifying what to re-fill
// Returns:
// 	Structure - See InitializeResultStructure
//
Function UpdateSpecificationsAndSeriesPricing(ProductKind, AdditionalParameters = Undefined) Export

	UpdateResult = InitializeResultStructure();
	
	If AdditionalParameters = Undefined Then
		
		AttributesStructure1 = New Structure;
		AttributesStructure1.Insert("SettingsOfPriceKeyByItemVariant");
		AttributesStructure1.Insert("SettingsOfPriceKeyByBatch");
		AttributesStructure1.Insert("ItemVariantsOwner");
		AttributesStructure1.Insert("BatchOwner");
	
		ObjectAttributes = Common.ObjectAttributesValues(ProductKind, AttributesStructure1);
		
		If Not ValueIsFilled(ObjectAttributes.SettingsOfPriceKeyByItemVariant) Then
			
			CatObject = ProductKind.GetObject();
			CatObject.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.DontUse;
			Try
				CatObject.Write();
			Except
				UpdateResult.Result = False;
				UpdateResult.ErrorDescription = NStr("vi = 'Lỗi khi cập nhật dạng mặt hàng';
													|ru = 'Ошибка при обновлении вида номенклатуры';
													|en = 'Error when updating item kind'; fa = 'Error when updating item kind';
													|it = 'Errore durante l''aggiornamento del tipo di articolo';
													|pl = 'Błąd podczas aktualizacji rodzaju produktu';
													|tr = 'Öğe görünümü güncellenirken hata'", Common.DefaultLanguageCode());
			EndTry;
			
		ElsIf ObjectAttributes.SettingsOfPriceKeyByItemVariant <> Enums.FilterOptionForPriceKey.DontUse
			And Not ValueIsFilled(ObjectAttributes.ItemVariantsOwner) Then
			
			If Not UpdatePricingHabits(ProductKind) Then
	
				UpdateResult.Result = False;
				UpdateResult.ErrorDescription = NStr("vi = 'Lỗi khi cập nhật đặc tính, thiết lập giá';
													|ru = 'Ошибка при обновлении характеристик ценообразования';
													|en = 'Error when updating pricing variants'; fa = 'Error when updating pricing variants';
													|it = 'Errore durante l''aggiornamento delle caratteristiche di elaborazione di prezzo';
													|pl = 'Błąd podczas aktualizacji charakterystyk tworzenia cen';
													|tr = 'Fiyatlandırma özellikleri güncellenirken hata'", Common.DefaultLanguageCode());
					
			EndIf;
			
		EndIf;
	
		If ObjectAttributes.SettingsOfPriceKeyByBatch <> Enums.FilterOptionForPriceKey.DontUse 
			And Not ValueIsFilled(ObjectAttributes.BatchOwner) Then
			
			If Not UpdateSeriesPricing(ProductKind) Then
				
				UpdateResult.Result = False;
				UpdateResult.ErrorDescription = UpdateResult.ErrorDescription + NStr("vi = 'Lỗi khi cập nhật sê-ri thiết lập giá';
																					|ru = 'Ошибка при обновлении серий ценообразования';
																					|en = 'Error when updating pricing batch'; fa = 'Error when updating pricing batch';
																					|it = 'Errore durante l''aggiornamento delle serie di elaborazione di prezzo';
																					|pl = 'Błąd podczas aktualizacji serii tworzenia cen';
																					|tr = 'Fiyatlandırma partisi güncellenirken hata'", Common.DefaultLanguageCode());
				
			EndIf;
			
		EndIf;
		
	Else
		
		If AdditionalParameters.ReplenishCharacteristics And Not UpdatePricingHabits(ProductKind) Then

			UpdateResult.Result = False;
			UpdateResult.ErrorDescription = NStr("vi = 'Lỗi khi cập nhật đặc tính, thiết lập giá';
												|ru = 'Ошибка при обновлении характеристик ценообразования';
												|en = 'Error when updating pricing variants'; fa = 'Error when updating pricing variants';
												|it = 'Errore durante l''aggiornamento delle caratteristiche di elaborazione di prezzo';
												|pl = 'Błąd podczas aktualizacji charakterystyk tworzenia cen';
												|tr = 'Fiyatlandırma özellikleri güncellenirken hata'", Common.DefaultLanguageCode());
				
		EndIf;
		
		If AdditionalParameters.ReFillSeries And Not UpdateSeriesPricing(ProductKind) Then
			
			UpdateResult.Result = False;
			UpdateResult.ErrorDescription = UpdateResult.ErrorDescription + NStr("vi = 'Lỗi khi cập nhật sê-ri thiết lập giá';
																				|ru = 'Ошибка при обновлении серий ценообразования';
																				|en = 'Error when updating pricing batch'; fa = 'Error when updating pricing batch';
																				|it = 'Errore durante l''aggiornamento delle serie di elaborazione di prezzo';
																				|pl = 'Błąd podczas aktualizacji serii tworzenia cen';
																				|tr = 'Fiyatlandırma partisi güncellenirken hata'", Common.DefaultLanguageCode());
			
		EndIf;
		
	EndIf;

	Return UpdateResult;
	
EndFunction

Function UpdateSeriesPricing(ProductKind)

	Result = True;
	
	Text = "SELECT
	|	ItemsBatches.Ref AS Ref
	|FROM
	|	Catalog.ItemsBatches AS ItemsBatches
	|WHERE
	|	ItemsBatches.ProductKind = &ProductKind";

	Query = New Query(Text);
	Query.SetParameter("ProductKind", ProductKind);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		CatObject = Selection.Ref.GetObject();
		CatObject.AdditionalProperties.Insert("UsePriceManagementSystem25", True);
		CatObject.AdditionalProperties.Insert("UpdatingPricingSettingsProductTypes", True);
		
		Try
			CatObject.Write();
		Except
			Result = False;
		EndTry;
		
	EndDo;

	Return Result;
	
EndFunction

Function UpdatePricingHabits(ProductKind)
	
	Result = True;
	
	QueryText = "SELECT
	|	ItemsCharacteristics.Ref AS Ref
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|WHERE
	|	ItemsCharacteristics.ProductKind = &ProductKind";

	Query = New Query(QueryText);
	Query.SetParameter("ProductKind", ProductKind);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		CatObject = Selection.Ref.GetObject();
		CatObject.AdditionalProperties.Insert("UsePriceManagementSystem25", True);
		CatObject.AdditionalProperties.Insert("UpdatingPricingSettingsProductTypes", True);
		
		Try
			CatObject.Write();
		Except
			Result = False;
		EndTry;
		
	EndDo;

	Return Result;
	
EndFunction

Procedure AddProductsByPriceGroupAndProduct(Form, PriceKind, PriceGroups, Goods)
	
	If PriceGroups.Count() Then
		
		AddProductsByDCSSelection(Form);
	
	EndIf;

	If Goods.Count() Then
		
		Form.AddressOfDataCacheStorage = "";
		DataCache = InitializeDataCacheStructure();
		
		PriceTypeLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, PriceKind);
		
		For Each String In Goods Do

			PriceTableRow = FindPriceTreeString(Form, String, DataCache);

			If PriceTableRow = Undefined Then
				
				Filter_Settings = SettingPricesServer.GetStructureOfDataSelectionByProduct();
				Filter_Settings.Insert("FillingVariant", "RemainingGoodsByShelfLives");
				Filter_Settings.Insert("Value", String);
				FilterValues = New Structure();
				FilterValues.Insert("RemainingGoodsByShelfLives", String.Products);
		
				If ValueIsFilled(String.Characteristic) Then
					
					ArrayOfCharacteristics = New Array();
					ArrayOfCharacteristics.Add(String.Characteristic);
					FilterValues.Insert("ByArrayOfCharacteristics", ArrayOfCharacteristics);
					
				EndIf;
				
				Filter_Settings.Insert("FilterValues", FilterValues);
				Filter_Settings.Insert("Date", Form.Date);
				Filter_Settings.Insert("UsePriceManagementSystem25", Form.UsePriceManagementSystem25);
				Filter_Settings.Insert("UseItemVariants", Form.UseItemVariants);
				Filter_Settings.Insert("UseItemsBatch", Form.UseItemsBatch);
				Filter_Settings.Insert("UseItemPackages", Form.UseItemPackages);
				
				ProductsTable = SettingPricesServer.CreateProductTable(Form);
				SettingPricesServer.GetDataOnProducts(Filter_Settings, ProductsTable);
				SettingPricesServer.AddGoodsByPicking(Form, Undefined, ProductsTable,, DataCache);
				
				PriceTableRow = FindPriceTreeString(Form, String, DataCache);
				
			EndIf;

			// Let's set a formula or a price
			
			If ValueIsFilled(PriceTableRow) Then
				
				If ValueIsFilled(String.PriceKind) Then
									
					PriceTableRow["Formula" + PriceTypeLine.ColumnName] = "[" + String.PriceKind + "]";
					PriceTableRow["FormulaChangedManually" + PriceTypeLine.ColumnName] = True;
					PriceTableRow["ChangedManually" + PriceTypeLine.ColumnName] = True;
					
				Else
					
					PriceTableRow[PriceTypeLine.ColumnName] = String.Price;
					PriceTableRow["ChangedManually" + PriceTypeLine.ColumnName] = True;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;

	//	calculate prices
	ArrayOfPriceTypes = New Array();
	ArrayOfPriceTypes.Add(PriceKind);
	
	CalculationParameters = New Structure();
	CalculationParameters.Insert("TypesOfPrices",				ArrayOfPriceTypes);
	CalculationParameters.Insert("SelectedLinesOnly",	False);
	CalculationParameters.Insert("OnlyEmpty",	True);
	CalculationParameters.Insert("ImportOldPrices",		False);
	CalculationParameters.Insert("RoundingUpManualPrices",	False);
	CalculationParameters.Insert("CalculationByFormulas",       False);

	SettingPricesServer.CalculatePrices(Form, CalculationParameters);
	
EndProcedure

#Region InitializationProcedures

// Initializes the transition state structure
//
// Returns:
//  Structure - structure with properties:
//  * DateOfMigrationToPriceManagementSystem25 - Date - Pricing start date for version 2.5
//  * StartDate - Date - Date and time when the transition started
//  * CompletedOn - Date - Date and time when the transition ends
//  * Step - Number - Transition step number
//  * State - EnumRef.JobsStates - Transition state
//  * StepParameters1 - See InitializeTransitionParameterStructure
//  * StepParameters2 - See InitializeTransitionParameterStructure
//  * StepParameters3 - See InitializeTransitionParameterStructure
//  * Initiator - CatalogRef.Users - The user is the initiator of the transition
//
Function InitializeTransitionStateStructure() Export
	
	TransitionState = New Structure;
	TransitionState.Insert("DateOfMigrationToPriceManagementSystem25", 		Date(1, 1, 1));
	TransitionState.Insert("StartDate", 		Date(1, 1, 1));
	TransitionState.Insert("CompletedOn", 	Date(1, 1, 1));
	TransitionState.Insert("Step", 				0); // 0 - not performed; 1 - Creation of the IPL; 2 - Creation of sections; 3 - Transfer of prices;
	TransitionState.Insert("State", 		Enums.JobsStates.EmptyRef());

	TransitionState.Insert("StepParameters1", 	InitializeTransitionParameterStructure(1));
	TransitionState.Insert("StepParameters2", 	InitializeTransitionParameterStructure(2));
	TransitionState.Insert("StepParameters3", 	InitializeTransitionParameterStructure(3));
	
	TransitionState.Insert("Initiator", 		Catalogs.Users.EmptyRef());
	
	Return TransitionState
	
EndFunction

// Initializes the structure of the function execution result
//
// Returns:
//  Structure - structure with properties:
//  * Result - Boolean - result of the function execution
//  * ErrorDescription - String - error description
//  * Ref - Undefined - Link if necessary
//
Function InitializeResultStructure() Export
	
	ResultStructure1 = New Structure();
	ResultStructure1.Insert("Result", True);
	ResultStructure1.Insert("ErrorDescription", "");
	ResultStructure1.Insert("Ref", Undefined);
	
	Return ResultStructure1;
	
EndFunction

// Initializes the state structure of the pricing transition step 2.5
//
// Returns:
//  Structure - structure with properties:
//  * State - EnumRef.JobsStates - Step transition state
//  * StartDate - Date - Date and time when the step transition started
//  * CompletedOn - Date - Date and time when the step transition ends
//  * TotalCount1 - Number - Number of objects to process
//  * QuantityProcessed - Number - Number of objects processed
//  * ErrorsCount - Number - Number of objects processed with an error
//  * TableForProcessing - See InitializeTableForProcessing
//
Function InitializeTransitionParameterStructure(StepNumber)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("State",			New TypeDescription("EnumRef.JobsStates"));
	ParametersStructure.Insert("StartDate", 			Date(1, 1, 1));
	ParametersStructure.Insert("CompletedOn", 		Date(1, 1, 1));
	
	ParametersStructure.Insert("TotalCount1", 	0);
	ParametersStructure.Insert("QuantityProcessed",0);
	ParametersStructure.Insert("ErrorsCount", 	0);
	
	ParametersStructure.Insert("TableForProcessing", InitializeTableForProcessing(StepNumber));
	
	Return ParametersStructure;
	
EndFunction

// Initializes the table for pricing transition data.
//
// Returns:
//  ValueTable - table with columns:
//  * Ref - CatalogRef.TermsOfSale, CatalogRef.ItemKinds, CatalogRef.TypesOfPrices - Reference to the object being processed
//  * State - EnumRef.JobsStates - The processing state of the object
//  * ErrorDescription - String - error description
//
Function InitializeTableForProcessing(StepNumber)

	TableOfSelectedPrices = New ValueTable();
	If StepNumber = 1 Then
		
		TableOfSelectedPrices.Columns.Add("Ref",	New TypeDescription("CatalogRef.TermsOfSale"));
		
	ElsIf StepNumber = 2 Then
		 
		TableOfSelectedPrices.Columns.Add("Ref",	New TypeDescription("CatalogRef.ItemKinds"));
		
	ElsIf StepNumber = 3 Then
		 
		TableOfSelectedPrices.Columns.Add("Ref",	New TypeDescription("CatalogRef.TypesOfPrices"));
		
	EndIf;
	
	TableOfSelectedPrices.Columns.Add("State",	New TypeDescription("EnumRef.JobsStates"));
	TableOfSelectedPrices.Columns.Add("ErrorDescription",	New TypeDescription("String"));
	
	Return TableOfSelectedPrices;
	
EndFunction

#EndRegion

#EndRegion

// Returns the date for executing the request for item prices
//
// Parameters:
//  Form - See BuildPriceTree.Form
//
// Returns:
//  Date
//
Function DateForRequestingProductPrices(Form)
	
	Return DocumentDate(Form) - 1;
	
EndFunction

// Returns the date when prices were set
//
// Parameters:
//  Form - See BuildPriceTree.Form
//
// Returns:
//  Date
//
Function DocumentDate(Form)
	
	Date = Undefined;
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Date") Then
		Date = Form.Object.Date;
	Else
		Date = Form.Date;
	EndIf;
	
	Return ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 	ArrayOfPriceTypes - Array of CatalogRef.VendorPriceTypes
Procedure InitializeSelectedProductPrices(Form, ArrayOfPriceTypes = Undefined,TableOfPriceTypes = Undefined)
	
	// The table of settings of the SCD for types of prices with the price calculation algorithm "Fill in according to information security data".
	DataCompositionSettings = LoadDataLayoutSettingsTable(Form);
	
	Form.SelectedPrices.Clear();
	
	Table = DownloadPriceCatalog(Form, DataCompositionSettings, ArrayOfPriceTypes, TableOfPriceTypes);
	For Each TSRow In Table Do
		
		If TSRow.Status = Enums.StatusesOfPriceTypeValidity.Valid Or
			(TMCommonUseClientServer.HasObjectAttribute(Form.Object, "TypesOfPrices") And
			Form.Object.TypesOfPrices.FindRows(New Structure("PriceKind", TSRow.Ref)).Count()>0) Then
		
			NewRow = Form.SelectedPrices.Add();
			NewRow.SetPriceDuringGeneration = TSRow.SetPriceDuringGeneration;
			NewRow.Formula                              = TSRow.Formula;
			NewRow.Currency                               = TSRow.Currency;
			NewRow.Id                        = TSRow.Id;
			NewRow.ColumnName                           = TSRow.ColumnName;
			NewRow.Description                         = TSRow.Description;
			NewRow.RoundOffOption                    = TSRow.RoundOffOption;
			NewRow.ThresholdOnPriceIncreaseFor                    = TSRow.ThresholdOnPriceIncreaseFor;
			NewRow.ThresholdOnPriceDecreaseBy       = TSRow.ThresholdOnPriceDecreaseBy;
			NewRow.AddlOrderingAttribute            = TSRow.AddlOrderingAttribute;
			NewRow.PricingMethod                    = TSRow.PricingMethod;
			NewRow.Ref                               = TSRow.Ref;
			NewRow.Level                              = TSRow.Level;
			NewRow.ProhibitedPriceType                   = TSRow.ProhibitedPriceType;
			NewRow.BasicPriceType                       = TSRow.BasicPriceType;
			NewRow.Markup                              = TSRow.Markup;
			NewRow.DeletionMark                      = TSRow.DeletionMark;
			NewRow.DateOfTheLastPriceSetting           = TSRow.DateOfTheLastPriceSetting;
			NewRow.DisablePriceEditingOutsideFilter	= TSRow.DisablePriceEditingOutsideFilter;
			NewRow.OptionForSpecifyingVATRates						= TSRow.OptionForSpecifyingVATRates;
			NewRow.Country											= TSRow.Country;
			NewRow.VATRate										= TSRow.VATRate;
			
			// Service fields for working with SKD settings
			NewRow.AddressOfDataCompositionSchema         = TSRow.AddressOfDataCompositionSchema;
			NewRow.AddressOfDataCompositionSchemaSettings = TSRow.AddressOfDataCompositionSchemaSettings;
			NewRow.AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem = TSRow.AddressOfTheLayoutSchemeSettingsForTheSelectionDataByItem;
			NewRow.RequiredParametersAreFound       = TSRow.RequiredParametersAreFound;
			NewRow.Parameters                          = TSRow.Parameters;
			
			If TypeOf(Form) = Type("ClientApplicationForm") Then
				
				NewRow.Thresholds.Load(TSRow.Thresholds);
				NewRow.PriceRoundingRules.Load(TSRow.PriceRoundingRules);
				NewRow.PriceGroups.Load(TSRow.PriceGroups);
				NewRow.InfluencingPriceTypes.Load(TSRow.InfluencingPriceTypes);
				NewRow.Currencies.Load(TSRow.Currencies);
				
			Else
					
				NewRow.Thresholds		= TSRow.Thresholds.Copy();
				NewRow.PriceRoundingRules	= TSRow.PriceRoundingRules.Copy();
				NewRow.PriceGroups			= TSRow.PriceGroups.Copy();
				NewRow.InfluencingPriceTypes			= TSRow.InfluencingPriceTypes.Copy();
				NewRow.Currencies					= TSRow.Currencies.Copy();
				
			EndIf;
			
			NewRow.InfluencingPrices.LoadValues(TSRow.InfluencingPrices.UnloadValues());
			NewRow.DependentPrices.LoadValues(TSRow.DependentPrices.UnloadValues());
			
		EndIf;
		
	EndDo;
	Form.SelectedPrices.Sort("Level");
	
	ThereAreTypesOfDCSPrices = False;
	ThereAreKindsOfPrices = False;
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "TypesOfPrices") Then
		For Each TSRow In Form.Object.TypesOfPrices Do
			PriceViewString = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, TSRow.PriceKind);
			If PriceViewString <> Undefined Then
				PriceViewString.Selected_5 = True;
				PriceViewString.Edit = True;
			EndIf;
		EndDo;
	EndIf;
	
	For Each PriceViewString In Form.SelectedPrices Do
		If PriceViewString.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
			Or PriceViewString.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt 
			Or PriceViewString.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
			Or PriceViewString.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
			Or PriceViewString.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost	Then
			ThereAreTypesOfDCSPrices = True;
		EndIf;
		If PriceViewString.PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup
			Or PriceViewString.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
			
			ThereAreKindsOfPrices = True;
			PriceViewString.FormulaIsBeingEdited = True;
			
		EndIf;
	EndDo;
	
	If ThereAreKindsOfPrices Then
		// Fill in the "Affects" and "Depends" flags
		For Each PriceKind In Form.SelectedPrices Do
			PriceKind.Depends = False;
			PriceKind.Influences  = False;
		EndDo;
		
		For Each PriceKind In Form.SelectedPrices Do
			
			If PriceKind.Selected_5 Then
				
				For Each DependentPrice In PriceKind.DependentPrices Do
					DependentPriceLine         = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, DependentPrice.Value);
					If DependentPriceLine <> Undefined Then
						DependentPriceLine.Depends = Not DependentPriceLine.Selected_5;
					EndIf;
				EndDo;
				
				For Each InfluencingPrice In PriceKind.InfluencingPrices Do
					SelectedPriceLine        = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, InfluencingPrice.Value);
					If SelectedPriceLine <> Undefined Then
						SelectedPriceLine.Influences = Not SelectedPriceLine.Selected_5;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesSelectAllInfluencingPrices",  "Visible", ThereAreKindsOfPrices);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesSelectAllDependentPrices", "Visible", ThereAreKindsOfPrices);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesDependentPrices",       "Visible", ThereAreKindsOfPrices);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesInfluencingPrices",        "Visible", ThereAreKindsOfPrices);
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "PriceTreeWillDisplayInfluencingPrices", "Visible", ThereAreKindsOfPrices);
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesGroupParameters",                  "Visible", ThereAreTypesOfDCSPrices);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesRestoreDefaultSettings", "Visible", ThereAreTypesOfDCSPrices);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "SelectedPricesEditSettings",           "Visible", ThereAreTypesOfDCSPrices);
	
	EndIf;
	
	Form.StorageAddressDataLayoutSettings = PutToTempStorage(DataCompositionSettings, Form.UUID);
	
EndProcedure

Procedure InitializeSelectedSupplierPrices(Form)
	
	Form.SelectedPrices.Clear();
	
	If Not ValueIsFilled(Form.Object.Partner) Then
		Return;
	EndIf;
	
	TS = Form.Object.Goods.Unload();
	TS.GroupBy("VendorPriceKind");
	
	Count = TS.Count();
	
	Table = DownloadSupplierSPriceCatalog(Form);
	For Each TSRow In Table Do
		NewRow = Form.SelectedPrices.Add();
		FillPropertyValues(NewRow, TSRow);
		NewRow.Selected_5 = TS.Find(TSRow.Ref, "VendorPriceKind") <> Undefined Or Count = 0;
	EndDo;
	
EndProcedure

// Fills in the price values calculated from the information base data
//
// Parameters:
//  ProductsTable - See CreateProductTable
//  PriceTypeLine - CatalogRef.TypesOfPrices - Type of price
//  OnlyEmpty - Boolean - Indicates that only unfilled prices should be calculated.
//
Procedure CalculatePriceValuesBasedOnInformationSecurityData(Form,
	                                      ProductsTable,
	                                      PriceTypeLine,
	                                      OnlyEmpty,
	                                      DataCompositionSettings,
	                                      DataCache)
	
	Form.Modified = True;
	
	SetPrivilegedMode(True);
	
	If ProductsTable.Count() > 0 Then
		
		If PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
			
			// Copying the data layout scheme
			If TypeOf(Form) = Type("ClientApplicationForm") Then
				
				Schema = New ValueStorage(GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchema));
				DataCompositionSchema = Schema.Get();
				
			ElsIf TypeOf(Form) = Type("Structure") Then
				
				Schema = New ValueStorage(PriceTypeLine.DataCompositionSchema);
				DataCompositionSchema = Schema.Get();
				
			EndIf;
			
			DCSCheckPassed = PriceManagementSystem.CheckDataLayoutScheme(DataCompositionSchema,
				StrReplace(NStr("vi = 'Dạng giá ""%PriceKind%""';
								|ru = 'Вид цены ""%PriceKind%""';
								|en = 'Price type ""%PriceKind%""'; fa = 'Price type ""%PriceKind%""';
								|it = 'Tipo di prezzo ""%PriceKind%""';
								|pl = 'Rodzaj ceny ""%PriceKind%""';
								|tr = 'Fiyat türü ""%PriceKind%""'"),
					"%PriceKind%",
					PriceTypeLine.Ref));
			
			If DCSCheckPassed Then
				
				// Filling in the data set of the Nomenclature table
				WorkingDataset = DataCompositionSchema.DataSets[0];
				
				QueryText = WorkingDataset.Query;
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor1", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package", 
						"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
				
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor2", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"DocumentGoods.Package", 
						"DocumentGoods.Products"));
						
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor3", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"GoodsDocumentInputBasedOn.Package", 
						"GoodsDocumentInputBasedOn.Products"));
					
				WorkingDataset.Query = QueryText;
				
				DataSetProducts                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
				DataSetProducts.Name            = "ProductsTable";
				DataSetProducts.ObjectName     = "ProductsTable";
				DataSetProducts.DataSource = WorkingDataset.DataSource;
				
				AddDCSDataSetField(DataSetProducts, "Products", "CatalogRef.Products");
				If Form.UseItemVariants Then
					AddDCSDataSetField(DataSetProducts, "Characteristic", "CatalogRef.ItemsCharacteristics");
				EndIf;
				
				DataCompositionSchema.DataSetLinks.Clear();
				AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "Products");
				
				If Form.UseItemVariants Then
					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "Characteristic");
				EndIf;
				
				// Preparing a data layout layout builder, loading settings
				SettingsComposer = New DataCompositionSettingsComposer;
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
				
				If DataCompositionSettings <> Undefined Then
					SettingsComposer.LoadSettings(DataCompositionSettings);
					SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
				Else
					
					If ValueIsFilled(PriceTypeLine.AddressOfDataCompositionSchemaSettings) Then
						SettingsFromPriceView = GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchemaSettings);
						SettingsComposer.LoadSettings(SettingsFromPriceView);
						SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
					Else
						SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
					EndIf;
					
				EndIf;
				
				// Filling in the report structure and selected fields.
				SettingsComposer.Settings.Structure.Clear();
				
				DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
				DetailedRecordsGroup.Use = True;
				
				SettingsComposer.Settings.Selection.Items.Clear();
				AddSelectedDCSField(DetailedRecordsGroup, "Products");
				
				If Form.UseItemVariants Then
					AddSelectedDCSField(DetailedRecordsGroup, "Characteristic");
				EndIf;
				
				If Form.UseItemPackages Then
					AddSelectedDCSField(DetailedRecordsGroup, "Package");
					AddSelectedDCSField(DetailedRecordsGroup, "ZoomRatio");
				EndIf;
				
				AddSelectedDCSField(DetailedRecordsGroup, "Price");
				AddSelectedDCSField(DetailedRecordsGroup, "Currency");
				
				LayoutOptions = SettingsComposer.Settings.DataParameters.Items;
				If ThisIsSettingProductPrices(Form) Then
					Parameter = LayoutOptions.Find("Basis");
					If Parameter <> Undefined Then
						Parameter.Value = Form.Object.DocumentBasis;
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
					Parameter = LayoutOptions.Find("ThisIsGenerationFromBaseDocuments");
					If Parameter <> Undefined Then
						Parameter.Value = ValueIsFilled(Form.Object.DocumentBasis);
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
				EndIf;
				Parameter = LayoutOptions.Find("ExcludedBusinessTransactions");
				If Parameter <> Undefined Then
					Parameter.Value = CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements();
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("DocumentDate");
				If Parameter <> Undefined Then
					Parameter.Value = DocumentDate(Form);
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("PriceKind");
				If Parameter <> Undefined Then
					Parameter.Value = PriceTypeLine.Ref;
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("Currency");
				If Parameter <> Undefined Then
					Parameter.Value = PriceTypeLine.Currency;
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				
				// Layout layout and query execution.
				TemplateComposer = New DataCompositionTemplateComposer;
				SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
				CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
				
				ExternalDataSets = New Structure;
				ExternalDataSets.Insert("ProductsTable", ProductsTable.Copy(, "Products, Characteristic"));
				
				CompositionProcessor = New DataCompositionProcessor;
				CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets,,True);
				OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

				ReportData = New ValueTable();
				OutputProcessor.SetObject(ReportData);
				ReportData = OutputProcessor.Output(CompositionProcessor);
				
				If Form.UseItemPackages Then
					TableOfCoefficientsOfProductPackages = CoefficientsOfPackagesOfProductsTreeTree(Form);
				Else
					TableOfCoefficientsOfProductPackages = Undefined;
				EndIf;
				
				ParametersStructure = New Structure();
				ParametersStructure.Insert("OnlyEmpty",  OnlyEmpty);
				ParametersStructure.Insert("ApplyRounding_",  True);
				ParametersStructure.Insert("LoadingPackaging",    False);
				ParametersStructure.Insert("AutoCalculate", True);

				If PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
					
					ParametersStructure.Insert("Rate_", True);
					LoadPricesFromValueTable(
						Form,
						ReportData,
						TableOfCoefficientsOfProductPackages,
						DataCache,
						PriceTypeLine,
						ParametersStructure);
					
				Else
					
					ParametersStructure.Insert("Rate_", False);
					LoadPricesFromValueTable(Form,
						ReportData,
						TableOfCoefficientsOfProductPackages,
						DataCache,
						PriceTypeLine,
						ParametersStructure);
					
				EndIf;
				
			Else
				
				ErrorText = StrTemplate(ErrorTemplateForCalculatingPriceAccordingToInfobaseData(),
					PriceTypeLine.Ref);
				
				CommonClientServer.MessageToUser(ErrorText);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the price values calculated from the information base data
//
// Parameters:
//  Form - ClientApplicationForm - 
//  ProductsTable - ValueTable - table of data for the item.
//  PriceTypeLine - FormDataCollectionItem - Price type string
//  OnlyEmpty - Boolean- Indicates that only unfilled prices should be calculated.
//  DataCompositionSettings - DataCompositionSettings - 
//  DataCache - See InitializeDataCacheStructure
//
Procedure CalculatePriceValuesBasedOnInformationSecurityData2_5(Form,
	                                      ProductsTable,
	                                      PriceTypeLine,
	                                      OnlyEmpty,
	                                      DataCompositionSettings,
	                                      DataCache)
	
	Form.Modified = True;
	
	SetPrivilegedMode(True);
	
	If ProductsTable.Count() > 0 Then
		
		If PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
			Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
			
			// Copying the data layout scheme
			If TypeOf(Form) = Type("ClientApplicationForm") Then
				
				Schema = New ValueStorage(GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchema));
				DataCompositionSchema = Schema.Get();
				
			ElsIf TypeOf(Form) = Type("Structure") Then
				
				Schema = New ValueStorage(PriceTypeLine.DataCompositionSchema);
				DataCompositionSchema = Schema.Get();
				
			EndIf;
			
			Cancel = False;
			
			DCSCheckPassed = PriceManagementSystem.CheckDataLayoutScheme(DataCompositionSchema, StrReplace(NStr("vi = 'Dạng giá ""%PriceKind%""';
																												|ru = 'Вид цены ""%PriceKind%""';
																												|en = 'Price type ""%PriceKind%""'; fa = 'Price type ""%PriceKind%""';
																												|it = 'Tipo di prezzo ""%PriceKind%""';
																												|pl = 'Rodzaj ceny ""%PriceKind%""';
																												|tr = 'Fiyat türü ""%PriceKind%""'"), "%PriceKind%", PriceTypeLine.Ref), False);
			DCSCheckPassed2_5 = PriceManagementSystem.CheckDataLayoutScheme2_5(DataCompositionSchema, StrReplace(NStr("vi = 'Dạng giá ""%PriceKind%""';
																														|ru = 'Вид цены ""%PriceKind%""';
																														|en = 'Price type ""%PriceKind%""'; fa = 'Price type ""%PriceKind%""';
																														|it = 'Tipo di prezzo ""%PriceKind%""';
																														|pl = 'Rodzaj ceny ""%PriceKind%""';
																														|tr = 'Fiyat türü ""%PriceKind%""'"), "%PriceKind%", PriceTypeLine.Ref), False);
			If DCSCheckPassed2_5 Then
				
				// Filling in the data set of the Nomenclature table
				WorkingDataset = DataCompositionSchema.DataSets[0];
				
				QueryText = WorkingDataset.Query;
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor1", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package", 
						"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
				
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor2", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"DocumentGoods.Package", 
						"DocumentGoods.Products"));
						
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor3", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"GoodsDocumentInputBasedOn.Package", 
						"GoodsDocumentInputBasedOn.Products"));
					
				WorkingDataset.Query = QueryText;
				
				DataSetProducts                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
				DataSetProducts.Name            = "ProductsTable";
				DataSetProducts.ObjectName     = "ProductsTable";
				DataSetProducts.DataSource = WorkingDataset.DataSource;
				
				DataCompositionSchema.DataSetLinks.Clear();
				
				AddDCSDataSetField(DataSetProducts, "Products", "CatalogRef.Products");
				AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "Products");
				
				If Form.UseItemVariants Then
					AddDCSDataSetField(DataSetProducts, "PricingVariant", "CatalogRef.ItemsCharacteristicsForPricing");
					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "PricingVariant");
				EndIf;
				
				If Form.UseItemsBatch Then
					AddDCSDataSetField(DataSetProducts, "PricingBatch",         "CatalogRef.ItemsBatchesForPricing");
					AddDCSDataSetField(DataSetProducts, "TSOSeriesForCommunication", "CatalogRef.ItemsBatchesForPricing");
					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "TSOSeriesForCommunication");
				EndIf;
				
				If Form.UseItemPackages Then
					AddDCSDataSetField(DataSetProducts, "PricingPackage", "CatalogRef.PackagesAndUnitsOfMeasure");
					AddDCSDataSetField(DataSetProducts, "TsoPackagingForCommunication", "CatalogRef.PackagesAndUnitsOfMeasure");
					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "TsoPackagingForCommunication");
				EndIf;
				
				// Preparing a data layout layout builder, loading settings
				SettingsComposer = New DataCompositionSettingsComposer;
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
				
				If DataCompositionSettings <> Undefined Then
					SettingsComposer.LoadSettings(DataCompositionSettings);
					SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
				Else
					
					If ValueIsFilled(PriceTypeLine.AddressOfDataCompositionSchemaSettings) Then
						SettingsFromPriceView = GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchemaSettings);
						SettingsComposer.LoadSettings(SettingsFromPriceView);
						SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
					Else
						SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
					EndIf;
					
				EndIf;
				
				// Filling in the report structure and selected fields.
				SettingsComposer.Settings.Structure.Clear();
				
				DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
				DetailedRecordsGroup.Use = True;
				
				SettingsComposer.Settings.Selection.Items.Clear();
				AddSelectedDCSField(DetailedRecordsGroup, "Products");
				
				If Form.UseItemVariants Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingVariant");
				EndIf;
				
				If Form.UseItemsBatch Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingBatch");
					AddSelectedDCSField(DetailedRecordsGroup, "TSOSeriesForCommunication");
				EndIf;
				
				If Form.UseItemPackages Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingPackage");
					AddSelectedDCSField(DetailedRecordsGroup, "TsoPackagingForCommunication");
					AddSelectedDCSField(DetailedRecordsGroup, "Package");
					AddSelectedDCSField(DetailedRecordsGroup, "ZoomRatio");
				EndIf;
				
				AddSelectedDCSField(DetailedRecordsGroup, "Price");
				AddSelectedDCSField(DetailedRecordsGroup, "Currency");
				
				LayoutOptions = SettingsComposer.Settings.DataParameters.Items;
				If ThisIsSettingProductPrices(Form) Then
					Parameter = LayoutOptions.Find("Basis");
					If Parameter <> Undefined Then
						Parameter.Value = Form.Object.DocumentBasis;
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
					Parameter = LayoutOptions.Find("ThisIsGenerationFromBaseDocuments");
					If Parameter <> Undefined Then
						Parameter.Value = ValueIsFilled(Form.Object.DocumentBasis);
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
				EndIf;
				Parameter = LayoutOptions.Find("ExcludedBusinessTransactions");
				If Parameter <> Undefined Then
					Parameter.Value = CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements();
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("DocumentDate");
				If Parameter <> Undefined Then
					Parameter.Value = DocumentDate(Form);
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("PriceKind");
				If Parameter <> Undefined Then
					Parameter.Value = PriceTypeLine.Ref;
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("Currency");
				If Parameter <> Undefined Then
					Parameter.Value = PriceTypeLine.Currency;
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				
				TempTablesManager = Undefined;
				Parameter = LayoutOptions.Find("UseDocumentData");
				If Parameter <> Undefined Then
					PutTableDataInTemporaryTableManager(TempTablesManager, Parameter, ProductsTable, PriceTypeLine);
				EndIf;
				
				// Layout layout and query execution.
				TemplateComposer = New DataCompositionTemplateComposer;
				SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
				CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
				
				ExternalDataSets = New Structure;
				ExternalDataSets.Insert("ProductsTable", ProductsTable.Copy(, "Products, PricingVariant, PricingBatch, TSOSeriesForCommunication, PricingPackage, TsoPackagingForCommunication"));
				
				CompositionProcessor = New DataCompositionProcessor;
				CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets,,True,, TempTablesManager);
				OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

				ReportData = New ValueTable();
				OutputProcessor.SetObject(ReportData);
				ReportData = OutputProcessor.Output(CompositionProcessor);
				
			ElsIf DCSCheckPassed Then
								
				// Filling in the data set of the Nomenclature table
				WorkingDataset = DataCompositionSchema.DataSets[0];
				
				QueryText = WorkingDataset.Query;
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor1", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package", 
						"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
				
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor2", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"DocumentGoods.Package", 
						"DocumentGoods.Products"));
						
				QueryText = StrReplace(
					QueryText, 
					"&QueryTextPackagingFactor3", 
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"GoodsDocumentInputBasedOn.Package", 
						"GoodsDocumentInputBasedOn.Products"));
					
				WorkingDataset.Query = QueryText;
				
				DataSetProducts                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
				DataSetProducts.Name            = "ProductsTable";
				DataSetProducts.ObjectName     = "ProductsTable";
				DataSetProducts.DataSource = WorkingDataset.DataSource;
				
				DataSetTransformation                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
				DataSetTransformation.Name            = "DataForTransformation";
				DataSetTransformation.DataSource = WorkingDataset.DataSource;
				DataSetTransformation.Query = GetRequestTextForTransformation();
			
				DataCompositionSchema.DataSetLinks.Clear();
				
				AddDCSDataSetField(DataSetProducts, "Products", "CatalogRef.Products");

				AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts,  DataSetTransformation, "Products");
				AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetTransformation, WorkingDataset,       "Products");
				
				If Form.UseItemVariants Then
					AddDCSDataSetField(DataSetProducts, "PricingVariant", "CatalogRef.ItemsCharacteristicsForPricing");

					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts,  DataSetTransformation, "PricingVariant", "PricingVariant");
					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetTransformation, WorkingDataset,       "Characteristic",   "Characteristic");
				EndIf;
				
				If Form.UseItemsBatch Then
					AddDCSDataSetField(DataSetProducts, "PricingBatch",         "CatalogRef.ItemsBatchesForPricing");
				EndIf;
				
				If Form.UseItemPackages Then
					AddDCSDataSetField(DataSetProducts, "PricingPackage", "CatalogRef.PackagesAndUnitsOfMeasure");
					AddDCSDataSetField(DataSetProducts, "TsoPackagingForCommunication", "CatalogRef.PackagesAndUnitsOfMeasure");
					AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "TsoPackagingForCommunication", "Package");
				EndIf;
				
				Total             = DataCompositionSchema.TotalFields.Add();
				Total.DataPath = "Price";
				Total.Expression   = "Max(Price)";

				// Preparing a data layout layout builder, loading settings
				SettingsComposer = New DataCompositionSettingsComposer;
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
				
				If DataCompositionSettings <> Undefined Then
					SettingsComposer.LoadSettings(DataCompositionSettings);
					SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
				Else
					
					If ValueIsFilled(PriceTypeLine.AddressOfDataCompositionSchemaSettings) Then
						SettingsFromPriceView = GetFromTempStorage(PriceTypeLine.AddressOfDataCompositionSchemaSettings);
						SettingsComposer.LoadSettings(SettingsFromPriceView);
						SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
					Else
						SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
					EndIf;
					
				EndIf;
				
				// we forbid the output of general totals
				SettingsComposer.Settings.OutputParameters.SetParameterValue("VerticalOverallPlacement", DataCompositionTotalPlacement.None);
				
				// Filling in the report structure and selected fields.
				SettingsComposer.Settings.Structure.Clear();
				
				DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
				DetailedRecordsGroup.Use = True;
				
				SettingsComposer.Settings.Selection.Items.Clear();
				AddSelectedDCSField(DetailedRecordsGroup, "Products", True);
				
				If Form.UseItemVariants Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingVariant", True);
				EndIf;
				
				If Form.UseItemsBatch Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingBatch", True);
				EndIf;
				
				If Form.UseItemPackages Then
					AddSelectedDCSField(DetailedRecordsGroup, "PricingPackage", True);
				EndIf;
				
				AddSelectedDCSField(DetailedRecordsGroup, "Package", True);
				AddSelectedDCSField(DetailedRecordsGroup, "ZoomRatio", True);
				
				AddSelectedDCSField(DetailedRecordsGroup, "Price");
				AddSelectedDCSField(DetailedRecordsGroup, "Currency", True);
				
				LayoutOptions = SettingsComposer.Settings.DataParameters.Items;
				If ThisIsSettingProductPrices(Form) Then
					Parameter = LayoutOptions.Find("Basis");
					If Parameter <> Undefined Then
						Parameter.Value = Form.Object.DocumentBasis;
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
					Parameter = LayoutOptions.Find("ThisIsGenerationFromBaseDocuments");
					If Parameter <> Undefined Then
						Parameter.Value = ValueIsFilled(Form.Object.DocumentBasis);
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
					Parameter = LayoutOptions.Find("ExcludedBusinessTransactions");
					If Parameter <> Undefined Then
						Parameter.Value = CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements();
						Parameter.Use = ValueIsFilled(Parameter.Value);
					EndIf;
				EndIf;
				Parameter = LayoutOptions.Find("DocumentDate");
				If Parameter <> Undefined Then
					Parameter.Value = DocumentDate(Form);
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("PriceKind");
				If Parameter <> Undefined Then
					Parameter.Value = PriceTypeLine.Ref;
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				Parameter = LayoutOptions.Find("Currency");
				If Parameter <> Undefined Then
					Parameter.Value = PriceTypeLine.Currency;
					Parameter.Use = ValueIsFilled(Parameter.Value);
				EndIf;
				
				// Layout layout and query execution.
				TemplateComposer = New DataCompositionTemplateComposer;
				SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
				CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
				
				ExternalDataSets = New Structure;
				ExternalDataSets.Insert("ProductsTable", ProductsTable.Copy(, "Products, PricingVariant, PricingBatch, TSOSeriesForCommunication, PricingPackage, TsoPackagingForCommunication"));
				
				CompositionProcessor = New DataCompositionProcessor;
				CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets,,True);
				OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

				ReportData = New ValueTable();
				OutputProcessor.SetObject(ReportData);
				ReportData = OutputProcessor.Output(CompositionProcessor);
				
			Else
				
				ErrorText = StrTemplate(ErrorTemplateForCalculatingPriceAccordingToInfobaseData(),
					PriceTypeLine.Ref);
				
				CommonClientServer.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
			
			If Not Cancel Then
				
				If Form.UseItemPackages Then
					TableOfCoefficientsOfProductPackages = CoefficientsOfPackagesOfProductsTreeTree(Form);
				Else
					TableOfCoefficientsOfProductPackages = Undefined;
				EndIf;
				
				ParametersStructure = New Structure();
				ParametersStructure.Insert("OnlyEmpty",  OnlyEmpty);
				ParametersStructure.Insert("ApplyRounding_",  True);
				ParametersStructure.Insert("LoadingPackaging",    False);
				ParametersStructure.Insert("AutoCalculate", True);

				If PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost Then
					
					ParametersStructure.Insert("Rate_", True);
					LoadPricesFromValueTable(
						Form,
						ReportData,
						TableOfCoefficientsOfProductPackages,
						DataCache,
						PriceTypeLine,
						ParametersStructure);
					
				Else
					
					ParametersStructure.Insert("Rate_", False);
					LoadPricesFromValueTable(Form,
						ReportData,
						TableOfCoefficientsOfProductPackages,
						DataCache,
						PriceTypeLine,
						ParametersStructure);
					
				EndIf;

			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Rounds up manual prices in the table.
//
// Parameters:
// 	Form - ClientApplicationForm
// 	ProductsTable - ValueTable - Table where rounding is applied
// 	TypesOfPrices - Array of CatalogRef.TypesOfPrices - types of prices for which rounding should be applied
//
Procedure ApplyRoundingToManualPrices(Form, ProductsTable, TypesOfPrices, DataCache)
	
	For Each RowOfProductTable In ProductsTable Do
		
		PriceTableRow = FindPriceTreeString(Form, RowOfProductTable, DataCache);
		
		For Each PriceTypeLine In TypesOfPrices Do
			
			ColumnName = PriceTypeLine.ColumnName;
			PriceTableRow[ColumnName] = SettingPricesClientServer.RoundUpPrice(PriceTableRow[ColumnName], PriceTypeLine);
			
			If PriceTableRow["OldPrice" + ColumnName] <> PriceTableRow[ColumnName] Then
				PriceTableRow["ChangedManually" + PriceTypeLine.ColumnName] = True;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Loads prices to the price table from the passed table
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  Table - ValueTable - The table from which you want to import prices
//  ComplianceOfFactorsOfPackagesOfProductRange - Map - contains the nomenclature, packages, and their coefficients
//  DataCache - See InitializeDataCacheStructure
//  LoadingPriceTypeLine - Undefined, FormDataCollectionItem -
//  AdditionalParameters - Structure - Contains:
//  * OnlyEmpty  - Boolean - Indicates that only unfilled prices should be calculated.
//  * ApplyRounding_  - Boolean - indicates that rounding should be applied to prices.
//  * LoadingPackaging    - Boolean - indicates that the package needs to be loaded.
//  * Rate_           - Boolean - indicates the need for extra charges.
//  * AutoCalculate - Boolean - indicates the need for automatic price recalculation.
//
Procedure LoadPricesFromValueTable(Form,
	                                     Table,
	                                     ComplianceOfFactorsOfPackagesOfProductRange,
	                                     DataCache,
	                                     LoadingPriceTypeLine = Undefined,
	                                     AdditionalParameters  = Undefined)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("OnlyEmpty",  False);
	ParametersStructure.Insert("ApplyRounding_",  False);
	ParametersStructure.Insert("LoadingPackaging",    False);
	ParametersStructure.Insert("Rate_",           False);
	ParametersStructure.Insert("AutoCalculate", False);

	If AdditionalParameters <> Undefined Then
		FillPropertyValues(ParametersStructure, AdditionalParameters);
	EndIf;
	
	ExchangeRates(Form, DataCache);
	
	If LoadingPriceTypeLine <> Undefined Then
		PriceTypeLine = LoadingPriceTypeLine;
	EndIf;
	
	CurCurrentPriceView = Undefined;
	
	For Each SourceRow In Table Do
	
		ThereAreSubordinateLines = Undefined;
		PriceTableRow = FindPriceTreeString(Form, SourceRow, DataCache);
		
		If LoadingPriceTypeLine = Undefined And CurCurrentPriceView <> SourceRow.PriceKind Then
			CurCurrentPriceView = SourceRow.PriceKind;
			PriceTypeLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, SourceRow.PriceKind);
		EndIf;
		
		ThresholdPriceGroups = PriceTypeLine.Thresholds.FindRows(New Structure("PriceGroup", PriceTableRow.PriceGroup));
		If ThresholdPriceGroups.Count() > 0 Then
			ThresholdOnPriceIncreaseFor = ThresholdPriceGroups[0].ThresholdOnPriceIncreaseFor;
			ThresholdOnPriceDecreaseBy = ThresholdPriceGroups[0].ThresholdOnPriceDecreaseBy;
		Else
			ThresholdOnPriceIncreaseFor = PriceTypeLine.ThresholdOnPriceIncreaseFor;
			ThresholdOnPriceDecreaseBy = PriceTypeLine.ThresholdOnPriceDecreaseBy;
		EndIf;
		
		ColumnName = PriceTypeLine.ColumnName;
		
		If ValueIsFilled(PriceTableRow["Currency" + ColumnName]) Then
			PriceCurrency = PriceTableRow["Currency" + ColumnName];
		Else
			CurrencyPriceGroups = PriceTypeLine.Currencies.FindRows(New Structure("PriceGroup", PriceTableRow.PriceGroup));
			If CurrencyPriceGroups.Count() > 0 Then
				PriceCurrency = CurrencyPriceGroups[0].Currency;
			Else
				PriceCurrency = PriceTypeLine.Currency;
			EndIf;
			
			If ThereAreSubordinateLines = Undefined Then
				If ThisIsVendorPriceRegistration(Form, DataCache) Then
					ThereAreSubordinateLines = False;
				Else
					If (TypeOf(Form.PriceTree) = Type("FormDataTree")) Then
						SubordinateRows = PriceTableRow.GetItems();
					Else
						SubordinateRows = PriceTableRow.Rows;
					EndIf;
					
					ThereAreSubordinateLines = SubordinateRows.Count() > 0;
				EndIf;
			EndIf;
			If Not ThereAreSubordinateLines Then
				PriceTableRow["Currency" + ColumnName] = PriceCurrency;
			EndIf;
		EndIf;
		
		If ParametersStructure.Rate_ Then
			PriceGroupsOfMargins = PriceTypeLine.PriceGroups.FindRows(New Structure("PriceGroup", PriceTableRow.PriceGroup));
			If PriceGroupsOfMargins.Count() > 0 Then
				Markup = PriceGroupsOfMargins[0].Markup;
			Else
				Markup = PriceTypeLine.Markup;
			EndIf;
		EndIf;
		
		If (PriceTableRow[ColumnName] = 0 Or Not ParametersStructure.OnlyEmpty) 
			And SourceRow.Price <> Null And Not PriceTableRow["NoEditingAllowed" + ColumnName] Then
			
			Price = SourceRow.Price;
			If ParametersStructure.Rate_ Then
				Price = Price * (Markup / 100 + 1);
			EndIf;
			
			If Form.UseItemPackages Then
				
				If ComplianceOfFactorsOfPackagesOfProductRange <> Undefined Then
					
					CurrentPackaging = PriceTableRow["Package" + ColumnName];
					CurRatio = 1;
					
					If ValueIsFilled(SourceRow.ZoomRatio)
						And (ValueIsFilled(SourceRow.Package) Or ValueIsFilled(CurrentPackaging)) Then
						
						If ValueIsFilled(CurrentPackaging) Then
														
							SearchResult = SettingPricesClientServer.GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																												SourceRow.Products, 
																												CurrentPackaging);
							
							If ValueIsFilled(SearchResult) Then
								CurRatio = SearchResult;
							EndIf;
							
						EndIf;
						
						Price = Price / SourceRow.ZoomRatio * CurRatio;
						
					EndIf;
					
				ElsIf ParametersStructure.LoadingPackaging Then
					PriceTableRow["Package" + ColumnName] = SourceRow.Package;
				EndIf;
				
			EndIf;
			
			If PriceCurrency <> Undefined And SourceRow.Currency <> Null And PriceCurrency <> SourceRow.Currency Then
				Price = RecalculateCurrency(SourceRow.Currency, PriceCurrency, Price, DataCache.ExchangeRates);
			EndIf;
			
			If ParametersStructure.ApplyRounding_ Then
				Price = SettingPricesClientServer.RoundUpPrice(Price, PriceTypeLine);
			EndIf;
			
			If PriceTableRow["OldPrice" + ColumnName] <> 0 Then
				ChangePercentage = Round(100 * (Price - PriceTableRow["OldPrice" + ColumnName]) / PriceTableRow["OldPrice" + ColumnName], 10, 2);
			Else
				ChangePercentage = 0;
			EndIf;
			
			If (ThresholdOnPriceIncreaseFor = 0 And ThresholdOnPriceDecreaseBy = 0)
				Or PriceTableRow["OldPrice" + ColumnName] = 0
				Or ?(ChangePercentage > 0, ChangePercentage >= ThresholdOnPriceIncreaseFor, -ChangePercentage >= ThresholdOnPriceDecreaseBy) Then
				
				PriceTableRow[ColumnName] = Price;
				If PriceTableRow["OldPrice" + ColumnName] <> 0 Then
					PriceTableRow["ChangePercentage" + ColumnName] = ChangePercentage;
				Else
					PriceTableRow["ChangePercentage" + ColumnName] = 0;
				EndIf;
				
			Else
				PriceTableRow[ColumnName] = PriceTableRow["OldPrice" + ColumnName];
				PriceTableRow["ChangePercentage" + ColumnName] = 0;
			EndIf;
			
			PriceTableRow["AmountOfChange" + ColumnName] = PriceTableRow[ColumnName] - PriceTableRow["OldPrice" + ColumnName];
			
			PriceTableRow["ChangedManually" + ColumnName] = False;
			PriceTableRow["ChangedAutomatically" + ColumnName] = ParametersStructure.AutoCalculate;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds tree element packages to the array of packages
//
// Parameters:
//  TreeItem       - FormDataTreeItemCollection - value tree element
//  ArrayOfPriceTypes      - Array - array of price types for searching columns in the value tree
//  Array of packages-Array-an array to add packages to.
//
Procedure AddPackagingProductsRowsOfPriceTableToTable(Val TreeItem,
	                                              Val ArrayOfPriceTypes,
	                                              TableOfProductPackages)
	
	For Each PricesKind In ArrayOfPriceTypes Do
		ColumnName = "Package" + PricesKind.ColumnName;
		Package = TreeItem[ColumnName];//CatalogRef.PackagesAndUnitsOfMeasure
		
		SearchParameters = New Structure("Products, Package", TreeItem.Products, Package);
		
		If ValueIsFilled(Package) And TableOfProductPackages.FindRows(SearchParameters).Count() = 0 Then
			NewRow = TableOfProductPackages.Add();
			NewRow.Products = TreeItem.Products;
			NewRow.Package = Package;
		EndIf;
		
	EndDo;
	
EndProcedure

// Puts the latest exchange rates in temporary storage
// 
// Parameters:
// 	Form - See BuildPriceTree.Form
// 	DataCache - See InitializeDataCacheStructure
// 
Procedure CorrespondenceOfExchangeRates(Form, DataCache)
	
	DataCache.ExchangeRates = New Map;
	
	Query = New Query(
	"SELECT ALLOWED
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS RelativeExchangeRatesSliceLast");
	
	Query.SetParameter("Date", DocumentDate(Form));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		CurrencyStructure = New Structure;
		CurrencyStructure.Insert("Currency", Selection.Currency);
		CurrencyStructure.Insert("CourseNumerator", Selection.CourseNumerator);
		CurrencyStructure.Insert("CourseDenominator", Selection.CourseDenominator);
		
		DataCache.ExchangeRates.Insert(Selection.Currency, CurrencyStructure);
		
	EndDo;
	
EndProcedure

// Returns price types that depend on the specified price type
//
// Parameters:
//  TableOfPriceTypes - See DownloadPriceCatalog
//  PriceKind - CatalogRef.TypesOfPrices - The type of price that you need to find dependent and influencing prices for
//  Stack - Array of ValueTableRow - A service array for a recursive call. Contains including:
//  * Ref - CatalogRef.TypesOfPrices, CatalogRef.VendorPriceTypes - Type of price
//
// Returns:
//  Array - Dependent types of prices
//
Function FindDependentAndInfluencingPrices(TableOfPriceTypes, PriceKind, Stack = Undefined)
	
	CatalogLine = TableOfPriceTypes.Find(PriceKind, "Ref");
	Level           = 0;
	
	For Each BasePrice In CatalogLine.InfluencingPriceTypes Do
		
		BasePriceLine  = TableOfPriceTypes.Find(BasePrice.InfluencingPriceType, "Ref");
		If BasePriceLine = Undefined Then
			Return Level;
		EndIf;
		BasePriceLevel = BasePriceLine.Level;
		
		If Stack = Undefined Then
			Stack = New Array();
		EndIf;
		
		Stack.Add(CatalogLine);
		BasePriceLevel = FindDependentAndInfluencingPrices(TableOfPriceTypes, BasePrice.InfluencingPriceType, Stack);
		
		If BasePriceLevel > Level Then
			Level = BasePriceLevel;
		EndIf;
		
		For Each StackItem In Stack Do
			
			If StackItem.InfluencingPrices.FindByValue(BasePriceLine.Ref) = Undefined Then
				StackItem.InfluencingPrices.Add(BasePriceLine.Ref);
			EndIf;
			
			If BasePriceLine.DependentPrices.FindByValue(StackItem.Ref) = Undefined Then
				BasePriceLine.DependentPrices.Add(StackItem.Ref);
			EndIf;
			
		EndDo;
		
		Stack.Delete(Stack.Count() - 1);
		
	EndDo;
	
	Level                   = Level + 1;
	CatalogLine.Level = Level;
	
	Return Level;
	
EndFunction

Function GetSettingsLinesForDependentPriceTypes(Form, ArrayOfPriceTypes)

	DependentPrices = New Array;

	For Each PriceKind In ArrayOfPriceTypes Do
		ArrayOfDependentPriceStrings = DependentOnTypeOfPriceTypesOfPrices(Form, PriceKind);
		For Each PriceTypeLine In ArrayOfDependentPriceStrings Do
			If DependentPrices.Find(PriceTypeLine) = Undefined
				And ArrayOfPriceTypes.Find(PriceTypeLine) = Undefined Then
				DependentPrices.Add(PriceTypeLine);
			EndIf;
		EndDo;
	EndDo;
	
	Return DependentPrices;
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 	SelectionOfProducts - QueryResultSelection - 
// 	DataCache - See InitializeDataCacheStructure
// 
Procedure UploadProductsToPriceTree(Form, SelectionOfProducts, DataCache)
	
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Form, DataCache);
	
	While SelectionOfProducts.Next() Do
		
		ProductItem = FindPriceTreeString(Form, SelectionOfProducts, DataCache);
		
		If Not ValueIsFilled(SelectionOfProducts.PriceKind) Then
			Continue;
		EndIf;
		
		If ProductItem = Undefined Then
			Continue;
		EndIf;
		
		ColumnName = ColumnNameByPriceType(SelectionOfProducts.PriceKind, DataCache);
		
		ProductItem[ColumnName] = SelectionOfProducts.Price;
		ProductItem["OldPrice" + ColumnName] = SelectionOfProducts.EffectivePrice;
		If ValueIsFilled(SelectionOfProducts.EffectivePrice) Then
			ProductItem["AmountOfChange" + ColumnName] = SelectionOfProducts.Price - SelectionOfProducts.EffectivePrice;
		EndIf;
		ProductItem["ChangePercentage" + ColumnName] = SelectionOfProducts.Percent;
		ProductItem["ChangedManually"  + ColumnName] = SelectionOfProducts.PriceIsChangedManually;
		
		If Form.UseItemPackages Then
			ProductItem["Package" + ColumnName] = SelectionOfProducts.Package;
		EndIf;
		
		If ThisIsVendorPriceRegistration Then
			
			SettingConditions = False;
			
			If Form.UseItemPackages Then
				
				If TypeOf(ProductItem) = Type("Structure")
						And ProductItem.Property("OrderPackage" + ColumnName)
						Or TypeOf(ProductItem) = Type("FormDataTreeItem") Then
							
							ProductItem["OrderPackage" + ColumnName] = SelectionOfProducts.OrderPackage;
							SettingConditions = ValueIsFilled(SelectionOfProducts.OrderPackage);
							
				EndIf;
				
			EndIf;
			
			If TypeOf(ProductItem) = Type("Structure")
					And ProductItem.Property("MinimumDeliveryLot" + ColumnName)
					Or TypeOf(ProductItem) = Type("FormDataTreeItem") Then

						ProductItem["MinimumDeliveryLot"  + ColumnName] = SelectionOfProducts.MinimumDeliveryLot;
						SettingConditions = SettingConditions Or ValueIsFilled(SelectionOfProducts.MinimumDeliveryLot);
						
			EndIf;
			
			If TypeOf(ProductItem) = Type("Structure")
					And ProductItem.Property("SettingConditions" + ColumnName)
					Or TypeOf(ProductItem) = Type("FormDataTreeItem") Then
						
				ProductItem["SettingConditions"  + ColumnName] = SettingConditions;
				
			EndIf;
			
		Else
			
			Formula = ?(SelectionOfProducts.Formula = "", SelectionOfProducts.DefaultFormulaIs, SelectionOfProducts.Formula);
			
			ProductItem["NoEditingAllowed"   + ColumnName] = SelectionOfProducts.NoEditingAllowed;
			ProductItem["Formula"                + ColumnName] = Formula;
			ProductItem["FormulaChangedManually" + ColumnName] = (Formula <> SelectionOfProducts.DefaultFormulaIs);
			ProductItem["Currency"                 + ColumnName] = SelectionOfProducts.Currency;
			
			If Form.UsePriceManagementSystem25 Then
				ProductItem["VATRate" + ColumnName] = SelectionOfProducts.VATRate;
				ProductItem["InitialVATRate" + ColumnName] = SelectionOfProducts.VATRate;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ControllingNumberOfRows(Parameters)
	
	If Parameters.RowsCount + Parameters.NumberOfPriceTypes > 99999 Then

		Parameters.RowsCount = Parameters.NumberOfPriceTypes;

		Parameters.TabularSections.Delete(Parameters.TabularSections.Find(Parameters.TabularSections[0]));
		If Parameters.TabularSections.Count() = 0 Then
			If Parameters.Property("DetailsOfNewDocuments") Then
				Document = Documents.PriceSetup.CreateDocument();
				FillPropertyValues(Document, Parameters.DetailsOfNewDocuments);
				PutPriceTypesInTablePart(Parameters.Form, Document.TypesOfPrices, True);
				Parameters.Documents.Add(Document);
				If Parameters.Form.UsePriceManagementSystem25 Then
					Parameters.TabularSections.Add(Document.Goods2_5);
				Else
					Parameters.TabularSections.Add(Document.Goods);
				EndIf;
			Else
				Raise NStr("vi = 'Trong chứng từ đã nhập quá nhiều hàng hóa.
										|Hãy thử phân chia chứng từ này thành nhiều chứng từ riêng biệt.';
										|ru = 'В документ введено слишком много товаров.
										|Попробуйте разбить данный документ на несколько отдельных документов.';
										|en = 'You have entered too many goods into the document.
										|Try to split the document into several separate documents.'; fa = 'You have entered too many goods into the document.
										|Try to split the document into several separate documents.';
										|it = 'Nel documento sono inseriti troppi articoli.
										| Dividere il documento in diversi documenti singoli.';
										|pl = 'W dokumencie wprowadzono zbyt wiele towarów.
										|Spróbuj rozdzielić ten dokument na kilka osobnych dokumentów.';
										|tr = 'Belgeye çok fazla ürün girildi.
										|Bu belgeyi birkaç ayrı belgeye bölmeyi dene.'");
			EndIf;
		EndIf;
		
	Else

		Parameters.RowsCount = Parameters.RowsCount + Parameters.NumberOfPriceTypes;

	EndIf;
	
EndProcedure

Procedure ClearPrices(Form, ProductsTable, ArrayOfPriceTypeStrings, DataCache)
	
	For Each ProductsRow In ProductsTable Do
		
		PriceTreeString = FindPriceTreeString(Form, ProductsRow, DataCache);
		For Each PriceTypeLine In ArrayOfPriceTypeStrings Do
			PriceTreeString[PriceTypeLine.ColumnName] = 0;
		EndDo;
		
	EndDo;
	
EndProcedure

Function RecalculateCurrency(CurrencySource, CurrencyDestination, Price, MatchingCurrencies)
	
	If CurrencySource <> CurrencyDestination Then
		
		SourceCurrencyString  = SettingPricesClientServer.FindCurrencyString(MatchingCurrencies, CurrencySource);
		DestinationCurrencyString = SettingPricesClientServer.FindCurrencyString(MatchingCurrencies, CurrencyDestination);
		
		If SourceCurrencyString <> Undefined And DestinationCurrencyString <> Undefined Then
			Return Round((Price * SourceCurrencyString.CourseNumerator * DestinationCurrencyString.CourseDenominator) / (DestinationCurrencyString.CourseNumerator * SourceCurrencyString.CourseDenominator), 2);
		EndIf;
		
	EndIf;
	
	Return Price;
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 	Name - String - Name of the new field
// 	AdditionalParameters - Structure - Content:
// 	* ChoiceParameterLinks - FixedArray - Relationships of selection parameters
// 	* TitleBackColor - Color - The background color of the header
// 	* BackColor - Border, Color, Font, Undefined - Background color
// 	* MarginWidth - Number - Field width
// 	* HandlerStartChoice - String - The name of the handler
// 	* HandlerOnChange - String - The name of the handler
// 	* Title - String - Title
// Returns:
// 	  FormField - The created form field
Function AddFormField(Form, Name, AdditionalParameters)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Title",              Undefined);
	ParametersStructure.Insert("HandlerOnChange", "");
	ParametersStructure.Insert("HandlerStartChoice", "");
	ParametersStructure.Insert("MarginWidth",             0);
	ParametersStructure.Insert("BackColor",               Undefined);
	ParametersStructure.Insert("TitleBackColor",      Undefined);
	ParametersStructure.Insert("Parent",               Undefined);
	ParametersStructure.Insert("HeaderPicture",          Undefined);
	ParametersStructure.Insert("DataPath",            Undefined);
	ParametersStructure.Insert("FieldViewOnly",     False);
	ParametersStructure.Insert("ChoiceParameterLinks",  Undefined);
	ParametersStructure.Insert("ShowInHeader",       True);
	ParametersStructure.Insert("Kind",                    FormFieldType.InputField);
	ParametersStructure.Insert("ValuesPicture",       Undefined);
	ParametersStructure.Insert("ToolTip",              "");
	ParametersStructure.Insert("Visible",              True);
	ParametersStructure.Insert("HorizontalAlign", ItemHorizontalLocation.Auto);
	ParametersStructure.Insert("TextEdit", Undefined);
	
	FillPropertyValues(ParametersStructure, AdditionalParameters);
	
	NewField                     = Form.Items.Add("PriceTree" + Name, Type("FormField"), ?(ParametersStructure.Parent = Undefined, Form.Items["PriceTree"], ParametersStructure.Parent));
	NewField.DataPath         = ?(ValueIsFilled(ParametersStructure.DataPath), ParametersStructure.DataPath, "PriceTree." + Name);
	NewField.Title           = ?(ValueIsFilled(ParametersStructure.Title), ParametersStructure.Title, Name);
	NewField.EditMode = ColumnEditMode.EnterOnInput;
	NewField.Type                 = ParametersStructure.Kind;
	NewField.ReadOnly      = ParametersStructure.FieldViewOnly;
	NewField.Width              = ParametersStructure.MarginWidth;
	NewField.ShowInHeader    = ParametersStructure.ShowInHeader;
	NewField.ToolTip           = ParametersStructure.ToolTip;
	NewField.Visible           = ParametersStructure.Visible;
	NewField.HorizontalAlign = ParametersStructure.HorizontalAlign;
	If ParametersStructure.ValuesPicture <> Undefined Then
		NewField.ValuesPicture    = ParametersStructure.ValuesPicture;
	EndIf;
	
	NewField.HorizontalStretch = False;
	
	If ParametersStructure.ChoiceParameterLinks <> Undefined Then
		NewField.ChoiceParameterLinks = ParametersStructure.ChoiceParameterLinks;
	EndIf;
	
	If ParametersStructure.TitleBackColor <> Undefined Then
		NewField.TitleBackColor = ParametersStructure.TitleBackColor;
	EndIf;
	
	If ParametersStructure.BackColor <> Undefined Then
		NewField.BackColor = ParametersStructure.BackColor;
	EndIf;
		
	If ParametersStructure.HeaderPicture <> Undefined Then
		NewField.HeaderPicture = ParametersStructure.HeaderPicture;
	EndIf;
		
	If ValueIsFilled(ParametersStructure.HandlerOnChange) Then
		NewField.SetAction("OnChange", ParametersStructure.HandlerOnChange);
	EndIf;
	
	If ValueIsFilled(ParametersStructure.HandlerStartChoice) Then
		NewField.SetAction("StartChoice", ParametersStructure.HandlerStartChoice);
		NewField.ClearButton = True;
		NewField.ChoiceButton 	= True;
	EndIf;
	
	If ParametersStructure.TextEdit <> Undefined Then
		NewField.TextEdit = ParametersStructure.TextEdit;
	EndIf;

	Return NewField;
	
EndFunction

Function AddFormGroup(Form,
	                        Name,
	                        Title,
	                        ShowInHeader,
	                        HeaderPicture,
	                        Var_ColumnsGroup,
	                        Parent)
	
	NewFolder                  = Form.Items.Add("PriceTree" + Name, Type("FormGroup"), ?(Parent = Undefined, Form.Items["PriceTree"], Parent));
	NewFolder.Title        = ?(ValueIsFilled(Title), Title, Name);
	NewFolder.Type              = FormGroupType.ColumnGroup;
	NewFolder.Group      = Var_ColumnsGroup;
	NewFolder.ShowInHeader = ShowInHeader;
	
	If ShowInHeader And HeaderPicture <> Undefined Then
		NewFolder.HeaderPicture = HeaderPicture;
	EndIf;
	
	Return NewFolder;
	
EndFunction

Procedure AddSelectedDCSField(DataCompositionGroup, Field, AddToGrouping = False) Export
	
	SelectedField               = DataCompositionGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField(Field);
	SelectedField.Use = True;
	
	If AddToGrouping Then
		GroupingField               = DataCompositionGroup.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Field          = New DataCompositionField(Field);
		GroupingField.Use = True;
	EndIf;
	
EndProcedure

// Parameters:
// 	DCS - DataCompositionSchema - Changeable data layout scheme
// 	DataSetProducts - DataCompositionSchemaDataSetObject - Dataset
// 	WorkingDataset - DataCompositionSchemaDataSetObject - Dataset
// 	Field - String - Field for a source expression and a sink expression
// 
Procedure AddRelationshipOfDCSDataSets(DCS, DataSetProducts, WorkingDataset, Field, WorkingSetField = Undefined)
	
	Link                     = DCS.DataSetLinks.Add();
	Link.SourceDataSet = DataSetProducts.Name;
	Link.DestinationDataSet = WorkingDataset.Name;
	Link.SourceExpression   = Field;
	Link.DestinationExpression   = ?(WorkingSetField = Undefined, Field, WorkingSetField);
	Link.Required        = True;
	
EndProcedure

// Parameters:
// 	DataSet - DataCompositionSchemaDataSetObject - Dataset
// 	FieldName - String - field name
// 	ValueType - String - Value type
// 
Procedure AddDCSDataSetField(DataSet, FieldName, ValueType)
	
	DataSetField             = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field        = FieldName;
	DataSetField.DataPath = FieldName;
	DataSetField.ValueType = New TypeDescription(ValueType);
	
EndProcedure

Procedure ComplianceTable(Form, DataCache, Regenerate = False)
	
	If Not Regenerate And ValueIsFilled(Form.AddressOfDataCacheStorage) Then
		DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree = GetFromTempStorage(Form.AddressOfDataCacheStorage);
		If Not DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree = Undefined Then
			Return;
		EndIf;
	EndIf;
	
	DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree = CreateProductTable(Form);
	DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Columns.Add("PriceTreeString");
	DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Columns.Add("RowID");
	
	GroupingOption = Form.GroupingOption;
	
	If GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
		DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Columns.Add(
			"ProductKind",New TypeDescription("CatalogRef.ItemKinds"));
	EndIf; 
	
	If TypeOf(Form.PriceTree) = Type("FormDataCollection") Then
		ProductItems_ = Form.PriceTree;
		
		For Each ProductItem In ProductItems_ Do
			
			NewLineOfVT = NewRowOfMatchingTable(DataCache, ProductItem);
			
		EndDo;
		
	Else
		
		PriceTreeIsDataTreeOfForm = (TypeOf(Form.PriceTree) = Type("FormDataTree"));
		
		CallParameters = New Structure();
		CallParameters.Insert("Operation", "AddRowToMatchTable");
		CallParameters.Insert("PriceTreeIsDataTreeOfForm", PriceTreeIsDataTreeOfForm);
		CallParameters.Insert("AddAllLines", True);
		
		ApplyChangesToTree(CallParameters, Form.PriceTree, DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree,,DataCache);
	
		SaveItemComplianceTable(Form, DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree);
		
	EndIf;
	
	If Form.UsePriceManagementSystem25 Then
		DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Indexes.Add("Products, PricingVariant, PricingBatch, PricingPackage");	
	Else	
		DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Indexes.Add("Products, Characteristic");	
	EndIf;
	
EndProcedure

Function NewRowOfMatchingTable(DataCache, SourceRow, FillInId = False)
	
	MapRow = DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree.Add();
	
	FillPropertyValues(MapRow, SourceRow);
	
	MapRow.PriceTreeString = SourceRow;
	If FillInId Then
		MapRow.RowID = SourceRow.GetID();
	EndIf;
	
	Return MapRow;
	
EndFunction

Procedure SaveItemComplianceTable(Form, TableOfCorrespondenceOfProductsToRowsInProductTree)
	Form.AddressOfDataCacheStorage = PutToTempStorage(TableOfCorrespondenceOfProductsToRowsInProductTree, Form.UUID);
EndProcedure

Function ThereArePriceChangesInLine(PriceTreeString, SelectedPrices, ByChangesPerDay = False)
	
	TheCostOfTheChanged = False;
	
	For Each PriceKind In SelectedPrices Do
		If ByChangesPerDay Then
			If (PriceTreeString["ChangePercentage" + PriceKind.ColumnName] <> 0
				And PriceTreeString["OldPrice" + PriceKind.ColumnName] <> 0)
				Or (PriceTreeString["OldPrice" + PriceKind.ColumnName] = 0
				And PriceTreeString[PriceKind.ColumnName] <> 0) Then
				TheCostOfTheChanged = True;
				Break;
			EndIf;
		Else
			If (PriceTreeString["ChangedManually" + PriceKind.ColumnName]
				Or PriceTreeString["ChangedAutomatically" + PriceKind.ColumnName]) Then
				TheCostOfTheChanged = True;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return TheCostOfTheChanged;
	
EndFunction

Function ThereAreChangesInNDSRateInLine(PriceTreeString, SelectedPrices, ByChangesPerDay = False)
	
	VATRateHasBeenChanged = False;
	For Each PriceKind In SelectedPrices Do
		
		If	(PriceTreeString["ManuallyChangedVATRate" + PriceKind.ColumnName]
				Or PriceTreeString["VATRateChangedAutomatically" + PriceKind.ColumnName]) Then
			VATRateHasBeenChanged = True;
			Break;
		EndIf;

	EndDo;
	
	Return VATRateHasBeenChanged;
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function ThisIsVendorPriceRegistration(Form, DataCache = Undefined)
	
	ThisIsVendorPriceRegistration = False;
	
	If DataCache = Undefined Then
		ThisIsVendorPriceRegistration = (ThisIsPriceRegistrationOfSupplierProductRange(Form)
			Or SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode)
			Or ThisIsDownloadingVendorPricesFromExternalFiles(Form));
	Else
		If DataCache.ThisIsVendorPriceRegistration = Undefined Then
			
			DataCache.ThisIsVendorPriceRegistration = (ThisIsPriceRegistrationOfSupplierProductRange(Form)
				Or SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode)
				Or ThisIsDownloadingVendorPricesFromExternalFiles(Form)
			);
				
		EndIf;
		ThisIsVendorPriceRegistration = DataCache.ThisIsVendorPriceRegistration;
	EndIf;
	
	Return ThisIsVendorPriceRegistration;
		
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function ThisIsPriceRegistrationOfSupplierProductRange(Form)
	
	Return (Form.FormCode = "VendorPriceList");
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function ThisIsDownloadingVendorPricesFromExternalFiles(Form)
	
	Return (Form.FormCode = "ImportVendorPricesFromFile");
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function ThisIsSettingProductPrices(Form)
	
	Return (Form.FormCode = "PriceSetup");
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function ThisIsPriceList(Form)
	
	Return (Form.FormCode = "Processing_PriceList_Form");
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function UseValueTableInsteadOfValueTree(Form)
	
	Return Form.FormCode = "ImportVendorPricesFromFile"
		Or SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode);
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Function LatestPricePackages(Form, Products, Characteristic, TypesOfPrices)
	
	Query = New Query;
	
	If ThisIsVendorPriceRegistration(Form) Then
		Query.Text = "
		|SELECT
		|	ItemsPrices.VendorPriceKind AS PriceKind,
		|	ItemsPrices.Package          AS Package
		|FROM
		|	InformationRegister.ItemsPricesOfVendor.SliceLast(
		|		&Date, Products = &Products
		|			AND Characteristic = &Characteristic AND VendorPriceKind IN (&TypesOfPrices)) AS ItemsPrices
		|";
	Else
		Query.Text = "
		|SELECT
		|	ItemsPrices.PriceKind  AS PriceKind,
		|	ItemsPrices.Package AS Package
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(
		|		&Date, Products = &Products
		|			AND Characteristic = &Characteristic AND PriceKind IN (&TypesOfPrices)) AS ItemsPrices
		|";
	EndIf;
	
	Query.SetParameter("Products",   Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("TypesOfPrices",        TypesOfPrices);
	Query.SetParameter("Date",           CurrentSessionDate());
	
	Return Query.Execute().Unload();
	
EndFunction

// Parameters:
// 	Form - See BuildPriceTree.Form
// 	RowID - Number
// 	CalculatePrices - Boolean - True-calculate prices by line ID
// 
Procedure PriceTreeCharacteristicOnChange(Form, RowID, CalculatePrices = True) Export
	
	DataCache = InitializeDataCacheStructure();
	
	CurrentRow = Form.PriceTree.FindByID(RowID);
	
	If ValueIsFilled(CurrentRow.Products) Then
		
		If Form.UseItemPackages Then
			
			TypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(Form);
			PackingTable_ = LatestPricePackages(Form, CurrentRow.Products, CurrentRow.Characteristic, TypesOfPrices);
			
			For Each CurRow In PackingTable_ Do
				ColumnNamePackaging = "Package" + ColumnNameByPriceType(CurRow.PriceKind, DataCache);
				If ValueIsFilled(CurRow.Package) Then
					CurrentRow[ColumnNamePackaging] = CurRow.Package;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// Loading old prices and percentage changes
	ValueTable = CreateProductsTable(ThisIsVendorPriceRegistration(Form));
	For Each PriceTypeLine In Form.SelectedPrices Do
		
		If PriceTypeLine.Selected_5
			Or PriceTypeLine.Influences Then
			
			ColumnName = PriceTypeLine.ColumnName;
			ColumnNamePackaging = "Package" + ColumnName;
			
			NewRow = ValueTable.Add();
			FillPropertyValues(NewRow, CurrentRow);
			NewRow.PriceKind        = PriceTypeLine.Ref;
			NewRow.Price           = CurrentRow[ColumnName];
			If Form.UseItemPackages Then
				NewRow.Package   = CurrentRow[ColumnNamePackaging];
			EndIf;
			
			If ThisIsDownloadingVendorPricesFromExternalFiles(Form) Then
				Continue;
			EndIf;
			
			For Each SubordinateRow In CurrentRow.GetItems() Do
				
				NewRow = ValueTable.Add();
				FillPropertyValues(NewRow, CurrentRow);
				NewRow.PriceKind        = PriceTypeLine.Ref;
				NewRow.Price           = SubordinateRow[ColumnName];
				If Form.UseItemPackages Then
					NewRow.Package   = CurrentRow[ColumnNamePackaging];
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	LoadOldPricesOfProducts(Form, ValueTable, DataCache);
	
	If Not ThisIsVendorPriceRegistration(Form) And CalculatePrices Then
		CalculatePricesByRowId(Form, RowID, True,,DataCache);
	EndIf;
	
EndProcedure

// Gets all the characteristics of the item
//
// Parameters:
// 	Form - See BuildPriceTree.Form
// 	CurrentRow - ValueTableRow - contains including:
// 		* Products - CatalogRef.Products - the item for which you want to obtain characteristics.
// 	CopyPricesFromCurLine - Boolean - True-prices will be copied from the passed string
//
Procedure FillInProductCharacteristics(Form, CurrentRow, CopyPricesFromCurLine = False) Export
	
	DataCache = InitializeDataCacheStructure();
	ThisIsVendorPriceRegistration = ThisIsVendorPriceRegistration(Form);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CatalogProducts.Ref AS Products,
	|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	CatalogProducts.SKU AS SKU,
	|	CASE
	|		WHEN CatalogProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	ItemsCharacteristics.Ref AS Characteristic
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (CASE
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN ItemsCharacteristics.Owner = CatalogProducts.Ref
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN ItemsCharacteristics.Owner = CatalogProducts.ProductKind
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN ItemsCharacteristics.Owner = CatalogProducts.ItemVariantsOwner
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatalogProducts.Ref = &Products
	|
	|ORDER BY
	|	ItemsCharacteristics.Ref";
	
	If Form.UseItemPackages And Not ThisIsVendorPriceRegistration Then
		
		Query.Text = Query.Text + "
			|;
			|SELECT
			|	ItemsPrices.Characteristic  AS Characteristic,
			|	ItemsPrices.PriceKind         AS PriceKind,
			|	ItemsPrices.Package        AS Package
			|FROM
			|	InformationRegister.ItemsPrices.SliceLast(&DocumentDate, Products = &Products AND PriceKind IN (&TypesOfPrices)) AS ItemsPrices
			|";
			
		Query.SetParameter("TypesOfPrices",       SettingPricesClientServer.SelectedTypesOfPrices(Form));
		Query.SetParameter("DocumentDate", DateForRequestingProductPrices(Form));
		
	EndIf;
	
	If ThisIsVendorPriceRegistration Then
		
		Query.Text = Query.Text + "
			|;
			|SELECT
			|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
			|	ItemsPricesOfVendor.VendorPriceKind         AS PriceKind,
			|	ItemsPricesOfVendor.Package                  AS Package,
			|	ItemsPricesOfVendor.Price                      AS Price
			|FROM
			|	InformationRegister.ItemsPricesOfVendor.SliceLast(&DocumentDate, Products = &Products AND VendorPriceKind IN (&TypesOfPrices)) AS ItemsPricesOfVendor
			|";
			
		Query.SetParameter("TypesOfPrices",       SettingPricesClientServer.SelectedTypesOfPrices(Form));
		Query.SetParameter("DocumentDate", DateForRequestingProductPrices(Form));
		
		Query.Text = Query.Text + "
			|;
			|SELECT
			|	PurchaseConditions.Characteristic            AS Characteristic,
			|	PurchaseConditions.VendorPriceKind         AS PriceKind,
			|	PurchaseConditions.OrderPackage            AS OrderPackage,
			|	PurchaseConditions.MinimumDeliveryLot AS MinimumDeliveryLot
			|FROM
			|	InformationRegister.PurchaseConditions.SliceLast(&DocumentDate, Products = &Products AND VendorPriceKind IN (&TypesOfPrices)) AS PurchaseConditions
			|";
			
		Query.SetParameter("TypesOfPrices",       SettingPricesClientServer.SelectedTypesOfPrices(Form));
		Query.SetParameter("DocumentDate", DateForRequestingProductPrices(Form));
		
	EndIf;
	
	Query.SetParameter("Products", CurrentRow.Products);
	
	ResultsArray = Query.ExecuteBatch();
	
	If Form.UseItemPackages And Not ThisIsVendorPriceRegistration Then
		Packages = ResultsArray[1].Unload(); // ValueTable
		Packages.Indexes.Add("Characteristic");
	EndIf;
	
	If ThisIsVendorPriceRegistration Then
		SupplierPricingAndPackaging = ResultsArray[1].Unload();
		SupplierPricingAndPackaging.Indexes.Add("Characteristic");
		
		PurchaseConditions = ResultsArray[2].Unload();
		PurchaseConditions.Indexes.Add("Characteristic");
	EndIf;
	
	TypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(Form);
	
	FeatureElements = CurrentRow.GetItems();
	FeatureElements.Clear();
	FeatureSelection_ = ResultsArray[0].Select();
	While FeatureSelection_.Next() Do
		
		ElementCharacteristic = FeatureElements.Add();
		
		FillPropertyValues(ElementCharacteristic, FeatureSelection_);
		SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(ElementCharacteristic);
		
		If Form.UseItemPackages And Not ThisIsVendorPriceRegistration Then
			
			SearchParameters = New Structure("Characteristic", ElementCharacteristic.Characteristic);
			
			FoundRows = Packages.FindRows(SearchParameters);
			For Each PackageSelection In FoundRows Do
				ElementCharacteristic["Package" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
			EndDo;
			
		EndIf;
		
		If ThisIsVendorPriceRegistration Then
			
				SearchParameters = New Structure("Characteristic", ElementCharacteristic.Characteristic);
				
				FoundRows = SupplierPricingAndPackaging.FindRows(SearchParameters);
				For Each SamplePackagingsAndPrices In FoundRows Do
					If Form.UseItemPackages Then
						ElementCharacteristic["Package" + ColumnNameByPriceType(SamplePackagingsAndPrices.PriceKind, DataCache)] = SamplePackagingsAndPrices.Package;
					EndIf;
					ElementCharacteristic["OldPrice" + ColumnNameByPriceType(SamplePackagingsAndPrices.PriceKind, DataCache)] = SamplePackagingsAndPrices.Price;
				EndDo;
				
				SearchParameters = New Structure("Characteristic", ElementCharacteristic.Characteristic);
				
				FoundRows = PurchaseConditions.FindRows(SearchParameters);
				For Each SampleTermsOfPurchase In FoundRows Do
					If Form.UseItemPackages Then
						ElementCharacteristic["OrderPackage" + ColumnNameByPriceType(SampleTermsOfPurchase.PriceKind, DataCache)] = SampleTermsOfPurchase.OrderPackage;
					EndIf;
					ElementCharacteristic["MinimumDeliveryLot" + ColumnNameByPriceType(SampleTermsOfPurchase.PriceKind, DataCache)] = SampleTermsOfPurchase.MinimumDeliveryLot;
				EndDo;
				
		EndIf;
		
	EndDo;
	
	If CopyPricesFromCurLine Then
		
		TableOfProductPackages = CreateTableOfProductPackages();
		TableOfCoefficientsOfProductPackages = Undefined;
		
		If Form.UseItemPackages Then
			
			For Each PriceKind In TypesOfPrices Do
				ColumnName = ColumnNameByPriceType(PriceKind, DataCache);
				
				SearchParameters = New Structure("Products, Package", CurrentRow.Products, CurrentRow["Package" + ColumnName]);
				
				If ValueIsFilled(CurrentRow["Package" + ColumnName]) And TableOfProductPackages.FindRows(SearchParameters).Count() = 0 Then
					NewRow = TableOfProductPackages.Add();
					NewRow.Package = CurrentRow["Package" + ColumnName];
					NewRow.Products = CurrentRow.Products;
				EndIf;
				
				FeatureElements = CurrentRow.GetItems();
				For Each ElementCharacteristic In FeatureElements Do
					
					Package = ElementCharacteristic["Package" + ColumnName];
					
					SearchParameters = New Structure("Products, Package", ElementCharacteristic.Products, Package);
					
					If ValueIsFilled(Package) And TableOfProductPackages.FindRows(SearchParameters).Count() = 0 Then
						NewRow = TableOfProductPackages.Add();
						NewRow.Package = Package;
						NewRow.Products = ElementCharacteristic.Products;
					EndIf;
					
				EndDo;
				
			EndDo;
			
			If TableOfProductPackages.Count() > 0 Then
				TableOfCoefficientsOfProductPackages = CoefficientsOfProductPackages(TableOfProductPackages);
			EndIf;
			
		EndIf;
		
		For Each PriceKind In TypesOfPrices Do
			ColumnName = ColumnNameByPriceType(PriceKind, DataCache);
			
			If CurrentRow["ChangedManually" + ColumnName] Then
				
				If Form.UseItemPackages Then
					
					// Let's determine the packing coefficient of the current price
					SourcePricePackingRatio = 1;
					If Form.UseItemPackages Then
						Package = CurrentRow["Package" + ColumnName];
						If ValueIsFilled(Package) And TableOfCoefficientsOfProductPackages <> Undefined Then
							SearchResult = SettingPricesClientServer.GetProductPackingRatio(TableOfCoefficientsOfProductPackages, 
																					CurrentRow.Products, 
																					Package);
							If ValueIsFilled(SearchResult) Then
								SourcePricePackingRatio = SearchResult;
							EndIf;
						EndIf;
					EndIf;
					
				EndIf;
				
				For Each ElementCharacteristic In FeatureElements Do
					
					ElementCharacteristic["ChangedManually" + ColumnName] = True;
					
					If Not Form.UseItemPackages
						Or CurrentRow["Package" + ColumnName] = ElementCharacteristic["Package" + ColumnName] Then
						ElementCharacteristic[ColumnName] = CurrentRow[ColumnName];
					Else
						
						// Let's determine the packing coefficient of the influencing price
						DestinationPricePackingRatio = 1;
						
						Package = ElementCharacteristic["Package" + ColumnName];
						If ValueIsFilled(Package) And TableOfCoefficientsOfProductPackages <> Undefined Then
							SearchResult = SettingPricesClientServer.GetProductPackingRatio(TableOfCoefficientsOfProductPackages, 
																					ElementCharacteristic.Products, 
																					Package);
							If ValueIsFilled(SearchResult) Then
								DestinationPricePackingRatio = SearchResult;
							EndIf;
						EndIf;
						
						If SourcePricePackingRatio = DestinationPricePackingRatio Then
							ElementCharacteristic[ColumnName] = CurrentRow[ColumnName];
						Else
							ElementCharacteristic[ColumnName] = CurrentRow[ColumnName] / SourcePricePackingRatio * DestinationPricePackingRatio;
						EndIf;
						
					EndIf;
				EndDo;
				
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Displays the selection line in the item Prices (price list) and supplier Prices forms.
// 
// Parameters:
// 	Form - See BuildPriceTree.Form
// 
Procedure ConfigureSelectionHeader(Form) Export
	
	If Form.SettingsComposerFilter.Settings.Filter.Items.Count() > 0
		And StrLen(TrimAll(String(Form.SettingsComposerFilter.Settings.Filter))) > 0 Then
		Form.HyperlinkFilterIsSet = NStr("vi = 'Đã đặt bộ lọc:';
										|ru = 'Установлен отбор:';
										|en = 'Set filter:'; fa = 'Set filter:';
										|it = 'Selezione impostata:';
										|pl = 'Ustawiona selekcja:';
										|tr = 'Filtre ayarlandı:'")
		                           + " " + String(Form.SettingsComposerFilter.Settings.Filter);
		Form.Items.HyperlinkFilterIsSet.Visible = True;
	Else
		Form.HyperlinkFilterIsSet = "";
		Form.Items.HyperlinkFilterIsSet.Visible = False;
	EndIf;
	
EndProcedure

// Function-Create a table of item packages
// 
// Returns:
//  ValueTable - table with columns:
//  * Products - CatalogRef.Products - Products
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//
Function CreateTableOfProductPackages() 
	
	Table = New ValueTable;
	Table.Columns.Add("Products", 	New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Package", 		New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	Return Table;
	
EndFunction

// Function - the table of units of item in array collections
//
// Parameters:
//  Array - Array - array of structures with the Item and Packaging keys.
// 
// Returns:
//  See CreateTableOfProductPackages
//
Function TableOfProductPackagesByCollectionArray(Array) Export 
	
	Table = CreateTableOfProductPackages();	
	
	For Each Structure In Array Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Structure);
	EndDo;
	
	Return Table;
	
EndFunction

// The function is a new table of formulas for calculation
// 
// Returns:
//  ValueTable - table with columns:
//  * PriceTableRow - ValueTreeRow - Product Line
//  * PriceKind - ValueTableRow - Price type string
//  * Formula - String - Formula text
//  * FormulaPresentation - String - Presentation of the formula
//  * ThresholdOnPriceIncreaseFor - Number - Operating threshold
//  * ThresholdOnPriceDecreaseBy - Number - The threshold of operation when decreasing
//
Function NewTableOfFormulasForCalculation()

	FormulasForCalculation = New ValueTable;
	FormulasForCalculation.Columns.Add("PriceTableRow");
	FormulasForCalculation.Columns.Add("PriceKind");
	FormulasForCalculation.Columns.Add("Formula", New TypeDescription("String"));
	FormulasForCalculation.Columns.Add("FormulaPresentation", New TypeDescription("String"));
	FormulasForCalculation.Columns.Add("DefaultFormulaPresentation", New TypeDescription("String"));
	FormulasForCalculation.Columns.Add("ThresholdOnPriceIncreaseFor", CurrencyRateOperations.MoneyFieldTypeDescription());
	FormulasForCalculation.Columns.Add("ThresholdOnPriceDecreaseBy", New TypeDescription("Number",
		New NumberQualifiers(5, 2, AllowedSign.Any)));

	Return FormulasForCalculation;

EndFunction

// Parameters:
// 	ArrayOfProductPackagingStructures - See TableOfProductPackagesByCollectionArray.Array
// 	
// Returns:
// 	See CoefficientsOfProductPackages
// 
Function ComplianceOfCoefficientsOfCollectionOfPackagesOfProductRange(ArrayOfProductPackagingStructures) Export 
	
	TableOfProductPackages = TableOfProductPackagesByCollectionArray(ArrayOfProductPackagingStructures); 
	Return CoefficientsOfProductPackages(TableOfProductPackages);
	
EndFunction

// Function-Get an array of previously set types of prices for the item
//
// Parameters:
//  Parameters	 - Structure - parameters to set in the request
// 
// Returns:
//  Array - with a list of the types of prices for which prices are set
//
Function GetArrayOfPreviouslySetPriceTypesByProductType(Parameters) Export 
	
	ArrayOfPriceTypes = New Array;	
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	|	ItemsPrices.PriceKind AS PriceKind
	|FROM
	|	InformationRegister.ItemsPrices.SliceLast(&Date, Products = &Products) AS ItemsPrices
	|WHERE
	|	ItemsPrices.Price > 0";
	
	If Parameters.UsePriceManagementSystem25 Then
		Query.Text = StrReplace(Query.Text, "InformationRegister.ItemsPrices", "InformationRegister.ItemsPrices25");
	EndIf;

	Query.SetParameter("Date", 		  Parameters.Date);
	Query.SetParameter("Products", Parameters.Products);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then		
	 	ArrayOfPriceTypes = Result.Unload().UnloadColumn("PriceKind");	
	EndIf; 
	                                                    	
	Return ArrayOfPriceTypes;
	
EndFunction

Function ThereIs_Column(PriceString, ColumnName)
	
	ThereIs_Column = False;
	
	If TypeOf(PriceString) = Type("ValueTreeRow") Then
		ThereIs_Column = (PriceString.Owner().Columns.Find(ColumnName) <> Undefined);
	Else
		ThereIs_Column = PriceString.Property(ColumnName);
	EndIf;
	
	Return ThereIs_Column;
EndFunction

// Returns a table with data for an item that is not allowed to be edited (by price type)  
//
// Parameters:
//  Additional_Settings - Structure - additional parameters (can be a form structure).
//  ProductsTable - ValueTable - data on the item.
//  PriceTypeLine - FormDataCollectionItem - Table row " types of prices"
//  DataCompositionSettings - DataCompositionSettings - data layout settings
//
Function GetTableOfProhibitedProducts(
										 Additional_Settings,
										 ProductsTable,
										 PriceTypeLine,
										 DataCompositionSettings = Undefined)
	
	ReportData = Undefined;

	SetPrivilegedMode(True);
	
	If ProductsTable.Count() > 0 Then
		
		If PriceTypeLine.DisablePriceEditingOutsideFilter Then
			
			// Copying the data layout scheme
			TemplateParameters1 = Catalogs.TypesOfPrices.InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName();
			TemplateParameters1.Ref 							= PriceTypeLine.Ref;
			TemplateParameters1.TemplateName 						= "Typical";
			TemplateParameters1.UsePriceManagementSystem25 	= False;
			
			SchemeAndSettings = Catalogs.TypesOfPrices.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1, True);
			DataCompositionSchema = SchemeAndSettings.DataCompositionSchema; 
			DataCompositionSettings = SchemeAndSettings.ProductSelectionDataLayoutSettings;

			If DataCompositionSettings = Undefined Then
				Return ReportData;
			EndIf;
			
			// Filling in the data set of the Nomenclature table
			WorkingDataset = DataCompositionSchema.DataSets[0];
			
			QueryText = WorkingDataset.Query;
				
			QueryText = StrReplace(
				QueryText, 
				"AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)",
				""
			);
				
			WorkingDataset.Query = QueryText;
			
			DataSetProducts                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
			DataSetProducts.Name            = "ProductsTable";
			DataSetProducts.ObjectName     = "ProductsTable";
			DataSetProducts.DataSource = WorkingDataset.DataSource;
			
			AddDCSDataSetField(DataSetProducts, "ItemRestr", "CatalogRef.Products");
			If Additional_Settings.UseItemVariants Then
				AddDCSDataSetField(DataSetProducts, "CharacteristicsRestr", "CatalogRef.ItemsCharacteristics");
			EndIf;
			
			DataCompositionSchema.DataSetLinks.Clear();
			AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "ItemRestr", "Products");
			
			If Additional_Settings.UseItemVariants Then
				AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "CharacteristicsRestr", "Characteristic");
			EndIf;
			
			// Preparing a data layout layout builder, loading settings
			SettingsComposer = New DataCompositionSettingsComposer;
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
			
			SettingsComposer.LoadSettings(DataCompositionSettings);
			// let's add the grouping "NOT", because we need to select those that are not included in the selection
			InvertSelection(DataCompositionSettings, SettingsComposer);
			SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
			
			// Filling in the report structure and selected fields.
			SettingsComposer.Settings.Structure.Clear();
			
			DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
			DetailedRecordsGroup.Use = True;
			
			SettingsComposer.Settings.Selection.Items.Clear();
			AddSelectedDCSField(DetailedRecordsGroup, "Products");
			
			If Additional_Settings.UseItemVariants Then
				AddSelectedDCSField(DetailedRecordsGroup, "Characteristic");
			EndIf;
			
			LayoutOptions = SettingsComposer.Settings.DataParameters.Items;

			Parameter = LayoutOptions.Find("PriceKind");
			If Parameter <> Undefined Then
				Parameter.Value = PriceTypeLine.Ref;
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			
			// Layout layout and query execution.
			TemplateComposer = New DataCompositionTemplateComposer;
			SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
			CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
			
			ExternalDataSets = New Structure;
			TableOfProductsCollapsed = ProductsTable.Copy(, "Products, Characteristic");
			TableOfProductsCollapsed.GroupBy("Products, Characteristic");
			TableOfProductsCollapsed.Columns.Products.Name = "ItemRestr";
			TableOfProductsCollapsed.Columns.Characteristic.Name = "CharacteristicsRestr";
			ExternalDataSets.Insert("ProductsTable", TableOfProductsCollapsed);
			
			CompositionProcessor = New DataCompositionProcessor;
			CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets,,True);
			OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

			ReportData = New ValueTable();
			OutputProcessor.SetObject(ReportData);
			ReportData = OutputProcessor.Output(CompositionProcessor);
			
		EndIf;
		
	EndIf;
	
	Return ReportData;
EndFunction

// Returns a table with data for an item that is not allowed to be edited (by price type)  
//
// Parameters:
//  Additional_Settings - Structure - additional parameters (can be a form structure).
//  ProductsTable - ValueTable - data on the item.
//  PriceTypeLine - FormDataCollectionItem - Table row " types of prices"
//  DataCompositionSettings - DataCompositionSettings - data layout settings
//
Function GetTableOfProhibitedProducts2_5(
										 Additional_Settings,
	                                     ProductsTable,
	                                     PriceTypeLine,
	                                     DataCompositionSettings = Undefined
										)
	
	ReportData = Undefined;

	SetPrivilegedMode(True);
	
	If ProductsTable.Count() > 0 Then
		
		If PriceTypeLine.DisablePriceEditingOutsideFilter Then
			
			// Copying the data layout scheme
			TemplateParameters1 = Catalogs.TypesOfPrices.InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName();
			TemplateParameters1.Ref 							= PriceTypeLine.Ref;
			TemplateParameters1.TemplateName 						= "Typical2_5";
			TemplateParameters1.UsePriceManagementSystem25 	= True;
			
			SchemeAndSettings = Catalogs.TypesOfPrices.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1, True);
			DataCompositionSchema = SchemeAndSettings.DataCompositionSchema; 
			DataCompositionSettings = SchemeAndSettings.ProductSelectionDataLayoutSettings;

			If DataCompositionSettings = Undefined Then
				Return ReportData;
			EndIf;
			
			// Filling in the data set of the Nomenclature table
			WorkingDataset = DataCompositionSchema.DataSets[0];
			
			QueryText = WorkingDataset.Query;
				
			QueryText = StrReplace(
				QueryText, 
				"AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)",
				""
			);
				
			WorkingDataset.Query = QueryText;
			
			DataSetProducts                = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
			DataSetProducts.Name            = "ProductsTable";
			DataSetProducts.ObjectName     = "ProductsTable";
			DataSetProducts.DataSource = WorkingDataset.DataSource;
			
			AddDCSDataSetField(DataSetProducts, "ItemRestr", "CatalogRef.Products");
			If Additional_Settings.UseItemVariants Then
				AddDCSDataSetField(DataSetProducts, "CharacteristicsTSORestr", "CatalogRef.ItemsCharacteristicsForPricing");
			EndIf;
			
			DataCompositionSchema.DataSetLinks.Clear();
			AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "ItemRestr", "Products");
			
			If Additional_Settings.UseItemVariants Then
				AddRelationshipOfDCSDataSets(DataCompositionSchema, DataSetProducts, WorkingDataset, "CharacteristicsTSORestr", "PricingVariant");
			EndIf;
			
			// Preparing a data layout layout builder, loading settings
			SettingsComposer = New DataCompositionSettingsComposer;
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
			
			SettingsComposer.LoadSettings(DataCompositionSettings);
			 // let's add the grouping "NOT", because we need to select those that are not included in the selection
			InvertSelection(DataCompositionSettings, SettingsComposer);
			SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
			
			// Filling in the report structure and selected fields.
			SettingsComposer.Settings.Structure.Clear();
			
			DetailedRecordsGroup = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
			DetailedRecordsGroup.Use = True;
			
			SettingsComposer.Settings.Selection.Items.Clear();
			AddSelectedDCSField(DetailedRecordsGroup, "Products");
			
			If Additional_Settings.UseItemVariants Then
				AddSelectedDCSField(DetailedRecordsGroup, "PricingVariant");
			EndIf;
			
			LayoutOptions = SettingsComposer.Settings.DataParameters.Items;
			Parameter = LayoutOptions.Find("PriceKind");
			If Parameter <> Undefined Then
				Parameter.Value = PriceTypeLine.Ref;
				Parameter.Use = ValueIsFilled(Parameter.Value);
			EndIf;
			
			// Layout layout and query execution.
			TemplateComposer = New DataCompositionTemplateComposer;
			SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
			CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
			
			ExternalDataSets = New Structure;
			TableOfProductsCollapsed = ProductsTable.Copy(, "Products, PricingVariant");
			TableOfProductsCollapsed.GroupBy("Products, PricingVariant");
			TableOfProductsCollapsed.Columns.Products.Name = "ItemRestr";
			TableOfProductsCollapsed.Columns.PricingVariant.Name = "CharacteristicsTSORestr";
			ExternalDataSets.Insert("ProductsTable", TableOfProductsCollapsed);
			
			CompositionProcessor = New DataCompositionProcessor;
			CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets,,True);
			OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

			ReportData = New ValueTable();
			OutputProcessor.SetObject(ReportData);
			ReportData = OutputProcessor.Output(CompositionProcessor);
			
		EndIf;
		
	EndIf;
	
	Return ReportData;
EndFunction

// Invert the selection.
// 
// Parameters:
//  DataCompositionSettings - DataCompositionSettings -  customize the layout data
//  SettingsComposer - DataCompositionSettingsComposer -  Settings Composer
Procedure InvertSelection(DataCompositionSettings, SettingsComposer)

	ComparisonKinds = Undefined;

	CompleteProcessingIsRequired = True;
	FilterItemsGroup = SettingsComposer.Settings.Filter;
	// if there is a selection by segments, then we invert only them, because in this case, product selections also work in segments
	ElementsOfSelectionBySegment = CommonClientServer.FindFilterItemsAndGroups(FilterItemsGroup, "ProductSegment");
	If ElementsOfSelectionBySegment.Count() Then
		For Each FilterElement In ElementsOfSelectionBySegment Do
			If FilterElement.Use Then
				FilterElement.ComparisonType = TypeOfComparisonToInvert(FilterElement.ComparisonType, ComparisonKinds);
				CompleteProcessingIsRequired = False;
			EndIf;
		EndDo;
	EndIf;

	If CompleteProcessingIsRequired Then
		If DataCompositionSettings.Filter.Items.Count() > 1 Then
			DataCompositionClientServer.DeleteSelection(SettingsComposer);
			FilterItemsGroup = DataCompositionClientServer.AddSelectionGroup(SettingsComposer.Settings.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
			DataCompositionClientServer.CopyElements(FilterItemsGroup, DataCompositionSettings.Filter);
		EndIf;
		InvertSelectionElements(FilterItemsGroup, ComparisonKinds);
	EndIf;
EndProcedure

Procedure InvertSelectionElements(FilterItemsGroup, ComparisonKinds)
	For Each FilterElement In FilterItemsGroup.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If FilterElement.GroupType = DataCompositionFilterItemsGroupType.AndGroup 
				Or FilterElement.GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
				FilterElement.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				InvertSelectionElements(FilterElement, ComparisonKinds);
			ElsIf FilterElement.GroupType = DataCompositionFilterItemsGroupType.OrGroup Then
				FilterElement.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				InvertSelectionElements(FilterElement, ComparisonKinds);
			EndIf;
		Else
			FilterElement.ComparisonType = TypeOfComparisonToInvert(FilterElement.ComparisonType, ComparisonKinds);
		EndIf;
	EndDo;
EndProcedure

Function TypeOfComparisonToInvert(Var_ComparisonType, ComparisonKinds = Undefined)
	
	If ComparisonKinds = Undefined Then
		ComparisonKinds = New Map();
		ComparisonKinds.Insert(DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.NotInHierarchy);
		ComparisonKinds.Insert(DataCompositionComparisonType.InList,DataCompositionComparisonType.NotInList);
		ComparisonKinds.Insert(DataCompositionComparisonType.InListByHierarchy,DataCompositionComparisonType.NotInListByHierarchy);
		ComparisonKinds.Insert(DataCompositionComparisonType.Filled,DataCompositionComparisonType.NotFilled);
		ComparisonKinds.Insert(DataCompositionComparisonType.BeginsWith,DataCompositionComparisonType.NotBeginsWith);
		ComparisonKinds.Insert(DataCompositionComparisonType.Like,DataCompositionComparisonType.NotLike);
		ComparisonKinds.Insert(DataCompositionComparisonType.Equal,DataCompositionComparisonType.NotEqual);
		ComparisonKinds.Insert(DataCompositionComparisonType.Contains,DataCompositionComparisonType.NotContains);
	
		ComparisonKinds.Insert(DataCompositionComparisonType.NotInHierarchy, DataCompositionComparisonType.InHierarchy);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotInList,DataCompositionComparisonType.InList);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotInListByHierarchy,DataCompositionComparisonType.InListByHierarchy);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotFilled,DataCompositionComparisonType.Filled);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotBeginsWith,DataCompositionComparisonType.BeginsWith);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotLike,DataCompositionComparisonType.Like);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotEqual,DataCompositionComparisonType.Equal);
		ComparisonKinds.Insert(DataCompositionComparisonType.NotContains,DataCompositionComparisonType.Contains);
	EndIf;
	
	TypeOfComparisonFound = ComparisonKinds.Get(Var_ComparisonType);

	If TypeOfComparisonFound = Undefined Then
		TypeOfComparisonFound = DataCompositionComparisonType.Equal;
	EndIf;
	
	Return TypeOfComparisonFound;
	
EndFunction

Function GetRequestTextForTransformation()
	QueryText = "SELECT
	|	Products.ProductKind AS ProductKind,
	|	Products.Ref AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef) AS PricingVariant
	|INTO RawData
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	NOT Products.IsFolder
	|	AND
	|		Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|
	|UNION ALL
	|
	|SELECT
	|	Products.ProductKind,
	|	Products.Ref,
	|	ItemsCharacteristics.Ref,
	|	CASE
	|		WHEN
	|			Products.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
	|	END
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.Products AS Products
	|		ON Products.Ref = ItemsCharacteristics.Owner
	|WHERE
	|	Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|
	|UNION ALL
	|
	|SELECT
	|	Products.ProductKind,
	|	Products.Ref,
	|	ItemsCharacteristics.Ref,
	|	CASE
	|		WHEN
	|			Products.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
	|	END
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.Products AS Products
	|		ON Products.ProductKind = ItemsCharacteristics.Owner
	|WHERE
	|	Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|
	|UNION ALL
	|
	|SELECT
	|	Products.ProductKind,
	|	Products.Ref,
	|	ItemsCharacteristics.Ref,
	|	CASE
	|		WHEN
	|			Products.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
	|	END
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.Products AS Products
	|		ON Products.ItemVariantsOwner = ItemsCharacteristics.Owner
	|WHERE
	|	Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SourceDataLastRequest.ProductKind AS ProductKind,
	|	SourceDataLastRequest.Products AS Products,
	|	SourceDataLastRequest.Characteristic AS Characteristic,
	|	SourceDataLastRequest.PricingVariant AS PricingVariant
	|FROM
	|	RawData AS SourceDataLastRequest
	|GROUP BY
	|	SourceDataLastRequest.ProductKind,
	|	SourceDataLastRequest.Products,
	|	SourceDataLastRequest.Characteristic,
	|	SourceDataLastRequest.PricingVariant";
	
	Return QueryText;
	
EndFunction

Procedure ApplyChangesToTree(Val Parameters, PriceTreeElementSource, Table, RowsProcessed = False, DataCache = Undefined)

	If Parameters.PriceTreeIsDataTreeOfForm Then
		PriceTreeElementsCur = PriceTreeElementSource.GetItems();
	Else
		PriceTreeElementsCur = PriceTreeElementSource.Rows;
	EndIf;
	
	LevelBelowProcessedLines = False;
	For Each PriceTreeElementCur In PriceTreeElementsCur Do
		
		ApplyChangesToTree(Parameters, PriceTreeElementCur, Table, LevelBelowProcessedLines, DataCache);
		
	EndDo;
	
	If TypeOf(PriceTreeElementSource) = Type("ValueTreeRow") 
		Or TypeOf(PriceTreeElementSource) = Type("FormDataTreeItem") Then
		ApplyChangesToProcessingOperationsTree(Parameters, PriceTreeElementSource, Table, LevelBelowProcessedLines, DataCache);
		
		RowsProcessed = LevelBelowProcessedLines;
	EndIf;
	
EndProcedure

Procedure ApplyChangesToProcessingOperationsTree(Val Parameters, PriceTreeElementSource, Table, RowsProcessed = False, DataCache = Undefined)
	If Parameters.AddAllLines Or Not RowsProcessed Then
		NewRow = Table.Add();
		FillPropertyValues(NewRow, PriceTreeElementSource);
		If Parameters.Operation = "AddRowToProductTable" Then
			If Parameters.UsePriceManagementSystem25 Then
				NewRow.TsoPackagingForCommunication = ?(PriceTreeElementSource.PricingPackage = PriceTreeElementSource.UnitOfMeasure, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), PriceTreeElementSource.PricingPackage);
				NewRow.TSOSeriesForCommunication    = ?(PriceTreeElementSource.PricingBatch.Predefined, Catalogs.ItemsBatchesForPricing.EmptyRef(), PriceTreeElementSource.PricingBatch);
			EndIf;
		ElsIf Parameters.Operation = "AddRowToMatchTable" Then
			NewRow.PriceTreeString = PriceTreeElementSource;
			If Parameters.PriceTreeIsDataTreeOfForm Then 
				NewRow.RowID = PriceTreeElementSource.GetID();
			EndIf;
		ElsIf Parameters.Operation = "ChangePrices" Then
			For Each PricesKind In Parameters.TypesOfPrices Do
				ColumnName = ColumnNameByPriceType(PricesKind.PriceKind, DataCache);
				
				If PricesKind.Property("PriceCurrency") And PriceTreeElementSource["Currency" + ColumnName] <> PricesKind.PriceCurrency Then
					Continue;
				EndIf;
				
				If PriceTreeElementSource["NoEditingAllowed" + ColumnName] Then
					Continue;
				EndIf;
				
				If PricesKind.Property("Price") Then
					NewPrice = PricesKind.Price;
				ElsIf PricesKind.Property("AmountOfChange") Then
					If Parameters.ChangeInRelationToOldPrice Then
						NewPrice = PriceTreeElementSource["OldPrice" + ColumnName] + PricesKind.AmountOfChange;
					Else
						NewPrice = PriceTreeElementSource[ColumnName] + PricesKind.AmountOfChange;
					EndIf;
				Else
					Continue;
				EndIf;
				
				PriceTreeElementSource[ColumnName] = NewPrice; 
				
				If PriceTreeElementSource["OldPrice" + ColumnName] <> 0 Then
					ChangePercentage = Round(100 * (NewPrice - PriceTreeElementSource["OldPrice" + ColumnName]) 
										/ PriceTreeElementSource["OldPrice" + ColumnName], 10, 2);
				Else
					ChangePercentage = 0;
				EndIf;
					
				PriceTreeElementSource["ChangePercentage" + ColumnName] = ChangePercentage;
				PriceTreeElementSource["AmountOfChange"   + ColumnName] = 
							PriceTreeElementSource[ColumnName] - PriceTreeElementSource["OldPrice"+ColumnName];
				
				PriceTreeElementSource["ChangedManually" + ColumnName] = 
					(PriceTreeElementSource[ColumnName] - PriceTreeElementSource["OldPrice" + ColumnName] <> 0);
				PriceTreeElementSource["ChangedAutomatically" + ColumnName] = False;
			EndDo;
		ElsIf Parameters.Operation = "ChangePricesByPercentage_2" Then
			For Each PricesKind In Parameters.TypesOfPrices Do
				ColumnName = ColumnNameByPriceType(PricesKind.PriceKind, DataCache);
				
				If PriceTreeElementSource["NoEditingAllowed" + ColumnName] Then
					Continue;
				EndIf;
					
				If PriceTreeElementSource["OldPrice" + ColumnName] <> 0 Then
					
					If Parameters.ChangeInRelationToOldPrice Then
						PriceTreeElementSource["ChangePercentage" + ColumnName] = PricesKind.ChangePercentage;
						PriceTreeElementSource[ColumnName] = Round(PriceTreeElementSource["OldPrice"+ColumnName]
												*((PriceTreeElementSource["ChangePercentage"+ColumnName]/100)+1), 2);
						PriceTreeElementSource["AmountOfChange"   + ColumnName] = 
							PriceTreeElementSource[ColumnName] - PriceTreeElementSource["OldPrice"+ColumnName];
					Else
						PriceTreeElementSource[ColumnName] = 
										Round(PriceTreeElementSource[ColumnName]*((PricesKind.ChangePercentage/100)+1), 2);
						PriceTreeElementSource["ChangePercentage" + ColumnName] = (PriceTreeElementSource[ColumnName] 
													/ PriceTreeElementSource["OldPrice" + ColumnName] - 1) * 100; 
						PriceTreeElementSource["AmountOfChange"   + ColumnName] = 
							PriceTreeElementSource[ColumnName] - PriceTreeElementSource["OldPrice"+ColumnName];
					EndIf;
					
				Else
					
					PriceTreeElementSource["ChangePercentage" + ColumnName] = 0;
					PriceTreeElementSource["AmountOfChange" + ColumnName] = 0;
					If Parameters.ChangeInRelationToOldPrice Then
						PriceTreeElementSource[ColumnName] = 0;
					Else
						PriceTreeElementSource[ColumnName] = 
										Round(PriceTreeElementSource[ColumnName]*((PricesKind.ChangePercentage/100)+1), 2);
					EndIf;
					
				EndIf;
				
				PriceTreeElementSource["ChangedManually" + ColumnName] = 
					(PriceTreeElementSource[ColumnName] - PriceTreeElementSource["OldPrice" + ColumnName] <> 0);
				PriceTreeElementSource["ChangedAutomatically" + ColumnName] = False;
			EndDo;
		ElsIf Parameters.Operation = "ChangeVATRates" Then
			
			For Each PricesKind In Parameters.TypesOfPrices Do
				ColumnName = ColumnNameByPriceType(PricesKind.Key, DataCache);
				
				PriceTreeElementSource["VATRate" + ColumnName] = PricesKind.Value;
				PriceTreeElementSource["ManuallyChangedVATRate" + ColumnName] =
					(Not PriceTreeElementSource["InitialVATRate" + ColumnName] = PriceTreeElementSource["VATRate" + ColumnName]);
				PriceTreeElementSource["VATRateChangedAutomatically" + ColumnName] = False;
			EndDo;
			
		ElsIf Parameters.Operation = "ChangeVATRatesFromItem" Then
			
			For Each PricesKind In Parameters.TypesOfPrices Do
				ColumnName = ColumnNameByPriceType(PricesKind, DataCache);
				
				SearchParameters = New Structure("Products, Country, PriceKind",
						PriceTreeElementSource.Products, PriceTreeElementSource["Country" + ColumnName], PricesKind);
				ArrayOfFound = Parameters.ProductPriceTable.FindRows(SearchParameters);
				If ValueIsFilled(ArrayOfFound) Then
					ValueOfVATRate = ArrayOfFound[0].Rate1;
				Else
					Continue;
				EndIf;
				
				PriceTreeElementSource["VATRate" + ColumnName] = ValueOfVATRate;
				PriceTreeElementSource["ManuallyChangedVATRate" + ColumnName] =
					(Not PriceTreeElementSource["InitialVATRate" + ColumnName] = PriceTreeElementSource["VATRate" + ColumnName]);
				PriceTreeElementSource["VATRateChangedAutomatically" + ColumnName] = False;
			EndDo;
		EndIf;
		
		RowsProcessed = True;
	EndIf;
	
EndProcedure

Procedure AddRowToTablePart(Val PriceTreeIsDataTreeOfForm, Val Level, PriceTreeElementSource, Parameters, AddedLines = False)
	
	UsePriceManagementSystem25 = Parameters.Form.UsePriceManagementSystem25;
	
	If PriceTreeIsDataTreeOfForm Then
		PriceTreeElementsCur = PriceTreeElementSource.GetItems();
	Else
		PriceTreeElementsCur = PriceTreeElementSource.Rows;
	EndIf;
	
	For Each PriceTreeElementCur In PriceTreeElementsCur Do
		LevelBelowAddedLines = False;
		
		AddRowToTablePart(PriceTreeIsDataTreeOfForm, (Level + 1), PriceTreeElementCur, Parameters, LevelBelowAddedLines);
		
		If Not LevelBelowAddedLines Then
			If Parameters.OnlyChangedItems Then
				
				TheCostOfTheChanged = ThereArePriceChangesInLine(PriceTreeElementCur, Parameters.TypesOfPrices);
				If UsePriceManagementSystem25 And Not TheCostOfTheChanged Then
					TheCostOfTheChanged = ThereAreChangesInNDSRateInLine(PriceTreeElementCur, Parameters.TypesOfPrices);
				EndIf;
				
				If TheCostOfTheChanged Then
					ControllingNumberOfRows(Parameters);
					PutPriceStringInTablePart(Parameters, PriceTreeElementCur);
				EndIf;
			Else
				ControllingNumberOfRows(Parameters);
				PutPriceStringInTablePart(Parameters, PriceTreeElementCur);
			EndIf;
			
			AddedLines = True;
		Else
			AddedLines = LevelBelowAddedLines;
		EndIf;
				
	EndDo;

EndProcedure

// Returns a table of data layout settings from the document
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  GoodsTable - ValueTable - Table with added products.
//  DataCache - See InitializeDataCacheStructure
//
// Returns:
//  ValueTable - matching the nomenclature and characteristics with the added line of the price tree.
//
Function AddCompanyProducts(Form, Val GoodsTable, DataCache)
	
	TMCommonUse.NumberValueTable(GoodsTable, "IndexOf");
	
	GroupingOption = Form.GroupingOption;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
	"SELECT
	|	Table.IndexOf AS IndexOf,
	|	CAST(Table.Products AS Catalog.Products) AS Products,
	|	CAST(Table.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic
	|INTO TableOfProducts
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProducts.Products.ProductKind AS ProductKind,
	|	TableOfProducts.Products.Description AS Description,
	|	&HierarchyRelationshipField,
	|	TableOfProducts.Products AS Products,
	|	TableOfProducts.Products.UnitOfMeasure AS UnitOfMeasure,
	|	TableOfProducts.Products.PriceGroup AS PriceGroup,
	|	TableOfProducts.Characteristic AS Characteristic,
	|	TableOfProducts.Products.SKU AS SKU,
	|	CASE
	|		WHEN TableOfProducts.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|FROM
	|	TableOfProducts AS TableOfProducts
	|
	|ORDER BY
	|	TableOfProducts.IndexOf
	|TOTALS BY
	|	Products";
	
	If Form.UseItemPackages Then
		Query.Text = Query.Text + "
		|;
		|SELECT ALLOWED
		|	ItemsPrices.Products   AS Products,
		|	ItemsPrices.Characteristic AS Characteristic,
		|	ItemsPrices.Package       AS Package,
		|	ItemsPrices.PriceKind        AS PriceKind
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(&DocumentDate, (Products, Characteristic) IN (SELECT T.Products, T.Characteristic FROM TableOfProducts AS T) AND PriceKind IN (&TypesOfPrices)) AS ItemsPrices
		|";
	EndIf;

	HierarchicalTree = True;
	If GroupingOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
		
		HierarchyRelationshipField = "TableOfProducts.Products.Parent AS Parent,";
		QueryingHierarchy = 
		"SELECT DISTINCT
		|	TableOfProducts.Products.Parent AS Products,
		|	TableOfProducts.Products.Parent.Description AS Description,
		|	TableOfProducts.Products.Parent.IsFolder AS HierarchyIsGroup,
		|	TableOfProducts.Products.Parent.IsFolder AS ThisIsHierarchy
		|FROM
		|	TableOfProducts AS TableOfProducts
		|WHERE
		|	TableOfProducts.Products.Parent <> VALUE(Catalog.Products.EmptyRef)
		|AUTOORDER
		|TOTALS BY
		|	Products HIERARCHY";
		
	ElsIf GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
		
		HierarchyRelationshipField = "";
		QueryingHierarchy = 
		"SELECT DISTINCT
		|	TableOfProducts.Products.ProductKind AS ProductKind,
		|	TableOfProducts.Products.ProductKind.Description AS Description,
		|	TableOfProducts.Products.ProductKind.IsFolder AS HierarchyIsGroup,
		|	TRUE AS ThisIsHierarchy
		|FROM
		|	TableOfProducts AS TableOfProducts
		|AUTOORDER
		|TOTALS
		|	MAX(ThisIsHierarchy)
		|BY
		|	ProductKind HIERARCHY";
		
	Else
		
		HierarchicalTree = False;
		HierarchyRelationshipField = "";
		QueryingHierarchy = 
		"SELECT
		|	1 AS Field1
		|WHERE
		|	FALSE";
		
	EndIf; 
	
	Query.Text = StrReplace(Query.Text,"&HierarchyRelationshipField,",HierarchyRelationshipField);
	
	SelectedTypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(Form);
	SelectedRowsOfPriceTypes = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
	
	Query.SetParameter("Table",       GoodsTable);
	Query.SetParameter("TypesOfPrices",       SelectedTypesOfPrices);
	Query.SetParameter("DocumentDate", EndOfDay(DocumentDate(Form)));
	
	QueryResult = Query.ExecuteBatch();
	
	SelectionOfProducts = QueryResult[1].Select(QueryResultIteration.ByGroups);
	
	If Form.UseItemPackages Then
		Packages = QueryResult[2].Unload(); // ValueTable
		Packages.Indexes.Add("Products, Characteristic");
	EndIf;
	
	EmptyCharacteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	EmptyItemList = Catalogs.Products.EmptyRef();
	
	ProductsTable = CreateProductTable(Form);
	ProductsTable.Columns.Add("PriceTreeString");
	
	// we check where the call 
	// comes from if it is from a managed form, then the type of the call is (Form.Derevocene) = Type("Given tree form"), getting a set of strings via *.Get elements()
	// if from the structure means the type of the form(Form.Derevocene) = Type("Structure"), getting a set of strings via *.Lines
	PriceTreeIsDataTreeOfForm = (TypeOf(Form.PriceTree) = Type("FormDataTree"));

	Parameters = New Structure();
	Parameters.Insert("PriceTreeIsDataTreeOfForm", TypeOf(Form.PriceTree) = Type("FormDataTree"));
	
	If HierarchicalTree Then
		
		Query.Text = QueryingHierarchy;
		TreeHierarchy = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
		If GroupingOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
			KeyField = "Products";
		ElsIf GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
			KeyField = "ProductKind";
		Else
			KeyField = "";
		EndIf;
		
		If ValueIsFilled(KeyField) Then
			
			For Each TreeRow In TreeHierarchy.Rows Do
				RemoveDuplicateRowsFromHierarchy(TreeRow, TreeRow.Rows.Count(), KeyField);
			EndDo;
			
			SearchForEmptyString = TreeHierarchy.Rows.Find(Catalogs.Products.EmptyRef(), KeyField);
			If SearchForEmptyString <> Undefined Then
				TreeHierarchy.Rows.Delete(SearchForEmptyString);
			EndIf;
			
		EndIf;
		
		CopyHierarchyTreeRows(Form, Form.PriceTree, TreeHierarchy, DataCache);
		
	EndIf;
	
	If PriceTreeIsDataTreeOfForm Then
		ProductItems_ = Form.PriceTree.GetItems(); // FormDataTreeItemCollection
	Else
		ProductItems_ = Form.PriceTree.Rows;
	EndIf;
	
	While SelectionOfProducts.Next() Do
		
		FilterParameters = New Structure("Products, Characteristic", SelectionOfProducts.Products, EmptyCharacteristic);
		FoundRow = FindPriceTreeString(Form, FilterParameters, DataCache, False);
		
		If FoundRow <> Undefined Then
			ProductItem = FoundRow;
			FillPropertyValues(ProductItem, SelectionOfProducts);
		Else
			
			If HierarchicalTree Then
				If GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
					FilterParameters = New Structure("Products,Characteristic,ProductKind", 
						EmptyItemList,EmptyCharacteristic, SelectionOfProducts.ProductKind);
				Else
					FilterParameters = New Structure("Products, Characteristic", 
						SelectionOfProducts.Parent, EmptyCharacteristic);
				EndIf; 
				
				HierarchyFound = FindPriceTreeString(Form, FilterParameters, DataCache, False);
				
				If HierarchyFound = Undefined Then
					ProductItem = ProductItems_.Add();
				Else
					If TypeOf(HierarchyFound) = Type("FormDataTreeItem") Then
						ProductItem = HierarchyFound.GetItems().Add();
					Else
						ProductItem = HierarchyFound.Rows.Add();
					EndIf; 
				EndIf; 
			Else
				ProductItem = ProductItems_.Add();
			EndIf; 
			
			FillPropertyValues(ProductItem, SelectionOfProducts);
			SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(ProductItem);
			
			NewLineOfVT = NewRowOfMatchingTable(DataCache, ProductItem, PriceTreeIsDataTreeOfForm);
			
			FillPropertyValues(ProductsTable.Add(), NewLineOfVT);
			
			If Form.UseItemPackages Then
				
				SearchParameters = New Structure("Products, Characteristic", ProductItem.Products, Catalogs.ItemsCharacteristics.EmptyRef());
				
				FoundRows = Packages.FindRows(SearchParameters);
				For Each PackageSelection In FoundRows Do
					ProductItem["Package" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
				EndDo;
				
			EndIf;
			
		EndIf;
		
		If Form.UseItemVariants Then
			
			FeatureSelection_ = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
			
			If PriceTreeIsDataTreeOfForm Then
				FeatureElements = ProductItem.GetItems();
			Else
				FeatureElements = ProductItem.Rows;
			EndIf;
			
			While FeatureSelection_.Next() Do
				
				If ValueIsFilled(FeatureSelection_.Characteristic) Then
					
					FilterParameters = New Structure("Products, Characteristic", FeatureSelection_.Products, FeatureSelection_.Characteristic);
					FoundRow = FindPriceTreeString(Form, FilterParameters, DataCache, False);
					
					If FoundRow <> Undefined Then
						ElementCharacteristic = FoundRow;
					Else
						
						ElementCharacteristic = FeatureElements.Add();
						FillPropertyValues(ElementCharacteristic, FeatureSelection_);
						SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(ElementCharacteristic);
						
						NewLineOfVT = NewRowOfMatchingTable(DataCache, ElementCharacteristic, PriceTreeIsDataTreeOfForm);
						
						FillPropertyValues(ProductsTable.Add(), NewLineOfVT);
						
						If Form.UseItemPackages Then
							
							SearchParameters = New Structure("Products,Characteristic", ElementCharacteristic.Products, ElementCharacteristic.Characteristic);
							
							FoundRows = Packages.FindRows(SearchParameters);
							For Each PackageSelection In FoundRows Do
								ElementCharacteristic["Package" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
							EndDo;
							
						EndIf;
						
						FillInFormula_(SelectedRowsOfPriceTypes, ElementCharacteristic);
						FillCurrency(SelectedRowsOfPriceTypes, ElementCharacteristic);
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	SaveItemComplianceTable(Form, DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree);
	Return ProductsTable;
	
EndFunction

Procedure RemoveDuplicateRowsFromHierarchy(TreeRow, RowsCount, FieldName)
	
	For IndexOf = 1 To TreeRow.Rows.Count() Do
		
		ChildRow = TreeRow.Rows.Get(RowsCount - IndexOf);
		
		If ChildRow[FieldName] = TreeRow[FieldName] Then
			TreeRow.Rows.Delete(ChildRow);
		ElsIf Not ValueIsFilled(ChildRow[FieldName]) Then
			
		Else
			RemoveDuplicateRowsFromHierarchy(ChildRow, ChildRow.Rows.Count(), FieldName);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns a table of data layout settings from the document
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  GoodsTable - ValueTable - Table with added products.
//  DataCache - Structure - Structure of the data cache.
//
// Returns:
//  ValueTable - matching the nomenclature and characteristics with the added line of the price tree.
//
Function AddCompanyProducts2_5(Form, Val GoodsTable, DataCache)
	
	TMCommonUse.NumberValueTable(GoodsTable, "IndexOf");
	
	GroupingOption = Form.GroupingOption;
	SelectedTypesOfPrices = SettingPricesClientServer.SelectedTypesOfPrices(Form);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;	
	
	Query.SetParameter("Table", GoodsTable);
	Query.SetParameter("TypesOfPrices", SelectedTypesOfPrices);
	Query.SetParameter("DocumentDate", EndOfDay(DocumentDate(Form)));
	Query.Text =
	"SELECT
	|	Table.IndexOf AS IndexOf,
	|	CAST(Table.Products AS Catalog.Products) AS Products,
	|	Table.PricingVariant AS PricingVariant,
	|	CAST(Table.PricingBatch AS Catalog.ItemsBatchesForPricing) AS PricingBatch,
	|	CAST(Table.PricingPackage AS Catalog.PackagesAndUnitsOfMeasure) AS PricingPackage
	|INTO TableProductList
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ItemKinds.Ref AS ProductKind,
	|	ItemKinds.SettingsOfPriceKeyByItemVariant AS SettingsOfPriceKeyByItemVariant,
	|	ItemKinds.SettingsOfPriceKeyByBatch AS SettingsOfPriceKeyByBatch,
	|	ItemKinds.SettingsOfPriceKeyByPackage AS SettingsOfPriceKeyByPackage
	|INTO TableTypesOfItems
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProducts.IndexOf AS IndexOf,
	|	TableOfProducts.Products AS Products,
	|	TableOfProducts.PricingVariant AS PricingVariant,
	|	TableOfProducts.PricingBatch AS PricingBatch,
	|	TableOfProducts.PricingPackage AS PricingPackage,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|				OR CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ItemVariantsAreUsed,
	|	ItemKinds.SettingsOfPriceKeyByBatch <> VALUE(Enum.FilterOptionForPriceKey.DontUse) AS SeriesAreUsed,
	|	ItemKinds.SettingsOfPriceKeyByPackage <> VALUE(Enum.FilterOptionForPriceKey.DontUse) AS PackagesAreUsed
	|INTO TableOfProducts
	|FROM
	|	TableProductList AS TableOfProducts
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfProducts.Products = CatalogProducts.Ref
	|		LEFT JOIN TableTypesOfItems AS ItemKinds
	|		ON CatalogProducts.ProductKind = ItemKinds.ProductKind
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&HierarchyRelationshipField,
	|	TableOfProducts.Products.ProductKind AS ProductKind,
	|	TableOfProducts.Products.SKU AS SKU,
	|	TableOfProducts.Products.Description AS Description,
	|	TableOfProducts.Products AS Products,
	|	TableOfProducts.Products.UnitOfMeasure AS UnitOfMeasure,
	|	TableOfProducts.Products.PriceGroup AS PriceGroup,
	|	TableOfProducts.PricingVariant AS PricingVariant,
	|	TableOfProducts.PricingBatch AS PricingBatch,
	|	CASE
	|		WHEN TableOfProducts.PricingBatch.Predefined
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE TableOfProducts.PricingBatch
	|	END AS TSOSeriesForCommunication,
	|	TableOfProducts.PricingPackage AS PricingPackage,
	|	CASE
	|		WHEN TableOfProducts.PricingPackage = TableOfProducts.Products.UnitOfMeasure
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE TableOfProducts.PricingPackage
	|	END AS TsoPackagingForCommunication,
	|	TableOfProducts.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TableOfProducts.SeriesAreUsed AS SeriesAreUsed,
	|	TableOfProducts.PackagesAreUsed AS PackagesAreUsed
	|FROM
	|	TableOfProducts AS TableOfProducts
	|
	|ORDER BY
	|	TableOfProducts.IndexOf
	|TOTALS
	|	MIN(TSOSeriesForCommunication),
	|	MIN(TsoPackagingForCommunication),
	|	MIN(ItemVariantsAreUsed),
	|	MIN(SeriesAreUsed),
	|	MIN(PackagesAreUsed)
	|BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ItemsPrices.Products AS Products,
	|	ItemsPrices.PricingVariant AS PricingVariant,
	|	ItemsPrices.PricingBatch AS PricingBatch,
	|	ItemsPrices.PricingPackage AS PricingPackage,
	|	ItemsPrices.Package AS Package,
	|	ItemsPrices.Formula AS Formula,
	|	ItemsPrices.PriceKind AS PriceKind
	|FROM
	|	InformationRegister.ItemsPrices25.SliceLast(
	|			&DocumentDate,
	|			(Products, PricingVariant, PricingBatch, PricingPackage) IN
	|					(SELECT
	|						T.Products,
	|						T.PricingVariant,
	|						T.PricingBatch,
	|						T.PricingPackage
	|					FROM
	|						TableOfProducts AS T)
	|				AND PriceKind IN (&TypesOfPrices)) AS ItemsPrices
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfPrices.Ref AS PriceKind,
	|	TypesOfPrices.Country AS Country
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Ref IN (&TypesOfPrices)
	|	AND TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.PricingVariant AS PricingVariant,
	|	TableOfGoods.PricingBatch AS PricingBatch,
	|	TableOfGoods.PricingPackage AS PricingPackage,
	|	TypesOfPrices.Ref AS PriceKind,
	|	CASE
	|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems)
	|			THEN TypesOfPrices.VATRate
	|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine)
	|			THEN ItemsPrices.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate
	|FROM
	|	TableOfProducts AS TableOfGoods
	|LEFT JOIN
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|ON
	|	TRUE
	|LEFT JOIN
	|	InformationRegister.ItemsPrices25.SliceLast(
	|			&DocumentDate,
	|			PriceKind IN (&TypesOfPrices)
	|			AND (Products, PricingVariant, PricingBatch, PricingPackage) IN
	|					(SELECT
	|						T.Products,
	|						T.PricingVariant,
	|						T.PricingBatch,
	|						T.PricingPackage
	|					FROM
	|						TableOfProducts AS T)
	|	) AS ItemsPrices
	|ON
	|	TableOfGoods.Products = ItemsPrices.Products
	|	AND TableOfGoods.PricingVariant = ItemsPrices.PricingVariant
	|	AND TableOfGoods.PricingBatch = ItemsPrices.PricingBatch
	|	AND TableOfGoods.PricingPackage = ItemsPrices.PricingPackage
	|	AND TypesOfPrices.Ref = ItemsPrices.PriceKind
	|WHERE
	|	TypesOfPrices.Ref IN (&TypesOfPrices)
	|	AND TypesOfPrices.Ref IS NOT NULL
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.PricingVariant,
	|	TableOfGoods.PricingBatch,
	|	TableOfGoods.PricingPackage,
	|	TypesOfPrices.Ref,
	|	CASE
	|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems)
	|			THEN TypesOfPrices.VATRate
	|		WHEN TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine)
	|			THEN ItemsPrices.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END
	|";
	
	HierarchicalTree = True;
	If GroupingOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
		
		HierarchyRelationshipField = "TableOfProducts.Products.Parent AS Parent,";
		QueryingHierarchy =
		"SELECT DISTINCT
		|	TableOfProducts.Products.Parent AS Products,
		|	TableOfProducts.Products.Parent.Description AS Description,
		|	TableOfProducts.Products.Parent.IsFolder AS HierarchyIsGroup,
		|	TableOfProducts.Products.Parent.IsFolder AS ThisIsHierarchy
		|FROM
		|	TableOfProducts AS TableOfProducts
		|WHERE
		|	TableOfProducts.Products.Parent <> VALUE(Catalog.Products.EmptyRef)
		|AUTOORDER
		|TOTALS BY
		|	Products HIERARCHY";
		
	ElsIf GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
		
		HierarchyRelationshipField = "TableOfProducts.Products.ProductKind AS Parent,";
		QueryingHierarchy =
		"SELECT DISTINCT
		|	TableOfProducts.Products.ProductKind AS ProductKind,
		|	TableOfProducts.Products.ProductKind.Description AS Description,
		|	TableOfProducts.Products.ProductKind.IsFolder AS HierarchyIsGroup,
		|	TRUE AS ThisIsHierarchy
		|FROM
		|	TableOfProducts AS TableOfProducts
		|AUTOORDER
		|TOTALS
		|	MAX(ThisIsHierarchy)
		|BY
		|	ProductKind HIERARCHY";
		
	Else
		
		HierarchicalTree = False;
		HierarchyRelationshipField = "";
		QueryingHierarchy = 
		"SELECT
		|	1 AS Field1
		|WHERE
		|	FALSE";
		
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&HierarchyRelationshipField,", HierarchyRelationshipField);
	
	QueryResult = Query.ExecuteBatch();
	
	SelectionOfProducts = QueryResult[3].Select(QueryResultIteration.ByGroups);
	
	Packages = QueryResult[4].Unload();
	Packages.Indexes.Add("Products, PricingVariant, PricingBatch, PricingPackage");
	
	Countries = QueryResult[5].Unload();
	VATRates = QueryResult[6].Unload();
	VATRates.Indexes.Add("Products, PricingVariant, PricingBatch, PricingPackage");
	
	ProductsTable = CreateProductTable(Form);
	ProductsTable.Columns.Add("PriceTreeString");
	
	Parameters = New Structure();
	Parameters.Insert("PriceTreeIsDataTreeOfForm", TypeOf(Form.PriceTree) = Type("FormDataTree"));
	Parameters.Insert("HierarchicalTree", HierarchicalTree);
	Parameters.Insert("GroupingOption", GroupingOption);
	
	If HierarchicalTree Then
		
		Query.Text = QueryingHierarchy;
		TreeHierarchy = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
		If GroupingOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
			KeyField = "Products";
		ElsIf GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
			KeyField = "ProductKind";
		Else
			KeyField = "";
		EndIf;
		
		If ValueIsFilled(KeyField) Then
			
			For Each TreeRow In TreeHierarchy.Rows Do
				RemoveDuplicateRowsFromHierarchy(TreeRow, TreeRow.Rows.Count(), KeyField);
			EndDo;
			
			SearchForEmptyString = TreeHierarchy.Rows.Find(Catalogs.Products.EmptyRef(), KeyField);
			If SearchForEmptyString <> Undefined Then
				TreeHierarchy.Rows.Delete(SearchForEmptyString);
			EndIf;
			
		EndIf;
		
		CopyHierarchyTreeRows(Form, Form.PriceTree, TreeHierarchy, DataCache);
		
	EndIf;
	
	SelectedRowsOfPriceTypes = SettingPricesClientServer.SelectedRowsInPriceViewTable(Form);
	
	Parameters.Insert("ProductsTable", ProductsTable);
	Parameters.Insert("Packages", Packages);
	Parameters.Insert("SelectedTypesOfPrices", SelectedRowsOfPriceTypes);
	Parameters.Insert("Countries", Countries);
	Parameters.Insert("VATRates", VATRates);
	
	AddCompanyProduct(Form, DataCache, SelectionOfProducts, Form.PriceTree, Parameters, 1);
	SaveItemComplianceTable(Form, DataCache.TableOfCorrespondenceOfProductsToRowsInProductTree);
	
	Return ProductsTable;
	
EndFunction

// Adding new rows to the price tree
// 
// Parameters:
//  Form - See BuildPriceTree.Form
//  DataCache - See InitializeDataCacheStructure 
// 	SelectingRows - QueryResultSelection - selecting rows
// 	PriceTreeElement - FormDataTree, ValueTree - price tree
// 	Parameters - Structure - Parameters:
//    * PriceTreeIsDataTreeOfForm - Boolean - indicates the shape of the price tree.
//    * HierarchicalTree - Boolean - indicates a hierarchical tree.
//    * GroupingOption - EnumRef.ItemFormNavigationOptions - 
//    * ProductsTable - ValueTable - data on added products.
//    * Packages - ValueTable - packages.
//    * SelectedTypesOfPrices - Array of FormDataCollectionItem- selected prices.
// 	Level - Number - current price tree level
Procedure AddCompanyProduct(Form, DataCache, SelectingRows, PriceTreeElement, Parameters, Val Level)

	BlankRefs = Undefined;
	
	If Parameters.PriceTreeIsDataTreeOfForm Then
		PriceTreeElements = PriceTreeElement.GetItems();
	Else
		PriceTreeElements = PriceTreeElement.Rows;
	EndIf;
	
	While SelectingRows.Next() Do
		
		FilterParameters = New Structure("Products, PricingVariant, PricingBatch, PricingPackage", 
											SelectingRows.Products, 
											SelectingRows.PricingVariant, 
											SelectingRows.PricingBatch, 
											SelectingRows.PricingPackage);
		FoundRow = FindPriceTreeString(Form, FilterParameters, DataCache, False);
		
		If FoundRow <> Undefined Then
			
			CurrentItem = FoundRow;
			FillPropertyValues(CurrentItem, SelectingRows);
			
		Else
			
			If Parameters.HierarchicalTree And Level = 1 Then
				If BlankRefs = Undefined Then
					BlankRefs = New Structure("Products, PricingVariant, PricingBatch, PricingPackage", 
						Catalogs.Products.EmptyRef(),
						Catalogs.ItemsCharacteristicsForPricing.EmptyRef(),
						Catalogs.ItemsBatchesForPricing.EmptyRef(),
						Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
				EndIf;
				
				If Parameters.GroupingOption = Enums.ItemFormNavigationOptions.ByKinds Then
					FilterParameters = New Structure("Products,PricingVariant, PricingBatch, PricingPackage,ProductKind", 
						BlankRefs.Products, 
						BlankRefs.PricingVariant, 
						BlankRefs.PricingBatch, 
						BlankRefs.PricingPackage, 
						SelectingRows.ProductKind);
				Else
					FilterParameters = New Structure("Products,PricingVariant, PricingBatch, PricingPackage", 
						SelectingRows.Parent, 
						BlankRefs.PricingVariant, 
						BlankRefs.PricingBatch, 
						BlankRefs.PricingPackage);
				EndIf; 
				
				HierarchyFound = FindPriceTreeString(Form, FilterParameters, DataCache, False);
				
				If HierarchyFound = Undefined Then
					CurrentItem = PriceTreeElements.Add();
				Else
					If Parameters.PriceTreeIsDataTreeOfForm Then
						CurrentItem = HierarchyFound.GetItems().Add();
					Else
						CurrentItem = HierarchyFound.Rows.Add();
					EndIf; 
				EndIf; 
			Else
				CurrentItem = PriceTreeElements.Add();
			EndIf; 
			
			FillPropertyValues(CurrentItem, SelectingRows);
			SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(CurrentItem);
			
			NewLineOfVT = NewRowOfMatchingTable(DataCache, CurrentItem, Parameters.PriceTreeIsDataTreeOfForm);
			
			FillCountry(Parameters.Countries, DataCache, CurrentItem);
			
		EndIf;

		If (Level > 3) Then
			If NewLineOfVT <> Undefined Then
				
				NewRowOfProductTable = Parameters.ProductsTable.Add();
				FillPropertyValues(NewRowOfProductTable, SelectingRows);
				NewRowOfProductTable.PriceTreeString = CurrentItem;
				
			EndIf;

			AddProductToFragment(Form, DataCache, CurrentItem, SelectingRows, Parameters);
			
			Continue;
		EndIf;
		
		NextGrouping = GetFollowingDimension(Level, SelectingRows);
		
		If NextGrouping.Group = Undefined Then
			If NewLineOfVT <> Undefined Then
	
				NewRowOfProductTable = Parameters.ProductsTable.Add();
				FillPropertyValues(NewRowOfProductTable, SelectingRows);
				NewRowOfProductTable.PriceTreeString = CurrentItem;
				
			EndIf;
			
			AddProductToFragment(Form, DataCache, CurrentItem, SelectingRows, Parameters);
				
			Continue;
		EndIf;

		FetchingSubordinateRows = SelectingRows.Select(QueryResultIteration.ByGroups, NextGrouping.Group);
		AddCompanyProduct(Form, DataCache, FetchingSubordinateRows, CurrentItem, Parameters, NextGrouping.Level);
				
	EndDo;
EndProcedure

Procedure AddProductToFragment(Form, DataCache, CurrentItem, SelectingRows, Parameters)

	FilterParameters = New Structure(
		"Products, PricingVariant, PricingBatch, PricingPackage", 
		SelectingRows.Products, 
		?(Form.UseItemVariants And ValueIsFilled(SelectingRows.PricingVariant), SelectingRows.PricingVariant, Catalogs.ItemsCharacteristicsForPricing.EmptyRef()),
		?(Form.UseItemsBatch And ValueIsFilled(SelectingRows.PricingBatch), SelectingRows.PricingBatch, Catalogs.ItemsBatchesForPricing.EmptyRef()),
		?(Form.UseItemPackages And ValueIsFilled(SelectingRows.PricingPackage), SelectingRows.PricingPackage, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef())
		);
	FoundRows = Parameters.Packages.FindRows(FilterParameters);
	For Each PackageSelection In FoundRows Do
		CurrentItem["Formula" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Formula;
		
		If Form.UseItemPackages And Not CurrentItem.PackagesAreUsed Then
			CurrentItem["Package" + ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
		EndIf;
	EndDo;
	
	FoundRows = Parameters.VATRates.FindRows(FilterParameters);
	For Each SamplingOfVATRate In FoundRows Do
		
		CurrentItem["VATRate" + ColumnNameByPriceType(SamplingOfVATRate.PriceKind, DataCache)] = SamplingOfVATRate.VATRate;
		
	EndDo;

	If Form.UseItemPackages 
		And SelectingRows.PackagesAreUsed 
		And Not SelectingRows.TsoPackagingForCommunication.IsEmpty() Then
			
		For Each PriceKind In Parameters.SelectedTypesOfPrices Do
			ColumnName = PriceKind.ColumnName;
			CurrentItem["Package" + ColumnName] = SelectingRows.TsoPackagingForCommunication;
		EndDo;
		
	EndIf;

	FillInFormula_(Parameters.SelectedTypesOfPrices, CurrentItem);
	FillCurrency(Parameters.SelectedTypesOfPrices, CurrentItem);
	
EndProcedure

Procedure CopyHierarchyTreeRows(Form, Receiver, Source, DataCache)
	
	SourceRows = Source.Rows;
	
	PriceTreeIsDataTreeOfForm = TypeOf(Form.PriceTree) = Type("FormDataTree");
	If PriceTreeIsDataTreeOfForm Then
		DestinationRows = Receiver.GetItems(); 
	Else
		DestinationRows = Receiver.Rows; 
	EndIf;	
		
	For Each SourceRow1 In SourceRows Do
		
		DestinationRow1 = FindPriceTreeString(Form, SourceRow1, DataCache, False);
		
		If DestinationRow1 = Undefined Then
			DestinationRow1 = DestinationRows.Add();
			FillPropertyValues(DestinationRow1, SourceRow1);
			SettingPricesClientServer.FillInIndexOfEachRowOfPriceTree(DestinationRow1);
			
			NewRowOfMatchingTable(DataCache, DestinationRow1, PriceTreeIsDataTreeOfForm);
		EndIf;
		
		CopyHierarchyTreeRows(Form, DestinationRow1, SourceRow1, DataCache);
	EndDo; 
	
EndProcedure
 
Function GetFollowingDimension(Val Level, SelectingRows)
	
	Level = Level + 1;
	NextGrouping = New Structure("Level, Group", 0, Undefined);
	
	If Level = 2 Then
		If SelectingRows.ItemVariantsAreUsed Then
			NextGrouping.Level     = Level;
			NextGrouping.Group = "PricingVariant";
		Else	
			NextGrouping = GetFollowingDimension(Level, SelectingRows);
		EndIf;
	ElsIf Level = 3 Then
		If SelectingRows.SeriesAreUsed Then
			NextGrouping.Level     = Level;
			NextGrouping.Group = "PricingBatch";
		Else	
			NextGrouping = GetFollowingDimension(Level, SelectingRows);
		EndIf;
	ElsIf Level = 4 Then		
		If SelectingRows.PackagesAreUsed Then
			NextGrouping.Level     = Level;
			NextGrouping.Group = "PricingPackage";
		EndIf;
	EndIf;	
	
	Return NextGrouping;
	
EndFunction

Procedure FillInFormula_(Val SelectedTypesOfPrices, Item)
	
	For Each PriceKind In SelectedTypesOfPrices Do

		If Not PriceKind.FormulaIsBeingEdited Then
			Continue;
		EndIf;
		
		ColumnName = PriceKind.ColumnName;
		Formula = Item["Formula" + ColumnName];
		StructurePriceGroup = New Structure("PriceGroup", Item.PriceGroup);
		
		PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
		If PriceGroupsOfAlgorithms.Count() > 0 Then
			DefaultFormulaIs = PriceGroupsOfAlgorithms[0].Formula;
		Else
			DefaultFormulaIs = PriceKind.Formula;
		EndIf;
		
		Formula = ?(Formula = "", DefaultFormulaIs, Formula);
		Item["Formula" + ColumnName] = Formula;
		Item["FormulaChangedManually" + ColumnName] = (Formula <> DefaultFormulaIs);
		
	EndDo;
	
EndProcedure

Procedure FillCurrency(Val SelectedTypesOfPrices, Item)
	
	For Each PriceKind In SelectedTypesOfPrices Do

		ColumnName = PriceKind.ColumnName;
		Currency = Item["Currency" + ColumnName];
		StructurePriceGroup = New Structure("PriceGroup", Item.PriceGroup);
		
		CurrencyPriceGroups = PriceKind.Currencies.FindRows(StructurePriceGroup);
		If CurrencyPriceGroups.Count() > 0 Then
			DefaultCurrency = CurrencyPriceGroups[0].Currency;
		Else
			DefaultCurrency = PriceKind.Currency;
		EndIf;
		
		Currency = ?(Currency.IsEmpty(), DefaultCurrency, Currency);
		Item["Currency" + ColumnName] = Currency;
		
	EndDo;
	
EndProcedure

Procedure FillCountry(SelectedCountries, DataCache, CurrentItem)
	
	For Each TableRow In SelectedCountries Do
		CurrentItem["Country" + ColumnNameByPriceType(TableRow.PriceKind, DataCache)] = TableRow.Country;
	EndDo;

EndProcedure

Procedure AddSubordinateElements(ProductsTable, PriceTableRow)
	Items = PriceTableRow.GetItems();
	If Items.Count() > 0 Then
		For Each Item In Items Do
			FillPropertyValues(ProductsTable.Add(), Item, "Products, PricingVariant, PricingBatch, PricingPackage");
			AddSubordinateElements(ProductsTable, Item);
		EndDo;
	EndIf;
EndProcedure

// Creates an entry in the log and messages to the user, 
//  Supports up to 4 parameters in comments using the function 
//    Strokemymouse.Substitute the parameter string
//  Supports transmitting error information, and a detailed representation 
//    of the error is added to the log entry comment.
// 
// Parameters:
//   LogParameters  - Structure - parameters for recording in the registration Log:
//    * Prefix    - String           - the prefix for the name of the event log.
//    * Metadata - MetadataObject - metadata for writing to the log.
//    * Data     - Arbitrary     - data to write to the log.
//   LogLevel - Number - Corresponds to the log levels.
//   EventName     - String - The suffix for the name of the event log.
//   CommentWithParameters -String - Comment, possibly with parameters %1 .. %4.
//   ErrorInfo - ErrorInfo, String - Information about the error that also needs
//                                                     to be documented in the log comments.
//
Procedure LogRecord(LogParameters, LogLevel , EventName, 
		Val CommentWithParameters , ErrorInfo = "") Export
	
	// Determining the log level based on the type of error message passed.
	If TypeOf(LogLevel) <> Type("EventLogLevel") Then
		If TypeOf(ErrorInfo) = Type("String") Then
			LogLevel = EventLogLevel.Warning;
		ElsIf TypeOf(ErrorInfo) = Type("ErrorInfo") Then
			LogLevel = EventLogLevel.Error;
		Else
			LogLevel = EventLogLevel.Information;
		EndIf;
	EndIf;
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		If CommentWithParameters = "" Then
			MessageToUserText = BriefErrorDescription(ErrorInfo);
			CommentWithParameters = DetailErrorDescription(ErrorInfo);
		Else
			MessageToUserText = CommentWithParameters + Chars.LF + BriefErrorDescription(ErrorInfo);
			CommentWithParameters = CommentWithParameters + Chars.LF + DetailErrorDescription(ErrorInfo);
		EndIf;
	Else
		If TypeOf(ErrorInfo) = Type("String") And ErrorInfo <> "" Then
			CommentWithParameters = CommentWithParameters + Chars.LF + ErrorInfo;
		EndIf;
		MessageToUserText = CommentWithParameters;
	EndIf;
	
	// Log 
	SetPrivilegedMode(True);
	EventGroup_ = LogParameters.EventGroup_ + ?(EventName = "", "", "."+ EventName);
	WriteLogEvent(
		EventGroup_, 
		LogLevel, 
		LogParameters.Metadata, 
		LogParameters.Data, 
		CommentWithParameters);
	SetPrivilegedMode(False);
	
	If LogLevel = EventLogLevel.Error
		Or LogLevel = EventLogLevel.Warning Then
		If LogLevel = EventLogLevel.Error Then
			LogParameters.Insert("HadErrors", True);
		Else
			LogParameters.Insert("HasWarnings", True);
		EndIf;
		Message = New UserMessage;
		Message.Text = TrimAll(MessageToUserText); //  + Symbols.PS + Symbols.PS + NStr ("ru = 'For details, see in the registration log.'")
		Message.SetData(LogParameters.Data);
		Message.Message();
	EndIf;
	
EndProcedure

Function ErrorTemplateForCalculatingPriceAccordingToInfobaseData()
	
	Return NStr("vi = 'Lỗi tính đơn giá thông qua truy vấn đến dữ liệu CSTT theo dạng giá ""%1""';
				|ru = 'Ошибка расчета цены с помощью запроса к данным ИБ по виду цен ""%1""';
				|en = 'An error occurred when calculating the price using an arbitrary request to infobase data for the ""%1"" price type'; fa = 'An error occurred when calculating the price using an arbitrary request to infobase data for the ""%1"" price type';
				|it = 'An error occurred when calculating the price using an arbitrary request to infobase data for the ""%1"" price type';
				|pl = 'An error occurred when calculating the price using an arbitrary request to infobase data for the ""%1"" price type';
				|tr = '""%1"" fiyat türü için IB veri sorgusu kullanılarak fiyat hesaplama hatası'");
	
EndFunction

// Deletes goods that are not available for setting prices from the source table and returns them in a separate table
// with the reason for unavailability.
//
// Parameters:
// 	GoodsTable - ValueTable - the original goods table.
//
// Returns:
// 	ValueTable - Table of Unavailable Items:
// 		* Products - CatalogRef.Products - Products
// 		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
// 		* Cause - String - the reason for the unavailability of setting prices for the goods.
//
Function ItemsThatAreNotAvailableForSettingPrices(GoodsTable)
	
	If GoodsTable.Columns.Find("Products") = Undefined
		Or GoodsTable.Columns.Find("Characteristic") = Undefined Then
		Return New ValueTable;
	EndIf;
	
	Result = GoodsTable.Copy(New Array, "Products, Characteristic");
	Result.Columns.Add("Cause", New TypeDescription("String",,,, New StringQualifiers(200)));
	
	// kits, the price of which consists of the prices of components
	Query = New Query;
	Query.SetParameter("ProductsTable", GoodsTable.Copy(, "Products, Characteristic"));
	Query.Text =
	"SELECT
	|	ProductsTable.Products AS Products,
	|	ProductsTable.Characteristic AS Characteristic
	|INTO ProductsTable
	|FROM
	|	&ProductsTable AS ProductsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductsTable.Products AS Products,
	|	ProductsTable.Characteristic AS Characteristic
	|FROM
	|	ProductsTable AS ProductsTable
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ProductsTable.Products = CatalogProducts.Ref
	|		INNER JOIN Catalog.ProductKitConfigurations AS CatalogKitConfigurations
	|		ON ProductsTable.Products = CatalogKitConfigurations.Owner
	|		AND ProductsTable.Characteristic = CatalogKitConfigurations.Characteristic
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Set)
	|	AND NOT CatalogKitConfigurations.DeletionMark
	|	AND CatalogKitConfigurations.Main
	|	AND CatalogKitConfigurations.SetPricingOption =
	|		VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Result.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.Cause = NStr("vi = 'tập hợp, đơn giá được hình thành từ đơn giá của thành phần chi tiết';
							|ru = 'набор, цена складывается из цен комплектующих';
							|en = 'set, the price is a sum of component prices'; fa = 'set, the price is a sum of component prices';
							|it = 'set, the price is a sum of component prices';
							|pl = 'set, the price is a sum of component prices';
							|tr = 'küme, fiyat bileşenlerin fiyatlarından oluşur'");
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic",
			Selection.Products,
			Selection.Characteristic);
		
		SearchForStrings = GoodsTable.FindRows(TheStructureOfTheSearch);
		For Each RowToDelete In SearchForStrings Do
			GoodsTable.Delete(RowToDelete);
		EndDo;
			
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddPackagesFromTreeRecursively(PriceTree, ArrayOfPriceTypes, TableOfProductPackages)
	
	TreeItems = ?(TypeOf(PriceTree) = Type("FormDataTree")
		Or TypeOf(PriceTree) = Type("FormDataTreeItem"),
		PriceTree.GetItems(),
		PriceTree.Rows);
	
	For Each TreeItem In TreeItems Do
		
		AddPackagingProductsRowsOfPriceTableToTable(TreeItem, ArrayOfPriceTypes, TableOfProductPackages);
		AddPackagesFromTreeRecursively(TreeItem, ArrayOfPriceTypes, TableOfProductPackages);
		
	EndDo;
	
EndProcedure

#Region FillingInVATRates

// Getting the VAT rate for an Item.
//
// Parameters:
//  Form - See BuildPriceTree.Form
//  CalculationParameters - Structure - Structure of calculation parameters
//  
// Returns:
//  ValueTable - Table of nomenclature and VAT rates:
//   * Products - CatalogRef.Products - Products
//   * Country - CatalogRef.WorldCountries - Country
//   * Rate1 - CatalogRef.VATRates - VAT rate
//   * PriceKind - CatalogRef.TypesOfPrices - Type of price
Function GetBidForItem(Form, CalculationParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TypesOfPrices.Ref AS PriceKind,
	|	TypesOfPrices.Country AS Country
	|INTO TableTypesOfPrices
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	Ref IN (&SelectedTypesOfPrices)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsVATRates.Products AS Products,
	|	ProductsVATRates.Country AS Country,
	|	ProductsVATRates.VATRate AS Rate1,
	|	Table.PriceKind AS PriceKind
	|FROM
	|	InformationRegister.ProductsVATRates.SliceLast(&ValidityDate, 
	|		Products IN (&ProductsArray)
	|		AND Country IN (SELECT DISTINCT Country FROM TableTypesOfPrices)
	|	) AS ProductsVATRates 
	|LEFT JOIN
	|	TableTypesOfPrices AS Table
	|ON
	|	ProductsVATRates.Country = Table.Country
	|LEFT JOIN
	|	Catalog.VATRates AS Bids
	|ON
	|	ProductsVATRates.VATRate = Bids.Ref
	|WHERE
	|	NOT Bids.DeletionMark
	|	AND (Bids.BeginOfPeriod <= &ValidityDate
	|		OR Bids.BeginOfPeriod = DATETIME(1,1,1))
	|	AND (ENDOFPERIOD(Bids.EndOfPeriod, DAY) >= &ValidityDate
	|		OR Bids.EndOfPeriod = DATETIME(1,1,1))
	|";
	
	ProductsArray = New Array;
	If CalculationParameters.SelectedLinesOnly Then
		
		For Each SelectedRow In Form.Items.PriceTree.SelectedRows Do
			PriceTableRow = Form.PriceTree.FindByID(SelectedRow);
			ProductsArray.Add(PriceTableRow.Products);
		EndDo;
	
	Else	
		
		PriceTreeIsDataTreeOfForm = (TypeOf(Form.PriceTree) = Type("FormDataTree"));
		If PriceTreeIsDataTreeOfForm Then
			NomenclatureTreeShapeDataInArray(Form.PriceTree.GetItems(), ProductsArray);
		Else
			NomenclatureOfTreeInArray(Form.PriceTree.Rows, ProductsArray);
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(ProductsArray) Then
		Return Undefined;
	EndIf;
	
	Query.SetParameter("SelectedTypesOfPrices",	CalculationParameters.SelectedTypesOfPrices);
	Query.SetParameter("ProductsArray",	ProductsArray);
	Query.SetParameter("ValidityDate",		CalculationParameters.ValidityDate);
	
	DataTable = Query.Execute().Unload();
	
	Return DataTable;
	
EndFunction

Procedure NomenclatureTreeShapeDataInArray(HierarchyRows, ProductsArray)
	
	For Each HierarchyLine In HierarchyRows Do
		If ValueIsFilled(HierarchyLine.Products)
			And ProductsArray.Find(HierarchyLine.Products) = Undefined Then
			ProductsArray.Add(HierarchyLine.Products);
		EndIf;
		NomenclatureTreeShapeDataInArray(HierarchyLine.GetItems(), ProductsArray);
	EndDo;
	
EndProcedure

Procedure NomenclatureOfTreeInArray(HierarchyRows, ProductsArray)
	
	For Each HierarchyLine In HierarchyRows Do
		If ValueIsFilled(HierarchyLine.Products)
			And ProductsArray.Find(HierarchyLine.Products) = Undefined Then
			ProductsArray.Add(HierarchyLine.Products);
		EndIf;
		NomenclatureOfTreeInArray(HierarchyLine.Rows, ProductsArray);
	EndDo;
	
EndProcedure

// Adds columns to the nomenclature table for VAT rates by price type, with the option "Specify VAT rates line by line".
//
// Parameters:
//   Form - See BuildPriceTree.Form
//   ProductsTable - ValueTable - to which the VAT rates columns are added.
//   ArrayOfPriceTypes - Array of CatalogRef.TypesOfPrices - types of prices to process.
//   If not specified, it is filled in with the selected prices available for editing from the form "Selected prices".
Procedure FillInNDSBidInItemTable(Form, ProductsTable, ArrayOfPriceTypes = Undefined) Export
	
	If Not Form.UsePriceManagementSystem25 Then
		Return;
	EndIf;
	
	If ArrayOfPriceTypes = Undefined Then
		
		ArrayOfPriceTypes = New Array();
		For Each PriceTypeLine In Form.SelectedPrices Do
			If PriceTypeLine.Selected_5 
				And PriceTypeLine.Edit
				And (PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseData
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataOnReceipt
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnPurchasingPrice
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.MarkupOnOBEntryPrice
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByCompetitors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillInByInfobaseDataByVendors 
					Or PriceTypeLine.PricingMethod = Enums.PriceSettingMethods.FillByInfobaseDataByCost) Then
				ArrayOfPriceTypes.Add(PriceTypeLine);
			EndIf;
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(ArrayOfPriceTypes) Then
		Return;
	EndIf;
		
	For Each PriceKind In ArrayOfPriceTypes Do
			
		If ValueIsFilled(PriceKind["ColumnName"])
			And PriceKind.OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine Then
			
			ColumnName = "VATRate" + PriceKind["ColumnName"];
			ProductsTable.Columns.Add(ColumnName, New TypeDescription("CatalogRef.VATRates"));
		
			PriceTreeIsDataTreeOfForm = (TypeOf(Form.PriceTree) = Type("FormDataTree"));
			If PriceTreeIsDataTreeOfForm Then
				FillInVATRateTreeFormDataInItemTable(Form.PriceTree.GetItems(), ProductsTable, ColumnName);
			EndIf;
		
		EndIf;
			
	EndDo;
	
EndProcedure

// The procedure recursively fills the VAT rate in the item table with data from a hierarchical structure (tree).
//
// Parameters:
//   HierarchyRows - FormDataTree - Tree rows containing VAT rates and item Attributes
//   ProductsTable - FormTable - The table of the nomenclature form in which the VAT rate is recorded
//   ColumnName - String - The name of the column in the source and receiver that contains the VAT rate
Procedure FillInVATRateTreeFormDataInItemTable(HierarchyRows, ProductsTable, ColumnName)
	
	For Each HierarchyLine In HierarchyRows Do
		
		VATRate = HierarchyLine[ColumnName];
		If ValueIsFilled(VATRate) And ValueIsFilled(HierarchyLine.Products) Then
			
			SearchParameters = New Structure;
			SearchParameters.Insert("Products", HierarchyLine.Products);
			SearchParameters.Insert("PricingVariant", HierarchyLine.PricingVariant);
			SearchParameters.Insert("PricingBatch", HierarchyLine.PricingBatch);
			SearchParameters.Insert("PricingPackage", HierarchyLine.PricingPackage);
			
			ArrayOfFound = ProductsTable.FindRows(SearchParameters);
			If ValueIsFilled(ArrayOfFound) Then
				ArrayOfFound[0][ColumnName] = VATRate;
			EndIf;
			
		EndIf;
		
		FillInVATRateTreeFormDataInItemTable(HierarchyLine.GetItems(), ProductsTable, ColumnName);
		
	EndDo;
	
EndProcedure

// Places data from the Item Table into the temporary table of the temporary table manager
// and configures usage parameters.
//
// Parameters:
//   TempTablesManager - TempTablesManager - manager of temporary tables for data placement
//   Parameter - Structure - structure with usage parameters (keys "Value" and "Usage")
//   ProductsTable - ValueTable - table of values with data from the document "Item price settings"
//   PriceTypeLine - ValueTableRow - processed price type string
Procedure PutTableDataInTemporaryTableManager(TempTablesManager, Parameter, ProductsTable, PriceTypeLine)
	
	If Not ValueIsFilled(PriceTypeLine["ColumnName"])
		Or PriceTypeLine.OptionForSpecifyingVATRates <> Enums.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine Then
					
		PlaceEmptyTableInTemporaryTableManager(TempTablesManager);
		
		Return;
	EndIf;
	
	Parameter.Value = True;
	Parameter.Use = True;

	TempTablesManager = New TempTablesManager();
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	VATRateTable.Products AS Products,
	|	VATRateTable.PricingVariant AS PricingVariant,
	|	VATRateTable.TSOSeriesForCommunication AS PricingBatch,
	|	VATRateTable.TsoPackagingForCommunication AS PricingPackage,
	|	VATRateTable.VATRate AS VATRate
	|INTO ItemPriceSettingDataTable
	|FROM
	|	&TableOfItemVATRate AS VATRateTable
	|";
	
	ColumnName = "VATRate" + PriceTypeLine["ColumnName"];
	TableOfItemVATRate = ProductsTable.Copy(, "Products, PricingVariant, TSOSeriesForCommunication, TsoPackagingForCommunication, " + ColumnName);
	TableOfItemVATRate.Columns[ColumnName].Name = "VATRate";
	
	Query.SetParameter("TableOfItemVATRate", TableOfItemVATRate);
	Query.Execute();
	
EndProcedure

// Places empty data in the temporary table "tableadannyhestablishment of value nomenclature" of the temporary table manager.
//
// Parameters:
//   TempTablesManager - TempTablesManager - manager of temporary tables for data placement
Procedure PlaceEmptyTableInTemporaryTableManager(TempTablesManager)

	TempTablesManager = New TempTablesManager();
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef) AS PricingVariant,
	|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate
	|INTO ItemPriceSettingDataTable
	|";

	Query.Execute();

EndProcedure

#EndRegion

#EndRegion
