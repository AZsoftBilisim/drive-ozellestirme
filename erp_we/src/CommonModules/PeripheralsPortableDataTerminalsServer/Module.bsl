
#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
//
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	
EndProcedure

// Prepare the operation data.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection setting
//  Command - String - Command
//  OperationParametersList - Structure - Operation parameters
// 
// Returns:
//  Structure - Prepare Operation Data:
// * Result - Boolean -
// * XMLPackages - Array of XMLReader
// * FullUpload - Boolean
// * ErrorText - String
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	If Command = "UploadDirectory" Then
		If OperationParametersList.TableOfGoods.Count() = 0 Then
			ErrorText = NStr("vi = 'Không có dữ liệu để kết xuất.';
							|ru = 'Нет данных для выгрузки.';
							|en = 'No data for export.'; fa = 'No data for export.';
							|it = 'Non ci sono dati da scaricare.';
							|pl = 'Brak danych do wysłania.';
							|tr = 'Dışa aktarılacak veri yok.'");
			OperationData = New Structure();
			OperationData.Insert("Result"  , False);
			OperationData.Insert("ErrorText", ErrorText);
			Return OperationData;
		EndIf;
		FullUpload = Not OperationParametersList.PartialUnloading; 
		PackagesForUnloading = PreparePackagesForDownloadingTSD(OperationParametersList.TableOfGoods, DefaultPacketSize(), FullUpload);
		OperationData = ParametersOfTSDOperation();
		OperationData.XMLPackages = PackagesForUnloading;
		OperationData.FullUpload = FullUpload;
		Return OperationData;
	EndIf;
	
EndFunction

// Process the operation data.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - Team.
//  ExecutionResult - Boolean - The result of the execution.
//  OperationData - Structure - Operation data.
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
	If Command = "DownloadDocument" Then
		AlcoholContainingProducts = False;    
		ProcessingResult = TSDProducts(OperationData.DownloadData, AlcoholContainingProducts);    
		If ProcessingResult.Result Then
			ExecutionResult.Insert("TableOfGoods", ProcessingResult.TableOfGoods);
			ExecutionResult.Insert("AlcoholContainingProducts", AlcoholContainingProducts);
		Else
			ExecutionResult.ErrorDescription = ProcessingResult.ErrorText;
		EndIf;
		ExecutionResult.Result = ProcessingResult.Result;
	EndIf;   
	
EndProcedure

#EndRegion

#Region Private          

// Fill in the structure of the TSD operation
//
// Returns:
//  Structure
Function ParametersOfTSDOperation(Result = True)
	
	OperationParametersList = New Structure();
	OperationParametersList.Insert("Result", Result);
	OperationParametersList.Insert("XMLPackages");
	OperationParametersList.Insert("FullUpload");
	OperationParametersList.Insert("ErrorText");
	Return OperationParametersList;
	
EndFunction 

// The size of the packet in the elements of information transmitted to the driver.
//
// Returns:
//  Number
Function DefaultPacketSize()
	
	PackageSize = 200;
	Return PackageSize;
	
EndFunction

// Get a table of products from the XML structure for the TSD.
// 
// Parameters:
//  DownloadData - String - Download data
//  AlcoholContainingProducts - Boolean - Alcoholic beverages
// 
// Returns:
//  Array - TSD products     
//
Function TSDProducts(DownloadData, AlcoholContainingProducts)
	
	ExecutionResult = ParametersOfTSDOperation(False);
	ExecutionResult.Insert("TableOfGoods", New Array());
	
	AlcoholContainingProducts = False;
	
	If Not IsBlankString(DownloadData) Then
		
		XMLReader = New XMLReader; 
		XMLReader.SetString(DownloadData); 
		Try
			XMLReader.MoveToContent();
		Except   
			ExecutionResult.ErrorText = NStr("vi = 'Dữ liệu được kết nhập từ thiết bị thu thập dữ liệu có định dạng không hợp lệ.';
											|ru = 'Загружаемые данные из ТСД имеют неверный формат.';
											|en = 'Data to import from the PDT has an incorrect format.'; fa = 'Data to import from the PDT has an incorrect format.';
											|it = 'Загружаемые данные из ТСД имеют неверный формат.';
											|pl = 'Data to import from the PDT has an incorrect format.';
											|tr = 'Veri Toplama Cihazı''ndan indirilen veriler yanlış formata sahip.'"); 
			Return ExecutionResult;
		EndTry;
		
		If XMLReader.Name = "Table" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			While XMLReader.Read() Do  
				If XMLReader.Name = "Record" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					DataPosition = New Structure();
					
					Barcode = XMLReader.AttributeValue("BarCode");
					BarcodeBASE64 = XMLReader.AttributeValue("BarCodeBase64");    
					If IsBlankString(BarcodeBASE64) Then
						BarcodeBASE64 = XMLReader.AttributeValue("BarcodeBase64");    
					EndIf;
					PackageBarcode = XMLReader.AttributeValue("ContainerBarCode");
					PackingBarcodeBase64 = XMLReader.AttributeValue("ContainerBarCodeBase64");
					If IsBlankString(PackingBarcodeBase64) Then
						PackingBarcodeBase64 = XMLReader.AttributeValue("ContainerBarcodeBase64");    
					EndIf;
					
					If Not IsBlankString(BarcodeBASE64) Then
						Barcode = EquipmentManagerClientServer.Base64BBarcode(BarcodeBASE64);   
						If CommonCEL.MarkingIsUsed() Then
							ModuleEquipmentManagerMarkingClientServer = CommonCEL.CommonModule("EquipmentManagerMarkingClientServer");
							If StrFind(Barcode, CommonCELClientServer.GS1Separator()) > 0 Then
								ProductBarCode_ = ModuleEquipmentManagerMarkingClientServer.DisassembleBarCodeOfProductService(Barcode);
								If ProductBarCode_.Disassembled_ Then
									Barcode = ProductBarCode_.BarcodePresentation;    
								Else
									Barcode = StrReplace(Barcode, CommonCELClientServer.GS1Separator(), ""); 
								EndIf;
							EndIf;
						Else
							If StrFind(Barcode, CommonCELClientServer.GS1Separator()) > 0 Then
								Barcode = StrReplace(Barcode, CommonCELClientServer.GS1Separator(), ""); 
							EndIf;
						EndIf;
					Else
						BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(Barcode);
					EndIf;           
					
					If Not IsBlankString(PackingBarcodeBase64) Then
						PackageBarcode = EquipmentManagerClientServer.Base64BBarcode(PackingBarcodeBase64);      
						If CommonCEL.MarkingIsUsed() Then
							If StrFind(PackageBarcode, CommonCELClientServer.GS1Separator()) > 0 Then
								ProductBarCode_ = ModuleEquipmentManagerMarkingClientServer.DisassembleBarCodeOfProductService(Barcode);
								If ProductBarCode_.Disassembled_ Then
									PackageBarcode = ProductBarCode_.BarcodePresentation;   
								Else
									PackageBarcode = StrReplace(PackageBarcode, CommonCELClientServer.GS1Separator(), ""); 
								EndIf;
							EndIf;
						Else
							If StrFind(PackageBarcode, CommonCELClientServer.GS1Separator()) > 0 Then
								PackageBarcode = StrReplace(PackageBarcode, CommonCELClientServer.GS1Separator(), ""); 
							EndIf;
						EndIf;
					Else            
						If Not IsBlankString(PackageBarcode) Then
							PackingBarcodeBase64 = EquipmentManagerClientServer.Base64BBarcode(PackageBarcode);      
						EndIf;
					EndIf;
					
					DataPosition.Insert("Count", XMLReader.AttributeValue("Quantity"));
					DataPosition.Insert("Barcode"  , Barcode);
					DataPosition.Insert("BarcodeBASE64", BarcodeBASE64);
					DataPosition.Insert("PackageBarcode", PackageBarcode);
					DataPosition.Insert("PackingBarcodeBase64", PackingBarcodeBase64);
					
					// Attributes to support integration with USAIS.
					BarcodeBrandOfAlcoholicBeverages = XMLReader.AttributeValue("AlcoholExciseStamp");
					If Not IsBlankString(BarcodeBrandOfAlcoholicBeverages) Then
						AlcoholContainingProducts = True;
					EndIf;
						
					DataPosition.Insert("BarcodeBrandOfAlcoholicBeverages", BarcodeBrandOfAlcoholicBeverages);
					DataPosition.Insert("NameOfAlcoholicProducts" , XMLReader.AttributeValue("AlcoholName"));
					DataPosition.Insert("SerialNumberOfAlcoholicBeverages", XMLReader.AttributeValue("AlcoholSerialNumber"));
					DataPosition.Insert("CodeOfTypeOfAlcoholicProducts", XMLReader.AttributeValue("AlcoholKindCode"));
					DataPosition.Insert("CodeOfAlcoholicProducts"    , XMLReader.AttributeValue("AlcoholCode"));
					DataPosition.Insert("ContainerCapacity"                , XMLReader.AttributeValue("AlcoholContainerSize"));
					DataPosition.Insert("Strength"                   , XMLReader.AttributeValue("AlcoholStrength"));
					DataPosition.Insert("ManufacturerSTin"           , XMLReader.AttributeValue("VendorINNCode"));
					DataPosition.Insert("ManufacturerSCheckpoint"           , XMLReader.AttributeValue("VendorKPPCode"));
					ExecutionResult.TableOfGoods.Add(DataPosition);   
				EndIf;
			EndDo;  
			ExecutionResult.Result = True;
		EndIf; 
		
		If ExecutionResult.TableOfGoods.Count() = 0 Then
			ExecutionResult.Result = False;
			ExecutionResult.ErrorText = NStr("vi = 'Không có mặt hàng để kết nhập từ thiết bị thu thập dữ liệu.';
											|ru = 'Нет товарных позиций для загрузки из ТСД.';
											|en = 'No items to import from the PDT.'; fa = 'No items to import from the PDT.';
											|it = 'Нет товарных позиций для загрузки из ТСД.';
											|pl = 'No items to import from the PDT.';
											|tr = 'Veri Toplama Cihazı''ndan yüklenenler için ürün konumları mevcut değil.'");
		EndIf;                  
	Else
		ExecutionResult.ErrorText = NStr("vi = 'Không có dữ liệu để kết nhập từ thiết bị thu thập dữ liệu.';
										|ru = 'Нет данных для загрузки из ТСД.';
										|en = 'No data to import from the PDT.'; fa = 'No data to import from the PDT.';
										|it = 'Нет данных для загрузки из ТСД.';
										|pl = 'No data to import from the PDT.';
										|tr = 'Veri Toplama Cihazı''ndan yüklenenler için veriler mevcut değil'");
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// Create a table of products in the XML structure for the TSD.
//
// Parameters:
//   DownloadData - Array of Structure
//   FullUpload - Boolean 
//   InterfaceRevision - Number
//
// Returns:
//  XMLWriter
Function CreateTableOfTSDProducts(DownloadData, FullUpload, InterfaceRevision = 0) 
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("Table");
	XMLWriter.WriteAttribute("FullLoad", XMLString(FullUpload));
	
	For Each Position In DownloadData  Do
		
		ItemName = "";
		If Position.Property("Products") Then
			ItemName = String(Position.Products);
		EndIf;
		If IsBlankString(ItemName) And Position.Property("Description") Then
			ItemName = Position.Description;
		EndIf;
		
		XMLWriter.WriteStartElement("Record");
		If InterfaceRevision >= 3003 Then
			
			If Position.Property("BarcodeBASE64") And Not IsBlankString(Position.BarcodeBASE64) Then
				BarcodeBASE64 = Position.BarcodeBASE64
			Else
				BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(Position.Barcode)
			EndIf;
			XMLWriter.WriteAttribute("BarCodeBase64" , XMLString(BarcodeBASE64));
			
			If Position.Property("PackingBarcodeBase64") And Not IsBlankString(Position.PackingBarcodeBase64) Then
				PackingBarcodeBase64 = Position.PackingBarcodeBase64
			ElsIf Position.Property("PackageBarcode") And Not IsBlankString(Position.PackageBarcode) Then
				PackingBarcodeBase64 = EquipmentManagerClientServer.BarcodeInBase64(Position.PackageBarcode);
			EndIf;
			If Not IsBlankString(PackingBarcodeBase64) Then 
			XMLWriter.WriteAttribute("ContainerBarcodeBase64", XMLString(PackingBarcodeBase64));
			EndIf; 
			
		Else
			XMLWriter.WriteAttribute("BarCode"         , XMLString(?(Position.Property("Barcode"), Position.Barcode, "")));
			If Position.Property("PackageBarcode") And Not IsBlankString(Position.PackageBarcode) Then
				XMLWriter.WriteAttribute("ContainerBarcode", XMLString(Position.Property("PackageBarcode")));
			EndIf;
		EndIf;
		XMLWriter.WriteAttribute("Name" , XMLString(ItemName));
		XMLWriter.WriteAttribute("UnitOfMeasurement"            , XMLString(?(Position.Property("UnitOfMeasure"), Position.UnitOfMeasure, "")));
		XMLWriter.WriteAttribute("CharacteristicOfNomenclature" , XMLString(?(Position.Property("ProductCharacteristic"), Position.ProductCharacteristic, "")));
		XMLWriter.WriteAttribute("SeriesOfNomenclature"         , XMLString(?(Position.Property("ProductSeries"), Position.ProductSeries, "")));
		XMLWriter.WriteAttribute("Quality"                      , XMLString(?(Position.Property("Quality")  , Position.Quality, "")));
		XMLWriter.WriteAttribute("Price"                        , XMLString(?(Position.Property("Price")      , Position.Price, 0)));
		XMLWriter.WriteAttribute("Quantity"                     , XMLString(?(Position.Property("Count"), Position.Count, 0)));
		XMLWriter.WriteAttribute("Article"                      , XMLString(?(Position.Property("SKU")   , Position.SKU, "")));
		Alcohol = ?(Position.Property("Alcohol"), Position.Alcohol, False);
		XMLWriter.WriteAttribute("Alcohol", XMLString(Alcohol));
		If Alcohol = True Then
			XMLWriter.WriteAttribute("AlcoholExcisable"     , XMLString(?(Position.Property("Labelled")                , Position.Labelled, False)));
			XMLWriter.WriteAttribute("AlcoholKindCode"      , XMLString(?(Position.Property("CodeOfTypeOfAlcoholicProducts"), Position.CodeOfTypeOfAlcoholicProducts, "")));
			XMLWriter.WriteAttribute("AlcoholCode"          , XMLString(?(Position.Property("CodeOfAlcoholicProducts")    , Position.CodeOfAlcoholicProducts, "")));
			XMLWriter.WriteAttribute("AlcoholContainerSize" , XMLString(?(Position.Property("ContainerCapacity")                , Position.ContainerCapacity, Undefined)));
			XMLWriter.WriteAttribute("AlcoholStrength"      , XMLString(?(Position.Property("Strength")                   , Position.Strength, Undefined)));
			XMLWriter.WriteAttribute("VendorINNCode"        , XMLString(?(Position.Property("ManufacturerSTin")           , Position.ManufacturerSTin, Undefined)));
			XMLWriter.WriteAttribute("VendorKPPCode"        , XMLString(?(Position.Property("ManufacturerSCheckpoint")           , Position.ManufacturerSCheckpoint, Undefined)));
			If InterfaceRevision >= 3003 Then
				If Position.Property("BarcodeBrandOfAlcoholicBeveragesBase64") And Not IsBlankString(Position.BarcodeBrandOfAlcoholicBeveragesBase64) Then
					BarcodeBrandOfAlcoholicBeveragesBase64 = Position.BarcodeBrandOfAlcoholicBeveragesBase64
				Else
					BarcodeBrandOfAlcoholicBeveragesBase64 = EquipmentManagerClientServer.BarcodeInBase64(Position.BarcodeBrandOfAlcoholicBeverages)
				EndIf;
				XMLWriter.WriteAttribute("AlcoholExciseStampBase64", XMLString(BarcodeBrandOfAlcoholicBeveragesBase64));
			Else
				XMLWriter.WriteAttribute("AlcoholExciseStamp", XMLString(?(Position.Property("BarcodeBrandOfAlcoholicBeverages") , Position.BarcodeBrandOfAlcoholicBeverages, Undefined)));
			EndIf;
		EndIf;
		
		XMLWriter.WriteEndElement();
	EndDo;
	XMLWriter.WriteEndElement();
	
	Return XMLWriter.Close();
	
EndFunction

// Generate XML product packages for uploading the TSD.
//
// Returns:
//  Array
Function PreparePackagesForDownloadingTSD(ExportedTable, PackageSize, FullUpload) 
	
	PackagesForUnloading = New Array();
	ArrayOfProducts_2 = New Array;
	
	WritingInPackage    = 0;
	RecordsUnloaded = 0;
	TotalRecords_     = ExportedTable.Count();
	
	For Each Position In ExportedTable  Do
		
		If WritingInPackage = 0 Then
		    ArrayOfProducts_2.Clear();
		EndIf;
		ArrayOfProducts_2.Add(Position);
		
		RecordsUnloaded  = RecordsUnloaded + 1;
		WritingInPackage = WritingInPackage + 1;
		
		If (WritingInPackage = PackageSize) Or (RecordsUnloaded = TotalRecords_) Then  
			DataToUpload = CreateTableOfTSDProducts(ArrayOfProducts_2, FullUpload);
			PackagesForUnloading.Add(DataToUpload);
			WritingInPackage = 0;
		EndIf;
		
	EndDo;
	
	Return PackagesForUnloading;
	
EndFunction

#EndRegion
