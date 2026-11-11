#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ScanningResult = Parameters.ScanningResult; // Structure 
	Warehouse = Parameters.Warehouse;
	Premise = Parameters.Premise;
	Mode = ScanningResult.Mode;
	Barcode = ScanningResult.Barcode;
	
	FillForm(ScanningResult);	
	SetConditionalAppearance(ScanningResult);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If UsedFormServer = UsedServer.Main Then

		If Source = "Peripherals" And IsInputAvailable() Then 
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
			
				If Items.GroupTableShipmentOrders.Visible Then 
					OrderSelectionShipment(OrdersShipment[0]);
				ElsIf Items.GroupTableOfAcceptanceOrders.Visible Then
					OrderSelectionAcceptance(OrdersAcceptance[0]);
				ElsIf Items.GroupTableOrders.Visible Then 
					Order_Selection(Orders_3[0]);
				ElsIf Items.TaskTableGroup.Visible Then
					SelectJob(Jobs[0]);
				ElsIf Items.GroupTableItem.Visible Then 
					SelectItems(Products[0]);
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersOrdersShipment

&AtClient
Procedure OrdersShipmentSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.OrdersShipment.CurrentData; 
	OrderSelectionShipment(CurrentRow);
	
EndProcedure

&AtClient
Procedure OrdersShipmentOnActivateRow(Item)
	
	OrdersShipment[0].Selection = False;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrdersAcceptance

&AtClient
Procedure OrdersAcceptanceSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.OrdersAcceptance.CurrentData; 
	OrderSelectionAcceptance(CurrentRow);
	
EndProcedure

&AtClient
Procedure OrdersAcceptanceOnActivateRow(Item)

	OrdersAcceptance[0].Selection = False;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrders_3

&AtClient
Procedure Orders_3Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False; 
	
	CurrentRow = Items.Orders_3.CurrentData;
	Order_Selection(CurrentRow);
	
EndProcedure

&AtClient
Procedure Orders_3OnActivateRow(Item)
	
	Orders_3[0].Selection = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersJobs

&AtClient
Procedure JobsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Jobs.CurrentData;  
	SelectJob(CurrentRow);
	
EndProcedure

&AtClient
Procedure JobsOnActivateRow(Item)

	Jobs[0].Selection = False;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProducts

&AtClient
Procedure ProductsSelection(Item, RowSelected, Field, StandardProcessing) 
	
	StandardProcessing = False;
	
	CurrentRow = Items.Products.CurrentData;  
	SelectItems(CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsOnActivateRow(Item)

	Products[0].Selection = False;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreatePlacement(Command)
	
	SearchResult = DocumentSearchResultBySchool();	
	Close(SearchResult);
	
EndProcedure

#EndRegion  

#Region Private

&AtClient
Procedure OrderSelectionShipment(CurrentRow)
			
	SearchResult = DocumentSearchResultBySchool();
	SearchResult.ThisIsOrder_ = True; 
	SearchResult.Direction = "Shipment";
	SearchResult.Barcode = Barcode;
	
	OrderData_2 = New Structure("ReferenceOrder, Recipient, Number");
	OrderData_2.Insert("DocumentType");
	FillPropertyValues(OrderData_2, CurrentRow); 
	SearchResult.References = MobileWarehouseKeeperWorkspaceClientServer.ValueInArray(OrderData_2);
	
	OrdersByReferences = New Array;
	If Mode = "DocumentSearch" Then

		OrdersByReferences = OrdersByReferences(CurrentRow.ReferenceOrder, True, False);
		
		If OrdersByReferences.References.Count() Then
			Close(OrdersByReferences);
		Else
			Close(SearchResult);
		EndIf;
		
	ElsIf Mode = "DocumentSelection" Then
		
		Close(SearchResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderSelectionAcceptance(CurrentRow)
		
	SearchResult = DocumentSearchResultBySchool();
	SearchResult.ThisIsOrder_ = True; 
	SearchResult.Direction = "Receiving";
	SearchResult.Barcode = Barcode;
	
	SearchResult.References = MobileWarehouseKeeperWorkspaceClientServer.ValueInArray(CurrentRow);
	
	OrdersByReferences = New Array;
	If Mode = "DocumentSearch" Then

		OrdersByReferences = OrdersByReferences(CurrentRow.ReferenceOrder, False, True);
		
		If OrdersByReferences.References.Count() Then
			Close(OrdersByReferences);
		Else
			Close(SearchResult);
		EndIf;
		
	ElsIf Mode = "DocumentSelection" Then
			
		Close(SearchResult);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure Order_Selection(CurrentRow)
		
	SearchResult = DocumentSearchResultBySchool();
	
	SearchResult.ThisIsOrder_ = False;
	SearchResult.References = MobileWarehouseKeeperWorkspaceClientServer.ValueInArray(CurrentRow.Ref);
	SearchResult.Barcode = Barcode;
	
	Close(SearchResult);
	
EndProcedure

&AtClient
Procedure SelectJob(CurrentRow)
		
	SearchResult = DocumentSearchResultBySchool();
	
	SearchResult.ThisIsOrder_ = False;	
	SearchResult.References = MobileWarehouseKeeperWorkspaceClientServer.ValueInArray(CurrentRow.Ref);
	
	Close(SearchResult);
	
EndProcedure 

&AtClient
Procedure SelectItems(CurrentRow)
	
	ProductData_8 = MobileWarehouseKeeperWorkspaceClientServer.ValueInArray(CurrentRow);

	Close(ProductData_8);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance(ScanningResult)
	
	If Mode = "DocumentSearch" Or ScanningResult.Mode = "DocumentSelection" Then
 
		If ScanningResult.ThisIsOrder_ Then 
			
			Title = NStr("vi = 'Chọn lệnh';
						|ru = 'Выберите распоряжение';
						|en = 'Select reference'; fa = 'انتخاب مرجع';
						|it = 'Seleziona una disposizione';
						|pl = 'Wybierz zamówienie';
						|tr = 'Emir seç'");

			If ScanningResult.Direction = "Shipment" Then
				
				Items.GroupTableShipmentOrders.Visible = True; 
				Items.RecipientGroup.Visible = True; 
				
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				ItemField = ConditionalAppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(Items.OrdersShipment.Name);
				ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("OrdersShipment.Selection");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = True;
				ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ActivityColor); 
				
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				ItemField = ConditionalAppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(Items.OrdersShipmentState.Name);
				ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("OrdersShipment.ShipmentStatus");
				ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
				ItemFilter.RightValue = 2;
				ConditionalAppearanceItem.Appearance.SetParameterValue("Font", StyleFonts.StandardTextFontMWKW);
				ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorAdditionalAssemblyAndDelivery);
			Else
				// Orders - acceptance
				Items.GroupTableOfAcceptanceOrders.Visible = True;
				Items.SenderGroup.Visible = True;
				
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				ItemField = ConditionalAppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(Items.OrdersAcceptance.Name);
				ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("OrdersAcceptance.Selection");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = True;
				ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ActivityColor);
				
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				ItemField = ConditionalAppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(Items.OrdersAcceptance.Name);
				ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("OrdersAcceptance.State");
				ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
				ItemFilter.RightValue = 3;
				ConditionalAppearanceItem.Appearance.SetParameterValue("Font", StyleFonts.StandardTextFontMWKW);
				ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorAdditionalAssemblyAndDelivery);
				
			EndIf;
			
		ElsIf Mode = "DocumentSearch" Then
			
			Items.GroupReference_.Visible = True;
			Items.GroupTableOrders.Visible = True; 
			
			WarehouseProperties = DataProcessors.MobileWarehouseKeeperWorkspace.WarehouseProperties(Warehouse);
			Items.GroupPlacingOrder.Visible = WarehouseProperties.UseWarerooms;
			
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.Orders_3.Name);
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Orders_3.Selection");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ActivityColor); 
				
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.Orders_3Status.Name);
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Orders_3.StatusOfShipmentAcceptance");
			ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
			ItemFilter.RightValue = 2;
			ConditionalAppearanceItem.Appearance.SetParameterValue("Font", StyleFonts.StandardTextFontMWKW);
			ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorAdditionalAssemblyAndDelivery);
			
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.Orders_3Performer.Name);
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Orders_3.Orders_3Performer");
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa ấn định>';
																				|ru = '<не назначен>';
																				|en = '<not assigned>'; fa = '<تخصیص‌نیافته>';
																				|it = '<not assigned>';
																				|pl = '<not assigned>';
																				|tr = '<atanmadı>'"));

			If ScanningResult.Direction = "Bidirectional" Then
				
				Title = NStr("vi = 'Hãy chọn phiếu';
							|ru = 'Выберите ордер';
							|en = 'Select the note'; fa = 'Select the note';
							|it = 'Select the note';
							|pl = 'Select the note';
							|tr = 'Sipariş seç'");
				Items.SenderRecipientGroup.Visible = True;
				Items.Orders_3DocumentType.Visible = True;

			ElsIf ScanningResult.Direction = "Shipment" Then
				
				Title = NStr("vi = 'Hãy chọn phiếu xuất kho';
							|ru = 'Выберите расходный ордер';
							|en = 'Select goods issue note'; fa = 'Select goods issue note';
							|it = 'Select goods issue note';
							|pl = 'Select goods issue note';
							|tr = 'Ambar çıkış fişini seç'");
				Items.RecipientGroup.Visible = True; 
				
			ElsIf ScanningResult.Direction = "Receiving" Then
				
				Title = NStr("vi = 'Hãy chọn phiếu nhập kho';
							|ru = 'Выберите приходный ордер';
							|en = 'Select goods receipt note'; fa = 'Select goods receipt note';
							|it = 'Select goods receipt note';
							|pl = 'Select goods receipt note';
							|tr = 'Giriş fişini seç'"); 
				Items.SenderGroup.Visible = True; 
				
			EndIf;
			
		ElsIf ScanningResult.Mode = "DocumentSelection" Then
			
			Items.GroupRoom.Visible = True; 
			Items.TaskTableGroup.Visible = True; 
			
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.Jobs.Name);
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Jobs.Selection");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ActivityColor); 
				
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.JobsStatus.Name);
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Jobs.JobStatus");
			ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
			ItemFilter.RightValue = 2;
			ConditionalAppearanceItem.Appearance.SetParameterValue("Font", StyleFonts.StandardTextFontMWKW);
			ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorAdditionalAssemblyAndDelivery);
			
			ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
			ItemField = ConditionalAppearanceItem.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.JobsPerformer.Name);
			ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Jobs.JobsPerformer");
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa ấn định>';
																				|ru = '<не назначен>';
																				|en = '<not assigned>'; fa = '<تخصیص‌نیافته>';
																				|it = '<not assigned>';
																				|pl = '<not assigned>';
																				|tr = '<atanmadı>'"));

			If ScanningResult.Direction = "Shipment" Then 
				Title = NStr("vi = 'Hãy chọn nhiệm vụ lấy ra';
							|ru = 'Выберите задание на отбор';
							|en = 'Select picking job'; fa = 'Select picking job';
							|it = 'Select picking job';
							|pl = 'Select picking job';
							|tr = 'Filtre görevleri seç'");
				Items.GroupShippingArea.Visible = True; 
			Else
				Title = NStr("vi = 'Hãy chọn nhiệm vụ sắp xếp';
							|ru = 'Выберите задание на размещение';
							|en = 'Select put-away task'; fa = 'Select put-away task';
							|it = 'Select put-away task';
							|pl = 'Select put-away task';
							|tr = 'Yerleştirme görevi seç'");
				Items.GroupInboundArea.Visible = True; 
				Items.IndentDecoration.Visible = False;
				Items.DecorationChoiceOfPlacement.Visible = True; 
				If UsedFormServer = UsedServer.Main Then
					Items.CreatePlacement.Visible = True;
				EndIf;
			EndIf;

		EndIf; 
		
	ElsIf Mode = "SelectItems" Then
		
		Items.GroupTableItem.Visible = True;
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.Products.Name);
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Products.Selection");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ActivityColor); 
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ProductsCharacteristic.Name);
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Products.Characteristic");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<đặc tính không được chỉ định>';
																			|ru = '<характеристика не указана>';
																			|en = '<variant is not specified>'; fa = '<variant is not specified>';
																			|it = '<variant is not specified>';
																			|pl = '<variant is not specified>';
																			|tr = '<varyant belirtilmedi>'"));
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ProductsSeries.Name);
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Products.Series");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định số sê-ri>';
																			|ru = '<серия не указана>';
																			|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
																			|it = '<batch is not specified>';
																			|pl = '<batch is not specified>';
																			|tr = '<parti belirtilmemiş>'"));		
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ProductsPackage.Name);
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Products.Package");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định bao bì>';
																			|ru = '<упаковка не указана>';
																			|en = '<packaging unit is not specified>'; fa = '<packaging unit is not specified>';
																			|it = '<packaging unit is not specified>';
																			|pl = '<packaging unit is not specified>';
																			|tr = '<paketleme ünitesi belirtilmemiş>'"));

		Title = NStr("vi = 'Hãy chọn mặt hàng';
					|ru = 'Выберите номенклатуру';
					|en = 'Select the item'; fa = 'Select the item';
					|it = 'Select the item';
					|pl = 'Select the item';
					|tr = 'Öğe seç'");
		Items.HeaderGroup.Visible = False; 
			
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillForm(ScanningResult)
	
	If Mode = "DocumentSearch" Or ScanningResult.Mode = "DocumentSelection" Then
		
		If ScanningResult.ThisIsOrder_ Then
					
			If ScanningResult.Direction = "Shipment" Then
				
				For Each ReferenceOrder In ScanningResult.References Do
					NewRow = OrdersShipment.Add();
					FillPropertyValues(NewRow, ReferenceOrder);
					NewRow.Picture_Barcode = 1;
				EndDo; 
				
				OrdersShipment.Sort("ShipmentStatus");
				
				Items.Recipient.Title = OrdersShipment[0].Recipient;
				OrdersShipment[0].Selection = True;
				OrdersShipment[0].Picture_Barcode = 0;

			Else
				For Each ReferenceOrder In ScanningResult.References Do
					NewRow = OrdersAcceptance.Add();
					FillPropertyValues(NewRow, ReferenceOrder);
					NewRow.Picture_Barcode = 1;
				EndDo;
				
				OrdersAcceptance.Sort("State");
				
				Items.Sender.Title = OrdersAcceptance[0].Sender; 
				OrdersAcceptance[0].Selection = True;
				OrdersAcceptance[0].Picture_Barcode = 0;

			EndIf;
			
		ElsIf Mode = "DocumentSearch" Then		
			
			Query = New Query; 
			
			If ScanningResult.Direction = "Bidirectional" Then 
				
				LinksSpendingOrders = New Array;
				ReferencesIncomingOrders = New Array;
				
				For Each WarehouseDocument In ScanningResult.References Do
					If TypeOf(WarehouseDocument) = Type("DocumentRef.GoodsIssueNote") Then 
						LinksSpendingOrders.Add(WarehouseDocument);
					Else
						ReferencesIncomingOrders.Add(WarehouseDocument);
					EndIf;
				EndDo;
				
				Query.Text = QueryTextGoodsIssueNotes();
				Query.SetParameter("References", LinksSpendingOrders);

				ResultSpendingOrders = Query.Execute().Unload();
				ResultSpendingOrders.Sort("StatusOfShipmentAcceptance");
						
				Query.Text = QueryTextGoodsReceiptNotes();
				Query.SetParameter("References", ReferencesIncomingOrders);

				ResultIncomingOrders = Query.Execute().Unload();
				ResultIncomingOrders.Sort("StatusOfShipmentAcceptance"); 
				
				MobileWarehouseKeeperWorkspaceClientServer.SupplementTable(ResultIncomingOrders, ResultSpendingOrders);
				Orders_3.Load(ResultSpendingOrders);
				
			Else
				Query.SetParameter("References", ScanningResult.References);
				
				If ScanningResult.Direction = "Shipment" Then
					Query.Text = QueryTextGoodsIssueNotes();
				Else
					Query.Text = QueryTextGoodsReceiptNotes();
				EndIf;
				
				QueryResult = Query.Execute().Unload();
				
				QueryResult.Sort("StatusOfShipmentAcceptance");
				Orders_3.Load(QueryResult);

			EndIf; 
			
			ReferenceOrder = ScanningResult.ReferenceOrder;
			DisposalInformation = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(ReferenceOrder, "Number, Date");	
			ReferenceDate = Format(DisposalInformation.Date, NStr("vi = 'DLF=D';
																	|ru = 'ДЛФ=D';
																	|en = 'DLF=D'; fa = 'DLF=D';
																	|it = 'DLF=D';
																	|pl = 'DLF=D';
																	|tr = 'DLF=G'"));
			
			LineAboutOrder = StrTemplate(NStr("vi = '%1, %2, %3';
												|ru = '%1, %2, %3';
												|en = '%1, %2, %3'; fa = '%1, %2, %3';
												|it = '%1, %2, %3';
												|pl = '%1, %2, %3';
												|tr = '%1, %2, %3'"), TypeOf(ReferenceOrder), DisposalInformation.Number,
				ReferenceDate);
			Items.ReferenceOrder.Title = LineAboutOrder;	
			
			Warehouse = Orders_3[0].Warehouse;
			Items.Recipient.Title = Orders_3[0].SenderRecipient;
			Items.Sender.Title = Orders_3[0].SenderRecipient;
			Items.SenderRecipient.Title = Orders_3[0].SenderRecipient;
			
			Orders_3[0].Selection = True;
			Orders_3[0].Picture_Barcode = 0;
			
		ElsIf Mode = "DocumentSelection" Then
			
			For Each Job In ScanningResult.References Do
				NewRow = Jobs.Add();
				FillPropertyValues(NewRow, Job);
				NewRow.Picture_Barcode = 1;
			EndDo; 
				
			Jobs.Sort("JobStatus");
			
			Jobs[0].Selection = True;
			Jobs[0].Picture_Barcode = 0;

		EndIf;
		
		Items.Warehouse.Title = Warehouse;
		
	ElsIf Mode = "SelectItems" Then
		
		For Each OwnGoods In ScanningResult.Goods Do
			NewRow = Products.Add();
			FillPropertyValues(NewRow, OwnGoods);
			NewRow.Picture_Barcode = 1;
		EndDo; 
		
		Products[0].Selection = True;
		Products[0].Picture_Barcode = 0; 
		
	EndIf;
	
EndProcedure

&AtServer
Function QueryTextGoodsIssueNotes()
	
	QueryText =
		"SELECT
		|	GoodsIssueNote.Ref AS Ref,
		|	VALUETYPE(GoodsIssueNote.Ref) AS DocumentType,
		|	GoodsIssueNote.Premise AS Premise,
		|	STRING(""Premise"") AS RoomTitle,
		|	GoodsIssueNote.Recipient AS SenderRecipient,
		|	GoodsIssueNote.Number AS Number,
		|	GoodsIssueNote.Date AS Date,
		|	GoodsIssueNote.Status AS Status,
		|	GoodsIssueNote.Warehouse AS Warehouse,
		|	1 AS Picture_Barcode,
		|	CASE
		|		WHEN GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared)
		|			THEN 0
		|		WHEN GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForPicking)
		|			THEN 1
		|		ELSE 2
		|	END AS StatusOfShipmentAcceptance,
		|	CASE
		|		WHEN GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared)
		|			OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForPicking)
		|			OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)
		|			THEN GoodsIssueNote.EmployeeResponsible
		|		WHEN GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.DuringChecking)
		|			OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Verified)
		|			THEN GoodsIssueNote.Inspector
		|		ELSE GoodsIssueNote.ShippedBy
		|	END AS Performer,
		|	CASE
		|		WHEN GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared)
		|			OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForPicking)
		|			OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForChecking)
		|			THEN STRING(""Performer"")
		|		WHEN GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.DuringChecking)
		|			OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Verified)
		|			THEN STRING(""Inspector"")
		|		ELSE STRING(""ShippedBy"")
		|	END AS PerformerTitle
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Ref IN (&References)"; 
	
	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextGoodsReceiptNotes()
	
	QueryText =
		"SELECT
		|	GoodsReceiptNote.Ref AS Ref,
		|	VALUETYPE(GoodsReceiptNote.Ref) AS DocumentType,
		|	GoodsReceiptNote.Premise AS Premise,
		|	STRING(""Premise"") AS RoomTitle,
		|	GoodsReceiptNote.Sender AS SenderRecipient,
		|	GoodsReceiptNote.Number AS Number,
		|	GoodsReceiptNote.Date AS Date,
		|	GoodsReceiptNote.Status AS Status,
		|	GoodsReceiptNote.Warehouse AS Warehouse,
		|	1 AS Picture_Barcode,
		|	CASE
		|		WHEN GoodsReceiptNote.Status = VALUE(Enum.GoodsReceiptNoteStatuses.ToReceive)
		|			THEN 0
		|		WHEN GoodsReceiptNote.Status = VALUE(Enum.GoodsReceiptNoteStatuses.InProgress)
		|			THEN 1
		|		ELSE 2
		|	END AS StatusOfShipmentAcceptance,
		|	GoodsReceiptNote.Performer AS Performer,
		|	STRING(""Performer"") AS PerformerTitle
		|FROM
		|	Document.GoodsReceiptNote AS GoodsReceiptNote
		|WHERE
		|	GoodsReceiptNote.Ref IN (&References)";
	
	Return QueryText;

EndFunction

&AtServer
Function OrdersByReferences(Val ReferenceOrder, Val ThisIsShipment, Val ThisIsAcceptance)
	
    OrdersByReferences =  DataProcessors.MobileWarehouseKeeperWorkspace.OrdersByReferences(ReferenceOrder, Warehouse, ThisIsShipment, ThisIsAcceptance);
	
	SearchResult = DocumentSearchResultBySchool();
	SearchResult.ThisIsOrder_ = False;
	SearchResult.References = OrdersByReferences.LinksToOrders; 
	SearchResult.ReferenceOrder = ReferenceOrder;
	SearchResult.Direction = OrdersByReferences.DirectionOfOrders; 
	SearchResult.Mode = Mode;
	SearchResult.Barcode = Barcode;
	
	Return SearchResult;
	
EndFunction

&AtServer
Function DocumentSearchResultBySchool()
		
	SearchResult = DataProcessors.MobileWarehouseKeeperWorkspace.DocumentSearchResultBySchool();
	
	Return SearchResult;
	
EndFunction
	
#EndRegion 
