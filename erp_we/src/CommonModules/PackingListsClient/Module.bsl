 
#Region Public

// Updates the cache of key details of the current product line.
//
// Parameters:
//  FormTable			 - FormTable - form table that displays the PM of products,
//  CachedValues	 - Structure - form module variable that stores the service cache,
//  SeriesSpecificationParameters	 - See ProductsClientServer.SeriesSpecificationParameters
//  Copy				 - Boolean - indicates that the cached string has been copied (parameter of the event at the start of Editing).
//
Procedure UpdateCachedValuesForPCHSWithPackingLists(FormTable, CachedValues,
	SeriesSpecificationParameters = Undefined,Copy = False) Export
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	CachedValues.Insert("AddingLines", False);
	CachedValues.Insert("EditingLines", False);
	CachedValues.Insert("PackingList", PredefinedValue("Document.PackingList.EmptyRef"));
	CachedValues.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	CachedValues.Insert("ThisIsAPackingList", False);
	CachedValues.Insert("DeletingRows", False);
	
	CurrentData = FormTable.CurrentData;
	
	If CurrentData <> Undefined Then
		FillPropertyValues(CachedValues, CurrentData);
	EndIf;
	
	If SeriesSpecificationParameters <> Undefined Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			FormTable,CachedValues,SeriesSpecificationParameters, Copy);
	EndIf;
	
EndProcedure

// Actions when you start editing the table part with packing lists.
// Parameters:
//		Form - ClientApplicationForm - form for performing actions,
//		CachedValues - Structure - the data in this structure is updated by the current row,
//		NewRow - Boolean - indicates whether to add a new line.
//
Procedure AtBeginningOfEditingPMWithPackingLists(Form, CachedValues, NewRow) Export
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	
	CurrentData = Form.Items[NameTSGoods].CurrentData;
	
	If NewRow Then
		Form.MaximumLineNumber = Form.MaximumLineNumber + 1;
		CurrentData.LineNumberDisplayed = Form.MaximumLineNumber;
		If ValueIsFilled(Form.PackingListParent) Then
			CurrentData.PackingListParent = Form.PackingListParent;
		EndIf;
	EndIf;
	UpdateCachedValuesForPCHSWithPackingLists(Form.Items[NameTSGoods], CachedValues);
	CachedValues.EditingLines = True;
	
EndProcedure

// Actions at the end of editing the table part with packing lists.
// Parameters:
//		Form - ClientApplicationForm - form for performing actions,
//		NewRow - Boolean - flag for adding a new line,
//		CancelEdit - Boolean - indicates whether to cancel editing.
//
Procedure AtEndOfEditingPMWithPackingLists(Form, NewRow, CancelEdit) Export
	
	If NewRow
		And CancelEdit Then
		Form.MaximumLineNumber = Form.MaximumLineNumber - 1;
	EndIf;
	
EndProcedure

// Actions before you start adding a row to the table part with packing lists.
//	Parameters:
//		FormTable - FormDataCollection - a table that can contain packing list rows,
//		Cancel - Boolean - sign of an adding error,
//		Copy - Boolean - whether to copy a string,
//		CachedValues - Structure - service data.
//
Procedure BeforeYouStartAddingVTCHSPackingLists(FormTable, Cancel, Copy, CachedValues) Export
	
	UpdateCachedValuesForPCHSWithPackingLists(FormTable, CachedValues);
	CurrentData = FormTable.CurrentData;
	If Copy
		And CurrentData <> Undefined
		And CurrentData.ThisIsAPackingList Then
		Cancel = True;
		ShowMessageBox(,NStr("vi = 'Không thể sao chép các dòng có phiếu đóng gói';
							|ru = 'Копирование строк с упаковочными листами не предусмотрено';
							|en = 'Copying lines with packing lists is not available'; fa = 'Copying lines with packing lists is not available';
							|it = 'Non è prevista la copiatura di righe con la distinta di imballaggio';
							|pl = 'Kopiowanie wierszy z arkuszami opakowań nie jest przewidziane';
							|tr = 'Ürün listesi satırlarının kopyalanması öngörülmedi'"));
	EndIf;
	
	CachedValues.AddingLines = True;
	
EndProcedure

// Converts the current packing list line to the lines contained within the packing list,
//	and the original packing list line is deleted.
//	Parameters:
//		Form - ClientApplicationForm - a form that contains a table with packing lists.
//
Procedure UnpackPackingList(Form) Export
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	
	CurrentData = Form.Items[NameTSGoods].CurrentData;
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Chọn dòng để giải nén.';
							|ru = 'Выберите строку для распаковки.';
							|en = 'Select a line to unpack.'; fa = 'Select a line to unpack.';
							|it = 'Selezionare riga per il dismballaggio.';
							|pl = 'Wybierz wiersz do rozpakowania.';
							|tr = 'Paketten çıkarmak için satırı seç.'");
		ShowMessageBox(,WarningText);
		Return;
	ElsIf Not ValueIsFilled(CurrentData.PackingListParent)
		And Not ValueIsFilled(CurrentData.PackingList) Then
		WarningText = NStr("vi = 'Dòng đã chọn không được bao gồm trong danh sách đóng gói, không thể giải nén.';
							|ru = 'Выбранная строка не включена в упаковочный лист, распаковка невозможна.';
							|en = 'The selected line is not included in the packing list; unable to unpack.'; fa = 'The selected line is not included in the packing list; unable to unpack.';
							|it = 'La riga selezionata non è inclusa nella distinta di imballaggio, impossibile disimballare.';
							|pl = 'Wybrany wiersz nie jest włączony do arkuszu opakowań, rozpakowanie niemożliwe.';
							|tr = 'Seçilen satır ürün listesine dahil edilmemiştir, paketten çıkarmak mümkün değildir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Giải nén?';
					|ru = 'Распаковать?';
					|en = 'Unpack?'; fa = 'Unpack?';
					|it = 'Disimballare?';
					|pl = 'Rozpakować?';
					|tr = 'Paketten çıkar?'");
	Notification = New CallbackDescription("AfterClosingUnboxingQuestion", Form);
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Checks whether it is possible to switch to packaging from the current line.
//	Parameters:
//		FormTable - FormDataCollection - a table that can contain packing list rows,
//		FieldName - String - name of the current field,
//		TSName - String - name of the table part with packing lists
//	Returns:
//		Boolean - True, if the transition to the packing list is possible.
//	
Function CheckPrepareTransitionToPackingListWhenSelecting(FormTable, FieldName, TSName = "Goods") Export
	
	CurrentData = FormTable.CurrentData;
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	If (FieldName = TSName + "Picture"
		Or FieldName = TSName + "LineNumberDisplayed")
	  And CurrentData.ThisIsAPackingList
	  And ValueIsFilled(CurrentData.PackingList) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Actions before deleting rows in the table part with packing lists.
//
// Parameters:
//  FormTable			 - FormDataCollection - a table that can contain packing list rows,
//  CachedValues	 - Structure - service data cache,
//  SeriesSpecificationParameters	 - See ProductsClientServer.SeriesSpecificationParameters
//
Procedure BeforeDeletingPMLinesWithPackingSheets(FormTable, CachedValues, SeriesSpecificationParameters) Export
	
	UpdateCachedValuesForPCHSWithPackingLists(FormTable, CachedValues, SeriesSpecificationParameters);
	CachedValues.DeletingRows = True;
	
EndProcedure

// Actions when you start selecting a value in a field that can be either an item or a packing list.
//	Parameters:
//		Form - ClientApplicationForm - a form that has a table with packing lists,
//		Item - FormField - field where the selection is made,
//		StandardProcessing - Boolean - indicates whether standard processing is being performed,
//		GoodsViewMode - Boolean - indicates the current mode for viewing
//			the table with packing lists (by product or product locations).
//	
Procedure StartOfProductPlaceSelection(Form, Item, StandardProcessing, GoodsViewMode = False) Export
	
	If Not Form.UsePackingLists Then
		Return;
	EndIf;
	
	If GoodsViewMode Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	NameTSGoods = SeriesSpecificationParameters(Form).NameTSGoods;
	CurrentData = Form.Items[NameTSGoods].CurrentData;
	
	List = New ValueList;
	ProductPresentation = NStr("vi = 'Mặt hàng';
								|ru = 'Номенклатура';
								|en = 'Items'; fa = 'اقلام';
								|it = 'Articolo';
								|pl = 'Pozycja';
								|tr = 'Öğe'");
	PresentationOfPackingList = NStr("vi = 'Danh sách đóng gói';
									|ru = 'Упаковочный лист';
									|en = 'Packing list'; fa = 'فهرست بسته‌بندی';
									|it = 'Distinta di imballaggio';
									|pl = 'Specyfikacja ładunkowa';
									|tr = 'Ürün listesi'");
	List.Add(ProductPresentation);
	List.Add(PresentationOfPackingList);
	AdditionalParameters = New Structure("Form", Form);
	OnCloseNotifyDescription = New CallbackDescription("AfterSelectingTypeOfGoodsPlace", ThisObject, AdditionalParameters);
	Form.ShowChooseFromList(OnCloseNotifyDescription, List, Item);
	
EndProcedure

// Break Up the TS string with packing lists.
//  Handler of the "Split line" command for a line in which a packing list can be specified. 
// Parameters:
//	TS - FormDataCollection - the table part with the processed row.
//	FormData1 - FormTable - a form element with the string being processed.
//	NotificationAfterSplitting - CallbackDescription - an alert that is triggered after a split attempt.
//	StringSplittingParameters - See ProcessingOfTabularFormsClient.StringSplittingParameters.
Procedure BreakUpPMStringWithPackingLists(TS, FormData1, NotificationAfterSplitting, StringSplittingParameters = Undefined) Export
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormData1) Then
		RunCallback(NotificationAfterSplitting, Undefined);
	ElsIf FormData1.CurrentData.ThisIsAPackingList Then
		MessageText = NStr("vi = 'Không thể tách dòng có phiếu đóng gói.';
							|ru = 'Невозможно разбить строку с упаковочным листом.';
							|en = 'Cannot break the line with packing list.'; fa = 'Cannot break the line with packing list.';
							|it = 'Non è possibile dividere la riga con la distinta di imballaggio';
							|pl = 'Nie można podzielić wiersz z arkuszem opakowań.';
							|tr = 'Ürün listesi satırını bölmek mümkün değildir.'");
		ShowMessageBox(,MessageText);
		RunCallback(NotificationAfterSplitting, Undefined);
	Else
		ProcessingOfTabularFormsClient.SplitRow(TS, FormData1, NotificationAfterSplitting, StringSplittingParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region GeneralProceduresAndFunctionsForHandlingPackingLists

Function SeriesSpecificationParameters(Form)
	
	If Form.SeriesSpecificationParameters.Property("ShippedGoods") Then
		Return Form.SeriesSpecificationParameters.ShippedGoods;
	Else
		Return Form.SeriesSpecificationParameters;
	EndIf;	
	
EndFunction

// Parameters:
// Result - ValueListItem
// AdditionalParameters - Structure - Where:
// * Form - ClientApplicationForm
// 
Procedure AfterSelectingTypeOfGoodsPlace(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	NameTSGoods = SeriesSpecificationParameters(AdditionalParameters.Form).NameTSGoods;
	CurrentData = AdditionalParameters.Form.Items[NameTSGoods].CurrentData;
	
	ProductPresentation      = NStr("vi = 'Mặt hàng';
									|ru = 'Номенклатура';
									|en = 'Items'; fa = 'اقلام';
									|it = 'Articolo';
									|pl = 'Pozycja';
									|tr = 'Öğe'");
	PresentationOfPackingList = NStr("vi = 'Danh sách đóng gói';
									|ru = 'Упаковочный лист';
									|en = 'Packing list'; fa = 'فهرست بسته‌بندی';
									|it = 'Distinta di imballaggio';
									|pl = 'Specyfikacja ładunkowa';
									|tr = 'Ürün listesi'");
	
	If Result.Value = ProductPresentation Then
		FormParameters = New Structure;
		FIlter_By_Type = New Array;
		FIlter_By_Type.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		FIlter_By_Type.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		FormParameters.Insert("Filter", New Structure("ItemsType", FIlter_By_Type));
		OpenForm("Catalog.Products.Form.ChoiceForm", FormParameters, AdditionalParameters.Form);
	ElsIf Result.Value = PresentationOfPackingList Then
		Filter = New Structure("Posted", True);
		FormParameters = New Structure("Filter, Barcode", Filter, "");
		FillPropertyValues(FormParameters, CurrentData);
		OpenForm("Document.PackingList.Form.ChoiceForm", FormParameters, AdditionalParameters.Form);
	EndIf;
EndProcedure

#EndRegion

#EndRegion




