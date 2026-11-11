
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
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(Items.ListOfOrders_.CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.ListOfOrders_) Then
		Close(Items.ListOfOrders_.CurrentData.Ref);
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
	
	InvoiceManager = Documents.GoodsShipmentToCustomer;
	
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Parameters);
	
	References = InvoiceManager.WaybillOrders(Parameters.Ref, HeaderAttributes);
	CommonClientServer.DeleteValueFromArray(References, Parameters.Ref);
	
	FillParameters = InvoiceManager.DocumentFillingParameters();
	InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, References);
	
	InvoiceTable = InvoiceManager.TableDataAndDocument(Undefined);
	InvoiceTable.Columns.Delete("Ref");
	
	OrderListColumns = New Array();
	TableOfOrders = ListOfOrders_.Unload();
	For Each TableColumn2 In TableOfOrders.Columns Do
	
		If InvoiceTable.Columns.Find(TableColumn2.Name) = Undefined Then
			InvoiceTable.Columns.Add(TableColumn2.Name, TableColumn2.ValueType);
		EndIf;
	
		OrderListColumns.Add(TableColumn2.Name);
		
	EndDo;
	
	InvoiceManager.FillInByOrdersOrders(InvoiceTable, Parameters.Ref, FillParameters);
	
	InvoiceTable.GroupBy(StrConcat(OrderListColumns, ","));
	
	ListOfOrders_.Load(InvoiceTable);
	
EndProcedure

#EndRegion

