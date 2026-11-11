
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	ParametersForObtainingBalances = CommonClientServer.StructureProperty(Parameters,
		                                                                        "ParametersForObtainingBalances",
		                                                                        Undefined);
	DocumentData = CommonClientServer.StructureProperty(Parameters,
		                                                             "DocumentData",
		                                                             Undefined);
	
	AddressOfBalanceReceiptParameters = PutToTempStorage(ParametersForObtainingBalances, UUID);
	
	BalanceTable.Clear();
	Selection = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.SamplingBalances(ParametersForObtainingBalances);
	While Selection.Next() Do
		
		NewRow = BalanceTable.Add();
		FillPropertyValues(NewRow, Selection);
		
		RowFilter = New Structure("AdvanceHolder,IssuancePurpose,Currency");
		FillPropertyValues(RowFilter, NewRow);
		NewRow.ExistsInTheDocument = DocumentData.FindRows(RowFilter).Count();
		NewRow.RowIsSelected          = NewRow.ExistsInTheDocument;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBalanceTable

&AtClient
Procedure BalanceTableSumOnChange(Item)
	
	AmountOnChangeAtServer(Items.BalanceTable.CurrentRow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	Result = New Array;
	PortableProperties = "AdvanceHolder,IssuancePurpose,Currency,Sum,SumCompl,SumMan,ExistsInTheDocument";
	For Each Balance In BalanceTable Do
		If Balance.RowIsSelected Then
			NewRow = New Structure(PortableProperties);
			FillPropertyValues(NewRow, Balance);
			Result.Add(NewRow);
		EndIf;
	EndDo;
	Close(Result);
	
EndProcedure

&AtClient
Procedure SelectRows(Command)
	SelectRowsServer(True);
EndProcedure

&AtClient
Procedure ClearRows(Command)
	SelectRowsServer(False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SelectRowsServer(SelectionValue = True)
	
	For Each TableRow In BalanceTable.FindRows(New Structure("RowIsSelected", Not SelectionValue)) Do
		TableRow.RowIsSelected = SelectionValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceTable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BalanceTable.ExistsInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
EndProcedure

&AtServer
Procedure AmountOnChangeAtServer(RowID)
	
	ParametersForObtainingBalances = GetFromTempStorage(AddressOfBalanceReceiptParameters);
	LineToEdit = BalanceTable.FindByID(RowID);
	FillPropertyValues(ParametersForObtainingBalances, LineToEdit);
	Documents.AdjustmentOfARAPAccountingForAdvanceHolders.RecalculateLocalAndManAmounts(LineToEdit, ParametersForObtainingBalances);
	
EndProcedure

#EndRegion
