
////////////////////////////////////////////////////////////////////////////////
// The "Invoice Client" module contains procedures and functions to
// support the filling of invoices and the functionality of document forms
// and invoice lists.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates an array of links based on the selected list lines, excluding groupings,
// and warns the user about the absence of selected lines.
//
// Parameters:
//  List 			- DynamicList - the list of the selected row which contain links for further processing.
//  Type_Invoice	- TypeDescription - a type description that contains the types of invoices that are present in the list.
//  OrderProperties_	- String - the list of properties you want to retrieve from the list.
//
// Returns:
//  Structure - contains two arrays "Orders" and "Invoices" containing links to the selected lines of the list.
//
Function LinksSelectedListRowsByType(List, Type_Invoice, OrderProperties_ = "") Export
	
	SelectedRows = List.SelectedRows;
	RowsIDs = New Array();
	
	If SelectedRows.Count() = 0 Then
		
		WarningText = NStr("vi = 'Để lập hóa đơn cần chọn một hoặc nhiều
		                                 |dòng trong danh sách lệnh cần lập.';
		                                 |ru = 'Для оформления накладных необходимо выделить одну или несколько
		                                 |строк в списке распоряжений к оформлению.';
		                                 |en = 'To register invoices, select one or several
		                                 |lines in the list of references to register.'; fa = 'To register invoices, select one or several
		                                 |lines in the list of references to register.';
		                                 |it = 'È necessario selezionare una o più
		                                 |righe nell''elenco degli ordini di progettazione per emettere le fatture.';
		                                 |pl = 'Do sporządzenia listów przewozowych należy wydzielić jeden lub kilka
		                                 |wierszy w liście zleceń do sporządzenia.';
		                                 |tr = 'İrsaliye düzenlemek için düzenlenecek siparişler listesinden bir veya daha fazla
		                                 |satır seç.'");
		ShowMessageBox(, WarningText);
		
	Else
		
		For Each Id In List.SelectedRows Do
			
			If TypeOf(Id) <> Type("DynamicListGroupRow") Then
				RowsIDs.Add(Id);
			EndIf;
			
		EndDo;
		
		If RowsIDs.Count() = 0 Then
			
			WarningText = NStr("vi = 'Lệnh để nhóm chuỗi không được cung cấp.';
								|ru = 'Выполнение команды для группировки строк не предусмотрено.';
								|en = 'Command execution for lines grouping is not available.'; fa = 'Command execution for lines grouping is not available.';
								|it = 'Non è possibile eseguire il comando per raggruppare le righe.';
								|pl = 'Wykonanie polecenia dla ugrupowania wierszy nie jest przewidziane.';
								|tr = 'Satırları gruplandırmak için komut gerçekleştirme öngörülmemiştir.'");
			ShowMessageBox(, WarningText);
			
		EndIf;
		
	EndIf;
	
	DocumentsByType = New Structure;
	DocumentsByType.Insert("Orders", New Array);
	DocumentsByType.Insert("Invoices", New Array);
	DocumentsByType.Insert("OrderCompliance", 0);
	DocumentsByType.Insert("InvoiceStatus", 0);
	DocumentsByType.Insert("OrderProperties_", New Array); // the values of the fields of the list line, if it is an order line
	DocumentsByType.Insert("Count", RowsIDs.Count());
	
	ThereIsInvoice = False;
	For Each Id In RowsIDs Do
		
		ListLine = List.RowData(Id);
		MatchingOrderInListLine = ListLine.OrderCompliance;
		InvoiceStateInListLine = ListLine.InvoiceStatus;
		
		Ref = ListLine.Ref;
		
		If Type_Invoice.ContainsType(TypeOf(Ref)) Then
			
			If Not ThereIsInvoice Then
				DocumentsByType.Invoices.Add(Ref);
				DocumentsByType.OrderCompliance = MatchingOrderInListLine;
				ThereIsInvoice = True;
			EndIf;
			
		Else
			
			DocumentsByType.Orders.Add(Ref);
			DocumentsByType.OrderCompliance = Max(DocumentsByType.OrderCompliance, MatchingOrderInListLine);
			DocumentsByType.InvoiceStatus = Max(DocumentsByType.InvoiceStatus, InvoiceStateInListLine);
			
			If OrderProperties_ <> "" Then
				OrderPropertyValues = New Structure(OrderProperties_);
				FillPropertyValues(OrderPropertyValues, ListLine);
				DocumentsByType.OrderProperties_.Add(OrderPropertyValues);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return DocumentsByType;
	
EndFunction

// Reports errors when creating an invoice based on orders if the header details of the orders do not match.
// Parameters:
//  ErrorsTexts - Array, String - An array of error texts or the text of a single error.
//
Procedure ReportErrorsInFillingInInternalInvoice(ErrorsTexts) Export
	
	ClearMessages();
	If TypeOf(ErrorsTexts) = Type("String") Then
		CommonClientServer.MessageToUser(ErrorsTexts,,,,);
	Else
		
		For Each ErrorText In ErrorsTexts Do
			
			CommonClientServer.MessageToUser(ErrorText,,,,);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Generates a list of groupings based on the selected lines in the list of orders, excluding incorrect States
// that contain the necessary information for processing the order invoice.
//
// Parameters:
//  OrderData_3	 - FormDataCollection - details on the form containing the details of the list of orders.
//  RowsIDs	 - Array - IDs of rows in the collection to be processed.
//  GroupFields		 - String - names of fields in the order data by which they should be grouped.
//  ErrorList		 - Structure - error list.
//  ErrorField			 - String - the value that is set in the field property of the message object to the User.
//  InvoiceMetadata_	 - FormDataCollection - table with fields:
//  												Economic operation - issued household. operation
//  												Key Field Caps - key Attributes of orders by which they can be grouped
//  												Full Document Name - the name of the document in the metadata
//  												of the header form - the header for the general form.Reissue of the waybills.
//	RemainingGoodsByShelfLives 		 - Boolean - attribute of the formation mode for the nomenclature (characteristic)
//
// Returns:
//  Array of Structure:
//  * AnArrayOfOrders - Array
//  * PopulationFields - Structure
//  * KeyHeaderFields - String
//  * NameOfDocumentBeingProcessed - String
//  * Handler - String
//  * ThereAreInvoices - Boolean
//  * ThisIsAnInvoice - Boolean
//  * TitleOfTheReissueForm - String
//  * Warehouse - CatalogRef.Warehouses
//  * ShippingSlip - DocumentRef
//  * ReceivingDocument - DocumentRef
//
Function DataForPlacingOrders(
			OrderData_3, 
			RowsIDs, 
			GroupFields, 
			ErrorList, 
			ErrorField, 
			InvoiceMetadata_, 
			RemainingGoodsByShelfLives = False) Export
	
	GroupingOrders = New Array;
	
	For Each RowID In RowsIDs Do
		
		String = OrderData_3.FindByID(RowID);
		ErrorText = "";
		
		If String.InvoiceStatus = 0 Then
			ErrorText = NStr("vi = 'Một hóa đơn đã được tạo cho đơn hàng  %1.';
							|ru = 'Для распоряжения %1 уже создана накладная.';
							|en = 'An invoice has already been created for the %1 reference.'; fa = 'An invoice has already been created for the %1 reference.';
							|it = 'Per la disposizione %1 è già creata una bolla.';
							|pl = 'Dla zamówienia %1 jest już utworzony list przewozowy.';
							|tr = '%1 emri için irsaliye artık oluşturuldu.'");
			ErrorText = StrTemplate(ErrorText, String.Ref);
		ElsIf String.InvoiceStatus = 4 Then
			ErrorText = NStr("vi = 'Đơn hàng %1 là hóa đơn. Không thể phát hành hóa đơn cho hóa đơn.';
							|ru = 'Распоряжение %1 является накладной. Невозможно оформить накладную по накладной.';
							|en = 'Reference %1 is an invoice. Cannot register an invoice for the invoice.'; fa = 'Reference %1 is an invoice. Cannot register an invoice for the invoice.';
							|it = 'La disposizione %1 è una fattura. Impossibile emettere una fattura per fattura.';
							|pl = 'Zamówienie %1 jest listem przewozowym. Niemożliwe jest sporządzenie listu przewozowego wg listu przewozowego.';
							|tr = '%1 emri bir irsaliyeye denk gelir. Bir irsaliye üzerine düzenlenme yapmak mümkün değildir.'");
			ErrorText = StrTemplate(ErrorText, String.Ref);
		EndIf;
		
		If IsBlankString(ErrorText) Then
			
			Group = GetDimension(GroupingOrders, String, GroupFields, InvoiceMetadata_, False);
			Group.AnArrayOfOrders.Add(String.Ref);
			
			If RemainingGoodsByShelfLives Then
				AddProductSelection(Group.PopulationFields, String.Ref, String.Products, String.Characteristic);
			EndIf;
			
		Else
			CommonClientServer.AddUserError(ErrorList, ErrorField, ErrorText, Undefined);
		EndIf;
		
	EndDo;
	
	If GroupingOrders.Count() = 0 And RowsIDs.Count() > 1 Then
		
		ErrorText = NStr("vi = 'Không có chứng từ đã được lựa chọn có thể được ban hành theo đơn đặt hàng.';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить по заказам.';
						|en = 'No documents selected which can be registered for orders.'; fa = 'No documents selected which can be registered for orders.';
						|it = 'Non è stato selezionato alcun documento da formalizzare.';
						|pl = 'Nie wybrano żadnego dokumentu, który można byłoby sporządzić wg zamówień.';
						|tr = 'Siparişlerde düzenlenebilecek hiçbir belge seçilmedi.'");
		CommonClientServer.AddUserError(ErrorList, ErrorField, ErrorText, Undefined);
		
	EndIf;
	
	Return GroupingOrders;
	
EndFunction

// Generates a list of groupings based on the selected lines in the list of orders, excluding incorrect States
// that contain the necessary information for processing an invoice for orders.
//
// Parameters:
//  OrderData_3	 - FormDataCollection - details on the form containing the details of the list of orders.
//  RowsIDs	 - Array - IDs of rows in the collection to be processed.
//  GroupFields		 - String - names of fields in the order data by which they should be grouped.
//  ErrorList		 - Structure - error list.
//  ErrorField			 - String - the value that is set in the field property of the message object to the User.
//  InvoiceMetadata_	 - FormDataCollection - table with fields:
//  												Economic operation - issued household. operation
//  												Key Field Caps - key Attributes of orders by which they can be grouped
//  												Full Document Name - the name of the document in the metadata
//  												of the header form - the header for the general form.Reissue of the waybills.
//	RemainingGoodsByShelfLives 		 - Boolean - attribute of the formation mode for the nomenclature (characteristic)
//
// Returns:
//  Array of Structure:
//  * AnArrayOfOrders - Array
//  * PopulationFields - Structure
//  * KeyHeaderFields - String
//  * NameOfDocumentBeingProcessed - String
//  * Handler - String
//  * ThereAreInvoices - Boolean
//  * ThisIsAnInvoice - Boolean
//  * TitleOfTheReissueForm - String
//  * Warehouse - CatalogRef.Warehouses
//  * ShippingSlip - DocumentRef
//  * ReceivingDocument - DocumentRef
//
Function DataForProcessingOrders(
			OrderData_3, 
			RowsIDs, 
			GroupFields, 
			ErrorList, 
			ErrorField, 
			InvoiceMetadata_, 
			RemainingGoodsByShelfLives = False) Export
	
	GroupingOrders          = New Array;
	SimultaneouslyIssuedInvoices = New Map;
	ValueIDs           = New Map;
	StructureOfDimensionFields        = New Structure(
		"Ref" + ?(ValueIsFilled(GroupFields), ",", "") + GroupFields);
	
	For Each RowID In RowsIDs Do
		
		String = OrderData_3.FindByID(RowID);
		ErrorText = "";
		
		If String.ShippingSlip And String.ReceivingDocument Then
			ByNotes = NStr("vi = 'trên lô hàng (chấp nhận)';
							|ru = 'по отгрузке (приемке)';
							|en = 'by shipment (receiving)'; fa = 'by shipment (receiving)';
							|it = 'in base alla spedizione (accettazione)';
							|pl = 'wg wysyłki (odbioru)';
							|tr = 'sevkiyata göre (tedarik)'");
		ElsIf String.ShippingSlip Then
			ByNotes = NStr("vi = 'theo giao hàng';
							|ru = 'по отгрузке';
							|en = 'by shipment'; fa = 'by shipment';
							|it = 'per la spedizione';
							|pl = 'wg wysyłki';
							|tr = 'sevkiyata göre'");
		ElsIf String.ReceivingDocument Then
			ByNotes = NStr("vi = 'theo nhập kho';
							|ru = 'по приемке';
							|en = 'by receipt'; fa = 'by receipt';
							|it = 'accettazione';
							|pl = 'wg odbioru';
							|tr = 'tedariğe göre'");
		EndIf;
		
		If (String.GoodsIssueNoteState = 0 Or Not String.ShippingSlip)
			And (String.GoodsReceiptNoteState = 0 Or Not String.ReceivingDocument) Then
			ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể phát hành hóa đơn %2, vì đơn hàng tương ứng với hóa đơn.';
							|ru = 'Для распоряжения %1 невозможно оформить накладную %2, т.к. ордера соответствуют накладным.';
							|en = 'Cannot register the %2 invoice for the %1 reference as notes correspond to the invoices.'; fa = 'Cannot register the %2 invoice for the %1 reference as notes correspond to the invoices.';
							|it = 'Per la disposizione %1 non è possibile rifinire la bolla %2, poiché i mandati corrispondono alle bolle.';
							|pl = 'Dla zamówienia %1 niemożliwe jest sporządzenie listu przewozowego %2, ponieważ zlecenia odpowiadają listom przewozowym.';
							|tr = '%1 siparişi için %2 irsaliyesi düzenlemek mümkün değil çünkü emirler irsaliyelere uygun gelir.'");
			ErrorText = StrTemplate(ErrorText, String.Ref, ByNotes);
		ElsIf (String.GoodsIssueNoteState = 1 Or Not String.ShippingSlip)
			And (String.GoodsReceiptNoteState = 1 Or Not String.ReceivingDocument) Then
			ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể phát hành hóa đơn %2, vì không có đơn đặt hàng.';
							|ru = 'Для распоряжения %1 невозможно оформить накладную %2, т.к. нет ни одного ордера.';
							|en = 'Cannot register the %2 invoice for the %1 reference as there are no notes.'; fa = 'Cannot register the %2 invoice for the %1 reference as there are no notes.';
							|it = 'Per la disposizione %1 non è possibile rifinire la bolla %2, poiché non c''è nessun mandato.';
							|pl = 'Dla zamówienia %1 niemożliwe jest sporządzenie listu przewozowego %2, ponieważ nie ma żadnego zlecenia.';
							|tr = '%1 siparişi için %2 irsaliyesi düzenlemek mümkün değil çünkü hiç bir emir mevcut değil.'");
			ErrorText = StrTemplate(ErrorText, String.Ref, ByNotes);
		ElsIf (String.GoodsIssueNoteState = 4 Or Not String.ShippingSlip)
			And (String.GoodsReceiptNoteState = 4 Or Not String.ReceivingDocument) Then
			ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể phát hành hóa đơn %2, vì đơn đặt hàng không được sử dụng.';
							|ru = 'Для распоряжения %1 невозможно оформить накладную %2, т.к. ордера не используются.';
							|en = 'Cannot register the %2 invoice for the %1 reference as notes are not used.'; fa = 'Cannot register the %2 invoice for the %1 reference as notes are not used.';
							|it = 'Per la disposizione %1 non è possibile rifinire la bolla %2, poiché i mandati non si usano.';
							|pl = 'Dla zamówienia %1 niemożliwe jest sporządzenie listu przewozowego %2, ponieważ zlecenia nie są stosowane.';
							|tr = '%1 siparişi için %2 irsaliyesi düzenlemek mümkün değil çünkü emirler kullanılmıyor.'");
			ErrorText = StrTemplate(ErrorText, String.Ref, ByNotes);
		EndIf;
		
		If IsBlankString(ErrorText) Then
			If String.InvoiceStatus = 4 Then
				
				KeyArray = New Array;
				For Each StructureItem In StructureOfDimensionFields Do
					
					Id = ValueIDs.Get(String[StructureItem.Key]);
					If Id = Undefined Then
						ValueIDs.Insert(String[StructureItem.Key], New UUID);
						Id = ValueIDs.Get(String[StructureItem.Key]);
					EndIf;	
					
					KeyArray.Add(Id);
					
				EndDo;	
				
				DataKey = StrConcat(KeyArray, "\");
				
				DataOfIssuedInvoices = SimultaneouslyIssuedInvoices.Get(DataKey);
				If DataOfIssuedInvoices = Undefined Then
					SimultaneouslyIssuedInvoices.Insert(DataKey, New Array);
					DataOfIssuedInvoices = SimultaneouslyIssuedInvoices.Get(DataKey);
				EndIf;
				
				DataOfIssuedInvoices.Add(String);
				
			Else
				Group = GetDimension(GroupingOrders, String, GroupFields, InvoiceMetadata_, True);
				Group.AnArrayOfOrders.Add(String.Ref);
				Group.ThereAreInvoices = Group.ThereAreInvoices Or (String.InvoiceStatus <> 1);
				
				If RemainingGoodsByShelfLives Then
					AddProductSelection(Group.PopulationFields, String.Ref, String.Products, String.Characteristic);
				EndIf;	
				
			EndIf;
		Else
			CommonClientServer.AddUserError(ErrorList, ErrorField, ErrorText, Undefined);
		EndIf;
		
	EndDo;
	
	If SimultaneouslyIssuedInvoices.Count() > 1 Or ValueIsFilled(GroupingOrders) Then
		
		For Each DataOfIssuedInvoices In SimultaneouslyIssuedInvoices Do
			
			String = DataOfIssuedInvoices.Value[0];
				
			ErrorText = NStr("vi = 'Không thể xử lý đồng thời %1 hóa đơn %2 cùng với các đơn hàng khác. Chọn hóa đơn riêng.';
							|ru = 'Одновременное оформление %1 накладной %2 вместе с другими распоряжениями невозможно. Выберите накладную отдельно.';
							|en = 'Cannot register the %1 invoice %2 with other references simultaneously. Select the invoice separately.'; fa = 'Cannot register the %1 invoice %2 with other references simultaneously. Select the invoice separately.';
							|it = 'La progettazione simultanea %1 della fattura %2 insieme ad altri ordini non è possibile. Selezionare la fattura separatamente.';
							|pl = 'Jednoczesne sporządzenie %1 listu przewozowego %2 razem z innymi zamówieniami jest niemożliwe. Wybierz list przewozowy oddzielnie.';
							|tr = 'Diğer siparişlerle birlikte %1 irsaliyenin %2 aynı anda düzenlenmesi mümkün değil. İrsaliyeyi ayrıca seç.'");
			ErrorText = StrTemplate(ErrorText, ByNotes, String.Ref);
			
			CommonClientServer.AddUserError(ErrorList, ErrorField, ErrorText, Undefined);
				
		EndDo;	
		
	ElsIf SimultaneouslyIssuedInvoices.Count() = 1 Then
		
		For Each DataOfIssuedInvoices In SimultaneouslyIssuedInvoices Do
			
			For Each String In DataOfIssuedInvoices.Value Do

				CorrectiveDocument = DocumentCorrectionServerCall.LastCorrectiveDocument(String.Ref);

				If CorrectiveDocument = Undefined Then

					Group = GetDimension(GroupingOrders, String, GroupFields, InvoiceMetadata_, True);
					Group.AnArrayOfOrders.Add(String.Ref);
					Group.Insert("ThisIsAnInvoice", True);

					If RemainingGoodsByShelfLives Then
						AddProductSelection(Group.PopulationFields, String.Ref, String.Products, String.Characteristic);
					EndIf;

				Else

					InvoiceMetadata = InvoiceMetadata_.FindRows(New Structure("BusinessOperation", String.BusinessOperation))[0];
					NameOfDocumentBeingProcessed = StrReplace(InvoiceMetadata.FullDocumentName, "Document.", "");

					WarningAboutPresenceOfFix(CorrectiveDocument.Ref, "Document." + NameOfDocumentBeingProcessed + ".ObjectForm");

				EndIf;

			EndDo;
			
		EndDo;
		
	EndIf;
	
	If GroupingOrders.Count() = 0 And RowsIDs.Count() > 1 Then
		
		ErrorText = NStr("vi = 'Không có chứng từ đã được lựa chọn có thể được ban hành theo đơn đặt hàng.';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить по ордерам.';
						|en = 'No documents selected which can be registered by notes.'; fa = 'No documents selected which can be registered by notes.';
						|it = 'Non è stato selezionato alcun documento da formalizzare su nota.';
						|pl = 'Nie wybrano żadnego dokumentu, który można byłoby sporządzić na asygnaty.';
						|tr = 'Emirlerle düzenlenebilecek hiç bir belge seçilmedi.'");
		CommonClientServer.AddUserError(ErrorList, ErrorField, ErrorText, Undefined);
		
	EndIf;
	
	Return GroupingOrders;
	
EndFunction

// Opens the registration form or a list of already completed documents.
//
// Parameters:
//  ParametersOfCreatedDocuments - Structure - containing the "Formname" and "Parameters" fields.
//  Owner					 - Form - the form element is the owner of the form that is being opened.
//
Procedure OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, Owner) Export
	
	If ParametersOfCreatedDocuments = Undefined Then
		
		Return;
		
	ElsIf ParametersOfCreatedDocuments.Property("NumberOfDocumentsCreated") Then
		
		If ParametersOfCreatedDocuments.NumberOfDocumentsCreated = 0 Then
			Return;
		EndIf;
		
		NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
								|ru = 'Создано документов: %1';
								|en = 'Created documents: %1'; fa = 'Created documents: %1';
								|it = 'Documenti creati: %1';
								|pl = 'Utworzono dokumentów: %1';
								|tr = 'Oluşturulan belgeler: %1'");
		NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.NumberOfDocumentsCreated);
		ShowUserNotification(NStr("vi = 'Tạo chứng từ';
									|ru = 'Создание документов';
									|en = 'Create documents'; fa = 'ایجاد اسناد';
									|it = 'Creazione documenti';
									|pl = 'Utworzenie dokumentów';
									|tr = 'Belgelerin oluşturulması'"),, NotificationText1);
		
	EndIf;
		
	OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, Owner);
	
EndProcedure

// A warning about the presence of a correction when reissuing the invoice.
// 
// Parameters:
//     CorrectiveBillOfLading - DocumentRef - The last correction document.
//     FormName - String - Name of the correction document form.
//
Procedure WarningAboutPresenceOfFix(CorrectiveBillOfLading, FormName) Export
	
	CaptionInfoTitle = StrTemplate(NStr("vi = 'Không thể điền lại hóa đơn, vì theo đó đã nhập hóa đơn chỉnh sửa: %1';
										|ru = 'Накладную нельзя перезаполнить, так как для нее введена исправительная накладная: %1';
										|en = 'Cannot refill the invoice as a corrective invoice is created for it: %1'; fa = 'Cannot refill the invoice as a corrective invoice is created for it: %1';
										|it = 'Накладную нельзя перезаполнить, так как для нее введена исправительная накладная: %1';
										|pl = 'Cannot refill the invoice as a corrective invoice is created for it: %1';
										|tr = 'Bir düzeltme notu girildiği için sevk irsaliyesi yeniden doldurulamaz: %1'"),
		String(CorrectiveBillOfLading));
	ButtonsList = New ValueList;
	ButtonsList.Add("GoToCorrectionInvoice", NStr("vi = 'Chuyển đến hóa đơn chỉnh sửa';
													|ru = 'Перейти к исправительной накладной';
													|en = 'Go to the corrective invoice'; fa = 'Go to the corrective invoice';
													|it = 'Перейти к исправительной накладной';
													|pl = 'Go to the corrective invoice';
													|tr = 'Düzeltme faturasına git'"));
	ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Отмена';
									|pl = 'Cancel';
									|tr = 'İptal'"));
	
	Context = New Structure;
	Context.Insert("CorrectiveBillOfLading", CorrectiveBillOfLading);
	Context.Insert("FormName", FormName);

	CallbackDescription = New CallbackDescription("WarningAboutPresenceOfFixCompletion", ThisObject, Context);

	ShowQueryBox(CallbackDescription, CaptionInfoTitle, ButtonsList);

EndProcedure

// Handler of the result of the operation of the procedure for the notification of a correction.
// 
// Parameters:
//  QuestionResult        - DialogReturnCode - The result of the question.
//  AdditionalParameters - Structure          - parameters of the Command being executed.
//
Procedure WarningAboutPresenceOfFixCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "GoToCorrectionInvoice" Then
		OpenForm(AdditionalParameters.FormName, New Structure("Key", AdditionalParameters.CorrectiveBillOfLading));
	EndIf;
	
EndProcedure


#EndRegion

#Region Private

Function GetDimension(ArrayOfDimensions, String, GroupFields, InvoiceMetadata_, ByNote)
	
	For Each Group In ArrayOfDimensions Do
		If TMCommonUseClientServer.StructuresAreEqual(Group.PopulationFields, String, GroupFields) Then
			Return Group;
		EndIf;
	EndDo;
	
	FieldsForFillingInDimensions = New Structure(GroupFields);
	Group = New Structure("AnArrayOfOrders,PopulationFields", New Array, FieldsForFillingInDimensions);
	FillPropertyValues(Group.PopulationFields, String);
	Group.PopulationFields.Insert("FillByWarehouseDocument", ByNote);
	
	InvoiceMetadata = InvoiceMetadata_.FindRows(New Structure("BusinessOperation", String.BusinessOperation))[0];
	Group.Insert("KeyHeaderFields", InvoiceMetadata.KeyHeaderFields);
	Group.Insert("NameOfDocumentBeingProcessed", StrReplace(InvoiceMetadata.FullDocumentName, "Document.", ""));
	Group.Insert("Handler");
	InvoiceMetadata.Property("Handler", Group.Handler);
	
	If ByNote Then
		Group.Insert("ThereAreInvoices", False);
		Group.Insert("ThisIsAnInvoice", False);
		Group.Insert("TitleOfTheReissueForm", InvoiceMetadata.TitleOfTheReissueForm);
		Group.Insert("Warehouse", String.Warehouse);
		Group.Insert("ShippingSlip", String.ShippingSlip);
		Group.Insert("ReceivingDocument", String.ReceivingDocument);
	EndIf;
	
	ArrayOfDimensions.Add(Group);
	
	Return Group;
	
EndFunction

Procedure AddProductSelection(StructureOfSupplement, ReferenceOrder, Products, Characteristic)
	
	FilterByGoods = Undefined;
	StructureOfSupplement.Property("FilterByGoods", FilterByGoods);
	If FilterByGoods = Undefined Then
		FilterByGoods = New Map;	
	EndIf;	
	
	SelectionByOrderItems = FilterByGoods.Get(ReferenceOrder);
	If SelectionByOrderItems = Undefined Then
		FilterByGoods.Insert(ReferenceOrder, New Structure);
		SelectionByOrderItems = FilterByGoods.Get(ReferenceOrder);
	EndIf;
	
	DataKey = "_" + StrReplace(Products.UUID()   , "-" , "x")
			   + "_" + StrReplace(Characteristic.UUID() , "-" , "x");
	
	If Not SelectionByOrderItems.Property(DataKey) Then
		
		StructureOfData = New Structure("Products, Characteristic", 
										   Products, 
										   Characteristic);
										   
		SelectionByOrderItems.Insert(DataKey, StructureOfData);
		
		StructureOfSupplement.Insert("FilterByGoods", FilterByGoods);		
		
	EndIf;			   
	
EndProcedure	

#EndRegion
