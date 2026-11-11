////////////////////////////////////////////////////////////////////////////////
// The module "Gift Certificate Client" contains procedures and functions for 
// processing user actions in the process of working with gift certificates.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Procedure for processing the selection of a gift certificate.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  CurrentData - Structure - The data of the selected gift certificate contains:
//  	* Ref - CatalogRef.GiftCertificates
//  CodeType - EnumRef.CardCodeTypes - Type of map code.
//  RegisterNewOnes - Boolean - Notify the owner's form instead of the form.
//  SimplifiedRegistration - Boolean - 
//
Procedure ProcessGiftCertificateSelection(Form, CurrentData, CodeType, RegisterNewOnes = True, SimplifiedRegistration = True) Export
	
	FormIdentifier = Form.UUID;
	
	If ValueIsFilled(CurrentData.Ref) Then
		
		Notify(
			"GiftCertificateIsRead",
			New Structure("GiftCertificate, OwnerForm", CurrentData.Ref, FormIdentifier),
			Undefined);
		
		ShowUserNotification(
			NStr("vi = 'Đã đọc phiếu quà tặng';
				|ru = 'Считан подарочный сертификат';
				|en = 'Gift card is read'; fa = 'Gift card is read';
				|it = 'Buono regalo letto';
				|pl = 'Sczytano certyfikat podarunkowy';
				|tr = 'Hediye kartı okundu'"),
			GetURL(CurrentData.Ref),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã đọc phiếu quà tặng %1';
																			|ru = 'Считан подарочный сертификат %1';
																			|en = 'Gift card %1 is read'; fa = 'Gift card %1 is read';
																			|it = 'Buono regalo letto %1';
																			|pl = 'Sczytano certyfikat podarunkowy %1';
																			|tr = 'Hediye kartı okundu %1'"), CurrentData.Ref),
			PictureLib.Information32);
			
	ElsIf RegisterNewOnes Then
		// The card is not registered.
		
		If SimplifiedRegistration Then
			CurrentData.Ref = GiftCertificatesServerCall.RegisterGiftCertificateSimplistically(CurrentData.GiftCertificateKind, 
																												   CodeType,
																												   CurrentData.MagneticCode, 
																												   CurrentData.Barcode);
		Else
			GiftCertificateDataStructure = GiftCertificatesServerCall.InitializeGiftCertificateDescription();
			FillPropertyValues(GiftCertificateDataStructure, CurrentData);
			CurrentData.Ref = GiftCertificatesServerCall.RegisterGiftCertificate(GiftCertificateDataStructure);
		EndIf;	
		
		Notify(
			"Write_GiftCertificate",
			New Structure,
			CurrentData.Ref);
		
		Notify(
			"GiftCertificateIsRead",
			New Structure("GiftCertificate, OwnerForm", CurrentData.Ref, FormIdentifier),
			Undefined);
		
		ShowUserNotification(
			NStr("vi = 'Đã đọc phiếu quà tặng';
				|ru = 'Считан подарочный сертификат';
				|en = 'Gift card is read'; fa = 'Gift card is read';
				|it = 'Buono regalo letto';
				|pl = 'Sczytano certyfikat podarunkowy';
				|tr = 'Hediye kartı okundu'"),
			GetURL(CurrentData.Ref),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã đọc phiếu quà tặng %1';
																			|ru = 'Считан подарочный сертификат %1';
																			|en = 'Gift card %1 is read'; fa = 'Gift card %1 is read';
																			|it = 'Buono regalo letto %1';
																			|pl = 'Sczytano certyfikat podarunkowy %1';
																			|tr = 'Hediye kartı okundu %1'"), CurrentData.Ref),
			PictureLib.Information32);
			
	Else

		MessageText = NStr("vi = 'Trong chế độ này không cho phép ghi nhận phiếu quà tặng.';
							|ru = 'В этом режиме регистрация подарочного сертификата не разрешена.';
							|en = 'You cannot register gift cards in this mode.'; fa = 'You cannot register gift cards in this mode.';
							|it = 'In questa modalità non è consentita la registrazione del buono regalo.';
							|pl = 'W tym trybie rejestracja certyfikatu podarunkowego nie jest zezwolona.';
							|tr = 'Bu modda hediye kartı kaydına izin verilmedi.'");
		ShowUserNotification(
			MessageText,
			GetURL(CurrentData.Ref),
			MessageText,
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

// The procedure performs the processing of the received gift certificate code.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  CardCode - String - Received gift certificate code.
//  CodeType - EnumRef.CardCodeTypes - Code type of the received gift certificate.
//	AdditionalParameters - Structure - Additional parameters for processing the received code; See GiftCertificatesServerCall.ParametersForProcessingReceivedCode.
//
Procedure ProcessReceivedCodeOnClient(Form, CardCode, CodeType, AdditionalParameters) Export
	
	Filters = AdditionalParameters.Filters;
	FoundGiftCertificates = GiftCertificatesServerCall.ProcessReceivedCodeOnServer(CardCode, CodeType, AdditionalParameters);
	If FoundGiftCertificates.Count() = 0 Then
		InformUserThatGiftCertificateWasNotFound(CardCode, CodeType, Filters);
		Return;
	ElsIf FoundGiftCertificates.Count() > 1 Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("CodeType", CodeType);
		OpeningParameters.Insert("CardCode", CardCode);
		OpeningParameters.Insert("Filter", Filters);
		OpeningParameters.Insert("RegisterNewOnes", AdditionalParameters.RegisterNewOnes);
		OpenForm("Catalog.GiftCertificates.Form.ReadGiftCard", OpeningParameters, Form);
	ElsIf FoundGiftCertificates.Count() = 1 Then
		ProcessGiftCertificateSelection(Form, FoundGiftCertificates[0], CodeType, AdditionalParameters.RegisterNewOnes);
	EndIf;
	
EndProcedure

// The procedure opens a form for selecting gift certificates.
//
// Parameters:
//  CardCode - String, Array of String - Received gift certificate code.
//  CodeType - EnumRef.CardCodeTypes - Code type of the received gift certificate.
//  Filters - Structure - Data on the selections used.
//
Procedure InformUserThatGiftCertificateWasNotFound(CardCode, CodeType, Val Filters) Export
	
	Preprocessing = GiftCertificatesClientServer.DataPreprocessingIsRequired(CardCode, CodeType);
	MessageTexts = New Array;

	If TypeOf(Filters) = Type("Structure") And Filters.Count() Then
		
		PresentationsOfSelections = New Array;
		For Each Filter In Filters Do
			If Filter.Key = "OperationType" Then
				Continue;
			EndIf;
			SelectionValues = New Array();
			If TypeOf(Filter.Value) = Type("Array") Then
				SelectionValues = Filter.Value;
			Else
				SelectionValues.Add(Filter.Value);
			EndIf;
			If SelectionValues.Count() Then
				PresentationsOfSelections.Add(Chars.Tab + Filter.Key + ":");
				For Each FilterValue In SelectionValues Do
					PresentationsOfSelections.Add(Chars.Tab + Chars.Tab + FilterValue);
				EndDo;
			EndIf;
		EndDo;
		
		If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			MessageText = NStr("vi = 'Không tìm thấy phiếu quà tặng với mã vạch ""%1"". Sử dụng bộ lọc theo:';
								|ru = 'Подарочный сертификат со штрихкодом ""%1"" не найден. Использовался отбор по:';
								|en = 'A gift card with the %1 barcode is not found. The application used the filter by:'; fa = 'A gift card with the %1 barcode is not found. The application used the filter by:';
								|it = 'Buono regalo con codice a barre ""%1"" non trovato. Utilizzare filtro per:';
								|pl = 'Nie znaleziono certyfikatu podarunkowego z kodem kreskowym ""%1"". Został użyty filtr według:';
								|tr = '""%1"" barkodlu hediye kartı bulunamadı. Filtre kullanıldı:'");
		Else
			If Preprocessing Then
				MessageText = NStr("vi = 'Không tìm thấy phiếu quà tặng với mã từ đã đọc. Sử dụng bộ lọc theo:';
									|ru = 'Подарочный сертификат со считанным магнитным кодом не найден. Использовался отбор по:';
									|en = 'A gift card with the scanned magnetic code is not found. The application used the filter by:'; fa = 'A gift card with the scanned magnetic code is not found. The application used the filter by:';
									|it = 'Buono regalo con codice magnetico letto non trovato. Utilizzare filtro per:';
									|pl = 'Nie znaleziono certyfikatu podarunkowego z odczytanym kodem magnetycznym. Został użyty filtr według:';
									|tr = 'Okunabilir manyetik kodlu bir hediye kartı bulunamadı. Filtre kullanıldı:'");
			Else
				MessageText = NStr("vi = 'Không tìm thấy phiếu quà tặng với mã từ ""%1"". Sử dụng bộ lọc theo:';
									|ru = 'Подарочный сертификат с магнитным кодом ""%1"" не найден. Использовался отбор по:';
									|en = 'A gift card with the %1 magnetic code is not found. The application used the filter by:'; fa = 'A gift card with the %1 magnetic code is not found. The application used the filter by:';
									|it = 'Buono regalo con codice magnetico ""%1"" non trovato. Utilizzare filtro per:';
									|pl = 'Nie znaleziono certyfikatu podarunkowego z kodem magnetycznym ""%1"". Został użyty filtr według:';
									|tr = 'Manyetik kodu ""%1"" olan hediye kartı bulunamadı. Filtre kullanıldı:'");
			EndIf;
		EndIf;
		
	Else
		If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			MessageText = NStr("vi = 'Chưa ghi nhận phiếu quà tặng với mã vạch ""%1"".';
								|ru = 'Подарочный сертификат со штрихкодом ""%1"" не зарегистрирован.';
								|en = 'Gift card with the ""%1"" barcode is not registered.'; fa = 'Gift card with the ""%1"" barcode is not registered.';
								|it = 'Il buono regalo con codice a barre ""%1"" non è registrato.';
								|pl = 'Certyfikat podarunkowy z kodem kreskowym ""%1"" nie jest zarejestrowany.';
								|tr = '""%1"" barkodlu hediye kartı kayıtlı değil.'");
		Else
			If Preprocessing Then
				MessageText = NStr("vi = 'Chưa ghi nhận phiếu quà tặng với mã từ đã đọc.';
									|ru = 'Подарочный сертификат со считанным магнитным кодом не зарегистрирован.';
									|en = 'Gift card with the scanned magnetic code is not registered.'; fa = 'Gift card with the scanned magnetic code is not registered.';
									|it = 'Il buono regalo con il codice magnetico letto non è registrato.';
									|pl = 'Certyfikat podarunkowy z odczytanym kodem magnetycznym nie jest zarejestrowany.';
									|tr = 'Manyetik kodu okunmuş bir hediye kartı kaydedilmemiştir.'");
			Else
				MessageText = NStr("vi = 'Chưa ghi nhận phiếu quà tặng với mã từ ""%1"".';
									|ru = 'Подарочный сертификат с магнитным кодом ""%1"" не зарегистрирован.';
									|en = 'Gift card with the ""%1"" magnetic code is not registered.'; fa = 'Gift card with the ""%1"" magnetic code is not registered.';
									|it = 'Il buono regalo con codice magnetico ""%1"" non è registrato.';
									|pl = 'Certyfikat podarunkowy z kodem magnetycznym ""%1"" nie jest zarejestrowany.';
									|tr = 'Manyetik kodu ""%1"" olan bir hediye kartı kaydedilmedi.'");
			EndIf;
		EndIf;
	EndIf;
	
	MessageTexts.Add(MessageText);
	CommonClientServer.SupplementArray(MessageTexts, PresentationsOfSelections);
	
	CommonClient.MessageToUser(
		StringFunctionsClientServer.SubstituteParametersToString(StrConcat(MessageTexts, Chars.LF), CardCode));
	
EndProcedure

// The procedure opens a form for selecting gift certificates.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  SelectionFormParameters - Structure - Data for opening the matching form.
//
Procedure OpenGiftCertificateSelectionForm(Form, SelectionFormParameters) Export

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("AddressInStorage", SelectionFormParameters.AddressInStorage);
	FormOpenParameters.Insert("Currency", SelectionFormParameters.Currency);
	FormOpenParameters.Insert("Organization", SelectionFormParameters.Organization);
	FormOpenParameters.Insert("PayInAddition", SelectionFormParameters.PayInAddition);
	FormOpenParameters.Insert("ShowResultItRemainsToPayExtra", SelectionFormParameters.ShowResultItRemainsToPayExtra);
	FormOpenParameters.Insert("Filter", SelectionFormParameters.Filter);
	FormOpenParameters.Insert("RegisterNewOnes", SelectionFormParameters.RegisterNewOnes);
	
	OpeningModeSurcharge = False;
	SelectionFormParameters.Property("OpeningModeSurcharge", OpeningModeSurcharge);
	// By default, the form opens in the mode of selecting the surcharge, if the property of the mode of opening the surcharge is not passed.
	OpeningModeSurcharge = ?(OpeningModeSurcharge = Undefined, True, OpeningModeSurcharge);
	FormOpenParameters.Insert("OpeningModeSurcharge", OpeningModeSurcharge);
	
	FormOpenParameters.Insert("CurrentRowIndex", Undefined);
	SelectionFormParameters.Property("CurrentRowIndex", FormOpenParameters.CurrentRowIndex);
	
	If SelectionFormParameters.Property("AddressInStorageGoods") Then
		FormOpenParameters.Insert("AddressInStorageGoods", SelectionFormParameters.AddressInStorageGoods);
	EndIf;

	OpenForm(
		"Document.CashRegisterReceipt.Form.TabularFormGiftCertificates",
		FormOpenParameters,
		Form,,,,
		SelectionFormParameters.OnCloseNotifyDescription,
		FormWindowOpeningMode.LockOwnerWindow);	
	
EndProcedure

// Checks the possibility of adding a gift certificate.
// Parameters:
//  Form - ClientApplicationForm - 
//  CheckStatusOfEvent - Boolean -
//  
// Returns:
//  Boolean -
Function CheckPossibilityOfAddingGiftCertificate(Form, CheckStatusOfEvent = True) Export
	Result = True;
	
	ClearMessages();
	If Not ValueIsFilled(Form.Object.Organization) Then
		MessageText = NStr("vi = 'Trước khi thêm phiếu quà tặng, cần chọn doanh nghiệp.';
							|ru = 'Перед добавлением подарочного сертификата необходимо выбрать организацию.';
							|en = 'Before you add a gift card, select a company.'; fa = 'Before you add a gift card, select a company.';
							|it = 'Prima dell''aggiunta del buono regalo è necessario selezionare l''azienda.';
							|pl = 'Przed dodaniem certyfikatu podarunkowego należy wybrać firmę.';
							|tr = 'Hediye kartı eklenebilmesi için önce bir iş yeri seçilmesi gerekir.'");
		CommonClient.MessageToUser(MessageText,,"Organization", "Object.Organization");
		Result = False;
	EndIf;
	
	If CheckStatusOfEvent And Form.Object.Posted Then
		MessageText = NStr("vi = 'Trước khi thêm phiếu quà tặng, cần hủy kết chuyển chứng từ.';
							|ru = 'Перед добавлением подарочного сертификата необходимо отменить проведение документа.';
							|en = 'Before you add a gift card, unpost the document.'; fa = 'Before you add a gift card, unpost the document.';
							|it = 'Prima dell''aggiunta del buono regalo è necessario annullare la pubblicazione del documento.';
							|pl = 'Przed dodaniem certyfikatu podarunkowego należy anulować zatwierdzenie dokumentu.';
							|tr = 'Hediye kartı eklemeden önce belge kaydının kaldırılması gerekir.'");
		CommonClient.MessageToUser(MessageText,,,);
		Result = False;
	EndIf;
	
	Return Result
EndFunction

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  EventName				- String - the ID of the message by the receiving form (see the Notify method)
//	Parameter				- Arbitrary - message parameter (see Notify method)
//	Source				- Arbitrary - event source (see Notify method)
//  AdditionalParameters	- Structure - advanced setting.
//
Procedure NotificationProcessing(Form, EventName, Parameter, Source, AdditionalParameters = Undefined) Export
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = Form.UUID Then
		

	EndIf;

	Return;
	
EndProcedure

#Region PaymentDocumentsBasedOnGiftCertificate

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificate(ReferencesArrray, ExecutionParameters) Export

	If ValueIsFilled(ExecutionParameters.CommandDetails.FormName) Then

		CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
		FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
		
		OpenForm("Catalog.Counterparties.Form.ChoiceForm" 
					,New Structure("CurrentRow", PredefinedValue("Catalog.Counterparties.RetailCustomer"))
					,CommandExecuteParameters.Source
					,CommandExecuteParameters.Uniqueness
					,CommandExecuteParameters.Window
					,CommandExecuteParameters.URL
					,New CallbackDescription("SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificateCompletion", ThisObject, ExecutionParameters)
					,FormWindowOpeningMode.LockOwnerWindow);
					
	EndIf;
				
EndProcedure

Procedure SelectCounterpartyToEnterPaymentDocumentBasedOnGiftCertificateCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
		CommandDetails = AdditionalParameters.CommandDetails; // Structure
		FillPropertyValues(CommandExecuteParameters, CommandDetails.AdditionalParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("Basis", New Structure("GiftCertificate,Counterparty", AdditionalParameters.ReferencesArrray, Result));
		
		OpenForm(
			AdditionalParameters.CommandDetails.FormName,
			OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
			
	EndIf;
		
EndProcedure

#EndRegion

#EndRegion
