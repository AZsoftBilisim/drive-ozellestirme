
#Region Private

// The exchange start operation
// verifies that the desired node is added to the plan and initialized correctly.
//
// Parameters:
//  MobileApplicationVersion - String- the version number of the mobile application;
//  MobileDeviceID - String - the code of the mobile app that is not changed is used as the code of the exchange plan node.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - boolean flag of a successful End;
//  DeleteAppData is a boolean flag for clearing data on a mobile device.
//
Function StartExchange(MobileApplicationVersion, MobileDeviceID)
	
	Return MobileApplicationSalesOrders.ExchangeStart(MobileApplicationVersion, MobileDeviceID);
	
EndFunction

// Operation for getting
// information base settings to send to the mobile app.
//
// Parameters:
//  MobileDeviceID - String - the code of the mobile app that is not changed is used as the code of the exchange plan node.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - boolean flag for a successful End;
//  AddChangeCustomer - boolean flag for adding client changes;
//  AddChangeCustomerOrders - boolean flag for adding changes to customer orders;
//  UsingCustomerAgreement - number - use of agreements with clients:
//    0 - standard and individual agreements,
//    1 - standard agreements only,
//    2 - individual agreements only,
//    3 - agreements are not used;
//  UsePricesInOrderLine - Boolean flag for using price types in the customer's order lines (always true for TM/ERP);
//  UseCustomerContract - Boolean flag for using Contracts with clients;
//  UseGoodsBalance - Boolean flag for the use of information about Balance of goods (always true for TM/ERP);
//  PartnersHowContractors - boolean flag for using partners as counterparties;
//  UseCommission - boolean flag for using the commission;
//  UseManualDiscounts - boolean flag for using manual discounts;
//  UseStoreInOrderLine - boolean flag for using warehouses in the customer's order lines;
//  UseOrderStatus - Boolean flag for using customer order Statuses;
//  ChangePriceInOrder - Boolean flag for editing prices in an order;
//  FrequencyExchangeRates - number - frequency of item price request (in hours);
//  FrequencyExchangeBalance - number - frequency of requesting item Balances (in hours).
//
Function GetSettings(MobileDeviceID)
	
	Return MobileApplicationSalesOrders.ExportSettings(MobileDeviceID);
	
EndFunction

// Operation of receiving tasks to the sales representative
// of the information base for transmission to the mobile app.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetJobTargets(MobileDeviceID)
	
	Return MobileApplicationSalesOrders.UploadTasks(MobileDeviceID);
	
EndFunction

// Operation for getting the reference books "Currencies", "types of prices", "Organizations", "Warehouses"
// of the information base for transmission to the mobile app.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetCatalogs(MobileDeviceID)
	
	Return MobileApplicationSalesOrders.UploadCatalogs(MobileDeviceID);
	
EndFunction

// Operation for getting the prices of the item, as well as related reference
// books of the information base for transmission to the mobile app.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  AllPrices - Boolean - "True" - uploading all prices," False " - uploading only changed prices;
//  Address - String - address(name of the temporary file) of the prepared data for exchange.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetPriceList(MobileDeviceID, AllPrices = False, Address = "")
	
	Return MobileApplicationSalesOrders.UploadPriceList(MobileDeviceID, AllPrices, Address);
	
EndFunction

// Operation for getting the remaining inventory items, as well as related reference
// books of the information base for transmission to the mobile app.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  Address - String - address(name of the temporary file) of the prepared data for exchange.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetOddments(MobileDeviceID, Address = "")
	
	Return MobileApplicationSalesOrders.UnloadBalance(MobileDeviceID, Address);
	
EndFunction

// Operation for getting information about partners, as well as related directories
// of the information base for transmission to the mobile app.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  AllCustomers - Boolean - "True" - uploading information for all partners, "False" - uploading only for modified ones;
//  Customer - String - uploading information about a specific partner;
//  Address - String - address(name of the temporary file) of the prepared data for exchange.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetCustomers(MobileDeviceID, AllCustomers = False, Customer = "", Address = "")
	
	Return MobileApplicationSalesOrders.UnloadClients(MobileDeviceID, AllCustomers, Customer, Address);
	
EndFunction

// Operation for getting information about the status of customer orders.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains the structure of the query on the order status.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetStatusCustomersOrders(MobileDeviceID, MessageExchange)
	
	Return MobileApplicationSalesOrders.UploadDocumentStatuses(MobileDeviceID, MessageExchange, 0);
	
EndFunction

// Operation for getting information about the status of customer refund requests.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains the structure of the query on the order status.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function GetDocumentsStatus(MobileDeviceID, MessageExchange, TypeOfDocs)
	
	Return MobileApplicationSalesOrders.UploadDocumentStatuses(MobileDeviceID, MessageExchange, TypeOfDocs);
	
EndFunction

// Operation for recording customer orders created on a mobile device.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains information about customer orders.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function FillCustomersOrders(MobileDeviceID, MessageExchange)
	
	Return MobileApplicationSalesOrders.UploadCustomerOrders(MobileDeviceID, MessageExchange);
	
EndFunction

// Operation for recording customer orders created on a mobile device.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains information about customer orders.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function FillRequestsToReturn(MobileDeviceID, MessageExchange)
	
	Return MobileApplicationSalesOrders.UploadRequestsForReturnOfGoodsFromClient(MobileDeviceID, MessageExchange);
	
EndFunction

// Operation for recording sales representative tasks created on a mobile device.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains information on the specifications of the clients.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function FillJobTargets(MobileDeviceID, MessageExchange, JobTargetSettings)
	
	Return MobileApplicationSalesOrders.UploadTasksToSalesRepresentatives(MobileDeviceID, MessageExchange, JobTargetSettings);
	
EndFunction

// Operation for writing directories created on a mobile device.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains information on reference books for recording.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function FillCatalogs(MobileDeviceID, MessageExchange)
	
	Return MobileApplicationSalesOrders.DownloadCatalogs(MobileDeviceID, MessageExchange);
	
EndFunction

// Operation for recording customer orders created on a mobile device.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  MessageExchange - XDTODataObject - contains information about customer orders.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function FillCustomersPayments(MobileDeviceID, MessageExchange)
	
	Return MobileApplicationSalesOrders.LoadingCustomerPayments(MobileDeviceID, MessageExchange);
	
EndFunction

// Operation for recording the ID of the push notification recipient generated on the mobile device.
//
// Parameters:
//  MobileDeviceID - String - not modified code of a mobile application used as the site code of the exchange;
//  PushNotificationsSubscriberID - ValueStorage - ID of the push notification recipient.
//
// Returns:
//  XDTODataObject - contains the response structure:
//  ResultMessage - string - informational message;
//  Success - Boolean flag for a successful End.
//
Function FillPushNotificationsSubscriberID(MobileDeviceID, PushNotificationsSubscriberID)
	
	Return MobileApplicationSalesOrders.RecordSubscriberIDOfDeliveredNotifications(MobileDeviceID,
		PushNotificationsSubscriberID);
EndFunction

#EndRegion