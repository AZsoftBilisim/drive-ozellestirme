
////////////////////////////////////////////////////////////////////////////////
// The "Invoice Server" module contains procedures and functions to
// support filling in invoices and functionality of document forms
// and invoice lists.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// For the passed grouping, returns parameters for opening the invoice form to be reissued for orders.
// See InvoicesClient.OpenFormForCreatedDocuments.
//
// Parameters:
//  ProcedureParameters - Structure - structure with fields:
//   *GroupingOrders            - Array - contains arrays of groups of orders to create a document for
//  															See InvoicesClient.DataForPlacingOrders.
//   *FormParametersForCreatedDocuments	 - Structure - parameters for the General Form.Forms of created documents.
//   *ErrorField						 - String - the value that is set in the field property of the message object to the User.
//  ResultAddress - String - The address in the temporary storage. Contains a structure with fields:
//   * ParametersOfCreatedDocuments - Structure - structure with fields:
//     ** FormName	 - String    - name of the form to open
//  	** Parameters - Structure - Parameters of the form to open
//   * ErrorList - See CommonClientServer.AddUserError
//
Procedure IssueInvoicesForOrdersInBackground_(ProcedureParameters, ResultAddress) Export
	
	GroupingOrders           = ProcedureParameters.GroupingOrders;
	FormParametersForCreatedDocuments = ProcedureParameters.FormParametersForCreatedDocuments;
	ErrorField                        = ProcedureParameters.ErrorField;
	Result = IssueInvoicesForOrders_(GroupingOrders, FormParametersForCreatedDocuments, ErrorField);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// For the passed grouping, returns parameters for opening the invoice form for orders.
// See InvoicesClient.OpenFormForCreatedDocuments.
//
// Parameters:
//  ProcedureParameters - Structure - structure with fields:
//   *GroupingOrders            - Array - contains arrays of groups of orders to create a document for
//  															See InvoicesClient.DataForPlacingOrders.
//   *FormParametersForCreatedDocuments	 - Structure - parameters for the General Form.Forms of created documents.
//   *ErrorField						 - String - the value that is set in the field property of the message object to the User.
//  ResultAddress - String - The address in the temporary storage. Contains a structure with fields:
//   * ParametersOfCreatedDocuments - Structure - structure with fields:
//     ** FormName	 - String    - name of the form to open
//  	** Parameters - Structure - Parameters of the form to open
//   * ErrorList - See CommonClientServer.AddUserError
//
Procedure IssueInvoicesForOrdersInBackground(ProcedureParameters, ResultAddress) Export
	
	GroupingOrders           = ProcedureParameters.GroupingOrders;
	FormParametersForCreatedDocuments = ProcedureParameters.FormParametersForCreatedDocuments;
	ErrorField                        = ProcedureParameters.ErrorField;
	Result = IssueInvoicesForOrders(GroupingOrders, FormParametersForCreatedDocuments, ErrorField);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Draws up reports of discrepancies for submitted invoices and orders.
//
// Parameters:
//  ProcedureParameters - Structure - structure with fields:
//   *Invoices                         - Array - overhead.
//   *Orders                            - Array - orders.
//   *FormParametersForCreatedDocuments - Structure - parameters for the General Form.Forms of created documents.
//   *ErrorField						- String - the value that is set in the field property of the message object to the User.
//  ResultAddress - String - The address in the temporary storage. Contains a structure with fields:
//   * ParametersOfCreatedDocuments - Structure - structure with fields:
//     ** FormName	 - String    - name of the form to open
//  	** Parameters - Structure - Parameters of the form to open
//   * ErrorList - See CommonClientServer.AddUserError
//
Procedure IssueReportsOnDiscrepanciesInBackground(ProcedureParameters, ResultAddress) Export

	Invoices                         = ProcedureParameters.Invoices;
	Orders                            = ProcedureParameters.Orders;
	FormParametersForCreatedDocuments = ProcedureParameters.FormParametersForCreatedDocuments;
	ErrorField                        = ProcedureParameters.ErrorField;

	Result = RegisterDiscrepancyCertificate(Invoices, Orders, FormParametersForCreatedDocuments, ErrorField);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Fills in the header of the order/order matching command.
//
// Parameters:
//   Item              - FormAllItems - element for filling in the header.
//   Parameters            - Structure        - structure with fields:
//    * AdvancedWarehousingOnShipment                 - Boolean - the value of the corresponding FO for the document type.
//    * OrdersUse                       - Boolean - the value of the corresponding FO for the document type.
//    * UseInvoicesForSeveralOrders - Boolean - the value of the corresponding FO for the document type.
//   SetAvailability_                    - Boolean - true if the item's availability is to be updated.
//
Procedure ConfigurePickUpByOrdersOrdersCommand(Item, Parameters, SetAvailability_ = True) Export
	
	If SetAvailability_ Then
		Item.Visible = Parameters.AdvancedWarehousingOnShipment Or Parameters.OrdersUse;
	EndIf;
	
	If Parameters.OrdersUse Then
		
		If Parameters.AdvancedWarehousingOnShipment Then
			
			Item.Title = ?(Parameters.UseInvoicesForSeveralOrders,
				NStr("vi = 'Chọn hàng hóa theo đơn hàng/phiếu kho';
					|ru = 'Подобрать товары по заказам/ордерам';
					|en = 'Pick goods by orders/notes'; fa = 'انتخاب کالا بر اساس سفارش‌ها/یادداشت‌ها';
					|it = 'Seleziona le merci in base agli ordini/mandati';
					|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
					|tr = 'Emir/siparişlere göre mal seçme'"),
				NStr("vi = 'Chọn hàng hóa theo đơn hàng/phiếu kho';
					|ru = 'Подобрать товары по заказу/ордерам';
					|en = 'Pick goods by order/notes'; fa = 'Pick goods by order/notes';
					|it = 'Seleziona le merci in base all''ordine/mandati';
					|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
					|tr = 'Ürünleri siparişe/emire  göre seç'"));
			
		Else
			
			Item.Title = ?(Parameters.UseInvoicesForSeveralOrders,
				NStr("vi = 'Nhận hàng theo đơn đặt hàng';
					|ru = 'Подобрать товары по заказам';
					|en = 'Pick goods by orders'; fa = 'Pick goods by orders';
					|it = 'Selezionare le merci per ordini';
					|pl = 'Wybierz wiersze pozycji wg zamówień';
					|tr = 'Siparişe göre malları seç'"),
				NStr("vi = 'Nhận hàng theo đơn đặt hàng';
					|ru = 'Подобрать товары по заказу';
					|en = 'Pick goods against the order'; fa = 'Pick goods against the order';
					|it = 'Selezionare le merci per ordine';
					|pl = 'Wybierz wiersze pozycji wg zamówienia';
					|tr = 'Ürünleri siparişe göre seç'"));
			
		EndIf;
		
	Else
		
		Item.Title = NStr("vi = 'Chọn sản phẩm theo đơn đặt hàng';
							|ru = 'Подобрать товары по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezionare le merci in base ai mandati';
							|pl = 'Wybierz wiersze pozycji wg zleceń';
							|tr = 'Emirlere göre mal seçme'");
		
	EndIf;
	
EndProcedure

// Checks whether there are spending orders on the order.
//
// Parameters:
//  References - DocumentRef - array of orders.
//  ItIsGoingToTakeIntoAccount - Boolean - the need to account for orders in the status is Collected.
//
// Returns:
//  Boolean - True if there are orders, False if there are no orders.
//
Function ThereIsSpendingOrderForShippingOrders(References, ItIsGoingToTakeIntoAccount = True) Export
	
	Query = New Query();
	Query.Text =
		"SELECT TOP 1
		|	1
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(, , , ,
		|	DocumentShipments IN (&Orders)
		|	AND Warehouse IN(
		|		SELECT
		|			CatWarehouses.Ref AS Warehouse
		|		FROM
		|			Catalog.Warehouses AS CatWarehouses
		|		WHERE
		|			CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue
		|			AND CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)) AS Table
		|WHERE
		|	Table.ToShipExpense + Table.AssembledReceipt + Table.AssemblyInProgressReceipt > 0";
	
	If Not ItIsGoingToTakeIntoAccount Then
		Query.Text = StrReplace(Query.Text, "+ Table.AssemblyInProgressReceipt", "");
	EndIf;
	
	Query.SetParameter("Orders", References);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Deducts the quantity for processing orders from the quantity for processing orders.
//
// Parameters:
//  DestinationTable - ValueTable - a table containing data for placing orders.
//  SourceTable1 - ValueTable - a table containing data for processing orders.
//  KeyFields - String - key for linking tables for debiting.
//
Procedure FillInQuantityIndicatorForOrders(DestinationTable, SourceTable1, KeyFields) Export
	
	// Support for "old" assignments that do not pass through the warehouse.
	NameOfDestinationField = NameOfDestinationField(DestinationTable, KeyFields);
	AddTrafficColumnForWarehouseRegisters(DestinationTable, KeyFields);
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	
	If DestinationTable.Columns.Find("NoteQuantity") = Undefined Then
		DestinationTable.Columns.Add("NoteQuantity", TMCommonUse.DescriptionOfQuantitativeFieldType());
	EndIf;
	If DestinationTable.Columns.Find("AssemblyInProgress") = Undefined Then
		DestinationTable.Columns.Add("AssemblyInProgress", TMCommonUse.DescriptionOfQuantitativeFieldType());
	EndIf;
	
	SourceTable1.Indexes.Add(KeyFields);
	SearchParameters = New Structure(KeyFields);
	
	// Attempt to save the quantity in the invoice.
	For Each DestinationRow In DestinationTable Do
		
		FillPropertyValues(SearchParameters, DestinationRow);
		If Not DestinationRow.RecordsInWarehouseRegisters Then
			SearchParameters[NameOfDestinationField] = EmptyAssignment;
		EndIf;
		FoundRows = SourceTable1.FindRows(SearchParameters);
		
		If FoundRows.Count() > 0 Then
			
			SourceRow = FoundRows[0];
			DestinationRow.AssemblyInProgress = SourceRow.AssemblyInProgress;
			WriteOffQuantity = Min(SourceRow.Count,
				?(DestinationRow.QuantityInInvoice > 0, Max(DestinationRow.QuantityInInvoice, DestinationRow.QuantityInOrder), 0));
			If WriteOffQuantity > 0 Then
				
				DestinationRow.NoteQuantity = WriteOffQuantity;
				SourceRow.Count = SourceRow.Count - WriteOffQuantity;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Addition of the shipment to the order.
	For Each DestinationRow In DestinationTable Do
		
		FillPropertyValues(SearchParameters, DestinationRow);
		If Not DestinationRow.RecordsInWarehouseRegisters Then
			SearchParameters[NameOfDestinationField] = EmptyAssignment;
		EndIf;
		FoundRows = SourceTable1.FindRows(SearchParameters);
		
		If FoundRows.Count() > 0 Then
			
			SourceRow = FoundRows[0];
			WriteOffQuantity = Min(SourceRow.Count, DestinationRow.QuantityInOrder - DestinationRow.NoteQuantity);
			If WriteOffQuantity > 0 Then
				
				DestinationRow.NoteQuantity = DestinationRow.NoteQuantity + WriteOffQuantity;
				SourceRow.Count = SourceRow.Count - WriteOffQuantity;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Adding lines in excess of the order.
	For Each SourceRow In SourceTable1 Do
		
		If SourceRow.Count > 0 Then
			
			WriteOffQuantity = SourceRow.Count;
			
			DestinationRow = DestinationTable.Add();
			FillPropertyValues(DestinationRow, SourceRow);
			DestinationRow.NoteQuantity = WriteOffQuantity;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the table according to the filling option (according to order data or order data).
//
// Parameters:
//  Receiver - ValueTable - a table with the required columns "Quantity" and "Number of packages".
//  Source - ValueTable - a table containing data for processing orders, or orders and orders.
//  FillingVariant - String - "Fill in the order" - if you need to fill in the order.
//  AddLines_ - Boolean - the ability to add drains in excess of the order to the invoice.
Procedure FillInOption(Receiver, Source, FillingVariant, AddLines_ = True) Export
	
	For Each TableRow In Source Do
		
		If FillingVariant = "FillByWarehouseDocument" And TableRow.NoteQuantity = 0 Then
			Continue;
		EndIf;
		
		If AddLines_ Then
			NewRow = Receiver.Add();
		Else
			NewRow = Receiver;
		EndIf;
		
		If FillingVariant = "FillByWarehouseDocument" Then
			FillInLineByOption(NewRow, TableRow, TableRow.NoteQuantity);
		ElsIf FillingVariant = "FillByOrderDocument" Then
			FillInLineByOption(NewRow, TableRow, TableRow.QuantityInOrder);
		EndIf;
		
	EndDo;
	
EndProcedure

// Calculates how to fill out the invoice, for orders or orders.
//
// Parameters:
//  Warehouse - CatalogRef.Warehouses - design warehouse.
//
// Returns:
//  Boolean - True if filled in by order, False if filled in by order.
//
Function FillByWarehouseDocument(Warehouse) Export
	
	Return WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Warehouse, CurrentSessionDate())
		And Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() =
			Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst;
	
EndFunction

#Region CWPDesign

// Splits documents of the same type into groups by key fields.
//
// Parameters:
//  DocumentsForGrouping	 - Array - containing links to documents.
//  KeyFields				 - String - lists the document details that will be used for grouping.
Procedure GroupDocumentsByKeyFields(DocumentsForGrouping, KeyFields) Export
	
	If Not ValueIsFilled(DocumentsForGrouping) Then
		Return;
	EndIf;
	
	Query = New Query(QueryTextGroups(KeyFields, DocumentsForGrouping, "TTRawData", "Documents"));
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Documents", DocumentsForGrouping);
	
	Selection = Query.Execute().Select();
	
	Filter = New Structure(KeyFields);
	
	SourceTable = Query.TempTablesManager.Tables[0].GetData().Unload();
	SourceTable.Indexes.Add(KeyFields);
	
	DocumentsForGrouping.Clear();
	While Selection.Next() Do
		FillPropertyValues(Filter, Selection);
		DocumentsArray = SourceTable.FindRows(Filter);
		For IndexOf = 0 To DocumentsArray.UBound() Do
			DocumentsArray[IndexOf] = DocumentsArray[IndexOf].Ref;
		EndDo;
		DocumentsForGrouping.Add(DocumentsArray);
	EndDo;
	
EndProcedure

// Splits documents of the same type into groups by key fields in the collection.
//
// Parameters:
//  Collection						 - Array - array of structures.
//  NameOfDocumentArrayInCollection	 - String - name of the collection field containing an array of links to documents.
//  FieldNameOfKeyFieldsInCollection	 - String - the name of the collection field that contains a string listing the document details that will be used for grouping.
//  FieldNameOfKeyFieldsAdaptedInCollection - String - name of the collection field containing a string with adapted field values that are mapped to the document details.
Procedure GroupDocumentsByKeyFieldsInCollection(
			Collection, 
			NameOfDocumentArrayInCollection, 
			FieldNameOfKeyFieldsInCollection, 
			FieldNameOfKeyFieldsAdaptedInCollection = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	IndexOf = 0;
	Package = New Array;
	For Each Value In Collection Do
		
		Package.Add(QueryTextGroups(Value[FieldNameOfKeyFieldsInCollection],
			Value[NameOfDocumentArrayInCollection],
			"TTRawData" + IndexOf, "Documents" + IndexOf,
			?(ValueIsFilled(FieldNameOfKeyFieldsAdaptedInCollection), Value[FieldNameOfKeyFieldsAdaptedInCollection], Undefined)));
		Query.SetParameter("Documents" + IndexOf, Value[NameOfDocumentArrayInCollection]);
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	Query.Text = StrConcat(Package, Common.QueryBatchSeparator());
	QueryResult = Query.ExecuteBatch();
	
	IndexOf = 0;
	For Each Value In Collection Do
		
		Filter = New Structure(Value[FieldNameOfKeyFieldsInCollection]);
		
		SourceTable = Query.TempTablesManager.Tables[IndexOf].GetData().Unload();
		SourceTable.Indexes.Add(Value[FieldNameOfKeyFieldsInCollection]);
		
		Value[NameOfDocumentArrayInCollection].Clear();
		
		Selection = QueryResult[2*IndexOf + 1].Select();
		While Selection.Next() Do
			FillPropertyValues(Filter, Selection);
			DocumentsArray = SourceTable.FindRows(Filter);
			For ArrayIndex = 0 To DocumentsArray.UBound() Do
				DocumentsArray[ArrayIndex] = DocumentsArray[ArrayIndex].Ref;
			EndDo;
			Value[NameOfDocumentArrayInCollection].Add(DocumentsArray);
		EndDo;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
EndProcedure

// Description of states:
// 0 - the document is issued in full
// 1 - the document is not issued
// 2 - the document is partially executed
// 3 - the order does not correspond to the document
// 4 - is not used.

// Fills the passed list with the values of invoice States in the RM
//
// Parameters:
//  ChoiceList	 - ValueList - a list to fill in.
//  ActiveOnly	 - Boolean - when set to True, it does not fill in the States that do not require registration (0 and 4).
//
Procedure FillInInvoiceStates(ChoiceList, ActiveOnly = False) Export
	
	ChoiceList.Clear();
	If ActiveOnly Then
		ChoiceList.Add("1", NStr("vi = 'Tạo hóa đơn bán hàng';
								|ru = 'Создать накладную';
								|en = 'Create invoice'; fa = 'ایجاد فاکتور';
								|it = 'Creare una bolla';
								|pl = 'Utwórz list przewozowy';
								|tr = 'İrsaliye oluştur'"),      False, PictureLib.CreateInvoice);
		ChoiceList.Add("2", NStr("vi = 'Gia hạn hóa đơn';
								|ru = 'Дооформить накладную';
								|en = 'Pending issue/receipt'; fa = 'Pending issue/receipt';
								|it = 'Completare la bolla';
								|pl = 'Sporządź do końca list przewozowy';
								|tr = 'İrsaliyeyi tamamla'"),   False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
	Else
		ChoiceList.Add("0", NStr("vi = 'Đã lập tất cả';
								|ru = 'Все оформлено';
								|en = 'Fully issued/received'; fa = 'Fully issued/received';
								|it = 'Formalizzato tutto';
								|pl = 'Wszystko jest sporządzone';
								|tr = 'Tümü düzenlenmiş'"),          False, PictureLib.ExecutedSuccessfully);
		ChoiceList.Add("1", NStr("vi = 'Tạo hóa đơn bán hàng';
								|ru = 'Создать накладную';
								|en = 'Create invoice'; fa = 'ایجاد فاکتور';
								|it = 'Creare una bolla';
								|pl = 'Utwórz list przewozowy';
								|tr = 'İrsaliye oluştur'"),      False, PictureLib.CreateInvoice);
		ChoiceList.Add("2", NStr("vi = 'Gia hạn hóa đơn';
								|ru = 'Дооформить накладную';
								|en = 'Pending issue/receipt'; fa = 'Pending issue/receipt';
								|it = 'Completare la bolla';
								|pl = 'Sporządź do końca list przewozowy';
								|tr = 'İrsaliyeyi tamamla'"),   False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
		ChoiceList.Add("4", NStr("vi = 'Không có đơn hàng sử dụng';
								|ru = 'Не используются заказы';
								|en = 'Not applicable'; fa = 'Not applicable';
								|it = 'Gli ordini non vengono utilizzati';
								|pl = 'Nie są używane zamówienia';
								|tr = 'Siparişler kullanılmıyor'"), False, PictureLib.AnEmptyPicture);
	EndIf;
	
EndProcedure

// Fills the passed list with the values of order States in RM
//
// Parameters:
//  ChoiceList	 - ValueList - a list to fill in.
//  ActiveOnly	 - Boolean - when set to True, it does not fill in the States that do not require registration (0 and 4).
//
Procedure FillOrderStates(ChoiceList, ActiveOnly = False) Export
	
	ChoiceList.Clear();
	If ActiveOnly Then
		ChoiceList.Add("1", NStr("vi = 'Chưa lập báo cáo';
								|ru = 'Не оформлены';
								|en = 'Pending creation'; fa = 'در انتظار ایجاد';
								|it = 'Non sono formalizzati';
								|pl = 'Nie są sporządzone';
								|tr = 'Düzenlenmemiş'"),               False, PictureLib.CreateInvoice);
		ChoiceList.Add("3", NStr("vi = 'Không khớp hóa đơn';
								|ru = 'Не соответствуют накладным';
								|en = 'Received vs invoiced mismatch'; fa = 'Received vs invoiced mismatch';
								|it = 'Non corrispondono alle bolle';
								|pl = 'Nie odpowiadają listom przewozowym';
								|tr = 'İrsaliyelere uygun değil'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
	Else
		ChoiceList.Add("0", NStr("vi = 'Hóa đơn khớp';
								|ru = 'Соответствуют накладным';
								|en = 'Notes correspond to the invoices'; fa = 'Notes correspond to the invoices';
								|it = 'Corrispondono alle bolle';
								|pl = 'Odpowiadają listom przewozowym';
								|tr = 'İrsaliyelere uygun'"),    False, PictureLib.ExecutedSuccessfully);
		ChoiceList.Add("1", NStr("vi = 'Chưa lập báo cáo';
								|ru = 'Не оформлены';
								|en = 'Pending creation'; fa = 'در انتظار ایجاد';
								|it = 'Non sono formalizzati';
								|pl = 'Nie są sporządzone';
								|tr = 'Düzenlenmemiş'"),               False, PictureLib.CreateInvoice);
		ChoiceList.Add("3", NStr("vi = 'Không khớp hóa đơn';
								|ru = 'Не соответствуют накладным';
								|en = 'Received vs invoiced mismatch'; fa = 'Received vs invoiced mismatch';
								|it = 'Non corrispondono alle bolle';
								|pl = 'Nie odpowiadają listom przewozowym';
								|tr = 'İrsaliyelere uygun değil'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
		ChoiceList.Add("4", NStr("vi = 'Không sử dụng';
								|ru = 'Не используются';
								|en = 'Not applicable'; fa = 'Not applicable';
								|it = 'Non vengono utilizzati';
								|pl = 'Nie używa się';
								|tr = 'Kullanılmıyor'"),            False, PictureLib.AnEmptyPicture);
	EndIf;
	
EndProcedure

// Generates documents based on the list of groups of orders.
//
// Parameters:
//  GroupingOrders  - See InvoicesClient.DataForPlacingOrders
//  ErrorList			 - Structure - error list.
//  ErrorField				 - String - the value that is set in the field property of the message object to the User.
//
// Returns:
//  Array of DocumentRef - contains links to the created documents.
//
Function GenerateDocumentsOnOrders(GroupingOrders, ErrorList, ErrorField) Export
	
	CreatedDocuments = New Array;
	
	For Each Group In GroupingOrders Do
		
		If Group.Property("Handler") And ValueIsFilled(Group.Handler) Then
			InvoiceManager = Common.CommonModule(Group.Handler);
		Else
			InvoiceManager = Documents[Group.NameOfDocumentBeingProcessed];
		EndIf;
		
		For Each References In Group.AnArrayOfOrders Do
			
			DocumentObject = Documents[Group.NameOfDocumentBeingProcessed].CreateDocument();
			
			FillParameters = InvoiceManager.DocumentFillingParameters();
			FillPropertyValues(FillParameters, Group.PopulationFields);
			HeaderAttributes = InvoiceManager.InvoiceFillingData(References, Group.PopulationFields);
			InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, References);
			
			DocumentObject.Fill(FillParameters);
			DocumentObject.Date = ?(ValueIsFilled(DocumentObject.Date), DocumentObject.Date, CurrentSessionDate());
			
			Error = Not DocumentObject.CheckFilling();
			If Not Error Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
				Except
					WriteLogEvent(
						NStr("vi = 'Lỗi khi kết chuyển chứng từ';
							|ru = 'Ошибка при проведении документа';
							|en = 'An error occurred while posting the document'; fa = 'An error occurred while posting the document';
							|it = 'Errore durante la registrazione del documento';
							|pl = 'Błąd podczas zaksięgowania dokumentu';
							|tr = 'Belge kaydı sırasında hata'", CommonClientServer.DefaultLanguageCode()),
						EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
					Error = True;
				EndTry;
			EndIf;
			
			If Error Then
				DocumentObject.Write(DocumentWriteMode.Write);
				
				Messages = GetUserMessages(True);
				For Each Message In Messages Do
					CommonClientServer.AddUserError(ErrorList, ErrorField, Message.Text, Undefined);
				EndDo;
				
				ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ - %1';
								|ru = 'Не удалось провести документ - %1';
								|en = 'Cannot post the document: %1'; fa = 'Cannot post the document: %1';
								|it = 'Impossibile registrare il documento - %1';
								|pl = 'Nie udało się zaksięgować dokument - %1';
								|tr = 'Belge kaydedilemedi - %1'");
				ErrorText = StrTemplate(ErrorText, DocumentObject.Ref);
				CommonClientServer.AddUserError(ErrorList, ErrorField, ErrorText, Undefined);
			EndIf;
			
			UserWorkHistory.Add(DocumentObject.Ref);
			CreatedDocuments.Add(DocumentObject.Ref);
			
		EndDo;
		
	EndDo;
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Return CreatedDocuments;
	
EndFunction

#EndRegion

#Region CalculationOfDesignStates

// Function-constructor of a structure that describes parameters for selecting orders in state calculation functions.
//
// Returns:
//  Structure - Structure with fields:
//  		Organization			- Boolean - Adding the Selection &Organization parameter to the request.
//  		Division		- Boolean - Adding the Selection &Division parameter to the query.
//  		Warehouse				- Boolean - Adding the Selection &Warehouse parameter to the request.
//  		Business Operation			- Boolean - Adding a selection parameter to the query &Business Operation.
//  		Manager			- Boolean - Adding the Selection &Manager parameter to the request.
//
Function OrderSelectionParameters(Organization = Undefined, Department = Undefined, Warehouse = Undefined,
	BusinessTransaction = Undefined, Manager = Undefined) Export
	
	FilterParameters = New Structure;
	
	FilterParameters.Insert("Organization",   ValueIsFilled(Organization));
	FilterParameters.Insert("Department", ValueIsFilled(Department));
	FilterParameters.Insert("Warehouse",         ValueIsFilled(Warehouse));
	FilterParameters.Insert("BusinessTransaction",   ValueIsFilled(BusinessTransaction));
	FilterParameters.Insert("Manager",      ValueIsFilled(Manager));
	
	Return FilterParameters;
	
EndFunction

// The function returns the text of a request to get a temporary table containing the document execution States
// The name of a temporary table: W[of Katalizatory]
// Required fields: Order, Status
// Additional fields: Warehouse, Sender, Recipient, and business Operation.
//
// Parameters:
//  NameOfStateTable			- String - name of the required table See StatesByBusinessTransactions.
//  FilterParameters				- See OrderSelectionParameters.
//  References				- Array - the names of the documents on which you want to calculate status.
//  OnlyAvailabilityForRegistration	- Boolean - if True, then return a temporary table with a single row
//                                         if there are balances for registration, or an empty table if there are no balances.
//  ReplacementParameters             - Undefined, Structure - If there is a key "Field Nomenclature", then the
//                                                          field Nomenclature (Characteristic) is put in the request text.
//
// Returns:
//  String - Query text
//
Function StateRequestText(
			NameOfStateTable,
			FilterParameters,
			References,
			OnlyAvailabilityForRegistration = False,
			ReplacementParameters = Undefined) Export
	
	If NameOfStateTable = "StatesOfSpendingOrders" Then
		Return QueryTextStatesOfSpendingOrders(FilterParameters, References, OnlyAvailabilityForRegistration, ReplacementParameters);
	ElsIf NameOfStateTable = "StatesOfIncomingOrders" Then
		Return QueryTextStatesOfIncomingOrders(FilterParameters, References, OnlyAvailabilityForRegistration, ReplacementParameters);
	ElsIf NameOfStateTable = "RevenueStates" Then
		Return QueryTextRevenueStates(FilterParameters, References, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "ShipmentStates" Then
		Return QueryTextShipmentStates(FilterParameters, References, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "MovementStates" Then
		Return QueryTextMovementStates(FilterParameters, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "AssemblyStates" Then
		Return QueryTextAssemblyStates(FilterParameters, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "StatesOfDomesticConsumption" Then
		Return QueryTextStatesOfDomesticConsumption(FilterParameters, References, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "StatesOfTransfersToProduction" Then
		Return QueryTextStatesOfTransfersToProduction(FilterParameters, References, OnlyAvailabilityForRegistration, ReplacementParameters);
	ElsIf NameOfStateTable = "StatesOfProcessorReports2_5" Then
		Return QueryTextStatesOfProcessorReports2_5(FilterParameters, References, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "StateOfProceedsFromProcessor2_5" Then
		Return QueryTextStateOfProceedsFromProcessor2_5(FilterParameters, References, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "StatesOfTransfersFromProduction" Then
		Return QueryTextStatesOfTransfersFromProduction(FilterParameters, References, OnlyAvailabilityForRegistration, ReplacementParameters);
	ElsIf NameOfStateTable = "TransfersStates" Then
		Return QueryTextTransfersStates(FilterParameters, References, OnlyAvailabilityForRegistration);
	ElsIf NameOfStateTable = "StatesOfReportsToGivers2_5" Then
		Return QueryTextStatesOfReportsToGivers2_5(FilterParameters, References, OnlyAvailabilityForRegistration);
	Else
		Raise NStr("vi = 'Lỗi tạo văn bản yêu cầu trạng thái: tên bảng trạng thái không hợp lệ.';
					|ru = 'Ошибка формирования текста запроса состояний: некорректное имя таблицы состояний.';
					|en = 'An error occurred while generating state request text: incorrect state table name.'; fa = 'An error occurred while generating state request text: incorrect state table name.';
					|it = 'Error generating state query text: invalid state table name.';
					|pl = 'Błąd tworzenia tekstu zapytania statusów: niepoprawna nazwa tabeli statusów.';
					|tr = 'Durum sorgu metni oluşturma hatası: geçersiz durum tablosu adı.'");;
	EndIf;
	
EndFunction

Procedure AddSelectionParametersForDocumentRegistry(Query, FilterParameters) Export
	
	Query.SetParameter("SelectByBusinessTransactions", FilterParameters.Property("BusinessTransaction") And FilterParameters.BusinessTransaction);
	Query.SetParameter("SelectByOrganization", FilterParameters.Property("Organization") And FilterParameters.Organization);
	Query.SetParameter("SelectByDivision", FilterParameters.Property("Department") And FilterParameters.Department);
	Query.SetParameter("SelectByWarehouse", FilterParameters.Property("Warehouse") And FilterParameters.Warehouse);
	Query.SetParameter("SelectByManager", FilterParameters.Property("Manager") And FilterParameters.Manager);
	
	AllParameters = "BusinessTransaction,Organization,Department,Warehouse,Manager";
	ParametersArray = StrSplit(AllParameters, ",");
	For Each Item In ParametersArray Do
		If Not Query.Parameters.Property(Item) Then
			Query.SetParameter(Item, Undefined);
		EndIf;
	EndDo;
	
EndProcedure

// The function returns a structure containing the necessary names of state calculation tables for the passed households. operations'.
// 
// Parameters:
//  BsnsTransactions	- Array - list of business operations.
//
// Returns:
//  Structure -
//  		Key - String is the name of the status table.
//  		Value - Array - names of documents for which states need to be calculated.
//
Function StatesByBusinessTransactions(BsnsTransactions) Export
	
	States1 = New Structure;
	
	For Each BO In BsnsTransactions Do
		If BO = Enums.BusinessTransactions.TransferToOperation Then
			AddState(States1, "StatesOfDomesticConsumption", Metadata.Documents.InventoryConsumptionOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.InventoryConsumptionOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.InventoryConsumption);
		ElsIf BO = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
			AddState(States1, "StatesOfDomesticConsumption", Metadata.Documents.InventoryConsumptionOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.InventoryConsumptionOrder);
			AddState(States1, "StatesOfDomesticConsumption", Metadata.Documents.RMOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.RMOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.InventoryConsumption);
		ElsIf BO = Enums.BusinessTransactions.InventoryTransfer
			Or BO = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
			AddState(States1, "MovementStates", Metadata.Documents.TransferOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.TransferOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.InventoryTransfer);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.TransferOrder);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.InventoryTransfer);
		ElsIf BO = Enums.BusinessTransactions.AssemblyFromComponents
			Or BO = Enums.BusinessTransactions.DisassemblyIntoComponents Then
			AddState(States1, "AssemblyStates", Metadata.Documents.ByAssemblyDisassemblyOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.ByAssemblyDisassemblyOrder);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.AssemblyFromComponents);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.ByAssemblyDisassemblyOrder);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.AssemblyFromComponents);
		ElsIf BO = Enums.BusinessTransactions.TransferToProduction Then
			AddState(States1, "StatesOfTransfersToProduction", Metadata.Documents.OrderOfMaterialsForProduction);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.OrderOfMaterialsForProduction);
		ElsIf BO = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			AddState(States1, "StatesOfTransfersToProduction", Metadata.Documents.OrderOfMaterialsForProduction);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.OrderOfMaterialsForProduction);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.MovementOfProductsAndMaterials);
		ElsIf BO = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
			Or BO = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.MovementOfProductsAndMaterials);
		ElsIf BO = Enums.BusinessTransactions.TransferToToller2_5 Then
			
			AddState(States1, "ShipmentStates",         Metadata.Documents.SubcontractOrder2_5);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.SubcontractOrder2_5);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.TransferOfGoodsToBailee);
			
		ElsIf BO = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			
			AddState(States1, "StateOfProceedsFromProcessor2_5", Metadata.Documents.SubcontractOrder2_5);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.SubcontractOrder2_5);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.ReceiptOfGoodsFromCustodian);
			
		ElsIf BO = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
			
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.ReceiptOfGoodsFromCustodian);
			
		ElsIf BO = Enums.BusinessTransactions.ProductionByToller2_5
			Or BO = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5 Then
			AddState(States1, "StatesOfProcessorReports2_5", Metadata.Documents.SubcontractOrder2_5);
		ElsIf BO = Enums.BusinessTransactions.MaterialTransferToProduction Then
			AddState(States1, "StatesOfTransfersToProduction", Metadata.Documents.ProductionStage2_2);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.ProductionStage2_2);
		ElsIf BO = Enums.BusinessTransactions.TransferOfProductsFromProduction
			Or BO = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			AddState(States1, "StatesOfTransfersFromProduction", Metadata.Documents.ProductionStage2_2);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.ProductionStage2_2);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.MovementOfProductsAndMaterials);
		ElsIf BO = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			
			AddState(States1, "RevenueStates",	  Metadata.Documents.MaterialProviderOrder2_5);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.MaterialProviderOrder2_5);
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.GoodsReceiptForStorage);
			
		ElsIf BO = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			
			AddState(States1, "TransfersStates",		  Metadata.Documents.MaterialProviderOrder2_5);
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.MaterialProviderOrder2_5);
			
		ElsIf BO = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			
			AddState(States1, "StatesOfSpendingOrders", Metadata.Documents.GoodsShipmentFromStorage);
			
		ElsIf BO = Enums.BusinessTransactions.ReportToMaterialProvider2_5 Then
			
			AddState(States1, "StatesOfReportsToGivers2_5", Metadata.Documents.MaterialProviderOrder2_5);
		ElsIf BO = Enums.BusinessTransactions.ReceiptFromProduction
			Or BO = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets
			Or BO = Enums.BusinessTransactions.PutOutOfOperation Then
			AddState(States1, "StatesOfIncomingOrders", Metadata.Documents.OtherGoodsRecordingAsReceived);
		EndIf;
		
	EndDo;
	
	Return States1;
	
EndFunction

// The function returns the names of temporary tables by state names.
// 
// Returns:
//  Structure -
//   Key - String is the name of the status table.
//   Value - String - Name of the temporary table.
//
Function NamesOfTemporaryTablesByState() Export
	
	TablesNames = New Structure();
	TablesNames.Insert("StatesOfDomesticConsumption", "TTStateOfInternalConsumption");
	TablesNames.Insert("StatesOfSpendingOrders", "TTStateOfSpendingOrders");
	TablesNames.Insert("MovementStates", "TTMovementStates");
	TablesNames.Insert("StatesOfIncomingOrders", "TTStateOfIncomingOrders");
	TablesNames.Insert("AssemblyStates", "TTStatesOfAssemblies");
	TablesNames.Insert("StatesOfTransfersToProduction", "TTStatesOfTransfersToProduction");
	TablesNames.Insert("ShipmentStates", "TTShipmentStates");
	TablesNames.Insert("RevenueStates", "TTStateReceipts");
	TablesNames.Insert("StatesOfTransfersFromProduction", "TTTransfersStateOfTransferFromProduction");
	
	TablesNames.Insert("StatesOfProcessorReports2_5",       "TTStateOfProcessorReports2_5");
	TablesNames.Insert("StateOfProceedsFromProcessor2_5", "TTStateOfRevenueFromProcessor2_5");
	TablesNames.Insert("TransfersStates",                       "TTTransfersState");
	TablesNames.Insert("StatesOfReportsToGivers2_5",           "TTStateReportsToGivers2_5");
	
	Return TablesNames;
	
EndFunction

#EndRegion

#Region RenewalOfInvoices

// Forms the structure of settings for the General form "reissue of invoices for orders".
// 
// Returns:
// 	Structure - LongDesc:
// * MainGoods - Structure -:
// ** Key - Structure -:
// *** Products - CatalogRef.Products - 
// *** Characteristic - CatalogRef.ItemsCharacteristics - 
// *** Warehouse - CatalogRef.Warehouses - 
// ** HeaderPicture - Picture - 
// ** ValuesPicture - Picture - 
// * ThisIsTheReceiptOfGoodsDocument - Boolean - 
// * ReceivingDocument - Boolean - 
// * ShippingSlip - Boolean - 
// * Title - String - 
// * FillingData - Structure - 
// * NameOfTheInvoiceForm - String -  
Function SettingsOfInvoiceReissueForm() Export
	
	FormSettings = New Structure();
	FormSettings.Insert("NameOfTheInvoiceForm");
	FormSettings.Insert("FillingData");
	FormSettings.Insert("Title");
	FormSettings.Insert("ShippingSlip", True);
	FormSettings.Insert("ReceivingDocument",  False);
	FormSettings.Insert("ThisIsTheReceiptOfGoodsDocument", False);
	
	ProductKey = New Structure("Products, Characteristic, Warehouse");
	MainGoods = New Structure("Key, HeaderPicture, ValuesPicture",
		ProductKey, PictureLib.Set, PictureLib.Sets);
	FormSettings.Insert("MainGoods", MainGoods);
	
	Return FormSettings;
	
EndFunction

// Transfers the rows selected for orders and orders to the table part of the document.
//
// Parameters:
//  StringTree - Array - the array elements are strings to wrap with the same values of key fields.
//  SearchFields - String - key search fields separated by commas.
//  TabPart - FormDataCollection - the table in which you want to transfer selected rows.
//  EmptyFieldsRelatedToOrder - Structure - values of the "line Code" and "Order..." fields in the table part of the document for
//                                        a line without an order.
//  NotFieldsToFillIn - String - Comma-separated fields that do not need to be moved to the table part from the row tree.
//
// Returns:
//  Array - added lines.
//
Function FillInProductsSelectedFromOrder(StringTree, SearchFields, TabPart, EmptyFieldsRelatedToOrder, NotFieldsToFillIn = "") Export
	
	AddedRows = New Array();
	TheStructureOfTheSearch = New Structure(SearchFields);
	For Each SelectedLines_ In StringTree Do
		
		FillPropertyValues(TheStructureOfTheSearch, SelectedLines_[0]);
		FoundRows = TabPart.FindRows(TheStructureOfTheSearch);
		
		// New row - adding rows.
		If FoundRows.Count() = 0 Then
			
			For Each SourceRow In SelectedLines_ Do
				
				If SourceRow.Count > 0 Then
					DestinationRow = TabPart.Add();
					FillPropertyValues(DestinationRow, SourceRow,, NotFieldsToFillIn);
					If SourceRow.UnlinkFromOrder Then
						FillPropertyValues(DestinationRow, EmptyFieldsRelatedToOrder);
					EndIf;
					AddedRows.Add(DestinationRow);
				EndIf;
				
			EndDo;
			
		Else
			
			If FoundRows.Count() > 1 Then
				
				For Counter = 1 To FoundRows.Count() - 1 Do
					TabPart.Delete(FoundRows[Counter]);
				EndDo;
				
			EndIf;
			
			If SelectedLines_.Count() = 1 Then
			
				SourceRow = SelectedLines_[0];
				DestinationRow = FoundRows[0];
				If SourceRow.Count = 0 Then
					TabPart.Delete(DestinationRow);
				Else
					FillPropertyValues(DestinationRow, SourceRow,, NotFieldsToFillIn);
					If SourceRow.UnlinkFromOrder Then
						FillPropertyValues(DestinationRow, EmptyFieldsRelatedToOrder);
					EndIf;
				EndIf;
			
			Else
				
				DestinationRow = FoundRows[0];
				DestinationRow.Count = 0;
				
				For Each SourceRow In SelectedLines_ Do
				
					If SourceRow.Count > 0 Then
						FillPropertyValues(DestinationRow, SourceRow,, NotFieldsToFillIn);
						If SourceRow.UnlinkFromOrder Then
							FillPropertyValues(DestinationRow, EmptyFieldsRelatedToOrder);
						EndIf;
						DestinationRow = TabPart.Add();
						AddedRows.Add(DestinationRow);
					EndIf;
				
				EndDo;
				
				If DestinationRow.Count = 0 Then
					TabPart.Delete(DestinationRow);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return AddedRows;
	
EndFunction

Procedure ReFillQuantityByOrders(TabPart, Invoice, References, Warehouse, DistributeCompletely = True) Export
	
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "Warehouse", "&Warehouse");
	
	Query = New Query(AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders(,Filter));
	Query.SetParameter("References", References);
	Query.SetParameter("Recorder",  Invoice);
	Query.SetParameter("Warehouse",        Warehouse);
	
	TableOrders = Query.Execute().Unload();
	InvoiceTable = TabPart.Unload(); // ValueTable - 
	
	// Adding the number of orders.
	ColumnVT = TableOrders.Columns.Count; // ValueTableColumn - 
	ColumnVT.Name = "NoteQuantity";
	InvoicesServer.DistributeQuantityAndFill(TableOrders, InvoiceTable, "NoteQuantity",
		"Products, Characteristic, Purpose", "On [Count]", DistributeCompletely, "Series");
	InvoicesServer.SupplementTable(TableOrders, InvoiceTable, "NoteQuantity");
	
	ColumnVT = InvoiceTable.Columns.Count; // ValueTableColumn - 
	ColumnVT.Name = "QuantityBeforeChange_";
	ColumnVT = InvoiceTable.Columns.NoteQuantity; // ValueTableColumn - 
	ColumnVT.Name = "Count";
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	TabPart.Load(InvoiceTable);
	
EndProcedure

#EndRegion

// Transfers the series specified in a separate table to rows in another table.
// 
// Parameters:
//   Table      - ValueTable - contains strings without specifying series.
//   RowIndexes - Array           - array of row indexes in the table to process. Indexes should be in descending order.
//   TableOfSeries - ValueTable - a table containing the series and the number of these series.
//   SeriesKey    - String           - key fields in the series table are separated by commas.
//
Procedure MoveSeriesFromTableToRows(Table, RowIndexes, TableOfSeries, SeriesKey) Export
	
	TableOfSeries.Indexes.Add(SeriesKey);
	SeriesSelectionParameters = New Structure(SeriesKey);
	For Each IndexOf In RowIndexes Do
		
		LineProducts_ = Table[IndexOf];
		FillPropertyValues(SeriesSelectionParameters, LineProducts_);
		FoundRows = TableOfSeries.FindRows(SeriesSelectionParameters);
		For Each RowSeries In FoundRows Do
			
			WriteOffQuantity = Min(RowSeries.Count, LineProducts_.Count);
			RowSeries.Count = RowSeries.Count - WriteOffQuantity;
			
			If WriteOffQuantity > 0 Then
				
				LineProducts_.Series = RowSeries.Series;
				
				If WriteOffQuantity < LineProducts_.Count Then
					
					NewRow = Table.Insert(IndexOf);
					FillPropertyValues(NewRow, LineProducts_);
					
					Share = WriteOffQuantity / LineProducts_.Count;
					
					NewRow.Count = WriteOffQuantity;
					NewRow.NumberOfPackages = Share * LineProducts_.NumberOfPackages;
					
					LineProducts_.Count = LineProducts_.Count - NewRow.Count;
					LineProducts_.NumberOfPackages = LineProducts_.NumberOfPackages - NewRow.NumberOfPackages;
					
				Else
					
					Break;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Collapse the resulting table.
	ColumnsArray1 = New Array();
	For Each Column In Table.Columns Do
		If Column.Name <> "Count" And Column.Name <> "NumberOfPackages" Then
			ColumnsArray1.Add(Column.Name);
		EndIf;
	EndDo;
	ColumnsByRow = StrConcat(ColumnsArray1, ",");
	Table.GroupBy(ColumnsByRow, "Count,NumberOfPackages");
	
EndProcedure

// Configures the Nomenclature (Characteristic) field in the request text,
// as well as, if necessary, the connection condition for the Nomenclature (Characteristic) field and index.
//
// Parameters:
//  QueryText                             - String                  - Query text
//  ReplacementParameters                          - Undefined, Structure - If there is a key "Field Nomenclature",
//                                                                       then the
//                                                                       field Nomenclature (Characteristic) is put in the request text
//  FieldProductDesign              - String                  - Construction field item
//                                                                       to be replaced
//  TableName                               - String                  - table name
//  ConditionConnectionConstruction             - Undefined, String    - Construction condition connection
//                                                                       to be replaced
//  TableNameConnection                     - Undefined, String    - Name of the connection table
//  FieldProductsWithoutAliasConstruction - Undefined, String    - Construction field nomenclature
//                                                                       without an alias to be replaced
//
Procedure ConfigureProductsField(
			QueryText,
			ReplacementParameters,
			FieldProductDesign,
			TableName,
			ConditionConnectionConstruction = Undefined,
			TableNameConnection = Undefined,
			FieldProductsWithoutAliasConstruction = Undefined) Export
	
	ProductsField			  = "";
	ConnectionCondition_			  = "TRUE";
	FieldProducts_WithoutAlias = "";
	
	If ValueIsFilled(ReplacementParameters) And ReplacementParameters.Property("ProductsField") Then
		
		If Right(FieldProductDesign, 1) = "," Then
			
			ProductsField = "Table.Products   AS Products,
							   |Table.Characteristic AS Characteristic,";
		
		Else
			
			ProductsField = "Table.Products   AS Products,
							   |Table.Characteristic AS Characteristic";
		
		EndIf;
		
		ProductsField = StrReplace(ProductsField, "Table", TableName);
	
		If ValueIsFilled(ConditionConnectionConstruction) Then
			
			ConnectionCondition_ = "Table.Products = TConnection.Products
								|AND Table.Characteristic = TConnection.Characteristic";
			
			ConnectionCondition_ = StrReplace(ConnectionCondition_, "Table", TableName);
			ConnectionCondition_ = StrReplace(ConnectionCondition_, "TConnection", TableNameConnection);
			
		EndIf;
		
		If ValueIsFilled(FieldProductsWithoutAliasConstruction) Then
			
			If Right(FieldProductsWithoutAliasConstruction, 1) = "," Then
				
				FieldProducts_WithoutAlias = "Table.Products,
												|Table.Characteristic,";
				
			Else
				
				FieldProducts_WithoutAlias = "Table.Products,
												|Table.Characteristic";
				
			EndIf;
			
			FieldProducts_WithoutAlias = StrReplace(FieldProducts_WithoutAlias, "Table", TableName);
			
		EndIf;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, FieldProductDesign, ProductsField);
	
	If ValueIsFilled(ConditionConnectionConstruction) Then
		QueryText = StrReplace(QueryText, ConditionConnectionConstruction, ConnectionCondition_);
	EndIf;
	
	If ValueIsFilled(FieldProductsWithoutAliasConstruction) Then
		QueryText =
			StrReplace(QueryText, FieldProductsWithoutAliasConstruction, FieldProducts_WithoutAlias);
	EndIf;
	
EndProcedure

// Returns the receipt date for the invoice.
// 
// Parameters:
//  DateOfReceipt - Date - the data access field in the document,
//  DocumentDate - Date - Date field in the document,
//  ReplaceEmptyDocumentDateWithCurrentOne - Boolean - True, if an empty document date needs to be replaced with the current one,
//                                                this is necessary, for example, when the method is called in the processing of filling
//                                                and the date has not yet been assigned by the platform. 
// Returns:
//  Date - Date of receipt.
Function DateOfReceipt(DateOfReceipt, DocumentDate, ReplaceEmptyDocumentDateWithCurrentOne = False) Export
	
	DocumentDateCurrent = ?(DocumentDate <> '00010101' Or Not ReplaceEmptyDocumentDateWithCurrentOne,
		BegOfDay(DocumentDate), BegOfDay(CurrentSessionDate()));
	Return ?(ValueIsFilled(DateOfReceipt), BegOfDay(DateOfReceipt), DocumentDateCurrent);
	
	
EndFunction

#EndRegion

#Region Internal

Function IssueInvoicesForOrders_(GroupingOrders, FormParametersForCreatedDocuments, ErrorField) Export
	
	ErrorList = Undefined;
	ParametersOfCreatedDocuments = New Structure("FormName, Parameters");
	
	If GroupingOrders.Count() = 1 And GroupingOrders[0].ThisIsAnInvoice Then
		
		FillingValues = New Structure(
			"FillByWarehouseDocument, AnArrayOfOrders, FilterByGoods", True, GroupingOrders[0].AnArrayOfOrders);
		GroupingOrders[0].PopulationFields.Property("FilterByGoods", FillingValues.FilterByGoods);
		
		ParametersOfCreatedDocuments.FormName = "Document." + GroupingOrders[0].NameOfDocumentBeingProcessed + ".ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Key, FillingValues",
			GroupingOrders[0].AnArrayOfOrders[0], FillingValues);
		
		Result = New Structure("ParametersOfCreatedDocuments, ErrorList",
			ParametersOfCreatedDocuments, ErrorList);
		Return Result;
		
	EndIf;
	
	InvoicesServer.GroupDocumentsByKeyFieldsInCollection(GroupingOrders, "AnArrayOfOrders", "KeyHeaderFields");
	
	If GroupingOrders.Count() = 1 And GroupingOrders[0].AnArrayOfOrders.Count() = 1 Then
		
		If GroupingOrders[0].Property("Handler")
		   And ValueIsFilled(GroupingOrders[0].Handler) Then
			InvoiceManager = Common.CommonModule(GroupingOrders[0].Handler);
		Else
			InvoiceManager = Documents[GroupingOrders[0].NameOfDocumentBeingProcessed];
		EndIf;
		
		If GroupingOrders[0].ThereAreInvoices Then
			
			HeaderAttributes = InvoiceManager.InvoiceFillingData(GroupingOrders[0].AnArrayOfOrders[0], GroupingOrders[0].PopulationFields);
			
			FormSettings = InvoicesServer.SettingsOfInvoiceReissueForm();
			FormSettings.Title = GroupingOrders[0].TitleOfTheReissueForm;
			FormSettings.NameOfTheInvoiceForm = "Document." + GroupingOrders[0].NameOfDocumentBeingProcessed + ".ObjectForm";
			FormSettings.ReceivingDocument = GroupingOrders[0].ReceivingDocument;
			FormSettings.ShippingSlip = GroupingOrders[0].ShippingSlip;
			
			ParametersOfCreatedDocuments.FormName = "CommonForm.ReregisterInvoicesByReferences";
			ParametersOfCreatedDocuments.Parameters = New Structure("FormSettings, Orders, HeaderAttributes, Warehouse",
				FormSettings, GroupingOrders[0].AnArrayOfOrders[0], HeaderAttributes, GroupingOrders[0].Warehouse);
			
		Else
			
			FillParameters = InvoiceManager.DocumentFillingParameters();
			FillPropertyValues(FillParameters, GroupingOrders[0].PopulationFields);
			HeaderAttributes = InvoiceManager.InvoiceFillingData(GroupingOrders[0].AnArrayOfOrders[0], GroupingOrders[0].PopulationFields);
			InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, GroupingOrders[0].AnArrayOfOrders[0]);
			
			ParametersOfCreatedDocuments.FormName = "Document." + GroupingOrders[0].NameOfDocumentBeingProcessed + ".ObjectForm";
			ParametersOfCreatedDocuments.Parameters = New Structure("Basis", FillParameters);
			
		EndIf;
		
	Else
		
		CreatedDocuments = InvoicesServer.GenerateDocumentsOnOrders(GroupingOrders, ErrorList, ErrorField);
		
		Owner = Users.AuthorizedUser();
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, CreatedDocuments, FormParametersForCreatedDocuments.DataKey);
		SetPrivilegedMode(False);
		
		ParametersOfCreatedDocuments.FormName = "CommonForm.CreatedDocumentForm";
		ParametersOfCreatedDocuments.Parameters = FormParametersForCreatedDocuments;
		ParametersOfCreatedDocuments.Insert("NumberOfDocumentsCreated", CreatedDocuments.Count());
		
	EndIf;
	
	Result = New Structure("ParametersOfCreatedDocuments, ErrorList",
		ParametersOfCreatedDocuments, ErrorList);
	Return Result;
	
EndFunction

Function IssueInvoicesForOrders(GroupingOrders, FormParametersForCreatedDocuments, ErrorField) Export
	
	ErrorList = Undefined;
	ParametersOfCreatedDocuments = New Structure("FormName, Parameters");
	
	InvoicesServer.GroupDocumentsByKeyFieldsInCollection(GroupingOrders, "AnArrayOfOrders", "KeyHeaderFields");
	
	If GroupingOrders.Count() = 1 And GroupingOrders[0].AnArrayOfOrders.Count() = 1 Then
		
		If GroupingOrders[0].Property("Handler")
			And ValueIsFilled(GroupingOrders[0].Handler) Then
			InvoiceManager = Common.CommonModule(GroupingOrders[0].Handler);
		Else
			InvoiceManager = Documents[GroupingOrders[0].NameOfDocumentBeingProcessed];
		EndIf;
		
		FillParameters = InvoiceManager.DocumentFillingParameters();
		FillPropertyValues(FillParameters, GroupingOrders[0].PopulationFields);
		HeaderAttributes = InvoiceManager.InvoiceFillingData(GroupingOrders[0].AnArrayOfOrders[0], GroupingOrders[0].PopulationFields);
		InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, GroupingOrders[0].AnArrayOfOrders[0]);
		
		ParametersOfCreatedDocuments.FormName = "Document." + GroupingOrders[0].NameOfDocumentBeingProcessed + ".ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Basis", FillParameters);
		
	Else
		
		CreatedDocuments = InvoicesServer.GenerateDocumentsOnOrders(GroupingOrders, ErrorList, ErrorField);
		
		Owner = Users.AuthorizedUser();
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, CreatedDocuments, FormParametersForCreatedDocuments.DataKey);
		SetPrivilegedMode(False);
		
		ParametersOfCreatedDocuments.FormName = "CommonForm.CreatedDocumentForm";
		ParametersOfCreatedDocuments.Parameters = FormParametersForCreatedDocuments;
		ParametersOfCreatedDocuments.Insert("NumberOfDocumentsCreated", CreatedDocuments.Count());
		
	EndIf;

	Result = New Structure("ParametersOfCreatedDocuments, ErrorList",
		ParametersOfCreatedDocuments, ErrorList);
	Return Result;
	
EndFunction

Function RegisterDiscrepancyCertificate(Invoices, Orders, FormParametersForCreatedDocuments, ErrorField)
	
	ErrorList = Undefined;
	
	ParametersOfCreatedDocuments = New Structure("FormName, Parameters");
	
	If ValueIsFilled(Orders) Then
		
		Query = New Query;
		Query.Text = 
			"SELECT DISTINCT
			|	InventoryTransfer.Ref AS Ref
			|FROM
			|	Document.InventoryTransfer.Goods AS InventoryTransfer
			|WHERE
			|	InventoryTransfer.TransferOrder IN(&TransferOrders)
			|	AND InventoryTransfer.Ref.Posted";
		
		Query.SetParameter("TransferOrders", Orders);
		
		CommonClientServer.SupplementArray(Invoices, Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
	
	InvoicesServer.GroupDocumentsByKeyFields(Invoices, Documents.DiscrepancyReportFollowingTransfer.KeyFieldsOfHeader());
	
	If Invoices.Count() = 1 Then
		
		InvoiceManager = Documents.DiscrepancyReportFollowingTransfer;
		
		FillParameters = InvoiceManager.DocumentFillingParameters();
		HeaderAttributes = InvoiceManager.InvoiceFillingData(Invoices[0]);
		InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, Invoices[0]);
		
		ParametersOfCreatedDocuments.FormName = "Document.DiscrepancyReportFollowingTransfer.ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Basis", FillParameters);
		
	Else
		
		Group = New Structure("NameOfDocumentBeingProcessed, AnArrayOfOrders, PopulationFields",
			Metadata.Documents.DiscrepancyReportFollowingTransfer.Name, Invoices, New Structure);
		
		GroupingOrders = New Array(1);
		GroupingOrders[0] = Group;
		
		CreatedDocuments = InvoicesServer.GenerateDocumentsOnOrders(GroupingOrders, ErrorList, ErrorField);
		
		If Not ValueIsFilled(CreatedDocuments) Then
			
			Result = New Structure("ParametersOfCreatedDocuments, ErrorList", Undefined, ErrorList);
			Return Result;
			
		EndIf;
		
		Owner = Users.AuthorizedUser();
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, CreatedDocuments, FormParametersForCreatedDocuments.DataKey);
		SetPrivilegedMode(False);
		
		ParametersOfCreatedDocuments.FormName = "CommonForm.CreatedDocumentForm";
		ParametersOfCreatedDocuments.Parameters = FormParametersForCreatedDocuments;
		ParametersOfCreatedDocuments.Insert("NumberOfDocumentsCreated", CreatedDocuments.Count());
		
	EndIf;
	
	Result = New Structure("ParametersOfCreatedDocuments, ErrorList",
		ParametersOfCreatedDocuments, ErrorList);
	Return Result;
	
EndFunction

Procedure AddState(States1, State, Document) Export
	
	If Not AccessRight("Read", Document) Then
		Return;
	EndIf;
	
	If Not States1.Property(State) Then
		States1.Insert(State, New Array);
	EndIf;
	
	If States1[State].Find(Document.FullName()) = Undefined Then
		States1[State].Add(Document.FullName());
	EndIf;

EndProcedure

#EndRegion

#Region Private

// Fills in the line according to the filling option (according to the order data or order data).
//
// Parameters:
//  Table acceptor-stringable Values, data Formstructure-a structure with the required columns "Quantity" and
//                                                                  "number of packages".
//  Source table - a table of Values, a sample of query Results-a structure containing data for processing
//                                                                  orders, or orders and orders.
//  Count - Number - Quantity to fill in.
//
Procedure FillInLineByOption(Receiver, Source, Count)
	
	FillPropertyValues(Receiver, Source);
	
	Receiver.Count = Count;
	// Filling in the number of packages.
	If ValueIsFilled(Source.QuantityInOrder) And Source.QuantityInOrder > 0
		And ValueIsFilled(Source.OrderPackingRatio) Then
		
		Receiver.Package = Source.OrderPackage;
		Receiver.NumberOfPackages = Receiver.Count / Source.OrderPackingRatio;
		
	ElsIf ValueIsFilled(Source.QuantityInInvoice) And Source.QuantityInInvoice > 0
		And ValueIsFilled(Source.PackingOfConsignmentNote_) Then
		
		Receiver.Package = Source.PackingOfConsignmentNote;
		Receiver.NumberOfPackages = Receiver.Count / Source.PackingOfConsignmentNote_;
		
	Else
		
		Receiver.NumberOfPackages = Receiver.Count;
		
	EndIf;
	
EndProcedure

Function CheckPossibilityOfEnteringBasedOn(Document, Status, ThereAreErrorsPosted, ThereAreErrorsStatus, ArrayOfValidStatuses) Export
	
	ErrorText = "";
	If ThereAreErrorsPosted Then
		
		ErrorText = NStr("vi = 'Chứng từ chưa kết chuyển. Cấm nhập trên cơ sở chứng từ chưa kết chuyển.';
						|ru = 'Документ не проведен. Ввод на основании непроведенного документа запрещен.';
						|en = 'Document is not posted. Generation from unposted documents is not allowed.'; fa = 'Document is not posted. Generation from unposted documents is not allowed.';
						|it = 'Il documento non è stato registrato. L''immissione in base al documento non registrato è proibita.';
						|pl = 'Dokument niezaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
						|tr = 'Belge kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
		
	ElsIf ThereAreErrorsStatus Then
		
		StringOfAcceptableStatuses = "";
		
		For Each AcceptableStatus In ArrayOfValidStatuses Do
			StringOfAcceptableStatuses = StringOfAcceptableStatuses + """" + AcceptableStatus + """, ";
		EndDo;
		
		StringOfAcceptableStatuses = Left(StringOfAcceptableStatuses, StrLen(StringOfAcceptableStatuses)-2);
		
		If ArrayOfValidStatuses.Count() = 1 Then
			If Status <> Undefined Then
				ErrorText = NStr("vi = 'Chứng từ ở trạng thái ""%Status%"". Nhập trên cơ sở chỉ được phép trong trạng thái %StringOfAcceptableStatuses%.';
								|ru = 'Документ находится в статусе ""%Status%"". Ввод на основании разрешен только в статусе %StringOfAcceptableStatuses%.';
								|en = 'Document is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% status.'; fa = 'Document is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% status.';
								|it = 'Il documento si trova nello stato ""%Status%"". L''inserimento concesso solo nello stato %StringOfAcceptableStatuses%.';
								|pl = 'Dokument ma status ""%Status%"". Wprowadzenie na podstawie jest dozwolone tylko w statusie %StringOfAcceptableStatuses%.';
								|tr = 'Belge ""%Status%"" durumundadır. Gerekçeye dayalı girişe yalnızca %StringOfAcceptableStatuses% durumunda izin verilir.'");
			Else
				ErrorText = NStr("vi = 'Nhập trên cơ sở chỉ được phép trong trạng thái %StringOfAcceptableStatuses%.';
								|ru = 'Ввод на основании разрешен только в статусе %StringOfAcceptableStatuses%.';
								|en = 'Generation is only allowed from base documents in %StringOfAcceptableStatuses% status.'; fa = 'Generation is only allowed from base documents in %StringOfAcceptableStatuses% status.';
								|it = 'Enter on the grounds is permitted only in the status %StringOfAcceptableStatuses%.';
								|pl = 'Wprowadzenie na podstawie jest dozwolone tylko w statusie %StringOfAcceptableStatuses%.';
								|tr = 'Buna dayalı girişe yalnızca %StringOfAcceptableStatuses% durumunda izin verilir.'");
			EndIf;
		Else
			If Status <> Undefined Then
				ErrorText = NStr("vi = 'Chứng từ ở trạng thái ""%Status%"". Nhập trên cơ sở chỉ được phép trong các trạng thái của %StringOfAcceptableStatuses%.';
								|ru = 'Документ находится в статусе ""%Status%"". Ввод на основании разрешен только в статусах %StringOfAcceptableStatuses%.';
								|en = 'Document is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% statuses.'; fa = 'Document is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% statuses.';
								|it = 'Il documento si trova nello stato ""%Status%"". L''inserimento concesso solo negli stati %StringOfAcceptableStatuses%.';
								|pl = 'Dokument ma status ""%Status%"". Wprowadzenie na podstawie jest dozwolone tylko przy statusach %StringOfAcceptableStatuses%.';
								|tr = 'Belge ""%Status%"" durumundadır. Gerekçeye  dayalı girişe yalnızca %StringOfAcceptableStatuses% durumlarında izin verilir.'");
			Else
				ErrorText = NStr("vi = 'Nhập trên cơ sở chỉ được phép trong các trạng thái của %StringOfAcceptableStatuses%.';
								|ru = 'Ввод на основании разрешен только в статусах %StringOfAcceptableStatuses%.';
								|en = 'Generation is only allowed from base documents in %StringOfAcceptableStatuses% statuses.'; fa = 'Generation is only allowed from base documents in %StringOfAcceptableStatuses% statuses.';
								|it = 'L''input basato è consentito solo nello stato %StringOfAcceptableStatuses%.';
								|pl = 'Wprowadzenie na podstawie jest dozwolone tylko przy statusach %StringOfAcceptableStatuses%.';
								|tr = 'Gerekçeye dayalı girişe yalnızca %StringOfAcceptableStatuses% durumlarında izin verilir.'");
			EndIf;
		EndIf;
		
		ErrorText = StrReplace(ErrorText, "%StringOfAcceptableStatuses%", StringOfAcceptableStatuses);
		ErrorText = StrReplace(ErrorText, "%Status%", Status);
	
	EndIf;
	
	Return ErrorText;
	
EndFunction

Function NameOfDestinationField(Table, Fields)
	
	FieldsStructure = New Structure(Fields);
	For Each Item In FieldsStructure Do
		
		Column = Table.Columns.Find(Item.Key);
		If Column.ValueType.ContainsType(Type("CatalogRef.Assignments")) Then
			Return Item.Key;
		EndIf;
		
	EndDo;
	
EndFunction

Procedure AddTrafficColumnForWarehouseRegisters(Table, Fields)
	
	NameOfDestinationField = NameOfDestinationField(Table, Fields);
	AssignmentsArray = Table.UnloadColumn(NameOfDestinationField);
	WarehouseAssignments = Common.ObjectsAttributesValues(AssignmentsArray, "RecordsInWarehouseRegisters");
	Table.Columns.Add("RecordsInWarehouseRegisters", New TypeDescription("Boolean"));
	For Each TableRow In Table Do
		
		TableRow.RecordsInWarehouseRegisters = ValueIsFilled(TableRow[NameOfDestinationField])
			And WarehouseAssignments[TableRow[NameOfDestinationField]].RecordsInWarehouseRegisters;
		
	EndDo;
	
EndProcedure

// Transfers the value of a numeric field from the source table to the receiver table. 
//
// Parameters:
//  SourceTable1			 - ValueTable - 
//  DestinationTable			 - ValueTable - 
//  FieldNameQuantity		 - String - Field to fill in. If there is no receiver in the table, it is added.
//  Dimensions				 - String - Key fields for finding matches between table rows
//  Resources					 - String - Conditions imposed on the numeric fields of the receiver's table rows, such as:
//  									"NOT [Quantity], BY [Quantity order], [Quantity order]"
//  									Where the name of the numeric field in the receiver table is written in square brackets, 
//  									and the action ID is in front of it:
//  									NOT [FIELD NAME] - the field name value must be zero
//  									BY [Field name] - in the receiver line, in the field *Field name*, you cannot write a number greater
//  									than in the field name.
//  									[Field name] - the field name value must be greater than zero
//  DistributeCompletely	 - Boolean - If, as a result of the restriction of the "BY" condition, an Unallocated quantity remains in the source line
//  									, we allow this quantity to be written off to the last matched line of the receiver.
//
Procedure AllocateQuantity(SourceTable1, DestinationTable, FieldNameQuantity, Dimensions, Resources, DistributeCompletely = False) Export
	
	If DestinationTable.Columns.Find(FieldNameQuantity) = Undefined Then
		DestinationTable.Columns.Add(FieldNameQuantity, New TypeDescription("Number"));
	EndIf;
	
	RowSelectionParameters = ActionsWithResourcesFromLine(Resources);
	
	Filter = New Structure(Dimensions);
	
	For Each SourceRow In SourceTable1 Do
		
		FillPropertyValues(Filter, SourceRow);
		FoundRows = DestinationTable.FindRows(Filter);
		
		For Each DestinationRow In FoundRows Do
			
			CheckPassed = StringMatchesFilter(DestinationRow, RowSelectionParameters);
			
			If Not CheckPassed Then
				Continue;
			EndIf;
			
			// If the array is small - empty, then it is transferred as is
			// , otherwise an additional occurs. checking that the result of filling in the field does not exceed the values of the fields being checked.
			Count = SourceRow[FieldNameQuantity];
			
			NumberOfValidationFields = RowSelectionParameters.NotGreater.Count();
			If NumberOfValidationFields > 0 Then
				MaxCount = DestinationRow[RowSelectionParameters.NotGreater[0]];
				For N1 = 1 To NumberOfValidationFields - 1 Do
					VerificationField = RowSelectionParameters.NotGreater[NumberOfValidationFields - N1 - 1];
					MaxCount = Min(DestinationRow[VerificationField], MaxCount);
				EndDo;
				
				Excess = DestinationRow[FieldNameQuantity] + Count - MaxCount;
				If Excess >= Count Then
					Count = 0;
				ElsIf Excess > 0 Then
					Count = Count - Excess;
				EndIf;
				
			EndIf;
			
			If Count = 0 Then
				Continue;
			EndIf;
			
			DestinationRow[FieldNameQuantity] = DestinationRow[FieldNameQuantity] + Count;
			SourceRow[FieldNameQuantity] = SourceRow[FieldNameQuantity] - Count;
			
		EndDo;
		
		// If not the full amount was distributed, we write the remainder to the last line found.
		If DistributeCompletely
			And SourceRow[FieldNameQuantity] > 0 
			And FoundRows.Count() > 0 Then
			
			Count = SourceRow[FieldNameQuantity];
			FoundRow = FoundRows[FoundRows.Count() - 1];
			
			If Not StringMatchesFilter(FoundRow, RowSelectionParameters) Then
				Continue;
			EndIf;
			
			FoundRow[FieldNameQuantity] = FoundRow[FieldNameQuantity] + Count;
			SourceRow[FieldNameQuantity] = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Option procedure Raspredelitelno
// Transfers the value of a numeric field from the source table to the receiver table.
// Fills in any field of the placeholder Field, and if one line of the receiver corresponds to several lines of the source
// that differ only in the value of the Placeholder field, it splits the corresponding line of the receiver.
//
// Parameters:
//  SourceTable1			 - ValueTable	 - 
//  DestinationTable			 - ValueTable	 - 
//  FieldNameQuantity		 - String	 - Field to fill in. If there is no receiver in the table, it is added.
//  Dimensions				 - String	 - Key fields for finding matches between table rows
//  Resources					 - String	 - Conditions imposed on the numeric fields of the receiver's table rows, such as:
//  									"NOT [Quantity], BY [Quantity order], [Quantity order]"
//  									Where the name of the numeric field in the receiver table is written in square brackets,
//  									and the action ID is in front of it:
//  									NOT [FIELD NAME] - the field name value must be zero
//  									BY [Field name] - in the receiver line, in the field *Field name*, you cannot write a number greater
//  									than in the field name.
//  									[Field name] - the field name value must be greater than zero
//  DistributeCompletely	 - Boolean	 - If, as a result of the restriction of the "BY" condition, an Unallocated quantity remains in the source line
//  			, we allow this quantity to be written off to the last matched line of the receiver
//  FieldsToFillIn			 - String	 - Custom fields whose value must be copied from the source string to the receiver string.
//
Procedure DistributeQuantityAndFill(SourceTable1, DestinationTable, FieldNameQuantity, Dimensions, Resources, 
									DistributeCompletely = False, FieldsToFillIn = "") Export
	
	If DestinationTable.Columns.Find(FieldNameQuantity) = Undefined Then
		DestinationTable.Columns.Add(FieldNameQuantity, New TypeDescription("Number"));
	EndIf;
	
	RowSelectionParameters = ActionsWithResourcesFromLine(Resources);
	
	Filter = New Structure(Dimensions);
	
	For Each SourceRow In SourceTable1 Do
		
		FillPropertyValues(Filter, SourceRow);
		FoundRows = DestinationTable.FindRows(Filter);
		
		For Each DestinationRow In FoundRows Do
			
			CheckPassed = StringMatchesFilter(DestinationRow, RowSelectionParameters);
			
			If Not CheckPassed Then
				Continue;
			EndIf;
			
			// If the array is small - empty, then it is transferred as is
			// , otherwise an additional occurs. checking that the result of filling in the field does not exceed the values of the fields being checked.
			Count = SourceRow[FieldNameQuantity];
			
			NumberOfValidationFields = RowSelectionParameters.NotGreater.Count();
			If NumberOfValidationFields > 0 Then
				MaxCount = DestinationRow[RowSelectionParameters.NotGreater[0]];
				For N1 = 1 To NumberOfValidationFields - 1 Do
					VerificationField = RowSelectionParameters.NotGreater[NumberOfValidationFields - N1 - 1];
					MaxCount = Min(DestinationRow[VerificationField], MaxCount);
				EndDo;
				
				Excess = DestinationRow[FieldNameQuantity] + Count - MaxCount;
				If Excess >= Count Then
					Count = 0;
				ElsIf Excess > 0 Then
					Count = Count - Excess;
				EndIf;
				
			EndIf;
			
			If Count = 0 Then
				Continue;
			EndIf;
			
			ArrayOfFieldsToFillIn = StringFunctionsClientServer.SplitStringIntoWordArray(FieldsToFillIn, ",");
			
			FieldsToFillInAreEqual = True;
			For Each FieldToFillIn In ArrayOfFieldsToFillIn Do
				If DestinationRow[FieldToFillIn] <> SourceRow[FieldToFillIn] Then
					FieldsToFillInAreEqual = False;
					Break;
				EndIf;
			EndDo;
			
			If ValueIsFilled(FieldsToFillIn)
				And Not FieldsToFillInAreEqual
				And DestinationRow[FieldNameQuantity] = 0 Then
				// You can fill in the current Receiver line
				FillPropertyValues(DestinationRow, SourceRow, FieldsToFillIn);
				
				DestinationRow[FieldNameQuantity] = DestinationRow[FieldNameQuantity] + Count;
				SourceRow[FieldNameQuantity] = SourceRow[FieldNameQuantity] - Count;
				
			ElsIf ValueIsFilled(FieldsToFillIn)
				And Not FieldsToFillInAreEqual Then
				// Data has already been written to the current Receiver line, you need to select a new line
				NewLineReceiver = DestinationTable.Add();
				FillPropertyValues(NewLineReceiver, DestinationRow);
				FillPropertyValues(NewLineReceiver, SourceRow, FieldsToFillIn);
				
				If NumberOfValidationFields > 0 Then
					QuantityControlField = RowSelectionParameters.NotGreater[0];
					NewLineReceiver[QuantityControlField] = NewLineReceiver[QuantityControlField] - NewLineReceiver[FieldNameQuantity];
					DestinationRow[QuantityControlField] = DestinationRow[FieldNameQuantity];
				EndIf;
				
				NewLineReceiver[FieldNameQuantity] = Count;
				SourceRow[FieldNameQuantity] = SourceRow[FieldNameQuantity] - Count;
				
			Else
				DestinationRow[FieldNameQuantity] = DestinationRow[FieldNameQuantity] + Count;
				SourceRow[FieldNameQuantity] = SourceRow[FieldNameQuantity] - Count;
			EndIf;
			
		EndDo;
		
		// If not the full amount was distributed, we write the remainder to the last line found.
		If DistributeCompletely
			And SourceRow[FieldNameQuantity] > 0 
			And FoundRows.Count() > 0 Then
			
			Count = SourceRow[FieldNameQuantity];
			FoundRow = FoundRows[FoundRows.Count() - 1];
			
			If Not StringMatchesFilter(FoundRow, RowSelectionParameters) Then
				Continue;
			EndIf;
			
			FoundRow[FieldNameQuantity] = FoundRow[FieldNameQuantity] + Count;
			SourceRow[FieldNameQuantity] = 0;
			
			If ValueIsFilled(FieldsToFillIn) Then
				FillPropertyValues(FoundRow, SourceRow, FieldsToFillIn);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Distributes the deviation of measured items (if it is allowed) from the source table to the receiver table.
//
// Parameters:
//  SourceTable1			 - ValueTable	 - 
//  DestinationTable			 - ValueTable	 - 
//  FieldNameQuantity		 - String	 - The field in the receiver table, relative to which the permissible deviation value will be calculated
//  NameOfRejectField		 - String	 - Field to fill in. The amount that remains to be distributed in the source table
//  										and the amount that has already been distributed in the receiver table
//  Dimensions				 - String	 - Key fields for finding matches between table rows.
//
Procedure DistributeDeviationOfDimensionalGoods(SourceTable1, DestinationTable, FieldNameQuantity, NameOfRejectField, Dimensions) Export
	
	If Not Constants.UseAllowableDeviationOfMeasuringGoodsShipmentReceiving.Get() Then
		Return;
	EndIf;
	
	AllowableVariance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get() / 100;
	
	If AllowableVariance = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Products.Ref AS Ref
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref IN (&ItemList)
		|	AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
	
	Query.SetParameter("ItemList", SourceTable1.UnloadColumn("Products"));
	Query.SetParameter("DimensionalTypesOfUnits", Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	
	FieldNameMaxQuantity = FieldNameQuantity + "Max";
	DestinationTable.Columns.Add(FieldNameMaxQuantity, New TypeDescription("Number"));
	FilterOfProductItem = New Structure("Products");
	DimensionsFilter = New Structure(Dimensions);
	RowsForDistribution = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		FilterOfProductItem.Products = Selection.Ref;
		
		SourceRows = SourceTable1.FindRows(FilterOfProductItem);
		For Each SourceRow In SourceRows Do
			
			If SourceRow[NameOfRejectField] <= 0 Then
				Continue;
			EndIf;
				
			HasBeenDistributed = 0;
			FillPropertyValues(DimensionsFilter, SourceRow);
			DestinationRows = DestinationTable.FindRows(DimensionsFilter);
			
			For Each String In DestinationRows Do
				String[FieldNameMaxQuantity] = String[FieldNameQuantity] * (1 + AllowableVariance);
				HasBeenDistributed = HasBeenDistributed + String[NameOfRejectField];
			EndDo;
			
			If HasBeenDistributed * AllowableVariance >= SourceRow[NameOfRejectField] Then
				RowsForDistribution.Add(SourceRow);
			EndIf;
			
		EndDo;
		
	EndDo;
		
	Condition = "[" + FieldNameQuantity + "], On [" + FieldNameMaxQuantity + "]";
	InvoicesServer.AllocateQuantity(RowsForDistribution, DestinationTable, NameOfRejectField, Dimensions, Condition, False);
	
	DestinationTable.Columns.Delete(FieldNameMaxQuantity);
	
EndProcedure

Function StringMatchesFilter(DestinationRow, FilterParameters)
	
	For Each VerificationField In FilterParameters.EqualToZero Do
		// The value of the validation field must be zero
		If DestinationRow[VerificationField] <> 0 Then
			Return False;
		EndIf;
	EndDo;
	
	For Each VerificationField In FilterParameters.GreaterThanZero Do
		// The value of the validation field must be greater than zero
		If DestinationRow[VerificationField] <= 0 Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ActionsWithResourcesFromLine(Resources)
	
	ActionsWithResources = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Resources);
	
	EqualToZero           = New Array();
	NotGreater            = New Array();
	GreaterThanZero          = New Array();
	
	For Each ResourceString In ActionsWithResources Do
		
		ResourceStringProcessed = Lower(ResourceString);
		ResourceStringProcessed = TrimAll(ResourceStringProcessed);
		
		BeginningOfFieldName = StrFind(ResourceStringProcessed, "[") + 1;
		EndOfFieldName = StrFind(ResourceStringProcessed, "]");
		LengthOfFieldName = EndOfFieldName - BeginningOfFieldName;
		CommandIsNot = "not";
		SoftwareCommand = "on";
		
		ResourceName = Mid(ResourceStringProcessed, BeginningOfFieldName, LengthOfFieldName);
		ResourceName = TrimAll(ResourceName);
		
		If StrStartsWith(ResourceStringProcessed, CommandIsNot) Then
			EqualToZero.Add(ResourceName);
		ElsIf StrStartsWith(ResourceStringProcessed, SoftwareCommand) Then
			NotGreater.Add(ResourceName);
		Else
			GreaterThanZero.Add(ResourceName);
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("EqualToZero",           EqualToZero);
	StructureOfActions.Insert("NotGreater",            NotGreater);
	StructureOfActions.Insert("GreaterThanZero",          GreaterThanZero);
	
	Return StructureOfActions;
	
EndFunction

// Adds a source row to the receiver table if the field name Is greater than zero
//
// Parameters:
//  SourceTable1		 - ValueTable - 
//  DestinationTable		 - ValueTable - 
//  FieldNameQuantity	 - String - 
//
Procedure SupplementTable(SourceTable1, DestinationTable, FieldNameQuantity) Export
	
	For Each SourceTableRow In SourceTable1 Do
		If SourceTableRow[FieldNameQuantity] > 0 Then
			FillPropertyValues(DestinationTable.Add(), SourceTableRow);
		EndIf;
	EndDo;
	
EndProcedure

Procedure DeleteEmptyLines(Table, FieldNameQuantity) Export
	
	NumberOfIndexes = Table.Count() - 1;
	For N = 0 To NumberOfIndexes Do
		
		String = Table[NumberOfIndexes - N];
		If String[FieldNameQuantity] = 0 Then
			Table.Delete(String);
		EndIf;
		
	EndDo;
	
EndProcedure

Function QuerySeparatorText() Export

	Return
		"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";

EndFunction

Procedure FillInAssignmentsInTablePart(TabularSection, Purpose) Export
	
	If TabularSection.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	If Not ValueIsFilled(Purpose) Then
		
		For Each String In TabularSection Do
			
			String.Purpose = EmptyAssignment;
			
		EndDo;
		
	Else
		
		Table = New ValueTable();
		Table.Columns.Add("IndexOf", New TypeDescription("Number"));
		Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		IndexOf = 0;
		For Each String In TabularSection Do
			
			NewRow = Table.Add();
			FillPropertyValues(NewRow, String);
			NewRow.IndexOf = IndexOf;
			IndexOf = IndexOf + 1;
			
		EndDo;
		
		Query = New Query();
		Query.Text =
			"SELECT
			|	Table.IndexOf       AS IndexOf,
			|	Table.Products AS Products
			|INTO TTProducts_1
			|FROM
			|	&Table AS Table
			|;
			|
			|//////////////////////////////
			|SELECT
			|	Table.IndexOf AS IndexOf,
			|	
			|	CASE WHEN CatProducts.Ref IS NULL THEN
			|				FALSE
			|			ELSE
			|				TRUE
			|		END AS FillOutAppointment
			|FROM
			|	TTProducts_1 AS Table
			|		LEFT JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.Ref = Table.Products
			|			AND CatProducts.ItemsType IN(
			|			VALUE(Enum.ItemsTypes.OwnGoods),
			|			VALUE(Enum.ItemsTypes.Work_5))";
			
		Query.SetParameter("Table", Table);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			If Selection.FillOutAppointment Then
				
				TabularSection[Selection.IndexOf].Purpose = Purpose;
				
			Else
				
				TabularSection[Selection.IndexOf].Purpose = EmptyAssignment;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function QueryTextGroups(
			KeyFields, References, TempTableName, ParameterName, KeyFieldsAdapted = Undefined)
	
	DocumentTypes = New Map();
	DocumentNames = New Array();
	For Each Item In References Do
		DocumentType = TypeOf(Item);
		If DocumentTypes.Get(DocumentType) = Undefined Then
			DocumentTypes.Insert(DocumentType, True);
			DocumentNames.Add(Item.Metadata().FullName());
		EndIf;
	EndDo;
	ThisIsFirstRequestInPackage = True;
	ReplacementText = "INTO SubstitutionTemporaryTableName";
	QueryText =
		"SELECT
		|	Ref,
		|	SubstitutionOfAdaptedKeyFields
		|INTO SubstitutionTemporaryTableName
		|FROM
		|	SubstitutingSourceName
		|WHERE
		|	Ref IN (&ParameterNameSubstitution)";
	Texts = New Array();
	For Each SourceName In DocumentNames Do
		Text = QueryText;
		If Not ThisIsFirstRequestInPackage Then
			Text = StrReplace(Text, ReplacementText, "");
		EndIf;
		Text = StrReplace(Text, "SubstitutingSourceName", SourceName);
		Texts.Add(Text);
		ThisIsFirstRequestInPackage = False;
	EndDo;
	QueryText = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	Texts = New Array();
	Texts.Add(QueryText);
	QueryText =
		"SELECT DISTINCT
		|	SubstitutionOfKeyFields
		|FROM
		|	SubstitutionTemporaryTableName";
	Texts.Add(QueryText);
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	SubstitutionOfAdaptedKeyFields = ?(ValueIsFilled(KeyFieldsAdapted), KeyFieldsAdapted, KeyFields);
	
	QueryText = StrReplace(QueryText, "SubstitutionTemporaryTableName", TempTableName);
	QueryText = StrReplace(QueryText, "ParameterNameSubstitution", ParameterName);
	QueryText = StrReplace(QueryText, "SubstitutionOfKeyFields", KeyFields);
	QueryText = StrReplace(QueryText, "SubstitutionOfAdaptedKeyFields", SubstitutionOfAdaptedKeyFields);
	Return QueryText;
	
EndFunction

#Region CalculationOfStatesOfRegistrationService

Function QueryTextStatesOfSpendingOrders(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration, ReplacementParameters = Undefined)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue) Then
		
		QueryText =
		"SELECT TOP 0
		|	NULL AS ToRegister,
		|	NULL AS ReferenceOrder,
		|	&Fields AS Fields,
		|	NULL AS Warehouse,
		|	NULL AS Recipient,
		|	NULL AS State
		|INTO TTStateOfSpendingOrders";
		
		ProductsField = "";
		If ValueIsFilled(ReplacementParameters) And ReplacementParameters.Property("ProductsField") Then
			ProductsField = "NULL AS Products,
							   |NULL AS Characteristic,"
		EndIf;
		
		QueryText = StrReplace(QueryText, "&Fields AS Fields,", ProductsField);
		
		Return QueryText;
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.DocumentShipments AS DocumentShipments,
	|	&TTHasTwoFields_ AS TTHasTwoFields_,
	|	NestedQuery.Warehouse            AS Warehouse,
	|	NestedQuery.Recipient       AS Recipient
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.Warehouse            AS Warehouse,
	|		Balance.Recipient       AS Recipient,
	|		Balance.DocumentShipments AS DocumentShipments,
	|		Balance.Products     AS Products,
	|		Balance.Characteristic   AS Characteristic,
	|		Balance.Purpose       AS Purpose,
	|		Balance.Series            AS Series
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(, &ConditionForSelectingResidues) AS Balance
	|			LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|			ON Balance.Warehouse = CatWarehouses.Ref
	|				AND (CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue)
	|				AND (CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)
	|	WHERE
	|		NOT CatWarehouses.Ref IS NULL
	|		AND Balance.ToShipBalance - Balance.AssembledBalance <> Balance.ToRegisterBalance
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.DocumentShipments
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.DocumentShipments AS DocumentShipments,
	|	&TTHasTwoFields AS TTHasTwoFields,
	|	References.Warehouse            AS Warehouse,
	|	References.Recipient       AS Recipient
	|INTO TueThereAreOrders_3
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|			WHERE
	|				GoodsForIssue.Active
	|				AND GoodsForIssue.DocumentShipments = References.DocumentShipments
	|				AND &TTHasOneCondition
	|				AND GoodsForIssue.Warehouse = References.Warehouse
	|				AND GoodsForIssue.Recipient = References.Recipient
	|				AND GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			HAVING
	|				SUM(GoodsForIssue.Assembled) > 0
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|			WHERE
	|				GoodsForIssue.Active
	|				AND GoodsForIssue.DocumentShipments = References.DocumentShipments
	|				AND &TTHasOneCondition
	|				AND GoodsForIssue.Warehouse = References.Warehouse
	|				AND GoodsForIssue.Recipient = References.Recipient
	|				AND GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Expense)
	|				
	|			HAVING
	|				SUM(GoodsForIssue.ToShip) > 0
	|			)
	|
	|INDEX BY
	|	DocumentShipments,
	|	TTHasTwoFields,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.DocumentShipments AS ReferenceOrder,
	|	&TTStateOfFieldSSpendingOrders AS TTStateOfFieldSSpendingOrders,
	|	TTHasOrders.Warehouse            AS Warehouse,
	|	TTHasOrders.Recipient       AS Recipient,
	|	CASE
	|		WHEN TueThereAreOrders_3.Warehouse IS NULL
	|			THEN 1
	|		ELSE 3
	|	END                               AS State
	|INTO TTStateOfSpendingOrders
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreOrders_3 AS TueThereAreOrders_3
	|		ON TTHasOrders.DocumentShipments = TueThereAreOrders_3.DocumentShipments
	|			AND &TTStateOfSpendingOrdersCondition
	|			AND TTHasOrders.Warehouse = TueThereAreOrders_3.Warehouse
	|			AND TTHasOrders.Recipient = TueThereAreOrders_3.Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreOrders_3";
	
	ConfigureProductsField(
		QueryText, ReplacementParameters, "&TTHasTwoFields_ AS TTHasTwoFields_,", "NestedQuery");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTHasTwoFields AS TTHasTwoFields,",
		"References",
		"&TTHasOneCondition",
		"GoodsForIssue",
		"TTHasTwoFields,");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTStateOfFieldSSpendingOrders AS TTStateOfFieldSSpendingOrders,",
		"TTHasOrders",
		"&TTStateOfSpendingOrdersCondition",
		"TueThereAreOrders_3");
	
	AddlCondition = "TRUE";
	If FilterParameters.Department Then
		AddlCondition = AddlCondition +
		" AND (Recipient IN (&Department)
		|	OR (CAST(Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|		AND CAST(Recipient AS Catalog.Warehouses).Department IN (&Department)))";
	EndIf;
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "DocumentShipments", TypesOfOrders, FilterParameters.Warehouse, AddlCondition, False, True);
	If FilterParameters.BusinessTransaction Then
		QueryText = StrReplace(QueryText, "DocumentsRegistry.BusinessOperation",
			"CASE
			|WHEN DocumentsRegistry.Ref REFS Document.ProductionStage2_2 THEN
			|	VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|WHEN DocumentsRegistry.Ref REFS Document.RMOrder THEN
			|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|ELSE
			|	DocumentsRegistry.BusinessOperation
			|END");
	EndIf;
	ConvertRequestTextToReadyToUse(QueryText, "TTStateOfSpendingOrders", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextStatesOfIncomingOrders(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration, ReplacementParameters = Undefined)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		
		QueryText =
		"SELECT TOP 0
		|	NULL AS ToRegister,
		|	NULL AS ReferenceOrder,
		|	&Fields AS Fields,
		|	NULL AS Warehouse,
		|	NULL AS Sender,
		|	NULL AS BusinessTransaction,
		|	NULL AS State
		|INTO TTStateOfIncomingOrders";
		
		ProductsField = "";
		If ValueIsFilled(ReplacementParameters) And ReplacementParameters.Property("ProductsField") Then
			ProductsField = "NULL AS Products,
							   |NULL AS Characteristic,"
		EndIf;
		
		QueryText = StrReplace(QueryText, "&Fields AS Fields,", ProductsField);
		
		Return QueryText;
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.DocumentInflow   AS DocumentInflow,
	|	&TTHasTwoFields_ AS TTHasTwoFields_,
	|	NestedQuery.Warehouse                 AS Warehouse,
	|	NestedQuery.Sender           AS Sender,
	|	NestedQuery.BusinessOperation AS BusinessOperation
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.Warehouse AS Warehouse,
	|		Balance.DocumentInflow   AS DocumentInflow,
	|		Balance.Products          AS Products,
	|		Balance.Characteristic        AS Characteristic,
	|		Balance.Purpose            AS Purpose,
	|		Balance.Series                 AS Series,
	|		Balance.ControlledLotReference  AS ControlledLotReference,
	|		Balance.Sender           AS Sender,
	|		Balance.BusinessOperation AS BusinessOperation
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(, &ConditionForSelectingResidues) AS Balance
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON Balance.Warehouse = CatWarehouses.Ref
	|			AND (CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt)
	|			AND (CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)
	|	WHERE
	|		NOT CatWarehouses.Ref IS NULL
	|		AND Balance.ToRegisterGoodsReceiptsBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.DocumentInflow
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.DocumentInflow   AS DocumentInflow,
	|	&TTHasTwoFields AS TTHasTwoFields,
	|	References.Warehouse                 AS Warehouse,
	|	References.Sender           AS Sender,
	|	References.BusinessOperation AS BusinessOperation
	|INTO TueThereAreOrders_3
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.GoodsToReceive AS GoodsReadyForReceipt
	|			WHERE
	|				GoodsReadyForReceipt.Active
	|				AND GoodsReadyForReceipt.DocumentInflow = References.DocumentInflow
	|				AND &TTHasOneCondition
	|				AND GoodsReadyForReceipt.Warehouse = References.Warehouse
	|				AND GoodsReadyForReceipt.Sender = References.Sender
	|				AND GoodsReadyForReceipt.BusinessOperation = References.BusinessOperation
	|				AND GoodsReadyForReceipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			HAVING
	|				SUM(GoodsReadyForReceipt.ToRegisterGoodsReceipts) > 0)
	|
	|INDEX BY
	|	DocumentInflow,
	|	TTHasTwoFields,
	|	Warehouse,
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.DocumentInflow   AS ReferenceOrder,
	|	&TTStatesOfIncomingOrders AS TTStatesOfIncomingOrders,
	|	TTHasOrders.Warehouse                 AS Warehouse,
	|	TTHasOrders.Sender           AS Sender,
	|	TTHasOrders.BusinessOperation AS BusinessTransaction,
	|	CASE
	|		WHEN TueThereAreOrders_3.Warehouse IS NULL
	|			THEN 1
	|		ELSE 3
	|	END                                  AS State
	|INTO TTStateOfIncomingOrders
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreOrders_3 AS TueThereAreOrders_3
	|		ON TTHasOrders.DocumentInflow = TueThereAreOrders_3.DocumentInflow
	|			AND &TTStateOfIncomingOrdersCondition
	|			AND TTHasOrders.Warehouse = TueThereAreOrders_3.Warehouse
	|			AND TTHasOrders.Sender = TueThereAreOrders_3.Sender
	|			AND TTHasOrders.BusinessOperation = TueThereAreOrders_3.BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreOrders_3";
	
	ConfigureProductsField(
		QueryText, ReplacementParameters, "&TTHasTwoFields_ AS TTHasTwoFields_,", "NestedQuery");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTHasTwoFields AS TTHasTwoFields,",
		"References",
		"&TTHasOneCondition",
		"GoodsReadyForReceipt",
		"TTHasTwoFields,");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTStatesOfIncomingOrders AS TTStatesOfIncomingOrders,",
		"TTHasOrders",
		"&TTStateOfIncomingOrdersCondition",
		"TueThereAreOrders_3");
	
	AddlCondition = "TRUE";
	If FilterParameters.BusinessTransaction Then
		AddlCondition = AddlCondition +
		" AND BusinessOperation IN (&BusinessTransaction)";
	EndIf;
	
	If FilterParameters.Department Then
		AddlCondition = AddlCondition +
		" AND (Sender IN (&Department)
		|	OR (CAST(Sender AS Catalog.Warehouses).ShopFloorStockroom
		|		AND CAST(Sender AS Catalog.Warehouses).Department IN (&Department)))";
	EndIf;
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "DocumentInflow", TypesOfOrders, FilterParameters.Warehouse, AddlCondition, True);
	ConvertRequestTextToReadyToUse(QueryText, "TTStateOfIncomingOrders", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextRevenueStates(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS Warehouse,
			|	NULL AS State
			|INTO TTStateReceipts";
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.PurchaseOrder AS PurchaseOrder,
	|	NestedQuery.Warehouse           AS Warehouse
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.PurchaseOrder AS PurchaseOrder,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.RowCode AS RowCode,
	|		Balance.Warehouse AS Warehouse
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(, &ConditionForSelectingResidues) AS Balance
	|	WHERE
	|		Balance.ToRegisterBalance <> 0
	|		AND NOT Balance.PurchaseOrder.Ref IS NULL // to work out RLS
	|		AND NOT Balance.Warehouse.Ref IS NULL
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.PurchaseOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.PurchaseOrder AS PurchaseOrder,
	|	References.Warehouse           AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|			WHERE
	|				PurchaseOrders.Active
	|				AND PurchaseOrders.PurchaseOrder = References.PurchaseOrder
	|				AND PurchaseOrders.Warehouse = References.Warehouse
	|				AND PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(PurchaseOrders.ToRegister) > 0)
	|
	|INDEX BY
	|	PurchaseOrder,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.PurchaseOrder AS ReferenceOrder,
	|	TTHasOrders.Warehouse           AS Warehouse,
	|	CASE
	|		WHEN TueThereAreInvoices.PurchaseOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                              AS State
	|INTO TTStateReceipts
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.PurchaseOrder = TueThereAreInvoices.PurchaseOrder
	|			AND TTHasOrders.Warehouse = TueThereAreInvoices.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "PurchaseOrder", TypesOfOrders, FilterParameters.Warehouse);
	ConvertRequestTextToReadyToUse(QueryText, "TTStateReceipts", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextShipmentStates(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS Warehouse,
			|	NULL AS State
			|INTO TTShipmentStates";
		
	EndIf;
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.SalesOrder AS SalesOrder,
	|	NestedQuery.Warehouse AS Warehouse
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.ReferenceOrder AS SalesOrder,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.RowCode AS RowCode,
	|		Balance.Warehouse AS Warehouse,
	|		Balance.Series AS Series
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS Balance
	|	WHERE
	|		(Balance.QuantityToBeShippedTurnover -
	|			Balance.ShippedQuantityTurnover) <> 0
	|		AND NOT Balance.ReferenceOrder.Ref IS NULL // to work out RLS
	|		AND NOT Balance.Warehouse.Ref IS NULL
	|		AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.ReferenceOrder
	|				AND (NOT &SelectByBusinessTransactions
	|				OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization
	|				OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision
	|				OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager
	|				OR DocumentsRegistry.EmployeeResponsible IN (&Manager)))) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.SalesOrder AS SalesOrder,
	|	References.Warehouse AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|		(SELECT
	|			TRUE
	|		FROM
	|			AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|		WHERE
	|			ShipmentReferences.Active
	|			AND ShipmentReferences.ReferenceOrder = References.SalesOrder
	|			AND ShipmentReferences.Warehouse = References.Warehouse
	|			AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|		HAVING
	|			SUM(ShipmentReferences.Count) > 0)
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.SalesOrder AS ReferenceOrder,
	|	TTHasOrders.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TueThereAreInvoices.SalesOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END AS State
	|INTO TTShipmentStates
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.SalesOrder = TueThereAreInvoices.SalesOrder
	|		AND TTHasOrders.Warehouse = TueThereAreInvoices.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"&ConditionForSelectingResidues";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);

	CompleteTextWithSelectionBasedOnResidues(QueryText, "ReferenceOrder", TypesOfOrders, FilterParameters.Warehouse);
	ConvertRequestTextToReadyToUse(QueryText, "TTShipmentStates", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextMovementStates(FilterParameters, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.TransferOrders) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS State
			|INTO TTMovementStates";
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.TransferOrder AS TransferOrder
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.TransferOrder AS TransferOrder,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.RowCode AS RowCode,
	|		Balance.Series AS Series
	|	FROM
	|		AccumulationRegister.TransferOrders.Balance(, ) AS Balance
	|	WHERE
	|		Balance.ToRegisterBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.TransferOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByWarehouse OR DocumentsRegistry.StorageLocation.Key IN (&Warehouse))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.TransferOrder AS TransferOrder
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.TransferOrders AS TransferOrders
	|			WHERE
	|				TransferOrders.Active
	|				AND TransferOrders.TransferOrder = References.TransferOrder
	|				AND TransferOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(TransferOrders.ToRegister) > 0)
	|
	|INDEX BY
	|	TransferOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.TransferOrder AS ReferenceOrder,
	|	CASE
	|		WHEN TueThereAreInvoices.TransferOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                                 AS State
	|INTO TTMovementStates
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.TransferOrder = TueThereAreInvoices.TransferOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	ConvertRequestTextToReadyToUse(QueryText, "TTMovementStates", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextAssemblyStates(FilterParameters, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.AssemblyOrders) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS State
			|INTO TTStatesOfAssemblies";
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.AssemblyType AS AssemblyType,
	|		Balance.RowCode AS RowCode,
	|		Balance.Series AS Series
	|	FROM
	|		AccumulationRegister.AssemblyOrders.Balance(, ) AS Balance
	|	WHERE
	|		Balance.ToRegisterBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.ByAssemblyDisassemblyOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByWarehouse OR DocumentsRegistry.StorageLocation.Key IN (&Warehouse))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.AssemblyOrders AS AssemblyOrders
	|			WHERE
	|				AssemblyOrders.Active
	|				AND AssemblyOrders.ByAssemblyDisassemblyOrder = References.ByAssemblyDisassemblyOrder
	|				AND AssemblyOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(AssemblyOrders.ToRegister) > 0)
	|
	|INDEX BY
	|	ByAssemblyDisassemblyOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.ByAssemblyDisassemblyOrder AS ReferenceOrder,
	|	CASE
	|		WHEN TueThereAreInvoices.ByAssemblyDisassemblyOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                            AS State
	|INTO TTStatesOfAssemblies
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.ByAssemblyDisassemblyOrder = TueThereAreInvoices.ByAssemblyDisassemblyOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	ConvertRequestTextToReadyToUse(QueryText, "TTStatesOfAssemblies", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextStatesOfDomesticConsumption(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.InventoryConsumptionOrders) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS Warehouse,
			|	NULL AS State
			|INTO TTStateOfInternalConsumption";
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|	NestedQuery.Warehouse                        AS Warehouse
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.RowCode AS RowCode,
	|		Balance.Warehouse AS Warehouse,
	|		Balance.Series AS Series
	|	FROM
	|		AccumulationRegister.InventoryConsumptionOrders.Balance(, &ConditionForSelectingResidues) AS Balance
	|	WHERE
	|		Balance.ToRegisterBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.InventoryConsumptionOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|	References.Warehouse                        AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.InventoryConsumptionOrders AS InventoryConsumptionOrders
	|			WHERE
	|				InventoryConsumptionOrders.Active
	|				AND InventoryConsumptionOrders.InventoryConsumptionOrder = References.InventoryConsumptionOrder
	|				AND InventoryConsumptionOrders.Warehouse = References.Warehouse
	|				AND InventoryConsumptionOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(InventoryConsumptionOrders.ToRegister) > 0)
	|
	|INDEX BY
	|	InventoryConsumptionOrder,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.InventoryConsumptionOrder AS ReferenceOrder,
	|	TTHasOrders.Warehouse                        AS Warehouse,
	|	CASE
	|		WHEN TueThereAreInvoices.InventoryConsumptionOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                                           AS State
	|INTO TTStateOfInternalConsumption
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.InventoryConsumptionOrder = TueThereAreInvoices.InventoryConsumptionOrder
	|			AND TTHasOrders.Warehouse = TueThereAreInvoices.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "InventoryConsumptionOrder", TypesOfOrders, FilterParameters.Warehouse);
	If FilterParameters.BusinessTransaction Then
		QueryText = StrReplace(QueryText, "DocumentsRegistry.BusinessOperation",
			"CASE WHEN DocumentsRegistry.Ref REFS Document.RMOrder THEN
			|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|ELSE
			|	DocumentsRegistry.BusinessOperation
			|END");
	EndIf;
	ConvertRequestTextToReadyToUse(QueryText, "TTStateOfInternalConsumption", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextStatesOfTransfersToProduction(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration, ReplacementParameters = Undefined)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction) Then
		
		QueryText =
		"SELECT TOP 0
		|	NULL AS ToRegister,
		|	NULL AS ReferenceOrder,
		|	&Fields AS Fields,
		|	NULL AS Warehouse,
		|	NULL AS Recipient,
		|	NULL AS State
		|INTO TTStatesOfTransfersToProduction";
		
		ProductsField = "";
		If ValueIsFilled(ReplacementParameters) And ReplacementParameters.Property("ProductsField") Then
			ProductsField = "NULL AS Products,
							   |NULL AS Characteristic,"
		EndIf;
		
		QueryText = StrReplace(QueryText, "&Fields AS Fields,", ProductsField);
		
		Return QueryText;
			
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	NestedQuery.ReferenceOrder       AS ReferenceOrder,
	|	&TTHasTwoFields_ AS TTHasTwoFields_,
	|	NestedQuery.Warehouse              AS Warehouse,
	|	NestedQuery.Recipient         AS Recipient,
	|	SUM(NestedQuery.ToRegister) AS ToRegister
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.ReferenceOrder          AS ReferenceOrder,
	|		Balance.Products          AS Products,
	|		Balance.Characteristic        AS Characteristic,
	|		Balance.RowCode             AS RowCode,
	|		Balance.Warehouse                 AS Warehouse,
	|		Balance.Department         AS Department,
	|		Balance.Series                 AS Series,
	|		Balance.Purpose            AS Purpose,
	|		Balance.AssignmentSender AS AssignmentSender,
	|		Balance.Recipient 			  AS Recipient,
	|		Balance.ToRegisterBalance    AS ToRegister
	|	FROM
	|		AccumulationRegister.OrdersOfMaterialsForProduction.Balance(, &ConditionForSelectingResidues) AS Balance
	|	WHERE
	|		Balance.ToRegisterBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.ReferenceOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ReferenceOrder,
	|	TTHasTwoFields_,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder AS ReferenceOrder,
	|	&TTHasOverheadFields AS TTHasOverheadFields,
	|	References.Warehouse        AS Warehouse,
	|	References.Recipient   AS Recipient
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.OrdersOfMaterialsForProduction AS OrdersOfMaterialsForProduction
	|			WHERE
	|				OrdersOfMaterialsForProduction.Active
	|				AND OrdersOfMaterialsForProduction.ReferenceOrder = References.ReferenceOrder
	|				AND &TTHasOverheadConditions
	|				AND OrdersOfMaterialsForProduction.Warehouse        = References.Warehouse
	|				AND OrdersOfMaterialsForProduction.Recipient   = References.Recipient
	|				AND OrdersOfMaterialsForProduction.RecordType  = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(OrdersOfMaterialsForProduction.ToRegister)  > 0)
	|
	|INDEX BY
	|	ReferenceOrder,
	|	TTHasOverheadFields,
	|	Warehouse,
	|	Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.ReferenceOrder AS ReferenceOrder,
	|	&TTStatesOfTransfersToProductionFields AS TTStatesOfTransfersToProductionFields,
	|	TTHasOrders.Warehouse        AS Warehouse,
	|	TTHasOrders.Recipient   AS Recipient,
	|	CASE
	|		WHEN TueThereAreInvoices.ReferenceOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                           AS State,
	|	TTHasOrders.ToRegister  AS ToRegister
	|INTO TTStatesOfTransfersToProduction
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.ReferenceOrder = TueThereAreInvoices.ReferenceOrder
	|			AND &TTStatesOfTransfersToProductionCondition
	|			AND TTHasOrders.Warehouse = TueThereAreInvoices.Warehouse
	|			AND TTHasOrders.Recipient = TueThereAreInvoices.Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTHasTwoFields_ AS TTHasTwoFields_,",
		"NestedQuery",,,
		"TTHasTwoFields_,");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTHasOverheadFields AS TTHasOverheadFields,",
		"References",
		"&TTHasOverheadConditions",
		"OrdersOfMaterialsForProduction",
		"TTHasOverheadFields,");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTStatesOfTransfersToProductionFields AS TTStatesOfTransfersToProductionFields,",
		"TTHasOrders",
		"&TTStatesOfTransfersToProductionCondition",
		"TueThereAreInvoices");
	
	AddlCondition = "TRUE";
	If FilterParameters.Department Then
		AddlCondition = AddlCondition +
			" AND (Recipient IN(&Department)
			|	OR (VALUETYPE(Recipient) = TYPE(Catalog.Warehouses)
			|		AND CAST(Recipient AS Catalog.Warehouses).ShopFloorStockroom
			|		AND CAST(Recipient AS Catalog.Warehouses).Department IN (&Department)))";
	EndIf;
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "ReferenceOrder", TypesOfOrders, FilterParameters.Warehouse, AddlCondition,, True);
	If FilterParameters.BusinessTransaction Then
		QueryText = StrReplace(QueryText, "DocumentsRegistry.BusinessOperation",
			"CASE
			|WHEN DocumentsRegistry.Ref REFS Document.ProductionStage2_2 THEN
			|	VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|ELSE
			|	DocumentsRegistry.BusinessOperation
			|END");
	EndIf;
	ConvertRequestTextToReadyToUse(QueryText, "TTStatesOfTransfersToProduction", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction


Function QueryTextStatesOfProcessorReports2_5(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS State
			|INTO TTStateOfProcessorReports2_5";
		
	EndIf;
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.ReferenceOrder AS ReferenceOrder
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.PurchaseOrder    AS ReferenceOrder,
	|		Balance.Products       AS Products,
	|		Balance.Characteristic     AS Characteristic,
	|		Balance.Warehouse              AS Warehouse,
	|		Balance.ToRegisterBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(, &ConditionForSelectingResidues) AS Balance
	|	WHERE
	|		Balance.ToRegisterBalance > 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.PurchaseOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	
	|	UNION ALL
	|	
	// Leftovers of goods to be processed without an order
	|	SELECT
	|		Balance.ReferenceOrder                     AS ReferenceOrder,
	|		Balance.Products                     AS Products,
	|		Balance.Characteristic                   AS Characteristic,
	|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|		SUM(Balance.ToRegister)               AS ToRegister
	|	FROM
	|		(SELECT
	|			Balance.ItemsLocationAttributes.Contract        AS ReferenceOrder,
	|			Balance.ItemsLocationAttributes.Products   AS Products,
	|			Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	// The remaining goods that require confirmation of the release are always negative
	|			-Balance.CountBalance                        AS ToRegister
	|		FROM
	|			AccumulationRegister.CompanyGoods.Balance(,
	|				NOT &SelectByOrganization OR Organization IN (&Organization)) AS Balance
	|		WHERE
	|			Balance.CountBalance < 0
	|			AND Balance.InventoryOwnerAttribute.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SubcontractorProducts),
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|			AND (ISNULL(Balance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|				VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|				OR ISNULL(Balance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|				VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|			AND (NOT &SelectByManager
	|				OR Balance.ItemsLocationAttributes.Contract.Manager IN (&Manager))
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			DocumentsRegistry.Contract         AS ReferenceOrder,
	|			GoodsReceipts.Products   AS Products,
	|			GoodsReceipts.Characteristic AS Characteristic,
	|			-GoodsReceipts.Count    AS ToRegister
	|		FROM
	|			AccumulationRegister.PurchaseOrders.Turnovers(,,
	|				Auto,
	|				VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)) AS TurnoverOnOrders
	|			
	|			INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsReceipts
	|			ON GoodsReceipts.ReferenceOrder = TurnoverOnOrders.PurchaseOrder
	|			AND GoodsReceipts.RowCode = TurnoverOnOrders.RowCode
	|			AND GoodsReceipts.Ref.Posted
	|			
	|			LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON DocumentsRegistry.Ref = TurnoverOnOrders.PurchaseOrder
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|			
	|		WHERE
	|			(NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|			AND (NOT &SelectByManager
	|				OR DocumentsRegistry.Contract.Manager IN (&Manager))
	|	) AS Balance
	|	
	|	GROUP BY
	|		Balance.ReferenceOrder,
	|		Balance.Products,
	|		Balance.Characteristic
	|		
	|	HAVING
	|		SUM(Balance.ToRegister) > 0
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder AS ReferenceOrder
	|INTO TTHasReports
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|		WHERE
	|			PurchaseOrders.Active
	|			AND PurchaseOrders.PurchaseOrder = References.ReferenceOrder
	|			AND PurchaseOrders.ToRegister > 0
	|			AND PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Expense))
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.ReferenceOrder AS ReferenceOrder,
	|	CASE
	|		WHEN TTHasReports.ReferenceOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                           AS State
	|INTO TTStateOfProcessorReports2_5
	|FROM
	|	TTHasOrders AS TTHasOrders
	|	
	|	LEFT JOIN TTHasReports AS TTHasReports
	|	ON TTHasOrders.ReferenceOrder = TTHasReports.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasReports";
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "PurchaseOrder", TypesOfOrders);
	
	ConvertRequestTextToReadyToUse(
		QueryText,
		"TTStateOfProcessorReports2_5",
		OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextStateOfProceedsFromProcessor2_5(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ReferenceOrder,
			|	NULL AS Warehouse,
			|	NULL AS State
			|INTO TTStateOfRevenueFromProcessor2_5";
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.ReferenceOrder AS ReferenceOrder,
	|	NestedQuery.Warehouse        AS Warehouse
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.PurchaseOrder     AS ReferenceOrder,
	|		Balance.Products        AS Products,
	|		Balance.Characteristic      AS Characteristic,
	|		Balance.Warehouse               AS Warehouse
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(, &ConditionForSelectingResidues) AS Balance
	|	WHERE
	|		Balance.ToReceiveBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.PurchaseOrder
	|				AND (NOT &SelectByBusinessTransactions OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByWarehouse OR DocumentsRegistry.StorageLocation.Key IN (&Warehouse))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder                      AS ReferenceOrder,
	|	References.Warehouse                             AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|			WHERE
	|				PurchaseOrders.Active
	|				AND PurchaseOrders.PurchaseOrder = References.ReferenceOrder
	|				AND PurchaseOrders.Warehouse = References.Warehouse
	|				AND PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(PurchaseOrders.ToReceive) > 0)
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.ReferenceOrder                AS ReferenceOrder,
	|	TTHasOrders.Warehouse                       AS Warehouse,
	|	CASE
	|		WHEN TueThereAreInvoices.ReferenceOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                              AS State
	|INTO TTStateOfRevenueFromProcessor2_5
	|FROM
	|	TTHasOrders AS TTHasOrders
	|	
	|	LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|	ON TueThereAreInvoices.ReferenceOrder = TTHasOrders.ReferenceOrder
	|	AND TueThereAreInvoices.Warehouse = TTHasOrders.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "PurchaseOrder", TypesOfOrders, FilterParameters.Warehouse);
	ConvertRequestTextToReadyToUse(QueryText, "TTStateOfRevenueFromProcessor2_5", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextStatesOfTransfersFromProduction(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration, ReplacementParameters = Undefined)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ReferencesToTransferFromProduction) Then
		
		QueryText =
		"SELECT TOP 0
		|	NULL AS ToRegister,
		|	NULL AS ReferenceOrder,
		|	&Fields AS Fields,
		|	NULL AS Warehouse,
		|	NULL AS Sender,
		|	NULL AS BusinessTransaction,
		|	NULL AS State
		|INTO TTTransfersStateOfTransferFromProduction";
		
		ProductsField = "";
		If ValueIsFilled(ReplacementParameters) And ReplacementParameters.Property("ProductsField") Then
			ProductsField = "NULL AS Products,
							   |NULL AS Characteristic,"
		EndIf;
		
		QueryText = StrReplace(QueryText, "&Fields AS Fields,", ProductsField);
		
		Return QueryText;
		
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	NestedQuery.ReferenceOrder       AS ReferenceOrder,
	|	&TTHasTwoFields_ AS TTHasTwoFields_,
	|	NestedQuery.Recipient         AS Recipient,
	|	NestedQuery.Sender        AS Sender,
	|	NestedQuery.Operation           AS Operation,
	|	SUM(NestedQuery.ToRegister) AS ToRegister
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.Sender           AS Sender,
	|		Balance.Recipient            AS Recipient,
	|		Balance.ReferenceOrder          AS ReferenceOrder,
	|		Balance.Products          AS Products,
	|		Balance.Characteristic        AS Characteristic,
	|		Balance.Purpose            AS Purpose,
	|		Balance.AssignmentSender AS AssignmentSender,
	|		Balance.Series                 AS Series,
	|		Balance.Operation              AS Operation,
	|		Balance.RowCode             AS RowCode,
	|		Balance.CountBalance     AS ToRegister
	|	FROM
	|		AccumulationRegister.ReferencesToTransferFromProduction.Balance(, &ConditionForSelectingResidues) AS Balance
	|	WHERE
	|		Balance.CountBalance <> 0
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.ReferenceOrder
	|				AND (NOT &SelectByOrganization OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|			)
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ReferenceOrder,
	|	TTHasTwoFields_,
	|	NestedQuery.Recipient,
	|	NestedQuery.Sender,
	|	NestedQuery.Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder AS ReferenceOrder,
	|	&TTHasOverheadFields AS TTHasOverheadFields,
	|	References.Recipient   AS Recipient,
	|	References.Sender  AS Sender,
	|	References.Operation     AS Operation
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				AccumulationRegister.ReferencesToTransferFromProduction AS ReferencesToTransferFromProduction
	|			WHERE
	|				ReferencesToTransferFromProduction.Active
	|				AND ReferencesToTransferFromProduction.ReferenceOrder = References.ReferenceOrder
	|				AND &TTHasOverheadConditions
	|				AND ReferencesToTransferFromProduction.Recipient = References.Recipient
	|				AND ReferencesToTransferFromProduction.Sender = References.Sender
	|				AND ReferencesToTransferFromProduction.Operation = References.Operation
	|				AND ReferencesToTransferFromProduction.RecordType = VALUE(AccumulationRecordType.Expense)
	|			HAVING
	|				SUM(ReferencesToTransferFromProduction.Count) > 0)
	|
	|INDEX BY
	|	ReferenceOrder,
	|	TTHasOverheadFields,
	|	Recipient,
	|	Sender,
	|	Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.ReferenceOrder AS ReferenceOrder,
	|	&TTTransfersStateOfTransferFromProductionField AS TTTransfersStateOfTransferFromProductionField,
	|	TTHasOrders.Recipient   AS Warehouse,
	|	TTHasOrders.Sender  AS Sender,
	|	TTHasOrders.Operation     AS BusinessTransaction,
	|	CASE
	|		WHEN TueThereAreInvoices.ReferenceOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END                           AS State,
	|	TTHasOrders.ToRegister  AS ToRegister
	|INTO TTTransfersStateOfTransferFromProduction
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.ReferenceOrder = TueThereAreInvoices.ReferenceOrder
	|			AND &TTStatesOfTransfersFromProductionCondition
	|			AND TTHasOrders.Recipient = TueThereAreInvoices.Recipient
	|			AND TTHasOrders.Sender = TueThereAreInvoices.Sender
	|			AND TTHasOrders.Operation = TueThereAreInvoices.Operation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTHasTwoFields_ AS TTHasTwoFields_,",
		"NestedQuery",,,
		"TTHasTwoFields_,");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTHasOverheadFields AS TTHasOverheadFields,",
		"References",
		"&TTHasOverheadConditions",
		"ReferencesToTransferFromProduction",
		"TTHasOverheadFields,");
	
	ConfigureProductsField(
		QueryText,
		ReplacementParameters,
		"&TTTransfersStateOfTransferFromProductionField AS TTTransfersStateOfTransferFromProductionField,",
		"TTHasOrders",
		"&TTStatesOfTransfersFromProductionCondition",
		"TueThereAreInvoices");
	
	AddlCondition = "VALUETYPE(Recipient) = TYPE(Catalog.Warehouses)";
	If FilterParameters.BusinessTransaction Then
		AddlCondition = AddlCondition + " AND Operation IN (&BusinessTransaction)";
	EndIf;
	
	If FilterParameters.Department Then
		AddlCondition = AddlCondition +
		" AND (Sender IN(&Department)
		|	OR (CAST(Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|		AND CAST(Recipient AS Catalog.Warehouses).Department IN (&Department)))";
	EndIf;
	
	If FilterParameters.Warehouse Then
		AddlCondition = AddlCondition + " AND Recipient IN (&Warehouse)";
	EndIf;
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "ReferenceOrder", TypesOfOrders, False, AddlCondition);
	ConvertRequestTextToReadyToUse(QueryText, "TTTransfersStateOfTransferFromProduction", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction


Function QueryTextTransfersStates(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS Warehouse,
			|	NULL AS State
			|INTO TTTransfersState";
		
	EndIf;
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	Orders.SalesOrder AS SalesOrder,
	|	Orders.Warehouse AS Warehouse
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.ReferenceOrder AS SalesOrder,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.RowCode AS RowCode,
	|		Balance.Warehouse AS Warehouse,
	|		Balance.Series AS Series
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS Balance
	|	WHERE
	|		(Balance.QuantityToBeShippedTurnover -
	|			Balance.ShippedQuantityTurnover) <> 0
	|		AND NOT Balance.ReferenceOrder.Ref IS NULL // to work out RLS
	|		AND NOT Balance.Warehouse.Ref IS NULL
	|		AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.ReferenceOrder
	|				AND (NOT &SelectByBusinessTransactions
	|				OR DocumentsRegistry.BusinessOperation IN (&BusinessTransaction))
	|				AND (NOT &SelectByOrganization
	|				OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision
	|				OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager
	|				OR DocumentsRegistry.EmployeeResponsible IN (&Manager)))) AS Orders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.SalesOrder AS SalesOrder,
	|	References.Warehouse AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|		WHERE
	|			ShipmentReferences.Active
	|			AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			AND ShipmentReferences.ReferenceOrder = References.SalesOrder
	|			AND ShipmentReferences.Warehouse = References.Warehouse
	|		HAVING
	|			SUM(ShipmentReferences.Count) > 0)
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTHasOrders.SalesOrder AS ReferenceOrder,
	|	TTHasOrders.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TueThereAreInvoices.SalesOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END AS State
	|INTO TTTransfersState
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.SalesOrder = TueThereAreInvoices.SalesOrder
	|		AND TTHasOrders.Warehouse = TueThereAreInvoices.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"&ConditionForSelectingResidues";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "ReferenceOrder", TypesOfOrders, FilterParameters.Warehouse);
	ConvertRequestTextToReadyToUse(QueryText, "TTTransfersState", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

Function QueryTextStatesOfReportsToGivers2_5(FilterParameters, TypesOfOrders, OnlyAvailabilityForRegistration)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
	 Or Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
		
		Return
			"SELECT TOP 0
			|	NULL AS ToRegister,
			|	NULL AS ReferenceOrder,
			|	NULL AS Contract,
			|	NULL AS Warehouse,
			|	NULL AS State
			|INTO TTStateReportsToGivers2_5";
		
	EndIf;
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	NestedQuery.SalesOrder AS SalesOrder,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.Warehouse AS Warehouse
	|INTO TTHasOrders
	|FROM
	|	(SELECT
	|		Balance.ReferenceOrder AS SalesOrder,
	|		CAST(Balance.ReferenceOrder AS Document.MaterialProviderOrder2_5).Contract AS Contract,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.RowCode AS RowCode,
	|		Balance.Warehouse AS Warehouse,
	|		Balance.Series AS Series,
	|		(Balance.ForRegistrationQuantityTurnover -
	|			Balance.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS Balance
	|	WHERE
	|		(Balance.ForRegistrationQuantityTurnover -
	|			Balance.IssuedQuantityTurnover) <> 0
	|		AND NOT Balance.ReferenceOrder.Ref IS NULL // to work out RLS
	|		AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Balance.ReferenceOrder
	|				AND (NOT &SelectByOrganization
	|				OR DocumentsRegistry.Organization IN (&Organization))
	|				AND (NOT &SelectByDivision
	|				OR DocumentsRegistry.Department IN (&Department))
	|				AND (NOT &SelectByManager
	|				OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
	|				AND NOT DocumentsRegistry.AdditionalRecord)
	|
	|	UNION ALL
	|
	|	SELECT
	|		VALUE(Document.MaterialProviderOrder2_5.EmptyRef) AS SalesOrder,
	|		BalancesWithoutOrder.Contract AS Contract,
	|		BalancesWithoutOrder.Products AS Products,
	|		BalancesWithoutOrder.Characteristic AS Characteristic,
	|		0 AS RowCode,
	|		BalancesWithoutOrder.Warehouse AS Warehouse,
	|		BalancesWithoutOrder.Series AS Series,
	|		BalancesWithoutOrder.ToRegister AS ToRegister
	|	FROM
	|		&BalancesWithoutOrder AS BalancesWithoutOrder) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.SalesOrder AS SalesOrder,
	|	References.Contract AS Contract,
	|	References.Warehouse AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	TRUE IN
	|		(SELECT
	|			TRUE
	|		FROM
	|			AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|		WHERE
	|			ShipmentReferences.Active
	|			AND ShipmentReferences.ReferenceOrder = References.SalesOrder
	|			AND ShipmentReferences.Warehouse = References.Warehouse
	|			AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|		HAVING
	|			SUM(ShipmentReferences.Count) > 0)
	|
	|UNION ALL
	|
	|SELECT
	|	References.SalesOrder AS SalesOrder,
	|	References.Contract AS Contract,
	|	References.Warehouse AS Warehouse
	|FROM
	|	TTHasOrders AS References
	|WHERE
	|	References.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|	AND TRUE IN
	|		(SELECT
	|			TRUE
	|		FROM
	|			AccumulationRegister.CompanyGoods AS CompanyGoods
	|		WHERE
	|			CompanyGoods.Active
	|			AND CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND CompanyGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			AND CAST(CompanyGoods.InventoryOwnerAttribute.Contract AS
	|				Catalog.CounterpartyContracts).ContractType = VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
	|			AND CompanyGoods.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			AND CompanyGoods.InventoryOwnerAttribute.Contract = References.Contract
	|			AND CompanyGoods.ItemsLocationAttributes.StorageLocation = References.Warehouse
	|		HAVING
	|			SUM(CompanyGoods.Count) > 0)
	|
	|INDEX BY
	|	SalesOrder,
	|	Contract,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTHasOrders.SalesOrder AS ReferenceOrder,
	|	TTHasOrders.Contract AS Contract,
	|	TTHasOrders.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TueThereAreInvoices.SalesOrder IS NULL
	|			THEN 1
	|		ELSE 2
	|	END AS State
	|INTO TTStateReportsToGivers2_5
	|FROM
	|	TTHasOrders AS TTHasOrders
	|		LEFT JOIN TueThereAreInvoices AS TueThereAreInvoices
	|		ON TTHasOrders.SalesOrder = TueThereAreInvoices.SalesOrder
	|		AND TTHasOrders.Contract = TueThereAreInvoices.Contract
	|		AND TTHasOrders.Warehouse = TueThereAreInvoices.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTHasOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TueThereAreInvoices";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"&ConditionForSelectingResidues AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
	
	QueryTextBalancesWithoutOrder = StrReplace(TextOfRequestForStateOfReportsGivers2_5BalancesWithoutOrder(),
												"&AdditionalConditionsOrganizationSProducts",
												"TRUE");
	
	QueryTextBalancesWithoutOrder = StrReplace(QueryTextBalancesWithoutOrder,
												"&AdditionalConditionsCustomerOrders",
												"TRUE");
	
	QueryText = StrReplace(QueryText, "&BalancesWithoutOrder", StrTemplate("(%1)", QueryTextBalancesWithoutOrder));
	
	CompleteTextWithSelectionBasedOnResidues(QueryText, "ReferenceOrder", TypesOfOrders, FilterParameters.Warehouse);
	
	ConvertRequestTextToReadyToUse(
		QueryText, "TTStateReportsToGivers2_5", OnlyAvailabilityForRegistration);
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for Balances without an order for issuing giver reports
// 
// Returns:
//  String - Query text
//
Function TextOfRequestForStateOfReportsGivers2_5BalancesWithoutOrder() Export
	
	QueryText =
		"SELECT
		|	BalancesWithoutOrder.Contract AS Contract,
		|	BalancesWithoutOrder.Products AS Products,
		|	BalancesWithoutOrder.Characteristic AS Characteristic,
		|	BalancesWithoutOrder.Purpose AS Purpose,
		|	BalancesWithoutOrder.Warehouse AS Warehouse,
		|	BalancesWithoutOrder.Series AS Series,
		|	SUM(BalancesWithoutOrder.ToRegister) AS ToRegister
		|FROM
		|	(SELECT
		|		CompanyGoods.InventoryOwnerAttribute.Contract AS Contract,
		|		CompanyGoods.ItemsLocationAttributes.Products AS Products,
		|		CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
		|		CompanyGoods.ItemsLocationAttributes.Purpose AS Purpose,
		|		CompanyGoods.ItemsLocationAttributes.StorageLocation AS Warehouse,
		|		CompanyGoods.ItemsLocationAttributes.Series AS Series,
		|		-CompanyGoods.CountBalance AS ToRegister
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(,
		|			InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|		AND CAST(InventoryOwnerAttribute.Contract AS
		|			Catalog.CounterpartyContracts).ContractType = VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
		|		AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|		AND (NOT &SelectByOrganization
		|		OR Organization IN (&Organization))
		|		AND (NOT &SelectByWarehouse
		|		OR ItemsLocationAttributes.StorageLocation IN (&Warehouse))
		|		AND &AdditionalConditionsOrganizationSProducts) AS CompanyGoods
		|	WHERE
		|		CompanyGoods.CountBalance < 0
		|
		|	UNION ALL
		|
		|	SELECT
		|		CAST(Turnovers.ReferenceOrder AS Document.MaterialProviderOrder2_5).Contract AS Contract,
		|		Turnovers.Products AS Products,
		|		Turnovers.Characteristic AS Characteristic,
		|		Goods.Purpose AS Purpose,
		|		Turnovers.Warehouse AS Warehouse,
		|		Turnovers.Series AS Series,
		|		-Goods.Count AS ToRegister
		|	FROM
		|		#ShipmentOrdersTurnoverExpanded AS Turnovers
		|			INNER JOIN Document.GoodsShipmentFromStorage.Goods AS Goods
		|			ON Turnovers.ReferenceOrder = Goods.SalesOrder
		|			AND Turnovers.RowCode = Goods.RowCode
		|			AND Goods.Ref.Posted
		|	WHERE
		|		NOT CAST(Turnovers.ReferenceOrder AS Document.MaterialProviderOrder2_5).Ref IS NULL // to work out RLS
		|		AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			WHERE
		|				DocumentsRegistry.Ref = Turnovers.ReferenceOrder
		|				AND (NOT &SelectByOrganization
		|				OR DocumentsRegistry.Organization IN (&Organization))
		|				AND (NOT &SelectByDivision
		|				OR DocumentsRegistry.Department IN (&Department))
		|				AND (NOT &SelectByManager
		|				OR DocumentsRegistry.EmployeeResponsible IN (&Manager))
		|				AND NOT DocumentsRegistry.AdditionalRecord)
		|		AND &AdditionalConditionsCustomerOrders) AS BalancesWithoutOrder
		|GROUP BY
		|	BalancesWithoutOrder.Contract,
		|	BalancesWithoutOrder.Products,
		|	BalancesWithoutOrder.Characteristic,
		|	BalancesWithoutOrder.Purpose,
		|	BalancesWithoutOrder.Warehouse,
		|	BalancesWithoutOrder.Series
		|HAVING
		|	SUM(BalancesWithoutOrder.ToRegister) > 0
		|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"&ConditionForSelectingResidues";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToRegister";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Return QueryText;
	
EndFunction
Procedure CompleteTextWithSelectionBasedOnResidues(QueryText, LinksField, TypesOfOrders, Warehouse = False, AddlCondition = "", IncludingSender = False, IncludingRecipient = False)
	
	ConditionsForSelectingBalances = New Array();
	
	If ValueIsFilled(TypesOfOrders) Then
		
		If TypesOfOrders.Count() = 1 Then
			Substitution = "CAST(Balance.PurchaseOrder AS Document.InventoryConsumptionOrder).Ref";
			Substitution = StrReplace(Substitution, "Document.InventoryConsumptionOrder", TypesOfOrders[0]);
			QueryText = StrReplace(QueryText, "Balance.PurchaseOrder.Ref", Substitution);
			Substitution = "CAST(Balance.ReferenceOrder AS Document.InventoryConsumptionOrder).Ref";
			Substitution = StrReplace(Substitution, "Document.InventoryConsumptionOrder", TypesOfOrders[0]);
			QueryText = StrReplace(QueryText, "Balance.ReferenceOrder.Ref", Substitution);
		EndIf;
		
		TermsAndConditions_ = New Array();
		ConditionTemplate = "&Dimension REFS Document.InventoryConsumptionOrder";
		For Each FullDocumentName In TypesOfOrders Do
			Text = StrReplace(ConditionTemplate, "&Dimension", LinksField);
			Text = StrReplace(Text, "Document.InventoryConsumptionOrder", FullDocumentName);
			TermsAndConditions_.Add(Text);
		EndDo;
		
		//@Query-part
		ConditionConnector = " OR ";
		ConditionText = StrConcat(TermsAndConditions_, ConditionConnector);
		
		Text = StrTemplate("(%1)", ConditionText);
		ConditionsForSelectingBalances.Add(Text);
	EndIf;
	
	If Warehouse Then
		If IncludingSender Then
			ConditionsForSelectingBalances.Add("(Warehouse IN (&Warehouse) OR Sender IN (&Warehouse))");
		ElsIf IncludingRecipient Then
			ConditionsForSelectingBalances.Add("(Warehouse IN (&Warehouse) OR Recipient IN (&Warehouse))");
		Else
			ConditionsForSelectingBalances.Add("Warehouse IN (&Warehouse)");
		EndIf;
	EndIf;
	
	If Not IsBlankString(AddlCondition) Then
		ConditionsForSelectingBalances.Add(AddlCondition);
	EndIf;
	
	//@Query-part
	ConditionConnector = " AND ";
	ConditionText = StrConcat(ConditionsForSelectingBalances, ConditionConnector);
	QueryText = StrReplace(QueryText, "&ConditionForSelectingResidues", ConditionText);
	
EndProcedure


Procedure ConvertRequestTextToReadyToUse(QueryText, NameOfStateTable, Convert)
	If Convert Then
		InitialNumber = StrFind(QueryText, "TTHasOrders");
		QueryText = StrReplace(Mid(QueryText, InitialNumber, StrFind(QueryText, ";") - InitialNumber),
			"TTHasOrders",
			"SELECT ALLOWED TOP 1
			|	TRUE AS ToRegister
			|INTO TableNameSubstitution");
		QueryText = StrReplace(QueryText, "TableNameSubstitution", NameOfStateTable);
	EndIf;
EndProcedure

#EndRegion


#EndRegion
