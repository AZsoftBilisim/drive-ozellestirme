
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Exchange Service Bankfeeds Clientserver: Functions used both on the client and on the server
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
#Region Internal

// Generates the text of the hyperlink to be placed in the form of an element of the Catalog of the banking account of the organization.
//
// Parameters:
//  Organization  - CatalogRef.Companies - the organization specified in the invoice.
//  Bank  - CatalogRef.BankClassifier - the bank specified in the invoice.
//  InvoiceId  - String - ID of the account on the service
//
// Returns:
//   String - hyperlink text.
//
Function HeaderOfExchangeSettingsWithBank(Val Organization, Val Bank, Val InvoiceId) Export
	
	CurrentSetting = ExchangeWithBankFeedsServiceServerCall.ConfigureExchange(Organization, Bank);
	
	If ValueIsFilled(CurrentSetting)
		And InvoiceId <> "" Then
		
		Template = NStr("vi = 'Đã kết nối';
						|ru = 'Подключен';
						|en = 'Connected'; fa = 'متصل';
						|it = 'Подключен';
						|pl = 'Connected';
						|tr = 'Bağlandı'");
		
	Else 
		Template = NStr("vi = 'Kết nối dịch vụ';
						|ru = 'Подключить сервис';
						|en = 'Enable service'; fa = 'فعال‌سازی سرویس';
						|it = 'Подключить сервис';
						|pl = 'Enable service';
						|tr = 'Hizmeti bağla'") + " BankFeeds";;
	EndIf;

	Return Template;
	
EndFunction

#EndRegion
