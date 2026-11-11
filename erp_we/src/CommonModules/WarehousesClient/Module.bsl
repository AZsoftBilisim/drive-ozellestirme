
#Region Public

// Processes parameters and opens the low-quality item selection form 
//
// Parameters:
//  CurrentRow					 - LineOfATabularSection - current row of the table part
//  StructureOfActions				 - Structure - structure of actions 
//  CachedValues			 - Structure - cached value
//  NotificationOfSuccessfulExecution	 - CallbackDescription - notification that will be called after closing the low-quality item selection form.
//
Procedure ChangeQuality(CurrentRow,StructureOfActions, CachedValues, NotificationOfSuccessfulExecution = Undefined) Export
	
	If CurrentRow = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn dòng mà bạn muốn thay đổi chất lượng';
								|ru = 'Выберите строку, для которой хотите изменить качество';
								|en = 'Select a line for which you want to change quality'; fa = 'Select a line for which you want to change quality';
								|it = 'Seleziona la riga per la quale si desidera modificare la qualità';
								|pl = 'Wybierz wiersz, dla którego chcesz zmienić jakość.';
								|tr = 'Kalitesini değiştirmek istediğiniz satırı seçin'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentRow.Products) Then
		ClearMessages();
		MessageText = NStr("vi = 'Trong dòng đã chọn chưa chỉ ra hàng hóa có chất lượng gốc.';
							|ru = 'В выбранной строке не указан товар исходного качества.';
							|en = 'Goods of original quality is not specified in the selected line.'; fa = 'Goods of original quality is not specified in the selected line.';
							|it = 'Nella riga selezionata non è indicata la merce di qualità originale.';
							|pl = 'Wybrany wiersz nie zawiera produktu o oryginalnej jakości.';
							|tr = 'Seçilen satırda orijinal kalitedeki ürün belirtilmedi.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert("CachedValues", CachedValues);
	AdditionalParameters.Insert("NotificationOfSuccessfulExecution", NotificationOfSuccessfulExecution);
	AdditionalParameters.Insert("StructureOfActions", StructureOfActions);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	Notification = New CallbackDescription("ChangeQualityCompletion", ThisObject, AdditionalParameters);
	OpenForm("Catalog.Products.Form.ChoiceFormOfLowQualityItems",
		New Structure("Products", CurrentRow.Products),
		,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Takes in the selection/placement tasks, processes the parameters, and opens the take-in settings form.
//
// Parameters:
//  Form							 - ClientApplicationForm - the form that contains the list of tasks for selection/placement
//  List							 - FormTable - the list of tasks for selection/placement
//  Operation						 - String - "Load management", "access Management", or " selection Placement"
//  NotificationOfSuccessfulExecution	 - CallbackDescription - notification that will be triggered after setting the settings.
//
Procedure TakeUpTheJobs(Form, List, Operation, NotificationOfSuccessfulExecution) Export
	ClearMessages();
	
	DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(List);
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	Structure = New Structure;
	Structure.Insert("Warehouse",Form.Warehouse);
	Structure.Insert("Premise",Form.Premise);
	
	ParametersForm = New Structure("Title ,Operation, ParameterObject", Operation, "TakingTasksToWork",Structure);  
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert("DocumentsArray", DocumentsArray);
	AdditionalParameters.Insert("NotificationOfSuccessfulExecution", NotificationOfSuccessfulExecution);
	AdditionalParameters.Insert("List", List);
	AdditionalParameters.Insert("Form", Form);
	
	Notification = New CallbackDescription("TakeUpTheJobsCompletion", ThisObject, AdditionalParameters);
	OpenForm("Document.GoodsPickingPlacement.Form.SettingsForm", 
		ParametersForm, 
		Form,
		,
		,
		,
		Notification, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Marks the selection/placement task as completed without errors
//
// Parameters:
//  Form							 - ClientApplicationForm	- the form that contains the list of tasks for selection/placement 
//  List							 - FormTable - the list of tasks for selection/placement 
//  Operation						 - String - "Load management", "access Management", or " selection Placement"
//  NotificationOfSuccessfulExecution	 - CallbackDescription - notification that will be triggered after setting the settings.
//
Procedure MarkCompletionOfTasksWithoutErrors(Form, List, Operation, NotificationOfSuccessfulExecution) Export
	ClearMessages();
	
	DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(List);
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	Structure = New Structure;
	Structure.Insert("Warehouse", Form.Warehouse);
	Structure.Insert("Premise", Form.Premise);
	
	ParametersForm = New Structure("Title ,Operation,ParameterObject", Operation, "CompletingTasks",Structure);  
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert("DocumentsArray", DocumentsArray);
	AdditionalParameters.Insert("NotificationOfSuccessfulExecution", NotificationOfSuccessfulExecution);
	AdditionalParameters.Insert("List", List);
	AdditionalParameters.Insert("Form", Form);
	
	Notification = New CallbackDescription("MarkCompletionOfTasksWithoutErrorsCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("Document.GoodsPickingPlacement.Form.SettingsForm",
		ParametersForm, 
		Form,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Checks whether the details required to fill in the "Warehouse" details in the table part are filled in.
//
// Parameters:
//		Object- DocumentObject - document in which PM you need to check whether the "Warehouse" column is filled in",
// 		TabularSection - FormDataCollection - table part where you need to perform the check,
// 		TabularSectionPresentation - String - table view for informing the user,
// 		SelectedRows - Array - Array of selected rows in the table part.
//
// Returns:
// 		Boolean - False if the required data is not filled in.
//
Function CheckPossibilityOfFillingWarehousesInTablePart(Object, TabularSection, TabularSectionPresentation, SelectedRows) Export
	
	If Type("DocumentRef.CustomerInvoice") = TypeOf(Object.Ref)
		Or Type("DocumentRef.TransferOfGoodsToBailee") = TypeOf(Object.Ref) Then
		
		If ValueIsFilled(Object.SalesOrder) Then
			WarningText = NStr("vi = 'Đã nhập chứng từ dựa trên đơn hàng của khách. Không thể điền trường ""Kho bãi""';
								|ru = 'Документ введен на основании заказа клиента. Поле ""Склад"" не может быть заполнено';
								|en = 'Document is generated from the sales order. The Warehouse field cannot be filled in'; fa = 'Document is generated from the sales order. The Warehouse field cannot be filled in';
								|it = 'Il documento è stato inserito in base all''ordine del cliente. Il campo ""Magazzino"" non può essere compilato';
								|pl = 'Dokument wprowadzony na podstawie zamówienia sprzedaży. Pola ""Magazyn"" nie można wypełnić';
								|tr = 'Belge müşteri siparişi gerekçesine dayalı girildi. ""Ambar"" alanı doldurulamaz'");
			ShowMessageBox(,WarningText);
			Return False;
		EndIf;
		
	EndIf;
	
	If TabularSection.Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền bảng %TabularSectionPresentation%. Không thể điền trường ""Kho bãi""';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Поле ""Склад"" не может быть заполнено';
							|en = 'Table %TabularSectionPresentation% is not filled in the document. You cannot fill in the Warehouse field'; fa = 'Table %TabularSectionPresentation% is not filled in the document. You cannot fill in the Warehouse field';
							|it = 'Nel documento non è compilata la tabella %TabularSectionPresentation%. Il campo ""Magazzino"" non può essere compilato';
							|pl = 'W dokumencie nie jest pełna tabela %TabularSectionPresentation%. Pole ""Magazyn"" nie może być puste';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. ""Ambar"" alanı doldurulamıyor'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	EndIf;
	
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(,NStr("vi = 'Trong bảng không có dòng đã chọn. Hãy chọn dòng để điền mục tin ""Kho bãi""';
							|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения реквизита ""Склад""';
							|en = 'Selected rows are missing in the table. Select rows to fill in the ""Warehouse"" attribute'; fa = 'Selected rows are missing in the table. Select rows to fill in the ""Warehouse"" attribute';
							|it = 'Nella tabella mancano le righe selezionate. Seleziona le righe per compilare il requisito ""Magazzino""';
							|pl = 'W tabeli nie ma wierszy. Wybierz wiersze, aby wypełnić katalog ""Magazyn""';
							|tr = 'Tabloda seçili satır bulunmamaktadır. ""Ambar"" gereksinimini doldurmak için satırları seç'"));
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction // Check if it is possible to fill in the Table part()

// The procedure shows a notification about filling in the "Warehouse" details of the table part
//
// Parameters:
// 		FillingWarehouse - CatalogRef.Warehouses - Warehouse where filling was performed
// 		FilledWithRows - Number - Number of rows filled in
// 		RowsSelectedCount - Number - The number of lines selected for filling in.
//
Procedure ShowNotificationAboutFillingOfWarehouseInTablePart(FillingWarehouse, FilledWithRows, RowsSelectedCount) Export
	
	If FilledWithRows = 0 Then // If no highlighted line has been filled in
		
		NotificationText1 = NStr("vi = 'Chưa điền dòng được chọn';
								|ru = 'Выделенные строки не заполнены';
								|en = 'The selected lines are not filled in'; fa = 'The selected lines are not filled in';
								|it = 'Le righe selezionate non sono compilate';
								|pl = 'Wybrane wiersze nie są wypełnione';
								|tr = 'Seçilen satırlar doldurulmadı'");
		Explanation = NStr("vi = 'Chưa điền cột ""Kho bãi"" trong các dòng đã chọn';
							|ru = 'Колонка ""Склад"" в выделенных строках не была заполнена';
							|en = 'The ""Warehouse"" column was not populated in the selected lines'; fa = 'The ""Warehouse"" column was not populated in the selected lines';
							|it = 'La colonna ""Magazzino"" nelle righe selezionate non è compilata';
							|pl = 'Kolumna ""Magazyn"" w wybranych wierszach nie została wypełniona';
							|tr = 'Seçilen satırlardaki ""Ambar"" sütunu doldurulmadı'");
		
	ElsIf FilledWithRows = RowsSelectedCount Then // If all the selected lines have been filled in
		
		NotificationText1 = NStr("vi = 'Đã điền dòng được chọn';
								|ru = 'Выделенные строки заполнены';
								|en = 'Selected lines are filled in'; fa = 'Selected lines are filled in';
								|it = 'Le righe selezionate sono compilate';
								|pl = 'Wybrane wiersze są wypełnione';
								|tr = 'Seçilen satırlar dolduruldu'");
		Explanation = StrReplace(NStr("vi = 'Đã điền cột ""Kho bãi"" trong dòng đã chọn bằng giá trị ""%Warehouse%""';
										|ru = 'Колонка ""Склад"" в выделенных строках заполнена значением ""%Warehouse%""';
										|en = 'The ""Warehouse"" column is populated in the selected lines with the ""%Warehouse%"" value'; fa = 'The ""Warehouse"" column is populated in the selected lines with the ""%Warehouse%"" value';
										|it = 'La colonna ""Magazzino"" nelle righe selezionate è compilata con il valore ""%Warehouse%""';
										|pl = 'Kolumna ""Magazyn"" w wybranych wierszach wypełniona wartością ""%Warehouse%""';
										|tr = 'Seçilen satırlardaki ""Ambar"" sütunu ""%Warehouse%"" değeriyle dolduruldu'"), "%Warehouse%", FillingWarehouse);
		
	Else // If not all the highlighted lines have been filled in
		
		NotificationText1 = NStr("vi = 'Đã điền phần dòng tách ra';
								|ru = 'Часть выделенных строк заполнена';
								|en = 'Some of the selected lines are filled in'; fa = 'Some of the selected lines are filled in';
								|it = 'Una parte delle righe selezionate è compilata';
								|pl = 'Część wybranych wierszy jest pełna';
								|tr = 'Seçilen satırlardan bazıları dolduruldu'");
		Explanation = NStr("vi = 'Đã điền cột ""Kho bãi"" trong %FilledWithRows% dòng từ %RowsSelectedCount% đã chọn bằng giá trị ""%Warehouse%""';
							|ru = 'Колонка ""Склад"" в %FilledWithRows% строках из %RowsSelectedCount% выделенных заполнена значением ""%Warehouse%""';
							|en = 'The ""Warehouse"" column is populated in %FilledWithRows% lines out of %RowsSelectedCount% selected with the ""%Warehouse%"" value'; fa = 'The ""Warehouse"" column is populated in %FilledWithRows% lines out of %RowsSelectedCount% selected with the ""%Warehouse%"" value';
							|it = 'La colonna ""Magazzino"" nelle righe %FilledWithRows% da %RowsSelectedCount% selezionate è compilata con il valore ""%Warehouse%""';
							|pl = 'Kolumna ""Magazyn"" w %FilledWithRows% wierszach z %RowsSelectedCount% wyróżnionych wypełniona wartością ""%Warehouse%""';
							|tr = '%RowsSelectedCount% satırlarının %FilledWithRows% satırlarındaki ""Ambar"" sütunu ""%Warehouse%"" değeriyle dolduruldu'");
		Explanation = StrReplace(Explanation, "%Warehouse%", FillingWarehouse);
		Explanation = StrReplace(Explanation, "%FilledWithRows%", FilledWithRows);
		Explanation = StrReplace(Explanation, "%RowsSelectedCount%", RowsSelectedCount);
		
	EndIf;
	
	ShowUserNotification(NotificationText1, , Explanation, PictureLib.Information32);
	
EndProcedure // Display the announcement of the completion of the Table part()

// Procedure-Open the form for checking the packaging and quantity correction.
//
// Parameters:
//	Form	 - ClientApplicationForm - the form from which the processing form is opened 
//		"checking the quantity of goods in the Document";
//	Action - String - "Verification" or "Correction".
//
Procedure OpenCheckingFormPackagingAndQuantities(Form, Action = "Validation") Export
	
	ThisIsSpendingOrder = (TypeOf(Form.Object.Ref) = Type("DocumentRef.GoodsIssueNote"));
	UsePackingLists = True;
	
	If Action = "Validation" Then
		If ThisIsSpendingOrder
			And Form.UsePackingLists Then
			ActionAndCase  = NStr("vi = 'Kiểm tra số lượng và đóng gói';
									|ru = 'Проверка количества и упаковка';
									|en = 'Quantity check and packaging unit'; fa = 'Quantity check and packaging unit';
									|it = 'Controllo di quantità e imballaggio';
									|pl = 'Weryfikacja ilości i opakowanie';
									|tr = 'Miktar ve paketleme ünitesi kontrolü'");
			ActionGenderCase = NStr("vi = 'kiểm tra số lượng và đóng gói';
									|ru = 'проверки количества и упаковки';
									|en = 'quantity and packaging unit check'; fa = 'quantity and packaging unit check';
									|it = 'controlli di quantità e imballaggio';
									|pl = 'sprawdź ilość i opakowanie';
									|tr = 'miktar ve paketleme ünitesi kontrolleri'");
		Else
			ActionAndCase  = NStr("vi = 'Kiểm tra số lượng';
									|ru = 'Проверка количества';
									|en = 'Check quantity'; fa = 'Check quantity';
									|it = 'Controllo di quantità';
									|pl = 'Weryfikacja ilości';
									|tr = 'Miktar kontrolü'");
			ActionGenderCase = NStr("vi = 'kiểm tra số lượng';
									|ru = 'проверки количества';
									|en = 'check quantity'; fa = 'check quantity';
									|it = 'controlli di quantità';
									|pl = 'sprawdź ilość';
									|tr = 'miktar kontrolleri'");
			UsePackingLists = False;
		EndIf;
	Else
		If ThisIsSpendingOrder
			And Form.UsePackingLists Then
			ActionAndCase  = NStr("vi = 'Chỉnh sửa số lượng và đóng gói';
									|ru = 'Исправление количества и упаковка';
									|en = 'Quantity correction and packaging unit'; fa = 'Quantity correction and packaging unit';
									|it = 'Rettifica di quantità e imballaggio';
									|pl = 'Korekta ilości i opakowanie';
									|tr = 'Miktar düzeltmesi ve paketleme ünitesi'");
			ActionGenderCase = NStr("vi = 'chỉnh sửa số lượng và đóng gói';
									|ru = 'исправления количества и упаковки';
									|en = 'corrections of quantity and packaging units'; fa = 'corrections of quantity and packaging units';
									|it = 'rettifiche di quantità e imballaggio';
									|pl = 'ustal ilość i opakowanie';
									|tr = 'miktar ve paketleme ünitesi düzeltmeleri'");
		Else
			ActionAndCase  = NStr("vi = 'Chỉnh sửa số lượng';
									|ru = 'Исправление количества';
									|en = 'Correct quantity'; fa = 'اصلاح مقدار';
									|it = 'Rettifica di quantità';
									|pl = 'Korekta ilości';
									|tr = 'Miktar düzeltmesi'");
			ActionGenderCase = NStr("vi = 'chỉnh sửa số lượng';
									|ru = 'исправления количества';
									|en = 'quantity corrections'; fa = 'quantity corrections';
									|it = 'rettifiche di quantità';
									|pl = 'ustal ilość';
									|tr = 'miktar düzeltmesi'");
			UsePackingLists = False;
		EndIf;
	EndIf;
	
	ClearMessages();
	Cancel = False;
	
	If Form.Modified
		Or Not Form.Object.Posted Then
		QueryText = NStr("vi = 'Trước khi bắt đầu %ChecksAndCorrections% hàng hóa, sẽ kết chuyển chứng từ. Tiếp tục?';
						|ru = 'Перед началом %ChecksAndCorrections% товаров документ будет проведен. Продолжить?';
						|en = 'Before %ChecksAndCorrections% of goods, the document will be posted. Continue?'; fa = 'Before %ChecksAndCorrections% of goods, the document will be posted. Continue?';
						|it = 'Prima di avviare %ChecksAndCorrections% di merci, il documento verrà registrato. Continuare?';
						|pl = 'Przed rozpoczęciem %ChecksAndCorrections% towarów dokument zostanie przeprowadzony. Kontynuować?';
						|tr = 'Belge, ürünlerin %ChecksAndCorrections% işlemi başlatılmadan önce kaydedilecektir. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText,"%ChecksAndCorrections%", ActionGenderCase);
		Response = Undefined;
		
		AdditionalParameters = New Structure;
		
		AdditionalParameters.Insert("Action", Action);
		AdditionalParameters.Insert("ActionAndCase", ActionAndCase);
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("ThisIsSpendingOrder", ThisIsSpendingOrder);
		AdditionalParameters.Insert("UsePackingLists", UsePackingLists);
		
		ShowQueryBox(New CallbackDescription("OpenCheckingFormPackagingAndQuantitiesCompletion",
												ThisObject,
												AdditionalParameters),
			QueryText,
			QuestionDialogMode.OKCancel,
			,
			DialogReturnCode.Cancel);
		Return;
	EndIf;
	
	OpenFormForCheckingPackagingCorrectingQuantityFragment(Action, ActionAndCase, Form, ThisIsSpendingOrder, UsePackingLists);
EndProcedure

// Updates the service details of the form with data about the number of warehouses used in the table part of the document.
//
// Parameters:
//	WarehouseTable - ValueTable - Service details of the form to update;
//	CurrentData - FormDataCollectionItem, Undefined - row in the table where the Bank details have changed;
//	CacheLines - FixedStructure, Undefined - the row in the table where the details were changed contains 
//		the values before the changes;
//	ShouldUpdate - Boolean - True-indicates that the warehouse table needs to be updated;
//	ThereIsCancellationOfLines - Boolean - True-current Data and cache Lines contain the "Canceled" field.
//
Procedure UpdateWarehouseTable(WarehouseTable, CurrentData, CacheLines, ShouldUpdate, ThereIsCancellationOfLines = True) Export
	
	If Not ShouldUpdate Then
		Return;
	EndIf;
	
	If CurrentData <> Undefined And CacheLines <> Undefined Then
		
		If CurrentData.Warehouse = CacheLines.Warehouse And (Not ThereIsCancellationOfLines Or CurrentData.Canceled = CacheLines.Canceled) Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If CacheLines <> Undefined And (Not ThereIsCancellationOfLines Or Not CacheLines.Canceled) Then
		
		For Each TableRow In WarehouseTable Do
		
			If TableRow.Warehouse = CacheLines.Warehouse Then
			
				If TableRow.RowsCount > 1 Then
					TableRow.RowsCount = TableRow.RowsCount - 1;
				Else
					WarehouseTable.Delete(TableRow);
				EndIf;
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.Warehouse)
		And (Not ThereIsCancellationOfLines Or Not CurrentData.Canceled) Then
		
		FoundRow = Undefined;
		For Each TableRow In WarehouseTable Do
			
			If TableRow.Warehouse = CurrentData.Warehouse Then
				
				FoundRow = TableRow;
				Break;
				
			EndIf;
			
		EndDo;
		
		If FoundRow = Undefined Then
			
			FoundRow = WarehouseTable.Add();
			FoundRow.Warehouse = CurrentData.Warehouse;
			FoundRow.RowsCount = 1;
			
		Else
			
			FoundRow.RowsCount = FoundRow.RowsCount + 1;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the division in the selected rows of the table part
//
// Parameters:
// 	Object - DocumentObject
// 	Form - ClientApplicationForm
// 	TabularSection - FormDataCollection
// 	TabularSectionPresentation - String
// 	SelectedRows - Array
// 	OnCloseNotifyDescription - CallbackDescription, Undefined -
//
Procedure FillInDivisionInTablePart(Object, Form, TabularSection, TabularSectionPresentation, SelectedRows, OnCloseNotifyDescription = Undefined) Export

	If TabularSection.Count() = 0 Then
		WarningText = NStr("vi = 'Không có hàng nào được nhập vào danh sách ""%TabularSectionPresentation%"".';
							|ru = 'В список ""%TabularSectionPresentation%"" не введено ни одной строки.';
							|en = 'No lines entered in the ""%TabularSectionPresentation%"" list.'; fa = 'No lines entered in the ""%TabularSectionPresentation%"" list.';
							|it = 'Nell''elenco ""%TabularSectionPresentation% non è stata inserita alcuna riga.';
							|pl = 'Do listy ""%TabularSectionPresentation%"" nie wprowadzono żadnego wiersza.';
							|tr = '""%TabularSectionPresentation%"" listesine hiçbir satır girilmedi.'");
		WarningText = StrReplace(WarningText,"%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox( , WarningText);
		Return;
	Else
		
		RequiredFilling_ = False;
		TypesList = SalesClient.TypesOfNomenclatureWithUnitAnalytics();
		
		For Each String In SelectedRows Do
			
			RowData = TabularSection.FindByID(String);
			
			If TypesList.FindByValue(RowData.ItemsType) = Undefined Then
				Continue;
			EndIf;
			
			RequiredFilling_ = True;
			Break;
			
		EndDo;
		
		If Not RequiredFilling_ Then
			WarningText = NStr("vi = 'Không cần điền bộ phận trong các dòng đã chọn của danh sách ""%TabularSectionPresentation%"".';
								|ru = 'В выделенных строках списка ""%TabularSectionPresentation%"" заполнение подразделения не требуется.';
								|en = 'Filling out operating unit is not required in the selected ""%TabularSectionPresentation%"" list rows.'; fa = 'Filling out operating unit is not required in the selected ""%TabularSectionPresentation%"" list rows.';
								|it = 'Nelle righe selezionate dell''elenco ""%TabularSectionPresentation%""  non è richiesta la compilazione del reparto.';
								|pl = 'W wybranych wierszach listy ""%TabularSectionPresentation%"" wypełnienie działu nie jest wymagane.';
								|tr = '""%TabularSectionPresentation%"" listesinin seçili satırlarında departmanın doldurulmasına gerek yoktur.'");
			WarningText = StrReplace(WarningText,"%TabularSectionPresentation%", TabularSectionPresentation);
			ShowMessageBox( , WarningText);
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Department", Object.Department);
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters, Form,,,, OnCloseNotifyDescription);
	
EndProcedure

#Region DiscrepanciesInShippingDocuments

// The procedure updates the cache of key details of the current product line.
//
// Parameters:
//  FormTable			 - FormTable - form table that displays the PM of products
//  CachedValues	 - Structure - a form module variable that stores cached values
//  SeriesSpecificationParameters	 - Structure - structure of parameters for specifying series returned by the corresponding procedure in the document Manager module
//  Copy				 - Boolean - indicates that the cached string has been copied (parameter of the event at the start of Editing).
//
Procedure UpdateCachedValues(FormTable,CachedValues,SeriesSpecificationParameters,Copy = False) Export
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	CurrentData = FormTable.CurrentData;
	If CurrentData <> Undefined Then
		// The structure of the cached values could be created using the Nomenclature Client.Update
		//	the cached values for the accounting criteria and may not contain the necessary properties.
		CachedValues.Insert("Products");
		CachedValues.Insert("Characteristic");
		CachedValues.Insert("Series");
		CachedValues.Insert("Warehouse");
		CachedValues.Insert("NumberOfPackages");
		CachedValues.Insert("Package");
		FillPropertyValues(CachedValues, CurrentData);
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				FormTable,CachedValues,SeriesSpecificationParameters, Copy);
	
EndProcedure

// AssemblyAndDelivery

// Procedure-Open the form for checking the packaging and quantity correction.
//
// Parameters:
//	Form	 - ClientApplicationForm - the form from which the processing form is opened 
//		"checking the quantity of goods in the Document"
//	EmployeeType - String
//	StandardProcessing - Boolean
//
Procedure OpenStoreEmployeeSelectionForm(Form, EmployeeType, StandardProcessing) Export
	
	StandardProcessing = False;
	
	HeaderParameter_ = "";
	If Lower(EmployeeType) = "courier" Then
		
		HeaderParameter_ = NStr("vi = 'Chọn bên giao nhận vận tải';
								|ru = 'Выбрать курьера';
								|en = 'Select courier'; fa = 'Select courier';
								|it = 'Selezionare corriere';
								|pl = 'Wybierz kuriera';
								|tr = 'Kurye seçimi'");
		
	ElsIf Lower(EmployeeType) = "picker" Then
		
		HeaderParameter_ = NStr("vi = 'Chọn người thu thập';
								|ru = 'Выбрать сборщика';
								|en = 'Select picker'; fa = 'Select picker';
								|it = 'Selezionare assemblatore';
								|pl = 'Wybierz zbieracza';
								|tr = 'Montajcı seç'");
		
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	
	OpenForm("Catalog.Persons.ChoiceForm", FormOpenParameters, Form);
	
EndProcedure

// End AssemblyAndDelivery

#EndRegion 

#EndRegion 

#Region Private

// Parameters:
// 	Products - CatalogRef.Products
// 	AdditionalParameters - Structure:
//		* CachedValues - Structure
//		* NotificationOfSuccessfulExecution - CallbackDescription
//		* StructureOfActions - Structure
//		* CurrentRow - Arbitrary
//
Procedure ChangeQualityCompletion(Products, AdditionalParameters) Export
	
	CachedValues = AdditionalParameters.CachedValues;
	NotificationOfSuccessfulExecution = AdditionalParameters.NotificationOfSuccessfulExecution;
	StructureOfActions = AdditionalParameters.StructureOfActions;
	CurrentRow = AdditionalParameters.CurrentRow;
	
	If ValueIsFilled(Products) Then
		
		EntryString = New Structure("ProductsOfOriginalQuality,
			|ItemVariantsAreUsed,
			|Products,
			|Characteristic,
			|Package,
			|PriceKind,
			|Price,
			|SKU,
			|SKURegistration,
			|Count,
			|NumberOfPackages,
			|Sum,
			|VATAmount,
			|AmountIncludingVAT");
		
		WarehousesClientLocalization.AddFieldsToRowsOfTablePartWhenQualityChanges(EntryString, StructureOfActions);
		
		ActionParameters = Undefined;
		If StructureOfActions.Property("FillInCheckQualityDateOfQualityConfirmation", ActionParameters)
				Or StructureOfActions.Property("FillInUnblockableDateOfQualityConfirmation", ActionParameters)
				Or StructureOfActions.Property("FillInSenderSControlledLotReference", ActionParameters) Then
			For Each ActionName In ActionParameters Do
				If ActionName.Key = "Key" Then
					Continue;
				EndIf;
				Fields = StrSplit(ActionParameters[ActionName.Key].EditableFields, ",");
				For Each Field In Fields Do
					EntryString.Insert(Field);
				EndDo;
				Fields = StrSplit(ActionParameters[ActionName.Key].ReadableFields, ",");
				For Each Field In Fields Do
					EntryString.Insert(Field);
				EndDo;
			EndDo;
		EndIf;
		
		If StructureOfActions.Property("FillInDuplicateDependentDetails", ActionParameters) Then
			For Each ActionName In ActionParameters Do
				EntryString.Insert(ActionName.Key);
				DependentDetails = New Structure(ActionName.Value);
				For Each Attribute In DependentDetails Do
					EntryString.Insert(Attribute.Key + ActionName.Key);
				EndDo;
			EndDo;
		EndIf;
		
		If StructureOfActions.Property("CheckSeriesCalculateStatus") Then
			EntryString.Insert("Series");
			EntryString.Insert("BatchesIndicationStatus");
			SeriesSpecificationParameters = StructureOfActions.CheckSeriesCalculateStatus.SeriesSpecificationParameters;
			For Each LinksField In SeriesSpecificationParameters.LinkFields Do
				EntryString.Insert(LinksField);
			EndDo;
			For Each Field In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				EntryString.Insert(Field);
			EndDo;
			For Each Field In SeriesSpecificationParameters.FieldNamesForOrderDefinition Do
				EntryString.Insert(Field);
			EndDo;
			For Each Field In SeriesSpecificationParameters.AdditionalFieldNames Do
				EntryString.Insert(Field);
			EndDo;
			If CurrentRow.Property("Purpose") Then
				EntryString.Insert("Purpose");
			EndIf;
		EndIf;
		
		If StructureOfActions.Property("FillInCountryOfOriginOfProduct") Then
			EntryString.Insert("TheRecordsAreKeptByCCD");
			EntryString.Insert("CCDNumber");
			EntryString.Insert("OriginCountry");
		EndIf;
		
		If CurrentRow.Property("ProductsRecordingAsReceived") Then
			CurrentRow.ProductsRecordingAsReceived = Products;
			
			FillPropertyValues(EntryString, CurrentRow);
			
			EntryString.ProductsOfOriginalQuality = CurrentRow.Products;
			EntryString.Products                  = CurrentRow.ProductsRecordingAsReceived;
			EntryString.ItemVariantsAreUsed    = CurrentRow.ItemVariantsAreUsedRecordingAsReceived;
			EntryString.Characteristic                = CurrentRow.Characteristic;
			
			BatchProcessingOfTablePartClient.ProcessTSString(EntryString, StructureOfActions, CachedValues);
			
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = EntryString.ItemVariantsAreUsed;
			CurrentRow.CharacteristicRecordingAsReceived             = EntryString.Characteristic;
			CurrentRow.SKURegistration                    = EntryString.SKU;
			
			If CurrentRow.Property("Price") Then
				CurrentRow.Price = EntryString.Price;
			EndIf;
			
			If CurrentRow.Property("Sum") Then
				CurrentRow.Sum = EntryString.Sum;
			EndIf;
			
			If CurrentRow.Property("AmountIncludingVAT") Then
				CurrentRow.AmountIncludingVAT = EntryString.AmountIncludingVAT;
			EndIf;
			
			ActionParameters = Undefined;
			If StructureOfActions.Property("FillInCheckQualityDateOfQualityConfirmation", ActionParameters)
					Or StructureOfActions.Property("FillInUnblockableDateOfQualityConfirmation", ActionParameters)
					Or StructureOfActions.Property("FillInSenderSControlledLotReference", ActionParameters) Then
				For Each ActionName In ActionParameters Do
					If ActionName.Key = "Key" Then
						Continue;
					EndIf;
					FillPropertyValues(CurrentRow, EntryString, ActionParameters[ActionName.Key].EditableFields);
				EndDo;
			EndIf;
			
		Else
			EntryString.ProductsOfOriginalQuality = CurrentRow.Products;
			CurrentRow.Products = Products;
			FillPropertyValues(EntryString, CurrentRow);
			BatchProcessingOfTablePartClient.ProcessTSString(EntryString, StructureOfActions, CachedValues);
			FillPropertyValues(CurrentRow, EntryString);
		EndIf;
		
		If NotificationOfSuccessfulExecution <> Undefined Then
			RunCallback(NotificationOfSuccessfulExecution, CurrentRow);
		EndIf;
		
	EndIf;

EndProcedure

Procedure TakeUpTheJobsCompletion(Result, AdditionalParameters) Export
	
	DocumentsArray = AdditionalParameters.DocumentsArray;
	NotificationOfSuccessfulExecution = AdditionalParameters.NotificationOfSuccessfulExecution;
	List = AdditionalParameters.List;
	Form = AdditionalParameters.Form;
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = WarehousesServerCall.TakeUpTheJobs(DocumentsArray, Form.AssignAssignee, Form.Performer);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(List, ArrayOfChangedDocuments.Count(), DocumentsArray.Count(),
	PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.InProgress"));
	
	If ArrayOfChangedDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	If Form.PrintJobs Then
		If Form.PrintToPrinter Then
			PrintManagementClient.ExecutePrintToPrinterCommand("Document.GoodsPickingPlacement", "WarehouseJob",
			ArrayOfChangedDocuments, New Structure);
		Else
			PrintManagementClient.ExecutePrintCommand("Document.GoodsPickingPlacement", "WarehouseJob",
			ArrayOfChangedDocuments, Form, New Structure);
		EndIf;
	EndIf;
	
	RunCallback(NotificationOfSuccessfulExecution);

EndProcedure

Procedure MarkCompletionOfTasksWithoutErrorsCompletion(Result, AdditionalParameters) Export
	
	DocumentsArray = AdditionalParameters.DocumentsArray;
	NotificationOfSuccessfulExecution = AdditionalParameters.NotificationOfSuccessfulExecution;
	List = AdditionalParameters.List;
	Form = AdditionalParameters.Form;
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = WarehousesServerCall.MarkCompletionOfTasksWithoutErrors(DocumentsArray,
	Form.AssignAssignee, Form.Performer);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		List, 
		ArrayOfChangedDocuments.Count(), 
		DocumentsArray.Count(),
		PredefinedValue("Enum.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors"));
	
	If ArrayOfChangedDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	RunCallback(NotificationOfSuccessfulExecution);

EndProcedure

// Parameters:
// 	QuestionResult - DialogReturnCode
// 	AdditionalParameters - Structure:
//		* Action - String - "Verification" or " Correction"
// 		* Form - ManagedFormExtensionForDocuments
// 
Procedure OpenCheckingFormPackagingAndQuantitiesCompletion(QuestionResult, AdditionalParameters) Export
    
    Action = AdditionalParameters.Action;
    ActionAndCase = AdditionalParameters.ActionAndCase;
    Form = AdditionalParameters.Form;
    ThisIsSpendingOrder = AdditionalParameters.ThisIsSpendingOrder;
    UsePackingLists = AdditionalParameters.UsePackingLists;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.Cancel Then
        Cancel = True;
    Else
        Cancel = Not Form.Write(New Structure("WriteMode", DocumentWriteMode.Posting));
    EndIf;
    If Cancel Then
        Return;
    EndIf;
    
    OpenFormForCheckingPackagingCorrectingQuantityFragment(Action, ActionAndCase, Form, ThisIsSpendingOrder, UsePackingLists);

EndProcedure

// Parameters:
// 	Action - String
// 	ActionAndCase - String
// 	Form - ClientApplicationForm:
// 		* Object - FormDataStructure:
// 			** Ref - DocumentRef
// 	ThisIsSpendingOrder - Boolean
//
Procedure OpenFormForCheckingPackagingCorrectingQuantityFragment(Val Action, Val ActionAndCase, Val Form, Val ThisIsSpendingOrder, Val UsePackingLists)
    
    Var HeaderParameter_, FormParameters;
    
    If ValueIsFilled(Form.Object.Ref) Then
        HeaderParameter_ = NStr("vi = '%InspectionAndCorrection% hàng hóa trong chứng từ %Document%';
								|ru = '%InspectionAndCorrection% товаров в документе %Document%';
								|en = '%InspectionAndCorrection% of goods in the %Document% document'; fa = '%InspectionAndCorrection% of goods in the %Document% document';
								|it = '%InspectionAndCorrection% di merci nel documento %Document%';
								|pl = '%InspectionAndCorrection% towarów w dokumencie %Document%';
								|tr = '%InspectionAndCorrection% ürünlerin belgede %Document%'");
        HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Form.Object.Ref);
    ElsIf ThisIsSpendingOrder Then
        HeaderParameter_ = NStr("vi = '%InspectionAndCorrection% hàng hóa trong phiếu xuất kho';
								|ru = '%InspectionAndCorrection% товаров в расходном ордере на товаров';
								|en = '%InspectionAndCorrection% of goods in goods issue note'; fa = '%InspectionAndCorrection% of goods in goods issue note';
								|it = '%InspectionAndCorrection% di merci nel mandato di pagamento per le merci';
								|pl = '%InspectionAndCorrection% towarów w zewnętrznym wydaniu towarów';
								|tr = '%InspectionAndCorrection% ambar çıkışında ürünler'");
    Else
        HeaderParameter_ = NStr("vi = '%InspectionAndCorrection% hàng hóa trong phiếu điều chuyển';
								|ru = '%InspectionAndCorrection% товаров в ордере на перемещение товаров';
								|en = '%InspectionAndCorrection% of goods in internal stock transfer'; fa = '%InspectionAndCorrection% of goods in internal stock transfer';
								|it = '%InspectionAndCorrection% di merci nel mandato di trasferimento delle merci';
								|pl = '%InspectionAndCorrection% towarów w zleceniu na przepływ towarów';
								|tr = 'dahili stok transferinde ürünler %InspectionAndCorrection%'");
    EndIf;
    
    HeaderParameter_ = StrReplace(HeaderParameter_, "%InspectionAndCorrection%", ActionAndCase);
    
    FormParameters = New Structure;
    FormParameters.Insert("Title", HeaderParameter_);
    FormParameters.Insert("False", True);
    FormParameters.Insert("Warehouse", Form.Object.Warehouse);
    FormParameters.Insert("Premise", ?(ThisIsSpendingOrder, Form.Object.Premise, Form.Object.SenderWareroom));
    FormParameters.Insert("WarehouseDocument", Form.Object.Ref);
    FormParameters.Insert("CorrectionMode", ?(Action = "Validation", False, True));
    FormParameters.Insert("UsePackingLists", UsePackingLists);
    Form.UnlockFormDataForEdit();
    OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.Form", FormParameters, Form);
    
    Form.Close();

EndProcedure

#EndRegion
