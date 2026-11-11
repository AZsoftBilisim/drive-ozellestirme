#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryTextReceiptDocuments();
	Common.SetDynamicListProperties(Items.ReceiptDocuments, ListProperties);
	
	ReceiptDocuments.Parameters.SetParameterValue("Organization",	Parameters.Organization);
	ReceiptDocuments.Parameters.SetParameterValue("Counterparty",	Parameters.Counterparty);
	ReceiptDocuments.Parameters.SetParameterValue("Contract",		Parameters.Contract);
	ReceiptDocuments.Parameters.SetParameterValue("ArrayOfSelectedDocuments", Parameters.ArrayOfSelectedDocuments);
	ReceiptDocuments.Parameters.SetParameterValue("Ref",		Parameters.Ref);
	ReceiptDocuments.Parameters.SetParameterValue("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	If Parameters.Property("CurrentDocument") Then
		Items.ReceiptDocuments.CurrentRow = Parameters.CurrentDocument;
	EndIf;

	SetConditionalAppearance();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceiptDocuments

&AtClient
Procedure ReceiptDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ValueChoiceProcessing1();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	
	 ValueChoiceProcessing1();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Already selected documents are displayed in gray.
	UOElement			= ConditionalAppearance.Items.Add();
	ItemField 		= UOElement.Fields.Items.Add();
	ItemField.Field 	= New DataCompositionField("ReceiptDocuments");
	
	CommonClientServer.AddCompositionItem(UOElement.Filter,
		"ReceiptDocuments.DocumentHasAlreadyBeenSelected", DataCompositionComparisonType.Equal, True);
	
	UOElement.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Function QueryTextReceiptDocuments()
	
	BaseRequestTexts = TextOfRequestGroundsForProcessingApplicationsForImportOfGoods();
	
	ArrayOfRequestTexts = New Array;
	ArrayOfRequestTexts.Add(BaseRequestTexts.TextTT);
	QueryText = 
	"SELECT DISTINCT ALLOWED
	|	ReceiptDocuments.Ref 					AS Ref,
	|	ReceiptDocuments.Number 						AS Number,
	|	ReceiptDocuments.Date 						AS Date,
	|	ReceiptDocuments.Organization 				AS Organization,
	|	ReceiptDocuments.Warehouse 						AS Warehouse,
	|	ReceiptDocuments.Department 				AS Department,
	|	ReceiptDocuments.Counterparty 				AS Counterparty,
	|	ReceiptDocuments.DocumentAmount 			AS DocumentAmount,
	|	ReceiptDocuments.Currency 					AS Currency,
	|	ReceiptDocuments.DocumentHasAlreadyBeenSelected 			AS DocumentHasAlreadyBeenSelected,
	|	ReceiptDocuments.IncomingDocumentNumber 	AS IncomingDocumentNumber,
	|	ReceiptDocuments.IncomingDocumentDate 	AS IncomingDocumentDate
	|FROM
	|	#QueryTextBasis1 AS ReceiptDocuments
	|";
	QueryText = StrReplace(QueryText, "#QueryTextBasis1", "(" + BaseRequestTexts.QueryText + ")");
	ArrayOfRequestTexts.Add(QueryText);
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator()); 
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextOfRequestGroundsForProcessingApplicationsForImportOfGoods()
	
	ArrayOfRequestTexts = New Array;
	
	QueryTemplate = "
	|SELECT
	|	TheseGrounds.Ref AS Ref,
	|	TheseGrounds.Number AS Number,
	|	TheseGrounds.Date AS Date,
	|	TheseGrounds.Organization AS Organization,
	|	&WarehouseField AS Warehouse,
	|	TheseGrounds.Department AS Department,
	|	TheseGrounds.Counterparty AS Counterparty,
	|	TheseGrounds.DocumentAmount AS DocumentAmount,
	|	TheseGrounds.Currency AS Currency,
	|	CASE
	|		WHEN TheseGrounds.Ref IN (&ArrayOfSelectedDocuments)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DocumentHasAlreadyBeenSelected,
	|	TheseGrounds.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	TheseGrounds.IncomingDocumentDate AS IncomingDocumentDate
	|FROM
	|	TTBalance AS TTBalance
	|		INNER JOIN #TheseGrounds AS TheseGrounds
	|		ON TTBalance.DocumentInflow = TheseGrounds.Ref
	|WHERE
	|	TheseGrounds.Organization = &Organization
	|	AND TheseGrounds.Counterparty = &Counterparty
	|	AND TheseGrounds.Contract = &Contract
	|
	|UNION
	|
	|SELECT
	|	TheseGrounds.Ref,
	|	TheseGrounds.Number,
	|	TheseGrounds.Date,
	|	TheseGrounds.Organization,
	|	&WarehouseField,
	|	TheseGrounds.Department,
	|	TheseGrounds.Counterparty,
	|	TheseGrounds.DocumentAmount,
	|	TheseGrounds.Currency,
	|	CASE
	|		WHEN TheseGrounds.Ref IN (&ArrayOfSelectedDocuments)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TheseGrounds.IncomingDocumentNumber,
	|	TheseGrounds.IncomingDocumentDate
	|FROM
	|	#TheseGrounds AS TheseGrounds
	|WHERE
	|	TheseGrounds.Ref IN(&ArrayOfSelectedDocuments)
	|";
	
	TextTT = 
	"SELECT
	|	GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow AS DocumentInflow
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|			,
	|			Organization = &Organization
	|				AND ImportDocumentType = &IdApplicationForImportOfGoods) AS GoodsForRegistrationOfImportDocumentsBalance
	|
	|UNION
	|
	|SELECT
	|	GoodsForRegistrationOfImportDocuments.DocumentInflow
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistrationOfImportDocuments
	|WHERE
	|	GoodsForRegistrationOfImportDocuments.Active
	|	AND GoodsForRegistrationOfImportDocuments.Recorder = &Ref
	|	AND GoodsForRegistrationOfImportDocuments.ImportDocumentType = &IdApplicationForImportOfGoods";
	
	TypesArray = Documents.ApplicationForImportationOfGoods.TypesOfDocumentsGroundsForRegistration();
	
	QueryText = "";
	
	For Each TypeName In TypesArray Do
		
		If Not AccessRight("Read", Metadata.Documents[TypeName]) Then 
			Continue;
		EndIf;
		
		RequestTextForType = StrReplace(QueryTemplate, "#TheseGrounds", "Document." + TypeName);
		If TypeName = "VendorInvoice" Then 
			RequestTextForType = StrReplace(RequestTextForType, "&WarehouseField", "TheseGrounds.Warehouse");
		ElsIf TypeName = "SubcontractorReport2_5"
			Or TypeName = "SigningOfLeaseContract" Then 
			RequestTextForType = StrReplace(RequestTextForType, "&WarehouseField", "UNDEFINED");
		EndIf;
		ArrayOfRequestTexts.Add(RequestTextForType);
		
	EndDo;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin(True));
	
	ReturnStructure = New Structure("TextTT, QueryText", TextTT, QueryText);
	Return ReturnStructure;
	
EndFunction


&AtClient
Procedure ValueChoiceProcessing1()
	
	DocumentsArray = New Array;
	
	DocumentsTable = Items.ReceiptDocuments;
	
	For Each RowIndex In DocumentsTable.SelectedRows Do
	
		RowOfSelectionTable = DocumentsTable.RowData(RowIndex);
		If RowOfSelectionTable.DocumentHasAlreadyBeenSelected Then 
			WarningText = StrReplace(NStr("vi = 'Đã chọn chứng từ %Document%';
											|ru = 'Документ %Document% уже выбран';
											|en = 'Document %Document% is already selected'; fa = 'Document %Document% is already selected';
											|it = 'Documento %Document%già selezionato';
											|pl = 'Dokument %Document% jest już wybrany';
											|tr = '%Document% belgesi zaten seçildi'"), "%Document%", String(RowOfSelectionTable.Ref));
			ShowMessageBox( , WarningText);
			Return;
		EndIf;
		
		DocumentsArray.Add(RowOfSelectionTable);
	
	EndDo; 
	
	NotifyChoice(DocumentsArray);
	
EndProcedure

#EndRegion