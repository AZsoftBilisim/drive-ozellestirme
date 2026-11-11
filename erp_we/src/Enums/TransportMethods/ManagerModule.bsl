//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the Presentation of the transmitted delivery method.
//
// Parameters:
//   DeliveryMethod - EnumRef.TransportMethods - the shipping method for receiving the Presentation.
//
// Returns:
//   String - representation of the delivery method.
//
Function PresentationOfShippingMethod(DeliveryMethod) Export

	PresentationsOfShippingMethods = PresentationsOfShippingMethods();
	
	PresentationOfShippingMethod = PresentationsOfShippingMethods[DeliveryMethod];
	If PresentationOfShippingMethod = Undefined Then
		PresentationOfShippingMethod = String(DeliveryMethod);
	EndIf;
	
	Return PresentationOfShippingMethod;

EndFunction

#EndRegion

#Region Private

// Delivery method Presentation constructor.
//
// Returns:
//   Map - list of Presentations:
//    * Key - EnumRef.TransportMethods - delivery method.
//    * Value - String - representation of the delivery method.
//
Function PresentationsOfShippingMethods()

	PresentationsOfShippingMethods = New Map;
	
	PresentationsOfShippingMethods.Insert(Enums.TransportMethods.SelfPickup,
											NStr("vi = 'Khách hàng tự vận chuyển (từ kho của chúng ta)';
												|ru = 'Самовывоз (с нашего склада)';
												|en = 'Pickup from warehouse'; fa = 'برداشت از انبار';
												|it = 'Ritiro (dal nostro magazzino)';
												|pl = 'Odbiór osobisty (z naszego magazynu)';
												|tr = 'İş yerinde teslim (ambarımızdan)'"));
	PresentationsOfShippingMethods.Insert(Enums.TransportMethods.ToCustomer,
											NStr("vi = 'Vận chuyển đến khách hàng';
												|ru = 'Наша транспортная служба до клиента';
												|en = 'In-house carrier'; fa = 'حمل‌کننده داخلی';
												|it = 'Il nostro servizio di trasporto fino al cliente';
												|pl = 'Nasza służba transportowa do klienta';
												|tr = 'Müşteriye taşıma hizmetimiz'"));
	PresentationsOfShippingMethods.Insert(Enums.TransportMethods.ByCarrierToAddress,
											NStr("vi = 'Chuyển hàng đến bên vận chuyển';
												|ru = 'Наша транспортная служба до перевозчика';
												|en = 'In-house carrier (delivery to shipping company)'; fa = 'حمل‌کننده داخلی (تحویل به شرکت حمل‌ونقل)';
												|it = 'Il nostro servizio di trasporto al vettore';
												|pl = 'Nasza służba transportowa do przewoźnika';
												|tr = 'Taşıyıcıya ulaşım hizmetimiz'"));
	PresentationsOfShippingMethods.Insert(Enums.TransportMethods.ByCarrier,
											NStr("vi = 'Bên vận chuyển đến kho lấy hàng';
												|ru = 'Перевозчик (с нашего склада)';
												|en = 'Outsourced carrier'; fa = 'حمل‌کننده برون‌سپاری‌شده';
												|it = 'Vettore (dal nostro magazzino)';
												|pl = 'Przewoźnik (z naszego magazynu)';
												|tr = 'Taşıyıcı (ambarımızdan)'"));
	PresentationsOfShippingMethods.Insert(Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany,
											NStr("vi = 'Theo quyết định của bộ phận vận chuyển';
												|ru = 'На усмотрение транспортной службы';
												|en = 'Define later'; fa = 'بعداً تعیین شود';
												|it = 'Per scelta del servizio di trasporti';
												|pl = 'Według uznania służby transportowej';
												|tr = 'Taşıma hizmetinin takdirine bağlı olarak'"));
	
	Return PresentationsOfShippingMethods;

EndFunction

#EndRegion

#EndIf