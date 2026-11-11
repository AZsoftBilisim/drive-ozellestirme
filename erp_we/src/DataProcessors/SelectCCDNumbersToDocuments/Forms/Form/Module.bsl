
#Region Variables

&AtClient
Var NeedToAskQuestionBeforeClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If TypeOf(Parameters.CreationParameters) <> Type("Structure") Then
		MessageText = NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ';
							|ru = 'Предусмотрено открытие обработки только из документов.';
							|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
							|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
							|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
							|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
		
		Raise MessageText;
	EndIf;
	
	FillInByCreationParameters();
	InitializeTheForm();
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	NeedToAskQuestionBeforeClosing = True;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If NeedToAskQuestionBeforeClosing Then
		StandardProcessing = False;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi.
							|Lưu các thay đổi?';
							|ru = 'Данные были изменены.
							|Сохранить изменения?';
							|en = 'The data was changed.
							|Save the changes?'; fa = 'The data was changed.
							|Save the changes?';
							|it = 'I dati sono stati modificati. 
							|Salvare le modifiche?';
							|pl = 'Dane zostały zmienione.
							|Zapisać zmiany?';
							|tr = 'Veriler değiştirildi.
							|Değişiklikleri kaydet?'");
		
		CommonClient.ShowFormClosingConfirmation(ClosingNotification_,
																	Cancel,
																	Exit,
																	QueryText,
																	WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If ValueIsFilled(AddressInTempStorage) Then
		Structure = New Structure("AddressInTempStorage", AddressInTempStorage);
		
		NotifyChoice(Structure);
	EndIf
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CCDNumberTypeOnChange(Item)
	
	If Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
		Object.ImportingCountryIsNotRF = False;
		NumberOfComponents_ = Object.TraceableComponents.Count();
		
		If NumberOfComponents_ = 0
			And ValueIsFilled(Object.Code) Then
			
			RowData = LineDataByCodeAndCountryOfOrigin(Object.Code,
																	Object.OriginCountry,
																	FEACNUnitOfMeasure);
			
			NewRow = Object.TraceableComponents.Add();
			FillPropertyValues(NewRow, RowData);
			
		ElsIf NumberOfComponents_ > 0 Then
			
			Object.Code = ?(Object.TraceableComponents.Count() > 0,
							Object.TraceableComponents[0].Code,
							Object.Code);
			
		EndIf;
	EndIf;
	
	UnitOfValue = UnitOfValue(Object.CCDNumberType,
															Object.UnitOfMeasure);
	
	ProcessCodeChange();
	CustomizeForm(ThisObject);
	SetPresentationOfUnitOfValue(Items.PresentationOfCostUnit.Title,
													Currency,
													UnitOfValue);
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers,
										BeginningOfCorrectPeriod,
										EndOfCorrectPeriod,
										Items.ErrorInTheCustomsDeclarationNumber);
	
EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	ProcessCodeChange();
	
EndProcedure

&AtClient
Procedure CodeEditTextChange(Item, Text, StandardProcessing)
	
	CurrentTextDeclarationNumbers = Text;
	
	AttachIdleHandler("Attachable_DisplayInformationAboutErrorsInNumber", 0.1, True);
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	If ValueIsFilled(Object.Products) Then
		ProductData_1 = ProductData_1(Object.Products);
		FillPropertyValues(ThisObject, ProductData_1, , "FEACNUnitOfMeasure");
		
		Object.ProductName = ProductData_1.DescriptionFull;
		
		If Not ValueIsFilled(Object.UnitOfMeasure) Then
			Object.UnitOfMeasure = ?(ProductData_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5"),
										FEACNUnitOfMeasure,
										ProductData_1.FEACNUnitOfMeasure);
		EndIf;
	Else
		Object.ProductName = "";
	EndIf;
	
	UnitOfValue = UnitOfValue(Object.CCDNumberType,
															Object.UnitOfMeasure);
	
	SetPresentationOfUnitOfValue(Items.PresentationOfCostUnit.Title,
													Currency,
													UnitOfValue);
	
EndProcedure

&AtClient
Procedure ProductNameOnChange(Item)
	
	If Not IsBlankString(Object.ProductName) Then
		Object.ProductName = TrimAll(Object.ProductName);
	EndIf;
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	SetPresentationOfUnitOfValue(Items.PresentationOfCostUnit.Title,
													Currency,
													Object.UnitOfMeasure);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTraceableComponents

&AtClient
Procedure TraceableComponentsAfterDeleteRow(Item)
	
	If Object.TraceableComponents.Count() = 0 Then
		Object.Code = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure TraceableComponentsOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit
		And Object.TraceableComponents.Count() = 0 Then
		
		Object.Code = "";
		
		Return;
		
	EndIf;
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If Not CancelEdit
		And CurrentRow <> Undefined Then
		
		If ValueIsFilled(CurrentRow.Code)
			And ValueIsFilled(CurrentRow.FEACNUnitOfMeasure) Then
			
			AttachIdleHandler("MergeRows", 0.1, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TraceableComponentsCodeOnChange(Item)
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.Code = "" Then
		CurrentRow.ProductBatchIDNumber				= Undefined;
		CurrentRow.StatusOfRPTNumber		= False;
		CurrentRow.FEACNUnitOfMeasure	= Undefined;
		
		InstallCodeOnFirstLineOfComponents(CurrentRow);
		
		Return;
	EndIf;
	
	RowData = LineDataByCodeAndCountryOfOrigin(CurrentRow.Code,
															Object.OriginCountry,
															FEACNUnitOfMeasure);
	
	FillPropertyValues(CurrentRow, RowData);
	InstallCodeOnFirstLineOfComponents(CurrentRow);
	
EndProcedure

&AtClient
Procedure TraceableComponentsCodeAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	PurchasesClient.CCDNumbersCodeOfComponentAutoSelection(Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TraceableComponentsCodeOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If CurrentRow <> Undefined
		And ValueIsFilled(CurrentRow.ProductBatchIDNumber) Then
		
		ShowValue(, CurrentRow.ProductBatchIDNumber);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TraceableComponentsCodeChoiceProcessing(Item, ValueSelected, AdditionalData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If ValueSelected = Undefined Then
		CurrentRow.ProductBatchIDNumber				= Undefined;
		CurrentRow.StatusOfRPTNumber		= False;
		CurrentRow.Code					= "";
		CurrentRow.FEACNUnitOfMeasure	= Undefined;
	Else
		CurrentRow.ProductBatchIDNumber				= ValueSelected; 
		CurrentRow.StatusOfRPTNumber		= True;
		CurrentRow.Code					= String(ValueSelected);
		CurrentRow.FEACNUnitOfMeasure	= Undefined;
		
		If AdditionalData <> Undefined Then
			CurrentRow.FEACNUnitOfMeasure = AdditionalData.UnitOfMeasure;
		EndIf;
	EndIf;
	
	InstallCodeOnFirstLineOfComponents(CurrentRow);
	
EndProcedure

&AtClient
Procedure TraceableComponentsQuantityByRNPTInADocumentOnChange(Item)
	
	If KitCount = 0 Then
		Return;
	EndIf;
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow.QuantityByGBRN = CurrentRow.QuantityByRNPTInADocument / KitCount;
	
EndProcedure

&AtClient
Procedure TraceableComponentsAmountByProductBatchIDInDocumentOnChange(Item)
	
	If KitCount = 0 Then
		Return;
	EndIf;
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow.AmountByProductBatchID = Round(CurrentRow.AmountByProductBatchIDInDocument / KitCount, 2);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ProcessSelectionOk();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region RegistrationProcessing

&AtServer
Procedure SaveRegistrationData(Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
		
		Return;
	EndIf;
	
	If Object.CCDNumberType = Enums.CCDNumberTypes.KitRNPT Then
		SaveRNPTNumberOfKit(Cancel);
	Else
		SaveCCDNumber(Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveRNPTNumberOfKit(Cancel)
	
	FillInComponentsWithRegisteredRNPTNumbers();
	FillInComponentsWithNewRNPTNumbers();
	
	TableOfComponents = TableOfComponentsForCreatingRPTNumberOfKit();
	
	CreationParameters = PurchasesServer.ParametersForSearchingOrCreatingCompositeTraceableSets();
	CreationParameters.ItemOfHeader = Object.Products;
	CreationParameters.AmountByProductBatchID = Object.AmountByProductBatchID;
	CreationParameters.AlwaysUseAmountByProductBatchIDForCostOfKit = True;
	
	RNPTKitData = PurchasesServer.FindOrCreateCompositeTraceableCCDNumbers(
							TableOfComponents,
							KitCount,
							Date(2399, 1, 1),
							Cancel,
							CreationParameters);
	
	If Cancel Then
		Return;
	EndIf;
	
	RegistrationResult = ResultOfDataLogging();
	RegistrationResult.CCDNumberType		= Object.CCDNumberType;
	RegistrationResult.MainNumberOfCCD	= RNPTKitData.MainCompositeNumberOfCCD;
	
	If RNPTKitData.ResidualCompositeNumberOfCCD <> Undefined Then
		RegistrationResult.ResidualNumberOfCCD = RNPTKitData.ResidualCompositeNumberOfCCD;
	EndIf;
	
	AddressInTempStorage = PutToTempStorage(RegistrationResult, UUID);
	
EndProcedure

&AtServer
Function TableOfComponentsForCreatingRPTNumberOfKit()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VALUE(Catalog.Products.EmptyRef)	AS Products,
	|	Components.ProductBatchIDNumber							AS CCDNumber,
	|	Components.QuantityByRNPTInADocument		AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure				AS UnitOfMeasure,
	|	Components.AmountByProductBatchID						AS AmountByProductBatchID
	|INTO TTComponents
	|FROM
	|	&Components AS Components
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Components.Products				AS Products,
	|	Components.CCDNumber					AS CCDNumber,
	|	SUM(Components.QuantityByGBRN)	AS QuantityByGBRN,
	|	Components.UnitOfMeasure			AS UnitOfMeasure,
	|	SUM(Components.AmountByProductBatchID)		AS AmountByProductBatchID
	|FROM
	|	TTComponents AS Components
	|
	|GROUP BY
	|	Components.Products,
	|	Components.CCDNumber,
	|	Components.UnitOfMeasure";
	
	UnloadedColumns = "ProductBatchIDNumber, QuantityByRNPTInADocument, FEACNUnitOfMeasure, AmountByProductBatchID";
	Query.SetParameter("Components", Object.TraceableComponents.Unload(, UnloadedColumns));
	
	TableOfComponents = Query.Execute().Unload();
	
	Return TableOfComponents;
	
EndFunction

&AtServer
Procedure FillInComponentsWithRegisteredRNPTNumbers()
	
	Components = Object.TraceableComponents;
	
	RowFilter = New Structure("ProductBatchIDNumber", Catalogs.CCDNumbers.EmptyRef());
	LinesWithoutRNPT = Components.FindRows(RowFilter);
	
	If LinesWithoutRNPT.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Components.LineNumber	AS LineNumber,
	|	Components.Code			AS Code
	|INTO TTComponents
	|FROM
	|	&Components AS Components
	|
	|WHERE
	|	Components.ProductBatchIDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|INDEX BY
	|	Code
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Components.LineNumber	AS LineNumber,
	|	CCDNumbers.Ref			AS ProductBatchIDNumber
	|FROM
	|	TTComponents AS Components
	|		INNER JOIN Catalog.CCDNumbers AS CCDNumbers
	|		ON Components.Code = CCDNumbers.Code
	|			AND CCDNumbers.OriginCountry = &OriginCountry
	|			AND CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("Components",			Components.Unload(, "LineNumber, ProductBatchIDNumber, Code"));
	Query.SetParameter("OriginCountry",	Object.OriginCountry);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		Components[Selection.LineNumber - 1].ProductBatchIDNumber = Selection.ProductBatchIDNumber;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInComponentsWithNewRNPTNumbers()
	
	RowFilter = New Structure("ProductBatchIDNumber", Catalogs.CCDNumbers.EmptyRef());
	LinesWithoutRNPT = Object.TraceableComponents.FindRows(RowFilter);
	
	ComparisonOfRNPTNumbers = New Map;
	
	For Each SetString_ In LinesWithoutRNPT Do
		RNPTCode		= TrimAll(SetString_.Code);
		ProductBatchIDNumber	= ComparisonOfRNPTNumbers.Get(RNPTCode);
		
		If ProductBatchIDNumber = Undefined Then
			SaveRNPTByComponentLine(SetString_);
			
			ComparisonOfRNPTNumbers.Insert(RNPTCode, SetString_.ProductBatchIDNumber);
		Else
			SetString_.ProductBatchIDNumber = ProductBatchIDNumber;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveRNPTByComponentLine(SetString_)
	
	ProductBatchIDNumber = Catalogs.CCDNumbers.CreateItem();
	ProductBatchIDNumber.RegistrationNumber	= SetString_.Code;
	ProductBatchIDNumber.CCDNumberType			= Enums.CCDNumberTypes.ProductBatchIDNumber;
	ProductBatchIDNumber.UnitOfMeasure		= SetString_.FEACNUnitOfMeasure;
	
	ObjectPropertiesNames = "OriginCountry, Products, ProductName";
	FillPropertyValues(ProductBatchIDNumber, Object, ObjectPropertiesNames);
	
	NamesOfKitProperties = "Code, AmountByProductBatchID";
	FillPropertyValues(ProductBatchIDNumber, SetString_, NamesOfKitProperties);
	
	ProductBatchIDNumber.Write();
	
	SetString_.ProductBatchIDNumber = ProductBatchIDNumber.Ref;
	
EndProcedure

&AtServer
Procedure SaveCCDNumber(Cancel)
	
	CCDNumber = Catalogs.CCDNumbers.CreateItem();
	
	If CCDNumber <> Undefined Then
		FillPropertyValues(CCDNumber, Object);
		
		CCDNumber.Write();
	Else
		TypePresentation = ?(Object.CCDNumberType = Enums.CCDNumberTypes.CCDNumber,
								NStr("vi = 'số tờ khai hải quan';
									|ru = 'номер ГТД';
									|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
									|it = 'Numero della polizza doganale di carico';
									|pl = 'numer ładunkowej deklaracji celnej';
									|tr = 'Gümrük Kargo Beyannamesi numarası'"),
								NStr("vi = 'số đăng ký lô hàng';
									|ru = 'номер РНПТ';
									|en = 'RNPT'; fa = 'RNPT';
									|it = 'Numero di registrazione lotti prodotti';
									|pl = 'Numer rejestracyjny partii towaru';
									|tr = 'RNPT numarası'"));
		
		MessageText = NStr("vi = 'Không thể đăng ký %1';
							|ru = 'Не удалось зарегистрировать %1';
							|en = 'Cannot register %1'; fa = 'Cannot register %1';
							|it = 'Non è stato possibile registrare %1';
							|pl = 'Nie udało się zarejestrować %1';
							|tr = 'Kaydedilemedi %1'");
		MessageText = StrTemplate(MessageText, TypePresentation);
		
		Common.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	RegistrationResult = ResultOfDataLogging();
	RegistrationResult.CCDNumberType		= CCDNumber.CCDNumberType;
	RegistrationResult.MainNumberOfCCD	= CCDNumber.Ref;
	
	AddressInTempStorage = PutToTempStorage(RegistrationResult, UUID);
	
EndProcedure

&AtServer
Function ResultOfDataLogging()
	
	RegistrationResult = New Structure;
	RegistrationResult.Insert("CCDNumberType",		Enums.CCDNumberTypes.EmptyRef());
	RegistrationResult.Insert("MainNumberOfCCD",	Undefined);
	RegistrationResult.Insert("ResidualNumberOfCCD",	Undefined);
	
	Return RegistrationResult;
	
EndFunction

#EndRegion

#Region OnChangeAttributes

&AtClient
Procedure ProcessCodeChange()
	
	CurrentTextDeclarationNumbers = Object.Code;
	
	If Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.CCDNumber") Then
		Attributes = RegistrationNumberAndCountryOfImportation(CurrentTextDeclarationNumbers);
		
		FillPropertyValues(Object, Attributes);
	ElsIf Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber") Then
		Object.RegistrationNumber = CurrentTextDeclarationNumbers;
	Else
		Object.RegistrationNumber		= "";
		CurrentTextDeclarationNumbers	= "";
	EndIf;
	
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers,
										BeginningOfCorrectPeriod,
										EndOfCorrectPeriod,
										Items.ErrorInTheCustomsDeclarationNumber);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	If Object.CCDNumberType = Enums.CCDNumberTypes.CCDNumber Then
		Return;
	EndIf;
	
	//
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields,
														Items.TraceableComponentsUnitOfMeasurement.Name);
	
	CommonClientServer.AddCompositionItem(Item.Filter,
															"Object.TraceableComponents.ProductBatchIDNumber",
															DataCompositionComparisonType.Filled);
	
	CommonClientServer.AddCompositionItem(Item.Filter,
															Items.TraceableComponentsUnitOfMeasurement.DataPath,
															DataCompositionComparisonType.Filled);
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure FillInByCreationParameters()
	
	CreationData = PurchasesServer.DefaultCCDNumberCreationParameters();
	InitializeCreationData(CreationData, Parameters.CreationParameters);
	
	ProductData_8 = CreationData.ProductData_8;
	
	If Not ValueIsFilled(ProductData_8.Products) Then
		ExceptionText = NStr("vi = 'Để mở bộ xử lý, không chuyển sang thông tin về hàng hóa.';
							|ru = 'Для открытия обработки не переданы сведения о товаре.';
							|en = 'To open the data processor, pass the goods information.'; fa = 'To open the data processor, pass the goods information.';
							|it = 'Le informazioni sul prodotto non sono state inviate per aprire l''elaborazione.';
							|pl = 'Dla otwarcia procesora danych nie są przekazane dane o towarze.';
							|tr = 'İşleme başlangıcı için ürün bilgisi transfer edilmedi.'");
		
		Raise ExceptionText;
	EndIf;
	
	FillPropertyValues(ThisObject, ProductData_8);
	FillPropertyValues(ThisObject, CreationData);
	
	TMCommonUseClientServer.FillInValuesOfEmptyProperties(Object, ProductData_8);
	TMCommonUseClientServer.FillInValuesOfEmptyProperties(Object, CreationData);
	
	AttributesNames			= "DescriptionFull, ItemsType, UnitOfMeasure, FEACNUnitOfMeasure, OriginCountry";
	ProductAttributes	= Common.ObjectAttributesValues(Object.Products, AttributesNames);
	
	If Not ValueIsFilled(Object.OriginCountry) Then
		Object.OriginCountry = ProductAttributes.OriginCountry;
	EndIf;
	
	Object.ProductName = ProductAttributes.DescriptionFull;
	
	If ProductAttributes.ItemsType <> Enums.ItemsTypes.Work_5 Then
		Object.UnitOfMeasure = ProductAttributes.FEACNUnitOfMeasure;
	EndIf;
	
	AttributesNames		= "Products, Characteristic, Package, UnitOfMeasure, AmountByProductBatchID";
	ProductData_1	= New Structure(AttributesNames);
	
	FillPropertyValues(ProductData_1, ProductData_8);
	FillPropertyValues(ProductData_1, ProductAttributes);
	
	InitializeCostIndicators(CreationData, ProductData_1);
	SetTitleOfProductInformationDocument(ProductData_1);
	
EndProcedure

&AtServer
Procedure InitializeCreationData(CreationData, CreationParameters)
	
	For Each KeyAndValue In CreationParameters Do
		If CreationData.Property(KeyAndValue.Key)
			And TypeOf(CreationData[KeyAndValue.Key]) = TypeOf(KeyAndValue.Value) Then
			
			CreationData[KeyAndValue.Key] = KeyAndValue.Value;
			
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeCostIndicators(CreationParameters, ProductData_1)
	
	Currency = AccountingForTraceableGoodsLocalization.LocalAccountingCurrencyOfCCDNumber();
	
	If Not ShowCostByDocument Then
		Return;
	EndIf;
	
	DocumentDate	= ?(ValueIsFilled(CreationParameters.Date),
						CreationParameters.Date,
						CurrentSessionDate());
	DocumentCurrency	= ?(ValueIsFilled(CreationParameters.DocumentCurrency),
						CreationParameters.DocumentCurrency,
						Currency);
	
	If ValueIsFilled(Currency)
		And ValueIsFilled(DocumentCurrency)
		And Currency <> DocumentCurrency Then
		
		OldCurrencyRate	= ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, DocumentDate, Currency);
		NewCurrencyRate		= ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, DocumentDate, Currency);
		
		Object.AmountByProductBatchID = ProcessingOfExchangeRatesTM.ConvertAtRate(Object.AmountByProductBatchID,
																		OldCurrencyRate,
																		NewCurrencyRate);
		
	EndIf;
	
	ProductData_1.AmountByProductBatchID = Object.AmountByProductBatchID;
	
	If KitCount <> 0 Then
		Object.AmountByProductBatchID = Round(Object.AmountByProductBatchID / KitCount, 2);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTitleOfProductInformationDocument(ProductData_1)
	
	Package = ?(ValueIsFilled(ProductData_1.Package),
				ProductData_1.Package,
				ProductData_1.UnitOfMeasure);
	
	ProductData_8 = New Array;
	ProductData_8.Add(TrimAll(String(ProductData_1.Products)));
	
	If ValueIsFilled(ProductData_1.Characteristic) Then
		ProductData_8.Add(TrimAll(String(ProductData_1.Characteristic)));
	EndIf;
	
	GoodsPresentation = StrConcat(ProductData_8, ",");
	
	If ShowCostByDocument Then
		TitleOfInformationInscription = NStr("vi = 'Trong chứng từ đã chỉ ra %1 %2 của bộ đóng gói ""%3"" bởi giá trị %4%5';
											|ru = 'В документе указано %1 %2 комплекта ""%3"" стоимостью %4 %5';
											|en = 'The document specifies %1 %2 kits of ""%3"" at the cost of %4 %5'; fa = 'The document specifies %1 %2 kits of ""%3"" at the cost of %4 %5';
											|it = 'В документе указано %1 %2 комплекта ""%3"" стоимостью %4 %5';
											|pl = 'The document specifies %1 %2 kits of ""%3"" at the cost of %4 %5';
											|tr = 'Belgede, ""%3"" seti %4 %5 maliyetle %1 %2 olarak belirtilmiştir'");
		TitleOfInformationInscription = StrTemplate(TitleOfInformationInscription,
													String(KitCount),
													TrimAll(String(Package)),
													GoodsPresentation,
													String(ProductData_1.AmountByProductBatchID),
													TrimAll(String(Currency)));
	Else
		TitleOfInformationInscription = NStr("vi = 'Trong chứng từ đã chỉ ra %1 %2 của bộ đóng gói ""%3""';
											|ru = 'В документе указано %1 %2 комплекта ""%3""';
											|en = '%1%2 of the ""%3"" kit is specified in the document'; fa = '%1%2 of the ""%3"" kit is specified in the document';
											|it = 'Nel documento sono indicati %1%2 del kit ""%3""';
											|pl = 'W dokumencie podano %1 %2 zestawy ""%3""';
											|tr = '""%3"" setinin belgesinde %1 %2 belirtildi'");
		TitleOfInformationInscription = StrTemplate(TitleOfInformationInscription,
													String(KitCount),
													TrimAll(String(Package)),
													GoodsPresentation);
	EndIf;
	
	Items.ProductInformationOfDocument.Title = TitleOfInformationInscription;
	
EndProcedure

&AtServer
Procedure InitializeTheForm()
	
	FillInUnitOfFuelTaxByDefault();
	
	TracedGoods = Common.ObjectAttributeValue(Object.Products, "TracedGoods");
	Object.CCDNumberType = ?(ValueIsFilled(Object.CCDNumberType),
							Object.CCDNumberType,
							?(TracedGoods,
								Enums.CCDNumberTypes.ProductBatchIDNumber,
								Enums.CCDNumberTypes.CCDNumber));
	
	CurrentTextDeclarationNumbers = ?(Object.CCDNumberType = Enums.CCDNumberTypes.KitRNPT,
									"",
									Object.Code);
	
	If Object.CCDNumberType = Enums.CCDNumberTypes.CCDNumber Then
		Attributes = RegistrationNumberAndCountryOfImportation(CurrentTextDeclarationNumbers);
		
		FillPropertyValues(Object, Attributes);
	ElsIf Object.CCDNumberType = Enums.CCDNumberTypes.ProductBatchIDNumber Then
		Object.RegistrationNumber = CurrentTextDeclarationNumbers;
		
		If Not ValueIsFilled(Object.UnitOfMeasure) Then
			Object.UnitOfMeasure = FEACNUnitOfMeasure;
		EndIf;
	EndIf;
	
	CorrectPeriod = PurchasesServer.CorrectPeriodForEnteringDocumentsCustomsDeclarationNumbers();
	BeginningOfCorrectPeriod	= CorrectPeriod.BeginningOfCorrectPeriod;
	EndOfCorrectPeriod		= CorrectPeriod.EndOfCorrectPeriod;
	
	UnitOfValue = UnitOfValue(Object.CCDNumberType,
															Object.UnitOfMeasure);
	
	CustomizeForm(ThisObject);
	CreatePresentationOfTDNumber();
	SetPresentationOfUnitOfValue(Items.PresentationOfCostUnit.Title,
													Currency,
													UnitOfValue);
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers,
										BeginningOfCorrectPeriod,
										EndOfCorrectPeriod,
										Items.ErrorInTheCustomsDeclarationNumber);
	
	Items.CCDNumberType.Visible = TracedGoods;
	
	If TracedGoods
		And Not CreatingElementOfAnyType Then
		
		Items.CCDNumberType.ChoiceList.LoadValues(
			AccountingForTraceableGoodsClientServerLocalization.CCDNumberTypes(True));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInUnitOfFuelTaxByDefault()
	
	ClassifierData	= Catalogs.PackagesAndUnitsOfMeasure.FillInUnitsFromClassifier("796");
	FEACNUnitOfMeasure	= ClassifierData["796"];
	
EndProcedure

&AtClientAtServerNoContext
Function UnitOfValue(CCDNumberType, UnitOfMeasure)
	
	UnitOfValue = ?(CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber"),
									UnitOfMeasure,
									PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	
	Return UnitOfValue;
	
EndFunction

// Parameters:
//	Form - ClientApplicationForm - the form of the Catalog element.
&AtClientAtServerNoContext
Procedure CustomizeForm(Form)
	
	Object		= Form.Object;
	Items	= Form.Items;
	
	ThisIsCCD				= Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.CCDNumber");
	ThisIsRNPTOfKit	= Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT");
	
	Items.Code.Visible = Not ThisIsRNPTOfKit;
	Items.Code.Title = ?(ThisIsCCD,
								NStr("vi = 'Số tờ khai';
									|ru = 'Номер декларации';
									|en = 'Declaration number'; fa = 'شماره اظهارنامه';
									|it = 'Numero della dichiarazione';
									|pl = 'Numer deklaracji';
									|tr = 'Beyanname numarası'"),
								NStr("vi = 'Số đăng ký lô hàng';
									|ru = 'Номер РНПТ';
									|en = 'RNPT'; fa = 'RNPT';
									|it = 'Numero di registrazione lotti prodotti';
									|pl = 'Numer rejestracyjny partii towaru';
									|tr = 'RNPT numarası'"));
	
	Items.AmountByProductBatchID.Title = ?(ThisIsRNPTOfKit,
										NStr("vi = 'Giá trị bộ';
											|ru = 'Стоимость комплекта';
											|en = 'Kit cost'; fa = 'Kit cost';
											|it = 'Стоимость комплекта';
											|pl = 'Kit cost';
											|tr = 'Set maliyeti'"),
										NStr("vi = 'Giá trị';
											|ru = 'Стоимость';
											|en = 'Cost'; fa = 'بهای تمام‌شده';
											|it = 'Стоимость';
											|pl = 'Cost';
											|tr = 'Maliyet'"));
	
	Items.TraceabilityDataGroup.Visible			= Not ThisIsCCD;
	Items.NomenclatureGroup.Visible					= Not ThisIsRNPTOfKit;
	Items.TraceableComponentsGroup.Visible	= ThisIsRNPTOfKit;
	
	Items.TraceableComponentsAmountByProductBatchIDInDocument.Visible = Form.ShowCostByDocument;
	
	SetFormHeader(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFormHeader(Form)
	
	Object = Form.Object;
	
	TitleTemplate1 = NStr("vi = 'Ghi nhận %1';
							|ru = 'Регистрация %1';
							|en = 'Registration %1'; fa = 'Registration %1';
							|it = 'Registrazione %1';
							|pl = 'Rejestracja %1';
							|tr = '%1 kaydı'");
	
	If Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.CCDNumber") Then
		TitleText = StrTemplate(TitleTemplate1, NStr("vi = 'số tờ khai hải quan';
													|ru = 'номера грузовой таможенной декларации';
													|en = 'cargo customs declaration numbers'; fa = 'cargo customs declaration numbers';
													|it = 'del numero della polizza doganale di carico';
													|pl = 'numeru ładunkowej deklaracji celnej';
													|tr = 'kargo gümrük beyannamesi numaraları'"));
	ElsIf Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber") Then
		TitleText = StrTemplate(TitleTemplate1, NStr("vi = 'số đăng ký lô hàng';
													|ru = 'номера РНПТ';
													|en = 'RNPT'; fa = 'RNPT';
													|it = 'del numero di registrazione lotti prodotti';
													|pl = 'numeru rejestracycjnego partii towaru';
													|tr = 'RNPT numarası'"));
	ElsIf Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
		TitleText = StrTemplate(TitleTemplate1, NStr("vi = 'số đăng ký lô hàng của bộ đóng gói';
													|ru = 'номера РНПТ комплекта';
													|en = 'kit RNPT'; fa = 'kit RNPT';
													|it = 'del numero di registrazione del lotto prodotti di un kit';
													|pl = 'numeru rejestracyjnego partii towaru zestawu';
													|tr = 'setin RNPT numaraları'"));
	EndIf;
	
	Form.Title = TitleText;
	
EndProcedure

&AtServer
Procedure CreatePresentationOfTDNumber()
	
	CustomsDeclaration = "";
	
	If AccessRight("View", Metadata.Documents.CCDImport) Then
		If Not Object.ImportingCountryIsNotRF
			And ValueIsFilled(Object.RegistrationNumber) Then
			
			CustomsDeclarationLink = Documents.CCDImport.FindByAttribute(
											"DeclarationNo",
											Object.RegistrationNumber);
			
			If Not CustomsDeclarationLink.IsEmpty() Then
				CustomsDeclaration = GetURL(CustomsDeclarationLink);
			EndIf;
			
		EndIf;
	EndIf;
	
	If ValueIsFilled(CustomsDeclaration)
		And ValueIsFilled(Object.RegistrationNumber) Then
		
		Term1 = New FormattedString(NStr("vi = 'Đã đăng ký tờ khai:';
										|ru = 'Зарегистрирована декларация:';
										|en = 'Registered declaration:'; fa = 'Registered declaration:';
										|it = 'Dichiarazione registrata:';
										|pl = 'Zarejestrowano deklarację:';
										|tr = 'Beyanname kaydedildi:'") + " ");
		Term2 = New FormattedString(Object.RegistrationNumber, , , , CustomsDeclaration);
		
		Items.RepresentationOfTheTDNumber.Title = New FormattedString(Term1, Term2);
		Items.RepresentationOfTheTDNumber.Visible = True;
		
	Else
		Items.RepresentationOfTheTDNumber.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPresentationOfUnitOfValue(ItemPresentation, Currency, FEACNUnitOfMeasure)
	
	UnitOfMeasurePresentation = ?(ValueIsFilled(FEACNUnitOfMeasure),
										TrimAll(String(FEACNUnitOfMeasure)),
										NStr("vi = 'đơn vị';
											|ru = 'единицу';
											|en = 'unit'; fa = 'واحد';
											|it = 'единицу';
											|pl = 'unit';
											|tr = 'birimini'"));
	
	PresentationText		= NStr("vi = '%1 trong %2';
									|ru = '%1 за %2';
									|en = '%1 for %2'; fa = '%1 for %2';
									|it = '%1 за %2';
									|pl = '%1 for %2';
									|tr = '%1 %2 için'");
	ItemPresentation	= StrTemplate(PresentationText, TrimAll(String(Currency)), UnitOfMeasurePresentation);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers,
											BeginningOfCorrectPeriod,
											EndOfCorrectPeriod,
											ElementErrorInCustomsDeclarationNumber)
	
	CheckResult = VATAccountingClientServerLocalization.CheckCorrectnessOfCustomsDeclarationNumber(
							CurrentTextDeclarationNumbers,
							BeginningOfCorrectPeriod,
							EndOfCorrectPeriod);
	
	ElementErrorInCustomsDeclarationNumber.Title = VATAccountingClientServerLocalization.TextOfErrorInCustomsDeclarationNumber(
															CheckResult.ErrorCode);
	ElementErrorInCustomsDeclarationNumber.Visible = CheckResult.ErrorCode <> 0;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		NeedToAskQuestionBeforeClosing = False;
		
		ProcessSelectionOk();
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		
		NeedToAskQuestionBeforeClosing = False;
		
		Close();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function LineDataByCodeAndCountryOfOrigin(Val Code, OriginCountry, FEACNUnitOfMeasure)
	
	FirstLineData = New Structure;
	FirstLineData.Insert("Code",						Code);
	FirstLineData.Insert("ProductBatchIDNumber",				Catalogs.CCDNumbers.EmptyRef());
	FirstLineData.Insert("FEACNUnitOfMeasure",	FEACNUnitOfMeasure);
	FirstLineData.Insert("StatusOfRPTNumber",			False);
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CCDNumbers.Ref			AS ProductBatchIDNumber,
	|	CCDNumbers.Code				AS Code,
	|	CCDNumbers.UnitOfMeasure	AS FEACNUnitOfMeasure,
	|	TRUE						AS StatusOfRPTNumber
	|FROM
	|	Catalog.CCDNumbers AS CCDNumbers
	|WHERE
	|	NOT CCDNumbers.DeletionMark
	|	AND CCDNumbers.Code = &Code
	|	AND CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|
	|ORDER BY
	|	Code";
	
	Query.SetParameter("Code", TrimAll(Code));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return FirstLineData;
	EndIf;
	
	Selection = QueryResult.Select();
	
	If Selection.Count() > 1 Then
		Return FirstLineData;
	EndIf;
	
	Selection.Next();
	FillPropertyValues(FirstLineData, Selection);
	
	Return FirstLineData;
	
EndFunction

&AtServerNoContext
Function ProductData_1(Products)
	
	AttributesNames		= "DescriptionFull, ItemsType, FEACNUnitOfMeasure";
	ProductData_1	= Common.ObjectAttributesValues(Products, AttributesNames);
	
	ProductData_1.DescriptionFull = TrimAll(ProductData_1.DescriptionFull);
	
	Return ProductData_1;
	
EndFunction

&AtClient
Procedure InstallCodeOnFirstLineOfComponents(CurrentRow)
	
	If CurrentRow.LineNumber = 1 Then
		If Object.Code <> CurrentRow.Code Then
			Object.Code = CurrentRow.Code;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RegistrationNumberAndCountryOfImportation(CurrentTextDeclarationNumbers)
	
	Return Catalogs.CCDNumbers.RegistrationNumberAndCountryOfImportation(CurrentTextDeclarationNumbers);
	
EndFunction

&AtClient
Procedure Attachable_DisplayInformationAboutErrorsInNumber()
	
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers,
										BeginningOfCorrectPeriod,
										EndOfCorrectPeriod,
										Items.ErrorInTheCustomsDeclarationNumber);
	
EndProcedure

&AtClient
Procedure ProcessSelectionOk()
	
	ClearMessages();
	
	Cancel = False;
	
	SaveRegistrationData(Cancel);
	
	If Not Cancel Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure MergeRows()
	
	CurrentRow = Items.TraceableComponents.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	MergeRowsServer(CurrentRow.GetID());
	
EndProcedure

&AtServer
Procedure MergeRowsServer(CurrentRowID)
	
	Components = Object.TraceableComponents;
	CurrentRow = Components.FindByID(CurrentRowID);
	
	IndexOf = Components.Count() - 1;
	CurrentRowIndex = 0;
	
	RowToDelete = Undefined;
	LineDetails = "ProductBatchIDNumber, Code, FEACNUnitOfMeasure";
	
	CurRowProperties = New Structure(LineDetails);
	FillPropertyValues(CurRowProperties, CurrentRow, , "Code");
	
	CurRowProperties.Code = TrimAll(CurrentRow.Code);
	
	While IndexOf >= 0 Do
		If Components[IndexOf].GetID() = CurrentRowID Then
			CurrentRowIndex = IndexOf;
			IndexOf = IndexOf - 1;
			
			Continue;
		EndIf;
		
		SetStringProperties = New Structure(LineDetails);
		FillPropertyValues(SetStringProperties, Components[IndexOf], , "Code");
		SetStringProperties.Code = TrimAll(Components[IndexOf].Code);
		
		LinesMatch = TMCommonUseClientServer.StructuresAreEqual(CurRowProperties, SetStringProperties);
		
		If Not LinesMatch Then
			IndexOf = IndexOf - 1;
			
			Continue;
		EndIf;
		
		If IndexOf > CurrentRowIndex Then
			RowToDelete = Components[IndexOf];
			
			CurrentRow.QuantityByGBRN = CurrentRow.QuantityByGBRN + Components[IndexOf].QuantityByGBRN;
			CurrentRow.QuantityByRNPTInADocument = CurrentRow.QuantityByRNPTInADocument
														+ Components[IndexOf].QuantityByRNPTInADocument;
			
			CurrentRow.AmountByProductBatchID = CurrentRow.AmountByProductBatchID + Components[IndexOf].AmountByProductBatchID;
			CurrentRow.AmountByProductBatchIDInDocument = CurrentRow.AmountByProductBatchIDInDocument
													+ Components[IndexOf].AmountByProductBatchIDInDocument;
		Else
			RowToDelete = CurrentRow;
			
			Components[IndexOf].QuantityByGBRN = Components[IndexOf].QuantityByGBRN
														+ CurrentRow.QuantityByGBRN;
			Components[IndexOf].QuantityByRNPTInADocument = Components[IndexOf].QuantityByRNPTInADocument
																+ CurrentRow.QuantityByRNPTInADocument;
			
			Components[IndexOf].AmountByProductBatchID = Components[IndexOf].AmountByProductBatchID + CurrentRow.AmountByProductBatchID;
			Components[IndexOf].AmountByProductBatchIDInDocument = Components[IndexOf].AmountByProductBatchIDInDocument
															+ CurrentRow.AmountByProductBatchIDInDocument;
		EndIf;
		
		Break;
		
	EndDo;
	
	If RowToDelete <> Undefined Then
		Components.Delete(RowToDelete);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
