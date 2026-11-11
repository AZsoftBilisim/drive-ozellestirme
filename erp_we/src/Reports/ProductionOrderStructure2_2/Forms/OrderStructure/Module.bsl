#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UploadFormSettings();
	
	If Parameters.Property("Orders") Then
		If Parameters.Orders.UBound() = 0 Then
			Orders.LoadValues(Parameters.Orders);
		Else
			Query = New Query(
				"SELECT
				|	Orders.Ref AS Ref
				|FROM
				|	Document.ProductionOrder2_2 AS Orders
				|WHERE
				|	Orders.Ref IN(&Orders)
				|
				|ORDER BY
				|	Orders.Priority.AddlOrderingAttribute,
				|	Orders.Department.AddlOrderingAttribute,
				|	Orders.Queue");
			Query.SetParameter("Orders", Parameters.Orders);
			Orders.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		EndIf;
	ElsIf Parameters.Property("OrderDocument") Then
		Orders.Add(Parameters.OrderDocument);
	ElsIf Parameters.Property("Stage") Then
		Orders.Add(Common.ObjectAttributeValue(Parameters.Stage, "ReferenceOrder"));
		FilterStage = Parameters.Stage;
		StagesShow = True;
	Else
		Cancel = True;
		Raise NStr("vi = 'Báo cáo không dành cho mở tương tác.';
					|ru = 'Отчет не предназначен для интерактивного открытия.';
					|en = 'The report is not designed for interactive opening.'; fa = 'The report is not designed for interactive opening.';
					|it = 'Il report non è destinato all''apertura interattiva.';
					|pl = 'Raport nie jest przeznaczony do otwarcia interaktywnego.';
					|tr = 'Rapor, etkileşimli açılmaya yönelik değildir.'");
	EndIf;
	
	SetFormHeader();
	URL = "";
	
	GraphIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	Items.GanttChart.Visible = GraphIsUsed;
	Items.StageResourceChart.Visible = GraphIsUsed;
	Items.ContextMenuGanttChart.Visible = GraphIsUsed;
	Items.ContextMenuStageDiagnostics.Visible = GraphIsUsed;
	
	ConfigureDependentFormElements(ThisForm);
	
	UpdateDataOnServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartAwaitingLongAction Then
		
		AttachIdleHandler("StartAwaitingLongAction", 0.1, True);
		
	ElsIf Orders.Count() <> 0 Then
		
		ExpandLines();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure;
	Filter.Insert("Posted", True);
	
	If Orders.Count() = 1 Then
		Filter.Insert("ReferenceOrder", Orders[0].Value);
	ElsIf Items.OrderStructure_2.CurrentData <> Undefined
		And Not Items.OrderStructure_2.CurrentData.OrderDocument.IsEmpty() Then
		Filter.Insert("ReferenceOrder", Items.OrderStructure_2.CurrentData.OrderDocument);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentRow", FilterStage);
	FormParameters.Insert("Filter", Filter);
	
	OpenForm(
		"Document.ProductionStage2_2.ChoiceForm",
		FormParameters,
		Item);
	
EndProcedure

&AtClient
Procedure HideCompletedOnChange(Item)
	
	WhenChangingDisplaySettingsOnClient();
	
EndProcedure

&AtClient
Procedure StagesShowOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "StagesShow");
	WhenChangingDisplaySettingsOnClient();
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	WhenSelectionChangesOnClient();
	
EndProcedure

&AtClient
Procedure FilterStageOnChange(Item)
	
	WhenSelectionChangesOnClient();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStageTree

&AtClient
Procedure OrderStructure_2Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TreeRow = Item.RowData(RowSelected);
	
	If TreeRow.RowType = StringTypeStage() Then
		
		ShowValue(, TreeRow.Stage);
		
	ElsIf TreeRow.RowType = LineTypeSemiFinished() Then
		
		ShowValue(, TreeRow.Products);
		
	ElsIf TreeRow.RowType = LineTypeProducts() Then
		
		OpenProductionOrderLine(TreeRow);
		
	ElsIf TreeRow.RowType = OrderLineType()
		Or TreeRow.RowType = LineTypeOtherProducts() Then
		
		ShowValue(, TreeRow.OrderDocument);
		
	ElsIf TreeRow.RowType = LineTypeSemiFinishedProductOfAnotherOrder() Then
		
		OpenSemiFinishedProductStructureFormOfAnotherOrder(TreeRow);
		
	ElsIf TreeRow.RowType = StringTypeCreateStages() Then
		
		OpenStageCreationForm(TreeRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderStructure_2BeforeExpand(Item, String, Cancel)
	
	TreeRow = Item.RowData(String);
	
	If Not TreeRow.DescendantsAreDisplayed Then
		FinishStageTree(TreeRow);
	EndIf;
	
	Source = Tree.FindByID(TreeRow.Source);
	Source.IsExpanded = True;
	
	If Not StagesShow
		And (Source.RowType = LineTypeSemiFinished()
			Or Source.RowType = LineTypeProducts()) Then
		For Each SourceStage In Source.GetItems() Do
			SourceStage.IsExpanded = True;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderStructure_2BeforeCollapse(Item, String, Cancel)
	
	TreeRow = Item.RowData(String);
	
	If TreeRow <> Undefined Then
		
		Source = Tree.FindByID(TreeRow.Source);
		Source.IsExpanded = False;
		
		If Not StagesShow 
			And (Source.RowType = LineTypeSemiFinished()
				Or Source.RowType = LineTypeProducts()) Then
			For Each SourceStage In Source.GetItems() Do
				SourceStage.IsExpanded = False;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateDataOnClient();
	
EndProcedure

&AtClient
Procedure GanttChart(Command)
	
	ClearMessages();
	
	CurrentData = Items.OrderStructure_2.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Dòng cấu trúc đơn hàng không được chọn';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"OrderStructure_2");
		Return;
	EndIf;
	
	If CurrentData.RowType = OrderLineType() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CommandParameter", CurrentData.OrderDocument);
		
		OpenForm(
			"Report.MonitorOrder.ObjectForm",
			FormParameters,
			ThisObject,
			CurrentData.OrderDocument);
		
	ElsIf CurrentData.RowType = LineTypeSemiFinished()
		Or CurrentData.RowType = LineTypeProducts() Then
		
		If Not CurrentData.ProductionLot.IsEmpty() Then
			
			FormParameters = New Structure;
			FormParameters.Insert("ProductionOrder", CurrentData.OrderDocument);
			FormParameters.Insert("ProductionLot", CurrentData.ProductionLot);
			
			OpenForm(
				"Report.StartingLotProductionChart.ObjectForm",
				FormParameters,
				ThisObject,
				CurrentData.ProductionLot);
			
		Else
			
			ProductionLots = ProductProductionBatches(CurrentData.Source);
			If ProductionLots.Count() = 0 Then
				MessageText = NStr("vi = 'Tạo báo cáo cho hàng đã chọn không khả dụng';
									|ru = 'Формирование отчета для выбранной строки недоступно';
									|en = 'Cannot generate the report for the selected line'; fa = 'Cannot generate the report for the selected line';
									|it = 'La generazione di report per la riga selezionata non è disponibile';
									|pl = 'Kształtowanie raportu dla wybranego wiersza nie jest dostępne';
									|tr = 'Seçili satır için raporun düzenlenmesi mevcut değildir'");
			Else
				MessageText = NStr("vi = 'Sản xuất được lên kế hoạch theo nhiều lô hàng, để tạo báo cáo, bạn phải chọn công đoạn sản xuất';
									|ru = 'Производство запланировано несколькими партиями, для формирования отчета необходимо выбрать этап производства';
									|en = 'Production is planned in several lots. To generate a report, you must select the production stage'; fa = 'Production is planned in several lots. To generate a report, you must select the production stage';
									|it = 'La produzione è programmata in più lotti, per generare il report è necessario selezionare una fase di produzione';
									|pl = 'Produkcję zaplanowano w kilku partiach, dla tworzenia raportu należy wybrać etap produkcji';
									|tr = 'Üretim birden fazla lot halinde planlandı, raporun oluşturulması için üretim aşamasını seçmeniz gerekmektedir'");
			EndIf;
			CommonClientServer.MessageToUser(MessageText);
			
		EndIf;
		
	ElsIf CurrentData.RowType = StringTypeStage() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CommandParameter", CurrentData.Stage);
		
		OpenForm(
			"Report.ConnectedProductionStagesChart.ObjectForm",
			FormParameters,
			ThisObject,
			CurrentData.Stage);
		
	Else
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Tạo báo cáo cho hàng đã chọn không khả dụng';
				|ru = 'Формирование отчета для выбранной строки недоступно';
				|en = 'Cannot generate the report for the selected line'; fa = 'Cannot generate the report for the selected line';
				|it = 'La generazione di report per la riga selezionata non è disponibile';
				|pl = 'Kształtowanie raportu dla wybranego wiersza nie jest dostępne';
				|tr = 'Seçili satır için raporun düzenlenmesi mevcut değildir'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StageResourceChart(Command)
	
	ClearMessages();
	
	CurrentData = Items.OrderStructure_2.CurrentData;
	
	If CurrentData = Undefined Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Dòng cấu trúc đơn hàng không được chọn';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"OrderStructure_2");
		
	ElsIf CurrentData.RowType = StringTypeStage() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CommandParameter", CurrentData.Stage);
		
		OpenForm(
			"Report.ProductionStageResourceChart.Form",
			FormParameters,
			ThisObject,
			CurrentData.Stage);
		
	Else
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để tạo báo cáo, bạn phải chọn công đoạn sản xuất';
				|ru = 'Для формирования отчета необходимо выбрать этап производства';
				|en = 'To generate a report, select a production stage'; fa = 'To generate a report, select a production stage';
				|it = 'Per generare un report, è necessario selezionare la fase di produzione.';
				|pl = 'Do tworzenia raportu należy wybrać etap produkcji';
				|tr = 'Raporun oluşturulması için üretim aşamasını seçmeniz gerekmektedir'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeStageChain(Command)
	
	ClearMessages();
	
	CurrentData = Items.OrderStructure_2.CurrentData;
	
	If CurrentData = Undefined Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Dòng cấu trúc đơn hàng không được chọn';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"OrderStructure_2");
		
	ElsIf CurrentData.RowType = LineTypeProducts()
		Or CurrentData.RowType = LineTypeSemiFinished() Then
		
		If Not CurrentData.ProductionLot.IsEmpty() Then
			
			ProductionManagementClient.OpenStageChainEditingForm(
				CurrentData.OrderDocument,
				CurrentData.ProductionLot,,
				ThisForm);
			
		Else
			
			ProductionLots = ProductProductionBatches(CurrentData.Source);
			If ProductionLots.Count() = 0 Then
				MessageText = NStr("vi = 'Không thể thực hiện hành động đã chọn cho hàng hiện tại.';
									|ru = 'Для текущей строки невозможно выполнить выбранное действие';
									|en = 'Cannot perform the selected action for the current line'; fa = 'Cannot perform the selected action for the current line';
									|it = 'Non è possibile eseguire l''azione selezionata per la riga corrente';
									|pl = 'Dla bieżącego wiersza nie można wykonać wybrane działanie';
									|tr = 'Mevcut satır için seçilen eylem gerçekleştirilemez'");
			Else
				MessageText = NStr("vi = 'Sản xuất được lên kế hoạch theo nhiều lô hàng, để thay đổi, cần phải chọn một công đoạn sản xuất';
									|ru = 'Производство запланировано несколькими партиями, для изменения необходимо выбрать этап производства';
									|en = 'Production is planned in several lots. To change, you must select the production stage'; fa = 'Production is planned in several lots. To change, you must select the production stage';
									|it = 'La produzione è programmata in più lotti, per modificare è necessario selezionare una fase di produzione';
									|pl = 'Produkcję zaplanowano w kilku partiach, dla zmiany należy wybrać etap produkcji';
									|tr = 'Üretim birden fazla lot halinde planlandı, raporun değiştirilmesi için üretim aşamasını seçmeniz gerekmektedir'");
			EndIf;
			CommonClientServer.MessageToUser(MessageText);
			
		EndIf;
		
	ElsIf CurrentData.RowType = StringTypeStage()
		And Not CurrentData.ProductionLot.IsEmpty() Then
		
		ProductionManagementClient.OpenStageChainEditingForm(
			CurrentData.OrderDocument,
			CurrentData.ProductionLot,,
			ThisForm);
		
	Else
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không thể thực hiện hành động đã chọn cho hàng hiện tại.';
				|ru = 'Для текущей строки невозможно выполнить выбранное действие';
				|en = 'Cannot perform the selected action for the current line'; fa = 'Cannot perform the selected action for the current line';
				|it = 'Non è possibile eseguire l''azione selezionata per la riga corrente';
				|pl = 'Dla bieżącego wiersza nie można wykonać wybrane działanie';
				|tr = 'Mevcut satır için seçilen eylem gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkStageChainForDeletion(Command)
	
	ClearMessages();
	
	CurrentData = Items.OrderStructure_2.CurrentData;
	
	If CurrentData = Undefined Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Dòng cấu trúc đơn hàng không được chọn';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"OrderStructure_2");
		
	ElsIf CurrentData.RowType = OrderLineType() Then
		
		CallbackDescription = New CallbackDescription("MarkStageChainForDeletionCompletion", ThisForm, CurrentData.OrderDocument);
	
		Presentation = ProductionManagementServerCall.OrderPresentation(CurrentData.OrderDocument,"");
		QueryText = StrTemplate(NStr("vi = 'Đặt dấu xóa tất cả các công đoạn của đơn hàng %1?';
									|ru = 'Пометить на удаление все этапы заказа %1?';
									|en = 'Mark all stages of order %1 for deletion?'; fa = 'Mark all stages of order %1 for deletion?';
									|it = 'Contrassegnare per eliminazione tutte le fasi dell''ordine%1?';
									|pl = 'Chcesz zaznaczyć do skasowania wszystkie etapy zamówienia %1?';
									|tr = '%1 emrinin tüm aşamaları silinmek üzere işaretlensin mi?'"), Presentation);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	ElsIf CurrentData.RowType = LineTypeProducts()
		Or CurrentData.RowType = LineTypeSemiFinished() Then
		
		ProductionLot = CurrentData.ProductionLot;
		If Not ValueIsFilled(ProductionLot) Then
			ProductionLot = ProductProductionBatches(CurrentData.Source);
		EndIf;
		
		If ValueIsFilled(ProductionLot) Then
			
			CallbackDescription = New CallbackDescription("MarkStageChainForDeletionCompletion",
				ThisForm,
				ProductionLot);
				
			ShowQueryBox(CallbackDescription,
				NStr("vi = 'Đánh dấu để xóa một chuỗi các công đoạn?';
					|ru = 'Пометить на удаление цепочки этапов?';
					|en = 'Mark stage chains for deletion?'; fa = 'Mark stage chains for deletion?';
					|it = 'Contrassegnare per l''eliminazione le catene di fasi?';
					|pl = 'Zaznaczyć na usunięcie łańcuchy etapów?';
					|tr = 'Aşama zincirleri silinmek üzere işaretlensin mi?'"),
				QuestionDialogMode.YesNo);
			
		Else
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Không thể thực hiện hành động đã chọn cho hàng hiện tại.';
					|ru = 'Для текущей строки невозможно выполнить выбранное действие';
					|en = 'Cannot perform the selected action for the current line'; fa = 'Cannot perform the selected action for the current line';
					|it = 'Non è possibile eseguire l''azione selezionata per la riga corrente';
					|pl = 'Dla bieżącego wiersza nie można wykonać wybrane działanie';
					|tr = 'Mevcut satır için seçilen eylem gerçekleştirilemez'"));
			
		EndIf;
		
	ElsIf CurrentData.RowType = StringTypeStage()
		And Not CurrentData.ProductionLot.IsEmpty() Then
		
		CallbackDescription = New CallbackDescription("MarkStageChainForDeletionCompletion",
			ThisForm,
			CurrentData.ProductionLot);
		
		ShowQueryBox(CallbackDescription,
			NStr("vi = 'Đánh dấu để xóa một chuỗi các công đoạn?';
				|ru = 'Пометить на удаление цепочки этапов?';
				|en = 'Mark stage chains for deletion?'; fa = 'Mark stage chains for deletion?';
				|it = 'Contrassegnare per l''eliminazione le catene di fasi?';
				|pl = 'Zaznaczyć na usunięcie łańcuchy etapów?';
				|tr = 'Aşama zincirleri silinmek üzere işaretlensin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không thể thực hiện hành động đã chọn cho hàng hiện tại.';
				|ru = 'Для текущей строки невозможно выполнить выбранное действие';
				|en = 'Cannot perform the selected action for the current line'; fa = 'Cannot perform the selected action for the current line';
				|it = 'Non è possibile eseguire l''azione selezionata per la riga corrente';
				|pl = 'Dla bieżącego wiersza nie można wykonać wybrane działanie';
				|tr = 'Mevcut satır için seçilen eylem gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkStageChainForDeletionCompletion(QuestionResult, ProcedureParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	RunBackgroundJob1("MarkProductionStagesForDeletion", ProcedureParameters);
	
EndProcedure

&AtClient
Procedure ChangeBatch(Command)
	
	ClearMessages();
	
	ProductionLot = Undefined;
	Stage = Undefined;
	
	CurrentData = Items.OrderStructure_2.CurrentData;
	
	If CurrentData = Undefined Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Dòng cấu trúc đơn hàng không được chọn';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"OrderStructure_2");
		
	ElsIf CurrentData.RowType = LineTypeProducts()
		Or CurrentData.RowType = LineTypeSemiFinished() Then
		
		If Not CurrentData.ProductionLot.IsEmpty() Then
			
			ProductionLot = CurrentData.ProductionLot;
			
		Else
			
			ProductionLots = ProductProductionBatches(CurrentData.Source);
			If ProductionLots.Count() = 0 Then
				MessageText = NStr("vi = 'Không thể thực hiện hành động đã chọn cho hàng hiện tại.';
									|ru = 'Для текущей строки невозможно выполнить выбранное действие';
									|en = 'Cannot perform the selected action for the current line'; fa = 'Cannot perform the selected action for the current line';
									|it = 'Non è possibile eseguire l''azione selezionata per la riga corrente';
									|pl = 'Dla bieżącego wiersza nie można wykonać wybrane działanie';
									|tr = 'Mevcut satır için seçilen eylem gerçekleştirilemez'");
			Else
				MessageText = NStr("vi = 'Sản xuất được lên kế hoạch theo nhiều lô hàng, để thay đổi, cần phải chọn một công đoạn sản xuất';
									|ru = 'Производство запланировано несколькими партиями, для изменения необходимо выбрать этап производства';
									|en = 'Production is planned in several lots. To change, you must select the production stage'; fa = 'Production is planned in several lots. To change, you must select the production stage';
									|it = 'La produzione è programmata in più lotti, per modificare è necessario selezionare una fase di produzione';
									|pl = 'Produkcję zaplanowano w kilku partiach, dla zmiany należy wybrać etap produkcji';
									|tr = 'Üretim birden fazla lot halinde planlandı, raporun değiştirilmesi için üretim aşamasını seçmeniz gerekmektedir'");
			EndIf;
			CommonClient.MessageToUser(MessageText);
			
		EndIf;
		
	ElsIf CurrentData.RowType = StringTypeStage()
		And Not CurrentData.ProductionLot.IsEmpty() Then
		
		ProductionLot = CurrentData.ProductionLot;
		Stage = CurrentData.Stage;
		
	Else
		
		CommonClient.MessageToUser(
			NStr("vi = 'Không thể thực hiện hành động đã chọn cho hàng hiện tại.';
				|ru = 'Для текущей строки невозможно выполнить выбранное действие';
				|en = 'Cannot perform the selected action for the current line'; fa = 'Cannot perform the selected action for the current line';
				|it = 'Non è possibile eseguire l''azione selezionata per la riga corrente';
				|pl = 'Dla bieżącego wiersza nie można wykonać wybrane działanie';
				|tr = 'Mevcut satır için seçilen eylem gerçekleştirilemez'"));
		
	EndIf;
	
	If ProductionLot <> Undefined Then
		
		If ObjectAttributeValue(ProductionLot, "ProcessType") 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các đơn hàng có quy trình sản xuất seri ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi seri';
					|ru = 'Для заказов с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order with ""No BOM"" production process type, lot change is not available'; fa = 'For order with ""No BOM"" production process type, lot change is not available';
					|it = 'Per gli ordini con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla zamówień o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan siparişler için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			New Structure("ProductionLot, Stage", ProductionLot, Stage),
			ThisForm,
			ProductionLot);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region ReportGeneration

&AtClient
Procedure UpdateDataOnClient()
	
	UpdateDataOnServer();
	
	If StartAwaitingLongAction Then
		StartAwaitingLongAction();
	Else
		ExpandLines();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDataOnServer()
	
	If Not ValueIsFilled(Orders) Then
		Return;
	EndIf;
	
	UpdateDashboard();
	
	If TimeConsumingOperation <> Undefined Then
		CancelLongRunningOperation(TimeConsumingOperation.JobID);
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("Products", FilterProducts);
	Filter.Insert("Stage", FilterStage);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Orders", Orders.UnloadValues());
	ProcedureParameters.Insert("Tree", FormAttributeToValue("Tree"));
	ProcedureParameters.Insert("Filter", Filter);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Tạo báo cáo ""Cấu trúc của một đơn đặt hàng sản xuất""';
			|ru = 'Формирование отчета ""Структура заказа на производство""';
			|en = 'Generate the ""Production order structure"" report'; fa = 'Generate the ""Production order structure"" report';
			|it = 'Formazione del report ""Struttura degli ordini di produzione""';
			|pl = 'Kształtowanie raportu ""Struktura zlecenia na produkcję""';
			|tr = '""Üretim Emri Yapısı"" raporunun düzenlenmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Reports.ProductionOrderStructure2_2.Generate",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartAwaitingLongAction = True;
		
	Else
		
		ProcessResultOfFormationInBackground(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
		
EndProcedure

&AtServerNoContext
Procedure CancelLongRunningOperation(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction()
	
	CallbackOnCompletion = New CallbackDescription("UpdateBackgroundDataEnd", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		CallbackOnCompletion,
		IdleParameters);
	
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationPage;
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtClient
Procedure UpdateBackgroundDataEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		ClearAndShowOrderStructure();
	Else
		ProcessResultOfFormationInBackground(Result);
		ExpandLines();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfFormationInBackground(Result)
	
	If Result.Status = "Completed2" Then
		
		ValueToFormAttribute(
			GetFromTempStorage(Result.ResultAddress),
			"Tree");
		
		DeriveStructure(True);
		
		Items.GroupPages.CurrentPage = Items.PageData;
		
	Else
		
		ClearAndShowOrderStructure();
		
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAndShowOrderStructure()
	
	OrderStructure_2.GetItems().Clear();
	
	Items.GroupPages.CurrentPage = Items.PageData;
	
EndProcedure

&AtClient
Procedure WhenChangingDisplaySettingsOnClient()
	
	WhenChangingDisplaySettingsOnServer();
	ExpandLines();
	
EndProcedure

&AtServer
Procedure WhenChangingDisplaySettingsOnServer()
	
	Settings = New Structure;
	Settings.Insert("HideCompleted", HideCompleted);
	Settings.Insert("StagesShow", StagesShow);
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		"",
		Settings);
	
	If Not StagesShow And Not FilterStage.IsEmpty() Then
		FilterStage = Undefined;
		WhenSelectionChangesOnServer();
	Else
		DeriveStructure(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenSelectionChangesOnClient()
	
	WhenSelectionChangesOnServer();
	ExpandLines();
	
EndProcedure

&AtServer
Procedure WhenSelectionChangesOnServer()
	
	IsDataUpdated = False;
	If HasFilter(ThisForm) Then
		
		Filter = New Structure;
		Filter.Insert("Products", FilterProducts);
		Filter.Insert("Stage", FilterStage);
		
		TreeCopy = FormAttributeToValue("Tree");
		Reports.ProductionOrderStructure2_2.ConfigureLineSelection(TreeCopy, Filter);
		ValueToFormAttribute(TreeCopy, "Tree");
		
		IsDataUpdated = True;
		
	EndIf;
	
	DeriveStructure(IsDataUpdated);
	
EndProcedure

#EndRegion

#Region FormationOfStages

&AtClient
Procedure GenerateProductionStages(Command)
	
	ReferencesArrray = Orders.UnloadValues();
	If ReferencesArrray.UBound() = -1 Then
		Return;
	EndIf;
	
	DefineParametersAndGenerateStages(ReferencesArrray);
	
EndProcedure

&AtClient
Procedure ItIsRequiredToClarifyStage(Command)
	
	OpeningParameters = New Structure("FiltersStructure", New Structure("ClarificationIsRequired", True));
	
	OpenForm("Document.ProductionStage2_2.Form.ProductionStageDispatching", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure HideTheGroupYouWantToFormTheStagesClick(Item)
	
	HideTheCommandYouNeedToFormTheStages = True;
	UpdateDashboard();
	
EndProcedure

&AtClient
Procedure DefineParametersAndGenerateStages(References)
	
	CallbackDescription = New CallbackDescription(
			"DefineParametersAndGenerateStagesCompletion", 
			ThisObject);
	
	OpenForm("Document.ProductionStage2_2.Form.StageGenerationSettings", 
		New Structure("References", References),
		ThisForm,
		UUID,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DefineParametersAndGenerateStagesCompletion(Result, References) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	RunBackgroundJob1("GenerateProductionStages", Result);
	
EndProcedure

#EndRegion

#Region FillingTree

&AtServer
Function DeriveStructure(IsDataUpdated)
	
	HasFilter = HasFilter(ThisForm);
	
	CurLines = Undefined;
	If Not HasFilter
		And Not IsDataUpdated
		And Items.OrderStructure_2.CurrentRow <> Undefined Then
		CurLines = New Array;
		String = Tree.FindByID(
			OrderStructure_2.FindByID(Items.OrderStructure_2.CurrentRow).Source);
		While String <> Undefined Do
			CurLines.Add(String.GetID());
			String = String.GetParent();
		EndDo;
	EndIf;
	
	OrderStructure_2.GetItems().Clear();
	ExpandedLines.Clear();
	CurrentRow = -1;
	
	For Each OrderDocument In Tree.GetItems() Do
		
		If HasFilter And Not OrderDocument.Filter Then
			Continue;
		EndIf;
		
		OrderRow = OrderStructure_2.GetItems().Add();
		FillPropertyValues(OrderRow, OrderDocument);
		OrderRow.Source = OrderDocument.GetID();
		// Expanded lines
		If OrderDocument.IsExpanded Then
			ExpandedLines.Add(OrderRow.GetID());
		EndIf;
		// Current line
		If HasFilter
			Or (CurLines <> Undefined And CurLines.Find(OrderRow.Source) <> Undefined) Then
			CurrentRow = OrderRow.GetID();
		EndIf;
		
		OrderRow.DescendantsAreDisplayed = True;
		
		For Each ManufacturedProduct In OrderDocument.GetItems() Do
			
			If HasFilter And Not ManufacturedProduct.Filter Then
				Continue;
			EndIf;
			
			If ManufacturedProduct.RowType = LineTypeOtherProducts()
				And (
					Not StagesShow
					Or HideCompleted And AllStagesAreCompleted(ManufacturedProduct)
				  ) Then
				Continue;
			EndIf;
			
			LineProducts = OrderRow.GetItems().Add();
			FillPropertyValues(LineProducts, ManufacturedProduct);
			LineProducts.Source = ManufacturedProduct.GetID();
			// Expanded lines
			If ManufacturedProduct.IsExpanded Then
				ExpandedLines.Add(LineProducts.GetID());
			EndIf;
			// Current line
			If HasFilter
				Or (CurLines <> Undefined And CurLines.Find(LineProducts.Source) <> Undefined) Then
				CurrentRow = LineProducts.GetID();
			EndIf;
			
			If ManufacturedProduct.IsExpanded Then
				AddProductDescendantsToTree(
					LineProducts.GetItems(),
					ManufacturedProduct.GetItems(),
					ThisForm,
					CurLines);
				LineProducts.DescendantsAreDisplayed = True;
			Else
				ConfigureOutputOfDescendantsOfProducts(ManufacturedProduct, LineProducts, ThisForm);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddProductDescendantsToTree(Receiver, Source, Form, CurLines)
	
	HasFilter = HasFilter(Form);
	
	For Each String In Source Do
		
		If String.RowType = StringTypeCreateStages() Then
			
			NewRow = Receiver.Add();
			FillPropertyValues(NewRow, String);
			NewRow.DescendantsAreDisplayed = True;
			Continue;
			
		EndIf;
		
		// Line type - stage
		If Form.StagesShow Then
			
			If ShowStage(String, Form) Then
				
				NewRow = Receiver.Add();
				FillPropertyValues(NewRow, String);
				NewRow.Source = String.GetID();
				// Expanded lines
				If String.IsExpanded Then
					Form.ExpandedLines.Add(NewRow.GetID());
				EndIf;
				// Current line
				If HasFilter
					Or (CurLines <> Undefined And CurLines.Find(NewRow.Source) <> Undefined) Then
					Form.CurrentRow = NewRow.GetID();
				EndIf;
				
				If String.IsExpanded Then
					AddDescendantsToTree(
						NewRow.GetItems(),
						String,
						Form,
						CurLines);
					NewRow.DescendantsAreDisplayed = True;
				Else
					If ThereAreDescendants(String, Form) Then
						NewRow.DescendantsAreDisplayed = False;
						NewRow.GetItems().Add();
					Else
						NewRow.DescendantsAreDisplayed = True;
					EndIf;
				EndIf;
				
			EndIf;
			
		Else
			
			If ThereAreDescendants(String, Form) Then
				AddDescendantsToTree(Receiver, String, Form, CurLines);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddDescendantsToTree(Receiver, Data_Stage, Form, CurLines)
	
	HasFilter = HasFilter(Form);
	
	For Each String In Data_Stage.GetItems() Do
		
		If ShowProducts(String, Data_Stage, Form) Then
			
			NewRow = Receiver.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Source = String.GetID();
			// Expanded lines
			If String.IsExpanded Then
				Form.ExpandedLines.Add(NewRow.GetID());
			EndIf;
			// Current line
			If HasFilter
				Or (CurLines <> Undefined And CurLines.Find(NewRow.Source) <> Undefined) Then
				Form.CurrentRow = NewRow.GetID();
			EndIf;
			
			If String.IsExpanded Then
				AddProductDescendantsToTree(
					NewRow.GetItems(),
					String.GetItems(),
					Form,
					CurLines);
				NewRow.DescendantsAreDisplayed = True;
			Else
				ConfigureOutputOfDescendantsOfProducts(String, NewRow, Form);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FinishStageTree(TreeRow)
	
	Children = TreeRow.GetItems();
	
	EmptyDescendant = Children[0];
	Children.Delete(EmptyDescendant);
	
	SourceRow = Tree.FindByID(TreeRow.Source);
	
	If TreeRow.RowType = LineTypeProducts()
		Or TreeRow.RowType = LineTypeSemiFinished()
		Or TreeRow.RowType = LineTypeOtherProducts() Then
		
		AddProductDescendantsToTree(
			Children,
			SourceRow.GetItems(),
			ThisForm,
			Undefined);
		
	ElsIf TreeRow.RowType = StringTypeStage() Then
		
		AddDescendantsToTree(Children, SourceRow, ThisForm, Undefined);
		
	EndIf;
	
	TreeRow.DescendantsAreDisplayed = True;
	
EndProcedure

&AtServer
Function AllStagesAreCompleted(StringTreeOutput)
	
	Result = True;
	
	For Each String In StringTreeOutput.GetItems() Do
		If Not String.Completed Then
			Result = False;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure ConfigureOutputOfDescendantsOfProducts(ProductData_1, StringProducts_, Form)
	
	Children = StringProducts_.GetItems();
	
	If ThereAreDescendantsOfProduct(ProductData_1, Form) Then
		StringProducts_.DescendantsAreDisplayed = False;
		Children.Add();
	Else
		StringProducts_.DescendantsAreDisplayed = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ThereAreDescendants(Data_Stage, Form)
	
	Result = False;
	
	For Each ProductData_1 In Data_Stage.GetItems() Do
		If ShowProducts(ProductData_1, Data_Stage, Form) Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ShowProducts(ProductData_1, ParentStageData, Form)
	
	Result = True;
	
	HasFilter = HasFilter(Form);
	If HasFilter And Not ProductData_1.Filter Then
		Result = False;
	ElsIf Form.HideCompleted Then
		Result = Not StageCompletedSemiFinishedProductProduced(ParentStageData, True)
			Or Not StageCompletedSemiFinishedProductProduced(ProductData_1, False);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreDescendantsOfProduct(ProductData_1, Form)
	
	Result = False;
	
	For Each Item In ProductData_1.GetItems() Do
		
		If Item.RowType = StringTypeStage() Then
			
			If Form.StagesShow Then
					
				If ShowStage(Item, Form) Then
					Result = True;
					Break;
				EndIf;
					
			Else
					
				If ThereAreDescendants(Item, Form) Then
					Result = True;
					Break;
				EndIf;
				
			EndIf;
			
		ElsIf Item.RowType = StringTypeCreateStages() Then
			
			Result = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ShowStage(Data_Stage, Form)
	
	If Form.StagesShow Then
		HasFilter = HasFilter(Form);
		If HasFilter And Not Data_Stage.Filter Then
			Result = False;
		ElsIf Form.HideCompleted Then
			Result = Not StageCompletedSemiFinishedProductProduced(Data_Stage, True);
		Else
			Result = True;
		EndIf;
	Else
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ExpandLines()
	
	For Each String In ExpandedLines Do
		If Not Items.OrderStructure_2.Expanded(String.Value) Then
			Items.OrderStructure_2.Expand(String.Value, False);
		EndIf;
	EndDo;
	
	If CurrentRow <> -1 Then
		Items.OrderStructure_2.CurrentRow = CurrentRow;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function OrderLineType()
	
	Return 3;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeProducts()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeSemiFinished()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function StringTypeStage()
	
	Return 4;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeSemiFinishedProductOfAnotherOrder()
	
	Return 5;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeOtherProducts()
	
	Return 7;
	
EndFunction

&AtClientAtServerNoContext
Function StringTypeCreateStages()
	
	Return 6;
	
EndFunction

&AtClientAtServerNoContext
Function StageCompletedSemiFinishedProductProduced(SemiFinishedProductStageData, ThisIsAStep)
	
	If ThisIsAStep Then
		Result = SemiFinishedProductStageData.Completed;
	Else
		Result = SemiFinishedProductStageData.CountReal
			>= (SemiFinishedProductStageData.CountPlan - SemiFinishedProductStageData.CountCanceled);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function HasFilter(Form)
	Return Not(Form.FilterProducts.IsEmpty() And Form.FilterStage.IsEmpty());
EndFunction

#EndRegion

#Region BackgroundJobs

&AtClient
Procedure RunBackgroundJob1(JobName, ProcedureParameters)
	
	ClearMessages();
	
	RunResult = RunBackgroundJobOnServer(JobName, ProcedureParameters);
	
	If RunResult.StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("ExecuteInBackgroundCompletion", ThisObject, New Structure("JobName", JobName)),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		ProcessJobCompletionOnClient(JobName, RunResult.JobResult);
		
	EndIf;
	
EndProcedure

&AtServer
Function RunBackgroundJobOnServer(JobName, ProcedureParameters)
	
	If JobName = "MarkProductionStagesForDeletion" Then
		
		ProcedureName = "Documents.ProductionStage2_2.MarkStagesDeferredForDeletion";
		JobDescription = NStr("vi = 'Đánh dấu xóa các công đoạn sản xuất';
								|ru = 'Пометка на удаление этапов производства';
								|en = 'Production stage deletion mark'; fa = 'Production stage deletion mark';
								|it = 'Contrassegno di eliminazione delle fasi di produzione';
								|pl = 'Zaznaczenie do usuwania etapów produkcji';
								|tr = 'Üretim aşamalarının silinmesine yönelik işaret'");
		
	ElsIf JobName = "GenerateProductionStages" Then
		
		ProcedureName = "Documents.ProductionStage2_2.GenerateStages";
		JobDescription = NStr("vi = 'Lập các công đoạn sản xuất';
								|ru = 'Формирование этапов производства';
								|en = 'Generate production stages'; fa = 'ایجاد مراحل تولید';
								|it = 'Generazione fasi di produzione';
								|pl = 'Tworzenie etapów produkcji';
								|tr = 'Üretim aşamalarının düzenlenmesi'");
		
	Else
		Return New Structure("StartWaiting, JobResult", False, Undefined);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters);
	
	StartWaiting = True;
	JobResult = Undefined;
	
	If TimeConsumingOperation.Status <> "Running" Then
		
		StartWaiting = False;
		JobResult = ProcessJobCompletionOnServer(TimeConsumingOperation);
		
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return New Structure("StartWaiting, JobResult", StartWaiting, JobResult);
	
EndFunction

&AtClient
Procedure ExecuteInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		JobResult = ProcessJobCompletionOnServer(Result);
		
		ProcessJobCompletionOnClient(AddlParameters.JobName, JobResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessJobCompletionOnClient(JobName, JobResult)

	If JobName = "GenerateProductionStages" Then
		
		ProductionManagementClient.NotifyUserAboutFormationOfProductionStages(
			JobResult, UUID);
		
	ElsIf JobName = "MarkProductionStagesForDeletion" Then
		
		ProductionManagementClient.NotifyUserAboutMarkToDeleteProductionStages(
			JobResult);
		
	EndIf;
	
	UpdateDataOnClient();
	
EndProcedure

&AtServer
Function ProcessJobCompletionOnServer(Result)
	
	JobResult = GetFromTempStorage(Result.ResultAddress);
	
	If Result.Status = "Error" Then
		
		If TypeOf(JobResult) = Type("Structure") And JobResult.Property("Messages") Then
			
			For Each Message In JobResult.Messages Do
			
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
	Return JobResult;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	#Region HideInformationLine
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructureInformationLineHyperlink.Name);
	
	FilterValues = New ValueList;
	FilterValues.Add(LineTypeSemiFinishedProductOfAnotherOrder());
	FilterValues.Add(StringTypeCreateStages());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = FilterValues;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region HidePurposeOfSemiFinishedProduct
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2Purpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = LineTypeProducts();
	
	Item.Appearance.SetParameterValue("Show", False);
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion

	#Region EmptyQuantityInRowWithNoData
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountPlan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountReal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2TheAmountOfTheShortfall.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountCanceled.Name);
	
	FilterValues = New ValueList;
	FilterValues.Add(OrderLineType());
	FilterValues.Add(StringTypeCreateStages());
	FilterValues.Add(LineTypeOtherProducts());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = FilterValues;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	#EndRegion
	
	#Region HideImagesInRows
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2PictureNumber.Name);
	
	FilterValues = New ValueList;
	FilterValues.Add(OrderLineType());
	FilterValues.Add(LineTypeProducts());
	FilterValues.Add(StringTypeCreateStages());
	FilterValues.Add(LineTypeOtherProducts());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = FilterValues;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
	
	#Region TotalsByNumber
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2NumberOfPlansTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2QuantityFactTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2QuantityDeficitTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2QuantityCanceledTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructureTextTotalQuantity.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.NumberOfPlansTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("OrderStructure_2.CountPlan");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.QuantityFactTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("OrderStructure_2.CountReal");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2NumberOfPlansTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2QuantityFactTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2QuantityDeficitTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2QuantityCanceledTotal.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.NumberOfPlansTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("OrderStructure_2.CountPlan");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.QuantityFactTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("OrderStructure_2.CountReal");

	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructureTextTotalQuantity.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.NumberOfPlansTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("OrderStructure_2.CountPlan");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.QuantityFactTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("OrderStructure_2.CountReal");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Lô sản xuất';
													|ru = 'Партия производства';
													|en = 'Production lot'; fa = 'بچ تولید';
													|it = 'Lotto di produzione';
													|pl = 'Partia produkcji';
													|tr = 'Üretim lotu'"));
	
	#EndRegion
	
	#Region CreateStages
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2PictureNumber.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2LinePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2Purpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StringTypeCreateStages();
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructureInformationLineHyperlink.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StringTypeCreateStages();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo công đoạn';
													|ru = 'Создать этапы';
													|en = 'Create stages'; fa = 'Create stages';
													|it = 'Creare fasi';
													|pl = 'Utwórz etapy';
													|tr = 'Aşamaları oluştur'"));
	
	#EndRegion
	
	#Region BackgroundColorOrder
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = OrderLineType();
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	#EndRegion
	
	#Region FontProducts
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2.Name);
	
	FilterValues = New ValueList;
	FilterValues.Add(LineTypeProducts());
	FilterValues.Add(LineTypeOtherProducts());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = FilterValues;
	
	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
	#EndRegion
	
	#Region HighlightLightGray
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StringTypeStage();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.ExecutedPerformed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2.Name);
	
	FilterValues = New ValueList;
	FilterValues.Add(LineTypeSemiFinished());
	FilterValues.Add(LineTypeSemiFinishedProductOfAnotherOrder());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = FilterValues;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.ExecutedPerformed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.ExecutedPerformedParent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	#EndRegion
	
	#Region HighlightInRed_
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2EndDatePlan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.ExecutedPerformed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.EndDatePlan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.EndDatePlan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	#EndRegion
	
	#Region FactOfStageOnSide
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountReal.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2TheAmountOfTheShortfall.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StringTypeStage();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.StageProductionOnTheSide");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
	#Region NumberOfStagesWithoutSpecification
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountPlan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountReal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2TheAmountOfTheShortfall.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderStructure_2CountCanceled.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StringTypeStage();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderStructure_2.StageProductionWithoutSpecification");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(Orders) Then
		
		If Orders.Count() = 1 Then
			
			OrderData = Common.ObjectAttributesValues(Orders[0].Value, "Number, Date");
		
			OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(
				OrderData.Number, False, True);
			OrderDate = Format(OrderData.Date, "DLF=D");
			
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cấu trúc đơn hàng sản xuất số %1 ngày %2';
					|ru = 'Структура заказа на производство № %1 от %2';
					|en = 'Structure of production order No. %1 dated %2'; fa = 'Structure of production order No. %1 dated %2';
					|it = 'Struttura ordine in produzione №%1 di %2';
					|pl = 'Struktura zlecenie produkcyjne nr %1 z dnia %2';
					|tr = '%2 tarihli %1 numaralı üretim emri yapısı'"),
				OrderNumber,
				OrderDate);
			
		Else
			
			Title = NStr("vi = 'Cấu trúc đơn hàng sản xuất';
						|ru = 'Структура заказов на производство';
						|en = 'Production order structure'; fa = 'ساختار سفارش تولید';
						|it = 'Struttura degli ordini in produzione';
						|pl = 'Struktura zamówień zlecenia produkcyjnego';
						|tr = 'Üretim emri yapısı'");
			
		EndIf;
		
	Else
		
		Title = NStr("vi = 'Cấu trúc đơn hàng sản xuất (không chọn đơn hàng)';
					|ru = 'Структура заказа на производство (не выбран заказ)';
					|en = 'Production order structure (order is not selected)'; fa = 'Production order structure (order is not selected)';
					|it = 'Struttura dell''ordine in produzione (ordine non selezionato)';
					|pl = 'Struktura zamówień zlecenia produkcyjnego (zamówienie nie wybrane)';
					|tr = 'Üretim emri yapısı (emir seçilmedi)'");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("StagesShow") 
		Or Initialize Then
		
		Items.FilterStage.Visible = Form.StagesShow;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(FormKey(), "");
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Settings);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FormKey()
	
	Return "Report.ProductionOrderStructure2_2.OrderStructure";
	
EndFunction

&AtServer
Procedure UpdateDashboard()
	
	CommandVisibility = Not HideTheCommandYouNeedToFormTheStages And Orders.Count() <> 0;
	
	If CommandVisibility Then
		
		ReferencesArrray = Orders.UnloadValues();
		If Documents.ProductionOrder2_2.NeedToClarifySteps(ReferencesArrray) Then
			Items.ThePictureIsRequiredToFormTheStages.Visible = False;
			Items.TheLabelIsRequiredToFormTheStages.Visible  = False;
			Items.GenerateProductionStages.Visible      = False;
			Items.ItIsRequiredToClarifyStage.Visible              = True;
		Else
			Items.ThePictureIsRequiredToFormTheStages.Visible = True;
			Items.TheLabelIsRequiredToFormTheStages.Visible  = True;
			Items.GenerateProductionStages.Visible      = True;
			Items.ItIsRequiredToClarifyStage.Visible              = False;
			CommandVisibility = Documents.ProductionOrder2_2.ItIsRequiredToFormStagesAccordingToSpecification(ReferencesArrray);
		EndIf;
		
	EndIf;
	
	Items.GroupRequiredToFormStages.Visible = CommandVisibility;
	
EndProcedure

&AtClient
Procedure OpenProductionOrderLine(CurrentData)
	
	RowData = ProductionManagementClientServer.OrderProductionStructure();
	FillPropertyValues(RowData, CurrentData);
	RowData.Warehouse         = CurrentData.Warehouse;
	RowData.Department = CurrentData.Warehouse;
	
	ProductionManagementClient.OpenProductionOrderLine(CurrentData.OrderDocument, RowData, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSemiFinishedProductStructureFormOfAnotherOrder(CurrentData)
	
	OrdersParameter = New Array;
	OrdersParameter.Add(CurrentData.OrderDocument);
	
	FormParameters = New Structure("Orders", OrdersParameter);
	
	OpenForm(
		"Report.ProductionOrderStructure2_2.Form.OrderStructure",
		FormParameters,
		ThisObject,
		CurrentData.OrderDocument);
	
EndProcedure

&AtClient
Procedure OpenStageCreationForm(CurrentData)
	
	NeedString = CurrentData.GetParent();
	
	If NeedString.GetParent().RowType = OrderLineType() Then
		
		AttributesValues = ObjectAttributesValues(NeedString.OrderDocument, "ProductionProcessType, ProductionLot");
		
		ProductionProcessType = AttributesValues.ProductionProcessType;
		ProductionLot           = AttributesValues.ProductionLot;
		
	Else
		
		ProductionProcessType = NeedString.ProcessType;
		ProductionLot           = Undefined;
		
	EndIf;
	
	Deficit = New Array;
	
	QuantityToCreate = NeedString.CountPlan
		- NeedString.CountCanceled
		- NeedString.QuantityCreated;
	
	If QuantityToCreate > 0 Then
		
		ManufacturedProduct = New Structure;
		
		ManufacturedProduct.Insert("Products",             NeedString.Products);
		ManufacturedProduct.Insert("Characteristic",           NeedString.Characteristic);
		ManufacturedProduct.Insert("Purpose",               NeedString.Purpose);
		ManufacturedProduct.Insert("ToExpenseAs",         NeedString.ToExpenseAs);
		ManufacturedProduct.Insert("ExpenseItem",           NeedString.ExpenseItem);
		ManufacturedProduct.Insert("DimensionOfExpenses",        NeedString.DimensionOfExpenses);
		ManufacturedProduct.Insert("AssetsLiabilitiesDimension", NeedString.AssetsLiabilitiesDimension);
		ManufacturedProduct.Insert("Count",               QuantityToCreate);
		ManufacturedProduct.Insert("NumberOfPackages",       QuantityToCreate);
		
		If NeedString.ProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
			ManufacturedProduct.Insert("Warehouse", NeedString.Warehouse);
		Else
			ManufacturedProduct.Insert("Recipient", NeedString.Warehouse);
		EndIf;
		
		Deficit.Add(ManufacturedProduct);
		
	EndIf;
	
	If ValueIsFilled(ProductionLot) Then
		
		ProductionManagementClient.OpenStageChainEditingForm(
			NeedString.OrderDocument,
			ProductionLot,
			Deficit,
			ThisObject);
		
	Else
		
		ProductionManagementClient.OpenFormForCreatingNewStageChain(
			NeedString.OrderDocument,
			ProductionProcessType,
			NeedString.AssignmentProducts,
			Deficit,
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ObjectAttributeValue(Ref, AttributeName)
	
	Return Common.ObjectAttributeValue(Ref, AttributeName);
	
EndFunction
	
&AtServerNoContext
Function ObjectAttributesValues(Ref, Attributes)
	
	Return Common.ObjectAttributesValues(Ref, Attributes);
	
EndFunction

&AtServer
Function ProductProductionBatches(RowID)
	
	Result = New Array;
	
	TreeRow = Tree.FindByID(RowID);
	
	If TreeRow.ProductionLot.IsEmpty() Then
		
		For Each String In TreeRow.GetItems() Do
		
			If Result.Find(String.ProductionLot) = Undefined Then
				Result.Add(String.ProductionLot);
			EndIf;
			
		EndDo;
		
	Else
		Result.Add(TreeRow.ProductionLot);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
