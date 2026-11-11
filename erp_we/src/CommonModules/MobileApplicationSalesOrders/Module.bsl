////////////////////////////////////////////////////////////////////////////////
// THE MODULE CONTAINS PROCEDURES AND FUNCTIONS FOR WORKING WITH EXCHANGE PACKAGES WITH THE MOBILE APPLICATION "1C:ORDERS"
// - unloading exchange objects
// - loading exchange objects
// - setting up exchange nodes
// - sending push notifications
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region DataExport

// Returns an exchange message with information about tasks for the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the non-changeable code of this mobile app
//    is used as the code of the exchange plan node.
//
// Returns:
//  XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UploadTasks(MobileDeviceId) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
	
	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Gửi nhiệm vụ';
											|ru = 'Отправка заданий';
											|en = 'Send jobs'; fa = 'Send jobs';
											|it = 'Invio dei task';
											|pl = 'Wysłanie zadań';
											|tr = 'Görevlerin iletilmesi'",
		Common.DefaultLanguageCode()));
		
	ExchangeMessage = "";
	Cancel = False;
	GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel, 5);
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	
	Return WSResponse(ResponseStructure);
EndFunction

// Returns an exchange message with customer information for the mobile app.
// If the passed parameter "All Clients" = True, all elements of the "Partners" Catalog are registered,
// if the passed parameter "Unique identifier" is not empty,
// only one object will be registered using the passed link.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  AllCustomers - Boolean - flag for registering all elements of the partners directory";
//  UUID - String - 
//    string representation of the unique identifier of the "Partners" directory elements";
//  DataAddress - String - address(name of the temporary file) of the prepared data for exchange.
//
// Returns:
//  XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UnloadClients(MobileDeviceId, AllCustomers, UUID, DataAddress) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId);
		
	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Gửi khách hàng';
											|ru = 'Отправка клиентов';
											|en = 'Send customers'; fa = 'Send customers';
											|it = 'Invio dei clienti';
											|pl = 'Wysłanie Klientów';
											|tr = 'Müşterilerin iletilmesi'",
		Common.DefaultLanguageCode()));
	
	ExchangeMessage = "";
	Cancel = False;
	If Not ValueIsFilled(DataAddress) Then
		MobileApplicationSalesOrdersOverridable.RegisterCustomerChangesForExchangePlan(ExchangeNode,
		AllCustomers, UUID, Cancel, ExchangeMessage);
	Else
		ResponseStructure.ResultMessage = DataAddress;
	EndIf;
	
	If Not Cancel Then
		If ValueIsFilled(UUID) Then
			GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel, 6, , ResponseStructure);
		Else
			GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel, 3, , ResponseStructure);
		EndIf;
	EndIf;
	
	If ResponseStructure.Continue Then
		DataAddress = ResponseStructure.ResultMessage;
	EndIf;
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure);
EndFunction

// Returns an exchange message with information about the app settings for the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the non-changeable code of this mobile app
//    is used as the code of the exchange plan node.
//
// Returns:
//  XDTODataObject - Settings (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function ExportSettings(MobileDeviceId) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
	
	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Gửi tùy chỉnh';
											|ru = 'Отправка настроек';
											|en = 'Send settings'; fa = 'Send settings';
											|it = 'Invio delle impostazioni';
											|pl = 'Wysłanie ustawień';
											|tr = 'Ayarların iletilmesi'",
		Common.DefaultLanguageCode()));
	
	MobileApplicationSalesOrdersOverridable.UploadSettingsForSharing(ExchangeNode, ResponseStructure);
	
	Return WSResponse(ResponseStructure, "Settings");
EndFunction

// Returns an exchange message with information about item balances for the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  DataAddress - String - address(name of the temporary file) of the prepared data for exchange.
//
// Returns:
//  XDTODataObject - Settings (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UnloadBalance(MobileDeviceId, DataAddress) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
		
	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Gửi số dư trong kho bãi';
											|ru = 'Отправка остатков на складах';
											|en = 'Send stocks'; fa = 'Send stocks';
											|it = 'Invio delle rimanenze nei magazzini';
											|pl = 'Wysłanie pozostałości w magazynach';
											|tr = 'Stok bakiyelerinin iletilmesi'",
		Common.DefaultLanguageCode()));
	
	If ValueIsFilled(DataAddress) Then
		ResponseStructure.ResultMessage = DataAddress;
	EndIf;
	
	ExchangeMessage = "";
	Cancel = False;
	GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel, 2,, ResponseStructure);
	If ResponseStructure.Continue Then
		DataAddress = ResponseStructure.ResultMessage;
	EndIf;
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure);
EndFunction

// Returns an exchange message with information about item prices based on standard agreements for the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  AllPrices - Boolean - flag for selecting all item prices;
//  DataAddress - String - address(name of the temporary file) of the prepared data for exchange.
//
// Returns:
//  XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UploadPriceList(MobileDeviceId, AllPrices = False, DataAddress = "") Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
	
	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Gửi đơn giá';
											|ru = 'Отправка цен';
											|en = 'Send prices'; fa = 'Send prices';
											|it = 'Invio dei prezzi';
											|pl = 'Wysłanie cen';
											|tr = 'Fiyatların iletilmesi'",
		Common.DefaultLanguageCode()));
	
	If ValueIsFilled(DataAddress) Then
		ResponseStructure.ResultMessage = DataAddress;
	EndIf;
	
	ExchangeMessage = "";
	Cancel = False;
	GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel, 1, AllPrices, ResponseStructure);
	If ResponseStructure.Continue Then
		DataAddress = ResponseStructure.ResultMessage;
	EndIf;
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure);
EndFunction

// Returns an exchange message with information about directories for the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the non-changeable code of this mobile app
//    is used as the code of the exchange plan node.
//
// Returns:
//  XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UploadCatalogs(MobileDeviceId) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
	
	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Gửi danh mục chính';
											|ru = 'Отправка основных справочников';
											|en = 'Send main catalogs'; fa = 'Send main catalogs';
											|it = 'Invio dei cataloghi principali';
											|pl = 'Wysłanie katalogów podstawowych';
											|tr = 'Temel dizinlerin iletilmesi'",
		Common.DefaultLanguageCode()));
	
	ExchangeMessage = "";
	Cancel = False;
	GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel);
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure);
EndFunction

// Returns an exchange message with information about the current document statuses.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  ExchangeMessage - XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange);
//  DocumentType - Number - defines the document type.
//
// Returns:
//  XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UploadDocumentStatuses(MobileDeviceId, ExchangeMessage, DocumentType) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure, 
		MobileDeviceId);
		
	Cancel = False;
	ResponseMessage_ = "";
	If ExchangeNode = Undefined Then
		ResponseMessage_ = NStr("vi = 'Không tìm thấy nút trao đổi đối với thiết bị %MobileDeviceId%.';
								|ru = 'Не найден узел обмена для устройства %MobileDeviceId%.';
								|en = 'Exchange node is not found for device %MobileDeviceId%.'; fa = 'Exchange node is not found for device %MobileDeviceId%.';
								|it = 'Non è stato trovato un nodo di scambio per l''apparecchio %MobileDeviceId%.';
								|pl = 'Nie jest znaleziony węzeł wymiany dla urządzenia %MobileDeviceId%.';
								|tr = '%MobileDeviceId% cihazı için değişim düğümü bulunamadı.'");
		ResponseMessage_ = StrReplace(ExchangeMessage, "%MobileDeviceId%", 
			MobileDeviceId);
		Cancel = True;
	Else
		IDs = DocumentIDsFromMessage(ExchangeMessage.ResultMessage, DocumentType);
		ResponseMessage_ = GeneratedResponseDocumentStatuses(IDs, ExchangeNode, DocumentType);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataExport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataExport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	CommentOnExchange = "";
	If DocumentType = 0 Then
		CommentOnExchange = NStr("vi = 'Gửi trạng thái đơn hàng của khách';
								|ru = 'Отправка состояния заказов клиентов';
								|en = 'Send sales order state'; fa = 'Send sales order state';
								|it = 'Invio dello stato degli ordini dei clienti';
								|pl = 'Wysłanie statusu zamówień klientów';
								|tr = 'Müşteri siparişlerinin durumunun gönderilmesi'",
			Common.DefaultLanguageCode());
	ElsIf DocumentType = 1 Then
		CommentOnExchange = NStr("vi = 'Gửi trạng thái giấy đề nghị trả lại';
								|ru = 'Отправка состояния заявок на возврат';
								|en = 'Send return request state'; fa = 'Send return request state';
								|it = 'Invio dello stato dei reclami di reso';
								|pl = 'Wysłanie statusu wniosków o zwrot';
								|tr = 'İade taleplerinin durumunun gönderilmesi'",
			Common.DefaultLanguageCode());
	EndIf;
	ResponseStructure.Insert("Comment", CommentOnExchange);
	
	ResponseStructure.ResultMessage = ResponseMessage_;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure);
EndFunction

#EndRegion

#Region DataImport

// Returns an exchange message with information about recording tasks from the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  ExchangeMessage - String - the information for the record;
//  TaskSettings - XDTODataObject - JobTargetSettings (http://www.1c.ru/CustomerOrders/Exchange),
//    settings for the use of tasks by sales representatives.
//
// Returns:
//  XDTODataObject - Permit (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function UploadTasksToSalesRepresentatives(MobileDeviceId, ExchangeMessage, TaskSettings) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
		
	Cancel = False;
	If ExchangeNode = Undefined Then
		ExchangeMessage = NStr("vi = 'Không tìm thấy nút trao đổi đối với thiết bị %MobileDeviceId%.';
								|ru = 'Не найден узел обмена для устройства %MobileDeviceId%.';
								|en = 'Exchange node is not found for device %MobileDeviceId%.'; fa = 'Exchange node is not found for device %MobileDeviceId%.';
								|it = 'Non è stato trovato un nodo di scambio per l''apparecchio %MobileDeviceId%.';
								|pl = 'Nie jest znaleziony węzeł wymiany dla urządzenia %MobileDeviceId%.';
								|tr = '%MobileDeviceId% cihazı için değişim düğümü bulunamadı.'");
		ExchangeMessage = StrReplace(ExchangeMessage, "%MobileDeviceId%", 
			MobileDeviceId);
		Cancel = True;
	Else
		ExchangeMessage = ExchangeMessage.ResultMessage;
		ExchangePacketReadingOptions = ExchangePacketReadingOptions();
		ExchangePacketReadingOptions.ObjectType = 3;
		ExchangePacketReadingOptions.TaskSettings = TaskSettings;
		ReadExchangePackage(ExchangeNode, ExchangeMessage, Cancel, ExchangePacketReadingOptions);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Nhận nhiệm vụ';
											|ru = 'Получение заданий';
											|en = 'Receive jobs'; fa = 'Receive jobs';
											|it = 'Ricezione dei task';
											|pl = 'Pobieranie zadań';
											|tr = 'Görevlerin teslim alınması'",
		Common.DefaultLanguageCode()));
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure, "MessageExchange");
EndFunction

// Returns an exchange message with information about recording orders from the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  ExchangeMessage - String - data to be written.
//
// Returns:
//  XDTODataObject - Permit (http://www.1c.ru / CustomerOrders/Exchange) - generated exchange message.
//
Function UploadCustomerOrders(MobileDeviceId, ExchangeMessage) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
		
	Cancel = False;
	If ExchangeNode = Undefined Then
		ExchangeMessage = NStr("vi = 'Không tìm thấy nút trao đổi đối với thiết bị %MobileDeviceId%.';
								|ru = 'Не найден узел обмена для устройства %MobileDeviceId%.';
								|en = 'Exchange node is not found for device %MobileDeviceId%.'; fa = 'Exchange node is not found for device %MobileDeviceId%.';
								|it = 'Non è stato trovato un nodo di scambio per l''apparecchio %MobileDeviceId%.';
								|pl = 'Nie jest znaleziony węzeł wymiany dla urządzenia %MobileDeviceId%.';
								|tr = '%MobileDeviceId% cihazı için değişim düğümü bulunamadı.'");
		ExchangeMessage = StrReplace(ExchangeMessage, "%MobileDeviceId%", 
			MobileDeviceId);
		Cancel = True;
	Else
		ExchangeMessage = ExchangeMessage.ResultMessage;
		ExchangePacketReadingOptions = ExchangePacketReadingOptions();
		ReadExchangePackage(ExchangeNode, ExchangeMessage, Cancel, ExchangePacketReadingOptions);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Nhận đơn hàng';
											|ru = 'Получение заказов';
											|en = 'Receive orders'; fa = 'Receive orders';
											|it = 'Ricezione degli ordini';
											|pl = 'Otrzymanie zamówień';
											|tr = 'Siparişlerin alınması'",
		Common.DefaultLanguageCode()));
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure, "MessageExchange");
EndFunction

// Returns an exchange message with information about recording requests for product returns from the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  ExchangeMessage - String - data to be written.
//
// Returns:
//  XDTODataObject - Permit (http://www.1c.ru / CustomerOrders/Exchange) - generated exchange message.
//
Function UploadRequestsForReturnOfGoodsFromClient(MobileDeviceId, ExchangeMessage) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
		
	Cancel = False;
	If ExchangeNode = Undefined Then
		ExchangeMessage = NStr("vi = 'Không tìm thấy nút trao đổi đối với thiết bị %MobileDeviceId%.';
								|ru = 'Не найден узел обмена для устройства %MobileDeviceId%.';
								|en = 'Exchange node is not found for device %MobileDeviceId%.'; fa = 'Exchange node is not found for device %MobileDeviceId%.';
								|it = 'Non è stato trovato un nodo di scambio per l''apparecchio %MobileDeviceId%.';
								|pl = 'Nie jest znaleziony węzeł wymiany dla urządzenia %MobileDeviceId%.';
								|tr = '%MobileDeviceId% cihazı için değişim düğümü bulunamadı.'");
		ExchangeMessage = StrReplace(ExchangeMessage, "%MobileDeviceId%", 
			MobileDeviceId);
		Cancel = True;
	Else
		ExchangeMessage = ExchangeMessage.ResultMessage;
		ExchangePacketReadingOptions = ExchangePacketReadingOptions();
		ExchangePacketReadingOptions.ObjectType = 4;
		ReadExchangePackage(ExchangeNode, ExchangeMessage, Cancel, ExchangePacketReadingOptions);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Nhận đơn hàng';
											|ru = 'Получение заказов';
											|en = 'Receive orders'; fa = 'Receive orders';
											|it = 'Ricezione degli ordini';
											|pl = 'Otrzymanie zamówień';
											|tr = 'Siparişlerin alınması'",
		Common.DefaultLanguageCode()));
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure, "MessageExchange");
EndFunction

// Returns an exchange message with information about recording orders from the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  ExchangeMessage - String - data to be written.
//
// Returns:
//  XDTODataObject - Permit (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function LoadingCustomerPayments(MobileDeviceId, ExchangeMessage) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
		
	Cancel = False;
	If ExchangeNode = Undefined Then
		ExchangeMessage = NStr("vi = 'Không tìm thấy nút trao đổi đối với thiết bị %MobileDeviceId%.';
								|ru = 'Не найден узел обмена для устройства %MobileDeviceId%.';
								|en = 'Exchange node is not found for device %MobileDeviceId%.'; fa = 'Exchange node is not found for device %MobileDeviceId%.';
								|it = 'Non è stato trovato un nodo di scambio per l''apparecchio %MobileDeviceId%.';
								|pl = 'Nie jest znaleziony węzeł wymiany dla urządzenia %MobileDeviceId%.';
								|tr = '%MobileDeviceId% cihazı için değişim düğümü bulunamadı.'");
		ExchangeMessage = StrReplace(ExchangeMessage, "%MobileDeviceId%", 
			MobileDeviceId);
		Cancel = True;
	Else
		ExchangeMessage = ExchangeMessage.ResultMessage;
		ExchangePacketReadingOptions = ExchangePacketReadingOptions();
		ExchangePacketReadingOptions.ObjectType = 2;
		ReadExchangePackage(ExchangeNode, ExchangeMessage, Cancel, ExchangePacketReadingOptions);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Nhận xác nhận thanh toán';
											|ru = 'Получение регистрации оплат';
											|en = 'Receipt of payment registration'; fa = 'Receipt of payment registration';
											|it = 'Ricezione delle registrazioni dei pagamenti';
											|pl = 'Otrzymanie rejestracji płatności';
											|tr = 'Ödeme kaydının alınması'",
		Common.DefaultLanguageCode()));
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure, "MessageExchange");
EndFunction

// Returns an exchange message with information about a directory entry from the mobile app.
//
// Parameters:
//  MobileDeviceId - String - the code of this mobile app that cannot be changed
//    is used as the code of the exchange plan node;
//  ExchangeMessage - String - data to be written.
//
// Returns:
//  XDTODataObject - Permit (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function DownloadCatalogs(MobileDeviceId, ExchangeMessage) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
		
	Cancel = False;
	If ExchangeNode = Undefined Then
		ExchangeMessage = NStr("vi = 'Không tìm thấy nút trao đổi đối với thiết bị %MobileDeviceId%.';
								|ru = 'Не найден узел обмена для устройства %MobileDeviceId%.';
								|en = 'Exchange node is not found for device %MobileDeviceId%.'; fa = 'Exchange node is not found for device %MobileDeviceId%.';
								|it = 'Non è stato trovato un nodo di scambio per l''apparecchio %MobileDeviceId%.';
								|pl = 'Nie jest znaleziony węzeł wymiany dla urządzenia %MobileDeviceId%.';
								|tr = '%MobileDeviceId% cihazı için değişim düğümü bulunamadı.'");
		ExchangeMessage = StrReplace(ExchangeMessage, "%MobileDeviceId%",
			MobileDeviceId);
		Cancel = True;
	Else
		ExchangeMessage = ExchangeMessage.ResultMessage;
		ExchangePacketReadingOptions = ExchangePacketReadingOptions();
		ExchangePacketReadingOptions.Transactioned = True;
		ExchangePacketReadingOptions.ObjectType = 1;
		ReadExchangePackage(ExchangeNode, ExchangeMessage, Cancel, ExchangePacketReadingOptions);
	EndIf;
	
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Nhận danh mục';
											|ru = 'Получение справочников';
											|en = 'Receive catalogs'; fa = 'Receive catalogs';
											|it = 'Ricezione dei cataloghi';
											|pl = 'Otrzymanie katalogów';
											|tr = 'Dizinlerin alınması'",
		Common.DefaultLanguageCode()));
	
	ResponseStructure.ResultMessage = ExchangeMessage;
	ResponseStructure.Success = Not Cancel;
	Return WSResponse(ResponseStructure, "MessageExchange");
EndFunction

#EndRegion

#Region ExchangeSettings

// Fills in the linker settings based on the passed source, layout, and settings.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - data settings linker where you need to fill in the settings;
//  Source - Arbitrary - metadata object that contains the layout of the data layout;
//  TemplateName - String - name of the layout that contains the layout diagram;
//  CompositionSettings - DataCompositionSettings - settings to fill in.
//
Procedure FillInComposerSettings(SettingsComposer, Source, TemplateName = "CompositionSchemaOfExchangeSettings", CompositionSettings = Undefined) Export
	
	If Source = Undefined Then
		Return;
	EndIf;
	
	CompositionSchema = Source.GetTemplate(TemplateName);
	If CompositionSettings = Undefined Then
		CompositionSettings = CompositionSchema.DefaultSettings;
	EndIf;
	URLSchemes = PutToTempStorage(CompositionSchema, New UUID());
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(URLSchemes));
	SettingsComposer.LoadSettings(CompositionSettings);
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	MatchesOfSelectionElements = Source.MatchingSelectionElementsToFunctionalOptions();
	SetComposerSelectionsByFunctionalOptions(SettingsComposer, MatchesOfSelectionElements);
EndProcedure

// Returns the ID of the user setting.
//
// Parameters:
//  TagName - String - name of the user settings element;
//  SettingsComposer - DataCompositionSettingsComposer - data settings linker where the search is performed;
//  Source - Arbitrary - metadata object that contains the layout of the data layout;
//  TemplateName - String - name of the layout that contains the layout diagram.
//
// Returns:
//  String - ID of the setting.
//
Function UserSettingID(TagName, SettingsComposer, Source, TemplateName) Export
	
	UserConfigurationID = "";
	
	If SettingsComposer.UserSettings.AdditionalProperties.Property(TagName) Then
		UserConfigurationID = SettingsComposer.UserSettings.AdditionalProperties[TagName];
		If ValueIsFilled(UserConfigurationID) Then
			Return UserConfigurationID;
		EndIf;
	EndIf;
	
	CompositionSchema = Source.GetTemplate(TemplateName);
	CompositionSettings = CompositionSchema.DefaultSettings;
	ArrayOfSelectionFields_ = CommonClientServer.FindFilterItemsAndGroups(CompositionSettings.Filter, TagName);
	For Each FoundItem In ArrayOfSelectionFields_ Do
		UserConfigurationID = FoundItem.UserSettingID;
	EndDo;
	
	Return UserConfigurationID;
EndFunction

// Returns the details of the exchange plan node.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - the site plan of exchange.
//
// Returns:
//  Structure - details of the exchange node.
//
Function NodeAttributes(ExchangeNode) Export
	
	NodeAttributes = Common.ObjectAttributesValues(ExchangeNode,
	"ReceivedNo, SentNo, PrefixForMobileDeviceData, KindExchangeSettings, ExchangeSettings");
	
	If Not ValueIsFilled(NodeAttributes.KindExchangeSettings) Then
		AttributesOfExchangeSetupNode =  NodeAttributes.ExchangeSettings; // ValueStorage
		CompositionSetup = AttributesOfExchangeSetupNode.Get();
	Else
		ExchangeSettingsDetails =
			Common.ObjectAttributeValue(NodeAttributes.KindExchangeSettings, "ExchangeSettings"); // ValueStorage
		CompositionSetup = ExchangeSettingsDetails.Get();
	EndIf;
	
	If CompositionSetup = Undefined Then
		Return NodeAttributes;
	EndIf;
	
	ExchangePlanManager = ExchangePlans[ExchangeNode.Metadata().Name];
	
	DetailsOfMainNode = Common.ObjectAttributesValues(ExchangePlanManager.ThisNode(),
	"PushNotificationOption, GoogleCloudAppsApplicationNumber");
	
	NodeAttributes.Insert("PushNotificationsAreSent",
		ValueIsFilled(DetailsOfMainNode.PushNotificationOption)
		And Not DetailsOfMainNode.PushNotificationOption =
			Enums.PushNotificationOptions.DontSend);
	NodeAttributes.Insert("GoogleCloudAppsApplicationNumber", DetailsOfMainNode.GoogleCloudAppsApplicationNumber);
	
	DataCompositionSettingsComposer = New DataCompositionSettingsComposer;
	FillInComposerSettings(DataCompositionSettingsComposer, ExchangePlanManager,, CompositionSetup);
	
	RequiredAttributes1 = ExchangePlanManager.FormHeaderDetails();
	For Each Attribute In RequiredAttributes1 Do
		NodeAttributes.Insert(Attribute);
	EndDo;
	
	MatchesOfSelectionElements = ExchangePlanManager.MatchingSelectionElementsToFunctionalOptions();
	SetComposerSelectionsToCollectionProps(NodeAttributes, DataCompositionSettingsComposer,
		MatchesOfSelectionElements, RequiredAttributes1);
	Return NodeAttributes;
EndFunction

// Fills in selections from the settings Builder in the collection details.
//
// Parameters:
//  Collection - FormDataCollection, Structure - collection of Bank details;
//  SettingsComposer - DataCompositionSettingsComposer - data settings linker, from which data details are filled in;
//  MatchesOfSelectionElements - Array - array of matches;
//  RequiredAttributes1 - Array - array of installation details.
//
Procedure SetComposerSelectionsToCollectionProps(Collection, SettingsComposer, MatchesOfSelectionElements, RequiredAttributes1) Export
	
	// Dependent on the FO
	For Each Map In MatchesOfSelectionElements Do
		For Each KeyAndValue In Map Do
			AttributeIndex = RequiredAttributes1.Find(KeyAndValue.Value);
			If AttributeIndex = Undefined Then
				Continue;
			Else
				RequiredAttributes1.Delete(AttributeIndex);
			EndIf;
			Use = GetFunctionalOption(KeyAndValue.Key);
			If TypeOf(Collection) = Type("ClientApplicationForm") Then
				Collection[KeyAndValue.Key] = Use;
			EndIf;
			If Use Then
				Collection[KeyAndValue.Value] = SelectionElementValueFromUserSettings(SettingsComposer,
					KeyAndValue.Value);
				DataCompositionServer.RemoveSelectionItemFromAllReportSettings(SettingsComposer,
					KeyAndValue.Value);
			EndIf;
		EndDo;
	EndDo;
	
	// Independent of the FO
	For Each AttributeName In RequiredAttributes1 Do
		Collection[AttributeName] = SelectionElementValueFromUserSettings(SettingsComposer, AttributeName);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(SettingsComposer, AttributeName);
	EndDo;
	
EndProcedure

// Fills in the selection of the settings Builder from the collection details.
//
// Parameters:
//  AttributeName - String - name of the collection's props;
//  Collection - FormDataCollection, Structure - collection of Bank details;
//  SettingsComposer - DataCompositionSettingsComposer - linker for data settings to fill in;
//  Source - Arbitrary - metadata object that contains the layout of the data layout;
//  TemplateName - String - name of the layout that contains the layout diagram.
//
Procedure SetFormPropsToComposerSelections(AttributeName, Collection, SettingsComposer, Source, TemplateName = "CompositionSchemaOfExchangeSettings") Export
	
	If Source = Undefined Then
		Return;
	EndIf;
	
	CommonClientServer.SetFilterItem(SettingsComposer.Settings.Filter,
		AttributeName, Collection[AttributeName], DataCompositionComparisonType.Equal,,
			ValueIsFilled(Collection[AttributeName]),,
			UserSettingID(AttributeName, SettingsComposer, Source, TemplateName));
EndProcedure

// Fills in the selection of the settings Builder with the collection details.
//
// Parameters:
//  Collection - FormDataCollection, Structure - collection of Bank details;
//  SettingsComposer - DataCompositionSettingsComposer - linker for data settings to fill in;
//  Source - Arbitrary - metadata object that contains the layout of the data layout;
//  TemplateName - String - name of the layout that contains the layout diagram.
//
Procedure SetFormPropsToComposerSelections_(Collection, SettingsComposer, Source, TemplateName = "CompositionSchemaOfExchangeSettings") Export
	
	If Source = Undefined Then
		Return;
	EndIf;
	
	InstallationAttributes = Source.FormHeaderDetails();
	For Each InstallationAttribute In InstallationAttributes Do
		SetFormPropsToComposerSelections(InstallationAttribute, Collection, SettingsComposer, Source, TemplateName);
	EndDo;
EndProcedure

#EndRegion

#Region DeliverableNotificationOperations

// Returns the flag for sending push notifications to the mobile device.
//
// Parameters:
//  Recipient - ExchangePlanRef - The node being checked that is configured to sync with the mobile device.
//
// Returns:
//  Boolean - flag for the possibility of sending push notifications.
//
Function SendingIsPossible(Recipient) Export
	
	SendingIsPossible = False;
	SubscriberID_ = Common.ObjectAttributeValue(Recipient,
		"DeliverableNotificationSubscriberID"); // ValueStorage
	If Not SubscriberID_ = Undefined Then
		Id = SubscriberID_.Get();
		If Not Id = Undefined Then
			SendingIsPossible = True;
		EndIf;
	EndIf;
	Return SendingIsPossible;
EndFunction

// Sends push notifications to mobile devices to users of the specified mobile app.
//
// Parameters:
//  NotificationText_ - String - notification text;
//  Recipients - Array - array of notification recipients;
//  RecipientsWithoutDelivery - Array - array of recipients of the notification that it was not sent to;
//  NodeName - String - name of the exchange plan associated with the mobile app.
//
Procedure SendNotification(NotificationText_, Recipients, RecipientsWithoutDelivery, NodeName = "MobileApplicationSalesOrders") Export
	
	Node = ExchangePlans[NodeName].ThisNode();
	
	UsePushNotifications = Node.PushNotificationOption;
	UseAPNS = Node.UseAPNS;
	UseGCM = Node.UseGCM;
	If Not ValueIsFilled(UsePushNotifications)
		Or UsePushNotifications = Enums.PushNotificationOptions.DontSend Then
		RecipientsWithoutDelivery = CommonClientServer.CopyArray(Recipients);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	MobileApplicationSalesOrders.Ref,
	|	MobileApplicationSalesOrders.DeliverableNotificationSubscriberID
	|FROM
	|	&ExchangePlanNodeName AS MobileApplicationSalesOrders
	|WHERE
	|	MobileApplicationSalesOrders.Ref IN(&Recipients)";
	
	Query.Text = StrReplace(Query.Text, "&ExchangePlanNodeName", "ExchangePlan." + NodeName);
	Query.SetParameter("Recipients", Recipients);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		RecipientsWithoutDelivery = CommonClientServer.CopyArray(Recipients);
		Return;
	EndIf;
	
	Notification = New DeliverableNotification;
	Selection = Result.Select();
	While Selection.Next() Do
		DeliverableNotificationSubscriberID = Selection.DeliverableNotificationSubscriberID; // ValueStorage
		If Not DeliverableNotificationSubscriberID = Undefined Then
			Id = DeliverableNotificationSubscriberID.Get();
			If Not Id = Undefined Then
				If UsePushNotifications =
						Enums.PushNotificationOptions.SendViaSupportingService Then
					Notification.Recipients.Add(Id);
				Else
					If ((Id.SubscriberType = DeliverableNotificationSubscriberType.APNS And UseAPNS)
						Or (Id.SubscriberType = DeliverableNotificationSubscriberType.GCM And UseGCM)) Then
						Notification.Recipients.Add(Id);
					Else
						RecipientsWithoutDelivery.Add(Selection.Ref);
					EndIf;
				EndIf;
			Else
				RecipientsWithoutDelivery.Add(Selection.Ref);
			EndIf;
		Else
			RecipientsWithoutDelivery.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	If Notification.Recipients.Count() > 0 Then
		Notification.Text = NotificationText_;
		AuthenticationData = "";
		Certificate = Undefined;
		UseService =
			UsePushNotifications = Enums.PushNotificationOptions.SendViaSupportingService;
		If UseService Then
			AuthenticationData = Node.TransferServiceOfPushNotificationLogin;
		Else
			AuthenticationData = New Map();
			If UseGCM Then
				AuthenticationData[DeliverableNotificationSubscriberType.GCM] = Node.ServerAPIKeySenderGCM;
			EndIf;
			If UseAPNS Then
				Certificate = Node.IOSMobileApplicationCertificate; // ValueStorage
				If Not Certificate = Undefined Then
					Certificate = Certificate.Get();
					If Not Certificate = Undefined Then
						AuthenticationData[DeliverableNotificationSubscriberType.APNS] = Certificate;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		DeletedTokens = New Array;
		Try
			DeliverableNotificationSend.Send(Notification, TrimAll(AuthenticationData),
				DeletedTokens, UseService);
		Except
			Raise(ErrorDescription());
		EndTry;
		DontUseIDs(DeletedTokens);
		
		If Not Certificate = Undefined Then
			DeletedTokens = DeliverableNotificationSend.GetExcludedRecipients(Certificate, UseService);
			DontUseIDs(DeletedTokens);
		EndIf;
	EndIf;
EndProcedure

// Operation for recording the ID of the push notification recipient generated on the mobile device.
//
// Parameters:
//  MobileDeviceId - String - not modified code of a mobile application used as the site code of the exchange;
//  DeliverableNotificationSubscriberID - ValueStorage - ID of the push notification recipient.
//
// Returns:
//  XDTODataObject - MessageExchange (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function RecordSubscriberIDOfDeliveredNotifications(MobileDeviceId, DeliverableNotificationSubscriberID) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	
	SetPrivilegedMode(True);
	ExchangeNodeReference = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());
	
	If ExchangeNodeReference = Undefined Then
		Return WSResponse(ResponseStructure);
	EndIf;
	
	ExchangeNode = ExchangeNodeReference;//ExchangePlanRef - 
		
	ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
	ResponseStructure.Insert("EventLogMessageKey",
		EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
	ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
	ResponseStructure.Insert("StartDate", CurrentSessionDate());
	ResponseStructure.Insert("Comment", NStr("vi = 'Nhận tên định danh đăng ký thông báo đẩy';
											|ru = 'Получение идентификатора подписчика push-уведомлений';
											|en = 'Receive push notification subscriber ID'; fa = 'Receive push notification subscriber ID';
											|it = 'Ricezione dell''identificatore dell''abbonato alle notifiche push';
											|pl = 'Otrzymanie identyfikatora subskrybenta push-zawiadomień';
											|tr = 'Anlık bildirim abone kimliği edinme'",
		Common.DefaultLanguageCode()));
	
	ExchangeNodeObject = ExchangeNode.GetObject();
	NewID1 = XDTOSerializer.ReadXDTO(DeliverableNotificationSubscriberID);
	NewSubscriberID =
		New ValueStorage(NewID1, New Deflation(9));
	ExchangeNodeObject.DeliverableNotificationSubscriberID = NewSubscriberID;
	Try
		ExchangeNodeObject.Write();
	Except
		ResponseStructure.ResultMessage = ErrorDescription();
		ResponseStructure.Success = False;
	EndTry;
	
	Return WSResponse(ResponseStructure, "MessageExchange");
EndFunction

#EndRegion

#Region FunctionsForReturningStructureOfExchangeObjectsOfPackageXDTO_CustomerOrders

// Returns the structure of the "Currencies" mobile app object for exchange.
//
// Returns:
//  Structure
//
Function CurrencyStructure() Export
	
	CurrencyStructure = StandardObjectStructure();
	CurrencyStructure.Insert("Code");
	
	Return CurrencyStructure;
	
EndFunction

// Returns the structure of the "types of contact information" mobile app object for sharing.
//
// Parameters:
//  IsFolder - Boolean - group attribute.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfKiSpecies(Val IsFolder) Export
	
	StructureOfKiSpecies = StandardObjectStructure();
	StructureOfKiSpecies.Insert("IsFolder");
	StructureOfKiSpecies.Insert("Parent");
	StructureOfKiSpecies.Insert("PredefinedDataName");
	StructureOfKiSpecies.Insert("ERPКод"); //@NON-NLS-1
	
	If Not IsFolder Then
	
		StructureOfKiSpecies.Insert("Тип"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("РеквизитДопУпорядочивания"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("РедактированиеТолькоВДиалоге"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("МожноИзменятьСпособРедактирования"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("АдресТолькоРоссийский"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("ВключатьСтрануВПредставление"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("ОбязательноеЗаполнение"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("ПроверятьКорректность"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("СкрыватьНеактуальныеАдреса"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("Подсказка"); //@NON-NLS-1
		StructureOfKiSpecies.Insert("РазрешитьВводНесколькихЗначений"); //@NON-NLS-1
		// Mobile app support up to version 3.0.2.
		StructureOfKiSpecies.Insert("ЗапрещатьВводНекорректного"); //@NON-NLS-1
		
	EndIf;
	
	Return StructureOfKiSpecies;
	
EndFunction

// Returns the structure of the item Types mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfProductType() Export
	
	StructureOfProductType = StandardObjectStructure();
	StructureOfProductType.Insert("IsFolder");
	StructureOfProductType.Insert("Parent");
	
	StructureOfProductType.Insert("ERPКод"); //@NON-NLS-1
	
	Return StructureOfProductType;
	
EndFunction

// Returns the structure of the "types of prices" mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfPriceType() Export
	
	StructureOfPriceType = StandardObjectStructure();
	StructureOfPriceType.Insert("ERPКод"); //@NON-NLS-1
	StructureOfPriceType.Insert("ВалютаЦены"); //@NON-NLS-1
	StructureOfPriceType.Insert("ЦенаВключаетНДС"); //@NON-NLS-1
	
	Return StructureOfPriceType;
	
EndFunction

// Returns the structure of the "customer Contracts" mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfContract() Export
	
	StructureOfContract = StandardObjectStructure();
	StructureOfContract.Insert("ERPКодДоговора"); //@NON-NLS-1
	StructureOfContract.Insert("ERPКодСоглашения"); //@NON-NLS-1
	StructureOfContract.Insert("ВалютаВзаиморасчетов"); //@NON-NLS-1
	StructureOfContract.Insert("ВидЦены"); //@NON-NLS-1
	StructureOfContract.Insert("Дата"); //@NON-NLS-1
	StructureOfContract.Insert("Действует"); //@NON-NLS-1
	StructureOfContract.Insert("Клиент"); //@NON-NLS-1
	StructureOfContract.Insert("Комиссия"); //@NON-NLS-1
	StructureOfContract.Insert("Контрагент"); //@NON-NLS-1
	StructureOfContract.Insert("Номер"); //@NON-NLS-1
	StructureOfContract.Insert("Организация"); //@NON-NLS-1
	StructureOfContract.Insert("Пояснение"); //@NON-NLS-1
	StructureOfContract.Insert("Склад"); //@NON-NLS-1
	StructureOfContract.Insert("УникальныйКлюч"); //@NON-NLS-1
	StructureOfContract.Insert("Типовое"); //@NON-NLS-1
	StructureOfContract.Insert("ЕстьУточнениеЦен"); //@NON-NLS-1
	StructureOfContract.Insert("ИспользуютсяДоговорыКонтрагентов"); //@NON-NLS-1
	StructureOfContract.Insert("ФормаОплаты"); //@NON-NLS-1
	StructureOfContract.Insert("РасчетыПоДоговору"); //@NON-NLS-1
	StructureOfContract.Insert("СуммаДолгаПоДоговору"); //@NON-NLS-1
	
	Return StructureOfContract;
	
EndFunction

// Returns the structure of the "Additional banking details and information" object of the mobile app for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfAdditionalProps() Export
	
	StructureOfAdditionalProps = StandardObjectStructure();
	StructureOfAdditionalProps.Insert("PredefinedDataName");
	StructureOfAdditionalProps.Insert("ПометкаУдаления"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("Наименование"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ИмяПредопределенныхДанных"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("Виден"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ВладелецДополнительныхЗначений"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ДополнительныеЗначенияИспользуются"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ДополнительныеЗначенияСВесом"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("Доступен"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("Заголовок"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ЗаголовокФормыВыбораЗначения"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ЗаголовокФормыЗначения"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ЗаполнятьОбязательно"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("МногострочноеПолеВвода"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("НаборСвойств"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ТипЗначения"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ФорматСвойства"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ЭтоДополнительноеСведение"); //@NON-NLS-1
	StructureOfAdditionalProps.Insert("ЗависимостиДополнительныхРеквизитов"); //@NON-NLS-1
	
	Return StructureOfAdditionalProps;
	
EndFunction

// Returns the structure of the "units of measurement" mobile app object to exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function UnitStructure() Export
	
	UnitStructure = StandardObjectStructure();
	UnitStructure.Insert("Code");
	UnitStructure.Insert("PredefinedDataName");
	UnitStructure.Insert("МеждународноеСокращение"); //@NON-NLS-1
	UnitStructure.Insert("НаименованиеПолное"); //@NON-NLS-1
	
	Return UnitStructure;
	
EndFunction

// Returns the structure of the mobile app object "object property Value"
//  and "object property Value (Hierarchy)" to exchange.
//
// Parameters:
//  Hierarchy - Boolean - hierarchy attribute;
//  IsFolder - Boolean - group attribute.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function ObjectPropertyValueStructure(Hierarchy, IsFolder) Export
	
	ZSOStructure = StandardObjectStructure();
	ZSOStructure.Insert("PredefinedDataName");
	ZSOStructure.Insert("Owner");
	ZSOStructure.Insert("Parent");
	
	If Not Hierarchy Then
		ZSOStructure.Insert("IsFolder");
	EndIf;
	
	If Not IsFolder Then
		ZSOStructure.Insert("Вес"); //@NON-NLS-1
	EndIf;
	
	Return ZSOStructure;
	
EndFunction

// Returns the structure of the "customer Contact persons" mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function ContactPersonStructure() Export
	
	ContactPersonStructure = StandardObjectStructure();
	ContactPersonStructure.Insert("Owner", "");
	ContactPersonStructure.Insert("ERPКод", ""); //@NON-NLS-1
	ContactPersonStructure.Insert("ДатаРождения", Date("00010101")); //@NON-NLS-1
	ContactPersonStructure.Insert("ДолжностьПоВизитке", ""); //@NON-NLS-1
	ContactPersonStructure.Insert("Комментарий", ""); //@NON-NLS-1
	ContactPersonStructure.Insert("КонтактнаяИнформация"); //@NON-NLS-1
	
	Return ContactPersonStructure;
	
EndFunction

// Returns the structure of the "Counterparty" mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function CounterpartyStructure() Export
	
	CounterpartyStructure = StandardObjectStructure();
	CounterpartyStructure.Insert("ERPКод"); //@NON-NLS-1
	CounterpartyStructure.Insert("ИНН"); //@NON-NLS-1
	CounterpartyStructure.Insert("ИННКПП"); //@NON-NLS-1
	CounterpartyStructure.Insert("Клиент"); //@NON-NLS-1
	CounterpartyStructure.Insert("КПП"); //@NON-NLS-1
	CounterpartyStructure.Insert("НаименованиеПолное"); //@NON-NLS-1
	CounterpartyStructure.Insert("ПредставлениеКонтрагента"); //@NON-NLS-1
	CounterpartyStructure.Insert("ЮрФизЛицо"); //@NON-NLS-1
	
	Return CounterpartyStructure;
	
EndFunction

// Returns the structure of the Nomenclature mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function ProductStructure_() Export
	
	ProductStructure_ = StandardObjectStructure();
	ProductStructure_.Insert("IsFolder");
	ProductStructure_.Insert("Parent");
	ProductStructure_.Insert("Code");
	
	ProductStructure_.Insert("ERPКодНоменклатура"); //@NON-NLS-1
	ProductStructure_.Insert("ERPКодХарактеристика"); //@NON-NLS-1
	ProductStructure_.Insert("Артикул"); //@NON-NLS-1
	ProductStructure_.Insert("ВидНоменклатуры"); //@NON-NLS-1
	ProductStructure_.Insert("ЕдиницаЗаказа"); //@NON-NLS-1
	ProductStructure_.Insert("ЕдиницаИзмерения"); //@NON-NLS-1
	ProductStructure_.Insert("НаименованиеПолное"); //@NON-NLS-1
	ProductStructure_.Insert("СтавкаНДСЧислом"); //@NON-NLS-1
	ProductStructure_.Insert("СтрокаПоиска"); //@NON-NLS-1
	ProductStructure_.Insert("Услуга"); //@NON-NLS-1
	ProductStructure_.Insert("ЦеноваяГруппа"); //@NON-NLS-1
	
	ProductStructure_.Insert("ВесЕдиницаИзмерения"); //@NON-NLS-1
	ProductStructure_.Insert("ВесЗнаменатель"); //@NON-NLS-1
	ProductStructure_.Insert("ВесИспользовать"); //@NON-NLS-1
	ProductStructure_.Insert("ВесМожноУказыватьВДокументах"); //@NON-NLS-1
	ProductStructure_.Insert("ВесЧислитель"); //@NON-NLS-1
	ProductStructure_.Insert("Описание"); //@NON-NLS-1
	ProductStructure_.Insert("ФайлКартинки"); //@NON-NLS-1
	
	ProductStructure_.Insert("Штрихкод"); //@NON-NLS-1
	ProductStructure_.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
	
	Return ProductStructure_;
	
EndFunction

// Returns the structure of the Nomenclature mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function ProductStructure_AttachedFiles() Export
	
	ProductStructure_AttachedFiles = StandardObjectStructure();
	ProductStructure_AttachedFiles.Insert("ВладелецФайла"); //@NON-NLS-1
	ProductStructure_AttachedFiles.Insert("ДатаСоздания"); //@NON-NLS-1
	ProductStructure_AttachedFiles.Insert("Описание"); //@NON-NLS-1
	ProductStructure_AttachedFiles.Insert("Размер"); //@NON-NLS-1
	ProductStructure_AttachedFiles.Insert("Расширение"); //@NON-NLS-1
	ProductStructure_AttachedFiles.Insert("ХранимыйФайл"); //@NON-NLS-1
	
	Return ProductStructure_AttachedFiles;
	
EndFunction

// Returns the structure of the "Clients" mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function PartnerStructure() Export
	
	PartnerStructure = StandardObjectStructure();
	PartnerStructure.Insert("Parent");
	PartnerStructure.Insert("Code");
	PartnerStructure.Insert("ERPКод"); //@NON-NLS-1
	PartnerStructure.Insert("ВидЦены"); //@NON-NLS-1
	PartnerStructure.Insert("ВремяДоставкиПо"); //@NON-NLS-1
	PartnerStructure.Insert("ВремяДоставкиС"); //@NON-NLS-1
	PartnerStructure.Insert("ДополнительнаяИнформацияПоДоставке"); //@NON-NLS-1
	PartnerStructure.Insert("ОтгрузкаЗапрещена"); //@NON-NLS-1
	PartnerStructure.Insert("ПричинаДобавленияВСтопЛист"); //@NON-NLS-1
	PartnerStructure.Insert("Самовывоз"); //@NON-NLS-1
	PartnerStructure.Insert("Склад"); //@NON-NLS-1
	PartnerStructure.Insert("СтрокаПоиска"); //@NON-NLS-1
	PartnerStructure.Insert("ФормаОплаты"); //@NON-NLS-1
	PartnerStructure.Insert("ДополнительнаяИнформация"); //@NON-NLS-1
	PartnerStructure.Insert("КонтактнаяИнформация"); //@NON-NLS-1
	PartnerStructure.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
	
	Return PartnerStructure;
	
EndFunction

// Returns the structure of the Organizations mobile app object for sharing.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function OrganizationStructure() Export
	
	OrganizationStructure = StandardObjectStructure();
	OrganizationStructure.Insert("ERPКод"); //@NON-NLS-1
	OrganizationStructure.Insert("Префикс"); //@NON-NLS-1
	OrganizationStructure.Insert("СистемаНалогообложения"); //@NON-NLS-1
	OrganizationStructure.Insert("Руководитель"); //@NON-NLS-1
	OrganizationStructure.Insert("ГлавныйБухгалтер"); //@NON-NLS-1
	OrganizationStructure.Insert("ИНН"); //@NON-NLS-1
	OrganizationStructure.Insert("КПП"); //@NON-NLS-1
	OrganizationStructure.Insert("СвидетельствоСерияНомер"); //@NON-NLS-1
	OrganizationStructure.Insert("СвидетельствоДатаВыдачи"); //@NON-NLS-1
	OrganizationStructure.Insert("НаименованиеПолное"); //@NON-NLS-1
	OrganizationStructure.Insert("ЮрФизЛицо"); //@NON-NLS-1
	
	OrganizationStructure.Insert("НомерСчета"); //@NON-NLS-1
	OrganizationStructure.Insert("Банк"); //@NON-NLS-1
	OrganizationStructure.Insert("БИК"); //@NON-NLS-1
	OrganizationStructure.Insert("ГородБанка"); //@NON-NLS-1
	OrganizationStructure.Insert("КоррСчет"); //@NON-NLS-1
	
	OrganizationStructure.Insert("КонтактнаяИнформация"); //@NON-NLS-1
	OrganizationStructure.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
	
	Return OrganizationStructure;
	
EndFunction

// Returns the structure of the response message to exchange.
//
// Returns:
//  Structure - contains the structure of responses.
//
Function ResponseStructure() Export
	
	ExchangeComponents = New Structure;
	ExchangeComponents.Insert("EventLogMessageKey",
		DataExchangeServer.DataExchangeEventLogEvent());
	
	ExchangeComponents.Insert("CorrespondentNode", Undefined);
	ExchangeComponents.Insert("Comment", "");
	ExchangeComponents.Insert("ActionOnExchange", Undefined);
	ExchangeComponents.Insert("ExchangeExecutionResult", Undefined);
	ExchangeComponents.Insert("StartDate", Date("00010101000000"));
	ExchangeComponents.Insert("EndDate", Date("00010101000000"));
	
	ExchangeComponents.Insert("ResultMessage", "");
	ExchangeComponents.Insert("Success", True);
	ExchangeComponents.Insert("Continue", False);
	
	Return ExchangeComponents;
	
EndFunction

// Returns the structure of the Nomenclature mobile app object to exchange for groups.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfParentProduct() Export
	
	StructureOfParentProduct = StandardObjectStructure();
	StructureOfParentProduct.Insert("IsFolder");
	StructureOfParentProduct.Insert("Parent");
	StructureOfParentProduct.Insert("Code");
	
	StructureOfParentProduct.Insert("ERPКодНоменклатура"); //@NON-NLS-1
	StructureOfParentProduct.Insert("СтрокаПоиска"); //@NON-NLS-1
	
	Return StructureOfParentProduct;
	
EndFunction

// Returns the structure of the Warehouses mobile app object for exchange.
//
// Parameters:
//  IsFolder - Boolean - indicates whether to create a structure for the group.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function WarehouseStructure(Val IsFolder) Export
	
	WarehouseStructure = StandardObjectStructure();
	WarehouseStructure.Insert("IsFolder");
	WarehouseStructure.Insert("Parent");
	WarehouseStructure.Insert("ERPКод"); //@NON-NLS-1
	
	If Not IsFolder Then
		WarehouseStructure.Insert("ГруппаСкладов"); //@NON-NLS-1
		WarehouseStructure.Insert("КонтактнаяИнформация"); //@NON-NLS-1
	EndIf;
	
	Return WarehouseStructure;
	
EndFunction

// Returns the structure of the "Countries of the world" mobile app object for sharing.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function CountryStructure() Export
	
	CountryStructure = StandardObjectStructure();
	CountryStructure.Insert("Code");
	CountryStructure.Insert("PredefinedDataName");
	CountryStructure.Insert("НаименованиеПолное"); //@NON-NLS-1
	CountryStructure.Insert("КодАльфа2"); //@NON-NLS-1
	CountryStructure.Insert("КодАльфа3"); //@NON-NLS-1
	
	Return CountryStructure;
	
EndFunction

// Returns the structure of the mobile application object "Task status to the sales representative" for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfTaskStatusToSalesRepresentative() Export
	
	Structure = New Structure();
	Structure.Insert("ref");
	Structure.Insert("Статус"); //@NON-NLS-1
	Structure.Insert("ПечатнаяФормаЗаказа"); //@NON-NLS-1
	
	Return Structure;
	
EndFunction

// Returns the structure of the mobile application object "Order status to the client" for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfCustomerSOrderStatus() Export
	
	Structure = New Structure();
	Structure.Insert("ref", "");
	Structure.Insert("Статус", ""); //@NON-NLS-1
	Structure.Insert("Проведен", False); //@NON-NLS-1
	Structure.Insert("ПометкаУдаления", False); //@NON-NLS-1
	Structure.Insert("Состояние", ""); //@NON-NLS-1
	Structure.Insert("Просрочен", False); //@NON-NLS-1
	Structure.Insert("ДатаОтгрузки", Date("00010101000000")); //@NON-NLS-1
	Structure.Insert("Изменен", False); //@NON-NLS-1
	Structure.Insert("СуммаДолгаПоДокументуУП", 0); //@NON-NLS-1
	Structure.Insert("ПечатнаяФормаДокумента", 
		New ValueStorage(New SpreadsheetDocument, New Deflation(9))); //@NON-NLS-1
	
	Structure.Insert("СуммаДокументаУП", 0); //@NON-NLS-1
	Structure.Insert("СуммаНДСДокументаУП", 0); //@NON-NLS-1
	Structure.Insert("ДатаСледующегоПлатежа", Date("00010101000000")); //@NON-NLS-1
	Structure.Insert("ДатаПредоплатыПоДокументу", Date("00010101000000")); //@NON-NLS-1
	Structure.Insert("СуммаПредоплатыПоДокументу", 0); //@NON-NLS-1
	
	//+ UP 2.2.
	Structure.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
	//- ERP 2.2.
	
	Return Structure;
	
EndFunction

// Returns the structure of the "Refund Request Status" object of the mobile application for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function StructureOfRefundRequestStatus() Export
	
	Structure = New Structure();
	Structure.Insert("ref", "");
	Structure.Insert("Статус", ""); //@NON-NLS-1
	Structure.Insert("Проведен", False); //@NON-NLS-1
	Structure.Insert("ПометкаУдаления", False); //@NON-NLS-1
	Structure.Insert("Состояние", ""); //@NON-NLS-1
	Structure.Insert("ДатаПоступления", Date("00010101000000")); //@NON-NLS-1
	Structure.Insert("ДатаОтгрузки", Date("00010101000000")); //@NON-NLS-1
	Structure.Insert("Изменен", False); //@NON-NLS-1
	Structure.Insert("СуммаДокументаУП", 0); //@NON-NLS-1
	Structure.Insert("СуммаНДСДокументаУП", 0); //@NON-NLS-1
	Structure.Insert("СуммаДолгаПоДокументуУП", 0); //@NON-NLS-1
	Structure.Insert("ПечатнаяФормаДокумента", 
		New ValueStorage(New SpreadsheetDocument, New Deflation(9))); //@NON-NLS-1
		
	//+ UP 2.2.
	Structure.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
	//- ERP 2.2.
	
	Return Structure;
	
EndFunction

// Returns the structure of the "Packages" mobile app object for sharing.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function PackingStructure() Export
	
	PackingStructure = StandardObjectStructure();
	PackingStructure.Insert("Owner");
	PackingStructure.Insert("Parent");
	PackingStructure.Insert("ERPКод"); //@NON-NLS-1
	PackingStructure.Insert("ЕдиницаИзмерения"); //@NON-NLS-1
	PackingStructure.Insert("Коэффициент"); //@NON-NLS-1
	PackingStructure.Insert("НаименованиеПолное"); //@NON-NLS-1
	PackingStructure.Insert("Вес"); //@NON-NLS-1
	PackingStructure.Insert("ВесЕдиницаИзмерения"); //@NON-NLS-1
	PackingStructure.Insert("Штрихкод"); //@NON-NLS-1
		
	Return PackingStructure;
	
EndFunction

// Returns the structure of the "Price groups" mobile app object for exchange.
//
// Returns:
//  Structure - contains the structure of the details.
//
Function PriceGroupStructure() Export
	
	PriceGroupStructure = StandardObjectStructure();
	PriceGroupStructure.Insert("Описание"); //@NON-NLS-1
	
	Return PriceGroupStructure;
	
EndFunction

#EndRegion

#Region AuxiliaryFunctions

// Returns a description of the types of additional details that are involved in the exchange.
//
// Returns:
//  TypeDescription - description of value types.
//
Function DescriptionOfValueTypesAndProps() Export
	
	Array = New Array;
	Array.Add(Type("Boolean"));
	Array.Add(Type("Date"));
	Array.Add(Type("String"));
	Array.Add(Type("Number"));
	Array.Add(Type("CatalogRef.ObjectsPropertiesValues"));
	Array.Add(Type("CatalogRef.ObjectPropertyValueHierarchy"));
	
	Return New TypeDescription(Array);
	
EndFunction

// Returns the request text for the client's contact persons.
//
// Returns:
//  String - the text of the request for contact persons.
//
Function RequestTextOfClientSContactPersons() Export
	
	QueryText = 
	"SELECT ALLOWED
	|	ContactPersonsForPartners.Ref AS ContactPerson,
	|	ContactPersonsForPartners.DeletionMark AS DeletionMark,
	|	ContactPersonsForPartners.Description AS Description,
	|	&OwnerCode AS Owner,
	|	"""" AS ERPCode,
	|	ContactPersonsForPartners.Comment,
	|	ContactPersonsForPartners.JobTitleOnBusinessCard,
	|	ContactPersonsForPartners.BirthDate
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner = &Partner";
	
	Return QueryText;
EndFunction

// Returns the text of the contract search query.
//
// Returns:
//  String - the text of the contract search query.
//
Function AgreementSearchRequestText() Export
	
	QueryText = 
	"SELECT ALLOWED
	|	0 AS Priority,
	|	CounterpartyContracts.Ref AS Contract
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND CounterpartyContracts.Approved
	|	AND CounterpartyContracts.Number = &Number
	|	AND CounterpartyContracts.Date = &Date
	|	AND CounterpartyContracts.Partner = &Partner
	|	AND CounterpartyContracts.Partner.ServedBySalesRepresentatives
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND CounterpartyContracts.Approved
	|	AND CounterpartyContracts.Number = &Number
	|	AND CounterpartyContracts.Date = &Date
	|	AND CounterpartyContracts.Partner = &Partner
	|	AND CounterpartyContracts.Partner.ServedBySalesRepresentatives
	|	AND NOT CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND CounterpartyContracts.Approved
	|	AND CounterpartyContracts.Number = &Number
	|	AND CounterpartyContracts.Partner = &Partner
	|	AND NOT CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND CounterpartyContracts.Approved
	|	AND CounterpartyContracts.Partner = &Partner
	|	AND NOT CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND CounterpartyContracts.Approved
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND NOT CounterpartyContracts.Approved
	|	AND CounterpartyContracts.Number = &Number
	|	AND CounterpartyContracts.Date = &Date
	|
	|ORDER BY
	|	Priority";
	
	Return QueryText;
EndFunction

// Returns the text of the search query for individual agreements.
//
// Returns:
//  String - the text of the individual agreement search query.
//
Function TextOfSearchQueryForIndividualAgreements() Export
	QueryText = 
	"SELECT ALLOWED
	|	0 AS Priority,
	|	TermsOfSale.Ref AS Terms,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND NOT TermsOfSale.Standard_
	|	AND TermsOfSale.Partner = &Partner
	|	AND TermsOfSale.Organization = &Organization
	|	AND TermsOfSale.PricesKind = &PricesKind
	|	AND TermsOfSale.Counterparty = &Counterparty
	|	AND TermsOfSale.Warehouse = &Warehouse
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND NOT TermsOfSale.Standard_
	|	AND TermsOfSale.Partner = &Partner
	|	AND TermsOfSale.Organization = &Organization
	|	AND TermsOfSale.PricesKind = &PricesKind
	|	AND TermsOfSale.Counterparty = &Counterparty
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND NOT TermsOfSale.Standard_
	|	AND TermsOfSale.Partner = &Partner
	|	AND TermsOfSale.Organization = &Organization
	|	AND TermsOfSale.PricesKind = &PricesKind
	|	AND NOT TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND NOT TermsOfSale.Standard_
	|	AND TermsOfSale.Partner = &Partner
	|	AND CASE
	|			WHEN TermsOfSale.Organization = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.PricesKind = &PricesKind
	|		END
	|	AND NOT TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND NOT TermsOfSale.Standard_
	|	AND TermsOfSale.Partner = &Partner
	|	AND CASE
	|			WHEN TermsOfSale.Organization = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.PricesKind = &PricesKind
	|		END
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|ORDER BY
	|	Priority";
	
	Return QueryText;
EndFunction

// Returns the text of the search query for standard agreements.
//
// Returns:
//  String - the text of the search query for standard agreements.
//
Function TextOfStandardAgreementSearchRequest() Export
	
	QueryText = 
	"SELECT ALLOWED
	|	0 AS Priority,
	|	TermsOfSale.Ref AS Terms,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		INNER JOIN InformationRegister.SegmentPartners AS PartnersSegments
	|		ON (CASE
	|				WHEN NOT &PartnerSegmentsAreUsed
	|					THEN TRUE
	|				ELSE CASE
	|						WHEN TermsOfSale.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
	|							THEN TRUE
	|						ELSE TermsOfSale.PartnersSegment = PartnersSegments.Segment
	|								AND &Partner = PartnersSegments.Partner
	|					END
	|			END)
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND TermsOfSale.Standard_
	|	AND TermsOfSale.Organization = &Organization
	|	AND TermsOfSale.PricesKind = &PricesKind
	|	AND TermsOfSale.Warehouse = &Warehouse
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		INNER JOIN InformationRegister.SegmentPartners AS PartnersSegments
	|		ON (CASE
	|				WHEN NOT &PartnerSegmentsAreUsed
	|					THEN TRUE
	|				ELSE CASE
	|						WHEN TermsOfSale.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
	|							THEN TRUE
	|						ELSE TermsOfSale.PartnersSegment = PartnersSegments.Segment
	|								AND &Partner = PartnersSegments.Partner
	|					END
	|			END)
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND TermsOfSale.Standard_
	|	AND TermsOfSale.Organization = &Organization
	|	AND TermsOfSale.PricesKind = &PricesKind
	|	AND CASE
	|			WHEN TermsOfSale.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Warehouse = &Warehouse
	|		END
	|	AND NOT TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		INNER JOIN InformationRegister.SegmentPartners AS PartnersSegments
	|		ON (CASE
	|				WHEN NOT &PartnerSegmentsAreUsed
	|					THEN TRUE
	|				ELSE CASE
	|						WHEN TermsOfSale.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
	|							THEN TRUE
	|						ELSE TermsOfSale.PartnersSegment = PartnersSegments.Segment
	|								AND &Partner = PartnersSegments.Partner
	|					END
	|			END)
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND TermsOfSale.Standard_
	|	AND TermsOfSale.Organization = &Organization
	|	AND CASE
	|			WHEN TermsOfSale.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.PricesKind = &PricesKind
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Warehouse = &Warehouse
	|		END
	|	AND NOT TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		INNER JOIN InformationRegister.SegmentPartners AS PartnersSegments
	|		ON (CASE
	|				WHEN NOT &PartnerSegmentsAreUsed
	|					THEN TRUE
	|				ELSE CASE
	|						WHEN TermsOfSale.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
	|							THEN TRUE
	|						ELSE TermsOfSale.PartnersSegment = PartnersSegments.Segment
	|								AND &Partner = PartnersSegments.Partner
	|					END
	|			END)
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND TermsOfSale.Standard_
	|	AND CASE
	|			WHEN TermsOfSale.Organization = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.PricesKind = &PricesKind
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Warehouse = &Warehouse
	|		END
	|	AND NOT TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	TermsOfSale.Ref,
	|	TermsOfSale.ContractsAreUsed
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		INNER JOIN InformationRegister.SegmentPartners AS PartnersSegments
	|		ON (CASE
	|				WHEN &ThisIsNewPartner
	|					THEN TRUE
	|				WHEN NOT &PartnerSegmentsAreUsed
	|					THEN TRUE
	|				ELSE CASE
	|						WHEN TermsOfSale.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
	|							THEN TRUE
	|						ELSE TermsOfSale.PartnersSegment = PartnersSegments.Segment
	|								AND &Partner = PartnersSegments.Partner
	|					END
	|			END)
	|WHERE
	|	TermsOfSale.BusinessOperation = &BusinessOperation
	|	AND TermsOfSale.Standard_
	|	AND CASE
	|			WHEN TermsOfSale.Organization = VALUE(Catalog.Companies.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.PricesKind = &PricesKind
	|		END
	|	AND CASE
	|			WHEN TermsOfSale.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE TermsOfSale.Warehouse = &Warehouse
	|		END
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|
	|ORDER BY
	|	Priority";
	
	Return QueryText;
EndFunction

// Returns the text of the query to fetch details of the facilities.
//
// Parameters:
//  Individual_ - Boolean - indicates the price list type.
//
// Returns:
//  String - the text of the request for the details of the price list.
//
Function RequestTextForDetailsOfPriceListObjects(Individual_) Export
	
	QueryText = "
	|SELECT ALLOWED
	|	&Parameter1,
	|	PriceTable_.PriceKind AS PriceKind,
	|	PriceTable_.Price AS Price,
	|	PriceTable_.ProductKind AS ProductKind,
	|	PriceTable_.ProductsParent AS ProductsParent,
	|	PriceTable_.PriceGroup AS PriceGroup,
	|	PriceTable_.SearchString AS SearchString,
	|	PriceTable_.ProductsLink AS ProductsLink,
	|	PriceTable_.PackagingRef AS PackagingRef,
	|	PriceTable_.PackagingOwnerReference AS PackagingOwnerReference,
	|	PriceTable_.UnitOfMeasureLink AS UnitOfMeasureLink,
	|	PriceTable_.CharacteristicReference AS CharacteristicReference,
	|	PriceTable_.PriceTypeReference AS PriceTypeReference,
	|	PriceTable_.UsePackages AS UsePackages,
	|	PriceTable_.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	PriceTable_.ProductsID AS ProductsID,
	|	PriceTable_.VariantID AS VariantID,
	|	PriceTable_.PackagingsID AS PackagingsID,
	|	PriceTable_.Products AS Products,
	|	PriceTable_.Package AS Package,
	|	PriceTable_.UseWeight AS UseWeight,
	|	PriceTable_.UsePictures AS UsePictures,
	|	PriceTable_.ImageFileLink AS ImageFileLink,
	|	PriceTable_.ImageSubmissionIsRequired AS ImageSubmissionIsRequired,
	|	PriceTable_.GoodsShipmentIsRequired AS GoodsShipmentIsRequired
	|INTO TemporaryPriceList
	|FROM
	|	&PriceTable_ AS PriceTable_
	|
	|INDEX BY
	|	&Parameter2,
	|	PriceKind,
	|	Price,
	|	ProductKind,
	|	ProductsParent,
	|	PriceGroup,
	|	SearchString,
	|	ProductsLink,
	|	PackagingRef,
	|	PackagingOwnerReference,
	|	UnitOfMeasureLink,
	|	CharacteristicReference,
	|	PriceTypeReference,
	|	UsePackages,
	|	ItemVariantsAreUsed,
	|	ProductsID,
	|	VariantID,
	|	PackagingsID,
	|	Products,
	|	Package,
	|	UseWeight,
	|	UsePictures,
	|	ImageFileLink,
	|	ImageSubmissionIsRequired,
	|	GoodsShipmentIsRequired
	|;";
	
	If Individual_ Then
		QueryText = StrReplace(QueryText, "&Parameter1", "PriceTable_.CustomerContract AS CustomerContract");
		QueryText = StrReplace(QueryText, "&Parameter2", "CustomerContract");
	Else	
		QueryText = StrReplace(QueryText, "&Parameter1,", "");
		QueryText = StrReplace(QueryText, "&Parameter2,", "");
	EndIf;
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	&Parameter1,
	|	PriceTable_.PriceKind,
	|	PriceTable_.Price,
	|	PriceTable_.ProductKind,
	|	PriceTable_.ProductsParent,
	|	PriceTable_.PriceGroup,
	|	PriceTable_.SearchString,
	|	PriceTable_.ProductsLink,
	|	PriceTable_.PackagingRef,
	|	PriceTable_.PackagingOwnerReference,
	|	PriceTable_.UnitOfMeasureLink AS ProductsUnitOfMeasure,
	|	PriceTable_.CharacteristicReference,
	|	PriceTable_.PriceTypeReference,
	|	PriceTable_.UsePackages,
	|	PriceTable_.ItemVariantsAreUsed,
	|	PriceTable_.ProductsID,
	|	PriceTable_.VariantID,
	|	PriceTable_.PackagingsID,
	|	PriceTable_.UseWeight,
	|	PriceTable_.ImageFileLink,
	|	PriceTable_.ImageSubmissionIsRequired,
	|	PriceTable_.GoodsShipmentIsRequired, &Parameter2, &Parameter3, &Parameter4, &Parameter5, &Parameter6
	|FROM
	|	TemporaryPriceList AS PriceTable_
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = PriceTable_.ProductsLink)
	|		LEFT JOIN Catalog.TypesOfPrices AS CatalogTypesOfPrices
	|		ON (CatalogTypesOfPrices.Ref = PriceTable_.PriceTypeReference)
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (ProductPackages.Ref = PriceTable_.PackagingRef)
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (PriceTable_.ItemVariantsAreUsed)
	|			AND (ItemsCharacteristics.Ref = PriceTable_.CharacteristicReference)
	|		LEFT JOIN InformationRegister.CorrespondenceOfProductsOf1COrdersMobileApplication AS PackagingConformity
	|		ON (PackagingConformity.ProductsID = PriceTable_.ProductsID)
	|			AND (PackagingConformity.VariantID = PriceTable_.VariantID)
	|			AND (PackagingConformity.PackagingsID = PriceTable_.PackagingsID)
	|		LEFT JOIN InformationRegister.CorrespondenceOfProductsOf1COrdersMobileApplication AS ProductCompliance
	|		ON (ProductCompliance.ProductsID = PriceTable_.ProductsID)
	|			AND (ProductCompliance.VariantID = PriceTable_.VariantID)
	|			AND (ProductCompliance.PackagingsID = """")
	|		LEFT JOIN Catalog.ProductsAttachedFiles AS ProductFiles
	|		ON (ProductFiles.Ref = CatalogProducts.PicturesFile)
	|			AND (PriceTable_.ImageSubmissionIsRequired)
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period,
	|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON PriceTable_.ProductsLink = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryPriceList";
	
	TextProducts = "
	|	CatalogProducts.DeletionMark AS ProductsDeletionMark,
	|	CatalogProducts.Code AS ProductsCode,
	|	CatalogProducts.DescriptionFull AS ProductFullName,
	|	CatalogProducts.SKU AS ProductsSKU,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef))) AS VATRateLink,
	|	CASE
	|		WHEN NOT CatalogProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OperationService,
	|	CatalogProducts.Parent AS ParentProduct,
	|	CatalogProducts.Parent.DeletionMark AS ParentProductDeletionMark,
	|	CatalogProducts.Parent.Parent AS ParentParentProduct,
	|	CatalogProducts.Parent.Code AS ProductParentCode,
	|	CatalogProducts.ProductKind AS ProductsTypeOfProducts_,
	|	CatalogProducts.ProductKind.DeletionMark AS ProductsTypeOfProducts_DeletionMark,
	|	CatalogProducts.ProductKind.Parent AS ProductsTypeOfProductsParent,
	|	CatalogProducts.PriceGroup AS ProductsPriceGroup,
	|	CatalogProducts.PriceGroup.DeletionMark AS ProductsPriceGroupDeletionMark,
	|	CatalogProducts.PriceGroup.LongDesc AS ProductsPriceGroupDescription,
	|	CatalogProducts.UnitOfMeasure.Code AS ProductsUnitOfMeasurementCode,
	|	CatalogProducts.UnitOfMeasure.DeletionMark AS ProductsUnitOfMeasureDeletionMark,
	|	CatalogProducts.UnitOfMeasure.InternationalAbbreviation AS ProductUnitOfMeasurementInternationalAbbreviation,
	|	CatalogProducts.UnitOfMeasure.DescriptionFull AS ProductsUnitOfMeasurementFullName,
	|	CatalogProducts.UnitOfMeasure.PredefinedDataName AS ProductUnitNameOfPredefinedData,
	|	CatalogProducts.WeightUnitOfMeasure AS WeightPackingLink,
	|	CatalogProducts.WeightUse,
	|	CatalogProducts.YouCanSpecifyWeightInDocuments,
	|	CatalogProducts.WeightDenominator,
	|	CatalogProducts.WeightNumerator,
	|	CAST(CatalogProducts.LongDesc AS STRING(1000)) AS ProductItemDescription";
	
	ImageFileText = "
	|	ISNULL(ProductFiles.Description, """") AS ImageFileName,
	|	ISNULL(ProductFiles.DeletionMark, FALSE) AS PicturesFileDeletionMark,
	|	ISNULL(ProductFiles.FileOwner, """") AS ImageFileFILEOwner,
	|	ISNULL(ProductFiles.CreationDate, """") AS ImageFileCreationDate,
	|	CAST(ISNULL(ProductFiles.LongDesc, """") AS STRING(1000)) AS ImageFileDescription,
	|	ISNULL(ProductFiles.Size, 0) AS ImageFileSize,
	|	ISNULL(ProductFiles.Extension, """") AS ImageFileExtension";
	
	TextPackaging = "
	|	ISNULL(ProductPackages.DeletionMark, FALSE) AS ProductPackagesDeletionMark,
	|	ISNULL(ProductPackages.Description, """") AS PackagingProductsName,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingNomenclatureCoefficient,
	|	ISNULL(ProductPackages.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS PackagingProductsUnitOfMeasurement,
	|	ISNULL(ProductPackages.UnitOfMeasure.Code, """") AS PackagingProductsUnitCode,
	|	ISNULL(ProductPackages.UnitOfMeasure.DeletionMark, FALSE) AS PackagingProductsUnitOfMeasurementDeletionMark,
	|	ISNULL(ProductPackages.UnitOfMeasure.InternationalAbbreviation, """") AS PackagingProductsUnitOfMeasureInternationalAbbreviation,
	|	ISNULL(ProductPackages.UnitOfMeasure.DescriptionFull, """") AS PackagingProductsUnitOfMeasurementFullName,
	|	ISNULL(ProductPackages.UnitOfMeasure.PredefinedDataName, """") AS PackagingProductsUnitOfMeasurementNameOfPredefinedData,
	|	ISNULL(ProductPackages.WeightUnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS PackagingProductsWeightUnit,
	|	ISNULL(&QueryTextPackageWeight, 0) AS PackagingProductsWeight,
	|	ISNULL(ProductPackages.WeightUnitOfMeasure.Code, """") AS PackagingProductsWeightUnitCode,
	|	ISNULL(ProductPackages.WeightUnitOfMeasure.DeletionMark, FALSE) AS PackagingProductsWeightUnitDeletionMark,
	|	ISNULL(ProductPackages.WeightUnitOfMeasure.InternationalAbbreviation, """") AS PackagingProductsWeightUnitOfMeasurementInternationalAbbreviation,
	|	ISNULL(ProductPackages.WeightUnitOfMeasure.DescriptionFull, """") AS PackagingProductsWeightUnitOfMeasurementFullName,
	|	ISNULL(ProductPackages.WeightUnitOfMeasure.PredefinedDataName, """") AS PackagingProductsWeightUnitPredefinedDataName,
	|	ISNULL(ProductPackages.Parent, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS PackagingProductsParent";
	
	TextOther = "
	|	ISNULL(ItemsCharacteristics.DescriptionFull, """") AS CharacteristicFullName,
	|	CatalogTypesOfPrices.Description AS PriceTypeName,
	|	CatalogTypesOfPrices.DeletionMark AS PriceKindDeletionMark,
	|	CatalogTypesOfPrices.PriceIncludesVAT AS PriceTypePriceIncludingVAT";
	
	MatchSearchText = "
	|	CASE
	|		WHEN PriceTable_.ItemVariantsAreUsed
	|			THEN ISNULL(ProductCompliance.MobileAppObjectID, """")
	|		ELSE PriceTable_.ProductsID
	|	END AS Products,
	|	CASE
	|		WHEN PriceTable_.ItemVariantsAreUsed
	|			THEN CASE
	|					WHEN ProductCompliance.MobileAppObjectID IS NULL 
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE FALSE
	|	END AS RecordProductCompliance,
	|	CASE
	|		WHEN PriceTable_.ItemVariantsAreUsed
	|			THEN ISNULL(PackagingConformity.MobileAppObjectID, """")
	|		ELSE CASE
	|				WHEN PriceTable_.UsePackages
	|					THEN CASE
	|							WHEN VALUETYPE(PriceTable_.PackagingOwnerReference) = TYPE(Catalog.Products)
	|								THEN CASE
	|										WHEN NOT PriceTable_.PackagingRef = PriceTable_.UnitOfMeasureLink
	|											THEN PriceTable_.PackagingsID
	|										ELSE ISNULL(PackagingConformity.MobileAppObjectID, """")
	|									END
	|							ELSE ISNULL(PackagingConformity.MobileAppObjectID, """")
	|						END
	|				ELSE ISNULL(PackagingConformity.MobileAppObjectID, """")
	|			END
	|	END AS Package,
	|	CASE
	|		WHEN PriceTable_.ItemVariantsAreUsed
	|			THEN CASE
	|					WHEN PackagingConformity.MobileAppObjectID IS NULL 
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN PriceTable_.UsePackages
	|					THEN CASE
	|							WHEN VALUETYPE(PriceTable_.PackagingOwnerReference) = TYPE(Catalog.Products)
	|								THEN CASE
	|										WHEN NOT PriceTable_.PackagingRef = PriceTable_.UnitOfMeasureLink
	|											THEN FALSE
	|										ELSE CASE
	|												WHEN PackagingConformity.MobileAppObjectID IS NULL 
	|													THEN TRUE
	|												ELSE FALSE
	|											END
	|									END
	|						END
	|				ELSE CASE
	|						WHEN PackagingConformity.MobileAppObjectID IS NULL 
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|			END
	|	END AS RecordPackagingCompliance";
	
	QueryText = StrReplace(QueryText, "&Parameter1", ?(Individual_, "PriceTable_.CustomerContract", "FALSE AS Exported"));
	QueryText = StrReplace(QueryText, "&Parameter2", TextProducts);
	QueryText = StrReplace(QueryText, "&Parameter3", ImageFileText);
	QueryText = StrReplace(QueryText, "&Parameter4", TextPackaging);
	QueryText = StrReplace(QueryText, "&Parameter5", TextOther);
	QueryText = StrReplace(QueryText, "&Parameter6", MatchSearchText);
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"CatalogProducts"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackageWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"ProductPackages",
			"CatalogProducts"));
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region OtherItems

// Returns a string representation of the URI of the web service namespace.
//
// Returns:
//  String - description of the namespace.
//
Function NamespaceURI() Export
	
	Return "http://www.1c.ru/CustomerOrders/Exchange";
EndFunction

// Returns an exchange message with information about the start of the exchange with the mobile app.
//
// Parameters:
//  MobileApplicationVersion - String - version of the mobile application;
//  MobileDeviceId - String - the non-changeable code of this mobile app
//    is used as the code of the exchange plan node.
//
// Returns:
//  XDTODataObject - Permit (http:// www.1c.ru/CustomerOrders/Exchange ) - generated exchange message.
//
Function ExchangeStart(MobileApplicationVersion, MobileDeviceId) Export
	
	ResponseStructure = MobileApplicationSalesOrders.ResponseStructure();
	ResponseStructure.Insert("DeleteAppData", False);
	
	If Not Constants.Use1COrdersMobileApplication.Get() Then
		ResponseStructure.Success = False;
		ResponseStructure.ResultMessage = NStr("vi = 'Không cho phép đồng bộ dữ liệu với cơ sở thông tin.';
												|ru = 'Нет разрешения на синхронизацию данных с информационной базой.';
												|en = 'No permission to synchronize data with the infobase.'; fa = 'No permission to synchronize data with the infobase.';
												|it = 'Non ci sono i permessi per sincronizzare i dati con il database.';
												|pl = 'Brak uprawnień do synchronizacji danych z bazą informacyjną.';
												|tr = 'Verileri bilgi tabanı ile senkronize etme izni yok.'");
		Return WSResponse(ResponseStructure, "Permit");
	EndIf;
	
	If MobileApplicationVersion = "1" Then
		ResponseStructure.Success = False;
		ResponseStructure.ResultMessage = NStr("vi = 'Cần cập nhật ứng dụng di động.';
												|ru = 'Требуется обновление мобильного приложения.';
												|en = 'Mobile app update is required.'; fa = 'Mobile app update is required.';
												|it = 'È necessario un aggiornamento dell''applicazione mobile.';
												|pl = 'Wymagana jest aktualizacja aplikacji mobilnej!.';
												|tr = 'Mobil uygulamanın güncellenmesi gerekmektedir.'");
		Return WSResponse(ResponseStructure, "Permit");
	EndIf;
	
	SetPrivilegedMode(True);
	
	MainExchangeNode = ExchangePlans.MobileApplicationSalesOrders.ThisNode();
	
	If Not ValueIsFilled(Common.ObjectAttributeValue(MainExchangeNode, "Code")) Then
		
		MainNodeObject = MainExchangeNode.GetObject();
		MainNodeObject.Code = "001";
		MainNodeObject.Description = NStr("vi = 'Trung tâm';
											|ru = 'Центральный';
											|en = 'Central'; fa = 'Central';
											|it = 'Centrale';
											|pl = 'Central';
											|tr = 'Merkezi'");
		MainNodeObject.Write();
		
	EndIf;
	
	ExchangeNode = MobileApplicationSalesOrdersOverridable.FindExchangeNode(ResponseStructure,
		MobileDeviceId, Users.CurrentUser());

	If ExchangeNode = Undefined Then
		Return WSResponse(ResponseStructure, "Permit");
	Else
		ResponseStructure.Insert("CorrespondentNode", ExchangeNode);
		ResponseStructure.Insert("EventLogMessageKey",
			EventLogMessageKey(ExchangeNode, TrimAll(Enums.ActionsOnExchange.DataImport)));
		ResponseStructure.Insert("ActionOnExchange", Enums.ActionsOnExchange.DataImport);
		ResponseStructure.Insert("StartDate", CurrentSessionDate());
		ResponseStructure.Insert("Comment", NStr("vi = 'Bắt đầu trao đổi';
												|ru = 'Начало обмена';
												|en = 'Exchange start'; fa = 'Exchange start';
												|it = 'Inizio dello scambio';
												|pl = 'Początek wymiany';
												|tr = 'Mübadelenin başlangıcı'",
			Common.DefaultLanguageCode()));
	
		If ExchangeNode.DeletionMark Then
			ResponseStructure.Success = False;
			ResponseStructure.ResultMessage = NStr("vi = 'Cấm kết nối với thiết bị.
			|Dữ liệu đã bị xóa.';
			|ru = 'Соединение с устройством запрещено.
			|Данные были очищены.';
			|en = 'Connection with the device is prohibited.
			|Data was cleared.'; fa = 'Connection with the device is prohibited.
			|Data was cleared.';
			|it = 'Connessione con l''apparecchio non permessa.
			|I dati sono stati cancellati.';
			|pl = 'Połączenie z urządzeniem jest zabronione.
			|Dane zostały oczyszczone.';
			|tr = 'Cihaza bağlantı yasaklandı.
			| Veriler temizlendi.'");
			ResponseStructure.DeleteAppData = True;
			Return WSResponse(ResponseStructure, "Permit");
		EndIf;
		
		If Not MobileApplicationVersion = "3.0.7" Then
			Try
				RecordingAppVersion = 
				InformationRegisters.CorrespondenceOfProductsOf1COrdersMobileApplication.CreateRecordManager();
				RecordingAppVersion.ProductsID = MobileDeviceId;
				RecordingAppVersion.MobileAppObjectID = MobileDeviceId;
				RecordingAppVersion.Write(True);
			Except
				WriteLogEvent(NStr("vi = 'Trao đổi 1C:Đơn hàng';
									|ru = 'Обмен 1С:Заказы';
									|en = 'Exchange 1C:Orders'; fa = 'Exchange 1C:Orders';
									|it = 'Scambio 1C:Orders';
									|pl = 'Wymiana 1C:Orders';
									|tr = '1C:Orders Değişimi'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		Else
			AppVersionRecords = 
				InformationRegisters.CorrespondenceOfProductsOf1COrdersMobileApplication.CreateRecordSet();
			AppVersionRecords.Filter["ProductsID"].Use = True;
			AppVersionRecords.Filter["ProductsID"].Value = MobileDeviceId;
			
			AppVersionRecords.Write();
		EndIf;
	EndIf;
	
	Return WSResponse(ResponseStructure, "Permit");
EndFunction

// Clears the exchange history records for the node.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - the site plan of exchange.
// 
Procedure ClearExchangeHistory(ExchangeNode) Export
	
	SetPrivilegedMode(True);
	
	StructureToRemove = New Structure("InfobaseNode", ExchangeNode);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Register_Manager = "DataAreaDataExchangeStates";
		RegisterManagerSuccessful = "DataAreasSuccessfulDataExchangeStates";
	Else
		Register_Manager = "DataExchangesStates";
		RegisterManagerSuccessful = "SuccessfulDataExchangesStates";
	EndIf;
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(StructureToRemove, Register_Manager);
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(StructureToRemove, RegisterManagerSuccessful);
EndProcedure

// The procedure, based on the analysis of the transmitted data type,
// converts this data to the "delete Object" type to delete this data.
//
// Parameters:
//  Data - CatalogObject, DocumentObject, ObjectDeletion, Undefined - object, a set of records to convert.
//
Procedure DataDeletion(Data) Export
	
	If Data = Undefined Then
		Return;
	EndIf;
	// We get the metadata description object corresponding to the data.
	MetadataObject = ?(TypeOf(Data) = Type("ObjectDeletion"), Data.Ref.Metadata(), Data.Metadata());
	// We check the type, we are interested only in those types that are implemented on the mobile platform.
	If Metadata.Catalogs.Contains(MetadataObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
		Or Metadata.Documents.Contains(MetadataObject) Then
		
		// Transferring object deletion for object
		Data = New ObjectDeletion(Data.Ref);
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
		Or Metadata.AccumulationRegisters.Contains(MetadataObject)
		Or Metadata.Sequences.Contains(MetadataObject) Then
		
		// Clearing the data
		Data.Clear();
	EndIf;
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ServiceExchangeSettings

Function SelectionElementValueFromUserSettings(SettingsComposer, TagName)
	
	If TypeOf(SettingsComposer) <> Type("DataCompositionSettingsComposer") Then
		Return Undefined;
	EndIf;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(SettingsComposer.Settings.Filter,
		TagName);
	For Each FilterElement In FilterItems1 Do
		UserSettingID = FilterElement.UserSettingID;
		SettingsComposer.UserSettings.AdditionalProperties.Insert(TagName,
			UserSettingID);
		ItemTheCustomSettings = 
			SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
		If ItemTheCustomSettings <> Undefined 
			And ItemTheCustomSettings.Use Then
				Return ItemTheCustomSettings.RightValue;
		Else
			If ItemTheCustomSettings = Undefined
				And FilterElement.Use Then
					Return FilterElement.RightValue;
			EndIf;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

Procedure SetComposerSelectionsByFunctionalOptions(SettingsComposer, MatchesOfSelectionElements)
	
	For Each Map In MatchesOfSelectionElements Do
		For Each KeyAndValue In Map Do
			If Not GetFunctionalOption(KeyAndValue.Key) Then
				DataCompositionServer.RemoveSelectionItemFromAllReportSettings(SettingsComposer,
					KeyAndValue.Value);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

#EndRegion

#Region DeliverableNotificationOperations

Procedure DontUseIDs(Tokens, NodeName = "MobileApplicationSalesOrders")
	
	If Tokens.Count() > 0 Then
		ExchangePlansManager = ExchangePlans[NodeName];//ExchangePlanManager - 
		Selection = ExchangePlansManager.Select();
		While Selection.Next() Do
			If Selection.DeliverableNotificationSubscriberID <> Undefined Then
				Id = Selection.DeliverableNotificationSubscriberID.Get();
				If Id <> Undefined And Tokens.Find(Id.DeviceID) Then
					Node = Selection.GetObject();
					Node.DeliverableNotificationSubscriberID = Undefined;
					Node.Write();
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region WorkingWithEventRegistration

Procedure RecordHistoryOfExchange(ExchangeResult, XDTOObjectName)
	
	If XDTOObjectName = "MessageExchange" Then
		If ExchangeResult.Success Then
			ExchangeResult.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed2;
			ELLevel = EventLogLevel.Information;
		Else
			ExchangeResult.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ELLevel = EventLogLevel.Error;
		EndIf;
	Else
		ExchangeResult.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed2;
		ELLevel = EventLogLevel.Information;
	EndIf;
	
	// We fix the event in the registration log.
	DataExchangeXDTOServer.WriteEventLogDataExchange1(
		ExchangeResult.Comment, ExchangeResult, ELLevel);
	
	// We fix the state of the exchange.
	RecordExchangeState(ExchangeResult);
EndProcedure

Procedure RecordExchangeState(ExchangeResult)
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Register_Manager = InformationRegisters.DataAreaDataExchangeStates;
		RegisterManagerSuccessful = InformationRegisters.DataAreasSuccessfulDataExchangeStates;
	Else
		Register_Manager = InformationRegisters.DataExchangesStates;
		RegisterManagerSuccessful = InformationRegisters.SuccessfulDataExchangesStates;
	EndIf;
	
	StateRecording = Register_Manager.CreateRecordManager();
	FillPropertyValues(StateRecording, ExchangeResult);
	StateRecording.InfobaseNode = ExchangeResult.CorrespondentNode;
	StateRecording.EndDate = CurrentSessionDate();
	StateRecording.Write();
	
	If ValueIsFilled(StateRecording.ActionOnExchange)
		And (StateRecording.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed2) Then
		
		RecordSuccessfulState = RegisterManagerSuccessful.CreateRecordManager();
		FillPropertyValues(RecordSuccessfulState, StateRecording);
		RecordSuccessfulState.Write();
	EndIf;
EndProcedure

Function EventLogMessageKey(InfobaseNode, ActionOnExchange)
	
	ExchangePlanName = "";
	DeviceName = "";
	If ValueIsFilled(InfobaseNode) Then
		ExchangePlanName = TrimAll(InfobaseNode.Metadata());
		DeviceName = TrimAll(InfobaseNode);
	EndIf;
	
	MessageKey = NStr("vi = 'Trao đổi dữ liệu. [ExchangePlanName]. Thiết bị: [DeviceName]. [ActionOnExchange]';
						|ru = 'Обмен данными. [ExchangePlanName]. Устройство: [DeviceName]. [ActionOnExchange]';
						|en = 'Data exchange. [ExchangePlanName]. Device: [DeviceName]. [ActionOnExchange]'; fa = 'Data exchange. [ExchangePlanName]. Device: [DeviceName]. [ActionOnExchange]';
						|it = 'Scambio di dati. [ExchangePlanName]. Apparecchio: [DeviceName]. [ActionOnExchange]';
						|pl = 'Wymiana danych. [ExchangePlanName]. Urządzenie: [DeviceName]. [ActionOnExchange]';
						|tr = 'Verilerin değişimi. [ExchangePlanName] Cihaz:[DeviceName]. [ActionOnExchange]'",
		Common.DefaultLanguageCode());
	
	MessageKey = StrReplace(MessageKey, "[ExchangePlanName]", ExchangePlanName);
	MessageKey = StrReplace(MessageKey, "[DeviceName]", DeviceName);
	MessageKey = StrReplace(MessageKey, "[ActionOnExchange]", ActionOnExchange);
	
	Return MessageKey;
EndFunction

#EndRegion

Function DataToContinue(Data)
	
	StorageAddress = GetTempFileName("xml");
	Try
		XMLWriter = New XMLWriter;
		XMLWriter.OpenFile(StorageAddress);
		WriteXML(XMLWriter, Data);
		XMLWriter.Close();
	Except
		StorageAddress = "";
	EndTry;
	Return StorageAddress;
EndFunction

Procedure WriteContractAgreement(Data, Message)
	
	ObjectType = XDTOFactory.Type(NamespaceURI(), "CatalogObject.ДоговорыКлиентов");
	
	MobileAgreement = XDTOFactory.Create(ObjectType);
	
	For Each Property In Data.Properties() Do
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not MobileAgreement.Properties().Get(TrimAll(Property)) = Undefined Then
			MobileAgreement[TrimAll(Property)] = Value;
		EndIf;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateAgreementAgreement(MobileAgreement, Message);
EndProcedure

// Parameters:
// - Data - 
// - Exchange nodes - 
// - Message - 
// - Task Settings - 
//
Procedure RecordTaskForSalesRepresentative(Data, ExchangeNode, Message, TaskSettings)
	
	NameUris = NamespaceURI();
	
	ObjectType = XDTOFactory.Type(NameUris, "DocumentObject.ЗаданиеТорговомуПредставителю");
	ItemTypeProducts = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаданиеТорговомуПредставителю.Товары");
	TaskObjectType = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаданиеТорговомуПредставителю.Задачи");
	MobileTask = XDTOFactory.Create(ObjectType);
	
	// Document header data
	For Each Property In Data.Properties() Do
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			If Not TrimAll(Property) = "Товары" And Not TrimAll(Property) = "Задачи"
			And Not TrimAll(Property) = "ДолгиПоЗаказам" And Not TrimAll(Property) = "РасшифровкаДебиторскойЗадолженности" Then //@NON-NLS-1 @NON-NLS-2 @NON-NLS-3 @NON-NLS-4
				Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
			EndIf;
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not TrimAll(Property) = "Товары" And Not TrimAll(Property) = "Задачи" And Not TrimAll(Property) = "PriceKind"
		And Not TrimAll(Property) = "ДолгиПоЗаказам" And Not TrimAll(Property) = "РасшифровкаДебиторскойЗадолженности" Then //@NON-NLS-1 @NON-NLS-2 @NON-NLS-4 @NON-NLS-5
			If Not MobileTask.Properties().Get(TrimAll(Property)) = Undefined Then
				MobileTask[TrimAll(Property)] = Value;
			EndIf;
		EndIf;
	EndDo;
	
	// PM data "Goods"
	TheseProducts = Data["Товары"]; //@NON-NLS-1
	PropertiesOfTheseProducts = TheseProducts.Properties(); // XDTOPropertyCollection
	If Not PropertiesOfTheseProducts.Get("Row") = Undefined Then //@NON-NLS-1
		If TypeOf(Data["Товары"].Row) = Type("XDTOList") Then //@NON-NLS-1
			For Each ListItem In Data["Товары"].Row Do //@NON-NLS-1
				MobileTaskProducts = XDTOFactory.Create(ItemTypeProducts);
				FillPropertyValues(MobileTaskProducts, ListItem);
				ObjectTablePart = MobileTask.Товары;//XDTOList -  
				ObjectTablePart.Add(MobileTaskProducts);
			EndDo;
		Else
			MobileTaskProducts = XDTOFactory.Create(ItemTypeProducts);
			FillPropertyValues(MobileTaskProducts, Data["Товары"].Row); //@NON-NLS-1
			ObjectTablePart = MobileTask.Товары;//XDTOList -  
			ObjectTablePart.Add(MobileTaskProducts);
		EndIf;
	EndIf;
	
	// PM data "Tasks"
	Task_Data_ = Data["Задачи"]; //@NON-NLS-1
	PropertiesTaskData = Task_Data_.Properties(); // XDTOPropertyCollection
	If Not PropertiesTaskData.Get("Row") = Undefined Then //@NON-NLS-1
		If TypeOf(Data["Задачи"].Row) = Type("XDTOList") Then //@NON-NLS-1
			For Each ListItem In Data["Задачи"].Row Do //@NON-NLS-1
				MobileTask_ = XDTOFactory.Create(TaskObjectType);
				MobileTask_.Выполнена = ListItem["Выполнена"]; //@NON-NLS-1
				If Not TypeOf(ListItem.TaskDetails1) = Type("XDTODataObject") Then
					MobileTask_.ОписаниеЗадачи = ListItem["ОписаниеЗадачи"]; //@NON-NLS-1
				EndIf;
				If Not TypeOf(ListItem.ResultDetails) = Type("XDTODataObject") Then
					MobileTask_.ОписаниеРезультата = ListItem["ОписаниеРезультата"]; //@NON-NLS-1
				EndIf;
				ObjectTablePart = MobileTask.Задачи;//XDTOList -  
				ObjectTablePart.Add(MobileTask_);
			EndDo;
		Else
			MobileTask_ = XDTOFactory.Create(TaskObjectType);
			MobileTask_.Выполнена = Data["Задачи"].Row["Выполнена"]; //@NON-NLS-1 @NON-NLS-2
			If Not TypeOf(Data["Задачи"].Row.TaskDetails1) = Type("XDTODataObject") Then //@NON-NLS-1
				MobileTask_.ОписаниеЗадачи = Data["Задачи"].Row["ОписаниеЗадачи"]; //@NON-NLS-1 @NON-NLS-2
			EndIf;
			If Not TypeOf(Data["Задачи"].Row.ResultDetails) = Type("XDTODataObject") Then //@NON-NLS-1
				MobileTask_.ОписаниеРезультата = Data["Задачи"].Row["ОписаниеРезультата"]; //@NON-NLS-1 @NON-NLS-2
			EndIf;
			ObjectTablePart = MobileTask.Задачи;//XDTOList -  
			ObjectTablePart.Add(MobileTask_);
		EndIf;
	EndIf;
		
	MobileApplicationSalesOrdersOverridable.CreateUpdateTaskForSalesRepresentative(
		MobileTask, ExchangeNode, Message, TaskSettings);
EndProcedure

Procedure RecordCustomerOrder(Data, Message)
	
	NameUris = NamespaceURI();
	
	ObjectType = XDTOFactory.Type(NameUris, "DocumentObject.ЗаказКлиента");
	ItemTypeProducts = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаказКлиента.Товары");
	ItemTypeAdditionalDetails = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаказКлиента.ДополнительныеРеквизиты");
	
	MobileOrdering = XDTOFactory.Create(ObjectType);
	
	For Each Property In Data.Properties() Do
		IsTabularSection = False;
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			If Not IsObjectTable(Data[TrimAll(Property)])
				And Not TrimAll(Property) = "Товары"
				And Not TrimAll(Property) = "ДополнительныеРеквизиты" Then //@NON-NLS-1 @NON-NLS-2
				Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
			Else
				Value = Data[TrimAll(Property)];
				IsTabularSection = True;
			EndIf;
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not IsTabularSection Then
			If Not MobileOrdering.Properties().Get(TrimAll(Property)) = Undefined Then
				MobileOrdering[TrimAll(Property)] = Value;
			EndIf;
		Else
			If Value.Properties().Count() = 0 Then
				Continue;
			EndIf;
			If Not MobileOrdering.Properties().Get(TrimAll(Property)) = Undefined Then
				If TypeOf(Value.Row) = Type("XDTOList") Then
					For Each ListItem In Value.Row Do
						If TrimAll(Property) = "Товары" Then //@NON-NLS-1
							MobileData = XDTOFactory.Create(ItemTypeProducts);
						Else
							MobileData = XDTOFactory.Create(ItemTypeAdditionalDetails);
						EndIf;
						FillObjectPropertiesValues(MobileData, ListItem);
						ObjectTablePart = MobileOrdering[TrimAll(Property)];//XDTOList -  
						ObjectTablePart.Add(MobileData);
						
					EndDo;
				Else
					If TrimAll(Property) = "Товары" Then //@NON-NLS-1
						MobileData = XDTOFactory.Create(ItemTypeProducts);
					Else
						MobileData = XDTOFactory.Create(ItemTypeAdditionalDetails);
					EndIf;
					FillObjectPropertiesValues(MobileData, Value.Row);
					ObjectTablePart = MobileOrdering[TrimAll(Property)];//XDTOList -  
					ObjectTablePart.Add(MobileData);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateCustomerOrder(MobileOrdering, Message);

EndProcedure

Procedure RecordRequestForReturnOfGoodsFromClient(Data, Message)
	
	NameUris = NamespaceURI();
	
	ObjectType = XDTOFactory.Type(NameUris, "DocumentObject.ЗаявкаНаВозвратТоваровОтКлиента");
	ItemTypeProducts = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаявкаНаВозвратТоваровОтКлиента.Товары");
	ItemTypeAdditionalDetails = XDTOFactory.Type(NameUris,
		"DocumentTabularSectionRow.ЗаявкаНаВозвратТоваровОтКлиента.ДополнительныеРеквизиты");
	
	MobileRefundRequest = XDTOFactory.Create(ObjectType);
	
	For Each Property In Data.Properties() Do
		IsTabularSection = False;
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			If Not IsObjectTable(Data[TrimAll(Property)])
				And Not TrimAll(Property) = "Товары"
				And Not TrimAll(Property) = "ДополнительныеРеквизиты" Then //@NON-NLS-1 @NON-NLS-2
				Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
			Else
				Value = Data[TrimAll(Property)];
				IsTabularSection = True;
			EndIf;
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not IsTabularSection Then
			If Not MobileRefundRequest.Properties().Get(TrimAll(Property)) = Undefined Then
				MobileRefundRequest[TrimAll(Property)] = Value;
			EndIf;
		Else
			If Value.Properties().Count() = 0 Then
				Continue;
			EndIf;
			If Not MobileRefundRequest.Properties().Get(TrimAll(Property)) = Undefined Then
				If TypeOf(Value.Row) = Type("XDTOList") Then
					For Each ListItem In Value.Row Do
						If TrimAll(Property) = "Товары" Then //@NON-NLS-1
							MobileData = XDTOFactory.Create(ItemTypeProducts);
						Else
							MobileData = XDTOFactory.Create(ItemTypeAdditionalDetails);
						EndIf;
						FillObjectPropertiesValues(MobileData, ListItem);
						ObjectTablePart = MobileRefundRequest[TrimAll(Property)];//XDTOList -  
						ObjectTablePart.Add(MobileData);
					EndDo;
				Else
					If TrimAll(Property) = "Товары" Then //@NON-NLS-1
						MobileData = XDTOFactory.Create(ItemTypeProducts);
					Else
						MobileData = XDTOFactory.Create(ItemTypeAdditionalDetails);
					EndIf;
					FillObjectPropertiesValues(MobileData, Value.Row);
					ObjectTablePart = MobileRefundRequest[TrimAll(Property)];//XDTOList -  
					ObjectTablePart.Add(MobileData);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateRequestForReturnOfGoodsFromCustomer(
		MobileRefundRequest, Message);
EndProcedure

Procedure RecordClient(Data, ExchangeNode, Message)
	
	NameUris = NamespaceURI();
	
	ObjectType = XDTOFactory.Type(NameUris, "CatalogObject.Клиенты");
	ItemTypeCI = XDTOFactory.Type(NameUris, "CatalogTabularSectionRow.Клиенты.КонтактнаяИнформация");
	ItemTypeAdditionalDetails = XDTOFactory.Type(NameUris, "CatalogTabularSectionRow.Клиенты.ДополнительныеРеквизиты");
	
	MobilePartner = XDTOFactory.Create(ObjectType);
	
	For Each Property In Data.Properties() Do
		IsTabularSection = False;
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			If Not IsObjectTable(Data[TrimAll(Property)])
				And Not TrimAll(Property) = "ДополнительныеРеквизиты"
				And Not TrimAll(Property) = "КонтактнаяИнформация" Then //@NON-NLS-1 @NON-NLS-2
				Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
			Else
				Value = Data[TrimAll(Property)];
				IsTabularSection = True;
			EndIf;
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not IsTabularSection Then
			If Not MobilePartner.Properties().Get(TrimAll(Property)) = Undefined Then
				MobilePartner[TrimAll(Property)] = Value;
			EndIf;
		Else
			If Value.Properties().Count() = 0 Then
				Continue;
			EndIf;
			If Not MobilePartner.Properties().Get(TrimAll(Property)) = Undefined Then
				If TypeOf(Value.Row) = Type("XDTOList") Then
					For Each ListItem In Value.Row Do
						If TrimAll(Property) = "КонтактнаяИнформация" Then //@NON-NLS-1
							MobileData = XDTOFactory.Create(ItemTypeCI);
						Else
							MobileData = XDTOFactory.Create(ItemTypeAdditionalDetails);
						EndIf;
						FillObjectPropertiesValues(MobileData, ListItem);
						ObjectTablePart = MobilePartner[TrimAll(Property)];//XDTOList -  
						ObjectTablePart.Add(MobileData);
					EndDo;
				Else
					If TrimAll(Property) = "КонтактнаяИнформация" Then //@NON-NLS-1
						MobileData = XDTOFactory.Create(ItemTypeCI);
					Else
						MobileData = XDTOFactory.Create(ItemTypeAdditionalDetails);
					EndIf;
					FillObjectPropertiesValues(MobileData, Value.Row);
					ObjectTablePart = MobilePartner[TrimAll(Property)];//XDTOList -  
					ObjectTablePart.Add(MobileData);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateClient(MobilePartner, ExchangeNode, Message);
EndProcedure

Procedure RecordCustomerContactPerson(Data, Message)
	
	NameUris = NamespaceURI();
	
	ObjectType = XDTOFactory.Type(NameUris, "CatalogObject.КонтактныеЛицаКлиентов");
	ItemTypeCI = XDTOFactory.Type(NameUris, "CatalogTabularSectionRow.КонтактныеЛицаКлиентов.КонтактнаяИнформация");
	
	MobileContactPerson = XDTOFactory.Create(ObjectType);
	
	For Each Property In Data.Properties() Do
		IsTabularSection = False;
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			If Not IsObjectTable(Data[TrimAll(Property)]) 
				And Not TrimAll(Property) = "КонтактнаяИнформация" Then //@NON-NLS-1
				Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
			Else
				Value = Data[TrimAll(Property)];
				IsTabularSection = True;
			EndIf;
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not IsTabularSection Then
			MobileContactPerson[TrimAll(Property)] = Value;
		Else
			If Value.Properties().Count() = 0 Then
				Continue;
			EndIf;
			If TypeOf(Value.Row) = Type("XDTOList") Then
				For Each ListItem In Value.Row Do
					MobileData = XDTOFactory.Create(ItemTypeCI);
					FillObjectPropertiesValues(MobileData, ListItem);
					ObjectTablePart = MobileContactPerson[TrimAll(Property)];//XDTOList -  
					ObjectTablePart.Add(MobileData);
				EndDo;
			Else
				MobileData = XDTOFactory.Create(ItemTypeCI);
				FillObjectPropertiesValues(MobileData, Value.Row);
				ObjectTablePart = MobileContactPerson[TrimAll(Property)];//XDTOList -  
				ObjectTablePart.Add(MobileData);
			EndIf;
		EndIf;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateClientContactPerson(MobileContactPerson,
		Message);
EndProcedure

Procedure RecordCounterparty(Data, Message)
	
	ObjectType = XDTOFactory.Type(NamespaceURI(), "CatalogObject.Контрагенты");
	
	MobileCounterparty = XDTOFactory.Create(ObjectType);
	
	For Each Property In Data.Properties() Do
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		MobileCounterparty[TrimAll(Property)] = Value;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateCounterparty(MobileCounterparty, Message);
EndProcedure

Procedure RecordCustomerPayment(Data, ExchangeNode, Message)
	
	ObjectType = XDTOFactory.Type(NamespaceURI(), "DocumentObject.ОплатаКлиента");
	MobilePayment = XDTOFactory.Create(ObjectType);
	
	// Document header data
	For Each Property In Data.Properties() Do
		If TypeOf(Data[TrimAll(Property)]) = Type("XDTODataObject") Then
			Value = XDTOSerializer.ReadXDTO(Data[TrimAll(Property)]);
		Else
			Value = Data[TrimAll(Property)];
		EndIf;
		If Not MobilePayment.Properties().Get(TrimAll(Property)) = Undefined Then
			MobilePayment[TrimAll(Property)] = Value;
		EndIf;
	EndDo;
	
	MobileApplicationSalesOrdersOverridable.CreateUpdateCustomerPayment(MobilePayment, ExchangeNode,
		Message);
EndProcedure

Procedure FillObjectPropertiesValues(MobileData, Value)
	
	For Each Property In Value.Properties() Do
		If TypeOf(Value[TrimAll(Property)]) = Type("XDTODataObject") Then
			MobileData[TrimAll(Property)] = XDTOSerializer.ReadXDTO(Value[TrimAll(Property)]);
		Else
			MobileData[TrimAll(Property)] = Value[TrimAll(Property)];
		EndIf;
	EndDo;
EndProcedure

Function DocumentIDsFromMessage(ExchangeMessage, DocumentType)
	
	MobileApplicationSalesOrdersOverridable.ProcessExchangeMessage(ExchangeMessage, False);
	
	IDs = New Array;
	
	XMLReader = New XMLReader;
	XMLReader.SetString(ExchangeMessage);
	
	MessageReader = ExchangePlans.CreateMessageReader();
	MessageReader.BeginRead(XMLReader);
	
	XMLDataType = GetXMLType(XMLReader);
	
	LocalName = "";
	If DocumentType = 0 Then
		LocalName = "DocumentRef.ЗаказКлиента"; //@NON-NLS-1
	ElsIf DocumentType = 1 Then
		LocalName = "DocumentRef.ЗаявкаНаВозвратТоваровОтКлиента"; //@NON-NLS-1
	EndIf;
	
	While XMLReader.LocalName = LocalName Do
		
		XMLDataType = GetXMLType(XMLReader);
		
		If XMLDataType.TypeName = LocalName Then

			If LocalName = "DocumentRef.ЗаказКлиента" Then //@NON-NLS-1
				Data = ReadXML(XMLReader, Type("DocumentRef.SalesOrder"));
			ElsIf LocalName = "DocumentRef.ЗаявкаНаВозвратТоваровОтКлиента" Then //@NON-NLS-1
				Data = ReadXML(XMLReader, Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
			EndIf;
				
			IDs.Add(Data);
			
		EndIf;
	EndDo;
	
	Return IDs;
EndFunction

Function WSResponse(ExchangeResult, XDTOObjectName = "MessageExchange", ExchangeComponents = Undefined)
	
	ObjectType = XDTOFactory.Type(NamespaceURI(), XDTOObjectName);
	ExchangeObject = XDTOFactory.Create(ObjectType);
	
	FillPropertyValues(ExchangeObject, ExchangeResult);
	
	RecordHistoryOfExchange(ExchangeResult, XDTOObjectName);
		
	Return ExchangeObject;
EndFunction

Function ExchangePacketReadingOptions();
	
	ReaderSettings = New Structure;
	ReaderSettings.Insert("Transactioned", False);
	ReaderSettings.Insert("ObjectType", 0);
	ReaderSettings.Insert("TaskSettings", Undefined);
	
	Return ReaderSettings;
EndFunction

Function PreparedData(StorageAddress)
	
	SelFile = New File(StorageAddress);
	If Not SelFile.Exists() Then
		Return Undefined;
	EndIf;
	XMLReader = New XMLReader;
	XMLReader.OpenFile(StorageAddress);
	Data = Undefined;
	While CanReadXML(XMLReader) Do
		Data = ReadXML(XMLReader);
	EndDo;
	DeleteFiles(SelFile);
	Return Data;
EndFunction

Procedure ReadExchangePackage(ExchangeNode, Message, Cancel, ReaderSettings)
	
	MobileApplicationSalesOrdersOverridable.ProcessExchangeMessage(Message, False);
	
	ExchangeMessage = Message;
	
	XMLReader = New XMLReader;
	XMLReader.SetString(ExchangeMessage);
	
	MessageReader = ExchangePlans.CreateMessageReader();
	MessageReader.BeginRead(XMLReader);
	
	ResponseMessage = New Array;
	
	If ReaderSettings.Transactioned Then
		BeginTransaction();
		Try
			ReadExchangePacketData(ExchangeNode, ReaderSettings, XMLReader, ResponseMessage);
			CommitTransaction();
		Except
			RollbackTransaction();
			Cancel = True;
			WriteLogEvent(NStr("vi = 'Trao đổi 1C:Đơn hàng';
								|ru = 'Обмен 1С:Заказы';
								|en = 'Exchange 1C:Orders'; fa = 'Exchange 1C:Orders';
								|it = 'Scambio 1C:Orders';
								|pl = 'Wymiana 1C:Orders';
								|tr = '1C:Orders Değişimi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
	Else
		Try
			ReadExchangePacketData(ExchangeNode, ReaderSettings, XMLReader, ResponseMessage);
		Except
			Cancel = True;
			WriteLogEvent(NStr("vi = 'Trao đổi 1C:Đơn hàng';
								|ru = 'Обмен 1С:Заказы';
								|en = 'Exchange 1C:Orders'; fa = 'Exchange 1C:Orders';
								|it = 'Scambio 1C:Orders';
								|pl = 'Wymiana 1C:Orders';
								|tr = '1C:Orders Değişimi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	MessageReader.EndRead();
	XMLReader.Close();
	
	NameUris = NamespaceURI();
	
	Message = New XMLWriter;
	
	Message.SetString("UTF-8");
	Message.WriteXMLDeclaration();
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	WriteMessage1.BeginWrite(Message, ExchangeNode);
	
	For Each Response In ResponseMessage Do
		
		LocalObjectName = "";
		If ReaderSettings.ObjectType = 0 Then
			LocalObjectName = "OrderStatus";
		ElsIf ReaderSettings.ObjectType = 1 Then
			LocalObjectName = "CatalogStatus";
		ElsIf ReaderSettings.ObjectType = 2 Then
			LocalObjectName = "PaymentStatus";
		ElsIf ReaderSettings.ObjectType = 3 Then
			LocalObjectName = "JobTargetStatus";
		ElsIf ReaderSettings.ObjectType = 4 Then
			LocalObjectName = "RequestToReturnStatus";
		EndIf;
		
		If ValueIsFilled(LocalObjectName) Then
			ObjectType = XDTOFactory.Type(NameUris, LocalObjectName);
			ExchangeObject = XDTOFactory.Create(ObjectType);
			FillPropertyValues(ExchangeObject, Response);
		
			XDTOFactory.WriteXML(Message, ExchangeObject);
		EndIf;
	EndDo;
	
	WriteMessage1.EndWrite();
	Message = Message.Close();
	
	MobileApplicationSalesOrdersOverridable.ProcessExchangeMessage(Message);
	
EndProcedure

Procedure ReadExchangePacketData(ExchangeNode, ReaderSettings, XMLReader, ResponseMessage)
	
	While XMLReader.LocalName = "DocumentObject.ЗаказКлиента"
		Or XMLReader.LocalName = "DocumentRef.ЗаказКлиента"
		Or XMLReader.LocalName = "DocumentObject.ЗаданиеТорговомуПредставителю"
		Or XMLReader.LocalName = "DocumentRef.ЗаданиеТорговомуПредставителю"
		Or XMLReader.LocalName = "DocumentObject.ЗаявкаНаВозвратТоваровОтКлиента"
		Or XMLReader.LocalName = "DocumentRef.ЗаявкаНаВозвратТоваровОтКлиента"
		Or XMLReader.LocalName = "DocumentObject.ОплатаКлиента"
		Or XMLReader.LocalName = "DocumentRef.ОплатаКлиента"
		Or XMLReader.LocalName = "CatalogObject.Клиенты"
		Or XMLReader.LocalName = "CatalogObject.Контрагенты"
		Or XMLReader.LocalName = "CatalogObject.ДоговорыКлиентов"
		Or XMLReader.LocalName = "CatalogObject.КонтактныеЛицаКлиентов"
		Or XDTOSerializer.CanReadXML(XMLReader) Do //@NON-NLS-1 @NON-NLS-2 @NON-NLS-3 @NON-NLS-4 @NON-NLS-5 @NON-NLS-6 @NON-NLS-7 @NON-NLS-8 @NON-NLS-9 @NON-NLS-10 @NON-NLS-11 @NON-NLS-12
		
		XMLDataType = GetXMLType(XMLReader);
		
		If XMLDataType.TypeName = "DocumentObject.ЗаказКлиента" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordCustomerOrder(Data, ResponseMessage);
		EndIf;
		
		If XMLDataType.TypeName = "DocumentObject.ЗаданиеТорговомуПредставителю" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordTaskForSalesRepresentative(Data, ExchangeNode, ResponseMessage, ReaderSettings.TaskSettings);
		EndIf;
		
		If XMLDataType.TypeName = "DocumentObject.ОплатаКлиента" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordCustomerPayment(Data, ExchangeNode, ResponseMessage);
		EndIf;
		
		If XMLDataType.TypeName = "DocumentObject.ЗаявкаНаВозвратТоваровОтКлиента" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordRequestForReturnOfGoodsFromClient(Data, ResponseMessage);
		EndIf;
		
		If XMLDataType.TypeName = "CatalogObject.Клиенты" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordClient(Data, ExchangeNode, ResponseMessage);
		EndIf;
		
		If XMLDataType.TypeName = "CatalogObject.Контрагенты" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordCounterparty(Data, ResponseMessage);
		EndIf;
		
		If XMLDataType.TypeName = "CatalogObject.ДоговорыКлиентов" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			WriteContractAgreement(Data, ResponseMessage);
		EndIf;
		
		If XMLDataType.TypeName = "CatalogObject.КонтактныеЛицаКлиентов" Then //@NON-NLS-1
			Data = XDTOFactory.ReadXML(XMLReader);
			RecordCustomerContactPerson(Data, ResponseMessage);
		EndIf;
		
	EndDo;
	
EndProcedure

Function GeneratedResponseDocumentStatuses(IDs, ExchangeNode, DocumentType)
	
	XMLResponseMessage = New XMLWriter;
	
	XMLResponseMessage.SetString("UTF-8");
	XMLResponseMessage.WriteXMLDeclaration();
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	WriteMessage1.BeginWrite(XMLResponseMessage, ExchangeNode);
	
	ResponseData_ = New Array;
	LocalObjectName = "";
	If DocumentType = 0 Then
		ResponseData_ = MobileApplicationSalesOrdersOverridable.ResponseDataStatusOfCustomerOrders(
			XMLResponseMessage, IDs);
		LocalObjectName = "OrderStatus";
		NameOfAdditionalBankingDetails = "DocumentTabularSectionRow.SalesOrder.AdditionalAttributes";
	ElsIf DocumentType = 1 Then
		ResponseData_ = MobileApplicationSalesOrdersOverridable.ResponseDataRefundRequestStatus(
			XMLResponseMessage, IDs);
		LocalObjectName = "RequestToReturnStatus";
		NameOfAdditionalBankingDetails = "DocumentTabularSectionRow.SalesOrder.AdditionalAttributes";
	EndIf;
	
	If ValueIsFilled(LocalObjectName) Then
		NamespaceURI = NamespaceURI();
		ObjectType = XDTOFactory.Type(NamespaceURI, LocalObjectName);
		ItemTypeAdditionalDetails = XDTOFactory.Type(NamespaceURI, NameOfAdditionalBankingDetails);
		For Each Response In ResponseData_ Do
			ExchangeObject = XDTOFactory.Create(ObjectType);
			FillPropertyValues(ExchangeObject, Response);
			
			If Response.Property("AdditionalAttributes") Then
				For Each ResponseString In Response.AdditionalAttributes Do
					AdditionalAttributes = XDTOFactory.Create(ItemTypeAdditionalDetails);
					FillPropertyValues(AdditionalAttributes, ResponseString);
					ObjectTablePart = ExchangeObject["AdditionalAttributes"];//XDTOList -  
					ObjectTablePart.Add(AdditionalAttributes);
				EndDo;
			EndIf;
			XDTOFactory.WriteXML(XMLResponseMessage, ExchangeObject);
		EndDo;
	EndIf;
	
	WriteMessage1.EndWrite();
	ExchangeMessage = XMLResponseMessage.Close();
	MobileApplicationSalesOrdersOverridable.ProcessExchangeMessage(ExchangeMessage);
	
	Return ExchangeMessage;
EndFunction

Procedure GenerateExchangeBatch(ExchangeNode, ExchangeMessage, Cancel, Mode = 0, AllPrices = False, ResponseStructure = Undefined)
	
	XMLWriter = New XMLWriter;
	
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	WriteMessage1.BeginWrite(XMLWriter, ExchangeNode);
	
	DataFromPreviousPartOfExchange = Undefined;
	If Mode = 0 Then
		MobileApplicationSalesOrdersOverridable.UploadCatalogsForExchange(XMLWriter, ExchangeNode);
	ElsIf Mode = 1 Then
		If ValueIsFilled(ResponseStructure.ResultMessage) Then
			AdditionalPropertiesInRepository = PreparedData(ResponseStructure.ResultMessage);
			If Not AdditionalPropertiesInRepository = Undefined 
				And TypeOf(AdditionalPropertiesInRepository) = Type("ValueStorage") Then
				DataFromPreviousPartOfExchange = AdditionalPropertiesInRepository.Get();
			EndIf;
		EndIf;
		MobileApplicationSalesOrdersOverridable.UploadPriceListForExchange(XMLWriter, ExchangeMessage, ExchangeNode,
			WriteMessage1.MessageNo, AllPrices, DataFromPreviousPartOfExchange);
	ElsIf Mode = 2 Then
		If ValueIsFilled(ResponseStructure.ResultMessage) Then
			AdditionalPropertiesInRepository = PreparedData(ResponseStructure.ResultMessage);
			If Not AdditionalPropertiesInRepository = Undefined 
				And TypeOf(AdditionalPropertiesInRepository) = Type("ValueStorage") Then
				DataFromPreviousPartOfExchange = AdditionalPropertiesInRepository.Get();
			EndIf;
		EndIf;
		MobileApplicationSalesOrdersOverridable.UnloadAvailableBalances(XMLWriter, ExchangeNode,
			DataFromPreviousPartOfExchange);
	ElsIf Mode = 3 Then
		If ValueIsFilled(ResponseStructure.ResultMessage) Then
			AdditionalPropertiesInRepository = PreparedData(ResponseStructure.ResultMessage);
			If Not AdditionalPropertiesInRepository = Undefined 
				And TypeOf(AdditionalPropertiesInRepository) = Type("ValueStorage") Then
				DataFromPreviousPartOfExchange = AdditionalPropertiesInRepository.Get();
			EndIf;
		EndIf;
		MobileApplicationSalesOrdersOverridable.UnloadClientsForExchange(XMLWriter, ExchangeNode,
			DataFromPreviousPartOfExchange);
	ElsIf Mode = 4 Then
		XMLWriter.WriteStartElement("ResultMessage");
		XMLWriter.Indent = True;
		XMLWriter.WriteRaw(ExchangeMessage);
		XMLWriter.WriteEndElement();
	ElsIf Mode = 5 Then
		MobileApplicationSalesOrdersOverridable.UploadTasksForSharing(XMLWriter, ExchangeNode, ExchangeMessage,
			WriteMessage1.MessageNo);
	ElsIf Mode = 6 Then
		If ValueIsFilled(ResponseStructure.ResultMessage) Then
			AdditionalPropertiesInRepository = PreparedData(ResponseStructure.ResultMessage);
			If Not AdditionalPropertiesInRepository = Undefined 
				And TypeOf(AdditionalPropertiesInRepository) = Type("ValueStorage") Then
				DataFromPreviousPartOfExchange = AdditionalPropertiesInRepository.Get();
			EndIf;
		EndIf;
		MobileApplicationSalesOrdersOverridable.UnloadClientsForExchange(XMLWriter, ExchangeNode,
			DataFromPreviousPartOfExchange, True);
	EndIf;
	
	WriteMessage1.EndWrite();
	
	If Not Cancel Then
		ExchangeMessage = XMLWriter.Close();
		If Not DataFromPreviousPartOfExchange = Undefined Then
			ResponseStructure.ResultMessage = "";
			ResponseStructure.Continue = False;
			If DataFromPreviousPartOfExchange.Continued Then
				ResponseStructure.ResultMessage = DataToContinue(New ValueStorage(DataFromPreviousPartOfExchange,
					New Deflation(9)));
				If Not IsBlankString(ResponseStructure.ResultMessage) Then
					ResponseStructure.Continue = True;
				EndIf;
			EndIf;
		EndIf;
		MobileApplicationSalesOrdersOverridable.ProcessExchangeMessage(ExchangeMessage);
	EndIf;
EndProcedure

Function IsObjectTable(Val XDTOProperty)
	
	If XDTOProperty.Properties().Count() = 1 Then
		PropertyXDTOProperties = XDTOProperty.Properties(); // XDTOPropertyCollection
		Return PropertyXDTOProperties.Get(0).UpperBound <> 1;
	EndIf;
	
	Return False;
EndFunction

Function StandardObjectStructure()
	
	StructureOfCatalog = New Structure;
	StructureOfCatalog.Insert("ref");
	StructureOfCatalog.Insert("DeletionMark");
	StructureOfCatalog.Insert("Description");
	
	Return StructureOfCatalog;
	
EndFunction

#EndRegion