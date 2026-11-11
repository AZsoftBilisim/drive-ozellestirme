#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.UUID = Undefined Then
		Raise NStr("vi = 'Xem xét mở bộ xử lý chỉ từ biểu mẫu của đối tượng.';
					|ru = 'Предусмотрено открытие обработки только из форм объектов.';
					|en = 'Data processor can be opened only from object forms.'; fa = 'Data processor can be opened only from object forms.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme degli oggetti.';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z form obiektów.';
					|tr = 'İşleme sadece nesne formlarından açılır.'");
	EndIf;
	
	CalledFormID = Parameters.UUID;
	
	If Parameters.Property("KeepRecordsOfQualityCertificates") Then
		KeepRecordsOfQualityCertificates = True;
	EndIf;
	If Parameters.Property("DisableCharacteristics") Then
		DisableCharacteristics = Parameters.DisableCharacteristics;
	EndIf;
	
	If Parameters.Property("FilterByProductType") And ValueIsFilled(Parameters.FilterByProductType) Then
		If TypeOf(Parameters.FilterByProductType) = Type("FixedArray") Then
			FilterByProductType.LoadValues(New Array(Parameters.FilterByProductType));
		ElsIf TypeOf(Parameters.FilterByProductType) = Type("EnumRef.ItemsTypes") Then
			FilterByProductType.Add(Parameters.FilterByProductType);
		Else
			FilterByProductType.LoadValues(Parameters.FilterByProductType);
		EndIf;
	EndIf;
	
	If ValueIsFilled(Parameters.SetPriceCalculationOptions) Then
		SetPriceCalculationOptions.LoadValues(Parameters.SetPriceCalculationOptions);
	EndIf;
	
	If Parameters.SelectThePartnerSNomenclature
		And ValueIsFilled(Parameters.Partner) Then
		
		SelectThePartnerSNomenclature = True;
		TemplateName = "TemplatePartnerSProducts";
		Partner = Parameters.Partner;
	
	ElsIf Parameters.UsePriceManagementSystem25 Then
		
		TemplateName = "Template2_5";
		UsePriceManagementSystem25 = True;
		
	Else

		TemplateName = "Template";
		
	EndIf;
	
	Items.GoodsPartnerProducts.Visible = Parameters.SelectThePartnerSNomenclature;
	
	
	LoadDefaultSelectionSettings();
	
	If Parameters.Property("ItemsCollection") Then
		FilterElement = DataCompositionClientServer.AddFilter(SettingsComposer, 
				"Products.ItemsCollection", 
				Parameters.ItemsCollection,
				DataCompositionComparisonType.Equal,
				True,
				New Structure("ToUserSettings", True));
		FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	If ValueIsFilled(Parameters.Title) Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	If ValueIsFilled(Parameters.TransferButtonTitle) Then
		Commands.MoveToDocument.Title = Parameters.TransferButtonTitle;
		Commands.MoveToDocument.ToolTip = Parameters.TransferButtonTitle;
	EndIf;
	
	If DisableCharacteristics Then
		Items.ProductsGroupFeatures.Visible = False;
	EndIf;
	 
	Items.GoodsCharacteristic.Visible 	= Not UsePriceManagementSystem25;
	Items.GoodsPricingVariant.Visible 	= UsePriceManagementSystem25;
	Items.GoodsPricingBatch.Visible 			= UsePriceManagementSystem25;
	Items.GoodsPricingPackage.Visible 		= UsePriceManagementSystem25;
	
	If Parameters.Property("SelectionOfProductsSettings") Then
		FillInTableOfProductsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not ClosingInProgress And Not MoveToDocument And Object.Goods.Count() > 0 Then
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Hàng hóa đã chọn chưa được chuyển vào chứng từ. Chuyển?';
																						|ru = 'Подобранные товары не перенесены в документ. Перенести?';
																						|en = 'Picked items are not added to the document. Do you want to add them?'; fa = 'Picked items are not added to the document. Do you want to add them?';
																						|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
																						|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
																						|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'"), QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();

	ElsIf UserAnswer = DialogReturnCode.Yes Then
		MoveToDocument = True;
		ClosingInProgress = True;
		GoodsAddressInStorage = PutItInTemporaryStorageOnServer();
		If Parameters.ChoiceMode Then
			NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));
			Close();
		Else
			Close(GoodsAddressInStorage);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	MoveToDocument = True;
	GoodsAddressInStorage = PutItInTemporaryStorageOnServer();
	If Parameters.ChoiceMode Then
		NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));
	Else
		Close(GoodsAddressInStorage);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheGoodsTable(Command)
	
	QueryText = NStr("vi = 'Khi điền lại, tất cả dữ liệu đã nhập thủ công sẽ mất, tiếp tục?';
					|ru = 'При перезаполнении все введенные вручную данные будут потеряны, продолжить?';
					|en = 'During repopulation all information entered manually will be lost, continue?'; fa = 'During repopulation all information entered manually will be lost, continue?';
					|it = 'Quando si ricompila, tutti i dati inseriti manualmente andranno persi, continuare?';
					|pl = 'Przy ponownym wypełnieniu wszystkie ręcznie wprowadzone dane zostaną utracone, kontynuować?';
					|tr = 'Yeniden doldurma sırasında manuel olarak girilen tüm veriler kaybolacaktır, devam edilsin mi?'");
	
	If Object.Goods.Count() > 0 Then
		ShowQueryBox(
			New CallbackDescription("FillInTheGoodsTableCompletion", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	Else
		FillInTableOfProductsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheGoodsTableCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInTableOfProductsOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Function SettingsStructure()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("RequiredFields"   , New Array);
	SettingsStructure.Insert("DataParameters"    , New Structure);
	SettingsStructure.Insert("SettingsComposer", Undefined);
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate" , Undefined);
	SettingsStructure.Insert("KeepRecordsOfQualityCertificates" , KeepRecordsOfQualityCertificates);
	SettingsStructure.Insert("PricesAsOfDate", Date(1, 1, 1));
	SettingsStructure.Insert("DateOfReceiptOfBalances", Date(1, 1, 1));
	SettingsStructure.Insert("Vendor", Catalogs.Partners.EmptyRef());
	SettingsStructure.Insert("KeepRecordsOfQualityCertificates" , KeepRecordsOfQualityCertificates);
	
	Return SettingsStructure;
	
EndFunction

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(Object.Goods.Unload(), CalledFormID);
	
EndFunction

&AtServer
Procedure FillInTableOfProductsOnServer(CheckFilling = True)
	
	// The fields required for output to the table of products on the form.
	SettingsStructure = SettingsStructure();
	
	If SelectThePartnerSNomenclature Then
		SettingsStructure.RequiredFields.Add("PartnerProducts");
		SettingsStructure.Vendor = Partner;
	EndIf;
	SettingsStructure.RequiredFields.Add("Products");
	If Not DisableCharacteristics Then
		If UsePriceManagementSystem25 Then
			If GetFunctionalOption("UseItemVariants") Then
				SettingsStructure.RequiredFields.Add("Characteristic");
				SettingsStructure.RequiredFields.Add("PricingVariant");
			EndIf;
			If GetFunctionalOption("UseItemsBatch") Then
				SettingsStructure.RequiredFields.Add("Series");
				SettingsStructure.RequiredFields.Add("PricingBatch");
			EndIf;
			If GetFunctionalOption("UseItemPackages") Then
				SettingsStructure.RequiredFields.Add("PricingPackage");
			EndIf;
		Else	
			If GetFunctionalOption("UseItemVariants") Then
				SettingsStructure.RequiredFields.Add("Characteristic");
			EndIf;
		EndIf;
	EndIf;
	
	SettingsComposerWithAdditionalSelection = New DataCompositionSettingsComposer;
	SettingsComposerWithAdditionalSelection.LoadSettings(SettingsComposer.Settings);
	
	If FilterByProductType.Count() > 0 Then
		Filter = SettingsComposerWithAdditionalSelection.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("Products.ItemsType");
		Filter.ComparisonType = DataCompositionComparisonType.InList;
		Filter.RightValue = FilterByProductType;
		Filter.Use = True;
	EndIf;
	
	If SetPriceCalculationOptions.Count() > 0 Then
		Filter = SettingsComposerWithAdditionalSelection.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("SetPricingOption");
		Filter.ComparisonType = DataCompositionComparisonType.InList;
		Filter.RightValue = SetPriceCalculationOptions;
		Filter.Use = True;
	EndIf;
	
	SettingsStructure.SettingsComposer = SettingsComposerWithAdditionalSelection;
	SettingsStructure.NameOfDataLayoutSchemaTemplate = TemplateName;
	
	Object.Goods.Clear();

	

	// Loading the generated list of products.
	ResultStructure1 = DataProcessors.GoodsSelectionByPicking.PrepareDataStructure(SettingsStructure);
	For Each TSRow In ResultStructure1.TableOfGoods Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, TSRow);
		
	EndDo;
	
	Items.Goods.Refresh();
	
EndProcedure

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate(TemplateName);

	

	SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, ThisForm.UUID)));
		
	If Parameters.Property("SelectionOfProductsSettings") And Parameters.SelectionOfProductsSettings <> Undefined Then
		SettingsComposer.LoadSettings(Parameters.SelectionOfProductsSettings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	UseProductRange = GetFunctionalOption("UseProductRange");
	If UseProductRange Then
		DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "ProductRangeAsOfDate", CurrentSessionDate());
	EndIf;
	If KeepRecordsOfQualityCertificates Then
		DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "KeepRecordsOfQualityCertificates", True);
	EndIf;

	
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
