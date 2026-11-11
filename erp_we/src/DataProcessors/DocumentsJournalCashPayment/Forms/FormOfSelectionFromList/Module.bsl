
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // refund upon receipt of the form for analysis
		Return;
	EndIf;
	
	ModeOfSelectionOfCashRegistersOfBankAccounts = Parameters.Mode = 1;
	Items.ShowClosedAccounts.Visible = ModeOfSelectionOfCashRegistersOfBankAccounts;
	List = Parameters.List;
	FullList = Parameters.List.Copy();
	
	Items.List.HeightInTableRows = List.Count();
	
	Parameters.Property("Title", ThisForm.Title);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ModeOfSelectionOfCashRegistersOfBankAccounts Then
		ShowHideClosedBankAccounts();
	Else
		List = FullList;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowClosedAccountsOnChange(Item)
	
	ShowHideClosedBankAccounts();
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	List[RowSelected].Check = Not List[RowSelected].Check;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure CheckOnChange(Item)
	
	ListLine = Items.List.CurrentData;
	ValueFound = FullList.FindByValue(ListLine.Value);
	ValueFound.Check = ListLine.Check;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	NotifyChoice(FullList);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ShowHideClosedBankAccounts()
	
	If Not ShowClosedAccounts Then
		
		NewList = New ValueList;
		TableOfAccounts = New ValueTable;
		ColumnTypes = New Array;
		
		ColumnTypes.Add(Type("CatalogRef.CashAccounts"));
		ColumnTypes.Add(Type("CatalogRef.CompaniesBankAccounts"));
		
		TableOfAccounts.Columns.Add("InvoiceCashier", New TypeDescription(ColumnTypes));
		TableOfAccounts.Columns.Add("Check", New TypeDescription("Boolean"));
		
		For Each CurCurrentListItem In FullList Do
			
			NewRow = TableOfAccounts.Add();
			NewRow.InvoiceCashier = CurCurrentListItem.Value;
			NewRow.Check = CurCurrentListItem.Check;
			
		EndDo;
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	AccountList.InvoiceCashier AS InvoiceCashier,
			|	AccountList.Check AS Check
			|INTO FullList
			|FROM
			|	&ListOfCashierAccounts AS AccountList
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	FullList.InvoiceCashier AS InvoiceCashier,
			|	FullList.Check AS Check,
			|	ISNULL(CompaniesBankAccounts.Closed, FALSE) AS Closed
			|FROM
			|	FullList AS FullList
			|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
			|		ON FullList.InvoiceCashier = CompaniesBankAccounts.Ref";
		
		Query.SetParameter("ListOfCashierAccounts", TableOfAccounts);
		QueryResult = Query.Execute().Select();
		
		While QueryResult.Next() Do
			
			If Not QueryResult.Closed Then
				NewList.Add(QueryResult.InvoiceCashier, , QueryResult.Check);
			Else
				If QueryResult.Check Then
					CurrentValue = FullList.FindByValue(QueryResult.InvoiceCashier);
					CurrentValue.Check = False;
				EndIf;
			EndIf;
			
		EndDo;
		
		List = NewList;
		
	Else
		List = FullList;
	EndIf;

EndProcedure

#EndRegion