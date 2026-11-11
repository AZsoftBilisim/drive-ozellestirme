
#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
// 
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	Driver = DriversOfHardware.Add();
	Driver.EquipmentType = Enums.PeripheralTypes.DigitalRetailScales;
	Driver.NameOfDriver  = "Driver1CElectronicScales";
	Driver.Description = NStr("vi = '1C:Cân điện tử (Native Api)';
								|ru = '1С:Электронные весы (Native Api)';
								|en = '1C:Electronic Scales (NativeApi)'; fa = '1C:Electronic Scales (NativeApi)';
								|it = '1C:Bilancia elettronica (Nativ Api)';
								|pl = '1C:Waga elektroniczna (Native Api)';
								|tr = '1C:Electronic Scales (NativeApi)'", CommonCEL.DefaultLanguageCode());
	Driver.ObjectID = "CheckoutScales"; 
	Driver.RecommendedUse = True;
	
	// ++ Non-mobile application
	// -- Non-mobile application     
	
EndProcedure

// Prepare the operation data before executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - executed command.
//  OperationParametersList - Structure - The operation parameters.
// 
// Returns:
//  Structure
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	If Command = "UploadGoods" Then
		
		If OperationParametersList.TableOfGoods.Count() = 0 Then
			ErrorDescription = NStr("vi = 'Không có dữ liệu để kết xuất.';
									|ru = 'Нет данных для выгрузки.';
									|en = 'No data for export.'; fa = 'No data for export.';
									|it = 'Non ci sono dati da scaricare.';
									|pl = 'Brak danych do wysłania.';
									|tr = 'Dışa aktarılacak veri yok.'");
			OperationData = New Structure();
			OperationData.Insert("Result"  , False);
			OperationData.Insert("ErrorText", ErrorDescription);
			Return OperationData;
		EndIf;
		FullUpload = Not OperationParametersList.PartialUnloading; 
		PackagesForUnloading = PreparePackagesForLoadingIntoScalesWithLabelPrinting(OperationParametersList.TableOfGoods, DefaultPacketSize(), ConnectionParameters.InterfaceRevision);
		OperationData = OperationParametersScales();
		OperationData.XMLPackages = PackagesForUnloading;
		OperationData.FullUpload = FullUpload;
		Return OperationData;
		
	ElsIf Command = "UploadProductImages" Then
		
		If OperationParametersList.TableOfImages.Count() = 0 Then
			ErrorDescription = NStr("vi = 'Không có dữ liệu để kết xuất.';
									|ru = 'Нет данных для выгрузки.';
									|en = 'No data for export.'; fa = 'No data for export.';
									|it = 'Non ci sono dati da scaricare.';
									|pl = 'Brak danych do wysłania.';
									|tr = 'Dışa aktarılacak veri yok.'");
			OperationData = New Structure();
			OperationData.Insert("Result"  , False);
			OperationData.Insert("ErrorText", ErrorDescription);
			Return OperationData;
		EndIf;
		PackagesForUnloading = PreparePackagesForUploadingImagesToScalesWithLabelPrinting(OperationParametersList.TableOfImages, DefaultPacketSize(), ConnectionParameters.InterfaceRevision);
		OperationData = OperationParametersScales();
		OperationData.XMLPackages = PackagesForUnloading;
		Return OperationData;
		
	EndIf      
	
EndFunction

// Process the operation data after executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - Connection parameters.
//  Command - String - executed command.
//  ExecutionResult - Structure - the result of the operation.
//  OperationData - Structure - The operation parameters.
// 
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
EndProcedure

#EndRegion

#Region Private   

// Fill in the operation structure
// 
// Returns:
//  Structure - Operation Parameters Scales:
// * Result - Boolean
// * XMLPackages - Array of XMLReader
// * FullUpload - Boolean
// * ErrorText - String
Function OperationParametersScales()
	
	OperationParametersList = New Structure();
	OperationParametersList.Insert("Result", True);
	OperationParametersList.Insert("XMLPackages");
	OperationParametersList.Insert("FullUpload");
	OperationParametersList.Insert("ErrorText");
	Return OperationParametersList;
	
EndFunction 

// The size of the packet in the elements of information transmitted to the driver.
//
// Returns:
//  Number
//
Function DefaultPacketSize()
	
	PackageSize = 10;
	Return PackageSize;
	
EndFunction

// Create a table of products in the XML structure for scales with label printing.
// 
// Parameters:
//  DownloadData - Array - Download data.           
//  InterfaceRevision - Number - Interface revision.
// 
// Returns:
//  XMLWriter - Create a table of products scales with label printing
Function GenerateTableOfGoodsScalesWithLabelPrinting(DownloadData, InterfaceRevision = 0) 
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("Table");
	For Each Position In DownloadData  Do
		XMLWriter.WriteStartElement("Record");   
		
		TimeName = ?(Position.Property("Description"), Position.Description, "");
		If Position.Property("DescriptionFull") And Not IsBlankString(Position.DescriptionFull) Then
			TimeName = Position.DescriptionFull;
		EndIf;
		
		Price = ?(Position.Property("Price"), Position.Price, 0);                       
		ProductDescription_3 = ?(Position.Property("ProductDescription_3"), Position.ProductDescription_3, Undefined);  
		ShelfLife   = ?(Position.Property("ShelfLife")  , Position.ShelfLife, Undefined);       
		GoodsSoldByWeight   = ?(Position.Property("GoodsSoldByWeight")  , Position.GoodsSoldByWeight, False);     
		
		XMLWriter.WriteAttribute("PLU"  , XMLString(Number(Position.PLU)));
		XMLWriter.WriteAttribute("Code" , XMLString(Number(Position.Code)));
		XMLWriter.WriteAttribute("Name" , XMLString(TimeName));
		XMLWriter.WriteAttribute("Price", XMLString(Price));
		If Not IsBlankString(ProductDescription_3) Then 
			XMLWriter.WriteAttribute("Description", XMLString(ProductDescription_3));  
		EndIf;  	
		If Not IsBlankString(ShelfLife) Then 
			XMLWriter.WriteAttribute("ShelfLife", XMLString(ShelfLife));  
		EndIf;  	
		XMLWriter.WriteAttribute("IsWeightGoods", XMLString(GoodsSoldByWeight));     
		
		If InterfaceRevision > 3007 Then // Standard version 3.8 and above // 
			
			If InterfaceRevision > 4005 And Not GoodsSoldByWeight Then      
				If Not IsBlankString(Position.UnitWeightOfPieceGoods) And Position.UnitWeightOfPieceGoods > 0 Then 
					XMLWriter.WriteAttribute("WeightPieceOfGoods", XMLString(Number(Position.UnitWeightOfPieceGoods)));    
				EndIf;
			EndIf;
			
			LabelFormat = ?(Position.Property("LabelFormat"), Position.LabelFormat, Undefined);     
			ButtonProduct   = ?(Position.Property("ButtonProduct"), Position.ButtonProduct, Undefined);
			If Not IsBlankString(LabelFormat) Then 
				XMLWriter.WriteAttribute("LabelFormat", XMLString(LabelFormat));     
			EndIf;
			If Not IsBlankString(ButtonProduct) Then 
				XMLWriter.WriteAttribute("ButtonNumber", XMLString(ButtonProduct));     
			EndIf;                                                                  
			
			If Position.Property("AdditionalPrices") Then      
				AdditionalPrices = Position.AdditionalPrices;
				Price1 = ?(AdditionalPrices.Property("Price1"), AdditionalPrices.Price1, 0);                      
				Price2 = ?(AdditionalPrices.Property("Price2"), AdditionalPrices.Price2, 0);                      
				Price3 = ?(AdditionalPrices.Property("Price3"), AdditionalPrices.Price3, 0);                      
				Price4 = ?(AdditionalPrices.Property("Price4"), AdditionalPrices.Price4, 0);                      
				XMLWriter.WriteStartElement("AdditionalPrices");     
				XMLWriter.WriteAttribute("Price1", XMLString(Price1));     
				XMLWriter.WriteAttribute("Price2", XMLString(Price2));     
				XMLWriter.WriteAttribute("Price3", XMLString(Price3));     
				XMLWriter.WriteAttribute("Price4", XMLString(Price4));     
				XMLWriter.WriteEndElement();
			EndIf;     
			
		EndIf;
		
		XMLWriter.WriteEndElement();
	EndDo;
	XMLWriter.WriteEndElement();
		
	Return XMLWriter.Close();
	
EndFunction

// Create a table of images in an XML structure for scales with label printing.
// 
// Parameters:
//  DownloadData - Array - Download data.           
//  InterfaceRevision - Number - Interface revision.
// 
// Returns:
//  XMLWriter - Create a table of products scales with label printing  
//
Function CreateTableOfImagesOfScalesWithLabelPrinting(DownloadData, InterfaceRevision = 0) 
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("Table");
	For Each Position In DownloadData  Do
		XMLWriter.WriteStartElement("Record");   
		XMLWriter.WriteAttribute("PLU"     , XMLString(Number(Position.PLU)));
		XMLWriter.WriteAttribute("Code"    , XMLString(Number(Position.Code)));
		XMLWriter.WriteAttribute("Picture" , XMLString(Position.Image));
		XMLWriter.WriteEndElement();
	EndDo;
	XMLWriter.WriteEndElement();
		
	Return XMLWriter.Close();
	
EndFunction

// Generate XML packages for uploading to scales with label printing.   
// 
// Parameters:
//  ExportedTable - Array - Data to upload.   
//  PackageSize - Number - Package size.
//  InterfaceRevision - Number - Interface revision.
//
// Returns:
//  Array of See GenerateTableOfGoodsScalesWithLabelPrinting
//
Function PreparePackagesForLoadingIntoScalesWithLabelPrinting(ExportedTable, PackageSize, InterfaceRevision = 0) 
	
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
			DataToUpload = GenerateTableOfGoodsScalesWithLabelPrinting(ArrayOfProducts_2, InterfaceRevision);
			PackagesForUnloading.Add(DataToUpload);
			WritingInPackage = 0;
		EndIf;
		
	EndDo;
	
	Return PackagesForUnloading;
	
EndFunction

// Generate XML packages for uploading images to scales with label printing.
// 
// Parameters:
//  TableOfImages - Array of Structure - Data to upload.
//  PackageSize - Number
//  InterfaceRevision - Number
// 
// Returns:
//  Array of See CreateTableOfImagesOfScalesWithLabelPrinting - 
//     packages for uploading images to scales with label printing
//
Function PreparePackagesForUploadingImagesToScalesWithLabelPrinting(TableOfImages, PackageSize, InterfaceRevision = 0) 
	
	PackagesForUnloading = New Array();
	ArrayOfImages = New Array;
	
	WritingInPackage    = 0;
	RecordsUnloaded = 0;
	TotalRecords_     = TableOfImages.Count();
	
	For Each Position In TableOfImages Do
		
		If WritingInPackage = 0 Then
		    ArrayOfImages.Clear();
		EndIf;
		ArrayOfImages.Add(Position);
		RecordsUnloaded  = RecordsUnloaded + 1;
		WritingInPackage = WritingInPackage + 1;
		
		If (WritingInPackage = PackageSize) Or (RecordsUnloaded = TotalRecords_) Then  
			DataToUpload = CreateTableOfImagesOfScalesWithLabelPrinting(ArrayOfImages, InterfaceRevision);
			PackagesForUnloading.Add(DataToUpload);
			WritingInPackage = 0;
		EndIf;
		
	EndDo;
	
	Return PackagesForUnloading;
	
EndFunction

#EndRegion