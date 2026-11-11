
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	Parameters.Property("Warehouse",Warehouse);
	Parameters.Property("SelectByProduct",SelectByProduct);
	
	If Not SelectByProduct Then
		Items.FormSelect.Title = NStr("vi = 'Thêm hàng hóa từ chứng từ giao hàng';
										|ru = 'Добавить товары из документов отгрузки';
										|en = 'Add items from shipping documents'; fa = 'افزودن اقلام از اسناد حمل';
										|it = 'Aggiungere le merci dai documenti di spedizione';
										|pl = 'Dodaj wiersze pozycji z dokumentów wysyłki';
										|tr = 'Sevkiyat belgelerinden ürünleri ekle'");
		Items.FormSelect.Representation = ButtonRepresentation.Text;
		Items.GroupCommandPanelSelect.Width = 34;
		Items.ShippingDocuments.SelectionMode = TableSelectionMode.MultiRow;
	Else
		If Not (Parameters.Property("Products",Products)
			And ValueIsFilled(Products)) Then
			TitleText = NStr("vi = 'Hãy chọn chứng từ giao hàng';
							|ru = 'Выберите документ отгрузки';
							|en = 'Select shipping document'; fa = 'انتخاب سند حمل';
							|it = 'Selezionare il documento di spedizione';
							|pl = 'Wybierz dokument wysyłki';
							|tr = 'Sevkiyat belgesi seç'");
		Else
			TitleText = NStr("vi = 'Hãy chọn chứng từ giao hàng theo %GoodsPresentation%';
							|ru = 'Выберите документ отгрузки по %GoodsPresentation%';
							|en = 'Select a shipping document by %GoodsPresentation%'; fa = 'Select a shipping document by %GoodsPresentation%';
							|it = 'Selezionare il documento di spedizione per %GoodsPresentation%';
							|pl = 'Wybierz dokument wysyłki według %GoodsPresentation%';
							|tr = '%GoodsPresentation% göre sevkiyat belgesi seç'");
			Parameters.Property("Characteristic",Characteristic);
			GoodsPresentation = ProductsClientServer.ProductPresentation(Products, Characteristic);
			TitleText = StrReplace(TitleText, "%GoodsPresentation%", GoodsPresentation);
		EndIf;
		Title = TitleText;
	EndIf;
	
	Period.Variant = StandardPeriodVariant.Last7Days;
	UpdateList();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region EventHandlersForHeaderElements

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure ShippingDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	WhenSelectingValue();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	WhenSelectingValue();
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateList()
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	VALUETYPE(RegisterData.DocumentShipments) AS DocumentType,
	|	RegisterData.DocumentShipments AS Ref,
	|	RegisterData.Recipient,
	|	RegisterData.DocumentShipments.Number AS Number,
	|	RegisterData.DocumentShipments.Date AS Date,
	|	TransportationTask.Ref AS TransportationJob
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			&StartDate,
	|			&EndDate,
	|			,
	|			(Products = &Products
	|				OR &Products = VALUE(Catalog.Products.EmptyRef))
	|				AND (Characteristic = &Characteristic
	|					OR &Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|				AND (Warehouse = &Warehouse
	|					OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))) AS RegisterData
	|		LEFT JOIN Document.TransportationJob.References AS TransportationTask
	|		ON RegisterData.DocumentShipments = TransportationTask.ReferenceOrder
	|			AND (TransportationTask.Ref.Posted)
	|
	|ORDER BY
	|	RegisterData.DocumentShipments.Date DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("StartDate", Period.StartDate);
	Query.SetParameter("EndDate", Period.EndDate);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	ShippingDocuments.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure WhenSelectingValue()
	If Not SelectByProduct Then
		ReferencesArrray = New Array;
		For Each RwID In Items.ShippingDocuments.SelectedRows Do
			ReferencesArrray.Add(Items.ShippingDocuments.RowData(RwID).Ref);
		EndDo;
		NotifyChoice(ReferencesArrray);
	ElsIf Items.ShippingDocuments.CurrentData <> Undefined Then
		NotifyChoice(Items.ShippingDocuments.CurrentData.Ref);
	EndIf;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippingDocumentsTransportationJob.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShippingDocuments.TransportationJob");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có nhiệm vụ vận chuyển>';
													|ru = '<без задания на перевозку>';
													|en = '<without itinerary>'; fa = '<without itinerary>';
													|it = '<senza un task di trasporto>';
													|pl = '<bez zadania na przewoź>';
													|tr = '<taşıma planı olmadan>'"));
	
EndProcedure

#EndRegion