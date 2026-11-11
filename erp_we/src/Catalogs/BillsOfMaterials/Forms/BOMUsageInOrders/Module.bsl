
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ProductionServer.ProductionIsUsed22() Then
		ExceptionText = NStr("vi = 'Khi mở biểu mẫu, cần bật quản lý sản xuất phiên bản 2.2';
							|ru = 'Для открытия формы необходимо включить управление производством версии 2.2';
							|en = 'To open the form, enable production management, version 2.2'; fa = 'To open the form, enable production management, version 2.2';
							|it = 'Per aprire il modulo è necessario attivare la gestione della produzione versione 2.2';
							|pl = 'Aby otworzyć formularz należy włączyć zarządzanie produkcją wersji 2.2';
							|tr = 'Formun açılması için üretim yönetimi sürüm 2.2 etkinleştirilmelidir'");
		Raise ExceptionText;
	EndIf;
	
	BillOfMaterials = Parameters.BillOfMaterials;
	
	FillInServiceDetails();
	
	FillInListOfOrders();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	Return; // empty handler
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If StrFind("Write_ProductionOrder, Write_ProductionStages, Write_ProductionSchedule", EventName) > 0
		And Source <> "UsageOfBOMInOrders" Then
		FillInListOfOrders();
	EndIf; 
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ChoiceFormByItems" Then
		ReplaceBORCompletion(ValueSelected);
	EndIf; 
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrderList

&AtClient
Procedure OrderListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.OrderList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ProductionStage.IsEmpty() Then
		
		ShowValue(, CurrentData.OrderDocument);
		
	Else
		
		ShowValue(, CurrentData.ProductionStage);
		
	EndIf;

	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OrderListOnActivateRow(Item)
	
	AttachIdleHandler("SetVisibilityOfCommands", 0.2, True);
	
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReplaceSpecificationCommand(Command)
	
	ExcludeSpecificationFromSelection = Undefined;
	
	DataOfSelectedRows = New Array;
	For Each RowData In OrderList Do
		
		RowID = RowData.GetID();
		If Items.OrderList.SelectedRows.Find(RowID) = Undefined Then
			RowData.Replace = False;
			Continue;
		EndIf;
		RowData.Replace = True;
		
		StructureOfData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		StructureOfData.Products            = RowData.Products;
		StructureOfData.Characteristic          = RowData.Characteristic;
		StructureOfData.ProductionStart      = RowData.ProductionStart;
		StructureOfData.ProductionDispatcherBusinessUnit  = RowData.Department;
		StructureOfData.LineOfBusiness = RowData.LineOfBusiness;
		DataOfSelectedRows.Add(StructureOfData);
		
		If Not RowData.ReplacementIsAvailable Then
			MessageText = NStr("vi = 'Không thể thay thế bảng kê chi tiết đối với các dòng đã chọn
			| - không được phép thay đổi bảng kê chi tiết, nếu đang chạy quá trình sản xuất,
			| - không hỗ trợ thay thế bảng kê chi tiết đối với bán thành phẩm (công việc) được sản xuất trong quá trình có bảng kê chi tiết đã thiết lập trước đó.';
			|ru = 'Замена спецификации для выбранных строк недоступна
			| - не допускается замена спецификации, если производство уже запущено,
			| - не поддерживается замена спецификации для полуфабрикатов (работ) производимых в процессе с предустановленной спецификацией.';
			|en = 'Replacement of the bill of materials for the selected lines is not available
			| - Replacement of the bill of materials is not allowed if production has already started.
			| - Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process with the predefined bill of materials is not supported.'; fa = 'Replacement of the bill of materials for the selected lines is not available
			| - Replacement of the bill of materials is not allowed if production has already started.
			| - Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process with the predefined bill of materials is not supported.';
			|it = 'Replacement of the bill of materials for the selected lines is not available
			| - Replacement of the bill of materials is not allowed if production has already started.
			| - Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process with the predefined bill of materials is not supported.';
			|pl = 'Replacement of the bill of materials for the selected lines is not available
			| - Replacement of the bill of materials is not allowed if production has already started.
			| - Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process with the predefined bill of materials is not supported.';
			|tr = 'Seçili satırlar için ürün reçetesi değişimi mümkün değildir
			| - Üretim artık başladıysa ürün reçetesi değişimine izin verilmemektedir,
			| - Ürün reçetesi değişikliği, önceden belirlenmiş ürün reçetesine sahip bir süreçte üretilen yarı mamul ürünler için desteklenmemektedir.'");
			ShowMessageBox(, MessageText);
			Return;
		EndIf;
		
		If Not RowData.CurrentBillOfMaterialsIsNoLongerUsed Then
			// the line for which the current specification
			// is used is selected, so we forbid the selection of the current specification for replacement
			ExcludeSpecificationFromSelection = BillOfMaterials;
		EndIf;
	EndDo;
	
	If DataOfSelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng cần thay thế.';
								|ru = 'Необходимо выбрать строки, в которых требуется выполнить замену.';
								|en = 'Select lines in which replacement should be made.'; fa = 'Select lines in which replacement should be made.';
								|it = 'È necessario selezionare le righe in cui si desidera eseguire la sostituzione.';
								|pl = 'Należy wybrać wiersze, w których trzeba dokonać zamiany.';
								|tr = 'Değişiklik yapacağınız satırları seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	AvailableTypes = BOMSelectionParameters.AvailableTypes; // Array
	AvailableTypes.Add(ProductionProcessType);
	
	AvailableStatuses = BOMSelectionParameters.AvailableStatuses; // Array
	AvailableStatuses.Add(PredefinedValue("Enum.BOMStatuses.Valid"));
	
	BOMSelectionParameters.Insert("ExcludeSpecification", ExcludeSpecificationFromSelection);
	
	ProductDataManagementClient.OpenFormForSelectingSpecificationsFromListOfProducts(DataOfSelectedRows, BOMSelectionParameters, ThisForm);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Refill(Command)
	ProductionOrdersRecalculation       = New Array();
	ProductionOrdersAreBeingOverfilled = New Array();
	
	SelectedRows = Items.OrderList.SelectedRows;
	For Each SelectedRow In SelectedRows Do
		RowData = OrderList.FindByID(SelectedRow);
		
		If RowData.BatchesHaveBeenFormed Then
			ProductionOrdersAreBeingOverfilled.Add(RowData.OrderDocument);
		ElsIf RowData.RecalculationIsAvailable Then
			ProductionOrdersRecalculation.Add(RowData.OrderDocument);
		EndIf;
		
	EndDo;
	
	If ProductionOrdersRecalculation.Count() = 0
			And ProductionOrdersAreBeingOverfilled.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các đơn hàng cần tính lại nhu cầu nguyên vật liệu, nhân công.';
								|ru = 'Необходимо выбрать заказы, для которых требуется пересчитать потребность в материалах, трудозатраты.';
								|en = 'Select the orders for which you need to recalculate the demand for materials, labor costs.'; fa = 'Select the orders for which you need to recalculate the demand for materials, labor costs.';
								|it = 'È necessario selezionare gli ordini per i quali è richiesto di ricalcolare il consumo in materiali e costi di lavoro.';
								|pl = 'Należy wybrać zamówienia, dla których wymagane jest przeliczenie zapotrzebowania w materiałach, nakładach pracy.';
								|tr = 'Malzeme gereksinimini, iş gücü maliyetlerini yeniden hesaplamak istediğiniz siparişleri seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	If SelectedRows.Count() = 1
		And ProductionOrdersAreBeingOverfilled.Count() = 1
		And OrderList.FindByID(SelectedRows[0]).BatchesLaunched Then
		
		ShowQueryBox(
			New CallbackDescription("RefillCompletion", ThisObject, ProductionOrdersAreBeingOverfilled),
			NStr("vi = 'Theo đơn hàng đã chọn có các công đoạn đã bắt đầu/đã hoàn thành. Tiếp tục điền lại theo bảng kê chi tiết không?';
				|ru = 'По выбранному заказу есть начатые/завершенные этапы. Продолжить перезаполнение по спецификации?';
				|en = 'The selected order has started/completed stages. Continue refilling by the BOM?'; fa = 'The selected order has started/completed stages. Continue refilling by the BOM?';
				|it = 'The selected order has started/completed stages. Continue refilling by the BOM?';
				|pl = 'The selected order has started/completed stages. Continue refilling by the BOM?';
				|tr = 'Seçili siparişte başlatılmış/tamamlanmış aşamalar bulunuyor. Ürün reçetesine göre yeniden doldurulsun mu?'"),
			QuestionDialogMode.YesNo);
			
	Else
		
		If ProductionOrdersRecalculation.Count() > 0 Then
			OrderStructureClient.StartRecalculatingOrderStructureAccordingToSpecification(BillOfMaterials, ProductionOrdersRecalculation);
		EndIf;
		
		If ProductionOrdersAreBeingOverfilled.Count() > 0 Then
			ReFillBatchesAccordingToSpecification(ProductionOrdersAreBeingOverfilled);
		EndIf;
		
	EndIf;
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	FillInListOfOrders();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ShowStages(Command)
	
	StagesShow = Not StagesShow;
	
	Items.OrderListShowStages.Check = StagesShow;
	
	FillInListOfOrders();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Registration of lines for which production has already been launched
	#Region BatchesHaveBeenFormed
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderList.BatchesHaveBeenFormed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", New Color(191, 97, 12));
	
	#EndRegion
	
	// Registration of the products for which the replacement was performed
	#Region CurrentBillOfMaterialsIsNoLongerUsed
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderList.CurrentBillOfMaterialsIsNoLongerUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.MediumGray);
	
	#EndRegion
	
	// standard design of the nomenclature
	#Region Products

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "OrderListProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "OrderList.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "OrderListCharacteristic",
																		     "OrderList.ItemVariantsAreUsed");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderListPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderList.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<No assignment>'; fa = '<No assignment>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	QueryText = "
	|SELECT
	|	T.ProductionProcessType                                                                   AS ProductionProcessType,
	|	T.MainProductProductKind.ItemsType = VALUE(Enum.ItemsTypes.Set) AS ThisIsTechnologicalSet
	|FROM
	|	Catalog.BillsOfMaterials AS T
	|
	|WHERE
	|	T.Ref = &BillOfMaterials
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

&AtServer
Procedure FillInListOfOrders()

	OrderList.Clear();
	
	Query = New Query();
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	Query.SetParameter("StagesShow", StagesShow);
	Query.SetParameter("ThisIsTechnologicalSet", ThisIsTechnologicalSet);
	Query.Text = "
	|SELECT ALLOWED
	|
	|	Table.Ref AS OrderDocument,
	|
	|	Table.LineNumber AS LineNumberProducts,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	CASE
	|		WHEN Table.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage)) 
	|				AND NOT Table.ToExpenseAs THEN
	|			Table.Warehouse
	|		WHEN Table.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) 
	|			  OR Table.ToExpenseAs THEN
	|			Table.Department
	|		ELSE
	|			UNDEFINED
	|	END                  AS Warehouse,
	|	Table.Purpose     AS Purpose,
	|
	|	FALSE AS ThisIsASemiFinishedProduct,
	|
	|	NULL AS ProductionStage,
	|	NULL AS PresentationStage,
	|
	|	CASE
	|		WHEN Table.Ref.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
	|			AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Document.ProductionStage2_2 AS Stages
	|				WHERE
	|					Stages.ReferenceOrder = Table.Ref
	|					AND Stages.Posted)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ReplacementIsAvailable,
	|	CASE
	|		WHEN Table.Ref.DynamicStructure
	|			AND Table.Ref.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
	|			AND Table.Ref.Posted
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecalculationIsAvailable,
	|
	|	CASE
	|		WHEN Table.Ref.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
	|			AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Document.ProductionStage2_2 AS Stages
	|				WHERE
	|					Stages.ReferenceOrder = Table.Ref
	|					AND Stages.Posted)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS BatchesHaveBeenFormed,
	|
	|	Table.Count AS Count
	|
	|INTO BOMUsageInOrders
	|
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS Table
	|
	|WHERE
	|	Table.BillOfMaterials = &BillOfMaterials
	|	AND Table.Ref.Status <> VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|	AND NOT Table.Ref.DeletionMark
	|	AND NOT Table.Canceled
	|	AND NOT &ThisIsTechnologicalSet
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Plan.ProductionOrder AS OrderDocument,
	|
	|	-1 AS LineNumberProducts,
	|
	|	Plan.Products        AS Products,
	|	Plan.Characteristic      AS Characteristic,
	|	Plan.Warehouse               AS Warehouse,
	|	Plan.Purpose          AS Purpose,
	|
	|	TRUE AS ThisIsASemiFinishedProduct,
	|
	|	NULL AS ProductionStage,
	|	NULL AS PresentationStage,
	|
	|	NOT MAX(NSICache.BOMIsPredefined) AS ReplacementIsAvailable,
	|	TRUE AS RecalculationIsAvailable,
	|
	|	FALSE AS BatchesHaveBeenFormed,
	|
	|	SUM(Plan.Scheduled) AS Count
	|
	|FROM
	|
	|	InformationRegister.OrderStructure AS Plan
	|
	|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|		ON NSICache.Products        = Plan.Products
	|		 AND NSICache.Characteristic      = Plan.Characteristic
	|		 AND NSICache.Warehouse               = Plan.Warehouse
	|		 AND NSICache.Purpose          = Plan.Purpose
	|		 AND NSICache.ProductionOrder = Plan.ProductionOrder
	|		 AND Plan.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)
	|
	|WHERE
	|	NSICache.BillOfMaterials = &BillOfMaterials
	|	AND NOT &ThisIsTechnologicalSet
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder
	|
	|HAVING
	|	SUM(Plan.Scheduled) > 0
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Table.Ref.ReferenceOrder AS OrderDocument,
	|	
	|	-1 AS LineNumberProducts,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Recipient     AS Warehouse,
	|	Table.Purpose     AS Purpose,
	|	
	|	FALSE AS ThisIsASemiFinishedProduct,
	|
	|	Table.Ref      AS ProductionStage,
	|	&PresentationStage AS PresentationStage,
	|
	|	FALSE AS ReplacementIsAvailable,
	|	FALSE AS RecalculationIsAvailable,
	|
	|	TRUE AS BatchesHaveBeenFormed,
	|
	|	Table.Count AS Count
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref.BillOfMaterials = &BillOfMaterials
	|	AND Table.Ref.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|	AND Table.Ref.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly),
	|														VALUE(Enum.ProductionProcessTypes.PerformRM),
	|														VALUE(Enum.ProductionProcessTypes.Repair))
	|	AND Table.Products = Table.Ref.ProductionLot.MainProductProducts
	|	AND Table.Characteristic = Table.Ref.ProductionLot.MainProductCharacteristic
	|	AND NOT Table.Canceled
	|	AND NOT Table.Ref.DeletionMark
	|	AND &StagesShow
	|	AND NOT &ThisIsTechnologicalSet
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Table.Ref.ReferenceOrder AS OrderDocument,
	|	
	|	-1 AS LineNumberProducts,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse          AS Warehouse,
	|	Table.Purpose     AS Purpose,
	|	
	|	FALSE AS ThisIsASemiFinishedProduct,
	|
	|	Table.Ref      AS ProductionStage,
	|	&PresentationStage AS PresentationStage,
	|
	|	FALSE AS ReplacementIsAvailable,
	|	FALSE AS RecalculationIsAvailable,
	|
	|	TRUE AS BatchesHaveBeenFormed,
	|
	|	Table.Count AS Count
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Table
	|WHERE
	|	Table.Ref.BillOfMaterials = &BillOfMaterials
	|	AND Table.Ref.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|	AND Table.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|	AND Table.Products = Table.Ref.ProductionLot.MainProductProducts
	|	AND Table.Characteristic = Table.Ref.ProductionLot.MainProductCharacteristic
	|	AND NOT Table.Canceled
	|	AND NOT Table.Ref.DeletionMark
	|	AND &StagesShow
	|	AND NOT &ThisIsTechnologicalSet
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Table.Ref.ReferenceOrder AS OrderDocument,
	|	
	|	-1 AS LineNumberProducts,
	|	
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse          AS Warehouse,
	|	Table.Purpose     AS Purpose,
	|
	|	FALSE AS ThisIsASemiFinishedProduct,
	|
	|	Table.Ref      AS ProductionStage,
	|	&PresentationStage AS PresentationStage,
	|
	|	FALSE AS ReplacementIsAvailable,
	|	FALSE AS RecalculationIsAvailable,
	|
	|	TRUE AS BatchesHaveBeenFormed,
	|
	|	Table.Count AS Count
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Table
	|WHERE
	|	Table.BillOfMaterials = &BillOfMaterials
	|	AND Table.Produced
	|	AND Table.Ref.ReferenceOrder.Status <> VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|	AND NOT Table.Ref.DeletionMark
	|	AND &StagesShow
	|	AND NOT &ThisIsTechnologicalSet
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Table.Ref.ReferenceOrder        AS OrderDocument,
	|
	|	-1 AS LineNumberProducts,
	|
	|	VALUE(Catalog.Products.EmptyRef)               AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|
	|	FALSE                AS ThisIsASemiFinishedProduct,
	|
	|	Table.Ref      AS ProductionStage,
	|	&PresentationStage AS PresentationStage,
	|
	|	FALSE AS ReplacementIsAvailable,
	|	FALSE AS RecalculationIsAvailable,
	|
	|	TRUE AS BatchesHaveBeenFormed,
	|
	|	0                                                            AS Count
	|
	|FROM
	|	Document.ProductionStage2_2.MaterialsAndWorksSets AS Table
	|WHERE
	|	Table.BillOfMaterials = &BillOfMaterials
	|	AND Table.Ref.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|	AND NOT Table.Ref.DeletionMark
	|	AND &StagesShow
	|	AND &ThisIsTechnologicalSet
	|
	|;
	|
	|";
	
	Query.Text = StrReplace(
		Query.Text,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("Table.Ref"));
		
	Query.Text = Query.Text +
	"SELECT
	|
	|	Table.OrderDocument AS OrderDocument,
	|
	|	Table.OrderDocument.Number  AS Number,
	|	Table.OrderDocument.Date   AS Date,
	|	Table.OrderDocument.Status AS Status,
	|
	|	Table.OrderDocument.EarliestStartDate     AS ProductionStart,
	|	Table.OrderDocument.DemandDate   AS EndOfProduction_,
	|
	|	Table.OrderDocument.Department           AS Department,
	|	Table.OrderDocument.LineOfBusiness AS LineOfBusiness,
	|
	|	Table.ReplacementIsAvailable   AS ReplacementIsAvailable,
	|	Table.RecalculationIsAvailable AS RecalculationIsAvailable,
	|
	|	Table.BatchesHaveBeenFormed AS BatchesHaveBeenFormed,
	|	TRUE IN (SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ProductionStage2_2 AS Stages
	|			WHERE
	|				Stages.ReferenceOrder = Table.OrderDocument
	|				AND Stages.Posted
	|				AND Stages.Status IN (VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
	|									VALUE(Enum.StatusesOfProductionStages2_2.Completed))) AS BatchesLaunched,
	|
	|	Table.ProductionStage AS ProductionStage,
	|	Table.PresentationStage AS PresentationStage,
	|
	|	Table.LineNumberProducts AS LineNumberProducts,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse          AS Warehouse,
	|	Table.Purpose     AS Purpose,
	|
	|	Table.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|
	|	Table.Products.ProductKind AS ProductKind,
	|
	|	CASE
	|		WHEN Table.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                AS ItemVariantsAreUsed,
	|
	|	Table.Count AS Count
	|
	|FROM
	|	BOMUsageInOrders AS Table
	|
	|ORDER BY
	|	Date,
	|	OrderDocument,
	|	ProductionStage,
	|	Products,
	|	Characteristic";
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		NewRow = OrderList.Add();
		FillPropertyValues(NewRow, Selection);
		
		OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number);
		OrderDate = Format(Selection.Date, "DLF=D");
		If ValueIsFilled(Selection.ProductionStage) Then
			
			OrderPresentation = StrTemplate(NStr("vi = 'Số %1 ngày %2 (%3)';
												|ru = '№%1 от %2 (%3)';
												|en = 'No.%1 dated %2 (%3)'; fa = 'No.%1 dated %2 (%3)';
												|it = '№%1 di %2 (%3)';
												|pl = 'nr%1 z dn. %2 (%3)';
												|tr = '%2 tarihli %1 numaralı (%3)'"),
											OrderNumber,
											OrderDate,
											Selection.PresentationStage);
											
		ElsIf Selection.LineNumberProducts > 0 Then
			
			OrderPresentation = StrTemplate(NStr("vi = 'Số %1 ngày %2 (dòng số %3)';
												|ru = '№%1 от %2 (строка № %3)';
												|en = 'No.%1 dated %2 (line No. %3)'; fa = 'No.%1 dated %2 (line No. %3)';
												|it = '№%1 di %2 (riga №%3)';
												|pl = 'Nr%1 z dn. %2 (wiersz nr %3)';
												|tr = '%2 tarihli %1 numaralı (%3 satır numaralı)'"),
								OrderNumber,
								OrderDate,
								Selection.LineNumberProducts);
								
		ElsIf ThisIsTechnologicalSet Then
			
			OrderPresentation = StrTemplate(NStr("vi = 'Số %1 ngày %2 (%3)';
												|ru = '№%1 от %2 (%3)';
												|en = 'No.%1 dated %2 (%3)'; fa = 'No.%1 dated %2 (%3)';
												|it = '№%1 di %2 (%3)';
												|pl = 'nr%1 z dn. %2 (%3)';
												|tr = '%2 tarihli %1 numaralı (%3)'"), 
											OrderNumber, 
											Format(Selection.Date, "DLF=D"),
											Selection.PresentationStage);
			
		Else
			
			OrderPresentation = StrTemplate(NStr("vi = 'Số %1 ngày %2';
												|ru = '№%1 от %2';
												|en = '#%1, %2'; fa = '#%1, %2';
												|it = '№%1 da %2';
												|pl = 'Nr%1 z dnia %2';
												|tr = '%2 tarihli %1 numaralı'"), OrderNumber, OrderDate);
			
		EndIf;
		
		NewRow.OrderPresentation = OrderPresentation;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfCommands() Export
	
	ReplaceSpecificationIsAvailable = True;
	RefillIsAvailable        = True;
	
	SelectedRows = Items.OrderList.SelectedRows;
	For Each SelectedRow In SelectedRows Do
		
		RowData = OrderList.FindByID(SelectedRow);
		
		If Not RowData.ReplacementIsAvailable Then
			ReplaceSpecificationIsAvailable = False;
		EndIf;
		
		If ValueIsFilled(RowData.ProductionStage) Then
			RefillIsAvailable = False;
		EndIf;
		
		If RowData.BatchesLaunched And SelectedRows.Count() > 1 Then
			RefillIsAvailable = False;
		EndIf;
		
		If Not ReplaceSpecificationIsAvailable And Not RefillIsAvailable Then
			Break;
		EndIf;
		
	EndDo;
	
	Items.OrderListReplaceBOR.Enabled = ReplaceSpecificationIsAvailable;
	Items.OrderListRefill.Enabled        = RefillIsAvailable;
	
EndProcedure

&AtClient
Procedure ReplaceBORCompletion(NewSpecification)
	
	PerformReplacementsInOrdersOnServer(NewSpecification);
	
	NotifyAboutChanges_ = False;
	
	If TotalReplacements = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng cần thay thế.';
								|ru = 'Необходимо выбрать строки, в которых требуется выполнить замену.';
								|en = 'Select lines in which replacement should be made.'; fa = 'Select lines in which replacement should be made.';
								|it = 'È necessario selezionare le righe in cui si desidera eseguire la sostituzione.';
								|pl = 'Należy wybrać wiersze, w których trzeba dokonać zamiany.';
								|tr = 'Değişiklik yapacağınız satırları seçmeniz gerekmektedir.'"));
		Return;
		
	ElsIf ReplacementsPerformed = TotalReplacements Then
		
		// Successfully replaced in all orders
		TextOfCompletedOperation = NStr("vi = 'Thay thế trong tất cả các dòng đã chọn';
										|ru = 'Выполнена замена во всех выбранных строках';
										|en = 'Replacement is made in all selected lines'; fa = 'Replacement is made in all selected lines';
										|it = 'Sostituito in tutte le righe selezionate';
										|pl = 'Wykonano zamianę we wszystkich wybranych wierszach';
										|tr = 'Seçili tüm satırlarda değişiklik yapıldı'");
		TextExplainingCompletedOperation = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Dòng đơn hàng đã thay đổi: %1 trong số %2';
															|ru = 'Изменено строк заказов: %1 из %2';
															|en = 'Order lines changed: %1 out of %2'; fa = 'Order lines changed: %1 out of %2';
															|it = 'Righe degli ordini modificate: %1 di %2';
															|pl = 'Zmienione wiersze zamówień: %1 z %2';
															|tr = 'Değiştirilen sipariş satırları: %2 üzerinden %1'"),
														Format(ReplacementsPerformed, "NG=0"),
														Format(TotalReplacements, "NG=0"));
														
		ShowUserNotification(TextOfCompletedOperation,, TextExplainingCompletedOperation);
		
		NotifyAboutChanges_ = True;
		
	ElsIf ReplacementsPerformed = 0 Then
		
		// Couldn't replace in any order
		ShowMessageBox(,NStr("vi = 'Thay thế thất bại.';
							|ru = 'Не удалось выполнить замену.';
							|en = 'Cannot replace.'; fa = 'Cannot replace.';
							|it = 'Non è stato possibile effettuare la sostituzione.';
							|pl = 'Zamiana nie powiodła się.';
							|tr = 'Değişiklik yapılamadı.'"));
		Return;
		
	Else
		
		// In some orders could not be replaced
		TextOfCompletedOperation = NStr("vi = 'Không thay thế trong tất cả các dòng đã chọn';
										|ru = 'Замена выполнена не во всех выбранных строках';
										|en = 'Replacement is made not in all selected lines'; fa = 'Replacement is made not in all selected lines';
										|it = 'La sostituzione è stata completata, ma non in tutte le righe selezionate';
										|pl = 'Zamiana została wykonana nie we wszystkich wybranych wierszach';
										|tr = 'Değişiklik, seçili tüm satırlarda yapılmadı'");
		TextExplainingCompletedOperation = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("vi = 'Dòng đơn hàng đã thay đổi: %1 trong số %2';
															|ru = 'Изменено строк заказов: %1 из %2';
															|en = 'Order lines changed: %1 out of %2'; fa = 'Order lines changed: %1 out of %2';
															|it = 'Righe degli ordini modificate: %1 di %2';
															|pl = 'Zmienione wiersze zamówień: %1 z %2';
															|tr = 'Değiştirilen sipariş satırları: %2 üzerinden %1'"),
														Format(ReplacementsPerformed, "NG=0"),
														Format(TotalReplacements, "NG=0"));
														
		ShowUserNotification(TextOfCompletedOperation,, TextExplainingCompletedOperation);
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Không thay thế trong tất cả các dòng đơn hàng (trong %1 trong số %2).';
											|ru = 'Замена выполнена не во всех строках заказов (в %1 из %2).';
											|en = 'Replacement is not made in all order lines (in %1 out of %2).'; fa = 'Replacement is not made in all order lines (in %1 out of %2).';
											|it = 'La sostituzione è stata completata, ma non in tutte le righe selezionate (in %1 su %2).';
											|pl = 'Zamiana została wykonana nie we wszystkich wybranych wierszach (w %1 z %2).';
											|tr = 'Değişiklik, seçili tüm satırlarda yapılmadı (%2 üzerinden %1 içinde).'"), 
										Format(ReplacementsPerformed, "NG=0"), 
										Format(TotalReplacements, "NG=0"));
										
		ShowMessageBox(, MessageText);
		
		NotifyAboutChanges_ = True;
		
	EndIf; 
	
	If NotifyAboutChanges_ Then
		
		NotifyChanged(Type("DocumentRef.ProductionOrder2_2"));
		
		Notify("Write_ProductionOrder",, "UsageOfBOMInOrders");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PerformReplacementsInOrdersOnServer(Val NewSpecification)
	
	// Let's determine which products this specification is suitable for
	
	Query = New Query(
	"SELECT
	|	Table.ProductKind AS ProductKind,
	|	Table.Products    AS Products,
	|	Table.Characteristic  AS Characteristic
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.Ref.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly),
	|													VALUE(Enum.ProductionProcessTypes.PerformRM),
	|													VALUE(Enum.ProductionProcessTypes.Repair))
	|
	|UNION ALL
	|
	|SELECT
	|	Table.MainProductProductKind,
	|	Table.MainProductProducts,
	|	Table.MainProductCharacteristic
	|FROM
	|	Catalog.BillsOfMaterials AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)");
	
	Query.SetParameter("BillOfMaterials", NewSpecification);
	
	ProductsForWhichSpecificationIsSuitable = Query.Execute().Unload();
	ProductsForWhichSpecificationIsSuitable.Indexes.Add("ProductKind,Products,Characteristic");
	
	TheStructureOfTheSearch = New Structure("Replace, BatchesHaveBeenFormed", True, False);
	
	OrdersTable = OrderList.Unload(TheStructureOfTheSearch);
	OrdersTable.GroupBy("OrderDocument");
	
	ReplacementData = Documents.ProductionOrder2_2.SpecificationReplacementData();
	
	TotalReplacements = 0;
	ReplacementsPerformed = 0;
	
	For Each OrderRow In OrdersTable Do
		
		// We will get the replacement data in the order
		LinesInWhichReplacementIsPerformed = New Array;
		TheStructureOfTheSearch = New Structure("OrderDocument,Replace,BatchesHaveBeenFormed", OrderRow.OrderDocument, True, False);
		StringsList = OrderList.FindRows(TheStructureOfTheSearch);
		For Each RowData In StringsList Do
			
			TotalReplacements = TotalReplacements + 1;
			
			// You need to make sure that the specification is suitable for the specified order line
			ProductSearchStructure = New Structure("ProductKind,Products,Characteristic",
				RowData.ProductKind,
				Catalogs.Products.EmptyRef(),
				Catalogs.ItemsCharacteristics.EmptyRef());
			
			FoundRows = ProductsForWhichSpecificationIsSuitable.FindRows(ProductSearchStructure);
			If FoundRows.UBound() = -1 Then
				ProductSearchStructure.Products = RowData.Products;
				FoundRows = ProductsForWhichSpecificationIsSuitable.FindRows(ProductSearchStructure);
				If FoundRows.UBound() = -1 Then
					If ValueIsFilled(RowData.Characteristic) Then
						ProductSearchStructure.Characteristic = RowData.Characteristic;
						FoundRows = ProductsForWhichSpecificationIsSuitable.FindRows(ProductSearchStructure);
						If FoundRows.UBound() = -1 Then
							Continue;
						EndIf;
					Else
						Continue;
					EndIf;
				EndIf;
			EndIf;
			
			Replacement = ReplacementData.Add();
			FillPropertyValues(Replacement, RowData);
			Replacement.ProductionOrder = RowData.OrderDocument;
			Replacement.BillOfMaterials = NewSpecification;
			LinesInWhichReplacementIsPerformed.Add(RowData);
			
		EndDo;
		
		ReplacementResult = Documents.ProductionOrder2_2.ReplaceSpecificationsWithoutControl(ReplacementData);
		
		If Not ReplacementResult.HasErrors Then
			
			For Each RowData In LinesInWhichReplacementIsPerformed Do
				RowData.CurrentBillOfMaterialsIsNoLongerUsed = (NewSpecification <> BillOfMaterials);
			EndDo;
			
			ReplacementsPerformed = ReplacementsPerformed + ReplacementResult.ReplacementsPerformed;
			
		EndIf;
		
		ReplacementData.Clear();
		
	EndDo;
		
EndProcedure

&AtClient
Procedure RefillCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ReFillBatchesAccordingToSpecification(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReFillBatchesAccordingToSpecification(Orders)
	
	ShowUserNotification(
		ReFillInBatchJobName(),,
		NStr("vi = 'Đã khởi động điền lại lô hàng trong đơn hàng được chọn theo bảng kê chi tiết đã chọn.';
			|ru = 'Запущено перезаполнение партий выбранных заказов по выбранной спецификации.';
			|en = 'Selected order lot refilling by the selected BOM is started.'; fa = 'Selected order lot refilling by the selected BOM is started.';
			|it = 'È stata avviata la ricompilazione in base alle specifica selezionata dei lotti degli ordini selezionati.';
			|pl = 'Uruchomiono ponowne wypełnienie partii wybranych zamówień według wybranej specyfikacji.';
			|tr = 'Seçili ürün reçetesine göre seçili sipariş lotlarının yeniden doldurulması başlatıldı.'"),
		PictureLib.Information32);
	ReFillBatchesAccordingToSpecificationServer(Orders);
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
		
	TimeConsumingOperationsClient.WaitCompletion(
		TimeConsumingOperation,
		New CallbackDescription("ReFillBatchesAccordingToSpecificationInBackgroundEnd", ThisObject),
		IdleParameters);
	
EndProcedure

&AtServer
Procedure ReFillBatchesAccordingToSpecificationServer(Orders)
	
	QueryText = "
	|SELECT DISTINCT
	|	Stages.ProductionLot AS ProductionLot,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS Stage
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|WHERE
	|	Stages.ReferenceOrder IN (&Orders)
	|	AND Stages.BillOfMaterials = &BillOfMaterials
	|	AND Stages.Posted";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Orders", Orders);
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	BatchTable_ = Query.Execute().Unload();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Lots", BatchTable_);
	ProcedureParameters.Insert("FormIdentifier", UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = ReFillInBatchJobName();
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionStage2_2.ReFillInBatchesInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ReFillBatchesAccordingToSpecificationInBackgroundEnd(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ResultStructure = ProcessResultOfBatchesReFillingAccordingToSpecification(Result);
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
			ShowUserNotification(ReFillInBatchJobName(),, MessageText, PictureLib.Warning);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ProcessResultOfBatchesReFillingAccordingToSpecification(Result)
	
	ResultStructure = Undefined;
	
	If Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	ElsIf Result.Status = "Completed2" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
	EndIf;
	
	Return ResultStructure;
	
EndFunction

&AtClientAtServerNoContext
Function ReFillInBatchJobName()
	
	Return NStr("vi = 'Điền lại lô hàng theo bảng kê chi tiết';
				|ru = 'Перезаполнение партий по спецификации';
				|en = 'Refill lots by BOM'; fa = 'Refill lots by BOM';
				|it = 'Ricompilazione lotti in base alla specifica';
				|pl = 'Ponowne wypełnienie partii według specyfikacji';
				|tr = 'Ürün reçetesine göre lotların yeniden doldurulması'");
	
EndFunction

#EndRegion
