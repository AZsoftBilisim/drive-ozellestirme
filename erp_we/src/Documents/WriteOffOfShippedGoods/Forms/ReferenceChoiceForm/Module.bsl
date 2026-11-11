
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInListOfOrders_();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrders_

&AtClient
Procedure ListOfOrders_Selection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	
	ProcessSelection(Item.CurrentData);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)

	If TMCommonUseClient.CheckForSelectedLinesInList(Items.ListOfOrders_) Then
		ProcessSelection(Items.ListOfOrders_.CurrentData);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfOrders_()
	
	InvoiceManager = Documents.WriteOffOfShippedGoods;
	
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Parameters);
	
	References = InvoiceManager.WaybillOrders(HeaderAttributes.Ref, HeaderAttributes);
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	VALUETYPE(DocumentData.Ref)   AS TypeOfOrder_,
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.Date                  AS Date,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.Terms            AS Terms,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.DocumentAmount        AS DocumentAmount,
	|	DocumentData.Manager              AS Manager,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment
	|FROM
	|	Document.SalesOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUETYPE(DocumentData.Ref)   AS TypeOfOrder_,
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.Date                  AS Date,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.Terms            AS Terms,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.DocumentAmount        AS DocumentAmount,
	|	DocumentData.Manager              AS Manager,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUETYPE(DocumentData.Ref)   AS TypeOfOrder_,
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.Date                  AS Date,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.Terms            AS Terms,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.DocumentAmount        AS DocumentAmount,
	|	DocumentData.Manager              AS Manager,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUETYPE(DocumentData.Lot)   AS TypeOfOrder_,
	|	DocumentData.Lot                AS Ref,
	|	DocumentData.Lot.Number          AS Number,
	|	DocumentData.Date                  AS Date,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.CustomerTermsOfSales   AS Terms,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.Lot.DocumentAmount AS DocumentAmount,
	|	DocumentData.Manager              AS Manager,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment
	|FROM
	|	Document.OBEntryGoods AS DocumentData
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentData.Lot IN(&References)
	|	AND DocumentData.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|";
	
	Query.SetParameter("References", References);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		ListOfOrders_.Load(QueryResult.Unload());
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSelection(CurrentRow)
	
	Close(CurrentRow.Ref);
	
EndProcedure

#EndRegion
