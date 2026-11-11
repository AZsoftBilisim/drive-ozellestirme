#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	RestoreSettings();
	CurrentRow = -1;
	ThisIsDecryptionMode = False;
	
	If Not Parameters.OrderDocument.IsEmpty() Then
		
		OrderDocument = Parameters.OrderDocument;
		NomenclatureSelection = Parameters.Products;
		ProductSearchKey = Parameters.KeyProducts;
		PurposeSelection = Parameters.Purpose;
		
		If TypeOf(Parameters.LaunchOrderStages) = Type("FixedArray")
			And Parameters.LaunchOrderStages.UBound() <> -1 Then
			StagesOfSelection = Parameters.LaunchOrderStages;
			StagesSelectionNomenclature = Parameters.LaunchOrderNomenclature;
			StagesSelectionCharacteristics = Parameters.LaunchOrderCharacteristics;
			StagesSelectionWarehouse = Parameters.OrderToLaunchWarehouse;
			StagesSelectionAppointment = Parameters.LaunchOrderAppointment;
			ThisIsDecryptionMode = True;
		EndIf;
		
		If Parameters.Property("StagesShow") Then
			StagesShow = Parameters.StagesShow;
		EndIf;
		
		FillInDetailsForOrder();
		
		Action = "Fill";
		Result = StartExecutionOfAction();
		If Not Result.ActionStarted
			And OrderStructureClientServer.ExpectEndOfOrderStructureCalculation(
				Result.CalculationProtocol.State, Result.CalculationProtocol.StateCodes) Then
			StartWaitingForCalculationWhenOpening = True;
		EndIf;
		
	EndIf;
	
	If Not TypeOf(StagesOfSelection) = Type("FixedArray") Then
		StagesOfSelection = New FixedArray(New Array);
	EndIf;
	
	ThereIsRightToFormStages = AccessRight("Use", Metadata.DataProcessors.GeneratingProductionStages);
	Items.GenerateStages.Visible = ThereIsRightToFormStages;
	
	If ThisIsDecryptionMode Then
		Items.OrderDocument.ReadOnly = True;
		Items.PurposeSelection.Visible = False;
	EndIf;
	
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	UseQuality = GetFunctionalOption("UseGoodsQuality");
	
	Items.GanttChart.Visible = TheProductionScheduleIsUsed;
	Items.StageResourceChart.Visible = TheProductionScheduleIsUsed;
	
	SamplePortionSize = Reports.ProductionOrderStructureDynamic.SamplePortionSize();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartWaitingForCalculationWhenOpening Then
		StartWaitingForCalculationWhenOpening = False;
		AttachIdleHandler("StartWaitingForEndOfCalculationWhenOpening", 0.1, True);
	ElsIf StartAwaitingLongAction Then
		AttachIdleHandler("StartWaitingForLongOperationWhenOpening", 0.1, True);
	ElsIf Not OrderDocument.IsEmpty() Then
		ExpandLines();
	EndIf;
	
	MarkDetailButtons();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Action = "Fill";
	ExpectStructureCalculationAndPerformAction();
	
EndProcedure

&AtClient
Procedure StartWaitingForEndOfCalculationWhenOpening()
	
	Action = "Fill";
	ExpectStructureCalculationAndPerformAction();
	
EndProcedure

&AtClient
Procedure StartWaitingForLongOperationWhenOpening()
	
	StartAwaitingLongAction("FillInBackgroundEnd");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrderDocumentOnChange(Item)
	
	ClearMessages();
	
	InformationBar = Undefined;
	
	If OrderDocument.IsEmpty() Then
		Tree.GetItems().Clear();
	Else
		FillInDetailsForOrder = True;
		Action = "Fill";
		ExpectStructureCalculationAndPerformAction();
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "OrderDocument");
	
EndProcedure

&AtClient
Procedure NomenclatureSelectionOnChange(Item)
	
	ProductSearchKey = Undefined;
	FilterOnChange();
	
EndProcedure

&AtClient
Procedure WarehouseSelectionOnChange(Item)
	
	FilterOnChange();
	
EndProcedure

&AtClient
Procedure PurposeSelectionOnChange(Item)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Action = "Fill";
	ExpectStructureCalculationAndPerformAction();
	
EndProcedure

&AtClient
Procedure FilterOnChange()
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If ThisIsSearchInStructure(ThisObject) Then
		
		Action = "Fill";
		ExpectStructureCalculationAndPerformAction();
		
	ElsIf FilterIs_Specified Then
		
		Action = "FillInExpand";
		ActionParameters = New Structure;
		ActionParameters.Insert("RowsIDs", IdsOfExpandedRows());
		
		ExpectStructureCalculationAndPerformAction();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ErrorsInSelectionOfSpecificationsInProductionOrdersURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ParametersStructure = New Structure("ProductionOrder", OrderDocument);
	OpenForm("InformationRegister.OrderStructureCalculationProtocol.Form.DisplayErrorsOfSelectingBOMsInProductionOrders", ParametersStructure, OrderDocument);
	
EndProcedure

&AtClient
Procedure ErrorsInFillingInProductDataURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ParametersStructure = New Structure("ProductionOrder", OrderDocument);
	OpenForm("InformationRegister.OrderStructureCalculationProtocol.Form.DisplayProductStructureExplosionErrors", ParametersStructure, OrderDocument);

EndProcedure

&AtClient
Procedure ErrorsInCalculationOfRegulatoryScheduleURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ParametersStructure = New Structure("ProductionOrder", OrderDocument);
	OpenForm("InformationRegister.TargetOrderStructureSchedule.Form.ErrorLog", ParametersStructure, OrderDocument);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStageTree

&AtClient
Procedure TreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TreeRow = Item.RowData(RowSelected);
	
	If Field.Name = "BillOfMaterials"
		And ValueIsFilled(TreeRow.BillOfMaterials) Then
		
		ShowValue(, TreeRow.BillOfMaterials);
		
	ElsIf Field.Name = "WarehouseDivision"
		And ValueIsFilled(TreeRow.WarehouseDivision) Then
		
		ShowValue(, TreeRow.WarehouseDivision);
		
	ElsIf Field.Name = "Warehouse"
		And ValueIsFilled(TreeRow.Warehouse) Then
		
		ShowValue(, TreeRow.Warehouse);
		
	ElsIf Field.Name = "Department"
		And ValueIsFilled(TreeRow.Department) Then
		
		ShowValue(, TreeRow.Department);
		
	ElsIf (Field.Name = "Left"
			   Or Field.Name = "IndexOfImageIsStillFreeOrNotNeeded"
			   Or Field.Name = "IndexOfImageRemainsForOtherPurposes"
			   Or Field.Name = "IndexOfImageRemainsInAnotherWarehouse"
			   Or Field.Name = "IndexOfImageLeft")
			And TreeRow.IndexOfImageLeft > 0 Then
		
		OpenProductBalancesAndAvailabilityReport(TreeRow.Products, TreeRow.Characteristic);
		
	ElsIf (Field.Name = "Required2" Or Field.Name = "Done" Or Field.Name = "Left" Or Field.Name = "Launched")
			And (TreeRow.RowType = LineTypeSemiFinished()
				Or TreeRow.RowType = LineTypeMove()
				Or TreeRow.RowType = LineTypeMaterial()) Then
		
		OpenStaffingByLine(TreeRow);
		
	ElsIf TreeRow.RowType = StringTypeStructureStage()
		Or TreeRow.RowType = LineTypeStageDocument() Then
		
		ShowValue(, TreeRow.StageLink);
		
	ElsIf TreeRow.RowType = LineTypeSemiFinished()
		Or TreeRow.RowType = LineTypeProduct()
		Or TreeRow.RowType = LineTypeMove()
		Or TreeRow.RowType = LineTypeMaterial()
		Or TreeRow.RowType = LineTypeDecryptionNomenclature()
		Or TreeRow.RowType = LineTypeIssue() Then
		
		ShowValue(, TreeRow.Products);
		
	ElsIf TreeRow.RowType = LineTypeLaunchOrder() Then
		
		If ObjectAttributeValue(TreeRow.LaunchOrder, "DynamicStructure") Then
			
			FormParameters = New Structure;
			FormParameters.Insert("OrderDocument", TreeRow.LaunchOrder);
			FormParameters.Insert("StagesShow", True);
			
			Uniqueness = Undefined;
			
			ParentRow = TreeRow.GetParent();
			If TreeRow.LaunchOrderStages.UBound() <> -1 Then
				FormParameters.Insert("LaunchOrderStages", TreeRow.LaunchOrderStages);
				FormParameters.Insert("LaunchOrderNomenclature", ParentRow.Products);
				FormParameters.Insert("LaunchOrderCharacteristics", ParentRow.Characteristic);
				FormParameters.Insert("OrderToLaunchWarehouse", ParentRow.Warehouse);
				FormParameters.Insert("LaunchOrderAppointment", ParentRow.Purpose);
				Uniqueness = TreeRow.LaunchOrderStages[0];
			Else
				FormParameters.Insert("Purpose", ParentRow.Purpose);
				Uniqueness = TreeRow.LaunchOrder;
			EndIf;
			
			OpenForm(
				"Report.ProductionOrderStructureDynamic.Form.ReportForm",
				FormParameters,
				ThisObject,
				Uniqueness);
			
		Else
			
			FormParameters = New Structure;
			FormParameters.Insert("OrderDocument", TreeRow.LaunchOrder);
			
			OpenForm(
				"Report.ProductionOrderStructure2_2.Form.OrderStructure",
				FormParameters,
				ThisObject,
				TreeRow.LaunchOrder);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TreeBeforeExpand(Item, String, Cancel)
	
	TreeRow = Item.RowData(String);
	
	If TreeRow.FinishTree Then
		
		PerformanceMonitorClient.TimeMeasurement(
			"Report.ProductionOrderStructureDynamic.ReportForm.FinishTree");
		
		Rows = TreeRow.GetItems();
		
		PartyKeys = New Array;
		For IndexOf = -Rows.Count()+1 To 0 Do
			String = Rows[-IndexOf];
			If String.RowType = RowTypeInternal() Then
				PartyKeys.Add(String.KeyLot);
				Rows.Delete(-IndexOf);
			EndIf;
		EndDo;
		
		TreeRow.FinishTree = False;
		
		FinishTree(PartyKeys, TreeRow.StageLink, TreeRow.GetID());
		
		ExpandLines();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TreeOnActivateRow(Item)
	
	CurrentData = Items.Tree.CurrentData;
	
	HasChildren = CurrentData <> Undefined
		And CurrentData.GetItems().Count() > 0;
	Items.DeploySubordinates.Visible = HasChildren;
	
	YouCanReplaceSpecification = CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeProduct()
				And Not CurrentData.MultipleSpecifications
			Or CurrentData.RowType = LineTypeSemiFinished()
				And Not CurrentData.MultipleSpecifications
			Or CurrentData.RowType = StringTypeStructureStage())
		And CurrentData.Left > 0;
	Items.ReplaceBOR.Visible = YouCanReplaceSpecification;
	Items.TreeContextMenuReplaceBOR.Visible = YouCanReplaceSpecification;
	
	CanBeRefilledAccordingToSpecification = CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeProduct()
				And Not CurrentData.MultipleSpecifications
			Or CurrentData.RowType = LineTypeSemiFinished()
				And Not CurrentData.MultipleSpecifications
			Or CurrentData.RowType = StringTypeStructureStage()
			Or CurrentData.RowType = LineTypeStageDocument());
	Items.TreeContextMenuReFillBySpecification.Visible = CanBeRefilledAccordingToSpecification;

	Items.TreeContextMenuMoveFinishedProduct.Visible = 
		CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeMove() Or CurrentData.MultipleWarehouses
			Or CurrentData.GetParent() <> Undefined And CurrentData.GetParent().RowType = LineTypeMove());
	
	Items.TreeContextMenuMoveToComponents.Visible =
		CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeProduct()
			Or CurrentData.RowType = LineTypeSemiFinished()
			Or CurrentData.RowType = StringTypeStructureStage());
	
	Items.TreeContextMenuCreateAssignmentAdjustmentDocument.Visible = 
		CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeSemiFinished()
			Or CurrentData.RowType = LineTypeMove()
			Or CurrentData.RowType = LineTypeMaterial())
		And ValueIsFilled(CurrentData.Purpose)
		And CurrentData.Left > 0;
	
	Items.TreeContextMenuFormStagesByLine.Visible = 
		CurrentData <> Undefined
		And CurrentData.RowType <> LineTypeMaterial()
		And CurrentData.RowType <> LineTypeIssue();
	
	Items.TreeContextMenuChangeBatch.Visible =
		CurrentData <> Undefined
		And CurrentData.RowType = LineTypeStageDocument();
	
	Items.TreeContextMenuDeleteBatchStages.Visible =
		CurrentData <> Undefined
		And CurrentData.RowType = LineTypeStageDocument();
	
	Items.TreeContextMenuGenerateReportDecodingStaffingContext.Visible =
		CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeSemiFinished()
			Or CurrentData.RowType = LineTypeMove()
			Or CurrentData.RowType = LineTypeMaterial());
	
	Items.TreeContextMenuCancel.Visible =
		CurrentData <> Undefined
		And CurrentData.RowType = LineTypeIssue()
		And Not CurrentData.ProductionLot.IsEmpty()
		And Not CurrentData.Canceled;
	
	Items.TreeContextMenuChangeQuality.Visible =
		UseQuality
		And CurrentData <> Undefined
		And CurrentData.RowType = LineTypeIssue()
		And Not CurrentData.ProductionLot.IsEmpty()
		And Not CurrentData.Canceled
		And CurrentData.Quality = PredefinedValue("Enum.QualityLevels.New");
	
	Items.TreeContextMenuAddWorks.Visible =
		CurrentData <> Undefined
		And CurrentData.RowType = LineTypeStageDocument()
		And CurrentData.WorkPlanning;
	
	If CurrentData <> Undefined Then
		AttachIdleHandler("FillInCurStateOfSoftware", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowStages(Command)
	
	StagesShow = Not StagesShow;
	
	ActionsONChangingDetailTag();
	
EndProcedure

&AtClient
Procedure ShowMaterials(Command)
	
	ShowContent = Not ShowContent;
	
	ActionsONChangingDetailTag();
	
EndProcedure

&AtClient
Procedure ShowIssues(Command)
	
	ShowIssues = Not ShowIssues;
	
	ActionsONChangingDetailTag();
	
EndProcedure

&AtClient
Procedure ShowTransfers(Command)
	
	ShowMovements = Not ShowMovements;
	
	ActionsONChangingDetailTag();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Action = "Fill";
	ExpectStructureCalculationAndPerformAction();
	
EndProcedure

&AtClient
Procedure GanttChart(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Не выбрана строка структуры заказа';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	If CurrentData.RowType = LineTypeLaunchOrder() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CommandParameter", OrderDocument);
		
		OpenForm(
			"Report.MonitorOrder.ObjectForm",
			FormParameters,
			ThisObject,
			OrderDocument);
		
	ElsIf CurrentData.RowType = StringTypeStructureStage() Or CurrentData.RowType = LineTypeStageDocument() Then
		
		FormParameters = New Structure;
		If CurrentData.RowType = LineTypeStageDocument() Then
			FormParameters.Insert("CommandParameter", CurrentData.StageLink);
		Else
			FormParameters.Insert("Stage", CurrentData.StageLink);
			FormParameters.Insert("KeyLot", CurrentData.KeyLot);
			FormParameters.Insert("ProductionOrder", OrderDocument);
		EndIf;
		
		OpenForm(
			"Report.ConnectedProductionStagesChart.ObjectForm",
			FormParameters,
			ThisObject,
			CurrentData.StageLink);
		
	Else
		
		CommonClient.MessageToUser(
			NStr("vi = 'Tạo báo cáo cho hàng đã chọn không khả dụng';
				|ru = 'Формирование отчета для выбранной строки недоступно';
				|en = 'Cannot generate the report for the selected line'; fa = 'Cannot generate the report for the selected line';
				|it = 'Формирование отчета для выбранной строки недоступно';
				|pl = 'Kształtowanie raportu dla wybranego wiersza nie jest dostępne';
				|tr = 'Seçili satır için raporun düzenlenmesi mevcut değildir'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StageResourceChart(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Dòng cấu trúc đơn hàng không được chọn';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Не выбрана строка структуры заказа';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		
	ElsIf CurrentData.RowType = StringTypeStructureStage() Or CurrentData.RowType = LineTypeStageDocument() Then
		
		FormParameters = New Structure;
		If CurrentData.RowType = LineTypeStageDocument() Then
			FormParameters.Insert("CommandParameter", CurrentData.StageLink);
		Else
			FormParameters.Insert("Stage", CurrentData.StageLink);
			FormParameters.Insert("KeyLot", CurrentData.KeyLot);
			FormParameters.Insert("ProductionOrder", OrderDocument);
		EndIf;
		
		OpenForm(
			"Report.ProductionStageResourceChart.Form",
			FormParameters,
			ThisObject,
			CurrentData.StageLink);
		
	Else
		
		CommonClient.MessageToUser(
			NStr("vi = 'Để tạo báo cáo, bạn phải chọn công đoạn sản xuất';
				|ru = 'Для формирования отчета необходимо выбрать этап производства';
				|en = 'To generate a report, select a production stage'; fa = 'To generate a report, select a production stage';
				|it = 'Для формирования отчета необходимо выбрать этап производства';
				|pl = 'Do tworzenia raportu należy wybrać etap produkcji';
				|tr = 'Raporun oluşturulması için üretim aşamasını seçmeniz gerekmektedir'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplaceBOR(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	RowData = ?(CurrentData.RowType = StringTypeStructureStage() Or CurrentData.RowType = LineTypeStageDocument(),
		CurrentData.GetParent(),
		CurrentData);
	
	Line1_3 = New Structure("ProductionOrder,Products,Characteristic,Warehouse,Purpose");
	FillPropertyValues(Line1_3, RowData);
	Line1_3.ProductionOrder = OrderDocument;
	
	If Not CheckPossibilityOfReplacingSpecification(RowData.RowType, Line1_3) Then
		TitleText = NStr("vi = 'Không thể thay thế bảng kê chi tiết.';
						|ru = 'Замена спецификации недоступна.';
						|en = 'Cannot replace the bill of materials.'; fa = 'Cannot replace the bill of materials.';
						|it = 'Impossibile sostituire la specifica.';
						|pl = 'Zmiana specyfikacji jest niedostępna.';
						|tr = 'Ürün reçetesi değişimi mevcut değildir.'");
		MessageText = NStr("vi = 'Không hỗ trợ thay thế bảng kê chi tiết được thiết lập từ trước trong công đoạn.';
							|ru = 'Замена предустановленной в этапе спецификации не поддерживается.';
							|en = 'Cannot replace the bill of materials predefined in the stage.'; fa = 'Cannot replace the bill of materials predefined in the stage.';
							|it = 'Cannot replace the bill of materials predefined in the stage.';
							|pl = 'Cannot replace the bill of materials predefined in the stage.';
							|tr = 'Önceden belirlenen ürün reçetelerinin bu aşamada değiştirilmesi desteklenmemektedir.'");
		ShowMessageBox(, MessageText,,TitleText);
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ReplaceBORCompletion", ThisObject, New Structure("RowData", Line1_3));
	
	DataOfSelectedRows = New Array;
	StructureOfData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
	StructureOfData.Products   = RowData.Products;
	StructureOfData.Characteristic = RowData.Characteristic;
	StructureOfData.UnderRepairProduct = RowData.UnderRepairProduct;
	StructureOfData.UnderRepairVariant = RowData.UnderRepairVariant;
	OrderData = GeneralPurposeTMServerCall.ObjectAttributesValues(OrderDocument, "Department, LineOfBusiness, EarliestStartDate");
	StructureOfData.ProductionStart      = OrderData.EarliestStartDate;
	StructureOfData.ProductionDispatcherBusinessUnit  = OrderData.Department;
	StructureOfData.LineOfBusiness = OrderData.LineOfBusiness;
	DataOfSelectedRows.Add(StructureOfData);
	
	If ProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingBillOfMaterialsForRepairWork();
	ElsIf ProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
		BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingBillOfMaterialsForReverseKitting();
	Else
		BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	EndIf;
	BOMSelectionParameters.Insert("ExcludeSpecification", CurrentData.BillOfMaterials);
	
	ProductDataManagementClient.OpenFormForSelectingSpecificationsFromListOfProducts(DataOfSelectedRows, BOMSelectionParameters, ThisObject, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ReplaceBORCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	ReplacementResult = ReplaceSpecificationOnServer(AdditionalParameters.RowData, ClosingResult);
	
	If Not ReplacementResult.HasErrors Then
		
		TimeConsumingOperation = Undefined;
		
		Action = "Fill";
		ExpectStructureCalculationAndPerformAction();
		
	Else
		ShowMessageBox(,NStr("vi = 'Không thể thay thế.';
							|ru = 'Не удалось выполнить замену.';
							|en = 'Cannot replace.'; fa = 'Cannot replace.';
							|it = 'Non è stato possibile effettuare la sostituzione.';
							|pl = 'Zamiana nie powiodła się.';
							|tr = 'Değişiklik yapılamadı.'"));
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReFillBySpecification(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.BillOfMaterials) Then
		ShowMessageBox(,NStr("vi = 'Không thể tính lại nguyên vật liệu, công lao động theo dòng được chọn.';
							|ru = 'Не удалось выполнить пересчет материалов, трудозатрат по выбранной строке.';
							|en = 'Cannot recalculate materials and labor costs for the selected line.'; fa = 'Cannot recalculate materials and labor costs for the selected line.';
							|it = 'Impossibile eseguire il ricalcolo dei materiali, costi di manodopera per la riga selezionata.';
							|pl = 'Nie udało się wykonać przeliczenia materiałów, nakładów pracy według wybranego wiersza.';
							|tr = 'Seçilen satıra göre malzemelerin, iş gücü maliyetlerinin yeniden hesaplanması gerçekleştirilemedi.'"));
		Return;
	EndIf;
	
	TimeConsumingOperation = Undefined;
	
	If CurrentData.RowType = LineTypeStageDocument() Then
		
		ShowUserNotification(
			ReFillBatchJobName(),,
			NStr("vi = 'Đã bắt đầu điền lại lô hàng theo bảng kê chi tiết.';
				|ru = 'Запущено перезаполнение партии по спецификации.';
				|en = 'Lot refilling by the BOM is started.'; fa = 'Lot refilling by the BOM is started.';
				|it = 'Ricompilazione del lotto in base alla specifica avviata.';
				|pl = 'Uruchomiono ponowne wypełnienie partii według specyfikacji.';
				|tr = 'Ürün reçetesine göre lotun yeniden doldurulması başladı.'"),
			PictureLib.Information32);
		RefillBatchAccordingToSpecificationServer(CurrentData.KeyLot);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("ReFillBatchAccordingToSpecificationInBackgroundEnd", ThisObject),
			IdleParameters);
		
	Else
		
		OrderStructureClient.StartRecalculatingOrderStructureAccordingToSpecification(CurrentData.BillOfMaterials, OrderDocument);
		
		Action = "Fill";
		ExpectStructureCalculationAndPerformAction();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeBatch(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	OpenForm(
		"DataProcessor.ProductionLotDivision.Form.Workplace",
		New Structure("ProductionLot, Stage", CurrentData.ProductionLot, CurrentData.StageLink),
		ThisObject,
		CurrentData.KeyLot);
	
EndProcedure

&AtClient
Procedure MoveFinishedProduct(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Не выбрана строка структуры заказа';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	FiltersStructure = New Structure("ProductionOrder, Products", OrderDocument, CurrentData.Products);
	FormParameters = New Structure("FiltersStructure", FiltersStructure);
	OpenForm("DataProcessor.GenerateProductionOrderRegisterRecords.Form.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure MoveToComponents(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Не выбрана строка структуры заказа';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	FiltersStructure = New Structure("ProductionOrder, BillOfMaterials", OrderDocument, CurrentData.BillOfMaterials);
	FormParameters = New Structure("FiltersStructure", FiltersStructure);
	OpenForm("DataProcessor.GenerateProductionOrderRegisterRecords.Form.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CreateAssignmentAdjustmentDocument(Command)
	
	CurrentData = Items.Tree.CurrentData;
	
	DataParameters = AssignmentMutualAdjustmentClient.AssignmentCounterAdjustmentParameters();
	
	AssignmentMutualAdjustmentClient.FillInParametersOfCounterAdjustmentOfAssignment(
		DataParameters, CurrentData, ThisObject);
	
	CounterAdjustmentData =
		AssignmentMutualAdjustmentServerCall.DestinationCounterAdjustmentData(DataParameters, UUID);
	
	CommandDetails = AssignmentMutualAdjustmentClient.CommandDetails(
						ThisObject, DataParameters, CounterAdjustmentData);
	
	GenerationByReferenceTMClient.OpenCounterAssignmentAdjustmentWizard(CommandDetails);
	
EndProcedure

&AtClient
Procedure GenerateReportDecodingStaffingContext(Command)
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenStaffingByLine(CurrentData);
	
EndProcedure

&AtClient
Procedure GenerateStages(Command)
	
	FiltersStructure = New Structure("ProductionOrder", OrderDocument);
	FormParameters = New Structure("FiltersStructure", FiltersStructure);
	OpenForm("DataProcessor.GeneratingProductionStages.Form.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure GenerateTransfers(Command)
	
	FiltersStructure = New Structure("ProductionOrder", OrderDocument);
	FormParameters = New Structure("FiltersStructure", FiltersStructure);
	OpenForm("DataProcessor.GenerateProductionOrderRegisterRecords.Form.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FormStagesByLine(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	FiltersStructure = New Structure;
	
	If CurrentData.RowType = LineTypeProduct()
		Or CurrentData.RowType = LineTypeSemiFinished()
		Or CurrentData.RowType = LineTypeMove()
		Or CurrentData.RowType = LineTypeDecryptionNomenclature() Then
		
		FiltersStructure.Insert("ProductionOrder", OrderDocument);
		FiltersStructure.Insert("Products", CurrentData.Products);
		FiltersStructure.Insert("BillOfMaterials", CurrentData.BillOfMaterials);
		
	ElsIf CurrentData.RowType = StringTypeStructureStage()
		Or CurrentData.RowType = LineTypeStageDocument() Then
		
		FiltersStructure.Insert("ProductionOrder", OrderDocument);
		FiltersStructure.Insert("Products", CurrentData.GetParent().Products);
		FiltersStructure.Insert("BillOfMaterials", CurrentData.GetParent().BillOfMaterials);
		
	ElsIf CurrentData.RowType = LineTypeLaunchOrder() Then
		
		FiltersStructure.Insert("ProductionOrder", CurrentData.LaunchOrder);
		
	EndIf;
	
	FormParameters = New Structure("FiltersStructure", FiltersStructure);
	OpenForm("DataProcessor.GeneratingProductionStages.Form.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	DeployEverythingOnClient(True);
	
EndProcedure

&AtClient
Procedure DeploySubordinates(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	DeployEverythingOnClient(True, CurrentData.GetID());
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	Queue = New Array;
	For Each String In Tree.GetItems() Do
		Queue.Add(String);
	EndDo;
	
	IndexOf = 0;
	While IndexOf <= Queue.UBound() Do
		For Each String In Queue[IndexOf].GetItems() Do
			Queue.Add(String);
		EndDo;
		IndexOf = IndexOf + 1;
	EndDo;
	
	For IndexOf = -Queue.UBound() To 0 Do
		If Items.Tree.Expanded(Queue[-IndexOf].GetID()) Then
			Items.Tree.Collapse(Queue[-IndexOf].GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure RecalculateOrderStructure(Command)
	
	If OrderDocument.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chọn đơn hàng sản xuất';
												|ru = 'Не выбран заказ на производство';
												|en = 'Production order is not selected'; fa = 'Production order is not selected';
												|it = 'Nessun ordine di produzione selezionato';
												|pl = 'Nie wybrano zlecenia produkcyjnego';
												|tr = 'Üretim emri seçilmedi'"),,"OrderDocument");
		Return;
	EndIf;
	
	Action = "Fill";
	OrderStructureClient.StartRecalculatingOrderStructure(OrderDocument);
	ExpectStructureCalculationAndPerformAction();
	
EndProcedure

&AtClient
Procedure CurCurrentStateOfSoftwareURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "StockAvailability" Then
		
		StandardProcessing = False;
		
		CurrentData = Items.Tree.CurrentData;
		
		If CurrentData = Undefined Then
			Return;
		EndIf;
		
		OpenProductBalancesAndAvailabilityReport(CurrentData.Products, CurrentData.Characteristic);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteBatchStages(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),
			,
			"Tree");
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"DeleteStagesQuestionEnd",
		ThisObject,
		CurrentData.KeyLot);
	
	ShowQueryBox(CallbackDescription,
		NStr("vi = 'Đặt dấu xóa chuỗi công đoạn?';
			|ru = 'Пометить на удаление цепочку этапов?';
			|en = 'Do you want to mark the stage chain for deletion?'; fa = 'Do you want to mark the stage chain for deletion?';
			|it = 'Пометить на удаление цепочку этапов?';
			|pl = 'Do you want to mark the stage chain for deletion?';
			|tr = 'Aşama zinciri silinmek üzere işaretlensin mi?'"),
		QuestionDialogMode.YesNo,,
		DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),,
			"Tree");
		Return;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RowID", CurrentData.GetID());
	ProcedureParameters.Insert("ProductionLot", CurrentData.ProductionLot);
	ProcedureParameters.Insert("Stage", CurrentData.StageLink);
	ProcedureParameters.Insert("Products", CurrentData.Products);
	ProcedureParameters.Insert("Characteristic", CurrentData.Characteristic);
	ProcedureParameters.Insert("Recipient", CurrentData.Warehouse);
	ProcedureParameters.Insert("Purpose", CurrentData.Purpose);
	
	CallbackDescription = New CallbackDescription(
		"SelectCancellationReasonCompletion",
		ThisObject,
		ProcedureParameters);
	
	ShowInputValue(
		CallbackDescription,,
		NStr("vi = 'Nguyên nhân hủy bỏ';
			|ru = 'Причина отмены';
			|en = 'Reason for cancellation'; fa = 'دلیل لغو';
			|it = 'Causa di annullamento';
			|pl = 'Przyczyna anulowania';
			|tr = 'İptal nedeni'"),
		Type("CatalogRef.ReasonsForProductionCancellation"));
	
EndProcedure

&AtClient
Procedure ChangeQuality(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),,
			"Tree");
		Return;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RowID", CurrentData.GetID());
	ProcedureParameters.Insert("ProductionLot", CurrentData.ProductionLot);
	ProcedureParameters.Insert("Stage", CurrentData.StageLink);
	ProcedureParameters.Insert("Products", CurrentData.Products);
	ProcedureParameters.Insert("Characteristic", CurrentData.Characteristic);
	ProcedureParameters.Insert("Recipient", CurrentData.Warehouse);
	ProcedureParameters.Insert("Purpose", CurrentData.Purpose);
	
	CallbackDescription = New CallbackDescription(
		"SelectionOfQualityGradationEnd",
		ThisObject,
		ProcedureParameters);
	
	ChoiceList = New ValueList;
	ChoiceList.Add(PredefinedValue("Enum.QualityLevels.NotUsable"));
	ChoiceList.Add(PredefinedValue("Enum.QualityLevels.SuitableToALimitedExtent"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("Ref", ChoiceList));
	
	OpenForm(
		"Enum.QualityLevels.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddWorks(Command)
	
	ClearMessages();
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData = Undefined Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn dòng cấu trúc đơn hàng';
				|ru = 'Не выбрана строка структуры заказа';
				|en = 'Order structure line is not selected'; fa = 'Order structure line is not selected';
				|it = 'Riga della struttura dell''ordine non selezionata';
				|pl = 'Nie wybrano wierszu struktury zamówienia';
				|tr = 'Sipariş yapısı satırı seçilmedi'"),,
			"Tree");
		Return;
	EndIf;
	
	ThisIsASemiFinishedProduct = CurrentData.GetParent().RowType <> LineTypeProduct();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RowID", CurrentData.GetID());
	ProcedureParameters.Insert("ThisIsASemiFinishedProduct", ThisIsASemiFinishedProduct);
	ProcedureParameters.Insert("Stage", CurrentData.StageLink);
	ProcedureParameters.Insert("KeyLot", CurrentData.KeyLot);
	
	CallbackDescription = New CallbackDescription(
		"SelectionOfWorksToAddEnd",
		ThisObject,
		ProcedureParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionLot", CurrentData.ProductionLot);
	FormParameters.Insert("Stage", CurrentData.StageLink);
	
	OpenForm(
		"DataProcessor.EditProductionStageSequence.Form.FormOfAddingWorks",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

#Region Fill

&AtServer
Procedure FillAtServer()
	
	// Fill out the report
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Lập báo cáo ""Cấu trúc đơn hàng sản xuất""';
			|ru = 'Формирование отчета ""Структура заказа на производство""';
			|en = 'Generate the ""Production order structure"" report'; fa = 'Generate the ""Production order structure"" report';
			|it = 'Formazione del report ""Struttura degli ordini di produzione""';
			|pl = 'Kształtowanie raportu ""Struktura zlecenia na produkcję""';
			|tr = '""Üretim Emri Yapısı"" raporunun düzenlenmesi'");
	
	ProcedureParameters = OrderTreeReadingParameters();
	
	If ThisIsSearchInStructure(ThisObject) Then
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
			"Reports.ProductionOrderStructureDynamic.BuildSearchTree",
			ProcedureParameters,
			ExecutionParameters);
		FilterIs_Specified = True;
	Else
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
			"Reports.ProductionOrderStructureDynamic.BuildOrderTree",
			ProcedureParameters,
			ExecutionParameters);
		FilterIs_Specified = False;
	EndIf;
	
	If TimeConsumingOperation.Status = "Running" Then
		StartAwaitingLongAction = True;
	Else
		ProcessResultFillInBackground(TimeConsumingOperation);
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	// Other
	BalanceTableOfCollateralState.Clear();
	
EndProcedure

&AtServer
Function OrderTreeReadingParameters()
	
	StagesSelectionOfAnalyst = New Structure;
	StagesSelectionOfAnalyst.Insert("Products", StagesSelectionNomenclature);
	StagesSelectionOfAnalyst.Insert("Characteristic", StagesSelectionCharacteristics);
	StagesSelectionOfAnalyst.Insert("Warehouse", StagesSelectionWarehouse);
	StagesSelectionOfAnalyst.Insert("Purpose", StagesSelectionAppointment);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("OrderDocument", OrderDocument);
	ProcedureParameters.Insert("ProcessType", ProcessType);
	ProcedureParameters.Insert("StagesShow", StagesShow);
	ProcedureParameters.Insert("ShowMovements", ShowMovements);
	ProcedureParameters.Insert("ShowContent", ShowContent);
	ProcedureParameters.Insert("ShowIssues", ShowIssues);
	ProcedureParameters.Insert("Purpose", PurposeSelection);
	ProcedureParameters.Insert("Stages", StagesOfSelection);
	ProcedureParameters.Insert("StagesOfAnalytics", StagesSelectionOfAnalyst);
	
	If ThisIsSearchInStructure(ThisObject) Then
		ProcedureParameters.Insert("Products", NomenclatureSelection);
		ProcedureParameters.Insert("Warehouse", WarehouseSelection);
	EndIf;
	
	Return ProcedureParameters;
	
EndFunction

&AtClient
Procedure FillInBackgroundEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		Tree.GetItems().Clear();
		Items.GroupPages.CurrentPage = Items.PageData;
	Else
		ProcessResultFillInBackground(Result);
		ExpandLines();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultFillInBackground(Result)
	
	If Result.Status = "Completed2" Then
		
		TreeRows = Tree.GetItems();
		TreeRows.Clear();
		ExpandedLines.Clear();
		
		DataTree = GetFromTempStorage(Result.ResultAddress);
		If DataTree.Rows.Count() > 0 Then
			If ThisIsSearchInStructure(ThisObject) Then
				FillTreeByRecursivelySearching(TreeRows, DataTree.Rows, True);
			Else
				FillTreeRecursively(TreeRows, DataTree.Rows);
				For Each String In TreeRows Do
					ExpandedLines.Add(String.GetID());
				EndDo;
			EndIf;
		EndIf;
		
		Items.GroupPages.CurrentPage = Items.PageData;
		
	Else
		
		Tree.GetItems().Clear();
		Items.GroupPages.CurrentPage = Items.PageData;
		
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
	EndIf;
	
	OrderStructureClientServer.DisplayStateOfStructureCalculation(
		Items,
		Documents.ProductionOrder2_2.OrderStructureCalculationProtocol(OrderDocument));
	
EndProcedure

&AtServer
Procedure FillTreeRecursively(TreeRows, StructureStrings)
	
	For Each String_Structure In StructureStrings Do
		
		NewRow = TreeRows.Add();
		FillPropertyValues(NewRow, String_Structure);
		
		If String_Structure.Rows.Count() > 0 Then
			FillTreeRecursively(NewRow.GetItems(), String_Structure.Rows);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillTreeByRecursivelySearching(TreeRows, StructureStrings, ExpandLines)
	
	For Each String_Structure In StructureStrings Do
		
		NewRow = TreeRows.Add();
		FillPropertyValues(NewRow, String_Structure);
		
		ExpandNode = ExpandLines
			And (Not NewRow.SearchString
				Or NewRow.KeyProducts = ProductSearchKey);
		
		If ExpandNode Then
			ExpandedLines.Add(NewRow.GetID());
		EndIf;
		
		If ValueIsFilled(ProductSearchKey)
				And NewRow.KeyProducts = ProductSearchKey Then
			CurrentRow = NewRow.GetID();
		ElsIf NewRow.SearchString
				And CurrentRow = -1 Then
			CurrentRow = NewRow.GetID();
		EndIf;
		
		If String_Structure.Rows.Count() > 0 Then
			FillTreeByRecursivelySearching(
				NewRow.GetItems(),
				String_Structure.Rows,
				ExpandLines And Not NewRow.SearchString);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ThisIsSearchInStructure(Form)
	
	Return Not(Form.NomenclatureSelection.IsEmpty()
		And Form.WarehouseSelection.IsEmpty());
	
EndFunction

#EndRegion

#Region FillInExpand

&AtServer
Procedure FillOutDeployOnServer(IDs)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Lập báo cáo ""Cấu trúc đơn hàng sản xuất""';
			|ru = 'Формирование отчета ""Структура заказа на производство""';
			|en = 'Generate the ""Production order structure"" report'; fa = 'Generate the ""Production order structure"" report';
			|it = 'Formazione del report ""Struttura degli ordini di produzione""';
			|pl = 'Kształtowanie raportu ""Struktura zlecenia na produkcję""';
			|tr = '""Üretim Emri Yapısı"" raporunun düzenlenmesi'");
		
	StagesSelectionOfAnalyst = New Structure;
	StagesSelectionOfAnalyst.Insert("Products", StagesSelectionNomenclature);
	StagesSelectionOfAnalyst.Insert("Characteristic", StagesSelectionCharacteristics);
	StagesSelectionOfAnalyst.Insert("Warehouse", StagesSelectionWarehouse);
	StagesSelectionOfAnalyst.Insert("Purpose", StagesSelectionAppointment);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("OrderDocument", OrderDocument);
	ProcedureParameters.Insert("ProcessType", ProcessType);
	ProcedureParameters.Insert("StagesShow", StagesShow);
	ProcedureParameters.Insert("ShowMovements", ShowMovements);
	ProcedureParameters.Insert("ShowContent", ShowContent);
	ProcedureParameters.Insert("ShowIssues", ShowIssues);
	ProcedureParameters.Insert("ExpandedLines", KeysOfExpandedStrings(IDs));
	ProcedureParameters.Insert("Purpose", PurposeSelection);
	ProcedureParameters.Insert("Stages", StagesOfSelection);
	ProcedureParameters.Insert("StagesOfAnalytics", StagesSelectionOfAnalyst);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Reports.ProductionOrderStructureDynamic.BuildTreeOfExpandedStrings",
		ProcedureParameters,
		ExecutionParameters);
	FilterIs_Specified = False;
	
	If TimeConsumingOperation.Status = "Running" Then
		StartAwaitingLongAction = True;
	Else
		ProcessResultFillInExpandInBackground(TimeConsumingOperation, IDs);
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillExpandInBackgroundEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		Tree.GetItems().Clear();
		Items.GroupPages.CurrentPage = Items.PageData;
	Else
		ProcessResultFillInExpandInBackground(Result, IdsOfExpandedRows());
		ExpandLines();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultFillInExpandInBackground(Result, IDs)
	
	If Result.Status = "Completed2" Then
		
		// Table of expanded rows
		ExpandRows = KeysOfExpandedStrings(IDs);
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products");
		TheStructureOfTheSearch.Insert("Characteristic");
		TheStructureOfTheSearch.Insert("Warehouse");
		TheStructureOfTheSearch.Insert("Purpose");
		TheStructureOfTheSearch.Insert("StageLink");
		
		// Cache the current row
		CurLineCache = Undefined;
		If Items.Tree.CurrentRow <> Undefined Then
			
			TreeRow = Tree.FindByID(Items.Tree.CurrentRow);
			
			CurLineCache = New Structure;
			CurLineCache.Insert("Products", TreeRow.Products);
			CurLineCache.Insert("Characteristic", TreeRow.Characteristic);
			CurLineCache.Insert("Warehouse", TreeRow.Warehouse);
			CurLineCache.Insert("Purpose", TreeRow.Purpose);
			CurLineCache.Insert("StageLink", TreeRow.StageLink);
			CurLineCache.Insert("LineNumber", TreeRow.LineNumber);
			CurLineCache.Insert("KeyProducts", TreeRow.KeyProducts);
			
		EndIf;
		
		// Cleaning Collections
		TreeRows = Tree.GetItems();
		TreeRows.Clear();
		ExpandedLines.Clear();
		
		// Filling in the tree
		DataTree = GetFromTempStorage(Result.ResultAddress);
		If DataTree.Rows.Count() > 0 Then
			
			FillExpandTreeRecursively(
				TreeRows,
				DataTree.Rows,
				ExpandRows,
				TheStructureOfTheSearch,
				CurLineCache);
			
			For Each String In TreeRows Do
				ExpandedLines.Add(String.GetID());
			EndDo;
			
		EndIf;
		
		Items.GroupPages.CurrentPage = Items.PageData;
		
	Else
		
		Tree.GetItems().Clear();
		Items.GroupPages.CurrentPage = Items.PageData;
		
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillExpandTreeRecursively(TreeRows, StructureStrings, ExpandRows, TheStructureOfTheSearch, CurLineCache)
	
	For Each String_Structure In StructureStrings Do
		
		NewRow = TreeRows.Add();
		FillPropertyValues(NewRow, String_Structure);
		
		If String_Structure.RowType = StringTypeStructureStage()
				Or String_Structure.RowType = LineTypeStageDocument() Then
			FillPropertyValues(TheStructureOfTheSearch, String_Structure.Parent,
				"Products, Characteristic, Warehouse, Purpose");
			TheStructureOfTheSearch.StageLink = String_Structure.StageLink;
		Else
			FillPropertyValues(TheStructureOfTheSearch, String_Structure);
		EndIf;
		
		If ExpandRows.FindRows(TheStructureOfTheSearch).UBound() <> -1 Then
			ExpandedLines.Add(NewRow.GetID());
		EndIf;
		
		If CurLineCache <> Undefined
				And NewRow.Products = CurLineCache.Products
				And NewRow.Characteristic = CurLineCache.Characteristic
				And NewRow.Warehouse = CurLineCache.Warehouse
				And NewRow.Purpose = CurLineCache.Purpose
				And NewRow.StageLink = CurLineCache.StageLink
				And NewRow.LineNumber = CurLineCache.LineNumber
				And NewRow.KeyProducts = CurLineCache.KeyProducts Then
			CurrentRow = NewRow.GetID();
			CurLineCache = Undefined;
		EndIf;
		
		If String_Structure.Rows.Count() > 0 Then
			FillExpandTreeRecursively(
				NewRow.GetItems(),
				String_Structure.Rows,
				ExpandRows,
				TheStructureOfTheSearch,
				CurLineCache);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function IdsOfExpandedRows()
	
	Result = New Array;
	
	Queue = New Array;
	For Each String In Tree.GetItems() Do
		If Items.Tree.Expanded(String.GetID()) Then
			Queue.Add(String);
		EndIf;
	EndDo;
	While Queue.UBound() <> -1 Do
		For Each String In Queue[0].GetItems() Do
			If Items.Tree.Expanded(String.GetID()) Then
				Result.Add(String.GetID());
				Queue.Add(String);
			EndIf;
		EndDo;
		Queue.Delete(0);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function KeysOfExpandedStrings(IDs)
	
	ExpandRows = New ValueTable;
	ExpandRows.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	ExpandRows.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ExpandRows.Columns.Add("Warehouse", New TypeDescription("CatalogRef.BusinessStructure,CatalogRef.Warehouses"));
	ExpandRows.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	ExpandRows.Columns.Add("StageLink", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	
	For Each Id In IDs Do
		
		TreeRow = Tree.FindByID(Id);
		
		NewRow = ExpandRows.Add();
		If TreeRow.RowType = StringTypeStructureStage()
				Or TreeRow.RowType = LineTypeStageDocument() Then
			FillPropertyValues(NewRow, TreeRow.GetParent(),
				"Products, Characteristic, Warehouse, Purpose");
			NewRow.StageLink = TreeRow.StageLink;
		Else
			FillPropertyValues(NewRow, TreeRow);
		EndIf;
		
	EndDo;
	
	ExpandRows.Indexes.Add("Products, Characteristic, Warehouse, Purpose, StageLink");
	
	Return ExpandRows;
	
EndFunction

#EndRegion

#Region ExpandAll

&AtClient
Procedure ShowQuestionExpandAllContinueOutput(RowID)
		
	ShowQueryBox(
		New CallbackDescription("QuestionExpandEverythingContinueOutputEnd", ThisObject, RowID),
		StrTemplate(NStr("vi = 'Hiển thị %1 phần tử. Tiếp tục hiển thị?';
						|ru = 'Выведено %1 элементов. Продолжить вывод?';
						|en = '%1 items are displayed. Continue?'; fa = '%1 items are displayed. Continue?';
						|it = 'Visualizzati %1 elementi. Continuare la visualizzazione?';
						|pl = 'Wyprowadzono %1 elementów. Kontynuować wyprowadzenie?';
						|tr = '""%1"" öğe çıkarıldı. Çıkarmaya devam edilsin mi?'"), SamplePortionSize),
		QuestionDialogMode.YesNo,,
		DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure QuestionExpandEverythingContinueOutputEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		DeployEverythingOnClient(False, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeployEverythingOnClient(PortionSelection, RowID = Undefined)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Action = "ExpandAll";
	ActionParameters = New Structure;
	ActionParameters.Insert("PortionSelection", PortionSelection);
	ActionParameters.Insert("RowID", RowID);
	
	ExpectStructureCalculationAndPerformAction();
	
EndProcedure

&AtServer
Procedure DeployEverythingOnServer(PortionSelection, RowID)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	Nodes = New Map;
	ExpandedLines.Clear();
	
	Queue = New Array;
	
	If RowID = Undefined Then
		
		For Each TreeRow In Tree.GetItems() Do
			Queue.Add(TreeRow);
			ExpandedLines.Add(TreeRow.GetID());
		EndDo;
		
	Else
		
		TreeRow = Tree.FindByID(RowID);
				
		If TreeRow.FinishTree Then
			PartyKeys = New Array;
			For Each String In TreeRow.GetItems() Do
				PartyKeys.Add(String.KeyLot);
			EndDo;
			Nodes.Insert(RowID,
				New Structure("PartyKeys, Stage", PartyKeys, TreeRow.StageLink));
		Else
			Queue.Add(TreeRow);
			ExpandedLines.Add(RowID);
		EndIf;
		
	EndIf;
	
	While Queue.UBound() <> -1 Do
		For Each TreeRow In Queue[0].GetItems() Do
			
			If TreeRow.FinishTree Then
				PartyKeys = New Array;
				For Each String In TreeRow.GetItems() Do
					PartyKeys.Add(String.KeyLot);
				EndDo;
				Nodes.Insert(TreeRow.GetID(),
					New Structure("PartyKeys, Stage", PartyKeys, TreeRow.StageLink));
			Else
				Queue.Add(TreeRow);
				ExpandedLines.Add(TreeRow.GetID());
			EndIf;
			
		EndDo;
		Queue.Delete(0);
	EndDo;
	
	If Nodes.Count() = 0 Then
		Return;
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Lập báo cáo ""Cấu trúc đơn hàng sản xuất""';
			|ru = 'Формирование отчета ""Структура заказа на производство""';
			|en = 'Generate the ""Production order structure"" report'; fa = 'Generate the ""Production order structure"" report';
			|it = 'Formazione del report ""Struttura degli ordini di produzione""';
			|pl = 'Kształtowanie raportu ""Struktura zlecenia na produkcję""';
			|tr = '""Üretim Emri Yapısı"" raporunun düzenlenmesi'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("OrderDocument", OrderDocument);
	ProcedureParameters.Insert("ProcessType", ProcessType);
	ProcedureParameters.Insert("StagesShow", StagesShow);
	ProcedureParameters.Insert("ShowMovements", ShowMovements);
	ProcedureParameters.Insert("ShowContent", ShowContent);
	ProcedureParameters.Insert("ShowIssues", ShowIssues);
	ProcedureParameters.Insert("Nodes", Nodes);
	ProcedureParameters.Insert("PortionSelection", PortionSelection);
	ProcedureParameters.Insert("Purpose", PurposeSelection);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Reports.ProductionOrderStructureDynamic.Expand_AllLevels",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		StartAwaitingLongAction = True;
	Else
		ProcessResultExpandEverythingInBackground(TimeConsumingOperation, RowID);
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandEverythingInBackgroundEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result = Undefined Then
		Items.GroupPages.CurrentPage = Items.PageData;
	Else
		ProcessResultExpandEverythingInBackground(Result, AdditionalParameters);
		ExpandLines();
		If ContinueOutput Then
			ShowQuestionExpandAllContinueOutput(AdditionalParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultExpandEverythingInBackground(Result, RowID)
	
	Items.GroupPages.CurrentPage = Items.PageData;
	
	ContinueOutput = False;
	
	If Result.Status = "Completed2" Then
		
		ResultOfFormation = GetFromTempStorage(Result.ResultAddress);
		
		Nodes = ResultOfFormation.Nodes;
		For Each KeyAndValue In Nodes Do
			TreeRow = Tree.FindByID(KeyAndValue.Key);
			If TreeRow <> Undefined Then
				Rows = TreeRow.GetItems();
				For IndexOf = -Rows.Count()+1 To 0 Do
					String = Rows[-IndexOf];
					If String.RowType = RowTypeInternal() Then
						Rows.Delete(-IndexOf);
					EndIf;
				EndDo;
				TreeRow.FinishTree = False;
				FillTreeRecursively(Rows, KeyAndValue.Value.Rows);
			EndIf;
		EndDo;
		
		ContinueOutput = Not ResultOfFormation.AllDataIsSelected;
		
		ExpandedLines.Clear();
		Queue = New Array;
		If RowID = Undefined Then
			For Each String In Tree.GetItems() Do
				Queue.Add(String);
			EndDo;
		Else
			String = Tree.FindByID(RowID);
			If String <> Undefined Then
				Queue.Add(String);
			EndIf;
		EndIf;
		While Queue.UBound() <> -1 Do
			If Not Queue[0].FinishTree Then
				ExpandedLines.Add(Queue[0].GetID());
				For Each String In Queue[0].GetItems() Do
					Queue.Add(String);
				EndDo;
			EndIf;
			Queue.Delete(0);
		EndDo;
		
	Else
		
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ReplacingSpecification

&AtServerNoContext
Function CheckPossibilityOfReplacingSpecification(Val RowType, Val RowData)
	
	If RowType = LineTypeProduct() Then
		
		Return True;
		
	EndIf;
	
	If RowType = LineTypeSemiFinished() And OrderStructureInternal.ReplacementOfSpecificationInOrderStructureIsAllowed(RowData) Then
		
		Return True;
		
	EndIf;

	Return False;
	
EndFunction

&AtServerNoContext
Function ReplaceSpecificationOnServer(Val RowData, Val BillOfMaterials)
	
	ReplacementData = Documents.ProductionOrder2_2.SpecificationReplacementData();
	
	Replacement = ReplacementData.Add();
	FillPropertyValues(Replacement, RowData);
	Replacement.BillOfMaterials = BillOfMaterials;
	
	ReplacementResult = Documents.ProductionOrder2_2.ReplaceSpecificationsWithoutControl(ReplacementData);
	
	Return ReplacementResult;
	
EndFunction

#EndRegion

#Region Constants

&AtClientAtServerNoContext
Function LineTypeProduct()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeSemiFinished()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function StringTypeStructureStage()
	
	Return 3;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeMove()
	
	Return 4;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeStageDocument()
	
	Return 5;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeLaunchOrder()
	
	Return 6;
	
EndFunction

&AtClientAtServerNoContext
Function RowTypeInternal()
	
	Return 7;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeMaterial()
	
	Return 8;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeDecryptionNomenclature()
	
	Return 9;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeIssue()
	
	Return 10;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeInformation()
	
	Return 11;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure FillInDetailsForOrder()
	
	If OrderDocument.IsEmpty() Then
		ProcessType = Undefined;
		OrderStatus = Undefined;
		OrderPresentation = "";
	Else
		OrderData = Common.ObjectAttributesValues(OrderDocument,
			"Number, Date, ProductionProcessType, Status");
		
		ProcessType = OrderData.ProductionProcessType;
		OrderStatus = OrderData.Status;
		OrderPresentation = Documents.ProductionOrder2_2.OrderPresentation(OrderDocument, "", OrderData);
	EndIf;
	
EndProcedure

// Configure dependent form elements.
// 
// Parameters:
//  Form - ClientApplicationForm
//  AttributesList - String - list of Bank details
//
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items; // FormAllItems
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize
		Or AttributesStructure1.Property("OrderDocument") Then
		
		Items.ShowIssuesDetails.Visible = 
			Form.ProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM")
			Or Form.ProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly");
		
		ChartDatesVisibility = 
			Form.ProcessType <> PredefinedValue("Enum.ProductionProcessTypes.Disassembly")
			Or Form.TheProductionScheduleIsUsed;
		Items.Begin.Visible = ChartDatesVisibility;
		Items.Ending.Visible = ChartDatesVisibility;
		
		If Form.ThisIsDecryptionMode Then
			Form.Title = StrTemplate(NStr("vi = 'Diễn giải các dòng trong cấu trúc đơn hàng %1';
											|ru = 'Расшифровка строки структуры заказа %1';
											|en = 'Drill down the line of the %1 order structure'; fa = 'Drill down the line of the %1 order structure';
											|it = 'Расшифровка строки структуры заказа %1';
											|pl = 'Drill down the line of the %1 order structure';
											|tr = '%1 sipariş yapısı satırının detaylandırılması'"), Form.OrderPresentation);
		ElsIf Form.OrderDocument.IsEmpty() Then
			Form.Title = NStr("vi = 'Cơ cấu đặt hàng sản xuất';
								|ru = 'Структура заказа на производство';
								|en = 'Production order structure'; fa = 'ساختار سفارش تولید';
								|it = 'Struttura dell''ordine di produzione';
								|pl = 'Struktura zamówienia produkcji';
								|tr = 'Üretim emri yapısı'");
		Else
			Form.Title = StrTemplate(NStr("vi = 'Cấu trúc đơn hàng %1';
											|ru = 'Структура заказа %1';
											|en = '%1 order structure'; fa = '%1 order structure';
											|it = 'Структура заказа %1';
											|pl = '%1 order structure';
											|tr = '%1 sipariş yapısı'"), Form.OrderPresentation);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ActionsONChangingDetailTag()
	
	MarkDetailButtons();	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ShouldSaveSettings();
	
	Action = "Fill";
	ExpectStructureCalculationAndPerformAction();

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	TypesOfFirstLevelStrings = New ValueList;
	TypesOfFirstLevelStrings.Add(LineTypeProduct());
	TypesOfFirstLevelStrings.Add(LineTypeDecryptionNomenclature());
	
	TypesOfStringsStages = New ValueList();
	TypesOfStringsStages.Add(LineTypeStageDocument());
	TypesOfStringsStages.Add(StringTypeStructureStage());
	
	RowTypesItem = New ValueList; // Lines with the Issue type have separate rules
	RowTypesItem.Add(LineTypeProduct());
	RowTypesItem.Add(LineTypeDecryptionNomenclature());
	RowTypesItem.Add(LineTypeSemiFinished());
	RowTypesItem.Add(LineTypeMove());
	RowTypesItem.Add(LineTypeMaterial());
	
	#Region HidePurposeOfSemiFinishedProduct
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Purpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfFirstLevelStrings;
	
	Item.Appearance.SetParameterValue("Show", False);
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region HideImagesInRows
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PictureNumber.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfFirstLevelStrings;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeInformation();
	
	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
		
	#Region FontProducts
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Tree.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfFirstLevelStrings;
	
	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
	#EndRegion
	
	#Region LinePresentation
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PictureNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LinePresentation.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Purpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeLaunchOrder();
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfHyperlinkString.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = LineTypeLaunchOrder();
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region ProductionByThirdParty
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Done.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Launched.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Left.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfStringsStages;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
	#Region MultipleWarehouses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Warehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WarehouseDivision.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.MultipleWarehouses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<nhiều kho>';
													|ru = '<несколько складов>';
													|en = '<several warehouses>'; fa = '<several warehouses>';
													|it = '<alcuni magazzini>';
													|pl = '<kilka magazynów>';
													|tr = '<birden fazla ambar>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	#EndRegion
	
	#Region SupplyIsRequired
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Supplied.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SecuredInterest.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.SupplyIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
	#Region MultipleSpecifications
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.MultipleSpecifications");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<nhiều bảng kê chi tiết>';
													|ru = '<несколько спецификаций>';
													|en = '<several bills of materials>'; fa = '<several bills of materials>';
													|it = '<alcune specifiche>';
													|pl = '<kilka specyfikacji>';
													|tr = '<birden fazla ürün reçetesi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	#EndRegion
	
	#Region DesiredDateIsNotFilledIn
	
	TypesOfStrings = New ValueList();
	TypesOfStrings.Add(LineTypeStageDocument());
	TypesOfStrings.Add(StringTypeStructureStage());
	TypesOfStrings.Add(LineTypeIssue());
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.DesiredDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfStrings;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
	#Region LackOfSchedule
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.DesiredDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = RowTypesItem;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.DesiredDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Begin.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = RowTypesItem;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfStringsStages;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeIssue();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.Begin");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Ending.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = RowTypesItem;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfStringsStages;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeIssue();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.Ending");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'tùy chỉnh dữ liệu';
													|ru = 'н/д';
													|en = 'n/a'; fa = 'ناموجود';
													|it = 'н/д';
													|pl = 'n/a';
													|tr = 'yok'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	
	#EndRegion
	
	#Region NotProvide
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Launched.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.NotProvide");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	#EndRegion
	
	#Region Canceled
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Tree.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.StrikethroughFont);
	
	#EndRegion
	
	#Region InformationBar
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LinePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeInformation();
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	Settings = Common.CommonSettingsStorageLoad("Report.ProductionOrderStructureDynamic", "");
	
	If Settings <> Undefined Then
		Settings.Property("StagesShow", StagesShow);
		Settings.Property("ShowMovements", ShowMovements);
		Settings.Property("ShowContent", ShowContent);
		Settings.Property("ShowIssues", ShowIssues);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldSaveSettings()
	
	Settings = New Structure;
	Settings.Insert("StagesShow", StagesShow);
	Settings.Insert("ShowMovements", ShowMovements);
	Settings.Insert("ShowContent", ShowContent);
	Settings.Insert("ShowIssues", ShowIssues);
	
	SaveSettingsAtServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(Settings)
	
	Common.CommonSettingsStorageSave("Report.ProductionOrderStructureDynamic", "", Settings);
	
EndProcedure

&AtServer
Procedure FinishTree(PartyKeys, Stage, RowID)
	
	ProcedureParameters = ParametersForReadingTreeOfSemiFinishedProducts();
	
	Result = Reports.ProductionOrderStructureDynamic.TreeOfSemiFinishedProducts(
		OrderDocument, PartyKeys, Stage, ProcedureParameters, PurposeSelection);
	
	FillTreeRecursively(
		Tree.FindByID(RowID).GetItems(),
		Result.Rows);
	
	ExpandedLines.Clear();
	ExpandedLines.Add(RowID);
	
EndProcedure

&AtServer
Function ParametersForReadingTreeOfSemiFinishedProducts()
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ProcessType", ProcessType);
	ProcedureParameters.Insert("StagesShow", StagesShow);
	ProcedureParameters.Insert("ShowMovements", ShowMovements);
	ProcedureParameters.Insert("ShowContent", ShowContent);
	ProcedureParameters.Insert("ShowIssues", ShowIssues);
	
	Return ProcedureParameters;
	
EndFunction

&AtClient
Procedure ExpandLines()
	
	For Each String In ExpandedLines Do
		If Not Items.Tree.Expanded(String.Value) Then
			Items.Tree.Expand(String.Value, False);
		EndIf;
	EndDo;
	ExpandedLines.Clear();
	
	If CurrentRow <> -1 Then
		Items.Tree.CurrentRow = CurrentRow;
		CurrentRow = -1;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpectStructureCalculationAndPerformAction() Export
	
	Result = StartExecutionOfAction();
	
	If Result.ActionStarted Then
		
		WaitingForStructureCalculation = Undefined;
		
		If StartAwaitingLongAction Then
			ProcedureName = "";
			If Action = "Fill" Then
				ProcedureName = "FillInBackgroundEnd";
			ElsIf Action = "FillInExpand" Then
				ProcedureName = "FillExpandInBackgroundEnd";
			ElsIf Action = "ExpandAll" Then
				ProcedureName = "ExpandEverythingInBackgroundEnd";
			EndIf;
			AdditionalParameters = ?(Action = "ExpandAll", ActionParameters.RowID, Undefined);
			StartAwaitingLongAction(ProcedureName, AdditionalParameters);
		Else
			Items.GroupPages.CurrentPage = Items.PageData;
			ExpandLines();
		EndIf;
		
		If Action = "ExpandAll" And ContinueOutput Then
			DeployEverythingOnClient(False, ActionParameters.RowID);
		EndIf;
		
	ElsIf OrderStructureClientServer.ExpectEndOfOrderStructureCalculation(
		Result.CalculationProtocol.State, Result.CalculationProtocol.StateCodes) Then
		
		If WaitingForStructureCalculation = Undefined Then
			WaitingForStructureCalculation = New Structure("Interval", 1);
			Items.GroupPages.CurrentPage = Items.TimeConsumingOperationPage;
			Items.MessageDecoration.Title = NStr("vi = 'Cấu trúc được tính toán';
												|ru = 'Структура рассчитывается';
												|en = 'Structure is calculated'; fa = 'Structure is calculated';
												|it = 'Structure is calculated';
												|pl = 'Structure is calculated';
												|tr = 'Yapı hesaplanıyor'");
		Else
			WaitingForStructureCalculation.Interval = ?(WaitingForStructureCalculation.Interval * 1.4 < 15,
				WaitingForStructureCalculation.Interval * 1.4,
				15);
		EndIf;
		
		AttachIdleHandler("ExpectStructureCalculationAndPerformAction", WaitingForStructureCalculation.Interval, True);
		
	Else
		
		WaitingForStructureCalculation = Undefined;
		
		Tree.GetItems().Clear();
		Items.GroupPages.CurrentPage = Items.PageData;
		
		OrderStructureClientServer.DisplayStateOfStructureCalculation(Items, Result.CalculationProtocol);
		
	EndIf;
	
EndProcedure

&AtServer
Function StartExecutionOfAction()
	
	If FillInDetailsForOrder Then
		FillInDetailsForOrder();
		FillInDetailsForOrder = False;
	EndIf;
	
	ActionStarted = False;
	
	CalculationProtocol = Documents.ProductionOrder2_2.OrderStructureCalculationProtocol(OrderDocument);
	StructureIsCalculated = CalculationProtocol.State = CalculationProtocol.StateCodes.Calculated;
	
	TheScheduleIsCalculated = False;
	If Not StructureIsCalculated Then
		QueryText =
			"SELECT
			|	Schedule.ProductionOrder AS ProductionOrder
			|FROM
			|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
			|WHERE
			|	Schedule.ProductionOrder = &ProductionOrder
			|	AND Schedule.KeyLot = &EmptyLinkKey
			|	AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
			|	AND Schedule.ScheduleStatus = 0";
		ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
		
		Query = New Query(QueryText);
		Query.SetParameter("ProductionOrder", OrderDocument);
		Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
		TheScheduleIsCalculated = Not Query.Execute().IsEmpty();
	EndIf;
	
	If StructureIsCalculated
		Or TheScheduleIsCalculated
		Or OrderStatus = Enums.ProductionOrderStatuses2_2.Closed Then
		
		If Action = "Fill" Then
			FillAtServer();
		ElsIf Action = "FillInExpand" Then
			FillOutDeployOnServer(ActionParameters.RowsIDs);
		ElsIf Action = "ExpandAll" Then
			DeployEverythingOnServer(ActionParameters.PortionSelection, ActionParameters.RowID);
		EndIf;
		
		ActionStarted = True;
		
	EndIf;
	
	Return New Structure("ActionStarted, CalculationProtocol", ActionStarted, CalculationProtocol);
	
EndFunction

&AtClient
Procedure StartAwaitingLongAction(ProcedureName, AdditionalParameters = Undefined)
	
	CallbackOnCompletion = New CallbackDescription(ProcedureName, ThisObject, AdditionalParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		CallbackOnCompletion,
		IdleParameters);
	
	Items.GroupPages.CurrentPage = Items.TimeConsumingOperationPage;
	Items.MessageDecoration.Title = NStr("vi = 'Báo cáo được lập';
										|ru = 'Отчет формируется';
										|en = 'The report is being generated'; fa = 'گزارش در حال تولید است';
										|it = 'Il report è in processo di generazione';
										|pl = 'Trwa tworzenie sprawozdania';
										|tr = 'Rapor oluşturuluyor'");
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServerNoContext
Function ObjectAttributeValue(Ref, AttributeName)
	
	Return Common.ObjectAttributeValue(Ref, AttributeName);
	
EndFunction

&AtClient
Procedure OpenProductBalancesAndAvailabilityReport(
			Products = Undefined, Characteristic = Undefined, VariantKey = Undefined)
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	
	If VariantKey <> Undefined Then
		FormParameters.Insert("VariantKey", VariantKey);
	EndIf;
	
	FormParameters.Insert("Filter", New Structure);
	
	FormParameters.Filter.Insert("ShowSeparateProducts", True);
	
	If Products <> Undefined Then
		FormParameters.Filter.Insert("Products", Products);
	EndIf;
	
	If Characteristic <> Undefined Then
		FormParameters.Filter.Insert("Characteristic", Characteristic);
	EndIf;
	
	OpenForm("Report.StockAvailability.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FillInCurStateOfSoftware() Export
	
	CurrentData = Items.Tree.CurrentData;
	
	If CurrentData <> Undefined
		And (CurrentData.RowType = LineTypeMaterial()
			Or CurrentData.RowType = LineTypeSemiFinished()) Then
		DetailsParameters = New Structure;
		DetailsParameters.Insert("Products");
		DetailsParameters.Insert("Characteristic");
		DetailsParameters.Insert("Warehouse");
		DetailsParameters.Insert("Purpose");
		DetailsParameters.Insert("KeyProducts");
		DetailsParameters.Insert("KeyLot");
		
		FillPropertyValues(DetailsParameters, CurrentData);
		
		FoundRows = BalanceTableOfCollateralState.FindRows(DetailsParameters);
		If FoundRows.Count() > 0 Then
			DecryptionString = FoundRows[0];
		Else
			
			DetailsParameters.KeyLot =
				CommonClient.CopyRecursive(CurrentData.ProvidingParty, False);
			
			DecryptionString = DecryptionDataStateOfSoftware(DetailsParameters);
			
			TableRow = BalanceTableOfCollateralState.Add();
			FillPropertyValues(TableRow, DecryptionString);
			FillPropertyValues(TableRow, DetailsParameters,, "KeyLot");
			TableRow.KeyLot = CurrentData.KeyLot;
			
			If BalanceTableOfCollateralState.Count() > 15 Then
				BalanceTableOfCollateralState.Delete(0);
			EndIf;
			
		EndIf;
		
		CurCurrentStateOfSoftware = CurCurrentStateOfSoftware(CurrentData, DecryptionString);
	Else
		CurCurrentStateOfSoftware = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Function CurCurrentStateOfSoftware(RowData, DecryptionString)
	
	BoldFont = New Font(Items.CurCurrentStateOfSoftware.Font,,, True);
	
	RepresentationOfUnit = TrimAll(RowData.UnitOfMeasure);
	
	DecryptionArray = New Array;
	
	//1. In the current warehouse
	DecryptionArray.Add(NStr("vi = 'Trong kho hiện tại:';
							|ru = 'На текущем складе:';
							|en = 'In the current warehouse:'; fa = 'در انبار جاری:';
							|it = 'Nel magazzino corrente:';
							|pl = 'W bieżącym magazynie:';
							|tr = 'Mevcut ambarda:'"));
	
	If DecryptionString.CurrentWarehouseIsAvailable Then
		
		RepresentationQuantity = StrTemplate(
									NStr("vi = ' %1 %2';
										|ru = ' %1 %2';
										|en = ' %1 %2'; fa = ' %1 %2';
										|it = ' %1 %2';
										|pl = ' %1 %2';
										|tr = ' %1 %2'"),
									Format(DecryptionString.InCurWarehouse, "NZ=0; NG=;"),
									RepresentationOfUnit);
		DecryptionArray.Add(New FormattedString(RepresentationQuantity, BoldFont));
		
		//
		If DecryptionString.CurWarehouseIsFreeOfSurplus > 0 Then
		
			DecryptionArray.Add(NStr("vi = ', trong đó hàng thừa:';
									|ru = ', в т.ч. излишек:';
									|en = 'including the surplus:'; fa = 'including the surplus:';
									|it = ', comprese le eccedenze:';
									|pl = ', w tym nadwyżka:';
									|tr = ', fazlalık dahil:'"));
			
			RepresentationQuantity = StrTemplate(
										NStr("vi = ' %1 %2';
											|ru = ' %1 %2';
											|en = ' %1 %2'; fa = ' %1 %2';
											|it = ' %1 %2';
											|pl = ' %1 %2';
											|tr = ' %1 %2'"),
										Format(DecryptionString.CurWarehouseIsFreeOfSurplus, "NZ=0; NG=;"),
										RepresentationOfUnit);
			DecryptionArray.Add(New FormattedString(RepresentationQuantity, BoldFont));
			
		EndIf;
		
	Else
		
		DecryptionArray.Add(New FormattedString(NStr("vi = ' không có truy cập';
													|ru = ' нет доступа';
													|en = ' no access'; fa = ' no access';
													|it = ' no access';
													|pl = ' no access';
													|tr = ' izin yok'"), BoldFont));
		
	EndIf;
	
	//2. In other warehouses
	If DecryptionString.InOtherWarehouses > 0 Then
		
		DecryptionArray.Add(NStr("vi = ', trong các kho khả dụng khác:';
								|ru = ', на других доступных складах:';
								|en = ', at other available warehouses:'; fa = ', at other available warehouses:';
								|it = ', at other available warehouses:';
								|pl = ', at other available warehouses:';
								|tr = ', başka müsait ambarlarda:'"));
		
		RepresentationQuantity = StrTemplate(
									NStr("vi = ' %1 %2';
										|ru = ' %1 %2';
										|en = ' %1 %2'; fa = ' %1 %2';
										|it = ' %1 %2';
										|pl = ' %1 %2';
										|tr = ' %1 %2'"),
									Format(DecryptionString.InOtherWarehouses, "NG=;"),
									RepresentationOfUnit);
		DecryptionArray.Add(New FormattedString(RepresentationQuantity, BoldFont));
	
		//
		If DecryptionString.ThereIsSurplusInOtherWarehouses > 0 Then
	
			DecryptionArray.Add(NStr("vi = ', trong đó hàng thừa:';
									|ru = ', в т.ч. излишек:';
									|en = 'including the surplus:'; fa = 'including the surplus:';
									|it = ', comprese le eccedenze:';
									|pl = ', w tym nadwyżka:';
									|tr = ', fazlalık dahil:'"));
			
			RepresentationQuantity = StrTemplate(
										NStr("vi = ' %1 %2';
											|ru = ' %1 %2';
											|en = ' %1 %2'; fa = ' %1 %2';
											|it = ' %1 %2';
											|pl = ' %1 %2';
											|tr = ' %1 %2'"),
										Format(DecryptionString.ThereIsSurplusInOtherWarehouses, "NZ=0; NG=;"),
										RepresentationOfUnit);
			DecryptionArray.Add(New FormattedString(RepresentationQuantity, BoldFont));
			
		EndIf;
		
	EndIf;
	
	Return New FormattedString(DecryptionArray,,,, "StockAvailability");
	
EndFunction

&AtServerNoContext
Function DecryptionDataStateOfSoftware(DetailsParameters)
	
	DecryptionResult_ = New Structure;
	DecryptionResult_.Insert("InCurWarehouse",                0);
	DecryptionResult_.Insert("CurWarehouseIsFreeOfSurplus", 0);
	DecryptionResult_.Insert("InOtherWarehouses",                0);
	DecryptionResult_.Insert("ThereIsSurplusInOtherWarehouses", 0);
	DecryptionResult_.Insert(
		"CurrentWarehouseIsAvailable",
		AccessManagement.ReadingAllowed(DetailsParameters.Warehouse));
	
	Query = New Query;
	Query.Text = Reports.ProductionOrderStructureDynamic.QueryTextBalancesForOtherAssignmentsInQuantitativeTerms();
	
	For Each DetailsParameter In DetailsParameters Do
		Query.SetParameter(DetailsParameter.Key, DetailsParameter.Value);
	EndDo;
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		
		FillPropertyValues(DecryptionResult_, Selection);
		
	EndIf;
	
	Return DecryptionResult_;
	
EndFunction

&AtServer
Procedure RefillBatchAccordingToSpecificationServer(KeyLot)
	
	BatchTable_ = New ValueTable;
	BatchTable_.Columns.Add("ProductionLot", New TypeDescription("CatalogRef.ProductionLots"));
	BatchTable_.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	
	NewRow = BatchTable_.Add();
	NewRow.ProductionLot = Catalogs.ProductionLots.GetRef(KeyLot);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Lots", BatchTable_);
	ProcedureParameters.Insert("FormIdentifier", UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = ReFillBatchJobName();
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionStage2_2.ReFillInBatchesInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ReFillBatchAccordingToSpecificationInBackgroundEnd(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ResultStructure = ProcessResultOfBatchReFillingAccordingToSpecification(Result);
		If ResultStructure.Cancel Then
			ResultsArray = ResultStructure.ResultsArray;
			If ResultsArray.Count() = 1 And ValueIsFilled(ResultsArray[0].Messages) Then
				MessageText = ResultsArray[0].Messages[0];
			Else
				MessageText = NStr("vi = 'Khi thực hiện giao dịch, đã xảy ra lỗi. Chi tiết xem trong nhật ký sự kiện.';
									|ru = 'При выполнении операции возникли ошибки. Подробности см. в журнале регистрации.';
									|en = 'Errors occurred when executing the operation. For more information, see the event log.'; fa = 'Errors occurred when executing the operation. For more information, see the event log.';
									|it = 'Si è verificato un errore durante l''esecuzione dell''operazione. Vedere il registro per i dettagli.';
									|pl = 'Podczas wykonania operacji wystąpiły błędy. Szczegóły patrz w dzienniku rejestracji.';
									|tr = 'İşlem gerçekleştirilirken hatalar oluştu. Ayrıntılar için olay günlüğüne bakın.'");
			EndIf;
			ShowUserNotification(ReFillBatchJobName(),, MessageText, PictureLib.Warning);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ProcessResultOfBatchReFillingAccordingToSpecification(Result)
	
	ResultStructure = Undefined;
	
	If Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	ElsIf Result.Status = "Completed2" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
	EndIf;
	
	Return ResultStructure;
	
EndFunction

&AtClientAtServerNoContext
Function ReFillBatchJobName()
	
	Return NStr("vi = 'Điền lại lô hàng theo bảng kê chi tiết';
				|ru = 'Перезаполнение партии по спецификации';
				|en = 'Refill lots by the BOM'; fa = 'Refill lots by the BOM';
				|it = 'Ricompilazione lotti in base alla specifica';
				|pl = 'Ponowne wypełnienie partii według specyfikacji';
				|tr = 'Ürün reçetesine göre lotun yeniden doldurulması'");
	
EndFunction

&AtClient
Procedure DeleteStagesQuestionEnd(QuestionResult, KeyLot) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	TimeConsumingOperation = Undefined;
	
	ShowUserNotification(
		DeleteStagesJobName(),,
		NStr("vi = 'Cấm xóa các công đoạn của lô hàng.';
			|ru = 'Запущено удаление этапов партии.';
			|en = 'Deletion of lot stages is started.'; fa = 'Deletion of lot stages is started.';
			|it = 'Запущено удаление этапов партии.';
			|pl = 'Deletion of lot stages is started.';
			|tr = 'Lot aşamalarının silinmesi başlatıldı.'"),
		PictureLib.Information32);
	
	DeleteServerStages(KeyLot);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
		
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		New CallbackDescription("DeleteStagesInBackgroundEnd", ThisObject),
		IdleParameters);
	
EndProcedure

&AtServer
Procedure DeleteServerStages(KeyLot)
	
	ProductionLot = Catalogs.ProductionLots.GetRef(KeyLot);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = DeleteStagesJobName();
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionStage2_2.MarkStagesDeferredForDeletion",
		ProductionLot,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure DeleteStagesInBackgroundEnd(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		JobResult = ProcessResultDeleteStages(Result);
		
		ProductionManagementClient.NotifyUserAboutMarkToDeleteProductionStages(
			JobResult);
		
		Action = "Fill";
		ExpectStructureCalculationAndPerformAction();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ProcessResultDeleteStages(Result)
	
	ResultStructure = Undefined;
	
	If Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	ElsIf Result.Status = "Completed2" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
	EndIf;
	
	Return ResultStructure;
	
EndFunction

&AtClientAtServerNoContext
Function DeleteStagesJobName()
	
	Return NStr("vi = 'Xóa các công đoạn của lô hàng';
				|ru = 'Удаление этапов партии';
				|en = 'Delete lot stages'; fa = 'Delete lot stages';
				|it = 'Удаление этапов партии';
				|pl = 'Delete lot stages';
				|tr = 'Lot aşamalarının silinmesi'");
	
EndFunction

&AtClient
Procedure MarkDetailButtons()
	
	Items.ShowStagesDetails.Check = StagesShow;
	Items.ShowContentDetails.Check = ShowContent;
	Items.ShowIssuesDetails.Check = ShowIssues;
	Items.ShowMovementDetails.Check = ShowMovements;
	
EndProcedure

&AtClient
Procedure OpenStaffingByLine(CurrentData)
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("VariantKey"			 , "BySourcesAndDatesContext");
	FormParameters.Insert("Filter"					 , New Structure);
	FormParameters.Insert("CommandParameter"		 , OrderDocument);
	
	FormParameters.Filter.Insert("Products",   CurrentData.Products);
	FormParameters.Filter.Insert("Characteristic", CurrentData.Characteristic);
	FormParameters.Filter.Insert("Warehouse",          CurrentData.Warehouse);
	FormParameters.Filter.Insert("Purpose",     CurrentData.Purpose);
	If Not CurrentData.MultipleWarehouses Then
		FormParameters.Filter.Insert("KeyLot", CurrentData.KeyLot);
	EndIf;
	FormParameters.Filter.Insert("ProductionOrder", OrderDocument);
	
	OpenForm("Report.OrderCompleteness.Form", FormParameters, ThisObject, CurrentData.KeyLot);
	
EndProcedure

&AtClient
Procedure SelectCancellationReasonCompletion(CancellationReason, ProcedureParameters) Export
	
	If Not ValueIsFilled(CancellationReason) Then
		Return;
	EndIf;
	
	ProcedureParameters.Insert("CancellationReason", CancellationReason);
	
	TimeConsumingOperation = StartCancelingLineAtServer(
		ProcedureParameters,
		UUID);
	
	CallbackDescription = New CallbackDescription(
		"CancelingEndLine",
		ThisObject,
		ProcedureParameters.RowID);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription);
	
EndProcedure

&AtServerNoContext
Function StartCancelingLineAtServer(ProcedureParameters, FormIdentifier)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Hủy xuất xưởng trong công đoạn sản xuất';
														|ru = 'Отмена выпуска в этапе производства';
														|en = 'Cancel the release in the production stage'; fa = 'Cancel the release in the production stage';
														|it = 'Cancel the release in the production stage';
														|pl = 'Cancel the release in the production stage';
														|tr = 'Üretim aşamasında ürün iptali'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionStage2_2.CancelOutputFinishedProductsOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
EndFunction

&AtClient
Procedure CancelingEndLine(Result, RowID) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	String = Tree.FindByID(RowID);
	If String <> Undefined Then
		String.Canceled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionOfQualityGradationEnd(Quality, ProcedureParameters) Export
	
	If Not ValueIsFilled(Quality) Then
		Return;
	EndIf;
	
	ProcedureParameters.Insert("Quality", Quality);
	
	TimeConsumingOperation = StartQualityChangeAtServer(
		ProcedureParameters,
		UUID);
	
	CallbackDescription = New CallbackDescription(
		"QualityChangeEnd",
		ThisObject,
		ProcedureParameters);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription);
	
EndProcedure

&AtServerNoContext
Function StartQualityChangeAtServer(ProcedureParameters, FormIdentifier)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thay đổi chất lượng xuất xưởng trong giai đoạn sản xuất';
														|ru = 'Изменение качества выпуска в этапе производства';
														|en = 'Change in release quality in the production stage'; fa = 'Change in release quality in the production stage';
														|it = 'Change in release quality in the production stage';
														|pl = 'Change in release quality in the production stage';
														|tr = 'Üretim aşamasında kalite değişikliği'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionStage2_2.ChangeQualityOfOutputFinishedProductsDelayed",
		ProcedureParameters,
		ExecutionParameters);
	
EndFunction

&AtClient
Procedure QualityChangeEnd(Result, ProcedureParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	String = Tree.FindByID(ProcedureParameters.RowID);
	If String <> Undefined Then
		ActionResult = ResultOfQualityChange(Result.ResultAddress);
		FillPropertyValues(String, ActionResult, "Products, Characteristic, LinePresentation");
		String.Quality = ProcedureParameters.Quality;
		
		Items.TreeContextMenuChangeQuality.Visible = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ResultOfQualityChange(ResultAddress)
	
	ProcessingResult = GetFromTempStorage(ResultAddress);
	
	References = New Array;
	References.Add(ProcessingResult.ProductsOfDifferentQuality);
	If ValueIsFilled(ProcessingResult.CharacteristicOfDifferentQuality) Then
		References.Add(ProcessingResult.CharacteristicOfDifferentQuality);
	EndIf;
	
	ValueOfBankingDetails = Common.ObjectsAttributeValue(References, "Description");
	
	LinePresentation = ProductsClientServer.ProductPresentation(
		ValueOfBankingDetails[ProcessingResult.ProductsOfDifferentQuality],
		ValueOfBankingDetails[ProcessingResult.CharacteristicOfDifferentQuality]);
	
	Result = New Structure;
	Result.Insert("Products", ProcessingResult.ProductsOfDifferentQuality);
	Result.Insert("Characteristic", ProcessingResult.CharacteristicOfDifferentQuality);
	Result.Insert("LinePresentation", LinePresentation);
	
	Return Result;
	
EndFunction

&AtClient
Procedure SelectionOfWorksToAddEnd(SelectionResult, ProcedureParameters) Export
	
	If TypeOf(SelectionResult) <> Type("Structure") Then
		Return;
	EndIf;
	
	TimeConsumingOperation = StartAddingWorkAtServer(
		ProcedureParameters.Stage,
		ProcedureParameters.KeyLot,
		ProcedureParameters.ThisIsASemiFinishedProduct,
		SelectionResult.AddressOfWorkTable,
		SelectionResult.StagesOfReverseKittingKitting);
	
	ProcedureParameters.Insert("AddressOfWorkTable", SelectionResult.AddressOfWorkTable);
	ProcedureParameters.Insert("StagesOfReverseKittingKitting", SelectionResult.StagesOfReverseKittingKitting);
	
	CallbackDescription = New CallbackDescription(
		"AddingWorksEnd",
		ThisObject,
		ProcedureParameters);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription);
	
EndProcedure

&AtServer
Function StartAddingWorkAtServer(Stage, KeyLot, ThisIsASemiFinishedProduct, AddressOfWorkTable, StagesOfReverseKittingKitting)
	
	OutputParameters = ?(ThisIsASemiFinishedProduct, ParametersForReadingTreeOfSemiFinishedProducts(), OrderTreeReadingParameters());
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("OrderDocument", OrderDocument);
	ProcedureParameters.Insert("Stage", Stage);
	ProcedureParameters.Insert("KeyLot", KeyLot);
	ProcedureParameters.Insert("Works", GetFromTempStorage(AddressOfWorkTable));
	ProcedureParameters.Insert("StagesOfReverseKittingKitting", StagesOfReverseKittingKitting);
	ProcedureParameters.Insert("ThisIsASemiFinishedProduct", ThisIsASemiFinishedProduct);
	ProcedureParameters.Insert("OutputParameters", OutputParameters);
	ProcedureParameters.Insert("Purpose", PurposeSelection);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thêm công việc vào công đoạn sản xuất';
														|ru = 'Добавление работ в этап производства';
														|en = 'Add works to the production stage'; fa = 'Add works to the production stage';
														|it = 'Add works to the production stage';
														|pl = 'Add works to the production stage';
														|tr = 'Üretim aşamasına iş eklenmesi'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"Reports.ProductionOrderStructureDynamic.AddWorksAndRepairedFinishedProductsOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
EndFunction

&AtClient
Procedure AddingWorksEnd(Result, ProcedureParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	DisplayAddedWorksAndFinishedProducts(Result.ResultAddress, ProcedureParameters);
	
EndProcedure

&AtServer
Procedure DisplayAddedWorksAndFinishedProducts(ResultAddress, ProcedureParameters)
	
	LineStageOfWork = Tree.FindByID(ProcedureParameters.RowID);
	If LineStageOfWork = Undefined Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("RowType, StageLink", LineTypeStageDocument());
	TreeResult = GetFromTempStorage(ResultAddress); // ValueTree
	
	// Stage with works
	If Not LineStageOfWork.FinishTree Then
		TheStructureOfTheSearch.StageLink = LineStageOfWork.StageLink;
		FoundRows = TreeResult.Rows.FindRows(TheStructureOfTheSearch, True);
		If FoundRows.Count() <> 0 Then
			LineStageOfWork.GetItems().Clear();
			FillTreeRecursively(LineStageOfWork.GetItems(), FoundRows[0].Rows);
			
			Works = GetFromTempStorage(ProcedureParameters.AddressOfWorkTable); // ValueTable
			Works.Indexes.Add("Products, Characteristic");
			WorkSearchStructure = New Structure("Products, Characteristic");
			
			For Each String In LineStageOfWork.GetItems() Do
				FillPropertyValues(WorkSearchStructure, String);
				FoundRows = Works.FindRows(WorkSearchStructure);
				If FoundRows.Count() > 0
					And String.GetItems().Count() = 0
					And Not String.BillOfMaterials.IsEmpty()
					And String.Done = 0 Then
					StringInformation_ = String.GetItems().Add();
					StringInformation_.RowType = LineTypeInformation();
					StringInformation_.LinePresentation = NStr("vi = '<dữ liệu được tính toán>';
																|ru = '<данные рассчитываются>';
																|en = '<data is calculated>'; fa = '<data is calculated>';
																|it = '<data is calculated>';
																|pl = '<data is calculated>';
																|tr = '<veri hesaplanıyor>'");
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Stages of Reverse kitting and kitting
	For Each StageLink In ProcedureParameters.StagesOfReverseKittingKitting Do
		
		StageString = Undefined;
		For Each String In LineStageOfWork.GetParent().GetItems() Do
			If String.StageLink = StageLink Then
				StageString = String;
				Break;
			EndIf;
		EndDo;
		
		If StageString <> Undefined
			And Not StageString.FinishTree Then
			TheStructureOfTheSearch.StageLink = StageString.StageLink;
			FoundRows = TreeResult.Rows.FindRows(TheStructureOfTheSearch, True);
			If FoundRows.Count() <> 0 Then
				StageString.GetItems().Clear();
				FillTreeRecursively(StageString.GetItems(), FoundRows[0].Rows);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
