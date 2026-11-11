#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DocumentInpayment = Parameters.DocumentInpayment;
	Contract = Parameters.Contract;
	PeriodReverseTransaction = Parameters.PeriodReverseTransaction;
	PurchaseOrder = Parameters.PurchaseOrder;
	
	RightToAddAPurchase = AccessRight("Insert", Metadata.Documents.VendorInvoice);
	Items.FormCreateNew.Visible = RightToAddAPurchase;
	RightToAddStorno = AccessRight("Insert", Metadata.Documents.ReversingEntry);
	Items.FormMapUser.Visible = RightToAddStorno;
	
	FillInListOfDocuments();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsTable

&AtClient
Procedure DocumentsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Item.CurrentData.Purchase);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenExistingFile(Command)
	
	If Items.DocumentsTable.CurrentData = Undefined Then
		Return;
	ElsIf ValueIsFilled(Items.DocumentsTable.CurrentData.Purchase) Then
		ShowValue(, Items.DocumentsTable.CurrentData.Purchase);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateNew(Command)
	
	FormNotificationDetails = New CallbackDescription("WhenClosingDocument", ThisObject);
	
	FormParameters = New Structure("FillingValues", New Structure);
	FormParameters.FillingValues.Insert("DocumentBasis", DocumentInpayment);
	
	OpenForm("Document.VendorInvoice.Form.DocumentForm",
		FormParameters,
		ThisObject,,,,
		FormNotificationDetails);
	
EndProcedure

&AtClient
Procedure MapUser(Command)
	
	CurrentData = Items.DocumentsTable.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParametersStorno = StornoParameters(CurrentData.Purchase);
	
	OpenForm("Document.ReversingEntry.Form.DocumentForm", FormParametersStorno, ThisObject);
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function StornoParameters(ReversedDocument)
	
	StornoParameters = New Structure("FillingValues", New Structure);
	StornoParameters.FillingValues.Insert("Date", CurrentSessionDate());
	StornoParameters.FillingValues.Insert("ReversedDocument", DocumentInpayment);
	StornoParameters.FillingValues.Insert("ReplacementDocument", ReversedDocument);
	
	Return StornoParameters;
	
EndFunction

&AtClient
Procedure WhenClosingDocument(ClosingResult, AdditionalParameters) Export
	FillInListOfDocuments();
EndProcedure

&AtServer
Procedure FillInListOfDocuments()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReversingEntry.ReplacementDocument AS ReplacementDocument
	|INTO ttReversingEntry
	|FROM
	|	Document.ReversingEntry AS ReversingEntry
	|WHERE
	|	ReversingEntry.Posted
	|	AND CAST(ReversingEntry.ReversedDocument AS Document.ReceiptOfServicesToBusinessUnit).Contract = &Contract
	|	AND NOT ReversingEntry.ReversedDocument = &DocumentInpayment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN VendorInvoice.Posted
	|			THEN 0
	|		WHEN VendorInvoice.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|	VendorInvoice.Ref AS Purchase,
	|	VendorInvoice.DocumentAmount AS DocumentAmount,
	|	VendorInvoice.IncomingDocumentDate AS IncomingDocumentDate,
	|	VendorInvoice.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	VendorInvoice.Presentation AS Presentation,
	|	VendorInvoice.Currency AS Currency
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|		LEFT JOIN ttReversingEntry AS ttReversingEntry
	|		ON VendorInvoice.Ref = ttReversingEntry.ReplacementDocument
	|WHERE
	|	&ConditionOfPurchaseOrder
	|	AND VendorInvoice.Date >= &BeginOfPeriod
	|	AND VendorInvoice.Posted
	|	AND VendorInvoice.Contract = &Contract
	|	AND VendorInvoice.BusinessOperation IN (VALUE(Enum.BusinessTransactions.PurchaseFromSupplier), VALUE(Enum.BusinessTransactions.ImportFromEAEU))
	|	AND ttReversingEntry.ReplacementDocument IS NULL";
	
	If Not PurchaseOrder.IsEmpty() Then
		Query.Text = StrReplace(Query.Text, "&ConditionOfPurchaseOrder", "VendorInvoice.PurchaseOrder = &PurchaseOrder");
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionOfPurchaseOrder", "TRUE");
	EndIf;
	
	If Parameters.Property("DocumentInpayment") 
		And Parameters.DocumentInpayment <> Documents.ReceiptOfServicesToBusinessUnit.EmptyRef() Then
		DateOfReceipt = Common.ObjectAttributeValue(Parameters.DocumentInpayment, "Date");
		BeginOfPeriod = Max(PeriodReverseTransaction.StartDate, DateOfReceipt);
	Else
		BeginOfPeriod = PeriodReverseTransaction.StartDate
	EndIf;
	
	Query.SetParameter("PurchaseOrder", PurchaseOrder);
	Query.SetParameter("DocumentInpayment", DocumentInpayment);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("Contract", Contract);
	
	DocumentsTable.Load(Query.Execute().Unload());
	
EndProcedure

#EndRegion