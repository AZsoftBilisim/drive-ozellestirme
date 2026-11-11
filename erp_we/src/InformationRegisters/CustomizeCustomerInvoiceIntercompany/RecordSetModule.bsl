#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(
								Filter.CompanyOwner.Value, Filter.CompanyCustomer.Value);
	
	If Not CheckStructure.CurrenciesDoNotMatch Then
		ErrorText = NStr("vi = 'Tiền tệ kế toán tài chính của chủ sở hữu %1 và người bán %2 phải trùng nhau.';
						|ru = 'Валюты регламентированного учета владельца %1 и продавца %2 должны совпадать.';
						|en = 'Local accounting currencies of the %1 owner and the %2 seller must match.'; fa = 'Local accounting currencies of the %1 owner and the %2 seller must match.';
						|it = 'Le valute della contabilità regolatoria del proprietario %1 e del venditore %2 devono coincidere.';
						|pl = 'Waluty ewidencji reglamentowanej właściciela %1 i sprzedawcy %2 powinny być jednakowe.';
						|tr = 'Sahip %1 ve satıcı %2''nin yerel muhasebe para birimleri eşleşmelidir.'");
		ErrorText = StrTemplate(ErrorText, Filter.CompanyOwner.Value, Filter.CompanyCustomer.Value);
		Common.MessageToUser(ErrorText, , "CompanyOwner",, Cancel);
	EndIf;
	
	If Not CheckStructure.CountriesMatch Then
		ErrorText = NStr("vi = 'Quốc gia đăng ký của chủ sở hữu %1 và người bán %2 phải trùng nhau.';
						|ru = 'Страны регистрации владельца %1 и продавца %2 должны совпадать.';
						|en = 'Countries of residence of owner %1 and seller %2 must be the same.'; fa = 'Countries of residence of owner %1 and seller %2 must be the same.';
						|it = 'I paesi di registrazione del proprietario %1 e del venditore %2 devono corrispondere.';
						|pl = 'Kraje rejestracji właściciela %1 i sprzedawcy %2 powinny być zgodne.';
						|tr = 'Sahip %1 ve satıcı %2''nin kayıtlı olduğu ülkeler eşleşmelidir.'");
		ErrorText = StrTemplate(ErrorText, Filter.CompanyOwner.Value, Filter.CompanyCustomer.Value);
		Common.MessageToUser(ErrorText, , "CompanyOwner",, Cancel);
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If ThisObject[0].GoodsTransferMethod <> Enums.GoodsTransferMethods.TransferToCommissionAgent Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
EndProcedure

#EndRegion

#EndIf
