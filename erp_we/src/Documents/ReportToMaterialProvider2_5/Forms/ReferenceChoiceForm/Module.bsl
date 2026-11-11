
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ArrayOfSelections = New Array;
	ArrayOfSelections.Add("Recorder");
	ArrayOfSelections.Add("BusinessOperation");
	ArrayOfSelections.Add("Organization");
	ArrayOfSelections.Add("Partner");
	ArrayOfSelections.Add("Counterparty");
	ArrayOfSelections.Add("Contract");
	ArrayOfSelections.Add("Warehouse");
	ArrayOfSelections.Add("Currency");
	ArrayOfSelections.Add("SalesOpportunity");
	ArrayOfSelections.Add("VATTaxation");
	ArrayOfSelections.Add("LineOfBusiness");
	ArrayOfSelections.Add("UseLinesOfBusiness");
	
	For Each FilterName In ArrayOfSelections Do
		
		FilterValue = Undefined;
		Parameters.Filter.Property(FilterName, FilterValue);
		
		CommonClientServer.SetDynamicListParameter(List, FilterName, FilterValue);
		
	EndDo;
	
	SetConditionalAppearanceOfLinkField();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData;
	
	Data = New Structure;
	Data.Insert("MaterialProviderOrder",   CurrentData.Ref);
	Data.Insert("Purpose",      CurrentData.Purpose);
	Data.Insert("ARAPObjectSettings", CurrentData.ARAPObjectSettings);
	
	Close(Data);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	
	Data = New Structure;
	Data.Insert("MaterialProviderOrder",   CurrentData.Ref);
	Data.Insert("Purpose",      CurrentData.Purpose);
	Data.Insert("ARAPObjectSettings", CurrentData.ARAPObjectSettings);
	
	Close(Data);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearanceOfLinkField()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Ref.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Ref");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có đơn hàng>';
													|ru = '<без заказа>';
													|en = '<without order>'; fa = '<بدون سفارش>';
													|it = '<senza ordine>';
													|pl = '<bez zamówienia>';
													|tr = '<sipariş verilmeden>.'"));
	
EndProcedure

#EndRegion