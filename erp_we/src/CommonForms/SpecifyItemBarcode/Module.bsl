///////////////////////////////////////////////////////////////////////////////////////////////////////
// The Form is intended for registration or clarification of the item in the barcode information base.
// Allows you to upload the item found in the service to the information database.
//
// When opening the Form, you must specify notifications about closing the Form, to which the structure with the result
// of the Form will be passed.
//
// Form Parameters:
//	* Name - String - name of the tabular part to be filled in. The default value is "Products".
//	* Actions with unknown Barcodes - String - description of the action to be performed with unknown barcodes.
//													If the value "Registration is required" is specified, then it is expected that
//													the Form is open with the right to register register entries, and the Form element
//													Register is hiding.
//	* Unknown Barcodes - An array from the Structure - collection of item barcodes, where:
//		** Barcode - String - barcode of the item.
//		** Quantity - String - quantity of the item.

#Region Variables

&AtClient
Var ClosingInProgress; // To Transfer the Form closing flag to the handler before closing.

&AtClient
Var AskQuestionBeforeClosing; // To pass to the handler before closing, a sign of the need for a question.

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	InitializeDataAndConfigureForm();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClosingInProgress				= False;
	AskQuestionBeforeClosing	= True;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Register Then
		Return;
	EndIf;
	
	BarcodeIndicationMode = Items.GroupPages.CurrentPage = Items.ItemBarcodeRefinementGroup;
	
	CheckBatchCompletion(Cancel, BarcodeIndicationMode);
	CheckingNonUniqueItemBarcodes(Cancel, BarcodeIndicationMode);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And AskQuestionBeforeClosing Then
		
		Cancel = True;
		
		If Register
			And NonUniqueBarcodesOfNomenclature.Count() = 0
			And Items.GroupPages.CurrentPage = Items.ItemBarcodeRefinementGroup Then
			
			WarningText = NStr("ru = 'Регистрация штрихкода номенклатуры будет прервана.';
								|vi = 'Item barcode registration will be interrupted.';
								|en = 'Item barcode registration will be interrupted.'; fa = 'Item barcode registration will be interrupted.';
								|it = 'Item barcode registration will be interrupted.';
								|pl = 'Item barcode registration will be interrupted.';
								|tr = 'Ürün kalemi barkod kaydı durdurulacak.'");
			
		Else
			WarningText = NStr("ru = 'Уточнение штрихкода номенклатуры будет прервано.';
								|vi = 'Item barcode refinement will be interrupted.';
								|en = 'Item barcode refinement will be interrupted.'; fa = 'Item barcode refinement will be interrupted.';
								|it = 'Item barcode refinement will be interrupted.';
								|pl = 'Item barcode refinement will be interrupted.';
								|tr = 'Öğe barkodu detaylandırması durdurulacak.'");
		EndIf;
		
		Return;
		
	EndIf;
	
	If Not ClosingInProgress
		And AskQuestionBeforeClosing Then
		
		Cancel = True;
		
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		
		If Items.GroupPages.CurrentPage = Items.ItemBarcodeRefinementGroup Then
			QueryText = NStr("ru = 'Товар не будет перенесен в документ.
				|Отложите его в сторону как неотсканированный.';
				|vi = 'The item will not be transferred to the document.
				|Set it aside as unscanned.';
				|en = 'The item will not be transferred to the document.
				|Set it aside as unscanned.'; fa = 'The item will not be transferred to the document.
				|Set it aside as unscanned.';
				|it = 'The item will not be transferred to the document.
				|Set it aside as unscanned.';
				|pl = 'The item will not be transferred to the document.
				|Set it aside as unscanned.';
				|tr = 'Mal belgeye aktarılmayacak. 
				|Taranmamış olarak bir kenara koyun.'");
		Else
			QueryText = NStr("vi = 'Hàng hóa sẽ không được chuyển vào chứng từ.
				|Hãy hoãn lại hàng hóa sang một bên như là hàng hóa chưa được quét.';
				|ru = 'Товары не будут перенесены в документ.
				|Отложите их в сторону как неотсканированные.';
				|en = 'These barcodes are not registered in the application.
				|We cannot add these items to the document. Please place them aside.'; fa = 'These barcodes are not registered in the application.
				|We cannot add these items to the document. Please place them aside.';
				|it = 'I prodotti non saranno riportati nel documento.
				|Metteteli da parte come non scannerizzati.';
				|pl = 'Wiersze pozycji nie zostaną przeniesione do dokumentu.
				|Odłóż je na bok, jako nieskanowane.';
				|tr = 'Ürünler belgeye transfer edilmeyecektir.
				|Bunları taranmamış olarak kenara koy.'");
		EndIf;
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	CurrentRow = BarcodeData_1();
	
	ProcessingActionsONChangesToItemList(CurrentRow);
	FillPropertyValues(ThisObject, CurrentRow, , "Barcode");
	UpdateItemDetails(CurrentRow);
	SetItemsAvailability(Items, ProductAttributes);
	FillChoiceLists(Item.Name);
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	
	Dimension_On_Change(Item);
	
EndProcedure

&AtClient
Procedure SeriesOnChange(Item)
	
	Dimension_On_Change(Item);
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	CurrentRow = ?(ValueIsFilled(ProductAttributes), ProductAttributes, ProductAttributes());
	
	Dimension_On_Change(Item);
	UpdateItemDetails(CurrentRow);
	SetItemsAvailability(Items, ProductAttributes);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersItemsBarcodes

&AtClient
Procedure ItemsBarcodesOnActivateCell(Item)
	
	FieldName = Item.CurrentItem.Name;
	
	If FieldName = Items.ItemsBarcodesProducts.Name
		Or FieldName = Items.ItemsBarcodesCharacteristic.Name
		Or FieldName = Items.ItemsBarcodesSeries.Name
		Or FieldName = Items.ItemsBarcodesPackage.Name Then
		
		FillChoiceLists(FieldName, False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ItemsBarcodesProductsOnChange(Item)
	
	CurrentRow = Items.ItemsBarcodes.CurrentRow;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ProcessingActionsONChangesToItemList(CurrentRow, False);
	
EndProcedure

&AtClient
Procedure ItemsBarcodesCharacteristicOnChange(Item)
	
	ItemBarcodesDimensionONChange();
	
EndProcedure

&AtClient
Procedure ItemsBarcodesSeriesOnChange(Item)
	
	ItemBarcodesDimensionONChange();
	
EndProcedure

&AtClient
Procedure ItemsBarcodesPackageOnChange(Item)
	
	ItemBarcodesDimensionONChange();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	ClearMessages();
	
	Cancel = False;
	BarcodeIndicationMode = Items.GroupPages.CurrentPage = Items.ItemBarcodeRefinementGroup;
	
	CheckFillingInGoodsInformation(Cancel, BarcodeIndicationMode);
	
	If Cancel Then
		Return;
	EndIf;
	
	InitializeItemBarcodesForClosingParameters(BarcodeIndicationMode);
	
	CloseParameter = FormClosingParameters(Cancel, BarcodeIndicationMode);
	
	ClearItemBarcodesForClosingParameters(BarcodeIndicationMode);
	
	If Cancel Then
		Return;
	EndIf;
	
	If CloseParameter.UnregisteredProductsFound Then
		NotificationParameters	= New Structure("CloseParameter", CloseParameter);
		CallbackDescription	= New CallbackDescription("MoveToDocumentCompletion", ThisObject, NotificationParameters);
		
		QueryText = NStr("ru = 'Не для всех штрихкодов указана информация о товарах.
			|Эти товары не будут перенесены в документ.
			|Отложите их в сторону как неотсканированные.';
			|vi = 'Item information is not provided for all barcodes.
			|These items will not be transferred to the document. 
			|Set them aside as unscanned.';
			|en = 'Item information is not provided for all barcodes.
			|These items will not be transferred to the document. 
			|Set them aside as unscanned.'; fa = 'Item information is not provided for all barcodes.
			|These items will not be transferred to the document. 
			|Set them aside as unscanned.';
			|it = 'Item information is not provided for all barcodes.
			|These items will not be transferred to the document. 
			|Set them aside as unscanned.';
			|pl = 'Item information is not provided for all barcodes.
			|These items will not be transferred to the document. 
			|Set them aside as unscanned.';
			|tr = 'Tüm barkodlar için ürün bilgisi belirtilmemiş.
			| Bu ürünler belgeye aktarılmayacak.
			| Onları taranmamış olarak kenara ayırın.'");
		
		If BarcodeIndicationMode Then
			QueryText = NStr("ru = 'Для штрихкода не указана информация о товаре.
				|Этот товар не будет перенесен в документ.
				|Отложите его в сторону как неотсканированный.';
				|vi = 'No item information is provided for the barcode.
				|This item will not be transferred to the document.
				|Set it aside as unscanned.';
				|en = 'No item information is provided for the barcode.
				|This item will not be transferred to the document.
				|Set it aside as unscanned.'; fa = 'No item information is provided for the barcode.
				|This item will not be transferred to the document.
				|Set it aside as unscanned.';
				|it = 'No item information is provided for the barcode.
				|This item will not be transferred to the document.
				|Set it aside as unscanned.';
				|pl = 'No item information is provided for the barcode.
				|This item will not be transferred to the document.
				|Set it aside as unscanned.';
				|tr = 'Barkod için ürün bilgisi belirtilmemiş. 
				|Bu ürün belgeye aktarılmayacak.
				| Taranmamış olarak bir kenara koyun.'");
		EndIf;
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
		
		Return;
	EndIf;
	
	MoveFragmentToDocument(CloseParameter);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		Items.ItemsBarcodesCharacteristic.Name,
		"ItemsBarcodes.ItemVariantsAreUsed");
	
	//
	If GetFunctionalOption("UseItemsBatchWarehouse") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ItemsBarcodesSeries.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.SeriesAreUsed");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng sê-ri>';
														|ru = '<серии не используются>';
														|en = '<batches are not used>'; fa = '<batches are not used>';
														|it = '<le serie non sono utilizzate>';
														|pl = '<serie nie są używane>';
														|tr = '<partiler kullanılmamaktadır>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	
	//
	AdditionalParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	AdditionalParameters.NameOfUnitField	= Items.ItemsBarcodesUnitOfMeasure.Name;
	AdditionalParameters.PathToPackagingUnitField		= "ItemsBarcodes.Package";
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, AdditionalParameters);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesRegistered.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.Registered");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mới';
													|ru = 'Новый';
													|en = 'New'; fa = 'جدید';
													|it = 'Nuovo';
													|pl = 'New';
													|tr = 'Yeni'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesRegistered.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.Registered");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã ghi nhận';
													|ru = 'Зарегистрирован';
													|en = 'Registered'; fa = 'ثبت‌شده';
													|it = 'Registrato';
													|pl = 'Registered';
													|tr = 'Kaydedildi'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.CurrentSubscriptionColor);
	
EndProcedure

&AtServer
Procedure InitializeDataAndConfigureForm()
	
	TSName					= Parameters.TSName;
	UnknownBarcodes	= NormalizedUnknownBarcodes();
	BarcodeIndicationMode	= UnknownBarcodes.Count() = 1;
	Register		= BarcodingOfItemsServer.ProductBarcodeRegistrationRightIsAvailable();
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	FillInNonUniqueItemBarcodes(UnknownBarcodes);
	FillInItemBarcodeSpecification(BarcodeIndicationMode, UnknownBarcodes);
	FillInItemBarcodes(BarcodeIndicationMode, UnknownBarcodes);
	CustomizeForm(BarcodeIndicationMode);
	
EndProcedure

&AtServer
Function NormalizedUnknownBarcodes()
	
	UnknownBarcodes = ItemsBarcodes.Unload(, "Barcode, Count");
	UnknownBarcodes.Columns.Add("NormalizedBarcode",
											Metadata.InformationRegisters.ItemsBarcodes.Dimensions.Barcode.Type);
	
	For Each BarcodeData_1 In Parameters.UnknownBarcodes Do
		TSRow = UnknownBarcodes.Add();
		FillPropertyValues(TSRow, BarcodeData_1);
		
		TSRow.NormalizedBarcode = Upper(TrimAll(BarcodeData_1.Barcode));
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BarcodeData_5.Barcode					AS Barcode,
	|	BarcodeData_5.NormalizedBarcode	AS NormalizedBarcode,
	|	BarcodeData_5.Count					AS Count
	|INTO UnknownBarcodes
	|FROM
	|	&UnknownBarcodes AS BarcodeData_5
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(BarcodeData_5.Barcode)			AS Barcode,
	|	BarcodeData_5.NormalizedBarcode	AS NormalizedBarcode,
	|	SUM(BarcodeData_5.Count)			AS Count
	|FROM
	|	UnknownBarcodes AS BarcodeData_5
	|
	|GROUP BY
	|	BarcodeData_5.NormalizedBarcode";
	
	Query.SetParameter("UnknownBarcodes", UnknownBarcodes);
	
	Selection = Query.Execute().Select();
	
	NormalizedUnknownBarcodes = New Array;
	
	While Selection.Next() Do
		BarcodeData_1 = New Structure("Barcode, Count");
		FillPropertyValues(BarcodeData_1, Selection);
		
		NormalizedUnknownBarcodes.Add(BarcodeData_1);
	EndDo;
	
	Return NormalizedUnknownBarcodes;
	
EndFunction

&AtServer
Procedure FillInNonUniqueItemBarcodes(UnknownBarcodes)
	
	CachedValues			= BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	PreviouslyUnencashedBarcodes	= New Array;
	
	For Each BarcodeData_1 In UnknownBarcodes Do
		PreviouslyUnencashedBarcodes.Add(BarcodeData_1.Barcode);
	EndDo;
	
	InformationRegisters.ItemsBarcodes.GetDataOnBarcodesAdvanced(
		CachedValues,
		PreviouslyUnencashedBarcodes,
		True);
	
	For Each DataOfCache In CachedValues.Barcodes Do
		If TypeOf(DataOfCache.Value) <> Type("Array") Then
			Continue;
		Else
			CollectionOfBarcodeInformation = DataOfCache.Value; // Array of See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues -
		EndIf;
		
		For Each BarcodeData_1 In CollectionOfBarcodeInformation Do
			NewRow = NonUniqueBarcodesOfNomenclature.Add();
			FillPropertyValues(NewRow, BarcodeData_1);
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInItemBarcodeSpecification(BarcodeIndicationMode, UnknownBarcodes)
	
	If Not BarcodeIndicationMode Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, UnknownBarcodes[0]);
	
EndProcedure

&AtServer
Procedure FillInItemBarcodes(BarcodeIndicationMode, UnknownBarcodes)
	
	If BarcodeIndicationMode Then
		Return;
	EndIf;
	
	For Each BarcodeData_1 In UnknownBarcodes Do
		TSRow = ItemsBarcodes.Add();
		FillPropertyValues(TSRow, BarcodeData_1);
	EndDo;
	
EndProcedure

&AtServer
Procedure CustomizeForm(BarcodeIndicationMode)
	
	ThereAreNonUniqueBarcodes = NonUniqueBarcodesOfNomenclature.Count() > 0;
	
	Title		= NStr("ru = 'Уточнение штрихкода номенклатуры';
						|vi = 'Specify item barcode';
						|en = 'Specify item barcode'; fa = 'تعیین بارکد قلم';
						|it = 'Specify item barcode';
						|pl = 'Specify item barcode';
						|tr = 'Öğe barkodu detaylandırması'");
	ExplanationText	= NStr("ru = 'По штрихкоду найдено несколько товаров. Выберите товар, соответствующий штрихкоду.';
								|vi = 'Several items were found using the barcode. Select the item that matches the barcode.';
								|en = 'Several items were found using the barcode. Select the item that matches the barcode.'; fa = 'Several items were found using the barcode. Select the item that matches the barcode.';
								|it = 'Several items were found using the barcode. Select the item that matches the barcode.';
								|pl = 'Several items were found using the barcode. Select the item that matches the barcode.';
								|tr = 'Barkoda göre birden fazla ürün bulundu. Barkoda karşılık gelen ürünü seçin.'");
	
	If Register
		And BarcodeIndicationMode
		And Not ThereAreNonUniqueBarcodes Then
		
		Title = NStr("ru = 'Регистрация штрихкода номенклатуры';
					|vi = 'Item barcode registration';
					|en = 'Item barcode registration'; fa = 'Item barcode registration';
					|it = 'Item barcode registration';
					|pl = 'Item barcode registration';
					|tr = 'Öğe barkodunun kaydı'");
		
	EndIf;
	
	If Not BarcodeIndicationMode Then
		ExplanationText = NStr("ru = 'Товар по штрихкоду не определен. Укажите товар, соответствующий штрихкоду.';
								|vi = 'The item is not identified by barcode. Specify the item corresponding to the barcode.';
								|en = 'The item is not identified by barcode. Specify the item corresponding to the barcode.'; fa = 'The item is not identified by barcode. Specify the item corresponding to the barcode.';
								|it = 'The item is not identified by barcode. Specify the item corresponding to the barcode.';
								|pl = 'The item is not identified by barcode. Specify the item corresponding to the barcode.';
								|tr = 'Barkoda göre ürün belirlenemedi. Barkoda karşılık gelen ürünü belirtin.'");
	ElsIf Not ThereAreNonUniqueBarcodes Then
		ExplanationText = NStr("ru = 'Товар по штрихкоду не найден. Укажите товар, соответствующий штрихкоду.';
								|vi = 'The item is not found by barcode. Specify the item corresponding to the barcode.';
								|en = 'The item is not found by barcode. Specify the item corresponding to the barcode.'; fa = 'قلم با بارکد یافت نشد. قلم متناظر با بارکد را مشخص کنید.';
								|it = 'The item is not found by barcode. Specify the item corresponding to the barcode.';
								|pl = 'The item is not found by barcode. Specify the item corresponding to the barcode.';
								|tr = 'Barkoda göre ürün bulunamadı. Barkoda karşılık gelen ürünü belirtin'");
	EndIf;
	
	VisibilityOfSignOfRegistration = Register
									And Parameters.ActionsWithUnknownBarcodes <> "RegistrationRequired_";
	
	Items.ExplanationToForm.Title						= ExplanationText;
	Items.GroupPages.CurrentPage					= ?(BarcodeIndicationMode,
																Items.ItemBarcodeRefinementGroup,
																Items.ItemBarcodesGroup);
	Items.ItemBarcodeRefinementGroup.Visible	= BarcodeIndicationMode;
	Items.ItemBarcodesGroup.Visible			= Not BarcodeIndicationMode;
	Items.ToRegisterBarcode.Visible				= VisibilityOfSignOfRegistration;
	Items.RegisterBarcodes.Visible			= VisibilityOfSignOfRegistration;
	
	If BarcodeIndicationMode Then
		FormatIsRegistered = NStr("ru = 'БЛ=''Новый''; БИ=''Зарегистрирован''';
									|vi = 'BF=''New''; BT=''Registered''';
									|en = 'BF=''New''; BT=''Registered'''; fa = 'BF=''New''; BT=''Registered''';
									|it = 'BF=''New''; BT=''Registered''';
									|pl = 'BF=''New''; BT=''Registered''';
									|tr = 'BF=''Yeni''; BT=''Kayıtlı'''");
		
		Items.States1.Format		= FormatIsRegistered;
		Items.States1.TextColor	= StyleColors.SpecialTextColor;
		
		SetItemsAvailability(Items, ProductAttributes());
	Else
		Items.ExplanationToForm.MaxWidth = 0;
	EndIf;
	
	InitializeItemSelectionList(BarcodeIndicationMode, ThereAreNonUniqueBarcodes);
	
EndProcedure

&AtServer
Procedure InitializeItemSelectionList(BarcodeIndicationMode, ThereAreNonUniqueBarcodes)
	
	If Not (BarcodeIndicationMode
		And ThereAreNonUniqueBarcodes) Then
		
		Return;
		
	EndIf;
	
	ItemsSelectionList = Items.Products.ChoiceList;
	ItemsSelectionList.Clear();
	
	For Each BarcodeData_1 In NonUniqueBarcodesOfNomenclature Do
		FillListWithValue(ItemsSelectionList, BarcodeData_1.Products);
	EndDo;
	
	Items.Products.ChoiceHistoryOnInput = ?(ItemsSelectionList.Count() > 0,
													ChoiceHistoryOnInput.DontUse,
													ChoiceHistoryOnInput.Auto);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillListWithValue(ChoiceList, ListValue)
	
	If ValueIsFilled(ListValue)
		And ChoiceList.FindByValue(ListValue) = Undefined Then
		
		ChoiceList.Add(ListValue);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ProductAttributes()
	
	PackagingUnitIsDefaultUnit	= PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	
	ItemDetailsTemplate = New Structure;
	ItemDetailsTemplate.Insert("ItemVariantsAreUsed",	False);
	ItemDetailsTemplate.Insert("SeriesAreUsed",			False);
	ItemDetailsTemplate.Insert("Package",					PackagingUnitIsDefaultUnit);
	ItemDetailsTemplate.Insert("UnitOfMeasure",			PackagingUnitIsDefaultUnit);
	
	Return ItemDetailsTemplate;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Items, ProductAttributes)
	
	CharacteristicInputHint	= ?(Not ProductAttributes.ItemVariantsAreUsed,
										NStr("vi = '<không sử dụng đặc tính>';
											|ru = '<характеристики не используются>';
											|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
											|it = '<le caratteristiche non vengono usate>';
											|pl = '<charakterystyki nie dotyczą>';
											|tr = '<varyantlar kullanılmamaktadır>'"),
										"");
	BatchInputPrompt				= ?(Not ProductAttributes.SeriesAreUsed,
										NStr("vi = '<không sử dụng sê-ri>';
											|ru = '<серии не используются>';
											|en = '<batches are not used>'; fa = '<batches are not used>';
											|it = '<le serie non sono utilizzate>';
											|pl = '<serie nie są używane>';
											|tr = '<partiler kullanılmamaktadır>'"),
										"");
	PackagingUnitInputPrompt			= ?(Not ValueIsFilled(ProductAttributes.Package),
										String(ProductAttributes.UnitOfMeasure),
										"");
	
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Characteristic",
																	"Enabled",
																	ProductAttributes.ItemVariantsAreUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Characteristic",
																	"InputHint",
																	CharacteristicInputHint);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Series",
																	"Enabled",
																	ProductAttributes.SeriesAreUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Series",
																	"InputHint",
																	BatchInputPrompt);
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"Package",
																	"InputHint",
																	PackagingUnitInputPrompt);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	RowFilter				= New Structure("Barcode");
	BarcodeIndicationMode	= Items.GroupPages.CurrentPage = Items.ItemBarcodeRefinementGroup;
	
	For Each BarcodeData_1 In BarcodeData_5 Do
		If BarcodeIndicationMode Then
			If Barcode = BarcodeData_1.Barcode Then
				Count = Count + BarcodeData_1.Count;
			EndIf;
		Else
			FillPropertyValues(RowFilter, BarcodeData_1);
			FoundRows = ItemsBarcodes.FindRows(RowFilter);
			
			If FoundRows.Count() > 0 Then
				FoundRows[0].Count = FoundRows[0].Count + BarcodeData_1.Count;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckBatchCompletion(Cancel, BarcodeIndicationMode)
	
	If Not GetFunctionalOption("UseItemsBatchWarehouse") Then
		Return;
	EndIf;
	
	If BarcodeIndicationMode
		And Not (Not Registered
			And ValueIsFilled(Series)) Then
		
		Return;
		
	EndIf;
	
	InformationRegisters.ItemsBarcodes.CheckBatchCompletion(ItemsBarcodes, Cancel, BarcodeIndicationMode);
	
EndProcedure

&AtServer
Procedure CheckingNonUniqueItemBarcodes(Cancel, BarcodeIndicationMode)
	
	If Registered
		And BarcodeIndicationMode Then
		
		Return;
		
	EndIf;
	
	InformationRegisters.ItemsBarcodes.CheckingNonUniqueItemBarcodes(
		ItemsBarcodes,
		Cancel,
		BarcodeIndicationMode);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		ClosingInProgress = True;
		
		Close();
	EndIf;
	
EndProcedure

&AtClient
Function BarcodeData_1()
	
	BarcodeDetails =
		"Registered,
		|Barcode,
		|Products,
		|Characteristic,
		|ItemVariantsAreUsed,
		|SeriesAreUsed,
		|Series,
		|Package,
		|UnitOfMeasure";
	
	BarcodeData_1 = New Structure(BarcodeDetails);
	FillPropertyValues(BarcodeData_1, ThisObject);
	
	Return BarcodeData_1;
	
EndFunction

&AtServer
Procedure ProcessingActionsONChangesToItemList(BarcodeData_1, BarcodeIndicationMode = True)
	
	If BarcodeIndicationMode Then
		CurrentRow = BarcodeData_1;
	Else
		CurrentRow = ItemsBarcodes.FindByID(BarcodeData_1);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",	CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckBatchByOwner",				CurrentRow.Series);
	StructureOfActions.Insert("CheckFillPackageByOwner",	CurrentRow.Package);
	StructureOfActions.Insert("CheckBarcodeRegistration",			CurrentRow.Registered);
	
	If BarcodeIndicationMode Then
		FillInUnitOfMeasurementAttribute = New Structure("Products", "UnitOfMeasure");
		
		StructureOfActions.Insert("FillInUnitOfMeasurementAttribute", FillInUnitOfMeasurementAttribute);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	ConfigureRegistrationFields(CurrentRow, BarcodeIndicationMode);
	
EndProcedure

&AtServer
Procedure ConfigureRegistrationFields(CurrentRow, BarcodeIndicationMode)
	
	If BarcodeIndicationMode Then
		Registered = CurrentRow.Registered;
		
		Items.States1.TextColor = ?(Registered,
											StyleColors.CurrentSubscriptionColor,
											StyleColors.SpecialTextColor);
	ElsIf CurrentRow.Registered Then
		CurrentRow.RegisteredByDataProcessor = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateItemDetails(ProductData_1)
	
	ItemDetailsTemplate = ProductAttributes();
	FillPropertyValues(ItemDetailsTemplate, ProductData_1);
	FillPropertyValues(ItemDetailsTemplate, ThisObject);
	
	ProductAttributes = New FixedStructure(ItemDetailsTemplate);
	
EndProcedure

&AtClient
Procedure Dimension_On_Change(Item)
	
	CheckBarcodeRegistration(BarcodeData_1());
	FillChoiceLists(Item.Name);
	
EndProcedure

&AtServer
Procedure CheckBarcodeRegistration(BarcodeData_1, BarcodeIndicationMode = True)
	
	If BarcodeIndicationMode Then
		CurrentRow = BarcodeData_1;
	Else
		CurrentRow = ItemsBarcodes.FindByID(BarcodeData_1);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckBarcodeRegistration", CurrentRow.Registered);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	ConfigureRegistrationFields(CurrentRow, BarcodeIndicationMode);
	
EndProcedure

&AtClient
Procedure FillChoiceLists(FieldName, BarcodeIndicationMode = True)
	
	If NonUniqueBarcodesOfNomenclature.Count() = 0 Then
		Return;
	EndIf;
	
	If BarcodeIndicationMode Then
		CurrentRow = BarcodeData_1();
		FillPropertyValues(CurrentRow, ProductAttributes);
	Else
		CurrentRow = Items.ItemsBarcodes.CurrentData;
	EndIf;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FillInItemList		= False;
	FillInListOfCharacteristics	= False;
	FillInBatchList			= False;
	FillInPackagingUnitList			= False;
	
	NameOfProductsField		= ?(BarcodeIndicationMode,
								Items.Products.Name,
								Items.ItemsBarcodesProducts.Name);
	NameOfCharacteristicField	= ?(BarcodeIndicationMode,
								Items.Characteristic.Name,
								Items.ItemsBarcodesCharacteristic.Name);
	FieldNameSeries			= ?(BarcodeIndicationMode,
								Items.Series.Name,
								Items.ItemsBarcodesSeries.Name);
	PackagingUnitFieldName			= ?(BarcodeIndicationMode,
								Items.Package.Name,
								Items.ItemsBarcodesPackage.Name);
	
	FilterFields = New Array;
	
	If Not BarcodeIndicationMode Then
		FilterFields.Add("Barcode");
	EndIf;
	
	If NameOfProductsField = FieldName Then
		If Not BarcodeIndicationMode Then
			FillInItemList = True;
		ElsIf ValueIsFilled(CurrentRow.Products) Then
			FilterFields.Add("Products");
			
			FillInListOfCharacteristics	= CurrentRow.ItemVariantsAreUsed;
			FillInBatchList			= CurrentRow.SeriesAreUsed;
			FillInPackagingUnitList			= True;
		EndIf;
	ElsIf NameOfCharacteristicField = FieldName Then
		If Not BarcodeIndicationMode Then
			If CurrentRow.ItemVariantsAreUsed
				And ValueIsFilled(CurrentRow.Products) Then
				
				FilterFields.Add("Products");
				
				FillInListOfCharacteristics = True;
				
			EndIf;
		Else
			FilterFields.Add("Products");
			FilterFields.Add("Characteristic");
			
			FillInBatchList	= CurrentRow.SeriesAreUsed;
			FillInPackagingUnitList	= True;
		EndIf;
	ElsIf FieldNameSeries = FieldName Then
		If Not BarcodeIndicationMode Then
			If CurrentRow.SeriesAreUsed
				And ValueIsFilled(CurrentRow.Products) Then
				
				FilterFields.Add("Products");
				FilterFields.Add("Characteristic");
				
				FillInBatchList = True;
				
			EndIf
		Else
			FilterFields.Add("Products");
			FilterFields.Add("Characteristic");
			FilterFields.Add("Series");
			
			FillInPackagingUnitList = True;
		EndIf;
	Else
		If Not BarcodeIndicationMode Then
			If ValueIsFilled(CurrentRow.Products) Then
				FilterFields.Add("Products");
				FilterFields.Add("Characteristic");
				FilterFields.Add("Series");
				
				FillInPackagingUnitList = True;
			EndIf;
		EndIf;
	EndIf;
	
	If Not (FillInItemList
		Or FillInListOfCharacteristics
		Or FillInBatchList
		Or FillInPackagingUnitList) Then
		
		Return;
		
	EndIf;
	
	If FillInItemList Then
		ItemsSelectionList = Items[NameOfProductsField].ChoiceList;
		ItemsSelectionList.Clear();
	EndIf;
	
	If FillInListOfCharacteristics Then
		FeatureSelectionList = Items[NameOfCharacteristicField].ChoiceList;
		FeatureSelectionList.Clear();
	EndIf;
	
	If FillInBatchList Then
		BatchSelectionList = Items[FieldNameSeries].ChoiceList;
		BatchSelectionList.Clear();
	EndIf;
	
	If FillInPackagingUnitList Then
		SelectionListOfPackagingUnits = Items[PackagingUnitFieldName].ChoiceList;
		SelectionListOfPackagingUnits.Clear();
	EndIf;
	
	FilterRows = NonUniqueBarcodesOfNomenclature;
	
	If FilterFields.Count() > 0 Then
		NamesOfSelectionFields = StrConcat(FilterFields, ",");
		
		RowFilter = New Structure(NamesOfSelectionFields);
		FillPropertyValues(RowFilter, CurrentRow);
		
		FilterRows = NonUniqueBarcodesOfNomenclature.FindRows(RowFilter);
	EndIf;
	
	For Each BarcodeData_1 In FilterRows Do
		If FillInItemList Then
			FillListWithValue(ItemsSelectionList, BarcodeData_1.Products);
		EndIf;
		
		If FillInListOfCharacteristics Then
			FillListWithValue(FeatureSelectionList, BarcodeData_1.Characteristic);
		EndIf;
		
		If FillInBatchList Then
			FillListWithValue(BatchSelectionList, BarcodeData_1.Series);
		EndIf;
		
		If FillInPackagingUnitList Then
			FillListWithValue(SelectionListOfPackagingUnits, BarcodeData_1.Package);
		EndIf;
	EndDo;
	
	If FillInItemList Then
		Items[NameOfProductsField].ChoiceHistoryOnInput = ?(ItemsSelectionList.Count() > 0,
																ChoiceHistoryOnInput.DontUse,
																ChoiceHistoryOnInput.Auto);
	EndIf;
	
	If FillInListOfCharacteristics Then
		Items[NameOfCharacteristicField].ChoiceHistoryOnInput = ?(FeatureSelectionList.Count() > 0,
																	ChoiceHistoryOnInput.DontUse,
																	ChoiceHistoryOnInput.Auto);
	EndIf;
	
	If FillInBatchList Then
		Items[FieldNameSeries].ChoiceHistoryOnInput = ?(BatchSelectionList.Count() > 0,
														ChoiceHistoryOnInput.DontUse,
														ChoiceHistoryOnInput.Auto);
	EndIf;
	
	If FillInPackagingUnitList Then
		Items[PackagingUnitFieldName].ChoiceHistoryOnInput = ?(SelectionListOfPackagingUnits.Count() > 0,
															ChoiceHistoryOnInput.DontUse,
															ChoiceHistoryOnInput.Auto);
	EndIf
	
EndProcedure

&AtClient
Procedure ItemBarcodesDimensionONChange()
	
	CurrentRow = Items.ItemsBarcodes.CurrentRow;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CheckBarcodeRegistration(CurrentRow, False);
	
EndProcedure

&AtClient
Procedure CheckFillingInGoodsInformation(Cancel, BarcodeIndicationMode)
	
	If Not BarcodeIndicationMode Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Products) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Mặt hàng""';
							|ru = 'Поле ""Номенклатура"" не заполнено';
							|en = '""Product"" is not filled in'; fa = '""Product"" is not filled in';
							|it = 'Il campo ""Articolo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Номенклатура""';
							|tr = '""Ürün"" alanı doldurulmadı'");
		
		CommonClient.MessageToUser(MessageText, Undefined, "Products", "", Cancel);
	EndIf;
	
	If UseItemVariants
		And Not ValueIsFilled(Characteristic)
		And ProductAttributes <> Undefined
		And ProductAttributes.ItemVariantsAreUsed Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Đặc tính""';
							|ru = 'Поле ""Характеристика"" не заполнено';
							|en = '""Variant"" is not filled in'; fa = '""Variant"" is not filled in';
							|it = 'Il campo ""Caratteristica"" non è compilato';
							|pl = 'Pole ""Charakterystyka"" nie jest wypełnione';
							|tr = '""Varyant"" alanı doldurulmadı'");
		
		CommonClient.MessageToUser(MessageText, Undefined, "Characteristic", "", Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveToDocumentCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	MoveFragmentToDocument(AdditionalParameters.CloseParameter);
	
EndProcedure

&AtClient
Procedure MoveFragmentToDocument(CloseParameter)
	
	AskQuestionBeforeClosing	= False;
	CloseParameter.OwnerForm	= FormOwner.UUID;
	
	Close(CloseParameter);
	Notify("UnknownBarcodes", CloseParameter, "Peripherals");
	
EndProcedure

&AtClient
Procedure InitializeItemBarcodesForClosingParameters(BarcodeIndicationMode)
	
	If Not BarcodeIndicationMode Then
		Return;
	EndIf;
	
	TSRow = ItemsBarcodes.Add();
	FillPropertyValues(TSRow, ThisObject);
	FillPropertyValues(TSRow, ProductAttributes);
	
EndProcedure

&AtServer
Function FormClosingParameters(Cancel, BarcodeIndicationMode)
	
	CloseParameter = New Structure;
	CloseParameter.Insert("DeferredGoods",					New Array);
	CloseParameter.Insert("UnregisteredProductsFound",	False);
	CloseParameter.Insert("RegisteredBarcodes",		New Array);
	CloseParameter.Insert("NewBarcodesReceived",				New Array);
	CloseParameter.Insert("ItemsBarcodes",				New Array);
	CloseParameter.Insert("OwnerForm",						Undefined);
	CloseParameter.Insert("TSName",								TSName);
	
	If Register Then
		If CheckFilling() Then
			RegisterBarcodes(Cancel)
		Else
			Cancel = True;
		EndIf;
		
		If Cancel Then
			Return CloseParameter;
		EndIf;
	EndIf;
	
	BarcodeTable = ItemsBarcodes.Unload();
	BarcodeTable.Indexes.Add("Registered");
	
	If Register Then
		BarcodeTable.Indexes.Add("RegisteredByDataProcessor");
		BarcodeTable.Indexes.Add("Registered, RegisteredByDataProcessor");
		
		RowFilter = New Structure("RegisteredByDataProcessor", True);
		CloseParameter.RegisteredBarcodes = BarcodesByFilter(RowFilter, BarcodeTable);
		
		RowFilter = New Structure("Registered, RegisteredByDataProcessor", False, False);
		CloseParameter.DeferredGoods = BarcodesByFilter(RowFilter, BarcodeTable);
		CloseParameter.UnregisteredProductsFound = CloseParameter.DeferredGoods.Count() > 0;
	Else
		CloseParameter.DeferredGoods = DeferredGoods(BarcodeTable);
		CloseParameter.UnregisteredProductsFound = CloseParameter.DeferredGoods.Count() > 0;
	EndIf;
	
	RowFilter = New Structure("Registered", True);
	CloseParameter.NewBarcodesReceived = BarcodesByFilter(RowFilter, BarcodeTable);
	CloseParameter.ItemsBarcodes = BarcodeData_();
	
	Return CloseParameter;
	
EndFunction

&AtServer
Procedure RegisterBarcodes(Cancel)
	
	BarcodesForTesting	= ItemsBarcodes.Unload().CopyColumns();
	LinesToWorkOut		= New Array;
	
	For Each BarcodeData_1 In ItemsBarcodes Do
		If BarcodeData_1.Registered
			Or Not ValueIsFilled(BarcodeData_1.Products)
			Or (UseItemVariants
				And BarcodeData_1.ItemVariantsAreUsed
				And Not ValueIsFilled(BarcodeData_1.Characteristic)) Then
			
			Continue;
			
		EndIf;
		
		FillPropertyValues(BarcodesForTesting.Add(), BarcodeData_1);
		
		LinesToWorkOut.Add(BarcodeData_1);
	EndDo;
	
	If BarcodesForTesting.Count() > 0 Then
		BeginTransaction();
		
		Try
			RegisterProductsBarcodes(BarcodesForTesting);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			MessageText = NStr("ru = 'При записи штрихкодов произошла ошибка.
				|Дополнительное описание:
				|%1';
				|vi = 'An error occurred when saving barcodes.
				|Additional info:
				|%1';
				|en = 'An error occurred when saving barcodes.
				|Additional info:
				|%1'; fa = 'An error occurred when saving barcodes.
				|Additional info:
				|%1';
				|it = 'An error occurred when saving barcodes.
				|Additional info:
				|%1';
				|pl = 'An error occurred when saving barcodes.
				|Additional info:
				|%1';
				|tr = '%1Barkodlar kaydedilirken hata oluştu.
				| Ek açıklama:
				|'");
			MessageText = StrTemplate(MessageText, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(MessageText, , , , Cancel);
		EndTry;
		
		For Each BarcodeData_1 In LinesToWorkOut Do
			BarcodeData_1.RegisteredByDataProcessor = True;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure RegisterProductsBarcodes(BarcodesForTesting)
	
	InformationRegisters.ItemsBarcodes.RegisterProductsBarcodes(BarcodesForTesting);
	
EndProcedure

&AtServer
Function BarcodesByFilter(RowFilter, BarcodeTable)
	
	BarcodesByFilter	= New Array;
	FoundRows		= BarcodeTable.FindRows(RowFilter);
	
	For Each TSRow In FoundRows Do
		BarcodeData_1 = New Structure("Barcode, Count");
		FillPropertyValues(BarcodeData_1, TSRow);
		
		BarcodesByFilter.Add(BarcodeData_1);
	EndDo;
	
	Return BarcodesByFilter;
	
EndFunction

&AtServer
Function DeferredGoods(BarcodeTable)
	
	DeferredGoods	= New Array;
	RowFilter			= New Structure("Registered", False);
	FoundRows		= BarcodeTable.FindRows(RowFilter);
	
	For Each TSRow In FoundRows Do
		If IsBlankString(TSRow.Barcode) Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(TSRow.Products)
			Or (TSRow.ItemVariantsAreUsed
				And UseItemVariants
				And Not ValueIsFilled(TSRow.Characteristic)) Then
			
			BarcodeData_1 = New Structure("Barcode, Count");
			FillPropertyValues(BarcodeData_1, TSRow);
			
			DeferredGoods.Add(BarcodeData_1);
			
		EndIf;
	EndDo;
	
	Return DeferredGoods;
	
EndFunction

&AtServer
Function BarcodeData_()
	
	BarcodeData_ = New Array;
	
	For Each TSRow In ItemsBarcodes Do
		If Not IsBlankString(TSRow.Barcode)
			And ValueIsFilled(TSRow.Products)
			And (Not TSRow.ItemVariantsAreUsed
				Or (TSRow.ItemVariantsAreUsed
					And UseItemVariants
					And ValueIsFilled(TSRow.Characteristic))) Then
			
			BarcodeData_1 = DefaultBarcodeData();
			FillPropertyValues(BarcodeData_1, TSRow);
			
			BarcodeData_.Add(BarcodeData_1);
			
		EndIf;
	EndDo;
	
	Return BarcodeData_;
	
EndFunction

&AtServer
Function DefaultBarcodeData()
	
	BarcodeData = New Structure;
	BarcodeData.Insert("Registered",			False);
	BarcodeData.Insert("RegisteredByDataProcessor",	False);
	BarcodeData.Insert("Barcode",					"");
	BarcodeData.Insert("Products",				Catalogs.Products.EmptyRef());
	BarcodeData.Insert("Characteristic",			Catalogs.ItemsCharacteristics.EmptyRef());
	BarcodeData.Insert("Series",						Catalogs.ItemsBatches.EmptyRef());
	BarcodeData.Insert("Package",					Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	BarcodeData.Insert("Count",				0);
	
	Return BarcodeData;
	
EndFunction

&AtClient
Procedure ClearItemBarcodesForClosingParameters(BarcodeIndicationMode)
	
	If Not BarcodeIndicationMode Then
		Return;
	EndIf;
	
	ItemsBarcodes.Clear();
	
EndProcedure

#EndRegion
