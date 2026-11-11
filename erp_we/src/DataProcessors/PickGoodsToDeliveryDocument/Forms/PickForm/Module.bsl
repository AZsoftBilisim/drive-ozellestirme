// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ModifiableFields = New Array; // Array of String
	ModifiableFields.Add("Balance");
	ModifiableFields.Add("Selected");
	ModifiableFields.Add("PictureIndex");
	ListByItem.SetRestrictionsForUseInFilter(ModifiableFields);
	ListByItem.SetRestrictionsForUseInGroup(ModifiableFields);
	ListByItem.SetRestrictionsForUseInOrder(ModifiableFields);
	
	ModifiableFields.Clear();
	ModifiableFields.Add("Balance");
	ListByDocuments.SetRestrictionsForUseInFilter(ModifiableFields);
	ListByDocuments.SetRestrictionsForUseInGroup(ModifiableFields);
	ListByDocuments.SetRestrictionsForUseInOrder(ModifiableFields);
	
	Object.Organization = Parameters.Organization;
	Object.Warehouse = Parameters.Warehouse;
	Object.DeliveryMethod = Parameters.DeliveryMethod;
	Object.DocumentDeliveryMethod = Parameters.DeliveryMethod;
	Object.Carrier = Parameters.Carrier;
	Object.DocumentCarrier = Parameters.Carrier;
	Object.DateOfShipment = Parameters.DateOfShipment;
	Object.DocumentShipmentDate = Parameters.DateOfShipment;
	Object.ConsiderQuantityInDocument = Parameters.ConsiderQuantityInDocument;
	Object.DocumentDeliveries = Parameters.DocumentDeliveries;
	Object.DeliveryParametersCorrespondToTrip = (TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip"));
	Object.Recipient = Parameters.Recipient;
	Object.DeliveryPoint = Parameters.DeliveryPoint;
	Object.DeliveryZone = Parameters.DeliveryZone;
	Object.DeliveryPointFixed = Parameters.DeliveryPointFixed;
	Object.DeliveryZoneFixed = Parameters.DeliveryZoneFixed;
	Object.RecordDeliveryParameters = Parameters.RecordDeliveryParameters;
	Object.DeliveryType = Parameters.DeliveryType;
	
	ConfigureVisibilityAvailabilityOfFields();
	ConfigureAvailabilityOfSelectionFields();
	SetFieldHeaders();
	
	RefineListRequestByGoods();
	RefineListRequestByDocuments();
	
	InitializeListSelections();
	InitializeAdditionalListProperties();
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
	   And Selected.Count() > 0 Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'The data has been changed. All changes will be lost.'; fa = 'The data has been changed. All changes will be lost.';
							|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
		Return;
		
	EndIf;
	
	If Not ClosingInProgress
	   And Not MoveToDocument
	   And Selected.Count() > 0 Then
		
		Cancel = True;
		QueryText = NStr("vi = 'Hàng hóa đã chọn chưa được chuyển vào chứng từ. Chuyển?';
						|ru = 'Подобранные товары не перенесены в документ. Перенести?';
						|en = 'Picked items are not added to the document. Do you want to add them?'; fa = 'Picked items are not added to the document. Do you want to add them?';
						|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
						|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
						|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'");
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If MoveToDocument Then
		
		Result = New Structure("AddressOfSelectedItems", AddressOfSelectedItems);
		NotifyChoice(Result);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	SuitableDeliveryMethods = New ValueList; // ValueList of EnumRef.TransportMethods25
	If ValueIsFilled(Object.DeliveryMethod) Then
		
		SuitableDeliveryMethods.Add(Object.DeliveryMethod);
		
		If Not Object.DeliveryParametersCorrespondToTrip Then
			SuitableDeliveryMethods.Add(PredefinedValue("Enum.TransportMethods25.DefinedByDeliveryService"));
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByItem,
		"DeliveryMethod",
		SuitableDeliveryMethods,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Object.DeliveryMethod));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByDocuments,
		"DeliveryMethod",
		SuitableDeliveryMethods,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Object.DeliveryMethod));
	
	If Object.DeliveryMethod <> PredefinedValue("Enum.TransportMethods25.ByCarrier")
	   And ValueIsFilled(Object.Carrier) Then
		
		Object.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		WhenChangingCarrier();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Lists = New Array; // Array of DynamicList
	Lists.Add(ListByItem);
	Lists.Add(ListByDocuments);
	
	For Each List In Lists Do
		
		CommonClientServer.SetDynamicListParameter(
			List, "DateOfShipmentBy", Object.DateOfShipment, ValueIsFilled(Object.DateOfShipment));
		
		If Object.DeliveryParametersCorrespondToTrip Then
			
			CommonClientServer.SetDynamicListParameter(
				List, "DateOfShipmentFrom", Object.DateOfShipment, ValueIsFilled(Object.DateOfShipment));
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	WhenChangingCarrier();
	
EndProcedure

&AtClient
Procedure DeliveryZoneOnChange(Item)
	
	SettingUpListsByDeliveryZone();
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
		And Not Object.RecordDeliveryParameters Then
		
		FilterFieldName = "FinalRecipientIsFinalLeverage";
		
	Else
		
		FilterFieldName = "FinalRecipientIsTurnover";
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByItem, FilterFieldName, Object.Recipient,,, ValueIsFilled(Object.Recipient));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByDocuments, FilterFieldName, Object.Recipient,,, ValueIsFilled(Object.Recipient));
	
EndProcedure

&AtClient
Procedure DeliveryParametersCorrespondToTripOnChange(Item)
	
	DeliveryParametersCorrespondToFlightOnChangeATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListByItem

&AtServerNoContext
Procedure ListByItemOnGetDataAtServer(TagName, Settings, Rows)
	
	ListOnGetDataAtServer(TagName, Settings, Rows);
	
EndProcedure

&AtClient
Procedure ListByItemSelection(Item, RowSelected, Field, StandardProcessing)
	
	ListDeliverSelection(Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListByItemOnActivateRow(Item)
	
	DetachIdleHandler("GoodsListUpdateAdditionalParameters");
	AttachIdleHandler("GoodsListUpdateAdditionalParameters", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListByDocuments

&AtServerNoContext
Procedure ListByDocumentsOnGetDataAtServer(TagName, Settings, Rows)
	
	ListOnGetDataAtServer(TagName, Settings, Rows);
	
EndProcedure

&AtClient
Procedure ListByDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ListDeliverSelection(Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListByDocumentsOnActivateRow(Item)
	
	DetachIdleHandler("ListOfDocumentsUpdateAdditionalParameters");
	AttachIdleHandler("ListOfDocumentsUpdateAdditionalParameters", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelected

&AtClient
Procedure SelectedDeliveryPointOnChange(Item)
	
	CurrentData = Items.Selected.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.DeliveryPoint) Then
		CurrentData.DeliveryZone = DeliveryZoneByPoint(CurrentData.DeliveryPoint);
	Else
		CurrentData.DeliveryZone = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedOnChange(Item)
	
	UpdateSelectedInDeliverList();
	Items.ListByItem.Refresh();
	
EndProcedure

&AtClient
Procedure SelectedCountOnChange(Item)
	
	CurrentRow = Items.Selected.CurrentData;
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	MoveToDocument = True;
	PlaceSelectedGoodsInVault();
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	UnitDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	UnitDesignParameters.NameOfUnitField = "ListByItemProductsUnitOfMeasure";
	UnitDesignParameters.PathToPackagingUnitField = "ListByItem.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, UnitDesignParameters);
	
	UnitDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	UnitDesignParameters.NameOfUnitField = "SelectedProductsUnitOfMeasure";
	UnitDesignParameters.PathToPackagingUnitField = "Selected.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, UnitDesignParameters);
	
	SetConditionalAppearanceBlankCarrier();
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
	   And Object.DocumentDeliveryMethod = Enums.TransportMethods25.ByCarrier Then
		
		SetConditionalAppearanceOfFieldsOfFinalRecipient();
		
	EndIf;
	
	SetConditionalAppearanceWeightVolumeNotUsed();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceBlankCarrier()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemCarrier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.Carrier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<неприменимо>';
													|vi = '<not applicable>';
													|en = '<not applicable>'; fa = '<not applicable>';
													|it = '<not applicable>';
													|pl = '<not applicable>';
													|tr = '<uygulanamaz>'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfFieldsOfFinalRecipient()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemFinalRecipient.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemFinalRecipientPoint.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemAreaOfFinalRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.FinalRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.FinalRecipientPoint");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.AreaOfFinalRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<неприменимо>';
													|vi = '<not applicable>';
													|en = '<not applicable>'; fa = '<not applicable>';
													|it = '<not applicable>';
													|pl = '<not applicable>';
													|tr = '<uygulanamaz>'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsFinalRecipient.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsFinalRecipientPoint.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsAreaOfFinalRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.FinalRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.FinalRecipientPoint");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.AreaOfFinalRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<неприменимо>';
													|vi = '<not applicable>';
													|en = '<not applicable>'; fa = '<not applicable>';
													|it = '<not applicable>';
													|pl = '<not applicable>';
													|tr = '<uygulanamaz>'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceWeightVolumeNotUsed()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	#Region ListByGoods_Weight
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
	#Region ListByGoods_Weight
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.VolumeM3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
	#Region ListByDocumentsWeight
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
	#Region ListByDocuments_Volume
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.VolumeM3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
	#Region Selected_PackageWeight
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Selected.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
	#Region Selected_PackageVolume
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Selected.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	#EndRegion
	
EndProcedure

&AtServer
Procedure RefineListRequestByGoods()
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		
		PreviousLevelsOfOperations.Add(10);
		ClarifyListRequestForGoodsForDeliveryOrder();
		
	ElsIf TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip") Then
		
		PreviousLevelsOfOperations.Add(15);
		PreviousLevelsOfOperations.Add(20);
		ClarifyListRequestForGoodsForFlight();
		
	Else
		
		ExceptionText = NStr("ru = 'В форму подбора товаров доставки передан неизвестный документ для работы';
							|vi = 'An unknown document is passed to the delivery product pick form';
							|en = 'An unknown document is passed to the delivery product pick form'; fa = 'An unknown document is passed to the delivery product pick form';
							|it = 'An unknown document is passed to the delivery product pick form';
							|pl = 'An unknown document is passed to the delivery product pick form';
							|tr = 'Teslimat ürün seçim formuna, işlem için bilinmeyen bir belge iletildi'");
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClarifyListRequestForGoodsForFlight()
	
	If Object.ConsiderQuantityInDocument Then
		
		QueryTextByGoods =
		"SELECT
		|	TripContent.ReferenceOrder AS ReferenceOrder,
		|	TripContent.PlanningDocument AS PlanningDocument,
		|	TripContent.RowCode AS RowCode,
		|	SUM(TripContent.Count) AS Count
		|INTO TTContentsOfDocument
		|FROM
		|	Document.Trip.Content AS TripContent
		|WHERE
		|	TripContent.Ref = &DocumentDeliveries
		|	AND NOT TripContent.Canceled
		|
		|GROUP BY
		|	TripContent.ReferenceOrder,
		|	TripContent.PlanningDocument,
		|	TripContent.RowCode
		|
		|INDEX BY
		|	ReferenceOrder,
		|	PlanningDocument,
		|	RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	DeliveryTurnover.Products AS Products,
		|	DeliveryTurnover.Characteristic AS Characteristic,
		|	DeliveryTurnover.Series AS Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END AS FinalRecipient,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END AS FinalRecipientPoint,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END AS AreaOfFinalRecipient,
		|	SUM(DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover - ISNULL(TTContentsOfDocument.Count, 0)) AS Balance,
		|	0 AS Selected,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitWeight) AS Weight,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitVolume) AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|{SELECT
		|	DateOfShipment,
		|	DeliveryMethod.*,
		|	Sender.*,
		|	Recipient.*,
		|	RecipientPoint.*,
		|	Recipient_Area.*,
		|	FinalRecipient.*,
		|	FinalRecipientPoint.*,
		|	AreaOfFinalRecipient.*,
		|	ReferenceOrder.*,
		|	DeliveryType,
		|	Products.*,
		|	Characteristic.*,
		|	Series.*,
		|	Package.*,
		|	Balance,
		|	Selected,
		|	Weight,
		|	VolumeM3,
		|	PictureIndex,
		|	Detailing,
		|	ThereAreDifferences_InDeliveryParameters,
		|	OptionsForDeliveryParameters}
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			&SelectionByParameters
		|				{&SelectionByLayout}
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|		LEFT JOIN TTContentsOfDocument AS TTContentsOfDocument
		|		ON DeliveryTurnover.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
		|			AND DeliveryTurnover.PlanningDocument = TTContentsOfDocument.PlanningDocument
		|			AND DeliveryTurnover.RowCode = TTContentsOfDocument.RowCode
		|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
		|		ON DeliveryTurnover.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = DeliveryFinalLeverage.RowCode
		|			AND DeliveryTurnover.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
		|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
		|			AND (DeliveryFinalLeverage.OperationLevel IN (&PreviousLevelsOfOperations))
		|			AND NOT 1 IN
		|				(SELECT TOP 1
		|					1
		|				FROM
		|					InformationRegister.DocumentCorrections AS DocumentCorrections
		|				WHERE
		|					DocumentCorrections.CorrectedDocument = DeliveryFinalLeverage.Recorder
		|					OR DocumentCorrections.PreviousCorrection = DeliveryFinalLeverage.Recorder)
		|WHERE
		|	DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover - ISNULL(TTContentsOfDocument.Count, 0) > 0
		|{WHERE
		|	DeliveryFinalLeverage.Recipient AS FinalRecipientIsFinalLeverage,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|			ELSE UNDEFINED
		|		END).* AS FinalRecipient,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|		END).* AS FinalRecipientPoint,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|		END).* AS AreaOfFinalRecipient}
		|
		|GROUP BY
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END,
		|	DeliveryTurnover.ReferenceOrder,
		|	DeliveryTurnover.DeliveryType,
		|	DeliveryTurnover.Products,
		|	DeliveryTurnover.Characteristic,
		|	DeliveryTurnover.Series";
		
		CommonClientServer.SetDynamicListParameter(
			ListByItem, "DocumentDeliveries", Object.DocumentDeliveries);
		
	Else
		
		QueryTextByGoods =
		"SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	DeliveryTurnover.Products AS Products,
		|	DeliveryTurnover.Characteristic AS Characteristic,
		|	DeliveryTurnover.Series AS Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END AS FinalRecipient,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END AS FinalRecipientPoint,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END AS AreaOfFinalRecipient,
		|	SUM(DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover) AS Balance,
		|	0 AS Selected,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover) * &ExpressionPackagingUnitWeight) AS Weight,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover) * &ExpressionPackagingUnitVolume) AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|{SELECT
		|	DateOfShipment,
		|	DeliveryMethod.*,
		|	Sender.*,
		|	Recipient.*,
		|	RecipientPoint.*,
		|	Recipient_Area.*,
		|	ReferenceOrder.*,
		|	DeliveryType,
		|	Products.*,
		|	Characteristic.*,
		|	Series.*,
		|	Package.*,
		|	FinalRecipient.*,
		|	FinalRecipientPoint.*,
		|	AreaOfFinalRecipient.*,
		|	Balance,
		|	Selected,
		|	Weight,
		|	VolumeM3,
		|	PictureIndex,
		|	Detailing,
		|	ThereAreDifferences_InDeliveryParameters,
		|	OptionsForDeliveryParameters}
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			&SelectionByParameters
		|				{&SelectionByLayout}
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
		|		ON DeliveryTurnover.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = DeliveryFinalLeverage.RowCode
		|			AND DeliveryTurnover.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
		|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
		|			AND (DeliveryFinalLeverage.OperationLevel IN (&PreviousLevelsOfOperations))
		|			AND NOT 1 IN
		|				(SELECT TOP 1
		|					1
		|				FROM
		|					InformationRegister.DocumentCorrections AS DocumentCorrections
		|				WHERE
		|					DocumentCorrections.CorrectedDocument = DeliveryFinalLeverage.Recorder
		|					OR DocumentCorrections.PreviousCorrection = DeliveryFinalLeverage.Recorder)
		|WHERE
		|	DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover > 0
		|{WHERE
		|	DeliveryFinalLeverage.Recipient AS FinalRecipientIsFinalLeverage,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|			ELSE UNDEFINED
		|		END).* AS FinalRecipient,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|		END).* AS FinalRecipientPoint,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|		END).* AS AreaOfFinalRecipient}
		|
		|GROUP BY
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	DeliveryTurnover.DeliveryType,
		|	DeliveryTurnover.ReferenceOrder,
		|	DeliveryTurnover.Series,
		|	DeliveryTurnover.Characteristic,
		|	DeliveryTurnover.Products,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END";
		
	EndIf;
	
	SubstituteSelectionOfDeliveryRevolutionsByParametersInRequest(QueryTextByGoods);
	SubstituteSelectionOfDeliveryRevolutionsByLayoutInRequest(QueryTextByGoods);
	
	ExpressionPackagingUnitWeight = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByGoods = StrReplace(QueryTextByGoods, "&ExpressionPackagingUnitWeight", ExpressionPackagingUnitWeight);
	
	ExpressionPackagingUnitVolume = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByGoods = StrReplace(QueryTextByGoods, "&ExpressionPackagingUnitVolume", ExpressionPackagingUnitVolume);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryTextByGoods;
	ListProperties.MainTable = "AccumulationRegister.Delivery.Turnovers";
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.ListByItem, ListProperties);
	
EndProcedure

&AtServer
Procedure ClarifyListRequestForGoodsForDeliveryOrder()
	
	If Object.ConsiderQuantityInDocument Then
		
		QueryTextByGoods =
		"SELECT
		|	DeliveryOrderGoods.ReferenceOrder AS ReferenceOrder,
		|	DeliveryOrderGoods.DeliveryLineCode AS RowCode,
		|	SUM(DeliveryOrderGoods.Count) AS Count
		|INTO TTContentsOfDocument
		|FROM
		|	Document.DeliveryOrder.Goods AS DeliveryOrderGoods
		|WHERE
		|	DeliveryOrderGoods.Ref = &DocumentDeliveries
		|
		|GROUP BY
		|	DeliveryOrderGoods.ReferenceOrder,
		|	DeliveryOrderGoods.DeliveryLineCode
		|
		|INDEX BY SETS (
		|	(ReferenceOrder, RowCode)
		|)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.RowCode AS RowCode
		|INTO TTBalancesOnEndArm
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Arm = 2
		|				AND Organization = &Organization
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|		LEFT JOIN TTContentsOfDocument AS TTContentsOfDocument
		|		ON DeliveryTurnover.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = TTContentsOfDocument.RowCode
		|WHERE
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0) > 0
		|
		|INDEX BY SETS (
		|	(ReferenceOrder, RowCode)
		|)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.Carrier AS Carrier,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	DeliveryTurnover.Products AS Products,
		|	DeliveryTurnover.Characteristic AS Characteristic,
		|	DeliveryTurnover.Series AS Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	SUM(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0)) AS Balance,
		|	0 AS Selected,
		|	SUM((DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitWeight) AS Weight,
		|	SUM((DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitVolume) AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|{SELECT
		|	DateOfShipment,
		|	DeliveryMethod.*,
		|	Sender.*,
		|	Recipient.*,
		|	Carrier.*,
		|	RecipientPoint.*,
		|	Recipient_Area.*,
		|	ReferenceOrder.*,
		|	DeliveryType,
		|	Products.*,
		|	Characteristic.*,
		|	Series.*,
		|	Package.*,
		|	Balance,
		|	Selected,
		|	Weight,
		|	VolumeM3,
		|	PictureIndex,
		|	Detailing,
		|	ThereAreDifferences_InDeliveryParameters,
		|	OptionsForDeliveryParameters}
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			&SelectionByParameters
		|				{&SelectionByLayout}
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|		LEFT JOIN TTContentsOfDocument AS TTContentsOfDocument
		|		ON DeliveryTurnover.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = TTContentsOfDocument.RowCode
		|WHERE
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0) > 0
		|
		|GROUP BY
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.Carrier,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder,
		|	DeliveryTurnover.DeliveryType,
		|	DeliveryTurnover.Products,
		|	DeliveryTurnover.Characteristic,
		|	DeliveryTurnover.Series
		|
		|UNION ALL
		|
		|SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.Carrier AS Carrier,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	DeliveryTurnover.Products AS Products,
		|	DeliveryTurnover.Characteristic AS Characteristic,
		|	DeliveryTurnover.Series AS Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	SUM(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0)) AS Balance,
		|	0 AS Selected,
		|	SUM((DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitWeight) AS Weight,
		|	SUM((DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitVolume) AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Arm = 1
		|				AND Sender = &Warehouse
		|				AND (ReferenceOrder, RowCode) IN
		|					(SELECT
		|						BalancesOnFinalArm.ReferenceOrder,
		|						BalancesOnFinalArm.RowCode
		|					FROM
		|						TTBalancesOnEndArm AS BalancesOnFinalArm)
		|				{&SelectionByLayout}) AS DeliveryTurnover
		|		LEFT JOIN TTContentsOfDocument AS TTContentsOfDocument
		|		ON DeliveryTurnover.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = TTContentsOfDocument.RowCode
		|WHERE
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover - ISNULL(TTContentsOfDocument.Count, 0) > 0
		|
		|GROUP BY
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.Carrier,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder,
		|	DeliveryTurnover.DeliveryType,
		|	DeliveryTurnover.Products,
		|	DeliveryTurnover.Characteristic,
		|	DeliveryTurnover.Series";
		
		CommonClientServer.SetDynamicListParameter(
			ListByItem, "DocumentDeliveries", Object.DocumentDeliveries);
		
	Else
		
		QueryTextByGoods =
		"SELECT DISTINCT
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.RowCode AS RowCode
		|INTO TTBalancesOnEndArm
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Arm = 2
		|				AND Organization = &Organization
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|WHERE
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover > 0
		|
		|INDEX BY
		|	ReferenceOrder,
		|	RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.Carrier AS Carrier,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	DeliveryTurnover.Products AS Products,
		|	DeliveryTurnover.Characteristic AS Characteristic,
		|	DeliveryTurnover.Series AS Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover AS Balance,
		|	0 AS Selected,
		|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) * &ExpressionPackagingUnitWeight AS Weight,
		|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) * &ExpressionPackagingUnitVolume AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|{SELECT
		|	DateOfShipment,
		|	DeliveryMethod.*,
		|	Sender.*,
		|	Recipient.*,
		|	Carrier.*,
		|	RecipientPoint.*,
		|	Recipient_Area.*,
		|	ReferenceOrder.*,
		|	DeliveryType,
		|	Products.*,
		|	Characteristic.*,
		|	Series.*,
		|	Package.*,
		|	Balance,
		|	Selected,
		|	Weight,
		|	VolumeM3,
		|	PictureIndex,
		|	Detailing,
		|	ThereAreDifferences_InDeliveryParameters,
		|	OptionsForDeliveryParameters}
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			&SelectionByParameters
		|				{&SelectionByLayout}
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|WHERE
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover > 0
		|
		|UNION ALL
		|
		|SELECT
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.Carrier,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	DeliveryTurnover.ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	DeliveryTurnover.Products,
		|	DeliveryTurnover.Characteristic,
		|	DeliveryTurnover.Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover,
		|	0,
		|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) * &ExpressionPackagingUnitWeight AS Weight,
		|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) * &ExpressionPackagingUnitVolume AS VolumeM3,
		|	-1,
		|	NULL,
		|	FALSE,
		|	NULL
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Arm = 1
		|				AND Sender = &Warehouse
		|				AND (ReferenceOrder, RowCode) IN
		|					(SELECT
		|						BalancesOnFinalArm.ReferenceOrder,
		|						BalancesOnFinalArm.RowCode
		|					FROM
		|						TTBalancesOnEndArm AS BalancesOnFinalArm)
		|				{&SelectionByLayout}) AS DeliveryTurnover
		|WHERE
		|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover > 0";
		
	EndIf;
	
	SubstituteSelectionOfDeliveryRevolutionsByParametersInRequest(QueryTextByGoods);
	SubstituteSelectionOfDeliveryRevolutionsByLayoutInRequest(QueryTextByGoods);
	
	ExpressionPackagingUnitWeight = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByGoods = StrReplace(QueryTextByGoods, "&ExpressionPackagingUnitWeight", ExpressionPackagingUnitWeight);
	
	ExpressionPackagingUnitVolume = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByGoods = StrReplace(QueryTextByGoods, "&ExpressionPackagingUnitVolume", ExpressionPackagingUnitVolume);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryTextByGoods;
	ListProperties.MainTable = "AccumulationRegister.Delivery.Turnovers";
	ListProperties.DynamicDataRead = False;
	Common.SetDynamicListProperties(Items.ListByItem, ListProperties);
	
EndProcedure

&AtServer
Procedure RefineListRequestByDocuments()
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		Return;
	EndIf;
	
	If Object.ConsiderQuantityInDocument Then
		
		QueryTextByDocuments =
		"SELECT
		|	TripContent.ReferenceOrder AS ReferenceOrder,
		|	TripContent.RowCode AS RowCode,
		|	TripContent.PlanningDocument AS PlanningDocument,
		|	SUM(TripContent.Count) AS Count
		|INTO TTContentsOfDocument
		|FROM
		|	Document.Trip.Content AS TripContent
		|WHERE
		|	TripContent.Ref = &DocumentDeliveries
		|	AND NOT TripContent.Canceled
		|
		|GROUP BY
		|	TripContent.ReferenceOrder,
		|	TripContent.PlanningDocument,
		|	TripContent.RowCode
		|
		|INDEX BY
		|	ReferenceOrder,
		|	PlanningDocument,
		|	RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END AS FinalRecipient,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END AS FinalRecipientPoint,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END AS AreaOfFinalRecipient,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitWeight) AS Weight,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover - ISNULL(TTContentsOfDocument.Count, 0)) * &ExpressionPackagingUnitVolume) AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|{SELECT
		|	DateOfShipment,
		|	DeliveryMethod.*,
		|	Sender.*,
		|	Recipient.*,
		|	RecipientPoint.*,
		|	Recipient_Area.*,
		|	FinalRecipient.*,
		|	FinalRecipientPoint.*,
		|	AreaOfFinalRecipient.*,
		|	ReferenceOrder.*,
		|	DeliveryType,
		|	Weight,
		|	VolumeM3,
		|	PictureIndex,
		|	Detailing,
		|	ThereAreDifferences_InDeliveryParameters,
		|	OptionsForDeliveryParameters}
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			&SelectionByParameters
		|				{&SelectionByLayout}
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|		LEFT JOIN TTContentsOfDocument AS TTContentsOfDocument
		|		ON DeliveryTurnover.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = TTContentsOfDocument.RowCode
		|			AND DeliveryTurnover.PlanningDocument = TTContentsOfDocument.PlanningDocument
		|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
		|		ON DeliveryTurnover.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = DeliveryFinalLeverage.RowCode
		|			AND DeliveryTurnover.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
		|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
		|			AND (DeliveryFinalLeverage.OperationLevel IN (&PreviousLevelsOfOperations))
		|			AND NOT 1 IN
		|				(SELECT TOP 1
		|					1
		|				FROM
		|					InformationRegister.DocumentCorrections AS DocumentCorrections
		|				WHERE
		|					DocumentCorrections.CorrectedDocument = DeliveryFinalLeverage.Recorder
		|					OR DocumentCorrections.PreviousCorrection = DeliveryFinalLeverage.Recorder)
		|{WHERE
		|	DeliveryFinalLeverage.Recipient AS FinalRecipientIsFinalLeverage,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|			ELSE UNDEFINED
		|		END).* AS FinalRecipient,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|		END).* AS FinalRecipientPoint,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|		END).* AS AreaOfFinalRecipient}
		|
		|GROUP BY
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END,
		|	DeliveryTurnover.ReferenceOrder,
		|	DeliveryTurnover.DeliveryType
		|
		|HAVING
		|	SUM(DeliveryTurnover.ToTripTurnover) - SUM(DeliveryTurnover.InTripTurnover) + SUM(DeliveryTurnover.CanceledTurnover) - SUM(ISNULL(TTContentsOfDocument.Count, 0)) > 0";
		
		CommonClientServer.SetDynamicListParameter(
			ListByDocuments, "DocumentDeliveries", Object.DocumentDeliveries);
		
	Else
		
		QueryTextByDocuments =
		"SELECT
		|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Recipient AS Recipient,
		|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
		|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END AS FinalRecipient,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END AS FinalRecipientPoint,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END AS AreaOfFinalRecipient,
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.DeliveryType AS DeliveryType,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover) * &ExpressionPackagingUnitWeight) AS Weight,
		|	SUM((DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover) * &ExpressionPackagingUnitVolume) AS VolumeM3,
		|	-1 AS PictureIndex,
		|	NULL AS Detailing,
		|	FALSE AS ThereAreDifferences_InDeliveryParameters,
		|	NULL AS OptionsForDeliveryParameters
		|{SELECT
		|	DateOfShipment,
		|	DeliveryMethod.*,
		|	Sender.*,
		|	Recipient.*,
		|	RecipientPoint.*,
		|	Recipient_Area.*,
		|	FinalRecipient.*,
		|	FinalRecipientPoint.*,
		|	AreaOfFinalRecipient.*,
		|	ReferenceOrder.*,
		|	DeliveryType,
		|	Weight,
		|	VolumeM3,
		|	PictureIndex,
		|	Detailing,
		|	ThereAreDifferences_InDeliveryParameters,
		|	OptionsForDeliveryParameters}
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			&SelectionByParameters
		|				{&SelectionByLayout}
		|				{(Recipient).* AS FinalRecipientIsTurnover}) AS DeliveryTurnover
		|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
		|		ON DeliveryTurnover.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = DeliveryFinalLeverage.RowCode
		|			AND DeliveryTurnover.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
		|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
		|			AND (DeliveryFinalLeverage.OperationLevel IN (&PreviousLevelsOfOperations))
		|			AND NOT 1 IN
		|				(SELECT TOP 1
		|					1
		|				FROM
		|					InformationRegister.DocumentCorrections AS DocumentCorrections
		|				WHERE
		|					DocumentCorrections.CorrectedDocument = DeliveryFinalLeverage.Recorder
		|					OR DocumentCorrections.PreviousCorrection = DeliveryFinalLeverage.Recorder)
		|WHERE
		|	DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover > 0
		|{WHERE
		|	DeliveryFinalLeverage.Recipient AS FinalRecipientIsFinalLeverage,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|			ELSE UNDEFINED
		|		END).* AS FinalRecipient,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|		END).* AS FinalRecipientPoint,
		|	(CASE
		|			WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|				THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|			ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|		END).* AS AreaOfFinalRecipient}
		|
		|GROUP BY
		|	DeliveryTurnover.DateOfShipment,
		|	DeliveryTurnover.DeliveryMethod,
		|	DeliveryTurnover.Sender,
		|	DeliveryTurnover.Recipient,
		|	DeliveryTurnover.RecipientPoint,
		|	DeliveryTurnover.Recipient_Area,
		|	DeliveryTurnover.DeliveryType,
		|	DeliveryTurnover.ReferenceOrder,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED)
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END,
		|	CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END";
		
	EndIf;
	
	SubstituteSelectionOfDeliveryRevolutionsByParametersInRequest(QueryTextByDocuments);
	SubstituteSelectionOfDeliveryRevolutionsByLayoutInRequest(QueryTextByDocuments);
	
	ExpressionPackagingUnitWeight = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByDocuments = StrReplace(QueryTextByDocuments, "&ExpressionPackagingUnitWeight", ExpressionPackagingUnitWeight);
	
	ExpressionPackagingUnitVolume = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByDocuments = StrReplace(QueryTextByDocuments, "&ExpressionPackagingUnitVolume", ExpressionPackagingUnitVolume);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryTextByDocuments;
	ListProperties.MainTable = "AccumulationRegister.Delivery.Turnovers";
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.ListByDocuments, ListProperties);
	
EndProcedure

&AtServerNoContext
Procedure SubstituteSelectionOfDeliveryRevolutionsByParametersInRequest(QueryText)
	
	FilterConditions =
	"Arm = 1
	|AND Organization = &Organization
	|AND Sender = &Warehouse";
	
	QueryText = StrReplace(QueryText, "&SelectionByParameters", FilterConditions);
	
EndProcedure

&AtServerNoContext
Procedure SubstituteSelectionOfDeliveryRevolutionsByLayoutInRequest(QueryText)
	
	FilterConditions =
	"(Carrier).* AS Carrier,
	|(DateOfShipment) AS DateOfShipment,
	|(DateOfShipment >= &DateOfShipmentFrom),
	|(DateOfShipment <= &DateOfShipmentBy),
	|(Recipient).* AS Recipient,
	|(Recipient_Area).* AS Recipient_Area,
	|(RecipientPoint).* AS RecipientPoint,
	|(DeliveryType) AS DeliveryType,
	|(DeliveryMethod) AS DeliveryMethod,
	|(ReferenceOrder).* AS ReferenceOrder,
	|(Products).*, (Characteristic).*, (Series).*";
	
	QueryText = StrReplace(QueryText, "&SelectionByLayout", FilterConditions);
	
EndProcedure

&AtServerNoContext
Function SelectionOfDetailedBalances(ThisIsListByGoods, OutputFinalRecipient)
	
	SelectionOfDetailedBalances = New Structure;
	SelectionOfDetailedBalances.Insert("ReferenceOrder", Undefined);
	SelectionOfDetailedBalances.Insert("Sender", Catalogs.Warehouses.EmptyRef());
	SelectionOfDetailedBalances.Insert("DeliveryMethod", Enums.TransportMethods25.EmptyRef());
	SelectionOfDetailedBalances.Insert("Recipient", Catalogs.Partners.EmptyRef());
	SelectionOfDetailedBalances.Insert("RecipientPoint", Catalogs.DeliveryPoints.EmptyRef());
	SelectionOfDetailedBalances.Insert("Recipient_Area", Catalogs.DeliveryZones.EmptyRef());
	SelectionOfDetailedBalances.Insert("DateOfShipment", '00010101');
	
	If ThisIsListByGoods Then
		
		SelectionOfDetailedBalances.Insert("Products", Catalogs.Products.EmptyRef());
		SelectionOfDetailedBalances.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
		SelectionOfDetailedBalances.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
		SelectionOfDetailedBalances.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
	EndIf;
	
	If OutputFinalRecipient Then
		
		SelectionOfDetailedBalances.Insert("FinalRecipient", Catalogs.Partners.EmptyRef());
		SelectionOfDetailedBalances.Insert("FinalRecipientPoint", Catalogs.DeliveryPoints.EmptyRef());
		SelectionOfDetailedBalances.Insert("AreaOfFinalRecipient", Catalogs.DeliveryZones.EmptyRef());
		
	EndIf;
	
	Return SelectionOfDetailedBalances;
	
EndFunction

&AtServerNoContext
Function DeliveryZoneByPoint(Val DeliveryPoint)
	
	PointDetails = Common.ObjectAttributesValues(DeliveryPoint, "DeliveryZone");
	Return PointDetails.DeliveryZone;
	
EndFunction

// Parameters:
//  RowData - See DeliverListLineData
//  SelectedDeliveryOptions - FormDataStructure, Structure - Selected Delivery Options
//
&AtServer
Procedure AddLinesToMatchedServer(Val RowData, Val SelectedDeliveryOptions)
	
	LineSelectionSelectedWithoutParameters = New Structure;
	LineSelectionSelectedWithoutParameters.Insert("ReferenceOrder", RowData.ReferenceOrder);
	LineSelectionSelectedWithoutParameters.Insert("PlanningDocument", Undefined);
	LineSelectionSelectedWithoutParameters.Insert("RowCode", 0);
	
	SelectionOfRowsSelectedWithParameters = New Structure;
	SelectionOfRowsSelectedWithParameters.Insert("ReferenceOrder", RowData.ReferenceOrder);
	SelectionOfRowsSelectedWithParameters.Insert("PlanningDocument", Undefined);
	SelectionOfRowsSelectedWithParameters.Insert("RowCode", 0);
	SelectionOfRowsSelectedWithParameters.Insert("DeliveryTo", SelectedDeliveryOptions.Recipient);
	SelectionOfRowsSelectedWithParameters.Insert("DeliveryPoint", SelectedDeliveryOptions.RecipientPoint);
	SelectionOfRowsSelectedWithParameters.Insert("DeliveryZone", SelectedDeliveryOptions.Recipient_Area);
	
	DetailsOfLine = RowData.Detailing.Get();
	ModifiedRows = New Array; // Array of FormDataCollectionItem
	
	For Each DetailOption In DetailsOfLine Do
		
		FillPropertyValues(LineSelectionSelectedWithoutParameters, DetailOption);
		FillPropertyValues(SelectionOfRowsSelectedWithParameters, DetailOption);
		
		SelectedOnlyByCode = Selected.Unload(LineSelectionSelectedWithoutParameters, "Count");
		QuantityIsSelected = SelectedOnlyByCode.Total("Count");
		BalanceForDetailOption = Max(DetailOption.Balance - QuantityIsSelected, 0);
		If BalanceForDetailOption <= 0 Then
			Continue;
		EndIf;
		
		LinesSelectedByParameters = Selected.FindRows(SelectionOfRowsSelectedWithParameters);
		If LinesSelectedByParameters.Count() > 0 Then
			
			StringMatched = LinesSelectedByParameters[0];
			
		Else
			
			StringMatched = Selected.Add();
			FillPropertyValues(StringMatched, RowData);
			FillPropertyValues(StringMatched, DetailOption);
			FillPropertyValues(StringMatched, SelectionOfRowsSelectedWithParameters);
			
		EndIf;
		
		StringMatched.Count = StringMatched.Count + BalanceForDetailOption;
		ModifiedRows.Add(StringMatched);
		
	EndDo;
	
	UpdateSelectedInDeliverList();
	
	FillInServiceDetailsOfItemSelected(ModifiedRows);
	
	For Each StringMatched In ModifiedRows Do
		RecalculateWeightVolumeInCommonUnits(StringMatched);
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateSelectedInDeliverList()
	
	AuxProperties = AdditionalPropertiesOfListSettings(ListByItem.SettingsComposer.Settings);
	AddressOfTableIsSelected = AuxProperties.AddressOfTableIsSelected;
	TableMatched = Selected.Unload();
	PutToTempStorage(TableMatched, AddressOfTableIsSelected);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfItemSelected(ModifiedRows)
	
	StructureOfActions = New Structure;
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActions.Insert("CheckFillPackageByOwner", Undefined);
	
	StructureOfActions.Insert("FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	StructureOfActions.Insert("FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	StructureOfActions.Insert("FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	StructureOfActions.Insert("FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows, StructureOfActions, Selected, CachedValues);
	
	For Each StringMatched In ModifiedRows Do
		FillInNetWeightOfUnit(StringMatched);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInNetWeightOfUnit(StringMatched)
	
	EmptyPackaging = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	ProductData_1 = CoefficientsWeightVolume(StringMatched.Products, EmptyPackaging);
	StringMatched.NetWeightUnits = ProductData_1.Net_Weight; // Number
	
EndProcedure

&AtServerNoContext
Function CoefficientsWeightVolume(Val Products, Val Package)
	
	Return Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Package, Products,, False);
	
EndFunction

&AtClientAtServerNoContext
Procedure RecalculateWeightVolumeInCommonUnits(StringMatched)
	
	// volume in cubic meters
	StringMatched.VolumeM3 = StringMatched.Count * StringMatched.PackageVolume;
	
	// gross weight in kg
	StringMatched.Weight = StringMatched.Count * StringMatched.PackageWeight;
	
EndProcedure

&AtServer
Function ParametersOfDeliveryParameterSelectionForm(Val TagName, Val RowSelected, Val RowData)
	
	Result = New Structure;
	
	ThisIsListByGoods = (TagName = Items.ListByItem.Name);
	Result.Insert("ForListByItem", ThisIsListByGoods);
	
	VariantsTable = OptionsForDeliveryParametersByLine(RowData);
	
	VariantsTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	VariantsTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	VariantsTable.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	VariantsTable.Columns.Add("ReferenceOrder", Metadata.DefinedTypes.DeliveryReferenceOrder25.Type);
	VariantsTable.Columns.Add("PlannedParameters", New TypeDescription("Boolean"));
	
	ThereArePlannedParameters = False;
	
	OutputFinalRecipient =
		(TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
			And Object.DocumentDeliveryMethod = Enums.TransportMethods25.ByCarrier);
	
	UseDataOfFinalRecipient =
		(OutputFinalRecipient
			And ValueIsFilled(RowData.FinalRecipient)
			And ValueIsFilled(RowData.FinalRecipientPoint)
			And ValueIsFilled(RowData.AreaOfFinalRecipient));
	
	If UseDataOfFinalRecipient Then
		
		PlannedRecipient = RowData.FinalRecipient;
		RecipientSPlannedPoint = RowData.FinalRecipientPoint;
		RecipientSPlannedArea = RowData.AreaOfFinalRecipient;
		
	Else
		
		PlannedRecipient = RowData.Recipient;
		RecipientSPlannedPoint = RowData.RecipientPoint;
		RecipientSPlannedArea = RowData.Recipient_Area;
		
	EndIf;
	
	For Each StringOfOptions In VariantsTable Do
		
		FillPropertyValues(StringOfOptions, RowData);
		
		If StringOfOptions.ContentPointOfRecipient = RecipientSPlannedPoint
		   And StringOfOptions.ContentRecipientSArea = RecipientSPlannedArea Then
			
			StringOfOptions.PlannedParameters = True;
			ThereArePlannedParameters = True;
			
		EndIf;
		
	EndDo;
	
	VariantsTable.Columns.ContentPointOfRecipient.Name = "DeliveryPoint";
	VariantsTable.Columns.ContentRecipientSArea.Name = "DeliveryZone";
	VariantsTable.Columns.RecipientContent.Name = "DeliveryTo";
	
	If Not ThereArePlannedParameters Then
		
		StringOfPlannedParameters = VariantsTable.Add();
		FillPropertyValues(StringOfPlannedParameters, RowData);
		StringOfPlannedParameters.DeliveryTo = PlannedRecipient;
		StringOfPlannedParameters.DeliveryPoint = RecipientSPlannedPoint;
		StringOfPlannedParameters.DeliveryZone = RecipientSPlannedArea;
		StringOfPlannedParameters.PlannedParameters = True;
		
	EndIf;
	
	VariantsTable.Sort("PlannedParameters Desc");
	
	AddressOfOptionsTable = PutToTempStorage(VariantsTable);
	Result.Insert("AddressOfOptionsTable", AddressOfOptionsTable);
	
	Result.Insert("RowSelected", RowSelected);
	
	Return Result;
	
EndFunction

// Parameters:
//  SelectedOptions - DialogReturnCode, Undefined, Structure - Selected parameters:
//  * RowSelected - Number
//  * Recipient - CatalogRef.Partners
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  AdditionalParameters - String - Name Of The List Item
//
&AtClient
Procedure ListDeliverSelectionCompletion(SelectedOptions, AdditionalParameters) Export
	
	If TypeOf(SelectedOptions) = Type("Structure") Then
		
		TagName = AdditionalParameters;
		RowData = Items[TagName].RowData(SelectedOptions.RowSelected); // See DeliverListLineData
		AddLinesToMatchedServer(RowData, SelectedOptions);
		
		Items.ListByItem.Refresh();
		Items.ListByDocuments.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PlaceSelectedGoodsInVault()
	
	TableMatched = Selected.Unload();
	
	AnalysisColumns = "ReferenceOrder, PlanningDocument, RowCode";
	TableIsCollapsedSelected = TableMatched.Copy(, AnalysisColumns);
	TableIsCollapsedSelected.GroupBy(AnalysisColumns);
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TTExternalData.ReferenceOrder AS ReferenceOrder,
	|	TTExternalData.PlanningDocument AS PlanningDocument,
	|	TTExternalData.RowCode AS RowCode
	|INTO TTDataContent
	|FROM
	|	&ExternalData AS TTExternalData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTExternalData.ReferenceOrder AS ReferenceOrder,
	|	TTExternalData.PlanningDocument AS PlanningDocument,
	|	TTExternalData.RowCode AS RowCode,
	|	ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED) AS Recipient,
	|	ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS RecipientPoint,
	|	ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Recipient_Area
	|FROM
	|	TTDataContent AS TTExternalData
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
	|		ON TTExternalData.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
	|			AND TTExternalData.RowCode = DeliveryFinalLeverage.RowCode
	|			AND TTExternalData.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
	|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
	|			AND (DeliveryFinalLeverage.OperationLevel IN (&PreviousLevelsOfOperations))";
	Query.Text = QueryText;
	Query.SetParameter("ExternalData", TableIsCollapsedSelected);
	Query.SetParameter("PreviousLevelsOfOperations", PreviousLevelsOfOperations);
	DeliveryDataPlan = Query.Execute().Unload();
	
	Type_Destination = New TypeDescription("CatalogRef.Partners, CatalogRef.Warehouses");
	TypeDeliveryPoint = New TypeDescription("CatalogRef.DeliveryPoints");
	TypeOfDeliveryZone = New TypeDescription("CatalogRef.DeliveryZones");
	
	TableMatched.Columns.Add("FinalDestination", Type_Destination);
	TableMatched.Columns.Add("FinalDeliveryPoint", TypeDeliveryPoint);
	TableMatched.Columns.Add("FinalDeliveryArea", TypeOfDeliveryZone);
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ReferenceOrder");
	TheStructureOfTheSearch.Insert("PlanningDocument");
	TheStructureOfTheSearch.Insert("RowCode");
	
	For Each RowOfGoods In TableMatched Do
		
		If Object.RecordDeliveryParameters Then
			
			RowOfGoods.DeliveryPoint = Object.DeliveryPointFixed;
			RowOfGoods.DeliveryZone = Object.DeliveryZoneFixed;
			
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		DataRows = DeliveryDataPlan.FindRows(TheStructureOfTheSearch);
		If DataRows.Count() > 0 Then
			
			DataString1 = DataRows[0];
			
			If RowOfGoods.DeliveryTo <> DataString1.Recipient Then
				
				RowOfGoods.FinalDestination = DataString1.Recipient;
				RowOfGoods.FinalDeliveryPoint = DataString1.RecipientPoint;
				RowOfGoods.FinalDeliveryArea = DataString1.Recipient_Area;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	AddressOfSelectedItems = PutToTempStorage(TableMatched, UUID);
	
EndProcedure

// Parameters:
//  QuestionResult - DialogReturnCode
//  AdditionalParameters - Undefined
// 
&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		MoveToDocument = True;
		ClosingInProgress = True;
		PlaceSelectedGoodsInVault();
		Close(DialogReturnCode.OK);
		ClosingInProgress = False;
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		
		ClosingInProgress = True;
		Close();
		ClosingInProgress = False;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Rows - DynamicListRows - 
//  DocumentDeliveries - DocumentRef.Trip - 
//  ConsiderQuantityInDocument - Boolean - 
//  ThisIsListByGoods - Boolean -
//  QueryText - String
// 
// Returns:
//  Structure - Detailed Data Portions Of Rows:
// * DeliveryParametersOfPortionContents - ValueTable
// * PortionFlags - ValueTable:
//   ** ItIsInContent - Boolean
//   ** ThereAreDifferences_InDeliveryParameters - Boolean
// * DetailedPortionLeftovers - ValueTable -
//
&AtServerNoContext
Function DetailedDataPortionsOfRows(Rows, DocumentDeliveries, ConsiderQuantityInDocument, ThisIsListByGoods, QueryText, PreviousLevelsOfOperations)
	
	DispositionsOfPortionOfLines = New Array; // Array of DefinedType.DeliveryReferenceOrder25
	ItemOfPortionOfLines = New Array; // Array of CatalogRef.Products
	
	For Each ListLine In Rows Do
		
		ListLineData = DeliverListLineData(ListLine);
		
		If DispositionsOfPortionOfLines.Find(ListLineData.ReferenceOrder) = Undefined Then
			DispositionsOfPortionOfLines.Add(ListLineData.ReferenceOrder);
		EndIf;
		
		If ThisIsListByGoods Then
			
			If ItemOfPortionOfLines.Find(ListLineData.Products) = Undefined Then
				ItemOfPortionOfLines.Add(ListLineData.Products);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DispositionsOfPortionOfLines", DispositionsOfPortionOfLines);
	If ThisIsListByGoods Then
		Query.SetParameter("ItemOfPortionOfLines", ItemOfPortionOfLines);
	EndIf;
	Query.SetParameter("DocumentDeliveries", DocumentDeliveries);
	Query.SetParameter("ConsiderQuantityInDocument", ConsiderQuantityInDocument);
	Query.SetParameter("PreviousLevelsOfOperations", PreviousLevelsOfOperations);
	
	QueryResult = Query.ExecuteBatch();
	DeliveryParametersOfPortionContents = QueryResult[QueryResult.UBound() - 2].Unload();
	PortionFlags = QueryResult[QueryResult.UBound() - 1].Unload();
	DetailedPortionLeftovers = QueryResult[QueryResult.UBound()].Unload();
	
	Result = New Structure;
	Result.Insert("DeliveryParametersOfPortionContents", DeliveryParametersOfPortionContents);
	Result.Insert("PortionFlags", PortionFlags);
	Result.Insert("DetailedPortionLeftovers", DetailedPortionLeftovers);
	
	Return Result;
	
EndFunction

&AtServer
Function QueryTextDetailedDataPortionsOfRows(ThisIsListByGoods, ConsiderQuantityInDocument)
	
	QueryBatch = New Array; // Array of String
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		
		QueryTextTTDocumentContent =
		"SELECT
		|	DeliveryOrderGoods.ReferenceOrder AS ReferenceOrder,
		|	DeliveryOrderGoods.DeliveryLineCode AS RowCode,
		|	UNDEFINED AS PlanningDocument,
		|	DeliveryOrder.DeliveryPointRecipient AS RecipientPoint,
		|	DeliveryOrder.DeliveryZone AS Recipient_Area,
		|	DeliveryOrder.Recipient AS Recipient,
		|	DeliveryOrderGoods.Count AS Count
		|INTO TTContentsOfDocument
		|FROM
		|	Document.DeliveryOrder.Goods AS DeliveryOrderGoods
		|		INNER JOIN Document.DeliveryOrder AS DeliveryOrder
		|		ON (DeliveryOrderGoods.Ref = &DocumentDeliveries)
		|			AND (DeliveryOrder.Ref = &DocumentDeliveries)";
		
	Else
		
		QueryTextTTDocumentContent =
		"SELECT
		|	TripContent.ReferenceOrder AS ReferenceOrder,
		|	TripContent.RowCode AS RowCode,
		|	TripContent.PlanningDocument AS PlanningDocument,
		|	TripRoute.DeliveryPoint AS RecipientPoint,
		|	TripRoute.DeliveryZone AS Recipient_Area,
		|	TripRoute.Point AS Recipient,
		|	TripContent.Count AS Count
		|INTO TTContentsOfDocument
		|FROM
		|	Document.Trip.Content AS TripContent
		|		INNER JOIN Document.Trip.Route AS TripRoute
		|		ON (TripContent.Ref = &DocumentDeliveries)
		|			AND (TripRoute.Ref = &DocumentDeliveries)
		|			AND TripContent.ConnectionKey = TripRoute.ConnectionKey
		|WHERE
		|	NOT TripContent.Canceled";
		
	EndIf;
	
	QueryBatch.Add(QueryTextTTDocumentContent);
	
	QueryTextTTContentOfDocumentIsCollapsed =
	"SELECT
	|	TTContentsOfDocument.ReferenceOrder AS ReferenceOrder,
	|	TTContentsOfDocument.RowCode AS RowCode,
	|	TTContentsOfDocument.PlanningDocument AS PlanningDocument,
	|	SUM(TTContentsOfDocument.Count) AS Count
	|INTO TTDocumentContentIsCollapsed
	|FROM
	|	TTContentsOfDocument AS TTContentsOfDocument
	|
	|GROUP BY
	|	TTContentsOfDocument.ReferenceOrder,
	|	TTContentsOfDocument.RowCode,
	|	TTContentsOfDocument.PlanningDocument";
	
	QueryBatch.Add(QueryTextTTContentOfDocumentIsCollapsed);
	
	QueryTextTTBalance =
	"SELECT
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	&ExpressionPlanningDocument AS PlanningDocument,
	|	DeliveryTurnover.RowCode AS RowCode,
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
	|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
	|	DeliveryTurnover.Sender AS Sender,
	|	DeliveryTurnover.Recipient AS Recipient,
	|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
	|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&ExpressionIsFinalRecipient AS FinalRecipient,
	|	&ExpressionIsPointOfFinalRecipient AS FinalRecipientPoint,
	|	&ExpressionAreaOfFinalRecipient AS AreaOfFinalRecipient,
	|	&ExpressionBalance AS Balance
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			Arm = 1
	|				AND ReferenceOrder IN (&DispositionsOfPortionOfLines)
	|				AND &GoodsConditions) AS DeliveryTurnover
	|		LEFT JOIN &DeliveryFinalLeverage AS DeliveryFinalLeverage ON TRUE
	|WHERE
	|	&ExpressionBalance > 0";
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		
		ExpressionBalance = "DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover";
		ExpressionPlanningDocument = "UNDEFINED";
		
	Else
		
		ExpressionBalance = "DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover + DeliveryTurnover.CanceledTurnover";
		ExpressionPlanningDocument = "DeliveryTurnover.PlanningDocument";
		
	EndIf;
	
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&ExpressionBalance", ExpressionBalance);
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&ExpressionPlanningDocument", ExpressionPlanningDocument);
	
	If ThisIsListByGoods Then
		GoodsConditions = "Products IN (&ItemOfPortionOfLines)";
	Else
		GoodsConditions = "TRUE";
	EndIf;
	
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&GoodsConditions", GoodsConditions);
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
	   And Object.DocumentDeliveryMethod = Enums.TransportMethods25.ByCarrier Then
		
		ExpressionIsFinalRecipient = "CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient, VALUE(Catalog.Partners.EmptyRef))
		|		ELSE VALUE(Catalog.Partners.EmptyRef)
		|	END";
		
		ExpressionIsPointOfFinalRecipient = "CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END";
		
		ExpressionAreaOfFinalRecipient = "CASE
		|		WHEN ISNULL(DeliveryFinalLeverage.Arm, 1) > 1
		|			THEN ISNULL(DeliveryFinalLeverage.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
		|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
		|	END";
		
		ConnectionEndArm =
		"		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
		|		ON DeliveryTurnover.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
		|			AND DeliveryTurnover.RowCode = DeliveryFinalLeverage.RowCode
		|			AND DeliveryTurnover.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
		|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
		|			AND (DeliveryFinalLeverage.OperationLevel IN (&PreviousLevelsOfOperations))";
		
	Else
		
		ExpressionIsFinalRecipient = "VALUE(Catalog.Partners.EmptyRef)";
		ExpressionIsPointOfFinalRecipient = "VALUE(Catalog.DeliveryPoints.EmptyRef)";
		ExpressionAreaOfFinalRecipient = "VALUE(Catalog.DeliveryZones.EmptyRef)";
		ConnectionEndArm = "";
		
	EndIf;
	
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&ExpressionIsFinalRecipient", ExpressionIsFinalRecipient);
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&ExpressionIsPointOfFinalRecipient", ExpressionIsPointOfFinalRecipient);
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&ExpressionAreaOfFinalRecipient", ExpressionAreaOfFinalRecipient);
	QueryTextTTBalance = StrReplace(
		QueryTextTTBalance,
		"LEFT JOIN &DeliveryFinalLeverage AS DeliveryFinalLeverage ON TRUE",
		ConnectionEndArm);
	
	QueryBatch.Add(QueryTextTTBalance);
	
	QueryTextDeliveryParameters =
	"SELECT DISTINCT
	|	TTBalance.ReferenceOrder AS ReferenceOrder,
	|	&ItemFields,
	|	TTBalance.DateOfShipment AS DateOfShipment,
	|	TTBalance.DeliveryMethod AS DeliveryMethod,
	|	TTBalance.Sender AS Sender,
	|	TTBalance.Recipient AS Recipient,
	|	TTBalance.RecipientPoint AS RecipientPoint,
	|	TTBalance.Recipient_Area AS Recipient_Area,
	|	TTBalance.FinalRecipient AS FinalRecipient,
	|	TTBalance.FinalRecipientPoint AS FinalRecipientPoint,
	|	TTBalance.AreaOfFinalRecipient AS AreaOfFinalRecipient,
	|	TTContentsOfDocument.RecipientPoint AS ContentPointOfRecipient,
	|	TTContentsOfDocument.Recipient_Area AS ContentRecipientSArea,
	|	TTContentsOfDocument.Recipient AS RecipientContent
	|FROM
	|	TTBalance AS TTBalance
	|		INNER JOIN TTContentsOfDocument AS TTContentsOfDocument
	|		ON TTBalance.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
	|			AND &ConditionOfCommunicationAccordingToPlanningDocument
	|			AND TTBalance.RowCode = TTContentsOfDocument.RowCode";
	
	If ThisIsListByGoods Then
		
		ItemFields =
		"TTBalance.Products AS Products,
		|	TTBalance.Characteristic AS Characteristic,
		|	TTBalance.Series AS Series,
		|	TTBalance.Package AS Package";
		
	Else
		
		ItemFields = "NULL";
		
	EndIf;
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		ConditionOfCommunicationAccordingToPlanningDocument = "TRUE";
	Else
		ConditionOfCommunicationAccordingToPlanningDocument = "TTBalance.PlanningDocument = TTContentsOfDocument.PlanningDocument";
	EndIf;
	
	QueryTextDeliveryParameters = StrReplace(
		QueryTextDeliveryParameters, "&ConditionOfCommunicationAccordingToPlanningDocument", ConditionOfCommunicationAccordingToPlanningDocument);
	QueryTextDeliveryParameters = StrReplace(QueryTextDeliveryParameters, "&ItemFields", ItemFields);
	
	QueryBatch.Add(QueryTextDeliveryParameters);
	
	QueryTextFlags =
	"SELECT
	|	Balance.ReferenceOrder AS ReferenceOrder,
	|	&GoodsExternalFields,
	|	Balance.DateOfShipment AS DateOfShipment,
	|	Balance.DeliveryMethod AS DeliveryMethod,
	|	Balance.Sender AS Sender,
	|	Balance.Recipient AS Recipient,
	|	Balance.RecipientPoint AS RecipientPoint,
	|	Balance.Recipient_Area AS Recipient_Area,
	|	Balance.FinalRecipient AS FinalRecipient,
	|	Balance.FinalRecipientPoint AS FinalRecipientPoint,
	|	Balance.AreaOfFinalRecipient AS AreaOfFinalRecipient,
	|	MAX(Balance.ItIsInContent) AS ItIsInContent,
	|	MAX(Balance.ThereAreDifferences_InDeliveryParameters) AS ThereAreDifferences_InDeliveryParameters
	|FROM
	|	(SELECT
	|		TTBalance.ReferenceOrder AS ReferenceOrder,
	|		&GoodsFieldsAreInternal,
	|		TTBalance.DateOfShipment AS DateOfShipment,
	|		TTBalance.DeliveryMethod AS DeliveryMethod,
	|		TTBalance.Sender AS Sender,
	|		TTBalance.Recipient AS Recipient,
	|		TTBalance.RecipientPoint AS RecipientPoint,
	|		TTBalance.Recipient_Area AS Recipient_Area,
	|		TTBalance.FinalRecipient AS FinalRecipient,
	|		TTBalance.FinalRecipientPoint AS FinalRecipientPoint,
	|		TTBalance.AreaOfFinalRecipient AS AreaOfFinalRecipient,
	|		CASE
	|			WHEN TTContentsOfDocument.RowCode IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END AS ItIsInContent,
	|		CASE
	|			WHEN TTContentsOfDocument.RecipientPoint IS NULL
	|				THEN FALSE
	|			WHEN TTBalance.FinalRecipientPoint = ISNULL(TTContentsOfDocument.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|					AND TTBalance.AreaOfFinalRecipient = ISNULL(TTContentsOfDocument.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
	|				THEN FALSE
	|			WHEN TTBalance.RecipientPoint = ISNULL(TTContentsOfDocument.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|					AND TTBalance.Recipient_Area = ISNULL(TTContentsOfDocument.Recipient_Area, VALUE(Catalog.DeliveryZones.EmptyRef))
	|				THEN FALSE
	|			ELSE TRUE
	|		END AS ThereAreDifferences_InDeliveryParameters
	|	FROM
	|		TTBalance AS TTBalance
	|			LEFT JOIN TTContentsOfDocument AS TTContentsOfDocument
	|			ON TTBalance.ReferenceOrder = TTContentsOfDocument.ReferenceOrder
	|				AND &ConditionOfCommunicationAccordingToPlanningDocument
	|				AND TTBalance.RowCode = TTContentsOfDocument.RowCode) AS Balance
	|
	|GROUP BY
	|	Balance.DateOfShipment,
	|	&GroupFieldsByGoods,
	|	Balance.DeliveryMethod,
	|	Balance.ReferenceOrder,
	|	Balance.Sender,
	|	Balance.Recipient,
	|	Balance.RecipientPoint,
	|	Balance.Recipient_Area,
	|	Balance.FinalRecipient,
	|	Balance.FinalRecipientPoint,
	|	Balance.AreaOfFinalRecipient";
	
	If ThisIsListByGoods Then
		
		GoodsExternalFields =
		"Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Series AS Series,
		|	Balance.Package AS Package";
		
		GoodsFieldsAreInternal =
		"TTBalance.Products AS Products,
		|		TTBalance.Characteristic AS Characteristic,
		|		TTBalance.Series AS Series,
		|		TTBalance.Package AS Package";
		
		GroupFieldsByGoods =
		"Balance.Products,
		|	Balance.Characteristic,
		|	Balance.Series,
		|	Balance.Package";
		
	Else
		
		GoodsExternalFields = "NULL";
		GoodsFieldsAreInternal = "NULL";
		GroupFieldsByGoods = "NULL";
		
	EndIf;
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		ConditionOfCommunicationAccordingToPlanningDocument = "TRUE";
	Else
		ConditionOfCommunicationAccordingToPlanningDocument = "TTBalance.PlanningDocument = TTContentsOfDocument.PlanningDocument";
	EndIf;
	
	QueryTextFlags = StrReplace(
		QueryTextFlags, "&ConditionOfCommunicationAccordingToPlanningDocument", ConditionOfCommunicationAccordingToPlanningDocument);
	QueryTextFlags = StrReplace(QueryTextFlags, "&GoodsExternalFields", GoodsExternalFields);
	QueryTextFlags = StrReplace(QueryTextFlags, "&GoodsFieldsAreInternal", GoodsFieldsAreInternal);
	QueryTextFlags = StrReplace(QueryTextFlags, "&GroupFieldsByGoods", GroupFieldsByGoods);
	
	QueryBatch.Add(QueryTextFlags);
	
	If ConsiderQuantityInDocument Then
		
		QueryTextDetailedBalance =
		"SELECT
		|	TTBalance.ReferenceOrder AS ReferenceOrder,
		|	&PlanningDocument AS PlanningDocument,
		|	TTBalance.RowCode AS RowCode,
		|	TTBalance.Products AS Products,
		|	TTBalance.Characteristic AS Characteristic,
		|	TTBalance.Series AS Series,
		|	TTBalance.Package AS Package,
		|	TTBalance.DateOfShipment AS DateOfShipment,
		|	TTBalance.DeliveryMethod AS DeliveryMethod,
		|	TTBalance.Sender AS Sender,
		|	TTBalance.Recipient AS Recipient,
		|	TTBalance.RecipientPoint AS RecipientPoint,
		|	TTBalance.Recipient_Area AS Recipient_Area,
		|	TTBalance.FinalRecipient AS FinalRecipient,
		|	TTBalance.FinalRecipientPoint AS FinalRecipientPoint,
		|	TTBalance.AreaOfFinalRecipient AS AreaOfFinalRecipient,
		|	SUM(TTBalance.Balance - ISNULL(TTDocumentContentIsCollapsed.Count, 0)) AS Balance
		|FROM
		|	TTBalance AS TTBalance
		|		LEFT JOIN TTDocumentContentIsCollapsed AS TTDocumentContentIsCollapsed
		|		ON TTBalance.ReferenceOrder = TTDocumentContentIsCollapsed.ReferenceOrder
		|			AND TTBalance.RowCode = TTDocumentContentIsCollapsed.RowCode
		|			AND &ConditionOfCommunicationAccordingToPlanningDocument
		|
		|GROUP BY
		|	TTBalance.ReferenceOrder,
		|	&PlanningDocument,
		|	TTBalance.RowCode,
		|	TTBalance.Products,
		|	TTBalance.Characteristic,
		|	TTBalance.Series,
		|	TTBalance.Package,
		|	TTBalance.DateOfShipment,
		|	TTBalance.DeliveryMethod,
		|	TTBalance.Sender,
		|	TTBalance.Recipient,
		|	TTBalance.RecipientPoint,
		|	TTBalance.Recipient_Area,
		|	TTBalance.FinalRecipient,
		|	TTBalance.FinalRecipientPoint,
		|	TTBalance.AreaOfFinalRecipient";
		
	Else
		
		QueryTextDetailedBalance =
		"SELECT
		|	TTBalance.ReferenceOrder AS ReferenceOrder,
		|	&PlanningDocument AS PlanningDocument,
		|	TTBalance.RowCode AS RowCode,
		|	TTBalance.Products AS Products,
		|	TTBalance.Characteristic AS Characteristic,
		|	TTBalance.Series AS Series,
		|	TTBalance.Package AS Package,
		|	TTBalance.DateOfShipment AS DateOfShipment,
		|	TTBalance.DeliveryMethod AS DeliveryMethod,
		|	TTBalance.Sender AS Sender,
		|	TTBalance.Recipient AS Recipient,
		|	TTBalance.RecipientPoint AS RecipientPoint,
		|	TTBalance.Recipient_Area AS Recipient_Area,
		|	TTBalance.FinalRecipient AS FinalRecipient,
		|	TTBalance.FinalRecipientPoint AS FinalRecipientPoint,
		|	TTBalance.AreaOfFinalRecipient AS AreaOfFinalRecipient,
		|	SUM(TTBalance.Balance) AS Balance
		|FROM
		|	TTBalance AS TTBalance
		|
		|GROUP BY
		|	TTBalance.ReferenceOrder,
		|	&PlanningDocument,
		|	TTBalance.RowCode,
		|	TTBalance.Products,
		|	TTBalance.Characteristic,
		|	TTBalance.Series,
		|	TTBalance.Package,
		|	TTBalance.DateOfShipment,
		|	TTBalance.DeliveryMethod,
		|	TTBalance.Sender,
		|	TTBalance.Recipient,
		|	TTBalance.RecipientPoint,
		|	TTBalance.Recipient_Area,
		|	TTBalance.FinalRecipient,
		|	TTBalance.FinalRecipientPoint,
		|	TTBalance.AreaOfFinalRecipient";
		
	EndIf;
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		
		ExpressionPlanningDocument = "UNDEFINED";
		ConditionOfCommunicationAccordingToPlanningDocument = "TRUE";
		
	Else
		
		ExpressionPlanningDocument = "TTBalance.PlanningDocument";
		ConditionOfCommunicationAccordingToPlanningDocument = "TTBalance.PlanningDocument = TTDocumentContentIsCollapsed.PlanningDocument";
		
	EndIf;
	
	QueryTextDetailedBalance = StrReplace(
		QueryTextDetailedBalance, "&PlanningDocument", ExpressionPlanningDocument);
	QueryTextDetailedBalance = StrReplace(
		QueryTextDetailedBalance, "&ConditionOfCommunicationAccordingToPlanningDocument", ConditionOfCommunicationAccordingToPlanningDocument);
	
	QueryBatch.Add(QueryTextDetailedBalance);
	
	QueryText = StrConcat(QueryBatch, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Parameters:
//  ListLine - DynamicListRow
// 
// Returns:
//  FormDataStructure - this line:
//  * Products - CatalogRef.Products
//  * Selected - Number
//  * Balance - Number
//  * ThereAreDifferences_InDeliveryParameters - Boolean
//  * PictureIndex - Number
//  * Detailing - ValueStorage
//  * OptionsForDeliveryParameters - ValueStorage
//  * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//  * DeliveryType - EnumRef.DeliveryTypes
//  * Recipient - CatalogRef.Partners
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  * FinalRecipient - CatalogRef.Partners
//  * FinalRecipientPoint - CatalogRef.DeliveryPoints
//  * AreaOfFinalRecipient - CatalogRef.DeliveryZones
//
&AtServerNoContext
Function DeliverListLineData(ListLine)
	
	ListLineData = ListLine.Value.Data;
	Return ListLineData;
	
EndFunction

// Parameters:
//  Settings - DataCompositionSettings
// 
// Returns:
//  Structure:
//    * ConsiderQuantityInDocument - Boolean
//    * DocumentDeliveries - DocumentRef.Trip
//    * AddressOfTableIsSelected - String
//    * QueryTextDetailedDataPortionsOfRows - String
//    * ThereAreDifferencesInDeliveryParameters - Boolean
//    * PreviousLevelsOfOperations - ValueList of Number
//    * OutputFinalRecipient - Boolean
//  
&AtClientAtServerNoContext
Function AdditionalPropertiesOfListSettings(Settings)
	
	Return Settings.AdditionalProperties;
	
EndFunction

// Parameters:
//  RowData - FormDataStructure
// 
// Returns:
//  ValueTable - Options For Delivery Parameters By Line:
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * Series - CatalogRef.ItemsBatches
// * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
// * PlannedParameters - Boolean
// * RecipientContent - CatalogRef.Partners
// * ContentPointOfRecipient - CatalogRef.DeliveryPoints
// * ContentRecipientSArea - CatalogRef.DeliveryZones
//
&AtServerNoContext
Function OptionsForDeliveryParametersByLine(RowData)
	
	Result = RowData.OptionsForDeliveryParameters.Get(); // ValueTable
	Return Result;
	
EndFunction

// Parameters:
//  AuxProperties - See AdditionalPropertiesOfListSettings
// 
// Returns:
//  ValueTable:
//  * Count - Number
//
&AtServerNoContext
Function TableMatched(AuxProperties)
	
	AddressOfTableIsSelected = AuxProperties.AddressOfTableIsSelected;
	TableMatched = GetFromTempStorage(AddressOfTableIsSelected); // ValueTable
	Return TableMatched;
	
EndFunction

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ThisIsListByGoods = (TagName = "ListByItem");
	
	AuxProperties = AdditionalPropertiesOfListSettings(Settings);
	ConsiderQuantityInDocument = AuxProperties.ConsiderQuantityInDocument;
	DocumentDeliveries = AuxProperties.DocumentDeliveries;
	QueryText = AuxProperties.QueryTextDetailedDataPortionsOfRows;
	PreviousLevelsOfOperations = AuxProperties.PreviousLevelsOfOperations;
	OutputFinalRecipient = AuxProperties.OutputFinalRecipient;
	
	DetailedData = DetailedDataPortionsOfRows(
		Rows, DocumentDeliveries, ConsiderQuantityInDocument, ThisIsListByGoods, QueryText, PreviousLevelsOfOperations);
	
	SelectionOfDetailedBalances = SelectionOfDetailedBalances(ThisIsListByGoods, OutputFinalRecipient);
	ColumnsOfDetailedResidues = "PlanningDocument,RowCode,Balance";
	If Not ThisIsListByGoods Then
		ColumnsOfDetailedResidues = ColumnsOfDetailedResidues + ",Products,Characteristic,Series";
	EndIf;
	
	DeliveryParameterColumns = "ContentPointOfRecipient,ContentRecipientSArea,RecipientContent";
	
	If ThisIsListByGoods Then
		TableMatched = TableMatched(AuxProperties);
	EndIf;
	
	For Each ListLine In Rows Do
		
		ListLineData = DeliverListLineData(ListLine);
		FillPropertyValues(SelectionOfDetailedBalances, ListLineData);
		
		ItIsInContent = False;
		FlagStrings = DetailedData.PortionFlags.FindRows(SelectionOfDetailedBalances);
		If FlagStrings.Count() > 0 Then
			
			ItIsInContent = FlagStrings[0].ItIsInContent;
			ListLineData.ThereAreDifferences_InDeliveryParameters = FlagStrings[0].ThereAreDifferences_InDeliveryParameters;
			
		EndIf;
		
		If ListLineData.ThereAreDifferences_InDeliveryParameters
		   And AuxProperties.ThereAreDifferencesInDeliveryParameters Then
			ListLineData.PictureIndex = 0;
		ElsIf ItIsInContent Then
			ListLineData.PictureIndex = 1;
		Else
			ListLineData.PictureIndex = -1;
		EndIf;
		
		DetailsOfLine = DetailedData.DetailedPortionLeftovers.Copy(SelectionOfDetailedBalances, ColumnsOfDetailedResidues);
		ListLineData.Detailing = New ValueStorage(DetailsOfLine);
		
		OptionsForDeliveryParameters = DetailedData.DeliveryParametersOfPortionContents.Copy(
			SelectionOfDetailedBalances, DeliveryParameterColumns);
		OptionsForDeliveryParameters.GroupBy(DeliveryParameterColumns);
		ListLineData.OptionsForDeliveryParameters = New ValueStorage(OptionsForDeliveryParameters);
		
		If ThisIsListByGoods Then
			
			FillInSelectedInListLine(TableMatched, ListLineData, DetailsOfLine);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure FillInSelectedInListLine(TableMatched, ListLineData, DetailsOfLine)
	
	LineSelectionSelected = New Structure;
	LineSelectionSelected.Insert("ReferenceOrder", Undefined);
	LineSelectionSelected.Insert("PlanningDocument", Undefined);
	LineSelectionSelected.Insert("RowCode", 0);
	
	FillPropertyValues(LineSelectionSelected, ListLineData);
	
	For Each DetailOption In DetailsOfLine Do
		
		FillPropertyValues(LineSelectionSelected, DetailOption);
		LinesMatched = TableMatched.FindRows(LineSelectionSelected);
		
		For Each StringMatched In LinesMatched Do
			
			ListLineData.Selected = ListLineData.Selected + StringMatched.Count;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeAdditionalListProperties()
	
	TableMatched = Selected.Unload();
	AddressOfTableIsSelected = PutToTempStorage(TableMatched, UUID);
	
	ThereAreDifferencesInDeliveryParameters = (TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip"));
	
	OutputFinalRecipient = (TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
		And Object.DocumentDeliveryMethod = Enums.TransportMethods25.ByCarrier);
	
	Lists = New Array; // Array of DynamicList
	Lists.Add(ListByItem);
	Lists.Add(ListByDocuments);
	
	For Each ListOfLeftovers In Lists Do
		
		ThisIsListByGoods = (ListOfLeftovers = ListByItem);
		
		AuxProperties = ListOfLeftovers.SettingsComposer.Settings.AdditionalProperties;
		AuxProperties.Insert("ConsiderQuantityInDocument", Object.ConsiderQuantityInDocument);
		AuxProperties.Insert("DocumentDeliveries", Object.DocumentDeliveries);
		AuxProperties.Insert("AddressOfTableIsSelected", AddressOfTableIsSelected);
		AuxProperties.Insert("ThereAreDifferencesInDeliveryParameters", ThereAreDifferencesInDeliveryParameters);
		AuxProperties.Insert("PreviousLevelsOfOperations", PreviousLevelsOfOperations);
		AuxProperties.Insert("OutputFinalRecipient", OutputFinalRecipient);
		
		QueryText = QueryTextDetailedDataPortionsOfRows(ThisIsListByGoods, Object.ConsiderQuantityInDocument);
		AuxProperties.Insert("QueryTextDetailedDataPortionsOfRows", QueryText);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeListSelections()
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
		And Not Object.RecordDeliveryParameters Then
		
		SelectionFieldFinalRecipient = "FinalRecipientIsFinalLeverage";
		
	Else
		
		SelectionFieldFinalRecipient = "FinalRecipientIsTurnover";
		
	EndIf;
	
	SuitableDeliveryMethods = New ValueList; // ValueList of EnumRef.TransportMethods25
	If ValueIsFilled(Object.DeliveryMethod) Then
		
		SuitableDeliveryMethods.Add(Object.DeliveryMethod);
		
		If Not Object.DeliveryParametersCorrespondToTrip Then
			SuitableDeliveryMethods.Add(Enums.TransportMethods25.DefinedByDeliveryService);
		EndIf;
		
	EndIf;
	
	Lists = New Array; // Array of DynamicList
	Lists.Add(ListByItem);
	Lists.Add(ListByDocuments);
	
	For Each ListOfLeftovers In Lists Do
		
		CommonClientServer.SetDynamicListParameter(
			ListOfLeftovers, "Organization", Object.Organization);
		CommonClientServer.SetDynamicListParameter(
			ListOfLeftovers, "Warehouse", Object.Warehouse);
		CommonClientServer.SetDynamicListParameter(
			ListOfLeftovers, "DateOfShipmentBy", Object.DateOfShipment, ValueIsFilled(Object.DateOfShipment));
		CommonClientServer.SetDynamicListParameter(
			ListOfLeftovers, "PreviousLevelsOfOperations", PreviousLevelsOfOperations);
		
		If Object.DeliveryParametersCorrespondToTrip Then
			
			CommonClientServer.SetDynamicListParameter(
				ListOfLeftovers, "DateOfShipmentFrom", Object.DateOfShipment, ValueIsFilled(Object.DateOfShipment));
			
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			ListOfLeftovers, "Carrier", Object.Carrier,,, ValueIsFilled(Object.Carrier));
		CommonClientServer.SetDynamicListFilterItem(
			ListOfLeftovers, SelectionFieldFinalRecipient, Object.Recipient,,, ValueIsFilled(Object.Recipient));
		CommonClientServer.SetDynamicListFilterItem(
			ListOfLeftovers, "DeliveryType", Object.DeliveryType,,, ValueIsFilled(Object.DeliveryType));
		
		CommonClientServer.SetDynamicListFilterItem(
			ListOfLeftovers,
			"DeliveryMethod",
			SuitableDeliveryMethods,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(Object.DeliveryMethod));
		
	EndDo;
	
	SettingUpListsByDeliveryZone();
	
EndProcedure

&AtServer
Procedure SettingUpListsByDeliveryZone()
	
	ThereIsSelectionByArea = ValueIsFilled(Object.DeliveryZone);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByItem, "Recipient_Area", Object.DeliveryZone,,, ThereIsSelectionByArea);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByDocuments, "Recipient_Area", Object.DeliveryZone,,, ThereIsSelectionByArea);
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add("ListByDocumentsRecipient_Area");
	FieldsNames.Add("ListByItemRecipient_Area");
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, FieldsNames, "Visible", Not ThereIsSelectionByArea);
	
EndProcedure

// Returns:
//  Array of String - Names of selection fields that cannot be edited
//
&AtServer
Function NamesOfFixedSelectionFields()
	
	Return Parameters.FixedSelectionFields.UnloadValues();
	
EndFunction

&AtClient
Procedure ListDeliverSelection(Item, RowSelected, Field, StandardProcessing)
	
	ThisIsListByGoods = (Item = Items.ListByItem);
	RowData = Item.RowData(RowSelected); // See DeliverListLineData
	
	If ThisIsListByGoods
	   And (RowData.Balance - RowData.Selected) <= 0 Then
		Return;
	EndIf;
	
	If RowData.ThereAreDifferences_InDeliveryParameters
	   And Not Object.RecordDeliveryParameters Then
		
		FormParameters = ParametersOfDeliveryParameterSelectionForm(Item.Name, RowSelected, RowData);
		Notification = New CallbackDescription("ListDeliverSelectionCompletion", ThisObject, Item.Name);
		
		OpenForm("DataProcessor.PickGoodsToDeliveryDocument.Form.ParameterChoiceForm",
			FormParameters,
			ThisObject,
			UUID,
			,
			,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		SelectedOptions = New Structure;
		
		OutputFinalRecipient = TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
			And Object.DocumentDeliveryMethod = PredefinedValue("Enum.TransportMethods25.ByCarrier");
		
		DataOfFinalRecipientIsFilledIn = OutputFinalRecipient
			And ValueIsFilled(RowData.FinalRecipient)
			And ValueIsFilled(RowData.FinalRecipientPoint)
			And ValueIsFilled(RowData.AreaOfFinalRecipient);
		
		If Not Object.RecordDeliveryParameters
		   And OutputFinalRecipient
		   And DataOfFinalRecipientIsFilledIn Then
			
			SelectedOptions.Insert("Recipient", RowData.FinalRecipient);
			SelectedOptions.Insert("RecipientPoint", RowData.FinalRecipientPoint);
			SelectedOptions.Insert("Recipient_Area", RowData.AreaOfFinalRecipient);
			
		Else
			
			SelectedOptions.Insert("Recipient", RowData.Recipient);
			SelectedOptions.Insert("RecipientPoint", RowData.RecipientPoint);
			SelectedOptions.Insert("Recipient_Area", RowData.Recipient_Area);
			
		EndIf;
		
		AddLinesToMatchedServer(RowData, SelectedOptions);
		Items.ListByItem.Refresh();
		Items.ListByDocuments.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityAvailabilityOfFields()
	
	DeliveryDocumentType = TypeOf(Object.DocumentDeliveries);
	
	FieldNamesAreViewOnly = New Array; // Array of String
	NamesOfInvisibleFields = New Array; // Array of String
	
	FixedSelectionFields = NamesOfFixedSelectionFields();
	CommonClientServer.SupplementArray(FieldNamesAreViewOnly, FixedSelectionFields);
	
	If Object.RecordDeliveryParameters Then
		
		FieldNamesAreViewOnly.Add(Items.SelectedDeliveryPoint.Name);
		FieldNamesAreViewOnly.Add(Items.SelectedDeliveryZone.Name);
		
	EndIf;
		
	If Not Object.RecordDeliveryParameters Then
		
		NamesOfInvisibleFields.Add(Items.DeliveryPointIsFixedAccordingToDocuments.Name);
		NamesOfInvisibleFields.Add(Items.DeliveryPointIsFixedForItems.Name);
		NamesOfInvisibleFields.Add(Items.DeliveryZoneIsFixedAccordingToDocuments.Name);
		NamesOfInvisibleFields.Add(Items.DeliveryZoneIsFixedForItems.Name);
		
	EndIf;
	
	If DeliveryDocumentType = Type("DocumentRef.DeliveryOrder") Then
		
		NamesOfInvisibleFields.Add(Items.PageOnDocuments.Name);
		NamesOfInvisibleFields.Add(Items.SelectedPlanningDocument.Name);
		NamesOfInvisibleFields.Add(Items.DeliveryZone.Name);
		NamesOfInvisibleFields.Add(Items.Recipient.Name);
		NamesOfInvisibleFields.Add(Items.Carrier.Name);
		NamesOfInvisibleFields.Add(Items.DeliveryParametersCorrespondToTrip.Name);
		NamesOfInvisibleFields.Add(Items.DeliveryMethod.Name);
		
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		
	Else
		
		NamesOfInvisibleFields.Add(Items.ListByItemCarrier.Name);
		
	EndIf;
	
	If Not (DeliveryDocumentType = Type("DocumentRef.Trip")
				And Object.DocumentDeliveryMethod = Enums.TransportMethods25.ByCarrier) Then
		
		NamesOfInvisibleFields.Add(Items.ListByDocumentsFinalRecipient.Name);
		NamesOfInvisibleFields.Add(Items.ListByDocumentsFinalRecipientPoint.Name);
		NamesOfInvisibleFields.Add(Items.ListByDocumentsAreaOfFinalRecipient.Name);
		NamesOfInvisibleFields.Add(Items.ListByItemFinalRecipient.Name);
		NamesOfInvisibleFields.Add(Items.ListByItemFinalRecipientPoint.Name);
		NamesOfInvisibleFields.Add(Items.ListByItemAreaOfFinalRecipient.Name);
		
		ListByDocuments.SetRequiredUse("FinalRecipient", False);
		ListByDocuments.SetRequiredUse("FinalRecipientPoint", False);
		ListByDocuments.SetRequiredUse("AreaOfFinalRecipient", False);
		
		ListByItem.SetRequiredUse("FinalRecipient", False);
		ListByItem.SetRequiredUse("FinalRecipientPoint", False);
		ListByItem.SetRequiredUse("AreaOfFinalRecipient", False);
		
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, NamesOfInvisibleFields, "Visible", False);
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, FieldNamesAreViewOnly, "ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetFieldHeaders()
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		
		FixedPointHeader = NStr("ru = 'Точка доставки';
								|vi = 'Delivery point';
								|en = 'Delivery point'; fa = 'نقطه تحویل';
								|it = 'Delivery point';
								|pl = 'Delivery point';
								|tr = 'Teslimat noktası'");
		FixedAreaHeader = NStr("ru = 'Зона доставки';
								|vi = 'Delivery zone';
								|en = 'Delivery zone'; fa = 'منطقه تحویل';
								|it = 'Area di consegna';
								|pl = 'Strefa dostawy';
								|tr = 'Teslimat bölgesi'");
		
	Else
		
		FixedPointHeader = NStr("ru = 'Точка доставки пункта';
								|vi = 'Point delivery point';
								|en = 'Point delivery point'; fa = 'نقطه تحویل نقطه';
								|it = 'Point delivery point';
								|pl = 'Point delivery point';
								|tr = 'Teslimat noktası'");
		FixedAreaHeader = NStr("ru = 'Зона доставки пункта';
								|vi = 'Point delivery zone';
								|en = 'Point delivery zone'; fa = 'منطقه تحویل نقطه';
								|it = 'Point delivery zone';
								|pl = 'Point delivery zone';
								|tr = 'Noktanın teslimat bölgesi'");
		
	EndIf;
	
	If Object.DeliveryParametersCorrespondToTrip Then
		
		ShipmentDateHeader = NStr("ru = 'Дата отгрузки';
									|vi = 'Shipment date';
									|en = 'Shipment date'; fa = 'تاریخ ارسال';
									|it = 'Data di spedizione';
									|pl = 'Data wysyłki';
									|tr = 'Sevkiyat tarihi'");
		
	Else
		
		ShipmentDateHeader = NStr("ru = 'Дата отгрузки по';
									|vi = 'Shipment date to';
									|en = 'Shipment date to'; fa = 'تاریخ ارسال تا';
									|it = 'Shipment date to';
									|pl = 'Shipment date to';
									|tr = 'Sevkiyat tarihine göre'");
		
	EndIf;
	
	Items.DeliveryPointIsFixedForItems.Title = FixedPointHeader;
	Items.DeliveryPointIsFixedAccordingToDocuments.Title = FixedPointHeader;
	
	Items.DeliveryZoneIsFixedForItems.Title = FixedAreaHeader;
	Items.DeliveryZoneIsFixedAccordingToDocuments.Title = FixedAreaHeader;
	
	Items.DateOfShipment.Title = ShipmentDateHeader;
	
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfSelectionFields()
	
	Items.DeliveryMethod.ReadOnly = (Object.DeliveryParametersCorrespondToTrip And ValueIsFilled(Object.DocumentDeliveryMethod));
	Items.DateOfShipment.ReadOnly = (Object.DeliveryParametersCorrespondToTrip And ValueIsFilled(Object.DocumentShipmentDate));
	Items.Carrier.ReadOnly = (Object.DeliveryParametersCorrespondToTrip And ValueIsFilled(Object.DocumentCarrier));
	
EndProcedure

&AtServer
Procedure DeliveryParametersCorrespondToFlightOnChangeATServer()
	
	If Object.DeliveryParametersCorrespondToTrip Then
		
		If ValueIsFilled(Object.DocumentDeliveryMethod) Then
			Object.DeliveryMethod = Object.DocumentDeliveryMethod;
		EndIf;
		
		If ValueIsFilled(Object.DocumentShipmentDate) Then
			Object.DateOfShipment = Object.DocumentShipmentDate;
		EndIf;
		
		If ValueIsFilled(Object.DocumentCarrier) Then
			Object.Carrier = Object.DocumentCarrier;
		EndIf;
		
	EndIf;
	
	SuitableDeliveryMethods = New ValueList; // ValueList of EnumRef.TransportMethods25
	If ValueIsFilled(Object.DeliveryMethod) Then
		
		SuitableDeliveryMethods.Add(Object.DeliveryMethod);
		
		If Not Object.DeliveryParametersCorrespondToTrip Then
			SuitableDeliveryMethods.Add(Enums.TransportMethods25.DefinedByDeliveryService);
		EndIf;
		
	EndIf;
	
	UseSelectionByShipmentDateFrom = (Object.DeliveryParametersCorrespondToTrip And ValueIsFilled(Object.DateOfShipment));
	
	Lists = New Array; // Array of DynamicList
	Lists.Add(ListByItem);
	Lists.Add(ListByDocuments);
	
	For Each List In Lists Do
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"DeliveryMethod",
			SuitableDeliveryMethods,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(Object.DeliveryMethod));
		
		CommonClientServer.SetDynamicListFilterItem(
			List, "Carrier", Object.Carrier,,, ValueIsFilled(Object.Carrier));
		
		CommonClientServer.SetDynamicListParameter(
			List, "DateOfShipmentFrom", Object.DateOfShipment, UseSelectionByShipmentDateFrom);
		
	EndDo;
	
	ConfigureAvailabilityOfSelectionFields();
	SetFieldHeaders();
	
EndProcedure

&AtClient
Procedure WhenChangingCarrier()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByItem, "Carrier", Object.Carrier,,, ValueIsFilled(Object.Carrier));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListByDocuments, "Carrier", Object.Carrier,,, ValueIsFilled(Object.Carrier));
	
EndProcedure

&AtClient
Procedure ListOfDocumentsUpdateAdditionalParameters()
	
	If Items.ListByDocuments.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	RowData = Items.ListByDocuments.CurrentData; // See DeliverListLineData
	UpdateAdditionalParametersATServer(Items.ListByDocuments.Name, RowData);
	
EndProcedure

&AtClient
Procedure GoodsListUpdateAdditionalParameters()
	
	If Items.ListByItem.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	RowData = Items.ListByItem.CurrentData; // See DeliverListLineData
	UpdateAdditionalParametersATServer(Items.ListByItem.Name, RowData);
	
EndProcedure

// Parameters:
//  TagName - String - 
//  RowData - See DeliverListLineData
//
&AtServer
Procedure UpdateAdditionalParametersATServer(Val TagName, Val RowData)
	
	If TagName = Items.ListByDocuments.Name Then
		
		ThisIsListByGoods = False;
		FieldsPrefix = "InformationOnDocuments";
		
	Else
		
		ThisIsListByGoods = True;
		FieldsPrefix = "InformationByGoods";
		
	EndIf;
	
	OutputFinalRecipient = (TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.Trip")
		And Object.DocumentDeliveryMethod = Enums.TransportMethods25.ByCarrier);
	FilterParameters = SelectionOfDetailedBalances(ThisIsListByGoods, OutputFinalRecipient);
	FillPropertyValues(FilterParameters, RowData);
	
	If TypeOf(Object.DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		
		ReferenceOrder = RowData.ReferenceOrder;
		
		If TypeOf(ReferenceOrder) = Type("DocumentRef.SalesOrder") Then
			
			DeliverySpecificationMethod = Common.ObjectAttributeValue(ReferenceOrder, "DeliverySpecificationMethod");
			If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
				
				AddlParameters = GoodsDelivery.AdditionalParametersFromDocumentHeader(ReferenceOrder);
				
			Else
				
				DeliveryDocuments = CommonClientServer.ValueInArray(ReferenceOrder);
				AddlParameters = GoodsDelivery.MatchingAdditionalParametersFromDocumentStrings(
					DeliveryDocuments, FilterParameters, ThisIsListByGoods);
				
			EndIf;
			
		Else
			
			AddlParameters = GoodsDelivery.AdditionalParametersFromDocumentHeader(ReferenceOrder);
			
		EndIf;
		
	Else // Selection for the flight
		
		DetailsOfLine = RowData.Detailing.Get();
		DeliveryDocuments = TMCommonUse.UniqueValuesFromTableColumn(DetailsOfLine, "PlanningDocument");
		
		If DeliveryDocuments.Count() = 1
		   And TypeOf(DeliveryDocuments[0]) = Type("DocumentRef.SalesOrder") Then
			
			DocumentDeliveries = DeliveryDocuments[0]; // DocumentRef.SalesOrder
			DeliverySpecificationMethod = Common.ObjectAttributeValue(DocumentDeliveries, "DeliverySpecificationMethod");
			If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
				
				AddlParameters = GoodsDelivery.AdditionalParametersFromDocumentHeader(DocumentDeliveries);
				
			Else
				
				AddlParameters = GoodsDelivery.MatchingAdditionalParametersFromDocumentStrings(
					DeliveryDocuments, FilterParameters, ThisIsListByGoods);
				
			EndIf;
			
		ElsIf DeliveryDocuments.Count() = 1 Then
			
			AddlParameters = GoodsDelivery.AdditionalParametersFromDocumentHeader(DeliveryDocuments[0]);
			
		Else
			
			AddlParameters = GoodsDelivery.MatchingAdditionalParametersFromDocumentStrings(
				DeliveryDocuments, FilterParameters, ThisIsListByGoods);
			
		EndIf;
		
	EndIf;
	
	For Each ElementOfAdditionalParameters In AddlParameters Do
		
		If ElementOfAdditionalParameters.Key = "Match" Then
			Continue;
		EndIf;
		FieldName = FieldsPrefix + ElementOfAdditionalParameters.Key;
		CommonClientServer.SetFormAttributeByPath(ThisObject, FieldName, ElementOfAdditionalParameters.Value);
		
	EndDo;
	
	ElementsOfAdditionalParameters = New Array; // Array of String
	
	If ThisIsListByGoods Then
		
		InscriptionIsDifferentInformation = Items.InscriptionContainsInformationOnItems;
		
		ElementsOfAdditionalParameters.Add(Items.ItemInformationDeliveryTimeFrom.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnItemsDeliveryTimeBy.Name);
		ElementsOfAdditionalParameters.Add(Items.ItemInformationAdditionalDeliveryInformation.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnItemsSpecialConditionsOfCarriage.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnItemsSpecialConditionsOfCarriageDescription.Name);
		
	Else
		
		InscriptionIsDifferentInformation = Items.InscriptionDiffersInformationOnDocuments;
		
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsDeliveryTimeFrom.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsDeliveryTimeBy.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsAdditionalInformationOnDelivery.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsSpecialConditionsOfTransportation.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsSpecialConditionsOfCarriageDescription.Name);
		
	EndIf;
	
	If AddlParameters.Match Then
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ElementsOfAdditionalParameters, "Visible", True);
		InscriptionIsDifferentInformation.Visible = False;
		
	Else
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ElementsOfAdditionalParameters, "Visible", False);
		InscriptionIsDifferentInformation.Visible = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
