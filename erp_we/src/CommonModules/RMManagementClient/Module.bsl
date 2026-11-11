////////////////////////////////////////////////////////////////////////////////
// Procedures of the repair management subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Retrieves the print data and opens the print form.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function LabelPrintingOfSubAssets(CommandDetails) Export
	
	OpenForm(
		"DataProcessor.LabelPrintingOfSubAssets.Form",
		New Structure("Nodes", CommandDetails.PrintObjects),
		CommandDetails.Form,
		New UUID);
	
	Return Undefined;
	
EndFunction

// Reports an unsuccessful search for nodes by barcode.
// 
Procedure ReportThatNodesCouldNotBeFoundByBarcode() Export

	MessageText = NStr("vi = 'Không tìm thấy nút';
						|ru = 'Узлы не найдены';
						|en = 'Sub-assets not found'; fa = 'Sub-assets not found';
						|it = 'Nodi non trovati';
						|pl = 'Nie znaleziono węzłów';
						|tr = 'Alt varlıklar bulunamadı'");
	ExplanationOfMessage = NStr("vi = 'Không thể tìm thấy chi tiết theo mã vạch';
								|ru = 'Не удалось найти узлы по штрихкоду';
								|en = 'Cannot find sub-assets using the barcode'; fa = 'Cannot find sub-assets using the barcode';
								|it = 'Non è stato possibile trovare i nodi per codice a barre';
								|pl = 'Nie udało się znaleźć węzłów wg kodu kreskowego';
								|tr = 'Barkoda ilişkin alt varlıklar bulunamadı'");
	
	ShowUserNotification(MessageText,, ExplanationOfMessage,,,);
		
EndProcedure

// Generates barcodes for the nodes of the objects of operation.
// 
// Parameters:
// 	NodesList - Array of CatalogRef.SubAssets - Nodes for which you want to generate a barcode.
Procedure GenerateNodeBarcodes(Val NodesList) Export
	
	TotalCount1 = NodesList.Count();
	ProcessedItemsCount = RMManagementServerCall.GenerateNodeBarcodes(NodesList);
	
	If ProcessedItemsCount > 0 Then
		
		If ProcessedItemsCount = TotalCount1 Then
			NotificationPicture = PictureLib.Information32;
			MessageText = NStr("vi = 'Đã tạo mã vạch đối với tất cả nút được chọn';
								|ru = 'Штрихкод сформирован для всех выбранных узлов';
								|en = 'Barcode generated for all selected sub-assets'; fa = 'Barcode generated for all selected sub-assets';
								|it = 'Codice a barre generato per tutti i nodi selezionati';
								|pl = 'Utworzono kod kreskowy dla wszystkich wybranych węzłów';
								|tr = 'Seçilen tüm alt varlıklar için barkod oluşturuldu'");
		Else	
			NotificationPicture = PictureLib.Attention32;
			MessageText = StrTemplate(NStr("vi = 'Đã tạo mã vạch đối với %1 trong số %2 nút được chọn';
											|ru = 'Штрихкод сформирован для %1 из %2 выбранных узлов';
											|en = 'Barcode generated for %1 of %2 selected sub-assets'; fa = 'Barcode generated for %1 of %2 selected sub-assets';
											|it = 'Codice a barre generato per %1 di %2 nodi selezionati';
											|pl = 'Utworzono kod kreskowy dla %1 z %2 wybranych węzłów';
											|tr = 'Barkod, seçilen %2 alt varlıklardan %1''i için oluşturulmuştur'"),
					ProcessedItemsCount, 
					TotalCount1);
		EndIf;

		TitleText = NStr("vi = 'Đã tạo mã vạch';
						|ru = 'Штрихкоды сформированы';
						|en = 'Barcodes are generated'; fa = 'Barcodes are generated';
						|it = 'Codici a barre generati';
						|pl = 'Utworzono kody kreskowe';
						|tr = 'Barkodlar oluşturuldu'");
		ShowUserNotification(TitleText,, MessageText, NotificationPicture);

	Else
		
		MessageText = NStr("vi = 'Trong các chi tiết đã chọn có tạo mã vạch';
							|ru = 'У выбранных узлов уже сформирован штрихкод';
							|en = 'The barcode has already been generated for selected sub-assets'; fa = 'The barcode has already been generated for selected sub-assets';
							|it = 'I nodi selezionati hanno già un codice a barre';
							|pl = 'Dla wybranych węzłów jest już wygenerowany kod kreskowy';
							|tr = 'Seçilen alt varlıkların zaten oluşturulmuş bir barkodu vardır'");
		TitleText = NStr("vi = 'Chưa tạo mã vạch';
						|ru = 'Штрихкоды не сформированы';
						|en = 'Barcodes are not generated'; fa = 'Barcodes are not generated';
						|it = 'Codici a barre non sono stati generati';
						|pl = 'Nie utworzono kodów kreskowych';
						|tr = 'Barkodlar oluşturulmadı'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Attention32);
		
	EndIf;

	Notify("Write_SubAssets");
	NotifyChanged(Type("CatalogRef.SubAssets"));
	
EndProcedure

// Searches for nodes by barcode.
// Opens a form where the user enters a barcode.
// After you enter it, the nodes are searched for.
// If multiple nodes are found, a form opens to select the nodes.
// After a successful search, it returns an array of found nodes.
// 
// Parameters:
// 	ProcessingProcedure - CallbackDescription - The procedure to call when the search is successful.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
Procedure SearchForNodesByBarcode(ProcessingProcedure, PickingParameters = Undefined) Export

	AdditionalParameters = New Structure("ProcessingProcedure, PickingParameters", ProcessingProcedure, PickingParameters);
	Notification = New CallbackDescription("SearchForNodesByBarcodeCompletion", ThisObject, AdditionalParameters);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

// Searches for operational objects or nodes by barcode.
// Opens a form where the user enters a barcode.
// After you enter it, a search is performed.
// If several OES or nodes are found, a selection form opens.
// After a successful search, it returns an array of links.
// 
// Parameters:
// 	ProcessingProcedure - CallbackDescription - The procedure to call when the search is successful.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
Procedure SearchForObjectsOfOperationOrNodesByBarcode(ProcessingProcedure, PickingParameters = Undefined) Export
	
	AdditionalParameters = New Structure("ProcessingProcedure, PickingParameters", ProcessingProcedure, PickingParameters);
	Notification = New CallbackDescription("SearchForObjectsOfOperationOrNodesByBarcodeCompletion", ThisObject, AdditionalParameters);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

// Input processing of barcode.
// 
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
// 	ProcessingProcedure - CallbackDescription - The procedure to call when the search is successful.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
Procedure ProcessInputOfBarcodes(BarcodeData_5, ProcessingProcedure, PickingParameters = Undefined) Export
	
	SearchResult = RMManagementServerCall.FindNodesByBarcodes(
						BarcodeData_5, PickingParameters);
	
	If SearchResult.ObjectsArray.Count() = 0 Then
		
		ReportResultsOfSearchForNodesByBarcode(SearchResult);
	
	ElsIf SearchResult.ObjectsArray.Count() = 1 Then
		
		RunCallback(ProcessingProcedure, SearchResult.ObjectsArray);
	
	Else
		
		AdditionalParameters = New Structure("ProcessingProcedure", ProcessingProcedure);
		Notification = New CallbackDescription("SelectionOfNodesByStrokeCompletion", ThisObject, AdditionalParameters);
		
		Parameters = New Structure;
		Parameters.Insert("BarcodeData_5", BarcodeData_5);
		Parameters.Insert("PickingParameters", PickingParameters);
		Parameters.Insert("ObjectsArray", SearchResult.ObjectsArray);
		Parameters.Insert("SearchForNodes", True);
		OpenForm("Catalog.Assets.Form.SearchByBarcode", Parameters,,,,, Notification);
	
	EndIf;
	
EndProcedure

// Input processing of barcode.
// 
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
// 	ProcessingProcedure - CallbackDescription - The procedure to call when the search is successful.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
Procedure ProcessInputOfBarcodesOfObjectsOfOperationOrNodes(BarcodeData_5, ProcessingProcedure, PickingParameters = Undefined) Export
	
	SearchResult = RMManagementServerCall.FindObjectsOfOperationOrNodesByBarcodes(
						BarcodeData_5, PickingParameters);
	
	If SearchResult.ObjectsArray.Count() = 0 Then
		
		ReportResultsOfSearchForObjectsOfOperationOrNodesByBarcode(SearchResult);
	
	ElsIf SearchResult.ObjectsArray.Count() = 1 Then
		
		RunCallback(ProcessingProcedure, SearchResult.ObjectsArray);
	
	Else
		
		AdditionalParameters = New Structure("ProcessingProcedure", ProcessingProcedure);
		Notification = New CallbackDescription("SelectionOfNodesByStrokeCompletion", ThisObject, AdditionalParameters);
		
		Parameters = New Structure;
		Parameters.Insert("BarcodeData_5", BarcodeData_5);
		Parameters.Insert("PickingParameters", PickingParameters);
		Parameters.Insert("ObjectsArray", SearchResult.ObjectsArray);
		Parameters.Insert("SearchForOperationalObjects", True);
		Parameters.Insert("SearchForNodes", True);
		OpenForm("Catalog.Assets.Form.SearchByBarcode", Parameters,,,,, Notification);
	
	EndIf;
	
EndProcedure

// Reports the barcode search results.
// 
// Parameters:
// 	SearchResult - See RMManagementServerCall.FindObjectsOfOperationOrNodesByBarcodes
Procedure ReportResultsOfSearchForObjectsOfOperationOrNodesByBarcode(SearchResult) Export
	
	ClearMessages();
	
	MessageTemplate = NStr("vi = 'Không thể tìm thấy đối tượng vận hành và chi tiết theo mã vạch %1';
							|ru = 'Не удалось найти объекты эксплуатации и узлы по штрихкоду %1';
							|en = 'Cannot find sub-assets and objects by barcode %1'; fa = 'Cannot find sub-assets and objects by barcode %1';
							|it = 'Non è stato possibile trovare oggetti d''uso operativo e nodi per codice a barre %1';
							|pl = 'Nie udało się znaleźć obiektów eksploatacji i węzłów wg kodu kreskowego %1';
							|tr = 'İşlem nesneleri ve barkodlar %1 barkoduna göre bulunamıyor'");
	For Each Barcode In SearchResult.NotFound_1 Do
		MessageText = StrTemplate(MessageTemplate, Barcode);
		CommonClient.MessageToUser(MessageText); 
	EndDo; 
	
	MessageTemplateObject = NStr("vi = 'Không thể thêm đối tượng vận hành ""%1 vào chứng từ, bởi vì không thỏa mãn điều kiện chọn';
								|ru = 'Объект эксплуатации ""%1"" не может быть добавлен в документ, т.к. он не удовлетворяет условиям выбора';
								|en = 'The asset ""%1"" cannot be added to the document, as it does not meet selection conditions'; fa = 'The asset ""%1"" cannot be added to the document, as it does not meet selection conditions';
								|it = 'Oggetto d''uso operativo ""%1"" non può essere aggiunto nel documento in quanto non soddisfa i criteri di selezione';
								|pl = 'Nie można dodać obiektu operacji „%1” do dokumentu, ponieważ nie spełnia warunków wyboru';
								|tr = '""%1"" varlığı seçim koşullarını karşılamadığı için belgeye eklenemiyor'");
	MessageTemplateNode = NStr("vi = 'Không thể thêm chi tiết ""%1"" vào chứng từ, bởi vì không thỏa mãn điều kiện chọn';
								|ru = 'Узел ""%1"" не может быть добавлен в документ, т.к. он не удовлетворяет условиям выбора';
								|en = 'The sub-asset ""%1"" cannot be added to the document, as it does not meet selection conditions'; fa = 'The sub-asset ""%1"" cannot be added to the document, as it does not meet selection conditions';
								|it = 'Nodo ""%1"" non può essere aggiunto nel documento in quanto non soddisfa i criteri di selezione';
								|pl = 'Węzeł ""%1"" nie może być dodany do dokumentu, ponieważ nie odpowiada warunkom wyboru';
								|tr = '""%1"" alt varlığı, seçim ölçütlerini karşılamadığı için belgeye eklenemiyor'");
	For Each ObjectReference In SearchResult.DoNotFit Do
		If TypeOf(ObjectReference) = Type("CatalogRef.SubAssets") Then
			MessageText = StrTemplate(MessageTemplateNode, ObjectReference);
		Else
			MessageText = StrTemplate(MessageTemplateObject, ObjectReference);
		EndIf;
		CommonClient.MessageToUser(MessageText, ObjectReference); 
	EndDo; 
	
EndProcedure

// Reports the barcode search results.
// 
// Parameters:
// 	SearchResult - See RMManagementServerCall.FindNodesByBarcodes
Procedure ReportResultsOfSearchForNodesByBarcode(SearchResult) Export
	
	ClearMessages();
	
	MessageTemplate = NStr("vi = 'Không thể tìm thấy chi tiết theo mã vạch %1';
							|ru = 'Не удалось найти узлы по штрихкоду %1';
							|en = 'Cannot find sub-assets using the barcode.%1'; fa = 'Cannot find sub-assets using the barcode.%1';
							|it = 'Non è stato possibile trovare i nodi per codice a barre %1';
							|pl = 'Nie udało się znaleźć węzłów wg kodu kreskowego %1';
							|tr = '%1 barkoda ilişkin alt varlıklar bulunamadı'");
	For Each Barcode In SearchResult.NotFound_1 Do
		MessageText = StrTemplate(MessageTemplate, Barcode);
		CommonClient.MessageToUser(MessageText); 
	EndDo; 
	
	MessageTemplate = NStr("vi = 'Không thể thêm chi tiết ""%1"" vào chứng từ, bởi vì không thỏa mãn điều kiện chọn';
							|ru = 'Узел ""%1"" не может быть добавлен в документ, т.к. он не удовлетворяет условиям выбора';
							|en = 'The sub-asset ""%1"" cannot be added to the document, as it does not meet selection conditions'; fa = 'The sub-asset ""%1"" cannot be added to the document, as it does not meet selection conditions';
							|it = 'Nodo ""%1"" non può essere aggiunto nel documento in quanto non soddisfa i criteri di selezione';
							|pl = 'Węzeł ""%1"" nie może być dodany do dokumentu, ponieważ nie odpowiada warunkom wyboru';
							|tr = '""%1"" alt varlığı, seçim ölçütlerini karşılamadığı için belgeye eklenemiyor'");
	For Each ObjectReference In SearchResult.DoNotFit Do
		MessageText = StrTemplate(MessageTemplate, ObjectReference);
		CommonClient.MessageToUser(MessageText, ObjectReference); 
	EndDo; 
	
EndProcedure

#EndRegion

#Region Private

// Sets a new status for operational objects.
//
// Parameters:
//	NewStatus - EnumRef.AssetStatuses - New status
//	StatusPresentation - String - the introduction of the new status
//  ObjectsArray - Array - list of operational objects.
//
Procedure EstablishStatusOfObjectsOfOperation(NewStatus, StatusPresentation, ObjectsArray) Export
	
	If ObjectsArray.Count() = 0 Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StatusValue",      NewStatus);
	AdditionalParameters.Insert("StatusPresentation", StatusPresentation);
	AdditionalParameters.Insert("HighlightedLinks",     ObjectsArray);
	CallbackDescription = New CallbackDescription("EstablishStatusOfObjectsOfOperationCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Sẽ đặt trạng thái ""%1"" cho các đối tượng vận hành đã chọn. Tiếp tục?';
					|ru = 'Выбранным объектам эксплуатации будет установлен статус ""%1"". Продолжить?';
					|en = 'Status ""%1"" will be set for the selected assets. Continue?'; fa = 'Status ""%1"" will be set for the selected assets. Continue?';
					|it = 'Agli oggetti d''uso operativo selezionati verrà impostato lo stato ""%1"". Continuare?';
					|pl = 'Dla wybranych obiektów eksploatacji będzie ustawiony status ""%1"". Kontynuować?';
					|tr = 'Seçilen varlıklar ""%1"" durumuna ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, StatusPresentation);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

Procedure ChangeClassOfOperationalObjects(ObjectsArray) Export
	
	If ObjectsArray.Count() = 0 Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("HighlightedLinks", ObjectsArray);
	CallbackDescription = New CallbackDescription("SelectObjectClassEnd", ThisObject, AdditionalParameters);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ThisNodeClass", False);
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Filter", FilterParameters);
	
	OpenForm("Catalog.MaintenanceSchemes.ChoiceForm", ChoiceParameters,,,,, CallbackDescription);
	
EndProcedure

Procedure EstablishStatusOfObjectsOfOperationCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	TotalCount1 = AdditionalParameters.HighlightedLinks.Count();
	
	Result = RMManagementServerCall.EstablishStatusOfObjectsOfOperation(
										AdditionalParameters.HighlightedLinks, 
										AdditionalParameters.StatusValue);
										
	If Result.ProcessedItemsCount > 0 Then
		
		If Result.ProcessedItemsCount = TotalCount1 Then
			NotificationPicture = PictureLib.Information32;
			MessageText = NStr("vi = 'Đặt trạng thái mới cho tất cả đối tượng vận hành đã chọn';
								|ru = 'Для всех выбранных в списке объектов эксплуатации установлен новый статус';
								|en = 'A new status has been set for all the assets selected in the list'; fa = 'A new status has been set for all the assets selected in the list';
								|it = 'Nuovo stato impostato per tutti gli oggetti d''uso operativo selezionati nell''elenco';
								|pl = 'Dla wszystkich wybranych na liście obiektów eksploatacji jest ustawiony nowy status';
								|tr = 'İşletim nesneleri listesinde seçilen tüm nesneler için yeni bir durum ayarlandı'");
		Else	
			NotificationPicture = PictureLib.Attention32;
			MessageText = StrTemplate(NStr("vi = 'Đặt trạng thái mới cho %1 trong số %2 đối tượng vận hành đã chọn';
											|ru = 'Для %1 из %2 выбранных в списке объектов эксплуатации установлен новый статус';
											|en = 'A new status has been set for %1 of %2 assets selected in the list'; fa = 'A new status has been set for %1 of %2 assets selected in the list';
											|it = 'Nuovo stato impostato per %1 di %2 oggetti d''uso operativo selezionati nell''elenco';
											|pl = 'Dla %1 z %2 wybranych na liście obiektów eksploatacji jest ustawiony nowy status';
											|tr = 'İşlem listesinde %2''den seçilen %1nesneler için yeni bir durum ayarlandı'"),
					Result.ProcessedItemsCount, 
					TotalCount1);
		EndIf;

		TitleText = StrTemplate(NStr("vi = 'Trạng thái ""%1"" đã đặt';
									|ru = 'Статус ""%1"" установлен';
									|en = 'Status ""%1"" is set'; fa = 'Status ""%1"" is set';
									|it = 'Lo stato ""%1"" è impostato';
									|pl = 'Ustawiono status ""%1""';
									|tr = 'Durum ""%1"" ayarlandı'"), AdditionalParameters.StatusPresentation);

		ShowUserNotification(TitleText,, MessageText, NotificationPicture);

	Else
		
		If Result.ThereAreFillCheckingErrors Then
			MessageText = NStr("vi = 'Chưa đặt trạng thái cho đối tượng vận hành nào. Cần mở đối tượng vận hành và thực hiện kiểm tra điền.';
								|ru = 'Статус не установлен ни для одного объекта эксплуатации. Необходимо открыть объект эксплуатации и выполнить проверку заполнения.';
								|en = 'The status is not set for any asset. Open the asset and perform a filling check.'; fa = 'The status is not set for any asset. Open the asset and perform a filling check.';
								|it = 'Lo stato non è stato impostato per nessun oggetto d''uso operativo. È necessario aprire l''oggetto d''uso operativo ed eseguire un controllo di compilazione.';
								|pl = 'Status nie jest ustawiony dla żadnego obiektu eksploatacji. Należy otworzyć obiekt eksploatacji i sprawdzić wypełnienie.';
								|tr = 'Durum herhangi bir varlık için ayarlanmamıştır. Varlığı açmalı ve bir dolum kontrolü gerçekleştirmelisiniz.'");
		Else	
			MessageText = NStr("vi = 'Chưa đặt trạng thái cho đối tượng vận hành nào.';
								|ru = 'Статус не установлен ни для одного объекта эксплуатации.';
								|en = 'The status is not set for any asset.'; fa = 'The status is not set for any asset.';
								|it = 'Lo stato non è stato impostato per nessun oggetto d''uso operativo.';
								|pl = 'Status nie jest ustawiony dla żadnego obiektu eksploatacji.';
								|tr = 'Herhangi bir işletme nesnesi için statü belirlenmemiştir.'");
		EndIf;
		
		TitleText = StrTemplate(NStr("vi = 'Trạng thái ""%1"" chưa đặt';
									|ru = 'Статус ""%1"" не установлен';
									|en = 'Status ""%1"" is not set'; fa = 'Status ""%1"" is not set';
									|it = 'Lo stato ""%1"" non è impostato';
									|pl = 'Nie ustawiono statusu ""%1""';
									|tr = 'Durum ""%1"" ayarlanmadı'"), AdditionalParameters.StatusPresentation);
		
		ShowUserNotification(TitleText,, MessageText, PictureLib.Attention32);
		
	EndIf;

	Notify("Write_Assets");
	NotifyChanged(Type("CatalogRef.Assets"));
	
EndProcedure

Procedure SelectObjectClassEnd(SelectionResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectionResult)
		Or TypeOf(SelectionResult) <> Type("CatalogRef.MaintenanceSchemes") Then
		Return;
	EndIf;
	
	If RMManagementServerCall.UseOfSubclasses(SelectionResult) Then
		
		AdditionalSelectionOptions = New Structure;
		AdditionalSelectionOptions.Insert("HighlightedLinks", AdditionalParameters.HighlightedLinks);
		AdditionalSelectionOptions.Insert("Class", SelectionResult);
		
		CallbackDescription = New CallbackDescription("SelectSubclassOfExploitationObjectsEnd", ThisObject, AdditionalSelectionOptions);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Owner", SelectionResult);
		
		ChoiceParameters = New Structure;
		ChoiceParameters.Insert("Filter", FilterParameters);

		OpenForm("Catalog.MaintenanceSchemeOptions.ChoiceForm", ChoiceParameters,,,,, CallbackDescription);
	
	Else
		
		ChangeClassOfOperationObjectsAfterSelecting(
			AdditionalParameters.HighlightedLinks, 
			SelectionResult, 
			Undefined);
			
	EndIf; 
	
EndProcedure

Procedure SelectSubclassOfExploitationObjectsEnd(SelectionResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectionResult)
		Or TypeOf(SelectionResult) <> Type("CatalogRef.MaintenanceSchemeOptions") Then
		Return;
	EndIf;
	
	ChangeClassOfOperationObjectsAfterSelecting(
		AdditionalParameters.HighlightedLinks, 
		AdditionalParameters.Class, 
		SelectionResult);
	
EndProcedure

Procedure ChangeClassOfOperationObjectsAfterSelecting(HighlightedLinks, Class, Subclass)

	ClearMessages();
	
	TotalCount1 = HighlightedLinks.Count();
	
	Result = RMManagementServerCall.ChangeClassOfOperationalObjects(
										HighlightedLinks, 
										Class,
										Subclass);
										
	If Result.ProcessedItemsCount > 0 Then
		
		If Result.ProcessedItemsCount = TotalCount1 Then
			MessageText = NStr("vi = 'Đặt phân loại mới cho tất cả đối tượng vận hành đã chọn trong danh sách';
								|ru = 'Для всех выбранных в списке объектов эксплуатации установлен новый класс';
								|en = 'A new class has been set for all the assets selected in the list'; fa = 'A new class has been set for all the assets selected in the list';
								|it = 'Nuova classe impostata per tutti gli oggetti d''uso operativo selezionati nell''elenco';
								|pl = 'Dla wszystkich wybranych na liście obiektów eksploatacji jest ustawiona nowa klasa';
								|tr = 'İşlem nesneleri listesinde seçilen tüm nesneler için yeni bir sınıf ayarlanır'");
		Else	
			MessageText = StrTemplate(NStr("vi = 'Đặt phân loại mới cho %1 trong số %2 đối tượng vận hành đã chọn';
											|ru = 'Для %1 из %2 выбранных в списке объектов эксплуатации установлен новый класс';
											|en = 'A new class has been set for %1 of %2 assets selected in the list'; fa = 'A new class has been set for %1 of %2 assets selected in the list';
											|it = 'Nuova classe impostata per %1 di %2 oggetti d''uso operativo selezionati nell''elenco';
											|pl = 'Dla %1 z %2 wybranych na liście obiektów eksploatacji jest ustawiona nowa klasa';
											|tr = 'İşlem listesinde %2''den seçilen %1nesneler için yeni bir sınıf ayarlandı'"),
					Result.ProcessedItemsCount, 
					TotalCount1);
		EndIf;

		TitleText = StrTemplate(NStr("vi = 'Đã đặt lớp ""%1""';
									|ru = 'Установлен класс ""%1""';
									|en = 'Class ""%1"" set'; fa = 'Class ""%1"" set';
									|it = 'Classe ""%1"" è stata impostata';
									|pl = 'Jest ustawiono klasę ""%1""';
									|tr = '""%1"" sınıfı ayarlandı'"), Result.ClassPresentation);

		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);

	Else
		
		If Result.ThereAreFillCheckingErrors Then
			MessageText = NStr("vi = 'Chưa đặt phân loại cho đối tượng vận hành nào.
			|Cần mở đối tượng vận hành và thực hiện kiểm tra điền.';
			|ru = 'Класс не установлен ни для одного объекта эксплуатации.
			|Необходимо открыть объект эксплуатации и выполнить проверку заполнения.';
			|en = 'The class is not set for any asset.
			|Open the asset and perform a filling check.'; fa = 'The class is not set for any asset.
			|Open the asset and perform a filling check.';
			|it = 'La classe non è stata impostata per nessun oggetto d''uso operativo.
			|È necessario aprire l''oggetto d''uso operativo ed eseguire un controllo di compilazione.';
			|pl = 'Klasa nie jest ustawiona dla żadnego obiektu eksploatacji.
			|Należy otworzyć obiekt eksploatacji i sprawdzić wypełnienie.';
			|tr = 'Sınıf herhangi bir varlık için ayarlanmamıştır.
			|Varlığı açmalı ve bir dolum kontrolü gerçekleştirmelisiniz.'");
		Else	
			MessageText = NStr("vi = 'Chưa đặt llớp phân loại cho đối tượng vận hành nào.';
								|ru = 'Класс не установлен ни для одного объекта эксплуатации.';
								|en = 'The class is not set for any asset.'; fa = 'The class is not set for any asset.';
								|it = 'La classe non è stata impostata per nessun oggetto d''uso operativo.';
								|pl = 'Klasa nie jest ustawiona dla żadnego obiektu eksploatacji.';
								|tr = 'Herhangi bir işletme nesnesi için sınıf belirlenmemiştir.'");
		EndIf;
		
		TitleText = StrTemplate(NStr("vi = 'Phân loại ""%1"" chưa đặt';
									|ru = 'Класс ""%1"" не установлен';
									|en = 'Class ""%1"" is not set'; fa = 'Class ""%1"" is not set';
									|it = 'La classe ""%1"" non è impostata';
									|pl = 'Klasa ""%1"" nie jest ustawiona';
									|tr = 'Sınıf ""%1"" ayarlanmadı'"), Result.ClassPresentation);
		
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf;

	Notify("Write_Assets");
	NotifyChanged(Type("CatalogRef.Assets"));
	
EndProcedure

Procedure SearchForNodesByBarcodeCompletion(BarcodeData_5, AdditionalParameters) Export
	
	ProcessInputOfBarcodes(
		BarcodeData_5, 
		AdditionalParameters.ProcessingProcedure, 
		AdditionalParameters.PickingParameters);
	
EndProcedure

Procedure SearchForObjectsOfOperationOrNodesByBarcodeCompletion(BarcodeData_5, AdditionalParameters) Export
	
	ProcessInputOfBarcodesOfObjectsOfOperationOrNodes(
		BarcodeData_5, 
		AdditionalParameters.ProcessingProcedure, 
		AdditionalParameters.PickingParameters);
	
EndProcedure

Procedure SelectionOfNodesByStrokeCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() <> 0 Then
		RunCallback(AdditionalParameters.ProcessingProcedure, Result);
	EndIf;
	
EndProcedure

#EndRegion
