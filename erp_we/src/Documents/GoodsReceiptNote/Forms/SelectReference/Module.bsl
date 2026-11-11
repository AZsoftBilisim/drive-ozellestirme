
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Sender           = Parameters.Sender;
	BusinessOperation = Parameters.BusinessOperation;
	Warehouse                 = Parameters.Warehouse;
	
	If Not ValueIsFilled(Warehouse) Then
		MessageText = NStr("vi = 'Trước khi chọn một lệnh, bạn cần chỉ định kho.';
							|ru = 'Перед выбором распоряжения нужно указать склад.';
							|en = 'Specify a warehouse before selecting a reference.'; fa = 'Specify a warehouse before selecting a reference.';
							|it = 'Prima di selezionare una disposizione è necessario specificare il magazzino.';
							|pl = 'Przed wyborem zamówienia należy podać magazyn.';
							|tr = 'Emir seçmeden önce ambar belirtilmesi gerekir.'");
		Raise MessageText;
	EndIf;
	
	SetListParameters();
	
	BusinessOperationsOfRegistry = TMCommonUse.BusinessTransactionsReflectedInRegister(
											Metadata.DefinedTypes.ReceiptReferenceOrder.Type.Types());
	
	MatchingOperations = WarehousesClientServer.ComplianceOfEconomicOperationsWithWarehouseAcceptanceOperations();
	SelectionOfBusinessOperations = New Array;
	
	For Each ArrRow In BusinessOperationsOfRegistry Do
		
		If MatchingOperations.Get(ArrRow) <> Undefined Then 
			SelectionOfBusinessOperations.Add(ArrRow);
		EndIf;
		
	EndDo;
											
	ChoiceParameter = New ChoiceParameter("Filter.Ref", New FixedArray(SelectionOfBusinessOperations));
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(ChoiceParameter);
	
	Items.BusinessOperation.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

#EndRegion

#Region EventHandlersForHeaderElements

&AtClient
Procedure SenderOnChange(Item)
	SetListParameters();
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	SetListParameters();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessSelection(Item.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		ProcessSelection(Items.List.CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Number");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListSourceDocumentNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.SourceDocumentNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListSourceDocumentDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.SourceDocumentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
EndProcedure

&AtClient
Procedure ProcessSelection(CurrentRow)
	
	ValueSelected = New Structure;
	ValueSelected.Insert("ReferenceOrder", 		     CurrentRow.DocumentInflow);
	ValueSelected.Insert("Sender", 		    CurrentRow.Sender);
	ValueSelected.Insert("BusinessOperation", CurrentRow.BusinessOperation);
	
	Close(ValueSelected);
	
EndProcedure

&AtServer
Procedure SetListParameters()
	
	CommonClientServer.SetDynamicListParameter(List,
																		"Warehouse",
																		Warehouse);
	CommonClientServer.SetDynamicListParameter(List,
																		"Sender",
																		Sender);
	CommonClientServer.SetDynamicListParameter(List,
																		"BusinessOperation",
																		BusinessOperation);
	CommonClientServer.SetDynamicListParameter(List,
																		"ForAllSenders",
																		Not ValueIsFilled(Sender));
	CommonClientServer.SetDynamicListParameter(List,
																		"ForAllBusinessTransactions",
																		Not ValueIsFilled(BusinessOperation));
	
EndProcedure

#EndRegion