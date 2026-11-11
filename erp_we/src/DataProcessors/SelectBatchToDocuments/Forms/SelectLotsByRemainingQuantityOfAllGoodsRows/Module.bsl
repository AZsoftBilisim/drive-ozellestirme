#Region Variables

&AtClient
Var CachedValues;  //used by the mechanism for processing changes in PM details

&AtClient
Var CurrentCount; //cache of the quantity in the current row to calculate the number of series

&AtClient
Var NeedToAskQuestionBeforeClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetConditionalAppearance();

	ReadOnly = Parameters.ReadOnly;
	If ReadOnly Then
		Items.FinishSeriesInput.Visible = False;
	EndIf; 
	
	Warehouse       = Parameters.Warehouse;
	Premise   = Parameters.Premise;
	ControlledLotReference = Parameters.ControlledLotReference;
	Recorder = Parameters.Recorder;
	AddressInTempStorage = Parameters.AddressInTempStorage;
	SeriesSpecificationParameters = Parameters.SeriesSpecificationParameters;
	
	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined;
	Items.Package.Enabled = Not ThereArePackages;
	
	SearchFields = "Products, Characteristic";
	If SeriesSpecificationParameters.LinkFields.Count() > 0 Then
		
		For Each LinksField In SeriesSpecificationParameters.LinkFields Do
			
			SearchFields = SearchFields + ", " + LinksField;
			
		EndDo;
		
	EndIf;
	
	FillNumberOfPackagesInCache();
	
	// We cache the values for later use of the values from the header (if there are any).
	If Parameters.Property("FieldValuesToIdentifyReferences") Then
		FieldValuesToIdentifyReferences = New FixedStructure(
			Parameters.FieldValuesToIdentifyReferences);
	Else
		FieldValuesToIdentifyReferences = New FixedStructure();
	EndIf;
	
	If FieldValuesToIdentifyReferences.Count() > 0 Then
		ObjectManager = Common.ObjectManagerByFullName(SeriesSpecificationParameters.FullObjectName);
		ReferenceOrder = ObjectManager.OrderToPerformWarehouseOperation(Parameters.FieldValuesToIdentifyReferences);
	Else
		ReferenceOrder = Undefined;
	EndIf;
	
	TheStructureOfTheSearch = New Structure(SearchFields);

	FillPropertyValues(TheStructureOfTheSearch,Parameters);
	
	FoundRows = Object.GoodsCacheOfDocument.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() = 0 Then
		NumberOfTheCurrentGoodsLine = 0;
	Else
		NumberOfTheCurrentGoodsLine = Object.GoodsCacheOfDocument.FindRows(TheStructureOfTheSearch)[0].LineNumber;
	EndIf;
	
	Initialize();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetAccessibilityOfForwardBackButtons();
	NeedToAskQuestionBeforeClosing = True;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified
		And NeedToAskQuestionBeforeClosing Then
		
		StandardProcessing = False;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Danh sách sê-ri đã thay đổi.
			|Lưu lại thay đổi?';
			|ru = 'Список серий был изменен.
			|Сохранить изменения?';
			|en = 'Batch list was changed.
			|Save changes?'; fa = 'Batch list was changed.
			|Save changes?';
			|it = 'L''elenco delle serie è stato modificato.
			|salvare le modifiche?';
			|pl = 'Lista serii została zmieniona.
			|Zapisać zmiany?';
			|tr = 'Parti listesi değiştirildi. 
			|Değişiklikleri kaydet?'");
		
		CommonClient.ShowFormClosingConfirmation(ClosingNotification_, Cancel, Exit, QueryText,
			WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_ItemsBatches" Then
		FoundRows = Object.SetOfSeries.FindRows(New Structure("Series", Source));
		
		If FoundRows.Count() > 0 Then
			SeriesString = FoundRows[0];
			FillPropertyValues(SeriesString, Parameter);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PackageOnChange(Item)
	
	If NumberOfTheCurrentGoodsLine < 1 
	 Or NumberOfTheCurrentGoodsLine > Object.GoodsCacheOfDocument.Count() Then
		Return;
	EndIf;
	
	PackageOnChangeServer();
	
EndProcedure

&AtClient
Procedure PackageClearing(Item, StandardProcessing)
	
	PackageOnChange(Item);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSetOfSeries

&AtClient
Procedure SetOfSeriesSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.SetOfSeriesSeries Then
		ChangeSeriesClient();
	EndIf;
EndProcedure

&AtClient
Procedure SetOfSeriesNumberOfPackagesOnChange(Item)

	PackagingFactor = PackagingFactor(Package, Products);
	
	CurrentData = Items.SetOfSeries.CurrentData;
	CurrentData.Count = CurrentData.NumberOfPackages * PackagingFactor;
	
EndProcedure

&AtClient
Procedure SetOfSeriesOnStartEdit(Item, NewRow, Copy)
	CurrentData = Item.CurrentData;
	
	If Copy Then
		CurrentCount = 0;
	Else
		CurrentCount =  CurrentData.NumberOfPackages;
	EndIf;
	
	If NewRow
		And Not SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
		
		CurrentData.NumberOfPackages = 1;
		CurrentData.Count         = 1;
		
	EndIf;
EndProcedure

&AtClient
Procedure SetOfSeriesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	If Not CancelEdit Then
		Delta = CurrentCount - Items.SetOfSeries.CurrentData.NumberOfPackages;
		SeriesCount = SeriesCount - Delta;
		Items.SetOfSeries.CurrentData.AvailableStock = Items.SetOfSeries.CurrentData.AvailableStock + Delta;
	EndIf;
EndProcedure

&AtClient
Procedure SetOfSeriesBeforeDeleteRow(Item, Cancel)
	CurrentData = Item.CurrentData;
	CurrentCount =  CurrentData.Count;
EndProcedure

&AtClient
Procedure SetOfSeriesAfterDeleteRow(Item)
	SeriesCount = SeriesCount - CurrentCount;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	Modified = False;
	Close();
EndProcedure

&AtClient
Procedure FinishSeriesInput(Command)
	ClearMessages();
    SaveInputToServer();
	If Not Modified Then
		Close(AddressInTempStorage);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		
		NeedToAskQuestionBeforeClosing = False;
		FinishSeriesInput(Undefined);// Saving the modification results.
		
	ElsIf Response = DialogReturnCode.No Then
		
		NeedToAskQuestionBeforeClosing = False;
		Close(Undefined);
		
	EndIf;

EndProcedure

&AtClient
Procedure NextRow(Command)
	ChangeCurLine(1);
	SetAccessibilityOfForwardBackButtons();
EndProcedure

&AtClient
Procedure PreviousString(Command)
	ChangeCurLine(-1);
	SetAccessibilityOfForwardBackButtons();
EndProcedure

&AtClient
Procedure EditAdditionalAttributes(Command)
	CurrentData = Items.SetOfSeries.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Series) Then
		MessageText = NStr("vi = 'Trong dòng đã chọn chưa điền sê-ri do lỗi dữ liệu về số dư. Hãy liên hệ với người quản trị.';
							|ru = 'В выбранной строке не заполнена серия из-за ошибки в данных об остатках. Обратитесь к администратору.';
							|en = 'Batch is not specified in the selected line due to the balance data error. Please contact the administrator.'; fa = 'Batch is not specified in the selected line due to the balance data error. Please contact the administrator.';
							|it = 'La riga selezionata non contiene una serie a causa di un errore nei dati sui saldi. Contatta il tuo amministratore.';
							|pl = 'W wybranym wierszu nie jest wypełniona seria ze względu na błędy w danych o pozostałościach. Skontaktuj się z administratorem.';
							|tr = 'Bakiye verilerindeki hata nedeniyle seçilen satırda parti doldurulmadı. Yöneticiyle iletişime geç.'");
		Return;
	EndIf;
	
	SeriesFillValues = New Structure;
	SeriesFillValues.Insert("ProductKind", ProductKind);
	SeriesFillValues.Insert("Number", CurrentData.Number);
	SeriesFillValues.Insert("ValidUntil_", CurrentData.ValidUntil_);
	
	SeriesShapeParameters = New Structure;
	SeriesShapeParameters.Insert("FillingValues",SeriesFillValues);
	SeriesShapeParameters.Insert("Key",CurrentData.Series);
	
	OpenForm("Catalog.ItemsBatches.Form.ItemForm",SeriesShapeParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInByFEFO(Command)
	If Count = 0 Then
		ShowMessageBox(,NStr("vi = 'Chứng từ không cho biết số lượng hàng hóa. Điền thông tin là không thể.';
							|ru = 'В документе не указано количество товара. Заполнение по FEFO не возможно.';
							|en = 'Quantity of goods is not specified in the document. Cannot populate by FEFO.'; fa = 'Quantity of goods is not specified in the document. Cannot populate by FEFO.';
							|it = 'Il documento non indica la quantità di merci. Non è possibile eseguire la compilazione con FEFO';
							|pl = 'W dokumencie nie określono ilości towaru. Wypełnienie według FEFO jest niemożliwe.';
							|tr = 'Belge ürün miktarını içermemektedir. FEFO tarafından doldurulması mümkün değildir.'"));
		Return;
	EndIf;	
	FillInByFEFOServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeriesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeriesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Count");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeriesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeriesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Count");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeriesAvailableStock.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetOfSeries.AvailableStock");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkNegatives", True);

EndProcedure

#Region Other

&AtServer
Procedure FillNumberOfPackagesInCache()
	
	StructureFromRepository = GetFromTempStorage(Parameters.AddressInTempStorage);
	
	If SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined Then
		
		SeriesSelectionText = "";
		ProductSelectionText = "";
		
		For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
			ProductSelectionText = ProductSelectionText + "
			|	TableOfGoods." + ArrRow + ",";
			
			SeriesSelectionText = SeriesSelectionText + "
			|	TableOfSeries." + ArrRow + ",";
		EndDo;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableOfSeries.LineNumber             AS LineNumber,
		|	TableOfSeries.ProductSelectionText,
		|	TableOfSeries.Products            AS Products,
		|	TableOfSeries.Characteristic          AS Characteristic,
		|	TableOfSeries.Series                   AS Series,
		|	TableOfSeries.Count              AS Count
		|INTO TableOfSeries
		|FROM
		|	&TableOfSeries AS TableOfSeries
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.DocumentRowsNumbers    AS DocumentRowsNumbers,
		|	TableOfGoods.ProductSelectionText,
		|	TableOfGoods.Products            AS Products,
		|	TableOfGoods.Characteristic          AS Characteristic,
		|	TableOfGoods.Package                AS Package,
		|	TableOfGoods.BatchesIndicationStatus     AS BatchesIndicationStatus,
		|	TableOfGoods.Count              AS Count
		|INTO TableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.LineNumber                                   AS LineNumber,
		|	TableOfGoods.ProductSelectionText,
		|	TableOfGoods.Products                                  AS Products,
		|	TableOfGoods.Characteristic                                AS Characteristic,
		|	TableOfGoods.Series                                         AS Series,
		|	TableOfGoods.Count                                    AS Count,
		|	TableOfGoods.Count / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages
		|FROM
		|	TableOfSeries AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.DocumentRowsNumbers                          AS DocumentRowsNumbers,
		|	TableOfGoods.ProductSelectionText,
		|	TableOfGoods.Products                                  AS Products,
		|	TableOfGoods.Characteristic                                AS Characteristic,
		|	TableOfGoods.BatchesIndicationStatus                           AS BatchesIndicationStatus,
		|	TableOfGoods.Count                                    AS Count,
		|	TableOfGoods.Count / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages
		|FROM
		|	TableOfGoods AS TableOfGoods";
		
		Query.Text = StrReplace(Query.Text, "TableOfGoods.ProductSelectionText,", ProductSelectionText);
		Query.Text = StrReplace(Query.Text, "TableOfSeries.ProductSelectionText,", SeriesSelectionText);
		
		Query.Text = StrReplace(Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"TableOfGoods.Package",
				"TableOfGoods.Products"));
		
		Query.SetParameter("TableOfSeries",   StructureFromRepository.TableOfSeries);
		Query.SetParameter("TableOfGoods", StructureFromRepository.TableOfGoods);
		
		Result_Query = Query.ExecuteBatch();
		
		Object.CacheDocumentBatch.Load(Result_Query[2].Unload());
		Object.GoodsCacheOfDocument.Load(Result_Query[3].Unload());
		
	Else
		
		Object.CacheDocumentBatch.Load(StructureFromRepository.TableOfSeries);
		Object.GoodsCacheOfDocument.Load(StructureFromRepository.TableOfGoods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByFEFOServer()
	
	QuantityToDistribution = Count;
	
	PackagingFactor = PackagingFactor(Package, Products);
	
	For Each RowOfTables In Object.SetOfSeries Do
		If QuantityToDistribution <= 0 Then
			RowOfTables.AvailableStock   = RowOfTables.AvailableStock + RowOfTables.NumberOfPackages;
			RowOfTables.NumberOfPackages = 0;
			RowOfTables.Count = 0;
			Continue;
		EndIf;
		
		QuantityPerRow =  Min(RowOfTables.AvailableStock + RowOfTables.NumberOfPackages, QuantityToDistribution);
		If QuantityPerRow < 0 Then
			RowOfTables.AvailableStock   = RowOfTables.AvailableStock + RowOfTables.NumberOfPackages;
			RowOfTables.NumberOfPackages = 0;
		Else
			RowOfTables.AvailableStock   = RowOfTables.AvailableStock + RowOfTables.NumberOfPackages - QuantityPerRow;
			RowOfTables.NumberOfPackages = QuantityPerRow;
			QuantityToDistribution = QuantityToDistribution - QuantityPerRow; 
		EndIf;
		
		RowOfTables.Count = RowOfTables.NumberOfPackages * PackagingFactor;

	EndDo;
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
EndProcedure

&AtServer
Procedure SaveSeriesInputInCache()
	
	ThereIsSignOfIndicatingSeries = SeriesSpecificationParameters.LinkFields.Find("SpecifyBatches") <> Undefined;
	
	TableOfSeries = Object.SetOfSeries.Unload();
	
	TableOfSeries.GroupBy("Series,Number,ValidUntil_", "Count,NumberOfPackages");
	
	IndexOf = TableOfSeries.Count();
	
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		RowOfTables = TableOfSeries[IndexOf];
		If RowOfTables.NumberOfPackages = 0 Then
			TableOfSeries.Delete(RowOfTables);
		EndIf;
	EndDo;
	
	RowOfGoods = Object.GoodsCacheOfDocument[NumberOfTheCurrentGoodsLine-1];
	
	SearchFieldText = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		SearchFieldText = SearchFieldText + ", " + ArrRow;
	EndDo;
		
	TheStructureOfTheSearch = New Structure("Products,Characteristic" + SearchFieldText);
	
	FillPropertyValues(TheStructureOfTheSearch,RowOfGoods);
	
	RowOfGoods.Package = Package;
	
	FoundSeriesRows_ = Object.CacheDocumentBatch.FindRows(TheStructureOfTheSearch);
	
	For Each RowOfTables In FoundSeriesRows_ Do
		Object.CacheDocumentBatch.Delete(RowOfTables);
	EndDo;
	
	For Each RowOfTables In TableOfSeries Do
		NewRow = Object.CacheDocumentBatch.Add();
		FillPropertyValues(NewRow,RowOfGoods);
		FillPropertyValues(NewRow,RowOfTables);
		If ThereIsSignOfIndicatingSeries Then
			NewRow.SpecifyBatches = True;
		EndIf;
		NewRow.Package = Package;
	EndDo;
	
	If ThereIsSignOfIndicatingSeries Then
		If TableOfSeries.Count() > 0 Then
			RowOfGoods.SpecifyBatches = True;
		Else
			RowOfGoods.SpecifyBatches = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveInputToServer()
	
	SaveSeriesInputInCache();
	
	ReturnStructure = New Structure;
	TableOfSeries = Object.CacheDocumentBatch.Unload();
	
	GroupingColumns =
	"Products,
	|Characteristic,
	|ProductsRecordingAsReceived,
	|CharacteristicRecordingAsReceived,
	|Package,
	|ZoomRatio,
	|Warehouse,
	|RegistrationOption,
	|Series,
	|DoNotShip";
	
	TotalingColumns =
	"Count,
	|NumberOfPackages";
	
	If SeriesSpecificationParameters.LinkFields.Count() > 0 Then
		
		For Each LinksField In SeriesSpecificationParameters.LinkFields Do
			
			If LinksField <> "Warehouse"
				And LinksField <> "DoNotShip"
				And LinksField <> "RegistrationOption" Then
				
				GroupingColumns = GroupingColumns + ", " + LinksField;
				
			EndIf;
			
		EndDo;
		
	EndIf;
		
	TableOfSeries.GroupBy(GroupingColumns, TotalingColumns);
	
	For Each CurrRow In TableOfSeries Do
		If CurrRow.ZoomRatio <> 0 And CurrRow.ZoomRatio <> 1 Then
			CurrRow.Count = CurrRow.Count * CurrRow.ZoomRatio;
			CurrRow.NumberOfPackages = CurrRow.NumberOfPackages * CurrRow.ZoomRatio;
		EndIf;
	EndDo;
	
	ReturnStructure.Insert("TableOfSeries", TableOfSeries);
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
		ReturnStructure.Insert("TableOfGoods", Object.GoodsCacheOfDocument.Unload());
	EndIf;
	
	PutToTempStorage(ReturnStructure, AddressInTempStorage);
	Modified = False;
	
EndProcedure

&AtClient
Procedure SetAccessibilityOfForwardBackButtons()
	If  NumberOfTheCurrentGoodsLine > 1 Then
		Items.BackButtonGroup.CurrentPage = Items.PageBackButton;
	Else
		Items.BackButtonGroup.CurrentPage = Items.PageButtonBackEmpty;
	EndIf;
	
	If NumberOfTheCurrentGoodsLine < Object.GoodsCacheOfDocument.Count() Then
		Items.GroupButtonForward.CurrentPage = Items.PageForwardButton;
	Else
		Items.GroupButtonForward.CurrentPage = Items.PageButtonForwardEmpty;
	EndIf;	
EndProcedure

&AtServer
Procedure Initialize(RecalculatePackages = False)
	
	If NumberOfTheCurrentGoodsLine < 1 
	 Or NumberOfTheCurrentGoodsLine > Object.GoodsCacheOfDocument.Count() Then
		Return;
	EndIf;
	
	RowOfGoods = Object.GoodsCacheOfDocument[NumberOfTheCurrentGoodsLine-1];
	
	ConnectionFieldValues = New Structure(StrConcat(SeriesSpecificationParameters.LinkFields,","));
	ConnectionFieldValues.Insert("Products");	
	ConnectionFieldValues.Insert("Characteristic");	
	FillPropertyValues(ConnectionFieldValues, RowOfGoods);
	
	ProductAttributes = New Structure;
	ProductAttributes.Insert("ProductKind", "ProductKind");
	ProductAttributes.Insert("UnitOfMeasurePresentation", "UnitOfMeasure.Description");
	ProductAttributes.Insert("ExpirationDate_", "ExpirationDate_");
	ProductAttributes.Insert("ShelfLifeUnitOfMeasure", "ShelfLifeUnitOfMeasure");
	ProductAttributes.Insert("TypeOfMeasuredValueOfProductRange", "UnitOfMeasure.MeasuredValueType");
	
	ProductAttributes =	Common.ObjectAttributesValues(ConnectionFieldValues.Products, ProductAttributes); 
	
	If ValueIsFilled(RowOfGoods.Package) Then
		If ProductAttributes.TypeOfMeasuredValueOfProductRange <> Enums.TypesOfMeasuredValues.NumberOfPieces 
			 Or ProductAttributes.TypeOfMeasuredValueOfProductRange = Enums.TypesOfMeasuredValues.NumberOfPieces
				And Common.ObjectAttributeValue(RowOfGoods.Package, "MeasuredValueType") = Enums.TypesOfMeasuredValues.Package Then
			Package = RowOfGoods.Package;
		Else
			Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
	Else
		Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	EndIf;
	
	VHFWarehouses = SeriesSpecificationParameters.LinkFields.Find("Warehouse") <> Undefined;
	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined;
	ThereIsSignOfIndicatingSeries = SeriesSpecificationParameters.LinkFields.Find("SpecifyBatches") <> Undefined;
	ThereIsDesignOption = SeriesSpecificationParameters.LinkFields.Find("RegistrationOption") <> Undefined;
	ThereAreGoodsUnshipped = SeriesSpecificationParameters.LinkFields.Find("DoNotShip") <> Undefined;
	
	If ValueIsFilled(Package) Then;
		PackingDetails = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Package, Products, "Description"); 
		ProductAttributes.Insert("UnitOfMeasurePresentation", PackingDetails.Description);
	Else
		PackingDetails = New Structure("ZoomRatio, Description", 1, ProductAttributes.UnitOfMeasurePresentation);
	EndIf;
	
	Count = RowOfGoods.Count / PackingDetails.ZoomRatio;
	LineNumbersPresentation = RowOfGoods.DocumentRowsNumbers;
	
	If Not VHFWarehouses Then
		CurrentWarehouse = Warehouse;
	Else
		CurrentWarehouse = RowOfGoods.Warehouse;
	EndIf;
	
	ConnectionFieldValues.Insert("Warehouse", CurrentWarehouse); 
	
	SeriesUseSettings = New FixedStructure(
		Catalogs.ItemKinds.SeriesUseSettings(ProductAttributes.ProductKind,SeriesSpecificationParameters,ConnectionFieldValues));
		

	ProductsServer.CheckWhetherSeriesIndicationFormCanBeOpened(SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues);
	
	TitleQuantityInDocument = NStr("vi = 'Cần để giao hàng, %UnitOfMeasure%';
									|ru = 'Необходимо для отгрузки, %UnitOfMeasure%';
									|en = 'Required for shipping, %UnitOfMeasure%'; fa = 'Required for shipping, %UnitOfMeasure%';
									|it = 'Necessario per la spedizione, %UnitOfMeasure%';
									|pl = 'Niezbędne dla wysyłki, %UnitOfMeasure%';
									|tr = 'Sevkiyat için gerekli, %UnitOfMeasure%'");
	TitleNumberOfSeries      = NStr("vi = 'Đã chọn từ sê-ri, %UnitOfMeasure%';
									|ru = 'Подобрано из серий, %UnitOfMeasure%';
									|en = 'Picked from the batch, %UnitOfMeasure%'; fa = 'Picked from the batch, %UnitOfMeasure%';
									|it = 'Selezionato dalle serie, %UnitOfMeasure%';
									|pl = 'Dobrano z serii, %UnitOfMeasure%';
									|tr = 'Partiden seçildi, %UnitOfMeasure%'");
	ColumnHeadingQuantity = "";
	If Not Parameters.Property("ColumnHeadingQuantity", ColumnHeadingQuantity) Then
		ColumnHeadingQuantity    = NStr("vi = 'Cần giao hàng';
										|ru = 'К отгрузке';
										|en = 'To ship'; fa = 'برای ارسال';
										|it = 'Da spedire';
										|pl = 'Do wysłania';
										|tr = 'Sevk edilecek'"); 
	EndIf;
	ColumnHeadingQuantity    = ColumnHeadingQuantity + ", " + ProductAttributes.UnitOfMeasurePresentation;
	
	OwnGoodsPresentation = NStr("vi = '%GoodsPresentation%';
								|ru = '%GoodsPresentation%';
								|en = '%GoodsPresentation%'; fa = '%GoodsPresentation%';
								|it = '%GoodsPresentation%';
								|pl = '%GoodsPresentation%';
								|tr = '%GoodsPresentation%'");
	
	TitleQuantityInDocument = StrReplace(TitleQuantityInDocument,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
	TitleNumberOfSeries      = StrReplace(TitleNumberOfSeries,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
	
	If SeriesSpecificationParameters.ItSWarrant Then
		OptionOfDataReceivingFromRegisters = "OrderSeriesFromRemainder";
	Else
		If ValueIsFilled(ReferenceOrder)
			And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined
			And SeriesUseSettings.AccountForRemainingSeries
			And SeriesUseSettings.SpecifyWhenPlanningShipment Then
			OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder";
		Else
			OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder";
		EndIf;
	EndIf;
	
	If OptionOfDataReceivingFromRegisters = "OrderSeriesFromRemainder"
		Or OptionOfDataReceivingFromRegisters = "OrderInvoiceSeriesFromRemainder" Then
		
		FreeBalanceHeader = NStr("vi = 'Số dư tự do, %UnitOfMeasure%';
								|ru = 'Свободный остаток, %UnitOfMeasure%';
								|en = 'Available inventory, %UnitOfMeasure%'; fa = 'Available inventory, %UnitOfMeasure%';
								|it = 'Saldo libero, %UnitOfMeasure%';
								|pl = 'Wolny ostatek, %UnitOfMeasure%';
								|tr = 'Serbest bakiye, %UnitOfMeasure%'");
		If TypeOf(Warehouse) = Type("CatalogRef.BusinessStructure") Then
			Title = NStr("vi = 'Chọn sê-ri theo số dư trong sản xuất';
						|ru = 'Подбор серий по остаткам в производстве';
						|en = 'Select batch by remaining quantity in production'; fa = 'Select batch by remaining quantity in production';
						|it = 'Selezione serie per saldi nella produzione';
						|pl = 'Dobór serii według pozostałości w produkcji';
						|tr = 'Üretim bakiyelerine göre parti seçimi'");
		Else
			Title = NStr("vi = 'Chọn sê-ri theo số dư trong kho';
						|ru = 'Подбор серий по остаткам на складе';
						|en = 'Select batch by warehouse stock'; fa = 'انتخاب بچ بر اساس موجودی انبار';
						|it = 'Selezione serie per saldi di magazzino';
						|pl = 'Wybór serii wg ostatków w magazynie';
						|tr = 'Ambardaki stoka göre parti seçimi'");
		EndIf;
		
	ElsIf OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder" 	Then
		
		FreeBalanceHeader = NStr("vi = 'Số dư theo đơn hàng, %UnitOfMeasure%';
								|ru = 'Остаток по заказу, %UnitOfMeasure%';
								|en = 'Order balance, %UnitOfMeasure%'; fa = 'Order balance, %UnitOfMeasure%';
								|it = 'Saldo su ordine, %UnitOfMeasure%';
								|pl = 'Pozostałość dla zlecenia, %UnitOfMeasure%';
								|tr = 'Sipariş bakiyesi, %UnitOfMeasure%'");
		Title                  = NStr("vi = 'Chọn sê-ri theo đơn hàng';
										|ru = 'Подбор серий по заказу';
										|en = 'Pick order batch'; fa = 'Pick order batch';
										|it = 'Selezione serie su ordine';
										|pl = 'Dobór serii według zlecenia';
										|tr = 'Siparişe göre parti seçimi'");

	ElsIf OptionOfDataReceivingFromRegisters = "OrderSeriesFromInvoice" Then
		
		FreeBalanceHeader = NStr("vi = 'Số dư theo lệnh, %UnitOfMeasure%';
								|ru = 'Остаток по распоряжению, %UnitOfMeasure%';
								|en = 'Reference balance, %UnitOfMeasure%'; fa = 'Reference balance, %UnitOfMeasure%';
								|it = 'Saldo su disposizione, %UnitOfMeasure%';
								|pl = 'Reszta wg zamówienia, %UnitOfMeasure%';
								|tr = 'Sipariş bakiyesi, %UnitOfMeasure%'");
		Title                  = NStr("vi = 'Chọn sê-ri theo lệnh giao hàng';
										|ru = 'Подбор серий по распоряжению на отгрузку';
										|en = 'Pick batch by the shipment reference'; fa = 'Pick batch by the shipment reference';
										|it = 'Selezione serie per disposizione alla spedizione';
										|pl = 'Dobór serii według zamówienia na wysyłkę';
										|tr = 'Sevkiyat siparişine göre parti seçimi'");
		
	ElsIf TypeOf(Warehouse) = Type("CatalogRef.BusinessStructure") Then
		Title = NStr("vi = 'Chọn sê-ri theo số dư trong sản xuất';
					|ru = 'Подбор серий по остаткам в производстве';
					|en = 'Select batch by remaining quantity in production'; fa = 'Select batch by remaining quantity in production';
					|it = 'Selezione serie per saldi nella produzione';
					|pl = 'Dobór serii według pozostałości w produkcji';
					|tr = 'Üretim bakiyelerine göre parti seçimi'");
	EndIf;
	
	FreeBalanceHeader = StrReplace(FreeBalanceHeader,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
	
	Products = RowOfGoods.Products;
	OwnGoodsPresentation = StrReplace(OwnGoodsPresentation,"%GoodsPresentation%",ProductsClientServer.ProductPresentation(RowOfGoods.Products, RowOfGoods.Characteristic));
	
	Items.SetOfSeriesNumberOfPackages.Title = ColumnHeadingQuantity;
	Items.SetOfSeriesAvailableStock.Title   = FreeBalanceHeader;
	Items.Count.Title              = TitleQuantityInDocument;
	Items.SeriesCount.Title         = TitleNumberOfSeries;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.SettingName <> "UseRFIDTags" Then
			
			SeriesFormField = Items[DataProcessors.SelectBatchToDocuments.NamesOfSeriesElements(LongDesc.AttributeName).SetOfSeries]; // FormField
			SeriesFormField.Visible        = LongDesc.Use; 
			
			If Not IsBlankString(LongDesc.Format) Then
				SeriesFormField.Format               = LongDesc.Format;
			EndIf;	
			
			If Not IsBlankString(LongDesc.PresentationOfFormatStringInHeader) Then
				ColumnHeaderPresentation = NStr("vi = '%AttributeRepresentation% (%FormatPresentation%)';
												|ru = '%AttributeRepresentation% (%FormatPresentation%)';
												|en = '%AttributeRepresentation% (%FormatPresentation%)'; fa = '%AttributeRepresentation% (%FormatPresentation%)';
												|it = '%AttributeRepresentation% (%FormatPresentation%)';
												|pl = '%AttributeRepresentation% (%FormatPresentation%)';
												|tr = '%AttributeRepresentation% (%FormatPresentation%)'");
				ColumnHeaderPresentation = StrReplace(ColumnHeaderPresentation, "%AttributeRepresentation%", LongDesc.AttributeRepresentation);
				ColumnHeaderPresentation = StrReplace(ColumnHeaderPresentation, "%FormatPresentation%", LongDesc.PresentationOfFormatStringInHeader);
				
				SeriesFormField.Title        = ColumnHeaderPresentation; 
			EndIf;

		EndIf;
	EndDo;
	
	Items.SetOfSeriesNumberOfPackages.Visible = SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch;
		
	// Formation of a table of tableseries	

	QueryTextTemplate2 = 
	"SELECT
	|	TableOfSeries.Series,
	|	&PackingFields
	|INTO TableOfSeries
	|FROM
	|	&TableOfSeries AS TableOfSeries
	|WHERE
	|  	TableOfSeries.Products = &Products
	|  	AND TableOfSeries.Characteristic = &Characteristic
	|	AND TableOfSeries.Purpose = &PurposeOfTS
	|	AND &ConditionVHFWarehouses
	|	AND &ConditionIsPackaging
	|	AND &ConditionThereIsDesignOption
	|	AND &ConditionIsNonLoadable
	|";
	
	ReplacementText = "";	
	If ThereIsSignOfIndicatingSeries Then
		ReplacementText = "
			|  	TableOfSeries.SpecifyBatches, 
			|	CASE WHEN TableOfSeries.SpecifyBatches = &SpecifyBatches
			|			THEN TableOfSeries.Count
			|			ELSE 0
			|	END AS Count, ";
		If ThereArePackages Then
			ReplacementText = ReplacementText + "
				|	CASE WHEN TableOfSeries.SpecifyBatches = &SpecifyBatches
				|			THEN TableOfSeries.NumberOfPackages
				|			ELSE 0
				|	END AS NumberOfPackages ";
		Else
			ReplacementText = ReplacementText + "
				|	CASE WHEN TableOfSeries.SpecifyBatches = &SpecifyBatches
				|			THEN TableOfSeries.Count
				|			ELSE 0
				|	END AS NumberOfPackages ";
		EndIf;
	ElsIf ThereArePackages Then
		ReplacementText = "
		|	TableOfSeries.Count,
		|	TableOfSeries.NumberOfPackages ";
	Else
		ReplacementText = "
		|	TableOfSeries.Count,
		|	TableOfSeries.Count AS NumberOfPackages ";
	EndIf;
	QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&PackingFields", ReplacementText);
	
	If VHFWarehouses Then
		ReplacementText = "AND TableOfSeries.Warehouse = &Warehouse";
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "AND &ConditionVHFWarehouses", ReplacementText);
	Else	
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "AND &ConditionVHFWarehouses", "");
	EndIf;
	
	If ThereIsDesignOption Then
		ReplacementText = "AND TableOfSeries.RegistrationOption = &RegistrationOption";
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "AND &ConditionThereIsDesignOption", ReplacementText);
	Else	
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "AND &ConditionThereIsDesignOption", "");
	EndIf;
	
	If ThereAreGoodsUnshipped Then
		ReplacementText = "AND TableOfSeries.DoNotShip = &DoNotShip";
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "AND &ConditionIsNonLoadable", ReplacementText);
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "AND &ConditionIsNonLoadable", "");
	EndIf;

	QueryTextTableSeries_ = QueryTextTemplate2;
	If ThereArePackages Then
		ReplacementText = "AND TableOfSeries.Package = &Package";
		QueryTextTableSeries_ = StrReplace(QueryTextTableSeries_, "AND &ConditionIsPackaging", ReplacementText);
	Else
		QueryTextTableSeries_ = StrReplace(QueryTextTableSeries_, "AND &ConditionIsPackaging", "");
	EndIf;

	QueryTextCommunicationFieldSeriesTable = QueryTextTemplate2;
	QueryTextCommunicationFieldSeriesTable = StrReplace(QueryTextCommunicationFieldSeriesTable, "INTO TableOfSeries", "INTO CommunicationFieldSeriesTable");
	QueryTextCommunicationFieldSeriesTable = StrReplace(QueryTextCommunicationFieldSeriesTable, "AND &ConditionIsPackaging", "");

	QueryText = QueryTextTableSeries_ + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + QueryTextCommunicationFieldSeriesTable;
	
	ParametersToAdd = New Array;
	
	If SeriesSpecificationParameters.LinkFields.Count() > 0 Then
		
		For Each LinksField In SeriesSpecificationParameters.LinkFields Do
			
			If LinksField <> "Warehouse"
				And LinksField <> "DoNotShip"
				And LinksField <> "SpecifyBatches"
				And LinksField <> "Purpose" Then
				
				QueryText = QueryText + "
				|  	AND TableOfSeries." + LinksField + " = &" + LinksField;
				
				ParametersToAdd.Add(LinksField);
				
			EndIf;
				
		EndDo;
		
	EndIf;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

	// Formation of a data table of registers	
	
	QueryText = QueryText + DataProcessors.SelectBatchToDocuments.TextOfRequestToGenerateTableRegisterData(OptionOfDataReceivingFromRegisters, Warehouse);
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	// Combining tables of tables of series and data of registers	
	
	QueryText = QueryText + "
	|SELECT
	|	SeriesTableWithResidues.Series AS Series,
	|	SUM(SeriesTableWithResidues.AvailableStock/&PackagingFactor) AS AvailableStock,
	|	SUM(SeriesTableWithResidues.Count) AS Count,
	|	SUM(CASE
	|			WHEN &RecalculatePackages
	|				THEN SeriesTableWithResidues.Count / &PackagingFactor
	|			ELSE SeriesTableWithResidues.NumberOfPackages
	|		END) AS NumberOfPackages,
	|	&RequestTextDetailsAndSelection
	|FROM
	|	(SELECT
	|		DataOfRegister.Series AS Series,
	|		DataOfRegister.AvailableStock AS AvailableStock,
	|		0 AS Count,
	|		0 AS NumberOfPackages
	|	FROM
	|		DataOfRegister AS DataOfRegister
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfSeries.Series,
	|		-TableOfSeries.Count,
	|		0,
	|		0
	|	FROM
	|		TableOfSeries AS TableOfSeries
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfSeries.Series,
	|		0,
	|		TableOfSeries.Count,
	|		TableOfSeries.NumberOfPackages
	|	FROM
	|		CommunicationFieldSeriesTable AS TableOfSeries) AS SeriesTableWithResidues
	|
	|GROUP BY
	|	SeriesTableWithResidues.Series,
	|	&RequestTextDetailsAndDimensions
	|
	|HAVING
	|	(SUM(SeriesTableWithResidues.AvailableStock) > 0
	|		OR SUM(SeriesTableWithResidues.Count) > 0)
	|
	|ORDER BY
	|	ValidUntil_,
	|	Number";
	
	QueryText = StrReplace(QueryText, "&RequestTextDetailsAndSelection",
		DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("SeriesTableWithResidues", SeriesUseSettings, False));
		
	QueryText = StrReplace(QueryText, "&RequestTextDetailsAndDimensions",
		DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("SeriesTableWithResidues", SeriesUseSettings, True));
	
	Query = New Query;
	Query.Text = QueryText;

	Query.SetParameter("TableOfSeries",Object.CacheDocumentBatch.Unload());
	Query.SetParameter("Products",RowOfGoods.Products);
	Query.SetParameter("Characteristic",RowOfGoods.Characteristic);
	
	If RowOfGoods.Property("Purpose")
		Or RowOfGoods.Property("AssignmentSender") Then
		If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined
			And SeriesSpecificationParameters.ThisIsOrder
			And RowOfGoods.WithAssignment Then
			Purpose = Catalogs.Assignments.EmptyRef();
		ElsIf SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined
			And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined Then //this is the movement of goods or transfer to production
			Purpose = RowOfGoods.AssignmentSender;
		Else
			Purpose = RowOfGoods.Purpose;
		EndIf;
		TheAppointmentOfResidues = Purpose;
	Else
		TheAppointmentOfResidues = Catalogs.Assignments.EmptyRef();
	EndIf;
	Query.SetParameter("Purpose", TheAppointmentOfResidues);
	Query.SetParameter("PurposeOfTS", RowOfGoods.Purpose);
			
	Query.SetParameter("AllSeries",False);
	If Not VHFWarehouses Then
		Query.SetParameter("Warehouse",Warehouse);
	Else
		Query.SetParameter("Warehouse",RowOfGoods.Warehouse);
	EndIf;
	
	If OptionOfDataReceivingFromRegisters = "InvoiceOfSeriesFromOrder"
		And FieldValuesToIdentifyReferences.Count() > 0 Then
		FieldValuesByLine = New Structure;
		For Each ArrRow In SeriesSpecificationParameters.FieldNamesForOrderDefinition Do
			SeparatorLocation = StrFind(ArrRow, "_");		
			If SeparatorLocation = 0 Then
				FieldValuesByLine.Insert(ArrRow, FieldValuesToIdentifyReferences[ArrRow]);
			Else
				FieldName = Right(ArrRow, StrLen(ArrRow)- SeparatorLocation);
				FieldValuesByLine.Insert(ArrRow, RowOfGoods[FieldName]);
			EndIf;
		EndDo;
		ObjectManager = Common.ObjectManagerByFullName(SeriesSpecificationParameters.FullObjectName);
		CommandLines = ObjectManager.OrderToPerformWarehouseOperation(FieldValuesByLine);
	 	Query.SetParameter("ReferenceOrder", CommandLines);
	EndIf;
	
	For Each AdditionalParameter In SeriesSpecificationParameters.ParametersForGettingDataFromRegisters Do
		Query.SetParameter(AdditionalParameter.Key, AdditionalParameter.Value);
	EndDo;
	
	If ThereIsDesignOption Then
		Query.SetParameter("RegistrationOption", RowOfGoods.RegistrationOption);
	EndIf;
	
	If ThereAreGoodsUnshipped Then
		Query.SetParameter("DoNotShip", RowOfGoods.DoNotShip);
	EndIf;
	
	Query.SetParameter("ControlledLotReference", ControlledLotReference);
	Query.SetParameter("Premise",Premise);
	Query.SetParameter("Recorder",Recorder);
	
	For Each ParameterToAdd In ParametersToAdd Do
		
		Query.SetParameter(ParameterToAdd, RowOfGoods[ParameterToAdd]);
		
	EndDo;
	
	Query.SetParameter("PackagingFactor", PackingDetails.ZoomRatio);
	Query.SetParameter("RecalculatePackages", RecalculatePackages);
	
	Object.SetOfSeries.Load(Query.Execute().Unload());
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
	If Object.SetOfSeries.Count() = 0 Then
		Items.GroupSeriesPages.CurrentPage = Items.PageNoBalance;
		Items.AllocateBalance.Visible = False;
		Items.FillInByFEFO.Visible = False;
		Items.Package.Visible = False;
	Else
		
		Items.Package.Visible = True;
		If SeriesUseSettings.BatchesAccountingByFEFO 
			And Enums.WarehouseTransactions.ThereIsShipment(SeriesSpecificationParameters.WarehouseTransactions) Then
			Items.FillInByFEFO.Visible = True;
		Else
			Items.FillInByFEFO.Visible = False;
		EndIf;
		Items.AllocateBalance.Visible = SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch;
		
		Items.GroupSeriesPages.CurrentPage = Items.SeriesPage;
		
		// Additional banking details
		TMPropertyManagement.AddColumnsOfAdditionalDetails(
			SeriesUseSettings,
			ThisForm,
			"Object.SetOfSeries",
			"SetOfSeries",
			"SetOfSeriesAvailableStock",
			True);
			
		TMPropertyManagement.FillInColumnsOfAdditionalDetails(
			ThisForm,
			"Object.SetOfSeries",
			"Series");
			
	EndIf;
		
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
	WorkScopePresentation = NStr("vi = 'Hàng hóa %CurrentRowNumber% / %TotalProducts_%:';
								|ru = 'Товар %CurrentRowNumber% из %TotalProducts_%:';
								|en = 'Goods %CurrentRowNumber% out of %TotalProducts_%:'; fa = 'Goods %CurrentRowNumber% out of %TotalProducts_%:';
								|it = 'Merce %CurrentRowNumber% di %TotalProducts_%:';
								|pl = 'Towar %CurrentRowNumber% z %TotalProducts_%:';
								|tr = '%TotalProducts_%''dan %CurrentRowNumber% ürünü'");
	WorkScopePresentation = StrReplace(WorkScopePresentation,"%CurrentRowNumber%",String(NumberOfTheCurrentGoodsLine));
	WorkScopePresentation = StrReplace(WorkScopePresentation,"%TotalProducts_%",Object.GoodsCacheOfDocument.Count());
	
EndProcedure

&AtServer
Procedure ChangeCurLine(Direction)
	
	SaveSeriesInputInCache();
	NumberOfTheCurrentGoodsLine = NumberOfTheCurrentGoodsLine + Direction;
	
	Package = Undefined;
	Initialize(True);
	
EndProcedure

&AtClient
Procedure ChangeSeriesClient()
	
	CurrentData = Items.SetOfSeries.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SeriesFillValues = New Structure;
	SeriesFillValues.Insert("ProductKind", ProductKind);
	SeriesFillValues.Insert("Number", CurrentData.Number);
	SeriesFillValues.Insert("ValidUntil_", CurrentData.ValidUntil_);
	
	SeriesShapeParameters = New Structure;
	SeriesShapeParameters.Insert("FillingValues",SeriesFillValues);
	SeriesShapeParameters.Insert("Key",CurrentData.Series);
	
	OpenForm("Catalog.ItemsBatches.Form.ItemForm",SeriesShapeParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AllocateBalance(Command)
	QuantityToDistribution = Count - SeriesCount;
	
	If Count = 0 Then
		ShowMessageBox(,NStr("vi = 'Trong chứng từ, chưa chỉ ra số lượng hàng hóa. Không thể phân bổ theo sê-ri.';
							|ru = 'В документе не указано количество товара. Распределение по сериям невозможно.';
							|en = 'Quantity of goods is not specified in the document. Cannot allocate by batch.'; fa = 'Quantity of goods is not specified in the document. Cannot allocate by batch.';
							|it = 'Il documento non indica la quantità di merci. La distribuzione per serie non è possibile.';
							|pl = 'W dokumencie nie określono ilości towaru. Podział według serii jest niemożliwy.';
							|tr = 'Belgede ürünlerin miktarı belirtilmedi. Partilere göre dağıtım mümkün değildir.'"));
		Return;
	ElsIf QuantityToDistribution <= 0 Then
		ShowMessageBox(,NStr("vi = 'Toàn bộ số lượng hàng hóa đã chỉ ra trong chứng từ, được phân bổ theo sê-ri.';
							|ru = 'Все количество товара, указанное в документе, распределено по сериям.';
							|en = 'All quantity of goods specified in the document is allocated by batch.'; fa = 'All quantity of goods specified in the document is allocated by batch.';
							|it = 'Tutta la quantità di merci specificata nel documento è distribuita per serie.';
							|pl = 'Ogólna ilość towaru określona w dokumencie, podział według serii.';
							|tr = 'Belgede belirtilen tüm ürün miktarı partilere göre dağıtıldı.'"));
		Return;
	EndIf;	
	
	PackagingFactor = PackagingFactor(Package, Products);
	
	For Each RowID In Items.SetOfSeries.SelectedRows Do
		
		If QuantityToDistribution <= 0 Then
			Break;
		EndIf;
	
		RowSeries = Object.SetOfSeries.FindByID(RowID);
		
		Quantity_Per_Line = Max(Min(QuantityToDistribution, RowSeries.AvailableStock), 0);
		QuantityToDistribution = QuantityToDistribution - Quantity_Per_Line;
		SeriesCount = SeriesCount + Quantity_Per_Line;
		
		RowSeries.NumberOfPackages = RowSeries.NumberOfPackages + Quantity_Per_Line;
		RowSeries.AvailableStock = RowSeries.AvailableStock - Quantity_Per_Line;
		RowSeries.Count = RowSeries.NumberOfPackages * PackagingFactor;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function PackagingFactor(Package, Products)
	Return Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
EndFunction

&AtServer
Procedure PackageOnChangeServer()
	
	SaveSeriesInputInCache();
	Initialize(True);
	
EndProcedure

#EndRegion

#EndRegion
