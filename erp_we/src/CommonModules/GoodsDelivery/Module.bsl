// @strict-types

#Region Public

// Settings for checking the use of delivery Attributes.
// An empty field name means that it is not used in the object.
//
// Returns:
//  Structure:
// * DocumentObject - DocumentObject, Undefined - Delivery object to be checked (required)
// * DeliveryWarehouses - Array of CatalogRef.Warehouses - warehouses that are used for delivery processing
// * OwnerOfDeliveryPoints - CatalogRef.Partners, CatalogRef.Warehouses, Undefined - owner of document delivery points
// * DeliveryIsRequired - Boolean - Transportation is required in general
// * TypeOfDeliveryPlanningFieldName - String - the name of the field with the delivery address, if not specified, the value must be specified in the Delivery scheduling viewconditional
// * TypeOfDeliveryPlanningIsUnconditional - EnumRef.DeliveryPlanningKinds  - value (required) if you don't specify the type of delivery planingfields
// * DeliveryIndicationMethodFieldName - String - the name of the delivery indication method field, if not specified, the value in the delivery method must be specified unconditionally
// * MethodOfSpecifyingDeliveryIsUnconditional - EnumRef.DeliverySpecificationMethods - value (required), if the method of specifying the delivery field is not specified
// * DeliveryMethod_FieldName - String - the name of the delivery method field, if not specified, the value must be specified in the Delivery methoddetermination
// * DeliveryMethodIsUnconditional - EnumRef.TransportMethods25 - value if no delivery method is setFields
// * DeliveryTimeWithFieldName - String - the name of the delivery time field from
// * DeliveryTimeByFieldName - String - name of the delivery time field by
// * DeliveryPointFieldName - String - delivery point field name 
// * DeliveryZoneFieldName - String  - field name of the deliveryzone
// * CarrierFieldName - String - name of the carrier field
// * DeliveryToCarrierFieldName - String - the name of the delivery field to the carrier, if not specified, the value must be specified in the deliveringcarrierreferencesexternal links
// * DeliveryToCarrierIsUnconditional - Boolean - value if you don't specify a deliverancerimage fields
// * CarrierSDeliveryPointFieldName - String - field name of the delivery point to the carrier
// * CarrierSDeliveryZoneFieldName - String - name of the carrier's deliveryzone field
// * DeliveryAddressFieldName - String - name of the delivery address field
// * AdditionalDeliveryInformationFieldName - String - The name of the additional information field for transportation may be empty
// * SpecialConditionsOfCarriageFieldName - String - Name of the field that indicates special conditions of carriage
// * SpecialConditionsOfCarriageDescriptionFieldName - String - Name of the field describing special conditions of carriage
// * GoodsForDeliveryTableName - String - the name of the tabular part of the goods for delivery
// * DeliveryGoodsTable - See NewDeliveryGoodsTable
// * InvoiceForOrders - Boolean - Used for delivery 2.0
//
Function NewSettingsForCheckingUseOfDeliveryDetails() Export
	
	NewSettings1 = New Structure;
	
	NewSettings1.Insert("DocumentObject", Undefined);
	NewSettings1.Insert("DeliveryWarehouses", New Array);
	NewSettings1.Insert("OwnerOfDeliveryPoints", Undefined);
	
	NewSettings1.Insert("DeliveryIsRequired", False);
	
	NewSettings1.Insert("TypeOfDeliveryPlanningFieldName", "DeliveryPlanning");
	NewSettings1.Insert("TypeOfDeliveryPlanningIsUnconditional", Enums.DeliveryPlanningKinds.EmptyRef());
	NewSettings1.Insert("DeliveryIndicationMethodFieldName", "DeliverySpecificationMethod");
	NewSettings1.Insert("MethodOfSpecifyingDeliveryIsUnconditional", Enums.DeliverySpecificationMethods.EmptyRef());
	NewSettings1.Insert("DeliveryMethod_FieldName", "DeliveryMethod25");
	NewSettings1.Insert("DeliveryMethodIsUnconditional", Enums.TransportMethods25.EmptyRef());
	
	NewSettings1.Insert("DeliveryTimeWithFieldName", "DeliveryTimeFrom");
	NewSettings1.Insert("DeliveryTimeByFieldName", "DeliveryTimeTo");
	
	NewSettings1.Insert("DeliveryPointFieldName", "DeliveryPoint");
	NewSettings1.Insert("DeliveryZoneFieldName", "DeliveryZone");
	
	NewSettings1.Insert("CarrierFieldName", "CarrierPartner");
	NewSettings1.Insert("DeliveryToCarrierFieldName", "DeliveryToCarrier");
	NewSettings1.Insert("DeliveryToCarrierIsUnconditional", False);
	NewSettings1.Insert("CarrierSDeliveryPointFieldName", "CarrierDeliveryPoint");
	NewSettings1.Insert("CarrierSDeliveryZoneFieldName", "CarrierSDeliveryArea");
	
	NewSettings1.Insert("DeliveryAddressFieldName", "DeliveryAddress");
	NewSettings1.Insert("AdditionalDeliveryInformationFieldName", "AdditionalDeliveryInformation");
	NewSettings1.Insert("SpecialConditionsOfCarriageFieldName", "SpecialTransportationConditions");
	NewSettings1.Insert("SpecialConditionsOfCarriageDescriptionFieldName", "SpecialTransportationConditionsDescription");
	
	NewSettings1.Insert("GoodsForDeliveryTableName", "GoodsToDeliver");
	NewSettings1.Insert("DeliveryGoodsTable", NewDeliveryGoodsTable());
	
	// Data for delivery 2.0
	NewSettings1.Insert("InvoiceForOrders", False);
	
	Return NewSettings1;
	
EndFunction

// Checks whether delivery data is filled in correctly based on the transmitted settings
//
// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  NotCheckedAttributeArray - Array of String - Array of names of unverifiable Attributes to be filled in
//  Cancel - Boolean - 
//
Procedure CheckCompletionOfDeliveryDetails(Settings, NotCheckedAttributeArray, Cancel) Export
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then 
		
		CheckDeliveryDetails(
			Settings.DocumentObject,
			NotCheckedAttributeArray,
			Cancel,
			Settings.InvoiceForOrders);
		
		Return;
		
	EndIf;
	
	// For compatibility with Delivery 2.0, it is required to keep the platform check,
	// and for Delivery 2.5 a different algorithm is used
	NotCheckedAttributeArray.Add(Settings.CarrierFieldName);
	NotCheckedAttributeArray.Add(Settings.SpecialConditionsOfCarriageDescriptionFieldName);
	
	If Not GoodsDeliveryClientServer.UsedDelivery() Then
		
		NotCheckedAttributeArray.Add(Settings.DeliveryAddressFieldName);
		Return;
		
	EndIf;
	
	Object = Settings.DocumentObject; // DocumentObject
	
	If Settings.DeliveryIsRequired Then
		
		If IsBlankString(Settings.TypeOfDeliveryPlanningFieldName) Then
			DeliveryPlanning = Settings.TypeOfDeliveryPlanningIsUnconditional;
		Else
			DeliveryPlanning = Object[Settings.TypeOfDeliveryPlanningFieldName]; // EnumRef.DeliveryPlanningKinds
		EndIf;
		
		If IsBlankString(Settings.DeliveryIndicationMethodFieldName) Then
			DeliverySpecificationMethod = Settings.MethodOfSpecifyingDeliveryIsUnconditional;
		Else
			DeliverySpecificationMethod = Object[Settings.DeliveryIndicationMethodFieldName]; // EnumRef.DeliverySpecificationMethods
		EndIf;
		
		If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
			
			NotCheckedAttributeArray.Add(Settings.DeliveryAddressFieldName);
			
		EndIf;
		
		If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
			
			If IsBlankString(Settings.DeliveryMethod_FieldName) Then
				DeliveryMethod = Settings.DeliveryMethodIsUnconditional;
			Else
				DeliveryMethod = Object[Settings.DeliveryMethod_FieldName]; // EnumRef.TransportMethods25
			EndIf;
			
			If DeliveryMethod.IsEmpty() Then
				
				ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Способ доставки';
																		|vi = 'Delivery method';
																		|en = 'Delivery method'; fa = 'روش تحویل';
																		|it = 'Metodo di consegna';
																		|pl = 'Sposób dostarczenia';
																		|tr = 'Teslimat yöntemi'"));
				Common.MessageToUser(
					ErrorText,
					Object,
					"DeliveryIsRequired",
					,
					Cancel);
				
				EndIf;
				
		EndIf;
		
		If DeliveryPlanning = Enums.DeliveryPlanningKinds.SeparateDocument Then
			
			CheckUpdatePointDataDeliveryZone(DeliverySpecificationMethod, Settings, False, True, True, Cancel);
			DisableVerificationOfRequiredDeliveryDataFields(NotCheckedAttributeArray, Settings);
			
		Else
			
			CheckUpdateDeliveryFieldData(Settings, Cancel, True);
			
		EndIf;
		
		// Other information is always checked, regardless of the type of delivery planning
		CheckUpdateDetailsOfDeliveryDataByWarehouses(Settings, Cancel);
		CheckIntersectionOfCustomerAndCarrier(Settings, DeliverySpecificationMethod, Cancel);
		
	Else
		
		DisableVerificationOfRequiredDeliveryDataFields(NotCheckedAttributeArray, Settings);
		
	EndIf;
	
EndProcedure

// Checks whether delivery data is filled in correctly based on the transmitted settings
//
// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  Cancel - Boolean - 
//
Procedure ClearUnusedDeliveryFields(Settings, Cancel) Export
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		Return;
	EndIf;
	
	WarehousesDeliveryDetailsTableName = "WarehousesDeliveryInformation";
	
	Object = Settings.DocumentObject; // DocumentObject
	
	If Settings.DeliveryIsRequired Then
		
		If IsBlankString(Settings.DeliveryIndicationMethodFieldName) Then
			DeliverySpecificationMethod = Settings.MethodOfSpecifyingDeliveryIsUnconditional;
		Else
			DeliverySpecificationMethod = Object[Settings.DeliveryIndicationMethodFieldName]; // EnumRef.DeliverySpecificationMethods
		EndIf;
		
		If IsBlankString(Settings.DeliveryMethod_FieldName) Then
			DeliveryMethod = Settings.DeliveryMethodIsUnconditional;
		Else
			DeliveryMethod = Object[Settings.DeliveryMethod_FieldName]; // EnumRef.TransportMethods25
		EndIf;
		
		#Region Carrier
		If IsBlankString(Settings.DeliveryToCarrierFieldName) Then
			DeliveryToCarrier = Settings.DeliveryToCarrierIsUnconditional;
		Else
			DeliveryToCarrier = Object[Settings.DeliveryToCarrierFieldName]; // Boolean
		EndIf;
		
		If (DeliveryMethod = Enums.TransportMethods25.OwnDelivery
				And Not DeliveryToCarrier)
			Or DeliveryMethod = Enums.TransportMethods25.OurCourier
			Or DeliveryMethod = Enums.TransportMethods25.SelfPickup
			Or DeliveryMethod = Enums.TransportMethods25.DefinedByDeliveryService
			Or DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows Then
			
			If Not IsBlankString(Settings.CarrierFieldName) Then
				Object[Settings.CarrierFieldName] = Catalogs.Partners.EmptyRef();
			EndIf;
			
			If Not IsBlankString(Settings.CarrierSDeliveryPointFieldName) Then
				Object[Settings.CarrierSDeliveryPointFieldName] = Catalogs.DeliveryPoints.EmptyRef();
			EndIf;
			
			If Not IsBlankString(Settings.CarrierSDeliveryZoneFieldName) Then
				Object[Settings.CarrierSDeliveryZoneFieldName] = Catalogs.DeliveryZones.EmptyRef();
			EndIf;
			
		EndIf;
		#EndRegion
		
		If Not IsBlankString(Settings.SpecialConditionsOfCarriageFieldName)
			And Not Object[Settings.SpecialConditionsOfCarriageFieldName] Then
			
			If Not IsBlankString(Settings.SpecialConditionsOfCarriageDescriptionFieldName) Then
				Object[Settings.SpecialConditionsOfCarriageDescriptionFieldName] = "";
			EndIf;
			
		EndIf;
		
		If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument
			And Not IsBlankString(Settings.GoodsForDeliveryTableName) Then
			
			// The data inside the table is processed as part of the field validation/update method
			TableGoodsForDelivery = Object[Settings.GoodsForDeliveryTableName]; // TabularSection
			TableGoodsForDelivery.Clear();
			
		EndIf;
		
	Else
		
		If Not IsBlankString(Settings.TypeOfDeliveryPlanningFieldName) Then
			Object[Settings.TypeOfDeliveryPlanningFieldName] = Enums.DeliveryPlanningKinds.EmptyRef();
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryIndicationMethodFieldName) Then
			Object[Settings.DeliveryIndicationMethodFieldName] = Enums.DeliverySpecificationMethods.EmptyRef();
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryMethod_FieldName) Then
			Object[Settings.DeliveryMethod_FieldName] = Enums.TransportMethods25.EmptyRef();
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryTimeWithFieldName) Then
			Object[Settings.DeliveryTimeWithFieldName] = Date(1, 1, 1, 0, 0, 0);
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryTimeByFieldName) Then
			Object[Settings.DeliveryTimeByFieldName] = Date(1, 1, 1, 0, 0, 0);
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryPointFieldName) Then
			Object[Settings.DeliveryPointFieldName] = Catalogs.DeliveryPoints.EmptyRef();
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryZoneFieldName) Then
			Object[Settings.DeliveryZoneFieldName] = Catalogs.DeliveryZones.EmptyRef();
		EndIf;
		
		#Region Carrier
		If Not IsBlankString(Settings.CarrierFieldName) Then
			Object[Settings.CarrierFieldName] = Catalogs.Partners.EmptyRef();
		EndIf;
		
		If Not IsBlankString(Settings.DeliveryToCarrierFieldName) Then
			Object[Settings.DeliveryToCarrierFieldName] = False;
		EndIf;
		
		If Not IsBlankString(Settings.CarrierSDeliveryPointFieldName) Then
			Object[Settings.CarrierSDeliveryPointFieldName] = Catalogs.DeliveryPoints.EmptyRef();
		EndIf;
		
		If Not IsBlankString(Settings.CarrierSDeliveryZoneFieldName) Then
			Object[Settings.CarrierSDeliveryZoneFieldName] = Catalogs.DeliveryZones.EmptyRef();
		EndIf;
		#EndRegion
		
		If Not IsBlankString(Settings.AdditionalDeliveryInformationFieldName) Then
			Object[Settings.AdditionalDeliveryInformationFieldName] = "";
		EndIf;
		
		If Not IsBlankString(Settings.SpecialConditionsOfCarriageFieldName) Then
			Object[Settings.SpecialConditionsOfCarriageFieldName] = False;
		EndIf;
		
		If Not IsBlankString(Settings.SpecialConditionsOfCarriageDescriptionFieldName) Then
			Object[Settings.SpecialConditionsOfCarriageDescriptionFieldName] = "";
		EndIf;
		
		If Not IsBlankString(Settings.GoodsForDeliveryTableName) Then
			
			TableGoodsForDelivery = Object[Settings.GoodsForDeliveryTableName]; // TabularSection
			TableGoodsForDelivery.Clear();
			
		EndIf;
		
		TableWarehousesDeliveryDetails = Object[WarehousesDeliveryDetailsTableName]; // TabularSection
		TableWarehousesDeliveryDetails.Clear();
		
	EndIf;
	
EndProcedure

// Updates the details of delivery points (if their details are not filled in)
//
// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  ToOutputErrors - Boolean
//  Cancel - Boolean - 
//
Procedure UpdateDeliveryFieldData(Settings, ToOutputErrors, Cancel) Export
	
	If GoodsDeliveryClientServer.UsedDelivery20() 
		Or Not Settings.DeliveryIsRequired Then
		
		ClearUnusedDeliveryFields(Settings, Cancel);
		Return;
		
	EndIf;
	
	CheckUpdateDeliveryFieldData(Settings, Cancel, ToOutputErrors, True);
	
EndProcedure

// Updates Delivery warehouse information (if the warehouses and their data are not filled in)
//
// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  ToOutputErrors - Boolean
//  Cancel - Boolean - 
//
Procedure UpdateDeliveryWarehouseDetails(Settings, ToOutputErrors, Cancel) Export
	
	If GoodsDeliveryClientServer.UsedDelivery20() 
		Or Not Settings.DeliveryIsRequired Then
		
		Return;
		
	EndIf;
	
	CheckUpdateDetailsOfDeliveryDataByWarehouses(Settings, Cancel, True, ToOutputErrors);
	
EndProcedure

// Verifies that delivery is provided for the transferred warehouse operation.
//
// Parameters:
//  WarehouseOperation - EnumRef.WarehouseTransactions - warehouse operation.
// 
// Returns:
//  Boolean - True - delivery is provided for the transferred warehouse operation.
//
Function ThereIsDeliveryOnWarehouseOperation(WarehouseOperation) Export
	
	QueryText = WarehousesServer.QueryTextWarehouseOperationDocumentType() + " 
	|SELECT
	|	WarehouseOperationDocumentType.WarehouseOperation
	|FROM
	|	WarehouseOperationDocumentType AS WarehouseOperationDocumentType
	|
	|WHERE
	|	WarehouseOperationDocumentType.WarehouseOperation = &WarehouseOperation
	|	AND WarehouseOperationDocumentType.Type IN (&TypesOfDeliveryOrder)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("WarehouseOperation", WarehouseOperation);
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		TypesOfDeliveryOrder = Metadata.DefinedTypes.DeliveryReferenceOrder25.Type.Types();
	Else
		TypesOfDeliveryOrder = Metadata.DefinedTypes.DeliveryReferenceOrder.Type.Types();
	EndIf;
	Query.SetParameter("TypesOfDeliveryOrder", TypesOfDeliveryOrder);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#Region WorkingWithForms

// Defines the headers of delivery setup items based on system settings
// 
// Parameters:
//  Form - See Catalog.Warehouses.Form.ItemForm
//
Procedure SetWarehouseFormElementSettings(Form) Export
	
	If Not GoodsDeliveryClientServer.UsedDelivery() Then
		Return;
	EndIf;
	
	Items = Form.Items;
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		TitleKittingIsPlannedForDelivery = NStr("ru = 'Собирать товары в порядке доставки';
												|vi = 'Pick goods according to the delivery procedure';
												|en = 'Pick goods according to the delivery procedure'; fa = 'برداشت کالا طبق رویه تحویل';
												|it = 'Raccogliere le merci nell''ordine di consegna';
												|pl = 'Zbieraj wiersze pozycji w kolejności dostawy';
												|tr = 'Ürünleri teslimat düzenine göre topla'");
		TitleDeliveryKittingIndependently = NStr("ru = 'Порядок отбора товаров не зависит от порядка доставки';
												|vi = 'Goods picking priority doesn''t depend on the delivery sequence';
												|en = 'Goods picking priority doesn''t depend on the delivery sequence'; fa = 'اولویت برداشت کالا به توالی تحویل بستگی ندارد';
												|it = 'L''ordine di selezione delle merci non dipende dall''ordine di consegna';
												|pl = 'Kolejność selekcji towarów nie zależy od kolejności dostawy';
												|tr = 'Ürünlerin filtre düzeni, teslimat düzenine bağlı değildir'");
		
		HintKitIsPlannedForDelivery = NStr("ru = 'Если распоряжением на отгрузку предусмотрена доставка, то расходные ордера можно будет создать только после включения распоряжения в задание на перевозку.';
											|vi = 'If a shipment reference provides delivery, then goods issues can be created only after the reference is included in the itinerary.';
											|en = 'If a shipment reference provides delivery, then goods issues can be created only after the reference is included in the itinerary.'; fa = 'اگر مرجع ارسال شامل تحویل باشد، حواله‌های انبار فقط پس از گنجاندن مرجع در مسیر سفر قابل ایجاد هستند.';
											|it = 'Se l''ordine di spedizione prevede la consegna, allora gli ordinativi di consumo si possono creare solo dopo l''inclusione degli ordini nell''assegnazione per il trasporto.';
											|pl = 'Jeżeli zamówieniem do wysyłki jest przewidziana dostawa, to wydania zewnętrzne można będzie utworzyć tylko po włączeniu rozporządzenia do zadania do dostawy.';
											|tr = 'Sevkiyat talimatlarına teslimat sağlandıysa, ambar çıkış fişleri sadece taşıma planına talimat dahil edildikten sonra oluşturulabilir.'");
		HintDeliveryKittingRegardless = NStr("ru = 'Расходные ордера создаются без учета заданий на перевозку. Если распоряжение на отгрузку предусматривает доставку, то нужно будет перед отгрузкой указать в ордере задание на перевозку.';
											|vi = 'Goods issues are created ignoring itineraries. If a shipment reference includes delivery, add an itinerary to the goods issue before shipment.';
											|en = 'Goods issues are created ignoring itineraries. If a shipment reference includes delivery, add an itinerary to the goods issue before shipment.'; fa = 'حواله‌های انبار بدون توجه به مسیرهای سفر ایجاد می‌شوند. اگر مرجع ارسال شامل تحویل باشد، پیش از ارسال یک مسیر سفر به حواله انبار اضافه کنید.';
											|it = 'Gli ordinativi di consumo vengono creati indipendentemente dalla contabilità di task per il trasporto. Se l''ordine di spedizione prevede la consegna, allora sarà necessario specificare il task per il trasporto nell''ordine prima della spedizione.';
											|pl = 'Wydania zewnętrzne są stwarzane bez uwzględnienia zadań na przewóz. Jeżeli zamówienie do wysyłki przewiduje dostawę, to trzeba będzie przed wysyłką wskazać w zleceniu zadanie na przewóz.';
											|tr = 'Ambar çıkış fişleri, taşıma planı hesaba katılmadan oluşturulur. Sevkiyat talimatına teslimat sağlıyorsa, sevkiyattan önce taşıma planını emirde belirtmeniz gerekecektir.'");
		
	Else
		
		TitleKittingIsPlannedForDelivery = NStr("ru = 'Сборка осуществляется после планирования доставки';
												|vi = 'Picking after delivery planning';
												|en = 'Picking after delivery planning'; fa = 'Picking after delivery planning';
												|it = 'Picking after delivery planning';
												|pl = 'Picking after delivery planning';
												|tr = 'Toplama, teslimat planlamasından sonra gerçekleştirilir'");
		TitleDeliveryKittingIndependently = NStr("ru = 'Доставка и сборка планируются независимо';
												|vi = 'Delivery and picking are planned independently';
												|en = 'Delivery and picking are planned independently'; fa = 'Delivery and picking are planned independently';
												|it = 'Delivery and picking are planned independently';
												|pl = 'Delivery and picking are planned independently';
												|tr = 'Teslimat ve toplama bağımsız olarak planlanır'");
		
		HintKitIsPlannedForDelivery = NStr("ru = 'Сборка осуществляется после того, как распоряжение на доставку включено в рейс, планирующийся к погрузке. Расходный ордер связан с рейсом.';
											|vi = 'Picking is carried out after the delivery reference is included in the trip scheduled for lading. The goods issue is related to the trip.';
											|en = 'Picking is carried out after the delivery reference is included in the trip scheduled for lading. The goods issue is related to the trip.'; fa = 'Picking is carried out after the delivery reference is included in the trip scheduled for lading. The goods issue is related to the trip.';
											|it = 'Picking is carried out after the delivery reference is included in the trip scheduled for lading. The goods issue is related to the trip.';
											|pl = 'Picking is carried out after the delivery reference is included in the trip scheduled for lading. The goods issue is related to the trip.';
											|tr = 'Toplama, teslimat talimatı yüklenmeye planlanan sefere dahil edildikten sonra gerçekleştirilir. Ambar çıkış fişi seferle ilişkilidir.'");
		HintDeliveryKittingRegardless = NStr("ru = 'Расходные ордера создаются без учета рейса. Сборка и планирование доставки происходит независимо. Расходный ордер и рейс не связаны.';
											|vi = 'Goods issues are created without taking trips into account. Picking and delivery planning is carried out independently. The goods issues and the trip are not related.';
											|en = 'Goods issues are created without taking trips into account. Picking and delivery planning is carried out independently. The goods issues and the trip are not related.'; fa = 'Goods issues are created without taking trips into account. Picking and delivery planning is carried out independently. The goods issues and the trip are not related.';
											|it = 'Goods issues are created without taking trips into account. Picking and delivery planning is carried out independently. The goods issues and the trip are not related.';
											|pl = 'Goods issues are created without taking trips into account. Picking and delivery planning is carried out independently. The goods issues and the trip are not related.';
											|tr = 'Sevk fişleri sefer dikkate alınmadan oluşturulur. Toplama ve teslimat planlaması bağımsız olarak gerçekleşir. Ambar çıkış fişi ve sefer ilişkili değildir.'");
		
	EndIf;
	
	Items.ProcedureOfTransportationJobIndication1.ChoiceList[0].Presentation = TitleKittingIsPlannedForDelivery;
	Items.ProcedureOfTransportationJobIndication2.ChoiceList[0].Presentation = TitleDeliveryKittingIndependently;
	
	Items.ProcedureOfTransportationJobIndication1.ExtendedTooltip.Title = HintKitIsPlannedForDelivery;
	Items.ProcedureOfTransportationJobIndication2.ExtendedTooltip.Title = HintDeliveryKittingRegardless;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds
//
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	LongDesc = LongDesc + "
	|Catalog.DeliveryOrderAttachedFiles.Read.Companies
	|Catalog.DeliveryOrderAttachedFiles.Update.Companies
	|Catalog.TripAttachedFiles.Read.Companies
	|Catalog.TripAttachedFiles.Update.Companies
	|Catalog.DeliveryPoints.Read.ExternalUsers
	|Catalog.DeliveryPoints.Read.Warehouses
	|Catalog.DeliveryPoints.Update.Warehouses
	|Catalog.DeliveryPoints.Read.PartnerGroups
	|Catalog.DeliveryPoints.Update.PartnerGroups
	|Document.DeliveryOrder.Read.PartnerGroups
	|Document.DeliveryOrder.Read.Companies
	|Document.DeliveryOrder.Read.Warehouses
	|Document.DeliveryOrder.Update.PartnerGroups
	|Document.DeliveryOrder.Update.Companies
	|Document.DeliveryOrder.Update.Warehouses
	|Document.Trip.Read.Companies
	|Document.Trip.Read.Warehouses
	|Document.Trip.Update.Companies
	|Document.Trip.Update.Warehouses
	|AccumulationRegister.Delivery.Read.PartnerGroups
	|AccumulationRegister.Delivery.Read.Companies
	|AccumulationRegister.Delivery.Read.Warehouses
	|";
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_DeliveryOrder";
	Set.Ref = New UUID("4168361e-b247-4e96-9bad-e3396176572e");
	Set.Used = GetFunctionalOption("NotUseDeliveryManagement20");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Заказ на доставку';
		|vi = 'Delivery order';
		|en = 'Delivery order';
		|it = 'Delivery order';
		|pl = 'Delivery order';
		|tr = 'Teslimat siparişi'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_Trip";
	Set.Ref = New UUID("d2a3c499-0913-4c02-a893-be7edb9c393f");
	Set.Used = GetFunctionalOption("NotUseDeliveryManagement20");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"ru = 'Рейс';
		|vi = 'Trip';
		|en = 'Trip';
		|it = 'Trip';
		|pl = 'Trip';
		|tr = 'Sefer'", LanguagesCodes); // @NStr-2
	
EndProcedure

// See ReportsOptionsOverridable.DefineObjectsWithReportCommands
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.Trip);
	
EndProcedure

#Region AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.DeliveryPoints, True);
	Lists.Insert(Metadata.Catalogs.DeliveryOrderAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.TripAttachedFiles, True);
	
	Lists.Insert(Metadata.Documents.DeliveryOrder, True);
	Lists.Insert(Metadata.Documents.Trip, True);
	
	Lists.Insert(Metadata.AccumulationRegisters.Delivery, True);
	
EndProcedure

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles
Procedure AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	AddDeliveryManagerProfile(ProfilesDetails, ParametersOfUpdate);
	
EndProcedure

#EndRegion

#EndRegion

#Region Delivery20

// The procedure uses the passed order link to calculate and record the order status in the data register.
//
//	Parameters:
//		ExternalLinks - Array of DocumentRef -
//						   - DocumentRef - links to documents that need to be used to calculate the shipment status.
//					In the Document manager module, the Text Request Request Delivery function() must be defined.
//		Cancel - Boolean - indicates that processing has been interrupted.
//		RemovalOfBody - Boolean - indicates whether the deletion is processed.
//
Procedure ReflectDeliveryState(ExternalLinks, Cancel = False, RemovalOfBody = False) Export
	
	If Cancel
	 Or Not ValueIsFilled(ExternalLinks)
	 Or Not GoodsDeliveryClientServer.UsedDelivery20() Then
		Return;
	EndIf;
	
	If TypeOf(ExternalLinks) <> Type("Array") Then
		
		ReferencesArrray = New Array; // Array of DocumentRef, CatalogRef
		ReferencesArrray.Add(ExternalLinks);
		
		ArrayOfContractsOrders = New Array; // Array of CatalogRef.CounterpartyContracts
		
		ContractOrder = GetContractOrder(ExternalLinks);
		
		If ContractOrder <> Undefined Then
			
			Contract = Common.ObjectAttributeValue(ExternalLinks, "Contract"); // CatalogRef.CounterpartyContracts
			
			ReferencesArrray.Add(Contract);
			ArrayOfContractsOrders.Add(Contract);
			
		EndIf;
		
	Else
		
		ReferencesArrray = ExternalLinks;
		ArrayOfContractsOrders = New Array;
		
		ContractOrder = GetContractOrder(ExternalLinks);
		
		If ContractOrder <> Undefined Then
			
			Contract = Common.ObjectAttributeValue(ExternalLinks, "Contract"); // CatalogRef.CounterpartyContracts
			
			ReferencesArrray.Add(Contract);
			ArrayOfContractsOrders.Add(Contract);
			
		EndIf;
		
	EndIf;
	
	If RemovalOfBody Then
		For Each Ref In ReferencesArrray Do
			Set = InformationRegisters.StatesAndDetailsOfDelivery.CreateRecordSet();
			Set.Filter.ReferenceOrder.Set(Ref);
			SetPrivilegedMode(True);
			Set.Write(True);
			SetPrivilegedMode(False);
		EndDo;
		Return;
	EndIf;
	
	UseTransportationJobsForDeliveryAccountingByCarriers = GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
	
	ThisIsDeliveryToOurWarehouse = GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(ReferencesArrray[0]);
	
	TableOfOrders = New ValueTable;
	TableOfOrders.Columns.Add("Ref", Metadata.DefinedTypes.DeliveryReferenceOrder.Type);
	MapTypes = New Map;
	QueryText = "";
	For Each Ref In ReferencesArrray Do
		
		If GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(Ref) Then
			
			AcceptanceParameters = GetAcceptanceParameters(Ref);
			
			DeliveryMethod = Common.ObjectAttributeValue(Ref, "DeliveryMethod");
			
			DeliveryIsDefinedInContract = DeliveryIsDefinedInContract(Ref);
			
			If ((AcceptanceParameters.AgreementIsOrder
					Or DeliveryIsDefinedInContract
						And AcceptanceParameters.ContractIsOrder)
					And AcceptanceParameters.ThisIsOrder_)
				Or
					(Not AcceptanceParameters.ThisIsAdmissionDocument
					And GoodsDeliveryClientServer.ShippingIsUsed(DeliveryMethod,
						UseTransportationJobsForDeliveryAccountingByCarriers)) Then
				
				Set = InformationRegisters.StatesAndDetailsOfDelivery.CreateRecordSet();
				Set.Filter.ReferenceOrder.Set(Ref);
				Set.Write(True);
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		NewRow = TableOfOrders.Add();
		NewRow.Ref = Ref;
		
		If TypeOf(Ref) = Type("CatalogRef.CounterpartyContracts") Then
			Continue; // The use of the contract as an order is defined in the documents
		EndIf;
		
		RefType = TypeOf(Ref);
		If MapTypes[RefType] <> Undefined Then
			Continue;
		EndIf;
		MapTypes.Insert(RefType,True);
		ObjectManager = Common.ObjectManagerByRef(Ref);
		QueryTextByDocument = ObjectManager.QueryTextDeliveryDetails_();
		If GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(Ref) Then
			AcceptanceParameters = GetAcceptanceParameters(Ref);
			QueryTextByDocument = StrReplace(QueryTextByDocument, "&ThisIsOrder_", ?(AcceptanceParameters.ThisIsOrder_, "TRUE", "FALSE"));
		EndIf;
		If QueryText = "" Then
			From_Position = StrFind(QueryTextByDocument, "FROM");
			QueryText = Left(QueryTextByDocument,From_Position - 1)
						+ " INTO OrderData_3
						|" + Right(QueryTextByDocument,StrLen(QueryTextByDocument) - From_Position + 1);
		Else
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + QueryTextByDocument;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(QueryTextByDocument) Then
		Return;
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator()
	+
	"SELECT
	|	TableOfOrders.Ref AS Ref,
	|	TableOfOrders.Ref REFS Document.InstructionForShippingAgent AS ThisIsInstructionForShippingAgent
	|INTO TableOfOrders
	|FROM
	|	&TableOfOrders AS TableOfOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToDeliver.TransportationJob AS TransportationJob,
	|	GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
	|	GoodsToDeliver.Warehouse AS Warehouse,
	|	GoodsToDeliver.Products AS Products,
	|	GoodsToDeliver.Characteristic AS Characteristic,
	|	GoodsToDeliver.Purpose AS Purpose,
	|	GoodsToDeliver.Series AS Series,
	|	GoodsToDeliver.Count AS Count,
	|	GoodsToDeliver.AllGoods AS AllGoods
	|INTO GoodsToDeliver
	|FROM
	|	InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|		INNER JOIN TableOfOrders AS TableOfOrders
	|		ON (TableOfOrders.Ref = GoodsToDeliver.ReferenceOrder)
	|		INNER JOIN Document.TransportationJob AS DocumentTransportationJob
	|		ON (DocumentTransportationJob.Ref = GoodsToDeliver.TransportationJob)
	|			AND (DocumentTransportationJob.Posted)
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Warehouse,
	|	TransportationJob
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TaskManager.ReferenceOrder AS Ref,
	|	TaskManager.Warehouse AS Warehouse,
	|	MIN(CASE
	|			WHEN GoodsToDeliver.TransportationJob IS NULL
	|					AND TransportationTaskHeader.Posted
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS AllCompletedTasksWithoutGoods,
	|	ISNULL(MAX(CASE
	|				WHEN GoodsToDeliver.AllGoods
	|						AND TransportationTaskHeader.Posted
	|					THEN TRUE
	|				ELSE FALSE
	|			END), MAX(TableOfOrders.ThisIsInstructionForShippingAgent)) AS AllGoodsInDelivery,
	|	MIN(CASE
	|			WHEN TransportationTaskHeader.Posted
	|					AND TransportationTaskHeader.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|					AND TaskManager.Delivered
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS AllJobsAreClosed,
	|	MAX(TransportationTaskHeader.Posted
	|				AND TaskManager.Delivered) AS ThereAreDeliveredGoods,
	|	MAX(TransportationTaskHeader.Posted
	|				AND NOT TaskManager.Delivered) AS ThereAreUndeliveredItems,
	|	MAX(TransportationTaskHeader.Posted) AS ThereAreCompletedTasks_,
	|	MAX(TableOfOrders.ThisIsInstructionForShippingAgent) AS ThisIsInstructionForShippingAgent
	|INTO TableForCheckingTasksAndProductsInDelivery
	|FROM
	|	Document.TransportationJob.References AS TaskManager
	|		INNER JOIN Document.TransportationJob AS TransportationTaskHeader
	|		ON TaskManager.Ref = TransportationTaskHeader.Ref
	|		INNER JOIN TableOfOrders AS TableOfOrders
	|		ON (TableOfOrders.Ref = TaskManager.ReferenceOrder)
	|		LEFT JOIN GoodsToDeliver AS GoodsToDeliver
	|		ON TaskManager.ReferenceOrder = GoodsToDeliver.ReferenceOrder
	|			AND TaskManager.Warehouse = GoodsToDeliver.Warehouse
	|			AND TaskManager.Ref = GoodsToDeliver.TransportationJob
	|
	|GROUP BY
	|	TaskManager.ReferenceOrder,
	|	TaskManager.Warehouse
	|
	|INDEX BY
	|	Ref,
	|	Warehouse,
	|	ThereAreCompletedTasks_";
	
	If ThisIsDeliveryToOurWarehouse Then
		QueryText = QueryText + Common.QueryBatchSeparator() +
		"SELECT DISTINCT
		|	TRUE AS ThereAreProductsNotIncludedInTasks,
		|	T.ReferenceOrder AS Ref,
		|	T.Warehouse
		|INTO OrdersArePartiallyInDelivery
		|FROM
		|	(SELECT
		|		GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
		|		GoodsToDeliver.Warehouse AS Warehouse,
		|		GoodsToDeliver.Products AS Products,
		|		GoodsToDeliver.Characteristic AS Characteristic,
		|		GoodsToDeliver.Purpose AS Purpose,
		|		GoodsToDeliver.Series AS Series,
		|		-GoodsToDeliver.Count AS Count
		|	FROM
		|		GoodsToDeliver AS GoodsToDeliver
		|			INNER JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
		|			ON (CheckTable.Warehouse = GoodsToDeliver.Warehouse)
		|				AND (CheckTable.Ref = GoodsToDeliver.ReferenceOrder)
		|				AND NOT CheckTable.AllGoodsInDelivery
		|				AND CheckTable.ThereAreCompletedTasks_
		|				AND CheckTable.ThereAreCompletedTasks_
		|				AND NOT CheckTable.ThisIsInstructionForShippingAgent
		|	UNION ALL
		|	
		|	SELECT
		|		DataOfOrdersOnGoods.Ref,
		|		DataOfOrdersOnGoods.Warehouse,
		|		DataOfOrdersOnGoods.Products,
		|		DataOfOrdersOnGoods.Characteristic,
		|		DataOfOrdersOnGoods.Purpose,
		|		VALUE(Catalog.ItemsBatches.EmptyRef),
		|		DataOfOrdersOnGoods.Count
		|	FROM
		|		Document.PurchaseOrder.Goods AS DataOfOrdersOnGoods
		|			INNER JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
		|			ON (CheckTable.Warehouse = DataOfOrdersOnGoods.Warehouse)
		|				AND (CheckTable.Ref = DataOfOrdersOnGoods.Ref)
		|				AND NOT CheckTable.AllGoodsInDelivery
		|				AND CheckTable.ThereAreCompletedTasks_
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DataOfOrdersOnGoods.Ref,
		|		DataOfOrdersOnGoods.Warehouse,
		|		DataOfOrdersOnGoods.Products,
		|		DataOfOrdersOnGoods.Characteristic,
		|		DataOfOrdersOnGoods.Purpose,
		|		VALUE(Catalog.ItemsBatches.EmptyRef),
		|		DataOfOrdersOnGoods.Count
		|	FROM
		|		Document.VendorInvoice.Goods AS DataOfOrdersOnGoods
		|			INNER JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
		|			ON (CheckTable.Warehouse = DataOfOrdersOnGoods.Warehouse)
		|				AND (CheckTable.Ref = DataOfOrdersOnGoods.Ref)
		|				AND NOT CheckTable.AllGoodsInDelivery
		|				AND CheckTable.ThereAreCompletedTasks_
		|
		|	UNION ALL
		|	
		|	SELECT
		|		DataOfOrdersOnGoods.Ref,
		|		DataOfOrdersOnGoods.Warehouse,
		|		DataOfOrdersOnGoods.Products,
		|		DataOfOrdersOnGoods.Characteristic,
		|		DataOfOrdersOnGoods.Purpose,
		|		VALUE(Catalog.ItemsBatches.EmptyRef),
		|		DataOfOrdersOnGoods.Count
		|	FROM
		|		Document.GoodsReceiptForStorage.Goods AS DataOfOrdersOnGoods
		|			INNER JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
		|			ON (CheckTable.Warehouse = DataOfOrdersOnGoods.Warehouse)
		|				AND (CheckTable.Ref = DataOfOrdersOnGoods.Ref)
		|				AND NOT CheckTable.AllGoodsInDelivery
		|				AND CheckTable.ThereAreCompletedTasks_) AS T
		|
		|GROUP BY
		|	T.ReferenceOrder,
		|	T.Warehouse,
		|	T.Characteristic,
		|	T.Purpose,
		|	T.Series,
		|	T.Products
		|
		|HAVING
		|	SUM(T.Count) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TRUE AS NoResidue,
		|	GoodsToReceiveTurnovers.DocumentInflow AS DocumentOfShipmentReceipt,
		|	GoodsToReceiveTurnovers.Warehouse AS Warehouse
		|INTO BalancesDueForShipmentDueForReceipt
		|FROM
		|	AccumulationRegister.GoodsToReceive.Turnovers(, , , DocumentInflow IN (&References)) AS GoodsToReceiveTurnovers
		|		LEFT JOIN AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow IN (&References)) AS RemainingGoodsDue
		|		ON GoodsToReceiveTurnovers.DocumentInflow = RemainingGoodsDue.DocumentInflow
		|			AND GoodsToReceiveTurnovers.Warehouse = RemainingGoodsDue.Warehouse
		|WHERE
		|	GoodsToReceiveTurnovers.GoodsReceiptNotesToRegisterReceipt > 0
		|	AND RemainingGoodsDue.GoodsReceiptNotesToRegisterBalance IS NULL";
	Else
		QueryText = QueryText + Common.QueryBatchSeparator() +
		"SELECT DISTINCT
		|	TRUE AS ThereAreProductsNotIncludedInTasks,
		|	T.ReferenceOrder AS Ref,
		|	T.Warehouse
		|INTO OrdersArePartiallyInDelivery
		|FROM
		|	(SELECT
		|		GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
		|		GoodsToDeliver.Warehouse AS Warehouse,
		|		GoodsToDeliver.Products AS Products,
		|		GoodsToDeliver.Characteristic AS Characteristic,
		|		GoodsToDeliver.Purpose AS Purpose,
		|		GoodsToDeliver.Series AS Series,
		|		-GoodsToDeliver.Count AS Count
		|	FROM
		|		GoodsToDeliver AS GoodsToDeliver
		|			INNER JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
		|			ON (CheckTable.Warehouse = GoodsToDeliver.Warehouse)
		|				AND (CheckTable.Ref = GoodsToDeliver.ReferenceOrder)
		|				AND NOT CheckTable.AllGoodsInDelivery
		|				AND CheckTable.ThereAreCompletedTasks_
		|				AND NOT CheckTable.ThisIsInstructionForShippingAgent
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForIssue.DocumentShipments,
		|		GoodsForIssue.Warehouse,
		|		GoodsForIssue.Products,
		|		GoodsForIssue.Characteristic,
		|		GoodsForIssue.Purpose,
		|		GoodsForIssue.Series,
		|		GoodsForIssue.ToShipReceipt
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Turnovers(, , , DocumentShipments IN (&References)) AS GoodsForIssue
		|			INNER JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
		|			ON (CheckTable.Warehouse = GoodsForIssue.Warehouse)
		|				AND (CheckTable.Ref = GoodsForIssue.DocumentShipments)
		|				AND NOT CheckTable.AllGoodsInDelivery
		|				AND CheckTable.ThereAreCompletedTasks_
		|	WHERE
		|		GoodsForIssue.ToShipReceipt > 0) AS T
		|
		|GROUP BY
		|	T.ReferenceOrder,
		|	T.Warehouse,
		|	T.Characteristic,
		|	T.Purpose,
		|	T.Series,
		|	T.Products
		|
		|HAVING
		|	SUM(T.Count) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TRUE AS NoResidue,
		|	GoodsForShipmentTurnover.DocumentShipments AS DocumentOfShipmentReceipt,
		|	GoodsForShipmentTurnover.Warehouse AS Warehouse
		|INTO BalancesDueForShipmentDueForReceipt
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(, , , DocumentShipments IN (&References)) AS GoodsForShipmentTurnover
		|		LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&References)) AS RemainingGoodsForShipment
		|		ON GoodsForShipmentTurnover.DocumentShipments = RemainingGoodsForShipment.DocumentShipments
		|			AND GoodsForShipmentTurnover.Warehouse = RemainingGoodsForShipment.Warehouse
		|WHERE
		|	GoodsForShipmentTurnover.ToShipReceipt > 0
		|	AND RemainingGoodsForShipment.ToShipBalance IS NULL";
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() +
	"SELECT
	|	TableOfOrders.Ref AS ReferenceOrder,
	|	OrderData_3.Number,
	|	OrderData_3.Date,
	|	ISNULL(OrderData_3.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
	|	OrderData_3.RecipientSender,
	|	OrderData_3.Carrier,
	|	OrderData_3.DeliveryMethod,
	|	OrderData_3.Zone,
	|	OrderData_3.Address,
	|	OrderData_3.FieldValueAddress,
	|	OrderData_3.TimeFrom,
	|	OrderData_3.TimeTo,
	|	OrderData_3.AdditionalInformation,
	|	OrderData_3.DeliverFully,
	|	OrderData_3.SpecialTransportationConditions,
	|	OrderData_3.SpecialTransportationConditionsDescription,
	|	OrderData_3.SplitGoodsIssueNotesByReferences,
	|	CASE
	|		WHEN OrderData_3.Ref IS NULL
	|			THEN UNDEFINED
	|		WHEN OrderData_3.DeliveryMethod = VALUE(Enum.TransportMethods.ByVendorToOurWarehouse)
	|			OR NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderData_3.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse)
	|			OR NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderData_3.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			OR OrderData_3.DeliveryMethod = VALUE(Enum.TransportMethods.SelfPickup)
	|				AND (NOT OrderData_3.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|					OR OrderData_3.Date < OrderData_3.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue)
	|			THEN UNDEFINED
	|		WHEN OrderData_3.Posted = FALSE
	|			THEN UNDEFINED
	|		WHEN CheckTable.AllCompletedTasksWithoutGoods
	|			THEN UNDEFINED
	|		WHEN CheckTable.AllJobsAreClosed = TRUE
	|				AND BalancesDueForShipmentDueForReceipt.NoResidue
	|			THEN UNDEFINED
	|		WHEN CheckTable.AllJobsAreClosed = TRUE
	|				AND OrdersArePartiallyInDelivery.Ref IS NULL 
	|			THEN UNDEFINED
	|
	|		WHEN ISNULL(CheckTable.ThereAreCompletedTasks_,FALSE)
	|				AND NOT ISNULL(OrdersArePartiallyInDelivery.ThereAreProductsNotIncludedInTasks,FALSE)
	|				AND ISNULL(CheckTable.ThereAreDeliveredGoods, FALSE)
	|				AND NOT ISNULL(CheckTable.ThereAreUndeliveredItems, FALSE)
	|			THEN VALUE(Enum.DeliveryStates.FullyInDelivery)
	|		ELSE
	|			VALUE(Enum.DeliveryStates.DeliveryIsRequired)
	|	END AS State
	|FROM
	|	TableOfOrders AS TableOfOrders
	|		LEFT JOIN OrderData_3 AS OrderData_3
	|		ON OrderData_3.Ref = TableOfOrders.Ref
	|		LEFT JOIN TableForCheckingTasksAndProductsInDelivery AS CheckTable
	|		ON OrderData_3.Warehouse = CheckTable.Warehouse
	|			AND OrderData_3.Ref = CheckTable.Ref
	|		LEFT JOIN OrdersArePartiallyInDelivery AS OrdersArePartiallyInDelivery
	|		ON OrderData_3.Warehouse = OrdersArePartiallyInDelivery.Warehouse
	|			AND OrderData_3.Ref = OrdersArePartiallyInDelivery.Ref
	|		LEFT JOIN BalancesDueForShipmentDueForReceipt AS BalancesDueForShipmentDueForReceipt
	|		ON OrderData_3.Warehouse = BalancesDueForShipmentDueForReceipt.Warehouse
	|			AND OrderData_3.Ref = BalancesDueForShipmentDueForReceipt.DocumentOfShipmentReceipt
	|
	|ORDER BY
	|	TableOfOrders.Ref,
	|	ISNULL(OrderData_3.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))";
	
	UseTransportationJobsForDeliveryAccountingByCarriers = GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
	
	Query = New Query(QueryText);
	Query.SetParameter("References", ReferencesArrray);
	Query.SetParameter("ReceiptOrderAgreement", ArrayOfContractsOrders);
	Query.SetParameter("TableOfOrders", TableOfOrders);
	Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
		UseTransportationJobsForDeliveryAccountingByCarriers);
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	Query.SetParameter("ShippingMethodsUsed", GoodsDeliveryClientServer.ShippingMethodsUsed(
		UseTransportationJobsForDeliveryAccountingByCarriers));
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	While Selection.NextByFieldValue("ReferenceOrder") Do
		
		SetState = InformationRegisters.StatesAndDetailsOfDelivery.CreateRecordSet();
		SetState.Filter.ReferenceOrder.Set(Selection.ReferenceOrder);
		
		While Selection.NextByFieldValue("Warehouse") Do
			
			If ValueIsFilled(Selection.State) Then
				FillPropertyValues(SetState.Add(), Selection);
			EndIf;
			
		EndDo;
		
		SetState.Write();
		
	EndDo;
	
EndProcedure

// Retrieves the list of carriers and places them in temporary storage.
//
// Parameters:
//  JobParameters - Array - contains the call parameters
//  StorageAddress - String - the address of the temporary storage where the execution result will be placed.
//
Procedure GetListOfCarriersInBackground(JobParameters, StorageAddress) Export
	
	SendersArray = GetListOfCarriers(JobParameters[0], JobParameters[1]);
	
	PutToTempStorage(SendersArray, StorageAddress);
	
EndProcedure

// Sets the properties of document forms that contain delivery details when reading or creating them.
//
// Parameters:
//  FormItems		 - FormAllItems	 - all form elements for managing properties and switching bookmarks can contain:
//  							* SpecialTransportationConditionsDescription - FormField - Required
//  							* SpecialTransportationConditionsDescription1 - FormField - optional
//  							* SpecialTransportationConditionsDescription2 - FormField - optional
//  							* SpecialConditionsOfCarriageDescriptionDeliveryByCarrier - FormField - optional
//  DocObject			       - FormDataStructure	 - object whose details are used when filling in properties,
//  OrderInvoice_3	       - Boolean				 - True if the Docobject is an invoice and for orders, otherwise False,
//  FillParameters	       - Structure			 - structure See ParametersForFillingInBankingDetails
//  SummaryInformation          - String				 - details of the form for filling out summary information on delivery.
//  FillInCarriersInBackground - Boolean				 - indicates that the carrier fill is being filled in the background.
// Returns:
//  Structure                  - See TimeConsumingOperations.ExecuteInBackground or an empty stucture.
//
Function WhenReadingCreatingOrdersOnServer(FormItems,
	DocObject, OrderInvoice_3 = False, FillParameters = Undefined, SummaryInformation = Undefined,
	FillInCarriersInBackground = False) Export
	
	AcceptanceParameters         = Undefined;
	OrderByAgreement = False;
	OrderUnderAgreement   = False;
	BackgroundJobResult = New Structure();
	
	ThisIsDeliveryToOurWarehouse = GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(DocObject);
	
	If ThisIsDeliveryToOurWarehouse And DocObject.Property("Ref") And DocObject.Property("GoodsReceiptOption") Then
		AcceptanceParameters = GetAcceptanceParameters(DocObject, DocObject.GoodsReceiptOption, OrderInvoice_3);
	EndIf;
	
	If Not SetVisibilityOfDeliveryItems(FormItems, DocObject, OrderInvoice_3, AcceptanceParameters, ThisIsDeliveryToOurWarehouse) Then
		WhenReadingCreatingFillInListsOfRecipientSenderSAddressSelections(FormItems, DocObject);
		Return BackgroundJobResult;
	EndIf;
	
	SetAddressAvailabilityFillTimeLists(FormItems);
	
	If FillInCarriersInBackground Then
		
		If Not FormItems.Find("CarrierPartner") = Undefined Then
			
			CalculationProcedure_ = "GoodsDelivery.GetListOfCarriersInBackground";
			
			JobParameters = New Array;
			JobParameters.Add(FormItems.CarrierPartner.ChoiceList.UnloadValues());
			If DocObject <> Undefined Then
				JobParameters.Add(RecipientSender(DocObject).Value);
			Else
				JobParameters.Add(Undefined);
			EndIf;
			
			ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
			ExecutionParameters.WaitCompletion = 0;
			ExecutionParameters.RunInBackground = True;
			
			BackgroundJobResult = TimeConsumingOperations.ExecuteInBackground(
				CalculationProcedure_, JobParameters, ExecutionParameters);
			
		EndIf;
	
	Else
		
		FillInCarrierSelectionList(FormItems,DocObject);
		
	EndIf;
	
	DeliveryMethod = DocObject.DeliveryMethod;
	
	If DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress
		Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint Then
		FillInCarrierAddressSelectionList(FormItems, DocObject);
	EndIf;
	FillInListsForSelectingRecipientSenderAddresses(FormItems, DocObject);
	UseTransportationJobsForDeliveryAccountingByCarriers = GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
	If FormItems.Find("DeliveryPages") <> Undefined Then
		
		DeliveryIsDefinedInContract = False;
		
		If ThisIsDeliveryToOurWarehouse Then
			OrderByAgreement    = ThisIsOrderByAgreement(DocObject, AcceptanceParameters);
			DeliveryIsDefinedInContract = DeliveryIsDefinedInContract(DocObject);
			If DeliveryIsDefinedInContract And DocObject.Property("Contract") And FormItems.Find("DeliverySummaryGroup") <> Undefined Then
				DeliveryMethod = Common.ObjectAttributeValue(DocObject.Contract, "DeliveryMethod");
				SummaryInformation = GenerateSummaryDeliveryInformation(DocObject.Contract);
				GoodsDeliveryClientServer.ClearDeliveryDetails(FormItems, DocObject);
			ElsIf OrderByAgreement And DocObject.Property("Terms") And FormItems.Find("DeliverySummaryGroup") <> Undefined Then
				DeliveryMethod = Common.ObjectAttributeValue(DocObject.Terms, "DeliveryMethod");
				SummaryInformation = GenerateSummaryDeliveryInformation(DocObject.Terms);
				GoodsDeliveryClientServer.ClearDeliveryDetails(FormItems, DocObject);
			EndIf;
		EndIf;
		
		ThisIsContractAgreement = TypeOf(DocObject.Ref) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(DocObject.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors");
		
		OrderUnderAgreement = Not ThisIsContractAgreement And DeliveryIsDefinedInContract;
		
		GoodsDeliveryClientServer.SetDeliveryPage(FormItems,
			DeliveryMethod,
			UseTransportationJobsForDeliveryAccountingByCarriers,
			OrderByAgreement,
			OrderUnderAgreement);
		If FormItems.Find("PageDeliveryByCarrier") <> Undefined Then
			FormItems.SpecialConditionsOfCarriageDeliveryByTheCarrier.Visible         = UseTransportationJobsForDeliveryAccountingByCarriers;
			FormItems.SpecialConditionsOfCarriageDescriptionDeliveryByCarrier.Visible = UseTransportationJobsForDeliveryAccountingByCarriers;
		EndIf;
	EndIf;
	
	SpecialConditionsOfCarriageAndAccessibility(FormItems, DocObject);
	
	Return BackgroundJobResult;
	
EndFunction

// Depending on the FO edit
//	delivery address, the text Editing flag is set for delivery address elements in the directory.
//
// Parameters:
//	FormItems - FormAllItems - form elements for which properties are changed.
//
Procedure SetAvailabilityOfDeliveryAddresses(FormItems) Export
	
	EditingAllowed = Not GetFunctionalOption("EditDeliveryAddressesOnlyInDialogBox");
	If EditingAllowed Then
		Return;
	EndIf;
	For Each FormItem In FormItems Do
		If TypeOf(FormItem) = Type("FormField")
		 And FormItem.Type = FormFieldType.InputField
		 And StrFind(Lower(FormItem.Name), Lower("Address")) > 0 Then
			FormItem.TextEdit = EditingAllowed;
			FormItem.ClearButton = True;
		EndIf;
	EndDo;
		
EndProcedure

// Depending on the FO edit
//	delivery address, the text Editing flag is set for delivery address items in the directory And the selection list is filled in.
//
// Parameters:
//	FormItems - FormAllItems - form elements for which properties are changed.
//
Procedure SetAddressAvailabilityFillTimeLists(FormItems) Export
	
	EditingAllowed = Not GetFunctionalOption("EditDeliveryAddressesOnlyInDialogBox");
	If FormItems.Find("DeliveryPage") <> Undefined Then
		ElementsToCrawl = FormItems.DeliveryPage.ChildItems;
	Else
		ElementsToCrawl = FormItems;
	EndIf;
	
	RecursivelySetAddressAvailabilityFillTimeLists(ElementsToCrawl, EditingAllowed);
	
EndProcedure

// Returns parameters for filling in delivery details
// 
// Returns:
//  Structure - with a key:
//  * ClearDeliveryDetails - Boolean - initialize delivery Attributes,
//  * SetDeliveryMethod - Boolean - set the delivery method based on statistics,
//  * SetDeliveryAddress - Boolean - set the delivery address from the selection list,
//  * SourceOfStatistics - DocumentManager, Undefined - document managers
//  from which statistics will be extracted for filling in delivery details.
//
Function ParametersForFillingInBankingDetails() Export
	
	FillParameters = New Structure();
	FillParameters.Insert("ClearDeliveryDetails", True);
	FillParameters.Insert("SetDeliveryMethod", True);
	FillParameters.Insert("SetDeliveryAddress", True);
	FillParameters.Insert("SourceOfStatistics", Undefined);
	
	Return FillParameters;
	
EndFunction

// Fills in the delivery details depending on the form element that changes are made to.
//
// Parameters:
//	FormItems - FormAllItems - all Form elements in which changes are made
//	FormItemName - String - name of the Form element where the changes occurred
//	DocObject - FormDataStructure - the object whose Attributes are used when filling in
//	FillParameters - See ParametersForFillingInBankingDetails
//
Procedure FillInDeliveryDetails(FormItems, FormItemName, DocObject, FillParameters = Undefined) Export
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		If DocObject.Property("Ref") Then
			
			ObjectValueType = TypeOf(DocObject.Ref);
			
			NameOfAddressElement = "";
			
			If ObjectValueType = Type("DocumentRef.SalesOrder") Then
				
				If DocObject.Property("CreateSalesOrder")
					Or (FormItemName = "Partner"
						And Not DocObject.Partner.IsEmpty()
						And (Not DocObject.DeliveryIsRequired))
					Or (DocObject.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows
						And DocObject.DeliveryIsRequired) Then
					
					NameOfAddressElement = "RecipientDeliveryAddress";
					
				EndIf;
				
			EndIf;
			
			If ObjectValueType = Type("DocumentRef.CustomerInvoice") Then
				
				If (FormItemName = "Partner"
						Or FormItemName = "GoodsRecipient")
					And Not DocObject.Partner.IsEmpty()
					And Not DocObject.DeliveryIsRequired Then
					
					NameOfAddressElement = "RecipientDeliveryAddress";
					
				EndIf;
				
			EndIf;
			
			If ObjectValueType = Type("DocumentRef.GoodsShipmentToCustomer")
				Or ObjectValueType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
				Or ObjectValueType = Type("DocumentRef.GoodsShipmentFromStorage")
				
				
				Or ObjectValueType = Type("DocumentRef.TransferOfGoodsToBailee") Then
				
				If FormItemName = "Partner"
					And Not DocObject.Partner.IsEmpty() Then
					
					NameOfAddressElement = "RecipientDeliveryAddress";
					
				EndIf;
				
			EndIf;
			
			If Not IsBlankString(NameOfAddressElement) Then
				
				FillInListsForSelectingRecipientSenderAddresses(FormItems, DocObject, True);
				
				AddressItem = FormItems[NameOfAddressElement]; // FormField, FormFieldExtensionForATextBox
				If AddressItem.ChoiceList.Count() > 0 Then
					
					FirstStructureInList = AddressItem.ChoiceList[0].Value; // Structure
					DocObject.DeliveryAddress = FirstStructureInList.DeliveryAddress;
					DocObject.DeliveryAddressValue = FirstStructureInList.DeliveryAddressValue;
					DocObject.DeliveryAddressFieldValues = FirstStructureInList.DeliveryAddressFieldValues;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	RecipientSender = RecipientSender(DocObject);
	
	If FormItemName = RecipientSender.FieldName Then
		
		WhenChangingSenderSDestination(FormItems, DocObject, FillParameters);
		
	ElsIf StrFind(FormItemName,"GoodsRecipient") > 0 Then
		
		If FillParameters = Undefined Then
			FillParameters = ParametersForFillingInBankingDetails();
			FillParameters.ClearDeliveryDetails = False;
			FillParameters.SetDeliveryMethod = False;
			FillParameters.SetDeliveryAddress = False;
		EndIf;
		
		WhenChangingSenderSDestination(FormItems, DocObject, FillParameters);
		
	Else
		
		If StrFind(FormItemName, "DeliveryMethod") > 0
		 Or StrFind(FormItemName, "TransferLocation") > 0 Then
			
			WhenYouChangeDeliveryMethod(FormItems, DocObject);
			
		ElsIf StrFind(FormItemName, "CarrierPartner") > 0 Then
			
			WhenChangingCarrier(FormItems, DocObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Performs the necessary actions when changing the delivery method in delivery orders,
//	fills in the selection lists, delivery details, and configures the form elements.
//
// Parameters:
//  FormItems - FormAllItems - elements of the form where changes are made,
//	DocObject - FormDataStructure, CatalogObject - the object whose details are used for filling in.
//
Procedure WhenYouChangeDeliveryMethod(FormItems, DocObject) Export
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		Return
	EndIf;
	
	ThisIsDeliveryToOurWarehouse = GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(DocObject.Ref);
	
	DeliveryDetails_ = DeliveryDetails_(DocObject);
	
	AdditionalInfoChangedByUser = GoodsDeliveryClientServer.AdditionalInfoChangedByUser(FormItems, DocObject);
	
	FillInDetailsOfDeliveryMethod(FormItems, DeliveryDetails_, AdditionalInfoChangedByUser);
	
	If (DeliveryDetails_.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress
			Or DeliveryDetails_.DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint)
		And ValueIsFilled(DeliveryDetails_.CarrierPartner) Then
		FillInCarrierAddressSelectionList(FormItems, DeliveryDetails_);
		FillInCarrierDetails(FormItems, DeliveryDetails_, AdditionalInfoChangedByUser);
	EndIf;
	
	If DeliveryDetails_.DeliveryMethod = Enums.TransportMethods.ToCustomerByCourier Then
		
		DocumentDate = DocObject.Date;
		If DocObject.Date - BegOfDay(DocObject.Date) = 0 Then
			DocumentDate = CurrentSessionDate();
		EndIf;
		
		DateOfShipment = DocumentDate;
		
		If (TypeOf(DocObject) = Type("FormDataStructure")
			Or TypeOf(DocObject) = Type("Structure")) Then
			
			If DocObject.Property("DateOfShipment") Then
				
				If ValueIsFilled(DocObject.DateOfShipment) Then
					DateOfShipment = DocObject.DateOfShipment;
				EndIf;
				
			EndIf;
			
		ElsIf Common.HasObjectAttribute("DateOfShipment", DocObject.Metadata()) Then
			
			If ValueIsFilled(DocObject.DateOfShipment) Then
				DateOfShipment = DocObject.DateOfShipment;
			EndIf;
			
		EndIf;
		
		WarehouseSettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(DocObject.Warehouse, DocumentDate);
		
		If WarehouseSettings <> Undefined 
			And WarehouseSettings.StandardOrderDeliveryTime > 0 
			And BegOfDay(DateOfShipment) = BegOfDay(DocumentDate) Then
			
			DeliveryDetails_.DeliveryTimeFrom = DocumentDate;
			DeliveryDetails_.DeliveryTimeTo = DocumentDate + WarehouseSettings.StandardOrderDeliveryTime*60;
			
		EndIf;
		
	EndIf;
	
	FillPropertyValues(DocObject, DeliveryDetails_);
	
	ThisIsContractAgreement = TypeOf(DocObject.Ref) = Type("CatalogRef.CounterpartyContracts")
		Or TypeOf(DocObject.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors");
	
	If FormItems.Find("DeliveryPages") <> Undefined Then
		OrderByAgreement = ThisIsDeliveryToOurWarehouse And ThisIsOrderByAgreement(DocObject);
		DeliveryIsDefinedInContract = ThisIsDeliveryToOurWarehouse And DeliveryIsDefinedInContract(DocObject);
		
		OrderUnderAgreement = Not ThisIsContractAgreement And DeliveryIsDefinedInContract;
		
		GoodsDeliveryClientServer.SetDeliveryPage(FormItems,
			DocObject.DeliveryMethod,
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"),
			OrderByAgreement,
			OrderUnderAgreement);
	EndIf;
	
	SpecialConditionsOfCarriageAndAccessibility(FormItems, DocObject);
	
EndProcedure

// Adds delivery details to the details Folder structure, depending on the delivery method
// .it is used when entering Sales of goods and services based on customer Orders.
//
// Parameters:
//	HeaderAttributes - Structure - the structure to which you add details related to the delivery;
//	SelectionHeaderDetails - QueryResultSelection - a selection from the query results that contains 
//		delivery data.
//
Procedure AddDeliveryDetailsToFillInDetails(HeaderAttributes,SelectionHeaderDetails) Export
	
	HeaderAttributes.Insert("DeliveryMethod", SelectionHeaderDetails.DeliveryMethod);
	If SelectionHeaderDetails.DeliveryMethod <> Enums.TransportMethods.SelfPickup 
	 Or ValueIsFilled(SelectionHeaderDetails.DeliveryAddress) Then //we inherit if the delivery address is filled in
		
		HeaderAttributes.Insert("DeliveryAddress", SelectionHeaderDetails.DeliveryAddress);
		HeaderAttributes.Insert("DeliveryAddressFieldValues", SelectionHeaderDetails.DeliveryAddressFieldValues);
		
		ThereIsPropertyOfAddressValue = CommonClientServer.HasAttributeOrObjectProperty(
			SelectionHeaderDetails,
			"DeliveryAddressValue");
			
		If ThereIsPropertyOfAddressValue Then
			DeliveryAddressValue = SelectionHeaderDetails.DeliveryAddressValue; // String
		Else
			DeliveryAddressValue = "";
		EndIf;
		
		HeaderAttributes.Insert("DeliveryAddressValue", DeliveryAddressValue);
		
		If SelectionHeaderDetails.DeliveryMethod = Enums.TransportMethods.ToCustomer
			Or SelectionHeaderDetails.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress Then
			HeaderAttributes.Insert("DeliveryZone", SelectionHeaderDetails.DeliveryZone);
			HeaderAttributes.Insert("DeliveryTimeFrom", SelectionHeaderDetails.DeliveryTimeFrom);
			HeaderAttributes.Insert("DeliveryTimeTo", SelectionHeaderDetails.DeliveryTimeTo);
			HeaderAttributes.Insert("AdditionalDeliveryInformation", SelectionHeaderDetails.AdditionalDeliveryInformation);
		EndIf;
		
		If SelectionHeaderDetails.DeliveryMethod = Enums.TransportMethods.ByCarrier
		 Or SelectionHeaderDetails.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress Then
			HeaderAttributes.Insert("CarrierPartner",                     SelectionHeaderDetails.CarrierPartner);
			HeaderAttributes.Insert("AdditionalDeliveryInformation",    SelectionHeaderDetails.AdditionalDeliveryInformation);
			If SelectionHeaderDetails.CarrierPartner <> Catalogs.Partners.EmptyRef()
					And SelectionHeaderDetails.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress Then
				HeaderAttributes.Insert("DeliveryAddressOfCarrier",              SelectionHeaderDetails.DeliveryAddressOfCarrier);
				HeaderAttributes.Insert("DeliveryAddressOfCarrierFieldValues", SelectionHeaderDetails.DeliveryAddressOfCarrierFieldValues);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// When you change the "by orders" flag in the invoice, it changes the visibility of delivery controls and changes the delivery method.
//
// Parameters:
//	FormItems		 - FormItems			- all form elements;
//	DocObject			 - DocumentObject			- document where changes are made;
//	InvoiceForOrders	 - Boolean					- True-the document is an invoice for orders.
//
Procedure WhenChangingFlagForOrders(FormItems, DocObject, InvoiceForOrders) Export
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		Return;
	EndIf;
	
	If InvoiceForOrders Then
		If GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers")
			Or DocObject.DeliveryMethod <> Enums.TransportMethods.ByCarrier Then
			FillPropertyValues(DocObject, GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails(DocObject));
		EndIf;
		SetVisibilityOfDeliveryItems(FormItems, DocObject, InvoiceForOrders);
	Else
		WhenReadingCreatingOrdersOnServer(FormItems, DocObject, InvoiceForOrders);
	EndIf;
	
EndProcedure

// Selects the values of the last delivery details for the recipient or partner from the delivery Tasks.
// Parameters:
//	RecipientSender - CatalogRef.Partners, CatalogRef.Warehouses - optional if the Carrier is specified,
//	Carrier - CatalogRef.Partners - optional if the recipient is specified.
//
// Returns:
//	ValueTable - contains the last three sets of delivery Attributes for the Partner or Carrier.
//		Columns:
//		Delivery addresss,
//		Delivery addressreferences,
//		Delivery addressreferences,
//		Delivery zones,
//		Vremyaas,
//		Paseo,
//		Additional information.
//
Function LastDeliveryDetailsFromTasks(RecipientSender = Undefined, Carrier = Undefined) Export
	
	QueryText =
	"SELECT
	|	TransportationTask.LineNumber,
	|	TransportationTask.Ref.Date,
	|	TransportationTask.ConnectionKey,
	|	TransportationTask.TimeFrom,
	|	TransportationTask.TimeTo,
	|	TransportationTask.AdditionalInformation,
	|	TaskForTransportationRoute.Address,
	|	TaskForTransportationRoute.AddressValue,
	|	TaskForTransportationRoute.FieldValueAddress
	|INTO VT_TaskForStringTransportation
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|		INNER JOIN Document.TransportationJob.Route AS TaskForTransportationRoute
	|		ON TransportationTask.Ref = TaskForTransportationRoute.Ref
	|			AND TransportationTask.ConnectionKey = TaskForTransportationRoute.ConnectionKey
	|WHERE
	|	TransportationTask.Ref.Posted
	|	AND (TransportationTask.RecipientSender = &RecipientSender
	|			OR &RecipientSender = UNDEFINED)
	|	AND (TransportationTask.Carrier = &Carrier
	|			OR &Carrier = UNDEFINED
	|				AND TransportationTask.Carrier = VALUE(Catalog.Partners.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 3
	|	VT_TaskForStringTransportation.Address AS Address,
	|	MAX(VT_TaskForStringTransportation.Date) AS Date
	|INTO TT_RecentAddresses
	|FROM
	|	VT_TaskForStringTransportation AS VT_TaskForStringTransportation
	|WHERE
	|	VT_TaskForStringTransportation.Address <> """"
	|
	|GROUP BY
	|	VT_TaskForStringTransportation.Address
	|
	|ORDER BY
	|	MAX(VT_TaskForStringTransportation.Date) DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RecentAddresses.Address,
	|	TaskForTransportationRoute.Zone,
	|	TaskForTransportationRoute.Ref.Date
	|INTO VT_RoutesWithNecessaryAddresses
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN Document.TransportationJob.Route AS TaskForTransportationRoute
	|		ON TT_RecentAddresses.Address = TaskForTransportationRoute.Address
	|WHERE
	|	TaskForTransportationRoute.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RecentAddresses.Address,
	|	MAX(VT_RoutesWithNecessaryAddresses.Date) AS Date
	|INTO VT_DatesOfLastZonesByAddress
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN VT_RoutesWithNecessaryAddresses AS VT_RoutesWithNecessaryAddresses
	|		ON TT_RecentAddresses.Address = VT_RoutesWithNecessaryAddresses.Address
	|
	|GROUP BY
	|	TT_RecentAddresses.Address
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(VT_RoutesWithNecessaryAddresses.Zone) AS Zone,
	|	VT_DatesOfLastZonesByAddress.Address
	|INTO VT_LastZonesByAddress
	|FROM
	|	VT_RoutesWithNecessaryAddresses AS VT_RoutesWithNecessaryAddresses
	|		INNER JOIN VT_DatesOfLastZonesByAddress AS VT_DatesOfLastZonesByAddress
	|		ON (VT_DatesOfLastZonesByAddress.Address = VT_RoutesWithNecessaryAddresses.Address)
	|			AND (VT_DatesOfLastZonesByAddress.Date = VT_RoutesWithNecessaryAddresses.Date)
	|
	|GROUP BY
	|	VT_DatesOfLastZonesByAddress.Address
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RecentAddresses.Address,
	|	MAX(VT_TaskForStringTransportation.ConnectionKey) AS ConnectionKey
	|INTO VT_LastAddressesCommunicationKeys
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN VT_TaskForStringTransportation AS VT_TaskForStringTransportation
	|		ON (VT_TaskForStringTransportation.Address = TT_RecentAddresses.Address)
	|			AND (VT_TaskForStringTransportation.Date = TT_RecentAddresses.Date)
	|
	|GROUP BY
	|	TT_RecentAddresses.Address
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VT_LastAddressesCommunicationKeys.ConnectionKey,
	|	MAX(VT_TaskForStringTransportation.LineNumber) AS LineNumber
	|INTO VT_LastAddressesCommunicationKeysLineNumbers
	|FROM
	|	VT_LastAddressesCommunicationKeys AS VT_LastAddressesCommunicationKeys
	|		INNER JOIN VT_TaskForStringTransportation AS VT_TaskForStringTransportation
	|		ON (VT_TaskForStringTransportation.ConnectionKey = VT_LastAddressesCommunicationKeys.ConnectionKey)
	|
	|GROUP BY
	|	VT_LastAddressesCommunicationKeys.Address,
	|	VT_LastAddressesCommunicationKeys.ConnectionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VT_TaskForStringTransportation.Address              AS DeliveryAddress,
	|	VT_TaskForStringTransportation.AddressValue      AS DeliveryAddressValue,
	|	VT_TaskForStringTransportation.FieldValueAddress AS DeliveryAddressFieldValues,
	|	VT_LastZonesByAddress.Zone                 AS DeliveryZone,
	|	VT_TaskForStringTransportation.TimeFrom             AS DeliveryTimeFrom,
	|	VT_TaskForStringTransportation.TimeTo            AS DeliveryTimeTo,
	|	VT_TaskForStringTransportation.AdditionalInformation AS AdditionalDeliveryInformation
	|FROM
	|	VT_TaskForStringTransportation AS VT_TaskForStringTransportation
	|		INNER JOIN VT_LastAddressesCommunicationKeysLineNumbers AS VT_LastAddressesCommunicationKeysLineNumbers
	|		ON VT_TaskForStringTransportation.ConnectionKey = VT_LastAddressesCommunicationKeysLineNumbers.ConnectionKey
	|			AND VT_TaskForStringTransportation.LineNumber = VT_LastAddressesCommunicationKeysLineNumbers.LineNumber
	|		INNER JOIN VT_LastZonesByAddress AS VT_LastZonesByAddress
	|		ON (VT_LastZonesByAddress.Address = VT_TaskForStringTransportation.Address)
	|
	|WHERE
	|	CAST(VT_TaskForStringTransportation.FieldValueAddress AS STRING(10)) = """"
	|	OR
	|	VT_TaskForStringTransportation.FieldValueAddress LIKE ""%< / Contact information>""
	|	OR
	|	VT_TaskForStringTransportation.AddressValue LIKE ""%}""
	|
	|ORDER BY
	|	VT_TaskForStringTransportation.Date DESC,
	|	VT_TaskForStringTransportation.Address";
	
	Query = New Query(QueryText);
	Query.SetParameter("RecipientSender", RecipientSender);
	Query.SetParameter("Carrier", Carrier);
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Return Result;
	
EndFunction

// Returns the order of delivery by recipient from the transportation task.
// If the recipient is mentioned several times, the number of the first item is taken,
// if the recipient is not in the task, "?" is written instead of the item.
//
// Parameters:
//	TransportationJob	 - DocumentRef.TransportationJob - link to the transport task document;
//	Recipient			 - DefinedType.SenderRecipientOfDelivery - consignee.
//
// Returns:
//	String - the order of delivery in the format "%of the number of points% of %of the number of points%".
//
Function DeliveryOrderInTransportOrder(TransportationJob, Recipient) Export
	
	If Not GoodsDeliveryClientServer.UsedDelivery20() Then
		Return "";
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(TaskForTransportationRoute.LineNumber) AS LineNumber,
	|	TaskForTransportationRoute.Ref AS Ref
	|INTO PointNumber
	|FROM
	|	Document.TransportationJob.Route AS TaskForTransportationRoute
	|		INNER JOIN Document.TransportationJob.References AS TransportationTask
	|		ON TaskForTransportationRoute.Ref = TransportationTask.Ref
	|			AND TaskForTransportationRoute.ConnectionKey = TransportationTask.ConnectionKey
	|WHERE
	|	TaskForTransportationRoute.Ref = &TransportationJob
	|	AND TransportationTask.Ref = &TransportationJob
	|	AND TransportationTask.RecipientSender = &Recipient
	|
	|GROUP BY
	|	TaskForTransportationRoute.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransportationJob.PointsNumber,
	|	ISNULL(PointNumber.LineNumber, 0) AS PointNumber
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|		LEFT JOIN PointNumber AS PointNumber
	|		ON PointNumber.Ref = TransportationJob.Ref
	|WHERE
	|	TransportationJob.Ref = &TransportationJob";
	
	Query.SetParameter("TransportationJob", TransportationJob);
	Query.SetParameter("Recipient", Recipient);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		DeliveryProcedure = NStr("vi = '%PointNumber% từ %PointsNumber%';
								|ru = '%PointNumber% из %PointsNumber%';
								|en = '%PointNumber% from %PointsNumber%'; fa = '%PointNumber% from %PointsNumber%';
								|it = '%PointNumber% di %PointsNumber%';
								|pl = '%PointNumber% z %PointsNumber%';
								|tr = '%PointsNumber%''dan %PointNumber%'");	
		DeliveryProcedure = StrReplace(DeliveryProcedure, "%PointNumber%", ?(Selection.PointNumber = 0, "?", Format(Selection.PointNumber,"ND=2; NLZ=")));
		DeliveryProcedure = StrReplace(DeliveryProcedure, "%PointsNumber%", Format(Selection.PointsNumber,"ND=2; NLZ="));
		
	Else
		
		DeliveryProcedure = "";
		
	EndIf;
	
	Return DeliveryProcedure;
	
EndFunction

// Returns the coefficient value from a constant, checks and returns a message if it is empty.
// 
// Returns:
//  Number - the value of the coefficient.
//
Function TonConversionFactor() Export
	
	Return ProductsServer.TonConversionFactor(Constants.UnitOfMeasureForWeight.Get());
	
EndFunction

// Returns the coefficient value from a constant, checks and returns a message if it is empty.
// Returns:
//		Number
//
Function CubicMeterConversionFactor() Export
	
	Return ProductsServer.CubicMeterConversionFactor(Constants.UnitOfMeasureForVolume.Get());
	
EndFunction

// Resets the list of delivery orders on the form.
//
// Parameters:
//	Form - ClientApplicationForm - form to update the list of delivery orders for;
//	UpdatedOrders - ValueTable, Undefined - filter for partial re-filling of the list only 
//		for orders passed in the table.
//
Procedure UpdateListOfDeliveryOrders(Form, UpdatedOrders = Undefined) Export
	
	AcceptableDeviationPercentage = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	DeliveryReferences 		= Form.DeliveryReferences;
	ReferenceGoodsToDeliver = Form.ReferenceGoodsToDeliver;
	FilterByAssigneeType 	= Form.FilterByAssigneeType;
	Zone 						= Form.Zone; // CatalogRef.DeliveryZones
	Warehouse 						= Form.Warehouse; // CatalogRef.Warehouses
	DateOfOrders_ 			= Form.DateOfOrders_; // Date
	AreaGroupOrEmpty 		= Not ValueIsFilled(Zone) Or Common.ObjectAttributeValue(Zone,"IsFolder");
	
	SelectiveUpdating = (UpdatedOrders <> Undefined);
	
	WeightVolumeOfOrdersByDate = New ValueTable;
	WeightVolumeOfOrdersByDate.Columns.Add("Date", New TypeDescription("Date"));
	WeightVolumeOfOrdersByDate.Columns.Add("Weight", Common.TypeDescriptionNumber(15,3));
	WeightVolumeOfOrdersByDate.Columns.Add("Count", Common.TypeDescriptionNumber(15,3));
	WeightVolumeOfOrdersByDate.Columns.Add("VolumeM3", Common.TypeDescriptionNumber(18,6));
	WeightVolumeOfOrdersByDate.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	WeightVolumeOfOrdersByDate.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	WeightVolumeOfOrdersByDate.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	WeightVolumeOfOrdersByDate.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	
	CacheOfAddedStrings = New Array;
	
	CollectionOfOrders = DeliveryReferences.GetItems();
	WeightVolume = New Structure;
	
	If Not SelectiveUpdating Then
		WeightVolume.Insert("TotalWeight_", 0);
		WeightVolume.Insert("TotalVolume",0);
		CollectionOfOrders.Clear();
		ReferenceGoodsToDeliver.Clear();
	Else
		TheStructureOfTheSearch = New Structure("Warehouse, ReferenceOrder");
		
		For Each Page1 In UpdatedOrders Do
			
			// When updating selectively, you first need to delete the lines of the updated orders,
			// for this we will use the list of goods by orders.
			PreviousID = Undefined;
			
			FillPropertyValues(TheStructureOfTheSearch, Page1);
			
			FoundRows = ReferenceGoodsToDeliver.FindRows(TheStructureOfTheSearch);
			For Each LineProducts_ In FoundRows Do
				Id = LineProducts_.IDInReferenceTree;
				If PreviousID = Id
					Or Not ValueIsFilled(Id) Then
					Continue;
				EndIf;
				CommandLine_ = DeliveryReferences.FindByID(Id);
				If CommandLine_ <> Undefined Then
					If AreaGroupOrEmpty Then
						CurBranch_ = CommandLine_.GetParent();
						CollectionCurBranch = CurBranch_.GetItems();
						// If we delete the last element in the branch, we delete the parent.
						If CollectionCurBranch.Count() = 1 Then
							CollectionOfOrders.Delete(CurBranch_);
						Else
							CurBranch_.Weight = CurBranch_.Weight - CommandLine_.Weight;
							CurBranch_.VolumeM3 = CurBranch_.VolumeM3 - CommandLine_.VolumeM3;
							CollectionCurBranch.Delete(CommandLine_);
						EndIf;
					Else
						CollectionOfOrders.Delete(CommandLine_);
					EndIf;
				EndIf;
				ReferenceGoodsToDeliver.Delete(LineProducts_);
			EndDo;
		EndDo;
	EndIf;
	
	JobStructure = New Structure("TransportationJob", Undefined);
	FillPropertyValues(JobStructure, Form);
	
	Query = New Query;
	OutgoingDelivery = Form.DeliveryKind = Enums.DeliveryKinds.FromWarehouse;
	
	ThereIsOrderWarehouseForShipment      = False;
	ThereIsWarehouseThatIsNotOrderForShipment    = False;
	ThereIsOrderForReceiptWarehouse   = False;
	ThereIsWarehouseThatIsNotOrderForReceipt = False;
	
	If OutgoingDelivery Then
		ThereIsOrderWarehouseForShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(Warehouse);
		ThereIsWarehouseThatIsNotOrderForShipment = WarehousesServer.ThereIsWarehouseThatIsNotOrderForShipment(Warehouse);
	Else
		ThereIsOrderForReceiptWarehouse = WarehousesServer.ThereIsOrderForReceiptWarehouse(Warehouse);
		ThereIsWarehouseThatIsNotOrderForReceipt = WarehousesServer.ThereIsWarehouseThatIsNotOrderForReceipt(Warehouse);
	EndIf;
	
	QueryText = "";
	If OutgoingDelivery Then
		
		QueryText = QueryTextDeliveryReferences(SelectiveUpdating,
			ThereIsOrderWarehouseForShipment,
			ThereIsWarehouseThatIsNotOrderForShipment,
			True);
		
		Query.SetParameter("MethodsOfDeliveryByOurForcesToRecipient", MethodsOfDeliveryByOurForcesToRecipient());
		Query.SetParameter("MethodsOfDeliveryByCarrierToRecipient", MethodsOfDeliveryByCarrierToRecipient());
		
	Else
		
		QueryText = QueryTextDeliveryReferences(SelectiveUpdating,
			ThereIsOrderForReceiptWarehouse,
			ThereIsWarehouseThatIsNotOrderForReceipt,
			False);
		
		Query.SetParameter("FilterDate", BegOfDay(CurrentSessionDate()));
		Query.SetParameter("MethodsOfDeliveryByOurForcesFromSender", MethodsOfDeliveryByOurForcesFromSender());
		Query.SetParameter("ShippingMethodsByCarrierFromSender", ShippingMethodsByCarrierFromSender());
	
	EndIf;
	
	Query.Text = QueryText;
	
	NoZoneSelection = Zone = Catalogs.DeliveryZones.EmptyRef();
	
	Query.SetParameter("Zone",                              Zone);
	Query.SetParameter("Warehouse",                             Warehouse);
	Query.SetParameter("NoZoneSelection",                   NoZoneSelection);
	Query.SetParameter("UpdatedOrders",           UpdatedOrders);
	Query.SetParameter("TaskForTransportationSelection",          JobStructure.TransportationJob);
	Query.SetParameter("TransportTaskEmptyLink",    Documents.TransportationJob.EmptyRef());
	Query.SetParameter("TaskStatusClosed",              Enums.StatusesOfTransportationJobs.Closed);
	Query.SetParameter("FilterByAssigneeType",           FilterByAssigneeType);
	Query.SetParameter("CurrentSessionDate",                 CurrentSessionDate());
	
	Package = Query.ExecuteBatch();
	QueryResult = Package[Package.UBound()-1]; // QueryResult
	RegisteredRecordsTowardsDistribution = QueryResult.Unload();
	
	MotionSelectionFields = New Array(); // Array of String
	MotionSelectionFields.Add("ReferenceOrder");
	MotionSelectionFields.Add("Warehouse");
	MotionSelectionFields.Add("Products");
	MotionSelectionFields.Add("Characteristic");
	MotionSelectionFields.Add("Purpose");
	If RegisteredRecordsTowardsDistribution.Columns.Find("Series") <> Undefined Then
		MotionSelectionFields.Add("Series");
	EndIf;
	SelectionFieldsAreAppliedToDistribution = StrConcat(MotionSelectionFields, ",");
	
	If OutgoingDelivery
		Or ThereIsOrderForReceiptWarehouse Then
		RegisteredRecordsTowardsDistribution.Indexes.Add(SelectionFieldsAreAppliedToDistribution);
	EndIf;
	
	QueryResult = Package[Package.UBound()]; // QueryResult
	Selection = QueryResult.Select();
	
	While Selection.NextByFieldValue("Zone") Do
		
		If SelectiveUpdating Then
			
		ElsIf AreaGroupOrEmpty Then
			CurBranch_ = CollectionOfOrders.Add();
			CurBranch_.Address = String(Selection.Zone);
			CurBranch_.Zone = Selection.Zone;
			CollectionCurBranch = CurBranch_.GetItems();
		Else
			CollectionCurBranch = CollectionOfOrders;
		EndIf;
		
		WeightByZone = 0;
		VolumeByZone = 0;
		
		While Selection.NextByFieldValue("ReferenceOrder") Do
			
			If SelectiveUpdating Then
				StructureZoneAddress = New Structure("Zone, Address");
				FillPropertyValues(StructureZoneAddress, Selection);
				InsertionPosition = GetPositionToInsert(DeliveryReferences, AreaGroupOrEmpty, StructureZoneAddress);
				If AreaGroupOrEmpty Then
					CurBranch_ = CollectionOfOrders[InsertionPosition.Zone];
					CollectionCurBranch = CurBranch_.GetItems();
				Else
					CollectionCurBranch = CollectionOfOrders;
				EndIf;
				InsertionPosition = InsertionPosition.ReferenceOrder;
			EndIf;
			
			If Selection.ReferenceKind = Type("DocumentRef.InstructionForShippingAgent") Then
				
				If ValueIsFilled(DateOfOrders_)
					And ValueIsFilled(Selection.Date)
					And BegOfDay(Selection.Date) > DateOfOrders_ Then
					Continue;
				EndIf;
				
				If SelectiveUpdating Then
					CommandLine_ = CollectionCurBranch.Insert(InsertionPosition);
					InsertionPosition = InsertionPosition + 1;
				Else
					CommandLine_ = CollectionCurBranch.Add();
				EndIf;
				FillPropertyValues(CommandLine_, Selection);
				CommandLine_.RecipientSenderPresentation = Selection.RecipientSender;
				CommandLine_.Time = GoodsDeliveryClientServer.PresentationOfDeliveryTime(Selection.TimeFrom, Selection.TimeTo);
				
				StringForStoringID = ReferenceGoodsToDeliver.Add();
				FillPropertyValues(StringForStoringID, Selection);
				StringForStoringID.IDInReferenceTree = CommandLine_.GetID();
				
				Continue;
				
			EndIf;
			
			While Selection.NextByFieldValue("Warehouse") Do
				
				Products = Undefined;
				Characteristic = Undefined;
				Purpose = Undefined;
				Series = Undefined;
				
				WeightVolumeOfOrdersByDate.Clear();
				CacheOfAddedStrings.Clear();
				ProductNeed = 0;
				CheckDeviation = False;
				
				While Selection.Next() Do
					
					If Products <> Selection.Products
					 Or Characteristic <> Selection.Characteristic
					 Or Purpose <> Selection.Purpose
					 Or Series <> Selection.Series Then
						// switched to another product
						
						Products = Selection.Products;
						Characteristic = Selection.Characteristic;
						Purpose = Selection.Purpose;
						Series = Selection.Series;
						
						If CheckDeviation Then
							AllowableVariance = AcceptableDeviationPercentage/100 * ProductNeed;
							// It is not necessary to output lines with a measured product if the balance for delivery has not exceeded the permissible deviation;
							For Each Page1 In CacheOfAddedStrings Do
								If Page1.Count <= AllowableVariance Then
									WeightVolumeOfOrdersByDate.Delete(Page1);
								EndIf;
							EndDo;
						EndIf;
						CacheOfAddedStrings.Clear();
						ProductNeed = 0;
						
						CheckDeviation = Selection.DimensionalUnitOfMeasurement And AcceptableDeviationPercentage > 0;
						
					EndIf;
					
					If OutgoingDelivery Then
						
						RemainsToAllocate = Selection.Count;
						
						FilterParameters = New Structure(SelectionFieldsAreAppliedToDistribution);
						FillPropertyValues(FilterParameters, Selection);
						DetailedData = RegisteredRecordsTowardsDistribution.FindRows(FilterParameters);
						For Each DetailedDataLine In DetailedData Do
							WriteOff_ = Min(RemainsToAllocate, DetailedDataLine.Count);
							RemainsToAllocate = RemainsToAllocate - WriteOff_;
							DetailedDataLine.Count = DetailedDataLine.Count - WriteOff_;
							
							If RemainsToAllocate = 0 Then
								Break;
							EndIf;
						EndDo;
						
						If RemainsToAllocate > 0 Then
							CurRowWeightVolume = WeightVolumeOfOrdersByDate.Add();
							FillPropertyValues(CurRowWeightVolume, Selection);
							CurRowWeightVolume.Count = RemainsToAllocate;
							CurRowWeightVolume.Weight = RemainsToAllocate * (Selection.Weight / Selection.Count);
							CurRowWeightVolume.VolumeM3 = RemainsToAllocate * (Selection.VolumeM3 / Selection.Count);
							
							CacheOfAddedStrings.Add(CurRowWeightVolume);
							ProductNeed = ProductNeed + RemainsToAllocate;
						EndIf;
						
					ElsIf Not ThereIsOrderForReceiptWarehouse Then
						
						CurRowWeightVolume = WeightVolumeOfOrdersByDate.Add();
						FillPropertyValues(CurRowWeightVolume, Selection);
						CacheOfAddedStrings.Add(CurRowWeightVolume);
						ProductNeed = ProductNeed + Selection.Count;
						
					Else
						
						FilterParameters = New Structure(SelectionFieldsAreAppliedToDistribution);
						FillPropertyValues(FilterParameters, Selection);
						DetailedData = RegisteredRecordsTowardsDistribution.FindRows(FilterParameters);
						
						RemainsToAllocate = Selection.Count;
						// Distribution of goods by receipt dates;
						For Each DetailedDataLine In DetailedData Do
							
							WriteOff_ = Min(RemainsToAllocate, DetailedDataLine.Count);
							RemainsToAllocate = RemainsToAllocate - WriteOff_;
							
							CurRowWeightVolume = WeightVolumeOfOrdersByDate.Add();
							FillPropertyValues(CurRowWeightVolume, Selection,,"Count,Weight,VolumeM3");
							CurRowWeightVolume.Date = DetailedDataLine.Period;
							CurRowWeightVolume.Count = WriteOff_;
							CurRowWeightVolume.Weight = WriteOff_ * DetailedDataLine.Weight / DetailedDataLine.Count;
							CurRowWeightVolume.VolumeM3 = WriteOff_ * DetailedDataLine.VolumeM3 / DetailedDataLine.Count;
							CacheOfAddedStrings.Add(CurRowWeightVolume);
							
							If RemainsToAllocate <= 0 Then
								Break;
							EndIf;
							
						EndDo;
						
						If RemainsToAllocate > 0 Then
							CurRowWeightVolume = WeightVolumeOfOrdersByDate.Add();
							FillPropertyValues(CurRowWeightVolume, Selection,,"Count,Weight,VolumeM3");
							CurRowWeightVolume.Date = BegOfDay(CurrentSessionDate());
							CurRowWeightVolume.Count = RemainsToAllocate;
							CurRowWeightVolume.Weight = RemainsToAllocate 	* Selection.Weight 	/ Selection.Count;
							CurRowWeightVolume.VolumeM3 = RemainsToAllocate 	* Selection.VolumeM3 / Selection.Count;
							CacheOfAddedStrings.Add(CurRowWeightVolume);
						EndIf;
						ProductNeed = ProductNeed + Selection.Count;
					EndIf;
				EndDo;
				
				// You need to check the last added product.;
				If CheckDeviation Then
					AllowableVariance = AcceptableDeviationPercentage/100 * ProductNeed;
					// It is not necessary to output lines with a measured product if the balance for delivery has not exceeded the permissible deviation;
					For Each Page1 In CacheOfAddedStrings Do
						If Page1.Count <= AllowableVariance Then
							WeightVolumeOfOrdersByDate.Delete(Page1);
						EndIf;
					EndDo;
				EndIf;
				
				WeightVolumeOfOrdersByDate.Sort("Date");
				
				CurrentDate = Undefined;
				
				For Each StringWeightVolumeDate In WeightVolumeOfOrdersByDate Do
					
					If ValueIsFilled(DateOfOrders_)
						And StringWeightVolumeDate.Date > DateOfOrders_ Then
						Break;
					EndIf;
					
					RowGoods = ReferenceGoodsToDeliver.Add();
					FillPropertyValues(RowGoods, Selection);
					FillPropertyValues(RowGoods, StringWeightVolumeDate);
					
					If CurrentDate <> StringWeightVolumeDate.Date Then
						
						CurrentDate = StringWeightVolumeDate.Date;
						
						If SelectiveUpdating Then
							CommandLine_ = CollectionCurBranch.Insert(InsertionPosition);
							InsertionPosition = InsertionPosition + 1;
						Else
							CommandLine_ = CollectionCurBranch.Add();
						EndIf;
						
						FillPropertyValues(CommandLine_, Selection);
						
						If CommandLine_.Property("DeliveryAddressFieldValues") Then
							CommandLine_.DeliveryAddressFieldValues = Selection.FieldValueAddress;
						EndIf;
						
						CommandLine_.Date = CurrentDate;
						CommandLine_.Weight = 0;
						CommandLine_.VolumeM3 = 0;
						
						CommandLine_.RecipientSenderPresentation = GoodsDeliveryClientServer.PresentationOfSenderSRecipient(
							Selection.RecipientSender, Selection.Carrier, Form.DeliveryKind);
						CommandLine_.Time = GoodsDeliveryClientServer.PresentationOfDeliveryTime(
							Selection.TimeFrom, Selection.TimeTo);
						
						IDInReferenceTree = CommandLine_.GetID();
						
					EndIf;
					
					RowGoods.IDInReferenceTree = IDInReferenceTree;
					
					CommandLine_.Weight = CommandLine_.Weight + StringWeightVolumeDate.Weight;
					CommandLine_.VolumeM3 = CommandLine_.VolumeM3 + StringWeightVolumeDate.VolumeM3;
					
					WeightByZone   = WeightByZone   + StringWeightVolumeDate.Weight;
					VolumeByZone = VolumeByZone + StringWeightVolumeDate.VolumeM3;
					
				EndDo;
				
			EndDo; // Warehouse
		EndDo; // ReferenceOrder
		
		If Not SelectiveUpdating Then
			WeightVolume.TotalWeight_ = WeightVolume.TotalWeight_ + WeightByZone;
			WeightVolume.TotalVolume = WeightVolume.TotalVolume  + VolumeByZone;
		EndIf;
		
		If AreaGroupOrEmpty Then
			
			If CollectionCurBranch.Count() = 0 Then
				CollectionOfOrders.Delete(CurBranch_);
			Else
				If SelectiveUpdating Then
					CurBranch_.Weight   = CurBranch_.Weight + WeightByZone;
					CurBranch_.VolumeM3 = CurBranch_.VolumeM3 + VolumeByZone;
				Else
					CurBranch_.Weight   = WeightByZone;
					CurBranch_.VolumeM3 = VolumeByZone;
				EndIf;
				CurBranch_.RowAppearance = 5;
				CurBranch_.Zone = Selection.Zone;
			EndIf;
		Else
			Break;
		EndIf;
		
	EndDo; // Zone
	
	FillPropertyValues(Form, WeightVolume);
	FillInSignsOfExecutionOfOrders(DeliveryReferences, AreaGroupOrEmpty);
	
EndProcedure

// Fills in the registration criteria in the delivery order tree.
// Parameters:
//	DeliveryReferences - FormDataTree - orders for delivery,
//  AreaGroupOrEmpty - Boolean - indicates that a group is set in the selection for the delivery zone or that the selection is not filled in.
//
Procedure FillInSignsOfExecutionOfOrders(DeliveryReferences, AreaGroupOrEmpty) Export
	
	TopRowsOfTree = DeliveryReferences.GetItems();
	If AreaGroupOrEmpty Then
		For Each DeliveryZoneLine In TopRowsOfTree Do
			FillInSignsOfExecutionOfOrdersLowerLevel(DeliveryZoneLine.GetItems())
		EndDo;
	Else
		FillInSignsOfExecutionOfOrdersLowerLevel(TopRowsOfTree)
	EndIf;
	
EndProcedure

// Resets the transport task according to the associated expenditure orders for goods.
//
// Parameters:
//  JobObject - DocumentObject.TransportationJob, FormDataStructure: See Document.TransportationJob.Form.DocumentForm.Object - document tasks for transportation;
//  GoodsToDeliver - FormDataCollection, Undefined - collection with data on delivered products.
// 
// Returns:
//  Boolean - a sign of correct overfilling.
//
Function ReCompleteTransportTaskForExpenseOrders(JobObject, GoodsToDeliver = Undefined) Export
	
	Query = New Query(TextOfRequestToFillInTransportationTaskForExpenseOrders());
	Query.SetParameter("Ref", JobObject.Ref);
	Query.SetParameter("TransportationTask", JobObject.References.Unload());
	Query.SetParameter("TaskForTransportationRoute", JobObject.Route.Unload());
	Query.SetParameter("PlanTripStartTime", JobObject.PlanTripStartTime);
	TransportMethods = New Array; // Array of EnumRef.TransportMethods
	TransportMethods.Add(Enums.TransportMethods.ByCarrierToAddress);
	TransportMethods.Add(Enums.TransportMethods.ToCustomer);
	TransportMethods.Add(Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany);
	If GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers") Then
		TransportMethods.Add(Enums.TransportMethods.ByCarrier);
	EndIf;
	Query.SetParameter("TransportMethods", TransportMethods);
	Query.SetParameter("DeliveryByCarrierToAddress", Enums.TransportMethods.ByCarrierToAddress);
	
	Result = Query.ExecuteBatch();
	UBound = Result.UBound();
	
	HasChanges = False;
	
	// changing
	Selection = Result[UBound-2].Select();
	While Selection.Next() Do
		Orders_Row = JobObject.References[Selection.LineNumber - 1];
		RouteString = JobObject.Route[Selection.RouteTheLineNumber - 1];
		RouteString.Weight = RouteString.Weight + (Selection.Weight - Orders_Row.Weight);
		RouteString.VolumeM3 = RouteString.VolumeM3 + (Selection.VolumeM3 - Orders_Row.VolumeM3);
		FillPropertyValues(Orders_Row, Selection);
		HasChanges = True;
	EndDo;
	
	// Deleting the order lines
	// The selection is ordered in descending order of the order line numbers.
	Selection = Result[UBound-4].Select();
	While Selection.Next() Do
		Orders_Row = JobObject.References[Selection.LineNumber - 1];
		RouteString = JobObject.Route[Selection.RouteTheLineNumber - 1];
		RouteString.Weight = RouteString.Weight - Orders_Row.Weight;
		RouteString.VolumeM3 = RouteString.VolumeM3 - Orders_Row.VolumeM3;
		JobObject.References.Delete(Selection.LineNumber - 1);
		HasChanges = True;
	EndDo;
	
	// Deleting route points
	// The selection is ordered in descending order of the route line numbers.
	Selection = Result[UBound-3].Select();
	While Selection.Next() Do
		JobObject.Route.Delete(Selection.RouteTheLineNumber - 1);
		HasChanges = True;
	EndDo;
	
	// Adding new ones
	Selection = Result[UBound-1].Select();
	While Selection.Next() Do
		Orders_Row = JobObject.References.Add();
		RouteString = AddEditItemByDeliveryDetails(JobObject.Route, Selection, JobObject.PlanTripStartTime);
		FillPropertyValues(Orders_Row, Selection);
		Orders_Row.ConnectionKey = RouteString.ConnectionKey;
		HasChanges = True;
	EndDo;
	
	TableGoodsForDelivery = Result[UBound].Unload();
	// We fill in the goods for delivery
	If GoodsToDeliver <> Undefined Then
		
		GoodsToDeliver.Load(TableGoodsForDelivery);
		
	Else
		
		JobObject.AdditionalProperties.Insert("GoodsToDeliver", TableGoodsForDelivery);
		
	EndIf;
	
	For Each Page1 In JobObject.References Do
		Page1.DeliveredInFull = False;
	EndDo;
	ThisAttributeIsDeliveredInFull(TableGoodsForDelivery, JobObject.References);
	
	Return HasChanges;
	
EndFunction

// Adds or changes the delivery point in accordance with the delivery details of the delivery order.
//
// Parameters:
//  RouteCollection	 - FormDataCollection - collection to add the item to;
//  DeliveryDetails_	 - Structure, QueryResultSelection, FormDataTreeItem	 - with properties:
//  	* Address - String - delivery address;
//  	* Weight - Number - cargo weight;
//  	* VolumeM3 - Number - cargo volume.
//  PlanTripStartTime	 - Date - scheduled start date of the flight.
// 
// Returns:
//  FormDataTreeItem, FormDataCollectionItem - line-delivery point. Contains including:
//  	* Ref - DocumentRef.TransportationJob
//
Function AddEditItemByDeliveryDetails(RouteCollection, DeliveryDetails_, PlanTripStartTime) Export
	
	AttributesStructure2 = New Structure("Address, DeliveryAddress, FieldValueAddress, Zone, DeliveryZone, AdditionalInformation, AdditionalDeliveryInformation, Weight, VolumeM3, TimeFrom, TimeTo");
	FillPropertyValues(AttributesStructure2, DeliveryDetails_);
	AttributesStructure2.Address = ?(ValueIsFilled(AttributesStructure2.DeliveryAddress),AttributesStructure2.DeliveryAddress, AttributesStructure2.Address);
	AttributesStructure2.Zone = ?(ValueIsFilled(AttributesStructure2.DeliveryZone),AttributesStructure2.DeliveryZone, AttributesStructure2.Zone);
	AttributesStructure2.AdditionalInformation = ?(ValueIsFilled(AttributesStructure2.AdditionalDeliveryInformation),AttributesStructure2.AdditionalDeliveryInformation, AttributesStructure2.AdditionalInformation);
	
	ComparisonAddress = Upper(TrimAll(AttributesStructure2.Address));
	ComparisonAddress = StrReplace(ComparisonAddress," ","");
	
	For Each RouteString In RouteCollection Do
		
		AddressAndRoute = StrReplace(Upper(TrimAll(RouteString.Address))," ","");
		
		If ComparisonAddress = AddressAndRoute Then
			
			RouteString.Weight = RouteString.Weight + AttributesStructure2.Weight;
			RouteString.VolumeM3 = RouteString.VolumeM3 + AttributesStructure2.VolumeM3;
			RouteString.AdditionalInformation = SupplementTextWithOrderAndAddInfo(RouteString.AdditionalInformation,
				AttributesStructure2.AdditionalInformation,DeliveryDetails_.ReferenceOrder);
			
			Return RouteString;
			
		EndIf;
		
	EndDo;
	
	RouteString = RouteCollection.Add();
	FillPropertyValues(RouteString, AttributesStructure2);
	RouteString.ConnectionKey = New UUID;
	
	RouteString.AdditionalInformation = SupplementTextWithOrderAndAddInfo(
		"", AttributesStructure2.AdditionalInformation,DeliveryDetails_.ReferenceOrder);
	
	If RouteCollection.Count() = 1 Then
		
		RouteString.TimeFrom = PlanTripStartTime;
		RouteString.TimeTo = RouteString.TimeFrom;
		
	Else
		
		RouteString.TimeFrom = RouteCollection[RouteCollection.IndexOf(RouteString) - 1].TimeTo;
		RouteString.TimeTo = RouteString.TimeFrom;
	
	EndIf;
	
	If TypeOf(RouteCollection) = Type("FormDataCollection") Then
		RouteString.TimeFromWithoutDate  = GoodsDeliveryClientServer.TimeWithoutDate(RouteString.TimeFrom);
		RouteString.TimeToWithoutDate = GoodsDeliveryClientServer.TimeWithoutDate(RouteString.TimeTo);
	EndIf;
	
	Return RouteString;
	
EndFunction

// Calculates and returns the maximum time for the planned end of delivery by item.
//
// Parameters:
//  Object - DocumentObject.TransportationJob -
//  	   - FormDataStructure: See Document.TransportationJob.Form.DocumentForm.Object
//
// Returns:
//	Date - the time of the end of delivery by points.
//
Function MaximumSoftwareTime(Object) Export
	
	If Object.Route.Count() <> 0 Then
		RouteTable = Object.Route.Unload();
		RouteTable.Sort("TimeTo Desc");
		
		Return Max(Object.PlanTripStartTime, RouteTable[0].TimeTo);
	Else
		Return Object.PlanTripStartTime;
	EndIf;
	
EndFunction

// Returns a table of values with columns copied from the passed collection.
//
// Parameters:
//  Collection	 - FormDataTree, FormDataCollection, ValueTable	 - the data source whose columns
//  	you want to copy.
//  ColumnsNames - String													 - names of copied columns, separated by commas.
// 
// Returns:
//  ValueTable - the copied table.
//
Function CopyCollectionColumns(Collection, ColumnsNames) Export
	
	If TypeOf(Collection) = Type("FormDataTree") Then
		TreeItems = Collection.GetItems();
		If TreeItems.Count() > 0 Then
			StringForCopyingTypes = TreeItems[0];
		Else
			CopyCollection = FormDataToValue(Collection, Type("ValueTree")).Rows; // ValueTree, ValueTable
			StringForCopyingTypes = CopyCollection.Add();
		EndIf;
	ElsIf TypeOf(Collection) = Type("FormDataCollection") Then
		If Collection.Count() > 0 Then
			StringForCopyingTypes = Collection[0];
		Else
			Return FormDataToValue(Collection, Type("ValueTable"));
		EndIf;
	Else // ValueTable
		Return Collection.CopyColumns();
	EndIf;
	
	ColumnStructure1 = New Structure(ColumnsNames);
	FillPropertyValues(ColumnStructure1, StringForCopyingTypes);
	
	Table = New ValueTable;
	TypesArray = New Array(1);
	For Each KeyAndValue In ColumnStructure1 Do
		If KeyAndValue.Key = "ReferenceOrder" Then
			Table.Columns.Add(KeyAndValue.Key, Metadata.DefinedTypes.DeliveryReferenceOrder.Type);
		ElsIf  KeyAndValue.Key = "RecipientSender" Then
			Table.Columns.Add(KeyAndValue.Key, Metadata.DefinedTypes.SenderRecipientOfDelivery.Type);
		Else
			TypesArray[0] = TypeOf(KeyAndValue.Value);
			Table.Columns.Add(KeyAndValue.Key, New TypeDescription(TypesArray));
		EndIf;
	EndDo;
	Return Table;
	
EndFunction

// Adds or replaces entries in the Product delivery information register for a transportation task.
//
// Parameters:
//	Goods_FromOrders - ValueTable, FormDataCollection - data source to fill in;
//	TSReferences - FormDataCollection - table part with orders;
//	TransportationJob - DocumentRef.TransportationJob - link to the transport task document.
//
Procedure PrepareGoodsForDelivery(Goods_FromOrders, TSReferences, TransportationJob) Export
	
	QueryText = 
	"SELECT
	|	T.ReferenceOrder,
	|	T.Warehouse,
	|	TRUE AS AllGoods
	|INTO FullyDeliverableOrders
	|FROM
	|	&FullyDeliverableOrders AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	GoodsToDeliver.Count,
	|	GoodsToDeliver.AllGoods,
	|	GoodsToDeliver.RecipientSender
	|INTO TTProductsTasks
	|FROM
	|	&GoodsToDeliver AS GoodsToDeliver
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTProductsTasks.ReferenceOrder,
	|	TTProductsTasks.Warehouse,
	|	TTProductsTasks.AllGoods
	|INTO OrdersTasks
	|FROM
	|	TTProductsTasks AS TTProductsTasks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ReferenceOrder,
	|	T.RecipientSender,
	|	T.Products,
	|	T.Warehouse,
	|	T.Purpose,
	|	T.Characteristic,
	|	T.Series,
	|	SUM(T.Count) AS Count,
	|	MAX(T.AllGoods) AS AllGoods
	|INTO TaskItems_
	|FROM
	|	TTProductsTasks AS T
	|
	|GROUP BY
	|	T.ReferenceOrder,
	|	T.RecipientSender,
	|	T.Products,
	|	T.Warehouse,
	|	T.Purpose,
	|	T.Characteristic,
	|	T.Series
	|
	|INDEX BY
	|	T.ReferenceOrder,
	|	T.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ReferenceOrder,
	|	T.Warehouse
	|INTO AmendedOrders
	|FROM
	|	(SELECT
	|		GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
	|		GoodsToDeliver.Warehouse AS Warehouse,
	|		GoodsToDeliver.Products AS Products,
	|		GoodsToDeliver.Characteristic AS Characteristic,
	|		GoodsToDeliver.Purpose AS Purpose,
	|		GoodsToDeliver.Series AS Series,
	|		GoodsToDeliver.Count AS Count,
	|		1 AS CountOfChangedRows
	|	FROM
	|		InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|	WHERE
	|		GoodsToDeliver.TransportationJob = &TransportationJob
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TaskItems_.ReferenceOrder,
	|		TaskItems_.Warehouse,
	|		TaskItems_.Products,
	|		TaskItems_.Characteristic,
	|		TaskItems_.Purpose,
	|		TaskItems_.Series,
	|		-TaskItems_.Count,
	|		-1
	|	FROM
	|		TaskItems_ AS TaskItems_) AS T
	|
	|GROUP BY
	|	T.ReferenceOrder,
	|	T.Characteristic,
	|	T.Purpose,
	|	T.Series,
	|	T.Products,
	|	T.Warehouse
	|
	|HAVING
	|	(SUM(T.Count) <> 0
	|		OR SUM(T.CountOfChangedRows) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AmendedOrders.ReferenceOrder,
	|	AmendedOrders.Warehouse
	|INTO ModifiedOrCollapsed
	|FROM
	|	AmendedOrders AS AmendedOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&TransportationJob AS TransportationJob,
	|	ModifiedOrCollapsed.ReferenceOrder,
	|	ModifiedOrCollapsed.Warehouse,
	|	TaskItems_.Products,
	|	TaskItems_.Characteristic,
	|	TaskItems_.Purpose,
	|	TaskItems_.Series,
	|	TaskItems_.Count,
	|	ISNULL(FullyDeliverableOrders.AllGoods, TaskItems_.AllGoods) AS AllGoods,
	|	TaskItems_.RecipientSender,
	|	CASE
	|		WHEN TaskItems_.ReferenceOrder IS NULL 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Delete
	|FROM
	|	ModifiedOrCollapsed AS ModifiedOrCollapsed
	|		LEFT JOIN TaskItems_ AS TaskItems_
	|		ON ModifiedOrCollapsed.ReferenceOrder = TaskItems_.ReferenceOrder
	|			AND ModifiedOrCollapsed.Warehouse = TaskItems_.Warehouse
	|		LEFT JOIN FullyDeliverableOrders AS FullyDeliverableOrders
	|		ON ModifiedOrCollapsed.ReferenceOrder = FullyDeliverableOrders.ReferenceOrder
	|			AND ModifiedOrCollapsed.Warehouse = FullyDeliverableOrders.Warehouse
	|
	|ORDER BY
	|	TaskItems_.ReferenceOrder,
	|	TaskItems_.Warehouse";
	
	Query = New Query(QueryText);
	Query.SetParameter("TransportationJob", TransportationJob);
	Query.SetParameter("FullyDeliverableOrders",
		TSReferences.Unload(New Structure("DeliveredInFull", True), "ReferenceOrder,Warehouse"));
	Query.SetParameter("GoodsToDeliver", Goods_FromOrders);
	
	Selection = Query.Execute().Select();
	While Selection.NextByFieldValue("ReferenceOrder") Do
		While Selection.NextByFieldValue("Warehouse") Do
			
			RecordSetDelete = InformationRegisters.GoodsToDeliver.CreateRecordSet();
			RecordSetDelete.Filter.Warehouse.Set(Selection.Warehouse);
			RecordSetDelete.Filter.ReferenceOrder.Set(Selection.ReferenceOrder);
			RecordSetDelete.Filter.Products.Set(Catalogs.Products.EmptyRef());
			RecordSetDelete.Filter.Characteristic.Set(Catalogs.ItemsCharacteristics.EmptyRef());
			RecordSetDelete.Filter.Purpose.Set(Catalogs.Assignments.EmptyRef());
			RecordSetDelete.Filter.Series.Set(Catalogs.ItemsBatches.EmptyRef());
			RecordSetDelete.Write();
			
			If ValueIsFilled(Selection.Products) Then
				
				RecordSetDelete = InformationRegisters.GoodsToDeliver.CreateRecordSet();
				RecordSetDelete.Filter.Warehouse.Set(Selection.Warehouse);
				RecordSetDelete.Filter.ReferenceOrder.Set(Selection.ReferenceOrder);
				RecordSetDelete.Filter.Products.Set(Selection.Products);
				RecordSetDelete.Filter.Characteristic.Set(Selection.Characteristic);
				RecordSetDelete.Filter.Purpose.Set(Selection.Purpose);
				RecordSetDelete.Filter.Series.Set(Selection.Series);
				RecordSetDelete.Write();
				
			EndIf;
			
			RecordSet = InformationRegisters.GoodsToDeliver.CreateRecordSet();
			RecordSet.Filter.TransportationJob.Set(TransportationJob);
			RecordSet.Filter.ReferenceOrder.Set(Selection.ReferenceOrder);
			RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
			If Not Selection.Delete Then
				If Selection.AllGoods Then
					FillPropertyValues(RecordSet.Add(),Selection,"TransportationJob,RecipientSender,Warehouse,ReferenceOrder,AllGoods");
				Else
					While Selection.Next() Do
						FillPropertyValues(RecordSet.Add(),Selection);
					EndDo;
				EndIf;
			EndIf;
			RecordSet.Write(True);
		EndDo;
	EndDo;
	
EndProcedure

// Calculates whether the order is fully delivered to the warehouse and fills in the corresponding attribute.
//
// Parameters:
//	Goods_FromOrders - ValueTable - delivery order items;
//	TSReferences - FormDataCollection - the table part with instructions for filling in the attribute is delivered in Full;
//	RowsByFilling - Array, Undefined - lines, table part of the order.
//
Procedure ThisAttributeIsDeliveredInFull(Goods_FromOrders, TSReferences, RowsByFilling = Undefined) Export
	
	QueryText = 
	"SELECT
	|	T.LineNumber,
	|	T.ReferenceOrder,
	|	T.Warehouse,
	|	T.DeliveredInFull
	|INTO TSReferences
	|FROM
	|	&TSReferences AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	GoodsToDeliver.Count,
	|	GoodsToDeliver.AllGoods,
	|	GoodsToDeliver.RecipientSender
	|INTO TTProductsTasks
	|FROM
	|	&GoodsToDeliver AS GoodsToDeliver
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTProductsTasks.ReferenceOrder,
	|	TTProductsTasks.Warehouse,
	|	TTProductsTasks.AllGoods
	|INTO OrdersTasks
	|FROM
	|	TTProductsTasks AS TTProductsTasks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ReferenceOrder AS ReferenceOrder,
	|	T.RecipientSender AS RecipientSender,
	|	T.Warehouse AS Warehouse,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Purpose AS Purpose,
	|	T.Series AS Series,
	|	SUM(T.Count) AS Count,
	|	MAX(T.AllGoods) AS AllGoods
	|INTO TaskItems_
	|FROM
	|	TTProductsTasks AS T
	|
	|GROUP BY
	|	T.ReferenceOrder,
	|	T.RecipientSender,
	|	T.Products,
	|	T.Warehouse,
	|	T.Purpose,
	|	T.Characteristic,
	|	T.Series
	|
	|INDEX BY
	|	T.ReferenceOrder,
	|	T.Warehouse";
	
	RequestTextTemplateForOrder =
	"SELECT ALLOWED
	|	Header.Ref,
	|	Header.Partner AS RecipientSender,
	|	TS.Warehouse AS Warehouse,
	|	TS.Products,
	|	TS.Characteristic,
	|	TS.Purpose AS Purpose,
	|	TS.Series,
	|	TS.Count AS Count
	|INTO Goods_FromOrders
	|FROM
	|	Document.SalesOrder AS Header
	|		INNER JOIN Document.SalesOrder.Goods AS TS
	|		ON Header.Ref = TS.Ref
	|		INNER JOIN OrdersTasks AS OrdersTasks
	|		ON (OrdersTasks.ReferenceOrder = Header.Ref)
	|			AND (OrdersTasks.Warehouse = TS.Warehouse)
	|			AND (NOT OrdersTasks.AllGoods)";
	
	TextOfDeliveryOrder = "";
	
	UnionAllText = "
	|
	|UNION ALL
	|";
	
	ThisIsFirstOne = True;
	DescriptionsOfDeliveryOrders = GoodsDeliveryClientServer.DescriptionsOfDeliveryOrders();
	For Each LongDesc In DescriptionsOfDeliveryOrders Do
		
		TextByOrder = StrReplace(RequestTextTemplateForOrder, "SalesOrder", LongDesc.Name);
		TextByOrder = StrReplace(TextByOrder, ".Goods",                    "." + LongDesc.TSName);
		TextByOrder = StrReplace(TextByOrder, "Partner AS RecipientSender",     LongDesc.FieldNameRecipientSender + " AS RecipientSender");
		TextByOrder = StrReplace(TextByOrder, "TS.Warehouse",                   LongDesc.WarehouseFieldName);
		TextByOrder = StrReplace(TextByOrder, "TS.Purpose",              LongDesc.NameOfDestinationField);
		TextByOrder = StrReplace(TextByOrder, "TS.Series",                   LongDesc.FieldNameSeries);
		
		If ThisIsFirstOne Then
			ThisIsFirstOne = False;
		Else
			TextByOrder = StrReplace(TextByOrder, "ALLOWED", "");
			TextByOrder = StrReplace(TextByOrder, "INTO Goods_FromOrders","");
			TextOfDeliveryOrder = TextOfDeliveryOrder + UnionAllText;
		EndIf;
		
		TextOfDeliveryOrder = TextOfDeliveryOrder + TextByOrder;
		
	EndDo;
	
	QueryTextByAgreements =
	"SELECT
	|	TermsOfPurchaseFromVendors.Ref,
	|	TermsOfPurchaseFromVendors.Partner,
	|	TermsOfPurchaseFromVendors.Warehouse,
	|	GoodsToReceiveBalance.Products,
	|	GoodsToReceiveBalance.Characteristic,
	|	GoodsToReceiveBalance.Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef),
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		INNER JOIN OrdersTasks AS OrdersTasks
	|		ON (OrdersTasks.ReferenceOrder = TermsOfPurchaseFromVendors.Ref)
	|			AND (NOT OrdersTasks.AllGoods)
	|		INNER JOIN AccumulationRegister.GoodsToReceive.Balance(, ) AS GoodsToReceiveBalance
	|		ON TermsOfPurchaseFromVendors.Ref = GoodsToReceiveBalance.DocumentInflow
	|			AND TermsOfPurchaseFromVendors.Warehouse = GoodsToReceiveBalance.Warehouse
	|		INNER JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		ON TermsOfPurchaseFromVendors.Ref = StatesAndDetailsOfDelivery.ReferenceOrder";
	
	QueryTextByContracts =
	"SELECT
	|	CounterpartyContracts.Ref,
	|	CounterpartyContracts.Partner,
	|	GoodsToReceiveBalance.Warehouse,
	|	GoodsToReceiveBalance.Products,
	|	GoodsToReceiveBalance.Characteristic,
	|	GoodsToReceiveBalance.Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef),
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|		INNER JOIN OrdersTasks AS OrdersTasks
	|		ON (OrdersTasks.ReferenceOrder = CounterpartyContracts.Ref)
	|			AND (NOT OrdersTasks.AllGoods)
	|		INNER JOIN AccumulationRegister.GoodsToReceive.Balance(, ) AS GoodsToReceiveBalance
	|		ON CounterpartyContracts.Ref = GoodsToReceiveBalance.DocumentInflow
	|		INNER JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		ON CounterpartyContracts.Ref = StatesAndDetailsOfDelivery.ReferenceOrder";
	
	TextOfDeliveryOrder = TextOfDeliveryOrder 
		+ UnionAllText 
		+ QueryTextByAgreements 
		+ UnionAllText 
		+ QueryTextByContracts;
	
	QueryText = QueryText 
		+ Common.QueryBatchSeparator() 
		+ TextOfDeliveryOrder 
		+ Common.QueryBatchSeparator();
	
	QueryText = QueryText +
	"SELECT
	|	T.ReferenceOrder,
	|	T.Warehouse,
	|	SUM(T.Count) AS Count
	|INTO RemainingQuantityAccToReference
	|FROM
	|	(SELECT
	|		TaskItems_.ReferenceOrder AS ReferenceOrder,
	|		TaskItems_.RecipientSender AS RecipientSender,
	|		TaskItems_.Warehouse AS Warehouse,
	|		TaskItems_.Products AS Products,
	|		TaskItems_.Characteristic AS Characteristic,
	|		TaskItems_.Purpose AS Purpose,
	|		TaskItems_.Series AS Series,
	|		-TaskItems_.Count AS Count
	|	FROM
	|		TaskItems_ AS TaskItems_
	|	WHERE
	|		NOT TaskItems_.AllGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Ref,
	|		T.RecipientSender,
	|		T.Warehouse,
	|		T.Products,
	|		T.Characteristic,
	|		T.Purpose,
	|		T.Series,
	|		T.Count
	|	FROM
	|		Goods_FromOrders AS T) AS T
	|
	|GROUP BY
	|	T.ReferenceOrder,
	|	T.RecipientSender,
	|	T.Warehouse,
	|	T.Products,
	|	T.Characteristic,
	|	T.Purpose,
	|	T.Series
	|
	|HAVING
	|	SUM(T.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	OrdersTasks.ReferenceOrder,
	|	OrdersTasks.Warehouse,
	|	TRUE AS AllGoods
	|INTO FullyDeliverableOrders
	|FROM
	|	OrdersTasks AS OrdersTasks
	|		LEFT JOIN RemainingQuantityAccToReference AS RemainingQuantityAccToReference
	|		ON OrdersTasks.ReferenceOrder = RemainingQuantityAccToReference.ReferenceOrder
	|			AND OrdersTasks.Warehouse = RemainingQuantityAccToReference.Warehouse
	|WHERE
	|	RemainingQuantityAccToReference.ReferenceOrder IS NULL" + Common.QueryBatchSeparator();
	
	QueryText = QueryText +
	"SELECT
	|	TSReferences.LineNumber
	|FROM
	|	FullyDeliverableOrders AS T
	|		INNER JOIN TSReferences AS TSReferences
	|		ON (TSReferences.ReferenceOrder = T.ReferenceOrder)
	|			AND (TSReferences.Warehouse = T.Warehouse)
	|			AND NOT TSReferences.DeliveredInFull";
	
	Query = New Query(QueryText);
	Query.SetParameter("GoodsToDeliver", Goods_FromOrders);
	
	If RowsByFilling = Undefined Then
		Query.SetParameter("TSReferences",
			TSReferences.Unload(,"LineNumber, ReferenceOrder, Warehouse, DeliveredInFull"));
	Else
		Query.SetParameter("TSReferences",
			TSReferences.Unload(RowsByFilling,"LineNumber, ReferenceOrder, Warehouse, DeliveredInFull"));
	EndIf;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TSReferences[Selection.LineNumber - 1].DeliveredInFull = True;
	EndDo;
	
EndProcedure

// Fills in an array of unverifiable delivery order details, depending on the delivery method.
//
// Parameters:
//  DocumentObject - DocumentObject	- an order that verifies the filling in of Bank details;
//  NotCheckedAttributeArray - Array of String - array of details that you don't need to fill in;
//  Cancel - Boolean - The truth is a sign of failure of the execution fill details;
//  InvoiceForOrders - Boolean - True-the document Object is an order invoice.
//
Procedure CheckDeliveryDetails(DocumentObject, NotCheckedAttributeArray, Cancel, InvoiceForOrders = False) Export
	
	If Not GoodsDeliveryClientServer.UsedDelivery20() Then
		
		NotCheckedAttributeArray.Add("DeliveryAddress");
		Return;
		
	EndIf;
	
	// We will check the compliance of the delivery details of orders and invoices
	DataKey = TMCommonUse.DataKeyForMessageToUser(DocumentObject);
	Field = "DeliveryMethod";
	
	SetPrivilegedMode(True);
	If Not GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers") Then
		
		If InvoiceForOrders
			And DocumentObject.DeliveryMethod = Enums.TransportMethods.ByCarrier Then
			// Let's check that the correct delivery method is specified in the orders on the invoice
			QueryText =
			"SELECT DISTINCT
			|	GoodsForShipmentTurnover.DocumentShipments AS Ref
			|FROM
			|	AccumulationRegister.GoodsForIssue.Turnovers(, , Recorder, ) AS GoodsForShipmentTurnover
			|WHERE
			|	GoodsForShipmentTurnover.Recorder = &Ref
			|	AND GoodsForShipmentTurnover.DocumentShipments.DeliveryMethod <> VALUE(Enum.TransportMethods.ByCarrier)";
			
			Query = New Query(QueryText);
			Query.SetParameter("Ref",DocumentObject.Ref);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				MessageText = NStr("vi = 'Phương thức Phân bổ trong chứng từ được liên kết %Ref% không khớp với chỉ định trên hóa đơn.';
									|ru = 'Способ доставки в связанном документе %Ref% не соответствует указанному в накладной.';
									|en = 'Delivery method in linked document %Ref% does not correspond to the one specified in the invoice.'; fa = 'Delivery method in linked document %Ref% does not correspond to the one specified in the invoice.';
									|it = 'Metodo di consegna nel documento correlato %Ref% non corrispondente a quello indicato in fattura.';
									|pl = 'Sposób dostawy w powiązanym dokumencie %Ref% nie odpowiada wskazanemu w liście przewozowym.';
									|tr = '%Ref% ilgili belgedeki teslimat yöntemi, irsaliyedeki ile eşleşmiyor.'");
				MessageText = StrReplace(MessageText, "%Ref%", Selection.Ref);
				Common.MessageToUser(MessageText,DataKey,Field,"Object",Cancel);
			EndDo;
			
		Else
			// Let's check that the correct delivery method is specified in the order invoices
			QueryText =
			"SELECT DISTINCT
			|	GoodsForShipmentTurnover.Recorder AS Ref
			|FROM
			|	AccumulationRegister.GoodsForIssue.Turnovers(, , Recorder, DocumentShipments = &Ref) AS GoodsForShipmentTurnover
			|WHERE
			|	GoodsForShipmentTurnover.Recorder <> GoodsForShipmentTurnover.DocumentShipments
			|	AND GoodsForShipmentTurnover.ToRegisterExpense > 0";
			
			Query = New Query(QueryText);
			Query.SetParameter("Ref", DocumentObject.Ref);
			
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				ByCarrier = PredefinedValue("Enum.TransportMethods.ByCarrier");
				ThereIsDeliveryMethod = TMCommonUseClientServer.HasObjectAttribute(Selection.Ref, "DeliveryMethod");
				If ThereIsDeliveryMethod Then
					DeliveryMethodForLinkedDocument = Common.ObjectAttributeValue(Selection.Ref, "DeliveryMethod");
					If DocumentObject.DeliveryMethod = ByCarrier
						And DeliveryMethodForLinkedDocument <> ByCarrier
						Or DocumentObject.DeliveryMethod <> ByCarrier
						And DeliveryMethodForLinkedDocument = ByCarrier Then
						
						MessageText = NStr("vi = 'Phương thức Phân bổ trong chứng từ được liên kết %Ref% không khớp với phương thức được chỉ định trong đơn hàng.';
											|ru = 'Способ доставки в связанном документе %Ref% не соответствует указанному в заказе.';
											|en = 'Delivery method in linked document %Ref% does not correspond to the one specified in the order.'; fa = 'Delivery method in linked document %Ref% does not correspond to the one specified in the order.';
											|it = 'Metodo di consegna nel documento correlato %Ref% non corrispondente a quanto indicato nell''ordine.';
											|pl = 'Sposób dostawy w powiązanym dokumencie %Ref% nie odpowiada wskazanemu w zamuwieniu.';
											|tr = '%Ref% ilgili belgedeki teslimat yöntemi, siparişteki ile eşleşmiyor.'");
						MessageText = StrReplace(MessageText, "%Ref%", Selection.Ref);
						Common.MessageToUser(MessageText,DataKey,Field,"Object",Cancel);
					EndIf;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;

	SetPrivilegedMode(False);
	
	If TMCommonUseClientServer.HasObjectAttribute(DocumentObject, "SpecialTransportationConditions")
		And Not DocumentObject.SpecialTransportationConditions Then
		NotCheckedAttributeArray.Add("SpecialTransportationConditionsDescription");
	EndIf;
	
	// No delivery required
	If Not ValueIsFilled(DocumentObject.DeliveryMethod)
	 Or DocumentObject.DeliveryMethod = Enums.TransportMethods.DeterminedInReference
	 Or (InvoiceForOrders And Not DocumentObject.DeliveryMethod = Enums.TransportMethods.ByCarrier)
	 Or DocumentObject.DeliveryMethod = Enums.TransportMethods.SelfPickup
	 Or DocumentObject.DeliveryMethod = Enums.TransportMethods.ByVendorToOurWarehouse Then
		
		NotCheckedAttributeArray.Add("CarrierPartner");
		NotCheckedAttributeArray.Add("DeliveryAddress");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
		
	// Delivery from us
		
	ElsIf DocumentObject.DeliveryMethod = Enums.TransportMethods.ByCarrier Then
		
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
		
	ElsIf DocumentObject.DeliveryMethod = Enums.TransportMethods.ToCustomer
		  Or DocumentObject.DeliveryMethod = Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany
		  Or DocumentObject.DeliveryMethod = Enums.TransportMethods.ToCustomerByCourier
	// Delivery to us
		
		  Or DocumentObject.DeliveryMethod = Enums.TransportMethods.OurOwnDeliveryFromSenderAddress
		  Or DocumentObject.DeliveryMethod = Enums.TransportMethods.FromSenderDeterminedByDeliveryService Then
		
		NotCheckedAttributeArray.Add("CarrierPartner");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
		
	ElsIf DocumentObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToOurWarehouse Then
		
		NotCheckedAttributeArray.Add("DeliveryAddress");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
		
	ElsIf DocumentObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint Then
		
		NotCheckedAttributeArray.Add("DeliveryAddress");
		
	EndIf;
	
EndProcedure

// Performs actions when changing the "Special conditions of carriage" details.
//
// Parameters:
//	FormItems - FormAllItems - form elements where properties are changed;
//	DocObject - FormDataStructure - the object whose details are used when changing 
//		the value of the "Special conditions of carriage"item.
//
Procedure SpecialTransportationConditionsOnChange(FormItems, DocObject) Export
	
	If Not DocObject.SpecialTransportationConditions Then
		DocObject.SpecialTransportationConditionsDescription = "";
	EndIf;
	
	SpecialConditionsOfCarriageAndAccessibility(FormItems, DocObject);
	
EndProcedure

// Supplements contact information with the phone numbers of the contact person, carrier, sender, or recipient.
//
// Parameters:
//  Object - FormDataStructure - an object where delivery data is filled in with contact information.
//
Procedure SupplementDeliveryInformationWithContacts(Object) Export
	
	TypesOfCI = New Array; // Array of EnumRef.ContactInformationTypes
	TypesOfCI.Add(Enums.ContactInformationTypes.Phone);
	
	SourcesOfCI = New Array;
	ContactPerson = Undefined;
	Object.Property("ContactPerson", ContactPerson);
	If ValueIsFilled(ContactPerson) Then
		SourcesOfCI.Add(ContactPerson);
	EndIf;
	
	DeliveryMethod = Undefined;
	Object.Property("DeliveryMethod",DeliveryMethod);
	
	If DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint
		Or DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress Then
		CarrierPartner = Object.CarrierPartner;
		SourcesOfCI.Add(CarrierPartner);
	Else
		RecipientSender = RecipientSender(Object);
		SourcesOfCI.Add(RecipientSender.Value);
	EndIf;
	
	For Each Source In SourcesOfCI Do
		If Not ValueIsFilled(Source) Then
			Continue;
		EndIf;
		SourceParameter = New Array;
		SourceParameter.Add(Source);
		ContactInformation = ContactsManager.ObjectsContactInformation(SourceParameter, TypesOfCI, , CurrentSessionDate());
		ContactsFilledIn = False;
		If ContactInformation.Count() > 0 Then
			TextPhones = String(Source) + ": ";
			For Each Page1 In ContactInformation Do
				If ValueIsFilled(Page1.Presentation) Then
					ContactsFilledIn = True;
					TextPhones = TextPhones + Page1.Presentation + ", ";
				EndIf;
			EndDo;
			TextPhones = Left(TextPhones, StrLen(TextPhones)-2) + ".";
			If ContactsFilledIn
				And StrFind(Object.AdditionalDeliveryInformation, TextPhones) = 0 Then
				If ValueIsFilled(Object.AdditionalDeliveryInformation) Then
					Object.AdditionalDeliveryInformation = Object.AdditionalDeliveryInformation + Chars.LF;
				EndIf;
				Object.AdditionalDeliveryInformation = Object.AdditionalDeliveryInformation + TextPhones;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Gets the details of the vehicle.
//
// Parameters:
//  Vehicle_ - CatalogRef.Vehicles, CatalogRef.VehicleTypes	 - the vehicle whose
//  	details you need to get.
// 
// Returns:
//  Structure - With Fields:
//  *CapacityPresentation - String - capacity
//  *CarryingCapacityInUserUnit - Number - CarryingCapacity
//  *CapacityInUserUnits - Number - capacity in custom units
//  *CarryingCapacityInTons - Number - load capacity in tons
//  *CapacityInCubicMeters - Number - capacity in cubic meters.
//
Function VehicleDetails(Vehicle_) Export
	
	ReturnStructure = New Structure;
	
	If ValueIsFilled(Vehicle_) Then
		
		VehicleDetails = Common.ObjectAttributesValues(
			Vehicle_,
			"CapacityPresentation, CarryingCapacityInTons, CapacityInCubicMeters");
		
		ReturnStructure.Insert("CapacityPresentation", VehicleDetails.CapacityPresentation);
		ReturnStructure.Insert("CarryingCapacityInUserUnit", VehicleDetails.CarryingCapacityInTons / TonConversionFactor());
		ReturnStructure.Insert("CapacityInUserUnits", VehicleDetails.CapacityInCubicMeters / CubicMeterConversionFactor());
		ReturnStructure.Insert("CarryingCapacityInTons", VehicleDetails.CarryingCapacityInTons);
		ReturnStructure.Insert("CapacityInCubicMeters", VehicleDetails.CapacityInCubicMeters);
		
	Else
		
		ReturnStructure.Insert("CapacityPresentation", "");
		ReturnStructure.Insert("CarryingCapacityInUserUnit", 0);
		ReturnStructure.Insert("CapacityInUserUnits", 0);
		ReturnStructure.Insert("CarryingCapacityInTons", 0);
		ReturnStructure.Insert("CapacityInCubicMeters", 0);
		
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Generates a text representation of delivery details for output to the form.
//
// Parameters:
//  ContainerForDeliveryDetails	 - CatalogRef.TermsOfPurchaseFromVendors, CatalogRef.CounterpartyContracts - 
//  									a contract or agreement containing information about the delivery details.
// 
// Returns:
//  String - text representation of delivery details.
//
Function GenerateSummaryDeliveryInformation(ContainerForDeliveryDetails) Export
	
	If Not ValueIsFilled(ContainerForDeliveryDetails) Then
		Return Undefined;
	EndIf;
	
	DeliveryDetails_Presentation = Undefined;
	
	DeliveryDetails_ = DeliveryDetails_(ContainerForDeliveryDetails);
	
	AttributesDetails1 = New Map;
	AttributesDetails1.Insert("DeliveryMethod"					, "Method deliveries");
	AttributesDetails1.Insert("TimeOfDelivery"						, "Desired time deliveries");
	AttributesDetails1.Insert("DeliveryAddress"						, "Address deliveries");
	AttributesDetails1.Insert("CarrierPartner"					, "Carrier");
	AttributesDetails1.Insert("DeliveryAddressOfCarrier"			, "Address point_1 transfers_");
	AttributesDetails1.Insert("DeliveryZone"						, "Zone deliveries");
	AttributesDetails1.Insert("AdditionalDeliveryInformation", "Additional information on delivery_");
	
	DeliveryDetails_Presentation = "";
	
	If ValueIsFilled(DeliveryDetails_.DeliveryTimeFrom) And ValueIsFilled(DeliveryDetails_.DeliveryTimeTo) Then
		Template = NStr("vi = 'từ %1 đến %2';
						|ru = 'с %1 до %2';
						|en = 'from %1 to %2'; fa = 'from %1 to %2';
						|it = 'da %1 a %2';
						|pl = 'od %1 do %2';
						|tr = '%1 itibaren %2 kadar'");
		PresentationOfDeliveryTime = StrTemplate(Template,
			Format(DeliveryDetails_.DeliveryTimeFrom	, NStr("vi = 'ДФ=''ЧЧ"":""мм''';
																|ru = 'ДФ=''HH"":""mm''';
																|en = 'DF=''HH"":""mm'''; fa = 'DF=''HH"":""mm''';
																|it = 'ДФ=''ЧЧ"":""мм''';
																|pl = 'DF=''HH"":""mm''';
																|tr = 'DF=''HH"":""mm'''")),
			Format(DeliveryDetails_.DeliveryTimeTo, NStr("vi = 'ДФ=''ЧЧ"":""мм''';
														|ru = 'ДФ=''HH"":""mm''';
														|en = 'DF=''HH"":""mm'''; fa = 'DF=''HH"":""mm''';
														|it = 'ДФ=''ЧЧ"":""мм''';
														|pl = 'DF=''HH"":""mm''';
														|tr = 'DF=''HH"":""mm'''")));
		DeliveryDetails_.Insert("TimeOfDelivery", PresentationOfDeliveryTime);
	ElsIf ValueIsFilled(DeliveryDetails_.DeliveryTimeFrom) Then
		Template = NStr("vi = 'sau %1';
						|ru = 'после %1';
						|en = 'after %1'; fa = 'after %1';
						|it = 'dopo %1';
						|pl = 'po %1';
						|tr = '%1 sonra'");
		PresentationOfDeliveryTime = StrTemplate(Template,
			Format(DeliveryDetails_.DeliveryTimeFrom	, NStr("vi = 'ДФ=''ЧЧ"":""мм''';
																|ru = 'ДФ=''HH"":""mm''';
																|en = 'DF=''HH"":""mm'''; fa = 'DF=''HH"":""mm''';
																|it = 'ДФ=''ЧЧ"":""мм''';
																|pl = 'DF=''HH"":""mm''';
																|tr = 'DF=''HH"":""mm'''")));
		DeliveryDetails_.Insert("TimeOfDelivery", PresentationOfDeliveryTime);
	ElsIf ValueIsFilled(DeliveryDetails_.DeliveryTimeTo) Then
		Template = NStr("vi = 'đến %1';
						|ru = 'до %1';
						|en = 'until %1'; fa = 'until %1';
						|it = 'al %1';
						|pl = 'do %1';
						|tr = '%1 kadar'");
		PresentationOfDeliveryTime = StrTemplate(Template,
			Format(DeliveryDetails_.DeliveryTimeTo, NStr("vi = 'ДФ=''ЧЧ"":""мм''';
														|ru = 'ДФ=''HH"":""mm''';
														|en = 'DF=''HH"":""mm'''; fa = 'DF=''HH"":""mm''';
														|it = 'ДФ=''ЧЧ"":""мм''';
														|pl = 'DF=''HH"":""mm''';
														|tr = 'DF=''HH"":""mm'''")));
		DeliveryDetails_.Insert("TimeOfDelivery", PresentationOfDeliveryTime);
	EndIf;
	
	For Each DeliveryDetails In DeliveryDetails_ Do
		AttributeRepresentation = AttributesDetails1[DeliveryDetails.Key]; 
		If AttributeRepresentation <> Undefined And ValueIsFilled(DeliveryDetails.Value) Then 
			DeliveryDetails_Presentation = DeliveryDetails_Presentation
			+ AttributeRepresentation + ": " + DeliveryDetails.Value + Chars.LF; 
		EndIf;
	EndDo;
	
	Return DeliveryDetails_Presentation;
	
EndFunction

// Called after calling the Print procedure of the object's print Manager, it has the same parameters.
// Used for printing a set of documents in accordance with the order of documents in the "transportation Task".
// 
// Parameters:
//  ObjectsArray - Array - list of objects for which the Print procedure was performed;
//  PrintParameters - Structure - custom parameters passed when calling the print command;
//  PrintFormsCollection - ValueTable - contains tabular documents and additional information;
//  PrintObjects - ValueList - the correspondence between objects and area names in tabular documents, where
//                                   the value is the Object, the representation is the name of the area with the object in tabular documents.
//  OutputParameters - Structure - parameters related to the output of tabular documents:
//		* SendOptions - Structure - the information for filling out a letter when sending a printed form by e-mail contains the following fields (for a description, see in the general configuration module, work with mail messages, the client in the Create New Message procedure):
//			* Recipient - String,
//			* Subject - String,
//			* Text - String
//
Procedure OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintFormsCollection.Count()
	   And PrintFormsCollection[0].TemplateName = "SetOfDocuments" 
	   And ObjectsArray.Count()
	   And TypeOf(ObjectsArray[0]) = Type("DocumentRef.TransportationJob") Then
		
		Job = ObjectsArray[0];
		TaskDocuments = Documents.TransportationJob.GetInvoicesForTransportationOrder(Job);
		Map = New Map;
		PrintObjectsResult = New ValueList;
		FillPropertyValues(PrintObjectsResult.Add(), PrintObjects[0]);
		For Each PrintObject In PrintObjects Do
			IndexOf = TaskDocuments.Find(PrintObject.Value);
			If IndexOf <> Undefined Then
				Map.Insert(IndexOf, PrintObject.Value);
			EndIf;
		EndDo;
		For Cnt = 0 To Map.Count() - 1 Do 
			ListItem = PrintObjects.FindByValue(Map[Cnt]);
			FillPropertyValues(PrintObjectsResult.Add(), ListItem);
		EndDo;
		PrintObjects = PrintObjectsResult;
		
	EndIf;
	
EndProcedure

// Returns an indication that the delivery address and the selection list in the sales document need to be refilled.
// 
// Parameters:
//  ReferenceOrder - DocumentRef, FormDataStructure - Sales document:
//      * Ref - DocumentRef - The sales document.
// 
// Returns:
//  Boolean - Re-fill in the delivery address in the sales document.
//
Function ReFillInDeliveryAddressInSalesDocument(ReferenceOrder) Export
	
	Return TypeOf(ReferenceOrder) = Type("DocumentRef.SalesOrder")
		Or TypeOf(ReferenceOrder) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(ReferenceOrder) = Type("DocumentRef.GoodsShipmentToCustomer")
		Or TypeOf(ReferenceOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
		Or TypeOf(ReferenceOrder) = Type("DocumentRef.TransferOfGoodsToBailee")
		
		Or (TypeOf(ReferenceOrder) = Type("FormDataStructure")
			Or TypeOf(ReferenceOrder) = Type("Structure")
			Or TypeOf(ReferenceOrder) = Type("ClientApplicationForm"))
			
			And (TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.SalesOrder")
				Or TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.CustomerInvoice")
				Or TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.GoodsShipmentToCustomer")
				Or TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
				Or TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.TransferOfGoodsToBailee"));
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  ManualStart - Boolean - 
// 
// Returns:
//  See NewTransitionDataForDelivery25 
//
Function StatusOfTransitionToDelivery25(ManualStart = False) Export
	
	TransitionState = NewTransitionDataForDelivery25();
	
	TransitionState.TransitionIsComplete = GoodsDeliveryClientServer.UsedDelivery25();
	
	If ManualStart Then
		
		TransitionState.TransitionIsRunning = True;
		
	EndIf;
	
	If Not TransitionState.TransitionIsComplete Then
		
		Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.MigrationToDeliveryManagement25);
		
		If Job <> Undefined Then
			
			TransitionState.JobCreated = True;
			TransitionState.TransitionIsRunning = True;
			
		EndIf;
		
	EndIf;
	
	If TransitionState.TransitionIsComplete
	 Or TransitionState.TransitionIsRunning Then
		
		QueryText = QueryTextOfProgressOfTransitionToDelivery25();
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("TypeOfCIWarehouse", Catalogs.ContactInformationKinds.WarehouseAddress);
		Query.SetParameter("TypeOfCIPartner", Catalogs.ContactInformationKinds.PartnerAddress);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			
			FillPropertyValues(TransitionState, Selection);
			
			PartnersProcessed = (TransitionState.NumberOfPartners = TransitionState.NumberOfPartnersProcessed);
			WarehousesHaveBeenProcessed = (TransitionState.NumberOfWarehouses = TransitionState.NumberOfWarehousesProcessed);
			
			TransitionState.DataProcessed = (PartnersProcessed And WarehousesHaveBeenProcessed);
			
		EndIf;
		
	EndIf;
	
	Return TransitionState;
	
EndFunction

// Clear fill delivery line codes.
// 
// Parameters:
//  Object - DocumentObject.CustomerInvoice - 
//         - DocumentObject.GoodsShipmentToCustomer-
//  DeliveryIsRequired - Boolean -
//  TabularSectionName - String - name of the table part
//  PropsMaximumLineCode - String - Attribute name maximum line code
//  TSAttributeName - String - The name of the TS Attribute
//
Procedure ClearFillDeliveryLineCodes(
	Object,
	DeliveryIsRequired,
	TabularSectionName = "Goods",
	PropsMaximumLineCode = "MaximumDeliveryLineCode",
	TSAttributeName = "DeliveryLineCode") Export
	
	If DeliveryIsRequired Then
		
		OrdersServer.SetKeyInRowsOfTablePart(
			Object,
			TabularSectionName,
			PropsMaximumLineCode,
			TSAttributeName);
		
	Else
		
		Object[PropsMaximumLineCode] = 0;
		
		TabularSection = Object[TabularSectionName]; // DocumentTabularSection.CustomerInvoice.Goods, DocumentTabularSection.GoodsShipmentToCustomer.Goods
		For Each LineOfATabularSection In TabularSection Do
			
			LineOfATabularSection[TSAttributeName] = 0;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Enables delivery mode 2.5 after data processing
//
Procedure CompleteTransitionToDelivery25() Export
	
	ConnectionsAreBlocked = IBConnections.ConnectionsLocked();
	
	BeginTransaction();
	
	Try
		
		ConnectionsInformation = IBConnections.ConnectionsInformation();
		TextOfBlockingMessage = GoodsDeliveryClientServer.TextForCheckingActiveSessions();
		If ConnectionsInformation.HasActiveConnections Then
			
			Raise TextOfBlockingMessage;
			
		EndIf;
		
		If Not ConnectionsAreBlocked Then
			
			LockSet = IBConnections.SetConnectionLock(TextOfBlockingMessage);
			If Not LockSet Then
				
				ExceptionText = NStr("ru = 'Не удалось установить блокировку соединений информационной базы.';
									|vi = 'Cannot lock the infobase connections.';
									|en = 'Cannot lock the infobase connections.'; fa = 'Cannot lock the infobase connections.';
									|it = 'Cannot lock the infobase connections.';
									|pl = 'Cannot lock the infobase connections.';
									|tr = 'Infobase bağlantılarının kilitlenmesi başarısız oldu.'"); 
				
			EndIf;
			
		EndIf;
		
		CheckResult = CheckPossibilityOfSwitchingToDelivery25(True);
		
		If Not CheckResult.TransitionIsAvailable Then
			
			ExceptionText = GoodsDeliveryClientServer.TextOfVerificationOfPossibilityOfSwitchingToDelivery25(
				CheckResult);
			
			Raise ExceptionText;
			
		EndIf;
		
		Constants.NotUseDeliveryManagement20.Set(True);
		Constants.NotUseDeliveryManagement25.Set(False);
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.MigrationToDeliveryManagement25);
		
		RefreshReusableValues();
		If Not ConnectionsAreBlocked Then
			
			IBConnections.AllowUserAuthorization();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		If Not ConnectionsAreBlocked Then
			
			IBConnections.AllowUserAuthorization();
			
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

// Supplements the Query Text for the shipment management Form with delivery data
// 
// Parameters:
//  Query - Query
//  QueryText - String
//
Procedure AddDeliveryDataToShipmentManagementQueryText(Query, QueryText) Export
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		AddDeliveryDataToShipmentManagementQueryText20(Query, QueryText);
		
	Else
		
		AddDeliveryDataToShipmentManagementQueryText25(QueryText);
		
	EndIf;
	
EndProcedure

// Supplements the Query Text for the shipment management Form with delivery data with a transcript of the delivery document
// 
// Parameters:
//  QueryText - String
//
Procedure CompleteQueryTextOfShipmentManagementWithDeliveryDataShipmentDetails(QueryText) Export
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		ToSupplementQueryTextOfShipmentManagementWithDeliveryData20ShipmentDetails(QueryText);
		
	Else
		
		SupplementQueryTextOfShipmentManagementWithDeliveryData25ShipmentDetails(QueryText);
		
	EndIf;
	
EndProcedure

Procedure StartSwitchingToDelivery25() Export
	
	TransitionStatus = StatusOfTransitionToDelivery25(True);
	
	If Not TransitionStatus.TransitionIsComplete
		And Not TransitionStatus.JobCreated Then
		
		GoToDelivery25(True);
		CreateRoutineTaskForSwitchingToDelivery25();
		
	EndIf;
	
EndProcedure

// These are delivery orders.
// 
// Parameters:
//  ReferenceOrder - DocumentRef.CustomerInvoice
//  AdditionalParameters - Undefined
//                          - Structure:
//                            * FilterOfProductItem - Array of CatalogRef.Products
// 
// Returns:
//  See NewOrderAddressData
//
Function DeliveryOrderData(ReferenceOrder, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters <> Undefined
		And AdditionalParameters.Property("FilterOfProductItem") Then
		
		FilterOfProductItem = AdditionalParameters.FilterOfProductItem;
		WithoutFilterByProducts = False;
		
	Else
		
		FilterOfProductItem = Undefined;
		WithoutFilterByProducts = True;
		
	EndIf;
	
	QueryText = QueryTextOfTheseDeliveryOrders();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", ReferenceOrder);
	Query.SetParameter("FilterOfProductItem", FilterOfProductItem);
	Query.SetParameter("WithoutFilterByProducts", WithoutFilterByProducts);
	
	DataOfAddresses = NewOrderAddressData();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DataString1 = DataOfAddresses.Add();
		FillPropertyValues(DataString1, Selection);
		
	EndDo;
	
	Return DataOfAddresses;
	
EndFunction

#Region WorkingWithForms
	
// Adds a command to the list of delivery points to the owner of delivery points Form.
// 
// Parameters:
//  Form - ClientApplicationForm
//  ItemForPlacementName - String
//  CommandName - String
//  Visible - Boolean
//
Procedure AddCommandToNavigateToListOfDeliveryPoints(Form, ItemForPlacementName, CommandName, Visible = True) Export
	
	Items = Form.Items;
	Parent = Items[ItemForPlacementName];
	
	Item = Items.Add(CommandName, Type("FormButton"), Parent);
	Item.Type = FormButtonType.Hyperlink;
	Item.CommandName = CommandName;
	Item.Visible = Visible;
	
EndProcedure

// Parameters:
//  List - ValueList of EnumRef.DeliveryPlanningKinds -
//  Object - FormDataStructure:
//  * Ref - CatalogRef.Partners, CatalogRef.TermsOfSale -
//  * Standard_ - Boolean -
//  * Partner - CatalogRef.Partners -
//
Procedure FillInDeliveryPlanningSelectionList(List, Object) Export
	
	List.Clear();
	
	If TypeOf(Object.Ref) = Type("CatalogRef.TermsOfSale")
	   And Not Object.Standard_
	   And ValueIsFilled(Object.Partner) Then
		
		EmptyValueTemplate = NStr("ru = '<Из клиента: %1>';
									|vi = '<From client: %1>';
									|en = '<From client: %1>'; fa = '<From client: %1>';
									|it = '<From client: %1>';
									|pl = '<From client: %1>';
									|tr = '<İstemciden: %1>'");
		
		SettingValue = Common.ObjectAttributeValue(Object.Partner, "DeliveryPlanning");
		
		If Not ValueIsFilled(SettingValue) Then
			
			SettingValue = TypeOfDeliveryPlanningAtSystemLevel();
			
		EndIf;
		
	Else
		
		EmptyValueTemplate = NStr("ru = '<Из настроек системы: %1>';
									|vi = '<From system settings: %1>';
									|en = '<From system settings: %1>'; fa = '<From system settings: %1>';
									|it = '<From system settings: %1>';
									|pl = '<From system settings: %1>';
									|tr = '<Sistem ayarlarından: %1>'");
		SettingValue = TypeOfDeliveryPlanningAtSystemLevel();
		
	EndIf;
	
	SettingPresentation = Common.SubjectString(SettingValue);
	
	PresentationOfEmptyValue = StringFunctionsClientServer.SubstituteParametersToString(
		EmptyValueTemplate,
		Lower(SettingPresentation));
	
	List.Add(Enums.DeliveryPlanningKinds.EmptyRef(), PresentationOfEmptyValue);
	List.Add(Enums.DeliveryPlanningKinds.ByCurrentDocument);
	List.Add(Enums.DeliveryPlanningKinds.SeparateDocument);
	
EndProcedure

// Sets the color highlighting of unused delivery points in lists
//
// Parameters:
//  List - DynamicList
//
Procedure SetUpRegistrationOfUnusedDeliveryPoints(List) Export
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NotUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
EndProcedure

#EndRegion

#Region WorkingWithDeliveryAddresses

// Parameters:
//  Address - String - String Presentation of an address
//  AddressValue - String - JSON Presentation of the address
//  FieldValueAddress - String - XML representation of the address
//
Procedure FillInAddressFieldsByPresentation(Address, AddressValue, FieldValueAddress) Export
	
	If IsBlankString(Address) Then
		
		AddressValue = "";
		FieldValueAddress = "";
		
	Else
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		
		GoodsDeliveryLocalization.SetAddressTypeInFreeForm(NewAddressStructure);
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		FieldValueAddress = ContactsManager.ContactInformationToXML(
			AddressValue,
			Address,
			Enums.ContactInformationTypes.Address);
		
	EndIf;
	
EndProcedure

// Gets addresses of delivery point owners and creates delivery points based on them
// 
// Parameters:
//  TransitionStart - Boolean - indicates the first launch at the beginning of the transition
//
Procedure GoToDelivery25(TransitionStart = False) Export
	
	If Not TransitionStart Then
		
		ScheduledJob = Metadata.ScheduledJobs.MigrationToDeliveryManagement25;
		Common.OnStartExecuteScheduledJob(ScheduledJob);
		
	EndIf;
	
	QueryText = QueryTextOfOwnersForCreatingDeliveryPoints();
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("TypeOfCIWarehouse", Catalogs.ContactInformationKinds.WarehouseAddress);
	Query.SetParameter("TypeOfCIPartner", Catalogs.ContactInformationKinds.PartnerAddress);
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("GoodsDelivery.GoToDelivery25");
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		If Not TransitionStart Then
			
			DisableRoutineTaskOfSwitchingToDelivery25();
			
		EndIf;
		
		NumberOfProcessedObjects = 0;
		
	Else
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			CreateDeliveryPointsByOwner(Selection.Ref);
			
		EndDo;
		
		NumberOfProcessedObjects = Selection.Count();
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedObjects);
	
EndProcedure

// Returns:
//  ValueTable - New Delivery Point Data:
// * Address - String -
// * AddressValue - String -
// * FieldValueAddress - String -
// * AddressID - String -
// * DeliveryPointID - String -
// * Description - String -
// * MainPoint - Boolean - 
// * NotUsed - Boolean - 
// * IDIsOverridden - Boolean - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryPoint - CatalogRef.DeliveryPoints - 
// * MatchedById - Boolean - 
// * SelectedAt - Boolean - 
// * UpdatingMainPoint - Boolean - 
// * SeveralMainAddresses - Boolean - 
//
Function NewDeliveryPointData() Export
	
	TypeStringUnlimited = Common.StringTypeDetails(0);
	TypeIdString = Common.StringTypeDetails(36);
	BooleanType = New TypeDescription("Boolean");
	
	Data = New ValueTable();
	Data.Columns.Add("Address", TypeStringUnlimited);
	Data.Columns.Add("AddressValue", TypeStringUnlimited);
	Data.Columns.Add("FieldValueAddress", TypeStringUnlimited);
	Data.Columns.Add("AddressID", TypeIdString);
	Data.Columns.Add("DeliveryPointID", TypeIdString);
	Data.Columns.Add("Description", Common.StringTypeDetails(150));
	Data.Columns.Add("MainPoint", BooleanType);
	Data.Columns.Add("NotUsed", BooleanType);
	Data.Columns.Add("IDIsOverridden", BooleanType);
	Data.Columns.Add("DeliveryZone", New TypeDescription("CatalogRef.DeliveryZones"));
	Data.Columns.Add("DeliveryPoint", New TypeDescription("CatalogRef.DeliveryPoints"));
	Data.Columns.Add("MatchedById", BooleanType);
	Data.Columns.Add("SelectedAt", BooleanType);
	Data.Columns.Add("UpdatingMainPoint", BooleanType);
	Data.Columns.Add("SeveralMainAddresses", BooleanType);
	
	Return Data;
	
EndFunction

// Parameters:
//  Owner - CatalogRef.Warehouses
//           - CatalogRef.Partners
//  PointData_ - ValueTableRow of See NewDeliveryPointData
//  SwitchingToDelivery25 - Boolean
// 
Procedure UpdateCreateDeliveryPoint(Owner, PointData_, SwitchingToDelivery25 = False) Export
	
	NewPoint = PointData_.DeliveryPoint.IsEmpty();
	
	If NewPoint Then
		
		PointObject = Catalogs.DeliveryPoints.CreateItem();
		
	Else
		
		PointObject = PointData_.DeliveryPoint.GetObject();
		
	EndIf;
	
	FillPropertyValues(PointObject, PointData_);
	
	PointObject.Owner = Owner;
	
	VersionComment = CommentOnDeliveryPointVersion(NewPoint, PointData_, SwitchingToDelivery25);
	If Not IsBlankString(VersionComment) Then
		
		PointObject.WriteDataHistory.VersionComment = VersionComment;
		
		AdditionalData = PointObject.WriteDataHistory.AdditionalData;
		AdditionalData.Insert("MainPoint", PointData_.MainPoint);
		
	EndIf;
	
	PointObject.Write();
	
EndProcedure

// Parameters:
//  Address - See NewDataAddresses
// 
// Returns:
//  Boolean
//
Function AddressIsEmpty(Address) Export
	
	AddressIsEmpty = False;
	
	If IsBlankString(Address.AddressValue)
		And IsBlankString(Address.Address)
		And IsBlankString(Address.FieldValueAddress) Then
		
		AddressIsEmpty = True;
		
	EndIf;
	
	Return AddressIsEmpty;
	
EndFunction

// Returns:
//  Structure - New Address Data:
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * Address - String - 
// * AddressValue - String - 
// * FieldValueAddress - String - 
// * Main - Boolean - 
//
Function NewDataAddresses() Export
	
	Result = New Structure;
	Result.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	Result.Insert("Address", "");
	Result.Insert("AddressValue", "");
	Result.Insert("FieldValueAddress", "");
	Result.Insert("Main", False);
	
	Return Result;
	
EndFunction

// Returns:
//  ValueTable:
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * Address - String - 
// * AddressValue - String - 
// * FieldValueAddress - String - 
// * Id - String - 
// * Main - Boolean -
//
Function NewAddressesData() Export
	
	DescriptionTypeUnlimitedString = Common.StringTypeDetails(0);
	
	Result = New ValueTable;
	Result.Columns.Add("DeliveryZone", New TypeDescription("CatalogRef.DeliveryZones"));
	Result.Columns.Add("Address", DescriptionTypeUnlimitedString);
	Result.Columns.Add("AddressValue", DescriptionTypeUnlimitedString);
	Result.Columns.Add("FieldValueAddress", DescriptionTypeUnlimitedString);
	Result.Columns.Add("Id", Common.StringTypeDetails(36));
	Result.Columns.Add("Main", New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

// Data of delivery points that are changed when the owner is recorded.
// 
// Parameters:
//  OwnerOfDeliveryPoints - CatalogRef.Partners -
//                        - CatalogRef.Warehouses -
//  FirstRecord - Boolean -
//  DataOfMainAddresses - See NewAddressesData
// 
// Returns:
//  See NewDeliveryPointData
//
Function DataOfDeliveryPointsForProcessing(OwnerOfDeliveryPoints, FirstRecord, DataOfMainAddresses) Export
	
	DataForProcessing_ = NewDeliveryPointData();
	SeveralMainAddresses = (DataOfMainAddresses.Count() > 1);
	DataOfOwnerSPoints = DataFromExistingDeliveryPoints(OwnerOfDeliveryPoints, FirstRecord);
	DataOfMainTD = DataOfMainDeliveryPoint(DataOfOwnerSPoints);
	MainTDIsFull = (DataOfMainTD <> Undefined);
	
	If SeveralMainAddresses Then
		
		MainTDHasBeenChanged = False;
		
		For Each PrimaryAddressData In DataOfMainAddresses Do
			
			AddDataToChangeFewBasic(
				DataForProcessing_,
				DataOfOwnerSPoints,
				PrimaryAddressData,
				MainTDHasBeenChanged);
			
		EndDo;
		
		If MainTDIsFull
		   And Not MainTDHasBeenChanged Then
			
			DataOfMainTD.MainPoint = False;
			DataOfMainTD.SeveralMainAddresses = True;
			AddDataToChange(DataForProcessing_, DataOfMainTD);
			
		EndIf;
		
	ElsIf DataOfMainAddresses.Count() = 1 Then
		
		PrimaryAddressData = DataOfMainAddresses[0];
		
		AddressProcessed = False;
		If MainTDIsFull Then
			
			AddDataToChangeOneMain(DataForProcessing_, DataOfOwnerSPoints, PrimaryAddressData, DataOfMainTD);
			AddressProcessed = DataOfMainTD.UpdatingMainPoint;
			
		EndIf;
		
		If Not AddressProcessed Then
			
			ChangeMainDeliveryPoint(DataForProcessing_, PrimaryAddressData, DataOfOwnerSPoints);
			
		EndIf;
		
	ElsIf MainTDIsFull Then
		
		DataOfMainTD.MainPoint = False;
		AddDataToChange(DataForProcessing_, DataOfMainTD);
		
	EndIf;
	
	DataForProcessing_.Sort("MainPoint Asc");
	
	Return DataForProcessing_;
	
EndFunction

// Parameters:
//  Address1 - ValueTableRow: See NewAddressesData
//  Address2 - ValueTableRow: See NewAddressesData
// 
// Returns:
//  Boolean
//
Function AddressesAreEqual(Address1, Address2) Export
	
	Result = False;
	
	If Not IsBlankString(Address1.AddressValue)
	   And Not IsBlankString(Address2.AddressValue) Then
		
		Result = (StrCompare(Address1.AddressValue, Address2.AddressValue) = 0);
		
	ElsIf Not IsBlankString(Address1.FieldValueAddress)
	   And Not IsBlankString(Address2.FieldValueAddress) Then
		
		Result = (StrCompare(Address1.FieldValueAddress, Address2.FieldValueAddress) = 0);
		
	ElsIf Not IsBlankString(Address1.Address)
	   And Not IsBlankString(Address2.Address) Then
		
		Result = (StrCompare(Address1.Address, Address2.Address) = 0);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  AddressesBefore - See NewAddressesData
//  AddressesAfter - See NewAddressesData
// 
// Returns:
//  Boolean -
//
Function AddressesChanged(AddressesBefore, AddressesAfter) Export
	
	AddressesChanged = False;
	
	If AddressesBefore.Count() <> AddressesAfter.Count() Then
		
		AddressesChanged = True;
		
	Else
		
		AddressesBefore.Sort("Id Desc");
		AddressesAfter.Sort("Id Desc");
		
		For IndexOf = 0 To AddressesBefore.Count() - 1 Do
			
			LineBefore = AddressesBefore[IndexOf];
			LineAfter = AddressesAfter[IndexOf];
			
			If (LineBefore.Main
					And LineAfter.Main)
				Or (IsBlankString(LineBefore.Id)
					And IsBlankString(LineAfter.Id)) Then
				
				LinesAreEqual = AddressesAreEqual(LineBefore, LineAfter);
				
			Else
				
				LinesAreEqual = (StrCompare(LineBefore.Id, LineAfter.Id) = 0);
				
			EndIf;
			
			If Not LinesAreEqual Then
				
				AddressesChanged = True;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return AddressesChanged;
	
EndFunction

// Parameters:
//  ObjectOwner - CatalogObject.Partners
//                 - CatalogObject.Warehouses -
// 
// Returns:
//  Boolean
//
Function FirstCreationOfDeliveryPoints(ObjectOwner) Export
	
	If ObjectOwner.IsNew() Then
		
		FirstRecord = True;
		
	Else
		
		QueryText =
		"SELECT TOP 1
		|	DeliveryPoints.Ref AS Ref
		|FROM
		|	Catalog.DeliveryPoints AS DeliveryPoints
		|WHERE
		|	DeliveryPoints.Owner = &Owner";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.Parameters.Insert("Owner", ObjectOwner.Ref);
		
		SetPrivilegedMode(True);
		
		QueryResult = Query.Execute();
		FirstRecord = QueryResult.IsEmpty();
		
	EndIf;
	
	Return FirstRecord;
	
EndFunction

// Parameters:
//  DeliveryPoint - CatalogRef.DeliveryPoints -
//  CheckWithBlocking - Boolean -
// 
// Returns:
//  Boolean -
//
Function PointIsUsedWhenPlanningDelivery(DeliveryPoint, CheckWithBlocking = False) Export
	
	QueryText =
	"SELECT TOP 1
	|	Delivery.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.Delivery AS Delivery
	|WHERE
	|	Delivery.SenderPoint = &DeliveryPoint
	|	OR Delivery.RecipientPoint = &DeliveryPoint";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DeliveryPoint", DeliveryPoint);
	
	DeliveryPointPresentation = String(DeliveryPoint);
	
	SetPrivilegedMode(True);
	
	If CheckWithBlocking Then
		
		Try
			
			Block = New DataLock();
			LockItem = Block.Add("AccumulationRegister.Delivery");
			LockItem.SetValue("SenderPoint", DeliveryPoint);
			LockItem.Mode = DataLockMode.Shared;
			LockItem = Block.Add("AccumulationRegister.Delivery");
			LockItem.SetValue("RecipientPoint", DeliveryPoint);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();
			
		Except
			
			Information = ErrorInfo();
			MessageTemplate = NStr("ru = 'Не удалось заблокировать записи регистра накопления Доставка по точке доставки ""%1""';
									|vi = 'Cannot lock the ""Delivery"" accumulation register records by the ""%1"" delivery point';
									|en = 'Cannot lock the ""Delivery"" accumulation register records by the ""%1"" delivery point'; fa = 'Cannot lock the ""Delivery"" accumulation register records by the ""%1"" delivery point';
									|it = 'Cannot lock the ""Delivery"" accumulation register records by the ""%1"" delivery point';
									|pl = 'Cannot lock the ""Delivery"" accumulation register records by the ""%1"" delivery point';
									|tr = '""%1"" teslimat noktasına göre Teslimat birikim kayıt tablosunun kayıtları kilitlenemedi'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				DeliveryPointPresentation);
			
			Refinement = CommonClientServer.ExceptionClarification(Information, MessageText);
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			Raise(Refinement.Text, Refinement.Category,, ErrorPresentation, Information);
			
		EndTry;
		
	EndIf;
	
	QueryResult = Query.Execute();
	
	DeliveryPointIsUsed = Not QueryResult.IsEmpty();
	
	Return DeliveryPointIsUsed;
	
EndFunction

// Address data according to contact information.
// 
// Parameters:
//  ContactInformationData - ValueTable:
//             * Presentation - String
//             * Value - String
//             * FieldValues - String
//             * DeliveryZone - CatalogRef.DeliveryZones
//             * Kind - CatalogRef.ContactInformationKinds
//           - Array of CatalogTabularSectionRow.Partners.ContactInformation
//           - Array of CatalogTabularSectionRow.Warehouses.ContactInformation
//  DeliveryZone - CatalogRef.DeliveryZones
// 
// Returns:
//  See NewAddressesData
//
Function AddressDataAccordingToContactInformation(ContactInformationData, DeliveryZone = Undefined) Export
	
	DataOfAddresses = NewAddressesData();
	
	If ValueIsFilled(DeliveryZone) Then
		
		DeliveryZoneToFillIn = DeliveryZone;
		
	Else
		
		DeliveryZoneToFillIn = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	For Each AddressLine In ContactInformationData Do
		
		DeliveryZoneData = New Structure("DeliveryZone", DeliveryZoneToFillIn);
		FillPropertyValues(DeliveryZoneData, AddressLine);
		
		AddressData = NewDataAddresses();
		
		AddressData.DeliveryZone = DeliveryZoneData.DeliveryZone;
		AddressData.Address = AddressLine.Presentation;
		AddressData.AddressValue = AddressLine.Value;
		AddressData.FieldValueAddress = AddressLine.FieldValues;
		
		If AddressLine.Kind = Catalogs.ContactInformationKinds.PartnerAddress
			Or AddressLine.Kind = Catalogs.ContactInformationKinds.WarehouseAddress Then
			
			AddressData.Main = True;
			
		EndIf;
		
		AddressIsEmpty = AddressIsEmpty(AddressData);
		If Not AddressIsEmpty Then
			
			AddressID = GoodsDeliveryLocalization.IdOfDeliveryPointAddress(AddressData.AddressValue);
			
			Filter = New Structure;
			Filter.Insert("Id", AddressID);
			
			If IsBlankString(AddressID) Then
				
				Filter.Insert("Address", AddressData.Address);
				
			EndIf;
			
			AddedRows = DataOfAddresses.FindRows(Filter);
			If AddedRows.Count() = 0 Then
				
				AddressLine = DataOfAddresses.Add();
				FillPropertyValues(AddressLine, AddressData);
				AddressLine.Id = AddressID;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return DataOfAddresses;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "11.5.27.26";
	Handler.Procedure = "GoodsDelivery.InitializingDeliverySupport25";
	Handler.ExecutionMode = "Exclusively";
	
EndProcedure

Procedure InitializingDeliverySupport25() Export
	
	If Constants.UseDeliveryManagement.Get() = True
	   And Constants.NotUseDeliveryManagement20.Get() = False Then
		
		Constants.NotUseDeliveryManagement25.Set(True);
		
	EndIf;
	
	If Constants.DeliveryPlanning.Get().IsEmpty() Then
		
		Constants.DeliveryPlanning.Set(Enums.DeliveryPlanningKinds.ByCurrentDocument);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Posting

// Parameters:
//  Ref - DefinedType.DeliveryPlanningDocument, DocumentRef.Trip - 
//  TypeOfPlanning - EnumRef.DeliveryPlanningKinds -
//                  - Undefined -
// 
// Returns:
//  Number - The level of operation of the document, taking into account the type of planning
//
Function LevelOfOperationOfDocument(Ref, TypeOfPlanning = Undefined) Export
	
	RefType = TypeOf(Ref);
	Result = -1;
	
	If RefType = Type("DocumentRef.SalesOrder")
	 Or RefType = Type("DocumentRef.CustomerInvoice")
	 Or RefType = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		If TypeOfPlanning = Enums.DeliveryPlanningKinds.SeparateDocument Then
			Result = 10;
		ElsIf TypeOfPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument Then
			Result = 15;
		EndIf;
		
	EndIf;
	
	If RefType = Type("DocumentRef.DeliveryOrder") Then
		
		Result = 20;
		
	EndIf;
	
	If RefType = Type("DocumentRef.Trip") Then
		
		Result = 30;
		
	EndIf;
	
	//@skip-check module-nstr-camelcase
	MessageTemplate = NStr("ru = 'Не удалось определить уровень операции документа.
						   |Переданные значения: Ссылка: ""%1"", ВидПланирования: ""%2""';
						   |vi = 'Cannot identify the document operation level.
						   |Passed values: Link: ""%1"", Planning kind: ""%2 ""';
						   |en = 'Cannot identify the document operation level.
						   |Passed values: Link: ""%1"", Planning kind: ""%2 ""'; fa = 'Cannot identify the document operation level.
						   |Passed values: Link: ""%1"", Planning kind: ""%2 ""';
						   |it = 'Cannot identify the document operation level.
						   |Passed values: Link: ""%1"", Planning kind: ""%2 ""';
						   |pl = 'Cannot identify the document operation level.
						   |Passed values: Link: ""%1"", Planning kind: ""%2 ""';
						   |tr = 'Belge işlem seviyesi belirlenemedi.  
						   |Aktarılan değerler: Bağlantı: ""%1"", PlanlamaTürü: ""%2""'");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		MessageTemplate,
		String(Ref),
		String(TypeOfPlanning));
	//@skip-check module-nstr-camelcase
	MessageContext = NStr("ru = 'ДоставкаТоваров.УровеньОперацииДокумента';
							|vi = 'Goods delivery. Document operation level';
							|en = 'Goods delivery. Document operation level'; fa = 'Goods delivery. Document operation level';
							|it = 'Goods delivery. Document operation level';
							|pl = 'Goods delivery. Document operation level';
							|tr = 'ДоставкаТоваров.УровеньОперацииДокумента'"); 
	CommonClientServer.Validate(
		Result >= 0,
		MessageText,
		MessageContext);
	
	Return Result;
	
EndFunction

// Parameters:
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the recording failed
//  WriteMode - DocumentWriteMode - the set document recording mode
//
Procedure BeforeWrite(Val Document, Cancel, Val WriteMode) Export
	
	If WriteMode <> DocumentWriteMode.Posting Then
		Return;
	EndIf;
	
	ExpectedDocumentTypes = New Array; // Array of Type
	ExpectedDocumentTypes.Add(Type("DocumentObject.SalesOrder"));
	ExpectedDocumentTypes.Add(Type("DocumentObject.CustomerInvoice"));
	ExpectedDocumentTypes.Add(Type("DocumentObject.GoodsShipmentToCustomer"));
	
	CommonClientServer.CheckParameter(
		"GoodsDelivery.BeforeWrite",
		"Document",
		Document,
		ExpectedDocumentTypes);
	
	If Document.IsNew()
		And CommonClientServer.HasAttributeOrObjectProperty(Document, "Patch")
		And Document.Patch Then
		
		DeliveryPlanning = Document.DeliveryPlanning;
		
	ElsIf Document.IsNew() Then
		
		DeliveryPlanning = Enums.DeliveryPlanningKinds.EmptyRef();
		
	Else
		
		DeliveryPlanning = Common.ObjectAttributeValue(
			Document.Ref,
			"DeliveryPlanning"); // EnumRef.DeliveryPlanningKinds
		
	EndIf;
	
	DeliveryData = New Structure;
	DeliveryData.Insert("PreviousTypeOfDeliveryPlanning", DeliveryPlanning);
	Document.AdditionalProperties.Insert("DeliveryData", DeliveryData);
	
EndProcedure

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		DocumentType = TypeOf(Document);
		
		If DocumentType = Type("DocumentObject.ReversingEntry")
			Or DocumentType = Type("DocumentObject.GoodsIssueNote") Then
			
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.Delivery);
			
		Else
			
			Parameters.ThereAreDerivedMotions = True;
			
		EndIf;
		
		If Properties.WriteMode <> DocumentWriteMode.Write Then
			
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.Delivery);
			
		EndIf;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
//  MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
//   Map of KeyAndValue - Contains the texts of the cancellation requests, where:
//    * Key - String - full name of the register.
//    * Value - String - query text.
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;
	
	RegisterMetadata = Metadata.AccumulationRegisters.Delivery;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		
		QueryTemplate =
		"SELECT
		|	DocumentsStorno.Ref AS Recorder,
		|	DocumentsStorno.Date AS Period,
		|	&SelectionFields1,
		|	TRUE AS ReversingEntry
		|FROM
		|	AccumulationRegister.Delivery AS RegisterData
		|		INNER JOIN &DocumentName AS DocumentsStorno
		|		ON RegisterData.Recorder = DocumentsStorno.ReversedDocument
		|			AND (DocumentsStorno.Ref IN (&Ref))
		|WHERE
		|	NOT RegisterData.ReversingEntry";
		
		ArrayOfSelectionFields = New Array; // Array of String
		Exceptions = New Array; // Array of String
		
		Exceptions.Add("Recorder");
		Exceptions.Add("Period");
		Exceptions.Add("ReversingEntry");
		Exceptions.Add("LineNumber");
		Exceptions.Add("Active");
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(
			RegisterMetadata.StandardAttributes,
			ArrayOfSelectionFields,
			Exceptions);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(
			RegisterMetadata.Dimensions,
			ArrayOfSelectionFields,
			Exceptions);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(
			RegisterMetadata.Resources,
			ArrayOfSelectionFields,
			Exceptions,
			True);
		
		SelectionFieldText = StrConcat(ArrayOfSelectionFields, "," + Chars.LF);
		QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
		QueryText = StrReplace(QueryText, "&DocumentName", MetadataOfDocument.FullName());
		
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
		
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - 
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	DocumentType = TypeOf(Document);
	If DocumentType <> Type("DocumentObject.ReversingEntry")
		And DocumentType <> Type("DocumentObject.GoodsIssueNote") Then
		
		// Due to the peculiarities of the mechanism of conducting, a double entry may occur.
		// To avoid such a situation, we explicitly indicate that PH Delivery is not written by the mechanism of Registering Recorded movements
		Document.RegisterRecords.Delivery.Write = False;
		
	EndIf;
	
EndProcedure

// Occurs after the document registers are recorded
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - 
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	RegisterName = "Delivery";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.AdditionalProperties = DocumentsPosting.DocumentProperties(Document);
	
	If AddlParameters.AdditionalProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		
		CancelDeliveryDocument(Document, RegisterName);
		
	Else
		
		GoodsLinesChangeOnlyPackaging = CommonClientServer.StructureProperty(
			Document.AdditionalProperties,
			"GoodsLinesChangeOnlyPackaging",
			New ValueTable); // ValueTable
		AddlParameters.Insert("GoodsLinesChangeOnlyPackaging", GoodsLinesChangeOnlyPackaging);
		
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(Document.Ref, RegisterName, AddlParameters);
		
		TableName = "Table" + RegisterName;
		HasTableData = TablesForRegisteredRecords.Property(TableName);
		
		If HasTableData Then
			
			DataTable = TablesForRegisteredRecords[TableName]; // ValueTable
			
			If DataTable.Columns.Find("Recorder") = Undefined Then
				
				DataTable.Columns.Add("Recorder");
				DataTable.FillValues(Document.Ref, "Recorder");
				
			EndIf;
			
		EndIf;
		
		PreviousTypeOfDeliveryPlanning = Enums.DeliveryPlanningKinds.EmptyRef();
		If TypeOf(Document) <> Type("DocumentObject.DeliveryOrder")
			And TypeOf(Document) <> Type("DocumentObject.Trip") Then
			
			PreviousTypeOfDeliveryPlanning = Document.AdditionalProperties.DeliveryData.PreviousTypeOfDeliveryPlanning; // EnumRef.DeliveryPlanningKinds
			
		EndIf;
		
		ArrayOfOFOperationLevels = New Array; // Array of Number
		DeleteStornoRegisteredRecords = True;
		
		If TypeOf(Document) = Type("DocumentObject.Trip") Then
			
			DeleteStornoRegisteredRecords = False;
			
		ElsIf TypeOf(Document) = Type("DocumentObject.DeliveryOrder") Then
			
			ArrayOfOFOperationLevels.Add(20);
			
		ElsIf Not Document.DeliveryIsRequired Then
			
			ArrayOfOFOperationLevels.Add(20);
			ArrayOfOFOperationLevels.Add(30);
			
		ElsIf Not PreviousTypeOfDeliveryPlanning.IsEmpty() Then
			
			PreviousOfOperationLevel = LevelOfOperationOfDocument(
				Document.Ref,
				PreviousTypeOfDeliveryPlanning);
			
			If PreviousOfOperationLevel = 10 Then
				
				ArrayOfOFOperationLevels.Add(20);
				
			ElsIf PreviousOfOperationLevel = 15 Then
				
				ArrayOfOFOperationLevels.Add(30);
				
			Else
				
				DeleteStornoRegisteredRecords = False;
				
			EndIf;
			
		Else
			
			// The document was not carried out, since the previous type of delivery planning is not specified
			DeleteStornoRegisteredRecords = False;
			
		EndIf;
		
		Query = New Query;
		QueryText =
		"SELECT
		|	Delivery.Recorder AS Recorder,
		|	Delivery.LineNumber AS LineNumber
		|FROM
		|	AccumulationRegister.Delivery AS Delivery
		|WHERE
		|	&DeleteStornoRegisteredRecords
		|	AND Delivery.ReversedPlan = &PlanningDocument
		|	AND Delivery.OperationLevel IN (&ArrayOfOFOperationLevels)
		|
		|UNION ALL
		|
		|SELECT
		|	Delivery.Recorder,
		|	Delivery.LineNumber
		|FROM
		|	AccumulationRegister.Delivery AS Delivery
		|WHERE
		|	Delivery.Recorder = &PlanningDocument";
		
		If GoodsLinesChangeOnlyPackaging.Count() > 0 Then
			
			QueryTextTTGoodsLinesChangeOnlyPackaging =
			"SELECT
			|	GoodsLinesChangeOnlyPackaging.ReferenceOrder AS ReferenceOrder,
			|	GoodsLinesChangeOnlyPackaging.DeliveryLineCode AS DeliveryLineCode
			|INTO TT_GoodsLinesChangeOnlyPackaging
			|FROM
			|	&GoodsLinesChangeOnlyPackaging AS GoodsLinesChangeOnlyPackaging";
			
			TextOfSelectionIsStornoOfRegisteredRecordedLineByLineWithChangeInPackaging =
			"SELECT
			|	Delivery.Recorder AS Recorder,
			|	Delivery.LineNumber AS LineNumber
			|FROM
			|	TT_GoodsLinesChangeOnlyPackaging AS GoodsLinesChangeOnlyPackaging
			|		INNER JOIN AccumulationRegister.Delivery AS Delivery
			|		ON GoodsLinesChangeOnlyPackaging.ReferenceOrder = Delivery.ReferenceOrder
			|			AND GoodsLinesChangeOnlyPackaging.DeliveryLineCode = Delivery.RowCode
			|WHERE
			|	Delivery.ReversedPlan = &PlanningDocument
			|	AND Delivery.OperationLevel = 30";
			
			QueryText = QueryTextTTGoodsLinesChangeOnlyPackaging
				+ Common.QueryBatchSeparator()
				+ QueryText
				+ TMCommonUse.QuerySeparatorInJoin()
				+ TextOfSelectionIsStornoOfRegisteredRecordedLineByLineWithChangeInPackaging;
			
			Query.SetParameter("GoodsLinesChangeOnlyPackaging", GoodsLinesChangeOnlyPackaging);
			
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Document, "Patch")
		   And Document.Patch Then
			
			TextOfSelectionIsStornoRegisteredRecordOfPreviousCorrections =
			"SELECT
			|	Delivery.Recorder AS Recorder,
			|	Delivery.LineNumber AS LineNumber
			|FROM
			|	InformationRegister.DocumentCorrections AS DocumentCorrections
			|		INNER JOIN AccumulationRegister.Delivery AS Delivery
			|		ON DocumentCorrections.PreviousCorrection = Delivery.ReversedPlan
			|WHERE
			|	DocumentCorrections.Recorder = &PlanningDocument
			|	AND DocumentCorrections.PreviousCorrection <> UNDEFINED
			|	AND Delivery.OperationLevel IN (&ArrayOfOFOperationLevels)
			|
			|UNION ALL
			|
			|SELECT
			|	Delivery.Recorder AS Recorder,
			|	Delivery.LineNumber AS LineNumber
			|FROM
			|	InformationRegister.DocumentCorrections AS DocumentCorrections
			|		INNER JOIN AccumulationRegister.Delivery AS Delivery
			|		ON DocumentCorrections.CorrectedDocument = Delivery.ReversedPlan
			|WHERE
			|	DocumentCorrections.Recorder = &PlanningDocument
			|	AND DocumentCorrections.PreviousCorrection = UNDEFINED
			|	AND DocumentCorrections.CorrectedDocument <> UNDEFINED
			|	AND Delivery.OperationLevel IN (&ArrayOfOFOperationLevels)";
			
			QueryText = QueryText
				+ TMCommonUse.QuerySeparatorInJoin()
				+ TextOfSelectionIsStornoRegisteredRecordOfPreviousCorrections;
			
		EndIf;
		
		Query.Text = QueryText;
		Query.SetParameter("PlanningDocument", Document.Ref);
		Query.SetParameter("ArrayOfOFOperationLevels", ArrayOfOFOperationLevels);
		Query.SetParameter("DeleteStornoRegisteredRecords", DeleteStornoRegisteredRecords);
		TableOfRecordsToDelete = Query.Execute().Unload();
		
		ArrayOfLoggers = TableOfRecordsToDelete.UnloadColumn("Recorder"); // Array of DocumentRef
		
		If HasTableData Then
			
			DataTable = TablesForRegisteredRecords[TableName]; // ValueTable
			RecordersOfActualRegisteredRecords = DataTable.UnloadColumn("Recorder"); // Array of DocumentRef
			CommonClientServer.SupplementArray(ArrayOfLoggers, RecordersOfActualRegisteredRecords, True);
			
		EndIf;
		
		If TableOfRecordsToDelete.Count() > 0 Then
			
			RecordSetToBeDeleted = AccumulationRegisters[RegisterName].CreateRecordSet();
			TempTableManager = DocumentsPosting.ManagerOfTemporaryControlTables(Document);
			DocumentsPosting.SetAdditionalRegisterProperties(RecordSetToBeDeleted, Document, TempTableManager, True);
			RecordSetToBeDeleted.AdditionalProperties.Insert("FixChangesAfterRecording", Not HasTableData);
			RecordSetToBeDeleted.AdditionalProperties.Insert("Recorders", ArrayOfLoggers);
			RecordSetToBeDeleted.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
			RecordSetToBeDeleted.ExtendedReplaceMode = True;
			RecordSetToBeDeleted.Filter.Recorder.Set(, False);
			RecordSetToBeDeleted.Load(TableOfRecordsToDelete);
			RecordSetToBeDeleted.Write(ReplacementMode.Delete);
			
		EndIf;
		
		If HasTableData Then
			
			SetOfRecordsToBeAdded = AccumulationRegisters[RegisterName].CreateRecordSet();
			TempTableManager = DocumentsPosting.ManagerOfTemporaryControlTables(Document);
			DocumentsPosting.SetAdditionalRegisterProperties(SetOfRecordsToBeAdded, Document, TempTableManager, True);
			SetOfRecordsToBeAdded.AdditionalProperties.Insert("FixChangesAfterRecording", True);
			SetOfRecordsToBeAdded.AdditionalProperties.Insert("Recorders", ArrayOfLoggers);
			SetOfRecordsToBeAdded.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
			SetOfRecordsToBeAdded.ExtendedReplaceMode = True;
			SetOfRecordsToBeAdded.Filter.Recorder.Set(, False);
			SetOfRecordsToBeAdded.Load(DataTable);
			SetOfRecordsToBeAdded.Write(ReplacementMode.Append);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure for the formation of Register Records for subordinate delivery registers.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "Delivery");
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of KeyAndValue:
//		* Key - String - The name of the temporary register change table.
//		* Value - String - query text.
//
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export
	
	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	NameOfControlTable = "RegisteredRecordsDeliveryChange";
	ThereAreChangesInDeliveryRegisteredRecords = DocumentsPosting.ThereAreRecordsInTable(Document, NameOfControlTable);
	If Not ThereAreChangesInDeliveryRegisteredRecords Then
		Return;
	EndIf;
	
	ControlTableParameters = Document.AdditionalProperties.DocumentsPosting.ControlTables[NameOfControlTable].Parameters; // See NewDeliveryControlTableParameters
	ControlDeviationOfMeasuredGoods = ControlTableParameters.ThereAreChangesInDimensionalGoods; // Boolean
	
	If ControlDeviationOfMeasuredGoods Then
		
		QueryTextPrimaryDeliveryAssignmentsForDimensional = QueryTextPrimaryDeliveryAssignmentsForDimensional();
		QueryTexts.Add(QueryTextPrimaryDeliveryAssignmentsForDimensional);
		
		QueryTextAcceptableDeviationsForTrip = QueryTextAcceptableDeviationsForTrip();
		QueryTexts.Add(QueryTextAcceptableDeviationsForTrip);
		
		ExpressionAcceptableDeviation = "ISNULL(AcceptableDeviationsOfDeliveryBalances.AllowableVariance, 0)";
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		Query.SetParameter(
			"AllowableDeviationOfMeasuringGoodsShipmentAndReceiving", AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
		
		DimensionalTypesOfUnits = Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits();
		Query.SetParameter("DimensionalTypesOfUnits", DimensionalTypesOfUnits);
		
	Else
		
		ExpressionAcceptableDeviation = "0";
		
	EndIf;
	
	If ControlTableParameters.ThereAreChangesToDeliveryForTrip Then
		
		QueryTextOfControlForDeliveryForTrip = DeliveryControlQueryText(
			"DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover",
			False,
			ExpressionAcceptableDeviation,
			ControlDeviationOfMeasuredGoods);
		QueryTexts.Add(QueryTextOfControlForDeliveryForTrip, "ControlErrorsForDeliveryToFlight");
		
	EndIf;
	
	If ControlTableParameters.ThereAreChangesToTripInTrip Then
		
		QueryTextOfControlForTripInTrip = DeliveryControlQueryText(
			"DeliveryTurnover.ToTripTurnover - DeliveryTurnover.InTripTurnover",
			True,
			ExpressionAcceptableDeviation,
			ControlDeviationOfMeasuredGoods);
		QueryTexts.Add(QueryTextOfControlForTripInTrip, "ControlErrorsForTripInTrip");
		
	EndIf;
	
	If ControlTableParameters.ThereAreBuildChanges Then
		
		QueryTextWarehouses = QueryTextForControlWarehouseParameters();
		QueryTexts.Add(QueryTextWarehouses);
		
		QueryTextPrimaryDeliveryRecords = QueryTextPrimaryDeliveryRecords();
		QueryTexts.Add(QueryTextPrimaryDeliveryRecords);
		
		If ControlDeviationOfMeasuredGoods Then
			
			QueryTextAcceptableDeviationsToKits = QueryTextAcceptableDeviationsToKits();
			QueryTexts.Add(QueryTextAcceptableDeviationsToKits);
			
		EndIf;
		
		QueryTextTurnoverOfKitsByOrder = QueryTextTurnoverOfKitsByOrder();
		QueryTexts.Add(QueryTextTurnoverOfKitsByOrder);
		
		QueryTextRevsForKitsOnTrip = QueryTextRevsForKitsOnTrip();
		QueryTexts.Add(QueryTextRevsForKitsOnTrip);
		
		QueryTextForControllingAmountOfKittingForTrip = QueryTextForControllingAmountOfKittingForTrip(
			ExpressionAcceptableDeviation,
			ControlDeviationOfMeasuredGoods);
		QueryTexts.Add(QueryTextForControllingAmountOfKittingForTrip, "ErrorsInControllingAmountOfKittingOnFlight");
		
		QueryTextForMonitoringTripStatuses = QueryTextForMonitoringTripStatuses(
			ExpressionAcceptableDeviation,
			ControlDeviationOfMeasuredGoods);
		QueryTexts.Add(QueryTextForMonitoringTripStatuses, "FlightEndControlErrors");
		
	EndIf;
	
EndProcedure

// Returns:
//  Structure - Delivery Control Table Parameters:
//  * ThereAreChangesToDeliveryForTrip - Boolean - Indicates whether there have been changes to the delivery or cruise resources
//  * ThereAreChangesToTripInTrip - Boolean - Indicates whether there have been changes to the TIME or Time resources
//  * ThereAreBuildChanges - Boolean - Indicates whether there have been changes to the assembly resources
//  * ThereAreChangesInDimensionalGoods - Boolean - A sign of the presence of measured goods in changes in Registered Records.
//
Function NewDeliveryControlTableParameters() Export
	
	ControlTableParameters = New Structure;
	ControlTableParameters.Insert("ThereAreChangesToDeliveryForTrip", False);
	ControlTableParameters.Insert("ThereAreChangesToTripInTrip", False);
	ControlTableParameters.Insert("ThereAreBuildChanges", False);
	ControlTableParameters.Insert("ThereAreChangesInDimensionalGoods", False);
	Return ControlTableParameters;
	
EndFunction

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes:
//    * ControlErrorsForDeliveryToFlight - ValueTable:
//      ** Organization - CatalogRef.Companies
//      ** Sender - CatalogRef.Warehouses, CatalogRef.Partners -
//      ** Recipient - CatalogRef.Partners
//      ** ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//      ** Products - CatalogRef.Products
//      ** Characteristic - CatalogRef.ItemsCharacteristics
//      ** Series - CatalogRef.ItemsBatches
//      ** Excess - Number
//      ** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//    * ControlErrorsForTripInTrip - ValueTable:
//      ** Organization - CatalogRef.Companies
//      ** Sender - CatalogRef.Warehouses, CatalogRef.Partners -
//      ** Recipient - CatalogRef.Partners
//      ** ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//      ** Products - CatalogRef.Products
//      ** Characteristic - CatalogRef.ItemsCharacteristics
//      ** Series - CatalogRef.ItemsBatches
//      ** Excess - Number
//      ** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//    * ErrorsInControllingAmountOfKittingOnFlight - ValueTable:
//      ** ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//      ** Products - CatalogRef.Products
//      ** Characteristic - CatalogRef.ItemsCharacteristics
//      ** Series - CatalogRef.ItemsBatches
//      ** Purpose - CatalogRef.Assignments
//      ** Trip - DocumentRef.Trip
//      ** Excess - Number
//      ** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//    * FlightEndControlErrors - ValueTable:
//      ** Sender - CatalogRef.Warehouses
//      ** ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//      ** Products - CatalogRef.Products
//      ** Characteristic - CatalogRef.ItemsCharacteristics
//      ** Series - CatalogRef.ItemsBatches
//      ** Trip - DocumentRef.Trip
//      ** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//      ** Excess - Number
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If ControlResults.Property("ControlErrorsForDeliveryToFlight")
	   And ValueIsFilled(ControlResults.ControlErrorsForDeliveryToFlight) Then
		
		ControlResults.ControlErrorsForDeliveryToFlight.GroupBy(
			"Sender,ReferenceOrder,Products,Characteristic,Series,UnitOfMeasure",
			"Excess");
		
		For Each ErrorString In ControlResults.ControlErrorsForDeliveryToFlight Do
			
			If TypeOf(ErrorString.Sender) = Type("CatalogRef.Warehouses") Then
				
				MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 со склада %3 запланировано к рейсу больше, чем требуется доставить, на %4 %5';
										|vi = 'Under the %1 reference, the %2 item from the %3 warehouse is scheduled for the trip in excess of the required delivery by %4 %5';
										|en = 'Under the %1 reference, the %2 item from the %3 warehouse is scheduled for the trip in excess of the required delivery by %4 %5'; fa = 'Under the %1 reference, the %2 item from the %3 warehouse is scheduled for the trip in excess of the required delivery by %4 %5';
										|it = 'Under the %1 reference, the %2 item from the %3 warehouse is scheduled for the trip in excess of the required delivery by %4 %5';
										|pl = 'Under the %1 reference, the %2 item from the %3 warehouse is scheduled for the trip in excess of the required delivery by %4 %5';
										|tr = '%3 ambarından %2 malının %1 talimatına göre sefere planlanan miktar, teslim edilmesi gereken miktardan %4 %5 fazla'");
				
			Else
				
				MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 от перевозчика %3 запланировано к рейсу больше, чем требуется доставить, на %4 %5';
										|vi = 'Under the %1 reference, the %2 item from the %3 carrier is scheduled for the trip in excess of the required delivery by %4 %5';
										|en = 'Under the %1 reference, the %2 item from the %3 carrier is scheduled for the trip in excess of the required delivery by %4 %5'; fa = 'Under the %1 reference, the %2 item from the %3 carrier is scheduled for the trip in excess of the required delivery by %4 %5';
										|it = 'Under the %1 reference, the %2 item from the %3 carrier is scheduled for the trip in excess of the required delivery by %4 %5';
										|pl = 'Under the %1 reference, the %2 item from the %3 carrier is scheduled for the trip in excess of the required delivery by %4 %5';
										|tr = '%3 taşıyıcısından %2 malının %1 talimatına göre sefere planlanan miktar, teslim edilmesi gereken miktardan %4 %5 fazla'");
				
			EndIf;
			
			PresentationsOfFields = PresentationOfControlResultFields(ErrorString);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PresentationsOfFields.ReferenceOrder,
				PresentationsOfFields.Products,
				PresentationsOfFields.Sender,
				PresentationsOfFields.Excess,
				PresentationsOfFields.UnitOfMeasure);
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	If ControlResults.Property("ControlErrorsForTripInTrip")
	   And ValueIsFilled(ControlResults.ControlErrorsForTripInTrip) Then
		
		ControlResults.ControlErrorsForTripInTrip.GroupBy(
			"Sender,Recipient,ReferenceOrder,Products,Characteristic,Series,UnitOfMeasure",
			"Excess");
		
		For Each ErrorString In ControlResults.ControlErrorsForTripInTrip Do
			
			If TypeOf(ErrorString.Sender) = Type("CatalogRef.Warehouses") Then
				
				MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 со склада %3 для получателя %4 в рейсы включено больше, чем запланировано, на %5 %6';
										|vi = 'Under the %1 reference, the %2 item from the %3 warehouse for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|en = 'Under the %1 reference, the %2 item from the %3 warehouse for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6'; fa = 'Under the %1 reference, the %2 item from the %3 warehouse for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|it = 'Under the %1 reference, the %2 item from the %3 warehouse for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|pl = 'Under the %1 reference, the %2 item from the %3 warehouse for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|tr = '%3 ambarından %4 alıcısı için %2 ürününün %1 talimatına göre seferlere dahil edilen miktar, planlanan miktardan %5 %6 fazla'");
				
			Else
				
				MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 от перевозчика %3 для получателя %4 в рейсы включено больше, чем запланировано, на %5 %6';
										|vi = 'Under the %1 reference, the %2 item from the %3 carrier for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|en = 'Under the %1 reference, the %2 item from the %3 carrier for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6'; fa = 'Under the %1 reference, the %2 item from the %3 carrier for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|it = 'Under the %1 reference, the %2 item from the %3 carrier for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|pl = 'Under the %1 reference, the %2 item from the %3 carrier for the %4 recipient is included in the trips in excess of the planned quantity by %5 %6';
										|tr = '%3 taşıyıcısından %4 alıcısı için %2 malının %1 talimatına göre seferlere dahil edilen miktar, planlanan miktardan %5 %6 fazla'");
				
			EndIf;
			
			PresentationsOfFields = PresentationOfControlResultFields(ErrorString);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PresentationsOfFields.ReferenceOrder,
				PresentationsOfFields.Products,
				PresentationsOfFields.Sender,
				PresentationsOfFields.Recipient,
				PresentationsOfFields.Excess,
				PresentationsOfFields.UnitOfMeasure);
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	If ControlResults.Property("ErrorsInControllingAmountOfKittingOnFlight")
	   And ValueIsFilled(ControlResults.ErrorsInControllingAmountOfKittingOnFlight) Then
		
		ControlResults.ErrorsInControllingAmountOfKittingOnFlight.GroupBy(
			"ReferenceOrder,Trip,Products,Characteristic,Series,Purpose,UnitOfMeasure",
			"Excess");
		
		For Each ErrorString In ControlResults.ErrorsInControllingAmountOfKittingOnFlight Do
			
			MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 планируется к отгрузке больше, чем в рейсе %3, на %4 %5';
									|vi = 'Under the %1 reference, the %2 item is scheduled for shipment in excess of the %3 trip by %4 %5';
									|en = 'Under the %1 reference, the %2 item is scheduled for shipment in excess of the %3 trip by %4 %5'; fa = 'Under the %1 reference, the %2 item is scheduled for shipment in excess of the %3 trip by %4 %5';
									|it = 'Under the %1 reference, the %2 item is scheduled for shipment in excess of the %3 trip by %4 %5';
									|pl = 'Under the %1 reference, the %2 item is scheduled for shipment in excess of the %3 trip by %4 %5';
									|tr = '%1 talimatına göre %2 malının sevkiyata planlanan miktarı, %3  seferindeki miktardan %4 %5 fazla'");
			
			PresentationsOfFields = PresentationOfControlResultFields(ErrorString);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PresentationsOfFields.ReferenceOrder,
				PresentationsOfFields.Products,
				PresentationsOfFields.Trip,
				PresentationsOfFields.Excess,
				PresentationsOfFields.UnitOfMeasure);
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	If ControlResults.Property("FlightEndControlErrors")
	   And ValueIsFilled(ControlResults.FlightEndControlErrors) Then
		
		For Each ErrorString In ControlResults.FlightEndControlErrors Do
			
			PresentationsOfFields = PresentationOfControlResultFields(ErrorString);
			
			If ErrorString.Excess > 0 Then
				
				MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 собрано больше, чем указано в рейсе, на %3 %4';
										|vi = 'Under the %1 reference, the %2 item is picked in excess of the trip by %3 %4';
										|en = 'Under the %1 reference, the %2 item is picked in excess of the trip by %3 %4'; fa = 'Under the %1 reference, the %2 item is picked in excess of the trip by %3 %4';
										|it = 'Under the %1 reference, the %2 item is picked in excess of the trip by %3 %4';
										|pl = 'Under the %1 reference, the %2 item is picked in excess of the trip by %3 %4';
										|tr = '%1 talimatına göre toplanan %2  malı, seferde belirtilenden %3 %4 fazla'");
				Deviation = ErrorString.Excess;
				
			Else
				
				MessageTemplate = NStr("ru = 'По распоряжению %1 товара %2 собрано меньше, чем указано в рейсе, на %3 %4';
										|vi = 'Under the %1 reference, the %2 item is picked less than specified in the trip by %3 %4';
										|en = 'Under the %1 reference, the %2 item is picked less than specified in the trip by %3 %4'; fa = 'Under the %1 reference, the %2 item is picked less than specified in the trip by %3 %4';
										|it = 'Under the %1 reference, the %2 item is picked less than specified in the trip by %3 %4';
										|pl = 'Under the %1 reference, the %2 item is picked less than specified in the trip by %3 %4';
										|tr = '%1 talimatına göre toplanan %2 malı, seferde belirtilenden %3 %4 az'");
				Deviation = -ErrorString.Excess;
				
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PresentationsOfFields.ReferenceOrder,
				PresentationsOfFields.Products,
				Format(Deviation, "NG=0;"),
				PresentationsOfFields.UnitOfMeasure);
			
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Prepares the final document reflection requests for the delivery register.
// 
// Parameters:
//  Query - Query - Request for document reflection:
//   * Parameters - Structure - The required parameters must be set:
//    ** Ref - DocumentRef
//    ** OperationLevel - Number
//    ** IsNew - Boolean
//    ** GoodsLinesChangeOnlyPackaging - ValueTable
//  Registers - Undefined, Structure, String - List of registers to reflect
//  QueryTexts - ValueList of String - List of document reflection Query Text
//  QueryTextDocument_ - String - Query Text for document data selection
//  SynonymForDocumentTable - String - Synonym of the main table in the text of the document request
//
Procedure AddDocumentReflectionRequest(Query, Registers, QueryTexts, QueryTextDocument_, SynonymForDocumentTable) Export
	
	ThereAreLinesOfGoodsChangingOnlyPackagingUnits = Query.Parameters.Property("GoodsLinesChangeOnlyPackaging");
	
	ReflectionTemplateTexts = New Structure();
	TextsOfDocumentDataRequests = New Structure();
	TemporaryTableQueryTexts_ = New Structure();
	
	TextsOfDocumentDataRequests.Insert(SynonymForDocumentTable, QueryTextDocument_);
	
	// Comparison with the previous planning level
	
	QueryText = QueryTextTTCurrentLevelT2();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTCurrentLevelT2", QueryText);
	
	QueryText = QueryTextTTSelectionOfDeliveryOfPreviousLevel();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTSelectionOfDeliveryOfPreviousLevel", QueryText);
	
	QueryText = QueryTextTTPreviousLevelT1();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTPreviousLevelT1", QueryText);
	
	QueryText = QueryTextTTShouldersOfPreviousLevelT1();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTShouldersOfPreviousLevelT1", QueryText);
	
	QueryText = QueryTextTTKeyFieldsOfCurrentT2Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTKeyFieldsOfCurrentT2Level", QueryText);
	
	QueryText = QueryTextTTMissingShouldersOfCurrentT2Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTMissingShouldersOfCurrentT2Level", QueryText);
	
	QueryText = QueryTextTTCurrentLevelT2_ShoulderPadding();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTCurrentLevelT2_AdditionOfShoulders", QueryText);
	
	QueryText = QueryTextTTShouldersOfCurrentT2Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTShouldersOfCurrentT2Level", QueryText);
	
	QueryText = QueryTextTTKeyFieldsOfPreviousLevelT1();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTKeyFieldsOfPreviousLevelT1", QueryText);
	
	QueryText = QueryTextTTMissingShouldersOfPreviousLevelT1();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTMissingShouldersOfPreviousT1Level", QueryText);
	
	QueryText = QueryTextTTPreviousLevelT1_ShoulderPadding();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTPreviousLevelT1_AdditionOfShoulders", QueryText);
	
	QueryText = QueryTextTTControlOfChangeOfFieldsOfCurrentLevel();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTControlOfChangesInFieldsOfCurrentLevel", QueryText);
	
	QueryText = QueryTextTTComparisonOfCurrentLevelWithPreviousOne();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTComparisonOfCurrentLevelWithPreviousOne", QueryText);
	
	// Comparison with the next level of planning
	
	QueryText = QueryTextTTCurrentT1Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTCurrentLevelT1", QueryText);
	
	If ThereAreLinesOfGoodsChangingOnlyPackagingUnits Then
		
		QueryText = QueryTextTTGoodsLinesChangeOnlyPackaging();
		TemporaryTableQueryTexts_.Insert("TTGoodsRowChangeOnlyPackagingUnits", QueryText);
		
	EndIf;
	
	QueryText = QueryTextTTNextLevelDeliverySelection(ThereAreLinesOfGoodsChangingOnlyPackagingUnits);
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("NextLevelDeliveryTTSelection", QueryText);
	
	QueryText = QueryTextTTIsNextLevelT2();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTIsNextLevelOfT2", QueryText);
	
	QueryText = QueryTextTTShouldersOfCurrentT1Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTShouldersOfCurrentT1Level", QueryText);
	
	QueryText = QueryTextTTKeyFieldsOfNextLevelT2();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTKeyFieldsOfNextLevelT2", QueryText);
	
	QueryText = QueryTextTTMissingShouldersOfNextLevelT2();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTMissingShouldersOfNextLevelT2", QueryText);
	
	QueryText = QueryTextTTNextLevelT2_ShoulderPadding();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTNextLevelT2_AdditionOfShoulders", QueryText);
	
	QueryText = QueryTextTTShouldersOfNextLevelT2();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTShouldersOfNextLevelT2", QueryText);
	
	QueryText = QueryTextTTKeyFieldsOfCurrentT1Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTKeyFieldsOfCurrentT1Level", QueryText);
	
	QueryText = QueryTextTTMissingShouldersOfCurrentT1Level();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTMissingShouldersOfCurrentT1Level", QueryText);
	
	QueryText = QueryTextTTCurrentLevelT1_ShoulderPadding();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTCurrentLevelT1_AdditionOfShoulders", QueryText);
	
	QueryText = QueryTextTTControlOfChangeOfFieldsOfNextLevel();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTControlOfChangeOfFieldsOfNextLevel", QueryText);
	
	QueryText = QueryTextTTComparisonOfCurrentLevelWithNext();
	SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable);
	TemporaryTableQueryTexts_.Insert("TTComparisonOfCurrentLevelWithNext", QueryText);
	
	// The formation of Registered Records with storno
	
	DeliveryRequestTemplate = DeliveryRequestTemplate();
	SubstituteSynonymForDocumentTable(DeliveryRequestTemplate, SynonymForDocumentTable);
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("Delivery", Registers) Then
		ReflectionTemplateTexts.Insert("Delivery", DeliveryRequestTemplate);
	EndIf;
	
	DocumentsPosting.AddDocumentReflectionRequest(
		Query,
		QueryTexts,
		ReflectionTemplateTexts,
		TextsOfDocumentDataRequests,
		TemporaryTableQueryTexts_);
	
EndProcedure

// Parameters:
//  Query - Query
//  AddlParameters - See DocumentsPosting.AdditionalParametersDocumentDataForPosting
//
Procedure SetParametersOfEventRequest(Query, AddlParameters = Undefined) Export
	
	AdditionalProperties = CommonClientServer.StructureProperty(AddlParameters, "AdditionalProperties"); // Structure
	IsNew = CommonClientServer.StructureProperty(AdditionalProperties, "IsNew", False);
	Query.SetParameter("IsNew", IsNew);
	
	GoodsLinesChangeOnlyPackaging = CommonClientServer.StructureProperty(AddlParameters, "GoodsLinesChangeOnlyPackaging"); // See the line Item changespackaging
	If GoodsLinesChangeOnlyPackaging <> Undefined
	   And TypeOf(GoodsLinesChangeOnlyPackaging) = Type("ValueTable")
	   And GoodsLinesChangeOnlyPackaging.Count() > 0 Then
		
		Query.SetParameter("GoodsLinesChangeOnlyPackaging", GoodsLinesChangeOnlyPackaging);
		
	EndIf;
	
	ThereAreLinesOfGoodsChangingOnlyPackagingUnits = Query.Parameters.Property("GoodsLinesChangeOnlyPackaging");
	
	CurrentLevelOfOperation = Query.Parameters.OperationLevel;
	PreviousLevelsOfOperation = PreviousLevelsOfOperation(CurrentLevelOfOperation);
	Query.SetParameter("PreviousLevelsOfOperation", PreviousLevelsOfOperation);
	NextLevelsOfOperation = NextLevelsOfOperation(CurrentLevelOfOperation, ThereAreLinesOfGoodsChangingOnlyPackagingUnits);
	Query.SetParameter("NextLevelsOfOperation", NextLevelsOfOperation);
	
	If Not Query.Parameters.Property("Patch") Then
		Query.SetParameter("Patch", False);
	EndIf;
	
	If AddlParameters.Property("PreviousCorrection") Then
		
		PreviousCorrection = AddlParameters.PreviousCorrection;
		
	ElsIf Query.Parameters.Patch Then
		
		RequestPreviousCorrection = New Query;
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DocumentCorrections.PreviousCorrection <> UNDEFINED
		|			THEN DocumentCorrections.PreviousCorrection
		|		ELSE DocumentCorrections.CorrectedDocument
		|	END AS PreviousCorrection
		|FROM
		|	InformationRegister.DocumentCorrections AS DocumentCorrections
		|WHERE
		|	DocumentCorrections.Recorder = &Ref";
		RequestPreviousCorrection.Text = QueryText;
		RequestPreviousCorrection.SetParameter("Ref", Query.Parameters.Ref);
		
		Selection = RequestPreviousCorrection.Execute().Select();
		If Selection.Next() Then
			PreviousCorrection = Selection.PreviousCorrection; // DocumentRef
		Else
			PreviousCorrection = Query.Parameters.CorrectedDocument;
		EndIf;
		
	Else
		
		PreviousCorrection = Query.Parameters.Ref;
		
	EndIf;
	
	Query.SetParameter("PreviousCorrection", PreviousCorrection);
	
EndProcedure

#EndRegion

#Region Other

// Returns:
//  EnumRef.DeliveryPlanningKinds
//
Function TypeOfDeliveryPlanningAtSystemLevel() Export
	
	SetPrivilegedMode(True);
	SettingValue = Constants.DeliveryPlanning.Get();
	
	Return SettingValue;
	
EndFunction

// Returns the delivery planning view from the agreement with the client, if it is filled in. Otherwise - from a partner.
// If the delivery planning type is not filled in either in the agreement or in the partner, returns the value of the system setting.
//
// Parameters:
//  Partner - CatalogRef.Partners -
//  Terms - CatalogRef.TermsOfSale -
// 
// Returns:
//  EnumRef.DeliveryPlanningKinds -
//
Function TypeOfDeliveryPlanningByPartnerAgreement(Partner, Terms) Export
	
	SourcesOfSettings = New Array; // Array of CatalogRef.Partners, CatalogRef.TermsOfSale
	SourcesOfSettings.Add(Partner);
	SourcesOfSettings.Add(Terms);
	
	TypesOfPlanning = Common.ObjectsAttributeValue(SourcesOfSettings, "DeliveryPlanning");
	
	If ValueIsFilled(TypesOfPlanning[Terms]) Then
		
		DeliveryPlanning = TypesOfPlanning[Terms];
		
	ElsIf ValueIsFilled(TypesOfPlanning[Partner]) Then 
		
		DeliveryPlanning = TypesOfPlanning[Partner];
		
	Else
		
		DeliveryPlanning = TypeOfDeliveryPlanningAtSystemLevel();
		
	EndIf;
	
	Return DeliveryPlanning;
	
EndFunction

// Parameters:
//  VerificationInTransaction - Boolean
// 
// Returns:
//   Structure:
//   * TransitionIsAvailable - Boolean -
//   * ThereAreLeftoversToBeShipped - Boolean
//   * ThereAreWarehousesForKitsAfterDelivery - Boolean -
//
Function CheckPossibilityOfSwitchingToDelivery25(VerificationInTransaction = False) Export
	
	DataForTransportationTasks = DataForTransportationTasksWithoutDeliveryMark();
	
	If DataForTransportationTasks.DocumentsCount > 0 Then
		
		EventName = NStr("ru = 'Переход на управление доставкой 2.5';
						|vi = 'Migration to delivery management 2.5';
						|en = 'Migration to delivery management 2.5'; fa = 'مهاجرت به مدیریت تحویل 2.5';
						|it = 'Migration to delivery management 2.5';
						|pl = 'Migration to delivery management 2.5';
						|tr = 'Teslimat 2.5 yönetimine geçiş'", Common.DefaultLanguageCode());
		
		MessageTemplate = NStr("ru = 'Перед началом перехода на управление доставкой 2.5 найдено %1 закрытых заданий на перевозку, в которых не отмечена доставка по всем пунктам маршрута (флаг ""Все товары по пункту маршрута доставлены""):
									 |%2';
									 |vi = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
									 |%2';
									 |en = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
									 |%2'; fa = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
									 |%2';
									 |it = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
									 |%2';
									 |pl = 'Before migrating to delivery management 2.5, %1 closed itineraries are found where delivery to all route points is not marked (the ""All goods delivered to route point"" checkbox):
									 |%2';
									 |tr = 'Teslimat 2.5 yönetimine geçiş başlatılmadan önce, tüm rota noktalarındaki teslimat işaretlenmemiş (""Rota noktasına ait tüm mallar teslim edildi"" bayrağı) kapalı taşıma görevi %1  adet bulundu: 
									 | %2'");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			Format(DataForTransportationTasks.DocumentsCount, "NG=0"),
			DataForTransportationTasks.DocumentsInfo);
		
		WriteLogEvent(EventName, EventLogLevel.Warning,,, MessageText);
		
	EndIf;
	
	CheckResult = New Structure;
	CheckResult.Insert("TransitionIsAvailable", True);
	CheckResult.Insert("ThereAreLeftoversToBeShipped", False);
	CheckResult.Insert("ThereAreWarehousesForKitsAfterDelivery", False);
	
	CheckResult.ThereAreLeftoversToBeShipped = ThereAreLeftoversToBeShippedBeforeEndOfTransitionToDelivery25(VerificationInTransaction);
	If Not CheckResult.ThereAreLeftoversToBeShipped Then
		
		RegistrationProcedure = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
		If RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst Then
			
			CheckResult.ThereAreWarehousesForKitsAfterDelivery = ThereAreWarehousesWithKitsForPostDelivery(VerificationInTransaction);
			
		EndIf;
		
	EndIf;
	
	If CheckResult.ThereAreLeftoversToBeShipped
	 Or CheckResult.ThereAreWarehousesForKitsAfterDelivery Then
		
		CheckResult.TransitionIsAvailable = False;
		
	EndIf;
	
	Return CheckResult;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions
Procedure CustomizeReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.PickingUnderTrip);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.InvoicesByTripReferences);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.StateOfDelivery);
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.TripRoute);
	
EndProcedure

Function Delivery25WasUsed() Export
	
	QueryText =
	"SELECT TOP 1
	|	Delivery.LineNumber AS LineNumber
	|FROM
	|	AccumulationRegister.Delivery AS Delivery";
	
	Query = New Query;
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	ThereAreRegisteredRecords = Not QueryResult.IsEmpty();
	
	Return ThereAreRegisteredRecords;
	
EndFunction

// Returns:
//  Structure - Data For Transportation Tasks Without A Delivery Mark:
// * DocumentsCount - Number - 
// * DocumentsInfo - String - 
//
Function DataForTransportationTasksWithoutDeliveryMark() Export
	
	Result = New Structure;
	Result.Insert("DocumentsCount", 0);
	Result.Insert("DocumentsInfo", "");
	
	QueryText =
	"SELECT
	|	COUNT(DISTINCT TaskForTransportationRoute.Ref) AS DocumentsCount
	|FROM
	|	Document.TransportationJob.Route AS TaskForTransportationRoute
	|WHERE
	|	TaskForTransportationRoute.Ref.Posted
	|	AND TaskForTransportationRoute.Ref.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|	AND NOT TaskForTransportationRoute.Delivered
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 5
	|	TaskForTransportationRoute.Ref AS TransportationJob,
	|	TaskForTransportationRoute.Ref.Date AS Date
	|FROM
	|	Document.TransportationJob.Route AS TaskForTransportationRoute
	|WHERE
	|	TaskForTransportationRoute.Ref.Posted
	|	AND TaskForTransportationRoute.Ref.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|	AND NOT TaskForTransportationRoute.Delivered
	|
	|ORDER BY
	|	Date";
	
	Query = New Query;
	Query.Text = QueryText;
	
	QueryResults = Query.ExecuteBatch();
	
	SampleQuantity = QueryResults[0].Select();
	SampleQuantity.Next();
	DocumentsCount = SampleQuantity.DocumentsCount; // Number
	
	Result.DocumentsCount = DocumentsCount;
	
	LinksToDocuments = QueryResults[1].Unload().UnloadColumn("TransportationJob");
	NumberOfSelectedDocuments = LinksToDocuments.Count();
	If NumberOfSelectedDocuments > 0 Then
		
		PresentationMap = Common.SubjectAsString(LinksToDocuments);
		PresentationsOfDocuments = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
			PresentationMap,
			False);
		
		DocumentsByLine = StrConcat(PresentationsOfDocuments, Chars.LF);
		
	EndIf;
	
	If DocumentsCount > NumberOfSelectedDocuments Then
		
		QuantityOptional = DocumentsCount - NumberOfSelectedDocuments;
		TemplateExtension = NStr("ru = '%1 (и еще %2)';
								|vi = '%1 (and %2 more)';
								|en = '%1 (and %2 more)'; fa = '%1 (and %2 more)';
								|it = '%1 (and %2 more)';
								|pl = '%1 (and %2 more)';
								|tr = '%1(ve %2 diğer)'");
		DocumentsByLine = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateExtension,
			DocumentsByLine,
			Format(QuantityOptional, "NG=0;"));
		
	EndIf;
	
	Result.DocumentsInfo = DocumentsByLine;
	
	Return Result;
	
EndFunction

// Parameters:
//  VerificationInTransaction - Boolean -
// 
// Returns:
//  Boolean -
//
Function ThereAreWarehousesWithKitsForPostDelivery(VerificationInTransaction = False) Export
	
	If VerificationInTransaction Then
		
		Try
			
			Block = New DataLock();
			LockItem = Block.Add("Catalog.Warehouses");
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
		Except
			
			Raise;
			
		EndTry;
		
	EndIf;
	
	QueryText =
	"SELECT TOP 1
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.StartShipmentOnceDeliveryOrderIsCreated";
	
	Query = New Query;
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	WarehousesFound = Not QueryResult.IsEmpty();
	
	Return WarehousesFound;
	
EndFunction

// Parameters:
//  Owner - CatalogRef.Partners -
//           - CatalogRef.Warehouses -
// 
// Returns:
//  Boolean -
//
Function ThereAreActiveDeliveryPoints(Owner) Export
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	DeliveryPoints.Ref AS Ref
	|FROM
	|	Catalog.DeliveryPoints AS DeliveryPoints
	|WHERE
	|	DeliveryPoints.Owner = &Owner
	|	AND NOT DeliveryPoints.NotUsed";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Owner", Owner);
	QueryResult = Query.Execute();
	
	ThereAreExistingTDS = Not QueryResult.IsEmpty();
	
	Return ThereAreExistingTDS;
	
EndFunction

// Parameters:
//  DocumentDeliveries - DefinedType.DeliveryPlanningDocument
// 
// Returns:
//  See AddlParameters
//
Function AdditionalParametersFromDocumentHeader(DocumentDeliveries) Export
	
	AddlParameters = AddlParameters();
	
	QueryText =
	"SELECT
	|	DocumentHeader.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentHeader.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
	|	&AdditionalInformationField AS AdditionalDeliveryInformation
	|FROM
	|	&DocumentTable AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref = &DocumentDeliveries";
	
	DocumentTable = DocumentDeliveries.Metadata().FullName();
	QueryText = StrReplace(QueryText, "&DocumentTable", DocumentTable);
	
	If TypeOf(DocumentDeliveries) = Type("DocumentRef.DeliveryOrder") Then
		AdditionalInformationField = "DocumentHeader.AdditionalInformation";
	Else
		AdditionalInformationField = "DocumentHeader.AdditionalDeliveryInformation";
	EndIf;
	QueryText = StrReplace(QueryText, "&AdditionalInformationField", AdditionalInformationField);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentDeliveries", DocumentDeliveries);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		FillPropertyValues(AddlParameters, Selection);
		
	EndIf;
	
	Return AddlParameters;
	
EndFunction

// Parameters:
//  DeliveryDocuments - Array of DefinedType.DeliveryPlanningDocument, DefinedType.DeliveryReferenceOrder25 -
//  FilterParameters - Structure:
//  * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//  * Sender - CatalogRef.Warehouses, CatalogRef.Partners - 
//  * DeliveryMethod - EnumRef.TransportMethods25
//  * Recipient - CatalogRef.Partners
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  * DateOfShipment - Date
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * Series - CatalogRef.ItemsBatches
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure
//  UseSelectionByGoods - Boolean
// 
// Returns:
//  See AddlParameters
//
Function MatchingAdditionalParametersFromDocumentStrings(DeliveryDocuments, FilterParameters, UseSelectionByGoods) Export
	
	AddlParameters = AddlParameters();
	
	OptionsForAdditionalParameters = AllAdditionalParametersFromDocumentStrings(DeliveryDocuments, FilterParameters, UseSelectionByGoods);
	
	If OptionsForAdditionalParameters.Count() = 1 Then
		
		FillPropertyValues(AddlParameters, OptionsForAdditionalParameters[0]);
		
	Else
		
		ColumnsWithoutRows = "SpecialTransportationConditions,SpecialConditionsOfCarriageDescriptionHash,DeliveryTimeFrom,DeliveryTimeTo,AdditionalInformationOnDeliveryHash";
		CopyOptionsForAdditionalParameters = OptionsForAdditionalParameters.Copy(, ColumnsWithoutRows);
		CopyOptionsForAdditionalParameters.GroupBy(ColumnsWithoutRows);
		
		If CopyOptionsForAdditionalParameters.Count() = 1 Then
			
			FillPropertyValues(AddlParameters, OptionsForAdditionalParameters[0]);
			
		Else
			
			AddlParameters.Match = False;
			
		EndIf;
		
	EndIf;
	
	Return AddlParameters;
	
EndFunction

// Parameters:
//  DeliveryDocuments - Array of DefinedType.DeliveryPlanningDocument, DefinedType.DeliveryReferenceOrder25 -
//  FilterParameters - Structure:
//  * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//  * Sender - CatalogRef.Warehouses, CatalogRef.Partners - 
//  * DeliveryMethod - EnumRef.TransportMethods25
//  * Recipient - CatalogRef.Partners
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  * DateOfShipment - Date
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * Series - CatalogRef.ItemsBatches
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure
//  UseSelectionByGoods - Boolean
// 
// Returns:
//  ValueTable:
//  * DocumentDeliveries - DefinedType.DeliveryPlanningDocument, DefinedType.DeliveryReferenceOrder25 -
//  * RowCode - Number
//  * DeliveryTimeFrom - Date
//  * DeliveryTimeTo - Date
//  * AdditionalDeliveryInformation - String
//  * SpecialTransportationConditions - Boolean
//  * SpecialTransportationConditionsDescription - String
//  * SpecialConditionsOfCarriageDescriptionHash - String
//  * AdditionalInformationOnDeliveryHash - String
//
Function AllAdditionalParametersFromDocumentStrings(DeliveryDocuments, FilterParameters = Undefined, UseSelectionByGoods = False) Export
	
	QueryText =
	"SELECT
	|	DocumentHeader.Ref AS DocumentDeliveries,
	|	0 AS RowCode,
	|	DocumentHeader.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentHeader.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
	|	DocumentHeader.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
	|FROM
	|	Document.CustomerInvoice AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref IN (&DeliveryDocumentsSaleOfGoodsAndServices)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentHeader.Ref AS DocumentDeliveries,
	|	0 AS RowCode,
	|	DocumentHeader.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentHeader.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
	|	DocumentHeader.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref IN (&DeliveryDocumentsShipmentOfGoodsToCustomer)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentHeader.Ref AS DocumentDeliveries,
	|	0 AS RowCode,
	|	DocumentHeader.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentHeader.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
	|	DocumentHeader.AdditionalInformation AS AdditionalDeliveryInformation
	|FROM
	|	Document.DeliveryOrder AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref IN (&DeliveryDocumentsOrderForDelivery)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentHeader.Ref AS DocumentDeliveries,
	|	0 AS RowCode,
	|	DocumentHeader.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DocumentHeader.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
	|	DocumentHeader.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
	|FROM
	|	Document.SalesOrder AS DocumentHeader
	|		INNER JOIN Document.SalesOrder.Goods AS DocumentGoods
	|		ON DocumentHeader.Ref = DocumentGoods.Ref
	|WHERE
	|	DocumentHeader.Ref IN (&DeliveryDocumentsSalesOrder)
	|	AND DocumentHeader.DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ForWholeDocument)";
	
	If ValueIsFilled(FilterParameters) Then
		
		QueryTextOfSalesOrderLine =
		"SELECT
		|	OrderHeader_.Ref AS DocumentDeliveries,
		|	GoodsForOrderDelivery.RowCode AS RowCode,
		|	GoodsForOrderDelivery.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	GoodsForOrderDelivery.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
		|	GoodsForOrderDelivery.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	GoodsForOrderDelivery.DeliveryTimeTo AS DeliveryTimeTo,
		|	GoodsForOrderDelivery.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
		|FROM
		|	Document.SalesOrder AS OrderHeader_
		|		INNER JOIN Document.SalesOrder.GoodsToDeliver AS GoodsForOrderDelivery
		|		ON OrderHeader_.Ref = GoodsForOrderDelivery.Ref
		|			AND GoodsForOrderDelivery.DeliveryMethod = &DeliveryMethod
		|			AND GoodsForOrderDelivery.DeliveryPoint = &RecipientPoint
		|			AND GoodsForOrderDelivery.DeliveryZone = &Recipient_Area
		|		INNER JOIN Document.SalesOrder.Goods AS GoodsFromOrder
		|		ON GoodsForOrderDelivery.Ref = GoodsFromOrder.Ref
		|			AND GoodsForOrderDelivery.RowCode = GoodsFromOrder.RowCode
		|			AND GoodsForOrderDelivery.DeliveryToCarrier = FALSE
		|			AND GoodsFromOrder.DateOfShipment = &DateOfShipment
		|			AND &SelectionBySender
		|			AND &FilterByGoods
		|WHERE
		|	OrderHeader_.Ref IN (&DeliveryDocumentsSalesOrder)
		|	AND OrderHeader_.DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ByRows)
		|	AND OrderHeader_.Partner = &Recipient
		|
		|UNION ALL
		|
		|SELECT
		|	OrderHeader_.Ref AS DocumentDeliveries,
		|	GoodsForOrderDelivery.RowCode AS RowCode,
		|	GoodsForOrderDelivery.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	GoodsForOrderDelivery.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
		|	GoodsForOrderDelivery.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	GoodsForOrderDelivery.DeliveryTimeTo AS DeliveryTimeTo,
		|	GoodsForOrderDelivery.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
		|FROM
		|	Document.SalesOrder AS OrderHeader_
		|		INNER JOIN Document.SalesOrder.GoodsToDeliver AS GoodsForOrderDelivery
		|		ON OrderHeader_.Ref = GoodsForOrderDelivery.Ref
		|			AND GoodsForOrderDelivery.DeliveryMethod = &DeliveryMethod
		|			AND GoodsForOrderDelivery.CarrierDeliveryPoint = &RecipientPoint
		|			AND GoodsForOrderDelivery.CarrierSDeliveryArea = &Recipient_Area
		|			AND GoodsForOrderDelivery.Carrier = &Recipient
		|		INNER JOIN Document.SalesOrder.Goods AS GoodsFromOrder
		|		ON GoodsForOrderDelivery.Ref = GoodsFromOrder.Ref
		|			AND GoodsForOrderDelivery.RowCode = GoodsFromOrder.RowCode
		|			AND GoodsForOrderDelivery.DeliveryToCarrier = TRUE
		|			AND GoodsFromOrder.DateOfShipment = &DateOfShipment
		|			AND &SelectionBySender
		|			AND &FilterByGoods
		|WHERE
		|	OrderHeader_.Ref IN (&DeliveryDocumentsSalesOrder)
		|	AND OrderHeader_.DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ByRows)";
		
		If FilterParameters.Property("Sender") Then
			SelectionBySender = "GoodsFromOrder.Warehouse = &Sender";
		Else
			SelectionBySender = "TRUE";
		EndIf;
		
		QueryTextOfSalesOrderLine = StrReplace(
			QueryTextOfSalesOrderLine, "&SelectionBySender", SelectionBySender);
		
	Else
		
		QueryTextOfSalesOrderLine =
		"SELECT
		|	OrderHeader_.Ref AS DocumentDeliveries,
		|	GoodsForOrderDelivery.RowCode AS RowCode,
		|	GoodsForOrderDelivery.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	GoodsForOrderDelivery.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
		|	GoodsForOrderDelivery.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	GoodsForOrderDelivery.DeliveryTimeTo AS DeliveryTimeTo,
		|	GoodsForOrderDelivery.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
		|FROM
		|	Document.SalesOrder AS OrderHeader_
		|		INNER JOIN Document.SalesOrder.GoodsToDeliver AS GoodsForOrderDelivery
		|		ON OrderHeader_.Ref = GoodsForOrderDelivery.Ref
		|		INNER JOIN Document.SalesOrder.Goods AS GoodsFromOrder
		|		ON GoodsForOrderDelivery.Ref = GoodsFromOrder.Ref
		|			AND GoodsForOrderDelivery.RowCode = GoodsFromOrder.RowCode
		|			AND &FilterByGoods
		|WHERE
		|	OrderHeader_.Ref IN (&DeliveryDocumentsSalesOrder)
		|	AND OrderHeader_.DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ByRows)";
		
	EndIf;
	
	QueryText = QueryText + Common.UnionAllText() + QueryTextOfSalesOrderLine;
	
	If UseSelectionByGoods Then
		
		FilterByGoods = "GoodsFromOrder.Products = &Products
		|AND GoodsFromOrder.Characteristic = &Characteristic
		|AND GoodsFromOrder.Series = &Series";
		
	Else
		FilterByGoods = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterByGoods", FilterByGoods);
	
	Query = New Query;
	Query.Text = QueryText;
	
	DocumentTypes = Metadata.DefinedTypes.DeliveryReferenceOrder25.Type.Types();
	CommonClientServer.SupplementArray(
		DocumentTypes, Metadata.DefinedTypes.DeliveryPlanningDocument.Type.Types(), True);
	
	DeliveryDocumentsByType = ObjectsByTypes(DeliveryDocuments);
	
	For Each DocumentType In DocumentTypes Do
		
		DocumentsByType_ = DeliveryDocumentsByType[DocumentType];
		If DocumentsByType_ = Undefined Then
			DocumentsByType_ = New Array; // Array of DocumentRef
		EndIf;
		
		MetadataOfDocument = Metadata.FindByType(DocumentType);
		ParameterName = "DeliveryDocuments" + MetadataOfDocument.Name;
		
		Query.SetParameter(ParameterName, DocumentsByType_);
		
	EndDo;
	
	If ValueIsFilled(FilterParameters) Then
		
		If FilterParameters.Property("Sender") Then
			Query.SetParameter("Sender", FilterParameters.Sender);
		EndIf;
		Query.SetParameter("DeliveryMethod", FilterParameters.DeliveryMethod);
		Query.SetParameter("Recipient", FilterParameters.Recipient);
		Query.SetParameter("RecipientPoint", FilterParameters.RecipientPoint);
		Query.SetParameter("Recipient_Area", FilterParameters.Recipient_Area);
		Query.SetParameter("DateOfShipment", FilterParameters.DateOfShipment);
		
	EndIf;
	
	If UseSelectionByGoods Then
		
		Query.SetParameter("Products", FilterParameters.Products);
		Query.SetParameter("Characteristic", FilterParameters.Characteristic);
		Query.SetParameter("Series", FilterParameters.Series);
		Query.SetParameter("Package", FilterParameters.Package);
		
	EndIf;
	
	OptionsForAdditionalParameters = Query.Execute().Unload();
	
	StringType32 = Common.StringTypeDetails(32);
	OptionsForAdditionalParameters.Columns.Add("SpecialConditionsOfCarriageDescriptionHash", StringType32);
	OptionsForAdditionalParameters.Columns.Add("AdditionalInformationOnDeliveryHash", StringType32);
	
	For Each StringOption In OptionsForAdditionalParameters Do
		
		StringOption.SpecialConditionsOfCarriageDescriptionHash = HashOfSignificantCharactersOfString(
			StringOption.SpecialTransportationConditionsDescription);
		StringOption.AdditionalInformationOnDeliveryHash = HashOfSignificantCharactersOfString(
			StringOption.AdditionalDeliveryInformation);
		
	EndDo;
	
	Return OptionsForAdditionalParameters;
	
EndFunction

// Parameters:
//  String - String
// 
// Returns:
//  String - Checksum of significant characters of a string, excluding spaces and line breaks
//
Function HashOfSignificantCharactersOfString(String) Export
	
	CharactersToDelete = " " + Chars.NBSp + Chars.Tab + Chars.CR + Chars.LF;
	SignificantCharacters = StrConcat(StrSplit(String, CharactersToDelete, False), "");
	SignificantCharacters = Lower(SignificantCharacters);
	Hash = Common.CheckSumString(SignificantCharacters);
	Return Hash;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns:
//  Structure:
// * TransitionIsRunning - Boolean - 
// * JobCreated - Boolean - 
// * DataProcessed - Boolean - 
// * TransitionIsComplete - Boolean - 
// * NumberOfPartners - Number - 
// * NumberOfPartnersProcessed - Number - 
// * NumberOfWarehouses - Number - 
// * NumberOfWarehousesProcessed - Number - 
//
Function NewTransitionDataForDelivery25()
	
	TransitionData = New Structure;
	TransitionData.Insert("TransitionIsRunning", False);
	TransitionData.Insert("JobCreated", False);
	TransitionData.Insert("DataProcessed", False);
	TransitionData.Insert("TransitionIsComplete", False);
	TransitionData.Insert("NumberOfPartners", 0);
	TransitionData.Insert("NumberOfPartnersProcessed", 0);
	TransitionData.Insert("NumberOfWarehouses", 0);
	TransitionData.Insert("NumberOfWarehousesProcessed", 0);
	
	Return TransitionData;
	
EndFunction

Function QueryTextOfProgressOfTransitionToDelivery25()
	
	QueryText =
	"SELECT
	|	ContactInformationData.Ref AS Ref
	|INTO VT_WarehousesWithAddresses
	|FROM
	|	Catalog.Warehouses.ContactInformation AS ContactInformationData
	|WHERE
	|	NOT ContactInformationData.Ref.IsFolder
	|	AND ContactInformationData.Type = VALUE(Enum.ContactInformationTypes.Address)
	|	AND TRIMALL(ContactInformationData.Presentation) <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContactInformationData.Ref AS Ref
	|INTO VT_PartnersWithAddresses
	|FROM
	|	Catalog.Partners.ContactInformation AS ContactInformationData
	|WHERE
	|	ContactInformationData.Type = VALUE(Enum.ContactInformationTypes.Address)
	|	AND TRIMALL(ContactInformationData.Presentation) <> """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Warehouses.Ref AS Ref
	|INTO VT_WarehousesReadyForProcessing
	|FROM
	|	VT_WarehousesWithAddresses AS Warehouses
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON Warehouses.Ref = DeliveryPoints.Owner
	|WHERE
	|	DeliveryPoints.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Partners.Ref AS Ref
	|INTO VT_PartnersForProcessing
	|FROM
	|	VT_PartnersWithAddresses AS Partners
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON Partners.Ref = DeliveryPoints.Owner
	|WHERE
	|	DeliveryPoints.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT Warehouses.Ref) AS NumberOfWarehouses,
	|	0 AS NumberOfPartners,
	|	0 AS NoWarehousesProcessed,
	|	0 AS NoPartnersProcessed
	|INTO TT_ProgressProcessing
	|FROM
	|	VT_WarehousesWithAddresses AS Warehouses
	|
	|UNION ALL
	|
	|SELECT
	|	0 AS NumberOfWarehouses,
	|	COUNT(DISTINCT Partners.Ref) AS NumberOfPartners,
	|	0 AS NoWarehousesProcessed,
	|	0 AS NoPartnersProcessed
	|FROM
	|	VT_PartnersWithAddresses AS Partners
	|
	|UNION ALL
	|
	|SELECT
	|	0 AS NumberOfWarehouses,
	|	0 AS NumberOfPartners,
	|	COUNT(DISTINCT Warehouses.Ref) AS NoWarehousesProcessed,
	|	0 AS NoPartnersProcessed
	|FROM
	|	VT_WarehousesReadyForProcessing AS Warehouses
	|
	|UNION ALL
	|
	|SELECT
	|	0 AS NumberOfWarehouses,
	|	0 AS NumberOfPartners,
	|	0 AS NoWarehousesProcessed,
	|	COUNT(DISTINCT Partners.Ref) AS NoPartnersProcessed
	|FROM
	|	VT_PartnersForProcessing AS Partners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(Progress.NumberOfWarehouses) AS NumberOfWarehouses,
	|	SUM(Progress.NumberOfPartners) AS NumberOfPartners,
	|	SUM(Progress.NumberOfWarehouses) - SUM(Progress.NoWarehousesProcessed) AS NumberOfWarehousesProcessed,
	|	SUM(Progress.NumberOfPartners) -SUM(Progress.NoPartnersProcessed) AS NumberOfPartnersProcessed
	|FROM
	|	TT_ProgressProcessing AS Progress";
	
	Return QueryText;
	
EndFunction

Procedure AddDeliveryDataToShipmentManagementQueryText25(QueryText)
	
	QueryTexts = New Array; // Array of String
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
	#Region QueryTextTTTripData_DeviationAllowed_0
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		
		QueryTextTripTTData =
		"SELECT ALLOWED
		|	VALUETYPE(DeliveryData.Trip) AS DocumentType,
		|	DeliveryData.Trip AS ReferenceOrder,
		|	DeliveryData.Trip AS TransportationJob,
		|	DeliveryData.Trip.Number AS Number,
		|	DeliveryData.Trip.DateOfDeparture AS Date,
		|	UNDEFINED AS Recipient,
		|	CASE MIN(DeliveryData.StatusCode)
		|		WHEN 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END AS State,
		|	1 AS PictureIndex
		|INTO TripTTData
		|FROM
		|	(SELECT
		|		DeliveryTurnover.Trip AS Trip,
		|		CASE
		|			WHEN DeliveryTurnover.ForAssemblyTurnover - DeliveryTurnover.AssemblyInProgressTurnover - DeliveryTurnover.AssembledTurnover > 0
		|				THEN 0
		|			WHEN DeliveryTurnover.InTransitTurnover <> 0
		|				THEN 200
		|			WHEN DeliveryTurnover.DeliveredTurnover <> 0
		|				THEN 200
		|			WHEN DeliveryTurnover.AssemblyInProgressTurnover <> 0
		|				THEN 1
		|			WHEN DeliveryTurnover.AssembledTurnover <> 0
		|				THEN 2
		|			ELSE 404
		|		END AS StatusCode,
		|		DeliveryTurnover.Products AS Products,
		|		DeliveryTurnover.Characteristic AS Characteristic,
		|		DeliveryTurnover.Series AS Series
		|	FROM
		|		AccumulationRegister.Delivery.Turnovers(
		|				,
		|				,
		|				,
		|				(DateOfShipment <= &DateOfShipmentDelivery
		|					OR NOT &ShipmentDateFilledIn)
		|					AND Trip <> VALUE(Document.Trip.EmptyRef)
		|					AND Sender = &Warehouse
		|					AND Arm = 1) AS DeliveryTurnover
		|	WHERE
		|		(DeliveryTurnover.ForAssemblyTurnover - DeliveryTurnover.AssemblyInProgressTurnover - DeliveryTurnover.AssembledTurnover > 0
		|				OR DeliveryTurnover.AssemblyInProgressTurnover <> 0
		|				OR DeliveryTurnover.AssembledTurnover <> 0)) AS DeliveryData
		|
		|GROUP BY
		|	DeliveryData.Trip,
		|	DeliveryData.Trip.Number,
		|	DeliveryData.Trip.DateOfDeparture
		|
		|HAVING
		|	CASE MIN(DeliveryData.StatusCode)
		|		WHEN 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END IN (&States1)";
		QueryTexts.Add(QueryTextTripTTData);
		
	EndIf;
	#EndRegion
	
	#Region QueryTextTripTTData_AllowableVariance_Not_0
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		QueryTextTripTTData =
		"SELECT ALLOWED
		|	VALUETYPE(DeliveryData.Trip) AS DocumentType,
		|	DeliveryData.Trip AS ReferenceOrder,
		|	DeliveryData.Trip AS TransportationJob,
		|	DeliveryData.Trip.Number AS Number,
		|	DeliveryData.Trip.DateOfDeparture AS Date,
		|	UNDEFINED AS Recipient,
		|	CASE MIN(DeliveryData.StatusCode)
		|		WHEN 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END AS State,
		|	1 AS PictureIndex
		|INTO TripTTData
		|FROM
		|	(SELECT
		|		DeliveryTurnover.Trip AS Trip,
		|		CASE
		|			WHEN CASE
		|					WHEN DeliveryTurnover.ForAssemblyTurnover - DeliveryTurnover.AssemblyInProgressTurnover - DeliveryTurnover.AssembledTurnover >= 0
		|						THEN DeliveryTurnover.ForAssemblyTurnover - DeliveryTurnover.AssemblyInProgressTurnover - DeliveryTurnover.AssembledTurnover
		|					ELSE -(DeliveryTurnover.ForAssemblyTurnover - DeliveryTurnover.AssemblyInProgressTurnover - DeliveryTurnover.AssembledTurnover)
		|				END > CASE
		|					WHEN DeliveryTurnover.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|						THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * DeliveryTurnover.ForAssemblyTurnover
		|					ELSE 0
		|				END
		|				THEN 0
		|			WHEN DeliveryTurnover.InTransitTurnover <> 0
		|				THEN 200
		|			WHEN DeliveryTurnover.DeliveredTurnover <> 0
		|				THEN 200
		|			WHEN DeliveryTurnover.AssemblyInProgressTurnover <> 0
		|				THEN 1
		|			WHEN DeliveryTurnover.AssembledTurnover <> 0
		|				THEN 2
		|			ELSE 404
		|		END AS StatusCode,
		|		DeliveryTurnover.Products AS Products,
		|		DeliveryTurnover.Characteristic AS Characteristic,
		|		DeliveryTurnover.Series AS Series
		|	FROM
		|		AccumulationRegister.Delivery.Turnovers(
		|				,
		|				,
		|				,
		|				(DateOfShipment <= &DateOfShipmentDelivery
		|					OR NOT &ShipmentDateFilledIn)
		|					AND Trip <> VALUE(Document.Trip.EmptyRef)
		|					AND Sender = &Warehouse
		|					AND Arm = 1) AS DeliveryTurnover
		|	WHERE
		|		(DeliveryTurnover.ForAssemblyTurnover - DeliveryTurnover.AssemblyInProgressTurnover - DeliveryTurnover.AssembledTurnover > 0
		|				OR DeliveryTurnover.AssemblyInProgressTurnover <> 0
		|				OR DeliveryTurnover.AssembledTurnover <> 0)) AS DeliveryData
		|
		|GROUP BY
		|	DeliveryData.Trip,
		|	DeliveryData.Trip.Number,
		|	DeliveryData.Trip.DateOfDeparture,
		|	DeliveryData.Trip
		|
		|HAVING
		|	CASE MIN(DeliveryData.StatusCode)
		|		WHEN 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN 1
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN 2
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END IN (&States1)";
		QueryTexts.Add(QueryTextTripTTData);
		
	EndIf;
	#EndRegion
	
	#Region TTDataWithoutDelivery
	TTDataWithoutDelivery =
	"SELECT
	|	GoodsForIssueBalance.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssueBalance.Recipient AS Recipient,
	|	GoodsForIssueBalance.ToShipBalance AS ToShipBalance,
	|	GoodsForIssueBalance.AssemblyInProgressBalance AS AssemblyInProgressBalance,
	|	GoodsForIssueBalance.AssembledBalance AS AssembledBalance,
	|	GoodsForIssueBalance.Products AS Products,
	|	GoodsForIssueBalance.Characteristic AS Characteristic,
	|	GoodsForIssueBalance.Series AS Series,
	|	GoodsForIssueBalance.Purpose AS Purpose
	|INTO DataOnShipmentOfGoodsTT
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS GoodsForIssueBalance
	|WHERE
	|	(GoodsForIssueBalance.ToShipBalance - GoodsForIssueBalance.AssemblyInProgressBalance - GoodsForIssueBalance.AssembledBalance > 0
	|			OR GoodsForIssueBalance.AssemblyInProgressBalance > 0
	|			OR GoodsForIssueBalance.AssembledBalance > 0)
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.Purpose AS Purpose,
	|	Delivery.RowCode AS RowCode,
	|	Delivery.PlanningDocument AS PlanningDocument
	|INTO TTPrimaryDeliveryRecords
	|FROM
	|	(SELECT DISTINCT
	|		DataOnShipmentOfGoodsTT.ReferenceOrder AS ReferenceOrder
	|	FROM
	|		DataOnShipmentOfGoodsTT AS DataOnShipmentOfGoodsTT) AS ShipmentOrders
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON ShipmentOrders.ReferenceOrder = Delivery.ReferenceOrder
	|		INNER JOIN DataOnShipmentOfGoodsTT AS DataOnShipmentOfGoodsTT
	|		ON (DataOnShipmentOfGoodsTT.ReferenceOrder = Delivery.ReferenceOrder)
	|			AND (DataOnShipmentOfGoodsTT.Products = Delivery.Products)
	|			AND (DataOnShipmentOfGoodsTT.Characteristic = Delivery.Characteristic)
	|			AND (DataOnShipmentOfGoodsTT.Series = Delivery.Series)
	|			AND (DataOnShipmentOfGoodsTT.Purpose = Delivery.Purpose)
	|			AND (Delivery.PrimaryRegisterRecord)
	|WHERE
	|	(NOT &ShipmentDateFilledIn
	|			OR ISNULL(Delivery.SourceShipmentDate, DATETIME(1, 1, 1)) <= &DateOfShipmentDelivery)
	|
	|INDEX BY
	|	ReferenceOrder,
	|	PlanningDocument,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	ISNULL(TTPrimaryDeliveryRecords.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
	|	SUM(0) AS ToShip,
	|	SUM(DeliveryTurnover.AssemblyInProgressTurnover) AS AssemblyInProgress,
	|	SUM(DeliveryTurnover.AssembledTurnover) AS Assembled,
	|	SUM(DeliveryTurnover.ToDeliverTurnover) AS ToDeliver
	|INTO TTDataToDelivery
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			Day,
	|			Sender = &Warehouse
	|				AND Arm = 1
	|				AND DeliveryMethod <> VALUE(Enum.TransportMethods25.SelfPickup)
	|				AND ReferenceOrder IN
	|					(SELECT DISTINCT
	|						DataOnShipmentOfGoodsTT.ReferenceOrder AS DocumentShipments
	|					FROM
	|						DataOnShipmentOfGoodsTT AS DataOnShipmentOfGoodsTT)
	|				AND (ReferenceOrder, Products, Characteristic, Series) IN
	|					(SELECT
	|						DataOnShipmentOfGoodsTT.ReferenceOrder AS ReferenceOrder,
	|						DataOnShipmentOfGoodsTT.Products AS Products,
	|						DataOnShipmentOfGoodsTT.Characteristic AS Characteristic,
	|						DataOnShipmentOfGoodsTT.Series AS Series
	|					FROM
	|						DataOnShipmentOfGoodsTT AS DataOnShipmentOfGoodsTT)) AS DeliveryTurnover
	|		LEFT JOIN TTPrimaryDeliveryRecords AS TTPrimaryDeliveryRecords
	|		ON DeliveryTurnover.ReferenceOrder = TTPrimaryDeliveryRecords.ReferenceOrder
	|			AND DeliveryTurnover.PlanningDocument = TTPrimaryDeliveryRecords.PlanningDocument
	|			AND DeliveryTurnover.RowCode = TTPrimaryDeliveryRecords.RowCode
	|
	|GROUP BY
	|	DeliveryTurnover.Products,
	|	ISNULL(TTPrimaryDeliveryRecords.Purpose, VALUE(Catalog.Assignments.EmptyRef)),
	|	DeliveryTurnover.Characteristic,
	|	DeliveryTurnover.Series,
	|	DeliveryTurnover.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUETYPE(DataShipments.ReferenceOrder) AS DocumentType,
	|	DataShipments.ReferenceOrder AS ReferenceOrder,
	|	UNDEFINED AS TransportationJob,
	|	DataShipments.Recipient AS Recipient,
	|	CASE MIN(DataShipments.StatusCode)
	|		WHEN 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END AS State,
	|	0 AS PictureIndex
	|INTO TTDataWithoutDelivery
	|FROM
	|	(SELECT
	|		ReferencesToShip.ReferenceOrder AS ReferenceOrder,
	|		ReferencesToShip.Recipient AS Recipient,
	|		CASE
	|			WHEN ReferencesToShip.ToShipBalance - ISNULL(GoodsToDeliver.ToDeliver, 0) - (ReferencesToShip.AssemblyInProgressBalance - ISNULL(GoodsToDeliver.AssemblyInProgress, 0)) - (ReferencesToShip.AssembledBalance - ISNULL(GoodsToDeliver.Assembled, 0)) > 0
	|				THEN 0
	|			WHEN ReferencesToShip.AssemblyInProgressBalance - ISNULL(GoodsToDeliver.AssemblyInProgress, 0) <> 0
	|				THEN 1
	|			WHEN ReferencesToShip.AssembledBalance - ISNULL(GoodsToDeliver.Assembled, 0) <> 0
	|				THEN 2
	|			ELSE 404
	|		END AS StatusCode,
	|		ReferencesToShip.Products AS Products,
	|		ReferencesToShip.Characteristic AS Characteristic,
	|		ReferencesToShip.Series AS Series
	|	FROM
	|		DataOnShipmentOfGoodsTT AS ReferencesToShip
	|			LEFT JOIN TTDataToDelivery AS GoodsToDeliver
	|			ON ReferencesToShip.ReferenceOrder = GoodsToDeliver.ReferenceOrder
	|				AND ReferencesToShip.Products = GoodsToDeliver.Products
	|				AND ReferencesToShip.Characteristic = GoodsToDeliver.Characteristic
	|				AND ReferencesToShip.Series = GoodsToDeliver.Series
	|				AND ReferencesToShip.Purpose = GoodsToDeliver.Purpose
	|	WHERE
	|		ReferencesToShip.ToShipBalance - (ISNULL(GoodsToDeliver.ToDeliver, 0) - ISNULL(GoodsToDeliver.Assembled, 0)) > 0) AS DataShipments
	|
	|GROUP BY
	|	DataShipments.Recipient,
	|	VALUETYPE(DataShipments.ReferenceOrder),
	|	DataShipments.ReferenceOrder
	|
	|HAVING
	|	CASE MIN(DataShipments.StatusCode)
	|		WHEN 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END IN (&States1)";
	QueryTexts.Add(TTDataWithoutDelivery);
	#EndRegion
	
	#Region QueryTextUnion
	QueryTextUnion =
	"SELECT
	|	TripTTData.DocumentType AS DocumentType,
	|	TripTTData.ReferenceOrder AS ReferenceOrder,
	|	TripTTData.TransportationJob AS TransportationJob,
	|	TripTTData.Number AS Number,
	|	TripTTData.Date AS Date,
	|	TripTTData.Recipient AS Recipient,
	|	TripTTData.State AS State,
	|	TripTTData.PictureIndex AS PictureIndex
	|FROM
	|	TripTTData AS TripTTData
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		WHEN TTDataWithoutDelivery.ReferenceOrder REFS Document.MovementOfProductsAndMaterials
	|			THEN PRESENTATION(ISNULL(DocumentsRegistry.BusinessOperation, VALUETYPE(TTDataWithoutDelivery.ReferenceOrder)))
	|		ELSE TTDataWithoutDelivery.DocumentType
	|	END,
	|	TTDataWithoutDelivery.ReferenceOrder,
	|	TTDataWithoutDelivery.TransportationJob,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """"),
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1)),
	|	TTDataWithoutDelivery.Recipient,
	|	TTDataWithoutDelivery.State,
	|	TTDataWithoutDelivery.PictureIndex
	|FROM
	|	TTDataWithoutDelivery AS TTDataWithoutDelivery
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TTDataWithoutDelivery.ReferenceOrder = DocumentsRegistry.Ref
	|			AND (NOT DocumentsRegistry.AdditionalRecord)
	|
	|ORDER BY
	|	Date";
	QueryTexts.Add(QueryTextUnion);
	#EndRegion
	
	ResultingQueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	QueryText = QueryText + ResultingQueryText;
	
EndProcedure

Procedure SupplementQueryTextOfShipmentManagementWithDeliveryData25ShipmentDetails(QueryText)
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		
		QueryText = QueryText +
		"SELECT
		|	VALUETYPE(DocumentData.Ref) AS DocumentType,
		|	2 AS PictureIndex,
		|	DocumentData.Ref AS ReferenceOrder,
		|	DocumentData.Ref AS TransportationJob,
		|	UNDEFINED AS Recipient,
		|	"""" AS Number,
		|	DATETIME(1, 1, 1) AS Date,
		|	VALUE(Enum.GoodsPickingStates.EmptyRef) AS State,
		|	0 AS Order
		|FROM
		|	Document.Trip AS DocumentData
		|WHERE
		|	DocumentData.Ref = &TransportationJob
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	VALUETYPE(DataByTrip.ReferenceOrder),
		|	3,
		|	DataByTrip.ReferenceOrder,
		|	&TransportationJob,
		|	ISNULL(DocumentsRegistry.Partner, UNDEFINED),
		|	ISNULL(DocumentsRegistry.IBDocumentNumber, """"),
		|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1)),
		|	CASE
		|		WHEN DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover > 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN DataByTrip.AssemblyInProgressTurnover <> 0
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN DataByTrip.AssembledTurnover <> 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END,
		|	1
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Trip = &TransportationJob
		|				AND Arm = 1) AS DataByTrip
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON DataByTrip.ReferenceOrder = DocumentsRegistry.Ref
		|			AND (NOT DocumentsRegistry.AdditionalRecord)
		|WHERE
		|	CASE
		|			WHEN DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover > 0
		|				THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|			WHEN DataByTrip.AssemblyInProgressTurnover <> 0
		|				THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|			WHEN DataByTrip.AssembledTurnover <> 0
		|				THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|			ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|		END IN (&States1)
		|
		|ORDER BY
		|	Order,
		|	Date";
		
	EndIf;
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		QueryText = QueryText +
		"SELECT
		|	VALUETYPE(DocumentData.Ref) AS DocumentType,
		|	2 AS PictureIndex,
		|	DocumentData.Ref AS ReferenceOrder,
		|	DocumentData.Ref AS TransportationJob,
		|	UNDEFINED AS Recipient,
		|	"""" AS Number,
		|	DATETIME(1, 1, 1) AS Date,
		|	VALUE(Enum.GoodsPickingStates.EmptyRef) AS State,
		|	0 AS Order
		|FROM
		|	Document.Trip AS DocumentData
		|WHERE
		|	DocumentData.Ref = &TransportationJob
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	VALUETYPE(DataByTrip.ReferenceOrder),
		|	3,
		|	DataByTrip.ReferenceOrder,
		|	&TransportationJob,
		|	ISNULL(DocumentsRegistry.Partner, UNDEFINED),
		|	ISNULL(DocumentsRegistry.IBDocumentNumber, """"),
		|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1, 1, 1)),
		|	CASE
		|		WHEN CASE
		|				WHEN DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover >= 0
		|					THEN DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover
		|				ELSE -(DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover)
		|			END > CASE
		|				WHEN DataByTrip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|					THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * DataByTrip.ForAssemblyTurnover
		|				ELSE 0
		|			END
		|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|		WHEN DataByTrip.AssemblyInProgressTurnover <> 0
		|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|		WHEN DataByTrip.AssembledTurnover <> 0
		|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|	END,
		|	1
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Trip = &TransportationJob
		|				AND Arm = 1) AS DataByTrip
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON DataByTrip.ReferenceOrder = DocumentsRegistry.Ref
		|			AND (NOT DocumentsRegistry.AdditionalRecord)
		|WHERE
		|	CASE
		|			WHEN CASE
		|					WHEN DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover >= 0
		|						THEN DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover
		|					ELSE -(DataByTrip.ForAssemblyTurnover - DataByTrip.AssemblyInProgressTurnover - DataByTrip.AssembledTurnover)
		|				END > CASE
		|					WHEN DataByTrip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|						THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * DataByTrip.ForAssemblyTurnover
		|					ELSE 0
		|				END
		|				THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
		|			WHEN DataByTrip.AssemblyInProgressTurnover <> 0
		|				THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
		|			WHEN DataByTrip.AssembledTurnover <> 0
		|				THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
		|			ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
		|		END IN (&States1)
		|
		|ORDER BY
		|	Order,
		|	Date";
		
	EndIf;
	
EndProcedure

Procedure DisableRoutineTaskOfSwitchingToDelivery25()
	
	Parameters = New Structure;
	Parameters.Insert("Use", False);
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", False);
	JobParameters.Insert("Parameters", Parameters);
	
	ScheduledJobsServer.ChangeJob(
		Metadata.ScheduledJobs.MigrationToDeliveryManagement25,
		JobParameters);
	
EndProcedure

Procedure CreateRoutineTaskForSwitchingToDelivery25()
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.MigrationToDeliveryManagement25);
	JobParameters.Insert("Use", True);
	
	Schedule = New JobSchedule();
	Schedule.DaysRepeatPeriod = 1;
	Schedule.RepeatPeriodInDay = 10;
	
	JobParameters.Insert("Schedule", Schedule);
	
	ScheduledJobsServer.AddJob(JobParameters);
	
EndProcedure

Procedure DisableVerificationOfRequiredDeliveryDataFields(NotCheckedAttributeArray, Val Settings)
	
	// Information about warehouses is always checked if delivery is required
	
	NotCheckedAttributeArray.Add(Settings.DeliveryAddressFieldName);
	NotCheckedAttributeArray.Add(Settings.CarrierFieldName);
	NotCheckedAttributeArray.Add(Settings.SpecialConditionsOfCarriageDescriptionFieldName);
	
EndProcedure

// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  Cancel  - Boolean
//  OutputFillingErrors - Boolean - indicates whether it is necessary to display filling errors
//  UpdateData1 - Boolean - indicates the need to write updated data to the table
//
Procedure CheckUpdateDeliveryFieldData(Settings, Cancel, OutputFillingErrors, UpdateData1 = False)
	
	If UpdateData1 Then
		ClearUnusedDeliveryFields(Settings, Cancel);
	EndIf;
	
	Object = Settings.DocumentObject; // DocumentObject
	
	If IsBlankString(Settings.DeliveryIndicationMethodFieldName) Then
		DeliverySpecificationMethod = Settings.MethodOfSpecifyingDeliveryIsUnconditional;
	Else
		DeliverySpecificationMethod = Object[Settings.DeliveryIndicationMethodFieldName]; // EnumRef.DeliverySpecificationMethods
	EndIf;
	
	If IsBlankString(Settings.TypeOfDeliveryPlanningFieldName) Then
		DeliveryPlanning = Settings.TypeOfDeliveryPlanningIsUnconditional;
	Else
		DeliveryPlanning = Object[Settings.TypeOfDeliveryPlanningFieldName]; // EnumRef.DeliveryPlanningKinds
	EndIf;
	
	OnlyReset = (DeliveryPlanning = Enums.DeliveryPlanningKinds.SeparateDocument);
	
	CheckUpdateDeliveryHeaderFieldData(DeliverySpecificationMethod, Settings, UpdateData1, OnlyReset, OutputFillingErrors, Cancel);
	CheckUpdateDeliveryFieldDataTable(DeliverySpecificationMethod, Settings, UpdateData1, OnlyReset, OutputFillingErrors, Cancel);
	
EndProcedure

Procedure CheckUpdateDeliveryHeaderFieldData(Val DeliverySpecificationMethod, Val Settings, Val UpdateData1, Val OnlyReset, Val OutputFillingErrors, Cancel)
	
	If DeliverySpecificationMethod <> Enums.DeliverySpecificationMethods.ForWholeDocument Then
		Return;
	EndIf;
	
	Object = Settings.DocumentObject; // DocumentObject
	
	CheckUpdatePointDataDeliveryZone(DeliverySpecificationMethod, Settings, UpdateData1, OnlyReset, OutputFillingErrors, Cancel);
	
	If IsBlankString(Settings.DeliveryMethod_FieldName) Then
		DeliveryMethod = Settings.DeliveryMethodIsUnconditional;
	Else
		DeliveryMethod = Object[Settings.DeliveryMethod_FieldName]; // EnumRef.TransportMethods25
	EndIf;
		
	If OutputFillingErrors Then
		
		CheckDataOfDeliveryFieldsHeaderCarrierDetails(Settings, DeliveryMethod, Object, Cancel);
		
		If Not IsBlankString(Settings.SpecialConditionsOfCarriageFieldName)
			And Object[Settings.SpecialConditionsOfCarriageFieldName] Then
			
			If Not ValueIsFilled(Object[Settings.SpecialConditionsOfCarriageDescriptionFieldName]) Then
				
				ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Описание особых условий перевозки';
																		|vi = 'Description of special transportation conditions';
																		|en = 'Description of special transportation conditions'; fa = 'شرح شرایط ویژه حمل‌ونقل';
																		|it = 'Descrizione delle condizioni particolari di trasporto';
																		|pl = 'Opis szczególnych warunków przewozu';
																		|tr = 'Özel nakliye koşullarının ayrıntıları'"));
				Common.MessageToUser(
					ErrorText,
					Object,
					"DeliveryIsRequired",
					,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckUpdatePointDataDeliveryZone(Val DeliverySpecificationMethod, Val Settings, Val UpdateData1, Val OnlyReset, Val OutputFillingErrors, Cancel)
	
	If DeliverySpecificationMethod <> Enums.DeliverySpecificationMethods.ForWholeDocument Then
		Return;
	EndIf;
	
	Object = Settings.DocumentObject; // DocumentObject
	
	DeliveryPoint = Object[Settings.DeliveryPointFieldName]; // CatalogRef.DeliveryPoints
	DeliveryZone = Object[Settings.DeliveryZoneFieldName]; // CatalogRef.DeliveryZones
	
	DataOfDeliveryPoint = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Settings.OwnerOfDeliveryPoints);
	DeliveryPointIsSet = True;
	DeliveryZoneIsSet = True;
	
	OwnersOfDeliveryPoints = New Map;
	If Not DataOfDeliveryPoint.DeliveryPoint.IsEmpty() Then
		OwnersOfDeliveryPoints[DataOfDeliveryPoint.DeliveryPoint] = Settings.OwnerOfDeliveryPoints;
	EndIf;
	OwnersOfDeliveryPoints[DeliveryPoint] = Common.ObjectAttributeValue(DeliveryPoint, "Owner");
	
	CheckUpdateDataOnDeliveryPoint(
		DataOfDeliveryPoint,
		OwnersOfDeliveryPoints,
		DeliveryPoint,
		DeliveryPointIsSet,
		DeliveryZone,
		DeliveryZoneIsSet,
		UpdateData1,
		OnlyReset);
	
	If UpdateData1 Then
		
		Object[Settings.DeliveryPointFieldName] = DeliveryPoint;
		Object[Settings.DeliveryZoneFieldName] = DeliveryZone;
		
	EndIf;
	
	If Not DeliveryPointIsSet
		And OutputFillingErrors Then
		
		ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Точка доставки';
																|vi = 'Delivery point';
																|en = 'Delivery point'; fa = 'نقطه تحویل';
																|it = 'Delivery point';
																|pl = 'Delivery point';
																|tr = 'Teslimat noktası'"));
		Common.MessageToUser(
			ErrorText,
			Object,
			"DeliveryIsRequired",
			,
			Cancel);
		
	EndIf;
	
	If Not DeliveryZoneIsSet
		And OutputFillingErrors Then
		
		ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Зона доставки';
																|vi = 'Delivery zone';
																|en = 'Delivery zone'; fa = 'منطقه تحویل';
																|it = 'Area di consegna';
																|pl = 'Strefa dostawy';
																|tr = 'Teslimat bölgesi'"));
		Common.MessageToUser(
			ErrorText,
			Object,
			"DeliveryIsRequired",
			,
			Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckDataOfDeliveryFieldsHeaderCarrierDetails(Val Settings, Val DeliveryMethod, Val Object, Cancel)

	If IsBlankString(Settings.DeliveryToCarrierFieldName) Then
		DeliveryToCarrier = Settings.DeliveryToCarrierIsUnconditional;
	Else
		DeliveryToCarrier = Object[Settings.DeliveryToCarrierFieldName]; // Boolean
	EndIf;
	
	If (DeliveryMethod = Enums.TransportMethods25.OwnDelivery
			And DeliveryToCarrier)
		Or DeliveryMethod = Enums.TransportMethods25.ByCarrier Then
		
		If Not ValueIsFilled(Object[Settings.CarrierFieldName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Перевозчик';
																	|vi = 'Carrier';
																	|en = 'Carrier'; fa = 'حمل‌کننده';
																	|it = 'Carrier';
																	|pl = 'Carrier';
																	|tr = 'Taşıyıcı'"));
			Common.MessageToUser(
				ErrorText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	If (DeliveryMethod = Enums.TransportMethods25.OwnDelivery
		And DeliveryToCarrier) Then
		
		If Not ValueIsFilled(Object[Settings.CarrierSDeliveryPointFieldName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Точка доставки перевозчика';
																	|vi = 'Carrier delivery point';
																	|en = 'Carrier delivery point'; fa = 'نقطه تحویل حمل‌کننده';
																	|it = 'Carrier delivery point';
																	|pl = 'Carrier delivery point';
																	|tr = 'Taşıyıcı teslimat noktası'"));
			Common.MessageToUser(
				ErrorText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Object[Settings.CarrierSDeliveryZoneFieldName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(,, NStr("ru = 'Зона доставки перевозчика';
																	|vi = 'Carrier delivery zone';
																	|en = 'Carrier delivery zone'; fa = 'منطقه تحویل حمل‌کننده';
																	|it = 'Carrier delivery zone';
																	|pl = 'Carrier delivery zone';
																	|tr = 'Taşıyıcı teslimat bölgesi'"));
			Common.MessageToUser(
				ErrorText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckUpdateDeliveryFieldDataTable(Val DeliverySpecificationMethod, Val Settings, Val UpdateData1, Val OnlyReset, Val OutputFillingErrors, Cancel)
	
	If DeliverySpecificationMethod <> Enums.DeliverySpecificationMethods.ByRows Then
		Return;
	EndIf;
	
	Object = Settings.DocumentObject; // DocumentObject
	
	DeliveryGoodsTable = Settings.DeliveryGoodsTable;
	DeliveryPointsOfTable = DeliveryGoodsTable.UnloadColumn("DeliveryPoint"); // Array of CatalogRef.DeliveryPoints
	DeliveryPointDataTables = Common.ObjectsAttributeValue(DeliveryPointsOfTable, "Owner");
	OwnerSDeliveryPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Settings.OwnerOfDeliveryPoints);
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(Object);
	ErrorTemplateField = NStr("ru = 'Поле ""%1"" параметров доставки не заполнено для строки %2';
								|vi = 'The ""%1"" field of the delivery parameters is not filled in for line %2';
								|en = 'The ""%1"" field of the delivery parameters is not filled in for line %2'; fa = 'The ""%1"" field of the delivery parameters is not filled in for line %2';
								|it = 'The ""%1"" field of the delivery parameters is not filled in for line %2';
								|pl = 'The ""%1"" field of the delivery parameters is not filled in for line %2';
								|tr = 'Teslimat parametrelerinin ""%1"" alanı %2 satırı için doldurulmamış'");
	ErrorTemplateColumn = NStr("ru = 'Колонка ""%1"" параметров доставки не заполнена для строки %2';
								|vi = 'The ""%1"" column of the delivery parameters is not filled in for line %2';
								|en = 'The ""%1"" column of the delivery parameters is not filled in for line %2'; fa = 'The ""%1"" column of the delivery parameters is not filled in for line %2';
								|it = 'The ""%1"" column of the delivery parameters is not filled in for line %2';
								|pl = 'The ""%1"" column of the delivery parameters is not filled in for line %2';
								|tr = 'Teslimat parametrelerinin ""%1"" sütunu %2 satırı için doldurulmamış'");
	
	For Each DeliveryLine In DeliveryGoodsTable Do
		
		If DeliveryLine.DeliveryMethod = Enums.TransportMethods25.SelfPickup Then
			
			If UpdateData1 Then
				ResetDeliveryParameterLineData(DeliveryLine);
			EndIf;
			
			Continue;
			
		EndIf;
		
		LineNumber = Format(DeliveryLine.DocumentRowNumber, "NG=");
		PathToField = CommonClientServer.PathToTabularSection(
			"Goods", DeliveryLine.DocumentRowNumber, "LineNumber");
			
		If DeliveryLine.DeliveryMethod.IsEmpty() Then
			
			If OutputFillingErrors Then
				
				FieldName = NStr("ru = 'Способ доставки';
								|vi = 'Delivery method';
								|en = 'Delivery method'; fa = 'روش تحویل';
								|it = 'Metodo di consegna';
								|pl = 'Sposób dostarczenia';
								|tr = 'Teslimat yöntemi'");
				CheckFillingOfTableField(DeliveryLine.DeliveryMethod, ErrorTemplateColumn, FieldName, LineNumber, DataKey, PathToField, Cancel);
				
			EndIf;
			
			Continue;
			
		EndIf;
		
		#Region PointOfDeliveryZone
		DeliveryPointIsSet = True;
		DeliveryZoneIsSet = True;
		
		CheckUpdateDataOnDeliveryPoint(
			OwnerSDeliveryPointData,
			DeliveryPointDataTables,
			DeliveryLine.DeliveryPoint,
			DeliveryPointIsSet,
			DeliveryLine.DeliveryZone,
			DeliveryZoneIsSet,
			UpdateData1,
			OnlyReset);
			
		If Not DeliveryPointIsSet
			And OutputFillingErrors Then
			
			FieldName = NStr("ru = 'Точка доставки';
							|vi = 'Delivery point';
							|en = 'Delivery point'; fa = 'نقطه تحویل';
							|it = 'Delivery point';
							|pl = 'Delivery point';
							|tr = 'Teslimat noktası'");
			CheckFillingOfTableField(Undefined, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
			
		EndIf;
		
		If Not DeliveryZoneIsSet
			And OutputFillingErrors Then
			
			FieldName = NStr("ru = 'Зона доставки';
							|vi = 'Delivery zone';
							|en = 'Delivery zone'; fa = 'منطقه تحویل';
							|it = 'Area di consegna';
							|pl = 'Strefa dostawy';
							|tr = 'Teslimat bölgesi'");
			CheckFillingOfTableField(Undefined, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
			
		EndIf;
		#EndRegion
		
		If DeliveryLine.DeliveryMethod = Enums.TransportMethods25.OwnDelivery Then
			
			If DeliveryLine.DeliveryToCarrier Then
				
				If OutputFillingErrors Then
					
					FieldName = NStr("ru = 'Перевозчик';
									|vi = 'Carrier';
									|en = 'Carrier'; fa = 'حمل‌کننده';
									|it = 'Carrier';
									|pl = 'Carrier';
									|tr = 'Taşıyıcı'");
					CheckFillingOfTableField(DeliveryLine.Carrier, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
					
					FieldName = NStr("ru = 'Точка доставки перевозчика';
									|vi = 'Carrier delivery point';
									|en = 'Carrier delivery point'; fa = 'نقطه تحویل حمل‌کننده';
									|it = 'Carrier delivery point';
									|pl = 'Carrier delivery point';
									|tr = 'Taşıyıcı teslimat noktası'");
					CheckFillingOfTableField(DeliveryLine.CarrierDeliveryPoint, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
					
					FieldName = NStr("ru = 'Зона доставки перевозчика';
									|vi = 'Carrier delivery zone';
									|en = 'Carrier delivery zone'; fa = 'منطقه تحویل حمل‌کننده';
									|it = 'Carrier delivery zone';
									|pl = 'Carrier delivery zone';
									|tr = 'Taşıyıcı teslimat bölgesi'");
					CheckFillingOfTableField(DeliveryLine.CarrierSDeliveryArea, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
					
				EndIf;
				
			Else
				
				If UpdateData1 Then
					
					DeliveryLine.Carrier = Catalogs.Partners.EmptyRef();
					DeliveryLine.CarrierDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
					DeliveryLine.CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If DeliveryLine.DeliveryMethod = Enums.TransportMethods25.ByCarrier Then
			
			If OutputFillingErrors Then
				
				FieldName = NStr("ru = 'Перевозчик';
								|vi = 'Carrier';
								|en = 'Carrier'; fa = 'حمل‌کننده';
								|it = 'Carrier';
								|pl = 'Carrier';
								|tr = 'Taşıyıcı'");
				CheckFillingOfTableField(DeliveryLine.Carrier, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
				
			EndIf;
			
			If UpdateData1 Then
				
				DeliveryLine.CarrierDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
				DeliveryLine.CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
				
			EndIf;
			
		EndIf;
		
		If DeliveryLine.SpecialTransportationConditions Then
			
			If OutputFillingErrors Then
				
				FieldName = NStr("ru = 'Описание особых условий перевозки';
								|vi = 'Description of special transportation conditions';
								|en = 'Description of special transportation conditions'; fa = 'شرح شرایط ویژه حمل‌ونقل';
								|it = 'Descrizione delle condizioni particolari di trasporto';
								|pl = 'Opis szczególnych warunków przewozu';
								|tr = 'Özel nakliye koşullarının ayrıntıları'");
				CheckFillingOfTableField(DeliveryLine.SpecialTransportationConditionsDescription, ErrorTemplateField, FieldName, LineNumber, DataKey, PathToField, Cancel);
				
			EndIf;
			
		Else
			
			If UpdateData1 Then
				DeliveryLine.SpecialTransportationConditionsDescription = "";
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If UpdateData1 Then
		
		GoodsToDeliver = Object[Settings.GoodsForDeliveryTableName]; // TabularSection
		GoodsToDeliver.Load(DeliveryGoodsTable);
		
	EndIf;
	
EndProcedure

Procedure CheckFillingOfTableField(FieldToCheck, ErrorTemplate, FieldName, LineNumber, DataKey, PathToField, Cancel)
	
	If Not ValueIsFilled(FieldToCheck) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			FieldName,
			LineNumber);
		Common.MessageToUser(ErrorText, DataKey, PathToField, "Object", Cancel);
		
	EndIf;
	
EndProcedure

Procedure ResetDeliveryParameterLineData(Val DeliveryLine)
	
	DeliveryLine.DeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
	DeliveryLine.DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
	
	DeliveryLine.DeliveryToCarrier = False;
	DeliveryLine.Carrier = Catalogs.Partners.EmptyRef();
	DeliveryLine.CarrierDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
	DeliveryLine.CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
	
	DeliveryLine.DeliveryTimeFrom = Date(1, 1, 1, 0, 0, 0);
	DeliveryLine.DeliveryTimeTo = Date(1, 1, 1, 0, 0, 0);
	
	DeliveryLine.AdditionalDeliveryInformation = "";
	
	DeliveryLine.SpecialTransportationConditions = False;
	DeliveryLine.SpecialTransportationConditionsDescription = "";

EndProcedure

Procedure CheckUpdateDataOnDeliveryPoint(Val DataOfDeliveryPoint, Val OwnersOfDeliveryPoints, DeliveryPoint, DeliveryPointIsSet, DeliveryZone, DeliveryZoneIsSet, Val UpdateData1, Val OnlyReset)
	
	OwnerOfCurrentDeliveryPoint = OwnersOfDeliveryPoints[DeliveryPoint];
	
	If DeliveryPoint.IsEmpty()
		Or DataOfDeliveryPoint.Owner <> OwnerOfCurrentDeliveryPoint Then
		
		If Not DeliveryZone.IsEmpty()
			And DataOfDeliveryPoint.Owner = OwnerOfCurrentDeliveryPoint Then
			
			DeliveryPointIsSet = False;
			
		ElsIf DataOfDeliveryPoint.DeliveryPoint.IsEmpty() Then
			
			DeliveryPointIsSet = False;
			DeliveryZoneIsSet = False;
			
		Else
			
			If DataOfDeliveryPoint.DeliveryZone.IsEmpty() Then
				DeliveryZoneIsSet = False;
			EndIf;
			
			If UpdateData1 Then
				
				DeliveryPoint = DataOfDeliveryPoint.DeliveryPoint;
				DeliveryZone = DataOfDeliveryPoint.DeliveryZone;
				
			EndIf;
			
		EndIf;
		
	Else
		
		If DataOfDeliveryPoint.Owner = OwnerOfCurrentDeliveryPoint Then
			
			If DeliveryZone.IsEmpty()
				And (DeliveryPoint <> DataOfDeliveryPoint.DeliveryPoint
					Or DataOfDeliveryPoint.DeliveryZone.IsEmpty()) Then
				
				DeliveryZoneIsSet = False;
				
			ElsIf DeliveryZone.IsEmpty()
				And DeliveryPoint = DataOfDeliveryPoint.DeliveryPoint
				And UpdateData1 Then
				
				DeliveryZone = DataOfDeliveryPoint.DeliveryZone;
				
			EndIf;
			
		Else
			
			If DataOfDeliveryPoint.DeliveryPoint.IsEmpty()
				Or OnlyReset Then
				
				DeliveryPointIsSet = False;
				DeliveryZoneIsSet = False;
				
				If UpdateData1 Then
					
					DeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
					DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
					
				EndIf;
				
			Else
				
				If DataOfDeliveryPoint.DeliveryZone.IsEmpty() Then
					
					DeliveryZoneIsSet = False;
					If UpdateData1 Then
						DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  DeliveryWarehouses - Array of CatalogRef.Warehouses
//  TableOfCurrentData - ValueTable - table of current data on warehouses:
//    * Warehouse - CatalogRef.Warehouses
//    * WarehousePoint - CatalogRef.DeliveryPoints
//    * AreaOfWarehouse - CatalogRef.DeliveryZones
// 
// Returns:
//  Structure - Generate Delivery Data For Warehouses:
// * WarehouseDuplicates - ValueTable:
//    ** Warehouse - CatalogRef.Warehouses 
// * InformationTable_ - ValueTable:
//    ** Warehouse - CatalogRef.Warehouses
//    ** WarehousePoint - CatalogRef.DeliveryPoints
//    ** AreaOfWarehouse - CatalogRef.DeliveryZones
// 
Function GenerateDeliveryDataForWarehouses(DeliveryWarehouses, TableOfCurrentData)
	
	Result = New Structure;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TTTableOfInformation.Warehouse AS Warehouse,
	|	TTTableOfInformation.WarehousePoint AS WarehousePoint,
	|	TTTableOfInformation.AreaOfWarehouse AS AreaOfWarehouse
	|INTO TTCurrentInformation
	|FROM
	|	&TableWarehousesDeliveryDetails AS TTTableOfInformation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Warehouses.Ref AS Warehouse,
	|	ISNULL(DeliveryPoints.Ref, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS DeliveryPoint,
	|	ISNULL(DeliveryPoints.DeliveryZone, VALUE(Catalog.DeliveryZones.EmptyRef)) AS DeliveryZone
	|INTO TTDataByWarehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON Warehouses.Ref = DeliveryPoints.Owner
	|			AND (DeliveryPoints.MainPoint)
	|WHERE
	|	Warehouses.Ref IN(&References)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCurrentInformation.Warehouse AS Warehouse,
	|	1 AS RecordsCount
	|FROM
	|	TTCurrentInformation AS TTCurrentInformation
	|
	|GROUP BY
	|	TTCurrentInformation.Warehouse
	|
	|HAVING
	|	COUNT(1) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataByWarehouses.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TTCurrentInformation.WarehousePoint IS NULL
	|			THEN TTDataByWarehouses.DeliveryPoint
	|		WHEN TTCurrentInformation.WarehousePoint = VALUE(Catalog.DeliveryPoints.EmptyRef)
	|			THEN TTDataByWarehouses.DeliveryPoint
	|		ELSE TTCurrentInformation.WarehousePoint
	|	END AS WarehousePoint,
	|	CASE
	|		WHEN TTCurrentInformation.AreaOfWarehouse IS NULL
	|			THEN TTDataByWarehouses.DeliveryZone
	|		WHEN TTCurrentInformation.AreaOfWarehouse = VALUE(Catalog.DeliveryZones.EmptyRef)
	|			THEN ISNULL((CASE
	|						WHEN TTCurrentInformation.WarehousePoint IS NULL
	|							THEN TTDataByWarehouses.DeliveryPoint
	|						WHEN TTCurrentInformation.WarehousePoint = VALUE(Catalog.DeliveryPoints.EmptyRef)
	|							THEN TTDataByWarehouses.DeliveryPoint
	|						ELSE TTCurrentInformation.WarehousePoint
	|					END).DeliveryZone, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|		WHEN TTCurrentInformation.WarehousePoint IS NULL
	|			THEN ISNULL(TTDataByWarehouses.DeliveryPoint.DeliveryZone, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|		WHEN TTCurrentInformation.WarehousePoint = VALUE(Catalog.DeliveryPoints.EmptyRef)
	|			THEN ISNULL(TTDataByWarehouses.DeliveryPoint.DeliveryZone, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|		ELSE TTCurrentInformation.AreaOfWarehouse
	|	END AS AreaOfWarehouse
	|FROM
	|	TTDataByWarehouses AS TTDataByWarehouses
	|		LEFT JOIN TTCurrentInformation AS TTCurrentInformation
	|		ON TTDataByWarehouses.Warehouse = TTCurrentInformation.Warehouse
	|
	|ORDER BY
	|	Warehouse";
	Query.Text = QueryText;
	Query.SetParameter("References", DeliveryWarehouses);
	Query.SetParameter("TableWarehousesDeliveryDetails", TableOfCurrentData);
	
	ResultsArray = Query.ExecuteBatch();
	NumberOfRequests_ = ResultsArray.Count();
	WarehouseDuplicates = ResultsArray[NumberOfRequests_ - 2].Unload();
	TableOfNewWarehouseInformation = ResultsArray[NumberOfRequests_ - 1].Unload();
	
	Result.Insert("WarehouseDuplicates", WarehouseDuplicates);
	Result.Insert("InformationTable_", TableOfNewWarehouseInformation);
	
	Return Result;
	
EndFunction

// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  Cancel  - Boolean
//  UpdateData1 - Boolean - indicates the need to write updated data to the table
//  OutputFillingErrors - Boolean - indicates whether it is necessary to display filling errors
//
Procedure CheckUpdateDetailsOfDeliveryDataByWarehouses(Val Settings, Cancel, UpdateData1 = False, OutputFillingErrors = True)
	
	WarehousesDeliveryDetailsTableName = "WarehousesDeliveryInformation";
	
	Object = Settings.DocumentObject; // DocumentObject
	DeliveryWarehouses = CommonClientServer.CollapseArray(Settings.DeliveryWarehouses);
	CommonClientServer.DeleteValueFromArray(DeliveryWarehouses, Catalogs.Warehouses.EmptyRef());
	
	TabularPartOfInformation = Object[WarehousesDeliveryDetailsTableName]; // TabularSection
	
	TableWarehousesDeliveryDetails = TabularPartOfInformation.Unload();
	WarehouseData = GenerateDeliveryDataForWarehouses(DeliveryWarehouses, TableWarehousesDeliveryDetails);
	
	ThereAreDuplicates = False;
	DoubleMessageTemplate = NStr("ru = 'Для склада ""%1"" обнаружены дубли в записях сведений доставки, обновите настройки доставки.';
								|vi = 'Duplicates are found in the delivery information records for the ""%1"" warehouse. Update the delivery settings.';
								|en = 'Duplicates are found in the delivery information records for the ""%1"" warehouse. Update the delivery settings.'; fa = 'Duplicates are found in the delivery information records for the ""%1"" warehouse. Update the delivery settings.';
								|it = 'Duplicates are found in the delivery information records for the ""%1"" warehouse. Update the delivery settings.';
								|pl = 'Duplicates are found in the delivery information records for the ""%1"" warehouse. Update the delivery settings.';
								|tr = '""%1"" ambarı için teslimat bilgileri kayıtlarında yinelenen öğeler tespit edildi, teslimat ayarlarını güncelleyin.'");
	For Each DuplicateRow In WarehouseData.WarehouseDuplicates Do
		
		ThereAreDuplicates = True;
		
		If OutputFillingErrors Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				DoubleMessageTemplate,
				String(DuplicateRow));
			
			Common.MessageToUser(
				MessageText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	If Not ThereAreDuplicates
		And OutputFillingErrors Then
		
		CheckFillingOutWarehouseInformation(Object, WarehouseData.InformationTable_, Cancel);
		
	EndIf;
	
	If Not Cancel
		And UpdateData1 Then
		
		TabularPartOfInformation.Load(WarehouseData.InformationTable_);
		
	EndIf;
	
EndProcedure

Procedure CheckFillingOutWarehouseInformation(Val Object, Val InformationTable_, Cancel )
	
	MessageTemplateDot = NStr("ru = 'Для склада ""%1"" не указана точка отправки';
								|vi = 'No sending point is specified for the ""%1"" warehouse';
								|en = 'No sending point is specified for the ""%1"" warehouse'; fa = 'No sending point is specified for the ""%1"" warehouse';
								|it = 'No sending point is specified for the ""%1"" warehouse';
								|pl = 'No sending point is specified for the ""%1"" warehouse';
								|tr = '""%1"" ambarı için çıkış noktası belirtilmemiş'");
	MessageTemplateArea = NStr("ru = 'Для склада ""%1"" не указана зона отправки';
								|vi = 'No sending area is specified for the ""%1"" warehouse';
								|en = 'No sending area is specified for the ""%1"" warehouse'; fa = 'No sending area is specified for the ""%1"" warehouse';
								|it = 'No sending area is specified for the ""%1"" warehouse';
								|pl = 'No sending area is specified for the ""%1"" warehouse';
								|tr = '""%1"" ambarı için çıkış bölgesi belirtilmemiş'");
	
	For Each WarehouseLine_ In InformationTable_ Do
		
		If WarehouseLine_.WarehousePoint.IsEmpty() Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplateDot,
				String(WarehouseLine_.Warehouse));
			
			Common.MessageToUser(
				MessageText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
		If WarehouseLine_.AreaOfWarehouse.IsEmpty() Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplateArea,
				String(WarehouseLine_.Warehouse));
			
			Common.MessageToUser(
				MessageText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Settings - See NewSettingsForCheckingUseOfDeliveryDetails
//  DeliverySpecificationMethod - EnumRef.DeliverySpecificationMethods
//  Cancel  - Boolean
//
Procedure CheckIntersectionOfCustomerAndCarrier(Settings, DeliverySpecificationMethod, Cancel)
	
	If Not ValueIsFilled(Settings.OwnerOfDeliveryPoints) Then
		Return;
	EndIf;
	
	Object = Settings.DocumentObject; // DocumentObject
	PartnerCarrier = Object[Settings.CarrierFieldName]; // CatalogRef.Partners
	PartnerPresentation_ = String(Settings.OwnerOfDeliveryPoints);
	
	If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
		
		If IsBlankString(Settings.DeliveryMethod_FieldName) Then
			DeliveryMethod = Settings.DeliveryMethodIsUnconditional;
		Else
			DeliveryMethod = Object[Settings.DeliveryMethod_FieldName]; // EnumRef.TransportMethods25
		EndIf;
		
		If IsBlankString(Settings.DeliveryToCarrierFieldName) Then
			DeliveryToCarrier = Settings.DeliveryToCarrierIsUnconditional;
		Else
			DeliveryToCarrier = Object[Settings.DeliveryToCarrierFieldName]; // Boolean
		EndIf;
		
		If ThisIsDeliveryMethodWithCarrier(DeliveryMethod, DeliveryToCarrier)
			And Settings.OwnerOfDeliveryPoints = PartnerCarrier Then
			
			MessageTemplate = NStr("ru = 'Совпадают данные получателя и перевозчика (%1), оформление доставки невозможно.';
									|vi = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
									|en = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.'; fa = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
									|it = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
									|pl = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
									|tr = 'Alıcı ve taşıyıcı verileri (%1) eşleşiyor, teslimat oluşturma mümkün değil.'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PartnerPresentation_);
			
			Common.MessageToUser(
				MessageText,
				Object,
				"DeliveryIsRequired",
				,
				Cancel);
			
		EndIf;
		
	Else
		
		MessageTemplate = NStr("ru = 'Совпадают данные получателя и перевозчика (%1), оформление доставки по строке %2 невозможно.';
								|vi = 'The details of the recipient and the carrier match (%1). Cannot register the delivery for line %2.';
								|en = 'The details of the recipient and the carrier match (%1). Cannot register the delivery for line %2.'; fa = 'The details of the recipient and the carrier match (%1). Cannot register the delivery for line %2.';
								|it = 'The details of the recipient and the carrier match (%1). Cannot register the delivery for line %2.';
								|pl = 'The details of the recipient and the carrier match (%1). Cannot register the delivery for line %2.';
								|tr = 'Alıcı ve taşıyıcı verileri (%1) eşleşiyor, %2 satırına göre teslimat oluşturma mümkün değil.'");
		DeliveryGoodsTable = Settings.DeliveryGoodsTable;
		DataKey = TMCommonUse.DataKeyForMessageToUser(Object);
		
		For Each DeliveryLine In DeliveryGoodsTable Do
			
			If Not (ThisIsDeliveryMethodWithCarrier(DeliveryLine.DeliveryMethod, DeliveryLine.DeliveryToCarrier)
				And Settings.OwnerOfDeliveryPoints = DeliveryLine.Carrier) Then
				
				Continue;
				
			EndIf;
			
			LineNumber = Format(DeliveryLine.DocumentRowNumber, "NG=");
			PathToField = CommonClientServer.PathToTabularSection(
				"Goods", DeliveryLine.DocumentRowNumber, "LineNumber");
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PartnerPresentation_,
				LineNumber);
			
			Common.MessageToUser(ErrorText, DataKey, PathToField, "Object", Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function ThisIsDeliveryMethodWithCarrier(DeliveryMethod, DeliveryToCarrier)
	
	Result = True;
	
	If DeliveryMethod.IsEmpty()
		Or DeliveryMethod = Enums.TransportMethods25.SelfPickup
		Or DeliveryMethod = Enums.TransportMethods25.OurCourier
		Or DeliveryMethod = Enums.TransportMethods25.DefinedByDeliveryService
		Or (DeliveryMethod = Enums.TransportMethods25.OwnDelivery
			And Not DeliveryToCarrier) Then
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns:
//  ValueTable - New Delivery Goods Table:
// * DocumentRowNumber - Number 
// * RowCode - Number 
// * Products - CatalogRef.Products 
// * Characteristic - CatalogRef.ItemsCharacteristics 
// * Series - CatalogRef.ItemsBatches
// * DeliveryMethod - EnumRef.TransportMethods25
// * DeliveryPoint - CatalogRef.DeliveryPoints
// * DeliveryZone - CatalogRef.DeliveryZones
// * DeliveryToCarrier - Boolean
// * Carrier - CatalogRef.Partners
// * CarrierDeliveryPoint - CatalogRef.DeliveryPoints
// * CarrierSDeliveryArea - CatalogRef.DeliveryZones
// * DeliveryTimeFrom - Date
// * DeliveryTimeTo - Date
// * AdditionalDeliveryInformation - String 
// * SpecialTransportationConditions - Boolean
// * SpecialTransportationConditionsDescription - String
//
Function NewDeliveryGoodsTable()
	
	NumberType5 = Common.TypeDescriptionNumber(5,, AllowedSign.Nonnegative);
	NumberType10 = Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative);
	TypeTime = Common.DateTypeDetails(DateFractions.Time);
	StringType0 = Common.StringTypeDetails(0);
	BooleanType = New TypeDescription("Boolean");
	
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeCharacteristic = New TypeDescription("CatalogRef.ItemsCharacteristics");
	ProductSeriesType = New TypeDescription("CatalogRef.ItemsBatches");
	TypeDeliveryMethod = New TypeDescription("EnumRef.TransportMethods25");
	TypeOfCarrier = New TypeDescription("CatalogRef.Partners");
	TypeDeliveryPoint = New TypeDescription("CatalogRef.DeliveryPoints");
	TypeOfDeliveryZone = New TypeDescription("CatalogRef.DeliveryZones");
	
	Table = New ValueTable;
	Table.Columns.Add("DocumentRowNumber", NumberType5);
	Table.Columns.Add("RowCode", NumberType10);
	Table.Columns.Add("Products", TypeProducts);
	Table.Columns.Add("Characteristic", TypeCharacteristic);
	Table.Columns.Add("Series", ProductSeriesType);
	Table.Columns.Add("DeliveryMethod", TypeDeliveryMethod);
	Table.Columns.Add("DeliveryPoint", TypeDeliveryPoint);
	Table.Columns.Add("DeliveryZone", TypeOfDeliveryZone);
	Table.Columns.Add("DeliveryToCarrier", BooleanType);
	Table.Columns.Add("Carrier", TypeOfCarrier);
	Table.Columns.Add("CarrierDeliveryPoint", TypeDeliveryPoint);
	Table.Columns.Add("CarrierSDeliveryArea", TypeOfDeliveryZone);
	Table.Columns.Add("DeliveryTimeFrom", TypeTime);
	Table.Columns.Add("DeliveryTimeTo", TypeTime);
	Table.Columns.Add("AdditionalDeliveryInformation", StringType0);
	Table.Columns.Add("SpecialTransportationConditions", BooleanType);
	Table.Columns.Add("SpecialTransportationConditionsDescription", StringType0);
	
	Return Table;
	
EndFunction

// Parameters:
//  VerificationInTransaction - Boolean -
// 
// Returns:
//  Boolean -
//
Function ThereAreLeftoversToBeShippedBeforeEndOfTransitionToDelivery25(VerificationInTransaction = False)
	
	TransportMethods = New Array; // Array of  EnumRef.TransportMethods
	TransportMethods.Add(Enums.TransportMethods.ToCustomer);
	TransportMethods.Add(Enums.TransportMethods.ByCarrier);
	TransportMethods.Add(Enums.TransportMethods.ByCarrierToAddress);
	TransportMethods.Add(Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany);
	
	QueryTextReferences =
	"SELECT
	|	StatesAndDetailsOfDelivery.ReferenceOrder AS ReferenceOrder,
	|	StatesAndDetailsOfDelivery.Warehouse AS Warehouse,
	|	StatesAndDetailsOfDelivery.DeliveryMethod AS DeliveryMethod
	|INTO TT_References
	|FROM
	|	InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|WHERE
	|	StatesAndDetailsOfDelivery.DeliveryMethod IN(&TransportMethods)
	|	AND StatesAndDetailsOfDelivery.Warehouse.StartShipmentOnceDeliveryOrderIsCreated";
	
	Query = New Query;
	Query.SetParameter("TransportMethods", TransportMethods);
	Query.Text = QueryTextReferences;
	Query.TempTablesManager = New TempTablesManager();
	Query.Execute();
	
	If VerificationInTransaction Then
		
		QueryTextBlockedValues =
		"SELECT
		|	References.ReferenceOrder AS ReferenceOrder,
		|	References.Warehouse AS Warehouse,
		|	References.DeliveryMethod AS DeliveryMethod
		|FROM
		|	TT_References AS References";
		
		Query.Text = QueryTextBlockedValues;
		QueryResult = Query.Execute();
		
		Try
			
			Block = New DataLock();
			
			LockItem = Block.Add("InformationRegister.StatesAndDetailsOfDelivery");
			LockItem.DataSource = QueryResult;
			LockItem.UseFromDataSource("Warehouse", "Warehouse");
			LockItem.UseFromDataSource("DeliveryMethod", "DeliveryMethod");
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("AccumulationRegister.GoodsForIssue");
			LockItem.DataSource = QueryResult;
			LockItem.UseFromDataSource("DocumentShipments", "ReferenceOrder");
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
		Except
			
			Raise;
			
		EndTry;
		
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsForIssueBalance.Warehouse AS Warehouse,
	|	GoodsForIssueBalance.ToShipBalance AS ToShipBalance
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN
	|		(SELECT
	|			References.ReferenceOrder AS DocumentShipments
	|		FROM
	|			TT_References AS References)) AS GoodsForIssueBalance";
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	IsBalance = Not Result.IsEmpty();
	
	Return IsBalance;
	
EndFunction

// Returns:
// Structure - Additional delivery parameters from the order header:
// * DeliveryTimeFrom - Date - 
// * DeliveryTimeTo - Date - 
// * AdditionalDeliveryInformation - String - 
// * SpecialTransportationConditions - Boolean - 
// * SpecialTransportationConditionsDescription - String - 
// * Match - Boolean
//
Function AddlParameters()
	
	EmptyTime = '00010101';
	IsBlankString = "";
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Match", True);
	AddlParameters.Insert("DeliveryTimeFrom", EmptyTime);
	AddlParameters.Insert("DeliveryTimeTo", EmptyTime);
	AddlParameters.Insert("AdditionalDeliveryInformation", IsBlankString);
	AddlParameters.Insert("SpecialTransportationConditions", False);
	AddlParameters.Insert("SpecialTransportationConditionsDescription", IsBlankString);
	
	Return AddlParameters;
	
EndFunction

// Parameters:
//  Objects - Array of Arbitrary - objects to group.
// 
// Returns:
//  Map of KeyAndValue:
//  * Key - Type
//  * Value - Array of Arbitrary
//
Function ObjectsByTypes(Objects)
	
	ObjectsByTypes = New Map;
	
	For Each Object In Objects Do
		
		ObjectsOfType = ObjectsByTypes[TypeOf(Object)];
		
		If ObjectsOfType = Undefined Then
			
			ObjectsOfType = New Array;
			ObjectsByTypes.Insert(TypeOf(Object), ObjectsOfType);
			
		EndIf;
		
		ObjectsOfType.Add(Object);
		
	EndDo;
	
	Return ObjectsByTypes;
	
EndFunction

// Returns:
//  ValueTable:
// * SalesOrder - DocumentRef.SalesOrder -
// * OrderLineCode - Number -
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics - 
// * Series - CatalogRef.ItemsBatches - 
// * Count - Number -
// * FinalDeliveryPoint - CatalogRef.DeliveryPoints - 
//
Function NewOrderAddressData()
	
	Type_Order = Metadata.Documents.CustomerInvoice.TabularSections.Goods.Attributes.SalesOrder.Type;
	TypeCode = Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative);
	TypeQuantity = Common.TypeDescriptionNumber(15, 3);
	
	DataOfAddresses = New ValueTable;
	DataOfAddresses.Columns.Add("SalesOrder", Type_Order);
	DataOfAddresses.Columns.Add("OrderLineCode", TypeCode);
	DataOfAddresses.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	DataOfAddresses.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	DataOfAddresses.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	DataOfAddresses.Columns.Add("Count", TypeQuantity);
	DataOfAddresses.Columns.Add("FinalDeliveryPoint", New TypeDescription("CatalogRef.DeliveryPoints"));
	
	Return DataOfAddresses;
	
EndFunction

Function QueryTextOfTheseDeliveryOrders()
	
	QueryText =
	"SELECT
	|	Goods.Ref AS Ref,
	|	Goods.SalesOrder AS SalesOrder,
	|	CASE
	|		WHEN Goods.SalesOrder = UNDEFINED
	|			THEN Goods.Ref
	|		ELSE Goods.SalesOrder
	|	END AS ReferenceOrder,
	|	Goods.RowCode AS RowCode,
	|	Goods.DeliveryLineCode AS DeliveryLineCode,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count
	|INTO TT_ImplementationData
	|FROM
	|	Document.CustomerInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND (&WithoutFilterByProducts
	|		OR Goods.Products IN (&FilterOfProductItem))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImplementationData.Ref AS Ref,
	|	ImplementationData.SalesOrder AS SalesOrder,
	|	ImplementationData.RowCode AS RowCode,
	|	ImplementationData.DeliveryLineCode AS DeliveryLineCode,
	|	ImplementationData.Products AS Products,
	|	ImplementationData.Characteristic AS Characteristic,
	|	ImplementationData.Series AS Series,
	|	ImplementationData.Count AS Count
	|INTO TT_RowsNotByOrder
	|FROM
	|	TT_ImplementationData AS ImplementationData
	|WHERE
	|	ImplementationData.SalesOrder = UNDEFINED
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImplementationData.Ref AS Ref,
	|	ImplementationData.SalesOrder AS SalesOrder,
	|	ImplementationData.RowCode AS RowCode,
	|	ImplementationData.DeliveryLineCode AS DeliveryLineCode,
	|	ImplementationData.Products AS Products,
	|	ImplementationData.Characteristic AS Characteristic,
	|	ImplementationData.Series AS Series,
	|	ImplementationData.Count AS Count
	|INTO TT_LinesForOrders
	|FROM
	|	TT_ImplementationData AS ImplementationData
	|WHERE
	|	ImplementationData.SalesOrder <> UNDEFINED
	|	AND ImplementationData.RowCode <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImplementationData.Ref AS Ref,
	|	ImplementationData.SalesOrder AS SalesOrder,
	|	ImplementationData.RowCode AS RowCode,
	|	ImplementationData.DeliveryLineCode AS DeliveryLineCode,
	|	ImplementationData.Products AS Products,
	|	ImplementationData.Characteristic AS Characteristic,
	|	ImplementationData.Series AS Series,
	|	ImplementationData.Count AS Count
	|INTO TT_LinesBeyondOrder
	|FROM
	|	TT_ImplementationData AS ImplementationData
	|WHERE
	|	ImplementationData.SalesOrder <> UNDEFINED
	|	AND ImplementationData.RowCode = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.PlanningDocument AS PlanningDocument,
	|	Delivery.RowCode AS RowCode,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.ToDeliverTurnover AS ToDeliver,
	|	Delivery.ToTripTurnover AS ToTrip,
	|	Delivery.InTripTurnover AS InTrip
	|INTO TT_DeliveryDataNotOnOrder
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			Arm = 1
	|				AND (ReferenceOrder, Products, Characteristic, Series, RowCode) IN
	|					(SELECT
	|						T.Ref,
	|						T.Products,
	|						T.Characteristic,
	|						T.Series,
	|						T.DeliveryLineCode
	|					FROM
	|						TT_RowsNotByOrder AS T)) AS Delivery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.PlanningDocument AS PlanningDocument,
	|	Delivery.RowCode AS RowCode,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.ToDeliverTurnover AS ToDeliver,
	|	Delivery.ToTripTurnover AS ToTrip,
	|	Delivery.InTripTurnover AS InTrip
	|INTO TT_DeliveryDataForOrder
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			Arm = 1
	|				AND NOT PlanningDocument IN
	|						(SELECT
	|							T.Ref
	|						FROM
	|							TT_LinesForOrders AS T)
	|				AND (ReferenceOrder, Products, Characteristic, Series, RowCode) IN
	|					(SELECT
	|						T.SalesOrder,
	|						T.Products,
	|						T.Characteristic,
	|						T.Series,
	|						T.RowCode
	|					FROM
	|						TT_LinesForOrders AS T)) AS Delivery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.PlanningDocument AS PlanningDocument,
	|	Delivery.RowCode AS RowCode,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.ToDeliverTurnover AS ToDeliver,
	|	Delivery.ToTripTurnover AS ToTrip,
	|	Delivery.InTripTurnover AS InTrip
	|INTO TT_DeliveryDataInExcessOfOrder
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			Arm = 1
	|				AND (ReferenceOrder, PlanningDocument, Products, Characteristic, Series, RowCode) IN
	|					(SELECT
	|						T.SalesOrder,
	|						T.Ref,
	|						T.Products,
	|						T.Characteristic,
	|						T.Series,
	|						T.DeliveryLineCode
	|					FROM
	|						TT_LinesBeyondOrder AS T)) AS Delivery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryData.ReferenceOrder AS ReferenceOrder,
	|	DeliveryData.PlanningDocument AS PlanningDocument,
	|	DeliveryData.RowCode AS RowCode,
	|	DeliveryData.Products AS Products,
	|	DeliveryData.Characteristic AS Characteristic,
	|	DeliveryData.Series AS Series,
	|	DeliveryData.ToDeliver AS ToDeliver,
	|	DeliveryData.ToTrip AS ToTrip,
	|	DeliveryData.InTrip AS InTrip
	|INTO TT_DeliveryData
	|FROM
	|	TT_DeliveryDataNotOnOrder AS DeliveryData
	|
	|UNION ALL
	|
	|SELECT
	|	DeliveryData.ReferenceOrder,
	|	DeliveryData.PlanningDocument,
	|	DeliveryData.RowCode,
	|	DeliveryData.Products,
	|	DeliveryData.Characteristic,
	|	DeliveryData.Series,
	|	DeliveryData.ToDeliver,
	|	DeliveryData.ToTrip,
	|	DeliveryData.InTrip
	|FROM
	|	TT_DeliveryDataForOrder AS DeliveryData
	|
	|UNION ALL
	|
	|SELECT
	|	DeliveryData.ReferenceOrder,
	|	DeliveryData.PlanningDocument,
	|	DeliveryData.RowCode,
	|	DeliveryData.Products,
	|	DeliveryData.Characteristic,
	|	DeliveryData.Series,
	|	DeliveryData.ToDeliver,
	|	DeliveryData.ToTrip,
	|	DeliveryData.InTrip
	|FROM
	|	TT_DeliveryDataInExcessOfOrder AS DeliveryData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryData.ReferenceOrder AS ReferenceOrder,
	|	DeliveryData.PlanningDocument AS PlanningDocument,
	|	DeliveryData.RowCode AS RowCode,
	|	DeliveryData.Products AS Products,
	|	DeliveryData.Characteristic AS Characteristic,
	|	DeliveryData.Series AS Series,
	|	SUM(DeliveryData.InTrip) AS BalanceOfTrip,
	|	SUM(DeliveryData.ToTrip) - SUM(DeliveryData.InTrip) AS BalanceForFlight,
	|	SUM(DeliveryData.ToDeliver) - SUM(DeliveryData.ToTrip) AS BalanceForDelivery
	|INTO TT_BalancesOnPlanningDocuments
	|FROM
	|	TT_DeliveryData AS DeliveryData
	|
	|GROUP BY
	|	DeliveryData.ReferenceOrder,
	|	DeliveryData.PlanningDocument,
	|	DeliveryData.RowCode,
	|	DeliveryData.Products,
	|	DeliveryData.Characteristic,
	|	DeliveryData.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryData.ReferenceOrder AS ReferenceOrder,
	|	DeliveryData.RowCode AS RowCode,
	|	DeliveryData.Products AS Products,
	|	DeliveryData.Characteristic AS Characteristic,
	|	DeliveryData.Series AS Series,
	|	SUM(DeliveryData.InTrip) AS BalanceOfTrip,
	|	SUM(DeliveryData.ToTrip) - SUM(DeliveryData.InTrip) AS BalanceForFlight,
	|	SUM(DeliveryData.ToDeliver) - SUM(DeliveryData.ToTrip) AS BalanceForDelivery
	|INTO TT_RemainingQuantityAccToReference
	|FROM
	|	TT_DeliveryData AS DeliveryData
	|
	|GROUP BY
	|	DeliveryData.ReferenceOrder,
	|	DeliveryData.RowCode,
	|	DeliveryData.Products,
	|	DeliveryData.Characteristic,
	|	DeliveryData.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemainingQuantityAccToReference.ReferenceOrder AS ReferenceOrder,
	|	RemainingQuantityAccToReference.PlanningDocument AS PlanningDocument,
	|	RemainingQuantityAccToReference.RowCode AS RowCode,
	|	RemainingQuantityAccToReference.Products AS Products,
	|	RemainingQuantityAccToReference.Characteristic AS Characteristic,
	|	RemainingQuantityAccToReference.Series AS Series,
	|	ISNULL(Delivery.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS DeliveryPoint
	|INTO TT_PointsInTrip
	|FROM
	|	TT_BalancesOnPlanningDocuments AS RemainingQuantityAccToReference
	|		LEFT JOIN AccumulationRegister.Delivery AS Delivery
	|		ON RemainingQuantityAccToReference.ReferenceOrder = Delivery.ReferenceOrder
	|			AND RemainingQuantityAccToReference.PlanningDocument = Delivery.PlanningDocument
	|			AND RemainingQuantityAccToReference.RowCode = Delivery.RowCode
	|			AND (Delivery.OperationLevel = 30)
	|			AND (Delivery.ThisIsFinalArm)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.RowCode AS RowCode,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.RecipientPoint AS DeliveryPoint,
	|	Delivery.InTripTurnover AS Balance
	|INTO TT_BalanceInTrip
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			(ReferenceOrder, PlanningDocument, RowCode, RecipientPoint) IN
	|				(SELECT
	|					T.ReferenceOrder,
	|					T.PlanningDocument,
	|					T.RowCode,
	|					T.DeliveryPoint
	|				FROM
	|					TT_PointsInTrip AS T)) AS Delivery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOnPlanningDocuments.ReferenceOrder AS ReferenceOrder,
	|	BalancesOnPlanningDocuments.RowCode AS RowCode,
	|	BalancesOnPlanningDocuments.Products AS Products,
	|	BalancesOnPlanningDocuments.Characteristic AS Characteristic,
	|	BalancesOnPlanningDocuments.Series AS Series,
	|	BalancesOnPlanningDocuments.BalanceForFlight AS Balance,
	|	Delivery.RecipientPoint AS DeliveryPoint
	|INTO TT_BalanceForTrip
	|FROM
	|	TT_BalancesOnPlanningDocuments AS BalancesOnPlanningDocuments
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON BalancesOnPlanningDocuments.ReferenceOrder = Delivery.ReferenceOrder
	|			AND BalancesOnPlanningDocuments.PlanningDocument = Delivery.PlanningDocument
	|			AND BalancesOnPlanningDocuments.RowCode = Delivery.RowCode
	|			AND (Delivery.OperationLevel IN (15, 20))
	|			AND (Delivery.ThisIsFinalArm)
	|WHERE
	|	BalancesOnPlanningDocuments.BalanceForFlight <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemainingQuantityAccToReference.ReferenceOrder AS ReferenceOrder,
	|	RemainingQuantityAccToReference.RowCode AS RowCode,
	|	RemainingQuantityAccToReference.Products AS Products,
	|	RemainingQuantityAccToReference.Characteristic AS Characteristic,
	|	RemainingQuantityAccToReference.Series AS Series,
	|	RemainingQuantityAccToReference.BalanceForDelivery AS Balance,
	|	ISNULL(Delivery.RecipientPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS DeliveryPoint
	|INTO TT_BalancesForDelivery
	|FROM
	|	TT_RemainingQuantityAccToReference AS RemainingQuantityAccToReference
	|		LEFT JOIN AccumulationRegister.Delivery AS Delivery
	|		ON RemainingQuantityAccToReference.ReferenceOrder = Delivery.ReferenceOrder
	|			AND RemainingQuantityAccToReference.RowCode = Delivery.RowCode
	|			AND (Delivery.OperationLevel = 10)
	|			AND (Delivery.ThisIsFinalArm)
	|WHERE
	|	RemainingQuantityAccToReference.BalanceForDelivery <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN Balance.ReferenceOrder REFS Document.SalesOrder
	|			THEN Balance.ReferenceOrder
	|		ELSE UNDEFINED
	|	END AS SalesOrder,
	|	Balance.RowCode AS OrderLineCode,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Series AS Series,
	|	Balance.DeliveryPoint AS FinalDeliveryPoint,
	|	SUM(Balance.Balance) AS Count
	|FROM
	|	(SELECT
	|		Balance.ReferenceOrder AS ReferenceOrder,
	|		Balance.RowCode AS RowCode,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.Series AS Series,
	|		Balance.DeliveryPoint AS DeliveryPoint,
	|		Balance.Balance AS Balance
	|	FROM
	|		TT_BalanceInTrip AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Balance.ReferenceOrder,
	|		Balance.RowCode,
	|		Balance.Products,
	|		Balance.Characteristic,
	|		Balance.Series,
	|		Balance.DeliveryPoint,
	|		Balance.Balance
	|	FROM
	|		TT_BalanceForTrip AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Balance.ReferenceOrder,
	|		Balance.RowCode,
	|		Balance.Products,
	|		Balance.Characteristic,
	|		Balance.Series,
	|		Balance.DeliveryPoint,
	|		Balance.Balance
	|	FROM
	|		TT_BalancesForDelivery AS Balance) AS Balance
	|
	|GROUP BY
	|	Balance.ReferenceOrder,
	|	Balance.RowCode,
	|	Balance.DeliveryPoint,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Series
	|
	|ORDER BY
	|	SalesOrder,
	|	OrderLineCode,
	|	FinalDeliveryPoint,
	|	Products,
	|	Characteristic,
	|	Series";
	
	Return QueryText;
	
EndFunction

#Region WorkingWithDeliveryAddresses

Function QueryTextOfOwnersForCreatingDeliveryPoints()
	
	QueryText =
	"SELECT
	|	KIWarehouses.Ref AS Ref,
	|	COUNT(*) AS AddressesCount
	|INTO TT_AddressesOfOwners
	|FROM
	|	Catalog.Warehouses.ContactInformation AS KIWarehouses
	|WHERE
	|	NOT KIWarehouses.Ref.IsFolder
	|	AND KIWarehouses.Type = VALUE(Enum.ContactInformationTypes.Address)
	|	AND STRINGLENGTH(TRIMALL(KIWarehouses.Presentation)) > 0
	|GROUP BY
	|	KIWarehouses.Ref
	|HAVING
	|	COUNT(*) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	CIPartners.Ref AS Ref,
	|	COUNT(*) AS AddressesCount
	|FROM
	|	Catalog.Partners.ContactInformation AS CIPartners
	|WHERE
	|	CIPartners.Type = VALUE(Enum.ContactInformationTypes.Address)
	|	AND STRINGLENGTH(TRIMALL(CIPartners.Presentation)) > 0
	|GROUP BY
	|	CIPartners.Ref
	|HAVING
	|	COUNT(*) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 100
	|	AddressesOfOwners.Ref AS Ref
	|FROM
	|	TT_AddressesOfOwners AS AddressesOfOwners
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON AddressesOfOwners.Ref = DeliveryPoints.Owner
	|WHERE
	|	DeliveryPoints.Ref IS NULL
	|
	|ORDER BY
	|	Ref";
	
	Return QueryText;
	
EndFunction

// Parameters:
//  DeliveryPointOwner - CatalogRef.Warehouses
//                        - CatalogRef.Partners
//
Procedure CreateDeliveryPointsByOwner(DeliveryPointOwner)
	
	If Not Common.RefExists(DeliveryPointOwner) Then
		Return;
	EndIf;
	
	LockSpace = Common.TableNameByRef(DeliveryPointOwner);
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		LockItem = Block.Add(LockSpace);
		LockItem.SetValue("Ref", DeliveryPointOwner);
		LockItem = Block.Add("Catalog.DeliveryPoints");
		LockItem.SetValue("Owner", DeliveryPointOwner);
		Block.Lock();
		
		DeliveryPointsData = OwnerSDeliveryPointsData(DeliveryPointOwner);
		For Each PointData_ In DeliveryPointsData Do
			
			UpdateCreateDeliveryPoint(DeliveryPointOwner, PointData_, True);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		RecordErrorOfCreatingDeliveryPointsInLog(ErrorPresentation, DeliveryPointOwner);
		
	EndTry;
	
EndProcedure

Function OwnerSDeliveryPointsData(DeliveryPointOwner)
	
	If TypeOf(DeliveryPointOwner) = Type("CatalogRef.Warehouses") Then
		
		QueryText = QueryTextForWarehouseAddresses();
		CIKind = Catalogs.ContactInformationKinds.WarehouseAddress;
		
	ElsIf TypeOf(DeliveryPointOwner) = Type("CatalogRef.Partners") Then
		
		QueryText = AddressQueryTextPartner();
		CIKind = Catalogs.ContactInformationKinds.PartnerAddress;
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Owner", DeliveryPointOwner);
	Query.SetParameter("CIKind", CIKind);
	
	ContactInformationData = Query.Execute().Unload();
	DataOfAddresses = AddressDataAccordingToContactInformation(ContactInformationData);
	
	Filter = New Structure("Main", True);
	MainAddresses = DataOfAddresses.FindRows(Filter);
	SeveralMainAddresses = (MainAddresses.Count() > 1);
	
	DeliveryPointsData = NewDeliveryPointData();
	
	For Each AddressData In DataOfAddresses Do
		
		PointData_ = DeliveryPointsData.Add();
		PointData_.SeveralMainAddresses = SeveralMainAddresses;
		
		If SeveralMainAddresses Then
			
			MainAddress = False;
			
		Else
			
			MainAddress = AddressData.Main;
			
		EndIf;
		
		If Not MainAddress Then
			
			AddressData.DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
			
		EndIf;
		
		FillInDeliveryPointDataWithAddressData(PointData_, AddressData, MainAddress);
		CheckFillInPresentationOfAddress(PointData_);
		
	EndDo;
	
	Return DeliveryPointsData;
	
EndFunction

Procedure CheckFillInPresentationOfAddress(DataOfDeliveryPoint)
	
	If IsBlankString(DataOfDeliveryPoint.Address) Then
		
		Source = "";
		
		If Not IsBlankString(DataOfDeliveryPoint.AddressValue) Then
			
			Source = DataOfDeliveryPoint.AddressValue;
			
		ElsIf Not IsBlankString(DataOfDeliveryPoint.FieldValueAddress) Then
			
			Source = DataOfDeliveryPoint.FieldValueAddress;
			
		EndIf;
		
		If Not IsBlankString(Source) Then
			
			DataOfDeliveryPoint.Address = ContactsManager.ContactInformationPresentation(Source);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function QueryTextForWarehouseAddresses()
	
	QueryText =
	"SELECT
	|	ContactInformation.Presentation AS Presentation,
	|	ContactInformation.Value AS Value,
	|	ContactInformation.FieldValues AS FieldValues,
	|	ContactInformation.Kind AS Kind
	|FROM
	|	Catalog.Warehouses.ContactInformation AS ContactInformation
	|WHERE
	|	ContactInformation.Ref = &Owner
	|	AND ContactInformation.Type = VALUE(Enum.ContactInformationTypes.Address)
	|	AND TRIMALL(ContactInformation.Presentation) <> """"";
	
	Return QueryText;
	
EndFunction

Function AddressQueryTextPartner()
	
	QueryText =
	"SELECT
	|	ContactInformation.Presentation AS Presentation,
	|	ContactInformation.Value AS Value,
	|	ContactInformation.FieldValues AS FieldValues,
	|	ContactInformation.Ref.DeliveryZone AS DeliveryZone,
	|	ContactInformation.Kind AS Kind
	|FROM
	|	Catalog.Partners.ContactInformation AS ContactInformation
	|WHERE
	|	ContactInformation.Ref = &Owner
	|	AND ContactInformation.Type = VALUE(Enum.ContactInformationTypes.Address)
	|	AND TRIMALL(ContactInformation.Presentation) <> """"";
	
	Return QueryText;
	
EndFunction

Procedure RecordErrorOfCreatingDeliveryPointsInLog(ErrorPresentation, DeliveryPointOwner)
	
	EventName = NStr("ru = 'Переход на управление доставкой 2.5';
					|vi = 'Migration to delivery management 2.5';
					|en = 'Migration to delivery management 2.5'; fa = 'مهاجرت به مدیریت تحویل 2.5';
					|it = 'Migration to delivery management 2.5';
					|pl = 'Migration to delivery management 2.5';
					|tr = 'Teslimat 2.5 yönetimine geçiş'", Common.DefaultLanguageCode());
	
	MessageTemplate = NStr("ru = 'Не удалось создать точки доставки для %1 по причине:
								 |%2';
								 |vi = 'Cannot create delivery points for %1 due to:
								 |%2';
								 |en = 'Cannot create delivery points for %1 due to:
								 |%2'; fa = 'Cannot create delivery points for %1 due to:
								 |%2';
								 |it = 'Cannot create delivery points for %1 due to:
								 |%2';
								 |pl = 'Cannot create delivery points for %1 due to:
								 |%2';
								 |tr = '%1 için teslimat noktaları oluşturulamadı, sebep: 
								 |%2'");
	
	OwnerPresentation = Common.SubjectString(DeliveryPointOwner);
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		MessageTemplate,
		OwnerPresentation,
		ErrorPresentation);
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Warning,
		,
		DeliveryPointOwner,
		MessageText);
	
EndProcedure

// Parameters:
//  ContactInformationOwner - CatalogRef.Partners, CatalogRef.Warehouses -
//  FirstRecord - Boolean -
// 
// Returns:
//  See GoodsDelivery.NewDeliveryPointData
//
Function DataFromExistingDeliveryPoints(ContactInformationOwner, FirstRecord)
	
	DeliveryPointsData = NewDeliveryPointData();
	
	If Not FirstRecord Then
		
		QueryText = QueryTextForDeliveryPointData();
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Owner", ContactInformationOwner);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			PointData_ = DeliveryPointsData.Add();
			FillPropertyValues(PointData_, Selection);
			
		EndDo;
		
	EndIf;
	
	Return DeliveryPointsData;
	
EndFunction

Function QueryTextForDeliveryPointData()
	
	QueryText =
	"SELECT
	|	DeliveryPoints.Ref AS DeliveryPoint,
	|	DeliveryPoints.MainPoint AS MainPoint,
	|	DeliveryPoints.NotUsed AS NotUsed,
	|	DeliveryPoints.Address AS Address,
	|	DeliveryPoints.AddressValue AS AddressValue,
	|	DeliveryPoints.FieldValueAddress AS FieldValueAddress,
	|	DeliveryPoints.IDIsOverridden AS IDIsOverridden,
	|	TRIMALL(DeliveryPoints.DeliveryPointID) AS DeliveryPointID,
	|	DeliveryPoints.Description AS Description,
	|	DeliveryPoints.DeliveryZone AS DeliveryZone,
	|	TRIMALL(DeliveryPoints.AddressID) AS AddressID
	|FROM
	|	Catalog.DeliveryPoints AS DeliveryPoints
	|WHERE
	|	DeliveryPoints.Owner = &Owner
	|	AND NOT DeliveryPoints.DeletionMark
	|
	|ORDER BY
	|	AddressID";
	
	Return QueryText;
	
EndFunction

Function DataOfMainDeliveryPoint(DeliveryPointsData)
	
	Filter = New Structure;
	Filter.Insert("MainPoint", True);
	
	Rows = DeliveryPointsData.FindRows(Filter);
	
	If Rows.Count() > 0 Then
		
		TDData = Rows[0];
		
	Else
		
		TDData = Undefined;
		
	EndIf;
	
	Return TDData;
	
EndFunction

Function DeliveryPointDataAccordingToAddress(OwnerSTDData, AddressData)
	
	If ValueIsFilled(AddressData.Id) Then
		
		TDData =  DeliveryPointDataById(OwnerSTDData, AddressData.Id);
		
	ElsIf ValueIsFilled(AddressData.Address) Then
		
		TDData =  DeliveryPointDataByPresentation(OwnerSTDData, AddressData.Address);
		
	Else
		
		TDData = Undefined;
		
	EndIf;
	
	Return TDData;
	
EndFunction

Function DeliveryPointDataById(OwnerSTDData, AddressID)
	
	TDData = Undefined;
	
	If Not IsBlankString(AddressID) Then
		
		Filter = New Structure;
		Filter.Insert("AddressID", AddressID);
		Filter.Insert("DeliveryPointID", "");
		
		Rows = OwnerSTDData.FindRows(Filter);
		
		If Rows.Count() = 0 Then
			
			Filter = New Structure;
			Filter.Insert("DeliveryPointID", AddressID);
			
			Rows = OwnerSTDData.FindRows(Filter);
			
		EndIf;
		
		If Rows.Count() > 0 Then
			
			TDData = Rows[0];
			TDData.MatchedById = True;
			
		EndIf;
		
	EndIf;
	
	Return TDData;
	
EndFunction

Function DeliveryPointDataByPresentation(OwnerSTDData, AddressPresentation)
	
	TDData = Undefined;
	
	If Not IsBlankString(AddressPresentation) Then
		
		Filter = New Structure;
		Filter.Insert("Address", AddressPresentation);
		Filter.Insert("AddressID", "");
		Filter.Insert("DeliveryPointID", "");
		
		Rows = OwnerSTDData.FindRows(Filter);
		
		If Rows.Count() > 0 Then
			
			TDData = Rows[0];
			TDData.SelectedAt = True;
			
		EndIf;
		
	EndIf;
	
	Return TDData;
	
EndFunction

Procedure AddDataToChange(DataPointsToChange, PointData_)
	
	TDData = DataPointsToChange.Add();
	FillPropertyValues(TDData, PointData_);
	
EndProcedure

Procedure AddDataToChangeFewBasic(DataForProcessing_, DataOfOwnerSPoints, PrimaryAddressData, MainTDHasBeenChanged)
	
	DataFromExistingTD = DeliveryPointDataAccordingToAddress(DataOfOwnerSPoints, PrimaryAddressData);
	
	If DataFromExistingTD <> Undefined Then
		
		If DataFromExistingTD.MainPoint Then
			
			UpdateRequired = True;
			MainTDHasBeenChanged = True;
			
		ElsIf DataFromExistingTD.NotUsed Then
			
			UpdateRequired = True;
			
		Else
			
			UpdateRequired = False;
			
		EndIf;
		
		If UpdateRequired Then
			
			DataFromExistingTD.MainPoint = False;
			DataFromExistingTD.NotUsed = False;
			DataFromExistingTD.SeveralMainAddresses = True;
			
			AddDataToChange(DataForProcessing_, DataFromExistingTD);
			
		EndIf;
		
	Else
		
		TDData = DataForProcessing_.Add();
		TDData.SeveralMainAddresses = True;
		FillInDeliveryPointDataWithAddressData(TDData, PrimaryAddressData);
		
	EndIf;
	
EndProcedure

Procedure AddDataToChangeOneMain(DataForProcessing_, DataOfOwnerSPoints, PrimaryAddressData, DataOfMainTD)
	
	ThisIsAddressOfMainTD = AddressCorrespondsToMainDeliveryPoint(PrimaryAddressData, DataOfMainTD);
	
	If ThisIsAddressOfMainTD Then
		
		DataOfMainTD.UpdatingMainPoint = True;
		If Not AddressesAreEqual(DataOfMainTD, PrimaryAddressData) Then
			
			FillInDeliveryPointDataWithAddressData(DataOfMainTD, PrimaryAddressData, True);
			AddDataToChange(DataForProcessing_, DataOfMainTD);
			
		EndIf;
		
	Else
		
		PointAtMainAddress = DeliveryPointDataAccordingToAddress(DataOfOwnerSPoints, PrimaryAddressData);
		
		If Not ValueIsFilled(PointAtMainAddress)
			Or Not PointAtMainAddress.MainPoint Then
			
			DataOfMainTD.MainPoint = False;
			AddDataToChange(DataForProcessing_, DataOfMainTD);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDeliveryPointDataWithAddressData(TDData, AddressData, Main = False)
	
	If Not ValueIsFilled(TDData.DeliveryPoint) Then
		
		FillPropertyValues(TDData, AddressData);
		TDData.Description = NameOfDeliveryPointAccordingToAddress(AddressData);
		
	Else
		
		FillPropertyValues(TDData, AddressData,, "DeliveryZone");
		
		If (TDData.UpdatingMainPoint
				And Not TDData.IDIsOverridden)
			Or (Not TDData.SeveralMainAddresses
				And TDData.MatchedById) Then
			
			TDData.Description = NameOfDeliveryPointAccordingToAddress(AddressData);
			
		EndIf;
		
	EndIf;
	
	TDData.AddressID = AddressData.Id;
	TDData.MainPoint = Main;
	If Main Then
		
		TDData.NotUsed = False;
		
	EndIf;
	
EndProcedure

Function NameOfDeliveryPointAccordingToAddress(AddressData)
	
	If Not IsBlankString(AddressData.AddressValue)
		And ValueIsFilled(AddressData.Id) Then
		
		NameOfDeliveryPoint = GoodsDeliveryLocalization.NameOfDeliveryPointAt(
			AddressData.Address,
			AddressData.AddressValue,
			False);
		
	Else
		
		NameOfDeliveryPoint = AddressData.Address;
		
	EndIf;
	
	Return NameOfDeliveryPoint;
	
EndFunction

// Parameters:
//  DataForProcessing_ - See NewDeliveryPointData
//  AddressData - ValueTableRow of See NewAddressesData
//  DataOfOwnerSPoints - See NewDeliveryPointData
//
Procedure ChangeMainDeliveryPoint(DataForProcessing_, AddressData, DataOfOwnerSPoints)
	
	DataFromExistingTD = DeliveryPointDataAccordingToAddress(DataOfOwnerSPoints, AddressData);
	
	If DataFromExistingTD <> Undefined Then
		
		If DataFromExistingTD.IDIsOverridden
			Or Not IsBlankString(DataFromExistingTD.DeliveryPointID)
			Or Not DataFromExistingTD.MainPoint Then
			
			DataChanged1 = True;
			
		Else
			
			DataChanged1 = Not AddressesAreEqual(DataFromExistingTD, AddressData);
			
		EndIf;
		
		If DataChanged1 Then
			
			DataFromExistingTD.IDIsOverridden = False;
			DataFromExistingTD.DeliveryPointID = "";
			
			FillInDeliveryPointDataWithAddressData(DataFromExistingTD, AddressData, True);
			AddDataToChange(DataForProcessing_, DataFromExistingTD);
			
		EndIf;
		
	Else
		
		DataOfNewTD = DataForProcessing_.Add();
		FillInDeliveryPointDataWithAddressData(DataOfNewTD, AddressData, True);
		
	EndIf;
	
EndProcedure

Function AddressCorrespondsToMainDeliveryPoint(AddressData, DataOfMainTD)
	
	ThisIsAddressOfMainPoint = False;
	
	If ValueIsFilled(AddressData.Id) Then
		
		ThisIsAddressOfMainPoint = (AddressData.Id = DataOfMainTD.AddressID);
		
	Else
		
		ThisIsAddressOfMainPoint = (StrCompare(AddressData.Address, DataOfMainTD.Address) = 0);
		
	EndIf;
	
	Return ThisIsAddressOfMainPoint;
	
EndFunction

Function CommentOnDeliveryPointVersion(NewPoint, PointData_, SwitchingToDelivery25)
	
	Delivery20 = GoodsDeliveryClientServer.UsedDelivery20();
	
	TextTransition = NStr("ru = 'Точка доставки создана при переходе на версию Доставки 2.5';
							|vi = 'The delivery point is created when migrating to Delivery version 2.5';
							|en = 'The delivery point is created when migrating to Delivery version 2.5'; fa = 'The delivery point is created when migrating to Delivery version 2.5';
							|it = 'The delivery point is created when migrating to Delivery version 2.5';
							|pl = 'The delivery point is created when migrating to Delivery version 2.5';
							|tr = 'Teslimat 2.5 sürümüne geçişte teslimat noktası oluşturuldu'");
	TextMain = NStr("ru = 'Точка доставки записана по данным адреса владельца';
					|vi = 'The delivery point is saved based on the owner address';
					|en = 'The delivery point is saved based on the owner address'; fa = 'The delivery point is saved based on the owner address';
					|it = 'The delivery point is saved based on the owner address';
					|pl = 'The delivery point is saved based on the owner address';
					|tr = 'Teslimat noktası, sahibinin adres verilerine göre kaydedildi'");
	TextMain20 = NStr("ru = 'Точка доставки записана по данным адреса владельца (версия Доставки 2.0)';
						|vi = 'The delivery point is saved based on the owner address (Delivery version 2.0)';
						|en = 'The delivery point is saved based on the owner address (Delivery version 2.0)'; fa = 'The delivery point is saved based on the owner address (Delivery version 2.0)';
						|it = 'The delivery point is saved based on the owner address (Delivery version 2.0)';
						|pl = 'The delivery point is saved based on the owner address (Delivery version 2.0)';
						|tr = 'Teslimat noktası, sahibinin adres verilerine göre kaydedildi (Teslimat 2.0 sürümü)'");
	OldMainText = NStr("ru = 'Адрес владельца изменен, не соответствует текущему адресу точки доставки';
						|vi = 'The owner address is changed and does not correspond to the current address of the delivery point';
						|en = 'The owner address is changed and does not correspond to the current address of the delivery point'; fa = 'The owner address is changed and does not correspond to the current address of the delivery point';
						|it = 'The owner address is changed and does not correspond to the current address of the delivery point';
						|pl = 'The owner address is changed and does not correspond to the current address of the delivery point';
						|tr = 'Sahibinin adresi değiştirildi, mevcut teslimat noktası adresiyle eşleşmiyor'");
	OldMainText20 = NStr("ru = 'Адрес владельца изменен, не соответствует текущему адресу точки доставки (версия Доставки 2.0)';
						|vi = 'The owner address is changed and does not correspond to the current address of the delivery point (Delivery version 2.0)';
						|en = 'The owner address is changed and does not correspond to the current address of the delivery point (Delivery version 2.0)'; fa = 'The owner address is changed and does not correspond to the current address of the delivery point (Delivery version 2.0)';
						|it = 'The owner address is changed and does not correspond to the current address of the delivery point (Delivery version 2.0)';
						|pl = 'The owner address is changed and does not correspond to the current address of the delivery point (Delivery version 2.0)';
						|tr = 'Sahibinin adresi değiştirildi, mevcut teslimat noktası adresiyle eşleşmiyor (Teslimat 2.0 sürümü)'");
	
	VersionComment = "";
	
	If SwitchingToDelivery25 Then
		
		VersionComment = TextTransition;
		
	ElsIf Delivery20
		And Not PointData_.SeveralMainAddresses Then
		
		If NewPoint
			Or PointData_.MatchedById
			Or PointData_.SelectedAt Then
			
			VersionComment = TextMain20;
			
		ElsIf Not PointData_.MainPoint Then
			
			VersionComment = OldMainText20;
			
		EndIf;
		
	ElsIf Not PointData_.SeveralMainAddresses Then
		
		If PointData_.MainPoint Then
			
			VersionComment = TextMain;
			
		Else
			
			VersionComment = OldMainText;
			
		EndIf;
		
	EndIf;
	
	Return VersionComment;
	
EndFunction

#EndRegion

#Region Posting

Procedure CancelDeliveryDocument(Document, Val RegisterName)
	
	If CommonClientServer.HasAttributeOrObjectProperty(Document, "Patch")
	   And Document.Patch Then
		
		RequestPreviousCorrection = New Query;
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DocumentCorrectionsSliceLast.LastChainDocument <> UNDEFINED
		|			THEN DocumentCorrectionsSliceLast.LastChainDocument
		|		ELSE DocumentCorrectionsSliceLast.CorrectedDocument
		|	END AS PreviousCorrection
		|FROM
		|	InformationRegister.DocumentCorrections.SliceLast(, CorrectedDocument = &CorrectedDocument) AS DocumentCorrectionsSliceLast";
		RequestPreviousCorrection.Text = QueryText;
		RequestPreviousCorrection.SetParameter("CorrectedDocument", Document.CorrectedDocument);
		Selection = RequestPreviousCorrection.Execute().Select();
		If Selection.Next() Then
			PreviousCorrection = Selection.PreviousCorrection; // DocumentRef
		Else
			PreviousCorrection = Document.CorrectedDocument;
		EndIf;
		PreviousDocument = PreviousCorrection.GetObject();
		
	EndIf;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	Delivery.Recorder AS Recorder,
	|	Delivery.LineNumber AS LineNumber
	|FROM
	|	AccumulationRegister.Delivery AS Delivery
	|WHERE
	|	Delivery.ReversedPlan = &PlanningDocument
	|
	|UNION ALL
	|
	|SELECT
	|	Delivery.Recorder,
	|	Delivery.LineNumber
	|FROM
	|	AccumulationRegister.Delivery AS Delivery
	|WHERE
	|	Delivery.Recorder = &PlanningDocument";
	
	If CommonClientServer.HasAttributeOrObjectProperty(Document, "Patch")
	   And Document.Patch Then
		
		TextOfRegisteredRecordedSampleOfPreviousDocument =
		"SELECT
		|	Delivery.Recorder AS Recorder,
		|	Delivery.LineNumber AS LineNumber
		|FROM
		|	AccumulationRegister.Delivery AS Delivery
		|WHERE
		|	Delivery.Recorder = &PreviousCorrection
		|
		|UNION ALL
		|
		|SELECT
		|	Delivery.Recorder AS Recorder,
		|	Delivery.LineNumber AS LineNumber
		|FROM
		|	AccumulationRegister.Delivery AS Delivery
		|WHERE
		|	Delivery.ReversedPlan = &PreviousCorrection";
		
		Query.SetParameter("PreviousCorrection", PreviousCorrection);
		
		QueryText = QueryText
			+ TMCommonUse.QuerySeparatorInJoin()
			+ TextOfRegisteredRecordedSampleOfPreviousDocument;
		
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("PlanningDocument", Document.Ref);
	TableOfRecordsToDelete = Query.Execute().Unload();
	Recorders = TableOfRecordsToDelete.UnloadColumn("Recorder"); // Array of DocumentRef
	Recorders.Add(Document.Ref);
	HasTableData = False;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Document, "Patch")
	   And Document.Patch Then
		
		// Re-form the Registered Records of the previous document of the correction chain.
		
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
		AddlParameters.AdditionalProperties = DocumentsPosting.DocumentProperties(Document);
		AddlParameters.Insert("PreviousCorrection", Document.Ref);
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(PreviousCorrection, RegisterName, AddlParameters);
		TableName = "Table" + RegisterName;
		HasTableData = TablesForRegisteredRecords.Property(TableName);
		
		If HasTableData Then
			
			DataTable = TablesForRegisteredRecords[TableName]; // ValueTable
			
			If DataTable.Columns.Find("Recorder") = Undefined Then
				
				DataTable.Columns.Add("Recorder");
				DataTable.FillValues(PreviousCorrection, "Recorder");
				
			EndIf;
			
		EndIf;
		
		If HasTableData Then
			
			DataTable = TablesForRegisteredRecords[TableName]; // ValueTable
			RecordersOfActualRegisteredRecords = DataTable.UnloadColumn("Recorder"); // Array of DocumentRef
			CommonClientServer.SupplementArray(Recorders, RecordersOfActualRegisteredRecords, True);
			
		EndIf;
		
	EndIf;
	
	If TableOfRecordsToDelete.Count() > 0 Then
		
		RecordSetToBeDeleted = AccumulationRegisters[RegisterName].CreateRecordSet();
		TempTableManager = DocumentsPosting.ManagerOfTemporaryControlTables(Document);
		DocumentsPosting.SetAdditionalRegisterProperties(RecordSetToBeDeleted, Document, TempTableManager, True);
		RecordSetToBeDeleted.AdditionalProperties.Insert("Recorders", Recorders);
		RecordSetToBeDeleted.AdditionalProperties.Insert("FixChangesAfterRecording", Not HasTableData);
		RecordSetToBeDeleted.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
		RecordSetToBeDeleted.ExtendedReplaceMode = True;
		RecordSetToBeDeleted.Filter.Recorder.Set(, False);
		RecordSetToBeDeleted.Load(TableOfRecordsToDelete);
		RecordSetToBeDeleted.Write(ReplacementMode.Delete);
		
	EndIf;
	
	If HasTableData Then
		
		SetOfRecordsToBeAdded = AccumulationRegisters[RegisterName].CreateRecordSet();
		TempTableManager = DocumentsPosting.ManagerOfTemporaryControlTables(Document);
		DocumentsPosting.SetAdditionalRegisterProperties(SetOfRecordsToBeAdded, Document, TempTableManager, True);
		SetOfRecordsToBeAdded.AdditionalProperties.Insert("FixChangesAfterRecording", True);
		SetOfRecordsToBeAdded.AdditionalProperties.Insert("Recorders", Recorders);
		SetOfRecordsToBeAdded.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
		SetOfRecordsToBeAdded.ExtendedReplaceMode = True;
		SetOfRecordsToBeAdded.Filter.Recorder.Set(, False);
		SetOfRecordsToBeAdded.Load(DataTable);
		SetOfRecordsToBeAdded.Write(ReplacementMode.Append);
	
	EndIf;
	
EndProcedure

Function PreviousLevelsOfOperation(CurrentLevelOfOperation)
	
	Result = New Array; // Array of Number
	
	If CurrentLevelOfOperation = 20 Then
		
		Result.Add(10);
		
	EndIf;
	
	If CurrentLevelOfOperation = 30 Then
		
		Result.Add(20);
		Result.Add(15);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function NextLevelsOfOperation(CurrentLevelOfOperation, ThereAreLinesOfGoodsChangingOnlyPackagingUnits = False)
	
	Result = New Array; // Array of Number
	
	If CurrentLevelOfOperation = 10 Then
		
		Result.Add(20);
		
	EndIf;
	
	If CurrentLevelOfOperation = 15 Then
		
		Result.Add(30);
		
	EndIf;
	
	If CurrentLevelOfOperation = 20
	   And ThereAreLinesOfGoodsChangingOnlyPackagingUnits Then
		
		Result.Add(30);
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure SubstituteSynonymForDocumentTable(QueryText, SynonymForDocumentTable)
	
	QueryText = StrReplace(QueryText, "&DataTable", "#" + SynonymForDocumentTable);
	
EndProcedure

Procedure InsertAdditionalFieldsIntoTemplates(TemplateTexts, AdditionalFields)
	
	For IndexOf = 0 To TemplateTexts.UBound() Do
		
		TemplateTexts[IndexOf] = StrReplace(TemplateTexts[IndexOf], "&AdditionalFields", AdditionalFields);
		
	EndDo;
	
EndProcedure

Function RequestTemplateTTCurrentLevel()
	
	QueryTemplate =
	"SELECT
	|	FALSE AS AugmentedString,
	|	&Ref AS Recorder,
	|	CAST(DataTable.LineNumber AS NUMBER(15, 0)) AS LineNumber,
	|	DataTable.Period AS Period,
	|	DataTable.Organization AS Organization,
	|	DataTable.DeliveryType AS DeliveryType,
	|	DataTable.DateOfShipment AS DateOfShipment,
	|	DataTable.DeliveryMethod AS DeliveryMethod,
	|	DataTable.Sender AS Sender,
	|	DataTable.SenderPoint AS SenderPoint,
	|	DataTable.Sender_Area AS Sender_Area,
	|	DataTable.Recipient AS Recipient,
	|	DataTable.RecipientPoint AS RecipientPoint,
	|	DataTable.Recipient_Area AS Recipient_Area,
	|	DataTable.ReferenceOrder AS ReferenceOrder,
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.Series AS Series,
	|	DataTable.RowCode AS RowCode,
	|	CAST(DataTable.Arm AS NUMBER(2, 0)) AS Arm,
	|	DataTable.Carrier AS Carrier,
	|	DataTable.Package AS Package,
	|	&OperationLevel AS OperationLevel,
	|	&ExpressionPlanningDocument AS PlanningDocument,
	|	DataTable.ThisIsFinalArm AS ThisIsFinalArm,
	|	CAST(DataTable.MinimumArmNumber AS NUMBER(2, 0)) AS MinimumArmNumber,
	|	&ExpressionQuantity AS Count
	|INTO AssignmentTable
	|FROM
	|	&DataTable AS DataTable";
	
	Return QueryTemplate;
	
EndFunction

Function QueryTextTTCurrentLevelT2()
	
	QueryText = RequestTemplateTTCurrentLevel();
	
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTCurrentLevelT2");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionPlanningDocument",
		"CASE
		|		WHEN &OperationLevel = 20
		|			THEN UNDEFINED
		|		ELSE DataTable.PlanningDocument
		|	END");
		
	QueryText = StrReplace(
		QueryText,
		"&ExpressionQuantity",
		"CASE
		|		WHEN &OperationLevel = 10
		|				OR &OperationLevel = 15
		|			THEN DataTable.ToDeliver
		|		WHEN &OperationLevel = 20
		|			THEN DataTable.ToTrip
		|		WHEN &OperationLevel = 30
		|			THEN DataTable.InTrip
		|		ELSE 0
		|	END");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSelectionOfDeliveryOfPreviousLevel()
	
	QueryText =
	"SELECT DISTINCT
	|	DataTable.ReferenceOrder AS ReferenceOrder,
	|	DataTable.RowCode AS RowCode,
	|	CASE
	|		WHEN &OperationLevel = 20
	|			THEN UNDEFINED
	|		ELSE DataTable.PlanningDocument
	|	END AS PlanningDocument
	|INTO TTSelectionOfDeliveryOfPreviousLevel
	|FROM
	|	&DataTable AS DataTable";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPreviousLevelT1()
	
	QueryText =
	"SELECT
	|	FALSE AS AugmentedString,
	|	Delivery.Recorder AS Recorder,
	|	CAST(Delivery.LineNumber AS NUMBER(15, 0)) AS LineNumber,
	|	Delivery.Period AS Period,
	|	Delivery.Organization AS Organization,
	|	Delivery.DeliveryType AS DeliveryType,
	|	Delivery.DateOfShipment AS DateOfShipment,
	|	Delivery.DeliveryMethod AS DeliveryMethod,
	|	Delivery.Sender AS Sender,
	|	Delivery.SenderPoint AS SenderPoint,
	|	Delivery.Sender_Area AS Sender_Area,
	|	Delivery.Recipient AS Recipient,
	|	Delivery.RecipientPoint AS RecipientPoint,
	|	Delivery.Recipient_Area AS Recipient_Area,
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.RowCode AS RowCode,
	|	CAST(Delivery.Arm AS NUMBER(2, 0)) AS Arm,
	|	Delivery.Carrier AS Carrier,
	|	Delivery.Package AS Package,
	|	Delivery.OperationLevel AS OperationLevel,
	|	CASE
	|		WHEN &OperationLevel = 20
	|			THEN UNDEFINED
	|		ELSE Delivery.PlanningDocument
	|	END AS PlanningDocument,
	|	Delivery.ThisIsFinalArm AS ThisIsFinalArm,
	|	CAST(Delivery.MinimumArmNumber AS NUMBER(2, 0)) AS MinimumArmNumber,
	|	0 AS Count
	|INTO TTPreviousLevelT1
	|FROM
	|	(SELECT DISTINCT
	|		TTSelectionOfDeliveryOfPreviousLevel.ReferenceOrder AS ReferenceOrder
	|	FROM
	|		TTSelectionOfDeliveryOfPreviousLevel AS TTSelectionOfDeliveryOfPreviousLevel) AS FilterReferences
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON FilterReferences.ReferenceOrder = Delivery.ReferenceOrder
	|		INNER JOIN TTSelectionOfDeliveryOfPreviousLevel AS TTSelectionOfDeliveryOfPreviousLevel
	|		ON (TTSelectionOfDeliveryOfPreviousLevel.ReferenceOrder = Delivery.ReferenceOrder)
	|			AND (TTSelectionOfDeliveryOfPreviousLevel.RowCode = Delivery.RowCode)
	|			AND (CASE
	|				WHEN &OperationLevel = 30
	|					THEN TTSelectionOfDeliveryOfPreviousLevel.PlanningDocument = Delivery.PlanningDocument
	|				ELSE TRUE
	|			END)
	|			AND (Delivery.OperationLevel IN (&PreviousLevelsOfOperation))
	|WHERE
	|	&OperationLevel > 15
	|	AND Delivery.ReversedPlan <> &Ref
	|	AND Delivery.ReversedPlan <> &PreviousCorrection
	|	AND NOT 1 IN
	|		(SELECT TOP 1
	|			1
	|		FROM
	|			InformationRegister.DocumentCorrections AS DocumentCorrections
	|		WHERE
	|			DocumentCorrections.CorrectedDocument = Delivery.Recorder
	|			OR DocumentCorrections.PreviousCorrection = Delivery.Recorder)";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTShouldersOfPreviousLevelT1()
	
	QueryText =
	"SELECT DISTINCT
	|	TTPreviousLevelT1.ReferenceOrder AS ReferenceOrder,
	|	TTPreviousLevelT1.RowCode AS RowCode,
	|	TTPreviousLevelT1.PlanningDocument AS PlanningDocument,
	|	TTPreviousLevelT1.Arm AS Arm
	|INTO TTShouldersOfPreviousLevelT1
	|FROM
	|	TTPreviousLevelT1 AS TTPreviousLevelT1
	|WHERE
	|	&OperationLevel > 15";
	
	Return QueryText;
	
EndFunction

Function RequestTemplateTTKeyFields()
	
	QueryTemplate =
	"SELECT DISTINCT
	|	T2.DeliveryType AS DeliveryType,
	|	T2.Recorder AS Recorder,
	|	T2.Period AS Period,
	|	T2.ReferenceOrder AS ReferenceOrder,
	|	T2.RowCode AS RowCode,
	|	T2.Products AS Products,
	|	T2.Characteristic AS Characteristic,
	|	T2.Series AS Series,
	|	T2.Organization AS Organization,
	|	T2.PlanningDocument AS PlanningDocument,
	|	T2.Count AS Count,
	|	T2.OperationLevel AS OperationLevel
	|INTO AssignmentTable
	|FROM
	|	&SourceTable1 AS T2
	|WHERE
	|	&ExpressionSelection";
	
	Return QueryTemplate;
	
EndFunction

Function QueryTextTTKeyFieldsOfCurrentT2Level()
	
	QueryText = RequestTemplateTTKeyFields();
	
	QueryText = StrReplace(QueryText, "&SourceTable1", "TTCurrentLevelT2");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTKeyFieldsOfCurrentT2Level");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function RequestTemplateMissingShouldersT2()
	
	QueryTemplate =
	"SELECT
	|	KeyFieldsT2.Period AS Period,
	|	KeyFieldsT2.DeliveryType AS DeliveryType,
	|	KeyFieldsT2.ReferenceOrder AS ReferenceOrder,
	|	KeyFieldsT2.RowCode AS RowCode,
	|	KeyFieldsT2.Products AS Products,
	|	KeyFieldsT2.Characteristic AS Characteristic,
	|	KeyFieldsT2.Series AS Series,
	|	KeyFieldsT2.Organization AS Organization,
	|	KeyFieldsT2.PlanningDocument AS PlanningDocument,
	|	KeyFieldsT2.Recorder AS Recorder,
	|	KeyFieldsT2.Count AS Count,
	|	KeyFieldsT2.OperationLevel AS OperationLevel,
	|	ShouldersT1.Arm AS Arm
	|INTO AssignmentTable
	|FROM
	|	&TableSourceT2 AS KeyFieldsT2
	|		INNER JOIN &TableSourceT1 AS ShouldersT1
	|		ON KeyFieldsT2.ReferenceOrder = ShouldersT1.ReferenceOrder
	|			AND KeyFieldsT2.RowCode = ShouldersT1.RowCode
	|			AND KeyFieldsT2.PlanningDocument = ShouldersT1.PlanningDocument
	|WHERE
	|	&ExpressionSelection";
	
	Return QueryTemplate;
	
EndFunction

Function QueryTextTTMissingShouldersOfCurrentT2Level()
	
	QueryText = RequestTemplateMissingShouldersT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTShouldersOfPreviousLevelT1");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTKeyFieldsOfCurrentT2Level");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTMissingShouldersOfCurrentT2Level");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function RequestTemplateShoulderExtensionT2()
	
	QueryTemplate =
	"SELECT
	|	TRUE AS AugmentedString,
	|	MissingShouldersT2.Recorder AS Recorder,
	|	0 AS LineNumber,
	|	MissingShouldersT2.Period AS Period,
	|	MissingShouldersT2.Organization AS Organization,
	|	MissingShouldersT2.DeliveryType AS DeliveryType,
	|	DATETIME(1, 1, 1) AS DateOfShipment,
	|	VALUE(Enum.TransportMethods25.EmptyRef) AS DeliveryMethod,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Sender,
	|	VALUE(Catalog.DeliveryPoints.EmptyRef) AS SenderPoint,
	|	VALUE(Catalog.DeliveryZones.EmptyRef) AS Sender_Area,
	|	VALUE(Catalog.Partners.EmptyRef) AS Recipient,
	|	VALUE(Catalog.DeliveryPoints.EmptyRef) AS RecipientPoint,
	|	VALUE(Catalog.DeliveryZones.EmptyRef) AS Recipient_Area,
	|	MissingShouldersT2.ReferenceOrder AS ReferenceOrder,
	|	MissingShouldersT2.Products AS Products,
	|	MissingShouldersT2.Characteristic AS Characteristic,
	|	MissingShouldersT2.Series AS Series,
	|	MissingShouldersT2.RowCode AS RowCode,
	|	MissingShouldersT2.Arm AS Arm,
	|	VALUE(Catalog.Partners.EmptyRef) AS Carrier,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	MissingShouldersT2.OperationLevel AS OperationLevel,
	|	MissingShouldersT2.PlanningDocument AS PlanningDocument,
	|	FALSE AS ThisIsFinalArm,
	|	0 AS MinimumArmNumber,
	|	MissingShouldersT2.Count AS Count
	|ADD AssignmentTable
	|FROM
	|	&TableMissingShouldersT2 AS MissingShouldersT2
	|		LEFT JOIN &TableSourceT2 AS T2
	|		ON MissingShouldersT2.ReferenceOrder = T2.ReferenceOrder
	|			AND MissingShouldersT2.RowCode = T2.RowCode
	|			AND MissingShouldersT2.PlanningDocument = T2.PlanningDocument
	|			AND MissingShouldersT2.Recorder = T2.Recorder
	|			AND MissingShouldersT2.Arm = T2.Arm
	|WHERE
	|	T2.Arm IS NULL
	|	AND &ExpressionSelection";
	
	Return QueryTemplate;
	
EndFunction

Function QueryTextTTCurrentLevelT2_ShoulderPadding()
	
	QueryText = RequestTemplateShoulderExtensionT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTCurrentLevelT2");
	QueryText = StrReplace(QueryText, "&TableMissingShouldersT2", "TTMissingShouldersOfCurrentT2Level");
	QueryText = StrReplace(QueryText, "ADD AssignmentTable", "ADD TTCurrentLevelT2"); // @Query-part-1, @Query-part-2
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTShouldersOfCurrentT2Level()
	
	QueryText =
	"SELECT DISTINCT
	|	TTCurrentLevelT2.ReferenceOrder AS ReferenceOrder,
	|	TTCurrentLevelT2.RowCode AS RowCode,
	|	TTCurrentLevelT2.PlanningDocument AS PlanningDocument,
	|	TTCurrentLevelT2.Arm AS Arm
	|INTO TTShouldersOfCurrentT2Level
	|FROM
	|	TTCurrentLevelT2 AS TTCurrentLevelT2
	|WHERE
	|	&OperationLevel > 15";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTKeyFieldsOfPreviousLevelT1()
	
	QueryText = RequestTemplateTTKeyFields();
	
	QueryText = StrReplace(QueryText, "&SourceTable1", "TTPreviousLevelT1");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTKeyFieldsOfPreviousLevelT1");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTMissingShouldersOfPreviousLevelT1()
	
	QueryText = RequestTemplateMissingShouldersT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTShouldersOfCurrentT2Level");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTKeyFieldsOfPreviousLevelT1");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTMissingShouldersOfPreviousT1Level");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPreviousLevelT1_ShoulderPadding()
	
	QueryText = RequestTemplateShoulderExtensionT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTPreviousLevelT1");
	QueryText = StrReplace(QueryText, "&TableMissingShouldersT2", "TTMissingShouldersOfPreviousT1Level");
	QueryText = StrReplace(QueryText, "ADD AssignmentTable", "ADD TTPreviousLevelT1"); // @Query-part-1, @Query-part-2 
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function RequestTemplateFieldChangeControl()
	
	QueryTemplate =
	"SELECT
	|	FieldControl.ReferenceOrder AS ReferenceOrder,
	|	FieldControl.RowCode AS RowCode,
	|	FieldControl.PlanningDocument AS PlanningDocument,
	|	FieldControl.T1Recorders AS T1Recorders,
	|	FieldControl.T2Recorders AS T2Recorders,
	|	MAX(FieldControl.FinalRecipientHasChanged) AS FinalRecipientHasChanged,
	|	MAX(FieldControl.InitialSenderHasChanged) AS InitialSenderHasChanged
	|INTO AssignmentTable
	|FROM
	|	(SELECT
	|		T1.ReferenceOrder AS ReferenceOrder,
	|		T1.RowCode AS RowCode,
	|		T1.PlanningDocument AS PlanningDocument,
	|		T1.Recorder AS T1Recorders,
	|		T2.Recorder AS T2Recorders,
	|		(T1.Recipient <> T2.Recipient) AS FinalRecipientHasChanged,
	|		FALSE AS InitialSenderHasChanged
	|	FROM
	|		&TableSourceT1 AS T1
	|			INNER JOIN &TableSourceT2 AS T2
	|			ON T1.ReferenceOrder = T2.ReferenceOrder
	|				AND T1.RowCode = T2.RowCode
	|				AND T1.PlanningDocument = T2.PlanningDocument
	|				AND T1.ThisIsFinalArm
	|				AND T2.ThisIsFinalArm
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T2.ReferenceOrder AS ReferenceOrder,
	|		T2.RowCode AS RowCode,
	|		T2.PlanningDocument AS PlanningDocument,
	|		T1.Recorder AS T1Recorders,
	|		T2.Recorder AS T2Recorders,
	|		FALSE AS FinalRecipientHasChanged,
	|		(T1.Sender <> T2.Sender) AS InitialSenderHasChanged
	|	FROM
	|		&TableSourceT2 AS T2
	|			INNER JOIN &TableSourceT1 AS T1
	|			ON T2.ReferenceOrder = T1.ReferenceOrder
	|				AND T2.RowCode = T1.RowCode
	|				AND T2.PlanningDocument = T1.PlanningDocument
	|				AND T2.MinimumArmNumber > 0
	|				AND T2.MinimumArmNumber = T1.Arm) AS FieldControl
	|
	|GROUP BY
	|	FieldControl.ReferenceOrder,
	|	FieldControl.RowCode,
	|	FieldControl.PlanningDocument,
	|	FieldControl.T1Recorders,
	|	FieldControl.T2Recorders";
	
	Return QueryTemplate;
	
EndFunction

Function QueryTextTTControlOfChangeOfFieldsOfCurrentLevel()
	
	QueryText = RequestTemplateFieldChangeControl();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTPreviousLevelT1");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTCurrentLevelT2");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTControlOfChangesInFieldsOfCurrentLevel");
	
	Return QueryText;
	
EndFunction

Function LevelComparisonRequestTemplate()
	
	QueryTemplate =
	"SELECT
	|	CASE
	|		WHEN T1.DeliveryType = VALUE(Enum.DeliveryTypes.EmptyRef)
	|			THEN T2.DeliveryType
	|		ELSE T1.DeliveryType
	|	END AS DeliveryType,
	|	CASE
	|		WHEN T1.ReferenceOrder = UNDEFINED
	|			THEN T2.ReferenceOrder
	|		ELSE T1.ReferenceOrder
	|	END AS ReferenceOrder,
	|	CASE
	|		WHEN T1.RowCode = 0
	|			THEN T2.RowCode
	|		ELSE T1.RowCode
	|	END AS RowCode,
	|	CASE
	|		WHEN T1.Arm = 0
	|			THEN T2.Arm
	|		ELSE T1.Arm
	|	END AS Arm,
	|	
	|	T2.ReferenceOrder AS OrderT2,
	|	T2.PlanningDocument AS PlanningDocumentT2,
	|	T2.Organization AS T2Company,
	|	T2.Recorder AS T2Recorders,
	|	T2.LineNumber AS LineNumberT2,
	|	T2.Period AS PeriodT2,
	|	T2.Count AS NumberOfT2,
	|	T2.OperationLevel AS LevelOfOperationT2,
	|	T2.DateOfShipment AS ShipmentDateT2,
	|	T2.DeliveryMethod AS DeliveryMethodT2,
	|	T2.Sender AS SenderT2,
	|	T2.SenderPoint AS SenderSPointT2,
	|	T2.Sender_Area AS SenderSAreaT2,
	|	T2.Recipient AS RecipientT2,
	|	T2.RecipientPoint AS RecipientSPointT2,
	|	T2.Recipient_Area AS RecipientSAreaT2,
	|	T2.Products AS ItemT2,
	|	T2.Characteristic AS CharacteristicOfT2,
	|	T2.Series AS T2Batch,
	|	T2.Carrier AS CarrierT2,
	|	T2.AugmentedString AS AugmentedStringT2,
	|	T2.ThisIsFinalArm AS ThisIsFinalArmOfT2,
	|	T2.MinimumArmNumber AS MinimumShoulderNumberT2,
	|	T2.Package AS T2PackagingUnit,
	|	
	|	T1.ReferenceOrder AS OrderT1,
	|	T1.PlanningDocument AS PlanningDocumentT1,
	|	T1.Organization AS T1Company,
	|	T1.Recorder AS T1Recorders,
	|	T1.LineNumber AS LineNumberT1,
	|	T1.Period AS PeriodT1,
	|	T1.Count AS NumberOfT1,
	|	T1.OperationLevel AS LevelOfOperationT1,
	|	T1.DateOfShipment AS ShipmentDateT1,
	|	T1.DeliveryMethod AS T1DeliveryMethod,
	|	T1.Sender AS SenderT1,
	|	T1.SenderPoint AS SenderSPointT1,
	|	T1.Sender_Area AS SenderSAreaT1,
	|	T1.Recipient AS RecipientT1,
	|	T1.RecipientPoint AS RecipientPointT1,
	|	T1.Recipient_Area AS RecipientST1Area,
	|	T1.Products AS T1Item,
	|	T1.Characteristic AS CharacteristicT1,
	|	T1.Series AS T1Batch,
	|	T1.Carrier AS T1Carrier,
	|	T1.AugmentedString AS ExtendedLineT1,
	|	T1.ThisIsFinalArm AS ThisIsFinalArmOfT1,
	|	T1.MinimumArmNumber AS MinimumShoulderNumberT1,
	|	T1.Package AS T1PackagingUnit,
	|	
	|	CASE
	|		WHEN ISNULL(ControlOfFieldChanges.InitialSenderHasChanged, FALSE)
	|				OR ISNULL(ControlOfFieldChanges.FinalRecipientHasChanged, FALSE)
	|			THEN 0
	|		WHEN (T1.Organization <> T2.Organization
	|				OR T1.Products <> T2.Products
	|				OR T1.Characteristic <> T2.Characteristic
	|				OR T1.Series <> T2.Series)
	|			THEN 0
	|		WHEN T1.DateOfShipment = T2.DateOfShipment
	|				AND T1.DeliveryMethod = T2.DeliveryMethod
	|				AND T1.Sender = T2.Sender
	|				AND T1.SenderPoint = T2.SenderPoint
	|				AND T1.Sender_Area = T2.Sender_Area
	|				AND T1.Recipient = T2.Recipient
	|				AND T1.RecipientPoint = T2.RecipientPoint
	|				AND T1.Recipient_Area = T2.Recipient_Area
	|				AND T1.Carrier = T2.Carrier
	|				AND T1.Package = T2.Package
	|			THEN 0
	|		ELSE T2.Count
	|	END AS Difference
	|INTO AssignmentTable
	|FROM
	|	&TableSourceT2 AS T2
	|		INNER JOIN &TableSourceT1 AS T1
	|		ON T2.ReferenceOrder = T1.ReferenceOrder
	|			AND T2.RowCode = T1.RowCode
	|			AND T2.PlanningDocument = T1.PlanningDocument
	|			AND T2.Arm = T1.Arm
	|		LEFT JOIN &FieldChangeControlTable AS ControlOfFieldChanges
	|		ON T2.ReferenceOrder = ControlOfFieldChanges.ReferenceOrder
	|			AND T2.RowCode = ControlOfFieldChanges.RowCode
	|			AND T2.PlanningDocument = ControlOfFieldChanges.PlanningDocument
	|			AND T2.Recorder = ControlOfFieldChanges.T2Recorders
	|			AND T1.Recorder = ControlOfFieldChanges.T1Recorders
	|WHERE
	|	&ExpressionSelection";
	
	Return QueryTemplate;
	
EndFunction

Function QueryTextTTComparisonOfCurrentLevelWithPreviousOne()
	
	QueryText = LevelComparisonRequestTemplate();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTPreviousLevelT1");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTCurrentLevelT2");
	QueryText = StrReplace(QueryText, "&FieldChangeControlTable", "TTControlOfChangesInFieldsOfCurrentLevel");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTComparisonOfCurrentLevelWithPreviousOne");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel > 15");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCurrentT1Level()
	
	QueryText = RequestTemplateTTCurrentLevel();
	
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTCurrentLevelT1");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionPlanningDocument",
		"CASE
		|		WHEN &OperationLevel = 10
		|			THEN UNDEFINED
		|		ELSE DataTable.PlanningDocument
		|	END");
		
	QueryText = StrReplace(
		QueryText,
		"&ExpressionQuantity",
		"CASE
		|		WHEN &OperationLevel = 10
		|				OR &OperationLevel = 15
		|			THEN DataTable.ToDeliver
		|		WHEN &OperationLevel = 20
		|			THEN DataTable.ToTrip
		|		WHEN &OperationLevel = 30
		|			THEN DataTable.InTrip
		|		ELSE 0
		|	END");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsLinesChangeOnlyPackaging()
	
	QueryText =
	"SELECT
	|	GoodsLinesChangeOnlyPackaging.ReferenceOrder AS ReferenceOrder,
	|	GoodsLinesChangeOnlyPackaging.DeliveryLineCode AS DeliveryLineCode
	|INTO TTGoodsRowChangeOnlyPackagingUnits
	|FROM
	|	&GoodsLinesChangeOnlyPackaging AS GoodsLinesChangeOnlyPackaging";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTNextLevelDeliverySelection(ThereAreLinesOfGoodsChangingOnlyPackagingUnits = False)
	
	If ThereAreLinesOfGoodsChangingOnlyPackagingUnits Then
		
		QueryText =
		"SELECT DISTINCT
		|	DataTable.ReferenceOrder AS ReferenceOrder,
		|	DataTable.RowCode AS RowCode,
		|	CASE
		|		WHEN &OperationLevel = 15
		|				OR &OperationLevel = 20
		|			THEN DataTable.PlanningDocument
		|		ELSE UNDEFINED
		|	END AS PlanningDocument
		|INTO NextLevelDeliveryTTSelection
		|FROM
		|	&DataTable AS DataTable
		|		INNER JOIN TTGoodsRowChangeOnlyPackagingUnits AS GoodsLinesChangeOnlyPackaging
		|		ON DataTable.ReferenceOrder = GoodsLinesChangeOnlyPackaging.ReferenceOrder
		|			AND DataTable.RowCode = GoodsLinesChangeOnlyPackaging.DeliveryLineCode";
		
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	DataTable.ReferenceOrder AS ReferenceOrder,
		|	DataTable.RowCode AS RowCode,
		|	CASE
		|		WHEN &OperationLevel = 15
		|				OR &OperationLevel = 20
		|			THEN DataTable.PlanningDocument
		|		ELSE UNDEFINED
		|	END AS PlanningDocument
		|INTO NextLevelDeliveryTTSelection
		|FROM
		|	&DataTable AS DataTable";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTIsNextLevelT2()
	
	QueryText =
	"SELECT
	|	FALSE AS AugmentedString,
	|	Delivery.Recorder AS Recorder,
	|	CAST(Delivery.LineNumber AS NUMBER(15, 0)) AS LineNumber,
	|	Delivery.Period AS Period,
	|	Delivery.Organization AS Organization,
	|	Delivery.DeliveryType AS DeliveryType,
	|	Delivery.DateOfShipment AS DateOfShipment,
	|	Delivery.DeliveryMethod AS DeliveryMethod,
	|	Delivery.Sender AS Sender,
	|	Delivery.SenderPoint AS SenderPoint,
	|	Delivery.Sender_Area AS Sender_Area,
	|	Delivery.Recipient AS Recipient,
	|	Delivery.RecipientPoint AS RecipientPoint,
	|	Delivery.Recipient_Area AS Recipient_Area,
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.RowCode AS RowCode,
	|	CAST(Delivery.Arm AS NUMBER(2,0)) AS Arm,
	|	Delivery.Carrier AS Carrier,
	|	Delivery.Package AS Package,
	|	Delivery.OperationLevel AS OperationLevel,
	|	CASE
	|		WHEN &OperationLevel = 15
	|				OR &OperationLevel = 20
	|			THEN Delivery.PlanningDocument
	|		ELSE UNDEFINED
	|	END AS PlanningDocument,
	|	Delivery.ThisIsFinalArm AS ThisIsFinalArm,
	|	CAST(Delivery.MinimumArmNumber AS NUMBER(2,0)) AS MinimumArmNumber,
	|	CASE
	|		WHEN Delivery.OperationLevel = 15
	|				OR Delivery.OperationLevel = 20
	|			THEN Delivery.ToTrip
	|		WHEN Delivery.OperationLevel = 30
	|			THEN Delivery.InTrip
	|		ELSE 0
	|	END AS Count
	|INTO TTIsNextLevelOfT2
	|FROM
	|	(SELECT DISTINCT
	|		NextLevelDeliveryTTSelection.ReferenceOrder AS ReferenceOrder
	|	FROM
	|		NextLevelDeliveryTTSelection AS NextLevelDeliveryTTSelection) AS FilterReferences
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON FilterReferences.ReferenceOrder = Delivery.ReferenceOrder
	|		INNER JOIN NextLevelDeliveryTTSelection AS NextLevelDeliveryTTSelection
	|		ON NextLevelDeliveryTTSelection.ReferenceOrder = Delivery.ReferenceOrder
	|			AND NextLevelDeliveryTTSelection.RowCode = Delivery.RowCode
	|			AND CASE
	|				WHEN &OperationLevel = 15
	|						OR &OperationLevel = 20
	|					THEN NextLevelDeliveryTTSelection.PlanningDocument = Delivery.PlanningDocument
	|				ELSE TRUE
	|			END
	|			AND Delivery.OperationLevel IN (&NextLevelsOfOperation)
	|WHERE
	|	&OperationLevel < 30
	|	AND (NOT &IsNew OR &Patch)
	|	AND Delivery.ReversedPlan <> &Ref
	|	AND Delivery.ReversedPlan <> &PreviousCorrection";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTShouldersOfCurrentT1Level()
	
	QueryText =
	"SELECT DISTINCT
	|	T1.ReferenceOrder AS ReferenceOrder,
	|	T1.RowCode AS RowCode,
	|	T1.PlanningDocument AS PlanningDocument,
	|	T1.Arm AS Arm
	|INTO TTShouldersOfCurrentT1Level
	|FROM
	|	TTCurrentLevelT1 AS T1
	|WHERE
	|	&OperationLevel < 30
	|	AND (NOT &IsNew OR &Patch)";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTKeyFieldsOfNextLevelT2()
	
	QueryText = RequestTemplateTTKeyFields();
	
	QueryText = StrReplace(QueryText, "&SourceTable1", "TTIsNextLevelOfT2");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTKeyFieldsOfNextLevelT2");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTMissingShouldersOfNextLevelT2()
	
	QueryText = RequestTemplateMissingShouldersT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTShouldersOfCurrentT1Level");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTKeyFieldsOfNextLevelT2");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTMissingShouldersOfNextLevelT2");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTNextLevelT2_ShoulderPadding()
	
	QueryText = RequestTemplateShoulderExtensionT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTIsNextLevelOfT2");
	QueryText = StrReplace(QueryText, "&TableMissingShouldersT2", "TTMissingShouldersOfNextLevelT2");
	QueryText = StrReplace(QueryText, "ADD AssignmentTable", "ADD TTIsNextLevelOfT2"); // @Query-part-1, @Query-part-2
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTControlOfChangeOfFieldsOfNextLevel()
	
	QueryText = RequestTemplateFieldChangeControl();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTCurrentLevelT1");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTIsNextLevelOfT2");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTControlOfChangeOfFieldsOfNextLevel");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTComparisonOfCurrentLevelWithNext()
	
	QueryText = LevelComparisonRequestTemplate();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTCurrentLevelT1");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTIsNextLevelOfT2");
	QueryText = StrReplace(QueryText, "&FieldChangeControlTable", "TTControlOfChangeOfFieldsOfNextLevel");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTComparisonOfCurrentLevelWithNext");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTShouldersOfNextLevelT2()
	
	QueryText =
	"SELECT DISTINCT
	|	T2.ReferenceOrder AS ReferenceOrder,
	|	T2.RowCode AS RowCode,
	|	T2.PlanningDocument AS PlanningDocument,
	|	T2.Arm AS Arm
	|INTO TTShouldersOfNextLevelT2
	|FROM
	|	TTIsNextLevelOfT2 AS T2
	|WHERE
	|	&OperationLevel < 30
	|	AND (NOT &IsNew OR &Patch)";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTKeyFieldsOfCurrentT1Level()
	
	QueryText = RequestTemplateTTKeyFields();
	
	QueryText = StrReplace(QueryText, "&SourceTable1", "TTCurrentLevelT1");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTKeyFieldsOfCurrentT1Level");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTMissingShouldersOfCurrentT1Level()
	
	QueryText = RequestTemplateMissingShouldersT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT1", "TTShouldersOfNextLevelT2");
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTKeyFieldsOfCurrentT1Level");
	QueryText = StrReplace(QueryText, "INTO AssignmentTable", "INTO TTMissingShouldersOfCurrentT1Level");
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCurrentLevelT1_ShoulderPadding()
	
	QueryText = RequestTemplateShoulderExtensionT2();
	
	QueryText = StrReplace(QueryText, "&TableSourceT2", "TTCurrentLevelT1");
	QueryText = StrReplace(QueryText, "&TableMissingShouldersT2", "TTMissingShouldersOfCurrentT1Level");
	QueryText = StrReplace(QueryText, "ADD AssignmentTable", "ADD TTCurrentLevelT1"); // @Query-part-1, @Query-part-2
	
	QueryText = StrReplace(
		QueryText,
		"&ExpressionSelection",
		"&OperationLevel < 30
		|	AND (NOT &IsNew OR &Patch)");
	
	Return QueryText;
	
EndFunction

Function RequestTemplateStornoT1ForPlanningDocument()
	
	Template =
	"SELECT
	|	SourceTable1.T2Recorders AS Recorder,
	|	SourceTable1.T1Recorders AS ReversedPlan,
	|	1 AS LineNumber,
	|	SourceTable1.PeriodT2 AS Period,
	|	SourceTable1.T1Company AS Organization,
	|	SourceTable1.DeliveryType AS DeliveryType,
	|	SourceTable1.ShipmentDateT1 AS DateOfShipment,
	|	SourceTable1.T1DeliveryMethod AS DeliveryMethod,
	|	SourceTable1.T1Carrier AS Carrier,
	|	SourceTable1.SenderT1 AS Sender,
	|	SourceTable1.SenderSPointT1 AS SenderPoint,
	|	SourceTable1.SenderSAreaT1 AS Sender_Area,
	|	SourceTable1.RecipientT1 AS Recipient,
	|	SourceTable1.RecipientPointT1 AS RecipientPoint,
	|	SourceTable1.RecipientST1Area AS Recipient_Area,
	|	SourceTable1.ReferenceOrder AS ReferenceOrder,
	|	VALUE(Document.Trip.EmptyRef) AS Trip,
	|	SourceTable1.T1Item AS Products,
	|	SourceTable1.CharacteristicT1 AS Characteristic,
	|	SourceTable1.T1Batch AS Series,
	|	SourceTable1.RowCode AS RowCode,
	|	SourceTable1.PlanningDocumentT1 AS PlanningDocument,
	|	SourceTable1.Arm AS Arm,
	|	SourceTable1.T1PackagingUnit AS Package,
	|	&AdditionalFields,
	|	CASE
	|		WHEN SourceTable1.LevelOfOperationT1 = 10
	|				OR SourceTable1.LevelOfOperationT1 = 15
	|			THEN -1 * SourceTable1.Difference
	|		ELSE 0
	|	END AS ToDeliver,
	|	CASE
	|		WHEN SourceTable1.LevelOfOperationT1 = 15
	|				OR SourceTable1.LevelOfOperationT1 = 20
	|			THEN -1 * SourceTable1.Difference
	|		ELSE 0
	|	END AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	SourceTable1.LevelOfOperationT2 AS OperationLevel
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	SourceTable1.Difference <> 0
	|	AND NOT SourceTable1.ExtendedLineT1";
	
	Return Template;
	
EndFunction

Function RequestTemplateStornoT1WithoutPlanningDocument()
	
	Template =
	"SELECT
	|	SourceTable1.T2Recorders AS Recorder,
	|	SourceTable1.T1Recorders AS ReversedPlan,
	|	1 AS LineNumber,
	|	SourceTable1.PeriodT2 AS Period,
	|	SourceTable1.T1Company AS Organization,
	|	SourceTable1.DeliveryType AS DeliveryType,
	|	SourceTable1.ShipmentDateT1 AS DateOfShipment,
	|	SourceTable1.T1DeliveryMethod AS DeliveryMethod,
	|	SourceTable1.T1Carrier AS Carrier,
	|	SourceTable1.SenderT1 AS Sender,
	|	SourceTable1.SenderSPointT1 AS SenderPoint,
	|	SourceTable1.SenderSAreaT1 AS Sender_Area,
	|	SourceTable1.RecipientT1 AS Recipient,
	|	SourceTable1.RecipientPointT1 AS RecipientPoint,
	|	SourceTable1.RecipientST1Area AS Recipient_Area,
	|	SourceTable1.ReferenceOrder AS ReferenceOrder,
	|	VALUE(Document.Trip.EmptyRef) AS Trip,
	|	SourceTable1.T1Item AS Products,
	|	SourceTable1.CharacteristicT1 AS Characteristic,
	|	SourceTable1.T1Batch AS Series,
	|	SourceTable1.RowCode AS RowCode,
	|	UNDEFINED AS PlanningDocument,
	|	SourceTable1.Arm AS Arm,
	|	SourceTable1.T1PackagingUnit AS Package,
	|	&AdditionalFields,
	|	-1 * SourceTable1.Difference AS ToDeliver,
	|	0 AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	SourceTable1.LevelOfOperationT2 AS OperationLevel
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	SourceTable1.Difference <> 0
	|	AND NOT SourceTable1.ExtendedLineT1
	|	AND SourceTable1.LevelOfOperationT1 = 20";
	
	Return Template;
	
EndFunction

Function RequestTemplateForNewT2ParametersAccordingToPlanningDocument()
	
	Template =
	"SELECT
	|	SourceTable1.T2Recorders AS Recorder,
	|	SourceTable1.T1Recorders AS ReversedPlan,
	|	1 AS LineNumber,
	|	SourceTable1.PeriodT2 AS Period,
	|	SourceTable1.T2Company AS Organization,
	|	SourceTable1.DeliveryType AS DeliveryType,
	|	SourceTable1.ShipmentDateT2 AS DateOfShipment,
	|	SourceTable1.DeliveryMethodT2 AS DeliveryMethod,
	|	SourceTable1.CarrierT2 AS Carrier,
	|	SourceTable1.SenderT2 AS Sender,
	|	SourceTable1.SenderSPointT2 AS SenderPoint,
	|	SourceTable1.SenderSAreaT2 AS Sender_Area,
	|	SourceTable1.RecipientT2 AS Recipient,
	|	SourceTable1.RecipientSPointT2 AS RecipientPoint,
	|	SourceTable1.RecipientSAreaT2 AS Recipient_Area,
	|	SourceTable1.ReferenceOrder AS ReferenceOrder,
	|	VALUE(Document.Trip.EmptyRef) AS Trip,
	|	SourceTable1.ItemT2 AS Products,
	|	SourceTable1.CharacteristicOfT2 AS Characteristic,
	|	SourceTable1.T2Batch AS Series,
	|	SourceTable1.RowCode AS RowCode,
	|	SourceTable1.PlanningDocumentT2 AS PlanningDocument,
	|	SourceTable1.Arm AS Arm,
	|	SourceTable1.T2PackagingUnit AS Package,
	|	&AdditionalFields,
	|	CASE
	|		WHEN SourceTable1.LevelOfOperationT1 = 10
	|				OR SourceTable1.LevelOfOperationT1 = 15
	|				OR SourceTable1.LevelOfOperationT1 = 20
	|					AND SourceTable1.PlanningDocumentT1 = UNDEFINED
	|			THEN SourceTable1.Difference
	|		ELSE 0
	|	END AS ToDeliver,
	|	CASE
	|		WHEN SourceTable1.LevelOfOperationT1 = 15
	|				OR SourceTable1.LevelOfOperationT1 = 20
	|					AND SourceTable1.PlanningDocumentT1 <> UNDEFINED
	|			THEN SourceTable1.Difference
	|		ELSE 0
	|	END AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	SourceTable1.LevelOfOperationT2 AS OperationLevel
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	SourceTable1.Difference <> 0
	|	AND NOT SourceTable1.AugmentedStringT2";
	
	Return Template;
	
EndFunction

Function RequestTemplateForNewT2ParametersWithoutPlanningDocument()
	
	Template =
	"SELECT
	|	SourceTable1.T2Recorders AS Recorder,
	|	SourceTable1.T1Recorders AS ReversedPlan,
	|	1 AS LineNumber,
	|	SourceTable1.PeriodT2 AS Period,
	|	SourceTable1.T2Company AS Organization,
	|	SourceTable1.DeliveryType AS DeliveryType,
	|	SourceTable1.ShipmentDateT2 AS DateOfShipment,
	|	SourceTable1.DeliveryMethodT2 AS DeliveryMethod,
	|	SourceTable1.CarrierT2 AS Carrier,
	|	SourceTable1.SenderT2 AS Sender,
	|	SourceTable1.SenderSPointT2 AS SenderPoint,
	|	SourceTable1.SenderSAreaT2 AS Sender_Area,
	|	SourceTable1.RecipientT2 AS Recipient,
	|	SourceTable1.RecipientSPointT2 AS RecipientPoint,
	|	SourceTable1.RecipientSAreaT2 AS Recipient_Area,
	|	SourceTable1.ReferenceOrder AS ReferenceOrder,
	|	VALUE(Document.Trip.EmptyRef) AS Trip,
	|	SourceTable1.ItemT2 AS Products,
	|	SourceTable1.CharacteristicOfT2 AS Characteristic,
	|	SourceTable1.T2Batch AS Series,
	|	SourceTable1.RowCode AS RowCode,
	|	UNDEFINED AS PlanningDocument,
	|	SourceTable1.Arm AS Arm,
	|	SourceTable1.T2PackagingUnit AS Package,
	|	&AdditionalFields,
	|	SourceTable1.Difference AS ToDeliver,
	|	0 AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	SourceTable1.LevelOfOperationT2 AS OperationLevel
	|FROM
	|	&SourceTable1 AS SourceTable1
	|WHERE
	|	SourceTable1.Difference <> 0
	|	AND NOT SourceTable1.AugmentedStringT2
	|	AND SourceTable1.LevelOfOperationT1 = 20";
	
	Return Template;
	
EndFunction

Function DeliveryRequestTemplate()
	
	TemplateTexts = New Array; // Array of String
	
	// Storno compared to the previous level of delivery planning
	
	SourceTable1 = "TTComparisonOfCurrentLevelWithPreviousOne";
	
	Template = RequestTemplateStornoT1ForPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	Template = RequestTemplateStornoT1WithoutPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	Template = RequestTemplateForNewT2ParametersAccordingToPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	Template = RequestTemplateForNewT2ParametersWithoutPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	// Storno compared to the next level of delivery planning
	
	SourceTable1 = "TTComparisonOfCurrentLevelWithNext";
	
	Template = RequestTemplateStornoT1ForPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	Template = RequestTemplateStornoT1WithoutPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	Template = RequestTemplateForNewT2ParametersAccordingToPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	Template = RequestTemplateForNewT2ParametersWithoutPlanningDocument();
	Template = StrReplace(Template, "&SourceTable1", SourceTable1);
	TemplateTexts.Add(Template);
	
	// Register Records of the current registrar
	
	CompleteTemplateWithActualRegisteredRecorded(TemplateTexts);
	
	DeliveryRequestTemplate = StrConcat(TemplateTexts, Common.UnionAllText()) + "
		|
		|ORDER BY
		|	LineNumber,
		|	Arm";
	
	Return DeliveryRequestTemplate;
	
EndFunction

Procedure CompleteTemplateWithActualRegisteredRecorded(TemplateTexts)
	
	AdditionalFieldsStorno =
	"FALSE AS ThisIsFinalArm,
	|0 AS MinimumArmNumber,
	|FALSE AS PrimaryRegisterRecord,
	|DATETIME(1, 1, 1) AS SourceShipmentDate,
	|VALUE(Catalog.Assignments.EmptyRef) AS Purpose";
	
	InsertAdditionalFieldsIntoTemplates(TemplateTexts, AdditionalFieldsStorno);
	
	// Additional fields in the template are placed between the Packaging Unit and Delivery order fields
	
	TemplateOfCurrentRegisteredRecordsOfCurrentRegistrar =
	"SELECT
	|	&Ref AS Recorder,
	|	UNDEFINED AS ReversedPlan,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Period AS Period,
	|	DataTable.Organization AS Organization,
	|	DataTable.DeliveryType AS DeliveryType,
	|	DataTable.DateOfShipment AS DateOfShipment,
	|	DataTable.DeliveryMethod AS DeliveryMethod,
	|	DataTable.Carrier AS Carrier,
	|	DataTable.Sender AS Sender,
	|	DataTable.SenderPoint AS SenderPoint,
	|	DataTable.Sender_Area AS Sender_Area,
	|	DataTable.Recipient AS Recipient,
	|	DataTable.RecipientPoint AS RecipientPoint,
	|	DataTable.Recipient_Area AS Recipient_Area,
	|	DataTable.ReferenceOrder AS ReferenceOrder,
	|	DataTable.Trip AS Trip,
	|	DataTable.Products AS Products,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.Series AS Series,
	|	DataTable.RowCode AS RowCode,
	|	DataTable.PlanningDocument AS PlanningDocument,
	|	DataTable.Arm AS Arm,
	|	DataTable.Package AS Package,
	|	DataTable.ThisIsFinalArm AS ThisIsFinalArm,
	|	DataTable.MinimumArmNumber AS MinimumArmNumber,
	|	DataTable.PrimaryRegisterRecord AS PrimaryRegisterRecord,
	|	DataTable.SourceShipmentDate AS SourceShipmentDate,
	|	DataTable.Purpose AS Purpose,
	|	DataTable.ToDeliver AS ToDeliver,
	|	DataTable.ToTrip AS ToTrip,
	|	DataTable.InTrip AS InTrip,
	|	DataTable.InTransit AS InTransit,
	|	DataTable.Delivered AS Delivered,
	|	DataTable.Canceled AS Canceled,
	|	DataTable.ForAssembly AS ForAssembly,
	|	DataTable.AssemblyInProgress AS AssemblyInProgress,
	|	DataTable.Assembled AS Assembled,
	|	DataTable.OperationLevel AS OperationLevel
	|	
	|FROM
	|	&DataTable AS DataTable";
	
	TemplateTexts.Add(TemplateOfCurrentRegisteredRecordsOfCurrentRegistrar);
	
EndProcedure

#Region ControlOfBalance

Function QueryTextPrimaryDeliveryAssignmentsForDimensional()
	
	QueryText =
	"SELECT DISTINCT
	|	ChangesInMeasuredGoods.ReferenceOrder AS ReferenceOrder,
	|	CASE
	|		WHEN ChangesInMeasuredGoods.PlanningDocument REFS Document.DeliveryOrder
	|			THEN UNDEFINED
	|		ELSE ChangesInMeasuredGoods.PlanningDocument
	|	END AS PlanningDocument,
	|	ChangesInMeasuredGoods.Products AS Products,
	|	ChangesInMeasuredGoods.Characteristic AS Characteristic,
	|	ChangesInMeasuredGoods.Series AS Series,
	|	ChangesInMeasuredGoods.RowCode AS RowCode,
	|	ISNULL(DeliveryAccordingToPlanningDocument.Purpose, DeliveryWithoutPlanningDocument.Purpose) AS Purpose
	|INTO VT_PrimaryDeliveryAssignmentsForDimensional
	|FROM
	|	(SELECT DISTINCT
	|		RegisteredRecordsDeliveryChange.ReferenceOrder AS ReferenceOrder,
	|		RegisteredRecordsDeliveryChange.PlanningDocument AS PlanningDocument,
	|		RegisteredRecordsDeliveryChange.Products AS Products,
	|		RegisteredRecordsDeliveryChange.Characteristic AS Characteristic,
	|		RegisteredRecordsDeliveryChange.Series AS Series,
	|		RegisteredRecordsDeliveryChange.RowCode AS RowCode
	|	FROM
	|		RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON RegisteredRecordsDeliveryChange.Products = CatalogProducts.Ref
	|	WHERE
	|		CatalogProducts.UnitOfMeasure.MeasuredValueType IN(&DimensionalTypesOfUnits)) AS ChangesInMeasuredGoods
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryAccordingToPlanningDocument
	|		ON ChangesInMeasuredGoods.ReferenceOrder = DeliveryAccordingToPlanningDocument.ReferenceOrder
	|			AND ChangesInMeasuredGoods.RowCode = DeliveryAccordingToPlanningDocument.RowCode
	|			AND (NOT ChangesInMeasuredGoods.PlanningDocument REFS Document.DeliveryOrder)
	|			AND ChangesInMeasuredGoods.PlanningDocument = DeliveryAccordingToPlanningDocument.PlanningDocument
	|			AND (DeliveryAccordingToPlanningDocument.PrimaryRegisterRecord = TRUE)
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryWithoutPlanningDocument
	|		ON ChangesInMeasuredGoods.ReferenceOrder = DeliveryWithoutPlanningDocument.ReferenceOrder
	|			AND ChangesInMeasuredGoods.RowCode = DeliveryWithoutPlanningDocument.RowCode
	|			AND (ChangesInMeasuredGoods.PlanningDocument REFS Document.DeliveryOrder)
	|			AND (DeliveryWithoutPlanningDocument.PlanningDocument = UNDEFINED)
	|			AND (DeliveryWithoutPlanningDocument.PrimaryRegisterRecord = TRUE)
	|WHERE
	|	(DeliveryAccordingToPlanningDocument.Purpose IS NOT NULL 
	|			OR DeliveryWithoutPlanningDocument.Purpose IS NOT NULL )";
	
	Return QueryText;
	
EndFunction

Function QueryTextAcceptableDeviationsForTrip()
	
	QueryText =
	"SELECT DISTINCT
	|	GoodsForShipmentTurnover.DocumentShipments AS ReferenceOrder,
	|	GoodsForShipmentTurnover.Products AS Products,
	|	GoodsForShipmentTurnover.Characteristic AS Characteristic,
	|	GoodsForShipmentTurnover.Series AS Series,
	|	GoodsForShipmentTurnover.Purpose AS Purpose,
	|	GoodsForShipmentTurnover.ToShipReceipt AS ToShipReceipt,
	|	CAST(GoodsForShipmentTurnover.ToShipReceipt * &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 AS NUMBER(15, 3)) AS AllowableVariance
	|INTO VT_PermissibleDeviationsToFlight
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(DocumentShipments, Products, Characteristic, Purpose, Series) IN
	|					(SELECT
	|						PrimaryDeliveryDestinations.ReferenceOrder,
	|						PrimaryDeliveryDestinations.Products,
	|						PrimaryDeliveryDestinations.Characteristic,
	|						PrimaryDeliveryDestinations.Purpose,
	|						PrimaryDeliveryDestinations.Series
	|					FROM
	|						VT_PrimaryDeliveryAssignmentsForDimensional AS PrimaryDeliveryDestinations)) AS GoodsForShipmentTurnover
	|";
	
	Return QueryText;
	
EndFunction

Function DeliveryControlQueryText(ExpressToCheck, ConsiderPlanningDocuments, ExpressionAcceptableDeviation, ControlDeviationOfMeasuredGoods)
	
	QueryText =
	"SELECT DISTINCT
	|	DeliveryTurnover.Organization AS Organization,
	|	DeliveryTurnover.DeliveryType AS DeliveryType,
	|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
	|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
	|	DeliveryTurnover.Sender AS Sender,
	|	DeliveryTurnover.SenderPoint AS SenderPoint,
	|	DeliveryTurnover.Sender_Area AS Sender_Area,
	|	DeliveryTurnover.Recipient AS Recipient,
	|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
	|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	&PlanningDocumentField AS PlanningDocument,
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.RowCode AS RowCode,
	|	DeliveryTurnover.Arm AS Arm,
	|	DeliveryTurnover.Carrier AS Carrier,
	|	-1 * (&ExpressToCheck) AS Excess,
	|	DeliveryTurnover.Products.UnitOfMeasure AS UnitOfMeasure
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			(Organization, DeliveryType, DateOfShipment, DeliveryMethod,
	|			Sender, SenderPoint, Sender_Area,
	|			Recipient, RecipientPoint, Recipient_Area,
	|			&SelectionOfTurnoverPlanningDocument, ReferenceOrder,
	|			Products, Characteristic, Series, RowCode, Arm, Carrier) IN
	|				(SELECT
	|					Table.Organization AS Organization,
	|					Table.DeliveryType AS DeliveryType,
	|					Table.DateOfShipment AS DateOfShipment,
	|					Table.DeliveryMethod AS DeliveryMethod,
	|					Table.Sender AS Sender,
	|					Table.SenderPoint AS SenderPoint,
	|					Table.Sender_Area AS Sender_Area,
	|					Table.Recipient AS Recipient,
	|					Table.RecipientPoint AS RecipientPoint,
	|					Table.Recipient_Area AS Recipient_Area,
	|					&SelectionModificationPlanningDocument AS PlanningDocument,
	|					Table.ReferenceOrder AS ReferenceOrder,
	|					Table.Products AS Products,
	|					Table.Characteristic AS Characteristic,
	|					Table.Series AS Series,
	|					Table.RowCode AS RowCode,
	|					Table.Arm AS Arm,
	|					Table.Carrier AS Carrier
	|				FROM
	|					RegisteredRecordsDeliveryChange AS Table)) AS DeliveryTurnover
	|		LEFT JOIN &AcceptableDeviationsOfDeliveryBalances AS AcceptableDeviationsOfDeliveryBalances ON TRUE
	|WHERE
	|	&ExpressToCheck + &ExpressionAcceptableDeviation < 0";
	
	If ConsiderPlanningDocuments Then
		
		PlanningDocumentField = "DeliveryTurnover.PlanningDocument";
		SelectionOfTurnoverPlanningDocument = "PlanningDocument";
		SelectionModificationPlanningDocument = "Table.PlanningDocument";
		
	Else
		
		PlanningDocumentField = "UNDEFINED";
		SelectionOfTurnoverPlanningDocument = "UNDEFINED";
		SelectionModificationPlanningDocument = "UNDEFINED";
		
	EndIf;
	
	If ControlDeviationOfMeasuredGoods
	   And ConsiderPlanningDocuments Then
		
		ConnectionPermissibleDeviations =
		"LEFT JOIN VT_PrimaryDeliveryAssignmentsForDimensional AS PrimaryDeliveryAssignmentsAccordingToPlanningDocument
		|ON DeliveryTurnover.ReferenceOrder = PrimaryDeliveryAssignmentsAccordingToPlanningDocument.ReferenceOrder
		|	AND DeliveryTurnover.Products = PrimaryDeliveryAssignmentsAccordingToPlanningDocument.Products
		|	AND DeliveryTurnover.Characteristic = PrimaryDeliveryAssignmentsAccordingToPlanningDocument.Characteristic
		|	AND DeliveryTurnover.Series = PrimaryDeliveryAssignmentsAccordingToPlanningDocument.Series
		|	AND DeliveryTurnover.RowCode = PrimaryDeliveryAssignmentsAccordingToPlanningDocument.RowCode
		|	AND (NOT DeliveryTurnover.PlanningDocument REFS Document.DeliveryOrder)
		|	AND DeliveryTurnover.PlanningDocument = PrimaryDeliveryAssignmentsAccordingToPlanningDocument.PlanningDocument
		|LEFT JOIN VT_PrimaryDeliveryAssignmentsForDimensional AS PrimaryDeliveryAssignmentsWithoutPlanningDocument
		|ON DeliveryTurnover.ReferenceOrder = PrimaryDeliveryAssignmentsWithoutPlanningDocument.ReferenceOrder
		|	AND DeliveryTurnover.Products = PrimaryDeliveryAssignmentsWithoutPlanningDocument.Products
		|	AND DeliveryTurnover.Characteristic = PrimaryDeliveryAssignmentsWithoutPlanningDocument.Characteristic
		|	AND DeliveryTurnover.Series = PrimaryDeliveryAssignmentsWithoutPlanningDocument.Series
		|	AND DeliveryTurnover.RowCode = PrimaryDeliveryAssignmentsWithoutPlanningDocument.RowCode
		|	AND DeliveryTurnover.PlanningDocument REFS Document.DeliveryOrder
		|	AND PrimaryDeliveryAssignmentsWithoutPlanningDocument.PlanningDocument = UNDEFINED
		|LEFT JOIN VT_PermissibleDeviationsToFlight AS AcceptableDeviationsOfDeliveryBalances
		|ON DeliveryTurnover.ReferenceOrder = AcceptableDeviationsOfDeliveryBalances.ReferenceOrder
		|	AND DeliveryTurnover.Products = AcceptableDeviationsOfDeliveryBalances.Products
		|	AND DeliveryTurnover.Characteristic = AcceptableDeviationsOfDeliveryBalances.Characteristic
		|	AND DeliveryTurnover.Series = AcceptableDeviationsOfDeliveryBalances.Series
		|	AND ISNULL(PrimaryDeliveryAssignmentsAccordingToPlanningDocument.Purpose, PrimaryDeliveryAssignmentsWithoutPlanningDocument.Purpose) = AcceptableDeviationsOfDeliveryBalances.Purpose";
		
	ElsIf ControlDeviationOfMeasuredGoods Then
		
		ConnectionPermissibleDeviations =
		"LEFT JOIN VT_PrimaryDeliveryAssignmentsForDimensional AS PrimaryDeliveryDestinations
		|ON DeliveryTurnover.ReferenceOrder = PrimaryDeliveryDestinations.ReferenceOrder
		|	AND DeliveryTurnover.Products = PrimaryDeliveryDestinations.Products
		|	AND DeliveryTurnover.Characteristic = PrimaryDeliveryDestinations.Characteristic
		|	AND DeliveryTurnover.Series = PrimaryDeliveryDestinations.Series
		|	AND DeliveryTurnover.RowCode = PrimaryDeliveryDestinations.RowCode
		|LEFT JOIN VT_PermissibleDeviationsToFlight AS AcceptableDeviationsOfDeliveryBalances
		|ON PrimaryDeliveryDestinations.ReferenceOrder = AcceptableDeviationsOfDeliveryBalances.ReferenceOrder
		|	AND PrimaryDeliveryDestinations.Products = AcceptableDeviationsOfDeliveryBalances.Products
		|	AND PrimaryDeliveryDestinations.Characteristic = AcceptableDeviationsOfDeliveryBalances.Characteristic
		|	AND PrimaryDeliveryDestinations.Series = AcceptableDeviationsOfDeliveryBalances.Series
		|	AND PrimaryDeliveryDestinations.Purpose = AcceptableDeviationsOfDeliveryBalances.Purpose";
		
	Else
		
		ConnectionPermissibleDeviations = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&PlanningDocumentField", PlanningDocumentField);
	QueryText = StrReplace(QueryText, "&SelectionOfTurnoverPlanningDocument", SelectionOfTurnoverPlanningDocument);
	QueryText = StrReplace(QueryText, "&SelectionModificationPlanningDocument", SelectionModificationPlanningDocument);
	QueryText = StrReplace(QueryText, "&ExpressToCheck", ExpressToCheck);
	QueryText = StrReplace(QueryText, "&ExpressionAcceptableDeviation", ExpressionAcceptableDeviation);
	
	QueryText = StrReplace(
		QueryText,
		"LEFT JOIN &AcceptableDeviationsOfDeliveryBalances AS AcceptableDeviationsOfDeliveryBalances ON TRUE",
		ConnectionPermissibleDeviations);
	
	Return QueryText;
	
EndFunction

Function QueryTextForControlWarehouseParameters()
	
	QueryText =
	"SELECT DISTINCT
	|	Warehouses.Ref AS Warehouse
	|INTO TT_Warehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		INNER JOIN RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		ON Warehouses.Ref = RegisteredRecordsDeliveryChange.Sender
	|			AND Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|			AND Warehouses.StartShipmentOnceDeliveryOrderIsCreated";
	
	Return QueryText;
	
EndFunction

Function QueryTextAcceptableDeviationsToKits()
	
	QueryText =
	"SELECT DISTINCT
	|	GoodsForShipmentTurnover.DocumentShipments AS ReferenceOrder,
	|	GoodsForShipmentTurnover.Products AS Products,
	|	GoodsForShipmentTurnover.Characteristic AS Characteristic,
	|	GoodsForShipmentTurnover.Series AS Series,
	|	GoodsForShipmentTurnover.Purpose AS Purpose,
	|	GoodsForShipmentTurnover.ToShipReceipt AS ToShipReceipt,
	|	CAST(GoodsForShipmentTurnover.ToShipReceipt * &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 AS NUMBER(15, 3)) AS AllowableVariance
	|INTO VT_PermissibleDeviationsToKits
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(DocumentShipments, Products, Characteristic, Purpose, Series) IN
	|					(SELECT
	|						Table.ReferenceOrder,
	|						Table.Products,
	|						Table.Characteristic,
	|						Table.Purpose,
	|						Table.Series
	|					FROM
	|						TT_PrimaryDeliveryRecords AS Table)
	|			AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)) AS GoodsForShipmentTurnover
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextPrimaryDeliveryRecords()
	
	QueryText =
	"SELECT DISTINCT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.PlanningDocument AS PlanningDocument,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.RowCode AS RowCode,
	|	RegisteredRecordsDeliveryChange.Trip AS Trip,
	|	Delivery.Purpose AS Purpose
	|INTO TT_PrimaryDeliveryRecords
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = Delivery.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = Delivery.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = Delivery.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = Delivery.Series
	|			AND Delivery.PrimaryRegisterRecord = TRUE
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode > 0
	|	AND RegisteredRecordsDeliveryChange.Trip <> VALUE(Document.Trip.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder AS ReferenceOrder,
	|	RegisteredRecordsOfDeliveryArePrimary.PlanningDocument AS PlanningDocument,
	|	RegisteredRecordsOfDeliveryArePrimary.Products AS Products,
	|	RegisteredRecordsOfDeliveryArePrimary.Characteristic AS Characteristic,
	|	RegisteredRecordsOfDeliveryArePrimary.Series AS Series,
	|	RegisteredRecordsOfDeliveryArePrimary.RowCode AS RowCode,
	|	RegisteredRecordsDeliveryChange.Trip AS Trip,
	|	RegisteredRecordsOfDeliveryArePrimary.Purpose AS Purpose
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|			AND DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryRegisteredRecordsOfTrip
	|		ON DeliveryOrderRegisteredRecords.ReferenceOrder = DeliveryRegisteredRecordsOfTrip.ReferenceOrder
	|			AND DeliveryOrderRegisteredRecords.Products = DeliveryRegisteredRecordsOfTrip.Products
	|			AND DeliveryOrderRegisteredRecords.Characteristic = DeliveryRegisteredRecordsOfTrip.Characteristic
	|			AND DeliveryOrderRegisteredRecords.Series = DeliveryRegisteredRecordsOfTrip.Series
	|			AND DeliveryOrderRegisteredRecords.Trip = DeliveryRegisteredRecordsOfTrip.Trip
	|			AND DeliveryRegisteredRecordsOfTrip.ForAssembly > 0
	|			AND DeliveryRegisteredRecordsOfTrip.PlanningDocument REFS Document.DeliveryOrder
	|		INNER JOIN AccumulationRegister.Delivery AS RegisteredRecordsOfDeliveryArePrimary
	|		ON DeliveryOrderRegisteredRecords.ReferenceOrder = RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder
	|			AND RegisteredRecordsOfDeliveryArePrimary.PlanningDocument = UNDEFINED
	|			AND DeliveryOrderRegisteredRecords.Products = RegisteredRecordsOfDeliveryArePrimary.Products
	|			AND DeliveryOrderRegisteredRecords.Characteristic = RegisteredRecordsOfDeliveryArePrimary.Characteristic
	|			AND DeliveryOrderRegisteredRecords.Series = RegisteredRecordsOfDeliveryArePrimary.Series
	|			AND DeliveryOrderRegisteredRecords.Purpose = RegisteredRecordsOfDeliveryArePrimary.Purpose
	|			AND DeliveryRegisteredRecordsOfTrip.RowCode = RegisteredRecordsOfDeliveryArePrimary.RowCode
	|			AND RegisteredRecordsOfDeliveryArePrimary.PrimaryRegisterRecord = TRUE
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode = 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder AS ReferenceOrder,
	|	RegisteredRecordsOfDeliveryArePrimary.PlanningDocument AS PlanningDocument,
	|	RegisteredRecordsOfDeliveryArePrimary.Products AS Products,
	|	RegisteredRecordsOfDeliveryArePrimary.Characteristic AS Characteristic,
	|	RegisteredRecordsOfDeliveryArePrimary.Series AS Series,
	|	RegisteredRecordsOfDeliveryArePrimary.RowCode AS RowCode,
	|	RegisteredRecordsDeliveryChange.Trip AS Trip,
	|	RegisteredRecordsOfDeliveryArePrimary.Purpose AS Purpose
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|			AND DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryRegisteredRecordsOfTrip
	|		ON DeliveryOrderRegisteredRecords.ReferenceOrder = DeliveryRegisteredRecordsOfTrip.ReferenceOrder
	|			AND DeliveryOrderRegisteredRecords.Products = DeliveryRegisteredRecordsOfTrip.Products
	|			AND DeliveryOrderRegisteredRecords.Characteristic = DeliveryRegisteredRecordsOfTrip.Characteristic
	|			AND DeliveryOrderRegisteredRecords.Series = DeliveryRegisteredRecordsOfTrip.Series
	|			AND DeliveryOrderRegisteredRecords.Trip = DeliveryRegisteredRecordsOfTrip.Trip
	|			AND DeliveryRegisteredRecordsOfTrip.ForAssembly > 0
	|			AND NOT (DeliveryRegisteredRecordsOfTrip.PlanningDocument REFS Document.DeliveryOrder)
	|		INNER JOIN AccumulationRegister.Delivery AS RegisteredRecordsOfDeliveryArePrimary
	|		ON DeliveryOrderRegisteredRecords.ReferenceOrder = RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder
	|			AND DeliveryRegisteredRecordsOfTrip.PlanningDocument = RegisteredRecordsOfDeliveryArePrimary.PlanningDocument
	|			AND DeliveryOrderRegisteredRecords.Products = RegisteredRecordsOfDeliveryArePrimary.Products
	|			AND DeliveryOrderRegisteredRecords.Characteristic = RegisteredRecordsOfDeliveryArePrimary.Characteristic
	|			AND DeliveryOrderRegisteredRecords.Series = RegisteredRecordsOfDeliveryArePrimary.Series
	|			AND DeliveryOrderRegisteredRecords.Purpose = RegisteredRecordsOfDeliveryArePrimary.Purpose
	|			AND DeliveryRegisteredRecordsOfTrip.RowCode = RegisteredRecordsOfDeliveryArePrimary.RowCode
	|			AND RegisteredRecordsOfDeliveryArePrimary.PrimaryRegisterRecord = TRUE
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode = 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder,
	|	RegisteredRecordsOfDeliveryArePrimary.PlanningDocument,
	|	RegisteredRecordsOfDeliveryArePrimary.Products,
	|	RegisteredRecordsOfDeliveryArePrimary.Characteristic,
	|	RegisteredRecordsOfDeliveryArePrimary.Series,
	|	RegisteredRecordsOfDeliveryArePrimary.RowCode,
	|	RegisteredRecordsDeliveryChange.Trip,
	|	RegisteredRecordsOfDeliveryArePrimary.Purpose
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|			AND (DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote)
	|		INNER JOIN AccumulationRegister.Delivery AS RegisteredRecordsOfDeliveryArePrimary
	|		ON (DeliveryOrderRegisteredRecords.ReferenceOrder = RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder)
	|			AND (DeliveryOrderRegisteredRecords.Products = RegisteredRecordsOfDeliveryArePrimary.Products)
	|			AND (DeliveryOrderRegisteredRecords.Characteristic = RegisteredRecordsOfDeliveryArePrimary.Characteristic)
	|			AND (DeliveryOrderRegisteredRecords.Series = RegisteredRecordsOfDeliveryArePrimary.Series)
	|			AND (DeliveryOrderRegisteredRecords.Purpose = RegisteredRecordsOfDeliveryArePrimary.Purpose)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.PrimaryRegisterRecord = TRUE)
	|			AND RegisteredRecordsOfDeliveryArePrimary.PlanningDocument = UNDEFINED
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryRegisteredRecordsOfTrip
	|		ON (RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder = DeliveryRegisteredRecordsOfTrip.ReferenceOrder)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.Products = DeliveryRegisteredRecordsOfTrip.Products)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.Characteristic = DeliveryRegisteredRecordsOfTrip.Characteristic)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.Series = DeliveryRegisteredRecordsOfTrip.Series)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.RowCode = DeliveryRegisteredRecordsOfTrip.RowCode)
	|			AND (DeliveryOrderRegisteredRecords.Trip = DeliveryRegisteredRecordsOfTrip.Trip)
	|			AND (DeliveryRegisteredRecordsOfTrip.ForAssembly > 0)
	|			AND DeliveryRegisteredRecordsOfTrip.PlanningDocument REFS Document.DeliveryOrder
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode = 0
	|	AND DeliveryRegisteredRecordsOfTrip.Recorder IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder,
	|	RegisteredRecordsOfDeliveryArePrimary.PlanningDocument,
	|	RegisteredRecordsOfDeliveryArePrimary.Products,
	|	RegisteredRecordsOfDeliveryArePrimary.Characteristic,
	|	RegisteredRecordsOfDeliveryArePrimary.Series,
	|	RegisteredRecordsOfDeliveryArePrimary.RowCode,
	|	RegisteredRecordsDeliveryChange.Trip,
	|	RegisteredRecordsOfDeliveryArePrimary.Purpose
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|			AND (DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote)
	|		INNER JOIN AccumulationRegister.Delivery AS RegisteredRecordsOfDeliveryArePrimary
	|		ON (DeliveryOrderRegisteredRecords.ReferenceOrder = RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder)
	|			AND (DeliveryOrderRegisteredRecords.Products = RegisteredRecordsOfDeliveryArePrimary.Products)
	|			AND (DeliveryOrderRegisteredRecords.Characteristic = RegisteredRecordsOfDeliveryArePrimary.Characteristic)
	|			AND (DeliveryOrderRegisteredRecords.Series = RegisteredRecordsOfDeliveryArePrimary.Series)
	|			AND (DeliveryOrderRegisteredRecords.Purpose = RegisteredRecordsOfDeliveryArePrimary.Purpose)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.PrimaryRegisterRecord = TRUE)
	|			AND RegisteredRecordsOfDeliveryArePrimary.PlanningDocument <> UNDEFINED
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryRegisteredRecordsOfTrip
	|		ON (RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder = DeliveryRegisteredRecordsOfTrip.ReferenceOrder)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.Products = DeliveryRegisteredRecordsOfTrip.Products)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.Characteristic = DeliveryRegisteredRecordsOfTrip.Characteristic)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.Series = DeliveryRegisteredRecordsOfTrip.Series)
	|			AND (RegisteredRecordsOfDeliveryArePrimary.RowCode = DeliveryRegisteredRecordsOfTrip.RowCode)
	|			AND (DeliveryOrderRegisteredRecords.Trip = DeliveryRegisteredRecordsOfTrip.Trip)
	|			AND (DeliveryRegisteredRecordsOfTrip.ForAssembly > 0)
	|			AND (DeliveryRegisteredRecordsOfTrip.PlanningDocument = RegisteredRecordsOfDeliveryArePrimary.PlanningDocument)
	|			
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode = 0
	|	AND DeliveryRegisteredRecordsOfTrip.Recorder IS NULL
	|	
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder AS ReferenceOrder,
	|	RegisteredRecordsOfDeliveryArePrimary.PlanningDocument AS PlanningDocument,
	|	RegisteredRecordsOfDeliveryArePrimary.Products AS Products,
	|	RegisteredRecordsOfDeliveryArePrimary.Characteristic AS Characteristic,
	|	RegisteredRecordsOfDeliveryArePrimary.Series AS Series,
	|	RegisteredRecordsOfDeliveryArePrimary.RowCode AS RowCode,
	|	RegisteredRecordsDeliveryChange.Trip AS Trip,
	|	RegisteredRecordsOfDeliveryArePrimary.Purpose AS Purpose
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|			AND DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryRegisteredRecordsOfTrip
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryRegisteredRecordsOfTrip.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryRegisteredRecordsOfTrip.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryRegisteredRecordsOfTrip.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryRegisteredRecordsOfTrip.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryRegisteredRecordsOfTrip.Trip
	|			AND DeliveryRegisteredRecordsOfTrip.ForAssembly > 0
	|			AND DeliveryRegisteredRecordsOfTrip.PlanningDocument REFS Document.DeliveryOrder
	|		INNER JOIN AccumulationRegister.Delivery AS RegisteredRecordsOfDeliveryArePrimary
	|		ON DeliveryRegisteredRecordsOfTrip.ReferenceOrder = RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder
	|			AND RegisteredRecordsOfDeliveryArePrimary.PlanningDocument = UNDEFINED
	|			AND DeliveryRegisteredRecordsOfTrip.Products = RegisteredRecordsOfDeliveryArePrimary.Products
	|			AND DeliveryRegisteredRecordsOfTrip.Characteristic = RegisteredRecordsOfDeliveryArePrimary.Characteristic
	|			AND DeliveryRegisteredRecordsOfTrip.Series = RegisteredRecordsOfDeliveryArePrimary.Series
	|			AND DeliveryRegisteredRecordsOfTrip.RowCode = RegisteredRecordsOfDeliveryArePrimary.RowCode
	|			AND RegisteredRecordsOfDeliveryArePrimary.PrimaryRegisterRecord = TRUE
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode = 0
	|	AND DeliveryOrderRegisteredRecords.Recorder IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder AS ReferenceOrder,
	|	RegisteredRecordsOfDeliveryArePrimary.PlanningDocument AS PlanningDocument,
	|	RegisteredRecordsOfDeliveryArePrimary.Products AS Products,
	|	RegisteredRecordsOfDeliveryArePrimary.Characteristic AS Characteristic,
	|	RegisteredRecordsOfDeliveryArePrimary.Series AS Series,
	|	RegisteredRecordsOfDeliveryArePrimary.RowCode AS RowCode,
	|	RegisteredRecordsDeliveryChange.Trip AS Trip,
	|	RegisteredRecordsOfDeliveryArePrimary.Purpose AS Purpose
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|		INNER JOIN TT_Warehouses AS Warehouses
	|		ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|			AND DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote
	|		INNER JOIN AccumulationRegister.Delivery AS DeliveryRegisteredRecordsOfTrip
	|		ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryRegisteredRecordsOfTrip.ReferenceOrder
	|			AND RegisteredRecordsDeliveryChange.Products = DeliveryRegisteredRecordsOfTrip.Products
	|			AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryRegisteredRecordsOfTrip.Characteristic
	|			AND RegisteredRecordsDeliveryChange.Series = DeliveryRegisteredRecordsOfTrip.Series
	|			AND RegisteredRecordsDeliveryChange.Trip = DeliveryRegisteredRecordsOfTrip.Trip
	|			AND DeliveryRegisteredRecordsOfTrip.ForAssembly > 0
	|			AND NOT (DeliveryRegisteredRecordsOfTrip.PlanningDocument REFS Document.DeliveryOrder)
	|		INNER JOIN AccumulationRegister.Delivery AS RegisteredRecordsOfDeliveryArePrimary
	|		ON DeliveryRegisteredRecordsOfTrip.ReferenceOrder = RegisteredRecordsOfDeliveryArePrimary.ReferenceOrder
	|			AND DeliveryRegisteredRecordsOfTrip.PlanningDocument = RegisteredRecordsOfDeliveryArePrimary.PlanningDocument
	|			AND DeliveryRegisteredRecordsOfTrip.Products = RegisteredRecordsOfDeliveryArePrimary.Products
	|			AND DeliveryRegisteredRecordsOfTrip.Characteristic = RegisteredRecordsOfDeliveryArePrimary.Characteristic
	|			AND DeliveryRegisteredRecordsOfTrip.Series = RegisteredRecordsOfDeliveryArePrimary.Series
	|			AND DeliveryRegisteredRecordsOfTrip.RowCode = RegisteredRecordsOfDeliveryArePrimary.RowCode
	|			AND RegisteredRecordsOfDeliveryArePrimary.PrimaryRegisterRecord = TRUE
	|WHERE
	|	RegisteredRecordsDeliveryChange.RowCode = 0
	|	AND DeliveryOrderRegisteredRecords.Recorder IS NULL";
	
	Return QueryText;
	
EndFunction

Function QueryTextTurnoverOfKitsByOrder()
	
	QueryText =
	"SELECT
	|	Delivery.ReferenceOrder AS ReferenceOrder,
	|	Delivery.Products AS Products,
	|	Delivery.Characteristic AS Characteristic,
	|	Delivery.Series AS Series,
	|	Delivery.Purpose AS Purpose,
	|	Delivery.Trip AS Trip,
	|	SUM(Delivery.KittingIsScheduled) AS KittingIsScheduledTurnover,
	|	SUM(Delivery.AssemblyInProgress) AS AssemblyInProgressTurnover,
	|	SUM(Delivery.Assembled) AS AssembledTurnover
	|INTO TT_TurnoverOfKitsByOrder
	|FROM
	|	(SELECT DISTINCT
	|		PrimaryDeliveryRecords.ReferenceOrder AS ReferenceOrder,
	|		PrimaryDeliveryRecords.Products AS Products,
	|		PrimaryDeliveryRecords.Characteristic AS Characteristic,
	|		PrimaryDeliveryRecords.Series AS Series,
	|		PrimaryDeliveryRecords.Purpose AS Purpose,
	|		PrimaryDeliveryRecords.Trip AS Trip
	|	FROM
	|		TT_PrimaryDeliveryRecords AS PrimaryDeliveryRecords
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		DeliveryOrderRegisteredRecords.ReferenceOrder,
	|		DeliveryOrderRegisteredRecords.Products,
	|		DeliveryOrderRegisteredRecords.Characteristic,
	|		DeliveryOrderRegisteredRecords.Series,
	|		DeliveryOrderRegisteredRecords.Purpose,
	|		DeliveryOrderRegisteredRecords.Trip
	|	FROM
	|		RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|			INNER JOIN TT_Warehouses AS Warehouses
	|			ON RegisteredRecordsDeliveryChange.Sender = Warehouses.Warehouse
	|			INNER JOIN AccumulationRegister.Delivery AS DeliveryOrderRegisteredRecords
	|			ON RegisteredRecordsDeliveryChange.ReferenceOrder = DeliveryOrderRegisteredRecords.ReferenceOrder
	|				AND RegisteredRecordsDeliveryChange.Products = DeliveryOrderRegisteredRecords.Products
	|				AND RegisteredRecordsDeliveryChange.Characteristic = DeliveryOrderRegisteredRecords.Characteristic
	|				AND RegisteredRecordsDeliveryChange.Series = DeliveryOrderRegisteredRecords.Series
	|				AND RegisteredRecordsDeliveryChange.Trip = DeliveryOrderRegisteredRecords.Trip
	|				AND (DeliveryOrderRegisteredRecords.Recorder REFS Document.GoodsIssueNote)
	|			LEFT JOIN TT_PrimaryDeliveryRecords AS PrimaryDeliveryRecords
	|			ON (DeliveryOrderRegisteredRecords.ReferenceOrder = PrimaryDeliveryRecords.ReferenceOrder)
	|				AND (DeliveryOrderRegisteredRecords.Products = PrimaryDeliveryRecords.Products)
	|				AND (DeliveryOrderRegisteredRecords.Characteristic = PrimaryDeliveryRecords.Characteristic)
	|				AND (DeliveryOrderRegisteredRecords.Series = PrimaryDeliveryRecords.Series)
	|				AND (DeliveryOrderRegisteredRecords.Trip = PrimaryDeliveryRecords.Trip)
	|				AND (DeliveryOrderRegisteredRecords.Purpose = PrimaryDeliveryRecords.Purpose)
	|	WHERE
	|		PrimaryDeliveryRecords.RowCode IS NULL) AS PrimaryDeliveryRecordsWithoutLineCode
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON PrimaryDeliveryRecordsWithoutLineCode.ReferenceOrder = Delivery.ReferenceOrder
	|			AND PrimaryDeliveryRecordsWithoutLineCode.Products = Delivery.Products
	|			AND PrimaryDeliveryRecordsWithoutLineCode.Characteristic = Delivery.Characteristic
	|			AND PrimaryDeliveryRecordsWithoutLineCode.Series = Delivery.Series
	|			AND PrimaryDeliveryRecordsWithoutLineCode.Purpose = Delivery.Purpose
	|			AND PrimaryDeliveryRecordsWithoutLineCode.Trip = Delivery.Trip
	|
	|GROUP BY
	|	Delivery.ReferenceOrder,
	|	Delivery.Products,
	|	Delivery.Characteristic,
	|	Delivery.Series,
	|	Delivery.Purpose,
	|	Delivery.Trip";
	
	Return QueryText;
	
EndFunction

Function QueryTextRevsForKitsOnTrip()
	
	QueryText =
	"SELECT
	|	NestedQuery.ReferenceOrder AS ReferenceOrder,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Trip AS Trip,
	|	SUM(NestedQuery.ForAssemblyTurnover) AS ForAssemblyTurnover,
	|	SUM(NestedQuery.InTransitTurnover) AS InTransitTurnover,
	|	SUM(NestedQuery.DeliveredTurnover) AS DeliveredTurnover
	|INTO TT_RevsForKitsOnTrip
	|FROM
	|	(SELECT
	|		DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|		DeliveryTurnover.Products AS Products,
	|		DeliveryTurnover.Characteristic AS Characteristic,
	|		DeliveryTurnover.Series AS Series,
	|		DeliveryTurnover.Products.UnitOfMeasure AS UnitOfMeasure,
	|		ISNULL(PrimaryDeliveryRecords.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
	|		DeliveryTurnover.Trip AS Trip,
	|		DeliveryTurnover.ForAssemblyTurnover AS ForAssemblyTurnover,
	|		DeliveryTurnover.InTransitTurnover AS InTransitTurnover,
	|		DeliveryTurnover.DeliveredTurnover AS DeliveredTurnover
	|	FROM
	|		AccumulationRegister.Delivery.Turnovers(
	|				,
	|				,
	|				,
	|				Arm = 1
	|					AND DeliveryType = VALUE(Enum.DeliveryTypes.OutgoingInfo)
	|					AND Sender IN
	|						(SELECT
	|							Warehouses.Warehouse AS Warehouse
	|						FROM
	|							TT_Warehouses AS Warehouses)
	|					AND NOT PlanningDocument REFS Document.DeliveryOrder
	|					AND (ReferenceOrder, PlanningDocument, Trip, Products, Characteristic, Series, RowCode) IN
	|						(SELECT
	|							Table.ReferenceOrder AS ReferenceOrder,
	|							Table.PlanningDocument AS PlanningDocument,
	|							Table.Trip AS Trip,
	|							Table.Products AS Products,
	|							Table.Characteristic AS Characteristic,
	|							Table.Series AS Series,
	|							Table.RowCode AS RowCode
	|						FROM
	|							TT_PrimaryDeliveryRecords AS Table
	|						WHERE
	|							Table.PlanningDocument <> UNDEFINED)) AS DeliveryTurnover
	|			LEFT JOIN TT_PrimaryDeliveryRecords AS PrimaryDeliveryRecords
	|			ON DeliveryTurnover.ReferenceOrder = PrimaryDeliveryRecords.ReferenceOrder
	|				AND DeliveryTurnover.PlanningDocument = PrimaryDeliveryRecords.PlanningDocument
	|				AND DeliveryTurnover.Products = PrimaryDeliveryRecords.Products
	|				AND DeliveryTurnover.Characteristic = PrimaryDeliveryRecords.Characteristic
	|				AND DeliveryTurnover.Series = PrimaryDeliveryRecords.Series
	|				AND DeliveryTurnover.RowCode = PrimaryDeliveryRecords.RowCode
	|				AND DeliveryTurnover.Trip = PrimaryDeliveryRecords.Trip
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DeliveryTurnover.ReferenceOrder,
	|		DeliveryTurnover.Products,
	|		DeliveryTurnover.Characteristic,
	|		DeliveryTurnover.Series,
	|		DeliveryTurnover.Products.UnitOfMeasure,
	|		ISNULL(PrimaryDeliveryRecords.Purpose, VALUE(Catalog.Assignments.EmptyRef)),
	|		DeliveryTurnover.Trip,
	|		DeliveryTurnover.ForAssemblyTurnover,
	|		DeliveryTurnover.InTransitTurnover AS InTransitTurnover,
	|		DeliveryTurnover.DeliveredTurnover AS DeliveredTurnover
	|	FROM
	|		AccumulationRegister.Delivery.Turnovers(
	|				,
	|				,
	|				,
	|				Arm = 1
	|					AND DeliveryType = VALUE(Enum.DeliveryTypes.OutgoingInfo)
	|					AND Sender IN
	|						(SELECT
	|							Warehouses.Warehouse AS Warehouse
	|						FROM
	|							TT_Warehouses AS Warehouses)
	|					AND PlanningDocument REFS Document.DeliveryOrder
	|					AND (ReferenceOrder, Trip, Products, Characteristic, Series, RowCode) IN
	|						(SELECT
	|							Table.ReferenceOrder AS ReferenceOrder,
	|							Table.Trip AS Trip,
	|							Table.Products AS Products,
	|							Table.Characteristic AS Characteristic,
	|							Table.Series AS Series,
	|							Table.RowCode AS RowCode
	|						FROM
	|							TT_PrimaryDeliveryRecords AS Table
	|						WHERE
	|							Table.PlanningDocument = UNDEFINED)) AS DeliveryTurnover
	|			LEFT JOIN TT_PrimaryDeliveryRecords AS PrimaryDeliveryRecords
	|			ON DeliveryTurnover.ReferenceOrder = PrimaryDeliveryRecords.ReferenceOrder
	|				AND (PrimaryDeliveryRecords.PlanningDocument = UNDEFINED)
	|				AND DeliveryTurnover.Products = PrimaryDeliveryRecords.Products
	|				AND DeliveryTurnover.Characteristic = PrimaryDeliveryRecords.Characteristic
	|				AND DeliveryTurnover.Series = PrimaryDeliveryRecords.Series
	|				AND DeliveryTurnover.RowCode = PrimaryDeliveryRecords.RowCode
	|				AND DeliveryTurnover.Trip = PrimaryDeliveryRecords.Trip) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ReferenceOrder,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Series,
	|	NestedQuery.Purpose,
	|	NestedQuery.Trip,
	|	NestedQuery.UnitOfMeasure";
	
	Return QueryText;
	
EndFunction

Function QueryTextForControllingAmountOfKittingForTrip(ExpressionAcceptableDeviation, ControlDeviationOfMeasuredGoods)
	
	QueryText =
	"SELECT
	|	RevsForKitsOnTrip.ReferenceOrder AS ReferenceOrder,
	|	RevsForKitsOnTrip.Products AS Products,
	|	RevsForKitsOnTrip.Characteristic AS Characteristic,
	|	RevsForKitsOnTrip.Series AS Series,
	|	RevsForKitsOnTrip.UnitOfMeasure AS UnitOfMeasure,
	|	RevsForKitsOnTrip.Purpose AS Purpose,
	|	RevsForKitsOnTrip.Trip AS Trip,
	|	-1 * (RevsForKitsOnTrip.ForAssemblyTurnover - ISNULL(TurnoverOfKitsByOrder.KittingIsScheduledTurnover, 0)
	|		- ISNULL(TurnoverOfKitsByOrder.AssemblyInProgressTurnover, 0) - ISNULL(TurnoverOfKitsByOrder.AssembledTurnover, 0)) AS Excess
	|FROM
	|	TT_RevsForKitsOnTrip AS RevsForKitsOnTrip
	|		LEFT JOIN TT_TurnoverOfKitsByOrder AS TurnoverOfKitsByOrder
	|			ON RevsForKitsOnTrip.ReferenceOrder = TurnoverOfKitsByOrder.ReferenceOrder
	|				AND RevsForKitsOnTrip.Products = TurnoverOfKitsByOrder.Products
	|				AND RevsForKitsOnTrip.Characteristic = TurnoverOfKitsByOrder.Characteristic
	|				AND RevsForKitsOnTrip.Series = TurnoverOfKitsByOrder.Series
	|				AND RevsForKitsOnTrip.Purpose = TurnoverOfKitsByOrder.Purpose
	|				AND RevsForKitsOnTrip.Trip = TurnoverOfKitsByOrder.Trip
	|		LEFT JOIN AcceptableDeviationsOfDeliveryBalances AS AcceptableDeviationsOfDeliveryBalances ON TRUE
	|WHERE
	|	RevsForKitsOnTrip.ForAssemblyTurnover - ISNULL(TurnoverOfKitsByOrder.KittingIsScheduledTurnover, 0)
	|		- ISNULL(TurnoverOfKitsByOrder.AssemblyInProgressTurnover, 0) - ISNULL(TurnoverOfKitsByOrder.AssembledTurnover, 0) + &ExpressionAcceptableDeviation < 0
	|
	|UNION ALL
	|
	|SELECT
	|	TurnoverOfKitsByOrder.ReferenceOrder AS ReferenceOrder,
	|	TurnoverOfKitsByOrder.Products AS Products,
	|	TurnoverOfKitsByOrder.Characteristic AS Characteristic,
	|	TurnoverOfKitsByOrder.Series AS Series,
	|	TurnoverOfKitsByOrder.Products.UnitOfMeasure AS UnitOfMeasure,
	|	TurnoverOfKitsByOrder.Purpose AS Purpose,
	|	TurnoverOfKitsByOrder.Trip AS Trip,
	|	-1 * (0 - TurnoverOfKitsByOrder.KittingIsScheduledTurnover
	|		- TurnoverOfKitsByOrder.AssemblyInProgressTurnover - TurnoverOfKitsByOrder.AssembledTurnover) AS Excess
	|FROM
	|	TT_TurnoverOfKitsByOrder AS TurnoverOfKitsByOrder
	|		LEFT JOIN TT_RevsForKitsOnTrip AS RevsForKitsOnTrip
	|			ON TurnoverOfKitsByOrder.ReferenceOrder = RevsForKitsOnTrip.ReferenceOrder
	|				AND TurnoverOfKitsByOrder.Products = RevsForKitsOnTrip.Products
	|				AND TurnoverOfKitsByOrder.Characteristic = RevsForKitsOnTrip.Characteristic
	|				AND TurnoverOfKitsByOrder.Series = RevsForKitsOnTrip.Series
	|				AND TurnoverOfKitsByOrder.Purpose = RevsForKitsOnTrip.Purpose
	|				AND TurnoverOfKitsByOrder.Trip = RevsForKitsOnTrip.Trip
	|WHERE
	|	RevsForKitsOnTrip.ForAssemblyTurnover IS NULL
	|	AND (TurnoverOfKitsByOrder.KittingIsScheduledTurnover + TurnoverOfKitsByOrder.AssemblyInProgressTurnover + TurnoverOfKitsByOrder.AssembledTurnover) > 0";
	
	If ControlDeviationOfMeasuredGoods Then
		
		ConnectionPermissibleDeviations =
		"LEFT JOIN VT_PermissibleDeviationsToKits AS AcceptableDeviationsOfDeliveryBalances
		|ON RevsForKitsOnTrip.ReferenceOrder = AcceptableDeviationsOfDeliveryBalances.ReferenceOrder
		|	AND RevsForKitsOnTrip.Products = AcceptableDeviationsOfDeliveryBalances.Products
		|	AND RevsForKitsOnTrip.Characteristic = AcceptableDeviationsOfDeliveryBalances.Characteristic
		|	AND RevsForKitsOnTrip.Series = AcceptableDeviationsOfDeliveryBalances.Series
		|	AND RevsForKitsOnTrip.Purpose = AcceptableDeviationsOfDeliveryBalances.Purpose";
		
	Else
		
		ConnectionPermissibleDeviations = "";
		
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"LEFT JOIN AcceptableDeviationsOfDeliveryBalances AS AcceptableDeviationsOfDeliveryBalances ON TRUE",
		ConnectionPermissibleDeviations);
	
	QueryText = StrReplace(QueryText, "&ExpressionAcceptableDeviation", ExpressionAcceptableDeviation);
	
	Return QueryText;
	
EndFunction

Function QueryTextForMonitoringTripStatuses(ExpressionAcceptableDeviation, ControlDeviationOfMeasuredGoods)
	
	If Not ControlDeviationOfMeasuredGoods Then
		
		QueryText =
		"SELECT
		|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
		|	DeliveryTurnover.Trip AS Trip,
		|	DeliveryTurnover.Sender AS Sender,
		|	DeliveryTurnover.Products AS Products,
		|	DeliveryTurnover.Products.UnitOfMeasure AS UnitOfMeasure,
		|	DeliveryTurnover.Characteristic AS Characteristic,
		|	DeliveryTurnover.Series AS Series,
		|	(DeliveryTurnover.AssembledTurnover - DeliveryTurnover.ForAssemblyTurnover) AS Excess
		|FROM
		|	AccumulationRegister.Delivery.Turnovers(
		|			,
		|			,
		|			,
		|			Arm = 1
		|				AND DeliveryType = VALUE(Enum.DeliveryTypes.OutgoingInfo)
		|				AND Sender IN
		|					(SELECT
		|						Warehouses.Warehouse AS Warehouse
		|					FROM
		|						TT_Warehouses AS Warehouses)
		|				AND (ReferenceOrder, Trip, Products, Characteristic, Series) IN
		|					(SELECT
		|						Table.ReferenceOrder AS ReferenceOrder,
		|						Table.Trip AS Trip,
		|						Table.Products AS Products,
		|						Table.Characteristic AS Characteristic,
		|						Table.Series AS Series
		|					FROM
		|						RegisteredRecordsDeliveryChange AS Table)) AS DeliveryTurnover
		|WHERE
		|	DeliveryTurnover.ForAssemblyTurnover <> DeliveryTurnover.AssembledTurnover
		|	AND (DeliveryTurnover.InTransitTurnover > 0
		|			OR DeliveryTurnover.DeliveredTurnover > 0)";
		
	Else
		
		QueryText =
		"SELECT
		|	RevsForKitsOnTrip.ReferenceOrder AS ReferenceOrder,
		|	RevsForKitsOnTrip.Products AS Products,
		|	RevsForKitsOnTrip.Characteristic AS Characteristic,
		|	RevsForKitsOnTrip.Series AS Series,
		|	RevsForKitsOnTrip.UnitOfMeasure AS UnitOfMeasure,
		|	RevsForKitsOnTrip.Purpose AS Purpose,
		|	RevsForKitsOnTrip.Trip AS Trip,
		|	(ISNULL(TurnoverOfKitsByOrder.AssembledTurnover, 0) - RevsForKitsOnTrip.ForAssemblyTurnover) AS Excess
		|FROM
		|	TT_RevsForKitsOnTrip AS RevsForKitsOnTrip
		|		LEFT JOIN TT_TurnoverOfKitsByOrder AS TurnoverOfKitsByOrder
		|			ON RevsForKitsOnTrip.ReferenceOrder = TurnoverOfKitsByOrder.ReferenceOrder
		|				AND RevsForKitsOnTrip.Products = TurnoverOfKitsByOrder.Products
		|				AND RevsForKitsOnTrip.Characteristic = TurnoverOfKitsByOrder.Characteristic
		|				AND RevsForKitsOnTrip.Series = TurnoverOfKitsByOrder.Series
		|				AND RevsForKitsOnTrip.Purpose = TurnoverOfKitsByOrder.Purpose
		|				AND RevsForKitsOnTrip.Trip = TurnoverOfKitsByOrder.Trip
		|		LEFT JOIN VT_PermissibleDeviationsToKits AS AcceptableDeviationsOfDeliveryBalances
		|			ON RevsForKitsOnTrip.ReferenceOrder = AcceptableDeviationsOfDeliveryBalances.ReferenceOrder
		|				AND RevsForKitsOnTrip.Products = AcceptableDeviationsOfDeliveryBalances.Products
		|				AND RevsForKitsOnTrip.Characteristic = AcceptableDeviationsOfDeliveryBalances.Characteristic
		|				AND RevsForKitsOnTrip.Series = AcceptableDeviationsOfDeliveryBalances.Series
		|				AND RevsForKitsOnTrip.Purpose = AcceptableDeviationsOfDeliveryBalances.Purpose
		|WHERE
		|	((RevsForKitsOnTrip.ForAssemblyTurnover - ISNULL(TurnoverOfKitsByOrder.AssembledTurnover, 0)) > &ExpressionAcceptableDeviation
		|		OR ISNULL(TurnoverOfKitsByOrder.KittingIsScheduledTurnover, 0) <> 0
		|		OR ISNULL(TurnoverOfKitsByOrder.AssemblyInProgressTurnover, 0) <> 0)
		|	AND (RevsForKitsOnTrip.InTransitTurnover > 0
		|		OR RevsForKitsOnTrip.DeliveredTurnover > 0)";
		
		QueryText = StrReplace(QueryText, "&ExpressionAcceptableDeviation", ExpressionAcceptableDeviation);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function PresentationOfControlResultFields(ErrorString)
	
	Result = New Structure;
	
	If CommonClientServer.HasAttributeOrObjectProperty(ErrorString, "Purpose") Then
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			ErrorString.Products, ErrorString.Characteristic,, ErrorString.Series, ErrorString.Purpose);
		
	Else
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			ErrorString.Products, ErrorString.Characteristic,, ErrorString.Series);
		
	EndIf;
	Result.Insert("Products", ProductPresentation);
	
	PresentationOfOrder = String(ErrorString.ReferenceOrder);
	Result.Insert("ReferenceOrder", PresentationOfOrder);
	
	If CommonClientServer.HasAttributeOrObjectProperty(ErrorString, "Sender") Then
		SenderSRepresentation = String(ErrorString.Sender);
	Else
		SenderSRepresentation = "";
	EndIf;
	Result.Insert("Sender", SenderSRepresentation);
	
	PresentationExceeding = String(ErrorString.Excess);
	Result.Insert("Excess", PresentationExceeding);
	
	PresentationUnit = String(ErrorString.UnitOfMeasure);
	Result.Insert("UnitOfMeasure", PresentationUnit);
	
	If CommonClientServer.HasAttributeOrObjectProperty(ErrorString, "Organization") Then
		RepresentationOfTheOrganization = String(ErrorString.Organization);
	Else
		RepresentationOfTheOrganization = "";
	EndIf;
	Result.Insert("Organization", RepresentationOfTheOrganization);
	
	If CommonClientServer.HasAttributeOrObjectProperty(ErrorString, "Recipient") Then
		RecipientPresentation1 = String(ErrorString.Recipient);
	Else
		RecipientPresentation1 = "";
	EndIf;
	Result.Insert("Recipient", RecipientPresentation1);
	
	If CommonClientServer.HasAttributeOrObjectProperty(ErrorString, "Trip") Then
		PresentationOfTrip = String(ErrorString.Trip);
	Else
		PresentationOfTrip = "";
	EndIf;
	Result.Insert("Trip", PresentationOfTrip);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region AccessManagement

Procedure AddDeliveryManagerProfile(ProfilesDetails, ParametersOfUpdate)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name = "DeliveryOfficer";
	ProfileDetails.Id = "d3e34937-0a73-4468-8105-8f9ab0e311ac";
	ProfileDetails.Parent = "Other";
	ProfileDetails.Description = NStr("vi = 'Người quản lý giao nhận';
										|ru = 'Менеджер по доставке';
										|en = 'Delivery officer'; fa = 'Delivery officer';
										|it = 'Manager per la consegna';
										|pl = 'Kierownik dostaw';
										|tr = 'Teslimat yöneticisi'", Common.DefaultLanguageCode());
	
	TMAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadPersons");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsTransfer");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsIssues");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	// Addendum.
	ProfileDetails.Roles.Add("UseDeliveryWorkplace");
	ProfileDetails.Roles.Add("AddAndEditDeliveryPoints");
	ProfileDetails.Roles.Add("AddEditsDeliveryZones");
	ProfileDetails.Roles.Add("AddAndEditDeliveryOrders");
	ProfileDetails.Roles.Add("AddAndEditTrips");
	ProfileDetails.Roles.Add("AddEditsOfTransportationJobs");
	ProfileDetails.Roles.Add("AddEditVehicles");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	
	// Reports and processing.
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	AccessManagementLocalization.AddDeliveryManagerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ này có thể tạo và điều chỉnh khu vực giao hàng,
										|tạo và điều chỉnh phương tiện giao thông, kiểu phương tiện giao thông,
										|tạo và xử lý Nhiệm vụ vận chuyển,
										|làm việc với bộ xử lý Chỗ làm việc của người quản lý giao hàng';
										|ru = 'Под профилем осуществляется создание и редактирование зон доставки,
										|создание и редактирование транспортных средств, типов транспортных средств,
										|создание и обработка Заданий на перевозку,
										|работа в обработке Рабочее место менеджера по доставке';
										|en = 'Use this profile to create and edit delivery zones,
										|create and edit vehicles, vehicle types,
										|create and process itineraries,
										|operate in the ""Workplace of delivery officer"" data processor'; fa = 'Use this profile to create and edit delivery zones,
										|create and edit vehicles, vehicle types,
										|create and process itineraries,
										|operate in the ""Workplace of delivery officer"" data processor';
										|it = 'Sotto il profilo vengono create e modificate le aree di consegna, 
										|i mezzi di trasporto, i tipi di mezzo di trasporto 
										|, i task di trasporto e
										| l''elaborazione del posto di lavoro del manager per la consegna';
										|pl = 'Pod profilem odbywa się tworzenie i edycja stref dostawy,
										|tworzenie i edycja pojazdów, rodzajów pojazdów,
										|tworzenie i przetwarzanie Zadań na przewóz,
										|praca w przetwarzaniu Miejsce pracy kierownika dostaw';
										|tr = 'Profil altında teslimat bölgeleri
										|oluşturabilir ve düzenleyebilir, araçlar, araç türleri
										|oluşturabilir ve düzenleyebilir, Taşıma planları
										|oluşturabilir ve işleyebilir, teslimat yöneticisinin çalışma alanında çalışılabilinir'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion

#Region Delivery20

Procedure AddDeliveryDataToShipmentManagementQueryText20(Query, QueryText)
	
	QueryText = QueryText +
	"SELECT DISTINCT
	|	StatesAndDetailsOfDelivery.ReferenceOrder AS DocumentShipments,
	|	StatesAndDetailsOfDelivery.RecipientSender AS Recipient
	|INTO TTOrdersWithDeliveryByTasks
	|FROM
	|	InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		LEFT JOIN InformationRegister.GoodsToDeliver AS RefusalOfTransportation
	|		ON (RefusalOfTransportation.TransportationJob = VALUE(Document.TransportationJob.EmptyRef))
	|			AND StatesAndDetailsOfDelivery.Warehouse = RefusalOfTransportation.Warehouse
	|			AND (RefusalOfTransportation.ReferenceOrder = StatesAndDetailsOfDelivery.ReferenceOrder)
	|WHERE
	|	StatesAndDetailsOfDelivery.Warehouse = &Warehouse
	|	AND StatesAndDetailsOfDelivery.DeliveryMethod IN(&TransportMethods)
	|	AND RefusalOfTransportation.ReferenceOrder IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.DocumentShipments AS DocumentShipments,
	|	NestedQuery.Recipient AS Recipient,
	|	MIN(NestedQuery.State) AS State
	|INTO TTOrdersEEU
	|FROM
	|	(SELECT
	|		ReferencesToShip.DocumentShipments AS DocumentShipments,
	|		ReferencesToShip.Recipient AS Recipient,
	|		ReferencesToShip.Products AS Products,
	|		ReferencesToShip.Characteristic AS Characteristic,
	|		ReferencesToShip.Purpose AS Purpose,
	|		ReferencesToShip.Series AS Series,
	|		CASE
	|			WHEN &PendingPicking
	|				THEN 0
	|			WHEN ReferencesToShip.AssemblyInProgressBalance <> 0
	|				THEN 1
	|			WHEN ReferencesToShip.AssembledBalance <> 0
	|				THEN 2
	|			WHEN ReferencesToShip.ToRegisterBalance <> 0
	|				THEN 3
	|			ELSE 404
	|		END AS State
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS ReferencesToShip
	|	WHERE &ConditionGoodsForSelection) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.DocumentShipments,
	|	NestedQuery.Recipient
	|
	|INDEX BY
	|	DocumentShipments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TransportationTask.Ref AS Ref,
	|	TransportationTask.ReferenceOrder AS ReferenceOrder,
	|	TransportationTask.RecipientSender AS RecipientSender
	|INTO TTTransportTaskSelection
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|WHERE
	|	TransportationTask.Ref.Posted
	|	AND TransportationTask.Warehouse = &Warehouse
	|	AND TransportationTask.Ref.Status IN (VALUE(Enum.StatusesOfTransportationJobs.ToLoad))
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VALUETYPE(TransportationJobs.Ref) AS DocumentType,
	|	TransportationJobs.Ref AS ReferenceOrder,
	|	TransportationJobs.Ref AS TransportationJob,
	|	TransportationJobs.Ref.Number AS Number,
	|	TransportationJobs.Ref.PlanTripStartTime AS Date,
	|	UNDEFINED AS Recipient,
	|	CASE
	|		WHEN MIN(TTOrdersEEU.State) = 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN MIN(TTOrdersEEU.State) = 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN MIN(TTOrdersEEU.State) = 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		WHEN MIN(TTOrdersEEU.State) = 3
	|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END AS State,
	|	1 AS PictureIndex
	|FROM
	|	TTTransportTaskSelection AS TransportationJobs
	|		INNER JOIN TTOrdersEEU AS TTOrdersEEU
	|		ON (TTOrdersEEU.DocumentShipments = TransportationJobs.ReferenceOrder)
	|
	|GROUP BY
	|	TransportationJobs.Ref,
	|	TransportationJobs.Ref.Number,
	|	TransportationJobs.Ref.PlanTripStartTime
	|
	|HAVING
	|	CASE
	|		WHEN MIN(TTOrdersEEU.State) = 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN MIN(TTOrdersEEU.State) = 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN MIN(TTOrdersEEU.State) = 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		WHEN MIN(TTOrdersEEU.State) = 3
	|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END IN (&States1)
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN ReferencesToShip.DocumentShipments REFS Document.MovementOfProductsAndMaterials
	|			THEN PRESENTATION(ISNULL(DocumentsRegistry.BusinessOperation, VALUETYPE(ReferencesToShip.DocumentShipments)))
	|		ELSE 
	|	VALUETYPE(ReferencesToShip.DocumentShipments)
	|	END
	|,
	|	ReferencesToShip.DocumentShipments,
	|	VALUE(Document.TransportationJob.EmptyRef),
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """"),
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)),
	|	ReferencesToShip.Recipient,
	|	CASE
	|		WHEN ReferencesToShip.State = 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN ReferencesToShip.State = 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN ReferencesToShip.State = 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		WHEN ReferencesToShip.State = 3
	|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END,
	|	0
	|FROM
	|	TTOrdersEEU AS ReferencesToShip
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON ReferencesToShip.DocumentShipments = DocumentsRegistry.Ref
	|			AND (NOT DocumentsRegistry.AdditionalRecord)
	|		LEFT JOIN TTOrdersWithDeliveryByTasks AS TTOrdersWithDeliveryByTasks
	|		ON ReferencesToShip.DocumentShipments = TTOrdersWithDeliveryByTasks.DocumentShipments
	|WHERE
	|	TTOrdersWithDeliveryByTasks.DocumentShipments IS NULL
	|	AND CASE
	|			WHEN ReferencesToShip.State = 0
	|				THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|			WHEN ReferencesToShip.State = 1
	|				THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|			WHEN ReferencesToShip.State = 2
	|				THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|			WHEN ReferencesToShip.State = 3
	|				THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
	|			ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|		END IN (&States1)
	|
	|ORDER BY
	|	Date";
	
	TransportMethods = GoodsDeliveryClientServer.DeliveryMethodsToCustomerWithOurParticipation(
		GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
	
	Query.SetParameter("TransportMethods", TransportMethods);
	
EndProcedure

Procedure ToSupplementQueryTextOfShipmentManagementWithDeliveryData20ShipmentDetails(QueryText)
	
	QueryText = QueryText + "
	|SELECT DISTINCT
	|	NestedQuery.DocumentShipments AS ReferenceOrder,
	|	NestedQuery.Recipient AS Recipient,
	|	CASE
	|		WHEN MIN(NestedQuery.State) = 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN MIN(NestedQuery.State) = 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN MIN(NestedQuery.State) = 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		WHEN MIN(NestedQuery.State) = 3
	|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END AS State
	|INTO OrdersAndStates
	|FROM
	|	(SELECT
	|		ReferencesToShip.DocumentShipments AS DocumentShipments,
	|		ReferencesToShip.Recipient AS Recipient,
	|		ReferencesToShip.Products AS Products,
	|		ReferencesToShip.Characteristic AS Characteristic,
	|		ReferencesToShip.Purpose AS Purpose,
	|		ReferencesToShip.Series AS Series,
	|		CASE
	|			WHEN &PendingPicking
	|				THEN 0
	|			WHEN ReferencesToShip.AssemblyInProgressBalance <> 0
	|				THEN 1
	|			WHEN ReferencesToShip.AssembledBalance <> 0
	|				THEN 2
	|			WHEN ReferencesToShip.ToRegisterBalance <> 0
	|				THEN 3
	|			ELSE 404
	|		END AS State
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(
	|				&DateOfShipment,
	|				Warehouse = &Warehouse
	|					AND DocumentShipments IN
	|						(SELECT
	|							TransportationTask.ReferenceOrder AS DocumentShipments
	|						FROM
	|							Document.TransportationJob.References AS TransportationTask
	|						WHERE
	|							TransportationTask.Ref = &TransportationJob)) AS ReferencesToShip
	|	WHERE &ConditionGoodsForSelection) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.DocumentShipments,
	|	NestedQuery.Recipient
	|
	|HAVING
	|	CASE
	|		WHEN MIN(NestedQuery.State) = 0
	|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
	|		WHEN MIN(NestedQuery.State) = 1
	|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
	|		WHEN MIN(NestedQuery.State) = 2
	|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
	|		WHEN MIN(NestedQuery.State) = 3
	|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
	|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
	|	END IN (&States1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		WHEN OrdersAndStates.ReferenceOrder REFS Document.MovementOfProductsAndMaterials
	|			THEN PRESENTATION(ISNULL(DocumentsRegistry.BusinessOperation, VALUETYPE(OrdersAndStates.ReferenceOrder)))
	|		ELSE VALUETYPE(OrdersAndStates.ReferenceOrder)
	|	END AS DocumentType,
	|	3 AS PictureIndex,
	|	OrdersAndStates.ReferenceOrder,
	|	&TransportationJob AS TransportationJob,
	|	OrdersAndStates.Recipient,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS Number,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)) AS Date,
	|	OrdersAndStates.State,
	|	1 AS Order
	|FROM
	|	OrdersAndStates AS OrdersAndStates
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON OrdersAndStates.ReferenceOrder = DocumentsRegistry.Ref
	|			AND (NOT DocumentsRegistry.AdditionalRecord)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUETYPE(TransportationJob.Ref),
	|	2,
	|	TransportationJob.Ref,
	|	TransportationJob.Ref,
	|	UNDEFINED,
	|	"""",
	|	DATETIME(1, 1, 1),
	|	VALUE(Enum.GoodsPickingStates.EmptyRef),
	|	0
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Ref = &TransportationJob
	|
	|ORDER BY
	|	Order,
	|	Date";
	
EndProcedure

Function TextOfRequestToFillInTransportationTaskForExpenseOrders()
	
	QueryText =
	"SELECT
	|	TransportationTasks.ReferenceOrder AS ReferenceOrder,
	|	TransportationTasks.Warehouse AS Warehouse,
	|	TransportationTasks.LineNumber AS LineNumber,
	|	TransportationTasks.Weight AS Weight,
	|	TransportationTasks.VolumeM3 AS VolumeM3,
	|	TransportationTasks.DeliveredInFull AS DeliveredInFull,
	|	TransportationTasks.ConnectionKey AS ConnectionKey
	|INTO TransportationTasks
	|FROM
	|	&TransportationTask AS TransportationTasks
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TasksForTransportationRoute.LineNumber AS LineNumber,
	|	TasksForTransportationRoute.ConnectionKey AS ConnectionKey
	|INTO TasksForTransportationRoute
	|FROM
	|	&TaskForTransportationRoute AS TasksForTransportationRoute
	|
	|INDEX BY
	|	ConnectionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsIssueNote.Ref,
	|	GoodsIssueNote.Warehouse
	|INTO OrdersFilter
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Posted
	|	AND GoodsIssueNote.ShipmentUnderTransportationJob
	|	AND GoodsIssueNote.TransportationJob = &Ref
	|
	|INDEX BY
	|	GoodsIssueNote.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods_From_Orders.Products,
	|	Goods_From_Orders.Characteristic,
	|	Goods_From_Orders.Purpose,
	|	Goods_From_Orders.Series,
	|	Goods_From_Orders.ReferenceOrder,
	|	SUM(Goods_From_Orders.Count) AS Count,
	|	OrdersFilter.Warehouse
	|INTO Goods_From_Orders
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS Goods_From_Orders
	|		INNER JOIN OrdersFilter AS OrdersFilter
	|		ON Goods_From_Orders.Ref = OrdersFilter.Ref
	|
	|GROUP BY
	|	Goods_From_Orders.ReferenceOrder,
	|	Goods_From_Orders.Purpose,
	|	Goods_From_Orders.Characteristic,
	|	Goods_From_Orders.Products,
	|	Goods_From_Orders.Series,
	|	OrdersFilter.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder,
	|	OrdersFilter.Warehouse
	|INTO OrdersInOrders
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
	|		INNER JOIN OrdersFilter AS OrdersFilter
	|		ON (OrdersFilter.Ref = GoodsIssueNoteGoodsByReferences.Ref)
	|
	|INDEX BY
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Purpose AS Purpose,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Series AS Series,
	|	GoodsForIssue.Recipient AS Recipient,
	|	GoodsForIssue.ToShipReceipt AS ToShipReceipt,
	|	Goods_From_Orders.ReferenceOrder AS ReferenceOrder,
	|	CASE
	|		WHEN ISNULL(Goods_From_Orders.Count, 0) > GoodsForIssue.ToShipReceipt
	|			THEN GoodsForIssue.ToShipReceipt
	|		ELSE Goods_From_Orders.Count
	|	END AS Count,
	|	CASE
	|		WHEN ISNULL(Goods_From_Orders.Count, 0) > GoodsForIssue.ToShipReceipt
	|			THEN GoodsForIssue.ToShipReceipt * &QueryTextPackageWeight
	|		ELSE Goods_From_Orders.Count * &QueryTextPackageWeight
	|	END AS Weight,
	|	CASE
	|		WHEN ISNULL(Goods_From_Orders.Count, 0) > GoodsForIssue.ToShipReceipt
	|			THEN GoodsForIssue.ToShipReceipt * &QueryTextPackageVolume
	|		ELSE Goods_From_Orders.Count * &QueryTextPackageVolume
	|	END AS VolumeM3
	|INTO GoodsOrdersOnShipment
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(DocumentShipments, Warehouse) IN
	|				(SELECT
	|					OrdersInOrders.ReferenceOrder,
	|					OrdersInOrders.Warehouse
	|				FROM
	|					OrdersInOrders)) AS GoodsForIssue
	|		LEFT JOIN Goods_From_Orders AS Goods_From_Orders
	|		ON GoodsForIssue.DocumentShipments = Goods_From_Orders.ReferenceOrder
	|			AND GoodsForIssue.Warehouse = Goods_From_Orders.Warehouse
	|			AND GoodsForIssue.Products = Goods_From_Orders.Products
	|			AND GoodsForIssue.Characteristic = Goods_From_Orders.Characteristic
	|			AND GoodsForIssue.Purpose = Goods_From_Orders.Purpose
	|			AND GoodsForIssue.Series = Goods_From_Orders.Series
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = GoodsForIssue.Products)
	|WHERE
	|	GoodsForIssue.ToShipReceipt > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsOrdersOnShipment.Warehouse,
	|	GoodsOrdersOnShipment.ReferenceOrder,
	|	GoodsOrdersOnShipment.Recipient,
	|	SUM(GoodsOrdersOnShipment.Weight) AS Weight,
	|	SUM(GoodsOrdersOnShipment.VolumeM3) AS VolumeM3
	|INTO WeightVolumeByOrder
	|FROM
	|	GoodsOrdersOnShipment AS GoodsOrdersOnShipment
	|WHERE
	|	GoodsOrdersOnShipment.Count > 0
	|
	|GROUP BY
	|	GoodsOrdersOnShipment.Warehouse,
	|	GoodsOrdersOnShipment.ReferenceOrder,
	|	GoodsOrdersOnShipment.Recipient" + Common.QueryBatchSeparator();
	
	QueryText = StrReplace(QueryText, "&QueryTextPackageWeight", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("CatalogProducts.UnitOfMeasure", "CatalogProducts"));
	QueryText = StrReplace(QueryText, "&QueryTextPackageVolume", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("CatalogProducts.UnitOfMeasure", "CatalogProducts"));
	
	RequestTextTemplateForOrder =
	"SELECT ALLOWED
	|	DeliveryReferences.Ref AS Ref,
	|	VALUETYPE(DeliveryReferences.Ref) AS ReferenceKind,
	|	DeliveryReferences.Number AS Number,
	|	CASE
	|		WHEN DeliveryReferences.DeliveryMethod = &DeliveryByCarrierToAddress
	|			THEN DeliveryReferences.DeliveryAddressOfCarrier
	|		ELSE DeliveryReferences.DeliveryAddress
	|	END AS DeliveryAddress,
	|	DeliveryReferences.DeliveryMethod AS DeliveryMethod,
	|	DeliveryReferences.DeliveryZone AS DeliveryZone,
	|	DeliveryReferences.CarrierPartner AS CarrierPartner,
	|	CASE
	|		WHEN DeliveryReferences.DeliveryMethod = &DeliveryByCarrierToAddress
	|			THEN DeliveryReferences.DeliveryAddressOfCarrierFieldValues
	|		ELSE DeliveryReferences.DeliveryAddressFieldValues
	|	END AS DeliveryAddressFieldValues,
	|	DeliveryReferences.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DeliveryReferences.DeliveryTimeTo AS DeliveryTimeTo,
	|	DeliveryReferences.AdditionalDeliveryInformation AS AdditionalDeliveryInformation
	|FROM
	|	Document.SalesOrder AS DeliveryReferences
	|		INNER JOIN OrdersInOrders AS OrdersInOrders
	|		ON (OrdersInOrders.ReferenceOrder = DeliveryReferences.Ref)
	|WHERE
	|	DeliveryReferences.DeliveryMethod IN(&TransportMethods)
	|	AND DeliveryReferences.Posted";
	
	ThisIsFirstOne = True;
	
	For Each TypeOfDeliveryOrder In Metadata.DefinedTypes.DeliveryReferenceOrder.Type.Types() Do
		
		// The text of the request is collected according to documents, and not according to the register of
		// the status of the delivery request, in order to support the re-completion of closed tasks,
		// since the register data on orders are cleared after the closure of transportation tasks on these orders.
		If TypeOfDeliveryOrder = Type("CatalogRef.TermsOfPurchaseFromVendors")
			Or TypeOfDeliveryOrder = Type("CatalogRef.CounterpartyContracts") Then
			Continue;
		EndIf;
		
		MetadataOfOrders = Metadata.FindByType(TypeOfDeliveryOrder);
		FullDocumentName = MetadataOfOrders.FullName();
		QueryTextByReference = StrReplace(RequestTextTemplateForOrder, "Document.SalesOrder", FullDocumentName);
		
		If ThisIsFirstOne Then
			QueryTextByReference = StrReplace(QueryTextByReference, "AS AdditionalDeliveryInformation",
				"AS AdditionalDeliveryInformation
				|INTO DeliveryReferences");
			
			ThisIsFirstOne = False;
		Else
			QueryTextByReference = StrReplace(QueryTextByReference, "ALLOWED", "");
			QueryText = QueryText + "
			|
			|UNION ALL
			|";
		EndIf;
		
		If Not Common.HasObjectAttribute("DeliveryAddressOfCarrier", MetadataOfOrders) Then
			// Not all orders contain the full set of delivery details
			QueryTextByReference = StrReplace(QueryTextByReference, "DeliveryAddressOfCarrier", "DeliveryAddress");
			QueryTextByReference = StrReplace(QueryTextByReference, "DeliveryAddressOfCarrierFieldValues", "DeliveryAddressFieldValues");
		EndIf;
		If Not Common.HasObjectAttribute("DeliveryZone", MetadataOfOrders) Then
			QueryTextByReference = StrReplace(QueryTextByReference, "DeliveryReferences.DeliveryZone", "VALUE(Catalog.DeliveryZones.EmptyRef)");
		EndIf;
		If Not Common.HasObjectAttribute("DeliveryTimeFrom", MetadataOfOrders) Then
			QueryTextByReference = StrReplace(QueryTextByReference, "DeliveryReferences.DeliveryTimeFrom", "DATETIME(1,1,1)");
			QueryTextByReference = StrReplace(QueryTextByReference, "DeliveryReferences.DeliveryTimeTo", "DATETIME(1,1,1)");
		EndIf;
		If Not Common.HasObjectAttribute("CarrierPartner", MetadataOfOrders) Then
			QueryTextByReference = StrReplace(QueryTextByReference, "DeliveryReferences.CarrierPartner", "VALUE(Catalog.Partners.EmptyRef)");
		EndIf;
		
		QueryText = QueryText + QueryTextByReference;
		
	EndDo;
	
	QueryText = QueryText + "
	|INDEX BY
	|	DeliveryReferences.Ref" + Common.QueryBatchSeparator() + 
	"SELECT
	|	DeleteInstructions.LineNumber AS LineNumber,
	|	Route.LineNumber AS RouteTheLineNumber
	|FROM
	|	TransportationTasks AS DeleteInstructions
	|		LEFT JOIN WeightVolumeByOrder AS WeightVolumeByOrder
	|		ON DeleteInstructions.ReferenceOrder = WeightVolumeByOrder.ReferenceOrder
	|			AND DeleteInstructions.Warehouse = WeightVolumeByOrder.Warehouse
	|		INNER JOIN TasksForTransportationRoute AS Route
	|		ON (DeleteInstructions.ConnectionKey = Route.ConnectionKey)
	|		INNER JOIN Catalog.Warehouses AS CatalogWarehouses
	|		ON (CatalogWarehouses.Ref = DeleteInstructions.Warehouse)
	|			AND (CatalogWarehouses.UseWarehouseManagemantSystemForGoodsIssue)
	|			AND (&PlanTripStartTime >= CatalogWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue)
	|WHERE
	|	WeightVolumeByOrder.ReferenceOrder IS NULL
	|	AND NOT DeleteInstructions.ReferenceOrder REFS Document.InstructionForShippingAgent
	|
	|GROUP BY
	|	DeleteInstructions.LineNumber,
	|	Route.LineNumber
	|
	|ORDER BY
	|	DeleteInstructions.LineNumber DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeleteRouteLines.LineNumber AS RouteTheLineNumber
	|FROM
	|	TasksForTransportationRoute AS DeleteRouteLines
	|		INNER JOIN TransportationTasks AS TransportationTasks
	|		ON (TransportationTasks.ConnectionKey = DeleteRouteLines.ConnectionKey)
	|		LEFT JOIN WeightVolumeByOrder AS WeightVolumeByOrder
	|		ON (TransportationTasks.ReferenceOrder = WeightVolumeByOrder.ReferenceOrder)
	|			AND (TransportationTasks.Warehouse = WeightVolumeByOrder.Warehouse)
	|		LEFT JOIN Catalog.Warehouses AS CatalogWarehouses
	|		ON (CatalogWarehouses.Ref = TransportationTasks.Warehouse)
	|
	|GROUP BY
	|	DeleteRouteLines.LineNumber
	|
	|HAVING
	|	MAX(CASE
	|			WHEN NOT WeightVolumeByOrder.ReferenceOrder IS NULL 
	|					OR NOT CatalogWarehouses.UseWarehouseManagemantSystemForGoodsIssue
	|					OR &PlanTripStartTime < CatalogWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|					OR TransportationTasks.ReferenceOrder REFS Document.InstructionForShippingAgent
	|				THEN TRUE
	|			ELSE FALSE
	|		END) = FALSE
	|
	|ORDER BY
	|	RouteTheLineNumber DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangeOrders.LineNumber AS LineNumber,
	|	WeightVolumeByOrder.Weight AS Weight,
	|	WeightVolumeByOrder.VolumeM3 AS VolumeM3,
	|	Route.LineNumber AS RouteTheLineNumber
	|FROM
	|	TransportationTasks AS ChangeOrders
	|		INNER JOIN WeightVolumeByOrder AS WeightVolumeByOrder
	|		ON ChangeOrders.ReferenceOrder = WeightVolumeByOrder.ReferenceOrder
	|			AND ChangeOrders.Warehouse = WeightVolumeByOrder.Warehouse
	|		INNER JOIN TasksForTransportationRoute AS Route
	|		ON (Route.ConnectionKey = ChangeOrders.ConnectionKey)
	|WHERE
	|	(WeightVolumeByOrder.Weight <> ChangeOrders.Weight
	|			OR WeightVolumeByOrder.VolumeM3 <> ChangeOrders.VolumeM3)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightVolumeByOrder.Weight AS Weight,
	|	WeightVolumeByOrder.VolumeM3 AS VolumeM3,
	|	WeightVolumeByOrder.Warehouse AS Warehouse,
	|	WeightVolumeByOrder.ReferenceOrder AS ReferenceOrder,
	|	NewOrders.ReferenceKind,
	|	NewOrders.Number,
	|	NewOrders.DeliveryAddress,
	|	NewOrders.DeliveryMethod,
	|	NewOrders.DeliveryZone,
	|	WeightVolumeByOrder.Recipient AS RecipientSender,
	|	NewOrders.CarrierPartner,
	|	NewOrders.DeliveryAddressFieldValues,
	|	NewOrders.DeliveryTimeFrom AS TimeFrom,
	|	NewOrders.DeliveryTimeTo AS TimeTo,
	|	NewOrders.AdditionalDeliveryInformation
	|FROM
	|	DeliveryReferences AS NewOrders
	|		INNER JOIN WeightVolumeByOrder AS WeightVolumeByOrder
	|		ON NewOrders.Ref = WeightVolumeByOrder.ReferenceOrder
	|		LEFT JOIN TransportationTasks AS TransportationTasks
	|		ON (TransportationTasks.ReferenceOrder = WeightVolumeByOrder.ReferenceOrder)
	|			AND (TransportationTasks.Warehouse = WeightVolumeByOrder.Warehouse)
	|WHERE
	|	TransportationTasks.ReferenceOrder IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Recipient AS RecipientSender,
	|	GoodsToDeliver.Products,
	|	GoodsToDeliver.Characteristic,
	|	GoodsToDeliver.Purpose,
	|	GoodsToDeliver.Series,
	|	FALSE AS AllGoods,
	|	GoodsToDeliver.Count
	|FROM
	|	GoodsOrdersOnShipment AS GoodsToDeliver
	|		INNER JOIN WeightVolumeByOrder AS WeightVolumeByOrder
	|		ON (WeightVolumeByOrder.Warehouse = GoodsToDeliver.Warehouse)
	|			AND (WeightVolumeByOrder.ReferenceOrder = GoodsToDeliver.ReferenceOrder)
	|WHERE
	|	GoodsToDeliver.Count > 0";
	
	Return QueryText;
	
EndFunction

Procedure FillInSignsOfExecutionOfOrdersLowerLevel(TreeRowsCollection)
	
	PreviousAddressOrCarrier = Undefined;
	Highlight_1 = 0;
	For Each String In TreeRowsCollection Do
		If (String.OrderingField <> PreviousAddressOrCarrier)
			And (PreviousAddressOrCarrier <> Undefined) Then
			Highlight_1 = Max(Highlight_1-1,-Highlight_1+1);
		EndIf;
		String.RowAppearance = Highlight_1;
		PreviousAddressOrCarrier = String.OrderingField;
	EndDo;
	
EndProcedure

// Returns:
// 	Structure - Where:
// * FieldName - String - field name
// * Value - DefinedType.SenderRecipientOfDelivery
// * Presentation - String - Presentation of the recipient/sender
//
Function RecipientSender(DocObject)
	
	FillType = New Structure("Partner,DestinationWarehouse,Point",0,0,0);
	
	FillPropertyValues(FillType,DocObject);
	If FillType.DestinationWarehouse <> 0 Then
		
		Return New Structure("FieldName, Value, Presentation", "DestinationWarehouse", DocObject.DestinationWarehouse, NStr("vi = 'Kho bãi';
																															|ru = 'Склад';
																															|en = 'Warehouse'; fa = 'Warehouse';
																															|it = 'Склад';
																															|pl = 'Warehouse';
																															|tr = 'Ambar'"));
		
	ElsIf FillType.Point <> 0 Then
		
		Return New Structure("FieldName, Value, Presentation", "Point", DocObject.Point, NStr("vi = 'Địa điểm';
																								|ru = 'Пункт';
																								|en = 'Point'; fa = 'نقطه';
																								|it = 'Пункт';
																								|pl = 'Point';
																								|tr = 'Nokta'"));
		
	ElsIf FillType.Partner <> 0 Then
		
		PartnerPresentation_ = ?(
			GetFunctionalOption("UsePartnersAsCounterparties"),
			NStr("vi = 'Đối tác';
				|ru = 'Контрагент';
				|en = 'Counterparty'; fa = 'طرف حساب';
				|it = 'Контрагент';
				|pl = 'Kontrahent';
				|tr = 'Cari hesap'"),
			NStr("vi = 'Bạn hàng';
				|ru = 'Партнер';
				|en = 'Partner'; fa = 'شریک تجاری';
				|it = 'Партнер';
				|pl = 'Partner';
				|tr = 'İş ortağı'"));
		Return New Structure("FieldName, Value, Presentation", "Partner", DocObject.Partner, PartnerPresentation_);
		
	Else
		
		Raise NStr("vi = 'Chưa xác định người nhận (người gửi).';
					|ru = 'Получатель (отправитель) не определен.';
					|en = 'Recipient (sender) is not determined.'; fa = 'Recipient (sender) is not determined.';
					|it = 'Destinatario (mittente) non indicato.';
					|pl = 'Odbiorca (nadawca) nie jest określony.';
					|tr = 'Alıcı (gönderen) tanımlanmadı.'");
		
	EndIf;
	
EndFunction

Function ElementNameAddress(FormItems)
	
	If FormItems.Find("RecipientDeliveryAddress") <> Undefined Then
		Return "RecipientDeliveryAddress";
	ElsIf FormItems.Find("DeliveryAddress") <> Undefined Then
		Return "DeliveryAddress";
	ElsIf FormItems.Find("SupplierSAddress") <> Undefined Then
		Return "SupplierSAddress";
	ElsIf FormItems.Find("ItemAddress") <> Undefined Then
		Return "ItemAddress";
	Else
		Raise NStr("vi = 'Phần tử địa chỉ không được xác định';
					|ru = 'Элемент адреса не определен';
					|en = 'Address item is not determined'; fa = 'Address item is not determined';
					|it = 'Elemento dell''indirizzo non indicato';
					|pl = 'Element adresu nie jest określony';
					|tr = 'Adres öğesi tanımlanmadı'");
	EndIf;
	
EndFunction

// Fills in the details of the delivery known to the recipient and method of delivery
// 
// Parameters:
//  FormItems - FormAllItems - all form elements for getting / filling in selection lists, managing delivery bookmarks.
//  DocObject - DocumentObject - document-an object whose details are being changed.
//  AdditionalInfoChangedByUser - Boolean -
//
Procedure FillInDetailsOfDeliveryMethod(FormItems, DocObject, AdditionalInfoChangedByUser = False)
	
	EmptyAttributes = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails(DocObject);
	FillPropertyValues(DocObject, EmptyAttributes,
		"DeliveryAddressOfCarrier, DeliveryAddressOfCarrierFieldValues, DeliveryZone, DeliveryTimeFrom, DeliveryTimeTo, Courier");
	
	If Not AdditionalInfoChangedByUser Then
		DocObject.AdditionalDeliveryInformation = "";
	EndIf;
	
	RecipientSender = RecipientSender(DocObject);
	
	If DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrier
		Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress
		Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToOurWarehouse
		Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint Then
			
		If FormItems.Find("CarrierPartner") <> Undefined
			And FormItems.CarrierPartner.ChoiceList.Count() > 0
			And DocObject.CarrierPartner = Catalogs.Partners.EmptyRef() Then
			DocObject.CarrierPartner = FormItems.CarrierPartner.ChoiceList[0].Value;
		EndIf;
		
	Else
		
		DocObject.CarrierPartner = Catalogs.Partners.EmptyRef();
		
	EndIf;
	
	ElementNameAddress = ElementNameAddress(FormItems);
	
	If DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrier Then
		
		If Not AdditionalInfoChangedByUser Then
			
			If ValueIsFilled(DocObject.DeliveryAddress) Then
				NWElementFound = GoodsDeliveryClientServer.FindInListOfStructures(
					FormItems[ElementNameAddress].ChoiceList, "DeliveryAddress", DocObject.DeliveryAddress);
				If Not NWElementFound = Undefined Then
					DocObject.AdditionalDeliveryInformation = NWElementFound.Value.AdditionalDeliveryInformation;
				EndIf;
			EndIf;
			
		EndIf;
		
	ElsIf DocObject.DeliveryMethod = Enums.TransportMethods.ToCustomer
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentFromWarehouse
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentToWarehouse
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentAtPoint 
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.ToCustomerByCourier Then
		
		If ValueIsFilled(DocObject.DeliveryAddress) Then
			NWElementFound = GoodsDeliveryClientServer.FindInListOfStructures(
				FormItems[ElementNameAddress].ChoiceList, "DeliveryAddress", DocObject.DeliveryAddress);
			If Not NWElementFound = Undefined Then
				FillPropertyValues(DocObject, NWElementFound.Value,
					"DeliveryZone, DeliveryTimeFrom, DeliveryTimeTo")
			EndIf;
		EndIf;
		
	ElsIf DocObject.DeliveryMethod = Enums.TransportMethods.OurOwnDeliveryFromSenderAddress
		Or DocObject.DeliveryMethod = Enums.TransportMethods.FromSenderDeterminedByDeliveryService Then
		
		If FormItems.SupplierSAddress.ChoiceList.Count() > 0 Then
			FirstStructureInList = FormItems[ElementNameAddress].ChoiceList[0].Value;
			FillPropertyValues(DocObject,FirstStructureInList,,"AdditionalDeliveryInformation");
			If Not AdditionalInfoChangedByUser Then
				DocObject.AdditionalDeliveryInformation = FirstStructureInList.AdditionalDeliveryInformation;
			EndIf;
		EndIf;
		
	ElsIf Not ValueIsFilled(DocObject.DeliveryMethod)
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.SelfPickup
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.ByVendorToOurWarehouse
		  Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToOurWarehouse Then
		
		DocObject.AdditionalDeliveryInformation = "";
		DocObject.SpecialTransportationConditions = False;
		DocObject.SpecialTransportationConditionsDescription = "";
		
	EndIf;
	
EndProcedure

Procedure FillInCarrierDetails(FormItems, DocObject, AdditionalInfoChangedByUser = False)
	
	EmptyAttributes = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails(DocObject);
	
	FillPropertyValues(DocObject, EmptyAttributes,
		"DeliveryAddressOfCarrier, DeliveryAddressOfCarrierFieldValues, DeliveryZone, DeliveryTimeFrom, DeliveryTimeTo");
	If Not AdditionalInfoChangedByUser Then
		DocObject.AdditionalDeliveryInformation = "";
	EndIf;
	
	If ValueIsFilled(DocObject.CarrierPartner)
			And FormItems.DeliveryAddressOfCarrier.ChoiceList.Count() > 0 Then
		FirstStructureInList = FormItems.DeliveryAddressOfCarrier.ChoiceList[0].Value;
		FillPropertyValues(DocObject,FirstStructureInList,
			"DeliveryZone, DeliveryTimeFrom, DeliveryTimeTo");
		DocObject.DeliveryAddressOfCarrier = FirstStructureInList.DeliveryAddress;
		DocObject.DeliveryAddressOfCarrierFieldValues = FirstStructureInList.DeliveryAddressFieldValues;
		If Not AdditionalInfoChangedByUser Then
			DocObject.AdditionalDeliveryInformation = FirstStructureInList.AdditionalDeliveryInformation;
		EndIf;
	EndIf;
	
EndProcedure

// Updates the selection list for the delivery method selection field when the shipment warehouse changes.
//
// Parameters:
//	FormSelectionField - FormField - the input box delivery time
//	ThereIsSupportForDeliveryByYourOwnCouriers - Boolean
//
Procedure UpdateShippingMethodSelectionListForShippingWarehouse(FormSelectionField, ThereIsSupportForDeliveryByYourOwnCouriers) Export
	
	ChoiceList = FormSelectionField.ChoiceList;
	SoughtValue = ChoiceList.FindByValue(Enums.TransportMethods.ToCustomerByCourier);
	
	If ThereIsSupportForDeliveryByYourOwnCouriers Then
		
		If SoughtValue = Undefined Then
			
			DesiredStartValue = ChoiceList.FindByValue(Enums.TransportMethods.ToCustomer);
			If DesiredStartValue <> Undefined Then
				IndexToInsert = ChoiceList.IndexOf(DesiredStartValue)+1;
				ChoiceList.Insert(IndexToInsert, Enums.TransportMethods.ToCustomerByCourier,
					NStr("vi = 'Đơn vị vận chuyển của chúng ta đến khách hàng';
						|ru = 'Наш курьер до клиента';
						|en = 'In-house carrier'; fa = 'حمل‌کننده داخلی';
						|it = 'Il nostro corriere fino al cliente';
						|pl = 'Nasz kurier do klienta';
						|tr = 'Kuryemiz müşteriye kadar'"));
			Else
				ChoiceList.Add(Enums.TransportMethods.ToCustomerByCourier,
					NStr("vi = 'Đơn vị vận chuyển của chúng ta đến khách hàng';
						|ru = 'Наш курьер до клиента';
						|en = 'In-house carrier'; fa = 'حمل‌کننده داخلی';
						|it = 'Il nostro corriere fino al cliente';
						|pl = 'Nasz kurier do klienta';
						|tr = 'Kuryemiz müşteriye kadar'"));
			EndIf;
			
		EndIf;
		
	ElsIf SoughtValue <> Undefined Then
		
		ChoiceList.Delete(SoughtValue);
		
	EndIf;
	
EndProcedure

// Getting a list of carriers.
//
// Parameters:
//  ListOfCarriers - Array of CatalogRef.Partners - contains carriers
//  RecipientSender - DefinedType.SenderRecipientOfDelivery
//  Warehouse - CatalogRef.Warehouses
//
// Returns:
//  Array of CatalogRef.Partners - contains carriers
//
Function GetListOfCarriers(Val ListOfCarriers, RecipientSender, Warehouse = Undefined)
	
	ThereIsConditionForVVarehouse = Warehouse <> Undefined;
	ThereIsConditionForRecipientSender = RecipientSender <> Undefined;
	DateOfRestriction = AddMonth(CurrentSessionDate(), -12);
	QueryText = CarrierRequestText(ThereIsConditionForVVarehouse, ThereIsConditionForRecipientSender);
	
	Query = New Query(QueryText);
	
	If ThereIsConditionForVVarehouse Then
		Query.SetParameter("Warehouse", Warehouse);
	EndIf;
	
	If ThereIsConditionForRecipientSender Then
		Query.SetParameter("RecipientSender",RecipientSender);
		Query.SetParameter("DateOfRestriction", DateOfRestriction);
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			ListOfCarriers = QueryResult.Unload().UnloadColumn("Carrier");
		EndIf;
	EndIf;
	
	NumberOfCarriers = ListOfCarriers.Count();
	If NumberOfCarriers < 5 Then
		// If the list is incomplete, we will try to supplement it by eliminating the restriction on the recipient.
		QueryText = CarrierRequestText(ThereIsConditionForVVarehouse, False);
		If ThereIsConditionForVVarehouse Then
			Query.SetParameter("Warehouse", Warehouse);
		EndIf;
		Query.SetParameter("DateOfRestriction", DateOfRestriction);
				
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() > 0 Then
			Selection = QueryResult.Select();
			While NumberOfCarriers < 5 Do
				If Selection.Next() Then
					If ListOfCarriers.Find(Selection.Carrier) = Undefined Then
						ListOfCarriers.Add(Selection.Carrier);
						NumberOfCarriers = NumberOfCarriers + 1;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return ListOfCarriers;
	
EndFunction

Function CarrierRequestText(ThereIsConditionForWarehouse, ThereIsConditionForRecipientSender)
	
	QueryText =
	"SELECT ALLOWED TOP 5
	|	T.Carrier AS Carrier,
	|	MAX(T.Date) AS Order_Date
	|FROM
	|	InformationRegister.StatesAndDetailsOfDelivery AS T
	|WHERE
	|	&ConditionByDate
	|	AND &WarehouseCondition
	|	AND &ConditionForRecipientSender
	|	AND T.Carrier <> VALUE(Catalog.Partners.EmptyRef)
	|GROUP BY
	|	T.Carrier
	|ORDER BY
	|	MAX(T.Date) DESC";
	
	If ThereIsConditionForWarehouse Then
		QueryText = StrReplace(QueryText, "&WarehouseCondition", "T.Warehouse = &Warehouse");
	Else
		QueryText = StrReplace(QueryText, "&WarehouseCondition", "True");
	EndIf;
	
	If ThereIsConditionForRecipientSender Then
		QueryText = StrReplace(QueryText, "&ConditionForRecipientSender", "T.RecipientSender = &RecipientSender");
	Else
		QueryText = StrReplace(QueryText, "&ConditionForRecipientSender", "True");
	EndIf;

	QueryText = StrReplace(QueryText, "&ConditionByDate", "T.Date > &DateOfRestriction");
	
	Return QueryText;
	
EndFunction

// Fills in the list of carriers in the form.
//
// Parameters:
//  FormItems		 - FormAllItems	 - all form elements for managing properties and switching bookmarks can contain:
//  							* CarrierPartner - FormField - Required
//  DocObject			 - FormDataStructure	 - object whose details are used when filling in properties,
//  Warehouse				 - CatalogRef.Warehouses
//
Procedure FillInCarrierSelectionList(FormItems, DocObject = Undefined, Warehouse = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If FormItems.Find("CarrierPartner") = Undefined Then
		Return;
	EndIf;
	
	ArrayOfCarriers = FormItems.CarrierPartner.ChoiceList.UnloadValues();
	
	RecipientSender = ?(DocObject <> Undefined,
			RecipientSender(DocObject).Value,
			Undefined);
	
	ArrayOfCarriers = GetListOfCarriers(ArrayOfCarriers, RecipientSender, Warehouse);
	
	FormItems.CarrierPartner.ChoiceList.LoadValues(ArrayOfCarriers);
	
	// Since a selection list is formed based on statistics, the information on the history is redundant, duplicative.
	FormItems.CarrierPartner.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
	
EndProcedure

Procedure FillInCarrierAddressSelectionList(FormItems, DocObject)
	
	SetPrivilegedMode(True);
	
	If FormItems.Find("DeliveryAddressOfCarrier") <> Undefined Then
		ElementNameAddress = "DeliveryAddressOfCarrier";
	Else
		Return;
	EndIf;
	
	CarrierPartner = DocObject.CarrierPartner;
	
	If Not ValueIsFilled(CarrierPartner) Then
		FormItems[ElementNameAddress].ChoiceList.Clear();
		Return;
	EndIf;
	
	ChoiceList = New ValueList;
	
	RecipientSender = RecipientSender(DocObject).Value;
	LastDeliveryDetailsFromTasks = LastDeliveryDetailsFromTasks(RecipientSender,CarrierPartner);
	// We will receive the last used details of the carrier's delivery to the recipient
	AddSelectionListFromAddressTable(ChoiceList, LastDeliveryDetailsFromTasks, NStr("vi = 'Theo thống kê';
																					|ru = 'По статистике';
																					|en = 'By statistics'; fa = 'By statistics';
																					|it = 'По статистике';
																					|pl = 'By statistics';
																					|tr = 'İstatistiğe göre'"));
	
	If ChoiceList.Count() < 3 Then
		LastDeliveryDetailsFromTasks = LastDeliveryDetailsFromTasks(,CarrierPartner);
		// If the list is incomplete, we will try to supplement it by eliminating the restriction on the recipient.
		AddSelectionListFromAddressTable(ChoiceList, LastDeliveryDetailsFromTasks, NStr("vi = 'Theo thống kê';
																						|ru = 'По статистике';
																						|en = 'By statistics'; fa = 'By statistics';
																						|it = 'По статистике';
																						|pl = 'By statistics';
																						|tr = 'İstatistiğe göre'"));
	EndIf;
	
	If ChoiceList.Count() < 5 Then
		LastDeliveryDetailsFromOrders = LastDeliveryDetailsFromOrders(DocObject.Ref, , CarrierPartner);
		AddSelectionListFromAddressTable(ChoiceList, LastDeliveryDetailsFromOrders, NStr("vi = 'Theo thống kê';
																						|ru = 'По статистике';
																						|en = 'By statistics'; fa = 'By statistics';
																						|it = 'По статистике';
																						|pl = 'By statistics';
																						|tr = 'İstatistiğe göre'"));
	EndIf;
	
	RecipientAddressesFromContactInformation = RecipientAddressesFromContactInformation(CarrierPartner);
	AddSelectionListFromAddressTable(ChoiceList, RecipientAddressesFromContactInformation, NStr("vi = 'Người vận chuyển';
																								|ru = 'Перевозчик';
																								|en = 'Carrier'; fa = 'حمل‌کننده';
																								|it = 'Перевозчик';
																								|pl = 'Carrier';
																								|tr = 'Taşıyıcı'"));
	
	CopyValueList(FormItems[ElementNameAddress].ChoiceList, ChoiceList);
	
EndProcedure

Procedure FillInListsForSelectingRecipientSenderAddresses(FormItems, DocObject, OrderUsesDelivery25 = False) Export
	
	SetPrivilegedMode(True);
	
	RecipientSender = RecipientSender(DocObject).Value;
	RecipientSenderPresentation = RecipientSender(DocObject).Presentation;
	
	If Not ValueIsFilled(RecipientSender) Then
		GoodsDeliveryClientServer.ClearRecipientSenderAddressSelectionLists(FormItems);
		Return;
	EndIf;
	
	Date = CurrentSessionDate();
	If CommonClientServer.HasAttributeOrObjectProperty(DocObject, "Date") Then
		Date = DocObject.Date;
	EndIf;
	
	GoodsRecipient = ?(
		CommonClientServer.HasAttributeOrObjectProperty(DocObject, "GoodsRecipient"),
		DocObject.GoodsRecipient,
		Undefined); // DefinedType.ContactInformationOwner
		
	Counterparty = ?(
		CommonClientServer.HasAttributeOrObjectProperty(DocObject, "Counterparty"),
		DocObject.Counterparty,
		Undefined); // DefinedType.ContactInformationOwner
		
	ChoiceList = New ValueList;
	
	If ValueIsFilled(GoodsRecipient) Then
		ConsigneeSAddresses = ContactsManager.ObjectContactInformation(
			GoodsRecipient, Enums.ContactInformationTypes.Address, Date, False);
		ConsigneeSAddresses = DeliveryAddresses_FromContactInformation(ConsigneeSAddresses);
		AddSelectionListFromAddressTable(ChoiceList, ConsigneeSAddresses, NStr("vi = 'Người nhận hàng';
																				|ru = 'Грузополучатель';
																				|en = 'Recipient'; fa = 'گیرنده';
																				|it = 'Грузополучатель';
																				|pl = 'Recipient';
																				|tr = 'Alıcı'"));
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		LastDeliveryDetailsFromTasks = LastDeliveryDetailsFromTasks(RecipientSender);
		AddSelectionListFromAddressTable(ChoiceList, LastDeliveryDetailsFromTasks, NStr("vi = 'Theo thống kê';
																						|ru = 'По статистике';
																						|en = 'By statistics'; fa = 'By statistics';
																						|it = 'По статистике';
																						|pl = 'By statistics';
																						|tr = 'İstatistiğe göre'"));
		
	EndIf;
	
	If Not OrderUsesDelivery25 Then
		
		LastDeliveryDetailsFromOrders = LastDeliveryDetailsFromOrders(
			DocObject.Ref, RecipientSender,, GoodsRecipient);
		AddSelectionListFromAddressTable(ChoiceList, LastDeliveryDetailsFromOrders, NStr("vi = 'Theo thống kê';
																						|ru = 'По статистике';
																						|en = 'By statistics'; fa = 'By statistics';
																						|it = 'По статистике';
																						|pl = 'By statistics';
																						|tr = 'İstatistiğe göre'"));
		
	EndIf;
	
	If (TypeOf(RecipientSender) <> Type("CatalogRef.BusinessStructure")
			And TypeOf(RecipientSender) <> Type("String")) Then
		
		RecipientAddressesFromContactInformation = RecipientAddressesFromContactInformation(RecipientSender);
		AddSelectionListFromAddressTable(ChoiceList, RecipientAddressesFromContactInformation, RecipientSenderPresentation);
		
	EndIf;
	
	If ValueIsFilled(Counterparty) Then
		CounterpartyAddresses = ContactsManager.ObjectContactInformation(
			Counterparty, Enums.ContactInformationTypes.Address, Date, False);
		CounterpartyAddresses = DeliveryAddresses_FromContactInformation(CounterpartyAddresses);
		AddSelectionListFromAddressTable(ChoiceList, CounterpartyAddresses, NStr("vi = 'Đối tác';
																				|ru = 'Контрагент';
																				|en = 'Counterparty'; fa = 'طرف حساب';
																				|it = 'Контрагент';
																				|pl = 'Counterparty';
																				|tr = 'Cari hesap'"));
	EndIf;
	
	If FormItems.Find("DeliveryAddressSelfPickup") <> Undefined Then
		CopyValueList(FormItems.DeliveryAddressSelfPickup.ChoiceList, ChoiceList);
	EndIf;
	If FormItems.Find("RecipientDeliveryAddress") <> Undefined Then
		CopyValueList(FormItems.RecipientDeliveryAddress.ChoiceList, ChoiceList);
	EndIf;
	If FormItems.Find("DeliveryAddress") <> Undefined Then
		CopyValueList(FormItems.DeliveryAddress.ChoiceList, ChoiceList);
	EndIf;
	If FormItems.Find("RecipientDeliveryAddress1") <> Undefined Then
		CopyValueList(FormItems.RecipientDeliveryAddress1.ChoiceList, ChoiceList);
	EndIf;
	If FormItems.Find("RecipientDeliveryAddress2") <> Undefined Then
		CopyValueList(FormItems.RecipientDeliveryAddress2.ChoiceList, ChoiceList);
	EndIf;
	If FormItems.Find("SupplierSAddress") <> Undefined Then
		CopyValueList(FormItems.SupplierSAddress.ChoiceList, ChoiceList);
	EndIf;
	If FormItems.Find("ItemAddress") <> Undefined Then
		CopyValueList(FormItems.ItemAddress.ChoiceList, ChoiceList);
	EndIf;
	
EndProcedure

Procedure AddSelectionListFromAddressTable(ChoiceList, AddressesTable, Source = "")
	
	For Each String In AddressesTable Do
		
		FoundListItem = GoodsDeliveryClientServer.FindInListOfStructures(ChoiceList, "DeliveryAddress", String.DeliveryAddress);
		
		If FoundListItem = Undefined Then
			ChoiceStructure = ChoiceStructure();
			FillPropertyValues(ChoiceStructure, String);
			If ValueIsFilled(Source) And CommonClientServer.HasAttributeOrObjectProperty(String, "Kind") Then
				Presentation =
					StringFunctionsClientServer.SubstituteParametersToString("%1 (%2, %3)", String.DeliveryAddress, String.Kind, Source);
			ElsIf ValueIsFilled(Source) Then
				Presentation =
					StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", String.DeliveryAddress, Source);
			Else
				Presentation = String.DeliveryAddress;
			EndIf;
			ChoiceList.Add(ChoiceStructure, Presentation);
		Else
			RefillEmptyProperties(FoundListItem.Value, String);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure - Selection structure:
// * DeliveryAddress - String - 
// * DeliveryAddressValue - String - 
// * DeliveryAddressFieldValues - String - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryTimeFrom - Date - 
// * DeliveryTimeTo - Date - 
// * AdditionalDeliveryInformation - String -
// 
Function ChoiceStructure()
	
	ChoiceStructure = New Structure;
	ChoiceStructure.Insert("DeliveryAddress", "");
	ChoiceStructure.Insert("DeliveryAddressValue", "");
	ChoiceStructure.Insert("DeliveryAddressFieldValues", "");
	ChoiceStructure.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	ChoiceStructure.Insert("DeliveryTimeFrom", Date(1,1,1));
	ChoiceStructure.Insert("DeliveryTimeTo", Date(1,1,1));
	ChoiceStructure.Insert("AdditionalDeliveryInformation", "");
	
	Return ChoiceStructure;
	
EndFunction

// Initialization of the delivery address table.
// 
// Returns:
//  ValueTable - Table of delivery addresses:
// * DeliveryAddress - String - 
// * Kind - CatalogRef.ContactInformationKinds - 
// * DeliveryAddressValue - String - 
// * DeliveryAddressFieldValues - String - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryTimeFrom - Date - 
// * DeliveryTimeTo - Date -
// * AdditionalDeliveryInformation - String - 
//
Function NewTableOfDeliveryAddresses()
	
	DeliveryAddresses = New ValueTable;
	DeliveryAddresses.Columns.Add("DeliveryAddress", Common.StringTypeDetails(0));
	DeliveryAddresses.Columns.Add("Kind", Common.StringTypeDetails(0));
	DeliveryAddresses.Columns.Add("DeliveryAddressValue", Common.StringTypeDetails(0));
	DeliveryAddresses.Columns.Add("DeliveryAddressFieldValues", Common.StringTypeDetails(0));
	DeliveryAddresses.Columns.Add("DeliveryZone", New TypeDescription("CatalogRef.DeliveryZones"));
	DeliveryAddresses.Columns.Add("DeliveryTimeFrom", Common.DateTypeDetails(DateFractions.Time));
	DeliveryAddresses.Columns.Add("DeliveryTimeTo", Common.DateTypeDetails(DateFractions.Time));
	DeliveryAddresses.Columns.Add("AdditionalDeliveryInformation",  Common.StringTypeDetails(0));
	
	Return DeliveryAddresses;
	
EndFunction

// Delivery addresses from contact information.
// 
// Parameters:
//  ContactInformation - See ContactsManager.NewContactInformation
// 
// Returns:
//  See NewTableOfDeliveryAddresses
//  
Function DeliveryAddresses_FromContactInformation(ContactInformation)
	
	DeliveryAddresses = NewTableOfDeliveryAddresses();
	
	For Each String In ContactInformation Do
		NewRow = DeliveryAddresses.Add();
		NewRow.DeliveryAddress = String.Presentation;
		NewRow.Kind = String.Kind;
		NewRow.DeliveryAddressValue = String.Value;
		NewRow.DeliveryAddressFieldValues = String.FieldValues;
	EndDo;
	
	Return DeliveryAddresses;
	
EndFunction

Function LastDeliveryDetailsFromOrders(
			ObjectRef,
			RecipientSender = Undefined,
			Carrier = Undefined,
			GoodsRecipient = Undefined)
	
	SetPrivilegedMode(True);
	
	ObjectMetadata = ObjectRef.Metadata();
	If TypeOf(ObjectRef) = Type("DocumentRef.InstructionForShippingAgent") Then
		Return LastDetailsOfOrdersToFreightForwarders(RecipientSender)
	EndIf;
	
	RelatedDocuments = New Array; // Array of Array, MetadataObject
	
	DocumentGroup = New Array; // Array of MetadataObject
	DocumentGroup.Add(Metadata.Documents.CustomerInvoice);
	DocumentGroup.Add(Metadata.Documents.SalesOrder);
	DocumentGroup.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	DocumentGroup.Add(Metadata.Documents.TransferOfGoodsToBailee);
	
	RelatedDocuments.Add(DocumentGroup);
	
	DocumentGroup = New Array; // Array of MetadataObject
	DocumentGroup.Add(Metadata.Documents.TransferOrder);
	DocumentGroup.Add(Metadata.Documents.InventoryTransfer);
	
	RelatedDocuments.Add(DocumentGroup);
	
	DocumentGroup = New Array; // Array of MetadataObject
	DocumentGroup.Add(Metadata.Documents.PurchaseOrder);
	DocumentGroup.Add(Metadata.Documents.VendorInvoice);
	DocumentGroup.Add(Metadata.Documents.GoodsReceiptForStorage);
	
	RelatedDocuments.Add(DocumentGroup);
	DocumentGroup = New Array; // Array of MetadataObject
	
	DocumentGroup.Add(Metadata.Documents.SubcontractOrder2_5);
	DocumentGroup.Add(Metadata.Documents.TransferOfGoodsToBailee);
	
	RelatedDocuments.Add(DocumentGroup);
	If TypeOf(ObjectRef) = Type("DocumentRef.GoodsShipmentFromStorage")
			And Common.ObjectAttributeValue(ObjectRef, "BusinessOperation") =
				Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		
		DocumentGroup = New Array; // Array of MetadataObject
		DocumentGroup.Add(Metadata.Documents.MaterialProviderOrder2_5);
		
		RelatedDocuments.Add(DocumentGroup);
		
		ObjectMetadata = Metadata.Documents.MaterialProviderOrder2_5;
		
	EndIf;
	DocumentGroup = New Array; // Array of MetadataObject
	DocumentGroup.Add(ObjectMetadata);
	
	RelatedDocuments.Add(DocumentGroup);
	
	For Each GroupOfRelatedDocuments In RelatedDocuments Do
		
		If GroupOfRelatedDocuments.Find(ObjectMetadata) <> Undefined Then
			CurGroupOfDocuments = GroupOfRelatedDocuments;
			Break;
		EndIf;
		
	EndDo;
	
	QueryTemplate =
	"SELECT TOP 3
	|	CASE WHEN Doc.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN Doc.DeliveryAddressOfCarrier
	|		ELSE Doc.DeliveryAddress
	|	END AS DeliveryAddress,
	|	MAX(Doc.Date) AS Date
	|INTO TT_RecentAddresses
	|FROM
	|	Document.CustomerInvoice AS Doc
	|WHERE
	|	Doc.Posted
	|	AND Doc.Ref <> &Ref
	|	AND Doc.Date > &StartDateOfSample
	|	AND (Doc.Partner = &RecipientSender
	|		OR &RecipientSender = UNDEFINED)
	|	AND (&ConditionForConsignee)
	|	AND (Doc.CarrierPartner = &Carrier
	|			AND Doc.DeliveryAddressOfCarrier <> """"
	|		OR &Carrier = UNDEFINED
	|			AND Doc.DeliveryAddress <> """")
	|	AND Doc.DeliveryMethod <> VALUE(Enum.TransportMethods.ByVendorToOurWarehouse)
	|
	|GROUP BY
	|	CASE WHEN Doc.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN Doc.DeliveryAddressOfCarrier
	|		ELSE Doc.DeliveryAddress
	|	END
	|";
	
	QueryText = "";
		
	For Each MetadataOfDocument In CurGroupOfDocuments Do
		
		TextByDocument = "";
		
		DocumentName = MetadataOfDocument.FullName();
		
		If MetadataOfDocument.Attributes.Find("Partner") <> Undefined Then
			RecipientFieldName = "Partner";
		Else
			RecipientFieldName = "DestinationWarehouse";
		EndIf;
		
		If Common.IsDocument(ObjectMetadata) Then
			NameOfCurrentObjectField = "Doc.Posted";
		Else
			NameOfCurrentObjectField = "NOT Doc.DeletionMark";
		EndIf;
		
		If MetadataOfDocument.Attributes.Find("GoodsRecipient") <> Undefined And ValueIsFilled(GoodsRecipient) Then
			ConditionForConsignee = "Doc.GoodsRecipient = &GoodsRecipient";
		Else
			ConditionForConsignee = "TRUE";
		EndIf;
				
		TextByDocument = StrReplace(QueryTemplate	, "Document.CustomerInvoice"	, DocumentName);
		TextByDocument = StrReplace(TextByDocument	, "Doc.Posted"					, NameOfCurrentObjectField);
		TextByDocument = StrReplace(TextByDocument	, "Doc.Partner"						, "Doc." + RecipientFieldName);
		TextByDocument = StrReplace(TextByDocument	, "&ConditionForConsignee"		, ConditionForConsignee);
		
		If ValueIsFilled(QueryText) Then
			TextByDocument = StrReplace(TextByDocument,"INTO TT_RecentAddresses", "");
			QueryText = QueryText + "
			|
			|UNION ALL
			|" + TextByDocument;
		Else
			QueryText = TextByDocument;
		EndIf;
			
	EndDo;
	
	QueryText = QueryText + "
	|ORDER BY
	|	MAX(Doc.Date) DESC
	|;" + "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	MAX(RecentAddresses.Ref) AS Ref,
	|	RecentAddresses.DeliveryAddress
	|INTO VT_LinksToAddresses
	|FROM #LinkTextByAddress AS RecentAddresses
	|GROUP BY
	|	RecentAddresses.DeliveryAddress
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" +
	"SELECT VT_LinksToAddresses.Ref,VT_LinksToAddresses.Ref.DeliveryMethod,
	|	VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToFinalDestination),
	|	TT_RecentAddresses.DeliveryAddress AS DeliveryAddress,
	|	CASE WHEN VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN VT_LinksToAddresses.Ref.DeliveryAddressOfCarrierValue
	|		ELSE VT_LinksToAddresses.Ref.DeliveryAddressValue
	|	END AS DeliveryAddressValue,
	|	CASE WHEN VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN VT_LinksToAddresses.Ref.DeliveryAddressOfCarrierFieldValues
	|		ELSE VT_LinksToAddresses.Ref.DeliveryAddressFieldValues
	|	END AS DeliveryAddressFieldValues,
	|	VT_LinksToAddresses.Ref.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	CASE WHEN VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToFinalDestination)
	|			AND &Carrier = UNDEFINED
	|		OR VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN VT_LinksToAddresses.Ref.DeliveryZone
	|		ELSE VALUE(Catalog.DeliveryZones.EmptyRef)
	|	END AS DeliveryZone,
	|	CASE WHEN VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToFinalDestination)
	|			AND &Carrier = UNDEFINED
	|		OR VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN VT_LinksToAddresses.Ref.DeliveryTimeFrom
	|		ELSE DATETIME(1,1,1)
	|	END AS DeliveryTimeFrom,
	|	CASE WHEN VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToFinalDestination)
	|			AND &Carrier = UNDEFINED
	|		OR VT_LinksToAddresses.Ref.DeliveryMethod IN (&MethodsOfDeliveryToPlaceOfTransfer)
	|			AND &Carrier <> UNDEFINED
	|		THEN VT_LinksToAddresses.Ref.DeliveryTimeTo
	|		ELSE DATETIME(1,1,1)
	|	END AS DeliveryTimeTo
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN VT_LinksToAddresses AS VT_LinksToAddresses
	|		ON (VT_LinksToAddresses.DeliveryAddress = TT_RecentAddresses.DeliveryAddress)
	|
	|WHERE
	|	(CAST(VT_LinksToAddresses.Ref.DeliveryAddressFieldValues AS STRING(10)) = """"
	|		OR VT_LinksToAddresses.Ref.DeliveryAddressFieldValues LIKE ""%< / Contact information>""
	|	AND CAST(VT_LinksToAddresses.Ref.DeliveryAddressOfCarrierFieldValues AS STRING(10)) = """"
	|		OR VT_LinksToAddresses.Ref.DeliveryAddressOfCarrierFieldValues LIKE ""%< / Contact information>"")
	|	OR
	|	(CAST(VT_LinksToAddresses.Ref.DeliveryAddressFieldValues AS STRING(10)) = """"
	|		OR VT_LinksToAddresses.Ref.DeliveryAddressFieldValues LIKE ""%}""
	|	AND CAST(VT_LinksToAddresses.Ref.DeliveryAddressOfCarrierFieldValues AS STRING(10)) = """"
	|		OR VT_LinksToAddresses.Ref.DeliveryAddressOfCarrierFieldValues LIKE ""%}"")
	|
	|ORDER BY
	|	TT_RecentAddresses.Date DESC";
	
	QueryTemplate =
	"SELECT
	|	Doc.Ref AS Ref,
	|	TT_RecentAddresses.DeliveryAddress AS DeliveryAddress
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN Document.CustomerInvoice AS Doc
	|		ON TT_RecentAddresses.Date = Doc.Date
	|			AND (TT_RecentAddresses.DeliveryAddress = Doc.DeliveryAddress
	|				OR TT_RecentAddresses.DeliveryAddress = Doc.DeliveryAddressOfCarrier)
	|";
	LinkTextByAddress = "";
	For Each MetadataOfDocument In CurGroupOfDocuments Do
		TextByDocument = "";
		DocumentName = MetadataOfDocument.FullName();
		TextByDocument = StrReplace(QueryTemplate,"Document.CustomerInvoice", DocumentName);
		If ValueIsFilled(LinkTextByAddress) Then
			LinkTextByAddress = LinkTextByAddress + "
			|
			|UNION ALL
			|" + TextByDocument;
		Else
			LinkTextByAddress = TextByDocument;
		EndIf;
	EndDo;
	QueryText = StrReplace(QueryText,"#LinkTextByAddress","("+LinkTextByAddress+")");
	
	Query = New Query;
	Query.Text = QueryText;
	
	Date = CurrentSessionDate();
	If Common.IsDocument(ObjectMetadata) And ValueIsFilled(ObjectRef) Then
		Date = Common.ObjectAttributeValue(ObjectRef, "Date");
	EndIf;
	
	Query.SetParameter("Ref", ObjectRef);
	Query.SetParameter("StartDateOfSample", AddMonth(Date, -12));
	Query.SetParameter("RecipientSender",RecipientSender);
	Query.SetParameter("Carrier",Carrier);
	Query.SetParameter("GoodsRecipient", GoodsRecipient);
	
	MethodsOfDeliveryToPlaceOfTransfer = New Array; // Array of EnumRef.TransportMethods
	MethodsOfDeliveryToPlaceOfTransfer.Add(Enums.TransportMethods.ByCarrierToAddress);
	MethodsOfDeliveryToPlaceOfTransfer.Add(Enums.TransportMethods.ByCarrierToTransferPoint);
	Query.SetParameter("MethodsOfDeliveryToPlaceOfTransfer",MethodsOfDeliveryToPlaceOfTransfer);
	
	MethodsOfDeliveryToFinalDestination = New Array; // Array of EnumRef.TransportMethods
	MethodsOfDeliveryToFinalDestination.Add(Enums.TransportMethods.ToCustomer);
	MethodsOfDeliveryToFinalDestination.Add(Enums.TransportMethods.OurOwnDeliveryFromSenderAddress);
	MethodsOfDeliveryToFinalDestination.Add(Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany);
	MethodsOfDeliveryToFinalDestination.Add(Enums.TransportMethods.FromSenderDeterminedByDeliveryService);
	Query.SetParameter("MethodsOfDeliveryToFinalDestination",MethodsOfDeliveryToFinalDestination);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Function LastDetailsOfOrdersToFreightForwarders(RecipientSender)
	
	QueryText =
	"SELECT TOP 3
	|	Doc.DeliveryAddress,
	|	MAX(Doc.Date) AS Date
	|INTO TT_RecentAddresses
	|FROM
	|	Document.InstructionForShippingAgent AS Doc
	|WHERE
	|	Doc.Posted
	|	AND Doc.Point = &RecipientSender
	|
	|GROUP BY
	|	Doc.DeliveryAddress
	|
	|ORDER BY
	|	MAX(Doc.Date) DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Doc.Ref) AS Ref,
	|	TT_RecentAddresses.DeliveryAddress
	|INTO VT_LinksToAddresses
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN Document.InstructionForShippingAgent AS Doc
	|		ON TT_RecentAddresses.Date = Doc.Date
	|			AND TT_RecentAddresses.DeliveryAddress = Doc.DeliveryAddress
	|
	|GROUP BY
	|	TT_RecentAddresses.DeliveryAddress
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RecentAddresses.DeliveryAddress AS DeliveryAddress,
	|	VT_LinksToAddresses.Ref.DeliveryAddressValue AS DeliveryAddressValue,
	|	VT_LinksToAddresses.Ref.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	VT_LinksToAddresses.Ref.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	VT_LinksToAddresses.Ref.DeliveryZone AS DeliveryZone,
	|	VT_LinksToAddresses.Ref.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	VT_LinksToAddresses.Ref.DeliveryTimeTo AS DeliveryTimeTo
	|FROM
	|	TT_RecentAddresses AS TT_RecentAddresses
	|		INNER JOIN VT_LinksToAddresses AS VT_LinksToAddresses
	|		ON (VT_LinksToAddresses.DeliveryAddress = TT_RecentAddresses.DeliveryAddress)
	|
	|ORDER BY
	|	TT_RecentAddresses.Date DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("RecipientSender",RecipientSender);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Function RecipientAddressesFromContactInformation(RecipientSender)
	
	Query = New Query(
		"SELECT
		|	ContactInformation.Presentation AS DeliveryAddress,
		|	ContactInformation.Kind.Presentation AS Kind,
		|	ContactInformation.Value AS DeliveryAddressValue,
		|	ContactInformation.FieldValues AS DeliveryAddressFieldValues,
		|	&DeliveryZone AS DeliveryZone
		|FROM
		|	&CatalogRecipientSenderContactInformation AS ContactInformation
		|WHERE
		|	ContactInformation.Ref = &RecipientSender
		|	AND ContactInformation.Type = VALUE(Enum.ContactInformationTypes.Address)");
		
	Query.Text = StrReplace(Query.Text, "&CatalogRecipientSenderContactInformation", "Catalog." + RecipientSender.Metadata().Name + ".ContactInformation");
	Query.SetParameter("RecipientSender", RecipientSender);
	If TypeOf(RecipientSender) = Type("CatalogRef.Partners") Then
		Query.Text = StrReplace(Query.Text, "&DeliveryZone", "ContactInformation.Ref.DeliveryZone");
	Else	
		Query.SetParameter("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	EndIf;
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

Procedure CopyValueList(DestinationList, SourceList)
	
	DestinationList.Clear();
	For Each Item In SourceList Do
		DestinationList.Add(Item.Value, Item.Presentation);
	EndDo;
	
EndProcedure

Procedure RefillEmptyProperties(ReceiverStructure, Source);
	
	FillingStructure = New Structure;
	For Each Item In ReceiverStructure Do
		If Not ValueIsFilled(Item.Value) Then
			FillingStructure.Insert(Item.Key);
		EndIf;
	EndDo;
	FillPropertyValues(FillingStructure, Source);
	FillPropertyValues(ReceiverStructure, FillingStructure);
	
EndProcedure

Function SetVisibilityOfDeliveryItems(FormItems, DocObject, InvoiceForOrders, AcceptanceParameters = Undefined, ThisIsDeliveryToOurWarehouse = Undefined)
	
	If ThisIsDeliveryToOurWarehouse = Undefined Then
		ThisIsDeliveryToOurWarehouse = GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(DocObject.Ref); 
	EndIf;
	
	If ThisIsDeliveryToOurWarehouse And AcceptanceParameters = Undefined Then
		AcceptanceParameters = GetAcceptanceParameters(DocObject,,InvoiceForOrders);
	EndIf;
	
	VisibilityOfDelivery = False;
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		If ThisIsDeliveryToOurWarehouse Then 
			VisibilityOfDelivery = AcceptanceParameters.ThisIsCounterpartyContract
								Or AcceptanceParameters.AgreementIsOrder
								Or AcceptanceParameters.ContractIsOrder
								Or AcceptanceParameters.ThisIsAdmissionDocument
								Or AcceptanceParameters.ThisIsOrder_;
		Else
			VisibilityOfDelivery = Not InvoiceForOrders 
								Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrier;
		EndIf;
	EndIf;
	
	If TypeOf(DocObject.Ref) = Type("CatalogRef.CounterpartyContracts") Then
		ContractType = DocObject.ContractType;
		UsePurchaseDesign = (ContractType = Enums.ContractTypes.WithVendor
			Or ContractType = Enums.ContractTypes.PurchaseEAEU
			Or ContractType = Enums.ContractTypes.Import);
			
		VisibilityOfDelivery = VisibilityOfDelivery And UsePurchaseDesign;
	EndIf;
	
	If FormItems.Find("DeliveryPage") <> Undefined Then
		FormItems.DeliveryPage.Visible = VisibilityOfDelivery;
		FormItems.DeliveryMethod.ReadOnly = InvoiceForOrders
			And DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrier;
	EndIf;
	
	Return VisibilityOfDelivery;
	
EndFunction

Function ThisIsOrderByAgreement(DocObject, AcceptanceParameters = Undefined)
	
	If GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(DocObject)
			And DocObject.Property("Terms")
			And ValueIsFilled(DocObject.Terms) Then
		
		If AcceptanceParameters = Undefined Then
			
			AcceptanceParameters = GetAcceptanceParameters(DocObject);
			
		EndIf;
		
		Return AcceptanceParameters.AgreementIsOrder And Not AcceptanceParameters.ThisIsAdmissionDocument;
		
	EndIf;
	
	Return False;
	
EndFunction

Function DeliveryIsDefinedInContract(DocObject)
	
	If DocObject = Undefined Then
		Return False;
	EndIf;
	
	ThisIsContract = (TypeOf(DocObject.Ref) = Type("CatalogRef.CounterpartyContracts"));
	
	OrderForDeliveryToOurWarehouse = False;
	
	If TypeOf(DocObject) = Type("FormDataStructure")
		Or TypeOf(DocObject) = Type("Structure") Then
		OrderForDeliveryToOurWarehouse = GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(DocObject)
			And DocObject.Property("Contract")
			And ValueIsFilled(DocObject.Contract);
	Else
		ObjectMetadata = Metadata.FindByType(TypeOf(DocObject.Ref));
		ThereIsContract = Common.HasObjectAttribute("Contract", ObjectMetadata);
		
		OrderForDeliveryToOurWarehouse = 
			(GoodsDeliveryClientServer.ThisIsDeliveryOrderToOurWarehouse(DocObject)
			 And ThisIsContract)
			Or (ThereIsContract
				And ValueIsFilled(DocObject.Contract));
	EndIf;
	
	If OrderForDeliveryToOurWarehouse Then
		
		SetPrivilegedMode(True);
		If ThisIsContract Then
			DeliveryMethod = Common.ObjectAttributeValue(DocObject.Ref, "DeliveryMethod");
		Else
			DeliveryMethod = Common.ObjectAttributeValue(DocObject.Contract, "DeliveryMethod");
		EndIf;
		SetPrivilegedMode(False);
		
		TransportMethods = New Array; // Array of EnumRef.TransportMethods 
		
		If GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers") Then
			TransportMethods.Add(Enums.TransportMethods.ByCarrierToOurWarehouse);
		EndIf;
		
		TransportMethods.Add(Enums.TransportMethods.ByVendorToOurWarehouse);
		TransportMethods.Add(Enums.TransportMethods.ByCarrierToTransferPoint);
		TransportMethods.Add(Enums.TransportMethods.OurOwnDeliveryFromSenderAddress);
		TransportMethods.Add(Enums.TransportMethods.FromSenderDeterminedByDeliveryService);
		
		ShippingIsUsed = TransportMethods.Find(DeliveryMethod) <> Undefined;
		
		Return ShippingIsUsed;
		
	EndIf;
	
	Return False;
	
EndFunction

Function GetContractOrder(ExternalLinks)
	
	ReturnValue = Undefined;
	
	If TMCommonUseClientServer.HasObjectAttribute(ExternalLinks, "Contract")
		And TMCommonUseClientServer.HasObjectAttribute(ExternalLinks, "GoodsReceiptOption") Then
		
		ObjectAttributes = Common.ObjectAttributesValues(ExternalLinks, "Contract, GoodsReceiptOption");
		
		AgreementIsUsedDuringAcceptance = Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(ObjectAttributes.GoodsReceiptOption);
		
		If AgreementIsUsedDuringAcceptance Then
			ReturnValue = ObjectAttributes.Contract;
		EndIf;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

Function GetAcceptanceParameters(ObjectRef, Val GoodsReceiptOption = Undefined, InvoiceForOrders = False)
	
	If Common.IsReference(TypeOf(ObjectRef)) Then
		Ref = ObjectRef;
	Else
		Ref = ObjectRef.Ref;
	EndIf;
	
	RefType = TypeOf(Ref);
	
	If GoodsReceiptOption = Undefined Then
		
		If RefType = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			GoodsReceiptOption = ?(ValueIsFilled(Ref),
				Common.ObjectAttributeValue(Ref, "GoodsReceiptOption"),
				Constants.GoodsReceiptOption.Get());
			
		ElsIf RefType = Type("CatalogRef.CounterpartyContracts") Then
			
			GoodsReceiptOption = ?(ValueIsFilled(Ref),
				Common.ObjectAttributeValue(Ref, "GoodsReceiptOption"),
				Constants.GoodsReceiptOption.Get());
			
		ElsIf RefType = Type("DocumentRef.VendorInvoice")
				And TypeOf(ObjectRef) = Type("FormDataStructure") Then
			
			GoodsReceiptOption = ObjectRef.GoodsReceiptOption;
			InvoiceForOrders = ObjectRef.ReceiptUnderOrders;
			
		ElsIf RefType = Type("DocumentRef.PurchaseOrder")
				And TypeOf(ObjectRef) = Type("FormDataStructure") Then
			
			GoodsReceiptOption = ObjectRef.GoodsReceiptOption;
			InvoiceForOrders = False;
			
		Else
			
			Query = New Query(
			"SELECT
			|	VendorInvoice.GoodsReceiptOption AS GoodsReceiptOption,
			|	VendorInvoice.Ref                AS Ref,
			|	VendorInvoice.ReceiptUnderOrders  AS ReceiptUnderOrders
			|FROM
			|	Document.VendorInvoice AS VendorInvoice
			|WHERE
			|	VendorInvoice.Ref = &Ref
			|
			|UNION ALL
			|
			|SELECT
			|	PurchaseOrder.GoodsReceiptOption         AS GoodsReceiptOption,
			|	PurchaseOrder.Ref                        AS Ref,
			|	FALSE                                          AS ReceiptUnderOrders
			|FROM
			|	Document.PurchaseOrder AS PurchaseOrder
			|WHERE
			|	PurchaseOrder.Ref = &Ref");
			
			Query.SetParameter("Ref", Ref);
			
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
				GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
			Else
				
				Selection = QueryResult.Select();
				Selection.Next();
				GoodsReceiptOption = Selection.GoodsReceiptOption;
				InvoiceForOrders = Selection.ReceiptUnderOrders;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("DocumentInpayment");
	ReturnStructure.Insert("AgreementIsOrder", False);
	ReturnStructure.Insert("ContractIsOrder");
	ReturnStructure.Insert("ThisIsCounterpartyContract", (TypeOf(Ref) = Type("CatalogRef.CounterpartyContracts")));
	ReturnStructure.Insert("ThisIsOrder_", False);
	ReturnStructure.Insert("ThisIsAdmissionDocument", False);
	ReturnStructure.Insert("AgreementWarehouse_");
	
	ReturnStructure.ContractIsOrder    = (Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(GoodsReceiptOption));
	
	Contract = Undefined;
	If RefType = Type("CatalogRef.CounterpartyContracts") Then
		Contract = Ref;
	ElsIf TMCommonUseClientServer.HasObjectAttribute(Ref, "Contract") Then
		Contract = Common.ObjectAttributeValue(Ref, "Contract");
	EndIf;
	
	OrderForAcceptance = Undefined;
	
	If Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(GoodsReceiptOption) Then
		
		If GoodsReceiptOption = PredefinedValue("Enum.GoodsReceiptOptions.NotSeparatedByInvoices") Then
			
			ReturnStructure.DocumentInpayment = Type("CatalogRef.TermsOfPurchaseFromVendors");
			OrderForAcceptance = Type("DocumentRef.VendorInvoice");
			
		ElsIf GoodsReceiptOption = PredefinedValue("Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices") Then
			
			ReturnStructure.DocumentInpayment = Type("CatalogRef.TermsOfPurchaseFromVendors");
			OrderForAcceptance = Type("DocumentRef.PurchaseOrder");
			
		ElsIf GoodsReceiptOption = PredefinedValue("Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed") Then 
			
			ReturnStructure.DocumentInpayment = Type("CatalogRef.TermsOfPurchaseFromVendors");
			OrderForAcceptance = Type("Undefined");
			
		EndIf;
		
		ReturnStructure.AgreementIsOrder = True;
		
	ElsIf Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(GoodsReceiptOption)
		And DeliveryIsDefinedInContract(Contract) Then
		
		If GoodsReceiptOption = PredefinedValue("Enum.GoodsReceiptOptions.ByContractsAfterInvoices") Then
			
			ReturnStructure.DocumentInpayment = Type("CatalogRef.CounterpartyContracts");
			OrderForAcceptance = Type("DocumentRef.VendorInvoice");
			
		ElsIf GoodsReceiptOption = PredefinedValue("Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices") Then
			
			ReturnStructure.DocumentInpayment = Type("CatalogRef.CounterpartyContracts");
			OrderForAcceptance = Type("DocumentRef.PurchaseOrder");
			
		ElsIf GoodsReceiptOption = PredefinedValue("Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices") Then 
			
			ReturnStructure.DocumentInpayment = Type("CatalogRef.CounterpartyContracts");
			OrderForAcceptance = Type("Undefined");
			
		EndIf;
		
	ElsIf PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(GoodsReceiptOption) Then
		
		ReturnStructure.DocumentInpayment = Type("DocumentRef.VendorInvoice");
		OrderForAcceptance = Type("DocumentRef.VendorInvoice");
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.VendorInvoice") And Not InvoiceForOrders Then
		
		ReturnStructure.DocumentInpayment = Type("DocumentRef.VendorInvoice");
		OrderForAcceptance = Type("DocumentRef.VendorInvoice");
		
	ElsIf TypeOf(Ref) = Type("DocumentRef.GoodsReceiptForStorage") And Not InvoiceForOrders Then
		
		ReturnStructure.DocumentInpayment = Type("DocumentRef.GoodsReceiptForStorage");
		OrderForAcceptance = Type("DocumentRef.GoodsReceiptForStorage");
		
	ElsIf PurchasesServer.OrderForAcceptanceOfGoodsOrder(GoodsReceiptOption) Then 
		
		ReturnStructure.DocumentInpayment = Type("DocumentRef.PurchaseOrder");
		OrderForAcceptance = Type("DocumentRef.PurchaseOrder");
		
	Else
		
		ReturnStructure.DocumentInpayment = Type("DocumentRef.PurchaseOrder");
		OrderForAcceptance = Type("DocumentRef.VendorInvoice");
		
	EndIf;
	
	ReturnStructure.ThisIsOrder_ = (RefType = OrderForAcceptance);
	ReturnStructure.ThisIsAdmissionDocument = (RefType = ReturnStructure.DocumentInpayment);
	
	Return ReturnStructure;
	
EndFunction

Function GetPositionToInsert(DeliveryReferences, AreaGroupOrEmpty, SourceRow)
	
	Address = SourceRow.Address;
	CollectionOfOrders = DeliveryReferences.GetItems(); // FormDataTreeItemCollection
	If AreaGroupOrEmpty Then
		For Each LineZone In CollectionOfOrders Do
			If SourceRow.Zone = LineZone.Zone Then
				Branch1 = LineZone.GetItems(); // FormDataTreeItemCollection
				For Each CommandLine_ In Branch1 Do
					If Address < CommandLine_.Address Then
						Return New Structure("Zone, ReferenceOrder", CollectionOfOrders.IndexOf(LineZone), Branch1.IndexOf(CommandLine_));
					EndIf;
				EndDo;
				Return New Structure("Zone, ReferenceOrder", CollectionOfOrders.IndexOf(LineZone), Max(0,Branch1.Count()));
			ElsIf String(SourceRow.Zone) < String(LineZone.Zone) Then
				NewRow = CollectionOfOrders.Insert(CollectionOfOrders.IndexOf(LineZone));
				NewRow.Zone  = SourceRow.Zone;
				NewRow.Address = SourceRow.Zone;
				NewRow.RowAppearance = 5;
				Return New Structure("Zone, ReferenceOrder", CollectionOfOrders.IndexOf(NewRow), 0);
			EndIf;
		EndDo;
		NewRow = CollectionOfOrders.Add();
		NewRow.Zone  = SourceRow.Zone;
		NewRow.Address = SourceRow.Zone;
		NewRow.RowAppearance = 5;
		Return New Structure("Zone, ReferenceOrder", CollectionOfOrders.Count() - 1, 0);
	Else
		For Each CommandLine_ In CollectionOfOrders Do
			If Address < CommandLine_.Address Then
				Return New Structure("Zone, ReferenceOrder", 0, CollectionOfOrders.IndexOf(CommandLine_));
			EndIf;
		EndDo;
		Return New Structure("Zone, ReferenceOrder", 0, CollectionOfOrders.Count());
	EndIf;
	
EndFunction

Procedure RecursivelySetAddressAvailabilityFillTimeLists(FormItems, EditingAllowed)
	
	For Each FormItem In FormItems Do
		
		If TypeOf(FormItem) = Type("FormGroup")
			Or TypeOf(FormItem) = Type("FormTable") Then
			RecursivelySetAddressAvailabilityFillTimeLists(FormItem.ChildItems, EditingAllowed);
		ElsIf TypeOf(FormItem) = Type("FormField")
			And FormItem.Type = FormFieldType.InputField Then
			TagName = Upper(FormItem.Name);
			If Not EditingAllowed
				And StrFind(TagName, "ADDRESS") > 0
				And TagName <> "DELIVERYADDRESSFORVENDOR" Then
				FormItem.TextEdit = False;
				FormItem.ClearButton = True;
			EndIf;
			If StrFind(TagName, "TIMEOFDELIVERY") > 0 Then
				GoodsDeliveryClientServer.FillTimeFieldSelectionList(FormItem);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Function DeliveryDetails_(DocObject)
	
	RecipientSender = RecipientSender(DocObject);
	DeliveryDetails_ = GoodsDeliveryClientServer.GetEmptyStructureOfDeliveryDetails(
		DocObject,
		GoodsDeliveryClientServer.UsedDelivery20());
	DeliveryDetails_.Insert(RecipientSender.FieldName, RecipientSender.Value);
	DeliveryDetails_.Insert("Ref");
	DeliveryDetails_.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	DeliveryDetails_.Insert("GoodsRecipient", Catalogs.Counterparties.EmptyRef());
	FillPropertyValues(DeliveryDetails_, DocObject);
	DeliveryDetails_.Insert("RecipientSender", RecipientSender);
	
	Return DeliveryDetails_;
	
EndFunction

// Re-fills in the delivery details when the form details are changed
// Parameters:
//		FormItems - FormAllItems - all elements of the form where changes are made,
//		DocObject - FormDataStructure - the object whose details are used for filling in.
//
Procedure WhenChangingCarrier(FormItems, DocObject)
	
	If Not GoodsDeliveryClientServer.UsedDelivery20() Then
		Return;
	EndIf;
	
	If (DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress
			Or DocObject.DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint) Then
		
		AdditionalInfoChangedByUser = GoodsDeliveryClientServer.AdditionalInfoChangedByUser(FormItems, DocObject);
		FillInCarrierAddressSelectionList(FormItems, DocObject);
		FillInCarrierDetails(FormItems, DocObject, AdditionalInfoChangedByUser);
		
	EndIf;
	
EndProcedure

Function SupplementTextWithOrderAndAddInfo(Val AddInfoModifiable, AdditionalInfoToAdd, ReferenceOrder)
	
	Result = AddInfoModifiable;
	
	If Not IsBlankString(AdditionalInfoToAdd) Then
		
		Attributes = Common.ObjectAttributesValues(ReferenceOrder, "Number, Date");
		AdditionalInfoText = NStr("vi = '%ReferenceOrder% %Number% ngày %Date%: %AddlInfo%';
									|ru = '%ReferenceOrder% %Number% от %Date%: %AddlInfo%';
									|en = '%ReferenceOrder% %Number% dated %Date%: %AddlInfo%'; fa = '%ReferenceOrder% %Number% dated %Date%: %AddlInfo%';
									|it = '%ReferenceOrder% %Number% di %Date%: %AddlInfo%';
									|pl = '%ReferenceOrder% %Number% z dn. %Date%: %AddlInfo%';
									|tr = '%ReferenceOrder% %Number% %Date% itibaren: %AddlInfo%'");
		
		AdditionalInfoText = StrReplace(AdditionalInfoText,"%ReferenceOrder%",String(TypeOf(ReferenceOrder)));
		AdditionalInfoText = StrReplace(AdditionalInfoText,"%Number%",
			ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		AdditionalInfoText = StrReplace(AdditionalInfoText, "%Date%", Format(Attributes.Date,"DF=MM/dd/yy"));
		AdditionalInfoText = StrReplace(AdditionalInfoText, "%AddlInfo%", AdditionalInfoToAdd);
		
		If StrFind(AddInfoModifiable, AdditionalInfoText) = 0 Then
			Result = Result + ?(ValueIsFilled(Result), Chars.LF, "") + AdditionalInfoText;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure SpecialConditionsOfCarriageAndAccessibility(FormItems, DocObject)
	
	If FormItems.Find("SpecialTransportationConditionsDescription") = Undefined Then
		Return;
	EndIf;
	
	SpecialTransportationConditions = DocObject.SpecialTransportationConditions;
	FormItems.SpecialTransportationConditionsDescription.Enabled = SpecialTransportationConditions;
	If FormItems.Find("SpecialTransportationConditionsDescription1") <> Undefined Then
		FormItems.SpecialTransportationConditionsDescription1.Enabled = SpecialTransportationConditions;
	EndIf;
	If FormItems.Find("SpecialTransportationConditionsDescription2") <> Undefined Then
		FormItems.SpecialTransportationConditionsDescription2.Enabled = SpecialTransportationConditions;
	EndIf;
	If FormItems.Find("SpecialConditionsOfCarriageDescriptionDeliveryByCarrier") <> Undefined Then
		FormItems.SpecialConditionsOfCarriageDescriptionDeliveryByCarrier.Enabled = SpecialTransportationConditions;
	EndIf;
	
EndProcedure

Function QueryTextDeliveryReferences(SelectiveUpdating, ThereIsOrderWarehouse, ThereIsNonOrderWarehouse, DeliveryToRecipients)
	
	If SelectiveUpdating Then
		QueryText = 
		"SELECT
		|	UpdatedOrders.ReferenceOrder,
		|	UpdatedOrders.Warehouse
		|INTO UpdatedOrders
		|FROM
		|	&UpdatedOrders AS UpdatedOrders";
	Else
		QueryText = 
		"SELECT
		|	UNDEFINED AS ReferenceOrder,
		|	UNDEFINED AS Warehouse
		|INTO UpdatedOrders";
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() +
		TTDeliveryRequestText(DeliveryToRecipients);
	
	PatternSamplingMovesToDistribution = ?(DeliveryToRecipients,
		"SELECT
		|	SourceTables_.Warehouse                  AS Warehouse,
		|	SourceTables_.ReferenceOrder           AS ReferenceOrder,
		|	SourceTables_.RecipientSender  AS RecipientSender,
		|	SourceTables_.DeliveryMethod         AS DeliveryMethod,
		|	SourceTables_.Zone                   AS Zone,
		|	SourceTables_.Carrier             AS Carrier,
		|	SourceTables_.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	SourceTables_.Products           AS Products,
		|	SourceTables_.Characteristic         AS Characteristic,
		|	SourceTables_.Purpose             AS Purpose,
		|	SourceTables_.Series                  AS Series,
		|	SourceTables_.Count             AS Count
		|FROM
		|	SourceTableName AS SourceTables_",
		"SELECT
		|	SourceTables_.Period         AS Period,
		|	SourceTables_.ReferenceOrder   AS ReferenceOrder,
		|	SourceTables_.Products   AS Products,
		|	SourceTables_.Characteristic AS Characteristic,
		|	SourceTables_.Purpose     AS Purpose,
		|	SourceTables_.Warehouse          AS Warehouse,
		|	SourceTables_.Count     AS Count,
		|	SourceTables_.Weight            AS Weight,
		|	SourceTables_.VolumeM3          AS VolumeM3
		|FROM
		|	SourceTableName AS SourceTables_");
	
	TemplateSelectionOfOrders = 
	"SELECT
	|	SourceTables_.Date                   AS Date,
	|	SourceTables_.Products           AS Products,
	|	SourceTables_.DimensionalUnitOfMeasurement AS DimensionalUnitOfMeasurement,
	|	SourceTables_.Characteristic         AS Characteristic,
	|	SourceTables_.Purpose             AS Purpose,
	|	SourceTables_.Series                  AS Series,
	|	SourceTables_.Count             AS Count,
	|	SourceTables_.Weight                    AS Weight,
	|	SourceTables_.VolumeM3                  AS VolumeM3,
	|	SourceTables_.Warehouse                  AS Warehouse,
	|	SourceTables_.ReferenceOrder           AS ReferenceOrder,
	|	SourceTables_.RecipientSender  AS RecipientSender,
	|	SourceTables_.ReferenceKind        AS ReferenceKind,
	|	SourceTables_.Number                  AS Number,
	|	SourceTables_.Address                  AS Address,
	|	SourceTables_.FieldValueAddress     AS FieldValueAddress,
	|	SourceTables_.DeliveryMethod         AS DeliveryMethod,
	|	SourceTables_.Picture               AS Picture,
	|	SourceTables_.Zone                   AS Zone,
	|	SourceTables_.ZonePresentation      AS ZonePresentation,
	|	SourceTables_.Carrier             AS Carrier,
	|	SourceTables_.TimeFrom                 AS TimeFrom,
	|	SourceTables_.TimeTo                AS TimeTo,
	|	SourceTables_.AdditionalInformation AS AdditionalInformation,
	|	SourceTables_.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	SourceTables_.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	SourceTables_.OrderField     AS OrderField
	|FROM
	|	SourceTableName AS SourceTables_";
	
	TextSourcesOfRegisteredRecordsToDistribution = "";
	TextSourcesOfOrders = "";
	
	If ThereIsOrderWarehouse Then
		
		QueryText = QueryText
			+ Common.QueryBatchSeparator()
			+ ?(DeliveryToRecipients,
				TextOfRequestOrderForDeliveryToRecipientsAccordingToOrderScheme(),
				TextOfRequestOrderForDeliveryFromSendersAccordingToOrderScheme());
		
		NameOfTableToDistribution = "TtOfMovementToDistributionAccordingToOrderScheme";
		OrderTableName = ?(DeliveryToRecipients,
			"TTOrdersForDeliveryToRecipientsAccordingToOrderScheme",
			"TTOrdersForDeliveryFromSendersAccordingToOrderScheme");
		
		TextSourceOfRegisteredRecordsToDistribution = StrReplace(PatternSamplingMovesToDistribution,
			"SourceTableName",
			NameOfTableToDistribution);
		TextSourceOfOrders = StrReplace(TemplateSelectionOfOrders,
			"SourceTableName",
			OrderTableName);
		
		TextSourcesOfRegisteredRecordsToDistribution = TextSourceOfRegisteredRecordsToDistribution;
		TextSourcesOfOrders = TextSourceOfOrders;
		
	EndIf;
	
	If ThereIsNonOrderWarehouse Then
		QueryText = QueryText
			+ Common.QueryBatchSeparator()
			+ ?(DeliveryToRecipients,
				TextOfRequestOrderForDeliveryToRecipientsWithoutOrderScheme(),
				TextOfRequestOrderForDeliveryFromSendersWithoutOrderScheme());
		
		NameOfTableToDistribution = "TTMovesToDistributionWithoutOrderScheme";
		OrderTableName = ?(DeliveryToRecipients,
			"TTOrdersForDeliveryToRecipientsWithoutOrderScheme",
			"TTDeliveryOrdersFromSendersWithoutOrderScheme");
		
		TextSourceOfRegisteredRecordsToDistribution = StrReplace(PatternSamplingMovesToDistribution,
			"SourceTableName",
			NameOfTableToDistribution);
		TextSourceOfOrders = StrReplace(TemplateSelectionOfOrders,
			"SourceTableName",
			OrderTableName);
		
		TextSourcesOfRegisteredRecordsToDistribution = ?(IsBlankString(TextSourcesOfRegisteredRecordsToDistribution),
			TextSourceOfRegisteredRecordsToDistribution,
			TextSourcesOfRegisteredRecordsToDistribution
			+ "
			|UNION ALL
			|
			|"
			+ TextSourceOfRegisteredRecordsToDistribution);
			
		TextSourcesOfOrders = ?(IsBlankString(TextSourcesOfOrders),
			TextSourceOfOrders,
			TextSourcesOfOrders
			+ "
			|UNION ALL
			|
			|"
			+ TextSourceOfOrders);
		
	EndIf;
	
	TextOfExcludedOrders =
		"
		|		LEFT JOIN InformationRegister.GoodsToDeliver AS TableOfExcludedOrders
		|		ON TableOfExcludedOrders.TransportationJob = VALUE(Document.TransportationJob.EmptyRef)
		|			AND SourceTables_.Warehouse = TableOfExcludedOrders.Warehouse
		|			AND SourceTables_.ReferenceOrder = TableOfExcludedOrders.ReferenceOrder
		|			AND SourceTables_.Products = TableOfExcludedOrders.Products
		|			AND SourceTables_.Characteristic = TableOfExcludedOrders.Characteristic
		|			AND SourceTables_.Purpose = TableOfExcludedOrders.Purpose
		|			AND &BatchConditions
		|
		|WHERE
		|	TableOfExcludedOrders.TransportationJob IS NULL";
		
	If DeliveryToRecipients Then
		BatchConditions = "SourceTables_.Series = TableOfExcludedOrders.Series";
	Else
		BatchConditions = "TRUE";
	EndIf;
	
	TextOfExcludedOrders = StrReplace(TextOfExcludedOrders,
		"&BatchConditions",
		BatchConditions);
	
	FinalQueryTextSelectionOfRegisteredRecordsForDistribution = 
		StrReplace(PatternSamplingMovesToDistribution,
			"SourceTableName",
			"("
			+ TextSourcesOfRegisteredRecordsToDistribution
			+ ")");
	
	FinalQueryTextSelectionOfRegisteredRecordsForDistribution = FinalQueryTextSelectionOfRegisteredRecordsForDistribution
		+ TextOfExcludedOrders;
	
	If Not DeliveryToRecipients Then
		FinalQueryTextSelectionOfRegisteredRecordsForDistribution = FinalQueryTextSelectionOfRegisteredRecordsForDistribution
			+
			"
			|ORDER BY
			|	SourceTables_.Period";
	EndIf;
	
	FinalRequestTextOrderSources = 
		StrReplace(TemplateSelectionOfOrders,
			"SourceTableName",
			"("
			+ TextSourcesOfOrders
			+ ")");
	
	FinalRequestTextOrderSources = FinalRequestTextOrderSources
		+ TextOfExcludedOrders;
	
	QueryTextOrdering = "";
	If Not DeliveryToRecipients
		And ThereIsOrderWarehouse Then
		QueryTextOrdering = 
		"
		|ORDER BY
		|	SourceTables_.ZonePresentation,
		|	SourceTables_.Zone,
		|	SourceTables_.ReferenceOrder,
		|	SourceTables_.Warehouse,
		|	SourceTables_.Products,
		|	SourceTables_.Characteristic,
		|	SourceTables_.Purpose,
		|	SourceTables_.Series,
		|	SourceTables_.Date";
	Else
		QueryTextOrdering = 
		"
		|ORDER BY
		|	SourceTables_.ZonePresentation,
		|	SourceTables_.Zone,
		|	SourceTables_.OrderField,
		|	SourceTables_.RecipientSender,
		|	SourceTables_.ReferenceOrder,
		|	SourceTables_.Warehouse,
		|	SourceTables_.Products,
		|	SourceTables_.Characteristic,
		|	SourceTables_.Purpose,
		|	SourceTables_.Series,
		|	SourceTables_.Date";
	EndIf;
	
	FinalRequestTextOrderSources = FinalRequestTextOrderSources
		+ QueryTextOrdering;
	
	QueryText = QueryText
		+ Common.QueryBatchSeparator()
		+ FinalQueryTextSelectionOfRegisteredRecordsForDistribution
		+ Common.QueryBatchSeparator()
		+ FinalRequestTextOrderSources;
		
	If Not SelectiveUpdating Then
		QueryText = StrReplace(QueryText,
		"INNER JOIN UpdatedOrders",
		"LEFT JOIN UpdatedOrders");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&QueryTextPackageWeight", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("CatalogProducts.UnitOfMeasure", "CatalogProducts"));
	QueryText = StrReplace(QueryText, "&QueryTextPackageVolume", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("CatalogProducts.UnitOfMeasure", "CatalogProducts"));
	
	Return QueryText;
	
EndFunction

Function TTDeliveryRequestText(DeliveryToRecipients)
	
	QueryText = "";
	
	If DeliveryToRecipients Then
		QueryText = 
		"SELECT ALLOWED
		|	DeliveryReferences.ReferenceOrder AS ReferenceOrder,
		|	DeliveryReferences.Warehouse AS Warehouse,
		|	(DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|		AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentSessionDate) AS ThisIsOrderWarehouse,
		|	DeliveryReferences.RecipientSender,
		|	DeliveryReferences.DeliveryMethod,
		|	DeliveryReferences.Zone,
		|	DeliveryReferences.Carrier,
		|	DeliveryReferences.Date,
		|	DeliveryReferences.SpecialTransportationConditions
		|INTO DeliveryReferences
		|FROM
		|	InformationRegister.StatesAndDetailsOfDelivery AS DeliveryReferences
		|		LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
		|		ON (GoodsToDeliver.ReferenceOrder = DeliveryReferences.ReferenceOrder)
		|			AND (GoodsToDeliver.Warehouse = DeliveryReferences.Warehouse)
		|			AND (GoodsToDeliver.AllGoods)
		|		INNER JOIN UpdatedOrders AS UpdatedOrders
		|		ON DeliveryReferences.ReferenceOrder = UpdatedOrders.ReferenceOrder
		|			AND DeliveryReferences.Warehouse = UpdatedOrders.Warehouse
		|WHERE
		|	(GoodsToDeliver.ReferenceOrder IS NULL
		|			OR GoodsToDeliver.TransportationJob = &TaskForTransportationSelection
		|			OR GoodsToDeliver.TransportationJob.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
		|			OR NOT GoodsToDeliver.TransportationJob.Posted)
		|	AND DeliveryReferences.State = VALUE(Enum.DeliveryStates.DeliveryIsRequired)
		|	AND CASE
		|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.OurTransportationService)
		|				THEN DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByOurForcesToRecipient)
		|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|				THEN DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByCarrierToRecipient)
		|			ELSE DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByOurForcesToRecipient)
		|					OR DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByCarrierToRecipient)
		|		END
		|	AND (&NoZoneSelection
		|			OR DeliveryReferences.Zone IN HIERARCHY (&Zone))
		|	AND (DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint)
		|			OR DeliveryReferences.Warehouse IN HIERARCHY (&Warehouse))
		|
		|UNION ALL
		|
		|SELECT
		|	DeliveryReferences.ReferenceOrder,
		|	DeliveryReferences.Warehouse,
		|	(DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|		AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentSessionDate) AS ThisIsOrderWarehouse,
		|	DeliveryReferences.RecipientSender,
		|	DeliveryReferences.DeliveryMethod,
		|	DeliveryReferences.Zone,
		|	DeliveryReferences.Carrier,
		|	DeliveryReferences.Date,
		|	DeliveryReferences.SpecialTransportationConditions
		|FROM
		|	InformationRegister.StatesAndDetailsOfDelivery AS DeliveryReferences
		|		INNER JOIN Document.TransportationJob.References AS OrdersTasks
		|		ON (OrdersTasks.ReferenceOrder = DeliveryReferences.ReferenceOrder)
		|			AND (OrdersTasks.Warehouse = DeliveryReferences.Warehouse)
		|			AND (OrdersTasks.Ref = &TaskForTransportationSelection)
		|			AND (DeliveryReferences.State <> VALUE(Enum.DeliveryStates.DeliveryIsRequired))
		|WHERE
		|	(&NoZoneSelection
		|			OR DeliveryReferences.Zone IN HIERARCHY (&Zone))
		|	AND (DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint)
		|			OR DeliveryReferences.Warehouse IN HIERARCHY (&Warehouse))
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Warehouse";
	Else
		QueryText = 
		"SELECT ALLOWED
		|	DeliveryReferences.ReferenceOrder AS ReferenceOrder,
		|	DeliveryReferences.Warehouse AS Warehouse,
		|	(DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentSessionDate) AS ThisIsOrderWarehouse,
		|	DeliveryReferences.RecipientSender,
		|	VALUETYPE(DeliveryReferences.ReferenceOrder) AS ReferenceKind,
		|	DeliveryReferences.Number AS Number,
		|	DeliveryReferences.Date AS Date,
		|	DeliveryReferences.Address AS Address,
		|	DeliveryReferences.FieldValueAddress AS FieldValueAddress,
		|	DeliveryReferences.DeliveryMethod AS DeliveryMethod,
		|	DeliveryReferences.Zone AS Zone,
		|	DeliveryReferences.Carrier AS Carrier,
		|	DeliveryReferences.TimeFrom AS TimeFrom,
		|	DeliveryReferences.TimeTo AS TimeTo,
		|	DeliveryReferences.AdditionalInformation AS AdditionalInformation,
		|	DeliveryReferences.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	DeliveryReferences.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
		|	CASE
		|		WHEN DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse)
		|			THEN PRESENTATION(DeliveryReferences.Carrier)
		|		ELSE DeliveryReferences.Address
		|	END AS OrderingField
		|INTO DeliveryReferences
		|FROM
		|	InformationRegister.StatesAndDetailsOfDelivery AS DeliveryReferences
		|		LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
		|		ON (GoodsToDeliver.ReferenceOrder = DeliveryReferences.ReferenceOrder)
		|			AND (GoodsToDeliver.Warehouse = DeliveryReferences.Warehouse)
		|			AND (GoodsToDeliver.AllGoods)
		|		INNER JOIN UpdatedOrders AS UpdatedOrders
		|		ON DeliveryReferences.ReferenceOrder = UpdatedOrders.ReferenceOrder
		|			AND DeliveryReferences.Warehouse = UpdatedOrders.Warehouse
		|WHERE
		|	(GoodsToDeliver.ReferenceOrder IS NULL
		|			OR GoodsToDeliver.TransportationJob = &TaskForTransportationSelection
		|			OR NOT GoodsToDeliver.TransportationJob.Posted)
		|	AND DeliveryReferences.State = VALUE(Enum.DeliveryStates.DeliveryIsRequired)
		|	AND CASE
		|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.OurTransportationService)
		|				THEN DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByOurForcesFromSender)
		|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|				THEN DeliveryReferences.DeliveryMethod IN (&ShippingMethodsByCarrierFromSender)
		|			ELSE DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByOurForcesFromSender)
		|					OR DeliveryReferences.DeliveryMethod IN (&ShippingMethodsByCarrierFromSender)
		|		END
		|	AND (&NoZoneSelection
		|			OR DeliveryReferences.Zone IN HIERARCHY (&Zone))
		|	AND (DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint)
		|			OR DeliveryReferences.Warehouse IN HIERARCHY (&Warehouse))
		|	AND (NOT (DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|			AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentSessionDate)
		|		OR (NOT DeliveryReferences.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
		|			 AND NOT DeliveryReferences.ReferenceOrder REFS Catalog.CounterpartyContracts)
		|		)
		|
		|UNION ALL
		|
		|SELECT
		|	DeliveryReferences.ReferenceOrder AS ReferenceOrder,
		|	DeliveryReferences.Warehouse AS Warehouse,
		|	(DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentSessionDate) AS ThisIsOrderWarehouse,
		|	DeliveryReferences.RecipientSender,
		|	VALUETYPE(DeliveryReferences.ReferenceOrder) AS ReferenceKind,
		|	DeliveryReferences.Number,
		|	DeliveryReferences.Date,
		|	DeliveryReferences.Address,
		|	DeliveryReferences.FieldValueAddress,
		|	DeliveryReferences.DeliveryMethod,
		|	DeliveryReferences.Zone,
		|	DeliveryReferences.Carrier,
		|	DeliveryReferences.TimeFrom,
		|	DeliveryReferences.TimeTo,
		|	DeliveryReferences.AdditionalInformation,
		|	DeliveryReferences.SpecialTransportationConditions,
		|	DeliveryReferences.SpecialTransportationConditionsDescription,
		|	CASE
		|		WHEN DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse)
		|			THEN PRESENTATION(DeliveryReferences.Carrier)
		|		ELSE DeliveryReferences.Address
		|	END
		|FROM
		|	InformationRegister.StatesAndDetailsOfDelivery AS DeliveryReferences
		|		INNER JOIN Document.TransportationJob.References AS OrdersTasks
		|		ON (OrdersTasks.ReferenceOrder = DeliveryReferences.ReferenceOrder)
		|			AND (OrdersTasks.Warehouse = DeliveryReferences.Warehouse)
		|			AND (OrdersTasks.Ref = &TaskForTransportationSelection)
		|			AND (DeliveryReferences.State <> VALUE(Enum.DeliveryStates.DeliveryIsRequired))
		|WHERE
		|	(&NoZoneSelection
		|			OR DeliveryReferences.Zone IN HIERARCHY (&Zone))
		|	AND (DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint)
		|			OR DeliveryReferences.Warehouse IN HIERARCHY (&Warehouse))
		|	AND (NOT (DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|			AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentSessionDate)
		|		OR (NOT DeliveryReferences.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
		|			 AND NOT DeliveryReferences.ReferenceOrder REFS Catalog.CounterpartyContracts)
		|		)
		|
		|UNION ALL
		|
		|SELECT
		|	DeliveryReferences.ReferenceOrder,
		|	DeliveryReferences.Warehouse,
		|	(DeliveryReferences.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND DeliveryReferences.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentSessionDate) AS ThisIsOrderWarehouse,
		|	DeliveryReferences.RecipientSender,
		|	VALUETYPE(DeliveryReferences.ReferenceOrder) AS ReferenceKind,
		|	NULL AS Number,
		|	DeliveryReferences.Date,
		|	NULL AS Address,
		|	NULL AS FieldValueAddress,
		|	DeliveryReferences.DeliveryMethod,
		|	DeliveryReferences.Zone,
		|	DeliveryReferences.Carrier,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL
		|FROM
		|	InformationRegister.StatesAndDetailsOfDelivery AS DeliveryReferences
		|		INNER JOIN UpdatedOrders AS UpdatedOrders
		|		ON DeliveryReferences.ReferenceOrder = UpdatedOrders.ReferenceOrder
		|			AND DeliveryReferences.Warehouse = UpdatedOrders.Warehouse
		|WHERE
		|	CASE
		|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.OurTransportationService)
		|				THEN DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByOurForcesFromSender)
		|			WHEN &FilterByAssigneeType = VALUE(Enum.TypesOfTransportationJobAssignees.Carrier)
		|				THEN DeliveryReferences.DeliveryMethod IN (&ShippingMethodsByCarrierFromSender)
		|			ELSE DeliveryReferences.DeliveryMethod IN (&MethodsOfDeliveryByOurForcesFromSender)
		|					OR DeliveryReferences.DeliveryMethod IN (&ShippingMethodsByCarrierFromSender)
		|		END
		|	AND (&NoZoneSelection
		|			OR DeliveryReferences.Zone IN HIERARCHY (&Zone))
		|	AND (DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint)
		|			OR DeliveryReferences.Warehouse IN HIERARCHY (&Warehouse))
		|	AND (DeliveryReferences.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
		|		OR DeliveryReferences.ReferenceOrder REFS Catalog.CounterpartyContracts)
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Warehouse";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextOfRequestOrderForDeliveryToRecipientsAccordingToOrderScheme()
	
	QueryText =
	"SELECT ALLOWED
	|	PartiallyDeliveredOrders.Warehouse             AS Warehouse,
	|	PartiallyDeliveredOrders.ReferenceOrder      AS ReferenceOrder,
	|	DeliveryReferences.RecipientSender AS RecipientSender,
	|	DeliveryReferences.DeliveryMethod        AS DeliveryMethod,
	|	DeliveryReferences.Zone                  AS Zone,
	|	DeliveryReferences.Carrier            AS Carrier,
	|	NULL                                         AS SpecialTransportationConditions,
	|	PartiallyDeliveredOrders.Products      AS Products,
	|	PartiallyDeliveredOrders.Characteristic    AS Characteristic,
	|	PartiallyDeliveredOrders.Purpose        AS Purpose,
	|	PartiallyDeliveredOrders.Series             AS Series,
	|	SUM(PartiallyDeliveredOrders.Count) AS Count
	|INTO TtOfMovementToDistributionAccordingToOrderScheme
	|FROM
	|	DeliveryReferences AS DeliveryReferences
	|		INNER JOIN InformationRegister.GoodsToDeliver AS PartiallyDeliveredOrders
	|		ON DeliveryReferences.ReferenceOrder = PartiallyDeliveredOrders.ReferenceOrder
	|			AND DeliveryReferences.Warehouse = PartiallyDeliveredOrders.Warehouse
	|			AND (NOT PartiallyDeliveredOrders.AllGoods)
	|			AND (DeliveryReferences.ThisIsOrderWarehouse
	|				OR DeliveryReferences.DeliveryMethod
	|					= VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint))
	|		LEFT JOIN Document.TransportationJob.References AS OrdersTasks
	|		ON PartiallyDeliveredOrders.TransportationJob = OrdersTasks.Ref
	|			AND PartiallyDeliveredOrders.ReferenceOrder = OrdersTasks.ReferenceOrder
	|WHERE
	|	(PartiallyDeliveredOrders.TransportationJob <> &TaskForTransportationSelection
	|		AND PartiallyDeliveredOrders.TransportationJob.Posted
	|		AND CASE
	|				WHEN OrdersTasks.Ref.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|					THEN OrdersTasks.Delivered
	|				ELSE TRUE
	|			END
	|			OR PartiallyDeliveredOrders.TransportationJob = &TransportTaskEmptyLink)
	|
	|GROUP BY
	|	PartiallyDeliveredOrders.Warehouse,
	|	PartiallyDeliveredOrders.ReferenceOrder,
	|	DeliveryReferences.RecipientSender,
	|	DeliveryReferences.DeliveryMethod,
	|	DeliveryReferences.Zone,
	|	DeliveryReferences.Carrier,
	|	PartiallyDeliveredOrders.Products,
	|	PartiallyDeliveredOrders.Characteristic,
	|	PartiallyDeliveredOrders.Purpose,
	|	PartiallyDeliveredOrders.Series
	|
	|HAVING
	|	SUM(PartiallyDeliveredOrders.Count) > 0
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsForShipmentInDetail.DateOfShipment AS Date,
	|	GoodsForShipmentInDetail.Products AS Products,
	|	GoodsForShipmentInDetail.DimensionalUnitOfMeasurement AS DimensionalUnitOfMeasurement,
	|	GoodsForShipmentInDetail.Characteristic AS Characteristic,
	|	GoodsForShipmentInDetail.Purpose AS Purpose,
	|	GoodsForShipmentInDetail.Series AS Series,
	|	GoodsForShipmentInDetail.Count AS Count,
	|	GoodsForShipmentInDetail.Weight AS Weight,
	|	GoodsForShipmentInDetail.VolumeM3 AS VolumeM3,
	|	GoodsForShipmentInDetail.Warehouse AS Warehouse,
	|	GoodsForShipmentInDetail.ReferenceOrder AS ReferenceOrder,
	|	GoodsForShipmentInDetail.RecipientSender AS RecipientSender,
	|	VALUETYPE(GoodsForShipmentInDetail.ReferenceOrder) AS ReferenceKind,
	|	StatesAndDetailsOfDelivery.Number AS Number,
	|	StatesAndDetailsOfDelivery.Address AS Address,
	|	StatesAndDetailsOfDelivery.FieldValueAddress AS FieldValueAddress,
	|	GoodsForShipmentInDetail.DeliveryMethod AS DeliveryMethod,
	|	CASE
	|		WHEN GoodsForShipmentInDetail.ThisIsInstructionForShippingAgent
	|			THEN 4
	|		ELSE CASE
	|				WHEN GoodsForShipmentInDetail.DeliveryMethod IN (VALUE(Enum.TransportMethods.ByCarrier))
	|					THEN 0
	|				WHEN GoodsForShipmentInDetail.DeliveryMethod IN (VALUE(Enum.TransportMethods.ToCustomer), VALUE(Enum.TransportMethods.ByCarrierToAddress))
	|					THEN 1
	|				ELSE 2
	|			END + CASE
	|				WHEN StatesAndDetailsOfDelivery.SpecialTransportationConditions
	|					THEN 3
	|				ELSE 0
	|			END
	|	END AS Picture,
	|	GoodsForShipmentInDetail.Zone AS Zone,
	|	GoodsForShipmentInDetail.Zone.Description AS ZonePresentation,
	|	GoodsForShipmentInDetail.Carrier AS Carrier,
	|	StatesAndDetailsOfDelivery.TimeFrom AS TimeFrom,
	|	StatesAndDetailsOfDelivery.TimeTo AS TimeTo,
	|	StatesAndDetailsOfDelivery.AdditionalInformation AS AdditionalInformation,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	CASE
	|		WHEN GoodsForShipmentInDetail.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN PRESENTATION(GoodsForShipmentInDetail.Carrier)
	|		ELSE StatesAndDetailsOfDelivery.Address
	|	END AS OrderField
	|INTO TTOrdersForDeliveryToRecipientsAccordingToOrderScheme
	|FROM
	|	(SELECT DISTINCT
	|		MAX(
	|			CASE WHEN
	|				BEGINOFPERIOD(ProductsIncludingDelivered.Period, DAY) < BEGINOFPERIOD(&CurrentSessionDate, DAY)
	|					THEN BEGINOFPERIOD(&CurrentSessionDate, DAY)
	|				ELSE BEGINOFPERIOD(ProductsIncludingDelivered.Period, DAY)
	|			END) AS DateOfShipment,
	|		CASE WHEN
	|			BEGINOFPERIOD(ProductsIncludingDelivered.Period, DAY) < BEGINOFPERIOD(&CurrentSessionDate, DAY)
	|				THEN BEGINOFPERIOD(&CurrentSessionDate, DAY)
	|			ELSE BEGINOFPERIOD(ProductsIncludingDelivered.Period, DAY)
	|		END AS FieldForGroupingExpiredShipmentDates,
	|		ProductsIncludingDelivered.Products AS Products,
	|		ProductsIncludingDelivered.Characteristic AS Characteristic,
	|		ProductsIncludingDelivered.Purpose AS Purpose,
	|		ProductsIncludingDelivered.Series AS Series,
	|		DeliveryReferences.Warehouse                 AS Warehouse,
	|		DeliveryReferences.ReferenceOrder          AS ReferenceOrder,
	|		DeliveryReferences.RecipientSender AS RecipientSender,
	|		DeliveryReferences.DeliveryMethod        AS DeliveryMethod,
	|		DeliveryReferences.Zone                  AS Zone,
	|		DeliveryReferences.Carrier            AS Carrier,
	|		SUM(ProductsIncludingDelivered.ToShip) AS Count,      // Count
	|		SUM(ProductsIncludingDelivered.ToShip * &QueryTextPackageWeight) AS Weight,
	|		SUM(ProductsIncludingDelivered.ToShip * &QueryTextPackageVolume) AS VolumeM3,
	|		FALSE AS ThisIsInstructionForShippingAgent,
	|		ProductsIncludingDelivered.Products.UnitOfMeasure.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS DimensionalUnitOfMeasurement
	|	FROM
	|		AccumulationRegister.GoodsForIssue AS ProductsIncludingDelivered
	|			INNER JOIN DeliveryReferences AS DeliveryReferences
	|			ON ProductsIncludingDelivered.DocumentShipments = DeliveryReferences.ReferenceOrder
	|			AND ProductsIncludingDelivered.Warehouse = DeliveryReferences.Warehouse
	|			AND DeliveryReferences.ThisIsOrderWarehouse
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON ProductsIncludingDelivered.Products = CatalogProducts.Ref
	|	WHERE
	|		ProductsIncludingDelivered.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	GROUP BY
	|		CASE WHEN
	|			BEGINOFPERIOD(ProductsIncludingDelivered.Period, DAY) < BEGINOFPERIOD(&CurrentSessionDate, DAY)
	|				THEN BEGINOFPERIOD(&CurrentSessionDate, DAY)
	|			ELSE BEGINOFPERIOD(ProductsIncludingDelivered.Period, DAY)
	|		END,
	|		DeliveryReferences.Warehouse,
	|		DeliveryReferences.ReferenceOrder,
	|		DeliveryReferences.Zone,
	|		DeliveryReferences.RecipientSender,
	|		DeliveryReferences.DeliveryMethod,
	|		DeliveryReferences.Carrier,
	|		ProductsIncludingDelivered.Products,
	|		ProductsIncludingDelivered.Characteristic,
	|		ProductsIncludingDelivered.Purpose,
	|		ProductsIncludingDelivered.Series,
	|		ProductsIncludingDelivered.Products.UnitOfMeasure.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|	HAVING
	|		SUM(ProductsIncludingDelivered.ToShip) > 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(DeliveryReferences.Date, DAY),
	|		BEGINOFPERIOD(DeliveryReferences.Date, DAY),
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		DeliveryReferences.Warehouse,
	|		DeliveryReferences.ReferenceOrder,
	|		DeliveryReferences.RecipientSender,
	|		DeliveryReferences.DeliveryMethod,
	|		DeliveryReferences.Zone,
	|		NULL,
	|		0,
	|		0,
	|		0,
	|		TRUE,
	|		FALSE
	|	FROM
	|		DeliveryReferences AS DeliveryReferences
	|			LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|			ON (GoodsToDeliver.ReferenceOrder = DeliveryReferences.ReferenceOrder)
	|	WHERE
	|		GoodsToDeliver.ReferenceOrder IS NULL
	|		AND DeliveryReferences.DeliveryMethod IN (
	|			VALUE(Enum.TransportMethods.InstructionForShippingAgentFromWarehouse),
	|			VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint)
	|			)
	|	) AS GoodsForShipmentInDetail
	|
	|	LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|	ON GoodsForShipmentInDetail.ReferenceOrder = StatesAndDetailsOfDelivery.ReferenceOrder
	|		AND GoodsForShipmentInDetail.Warehouse = StatesAndDetailsOfDelivery.Warehouse";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestOrderForDeliveryToRecipientsWithoutOrderScheme()
	
	QueryText =
	"SELECT ALLOWED
	|	PartiallyDeliveredOrders.Warehouse              AS Warehouse,
	|	PartiallyDeliveredOrders.ReferenceOrder       AS ReferenceOrder,
	|	NULL                                          AS RecipientSender,
	|	DeliveryReferences.DeliveryMethod         AS DeliveryMethod,
	|	NULL                                          AS Zone,
	|	NULL                                          AS Carrier,
	|	DeliveryReferences.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	PartiallyDeliveredOrders.Products       AS Products,
	|	PartiallyDeliveredOrders.Characteristic     AS Characteristic,
	|	PartiallyDeliveredOrders.Purpose         AS Purpose,
	|	PartiallyDeliveredOrders.Series              AS Series,
	|	SUM(PartiallyDeliveredOrders.Count)  AS Count
	|INTO TTMovesToDistributionWithoutOrderScheme
	|FROM
	|	DeliveryReferences AS DeliveryReferences
	|		INNER JOIN InformationRegister.GoodsToDeliver AS PartiallyDeliveredOrders
	|		ON DeliveryReferences.ReferenceOrder = PartiallyDeliveredOrders.ReferenceOrder
	|			AND DeliveryReferences.Warehouse = PartiallyDeliveredOrders.Warehouse
	|			AND NOT DeliveryReferences.ThisIsOrderWarehouse
	|			AND (NOT PartiallyDeliveredOrders.AllGoods)
	|		LEFT JOIN Document.TransportationJob.References AS OrdersTasks
	|		ON PartiallyDeliveredOrders.TransportationJob = OrdersTasks.Ref
	|			AND PartiallyDeliveredOrders.ReferenceOrder = OrdersTasks.ReferenceOrder
	|WHERE
	|	(PartiallyDeliveredOrders.TransportationJob <> &TaskForTransportationSelection
	|		AND PartiallyDeliveredOrders.TransportationJob.Posted
	|		AND CASE
	|				WHEN OrdersTasks.Ref.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|					THEN OrdersTasks.Delivered
	|				ELSE TRUE
	|			END
	|			OR PartiallyDeliveredOrders.TransportationJob = &TransportTaskEmptyLink)
	|
	|GROUP BY
	|	PartiallyDeliveredOrders.Warehouse,
	|	PartiallyDeliveredOrders.ReferenceOrder,
	|	DeliveryReferences.DeliveryMethod,
	|	DeliveryReferences.SpecialTransportationConditions,
	|	PartiallyDeliveredOrders.Products,
	|	PartiallyDeliveredOrders.Characteristic,
	|	PartiallyDeliveredOrders.Purpose,
	|	PartiallyDeliveredOrders.Series
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	VZ.Date AS Date,
	|	VZ.Products AS Products,
	|	VZ.Products.UnitOfMeasure.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS DimensionalUnitOfMeasurement,
	|	VZ.Characteristic AS Characteristic,
	|	VZ.Purpose AS Purpose,
	|	VZ.Series AS Series,
	|	VZ.Count AS Count,
	|	VZ.Count * &QueryTextPackageWeight AS Weight,
	|	VZ.Count * &QueryTextPackageVolume AS VolumeM3,
	|	VZ.Warehouse AS Warehouse,
	|	VZ.ReferenceOrder AS ReferenceOrder,
	|	AddAttributes.RecipientSender AS RecipientSender,
	|	VALUETYPE(VZ.ReferenceOrder) AS ReferenceKind,
	|	AddAttributes.Number AS Number,
	|	AddAttributes.Address AS Address,
	|	AddAttributes.FieldValueAddress AS FieldValueAddress,
	|	VZ.DeliveryMethod AS DeliveryMethod,
	|	VZ.Picture AS Picture,
	|	ISNULL(AddAttributes.Zone, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Zone,
	|	AddAttributes.Zone.Description AS ZonePresentation,
	|	AddAttributes.Carrier AS Carrier,
	|	AddAttributes.TimeFrom AS TimeFrom,
	|	AddAttributes.TimeTo AS TimeTo,
	|	AddAttributes.AdditionalInformation AS AdditionalInformation,
	|	AddAttributes.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	AddAttributes.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	CASE
	|		WHEN VZ.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN PRESENTATION(AddAttributes.Carrier)
	|		ELSE AddAttributes.Address
	|	END AS OrderField
	|INTO TTOrdersForDeliveryToRecipientsWithoutOrderScheme
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(GoodsForIssue.Period, DAY) AS Date,
	|		DeliveryReferences.ReferenceOrder AS ReferenceOrder,
	|		DeliveryReferences.Warehouse AS Warehouse,
	|		GoodsForIssue.Products AS Products,
	|		GoodsForIssue.Characteristic AS Characteristic,
	|		GoodsForIssue.Purpose AS Purpose,
	|		GoodsForIssue.Series AS Series,
	|		DeliveryReferences.DeliveryMethod AS DeliveryMethod,
	|		SUM(GoodsForIssue.ToShip) AS Count,
	|		CASE
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.ByCarrier))
	|				THEN 0
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.ToCustomer), VALUE(Enum.TransportMethods.ByCarrierToAddress))
	|				THEN 1
	|			ELSE 2
	|		END + CASE
	|			WHEN DeliveryReferences.SpecialTransportationConditions
	|				THEN 3
	|			ELSE 0
	|		END AS Picture
	|	FROM
	|		DeliveryReferences AS DeliveryReferences
	|			INNER JOIN AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|			ON DeliveryReferences.ReferenceOrder = GoodsForIssue.DocumentShipments
	|				AND DeliveryReferences.Warehouse = GoodsForIssue.Warehouse
	|				AND NOT DeliveryReferences.ThisIsOrderWarehouse
	|	WHERE
	|		GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	GROUP BY
	|		BEGINOFPERIOD(GoodsForIssue.Period, DAY),
	|		DeliveryReferences.ReferenceOrder,
	|		DeliveryReferences.Warehouse,
	|		GoodsForIssue.Products,
	|		GoodsForIssue.Characteristic,
	|		GoodsForIssue.Purpose,
	|		GoodsForIssue.Series,
	|		DeliveryReferences.DeliveryMethod,
	|		CASE
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.ByCarrier))
	|				THEN 0
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.ToCustomer), VALUE(Enum.TransportMethods.ByCarrierToAddress))
	|				THEN 1
	|			ELSE 2
	|		END + CASE
	|			WHEN DeliveryReferences.SpecialTransportationConditions
	|				THEN 3
	|			ELSE 0
	|		END
	|	
	|	HAVING
	|		SUM(GoodsForIssue.ToShip) > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(DeliveryReferences.Date, DAY),
	|		DeliveryReferences.ReferenceOrder,
	|		DeliveryReferences.Warehouse,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		DeliveryReferences.DeliveryMethod,
	|		NULL,
	|		4
	|	FROM
	|		DeliveryReferences AS DeliveryReferences
	|			LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|			ON (GoodsToDeliver.ReferenceOrder = DeliveryReferences.ReferenceOrder)
	|	WHERE
	|		DeliveryReferences.DeliveryMethod IN
	|			(VALUE(Enum.TransportMethods.InstructionForShippingAgentFromWarehouse),
	|			VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint))
	|		AND GoodsToDeliver.ReferenceOrder IS NULL
	|	) AS VZ
	|	
	|	LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS AddAttributes
	|	ON VZ.ReferenceOrder = AddAttributes.ReferenceOrder
	|		AND VZ.Warehouse = AddAttributes.Warehouse
	|	LEFT JOIN Catalog.Products AS CatalogProducts
	|	ON VZ.Products = CatalogProducts.Ref";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestOrderForDeliveryFromSendersAccordingToOrderScheme()
	
	QueryText =
	"SELECT ALLOWED
	|	GoodsToReceiveBalance.Warehouse AS Warehouse,
	|	GoodsToReceiveBalance.DocumentInflow AS ReferenceOrder,
	|	GoodsToReceiveBalance.Products AS Products,
	|	GoodsToReceiveBalance.Characteristic AS Characteristic,
	|	GoodsToReceiveBalance.Purpose AS Purpose,
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS Count
	|INTO GoodsToDeliverBalance
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			(Warehouse, DocumentInflow) IN
	|				(SELECT
	|					DeliveryReferences.Warehouse,
	|					DeliveryReferences.ReferenceOrder
	|				FROM
	|					DeliveryReferences AS DeliveryReferences
	|				WHERE
	|					DeliveryReferences.ThisIsOrderWarehouse)) AS GoodsToReceiveBalance
	|WHERE
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DetailedData.Warehouse AS Warehouse,
	|	DetailedData.ReferenceOrder AS ReferenceOrder,
	|	DetailedData.Products AS Products,
	|	DetailedData.Characteristic AS Characteristic,
	|	DetailedData.Purpose AS Purpose,
	|	SUM(DetailedData.Count) AS Count
	|INTO ProductsIncludingDelivered
	|FROM
	|	(SELECT
	|		GoodsToDeliverBalance.Warehouse AS Warehouse,
	|		GoodsToDeliverBalance.ReferenceOrder AS ReferenceOrder,
	|		GoodsToDeliverBalance.Products AS Products,
	|		GoodsToDeliverBalance.Characteristic AS Characteristic,
	|		GoodsToDeliverBalance.Purpose AS Purpose,
	|		GoodsToDeliverBalance.Count AS Count
	|	FROM
	|		GoodsToDeliverBalance AS GoodsToDeliverBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToDeliverBalance.Warehouse,
	|		GoodsToDeliverBalance.ReferenceOrder,
	|		GoodsToDeliverBalance.Products,
	|		GoodsToDeliverBalance.Characteristic,
	|		GoodsToDeliverBalance.Purpose,
	|		-ISNULL(GoodsToDeliver.Count, 0)
	|	FROM
	|		GoodsToDeliverBalance AS GoodsToDeliverBalance
	|			INNER JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|			ON GoodsToDeliverBalance.Warehouse = GoodsToDeliver.Warehouse
	|				AND GoodsToDeliverBalance.ReferenceOrder = GoodsToDeliver.ReferenceOrder
	|				AND GoodsToDeliverBalance.Products = GoodsToDeliver.Products
	|				AND GoodsToDeliverBalance.Characteristic = GoodsToDeliver.Characteristic
	|				AND GoodsToDeliverBalance.Purpose = GoodsToDeliver.Purpose
	|	WHERE
	|		(GoodsToDeliver.TransportationJob <> &TaskForTransportationSelection
	|					AND GoodsToDeliver.TransportationJob.Posted
	|				OR GoodsToDeliver.TransportationJob = &TransportTaskEmptyLink)
	|		AND NOT GoodsToDeliver.AllGoods) AS DetailedData
	|
	|GROUP BY
	|	DetailedData.Warehouse,
	|	DetailedData.ReferenceOrder,
	|	DetailedData.Products,
	|	DetailedData.Characteristic,
	|	DetailedData.Purpose
	|
	|HAVING
	|	SUM(DetailedData.Count) > 0
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsToReceive.Period AS Period,
	|	GoodsToReceive.DocumentInflow AS ReferenceOrder,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Purpose AS Purpose,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	SUM(ISNULL(GoodsToReceive.GoodsReceiptNotesToRegister, 0)) AS Count,
	|	SUM(ISNULL(GoodsToReceive.GoodsReceiptNotesToRegister, 0) * &QueryTextPackageWeight) AS Weight,
	|	SUM(ISNULL(GoodsToReceive.GoodsReceiptNotesToRegister, 0) * &QueryTextPackageVolume) AS VolumeM3
	|INTO TtOfMovementToDistributionAccordingToOrderScheme
	|FROM
	|	ProductsIncludingDelivered AS ProductsIncludingDelivered
	|		LEFT JOIN AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|		ON ProductsIncludingDelivered.ReferenceOrder = GoodsToReceive.DocumentInflow
	|			AND ProductsIncludingDelivered.Warehouse = GoodsToReceive.Warehouse
	|			AND ProductsIncludingDelivered.Products = GoodsToReceive.Products
	|			AND ProductsIncludingDelivered.Characteristic = GoodsToReceive.Characteristic
	|			AND ProductsIncludingDelivered.Purpose = GoodsToReceive.Purpose
	|			AND (GoodsToReceive.Period >= &FilterDate)
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ProductsIncludingDelivered.Products = CatalogProducts.Ref
	|WHERE
	|	GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|GROUP BY
	|	GoodsToReceive.Period,
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Purpose,
	|	GoodsToReceive.Warehouse
	|HAVING
	|	SUM(GoodsToReceive.GoodsReceiptNotesToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ISNULL(StatesAndDetailsOfDelivery.RecipientSender, UNDEFINED) AS RecipientSender,
	|	ProductsIncludingDelivered.Products AS Products,
	|	ProductsIncludingDelivered.Products.UnitOfMeasure.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS DimensionalUnitOfMeasurement,
	|	ProductsIncludingDelivered.Characteristic AS Characteristic,
	|	ProductsIncludingDelivered.Purpose AS Purpose,
	|	ProductsIncludingDelivered.Count AS Count,
	|	ProductsIncludingDelivered.Count * &QueryTextPackageWeight AS Weight,
	|	ProductsIncludingDelivered.Count * &QueryTextPackageVolume AS VolumeM3,
	|	ProductsIncludingDelivered.Warehouse AS Warehouse,
	|	ProductsIncludingDelivered.ReferenceOrder AS ReferenceOrder,
	|	VALUETYPE(ProductsIncludingDelivered.ReferenceOrder) AS ReferenceKind,
	|	StatesAndDetailsOfDelivery.Number AS Number,
	|	StatesAndDetailsOfDelivery.Address AS Address,
	|	StatesAndDetailsOfDelivery.FieldValueAddress AS FieldValueAddress,
	|	StatesAndDetailsOfDelivery.DeliveryMethod AS DeliveryMethod,
	|	StatesAndDetailsOfDelivery.Zone AS Zone,
	|	StatesAndDetailsOfDelivery.Zone.Description AS ZonePresentation,
	|	StatesAndDetailsOfDelivery.Carrier AS Carrier,
	|	StatesAndDetailsOfDelivery.TimeFrom AS TimeFrom,
	|	StatesAndDetailsOfDelivery.TimeTo AS TimeTo,
	|	CASE
	|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN (VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse))
	|			THEN 0
	|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN (VALUE(Enum.TransportMethods.OurOwnDeliveryFromSenderAddress), VALUE(Enum.TransportMethods.ByCarrierToTransferPoint))
	|			THEN 1
	|		ELSE 2
	|	END + CASE
	|		WHEN StatesAndDetailsOfDelivery.SpecialTransportationConditions
	|			THEN 3
	|		ELSE 0
	|	END AS Picture,
	|	StatesAndDetailsOfDelivery.AdditionalInformation AS AdditionalInformation,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	StatesAndDetailsOfDelivery.Date AS Date,
	|	NULL AS OrderField
	|INTO TTOrdersForDeliveryFromSendersAccordingToOrderScheme
	|FROM
	|	ProductsIncludingDelivered AS ProductsIncludingDelivered
	|		LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		ON ProductsIncludingDelivered.Warehouse = StatesAndDetailsOfDelivery.Warehouse
	|			AND ProductsIncludingDelivered.ReferenceOrder = StatesAndDetailsOfDelivery.ReferenceOrder
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ProductsIncludingDelivered.Products = CatalogProducts.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DeliveryReferences.RecipientSender,
	|	UNDEFINED,
	|	FALSE,
	|	UNDEFINED,
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	DeliveryReferences.Warehouse,
	|	DeliveryReferences.ReferenceOrder,
	|	VALUETYPE(DeliveryReferences.ReferenceOrder),
	|	StatesAndDetailsOfDelivery.Number,
	|	StatesAndDetailsOfDelivery.Address,
	|	StatesAndDetailsOfDelivery.FieldValueAddress,
	|	StatesAndDetailsOfDelivery.DeliveryMethod,
	|	StatesAndDetailsOfDelivery.Zone,
	|	StatesAndDetailsOfDelivery.Zone.Description,
	|	StatesAndDetailsOfDelivery.Carrier,
	|	StatesAndDetailsOfDelivery.TimeFrom,
	|	StatesAndDetailsOfDelivery.TimeTo,
	|	4,
	|	StatesAndDetailsOfDelivery.AdditionalInformation,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditions,
	|	StatesAndDetailsOfDelivery.SpecialTransportationConditionsDescription,
	|	UNDEFINED,
	|	CASE
	|		WHEN DeliveryReferences.ReferenceOrder REFS Document.InstructionForShippingAgent
	|			THEN BEGINOFPERIOD(StatesAndDetailsOfDelivery.Date, DAY)
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	DeliveryReferences.OrderingField
	|FROM
	|	DeliveryReferences AS DeliveryReferences
	|		LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|		ON DeliveryReferences.ReferenceOrder = GoodsToDeliver.ReferenceOrder
	|		INNER JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		ON DeliveryReferences.ReferenceOrder = StatesAndDetailsOfDelivery.ReferenceOrder
	|WHERE
	|	GoodsToDeliver.ReferenceOrder IS NULL
	|	AND DeliveryReferences.DeliveryMethod IN (
	|		VALUE(Enum.TransportMethods.InstructionForShippingAgentToWarehouse),
	|		VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint))
	|";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestOrderForDeliveryFromSendersWithoutOrderScheme()
	
	QueryText = 
	"SELECT ALLOWED
	|	NestedQuery.ReferenceOrder AS ReferenceOrder,
	|	NestedQuery.Warehouse AS Warehouse,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	CASE
	|		WHEN SUM(NestedQuery.QuantityInDelivery) > SUM(NestedQuery.QuantityAccepted)
	|			THEN SUM(NestedQuery.QuantityInDelivery)
	|		ELSE SUM(NestedQuery.QuantityAccepted)
	|	END AS Count
	|INTO ItemsDeductedFromDelivery
	|FROM
	|	(SELECT
	|		GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
	|		GoodsToDeliver.Warehouse AS Warehouse,
	|		GoodsToDeliver.Products AS Products,
	|		GoodsToDeliver.Characteristic AS Characteristic,
	|		GoodsToDeliver.Purpose AS Purpose,
	|		GoodsToDeliver.Count AS QuantityInDelivery,
	|		0 AS QuantityAccepted
	|	FROM
	|		InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|			INNER JOIN DeliveryReferences AS DeliveryReferences
	|			ON GoodsToDeliver.ReferenceOrder = DeliveryReferences.ReferenceOrder
	|				AND GoodsToDeliver.Warehouse = DeliveryReferences.Warehouse
	|				AND NOT DeliveryReferences.ThisIsOrderWarehouse
	|				AND (NOT GoodsToDeliver.AllGoods)
	|	WHERE
	|		(GoodsToDeliver.TransportationJob <> &TaskForTransportationSelection
	|					AND GoodsToDeliver.TransportationJob.Posted
	|				OR GoodsToDeliver.TransportationJob = &TransportTaskEmptyLink)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToReceiveTurnovers.DocumentInflow,
	|		GoodsToReceiveTurnovers.Warehouse,
	|		GoodsToReceiveTurnovers.Products,
	|		GoodsToReceiveTurnovers.Characteristic,
	|		GoodsToReceiveTurnovers.Purpose,
	|		0,
	|		GoodsToReceiveTurnovers.GoodsReceiptNotesToRegisterExpense
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Turnovers(, , , 
	|			(DocumentInflow, Warehouse) IN (
	|				SELECT
	|					DeliveryReferences.ReferenceOrder,
	|					DeliveryReferences.Warehouse
	|				FROM
	|					DeliveryReferences AS DeliveryReferences
	|				WHERE
	|					NOT DeliveryReferences.ThisIsOrderWarehouse)
	|			) AS GoodsToReceiveTurnovers
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Warehouse,
	|	NestedQuery.Purpose,
	|	NestedQuery.ReferenceOrder,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic
	|
	|INDEX BY
	|	NestedQuery.ReferenceOrder,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NULL AS Period,
	|	NULL AS ReferenceOrder,
	|	NULL AS Products,
	|	NULL AS Characteristic,
	|	NULL AS Purpose,
	|	NULL AS Warehouse,
	|	0 AS Count,
	|	0 AS Weight,
	|	0 AS VolumeM3
	|INTO TTMovesToDistributionWithoutOrderScheme
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DetailedData.Date AS Date,
	|	DetailedData.Products AS Products,
	|	DetailedData.DimensionalUnitOfMeasurement AS DimensionalUnitOfMeasurement,
	|	DetailedData.Characteristic AS Characteristic,
	|	DetailedData.Purpose AS Purpose,
	|	DetailedData.Series AS Series,
	|	DetailedData.InitialNeedByDate - DetailedData.DeductionOfGoodsForDelivery AS Count,
	|	DetailedData.InitialNeedByDateWeight - DetailedData.DeductionGoodsForDeliveryWeight AS Weight,
	|	DetailedData.InitialDemandByDateVolume - DetailedData.DeductionGoodsForDeliveryVolume AS VolumeM3,
	|	DetailedData.Warehouse AS Warehouse,
	|	DetailedData.ReferenceOrder AS ReferenceOrder,
	|	DetailedData.RecipientSender AS RecipientSender,
	|	DetailedData.ReferenceKind AS ReferenceKind,
	|	DetailedData.Number AS Number,
	|	DetailedData.Address AS Address,
	|	DetailedData.FieldValueAddress AS FieldValueAddress,
	|	DetailedData.DeliveryMethod AS DeliveryMethod,
	|	DetailedData.Picture AS Picture,
	|	DetailedData.Zone AS Zone,
	|	DetailedData.ZonePresentation AS ZonePresentation,
	|	DetailedData.Carrier AS Carrier,
	|	DetailedData.TimeFrom AS TimeFrom,
	|	DetailedData.TimeTo AS TimeTo,
	|	DetailedData.AdditionalInformation AS AdditionalInformation,
	|	DetailedData.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DetailedData.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	DetailedData.OrderingField AS OrderField
	|INTO TTDeliveryOrdersFromSendersWithoutOrderScheme
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(GoodsForDeliveryByRegistrars.Period, DAY) AS Date,
	|		GoodsForDeliveryByRegistrars.Products AS Products,
	|		GoodsForDeliveryByRegistrars.Products.UnitOfMeasure.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS DimensionalUnitOfMeasurement,
	|		GoodsForDeliveryByRegistrars.Characteristic AS Characteristic,
	|		GoodsForDeliveryByRegistrars.Purpose AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|		GoodsForDeliveryByRegistrars.GoodsReceiptNotesToRegisterReceipt AS InitialNeedByDate,
	|		GoodsForDeliveryByRegistrars.GoodsReceiptNotesToRegisterReceipt * &QueryTextPackageWeight AS InitialNeedByDateWeight,
	|		GoodsForDeliveryByRegistrars.GoodsReceiptNotesToRegisterReceipt * &QueryTextPackageVolume AS InitialDemandByDateVolume,
	|		ISNULL(ItemsDeductedFromDelivery.Count, 0) AS DeductionOfGoodsForDelivery,
	|		ISNULL(ItemsDeductedFromDelivery.Count, 0) * &QueryTextPackageWeight AS DeductionGoodsForDeliveryWeight,
	|		ISNULL(ItemsDeductedFromDelivery.Count, 0) * &QueryTextPackageVolume AS DeductionGoodsForDeliveryVolume,
	|		DeliveryReferences.Warehouse AS Warehouse,
	|		DeliveryReferences.ReferenceOrder AS ReferenceOrder,
	|		DeliveryReferences.RecipientSender AS RecipientSender,
	|		DeliveryReferences.ReferenceKind AS ReferenceKind,
	|		DeliveryReferences.Number AS Number,
	|		DeliveryReferences.Address AS Address,
	|		DeliveryReferences.FieldValueAddress AS FieldValueAddress,
	|		DeliveryReferences.DeliveryMethod AS DeliveryMethod,
	|		CASE
	|			WHEN DeliveryReferences.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse)
	|				THEN 0
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.OurOwnDeliveryFromSenderAddress), VALUE(Enum.TransportMethods.ByCarrierToTransferPoint), VALUE(Enum.TransportMethods.InstructionForShippingAgentToWarehouse), VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint))
	|				THEN 1
	|			ELSE 2
	|		END + CASE
	|			WHEN DeliveryReferences.SpecialTransportationConditions
	|				THEN 3
	|			ELSE 0
	|		END AS Picture,
	|		DeliveryReferences.Zone AS Zone,
	|		DeliveryReferences.Zone.Description AS ZonePresentation,
	|		DeliveryReferences.Carrier AS Carrier,
	|		DeliveryReferences.TimeFrom AS TimeFrom,
	|		DeliveryReferences.TimeTo AS TimeTo,
	|		DeliveryReferences.AdditionalInformation AS AdditionalInformation,
	|		DeliveryReferences.SpecialTransportationConditions AS SpecialTransportationConditions,
	|		DeliveryReferences.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|		DeliveryReferences.OrderingField AS OrderingField
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Turnovers(, , Recorder, 
	|			(DocumentInflow, Warehouse) IN (
	|				SELECT
	|					DeliveryReferences.ReferenceOrder,
	|					DeliveryReferences.Warehouse
	|				FROM
	|					DeliveryReferences AS DeliveryReferences
	|				WHERE
	|					NOT DeliveryReferences.ThisIsOrderWarehouse
	|				)
	|			) AS GoodsForDeliveryByRegistrars
	|			LEFT JOIN ItemsDeductedFromDelivery AS ItemsDeductedFromDelivery
	|			ON (ItemsDeductedFromDelivery.ReferenceOrder = GoodsForDeliveryByRegistrars.Recorder)
	|				AND (ItemsDeductedFromDelivery.Warehouse = GoodsForDeliveryByRegistrars.Warehouse)
	|				AND (ItemsDeductedFromDelivery.Products = GoodsForDeliveryByRegistrars.Products)
	|				AND (ItemsDeductedFromDelivery.Characteristic = GoodsForDeliveryByRegistrars.Characteristic)
	|				AND (ItemsDeductedFromDelivery.Purpose = GoodsForDeliveryByRegistrars.Purpose)
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON (CatalogProducts.Ref = GoodsForDeliveryByRegistrars.Products)
	|			LEFT JOIN DeliveryReferences AS DeliveryReferences
	|			ON GoodsForDeliveryByRegistrars.Recorder = DeliveryReferences.ReferenceOrder
	|				AND GoodsForDeliveryByRegistrars.Warehouse = DeliveryReferences.Warehouse
	|			LEFT JOIN Catalog.DeliveryZones AS Zones
	|			ON (Zones.Ref = DeliveryReferences.Zone)
	|	WHERE
	|		GoodsForDeliveryByRegistrars.GoodsReceiptNotesToRegisterReceipt > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(GoodsForDeliveryByDay.Period, DAY),
	|		GoodsForDeliveryByDay.Products,
	|		GoodsForDeliveryByDay.Products.UnitOfMeasure.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces),
	|		GoodsForDeliveryByDay.Characteristic,
	|		GoodsForDeliveryByDay.Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef),
	|		GoodsForDeliveryByDay.Count,
	|		GoodsForDeliveryByDay.Count * &QueryTextPackageWeight,
	|		GoodsForDeliveryByDay.Count * &QueryTextPackageVolume,
	|		ISNULL(ItemsDeductedFromDelivery.Count, 0),
	|		ISNULL(ItemsDeductedFromDelivery.Count, 0) * &QueryTextPackageWeight,
	|		ISNULL(ItemsDeductedFromDelivery.Count, 0) * &QueryTextPackageVolume,
	|		DeliveryReferences.Warehouse,
	|		DeliveryReferences.ReferenceOrder,
	|		DeliveryReferences.RecipientSender,
	|		DeliveryReferences.ReferenceKind,
	|		DeliveryReferences.Number,
	|		DeliveryReferences.Address,
	|		DeliveryReferences.FieldValueAddress,
	|		DeliveryReferences.DeliveryMethod,
	|		CASE
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse))
	|				THEN 0
	|			WHEN DeliveryReferences.DeliveryMethod IN (VALUE(Enum.TransportMethods.OurOwnDeliveryFromSenderAddress), VALUE(Enum.TransportMethods.ByCarrierToTransferPoint))
	|				THEN 1
	|			ELSE 2
	|		END + CASE
	|			WHEN DeliveryReferences.SpecialTransportationConditions
	|				THEN 3
	|			ELSE 0
	|		END,
	|		DeliveryReferences.Zone,
	|		DeliveryReferences.Zone.Description,
	|		DeliveryReferences.Carrier,
	|		DeliveryReferences.TimeFrom,
	|		DeliveryReferences.TimeTo,
	|		DeliveryReferences.AdditionalInformation,
	|		DeliveryReferences.SpecialTransportationConditions,
	|		DeliveryReferences.SpecialTransportationConditionsDescription,
	|		DeliveryReferences.OrderingField
	|	FROM
	|		(SELECT
	|			T.Ref AS Ref,
	|			T.DateOfReceipt AS Period,
	|			T.Warehouse AS Warehouse,
	|			T.Products AS Products,
	|			T.Characteristic AS Characteristic,
	|			T.Purpose AS Purpose,
	|			SUM(T.Count) AS Count
	|		FROM
	|			Document.PurchaseOrder.Goods AS T
	|				INNER JOIN DeliveryReferences AS DeliveryReferences
	|				ON T.Ref = DeliveryReferences.ReferenceOrder
	|					AND T.Warehouse = DeliveryReferences.Warehouse
	|					AND (NOT T.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|						OR T.DateOfReceipt < T.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|		
	|		GROUP BY
	|			T.Ref,
	|			T.DateOfReceipt,
	|			T.Warehouse,
	|			T.Products,
	|			T.Characteristic,
	|			T.Purpose
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			T.Ref,
	|			T.Ref.Date,
	|			T.Warehouse,
	|			T.Products,
	|			T.Characteristic,
	|			T.Purpose,
	|			SUM(T.Count)
	|		FROM
	|			Document.VendorInvoice.Goods AS T
	|				INNER JOIN DeliveryReferences AS DeliveryReferences
	|				ON T.Ref = DeliveryReferences.ReferenceOrder
	|					AND T.Warehouse = DeliveryReferences.Warehouse
	|					AND (NOT T.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|						OR T.Ref.Date < T.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|		
	|		GROUP BY
	|			T.Ref,
	|			T.Warehouse,
	|			T.Products,
	|			T.Characteristic,
	|			T.Purpose,
	|			T.Ref.Date
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			T.Ref,
	|			T.Ref.Date,
	|			T.Warehouse,
	|			T.Products,
	|			T.Characteristic,
	|			T.Purpose,
	|			SUM(T.Count)
	|		FROM
	|			Document.GoodsReceiptForStorage.Goods AS T
	|				INNER JOIN DeliveryReferences AS DeliveryReferences
	|				ON T.Ref = DeliveryReferences.ReferenceOrder
	|					AND T.Warehouse = DeliveryReferences.Warehouse
	|					AND (NOT T.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|						OR T.Ref.Date < T.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|		
	|		GROUP BY
	|			T.Ref,
	|			T.Warehouse,
	|			T.Products,
	|			T.Characteristic,
	|			T.Purpose,
	|			T.Ref.Date
	|	) AS GoodsForDeliveryByDay
	|		LEFT JOIN ItemsDeductedFromDelivery AS ItemsDeductedFromDelivery
	|		ON (ItemsDeductedFromDelivery.ReferenceOrder = GoodsForDeliveryByDay.Ref)
	|			AND (ItemsDeductedFromDelivery.Warehouse = GoodsForDeliveryByDay.Warehouse)
	|			AND (ItemsDeductedFromDelivery.Products = GoodsForDeliveryByDay.Products)
	|			AND (ItemsDeductedFromDelivery.Characteristic = GoodsForDeliveryByDay.Characteristic)
	|			AND (ItemsDeductedFromDelivery.Purpose = GoodsForDeliveryByDay.Purpose)
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = GoodsForDeliveryByDay.Products)
	|		INNER JOIN DeliveryReferences AS DeliveryReferences
	|		ON GoodsForDeliveryByDay.Ref = DeliveryReferences.ReferenceOrder
	|			AND GoodsForDeliveryByDay.Warehouse = DeliveryReferences.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(DeliveryReferences.Date, DAY),
	|		UNDEFINED,
	|		FALSE,
	|		UNDEFINED,
	|		UNDEFINED,
	|		UNDEFINED,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		DeliveryReferences.Warehouse,
	|		DeliveryReferences.ReferenceOrder,
	|		DeliveryReferences.RecipientSender,
	|		DeliveryReferences.ReferenceKind,
	|		DeliveryReferences.Number,
	|		DeliveryReferences.Address,
	|		DeliveryReferences.FieldValueAddress,
	|		DeliveryReferences.DeliveryMethod,
	|		4,
	|		DeliveryReferences.Zone,
	|		DeliveryReferences.Zone.Description,
	|		DeliveryReferences.Carrier,
	|		DeliveryReferences.TimeFrom,
	|		DeliveryReferences.TimeTo,
	|		DeliveryReferences.AdditionalInformation,
	|		DeliveryReferences.SpecialTransportationConditions,
	|		DeliveryReferences.SpecialTransportationConditionsDescription,
	|		DeliveryReferences.OrderingField
	|	FROM
	|		DeliveryReferences AS DeliveryReferences
	|			LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|			ON (GoodsToDeliver.ReferenceOrder = DeliveryReferences.ReferenceOrder)
	|	WHERE
	|		DeliveryReferences.DeliveryMethod IN (
	|			VALUE(Enum.TransportMethods.InstructionForShippingAgentToWarehouse),
	|			VALUE(Enum.TransportMethods.InstructionForShippingAgentAtPoint))
	|		AND GoodsToDeliver.ReferenceOrder IS NULL
	|	) AS DetailedData
	|WHERE
	|	(DetailedData.InitialNeedByDate = 0
	|			OR DetailedData.InitialNeedByDate - DetailedData.DeductionOfGoodsForDelivery > 0)";
	
	Return QueryText;
	
EndFunction

// Returns:
//   Array of EnumRef.TransportMethods
//
Function MethodsOfDeliveryByOurForcesToRecipient()
	
	MethodsOfDeliveryByOurForcesToRecipient = New Array; // Array of EnumRef.TransportMethods
	
	MethodsOfDeliveryByOurForcesToRecipient.Add(Enums.TransportMethods.ToCustomer);
	MethodsOfDeliveryByOurForcesToRecipient.Add(Enums.TransportMethods.ByCarrierToAddress);
	MethodsOfDeliveryByOurForcesToRecipient.Add(Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany);
	MethodsOfDeliveryByOurForcesToRecipient.Add(Enums.TransportMethods.InstructionForShippingAgentFromWarehouse);
	MethodsOfDeliveryByOurForcesToRecipient.Add(Enums.TransportMethods.InstructionForShippingAgentAtPoint);
	
	Return MethodsOfDeliveryByOurForcesToRecipient;
	
EndFunction

// Returns:
//   Array of EnumRef.TransportMethods
//
Function MethodsOfDeliveryByCarrierToRecipient()
	
	MethodsOfDeliveryByCarrierToRecipient = New Array; // Array of EnumRef.TransportMethods
	
	MethodsOfDeliveryByCarrierToRecipient.Add(Enums.TransportMethods.ByCarrier);
	MethodsOfDeliveryByCarrierToRecipient.Add(Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany);
	MethodsOfDeliveryByCarrierToRecipient.Add(Enums.TransportMethods.InstructionForShippingAgentAtPoint);
	
	Return MethodsOfDeliveryByCarrierToRecipient;	
	
EndFunction

// Returns:
//   Array of EnumRef.TransportMethods
//
Function MethodsOfDeliveryByOurForcesFromSender()
	
	MethodsOfDeliveryByOurForcesFromSender = New Array; // Array of EnumRef.TransportMethods
	
	MethodsOfDeliveryByOurForcesFromSender.Add(Enums.TransportMethods.ByCarrierToTransferPoint);
	MethodsOfDeliveryByOurForcesFromSender.Add(Enums.TransportMethods.OurOwnDeliveryFromSenderAddress);
	MethodsOfDeliveryByOurForcesFromSender.Add(Enums.TransportMethods.FromSenderDeterminedByDeliveryService);
	MethodsOfDeliveryByOurForcesFromSender.Add(Enums.TransportMethods.InstructionForShippingAgentToWarehouse);
	MethodsOfDeliveryByOurForcesFromSender.Add(Enums.TransportMethods.InstructionForShippingAgentAtPoint);
	
	Return MethodsOfDeliveryByOurForcesFromSender;
	
EndFunction

// Returns:
//   Array of EnumRef.TransportMethods
//
Function ShippingMethodsByCarrierFromSender()
	
	ShippingMethodsByCarrierFromSender = New Array; // Array of EnumRef.TransportMethods
	
	ShippingMethodsByCarrierFromSender.Add(Enums.TransportMethods.ByCarrierToOurWarehouse);
	ShippingMethodsByCarrierFromSender.Add(Enums.TransportMethods.FromSenderDeterminedByDeliveryService);
	ShippingMethodsByCarrierFromSender.Add(Enums.TransportMethods.InstructionForShippingAgentAtPoint);
	Return ShippingMethodsByCarrierFromSender;
	
EndFunction

// Sets the properties of document forms that contain delivery details when reading or creating them.
//
// Parameters:
//	FormItems - FormAllItems - all elements of the form where changes are made,
//	DocObject - FormDataStructure, CatalogObject - the object whose details are used for filling in.
//
Procedure WhenReadingCreatingFillInListsOfRecipientSenderSAddressSelections(FormItems, DocObject)
	
	If ReFillInDeliveryAddressInSalesDocument(DocObject) Then
		FillInListsForSelectingRecipientSenderAddresses(FormItems, DocObject);
	EndIf;
	
EndProcedure

// Re-fills in the delivery details when the form details are changed.
//
// Parameters:
//	FormItems - FormAllItems - all elements of the form where changes are made,
//	DocObject - FormDataStructure, CatalogObject - the object whose details are used when filling in the form,
//	FillParameters - Structure, Undefined - parameters for filling in delivery Attributes. 
//		See ParametersForFillingInBankingDetails.
//
Procedure WhenChangingSenderSDestination(FormItems, DocObject, FillParameters = Undefined)
	
	If FillParameters = Undefined Then
		FillParameters = ParametersForFillingInBankingDetails();
	EndIf;
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		WhenChangingRecipientDoNotUseDeliveryManagement(FormItems, DocObject, FillParameters);
		Return
	EndIf;
	
	DeliveryDetails_ = DeliveryDetails_(DocObject);
	
	RecipientSender = DeliveryDetails_.RecipientSender;
	
	ElementNameAddress = ElementNameAddress(FormItems);
	If FillParameters.ClearDeliveryDetails Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(FormItems, DeliveryDetails_);
	EndIf;
	
	If ValueIsFilled(RecipientSender.Value) Then
		
		FillInListsForSelectingRecipientSenderAddresses(FormItems, DeliveryDetails_);
		
		If FormItems[ElementNameAddress].ChoiceList.Count() > 0
			And FillParameters.SetDeliveryAddress Then
			
			FirstStructureInList = FormItems[ElementNameAddress].ChoiceList[0].Value;
			DeliveryDetails_.DeliveryAddress = FirstStructureInList.DeliveryAddress;
			DeliveryDetails_.DeliveryAddressValue = FirstStructureInList.DeliveryAddressValue;
			DeliveryDetails_.DeliveryAddressFieldValues = FirstStructureInList.DeliveryAddressFieldValues;
			
		EndIf;
		
		FillInCarrierSelectionList(FormItems, DeliveryDetails_);
		
		If FillParameters.SetDeliveryMethod Then
			
			// We will get the values according to statistics
			If ValueIsFilled(FillParameters.SourceOfStatistics) Then
				LinkForStatistics = FillParameters.SourceOfStatistics.EmptyRef();
			Else
				LinkForStatistics = DeliveryDetails_.Ref;
			EndIf;
			
			AttributesDetails1 = New Structure;
			Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
			Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = RecipientSender.FieldName;
			If Common.HasObjectAttribute("Author", LinkForStatistics.Metadata()) Then
				Parameters.StatisticsCollectionSections.UseAlways = "Author";
				Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
			EndIf;
			ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DeliveryMethod", Parameters);
			DetailsForSelection = New Structure(RecipientSender.FieldName, RecipientSender.Value);
			DetailsToFillIn = ObjectsFillingByStatistics.GetBankingDetailsValues(LinkForStatistics,
				AttributesDetails1, DetailsForSelection);
			
			If ValueIsFilled(DetailsToFillIn.DeliveryMethod) Then
				DeliveryDetails_.DeliveryMethod = DetailsToFillIn.DeliveryMethod;
			EndIf;
			
			If ValueIsFilled(DetailsToFillIn.DeliveryMethod) Then
				
				FillInDetailsOfDeliveryMethod(FormItems, DeliveryDetails_);
				
				If (DeliveryDetails_.DeliveryMethod = Enums.TransportMethods.ByCarrierToAddress
						Or DeliveryDetails_.DeliveryMethod = Enums.TransportMethods.ByCarrierToTransferPoint)
					And ValueIsFilled(DeliveryDetails_.CarrierPartner) Then
					FillInCarrierAddressSelectionList(FormItems, DeliveryDetails_);
					FillInCarrierDetails(FormItems, DeliveryDetails_);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	FillPropertyValues(DocObject, DeliveryDetails_);
	
	If FormItems.Find("DeliveryPages") <> Undefined Then
		
		OrderByAgreement = ThisIsOrderByAgreement(DocObject);
		ThisIsContractAgreement = TypeOf(DocObject.Ref) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(DocObject.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors");
		
		DeliveryIsDefinedInContract = DeliveryIsDefinedInContract(DocObject);
		
		OrderUnderAgreement = Not ThisIsContractAgreement And DeliveryIsDefinedInContract;
		
		GoodsDeliveryClientServer.SetDeliveryPage(FormItems,
			DocObject.DeliveryMethod,
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"),
			OrderByAgreement,
			OrderUnderAgreement);
		
	EndIf;
	
	SpecialConditionsOfCarriageAndAccessibility(FormItems, DocObject);
	
EndProcedure

// Re-fills in the delivery details when the form details are changed.
//
// Parameters:
//	FormItems - FormAllItems - all elements of the form where changes are made,
//	DocObject - FormDataStructure, CatalogObject - the object whose details are used when filling in the form,
//	FillParameters - See ParametersForFillingInBankingDetails.
//
Procedure WhenChangingRecipientDoNotUseDeliveryManagement(FormItems, DocObject, FillParameters)
	
	If Not ReFillInDeliveryAddressInSalesDocument(DocObject) Then
		Return;
	EndIf;
	
	DeliveryDetails_ = DeliveryDetails_(DocObject);
	
	RecipientSender = DeliveryDetails_.RecipientSender;
	
	ElementNameAddress = ElementNameAddress(FormItems);
	If FillParameters.ClearDeliveryDetails Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(FormItems, DeliveryDetails_);
	EndIf;
	
	If ValueIsFilled(RecipientSender.Value) Then
		
		FillInListsForSelectingRecipientSenderAddresses(FormItems, DeliveryDetails_);
		If FormItems[ElementNameAddress].ChoiceList.Count() > 0 And FillParameters.SetDeliveryAddress Then
			FirstStructureInList = FormItems[ElementNameAddress].ChoiceList[0].Value;
			DeliveryDetails_.DeliveryAddress = FirstStructureInList.DeliveryAddress;
			DeliveryDetails_.DeliveryAddressFieldValues = FirstStructureInList.DeliveryAddressFieldValues;
		EndIf;
		
	EndIf;
	
	FillPropertyValues(DocObject, DeliveryDetails_);
	
EndProcedure

#Region Other

// Parameters:
//  Address - String - Temporary storage address
// 
// Returns:
//  Arbitrary, Undefined -
Function GetDeleteFromTempStorage(Address) Export
	
	Result = Undefined;
	
	If Not IsTempStorageURL(Address) Then
		Return Result;
	EndIf;
	
	Result = GetFromTempStorage(Address);
	
	DeleteFromTempStorage(Address);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion