
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		FillInByCreationParameters();
		OnReadCreateAtServer();
	Else
		Items.CCDNumberType.Visible = UseTraceableImportedGoodsAccounting;
	EndIf;
	
	SetConditionalAppearance();
	
	// Prohibit editing
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetFormHeader(ThisObject);
	FillInServiceDataOfTrackedComponents();
	
	// Prohibit editing
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.CCDNumberType <> Enums.CCDNumberTypes.KitRNPT Then
		Return;
	ElsIf Object.TraceableComponents.Count() = 0 Then
		Return;
	EndIf;
	
	RowFilter = New Structure("Code", "");
	LinesNotFilledIn = Object.TraceableComponents.FindRows(RowFilter);
	
	MessageTextTemplate = NStr("vi = 'Chưa điền cột ""Mã"" trong dòng %1 của danh sách ""Thành phần chi tiết có nguồn gốc xuất xứ"".';
								|ru = 'Не заполнена колонка ""Код"" в строке %1 списка ""Прослеживаемые комплектующие"".';
								|en = 'The ""Code"" column in the %1 line of the ""Traceable components"" list is not filled.'; fa = 'The ""Code"" column in the %1 line of the ""Traceable components"" list is not filled.';
								|it = 'Colonna ""Codice"" nella riga %1 dell''elenco ""Componenti tracciabili"" non compilata';
								|pl = 'Nie wypełniono kolumny ""Kod"" w wierszu %1 listy ""Komponenty identyfikowalne"".';
								|tr = '""İzlenebilir Bileşenler"" listesinin %1 satırındaki ""Kod"" sütunu doldurulmadı.'");
	
	For Each LineNotFilledIn In LinesNotFilledIn Do
		MessageText = StrTemplate(MessageTextTemplate, LineNotFilledIn.LineNumber);
		Field = CommonClientServer.PathToTabularSection("TraceableComponents",
																LineNotFilledIn.LineNumber,
																"Code");
		
		Common.MessageToUser(MessageText, , Field, , Cancel);
	EndDo;
	
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
			
			RowData = LineDataByCodeAndCountryOfOrigin(Object.Ref,
																	Object.Code,
																	Object.OriginCountry,
																	FEACNUnitOfMeasure);
			
			NewRow = Object.TraceableComponents.Add();
			FillPropertyValues(NewRow, RowData);
			
		ElsIf NumberOfComponents_ > 0 Then
			
			Object.Code = ?(Object.TraceableComponents.Count() > 0,
							Object.TraceableComponents[0].Code,
							Object.Code);
			
		EndIf;
	ElsIf Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber") Then
		If Not ValueIsFilled(Object.UnitOfMeasure) Then
			Object.UnitOfMeasure = FEACNUnitOfMeasure;
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
		
		If Not ValueIsFilled(Object.ProductName) Then
			Object.ProductName = ProductData_1.DescriptionFull;
		EndIf;
		
		If Not ValueIsFilled(Object.UnitOfMeasure) Then
			Object.UnitOfMeasure = ?(ProductData_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5"),
										FEACNUnitOfMeasure,
										ProductData_1.FEACNUnitOfMeasure);
		EndIf;
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
	
	RowData = LineDataByCodeAndCountryOfOrigin(Object.Ref,
															CurrentRow.Code,
															Object.OriginCountry,
															FEACNUnitOfMeasure);
	
	FillPropertyValues(CurrentRow, RowData);
	InstallCodeOnFirstLineOfComponents(CurrentRow);
	
EndProcedure

&AtClient
Procedure TraceableComponentsCodeAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	PurchasesClient.CCDNumbersCodeOfComponentAutoSelection(Text, ChoiceData, StandardProcessing, Object.Ref);
	
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteData(Command)
	
	PerformCheckBeforeRecordingAndRecord();
	
EndProcedure

&AtClient
Procedure RecordDataAndClose(Command)
	
	Cancel = False;
	
	PerformCheckBeforeRecordingAndRecord(Cancel);
	
	If Not Cancel Then
		Close();
	EndIf;
	
EndProcedure

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		FormParameters = New Structure;
		FormParameters.Insert("CCDNumberType",		Object.CCDNumberType);
		FormParameters.Insert("KeepRecordsOfRNPT",	Items.CCDNumberType.Visible);
		
		CallbackDescription = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion",
														ThisObject);
		
		OpenForm(
			"Catalog.CCDNumbers.Form.AttributeUnlocking",
			FormParameters,
			,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array")
		And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region ObjectProcessingBeforeRecording

&AtClient
Procedure PerformCheckBeforeRecordingAndRecord(Cancel = False)
	
	ClearMessages();
	
	If Not ControlOfUniquenessIsCarriedOut
		And UseTraceableImportedGoodsAccounting
		And Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
		
		ExecuteChecksBeforeWriteServer(Cancel);
		
		If ValueIsFilled(AddressTemporaryStorageTableFound) Then
			FormParameters = New Structure("AddressTemporaryStorageTableFound",
											AddressTemporaryStorageTableFound);
			CallbackDescription = New CallbackDescription("CheckForUniquenessCompletion", ThisObject);
			
			OpenForm("Catalog.CCDNumbers.Form.CheckUnique",
						FormParameters,
						ThisObject,
						,
						,
						,
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
		EndIf;
		
		WriteElement(Cancel);
		
	Else
		If Not Write() Then
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
//	Result - See ProductsClient.NewCompletionProcessingResult
//	AdditionalParameters - Structure, Undefined - parameters for processing the End of uniqueness control.
//
&AtClient
Procedure CheckForUniquenessCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Action = "SelectAnExisting" Then
		Modified = False;
		
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteChecksBeforeWriteServer(Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		FillInComponentsWithRegisteredRNPTNumbers();
		FillInComponentsWithNewRNPTNumbers();
		
		AddressTemporaryStorageTableFound = CheckUniquenessOfRNPTKit(Cancel);
	EndIf;
	
EndProcedure

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
	|			AND CCDNumbers.Ref <> &CurrentRef
	|			AND CCDNumbers.OriginCountry = &OriginCountry
	|			AND CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("CurrentRef",			Object.Ref);
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
		RNPTCode = TrimAll(SetString_.Code);
		ProductBatchIDNumber = ComparisonOfRNPTNumbers.Get(RNPTCode);
		
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
Function CheckUniquenessOfRNPTKit(Cancel)
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	TableFound.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Components.ProductBatchIDNumber					AS ProductBatchIDNumber,
	|	Components.FEACNUnitOfMeasure		AS UnitOfMeasure,
	|	Components.QuantityByGBRN			AS QuantityByGBRN,
	|	Components.AmountByProductBatchID				AS AmountByProductBatchID,
	|	&NumberOfComponents_				AS NumberOfComponents_
	|INTO TTComponents
	|FROM
	|	&Components AS Components
	|
	|INDEX BY
	|	ProductBatchIDNumber,
	|	UnitOfMeasure,
	|	QuantityByGBRN,
	|	AmountByProductBatchID,
	|	NumberOfComponents_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CCDNumbers.Ref						AS Ref,
	|	Components.ProductBatchIDNumber					AS ProductBatchIDNumber,
	|	Components.FEACNUnitOfMeasure		AS UnitOfMeasure,
	|	Components.QuantityByGBRN			AS QuantityByGBRN,
	|	Components.AmountByProductBatchID				AS AmountByProductBatchID,
	|	CCDNumbers.NumberOfComponents_		AS NumberOfComponents_
	|INTO AccessoriesOfDoubles
	|FROM
	|	Catalog.CCDNumbers.TraceableComponents AS Components
	|		INNER JOIN Catalog.CCDNumbers AS CCDNumbers
	|		ON CCDNumbers.Ref = Components.Ref
	|
	|WHERE
	|	CCDNumbers.Ref <> &Ref
	|	AND NOT CCDNumbers.DeletionMark
	|	AND CCDNumbers.Code = &Code
	|	AND CCDNumbers.OriginCountry = &OriginCountry
	|	AND CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT)
	|
	|INDEX BY
	|	ProductBatchIDNumber,
	|	UnitOfMeasure,
	|	QuantityByGBRN,
	|	AmountByProductBatchID,
	|	NumberOfComponents_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccessoriesOfDoubles.Ref				AS Ref,
	|	Components.ProductBatchIDNumber					AS ProductBatchIDNumber,
	|	Components.UnitOfMeasure			AS UnitOfMeasure,
	|	Components.NumberOfComponents_	AS NumberOfComponents_
	|INTO AccessoriesOfDuplicatesForSelection
	|FROM
	|	TTComponents AS Components
	|		INNER JOIN AccessoriesOfDoubles AS AccessoriesOfDoubles
	|		ON Components.ProductBatchIDNumber = AccessoriesOfDoubles.ProductBatchIDNumber
	|			AND Components.UnitOfMeasure = AccessoriesOfDoubles.UnitOfMeasure
	|			AND Components.QuantityByGBRN = AccessoriesOfDoubles.QuantityByGBRN
	|			AND Components.AmountByProductBatchID = AccessoriesOfDoubles.AmountByProductBatchID
	|			AND Components.NumberOfComponents_ = AccessoriesOfDoubles.NumberOfComponents_
	|
	|INDEX BY
	|	Ref,
	|	NumberOfComponents_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Components.Ref	AS Ref,
	|	COUNT(*)			AS NumberOfComponents_
	|INTO NumberOfComponentDoubles
	|FROM
	|	AccessoriesOfDuplicatesForSelection AS Components
	|
	|GROUP BY
	|	Components.Ref
	|
	|INDEX BY
	|	Ref,
	|	NumberOfComponents_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Components.Ref AS Ref
	|FROM
	|	AccessoriesOfDuplicatesForSelection AS Components
	|		INNER JOIN NumberOfComponentDoubles AS NumberOfComponentDoubles
	|		ON Components.Ref = NumberOfComponentDoubles.Ref
	|			AND Components.NumberOfComponents_ = NumberOfComponentDoubles.NumberOfComponents_";
	
	GroupColumns	= "ProductBatchIDNumber, FEACNUnitOfMeasure";
	TotalingColumns	= "QuantityByGBRN, AmountByProductBatchID";
	
	TableOfComponents = Object.TraceableComponents.Unload();
	TableOfComponents.GroupBy(GroupColumns, TotalingColumns);
	
	Query.SetParameter("Ref",						Object.Ref);
	Query.SetParameter("Code",						Object.Code);
	Query.SetParameter("OriginCountry",		Object.OriginCountry);
	Query.SetParameter("Components",				TableOfComponents);
	Query.SetParameter("NumberOfComponents_",	TableOfComponents.Count());
	
	TableFound.Load(Query.Execute().Unload());
	
	If TableFound.Count() > 0 Then
		Cancel = True;
		
		Return PutToTempStorage(TableFound.Unload(), UUID);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClient
Procedure WriteElement(Cancel)
	
	If Not Cancel Then
		ControlOfUniquenessIsCarriedOut = True;
		
		Try
			If Not Write() Then
				Cancel = True;
			EndIf;
		Except
			Cancel = True;
			ControlOfUniquenessIsCarriedOut = False;
			
			Return;
		EndTry;
		
		If Cancel Then
			ControlOfUniquenessIsCarriedOut = False;
			
			Return;
		EndIf;
	
	EndIf;
	
EndProcedure

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
	
	If Not UseTraceableImportedGoodsAccounting Then
		Return;
	EndIf;
	
	//
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields,
														Items.TraceableComponentsCode.Name);
	
	CommonClientServer.AddCompositionItem(Item.Filter,
															Items.TraceableComponentsCode.DataPath,
															DataCompositionComparisonType.NotFilled);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields,
														Items.TraceableComponentsCode.Name);
	
	CommonClientServer.AddCompositionItem(Item.Filter,
															Items.TraceableComponentsCode.DataPath,
															DataCompositionComparisonType.Filled);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
	
	CreationParameters = Undefined;
	
	If Parameters.Property("CreationParameters", CreationParameters)
		And TypeOf(CreationParameters) = Type("Structure") Then
		
		CreationData = PurchasesServer.DefaultCCDNumberCreationParameters();
		InitializeCreationData(CreationData, CreationParameters);
		
		FillPropertyValues(ThisObject, CreationData);
		TMCommonUseClientServer.FillInValuesOfEmptyProperties(Object, CreationData);
		
		Currency = AccountingForTraceableGoodsLocalization.LocalAccountingCurrencyOfCCDNumber();
		
		If Not CreationParameters.Property("UseTraceableImportedGoodsAccounting") Then
			UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
																Date(1, 1, 1));
		EndIf;
		
		TMCommonUseClientServer.FillInValuesOfEmptyProperties(Object, CreationData.ProductData_8);
		InitializeCostIndicators(CreationData, CreationData.ProductData_8);
		
		If ValueIsFilled(Object.Products)
			And Not ValueIsFilled(Object.OriginCountry) Then
			
			Object.OriginCountry = Common.ObjectAttributeValue(Object.Products,
																					"OriginCountry");
			
		EndIf;
		
	Else
		UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
															Date(1, 1, 1));
	EndIf;
	
	ItemsType = Undefined;
	UnitOfFEAOfItem = Undefined;
	
	If ValueIsFilled(Object.Products) Then
		AttributesNames			= "ItemsType, TracedGoods, OriginCountry, FEACNUnitOfMeasure";
		ProductAttributes	= Common.ObjectAttributesValues(Object.Products, AttributesNames);
		
		ItemsType		= ProductAttributes.ItemsType;
		TracedGoods	= ?(ValueIsFilled(ProductAttributes.TracedGoods),
								ProductAttributes.TracedGoods,
								False);
		
		If Not ValueIsFilled(Object.OriginCountry) Then
			Object.OriginCountry = ProductAttributes.OriginCountry;
		EndIf;
		
		If ValueIsFilled(ProductAttributes.FEACNUnitOfMeasure) Then
			UnitOfFEAOfItem = ProductAttributes.FEACNUnitOfMeasure;
		EndIf;
		
		Object.CCDNumberType = ?(TracedGoods
									And UseTraceableImportedGoodsAccounting,
								Enums.CCDNumberTypes.ProductBatchIDNumber,
								Enums.CCDNumberTypes.CCDNumber);
		
		If TracedGoods
			And UseTraceableImportedGoodsAccounting Then
			
			Items.CCDNumberType.ChoiceList.LoadValues(
				AccountingForTraceableGoodsClientServerLocalization.CCDNumberTypes(True));
			
		Else
			Items.CCDNumberType.Visible = False;
		EndIf;
	Else
		Object.CCDNumberType = ?(ValueIsFilled(Object.CCDNumberType),
								Object.CCDNumberType,
								Enums.CCDNumberTypes.CCDNumber);
	EndIf;
	
	If Object.CCDNumberType = Enums.CCDNumberTypes.CCDNumber Then
		Attributes = RegistrationNumberAndCountryOfImportation(Object.Code);
		
		FillPropertyValues(Object, Attributes);
	ElsIf Object.CCDNumberType = Enums.CCDNumberTypes.ProductBatchIDNumber Then
		Object.RegistrationNumber = Object.Code;
		
		If ValueIsFilled(UnitOfFEAOfItem)
			And ItemsType <> Enums.ItemsTypes.Work_5 Then
			
			Object.UnitOfMeasure = UnitOfFEAOfItem;
		Else
			FillInUnitOfFuelTaxByDefault();
			
			Object.UnitOfMeasure = FEACNUnitOfMeasure;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CurrentTextDeclarationNumbers = ?(Object.CCDNumberType = Enums.CCDNumberTypes.KitRNPT,
									"",
									Object.Code);
	
	If ValueIsFilled(Object.Ref) Then
		UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
															Date(1, 1, 1));
	EndIf;
	
	CorrectPeriod = PurchasesServer.CorrectPeriodForEnteringDocumentsCustomsDeclarationNumbers();
	BeginningOfCorrectPeriod	= CorrectPeriod.BeginningOfCorrectPeriod;
	EndOfCorrectPeriod		= CorrectPeriod.EndOfCorrectPeriod;
	
	If ValueIsFilled(Object.Products) Then
		ProductData_1 = ProductData_1(Object.Products);
		FillPropertyValues(ThisObject, ProductData_1, , "FEACNUnitOfMeasure");
		
		If Not ValueIsFilled(Object.ProductName) Then
			Object.ProductName = ProductData_1.DescriptionFull;
		EndIf;
		
		If Not ValueIsFilled(Object.UnitOfMeasure) Then
			Object.UnitOfMeasure = ?(ProductData_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5"),
										FEACNUnitOfMeasure,
										ProductData_1.FEACNUnitOfMeasure);
		EndIf;
	EndIf;
	
	Currency = AccountingForTraceableGoodsLocalization.LocalAccountingCurrencyOfCCDNumber();
	UnitOfValue = UnitOfValue(Object.CCDNumberType,
															Object.UnitOfMeasure);
	
	FillInUnitOfFuelTaxByDefault();
	FillInServiceDataOfTrackedComponents();
	
	CustomizeForm(ThisObject);
	CreatePresentationOfTDNumber();
	SetPresentationOfUnitOfValue(Items.PresentationOfCostUnit.Title,
													Currency,
													UnitOfValue);
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers,
										BeginningOfCorrectPeriod,
										EndOfCorrectPeriod,
										Items.ErrorInTheCustomsDeclarationNumber);
	
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
	
	If Not CreationParameters.ShowCostByDocument Then
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
	
	If ProductData_1.KitCount <> 0 Then
		Object.AmountByProductBatchID = Round(Object.AmountByProductBatchID / ProductData_1.KitCount, 2);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function UnitOfValue(CCDNumberType, UnitOfMeasure)
	
	UnitOfValue = ?(CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber"),
									UnitOfMeasure,
									PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	
	Return UnitOfValue;
	
EndFunction

&AtServer
Procedure FillInUnitOfFuelTaxByDefault()
	
	If ValueIsFilled(FEACNUnitOfMeasure) Then
		Return;
	EndIf;
	
	ClassifierData	= Catalogs.PackagesAndUnitsOfMeasure.FillInUnitsFromClassifier("796");
	FEACNUnitOfMeasure	= ClassifierData["796"];
	
EndProcedure

&AtServer
Procedure FillInServiceDataOfTrackedComponents()
	
	Components = Object.TraceableComponents;
	
	If Components.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Components.LineNumber AS LineNumber,
	|	CAST(Components.ProductBatchIDNumber AS Catalog.CCDNumbers) AS ProductBatchIDNumber
	|INTO TTComponents
	|FROM
	|	&Components AS Components
	|
	|WHERE
	|	Components.ProductBatchIDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Components.LineNumber AS LineNumber,
	|	TRUE AS StatusOfRPTNumber,
	|	ISNULL(Components.ProductBatchIDNumber.Code, """") AS Code
	|FROM
	|	TTComponents AS Components
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("Components", Components.Unload(, "LineNumber, ProductBatchIDNumber"));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	FillableProperties = "StatusOfRPTNumber, Code";
	
	While Selection.Next() Do
		FillPropertyValues(Components[Selection.LineNumber - 1], Selection, FillableProperties);
	EndDo;
	
EndProcedure

// Parameters:
//	Form - ClientApplicationForm - the form of the Catalog element.
//
&AtClientAtServerNoContext
Procedure CustomizeForm(Form)
	
	Object		= Form.Object;
	Items	= Form.Items;
	
	ThisIsCCD				= Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.CCDNumber");
	ThisIsRNPTOfKit	= Form.UseTraceableImportedGoodsAccounting
							And Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT");
	
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
	
	Items.TraceabilityDataGroup.Visible			= Not ThisIsCCD
																And Form.UseTraceableImportedGoodsAccounting;
	Items.UnitOfMeasure.Visible						= Not ThisIsCCD
																And Not ThisIsRNPTOfKit
																And Form.UseTraceableImportedGoodsAccounting;
	Items.TraceableComponentsGroup.Visible	= ThisIsRNPTOfKit;
	
	SetFormHeader(Form);
	
EndProcedure

// Parameters:
//	Form - ClientApplicationForm - the form of the Catalog element.
//
&AtClientAtServerNoContext
Procedure SetFormHeader(Form)
	
	Object = Form.Object;
	
	If ValueIsFilled(Object.Ref) Then
		TitleTemplate1 = NStr("vi = '%1 (Số tờ khai hải quan hàng hóa)';
								|ru = '%1 (Номер грузовой таможенной декларации)';
								|en = '%1 (Cargo customs declaration number)'; fa = '%1 (Cargo customs declaration number)';
								|it = '%1 (Il numero della polizza doganale di carico)';
								|pl = '%1 (Numer ładunkowej deklaracji celnej)';
								|tr = '%1 (kargo gümrük beyannamesi numarası)'");
		
		If Form.UseTraceableImportedGoodsAccounting Then
			If Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber") Then
				TitleTemplate1 = NStr("vi = '%1 (Số đăng ký lô hàng)';
										|ru = '%1 (Номер РНПТ)';
										|en = '%1 (RNPT)'; fa = '%1 (RNPT)';
										|it = '%1 (Numero di registrazione lotti prodotti)';
										|pl = '%1 (Numer rejestracyjny partii towaru)';
										|tr = '%1 (RNTP Numarası)'");
			ElsIf Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
				TitleTemplate1 = NStr("vi = '%1 (Số đăng ký lô hàng bộ sản phẩm)';
										|ru = '%1 (Номер РНПТ комплекта)';
										|en = '%1 (Kit RNPT)'; fa = '%1 (Kit RNPT)';
										|it = '%1 (Numero di registrazione lotti prodotti del set)';
										|pl = '%1 (Numer rejestracyjny partii towaru zestawu)';
										|tr = '%1 (Set RNPT Numarası)'");
			EndIf;
		EndIf;
		
		TitleText = StrTemplate(TitleTemplate1, TrimAll(String(Object.Ref)));
	Else
		TitleText = NStr("vi = 'Số tờ khai hải quan hàng hóa (tạo mới)';
						|ru = 'Номер грузовой таможенной декларации (создание)';
						|en = 'Cargo customs declaration number (create)'; fa = 'Cargo customs declaration number (create)';
						|it = 'Numero della polizza doganale di carico (creare)';
						|pl = 'Numer ładunkowej deklaracji celnej (tworzenie)';
						|tr = 'Kargo gümrük beyannamesi numarası (oluşturma)'");
		
		If Form.UseTraceableImportedGoodsAccounting Then
			If Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber") Then
				TitleText = NStr("vi = 'Số đăng ký lô hàng (tạo mới)';
								|ru = 'Номер РНПТ (создание)';
								|en = 'RNPT (create)'; fa = 'RNPT (create)';
								|it = 'Numero di registrazione lotti prodotti (creare)';
								|pl = 'Numer rejestracyjny partii towaru (tworzenie)';
								|tr = 'RNPT Numarası (oluşturma)'");
			ElsIf Object.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
				TitleText = NStr("vi = 'Số đăng ký lô hàng bộ sản phẩm (tạo mới)';
								|ru = 'Номер РНПТ комплекта (создание)';
								|en = 'Kit RNPT create)'; fa = 'Kit RNPT create)';
								|it = 'Numero di registrazione lotti prodotti del set (creare)';
								|pl = 'Numer rejestracyjny partii towaru zestawu (tworzenie)';
								|tr = 'Set RNPT Numarası (oluşturma)'");
			EndIf;
		EndIf;
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
		
		Term1 = New FormattedString(NStr("vi = 'Tờ khai đã ghi nhận:';
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

&AtServerNoContext
Function LineDataByCodeAndCountryOfOrigin(CurrentRef, Val Code, OriginCountry, FEACNUnitOfMeasure)
	
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
	|	CCDNumbers.Ref <> &CurrentRef
	|	AND NOT CCDNumbers.DeletionMark
	|	AND CCDNumbers.Code = &Code
	|	AND CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|
	|ORDER BY
	|	Code";
	
	Query.SetParameter("CurrentRef",	CurrentRef);
	Query.SetParameter("Code",			TrimAll(Code));
	
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

// Parameters:
//	CurrentRow - FormDataCollectionItem - a row of the table part that contains the following properties:
//		* LineNumber - Number - line number of the table part.
//
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
			
			CurrentRow.QuantityByGBRN	= CurrentRow.QuantityByGBRN + Components[IndexOf].QuantityByGBRN;
			CurrentRow.AmountByProductBatchID		= CurrentRow.AmountByProductBatchID + Components[IndexOf].AmountByProductBatchID;
		Else
			RowToDelete = CurrentRow;
			
			Components[IndexOf].QuantityByGBRN	= Components[IndexOf].QuantityByGBRN + CurrentRow.QuantityByGBRN;
			Components[IndexOf].AmountByProductBatchID		= Components[IndexOf].AmountByProductBatchID + CurrentRow.AmountByProductBatchID;
		EndIf;
		
		Break;
		
	EndDo;
	
	If RowToDelete <> Undefined Then
		Components.Delete(RowToDelete);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion