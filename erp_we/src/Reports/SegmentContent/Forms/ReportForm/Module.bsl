
#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then 
		Parameters.Segment = Parameters.CommandParameter;
	EndIf;
	
	Segment = Parameters.Segment;
	
	If Not ValueIsFilled(Segment) Then
		Raise NStr("vi = 'Báo cáo không được dùng để sử dụng không theo ngữ cảnh. Hãy mở báo cáo từ biểu mẫu danh sách hoặc phần tử trong phân khúc.';
					|ru = 'Отчет не предназначен для неконтекстного использования. Открывайте отчет из формы списка или элемента сегмента.';
					|en = 'The report is not for non-context use. Open the report from the list form or the segment item.'; fa = 'The report is not for non-context use. Open the report from the list form or the segment item.';
					|it = 'Il report non è inteso per l''utilizzo non contestuale. Aprire report dal modulo dell''elenco o dell''elemento del segmento.';
					|pl = 'Raport nie jest przeznaczony dla użycia poza kontekstem. Otwieraj raport z formularza listy lub elementu segmentu.';
					|tr = 'Rapor bağlamsal kullanım için tasarlanmamıştır. Raporu liste formundan veya segment öğesinden açın.'");
	EndIf;
	
	SegmentDetails = Common.ObjectAttributesValues(Segment, "GenerationMethod, IsFolder");
	
	If SegmentDetails.IsFolder Then
		Raise NStr("vi = 'Không thể lập báo cáo đối với nhóm phân khúc.';
					|ru = 'Отчет не может быть сформирован для группы сегментов.';
					|en = 'Report cannot be generated for the segment group.'; fa = 'Report cannot be generated for the segment group.';
					|it = 'Il report non può essere generato per il gruppo di segmenti.';
					|pl = 'Raport nie może zostać wygenerowany dla grupy segmentów.';
					|tr = 'Segment grubu için rapor oluşturulamaz.'");
	EndIf;
	
	Partners = (
		TypeOf(Segment) = Type("CatalogRef.PartnersSegments"));
	ItemsCharacteristics =
		GetFunctionalOption("UseItemVariants");
	
	Items.AddToSegment.Visible = (
		SegmentDetails.GenerationMethod =
		Enums.SegmentGenerationMethods.GenerateManually);
	Items.RemoveFromTheSegment.Visible = Items.AddToSegment.Visible;
	Items.AddToTheSegmentByFilter.Visible = Items.AddToSegment.Visible And Not Partners;
	Items.GenerateSegment.Visible = (
		SegmentDetails.GenerationMethod <>
		Enums.SegmentGenerationMethods.GenerateDynamically);
	
	Report.SettingsComposer.FixedSettings.AdditionalProperties.Insert(
		"Segment", Segment);
	
	If Partners Then
		EditRight = AccessRight("Update", Metadata.InformationRegisters.SegmentPartners);
	Else
		EditRight = AccessRight("Update", Metadata.InformationRegisters.SegmentProducts);
	EndIf;
	
	Items.GroupSegmentChange.Enabled = EditRight;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)

	If TypeOf(Details) <> Type("DataCompositionDetailsID") Then
		Return;
	EndIf;

	StandardProcessing = False;
	Item = ElementDecryptionValue(Details);
	If ValueIsFilled(Item) Then
		ShowValue(Undefined, Item);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddToSegment(Command)
	
	ClearMessages();

	If Partners Then
		Item = Undefined;

		OpenForm("Catalog.Partners.ChoiceForm",New Structure("MultipleChoice",True),,,,, New CallbackDescription("AddToSegmentAfterSelection", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	ElsIf ItemsCharacteristics Then
		OpenForm("Report.SegmentContent.Form.SelectItems",,,,,, New CallbackDescription("AddToSegmentAfterCompositionSelection", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	Else
		ProductSelectionFormParameters = New Structure;
		ProductSelectionFormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
		
		SelectionResult = Undefined;
		
		OpenForm("Catalog.Products.ChoiceForm",ProductSelectionFormParameters,,,,, New CallbackDescription("AddToSegmentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	AddFragmentToSegment(Item);
	
EndProcedure

&AtClient
Procedure AddToSegmentAfterSelection(Result1, AdditionalParameters) Export
    
    Item = Result1;
    
    AddFragmentToSegment(Item);

EndProcedure

&AtClient
Procedure AddToSegmentAfterCompositionSelection(Result1, AdditionalParameters) Export
    
    Item = Result1;
    If TypeOf(Item) <> Type("Structure") Then
        Return;
    EndIf;
    
    AddFragmentToSegment(Item);

EndProcedure

&AtClient
Procedure AddToSegmentCompletion(Result1, AdditionalParameters) Export
    
    SelectionResult = Result1;
    Item = ?(SelectionResult = Undefined,Undefined,New Structure("Products",SelectionResult));
    
    AddFragmentToSegment(Item);

EndProcedure

&AtClient
Procedure AddFragmentToSegment(Val Item)
    
    If ValueIsFilled(Item) Then
        AddItem(Item,True,True);
    EndIf;

EndProcedure

&AtClient
Procedure RemoveFromTheSegment(Command)
	
	ClearMessages();
	
	ArrayOfDecryptions = New Array();
	Areas = Result.SelectedAreas;
	
	For Each Area In Areas Do
		
		If Area.Top = 0 Then
			ClearSegment();
			Return;
		Else
			
			For String = Area.Top To Area.Bottom Do
				For Column5 = 1 To 200 Do
					Try
						Details = Result.Area("R" + Format(String, "NG=0") + "C" + Column5).Details;
						If TypeOf(Details) = Type("DataCompositionDetailsID") Then
							ArrayOfDecryptions.Add(Details);
							Break;
						EndIf;
					Except
						Continue;
					EndTry
				EndDo;
			EndDo;
			
			If ArrayOfDecryptions.Count() = 0 Then
				CommonClient.MessageToUser(NStr("vi = 'Chưa chọn một phần tử nào để xóa.';
												|ru = 'Не выбран ни один элемент для удаления.';
												|en = 'No item for deletion is selected.'; fa = 'No item for deletion is selected.';
												|it = 'Nessun elemento per l''eliminazione selezionato.';
												|pl = 'Nie wybrano żadnego elementu do usunięcia.';
												|tr = 'Silmek için herhangi bir öğe seçilmedi.'"),,"Result");
			Else
				DeleteItems(ArrayOfDecryptions);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearSegment()

	SegmentsOfCallServer.Clear(Segment);
	ComposeResult();

EndProcedure

&AtClient
Procedure GenerateSegment(Command)

	CompletionHandler = New CallbackDescription( "WhenAnsweringQuestionCreatingSegment", ThisObject);
	ShowQueryBox(CompletionHandler,
	               NStr("vi = 'Thành phần của phân khúc sẽ được tạo lại theo tùy chỉnh sơ đồ dàn dựng. Tiếp tục?';
						|ru = 'Состав сегмента будет переформирован в соответствии с настройками схемы компоновки. Продолжить?';
						|en = 'Segment content will be rebuilt according to composition schema settings. Continue?'; fa = 'Segment content will be rebuilt according to composition schema settings. Continue?';
						|it = 'I componenti del segmento verranno riorganizzati in base alle impostazioni dello schema di layout. Continuare?';
						|pl = 'Skład segmentu zostanie zreorganizowany zgodnie z ustawieniami schematu układu. Kontynuować?';
						|tr = 'Segment içeriği, inşa şeması ayarlarına göre yeniden oluşturulacaktır. Devam edilsin mi?'"),
	               QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AddToTheSegmentByFilter(Command)
	
	PickFormHeader = NStr("vi = 'Chọn mặt hàng vào phân khúc';
							|ru = 'Подбор номенклатуры в сегмент';
							|en = 'Pick items in segment'; fa = 'Pick items in segment';
							|it = 'Selezionare gli articoli nel segmento';
							|pl = 'Wybór nomenklatury w segmencie';
							|tr = 'Segmentte öğe seçimi'");
	TitleOfTransferSelectionFormButton = NStr("vi = 'Chuyển vào phân khúc';
												|ru = 'Перенести в сегмент';
												|en = 'Move to segment'; fa = 'Move to segment';
												|it = 'Spostare nel segmento';
												|pl = 'Przenieś do selekcji';
												|tr = 'Segmente taşı'");
	
	AddressInTempStorage = Undefined;

	
	OpenForm(
		"DataProcessor.GoodsSelectionByPicking.Form.Form",
		New Structure("Title,TransferButtonTitle, UUID",PickFormHeader, TitleOfTransferSelectionFormButton, UUID),
		ThisForm,,,, New CallbackDescription("AddToTheSegmentByFilterCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddToTheSegmentByFilterCompletion(Result1, AdditionalParameters) Export
    
    AddressInTempStorage = Result1;
    If ValueIsFilled(AddressInTempStorage) Then
        AddSelectionProductsOnServer(AddressInTempStorage);
    EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WhenAnsweringQuestionCreatingSegment(ReturnCode, AdditionalParameters) Export
	
	If ReturnCode = DialogReturnCode.Yes Then
		
		GenerateSegmentServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteItems(Decryptions)
	
	ReportDetailsData = GetFromTempStorage(DetailsData); // Structure
	
	For Each Details In Decryptions Do
		DetailsItem = ReportDetailsData.Items[Details];
		For Each DecryptionFieldValue In DetailsItem.GetFields() Do
			Value = DecryptionFieldValue.Value;
			If Partners Then
				If TypeOf(Value) = Type("CatalogRef.Partners") Then
					RecordSet = InformationRegisters.SegmentPartners.CreateRecordSet();
					RecordSet.Filter.Segment.Set(Segment);
					RecordSet.Filter.Partner.Set(Value);
					RecordSet.Write();
				EndIf;
			Else 
				If TypeOf(Value) = Type("CatalogRef.Products") Then
					RecordSet = InformationRegisters.SegmentProducts.CreateRecordSet();
					RecordSet.Filter.Segment.Set(Segment);
					RecordSet.Filter.Products.Set(Value);
					Try
						MeaningOfFollowingDecryption = ReportDetailsData.Items[Details+1].GetFields()[0].Value;
						If TypeOf(MeaningOfFollowingDecryption) = Type("CatalogRef.ItemsCharacteristics") Then
							RecordSet.Filter.Characteristic.Set(MeaningOfFollowingDecryption);
						Else
							RecordSet.Filter.Characteristic.Set(Catalogs.ItemsCharacteristics.EmptyRef());
						EndIf;
					Except
						Continue;
					EndTry;
					RecordSet.Write();
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	ComposeResult();
	
EndProcedure

// Adds a data layout element
// 
// Parameters:
//  Item - Structure - Contains:
//   * Description - String - 
// 	ComposeResult - Boolean - indicates whether the result should be compiled.
// 	OutputMessages - Boolean - indicates whether user messages should be displayed.
//
&AtServer
Procedure AddItem(Item, ComposeResult = False, OutputMessages = False)
	
	If TypeOf(Item) = Type("Array") Then
		For Each ArrayElement In Item Do
			AddItem(ArrayElement,ComposeResult,OutputMessages);
		EndDo;
		Return;
	EndIf;
	
	If Partners Then
		If Item.IsEmpty() Then
			Return;
		EndIf;
	Else
		If Item.Products.IsEmpty() Then
			Return;
		EndIf;
	EndIf;
	
	If Partners Then
		Record = InformationRegisters.SegmentPartners.CreateRecordManager();
		Record.Segment = Segment;
		Record.Partner = Item;
	Else
		Record = InformationRegisters.SegmentProducts.CreateRecordManager();
		Record.Segment = Segment;
		If ItemsCharacteristics Then
			Record.Products = Item.Products;
			If ValueIsFilled(Item.Characteristic) Then
				Record.Characteristic = Item.Characteristic;
			EndIf;
		Else
			Record.Products = Item.Products;
		EndIf;
	EndIf;
	
	Record.Read();
	
	If Record.Selected() Then
		If OutputMessages Then
			If Partners Then
				CommonClientServer.MessageToUser(Item.Description + " " + NStr("vi = 'đã có trong phân khúc.';
																				|ru = 'уже включен в сегмент.';
																				|en = 'already included in the segment.'; fa = 'already included in the segment.';
																				|it = 'già incluso nel segmento.';
																				|pl = 'już uwzględnione w selekcji.';
																				|tr = 'zaten segmente dahildir.'"))
			Else	
				If ItemsCharacteristics
					And Not Item.Characteristic.IsEmpty() Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1/%2 đã có trong phân khúc';
																								|ru = '%1/%2 уже включен в сегмент';
																								|en = '%1/%2 is already included in the segment'; fa = '%1/%2 is already included in the segment';
																								|it = '%1/%2 già incluso nel segmento';
																								|pl = '%1/%2 jest już dodany do segmentu';
																								|tr = '%1/%2 zaten segmente dahildir'"), 
					                                                                         String(Item.Products),
					                                                                         String(Item.Characteristic)); 
				Else
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 đã có trong phân khúc';
																								|ru = '%1 уже включен в сегмент';
																								|en = '%1 is already included in the segment'; fa = '%1 is already included in the segment';
																								|it = '%1 già incluso nel segmento';
																								|pl = '%1 jest już dodany do segmentu';
																								|tr = '%1 zaten segmente dahildir'"), 
					                                                                         String(Item.Products)); 
				EndIf;
				Common.MessageToUser(MessageText,, "Result");
			EndIf;
		EndIf;
	Else
		
		Record.Segment = Segment;
		If Partners Then
			Record.Partner = Item;
		Else
			If ItemsCharacteristics Then
				Record.Products = Item.Products;
				If ValueIsFilled(Item.Characteristic) Then
					Record.Characteristic = Item.Characteristic;
				EndIf;
			Else
				Record.Products = Item.Products;
			EndIf;
		EndIf;
		Record.Write();
		If ComposeResult Then
			ComposeResult();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ElementDecryptionValue(Details)

	ReportDetailsData = GetFromTempStorage(DetailsData); // DataCompositionDetailsData
	DetailsItem = ReportDetailsData.Items[Details]; 

	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each DecryptionFieldValue In DetailsItem.GetFields() Do
			Value = DecryptionFieldValue.Value;
			If Catalogs.AllRefsType().ContainsType(TypeOf(Value))
			 Or Documents.AllRefsType().ContainsType(TypeOf(Value)) Then
				Return Value;
			EndIf;
		EndDo;
	EndIf;

	Return Undefined;

EndFunction

&AtServer
Procedure AddSelectionProductsOnServer(AddressInTempStorage);

	TableOfProducts = GetFromTempStorage(AddressInTempStorage);
	
	For Each TableRow In TableOfProducts Do
		AddItem(TableRow);
	EndDo;

	ComposeResult();
	
EndProcedure

&AtServer
Procedure GenerateSegmentServer()

	SegmentsOfCallServer.Generate(Segment);
	ComposeResult();

EndProcedure

#EndRegion
