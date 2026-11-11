// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DeliverySettings = GoodsDeliveryClientServer.NewDeliverySettings();
	
	If Not Parameters.Property("DeliverySettings", DeliverySettings) Then
		
		ExceptionText = NStr("ru = 'В форму настроек доставки не передан обязательный параметр ""Настройки доставки"".
							   |Обратитесь к администратору.';
							   |vi = 'The required ""Delivery settings"" parameter is not passed to the delivery settings form.
							   |Contact the administrator.';
							   |en = 'The required ""Delivery settings"" parameter is not passed to the delivery settings form.
							   |Contact the administrator.'; fa = 'The required ""Delivery settings"" parameter is not passed to the delivery settings form.
							   |Contact the administrator.';
							   |it = 'The required ""Delivery settings"" parameter is not passed to the delivery settings form.
							   |Contact the administrator.';
							   |pl = 'The required ""Delivery settings"" parameter is not passed to the delivery settings form.
							   |Contact the administrator.';
							   |tr = 'Teslimat ayarları formuna zorunlu ""Teslimat ayarları"" parametresi iletilmedi.
							   | Yöneticiye başvurun.'");
		Raise ExceptionText;
		
	EndIf;
	
	Object.Partner = DeliverySettings.Partner;
	
	Object.DeliveryPlanning = DeliverySettings.DeliveryPlanning;
	Object.DeliverySpecificationMethod = DeliverySettings.DeliverySpecificationMethod;
	Object.DeliveryMethod = DeliverySettings.DeliveryMethod;
	Object.Courier = DeliverySettings.Courier;
	Object.DeliveryToCarrier = DeliverySettings.DeliveryToCarrier;
	Object.Carrier = DeliverySettings.Carrier;
	Object.CarrierDeliveryPoint = DeliverySettings.CarrierDeliveryPoint;
	Object.CarrierSDeliveryArea = DeliverySettings.CarrierSDeliveryArea;
	Object.DeliveryPoint = DeliverySettings.DeliveryPoint;
	Object.DeliveryZone = DeliverySettings.DeliveryZone;
	CheckFillInDeliveryDetailsForEntireDocument();
	
	Object.DeliveryTimeFrom = DeliverySettings.DeliveryTimeFrom;
	Object.DeliveryTimeTo = DeliverySettings.DeliveryTimeTo;
	
	Object.AdditionalDeliveryInformation = DeliverySettings.AdditionalDeliveryInformation;
	Object.SpecialTransportationConditions = DeliverySettings.SpecialTransportationConditions;
	If Object.SpecialTransportationConditions Then
		Object.SpecialTransportationConditionsDescription = DeliverySettings.SpecialTransportationConditionsDescription;
	EndIf;
	
	VerificationOfDeliveryTransferMethods(DeliverySettings);
	SetUpDeliveryMethodRestrictions(DeliverySettings);
	
	For Each RowOfGoods In DeliverySettings.Goods Do
		
		NewRow = Object.GoodsToDeliver.Add();
		FillPropertyValues(NewRow, RowOfGoods);
		NewRow.ItemsType = Enums.ItemsTypes.OwnGoods;
		
	EndDo;
	Object.GoodsToDeliver.Sort("DocumentRowNumber");
	CheckFillInDeliveryDetailsLineByLine();
	
	For Each RowOfWarehouses In DeliverySettings.Warehouses Do
		
		NewRow = Object.Warehouses.Add();
		FillPropertyValues(NewRow, RowOfWarehouses);
		
	EndDo;
	Object.Warehouses.Sort("Warehouse");
	
	SetFixedVisibilityAccessibilityOfItems(DeliverySettings);
	SetVisibilityAccessibilityOfElements();
	
	Items.GoodsToDeliverDateOfShipment.Visible = Not DeliverySettings.SingleShipmentDateIsUsed;
	
	TimeFillingItems = New Array; // Array of FormField
	TimeFillingItems.Add(Items.DeliveryTimeFrom);
	TimeFillingItems.Add(Items.DeliveryTimeTo);
	TimeFillingItems.Add(Items.ItemsForDeliveryDeliveryTimeWith);
	TimeFillingItems.Add(Items.ItemsForDeliveryDeliveryTimeBy);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(TimeFillingItems);
	
	SetConditionalAppearance();
	
	If ReadOnly Then
		
		ItemsNames = New Array; // Array of String
		ItemsNames.Add("DeliverySpecificationMethod");
		ItemsNames.Add("DeliveryPlanning");
		
		// For The Entire Document
		ItemsNames.Add("DeliveryMethod");
		ItemsNames.Add("Courier");
		ItemsNames.Add("DeliveryPoint");
		ItemsNames.Add("DeliveryZone");
		ItemsNames.Add("DeliveryTimeFrom");
		ItemsNames.Add("DeliveryTimeTo");
		ItemsNames.Add("DeliveryToCarrier");
		ItemsNames.Add("Carrier");
		ItemsNames.Add("CarrierDeliveryPoint");
		ItemsNames.Add("CarrierSDeliveryArea");
		ItemsNames.Add("AdditionalDeliveryInformation");
		ItemsNames.Add("SpecialTransportationConditions");
		ItemsNames.Add("SpecialTransportationConditionsDescription");
		
		// LineByLine
		ItemsNames.Add("GoodsToDeliver");
		ItemsNames.Add("ItemsForDeliveryDeliveryTimeWith");
		ItemsNames.Add("ItemsForDeliveryDeliveryTimeBy");
		ItemsNames.Add("ItemsForDeliveryDeliveryToCarrier");
		ItemsNames.Add("ItemsForDeliveryByCarrier");
		ItemsNames.Add("ItemsForDeliveryCarrierSDeliveryPoint");
		ItemsNames.Add("ItemsForDeliveryCarrierSDeliveryZone");
		ItemsNames.Add("ItemsForDeliveryAdditionalInformationOnDelivery");
		ItemsNames.Add("ItemsForDeliverySpecialConditionsOfCarriage");
		ItemsNames.Add("ItemsForDeliverySpecialConditionsOfCarriageDescription");
		
		// Warehouses
		ItemsNames.Add("Warehouses");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"ReadOnly",
			True,
			True);
		
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeliverySpecificationMethodOnChange(Item)
	
	DeliverySpecificationMethodOnChangeServer();
	
EndProcedure

&AtClient
Procedure DeliveryPlanningOnChange(Item)
	
	DeliveryPlanningOnChangeServer();
	
EndProcedure

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	DeliveryMethodOnChangeServer();
	
EndProcedure

&AtClient
Procedure DeliveryMethodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DeliveryPointOnChange(Item)
	
	If Object.DeliveryPoint.IsEmpty() Then
		
		Object.DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		Object.DeliveryZone = DeliveryPointArea(Object.DeliveryPoint);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryToCarrierOnChange(Item)
	
	If Not Object.DeliveryToCarrier Then
		
		Object.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		Object.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		Object.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	EndIf;
	
	SetVisibilityAccessibilityOfElements();
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	Items.SpecialTransportationConditionsDescription.ReadOnly = Not Object.SpecialTransportationConditions;
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	CarrierData = DeliveryPointInformationByOwner(Object.Carrier);
	Object.CarrierDeliveryPoint = CarrierData.DeliveryPoint;
	Object.CarrierSDeliveryArea = CarrierData.DeliveryZone;
	
EndProcedure

&AtClient
Procedure CarrierDeliveryPointOnChange(Item)
	
	If Object.CarrierDeliveryPoint.IsEmpty() Then
		
		Object.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		Object.CarrierSDeliveryArea = DeliveryPointArea(Object.CarrierDeliveryPoint);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ItemsForDeliveryDeliveryToCarrierOnChange(Item)
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	
	If Not Object.DeliveryToCarrier Then
		
		CurrentData.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		CurrentData.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		CurrentData.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	EndIf;
	
	DeliveryLine = GoodsDeliveryClientServer.NewDeliveryLineData();
	FillPropertyValues(DeliveryLine, CurrentData);
	SetVisibilityAvailabilityOfDeliveryLineDetailsItems(DeliveryLine);
	
EndProcedure

&AtClient
Procedure ItemsForDeliveryByCarrierOnChange(Item)
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	
	CarrierData = DeliveryPointInformationByOwner(CurrentData.Carrier);
	CurrentData.CarrierDeliveryPoint = CarrierData.DeliveryPoint;
	CurrentData.CarrierSDeliveryArea = CarrierData.DeliveryZone;
	
EndProcedure

&AtClient
Procedure ItemsForDeliveryCarrierSDeliveryPointOnChange(Item)
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	
	If CurrentData.CarrierDeliveryPoint.IsEmpty() Then
		
		CurrentData.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		CurrentData.CarrierSDeliveryArea = DeliveryPointArea(CurrentData.CarrierDeliveryPoint);
		
	EndIf;

EndProcedure

&AtClient
Procedure ItemsForDeliverySpecialConditionsOfCarriageOnChange(Item)
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	
	Items.ItemsForDeliverySpecialConditionsOfCarriageDescription.ReadOnly = Not CurrentData.SpecialTransportationConditions;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsToDeliver

&AtClient
Procedure GoodsToDeliverOnActivateRow(Item)
	
	AttachIdleHandler("GoodsForDeliveryWhenWaitingHandlerLineIsActivated", 0.1, True);
	
EndProcedure

&AtClient
Procedure GoodsToDeliverDeliveryMethodOnChange(Item)
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	
	If CurrentData.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OwnDelivery") Then
		
		If Not CurrentData.DeliveryToCarrier Then
			
			CurrentData.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
			CurrentData.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
			CurrentData.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			
		EndIf;
		
	ElsIf CurrentData.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.ByCarrier") Then
		
		CurrentData.DeliveryToCarrier = False;
		CurrentData.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		CurrentData.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	ElsIf CurrentData.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.DefinedByDeliveryService") Then
		
		CurrentData.DeliveryToCarrier = False;
		CurrentData.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		CurrentData.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		CurrentData.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else // Self-pickup or empty
		
		CurrentData.DeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		CurrentData.DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		CurrentData.DeliveryToCarrier = False;
		CurrentData.DeliveryTimeFrom = Date(1, 1, 1);
		CurrentData.DeliveryTimeTo = Date(1, 1, 1);
		CurrentData.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		CurrentData.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		CurrentData.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		CurrentData.AdditionalDeliveryInformation = "";
		CurrentData.SpecialTransportationConditions = False;
		CurrentData.SpecialTransportationConditionsDescription = "";
		
	EndIf;
	
	DeliveryLine = GoodsDeliveryClientServer.NewDeliveryLineData();
	FillPropertyValues(DeliveryLine, CurrentData);
	SetVisibilityAvailabilityOfDeliveryLineDetailsItems(DeliveryLine);
	
	If CurrentData.DeliveryMethod <> PredefinedValue("Enum.TransportMethods25.SelfPickup")
		And Not CurrentData.DeliveryMethod.IsEmpty() Then
		
		If CurrentData.DeliveryZone.IsEmpty()
			And CurrentData.DeliveryPoint.IsEmpty() Then
			
			PartnerData = DeliveryPointInformationByOwner(Object.Partner);
			CurrentData.DeliveryPoint = PartnerData.DeliveryPoint;
			CurrentData.DeliveryZone = PartnerData.DeliveryZone;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsToDeliverDeliveryMethodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsToDeliverDeliveryPointOnChange(Item)
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	If CurrentData.DeliveryPoint.IsEmpty() Then
		
		CurrentData.DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		CurrentData.DeliveryZone = DeliveryPointArea(CurrentData.DeliveryPoint);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWarehouses

&AtClient
Procedure WarehousesWarehousePointOnChange(Item)
	
	CurrentData = Items.Warehouses.CurrentData;
	If CurrentData.WarehousePoint.IsEmpty() Then
		
		CurrentData.AreaOfWarehouse = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		CurrentData.AreaOfWarehouse = DeliveryPointArea(CurrentData.WarehousePoint);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	Result = GoodsDeliveryClientServer.NewDeliverySettings();
	
	Result.DeliverySpecificationMethod = Object.DeliverySpecificationMethod;
	Result.DeliveryPlanning = Object.DeliveryPlanning;
	
	If Object.DeliverySpecificationMethod = PredefinedValue("Enum.DeliverySpecificationMethods.ForWholeDocument") Then
		
		Result.DeliveryMethod = Object.DeliveryMethod;
		Result.DeliveryPoint = Object.DeliveryPoint;
		Result.DeliveryZone = Object.DeliveryZone;
		Result.DeliveryTimeFrom = Object.DeliveryTimeFrom;
		Result.DeliveryTimeTo = Object.DeliveryTimeTo;
		
		Result.SpecialTransportationConditions = Object.SpecialTransportationConditions;
		If Object.SpecialTransportationConditions Then
			Result.SpecialTransportationConditionsDescription = Object.SpecialTransportationConditionsDescription;
		Else
			Result.SpecialTransportationConditionsDescription = "";
		EndIf;
		Result.AdditionalDeliveryInformation = Object.AdditionalDeliveryInformation;
		
		Result.DeliveryToCarrier = Object.DeliveryToCarrier;
		Result.Carrier = Object.Carrier;
		Result.CarrierDeliveryPoint = Object.CarrierDeliveryPoint;
		Result.CarrierSDeliveryArea = Object.CarrierSDeliveryArea;
		
		If Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OwnDelivery") Then
			
			Result.Courier = PredefinedValue("Catalog.Persons.EmptyRef");
			
			If Not Object.DeliveryToCarrier Then
				
				Result.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
				Result.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
				Result.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
				
			EndIf;
			
		ElsIf Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.ByCarrier") Then
			
			Result.Courier = PredefinedValue("Catalog.Persons.EmptyRef");
			Result.DeliveryToCarrier = False;
			Result.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
			Result.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			
		ElsIf Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.DefinedByDeliveryService") Then
			
			Result.Courier = PredefinedValue("Catalog.Persons.EmptyRef");
			Result.DeliveryToCarrier = False;
			Result.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
			Result.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
			Result.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			
		ElsIf Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OurCourier") Then
			
			Result.Courier = Object.Courier;
			
			Result.DeliveryToCarrier = False;
			Result.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
			Result.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
			Result.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			
			Result.SpecialTransportationConditions = False;
			Result.SpecialTransportationConditionsDescription = "";
			
		Else // Self-pickup or empty
			
			Result.Courier = PredefinedValue("Catalog.Persons.EmptyRef");
			Result.DeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
			Result.DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			Result.DeliveryToCarrier = False;
			Result.DeliveryTimeFrom = Date(1, 1, 1);
			Result.DeliveryTimeTo = Date(1, 1, 1);
			Result.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
			Result.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
			Result.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			Result.AdditionalDeliveryInformation = "";
			Result.SpecialTransportationConditions = False;
			Result.SpecialTransportationConditionsDescription = "";
			
		EndIf;
		
	Else
		
		Result.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.EmptyRef");
		Result.DeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		Result.DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		Result.DeliveryTimeFrom = Date(1, 1, 1);
		Result.DeliveryTimeTo = Date(1, 1, 1);
		
		Result.SpecialTransportationConditions = False;
		Result.SpecialTransportationConditionsDescription = "";
		
		Result.DeliveryToCarrier = False;
		Result.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		Result.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		Result.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		Result.AdditionalDeliveryInformation = "";
		
		For Each RowOfGoods In Object.GoodsToDeliver Do
			
			NewRow = GoodsDeliveryClientServer.NewDeliveryLineData();
			FillPropertyValues(NewRow, RowOfGoods);
			If Not NewRow.SpecialTransportationConditions Then
				NewRow.SpecialTransportationConditionsDescription = "";
			EndIf;
			
			Result.Goods.Add(NewRow);
			
		EndDo;
		
	EndIf;
	
	If Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OurCourier") Then
		Result.Courier = Object.Courier;
	Else
		Result.Courier = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
	For Each RowOfWarehouses In Object.Warehouses Do
		
		NewRow = GoodsDeliveryClientServer.NewDeliveryWarehouseRowData();
		FillPropertyValues(NewRow, RowOfWarehouses);
		Result.Warehouses.Add(NewRow);
		
	EndDo;
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure VerificationOfDeliveryTransferMethods(Val DeliverySettings)
	
	NumberOfDeliveryMethodsUsed = DeliverySettings.ShippingMethodsUsed.Count();
	NumberOfExcludedDeliveryMethods = DeliverySettings.ExcludedDeliveryMethods.Count();
	
	BothDeliveryOptionsAreSet =
		(NumberOfDeliveryMethodsUsed > 0
		 And NumberOfExcludedDeliveryMethods > 0);
	OptionsForDeliveryMethodsAreNotSet =
		(NumberOfDeliveryMethodsUsed = 0
		 And NumberOfExcludedDeliveryMethods = 0);
	
	//@skip-check module-nstr-camelcase
	MessageTextNotSpecified = NStr("ru = 'Одновременно не заданы ИспользуемыеСпособыДоставки и ИсключаемыеСпособыДоставки';
									|vi = 'Used delivery methods and Excluded delivery methods are not specified simultaneously';
									|en = 'Used delivery methods and Excluded delivery methods are not specified simultaneously'; fa = 'Used delivery methods and Excluded delivery methods are not specified simultaneously';
									|it = 'Used delivery methods and Excluded delivery methods are not specified simultaneously';
									|pl = 'Used delivery methods and Excluded delivery methods are not specified simultaneously';
									|tr = 'KullanılanTeslimatYöntemleri ve HariçTutulanTeslimatYöntemleri aynı anda belirtilmemiş'");
	//@skip-check module-nstr-camelcase
	MessageTextIsSet = NStr("ru = 'Одновременно заданы ИспользуемыеСпособыДоставки и ИсключаемыеСпособыДоставки';
							|vi = 'Used delivery methods and Excluded delivery methods are specified simultaneously';
							|en = 'Used delivery methods and Excluded delivery methods are specified simultaneously'; fa = 'Used delivery methods and Excluded delivery methods are specified simultaneously';
							|it = 'Used delivery methods and Excluded delivery methods are specified simultaneously';
							|pl = 'Used delivery methods and Excluded delivery methods are specified simultaneously';
							|tr = 'KullanılanTeslimatYöntemleri ve HariçTutulanTeslimatYöntemleri aynı anda belirtilmiş'");
	//@skip-check module-nstr-camelcase
	MessageContext = NStr("ru = 'РедактированиеПараметровДоставки.ПараметрыДоставки.ПриСозданииНаСервере';
							|vi = 'Edit delivery parameters. Delivery parameters. On create at server';
							|en = 'Edit delivery parameters. Delivery parameters. On create at server'; fa = 'Edit delivery parameters. Delivery parameters. On create at server';
							|it = 'Edit delivery parameters. Delivery parameters. On create at server';
							|pl = 'Edit delivery parameters. Delivery parameters. On create at server';
							|tr = 'TeslimatParametreleriniDüzenleme.TeslimatParametreleri.SunucudaOluşturulduğunda'");
	
	CommonClientServer.Validate(
		BothDeliveryOptionsAreSet = False,
		MessageTextNotSpecified,
		MessageContext);
	
	CommonClientServer.Validate(
		OptionsForDeliveryMethodsAreNotSet = False,
		MessageTextIsSet,
		MessageContext);
	
EndProcedure

&AtServer
Procedure CheckFillInDeliveryDetailsForEntireDocument()
	
	If Object.DeliverySpecificationMethod <> Enums.DeliverySpecificationMethods.ForWholeDocument Then
		Return;
	EndIf;
	
	If Not Object.DeliveryPoint.IsEmpty() Then
		
		DeliveryPointOwner = Common.ObjectAttributeValue(Object.DeliveryPoint, "Owner");
		If DeliveryPointOwner <> Object.Partner Then
			
			Object.DeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
			Object.DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
			
		EndIf;
		
	EndIf;
	
	// If the delivery zone is not filled in (we check first) and the delivery point is not filled in,
	// then fill in the delivery point and the delivery zone data for it.
	// If the area is full, then we do not fill in the delivery point
	
	If Object.DeliveryZone.IsEmpty()
		And Object.DeliveryPoint.IsEmpty() Then
		
		DataOfDeliveryPoint = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Partner);
		Object.DeliveryPoint = DataOfDeliveryPoint.DeliveryPoint;
		Object.DeliveryZone = DataOfDeliveryPoint.DeliveryZone;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckFillInDeliveryDetailsLineByLine()
	
	If Object.DeliverySpecificationMethod <> Enums.DeliverySpecificationMethods.ByRows Then
		Return;
	EndIf;
	
	DeliveryPoints = Object.GoodsToDeliver.Unload(, "DeliveryPoint").UnloadColumn("DeliveryPoint"); // Array of CatalogRef.DeliveryPoints
	If Not Object.DeliveryPoint.IsEmpty() Then
		DeliveryPoints.Add(Object.DeliveryPoint);
	EndIf;
	OwnersOfDeliveryPoints = Common.ObjectsAttributeValue(DeliveryPoints, "Owner");
	
	DataOfDeliveryPoint = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Partner);
	
	For Each RowOfGoods In Object.GoodsToDeliver Do
		
		If RowOfGoods.DeliveryMethod = Enums.TransportMethods25.SelfPickup Then
			Continue;
		EndIf;
		
		If RowOfGoods.DeliveryMethod.IsEmpty() Then
			
			RowOfGoods.DeliveryMethod = Object.DeliveryMethod;
			RowOfGoods.DeliveryPoint = Object.DeliveryPoint;
			RowOfGoods.DeliveryZone = Object.DeliveryZone;
			RowOfGoods.DeliveryToCarrier = Object.DeliveryToCarrier;
			RowOfGoods.Carrier = Object.Carrier;
			RowOfGoods.CarrierDeliveryPoint = Object.CarrierDeliveryPoint;
			RowOfGoods.CarrierSDeliveryArea = Object.CarrierSDeliveryArea;
			
		EndIf;
		
		If Not RowOfGoods.DeliveryPoint.IsEmpty()
			And Object.Partner <> OwnersOfDeliveryPoints[RowOfGoods.DeliveryPoint] Then
			
			RowOfGoods.DeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
			RowOfGoods.DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
			
		EndIf;
		
		// If the delivery zone is not filled in (we check first) and the delivery point is not filled in,
		// then fill in the delivery point and the delivery zone data for it.
		// If the area is full, then we do not fill in the delivery point
		
		If RowOfGoods.DeliveryZone.IsEmpty()
			And RowOfGoods.DeliveryPoint.IsEmpty() Then
			
			RowOfGoods.DeliveryPoint = DataOfDeliveryPoint.DeliveryPoint;
			RowOfGoods.DeliveryZone = DataOfDeliveryPoint.DeliveryZone;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetUpDeliveryMethodRestrictions(DeliverySettings)
	
	If DeliverySettings.ShippingMethodsUsed.Count() > 0 Then
		
		// An indication of the entire document
		ShippingMethodsUsed = Common.CopyRecursive(DeliverySettings.ShippingMethodsUsed);
		DeliveryMethodsUsedWithoutCourier = Common.CopyRecursive(ShippingMethodsUsed);
		CommonClientServer.DeleteValueFromArray(
			DeliveryMethodsUsedWithoutCourier,
			Enums.TransportMethods25.OurCourier);
		CapDeliveryMethods.LoadValues(ShippingMethodsUsed);
		
		// Specifying a list, always excludes the option Our Courier
		ChoiceParameters = New Array; // Array of ChoiceParameter
		ChoiceParameter = New ChoiceParameter(
			"Filter.Ref",
			New FixedArray(DeliveryMethodsUsedWithoutCourier));
		ChoiceParameters.Add(ChoiceParameter);
		
		Items.GoodsToDeliverDeliveryMethod.ChoiceParameters = New FixedArray(ChoiceParameters);
		
	EndIf;
	
	If DeliverySettings.ExcludedDeliveryMethods.Count() > 0 Then
		
		// An indication of the entire document 
		ExcludedCapDeliveryMethods = Common.CopyRecursive(DeliverySettings.ExcludedDeliveryMethods);
		ExcludedCapDeliveryMethods.Add(Enums.TransportMethods25.SelfPickup);
		ExcludedCapDeliveryMethods = CommonClientServer.CollapseArray(ExcludedCapDeliveryMethods);
		
		MethodSelectionParameters = New Structure;
		MethodSelectionParameters.Insert("ExcludedValues", ExcludedCapDeliveryMethods);
		CapDeliveryMethods = Enums.TransportMethods25.GetChoiceData(MethodSelectionParameters);
		
		// Specifying a list, always excludes the option Our Courier
		DeliveryMethodsUsedWithoutCourier = Common.CopyRecursive(DeliverySettings.ExcludedDeliveryMethods);
		DeliveryMethodsUsedWithoutCourier.Add(Enums.TransportMethods25.OurCourier);
		
		ChoiceParameters = New Array; // Array of ChoiceParameter
		ChoiceParameter = New ChoiceParameter(
			"ExcludedValues",
			New FixedArray(DeliveryMethodsUsedWithoutCourier));
		ChoiceParameters.Add(ChoiceParameter);
		
		Items.GoodsToDeliverDeliveryMethod.ChoiceParameters = New FixedArray(ChoiceParameters);
		
	EndIf;
	
	// The Self-pickup method is always excluded for the header
	ValueListItem = CapDeliveryMethods.FindByValue(Enums.TransportMethods25.SelfPickup);
	If ValueListItem <> Undefined Then
		CapDeliveryMethods.Delete(ValueListItem);
	EndIf;
	
	// Auxiliary list of header method, but without courier
	CapDeliveryMethodsWithoutCourier = Common.CopyRecursive(CapDeliveryMethods);
	ValueListItem = CapDeliveryMethodsWithoutCourier.FindByValue(Enums.TransportMethods25.OurCourier);
	If ValueListItem <> Undefined Then
		CapDeliveryMethodsWithoutCourier.Delete(ValueListItem);
	EndIf;
	
	SetParametersForHeaderDeliveryMethod();
	
EndProcedure

&AtServer
Procedure SetFixedVisibilityAccessibilityOfItems(DeliverySettings)
	
	Items.DeliveryPlanning.ReadOnly = Not DeliverySettings.AllowChangingTypeOfDeliveryPlanning;
	Items.DeliverySpecificationMethod.ReadOnly = Not DeliverySettings.AllowChangingDeliveryIndicationMethod;
	
EndProcedure

&AtServer
Procedure SetVisibilityAccessibilityOfElements()
	
	VisibleElementsNames = New Array; // Array of String
	NamesOfAllElements = New Array; // Array of String
	NamesOfPossibleMandatoryElements = New Array; // Array of String
	NamesOfRequiredElements = New Array; // Array of String
	
	NamesOfAllElements.Add(Items.PageForEntireDocument.Name);
	NamesOfAllElements.Add(Items.PageByLine.Name);
	NamesOfAllElements.Add(Items.DeliveryMethod.Name);
	NamesOfAllElements.Add(Items.Courier.Name);
	NamesOfAllElements.Add(Items.DeliveryToCarrier.Name);
	NamesOfAllElements.Add(Items.Carrier.Name);
	NamesOfAllElements.Add(Items.CarrierDeliveryPoint.Name);
	NamesOfAllElements.Add(Items.CarrierSDeliveryArea.Name);
	NamesOfAllElements.Add(Items.DeliveryTimeFrom.Name);
	NamesOfAllElements.Add(Items.DeliveryTimeTo.Name);
	NamesOfAllElements.Add(Items.AdditionalDeliveryInformation.Name);
	NamesOfAllElements.Add(Items.SpecialTransportationConditions.Name);
	NamesOfAllElements.Add(Items.SpecialTransportationConditionsDescription.Name);
	
	NamesOfPossibleMandatoryElements.Add(Items.Carrier.Name);
	NamesOfPossibleMandatoryElements.Add(Items.CarrierDeliveryPoint.Name);
	NamesOfPossibleMandatoryElements.Add(Items.CarrierSDeliveryArea.Name);
	
	If Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
		
		VisibleElementsNames.Add(Items.PageForEntireDocument.Name);
		VisibleElementsNames.Add(Items.DeliveryMethod.Name);
		VisibleElementsNames.Add(Items.DeliveryTimeFrom.Name);
		VisibleElementsNames.Add(Items.DeliveryTimeTo.Name);
		VisibleElementsNames.Add(Items.AdditionalDeliveryInformation.Name);
		
		If Object.DeliveryMethod = Enums.TransportMethods25.OwnDelivery Then
			
			VisibleElementsNames.Add(Items.DeliveryToCarrier.Name);
			VisibleElementsNames.Add(Items.Carrier.Name);
			VisibleElementsNames.Add(Items.CarrierDeliveryPoint.Name);
			VisibleElementsNames.Add(Items.CarrierSDeliveryArea.Name);
			
			If Object.DeliveryToCarrier
			   And Object.DeliveryPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument Then
				
				NamesOfRequiredElements.Add(Items.Carrier.Name);
				NamesOfRequiredElements.Add(Items.CarrierDeliveryPoint.Name);
				NamesOfRequiredElements.Add(Items.CarrierSDeliveryArea.Name);
				
			EndIf;
			
		EndIf;
		
		If Object.DeliveryMethod = Enums.TransportMethods25.ByCarrier Then
			
			VisibleElementsNames.Add(Items.Carrier.Name);
			
			If Object.DeliveryPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument Then
				
				NamesOfRequiredElements.Add(Items.Carrier.Name);
				
			EndIf;
			
		EndIf;
		
		If Object.DeliveryMethod = Enums.TransportMethods25.OurCourier Then
			
			VisibleElementsNames.Add(Items.Courier.Name);
			
		Else
			
			VisibleElementsNames.Add(Items.SpecialTransportationConditions.Name);
			VisibleElementsNames.Add(Items.SpecialTransportationConditionsDescription.Name);
		
		EndIf;
		
	EndIf;
	
	If Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows Then
		
		VisibleElementsNames.Add(Items.PageByLine.Name);
		
	EndIf;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items,
		NamesOfAllElements,
		VisibleElementsNames);
	
	NamesOfOptionalElements = CommonClientServer.ArraysDifference(
		NamesOfPossibleMandatoryElements,
		NamesOfRequiredElements);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfOptionalElements,
		"AutoMarkIncomplete",
		False);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfOptionalElements,
		"MarkIncomplete",
		False);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfRequiredElements,
		"AutoMarkIncomplete",
		True);
	
	Items.SpecialTransportationConditionsDescription.ReadOnly = Not Object.SpecialTransportationConditions;
	
	CarrierDataIsAvailable =
		((Object.DeliveryMethod = Enums.TransportMethods25.OwnDelivery
		  And Object.DeliveryToCarrier)
		 Or Object.DeliveryMethod = Enums.TransportMethods25.ByCarrier);
		
	Items.Carrier.ReadOnly = Not CarrierDataIsAvailable;
	Items.CarrierDeliveryPoint.ReadOnly = Not CarrierDataIsAvailable;
	Items.CarrierSDeliveryArea.ReadOnly = Not CarrierDataIsAvailable;
	
EndProcedure

&AtClient
Procedure GoodsForDeliveryWhenWaitingHandlerLineIsActivated()
	
	CurrentData = Items.GoodsToDeliver.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DeliveryLine = GoodsDeliveryClientServer.NewDeliveryLineData();
	FillPropertyValues(DeliveryLine, CurrentData);
	SetVisibilityAvailabilityOfDeliveryLineDetailsItems(DeliveryLine);
	
EndProcedure

&AtClient
Procedure SetVisibilityAvailabilityOfDeliveryLineDetailsItems(DeliveryLine)
	
	VisibleElementsNames = New Array; // Array of String
	NamesOfAllElements = New Array; // Array of String
	NamesOfRequiredElements = New Array; // Array of String
	NamesOfPossibleMandatoryElements = New Array; // Array of String
	
	NamesOfAllElements.Add(Items.ItemsForDeliveryDeliveryTimeWith.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliveryDeliveryTimeBy.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliveryDeliveryToCarrier.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliveryByCarrier.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliveryCarrierSDeliveryPoint.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliveryCarrierSDeliveryZone.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliveryAdditionalInformationOnDelivery.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliverySpecialConditionsOfCarriage.Name);
	NamesOfAllElements.Add(Items.ItemsForDeliverySpecialConditionsOfCarriageDescription.Name);
	
	NamesOfPossibleMandatoryElements.Add(Items.GoodsToDeliverDeliveryPoint.Name);
	NamesOfPossibleMandatoryElements.Add(Items.GoodsToDeliverDeliveryZone.Name);
	NamesOfPossibleMandatoryElements.Add(Items.ItemsForDeliveryByCarrier.Name);
	NamesOfPossibleMandatoryElements.Add(Items.ItemsForDeliveryCarrierSDeliveryPoint.Name);
	NamesOfPossibleMandatoryElements.Add(Items.ItemsForDeliveryCarrierSDeliveryZone.Name);
	
	If DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OwnDelivery") Then
		
		Items.PagesInformation.CurrentPage = Items.PageHasDeliveryMethod;
		
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryTimeWith.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryTimeBy.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryToCarrier.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryByCarrier.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryCarrierSDeliveryPoint.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryCarrierSDeliveryZone.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryAdditionalInformationOnDelivery.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliverySpecialConditionsOfCarriage.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliverySpecialConditionsOfCarriageDescription.Name);
		
		If Object.DeliveryPlanning = PredefinedValue("Enum.DeliveryPlanningKinds.ByCurrentDocument") Then
			
			NamesOfRequiredElements.Add(Items.GoodsToDeliverDeliveryPoint.Name);
			NamesOfRequiredElements.Add(Items.GoodsToDeliverDeliveryZone.Name);
			
			If DeliveryLine.DeliveryToCarrier Then
				
				NamesOfRequiredElements.Add(Items.ItemsForDeliveryByCarrier.Name);
				NamesOfRequiredElements.Add(Items.ItemsForDeliveryCarrierSDeliveryPoint.Name);
				NamesOfRequiredElements.Add(Items.ItemsForDeliveryCarrierSDeliveryZone.Name);
				
			EndIf;
			
		EndIf;
		
	EndIf;
		
	If DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.ByCarrier") Then
		
		Items.PagesInformation.CurrentPage = Items.PageHasDeliveryMethod;
		
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryTimeWith.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryTimeBy.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryByCarrier.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryAdditionalInformationOnDelivery.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliverySpecialConditionsOfCarriage.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliverySpecialConditionsOfCarriageDescription.Name);
		
		If Object.DeliveryPlanning = PredefinedValue("Enum.DeliveryPlanningKinds.ByCurrentDocument") Then
			
			NamesOfRequiredElements.Add(Items.GoodsToDeliverDeliveryPoint.Name);
			NamesOfRequiredElements.Add(Items.GoodsToDeliverDeliveryZone.Name);
			NamesOfRequiredElements.Add(Items.ItemsForDeliveryByCarrier.Name);
			
		EndIf;
		
	EndIf;
	
	If DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.SelfPickup") Then
		
		Items.PagesInformation.CurrentPage = Items.PagePickup;
		
	EndIf;
	
	If DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.DefinedByDeliveryService") Then
		
		Items.PagesInformation.CurrentPage = Items.PageHasDeliveryMethod;
		
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryTimeWith.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryDeliveryTimeBy.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliveryAdditionalInformationOnDelivery.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliverySpecialConditionsOfCarriage.Name);
		VisibleElementsNames.Add(Items.ItemsForDeliverySpecialConditionsOfCarriageDescription.Name);
		
		NamesOfRequiredElements.Add(Items.GoodsToDeliverDeliveryPoint.Name);
		NamesOfRequiredElements.Add(Items.GoodsToDeliverDeliveryZone.Name);
		
	EndIf;
	
	If DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.EmptyRef") Then
		
		Items.PagesInformation.CurrentPage = Items.PageThereIsNoDeliveryMethod;
		
	EndIf;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items,
		NamesOfAllElements,
		VisibleElementsNames);
	
	NamesOfOptionalElements = CommonClientServer.ArraysDifference(
		NamesOfPossibleMandatoryElements,
		NamesOfRequiredElements);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfOptionalElements,
		"AutoMarkIncomplete",
		False);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfOptionalElements,
		"MarkIncomplete",
		False);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfRequiredElements,
		"AutoMarkIncomplete",
		True);
	
	Items.ItemsForDeliverySpecialConditionsOfCarriageDescription.ReadOnly = Not DeliveryLine.SpecialTransportationConditions;
	
	CarrierDataIsAvailable =
		((DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OwnDelivery")
		  And DeliveryLine.DeliveryToCarrier)
		 Or DeliveryLine.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.ByCarrier"));
	
	Items.ItemsForDeliveryByCarrier.ReadOnly = Not CarrierDataIsAvailable;
	Items.ItemsForDeliveryCarrierSDeliveryPoint.ReadOnly = Not CarrierDataIsAvailable;
	Items.ItemsForDeliveryCarrierSDeliveryZone.ReadOnly = Not CarrierDataIsAvailable;
	
EndProcedure

&AtServerNoContext
Function DeliveryPointInformationByOwner(Val DeliveryPointOwner)
	
	Return Catalogs.DeliveryPoints.DeliveryPointInformationMain(DeliveryPointOwner);
	
EndFunction

&AtServerNoContext
Function DeliveryPointArea(Val DeliveryPoint)
	
	Return Common.ObjectAttributeValue(DeliveryPoint, "DeliveryZone");
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		Items.GoodsToDeliverCharacteristic.Name,
		"Object.GoodsToDeliver.ItemVariantsAreUsed");
	
	AdditionalParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	AdditionalParameters.NameOfUnitField = Items.GoodsToDeliverProductsUnitOfMeasure.Name;
	AdditionalParameters.PathToPackagingUnitField = "Object.GoodsToDeliver.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(
		ThisObject,
		AdditionalParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		Items.GoodsToDeliverSeries.Name,
		"Object.GoodsToDeliver.BatchesIndicationStatus",
		"Object.GoodsToDeliver.ItemsType");
	
	#Region DeliveryMethodIsEmpty
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToDeliverDeliveryPoint.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToDeliverDeliveryZone.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsToDeliver.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TransportMethods25.EmptyRef();
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<укажите способ доставки>';
													|vi = '<specify the delivery method>';
													|en = '<specify the delivery method>'; fa = '<specify the delivery method>';
													|it = '<specify the delivery method>';
													|pl = '<specify the delivery method>';
													|tr = '<teslimat yöntemini belirtin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region DeliveryMethodIsSelfPickup
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToDeliverDeliveryPoint.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToDeliverDeliveryZone.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsToDeliver.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TransportMethods25.SelfPickup;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не требуется>';
													|vi = '<not required>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetParametersForHeaderDeliveryMethod()
	
	ChoiceParameters = New Array; // Array of ChoiceParameter
	
	If Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument
	   And Object.DeliveryPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument Then
		
		ChoiceParameter = New ChoiceParameter(
			"Filter.Ref",
			New FixedArray(CapDeliveryMethods.UnloadValues()));
		
	Else
		
		ChoiceParameter = New ChoiceParameter(
			"Filter.Ref",
			New FixedArray(CapDeliveryMethodsWithoutCourier.UnloadValues()));
		
		If Object.DeliveryMethod = Enums.TransportMethods25.OurCourier Then
			
			Object.DeliveryMethod = Enums.TransportMethods25.EmptyRef();
			DeliveryMethodOnChangeServer();
			
		EndIf;
		
	EndIf;
	
	ChoiceParameters.Add(ChoiceParameter);
	
	Items.DeliveryMethod.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure DeliverySpecificationMethodOnChangeServer()
	
	SetParametersForHeaderDeliveryMethod();
	SetVisibilityAccessibilityOfElements();
	CheckFillInDeliveryDetailsForEntireDocument();
	CheckFillInDeliveryDetailsLineByLine();
	
EndProcedure

&AtServer
Procedure DeliveryPlanningOnChangeServer()
	
	SetParametersForHeaderDeliveryMethod();
	SetVisibilityAccessibilityOfElements();
	
EndProcedure

&AtServer
Procedure DeliveryMethodOnChangeServer()
	
	If Object.DeliveryMethod <> Enums.TransportMethods25.OwnDelivery Then
		
		Object.DeliveryToCarrier = False;
		
	EndIf;
	
	If Object.DeliveryMethod <> Enums.TransportMethods25.OwnDelivery
	   And Object.DeliveryMethod <> Enums.TransportMethods25.ByCarrier Then
		
		Object.Carrier = Catalogs.Partners.EmptyRef();
		Object.CarrierDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
		Object.CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	If Object.DeliveryMethod = Enums.TransportMethods25.OurCourier Then
		
		Object.SpecialTransportationConditions = False;
		Object.SpecialTransportationConditionsDescription = "";
		
	Else
		
		Object.Courier = Catalogs.Persons.EmptyRef();
		
	EndIf;
	
	SetVisibilityAccessibilityOfElements();
	
EndProcedure

#EndRegion

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
