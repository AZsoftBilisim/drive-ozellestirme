#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	ThereMayBeAppointmentsWithoutAnOrder = Documents.InventoryAssignmentAdjustment.AppointmentsWithoutOrderAreAllowed();
	OperationTypeReserve = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_;
	TypeOfOperationReserveAndAdjust = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment;
	TypeOfOperationCounterAdjustment = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment;
	
	If Not Users.RolesAvailable("AdditionalOperationsOfInventoryAssignmentAdjustment") Then
		Items.OperationKindRadioButton.Visible = False;
	EndIf;
	
	// Initialization of form details from parameters.
	FillPropertyValues(ThisObject, Parameters,
		"OperationKind,Organization,Purpose,MultipleAppointments,OrderDocument,AssignmentAdjustment,QuantityToPassForAssignment");
	ConfigureFormElementsByFunctionalOptions();
	
	If MultipleAppointments Then
		Assignments.LoadValues(Parameters.Assignments);
	EndIf;
	
	If ValueIsFilled(Parameters.OrderDocument) Then
		Organization = Common.ObjectAttributeValue(Parameters.OrderDocument, "Organization");
	EndIf;
	
	If IsTempStorageURL(Parameters.AddressOfGoods) Then
		GoodsFilter.Load(GetFromTempStorage(Parameters.AddressOfGoods));
		DeleteFromTempStorage(Parameters.AddressOfGoods);
	EndIf;
	
	If Not MultipleAppointments And Not ValueIsFilled(Purpose) Then
		Purpose = Documents.InventoryAssignmentAdjustment.OrderAssignment(OrderDocument);
	EndIf;
	
	If Not MultipleAppointments And Not OperationKind = TypeOfOperationCounterAdjustment Then
		OrderDocument = Common.ObjectAttributeValue(Purpose, "OrderDocument");
	EndIf;
	
	// Checking the possibility of opening the form / refusing to open the form.
	If Not ValueIsFilled(OperationKind) Then
		ExceptionText = NStr("vi = 'Biểu mẫu không được dùng để mở trực tiếp.';
							|ru = 'Форма не предназначена для непосредственного открытия.';
							|en = 'Form is not intended for direct opening.'; fa = 'Form is not intended for direct opening.';
							|it = 'Il modulo non è inteso per l''apertura diretta.';
							|pl = 'Formularz nie jest przeznaczony dla bezpośredniego otwierania.';
							|tr = 'Form doğrudan açılmak üzere tasarlanmamıştır.'");
		Raise ExceptionText;
	EndIf;
	
	// Prohibition of withdrawal of the reserve for appointments of the production giver's order 2.1
	AssignmentType = Common.ObjectAttributeValue(Parameters.Purpose, "AssignmentType");
	
	// For tolling assignments, the transfer of reserves from other assignments is a priority.
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_
			And (AssignmentType = Enums.AssignmentTypes.Giveaway2_5
				Or AssignmentType = Enums.AssignmentTypes.ProvidedMaterialsForStage22
				Or False) Then
		OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment;
	EndIf;
	OrganizationOrdersOnly = ValueIsFilled(Organization)
		And (OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment
			Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments
				 And Not MultipleAppointments);

	Items.OrganizationOrdersOnly.Title = StrReplace(
		NStr("vi = 'Chỉ các đơn hàng của doanh nghiệp ""%1""';
			|ru = 'Только заказы организации ""%1""';
			|en = 'Only orders of company ""%1""'; fa = 'Only orders of company ""%1""';
			|it = 'Solo ordini della società ""%1""';
			|pl = 'Tylko zamówienia firmy ""%1""';
			|tr = 'Yalnız iş yeri siparişleri ""%1""'"), "%1", Organization);

	OperationKindRadioButton = OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment;
	
	Items.PagesDisplayExcessImages.CurrentPage = Items.PageDoesNotDisplayPictureExcess;
	ResultsPurposeSource = "";
	
	ConfigureFormElementsByTypeOfOperation();
	
	If Parameters.Property("UniqueIDForTemporaryStorage") Then
		UniqueIDForTemporaryStorage = Parameters.UniqueIDForTemporaryStorage;
	Else
		UniqueIDForTemporaryStorage = New UUID();
	EndIf;
	
	ToggleSwitchRemoveReserves = Not (OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve
		Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments
			And MultipleAppointments);
	
	FillInTable();
	
	CounterAdjustmentStepIsUsed = OperationKind
		= Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment
			And GoodsTable.FindRows(New Structure("PageIndex", 1)).Count() > 0;
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	NextOnClient(True);
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ToggleSwitchRemoveReservesOnChange(Item)
	WithdrawReserves(Undefined);
EndProcedure

&AtClient
Procedure OrganizationOrdersOnlyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.AssignmentAdjustmentFilling.ObjectForm.Item.OrganizationOrdersOnly.OnChange");
	
	OrganizationOrdersOnlyOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsTable

&AtClient
Procedure GoodsTableRowIsSelectedOnChange(Item)
	
	CurrentRow = Items.GoodsTable.CurrentData;
	
	If CurrentRow.PageIndex = 0 Then
		RecalculateCountForPageIndex1 = True;
	EndIf;
	
	ReFillCountInTotalsTable();
	CalculateTotalsByOrder();
	FillInRequiredStepByRoomsCellsInRow(CurrentRow);
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure GoodsTableCountOnChange(Item)
	
	CurrentRow = Items.GoodsTable.CurrentData;
	CurrentRow.Mark = CurrentRow.Count > 0;
	
	If CurrentRow.PageIndex = 0 Then
		RecalculateCountForPageIndex1 = True;
	EndIf;
	
	ReFillCountInTotalsTable();
	CalculateTotalsByOrder();
	FillInRequiredStepByRoomsCellsInRow(CurrentRow);
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.AssignmentAdjustmentFilling.ObjectForm.Item.GoodsTable.OnActivateRow");
	
	AttachIdleHandler("Attachable_OnActivateRow", 0.1, True);
	
EndProcedure

#EndRegion

#Region EventHandlersForRoomAndCellTreeElements

&AtClient
Procedure TheTreeSpaceOfTheCellNumberOfTheBranchOnChange(Item)
	
	CurrentRow = Items.CellPlacementTree.CurrentData;
	
	UnitConversionStructure = New Structure();
	UnitConversionStructure.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, UnitConversionStructure, Undefined);
	
	CurrentRow.Mark = CurrentRow.Count > 0;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OperationKindRadioButtonOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.AssignmentAdjustmentFilling.ObjectForm.Item.OperationKindRadioButton.OnChange");
	
	TypeOfOperationSwitchWhenChangingOnServer();
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure ModeOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.AssignmentAdjustmentFilling.ObjectForm.Item.FilterReservationByShippingWarehouse.OnChange");
	
	ModeWhenChangingOnServer();
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure SelectRows(Command)
	
	MarkLines(True);
	CalculateTotalsByOrder();
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure ClearRows(Command)
	
	MarkLines(False);
	CalculateTotalsByOrder();
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure WithdrawReserves(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.AssignmentAdjustmentFilling.ObjectForm.Command.RemoveAllReserves");
	
	WithdrawReservesServer();
	CalculateTotalsByOrder();
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure FilterMarkOnChange(Item)
	
	If FilterMark Then
		FilterStructure1 = New Structure("Mark", FilterMark);
	Else
		FilterStructure1 = New Structure();
	EndIf;
	SetRowSelectionTableProducts(Items, FilterStructure1);
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.AssignmentAdjustmentFilling.ObjectForm.Command.Next");
	
	ClearMessages();
	NextOnClient(False);
	NextOnClient(True);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ClearMessages();
	If Items.Steps.CurrentPage = Items.StepByWarehouses Then
		
		If CounterAdjustmentStepIsUsed And Items.GoodsTable.RowFilter.PageIndex = 1 Then
			
			FilterStructure1 = New Structure(Items.GoodsTable.RowFilter);
			FilterStructure1.PageIndex = 0;
			SetRowSelectionTableProducts(Items, FilterStructure1);
			AdjustElementsByCounterAdjustmentStep();
			
		ElsIf MultipleAppointments And Items.GoodsTable.RowFilter.PageIndex = 1 Then
			
			FilterStructure1 = New Structure(Items.GoodsTable.RowFilter);
			FilterStructure1.PageIndex = 0;
			SetRowSelectionTableProducts(Items, FilterStructure1);
			CustomizeItemsByStepOfManyAssignments();
			
		Else
		
			If Modified Then
				ShowQueryBox(
					New CallbackDescription("CancelCompletion", ThisObject),
					NStr("vi = 'Đóng trình hướng dẫn để tạo điều chỉnh gán sản phẩm?';
						|ru = 'Закрыть мастер создания корректировки назначения товаров?';
						|en = 'Close the inventory assignment adjustment creation wizard?'; fa = 'Close the inventory assignment adjustment creation wizard?';
						|it = 'Chiudere la guida della creazione della correzione dell''assegnazione dei beni?';
						|pl = 'Zamknąć kreatora tworzenia zapisu korygującego przeznaczenia towarów?';
						|tr = 'Stok tahsisi düzeltmesi oluşturma sihirbazı kapatılsın mı?'"),
					QuestionDialogMode.YesNo);
			Else
				Close();
			EndIf;
			
		EndIf;
		
	ElsIf Items.Steps.CurrentPage = Items.StepOfWareroomsBins Then
		
		Items.Steps.CurrentPage = Items.StepByWarehouses;
		CellPlacementTree.GetItems().Clear();
		
	ElsIf Items.Steps.CurrentPage = Items.StepCreatedDocuments Then
		
		RefsCount = MarkCreatedDocumentsForDeletion();
		If RefsCount > 0 Then
			ShowUserNotification(NStr("vi = 'Hủy bỏ thao tác';
										|ru = 'Отмена операции';
										|en = 'Cancel operation'; fa = 'لغو عملیات';
										|it = 'Annullamento dell''operazione';
										|pl = 'Anulowanie operacji';
										|tr = 'İşlem iptali'"), , NStr("vi = 'Đã đặt dấu xóa các chứng từ được tạo';
																		|ru = 'Созданные документы помечены на удаление';
																		|en = 'The created documents are marked for deletion'; fa = 'The created documents are marked for deletion';
																		|it = 'Созданные документы помечены на удаление';
																		|pl = 'The created documents are marked for deletion';
																		|tr = 'Oluşturulan belgeler silinmek üzere işaretlendi'"));
		EndIf;
		
		If GoodsTable.Total("RequiresStepThroughRoomsCells") > 0 Then
			Items.Steps.CurrentPage = Items.StepOfWareroomsBins;
		Else
			Items.Steps.CurrentPage = Items.StepByWarehouses;
		EndIf;
		
		CustomizeItemsByStepOfManyAssignments();
		
	EndIf;
	NextOnClient(True);
	
EndProcedure

#EndRegion

#Region Private

#Region VisibilityManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "RoomTreeCellsUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "CellPlacementTree.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsByOrderAssignments.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ResultsByOrder");
	ItemFilter.RightValue = New DataCompositionField("TotalsByOrderAssignments");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableGoodsNewPurposeMaterialsForStage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsTable.NewAssignment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tiếp nhận vào kho>';
													|ru = '<Поступает на склад>';
													|en = '<Delivered to warehouse>'; fa = '<Delivered to warehouse>';
													|it = '<Arriva nel magazzino>';
													|pl = '<Wpływa do magazynu>';
													|tr = '<Ambara giriş>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeCharacteristic.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeOrderSource.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeInitialAssignment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeWarehouse.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.ThisIsRoot");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeSeries.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreePremise.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeCell.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeMark.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.ThisIsRoot");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeSeries.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.TheseAreSeries");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.TheseAreSeries");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeCharacteristic.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeOrderSource.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeInitialAssignment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeWarehouse.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreePremise.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeCell.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeMark.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.TheseAreSeries");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreePremise.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeCell.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeMark.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.TheseAreCells");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeCharacteristic.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeOrderSource.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeInitialAssignment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CellPlacementTreeWarehouse.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSpaceOfTheCellNumberOfTheBranch1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CellPlacementTree.TheseAreCells");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsByFunctionalOptions()
	
	// Unconditional initialization of form elements.
	
	SetRowSelectionTableProducts(Items, New Structure("PageIndex", 0));
	
	// Customizing form elements from functional options.
	
	Items.DecorationInStockOnShipment.Visible = UseSeveralWarehouses;
	Items.GroupInStockAtTheShippingWarehouse.Visible = UseSeveralWarehouses;
	If Not UseSeveralWarehouses Then
		Items.SceneryInCurWarehouse.Title = Chars.LF;
	EndIf;
	Items.GroupPageBasementMultipleAssignmentsNotUsedCollectively.Visible = UseSeveralWarehouses;
	Items.PagesReservationMode.CurrentPage = ?(UseSeveralWarehouses,
		Items.ReservationModeUse, Items.DoNotUseBackupMode);
	
	// The title of the tree of the placeholder of the grouping.
	ArrayAnalytics = New Array();
	ArrayAnalytics.Add(NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Item'; fa = 'قلم';
							|it = 'Articolo';
							|pl = 'Produkt';
							|tr = 'Öğe'"));
	If GetFunctionalOption("UseItemVariants") Then
		ArrayAnalytics.Add(NStr("vi = 'Đặc tính';
								|ru = 'Характеристика';
								|en = 'Variant'; fa = 'گونه';
								|it = 'Caratteristica';
								|pl = 'Charakterystyka';
								|tr = 'Varyant'"));
	EndIf;
	If OperationKind <> Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_
			And OperationKind <> Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
		If ThereMayBeAppointmentsWithoutAnOrder Then
			ArrayAnalytics.Add(NStr("vi = 'Mục đích';
									|ru = 'Назначение';
									|en = 'Assigned to'; fa = 'تخصیص‌یافته به';
									|it = 'Assegnazione';
									|pl = 'Przeznaczenie';
									|tr = 'Atama'"));
		Else
			ArrayAnalytics.Add(NStr("vi = 'Đơn hàng';
									|ru = 'Заказ';
									|en = 'Order'; fa = 'سفارش';
									|it = 'Ordine';
									|pl = 'Zamówienie';
									|tr = 'Sipariş'"));
		EndIf;
	EndIf;
	If UseSeveralWarehouses Then
		ArrayAnalytics.Add(NStr("vi = 'Kho bãi';
								|ru = 'Склад';
								|en = 'Warehouse'; fa = 'Warehouse';
								|it = 'Magazzino';
								|pl = 'Magazyn';
								|tr = 'Ambar'"));
	EndIf;
	BranchInscription = NStr("vi = 'Sê-ri, Nhà kho, Ô hàng';
							|ru = 'Серия, Помещение, Ячейка';
							|en = 'Batch, Wareroom, Bin'; fa = 'Batch, Wareroom, Bin';
							|it = 'Serie, Locale, Cella';
							|pl = 'Seria, Pomieszczenie, Komórka';
							|tr = 'Parti, Depolama alanı, Depo'");
	Items.LocationTreeOfAGroupingCell.Title = StrConcat(ArrayAnalytics, ", ") + " / " + BranchInscription;

	If ThereMayBeAppointmentsWithoutAnOrder Then
		Items.OperationKindRadioButton.Title = NStr("vi = 'Sử dụng dự phòng cho các mục đích khác';
													|ru = 'Использовать резервы других назначений';
													|en = 'Use other assignment reserves'; fa = 'Use other assignment reserves';
													|it = 'Usare le riserve delle altre assegnazioni';
													|pl = 'Używaj rezerwy innych przeznaczeń';
													|tr = 'Rezervlerin başka atamalar için kullan'");
		Items.PageDecorationState.CurrentPage = Items.PageDecorationStateDestination;
	Else
		Items.PageDecorationState.CurrentPage = Items.PageDecorationStateOrder;
	EndIf;
	
EndProcedure

&AtServer
Function StepNameIndicationOfSerialCellsByFunctionalOptions()
	
	Text = "";
	If GetFunctionalOption("UseItemsBatch") Then
		
		If GetFunctionalOption("UseBinLocationWarehousing") Then
				Text = NStr("vi = 'Chỉ ra sê-ri / nhà kho / ô hàng';
							|ru = 'Указание серий / помещений / ячеек';
							|en = 'Specify batches / warerooms / bins'; fa = 'Specify batches / warerooms / bins';
							|it = 'Indicazione serie / ubicazione / celle';
							|pl = 'Wskazanie serii / pomieszczeń / komórek';
							|tr = 'Parti / depo/ depo yeri belirleme'");
		ElsIf GetFunctionalOption("UseWarerooms") Then
				Text = NStr("vi = 'Chỉ ra sê-ri / nhà kho';
							|ru = 'Указание серий / помещений';
							|en = 'Specify batches / warerooms'; fa = 'Specify batches / warerooms';
							|it = 'Indicazione serie / ubicazioni';
							|pl = 'Wskazanie serii / pomieszczeń';
							|tr = 'Parti / depo belirleme'");
		Else
				Text = NStr("vi = 'Chỉ ra sê-ri';
							|ru = 'Указание серий';
							|en = 'Specify batch'; fa = 'تعیین بچ';
							|it = 'Indicazione della serie';
							|pl = 'Określanie serii';
							|tr = 'Parti belirtme'");
		EndIf;
		
	ElsIf GetFunctionalOption("UseBinLocationWarehousing") Then
		Text = NStr("vi = 'Chỉ ra nhà kho / ô hàng';
					|ru = 'Указание помещений / ячеек';
					|en = 'Specify warerooms / bins'; fa = 'Specify warerooms / bins';
					|it = 'Indicazione ubicazioni / celle';
					|pl = 'Wskazanie pomieszczeń / komórek';
					|tr = 'Alan / depo yeri belirleme'");
	Else
		Text = NStr("vi = 'Chỉ ra nhà kho';
					|ru = 'Указание помещений';
					|en = 'Specify warerooms'; fa = 'Specify warerooms';
					|it = 'Indicazioni ubicazioni';
					|pl = 'Wskazanie pomieszczeń';
					|tr = 'Depo belirleme'");
	EndIf;
	
	Return Text;
	
EndFunction

&AtServer
Procedure ConfigureFormElementsByTypeOfOperation()

	If MultipleAppointments And OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		
		Title = StrReplace(NStr("vi = 'Bỏ dự phòng theo mục đích của đơn hàng (%1)';
								|ru = 'Снятие резерва по назначениям заказа (%1)';
								|en = 'Remove the reserve of order assignments (%1)'; fa = 'Remove the reserve of order assignments (%1)';
								|it = 'Rimozione della riserva per le assegnazioni dell''ordine (%1)';
								|pl = 'Usunięcie rezerwy według przeznaczeń zamówienia (%1)';
								|tr = 'Sipariş atamalarında rezervin kaldırılması (%1)'"), "%1", OrderDocument);
		Items.GroupSwitches.CurrentPage = Items.GroupModeWithdrawalOfReserves;
		Items.OperationKindRadioButton.Visible = False;
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableProductsOriginalOrderReservation.Visible = False;
		Items.TableProductsOriginalDestinationReservation.Visible = False;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.CellPlacementTreeOrderSource.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeInitialAssignment.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Dự phòng';
														|ru = 'Резерв';
														|en = 'Reserve'; fa = 'رزرو';
														|it = 'Riservato';
														|pl = 'Reserve';
														|tr = 'Rezerv'");
		Items.OrganizationOrdersOnly.Visible = False;
		Items.GoodsTableNewOrder.Visible = False;
		Items.GoodsTableNewAssignment.Visible = False;
		Items.TableProductsInStockRow.Visible = False;
		Items.TableProductsNeedRow.Visible = False;
		Items.TableGoodsProvidedRow.Visible = False;
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = True;
		Items.GoodsTablePictureSurplusSource.Visible = False;
		Items.GoodsTableDemand.Visible = False;
		Items.GroupInformationOnSourcesOfSupply.Visible = False;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích:';
											|ru = 'Состояние по назначению:';
											|en = 'Assignment state:'; fa = 'Assignment state:';
											|it = 'Stato secondo l''assegnazione:';
											|pl = 'Status według przeznaczenia:';
											|tr = 'Atamaya göre durum:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 2: %1';
								|ru = 'Шаг 2: %1';
								|en = 'Step 2: %1'; fa = 'Step 2: %1';
								|it = 'Passaggio 2: %1';
								|pl = 'Krok 2: %1';
								|tr = 'Aşama 2: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 3: Chứng từ đã tạo';
																|ru = 'Шаг 3: Созданные документы';
																|en = 'Step 3: Created documents'; fa = 'مرحله 3: اسناد ایجادشده';
																|it = 'Passaggio 3: Creazione documenti';
																|pl = 'Krok 3: Utworzone dokumenty';
																|tr = 'Adım 3: Oluşturulan belgeler'");
		
	ElsIf MultipleAppointments And OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
		
		Title = StrReplace(NStr("vi = 'Lập dự phòng (%1)';
								|ru = 'Резервирование (%1)';
								|en = 'Assignment (%1)'; fa = 'Assignment (%1)';
								|it = 'Sistema di riserva (%1)';
								|pl = 'Rezerwacja (%1)';
								|tr = 'Rezervasyon (%1)'"), "%1", OrderDocument);
		Items.GroupSwitches.CurrentPage = Items.GroupReservationMode;
		Items.OrganizationOrdersOnly.Visible = False;
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = False;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = False;
		Items.TableProductsOriginalOrderReservation.Visible = False;
		Items.TableProductsOriginalDestinationReservation.Visible = False;
		Items.CellPlacementTreeOrderSource.Visible = False;
		Items.CellPlacementTreeInitialAssignment.Visible = False;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Cho phép';
														|ru = 'Доступно';
														|en = 'Available'; fa = 'در دسترس';
														|it = 'Disponibile';
														|pl = 'Dostępne';
														|tr = 'Mevcut'");
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.TheTextWillBeCreatedByTheAdjustment.Visible = False;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = False;
		Items.GoodsTablePictureSurplusSource.Visible = False;
		Items.GoodsTableDemand.Visible = False;
		Items.GroupInformationOnSourcesOfSupply.Visible = False;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo tất cả mục đích của đơn hàng:';
											|ru = 'Состояние по всем назначениям заказа:';
											|en = 'State of all order assignments:'; fa = 'State of all order assignments:';
											|it = 'Stato di tutte le assegnazioni dell''ordine:';
											|pl = 'Status według wszystkich przeznaczeń zamówienia:';
											|tr = 'Tüm sipariş atamalarının durumu:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 3: %1';
								|ru = 'Шаг 3: %1';
								|en = 'Step 3: %1'; fa = 'Step 3: %1';
								|it = 'Passaggio 3: %1';
								|pl = 'Krok 3: %1';
								|tr = 'Aşama 3: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 4: Chứng từ đã tạo';
																|ru = 'Шаг 4: Созданные документы';
																|en = 'Step 4: Created documents'; fa = 'Step 4: Created documents';
																|it = 'Passaggio 4: Creazione documenti';
																|pl = 'Krok 4: Utworzone dokumenty';
																|tr = 'Adım 4: Oluşturulan belgeler'");

		CustomizeItemsByStepOfManyAssignments();
		
	ElsIf MultipleAppointments And OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
		
		Title = StrReplace(NStr("vi = 'Lập dự phòng (%1)';
								|ru = 'Резервирование (%1)';
								|en = 'Assignment (%1)'; fa = 'Assignment (%1)';
								|it = 'Sistema di riserva (%1)';
								|pl = 'Rezerwacja (%1)';
								|tr = 'Rezervasyon (%1)'"), "%1", OrderDocument);
		Items.GroupSwitches.CurrentPage = Items.GroupReservationMode;
		Items.OrganizationOrdersOnly.Visible = ValueIsFilled(Organization);
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = False;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = False;
		Items.TableProductsOriginalOrderReservation.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableProductsOriginalDestinationReservation.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeOrderSource.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeInitialAssignment.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Cho phép';
														|ru = 'Доступно';
														|en = 'Available'; fa = 'در دسترس';
														|it = 'Disponibile';
														|pl = 'Dostępne';
														|tr = 'Mevcut'");
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.TheTextWillBeCreatedByTheAdjustment.Visible = False;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = False;
		Items.GoodsTablePictureSurplusSource.Visible = False;
		Items.GoodsTableDemand.Visible = False;
		Items.GroupInformationOnSourcesOfSupply.Visible = False;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo tất cả mục đích của đơn hàng:';
											|ru = 'Состояние по всем назначениям заказа:';
											|en = 'State of all order assignments:'; fa = 'State of all order assignments:';
											|it = 'Stato di tutte le assegnazioni dell''ordine:';
											|pl = 'Status według wszystkich przeznaczeń zamówienia:';
											|tr = 'Tüm sipariş atamalarının durumu:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 3: %1';
								|ru = 'Шаг 3: %1';
								|en = 'Step 3: %1'; fa = 'Step 3: %1';
								|it = 'Passaggio 3: %1';
								|pl = 'Krok 3: %1';
								|tr = 'Aşama 3: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 4: Chứng từ đã tạo';
																|ru = 'Шаг 4: Созданные документы';
																|en = 'Step 4: Created documents'; fa = 'Step 4: Created documents';
																|it = 'Passaggio 4: Creazione documenti';
																|pl = 'Krok 4: Utworzone dokumenty';
																|tr = 'Adım 4: Oluşturulan belgeler'");
		
		CustomizeItemsByStepOfManyAssignments();
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
		
		Title = StrReplace(NStr("vi = 'Bỏ dự phòng (%1)';
								|ru = 'Снятие резерва (%1)';
								|en = 'Remove reserve (%1)'; fa = 'Remove reserve (%1)';
								|it = 'Rimuovere i prodotti riservati (%1)';
								|pl = 'Wycofanie rezerwy (%1)';
								|tr = 'Rezervin kaldırılması (%1)'"), "%1", OrderDocument);
		If ThereMayBeAppointmentsWithoutAnOrder Then
			Title = StrReplace(NStr("vi = 'Bỏ dự phòng (Mục đích: %1)';
									|ru = 'Снятие резерва (Назначение: %1)';
									|en = 'Remove reserve (Assignment: %1)'; fa = 'Remove reserve (Assignment: %1)';
									|it = 'Rimuovere i prodotti riservati (Assegnazione:%1)';
									|pl = 'Wycofanie rezerwy (Przeznaczenie: %1)';
									|tr = 'Rezervin kaldırılması (Atama: %1)'"), "%1", Purpose);
		EndIf;
		Items.GroupSwitches.CurrentPage = Items.GroupModeWithdrawalOfReserves;
		Items.OrganizationOrdersOnly.Visible = False;
		Items.OperationKindRadioButton.Visible = False;
		Items.TableGoodsNewPurposeMaterialsForStage.Visible =
			Common.ObjectAttributeValue(Purpose, "AssignmentType") = Enums.AssignmentTypes.ProvidedMaterialsForStage22;
		Items.TableProductsOriginalOrderWithdrawal.Visible = False;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = False;
		Items.TableProductsOriginalOrderReservation.Visible = False;
		Items.TableProductsOriginalDestinationReservation.Visible = False;
		Items.CellPlacementTreeOrderSource.Visible = False;
		Items.CellPlacementTreeInitialAssignment.Visible = False;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Dự phòng';
														|ru = 'Резерв';
														|en = 'Reserve'; fa = 'رزرو';
														|it = 'Riservato';
														|pl = 'Reserve';
														|tr = 'Rezerv'");
		Items.GoodsTableNewOrder.Visible = False;
		Items.GoodsTableNewAssignment.Visible = False;
		Items.TableProductsInStockRow.Visible = False;
		Items.TableProductsNeedRow.Visible = False;
		Items.TableGoodsProvidedRow.Visible = False;
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = True;
		Items.GoodsTablePictureSurplusSource.Visible = False;
		Items.GoodsTableDemand.Visible = False;
		Items.GroupInformationOnSourcesOfSupply.Visible = False;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích:';
											|ru = 'Состояние по назначению:';
											|en = 'Assignment state:'; fa = 'Assignment state:';
											|it = 'Stato secondo l''assegnazione:';
											|pl = 'Status według przeznaczenia:';
											|tr = 'Atamaya göre durum:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 2: %1';
								|ru = 'Шаг 2: %1';
								|en = 'Step 2: %1'; fa = 'Step 2: %1';
								|it = 'Passaggio 2: %1';
								|pl = 'Krok 2: %1';
								|tr = 'Aşama 2: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 3: Chứng từ đã tạo';
																|ru = 'Шаг 3: Созданные документы';
																|en = 'Step 3: Created documents'; fa = 'مرحله 3: اسناد ایجادشده';
																|it = 'Passaggio 3: Creazione documenti';
																|pl = 'Krok 3: Utworzone dokumenty';
																|tr = 'Adım 3: Oluşturulan belgeler'");
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		
		Title = NStr("vi = 'Bỏ dự phòng theo nhiều mục đích';
					|ru = 'Снятие резерва по многим назначениям';
					|en = 'Multiple assignment removal'; fa = 'حذف چندگانه تخصیص';
					|it = 'Annullamento della prenotazione per varie assegnazioni';
					|pl = 'Usunięcie rezerwy wg wielu przeznaczeń';
					|tr = 'Rezervin birçok atamayla çıkarılması'");
		Items.GroupSwitches.CurrentPage = Items.GroupModeWithdrawalOfReserves;
		Items.OperationKindRadioButton.Visible = False;
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableProductsOriginalOrderReservation.Visible = False;
		Items.TableProductsOriginalDestinationReservation.Visible = False;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.CellPlacementTreeOrderSource.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeInitialAssignment.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Dự phòng';
														|ru = 'Резерв';
														|en = 'Reserve'; fa = 'رزرو';
														|it = 'Riservato';
														|pl = 'Reserve';
														|tr = 'Rezerv'");
		Items.GoodsTableNewOrder.Visible = False;
		Items.GoodsTableNewAssignment.Visible = False;
		Items.TableProductsInStockRow.Visible = False;
		Items.TableProductsNeedRow.Visible = False;
		Items.TableGoodsProvidedRow.Visible = False;
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = True;
		Items.GoodsTablePictureSurplusSource.Visible = False;
		Items.GoodsTableDemand.Visible = False;
		Items.GroupInformationOnSourcesOfSupply.Visible = False;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích:';
											|ru = 'Состояние по назначению:';
											|en = 'Assignment state:'; fa = 'Assignment state:';
											|it = 'Stato secondo l''assegnazione:';
											|pl = 'Status według przeznaczenia:';
											|tr = 'Atamaya göre durum:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 2: %1';
								|ru = 'Шаг 2: %1';
								|en = 'Step 2: %1'; fa = 'Step 2: %1';
								|it = 'Passaggio 2: %1';
								|pl = 'Krok 2: %1';
								|tr = 'Aşama 2: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 3: Chứng từ đã tạo';
																|ru = 'Шаг 3: Созданные документы';
																|en = 'Step 3: Created documents'; fa = 'مرحله 3: اسناد ایجادشده';
																|it = 'Passaggio 3: Creazione documenti';
																|pl = 'Krok 3: Utworzone dokumenty';
																|tr = 'Adım 3: Oluşturulan belgeler'");
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
		
		Title = StrReplace(NStr("vi = 'Lập dự phòng (%1)';
								|ru = 'Резервирование (%1)';
								|en = 'Assignment (%1)'; fa = 'Assignment (%1)';
								|it = 'Sistema di riserva (%1)';
								|pl = 'Rezerwacja (%1)';
								|tr = 'Rezervasyon (%1)'"), "%1", OrderDocument);
		If ThereMayBeAppointmentsWithoutAnOrder Then
			Title = StrReplace(NStr("vi = 'Lập dự phòng (Mục đích: %1)';
									|ru = 'Резервирование (Назначение: %1)';
									|en = 'Assignment (Purpose: %1)'; fa = 'Assignment (Purpose: %1)';
									|it = 'Sistema di riserva (Assegnazione:%1)';
									|pl = 'Rezerwacja (Przeznaczenie: %1)';
									|tr = 'Rezervasyon (Atama: %1)'"), "%1", Purpose);
		EndIf;
		Items.GroupSwitches.CurrentPage = Items.GroupReservationMode;
		Items.OrganizationOrdersOnly.Visible = False;
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = False;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = False;
		Items.TableProductsOriginalOrderReservation.Visible = False;
		Items.TableProductsOriginalDestinationReservation.Visible = False;
		Items.CellPlacementTreeOrderSource.Visible = False;
		Items.CellPlacementTreeInitialAssignment.Visible = False;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Cho phép';
														|ru = 'Доступно';
														|en = 'Available'; fa = 'در دسترس';
														|it = 'Disponibile';
														|pl = 'Dostępne';
														|tr = 'Mevcut'");
		Items.GoodsTableNewOrder.Visible = False;
		Items.GoodsTableNewAssignment.Visible = False;
		Items.TableProductsInStockRow.Visible = False;
		Items.TableProductsNeedRow.Visible = False;
		Items.TableGoodsProvidedRow.Visible = False;
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = False;
		Items.GoodsTablePictureSurplusSource.Visible = True;
		Items.GoodsTableDemand.Visible = True;
		Items.GroupInformationOnSourcesOfSupply.Visible = UseSeveralWarehouses;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích nhận:';
											|ru = 'Состояние по назначению-получателю:';
											|en = 'Assignment recipient state:'; fa = 'وضعیت گیرنده تخصیص:';
											|it = 'Stato secondo l''assegnazione destinataria:';
											|pl = 'Status według przeznaczenia-odbiorcy:';
											|tr = 'Alıcı atamasına göre durum:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 2: %1';
								|ru = 'Шаг 2: %1';
								|en = 'Step 2: %1'; fa = 'Step 2: %1';
								|it = 'Passaggio 2: %1';
								|pl = 'Krok 2: %1';
								|tr = 'Aşama 2: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 3: Chứng từ đã tạo';
																|ru = 'Шаг 3: Созданные документы';
																|en = 'Step 3: Created documents'; fa = 'مرحله 3: اسناد ایجادشده';
																|it = 'Passaggio 3: Creazione documenti';
																|pl = 'Krok 3: Utworzone dokumenty';
																|tr = 'Adım 3: Oluşturulan belgeler'");
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
		
		Title = StrReplace(NStr("vi = 'Lập dự phòng (%1)';
								|ru = 'Резервирование (%1)';
								|en = 'Assignment (%1)'; fa = 'Assignment (%1)';
								|it = 'Sistema di riserva (%1)';
								|pl = 'Rezerwacja (%1)';
								|tr = 'Rezervasyon (%1)'"), "%1", OrderDocument);
		If ThereMayBeAppointmentsWithoutAnOrder Then
			Title = StrReplace(NStr("vi = 'Lập dự phòng (Mục đích: %1)';
									|ru = 'Резервирование (Назначение: %1)';
									|en = 'Assignment (Purpose: %1)'; fa = 'Assignment (Purpose: %1)';
									|it = 'Sistema di riserva (Assegnazione:%1)';
									|pl = 'Rezerwacja (Przeznaczenie: %1)';
									|tr = 'Rezervasyon (Atama: %1)'"), "%1", Purpose);
		EndIf;
		Items.GroupSwitches.CurrentPage = Items.GroupReservationMode;
		Items.OrganizationOrdersOnly.Visible = ValueIsFilled(Organization);
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = False;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = False;
		Items.TableProductsOriginalOrderReservation.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableProductsOriginalDestinationReservation.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeOrderSource.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeInitialAssignment.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Cần điều chỉnh';
																		|ru = 'К корректировке';
																		|en = 'For adjustment'; fa = 'برای تعدیل';
																		|it = 'In correzione';
																		|pl = 'Do korekty';
																		|tr = 'Düzeltilecek'");
		Items.GoodsTableAvailableForInventoryAllocation.Title = NStr("vi = 'Cho phép';
																	|ru = 'Доступно';
																	|en = 'Available'; fa = 'در دسترس';
																	|it = 'Disponibile';
																	|pl = 'Dostępne';
																	|tr = 'Mevcut'");
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Cho phép';
														|ru = 'Доступно';
														|en = 'Available'; fa = 'در دسترس';
														|it = 'Disponibile';
														|pl = 'Dostępne';
														|tr = 'Mevcut'");
		Items.GoodsTableNewOrder.Visible = False;
		Items.GoodsTableNewAssignment.Visible = False;
		Items.TableProductsInStockRow.Visible = False;
		Items.TableProductsNeedRow.Visible = False;
		Items.TableGoodsProvidedRow.Visible = False;
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = False;
		Items.GoodsTablePictureSurplusSource.Visible = True;
		Items.GoodsTableDemand.Visible = True;
		Items.GroupInformationOnSourcesOfSupply.Visible = UseSeveralWarehouses;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích nhận:';
											|ru = 'Состояние по назначению-получателю:';
											|en = 'Assignment recipient state:'; fa = 'وضعیت گیرنده تخصیص:';
											|it = 'Stato secondo l''assegnazione destinataria:';
											|pl = 'Status według przeznaczenia-odbiorcy:';
											|tr = 'Alıcı atamasına göre durum:'");
		
		TitleTemplate1 = NStr("vi = 'Bước 2: %1';
								|ru = 'Шаг 2: %1';
								|en = 'Step 2: %1'; fa = 'Step 2: %1';
								|it = 'Passaggio 2: %1';
								|pl = 'Krok 2: %1';
								|tr = 'Aşama 2: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 3: Chứng từ đã tạo';
																|ru = 'Шаг 3: Созданные документы';
																|en = 'Step 3: Created documents'; fa = 'مرحله 3: اسناد ایجادشده';
																|it = 'Passaggio 3: Creazione documenti';
																|pl = 'Krok 3: Utworzone dokumenty';
																|tr = 'Adım 3: Oluşturulan belgeler'");
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment Then
		
		Title = StrReplace(NStr("vi = 'Đối chiếu điều chỉnh giá trị (%1)';
								|ru = 'Встречная корректировка назначения (%1)';
								|en = 'Assignment mutual adjustment (%1)'; fa = 'Assignment mutual adjustment (%1)';
								|it = 'Controrettifica dell''assegnazione (%1)';
								|pl = 'Wzajemna korekta przeznaczenia (%1)';
								|tr = 'Atamanın karşılıklı düzeltmesi (%1)'"), "%1", OrderDocument);
		Items.GroupSwitches.CurrentPage = Items.GroupReservationMode;
		Items.OperationKindRadioButton.Visible = False;
		Items.TableGoodsNewPurposeMaterialsForStage.Visible = False;
		Items.TableProductsOriginalOrderWithdrawal.Visible = False;
		Items.TableGoodsInitialDestinationWithdrawal.Visible = False;
		Items.GoodsTableAvailableForInventoryAllocation.Visible = False;
		Items.GoodsTableCount.Title = NStr("vi = 'Chuyển giao';
											|ru = 'Передать';
											|en = 'Transfer'; fa = 'انتقال';
											|it = 'Trasferire';
											|pl = 'Transfer';
											|tr = 'Transfer et'");
		Items.CellPlacementTreeOrderSource.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.CellPlacementTreeInitialAssignment.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.Title = NStr("vi = 'Chuyển giao';
																		|ru = 'Передать';
																		|en = 'Transfer'; fa = 'انتقال';
																		|it = 'Trasferire';
																		|pl = 'Transfer';
																		|tr = 'Transfer et'");
		Items.GoodsTableCount.HeaderPicture = PictureLib.Change;
		Items.TheTreeSpaceOfTheCellGroupTheNumberOfVertical.HeaderPicture = PictureLib.Change;
		Items.LocationTreeOfTheReserveCell.Title = NStr("vi = 'Số dư';
														|ru = 'Остаток';
														|en = 'Balance'; fa = 'مانده';
														|it = 'Rimanenze';
														|pl = 'Balance';
														|tr = 'Bakiye'");
		Items.GoodsTableNewOrder.Visible = False;
		Items.GoodsTableNewAssignment.Visible = False;
		Items.TableProductsInStockRow.Visible = False;
		Items.TableProductsNeedRow.Visible = False;
		Items.TableGoodsProvidedRow.Visible = False;
		Items.GroupPageBasementMultipleAssignments_.CurrentPage = Items.GroupPageBasementMultipleAssignmentsNotUsed;
		Items.GoodsTablePictureSurplusSource.Visible = False;
		Items.GoodsTableDemand.Visible = False;
		Items.GroupInformationOnSourcesOfSupply.Visible = False;
		
		TitleTemplate1 = NStr("vi = 'Bước 1. Chuyển giao vật tư cần thiết theo mục đích: %1';
								|ru = 'Шаг 1. Передача требуемых запасов под назначение: %1';
								|en = 'Step 1. Transfer required inventory for assignment: %1'; fa = 'مرحله 1. انتقال موجودی مورد نیاز برای تخصیص: %1';
								|it = 'Passaggio 1. Trasferimento scorte richieste assegnate: %1';
								|pl = 'Krok 1. Przekazanie wymaganych zapasów dla przeznaczenia: %1';
								|tr = 'Adım 1. Gerekli stokların atama kapsamında transferi: %1'");
		Items.DecorationPassNameOfStepByCounterCorrection.Title = StrTemplate(TitleTemplate1, Purpose);
		
		TitleTemplate1 = NStr("ru = 'Шаг 2. Распределение запасов, высвобождающихся из-под назначения: %1';
								|vi = 'Step 2. Allocate the inventory free from assignment: %1';
								|en = 'Step 2. Allocate the inventory free from assignment: %1'; fa = 'مرحله 2. تخصیص موجودی آزاد از تخصیص: %1';
								|it = 'Step 2. Allocate the inventory free from assignment: %1';
								|pl = 'Step 2. Allocate the inventory free from assignment: %1';
								|tr = 'Adım 2. Tahsisten boşalan stokların dağıtımı: %1'");
		Items.DecorationNameOfStepShouldBeDistributedFromUnderDestinationAccordingToCounterAdjustment.Title =
			StrTemplate(TitleTemplate1, Purpose);
		
		TitleTemplate1 = NStr("vi = 'Bước 3: %1';
								|ru = 'Шаг 3: %1';
								|en = 'Step 3: %1'; fa = 'Step 3: %1';
								|it = 'Passaggio 3: %1';
								|pl = 'Krok 3: %1';
								|tr = 'Aşama 3: %1'");
		Items.DecorationStepNameIndicationOfCellRoomSeries.Title =
			StrTemplate(TitleTemplate1, StepNameIndicationOfSerialCellsByFunctionalOptions());
		Items.DecorationStepNameCreatedDocuments.Title = NStr("vi = 'Bước 4: Chứng từ đã tạo';
																|ru = 'Шаг 4: Созданные документы';
																|en = 'Step 4: Created documents'; fa = 'Step 4: Created documents';
																|it = 'Passaggio 4: Creazione documenti';
																|pl = 'Krok 4: Utworzone dokumenty';
																|tr = 'Adım 4: Oluşturulan belgeler'");
		
		AdjustElementsByCounterAdjustmentStep();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustElementsByCounterAdjustmentStep()
	
	If Items.GoodsTable.RowFilter.PageIndex = 0 Then
		
		Items.TableProductsOriginalOrderReservation.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
		Items.TableProductsOriginalDestinationReservation.Visible = ThereMayBeAppointmentsWithoutAnOrder;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích nhận:';
											|ru = 'Состояние по назначению-получателю:';
											|en = 'Assignment recipient state:'; fa = 'وضعیت گیرنده تخصیص:';
											|it = 'Stato secondo l''assegnazione destinataria:';
											|pl = 'Status według przeznaczenia-odbiorcy:';
											|tr = 'Alıcı atamasına göre durum:'");
		
	Else
		
		Items.TableProductsOriginalOrderReservation.Visible = False;
		Items.TableProductsOriginalDestinationReservation.Visible = False;
		Items.StateDecoration.Title = NStr("vi = 'Trạng thái theo mục đích:';
											|ru = 'Состояние по назначению:';
											|en = 'Assignment state:'; fa = 'Assignment state:';
											|it = 'Stato secondo l''assegnazione:';
											|pl = 'Status według przeznaczenia:';
											|tr = 'Atamaya göre durum:'");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeItemsByStepOfManyAssignments()
	
	If MultipleAppointments Then
		
		If Items.GoodsTable.RowFilter.PageIndex = 0 Then
			
			Visible = OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment;
			Items.TableProductsOriginalOrderReservation.Visible = Visible And Not ThereMayBeAppointmentsWithoutAnOrder;
			Items.TableProductsOriginalDestinationReservation.Visible = Visible And ThereMayBeAppointmentsWithoutAnOrder;
			Items.GoodsTableNewOrder.Visible = False;
			Items.GoodsTableNewAssignment.Visible = False;
			Items.TableProductsInStockRow.Visible = False;
			Items.TableProductsNeedRow.Visible = False;
			Items.TableGoodsProvidedRow.Visible = False;
			Items.GroupOrder.Visible = True;
			Items.GroupHeaderMultipleAssignments.Visible = True;
			Items.GroupSwitchesMultipleAssignments.Visible = True;
			Items.GroupPageBasementMultipleAssignments_.CurrentPage =
				Items.GroupPageBasementMultipleAssignmentsNotUsed;
			Items.GoodsTableWarehouse.Visible = True;
			
			Items.TableOfProductsInStock.Visible = True;
			Items.TableGoodsInReserve.Visible = True;
			Items.GoodsTableUnderControl.Visible = True;
			Items.GoodsTablePictureSurplusSource.Visible = True;
			Items.GoodsTableDemand.Visible = True;
			Items.GroupInformationOnSourcesOfSupply.Visible = UseSeveralWarehouses;
			
		Else
			
			Items.TableProductsOriginalOrderReservation.Visible = False;
			Items.TableProductsOriginalDestinationReservation.Visible = False;
			Items.GoodsTableNewOrder.Visible = Not ThereMayBeAppointmentsWithoutAnOrder;
			Items.GoodsTableNewAssignment.Visible = ThereMayBeAppointmentsWithoutAnOrder;
			Items.TableProductsInStockRow.Visible = True;
			Items.TableProductsNeedRow.Visible = True;
			Items.TableGoodsProvidedRow.Visible = True;
			Items.GroupOrder.Visible = False;
			Items.GroupHeaderMultipleAssignments.Visible = False;
			Items.GroupSwitchesMultipleAssignments.Visible = False;
			Items.GroupPageBasementMultipleAssignments_.CurrentPage =
				Items.GroupPageBasementMultipleAssignments;
			Items.GoodsTableWarehouse.Visible = False;
			
			Items.TableOfProductsInStock.Visible = False;
			Items.TableGoodsInReserve.Visible = False;
			Items.GoodsTableUnderControl.Visible = False;
			Items.GoodsTablePictureSurplusSource.Visible = False;
			Items.GoodsTableDemand.Visible = False;
			Items.GroupInformationOnSourcesOfSupply.Visible = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsOnServer

&AtServer
Procedure OrganizationOrdersOnlyOnChangeServer()
	ConfigureFormElementsByTypeOfOperation();
	FillInTable();
EndProcedure

&AtServer
Procedure TypeOfOperationSwitchWhenChangingOnServer()
	
	OperationKind = ?(OperationKindRadioButton, PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment"), 
		PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_"));
	
	FillInTable();
	ConfigureFormElementsByTypeOfOperation();
	
EndProcedure

&AtServer
Procedure ModeWhenChangingOnServer()
	
	FillInTable();
	
EndProcedure

&AtServer
Procedure MarkLines(Value)

	FilterParameters = Items.GoodsTable.RowFilter;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("PageIndex", FilterParameters.PageIndex);
	FilterStructure1.Insert("Mark",        Not Value);
	
	RowsArray = GoodsTable.FindRows(FilterStructure1);
	For Each RowOfGoods In RowsArray Do
		RowOfGoods.Mark = Value;
	EndDo;

	If FilterParameters.PageIndex = 0 Then
		RecalculateCountForPageIndex1 = True;
	EndIf;
	
	ReFillCountInTotalsTable();
	FillInRequiredStepByRoomsCells();

EndProcedure

&AtServer
Procedure WithdrawReservesServer()
	
	Documents.InventoryAssignmentAdjustment.WithdrawReserves(GoodsTable, Not ToggleSwitchRemoveReserves, ProductResults);
	ReFillCountInTotalsTable();
	FillInRequiredStepByRoomsCells();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetRowSelectionTableProducts(Items, Val FilterStructure1)
	
	If Not FilterStructure1.Property("PageIndex") Then
		FilterStructure1.Insert("PageIndex", Items.GoodsTable.RowFilter.PageIndex);
	EndIf;
	FilterStructure1.Insert("SatisfiesTheFilter", True);
	Items.GoodsTable.RowFilter = New FixedStructure(FilterStructure1);
	
EndProcedure

#EndRegion

#Region TransitionBetweenSteps

&AtClient
Procedure NextOnClient(OnlyButtonSettings)
	
	MultipleDocuments = MultipleAppointments
		And (OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_")
			Or OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment"));
	
	If Not OnlyButtonSettings Then
		ClearMessages();
	EndIf;
	
	If CounterAdjustmentStepIsUsed Then // counter adjustment
		
		If Items.Steps.CurrentPage = Items.StepByWarehouses
			And Items.GoodsTable.RowFilter.PageIndex = 0 Then // Step 1.
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageNameOfPassStepByCounterCorrection;
				ConfigureStepButtons("Cancel", "Next");
				Return;
			EndIf;
			
			NextToCounterAdjustment();
			
		ElsIf Items.Steps.CurrentPage = Items.StepByWarehouses
			And Items.GoodsTable.RowFilter.PageIndex = 1 Then // Step 2.
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageNameOfDistributeStepFromUnderAppointmentOfCounterAdjustment;
			EndIf;
			
			If GoodsTable.Total("RequiresStepThroughRoomsCells") > 0 Then
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Back", "Next");
					Return;
				EndIf;
				NextToRoomsAndCells();
				
			Else
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Back", "Create");
					Return;
				EndIf;
				NextToCreatingDocument();
				
			EndIf;
			
		ElsIf Items.Steps.CurrentPage = Items.StepOfWareroomsBins Then // Step 3.
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameSpecifyingSerialCells;
				ConfigureStepButtons("Back", "Create");
				Return;
			EndIf;
			
			NextToCreateDocumentFromRoomsAndCells();
			
		ElsIf Items.Steps.CurrentPage = Items.StepCreatedDocuments Then
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameCreatedDocuments;
				ConfigureStepButtons("Back", "Close");
				Return;
			EndIf;
			
			Close();
			
		EndIf;
		
	ElsIf MultipleDocuments Then // two-step redundancy
		
		If Items.Steps.CurrentPage = Items.StepByWarehouses
			And Items.GoodsTable.RowFilter.PageIndex = 0 Then // Step 1
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageNameOfStepToReservationByOrderTotal;
				ConfigureStepButtons("Cancel", "Next");
				Return;
			EndIf;
			
			NextToManyAppointments();
			
		ElsIf Items.Steps.CurrentPage = Items.StepByWarehouses
			And Items.GoodsTable.RowFilter.PageIndex = 1 Then // Step 2
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.ReservesByOrderAssignmentPageClarification;
			EndIf;
			
			If GoodsTable.Total("RequiresStepThroughRoomsCells") > 0 Then
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Back", "Next");
					Return;
				EndIf;
				
				NextToRoomsAndCells();
				
			Else
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Back", "CreateMultiple");
					Return;
				EndIf;
				
				NextToCreatingDocuments();
				
			EndIf;
			
		ElsIf Items.Steps.CurrentPage = Items.StepOfWareroomsBins Then // Step 3
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameSpecifyingSerialCells;
				ConfigureStepButtons("Back", "CreateMultiple");
				Return;
			EndIf;
			
			NextToCreateDocumentsFromRoomsAndCells();
			
		ElsIf Items.Steps.CurrentPage = Items.StepCreatedDocuments Then
		
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameCreatedDocuments;
				ConfigureStepButtons("Back", "Close");
				Return;
			EndIf;
			
			Close();
		
		EndIf;
		
	ElsIf Parameters.Master_2 Then // normal reservation or withdrawal of a reserve caused from an order
		
		If Items.Steps.CurrentPage = Items.StepByWarehouses Then // Step 1.
			
			If OnlyButtonSettings Then
				If OperationKind = TypeOfOperationCounterAdjustment Then
					Items.PagesStepName.CurrentPage = Items.PageNameOfPassStepByCounterCorrection;
				ElsIf OperationKind = OperationTypeReserve Or OperationKind = TypeOfOperationReserveAndAdjust Then
					Items.PagesStepName.CurrentPage = Items.PageNameOfReservationStep;
				Else
					Items.PagesStepName.CurrentPage = Items.PageNameOfStepToWithdrawReserve;
				EndIf;
			EndIf;
			
			If GoodsTable.Total("RequiresStepThroughRoomsCells") > 0 Then
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Cancel", "Next");
					Return;
				EndIf;
				
				NextToRoomsAndCells();
				
			Else
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Cancel", "Create");
					Return;
				EndIf;
				
				NextToCreatingDocument();
				
			EndIf;
			
		ElsIf Items.Steps.CurrentPage = Items.StepOfWareroomsBins Then // Step 2.
		
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameSpecifyingSerialCells;
				ConfigureStepButtons("Back", "Create");
				Return;
			EndIf;
			
			NextToCreateDocumentFromRoomsAndCells();
			
		ElsIf Items.Steps.CurrentPage = Items.StepCreatedDocuments Then
			
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameCreatedDocuments;
				ConfigureStepButtons("Back", "Close");
				Return;
			EndIf;
			
			Close();
			
		EndIf;
		
	Else // the usual reservation or withdrawal of a reserve on the command to fill in from the document Adjustment of the destination of goods
		
		If Items.Steps.CurrentPage = Items.StepByWarehouses Then // Step 1.
			
			If OnlyButtonSettings Then
				If OperationKind = OperationTypeReserve Or OperationKind = TypeOfOperationReserveAndAdjust Then
					Items.PagesStepName.CurrentPage = Items.PageNameOfReservationStep;
				Else
					Items.PagesStepName.CurrentPage = Items.PageNameOfStepToWithdrawReserve;
				EndIf;
			EndIf;
			
			If GoodsTable.Total("RequiresStepThroughRoomsCells") > 0 Then
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Cancel", "Next");
					Return;
				EndIf;
				
				NextToRoomsAndCells();
				
			Else
				
				If OnlyButtonSettings Then
					ConfigureStepButtons("Cancel", "MoveTo_");
					Return;
				EndIf;
				
					NextToTransferToDocument();
				
			EndIf;
			
		ElsIf Items.Steps.CurrentPage = Items.StepOfWareroomsBins Then // Step 2.
		
			If OnlyButtonSettings Then
				Items.PagesStepName.CurrentPage = Items.PageStepNameSpecifyingSerialCells;
				ConfigureStepButtons("Back", "MoveTo_");
				Return;
			EndIf;
			
			NextToTransferToDocumentFromRoomsAndCells();
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure ConfigureStepButtons(CodeBack, CodeNext)
	
	CancelCommand = Items.Cancel;
	NextCommand = Items.Next;
	
	If CodeBack = "Cancel" Then
		CancelCommand.Title = NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Anuluj';
									|tr = 'İptal'");
	ElsIf CodeBack = "Back" Then
		CancelCommand.Title = NStr("vi = '< Quay lại';
									|ru = '< Назад';
									|en = '< Back'; fa = '< بازگشت';
									|it = '< Indietro';
									|pl = '< Wróć';
									|tr = '< Geri'");
	EndIf;
		 
	If CodeNext = "Next" Then
		NextCommand.Title = NStr("vi = 'Tiếp theo >';
								|ru = 'Далее >';
								|en = 'Next >'; fa = 'بعدی >';
								|it = 'Avanti >';
								|pl = 'Dalej >';
								|tr = 'İleri >'");
		Items.TheTextWillBeCreatedByTheAdjustment.Visible = False;
	ElsIf CodeNext = "Create" Then
		NextCommand.Title = NStr("vi = 'Tạo chứng từ';
								|ru = 'Создать документ';
								|en = 'Create document'; fa = 'ایجاد سند';
								|it = 'Creare documento';
								|pl = 'Utwórz dokument';
								|tr = 'Belge oluştur'");
		Items.TheTextWillBeCreatedByTheAdjustment.Visible = True;
	ElsIf CodeNext = "CreateMultiple" Then
		NextCommand.Title = NStr("vi = 'Tạo chứng từ';
								|ru = 'Создать документы';
								|en = 'Create documents'; fa = 'ایجاد اسناد';
								|it = 'Creare documenti';
								|pl = 'Utwórz dokumenty';
								|tr = 'Belge oluştur'");
	ElsIf CodeNext = "MoveTo_" Then
		NextCommand.Title = NStr("vi = 'Chuyển vào chứng từ';
								|ru = 'Перенести в документ';
								|en = 'Add to document'; fa = 'افزودن به سند';
								|it = 'Trasferire nel documento';
								|pl = 'Przenieś do dokumentu';
								|tr = 'Belgeye taşı'");
		Items.TheTextWillBeCreatedByTheAdjustment.Visible = False;
	ElsIf CodeNext = "Close" Then
		NextCommand.Title = NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Close';
								|tr = 'Kapat'");
		Items.TheTextWillBeCreatedByTheAdjustment.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NextToCounterAdjustment()

	Error = Undefined;
	If Not NextToCounterAdjustmentServer(Error) Then
		ReportErrorsToUser(Error);
	Else
		ReFillCountInTotalsTable();
		CalculateTotalsByOrder();
	EndIf;
	
EndProcedure

&AtClient
Procedure NextToManyAppointments()

	Error = Undefined;
	If Not NextToManyAppointmentsServer(Error) Then
		ReportErrorsToUser(Error);
	Else
		ReFillCountInTotalsTable();
		CalculateTotalsByOrder();
	EndIf;

EndProcedure

&AtClient
Procedure NextToRoomsAndCells()
	
	Error = Undefined;
	If Not NextToRoomsAndCellsServer(Error) Then
		ReportErrorsToUser(Error);
	Else
		For Each String In CellPlacementTree.GetItems() Do
			Items.CellPlacementTree.Expand(String.GetID(), True);
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure NextToCreatingDocument()
	
	Error = Undefined;
	Result = NextToCreatingDocumentServer(Error, Undefined);
	If Result = False Then
		ReportErrorsToUser(Error);
		NextOnClient(True);
	ElsIf TypeOf(Result) = Type("Structure") Then
		ShowUserNotification(NStr("vi = 'Đã tạo điều chỉnh mục đích hàng hóa';
									|ru = 'Создана корректировка назначения товаров';
									|en = 'Inventory assignment adjustment is created'; fa = 'Inventory assignment adjustment is created';
									|it = 'È stata creata la rettifica dell''assegnazione della merce';
									|pl = 'Utworzono zapis korygujący przeznaczenia towarów';
									|tr = 'Ürün atama düzeltmesi oluşturuldu'"),
			GetURL(Result.Ref),
			Result.Ref);
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure NextToCreatingDocuments()
	
	ClearMessages();
	Error = Undefined;
	Result = NextToCreatingDocumentsServer(Error);
	If Result = False Then
		ReportErrorsToUser(Error);
	Else
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(Result,
			New CallbackDescription("NextToCreatingDocumentsCompletion", ThisObject, Undefined),
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NextToTransferToDocument()
	
	Error = Undefined;
	Result = NextToTransferToDocumentServer(Error, Undefined);
	If Result = False Then
		ReportErrorsToUser(Error);
	Else
		NotifyChoice(New Structure("GoodsTable, OperationKind", Result.AddressInStorage, OperationKind));
		If Result.ThereIsWarning Then
			ShowUserNotification(,,Error,PictureLib.Information32);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NextToCreateDocumentFromRoomsAndCells()
	
	Error = Undefined;
	Result = NextToCreateDocumentFromRoomsAndCellsServer(Error);
	If Result = False Then
		ReportErrorsToUser(Error);
	ElsIf TypeOf(Result) = Type("Structure") Then
		ShowUserNotification(NStr("vi = 'Đã tạo điều chỉnh mục đích hàng hóa';
									|ru = 'Создана корректировка назначения товаров';
									|en = 'Inventory assignment adjustment is created'; fa = 'Inventory assignment adjustment is created';
									|it = 'È stata creata la rettifica dell''assegnazione della merce';
									|pl = 'Utworzono zapis korygujący przeznaczenia towarów';
									|tr = 'Ürün atama düzeltmesi oluşturuldu'"),
			GetURL(Result.Ref),
			Result.Ref);
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure NextToCreateDocumentsFromRoomsAndCells()
	
	Error = Undefined;
	Result = NextToCreateDocumentsFromRoomsAndCellsServer(Error);
	If Result = False Then
		ReportErrorsToUser(Error);
	Else
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(Result,
			New CallbackDescription("NextToCreatingDocumentsCompletion", ThisObject, Undefined),
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NextToTransferToDocumentFromRoomsAndCells()
	
	Error = Undefined;
	Result = NextToTransferToDocumentFromRoomsAndCellsServer(Error);
	If Result = False Then
		ReportErrorsToUser(Error);
	Else
		NotifyChoice(New Structure("GoodsTable, OperationKind", Result.AddressInStorage, OperationKind));
		If Result.ThereIsWarning Then
			ShowUserNotification(,,Error,PictureLib.Information32);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ReportErrorsToUser(Error)
	
	If TypeOf(Error) = Type("Array") Then
		For Each CurError In Error Do
			CommonClient.MessageToUser(CurError);
		EndDo;
	Else
		ShowMessageBox(, Error);
	EndIf;
	
EndProcedure

&AtServer
Function NextToCounterAdjustmentServer(Error)
	
	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;	
	
	If RecalculateCountForPageIndex1 Then
		FillInAmountOfCounterAdjustment();
		RecalculateCountForPageIndex1 = False;
	EndIf;
	
	FilterStructure1 = New Structure(Items.GoodsTable.RowFilter);
	FilterStructure1.PageIndex = 1;
	SetRowSelectionTableProducts(Items, FilterStructure1);
	AdjustElementsByCounterAdjustmentStep();
	
	Return True;
	
EndFunction

&AtServer
Function NextToManyAppointmentsServer(Error)
	
	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;
	
	If RecalculateCountForPageIndex1 Then
		FillQuantityForManyAppointments();
		RecalculateCountForPageIndex1 = False;
	EndIf;
	
	FilterStructure1 = New Structure(Items.GoodsTable.RowFilter);
	FilterStructure1.PageIndex = 1;
	SetRowSelectionTableProducts(Items, FilterStructure1);
	CustomizeItemsByStepOfManyAssignments();
	
	Return True;

EndFunction

&AtServer
Function NextToRoomsAndCellsServer(Error)

	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;	
	
	FillInTree();
	
	Items.Steps.CurrentPage = Items.StepOfWareroomsBins;
	
	Return True;
	
EndFunction

&AtServer
Function NextToCreatingDocumentServer(Error, TableToTransfer)
	
	If TableToTransfer = Undefined Then
		TableToTransfer = GoodsTable;
	EndIf;
	
	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;
	
	RowsArray = New Array();
	
	For Each String In TableToTransfer Do
		If String.Count > 0 And String.Mark And String.PageIndex = 0 Then
			RowsArray.Add(String);
		EndIf;
	EndDo;
	If TypeOf(TableToTransfer) = Type("FormDataCollection") Then
		ItemsToTransfer = TableToTransfer.Unload(RowsArray);
	Else
		ItemsToTransfer = TableToTransfer.Copy(RowsArray);
	EndIf;
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment Then
	
		RowFilter = New Structure("Mark, PageIndex", True, 1);
		If TypeOf(TableToTransfer) = Type("FormDataCollection") Then
			DistributionTable_1 = TableToTransfer.Unload(RowFilter);
		Else
			DistributionTable_1 = TableToTransfer.Copy(RowFilter);
		EndIf;
		
		ItemsToTransfer = Documents.InventoryAssignmentAdjustment.DistributeCounterAdjustmentGoods(
			ItemsToTransfer, DistributionTable_1);
	EndIf;
	
	Documents.InventoryAssignmentAdjustment.AddControlledLotReferencesToTable(ItemsToTransfer, AssignmentAdjustment);
	
	HeaderAttributes = New Structure("OperationKind,Organization,Purpose");
	FillPropertyValues(HeaderAttributes, ThisObject);
	DocumentCreationResult = Documents.InventoryAssignmentAdjustment.CreateFillAndNavigateDocument(
		HeaderAttributes,
		ItemsToTransfer);
	If DocumentCreationResult.Posted Then
		Result = New Structure("Ref", DocumentCreationResult.Document);
		Return Result;
	Else
		For Each DocumentError In DocumentCreationResult.Errors Do
			Common.MessageToUser(DocumentError.Text, DocumentCreationResult.Document);
		EndDo;
		
		DownloadableDocuments = CommonClientServer.ValueInArray(DocumentCreationResult.Document);
		DocumentsList.LoadValues(DownloadableDocuments);
		
		CommonClientServer.SetDynamicListFilterItem(
			CreatedDocuments,
			"Ref",
			DocumentsList.UnloadValues(),
			DataCompositionComparisonType.InList,
			,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
			
		Items.Steps.CurrentPage = Items.StepCreatedDocuments;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function DistributeSourcesToReceivers(TableToTransfer = Undefined)
	
	If TypeOf(TableToTransfer) = Type("FormDataCollection") Then
		Sources = TableToTransfer.Unload(New Structure("PageIndex,Mark", 0, True));
		Destinations = TableToTransfer.Unload(New Structure("PageIndex,Mark", 1, True));
	Else
		Sources = TableToTransfer.Copy(New Structure("PageIndex,Mark", 0, True));
		Destinations = TableToTransfer.Copy(New Structure("PageIndex,Mark", 1, True));
	EndIf;
	
	ListOfItems = Destinations.UnloadColumn("Products");
	ProductLocations = Documents.InventoryAssignmentAdjustment.ProductLocationsAccordingToItemList(ListOfItems);
	Sources.Columns.Add("KeyProductLocations", New TypeDescription("UUID"));
	Sources.Columns.Add("Ignore", New TypeDescription("Boolean"));
	CargoPackagingTable = Sources.CopyColumns();
	
	If ProductLocations.Count() > 0 Then
		
		// Transfer of items to a separate table.
		Sources.Sort("Products,Characteristic,InitialAssignment,Warehouse,Series,Premise,Cell");
		GroupingKey = New Structure("InitialAssignment,Products,Characteristic,Warehouse,Series,Premise");
		KeyProductLocations = Undefined;
		
		For IndexOf = 0 To Sources.Count() - 1 Do
			
			TableRow = Sources[IndexOf];
			TableRow.Ignore = False;
			
			Packages = ProductLocations[TableRow.Products];
			If Packages <> Undefined And Packages[TableRow.Package] <> Undefined Then
				
				If GroupingKey.InitialAssignment <> TableRow.InitialAssignment
						Or GroupingKey.Products <> TableRow.Products
						Or GroupingKey.Characteristic <> TableRow.Characteristic
						Or GroupingKey.Warehouse <> TableRow.Warehouse
						Or GroupingKey.Series <> TableRow.Series
						Or GroupingKey.Premise <> TableRow.Premise Then
						
						FillPropertyValues(GroupingKey, TableRow);
						KeyProductLocations = New UUID();
						
				Else
					
					TableRow.Ignore = True;
					
				EndIf;
				
				TableRow.KeyProductLocations = KeyProductLocations;
				NewRow = CargoPackagingTable.Add();
				FillPropertyValues(NewRow, TableRow);
				
			EndIf;
			
		EndDo;
		
		Sources = Sources.Copy(New Structure("Ignore", False));
		CargoPackagingTable.Indexes.Add("KeyProductLocations");
		
	EndIf;
	
	// The distribution of the quantity from the receiver table between the quantities from the source table.
	ItemsToTransfer = Sources.CopyColumns();
	Destinations.Sort("NewAssignment");
	
	KeyFields = "Products,Characteristic";
	Sources.Indexes.Add(KeyFields);
	
	Sources.Columns.Add("CurrentIndex", New TypeDescription("Number"));
	
	Var_Key = New Structure(KeyFields);
	For Each TableRow In Destinations Do
		
		FillPropertyValues(Var_Key, TableRow);
		ProductSources = Sources.FindRows(Var_Key);
		
		If ProductSources.Count() = 0 Then
			Continue;
		EndIf;
		
		IndexOf = ProductSources[0].CurrentIndex;
		While TableRow.Count > 0 Do
			
			If ProductSources[IndexOf].Count = 0 And IndexOf = ProductSources.Count() - 1 Then
				Break;
			EndIf;
			
			While ProductSources[IndexOf].Count = 0 Do
				IndexOf = IndexOf + 1;
			EndDo;
			
			Count = Min(ProductSources[IndexOf].Count, TableRow.Count);
			ProductSources[IndexOf].Count = ProductSources[IndexOf].Count - Count;
			TableRow.Count = TableRow.Count - Count;
			
			Packages = ProductLocations[ProductSources[IndexOf].Products];
			If Packages <> Undefined And Packages[ProductSources[IndexOf].Package] <> Undefined Then
				
				FoundRowsAreProductLocations = CargoPackagingTable.FindRows(
					New Structure("KeyProductLocations", ProductSources[IndexOf].KeyProductLocations));
				
				For Each ProductLocationsLine In FoundRowsAreProductLocations Do
					
					NewRow = ItemsToTransfer.Add();
					FillPropertyValues(NewRow, ProductLocationsLine);
					NewRow.Count = Count; // completeness has already been checked before, before distribution.
					NewRow.NewAssignment = TableRow.NewAssignment;
					
				EndDo;
				
			Else
				
				NewRow = ItemsToTransfer.Add();
				FillPropertyValues(NewRow, ProductSources[IndexOf]);
				NewRow.Count = Count;
				NewRow.NewAssignment = TableRow.NewAssignment;
				
			EndIf;
			
		EndDo;
		ProductSources[0].CurrentIndex = IndexOf;
		
	EndDo;
	Return ItemsToTransfer;
	
EndFunction

&AtServer
Function NextToCreatingDocumentsServer(Error)
	
	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;
	
	ItemsToTransfer = DistributeSourcesToReceivers(GoodsTable);
	Documents.InventoryAssignmentAdjustment.AddControlledLotReferencesToTable(ItemsToTransfer, AssignmentAdjustment);
	
	DocumentsList.Clear();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo chứng từ ""Điều chỉnh mục đích hàng hóa""';
														|ru = 'Создание документов ""Корректировка назначения товаров""';
														|en = 'Create the ""Inventory assignment adjustment"" documents'; fa = 'Create the ""Inventory assignment adjustment"" documents';
														|it = 'Creazione di documenti ""Rettifica delle assegnazioni delle merci""';
														|pl = 'Utworzenie dokumentów ""Korekta przeznaczenia towarów""';
														|tr = '""Stok atama düzeltmesi"" belgelerinin oluşturulması'");
	ProcedureParameters = New Structure("OperationKind,Organization");
	FillPropertyValues(ProcedureParameters, ThisObject);
	ProcedureParameters.Insert("ItemsToTransfer", ItemsToTransfer);
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"DataProcessors.AssignmentAdjustmentFilling.CreateDocumentsInBackground",
		ProcedureParameters);
	
EndFunction

&AtClient
Procedure NextToCreatingDocumentsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	ElsIf Result.Status = "Error" Then
		
		ShowMessageBox(, Result.BriefErrorDescription);
		
	Else
		
		NextToCreatingDocumentsCompletionServer(Result.ResultAddress);
		
	EndIf;
	NextOnClient(True);
	
EndProcedure

&AtServer
Procedure NextToCreatingDocumentsCompletionServer(ResultAddress)
	
	DocumentCreationResult_ = GetFromTempStorage(ResultAddress);
	For Each DocumentErrors In DocumentCreationResult_.Errors Do
		For Each DocumentError In DocumentErrors.Errors Do
			Common.MessageToUser(DocumentError.Text, DocumentErrors.Document);
		EndDo;
	EndDo;
	
	DocumentsList.LoadValues(DocumentCreationResult_.Documents);
	
	CommonClientServer.SetDynamicListFilterItem(
		CreatedDocuments,
		"Ref",
		DocumentsList.UnloadValues(),
		DataCompositionComparisonType.InList,
		,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
		
	Items.Steps.CurrentPage = Items.StepCreatedDocuments;

EndProcedure

&AtServer
Function NextToCreateDocumentFromRoomsAndCellsServer(Error)
	
	If Not YouCanTransferTreeDataToTable(Error) Then
		Return False;
	EndIf;
	TableToTransfer = MoveTreeDataToTable();
	Return NextToCreatingDocumentServer(Error, TableToTransfer);
	
EndFunction

&AtServer
Function NextToCreateDocumentsFromRoomsAndCellsServer(Error)
	
	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;
	
	If Not YouCanTransferTreeDataToTable(Error) Then
		Return False;
	EndIf;
	
	TableToTransfer = MoveTreeDataToTable();
	ItemsToTransfer = DistributeSourcesToReceivers(TableToTransfer);
	Documents.InventoryAssignmentAdjustment.AddControlledLotReferencesToTable(ItemsToTransfer, AssignmentAdjustment);
	
	DocumentsList.Clear();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo chứng từ ""Điều chỉnh mục đích hàng hóa""';
														|ru = 'Создание документов ""Корректировка назначения товаров""';
														|en = 'Create the ""Inventory assignment adjustment"" documents'; fa = 'Create the ""Inventory assignment adjustment"" documents';
														|it = 'Creazione di documenti ""Rettifica delle assegnazioni delle merci""';
														|pl = 'Utworzenie dokumentów ""Korekta przeznaczenia towarów""';
														|tr = '""Stok atama düzeltmesi"" belgelerinin oluşturulması'");
	ProcedureParameters = New Structure("OperationKind,Organization");
	FillPropertyValues(ProcedureParameters, ThisObject);
	ProcedureParameters.Insert("ItemsToTransfer", ItemsToTransfer);
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"DataProcessors.AssignmentAdjustmentFilling.CreateDocumentsInBackground",
		ProcedureParameters);
	
EndFunction

&AtServer
Function NextToTransferToDocumentServer(Error, Val TableToTransfer)
	
	If Not ThereAreSelectedRows() Then
		Error = NStr("vi = 'Chưa chọn dòng nào có số lượng được điền.';
					|ru = 'Ни одна строка, с заполненным количеством, не выбрана.';
					|en = 'Line with populated quantity is not selected.'; fa = 'Line with populated quantity is not selected.';
					|it = 'Non è stata selezionata nessuna riga con quantità compilata.';
					|pl = 'Nie wybrano ani jednego wierszu z wypełnioną ilością.';
					|tr = 'Miktarın doldurulduğu hiçbir satır seçilmedi.'");
		Return False;
	EndIf;
	
	If TableToTransfer = Undefined Then
		TableToTransfer = GoodsTable.Unload();
	EndIf;
	
	Documents.InventoryAssignmentAdjustment.AddControlledLotReferencesToTable(TableToTransfer, AssignmentAdjustment);
	
	AddressInStorage = PutProductsInStorage(Error, TableToTransfer);
	If AddressInStorage = Undefined Then
		Return False;
	EndIf;
	ThereIsWarning = ValueIsFilled(Error);
	Result = New Structure("ThereIsWarning,AddressInStorage", ThereIsWarning, AddressInStorage);
	Return Result;

EndFunction

&AtServer
Function NextToTransferToDocumentFromRoomsAndCellsServer(Error)
	
	If Not YouCanTransferTreeDataToTable(Error) Then
		Return False;
	EndIf;
	TableToTransfer = MoveTreeDataToTable();
	Return NextToTransferToDocumentServer(Error, TableToTransfer);
	
EndFunction

&AtServer
Procedure FillInRequiredStepByRoomsCells()
	
	For Each String In GoodsTable Do
		FillInRequiredStepByRoomsCellsInRow(String);
	EndDo; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInRequiredStepByRoomsCellsInRow(String)

	String.RequiresStepThroughRoomsCells = ?(
		(String.UseOfCellPremises Or String.UsingSeries)
			And String.Mark And String.Count > 0, 1, 0);

EndProcedure

&AtServer
Procedure FillInUseOfCellRooms()
	
	MostOfGoods = GoodsTable.Unload(, "Products,InitialAssignment,NewAssignment,Warehouse");
	Selection = Documents.InventoryAssignmentAdjustment.SpecifyingNumberOfSeriesCellsForRow(MostOfGoods);
	While Selection.Next() Do
		
		String = GoodsTable[Selection.LineNumber - 1];
		String.UsingSeries = Selection.KeepAccountingByBatch;
		String.UseOfCellPremises = Selection.UseWarerooms
			Or Selection.UseBinLocationWarehousing;
		
	EndDo;
	
EndProcedure

&AtServer
Function ThereAreSelectedRows()
	
	Result = False;
	For Each String In GoodsTable Do
		If String.PageIndex = 0 And String.Mark And String.Count > 0 Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

&AtClient
Procedure CancelCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Close();
	
EndProcedure

&AtServer
Function MoveTreeDataToTable()
	
	DestinationTable = GoodsTable.Unload();
	TheStructureOfTheSearch = New Structure("InitialAssignment,Products,Characteristic,Warehouse");
	
	For Each Root In CellPlacementTree.GetItems() Do
		
		FillPropertyValues(TheStructureOfTheSearch, Root);
		TheStructureOfTheSearch.InitialAssignment = Root.Purpose;
		
		Branches = Root.GetItems();
		
		If Branches.Count() > 0 Then
			FoundRows = DestinationTable.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() > 0 Then
				
				For Each Branch In Branches Do
					
					If Branch.Mark And Branch.Count > 0 Then
						NewRow = DestinationTable.Add();
						FillPropertyValues(NewRow, FoundRows[0]);
						FillPropertyValues(NewRow, Branch, "Premise, Cell, Series, Package, Count, Mark");
					EndIf;
					
					For Each CellBranch In Branch.GetItems() Do
						
						If CellBranch.Mark And CellBranch.Count > 0 Then
							NewRow = DestinationTable.Add();
							FillPropertyValues(NewRow, FoundRows[0]);
							FillPropertyValues(NewRow, CellBranch, "Premise, Cell, Package, Count, Mark");
							NewRow.Series = Branch.Series;
						EndIf;
						
					EndDo;
					
				EndDo;
				
				For Each FoundRow In FoundRows Do
					DestinationTable.Delete(FoundRow);
				EndDo;
					
			EndIf;
		EndIf;
		
	EndDo;
	
	Return DestinationTable;
	
EndFunction

#EndRegion

#Region FillingTables

&AtServer
Procedure FillInTable()
	
	FilterByCompany = ?(OrganizationOrdersOnly, Organization, Undefined);
	
	Table = Undefined;
	TableOfResults = Undefined;
	TableOfTotalsOfSourcesOfProvision = New ValueTable();
	If MultipleAppointments And OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
		
		Sources = New Structure("WarehouseStockBalance,ProvisionsForAppointments", True , False);
		Tables = Documents.InventoryAssignmentAdjustment.ReservationTable(
			Assignments.UnloadValues(),
			Sources,
			FilterReservationByShippingWarehouse,
			Undefined,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
			
		Table = Tables.TableOfGoods;
		Items.DecorationNoLeftovers.Visible = Table.Count() = 0;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		TableOfTotalsOfSourcesOfProvision = Tables.TableOfTotalsOfSourcesOfProvision;
		
		MultiPurposeTable = Documents.InventoryAssignmentAdjustment.MultiPurposeTable(
			Assignments.UnloadValues(),
			FilterReservationByShippingWarehouse,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
		
		Table.Columns.Add("PageIndex");
		Table.Columns.Add("Supplied");
		For Counter = 1 To MultiPurposeTable.Count() Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, MultiPurposeTable[Counter - 1]);
			NewRow.PageIndex = 1;
		EndDo;
		
		TMCommonUse.AddRowsToTable(TableOfResults, MultiPurposeTable);
		
	ElsIf MultipleAppointments And OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
		
		Sources = New Structure("WarehouseStockBalance,ProvisionsForAppointments", Not OrganizationOrdersOnly, True);
		Tables = Documents.InventoryAssignmentAdjustment.ReservationTable(
			Assignments.UnloadValues(),
			Sources,
			FilterReservationByShippingWarehouse,
			FilterByCompany,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
			
		Table = Tables.TableOfGoods;
		Items.DecorationNoLeftovers.Visible = Table.Count() = 0;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		TableOfTotalsOfSourcesOfProvision = Tables.TableOfTotalsOfSourcesOfProvision;
		
		MultiPurposeTable = Documents.InventoryAssignmentAdjustment.MultiPurposeTable(
			Assignments.UnloadValues(),
			FilterReservationByShippingWarehouse,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
		
		Table.Columns.Add("PageIndex");
		Table.Columns.Add("Supplied");
		For Counter = 1 To MultiPurposeTable.Count() Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, MultiPurposeTable[Counter - 1]);
			NewRow.PageIndex = 1;
		EndDo;
		
		TMCommonUse.AddRowsToTable(TableOfResults, MultiPurposeTable);
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
		
		Tables = Documents.InventoryAssignmentAdjustment.ReserveWithdrawalTable(
			Purpose,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
		
		Table = Tables.TableOfGoods;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		
		Tables = Documents.InventoryAssignmentAdjustment.TableOfWithdrawalOfReserveForManyPurposes(
			FilterByCompany,
			GoodsFilter.Unload(),
			AssignmentAdjustment,
			Assignments.UnloadValues());
		Table = Tables.TableOfGoods;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
		
		Sources = New Structure("WarehouseStockBalance,ProvisionsForAppointments", True, False);
		Tables = Documents.InventoryAssignmentAdjustment.ReservationTable(
			Purpose,
			Sources,
			FilterReservationByShippingWarehouse,
			Undefined,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
		Table = Tables.TableOfGoods;
		Items.DecorationNoLeftovers.Visible = Table.Count() = 0;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		TableOfTotalsOfSourcesOfProvision = Tables.TableOfTotalsOfSourcesOfProvision;
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
		
		Sources = New Structure("WarehouseStockBalance,ProvisionsForAppointments", Not OrganizationOrdersOnly, True);
		Tables = Documents.InventoryAssignmentAdjustment.ReservationTable(
			Purpose,
			Sources,
			FilterReservationByShippingWarehouse,
			FilterByCompany,
			GoodsFilter.Unload(),
			AssignmentAdjustment);
		Table = Tables.TableOfGoods;
		Items.DecorationNoLeftovers.Visible = Table.Count() = 0;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		TableOfTotalsOfSourcesOfProvision = Tables.TableOfTotalsOfSourcesOfProvision;
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment Then
		
		Sources = New Structure("WarehouseStockBalance,ProvisionsForAppointments", True, True);
		Tables = Documents.InventoryAssignmentAdjustment.ReservationTable(
			Purpose,
			Sources,
			FilterReservationByShippingWarehouse,
			FilterByCompany,
			GoodsFilter.Unload(New Structure("ByAssignment", 2)),
			AssignmentAdjustment);
		Table = Tables.TableOfGoods;
		TableOfResults = Tables.TableOfResults;
		SummaryTotalsTable = Tables.SummaryTotalsTable;
		TableOfTotalsOfSourcesOfProvision = Tables.TableOfTotalsOfSourcesOfProvision;
		
		Tables = Documents.InventoryAssignmentAdjustment.ReserveWithdrawalTable(
			Purpose,
			GoodsFilter.Unload(New Structure("ByAssignment", 1)),
			AssignmentAdjustment);
		
		Table.Columns.Add("PageIndex");
		For Counter = 1 To Tables.TableOfGoods.Count() Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, Tables.TableOfGoods[Counter - 1]);
			NewRow.PageIndex = 1;
		EndDo;
		
		TMCommonUseClientServer.SupplementTable(Tables.TableOfResults, TableOfResults);
		TMCommonUseClientServer.SupplementTable(Tables.SummaryTotalsTable, SummaryTotalsTable);
		
	EndIf;
	
	FieldNameForCommunication = "IDOfSourceTotalsRow";
	
	GroupingRows = "InitialAssignment,Products,Characteristic";
	ResultsOfSourcesOfProvision.Load(TableOfTotalsOfSourcesOfProvision);
	
	Table.Columns.Add(FieldNameForCommunication);
	Table.Indexes.Add(GroupingRows);
	BindTableRowsToTableTotals(Table, ResultsOfSourcesOfProvision, GroupingRows, FieldNameForCommunication);
	
	FieldNameForCommunication = "TotalLineID";
	
	GroupingRows = "AssignmentForTotals";
	TableOfTotalsByAppointment = TableOfResults.Copy(, GroupingRows); // ValueTable
	TableOfTotalsByAppointment.GroupBy(GroupingRows);
	ResultsByAppointment.Load(TableOfTotalsByAppointment);
	
	TableOfResults.Columns.Add(FieldNameForCommunication);
	TableOfResults.Indexes.Add(GroupingRows);
	BindTableRowsToTableTotals(TableOfResults, ResultsByAppointment, GroupingRows, FieldNameForCommunication);
	
	SummaryTotalsTable.Columns.Add(FieldNameForCommunication);
	SummaryTotalsTable.Indexes.Add(GroupingRows);
	BindTableRowsToTableTotals(SummaryTotalsTable, ResultsByAppointment, GroupingRows, FieldNameForCommunication);
	
	FieldNameForCommunication = "IDOfSummaryTotalsRow";
	
	GroupingRows = "Products,Characteristic,AssignmentForTotals";
	SummaryOfProductResults.Load(SummaryTotalsTable);
	
	TableOfResults.Columns.Add(FieldNameForCommunication);
	TableOfResults.Indexes.Add(GroupingRows);
	BindTableRowsToTableTotals(TableOfResults, SummaryOfProductResults, GroupingRows, FieldNameForCommunication);
	ProductResults.Load(TableOfResults);
	
	FieldNameForCommunication = "TotalLineID";
	
	GroupingRows = "Products,Characteristic,Warehouse,AssignmentForTotals";
	Table.Columns.Add(FieldNameForCommunication);
	Table.Indexes.Add(GroupingRows);
	BindTableRowsToTableTotals(Table, ProductResults, GroupingRows, FieldNameForCommunication);
	
	FieldNameForCommunication = "IDOfMultiAssignmentTotalsRow";
	GroupingRows = "Products,Characteristic,AssignmentForTotals";
	Table.Columns.Add(FieldNameForCommunication);
	Table.FillValues(-1, FieldNameForCommunication);
	Table.Indexes.Add(GroupingRows);
	TotalsOfGoodsForManyPurposes = ProductResults.FindRows(New Structure("Warehouse", Catalogs.Warehouses.EmptyRef()));
	BindTableRowsToTableTotals(Table, TotalsOfGoodsForManyPurposes, GroupingRows, FieldNameForCommunication);
	
	Table.Columns.Add("SatisfiesTheFilter");
	Table.FillValues(True, "SatisfiesTheFilter");
	GoodsTable.Load(Table);
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve
			Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		
		Documents.InventoryAssignmentAdjustment.WithdrawReserves(GoodsTable, Not ToggleSwitchRemoveReserves, TableOfResults);
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_
		Or  OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
		
		Documents.InventoryAssignmentAdjustment.EstablishReserves(
			GoodsTable, TableOfResults, Not FilterReservationByShippingWarehouse);
		
	EndIf;
	RecalculateCountForPageIndex1 = True;
	FillPictureWithExcessSource();
	ReFillCountInTotalsTable();
	FillInUseOfCellRooms();
	FillInRequiredStepByRoomsCells();
	
EndProcedure

&AtServer
Procedure FillInTree()
	
	TreeItems = CellPlacementTree.GetItems();
	TreeItems.Clear();
	
	Marked_Goods = GoodsTable.Unload(New Structure("Mark", True));
	CellRoomTable = Documents.InventoryAssignmentAdjustment.TableOfCellPlacementByProduct(Marked_Goods, AssignmentAdjustment);
	Marked_Goods.GroupBy("Products");
	ListOfItems = Marked_Goods.UnloadColumn("Products");
	ProductLocations = Documents.InventoryAssignmentAdjustment.ProductLocationsAccordingToItemList(ListOfItems);
	
	FillingStructure = New Structure("Purpose,Products,Characteristic,Warehouse");
	CurSeries_ = Undefined;
	
	BranchesOfBatchesForCalculationAreProvided = New Array();
	For Each String In CellRoomTable Do
		
		If Not ValueIsFilled(String.Series) And Not ValueIsFilled(String.Premise) And Not ValueIsFilled(String.Cell) Then
			Continue;
		EndIf;
		
		If FillingStructure.Purpose <> String.Purpose
			Or FillingStructure.Products <> String.Products
			Or FillingStructure.Characteristic <> String.Characteristic
			Or FillingStructure.Warehouse <> String.Warehouse Then
			
			FillPropertyValues(FillingStructure, String);
			CurSeries_ = Undefined;
			
			NewRoot = TreeItems.Add();
			FillPropertyValues(NewRoot, String, , "Series,Premise,Cell");
			NewRoot.Supplied = String.AvailableStock;
			NewRoot.ProvidedOnControl = String.FreeBalanceUnderControl;
			NewRoot.NumberOfPackages = String.Count;
			NewRoot.Package = String.ProductsUnitOfMeasure;
			
			NewRoot.ThisIsRoot = True;
			RootStrings = NewRoot.GetItems();
			
		EndIf;
		
		If String.ThereAreCells Then
			
			If String.ThereAreSeries Then
				If CurSeries_ <> String.Series Then
					
					CurSeries_ = String.Series;
					NewBranchOfSeries = RootStrings.Add();
					NewBranchOfSeries.Series = String.Series;
					NewBranchOfSeries.Package = String.ProductsUnitOfMeasure;
					NewBranchOfSeries.Supplied = - String.SeriesReadyForShipment;
					NewBranchOfSeries.ProvidedOnControl = - String.SeriesToBeShippedUnderControl;
					NewBranchOfSeries.TheseAreSeries = True;
					NewBranchOfSeries.Products = String.Products;
					BranchesOfBatchesForCalculationAreProvided.Add(NewBranchOfSeries);
					
				EndIf;
			Else
				NewBranchOfSeries = NewRoot;
			EndIf;
			
			NewBranch_ = NewBranchOfSeries.GetItems().Add();
			NewBranch_.TheseAreCells = True;
			FillPropertyValues(
				NewBranch_,
				String,
				"Products,
				|Premise,
				|Cell,
				|Package,
				|Supplied,
				|SecuredUnits,
				|ProvidedOnControl,
				|SecuredUnitsUnderControl");
				
			NewBranch_.SecuredUnits = NewBranch_.SecuredUnits - NewBranch_.SecuredUnitsUnderControl;
			
		Else
			
			NewBranchOfSeries = RootStrings.Add();
			NewBranchOfSeries.Series = String.Series;
			NewBranchOfSeries.Package = String.ProductsUnitOfMeasure;
			NewBranchOfSeries.Supplied = String.SecuredUnits - String.SeriesReadyForShipment;
			NewBranchOfSeries.ProvidedOnControl = String.SecuredUnitsUnderControl - String.SeriesToBeShippedUnderControl;
			NewBranchOfSeries.SecuredUnits = NewBranchOfSeries.Supplied;
			NewBranchOfSeries.SecuredUnitsUnderControl = NewBranchOfSeries.ProvidedOnControl;
			NewBranchOfSeries.TheseAreCells = True;
			
			NewBranchOfSeries.SecuredUnits = NewBranchOfSeries.SecuredUnits - NewBranchOfSeries.SecuredUnitsUnderControl;
			
		EndIf;
		
	EndDo;
	
	For Each NewBranchOfSeries In BranchesOfBatchesForCalculationAreProvided Do
		
		ProductPackages = ProductLocations.Get(NewBranchOfSeries.Products);
		CalculateProvidedByBatchCells(NewBranchOfSeries, ProductPackages);
		
		NewBranchOfSeries.SecuredUnits = NewBranchOfSeries.SecuredUnits - NewBranchOfSeries.SecuredUnitsUnderControl;
		Cells = NewBranchOfSeries.GetItems();
		For Each CellRow In Cells Do
			CellRow.SecuredUnits = CellRow.SecuredUnits - CellRow.SecuredUnitsUnderControl;
		EndDo;
		
	EndDo;
	
	// Deleting lines in which there is nothing to specify.
	GoodsQuantity = TreeItems.Count();
	For ProductCounter = 1 To GoodsQuantity Do
		
		RowOfProduct = TreeItems[GoodsQuantity - ProductCounter];
		
		SetOfSeries = RowOfProduct.GetItems();
		SeriesCount = SetOfSeries.Count();
		For SeriesCounter = 1 To SeriesCount Do
			
			RowSeries = SetOfSeries[SeriesCount - SeriesCounter];
			
			Cells = RowSeries.GetItems();
			NumberOfBins = Cells.Count();
			For CellCounter = 1 To NumberOfBins Do
				
				CellRow = Cells[NumberOfBins - CellCounter];
				
				// Processing of cells.
				If CellRow.SecuredUnits = 0 Then
					Cells.Delete(CellRow);
				EndIf;
				
			EndDo;
			
			// Processing of series.
			If RowSeries.Supplied <= 0 Then
				SetOfSeries.Delete(RowSeries);
			EndIf;
			
		EndDo;
		
		// Processing of goods.
		If SetOfSeries.Count() = 0 Then
			TreeItems.Delete(RowOfProduct);
		EndIf;
		
	EndDo;
	
	// Filling in the quantity.
	GoodsQuantity = TreeItems.Count();
	For ProductCounter = 0 To GoodsQuantity - 1 Do
		
		RowOfProduct = TreeItems[ProductCounter];
		ProductPackages = ProductLocations.Get(RowOfProduct.Products);
		
		DistributeByProduct = RowOfProduct.Count;
		WithProvenQuality = RowOfProduct.Supplied - String.FreeBalanceUnderControl;
		
		SetOfSeries = RowOfProduct.GetItems();
		SeriesCount = SetOfSeries.Count();
		
		DistributeInCurrentPass = 0;
		
		For AisleNumber = 1 To 2 Do
			
			// If you manually specified quantities
			// greater than the free Balance of the verified goods in the "Goods" step of the assistant, then you must use the unchecked Balance.
			DistributeInCurrentPass = DistributeByProduct - ?(AisleNumber = 1, Max(0, DistributeByProduct - WithProvenQuality), 0);
			DistributeByProduct = DistributeByProduct - DistributeInCurrentPass;
			
			PostfixOfName = ?(AisleNumber = 1, "", "UnderControl");
			FieldName = "SecuredUnits" + PostfixOfName;
			
			// If the series are not used, then the Series branch is in fact a branch of cells.
			DistributedToProductLocations = DistributeToGoodsPlaces(
				Max(0, DistributeInCurrentPass), SetOfSeries, ProductPackages, PostfixOfName);
			DistributeInCurrentPass = DistributeInCurrentPass - DistributedToProductLocations;
			
			For SeriesCounter = 0 To SeriesCount - 1 Do
				
				RowSeries = SetOfSeries[SeriesCounter];
				DistributeBySeries = RowSeries[FieldName];
				
				Cells = RowSeries.GetItems();
				NumberOfBins = Cells.Count();
				DistributedToProductLocations = DistributeToGoodsPlaces(
					Max(0, Min(DistributeInCurrentPass, DistributeBySeries)), Cells, ProductPackages, PostfixOfName);
				DistributeInCurrentPass = DistributeInCurrentPass - DistributedToProductLocations;
				DistributeBySeries = DistributeBySeries - DistributedToProductLocations;
				
				For CellCounter = 0 To NumberOfBins - 1 Do
					
					CellRow = Cells[CellCounter];
					
					If DistributeBySeries > 0
							And (ProductPackages = Undefined
								Or ProductPackages.Get(CellRow.Package) = Undefined) Then
							
							DistributeByCell = CellRow[FieldName];
							
							Allocate = Min(DistributeInCurrentPass, DistributeBySeries, DistributeByCell);
							CellRow.Count = CellRow.Count + Allocate;
							DistributeInCurrentPass = DistributeInCurrentPass - Allocate;
							DistributeBySeries = DistributeBySeries - Allocate;
							
					EndIf;
					
				// Cell counter.
				EndDo;
				
				If DistributeBySeries > 0 And NumberOfBins = 0 Then
					
					Allocate = Min(DistributeInCurrentPass, DistributeBySeries);
					RowSeries.Count = RowSeries.Count + Allocate;
					DistributeInCurrentPass = DistributeInCurrentPass - Allocate;
					
				EndIf;
				
				If DistributeInCurrentPass = 0 Then
					Break;
				EndIf;
				
			// Series counter.
			EndDo;
			
		// Pass number.
		EndDo;
		
	// Counter of goods.
	EndDo;
	
	// Recalculation of packages.
	TableForCalculatingNumberOfPackages = New ValueTable();
	TableForCalculatingNumberOfPackages.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableForCalculatingNumberOfPackages.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableForCalculatingNumberOfPackages.Columns.Add("Count", Common.TypeDescriptionNumber(15, 3));
	TableForCalculatingNumberOfPackages.Columns.Add("NumberOfPackages", Common.TypeDescriptionNumber(15, 3));
	TableForCalculatingNumberOfPackages.Columns.Add("LineNumber", Common.TypeDescriptionNumber(10, 0));
	TableForCalculatingNumberOfPackages.Columns.Add("TreeRow");
	
	For Each RowOfProduct In TreeItems Do
		
		SetOfSeries = RowOfProduct.GetItems();
		For Each RowSeries In SetOfSeries Do
			
			If RowSeries.Count > 0 Then
				
				RowSeries.Mark = True;
				LineForCalculation = TableForCalculatingNumberOfPackages.Add();
				FillPropertyValues(LineForCalculation, RowSeries);
				LineForCalculation.TreeRow = RowSeries;
				LineForCalculation.LineNumber = TableForCalculatingNumberOfPackages.Count();
				
			EndIf;
			
			Cells = RowSeries.GetItems();
			For Each CellRow In Cells Do
				
				If CellRow.Count > 0 Then
					
					CellRow.Mark = True;
					LineForCalculation = TableForCalculatingNumberOfPackages.Add();
					FillPropertyValues(LineForCalculation, CellRow);
					LineForCalculation.TreeRow = CellRow;
					LineForCalculation.LineNumber = TableForCalculatingNumberOfPackages.Count();
					
				EndIf;
				
			EndDo;
				
		EndDo;
		
	EndDo;

	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(TableForCalculatingNumberOfPackages, StructureOfActions);
	
	For Each String In TableForCalculatingNumberOfPackages Do
		String.TreeRow.NumberOfPackages = String.NumberOfPackages;
	EndDo;
	
EndProcedure

&AtServer
Function Kits(Cells, ProductPackages)
	
	PackingTable_ = New ValueTable();
	PackingTable_.Columns.Add("Package");
	PackingTable_.Columns.Add("SecuredUnits");
	PackingTable_.Columns.Add("SecuredUnitsUnderControl");
	
	NumberOfBins = Cells.Count();
	For CellCounter = 0 To NumberOfBins - 1 Do
		CellRow = Cells[CellCounter];
		If ProductPackages.Get(CellRow.Package) <> Undefined Then
			FillPropertyValues(PackingTable_.Add(), CellRow);
		EndIf;
	EndDo;
	
	PackingTable_.GroupBy("Package", "SecuredUnits,SecuredUnitsUnderControl");
	PackingTable_.Indexes.Add("Package");
	NumberOfWholeKits = 0;
	NumberOfWholeSetsUnderControl = 0;
	If PackingTable_.Count() > 0 Then
		NumberOfWholeKits = PackingTable_[0].SecuredUnits;
		NumberOfWholeSetsUnderControl = PackingTable_[0].SecuredUnitsUnderControl;
		For Each String In PackingTable_ Do
			NumberOfWholeKits = Min(NumberOfWholeKits, String.SecuredUnits);
			NumberOfWholeSetsUnderControl = Min(NumberOfWholeSetsUnderControl, String.SecuredUnitsUnderControl);
		EndDo;
	EndIf;
	Return New Structure("PackingTable_,NumberOfWholeKits,NumberOfWholeSetsUnderControl",
		PackingTable_, NumberOfWholeKits, NumberOfWholeSetsUnderControl);
	
EndFunction

&AtServer
Function DistributeToGoodsPlaces(DistributeEverything, Cells, ProductPackages, PostfixOfName)
	
	If DistributeEverything = 0 Or ProductPackages = Undefined Then
		Return 0;
	EndIf;
	Kits = Kits(Cells, ProductPackages);
	PackingTable_ = Kits.PackingTable_;
	NumberOfWholeKits = Kits["NumberOfWholeKits" + PostfixOfName];
	FieldName = "SecuredUnits" + PostfixOfName;
	
	NumberOfWholeKits = Min(NumberOfWholeKits, DistributeEverything);
	For Each String In PackingTable_ Do
		String[FieldName] = NumberOfWholeKits;
	EndDo;
	
	NumberOfBins = Cells.Count();
	For CellCounter = 0 To NumberOfBins - 1 Do
		CellRow = Cells[CellCounter];
		PackingString = PackingTable_.Find(CellRow.Package, "Package");
		If PackingString <> Undefined Then
			Allocate = Max(0, Min(PackingString[FieldName], CellRow[FieldName]));
			PackingString[FieldName] = PackingString[FieldName] - Allocate;
			CellRow.Count = Allocate;
		EndIf;
	EndDo;
	
	Return NumberOfWholeKits;
	
EndFunction

&AtServer
Procedure CalculateProvidedByBatchCells(NewBranchOfSeries, ProductPackages)
	
	If NewBranchOfSeries = Undefined Then
		Return;
	EndIf;
	Cells = NewBranchOfSeries.GetItems();
	SecuredUnits = 0;
	SecuredUnitsUnderControl = 0;
	If ProductPackages <> Undefined Then
		Kits = Kits(Cells, ProductPackages);
		PackingTable_ = Kits.PackingTable_;
		SecuredUnits = Kits.NumberOfWholeKits;
		SecuredUnitsUnderControl = Kits.NumberOfWholeSetsUnderControl;
	EndIf;
	NumberOfBins = Cells.Count();
	For CellCounter = 0 To NumberOfBins - 1 Do
		CellRow = Cells[CellCounter];
		If ProductPackages = Undefined Or PackingTable_.Find(CellRow.Package, "Package") = Undefined Then
			SecuredUnits = SecuredUnits + CellRow.SecuredUnits;
			SecuredUnitsUnderControl = SecuredUnitsUnderControl + CellRow.SecuredUnitsUnderControl;
		EndIf;
	EndDo;
	
	NewBranchOfSeries.SecuredUnits = SecuredUnits;
	NewBranchOfSeries.SecuredUnitsUnderControl = SecuredUnitsUnderControl;
	NewBranchOfSeries.Supplied = SecuredUnits;
	NewBranchOfSeries.ProvidedOnControl = SecuredUnitsUnderControl;
	
EndProcedure

&AtServer
Function YouCanTransferTreeDataToTable(Error)
	
	For Each Root In CellPlacementTree.GetItems() Do
		
		Branches = Root.GetItems();
		// Bypassing series, or bypassing rooms and cells when there are no series.
		For Each Branch In Branches Do
			
			If Branch.Mark Then
				NewRow = GoodsForCheckingCompletenessOfProductLocations.Add();
				FillPropertyValues(NewRow, Root, "Products,Characteristic,Purpose,Warehouse");
				FillPropertyValues(NewRow, Branch, "Package,Premise,Count,NumberOfPackages");
				NewRow.Series = Branch.Series;
			EndIf;
			
			// Bypassing rooms and cells when there is a series.
			For Each CellBranch In Branch.GetItems() Do
				
				If CellBranch.Mark Then
					NewRow = GoodsForCheckingCompletenessOfProductLocations.Add();
					FillPropertyValues(NewRow, Root, "Products,Characteristic,Purpose,Warehouse");
					FillPropertyValues(NewRow, CellBranch, "Package,Premise,Count,NumberOfPackages");
					NewRow.Series = Branch.Series;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.FieldsForCheckingCompleteness = "Warehouse,Premise";
	Cancel = False;
	ProductsServer.CheckCompletenessOfProductLocations(GoodsForCheckingCompletenessOfProductLocations, Cancel, CheckParameters);
	GoodsForCheckingCompletenessOfProductLocations.Clear();
	If Cancel Then
		Error = New Array();
		Return False;
	EndIf;
	
	Marked_Goods = GoodsTable.Unload(New Structure("Mark", True));
	Marked_Goods.GroupBy("Products");
	ListOfItems = Marked_Goods.UnloadColumn("Products");
	ProductLocations = Documents.InventoryAssignmentAdjustment.ProductLocationsAccordingToItemList(ListOfItems);
	Errors = New Array();
	
	For Each Root In CellPlacementTree.GetItems() Do
		
		Packages = ProductLocations.Get(Root.Products);
		FirstPackagingUnitOfGoodsPlace = Undefined;
		If Packages <> Undefined Then
			For Each Item In Packages Do
				FirstPackagingUnitOfGoodsPlace = Item.Key;
				Break;
			EndDo;
		EndIf;
		Count = 0;
		Branches = Root.GetItems();
		
		// Bypassing series, or bypassing rooms and cells when there are no series.
		For Each Branch In Branches Do
			
			If Branch.Mark Then
				ItIsACargoItem = Packages <> Undefined And Packages.Get(Branch.Package) <> Undefined;
				If Not ItIsACargoItem Or Branch.Package = FirstPackagingUnitOfGoodsPlace Then
					Count = Count + Branch.Count;
				EndIf;
			EndIf;
			
			// Bypassing rooms and cells when there is a series.
			For Each CellBranch In Branch.GetItems() Do
				
				If CellBranch.Mark Then
					ItIsACargoItem = Packages <> Undefined And Packages.Get(CellBranch.Package) <> Undefined;
					If Not ItIsACargoItem Or CellBranch.Package = FirstPackagingUnitOfGoodsPlace Then
						Count = Count + CellBranch.Count;
					EndIf;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		If Count <> Root.Count Then
			NewError = NStr("vi = 'Theo hàng hóa %1 trong kho %2 cần chỉ ra %3 %4, nhưng đã chỉ ra %5 %4';
							|ru = 'По товару %1 на складе %2 требуется указать %3 %4 а указано %5 %4';
							|en = 'For the %1 item in the %2 warehouse, %3 %4 must be specified instead of the currently specified %5 %4'; fa = 'For the %1 item in the %2 warehouse, %3 %4 must be specified instead of the currently specified %5 %4';
							|it = 'In riferimento alla merce %1 nel magazzino %2 è necessario indicare %3 %4 mentre risulta indicato %5 %4';
							|pl = 'Wg towaru %1 w magazynie %2 należy podać %3 %4 a podano %5 %4';
							|tr = '%2 ambarındaki %1 ürününe ilişkin %3 %4 belirtilmelidir, fakat %5 %4 belirtilmiştir'");
			If ValueIsFilled(Root.Characteristic) Then
				RowGoods = StrTemplate(NStr("vi = '%1, %2';
											|ru = '%1, %2';
											|en = '%1, %2'; fa = '%1, %2';
											|it = '%1, %2';
											|pl = '%1, %2';
											|tr = '%1, %2'"), Root.Products, Root.Characteristic);
			Else
				RowGoods = String(Root.Products);
			EndIf;
			NewError = StrTemplate(NewError, RowGoods, Root.Warehouse, Root.Count, Root.Package, Count);
			Errors.Add(NewError);
		EndIf;
		
	EndDo;
	
	If Errors.Count() > 0 Then
		Error = Errors;
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function PutProductsInStorage(Error, TableToTransfer)
	
	RowsArray = New Array();
	
	For Each String In TableToTransfer Do
		If String.Count > 0 And String.Mark Then
			 RowsArray.Add(String);
		EndIf;
	EndDo;
	
	If TypeOf(TableToTransfer) = Type("FormDataCollection") Then
		ItemsToTransfer = TableToTransfer.Unload(RowsArray);
	Else
		ItemsToTransfer = TableToTransfer.Copy(RowsArray);
	EndIf;
	
	Result = New Structure("Goods", ItemsToTransfer);
	AddressInStorage = PutToTempStorage(
		Result,
		UniqueIDForTemporaryStorage);
	Return AddressInStorage;

EndFunction

#EndRegion

#Region ResultsForProductsTable

&AtClient
Procedure Attachable_OnActivateRow()
	
	CalculateTotalsByOrder();
	
EndProcedure

&AtClient
Procedure CalculateTotalsByOrder()
	
	CurrentRow = Items.GoodsTable.CurrentRow;
	Items.PagesTotalsInBasementStepByWarehouses.CurrentPage = Items.PageDisplayTotalsInBasementByWarehouses;
	If CurrentRow = Undefined Then
		Items.PagesTotalsInBasementStepByWarehouses.CurrentPage = Items.PageDoesNotDisplayTotalsInBasementByWarehouses;
		ResultsPurposeSource = "";
		Items.PagesDisplayExcessImages.CurrentPage = Items.PageDoesNotDisplayPictureExcess;
		Return;
	EndIf;
	
	String = GoodsTable.FindByID(CurrentRow);
	ResultsPackaging = String.UnitOfMeasure;
	
	TotalsLine = ProductResults.FindByID(String.TotalLineID);
	ResultsByOrder = TotalsLine.Count;
	TotalsByOrderAssignments = TotalsLine.QuantityByOrderDestination;
	ResultsOfTheMeeting = TotalsLine.Demand;
	ResultsSecured = TotalsLine.Supplied + TotalsLine.Count;
	StockTotals = TotalsLine.InStock + TotalsLine.Count;
	
	RowTotalsSummary = SummaryOfProductResults.FindByID(TotalsLine.IDOfSummaryTotalsRow);
	If RowTotalsSummary <> Undefined Then
		ResultsOfNeedAreSummarized = RowTotalsSummary.Demand;
		ResultsProvidedInSummary = RowTotalsSummary.Supplied + RowTotalsSummary.Count;
		StockTotalsSummary = RowTotalsSummary.InStock + RowTotalsSummary.Count;
	EndIf;
	
	If ResultsSecured < 0 Or ResultsSecured > ResultsOfTheMeeting Then
		Items.PagesTotalsProvided.CurrentPage = Items.PageTotalsProvidedExcess;
	Else
		Items.PagesTotalsProvided.CurrentPage = Items.ResultsPageIsProvided;
	EndIf;
	If StockTotals < 0 Or StockTotals > ResultsOfTheMeeting Then
		Items.PagesTotalsInStock.CurrentPage = Items.StockTotalsPageExceeds;
	Else
		Items.PagesTotalsInStock.CurrentPage = Items.StockTotalsPage;
	EndIf;
	
	If ResultsProvidedInSummary < 0 Or ResultsProvidedInSummary > ResultsOfNeedAreSummarized Then
		Items.PagesTotalsProvidedInSummary.CurrentPage = Items.TotalsPageProvidedSummaryOfExcess;
	Else
		Items.PagesTotalsProvidedInSummary.CurrentPage = Items.TotalsPageIsProvidedInSummary;
	EndIf;
	If StockTotalsSummary < 0 Or StockTotalsSummary > ResultsOfNeedAreSummarized Then
		Items.PagesTotalsInStockSummary.CurrentPage = Items.StockTotalsPageSummarizesExcess;
	Else
		Items.PagesTotalsInStockSummary.CurrentPage = Items.StockTotalsSummaryPage;
	EndIf;
	
	TotalsLine = ResultsByAppointment.FindByID(TotalsLine.TotalLineID);
	
	// String representation of the totals as a whole by order
	If TotalsLine.NotProvided Then
		Items.StateGroup.CurrentPage = Items.GroupNotSecured;
	ElsIf TotalsLine.SuppliedBeyondDemand Then
		Items.StateGroup.CurrentPage = Items.TheGroupIsProvidedInExcessOfTheNeed;
	ElsIf TotalsLine.FullySupplied Then
		Items.StateGroup.CurrentPage = Items.TheGroupIsFullySecured;
	Else
		Items.StateGroup.CurrentPage = Items.TheGroupIsPartiallySecured;
	EndIf;
	
	If TotalsLine.OutOfStockShipment Then
		Items.GroupInStockAtTheShippingWarehouse.CurrentPage = Items.GroupNoItemsInTheShippingWarehouse;
	ElsIf TotalsLine.OverAndAboveNeedForShipmentStock Then
		Items.GroupInStockAtTheShippingWarehouse.CurrentPage = Items.GroupInExcessOfTheNeedForAShipmentWarehouse;
	ElsIf TotalsLine.FullyInStockShipment Then
		Items.GroupInStockAtTheShippingWarehouse.CurrentPage = Items.TheGroupIsFullyInTheShipmentWarehouse;
	Else
		Items.GroupInStockAtTheShippingWarehouse.CurrentPage = Items.TheGroupIsPartiallyInTheShipmentWarehouse;
	EndIf;
	
	// Results by destination-source.
	If String.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_") Then
		SourceTotalsString = ResultsOfSourcesOfProvision.FindByID(String.IDOfSourceTotalsRow);
		If ValueIsFilled(SourceTotalsString.InitialAssignment) Then
			Text = NStr("vi = 'Theo mục đích nguồn %1 trong tất cả kho bãi cần có: %2 %4, có sẵn: %3 %4';
						|ru = 'По назначению-источнику %1 на всех складах потребность: %2 %4, в наличии: %3 %4';
						|en = 'By the %1 source assignment all warehouses have the demand: %2 %4, in stock: %3 %4'; fa = 'By the %1 source assignment all warehouses have the demand: %2 %4, in stock: %3 %4';
						|it = 'In riferimento all''assegnazione iniziale %1 il fabbisogno in tutti i magazzini: %2 %4, disponibile: %3%4';
						|pl = 'Wg przeznaczenia-źródła %1 we wszystkich magazynach zapotrzebowanie: %2 %4, dostępne: %3 %4';
						|tr = 'Atama kaynağına %1 göre tüm ambarlarda gereksinim: %2 %4, stokta: %3 %4'");
		Else
			Text = NStr("vi = 'Trong tất cả kho bãi, nhu cầu không đặt riêng là: %2 %4, có sẵn: %3 %4';
						|ru = 'На всех складах необособленная потребность: %2 %4, в наличии: %3 %4';
						|en = 'All warehouses have the non-assigned demand: %2 %4, in stock: %3 %4'; fa = 'All warehouses have the non-assigned demand: %2 %4, in stock: %3 %4';
						|it = 'Fabbisogno non separato in tutti i magazzini: %2 %4, disponibile: %3 %4';
						|pl = 'We wszystkich magazynach nieodosobnione zapotrzebowanie: %2 %4, dostępne: %3 %4';
						|tr = 'Tüm ambarlarda dağıtılmamış talep: %2 %4, stokta: %3 %4'");
		EndIf;
		ResultsPurposeSource = StrTemplate(
			Text,
			SourceTotalsString.InitialAssignment,
			Format(SourceTotalsString.Demand, "NFD=3; NZ=0,000"),
			Format(SourceTotalsString.Inventory, "NFD=3; NZ=0,000"),
			ResultsPackaging);
		If String.PictureSurplusSource = 0 Then
			Items.PagesDisplayExcessImages.CurrentPage = Items.PageDisplayPictureSurplus;
		Else
			Items.PagesDisplayExcessImages.CurrentPage = Items.PageDoesNotDisplayPictureExcess;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BindTableRowsToTableTotals(Table, Totals, GroupingRows, ColumnName)
	
	ProductSelectionParameters_ = New Structure(GroupingRows);
	For Each String In Totals Do
		FillPropertyValues(ProductSelectionParameters_, String);
		FoundProductLines = Table.FindRows(ProductSelectionParameters_);
		TotalLineID = String.GetID();
		For Each RowOfGoods In FoundProductLines Do
			RowOfGoods[ColumnName] = TotalLineID;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure ReFillCountInTotalsTable()
	
	For Each TotalsLine In ProductResults Do
		TotalsLine.Count = 0;
		TotalsLine.QuantityByOrderDestination = 0;
	EndDo;
	For Each RowTotalsSummary In SummaryOfProductResults Do
		RowTotalsSummary.Count = 0;
	EndDo;
	
	For Each String In GoodsTable Do
	
		TotalsLine = ProductResults.FindByID(String.TotalLineID);
		AddSubtractQuantity = 0;
		If String.Mark Then
			If String.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
				AddSubtractQuantity = String.Count;
			ElsIf String.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
				AddSubtractQuantity = - String.Count;
			EndIf;
			TotalsLine.Count = TotalsLine.Count + AddSubtractQuantity;
			
			LineSummary_ = SummaryOfProductResults.FindByID(TotalsLine.IDOfSummaryTotalsRow);
			If LineSummary_ <> Undefined Then
				LineSummary_.Count = LineSummary_.Count + AddSubtractQuantity;
			EndIf;
			
			If String.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.EmptyRef() Then
				TotalsLine.QuantityByOrderDestination = TotalsLine.QuantityByOrderDestination + String.Count;
			EndIf;
		EndIf;
		
		TotalsLine = ProductResults.FindByID(String.IDOfMultiAssignmentTotalsRow);
		If TotalsLine <> Undefined Then
			If String.Mark And String.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
				TotalsLine.Count = TotalsLine.Count + String.Count;
			EndIf;
		EndIf;
		
	EndDo;
	
	ProductSummaryTable = SummaryOfProductResults.Unload();
	ProductSummaryTable.GroupBy("TotalLineID,Products,Characteristic",
		"Supplied,Demand,InStock,Count");
	ProductSummaryTable.Columns.Add("NotProvided");
	ProductSummaryTable.Columns.Add("PartiallySupplied");
	ProductSummaryTable.Columns.Add("FullySupplied");
	ProductSummaryTable.Columns.Add("SuppliedBeyondDemand");
	
	For Each String In ProductSummaryTable Do
		Count = String.Supplied + String.Count;
		String.NotProvided = ?(Count = 0 And String.Demand > 0, 1, 0);
		String.PartiallySupplied = ?(Count > 0 And Count < String.Demand, 1, 0);
		String.FullySupplied = ?(Count > 0 And Count >= String.Demand, 1, 0);
		String.SuppliedBeyondDemand = ?(Count > String.Demand, 1, 0);;
	EndDo;
	ProductSummaryTable.GroupBy("TotalLineID",
		"NotProvided,PartiallySupplied,FullySupplied,SuppliedBeyondDemand");
	For Each String In ProductSummaryTable Do
		TotalsLine = ResultsByAppointment.FindByID(String.TotalLineID);
		TotalsLine.NotProvided = String.NotProvided > 0 And String.PartiallySupplied = 0 And String.FullySupplied = 0;
		TotalsLine.FullySupplied = String.NotProvided = 0 And String.PartiallySupplied = 0;
		TotalsLine.PartiallySupplied = Not TotalsLine.NotProvided And Not TotalsLine.FullySupplied;
		TotalsLine.SuppliedBeyondDemand = TotalsLine.FullySupplied And String.SuppliedBeyondDemand > 0;
	EndDo;
	
	TableOfProducts_ = ProductResults.Unload(New Structure("ThisIsShippingWarehouse", True));
	TableOfProducts_.GroupBy("TotalLineID,Products,Characteristic",
		"InStock,Demand,Count");
	TableOfProducts_.Columns.Add("NotProvided");
	TableOfProducts_.Columns.Add("PartiallySupplied");
	TableOfProducts_.Columns.Add("FullySupplied");
	TableOfProducts_.Columns.Add("SuppliedBeyondDemand");
	
	For Each String In TableOfProducts_ Do
		Count = String.InStock + String.Count;
		String.NotProvided = ?(Count = 0 And String.Demand > 0, 1, 0);
		String.PartiallySupplied = ?(Count > 0 And Count < String.Demand, 1, 0);
		String.FullySupplied = ?(Count > 0 And Count >= String.Demand, 1, 0);
		String.SuppliedBeyondDemand = ?(Count > String.Demand, 1, 0);;
	EndDo;
	TableOfProducts_.GroupBy("TotalLineID",
		"NotProvided,PartiallySupplied,FullySupplied,SuppliedBeyondDemand");
	
	For Each TotalsLine In ResultsByAppointment Do
		TotalsLine.OutOfStockShipment = True;
		TotalsLine.FullyInStockShipment = False;
		TotalsLine.PartiallyInStockShipping = False;
		TotalsLine.OverAndAboveNeedForShipmentStock = False;
	EndDo;
	
	For Each String In TableOfProducts_ Do
		TotalsLine = ResultsByAppointment.FindByID(String.TotalLineID);
		TotalsLine.OutOfStockShipment = String.NotProvided > 0 And String.PartiallySupplied = 0 And String.FullySupplied = 0;
		TotalsLine.FullyInStockShipment = String.NotProvided = 0 And String.PartiallySupplied = 0;
		TotalsLine.PartiallyInStockShipping = Not TotalsLine.OutOfStockShipment And Not TotalsLine.FullyInStockShipment;
		TotalsLine.OverAndAboveNeedForShipmentStock = TotalsLine.FullyInStockShipment And String.SuppliedBeyondDemand > 0;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillPictureWithExcessSource()
	
	For Each String In GoodsTable Do
		If String.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
			SourceTotalsString = ResultsOfSourcesOfProvision.FindByID(String.IDOfSourceTotalsRow);
			String.PictureSurplusSource = ?(SourceTotalsString.Inventory > SourceTotalsString.Demand, 0, 1);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAmountOfCounterAdjustment()
	
	RowsArray = GoodsTable.FindRows(New Structure("PageIndex", 1));
	For Each TableRow In RowsArray Do
		TableRow.Mark = False;
		TableRow.Count = 0;
	EndDo;
	
	QuantityBase = 0;
	
	FilterByRows = New Structure();
	FilterByRows.Insert("Mark", True);
	FilterByRows.Insert("PageIndex", 0);
	
	RowsArray = GoodsTable.FindRows(FilterByRows);
	For Each TableRow In RowsArray Do
		If TableRow.Count > 0 Then
			QuantityBase = QuantityBase + TableRow.Count;
		EndIf;
	EndDo;
	
	If QuantityBase > 0 Then
		
		AllocateQuantity(QuantityBase, QuantityToPassForAssignment);
		
		FilterByRows.PageIndex = 1;
		RowsArray = GoodsTable.FindRows(FilterByRows);
		For Each TableRow In RowsArray Do
			
			MeasuredValueType = Common.ObjectAttributeValue(
										TableRow.Products, "UnitOfMeasure.MeasuredValueType");
				
			If MeasuredValueType = Enums.TypesOfMeasuredValues.NumberOfPieces
					And TableRow.Count <> Int(TableRow.Count) Then
				
				NumberOfAdjustments = Round(TableRow.Count);
				NumberOfAdjustments = ?(NumberOfAdjustments = 0, 1, NumberOfAdjustments); 
				
				TableRow.Count = Min(NumberOfAdjustments, TableRow.InStock);
				TableRow.Mark    = TableRow.Count > 0;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AllocateQuantity(RequiredQuantity, Expense, Allocated = 0, KeyOfParentString = Undefined)
	
	SelectionByParent = New Structure;
	SelectionByParent.Insert("ByAssignment", 1);
	
	If KeyOfParentString = Undefined Then
		SelectionByParent.Insert(
			"KeyOfParentString", New UUID("00000000-0000-0000-0000-000000000000"));
	Else
		SelectionByParent.Insert("KeyOfParentString", KeyOfParentString);
	EndIf;
	
	RowsArray = GoodsFilter.FindRows(SelectionByParent);
	For Each LineProducts_ In RowsArray Do
		
		DistributionCoefficientPerUnit = LineProducts_.Expense / (Expense - Allocated);
		
		QuantityToDistribution = RequiredQuantity * DistributionCoefficientPerUnit;
		QuantityIsAllocated   = Min(QuantityToDistribution, LineProducts_.Allocated);
		QuantityToDistribution = QuantityToDistribution - QuantityIsAllocated;
		
		If QuantityIsAllocated > 0 Then
			
			FilterRemainingGoodsByShelfLives = New Structure;
			FilterRemainingGoodsByShelfLives.Insert("Products"  , LineProducts_.Products);
			FilterRemainingGoodsByShelfLives.Insert("Characteristic", LineProducts_.Characteristic);
			FilterRemainingGoodsByShelfLives.Insert("Warehouse",          LineProducts_.Warehouse);
			FilterRemainingGoodsByShelfLives.Insert("PageIndex", 1);
			
			ArrayOfRowsInProductTable = GoodsTable.FindRows(FilterRemainingGoodsByShelfLives);
			If ArrayOfRowsInProductTable.Count() > 0 Then
			
				ProductTableRow_ = ArrayOfRowsInProductTable[0];
				ProductTableRow_.Count =
					Min(QuantityIsAllocated + ProductTableRow_.Count, ProductTableRow_.Inventory - ProductTableRow_.Reserve);
					
				ProductTableRow_.Mark = ProductTableRow_.Count > 0;
			
			EndIf;
			
			If QuantityToDistribution > 0 Then
				AllocateQuantity(
					QuantityToDistribution, LineProducts_.Expense, LineProducts_.Allocated, LineProducts_.RowKey);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillQuantityForManyAppointments()
	
	TableOfManyAssignments = GoodsTable.Unload(New Structure("PageIndex", 1));
	TableOfManyAssignments.FillValues(0, "Count");
	TableOfManyAssignments.FillValues(False, "Mark");
	RowsArray = GoodsTable.FindRows(New Structure("PageIndex", 1));
	For Each TableRow In RowsArray Do
		GoodsTable.Delete(TableRow);
	EndDo;
	
	KeyFields = "Products,Characteristic";
	TableOfSources = GoodsTable.Unload(New Structure("Mark", True));
	TableOfSources.GroupBy(KeyFields, "Count");
	TableOfManyAssignments.FillValues(False, "SatisfiesTheFilter");
	TableOfManyAssignments.Indexes.Add(KeyFields);
	Var_Key = New Structure(KeyFields);
	For Each TableRow In TableOfSources Do
		
		FillPropertyValues(Var_Key, TableRow);
		Destinations = TableOfManyAssignments.FindRows(Var_Key);
		For Each Receiver In Destinations Do
			
			Receiver.SatisfiesTheFilter = True;
			If TableRow.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(TableRow.Count, Receiver.Demand - Receiver.Supplied);
			TableRow.Count = TableRow.Count - Count;
			Receiver.Count = Count;
			Receiver.Mark = Receiver.Count > 0;
			
		EndDo;
		
		Receiver.Count = Receiver.Count + TableRow.Count; // provision in excess of need.
		Receiver.Mark = Receiver.Count > 0;
		
	EndDo;
	
	TMCommonUseClientServer.SupplementTable(TableOfManyAssignments, GoodsTable);
	
EndProcedure

&AtServer
Function MarkCreatedDocumentsForDeletion()
	
	ArrayOfDeleteLinks = DocumentsList.UnloadValues();
	
	Query = New Query(
		"SELECT
		|COUNT(*) AS Count
		|FROM
		|	Document.InventoryAssignmentAdjustment AS Table
		|WHERE
		|	Table.Ref IN(&References)
		|	AND Table.DeletionMark");
	Query.SetParameter("References", ArrayOfDeleteLinks);
	
	RefsCount = 0;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		RefsCount = Selection.Count;
	EndIf;
	
	ErrorList = TMCommonUse.SetMarkForDeletingDocuments(ArrayOfDeleteLinks);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		RefsCount = Selection.Count - RefsCount;
	Else
		RefsCount = 0;
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	Return RefsCount;
	
EndFunction

#EndRegion

#EndRegion
