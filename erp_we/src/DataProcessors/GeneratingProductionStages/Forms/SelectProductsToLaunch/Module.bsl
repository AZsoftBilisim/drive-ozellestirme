
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If IsTempStorageURL(Parameters.ProductAddress) Then
		
		Object.Plan.Load(GetFromTempStorage(Parameters.ProductAddress));
		CalculateTotals();
		
		ProvidedResult = "";
		Supplied = Object.Plan.Total("Supplied");
		If Supplied > 0 Then
			ProvidedResult = Format(Supplied, "ND=15; NFD=3; NG=0;");
		EndIf;
		
	EndIf;
	
	Title = StrTemplate(
		NStr("vi = 'Sản phẩm cần khởi động: %1';
			|ru = 'Изделия к запуску: %1';
			|en = 'Finished products to launch: %1'; fa = 'Finished products to launch: %1';
			|it = 'Produzione in avvio: %1';
			|pl = 'Wyroby do uruchomienia: %1';
			|tr = 'Başlatılacak nihai ürünler: %1'"),
		ProductsClientServer.ProductPresentation(Parameters.Products, Parameters.Characteristic));
	
	If Not IsBlankString(Parameters.Route) Then
		Route = Parameters.Route;
	Else
		Items.Route.Visible = False;
	EndIf;    
	
	Items.SeparateFormByRecipientSDestination.Visible = Not Parameters.IssueIsSeparatedByDefault; // the release of semi-finished products is separated by default
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Mark", True);
	TheStructureOfTheSearch.Insert("Launch", 0);
	
	For Each String In Object.Plan.FindRows(TheStructureOfTheSearch) Do
		
		MessageText = CommonClientServer.FillingErrorText(
			"Column", "FillType", NStr("vi = 'Cần khởi động';
										|ru = 'К запуску';
										|en = 'Launch'; fa = 'راه‌اندازی';
										|it = 'In avvio';
										|pl = 'Do uruchomienia';
										|tr = 'Başlatılacak'"), String.LineNumber, NStr("vi = 'Sản phẩm';
																				|ru = 'Изделия';
																				|en = 'Products'; fa = 'کالاها';
																				|it = 'Produzione';
																				|pl = 'Wyroby';
																				|tr = 'Nihai ürünler'"));
		
		Field = CommonClientServer.PathToTabularSection(
			"Object.Plan", String.LineNumber, "Launch");
		
		Common.MessageToUser(MessageText,, Field,, Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPlan

&AtClient
Procedure PlanSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = StrReplace(Field.Name, "Plan", "");
	
	If StrFind("Recipient,Purpose", FieldName) > 0 Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData[FieldName]);
	ElsIf FieldName = "ProductionOrderPresentation" Or FieldName = "ProductionOrder" Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData.ProductionOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanLaunchOnChange(Item)
	
	Items.Plan.CurrentData.Mark = Items.Plan.CurrentData.Launch > 0;
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure PlanMarkOnChange(Item)
	
	CalculateTotals();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ClearMessages();
	
	Cancel = False;
	SelectionResult = SelectionResult(Cancel);
	
	If Not Cancel Then
		Close(SelectionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure Notice(Command)
	
	For Each RowID In Items.Plan.SelectedRows Do
		Object.Plan.FindByID(RowID).Mark = True;
	EndDo;
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure ClearMark1(Command)
	
	For Each RowID In Items.Plan.SelectedRows Do
		Object.Plan.FindByID(RowID).Mark = False;
	EndDo;
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure SeparateByDestinationOfRecipient(Command)
	
	For Each RowID In Items.Plan.SelectedRows Do
		
		String = Object.Plan.FindByID(RowID);
		
		If String.Purpose.IsEmpty() And Not String.OrderProducts_ Then
			String.Purpose = String.AssignmentRecipient;
			String.Mark = True;
		EndIf;
		
	EndDo;
	
	CalculateTotals();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanProductionOrderPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.ExceedingOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanLaunch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.Mark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlanSupplied.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.SupplyIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Query = New Query(
		"SELECT
		|	Priorities.Ref AS Priority,
		|	Priorities.Color   AS Color
		|FROM
		|	Catalog.Priorities AS Priorities");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
	 
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PlanPriority.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Plan.Priority");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Selection.Priority;
		
		Color = Selection.Color; //ValueStorage
		Item.Appearance.SetParameterValue("TextColor", Color.Get());
		
	EndDo;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Plan.AssignmentRecipient");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Plan.AssignedPurchaseSale");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
EndProcedure


&AtServer
Function SelectionResult(Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
		Return Undefined;
	EndIf;
	
	Launch = 0;
	For Each String In Object.Plan.FindRows(New Structure("Mark", True)) Do
		Launch = Launch + String.Launch;
	EndDo;
	
	Result = New Structure;
	Result.Insert("Launch", Launch);
	Result.Insert("ProductAddress", PutToTempStorage(Object.Plan.Unload()));
	
	Return Result;
	
EndFunction

&AtServer
Procedure CalculateTotals()
	
	ToLaunchResult = 0;
	For Each String In Object.Plan.FindRows(New Structure("Mark", True)) Do
		ToLaunchResult = ToLaunchResult + String.Launch;
	EndDo;
	
EndProcedure

#EndRegion
