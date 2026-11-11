////////////////////////////////////////////////////////////////////////////////
// Client procedures for working with nomenclature and related reference books
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates the name of the reference list element based on the template specified for the item type.
//
// Parameters:
//		DataForNameFormation - Structure - the structure returned by the function Nomenclaturally.Naming formulae
//		ProductKind - CatalogRef.ItemKinds	- type of item where the name template is set
//		MeaningOfName - String - the full name formula may include the name. The name may not
//								be filled in at the time of forming the data array for forming the Name.Array of requisit values,
//								so you need to update the name value before calculating the full name.
// Returns:
// String - The name obtained by the calculation algorithm
// Empty string - if the name could not be formed or the operands of the algorithm are not filled in.
//
Function NameByFormula(DataForNameFormation, ProductKind, MeaningOfName = "") Export
	
	Description = "";
	If ValueIsFilled(DataForNameFormation.NamingFormula) Then
		
		ArrayOfPropsValues = DataForNameFormation.ArrayOfPropsValues;
		
		For Each IndexOf In DataForNameFormation.IndexesOfNameInArrayOfPropsValues Do
			ArrayOfPropsValues[IndexOf] = MeaningOfName;
		EndDo;
		
		Try
			
			Execute("Description = """" + " + DataForNameFormation.NamingFormula);
			
		Except
			
			ErrorMessageTemplate = NStr("vi = 'Không thể tính tên gọi theo khuôn mẫu đã đưa ra đối với dạng mặt hàng ""%ProductKind%"". Hãy kiểm tra độ chính xác của khuôn mẫu.';
										|ru = 'Невозможно рассчитать наименование по заданному для вида номенклатуры ""%ProductKind%"" шаблону. Проверьте правильность шаблона.';
										|en = 'Cannot calculate a name according to template ""%ProductKind%"" specified for the item kind. Check whether the template is correct.'; fa = 'Cannot calculate a name according to template ""%ProductKind%"" specified for the item kind. Check whether the template is correct.';
										|it = 'Non è possibile calcolare il nome per il modello specificato per la vista articolo ""%ProductKind%"". Verificare che il modello sia corretto.';
										|pl = 'Niemożliwe jest rozliczenie nazwy wg zadanego dla rodzaju nomenklatury ""%ProductKind%"" szablonu. Sprawdź poprawność szablonu.';
										|tr = '""%ProductKind%"" öğe türü için belirtilen numuneye göre öğenin hesaplanması mümkün değildir. Numunenin doğru olup olmadığını kontrol et.'");
			
			ErrorMessage = StrReplace(ErrorMessageTemplate, "%ProductKind%", ProductKind);
			Raise ErrorMessage;
			
		EndTry;
		
	EndIf;
	
	Return Description;
	
EndFunction

// Returns the filter used for selecting image files.
// Returns:
// String - a string containing a filter for image files.
//
Function FilterImageFiles() Export
	
	AllPictures		= NStr("vi = 'Tất cả hình ảnh (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
								|ru = 'Все картинки (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
								|en = 'All images (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf'; fa = 'All images (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
								|it = 'Tutte le immagini (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
								|pl = 'Wszystkie obrazki (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
								|tr = 'Tüm resimler (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf'");
	AllFiles		= NStr("vi = 'Tất cả tệp(*.*)|*.*';
							|ru = 'Все файлы(*.*)|*.*';
							|en = 'All files(*.*)|*.*'; fa = 'All files(*.*)|*.*';
							|it = 'Tutti i file(*.*)|*.*';
							|pl = 'Wszystkie pliki(*.*)|*.*';
							|tr = 'Tüm dosyalar (*. *) | *. *'");
	BMPFormat		= NStr("vi = 'Định dạng bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle';
							|ru = 'Формат bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle';
							|en = 'Format bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle'; fa = 'Format bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle';
							|it = 'Formato bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle';
							|pl = 'Format bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle';
							|tr = 'Format bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle'");
	GIFFormat		= NStr("vi = 'Định dạng GIF(*.gif*)|*.gif';
							|ru = 'Формат GIF(*.gif*)|*.gif';
							|en = 'Format GIF(*.gif*)|*.gif'; fa = 'Format GIF(*.gif*)|*.gif';
							|it = 'Formato GIF(*.gif*)|*.gif';
							|pl = 'Format GIF(*.gif*)|*.gif';
							|tr = 'Format GIF(*.gif*)|*.gif'");
	JPEGFormat		= NStr("vi = 'Định dạng JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg';
							|ru = 'Формат JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg';
							|en = 'Format JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg'; fa = 'Format JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg';
							|it = 'Formato JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg';
							|pl = 'Format JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg';
							|tr = 'Format JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg'");
	PNGFormat		= NStr("vi = 'Định dạng PNG(*.png*)|*.png';
							|ru = 'Формат PNG(*.png*)|*.png';
							|en = 'Format PNG(*.png*)|*.png'; fa = 'Format PNG(*.png*)|*.png';
							|it = 'Formato PNG(*.png*)|*.png';
							|pl = 'Format PNG(*.png*)|*.png';
							|tr = 'Format PNG(*.png*)|*.png'");
	TIFFFormat		= NStr("vi = 'Định dạng TIFF(*.tif)|*.tif';
							|ru = 'Формат TIFF(*.tif)|*.tif';
							|en = 'Format TIFF(*.tif)|*.tif'; fa = 'Format TIFF(*.tif)|*.tif';
							|it = 'Formato TIFF(*.tif)|*.tif';
							|pl = 'Format TIFF(*.tif)|*.tif';
							|tr = 'Format TIFF(*.tif)|*.tif'");
	ICONFormat		= NStr("vi = 'Định dạng icon(*.ico)|*.ico';
							|ru = 'Формат icon(*.ico)|*.ico';
							|en = 'Format icon(*.ico)|*.ico'; fa = 'Format icon(*.ico)|*.ico';
							|it = 'Formato icon(*.ico)|*.ico';
							|pl = 'Format icon(*.ico)|*.ico';
							|tr = 'Format icon(*.ico)|*.ico'");
	MetafileFormat	= NStr("vi = 'Định dạng metafile(*.wmf;*.emf)|*.wmf;*.emf';
							|ru = 'Формат метафайл(*.wmf;*.emf)|*.wmf;*.emf';
							|en = 'Metafile format (*.wmf;*.emf)|*.wmf;*.emf'; fa = 'Metafile format (*.wmf;*.emf)|*.wmf;*.emf';
							|it = 'Formato metafile(*.wmf;*.emf)|*.wmf;*.emf';
							|pl = 'Format metaplik (*.wmf;*.emf)|*.wmf;*.emf';
							|tr = 'Meta dosyasını formatı(*.wmf;*.emf)|*.wmf;*.emf'");
	
	FileFilter = AllPictures + "|" + AllFiles + "|" + BMPFormat + "|" + GIFFormat + "|" + JPEGFormat + "|" + PNGFormat
					+ "|" + TIFFFormat + "|" + ICONFormat + "|" + MetafileFormat;
	
	Return FileFilter;
	
EndFunction

// Notifies the user about the completed selection of measurement units from the classifier.
//
// Parameters:
//	NumberOfNewItems_ - Number - number of selected units of measurement from the classifier,
//	ItemArray			 - Array - an array of references to the dictionary elements 'Packings of units of measurement'
//		selected from the classifier of units of measurement.
//
Procedure NotifyAboutChangesInUnitSelectionList(NumberOfNewItems_, ItemArray) Export
	
	TitleText = NStr("vi = 'Thêm yếu tố';
					|ru = 'Добавление элементов';
					|en = 'Add items'; fa = 'افزودن اقلام';
					|it = 'Aggiunta degli elementi';
					|pl = 'Dodanie elementów';
					|tr = 'Öğe ekleme'");
	
	If NumberOfNewItems_ = 1 Then
		ItemToAdd = ItemArray[0];
		
		UnitReference__ = GetURL(ItemToAdd);
		
		MessageText = NStr("vi = 'Một đơn vị đo lường mới đã được thêm vào danh sách: %UnitOfMeasure%.';
							|ru = 'В список добавлена новая единица измерения: %UnitOfMeasure%.';
							|en = 'New unit of measure is added to the list: %UnitOfMeasure%.'; fa = 'New unit of measure is added to the list: %UnitOfMeasure%.';
							|it = 'lista aggiunta una nuova unità di Misura: %UnitOfMeasure%.';
							|pl = 'Do listy jest dodana nowa jednostka miary: %UnitOfMeasure%.';
							|tr = 'Listeye yeni bir ölçü birimi eklendi: %UnitOfMeasure%.'");
		MessageText = StrReplace(MessageText, "%UnitOfMeasure%", String(ItemToAdd));
	Else
		UnitReference__ = "";
		
		DeclinedExpression = TMCommonUseClientServer.InPlural(NStr("vi = 'đơn vị mới';
																	|ru = 'новая единица измерения';
																	|en = 'new unit of measure'; fa = 'new unit of measure';
																	|it = 'nuova unità di misura';
																	|pl = 'nowa jednostka miary';
																	|tr = 'yeni ölçü birimi'"),
																					NStr("vi = 'đơn vị mới';
																						|ru = 'новых единиц измерений';
																						|en = 'new units of measure'; fa = 'new units of measure';
																						|it = 'di nuove unità di misura';
																						|pl = 'nowych jednostek miary';
																						|tr = 'yeni ölçü birimlerinin'"),
																					NStr("vi = 'đơn vị mới';
																						|ru = 'новых единиц измерений';
																						|en = 'new units of measure'; fa = 'new units of measure';
																						|it = 'di nuove unità di misura';
																						|pl = 'nowych jednostek miary';
																						|tr = 'yeni ölçü birimlerinin'"),
																					NumberOfNewItems_);
		
		MessageText = NStr("vi = 'Đã thêm vào danh sách %NumberOfNewItems_% %DeclinedExpression%.';
							|ru = 'В список добавлено %NumberOfNewItems_% %DeclinedExpression%.';
							|en = '%NumberOfNewItems_% %DeclinedExpression% are added to the list.'; fa = '%NumberOfNewItems_% %DeclinedExpression% are added to the list.';
							|it = 'L''elenco contiene%NumberOfNewItems_% %DeclinedExpression%.';
							|pl = 'Do listy dodano %NumberOfNewItems_% %DeclinedExpression%.';
							|tr = 'Listeye eklendi %NumberOfNewItems_% %DeclinedExpression%.'");
		MessageText = StrReplace(MessageText, "%NumberOfNewItems_%", NumberOfNewItems_);
		MessageText = StrReplace(MessageText, "%DeclinedExpression%", DeclinedExpression);
	EndIf;
	
	ShowUserNotification(TitleText, UnitReference__, MessageText,
		PictureLib.Information32);
	
EndProcedure

#Region InteractiveActions

// The function is a handler for the "initial Selection" event for those form elements in which
//  both the reference group and the element can be selected.
//
// Parameters:
//  Form				 - ClientApplicationForm	 - the context of the action.
//  Item				 - FormField		 - the element where the selection is made.
//  StandardProcessing - Boolean			 - indicates the standard processing of the selection in the field.
//
Procedure SelectItemGroupOfProducts(Form, Item, StandardProcessing) Export
	If Item.ChoiceFoldersAndItems <> FoldersAndItems.Folders
		And Item.ChoiceFoldersAndItems <> FoldersAndItems.Items Then 
		
		StandardProcessing = False;
		
		ListGroupElement = New ValueList;
		ListGroupElement.Add(FoldersAndItemsUse.Folders, NStr("vi = 'Chọn nhóm mặt hàng';
																|ru = 'Выбрать группу номенклатуры';
																|en = 'Select items group'; fa = 'Select items group';
																|it = 'Seleziona il valore degli articoli';
																|pl = 'Wybierz grupę nomenklatury';
																|tr = 'Öğe grubunu seç'"));
		ListGroupElement.Add(FoldersAndItemsUse.Items, NStr("vi = 'Chọn mục mặt hàng';
															|ru = 'Выбрать позицию номенклатуры';
															|en = 'Select product item'; fa = 'Select product item';
															|it = 'Seleziona laposizione degli articoli';
															|pl = 'Wybierz pozycję nomenklatury';
															|tr = 'Öğe konumunu seç'"));
		
		ListItem = Form.ChooseFromList(ListGroupElement,Item);
		
		If ListItem = Undefined Then
			Return;
		EndIf;
		
		ProductSelectionFormParameters = New Structure;
		ProductSelectionFormParameters.Insert("ChoiceFoldersAndItems", ListItem.Value);
	
		If ProductSelectionFormParameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
			OpenForm("Catalog.Products.ChoiceForm",ProductSelectionFormParameters, Item);
		Else
			OpenForm("Catalog.Products.FolderChoiceForm",ProductSelectionFormParameters, Item);
		EndIf;
	Else
		Return;
	EndIf;
EndProcedure

#EndRegion

#Region ProceduresForWorkingWithSeries

// The function checks whether the series must be specified in the string, if possible, and opens the indication form
//  if the indication form does not require a context call to the server.
//
// Parameters:
//  Form					 - ClientApplicationForm	 - The Form Of the document in which the indication of the series is initiated contains, among other things:
//  	* Object - DocumentObject, FormDataStructure - 
//  SeriesSpecificationParameters	 - Structure		 - parameters for specifying series returned by the corresponding procedure in the document Manager module.
//  Text					 - String			 - text entered in the input field (parameter for the end of text And auto-end of Text events);
//  CurrentData			 - Structure, FormDataCollectionItem - The data of the row in which the series is specified, if the value is not passed, then the Cur data of the table field with the name of the Series parametersreferences is used.Product name, must contain:
//  	* Ref - DocumentRef
//  DefineOrder	 - Boolean			 - indicates whether an order must be determined based on field values;
//  IssueMessages		 - Boolean			 - indicates whether an informational message should be displayed to the user.
// 
// Returns:
//  Boolean - a contextual call is needed.
//
Function YouNeedServerCallToSpecifySeries(Form, SeriesSpecificationParameters, Text, CurrentData = Undefined, DefineOrder = True, IssueMessages = True) Export
	
	If Not CheckFieldsBeforeSpecifyingSeries(Form, SeriesSpecificationParameters, CurrentData, IssueMessages) Then
		Return False;
	EndIf;
	
	TextOfSeriesSelectionField_ = "";
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		TextOfSeriesSelectionField_ = TextOfSeriesSelectionField_ + "," + ArrRow  ;
	EndDo;
	For Each ArrRow In SeriesSpecificationParameters.AdditionalFieldNames Do
		TextOfSeriesSelectionField_ = TextOfSeriesSelectionField_ + "," + ArrRow  ;
	EndDo;
	SeriesSelectionParameters_ = New Structure("Products,Characteristic" + TextOfSeriesSelectionField_);
	If SeriesSelectionParameters_.Property("Purpose") Then
		SeriesSelectionParameters_.Delete("Purpose");
	EndIf;
	
	If SeriesSpecificationParameters.ProductInHeader And CurrentData = Undefined Then
		
		If Form.Object.BatchesIndicationStatus = 13
			Or Form.Object.BatchesIndicationStatus = 14
			Or Form.Object.BatchesIndicationStatus = 15
			Or Form.Object.BatchesIndicationStatus = 19 Then
			
			If SeriesSpecificationParameters.ReadOnly
				Or Form.ReadOnly Then
				SeriesSelectionParameters_.Insert("ReadOnly", True);
			Else
				Form.LockFormDataForEdit();
				Form.Modified = True;
				
				SeriesSelectionParameters_.Insert("ReadOnly", False);
			EndIf;
			
			SeriesSelectionParameters_.Insert("Products", Form.Object.Products);
			SeriesSelectionParameters_.Insert("Characteristic", Form.Object.Characteristic);
			
			If SeriesSpecificationParameters.FieldNameQuantity <> Undefined Then
				SeriesSelectionParameters_.Insert("Count", Form.Object[SeriesSpecificationParameters.FieldNameQuantity]);
			EndIf;
			
			// Filling in the assignment in the assembly order
			If Form.Object.Property("AssignmentGoods") 
				And SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ShipSetsForDisassembly")) <> Undefined Then
				If Form.Object.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
							And Form.Object.WithAssignment
						Or Form.Object.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
							And Form.Object.WithAssignment Then
					If ValueIsFilled(Form.Object.Purpose) Then
						SeriesSelectionParameters_.Insert("Purpose", Form.Object.Purpose);
					Else
						SeriesSelectionParameters_.Insert("Purpose", Form.Object.AssignmentGoods);
					EndIf;
				EndIf;
			ElsIf Form.Object.Property("Purpose") Then
				SeriesSelectionParameters_.Insert("Purpose", Form.Object.Purpose);
			EndIf;
			
			SeriesSelectionParameters_.Insert("Series", Form.Object.Series);
			
			If Form.Object.Property("Ref") Then
				SeriesSelectionParameters_.Insert("Recorder", Form.Object.Ref);
			EndIf;
				
			If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
				SeriesSelectionParameters_.Insert("Warehouse", Form.Object[SeriesSpecificationParameters.WarehouseFieldName]);
			EndIf;
			
			SeriesSelectionParameters_.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
			
			FieldValuesToIdentifyReferences = ProductsClientServer.FieldValuesToIdentifyReferences(Form.Object,
																							  Form.Object,
																							  SeriesSpecificationParameters);

			SeriesSelectionParameters_.Insert("FieldValuesToIdentifyReferences", FieldValuesToIdentifyReferences);
			SeriesSelectionParameters_.Insert("Text", Text);
			
			OpenForm("DataProcessor.SelectBatchToDocuments.Form.BatchIndicationInGoodsRow",SeriesSelectionParameters_, Form);
			
			Return False;
		EndIf;
		
	Else
		
		CurrentRowID = Undefined;
		
		If Not CurrentData.Property("CurrentRowID", CurrentRowID) Then
			CurrentRowID = CurrentData.GetID();
		EndIf;
			
		If ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(CurrentData.BatchesIndicationStatus, SeriesSpecificationParameters)
			And CurrentData.Property("Series")
			And (Not SeriesSpecificationParameters.ItSWarrant
				Or (SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.SurplusesRecord")) <> Undefined
					And SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ShortageRecord")) <> Undefined)) Then
			
			If SeriesSpecificationParameters.NameOfValueSourceInObjectForm = "CurrentData" Then
				FormDataSource = CurrentData;
			Else 
				FormDataSource = Form[SeriesSpecificationParameters.NameOfValueSourceInObjectForm];
			EndIf; 
			
			If SeriesSpecificationParameters.ReadOnly
				Or Form.ReadOnly Then
				SeriesSelectionParameters_.Insert("ReadOnly", True);
			Else
				Form.LockFormDataForEdit();
				Form.Modified = True;
				
				SeriesSelectionParameters_.Insert("ReadOnly", False);
			EndIf;
				
			FillPropertyValues(SeriesSelectionParameters_,CurrentData);
			
			If SeriesSpecificationParameters.FieldNameQuantity <> Undefined Then
				SeriesSelectionParameters_.Insert("Count", CurrentData[SeriesSpecificationParameters.FieldNameQuantity]);
			EndIf;
			
			If CurrentData.Property("WizardMode") Then
				SeriesSelectionParameters_.Insert("WizardMode", CurrentData.WizardMode);
			EndIf;
			
			If CurrentData.Property("AssignmentSender") Then
				SeriesSelectionParameters_.Insert("AssignmentSender", CurrentData.AssignmentSender);	
			ElsIf SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ShipmentByTransfer")) <> Undefined 
				And CurrentData.Property("SupplyOption") Then
				If CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
							And CurrentData.WithAssignment
						Or CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
							And CurrentData.WithAssignment Then
					If ValueIsFilled(CurrentData.Purpose) Then
						SeriesSelectionParameters_.Insert("AssignmentSender", CurrentData.Purpose);
					Else
						SeriesSelectionParameters_.Insert("AssignmentSender", FormDataSource.Purpose);
					EndIf;
				Else
					SeriesSelectionParameters_.Insert("AssignmentSender", PredefinedValue("Catalog.Assignments.EmptyRef"));	
				EndIf;
			EndIf;
			
			If CurrentData.Property("Purpose") Then
				SeriesSelectionParameters_.Insert("Purpose", CurrentData.Purpose);
			ElsIf TypeOf(FormDataSource) <> Type("ClientApplicationForm") 
				And FormDataSource.Property("Purpose") Then
				
				If CurrentData.Property("SupplyOption") Then 
				If CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
							And CurrentData.WithAssignment
						Or CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
							And CurrentData.WithAssignment Then
						SeriesSelectionParameters_.Insert("Purpose", Form.Object.Purpose);
					EndIf; 
				EndIf;
				
			EndIf;
			
			// Filling in the assignment in the assembly order
			If TypeOf(FormDataSource) <> Type("ClientApplicationForm") 
				And FormDataSource.Property("AssignmentGoods")
				And SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ShipComponentsForAssembly")) <> Undefined Then
				If CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
							And CurrentData.WithAssignment
						Or CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
							And CurrentData.WithAssignment Then
					If ValueIsFilled(FormDataSource.Purpose) Then
						SeriesSelectionParameters_.Insert("Purpose", Form.Object.Purpose);
					Else
						SeriesSelectionParameters_.Insert("Purpose", Form.Object.AssignmentGoods);
					EndIf;
				EndIf;
			EndIf;
			
			// Filling in the assignment in the order of materials for production
			If SeriesSpecificationParameters.FullObjectName = "Document.OrderOfMaterialsForProduction" Then
				If CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
							And CurrentData.WithAssignment
						Or CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
							And CurrentData.WithAssignment Then
					If ValueIsFilled(CurrentData.Purpose) Then
						SeriesSelectionParameters_.Insert("Purpose", CurrentData.Purpose);
					Else
						SeriesSelectionParameters_.Insert("Purpose", FormDataSource.Purpose);
					EndIf;
				Else
					SeriesSelectionParameters_.Insert("Purpose", PredefinedValue("Catalog.Assignments.EmptyRef"));
				EndIf;
			EndIf;
			// Filling out assignments for production stages
			If TypeOf(FormDataSource) <> Type("ClientApplicationForm")
				And (SeriesSpecificationParameters.FullObjectName = "Document.ProductionStage2_2"
					Or SeriesSpecificationParameters.FullObjectName = "DataProcessor.EditProductionStageSequence")
				And CurrentData.Property("SupplyOption") Then
				If CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship")
							And CurrentData.WithAssignment
						Or CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
							And CurrentData.WithAssignment Then
					SeriesSelectionParameters_.Insert("Purpose", CurrentData.Purpose);
				Else
					SeriesSelectionParameters_.Insert("Purpose", PredefinedValue("Catalog.Assignments.EmptyRef"));
				EndIf;
			EndIf;
			
			// Filling out an appointment for production without an order
			If SeriesSpecificationParameters.FullObjectName = "Document.BackflushProduction" Then
				SeriesSelectionParameters_.Insert("Purpose", CurrentData.Purpose);
			EndIf;
			If SeriesSpecificationParameters.FullObjectName = "Document.InventoryAssignmentAdjustment" Then
				SeriesSelectionParameters_.Insert("Purpose", SeriesSelectionParameters_.InitialAssignment);
			EndIf;
			
			SeriesSelectionParameters_.Insert("Series", CurrentData.Series);
			SeriesSelectionParameters_.Insert("Recorder", FormDataSource.Ref);
			
			If SeriesSpecificationParameters.FieldNameRoom <> Undefined Then
				SeriesSelectionParameters_.Insert("Premise", FormDataSource[SeriesSpecificationParameters.FieldNameRoom]);
			ElsIf SeriesSpecificationParameters.LinkFields.Find("Premise") <> Undefined Then
				SeriesSelectionParameters_.Insert("Premise", CurrentData.Premise);
			EndIf;
			
			If SeriesSpecificationParameters.FullObjectName = "Document.ReceiptOfGoodsFromCustodian"
				Or SeriesSpecificationParameters.FullObjectName = "Document.GoodsReceiptFromCustomer"
				Or SeriesSpecificationParameters.FullObjectName = "Document.RedemptionOfGoodsByCustodian"
				Or SeriesSpecificationParameters.FullObjectName = "Document.WriteOffOfShippedGoods"
				Or SeriesSpecificationParameters.FullObjectName = "Document.RecognitionOfStockSurplusShippedToCustomer"
				Or SeriesSpecificationParameters.FullObjectName = "Document.ConsignmentReportFromCustomer"
				Or SeriesSpecificationParameters.FullObjectName = "Document.WriteOffOfShippedGoods"
				Or (SeriesSpecificationParameters.FullObjectName = "Document.SubcontractorReport2_5"
					And Not SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.MovementInFinancialAccounting")) = Undefined)
				Or (SeriesSpecificationParameters.FullObjectName = "Document.CustomerInvoice"
					And SeriesSpecificationParameters.DocumentOperation_ = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")) Then
				SeriesSelectionParameters_.Insert("Warehouse", FormDataSource.Contract);
			ElsIf SeriesSpecificationParameters.LinkFields.Find("Warehouse") <> Undefined
				Or SeriesSpecificationParameters.AdditionalFieldNames.Find("Warehouse") <> Undefined Then
				SeriesSelectionParameters_.Insert("Warehouse", CurrentData.Warehouse);
			ElsIf SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined Then
				SeriesSelectionParameters_.Insert("Warehouse", CurrentData[SeriesSpecificationParameters.WarehouseFieldName]);
			ElsIf SeriesSpecificationParameters.LinkFields.Find("Department") <> Undefined Then
				SeriesSelectionParameters_.Insert("Warehouse", CurrentData.Department);
			ElsIf ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
				SeriesSelectionParameters_.Insert("Warehouse", FormDataSource[SeriesSpecificationParameters.WarehouseFieldName]);
			EndIf;
			
			SeriesSelectionParameters_.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
			
			If DefineOrder Then
				FieldValuesToIdentifyReferences = ProductsClientServer.FieldValuesToIdentifyReferences(FormDataSource,
																									CurrentData,
																									SeriesSpecificationParameters);
			Else
				FieldValuesToIdentifyReferences = New Structure;
			EndIf;
			SeriesSelectionParameters_.Insert("FieldValuesToIdentifyReferences", FieldValuesToIdentifyReferences);
			SeriesSelectionParameters_.Insert("CurrentRowID", CurrentRowID);
			SeriesSelectionParameters_.Insert("Text", Text);
			
			ControlledLotReference = Undefined;
			If SeriesSpecificationParameters.FieldNameControlledLotReference = Undefined Then
				ControlledLotReference = PredefinedValue("Catalog.ControlledLots.EmptyRef");
			ElsIf StrFind(SeriesSpecificationParameters.FieldNameControlledLotReference, ".") > 0 Then
				ControlledLotReference = CurrentData[StrReplace(SeriesSpecificationParameters.FieldNameControlledLotReference, ".", "")];
			Else
				ControlledLotReference = Form.Object[SeriesSpecificationParameters.FieldNameControlledLotReference];
			EndIf;
			SeriesSelectionParameters_.Insert("ControlledLotReference", ControlledLotReference);
			
			OpenForm("DataProcessor.SelectBatchToDocuments.Form.BatchIndicationInGoodsRow",SeriesSelectionParameters_, Form);
			
			Return False;
			
		EndIf;
				
	EndIf;
	
	Return True;
	
EndFunction

// The function checks whether the series can be canceled in a row.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the document in which the indication of series is initiated;
//	SeriesSpecificationParameters - Structure - parameters for specifying the series returned by the corresponding procedure in the document Manager module;
//	NameOfTableField - String - The name of the tabular part of the document.
//
// Returns:
//	Boolean - True if a server call is needed.
//
Function ToCancelIndicationOfSeriesServerCallIsNeeded(Form,SeriesSpecificationParameters, NameOfTableField = "") Export
	
	If NameOfTableField = "" Then
		NameOfTableField = SeriesSpecificationParameters.NameTSGoods;
	EndIf;
	
	If SeriesSpecificationParameters.ProductInHeader Then
		
		If Not Form.Object.SpecifyBatches Then
			
			MessageText = NStr("vi = 'Chưa chỉ ra sê-ri đối với bộ đóng gói.';
								|ru = 'Для комплекта серии не указаны.';
								|en = 'Batches are not specified for the kit.'; fa = 'Batches are not specified for the kit.';
								|it = 'Per il kit di serie non sono specificati.';
								|pl = 'Dla kompletu serie nie są wskazane.';
								|tr = 'Set için partiler belirtilmedi.'");
			ShowMessageBox(,MessageText);
			Return False;
			
		EndIf;
		
	Else
		
		CurrentData = Form.Items[NameOfTableField].CurrentData;
		
		If CurrentData = Undefined Then
			
			MessageText = NStr("vi = 'Cần chọn dòng hàng hóa mà cần hủy bỏ việc chỉ ra sê-ri.';
								|ru = 'Необходимо выбрать строку товаров, для которой необходимо отменить указание серий.';
								|en = 'Select a goods line for which batch specification should be canceled.'; fa = 'Select a goods line for which batch specification should be canceled.';
								|it = 'È necessario selezionare la riga degli articoli per la quale si desidera annullare l''indicazione della serie.';
								|pl = 'Należy wybrać wiersz towarów, dla którego należy anulować wskazanie serii.';
								|tr = 'Partinin seçimini kaldırmak için ürün partisi seçilmeli.'");
			ShowMessageBox(,MessageText);
			Return False;
			
		ElsIf Not CurrentData.SpecifyBatches Then
			
			MessageText = NStr("vi = 'Đối với dòng sê-ri đã chọn chưa chỉ ra.';
								|ru = 'Для выбранной строки серии не указаны.';
								|en = 'Batches are not specified for the selected line.'; fa = 'Batches are not specified for the selected line.';
								|it = 'Per la riga selezionata di serie non sono specificati.';
								|pl = 'Dla wybranego wiersza serie nie są wskazane.';
								|tr = 'Seçilen satır için partiler belirtilmedi.'");
			ShowMessageBox(,MessageText);
			Return False;
			
		ElsIf CurrentData.BatchesIndicationStatus = 14 Then
			
			If CurrentData.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse") Then
				CurrentData.BatchesIndicationStatus = 15;
			Else
				CurrentData.BatchesIndicationStatus = 13;
			EndIf;
			
			CurrentData.Series               = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			CurrentData.SpecifyBatches      = False;
			
			Return False;
			
		EndIf;
		
	EndIf;
	
	Form.LockFormDataForEdit();
	Form.Modified = True;
	
	Return True;
	
EndFunction

// The procedure updates the cache of key details of the current product line. Key details are
//  used to link the PM series and PM products.
//
// Parameters:
//  FormTable			 - FormTable	 - the table that lists the PM with the goods.
//  CachedValues	 - Structure	 - a form module variable that stores cached values.
//  SeriesSpecificationParameters	 - Structure	 - structure of parameters for specifying series returned by the corresponding procedure in the document Manager module.
//  Copy				 - Boolean		 - indicates that the cached string has been copied (parameter of the event at the start of Editing).
//
Procedure UpdateCachedValuesToAccountForSeries(FormTable,CachedValues,SeriesSpecificationParameters,Copy = False) Export
	
	CurrentData = FormTable.CurrentData;
	
	ProductsClientServer.UpdateCachedValuesToAccountForSeries(CurrentData,CachedValues,SeriesSpecificationParameters,Copy);
	
EndProcedure

// Updates the cache of key Attributes of the product in the header of the document. According to the key Attributes, communication is carried
//  out between the TS and the product.
//
// Parameters:
//  Object					 - FormDataStructure	 - The main props of the form
//  CachedValues	 - Structure			 - a form module variable that stores cached values
//  SeriesSpecificationParameters	 - Structure			 - parameters for specifying the series returned by the corresponding procedure in the document Manager module.
//
Procedure UpdateCachedHeaderValuesToAccountForSeries(Object, CachedValues, SeriesSpecificationParameters) Export
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return;
	EndIf;
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	CachedValues.Insert("ProductHeader", Object.Products);
	CachedValues.Insert("CharacteristicCap", Object.Characteristic);
	CachedValues.Insert("DestinationHeader_", Object.Purpose);
	CachedValues.Insert("NumberOfCaps", Object.Count);
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		NameOfProductHeaderField = ProductsClientServer.NameOfProductHeaderField(ArrRow);
		
		CachedValues.Insert(NameOfProductHeaderField, Object[ArrRow]);
	EndDo;
		
EndProcedure

// This function checks whether the series indication statuses need to be updated when the product line is finished editing.
//
// Parameters:
//  FormTable			 - FormTable	 - form table that displays the PM of products;
//  CachedValues	 - Structure	 - a form module variable that stores cached values;
//  SeriesSpecificationParameters	 - Structure	 - parameters for specifying series returned by the corresponding procedure in the document Manager module.
//  Delete				 - Boolean		 - True, indicates that the check is called when the PM string is deleted.
// 
// Returns:
//  Boolean - whether the series indication statuses need to be updated.
//
Function SeriesStatusesNeedToBeUpdated(FormTable,CachedValues,SeriesSpecificationParameters, Delete = False) Export
	
	CurrentData = FormTable.CurrentData;
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return False;
	EndIf;
	
	If Delete Then
		Return True;
	EndIf;
	
	If CachedValues = Undefined Then
		Return False;
	EndIf;
	
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
		Return False;
	EndIf;
	
	LinkFieldText = "";
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + ArrRow;
	EndDo;
	
	If CurrentData.Property("Canceled") Then
		LinkFieldText = LinkFieldText + ",Canceled";
	EndIf;
	
	If Not TMCommonUseClientServer.StructuresAreEqual(CachedValues,CurrentData,
		SeriesSpecificationParameters.FieldNameQuantity + ",Products,Characteristic"+LinkFieldText) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// The function checks whether the status of specifying the product series in the document header needs to be updated.
//
// Parameters:
//  Object					 - FormDataStructure	 - the main props of the form;
//  CachedValues	 - Structure			 - a form module variable that stores cached values;
//  SeriesSpecificationParameters	 - Structure			 - parameters for specifying series returned by the corresponding procedure
//  			in the document Manager module.
// 
// Returns:
//  Boolean - whether the status of the series indication needs to be updated.
//
Function YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,Val SeriesSpecificationParameters) Export
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return False;
	EndIf;
	
	If CachedValues.ProductHeader <> Object.Products
		Or CachedValues.CharacteristicCap <> Object.Characteristic
		Or CachedValues.NumberOfCaps <> Object.Count
		Or CachedValues.DestinationHeader_ <> Object.Purpose Then
		
		Return True;
		
	Else
		For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
			NameOfProductHeaderField = ProductsClientServer.NameOfProductHeaderField(ArrRow);
			
			If CachedValues[NameOfProductHeaderField] <> Object[ArrRow] Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

// Requests the user to confirm that the FEFO series has been re-filled.
//
// Parameters:
//  NotificationAfterResponse	 - CallbackDescription - action after the response.
//
Procedure AskQuestionAboutReFillingSeriesByFEFO(NotificationAfterResponse) Export 
	
	QueryText = NStr("vi = 'Có các dòng, trong đó đã điền sê-ri theo FEFO. Khi thực hiện giao dịch
		|sê-ri trong các dòng này sẽ được điền lại. Tiếp tục?';
		|ru = 'Есть строки, в которых серии по FEFO уже заполнены. При выполнении операции
		|серии в этих строках будут перезаполнены. Продолжить?';
		|en = 'There are lines in which batch by FEFO are already filled in. When executing the operation,
		|the batch in these lines will be refilled. Continue?'; fa = 'There are lines in which batch by FEFO are already filled in. When executing the operation,
		|the batch in these lines will be refilled. Continue?';
		|it = 'Ci sono righe in cui le serie di FEFO sono già riempite. Quando si esegue l''operazioni
		| delle serie in queste righe, verranno sovrascritti. Continuare?';
		|pl = 'Są wiersze, w których serie wg FEFO już są wypełnione. Przy wykonaniu operacji
		|serie w tych wierszach będą wypełnione ponownie. Kontynuować?';
		|tr = 'FEFO partisinin zaten doldurulduğu satırlar mevcut. İşlem yapıldığında
		|bu satırlardaki partiler yeniden doldurulacaktır. Devam edilsin mi?'");
	
	ShowQueryBox(
		New CallbackDescription("AskQuestionAboutReFillingSeriesByFEFOCompletion", 
			ThisObject, 
			New Structure("NotificationAfterResponse", NotificationAfterResponse)), 
		QueryText, 
		QuestionDialogMode.OKCancel,
		,
		DialogReturnCode.OK);
		
EndProcedure

// The procedure processes an alert after a question about re-filling the FEFO series.
//
// Parameters:
//  QuestionResult		 - DialogReturnCode - response to question.
//  AdditionalParameters	 - Structure - a notification is sent after the Response.
//
Procedure AskQuestionAboutReFillingSeriesByFEFOCompletion(QuestionResult, AdditionalParameters) Export
	
	NotificationAfterResponse = AdditionalParameters.NotificationAfterResponse;
	
	If QuestionResult <> DialogReturnCode.OK Then
		RunCallback(NotificationAfterResponse, False);
	Else
		RunCallback(NotificationAfterResponse, True);
	EndIf;

EndProcedure

// The function displays a warning that there are no rows in the PM that can be filled in by FEFO.
Procedure WarnAboutAbsenceOfLinesFilledByFEFO() Export
	WarningText = NStr("vi = 'Trong phần bảng không có hàng hóa mà theo đó sê-ri có thể điền theo FEFO.';
						|ru = 'В табличной части нет товаров, по которым серии можно заполнить по FEFO.';
						|en = 'The table contains no goods that can be used to fill in batch by FEFO.'; fa = 'The table contains no goods that can be used to fill in batch by FEFO.';
						|it = 'Nella parte tabellare non ci sono prodotti su cui le serie possono essere riempite da FEFO.';
						|pl = 'W części tabelarycznej brak towarów, wg których serie można wypełnić wg FEFO.';
						|tr = 'Tablo bölümünde FEFO''ya göre parti doldurulabilecek ürün yok.'");	
	
	ShowMessageBox(Undefined, WarningText);
EndProcedure

// Processes the indication of the series in PM "Products".
//	Parameters:
//		Form - ClientApplicationForm - the document form in which the series is initiated
//		SeriesSpecificationParameters - Structure - parameters for specifying series returned by the corresponding procedure in the document Manager module
//		SelectedSeries - Structure - the format that is described in the function Nomenclaturales.Selected criteria
//		CurrentData - Structure, FormDataCollectionItem  - data string which identifies the series, if a value is not passed,
//									it uses the current data table field name Parametrizatsii.Matchcover.
//
Procedure ProcessSeriesIndication(Form, SeriesSpecificationParameters, SelectedSeries, CurrentData = Undefined) Export
	
	ThereIsSignOfIndicatingSeries = SeriesSpecificationParameters.LinkFields.Find("SpecifyBatches") <> Undefined;
	
	If CurrentData = Undefined Then 
		If Not SeriesSpecificationParameters.ProductInHeader Then		
			CurrentData = Form.Items[SeriesSpecificationParameters.NameTSGoods].RowData(SelectedSeries.CurrentRowID);
			
			If CurrentData = Undefined Then
				Return;
			EndIf;
		Else
			CurrentData = Form.Object;
		EndIf;
	EndIf;
	
	// It is possible to recalculate the serial indication status on the client after specifying the series,
	// if it is not necessary to analyze the PM Series for this, i.e. when there is no PM, or when the series are indicated in PM Products.
	If ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(CurrentData.BatchesIndicationStatus, SeriesSpecificationParameters) Then
		
		If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
			ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
																				CurrentData.BatchesIndicationStatus,
																				ValueIsFilled(SelectedSeries.Value),
																				Undefined,
																				?(SeriesSpecificationParameters.ThisIsOrder, CurrentData.SupplyOption, Undefined),
																				CurrentData);
		Else
			
			For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				If CurrentData.Property(NameOfStatusField) Then
					ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
																						CurrentData[NameOfStatusField],
																						ValueIsFilled(SelectedSeries.Value),
																						Undefined,
																						?(SeriesSpecificationParameters.ThisIsOrder, CurrentData.SupplyOption, Undefined),
																						CurrentData);
				EndIf;
			EndDo;
			
		EndIf;
		
		CurrentData.Series = SelectedSeries.Value;
		
		If ThereIsSignOfIndicatingSeries Then
			CurrentData.SpecifyBatches = Not ProductsClientServer.NoSeriesAreSpecifiedInThisStatus(CurrentData.BatchesIndicationStatus,
																										SeriesSpecificationParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns the parameters needed to decrypt the report Videosdepornogratis.
//
// Returns:
//   Structure   - parameters required to decrypt the report.
//
Function DecryptionParametersReportStatementBySeriesOfProducts() Export

	ReportMenu  = New Array;
	ActionMenu = New Array;
	
	// Decipher the report -> Movement of a series of nomenclature
	#Region ProductSeriesMovementContext
	ReportParameters = New Structure;
	ReportParameters.Insert("Name", "ProductSeriesMovementContext");
	ReportParameters.Insert("Title", NStr("vi = 'Biến động sê-ri mặt hàng';
											|ru = 'Движение серии номенклатуры';
											|en = 'Item batch movement'; fa = 'جابه‌جایی بچ قلم';
											|it = 'Movimento di lotti di articoli';
											|pl = 'Ruch serii nomenklatury';
											|tr = 'Ürün parti hareketi'"));
	ReportParameters.Insert("ReportName", "Report.ItemBatchMovement");
	
	DecryptionFields  = New Array;
	DecryptionFields.Add("Series");
	DecryptionFields.Add("Characteristic");
	DecryptionFields.Add("Recipient");
	DecryptionFields.Add("Premise");
	ReportParameters.Insert("DecryptionFields", DecryptionFields);
	
	RequiredParameters = New Structure;
	RequiredParameters.Insert("Series");
	RequiredParameters.Insert("Characteristic");
	ReportParameters.Insert("RequiredParameters", RequiredParameters);
	
	ParametersList = New Array;
	ParametersList.Add("Products");
	ReportParameters.Insert("ParametersList", ParametersList);
	
	ReplacingParameters = New Structure;
	ReplacingParameters.Insert("Recipient", "ConsigneeOrSender");
	ReplacingParameters.Insert("Premise", "ShippingOrReceivingWareroom");
	ReportParameters.Insert("ReplacingParameters", ReplacingParameters);
	
	FixedParameters = New Structure;
	FixedParameters.Insert("UseSenderOrRecipientWareroom", True);
	ReportParameters.Insert("FixedParameters", FixedParameters);
	
	ReportMenu.Add(ReportParameters);
	#EndRegion
		
	DetailsParameters = New Structure;
	DetailsParameters.Insert("ReportMenu",  ReportMenu);
	DetailsParameters.Insert("ActionMenu", ActionMenu);

	Return DetailsParameters;
	
EndFunction

// The function is called in the selection Handler in the form that specifies the series
// and checks that the source of the selection is the form that specifies the series.
//
// Parameters:
//  ChoiceSource	 - Arbitrary - the form where the selection was made. Parameter of the form selection Processing event.
// 
// Returns:
//   Boolean - true if it is an indication of the series.
//
Function ThisIsIndicationOfSeries(ChoiceSource) Export
	
	Return ChoiceSource.FormName = "DataProcessor.SelectBatchToDocuments.Form.BatchIndicationInGoodsRow";
	
EndFunction

// Re-computes the platform event handler start selecting props "Datapointstyle" directory "Sereinement".
//
// Parameters:
//	Object					 - FormDataStructure, FormDataCollectionItem	 - data structure containing the processed information
//	CallbackOnCompletion	 - CallbackDescription, Undefined						 - description of the notification that is executed after closing the date indication form.
//	StandardProcessing	 - Boolean												 - indicates whether standard event processing is being performed.
//
Procedure ProductionDateStartChoice(Object, CallbackOnCompletion, StandardProcessing) Export
	
	StandardProcessing = False;
	
	FormParameters      = New Structure("ProductionDate, SpecifyProductionDate", Object.ProductionDate, True);
	NotificationParameters = New Structure("Object, CallbackOnCompletion", Object, CallbackOnCompletion);
	CallbackDescription  = New CallbackDescription("ProductionDateStartChoiceCompletion", ThisObject,
									NotificationParameters);
	
	OpenForm("DataProcessor.SelectBatchToDocuments.Form.SpecifyDate", FormParameters, ThisObject, , , ,
		CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Redefines the platform event handler for the beginning of the selection of the "Godendo" attribute in the "Seriinomenklatura" reference list.
//
// Parameters:
//	Object					 - FormDataStructure, FormDataCollectionItem	 - data structure containing the processed information
//	FormParameters			 - Structure											 - parameters used when opening the date indication form
//	CallbackOnCompletion	 - CallbackDescription, Undefined						 - description of the notification that is executed after the form is closed 
//																						date indication.
//	StandardProcessing	 - Boolean												 - indicates whether standard event processing is being performed.
//
Procedure ExpirationDateStartOfSelection(Object, FormParameters, CallbackOnCompletion, StandardProcessing) Export
	
	StandardProcessing = False;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Object",                       Object);
	NotificationParameters.Insert("UseProductionDate", FormParameters.UseProductionDate);
	NotificationParameters.Insert("CallbackOnCompletion",        CallbackOnCompletion);
	
	CallbackDescription = New CallbackDescription("ExpirationDateStartOfSelectionCompletion", ThisObject,
									NotificationParameters);
	
	OpenForm("DataProcessor.SelectBatchToDocuments.Form.SpecifyDate", FormParameters, ThisObject, , , ,
		CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Notifies the user that a series has been re-filled
//
// Parameters:
//  HasChanges				 - Boolean	 - was the execution a re-fill
//  NumberIsInitiallyCorrect	 - Boolean	 - indicates that the original data corresponds to the overfilled data.
//
Procedure NotifyAboutReFillingSeries(HasChanges, NumberIsInitiallyCorrect) Export
	
	If HasChanges Then
		
		ShowUserNotification(
			NStr("vi = 'Điền lại sê-ri';
				|ru = 'Серии перезаполнены';
				|en = 'Batches are refilled'; fa = 'Batches are refilled';
				|it = 'La serie è piena';
				|pl = 'Serie są wypełnione ponownie';
				|tr = 'Partiler yeniden dolduruldu'"),
				,
				NStr("vi = 'Trong các dòng đã điền lại dữ liệu theo sê-ri.';
					|ru = 'В строках перезаполнены данные по сериям.';
					|en = 'Data by batches are repopulated in lines.'; fa = 'Data by batches are repopulated in lines.';
					|it = 'Le righe riempiono i dati di serie.';
					|pl = 'W wierszach są wypełnione ponownie dane wg serii.';
					|tr = 'Satırlarda partilere göre veriler aşırı dolduruldu.'"),
				PictureLib.Information32);
	
	ElsIf NumberIsInitiallyCorrect Then
			
			ShowUserNotification(
				NStr("vi = 'Không cần điền lại';
					|ru = 'Перезаполнение не требуется';
					|en = 'You do not need to refill'; fa = 'You do not need to refill';
					|it = 'Reseeding non richiesto';
					|pl = 'Ponowne wypełnienie nie jest potrzebne';
					|tr = 'Yeniden doldurma gerekmiyor'"),
				,
				NStr("vi = 'Không cần điền lại, bởi vì trong tất cả các dòng, đã chỉ ra đúng số lượng sê-ri hoặc còn chưa tiếp nhận sê-ri.';
					|ru = 'Перезаполнение не требуется, т.к. во всех строках количество серий указано верно, либо поступление серий еще не выполнено.';
					|en = 'It is not required to refill as batch quantity is specified correctly in all lines, or the batch have not been received yet.'; fa = 'It is not required to refill as batch quantity is specified correctly in all lines, or the batch have not been received yet.';
					|it = 'Reseeding non è necessario, perché in tutte le righe il numero di serie indicato giusto, o in arrivo la serie non è ancora disponibile.';
					|pl = 'Ponowne wypełnienie nie jest potrzebne, ponieważ we wszystkich wierszach ilość serii jest wskazana prawidłowo, albo wpływ serii jeszcze nie jest wykonany.';
					|tr = 'Yeniden doldurma gerekmiyor, çünkü tüm satırlarda parti numarası doğru verilmiş veya parti girişi henüz gerçekleştirilmedi.'"),
				PictureLib.Information32);
	
	Else
			
			ShowUserNotification(
				NStr("vi = 'Không cần điền lại';
					|ru = 'Перезаполнение не требуется';
					|en = 'You do not need to refill'; fa = 'You do not need to refill';
					|it = 'Reseeding non richiesto';
					|pl = 'Ponowne wypełnienie nie jest potrzebne';
					|tr = 'Yeniden doldurma gerekmiyor'"),
				,
				NStr("vi = 'Không cần điền lại, bởi vì còn chưa tiếp nhận sê-ri.';
					|ru = 'Перезаполнение не требуется, т.к. поступление серий еще не выполнено.';
					|en = 'It is not required to refill as batch have not been received.'; fa = 'It is not required to refill as batch have not been received.';
					|it = 'Reseeding non richiesto perché l''arrivo delle serie non è ancora stato completato.';
					|pl = 'Ponowne wypełnienie nie jest potrzebne, ponieważ wpływ serii jeszcze nie jest wykonany.';
					|tr = 'Yeniden doldurma gerekmiyor, çünkü parti girişi henüz gerçekleştirilmedi.'"),
				PictureLib.Information32);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region QualityCertificates

// Sets the Status value of nomenclature certificates for selected rows in the Form table.
//
// Parameters:
//	Form - ClientApplicationForm - The Form is the source of the Command initialization.
//	List - FormTable - the Form table for which Statuses are set.
//	Status - EnumRef.StatusesOfQualityCertificates - the value of the Status to be set.
//
Procedure SetStatusOfNomenclatureCertificates(Form, List, Status) Export
	
	ClearMessages();
	
	DataForProcessing_ = TMCommonUseClient.CheckGetLinksHighlightedInList(List);
	
	If DataForProcessing_.Count() = 0 Then
		Return;
	EndIf;
	
	FillParameters = ProductsClientServer.ParametersForSettingStatusOfCertificatesOfDefaultNomenclature();
	FillParameters.Status = Status;
	FillParameters.DataForProcessing_ = DataForProcessing_;
	
	TimeConsumingOperation = ProductsServerCall.SetStatusOfNomenclatureCertificates(
							Form.UUID,
							FillParameters);
	
	IdleParameters	= TimeConsumingOperationsClient.IdleParameters(Form);
	NotificationParameters	= New Structure("List", List);
	CallbackDescription	= New CallbackDescription("SetStatusOfNomenclatureCertificatesCompletion",
													ThisObject,
													NotificationParameters);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

#EndRegion

// Returns uninitialized parameters of the result of working with the form for monitoring the uniqueness of information database data.
//
// Returns:
//	Structure - a collection containing the following properties:
//		* Action - String - data processing action.
//		* Ref - CatalogRef.Products, CatalogRef.ItemsCharacteristics, CatalogRef.CCDNumbers, Undefined - link to the information base element.
//
Function NewCompletionProcessingResult() Export
	
	Result = New Structure;
	Result.Insert("Action",	"");
	Result.Insert("Ref",	Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region ProceduresForWorkingWithSeries

Procedure ProductionDateStartChoiceCompletion(Result, AdditionalParameters) Export
	
	CallbackOnCompletion = AdditionalParameters.CallbackOnCompletion;
	
	If Result <> Undefined Then
		FillPropertyValues(AdditionalParameters.Object, Result);
	EndIf;
	
	If CallbackOnCompletion <> Undefined Then
		RunCallback(CallbackOnCompletion, Result);
	EndIf;
	
EndProcedure

Procedure ExpirationDateStartOfSelectionCompletion(Result, AdditionalParameters) Export
	
	CallbackOnCompletion = AdditionalParameters.CallbackOnCompletion;
	
	If Result <> Undefined Then
		
		Object = AdditionalParameters.Object;
		
		Object.ValidUntil_ = Result.ValidUntil_;
		
		If ValueIsFilled(Result.ProductionDate)
			And AdditionalParameters.UseProductionDate Then
			
			Object.ProductionDate = Result.ProductionDate;
			
		EndIf;
		
	EndIf;
	
	If CallbackOnCompletion <> Undefined Then
		RunCallback(CallbackOnCompletion, Result);
	EndIf;
	
EndProcedure

Function	CheckFieldsBeforeSpecifyingSeries(Form, SeriesSpecificationParameters, CurrentData, IssueMessages)
	
	EverythingIsFilled = True;
	
	If SeriesSpecificationParameters.ProductInHeader And CurrentData = Undefined Then
		
		If Form.Object.BatchesIndicationStatus = 0 Then
			If IssueMessages Then
				MessageText = NStr("vi = 'Đối với bộ mặt hàng này không cần chỉ ra sê-ri.';
									|ru = 'Для этого комплекта серии указывать не нужно.';
									|en = 'Do not specify batch for this kit.'; fa = 'Do not specify batch for this kit.';
									|it = 'Per questo kit di serie non è necessario specificare.';
									|pl = 'Dla tego kompletu serii wskazywać nie trzeba.';
									|tr = 'Bu set için parti belirtilmesine gerek yoktur.'");
				ShowMessageBox(,MessageText);
			EndIf;
			EverythingIsFilled = False;
		EndIf;
		
	Else		
		
		If CurrentData = Undefined Then
			CurrentData = Form.Items[SeriesSpecificationParameters.NameTSGoods].CurrentData;
			If CurrentData = Undefined Then
				If IssueMessages Then
					MessageText = NStr("vi = 'Hãy chọn dòng hàng hóa mà cần chỉ ra sê-ri.';
										|ru = 'Выберите строку товаров, для которой необходимо указать серии.';
										|en = 'Select a goods line for which the batch shall be specified.'; fa = 'Select a goods line for which the batch shall be specified.';
										|it = 'Selezionare la riga dei prodotti per la quale è necessario specificare le serie.';
										|pl = 'Wybierz wiersz towarów, dla których chcesz określić serie.';
										|tr = 'Partisini belirtmek istediğin ürün satırını seç.'");
					ShowMessageBox(,MessageText);
				EndIf;
				EverythingIsFilled = False;
			EndIf;
		EndIf;
		
		If EverythingIsFilled
				And CurrentData.BatchesIndicationStatus = 0 Then
			If IssueMessages Then
					MessageText = NStr("vi = 'Đối với hàng hóa này, không cần chỉ ra sê-ri. Có thể ảnh hưởng đến khả năng chỉ ra sê-ri: dạng mặt hàng, kho bãi, chính sách chỉ ra sê-ri, trạng thái chứng từ.';
										|ru = 'Для этого товара серии указывать не нужно. На возможность указания серий могут влиять: вид номенклатуры, склад, политика указания серий, статус документа.';
										|en = 'Batches are not required for these goods. The option depends on: item kind, warehouse, batch specification policy, document status.'; fa = 'Batches are not required for these goods. The option depends on: item kind, warehouse, batch specification policy, document status.';
										|it = 'Per questo prodotto non è necessario specificare le serie. La possibilità di specificare le serie può essere influenzata da: tipo di articolo, magazzino, politica dell''indicazione serie, stato del documento.';
										|pl = 'Dla tego towaru serii wskazywać nie trzeba. Na możliwość podania serii mogą wpływać: rodzaj pozycji, magazyn, polityka podania serii, status dokumentu.';
										|tr = 'Bu öğe için bir parti girilmesine gerek yoktur. Bir parti belirtme gerekliliği şunlarda ortaya çıkabilir: ürün türü, ambar, parti belirtme politikası, belge durumu.'");
				ShowMessageBox(,MessageText);
			EndIf;
			EverythingIsFilled = False;
		EndIf;
		
		If EverythingIsFilled
			And CurrentData.ItemVariantsAreUsed
			And Not ValueIsFilled(CurrentData.Characteristic) Then
			If IssueMessages Then
				
				MessageText = NStr("vi = 'Trước khi chỉ ra sê-ri, cần điền đặc tính.';
									|ru = 'Перед указанием серий нужно заполнить характеристику.';
									|en = 'Fill in the variants before specifying the batch.'; fa = 'Fill in the variants before specifying the batch.';
									|it = 'Prima di specificare le serie, è necessario compilare la caratteristica.';
									|pl = 'Przed podaniem seriii trzeba wypełnić charakterystykę.';
									|tr = 'Partiyi belirtmeden önce özellik doldurulmalı.'");
				ShowMessageBox(,MessageText);
			EndIf;
			EverythingIsFilled = False;
		EndIf;
		
		If EverythingIsFilled Then
			ProductsClientLocalization.CheckFieldsBeforeSpecifyingSeries(EverythingIsFilled, Form, SeriesSpecificationParameters, CurrentData, IssueMessages);
		EndIf;
						
	EndIf;
	
	Return EverythingIsFilled;
	
EndFunction

#EndRegion

#Region QualityCertificates

Procedure SetStatusOfNomenclatureCertificatesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ProcessResultOfSettingStatusOfNomenclatureCertificates(Result, AdditionalParameters.List);
	
EndProcedure

// Parameters:
//	Result - See Catalogs.QualityCertificates.SetStatusOfNomenclatureCertificates.
//	List - FormTable - the Form table in which the data is processed.
//
Procedure ProcessResultOfSettingStatusOfNomenclatureCertificates(Result, List)
	
	If Result.Status = "Error" Then
		MessageText = NStr("vi = 'Đã xảy ra lỗi trong quá trình thay đổi trạng thái chứng nhận mặt hàng: %1';
							|ru = 'Возникла ошибка в процессе изменения статуса сертификатов номенклатуры: %1';
							|en = 'An error occurred when changing quality certificate status: %1'; fa = 'An error occurred when changing quality certificate status: %1';
							|it = 'Возникла ошибка в процессе изменения статуса сертификатов номенклатуры: %1';
							|pl = 'An error occurred when changing quality certificate status: %1';
							|tr = 'Kalite belgeleri durumunu değiştirme sürecinde bir hata oluştu: %1'");
		MessageText = StrTemplate(MessageText, Result.BriefErrorDescription);
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	OutputBackgroundJobMessages(Result.Messages);
	
	FillingResult = GetFromTempStorage(Result.ResultAddress);
	
	If FillingResult = Undefined Then
		Return;
	EndIf;
	
	List.Refresh();
	NotifyUserAboutSettingStatus(FillingResult.NumberOfChangedData,
											FillingResult.AmountOfDataToBeProcessed,
											FillingResult.Status);
	
EndProcedure

Procedure NotifyUserAboutSettingStatus(ProcessedItemsCount, TotalCount1, Status)
	
	If ProcessedItemsCount > 0 Then
		TitleText = NStr("vi = 'Trạng thái ""%1"" đã đặt';
						|ru = 'Статус ""%1"" установлен';
						|en = 'Status ""%1"" is set'; fa = 'Status ""%1"" is set';
						|it = 'Lo stato ""%1"" è impostato';
						|pl = 'Ustawiono status ""%1""';
						|tr = 'Durum ""%1"" ayarlandı'");
		TitleText = StrTemplate(TitleText, Status);
		
		MessageText = NStr("vi = 'Đối với %1 trong số %2 chứng nhận mặt hàng đã chọn trong danh sách đã thiết lập trạng thái ""%3""';
							|ru = 'Для %1 из %2 выделенных в списке сертификатов номенклатуры установлен статус ""%3""';
							|en = 'The ""%3"" status is set for %1 out of %2 quality certificates selected in the list'; fa = 'The ""%3"" status is set for %1 out of %2 quality certificates selected in the list';
							|it = 'Для %1 из %2 выделенных в списке сертификатов номенклатуры установлен статус ""%3""';
							|pl = 'The ""%3"" status is set for %1 out of %2 quality certificates selected in the list';
							|tr = 'Kalite belgeleri listesinde seçilen %2''nin %1''i için durum ""%3"" olarak yapılandırıldı'");
		MessageText = StrTemplate(MessageText, ProcessedItemsCount, TotalCount1, Status);
	Else
		TitleText = NStr("vi = 'Trạng thái ""%1"" chưa đặt';
						|ru = 'Статус ""%1"" не установлен';
						|en = 'Status ""%1"" is not set'; fa = 'Status ""%1"" is not set';
						|it = 'Lo stato ""%1"" non è impostato';
						|pl = 'Nie ustawiono statusu ""%1""';
						|tr = 'Durum ""%1"" ayarlanmadı'");
		TitleText = StrTemplate(TitleText, Status);
		
		MessageText = NStr("vi = 'Trạng thái ""%1"" không được đặt cho bất kỳ chứng nhận mặt hàng nào';
							|ru = 'Статус ""%1"" не установлен ни для одного сертификата номенклатуры';
							|en = 'The ""%1"" status is not set for any quality certificate'; fa = 'The ""%1"" status is not set for any quality certificate';
							|it = 'Статус ""%1"" не установлен ни для одного сертификата номенклатуры';
							|pl = 'The ""%1"" status is not set for any quality certificate';
							|tr = '""%1"" durumu herhangi bir kalite belgesi için yapılandırılmadı'");
		MessageText = StrTemplate(MessageText, Status);
	EndIf;
	
	ShowUserNotification(TitleText, , MessageText, PictureLib.Information32);
	
EndProcedure

Procedure OutputBackgroundJobMessages(Messages)
	
	JobMessages = New Array(Messages);
	
	For Each WarningMessage In JobMessages Do
		CommonClient.MessageToUser(WarningMessage.Text, WarningMessage.DataKey);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
