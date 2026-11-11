
#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	AmountReceived = Parameters.AmountReceived;
	AmountExpensed = Parameters.AmountExpensed;
	Currency = Parameters.Currency;
	
	Multicurrency = Parameters.Multicurrency;
	Items.FooterGroup.Visible = Not Multicurrency;
	
	TableOfPurchasingDocument.Clear();
	Selection = SelectionOfProcurementDocuments(Parameters);
	While Selection.Next() Do
		NewRow = TableOfPurchasingDocument.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.PurchasingDocumentPresentation = StrTemplate(" %1 " + NStr("vi = 'từ %2';
																			|ru = 'от %2';
																			|en = 'dated %2'; fa = 'dated %2';
																			|it = 'da %2';
																			|pl = 'od %2';
																			|tr = '%2 tarihinden'"), Selection.Number, Format(Selection.Date, "DLF=D"));
	EndDo;
	
	SetSignsOfPresenceOfLineInDocument(Parameters.PurchasingDocumentsList);
	
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.DocumentReference);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not ClosingInProgress And Modified Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
				|ru = 'Данные были изменены. Перенести изменения в документ?';
				|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
				|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
				|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"),
			QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		
		ClosingInProgress = True;
		Modified = False;
		MovePurchaseDocumentsToDocument();
		
	ElsIf Response = DialogReturnCode.No Then
		
		ClosingInProgress = True;
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure TableOfPurchasingDocumentSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.TableOfPurchasingDocument.CurrentData <> Undefined Then
		If Field.Name = "TableOfPurchasingDocumentPurchasingDocumentPresentation" Then
			ShowValue(Undefined, Items.TableOfPurchasingDocument.CurrentData.DocumentPurchases);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TableOfPurchasingDocumentOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotals();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRows(Command)
	
	SelectRowsServer(True);
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure ClearRows(Command)
	
	SelectRowsServer(False);
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	MovePurchaseDocumentsToDocument();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfPurchasingDocumentPurchasingDocumentPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfPurchasingDocument.DocumentPurchases");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfPurchasingDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfPurchasingDocument.ExistsInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfPurchasingDocumentSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfPurchasingDocument.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đa tiền tệ>';
													|ru = '<Мультивалютный>';
													|en = '<Multicurrency>'; fa = '<Multicurrency>';
													|it = '<Multivaluta>';
													|pl = '<Multicurrency>';
													|tr = '<Çoklu para birimi>'"));
	
EndProcedure

&AtServer
Function SelectionOfProcurementDocuments(Var_Parameters)
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS DocumentPurchases,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Partner AS Vendor,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum
	|	
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|	INNER JOIN TTPurchaseDocuments AS PurchaseDocumentsAll
	|	ON PurchaseDocumentsAll.Ref = DocumentData.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS DocumentPurchases,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Partner AS Vendor,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum
	|	
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.ExpenseReport = &DocumentReference
	|	AND &LinkFilledIn
	|	AND DocumentData.Date <= &ExpenseReportDate
	|	AND DocumentData.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	ETicketsData.Ref AS DocumentPurchases,
	|	ETicketsData.TicketNumber AS Number,
	|	ETicketsData.Date AS Date,
	|	ETicketsData.Carrier AS Vendor,
	|	ETicketsData.CashFlowItem AS CashFlowItem,
	|	ETicketsData.Currency AS Currency,
	|	ETicketAmounts.DocumentAmount AS Sum
	|FROM
	|	TTETicketData AS ETicketsData
	|		INNER JOIN TTOfAmountOfElectronicTickets AS ETicketAmounts
	|		ON ETicketsData.Ref = ETicketAmounts.Ref
	|";
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextTTPurchaseDocumentsAll());
	ArrayOfTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	PickingParameters = New Structure("DocumentReference, AdvanceHolder, Organization, Department, Currency, Multicurrency, ExpenseReportDate");
	FillPropertyValues(PickingParameters, Var_Parameters);
	
	For Each Parameter_Selection In PickingParameters Do
		Query.SetParameter(Parameter_Selection.Key, Parameter_Selection.Value);
	EndDo;
	Query.SetParameter("LinkFilledIn", ValueIsFilled(PickingParameters.DocumentReference));
	
	Return Query.Execute().Select();
	
EndFunction

&AtServer
Procedure SetSignsOfPresenceOfLineInDocument(PurchasingDocumentsList)
	
	For Each TableRow In TableOfPurchasingDocument Do
		If PurchasingDocumentsList.FindByValue(TableRow.DocumentPurchases) <> Undefined Then
			TableRow.ExistsInTheDocument = True;
		EndIf;
		TableRow.RowIsSelected = TableRow.ExistsInTheDocument;
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectRowsServer(SelectionValue = True)
	
	For Each TableRow In TableOfPurchasingDocument.FindRows(New Structure("RowIsSelected", Not SelectionValue)) Do
		TableRow.RowIsSelected = SelectionValue;
	EndDo;
	
EndProcedure

&AtClient
Procedure CalculateTotals()
	
	AmountSelected = 0;
	For Each TableRow In TableOfPurchasingDocument Do
		If TableRow.RowIsSelected Then
			AmountSelected = AmountSelected + TableRow.Sum;
		EndIf;
	EndDo;
	AmountSpentTotal = AmountExpensed + AmountSelected;
	
EndProcedure

&AtClient
Procedure MovePurchaseDocumentsToDocument()
	
	Modified = False;
	SelectedDocuments = New Array;
	For Each TableRow In TableOfPurchasingDocument.FindRows(New Structure("RowIsSelected", True)) Do
		SelectedDocuments.Add(TableRow.DocumentPurchases);
	EndDo;
	
	Close(PutInStorage(SelectedDocuments));
	
EndProcedure

&AtServer
Function PutInStorage(SelectedDocuments)
	
	Return PutToTempStorage(SelectedDocuments);
	
EndFunction

&AtServer
Function QueryTextTTPurchaseDocumentsAll()
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterData.Recorder AS Ref
	|INTO TTPurchaseDocuments
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS RegisterData
	|WHERE
	|	RegisterData.Organization = &Organization
	|	AND RegisterData.AdvanceHolder = &AdvanceHolder
	|	AND RegisterData.Department = &Department
	|	AND (RegisterData.Currency = &Currency
	|			OR &Multicurrency)
	|	AND RegisterData.PurchaseAmount <> 0
	|	AND RegisterData.Period <= &ExpenseReportDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.TicketNumber AS TicketNumber,
	|	DocumentData.Date AS Date,
	|	DocumentData.Carrier AS Carrier,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum
	|INTO TTETicketData
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|		INNER JOIN TTPurchaseDocuments AS PurchaseDocumentsAll
	|		ON (PurchaseDocumentsAll.Ref = DocumentData.Ref)
	|		AND DocumentData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.TicketNumber,
	|	DocumentData.Date,
	|	DocumentData.Carrier,
	|	DocumentData.CashFlowItem,
	|	DocumentData.Currency,
	|	DocumentData.DocumentAmount
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.ExpenseReport = &DocumentReference
	|	AND &LinkFilledIn
	|	AND DocumentData.Date <= &ExpenseReportDate
	|	AND DocumentData.Posted
	|	AND DocumentData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AmountsOfOperations.Ref AS Ref,
	|	SUM(AmountsOfOperations.DocumentAmount) AS DocumentAmount
	|INTO TTOfAmountOfElectronicTickets
	|FROM
	|	(SELECT
	|		ETicketsData.Ref AS Ref,
	|		CASE
	|			WHEN CompositionOfOperations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperations.Sum
	|			ELSE CompositionOfOperations.Sum
	|		END AS DocumentAmount
	|	FROM
	|		TTETicketData AS ETicketsData
	|			INNER JOIN Document.ElectronicTicketTransaction.Operations AS CompositionOfOperations
	|			ON ETicketsData.Ref = CompositionOfOperations.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ETicketsData.Ref,
	|		CASE
	|			WHEN CompositionOfOperations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -CompositionOfOperations.Sum
	|			ELSE CompositionOfOperations.Sum
	|		END
	|	FROM
	|		TTETicketData AS ETicketsData
	|			INNER JOIN Document.ElectronicTicketTransaction AS OperationData_
	|			ON ETicketsData.Ref = OperationData_.ElectronicTicket
	|			AND OperationData_.Posted
	|			INNER JOIN Document.ElectronicTicketTransaction.Operations AS CompositionOfOperations
	|			ON (OperationData_.Ref = CompositionOfOperations.Ref)) AS AmountsOfOperations
	|
	|GROUP BY
	|	AmountsOfOperations.Ref
	|
	|HAVING
	|	SUM(AmountsOfOperations.DocumentAmount) <> 0";
	
	Return QueryText;
	
EndFunction

#EndRegion


#Region Initialize

ClosingInProgress = False;


#EndRegion
