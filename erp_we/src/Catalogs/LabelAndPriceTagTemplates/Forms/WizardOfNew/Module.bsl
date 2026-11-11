#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel);
	Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag);
	
	If GetFunctionalOption("UseBinLocationWarehousing", New Structure)
		 Or GetFunctionalOption("UseBinLocationWarehousingForInformation", New Structure) Then
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins);
	EndIf;
	If GetFunctionalOption("UseDeliveryManagement") Then
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery);
	EndIf;
	If GetFunctionalOption("UseItemsBatch") Then
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel);
	EndIf;
	If GetFunctionalOption("UsePackingLists") Then
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel);
	EndIf;
	Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape);
	Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper);
	If GetFunctionalOption("UseNonCurrentAssets2_2")
		Or GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape);
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper);
	EndIf;
	If GetFunctionalOption("UseSubAssets") Then
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape);
		Items.Purpose.ChoiceList.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper);
	EndIf;
	If TMCommonUseClientServer.HasObjectAttribute(Parameters, "FillingValues")
		And TypeOf(Parameters.FillingValues) = Type("Structure") Then
		FillPropertyValues(ThisObject, Parameters.FillingValues);
	EndIf;
	
	If Not ValueIsFilled(Purpose) Then
		Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel;
	EndIf;
	
	WhenChangingDestinationServer();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	Items.Purpose.ChoiceList.SortByPresentation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PurposeOnChange(Item)
	WhenChangingDestinationServer();
EndProcedure

&AtClient
Procedure TapeSizeOnChange(Item)
	
	TapeSizeWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure TapeSizeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PurposeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeInTheEditor(Command)
	
	CellSize = GetDimensions_(ThisForm);
	
	Close(Undefined);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("OpenEditor", True);
	OpeningParameters.Insert("TemplateName", SelectedTemplateName);
	OpeningParameters.Insert("Width", CellSize.Width);
	OpeningParameters.Insert("Height", CellSize.Height);
	OpeningParameters.Insert("Description", Description);
	OpeningParameters.Insert("Purpose", Purpose);
	
	OpenForm("Catalog.LabelAndPriceTagTemplates.ObjectForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure CommandNextTemplate(Command)
	CurrentTemplateIndex = CurrentTemplateIndex + 1;
	UpdateAll();
EndProcedure

&AtClient
Procedure CommandPreviousTemplate(Command)
	CurrentTemplateIndex = CurrentTemplateIndex - 1;
	UpdateAll();
EndProcedure

&AtServer
Procedure WhenChangingDestinationServer()
	
	TapeSize = "";
	TypeSearchStrings = New Array();
	
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		
		Title = NStr("vi = 'Trợ giúp tạo nhãn tem';
					|ru = 'Помощник создания этикетки';
					|en = 'Label Wizard'; fa = 'Label Wizard';
					|it = 'Aiutante di creazione delle etichette';
					|pl = 'Asystent tworzenia etykiety';
					|tr = 'Etiket oluşturma sihirbazı'");
		TypeSearchStrings.Add("LabelsTemplate");
		TypeSearchStrings.Add("LabelsTemplateH1");
		TypeSearchStrings.Add("LabelsTemplateH2");
		Items.TapeSize.Title = NStr("vi = 'Kích cỡ dải băng';
									|ru = 'Размер ленты';
									|en = 'Tape size'; fa = 'اندازه نوار';
									|it = 'Dimensione del nastro';
									|pl = 'Rozmiar taśmy';
									|tr = 'Bant boyutu'");
		Items.DescriptionOfPriceTagQuantity.Visible = False;
		
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape 
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape Then
	
		Title = NStr("vi = 'Trợ giúp tạo nhãn tem (in trên dải băng)';
					|ru = 'Помощник создания этикетки (печать на ленте)';
					|en = 'Label wizard — Tape'; fa = 'Label wizard — Tape';
					|it = 'Assistente di creazione dell''etichetta (stampa sul nastro)';
					|pl = 'Asystent utworzenia etykiety (drukowanie na taśmie)';
					|tr = 'Etiket oluşturma sihirbazı (bant üzerinde yazdırma)'");
		TypeSearchStrings.Add("LabelsTemplate");
		TypeSearchStrings.Add("LabelsTemplateH1");
		TypeSearchStrings.Add("LabelsTemplateH2");
		Items.TapeSize.Title = NStr("vi = 'Kích cỡ dải băng';
									|ru = 'Размер ленты';
									|en = 'Tape size'; fa = 'اندازه نوار';
									|it = 'Dimensione del nastro';
									|pl = 'Rozmiar taśmy';
									|tr = 'Bant boyutu'");
		Items.DescriptionOfPriceTagQuantity.Visible = False;
		
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then
	
		Title = NStr("vi = 'Trợ giúp tạo nhãn tem (in trên giấy)';
					|ru = 'Помощник создания этикетки (печать на бумаге)';
					|en = 'Label wizard — Sheet'; fa = 'Label wizard — Sheet';
					|it = 'Assistente di creazione dell''etichetta (stampa sulla carta)';
					|pl = 'Asystent utworzenia etykiety (drukowanie na papierze)';
					|tr = 'Etiket oluşturma sihirbazı (kağıt üzerinde yazdırma)'");
		TypeSearchStrings.Add("LabelsTemplate");
		TypeSearchStrings.Add("LabelsTemplateH1");
		TypeSearchStrings.Add("LabelsTemplateH2");
		Items.TapeSize.Title = NStr("vi = 'Kích cỡ giấy';
									|ru = 'Размер бумаги';
									|en = 'Paper size'; fa = 'اندازه کاغذ';
									|it = 'Dimensione della carta';
									|pl = 'Rozmiar papieru';
									|tr = 'Kağıt boyutu'");
		Items.DescriptionOfPriceTagQuantity.Visible = True;
		
	Else
		Title = NStr("vi = 'Trợ giúp tạo nhãn giá';
					|ru = 'Помощник создания ценника';
					|en = 'Price Tag Wizard'; fa = 'ویزارد برچسب قیمت';
					|it = 'Assistente di creazione dei cartellini prezzi';
					|pl = 'Asystent tworzenia cennika';
					|tr = 'Fiyat etiketi oluşturma sihirbazı'");
		TypeSearchStrings.Add("PriceTagTemplate");
		TypeSearchStrings.Add("PriceTagTemplateH1");
		TypeSearchStrings.Add("PriceTagTemplateH2");
		Items.TapeSize.Title = NStr("vi = 'Kích cỡ giấy';
									|ru = 'Размер бумаги';
									|en = 'Paper size'; fa = 'اندازه کاغذ';
									|it = 'Dimensione della carta';
									|pl = 'Rozmiar papieru';
									|tr = 'Kağıt boyutu'");
		Items.DescriptionOfPriceTagQuantity.Visible = True;
	EndIf;
	
	Templates = New Structure;
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		TemplateAttributeForProducts = "StorageBins";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		TemplateAttributeForProducts = "Goods";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
		TemplateAttributeForProducts = "Goods";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		TemplateAttributeForProducts = "Deliveries";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		TemplateAttributeForProducts = "ItemsBatches";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		TemplateAttributeForProducts = "PackingLists";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper Then
		TemplateAttributeForProducts = "Assets";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper Then
		TemplateAttributeForProducts = "SubAssets";
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then
		TemplateAttributeForProducts = "InventoryInOperation";
	EndIf;
		
	TypesArray = New Array;
	Items.ForWhat.ChooseType = False;
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		ForWhat = Catalogs.Products.EmptyRef();
		TypesArray.Add(Type("CatalogRef.Products"));
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		ForWhat = Catalogs.StorageBins.EmptyRef();
		TypesArray.Add(Type("CatalogRef.StorageBins"));
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		Items.ForWhat.ChooseType = True;
		ForWhat = Undefined;
		TypesArray.Add(Type("DocumentRef.CustomerInvoice"));
		TypesArray.Add(Type("DocumentRef.TransferOfGoodsToBailee"));
		TypesArray.Add(Type("DocumentRef.InventoryTransfer"));
		TypesArray.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		ForWhat = Catalogs.ItemsBatches.EmptyRef();
		TypesArray.Add(Type("CatalogRef.ItemsBatches"));
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		ForWhat = Documents.PackingList.EmptyRef();
		TypesArray.Add(Type("DocumentRef.PackingList"));
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper Then
		ForWhat = Catalogs.Assets.EmptyRef();
		TypesArray.Add(Type("CatalogRef.Assets"));
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper Then
		ForWhat = Catalogs.SubAssets.EmptyRef();
		TypesArray.Add(Type("CatalogRef.SubAssets"));
	EndIf;
	
	LabelAndPriceTagTemplatesLocalization.WhenYouChangeAssignmentToNewOne(
		ThisObject, TypeSearchStrings, TemplateAttributeForProducts, TypesArray);
		
	If TypesArray.Count() <> 0 Then
		Items.ForWhat.TypeRestriction = New TypeDescription(TypesArray);
		Items.ForWhat.Visible = True;
	Else
		Items.ForWhat.Visible = False;
		ForWhat = Undefined;
	EndIf; 
	
	Items.TapeSize.ChoiceList.Clear();
	AttributeLength = StrLen(TemplateAttributeForProducts);
	For Each Template In Metadata.Catalogs.LabelAndPriceTagTemplates.Templates Do
		If Template.TemplateType = Metadata.ObjectProperties.TemplateType.SpreadsheetDocument Then
			If Upper(Right(Template.Name, AttributeLength)) = Upper(TemplateAttributeForProducts) Then
				
				For Each TypeSearchString_ In TypeSearchStrings Do
					
					If StrFind(Template.Name, TypeSearchString_) > 0 Then
					
						Size = StrReplace(Template.Name, Left(Template.Name, StrFind(Template.Name, "_")), "");
						Size = StrReplace(Size, "_"+TemplateAttributeForProducts, "");
						
						If StrFind(Template.Name, "x") > 0 Then
							
							Var_Key = "Size"+Size;
							If Not Templates.Property(Var_Key) Then
								Templates.Insert(Var_Key, New Array);
							EndIf;
							Var_11_Template = Templates[Var_Key]; // Array
							Var_11_Template.Add(Template.Name);
							
							If Not ValueIsFilled(TapeSize) Then
								TapeSize = Size;
							EndIf;
							
							If Items.TapeSize.ChoiceList.FindByValue(Size) = Undefined Then
								Items.TapeSize.ChoiceList.Add(Size, Size);
							EndIf;
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	TapeSizeWhenChangedOnServer();
	
	FormEvents.WhenChangingElement(ThisObject, "Purpose");
	
EndProcedure

&AtClient
Procedure PrintSample(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(ForWhat) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Mục đích""';
							|ru = 'Не заполнено поле ""Для чего""';
							|en = '""For what"" is required'; fa = '""For what"" is required';
							|it = 'Il campo ""Per cosa"" non è compilato';
							|pl = 'Nie wypełniono pola ""W jakim celu""';
							|tr = '""Ne için"" alanı doldurulmadı'");
		CommonClient.MessageToUser(MessageText,,"ForWhat");
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.Products.EmptyRef"));
	
	If Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"PriceTagProducts",
			CommandParameter,
			Undefined,
			GetParametersForPrintingSampleProductPriceTag());
		
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelProducts_",
			CommandParameter,
			Undefined, 
			GetParametersForPrintingSampleProductLabel());
		
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelStorageCells",
			CommandParameter,
			Undefined,
			GetParametersForPrintingSampleLabelOfWarehouseCell());
		
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"ShippingLabel",
			CommandParameter,
			Undefined,
			GetParametersForPrintingSampleShippingLabels());
		
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"ItemsBatchLabel",
			CommandParameter,
			Undefined,
			GetParametersForPrintingSampleLabelsOfProductSeries());
			
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelPackingSheets",
			CommandParameter,
			Undefined, 
			GetParametersForPrintingSampleLabelsPackingSheets());
			
			
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape")
		Or Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelOfObjectsOfOperation",
			CommandParameter,
			Undefined, 
			GetParametersForPrintingSampleLabelOfObjectOfOperation());
	ElsIf Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape")
		Or Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper") Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelOfUnitOfObjectOfOperation",
			CommandParameter,
			Undefined, 
			GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation());
	Else
		ParametersForSamplePrinting = ParametersForSamplePrinting();
		PrintPriceTagsAndLabelsLocalizationClient.PrintSample(
			ParametersForSamplePrinting, CommandParameter, ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Function SaveAtServer()
	
	Size = GetDimensions_(ThisForm);
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	
	NewItem = Catalogs.LabelAndPriceTagTemplates.CreateItem();
	NewItem.Height       = Size.Height;
	NewItem.Width       = Size.Width;
	NewItem.CellSize = 5;
	NewItem.Purpose   = Purpose;
	NewItem.Description = Description;
	NewItem.ForWhat      = ForWhat;
	NewItem.Template       = New ValueStorage(TemplateParameters1);
	NewItem.Write();
	
	Return NewItem.Ref;
	
EndFunction

&AtClient
Procedure Save(Command)
	
	ClearMessages();
	If CheckFilling() Then
	
		Template = SaveAtServer();
		Notify("Write_LabelAndPriceTagTemplates", New Structure, Template);
		Close();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChange

&AtServer
Procedure TapeSizeWhenChangedOnServer()
	
	Var_Key = "Size"+TapeSize;
	
	CurrentTemplateIndex  = 1;
	TotalTemplates = Templates[Var_Key].Count();
	
	UpdateAll();
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function GetDimensions_(Form)
	
	Height = Number(StrReplace(Form.TapeSize, Left(Form.TapeSize, StrFind(Form.TapeSize, "x")), ""));
	Width = (StrReplace(Form.TapeSize, "x"+Height, ""));
	
	Return New Structure("Width,Height",Width,Height);
	
EndFunction

&AtServer
Function TemplateImageTemplate(TemplateName)
	
	CurrentLanguage = CurrentLanguage();
	If TypeOf(CurrentLanguage) = Type("MetadataObject") Then
		CurrentLanguage = CurrentLanguage.LanguageCode;
	EndIf;
	
	FullTemplateName = TemplateName + "_" + CurrentLanguage;
	If Metadata.Catalogs.LabelAndPriceTagTemplates.Templates.Find(FullTemplateName) <> Undefined Then
		ImageTemplate = Catalogs.LabelAndPriceTagTemplates.GetTemplate(FullTemplateName);
		Return ImageTemplate;
	EndIf;
	
	FullTemplateName = TemplateName + "_" + CommonClientServer.DefaultLanguageCode();
	If Metadata.Catalogs.LabelAndPriceTagTemplates.Templates.Find(FullTemplateName) <> Undefined Then
		ImageTemplate = Catalogs.LabelAndPriceTagTemplates.GetTemplate(FullTemplateName);
		Return ImageTemplate;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure UpdateAll()
	
	Var_Key = "Size" + TapeSize;
	
	Items.CommandNextTemplate.Enabled = Not (CurrentTemplateIndex = TotalTemplates);
	Items.CommandPreviousTemplate.Enabled = Not (CurrentTemplateIndex = 1);
	
	Items.CurrentNumber.Title = String(CurrentTemplateIndex) + " " + NStr("vi = 'từ';
																			|ru = 'из';
																			|en = 'from'; fa = 'از';
																			|it = 'da';
																			|pl = 'from';
																			|tr = '-den/dan'") + " " + TotalTemplates;
	
	TemplateName = Templates[Var_Key][CurrentTemplateIndex - 1];
	SelectedTemplateName = TemplateName;
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	
	ImageTemplate = TemplateImageTemplate(TemplateName + "Picture");
	PictureAddress = "";
	If Not(ImageTemplate = Undefined) Then
		PictureAddress = PutToTempStorage(ImageTemplate, UUID);
	EndIf;
	
	QuantityPerPage = Catalogs.LabelAndPriceTagTemplates.MaximumNumberPerPage(Template, Purpose);
	Items.DescriptionOfPriceTagQuantity.Title = QuantityPerPage.LongDesc;
	
	If TemplateParameters1.TemplateParameters.Count() > 0 Then
		ParameterNames = New Array;
		For Each KeyAndValue In TemplateParameters1.TemplateParameters Do
			ParameterNames.Add(KeyAndValue.Key);
		EndDo;
		LongDesc = New FormattedString(StrConcat(ParameterNames, ", "));
	Else
		LongDesc = New FormattedString(NStr("vi = 'Không có tham số';
											|ru = 'Нет параметров';
											|en = 'No parameters'; fa = 'No parameters';
											|it = 'Non ci sono parametri';
											|pl = 'Brak parametrów';
											|tr = 'Parametreler yok'"));
	EndIf;
	
EndProcedure

&AtServer
Function AddParametersForPrintingSample(PrintParameters, TemplateParameters1)
	
	PrintParameters.Insert("StructureOfTemplateTemplate", TemplateParameters1);
	
	Return PrintParameters;
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleProductLabel()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	CodeType = TemplateParameters1.CodeType;
	
	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleProductLabel(ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleProductPriceTag()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	CodeType = TemplateParameters1.CodeType;
	
	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleProductPriceTag(ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelOfWarehouseCell()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	CodeType = TemplateParameters1.CodeType;
	
	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelOfWarehouseCell(ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleShippingLabels()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	
	ObjectsArray = New Array;
	ObjectsArray.Add(ForWhat);
	
	PrintParameters = DataProcessors.PrintPriceTagsAndLabels.ShippingLabelPrintingData(ObjectsArray);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelsOfProductSeries()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	CodeType = TemplateParameters1.CodeType;
	
	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelsOfProductSeries(ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelsPackingSheets()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	CodeType = TemplateParameters1.CodeType;
	
	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelsPackingSheets(ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
		
EndFunction


&AtServer
Function GetParametersForPrintingSampleLabelOfObjectOfOperation()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelOfObjectOfOperation(
		ForWhat, TemplateParameters1.CodeType, UUID);

	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation(
		ForWhat, TemplateParameters1.CodeType, UUID);

	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

&AtServer
Function ParametersForSamplePrinting()
	
	Template = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);
	TemplateParameters1 = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Template, Purpose);
	CodeType = TemplateParameters1.CodeType;
	PrintParameters = PrintPriceTagsAndLabelsLocalization.GetParametersForPrintingSample(
		ThisObject, Purpose, CodeType, ThisObject);
	Return AddParametersForPrintingSample(PrintParameters, TemplateParameters1);
	
EndFunction

#EndRegion

#EndRegion
