#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

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
	If Not ValueIsFilled(Object.Ref) Then

		CopyingValue = Undefined;
		Items.Height.ReadOnly = False;
		Items.Width.ReadOnly = False;
		Items.CellSize.ReadOnly = False;
		Parameters.Property("CopyingValue", CopyingValue);

		If Not ValueIsFilled(CopyingValue) Then

			TemplateName = Parameters.TemplateName;
			If ValueIsFilled(Parameters.Purpose) Then
				Object.Purpose = Parameters.Purpose;
			EndIf;
			If ValueIsFilled(Parameters.Height) Then
				Object.Height = Parameters.Height;
			EndIf;
			If Parameters.Width > 0 Then
				Object.Width = Parameters.Width;
			EndIf;
			If ValueIsFilled(Parameters.Description) Then
				Object.Description = Parameters.Description;
			EndIf;
			DetailLevel = ?(DetailLevel = 0, 1, DetailLevel);
			If Not ValueIsFilled(TemplateName) Then
				SetSize(Object.Width, Object.Height, Object.CellSize);
			EndIf;

			FillInAvailableFields();
			CustomizeTemplate();

		Else

			FillInAvailableFields();
			UploadTemplate();

		EndIf;
	
	EndIf;
	
	ActualSize = CurPageSize(ThisObject);
	PageSize = ActualSize;

	RefreshTitle(ThisObject);
	PurposeOnChangeServer(False);

	Codes = GetCodes();
	For Each TSRow In Codes Do
		NewCodeType = BarcodeTypes.Add();
		NewCodeType.CodeType = TSRow.CodeType;
		NewCodeType.BarcodeType = TSRow.BarcodeType;
		ListCodeType.Add(TSRow.BarcodeType, TSRow.Description);
	EndDo;
	
	ListMonochromeFont.Add(True, NStr("vi = 'Đơn sắc';
										|ru = 'Монохромный';
										|en = 'Monochrome'; fa = 'تک‌رنگ';
										|it = 'Monocromatico';
										|pl = 'Monochrome';
										|tr = 'Tek renkli'"));
	ListMonochromeFont.Add(False, NStr("vi = 'Dải màu ghi';
										|ru = 'Градации серого';
										|en = 'Gray gradations'; fa = 'Gray gradations';
										|it = 'Gradazioni di grigio';
										|pl = 'Skala szarości';
										|tr = 'Gri tonlaması'"));

	ListSweepAngle.Add(0, NStr("vi = '0°';
								|ru = '0°';
								|en = '0°'; fa = '0°';
								|it = '0°';
								|pl = '0°';
								|tr = '0°'"));
	ListSweepAngle.Add(90, NStr("vi = '90°';
								|ru = '90°';
								|en = '90°'; fa = '90°';
								|it = '90°';
								|pl = '90°';
								|tr = '90°'"));
	ListSweepAngle.Add(180, NStr("vi = '180°';
								|ru = '180°';
								|en = '180°'; fa = '180°';
								|it = '180°';
								|pl = '180°';
								|tr = '180°'"));
	ListSweepAngle.Add(270, NStr("vi = '270°';
								|ru = '270°';
								|en = '270°'; fa = '270°';
								|it = '270°';
								|pl = '270°';
								|tr = '270°'"));

	ListGS1DatabarNumberOfRows.Add(100, NStr("vi = 'Ưu tiên mô-đun và số dòng (tối đa)';
											|ru = 'Приоритет модуля и числа строк (max)';
											|en = 'Priority of module and number of lines (max)'; fa = 'Priority of module and number of lines (max)';
											|it = 'Priorità del modulo e del numero di righe (max)';
											|pl = 'Priorytet modułu i liczby wierszy (max)';
											|tr = 'Öncelik modülü ve satır sayı (maksimum)'"));
	ListGS1DatabarNumberOfRows.Add(101, NStr("vi = 'Ưu tiên mô-đun và số dòng (tối thiểu)';
											|ru = 'Приоритет модуля и числа строк (min)';
											|en = 'Priority of module and number of lines (min)'; fa = 'Priority of module and number of lines (min)';
											|it = 'Priorità del modulo e del numero di righe (min)';
											|pl = 'Priorytet modułu i liczby wierszy (min)';
											|tr = 'Öncelik modülü ve satır sayı (minimum)'"));
	ListGS1DatabarNumberOfRows.Add(102, NStr("vi = 'Ưu tiên mối quan hệ giữa các bên';
											|ru = 'Приоритет соотношения сторон';
											|en = 'Side ratio priority'; fa = 'Side ratio priority';
											|it = 'Priorità di correlazione delle parti';
											|pl = 'Priorytet proporcji';
											|tr = 'Uzunluk genişlik oran önceliği'"));
	ListGS1DatabarNumberOfRows.Add(1, NStr("vi = '1 dòng';
											|ru = '1 строка';
											|en = '1 line'; fa = '1 line';
											|it = '1 riga';
											|pl = '1 wiersz';
											|tr = '1 satır'"));
	ListGS1DatabarNumberOfRows.Add(2, NStr("vi = '2 dòng';
											|ru = '2 строки';
											|en = '2 lines'; fa = '2 lines';
											|it = '2 righe';
											|pl = '2 wiersze';
											|tr = '2 satırlar'"));
	ListGS1DatabarNumberOfRows.Add(3, NStr("vi = '3 dòng';
											|ru = '3 строки';
											|en = '3 lines'; fa = '3 lines';
											|it = '3 righe';
											|pl = '3 wiersze';
											|tr = '3 satırlar'"));
	ListGS1DatabarNumberOfRows.Add(4, NStr("vi = '4 dòng';
											|ru = '4 строки';
											|en = '4 lines'; fa = '4 lines';
											|it = '4 righe';
											|pl = '4 wiersze';
											|tr = '4 satırlar'"));
	ListGS1DatabarNumberOfRows.Add(5, NStr("vi = '5 dòng';
											|ru = '5 строк';
											|en = '5 lines'; fa = '5 lines';
											|it = '5 righe';
											|pl = '5 wierszy';
											|tr = '5 satır'"));

	TheListOptionZooming.Add("RealSize", NStr("vi = 'Kích thước thực tế';
												|ru = 'Реальный размер';
												|en = 'Actual size'; fa = 'اندازه واقعی';
												|it = 'Dimensione reale';
												|pl = 'Rozmiar faktyczny';
												|tr = 'Gerçek boyut'"));
	TheListOptionZooming.Add("ScaleMaintainProportions", NStr("vi = 'Chia tỷ lệ (giữ tỷ lệ)';
																|ru = 'Масштабировать (сохранять пропорции)';
																|en = 'Scale (keep aspect ratio)'; fa = 'Scale (keep aspect ratio)';
																|it = 'Scalare (mantenendo le proporzioni)';
																|pl = 'Skaluj (zachowaj proporcje)';
																|tr = 'Ölçeklemek (oranları sakla)'"));
	TheListOptionZooming.Add("ScaleNotKeepProportions", NStr("vi = 'Chia tỷ lệ (không giữ tỷ lệ)';
															|ru = 'Масштабировать (не сохранять пропорции)';
															|en = 'Scale (do not keep aspect ratio)'; fa = 'Scale (do not keep aspect ratio)';
															|it = 'Scalare (senza mantenere le proporzioni)';
															|pl = 'Skaluj (nie zachowuj proporcji)';
															|tr = 'Ölçeklemek (oranları saklamamak)'"));

	ListVerticalAlignment.Add(1, NStr("vi = 'Cạnh trên';
										|ru = 'По верхнему краю';
										|en = 'Top'; fa = 'بالا';
										|it = 'Lungo il bordo superiore';
										|pl = 'Względem górnej granicy';
										|tr = 'Üst kenar hizasıyla'"));
	ListVerticalAlignment.Add(2, NStr("vi = 'Ở giữa';
										|ru = 'По центру';
										|en = 'Center'; fa = 'وسط';
										|it = 'Nel centro';
										|pl = 'Względem środka';
										|tr = 'Merkez hizasında'"));
	ListVerticalAlignment.Add(3, NStr("vi = 'Cạnh dưới';
										|ru = 'По нижнему краю';
										|en = 'Bottom'; fa = 'پایین';
										|it = 'Lungo il bordo inferiore';
										|pl = 'Względem dolnej granicy';
										|tr = 'Alt kenarlık hizasıyla'"));

	DetailLevelList.Add(1, NStr("vi = 'Tiêu chuẩn';
								|ru = 'Стандартный';
								|en = 'Standard'; fa = 'استاندارد';
								|it = 'Standard';
								|pl = 'Standard';
								|tr = 'Standart'"));
	DetailLevelList.Add(2, NStr("vi = 'Nâng cao';
								|ru = 'Повышенный';
								|en = 'Increased'; fa = 'Increased';
								|it = 'Elevato';
								|pl = 'Increased';
								|tr = 'Yükseltilmiş'"));

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	Items.Purpose.ChoiceList.SortByPresentation();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("UpdatePlacement", 1, False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_LabelAndPriceTagTemplates", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	FillInAvailableFields();

	UploadTemplate();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CalculateMaximumNumberPerPage();

	If Not CheckFit() Then
		Cancel = True;
	Else
		StructureOfTemplateTemplate = PrepareStructureOfTemplateTemplate();
		CurrentObject.Template = New ValueStorage(StructureOfTemplateTemplate);
		CurrentObject.BarcodeType = StructureOfTemplateTemplate.BarcodeType;
	EndIf;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	RefreshTitle(ThisForm);
EndProcedure

&AtClient
Procedure DataCompositionAvailableFieldsBeforeExpand(Item, String, Cancel)
	
	CurrentData = DataCompositionAvailableFields.FindByID(String);
	If CurrentData.ExpandToAttributes
		And Not CurrentData.SubordinateRowsExpanded Then
		// If there are subordinate details and the details of the next level have not been received for them.
		ExpandSubordinateRowsOfOperandTree(String);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExpandSubordinateRowsOfOperandTree(IDOfCurRowOfOperandTree)
	
	ProcessingOfFormulas.ExpandOperandStringOfFormTree(DataCompositionAvailableFields,
		IDOfCurRowOfOperandTree);
	
EndProcedure

&AtClient
Procedure AvailableFieldsSelection(Item, RowSelected, Field,
		StandardProcessing)

	If ThisForm.ReadOnly Then
		Return;
	EndIf;
	
	CurrentData = DataCompositionAvailableFields.FindByID(RowSelected);
	If Not CurrentData.OperandSelectionAllowed Then
		Return;
	EndIf;

	Modified = True;
	SelectingAvailableField(RowSelected);

EndProcedure

&AtClient
Procedure TextVisibleOnChange(Item)
	Items.FontSize.Enabled = TextVisible;
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)

	If Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins")
			Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel")
			Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel") Then
		BarcodeType = PredefinedValue("Enum.BarcodeTypes.Code128");
	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ExciseStampLabel") Then
		BarcodeType = PredefinedValue("Enum.BarcodeTypes.PDF417");
	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages") Then
		BarcodeType = PredefinedValue("Enum.BarcodeTypes.GS1_DataBarExpandedStacked");
	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape")
			Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper")
	 		Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape")
	 		Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper")
	 		Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape")
	 		Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper") Then
		BarcodeType = PredefinedValue("Enum.BarcodeTypes.QR");
	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelShoesClothesTobacco") Then
		BarcodeType = PredefinedValue("Enum.BarcodeTypes.DataMatrix");
	Else
		BarcodeType = PredefinedValue("Enum.BarcodeTypes.EAN13");
	EndIf;

	For Each StringBarcodeTypes In BarcodeTypes Do
		If StringBarcodeTypes.BarcodeType = BarcodeType Then
			CodeType = StringBarcodeTypes.CodeType;
		EndIf;
	EndDo;

	PurposeOnChangeServer();

	FillInPropertiesTable();

EndProcedure

&AtClient
Procedure SpreadsheetDocumentFieldOnChangeAreaContent(Item,
		Area)

	Modified = True;

EndProcedure

&AtClient
Procedure WidthOnChange(Item)
	SetSize(Object.Width, Object.Height, Object.CellSize);
EndProcedure

&AtClient
Procedure HeightOnChange(Item)
	SetSize(Object.Width, Object.Height, Object.CellSize);
EndProcedure

&AtClient
Procedure CellSizeOnChange(Item)
	SetSize(Object.Width, Object.Height, Object.CellSize);
EndProcedure

&AtClient
Procedure PurposeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ForWhatOnChange(Item)

	If Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages") Then

		For Each Area In SpreadsheetDocumentField.Areas Do

			Name = Area.Name;
			If StrStartsWith(Upper(Name), Upper("Barcode")) Then
				IndexOf = ReplaceBarcodeDrawing(Name);
				SpreadsheetDocumentField.Drawings[IndexOf].Name = Name;
			EndIf;

		EndDo;

	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCellProperties

&AtClient
Procedure CellPropertiesValueOnChange(Item)

	SelectedArea1 = SpreadsheetDocumentField.CurrentArea;
	CurrentData = Items.CellProperties.CurrentData;

	If TypeOf(SelectedArea1) = Type("SpreadsheetDocumentRange") Then

		SelectedArea1[CurrentData.PropertyName] = CurrentData.Value;
		SetCurrentItem = Undefined;

	ElsIf TypeOf(SelectedArea1) = Type("SpreadsheetDocumentDrawing") Then

		If CurrentData.PropertyName = "CodeType" Then

			For Each KeyAndValue In ListCodeType Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					BarcodeType = KeyAndValue.Value;
					For Each StringBarcodeTypes In BarcodeTypes Do
						If BarcodeType = StringBarcodeTypes.BarcodeType Then
							CodeType = StringBarcodeTypes.CodeType;
						EndIf;
					EndDo;
				EndIf;
			EndDo;

		ElsIf CurrentData.PropertyName = "FontSize" Then

			FontSize = CurrentData.Value;

		ElsIf CurrentData.PropertyName = "DetailLevel" Then

			For Each KeyAndValue In DetailLevelList Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					DetailLevel = KeyAndValue.Value;
				EndIf;
			EndDo;

		ElsIf CurrentData.PropertyName = "TextVisible" Then

			TextVisible = CurrentData.Value;

		ElsIf CurrentData.PropertyName = "GS1DatabarRowCount" Then

			For Each KeyAndValue In ListGS1DatabarNumberOfRows Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					GS1DatabarRowCount = KeyAndValue.Value;
				EndIf;
			EndDo;

		ElsIf CurrentData.PropertyName = "MonochromeFont" Then

			For Each KeyAndValue In ListMonochromeFont Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					MonochromeFont = KeyAndValue.Value;
				EndIf;
			EndDo;

		ElsIf CurrentData.PropertyName = "CanvasRotation" Then

			For Each KeyAndValue In ListSweepAngle Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					CanvasRotation = KeyAndValue.Value;
				EndIf;
			EndDo;

		ElsIf CurrentData.PropertyName = "VerticalAlignment" Then

			For Each KeyAndValue In ListVerticalAlignment Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					VerticalAlignment = KeyAndValue.Value;
				EndIf;
			EndDo;

		ElsIf CurrentData.PropertyName = "ZoomOption" Then

			For Each KeyAndValue In TheListOptionZooming Do
				Presentation = KeyAndValue.Presentation;
				If CurrentData.Value = Presentation Then
					If KeyAndValue.Value = "RealSize" Then
						Zoomable = False;
						MaintainAspectRatio = True;
					ElsIf KeyAndValue.Value = "ScaleMaintainProportions" Then
						Zoomable = True;
						MaintainAspectRatio = True;
					ElsIf KeyAndValue.Value = "ScaleNotKeepProportions" Then
						Zoomable = True;
						MaintainAspectRatio = False;
					EndIf;
				EndIf;
			EndDo;

		Else

			SelectedArea1[CurrentData.PropertyName] = CurrentData.Value;

		EndIf;

		Name = SelectedArea1.Name;
		If StrStartsWith(Upper(Name), Upper("Barcode")) Then
			IndexOf = ReplaceBarcodeDrawing(Name);
			SpreadsheetDocumentField.Drawings[IndexOf].Name = Name;
		EndIf;

		AttachIdleHandler("FillInPropertiesTable", 0.1, True);

	EndIf;

EndProcedure

&AtClient
Procedure CellPropertiesValueStartChoice(Item, ChoiceData,
		StandardProcessing)

	SelectedArea1 = SpreadsheetDocumentField.CurrentArea;
	CurrentData = Items.CellProperties.CurrentData;

	If TypeOf(SelectedArea1) = Type("SpreadsheetDocumentDrawing") Then

		If StrFind(CurrentData.PropertyName, "Line") > 0 Then

			StandardProcessing = False;
			SetUpLine(SelectedArea1, CurrentData);

		EndIf;
	ElsIf TypeOf(SelectedArea1) = Type("SpreadsheetDocumentRange") Then

		If StrFind(CurrentData.PropertyName, "Boundary") > 0 Then

			StandardProcessing = False;
			SetUpLine(SelectedArea1, CurrentData);

		EndIf;

		If StrFind(CurrentData.PropertyName, "Format") > 0 Then
			StandardProcessing = False;
		EndIf;

		If StrFind(CurrentData.PropertyName, "FillType") > 0 Then

			StandardProcessing = False;
			ValueList = New ValueList;
			ValueList.Add(SpreadsheetDocumentAreaFillType.Parameter);
			ValueList.Add(SpreadsheetDocumentAreaFillType.Text);
			ValueList.Add(SpreadsheetDocumentAreaFillType.Template);

			ShowChooseFromList(New CallbackDescription("CellPropertiesValueStartChoiceCompletion", ThisObject, New Structure("SelectedArea1, CurrentData", SelectedArea1, CurrentData)), ValueList, Items.CellPropertiesValue);

		EndIf;

		If StrFind(CurrentData.PropertyName, "Format") > 0 Then

			Designer = New FormatStringWizard;
			Designer.Show(New CallbackDescription("CellPropertiesValueStartSelectionConstructorEnd", ThisObject, New Structure("SelectedArea1, Designer, CurrentData", SelectedArea1, Designer, CurrentData)));

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure CellPropertiesValueStartSelectionConstructorEnd(Text,
		AdditionalParameters) Export

	SelectedArea1 = AdditionalParameters.SelectedArea1;
	Designer = AdditionalParameters.Designer;
	CurrentData = AdditionalParameters.CurrentData;

	If Text <> Undefined Then
		CurrentData.Value = Designer.Text;
		SelectedArea1.Format = Designer.Text;
	EndIf;

EndProcedure

&AtClient
Procedure CellPropertiesValueStartChoiceCompletion(SelectedElement,
		AdditionalParameters) Export

	SelectedArea1 = AdditionalParameters.SelectedArea1;
	CurrentData = AdditionalParameters.CurrentData;

	ListItem = SelectedElement;
	If ListItem <> Undefined Then
		CurrentData.Value = String(ListItem.Value);
		SelectedArea1.FillType = ListItem.Value;
	EndIf;
	FillInPropertiesTable();

EndProcedure

&AtClient
Procedure CellPropertiesOnActivateRow(Item)

	CurrentData = Items.CellProperties.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	Items.CellPropertiesValue.ChoiceList.Clear();

	ThisIsLineWithCodeType = StrFind(CurrentData.PropertyName, "CodeType") > 0;
	ThisIsStringWithFontType = StrFind(CurrentData.PropertyName, "MonochromeFont") > 0;
	ThisIsLineBoundary = StrFind(CurrentData.PropertyName, "Boundary") > 0;
	ThisIsStringLine = StrFind(CurrentData.PropertyName, "Line") > 0;
	ThisIsAngleOfRotation = StrFind(CurrentData.PropertyName, "CanvasRotation") > 0;
	ThisIsGS1DatabarNumberOfRows = StrFind(CurrentData.PropertyName, "GS1DatabarRowCount") > 0;
	ThisIsScalingOption = StrFind(CurrentData.PropertyName, "ZoomOption") > 0;
	ThisIsVerticalAlignment = StrFind(CurrentData.PropertyName, "VerticalAlignment") > 0;
	ThisIsClarityLevelOption = StrFind(CurrentData.PropertyName, "DetailLevel") > 0;

	If ThisIsLineWithCodeType Then

		For Each ListItem In ListCodeType Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	ElsIf ThisIsStringWithFontType Then

		For Each ListItem In ListMonochromeFont Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	ElsIf ThisIsAngleOfRotation Then

		For Each ListItem In ListSweepAngle Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	ElsIf ThisIsGS1DatabarNumberOfRows Then

		For Each ListItem In ListGS1DatabarNumberOfRows Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	ElsIf ThisIsScalingOption Then

		For Each ListItem In TheListOptionZooming Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	ElsIf ThisIsVerticalAlignment Then

		For Each ListItem In ListVerticalAlignment Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	ElsIf ThisIsClarityLevelOption Then

		For Each ListItem In DetailLevelList Do
			Items.CellPropertiesValue.ChoiceList.Add(ListItem.Presentation);
		EndDo;

		Items.CellPropertiesValue.ListChoiceMode = True;
		Items.CellPropertiesValue.ChoiceListButton = False;

	Else

		Items.CellPropertiesValue.ListChoiceMode = False;
		Items.CellPropertiesValue.ChoiceListButton = False;

	EndIf;

	Items.CellPropertiesValue.TextEdit = Not (ThisIsLineBoundary
		Or ThisIsLineWithCodeType Or ThisIsStringWithFontType
		Or ThisIsGS1DatabarNumberOfRows Or ThisIsAngleOfRotation
		Or ThisIsScalingOption Or ThisIsVerticalAlignment
		Or ThisIsStringLine);

EndProcedure

&AtClient
Procedure CellPropertiesBeforeAddRow(Item, Cancel, Copy,
		Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Union(Command)

	If SpreadsheetDocumentField.SelectedAreas.Count() = 1
			And TypeOf(SpreadsheetDocumentField.SelectedAreas[0]) = Type("SpreadsheetDocumentRange") Then

		CurrentArea = SpreadsheetDocumentField.CurrentArea;
		MergeArea(CurrentArea.Name);

	Else

		ClearMessages();
		MessageText = NStr("vi = 'Vùng sai';
							|ru = 'Некорректная область';
							|en = 'Incorrect area'; fa = 'Incorrect area';
							|it = 'Area non valida';
							|pl = 'Nieprawidłowy obszar';
							|tr = 'Yanlış alan'");
		Field = "SpreadsheetDocumentField";
		CommonClient.MessageToUser(MessageText,, Field);
	EndIf;

EndProcedure

&AtClient
Procedure UndoMerge(Command)

	If SpreadsheetDocumentField.SelectedAreas.Count() = 1
			And TypeOf(SpreadsheetDocumentField.SelectedAreas[0]) = Type("SpreadsheetDocumentRange") Then

		CurrentArea = SpreadsheetDocumentField.CurrentArea;
		DisconnectArea(CurrentArea.Name);

	Else

		ClearMessages();
		MessageText = NStr("vi = 'Vùng sai';
							|ru = 'Некорректная область';
							|en = 'Incorrect area'; fa = 'Incorrect area';
							|it = 'Area non valida';
							|pl = 'Nieprawidłowy obszar';
							|tr = 'Yanlış alan'");
		Field = "SpreadsheetDocumentField";
		CommonClient.MessageToUser(MessageText,, Field);

	EndIf;

EndProcedure

&AtClient
Procedure Select(Command)

	CurrentRow = Items.DataCompositionAvailableFields.CurrentRow;
	If CurrentRow <> Undefined Then
		SelectingAvailableField(CurrentRow);
	EndIf;

EndProcedure

&AtClient
Procedure SetPrintArea(Command)

	If (SpreadsheetDocumentField.SelectedAreas[0].Left <> 0
			And SpreadsheetDocumentField.SelectedAreas[0].Top <> 0)
			And SpreadsheetDocumentField.SelectedAreas.Count() = 1
			And TypeOf(SpreadsheetDocumentField.SelectedAreas[0]) = Type("SpreadsheetDocumentRange") Then

		SetPrintAreaOnServer(SpreadsheetDocumentField.SelectedAreas[0].Name);

	Else

		ClearMessages();
		MessageText = NStr("vi = 'Sai vùng in';
							|ru = 'Некорректная область печати';
							|en = 'Print area is incorrect'; fa = 'Print area is incorrect';
							|it = 'Area di stampa non valida';
							|pl = 'Nieprawidłowy obszar druku';
							|tr = 'Yazdırmak için dikdörtgen bir alan seçin.'");
		Field = "SpreadsheetDocumentField";
		CommonClient.MessageToUser(MessageText,, Field);

	EndIf;

EndProcedure

&AtClient
Procedure PrintSample(Command)

	ClearMessages();

	If Not ValueIsFilled(Object.ForWhat) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Mục đích""';
							|ru = 'Не заполнено поле ""Для чего""';
							|en = '""For what"" is required'; fa = '""For what"" is required';
							|it = 'Il campo ""Per cosa"" non è compilato';
							|pl = 'Nie wypełniono pola ""W jakim celu""';
							|tr = '""Ne için"" alanı doldurulmadı'");
		CommonClient.MessageToUser(MessageText,, "Object.ForWhat");
		Return;
	EndIf;

	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.Products.EmptyRef"));

	If Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag") Then

		PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "PriceTagProducts", CommandParameter, Undefined, GetParametersForPrintingSampleProductPriceTag());

	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel") Then

		PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "LabelProducts_", CommandParameter, Undefined, GetParametersForPrintingSampleProductLabel());

	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins") Then

		PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "LabelStorageCells", CommandParameter, Undefined, GetParametersForPrintingSampleLabelOfWarehouseCell());

	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery") Then

		PrintParameters = GetParametersForPrintingSampleShippingLabels();
		
		If PrintParameters.ThereAreLabelsToPrint Then
			PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "ShippingLabel", CommandParameter, Undefined, PrintParameters);
		ElsIf PrintParameters.DeliveryToOurWarehouse Then
			CommonClientServer.MessageToUser(NStr("vi = 'Chỉ có thể in nhãn giá để vận chuyển từ kho của chúng ta.';
													|ru = 'Печать этикетки доступна только для доставки с нашего склада.';
													|en = 'You can print a label only for delivery from our warehouse.'; fa = 'You can print a label only for delivery from our warehouse.';
													|it = 'La stampa delle etichette è disponibile solo per la consegna dal nostro magazzino.';
													|pl = 'Wydruk etykiety jest dostępna tylko dla dostawy z naszego magazynu.';
													|tr = 'Etiket yazdırması sadece ambardan teslimat için mevcuttur.'"));	
		Else
			CommonClientServer.MessageToUser(NStr("vi = 'Mẫu in không sử dụng được.';
													|ru = 'Печатная форма недоступна.';
													|en = 'Print form not available.'; fa = 'فرم چاپی در دسترس نیست.';
													|it = 'Modulo di stampa non disponibile.';
													|pl = 'Formularz wydruku jest niedostępny.';
													|tr = 'Yazdırma formu mevcut değil.'"));
			If PrintParameters.ArrayOfLinksWithErrors.Count() > 0 Then
				MessageText = NStr("vi = 'Chưa tùy chỉnh khuôn mẫu nhãn tem vận chuyển. Hãy liên hệ với người quản trị.';
									|ru = 'Не настроен общий шаблон этикетки доставки. Обратитесь к администратору.';
									|en = 'Common delivery label template is not configured. Please contact the administrator.'; fa = 'Common delivery label template is not configured. Please contact the administrator.';
									|it = 'Modello standard di etichetta di consegna non impostato. Rivolgersi all''amministratore.';
									|pl = 'Nie został skonfigurowany szablon etykiety dostawy. Skontaktuj się z administratorem.';
									|tr = 'Genel teslimat etiket numunesi ayarlanmadı. Yöneticiyle iletişime geç.'");
				CommonClientServer.MessageToUser(MessageText);
			EndIf;
		EndIf;

	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel") Then

		PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "ItemsBatchLabel", CommandParameter, Undefined, GetParametersForPrintingSampleLabelsOfProductSeries());

	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel") Then

		PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "LabelPackingSheets", CommandParameter, Undefined, GetParametersForPrintingSampleLabelsPackingSheets());

			
	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape")
		Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper") Then

		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels", 
			"LabelOfObjectsOfOperation", 
			CommandParameter, 
			Undefined, 
			GetParametersForPrintingSampleLabelOfObjectOfOperation());
	ElsIf Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape")
		Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper") Then

		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels", 
			"LabelOfUnitOfObjectOfOperation", 
			CommandParameter, 
			Undefined, 
			GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation());
	Else
		ParametersForSamplePrinting = ParametersForSamplePrinting();
		PrintPriceTagsAndLabelsLocalizationClient.PrintSample(ParametersForSamplePrinting, CommandParameter, Object);
	EndIf;

EndProcedure

&AtClient
Procedure VerticalAlignmentTop(Command)

	If TypeOf(SpreadsheetDocumentField.CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Chỉ có thể thực hiện giao dịch đối với ô hàng trong chứng từ dạng bảng';
							|ru = 'Операция может быть выполнена только над ячейкой табличного документа';
							|en = 'This operation can only be performed with a spreadsheet document cell.'; fa = 'This operation can only be performed with a spreadsheet document cell.';
							|it = 'L''operazione può essere eseguita solo sulla cella del documento tabellare';
							|pl = 'Operacja może być zastosowana tylko do komórki dokumentu tabelarycznego';
							|tr = 'İşlem yalnızca tablo belgesi hücresinde gerçekleştirilebilir'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;

	SpreadsheetDocumentField.CurrentArea.VerticalAlign = VerticalAlign.Top;

EndProcedure

&AtClient
Procedure VerticalAlignmentCenter(Command)

	If TypeOf(SpreadsheetDocumentField.CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Chỉ có thể thực hiện giao dịch đối với ô hàng trong chứng từ dạng bảng';
							|ru = 'Операция может быть выполнена только над ячейкой табличного документа';
							|en = 'This operation can only be performed with a spreadsheet document cell.'; fa = 'This operation can only be performed with a spreadsheet document cell.';
							|it = 'L''operazione può essere eseguita solo sulla cella del documento tabellare';
							|pl = 'Operacja może być zastosowana tylko do komórki dokumentu tabelarycznego';
							|tr = 'İşlem yalnızca tablo belgesi hücresinde gerçekleştirilebilir'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;

	SpreadsheetDocumentField.CurrentArea.VerticalAlign = VerticalAlign.Center;

EndProcedure

&AtClient
Procedure VerticalAlignmentBottom(Command)

	If TypeOf(SpreadsheetDocumentField.CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Chỉ có thể thực hiện giao dịch đối với ô hàng trong chứng từ dạng bảng';
							|ru = 'Операция может быть выполнена только над ячейкой табличного документа';
							|en = 'This operation can only be performed with a spreadsheet document cell.'; fa = 'This operation can only be performed with a spreadsheet document cell.';
							|it = 'L''operazione può essere eseguita solo sulla cella del documento tabellare';
							|pl = 'Operacja może być zastosowana tylko do komórki dokumentu tabelarycznego';
							|tr = 'İşlem yalnızca tablo belgesi hücresinde gerçekleştirilebilir'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;

	SpreadsheetDocumentField.CurrentArea.VerticalAlign = VerticalAlign.Bottom;

EndProcedure

&AtClient
Procedure HorizontalAlignmentLeft(Command)

	If TypeOf(SpreadsheetDocumentField.CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Chỉ có thể thực hiện giao dịch đối với ô hàng trong chứng từ dạng bảng';
							|ru = 'Операция может быть выполнена только над ячейкой табличного документа';
							|en = 'This operation can only be performed with a spreadsheet document cell.'; fa = 'This operation can only be performed with a spreadsheet document cell.';
							|it = 'L''operazione può essere eseguita solo sulla cella del documento tabellare';
							|pl = 'Operacja może być zastosowana tylko do komórki dokumentu tabelarycznego';
							|tr = 'İşlem yalnızca tablo belgesi hücresinde gerçekleştirilebilir'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;

	SpreadsheetDocumentField.CurrentArea.HorizontalAlign = HorizontalAlign.Left;

EndProcedure

&AtClient
Procedure HorizontalAlignmentCenter(Command)

	If TypeOf(SpreadsheetDocumentField.CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Chỉ có thể thực hiện giao dịch đối với ô hàng trong chứng từ dạng bảng';
							|ru = 'Операция может быть выполнена только над ячейкой табличного документа';
							|en = 'This operation can only be performed with a spreadsheet document cell.'; fa = 'This operation can only be performed with a spreadsheet document cell.';
							|it = 'L''operazione può essere eseguita solo sulla cella del documento tabellare';
							|pl = 'Operacja może być zastosowana tylko do komórki dokumentu tabelarycznego';
							|tr = 'İşlem yalnızca tablo belgesi hücresinde gerçekleştirilebilir'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;

	SpreadsheetDocumentField.CurrentArea.HorizontalAlign = HorizontalAlign.Center;

EndProcedure

&AtClient
Procedure HorizontalAlignmentRight(Command)

	If TypeOf(SpreadsheetDocumentField.CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Chỉ có thể thực hiện giao dịch đối với ô hàng trong chứng từ dạng bảng';
							|ru = 'Операция может быть выполнена только над ячейкой табличного документа';
							|en = 'This operation can only be performed with a spreadsheet document cell.'; fa = 'This operation can only be performed with a spreadsheet document cell.';
							|it = 'L''operazione può essere eseguita solo sulla cella del documento tabellare';
							|pl = 'Operacja może być zastosowana tylko do komórki dokumentu tabelarycznego';
							|tr = 'İşlem yalnızca tablo belgesi hücresinde gerçekleştirilebilir'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;

	SpreadsheetDocumentField.CurrentArea.HorizontalAlign = HorizontalAlign.Right;

EndProcedure

&AtClient
Procedure Assign(Command)

	ClearMessages();

	If Not ValueIsFilled(Object.ForWhat) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Mục đích""';
							|ru = 'Поле ""Для чего"" не заполнено';
							|en = '""For what"" is required'; fa = '""For what"" is required';
							|it = 'Il campo ""Per cosa"" non è compilato';
							|pl = 'Nie wypełniono pola ""W jakim celu""';
							|tr = '""Ne için"" alanı doldurulmadı'");
		CommonClient.MessageToUser(MessageText,,"Object.ForWhat");
		Return;
	EndIf;

	If Not ValueIsFilled(Object.Ref) Then

		QueryText = NStr("vi = 'Trước khi thực hiện giao dịch, cần ghi lại phần tử. Ghi lại phần tử và tiếp tục?';
						|ru = 'Перед выполнением операции элемент необходимо записать. Выполнить запись элемента и продолжить?';
						|en = 'You need to overwrite the item before the operation is executed. Overwrite and continue?'; fa = 'You need to overwrite the item before the operation is executed. Overwrite and continue?';
						|it = 'Prima di eseguire l''operazione, l''elemento deve essere registrato. Registrare l''elemento e continuare?';
						|pl = 'Przed wykonaniem operacji element musi zostać zapisany. Zapisać element i kontynuować?';
						|tr = 'İşlemi gerçekleştirmeden önce öğe kaydedilmelidir. Öğeyi kaydedip devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("AssignCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;

	EndIf;

	AssignFragment();

EndProcedure

&AtClient
Procedure AssignCompletion(QuestionResult,
		AdditionalParameters) Export

	ResponseCode = QuestionResult;
	If ResponseCode <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	If CheckFilling() Then
		If Not Write() Then
			Return;
		EndIf;
	Else
		Return;
	EndIf;

	AssignFragment();

EndProcedure

&AtClient
Procedure AssignFragment()

	If Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel") Then
		AssignPackingListLabelTemplate(Object.Ref);
	Else
		ParametersOfFormToOpen = New Structure("Purpose, ForWhat, Template", Object.Purpose, Object.ForWhat, Object.Ref);
		OpenForm("Catalog.LabelAndPriceTagTemplates.Form.TemplateAssignmentForm", ParametersOfFormToOpen);
	EndIf;

EndProcedure

&AtClient
Procedure SelectTemplate(Command)

	OpenForm("Catalog.LabelAndPriceTagTemplates.Form.TemplateChoiceForm", New Structure("Purpose", Object.Purpose), ThisObject, , , , New CallbackDescription("SelectTemplateCompletion", ThisObject));

EndProcedure

&AtClient
Procedure SelectTemplateCompletion(TemplateName, AdditionalParameters) Export

	If ValueIsFilled(TemplateName) Then

		QueryText = NStr("vi = 'Khuôn mẫu đã soạn sẽ được thay thế bằng khuôn mẫu mặc định, tiếp tục?';
						|ru = 'Редактируемый шаблон будет заменен на шаблон по умолчанию, продолжить?';
						|en = 'The template being edited will be replaced with the default template, continue?'; fa = 'The template being edited will be replaced with the default template, continue?';
						|it = 'Il modello che si sta modificando verrà sostituito con quello di default, continuare?';
						|pl = 'Edytowany szablon zostanie zamieniony na szablon domyślny, kontynuować?';
						|tr = 'Varsayılan numuneye geri dönmek istiyor musunuz?'");
		AddlParameters = New Structure("TemplateName", TemplateName);
		CallbackDescription = New CallbackDescription("SelectQuestionCompletionTemplate", ThisObject, AddlParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

	EndIf;

EndProcedure

&AtClient
Procedure SelectQuestionCompletionTemplate(QuestionResult,
		AdditionalParameters) Export

	TemplateName = AdditionalParameters.TemplateName;

	Result = QuestionResult;
	If Result = DialogReturnCode.Yes Then
		SetDefaultTemplate(TemplateName);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)

	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellProperties.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellProperties.PropertyName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = 'Ký tự chia tách';
								|ru = 'Разделитель';
								|en = 'Separator'; fa = 'جداکننده';
								|it = 'Separatore';
								|pl = 'Separator';
								|tr = 'Ayırıcı'");

	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportHeaderBackColor);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPropertiesValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellProperties.PropertyName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = 'Ký tự chia tách';
								|ru = 'Разделитель';
								|en = 'Separator'; fa = 'جداکننده';
								|it = 'Separatore';
								|pl = 'Separator';
								|tr = 'Ayırıcı'");

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPropertiesValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellProperties.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPropertiesValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellProperties.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không có sẵn>';
													|ru = '<Не доступно>';
													|en = '<Unavailable>'; fa = '<Unavailable>';
													|it = '<Non disponibile>';
													|pl = '<Niedostępne>';
													|tr = '<Erişilebilir değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Function ParametersForSamplePrinting()
	
	PrintParameters = PrintPriceTagsAndLabelsLocalization.GetParametersForPrintingSample(
		ThisObject, Object.Purpose, CodeType, Object);
	Return AddParametersForPrintingSample(PrintParameters);
	
EndFunction

#Region Other

&AtServerNoContext
Function GetCodes()

	Return Catalogs.LabelAndPriceTagTemplates.GetBarcodeSamples();

EndFunction

&AtClientAtServerNoContext
Function NameOfBarcodeParameter()

	Return "Barcode";

EndFunction

&AtClient
Function ParameterNameExciseStampCode()

	Return "ExciseStampCode";

EndFunction

&AtClientAtServerNoContext
Function NameOfPriceCurrencyParameter()

	Return "PriceKind.PriceCurrency";

EndFunction

&AtClientAtServerNoContext
Function PageSize(SpreadsheetDocumentField)

	PageHeight = SpreadsheetDocumentField.PageHeight;
	PageWidth = SpreadsheetDocumentField.PageWidth;

	Description = String(PageWidth) + "x" + String(PageHeight);

	If PageWidth = 210 And PageHeight = 297 Then
		Description = "A4";
	ElsIf PageWidth = 148 And PageHeight = 210 Then
		Description = "A5";
	ElsIf PageWidth = 105 And PageHeight = 148 Then
		Description = "A6";
	ElsIf PageWidth = 74 And PageHeight = 105 Then
		Description = "A7";
	ElsIf PageWidth = 52 And PageHeight = 74 Then
		Description = "A8";
	ElsIf PageWidth = 37 And PageHeight = 52 Then
		Description = "A9";
	ElsIf PageWidth = 26 And PageHeight = 37 Then
		Description = "A10";
	EndIf;

	Return Description;

EndFunction

&AtClientAtServerNoContext
Procedure RefreshTitle(Form)

	Description = Form.Object.Description;
	If Not ValueIsFilled(Form.Object.Ref) Then
		Description = Description + ?(ValueIsFilled(Description), " ", "")
			+ NStr("vi = '(Tạo mới)';
					|ru = '(Создание)';
					|en = '(Create)'; fa = '(Create)';
					|it = '(creazione)';
					|pl = '(utworzenie)';
					|tr = '(oluştur)'");
	EndIf;

	Form.AutoTitle = False;
	If Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn giá:';
							|ru = 'Шаблон ценника:';
							|en = 'Price tag template:'; fa = 'Price tag template:';
							|it = 'Modello del cartellino del prezzo:';
							|pl = 'Szablon cennika:';
							|tr = 'Fiyat etiketi numunesi:'") + " " + Description;
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ExciseStampLabel") Then
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
		
	ElsIf Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape")
		Or Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper")
		Or Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper")
		Or Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape") 
		Or Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape")
		Or Form.Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper") Then
			
		Form.Title = NStr("vi = 'Khuôn mẫu nhãn tem:';
							|ru = 'Шаблон этикетки:';
							|en = 'Label template:'; fa = 'Label template:';
							|it = 'Modello dell''etichetta:';
							|pl = 'Szablon etykiety:';
							|tr = 'Etiket numunesi:'") + " " + Description;
		
	EndIf;

	PrintPriceTagsAndLabelsLocalizationClientServer.UpdateFormHeaderLabelAndPriceTagTemplates(Form, Description);

EndProcedure

&AtServer
Procedure UploadTemplate()

	TemplateStructure = TemplateStructure();

	If TemplateStructure <> Undefined Then

		StructureOfTemplateTemplate = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Undefined, Object.Purpose);

		// Loading the template.
		TemplateStructure.Property("TabularDocumentEditor", SpreadsheetDocumentField);

		If TemplateStructure.Property("VerticalQuantity") Then
			VerticalQuantity = TemplateStructure.VerticalQuantity;
		Else
			VerticalQuantity = StructureOfTemplateTemplate.VerticalQuantity;
		EndIf;

		If TemplateStructure.Property("HorizontalQuantity") Then
			HorizontalQuantity = TemplateStructure.HorizontalQuantity;
		Else
			HorizontalQuantity = StructureOfTemplateTemplate.HorizontalQuantity;
		EndIf;

		If TemplateStructure.Property("CodeType") Then
			CodeType = TemplateStructure.CodeType;
		Else
			CodeType = StructureOfTemplateTemplate.CodeType;
		EndIf;

		If TemplateStructure.Property("BarcodeType") Then
			BarcodeType = TemplateStructure.BarcodeType;
		Else
			BarcodeSamples = GetCodes();
			For Each StringBarcodeTypes In BarcodeSamples Do
				If StringBarcodeTypes.CodeType = CodeType Then
					BarcodeType = StringBarcodeTypes.BarcodeType;
				EndIf;
			EndDo;
		EndIf;

		If TemplateStructure.Property("FontSize") Then
			FontSize = TemplateStructure.FontSize;
		Else
			FontSize = StructureOfTemplateTemplate.FontSize;
		EndIf;

		If TemplateStructure.Property("DetailLevel") Then
			DetailLevel = TemplateStructure.DetailLevel;
		Else
			DetailLevel = StructureOfTemplateTemplate.DetailLevel;
		EndIf;

		If TemplateStructure.Property("TextVisible") Then
			TextVisible = TemplateStructure.TextVisible;
		Else
			TextVisible = StructureOfTemplateTemplate.TextVisible;
		EndIf;

		If TemplateStructure.Property("GS1DatabarRowCount") Then
			GS1DatabarRowCount = TemplateStructure.GS1DatabarRowCount;
		Else
			GS1DatabarRowCount = StructureOfTemplateTemplate.GS1DatabarRowCount;
		EndIf;

		If TemplateStructure.Property("MonochromeFont") Then
			MonochromeFont = TemplateStructure.MonochromeFont;
		Else
			MonochromeFont = StructureOfTemplateTemplate.MonochromeFont;
		EndIf;

		If TemplateStructure.Property("CanvasRotation") Then
			CanvasRotation = TemplateStructure.CanvasRotation;
		Else
			CanvasRotation = StructureOfTemplateTemplate.CanvasRotation;
		EndIf;

		If TemplateStructure.Property("Zoomable") Then
			Zoomable = TemplateStructure.Zoomable;
		Else
			Zoomable = StructureOfTemplateTemplate.Zoomable;
		EndIf;

		If TemplateStructure.Property("MaintainAspectRatio") Then
			MaintainAspectRatio = TemplateStructure.MaintainAspectRatio;
		Else
			MaintainAspectRatio = StructureOfTemplateTemplate.MaintainAspectRatio;
		EndIf;

		If TemplateStructure.Property("VerticalAlignment") Then
			VerticalAlignment = TemplateStructure.VerticalAlignment;
		Else
			VerticalAlignment = StructureOfTemplateTemplate.VerticalAlignment;
		EndIf;

		Items.FontSize.Enabled = TextVisible;

	EndIf;

EndProcedure

&AtServer
Procedure CalculateMaximumNumberPerPage()

	MaxCount = MaximumNumberOfLabelsPerPage();

	VerticalQuantity = MaxCount.Vertical;
	HorizontalQuantity = MaxCount.Horizontal;

	StringPattern = NStr("vi = 'Trang %1 vừa vặn theo chiều dọc: %2, theo chiều ngang: %3';
						|ru = 'На странице %1 помещается по вертикали: %2, по горизонтали: %3';
						|en = 'On page %1 it is placed vertically: %2, horizontally: %3'; fa = 'On page %1 it is placed vertically: %2, horizontally: %3';
						|it = 'Nella pagina %1 presente in verticale: %2, in orizzontale: %3';
						|pl = 'Na stronie %1 znajduje się w pionie: %2, w poziomie: %3';
						|tr = '%1 sayfasında dikey olarak yerleştirildi: %2, yatay olarak: %3'");
	PriceTagPlacementDescription = StringFunctionsClientServer.SubstituteParametersToString(
		StringPattern,
		PageSize(SpreadsheetDocumentField),
		VerticalQuantity,
		HorizontalQuantity);

EndProcedure

&AtServer
Procedure PurposeOnChangeServer(Val ClearingAssignment = True)

	RefreshTitle(ThisForm);
	Items.GroupSizeDescription.Visible =
		(Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag")
			Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper")
			Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper")
			Or Object.Purpose = PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper"));

	FillInAvailableFields();

	TypesArray = New Array;
	Items.ForWhat.ChooseType = False;
	If Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		If ClearingAssignment Or Object.ForWhat = Undefined Then
			Object.ForWhat = Catalogs.Products.EmptyRef();
		EndIf;
		TypesArray.Add(Type("CatalogRef.Products"));
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		If ClearingAssignment Or Object.ForWhat = Undefined Then
			Object.ForWhat = Catalogs.StorageBins.EmptyRef();
		EndIf;
		TypesArray.Add(Type("CatalogRef.StorageBins"));
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		Items.ForWhat.ChooseType = True;
		If ClearingAssignment Then
			Object.ForWhat = Undefined;
		EndIf;
		TypesArray.Add(Type("DocumentRef.CustomerInvoice"));
		TypesArray.Add(Type("DocumentRef.TransferOfGoodsToBailee"));
		TypesArray.Add(Type("DocumentRef.InventoryTransfer"));
		TypesArray.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		If ClearingAssignment Or Object.ForWhat = Undefined Then
			Object.ForWhat = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		TypesArray.Add(Type("CatalogRef.ItemsBatches"));
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		If ClearingAssignment Or Object.ForWhat = Undefined Then
			Object.ForWhat = Documents.PackingList.EmptyRef();
		EndIf;
		TypesArray.Add(Type("DocumentRef.PackingList"));
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper Then
		If ClearingAssignment Or Object.ForWhat = Undefined Then
			Object.ForWhat = Catalogs.Assets.EmptyRef();
		EndIf;
		TypesArray.Add(Type("CatalogRef.Assets"));
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape Then
		If ClearingAssignment Or Object.ForWhat = Undefined Then
			Object.ForWhat = Catalogs.Assets.EmptyRef();
		EndIf;
		TypesArray.Add(Type("CatalogRef.SubAssets"));
	EndIf;

	LabelAndPriceTagTemplatesLocalization.WhenChangingTemplateAssignmentInTemplateCatalog(
		ThisObject, ClearingAssignment, TypesArray);

	Items.ForWhat.TypeRestriction = New TypeDescription(TypesArray);

	For Each Area In SpreadsheetDocumentField.Areas Do

		If TypeOf(Area) <> Type("SpreadsheetDocumentDrawing") Then
			Name = Area.Name;
			If StrStartsWith(Upper(Name), Upper("Barcode")) Then
				IndexOf = ReplaceBarcodeDrawing(Name);
				SpreadsheetDocumentField.Drawings[IndexOf].Name = Name;
			EndIf;
		Else

		EndIf;

	EndDo;
	
	CalculateMaximumNumberPerPage();
	
	FormEvents.WhenChangingElement(ThisObject, "Purpose", New Structure("ClearingAssignment", ClearingAssignment));
	
EndProcedure

&AtServer
Procedure SetDefaultTemplate(TemplateName)

	DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.GetTemplate(TemplateName);

	SpreadsheetDocumentField = DefaultTemplate;

	If TemplateName = "LabelTemplateStorageCells" Then

		BarcodeType = Enums.BarcodeTypes.Code128;
		TextVisible = False;

	ElsIf TemplateName = "ProductSeriesLabelTemplate" Then

		BarcodeType = Enums.BarcodeTypes.Code128;
		TextVisible = True;

	Else

		If Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins
				Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then

			BarcodeType = Enums.BarcodeTypes.Code128;
			TextVisible = True;

		ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then

			BarcodeType = Enums.BarcodeTypes.Code128;
			TextVisible = False;

		ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then

			BarcodeType = Enums.BarcodeTypes.QR;
			TextVisible = False;

		Else

			BarcodeType = Enums.BarcodeTypes.EAN13;
			TextVisible = True;

		EndIf;

	EndIf;

	LabelAndPriceTagTemplatesLocalization.SetDefaultTemplate(ThisObject, Object, TemplateName);

	BarcodeSamples = GetCodes();
	For Each StringBarcodeTypes In BarcodeSamples Do
		If StringBarcodeTypes.BarcodeType = BarcodeType Then
			CodeType = StringBarcodeTypes.CodeType;
		EndIf;
	EndDo;

	StructureOfTemplateTemplate = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Undefined, Object.Purpose);
	FontSize = StructureOfTemplateTemplate.FontSize;
	DetailLevel = StructureOfTemplateTemplate.DetailLevel;
	GS1DatabarRowCount = StructureOfTemplateTemplate.GS1DatabarRowCount;
	MonochromeFont = StructureOfTemplateTemplate.MonochromeFont;
	CanvasRotation = StructureOfTemplateTemplate.CanvasRotation;
	Zoomable = StructureOfTemplateTemplate.Zoomable;
	MaintainAspectRatio = StructureOfTemplateTemplate.MaintainAspectRatio;
	VerticalAlignment = StructureOfTemplateTemplate.VerticalAlignment;

	NameArray = StrSplit(TemplateName, "_");
	For Each Item In NameArray Do
		ArraySize_ = StrSplit(Item, "x");
		If ArraySize_.Count() = 2 Then
			SetDimensions(ArraySize_);
			Break;
		Else
			ArraySize_ = StrSplit(Item, "x");
			If ArraySize_.Count() = 2 Then
				SetDimensions(ArraySize_);
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	For Each Area In SpreadsheetDocumentField.Areas Do

		Name = Area.Name;
		If StrStartsWith(Upper(Name), Upper("Barcode")) Then
			IndexOf = ReplaceBarcodeDrawing(Name);
			SpreadsheetDocumentField.Drawings[IndexOf].Name = Name;
		EndIf;

	EndDo;

EndProcedure

&AtServer
Procedure SetDimensions(ArraySize_)
	Try
		Object.Width = Number(ArraySize_[0]); 
		Object.Height = Number(ArraySize_[1]); 
	Except
	EndTry;
EndProcedure

// Returns data about the template as a property structure.
//
// Returns:
//  Structure, Undefined -
//
&AtServer
Function TemplateStructure()

	TemplateStructure = Undefined;

	If ValueIsFilled(Object.Ref) Then
		TemplateStructure = Common.ObjectAttributeValue(Object.Ref, "Template").Get();
	Else
		CopyingValue = Undefined;
		Parameters.Property("CopyingValue", CopyingValue);
		If CopyingValue <> Undefined Then
			ValueOfCopyingTemplate = CopyingValue.Template; // ValueStorage
			TemplateStructure = ValueOfCopyingTemplate.Get();
		EndIf;
	EndIf;

	Return TemplateStructure;

EndFunction

&AtServer
Function PrepareStructureOfTemplateTemplate()

	StructureOfTemplateTemplate = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(SpreadsheetDocumentField, Object.Purpose);
	StructureOfTemplateTemplate.CodeType = CodeType;
	StructureOfTemplateTemplate.BarcodeType = BarcodeType;
	StructureOfTemplateTemplate.FontSize = FontSize;
	StructureOfTemplateTemplate.DetailLevel = DetailLevel;
	StructureOfTemplateTemplate.GS1DatabarRowCount = GS1DatabarRowCount;
	StructureOfTemplateTemplate.MonochromeFont = MonochromeFont;
	StructureOfTemplateTemplate.CanvasRotation = CanvasRotation;
	StructureOfTemplateTemplate.TextVisible = TextVisible;
	StructureOfTemplateTemplate.Zoomable = Zoomable;
	StructureOfTemplateTemplate.MaintainAspectRatio = MaintainAspectRatio;
	StructureOfTemplateTemplate.VerticalAlignment = VerticalAlignment;

	Return StructureOfTemplateTemplate;

EndFunction

&AtServer
Function CheckFit()

	Error = False;

	MaxCount = MaximumNumberOfLabelsPerPage();

	If MaxCount.Horizontal > 0
			And HorizontalQuantity > MaxCount.Horizontal Then

		MessageText = NStr("vi = 'Số lượng tối đa theo chiều ngang: %Count%';
							|ru = 'Максимальное количество по горизонтали: %Count%';
							|en = 'Maximum horizontal quantity: %Count%'; fa = 'Maximum horizontal quantity: %Count%';
							|it = 'Quantità massima in orizzontale: %Count%';
							|pl = 'Maksymalna ilość poziomo: %Count%';
							|tr = 'Yatay olarak maksimum miktar: %Count%'");
		MessageText = StrReplace(MessageText, "%Count%", MaxCount.Horizontal);

		CommonClientServer.MessageToUser(MessageText, , "HorizontalQuantity", , Error);

	EndIf;

	If MaxCount.Vertical > 0
			And VerticalQuantity > MaxCount.Vertical Then

		MessageText = NStr("vi = 'Số lượng tối đa theo chiều dọc: %Count%';
							|ru = 'Максимальное количество по вертикали: %Count%';
							|en = 'Maximum vertical quantity: %Count%'; fa = 'Maximum vertical quantity: %Count%';
							|it = 'Quantità massima in verticale: %Count%';
							|pl = 'Maksymalna ilość pionowo: %Count%';
							|tr = 'Dikey olarak maksimum miktar: %Count%'");
		MessageText = StrReplace(MessageText, "%Count%", MaxCount.Vertical);

		CommonClientServer.MessageToUser(MessageText, , "VerticalQuantity", , Error);

	EndIf;

	Return Not Error;

EndFunction

&AtServer
Function MaximumNumberOfLabelsPerPage()

	Return Catalogs.LabelAndPriceTagTemplates.MaximumNumberPerPage(SpreadsheetDocumentField, Object.Purpose);

EndFunction

&AtServer
Procedure SetPrintAreaOnServer(AreaName)

	SelectedArea1 = SpreadsheetDocumentField.Area(AreaName);

	None = New Line(SpreadsheetDocumentCellLineType.None, 0);
	ThinDashed = New Line(SpreadsheetDocumentCellLineType.ThinDashed, 1);

	If SpreadsheetDocumentField.PrintArea <> Undefined Then
		SpreadsheetDocumentField.PrintArea.Outline(None, None, None, None);
	EndIf;

	SpreadsheetDocumentField.PrintArea = SelectedArea1;
	SpreadsheetDocumentField.PrintArea.Outline(ThinDashed, ThinDashed, ThinDashed, ThinDashed);

	SpreadsheetDocumentField.PrintArea.AutoRowHeight = False;

EndProcedure

&AtServer
Procedure SetBarcodePicture(BarcodeDrawing)

	Etalon = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("Etalon");
	NumberOfMillimetersPerPixel = Etalon.Drawings.Square100Pixels.Height
		/ 100;

	If Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages
			And ValueIsFilled(Object.ForWhat) Then
		AttributesValues = Common.ObjectAttributesValues(Object.ForWhat, "BarcodeValue, BarcodeType");
		Barcode = AttributesValues.BarcodeValue;
	EndIf;

	If Not ValueIsFilled(Barcode) Then
		BarcodeExample = Undefined;
		Codes = GetCodes();
		For Each TSRow In Codes Do
			If TSRow.CodeType = CodeType Then
				BarcodeExample = TSRow;
				Break;
			EndIf;
		EndDo;
		Barcode = TrimAll(BarcodeExample.Sample);
	EndIf;

	BarcodeValueForComponent = Barcode;
	PrintPriceTagsAndLabelsLocalization.ModificationOfValueOfStricodeComponent(BarcodeValueForComponent, CodeType);

	BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
	BarcodeParameters.Width = Round(BarcodeDrawing.Width
		/ NumberOfMillimetersPerPixel) * DetailLevel;
	BarcodeParameters.Height = Round(BarcodeDrawing.Height
		/ NumberOfMillimetersPerPixel) * DetailLevel;
	BarcodeParameters.Barcode = BarcodeValueForComponent;
	BarcodeParameters.InputDataType = 0; // A barcode is a string
	BarcodeParameters.CodeType = CodeType;
	BarcodeParameters.GS1DatabarRowCount = GS1DatabarRowCount;
	BarcodeParameters.Insert("MonochromeFont", MonochromeFont);
	BarcodeParameters.CanvasRotation = CanvasRotation;
	BarcodeParameters.TextVisible = TextVisible;
	BarcodeParameters.FontSize = FontSize * DetailLevel;
	BarcodeParameters.Zoomable = Zoomable;
	BarcodeParameters.MaintainAspectRatio = MaintainAspectRatio;
	BarcodeParameters.VerticalAlignment = VerticalAlignment;
	
	BarcodeGenerationResult = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters);
	If BarcodeGenerationResult.Picture <> Undefined Then
		BarcodeDrawing.Picture = BarcodeGenerationResult.Picture;
	Else
		Common.MessageToUser(NStr("vi = 'Khi khởi tạo hình ảnh mã vạch đã xảy ra lỗi';
									|ru = 'При генерации картинки штрихкода произошла ошибка';
									|en = 'Error occurred when generating barcode picture'; fa = 'Error occurred when generating barcode picture';
									|it = 'Si è verificato un errore durante la generazione dell''immagine di codice a barre';
									|pl = 'Podczas generacji obraz kodu kreskowego zaistniał błąd';
									|tr = 'Barkod resmi oluşturulurken hata oluştu'"));
	EndIf;
	
EndProcedure

&AtServer
Function InsertBarcodeDrawing(CurScopeName)

	BarcodeDrawing = SpreadsheetDocumentField.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	IndexOf = SpreadsheetDocumentField.Drawings.IndexOf(BarcodeDrawing);
	BarcodeDrawing.Place(SpreadsheetDocumentField.Area(CurScopeName));
	BarcodeDrawing.Name = NameOfBarcodeParameter()
		+ StrReplace(New UUID, "-", "_");
	BarcodeDrawing.PictureSize = PictureSize.Stretch;
	BarcodeDrawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None, 0);

	SetBarcodePicture(SpreadsheetDocumentField.Drawings[IndexOf]);

	Return IndexOf;

EndFunction

&AtServer
Function InsertFigureCurrencySign(CurScopeName)

	Drawing = SpreadsheetDocumentField.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	IndexOf = SpreadsheetDocumentField.Drawings.IndexOf(Drawing);
	Drawing.Place(SpreadsheetDocumentField.Area(CurScopeName));
	Drawing.Name = "CurrencySign"
		+ StrReplace(New UUID, "-", "_");

	Drawing.BackColor = New Color;
	Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
	Drawing.PictureSize = PictureSize.Proportionally;
	Drawing.Picture = New Picture(Catalogs.LabelAndPriceTagTemplates.GetTemplate("CurrencySign643"), True);

	Return IndexOf;

EndFunction

&AtServer
Function ReplaceBarcodeDrawing(PictureNameOrPicture)

	BarcodeDrawingSource = Undefined;
	If TypeOf(PictureNameOrPicture) = Type("String") Then
		For Each Drawing In SpreadsheetDocumentField.Drawings Do
			If Drawing.Name <> PictureNameOrPicture Then
				Continue;
			EndIf;
			BarcodeDrawingSource = Drawing;
			Break;
		EndDo;
	Else
		BarcodeDrawingSource = PictureNameOrPicture;
	EndIf;

	BarcodeDrawing = SpreadsheetDocumentField.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	BarcodeDrawing.Top = BarcodeDrawingSource.Top;
	BarcodeDrawing.Left = BarcodeDrawingSource.Left;
	BarcodeDrawing.Height = BarcodeDrawingSource.Height;
	BarcodeDrawing.Width = BarcodeDrawingSource.Width;
	BarcodeDrawing.Name = BarcodeDrawingSource.Name;
	BarcodeDrawing.Line = BarcodeDrawingSource.Line;
	BarcodeDrawing.PictureSize = BarcodeDrawingSource.PictureSize;

	SpreadsheetDocumentField.Drawings.Delete(BarcodeDrawingSource);

	IndexOf = SpreadsheetDocumentField.Drawings.IndexOf(BarcodeDrawing);
	SetBarcodePicture(SpreadsheetDocumentField.Drawings[IndexOf]);

	Return IndexOf;

EndFunction

&AtServer
Procedure MergeArea(AreaName)

	Area = SpreadsheetDocumentField.Area(AreaName);
	Area.Merge();

EndProcedure

&AtServer
Procedure DisconnectArea(AreaName)

	Area = SpreadsheetDocumentField.Area(AreaName);
	Area.UndoMerge();

EndProcedure

&AtServer
Procedure CustomizeTemplate()

	If ValueIsFilled(TemplateName) Then
		SetDefaultTemplate(TemplateName);
	Else
		SpreadsheetDocumentField = New SpreadsheetDocument;
		SpreadsheetDocumentField.PrintArea = SpreadsheetDocumentField.Area("R2C2:R20C5");
		ThinDashed = New Line(SpreadsheetDocumentCellLineType.ThinDashed, 1);
		SpreadsheetDocumentField.PrintArea.Outline(ThinDashed, ThinDashed, ThinDashed, ThinDashed);

		StructureOfTemplateTemplate = Catalogs.LabelAndPriceTagTemplates.PrepareStructureOfTemplateTemplate(Undefined, Object.Purpose);
		HorizontalQuantity = StructureOfTemplateTemplate.HorizontalQuantity;
		VerticalQuantity = StructureOfTemplateTemplate.VerticalQuantity;
		CodeType = StructureOfTemplateTemplate.CodeType;
		BarcodeType = StructureOfTemplateTemplate.BarcodeType;
		TextVisible = StructureOfTemplateTemplate.TextVisible;
		FontSize = StructureOfTemplateTemplate.FontSize;
		DetailLevel = StructureOfTemplateTemplate.DetailLevel;
		GS1DatabarRowCount = StructureOfTemplateTemplate.GS1DatabarRowCount;
		MonochromeFont = StructureOfTemplateTemplate.MonochromeFont;
		CanvasRotation = StructureOfTemplateTemplate.CanvasRotation;
		Zoomable = StructureOfTemplateTemplate.Zoomable;
		MaintainAspectRatio = StructureOfTemplateTemplate.MaintainAspectRatio;
		VerticalAlignment = StructureOfTemplateTemplate.VerticalAlignment;

		Items.TextVisible.Enabled = True;
		Items.CodeType.Enabled = True;
	EndIf;

	Items.FontSize.Enabled = TextVisible;

EndProcedure

// Parameters:
// 	Collection - A collection of available data fields - Description
// 	Field Structure - Arbitrary - Description
// 	Tree - Tree of values - contains, among other things:
// 		* Description - String - 
&AtServer
Procedure FillInAvailableFields()

	SetPrivilegedMode(True);

	DataCompositionSchema = Undefined;
	LabelAndPriceTagTemplatesLocalization.WhenFillingOutDataLayoutDiagram(DataCompositionSchema, Object.Purpose);

	// Filling in the available fields
	If Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsStorageBins");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsGoods");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsGoods");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsDelivery");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsItemBatch");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsPackingLists");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper Then
		DataCompositionSchema = DataProcessors.LabelPrintingOfAssets.GetTemplate("FieldsOfTemplateAssets");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper Then
		DataCompositionSchema = DataProcessors.LabelPrintingOfSubAssets.GetTemplate("FieldsOfTemplateSubAsset");
	EndIf;
	
	FieldsNames = New Array;
	LabelAndPriceTagTemplatesLocalization.WhenFillingInAvailableDataLayoutFields(FieldsNames, Object.Purpose);
	
	If Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
	
		FieldsNames.Add("Barcode");
	
		FieldsNames.Add("Cell");
		FieldsNames.Add("Cell.Code");
		FieldsNames.Add("Cell.Parent");
		FieldsNames.Add("Cell.Line");
		FieldsNames.Add("Cell.Description");
		FieldsNames.Add("Cell.Position");
		FieldsNames.Add("Cell.TabIndex");
		FieldsNames.Add("Cell.WarehouseZone");
		FieldsNames.Add("Cell.Section3");
		FieldsNames.Add("Cell.Owner");
		FieldsNames.Add("Cell.Rack");
		FieldsNames.Add("Cell.Tier");
	
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag
			Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
	
		FieldsNames.Add("Barcode");
	
		FieldsNames.Add("PriceKind");
		FieldsNames.Add("PriceKind.PriceCurrency");
		FieldsNames.Add("PriceKind.Description");
		FieldsNames.Add("PriceKind.PriceIncludesVAT");
		FieldsNames.Add("Price");
		FieldsNames.Add("LastPriceChangeDate");

		FieldsNames.Add("PriceKindAdditional");
		FieldsNames.Add("PriceKindAdditional.PriceCurrency");
		FieldsNames.Add("PriceKindAdditional.Description");
		FieldsNames.Add("PriceKindAdditional.PriceIncludesVAT");
		FieldsNames.Add("PriceAdditionally");
		FieldsNames.Add("LastPriceChangeDateAdditionally");

		FieldsNames.Add("Products.SKU");
		FieldsNames.Add("Products.SaleRegistrationOption");
		FieldsNames.Add("Products.Weight");
		FieldsNames.Add("Products.KeepRecordsByCCD");
		FieldsNames.Add("Products.ProductKind");
		FieldsNames.Add("Products.Parent");
		FieldsNames.Add("Products.UnitOfMeasure");
		FieldsNames.Add("Products.Code");
		FieldsNames.Add("Products.SearchCode");
		FieldsNames.Add("Products.Description");
		FieldsNames.Add("Products.DescriptionFull");
		FieldsNames.Add("Products.VolumeM3");
		FieldsNames.Add("Products.Manufacturer");
		FieldsNames.Add("Products.LongDesc");
		FieldsNames.Add("Products.ItemsType");
		FieldsNames.Add("Products,Properties");
		
		FieldsNames.Add("Characteristic.Description");
		FieldsNames.Add("Characteristic.DescriptionFull");
		FieldsNames.Add("Characteristic.Owner");
		FieldsNames.Add("Characteristic,Properties");
		
		FieldsNames.Add("Series.Description");
		FieldsNames.Add("Series,Properties");

		FieldsNames.Add("SoldByWeight");
		FieldsNames.Add("CodeOfConnectedEquipmentOffline");
		FieldsNames.Add("PLU");
		FieldsNames.Add("Organization");
		FieldsNames.Add("CurrentTime");
		FieldsNames.Add("CurrentUser");
		FieldsNames.Add("PackagingUnitOfMeasure");
		FieldsNames.Add("VATRate");

	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then

		FieldsNames.Add("InvoiceWeight");
		FieldsNames.Add("UnitOfMeasureForWeight");
		FieldsNames.Add("UnitOfMeasureForVolume");
		FieldsNames.Add("NumberOfRows");
		FieldsNames.Add("InvoiceVolume");
		FieldsNames.Add("ReferenceOrder,Properties");

		FieldsNames.Add("ReferenceOrder.Author");
		FieldsNames.Add("ReferenceOrder.DeliveryAddress");
		FieldsNames.Add("ReferenceOrder.ShipperBankAccount");
		FieldsNames.Add("ReferenceOrder.GoodsRecipientBankAccount");
		FieldsNames.Add("ReferenceOrder.CounterpartyBankAccount");
		FieldsNames.Add("ReferenceOrder.CompanyBankAccount");
		FieldsNames.Add("ReferenceOrder.Currency");
		FieldsNames.Add("ReferenceOrder.ARAPCurrency");
		FieldsNames.Add("ReferenceOrder.PriceKind");
		FieldsNames.Add("ReferenceOrder.InventoryKinds");
		FieldsNames.Add("ReferenceOrder.Shipper");
		FieldsNames.Add("ReferenceOrder.GoodsRecipient");
		FieldsNames.Add("ReferenceOrder.Date");
		FieldsNames.Add("ReferenceOrder.PowerOfAttorneyDate");
		FieldsNames.Add("ReferenceOrder.PaymentDate");
		FieldsNames.Add("ReferenceOrder.Contract");
		FieldsNames.Add("ReferenceOrder.IssuiedByJobTitle");
		FieldsNames.Add("ReferenceOrder.LoyaltyCard");
		FieldsNames.Add("ReferenceOrder.CashAccount");
		FieldsNames.Add("ReferenceOrder.LetterOfAuthorityIssuedBy");
		FieldsNames.Add("ReferenceOrder.Partner,Properties");
		FieldsNames.Add("ReferenceOrder.Comment");
		FieldsNames.Add("ReferenceOrder.PowerOfAttorneyPerson");
		FieldsNames.Add("ReferenceOrder.Manager");
		FieldsNames.Add("ReferenceOrder.VATTaxation");
		FieldsNames.Add("ReferenceOrder.Number");
		FieldsNames.Add("ReferenceOrder.PowerOfAttorneyNumber");
		FieldsNames.Add("ReferenceOrder.BusinessOperation");
		FieldsNames.Add("ReferenceOrder.Organization");
		FieldsNames.Add("ReferenceOrder.Basis");
		FieldsNames.Add("ReferenceOrder.EmployeeResponsible");
		FieldsNames.Add("ReferenceOrder.IssuiedBy");
		FieldsNames.Add("ReferenceOrder.Department");
		FieldsNames.Add("ReferenceOrder.Warehouse");
		FieldsNames.Add("ReferenceOrder.SourceWarehouse");
		FieldsNames.Add("ReferenceOrder.DestinationWarehouse");
		FieldsNames.Add("ReferenceOrder.Approved");
		FieldsNames.Add("ReferenceOrder.Terms");
		FieldsNames.Add("ReferenceOrder.AmountARAP");
		FieldsNames.Add("ReferenceOrder.DocumentAmount");
		FieldsNames.Add("ReferenceOrder.PaymentMethod");
		FieldsNames.Add("ReferenceOrder.PriceIncludesVAT");

	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then

		FieldsNames.Add("Barcode");
		FieldsNames.Add("Series.ProductKind");
		FieldsNames.Add("Series.ValidUntil_");
		FieldsNames.Add("Series.Description");
		FieldsNames.Add("Series.Number");
		FieldsNames.Add("Series,Properties");

	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then

		FieldsNames.Add("Barcode");
		FieldsNames.Add("Code");
		FieldsNames.Add("Basis");

		FieldsNames.Add("PackingList.Code");
		FieldsNames.Add("PackingList.PackageWarehouse");
		FieldsNames.Add("PackingList.Kind");
		FieldsNames.Add("PackingList.PackedBy");
		FieldsNames.Add("PackingList.Basis");
		FieldsNames.Add("PackingList.Comment");
		FieldsNames.Add("PackingList.TotalNumberOfPackageItems");

	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then

		FieldsNames = New Array;
		FieldsNames.Add("AssetID");

		FieldsNames.Add("Products.SKU");
		FieldsNames.Add("Products.SaleRegistrationOption");
		FieldsNames.Add("Products.Weight");
		FieldsNames.Add("Products.KeepRecordsByCCD");
		FieldsNames.Add("Products.ProductKind");
		FieldsNames.Add("Products.Parent");
		FieldsNames.Add("Products.UnitOfMeasure");
		FieldsNames.Add("Products.Code");
		FieldsNames.Add("Products.SearchCode");
		FieldsNames.Add("Products.Description");
		FieldsNames.Add("Products.DescriptionFull");
		FieldsNames.Add("Products.VolumeM3");
		FieldsNames.Add("Products.Manufacturer");
		FieldsNames.Add("Products.LongDesc");
		FieldsNames.Add("Products.ItemsType");
		FieldsNames.Add("Products,Properties");

		FieldsNames.Add("Characteristic.Description");
		FieldsNames.Add("Characteristic.DescriptionFull");
		FieldsNames.Add("Characteristic.Owner");
		FieldsNames.Add("Characteristic,Properties");
		
		FieldsNames.Add("Series.Description");
		FieldsNames.Add("Series.ValidUntil_");
		FieldsNames.Add("Series.Number");
		FieldsNames.Add("Series,Properties");

		FieldsNames.Add("Lot.Description");
		FieldsNames.Add("Lot.OperationCategory");
		FieldsNames.Add("Lot.ServiceLife");
		FieldsNames.Add("Lot.StartDateOfOperation");
		FieldsNames.Add("Lot.CompletionDate_");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper Then

		FieldsNames = New Array;
		FieldsNames.Add("Barcode");

		FieldsNames.Add("Asset");
		FieldsNames.Add("Asset.DescriptionFull");
		FieldsNames.Add("Asset.AssetID");
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
		Or Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper Then

		FieldsNames = New Array;
		FieldsNames.Add("Barcode");

		FieldsNames.Add("Node");
		FieldsNames.Add("Node.DescriptionFull");
		FieldsNames.Add("Node.Class");
		FieldsNames.Add("Node.Subclass");
		FieldsNames.Add("Node.Model");
		FieldsNames.Add("Node.SerialNumber");
		FieldsNames.Add("Node.Barcode");
	EndIf;
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	If Not DataCompositionSchema = Undefined Then
		
		SweepRestrictions = SweepRestrictionsOnFieldNames(FieldsNames, "");
		ProcessingOfFormulas.AddAvailableFieldsToTreeUsingLayoutScheme(OperandsTree, DataCompositionSchema, SweepRestrictions);
		
		RecursivelyExpandTreeRowsGivenFieldConstraints(OperandsTree, FieldsNames, "");
	EndIf;
	
	SetPrivilegedMode(False);
	
	ProcessingOfFormulas.LoadOperandTreeIntoTreeOfForm(DataCompositionAvailableFields, OperandsTree);
	
EndProcedure

&AtServer
Function SweepRestrictionsOnFieldNames(FieldsNames, PreviousAccumulatedFieldLevel = "")
	SweepRestrictions = ProcessingOfFormulas.LimitationsOfOperandSweep();
	SweepRestrictions.OutputAttributes = "";
	SweepRestrictions.DisplayBankingDetails = False;
	SweepRestrictions.DisplayCharacteristics = False;
	
	OutputFields = New Array;
	For Each FieldStructure In FieldsNames Do
		// Checking whether the field structure corresponds to the output branch (the previous accumulated field level).
		If PreviousAccumulatedFieldLevel = "" Then
			RestOfFieldStructure = FieldStructure;
		ElsIf StrStartsWith(FieldStructure, PreviousAccumulatedFieldLevel)
			And (Mid(FieldStructure, StrLen(PreviousAccumulatedFieldLevel) + 1, 1) = "."
				Or Mid(FieldStructure, StrLen(PreviousAccumulatedFieldLevel) + 1, 1) = ",") Then
			RestOfFieldStructure = Mid(FieldStructure, StrLen(PreviousAccumulatedFieldLevel) + 1);
		Else
			RestOfFieldStructure = "";
		EndIf;
		
		If Not IsBlankString(RestOfFieldStructure) Then
			// the description of the properties is separated by commas at the end.
			IncludingEmptyOnes = True; // Field names in any case with index 0.
			FieldNamesAndActions = StrSplit(RestOfFieldStructure, ",", IncludingEmptyOnes);
			FieldEnumerations = FieldNamesAndActions[0];
			
			IncludingEmptyOnes = False;
			FieldHierarchy = StrSplit(FieldEnumerations, ".", IncludingEmptyOnes);
			
			If FieldHierarchy.Count() = 0
				And FieldNamesAndActions.Count() = 2
				And FieldNamesAndActions[1] = "Properties" Then
				SweepRestrictions.DisplayCharacteristics = True;
			EndIf;
			FieldsCount = FieldHierarchy.Count();
			If FieldsCount > 0 Then
				For FieldCounter = 1 To FieldsCount Do
					FullFieldName1 = "";
					For NestedFieldCounter = 1 To FieldCounter Do
						Field = FieldHierarchy[NestedFieldCounter - 1];
						FullFieldName1 = FullFieldName1 + ?(FullFieldName1 = "", "", ".") + Field;
					EndDo;
					If OutputFields.Find(FullFieldName1) = Undefined Then
						OutputFields.Add(FullFieldName1);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	SweepRestrictions.OutputAttributes = StrConcat(OutputFields, ",");
	If OutputFields.Count() > 0 Then
		SweepRestrictions.DisplayBankingDetails = True;
	EndIf;
	
	Return SweepRestrictions;
	
EndFunction

&AtServer
Procedure RecursivelyExpandTreeRowsGivenFieldConstraints(StringSource_, FieldsNames, Val PreviousAccumulatedLevel = "")
	
	TypesOfTreeElements = ProcessingOfFormulas.TypesOfOperandTreeElements();
	For Each TreeRow In StringSource_.Rows Do
		CurAccumulatedLevel = PreviousAccumulatedLevel + ?(PreviousAccumulatedLevel = "", "", ".") + TreeRow.Id;
		SweepRestrictions = SweepRestrictionsOnFieldNames(FieldsNames, CurAccumulatedLevel);
		If TreeRow.TreeItemType = TypesOfTreeElements.Group
			Or TreeRow.TreeItemType = TypesOfTreeElements.TopLevelRowGroup Then
			// The groups of strings themselves are not expanded, but contain substrings inside.
			For Each SubordinateRow In TreeRow.Rows Do
				RecursivelyExpandTreeRowsGivenFieldConstraints(SubordinateRow, FieldsNames, CurAccumulatedLevel);
			EndDo;
			Continue;
		EndIf;
		If SweepRestrictions.DisplayBankingDetails
			Or SweepRestrictions.DisplayCharacteristics Then
			
			If SweepRestrictions.DisplayCharacteristics
				And TypeOf(Object.ForWhat) = Type("CatalogRef.Products")
				And ValueIsFilled(Object.ForWhat) Then
				
				If TreeRow.Id = "Products" Then
					Set = Common.ObjectAttributeValue(Object.ForWhat, "ProductKind.PropertiesSet");
					If ValueIsFilled(Set) Then
						SweepRestrictions.AdditionalAttributeSets.Add(Set);
					Else
						SweepRestrictions.DisplayCharacteristics = False;
					EndIf;
				ElsIf TreeRow.Id = "Characteristic" Then
					Set = Common.ObjectAttributeValue(Object.ForWhat, "ProductKind.CharacteristicsPropertySet");
					If ValueIsFilled(Set) Then
						SweepRestrictions.AdditionalAttributeSets.Add(Set);
					Else
						SweepRestrictions.DisplayCharacteristics = False;
					EndIf;
				ElsIf TreeRow.Id = "Series" Then
					Set = Common.ObjectAttributeValue(Object.ForWhat, "ProductKind.BatchPropertySet");
					If ValueIsFilled(Set) Then
						SweepRestrictions.AdditionalAttributeSets.Add(Set);
					Else
						SweepRestrictions.DisplayCharacteristics = False;
					EndIf;
				EndIf;
				
			EndIf;
			
			ProcessingOfFormulas.ExpandOperandString(TreeRow, SweepRestrictions);
			RecursivelyExpandTreeRowsGivenFieldConstraints(TreeRow, FieldsNames, CurAccumulatedLevel);
		Else
			// Based on the description of the fields, it is not necessary to expand the rows further (the maximum level of scanning
			// is limited by the list), so we remove the flag for recursive scanning of rows.
			TreeRow.ExpandToAttributes = False;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure SetSize(AreaWidthInMillimeters,
		AreaHeightInMillimeters, CellSizeInMillimeters)

	StandardSizes = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("StandardStorageBinSizes");
	Picture = StandardSizes.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	Picture.Place(StandardSizes.Area("R1C1:R100C100"));
	ImageHeightInMillimeters = Picture.Height;
	ImageWidthInMillimeters = Picture.Width;

	HeightInMillimetersOfCellHeight0_25 = ImageHeightInMillimeters / 100;
	WidthInMillimetersOfCellWidth0_125 = (ImageWidthInMillimeters / 100)
		/ 4;

	MinimumWidthSettingStep = 0.125;
	MinimumHeightSettingStep = 0.25;

	NumberOfStepsPerMillimeterInHeight = 0;
	While NumberOfStepsPerMillimeterInHeight
		* HeightInMillimetersOfCellHeight0_25 < 1 Do
		NumberOfStepsPerMillimeterInHeight = NumberOfStepsPerMillimeterInHeight + 1;
	EndDo;
	NumberOfStepsPerMillimeterInHeight = NumberOfStepsPerMillimeterInHeight - 1;

	NumberOfStepsPerMillimeterInWidth = 0;
	While NumberOfStepsPerMillimeterInWidth
		* WidthInMillimetersOfCellWidth0_125 < 1 Do
		NumberOfStepsPerMillimeterInWidth = NumberOfStepsPerMillimeterInWidth + 1;
	EndDo;
	NumberOfStepsPerMillimeterInWidth = NumberOfStepsPerMillimeterInWidth - 1;

	RandomNumberGenerator = New RandomNumberGenerator;
	SpreadsheetDocumentField.Clear();

	NumberOfCellsByWidth = Int(AreaWidthInMillimeters
		/ CellSizeInMillimeters);
	NumberOfCellsByHeight = Int(AreaHeightInMillimeters
		/ CellSizeInMillimeters);

	DocumentWidth = 1 + NumberOfCellsByWidth;
	DocumentHeight = 1 + NumberOfCellsByHeight;

	For ColumnNumber = 2 To DocumentWidth Do
	// Minimum width setting step = 0.125
	// 1 cell with a width of 0.5 takes 0.97 mm.
		AreaName = "C" + ColumnNumber;
		SpreadsheetDocumentField.Area(AreaName).ColumnWidth = (MinimumWidthSettingStep
			* NumberOfStepsPerMillimeterInWidth) * CellSizeInMillimeters;
	EndDo;

	For LineNumber = 2 To DocumentHeight Do
	// The minimum height setting step = 0.25
	// 1 cell with a width of 2.75 takes 0.97 mm.
		AreaName = "R" + LineNumber;
		SpreadsheetDocumentField.Area(AreaName).AutoRowHeight = False;
		SpreadsheetDocumentField.Area(AreaName).RowHeight = (MinimumHeightSettingStep
			* NumberOfStepsPerMillimeterInHeight) * CellSizeInMillimeters;
	EndDo;

	AreaNameSeals = "R2C2" + ":" + "R" + Format(DocumentHeight, "NG=0") + "C"
		+ Format(DocumentWidth, "NG=0");
	SpreadsheetDocumentField.Area("R1C1:" + "R" + 200 + "C"
		+ 200).BackColor = WebColors.Gray;
	SpreadsheetDocumentField.Area(AreaNameSeals).BackColor = New Color;
	SetPrintAreaOnServer(AreaNameSeals);

	PictureIndex = InsertBarcodeDrawing(AreaNameSeals);
	ActualWidthInMillimeters = SpreadsheetDocumentField.Drawings[PictureIndex].Width;
	ActualHeightInMillimeters = SpreadsheetDocumentField.Drawings[PictureIndex].Height;

	// Let's perform a fitting to more accurately match the real values.
	MissingWidthInMillimeters = AreaWidthInMillimeters
		- ActualWidthInMillimeters;
	NumberOfCellsToChangeWidth = Int(MissingWidthInMillimeters
		/ ((ActualWidthInMillimeters / AreaWidthInMillimeters)
		/ NumberOfStepsPerMillimeterInWidth));

	ZoomRatio = 1;
	NumberOfChangedCells = 0;
	While NumberOfCellsToChangeWidth > 0 Do // -1 in order not to exceed the actual required values
		ColumnNumber = RandomNumberGenerator.RandomNumber(2, DocumentWidth);
		AreaName = "C" + ColumnNumber;
		If SpreadsheetDocumentField.Area(AreaName).ColumnWidth = (MinimumWidthSettingStep
				* NumberOfStepsPerMillimeterInWidth) * CellSizeInMillimeters
				+ MinimumWidthSettingStep * (ZoomRatio - 1) Then
			SpreadsheetDocumentField.Area(AreaName).ColumnWidth = (MinimumWidthSettingStep
				* NumberOfStepsPerMillimeterInWidth) * CellSizeInMillimeters
				+ MinimumWidthSettingStep * ZoomRatio;
			NumberOfCellsToChangeWidth = NumberOfCellsToChangeWidth - 1;

			NumberOfChangedCells = NumberOfChangedCells + 1;
		EndIf;

		If NumberOfChangedCells = NumberOfCellsByWidth Then
			NumberOfChangedCells = 0;
			ZoomRatio = ZoomRatio + 1;
		EndIf;

		If NumberOfCellsToChangeWidth = 0 Then
			ActualWidthInMillimeters = SpreadsheetDocumentField.Drawings[PictureIndex].Width;
			MissingWidthInMillimeters = AreaWidthInMillimeters
				- ActualWidthInMillimeters;
			NumberOfCellsToChangeWidth = Int(MissingWidthInMillimeters
				/ ((ActualWidthInMillimeters / AreaWidthInMillimeters)
				/ NumberOfStepsPerMillimeterInWidth));
		EndIf;

	EndDo;

	// Let's perform a fitting to more accurately match the real values.
	MissingHeightInMillimeters = AreaHeightInMillimeters
		- ActualHeightInMillimeters;
	NumberOfCellsToChangeHeight = Int(MissingHeightInMillimeters
		/ ((ActualHeightInMillimeters / AreaHeightInMillimeters)
		/ NumberOfStepsPerMillimeterInHeight));

	ZoomRatio = 1;
	NumberOfChangedCells = 0;
	While NumberOfCellsToChangeHeight > 0 Do // -1 in order not to exceed the actual required values
		LineNumber = RandomNumberGenerator.RandomNumber(2, DocumentHeight);
		AreaName = "R" + LineNumber;
		If SpreadsheetDocumentField.Area(AreaName).RowHeight = (MinimumHeightSettingStep
				* NumberOfStepsPerMillimeterInHeight) * CellSizeInMillimeters
				+ MinimumHeightSettingStep * (ZoomRatio - 1) Then
			SpreadsheetDocumentField.Area(AreaName).RowHeight = (MinimumHeightSettingStep
				* NumberOfStepsPerMillimeterInHeight) * CellSizeInMillimeters
				+ MinimumHeightSettingStep * ZoomRatio;
			NumberOfCellsToChangeHeight = NumberOfCellsToChangeHeight - 1;

			NumberOfChangedCells = NumberOfChangedCells + 1;
		EndIf;

		If NumberOfChangedCells = NumberOfCellsByHeight Then
			NumberOfChangedCells = 0;
			ZoomRatio = ZoomRatio + 1;
		EndIf;

		If NumberOfCellsToChangeHeight = 0 Then
			ActualHeightInMillimeters = SpreadsheetDocumentField.Drawings[PictureIndex].Height;
			MissingHeightInMillimeters = AreaHeightInMillimeters
				- ActualHeightInMillimeters;
			NumberOfCellsToChangeHeight = Int(MissingHeightInMillimeters
				/ ((ActualHeightInMillimeters / AreaHeightInMillimeters)
				/ NumberOfStepsPerMillimeterInHeight));
		EndIf;

	EndDo;

	SpreadsheetDocumentField.Drawings.Delete(SpreadsheetDocumentField.Drawings[PictureIndex]);

	CalculateMaximumNumberPerPage();

EndProcedure

&AtServer
Function AddParametersForPrintingSample(PrintParameters)

	PrintParameters.Insert("StructureOfTemplateTemplate", PrepareStructureOfTemplateTemplate());

	Return PrintParameters;

EndFunction

&AtServer
Function GetParametersForPrintingSampleProductLabel()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleProductLabel(
		Object.ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtServer
Function GetParametersForPrintingSampleProductPriceTag()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleProductPriceTag(
		Object.ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelOfWarehouseCell()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelOfWarehouseCell(
		Object.ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtServer
Function GetParametersForPrintingSampleShippingLabels()

	ObjectsArray = New Array;
	ObjectsArray.Add(Object.ForWhat);

	PrintParameters = DataProcessors.PrintPriceTagsAndLabels.ShippingLabelPrintingData(ObjectsArray);
	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelsPackingSheets()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelsPackingSheets(
		Object.ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelsOfProductSeries()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelsOfProductSeries(
		Object.ForWhat, CodeType, UUID);
	Return AddParametersForPrintingSample(PrintParameters);

EndFunction


&AtServer
Function GetParametersForPrintingSampleLabelOfObjectOfOperation()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelOfObjectOfOperation(
		Object.ForWhat, CodeType, UUID);

	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtServer
Function GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation()

	PrintParameters = Catalogs.LabelAndPriceTagTemplates.GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation(
		Object.ForWhat, CodeType, UUID);

	Return AddParametersForPrintingSample(PrintParameters);

EndFunction

&AtClient
Procedure SpreadsheetDocumentFieldDrag(Item,
		DragParameters, StandardProcessing, Area)

	StandardProcessing = False;

	SubstituteTemplateField(Area, Items.DataCompositionAvailableFields.CurrentRow);

EndProcedure

&AtClient
Function LinePresentation_(Line)

	If Line <> Undefined Then
		Result = String(Line.LineType) + ", "
			+ String(?(Line.Width = 0, 1, Line.Width))
	Else
		Result = "";
	EndIf;

	Return Result;

EndFunction

&AtClient
Procedure FillInPropertiesTable()

	SelectedArea1 = SpreadsheetDocumentField.CurrentArea;
	CellProperties.Clear();

	If TypeOf(SelectedArea1) = Type("SpreadsheetDocumentRange") Then

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Separator";
		NewRow.Presentation = NStr("vi = 'Trang trí';
									|ru = 'Оформление';
									|en = 'Appearance'; fa = 'ظاهر';
									|it = 'Formattazione';
									|pl = 'Appearance';
									|tr = 'Düzenleme'");
		NewRow.Value = NStr("vi = 'Ký tự tách';
							|ru = 'Разделитель';
							|en = 'Separator'; fa = 'جداکننده';
							|it = 'Разделитель';
							|pl = 'Separator';
							|tr = 'Ayırıcı'");

		// Font and color
		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Font";
		NewRow.Presentation = NStr("vi = 'Cỡ chữ';
									|ru = 'Шрифт';
									|en = 'Font'; fa = 'فونت';
									|it = 'Font';
									|pl = 'Font';
									|tr = 'Yazı tipi'");
		NewRow.Value = SelectedArea1.Font;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "BackColor";
		NewRow.Presentation = NStr("vi = 'Màu nền';
									|ru = 'Цвет фона';
									|en = 'Background color'; fa = 'رنگ پس‌زمینه';
									|it = 'Colore di sfondo';
									|pl = 'Kolor tła';
									|tr = 'Arka plan rengi'");
		NewRow.Value = SelectedArea1.BackColor;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "TextColor";
		NewRow.Presentation = NStr("vi = 'Màu nội dung';
									|ru = 'Цвет текста';
									|en = 'Text color'; fa = 'رنگ متن';
									|it = 'Colore testo';
									|pl = 'Kolor tekstu';
									|tr = 'Metin rengi'");
		NewRow.Value = SelectedArea1.TextColor;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "TextOrientation";
		NewRow.Presentation = NStr("vi = 'Hướng văn bản';
									|ru = 'Ориентация текста';
									|en = 'Text orientation'; fa = 'جهت متن';
									|it = 'Orientamento del testo';
									|pl = 'Orientacja tekstu';
									|tr = 'Metin yönü'");
		NewRow.Value = SelectedArea1.TextOrientation;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Separator";
		NewRow.Presentation = NStr("vi = 'Biên';
									|ru = 'Границы';
									|en = 'Borders'; fa = 'کادرها';
									|it = 'Margini';
									|pl = 'Borders';
									|tr = 'Sınırlar'");
		NewRow.Value = NStr("vi = 'Ký tự tách';
							|ru = 'Разделитель';
							|en = 'Separator'; fa = 'جداکننده';
							|it = 'Разделитель';
							|pl = 'Separator';
							|tr = 'Ayırıcı'");

		// Boundaries
		NewRow = CellProperties.Add();
		NewRow.PropertyName = "LeftBorder";
		NewRow.Presentation = NStr("vi = 'Biên bên trái';
									|ru = 'Граница слева';
									|en = 'Left border'; fa = 'کادر چپ';
									|it = 'Bordo a sinistra';
									|pl = 'Lewa granica';
									|tr = 'Sol kenarlık'");
		NewRow.Value = LinePresentation_(SelectedArea1.LeftBorder);

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "TopBorder";
		NewRow.Presentation = NStr("vi = 'Biên phía trên';
									|ru = 'Граница сверху';
									|en = 'Top border'; fa = 'کادر بالا';
									|it = 'Bordo sopra';
									|pl = 'Górna granica';
									|tr = 'Üst kenarlık'");
		NewRow.Value = LinePresentation_(SelectedArea1.TopBorder);

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "RightBorder";
		NewRow.Presentation = NStr("vi = 'Biên bên phải';
									|ru = 'Граница справа';
									|en = 'Right border'; fa = 'کادر راست';
									|it = 'Bordo a destra';
									|pl = 'Prawa granica';
									|tr = 'Sağ kenarlık'");
		NewRow.Value = LinePresentation_(SelectedArea1.RightBorder);

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "BottomBorder";
		NewRow.Presentation = NStr("vi = 'Biên phía dưới';
									|ru = 'Граница снизу';
									|en = 'Bottom border'; fa = 'کادر پایین';
									|it = 'Bordo sotto';
									|pl = 'Dolna granica';
									|tr = 'Alt kenarlık'");
		NewRow.Value = LinePresentation_(SelectedArea1.BottomBorder);

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Separator";
		NewRow.Presentation = NStr("vi = 'Điền';
									|ru = 'Заполнение';
									|en = 'Filling'; fa = 'پرکردن';
									|it = 'Compilazione';
									|pl = 'Filling';
									|tr = 'Doldurma'");
		NewRow.Value = NStr("vi = 'Ký tự tách';
							|ru = 'Разделитель';
							|en = 'Separator'; fa = 'جداکننده';
							|it = 'Разделитель';
							|pl = 'Separator';
							|tr = 'Ayırıcı'");

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "FillType";
		NewRow.Presentation = NStr("vi = 'Điền';
									|ru = 'Заполнение';
									|en = 'Filling'; fa = 'پرکردن';
									|it = 'Compilazione';
									|pl = 'Filling';
									|tr = 'Doldurma'");
		NewRow.Value = SelectedArea1.FillType;

		If SelectedArea1.FillType = SpreadsheetDocumentAreaFillType.Parameter Then
			NewRow = CellProperties.Add();
			NewRow.PropertyName = "Parameter";
			NewRow.Presentation = NStr("vi = 'Tham số';
										|ru = 'Параметр';
										|en = 'Parameter'; fa = 'پارامتر';
										|it = 'Parametro';
										|pl = 'Parameter';
										|tr = 'Parametre'");
			NewRow.Value = SelectedArea1.Parameter;
			If NewRow.Value = Undefined Then
				NewRow.Value = "";
			EndIf;
		Else
			NewRow = CellProperties.Add();
			NewRow.PropertyName = "Text";
			NewRow.Presentation = NStr("vi = 'Nội dung';
										|ru = 'Текст';
										|en = 'Text'; fa = 'متن';
										|it = 'Testo';
										|pl = 'Text';
										|tr = 'Metin'");
			NewRow.Value = SelectedArea1.Text;
		EndIf;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Format";
		NewRow.Presentation = NStr("vi = 'Định dạng';
									|ru = 'Формат';
									|en = 'Format'; fa = 'قالب';
									|it = 'Formato';
									|pl = 'Format';
									|tr = 'Format'");
		NewRow.Value = SelectedArea1.Format;
		NewRow.ReadOnly = (SelectedArea1.FillType <> SpreadsheetDocumentAreaFillType.Parameter);

	ElsIf TypeOf(SelectedArea1) = Type("SpreadsheetDocumentDrawing") Then

		If SelectedArea1.DrawingType = SpreadsheetDocumentDrawingType.Text
				Or SelectedArea1.DrawingType = SpreadsheetDocumentDrawingType.Comment Then
			Return;
		EndIf;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Separator";
		NewRow.Presentation = NStr("vi = 'Tham số mã vạch';
									|ru = 'Параметры штрихкода';
									|en = 'Barcode settings'; fa = 'Barcode settings';
									|it = 'Parametri del codice a barre';
									|pl = 'Parametry kodu kreskowego';
									|tr = 'Barkod parametreleri'");
		NewRow.Value = NStr("vi = 'Ký tự tách';
							|ru = 'Разделитель';
							|en = 'Separator'; fa = 'جداکننده';
							|it = 'Разделитель';
							|pl = 'Separator';
							|tr = 'Ayırıcı'");

		If StrFind(SelectedArea1.Name, "Barcode") > 0 Then

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "CodeType";
			NewRow.Presentation = NStr("vi = 'Kiểu mã vạch';
										|ru = 'Тип штрихкода';
										|en = 'Barcode type'; fa = 'نوع بارکد';
										|it = 'Tipo del codice a barre';
										|pl = 'Typ kodu kreskowego';
										|tr = 'Barkod tipi'");
			ListItem = ListCodeType.FindByValue(BarcodeType);
			NewRow.Value = ListItem.Presentation;

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "TextVisible";
			NewRow.Presentation = NStr("vi = 'Hiển thị nội dung';
										|ru = 'Отображать текст';
										|en = 'Display text'; fa = 'نمایش متن';
										|it = 'Visualizza il testo';
										|pl = 'Wyświetlać tekst';
										|tr = 'Metin yansıt'");
			NewRow.Value = TextVisible;

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "FontSize";
			NewRow.Presentation = NStr("vi = 'Cỡ chữ';
										|ru = 'Размер шрифта';
										|en = 'Font size'; fa = 'اندازه فونت';
										|it = 'Dimensione del font';
										|pl = 'Rozmiar czcionki';
										|tr = 'Yazı boyutu'");
			NewRow.Value = FontSize;
			NewRow.ReadOnly = Not TextVisible;

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "MonochromeFont";
			NewRow.Presentation = NStr("vi = 'Kiểu chữ';
										|ru = 'Тип шрифта';
										|en = 'Font type'; fa = 'Font type';
										|it = 'Tipo del font';
										|pl = 'Typ czcionki';
										|tr = 'Yazı tipi'");
			NewRow.ReadOnly = Not TextVisible;
			ListItem = ListMonochromeFont.FindByValue(MonochromeFont);
			NewRow.Value = ListItem.Presentation;

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "DetailLevel";
			NewRow.Presentation = NStr("vi = 'Mức độ rõ ràng';
										|ru = 'Уровень четкости';
										|en = 'Detail level'; fa = 'سطح جزئیات';
										|it = 'Livello di chiarezza';
										|pl = 'Poziom dokładności';
										|tr = 'Netlik düzeyi'");
			ListItem = DetailLevelList.FindByValue(DetailLevel);
			NewRow.Value = ListItem.Presentation;

			If CodeType = 17 Then

				NewRow = CellProperties.Add();
				NewRow.PropertyName = "GS1DatabarRowCount";
				NewRow.Presentation = NStr("vi = 'Số lượng dòng';
											|ru = 'Количество строк';
											|en = 'Line quantity'; fa = 'تعداد سطر';
											|it = 'Numero di righe';
											|pl = 'Ilość wierszy';
											|tr = 'Satır sayısı'");
				ListItem = ListGS1DatabarNumberOfRows.FindByValue(GS1DatabarRowCount);
				NewRow.Value = ListItem.Presentation;

			EndIf;

			If CodeType = 17 Or CodeType = 6 Or CodeType = 18 Or CodeType = 24 Then

				NewRow = CellProperties.Add();
				NewRow.PropertyName = "VerticalAlignment";
				NewRow.Presentation = NStr("vi = 'Căn dọc';
											|ru = 'Вертикальное выравнивание';
											|en = 'Vertical alignment'; fa = 'تراز عمودی';
											|it = 'Allineamento verticale';
											|pl = 'Pionowe wyrównanie';
											|tr = 'Dikey hizalama'");
				ListItem = ListVerticalAlignment.FindByValue(VerticalAlignment);
				NewRow.Value = ListItem.Presentation;

			EndIf;

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "CanvasRotation";
			NewRow.Presentation = NStr("vi = 'Góc xoay';
										|ru = 'Угол поворота';
										|en = 'Sweep angle'; fa = 'زاویه چرخش';
										|it = 'Angolo di rotazione';
										|pl = 'Kąt obrotu';
										|tr = 'Dönüş açısı'");
			ListItem = ListSweepAngle.FindByValue(CanvasRotation);
			NewRow.Value = ListItem.Presentation;

			If Not Zoomable Then
				ZoomOption = "RealSize";
			ElsIf Zoomable And MaintainAspectRatio Then
				ZoomOption = "ScaleMaintainProportions";
			Else
				ZoomOption = "ScaleNotKeepProportions";
			EndIf;

			NewRow = CellProperties.Add();
			NewRow.PropertyName = "ZoomOption";
			NewRow.Presentation = NStr("vi = 'Tỷ lệ';
										|ru = 'Масштабирование';
										|en = 'Scaling'; fa = 'Scaling';
										|it = 'Ridimensionamento';
										|pl = 'Scaling';
										|tr = 'Ölçekleme'");
			ListItem = TheListOptionZooming.FindByValue(ZoomOption);
			NewRow.Value = ListItem.Presentation;

		EndIf;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Name";
		NewRow.Presentation = NStr("vi = 'Tên';
									|ru = 'Имя';
									|en = 'Name'; fa = 'نام';
									|it = 'Nome';
									|pl = 'Name';
									|tr = 'Ad'");
		NewRow.Value = SelectedArea1.Name;

#If Not WebClient Then
		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Height";
		NewRow.Presentation = NStr("vi = 'Chiều cao';
									|ru = 'Высота';
									|en = 'Height'; fa = 'ارتفاع';
									|it = 'Altezza';
									|pl = 'Height';
									|tr = 'Yükseklik'");
		NewRow.Value = SelectedArea1.Height;

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Width";
		NewRow.Presentation = NStr("vi = 'Chiều rộng';
									|ru = 'Ширина';
									|en = 'Width'; fa = 'عرض';
									|it = 'Larghezza';
									|pl = 'Width';
									|tr = 'Genişlik'");
		NewRow.Value = SelectedArea1.Width;
#EndIf

		NewRow = CellProperties.Add();
		NewRow.PropertyName = "Line";
		NewRow.Presentation = NStr("vi = 'Đường thẳng';
									|ru = 'Линия';
									|en = 'Line'; fa = 'راهرو';
									|it = 'Linea';
									|pl = 'Line';
									|tr = 'Hat'");
		NewRow.Value = LinePresentation_(SelectedArea1.Line);

	EndIf;

EndProcedure

&AtClient
Procedure TableDocumentFieldWhenTheAreaIsActivated(Item)

	AttachIdleHandler("FillInPropertiesTable", 0.1, True);

EndProcedure

&AtClient
Procedure SetUpLine(SelectedArea1, CurrentData)

	FormParameters = New Structure;
	FormParameters.Insert("LineType", SelectedArea1[CurrentData.PropertyName].LineType);
	FormParameters.Insert("Width", SelectedArea1[CurrentData.PropertyName].Width);
	
	AddlParameters = New Structure("SelectedArea1, CurrentData", SelectedArea1, CurrentData);
	CallbackDescription = New CallbackDescription("SetUpLineCompletion", ThisObject, AddlParameters);
	OpenForm("Catalog.LabelAndPriceTagTemplates.Form.LineTypeChoiceForm", FormParameters, , , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SetUpLineCompletion(Result, AdditionalParameters) Export

	SelectedArea1 = AdditionalParameters.SelectedArea1;
	CurrentData = AdditionalParameters.CurrentData;

	If Result <> Undefined Then

		SelectedArea1[CurrentData.PropertyName] = New Line(Result.LineType, Result.Width);
		FillInPropertiesTable();

	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function CurPageSize(Form)

	ActualSize = "TopMargin:" + Form.SpreadsheetDocumentField.TopMargin
		+ "BottomMargin:" + Form.SpreadsheetDocumentField.BottomMargin + "LeftMargin:"
		+ Form.SpreadsheetDocumentField.LeftMargin + "RightMargin:"
		+ Form.SpreadsheetDocumentField.RightMargin + "Size:"
		+ PageSize(Form.SpreadsheetDocumentField);

	Return ActualSize;

EndFunction

&AtClient
Procedure UpdatePlacement()

	ActualSize = CurPageSize(ThisForm);

	If ActualSize <> PageSize Then
		PageSize = ActualSize;
		CalculateMaximumNumberPerPage();
	EndIf;

EndProcedure

&AtClient
Procedure SubstituteTemplateField(Area, RowSelected)

// Before you start adding, you need to select an area in a tabular document.
	If TypeOf(Area) <> Type("SpreadsheetDocumentRange") Then
		MessageText = NStr("vi = 'Để chuyển trường khuôn mẫu, cần chọn ô hoặc vùng chứa ô';
							|ru = 'Для переноса поля шаблона нужно выделить ячейку или область ячеек';
							|en = 'To transfer the template field, it is required to select a cell or cells area.'; fa = 'To transfer the template field, it is required to select a cell or cells area.';
							|it = 'Per trasferire il campo di un modello bisogna selezionare una cella o una regione di celle';
							|pl = 'Aby przenieść pole szablonu, należy zaznaczyć komórkę lub obszar komórek';
							|tr = 'Bir numune alanını aktarmak için hücre veya hücre alanının seçilmesi gerekir.'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	Else
		CurrentArea = Area;
		MergeArea(CurrentArea.Name);
	EndIf;

	// Data preparation.
	CurrentData = DataCompositionAvailableFields.FindByID(RowSelected);
	NameOfFieldInTemplate = CurrentData.FullRowID;

	// Placement of the field in the template.
	If NameOfFieldInTemplate = NameOfBarcodeParameter()
			Or NameOfFieldInTemplate = ParameterNameExciseStampCode() Then

		QueryText = NStr("vi = 'Thêm mã vạch như hình?';
						|ru = 'Добавить штрихкод, как картинку?';
						|en = 'Add a barcode as an image?'; fa = 'Add a barcode as an image?';
						|it = 'Aggiungere un codice a barre come immagine?';
						|pl = 'Dodać kod kreskowy jako obraz?';
						|tr = 'Resim gibi barkod eklensin mi?'");
		AdditionalData = New Structure("NameOfFieldInTemplate, CurrentArea", NameOfFieldInTemplate, CurrentArea);
		CallbackDescription = New CallbackDescription("SubstituteTemplateFieldCompletion", ThisObject, AdditionalData);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

	ElsIf NameOfFieldInTemplate = NameOfPriceCurrencyParameter() Then

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Dấu hiệu tiền tệ';
												|ru = 'Знак валюты';
												|en = 'Currency sign'; fa = 'Currency sign';
												|it = 'Simbolo della valuta';
												|pl = 'Znak waluty';
												|tr = 'Para birimleri işareti'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Nội dung';
												|ru = 'Текст';
												|en = 'Text'; fa = 'متن';
												|it = 'Testo';
												|pl = 'Text';
												|tr = 'Metin'"));

		QueryText = NStr("vi = 'Thêm tiền tệ như là...';
						|ru = 'Добавить валюту как...';
						|en = 'Add currency as ...'; fa = 'Add currency as ...';
						|it = 'Aggiungere la valuta come...';
						|pl = 'Dodaj walutę jako...';
						|tr = 'Para birimi olarak ekle...'");
		AdditionalParameters = New Structure("NameOfFieldInTemplate, CurrentArea", NameOfFieldInTemplate, CurrentArea);
		CallbackDescription = New CallbackDescription("SubstituteTemplateFieldCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);

	Else

		CurrentArea.FillType = SpreadsheetDocumentAreaFillType.Template;
		CurrentArea.Text = CurrentArea.Text + "[" + NameOfFieldInTemplate + "]";

	EndIf;

EndProcedure

&AtClient
Procedure SubstituteTemplateFieldCompletion(QuestionResult,
		AdditionalParameters) Export

	NameOfFieldInTemplate = AdditionalParameters.NameOfFieldInTemplate;
	CurrentArea = AdditionalParameters.CurrentArea;

	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then

		If NameOfFieldInTemplate = NameOfBarcodeParameter()
				Or NameOfFieldInTemplate = ParameterNameExciseStampCode() Then
			InsertBarcodeDrawing(CurrentArea.Name);
		ElsIf NameOfFieldInTemplate = NameOfPriceCurrencyParameter() Then
			InsertFigureCurrencySign(CurrentArea.Name);
		EndIf;

	Else

		CurrentArea.FillType = SpreadsheetDocumentAreaFillType.Template;
		CurrentArea.Text = CurrentArea.Text + "[" + NameOfFieldInTemplate + "]";

	EndIf;

EndProcedure

&AtClient
Procedure SelectingAvailableField(RowSelected)

	SubstituteTemplateField(SpreadsheetDocumentField.CurrentArea, RowSelected);

EndProcedure

&AtServerNoContext
Procedure AssignPackingListLabelTemplate(Template)

	Constants.PackingListLabelTemplate.Set(Template);

EndProcedure

#EndRegion

#EndRegion
