///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

 // Parameters:
//   ReportForm - ClientApplicationForm:
//    * ReportSpreadsheetDocument - SpreadsheetDocument
//   Command - FormCommand
//   Result - Boolean
// 
Procedure OnProcessCommand(ReportForm, Command, Result) Export
	
	If ReportForm.ReportSettings.FullName = "Report.RenewDigitalSignatures" Then
		
		FormParameters = New Structure("ExtensionMode", ReportForm.CurrentVariantKey);
		OpenForm("CommonForm.RenewDigitalSignatures", FormParameters, ReportForm, ReportForm.UniqueKey);
		
	EndIf;
	
EndProcedure

// Obtains installed cryptographic service providers.
//  
// Parameters:
//  Notification - CallbackDescription - Runtime result notification. One of the types::
//    = Undefined - Failed to obtain data (no cryptography extension or add-in is installed)
//    = Structure:
//      # CheckCompleted = Boolean - If True, the check is successful, the installed CSP are detected.
//        If False, populate Error.
//      # Error = String - Error details
//      # Cryptoproviders = Array of DigitalSignatureInternalClientServer.NewExtendedApplicationDetails
//      # CryptoProvidersAtServer = Array of DigitalSignatureInternalClientServer.NewExtendedApplicationDetails
//  CheckParameters - Undefined
//                    - Structure:
//                         * ShouldInstallExtension - Boolean - Flag indicating whether to install the digital signature extension.
//                         * SetComponent - Boolean - Flag indicating whether to install the digital signature add-in.
//                         * CheckAtServer1      - Boolean - Flag indicating whether to get a list of CSP on server.
// 
Procedure GetInstalledCryptoProviders(Notification, CheckParameters = Undefined) Export

	Context = New Structure;
	Context.Insert("ShouldInstallExtension", True);
	Context.Insert("SetComponent", True);
	Context.Insert("Result", InstalledCryptoProvidersGettingResult());
	
	CheckAtServer1 = Undefined;
	
	If TypeOf(CheckParameters) = Type("Structure") Then
		FillPropertyValues(Context, CheckParameters);
		CheckAtServer1 = CommonClientServer.StructureProperty(CheckParameters, "CheckAtServer1", Undefined);
	EndIf;
	
	If CheckAtServer1 = Undefined Then
		CheckAtServer1 = DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
		Or DigitalSignatureClient.GenerateDigitalSignaturesAtServer();
	EndIf;
	
	If CheckAtServer1 Then
		ResultIsAtServer = DigitalSignatureInternalServerCall.InstalledCryptoProviders();
		If ResultIsAtServer.CheckCompleted Then
			Context.Result.CryptoProvidersAtServer = ResultIsAtServer.Cryptoproviders;
		EndIf;
	EndIf;

	Context.Insert("Notification", Notification);
	Context.Insert("ShouldContinueWithoutInstallingExtention", True);
	
	ContinuationNotification = New CallbackDescription("GetInstalledCryptoProvidersAfterAddInAttached",
		ThisObject, Context);
	RunAfterExtensionAndAddInChecked(ContinuationNotification, Context);
	
EndProcedure

// Obtains revocation list addresses from a certificate, downloads them, and installs into an intermediate certificate storage
// 
// Parameters:
//  RevocationListInstallationParameters - See RevocationListInstallationParameters
//
Procedure SetListOfCertificateRevocation(RevocationListInstallationParameters) Export
	
	If Not DigitalSignatureClient.CommonSettings().AccessToInternetServicesAllowed Then
		HandlerErrorOfSettingRevocationList(
			DigitalSignatureInternalClientServer.AccessToInternetServicesDeniedMessageText(),
			RevocationListInstallationParameters);
		Return;
	EndIf;
	
	Notification = New CallbackDescription("InstallCertificateRevocationListAfterAddInAttached",
			ThisObject, RevocationListInstallationParameters);
	
	Parameters = New Structure;
	
	If ValueIsFilled(RevocationListInstallationParameters.ExplanationText) Then
		Parameters.Insert("ExplanationText", RevocationListInstallationParameters.ExplanationText);
	EndIf;
	
	RunAfterExtensionAndAddInChecked(Notification, Parameters);
	
EndProcedure

// Revocation list installation parameters.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - address in temporary storage.
//             - String - Certificate's string presentation in the Base64 format.
//             - CryptoCertificate
// 
// Returns:
//  Structure:
//   * Certificate - BinaryData
//             - String - address in temporary storage.
//             - String - Certificate's string presentation in the Base64 format.
//             - CryptoCertificate
//   * Addresses  - String - Revocation list address. If not specified, the list will be downloaded from the addresses provided in the certificate.
//             - Array of String
//   * InternalAddress - String - If specified, the revocation list will be saved to cache.
//   * CallbackOnCompletion - Undefined
//                           - CallbackDescription - Notification to display after the installation with the result:
//                              # Structure:
//                                ## IsInstalledSuccessfully - Boolean
//                                ## Message - Installation result message
//   * Form - ClientApplicationForm - Installation form owner
//   * ExplanationText - String - Text of the add-in installation note.
//
Function RevocationListInstallationParameters(Certificate) Export
	
	RevocationListInstallationParameters = New Structure;
	RevocationListInstallationParameters.Insert("Certificate", Certificate);
	RevocationListInstallationParameters.Insert("Addresses", New Array);
	RevocationListInstallationParameters.Insert("InternalAddress");
	RevocationListInstallationParameters.Insert("CallbackOnCompletion");
	RevocationListInstallationParameters.Insert("Form");
	RevocationListInstallationParameters.Insert("ExplanationText");
	
	Return RevocationListInstallationParameters;
	
EndFunction

// Install certificate
// 
// Parameters:
//  CertificateInstallationParameters - See CertificateInstallationParameters
//
Procedure InstallCertificate(CertificateInstallationParameters) Export
	
	Notification = New CallbackDescription("InstallCertificateAfterAddInAttached",
		ThisObject, CertificateInstallationParameters);
	RunAfterExtensionAndAddInChecked(Notification);
	
EndProcedure

// Gets a root certificate from the certificate data and installs it.
// 
// Parameters:
//  CertificateInstallationParameters - See CertificateInstallationParameters 
//                                - Structure:
//                                   * Certificate - BinaryData
//                                                - String - address in temporary storage
//                                                - String - string Presentation of the certificate in base64 format
//                                                - CryptoCertificate
//                                   * Storage - Structure:
//                                      ** Value - String
//                                      ** Presentation - String
//
Procedure InstallRootCertificate(CertificateInstallationParameters) Export
	
	InstallationParameters = CertificateInstallationParameters(CertificateInstallationParameters.Certificate);
	FillPropertyValues(InstallationParameters, CertificateInstallationParameters);
	Notification = New CallbackDescription("InstallRootCertificateAfterAddInAttached",
		ThisObject, InstallationParameters);
	RunAfterExtensionAndAddInChecked(Notification);
	
EndProcedure 

// Certificate installation parameters.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Certificate's string presentation in the Base64 format
//             - CryptoCertificate
// 
// Returns:
//  Structure:
//   * Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Certificate's string presentation in the Base64 format
//             - CryptoCertificate
//   * CallbackOnCompletion - CallbackDescription - Notification to display after the installation.
//                             Notification result - Structure:
//                                       # IsInstalledSuccessfully - Installation success flag.
//                                       # Message - Error or installation result message.
//   * InstallationOptions - ValueList - Intended for the selection in the installation form
//   * Storage - String - Storage name
//               - Structure:
//                  ** Value - Storage name
//                  ** Presentation - Presentation in the installation form
//   * ContainerProperties - Structure:
//                           ** Name - String - Container name
//                           ** ApplicationType - Number - Type of the CSP app
//                           ** ApplicationName - String - Name of the CSP app
//                           ** ApplicationPath - String - Name of the CSP app
//   * WarningText - String - Intended for the display in the installation form
//   * Form - ClientApplicationForm - Installation form owner
//
Function CertificateInstallationParameters(Certificate) Export
	
	CertificateInstallationParameters = New Structure;
	CertificateInstallationParameters.Insert("Certificate", Certificate);
	CertificateInstallationParameters.Insert("CallbackOnCompletion", Undefined);
	CertificateInstallationParameters.Insert("InstallationOptions", Undefined);
	CertificateInstallationParameters.Insert("Storage", Undefined);
	CertificateInstallationParameters.Insert("ContainerProperties", Undefined);
	CertificateInstallationParameters.Insert("WarningText", "");
	CertificateInstallationParameters.Insert("Form", Undefined);
	
	Return CertificateInstallationParameters;
	
EndFunction

// Opens an error dialog.
// 
// Parameters:
//  FormCaption - String - Form title
//  ErrorTitle - String - Error title
//  ErrorAtClient - Structure:
//   * Errors - Array
//  ErrorAtServer - Structure
//  AdditionalParameters - Undefined, Structure:
//   * Certificate 
//  ContinuationHandler - CallbackDescription - Continuation handler
//
Procedure ShowApplicationCallError(FormCaption, ErrorTitle, ErrorAtClient, ErrorAtServer,
				AdditionalParameters = Undefined, ContinuationHandler = Undefined) Export
	
	If TypeOf(ErrorAtClient) <> Type("Structure") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với thủ tục %1
			           |đã chỉ ra sai kiểu tham số %2.';
			           |ru = 'Для процедуры %1
			           |указан некорректный тип параметра %2.';
			           |en = 'Procedure ""%1""
			           |has parameter with invalid type ""%2"".'; fa = 'Procedure ""%1""
			           |has parameter with invalid type ""%2"".';
			           |it = 'Per la procedura %1
			           | è indicato un tipo errato di parametro %2.';
			           |pl = 'Dla procedury %1 
			           |jest określony nieprawidłowy typ parametru %2.';
			           |tr = '%1
			           | prosedür için yanlış %2parametre değeri belirtildi.'"),
				"ShowApplicationCallError", "ErrorAtClient");
	EndIf;
	
	If TypeOf(ErrorAtServer) <> Type("Structure") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với thủ tục %1
			           |đã chỉ ra sai kiểu tham số %2.';
			           |ru = 'Для процедуры %1
			           |указан некорректный тип параметра %2.';
			           |en = 'Procedure ""%1""
			           |has parameter with invalid type ""%2"".'; fa = 'Procedure ""%1""
			           |has parameter with invalid type ""%2"".';
			           |it = 'Per la procedura %1
			           | è indicato un tipo errato di parametro %2.';
			           |pl = 'Dla procedury %1 
			           |jest określony nieprawidłowy typ parametru %2.';
			           |tr = '%1
			           | prosedür için yanlış %2parametre değeri belirtildi.'"),
				"ShowApplicationCallError", "ErrorAtServer");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowInstruction",                True);
	FormParameters.Insert("ShowOpenApplicationsSettings", False);
	FormParameters.Insert("ShowExtensionInstallation",       False);
	
	AdditionalData = New Structure;
	AdditionalData.Insert("UnsignedData");
	AdditionalData.Insert("Certificate");
	AdditionalData.Insert("Signature");
	AdditionalData.Insert("AdditionalDataChecksOnClient");
	AdditionalData.Insert("AdditionalDataChecksOnServer");
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(FormParameters, AdditionalParameters);
		FillPropertyValues(AdditionalData, AdditionalParameters);
	EndIf;
	
	FormParameters.Insert("AdditionalData", AdditionalData);
	
	FormParameters.Insert("FormCaption",  FormCaption);
	FormParameters.Insert("ErrorTitle", ErrorTitle);
	
	DigitalSignatureClientLocalization.OnGetErrorAtClient(ErrorAtClient);
	FormParameters.Insert("ErrorAtClient", ErrorAtClient);
	FormParameters.Insert("ErrorAtServer", ErrorAtServer);
	
	Context = New Structure;
	Context.Insert("FormParameters", FormParameters);
	Context.Insert("ContinuationHandler", ContinuationHandler);
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"ShowApplicationCallErrorAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Opens the certificate selection form.
// 
// Parameters:
//  ServerParameters1 - Structure:
//   * Organization - DefinedType.Organization 
//   * Individual - DefinedType.Individual
//   * CertificateBasis - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates 
//   * ToEncryptAndDecrypt - Boolean, Undefined
//   * CanAddToList - Boolean
//   * PersonalListOnAdd - Boolean 
//   * Organization - DefinedType.Organization 
//  NewFormOwner - Undefined, Form -  Form owner
//  CompletionHandler - Undefined, NotifyDescription
//
Procedure SelectSigningOrDecryptionCertificate(ServerParameters1, NewFormOwner = Undefined, CompletionHandler = Undefined) Export
	
	If NewFormOwner = Undefined Then
		NewFormOwner = New UUID;
	EndIf;
	
	Context = New Structure;
	Context.Insert("ServerParameters1", ServerParameters1);
	Context.Insert("NewFormOwner", NewFormOwner);
	Context.Insert("CompletionHandler", CompletionHandler);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
		And ServerParameters1.Property("ExecuteAtServer")
		And ServerParameters1.ExecuteAtServer = True Then
		
		Result = New Structure;
		Result.Insert("CertificatesPropertiesAtClient", New Array);
		Result.Insert("ErrorOnGetCertificatesAtClient", New Structure);
		
		SelectSigningOrDecryptionCertificateContinued(Result, Context);
	Else
		GetCertificatesPropertiesAtClient(New CallbackDescription(
			"SelectSigningOrDecryptionCertificateContinued", ThisObject, Context), True, False);
	EndIf;
	
EndProcedure

// See DigitalSignature.CertificateProperties
Async Function CertificateProperties(Certificate) Export
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		CertificateBinaryData = Await Certificate.UnloadAsync();
	ElsIf TypeOf(Certificate) = Type("FixedStructure") Then
		CertificateBinaryData = Certificate.Certificate;
	Else
		CertificateBinaryData = Undefined;
	EndIf;
			
	Return DigitalSignatureInternalClientServer.CertificateProperties(Certificate,
		UTCOffset(), CertificateBinaryData);
		
EndFunction

Procedure TimestampServersDiagnostics(Location = Undefined) Export
	
	DiagnosticsResult = New Array;

	TimestampServersAddresses = DigitalSignatureClient.CommonSettings().TimestampServersAddresses;

	If TimestampServersAddresses.Count() = 0 Then
		DiagnosticsResult.Add(NStr(
			"vi = 'Chưa điền địa chỉ máy chủ dấu thời gian trong tùy chỉnh chữ ký điện tử.';
			|ru = 'Адреса серверов меток времени не заполнены в настройках электронной подписи.';
			|en = 'The addresses of timestamp servers are unfilled in digital signature settings.'; fa = 'The addresses of timestamp servers are unfilled in digital signature settings.';
			|it = 'Адреса серверов меток времени не заполнены в настройках электронной подписи.';
			|pl = 'The addresses of timestamp servers are unfilled in digital signature settings.';
			|tr = 'Elektronik imza ayarlarında zaman damgası sunucu adresleri doldurulmamıştır.'"));
	Else
		If Location = "Client" Or Location = Undefined Then
			DiagnosticsResult.Add(TimestampServersDiagnosticsResult());
		EndIf;

		If Location = "Server" Or Location = Undefined
			And DigitalSignatureClient.CommonSettings().GenerateDigitalSignaturesAtServer Then
			If DiagnosticsResult.Count() > 0 Then
				DiagnosticsResult.Add(Chars.LF);
			EndIf;
			DiagnosticsResult.Add(
				DigitalSignatureInternalServerCall.TimestampServersDiagnosticsResult());
		EndIf;
	EndIf;
	
	TextDocument = New TextDocument;
	TextDocument.SetText(StrConcat(DiagnosticsResult, Chars.LF));
	TextDocument.Show(NStr("vi = 'Chẩn đoán tính khả dụng của máy chủ dấu thời gian';
							|ru = 'Диагностика доступности серверов меток времени';
							|en = 'Test the availability of timestamp servers'; fa = 'Test the availability of timestamp servers';
							|it = 'Диагностика доступности серверов меток времени';
							|pl = 'Test the availability of timestamp servers';
							|tr = 'Zaman damgası sunucu adreslerinin tanılaması.'"),);
	
EndProcedure

// Opens the certificate form.
// 
// Parameters:
//  FormParameters - Structure
//  OwnerForm - ClientApplicationForm
//  CallbackOnCompletion - CallbackDescription
//
Procedure OpenCertificateForm(FormParameters, OwnerForm = Undefined, CallbackOnCompletion = Undefined) Export

	OpenForm("CommonForm.Certificate", FormParameters, OwnerForm,,,, CallbackOnCompletion, ?(OwnerForm
		= Undefined, Undefined, FormWindowOpeningMode.LockOwnerWindow));

EndProcedure

// Opens a form with the detailed error presentation.
// 
// Parameters:
//  FormParameters - Structure
//  OwnerForm - ClientApplicationForm
//  CallbackOnCompletion - CallbackDescription
//
Procedure OpenExtendedErrorPresentationForm(FormParameters, OwnerForm = Undefined, CallbackOnCompletion = Undefined) Export
	
	OpenForm("CommonForm.ExtendedErrorPresentation", FormParameters, OwnerForm,,,, CallbackOnCompletion, ?(OwnerForm
		= Undefined, Undefined, FormWindowOpeningMode.LockOwnerWindow))
	
EndProcedure

// Opens a form by the passed details.
// 
// Parameters:
//  ApplicationDetails - Undefined, Structure, String - If set to "Undefined" or "String" (where "String" is the ID of the initial population setting),
//                        opens the app creation form.
//  OwnerForm - ClientApplicationForm
//  CallbackOnCompletion - CallbackDescription
//
Procedure OpenAppForm(ApplicationDetails = Undefined, OwnerForm = Undefined, CallbackOnCompletion = Undefined) Export

	WindowOpeningMode = ?(OwnerForm = Undefined, Undefined,
			FormWindowOpeningMode.LockOwnerWindow);
	
	If ApplicationDetails = Undefined Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.ObjectForm", , OwnerForm,,,,
			CallbackOnCompletion, WindowOpeningMode);
		Return;
	EndIf;
	
	If TypeOf(ApplicationDetails) = Type("String") Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.ObjectForm", New Structure("SuppliedSettingID", ApplicationDetails) , OwnerForm,,,,
			CallbackOnCompletion, WindowOpeningMode);
		Return;
	EndIf;
	
	AppParameters = DigitalSignatureInternalClientServer.NewExtendedApplicationDetails();
	FillPropertyValues(AppParameters, ApplicationDetails);

	If ValueIsFilled(AppParameters.Ref) Then
		ShowValue(CallbackOnCompletion, AppParameters.Ref);
	ElsIf AppParameters.AutoDetect = False Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.ObjectForm", New Structure("Application",
			AppParameters), OwnerForm,,,,CallbackOnCompletion, WindowOpeningMode);
	Else
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.Form.ApplicationDefinedAutomatically",
			New Structure("Application", AppParameters), OwnerForm,,,, CallbackOnCompletion, WindowOpeningMode);
	EndIf;

EndProcedure

// Opens the form for installing cryptographic tools.
// 
// Parameters:
//  Parameters - Structure
//  Owner - ClientApplicationForm
//  Notification - CallbackDescription
//
Procedure OpenCryptoProviderAppsInstallationForm(Parameters = Undefined, Owner = Undefined, Notification = Undefined) Export
	
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnOpenCryptoProviderAppsInstallationForm(
		Parameters, Owner, Notification, StandardProcessing);
	
	If StandardProcessing Then
		ShowMessageBox(, NStr("vi = 'Thao tác không được phép trong ứng dụng';
								|ru = 'Действие недоступно в приложении';
								|en = 'Application does not support this action'; fa = 'Application does not support this action';
								|it = 'Application does not support this action';
								|pl = 'Application does not support this action';
								|tr = 'Uygulamadaki kullanılabilir eylemler'"));
	EndIf;
	
EndProcedure

// Opens the data presentation by the hyperlink on the form.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Item - FormItems
//  StandardProcessing - Boolean
//  CurrentPresentationsList - ValueList
//
Procedure DataPresentationClick(Form, Item, StandardProcessing, CurrentPresentationsList) Export
	
	StandardProcessing = False;
	
	If CurrentPresentationsList.Count() > 1 Then
		ListDataPresentations = New Array;
		For Each ListItem In CurrentPresentationsList Do
			ListDataPresentations.Add(ListItem.Presentation);
		EndDo;
		FormParameters = New Structure;
		FormParameters.Insert("ListDataPresentations", ListDataPresentations);
		FormParameters.Insert("DataPresentation", Form.DataPresentation);
		NewForm = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.DataView",
			FormParameters, Item);
		If NewForm = Undefined Then
			Return;
		EndIf;
		NewForm.SetPresentationList(CurrentPresentationsList, Undefined);
	Else
		Value = CurrentPresentationsList[0].Value;
		If TypeOf(Value) = Type("CallbackDescription") Then
			RunCallback(Value);
		Else
			ShowValue(, Value);
		EndIf;
	EndIf;
	
EndProcedure

// Returns the presentation of form data.
//
// Parameters:
//   Form - ClientApplicationForm
//
Function FullDataPresentation(Form) Export
	
	Items = Form.Items;
	ItemDataPresentation = Items.DataPresentation; // FormField
	If Items.DataPresentation.TitleLocation <> FormItemTitleLocation.None
	   And ValueIsFilled(ItemDataPresentation.Title) Then
	
		Return ItemDataPresentation.Title + ": " + Form.DataPresentation;
	Else
		Return Form.DataPresentation;
	EndIf;
	
EndFunction

Function ClassifierError(ErrorText, ErrorAtServer = False, SignatureVerificationError = False,
		IsCertificateSpecified = False) Export
	
	Return DigitalSignatureInternalClientCached.ClassifierError(
		ErrorText, ErrorAtServer, SignatureVerificationError, IsCertificateSpecified);
	
EndFunction

Function ErrorTextDeviceNotSupported() Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thao tác chỉ hợp lệ trên máy tính có hệ điều hành %1, %2 hoặc %3.';
					|ru = 'Действие доступно только на компьютерах с операционной системой %1, %2 или %3.';
					|en = 'The action is only available on computers running on %1, %2, or %3.'; fa = 'The action is only available on computers running on %1, %2, or %3.';
					|it = 'Действие доступно только на компьютерах с операционной системой %1, %2 или %3.';
					|pl = 'The action is only available on computers running on %1, %2, or %3.';
					|tr = 'Bu özellikler sadece %1, %2 veya %3 işletim sistemlerinin olduğu bilgisayarlarda mevcut.'"),
					"MacOS", "Windows", "Linux");
EndFunction

#EndRegion

#Region Private

Procedure OpenToken(Token, FormOwner, CompletionProcessing = Undefined) Export
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Token", Token);
	OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.Form.Token",
		ServerParameters1, FormOwner, CompletionProcessing);
	
EndProcedure

Function TokenRecommendations() Export
	
	Return NStr("vi = 'Hãy đảm bảo rằng, token đã được cắm đúng vào cổng USB của máy tính và đèn báo sáng trên token, cập nhật danh sách token và thực hiện lại thao tác.
		|Nếu token không được tìm thấy sau khi cập nhật danh sách token, hãy thử cổng USB khác hoặc máy tính khác.';
		|ru = 'Убедитесь, что токен правильно вставлен в USB-порт компьютера и на нем горит световой индикатор, обновите список токенов и повторите действие.
		|Если токен не найден после обновления списка токенов, попробуйте другой USB-порт или другой компьютер.';
		|en = 'Make sure the token is properly inserted into the computer''s USB port and its indicator light is on. 
		|Refresh the token list and try again. If the token is still not found, try a different USB port or another computer.'; fa = 'Make sure the token is properly inserted into the computer''s USB port and its indicator light is on. 
		|Refresh the token list and try again. If the token is still not found, try a different USB port or another computer.';
		|it = 'Убедитесь, что токен правильно вставлен в USB-порт компьютера и на нем горит световой индикатор, обновите список токенов и повторите действие.
		|Если токен не найден после обновления списка токенов, попробуйте другой USB-порт или другой компьютер.';
		|pl = 'Make sure the token is properly inserted into the computer''s USB port and its indicator light is on. 
		|Refresh the token list and try again. If the token is still not found, try a different USB port or another computer.';
		|tr = 'Token''ın bilgisayarın USB bağlantı noktasına doğru şekilde takıldığından ve ışığının yandığından emin olun, token listesini yenileyin ve işlemi tekrarlayın.
		|Token listesini yeniledikten sonra token bulunamazsa farklı bir USB bağlantı noktası veya bilgisayar deneyin.'");
	
EndFunction

Function TokenNotFoundError() Export
	
	Return NStr("vi = 'Chưa kết nối token';
				|ru = 'Не подключен токен';
				|en = 'Token is not connected'; fa = 'Token is not connected';
				|it = 'Не подключен токен';
				|pl = 'Token is not connected';
				|tr = 'Token bağlanmamıştır.'");
	
EndFunction

Function ParametersOfSignatureOnToken(Token, Certificate, SignatureType) Export
	
	Structure = New Structure;
	Structure.Insert("Token", Token);
	Structure.Insert("Certificate", Certificate);
	Structure.Insert("SignatureType", SignatureType);
	Structure.Insert("DetachedAddIn", True);
	Structure.Insert("ComponentObject", Undefined);
	Structure.Insert("ShouldIncludeCertificateInSignature", True);
	
	Return Structure;
	
EndFunction

Function SignatureOnTokenCheckParameters(SignAlgorithm = Undefined)
	
	Structure = New Structure;
	Structure.Insert("SignAlgorithm", SignAlgorithm);
	Structure.Insert("ComponentObject", Undefined);
	Structure.Insert("ShouldReturnCertificatesForVerification", False);
	Structure.Insert("DetachedSignature", True);

	Return Structure;
	
EndFunction

Procedure AddCertificateFromTokenAfterReceiveSignature(Result, Context) Export
	
	If TypeOf(Result) = Type("String") Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			Context.ErrorAtClient,
			New Structure("Ref, Token", Context.Token.Presentation, Context.Token),
			"Signing",
			Result,
			Context.IsFullUser);
		RunCallback(Context.CompletionHandler, Undefined);
		ReportCertificateAddingError(Context);
		Return;
	EndIf;
	
	Context.Insert("ApplicationDetails", New Structure("Ref", Undefined));
	AddCertificateLoopAfterSigning(Result, Context);

EndProcedure

Procedure AddCertificateFromTokenAfterDecryption(Result, Context) Export
	
	If TypeOf(Result) = Type("String") Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			Context.ErrorAtClient,
			New Structure("Ref, Token", Context.Token.Presentation, Context.Token),
			"Details",
			Result,
			Context.IsFullUser);
		RunCallback(Context.CompletionHandler, Undefined);
		ReportCertificateAddingError(Context);
		Return;
	EndIf;
	
	Context.Insert("ApplicationDetails", New Structure("Ref", Undefined));
	AddCertificateLoopAfterSigning(Result, Context);

EndProcedure

Procedure AddCertificateFromTokenAfterEncryption(Result, Context) Export
	
	If TypeOf(Result) = Type("String") Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			Context.ErrorAtClient,
			New Structure("Ref, Token", Context.Token.Presentation, Context.Token),
			"Encryption",
			Result,
			Context.IsFullUser);
		RunCallback(Context.CompletionHandler, Undefined);
		ReportCertificateAddingError(Context);
		Return;
	EndIf;
	
	DecryptionOnTokenParameters = DecryptionOnTokenParameters(Context.Token, Context.CryptoCertificate);
	Notification = New CallbackDescription("AddCertificateFromTokenAfterDecryption", ThisObject, 
			Context);
			
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnDecryptionOnToken(Notification, DecryptionOnTokenParameters, Result, StandardProcessing);
	If StandardProcessing Then
		RunCallback(Context.CompletionHandler, Undefined);
		ReportCertificateAddingError(Context);
	EndIf;
	
EndProcedure

Function EncryptionOnTokenParameters(Token, Certificate, EncryptAlgorithm = Undefined) Export
	
	Structure = New Structure;
	Structure.Insert("Token", Token);
	Structure.Insert("Certificate", Certificate);
	Structure.Insert("EncryptAlgorithm", EncryptAlgorithm);
	Structure.Insert("ComponentObject", Undefined);
		
	Return Structure;
	
EndFunction

Function DecryptionOnTokenParameters(Token, Certificate) Export
	
	Structure = New Structure;
	Structure.Insert("Token", Token);
	Structure.Insert("Certificate", Certificate);
	Structure.Insert("ComponentObject", Undefined);
		
	Return Structure;
	
EndFunction

Procedure PasswordFieldStartChoice(Form, InternalData, PasswordProperties, StandardProcessing, AdditionalParameters = Undefined) Export
	
	StandardProcessing = False;
	Item = Form.Items.Password;
	
	Item.PasswordMode = Not Item.PasswordMode;
	If Item.PasswordMode Then
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
	Else
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedHidden;
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	AdditionalParameters.Insert("OnTogglePasswordConcealMode", True);
	
	ProcessPasswordInForm(Form,
		InternalData, PasswordProperties, AdditionalParameters, Item.EditText);
	
EndProcedure

Function InteractiveCryptographyModeUsed(CryptoManager) Export
	
	If TypeOf(CryptoManager) = Type("Structure") And Not CryptoManager.Property("InteractiveModeUse") Then
		Return False;
	EndIf;
	
	If CryptoManager.InteractiveModeUse = InteractiveCryptoModeUsageUse() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// In Linux and MacOS, when creating a crypto manager,
// it is required to specify the path to the application.
//
// Returns:
//  Boolean
//
Function RequiresThePathToTheProgram() Export
	
	Return CommonClient.IsLinuxClient()
		Or CommonClient.IsMacOSClient();
	
EndFunction

Procedure ToObtainThePathToTheProgram(CompletionProcessing, ProgramLink) Export
	
	Result = New Structure("ApplicationPath, Exists", "", False);
	
	If Not RequiresThePathToTheProgram() Then
		RunCallback(CompletionProcessing, Result);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("CompletionProcessing", CompletionProcessing);
	Context.Insert("ProgramLink", ProgramLink);
	VerifiedPathsToProgramModules = VerifiedPathsToProgramModules();
	
	DescriptionOfWay = VerifiedPathsToProgramModules.Get(ProgramLink);
	If DescriptionOfWay <> Undefined Then
		ToObtainThePathToTheProgramCompletion(DescriptionOfWay, Context);
		Return;
	EndIf;
	Context.Insert("VerifiedPathsToProgramModules", VerifiedPathsToProgramModules);
	
	PersonalSettings = DigitalSignatureClient.PersonalSettings();
	ApplicationPath = PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications.Get(
		ProgramLink);
	
	If ValueIsFilled(ApplicationPath) Then
		Context.Insert("Result", Result);
		Result.ApplicationPath = ApplicationPath;
		CheckThePathToTheProgram(New CallbackDescription(
			"GetTheProgramPathAfterCheckingThePath", ThisObject, Context), ApplicationPath);
	Else
		GetTheDefaultProgramPath(New CallbackDescription(
			"ToObtainThePathToTheProgramCompletion", ThisObject, Context), ProgramLink);
	EndIf;
	
EndProcedure

// Continues the GetApplicationPath procedure.
Procedure GetTheProgramPathAfterCheckingThePath(Exists, Context) Export
	
	Context.Result.Exists = Exists;
	ToObtainThePathToTheProgramCompletion(Context.Result, Context);
	
EndProcedure

// Continues the GetApplicationPath procedure.
Procedure ToObtainThePathToTheProgramCompletion(DescriptionOfWay, Context) Export
	
	If Context.Property("VerifiedPathsToProgramModules") Then
		Context.VerifiedPathsToProgramModules.Insert(Context.ProgramLink, DescriptionOfWay);
	EndIf;
	
	Result = New Structure("ApplicationPath, Exists",
		DescriptionOfWay.ApplicationPath, DescriptionOfWay.Exists <> False);
	
	RunCallback(Context.CompletionProcessing, Result);
	
EndProcedure

Function VerifiedPathsToProgramModules()
	
	CommonSettings = DigitalSignatureClient.CommonSettings();
	
	ParameterName = "StandardSubsystems.DigitalSignature.DescriptionOfPathsToProgramModules";
	DescriptionOfPathsToProgramModules = ApplicationParameters.Get(ParameterName);
	
	If DescriptionOfPathsToProgramModules = Undefined
	 Or DescriptionOfPathsToProgramModules.SettingsVersion <> CommonSettings.SettingsVersion Then
		
		DescriptionOfPathsToProgramModules = New Structure("ThePathToTheProgramModules, SettingsVersion",
			New Map, CommonSettings.SettingsVersion);
		
		ApplicationParameters.Insert(ParameterName, DescriptionOfPathsToProgramModules);
	EndIf;
	
	Return DescriptionOfPathsToProgramModules.ThePathToTheProgramModules;
	
EndFunction

Async Procedure CheckThePathToTheProgram(CompletionProcessing, ApplicationPath)
	
	Context = New Structure;
	Context.Insert("CompletionProcessing", CompletionProcessing);
	Context.Insert("ApplicationPath", ApplicationPath);
	
	Notification = New CallbackDescription(
		"CheckThePathToTheProgramAfterAttach1CEnterpriseExtension", ThisObject, Context);
	
	IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(Notification);
	If IsInstallingAddIns Then
		Return;
	EndIf;
	
	FileSystemClient.Attach1CEnterpriseExtension(Notification);
	
EndProcedure

// Continue the CheckApplicationPath procedure.
Procedure CheckThePathToTheProgramAfterAttach1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		RunCallback(Context.CompletionProcessing, Undefined);
		Return;
	EndIf;
	
	Context.Insert("ThePathToTheModules", StrSplit(Context.ApplicationPath, ":", False));
	Context.Insert("IndexOf", -1);
	
	CheckThePathToTheProgramCycleStart(Context);
	
EndProcedure

// Continue the CheckApplicationPath procedure.
//
// Parameters:
//  Context - Structure
//
Procedure CheckThePathToTheProgramCycleStart(Context)
	
	If Context.ThePathToTheModules.Count() <= Context.IndexOf + 1 Then
		// After loop.
		RunCallback(Context.CompletionProcessing, False);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	
	File = New File;
	File.BeginInitialization(New CallbackDescription(
		"CheckThePathToTheProgramLoopAfterInitializingTheFile", ThisObject, Context),
		Context.ThePathToTheModules[Context.IndexOf]);
	
EndProcedure

// Continue the CheckApplicationPath procedure.
Procedure CheckThePathToTheProgramLoopAfterInitializingTheFile(File, Context) Export
	
	File.BeginCheckingExistence(New CallbackDescription(
		"CheckThePathToTheProgramLoopAfterCheckingTheExistenceOfTheFile", ThisObject, Context));
	
EndProcedure

// Continue the CheckApplicationPath procedure.
Procedure CheckThePathToTheProgramLoopAfterCheckingTheExistenceOfTheFile(Exists, Context) Export
	
	If Exists Then
		RunCallback(Context.CompletionProcessing, True);
		Return;
	EndIf;
	
	CheckThePathToTheProgramCycleStart(Context);
	
EndProcedure

Procedure GetTheDefaultProgramPath(CompletionProcessing, ProgramLink) Export
	
	Result = New Structure("ApplicationPath, Exists", "", False);
	
	If Not RequiresThePathToTheProgram() Then
		RunCallback(CompletionProcessing, Result);
		Return;
	EndIf;
	
	CommonSettings = DigitalSignatureClient.CommonSettings();
	If TypeOf(ProgramLink) = Type("String") Then
		TheProgramID = ProgramLink;
	Else
		ApplicationDetails = CommonSettings.DescriptionsOfTheProgramsOnTheLink.Get(ProgramLink); // See DigitalSignatureInternalCached.ApplicationDetails
		If ApplicationDetails = Undefined Then
			RunCallback(CompletionProcessing, Result);
			Return;
		EndIf;
		TheProgramID = ApplicationDetails.Id;
	EndIf;
	
	ThePathWasFound = False;
	For Each ThePathToTheProgramModules In CommonSettings.SupplyThePathToTheProgramModules Do
		If StrStartsWith(TheProgramID, ThePathToTheProgramModules.Key) Then
			ThePathWasFound = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ThePathWasFound Then
		RunCallback(CompletionProcessing, Result);
		Return;
	EndIf;
	
	PathsToProgramModules = ThePathToTheProgramModules.Value.Get(
		CommonClientServer.NameOfThePlatformType());
	
	If PathsToProgramModules = Undefined Then
		RunCallback(CompletionProcessing, Result);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("CompletionProcessing", CompletionProcessing);
	Context.Insert("PathsToProgramModules", PathsToProgramModules);
	Context.Insert("IndexOf", -1);
	
	ToObtainThePathToTheProgramDefaultCycleStart(Context);
	
EndProcedure

// Continues the GetApplicationPath procedure.
Procedure ToObtainThePathToTheProgramDefaultCycleStart(Context)
	
	If Context.PathsToProgramModules.Count() <= Context.IndexOf + 1 Then
		// After loop.
		ToObtainThePathToTheProgramDefaultCycleCompletion(Context, False);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	
	CheckThePathToTheProgram(New CallbackDescription(
		"GetTheDefaultProgramPathLoopAfterCheckingThePath", ThisObject, Context),
		Context.PathsToProgramModules.Get(Context.IndexOf))
	
EndProcedure

// Continues the GetApplicationPath procedure.
Procedure GetTheDefaultProgramPathLoopAfterCheckingThePath(Exists, Context) Export
	
	If Exists <> False Then
		ToObtainThePathToTheProgramDefaultCycleCompletion(Context, Exists);
		Return;
	EndIf;
	
	ToObtainThePathToTheProgramDefaultCycleStart(Context);
	
EndProcedure

// Continues the GetApplicationPath procedure.
Procedure ToObtainThePathToTheProgramDefaultCycleCompletion(Context, Exists)
	
	CurrentPath = Context.PathsToProgramModules.Get(
		?(Exists <> True, 0, Context.IndexOf));
	
	Result = New Structure("ApplicationPath, Exists", CurrentPath, Exists);
	
	RunCallback(Context.CompletionProcessing, Result);
	
EndProcedure

// Continue the FindValidPersonalCertificates procedure.
Procedure FindValidPersonalCertificates(Notification, Filter = Undefined) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CallbackOnCompletion", Notification);
	
	If Filter = Undefined Then
		Filter = New Structure;
	EndIf;
	
	If Not Filter.Property("CheckExpirationDate") Then
		Filter.Insert("CheckExpirationDate", True);
	EndIf;
	
	If Not Filter.Property("CertificatesWithFilledProgramOnly") Then
		Filter.Insert("CertificatesWithFilledProgramOnly", True);
	EndIf;
	
	If Not Filter.Property("IncludeCertificatesWithBlankUser") Then
		Filter.Insert("IncludeCertificatesWithBlankUser", True);
	EndIf;
	
	If Not Filter.Property("Organization") Then
		Filter.Insert("Organization", Undefined);
	EndIf;

	NotificationParameters.Insert("Filter",                 Filter);
	
	Notification = New CallbackDescription("FindValidPersonalCertificatesAfterGetSignaturesAtClient", ThisObject, NotificationParameters);
	GetCertificatesPropertiesAtClient(Notification, Not Filter.CheckExpirationDate, True);
	
EndProcedure

// Continue the FindValidPersonalCertificates procedure.
Procedure FindValidPersonalCertificatesAfterGetSignaturesAtClient(Result, AdditionalParameters) Export

	PersonalCertificates = DigitalSignatureInternalServerCall.PersonalCertificates(Result.CertificatesPropertiesAtClient, AdditionalParameters.Filter);
	RunCallback(AdditionalParameters.CallbackOnCompletion, PersonalCertificates);
	
EndProcedure

// Continues the CheckCryptographyAppsInstallation procedure.
Procedure CheckCryptographyAppsInstallation(Form, CheckParameters = Undefined, CallbackOnCompletion = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Form", Form);
	Context.Insert("IsReCheck", False);
	Context.Insert("ShouldPromptToInstallApp", Undefined);
	Context.Insert("AppsToCheck", Undefined);
	Context.Insert("ExtendedDescription", False);
	Context.Insert("Notification", CallbackOnCompletion);
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("SetComponent", True);
	ReceivingParameters.Insert("ShouldInstallExtension", True);
	ReceivingParameters.Insert("CheckAtServer1",      Undefined);
	
	If TypeOf(CheckParameters) = Type("Structure") Then
		FillPropertyValues(Context, CheckParameters);
		FillPropertyValues(ReceivingParameters, CheckParameters);
	EndIf;
	
	If Context.ShouldPromptToInstallApp = Undefined Then
		Context.ShouldPromptToInstallApp = Context.AppsToCheck = True
			And Not DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
			And Not DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
			And Not UseCloudSignatureService()
			And Not UseDigitalSignatureSaaS();
	EndIf;
	
	Context.Insert("SignAlgorithms", New Array);
	Context.Insert("DataType", Undefined);
		
	If Context.AppsToCheck <> Undefined Then
		If Context.AppsToCheck = True Then
			Context.AppsToCheck = Undefined;
			Context.SignAlgorithms = DigitalSignatureInternalClientServer.AppsRelevantAlgorithms();
			Context.DataType = "Certificate";
		ElsIf TypeOf(Context.AppsToCheck) = Type("BinaryData")
			Or TypeOf(Context.AppsToCheck) = Type("String") Then
			BinaryData = DigitalSignatureInternalClientServer.BinaryDataFromTheData(
				Context.AppsToCheck, "DigitalSignatureInternalClient.CheckCryptographyAppsInstallation");
			Context.AppsToCheck = Undefined;
			Context.DataType = DigitalSignatureInternalClientServer.DefineDataType(BinaryData);
			If Context.DataType = "Certificate" Then
				SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(BinaryData);
			ElsIf Context.DataType = "Signature" Then
				SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(BinaryData);
			Else
				Raise NStr("vi = 'Dữ liệu để tìm kiếm ứng dụng mã hóa không phải là chứng thư hoặc chữ ký.';
							|ru = 'Данные для поиска приложения криптографии не являются сертификатом или подписью.';
							|en = 'The data to search for a cryptography app is not a certificate or a signature.'; fa = 'The data to search for a cryptography app is not a certificate or a signature.';
							|it = 'Данные для поиска приложения криптографии не являются сертификатом или подписью.';
							|pl = 'The data to search for a cryptography app is not a certificate or a signature.';
							|tr = 'Kriptografi uygulaması arama verisi bir sertifika veya imza değildir.'");
			EndIf;
			Context.SignAlgorithms.Add(SignAlgorithm);
		EndIf;
	EndIf;
	
	GetInstalledCryptoProviders(
		New CallbackDescription("CheckCryptographyAppsInstallationAfterInstalledObtained", ThisObject, Context),
		ReceivingParameters);

EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledPrograms(Notification, ApplicationsDetails, CheckAtServer1) Export
	
	Programs = DigitalSignatureInternalServerCall.FindInstalledPrograms(
		ApplicationsDetails, CheckAtServer1);
	
	Context = InstalledApplicationsSearchContext();
	Context.IndexOf = -1;
	Context.Programs = Programs;
	Context.CallbackOnCompletion = Notification;
	
	Notification = New CallbackDescription("FindInstalledApplicationsAfterAttachExtension", ThisObject, Context);
	DigitalSignatureClient.InstallExtension(True, Notification);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledApplicationsAfterAttachExtension(Attached, Context) Export
	
	FindInstalledApplicationsLoopStart(Context);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledApplicationsLoopStart(Context)
	
	If Context.Programs.Count() <= Context.IndexOf + 1 Then
		FindInstalledProgramsAfterTheLoop(Context);
		Return;
	EndIf;
	Context = Context; // See InstalledApplicationsSearchContext
	Context.IndexOf = Context.IndexOf + 1;
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.Application = Context.Programs.Get(Context.IndexOf);
	CreationParameters.ShowError = Undefined;
	
	Notification = New CallbackDescription("FindInstalledApplicationsLoopFollowUp", ThisObject, Context);
	CreateCryptoManager(Notification, "", CreationParameters);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledApplicationsLoopFollowUp(Result, Context) Export
	
	Context = Context; // See InstalledApplicationsSearchContext
	ApplicationDetails = Context.Programs.Get(Context.IndexOf);
	
	If TypeOf(Result) = Type("CryptoManager") Then
		ApplicationDetails.CheckResultAtClient = "";
		ApplicationDetails.Use = True;
	Else
		ApplicationDetails.CheckResultAtClient =
			DigitalSignatureInternalClientServer.TextOfTheProgramSearchError(
				NStr("vi = 'Chưa cài đặt trên máy tính.';
					|ru = 'Не установлено на компьютере.';
					|en = 'It is not installed on the computer.'; fa = 'It is not installed on the computer.';
					|it = 'It is not installed on the computer.';
					|pl = 'It is not installed on the computer.';
					|tr = 'Bilgisayara kurulmadı.'"), Result);
	EndIf;
	
	FindInstalledApplicationsLoopStart(Context);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledProgramsAfterTheLoop(Context)
	
	For Each Application In Context.Programs Do
		Application.Delete("Id");
	EndDo;
	
	RunCallback(Context.CallbackOnCompletion, Context.Programs);
	
EndProcedure

// Opens the certificate data view form.
//
// Parameters:
//  CertificateData - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//                    - CryptoCertificate - an existing certificate.
//                    - BinaryData - certificate binary data.
//                    - String - an address of temporary storage that contains the certificate BinaryData.
//                    - String - a certificate thumbprint to be searched in all storages.
//
//  OpenData     - Boolean - open the certificate data and not the form of catalog item.
//                      If not a reference is passed to the catalog item and the catalog item
//                      could not be found by thumbprint, the certificate data will be opened.
//
Procedure OpenCertificate(CertificateData, OpenData = False) Export
	
	Context = CertificateOpeningContext();
	Context.CertificateData = CertificateData;
	Context.OpenData = OpenData;
	Context.CertificateAddress = Undefined;
	
	If TypeOf(CertificateData) = Type("CryptoCertificate") Then
		CertificateData.BeginUnloading(New CallbackDescription(
			"OpenCertificateAfterCertificateExport", ThisObject, Context));
	Else
		OpenCertificateContinued(Context);
	EndIf;
	
EndProcedure

// The context of the certificate opening.
// 
// Returns:
//  Structure - Context of the certificate opening:
//   * CertificateData - See OpenCertificate.CertificateData
//   * OpenData - See OpenCertificate.OpenData
//   * CertificateAddress - String
//   * Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//   * Thumbprint - String
//   * ErrorAtClient - Structure
//
Function CertificateOpeningContext()
	Context = New Structure;
	Context.Insert("CertificateData");
	Context.Insert("OpenData");
	Context.Insert("CertificateAddress");
	Context.Insert("Ref");
	Context.Insert("Thumbprint");
	Context.Insert("ErrorAtClient", New Structure);
	Return Context;
EndFunction

// Continue the OpenCertificate procedure.
Procedure OpenCertificateAfterCertificateExport(ExportedData, Context) Export
	
	Context.CertificateAddress = PutToTempStorage(ExportedData);
	
	OpenCertificateContinued(Context);
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateContinued(Context)
	
	If Context.CertificateAddress <> Undefined Then
		// The certificate is prepared.
		
	ElsIf TypeOf(Context.CertificateData) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		Ref = Context.CertificateData;
		
	ElsIf TypeOf(Context.CertificateData) = Type("BinaryData") Then
		Context.CertificateAddress = PutToTempStorage(Context.CertificateData);
		
	ElsIf TypeOf(Context.CertificateData) <> Type("String") Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi khi gọi ra thủ tục %1 của mô-đun chung %2:
			           |Sai giá trị tham số %3 ""%4"".';
			           |ru = 'Ошибка при вызове процедуры %1 общего модуля %2:
			           |Некорректное значение параметра %3 ""%4"".';
			           |en = 'Error calling procedure ""%1"" of common module ""%2"". Details:
			           |Parameter ""%3"" has invalid value: %4.'; fa = 'Error calling procedure ""%1"" of common module ""%2"". Details:
			           |Parameter ""%3"" has invalid value: %4.';
			           |it = 'Errore alla chiamata della procedura %1 del modulo comune %2:
			           |Valore invalido del parametro %3 ""%4"".';
			           |pl = 'Błąd podczas wywołania procedury %1 wspólnego modułu %2:
			           |Niepoprawna wartość parametru %3 ""%4"".';
			           |tr = '%2 genel modülde %1 prosedürü çağrısı sırasında hata oluştu:
			           | %3 ""%4"" parametrenin değeri geçersiz.'"),
				"OpenCertificate", "DigitalSignatureClient", "CertificateData", String(Context.CertificateData));
		Raise(MessageText, ErrorCategory.ConfigurationError);
		
	ElsIf IsTempStorageURL(Context.CertificateData) Then
		Context.CertificateAddress = Context.CertificateData;
	Else
		Thumbprint = String(Context.CertificateData); // String
	EndIf;
	
	If Not Context.OpenData Then
		If Ref = Undefined Then
			Ref = DigitalSignatureInternalServerCall.CertificateRef(Thumbprint, Context.CertificateAddress);
		EndIf;
		If ValueIsFilled(Ref) Then
			ShowValue(, Ref);
			Return;
		EndIf;
	EndIf;
	
	Context.Ref = Ref;
	Context.Thumbprint = Thumbprint;
	
	If Context.CertificateAddress = Undefined
	   And Ref = Undefined Then
		
		GetCertificateByThumbprint(New CallbackDescription(
			"OpenCertificateAfterCertificateSearch", ThisObject, Context), Thumbprint, False, Undefined);
	Else
		OpenCertificateCompletion(Context);
	EndIf;
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoCertificate") Then
		Result.BeginUnloading(New CallbackDescription(
			"OpenCertificateAfterExportFoundCertificate", ThisObject, Context));
	Else
		Context.ErrorAtClient = Result;
		OpenCertificateCompletion(Context);
	EndIf;
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateAfterExportFoundCertificate(ExportedData, Context) Export
	
	Context.CertificateAddress = PutToTempStorage(ExportedData);
	
	OpenCertificateCompletion(Context);
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateCompletion(Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref");
	FormParameters.Insert("CertificateAddress");
	FormParameters.Insert("Thumbprint");
	FormParameters.Insert("ErrorAtClient");
	
	FillPropertyValues(FormParameters, Context);
	
	OpenCertificateForm(FormParameters);
	
EndProcedure

// Saves the certificate to a file.
// 
// Parameters:
//   Notification - CallbackDescription - called after saving.
//              - Undefined - follow up is not required.
//
//   Certificate - CryptoCertificate - a certificate.
//              - BinaryData - certificate binary data.
//              - String - an address of a temporary storage that contains certificate binary data.
//
Async Procedure SaveCertificate(Notification, Certificate, FileNameWithoutExtension = "", RepeatedCall = False) Export
	
	If Not RepeatedCall Then
		RetryCallParameters = New Structure("Notification, Certificate, FileNameWithoutExtension",
			Notification, Certificate, FileNameWithoutExtension);
		NotificationWhenDigitalSignatureAddInsMissing = New CallbackDescription(
			"ReSaveCertificateAfterAddInsInstalled", ThisObject, RetryCallParameters);
		IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(
			NotificationWhenDigitalSignatureAddInsMissing);
		If IsInstallingAddIns Then
			Return;
		EndIf;
	EndIf;
	
	Context =  CertificateSaveContext();
	Context.Notification =            Notification;
	Context.Certificate =            Certificate;
	Context.FileNameWithoutExtension = FileNameWithoutExtension;
	Context.CertificateAddress =      Undefined;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Certificate.BeginUnloading(New CallbackDescription(
			"SaveCertificateAfterCertificateExport", ThisObject, Context));
	Else
		SaveCertificateContinued(Context);
	EndIf;
	
EndProcedure

// Follow-up call to "SaveCertificate" after the add-ins have been installed.
Procedure ReSaveCertificateAfterAddInsInstalled(Result, RetryCallParameters) Export
	
	If Result = True Then
		SaveCertificate(RetryCallParameters.Notification, RetryCallParameters.Certificate,
			RetryCallParameters.FileNameWithoutExtension , True)
	EndIf;
	
EndProcedure

// Returns:
//   Structure:
//   * CertificateAddress - String
//   * FileNameWithoutExtension - String
//   * Certificate - See SaveCertificate.Certificate
//   * Notification - See SaveCertificate.Notification
//
Function CertificateSaveContext()
	Context =  New Structure;
	Context.Insert("Notification");
	Context.Insert("Certificate");
	Context.Insert("FileNameWithoutExtension");
	Context.Insert("CertificateAddress");
	
	Return Context;
EndFunction

// Continue the SaveCertificate procedure.
Procedure SaveCertificateAfterCertificateExport(ExportedData, Context) Export
	
	Context.CertificateAddress = PutToTempStorage(ExportedData, New UUID);
	Context.Insert("DeleteCertificateFromTempStorage", True);
	SaveCertificateContinued(Context);
	
EndProcedure

// Continue the SaveCertificate procedure.
Procedure SaveCertificateContinued(Context)
	
	If Context.CertificateAddress <> Undefined Then
		// The certificate is prepared.
		
	ElsIf TypeOf(Context.Certificate) = Type("BinaryData") Then
		Context.CertificateAddress = PutToTempStorage(Context.Certificate, New UUID);
		Context.Insert("DeleteCertificateFromTempStorage", True);
	ElsIf TypeOf(Context.Certificate) = Type("String")
		And IsTempStorageURL(Context.Certificate) Then
		
		Context.CertificateAddress = Context.Certificate;
	Else
		If Context.Notification <> Undefined Then
			RunCallback(Context.Notification, False);
		EndIf;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Context.FileNameWithoutExtension) Then
		Context.FileNameWithoutExtension = DigitalSignatureInternalServerCall.SubjectPresentation(Context.CertificateAddress);
	EndIf;
	
	FileName = DigitalSignatureInternalClientServer.PrepareStringForFileName(
		Context.FileNameWithoutExtension) + ".cer";
	
	Notification = New CallbackDescription("SaveCertificatesAfterFilesReceipt", ThisObject, Context);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp để lưu chứng thư';
										|ru = 'Выберите файл для сохранения сертификата';
										|en = 'Select a file to save the certificate to'; fa = 'Select a file to save the certificate to';
										|it = 'Selezionare file per il salvataggio del certificato';
										|pl = 'Wybierz plik, aby zapisać certyfikat';
										|tr = 'Sertifikayı kaydetmek için dosya seçin'");
	SavingParameters.Dialog.Filter    = NStr("vi = 'Tệp chứng thư (*.cer)|*.cer';
											|ru = 'Файлы сертификатов (*.cer)|*.cer';
											|en = 'Certificate files (*.cer)|*.cer'; fa = 'Certificate files (*.cer)|*.cer';
											|it = 'Файлы сертификатов (*.cer)|*.cer';
											|pl = 'Certificate files (*.cer)|*.cer';
											|tr = 'Sertifika dosyaları (*.cer)|*.cer'")+ "|"
		+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																		|ru = 'Все файлы (%1)|%1';
																		|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																		|it = 'Все файлы (%1)|%1';
																		|pl = 'All files (%1)|%1';
																		|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	FileSystemClient.SaveFile(Notification, Context.CertificateAddress, FileName, SavingParameters);
	
EndProcedure

// Continue the SaveCertificate procedure.
// 
// Parameters:
//   ObtainedFiles - Array of TransferredFileDescription
//   Context - Structure
//
Procedure SaveCertificatesAfterFilesReceipt(ObtainedFiles, Context) Export
	
	If ObtainedFiles = Undefined
	 Or ObtainedFiles.Count() = 0 Then
		
		HasObtainedFiles = False;
	Else
		HasObtainedFiles = True;
		ShowUserNotification(NStr("vi = 'Đã lưu chứng thư trong tệp:';
									|ru = 'Сертификат сохранен в файл:';
									|en = 'Certificate is saved to file:'; fa = 'Certificate is saved to file:';
									|it = 'Certificato salvato nel file:';
									|pl = 'Certyfikat zapisany w pliku:';
									|tr = 'Sertifika şu dosyaya kaydedildi:'"),,
			ObtainedFiles[0].Name);
	EndIf;
	
	If Context.Property("DeleteCertificateFromTempStorage") Then
		DeleteFromTempStorage(Context.CertificateAddress);
	EndIf;
	
	If Context.Notification <> Undefined Then
		RunCallback(Context.Notification, HasObtainedFiles);
	EndIf;
	
EndProcedure

// Saves a signature to the computer.
Async Procedure SaveSignature(SignatureAddress, SignatureFileName = "", RepeatedCall = False) Export
	
	If Not RepeatedCall Then
		RetryCallParameters = New Structure("SignatureAddress, SignatureFileName", SignatureAddress, SignatureFileName);
		NotificationWhenDigitalSignatureAddInsMissing = New CallbackDescription(
			"ReSaveSignatureAfterAddInsInstalled", ThisObject, RetryCallParameters);
		IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(
			NotificationWhenDigitalSignatureAddInsMissing);
		If IsInstallingAddIns Then
			Return;
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("SaveSignatureAfterFileReceipt", ThisObject, Undefined);
	Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tệp chữ ký điện tử (*.%1)|*.%1';
			|ru = 'Файлы электронных подписей (*.%1)|*.%1';
			|en = 'Digital signature files (*.%1)|*.%1'; fa = 'Digital signature files (*.%1)|*.%1';
			|it = 'Файлы электронных подписей (*.%1)|*.%1';
			|pl = 'Digital signature files (*.%1)|*.%1';
			|tr = 'Elektronik imza dosyaları (*.%1)|*.%1'"),
		DigitalSignatureClient.PersonalSettings().SignatureFilesExtension);
	Filter = Filter + "|" + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																							|ru = 'Все файлы (%1)|%1';
																							|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																							|it = 'Все файлы (%1)|%1';
																							|pl = 'All files (%1)|%1';
																							|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Filter = Filter;
	SavingParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp để lưu chữ ký';
										|ru = 'Выберите файл для сохранения подписи';
										|en = 'Select a file to save the signature to'; fa = 'Select a file to save the signature to';
										|it = 'Selezionare file per il salvataggio della firma';
										|pl = 'Wybierz plik, aby zapisać podpis';
										|tr = 'İmzayı kaydetmek için dosya seçin'");
	
	FileSystemClient.SaveFile(Notification, SignatureAddress, SignatureFileName, SavingParameters);
	
EndProcedure

// Follow-up call to "SaveSignature" after the add-ins have been installed.
Procedure ReSaveSignatureAfterAddInsInstalled(Result, RetryCallParameters) Export
	
	If Result = True Then
		SaveSignature(RetryCallParameters.SignatureAddress, RetryCallParameters.SignatureFileName, True);
	EndIf;
	
EndProcedure

// Continue the SaveSignature procedure.
// 
// Parameters:
//   ObtainedFiles - Array of TransferredFileDescription
//   Context - Structure
//
Procedure SaveSignatureAfterFileReceipt(ObtainedFiles, Context) Export
	
	If ObtainedFiles = Undefined
	 Or ObtainedFiles.Count() = 0 Then
		
		Return;
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Chữ ký điện tử đã lưu trong tệp:';
								|ru = 'Электронная подпись сохранена в файл:';
								|en = 'Digital signature is saved to file:'; fa = 'Digital signature is saved to file:';
								|it = 'Firma elettronica salvata nel file:';
								|pl = 'Podpis elektroniczny zapisany do pliku:';
								|tr = 'Dijital imza şu dosyaya kaydedildi:'"),,
		ObtainedFiles[0].Name);
	
EndProcedure

// Certificate write parameters.
// 
// Returns:
//  Structure - Notification parameters for writing the certificate and changing the request status:
//   * IsNew - Boolean - Add certificate to the catalog.
//   * Is_Specified - Boolean - Certificate is installed to the Personal store.
//   * Revoked - Boolean - Revocation flag.
//
Function ParametersNotificationWhenWritingCertificate() Export
	
	ParametersNotificationWhenWritingCertificate = New Structure;
	ParametersNotificationWhenWritingCertificate.Insert("IsNew", False);
	ParametersNotificationWhenWritingCertificate.Insert("Is_Specified", False);
	ParametersNotificationWhenWritingCertificate.Insert("Revoked", False);
	Return ParametersNotificationWhenWritingCertificate;
	
EndFunction

// Finds a certificate on the computer by a thumbprint string.
//
// Parameters:
//   Notification - CallbackDescription - a notification about the execution result of the following types:
//     = CryptoCertificate - a found certificate.
//     = Undefined           - the certificate does not exist in the storage.
//     = String                 - a text of the crypto manager creation error (or other error).
//     = Structure              - an error details as a structure.
//
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - If "True", search only in the personal store. Otherwise, search everywhere.
//                          - CryptoCertificateStoreType - the specified storage type.
//
//   ShowError - Boolean - show the crypto manager creation error.
//                  - Undefined - do not show the error and return the error structure,
//                    including the addition of the CertificateNotFound property.
//
//   Application  - Undefined - search using any application.
//              - CatalogRef.DigitalSignatureAndEncryptionApplications - search
//                   using the specified application.
//              - CryptoManager - an initialized crypto manager
//                   to use for search.
//
Procedure GetCertificateByThumbprint(Notification, Thumbprint, InPersonalStorageOnly,
			ShowError = True, Application = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Notification",             Notification);
	Context.Insert("Thumbprint",              Thumbprint);
	Context.Insert("InPersonalStorageOnly", InPersonalStorageOnly);
	Context.Insert("ShowError",         ShowError);
	Context.Insert("Errors", New Array);
	Context.Insert("Application", Application);
	
	If TypeOf(Application) = Type("CryptoManager") Then
		GetCertificateByThumbprintAfterCreateCryptoManager(Application, Context);
	Else
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = ShowError;
		CreationParameters.Application = Application;
		
		CreateCryptoManager(New CallbackDescription(
			"GetCertificateByThumbprintAfterCreateCryptoManager", ThisObject, Context),
			"GetCertificates", CreationParameters);
		
	EndIf;
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		Context.Errors.Add(?(TypeOf(Result) = Type("String"), Result, Result.ErrorDescription));
			
		StandardProcessing = True;
		DigitalSignatureClientLocalization.OnGettingCertificateByThumbprintOnToken(
			New CallbackDescription("AfterGettingCertificateByThumbprintOnToken", ThisObject, Context),
			Context.Thumbprint, StandardProcessing, True, True);

		If Not StandardProcessing Then
			Return;
		EndIf;
	
		GetCertificateByThumbprintCompletion(Undefined, StrConcat(Context.Errors, Chars.LF), Context);
		Return;
	EndIf;
	Context.Insert("CryptoManager", Result);
	
	StoreType = DigitalSignatureInternalClientServer.StorageTypeToSearchCertificate(
		Context.InPersonalStorageOnly);
	
	Try
		Context.Insert("ThumbprintBinaryData", Base64Value(Context.Thumbprint));
	Except
		If Context.ShowError = True Then
			Raise;
		EndIf;
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		GetCertificateByThumbprintAfterSearchByCryptoManager(Undefined, ErrorPresentation, Context);
		Return;
	EndTry;
	
	Context.CryptoManager.BeginGettingCertificateStore(
		New CallbackDescription(
			"GetCertificateByThumbprintAfterGetStorage", ThisObject, Context,
			"GetCertificateByThumbprintAfterGetStorageError", ThisObject),
		StoreType);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterGetStorageError(ErrorInfo, StandardProcessing, Context) Export
	
	If Context.ShowError = True Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	GetCertificateByThumbprintAfterSearchByCryptoManager(Undefined, ErrorPresentation, Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterGetStorage(CryptoCertificateStore, Context) Export
	
	CryptoCertificateStore.BeginFindingByThumbprint(New CallbackDescription(
			"GetCertificateByThumbprintAfterSearch", ThisObject, Context,
			"GetCertificateByThumbprintAfterSearchError", ThisObject),
		Context.ThumbprintBinaryData);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterSearchError(ErrorInfo, StandardProcessing, Context) Export
	
	If Context.ShowError = True Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	
	GetCertificateByThumbprintAfterSearchByCryptoManager(Undefined, ErrorPresentation, Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterSearch(Certificate, Context) Export
	
	GetCertificateByThumbprintAfterSearchByCryptoManager(Certificate, "", Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterSearchByCryptoManager(Certificate, ErrorPresentation, Context)
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		RunCallback(Context.Notification, Certificate);
		Return;
	EndIf;
	
	If ValueIsFilled(ErrorPresentation) Then
		Context.Errors.Add(ErrorPresentation);
	EndIf;
	
	If Context.Property("Application") And Context.Application <> Undefined Then
		GetCertificateByThumbprintCompletion(Undefined, StrConcat(Context.Errors, Chars.LF), Context);
		Return;
	EndIf;
	
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnGettingCertificateByThumbprintOnToken(
		New CallbackDescription("AfterGettingCertificateByThumbprintOnToken", ThisObject, Context),
		Context.Thumbprint, StandardProcessing, True, True);
		
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	GetCertificateByThumbprintCompletion(Undefined, StrConcat(Context.Errors, Chars.LF), Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure AfterGettingCertificateByThumbprintOnToken(Certificate, Context) Export

	If Certificate <> Undefined Then
		GetCertificateByThumbprintCompletion(Certificate, StrConcat(Context.Errors, Chars.LF), Context);
	Else
		GetCertificateByThumbprintCompletion(Undefined, StrConcat(Context.Errors, Chars.LF), Context);
	EndIf;
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintCompletion(Certificate, ErrorPresentation, Context)
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		RunCallback(Context.Notification, Certificate);
		Return;
	EndIf;
	
	If ValueIsFilled(ErrorPresentation) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chứng chỉ không được cài đặt trên máy tính do nguyên nhân:
			           |%1';
			           |ru = 'Сертификат не установлен на компьютере по причине:
			           |%1';
			           |en = 'The certificate is not installed on the computer due to:
			           |%1'; fa = 'The certificate is not installed on the computer due to:
			           |%1';
			           |it = 'Certificato non installato sul computer a causa di: 
			           |%1';
			           |pl = 'Nie znaleziono certyfikatu na komputerze z powodu:
			           |%1';
			           |tr = 'Sertifika şu sebeple bilgisayara ayarlanmadı:
			           |%1'"),
			ErrorPresentation);
	Else
		ErrorText = NStr("vi = 'Chưa cài đặt chứng chỉ trên máy tính.';
						|ru = 'Сертификат не установлен на компьютере.';
						|en = 'The certificate is not installed on the computer.'; fa = 'The certificate is not installed on the computer.';
						|it = 'Certificato non installato sul computer.';
						|pl = 'Nie zainstalowano certyfikatu na komputerze.';
						|tr = 'Bilgisayarda sertifika ayarlanmadı.'");
	EndIf;
	
	If Context.ShowError = Undefined Then
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorText);
		If Not ValueIsFilled(ErrorPresentation) Then
			Result.Insert("CertificateNotFound");
		EndIf;
	ElsIf Not ValueIsFilled(ErrorPresentation) Then
		Result = Undefined;
	Else
		Result = ErrorPresentation;
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Gets certificate thumbprints of the OS user on the computer.
//
// Parameters:
//  Notification     - CallbackDescription - it is called to pass the return value of one of the types:
//                     = Map - Key - a thumbprint in the Base64 string format, and Value is True,
//                     = String - a text of the crypto manager creation error (or other error).
//
//  OnlyPersonal   - Boolean - if False, recipient certificates are added to the personal certificates.
//
//  ReceivingParameters - See DigitalSignatureClient.CertificateThumbprintsReceiptParameters
//
Procedure GetCertificatesThumbprints(Notification, OnlyPersonal, ReceivingParameters = True) Export
	
	If TypeOf(ReceivingParameters) = Type("Boolean") Then
		ReceivingParameters = DigitalSignatureClient.CertificateThumbprintsReceiptParameters(ReceivingParameters, Undefined, Undefined);
		ReceivingParameters.ShouldReturnSource = False;
	ElsIf ReceivingParameters = Undefined Then
		ReceivingParameters = DigitalSignatureClient.CertificateThumbprintsReceiptParameters();
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("OnlyPersonal",       OnlyPersonal);
	Context.Insert("ReceivingParameters", ReceivingParameters);
	
	GetCertificatesPropertiesAtClient(New CallbackDescription(
			"GetCertificatesThumbprintsAfterExecute", ThisObject, Context),
		OnlyPersonal, False, True, ReceivingParameters.ClientSide = True);
	
EndProcedure

// Continues the GetCertificatesThumbprints procedure.
Procedure GetCertificatesThumbprintsAfterExecute(Result, Context) Export

	Thumbprints = New Map;
	
	ResultOfObtainingPrints = New Structure;
	ResultOfObtainingPrints.Insert("ErrorOnGetCertificatesAtClient");
	ResultOfObtainingPrints.Insert("ErrorGettingCertificatesAtServer");
	
	If Result <> Undefined Then
		If ValueIsFilled(Result.ErrorOnGetCertificatesAtClient) Then
			ResultOfObtainingPrints.ErrorOnGetCertificatesAtClient = Result.ErrorOnGetCertificatesAtClient;
		Else
			For Each KeyAndValue In Result.CertificatesPropertiesAtClient Do
				Thumbprints.Insert(KeyAndValue.Key, ?(Context.ReceivingParameters.ShouldReturnSource = True, "Client", KeyAndValue.Value))
			EndDo;
		EndIf;
	EndIf;
	
	If Context.ReceivingParameters.ServerSide <> Undefined Then
		
		If Context.ReceivingParameters.ServerSide = True Then
			ErrorDescription = Null
		Else
			ErrorDescription = "";
		EndIf;
		
		ThumbprintsOnServer = DigitalSignatureInternalServerCall.CertificateThumbprints(Context.OnlyPersonal, ErrorDescription, Context.ReceivingParameters.Service <> Undefined);
		If ValueIsFilled(ErrorDescription) Then
			ResultOfObtainingPrints.ErrorGettingCertificatesAtServer = ErrorDescription;
		EndIf;
		
		For Each Item In ThumbprintsOnServer Do
			If Thumbprints[Item] <> Undefined Then
				Continue;
			EndIf;
			Thumbprints.Insert(Item.Key, Item.Value);
		EndDo;
		
	ElsIf Context.ReceivingParameters.Service <> Undefined Then
		
		ThumbprintsInService = DigitalSignatureInternalServerCall.ServiceCertificateThumbprints();
		For Each Item In ThumbprintsInService Do
			If Thumbprints[Item] <> Undefined Then
				Continue;
			EndIf;
			Thumbprints.Insert(Item, "Service")
		EndDo;
		
	EndIf;
		
	If ValueIsFilled(Result.ErrorOnGetCertificatesAtClient) And Not Context.ReceivingParameters.ShouldReturnSource Then
		RunCallback(Context.Notification, Result.ErrorOnGetCertificatesAtClient);
		Return;
	EndIf;
	
	If Context.ReceivingParameters.ShouldReturnSource Then
		ResultOfObtainingPrints.Insert("Thumbprints", Thumbprints);
		RunCallback(Context.Notification, ResultOfObtainingPrints);
	Else
		RunCallback(Context.Notification, Thumbprints);
	EndIf;

EndProcedure

// For internal use only.
Function UTCOffset() Export
	
	Return CommonClient.SessionDate() - CommonClient.UniversalDate();
	
EndFunction

// Continues the DigitalSignatureClient.VerifySignature procedure.
//
// Parameters:
//   Notification           - See DigitalSignatureClient.VerifySignature.Notification
//   RawData       - See DigitalSignatureClient.VerifySignature.RawData
//   Signature              - See DigitalSignatureClient.VerifySignature.Signature
//   CryptoManager - See DigitalSignatureClient.VerifySignature.CryptoManager
//   OnDate               - See DigitalSignatureClient.VerifySignature.OnDate
//   CheckParameters    - See DigitalSignatureClient.VerifySignature.CheckParameters
//
Procedure VerifySignature(Notification, RawData, Signature, CryptoManager = Undefined, OnDate = Undefined, CheckParameters = Undefined) Export
	
	ParametersForCheck = DigitalSignatureClient.SignatureVerificationParameters();
	
	If CheckParameters = Undefined Then
		ParametersForCheck.ShowCryptoManagerCreationError = True;
	ElsIf TypeOf(CheckParameters) = Type("Boolean") Then
		ParametersForCheck.ShowCryptoManagerCreationError = CheckParameters;
	ElsIf TypeOf(CheckParameters) = Type("Structure") Then
		FillPropertyValues(ParametersForCheck, CheckParameters);
		ExpectedValues = New Array;
		ExpectedValues.Add(DigitalSignatureInternalClientServer.VerifyQualified());
		If ParametersForCheck.ResultAsStructure Then
			ExpectedValues.Add(DigitalSignatureInternalClientServer.QualifiedOnly());
			ExpectedValues.Add(DigitalSignatureInternalClientServer.NotVerifyCertificate());
		EndIf;
		CommonClientServer.CheckParameter("DigitalSignatureInternalClient.VerifySignature",
			"CheckParameters.VerifyCertificate", ParametersForCheck.VerifyCertificate, Type("String"),, ExpectedValues);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",     Notification);
	Context.Insert("RawData", RawData);
	Context.Insert("Signature",        Signature);
	Context.Insert("SignatureAddress",   "");
	Context.Insert("OnDate",         OnDate);
	Context.Insert("CheckAtServer1",
		DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer());
	
	If ParametersForCheck.ResultAsStructure Then
		Context.Insert("CheckResult", DigitalSignatureClientServer.SignatureVerificationResult());
		Context.CheckResult.CertificateVerificationParameters = ParametersForCheck.VerifyCertificate;
		Context.Insert("VerifyCertificate", ParametersForCheck.VerifyCertificate);
	Else
		Context.Insert("CheckResult", Undefined);
		Context.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.VerifyQualified());
	EndIf;
	
	If TypeOf(Context.Signature) = Type("String")
	   And IsTempStorageURL(Context.Signature) Then
		
		Context.SignatureAddress = Context.Signature;
		Context.Signature = GetFromTempStorage(Signature);
	EndIf;
	
	If Not DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
	   And TypeOf(Context.RawData) = Type("String")
	   And IsTempStorageURL(Context.RawData) Then
		
		Context.RawData = GetFromTempStorage(Context.RawData);
	EndIf;
	
	If TypeOf(Context.RawData) = Type("Structure")
	   And Context.RawData.Property("XMLDSigParameters") Then // IsXMLDSig.
		
		If Not Context.RawData.Property("XMLEnvelope") Then
			Context.RawData = New Structure(New FixedStructure(Context.RawData));
			Context.RawData.Insert("XMLEnvelope", Context.RawData.SOAPEnvelope);
		EndIf;
		XMLEnvelopeProperties = DigitalSignatureInternalServerCall.XMLEnvelopeProperties(
			Context.RawData.XMLEnvelope, Context.RawData.XMLDSigParameters, True);
		Context.Insert("XMLEnvelopeProperties", XMLEnvelopeProperties);
		If XMLEnvelopeProperties = Undefined Then
			CertificateData = DigitalSignatureInternalClientServer.CertificateFromSOAPEnvelope(
				Context.RawData.XMLEnvelope, False);
		ElsIf ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
			RunCallback(Context.Notification,
				SignatureVerificationResult(XMLEnvelopeProperties.ErrorText, Context.CheckResult));
			Return;
		Else
			CertificateData = Base64Value(XMLEnvelopeProperties.Certificate.CertificateValue);
		EndIf;
		
		Context.Insert("SignAlgorithm",
			DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData));
		
	ElsIf TypeOf(Context.Signature) = Type("BinaryData") Then
		Context.Insert("SignAlgorithm",
			DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Context.Signature));
	Else
		Context.Insert("SignAlgorithm", "");
	EndIf;
	
	If CryptoManager = Undefined Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = ParametersForCheck.ShowCryptoManagerCreationError
			And Not Context.CheckAtServer1
			And Not UseDigitalSignatureSaaS()
			And Not VerifyCertificatesWithACloudSignature();
		CreationParameters.SignAlgorithm = Context.SignAlgorithm;
		
		CreateCryptoManager(New CallbackDescription(
			"CheckSignatureAfterCreateCryptoManager", ThisObject, Context),
			"CheckSignature", CreationParameters);
	Else
		CheckSignatureAfterCreateCryptoManager(CryptoManager, Context);
	EndIf;
	
EndProcedure

// Continues the VerifySignature procedure.
Procedure CheckSignatureAfterCreateCryptoManager(Result, Context) Export
	
	If Result = "CryptographyService" Then
		CheckSignatureSaaS(Context);
		Return;
	ElsIf Result = "CloudSignature" Then
		VerifySignatureCloudSignature(Context);
		Return;
	ElsIf TypeOf(Result) = Type("CryptoManager") Then
		CryptoManager = Result;
	Else
		CryptoManager = Undefined;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	
	If Not DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		// Checking the signature and certificate on the client side.
		If CryptoManager = Undefined Then
			
			If UseDigitalSignatureSaaS() Then
				CheckSignatureSaaS(Context);
			ElsIf VerifyCertificatesWithACloudSignature() Then
				VerifySignatureCloudSignature(Context);
			Else
				VerifySignatureUsingToken(Context);
			EndIf;
			
			Return;
			
		EndIf;
		
		Context.Insert("CheckCertificateAtClient");
		CheckSignatureAtClient(Context);
		Return;
	EndIf;
	
	If CryptoManager <> Undefined
	   And Not (  TypeOf(Context.RawData) = Type("String")
	         And IsTempStorageURL(Context.RawData)) Then
		// Mathematical signature verification on the client side. Intended to improve performance and security
		// in cases where "RawData" is the result of the secret file decryption.
		
		// The certificate is checked both on the client and on the server.
		CheckSignatureAtClient(Context);
		Return;
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		// Checking certificate signature in SaaS.
		CheckSignatureSaaS(Context);
	Else
		// Checking the signature and certificate on the server.
		If TypeOf(Context.RawData) = Type("String")
		   And IsTempStorageURL(Context.RawData) Then
			
			SourceDataAddress = Context.RawData;
		Else
			If TypeOf(Context.RawData) = Type("Structure")
			   And Context.RawData.Property("CMSParameters") Then
				
				Context.RawData.CMSParameters.IncludeCertificatesInSignature =
					IncludingCertificatesInSignatureAsString(
						Context.RawData.CMSParameters.IncludeCertificatesInSignature);
			EndIf;
			SourceDataAddress = PutToTempStorage(Context.RawData);
		EndIf;
		
		If Not ValueIsFilled(Context.SignatureAddress) Then
			Context.SignatureAddress = PutToTempStorage(Context.Signature);
		EndIf;
		
		ErrorDescription = "";
		Result = DigitalSignatureInternalServerCall.VerifySignature(
			SourceDataAddress, Context.SignatureAddress, ErrorDescription, Context.OnDate, Context.CheckResult);
		
		If Result <> True Then
			Result = ErrorDescription;
		EndIf;

		RunCallback(Context.Notification,
			SignatureVerificationResult(Result, Context.CheckResult));
		
	EndIf;
	
EndProcedure

Async Procedure VerifySignatureUsingToken(Context) Export
	
	CheckParameters = SignatureOnTokenCheckParameters(Context.SignAlgorithm);
	
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnCheckSignatureOnToken(
		New CallbackDescription("AfterSignatureInTokenChecked", ThisObject, Context),
		Context.RawData, Context.Signature, CheckParameters, StandardProcessing);
		
	If StandardProcessing Then
		AfterSignatureInTokenChecked(Undefined, Context);
	EndIf;
	
EndProcedure

Async Procedure AfterSignatureInTokenChecked(MathValidationResult, Context) Export
	
	If MathValidationResult = Undefined Then
		VerifySignatureAddSignaturePropertiesToResult(Context.Signature, Undefined, Context);
	Else
		
		If MathValidationResult = False Then
			InvalidHash = True;
			IsVerificationRequired = False;
			Result = NStr("vi = 'Sai hash.';
							|ru = 'Неверный хеш.';
							|en = 'Invalid hash sum.'; fa = 'Invalid hash sum.';
							|it = 'Invalid hash sum.';
							|pl = 'Invalid hash sum.';
							|tr = 'Önbellek yanlış.'");
		ElsIf MathValidationResult = True Then
			If Context.VerifyCertificate = DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
				IsVerificationRequired = False;
				Result = True;
			Else
				IsVerificationRequired = True;
				InvalidHash = False;
				Result = NStr("vi = 'Việc kiểm tra chứng thư bằng các công cụ của token sẽ có trong các phiên bản sau của ứng dụng.';
								|ru = 'Проверка сертификата средствами токена будет доступна в следующих версиях приложения.';
								|en = 'Certificate validation using the token''s built-in mechanisms will be released later.'; fa = 'Certificate validation using the token''s built-in mechanisms will be released later.';
								|it = 'Certificate validation using the token''s built-in mechanisms will be released later.';
								|pl = 'Certificate validation using the token''s built-in mechanisms will be released later.';
								|tr = 'Token aracılığıyla sertifika doğrulama, uygulamanın sonraki sürümlerinde mevcut olacaktır.'");
			EndIf;
		Else
			IsVerificationRequired = True;
			Result = MathValidationResult;
		EndIf;
		
		If TypeOf(Context.CheckResult) = Type("Structure") Then
			SignatureProperties = Await SignaturePropertiesFromBinaryData(Context.Signature, True);
			FillPropertyValues(Context.CheckResult, SignatureProperties);
		EndIf;
			
		RunCallback(Context.Notification,
			SignatureVerificationResult(Result, Context.CheckResult, IsVerificationRequired, InvalidHash));
		
	EndIf;
	
EndProcedure

Async Procedure VerifySignatureAddSignaturePropertiesToResult(Signature, Result, Context, MathValidationError = Undefined)
	
	IsVerificationRequired = Undefined;
	InvalidHash = Undefined;
	
	If TypeOf(Context.CheckResult) = Type("Structure") Then
		
		If Result = Undefined Then
			Context.CheckResult.IsVerificationRequired = True;
		ElsIf TypeOf(Result) =  Type("String") Then
			ClassifierError = DigitalSignatureInternalClientCached.ClassifierError(Result);
			If ClassifierError <> Undefined Then
				IsVerificationRequired = ClassifierError.IsCheckRequired;
				InvalidHash = ClassifierError.InvalidSignatureHash;
			EndIf;
		EndIf;
		
		If TypeOf(Context.CryptoManager) = Type("CryptoManager") Then
			SignatureProperties = Await SignaturePropertiesReadByCryptoManager(Signature, Context.CryptoManager, True);
		Else
			SignatureProperties = Await SignaturePropertiesFromBinaryData(Signature, True);
		EndIf;
			
		FillPropertyValues(Context.CheckResult, SignatureProperties);
	EndIf;
	
	If InvalidHash = Undefined Then
		InvalidHash = MathValidationError = True;
	EndIf;
	
	RunCallback(Context.Notification,
		SignatureVerificationResult(Result, Context.CheckResult, IsVerificationRequired, InvalidHash));
			
EndProcedure

// Continues the VerifySignature procedure.
Procedure CheckSignatureAtClient(Context)
	
	Context.Insert("SignatureData", Context.Signature);
	
	IsXMLDSig = (TypeOf(Context) = Type("Structure")
	            And TypeOf(Context.RawData) = Type("Structure")
	            And Context.RawData.Property("XMLDSigParameters"));
	
	IsCMS = (TypeOf(Context) = Type("Structure")
	            And TypeOf(Context.RawData) = Type("Structure")
	            And Context.RawData.Property("CMSParameters"));
	
	If IsXMLDSig Then
		
		NotificationSuccess = New CallbackDescription(
			"CheckSignatureAtClientAfterXMLDSigCheckSignature", ThisObject, Context);
		
		NotificationError = New CallbackDescription(
			"CheckSignatureAtClientAfterXMLDSigCheckSignatureError", ThisObject, Context);
		
		Notifications = New Structure;
		Notifications.Insert("Success", NotificationSuccess);
		Notifications.Insert("Error", NotificationError);
		
		StartCryptoCertificateInitializationToCheckSignatureXMLDSig(Notifications,
			Context.RawData.XMLEnvelope,
			Context.RawData.XMLDSigParameters,
			Context.XMLEnvelopeProperties,
			Context.CryptoManager);
		
	ElsIf IsCMS Then
		
		NotificationSuccess = New CallbackDescription(
			"CheckSignatureAtClientAfterXMLDSigCheckSignature", ThisObject, Context);
		
		NotificationError = New CallbackDescription(
			"CheckSignatureAtClientAfterXMLDSigCheckSignatureError", ThisObject, Context);
		
		Notifications = New Structure;
		Notifications.Insert("Success", NotificationSuccess);
		Notifications.Insert("Error", NotificationError);
		
		StartCryptoCertificateInitializationToCheckSignatureCMS(
			Notifications,
			Context.SignatureData,
			Context.RawData.Data,
			Context.RawData.CMSParameters,
			Context.CryptoManager);
		
	Else
		CryptoManager = Context.CryptoManager; // CryptoManager
		CryptoManager.BeginVerifyingSignature(New CallbackDescription(
			"CheckSignatureAtClientAfterCheckSignature", ThisObject, Context,
			"CheckSignatureAtClientAfterCheckSignatureError", ThisObject),
			Context.RawData, Context.SignatureData, False);
	EndIf;
	
EndProcedure

// Continues the VerifySignature procedure.
Procedure CheckSignatureAtClientAfterXMLDSigCheckSignatureError(ErrorText, Context) Export
	
	RunCallback(Context.Notification, ErrorText);
	
EndProcedure

// Continues the VerifySignature procedure.
Procedure CheckSignatureAtClientAfterXMLDSigCheckSignature(Data, Context) Export
	
	If Context.VerifyCertificate = DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		VerifySignatureAfterSignatureCertificateVerified(True, Context);
	Else

		If Context.Property("CheckCertificateAtClient") Then
			CryptoManager = Context.CryptoManager;
		Else
		// Checking the certificate both on the server and on the client.
			CryptoManager = Undefined;
		EndIf;

		AdditionalParameters = AdditionalCertificateVerificationParameters();
		AdditionalParameters.ToVerifySignature = True;
		AdditionalParameters.PerformCAVerification = Context.VerifyCertificate;

		Notification = New CallbackDescription("VerifySignatureAfterSignatureCertificateVerified", ThisObject, Context);

		CheckCertificate(Notification, Data.Certificate, CryptoManager, Data.SigningDate,
			AdditionalParameters);
	EndIf;
	
EndProcedure

// Continues the VerifySignature procedure.
Procedure CheckSignatureAtClientAfterCheckSignatureError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		MathValidationError = True;
	Else
		ErrorText = String(ErrorInfo);
		MathValidationError = Undefined;
	EndIf;
	
	If Context.Property("SignatureData") Then
		Signature = Context.SignatureData;
	Else
		Signature = Context.Signature;
	EndIf;
	
	VerifySignatureAddSignaturePropertiesToResult(Signature, ErrorText, Context, MathValidationError);
	
EndProcedure

// Continues the VerifySignature procedure.
Async Procedure CheckSignatureAtClientAfterCheckSignature(Certificate, Context) Export
	
	SignatureVerificationError = "";
	If TypeOf(Context.CryptoManager) = Type("CryptoManager") Then
		
		CertificateProperties = Undefined;
		
		SignatureProperties = Await SignaturePropertiesReadByCryptoManager(Context.SignatureData, Context.CryptoManager, False);
		
		If SignatureProperties.SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
			And SignatureProperties.SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES") Then
			// Verify the additional attributes.
			Try
				Await Context.CryptoManager.VerifySignatureAsync(
					Context.RawData, Context.SignatureData, True);
			Except
				SignatureVerificationError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;
		EndIf;
		
		If TypeOf(Context.CheckResult) = Type("Structure") Then
			FillPropertyValues(Context.CheckResult, SignatureProperties);
			Context.CheckResult.Certificate = Await Certificate.UnloadAsync();
		EndIf;
		
		If Not IsBlankString(SignatureVerificationError) Then
			RunCallback(Context.Notification, SignatureVerificationResult(
					SignatureVerificationError, Context.CheckResult,, False));
			Return;
		EndIf;
		
	Else // After a check in cloud services.
		
		SignatureProperties = Await SignaturePropertiesFromBinaryData(Context.SignatureData, True);
		
		If SignatureProperties.Certificate = Undefined Then
			RunCallback(Context.Notification, SignatureVerificationResult(
				NStr("vi = 'Chứng chỉ không tồn tại trong dữ liệu chữ ký.';
					|ru = 'Сертификат не существует в данных подписи.';
					|en = 'The certificate does not exist in signature data.'; fa = 'The certificate does not exist in signature data.';
					|it = 'Il certificato non esiste nei dati di firma.';
					|pl = 'Certyfikat nie istnieje w danych podpisu.';
					|tr = 'Sertifika imza verilerde mevcut değil.'"), Context.CheckResult,, False));
			Return;
		EndIf;
		
		Certificate = SignatureProperties.Certificate;
		
		If TypeOf(Context.CheckResult) = Type("Structure") Then
			FillPropertyValues(Context.CheckResult, SignatureProperties);
			Context.CheckResult.Certificate = Certificate;
		EndIf;
		
	EndIf;
	
	If Not Context.Property("CheckCertificateAtClient") Then
		// Checking the certificate both on the server and on the client.
		Context.Insert("CryptoManager", Undefined);
	EndIf;
		
	Context.Insert("Certificate", Certificate);
	
	If Context.VerifyCertificate = DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		VerifySignatureAfterSignatureCertificateVerified(True, Context);
	Else
		SigningDate = DigitalSignatureInternalClientServer.DateToVerifySignatureCertificate(SignatureProperties);
		If Not ValueIsFilled(SigningDate) Then
			SigningDate = Context.OnDate;
		EndIf;

		AdditionalParameters = AdditionalCertificateVerificationParameters();
		AdditionalParameters.ToVerifySignature = True;
		AdditionalParameters.PerformCAVerification = Context.VerifyCertificate;
		If SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3") Then
			AdditionalParameters.IgnoreCertificateRevocationStatus = True;
		EndIf;
		If ValueIsFilled(SignatureProperties.DateSignedFromLabels) Then 
			AdditionalParameters.IsTimestampDateSpecified = True;
		EndIf;
		
		Notification = New CallbackDescription("VerifySignatureAfterSignatureCertificateVerified", ThisObject, Context);
		CheckCertificate(Notification, Context.Certificate, Context.CryptoManager, SigningDate,
			AdditionalParameters);
	EndIf;
		
EndProcedure

Procedure VerifySignatureAfterSignatureCertificateVerified(CheckResult, Context) Export
	
	If TypeOf(CheckResult) = Type("Structure") Then

		Result = CheckResult.GeneralDescriptionOfTheError;
		If Context.CheckResult <> Undefined Then
			If CheckResult.CertificateRevoked Then
				Result = DigitalSignatureInternalClientServer.ErrorTextForRevokedSignatureCertificate(
					Context.CheckResult);
			EndIf;
			Context.CheckResult.CertificateRevoked = CheckResult.CertificateRevoked;
			Context.CheckResult.IsVerificationRequired = CheckResult.IsVerificationRequired;
		EndIf;

	ElsIf CheckResult = Undefined Then
		
		Result = CheckResult;
		If Context.CheckResult <> Undefined Then
			Context.CheckResult.IsVerificationRequired = True;
		EndIf;
		
	Else
		
		Result = CheckResult;
		
	EndIf;
	
	RunCallback(Context.Notification,
		SignatureVerificationResult(Result, Context.CheckResult,,False));
	
EndProcedure

// Checks the crypto certificate validity.
//
// Parameters:
//   Notification           - CallbackDescription - Runtime result notification of one of the following types:
//             = Boolean - True if the check is passed.
//             = String - Error details (if the check is failed).
//             = Undefined - Crypto manager is not received (because it is not specified).
//             = Structure - If an error occurred (AdditionalParameters.ToVerifySignature AND AdditionalParameters.ShouldConsolidateCertificateErrors) 
//                # GeneralErrorDescription - String
//                # CertificateRevoked - Boolean - Error because the certificate is revoked.
//                # CheckRequired - Boolean - Recheck required after additional actions taken.
//                    For example, after a root certificate was installed.
//             = Structure - If an error occurred (AdditionalParameters.ToVerifySignature AND Not AdditionalParameters.ShouldConsolidateCertificateErrors) 
//                # ErrorDetailsAtClient - String
//                # ErrorDescriptionAtServer - String
//                # AdditionalDataChecksAtServer - See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
//                # AdditionalDataChecksAtClient - See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
//                # CertificateRevoked - Boolean - See above.
//                # CheckRequired - Boolean - See above.
//
//   Certificate           - CryptoCertificate - a certificate.
//                        - BinaryData - certificate binary data.
//                        - String - an address of a temporary storage that contains certificate binary data.
//
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - use the specified crypto manager
//                          (a check on the server will not be executed).
//
//   OnDate               - Date - Check the certificate validity on the specified date.
//                          If the parameter is not specified or an empty value is passed, check on the session date.
//
//   AdditionalParameters - See AdditionalCertificateVerificationParameters.
//
Procedure CheckCertificate(Notification, Certificate, CryptoManager = Undefined, OnDate = Undefined,
	AdditionalParameters = Undefined) Export

	Context = CertificateCheckContext();
	Context.Notification =                        Notification;
	Context.Certificate =                        Certificate;
	Context.CryptoManager =              CryptoManager;
	Context.OnDate =                            OnDate;
	
	AdditionalCertificateVerificationParameters = AdditionalCertificateVerificationParameters();
	If AdditionalParameters <> Undefined Then
		FillPropertyValues(AdditionalCertificateVerificationParameters, AdditionalParameters);
		
		If TypeOf(AdditionalCertificateVerificationParameters.PerformCAVerification) = Type("Boolean") Then // Intended for compatibility purposes.
			AdditionalCertificateVerificationParameters.PerformCAVerification = ?(
				AdditionalCertificateVerificationParameters.PerformCAVerification,
				DigitalSignatureInternalClientServer.VerifyQualified(), 
				DigitalSignatureInternalClientServer.NotVerifyCertificate());
		EndIf;
		
		ExpectedValues = New Array;
		ExpectedValues.Add(DigitalSignatureInternalClientServer.VerifyQualified());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.QualifiedOnly());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.NotVerifyCertificate());
		CommonClientServer.CheckParameter("DigitalSignatureInternalClient.CheckCertificate",
			"AdditionalParameters.PerformCAVerification", AdditionalCertificateVerificationParameters.PerformCAVerification,
			Type("String"),, ExpectedValues);
			
		Context.ShowError                    = AdditionalCertificateVerificationParameters.ShowError;
		Context.MergeCertificateDataErrors = AdditionalCertificateVerificationParameters.MergeCertificateDataErrors;
		Context.CheckInServiceAfterError      = AdditionalCertificateVerificationParameters.CheckInServiceAfterError;
		Context.PerformCAVerification = AdditionalCertificateVerificationParameters.PerformCAVerification;
		Context.ToVerifySignature                = AdditionalCertificateVerificationParameters.ToVerifySignature;
		Context.IgnoreCertificateRevocationStatus = AdditionalCertificateVerificationParameters.IgnoreCertificateRevocationStatus;
		Context.IsTimestampDateSpecified = AdditionalCertificateVerificationParameters.IsTimestampDateSpecified;
		
	EndIf;
	
	Context.ErrorDetailsAtClient = Undefined;
	Context.ErrorDescriptionAtServer = Undefined;
	
	If Context.CryptoManager = Undefined And DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		
		Context.IsCheckRequiredAtServer = False;
		
		// Check on the server before checking on the client.
		If TypeOf(Certificate) = Type("CryptoCertificate") Then

			Certificate.BeginUnloading(New CallbackDescription("CheckCertificateAfterExportCertificate",
				ThisObject, Context));
		Else
			CheckCertificateAfterExportCertificate(Certificate, Context);
		EndIf;
	Else
		// When the crypto manager is specified, the check is executed only on the client.
		CheckCertificateAtClient(Context);
	EndIf;

EndProcedure

// Returns:
//   Structure:
//   * ErrorDescriptionAtServer - String
//   * ErrorDetailsAtClient - String
//   * IsCheckRequiredAtClient - Undefined, Boolean
//   * IsCheckRequiredAtServer - Undefined, Boolean
//   * CertificateRevoked - Boolean
//   * ShowError  - See CheckCertificate.
//   * OnDate - See CheckCertificate.OnDate
//   * IsTimestampDateSpecified - Boolean 
//   * CryptoManager - See CheckCertificate.CryptoManager
//   * Certificate - See CheckCertificate.Certificate
//   * Notification - See CheckCertificate.Notification
//   * MergeCertificateDataErrors - Boolean
//   * CheckInServiceAfterError - Boolean
//   * PerformCAVerification - String
//   * IgnoreCertificateRevocationStatus - Boolean
//
Function CertificateCheckContext()
	
	Context = New Structure;
	Context.Insert("Notification");
	Context.Insert("Certificate");
	Context.Insert("CertificateRevoked", False);
	Context.Insert("CryptoManager");
	Context.Insert("OnDate");
	Context.Insert("IsTimestampDateSpecified", False);
	Context.Insert("ErrorDetailsAtClient");
	Context.Insert("IsCheckRequiredAtClient");
	Context.Insert("AdditionalDataChecksAtClient");
	Context.Insert("ErrorDescriptionAtServer");
	Context.Insert("IsCheckRequiredAtServer");
	Context.Insert("AdditionalDataChecksAtServer");
	Context.Insert("ShowError", True);
	Context.Insert("MergeCertificateDataErrors", True);
	Context.Insert("CheckInServiceAfterError", True);
	Context.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.VerifyQualified());
	Context.Insert("ToVerifySignature", False);
	Context.Insert("ActionsToFixErrors", New Map);
	Context.Insert("CertificateProperties");
	Context.Insert("IgnoreCertificateRevocationStatus", False);
	
	Return Context;
	
EndFunction

// Additional parameters for the certificate check.
// 
// Returns:
//  Structure - - Additional parameters for the certificate check.:
//   * ShowError - Boolean  - show the crypto manager creation error (when it is not specified).
//   * MergeCertificateDataErrors - Boolean - Merge certificate data errors on the server and on the client in a string.
//                                                  
//   * CheckInServiceAfterError - Boolean - In case a data certificate check error, perform the check on the service.
//   * PerformCAVerification - See DigitalSignatureClient.CertificateVerificationParameters.
//                                             
//   * ToVerifySignature - Boolean - Flag indicating whether to hide notifications for certificates,
//                                               and return the result as specified in the signature check calling procedure.
//   * IsTimestampDateSpecified - See DigitalSignatureClient.CertificateVerificationParameters.
//
Function AdditionalCertificateVerificationParameters() Export
	
	Structure = New Structure;
	Structure.Insert("ShowError", True);
	Structure.Insert("MergeCertificateDataErrors", True);
	Structure.Insert("CheckInServiceAfterError", True);
	Structure.Insert("ToVerifySignature", False);
	Structure.Insert("IsTimestampDateSpecified", False);
	Structure.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.VerifyQualified());
	Structure.Insert("IgnoreCertificateRevocationStatus", False);
	
	Return Structure;
	
EndFunction

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterExportCertificate(Certificate, Context) Export
	
	// Checking the certificate on the server.
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateAddress = PutToTempStorage(Certificate);
	Else
		CertificateAddress = Certificate;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("IgnoreCertificateRevocationStatus", Context.IgnoreCertificateRevocationStatus);
	AdditionalParameters.Insert("PerformCAVerification", Context.PerformCAVerification);
	AdditionalParameters.Insert("ToVerifySignature", Context.ToVerifySignature);
	AdditionalParameters.Insert("IsTimestampDateSpecified", Context.IsTimestampDateSpecified);
	AdditionalParameters.Insert("Warning");
	AdditionalParameters.Insert("Certificate", CertificateAddress);
	
	If DigitalSignatureInternalServerCall.CheckCertificate(CertificateAddress,
		Context.ErrorDescriptionAtServer, Context.OnDate, AdditionalParameters) Then

		If ValueIsFilled(AdditionalParameters.Warning) And Not Context.ToVerifySignature
			And AdditionalParameters.Certificate <> Undefined Then

			FormOpenParameters = New Structure("Certificate, AdditionalDataChecks", AdditionalParameters.Certificate,
				AdditionalParameters.Warning);
			ActionOnClick = New CallbackDescription("OpenNotificationFormNeedReplaceCertificate",
				DigitalSignatureInternalClient, FormOpenParameters);

			ShowUserNotification(
					NStr("vi = 'Cần thay đổi chứng chỉ';
						|ru = 'Необходима замена сертификата';
						|en = 'You need to reissue the certificate'; fa = 'You need to reissue the certificate';
						|it = 'È necessario sostituire il certificato';
						|pl = 'Jest konieczna wymiana certyfikatu';
						|tr = 'Sertifika değiştirilmelidir'"), ActionOnClick, AdditionalParameters.Certificate,
				PictureLib.DialogExclamation, UserNotificationStatus.Important, AdditionalParameters.Certificate);

		EndIf;

		RunCallback(Context.Notification, True);
	Else
		CheckCertificateAtClient(Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAtClient(Context)
	
	Context.IsCheckRequiredAtClient = False;
	
	CertificateToCheck = Context.Certificate;
	
	If TypeOf(CertificateToCheck) = Type("String") Then
		CertificateToCheck = GetFromTempStorage(CertificateToCheck);
	EndIf;
	Context.Insert("CertificateToCheck", CertificateToCheck);
	
	If TypeOf(CertificateToCheck) = Type("BinaryData") Then
		
		DigitalSignatureClient.InstallExtension(False, New CallbackDescription(
			"VerifyCertificateOnClientAfterEnablingCryptographyExtension", ThisObject, Context),
			NStr("vi = 'Để tiếp tục, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
				|ru = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
				|en = 'To continue, install 1C:Enterprise Extension.'; fa = 'To continue, install 1C:Enterprise Extension.';
				|it = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
				|pl = 'W celu kontynuowania zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
				|tr = 'Devam etmek için 1C:Enterprise ile çalışma uzantısını yükleyin.'"));
	
	Else
		CheckCertificateAfterInitializeCertificate(CertificateToCheck, Context)
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure VerifyCertificateOnClientAfterEnablingCryptographyExtension(Attached, Context) Export
	
	If Attached = True Then
		CryptoCertificate = New CryptoCertificate;
		CryptoCertificate.BeginInitialization(New CallbackDescription(
				"CheckCertificateAfterInitializeCertificate", ThisObject, Context),
			Context.CertificateToCheck);
	Else
		CheckCertificateAtClientAfterCheckError(ErrorTextExtensionNotInstalled(), False, Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.Insert("CryptoCertificate", CryptoCertificate);
	Context.Insert("CertificateCheckModes",
		DigitalSignatureInternalClientServer.CertificateCheckModes(
			ValueIsFilled(Context.OnDate), Context.IgnoreCertificateRevocationStatus));
	
	If TypeOf(Context.CertificateToCheck) = Type("CryptoCertificate") Then
		Context.CertificateToCheck.BeginUnloading(New CallbackDescription(
			"CheckCertificateAfterDefineSignAlgorithm", ThisObject, Context));
	Else
		CheckCertificateAfterDefineSignAlgorithm(Context.CertificateToCheck, Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterDefineSignAlgorithm(CertificateData, Context) Export
	
	Context.Insert("CertificateData", CertificateData);
	Context.Insert("SignAlgorithm",
		DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData));
		
	ContinueCheckingCertificateAtClient(Context);
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure ContinueCheckingCertificateAtClient(Context)
	
	If Context.CryptoManager = Undefined Then
		
		CreationParameters = CryptoManagerCreationParameters();
		If Context.ShowError = True
		   And Context.ErrorDescriptionAtServer = Undefined
		   And Not UseDigitalSignatureSaaS() Then
			
			CreationParameters.ShowError = True;
		Else
			CreationParameters.ShowError = Undefined;
		EndIf;
		CreationParameters.SignAlgorithm = Context.SignAlgorithm;
		
		CreateCryptoManager(New CallbackDescription(
				"CheckCertificateAfterCreateCryptoManager", ThisObject, Context),
			"CertificateCheck", CreationParameters);
		
	Else
		
		If Context.CryptoManager = "CryptographyService" Then
			CheckCertificateSaaS(Context);
		ElsIf Context.CryptoManager = "CloudSignature" Then
			VerifyTheCloudSignatureCertificate(Context);
		Else
			CheckCertificateAfterCreateCryptoManager(Context.CryptoManager, Context);
		EndIf;
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		If UseDigitalSignatureSaaS() Then
			CheckCertificateSaaS(Context);
		ElsIf VerifyCertificatesWithACloudSignature() Then
			VerifyTheCloudSignatureCertificate(Context);
		Else
			If TypeOf(Result) = Type("Structure") Then
				Context.ErrorDetailsAtClient = Result.ErrorDescription;
			Else
				Context.ErrorDetailsAtClient = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось получить менеджер криптографии для алгоритма %1: %2.';
						|vi = 'Cannot get the cryptography manager for the algorithm %1: %2.';
						|en = 'Cannot get the cryptography manager for the algorithm %1: %2.'; fa = 'Cannot get the cryptography manager for the algorithm %1: %2.';
						|it = 'Cannot get the cryptography manager for the algorithm %1: %2.';
						|pl = 'Cannot get the cryptography manager for the algorithm %1: %2.';
						|tr = '%1 algoritması için kriptografi yöneticisi alınamadı: %2.'"),
					Context.SignAlgorithm, Result);
			EndIf;
			CheckCertificateAfterFailedCheck(Context);
		EndIf;
		Return;
	EndIf;
	
	Context.CryptoManager = Result;
	
	CallbackDescription = New CallbackDescription("CheckCertificateAtClientAfterCheck", ThisObject, Context,
		"CheckCertificateAtClientAfterCheckError", ThisObject);

	If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable()
		And Context.IsTimestampDateSpecified Then
		//@skip-check bsl-legacy-check-dynamic-feature-access
		Context.CryptoManager.BeginCheckingCertificate(CallbackDescription, Context.CryptoCertificate,
			Context.CertificateCheckModes, Context.OnDate - UTCOffset());
	Else
		Context.CryptoManager.BeginCheckingCertificate(CallbackDescription, Context.CryptoCertificate,
			Context.CertificateCheckModes);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAtClientAfterCheckError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		ClassifierError = DigitalSignatureInternalClientCached.ClassifierError(ErrorDescription);
	
		If ClassifierError <> Undefined And ValueIsFilled(ClassifierError.RemedyActions) Then
			
			Action = Undefined;
			
			For Each CurrentAction1 In ClassifierError.RemedyActions Do
				If Context.ActionsToFixErrors.Get(CurrentAction1) = Undefined Then
					Action = CurrentAction1;
					Break;
				EndIf;
			EndDo;
			 
			If Action <> Undefined Then
				Context.ActionsToFixErrors.Insert(Action, ErrorDescription);
				Context.ActionsToFixErrors.Insert("ActionOnRecheck", Action);
				
				If Action = "SetListOfCertificateRevocation"
					And DigitalSignatureClient.CommonSettings().AccessToInternetServicesAllowed Then
					
					CertificateAuthorityName = Lower(DigitalSignatureClient.CertificateIssuerProperties(Context.CryptoCertificate).CommonName);
					If ValueIsFilled(CertificateAuthorityName) Then
						
						CertificateAuthorityName = StringFunctionsClient.LatinString(CertificateAuthorityName);
						
						If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
							CertificateProperties = DigitalSignatureClient.CertificateProperties(Context.CryptoCertificate);
							RevocationListInternalAddress = DigitalSignatureInternalClientServer.RevocationListInternalAddress(
								CertificateAuthorityName, CertificateProperties,
								DigitalSignatureInternalClientCached.CARevocationListDirectories());
						Else
							RevocationListInternalAddress = DigitalSignatureInternalClientServer.RevocationListInternalAddress(
								CertificateAuthorityName, Context.CertificateData,
								DigitalSignatureInternalClientCached.CARevocationListDirectories());
						EndIf;
						
						RevocationListInstallationParameters = RevocationListInstallationParameters(
								Context.CryptoCertificate);
						RevocationListInstallationParameters.CallbackOnCompletion = New CallbackDescription("RecheckCertificate",
							ThisObject, Context);
						RevocationListInstallationParameters.ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Để kiểm tra chứng thư, cần thiết lập danh sách thu hồi thông qua cấu phần ngoài %1.';
								|ru = 'Для проверки сертификата требуется установка списка отзыва с помощью внешней компоненты %1.';
								|en = 'To check the certificate, install a revocation list using the %1 add-in.'; fa = 'To check the certificate, install a revocation list using the %1 add-in.';
								|it = 'Для проверки сертификата требуется установка списка отзыва с помощью внешней компоненты %1.';
								|pl = 'To check the certificate, install a revocation list using the %1 add-in.';
								|tr = 'Sertifika doğrulaması, harici bir bileşen %1kullanılarak geri çekme listesinin yüklenmesini gerektirir.'"),
							"ExtraCryptoAPI");
						If ValueIsFilled(RevocationListInternalAddress.InternalAddress) Then
							RevocationListInstallationParameters.Addresses = RevocationListInternalAddress.ExternalAddress;
							RevocationListInstallationParameters.InternalAddress = RevocationListInternalAddress.InternalAddress;
							SetListOfCertificateRevocation(RevocationListInstallationParameters);
							Return;
						EndIf;
					EndIf;
				EndIf;
				
			EndIf;
		EndIf;
		
	Else
		ErrorDescription = String(ErrorInfo);
		ClassifierError = DigitalSignatureInternalClientCached.ClassifierError(ErrorDescription);
	EndIf;
	
	If ClassifierError <> Undefined Then
		ProcessErrorByClassifier(ErrorDescription, Context.IsCheckRequiredAtClient, Context, ClassifierError);
	EndIf;
	
	Context.ErrorDetailsAtClient = ErrorDescription;
	
	If Context.CheckInServiceAfterError And UseDigitalSignatureSaaS() Then
		CheckCertificateSaaS(Context);
	ElsIf Context.CheckInServiceAfterError And VerifyCertificatesWithACloudSignature() Then
		VerifyTheCloudSignatureCertificate(Context, False);
	Else
		CheckCertificateAfterFailedCheck(Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure RecheckCertificate(Result, Context) Export
	
	If Context.ActionsToFixErrors.Get("ActionOnRecheck") = "SetListOfCertificateRevocation" Then
		
		If Not Result.IsInstalledSuccessfully Then
			
			PreviousErrorText = Context.ActionsToFixErrors.Get("SetListOfCertificateRevocation");
			
			RevocationListInstallationErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thiết lập danh sách thu hồi khi kiểm tra chứng thư: %1
				|%2.';
				|ru = 'Не удалось установить список отзыва при проверке сертификата: %1
				|%2.';
				|en = 'Couldn''t install the revocation list when checking the certificate: %1
				|%2.'; fa = 'Couldn''t install the revocation list when checking the certificate: %1
				|%2.';
				|it = 'Не удалось установить список отзыва при проверке сертификата: %1
				|%2.';
				|pl = 'Couldn''t install the revocation list when checking the certificate: %1
				|%2.';
				|tr = 'Sertifika doğrulaması sırasında geri çekme listesi yapılandırılamadı: %1
				|%2.'"), Result.Message, PropertiesCertificateString(Context.CryptoCertificate));
			EventLogClient.AddMessageForEventLog(
				NStr("vi = 'Chữ ký điện tử. Cập nhật danh sách thu hồi';
					|ru = 'Электронная подпись.Обновление списков отзыва';
					|en = 'Digital signature.Revocation list update'; fa = 'Digital signature.Revocation list update';
					|it = 'Firma elettronica. Aggiornamento degli elenchi di chiamata';
					|pl = 'Podpis elektroniczny.Aktualizacja list odwołania';
					|tr = 'Dijital imza.İptal listesini güncelle'", CommonClient.DefaultLanguageCode()),
				"Error", RevocationListInstallationErrorText,, True);
				
			CheckCertificateAtClientAfterCheckError(PreviousErrorText, False, Context);
			
			Return;
		Else
			
			MessageTextOnInstallRevocationList = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã cài đặt danh sách thu hồi khi kiểm tra chứng thư: %1.';
					|ru = 'Установлен список отзыва при проверке сертификата: %1.';
					|en = 'Certificate revocation list was installed during the certificate validation: %1'; fa = 'Certificate revocation list was installed during the certificate validation: %1';
					|it = 'Установлен список отзыва при проверке сертификата: %1.';
					|pl = 'Certificate revocation list was installed during the certificate validation: %1';
					|tr = 'Sertifika kontrolü esnasında sunucudaki iptal listesi ayarlandı: %1'"), 
				PropertiesCertificateString(Context.CryptoCertificate));
			EventLogClient.AddMessageForEventLog(
				NStr("vi = 'Chữ ký điện tử. Cập nhật danh sách thu hồi';
					|ru = 'Электронная подпись.Обновление списков отзыва';
					|en = 'Digital signature.Revocation list update'; fa = 'Digital signature.Revocation list update';
					|it = 'Firma elettronica. Aggiornamento degli elenchi di chiamata';
					|pl = 'Podpis elektroniczny.Aktualizacja list odwołania';
					|tr = 'Dijital imza.İptal listesini güncelle'", CommonClient.DefaultLanguageCode()),
				"Information", MessageTextOnInstallRevocationList,, True);
				
		EndIf;
		
	EndIf;
	
	CallbackDescription = New CallbackDescription("CheckCertificateAtClientAfterCheck", ThisObject, Context,
		"CheckCertificateAtClientAfterCheckError", ThisObject);
	If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable()
		And Context.IsTimestampDateSpecified Then
		Context.CryptoManager.BeginCheckingCertificate(CallbackDescription, Context.CryptoCertificate,
			Context.CertificateCheckModes, Context.OnDate - UTCOffset());
	Else
		Context.CryptoManager.BeginCheckingCertificate(CallbackDescription, Context.CryptoCertificate,
			Context.CertificateCheckModes);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Async Procedure CheckCertificateAtClientAfterCheck(Context) Export
	
	OverdueError = DigitalSignatureInternalClientServer.CertificateOverdue(
		Context.CryptoCertificate, Context.OnDate, UTCOffset());
	
	If ValueIsFilled(OverdueError) Then
		CheckCertificateAtClientAfterCheckError(OverdueError, False, Context);
	Else
		
		If Context.ToVerifySignature Then
			CertificateProperties = Await CertificateProperties(Context.CryptoCertificate);
			Context.CertificateProperties = CertificateProperties;
			OverdueError = DigitalSignatureInternalClientServer.PrivateKeyExpired(
				CertificateProperties, Context.OnDate);
			If ValueIsFilled(OverdueError) Then
				CheckCertificateAtClientAfterCheckError(OverdueError, False, Context);
				Return;
			EndIf;
		EndIf;
		
		AdditionalVerificationCertificate(Context.CryptoCertificate, False, Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Async Procedure AdditionalVerificationCertificate(CryptoCertificate, CheckAtServer, Context)
	
	If Context.PerformCAVerification <> DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ThisVerificationSignature", Context.ToVerifySignature);
		CheckParameters.Insert("VerifyCertificate", Context.PerformCAVerification);
		
		ResultofCertificateAuthorityVerification = Await ResultofCertificateAuthorityVerification(
			CryptoCertificate, Context.OnDate, CheckParameters, Context.CertificateProperties);
			
		If Not ResultofCertificateAuthorityVerification.Valid Or ValueIsFilled(
			ResultofCertificateAuthorityVerification.Warning.ErrorText)
			And Not Context.ToVerifySignature Then
			
			CertificateCustomSettings = DigitalSignatureInternalServerCall.CertificateCustomSettings(
					CryptoCertificate.Thumbprint);
			
			If Not ResultofCertificateAuthorityVerification.Valid 
				And (Context.PerformCAVerification = DigitalSignatureInternalClientServer.QualifiedOnly()
					Or CertificateCustomSettings.SigningAllowed <> True) Then
			
				If CheckAtServer Then
					Context.ErrorDescriptionAtServer = ResultofCertificateAuthorityVerification.Warning.ErrorText;
					Context.AdditionalDataChecksAtServer = ResultofCertificateAuthorityVerification.Warning;
				Else
					Context.ErrorDetailsAtClient = ResultofCertificateAuthorityVerification.Warning.ErrorText;
					Context.AdditionalDataChecksAtClient = ResultofCertificateAuthorityVerification.Warning;
				EndIf;

				CheckCertificateAfterFailedCheck(Context);
				Return;

			EndIf;

			If ValueIsFilled(ResultofCertificateAuthorityVerification.Warning.ErrorText)
				And Not Context.ToVerifySignature Then
				
				CertificateRef = CertificateCustomSettings.CertificateRef;
				If Not CertificateCustomSettings.IsNotified And CertificateRef <> Undefined Then

					FormOpenParameters = New Structure("Certificate, AdditionalDataChecks",
						CertificateRef, ResultofCertificateAuthorityVerification.Warning);
					ActionOnClick = New CallbackDescription("OpenNotificationFormNeedReplaceCertificate",
						DigitalSignatureInternalClient, FormOpenParameters);

					ShowUserNotification(
					NStr("vi = 'Cần thay đổi chứng chỉ';
						|ru = 'Необходима замена сертификата';
						|en = 'You need to reissue the certificate'; fa = 'You need to reissue the certificate';
						|it = 'È necessario sostituire il certificato';
						|pl = 'Jest konieczna wymiana certyfikatu';
						|tr = 'Sertifika değiştirilmelidir'"), ActionOnClick, CertificateRef,
						PictureLib.DialogExclamation, UserNotificationStatus.Important, CertificateRef);
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
	RunCallback(Context.Notification, True);
	
EndProcedure

Async Function ResultofCertificateAuthorityVerification(CryptoCertificate,  OnDate = Undefined, CheckParameters = Undefined, CertificateProperties = Undefined) Export
	
	Result = DigitalSignatureInternalClientServer.DefaultCAVerificationResult();
	Result = Await DigitalSignatureClientLocalization.OnFillCertificationAuthorityAuditResult(
		Result, CryptoCertificate, OnDate, CheckParameters, CertificateProperties);
	
	Return Result;
		
EndFunction

// Continues the CheckCertificate procedure.
//
// Parameters:
//   Context - Structure:
//     * Certificate - CryptoCertificate
//
Procedure CheckCertificateSaaS(Context)
	
	If TypeOf(Context.Certificate) = Type("CryptoCertificate") Then
		Context.Certificate.BeginUnloading(New CallbackDescription(
			"CheckCertificateSaaSAfterExportCertificate", ThisObject, Context));
	Else
		CheckCertificateSaaSAfterExportCertificate(Context.Certificate, Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateSaaSAfterExportCertificate(Certificate, Context) Export
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateData = Certificate;
	Else
		CertificateData = GetFromTempStorage(Certificate);
	EndIf;
	
	ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
	CheckParameters = DigitalSignatureInternalClientServer.CertificateVerificationParametersInTheService(
		DigitalSignatureClient.CommonSettings(), Context.CertificateCheckModes);
	
	If CheckParameters <> Undefined Then
		// ACC:287-off - No.640. It's acceptable to call a non-existent CTL procedure.
		// It's checked against CTL v.2.0.3, where the procedure exists.
		ModuleCryptographyServiceClient.VerifyCertificateWithParameters(New CallbackDescription(
			"CheckCertificateAfterSaaSCheck", ThisObject, Context), CertificateData, CheckParameters);
		// ACC:287-on
	Else
		ModuleCryptographyServiceClient.CheckCertificate(New CallbackDescription(
			"CheckCertificateAfterSaaSCheck", ThisObject, Context), CertificateData);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterSaaSCheck(Result, Context) Export
	
	If Not Result.Completed2 Then
		Context.ErrorDescriptionAtServer = ErrorProcessing.BriefErrorDescription(Result.ErrorInfo);
		CheckCertificateAfterFailedCheck(Context);
		Return;
	EndIf;
	
	If Not Result.Valid1 Then
		Context.ErrorDescriptionAtServer =
			DigitalSignatureInternalClientServer.ServiceErrorTextCertificateInvalid();
		ProcessErrorByClassifier(Context.ErrorDescriptionAtServer, Context.IsCheckRequiredAtServer, Context);
		CheckCertificateAfterFailedCheck(Context);
		Return;
	EndIf;
	
	OverdueError = DigitalSignatureInternalClientServer.CertificateOverdue(
		Context.CryptoCertificate, Context.OnDate, UTCOffset());
	
	If ValueIsFilled(OverdueError) Then
		Context.ErrorDescriptionAtServer = OverdueError;
		CheckCertificateAfterFailedCheck(Context);
		Return;
	EndIf;
	
	AdditionalVerificationCertificate(Context.CryptoCertificate, True, Context);

EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterFailedCheck(Context)
	
	If Context.MergeCertificateDataErrors Then
		If Context.ErrorDetailsAtClient = Undefined
		   And Context.ErrorDescriptionAtServer = Undefined Then
			
			GeneralDescriptionOfTheError = Undefined;
		Else
			GeneralDescriptionOfTheError = DigitalSignatureInternalClientServer.GeneralDescriptionOfTheError(
				Context.ErrorDetailsAtClient, Context.ErrorDescriptionAtServer, Undefined);
		EndIf;
	
		If Context.ToVerifySignature Then
			
			Structure = New Structure;
			Structure.Insert("GeneralDescriptionOfTheError", GeneralDescriptionOfTheError);
			Structure.Insert("CertificateRevoked", Context.CertificateRevoked);
			Structure.Insert("IsVerificationRequired", GeneralDescriptionOfTheError = Undefined
				Or (Context.IsCheckRequiredAtServer = Undefined Or Context.IsCheckRequiredAtServer)
				And (Context.IsCheckRequiredAtClient = Undefined Or Context.IsCheckRequiredAtClient));
			
			RunCallback(Context.Notification, Structure);
			
		Else
			RunCallback(Context.Notification, GeneralDescriptionOfTheError);
		EndIf;
		
	Else
		
		Structure = New Structure;
		Structure.Insert("ErrorDetailsAtClient", Context.ErrorDetailsAtClient);
		Structure.Insert("ErrorDescriptionAtServer", Context.ErrorDescriptionAtServer);
		Structure.Insert("AdditionalDataChecksAtServer", Context.AdditionalDataChecksAtServer);
		Structure.Insert("AdditionalDataChecksAtClient", Context.AdditionalDataChecksAtClient);
		
		If Context.ToVerifySignature Then
			
			Structure.Insert("CertificateRevoked", Context.CertificateRevoked);
			Structure.Insert("IsVerificationRequired", GeneralDescriptionOfTheError = Undefined
				Or (Context.IsCheckRequiredAtServer = Undefined Or Context.IsCheckRequiredAtServer)
				And (Context.IsCheckRequiredAtClient = Undefined Or Context.IsCheckRequiredAtClient));
			
			RunCallback(Context.Notification, Structure);
		Else
			RunCallback(Context.Notification, Structure);
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns additional parameters of the crypto manager creation.
//
// Returns:
//   Structure:
//     * ShowError - Boolean - if True, the ApplicationCallError form will open,
//                      from which you can go to the list of installed apps
//                      in the personal settings form on the "Installed applications" page,
//                      where you can see why the app could not be used,
//                      and open the installation instructions.
//                      - Undefined - Return all application call errors (see above).
//
//     * Application          - Undefined - returns a crypto manager of the first
//                          application from the catalog for which it was possible to create it.
//                          - CatalogRef.DigitalSignatureAndEncryptionApplications - an application
//                          that requires creating and returning a crypto manager.
//                          - Structure - See DigitalSignature.NewApplicationDetails
//                          - BinaryData - DER-encoded data from a signature or certificate used to determine the application.
//                          - String - Address of the binary data in the temp storage.
//
//
//     * InteractiveMode - Boolean - if True, then the crypto manager will be created
//                          in the interactive crypto mode
//                          (setting the PrivateKeyAccessPassword property will be prohibited).
//
//     * SignAlgorithm    - String - If specified, returns an app that uses this signature algorithm.
//     * EncryptAlgorithm - String - If specified, returns an application with the given encryption algorithm.
//     * AutoDetect    - Boolean - Flag indicating whether to autodetect installed apps,
//                          if no app is specified explicitly.
//
Function CryptoManagerCreationParameters() Export
	
	CryptoManagerCreationParameters = New Structure;
	CryptoManagerCreationParameters.Insert("ShowError", False);
	CryptoManagerCreationParameters.Insert("Application", Undefined);
	CryptoManagerCreationParameters.Insert("InteractiveMode", False);
	CryptoManagerCreationParameters.Insert("SignAlgorithm", "");
	CryptoManagerCreationParameters.Insert("EncryptAlgorithm", "");
	CryptoManagerCreationParameters.Insert("AutoDetect", True);
	
	Return CryptoManagerCreationParameters;
	
EndFunction

// Creates and returns the crypto manager (on the client) for the specified application.
//
// Parameters:
//  Notification     - CallbackDescription - Runtime result notification of the following types:
//    = String - Details of the cryptographic manager creation error.
//    = Structure -  See DigitalSignatureInternalClientServer.NewErrorsDescription
//    = CryptoManager - Initialized crypto manager.
//
//  Operation       - String - if it is not blank, it needs to contain one of rows that determine
//                   the operation to insert into the error description: Signing, SignatureCheck, Encryption,
//                   Decryption, CertificateCheck, and GetCertificates.
//  CryptoManagerCreationParameters - See CryptoManagerCreationParameters.
//
Procedure CreateCryptoManager(Notification, Operation, CryptoManagerCreationParameters = Undefined) Export
	
	If CryptoManagerCreationParameters = Undefined Then
		CryptoManagerCreationParameters = CryptoManagerCreationParameters();
	EndIf;
	
	Context = ContextCreateCryptoManager();
	FillPropertyValues(Context, CryptoManagerCreationParameters);
	Context.Operation	= Operation;
	Context.Notification = Notification;
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"CreateCryptoManagerAfterAttachCryptoExtension", ThisObject, Context));
	
EndProcedure

// Returns:
//  Structure:
//   * InteractiveMode - Boolean
//   * SignAlgorithm - String
//   * EncryptAlgorithm - String
//   * ShowError - Boolean
//   * Application - CatalogRef.DigitalSignatureAndEncryptionApplications
//               - BinaryData - DER-encoded data from a signature or certificate
//               - String - Data address in the temp storage.
//               - Structure - See DigitalSignature.NewApplicationDetails
//               - FixedStructure - See DigitalSignature.NewApplicationDetails
//   * Notification - CallbackDescription
//   * Operation - See CreateCryptoManager.Operation
//   * AutoDetect - Boolean
//   * ApplicationsDetails - Array of See DigitalSignatureInternalCached.ApplicationDetails
//   * ErrorProperties - Array of Structure:
//      ** LongDesc - String
//   * IndexOf - Number
// 
Function ContextCreateCryptoManager()
	
	Context = New Structure;
	Context.Insert("Operation");
	Context.Insert("Notification");
	Context.Insert("Application");
	Context.Insert("ShowError");
	Context.Insert("SignAlgorithm");
	Context.Insert("EncryptAlgorithm");
	Context.Insert("InteractiveMode");
	Context.Insert("AutoDetect");
	
	Return Context;
	
EndFunction

// Continues the CreateCryptoManager procedure.
Async Procedure CreateCryptoManagerAfterAttachCryptoExtension(Attached, Context) Export
	
	FormCaption = NStr("vi = 'Cần có ứng dụng chữ ký điện tử và mã hóa';
						|ru = 'Требуется приложение электронной подписи и шифрования';
						|en = 'A digital signing and encryption app is required'; fa = 'A digital signing and encryption app is required';
						|it = 'Требуется приложение электронной подписи и шифрования';
						|pl = 'A digital signing and encryption app is required';
						|tr = 'Dijital imza ve şifreleme uygulaması gerekli'");
	ErrorTitle = OperationErrorTitle(Context.Operation, Context.ShowError);
	ErrorsDescription = DigitalSignatureInternalClientServer.NewErrorsDescription();
	ErrorsDescription.ErrorTitle = ErrorTitle;
	
	CommonErrorText = "";
	
	If Not CommonClient.IsWindowsClient()
		And Not CommonClient.IsLinuxClient()
		And Not CommonClient.IsMacOSClient() Then
		
		CommonErrorText = ErrorTextDeviceNotSupported();
			
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		ErrorProperties.NotSupported = True;
	EndIf;
	
	If Not Attached Then
		CommonErrorText = NStr("vi = 'Cài đặt tiện ích mở rộng trong trình duyệt để hoạt động với 1C: Enterprise.';
								|ru = 'Установите в браузере расширение для работы с 1С:Предприятием.';
								|en = 'Install 1C:Enterprise Extension.'; fa = 'Install 1C:Enterprise Extension.';
								|it = 'Установите в браузере расширение для работы с 1С:Предприятием.';
								|pl = 'Install 1C:Enterprise Extension.';
								|tr = '1C:Enterprise uzantısını tarayıcınıza yükleyin.'");
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		ErrorProperties.NoExtension = True;
	EndIf;
	
	If TypeOf(Context.Application) = Type("String") Or TypeOf(Context.Application) = Type("BinaryData") Then
		
		IsPrivateKeyRequied = Context.Operation = "Signing"
			Or Context.Operation = "Details";
		
		Result = Await PopulateParametersForCreatingCryptoManager(Context, IsPrivateKeyRequied);
		Context = Result.Context;
		
		If ValueIsFilled(Result.Error) Then
			
			If IsPrivateKeyRequied And Context.Application = Undefined Then
				
				CommonErrorText = Result.Error;
				ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			
			Else
				
				ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
				ErrorProperties.LongDesc = Result.Error;
				ErrorsDescription.Errors.Add(ErrorProperties);
			
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CommonErrorText) Then
		ErrorProperties.LongDesc = CommonErrorText;
		
		ErrorsDescription.Shared3 = True;
		ErrorsDescription.Errors.Add(ErrorProperties);
		ErrorsDescription.ErrorDescription = TrimAll(ErrorTitle + Chars.LF + CommonErrorText);
		
		If Context.ShowError = Undefined Then
			ErrorDescription = ErrorsDescription;
		Else
			ErrorDescription = ErrorsDescription.ErrorDescription;
		EndIf;

		If Context.ShowError = True And CommonErrorText <> ErrorTextDeviceNotSupported() Then
			ShowApplicationCallError(FormCaption, "", ErrorsDescription, New Structure);
		EndIf;
		RunCallback(Context.Notification, ErrorDescription);
		
		Return;
	EndIf;
	
	AppsAuto = Undefined;
	
	If Context.AutoDetect And TypeOf(Context.Application) <> Type("Structure")
		And TypeOf(Context.Application) <> Type("FixedStructure") Then
		
		CryptoProvidersResult = Await InstalledCryptoProvidersFromCache();
		AppsAuto = DigitalSignatureInternalClientServer.CryptoProvidersSearchResult(CryptoProvidersResult);
		
		If TypeOf(AppsAuto) = Type("String") Then
			ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			ErrorProperties.LongDesc = AppsAuto;
			ErrorsDescription.Errors.Add(ErrorProperties);
			AppsAuto = Undefined;
		EndIf;
		
	EndIf;
	
	Context.Insert("FormCaption", FormCaption);
	Context.Insert("ErrorsDescription", ErrorsDescription);
	Context.Insert("IsLinux", RequiresThePathToTheProgram());
		
	ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
		Context.Application, ErrorsDescription.Errors, DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection, AppsAuto);
	
	Context.Insert("Manager", Undefined);
	
	If ApplicationsDetailsCollection = Undefined
		Or ApplicationsDetailsCollection.Count() = 0 Then
			CreateCryptoManagerAfterLoop(Context);
			Return;
	EndIf;
	
	Context.Insert("ApplicationsDetailsCollection",  ApplicationsDetailsCollection);
	Context.Insert("IndexOf", -1);
	
	CreateCryptoManagerLoopStart(Context);
	
EndProcedure

// Intended for: CreateCryptoManager procedure.
Function OperationErrorTitle(Operation, ShowError)
	
	If Operation = "Signing" Then
		ErrorTitle = NStr("vi = 'Không thể ký dữ liệu do nguyên nhân:';
							|ru = 'Не удалось подписать данные по причине:';
							|en = 'Cannot sign data due to:'; fa = 'Cannot sign data due to:';
							|it = 'Non è stato possibile firmare i dati a causa di:';
							|pl = 'Nie udało się podpisać danych z powodu:';
							|tr = 'Veriler şu sebeple imzalanamadı:'");
		
	ElsIf Operation = "CheckSignature" Then
		ErrorTitle = NStr("vi = 'Không thể kiểm tra chữ ký do nguyên nhân:';
							|ru = 'Не удалось проверить подпись по причине:';
							|en = 'Cannot verify the signature due to:'; fa = 'Cannot verify the signature due to:';
							|it = 'Non è stato possibile verificare la firma a causa di:';
							|pl = 'Nie udało się zweryfikować podpisu z powodu:';
							|tr = 'İmza şu sebeple denetlenemedi:'");
	
	ElsIf Operation = "Encryption" Then
		ErrorTitle = NStr("vi = 'Không thể mã hóa dữ liệu do nguyên nhân:';
							|ru = 'Не удалось зашифровать данные по причине:';
							|en = 'Cannot encrypt data due to:'; fa = 'Cannot encrypt data due to:';
							|it = 'Non è stato possibile crittografare i dati a causa di:';
							|pl = 'Nie można zaszyfrować danych z powodu:';
							|tr = 'Veriler şu sebeple şifrelenemedi:'");
		
	ElsIf Operation = "Details" Then
		ErrorTitle = NStr("vi = 'Không thể giải mã dữ liệu do:';
							|ru = 'Не удалось расшифровать данные по причине:';
							|en = 'Cannot decrypt data due to:'; fa = 'Cannot decrypt data due to:';
							|it = 'Non è stato possibile decrittare i dati a causa di:';
							|pl = 'Nie udało się odszyfrować danych z powodu:';
							|tr = 'Veriler şu sebeple detaylandırılamadı:'");
		
	ElsIf Operation = "CertificateCheck" Then
		ErrorTitle = NStr("vi = 'Không thể kiểm tra chứng thư do nguyên nhân:';
							|ru = 'Не удалось проверить сертификат по причине:';
							|en = 'Cannot verify the certificate due to:'; fa = 'Cannot verify the certificate due to:';
							|it = 'Non è stato possibile verificare il certificato a causa di:';
							|pl = 'Nie można zweryfikować certyfikatu z powodu:';
							|tr = 'Sertifika şu sebeple denetlenemedi:'");
		
	ElsIf Operation = "GetCertificates" Then
		ErrorTitle = NStr("vi = 'Không thể nhận chứng thư do nguyên nhân:';
							|ru = 'Не удалось получить сертификаты по причине:';
							|en = 'Cannot receive certificates due to:'; fa = 'Cannot receive certificates due to:';
							|it = 'Non è stato possibile ricevere i certificati a causa di:';
							|pl = 'Nie udało się uzyskać certyfikatów z powodu:';
							|tr = 'Sertifikalar şu sebeple alınamadı:'");
	
	ElsIf Operation = "ReadSignature" Then
		ErrorTitle = NStr("vi = 'Không thể đọc tất cả thuộc tính chữ ký theo nguyên nhân:';
							|ru = 'Не удалось прочитать все свойства подписи по причине:';
							|en = 'Cannot read all the signature properties due to:'; fa = 'Cannot read all the signature properties due to:';
							|it = 'Не удалось прочитать все свойства подписи по причине:';
							|pl = 'Cannot read all the signature properties due to:';
							|tr = 'Tüm imza özelliklerinin okunamama nedeni:'");
		
	ElsIf Operation = "ExtensionValiditySignature" Then
		ErrorTitle = NStr("vi = 'Không thể gia hạn ký do nguyên nhân:';
							|ru = 'Не удалось продлить действие подписи по причине:';
							|en = 'Cannot renew signature due to:'; fa = 'Cannot renew signature due to:';
							|it = 'Non è stato possibile prolungare la validità della firma a causa di:';
							|pl = 'Nie udało się przedłużyć terminu ważności podpisu z powodu:';
							|tr = 'İmza şu nedenle yenilenemedi:'");
		
	ElsIf Operation = Null And ShowError <> True Then
		ErrorTitle = "";
		
	ElsIf Operation <> "" Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi trong hàm %1.
			           |Sai giá trị tham số Thao tác ""%2"".';
			           |ru = 'Ошибка в функции %1.
			           |Неверное значение параметра Операция ""%2"".';
			           |en = 'Error in function ""%1"".
			           |Parameter ""Operation"" has invalid value: %2.'; fa = 'Error in function ""%1"".
			           |Parameter ""Operation"" has invalid value: %2.';
			           |it = 'Errore nella funzione %1.
			           | Valore errato del Parametro dell''operazione ""%2"".';
			           |pl = 'Błąd w funkcji %1.
			           |Niepoprawna wartość parametru Operacja ""%2"".';
			           |tr = '%1 işlevinde hata oluştu.
			           |""%2""İşlem parametre değeri geçersiz.'"), 
			"CryptoManager", Operation);
		Raise(MessageText, ErrorCategory.ConfigurationError);
	Else
		ErrorTitle = NStr("vi = 'Không thể thực hiện thao tác do nguyên nhân:';
							|ru = 'Не удалось выполнить операцию по причине:';
							|en = 'Cannot perform the operation. Reason:'; fa = 'Cannot perform the operation. Reason:';
							|it = 'Non è stato possibile eseguire l''operazione a causa di:';
							|pl = 'Operacja nie mogła zostać zakończona z powodu:';
							|tr = 'İşlem şu sebeple yürütülemedi:'");
	EndIf;
	
	Return ErrorTitle;
	
EndFunction

// Intended for: CreateCryptoManager procedure.
// 
// Returns the clarified context of the cryptography manager creation for the given signature or certificate data.
//  Context - See ContextCreateCryptoManager
//
Async Function PopulateParametersForCreatingCryptoManager(Context, IsPrivateKeyRequied)
	
	Result = New Structure("Context, Error", Context, "");
	Data = Context.Application;
	
	Try
		
		DataType = DigitalSignatureInternalClientServer.DefineDataType(Data);
		
	Except
		
		Result.Context.Application = Undefined;
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xác định ứng dụng chữ ký điện tử và mã hóa đối với dữ liệu được chuyển: %1';
				|ru = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных: %1';
				|en = 'Couldn''t determine digital signing and encryption app for the passed data: %1'; fa = 'Couldn''t determine digital signing and encryption app for the passed data: %1';
				|it = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных: %1';
				|pl = 'Couldn''t determine digital signing and encryption app for the passed data: %1';
				|tr = 'Aktarılan verilere ilişkin elektronik imza ve şifreleme uygulaması belirlenememiştir: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
		
	EndTry;
	
	If DataType = "Certificate" Then
		
		CertificateApplicationResult = Await AppForCertificate(Data, IsPrivateKeyRequied,, True);
		If ValueIsFilled(CertificateApplicationResult.Error) Then
			
			Result.Error = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				CertificateApplicationResult.Error);
			Result.Context.SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(Data);
			Result.Context.Application = Undefined;
			
		Else
			Result.Context.Application = CertificateApplicationResult.Application;
		EndIf;
		
		Return Result;
		
	ElsIf DataType = "Signature" Then
		
		Result.Context.Application = Undefined;
		Result.Context.SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Data);
		Return Result;
		
	ElsIf DataType = "EncryptedData" Then
		
		Result.Context.Application = Undefined;
		Result.Error = NStr("vi = 'Để xác định ứng dụng giải mã, cần truyền dữ liệu chứng thư vào thủ tục.';
							|ru = 'Для определения приложения для расшифровки в процедуру должны быть переданы данные сертификата.';
							|en = 'To determine a decryption app, pass the certificate data to the procedure.'; fa = 'To determine a decryption app, pass the certificate data to the procedure.';
							|it = 'Для определения приложения для расшифровки в процедуру должны быть переданы данные сертификата.';
							|pl = 'To determine a decryption app, pass the certificate data to the procedure.';
							|tr = 'Şifreleme uygulamasını tespit etmek için veriler sertifikası prosedüre aktarılmış olmalıdır.'");
		Return Result;
		
	EndIf;
	
	Result.Context.Application = Undefined;
	Result.Error = NStr("vi = 'Không thể xác định ứng dụng chữ ký điện tử và mã hóa đối với dữ liệu được chuyển.';
						|ru = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных.';
						|en = 'Couldn''t determine digital signing and encryption app for the passed data.'; fa = 'Couldn''t determine digital signing and encryption app for the passed data.';
						|it = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных.';
						|pl = 'Couldn''t determine digital signing and encryption app for the passed data.';
						|tr = 'Aktarılan verilere ilişkin elektronik imza ve şifreleme uygulaması belirlenememiştir.'");
	
	Return Result;
	
EndFunction

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerLoopStart(Context) Export
	
	If Context.ApplicationsDetailsCollection.Count() <= Context.IndexOf + 1 Then
		CreateCryptoManagerAfterLoop(Context);
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"CreateCryptoManagerLoopStartContinued", ThisObject, Context);
	
	StandardSubsystemsClient.StartNotificationProcessing(Notification);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerLoopStartContinued(Result, Context) Export
	
	Context = Context; // See ContextCreateCryptoManager
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDetails = Context.ApplicationsDetailsCollection[Context.IndexOf]; // See DigitalSignatureInternalCached.ApplicationDetails
	Context.Insert("ApplicationDetails", ApplicationDetails);
	
	If ValueIsFilled(Context.SignAlgorithm) Then
		SignAlgorithmSupported =
			DigitalSignatureInternalClientServer.CryptoManagerSignAlgorithmSupported(
				ApplicationDetails,
				?(Context.Property("Operation"), Context.Operation, ""),
				Context.SignAlgorithm,
				Context.ErrorsDescription.Errors,
				False,
				Context.Application <> Undefined);
		
		If Not SignAlgorithmSupported Then
			Context.Manager = Undefined;
			CreateCryptoManagerLoopStart(Context);
			Return;
		EndIf;
	EndIf;
	
	If ApplicationDetails.Property("AutoDetect") Then
		DescriptionOfWay = New Structure("ApplicationPath, Exists", ApplicationDetails.PathToAppAuto, True);
		CreateACryptographyManagerLoopAfterGettingTheProgramPath(DescriptionOfWay, Context);
		Return;
	EndIf;
	
	IDOfTheProgramPath = ?(ValueIsFilled(ApplicationDetails.Ref),
		ApplicationDetails.Ref, ApplicationDetails.Id);
	
	ToObtainThePathToTheProgram(New CallbackDescription("CreateACryptographyManagerLoopAfterGettingTheProgramPath",
		ThisObject, Context), IDOfTheProgramPath);
	
EndProcedure

Procedure CreateACryptographyManagerLoopAfterGettingTheProgramPath(DescriptionOfWay, Context) Export
	
	ApplicationProperties1 = DigitalSignatureInternalClientServer.CryptoManagerApplicationProperties(
		Context.ApplicationDetails,
		Context.IsLinux,
		Context.ErrorsDescription.Errors,
		False,
		DescriptionOfWay);
	
	If ApplicationProperties1 = Undefined Then
		CreateCryptoManagerLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("ApplicationProperties1", ApplicationProperties1);
	
	CryptoTools.BeginGettingCryptoModuleInformation(New CallbackDescription(
			"CreateCryptoManagerLoopAfterGetInformation", ThisObject, Context,
			"CreateCryptographyManagerLoopAfterInformationReceiptError", ThisObject),
		Context.ApplicationProperties1.ApplicationName,
		Context.ApplicationProperties1.ApplicationPath,
		Context.ApplicationProperties1.ApplicationType);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptographyManagerLoopAfterInformationReceiptError(ErrorInfo, StandardProcessing, Context) Export
	
	CreateCryptographyManagerLoopOnInitializationError(ErrorInfo, StandardProcessing, Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
// 
// Parameters:
//   ModuleInfo - CryptoModuleInformation
//   Context - Structure
//
Procedure CreateCryptoManagerLoopAfterGetInformation(ModuleInfo, Context) Export
	
	If ModuleInfo = Undefined Then
		DigitalSignatureInternalClientServer.CryptoManagerApplicationNotFound(
			Context.ApplicationDetails, Context.ErrorsDescription.Errors, False);
		
		Context.Manager = Undefined;
		CreateCryptoManagerLoopStart(Context);
		Return;
	EndIf;
	
	If Not Context.IsLinux Then
		ApplicationNameReceived = ModuleInfo.Name;
		
		ApplicationNameMatches = DigitalSignatureInternalClientServer.CryptoManagerApplicationNameMaps(
			Context.ApplicationDetails, ApplicationNameReceived, Context.ErrorsDescription.Errors, False);
		
		If Not ApplicationNameMatches Then
			Context.Manager = Undefined;
			CreateCryptoManagerLoopStart(Context);
			Return;
		EndIf;
	EndIf;
	
	Context.Manager = New CryptoManager;
	
	If Not Context.InteractiveMode Then
		Context.Manager.BeginInitialization(New CallbackDescription(
				"CreateCryptoManagerLoopAfterInitialize", ThisObject, Context,
				"CreateCryptographyManagerLoopOnInitializationError", ThisObject),
			Context.ApplicationProperties1.ApplicationName,
			Context.ApplicationProperties1.ApplicationPath,
			Context.ApplicationProperties1.ApplicationType);
	Else
		Context.Manager.BeginInitialization(New CallbackDescription(
				"CreateCryptoManagerLoopAfterInitialize", ThisObject, Context,
				"CreateCryptographyManagerLoopOnInitializationError", ThisObject),
			Context.ApplicationProperties1.ApplicationName,
			Context.ApplicationProperties1.ApplicationPath,
			Context.ApplicationProperties1.ApplicationType,
			InteractiveCryptoModeUsageUse());
	EndIf;
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptographyManagerLoopOnInitializationError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	Context.Manager = Undefined;
	
	ApplicationDetails = Context.ApplicationDetails; // See DigitalSignatureInternalCached.ApplicationDetails
	DigitalSignatureInternalClientServer.CryptoManagerAddError(
		Context.ErrorsDescription.Errors,
		ApplicationDetails.Ref,
		ErrorProcessing.BriefErrorDescription(ErrorInfo),
		False, True, True);
	
	CreateCryptoManagerLoopStart(Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerLoopAfterInitialize(Var_Undefined, Context) Export
	
	EncryptAlgorithm = CommonClientServer.StructureProperty(Context, "EncryptAlgorithm", "");
	
	AlgorithmsSet = DigitalSignatureInternalClientServer.CryptoManagerAlgorithmsSet(
		Context.ApplicationDetails,
		Context.Manager,
		Context.ErrorsDescription.Errors,
		EncryptAlgorithm);
	
	If Not AlgorithmsSet Then
		CreateCryptoManagerLoopStart(Context);
		Return;
	EndIf;
	
	// The required crypto manager is received.
	CreateCryptoManagerAfterLoop(Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerAfterLoop(Context)
	
	If Context.Manager <> Undefined Or Not Context.Property("FormCaption") Then
		RunCallback(Context.Notification, Context.Manager);
		Return;
	EndIf;
	
	ErrorsDescription = Context.ErrorsDescription;
	DigitalSignatureInternalClientServer.CryptoManagerFillErrorsPresentation(
		ErrorsDescription,
		Context.Application,
		Context.SignAlgorithm,
		UsersClient.IsFullUser(),
		False);
	
	If Context.ShowError = Undefined Then
		ErrorDescription = ErrorsDescription;
	Else
		ErrorDescription = ErrorsDescription.ErrorDescription;
	EndIf;
	
	If Context.ShowError = True Then
		ShowApplicationCallError(Context.FormCaption, "", ErrorsDescription, New Structure);
	EndIf;
	
	RunCallback(Context.Notification, ErrorDescription);
	
EndProcedure

Async Function AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(SuggestInstall = True, ExplanationText = Undefined) Export
	
	If Not CommonClient.IsWindowsClient()
	   And Not CommonClient.IsLinuxClient()
	   And Not CommonClient.IsMacOSClient() Then
		
		Raise ErrorTextDeviceNotSupported();
		
	EndIf;
	
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	If ExplanationText = Undefined Then
		ConnectionParameters.ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để đơn giản hóa làm việc với mã hóa, cần cài đặt cấu phần ngoài %1.';
				|ru = 'Для упрощения работы с криптографией требуется установка внешней компоненты %1.';
				|en = 'To simplify operations with the cryptography, install the %1 add-in.'; fa = 'To simplify operations with the cryptography, install the %1 add-in.';
				|it = 'Для упрощения работы с криптографией требуется установка внешней компоненты %1.';
				|pl = 'To simplify operations with the cryptography, install the %1 add-in.';
				|tr = 'İşin kriptografiyle basitleştirilmesi için %1 harici bileşeninin kurulması gerektirmektedir.'"),
			ComponentDetails.ObjectName);
	Else
		ConnectionParameters.ExplanationText = ExplanationText;
	EndIf;
	ConnectionParameters.SuggestInstall = SuggestInstall;
	ConnectionParameters.SuggestToImport = False;
	
	Result = Await CommonClient.AttachAddInFromTemplateAsync(
		ComponentDetails.ObjectName,
		ComponentDetails.FullTemplateName,
		ConnectionParameters);
	
	If Result.Attached Then
		ComponentObject = Result.Attachable_Module;
		ComponentObject = Await ConfigureTheComponent(ComponentObject);
		FillPathToAddInLog(ComponentObject, ComponentDetails.ObjectName);

	ElsIf ValueIsFilled(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối cấu phần ngoài %1.';
				|ru = 'Не удалось подключить внешнюю компоненту %1.';
				|en = 'Couldn''t attach add-in ""%1"".'; fa = 'Couldn''t attach add-in ""%1"".';
				|it = 'Non è stato possibile collegare la componente esterna %1.';
				|pl = 'Nie udało się podłączyć komponentu zewnętrznego %1.';
				|tr = '%1 harici bileşen bağlanamadı.'"), ComponentDetails.ObjectName);
			Raise ErrorText;
	EndIf;
	
	Return ComponentObject;
	
EndFunction

Async Function ConfigureTheComponent(ComponentObject)
	
	Try
		Await ComponentObject.SetOIDMapAsync(
			DigitalSignatureInternalClientServer.IdentifiersOfHashingAlgorithmsAndThePublicKey());
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập thuộc tính %1 cấu phần %2 do nguyên nhân:
				|%3';
				|ru = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|en = 'Cannot set the %1 property of the %2 add-in due to:
				|%3'; fa = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';
				|it = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|pl = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';
				|tr = '%2 bileşeninin %1 özelliği şu sebeple kurulamadı:
				|%3'"), "OIDMap", "ExtraCryptoAPI", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	Return ComponentObject;
	
EndFunction

Async Procedure FillPathToAddInLog(ComponentObject, FileName)
	PathToDiagnosticsDirectory = DigitalSignatureClient.PersonalSettings().PathToDiagnosticsDirectory;
	SystemInfo = New SystemInfo();
	PathToAddInLogOnClient = PathToDiagnosticsDirectory.Get(SystemInfo.ClientID);
	If ValueIsFilled(PathToAddInLogOnClient) Then
		Await ComponentObject.SetLog_Async(CommonClientServer.AddLastPathSeparator(
				PathToAddInLogOnClient) + FileName + ".log");
	EndIf;
EndProcedure

Async Function AppForCertificate(Certificate,
	IsPrivateKeyRequied = Undefined, ComponentObject = Undefined, SuggestInstall = False) Export
	
	Result = New Structure("Application, Error");
	
#If MobileClient Or MobileAppClient Then
		Result.Error = ErrorTextDeviceNotSupported();
		Return Result;
#EndIf

	If ComponentObject = Undefined Then
		
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để nhận dữ liệu về ứng dụng để làm việc với chứng thư chữ ký điện tử, cần thiết lập cấu phần ngoài %1.';
				|ru = 'Для получения данных о приложении для работы с сертификатом электронной подписи требуется установка внешней компоненты %1.';
				|en = 'To get information on the digital signing and encryption app, install the %1 add-in.'; fa = 'To get information on the digital signing and encryption app, install the %1 add-in.';
				|it = 'Для получения данных о приложении для работы с сертификатом электронной подписи требуется установка внешней компоненты %1.';
				|pl = 'To get information on the digital signing and encryption app, install the %1 add-in.';
				|tr = 'Dijital imza sertifikasıyla çalışmaya yönelik uygulama hakkında veri elde etmek için %1 harici bileşenini yapılandırmanız gerekmektedir.'"),
			"ExtraCryptoAPI");
		
		Try
			ComponentObject = Await AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(SuggestInstall, ExplanationText);
		Except
			Result.Error = ErrorTextAddInNotInstalled();
			Return Result;
		EndTry;
	EndIf;

	Certificate = Await CertificateBase64String(Certificate);
	
	If IsPrivateKeyRequied <> False Then
		
		Try
			CryptoProviderPropertyResult = Await ComponentObject.GetCryptoProviderPropertiesAsync(Certificate);
			CurCryptoProvider = CryptoProviderFromAddInResponse(CryptoProviderPropertyResult.Value);
		Except
			Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Return Result;
		EndTry;
		
		ApplicationsByNamesWithType = DigitalSignatureClient.CommonSettings().ApplicationsByNamesWithType;
		ExtendedApplicationDetails = DigitalSignatureInternalClientServer.ExtendedApplicationDetails(
			CurCryptoProvider, ApplicationsByNamesWithType);
			
		If ExtendedApplicationDetails <> Undefined Then
			Result.Application = ExtendedApplicationDetails;
			Return Result;
		ElsIf IsPrivateKeyRequied = True And ValueIsFilled(CurCryptoProvider) And CurCryptoProvider.Get("type") <> 0 Then
			Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng thư liên kết với ứng dụng %1 có kiểu %2, hãy tùy chỉnh ứng dụng trong danh mục để sử dụng.';
					|ru = 'Сертификат связан с приложением %1 с типом %2, настройте его в справочнике для дальнейшего использования.';
					|en = 'The certificate is connected to the %1 app (of the %2 type). To use it, configure it in the catalog.'; fa = 'The certificate is connected to the %1 app (of the %2 type). To use it, configure it in the catalog.';
					|it = 'Сертификат связан с приложением %1 с типом %2, настройте его в справочнике для дальнейшего использования.';
					|pl = 'The certificate is connected to the %1 app (of the %2 type). To use it, configure it in the catalog.';
					|tr = 'Sertifika %2 türündeki %1 uygulamasına bağlandı, kullanılabilmesi için kataloğunda ayarlayın.'"),
				CurCryptoProvider.Get("name"),
				CurCryptoProvider.Get("type"));
			Return Result;
		EndIf;
		
	EndIf;
	
	If IsPrivateKeyRequied = True Then
		Result.Error = ErrorTextCannotDetermineAppByPrivateCertificateKey();
		Return Result;
	EndIf; 
	
	CertificateProperties = Await GetCertificatePropertiesAsync(Certificate, ComponentObject);
	If ValueIsFilled(CertificateProperties.Error) Then
		Result.Error = CertificateProperties.Error;
		Return Result;
	EndIf;
	
	CertificateProperties = CertificateProperties.CertificateProperties;
	
	InstalledCryptoProviders = Await InstalledCryptoProvidersFromCache(
		SuggestInstall);
		
	If InstalledCryptoProviders.CheckCompleted Then
		
		ApplicationsByPublicKeyAlgorithmsIDs = DigitalSignatureClient.CommonSettings().ApplicationsByPublicKeyAlgorithmsIDs;
		Error = "";
		ExtendedApplicationDetails = DigitalSignatureInternalClientServer.DefineApp(CertificateProperties,
			InstalledCryptoProviders.Cryptoproviders, ApplicationsByPublicKeyAlgorithmsIDs, Error);
		Result.Application = ExtendedApplicationDetails;
		
		If Result.Application = Undefined Then
			Result.Error = Error;
		EndIf;
		
		Return Result;
		
	Else
		Result.Error = InstalledCryptoProviders.Error;
		Return Result;
	EndIf;

EndFunction

Function ErrorTextCannotDetermineAppByPrivateCertificateKey()
	
	Return NStr("vi = 'Không thể xác định ứng dụng chữ ký điện tử và mã hóa theo khóa bảo mật chứng thư.';
				|ru = 'Не удалось определить приложение электронной подписи и шифрования по закрытому ключу сертификата.';
				|en = 'Couldn''t determine digital signing and encryption app by the passed certificate''s private key.'; fa = 'Couldn''t determine digital signing and encryption app by the passed certificate''s private key.';
				|it = 'Не удалось определить приложение электронной подписи и шифрования по закрытому ключу сертификата.';
				|pl = 'Couldn''t determine digital signing and encryption app by the passed certificate''s private key.';
				|tr = 'Sertifikanın özel anahtarı kullanılarak elektronik imza ve şifreleme uygulaması belirlenemedi.'");
	
EndFunction

Function CryptoProviderFromAddInResponse(Val Text)

	Result = New Map;

	Try
		
		FillMapFromJSONResponse(Result, Text);
		Return Result;

	Except

		ErrorInfo = ErrorProcessing.BriefErrorDescription(ErrorInfo());

		Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đọc phản hồi cấu phần: %1
						 |%2';
						 |ru = 'Не удалось прочитать ответ компоненты: %1
						 |%2';
						 |en = 'Cannot read the add-in response: %1
						 |%2'; fa = 'Cannot read the add-in response: %1
						 |%2';
						 |it = 'Не удалось прочитать ответ компоненты: %1
						 |%2';
						 |pl = 'Cannot read the add-in response: %1
						 |%2';
						 |tr = 'Şu bileşene yanıt yazılamadı: %1
						 |%2'"), Text, ErrorInfo);

	EndTry;
	
	Return Result;
	
EndFunction

// Intended for the CryptoProviderFromAddInResponse function
Procedure FillMapFromJSONResponse(Result, Val JSONText)
	
	JSONText = StrReplace(TrimAll(JSONText), Chars.LF, "");
	JSONText = TrimAll(Mid(JSONText, 2, StrLen(JSONText)-2));
	
	While JSONText <> "" Do
		
		Position = StrFind(JSONText, ":");
		If Position = 0 Then
			Break;
		EndIf;
		
		EnumValueName = TrimAll(Left(JSONText, Position-1));
		EnumValueName = StrReplace(EnumValueName, """","");
		
		IsNumber = False;
		JSONText = TrimAll(Mid(JSONText, Position+1));
		If Left(JSONText, 1) = """" Then
			JSONText = TrimAll(Mid(JSONText, 2));
		Else
			IsNumber = True;
		EndIf; 
		
		Position = 0;
		For NewPosition = 1 To StrLen(JSONText) Do
			Char = Mid(JSONText, NewPosition, 1);
			
			NextChar = Undefined;
			If Char = "," Then
				For NextPosition = NewPosition + 1 To StrLen(JSONText) Do
					NextChar = Mid(JSONText, NextPosition, 1);
					If NextChar <> " " Then
						Break;
					EndIf; 
				EndDo; 
			EndIf; 
			If Char = "," And (NextChar = Undefined Or NextChar = """") Then
				Position = NewPosition;
				Break;
			EndIf;
		EndDo;
		
		If Position = 0 Then
			Value = JSONText;
			JSONText = "";
		Else
			Value = Left(JSONText, Position-1);
			JSONText = TrimAll(Mid(JSONText, Position + ?(Mid(JSONText, Position, 1) = ",", 1, 0)));
		EndIf;
		
		Value = TrimAll(Value);
		If Value = "true" Then
			Value = True;
		ElsIf Value = "false" Then
			Value = False;
		ElsIf Value = "null" Then
			Value = Undefined;
		Else
			If IsNumber Then
				Value = StringFunctionsClientServer.StringToNumber(Value);
			Else
				Value = Left(Value, StrLen(Value)-1);
			EndIf;
		EndIf;
		
		Result.Insert(EnumValueName, Value);
		
	EndDo;
	
EndProcedure

// Certificate's containers.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Certificate's string presentation in the Base64 format
//             - CryptoCertificate
//  ComponentObject - AddInObject  - Instance of the add-in object
//
// Returns:
//  Promise - In case a known error occurred. See ContainerNewProperties
//           - Undefined - In case a known error occurred.
//
Async Function ContainersByCertificate(Certificate, ComponentObject = Undefined) Export
	
	If ComponentObject = Undefined Then
		ComponentObject = Await AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(True);
	EndIf;
	
	Certificate = Await CertificateBase64String(Certificate);
	
	Containers = New Array;
	CertificatePropertiesResult = Await GetCertificatePropertiesAsync(Certificate, ComponentObject);
	
	If Not IsBlankString(CertificatePropertiesResult.Error) Then
		ClassifierError = DigitalSignatureInternalServerCall.ClassifierError(CertificatePropertiesResult.Error);
		If ClassifierError = Undefined Then
			Raise CertificatePropertiesResult.Error;
		Else
			ErrorParameters = New Structure;
			ErrorParameters.Insert("WarningTitle", NStr("vi = 'Không thể nhận nơi chứa theo chứng thư';
														|ru = 'Не удалось получить контейнеры по сертификату';
														|en = 'Cannot receive containers for the certificate'; fa = 'Cannot receive containers for the certificate';
														|it = 'Cannot receive containers for the certificate';
														|pl = 'Cannot receive containers for the certificate';
														|tr = 'Sertifikaya göre konteyner alınamadı'"));
			ErrorParameters.Insert("ErrorTextClient", CertificatePropertiesResult.Error);
			ErrorParameters.Insert("ShowNeedHelp", True);
			OpenExtendedErrorPresentationForm(ErrorParameters);
			Return Undefined;
		EndIf;
	EndIf;
	
	CertificateProperties = CertificatePropertiesResult.CertificateProperties;
	
	ContainersNames = New Map;
	CertificateApplicationResult = Await AppForCertificate(Certificate, Undefined, ComponentObject, True);
	
	If CertificateApplicationResult.Application <> Undefined Then
		Containers = Await AddContainerByCertificateByCryptoProvider(
			CertificateProperties, CertificateApplicationResult.Application,
			ComponentObject, Containers, ContainersNames);
			
		For Each CurContainer In Containers Do
			ContainersNames.Insert(CurContainer.Name, True);
		EndDo;
	EndIf;
	
	CryptoProvidersResult = Await InstalledCryptoProviders(ComponentObject);
	
	If Not CryptoProvidersResult.CheckCompleted Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận danh sách nhà cung cấp mã hóa đã cài đặt:
				|%1';
				|ru = 'Не удалось получить список установленных криптопровайдеров:
				|%1';
				|en = 'Cannot receive a list of installed cryptographic service providers:
				|%1'; fa = 'Cannot receive a list of installed cryptographic service providers:
				|%1';
				|it = 'Не удалось получить список установленных криптопровайдеров:
				|%1';
				|pl = 'Cannot receive a list of installed cryptographic service providers:
				|%1';
				|tr = 'Kurulan kripto sağlayıcılarının listesi alınamadı:
				|%1'"), CryptoProvidersResult.Error);
	EndIf;
	
	For Each CurCryptoProvider In CryptoProvidersResult.Cryptoproviders Do
		Containers = Await AddContainerByCertificateByCryptoProvider(
			CertificateProperties, CurCryptoProvider,
			ComponentObject, Containers, ContainersNames);
		For Each CurContainer In Containers Do
			ContainersNames.Insert(CurContainer.Name, True);
		EndDo;
	EndDo;
	
	Return Containers;
	
EndFunction

// For ContainersByCertificate
Async Function AddContainerByCertificateByCryptoProvider(CertificateProperties, Cryptoprovider, ComponentObject, Containers, ContainersNames)
	
	Result = Await ComponentObject.FindContainersAsync(
			Cryptoprovider.ApplicationType,
			Cryptoprovider.ApplicationName,
			CertificateProperties.Certificate);

	If ValueIsFilled(Result.Value) And Result.Value <> "null" Then
		Read = DigitalSignatureInternalClientServer.ReadAddInResponce(Result.Value);
	Else
		Return Containers;
	EndIf;

	CryptoProviderContainders = Read.Get(Cryptoprovider.ApplicationName);
	ContainersProperties = CryptoProviderContainders.Get("containers");

	If ContainersProperties = Undefined Then
		Return Containers;
	EndIf;

	For Each CurContainer In ContainersProperties Do

		NameOfContainer = CurContainer.Get("FQCN");

		If ContainersNames.Get(NameOfContainer) = True Then
			Continue;
		EndIf;

		IsCurrentContainer = NameOfContainer = CertificateProperties.NameOfContainer;

		Container = ContainerNewProperties();
		Container.Name = NameOfContainer;
		Container.FriendlyName = CurContainer.Get("Friendly name");
		If Not ValueIsFilled(Container.FriendlyName) Then
			Container.FriendlyName = Container.Name;
		EndIf;
		Container.ApplicationType = Cryptoprovider.ApplicationType;
		Container.ApplicationName = Cryptoprovider.ApplicationName;
		Container.ApplicationPath = Cryptoprovider.PathToAppAuto;

		Container.Insert("IsCurrentContainer", IsCurrentContainer);

		Containers.Add(Container);

	EndDo;
	
	Return Containers;
	
EndFunction

// Properties of the private key container.
// 
// Returns:
//  Structure:
//   * Name - String 
//   * FriendlyName - String
//   * ApplicationType - Number
//   * ApplicationName - String
//   * ApplicationPath - String
//
Function ContainerNewProperties() Export
	
	Container = New Structure;
	Container.Insert("Name", "");
	Container.Insert("FriendlyName", "");
	Container.Insert("ApplicationType", 0);
	Container.Insert("ApplicationName", "");
	Container.Insert("ApplicationPath", "");
	
	Return Container;
	
EndFunction


// For internal purpose only.
// 
// Parameters:
//  CreationParameters - See CertificateAddingOptions
//  CompletionHandler - Undefined - Completion handler
//
Procedure ToAddCertificate(CreationParameters = Undefined, CompletionHandler = Undefined) Export
	
	CertificateAddingOptions = CertificateAddingOptions();
	FillPropertyValues(CertificateAddingOptions, CreationParameters);
	CertificateAddingOptions.CompletionHandler = CompletionHandler;
	
	If CertificateAddingOptions.CreateRequest = True Then
		AddCertificateAfterPurposeChoice("CertificateIssueRequest", CertificateAddingOptions);
		Return;
	EndIf;
	
	If CertificateAddingOptions.HideApplication = Undefined Then
		CertificateAddingOptions.HideApplication = True;
	EndIf;
	
	Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddingCertificate",
		New Structure("HideApplication", CertificateAddingOptions.HideApplication),,,,,
		New CallbackDescription("AddCertificateAfterPurposeChoice", ThisObject, CertificateAddingOptions));
	
	If Form = Undefined Then
		AddCertificateAfterPurposeChoice("ToSignEncryptAndDecrypt", CertificateAddingOptions);
	EndIf;
	
EndProcedure

// For internal purpose only.
// 
// Returns:
//  Structure - Parameters for adding a certificate:
//   * ToPersonalList - Boolean - False if not specified.
//   * Organization - DefinedType.Organization - a default value.
//   * Individual - CatalogRef - the individual for whom you need to create an application
//                       for certificate issue (when it is filled in, has priority over the company).
//                       The default value is Undefined.
//   * CertificateBasis - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Certificate to be reissued.
//   * CompletionHandler - CallbackDescription
//   * CreateRequest - Boolean - Immediately open the certificate application form.
//   * HideApplication - Boolean - Do not prompt to create a certificate application.
//   * IsOnToken - Boolean - By default, select token in certificate issuance applications.
//
Function CertificateAddingOptions() Export
	
	Structure = New Structure;
	Structure.Insert("ToPersonalList", False);
	Structure.Insert("Organization", Undefined);
	Structure.Insert("Individual", Undefined);
	Structure.Insert("CertificateBasis", Undefined);
	Structure.Insert("CompletionHandler", Undefined);
	Structure.Insert("CreateRequest", Undefined);
	Structure.Insert("HideApplication", Undefined);
	Structure.Insert("IsOnToken", False);
	
	Return Structure;
	
EndFunction

// For internal purpose only.
Procedure AddCertificateAfterPurposeChoice(Purpose, CreationParameters) Export
	
	FormParameters = New Structure;
	
	If Purpose = "CertificateIssueRequest" Then
		FormParameters.Insert("Organization", CreationParameters.Organization);
		FormParameters.Insert("Individual", CreationParameters.Individual);
		FormParameters.Insert("CertificateBasis", CreationParameters.CertificateBasis);
		FormParameters.Insert("IsOnToken", CreationParameters.IsOnToken);
		FormName = "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Form.Form";
		OpenForm(FormName, FormParameters, , , , , CreationParameters.CompletionHandler);
		Return;
	EndIf;
	
	If Purpose = "OnlyForEncryptionFromFile" Then
		AddCertificateOnlyToEncryptFromFile(CreationParameters);
		Return;
	EndIf;
	
	If Purpose = "OnlyForEncryptionFromFiles" Then
		AddCertificateOnlyToEncryptFromFile(CreationParameters, True);
		Return;
	EndIf;
	
	If Purpose = "OnlyForEncryptionFromDirectory" Then
		AddCertificateOnlyToEncryptFromDirectory(CreationParameters);
		Return;
	EndIf;
	
	If Purpose = "ForSigningEncryptionAndDecryptionFromFiles" Then
		FormParameters.Insert("CompletionHandler", CreationParameters.CompletionHandler);
		FormParameters.Insert("CanAddToList", True);
		FormParameters.Insert("PersonalListOnAdd", CreationParameters.ToPersonalList);
		FormParameters.Insert("Organization", CreationParameters.Organization);
		FormParameters.Insert("ShouldDisplayAddCommands", False);
		AddCertificateForSigningOrDecryptionFromFile(CreationParameters);
		Return;
	EndIf;
	
	If Purpose <> "ToEncryptOnly" Then
		FormParameters.Insert("ToEncryptAndDecrypt", Undefined);
		
		If Purpose = "ToEncryptAndDecrypt" Then
			FormParameters.Insert("ToEncryptAndDecrypt", True);
		
		ElsIf Purpose <> "ToSignEncryptAndDecrypt" Then
			Return;
		EndIf;
		
		FormParameters.Insert("CanAddToList", True);
		FormParameters.Insert("PersonalListOnAdd", CreationParameters.ToPersonalList);
		FormParameters.Insert("Organization", CreationParameters.Organization);
		FormParameters.Insert("ShouldDisplayAddCommands", False);
		SelectSigningOrDecryptionCertificate(FormParameters, , CreationParameters.CompletionHandler);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("CreationParameters", CreationParameters);
	
	GetCertificatesPropertiesAtClient(New CallbackDescription(
			"AddCertificateAfterGetCertificatesPropertiesAtClient", ThisObject, Context),
		False, False);
	
EndProcedure

// Continues the AddCertificateAfterPurposeChoice procedure.
Procedure AddCertificateAfterGetCertificatesPropertiesAtClient(Result, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificatesPropertiesAtClient",        Result.CertificatesPropertiesAtClient);
	FormParameters.Insert("ErrorOnGetCertificatesAtClient", Result.ErrorOnGetCertificatesAtClient);
	
	If Context.CreationParameters.Property("ToPersonalList") Then
		FormParameters.Insert("PersonalListOnAdd", Context.CreationParameters.ToPersonalList);
	EndIf;
	If Context.CreationParameters.Property("Organization") Then
		FormParameters.Insert("Organization", Context.CreationParameters.Organization);
	EndIf;
	
	CompletionHandler = Undefined;
	Context.CreationParameters.Property("CompletionHandler", CompletionHandler);
	
	Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddEncryptionCertificate",
		FormParameters, , , , , CompletionHandler);
		
	If Not Form.IsOpen() And Not IsBlankString(Form.WarningTextOnOpen) Then
		ShowMessageBox(, Form.WarningTextOnOpen);
	EndIf;
	
EndProcedure

// For internal purpose only.
Procedure GetCertificatesPropertiesAtClient(Notification, Personal, NoFilter, ThumbprintsOnly = False, ShowError = Undefined) Export
	
	Result = New Structure;
	Result.Insert("ErrorOnGetCertificatesAtClient", New Structure);
	Result.Insert("CertificatesPropertiesAtClient", ?(ThumbprintsOnly, New Map, New Array));
	
	Context = New Structure;
	Context.Insert("Notification",      Notification);
	Context.Insert("Personal",          Personal);
	Context.Insert("NoFilter",       NoFilter);
	Context.Insert("ThumbprintsOnly", ThumbprintsOnly);
	Context.Insert("Result",       Result);
	Context.Insert("CertificatesArray", New Array);
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ShowError = ShowError;
	
	CreateCryptoManager(New CallbackDescription(
			"GetCertificatesPropertiesAtClientAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", CreationParameters);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		Context.Result.ErrorOnGetCertificatesAtClient = CryptoManager;
		GetCertificatesPropertiesAtClientAfterGetAll(Context);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	
	Context.CryptoManager.BeginGettingCertificateStore(
		New CallbackDescription(
			"GetCertificatesPropertiesAtClientAfterGetPersonalStorage", ThisObject, Context),
		CryptoCertificateStoreType.PersonalCertificates);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetPersonalStorage(Storage, Context) Export
	
	Storage.BeginGettingAll(New CallbackDescription(
		"GetCertificatesPropertiesAtClientAfterGetAllPersonalCertificates", ThisObject, Context));
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetAllPersonalCertificates(Array, Context) Export
	
	Context.Insert("CertificatesArray", Array);
	
	If Context.Personal Then
		GetCertificatesPropertiesAtClientAfterGetAll(Context);
		Return;
	EndIf;
	
	Context.CryptoManager.BeginGettingCertificateStore(
		New CallbackDescription(
			"GetCertificatesPropertiesAtClientAfterGetRecipientsStorage", ThisObject, Context),
		CryptoCertificateStoreType.RecipientCertificates);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetRecipientsStorage(Storage, Context) Export
	
	Storage.BeginGettingAll(New CallbackDescription(
		"GetCertificatesPropertiesAtClientAfterGetAllRecipientsCertificates", ThisObject, Context));
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
//
// Parameters:
//   Context - Structure:
//     * CertificatesArray - Array
//
Procedure GetCertificatesPropertiesAtClientAfterGetAllRecipientsCertificates(Array, Context) Export
	
	For Each Certificate In Array Do
		Context.CertificatesArray.Add(Certificate);
	EndDo;
	
	GetCertificatesPropertiesAtClientAfterGetAll(Context);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetAll(Context)
	
	Notification = New CallbackDescription("AfterGettingCertificatePropertiesOnTokens", ThisObject, Context);
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnGettingTokens(Notification, True, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	GetCertificatesPropertiesAtClientReturnResult(Context);

EndProcedure

Async Procedure AfterGettingCertificatePropertiesOnTokens(Tokens, Context) Export
	
	Context.CertificatesArray = Await DigitalSignatureClientLocalization.AddCertificatesFromTokenToArray(Tokens, Context.CertificatesArray);
	GetCertificatesPropertiesAtClientReturnResult(Context);
	
EndProcedure

Procedure GetCertificatesPropertiesAtClientReturnResult(Context)
	
	If Context.CertificatesArray.Count() = 0 Then
		RunCallback(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	PropertiesAddingOptions = New Structure("ThumbprintsOnly", Context.ThumbprintsOnly);
	DigitalSignatureInternalClientServer.AddCertificatesProperties(
		Context.Result.CertificatesPropertiesAtClient,
		Context.CertificatesArray,
		Context.NoFilter,
		UTCOffset(),
		CommonClient.SessionDate(),
		PropertiesAddingOptions);
	RunCallback(Context.Notification, Context.Result);
	
EndProcedure

// For internal purpose only.
Async Procedure AddCertificateForSigningOrDecryptionFromFile(CreationParameters, RepeatedCall = False)
	
	If Not RepeatedCall Then
		NotificationWhenDigitalSignatureAddInsMissing = New CallbackDescription(
			"ReAddCertificateForSigningOrDecryptionFromFileAfterAddInsInstalled", ThisObject, CreationParameters);
		IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(
			NotificationWhenDigitalSignatureAddInsMissing);
		If IsInstallingAddIns Then
			Return;
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("AddCertificateForSigningOrDecryptionFromFileAfterPutFiles",
		ThisObject, CreationParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp chứng thư (chỉ để mã hóa)';
										|ru = 'Выберите файл сертификата (только для шифрования)';
										|en = 'Select a certificate file (only for encryption)'; fa = 'Select a certificate file (only for encryption)';
										|it = 'Selezionare il file del certificato (solamente per la crittografia)';
										|pl = 'Wybierz plik certyfikatu (tylko dla szyfrowania)';
										|tr = 'Sertifika dosyasını seçin (sadece şifreleme için)'");
	ImportParameters.Dialog.Filter = NStr("vi = 'Chứng thư X.509 (*.cer;*.crt)|*.cer;*.crt';
											|ru = 'Сертификат X.509 (*.cer;*.crt)|*.cer;*.crt';
											|en = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt'; fa = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt';
											|it = 'Сертификат X.509 (*.cer;*.crt)|*.cer;*.crt';
											|pl = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt';
											|tr = 'X.509 sertifikası (*.cer;*.crt)|*.cer;*.crt'")+ "|"
		+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																		|ru = 'Все файлы (%1)|%1';
																		|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																		|it = 'Все файлы (%1)|%1';
																		|pl = 'All files (%1)|%1';
																		|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	FileSystemClient.ImportFile_(Notification, ImportParameters);
	
EndProcedure

// Follow-up call to "AddCertificateForSigningOrDecryptionFromFile" after the add-ins have been installed.
Procedure ReAddCertificateForSigningOrDecryptionFromFileAfterAddInsInstalled(Result, CreationParameters) Export
	
	If Result = True Then
		AddCertificateForSigningOrDecryptionFromFile(CreationParameters, True);
	EndIf;
	
EndProcedure

// Continuation of the "AddCertificateForSigningOrDecryptionFromFile" procedure.
Procedure AddCertificateForSigningOrDecryptionFromFileAfterPutFiles(PlacedFiles, Context) Export
	
	If Not ValueIsFilled(PlacedFiles) Then
		Return;
	EndIf;
	
	CertificateAddress = PlacedFiles.Location;
	
	CertificateData = GetFromTempStorage(CertificateAddress);
	ThisIsCertificate = DigitalSignatureInternalServerCall.FileIsCertificate(CertificateData);
	If Not ThisIsCertificate Then
		ShowMessageBox(, NStr("vi = 'Tệp chứng thư cần có định dạng DER X.509.';
								|ru = 'Файл сертификата должен быть в формате DER X.509.';
								|en = 'Certificate file must have DER X.509 format.'; fa = 'Certificate file must have DER X.509 format.';
								|it = 'Файл сертификата должен быть в формате DER X.509.';
								|pl = 'Certificate file must have DER X.509 format.';
								|tr = 'Файл сертификата должен быть в формате DER X.509.'"));
		Return;
	EndIf;
	
	AddCertificateForSigningOrDecryptionFromFileAfterPutFile(CertificateAddress, Context);
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Async Procedure AddCertificateForSigningOrDecryptionFromFileAfterPutFile(Address, Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificateDataAddress", Address);
	FormParameters.Insert("PersonalListOnAdd", Context.ToPersonalList);
	FormParameters.Insert("Organization",               Context.Organization);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CertificateAddress", Address);
	
	CompletionHandler = ?(Context.Property("CompletionHandler"), Context.CompletionHandler, Undefined);
	
	CertificateInstallationParameters = CertificateInstallationParameters(Address);
	CertificateInstallationParameters.CallbackOnCompletion = ?(CompletionHandler = Undefined,
		New CallbackDescription("AfterAddCertificateFromFiles", ThisObject, NotificationParameters),
		Context.CompletionHandler);
		
	Containers = Await ContainersByCertificate(Address);
	
	If Containers = Undefined Then
		Return;
	ElsIf Containers.Count() = 0 Then
		FormParameters = DigitalSignatureClient.ExtendedErrorPresentationFormParameters();
		FormParameters.WarningTitle = NStr("vi = 'Không thể cài đặt chứng thư';
											|ru = 'Не удалось установить сертификат';
											|en = 'Couldn''t install the certificate'; fa = 'Couldn''t install the certificate';
											|it = 'Не удалось установить сертификат';
											|pl = 'Couldn''t install the certificate';
											|tr = 'Sertifika kurulamadı'");
		FormParameters.ErrorTextClient = NStr("vi = 'Chưa tìm thấy nơi chứa khóa chữ ký điện tử.';
												|ru = 'Не найден контейнер ключа электронной подписи.';
												|en = 'Digital signature key container not found.'; fa = 'Digital signature key container not found.';
												|it = 'Digital signature key container not found.';
												|pl = 'Digital signature key container not found.';
												|tr = 'Dijital imza anahtarı konteyneri bulunamadı.'");
		FormParameters.AdditionalData.Insert("Certificate", Address);
		OpenExtendedErrorPresentationForm(FormParameters, , CertificateInstallationParameters.CallbackOnCompletion);
	Else
		CertificateInstallationParameters.Storage = New Structure("Value, Presentation", "MY", NStr("vi = 'Kho chứa riêng chứng thư';
																									|ru = 'Личное хранилище сертификатов';
																									|en = 'Personal certificate store'; fa = 'Personal certificate store';
																									|it = 'Личное хранилище сертификатов';
																									|pl = 'Personal certificate store';
																									|tr = 'Güvenilir kök sertifikaları'"));
		CertificateInstallationParameters.ContainerProperties = Containers[0];
		InstallCertificateAfterInstallationOptionSelected(CertificateInstallationParameters);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AfterAddCertificateFromFiles(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificateAddress", Result.Certificate);
	SelectSigningOrDecryptionCertificate(FormParameters, ThisObject);
	
EndProcedure

// For internal purpose only.
Async Procedure AddCertificateOnlyToEncryptFromFile(CreationParameters, MultipleChoice = False, RepeatedCall = False) Export
	
	If Not RepeatedCall Then
		RetryCallParameters = New Structure("CreationParameters, MultipleChoice",
			CreationParameters, MultipleChoice);
		NotificationWhenDigitalSignatureAddInsMissing = New CallbackDescription(
			"ReAddEncryptionOnlyCertificateFromFileAfterAddInstInstalled", ThisObject, RetryCallParameters);
		IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(
			NotificationWhenDigitalSignatureAddInsMissing);
		If IsInstallingAddIns Then
			Return;
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("AddCertificateOnlyToEncryptFromFileAfterPutFiles",
		ThisObject, CreationParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp chứng chỉ (chỉ để mã hóa)';
										|ru = 'Выберите файл сертификата (только для шифрования)';
										|en = 'Select a certificate file (only for encryption)'; fa = 'Select a certificate file (only for encryption)';
										|it = 'Selezionare il file del certificato (solamente per la crittografia)';
										|pl = 'Wybierz plik certyfikatu (tylko dla szyfrowania)';
										|tr = 'Sertifika dosyasını seçin (sadece şifreleme için)'");
	ImportParameters.Dialog.Filter = NStr("vi = 'Chứng thư X.509 (*.cer;*.crt)|*.cer;*.crt ';
											|ru = 'Сертификат X.509 (*.cer;*.crt)|*.cer;*.crt';
											|en = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt'; fa = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt';
											|it = 'Сертификат X.509 (*.cer;*.crt)|*.cer;*.crt';
											|pl = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt';
											|tr = 'X.509 sertifikası (*.cer;*.crt)|*.cer;*.crt'")+ "|"
		+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																		|ru = 'Все файлы (%1)|%1';
																		|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																		|it = 'Все файлы (%1)|%1';
																		|pl = 'All files (%1)|%1';
																		|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	If MultipleChoice Then
		ImportParameters.Dialog.Multiselect = MultipleChoice;
		FileSystemClient.ImportFiles(Notification, ImportParameters);
	Else
		FileSystemClient.ImportFile_(Notification, ImportParameters);
	EndIf;
	
EndProcedure

// Follow-up call to "AddCertificateOnlyToEncryptFromFile" after the add-ins have been installed.
Procedure ReAddEncryptionOnlyCertificateFromFileAfterAddInstInstalled(Result, RetryCallParameters) Export
	
	If Result = True Then
		AddCertificateOnlyToEncryptFromFile(
			RetryCallParameters.CreationParameters, RetryCallParameters.MultipleChoice, True);
	EndIf;
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificateOnlyToEncryptFromFileAfterPutFiles(PlacedFiles, Context) Export
	
	If Not ValueIsFilled(PlacedFiles) Then
		Return;
	EndIf;
	
	If TypeOf(PlacedFiles) = Type("Array") Then
		
		If PlacedFiles.Count() = 1 Then
			AddCertificateOnlyToEncryptFromFileAfterPutFile(PlacedFiles[0].Location, Context);
			Return;
		EndIf;
		
		AddCertificatesOnlyToEncryptFromFileAfterPutFiles(PlacedFiles, Context);
		Return;
		
	EndIf;
	
	AddCertificateOnlyToEncryptFromFileAfterPutFile(PlacedFiles.Location, Context);
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificateOnlyToEncryptFromFileAfterPutFile(Address, Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificateDataAddress", Address);
	FormParameters.Insert("PersonalListOnAdd", Context.ToPersonalList);
	FormParameters.Insert("Organization",               Context.Organization);
	
	CompletionHandler = ?(Context.Property("CompletionHandler"), Context.CompletionHandler, Undefined);
	Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddEncryptionCertificate",
		FormParameters, , , , , CompletionHandler);
	
	If Form = Undefined Then
		ShowMessageBox(,
			NStr("vi = 'Tệp chứng thư cần có định dạng DER X.509.';
				|ru = 'Файл сертификата должен быть в формате DER X.509.';
				|en = 'Certificate file must have DER X.509 format.'; fa = 'Certificate file must have DER X.509 format.';
				|it = 'Файл сертификата должен быть в формате DER X.509.';
				|pl = 'Certificate file must have DER X.509 format.';
				|tr = 'Файл сертификата должен быть в формате DER X.509.'"));
		Return;
	EndIf;
	
	If Not Form.IsOpen() Then
		If IsBlankString(Form.WarningTextOnOpen) Then
			Buttons = New ValueList;
			Buttons.Add("Open", NStr("vi = 'Mở';
									|ru = 'Открыть';
									|en = 'Open'; fa = 'باز';
									|it = 'Aprire';
									|pl = 'Otwórz';
									|tr = 'Aç'"));
			Buttons.Add("Cancel",  NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Anuluj';
										|tr = 'İptal'"));
			ShowQueryBox(
				New CallbackDescription("AddCertificateOnlyToEncryptFromFileAfterNotifyOfExisting",
					ThisObject, Form.ThumbprintOfCertificate),
				NStr("vi = 'Đã thêm chứng thư.';
					|ru = 'Сертификат уже добавлен.';
					|en = 'Certificate is already added.'; fa = 'Certificate is already added.';
					|it = 'Certificato già aggiunto.';
					|pl = 'Certyfikat został już dodany.';
					|tr = 'Sertifika zaten eklendi.'"), Buttons);
		Else
			ShowMessageBox(, Form.WarningTextOnOpen);
		EndIf;
	EndIf;
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificatesOnlyToEncryptFromFileAfterPutFiles(PlacedFiles, Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("PlacedFiles", PlacedFiles);
	FormParameters.Insert("Organization",     Context.Organization);
	
	CompletionHandler = ?(Context.Property("CompletionHandler"), Context.CompletionHandler, Undefined);
	Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddCertificatesForEncryption",
		FormParameters, , , , , CompletionHandler);
	
	If Form = Undefined Then
		ShowMessageBox(, NStr("vi = 'Trong thư mục được chọn, không có chứng thư để thêm.';
								|ru = 'В выбранном каталоге отсутствуют сертификаты для добавления.';
								|en = 'The directory contains no certificates that can be exported.'; fa = 'The directory contains no certificates that can be exported.';
								|it = 'В выбранном каталоге отсутствуют сертификаты для добавления.';
								|pl = 'The directory contains no certificates that can be exported.';
								|tr = 'В выбранном каталоге отсутствуют сертификаты для добавления.'"));
		Return;
	EndIf;
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificateOnlyToEncryptFromFileAfterNotifyOfExisting(Response, Certificate) Export
	
	If Response <> "Open" Then
		Return;
	EndIf;
	
	OpenCertificate(Certificate);
	
EndProcedure

// For internal purpose only.
Async Procedure AddCertificateOnlyToEncryptFromDirectory(CreationParameters)
	
	Notification = New CallbackDescription("AddCertificateOnlyToEncryptFromDirectoryAfterAttachExtension",
		ThisObject, CreationParameters);
		
	IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(Notification);
	If IsInstallingAddIns Then
		Return;
	EndIf;
	
	SuggestionText =  NStr("vi = 'Để kết nhập các chứng thư từ thư mục, cần thiết lập phần mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для загрузки сертификатов из каталога требуется установить расширение для работы с 1С:Предприятием.';
							|en = 'To import certificates from the directory, install 1C:Enterprise Extension.'; fa = 'To import certificates from the directory, install 1C:Enterprise Extension.';
							|it = 'Для загрузки сертификатов из каталога требуется установить расширение для работы с 1С:Предприятием.';
							|pl = 'To import certificates from the directory, install 1C:Enterprise Extension.';
							|tr = 'Dizinden sertifikanın yüklenmesi için 1C:Enterprise uzantısının yapılandırılması gerekmektedir.'");
	FileSystemClient.Attach1CEnterpriseExtension(Notification, SuggestionText, False);
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromDirectory procedure.
Procedure AddCertificateOnlyToEncryptFromDirectoryAfterAttachExtension(Result, CreationParameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
		
	Notification = New CallbackDescription("AddCertificateOnlyToEncryptFromFileAfterSelectDirectory",
		ThisObject, CreationParameters);
	
	Title = NStr("vi = 'Hãy chọn thư mục tệp chứng thư (chỉ để mã hóa)';
				|ru = 'Выберите каталог файлов сертификатов (только для шифрования)';
				|en = 'Select a certificate file directory (for encryption only)'; fa = 'Select a certificate file directory (for encryption only)';
				|it = 'Выберите каталог файлов сертификатов (только для шифрования)';
				|pl = 'Select a certificate file directory (for encryption only)';
				|tr = 'Sertifika dosyası kataloğunu seçin (sadece şifreleme için)'");
	
	FileSystemClient.SelectDirectory(Notification, Title);
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromDirectory procedure.
Async Procedure AddCertificateOnlyToEncryptFromFileAfterSelectDirectory(SelectedDirectory, Context) Export
	
	If Not ValueIsFilled(SelectedDirectory) Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AddCertificateOnlyToEncryptFromFileAfterPutFiles",
		ThisObject, Context);
	
	DetailsOfFilesToTransfer = New Array;
	
	Files = Await FindFilesAsync(SelectedDirectory,"*.*", True);

	For Each CurrentFile In Files Do
		If Await CurrentFile.IsDirectoryAsync() Then
			Continue;
		EndIf;
		TransferableFileDescription = New TransferableFileDescription(CurrentFile.FullName);
		DetailsOfFilesToTransfer.Add(TransferableFileDescription);
	EndDo;
	
	If DetailsOfFilesToTransfer.Count() = 0 Then
		Raise NStr("vi = 'Thư mục chỉ định không chứa tệp.';
					|ru = 'Указанный каталог не содержит файлов.';
					|en = 'The specified directory does not contain files.'; fa = 'The specified directory does not contain files.';
					|it = 'Указанный каталог не содержит файлов.';
					|pl = 'The specified directory does not contain files.';
					|tr = 'Belirtilen katalog dosya içermiyor.'");
	EndIf;
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Interactively = False;
	FileSystemClient.ImportFiles(Notification, ImportParameters, DetailsOfFilesToTransfer);
		
EndProcedure

// Continues the ShowApplicationCallError procedure.
Async Procedure ShowApplicationCallErrorAfterAttachExtension(Attached, Context) Export
	
	Context.FormParameters.Insert("ExtensionAttached", Attached);
	
#If WebClient Then
	If Not Attached Then
		Components = NewCryptoManagementAddIns();
		Components.IsCryptographicExtensionInstalled = False;
		
		IsAdditionalAddInsInstallationRequired = Await IsAdditionalAddInsInstallationRequired(Components);
		
		If IsAdditionalAddInsInstallationRequired Then
			FormParameters = New Structure;
			FormParameters.Insert("Components", Components);
			FormParameters.Insert("RequiredAddInName", "CryptographicExtension");
			OpenForm("CommonForm.StartWorkWithDigitalSignature", FormParameters,
				, , , , Context.ContinuationHandler, FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
	EndIf;
#EndIf
	
	OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.Form.ApplicationCallError",
		Context.FormParameters,,,, , Context.ContinuationHandler);
	
EndProcedure

// For internal use only.
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote = Undefined) Export
	
	PassParametersForm().SetCertificatePassword(CertificateReference, Password, PasswordNote);
	
EndProcedure

// For internal use only.
Function CertificatePasswordIsSet(CertificateReference) Export
	
	Return PassParametersForm().CertificatePasswordIsSet(CertificateReference);
	
EndFunction

// For internal use only.
Procedure OpenNewForm(FormType, ClientParameters, ServerParameters1, CompletionProcessing) Export
	
	DataDetails = ClientParameters.DataDetails;
	
	ServerParameters1.Insert("NoConfirmation", False);
	
	If DataDetails.Property("NoConfirmation")
		And DataDetails.NoConfirmation
		And (ServerParameters1.Property("CertificatesFilter")
				And TypeOf(ServerParameters1.CertificatesFilter) = Type("Array")
				And ServerParameters1.CertificatesFilter.Count() = 1 
			Or ServerParameters1.Property("Signatory") And ValueIsFilled(ServerParameters1.Signatory)) Then
		ServerParameters1.Insert("NoConfirmation", True);
	EndIf;
	
	If ServerParameters1.Property("CertificatesSet")
	   And DataDetails.Property("NoConfirmation")
	   And DataDetails.NoConfirmation Then
		
		ServerParameters1.Insert("NoConfirmation", True);
	EndIf;
	
	SetDataPresentation(ClientParameters, ServerParameters1);
	
	Context = New Structure;
	Context.Insert("FormType",            FormType);
	Context.Insert("ClientParameters", ClientParameters);
	Context.Insert("ServerParameters1",  ServerParameters1);
	Context.Insert("CompletionProcessing", CompletionProcessing);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
	   And ServerParameters1.Property("ExecuteAtServer")
	   And ServerParameters1.ExecuteAtServer = True Or FormType = "SendForSigning" Then
		
		OpenNewFormCompletion(New Array, Context);
	Else
		GetCertificatesThumbprintsAtClient(New CallbackDescription(
			"OpenNewFormCompletion", ThisObject, Context), FormType = "DataDecryption");
	EndIf;
	
EndProcedure

// Continues the OpenNewForm procedure.
Procedure OpenNewFormCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	Context.ServerParameters1.Insert("CertificatesThumbprintsAtClient",
		CertificatesThumbprintsAtClient);
	
	PassParametersForm().OpenNewForm(
		Context.FormType,
		Context.ServerParameters1,
		Context.ClientParameters,
		Context.CompletionProcessing);
	
EndProcedure

// For internal use only.
Procedure OpenNotificationFormNeedReplaceCertificate(Parameters) Export
	
	OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.CertificateAboutToExpireNotification",
			Parameters,,,,,,FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

// For internal use only.
Procedure RefreshFormBeforeSecondUse(Form, ClientParameters) Export
	
	ServerParameters1  = New Structure;
	SetDataPresentation(ClientParameters, ServerParameters1);
	
	Form.DataPresentation  = ServerParameters1.DataPresentation;
	
EndProcedure

// For internal use only.
Procedure SetDataPresentation(ClientParameters, ServerParameters1) Export
	
	DataDetails = ClientParameters.DataDetails;
	
	If DataDetails.Property("PresentationsList") Then
		PresentationsList = DataDetails.PresentationsList;
	Else
		PresentationsList = New Array;
		
		If DataDetails.Property("Data")
		 Or DataDetails.Property("Object") Then
			
			FillPresentationsList(PresentationsList, DataDetails);
		Else
			For Each DataElement In DataDetails.DataSet Do
				FillPresentationsList(PresentationsList, DataElement);
			EndDo;
		EndIf;
	EndIf;
	
	CurrentPresentationsList = New ValueList;
	
	For Each ListItem In PresentationsList Do
		If TypeOf(ListItem) = Type("String") Then
			Presentation = ListItem;
			Value = Undefined;
		ElsIf TypeOf(ListItem) = Type("Structure") Then
			Presentation = ListItem.Presentation;
			Value = ListItem.Value;
		Else // Reference
			Presentation = String(ListItem.Value);
			Value = ListItem.Value;
		EndIf;
		
		CurrentPresentationsList.Add(Value, Presentation);
	EndDo;
	
	If CurrentPresentationsList.Count() > 1 Then
		ServerParameters1.Insert("DataPresentationCanOpen", True);
		ServerParameters1.Insert("DataPresentation", StrReplace(
			DataDetails.SetPresentation, "%1", DataDetails.DataSet.Count()));
	Else
		ServerParameters1.Insert("DataPresentationCanOpen",
			TypeOf(CurrentPresentationsList[0].Value) = Type("CallbackDescription")
			Or ValueIsFilled(CurrentPresentationsList[0].Value));
		
		ServerParameters1.Insert("DataPresentation",
			CurrentPresentationsList[0].Presentation);
	EndIf;
	
	ClientParameters.Insert("CurrentPresentationsList", CurrentPresentationsList);
	
EndProcedure

// For internal use only.
Procedure StartChooseCertificateAtSetFilter(Form) Export
	
	AvailableCertificates = "";
	UnavailableCertificates = "";
	
	Text = NStr("vi = 'Đã hạn chế các chứng chỉ có thể được sử dụng đối với giao dịch này.';
				|ru = 'Сертификаты, которые могут быть использованы для этой операции ограничены.';
				|en = 'Certificates that can be used for this operation are limited.'; fa = 'Certificates that can be used for this operation are limited.';
				|it = 'L''accesso ai certificati che possono essere utilizzati per questa operazione è limitato.';
				|pl = 'Certyfikaty, których można używać w tej operacji, są ograniczone.';
				|tr = 'Bu işlem için kullanılabilecek sertifikalar kısıtlı.'");
	
	For Each ListItem In Form.CertificatesFilter Do
		If Form.CertificatePicklist.FindByValue(ListItem.Value) = Undefined Then
			UnavailableCertificates = UnavailableCertificates + Chars.LF + String(ListItem.Value);
		Else
			AvailableCertificates = AvailableCertificates + Chars.LF + String(ListItem.Value);
		EndIf;
	EndDo;
	
	If ValueIsFilled(AvailableCertificates) Then
		Title = NStr("vi = 'Các chứng chỉ được phép chọn sau đây:';
					|ru = 'Следующие разрешенные сертификаты доступны для выбора:';
					|en = 'The following trusted certificates are available for selection:'; fa = 'The following trusted certificates are available for selection:';
					|it = 'I seguenti certificati sono disponibili per la selezione:';
					|pl = 'Dostępne są następujące dozwolone certyfikaty:';
					|tr = 'Aşağıdaki onaylı sertifikalar seçilebilir:'");
		Text = Text + Chars.LF + Chars.LF + Title + Chars.LF + TrimAll(AvailableCertificates);
	EndIf;
	
	If ValueIsFilled(UnavailableCertificates) Then
		If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
			If ValueIsFilled(AvailableCertificates) Then
				Title = NStr("vi = 'Chưa cài đặt chứng chỉ được phép sau đây trên máy tính hoặc máy chủ:';
							|ru = 'Следующие разрешенные сертификаты не установлены ни на компьютере, ни на сервере:';
							|en = 'The following trusted certificates are not installed either on the computer, or on the server:'; fa = 'The following trusted certificates are not installed either on the computer, or on the server:';
							|it = 'I seguenti certificati consentiti non sono installati né sul computer né sul server:';
							|pl = 'Nie zainstalowano dozwolonych certyfikatów ani na komputerze, ani na serwerze:';
							|tr = 'Aşağıdaki onaylı sertifikalar bilgisayarda ve sunucuda yüklü değil:'");
			Else
				Title = NStr("vi = 'Chưa cài đặt chứng chỉ nào được phép sau đây trên máy tính hoặc máy chủ:';
							|ru = 'Ни один из следующих разрешенных сертификатов не установлен ни на компьютере, ни на сервере:';
							|en = 'None of the following trusted certificates is installed either on the computer, or on the server:'; fa = 'None of the following trusted certificates is installed either on the computer, or on the server:';
							|it = 'Nessuno dei seguenti certificati consentiti è installato né sul computer né sul server:';
							|pl = 'Żaden z następujących dozwolonych certyfikatów nie jest zainstalowany ani na komputerze, ani na serwerze:';
							|tr = 'Aşağıdaki onaylı sertifikalar dan hiçbiri bilgisayarda ve sunucuda yüklü değil:'");
			EndIf;
		Else
			If ValueIsFilled(AvailableCertificates) Then
				Title = NStr("vi = 'Chưa cài đặt chứng chỉ được phép nào trên máy tính:';
							|ru = 'Следующие разрешенные сертификаты не установлены на компьютере:';
							|en = 'The following trusted certificates are not installed on the computer: '; fa = 'The following trusted certificates are not installed on the computer: ';
							|it = 'I seguenti certificati consentiti non sono installati sul computer:';
							|pl = 'Następujące dozwolone certyfikaty nie są zainstalowane na komputerze:';
							|tr = 'Aşağıdaki onaylı sertifikalar bilgisayarda yüklü değil:'");
			Else
				Title = NStr("vi = 'Chưa ccài đặt chứng chỉ được phép nào sau đây trên máy tính:';
							|ru = 'Ни один из следующих разрешенных сертификатов не установлен на компьютере:';
							|en = 'None of the following trusted certificates is installed on the computer:'; fa = 'None of the following trusted certificates is installed on the computer:';
							|it = 'Nessuno dei seguenti certificati consentiti è stato trovato sul computer:';
							|pl = 'Żaden z następujących dozwolonych certyfikatów nie jest zainstalowany na komputerze:';
							|tr = 'Aşağıdaki onaylı sertifikalardan hiçbiri bilgisayarda yüklü değil:'");
			EndIf;
		EndIf;
		Text = Text + Chars.LF + Chars.LF + Title + Chars.LF + TrimAll(UnavailableCertificates);
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

// Continues the SelectSigningOrDecryptionCertificate procedure.
Procedure SelectSigningOrDecryptionCertificateContinued(Result, Context) Export
	
	Context.ServerParameters1.Insert("CertificatesPropertiesAtClient",
		Result.CertificatesPropertiesAtClient);
	
	Context.ServerParameters1.Insert("ErrorOnGetCertificatesAtClient",
		Result.ErrorOnGetCertificatesAtClient);
	
	PassParametersForm().OpenNewForm("SelectSigningOrDecryptionCertificate",
		Context.ServerParameters1, , Context.CompletionHandler, Context.NewFormOwner);
	
EndProcedure

// For internal use only.
Procedure CheckCatalogCertificate(Certificate, AdditionalParameters) Export
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("FormCaption");
	ServerParameters1.Insert("CheckOnSelection");
	ServerParameters1.Insert("AdditionalChecksParameters");
	ServerParameters1.Insert("SignatureType");
	ServerParameters1.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.VerifyQualified());
	ServerParameters1.Insert("IgnoreCertificateRevocationStatus", False);
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		SpecifiedContextOfOtherOperation = False;
		If AdditionalParameters.Property("OperationContext")
			And TypeOf(AdditionalParameters.OperationContext) = Type("ClientApplicationForm") Then
			
			If Not AdditionalParameters.Property("NoConfirmation") Then
				AdditionalParameters.Insert("NoConfirmation");
			EndIf;
			
			FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
			
			If AdditionalParameters.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
				AdditionalParameters.Insert("SignatureType", AdditionalParameters.OperationContext.SignatureType);
				AdditionalParameters.Insert("PerformCAVerification", AdditionalParameters.OperationContext.VerifyCertificate);
			EndIf;
			
			SpecifiedContextOfOtherOperation = True;
			AdditionalParameters.NoConfirmation = True;
			
		ElsIf AdditionalParameters.Property("DontShowResults") Then
			AdditionalParameters.DontShowResults = False;
		EndIf;
		
		ClientParameters = AdditionalParameters;
		If SpecifiedContextOfOtherOperation Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
		
		FillPropertyValues(ServerParameters1, AdditionalParameters);
		
	Else
		ClientParameters = New Structure;
	EndIf;
	
	ServerParameters1.Insert("Certificate", Certificate);
	
	FormOwner = Undefined;
	ClientParameters.Property("FormOwner", FormOwner);
	
	CompletionProcessing = Undefined;
	ClientParameters.Property("CompletionProcessing", CompletionProcessing);
	
	PassParametersForm().OpenNewForm("CertificateCheck",
		ServerParameters1, ClientParameters, CompletionProcessing, FormOwner);
	
EndProcedure

// For internal use only.
Procedure RegularlyCompletion(Success, ClientParameters) Export
	
	ClientParameters.DataDetails.Insert("Success", Success = True);
	ClientParameters.DataDetails.Insert("Cancel", Success = Undefined);
	
	If ClientParameters.ResultProcessing <> Undefined Then
		
		ResultProcessing = ClientParameters.ResultProcessing;
		ClientParameters.ResultProcessing = Undefined;
		RunCallback(ResultProcessing, ClientParameters.DataDetails);
		
	EndIf;
	
EndProcedure

// Continues the DigitalSignatureClient.AddSignatureFromFile procedure.
Procedure AddSignatureFromFileAfterCreateCryptoManager(Result, Context) Export
	
	If Context.CheckCryptoManagerAtClient
	   And TypeOf(Result) <> Type("CryptoManager") Then
		
		ShowApplicationCallError(
			NStr("vi = 'Cần có ứng dụng chữ ký điện tử và mã hóa';
				|ru = 'Требуется приложение электронной подписи и шифрования';
				|en = 'A digital signing and encryption app is required'; fa = 'A digital signing and encryption app is required';
				|it = 'Требуется приложение электронной подписи и шифрования';
				|pl = 'A digital signing and encryption app is required';
				|tr = 'Dijital imza ve şifreleme uygulaması gerekli'"),
			"", Result, Context.AdditionForm.CryptographyManagerOnServerErrorDescription);
	Else
		Context.AdditionForm.Open();
		If Context.AdditionForm.IsOpen() Then
			Return;
		EndIf;
	EndIf;
	
	If Context.ResultProcessing <> Undefined Then
		RunCallback(Context.ResultProcessing, Context.DataDetails);
	EndIf;
	
EndProcedure

// It prompts the user to select signatures to save together with the object data.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it.
//  This structure always has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during the asynchronous
//  execution, add the ErrorDetails property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * DataTitle     - String - a data item title, for example, File.
//    * ShowComment - Boolean - (optional) - allows adding a comment in the
//                              data signing form. False if not specified.
//    * Presentation      - AnyRef
//                         - String - (optional), if it is not specified,
//                                the presentation is calculated by the Object property value.
//    * Object             - AnyRef - a reference to object with the DigitalSIgnatures tabular section,
//                              from which you need to get the signatures list.
//                         - String - a temporary storage address of a signature array with properties,
//                              as the AddSignatureFromFile procedure returns.
//    * Data             - CallbackDescription - Handler for saving data and receiving the full filename with the path
//                              returned in the FullFileName property of the String type for saving digital signatures
//                              (see the common approach above).
//                              If 1C:Enterprise Extension is not attached, return
//                              the file name without a path.
//                              If the property will not be inserted or filled, it means canceling
//                              the continuation, and ResultProcessing with the False result will be called.
//
//                              For a batch request for permissions from the web client user to save the file of data
//                              and signatures, you need to insert the PermissionsProcessingRequest parameter of the NotifyDescription type.
//                              The procedure will get a Structure:
//                                # Calls - Array - Contains the details of calls to save signatures.
//                                # ContinuationHandler - NotifyDescription - Procedure to be executed
//                                                         after requesting permissions, the procedure parameters are the same as
//                                                         the notification for the BeginRequestingUserPermission method has.
//                                                         If the permission is not received, everything is canceled.
//
//  ResultProcessing - CallbackDescription - the parameter to be passed to the result:
//    Boolean - True if everything was successful.
//
Procedure SaveDataWithSignature(DataDetails, ResultProcessing = Undefined) Export
	
	Context = New Structure;
	Context.Insert("DataDetails", DataDetails);
	Context.Insert("ResultProcessing", ResultProcessing);
	
	PersonalSettings = DigitalSignatureClient.PersonalSettings();
	SaveAllSignatures = PersonalSettings.ActionsOnSavingWithDS = "SaveAllSignatures";
	SaveCertificateWithSignature = PersonalSettings.SaveCertificateWithSignature;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("DataTitle",     NStr("vi = 'Dữ liệu';
													|ru = 'Данные';
													|en = 'Data'; fa = 'داده';
													|it = 'Dati';
													|pl = 'Data';
													|tr = 'Veriler'"));
	ServerParameters1.Insert("ShowComment", False);
	FillPropertyValues(ServerParameters1, DataDetails);
	
	Context.Insert("SaveCertificateWithSignature", SaveCertificateWithSignature);
	
	ServerParameters1.Insert("SaveAllSignatures", SaveAllSignatures);
	ServerParameters1.Insert("Object", DataDetails.Object);
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	SetDataPresentation(ClientParameters, ServerParameters1);
	
	SaveForm = OpenForm("CommonForm.SaveWithDigitalSignature", ServerParameters1,,,,,
		New CallbackDescription("SaveDataWithSignatureAfterSignaturesChoice", ThisObject, Context));
	
	ExitApp = False;
	Context.Insert("Form", SaveForm);
	
	If SaveForm = Undefined Then
		ExitApp = True;
	Else
		SaveForm.ClientParameters = ClientParameters;
		
		If SaveAllSignatures Then
			SaveDataWithSignatureAfterSignaturesChoice(SaveForm.SignatureTable, Context);
			Return;
			
		ElsIf Not SaveForm.IsOpen() Then
			ExitApp = True;
		EndIf;
	EndIf;
	
	If ExitApp And Context.ResultProcessing <> Undefined Then
		RunCallback(Context.ResultProcessing, False);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterSignaturesChoice(SignaturesCollection, Context) Export
	
	If TypeOf(SignaturesCollection) <> Type("FormDataCollection") Then
		If Context.ResultProcessing <> Undefined Then
			RunCallback(Context.ResultProcessing, False);
		EndIf;
		Return;
	EndIf;
	
	Context.Insert("SaveCertificateWithSignature",
		DigitalSignatureClient.PersonalSettings().SaveCertificateWithSignature);
		
	Context.Insert("SignaturesCollection", SignaturesCollection);
		
	MachineReadableLettersOfAuthority = New Array;
	DigitalSignatureClientLocalization.OnDefineMRLOAFiles(MachineReadableLettersOfAuthority,
		Context.SignaturesCollection);
	
	Context.Insert("MachineReadableLettersOfAuthority", MachineReadableLettersOfAuthority);
	Context.Insert("ExportedCertificates", New Map);

	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New CallbackDescription(
		"SaveDataWithSignatureAfterSaveFileData", ThisObject, Context));
	
	Try
		RunCallback(Context.DataDetails.Data, ExecutionParameters);
	Except
		ErrorInfo = ErrorInfo();
		SaveDataWithSignatureAfterSaveFileData(
			New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo)), Context);
	EndTry;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Async Procedure SaveDataWithSignatureAfterSaveFileData(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Error = New Structure("ErrorDescription",
			NStr("vi = 'Không thể ghi lại tệp do nguyên nhân:';
				|ru = 'Не удалось записать файл по причине:';
				|en = 'Cannot save the file due to:'; fa = 'Cannot save the file due to:';
				|it = 'Не удалось записать файл по причине:';
				|pl = 'Cannot save the file due to:';
				|tr = 'Dosya şu sebeple kaydedilemedi:'") + Chars.LF + Result.ErrorDescription);
		
		ShowApplicationCallError(
			NStr("vi = 'Không thể lưu chữ ký cùng với tệp';
				|ru = 'Не удалось сохранить подписи вместе с файлом';
				|en = 'Couldn''t save signatures with the file'; fa = 'Couldn''t save signatures with the file';
				|it = 'Non è stato possibile salvare la firma con il file';
				|pl = 'Nie udało się zapisać podpisów w pliku';
				|tr = 'İmzalar dosya ile birlikte kaydedilemedi'"), "", Error, New Structure);
		Return;
		
	ElsIf Not Result.Property("FullFileName")
		Or TypeOf(Result.FullFileName) <> Type("String")
		Or IsBlankString(Result.FullFileName) Then
		
		If Context.ResultProcessing <> Undefined Then
			RunCallback(Context.ResultProcessing, False);
		EndIf;
		Return;
	EndIf;
	
	If Result.Property("PremissionRequestProcessing") Then
		Context.Insert("PremissionRequestProcessing", Result.PremissionRequestProcessing);
	EndIf;
	
	Context.Insert("FullFileName", Result.FullFileName);
	Context.Insert("DataFileNameContent",
		CommonClientServer.ParseFullFileName(Context.FullFileName));
	
	Notification = New CallbackDescription(
		"SaveDataWithSignatureAfterAttachFileSystemExtention", ThisObject, Context);
	
	IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(Notification);
	If IsInstallingAddIns Then
		Return;
	EndIf;
	
	FileSystemClient.Attach1CEnterpriseExtension(Notification);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterAttachFileSystemExtention(Attached, Context) Export
	
	Context.Insert("Attached", Attached);
	
	Context.Insert("SignatureFilesExtension",
	DigitalSignatureClient.PersonalSettings().SignatureFilesExtension);
	
	If Context.Attached Then
		Context.Insert("FilesToObtain", New Array);
		If ValueIsFilled(Context.DataFileNameContent.Path) Then
			Context.Insert("FilesPath", CommonClientServer.AddLastPathSeparator(
				Context.DataFileNameContent.Path));
		Else
			Context.Insert("FilesPath", "");
		EndIf;
	EndIf;
	
	Context.Insert("FilesNames", New Map);
	Context.FilesNames.Insert(Context.DataFileNameContent.Name, True);

	Context.Insert("IndexOf", -1);

	SaveDataWithSignatureLoopStart(Context);

EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
// 
// Parameters:
//  Context - Structure:
//   * IndexOf - Number
//
Procedure SaveDataWithSignatureLoopStart(Context)
	
	If Context.SignaturesCollection.Count() <= Context.IndexOf + 1 Then
		SaveDataWithSignatureAfterLoop(Context);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("SignatureDescription", Context.SignaturesCollection[Context.IndexOf]);
	
	If Not Context.SignatureDescription.Check Then
		SaveDataWithSignatureLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("SignatureFileName", Context.SignatureDescription.SignatureFileName);
	
	If IsBlankString(Context.SignatureFileName) Then 
		Context.SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(Context.DataFileNameContent.BaseName,
			String(Context.SignatureDescription.CertificateOwner), Context.SignatureFilesExtension);
	Else
		If Not CommonClient.IsWindowsClient() And StrLen(Context.SignatureFileName) > 127 Then
			SignatureFileNameContent = CommonClientServer.ParseFullFileName(Context.SignatureFileName);
			Context.SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(
				SignatureFileNameContent.BaseName,"", SignatureFileNameContent.Extension, False);
		Else
			Context.SignatureFileName = CommonClientServer.ReplaceProhibitedCharsInFileName(Context.SignatureFileName);
		EndIf;
	EndIf;
	
	SignatureFileNameContent = CommonClientServer.ParseFullFileName(Context.SignatureFileName);
	Context.Insert("SignatureFileNameWithoutExtension", SignatureFileNameContent.BaseName);
	
	Context.Insert("Counter", 1);
	
	SaveDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopInternalLoopStart(Context)
	
	Context.Counter = Context.Counter + 1;
	
	If Context.Attached Then
		Context.Insert("SignatureFileFullName", Context.FilesPath + Context.SignatureFileName);
	Else
		Context.Insert("SignatureFileFullName", Context.SignatureFileName);
	EndIf;
	
	If Context.FilesNames[Context.SignatureFileName] <> Undefined Then
		SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence(True, Context);
		
	ElsIf Context.Attached Then
		File = New File(Context.SignatureFileFullName);
		File.BeginCheckingExistence(New CallbackDescription(
			"SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence", ThisObject, Context));
	Else
		SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence(False, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence(Exists, Context) Export
	
	If Not Exists Then
		SaveDataWithSignatureLoopAfterInternalLoop(Context);
		Return;
	EndIf;
	
	Context.SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(Context.SignatureFileNameWithoutExtension,
		"(" + String(Context.Counter) + ")", Context.SignatureFilesExtension, False);
	
	SaveDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
// 
// Parameters:
//  Context - Structure:
//   * FilesToObtain - Array
//
Procedure SaveDataWithSignatureLoopAfterInternalLoop(Context)
	
	SignatureFileNameContent = CommonClientServer.ParseFullFileName(Context.SignatureFileFullName);
	Context.FilesNames.Insert(SignatureFileNameContent.Name, False);
	
	If Context.Attached Then
		LongDesc = New TransferableFileDescription(SignatureFileNameContent.Name, Context.SignatureDescription.SignatureAddress);
		Context.FilesToObtain.Add(LongDesc);
		SaveDataWithSignatureLoopAfterSaveSignature(Undefined, Context);
	Else
		// Save the file from the app to the computer.
		FileSystemClient.SaveFile(
			New CallbackDescription("SaveDataWithSignatureLoopAfterSaveSignature", ThisObject, Context),
			Context.SignatureDescription.SignatureAddress, SignatureFileNameContent.Name);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopAfterSaveSignature(Result, Context) Export
	
	If Context.SaveCertificateWithSignature And Context.ExportedCertificates.Get(
		Context.SignatureDescription.Thumbprint) = Undefined Then
		Context.Insert("Counter", 1);
		SaveCertificateDataWithSignatureLoopStart(Context);
	Else
		SaveDataWithSignatureLoopStart(Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopInternalLoopStart(Context)
	
	If Context.Attached Then
		Context.Insert("CertificateFileFullName", Context.FilesPath + Context.CertificateFileName);
	Else
		Context.Insert("CertificateFileFullName", Context.CertificateFileName);
	EndIf;
	
	If Context.FilesNames[Context.CertificateFileName] <> Undefined Then
		SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence(True, Context);
		
	ElsIf Context.Attached Then
		File = New File(Context.CertificateFileFullName);
		File.BeginCheckingExistence(New CallbackDescription(
			"SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence", ThisObject, Context));
	Else
		SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence(False, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence(Exists, Context) Export
	
	If Not Exists Then
		SaveCertificateDataWithSignatureLoopAfterInternalLoop(Context);
		Return;
	EndIf;
	
	Context.CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(Context.CertificateFileNameWithoutExtension,
		"(" + String(Context.Counter) + ")", Context.SignatureDescription.CertificateExtension, False);
	
	Context.Counter = Context.Counter + 1;
	SaveCertificateDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopStart(Context)
	
	Context.Insert("CertificateFileName", "");
	
	Context.CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(Context.DataFileNameContent.BaseName,
		String(Context.SignatureDescription.CertificateOwner), Context.SignatureDescription.CertificateExtension);
	
	CertificateFileNameComposition  = CommonClientServer.ParseFullFileName(Context.CertificateFileName);
	Context.Insert("CertificateFileNameWithoutExtension", CertificateFileNameComposition.BaseName);
	
	SaveCertificateDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
// 
// Parameters:
//  Context - Structure:
//   * FilesToObtain - Array
//
Procedure SaveCertificateDataWithSignatureLoopAfterInternalLoop(Context)
	
	CertificateFileNameComposition = CommonClientServer.ParseFullFileName(Context.CertificateFileFullName);
	Context.FilesNames.Insert(CertificateFileNameComposition.Name, False);
	Context.ExportedCertificates.Insert(Context.SignatureDescription.Thumbprint, True);
	
	If Context.Attached Then
		LongDesc = New TransferableFileDescription(CertificateFileNameComposition.Name, Context.SignatureDescription.CertificateAddress);
		Context.FilesToObtain.Add(LongDesc);
		SaveDataWithSignatureLoopStart(Context);
	Else
		// Save the file from the app to the computer.
		FileSystemClient.SaveFile(
			New CallbackDescription("SaveCertificateDataWithSignatureLoopAfterSaveCertificate", ThisObject, Context),
			Context.SignatureDescription.CertificateAddress, CertificateFileNameComposition.Name);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopAfterSaveCertificate(Result, Context) Export
	
	SaveDataWithSignatureLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterLoop(Context)
	
	Context.Insert("LOAIndex", -1);
	SaveMRLOAsLoopStart(Context);
	
EndProcedure

// Follow-up of the "DigitalSignatureClient.SaveDataWithSignature" procedure.
Procedure SaveMRLOAsLoopStart(Context)
	
	If Context.MachineReadableLettersOfAuthority.Count() <= Context.LOAIndex + 1 Then
		SaveDataWithSignatureAfterMRLOAsSaveLoop(Context);
		Return;
	EndIf;
	
	Context.LOAIndex = Context.LOAIndex + 1;
	LOAToExport = Context.MachineReadableLettersOfAuthority[Context.LOAIndex];
	
	If Context.Attached Then
		LongDesc = New TransferableFileDescription(LOAToExport.Name, LOAToExport.Location);
		Context.FilesToObtain.Add(LongDesc);
		SaveMRLOAsLoopStart(Context);
	Else
		// Save the file from the app to the computer.
		FileSystemClient.SaveFile(
			New CallbackDescription("SaveDataWithSignatureAfterMRLOASaveLoop", ThisObject, Context),
			 LOAToExport.Location, LOAToExport.Name);
	EndIf;
	
EndProcedure

// Follow-up of the "DigitalSignatureClient.SaveDataWithSignature" procedure.
Procedure SaveDataWithSignatureAfterMRLOASaveLoop(Result, Context) Export
	
	SaveMRLOAsLoopStart(Context);
	
EndProcedure

// Follow-up of the "DigitalSignatureClient.SaveDataWithSignature" procedure.
Procedure SaveDataWithSignatureAfterMRLOAsSaveLoop(Context)
	
	If Not Context.Attached Then
		If Context.ResultProcessing <> Undefined Then
			RunCallback(Context.ResultProcessing, True);
		EndIf;
		Return;
	EndIf;

	// Save the file from the app to the computer.
	If Context.FilesToObtain.Count() > 0 Then
		Context.Insert("FilesToObtain", Context.FilesToObtain);
		
		Calls = New Array;
		Call = New Array;
		Call.Add("BeginGettingFiles");
		Call.Add(Context.FilesToObtain);
		Call.Add(Context.FilesPath);
		Call.Add(False);
		Calls.Add(Call);
		
		ContinuationHandler = New CallbackDescription(
			"SaveDataWithSignatureAfterGetExtensions", ThisObject, Context);
		
		If Context.Property("PremissionRequestProcessing") Then
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("Calls", Calls);
			ExecutionParameters.Insert("ContinuationHandler", ContinuationHandler);
			RunCallback(Context.PremissionRequestProcessing, ExecutionParameters);
		Else
			BeginRequestingUserPermission(ContinuationHandler, Calls);
		EndIf;
	Else
		SaveDataWithSignatureAfterGetExtensions(False, Context);
	EndIf;

EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterGetExtensions(PermissionsGranted, Context) Export
	
	If Not PermissionsGranted
	   And Context.FilesToObtain.Count() > 0
	   And Context.Property("PremissionRequestProcessing") Then
		
		// The data file was not got - the report is not required.
		If Context.ResultProcessing <> Undefined Then
			RunCallback(Context.ResultProcessing, False);
		EndIf;
		
	ElsIf PermissionsGranted Then
		
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Interactively = Not ValueIsFilled(Context.FilesPath);
		SavingParameters.Dialog.Directory = Context.FilesPath;
		FileSystemClient.SaveFiles(New CallbackDescription(
				"SaveDataWithSignatureAfterGetFiles", ThisObject, Context), 
			Context.FilesToObtain, SavingParameters);
	Else
		SaveDataWithSignatureAfterGetFiles(Undefined, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
//
// Parameters:
//   ObtainedFiles - Array of TransferableFileDescription
//
Procedure SaveDataWithSignatureAfterGetFiles(ObtainedFiles, Context) Export
	
	ReceivedFilesNames = New Map;
	ReceivedFilesNames.Insert(Context.DataFileNameContent.Name, True);
	
	If TypeOf(ObtainedFiles) = Type("Array") Then
		For Each ReceivedFile In ObtainedFiles Do
			SignatureFileNameContent = CommonClientServer.ParseFullFileName(ReceivedFile.FullName);
			ReceivedFilesNames.Insert(SignatureFileNameContent.Name, True);
			If Not ValueIsFilled(Context.FilesPath) Then
				Context.FilesPath = SignatureFileNameContent.Path;
			EndIf;
		EndDo;
	EndIf;
	
	Text = NStr("vi = 'Thư mục tệp:';
				|ru = 'Папка с файлами:';
				|en = 'Folder with files:'; fa = 'Folder with files:';
				|it = 'Cartella con i file:';
				|pl = 'Folder z plikami:';
				|tr = 'Dosya klasörü:'") + Chars.LF
		+ Context.FilesPath + Chars.LF + Chars.LF
		+ NStr("vi = 'Tệp:';
				|ru = 'Файлы:';
				|en = 'Files:'; fa = 'Files:';
				|it = 'File:';
				|pl = 'Pliki:';
				|tr = 'Dosyalar:'") + Chars.LF;
	
	For Each KeyAndValue In ReceivedFilesNames Do
		Text = Text + KeyAndValue.Key + Chars.LF;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Text", Text);
	If Not ValueIsFilled(Context.DataFileNameContent.Path) Then
		FormParameters.Insert("DirectoryWithFiles", Context.FilesPath);
	Else
		FormParameters.Insert("DirectoryWithFiles", Context.DataFileNameContent.Path);
	EndIf;
		
	OpenForm("CommonForm.ReportOnSavingFilesOfDigitalSignatures", FormParameters,,,,,
		New CallbackDescription("SaveDataWithSignatureAfterCloseReport", ThisObject, Context));
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterCloseReport(Result, Context) Export
	
	If Context.ResultProcessing <> Undefined Then
		RunCallback(Context.ResultProcessing, True);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OpenInstructionOfWorkWithApplications() Export
	
	Section = "BookkeepingAndTaxAccounting";
	DigitalSignatureClientOverridable.OnDetermineArticleSectionAtITS(Section);
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToAppsGuide(
		Section, URL);
	
	If Not IsBlankString(URL) Then
		FileSystemClient.OpenURL(URL);
	EndIf;
	
EndProcedure

// See DigitalSignatureClient.InstallExtension
Procedure InstallExtension(WithoutQuestion, HandlerResults_1 = Undefined, QueryText = "", QuestionTitle = "") Export
	
	Context = New Structure;
	Context.Insert("Notification",       HandlerResults_1);
	Context.Insert("QueryText",     QueryText);
	Context.Insert("QuestionTitle", QuestionTitle);
	Context.Insert("WithoutQuestion",       WithoutQuestion);
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"InstallExtensionAfterCheckCryptoExtensionAttachment", ThisObject, Context));
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterCheckCryptoExtensionAttachment(Attached, Context) Export
	
	If Attached Then
		RunCallback(Context.Notification, True);
		Return;
	EndIf;
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"InstallExtensionAfterAttachCryptoExtension", ThisObject, Context));
	
EndProcedure

// Continue the InstallExtension procedure.
Async Procedure InstallExtensionAfterAttachCryptoExtension(Attached, Context) Export
	
	If Attached Then
		If Context.Notification <> Undefined Then
			RunCallback(Context.Notification, True);
		EndIf;
		Return;
	EndIf;
	
	Handler = New CallbackDescription("InstallExtensionAfterResponse", ThisObject, Context);
	
	If Context.WithoutQuestion Then
		RunCallback(Handler, DialogReturnCode.Yes);
		Return;
	EndIf;
	
#If WebClient Then
	Components = NewCryptoManagementAddIns();
	Components.IsCryptographicExtensionInstalled = False;
	
	IsAdditionalAddInsInstallationRequired = Await IsAdditionalAddInsInstallationRequired(Components);
	
	If IsAdditionalAddInsInstallationRequired Then
		FormParameters = New Structure;
		FormParameters.Insert("Components", Components);
		FormParameters.Insert("RequiredAddInName", "CryptographicExtension");
		OpenForm("CommonForm.StartWorkWithDigitalSignature", FormParameters,
			, , , , Handler, FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
#EndIf
	
	FormParameters = New Structure;
	FormParameters.Insert("QuestionTitle", Context.QuestionTitle);
	FormParameters.Insert("QueryText",     Context.QueryText);
	
	OpenForm("CommonForm.QuestionInstallCryptographyExtension",
		FormParameters,,,,, Handler);
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterResponse(Response, Context) Export
	
	If Response = True Or Response = DialogReturnCode.Yes Then
		BeginInstallCryptoExtension(New CallbackDescription(
			"InstallExtensionAfterInstallCryptoExtension", ThisObject, Context));
	Else
		If Context.Notification <> Undefined Then
			RunCallback(Context.Notification, Undefined);
		EndIf;
	EndIf;
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterInstallCryptoExtension(Context) Export
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"InstallExtensionAfterAttachInstalledCryptoExtension", ThisObject, Context));
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterAttachInstalledCryptoExtension(Attached, Context) Export
	
	If Attached Then
		Notify("InstallCryptoExtension");
	EndIf;
	
	If Context.Notification <> Undefined Then
		RunCallback(Context.Notification, Attached);
	EndIf;
	
EndProcedure

#Region CommonProceduresAndFunctionsForManagedForms

// For internal use only.
Procedure ContinueOpeningStart(Notification, Form, ClientParameters, Encryption = False, Details = False) Export
	
	If Not Encryption Then
		InputParameters = Undefined;
		ClientParameters.DataDetails.Property("AdditionalActionParameters", InputParameters);
		OutputParametersSet = Form.AdditionalActionsOutputParameters;
		Form.AdditionalActionsOutputParameters = Undefined;
		DigitalSignatureClientOverridable.BeforeOperationStart(
			?(Details, "Details", "Signing"), InputParameters, OutputParametersSet);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtServer", New Structure);
	Context.Insert("Operation", ?(Details, "Details", "Signing"));
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
		If Not ValueIsFilled(Form.CryptographyManagerOnServerErrorDescription) Then
			RunCallback(Notification, True);
			Return;
		EndIf;
		Context.ErrorAtServer = Form.CryptographyManagerOnServerErrorDescription;
	EndIf;
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ShowError = Undefined;
	
	CreateCryptoManager(New CallbackDescription(
			"ContinueOpeningStartAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", CreationParameters);
	
EndProcedure

// Continues the ContinueOpeningStart procedure.
Async Procedure ContinueOpeningStartAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") And Not UseDigitalSignatureSaaS()
		And Not UseCloudSignatureService() Then

		If Context.Operation = "Signing" Or Context.Operation = "Details" Then
			
			Notification = New CallbackDescription("ContinueOpeningAfterGettingThumbprintsOnTokens", ThisObject, 
				New Structure("Result, Context", Result, Context));
			StandardProcessing = True;
			DigitalSignatureClientLocalization.OnGettingCertificatesThumbprintsOnTokens(Notification, True, False,
				StandardProcessing);
			If Not StandardProcessing Then
				Return;
			ElsIf Context.Operation = "Signing" And DigitalSignatureClient.CommonSettings().UseMobileSignatureService Then
				RunCallback(Context.Notification, True);
				Return;
			EndIf;
		EndIf;

		ShowApplicationCallError(
			NStr("vi = 'Cần có ứng dụng chữ ký điện tử và mã hóa';
				|ru = 'Требуется приложение электронной подписи и шифрования';
				|en = 'A digital signing and encryption app is required'; fa = 'A digital signing and encryption app is required';
				|it = 'Требуется приложение электронной подписи и шифрования';
				|pl = 'A digital signing and encryption app is required';
				|tr = 'Dijital imza ve şifreleme uygulaması gerekli'"), "", Result,
			 Context.ErrorAtServer);

		RunCallback(Context.Notification, False);
		Return;
	EndIf;

	RunCallback(Context.Notification, True);
	
EndProcedure

// Continues the ContinueOpeningStart procedure.
Procedure ContinueOpeningAfterGettingThumbprintsOnTokens(CertificatesThumbprintsOnTokens, AdditionalParameters) Export
	
	Context = AdditionalParameters.Context;
	
	If CertificatesThumbprintsOnTokens.Count() > 0 Then
		RunCallback(Context.Notification, True);
		Return;
	EndIf;
	
	ShowApplicationCallError(
		NStr("vi = 'Cần có ứng dụng chữ ký điện tử và mã hóa';
			|ru = 'Требуется приложение электронной подписи и шифрования';
			|en = 'A digital signing and encryption app is required'; fa = 'A digital signing and encryption app is required';
			|it = 'Требуется приложение электронной подписи и шифрования';
			|pl = 'A digital signing and encryption app is required';
			|tr = 'Dijital imza ve şifreleme uygulaması gerekli'"), "", AdditionalParameters.Result,
		Context.ErrorAtServer);
		
	RunCallback(Context.Notification, False);
	
EndProcedure

// For internal use only.
Procedure GetCertificatesThumbprintsAtClient(Notification, IncludingOverduePayments = False) Export
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("IncludingOverduePayments", IncludingOverduePayments);
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ShowError = False;
	
	CreateCryptoManager(New CallbackDescription(
			"GetCertificatesThumbprintsAtClientAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", CreationParameters);
	
EndProcedure

// Continues the GetCertificatesThumbprintsAtClient procedure.
Procedure GetCertificatesThumbprintsAtClientAfterCreateCryptoManager(CryptoManager, Context) Export

	Notification = New CallbackDescription("AfterGettingThumbprintsOnTokens", ThisObject, 
		New Structure("Context, CryptoManager", Context, CryptoManager));
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnGettingCertificatesThumbprintsOnTokens(
		Notification, Context.IncludingOverduePayments, False, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	RunCallback(Notification, New Array);
	
EndProcedure

Procedure AfterGettingThumbprintsOnTokens(Array, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters.CryptoManager) <> Type("CryptoManager") Then
		RunCallback(AdditionalParameters.Context.Notification, Array);
		Return;
	EndIf;
	
	AdditionalParameters.Context.Insert("ThumbprintsArray", Array);
	
	AdditionalParameters.CryptoManager.BeginGettingCertificateStore(
		New CallbackDescription(
			"GetCertificatesThumbprintsAtClientAfterGetStorage", ThisObject, AdditionalParameters.Context),
		CryptoCertificateStoreType.PersonalCertificates);
	
EndProcedure

// Continues the GetCertificatesThumbprintsAtClient procedure.
Procedure GetCertificatesThumbprintsAtClientAfterGetStorage(CryptoCertificateStore, Context) Export
	
	CryptoCertificateStore.BeginGettingAll(New CallbackDescription(
		"GetCertificatesThumbprintsAtClientAfterGetAll", ThisObject, Context));
	
EndProcedure

// Continues the GetCertificatesThumbprintsAtClient procedure.
Procedure GetCertificatesThumbprintsAtClientAfterGetAll(CertificatesArray, Context) Export
	
	CertificatesThumbprintsAtClient = Context.ThumbprintsArray;
	
	DigitalSignatureInternalClientServer.AddCertificatesThumbprints(CertificatesThumbprintsAtClient,
		CertificatesArray,
		UTCOffset(),
		?(Context.IncludingOverduePayments, Undefined, CommonClient.SessionDate()));
	
	RunCallback(Context.Notification, CertificatesThumbprintsAtClient);
	
EndProcedure


// For internal use only.
//
// Parameters:
//   Form - ClientApplicationForm
//
Procedure ProcessPasswordInForm(Form, InternalData, PasswordProperties, AdditionalParameters = Undefined, NewPassword = Null) Export
	
	If TypeOf(PasswordProperties) <> Type("Structure") Then
		PasswordProperties = New Structure;
		PasswordProperties.Insert("Value", Undefined);
		PasswordProperties.Insert("PasswordNoteHandler", Undefined);
		// The property "PasswordVerified" allows for saving passwords without verification.
		// If it is raised if "NewPassword" is specified and the operation successful. 
		PasswordProperties.Insert("PasswordVerified", False);
		PasswordProperties.Insert("PasswordVisibility", False);
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If Not AdditionalParameters.Property("OnReadTokenCertificates") Then
		AdditionalParameters.Insert("Certificate", Form.Certificate);
		AdditionalParameters.Insert("EnterPasswordInDigitalSignatureApplication",
			Form.CertificateEnterPasswordInElectronicSignatureProgram);
	EndIf;
		
	If Not AdditionalParameters.Property("OnTogglePasswordConcealMode") Then
		AdditionalParameters.Insert("OnTogglePasswordConcealMode", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnSetPasswordFromAnotherOperation") Then
		AdditionalParameters.Insert("OnSetPasswordFromAnotherOperation", False);
	EndIf;

	If Not AdditionalParameters.Property("OnChangeAttributePassword") Then
		AdditionalParameters.Insert("OnChangeAttributePassword", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnChangeAttributeRememberPassword") Then
		AdditionalParameters.Insert("OnChangeAttributeRememberPassword", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnOperationSuccess") Then
		AdditionalParameters.Insert("OnOperationSuccess", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnChangeCertificateProperties") Then
		AdditionalParameters.Insert("OnChangeCertificateProperties", False);
	EndIf;
	
	AdditionalParameters.Insert("PasswordInMemory", False);
	AdditionalParameters.Insert("PasswordSetProgrammatically", False);
	AdditionalParameters.Insert("PasswordNote");
	
	Items = Form.Items;
	PasswordProperties.Insert("PasswordMode", Items.Password.PasswordMode);
		
	ProcessPassword(InternalData, Form.Password, PasswordProperties, Form.RememberPassword,
		AdditionalParameters, NewPassword);
		
	If Items.Find("Pages") = Undefined
		Or Items.Find("EnhancedPasswordNotePage") = Undefined Then
		
		Return;
	EndIf;
	
	CurrentProperties = New Structure("ExecuteInSaaS", False);
	FillPropertyValues(CurrentProperties, Form);
	
	ItemPassword = Items.Password; // FormField
	ItemRememberPassword = Items.RememberPassword;
	If CurrentProperties.ExecuteInSaaS
		And UseDigitalSignatureSaaS() Then
		
		ItemPassword.Enabled = False;
		ItemRememberPassword.Enabled = False;
		Items.Pages.Visible = True;
		Items.Pages.CurrentPage = Items.EnhancedPasswordNotePage;
		Items.AdvancedPasswordNote.ToolTip =
			NStr("vi = 'Dịch vụ đám mây sẽ gửi mật khẩu dùng một lần qua SMS hoặc email,
			           |cần nhập mật khẩu sau khi nhận.';
			           |ru = 'Сервис вышлет одноразовый пароль по SMS или E-Mail,
			           |который нужно будет ввести после получения.';
			           |en = 'The service will send a one-time password via text message or email.
			           |Enter the password after receiving.'; fa = 'The service will send a one-time password via text message or email.
			           |Enter the password after receiving.';
			           |it = 'Il servizio invierà tramite SMS o email una passwordunica
			           |da inserire.';
			           |pl = 'Usługa wyśle hasło jednorazowe przez SMS lub E-Mail,
			           |który należy wprowadzić po otrzymaniu.';
			           |tr = 'Hizmet, alındığında girilmesi gereken SMS veya E-Posta
			           | yoluyla tek kullanımlık bir şifre gönderecektir.'");
		
	ElsIf AdditionalParameters.EnterPasswordInDigitalSignatureApplication Then
		
		ItemPassword.Enabled = False;
		ItemRememberPassword.Enabled = False;
		Items.Pages.Visible = True;
		Items.Pages.CurrentPage = Items.EnhancedPasswordNotePage;
		Items.AdvancedPasswordNote.ToolTip =
			NStr("vi = 'Đối với chứng chỉ đã chọn, có chỉ ra ""Nhập mật khẩu trong ứng dụng chữ ký điện tử"".';
				|ru = 'Для выбранного сертификата указано ""Вводить пароль в приложении электронной подписи"".';
				|en = 'The option ""Protect digital signing app with password"" is set for this certificate.'; fa = 'The option ""Protect digital signing app with password"" is set for this certificate.';
				|it = 'Для выбранного сертификата указано ""Вводить пароль в приложении электронной подписи"".';
				|pl = 'The option ""Protect digital signing app with password"" is set for this certificate.';
				|tr = 'Seçilen sertifika için ""Dijital imza uygulamasında şifre giriniz"" belirtilir.'");
		
	Else
		
		If AdditionalParameters.PasswordSetProgrammatically Then
			
			Items.Pages.Visible = True;
			Items.Pages.CurrentPage = Items.SpecifiedPasswordNotePage;
			PasswordNote = AdditionalParameters.PasswordNote;
			
			Items.SpecifiedPasswordNote.Title   = PasswordNote.ExplanationText;
			Items.SpecifiedPasswordNote.Hyperlink = PasswordNote.HyperlinkNote;
			
			ItemSpecifiedPasswordNoteExtendedTooltip = Items.SpecifiedPasswordNoteExtendedTooltip; // FormField
			ItemSpecifiedPasswordNoteExtendedTooltip.Title = PasswordNote.ToolTipText;
			PasswordProperties.PasswordNoteHandler = PasswordNote.ProcessAction;
			
			ItemPassword.Enabled = True;
			ItemRememberPassword.Enabled = True;
			
		Else
			
			ItemPassword.Enabled = Not AdditionalParameters.PasswordInMemory;
			ItemRememberPassword.Enabled = Not AdditionalParameters.PasswordInMemory;
			
			If Items.Find("RememberPasswordPage") = Undefined Then
				Items.Pages.Visible = False;
			Else
				Items.Pages.Visible = True;
				Items.Pages.CurrentPage = Items.RememberPasswordPage;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	AdditionalParameters.Insert("PasswordSpecified1",
		AdditionalParameters.PasswordSetProgrammatically
		Or AdditionalParameters.PasswordInMemory
		Or AdditionalParameters.OnSetPasswordFromAnotherOperation);
	
	FormValues = GetDataCloudSignature(Form, "CertificateData");
	If CommonClientServer.StructureProperty(AdditionalParameters, "OnOpen", False) 
		And CommonClientServer.StructureProperty(FormValues, "Cloud", False) Then
		RemovePassword = AdditionalParameters.PasswordInMemory;
		Items.Pages.Visible = Not RemovePassword;
		ItemPassword.Visible = Not RemovePassword;
	EndIf;	
	
EndProcedure

// For internal use only.
Procedure SpecifiedPasswordNoteClick(Form, Item, PasswordProperties) Export
	
	If TypeOf(PasswordProperties.PasswordNoteHandler) = Type("CallbackDescription") Then
		Result = New Structure;
		Result.Insert("Certificate", Form.Certificate);
		Result.Insert("Action", "NoteClick");
		RunCallback(PasswordProperties.PasswordNoteHandler, Result);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure SpecifiedPasswordNoteURLProcessing(Form, Item, URL,
			StandardProcessing, PasswordProperties) Export
	
	StandardProcessing = False;
	
	If TypeOf(PasswordProperties.PasswordNoteHandler) = Type("CallbackDescription") Then
		Result = New Structure;
		Result.Insert("Certificate", Form.Certificate);
		Result.Insert("Action", URL);
		RunCallback(PasswordProperties.PasswordNoteHandler, Result);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure CertificatePickupFromSelectionList(Form, Text, ChoiceData, StandardProcessing) Export
	
	If Text = "" And Form.CertificatePicklist.Count() = 0 Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	For Each ListItem In Form.CertificatePicklist Do
		If StrFind(Upper(ListItem.Presentation), Upper(Text)) > 0 Then
			ChoiceData.Add(ListItem.Value, ListItem.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

// For internal use only.
Async Procedure ExecuteAtSide(Notification, Operation, ExecutionSide, ExecutionParameters) Export
	
	Context = ExecuteANewContextOnTheSide();
	
	FillPropertyValues(Context, ExecutionParameters);
	
	CloudSignatureProperties = GetThePropertiesOfACloudSignature(Context.DataDetails);
	UseACloudSignature = CommonClientServer.StructureProperty(ExecutionParameters, "UseACloudSignature", True);
	EncryptAlgorithm = CommonClientServer.StructureProperty(Context.DataDetails, "EncryptAlgorithm", "");
	
	Context.Insert("Notification",       Notification);
	Context.Insert("Operation",         Operation); // Signing, Encryption, Decryption.
	Context.Insert("OnClientSide", ExecutionSide = "OnClientSide");
	Context.Insert("OperationStarted", False);
	Context.Insert("UseACloudSignature", UseACloudSignature);
	
	If Context.OnClientSide Then
		If ValueIsFilled(CloudSignatureProperties.Account) Then
			Context.Insert("CryptoManager", "CloudSignature");
			ExecuteOnTheCloudSignatureSide(Context);
		ElsIf Context.Operation = "Encryption" And UseDigitalSignatureSaaS() Then
			Context.Insert("CryptoManager", "CryptographyService");
			ExecuteAtSIdeSaaS(Null, Context);
		ElsIf (Context.Operation = "Details" Or Context.Operation = "Signing")
			And UseDigitalSignatureSaaS()
			And Context.Form.ExecuteInSaaS Then
				Context.Insert("CryptoManager", "CryptographyService");
				ExecuteAtSIdeSaaS(Null, Context);
		Else
			
			If ValueIsFilled(Context.Form.CertificateApp) Then
				Application = Context.Form.CertificateApp;
			Else
				If Operation = "Signing" Or Operation = "Details" Then
					IsPrivateKeyRequied = True;
				Else
					IsPrivateKeyRequied = Undefined;
				EndIf;
				CertificateApplicationResult = Await AppForCertificate(
					ExecutionParameters.AddressOfCertificate, IsPrivateKeyRequied, Undefined, True);
				If ValueIsFilled(CertificateApplicationResult.Application) Then
					Application = CertificateApplicationResult.Application;
				Else
					
					CertificateData = GetFromTempStorage(ExecutionParameters.AddressOfCertificate);
					
					CryptoCertificate = New CryptoCertificate;
					Await CryptoCertificate.InitializeAsync(CertificateData);
					Context.Insert("CryptoCertificate", CryptoCertificate);
					Context.Insert("CertificateProperties", Await CertificateProperties(CryptoCertificate));
					Context.CertificateProperties.Insert("BinaryData", CertificateData);
					
					If Operation = "Encryption" Then
						
						Notification = New CallbackDescription("AfterSearchingForTokenForEncryption", ThisObject, 
							New Structure("Context, EncryptAlgorithm, ErrorDescription",
							Context, EncryptAlgorithm, CertificateApplicationResult.Error));
						StandardProcessing = True;
						DigitalSignatureClientLocalization.OnSearchTokenForEncryption(Notification, CryptoCertificate, EncryptAlgorithm,
							Context.CertificateProperties, StandardProcessing);
						If Not StandardProcessing Then
							Return;
						EndIf;
						
					Else
						
						Notification = New CallbackDescription("AfterSearchingForTokenByCertificate", ThisObject, 
								New Structure("Context, EncryptAlgorithm, ErrorDescription", 
								Context, EncryptAlgorithm, CertificateApplicationResult.Error));
						StandardProcessing = True;
						DigitalSignatureClientLocalization.OnGettingTokenByCertificate(
							Notification, Context.CryptoCertificate, StandardProcessing, True);
						If Not StandardProcessing Then
							Return;
						EndIf;
		
					EndIf;
					
					ErrorAtClient = New Structure("ErrorDescription", CertificateApplicationResult.Error);
					ErrorAtClient.Insert("Instruction", True);
					ExecuteAtSideAfterLoop(ErrorAtClient, Context);
					Return;
					
				EndIf;
			EndIf;
			
			CreationParameters = CryptoManagerCreationParameters();
			CreationParameters.ShowError = Undefined;
			CreationParameters.Application = Application;
			CreationParameters.InteractiveMode = Context.Form.CertificateEnterPasswordInElectronicSignatureProgram;
			CreationParameters.EncryptAlgorithm = EncryptAlgorithm;
			
			Context.Insert("Application", Application);
			
			CreateCryptoManager(New CallbackDescription(
					"ExecuteAtSideAfterCreateCryptoManager", ThisObject, Context),
				Operation, CreationParameters);
				
		EndIf;
	Else
		ExecuteAtSideLoopRun(Context);
	EndIf;
	
EndProcedure

Async Procedure AfterSearchingForTokenForEncryption(Token, AdditionalParameters) Export
	
	If Not ValueIsFilled(Token) Then
#If MobileClient Or MobileAppClient Then
		ErrorAtClient = New Structure("ErrorDescription", NStr("ru = 'Не найден токен для шифрования данных.';
																|vi = 'Token for data encryption not found.';
																|en = 'Token for data encryption not found.'; fa = 'Token for data encryption not found.';
																|it = 'Token for data encryption not found.';
																|pl = 'Token for data encryption not found.';
																|tr = 'Veri şifreleme için token bulunamadı.'"));
#Else
		ErrorAtClient = New Structure("ErrorDescription", AdditionalParameters.ErrorDescription);
#EndIf
		ErrorAtClient.Insert("Instruction", True);
		ExecuteAtSideAfterLoop(ErrorAtClient, AdditionalParameters.Context);
		Return;
	EndIf;
	
	AdditionalParameters.Context.Insert("CryptoManager", Token);
	AdditionalParameters.Context.Insert("EncryptAlgorithm", AdditionalParameters.EncryptAlgorithm);
	ExecuteAtSidePrepareCertificatesLoopStart(AdditionalParameters.Context);
		
EndProcedure


Async Procedure AfterSearchingForTokenByCertificate(Token, AdditionalParameters) Export
	
	If Not ValueIsFilled(Token) Then
#If MobileClient Or MobileAppClient Then
		ErrorAtClient = New Structure("ErrorDescription", NStr("ru = 'Не найден токен с указанным сертификатом.';
																|vi = 'Token with the specified certificate not found.';
																|en = 'Token with the specified certificate not found.'; fa = 'Token with the specified certificate not found.';
																|it = 'Token with the specified certificate not found.';
																|pl = 'Token with the specified certificate not found.';
																|tr = 'Belirtilen sertifikaya sahip token bulunamadı.'"));
#Else
		ErrorAtClient = New Structure("ErrorDescription", AdditionalParameters.ErrorDescription);
#EndIf
		
		ErrorAtClient.Insert("Instruction", True);
		ExecuteAtSideAfterLoop(ErrorAtClient, AdditionalParameters.Context);
		Return;
	EndIf;
	
	AdditionalParameters.Context.Insert("CryptoManager", Token);
	Token.Insert("Password", AdditionalParameters.Context.PasswordValue);
	AdditionalParameters.Context.Delete("PasswordValue");
	ExecuteAtSideLoopRun(AdditionalParameters.Context);
		
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		
		If Context.Operation = "Encryption" Then

			If CommonClientServer.StructureProperty(Context, "UseACloudSignature", True) = True
				And EncryptDataWithACloudSignature() Then
				Context.Insert("CryptoManager", "CloudSignature");
				ExecuteOnTheCloudSignatureSide(Context);
			ElsIf TypeOf(Result) = Type("Structure") And Result.Property("Token") Then
				Context.Insert("CryptoManager", Result);
				ExecuteAtSideAfterCertificateSearch(Null, Context);
				Return;
			EndIf;
				
		Else
			RunCallback(Context.Notification, New Structure("Error", Result));
			Return;
		EndIf;
	EndIf;
	Context.Insert("CryptoManager", Result);
	
	// If a personal crypto certificate is not used, it does not need to be searched for.
	If Context.Operation <> "Encryption"
	 Or ValueIsFilled(Context.Form.ThumbprintOfCertificate) Then
		
		GetCertificateByThumbprint(New CallbackDescription(
				"ExecuteAtSideAfterCertificateSearch", ThisObject, Context),
			Context.Form.ThumbprintOfCertificate, True, Undefined,
			?(TypeOf(Result) <> Type("CryptoManager"), Context.Form.CertificateApp, Result));

	Else
		ExecuteAtSideAfterCertificateSearch(Null, Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
//
// Parameters:
//   Context - Structure:
//     * CryptoCertificate - CryptoCertificate
//
Procedure ExecuteAtSideAfterCertificateSearch(Result, Context) Export

	If TypeOf(Result) <> Type("CryptoCertificate") And Result <> Null Then
		RunCallback(Context.Notification, New Structure("Error", Result));
		Return;
	EndIf;
	Context.Insert("CryptoCertificate", Result);
	
	If Context.Operation = "Signing" Then
		If Not InteractiveCryptographyModeUsed(Context.CryptoManager) Then
			Context.CryptoManager.PrivateKeyAccessPassword = Context.PasswordValue;
		EndIf;
		Context.Delete("PasswordValue");
		Context.CryptoCertificate.BeginUnloading(New CallbackDescription(
			"ExecuteAtSideAfterCertificateExport", ThisObject, Context));
		
	ElsIf Context.Operation = "Encryption" Then
		ExecuteAtSidePrepareCertificatesLoopStart(Context);
		Return;
	Else
		If Not InteractiveCryptographyModeUsed(Context.CryptoManager) Then
			Context.CryptoManager.PrivateKeyAccessPassword = Context.PasswordValue;
		EndIf;
		Context.Delete("PasswordValue");
		ExecuteAtSideLoopRun(Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
//
// Parameters:
//   Context - Structure
//
Async Procedure ExecuteAtSidePrepareCertificatesLoopStart(Context)
	
	CertificatesProperties = Context.DataDetails.EncryptionCertificates;
	If TypeOf(CertificatesProperties) = Type("String") Then
		CertificatesProperties = GetFromTempStorage(CertificatesProperties);
	EndIf;
	Context.Insert("EncryptionCertificates", New Array);
	For Each EncryptionCertificate In CertificatesProperties Do
		CryptoCertificate = New CryptoCertificate;
		Await CryptoCertificate.InitializeAsync(EncryptionCertificate.Certificate);
		Context.EncryptionCertificates.Add(CryptoCertificate);
	EndDo;
	ExecuteAtSideLoopRun(Context);

EndProcedure

// Continues the ExecuteAtSide procedure.
Async Procedure ExecuteAtSideAfterCertificateExport(ExportedData, Context) Export
	
	Context.Insert("CertificateProperties", Await CertificateProperties(
		Context.CryptoCertificate));
	Context.CertificateProperties.Insert("BinaryData", ExportedData);
	
	If Context.Operation = "Signing" And TypeOf(Context.CryptoManager) = Type("CryptoManager")
		And ValueIsFilled(Context.CryptoManager.SignAlgorithm) Then

		If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
			CertificateAlgorithm = Context.CertificateProperties.PublicKeyAlgorithm;
		Else
			CertificateAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
				ExportedData, False, True);
		EndIf;

		Result = DigitalSignatureInternalClientServer.SignAlgorithmCorrespondsToCertificate(
			Context.CertificateProperties.Presentation, CertificateAlgorithm,
			Context.CryptoManager.SignAlgorithm);

		If Result <> True Then

			ErrorAtClient = New Structure("ErrorDescription", Result);
			RunCallback(Context.Notification, New Structure("Error", ErrorAtClient));
			Return;

		EndIf;
	
	EndIf;
	
	ExecuteAtSideLoopRun(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopRun(Context)
	
	If Context.DataDetails.Property("Data") Then
		DataItems = New Array;
		DataItems.Add(Context.DataDetails);
	Else
		DataItems = Context.DataDetails.DataSet;
	EndIf;
	
	Context.Insert("DataItems", DataItems);
	Context.Insert("IndexOf", -1);
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopStart(Context)
	
	If Context.DataItems.Count() <= Context.IndexOf + 1 Then
		ExecuteAtSideAfterLoop(Undefined, Context);
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"ExecuteAtSideLoopStartContinued", ThisObject, Context);
	
	StandardSubsystemsClient.StartNotificationProcessing(Notification);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
//
// Parameters:
//  Result - Number
//  Context - See ExecuteANewContextOnTheSide
//
Procedure ExecuteAtSideLoopStartContinued(Result, Context) Export
	
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("DataElement", Context.DataItems[Context.IndexOf]);
	
	If Not Context.DataDetails.Property("Data") Then
		Context.DataDetails.Insert("CurrentDataSetItem", Context.DataElement);
	EndIf;
	
	If Context.Operation = "Signing"
	   And Context.DataElement.Property("SignatureProperties")
	 Or Context.Operation = "Encryption"
	   And Context.DataElement.Property("EncryptedData")
	 Or Context.Operation = "Details"
	   And Context.DataElement.Property("DecryptedData") Then
		
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	GetDataFromDataDetails(New CallbackDescription(
			"ExecuteAtSideCycleAfterGetData", ThisObject, Context),
		Context.Form, Context.DataDetails, Context.DataElement.Data, Context.OnClientSide);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterOperationAtClientXMLDSig(XMLEnvelope, Context) Export
	
	Context.OperationStarted = True;
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(XMLEnvelope,
		Context.CertificateProperties,
		Context.Form.Comment,
		UsersClient.AuthorizedUser());
	
	If Context.CertificateValid <> Undefined Then
		SignatureProperties.SignatureDate = CommonClient.SessionDate();
		SignatureProperties.SignatureValidationDate = SignatureProperties.SignatureDate;
		SignatureProperties.SignatureCorrect = Context.CertificateValid;
	EndIf;
	
	SignatureProperties.IsVerificationRequired = Context.IsVerificationRequired;
	
	ExecuteAtSideAfterSigning(SignatureProperties, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideCycleAfterErrorAtClientXMLDSig(ErrorText, Context) Export
	
	ErrorAtClient = New Structure("ErrorDescription", ErrorText);
	ErrorAtClient.Insert("Instruction", True);
	
	ExecuteAtSideAfterLoop(ErrorAtClient, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
//
// Parameters:
//  Result - BinaryData
//            - String
//            - Structure
//  Context - See ExecuteANewContextOnTheSide
//
Procedure ExecuteAtSideCycleAfterGetData(Result, Context) Export
	
	ResultType = TypeOf(Result);
	
	If ResultType <> Type("String")
		And ResultType <> Type("BinaryData")
		And ResultType <> Type("Structure") Then
			
		Error = New Structure("ErrorDescription",
			DigitalSignatureInternalClientServer.DataGettingErrorTitle(Context.Operation)
			+ Chars.LF
			+ NStr("vi = 'Sai kiểu dữ liệu: %1';
					|ru = 'Некорректный тип данных: %1';
					|en = 'Invalid data type: %1'; fa = 'Invalid data type: %1';
					|it = 'Tipo di dati errato: %1';
					|pl = 'Nieprawidłowy typ danych: %1';
					|tr = 'Geçersiz veri türü: %1'"));
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	IsXMLDSig = (ResultType = Type("Structure") And Result.Property("XMLDSigParameters"));
	IsCMS     = (ResultType = Type("Structure") And Result.Property("CMSParameters"));
	
	If IsXMLDSig And Not Result.Property("XMLEnvelope") Then
		Result = New Structure(New FixedStructure(Result));
		Result.Insert("XMLEnvelope", Result.SOAPEnvelope);
	EndIf;
	
	If ResultType = Type("Structure")
	   And Not IsXMLDSig
	   And Not IsCMS Then
		
		Error = New Structure("ErrorDescription",
			DigitalSignatureInternalClientServer.DataGettingErrorTitle(Context.Operation)
			+ Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	Data = Result;
	
	If Context.OnClientSide Then
		
		If IsXMLDSig  And TypeOf(Context.CryptoManager) = Type("Structure") Then
			Error = New Structure("ErrorDescription",
			NStr("vi = 'Sẽ có thể tạo chữ ký XMLDSig bằng cơ chế token trong các phiên bản tiếp theo của ứng dụng.';
				|ru = 'Создать подпись XMLDSig с помощью механизмов токена можно будет в следующих версиях приложения.';
				|en = 'Generating XMLDSig signatures using the token''s built-in mechanisms will be released later.'; fa = 'Generating XMLDSig signatures using the token''s built-in mechanisms will be released later.';
				|it = 'Generating XMLDSig signatures using the token''s built-in mechanisms will be released later.';
				|pl = 'Generating XMLDSig signatures using the token''s built-in mechanisms will be released later.';
				|tr = 'Uygulamanın gelecek sürümlerinde token mekanizmaları aracılığıyla bir XMLDSig imzası oluşturulabilecektir.'"));
			ExecuteAtSideAfterLoop(Error, Context);
			Return;
		EndIf;
		
		CryptoManager = Context.CryptoManager;
		OperationParametersList = New Structure;
		OperationParametersList.Insert("Operation", Context.DataDetails.Operation);
		OperationParametersList.Insert("DataTitle", Context.DataDetails.DataTitle);
		
		If IsXMLDSig Then
			
			If Context.Operation <> "Signing" Then
				Error = New Structure("ErrorDescription",
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chỉ có thể sử dụng cấu phần ngoài %1 để ký.';
							|ru = 'Внешняя компонента %1 может использоваться только для подписания.';
							|en = '%1 add-in is intended for signing only.'; fa = '%1 add-in is intended for signing only.';
							|it = 'La componente esterna %1può essere utilizzata solo per la firma.';
							|pl = 'Zewnętrzny komponent %1 może być używany tylko do podpisywania.';
							|tr = '%1 harici bileşen yalnızca imzalama amacıyla kullanılabilir.'"), "ExtraCryptoAPI"));
				ExecuteAtSideAfterLoop(Error, Context);
				Return;
			EndIf;
			
			NotificationSuccess = New CallbackDescription(
				"ExecuteAtSideLoopAfterOperationAtClientXMLDSig", ThisObject, Context);
			
			NotificationError = New CallbackDescription(
				"ExecuteAtSideCycleAfterErrorAtClientXMLDSig", ThisObject, Context);
			
			Notifications = New Structure;
			Notifications.Insert("Success", NotificationSuccess);
			Notifications.Insert("Error", NotificationError);
			
			StartCryptoCertificateExportToSignXMLDSig(Notifications,
				Result.XMLEnvelope,
				Result.XMLDSigParameters,
				Context.CryptoCertificate,
				Context.CryptoManager);
		
		ElsIf IsCMS Then
			If Context.Operation <> "Signing" Then
				Error = New Structure("ErrorDescription",
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chỉ có thể sử dụng cấu phần ngoài %1 để ký.';
							|ru = 'Внешняя компонента %1 может использоваться только для подписания.';
							|en = '%1 add-in is intended for signing only.'; fa = '%1 add-in is intended for signing only.';
							|it = 'La componente esterna %1può essere utilizzata solo per la firma.';
							|pl = 'Zewnętrzny komponent %1 może być używany tylko do podpisywania.';
							|tr = '%1 harici bileşen yalnızca imzalama amacıyla kullanılabilir.'"), "ExtraCryptoAPI"));
				ExecuteAtSideAfterLoop(Error, Context);
				Return;
			EndIf;
			
			If CryptoManager = "CryptographyService" Then
				If Result.CMSParameters.IncludeCertificatesInSignature <> CryptoCertificateIncludeMode.IncludeSubjectCertificate Then
					Error = New Structure("ErrorDescription",
						NStr("vi = 'Không được phép ký bằng chứng thư với ứng dụng của nhà cung cấp mã hóa tích hợp.
						           |Hãy chọn chứng thư khác từ các chứng thư đã cài đặt trên máy tính.';
						           |ru = 'Подписание сертификатом с приложением встроенного криптопровайдера недоступно.
						           |Выберите другой сертификат из установленных на компьютере.';
						           |en = 'Certificates with a built-in cryptographic service provider are not supported.
						           |Choose a local certificate.'; fa = 'Certificates with a built-in cryptographic service provider are not supported.
						           |Choose a local certificate.';
						           |it = 'Подписание сертификатом с приложением встроенного криптопровайдера недоступно.
						           |Выберите другой сертификат из установленных на компьютере.';
						           |pl = 'Certificates with a built-in cryptographic service provider are not supported.
						           |Choose a local certificate.';
						           |tr = 'Yerleşik kriptografik sağlayıcı ile sertifika ile imzalama mevcut değil.
						           |Bilgisayarda kurulu olanlardan başka bir sertifika seçin.'"));
					ExecuteAtSideAfterLoop(Error, Context);
					Return;
				EndIf;
				If TypeOf(Data.Data) = Type("BinaryData") Then
					DataToSign = Data.Data;
				Else
					DataToSign = GetBinaryDataFromString(Data.Data);
				EndIf;
				OperationParametersList.Insert("DisconnectedSignature", Result.CMSParameters.DetachedAddIn);
				Notification = New CallbackDescription(
					"ExecuteAtSideCycleAfterOPerationAtClient", ThisObject, Context,
					"ExecuteOnSideLoopAfterOperationErrorAtClient", ThisObject);
				CertificateForSignature = GetFromTempStorage(Context.DataDetails.SelectedCertificate.Data);
				ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
				ModuleCryptographyServiceClient.Sign(Notification, DataToSign, CertificateForSignature, , OperationParametersList);
			ElsIf CryptoManager = "CloudSignature" Then
				
				Notification = New CallbackDescription(
					"ExecuteAtSideCycleAfterOPerationAtClient", ThisObject, Context,
					"ExecuteOnSideLoopAfterOperationErrorAtClient", ThisObject);
				PerformACloudSignatureOperation(Notification, Context, Data, OperationParametersList);
				
			ElsIf TypeOf(CryptoManager) = Type("Structure") Then // Token
				
				SignatureParameters = ParametersOfSignatureOnToken(CryptoManager, Context.CryptoCertificate,
							Context.DataDetails.SignatureType);
				SignatureParameters.DetachedAddIn = Result.CMSParameters.DetachedAddIn;
				StandardProcessing = True;
				NotificationAfterOperationOnToken = New CallbackDescription("AfterSigningOnToken",
					ThisObject, Context);
					
				DigitalSignatureClientLocalization.OnSigningOnToken(NotificationAfterOperationOnToken,
					SignatureParameters, Data, StandardProcessing);
				If Not StandardProcessing Then
					Return;
				EndIf;
				RunCallback(NotificationAfterOperationOnToken, 
							NStr("ru = 'Не найдена процедура подписания для токена.';
								|vi = 'Signing procedure for the token not found.';
								|en = 'Signing procedure for the token not found.'; fa = 'Signing procedure for the token not found.';
								|it = 'Signing procedure for the token not found.';
								|pl = 'Signing procedure for the token not found.';
								|tr = 'Token için imzalama prosedürü bulunamadı.'"));
			Else
				NotificationSuccess = New CallbackDescription(
					"ExecuteAtSideLoopAfterOperationAtClientXMLDSig", ThisObject, Context);
				
				NotificationError = New CallbackDescription(
					"ExecuteAtSideCycleAfterErrorAtClientXMLDSig", ThisObject, Context);
				
				Notifications = New Structure;
				Notifications.Insert("Success", NotificationSuccess);
				Notifications.Insert("Error", NotificationError);
				
				StartCryptoCertificateExportToSignCMS(Notifications,
					Result.Data,
					Result.CMSParameters,
					Context.CryptoCertificate,
					Context.CryptoManager);
			EndIf;
		Else
			Notification = New CallbackDescription(
				"ExecuteAtSideCycleAfterOPerationAtClient", ThisObject, Context,
				"ExecuteOnSideLoopAfterOperationErrorAtClient", ThisObject);
			
			If CryptoManager = "CloudSignature" Then
				PerformACloudSignatureOperation(Notification, Context, Data, OperationParametersList);
			
			ElsIf Context.Operation = "Signing" Then
				
				If CryptoManager = "CryptographyService" Then
					CertificateForSignature = GetFromTempStorage(Context.DataDetails.SelectedCertificate.Data);
					ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
					ModuleCryptographyServiceClient.Sign(Notification, Data, CertificateForSignature, , OperationParametersList);
				Else
					
					Try
						SettingsSignatures = DigitalSignatureInternalClientServer.SignatureCreationSettings(
							Context.DataDetails.SignatureType,
							DigitalSignatureClient.CommonSettings().TimestampServersAddresses);
					Except
						ExecuteOnSideLoopAfterOperationErrorAtClient(ErrorInfo(), False, Context);
						Return;
					EndTry;
					
					If TypeOf(CryptoManager) = Type("Structure") Then // Token
					
						SignatureParameters = ParametersOfSignatureOnToken(CryptoManager, Context.CryptoCertificate,
							Context.DataDetails.SignatureType);
						StandardProcessing = True;
						NotificationAfterOperationOnToken = New CallbackDescription("AfterSigningOnToken",
							ThisObject, Context);
						
						DigitalSignatureClientLocalization.OnSigningOnToken(NotificationAfterOperationOnToken,
							SignatureParameters, Data, StandardProcessing);
						If Not StandardProcessing Then
							Return;
						EndIf;
						
						RunCallback(NotificationAfterOperationOnToken, 
							NStr("ru = 'Не найдена процедура подписания для токена.';
								|vi = 'Signing procedure for the token not found.';
								|en = 'Signing procedure for the token not found.'; fa = 'Signing procedure for the token not found.';
								|it = 'Signing procedure for the token not found.';
								|pl = 'Signing procedure for the token not found.';
								|tr = 'Token için imzalama prosedürü bulunamadı.'"));
						
					Else
						If ValueIsFilled(SettingsSignatures.TimestampServersAddresses) Then
							CryptoManager.TimestampServersAddresses = SettingsSignatures.TimestampServersAddresses;
						EndIf;
						CryptoManager.BeginSigning(Notification, Data, Context.CryptoCertificate, 
							SettingsSignatures.SignatureType);
					EndIf;
					
				EndIf;
				
			ElsIf Context.Operation = "Encryption" Then
				
				If CryptoManager = "CryptographyService" Then
					ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
					ModuleCryptographyServiceClient.Encrypt(Notification, Data, Context.EncryptionCertificates, , OperationParametersList);
				ElsIf TypeOf(CryptoManager) = Type("Structure") Then // Token
	
					EncryptionParameters = EncryptionOnTokenParameters(CryptoManager,
						Context.EncryptionCertificates, Context.EncryptAlgorithm);

					StandardProcessing = True;
					NotificationAfterOperationOnToken = New CallbackDescription("AfterEncryptionOnToken", ThisObject, Context);
					DigitalSignatureClientLocalization.OnEncryptionOnToken(NotificationAfterOperationOnToken,
						EncryptionParameters, Data, StandardProcessing);
					If Not StandardProcessing Then
						Return;
					EndIf;
					
					RunCallback(NotificationAfterOperationOnToken, 
						NStr("ru = 'Не найдена процедура шифрования для токена.';
							|vi = 'Encryption procedure for the token not found.';
							|en = 'Encryption procedure for the token not found.'; fa = 'Encryption procedure for the token not found.';
							|it = 'Encryption procedure for the token not found.';
							|pl = 'Encryption procedure for the token not found.';
							|tr = 'Token için şifreleme prosedürü bulunamadı.'"));
					
				Else
					CryptoManager.BeginEncrypting(Notification, Data, Context.EncryptionCertificates);
				EndIf;
				
			Else
				
				If CryptoManager = "CryptographyService" Then
					ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
					ModuleCryptographyServiceClient.Decrypt(Notification, Data, , OperationParametersList);
				ElsIf TypeOf(CryptoManager) = Type("Structure") Then // Token
				
					DetailsParameters = DecryptionOnTokenParameters(CryptoManager, 
						Context.CryptoCertificate);
					NotificationAfterOperationOnToken = New CallbackDescription("AfterDecryptionOnToken",
							ThisObject, Context);
					StandardProcessing = True;
					DigitalSignatureClientLocalization.OnDecryptionOnToken(NotificationAfterOperationOnToken,
						DetailsParameters, Data, StandardProcessing);
					If Not StandardProcessing Then
						Return;
					EndIf;
					
					RunCallback(NotificationAfterOperationOnToken, 
						NStr("ru = 'Не найдена процедура расшифровки для токена.';
							|vi = 'Decryption procedure for the token not found.';
							|en = 'Decryption procedure for the token not found.'; fa = 'Decryption procedure for the token not found.';
							|it = 'Decryption procedure for the token not found.';
							|pl = 'Decryption procedure for the token not found.';
							|tr = 'Token için şifre çözme prosedürü bulunamadı.'"));
					
				Else
					CryptoManager.BeginDecrypting(Notification, Data);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	DataItemForSErver = New Structure;
	DataItemForSErver.Insert("Data", Data);
	
	ParametersForServer = New Structure;
	ParametersForServer.Insert("Operation", Context.Operation);
	ParametersForServer.Insert("FormIdentifier",  Context.FormIdentifier);
	ParametersForServer.Insert("CertificateValid",     Context.CertificateValid);
	ParametersForServer.Insert("IsVerificationRequired",   Context.IsVerificationRequired);
	ParametersForServer.Insert("CertificateApp", Context.Form.CertificateApp);
	ParametersForServer.Insert("ThumbprintOfCertificate", Context.Form.ThumbprintOfCertificate);
	ParametersForServer.Insert("DataItemForSErver", DataItemForSErver);
	
	ErrorAtServer = New Structure;
	ResultAddress = Undefined;
	
	If Not ValueIsFilled(ParametersForServer.CertificateApp) Then
		ParametersForServer.Insert("DataToCreateCryptographyManager", Context.AddressOfCertificate);
	EndIf;
	
	If Context.Operation = "Signing" Then
	
		ParametersForServer.Insert("SignatureType",     Context.DataDetails.SignatureType);
		ParametersForServer.Insert("Comment",    Context.Form.Comment);
		ParametersForServer.Insert("PasswordValue", Context.PasswordValue);
		ParametersForServer.Insert("SelectedLetterOfAuthority", Context.DataDetails.SelectedLetterOfAuthority);
		ParametersForServer.Insert("MachineReadableSigningLOACheckResult", Context.DataDetails.MachineReadableSigningLOACheckResult);
		
		If Context.DataElement.Property("Object")
		   And Not TypeOf(Context.DataElement.Object) = Type("CallbackDescription") Then
			
			DataItemForSErver.Insert("Object", Context.DataElement.Object);
			
			If Context.DataElement.Property("ObjectVersion") Then
				DataItemForSErver.Property("ObjectVersion", Context.DataElement.ObjectVersion);
			EndIf;
		EndIf;
		
	ElsIf Context.Operation = "Encryption" Then
	
		ParametersForServer.Insert("CertificatesAddress", Context.DataDetails.EncryptionCertificates);
		EncryptAlgorithm = CommonClientServer.StructureProperty(Context.DataDetails, "EncryptAlgorithm", "");
		ParametersForServer.Insert("EncryptAlgorithm", EncryptAlgorithm);
		
	Else // Decryption.
		ParametersForServer.Insert("PasswordValue", Context.PasswordValue);
	EndIf;
	
	Success = DigitalSignatureInternalServerCall.ExecuteAtServerSide(ParametersForServer,
		ResultAddress, Context.OperationStarted, ErrorAtServer);
	
	If Not Success Then
		ExecuteAtSideAfterLoop(ErrorAtServer, Context);
		
	ElsIf Context.Operation = "Signing" Then
		ExecuteAtSideAfterSigning(ResultAddress, Context);
		
	ElsIf Context.Operation = "Encryption" Then
		ExecuteAtSideLoopAfterEncryption(ResultAddress, Context);
	Else // Decryption.
		ExecuteAtSideAfterDecrypt(ResultAddress, Context);
	EndIf;
	
EndProcedure

Procedure AfterSigningOnToken(Signature,Context) Export
		
	If TypeOf(Signature) = Type("String") Then
		ErrorAtClient = New Structure("ErrorDescription", Signature);
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
		Return;
	EndIf;
	
	ExecuteAtSideCycleAfterOPerationAtClient(Signature, Context);
	
EndProcedure

Procedure AfterEncryptionOnToken(EncryptedData, Context) Export

	If TypeOf(EncryptedData) = Type("String") Then
		ErrorAtClient = New Structure("ErrorDescription", EncryptedData);
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
		Return;
	EndIf;
	
	ExecuteAtSideCycleAfterOPerationAtClient(EncryptedData, Context);
	
EndProcedure

Procedure AfterDecryptionOnToken(DecryptedData, Context) Export
	
	If TypeOf(DecryptedData) = Type("String") Then
		ErrorAtClient = New Structure("ErrorDescription", DecryptedData);
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
		Return;
	EndIf;
	
	If Not ValueIsFilled(DecryptedData) Then
		ErrorAtClient = New Structure("ErrorDescription", NStr("ru = 'Получены пустые расшифрованные данные.';
																|vi = 'Empty decrypted data retrieved.';
																|en = 'Empty decrypted data retrieved.'; fa = 'Empty decrypted data retrieved.';
																|it = 'Empty decrypted data retrieved.';
																|pl = 'Empty decrypted data retrieved.';
																|tr = 'Boş şifre çözülmüş veri alındı.'"));
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
		Return;
	EndIf;
	
	ExecuteAtSideCycleAfterOPerationAtClient(DecryptedData, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteOnSideLoopAfterOperationErrorAtClient(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorAtClient = New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
	ErrorAtClient.Insert("Instruction", True);
	
	ExecuteAtSideAfterLoop(ErrorAtClient, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
// 
// Parameters:
//   BinaryData - Structure:
//   * ErrorInfo - Structure:
//   ** LongDesc - String
//   Context - Structure
//
Async Procedure ExecuteAtSideCycleAfterOPerationAtClient(BinaryData, Context) Export
	
	If Context.Property("CryptoManager") And Context.CryptoManager = "CryptographyService" Then
		
		If Not BinaryData.Completed2 Then
			ErrorText = ErrorTextCloudSignature(Context.Operation, BinaryData.ErrorInfo.LongDesc, True, True);
			ErrorAtClient = New Structure("ErrorDescription", ErrorText);
			ExecuteAtSideAfterLoop(ErrorAtClient, Context);
			Return;
		EndIf;
		
		If Context.Operation = "Signing" Then
			BinaryData = BinaryData.Signature;
		ElsIf Context.Operation = "Encryption" Then
			BinaryData = BinaryData.EncryptedData;
		Else
			BinaryData = BinaryData.DecryptedData;
		EndIf;
		
	ElsIf Context.Property("CryptoManager") And Context.CryptoManager = "CloudSignature" Then
		
		If Not BinaryData.Completed2 Then
			If CommonClientServer.StructureProperty(Context, "UseACloudSignature", False) Then
				Context.Insert("UseACloudSignature", False);
				ExecuteAtSide(Context.Notification, Context.Operation, "OnClientSide", Context);
			Else
				ErrorAtClient = New Structure("ErrorDescription",
					ErrorTextCloudSignature(Context.Operation, BinaryData));
				ExecuteAtSideAfterLoop(ErrorAtClient, Context);
			EndIf;
			Return;
		EndIf;
		
		BinaryData = BinaryData.Result;
		
	EndIf;
	
	ErrorDescription = "";
	If Context.Operation = "Signing"
	   And DigitalSignatureInternalClientServer.BlankSignatureData(BinaryData, ErrorDescription)
	 Or Context.Operation = "Encryption"
	   And DigitalSignatureInternalClientServer.BlankEncryptedData(BinaryData, ErrorDescription) Then

		ErrorAtClient = New Structure("ErrorDescription", ErrorDescription);
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
		Return;
	EndIf;
	
	Context.OperationStarted = True;
	
	If Context.Operation = "Signing" Then
		If TypeOf(BinaryData) = Type("Array") Then
			RunALoopOnTheSideAfterSigningThePackage(BinaryData, Context);
		Else
			If Context.Property("CryptoManager") And TypeOf(Context.CryptoManager) = Type(
				"CryptoManager") Then

				SignatureProperties = Await SignaturePropertiesReadByCryptoManager(BinaryData, Context.CryptoManager, False);
			Else
				SignatureProperties = Await SignaturePropertiesFromBinaryData(BinaryData, False);
			EndIf;
			
			If SignatureProperties.Success = False Then
				SignatureData = Base64String(BinaryData);
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1.
						 |Kết quả chữ ký: %2';
						 |ru = '%1.
						 |Результат подписи: %2';
						 |en = '%1.
						 |Signature result: %2'; fa = '%1.
						 |Signature result: %2';
						 |it = '%1.
						 |Результат подписи: %2';
						 |pl = '%1.
						 |Signature result: %2';
						 |tr = '%1.
						 |İmza sonucu: %2'"), SignatureProperties.ErrorText, SignatureData);
				ErrorAtClient = New Structure("ErrorDescription", ErrorDescription);
				ErrorAtClient.Insert("Instruction", True);
				ExecuteAtSideAfterLoop(ErrorAtClient, Context);
				Return;
			EndIf;

			SignatureProperties = GetSignaturePropertiesAfterSigning(BinaryData, Context, SignatureProperties);
			ExecuteAtSideAfterSigning(SignatureProperties, Context);
		EndIf;
	ElsIf Context.Operation = "Encryption" Then
		ExecuteAtSideLoopAfterEncryption(BinaryData, Context);
	Else
		ExecuteAtSideAfterDecrypt(BinaryData, Context);
	EndIf;
	
EndProcedure 

Function GetSignaturePropertiesAfterSigning(BinaryData, Context, SignatureParameters = Undefined)
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(BinaryData,
		Context.CertificateProperties,
		Context.Form.Comment,
		UsersClient.AuthorizedUser(),, SignatureParameters);
		
	SignatureProperties.SignatureDate = ?(ValueIsFilled(SignatureProperties.UnverifiedSignatureDate),
		SignatureProperties.UnverifiedSignatureDate, CommonClient.SessionDate());
	
	If Context.CertificateValid <> Undefined Then
		SignatureProperties.SignatureValidationDate = SignatureProperties.SignatureDate;
		SignatureProperties.SignatureCorrect = Context.CertificateValid;
	EndIf;
	
	SignatureProperties.IsVerificationRequired = Context.IsVerificationRequired;
	
	Return SignatureProperties;
	
EndFunction

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterSigning(SignatureProperties, Context)
	
	DataElement = Context.DataElement;
	SignedObject = CommonClientServer.StructureProperty(DataElement, "Object", Undefined);
				
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If Context.OnClientSide And ValueIsFilled(Context.DataDetails.MachineReadableSigningLOACheckResult)
		And CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then

		ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule(
					"MachineReadableLettersOfAuthorityFTSInternalClient");
		ResultOfSignatureVerificationByMRLOA = ModuleMachineReadableLettersOfAuthorityFTSInternalClient.ResultOfSignatureVerificationByMRLOA(
			Context.DataDetails.SelectedLetterOfAuthority, 
			?(TypeOf(SignedObject) = Type("CallbackDescription"), Undefined, SignedObject),
			SignatureProperties.Certificate, Undefined, Context.DataDetails.MachineReadableSigningLOACheckResult);
		If ValueIsFilled(ResultOfSignatureVerificationByMRLOA) Then
			SignatureProperties.Insert("ResultOfSignatureVerificationByMRLOA", ResultOfSignatureVerificationByMRLOA);
		EndIf;

	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	DataElement.Insert("SignatureProperties", SignatureProperties);
	
	If SignedObject = Undefined Then
		DigitalSignatureInternalServerCall.RegisterDataSigningInLog(
			CurrentDataItemProperties(Context, SignatureProperties));
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	If TypeOf(SignedObject) <> Type("CallbackDescription") Then
		If Context.OnClientSide Then
			ObjectVersion = Undefined;
			DataElement.Property("ObjectVersion", ObjectVersion);
			SignatureProperties.Insert("SignatureID", New UUID);
			
			// StandardSubsystems.MachineReadableLettersOfAuthority
			
			If ValueIsFilled(Context.DataDetails.MachineReadableSigningLOACheckResult)
				And CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
				
				ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule(
					"MachineReadableLettersOfAuthorityFTSInternalClient");
				ResultOfSignatureVerificationByMRLOA = ModuleMachineReadableLettersOfAuthorityFTSInternalClient.ResultOfSignatureVerificationByMRLOA(
					Context.DataDetails.SelectedLetterOfAuthority, SignedObject,
					SignatureProperties.Certificate, Undefined, Context.DataDetails.MachineReadableSigningLOACheckResult);
				If ValueIsFilled(ResultOfSignatureVerificationByMRLOA) Then
					SignatureProperties.Insert("ResultOfSignatureVerificationByMRLOA", ResultOfSignatureVerificationByMRLOA);
				EndIf;
				
			EndIf;
			
			// End StandardSubsystems.MachineReadableLettersOfAuthority
			
			ErrorPresentation = DigitalSignatureInternalServerCall.AddSignature(
				SignedObject, SignatureProperties, Context.FormIdentifier, ObjectVersion);
			If ValueIsFilled(ErrorPresentation) Then
				DataElement.Delete("SignatureProperties");
				ErrorAtClient = New Structure("ErrorDescription", ErrorPresentation);
				ExecuteAtSideAfterLoop(ErrorAtClient, Context);
				Return;
			EndIf;
		EndIf;
		NotifyChanged(SignedObject);
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	DigitalSignatureInternalServerCall.RegisterDataSigningInLog(
		CurrentDataItemProperties(Context, SignatureProperties));
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New CallbackDescription(
		"ExecuteAtSideAfterRecordSignature", ThisObject, Context));
	
	Try
		RunCallback(SignedObject, ExecutionParameters);
	Except
		ErrorInfo = ErrorInfo();
		ExecuteAtSideAfterRecordSignature(New Structure("ErrorDescription",
			ErrorProcessing.BriefErrorDescription(ErrorInfo)), Context);
	EndTry;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterRecordSignature(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Context.DataElement.Delete("SignatureProperties");
		Error = New Structure("ErrorDescription",
			NStr("vi = 'Khi ghi lại chữ ký, đã xảy ra lỗi:';
				|ru = 'При записи подписи возникла ошибка:';
				|en = 'An error occurred when saving the signature:'; fa = 'An error occurred when saving the signature:';
				|it = 'Durante la registrazione della firma si è verificato un errore:';
				|pl = 'Podczas zapisu podpisu zaistniał błąd:';
				|tr = 'İmza kaydında hata oluştu:'") + Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterEncryption(EncryptedData, Context)
	
	DataElement = Context.DataElement;
	DataElement.Insert("EncryptedData", EncryptedData);
	
	If Not DataElement.Property("ResultPlacement")
	 Or TypeOf(DataElement.ResultPlacement) <> Type("CallbackDescription") Then
		
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New CallbackDescription(
		"ExecuteAtSideLoopAfterWriteEncryptedData", ThisObject, Context));
	
	Try
		RunCallback(DataElement.ResultPlacement, ExecutionParameters);
	Except
		ErrorInfo = ErrorInfo();
		ExecuteAtSideLoopAfterWriteEncryptedData(New Structure("ErrorDescription",
			ErrorProcessing.BriefErrorDescription(ErrorInfo)), Context);
	EndTry;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterWriteEncryptedData(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Context.DataElement.Delete("EncryptedData");
		Error = New Structure("ErrorDescription",
			NStr("vi = 'Không thể ghi lại dữ liệu đã mã hóa do nguyên nhân:';
				|ru = 'Не удалось записать зашифрованные данные по причине:';
				|en = 'Cannot save the encrypted data due to:'; fa = 'Cannot save the encrypted data due to:';
				|it = 'Не удалось записать зашифрованные данные по причине:';
				|pl = 'Cannot save the encrypted data due to:';
				|tr = 'Veri şifrelemesi şu sebeple kaydedilemedi:'")
			+ Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterDecrypt(DecryptedData, Context)
	
	DataElement = Context.DataElement;
	DataElement.Insert("DecryptedData", DecryptedData);
	
	If Not DataElement.Property("ResultPlacement")
	 Or TypeOf(DataElement.ResultPlacement) <> Type("CallbackDescription") Then
	
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New CallbackDescription(
		"ExecuteAtSideLoopAfterWriteDecryptedData", ThisObject, Context));
	
	Try
		RunCallback(DataElement.ResultPlacement, ExecutionParameters);
	Except
		ErrorInfo = ErrorInfo();
		ExecuteAtSideLoopAfterWriteEncryptedData(New Structure("ErrorDescription",
			ErrorProcessing.BriefErrorDescription(ErrorInfo)), Context);
	EndTry;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterWriteDecryptedData(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Context.DataElement.Delete("DecryptedData");
		Error = New Structure("ErrorDescription",
			NStr("vi = 'Không thể ghi lại dữ liệu đã mã hóa do nguyên nhân:';
				|ru = 'Не удалось записать расшифрованные данные по причине:';
				|en = 'Cannot save the decrypted data due to:'; fa = 'Cannot save the decrypted data due to:';
				|it = 'Не удалось записать расшифрованные данные по причине:';
				|pl = 'Cannot save the decrypted data due to:';
				|tr = 'Veri şifrelemesi şu sebeple kaydedilemedi:'")
			+ Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterLoop(Error, Context)
	
	Result = New Structure;
	If Error <> Undefined Then
		Result.Insert("Error", Error);
		If Context.Operation = "Details" Then
			HandleDecryptionError(Error, Context);
		EndIf;
	EndIf;
	
	If Context.OperationStarted Then
		Result.Insert("OperationStarted");
		
		If Not Result.Property("Error") And Context.IndexOf > 0 Then
			Result.Insert("HasProcessedDataItems");
		EndIf;
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Returns:
//  Structure:
//   * Notification - CallbackDescription
//   * Operation - String
//   * OnClientSide - Boolean
//   * OperationStarted - Boolean
//   * DataDetails - Structure
//   * Form - ClientApplicationForm
//   * FormIdentifier - UUID
//   * PasswordValue - String
//   * CertificateValid - Undefined
//                     - Boolean
//   * IsVerificationRequired - Undefined
//                       - Boolean
//   * AddressOfCertificate - String
//   * CurrentPresentationsList - ValueList
//                                - Array
//   * FullDataPresentation - String
//   * CryptoManager - CryptoManager
//                          - String
//   * CryptoCertificate - CryptoCertificate
//   * IndexOf - Number
//   * CertificatesProperties - Structure
//   * EncryptionCertificates - Array
//
Function ExecuteANewContextOnTheSide()
	
	Return New Structure("DataDetails, Form, FormIdentifier, PasswordValue,
		|CertificateValid, IsVerificationRequired, AddressOfCertificate, CurrentPresentationsList, FullDataPresentation");
	
EndFunction

// For internal use only.
Function CurrentDataItemProperties(ExecutionParameters, SignatureProperties = Undefined) Export
	
	If ExecutionParameters.DataDetails.Property("Data")
	 Or Not ExecutionParameters.DataDetails.Property("CurrentDataSetItem") Then
		
		DataItemPresentation = ExecutionParameters.CurrentPresentationsList[0].Value;
	Else
		DataItemPresentation = ExecutionParameters.CurrentPresentationsList[
			ExecutionParameters.DataDetails.DataSet.Find(
				ExecutionParameters.DataDetails.CurrentDataSetItem)].Value;
	EndIf;
	
	If TypeOf(DataItemPresentation) = Type("CallbackDescription") Then
		DataItemPresentation = ExecutionParameters.FullDataPresentation;
	EndIf;
	
	If SignatureProperties = Undefined Then
		SignatureProperties = New Structure;
		SignatureProperties.Insert("Certificate",  ExecutionParameters.AddressOfCertificate);
		SignatureProperties.Insert("SignatureDate", '00010101');
	EndIf;
	
	DataItemProperties = New Structure;
	
	DataItemProperties.Insert("SignatureProperties",     SignatureProperties);
	DataItemProperties.Insert("DataPresentation", DataItemPresentation);
	
	Return DataItemProperties;
	
EndFunction

// For internal use only.
Procedure GetDataFromDataDetails(Notification, Form, DataDetails, DataSource, ForClientSide) Export
	
	Context = New Structure;
	Context.Insert("Form", Form);
	Context.Insert("Notification", Notification);
	Context.Insert("ForClientSide", ForClientSide);
	
	If TypeOf(DataSource) = Type("CallbackDescription") Then
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification",  New CallbackDescription(
			"GetDataFromDataDetailsContinued", ThisObject, Context));
		
		Try
			RunCallback(DataSource, ExecutionParameters);
		Except
			ErrorInfo = ErrorInfo();
			Result = New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
			GetDataFromDataDetailsContinued(Result, Context);
		EndTry;
	Else
		GetDataFromDataDetailsContinued(New Structure("Data", DataSource), Context);
	EndIf;
	
EndProcedure

// Continue the GetDataFromDataDetails procedure.
Procedure GetDataFromDataDetailsContinued(Result, Context) Export
	
	IsXMLDSig = (TypeOf(Result) = Type("Structure")
		And Result.Property("Data")
		And TypeOf(Result.Data) = Type("Structure")
		And Result.Data.Property("XMLDSigParameters"));
	
	If IsXMLDSig And Not Result.Data.Property("XMLEnvelope") Then
		Result.Data = New Structure(New FixedStructure(Result.Data));
		Result.Data.Insert("XMLEnvelope", Result.Data.SOAPEnvelope);
	EndIf;
	
	IsCMS = (TypeOf(Result) = Type("Structure")
		And Result.Property("Data")
		And TypeOf(Result.Data) = Type("Structure")
		And Result.Data.Property("CMSParameters"));
	
	If TypeOf(Result) <> Type("Structure")
		Or Not Result.Property("Data")
		Or TypeOf(Result.Data) <> Type("BinaryData")
		And TypeOf(Result.Data) <> Type("String")
		And Not IsXMLDSig
		And Not IsCMS Then
		
		If TypeOf(Result) <> Type("Structure") Or Not Result.Property("ErrorDescription") Then
			Error = New Structure("ErrorDescription", NStr("vi = 'Sai kiểu dữ liệu.';
															|ru = 'Некорректный тип данных.';
															|en = 'Invalid data type.'; fa = 'Invalid data type.';
															|it = 'Tipo di dati errato.';
															|pl = 'Nieprawidłowy typ danych.';
															|tr = 'Geçersiz veri türü.'"));
		Else
			Error = New Structure("ErrorDescription", Result.ErrorDescription);
		EndIf;
		RunCallback(Context.Notification, Error);
		Return;
	EndIf;
	
	Data = Result.Data;
	
	If Context.ForClientSide Then
		// The client side requires binary data or file path.
		
		If TypeOf(Data) = Type("BinaryData")
			Or IsXMLDSig
			Or IsCMS Then
			
			RunCallback(Context.Notification, Data);
			
		ElsIf IsTempStorageURL(Data) Then
			Try
				CurrentResult = GetFromTempStorage(Data);
			Except
				ErrorInfo = ErrorInfo();
				CurrentResult = New Structure("ErrorDescription",
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
			EndTry;
			RunCallback(Context.Notification, CurrentResult);
			
		Else // File path
			RunCallback(Context.Notification, Data);
		EndIf;
	Else
		// The server side requires a binary data address in the temporary storage.
		
		If TypeOf(Data) = Type("BinaryData")
			Or IsXMLDSig Then
			
			RunCallback(Context.Notification,
				PutToTempStorage(Data, Context.Form.UUID));
			
		ElsIf IsCMS Then
			
			Data.CMSParameters.IncludeCertificatesInSignature =
				IncludingCertificatesInSignatureAsString(
					Data.CMSParameters.IncludeCertificatesInSignature);
			
			RunCallback(Context.Notification,
				PutToTempStorage(Data, Context.Form.UUID));
			
		ElsIf IsTempStorageURL(Data) Then
			RunCallback(Context.Notification, Data);
			
		Else // File path
			
			GetDataFromDataDetailImportFromFileFollowUp(Data, Context);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Async Procedure GetDataFromDataDetailImportFromFileFollowUp(Data, Context, RepeatedCall = False)
	
	If Not RepeatedCall Then
		RetryCallParameters = New Structure("Data, Context", Data, Context);
		NotificationWhenDigitalSignatureAddInsMissing = New CallbackDescription(
			"ReGetDataFromDataDetailImportFromFileFollowUpAfterAddInsInstalled", ThisObject, RetryCallParameters);
		IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(
			NotificationWhenDigitalSignatureAddInsMissing);
		If IsInstallingAddIns Then
			Return;
		EndIf;
	EndIf;
	
	Try
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.FormIdentifier = Context.Form.UUID;
		ImportParameters.Interactively = False;
		FileSystemClient.ImportFile_(New CallbackDescription(
			"GetDataFromDataDetailsCompletion", ThisObject, Context,
			"GetDataFromDataDescriptionCompletionOnError", ThisObject),
			ImportParameters, Data); 
	Except
		ErrorInfo = ErrorInfo();
		CurrentResult = New Structure("ErrorDescription",
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		RunCallback(Context.Notification, CurrentResult);
	EndTry;
	
EndProcedure

Procedure ReGetDataFromDataDetailImportFromFileFollowUpAfterAddInsInstalled(Result, RetryCallParameters) Export
	
	If Result = True Then
		GetDataFromDataDetailImportFromFileFollowUp(RetryCallParameters.Data,
			RetryCallParameters.Context, True);
	EndIf;
	
EndProcedure

// Continue the GetDataFromDataDetails procedure.
Procedure GetDataFromDataDescriptionCompletionOnError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Result = New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Continue the GetDataFromDataDetails procedure.
Procedure GetDataFromDataDetailsCompletion(PlacedFiles, Context) Export
	
	If PlacedFiles = Undefined Or PlacedFiles.Count() = 0 Then
		Result = New Structure("ErrorDescription",
			NStr("vi = 'Người sử dụng đã hủy việc chuyển dữ liệu.';
				|ru = 'Передача данных отменена пользователем.';
				|en = 'User canceled data transfer.'; fa = 'User canceled data transfer.';
				|it = 'Il trasferimento di dati è stato annullato dall''utente.';
				|pl = 'Transfer danych anulowany przez użytkownika.';
				|tr = 'Veri aktarımı kullanıcı tarafından iptal edildi.'"));
	Else
		Result = PlacedFiles[0].Location;
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// For internal use only.
Procedure ExtendStoringOperationContext(DataDetails) Export
	
	PassParametersForm().ExtendStoringOperationContext(DataDetails.OperationContext);
	
EndProcedure

#EndRegion

#Region EnhanceSignature

Procedure EnhanceSignature(Context) Export
	
	If Not ValueIsFilled(Context.ExecutionParameters.DataDetails.Signature) Then
		Raise NStr("vi = 'Tham số đã chuyển không chứa dữ liệu chữ ký.';
					|ru = 'Переданные параметры не содержат данных подписи.';
					|en = 'Passed parameters do not contain signature data.'; fa = 'Passed parameters do not contain signature data.';
					|it = 'I parametri trasferiti non contengono dati di firma.';
					|pl = 'Przekazane parametry nie zawierają danych podpisu.';
					|tr = 'Aktarılan parametreler imza verileri içermez.'");
	EndIf;
	
	If DigitalSignatureClient.CommonSettings().ThisistheServiceModelwithEnhancementAvailable 
		And Context.ExecutionParameters.DataDetails.SignatureType = 
			PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST") Then
		
		SettingsConnectionService = 
			DigitalSignatureInternalServerCall.ServiceAccountSettingsToImproveSignatures(
				Context.ExecutionParameters.FormIdentifier);
		If ValueIsFilled(SettingsConnectionService.Error) Then
			CallbackDescription = New CallbackDescription("ContinueImproveAfterAnsweringQuestion", ThisObject, Context);
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nâng cấp chữ ký điện tử thông qua ứng dụng trên Internet:
				|%1
				|Tiếp tục nâng cấp thông qua các ứng dụng đã cài đặt trên máy tính?';
				|ru = 'Невозможно усовершенствовать электронную подпись с помощью приложения в Интернете:
				|%1
				|Продолжить усовершенствование с помощью приложений, установленных на компьютере?';
				|en = 'Unable to enhance the signature using the web application:
				|%1
				|Do you want to continue enhancement using a local application?'; fa = 'Unable to enhance the signature using the web application:
				|%1
				|Do you want to continue enhancement using a local application?';
				|it = 'Unable to enhance the signature using the web application:
				|%1
				|Do you want to continue enhancement using a local application?';
				|pl = 'Unable to enhance the signature using the web application:
				|%1
				|Do you want to continue enhancement using a local application?';
				|tr = 'İnternetteki uygulamalar yardımıyla dijital imzayı geliştirmek mümkün değildir:
				|%1
				|Bilgisayarınızda yüklü olan uygulamaları kullanarak geliştirmeye devam etmek istiyor musunuz?'"),
				SettingsConnectionService.Error);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, 60);
			Return;
		EndIf;
		
		Context.ExecutionParameters.Insert("ThisistheServiceModelwithEnhancementAvailable", True);
		Context.ExecutionParameters.Insert("ServiceAccountDSS", SettingsConnectionService.ServiceAccountDSS);
		Context.ExecutionParameters.Insert("ParametersSignatureCAdEST", SettingsConnectionService.ParametersSignatureCAdEST);
		
		RefineSide(New CallbackDescription(
			"RefineAfterRunningServerSide", DigitalSignatureInternalClient, Context),
			"AtServerSide", Context.ExecutionParameters);

	ElsIf DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
		RefineSide(New CallbackDescription(
			"RefineAfterRunningServerSide", DigitalSignatureInternalClient, Context),
			"AtServerSide", Context.ExecutionParameters);
	Else
		RefineAfterRunningServerSide(Undefined, Context);
	EndIf;
	
EndProcedure 

Procedure ContinueImproveAfterAnsweringQuestion(QuestionResult, Context) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		RefineAfterRunningServerSide(Undefined, Context);
	Else
		Result = New Structure;
		Result.Insert("Error", True);
		Result.Insert("ErrorText", NStr("vi = 'Không thể nâng cấp chữ ký điện tử bằng ứng dụng trong Internet';
										|ru = 'Невозможно усовершенствовать электронную подпись с помощью приложения в Интернете';
										|en = 'Unable to enhance the digital signature using the web application'; fa = 'Unable to enhance the digital signature using the web application';
										|it = 'Unable to enhance the digital signature using the web application';
										|pl = 'Unable to enhance the digital signature using the web application';
										|tr = 'İnternetteki uygulamalar yardımıyla dijital imzayı geliştirmek mümkün değildir'"));
		RefineAfterExecutionOnClientSide(Result, Context);
	EndIf;
	
EndProcedure

Procedure RefineSide(Notification, ExecutionSide, ExecutionParameters)

	Context = New Structure("DataDetails, FormIdentifier");
	Context.Insert("AbortArrayProcessingOnError",  True);
	Context.Insert("ShouldIgnoreCertificateValidityPeriod", False);
	Context.Insert("PerformCAVerification",
		DigitalSignatureInternalClientServer.NotVerifyCertificate());
	FillPropertyValues(Context, ExecutionParameters);
	
	If ExecutionParameters.Property("ThisistheServiceModelwithEnhancementAvailable") Then
		Context.Insert("ThisistheServiceModelwithEnhancementAvailable", True);
		Context.Insert("ServiceAccountDSS", ExecutionParameters.ServiceAccountDSS);
		Context.Insert("ParametersSignatureCAdEST", ExecutionParameters.ParametersSignatureCAdEST);
	Else
		Context.Insert("ThisistheServiceModelwithEnhancementAvailable", False);
	EndIf;
	
	Context.Insert("Notification",       Notification);
	Context.Insert("OnClientSide", ExecutionSide = "OnClientSide");
	Context.Insert("OperationStarted", False);
	Context.Insert("HasErrors", False);
	Context.Insert("ErrorsCreatingCryptographyManager", New Array);
	
	If ExecutionParameters.Property("DataItems") Then
		Context.Insert("DataItems", ExecutionParameters.DataItems);
	Else
		If TypeOf(Context.DataDetails.Signature) = Type("Array") Then
			Signatures = Context.DataDetails.Signature;
		Else
			Signatures = New Array;
			Signatures.Add(Context.DataDetails.Signature);
		EndIf;
		
		TypeDataItem = TypeOf(Signatures[0]); // All must be of the same type.
		
		If TypeDataItem = Type("Structure") Then
			DataItems = DigitalSignatureInternalServerCall.ConvertSignaturestoArray(Signatures,
				Context.FormIdentifier);
		Else
			DataItems = New Array;
			For Each CurrentItem In Signatures Do
				DataItems.Add(New Structure("Signature, SignatureType, DateActionLastTimestamp", CurrentItem));
			EndDo;
		EndIf;
		Context.Insert("DataItems", DataItems);
	EndIf;
	
	Context.Insert("IndexOf", -1);
	RefineSideLoopStart(Context);
	
EndProcedure 

// Continuation of the EnhancedOnSide procedure.
// 
// Parameters:
//  Context - Structure:
//   * IndexOf - Number
//
Procedure RefineSideLoopStart(Context)
	
	If Context.DataItems.Count() <= Context.IndexOf + 1 Then
		RefineOnSideAfterCycle(Context);
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"RefineSideLoopStartContinued", ThisObject, Context);
	
	StandardSubsystemsClient.StartNotificationProcessing(Notification);
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
// 
// Parameters:
//  Context - Structure:
//   * IndexOf - Number
//
Procedure RefineSideLoopStartContinued(Result, Context) Export
	
	Context.IndexOf = Context.IndexOf + 1;
	DataElement = Context.DataItems[Context.IndexOf];
	
	If DataElement.Property("SignatureProperties") Then
		RefineSideLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("DataElement", DataElement);
	
	Signature = DataElement.Signature;
		
	If Context.OnClientSide Then
		// The client side requires binary data. 
		If TypeOf(Signature) = Type("String") Then
			Try
				Signature = GetFromTempStorage(Signature);
			Except
				Error = DescriptionBugsUpgraded();
				Error.Text = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				RefineSideAfterError(Error, Context);
				Return;
			EndTry;
		EndIf;
		
		DataElement.Signature = Signature;

		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = Undefined;
		If DataElement.Property("SignAlgorithm") Then
			CreationParameters.SignAlgorithm = DataElement.SignAlgorithm;
		Else
			CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Signature);
			Context.DataItems[Context.IndexOf].Insert("SignAlgorithm", CreationParameters.SignAlgorithm);
		EndIf;
		
		CreateCryptoManager(New CallbackDescription(
			"RefineOnTheSideAfterCreationCryptographyManager", ThisObject, Context),
			"ExtensionValiditySignature", CreationParameters);

		Return;
		
	EndIf;
	
	RefineOnServer(DataElement, Context);

EndProcedure 

// Continuation of the EnhancedOnSide procedure.
Procedure RefineOnServer(DataElement, Context)

	Signature = Context.DataElement.Signature;

	ParametersForServer = New Structure;
	ParametersForServer.Insert("ThisistheServiceModelwithEnhancementAvailable",
		Context.ThisistheServiceModelwithEnhancementAvailable);
		
	ParametersForServer.Insert("FormIdentifier", Context.FormIdentifier);
	ParametersForServer.Insert("DataItemForSErver", DataElement);
	ParametersForServer.Insert("SignatureType", Context.DataDetails.SignatureType);
	ParametersForServer.Insert("AddArchiveTimestamp", Context.DataDetails.AddArchiveTimestamp);
	ParametersForServer.Insert("OperationStarted", Context.OperationStarted);
	ParametersForServer.Insert("ShouldIgnoreCertificateValidityPeriod", Context.ShouldIgnoreCertificateValidityPeriod);
	ParametersForServer.Insert("PerformCAVerification", Context.PerformCAVerification);
	
	If ParametersForServer.ThisistheServiceModelwithEnhancementAvailable Then
		
		ParametersForServer.DataItemForSErver.Signature = Signature;
		ParametersForServer.Insert("ParametersSignatureCAdEST", Context.ParametersSignatureCAdEST);
		ParametersForServer.Insert("ServiceAccountDSS", Context.ServiceAccountDSS);
		
		TimeConsumingOperation = DigitalSignatureInternalServerCall.StartImprovementOnServer(
			ParametersForServer);
			
		If Not TimeConsumingOperation.Property("ResultAddress") Then
			ContinueAfterImprovementsOnServer(TimeConsumingOperation, Context);
			Return;
		EndIf;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
		IdleParameters.OutputIdleWindow = True;
		
		CallbackOnCompletion = New CallbackDescription("ResumeAfterImprovementOperationAtServer", ThisObject, Context);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	Else
		// The server side requires a binary data address in the temporary storage.
		If TypeOf(Signature) = Type("BinaryData") Then
			ParametersForServer.DataItemForSErver.Signature = PutToTempStorage(Signature, Context.FormIdentifier);
		EndIf;
		
		Result = DigitalSignatureInternalServerCall.EnhanceServerSide(ParametersForServer);
		ContinueAfterImprovementsOnServer(Result, Context);
	EndIf;
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
// 
// Parameters:
//   ExecutionResult - See TimeConsumingOperationsClient.NewResultLongOperation
//  Context - Structure
//
Procedure ResumeAfterImprovementOperationAtServer(ExecutionResult, Context) Export
	
	If ExecutionResult = Undefined Then
		ErrorAtServer = DescriptionBugsUpgraded(False);
		ErrorAtServer.Text = NStr("vi = 'Chưa hoàn tất cải thiện chữ ký bằng nhiệm vụ thường kỳ theo cách thông thường';
									|ru = 'Усовершенствование подписи фоновым заданием не было завершено штатно';
									|en = 'The signature enhancement by the background job was not completed correctly'; fa = 'The signature enhancement by the background job was not completed correctly';
									|it = 'Усовершенствование подписи фоновым заданием не было завершено штатно';
									|pl = 'The signature enhancement by the background job was not completed correctly';
									|tr = 'Arka plan işine göre imza geliştirme normal şekilde tamamlanmadı'");
		RefineSideAfterError(ErrorAtServer, Context);
		Return;
	EndIf;
	
	If ExecutionResult.Status = "Error" Then
		ErrorAtServer = DescriptionBugsUpgraded(False);
		ErrorAtServer.Text = ErrorProcessing.BriefErrorDescription(ExecutionResult.ErrorInfo);
		RefineSideAfterError(ErrorAtServer, Context);
		Return;
	EndIf;
	
	// Background job result.
	Try
		Result = GetFromTempStorage(ExecutionResult.ResultAddress);
		If Not ValueIsFilled(Result) Then
			ErrorText = NStr("vi = 'Nhiệm vụ nền không trả về kết quả';
							|ru = 'Фоновое задание не вернуло результат';
							|en = 'The background job did not return a result'; fa = 'The background job did not return a result';
							|it = 'Compito in background non ha restituito il risultato';
							|pl = 'Zadanie w tle nie zwróciło wyniku';
							|tr = 'Arka plan görevi sonuç vermedi'");
			Raise ErrorText;
		EndIf;
	Except
		ErrorAtServer = DescriptionBugsUpgraded(False);
		ErrorAtServer.Text = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		RefineSideAfterError(ErrorAtServer, Context);
		Return;
	EndTry;
	
	DeleteFromTempStorage(ExecutionResult.ResultAddress);
	ContinueAfterImprovementsOnServer(Result, Context);
	
EndProcedure

// Continues the EnhancedOnSide procedure.
// 
// Parameters:
//  ExecutionResult - Structure:
//   * Success
//   * ErrorText
//   * SignatureProperties
//   * SignAlgorithm
//   * ErrorCreatingCryptoManager
//   * OperationStarted
//  Context - Structure
//
Procedure ContinueAfterImprovementsOnServer(Result, Context)
	
	Context.OperationStarted = Result.OperationStarted;
	
	If Result.Property("SignAlgorithm") And ValueIsFilled(Result.SignAlgorithm) Then
		Context.DataItems[Context.IndexOf].Insert("SignAlgorithm", Result.SignAlgorithm);
	EndIf;
	
	If Not Result.Success Then
		ErrorAtServer = DescriptionBugsUpgraded(False);
		ErrorAtServer.Text = Result.ErrorText;
		If Result.ErrorCreatingCryptoManager = True Then
			ErrorAtServer.ErrorCreatingCryptographyManager = True;
		EndIf;
		RefineSideAfterError(ErrorAtServer, Context);
	Else
		RunOnSideLoopAfterImprove(Result.SignatureProperties, Context);
	EndIf;
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
Procedure RefineOnTheSideAfterCreationCryptographyManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		Error = DescriptionBugsUpgraded();
		Error.Text = CryptoManager.ErrorDescription;
		Error.ErrorCreatingCryptographyManager = True;
		RefineSideAfterError(Error, Context);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	Signature = Context.DataElement.Signature;
	
	Notification = New CallbackDescription("Refineonthesideafterreceivingthecontainersignature", ThisObject, Context,
		"ImproveOnSideLoopAfterErrorOperationsOnClient", ThisObject);
	CryptoManager.BeginGettingCryptoSignaturesContainer(Notification, Signature);

EndProcedure

// Continuation of the EnhancedOnSide procedure.
Async Procedure Refineonthesideafterreceivingthecontainersignature(ContainerSignatures, Context) Export
	
	SessionDate = CommonClient.SessionDate();
	UTCOffset = SessionDate - CommonClient.UniversalDate();
	SignatureParameters = Await ParametersCryptoSignatures(
		ContainerSignatures, UTCOffset, SessionDate);
	
	Context.DataElement.Insert("SignatureParameters", SignatureParameters);
	
	If SignatureParameters.CertificateLastTimestamp = Undefined Then
		ErrorDescription = NStr("vi = 'Không thể nhận chứng thư chữ ký';
								|ru = 'Не удалось получить сертификат подписи';
								|en = 'Cannot get the signature certificate'; fa = 'Cannot get the signature certificate';
								|it = 'Не удалось получить сертификат подписи';
								|pl = 'Cannot get the signature certificate';
								|tr = 'İmza sertifikası alınamadı'");
		Context.DataElement.Insert("Error", ErrorDescription);
		RefineSideLoopAfterOperationClient(SignatureParameters, Context);
		Return;
	EndIf;
	
	If Not Context.ShouldIgnoreCertificateValidityPeriod
		And ValueIsFilled(SignatureParameters.DateActionLastTimestamp)
		And SignatureParameters.DateActionLastTimestamp < SessionDate Then 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã quá hạn hiệu lực chứng chỉ chữ ký: %1';
				|ru = 'Истек срок действия сертификата подписи: %1';
				|en = 'Certificate expired:%1'; fa = 'Certificate expired:%1';
				|it = 'È scaduto il periodo di validità del certificato: %1';
				|pl = 'Upłynął termin ważności certyfikatu podpisu: %1';
				|tr = 'İmza sertifikasının geçerlilik dönemi sona erdi: %1'"),
			PropertiesCertificateString(SignatureParameters.CertificateLastTimestamp));
		Context.DataElement.Insert("Error", ErrorDescription);
		RefineSideLoopAfterOperationClient(SignatureParameters, Context);
		
		Return;
	EndIf;
	
	If SignatureParameters.CertificateLastTimestamp <> Undefined Then
		Notification = New CallbackDescription("RefineSideAfterVerifyingCertificateSignature", ThisObject, Context);
		CheckParameters = AdditionalCertificateVerificationParameters();
		CheckParameters.PerformCAVerification = Context.PerformCAVerification;
		CheckCertificate(Notification, SignatureParameters.CertificateLastTimestamp, Context.CryptoManager,,CheckParameters);
	Else
		RefineSideAfterVerifyingCertificateSignature(True, Context);
	EndIf;

EndProcedure

// Continuation of the EnhancedOnSide procedure.
Procedure RefineSideAfterVerifyingCertificateSignature(Result, Context) Export
	
	SignatureParameters = Context.DataElement.SignatureParameters;
	
	If Result <> True Then
		Error = DescriptionBugsUpgraded();
		Error.Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi kiểm tra chứng chỉ chữ ký trước khi nâng cấp: %1
			|%2';
			|ru = 'При проверке сертификата подписи до усовершенствования: %1
			|%2';
			|en = 'When checking the signature certificate before enhancement: %1
			|%2'; fa = 'When checking the signature certificate before enhancement: %1
			|%2';
			|it = 'Durante la verifica del certificato di firma fino al perfezionamento: %1
			|%2';
			|pl = 'Podczas sprawdzenia certyfikatu podpisu przed udoskonaleniem: %1
			|%2';
			|tr = 'Geliştirme öncesi imza sertifikasının denetlenmesi sırasında: %1
			|%2'"), Result, PropertiesCertificateString(SignatureParameters.CertificateLastTimestamp));
		RefineSideAfterError(Error, Context);
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"RefineSideLoopAfterOperationClient", ThisObject, Context,
		"ImproveOnSideLoopAfterErrorOperationsOnClient", ThisObject); 
	
	CryptoManager = Context.CryptoManager;
	CryptoManager.TimestampServersAddresses = 
		DigitalSignatureClient.CommonSettings().TimestampServersAddresses;
		
	Signature = Context.DataElement.Signature;
	
	If SignatureParameters.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3")
		Or SignatureParameters.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.CAdESAv2") Then
		If Context.DataDetails.AddArchiveTimestamp Then
			CryptoManager.BeginAddingArchiveTimestamp(Notification, Signature);
		Else
			RefineSideLoopAfterOperationClient(SignatureParameters, Context);
			Return;
		EndIf;
	ElsIf ValueIsFilled(Context.DataDetails.SignatureType)
		And DigitalSignatureInternalClientServer.ToBeImproved(SignatureParameters.SignatureType, Context.DataDetails.SignatureType) Then
			CryptoManager.BeginEnhancingSignature(Notification, Signature,
				DigitalSignatureInternalClientServer.CryptoSignatureType(Context.DataDetails.SignatureType));
	Else
		RefineSideLoopAfterOperationClient(SignatureParameters, Context);
		Return;
	EndIf;
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
// 
// Parameters:
//   BinaryData - BinaryData
//                  - Structure - Parameters of the signature that cannot be upgraded.
//   Context - Structure
//
Procedure RefineSideLoopAfterOperationClient(BinaryData, Context) Export
	
	If TypeOf(BinaryData) = Type("Structure") Then 
		// Signature wasn't renewed. Probably, need to write the passed signature data.
		Context.DataElement.Insert("NotRequiredExtension", True);
		RunOnSideLoopAfterImprove(BinaryData, Context);
		Return;
	EndIf;
		
	ErrorDescription = "";
	If DigitalSignatureInternalClientServer.BlankSignatureData(BinaryData, ErrorDescription) Then
		Error = DescriptionBugsUpgraded();
		Error.Text = ErrorDescription;
		RefineSideAfterError(Error, Context);
		Return;
	EndIf;
	
	Context.OperationStarted = True;
	Context.DataElement.Insert("SignatureProperties", New Structure("Signature", BinaryData));

	Notification = New CallbackDescription("ExecuteAfterGettingEnhancedSignatureContainer", ThisObject, Context, 
		"ImproveOnSideLoopAfterErrorOperationsOnClient", ThisObject);
	Context.CryptoManager.BeginGettingCryptoSignaturesContainer(Notification, BinaryData);

EndProcedure

// Continues the EnhancedOnSide procedure.
Async Procedure ExecuteAfterGettingEnhancedSignatureContainer(ContainerSignatures, Context) Export

	SessionDate = CommonClient.SessionDate();
	UTCOffset = SessionDate - CommonClient.UniversalDate();
	SignatureParameters = Await ParametersCryptoSignatures(
			ContainerSignatures, UTCOffset, SessionDate);
			
	Context.DataElement.Insert("SignatureParameters", SignatureParameters);

	If SignatureParameters.CertificateLastTimestamp <> Undefined Then
		Notification = New CallbackDescription("ExecuteOnSideAfterImprovementAndCertificateVerification", ThisObject, Context); 
		CheckCertificate(Notification, SignatureParameters.CertificateLastTimestamp, Context.CryptoManager);
	Else
		SignatureProperties = New Structure;
		SignatureProperties.Insert("Signature",             Context.DataElement.SignatureProperties.Signature);
		SignatureProperties.Insert("SignatureType",          SignatureParameters.SignatureType);
		SignatureProperties.Insert("DateActionLastTimestamp", SignatureParameters.DateActionLastTimestamp);
		SignatureProperties.Insert("DateSignedFromLabels", SignatureParameters.DateSignedFromLabels);
		SignatureProperties.Insert("CertificateDetails", SignatureParameters.CertificateDetails);
		SignatureProperties.Insert("SignatureDate",
			?(ValueIsFilled(SignatureParameters.UnverifiedSignatureDate),
			SignatureParameters.UnverifiedSignatureDate, SignatureParameters.DateSignedFromLabels));

		RunOnSideLoopAfterImprove(SignatureProperties, Context);
	EndIf;
	
EndProcedure

// Continues the EnhancedOnSide procedure.
Procedure ExecuteOnSideAfterImprovementAndCertificateVerification(Result, Context) Export
	
	SignatureParameters = Context.DataElement.SignatureParameters;
	
	SignatureProperties = New Structure;
	SignatureProperties.Insert("Signature",             Context.DataElement.SignatureProperties.Signature);
	SignatureProperties.Insert("SignatureType",          SignatureParameters.SignatureType);
	SignatureProperties.Insert("DateActionLastTimestamp", SignatureParameters.DateActionLastTimestamp);
	SignatureProperties.Insert("CertificateDetails", SignatureParameters.CertificateDetails);
	SignatureProperties.Insert("DateSignedFromLabels", SignatureParameters.DateSignedFromLabels);
	SignatureProperties.Insert("SignatureDate",
			?(ValueIsFilled(SignatureParameters.UnverifiedSignatureDate),
			SignatureParameters.UnverifiedSignatureDate, SignatureParameters.DateSignedFromLabels));
	
	If Result = True Then
		RunOnSideLoopAfterImprove(SignatureProperties, Context);
	Else
		Error = DescriptionBugsUpgraded();
		Error.Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi kiểm tra chứng chỉ chữ ký sau khi nâng cấp: %1
			|%2';
			|ru = 'При проверке сертификата подписи после усовершенствования: %1
			|%2';
			|en = 'When checking the signature certificate after enhancement: %1
			|%2'; fa = 'When checking the signature certificate after enhancement: %1
			|%2';
			|it = 'Durante la verifica del certificato di firma dopo il perfezionamento: %1
			|%2';
			|pl = 'Podczas sprawdzenia certyfikatu podpisu po udoskonaleniu: %1
			|%2';
			|tr = 'Geliştirme sonrası imza sertifikasının denetlenmesi sırasında: %1
			|%2'"), Result, PropertiesCertificateString(SignatureParameters.CertificateLastTimestamp));
		RefineSideAfterError(Error, Context);
	EndIf;
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
Procedure ImproveOnSideLoopAfterErrorOperationsOnClient(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Error = DescriptionBugsUpgraded();
	Error.Text = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	RefineSideAfterError(Error, Context);
	
EndProcedure

// Continues the EnhancedOnSide procedure.
Procedure RunOnSideLoopAfterImprove(SignatureProperties, Context)

	DataElement = Context.DataItems[Context.IndexOf];
	
	If Context.OnClientSide Then
		
		NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
		FillPropertyValues(NewSignatureProperties, SignatureProperties);
		UpdateSignature = False;
		
		If Context.DataElement.Property("NotRequiredExtension") Then 
			If DataElement.SignatureType <> SignatureProperties.SignatureType Then
				DataElement.SignatureType = SignatureProperties.SignatureType;
				UpdateSignature = True;
			EndIf;
			If DataElement.DateActionLastTimestamp <> SignatureProperties.DateActionLastTimestamp Then
				DataElement.DateActionLastTimestamp = SignatureProperties.DateActionLastTimestamp;
				UpdateSignature = True;
			EndIf;
		Else
			UpdateSignature = True;
		EndIf;
		
		DataElement.Insert("SignatureProperties", NewSignatureProperties);
		
		If Not DataElement.Property("SignedObject") Then
			RefineSideLoopStart(Context);
			Return;
		EndIf;
		
		If UpdateSignature Then
			DataElement.SignatureProperties.SignedObject = DataElement.SignedObject;
			DataElement.SignatureProperties.SequenceNumber = DataElement.SequenceNumber;
			
			ErrorPresentation = DigitalSignatureInternalServerCall.UpdateAdvancedSignature(
				DataElement.SignatureProperties);
			
			If ValueIsFilled(ErrorPresentation) Then
				DataElement.Delete("SignatureProperties");
				Error = DescriptionBugsUpgraded();
				Error.Text = ErrorPresentation;
				RefineSideAfterError(Error, Context);
				Return;
			EndIf;
			
			If ValueIsFilled(DataElement.SignatureProperties.Signature) Then
				DigitalSignatureInternalServerCall.RegisterImprovementSignaturesInJournal(
					DataElement.SignatureProperties);
			EndIf;
		EndIf;
		
	Else

		DataElement.Insert("SignatureProperties", SignatureProperties);
		
	EndIf;

	NotifyChanged(DataElement.SignedObject);
	RefineSideLoopStart(Context);
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
Procedure RefineSideAfterError(Error, Context)
	
	Context.HasErrors = True;
	
	DataElement = Context.DataItems[Context.IndexOf];
	If Not DataElement.Property("Error") Then
		DataElement.Insert("Error", "");
	EndIf;
	
	ErrorText = Error.Text;
	If Not Context.AbortArrayProcessingOnError Then
		
		If Error.ErrorCreatingCryptographyManager Then
			ErrorsCreatingCryptographyManager = Context.ErrorsCreatingCryptographyManager;
			If ErrorsCreatingCryptographyManager.Find(ErrorText) = Undefined Then
				ErrorsCreatingCryptographyManager.Add(ErrorText);
			EndIf;
		EndIf;
		
		DataElement.Error = DataElement.Error + ?(DataElement.Error <> "", Chars.LF, "")
		+ ?(Error.AtClient, NStr("vi = 'Trên máy tính:';
								|ru = 'На компьютере:';
								|en = 'On computer:'; fa = 'On computer:';
								|it = 'Sul computer:';
								|pl = 'Na komputerze:';
								|tr = 'Bilgisayarda:'"), NStr("vi = 'Trên máy chủ:';
																|ru = 'На сервере:';
																|en = 'On the server:'; fa = 'On the server:';
																|it = 'Su server:';
																|pl = 'Na serwerze';
																|tr = 'Sunucuda:'")) + " "
		+ Error.Text;
	Else
		DataElement.Error = DataElement.Error + ?(DataElement.Error <> "", Chars.LF, "")
			+ ?(Error.AtClient, NStr("vi = 'Trên máy tính:';
									|ru = 'На компьютере:';
									|en = 'On computer:'; fa = 'On computer:';
									|it = 'Sul computer:';
									|pl = 'Na komputerze:';
									|tr = 'Bilgisayarda:'"), NStr("vi = 'Trên máy chủ:';
																	|ru = 'На сервере:';
																	|en = 'On the server:'; fa = 'On the server:';
																	|it = 'Su server:';
																	|pl = 'Na serwerze';
																	|tr = 'Sunucuda:'")) + " "
			+ Error.Text;
	EndIf;
		
	If Context.AbortArrayProcessingOnError Then
		RefineOnSideAfterCycle(Context, ErrorText);
	Else
		RefineSideLoopStart(Context);
	EndIf;
	
EndProcedure 

// Intended for: EnhancedOnSide procedure.
Function DescriptionBugsUpgraded(ErrorAtClient = True)
	
	Return New Structure("AtClient, Text, ErrorCreatingCryptographyManager",
		ErrorAtClient, "", False);
		
EndFunction

// Continuation of the EnhancedOnSide procedure.
Procedure RefineOnSideAfterCycle(Context, ErrorText = Undefined)
	
	Result = New Structure;
	
	If Context.HasErrors Or Not Context.OperationStarted Then
		Result.Insert("Error", True);
		If Context.DataItems.Count() = 0 Then
			Result.Insert("ErrorText", NStr("vi = 'Không có chữ ký để xử lý.';
											|ru = 'Нет подписей для обработки.';
											|en = 'No signatures to process.'; fa = 'No signatures to process.';
											|it = 'Non ci sono firme da elaborare.';
											|pl = 'Brak podpisów do przetworzenia.';
											|tr = 'İşlenecek imza yok.'"));
		Else
			HasNoSignaturesToProcess = True;
			For Each DataElement In Context.DataItems Do
				If Not DataElement.Property("NotRequiredExtension") Then
					HasNoSignaturesToProcess = False;
					Break;
				EndIf;
			EndDo;
			StartErrors = ?(Context.OnClientSide, NStr("vi = 'Trên máy tính:';
														|ru = 'На компьютере:';
														|en = 'On the computer:'; fa = 'On the computer:';
														|it = 'Sul computer:';
														|pl = 'Na komputerze:';
														|tr = 'Bilgisayarda:'"), NStr("vi = 'Trên máy chủ:';
																						|ru = 'На сервере:';
																						|en = 'On the server:'; fa = 'On the server:';
																						|it = 'Su server:';
																						|pl = 'Na serwerze:';
																						|tr = 'Sunucuda:'"));
			If Context.ErrorsCreatingCryptographyManager.Count() > 0 Then
				Result.Insert("ErrorText", StartErrors + Chars.LF + StrConcat(Context.ErrorsCreatingCryptographyManager, Chars.LF));
			ElsIf HasNoSignaturesToProcess Then
				Result.Insert("ErrorText", NStr("vi = 'Không có chữ ký để xử lý.';
												|ru = 'Нет подписей для обработки.';
												|en = 'No signatures to process.'; fa = 'No signatures to process.';
												|it = 'Non ci sono firme da elaborare.';
												|pl = 'Brak podpisów do przetworzenia.';
												|tr = 'İşlenecek imza yok.'"));
			Else
				Result.Insert("ErrorText", StartErrors + Chars.LF + NStr("vi = 'Có lỗi khi gia hạn chữ ký';
																		|ru = 'Есть ошибки при продлении подписей';
																		|en = 'Errors occurred upon signature renewal'; fa = 'Errors occurred upon signature renewal';
																		|it = 'Vi sono errori di proroga delle firme';
																		|pl = 'Istnieją błędy podczas przedłużenia podpisów';
																		|tr = 'İmzaların uzatılmasında hatalar mevcut'"));
			EndIf;
		EndIf;
	EndIf;
	
	Result.Insert("DataItems", Context.DataItems);
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
Procedure RefineAfterRunningServerSide(Result, Context) Export
	
	If Result <> Undefined And Not Result.Property("Error") Then 
		RefineAfterExecutionOnClientSide(Result, Context);
	Else
		If Result <> Undefined Then
			Context.ExecutionParameters.Insert("DataItems", Result.DataItems);
			Context.ExecutionParameters.Insert("ErrorText", Result.ErrorText);
		EndIf;
		
		RefineSide(New CallbackDescription(
				"RefineAfterExecutionOnClientSide", ThisObject, Context),
			"OnClientSide", Context.ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
Procedure RefineAfterExecutionOnClientSide(Result, Context) Export
	
	ProcessingResult = New Structure("Success, ErrorText, PropertiesSignatures");
	
	If Result.Property("Error") Then
		ProcessingResult.Success = False;
		ProcessingResult.ErrorText = Result.ErrorText;
		
	Else
		ProcessingResult.Success = True;
	EndIf;
	
	If Context.ResultProcessing = Undefined Then
		Return;
	EndIf;
	
	If Result.Property("DataItems") Then
		ProcessingResult.PropertiesSignatures = Result.DataItems;
	EndIf;
	
	RunCallback(Context.ResultProcessing, ProcessingResult);
	
EndProcedure

// Continuation of the EnhancedOnSide procedure.
Function PropertiesCertificateString(Certificate)

	If Certificate = Undefined Then
		Return "";
	EndIf;
	
	CertificateProperties = DigitalSignatureClient.CertificateProperties(Certificate);
	InformationAboutCertificate = 
		DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
	
	Return InformationAboutCertificate;
	
EndFunction

#EndRegion

#Region ManagingXMLDSig

// Starts signing an XML message.
//
// Parameters:
//  NotificationsOnComplete - Structure:
//   * Success  - CallbackDescription - the procedure that will be called after signing.
//   * Error - CallbackDescription - the procedure that will be called when a signing error occurs.
//  XMLEnvelope             - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters       - See DigitalSignatureClient.XMLDSigParameters
//  CryptoCertificate - CryptoCertificate
//  CryptoManager   - CryptoManager
//
Procedure StartCryptoCertificateExportToSignXMLDSig(NotificationsOnComplete, XMLEnvelope,
			XMLDSigParameters, CryptoCertificate, CryptoManager)
	
	XMLEnvelopeProperties = DigitalSignatureInternalServerCall.XMLEnvelopeProperties(XMLEnvelope,
		XMLDSigParameters, False);
	
	SigningAlgorithmData = New Structure(New FixedStructure(XMLDSigParameters));
	
	Context = New Structure;
	Context.Insert("Mode",                   "SigningMode");
	Context.Insert("SignatureType",              "XMLDSig");
	Context.Insert("NotificationsOnComplete", NotificationsOnComplete);
	Context.Insert("SetComponent", True);
	
	Context.Insert("XMLEnvelope", XMLEnvelope);
	Context.Insert("XMLEnvelopeProperties", XMLEnvelopeProperties);
	
	Context.Insert("SigningAlgorithmData",    SigningAlgorithmData);
	Context.Insert("CryptoCertificate",       CryptoCertificate);
	Context.Insert("Base64CryptoCertificate", Undefined);
	Context.Insert("CryptoManager",         CryptoManager);
	
	Context.Insert("CryptoProviderType", Undefined);
	Context.Insert("CryptoProviderName", Undefined);
	Context.Insert("PathToCryptoProvider", Undefined);
	
	If XMLEnvelopeProperties <> Undefined
	   And ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
		
		CompleteOperationWithError(Context, XMLEnvelopeProperties.ErrorText);
		Return;
	EndIf;
	
	CryptoCertificate.BeginUnloading(
		New CallbackDescription("StartSigningAfterExportCryptoCertificate", ThisObject, Context));
	
EndProcedure

// Starts the XML message signature check.
//
// Parameters:
//  NotificationsOnComplete - Structure:
//   * Success  - CallbackDescription - the procedure that will be called after signature check.
//   * Error - CallbackDescription - the procedure that will be called when a signature check error occurs.
//  XMLEnvelope           - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters     - See DigitalSignatureClient.XMLDSigParameters
//  XMLEnvelopeProperties  - See DigitalSignatureInternal.XMLEnvelopeProperties
//  CryptoManager - CryptoManager
//
Procedure StartCryptoCertificateInitializationToCheckSignatureXMLDSig(NotificationsOnComplete, XMLEnvelope,
			XMLDSigParameters, XMLEnvelopeProperties, CryptoManager)
	
	If XMLEnvelopeProperties = Undefined Then
		Base64CryptoCertificate = DigitalSignatureInternalClientServer.CertificateFromSOAPEnvelope(XMLEnvelope);
	Else
		Base64CryptoCertificate = XMLEnvelopeProperties.Certificate.CertificateValue;
	EndIf;
	BinaryData = Base64Value(Base64CryptoCertificate);
	SigningAlgorithmData = New Structure(New FixedStructure(XMLDSigParameters));
	
	Context = New Structure;
	Context.Insert("Mode",                   "ModeChecking");
	Context.Insert("SignatureType",              "XMLDSig");
	Context.Insert("NotificationsOnComplete", NotificationsOnComplete);
	Context.Insert("SetComponent", True);
	
	Context.Insert("XMLEnvelope", XMLEnvelope);
	Context.Insert("XMLEnvelopeProperties", XMLEnvelopeProperties);
	
	Context.Insert("SigningAlgorithmData", SigningAlgorithmData);
	Context.Insert("CryptoCertificate",    New CryptoCertificate);
	Context.Insert("Base64CryptoCertificate", Base64CryptoCertificate);
	Context.Insert("CryptoManager",      CryptoManager);
	
	Context.Insert("CryptoProviderType",  Undefined);
	Context.Insert("CryptoProviderName",  Undefined);
	Context.Insert("PathToCryptoProvider", Undefined);
	
	Context.CryptoCertificate.BeginInitialization(New CallbackDescription(
			"StartCheckSignatureAfterInitializeCertificate", ThisObject, Context),
		BinaryData);
	
EndProcedure

// Starts signing the CMS message.
Procedure StartCryptoCertificateExportToSignCMS(NotificationsOnComplete, Data, CMSParameters, CryptoCertificate, CryptoManager)
	
	Context = New Structure;
	Context.Insert("Mode",                   "SigningMode");
	Context.Insert("SignatureType",              "CMS");
	Context.Insert("NotificationsOnComplete", NotificationsOnComplete);
	Context.Insert("SetComponent", True);
	
	Context.Insert("Data", Data);
	
	Context.Insert("CMSParameters",                 CMSParameters);
	Context.Insert("CryptoCertificate",       CryptoCertificate);
	Context.Insert("Base64CryptoCertificate", Undefined);
	Context.Insert("CryptoManager",         CryptoManager);
	
	Context.Insert("CryptoProviderType", Undefined);
	Context.Insert("CryptoProviderName", Undefined);
	Context.Insert("PathToCryptoProvider", Undefined);
	
	CryptoCertificate.BeginUnloading(
		New CallbackDescription("StartCMSSigningAfterExportCryptoCertificate", ThisObject, Context));
	
EndProcedure

// Starts the CMS message signature check.
Procedure StartCryptoCertificateInitializationToCheckSignatureCMS(NotificationsOnComplete, Signature, Data, CMSParameters, CryptoManager)
	
	Context = New Structure;
	Context.Insert("Mode",                   "ModeChecking");
	Context.Insert("SignatureType",              "CMS");
	Context.Insert("NotificationsOnComplete", NotificationsOnComplete);
	Context.Insert("SetComponent", True);
	
	Context.Insert("Data", Data);
	Context.Insert("Signature", Signature);
	Context.Insert("CMSParameters", CMSParameters);
	
	Context.Insert("CryptoCertificate",    Undefined);
	Context.Insert("CryptoManager",      CryptoManager);
	
	Context.Insert("CryptoProviderType",  Undefined);
	Context.Insert("CryptoProviderName",  Undefined);
	Context.Insert("PathToCryptoProvider", Undefined);
	
	StartCheckSignatureAfterInitializeCertificate(Undefined, Context);
	
EndProcedure

Procedure StartCheckSignatureAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.CryptoCertificate = CryptoCertificate;
	
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để kiểm tra chữ ký %1 cần cài đặt cấu phần %2';
			|ru = 'Для проверки подписи %1 необходима установка компоненты %2';
			|en = 'To verify %1 signature, install add-in ""%2""'; fa = 'To verify %1 signature, install add-in ""%2""';
			|it = 'Per la verifica della firma %1è necessario installare la componente %2';
			|pl = 'Do sprawdzenia podpisu %1 konieczne jest zainstalowanie komponentu %2';
			|tr = '%1 imzanın denetlenmesi için %2 bileşeni kurulmalı'"),
		?(Context.SignatureType = "CMS", "CMS", "XML"), "ExtraCryptoAPI");
	
	AttachAddInSSL(Context, ExplanationText);
	
EndProcedure

Procedure AttachAddInSSL(Context, ExplanationText)
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = ExplanationText;
	ConnectionParameters.SuggestToImport = True;
	
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	Context.Insert("AddInObjectName", ComponentDetails.ObjectName);
	
	CommonClient.AttachAddInFromTemplate(
		New CallbackDescription("AfterAttachComponent", ThisObject, Context),
		ComponentDetails.ObjectName,
		ComponentDetails.FullTemplateName,
		ConnectionParameters);
	
EndProcedure

Procedure AfterAttachComponent(Result, Context) Export
	
	If Result.Attached Then
		Context.Insert("ComponentObject", Result.Attachable_Module);
		AfterConnectingTheComponentsConfigureTheComponent(Context);
	Else
		
		If IsBlankString(Result.ErrorDescription) Then 
			
			// A user canceled the installation.
			
			CompleteOperationWithError(
				Context,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thao tác không khả thi. Cần cài đặt cấu phần %1.';
						|ru = 'Операция невозможна. Требуется установка компоненты %1.';
						|en = 'Operation failed. Add-in is required: %1.'; fa = 'Operation failed. Add-in is required: %1.';
						|it = 'Impossibile eseguire l''operazione. È richiesta l''installazione della componente %1.';
						|pl = 'Operacja jest niemożliwa. Wymagana jest instalacja komponentu %1.';
						|tr = 'İşlem yapılamaz. %1 bileşeni kurulmalı.'"), "ExtraCryptoAPI"));
				
		Else
			
			// Installation failed. The error description is in Result.ErrorDetails.
			
			CompleteOperationWithError(
				Context,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thao tác không khả thi. %1';
						|ru = 'Операция невозможна. %1';
						|en = 'Operation is not allowed. %1'; fa = 'Operation is not allowed. %1';
						|it = 'Impossibile eseguire l''operazione. %1';
						|pl = 'Operacja jest niemożliwa. %1';
						|tr = 'İşlem yapılamaz. %1'"), Result.ErrorDescription));
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AfterConnectingTheComponentsConfigureTheComponent(Context)
	
	Notification = New CallbackDescription(
		"AfterConnectingTheComponentsAfterInstallingTheOIDCompliance", ThisObject, Context,
		"AfterConnectingTheComponentsAfterAnInstallationErrorOIDCompliance", ThisObject);
		
	FillPathToAddInLog(Context.ComponentObject, Context.AddInObjectName);
	
	Context.ComponentObject.BeginSettingOIDMap(Notification,
		DigitalSignatureInternalClientServer.IdentifiersOfHashingAlgorithmsAndThePublicKey());
	
EndProcedure

Procedure AfterConnectingTheComponentsAfterInstallingTheOIDCompliance(Context) Export
	
	If TypeOf(Context.CryptoManager) = Type("Structure") Then
		AfterSetPropertyDisableUserInterface(Context);
		Return;
	EndIf;
	
	Context.CryptoManager.BeginGettingCryptoModuleInformation(
		New CallbackDescription("AfterGetCryptoModuleInformation", ThisObject, Context));
	
EndProcedure

Procedure AfterConnectingTheComponentsAfterAnInstallationErrorOIDCompliance(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(Context,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập thuộc tính %1 cấu phần %2 do nguyên nhân:
				|%3';
				|ru = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|en = 'Cannot set the %1 property of the %2 add-in due to:
				|%3'; fa = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';
				|it = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|pl = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';
				|tr = '%2 bileşeninin %1 özelliği şu sebeple kurulamadı:
				|%3'"), "OIDMap", "ExtraCryptoAPI", ErrorProcessing.DetailErrorDescription(ErrorInfo)));
	
EndProcedure

// Parameters:
//   CryptoModuleInformation - CryptoModuleInformation
//   Context - Structure
//
Async Procedure AfterGetCryptoModuleInformation(CryptoModuleInformation, Context) Export
	
	CryptoProviderName = CryptoModuleInformation.Name;
	
	ErrorDescription = "";
	
	CryptoProvidersResult = Await InstalledCryptoProvidersFromCache();
	AppsAuto = DigitalSignatureInternalClientServer.CryptoProvidersSearchResult(CryptoProvidersResult);
		
	If TypeOf(AppsAuto) = Type("String") Then
		ErrorDescription = AppsAuto;
		AppsAuto = Undefined;
	EndIf;
	
	ApplicationDetails = DigitalSignatureInternalClientServer.ApplicationDetailsByCryptoProviderName(
		CryptoProviderName, DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection, AppsAuto); // See DigitalSignatureInternalCached.ApplicationDetails
	
	If ApplicationDetails = Undefined Then
		If Not IsBlankString(ErrorDescription) Then
			CompleteOperationWithError(Context, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định kiểu nhà cung cấp mã hóa %1. %2';
					|ru = 'Не удалось определить тип криптопровайдера %1. %2';
					|en = 'Cannot determine the type of cryptographic service provider %1. %2'; fa = 'Cannot determine the type of cryptographic service provider %1. %2';
					|it = 'Не удалось определить тип криптопровайдера %1. %2';
					|pl = 'Cannot determine the type of cryptographic service provider %1. %2';
					|tr = '%1 kripto sağlayıcısının türü tespit edilemedi. %2'"), CryptoModuleInformation.Name, ErrorDescription));
		Else
			CompleteOperationWithError(Context, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định kiểu nhà cung cấp mã hóa %1';
					|ru = 'Не удалось определить тип криптопровайдера %1';
					|en = 'Cannot determine the type of cryptographic service provider %1'; fa = 'Cannot determine the type of cryptographic service provider %1';
					|it = 'Non è stato possibile definire il tipo di cryptoprovider%1';
					|pl = 'Nie można określić typu dostawcy kryptograficznego %1';
					|tr = '%1 kripto sağlayıcının türü tespit edilemedi'"), CryptoModuleInformation.Name));
		EndIf;
		Return;
	EndIf;
	
	Context.CryptoProviderType = ApplicationDetails.ApplicationType;
	Context.CryptoProviderName = CryptoProviderName;
	
	If ApplicationDetails.Property("AutoDetect") Then
		DescriptionOfWay = New Structure("ApplicationPath, Exists", ApplicationDetails.PathToAppAuto, True);
		AfterGettingTheProgramPath(DescriptionOfWay, Context);
		Return;
	EndIf;
	
	ToObtainThePathToTheProgram(New CallbackDescription("AfterGettingTheProgramPath",
		ThisObject, Context), ApplicationDetails.Ref);
	
EndProcedure

Procedure AfterGettingTheProgramPath(DescriptionOfWay, Context) Export
	
	Context.PathToCryptoProvider = DescriptionOfWay.ApplicationPath;
	
	Notification = New CallbackDescription(
		"AfterSetComponentCryptoproviderPath", ThisObject, Context);
	
	Context.ComponentObject.BeginSettingPathToCryptoprovider(Notification,
		Context.PathToCryptoProvider);
	
EndProcedure

Procedure AfterSetComponentCryptoproviderPath(Context) Export
	
	If Not RequiresThePathToTheProgram() Then
		Notification = New CallbackDescription(
			"AfterSetPropertyDisableUserInterface", ThisObject, Context);
		
		Context.ComponentObject.StartInstallationProhibitUserInterface(Notification,
			Not InteractiveCryptographyModeUsed(Context.CryptoManager));
	Else
		AfterSetPropertyDisableUserInterface(Context);
	EndIf;
	
EndProcedure

Procedure AfterSetPropertyDisableUserInterface(Context) Export
	
	If Context.SignatureType = "XMLDSig" Then
		
		If Context.Mode = "ModeChecking" Then
			StartCheckSignatureXMLDSig(Context);
			
		ElsIf Context.Mode = "SigningMode" Then
			StartXMLDSigSigning(Context);
		Else
			CompleteOperationWithError(Context, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa thiết lập chế độ hoạt động của cấu phần %1.';
					|ru = 'Не установлен режим работы компоненты %1.';
					|en = 'Operating mode not specified for add-in ""%1"".'; fa = 'Operating mode not specified for add-in ""%1"".';
					|it = 'Modalità di lavoro della componente %1non impostata.';
					|pl = 'Nie ustawiono trybu pracy komponentu %1.';
					|tr = '%1 bileşenin çalışma modu ayarlanmadı.'"), "ExtraCryptoAPI"));
		EndIf;
		
	ElsIf Context.SignatureType = "CMS" Then
		
		If Context.Mode = "ModeChecking" Then
			StartCheckingTheCMSSignature(Context);
			
		ElsIf Context.Mode = "SigningMode" Then
			StartCMSSigning(Context);
		Else
			CompleteOperationWithError(Context, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa thiết lập chế độ hoạt động của cấu phần %1.';
					|ru = 'Не установлен режим работы компоненты %1.';
					|en = 'Operating mode not specified for add-in ""%1"".'; fa = 'Operating mode not specified for add-in ""%1"".';
					|it = 'Modalità di lavoro della componente %1non impostata.';
					|pl = 'Nie ustawiono trybu pracy komponentu %1.';
					|tr = '%1 bileşenin çalışma modu ayarlanmadı.'"), "ExtraCryptoAPI"));
		EndIf;
		
	Else
		
		CompleteOperationWithError(Context, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa cài đặt kiểu chữ ký cấu phần %1.';
				|ru = 'Не установлен тип подписи компоненты %1.';
				|en = 'Signature type not specified for add-in ""%1"".'; fa = 'Signature type not specified for add-in ""%1"".';
				|it = 'Tipo di firma della componente %1non impostato.';
				|pl = 'Nie ustawiono typu podpisu komponentu %1.';
				|tr = '%1 bileşenin imza türü ayarlanmadı.'"), "ExtraCryptoAPI"));
	EndIf;
	
EndProcedure

Procedure StartSigningAfterExportCryptoCertificate(CertificateBinaryData, Context) Export
	
	Context.Base64CryptoCertificate =
		DigitalSignatureInternalClientServer.Base64CryptoCertificate(
			CertificateBinaryData);
	
	AttachAddInSSL(Context, StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để ký XML, cần cài đặt cấu phần %1';
			|ru = 'Для подписания XML необходима установка компоненты %1';
			|en = 'To sign XML files, install add-in ""%1""'; fa = 'To sign XML files, install add-in ""%1""';
			|it = 'Per la firma XML è necessario installare la componente %1';
			|pl = 'Aby podpisać XML należy zainstalować komponent %1';
			|tr = 'XML''nin imzalanması için %1 bileşen ayarlanmalı'"), "ExtraCryptoAPI"));
	
EndProcedure

Procedure StartCMSSigningAfterExportCryptoCertificate(CertificateBinaryData, Context) Export
	
	Context.Base64CryptoCertificate =
		DigitalSignatureInternalClientServer.Base64CryptoCertificate(
			CertificateBinaryData);
	
	AttachAddInSSL(Context, StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để ký CMS, cần cài đặt cấu phần %1';
			|ru = 'Для подписания CMS необходима установка компоненты %1';
			|en = 'To sign CMS files, install add-in ""%1""'; fa = 'To sign CMS files, install add-in ""%1""';
			|it = 'Per la firma SMS è necessario installare la componente %1';
			|pl = 'Aby podpisać CMS należy zainstalować komponent %1';
			|tr = 'CMS''in imzalanması için %1 bileşen ayarlanmalı'"), "ExtraCryptoAPI"));
		
	
EndProcedure

Procedure StartCMSSigning(Context)
	
	CMSSignParameters = DigitalSignatureInternalClientServer.AddInParametersCMSSign(
		Context.CMSParameters, Context.Data);
	
	Notification = New CallbackDescription(
		"SigningAfterCMSSignExecution", ThisObject, Context,
		"SigningAfterExecuteCMSSignError", ThisObject);
	
	Try
		Context.ComponentObject.BeginCallingCMSSign(Notification,
			CMSSignParameters.Data,
			Context.Base64CryptoCertificate,
			Context.CryptoManager.PrivateKeyAccessPassword,
			CMSSignParameters.SignatureType,
			CMSSignParameters.DetachedAddIn,
			CMSSignParameters.IncludeCertificatesInSignature);
	Except
		CompleteOperationWithError(Context, DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSSign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

Procedure SigningAfterExecuteCMSSignError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(Context, DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSSign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo)));
	
EndProcedure

Procedure SigningAfterCMSSignExecution(SignatureValueAttribute, Parameters, Context) Export
	
	If Not ValueIsFilled(SignatureValueAttribute) Then
		StartGetErrorText(StartErrorTextDetails("CMSSign"), Context);
		Return;
	EndIf;
	
	RunCallback(Context.NotificationsOnComplete.Success, SignatureValueAttribute);
	
EndProcedure

Procedure StartCheckingTheCMSSignature(Context)
	
	CMSSignParameters = DigitalSignatureInternalClientServer.AddInParametersCMSSign(
		Context.CMSParameters, Context.Data);
	
	Notification = New CallbackDescription(
		"VerificationAfterCMSVerifySignExecution", ThisObject, Context,
		"CheckingAfterCMSVerifySignExecutionError", ThisObject);
	
	Try
		Context.ComponentObject.BeginCallingCMSVerifySign(Notification,
			Context.Signature,
			CMSSignParameters.DetachedAddIn,
			Context.Data,
			Context.CryptoProviderType,
			Null);
	Except
		CompleteOperationWithError(Context, 
			DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSVerifySign",
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
				
	EndTry;
	
EndProcedure

Procedure CheckingAfterCMSVerifySignExecutionError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(Context,
		DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSVerifySign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo)));
	
EndProcedure

Procedure VerificationAfterCMSVerifySignExecution(SignatureCorrect, Parameters, Context) Export
	
	If SignatureCorrect <> True Then
		StartGetErrorText(StartErrorTextDetails("CMSVerifySign"), Context);
		Return;
	EndIf;
	
	If TypeOf(Parameters[4]) = Type("BinaryData") Then
		Context.CryptoCertificate = Parameters[4];
	Else
		CompleteOperationWithError(Context,
			NStr("vi = 'Chữ ký đúng, nhưng không chứa dữ liệu chứng thư.';
				|ru = 'Подпись верна, но не содержит данных сертификата.';
				|en = 'The signature is valid but does not contain the certificate data.'; fa = 'The signature is valid but does not contain the certificate data.';
				|it = 'Firma corretta, ma non contiene i dati del certificato.';
				|pl = 'Podpis jest zgodny, ale nie zawiera danych certyfikatu.';
				|tr = 'İmza geçrli, ancak sertifika verileri içermiyor.'"));
		Return;
	EndIf;
	
	DigitalSignatureClient.SigningDate(
		New CallbackDescription("CheckAfterExecuteHashTagToSignAfterGetSigningDate", ThisObject, Context), Context.Signature);
	
EndProcedure

Async Procedure StartXMLDSigSigning(Context)
	
	Try
		XMLEnvelope = Await SignXMLDSig(Context);
		RunCallback(Context.NotificationsOnComplete.Success, XMLEnvelope);
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		CompleteOperationWithError(Context, ErrorText);
	EndTry;

EndProcedure

Async Function SignXMLDSig(Context)
	
	Password = Context.CryptoManager.PrivateKeyAccessPassword;
	ComponentObject = Context.ComponentObject;
	XMLEnvelope = Context.XMLEnvelope;
	XMLEnvelopeProperties = Context.XMLEnvelopeProperties;
	
	If XMLEnvelopeProperties <> Undefined
	   And ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
		Raise XMLEnvelopeProperties.ErrorText;
	EndIf;
	
	Base64CryptoCertificate = Context.Base64CryptoCertificate;
	
	SigningAlgorithmData = Context.SigningAlgorithmData;
	DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
		Base64CryptoCertificate, SigningAlgorithmData, True, XMLEnvelopeProperties);
	
	XMLEnvelope = StrReplace(XMLEnvelope, "%BinarySecurityToken%", Base64CryptoCertificate);
	XMLEnvelope = StrReplace(XMLEnvelope, "%SignatureMethod%", SigningAlgorithmData.SelectedSignatureAlgorithm);
	XMLEnvelope = StrReplace(XMLEnvelope, "%DigestMethod%",    SigningAlgorithmData.SelectedHashAlgorithm);
	
	If XMLEnvelopeProperties <> Undefined Then
		For IndexOf = 0 To XMLEnvelopeProperties.AreasToHash.UBound() Do
			HashedArea = XMLEnvelopeProperties.AreasToHash[IndexOf];
			CanonizedTextXMLBody = Await CanonizedXMLText(ComponentObject,
					XMLEnvelopeProperties.AreasBody[IndexOf], HashedArea.TransformationAlgorithms);
			DigestValueAttribute = Await HashResult(ComponentObject,
					CanonizedTextXMLBody,
					SigningAlgorithmData.SelectedHashAlgorithmOID,
					Context.CryptoProviderType);

			XMLEnvelope = StrReplace(XMLEnvelope, HashedArea.HashValue, DigestValueAttribute);
		EndDo;
	Else
		CanonizedTextXMLBody = Await C14NAsync(ComponentObject,
		XMLEnvelope, SigningAlgorithmData.XPathTagToSign);
		
		DigestValueAttribute = Await HashResult(ComponentObject,
				CanonizedTextXMLBody,
				SigningAlgorithmData.SelectedHashAlgorithmOID,
				Context.CryptoProviderType);

		XMLEnvelope = StrReplace(XMLEnvelope, "%DigestValue%", DigestValueAttribute);
	EndIf;
	
	If XMLEnvelopeProperties = Undefined Then
		CanonizedTextXMLSignedInfo = Await C14NAsync(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathSignedInfo);
	Else
		SignedInfoArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
			XMLEnvelopeProperties.SignedInfoArea.TagName);
		SignedInfoArea.NamespacesUpToANode =
			XMLEnvelopeProperties.SignedInfoArea.NamespacesUpToANode;
		
		If ValueIsFilled(SignedInfoArea.ErrorText) Then
			Raise SignedInfoArea.ErrorText;
		EndIf;
		
		CanonizedTextXMLSignedInfo = Await CanonizedXMLText(ComponentObject,
			SignedInfoArea,
			CommonClientServer.ValueInArray(XMLEnvelopeProperties.TheCanonizationAlgorithm));
	EndIf;
	
	SignatureValueAttribute = Await SignResult(ComponentObject,
		CanonizedTextXMLSignedInfo,
		Context.CryptoCertificate,
		Password);
	
	XMLEnvelope = StrReplace(XMLEnvelope, "%SignatureValue%", SignatureValueAttribute);
	
	Return XMLEnvelope;
	
EndFunction

Async Function HashResult(ComponentObject, CanonizedTextXMLBody, HashingAlgorithmOID, CryptoProviderType)
	
	Try
		Result = Await ComponentObject.HashAsync(
			CanonizedTextXMLBody,
			HashingAlgorithmOID,
			CryptoProviderType);
		DigestValueAttribute = Result.Value;
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Hash",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If DigestValueAttribute = Undefined Then
		ResultError = Await ComponentObject.GetLastErrorAsync();
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Hash",
			ResultError.Value);
		Raise ErrorText;
	EndIf;
	
	Return DigestValueAttribute;
	
EndFunction

Async Function SignResult(ComponentObject, CanonizedTextXMLSignedInfo,
	CryptoCertificate, PrivateKeyAccessPassword)
	
	Base64CryptoCertificate = Await CryptoCertificate.UnloadAsync();
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		Base64CryptoCertificate);

	Try
		Result = Await ComponentObject.SignAsync(
			CanonizedTextXMLSignedInfo,
			Base64CryptoCertificate,
			PrivateKeyAccessPassword);
		SignatureValueAttribute = Result.Value;
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Sign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureValueAttribute = Undefined Then
		ResultError = Await ComponentObject.GetLastErrorAsync();
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Sign",
			ResultError.Value);
		Raise ErrorText;
	EndIf;
	
	Return SignatureValueAttribute;
	
EndFunction

Async Procedure StartCheckSignatureXMLDSig(Context)
	
	ErrorText = DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
		Context.Base64CryptoCertificate, Context.SigningAlgorithmData, , Context.XMLEnvelopeProperties);
	
	If ValueIsFilled(ErrorText) Then
		CompleteOperationWithError(Context, ErrorText);
		Return;
	EndIf;
	
	Try
		Result = Await VerifySignatureXMLDSig(Context);
		RunCallback(Context.NotificationsOnComplete.Success, Result);
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		CompleteOperationWithError(Context, ErrorText);
	EndTry;
	
EndProcedure

Async Function VerifySignatureXMLDSig(Context)
	
	ComponentObject = Context.ComponentObject;
	SigningAlgorithmData = Context.SigningAlgorithmData;
	XMLEnvelope = Context.XMLEnvelope;
	XMLEnvelopeProperties = Context.XMLEnvelopeProperties;
		
	If XMLEnvelopeProperties = Undefined Then
		CanonizedTextXMLSignedInfo = Await C14NAsync(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathSignedInfo);
		CanonizedTextXMLBody = Await C14NAsync(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathTagToSign);
		Base64CryptoCertificate = DigitalSignatureInternalClientServer.CertificateFromSOAPEnvelope(XMLEnvelope);
		SignatureValue = DigitalSignatureInternalClientServer.FindInXML(XMLEnvelope, "SignatureValue");
		HashValue    = DigitalSignatureInternalClientServer.FindInXML(XMLEnvelope, "DigestValue");
	Else
		CanonizedTextXMLSignedInfo = Await CanonizedXMLText(ComponentObject,
			XMLEnvelopeProperties.SignedInfoArea,
			CommonClientServer.ValueInArray(XMLEnvelopeProperties.TheCanonizationAlgorithm));
		
		SignatureValue = XMLEnvelopeProperties.SignatureValue;
		Base64CryptoCertificate = XMLEnvelopeProperties.Certificate.CertificateValue;
		DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
			Base64CryptoCertificate, SigningAlgorithmData, True, XMLEnvelopeProperties);
	EndIf;
	
	SignatureCorrect = Await VerifySignResult(ComponentObject,
		CanonizedTextXMLSignedInfo,
		SignatureValue,
		Base64CryptoCertificate,
		Context.CryptoProviderType);
	
	If XMLEnvelopeProperties <> Undefined Then
		
		Counter = 1;
		
		For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
			CanonizedTextXMLBody = Await CanonizedXMLText(ComponentObject,
				XMLEnvelopeProperties.AreasBody[Counter-1], HashedArea.TransformationAlgorithms);
			HashValue = HashedArea.HashValue; 
			
			DigestValueAttribute = Await HashResult(ComponentObject,
				CanonizedTextXMLBody,
				SigningAlgorithmData.SelectedHashAlgorithmOID,
				Context.CryptoProviderType);
				
			HashMaps = (DigestValueAttribute = HashValue);
			
			If Not HashMaps Or Not SignatureCorrect Then
				Raise DigitalSignatureInternalClientServer.XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps);
			EndIf;
			Counter = Counter + 1;
		EndDo;
		
		Return Await XMLSignatureVerificationResult(Base64CryptoCertificate);
	EndIf;
	
	DigestValueAttribute = Await HashResult(ComponentObject,
		CanonizedTextXMLBody,
		SigningAlgorithmData.SelectedHashAlgorithmOID,
		Context.CryptoProviderType);
	
	HashMaps = (DigestValueAttribute = HashValue);
	
	If HashMaps And SignatureCorrect Then
		Return Await XMLSignatureVerificationResult(Base64CryptoCertificate);
	Else
		Raise DigitalSignatureInternalClientServer.XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps);
	EndIf;

EndFunction

Async Function XMLSignatureVerificationResult(Base64CryptoCertificate)
	
	BinaryData = Base64Value(Base64CryptoCertificate);
	
	CryptoCertificate = New CryptoCertificate;
	Await CryptoCertificate.InitializeAsync(BinaryData);

	Result = New Structure;
	Result.Insert("Certificate", CryptoCertificate);
	Result.Insert("SigningDate", Undefined);

	Return Result;
		
EndFunction

Async Function VerifySignResult(ComponentObject, CanonizedTextXMLSignedInfo,
	SignatureValueAttribute, Base64CryptoCertificate, CryptoProviderType)
	
	Try
		Result = Await ComponentObject.VerifySignAsync(
			CanonizedTextXMLSignedInfo,
			SignatureValueAttribute,
			Base64CryptoCertificate,
			CryptoProviderType);
		SignatureCorrect = Result.Value;
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("VerifySign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureCorrect = Undefined Then
		ResultError = Await ComponentObject.GetLastErrorAsync();
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("VerifySign",
			ResultError.Value);
		Raise ErrorText;
	EndIf;
	
	Return SignatureCorrect;
	
EndFunction

Procedure CheckAfterExecuteHashTagToSignAfterGetSigningDate(SigningDate, Context) Export
	
	If Not ValueIsFilled(SigningDate) Then
		SigningDate = Undefined;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Certificate", Context.CryptoCertificate);
	ReturnValue.Insert("SigningDate", SigningDate);
	
	RunCallback(Context.NotificationsOnComplete.Success, ReturnValue);
	
EndProcedure

Async Function C14NAsync(ComponentObject, XMLEnvelope, XPath)
	
	Try
		Result = Await ComponentObject.C14NAsync(XMLEnvelope, XPath);
		CanonizedXMLText = Result.Value;
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		
		ResultError = Await ComponentObject.GetLastErrorAsync();
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N",
			ResultError.Value);
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Async Function CanonizedXMLText(ComponentObject, XMLScope, Algorithms)
	
	Result = Undefined;
	HigherLevelNamespacesHaveBeenAdded = False;
	
	For Each Algorithm In Algorithms Do
		If Algorithm.Kind = "envsig" Then
			Continue;
		ElsIf Algorithm.Kind = "c14n"
		      Or Algorithm.Kind = "smev" Then
			
			If Not HigherLevelNamespacesHaveBeenAdded Then
				DescriptionOfTheBeginningOfTheArea = DigitalSignatureInternalClientServer.ExtendedBeginningOfTheXMLArea(
					XMLScope, Algorithm, Result);
				If ValueIsFilled(DescriptionOfTheBeginningOfTheArea.ErrorText) Then
					Raise DescriptionOfTheBeginningOfTheArea.ErrorText;
				EndIf;
				XMLText = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope,
					DescriptionOfTheBeginningOfTheArea.Begin);
				HigherLevelNamespacesHaveBeenAdded = True;
				
			ElsIf Result = Undefined Then
				XMLText = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope);
			Else
				XMLText = Result;
			EndIf;
			
			If Algorithm.Kind = "c14n" Then
				Result = Await C14N_body(ComponentObject, XMLText, Algorithm);
			Else
				Result = Await CanonizationSMEV(ComponentObject, XMLText);
			EndIf;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		Result = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope);
	EndIf;
	
	Return Result;
	
EndFunction

Async Function C14N_body(ComponentObject, XMLText, Algorithm)
	
	Try
		Result = Await ComponentObject.c14n_bodyAsync(XMLText,
			Algorithm.Version, Algorithm.WithComments);
		CanonizedXMLText = Result.Value;

	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N_body",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ResultError = Await ComponentObject.GetLastErrorAsync();
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N_body",
			ResultError.Value);
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Async Function CanonizationSMEV(ComponentObject, XMLText)
	
	Try
		Result = Await ComponentObject.TransformSMEVAsync(XMLText);
		CanonizedXMLText = Result.Value;
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("TransformSMEV",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ResultError = Await ComponentObject.GetLastErrorAsync();
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("TransformSMEV",
			ResultError.Value);
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Procedure StartGetErrorText(StartErrorTextDetails, Context)
	
	Context.Insert("StartErrorTextDetails", StartErrorTextDetails);
	
	Notification = New CallbackDescription(
		"GetErrorAfterCompletion", ThisObject, Context,
		"GetErrorAfterCompletion_Error", ThisObject);
	
	Try
		Context.ComponentObject.BeginCallingGetLastError(Notification);
	Except
		CompleteOperationWithError(Context,
			DigitalSignatureInternalClientServer.ErrorCallMethodComponents("GetLastError",
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

Procedure GetErrorAfterCompletion_Error(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(Context,
		DigitalSignatureInternalClientServer.ErrorCallMethodComponents("GetLastError",
			ErrorProcessing.DetailErrorDescription(ErrorInfo)));
	
EndProcedure

Procedure GetErrorAfterCompletion(ErrorText, Parameters, Context) Export
	
	CompleteOperationWithError(Context,
		Context.StartErrorTextDetails + Chars.LF + ErrorText);
	
EndProcedure

Procedure CompleteOperationWithError(Context, ErrorText)
	
	RunCallback(Context.NotificationsOnComplete.Error, ErrorText);
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// For the SetCertificatePassword, OpenNewForm, SelectSigningOrDecryptionCertificate, and
// CheckCatalogCertificate procedures.
//
Function PassParametersForm()
	
	ParameterName = "StandardSubsystems.DigitalSignatureAndEncryptionParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	
	Form = ApplicationParameters["StandardSubsystems.DigitalSignatureAndEncryptionParameters"].Get("PassParametersForm");
	
	If Form = Undefined Then
		Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.PassingParameters");
		ApplicationParameters["StandardSubsystems.DigitalSignatureAndEncryptionParameters"].Insert("PassParametersForm", Form);
	EndIf;
	
	Return Form;
	
EndFunction

// Intended for: ProcessPasswordInForm procedure.
Procedure ProcessPassword(InternalData, AttributePassword, PasswordProperties,
			RememberPasswordAttribute, AdditionalParameters, NewPassword = Null)
	
	Certificate = AdditionalParameters.Certificate;
	
	PasswordStorage = InternalData.Get("PasswordStorage");
	If PasswordStorage = Undefined Then
		PasswordStorage = New Map;
		InternalData.Insert("PasswordStorage", PasswordStorage);
	EndIf;
	
	SpecifiedPasswords = InternalData.Get("SpecifiedPasswords");
	If SpecifiedPasswords = Undefined Then
		SpecifiedPasswords = New Map;
		InternalData.Insert("SpecifiedPasswords", SpecifiedPasswords);
		InternalData.Insert("SpecifiedPasswordsNotes", New Map);
	EndIf;
	
	SpecifiedPassword = SpecifiedPasswords.Get(Certificate);
	AdditionalParameters.Insert("PasswordSetProgrammatically", SpecifiedPassword <> Undefined);
	If SpecifiedPassword <> Undefined Then
		AdditionalParameters.Insert("PasswordNote",
			InternalData.Get("SpecifiedPasswordsNotes").Get(Certificate));
	EndIf;
	
	If AdditionalParameters.EnterPasswordInDigitalSignatureApplication Then
		PasswordProperties.Value = "";
		PasswordProperties.PasswordVerified = False;
		AttributePassword = "";
		Value = PasswordStorage.Get(Certificate);
		If Value <> Undefined Then
			PasswordStorage.Delete(Certificate);
			Value = Undefined;
		EndIf;
		AdditionalParameters.Insert("PasswordInMemory", False);
		
		Return;
	EndIf;
	
	Password = PasswordStorage.Get(Certificate);
	AdditionalParameters.Insert("PasswordInMemory", Password <> Undefined);
	
	If AdditionalParameters.OnTogglePasswordConcealMode Then
		If Not AttributePassword = "****************" And Not PasswordProperties.PasswordMode Then
			PasswordProperties.Value = NewPassword;
		EndIf;
		UpdatePasswordAttribute(AttributePassword, PasswordProperties);
		Return;
	EndIf;
	
	If AdditionalParameters.OnSetPasswordFromAnotherOperation Then
		UpdatePasswordAttribute(AttributePassword, PasswordProperties);
		RememberPasswordAttribute = AdditionalParameters.PasswordInMemory;
		Return;
	EndIf;
	
	If AdditionalParameters.OnChangeAttributePassword Then
		If AttributePassword = "****************" And PasswordProperties.PasswordMode Then
			Return;
		EndIf;
		PasswordProperties.Value = AttributePassword;
		PasswordProperties.PasswordVerified = False;
		UpdatePasswordAttribute(AttributePassword, PasswordProperties);
		
		Return;
	EndIf;
	
	If AdditionalParameters.OnChangeAttributeRememberPassword Then
		If Not RememberPasswordAttribute Then
			Value = PasswordStorage.Get(Certificate);
			If Value <> Undefined Then
				PasswordStorage.Delete(Certificate);
				Value = Undefined;
			EndIf;
			AdditionalParameters.Insert("PasswordInMemory", False);
			
		ElsIf PasswordProperties.PasswordVerified Then
			PasswordStorage.Insert(Certificate, PasswordProperties.Value);
			AdditionalParameters.Insert("PasswordInMemory", True);
		EndIf;
		
		Return;
	EndIf;
	
	If AdditionalParameters.OnOperationSuccess Then
		If RememberPasswordAttribute
		   And Not AdditionalParameters.PasswordSetProgrammatically Then
			
			PasswordStorage.Insert(Certificate, PasswordProperties.Value);
			AdditionalParameters.Insert("PasswordInMemory", True);
			PasswordProperties.PasswordVerified = True;
		EndIf;
		
		Return;
	EndIf;
	
	If AdditionalParameters.PasswordSetProgrammatically Then
		If NewPassword <> Null Then
			PasswordProperties.Value = String(NewPassword);
		Else
			PasswordProperties.Value = String(SpecifiedPassword);
		EndIf;
		PasswordProperties.PasswordVerified = False;
		UpdatePasswordAttribute(AttributePassword, PasswordProperties);
		
		Return;
	EndIf;
	
	If NewPassword <> Null Then
		// Setting a new password to a new certificate.
		If NewPassword <> Undefined Then
			PasswordProperties.Value = String(NewPassword);
			PasswordProperties.PasswordVerified = True;
			NewPassword = "";
			If PasswordStorage.Get(Certificate) <> Undefined Or RememberPasswordAttribute Then
				PasswordStorage.Insert(Certificate, PasswordProperties.Value);
				AdditionalParameters.Insert("PasswordInMemory", True);
			EndIf;
		ElsIf PasswordStorage.Get(Certificate) <> Undefined Then
			// Deleting the saved password from the storage.
			RememberPasswordAttribute = False;
			PasswordStorage.Delete(Certificate);
			AdditionalParameters.Insert("PasswordInMemory", False);
		EndIf;
		UpdatePasswordAttribute(AttributePassword, PasswordProperties);
		
		Return;
	EndIf;
	
	If AdditionalParameters.OnChangeCertificateProperties Then
		Return;
	EndIf;
	
	// Getting a password from the storage.
	Value = PasswordStorage.Get(Certificate);
	AdditionalParameters.Insert("PasswordInMemory", Value <> Undefined);
	RememberPasswordAttribute = AdditionalParameters.PasswordInMemory;
	PasswordProperties.Value = String(Value);
	PasswordProperties.PasswordVerified = AdditionalParameters.PasswordInMemory;
	Value = Undefined;
	UpdatePasswordAttribute(AttributePassword, PasswordProperties);
	
EndProcedure

Procedure UpdatePasswordAttribute(AttributePassword, PasswordProperties)
	AttributePassword = ?(PasswordProperties.Value <> "",
			?(PasswordProperties.PasswordMode, "****************", PasswordProperties.Value),
			?(PasswordProperties.PasswordMode, "", AttributePassword));
EndProcedure

// Intended for: SetDataPresentation procedure.
Procedure FillPresentationsList(PresentationsList, DataElement)
	
	ListItem = New Structure("Value, Presentation", Undefined, "");
	PresentationsList.Add(ListItem);
	
	If DataElement.Property("Presentation")
	   And TypeOf(DataElement.Presentation) = Type("Structure") Then
		
		FillPropertyValues(ListItem, DataElement.Presentation);
		Return;
	EndIf;
	
	If DataElement.Property("Presentation")
	   And TypeOf(DataElement.Presentation) <> Type("String") Then
	
		ListItem.Value = DataElement.Presentation;
		
	ElsIf DataElement.Property("Object")
	        And TypeOf(DataElement.Object) <> Type("CallbackDescription") Then
		
		ListItem.Value = DataElement.Object;
	EndIf;
	
	If DataElement.Property("Presentation") Then
		ListItem.Presentation = DataElement.Presentation;
	EndIf;
	
EndProcedure

// For the CheckSignatureAfterCreateCryptoManager and
// GetDataFromDataDetailsFollowUp procedures.
//
Function IncludingCertificatesInSignatureAsString(IncludeCertificatesInSignature) Export
	
	If TypeOf(IncludeCertificatesInSignature) <> Type("CryptoCertificateIncludeMode") Then
		Return IncludeCertificatesInSignature;
	EndIf;
	
	If IncludeCertificatesInSignature = CryptoCertificateIncludeMode.DontInclude Then
		Return "DontInclude";
	ElsIf IncludeCertificatesInSignature = CryptoCertificateIncludeMode.IncludeSubjectCertificate Then
		Return "IncludeSubjectCertificate";
	Else
		Return "IncludeWholeChain";
	EndIf;
	
EndFunction

// This method is required by the SaveCertificateFollowUp and SaveApplicationForCertificateAfterInstallExtension procedures.

// Continues the VerifySignature procedure.
Procedure CheckSignatureSaaS(Context)
	
	If Not DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		Context.Insert("CheckCertificateAtClient");
		CheckSignatureAtClientSaaS(Context);
		Return;
	EndIf;
	
EndProcedure

// Continues the VerifySignature procedure.
Procedure CheckSignatureAtClientSaaS(Context)
	
	Signature = Context.Signature;
	
	If TypeOf(Signature) = Type("String") And IsTempStorageURL(Signature) Then
		Signature = GetFromTempStorage(Signature);
	EndIf;
	
	Context.Insert("SignatureData", Signature);
	Context.Insert("CryptoManager", "CryptographyService");
	
	ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
	ModuleCryptographyServiceClient.VerifySignature(New CallbackDescription(
		"CheckSignatureAtClientAfterCheckSignatureSaaS", ThisObject, Context,
		"CheckSignatureAtClientAfterCheckSignatureError", ThisObject),
		Context.SignatureData,
		Context.RawData);
		
EndProcedure

// Continues the VerifySignature procedure.
Async Procedure CheckSignatureAtClientAfterCheckSignatureSaaS(Result, Context) Export
	
	If Not Result.Completed2 Then
		If TypeOf(Context.CheckResult) = Type("Structure") Then
			Context.CheckResult.IsVerificationRequired = True;
		EndIf;
		CheckSignatureAtClientAfterCheckSignatureError(Result.ErrorInfo, False, Context);
		Return;
	EndIf;
	
	If Not Result.SignatureIsValid Then
		CheckSignatureAtClientAfterCheckSignatureError(
			DigitalSignatureInternalClientServer.ServiceErrorTextSignatureInvalid(),
				False, Context);
		Return;
	EndIf;
	
	CheckSignatureAtClientAfterCheckSignature(Undefined, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSIdeSaaS(Result, Context)
	
	Context.Insert("CryptoCertificate", Result);
	
	If Context.Operation = "Signing" Then
		
		If ValueIsFilled(Context.DataDetails.SignatureType) Then
			If Context.DataDetails.SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES")
				And Context.DataDetails.SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS") Then
				Error = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể ký bởi kiểu chữ ký %1 thông qua nhà cung cấp mã hóa tích hợp sẵn.';
						|ru = 'Недоступно подписание типом подписи %1 с помощью встроенного криптопровайдера.';
						|en = 'Cannot sign with signature type %1 using the built-in cryptographic service provider.'; fa = 'Cannot sign with signature type %1 using the built-in cryptographic service provider.';
						|it = 'Non è disponibile la firma con tipo di firma %1 tramite cryptoprovider integrato.';
						|pl = 'Jest niedostępne podpisanie typem podpisu %1 za pomocą wbudowanego dostawcy usług kryptograficznych.';
						|tr = 'Yerleşik kripto sağlayıcısı kullanılarak%1 imza türüyle imzalama mevcut değildir.'"), Context.DataDetails.SignatureType));
				ExecuteAtSideAfterLoop(Error, Context);
				Return;
			EndIf;
		EndIf;

		SignatureCertificate = New Structure("Thumbprint",
			Base64Value(Context.DataDetails.SelectedCertificate.Thumbprint));
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New CallbackDescription(
				"ExecuteAtSideAfterExportCertificateInSaaSMode", ThisObject, Context), SignatureCertificate);
		
	ElsIf Context.Operation = "Encryption" Then
		CertificatesProperties = Context.DataDetails.EncryptionCertificates;
		If TypeOf(CertificatesProperties) = Type("String") Then
			CertificatesProperties = GetFromTempStorage(CertificatesProperties);
		EndIf;
		Context.Insert("IndexOf", -1);
		Context.Insert("CertificatesProperties", CertificatesProperties);
		Context.Insert("EncryptionCertificates", New Array);
		ExecuteAtSidePrepareCertificatesSaaSLoopStart(Context);
		Return;
	Else
		ExecuteAtSideLoopRun(Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSidePrepareCertificatesSaaSLoopStart(Context)
	
	If Context.CertificatesProperties.Count() <= Context.IndexOf + 1 Then
		ExecuteAtSideLoopRun(Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	
	ExecuteAtSidePrepareCertificatesAfterInitializeCertificateSaaS(
		Context.CertificatesProperties[Context.IndexOf].Certificate, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSidePrepareCertificatesAfterInitializeCertificateSaaS(CryptoCertificate, Context)
	
	Context.EncryptionCertificates.Add(CryptoCertificate);
	
	ExecuteAtSidePrepareCertificatesSaaSLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
// 
// Parameters:
//   SearchResult - Structure:
//   * ErrorDescription - ErrorInfo
//   Context - Structure
//
Async Procedure ExecuteAtSideAfterExportCertificateInSaaSMode(SearchResult, Context) Export
	
	If Not SearchResult.Completed2 Then
		Error = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tìm thấy chứng thư trong dịch vụ vì lý do:
			           |%1';
			           |ru = 'Не удалось найти сертификат в сервисе по причине:
			           |%1';
			           |en = 'Couldn''t find certificate in the service due to:
			           |%1'; fa = 'Couldn''t find certificate in the service due to:
			           |%1';
			           |it = 'Non è stato possibile trovare il certificato nel servizio a causa di:
			           |%1';
			           |pl = 'Nie udało się znaleźć certyfikatu w usłudze z powodu:
			           |%1';
			           |tr = 'Sertifika hizmette şu sebeple bulunamadı:
			           |%1'"), SearchResult.ErrorDescription.Description));
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	If Not ValueIsFilled(SearchResult.Certificate) Then
		Error = New Structure("ErrorDescription",
			NStr("vi = 'Không tồn tại chứng thư trong dịch vụ (có thể là đã bị xóa).';
				|ru = 'Сертификат отсутствует в сервисе (возможно удален).';
				|en = 'The certificate does not exist in the service. It might have been deleted.'; fa = 'The certificate does not exist in the service. It might have been deleted.';
				|it = 'Certificato assente nel servizio (forse eliminato).';
				|pl = 'Brak certyfikatu w usłudze (mógł być usunięty).';
				|tr = 'Hizmette sertifika eksik (silinmiş olabilir).'"));
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	Context.Insert("CertificateProperties", Await CertificateProperties(
		SearchResult.Certificate));
	Context.CertificateProperties.Insert("BinaryData", SearchResult.Certificate.Certificate);
	
	ExecuteAtSideLoopRun(Context);
	
EndProcedure

Function UseDigitalSignatureSaaS() Export
	
	If CommonClient.SubsystemExists("CloudTechnology.DigitalSignatureSaaS") Then
		ModuleDigitalSignatureSaaSClient = CommonClient.CommonModule("DigitalSignatureSaaSClient");
		Return ModuleDigitalSignatureSaaSClient.UsageAllowed() And CommonClient.DataSeparationEnabled();
	EndIf;
	
	Return False;
	
EndFunction

Function InteractiveCryptoModeUsageUse()
	
	Return Eval("CryptoInteractiveModeUse.Use");
	
EndFunction

Function StartErrorTextDetails(MethodName)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa thực hiện phương thức %1 do nguyên nhân:';
			|ru = 'Метод %1 не выполнен по причине:';
			|en = 'The %1 method is not executed due to:'; fa = 'The %1 method is not executed due to:';
			|it = 'Метод %1 не выполнен по причине:';
			|pl = 'The %1 method is not executed due to:';
			|tr = '%1 yöntemi şu sebeple gerçekleştirilmedi:'"), MethodName); 
	
EndFunction

#EndRegion

#Region AddingCertificate

// Continues the DigitalSignatureClient.AddCertificate procedure.
Procedure AddCertificateAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager")
		And Result.Shared3 Then
		
		Result.ErrorTitle = Context.ApplicationErrorTitle;
		Context.Insert("ErrorAtClient", Result);
		Context.Insert("CryptoCertificate");
		If Not Context.Property("SignAlgorithm") Then
			Context.Insert("SignAlgorithm", "");
		EndIf;
		Context.Insert("IsFullUser", UsersClient.IsFullUser());
		AddCertificateFromToken(Context);
		Return;
		
	EndIf;
	
	CryptoCertificate = New CryptoCertificate;
	CryptoCertificate.BeginInitialization(New CallbackDescription(
		"AddCertificateAfterInitializeCertificate", ThisObject, Context),
		Context.CertificateData);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
Async Procedure AddCertificateAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.Insert("CryptoCertificate", CryptoCertificate);
	
	Context.Insert("ErrorAtClient", 
		DigitalSignatureInternalClientServer.NewErrorsDescription());
	
	If Not Context.Property("SignAlgorithm") Then
		Context.Insert("SignAlgorithm", "");
	EndIf;
	
	Context.Insert("IsFullUser", UsersClient.IsFullUser());
	
	ApplicationsDetailsCollection = DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection;
	
	CertificateApplicationResult = Await AppForCertificate(CryptoCertificate, True, Undefined, True);
	If ValueIsFilled(CertificateApplicationResult.Application) Then
		ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
			CertificateApplicationResult.Application, Context.ErrorAtClient.Errors, ApplicationsDetailsCollection);
	Else
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		ErrorProperties.LongDesc = CertificateApplicationResult.Error;
		Context.ErrorAtClient.Errors.Add(ErrorProperties);
	EndIf;
		
	Context.Insert("ApplicationsDetailsCollection", ApplicationsDetailsCollection);
	Context.Insert("ApplicationDetails", Undefined);
	Context.Insert("IndexOf", -1);
	
	AddCertificateLoopStart(Context);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
// 
// Parameters:
//  Context - Structure:
//   * ErrorAtClient - Structure:
//      ** Errors - Array - ErrorInfo.
//   * ApplicationsDetails - See DigitalSignatureInternalCached.ApplicationDetails
//
Procedure AddCertificateLoopStart(Context)
	
	If Context.ApplicationsDetailsCollection.Count() <= Context.IndexOf + 1 Then
		
		AddCertificateFromToken(Context);
		Return;
		
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDetails = Context.ApplicationsDetailsCollection[Context.IndexOf]; // See DigitalSignatureInternalCached.ApplicationDetails
	Context.ApplicationDetails = ApplicationDetails;
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ShowError = Undefined;
	 
	CreationParameters.Application = ApplicationDetails;
	CreationParameters.InteractiveMode = Context.AdditionalParameters.EnterPasswordInDigitalSignatureApplication;
	CreationParameters.SignAlgorithm = Context.SignAlgorithm;
	
	CreateCryptoManager(
		New CallbackDescription("AddCertificateLoopAfterCreateCryptoManager",ThisObject, Context),
		"", CreationParameters);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
Async Procedure AddCertificateFromToken(Context)
	
	If Context.CryptoCertificate = Undefined Then
		CryptoCertificate = New CryptoCertificate;
		Await CryptoCertificate.InitializeAsync(Context.CertificateData);
		Context.Insert("CryptoCertificate", CryptoCertificate);
	EndIf;
	
	Notification = New CallbackDescription("AddCertificateFromTokenAfterReceiveToken", ThisObject, Context);
	
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnGettingTokenByCertificate(
		Notification, Context.CryptoCertificate, StandardProcessing, True);
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	RunCallback(Context.CompletionHandler, Undefined);
	ReportCertificateAddingError(Context);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
Procedure AddCertificateFromTokenAfterReceiveToken(Token, Context) Export
	
	If Not ValueIsFilled(Token) Then
		RunCallback(Context.CompletionHandler, Undefined);
		ReportCertificateAddingError(Context);
		Return;
	EndIf;
	
	Token.Insert("Password", Context.CertificatePassword);
	Context.Insert("Token", Token);
	
	StandardProcessing = True;
	If Context.ToEncrypt = True Then
		EncryptionOnTokenParameters = EncryptionOnTokenParameters(Token, Context.CryptoCertificate);
		DigitalSignatureClientLocalization.OnEncryptionOnToken(New CallbackDescription("AddCertificateFromTokenAfterEncryption", ThisObject, 
			Context), EncryptionOnTokenParameters, Context.CertificateData, StandardProcessing);
	Else
		SignatureParameters = ParametersOfSignatureOnToken(Token, 
			Context.CryptoCertificate, PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES"));
		DigitalSignatureClientLocalization.OnSigningOnToken(New CallbackDescription("AddCertificateFromTokenAfterReceiveSignature", ThisObject, 
			Context), SignatureParameters, Context.CertificateData, StandardProcessing);
	EndIf;
	
	If StandardProcessing Then
		RunCallback(Context.CompletionHandler, Undefined);
		ReportCertificateAddingError(Context);
	EndIf;
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
// 
// Parameters:
//   Context - Structure:
//     * ErrorAtClient - Structure:
//         ** Errors - Array
//
Procedure AddCertificateLoopAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		
		If Result.Errors.Count() > 0 Then
			If Not (ValueIsFilled(Context.SignAlgorithm)
				And Result.Errors[0].NoAlgorithm) Then
				Result.Errors[0].ErrorTitle = Context.ApplicationErrorTitle;
				Context.ErrorAtClient.Errors.Add(Result.Errors[0]);
			ElsIf ValueIsFilled(Context.SignAlgorithm) 
				And Result.Errors[0].NoAlgorithm 
				And Context.ApplicationsDetailsCollection.Count() = 1 Then
				
				Result.Errors[0].ErrorTitle = Context.ApplicationErrorTitle;
				
				PossibleAlgorithms = StrSplit(Context.SignAlgorithm, ",", False);

				Result.Errors[0].LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã liên kết chứng thư với ứng dụng không tương ứng %1, hãy cài đặt lại chứng thư trong hệ điều hành bằng cách liên kết chứng thư với ứng dụng chữ ký điện tử có thuật toán ""%2"".';
						|ru = 'Сертификат связан с не соответствующим ему приложением %1, переустановите сертификат в операционной системе, связав его с приложением электронной подписи с алгоритмом ""%2"".';
						|en = 'The certificate is associated with %1, which a non-proper application. Reinstall the certificate in the operating system and associate it with the digital signature application using the %2 algorithm.'; fa = 'The certificate is associated with %1, which a non-proper application. Reinstall the certificate in the operating system and associate it with the digital signature application using the %2 algorithm.';
						|it = 'Сертификат связан с не соответствующим ему приложением %1, переустановите сертификат в операционной системе, связав его с приложением электронной подписи с алгоритмом ""%2"".';
						|pl = 'The certificate is associated with %1, which a non-proper application. Reinstall the certificate in the operating system and associate it with the digital signature application using the %2 algorithm.';
						|tr = 'Sertifika, uyumsuz bir uygulama ile ilişkilendirilmiş%1, sertifikayı ""%2"" algoritmalı olan bir elektronik imza uygulaması ile ilişkilendirerek işletim sistemine yeniden yükleyin.'"),
					Context.ApplicationDetails.ApplicationName,
					PossibleAlgorithms[0]);
				Context.ErrorAtClient.Errors.Add(Result.Errors[0]);
			EndIf;
		EndIf;
		
		AddCertificateLoopStart(Context);
		Return;
		
	EndIf;
	
	Context.Insert("CryptoManager", Result);
	If Not InteractiveCryptographyModeUsed(Context.CryptoManager) Then
		Context.CryptoManager.PrivateKeyAccessPassword = Context.CertificatePassword;
	EndIf;
	
	If Context.ToEncrypt = True Then
		Context.CryptoManager.BeginEncrypting(New CallbackDescription(
			"AddCertificateLoopAfterEncryption", ThisObject, Context,
			"AddCertificateLoopAfterEncryptionError", ThisObject),
			Context.CertificateData, Context.CryptoCertificate);
	Else
		Context.CryptoManager.BeginSigning(New CallbackDescription(
			"AddCertificateLoopAfterSigning", ThisObject, Context,
			"AddCertificateLoopAfterSigningError", ThisObject),
			Context.CertificateData, Context.CryptoCertificate);
	EndIf;
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
Procedure AddCertificateLoopAfterEncryption(EncryptedData, Context) Export
	
	Context.CryptoManager.BeginDecrypting(New CallbackDescription(
		"AddCertificateLoopAfterDecryption", ThisObject, Context,
		"AddCertificateLoopAfterDecryptionError", ThisObject),
		EncryptedData);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
// 
// Parameters:
//   Context - Structure:
//     * ErrorAtClient - Structure:
//         ** Errors - Array
//     * ApplicationsDetails - See DigitalSignatureInternalCached.ApplicationDetails
//
Procedure AddCertificateLoopAfterEncryptionError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
		Context.ErrorAtClient,
		Context.ApplicationDetails,
		"Encryption",
		ErrorProcessing.BriefErrorDescription(ErrorInfo),
		Context.IsFullUser);
		
	AddCertificateLoopStart(Context);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
// 
// Parameters:
//   Context - Structure:
//    * ErrorDescription - See DigitalSignatureInternalCached.ApplicationDetails
//
Procedure AddCertificateLoopAfterSigning(SignatureData, Context) Export
	
	ErrorInfo = Undefined;
	ErrorPresentation = "";
	Try
		DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorPresentation);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			Context.ErrorAtClient,
			Context.ApplicationDetails,
			"Signing",
			ErrorPresentation,
			Context.IsFullUser,
			ErrorInfo = Undefined);
		
		AddCertificateLoopStart(Context);
		Return;
	EndIf;
	
	Certificate = DigitalSignatureInternalClientServer.WriteCertificateToCatalog(Context,
		Context.ErrorAtClient);
	
	If Certificate = Undefined Then
		ReportCertificateAddingError(Context);
	Else
		RunCallback(Context.CompletionHandler, Certificate);
	EndIf;
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
Procedure AddCertificateLoopAfterSigningError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
		Context.ErrorAtClient,
		Context.ApplicationDetails,
		"Signing",
		ErrorProcessing.BriefErrorDescription(ErrorInfo),
		Context.IsFullUser);
	
	AddCertificateLoopStart(Context);
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
// 
// Parameters:
//   Context - Structure
//
Procedure AddCertificateLoopAfterDecryption(DecryptedData, Context) Export
	
	ErrorInfo = Undefined;
	ErrorPresentation = "";
	Try
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorPresentation);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			Context.ErrorAtClient,
			Context.ApplicationDetails,
			"Details",
			ErrorPresentation,
			Context.IsFullUser,
			ErrorInfo = Undefined);
	
		AddCertificateLoopStart(Context);
		Return;
	EndIf;
	
	Certificate = DigitalSignatureInternalClientServer.WriteCertificateToCatalog(Context,
		Context.ErrorAtClient);
	
	If Certificate = Undefined Then
		ReportCertificateAddingError(Context);
	Else
		RunCallback(Context.CompletionHandler, Certificate);
	EndIf;
	
EndProcedure

// Continues the DigitalSignatureClient.AddCertificate procedure.
Procedure AddCertificateLoopAfterDecryptionError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
		Context.ErrorAtClient,
		Context.ApplicationDetails,
		"Details",
		ErrorProcessing.BriefErrorDescription(ErrorInfo),
		Context.IsFullUser);
	
	AddCertificateLoopStart(Context);
	
EndProcedure

Procedure ReportCertificateAddingError(AddingContext)
	
	ErrorAtClient = ?(AddingContext.Property("ErrorAtClient"),
		AddingContext.ErrorAtClient, New Structure);
	ErrorAtServer = ?(AddingContext.Property("ErrorAtServer"),
		AddingContext.ErrorAtServer, New Structure);
	
	AdditionalParameters = New Structure("Certificate",
		AddingContext.CertificateData);
		
	If ValueIsFilled(ErrorAtClient) And ErrorAtClient.Errors.Count() > 0
		And ErrorAtClient.Errors[0].LongDesc = ErrorTextCannotDetermineAppByPrivateCertificateKey() Then
		
		HasTokenErrors = False;
		For Each Error In ErrorAtClient.Errors Do
			If ValueIsFilled(Error.Token) Then
				HasTokenErrors = True;
				Break;
			EndIf;
		EndDo;

		If HasTokenErrors Then
			ShowApplicationCallError(AddingContext.FormCaption, "", ErrorAtClient, ErrorAtServer,
				AdditionalParameters);
			Return;
		EndIf;
		
		ErrorParameters = New Structure;
		ErrorParameters.Insert("WarningTitle", AddingContext.FormCaption);
		ErrorParameters.Insert("ErrorTextClient", ErrorAtClient.Errors[0].LongDesc);
		
		If ValueIsFilled(ErrorAtServer) And ErrorAtServer.Errors.Count() > 0 Then
			ErrorParameters.Insert("ErrorTextServer", ErrorAtServer.Errors[0].LongDesc);
		EndIf;
		
		ErrorParameters.Insert("AdditionalData", AdditionalParameters);
		
		OpenExtendedErrorPresentationForm(ErrorParameters);
		
	Else
		ShowApplicationCallError(AddingContext.FormCaption,
			"", ErrorAtClient, ErrorAtServer, AdditionalParameters);
	EndIf;
EndProcedure

// Called after digital signatures are added to the catalog.
//
// Parameters:
//  Certificate								 - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - Reference to the added certificate.
//  ParametersNotificationWhenWritingCertificate	 - See ParametersNotificationWhenWritingCertificate
//
Procedure AfterAddingElectronicSignatureCertificatesToCatalog(Certificate, ParametersNotificationWhenWritingCertificate) Export
	
	NotifyChanged(Certificate);
	Notify("Write_DigitalSignatureAndEncryptionKeysCertificates", ParametersNotificationWhenWritingCertificate, Certificate);
	If ParametersNotificationWhenWritingCertificate.IsNew Then
		AddedCertificates = DigitalSignatureInternalServerCall.AddedCertificates(Certificate);
		DigitalSignatureClientOverridable.AfterAddingElectronicSignatureCertificatesToCatalog(
			New Structure("Certificates", AddedCertificates));
	EndIf;
	
EndProcedure

#EndRegion

#Region OperationsWithACloudSignature

Procedure ExecuteOnTheCloudSignatureSide(Context)
	
	DataDetails = Context.DataDetails;
	
	Context.Insert("CryptoCertificate", Null);
	
	If Context.Operation = "Signing" Then
		
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		SelectedCertificate = DataDetails.SelectedCertificate;
		
		Thumbprint = New Structure();
		Thumbprint.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(SelectedCertificate.Thumbprint));
		Thumbprint.Insert("BinaryData", GetFromTempStorage(SelectedCertificate.Data));
		
		CloudSignatureProperties = GetThePropertiesOfACloudSignature(DataDetails);
		WeFoundTheCertificate = TheDSSCryptographyServiceModuleClientServer.FindCertificate(CloudSignatureProperties.Account, Thumbprint);
		
		If WeFoundTheCertificate.Id = -1 Then
			Error = New Structure("ErrorDescription", ErrorTextCloudSignature("CertificateSearch"));
			Context.Insert("OperationStarted", False);
			ExecuteAtSideAfterLoop(Error, Context);
			Return;
		EndIf;
		
		WeFoundTheCertificate.Insert("BinaryData", Thumbprint.BinaryData);
		
		Context.Insert("CertificateProperties", WeFoundTheCertificate);
		
	ElsIf Context.Operation = "Encryption" Then
		CertificatesProperties = DataDetails.EncryptionCertificates;
		If TypeOf(CertificatesProperties) = Type("String") Then
			CertificatesProperties = GetFromTempStorage(CertificatesProperties);
		EndIf;
		
		EncryptionCertificates = New Array;
		
		For Each ArrayRow In CertificatesProperties Do
			EncryptionCertificates.Add(ArrayRow);
		EndDo;
		
		Context.Insert("IndexOf", EncryptionCertificates.Count());
		Context.Insert("CertificatesProperties", CertificatesProperties);
		Context.Insert("EncryptionCertificates", EncryptionCertificates);
		
	EndIf;
	
	ExecuteAtSideLoopRun(Context);
	
EndProcedure

Procedure PerformACloudSignatureOperation(Notification, Context, Data, OperationParametersList)
	
	DataDetails = Context.DataDetails;
	TheIndexOfTheData = CommonClientServer.StructureProperty(Context, "IndexOf", 0);
	ExecuteImmediately = True;
	ResultType = Undefined;
			
	TransactionID = Undefined;
	CloudSignatureProperties = GetThePropertiesOfACloudSignature(DataDetails);
	ConfirmationData = CloudSignatureProperties.ConfirmationData;
	If ConfirmationData <> Undefined Then
		TransactionID = ?(ValueIsFilled(ConfirmationData.TransactionID), ConfirmationData.TransactionID, ConfirmationData.OperationID);
	EndIf;
	
	If Context.Operation = "Signing" Then
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		PINCodeValue = ?(ValueIsFilled(Context.PasswordValue), Context.PasswordValue, Undefined);
		Pin = TheDSSCryptographyServiceModuleClient.PreparePasswordObject(PINCodeValue);
		OperationParametersList.Insert("Pin", Pin);
		
		If ConfirmationData <> Undefined Then
			BatchOperation = ConfirmationData.ParametersOfBuiltInOption.BatchOperation;
			ResultType = ConfirmationData.ParametersOfBuiltInOption.ResultType;
			If ValueIsFilled(TransactionID)
				And TheIndexOfTheData > 0
				And Not BatchOperation Then
				ExecuteImmediately = False;
			EndIf;
			OperationParametersList.Insert("TransactionID", TransactionID);
			OperationParametersList.Insert("BatchSignature", BatchOperation);
		EndIf;	
		
		If ExecuteImmediately Then
			If ValueIsFilled(TransactionID) Then
				SignCloudSignature(Notification, Context, Undefined, OperationParametersList, ResultType);
			ElsIf CloudSignatureProperties.PackageData = Undefined Then
				SignCloudSignature(Notification, Context, Data, OperationParametersList, ResultType);
			Else
				SignCloudSignature(Notification, Context, CloudSignatureProperties.PackageData, OperationParametersList, ResultType);
			EndIf;	
		EndIf;
					
	ElsIf Context.Operation = "Encryption" Then
		EncryptCloudSignature(Notification, Context, Data, OperationParametersList, ResultType);
		
	ElsIf Context.Operation = "Details" Then
		ResultType = Undefined;
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		PINCodeValue = ?(ValueIsFilled(Context.PasswordValue), Context.PasswordValue, Undefined);
		Pin = TheDSSCryptographyServiceModuleClient.PreparePasswordObject(Context.PasswordValue);
		OperationParametersList.Insert("Pin", Pin);
		
		If ConfirmationData <> Undefined Then
			ResultType = ConfirmationData.ParametersOfBuiltInOption.ResultType;
			If ValueIsFilled(TransactionID)
				And TheIndexOfTheData > 0 Then
				ExecuteImmediately = False;
			EndIf;
			OperationParametersList.Insert("TransactionID", TransactionID);
		EndIf;
		
		If ExecuteImmediately Then
			DecryptCloudSignature(Notification, Context, Data, OperationParametersList, ResultType);
		EndIf;	
		
	EndIf;
	
	If Not ExecuteImmediately Then
		ConfirmationParameters = New Structure();
		ConfirmationParameters.Insert("Notification", Notification);
		ConfirmationParameters.Insert("Context", Context);
		ConfirmationParameters.Insert("Data", Data);
		ConfirmationParameters.Insert("OperationParametersList", OperationParametersList);
		ConfirmationParameters.Insert("ResultType", ResultType);
		
		NotificationWhenExecuting = New CallbackDescription("PerformACloudSignatureOperationAfterConfirmation", ThisObject, ConfirmationParameters); 
		SetThePropertiesOfTheCloudSignature(Context.DataDetails,
			New Structure("NotificationOnConfirmation", NotificationWhenExecuting));
			
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		ModuleCryptographyServiceDSSConfirmationClient.PerformInitialServiceOperation(
					Context.Form, 
					Context.DataDetails, 
					Context.PasswordValue, 
					TheIndexOfTheData);
	EndIf;	
				
EndProcedure	

Procedure PerformACloudSignatureOperationAfterConfirmation(ExecutionResult, IncomingContext) Export
	
	Context = IncomingContext.Context;
	
	If Context.Operation = "Signing" Then
		SignCloudSignature(IncomingContext.Notification, IncomingContext.Context, IncomingContext.Data, IncomingContext.OperationParametersList, IncomingContext.ResultType);
	ElsIf Context.Operation = "Details" Then
		DecryptCloudSignature(IncomingContext.Notification, IncomingContext.Context, IncomingContext.Data, IncomingContext.OperationParametersList, IncomingContext.ResultType);
	EndIf;	
	
EndProcedure

Procedure SignCloudSignature(Notification, Context, Data, OperationParametersList, ResultType = Undefined)
	
	TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	
	If TypeOf(Data) = Type("Structure") 
		And Data.Property("CMSParameters") Then
		
		CMSParameters = Data.CMSParameters;
		If CMSParameters.SignatureType = "CAdES-BES" Then
			SignatureType = "BES";
		Else
			Error = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ký bằng kiểu chữ ký %1 thông qua tài khoản DSS.';
					|ru = 'Недоступно подписание типом подписи %1 с помощью учетной записи DSS.';
					|en = 'Cannot sign with signature type %1 using DSS account.'; fa = 'Cannot sign with signature type %1 using DSS account.';
					|it = 'Non è disponibile la firma con tipo di firma %1 tramite account DSS.';
					|pl = 'Jest niedostępne podpisanie typem podpisu %1 za pomocą konta DSS.';
					|tr = 'DSS hesabı ile %1 imza türü imzalama kullanılamaz.'"), CMSParameters.SignatureType));
			ExecuteAtSideAfterLoop(Error, Context);
			Return;
		EndIf;
		SignatureProperty = TheDSSCryptographyServiceModuleClientServer.GetCAdESSignatureProperty(SignatureType, CMSParameters.DetachedAddIn, False, "Signature");
		Data = Data.Data;
		If TypeOf(Data) = Type("String") Then
			Data = GetBinaryDataFromString(Data);
		EndIf;
		
	ElsIf ValueIsFilled(Context.DataDetails.SignatureType) Then
		If Context.DataDetails.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES") Then
			SignatureProperty = TheDSSCryptographyServiceModuleClientServer.GetCAdESSignatureProperty("BES", True, False, "Signature");
		ElsIf Context.DataDetails.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST") Then
			SignatureProperty = TheDSSCryptographyServiceModuleClientServer.GetCAdESSignatureProperty("T", True, False, "Signature");
		ElsIf Context.DataDetails.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS") Then
			SignatureProperty = TheDSSCryptographyServiceModuleClientServer.GetCMSSignatureProperty(True, False);
		Else
			Error = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ký bằng kiểu chữ ký %1 thông qua tài khoản DSS.';
					|ru = 'Недоступно подписание типом подписи %1 с помощью учетной записи DSS.';
					|en = 'Cannot sign with signature type %1 using DSS account.'; fa = 'Cannot sign with signature type %1 using DSS account.';
					|it = 'Non è disponibile la firma con tipo di firma %1 tramite account DSS.';
					|pl = 'Jest niedostępne podpisanie typem podpisu %1 za pomocą konta DSS.';
					|tr = 'DSS hesabı ile %1 imza türü imzalama kullanılamaz.'"), Context.DataDetails.SignatureType));
			ExecuteAtSideAfterLoop(Error, Context);
			Return;
		EndIf;
	Else
		SignatureProperty = TheDSSCryptographyServiceModuleClientServer.GetCMSSignatureProperty(True, False);
	EndIf;
	
	If ResultType <> Undefined Then
		OperationParametersList.Insert("TransformTheResult", New Structure("ResultType", ResultType));
	EndIf;
	
	CloudSignatureProperties = GetThePropertiesOfACloudSignature(Context.DataDetails);
	
	TheDSSCryptographyServiceModuleClient.Sign(
				Notification,
				CloudSignatureProperties.Account,
				Data, 
				SignatureProperty, 
				Context.CertificateProperties, 
				OperationParametersList);
	
EndProcedure

Procedure EncryptCloudSignature(Notification, Context, Data, OperationParametersList, ResultType = Undefined)
	
	If ResultType <> Undefined Then
		OperationParametersList.Insert("TransformTheResult", New Structure("ResultType", ResultType));
	EndIf;
	
	CloudSignatureProperties = GetThePropertiesOfACloudSignature(Context.DataDetails);
	
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	TheDSSCryptographyServiceModuleClient.Encrypt(
				Notification,
				CloudSignatureProperties.Account,
				Data,
				Context.EncryptionCertificates,
				"CMS", 
				OperationParametersList);
	
EndProcedure

Procedure DecryptCloudSignature(Notification, Context, Data, OperationParametersList, ResultType = Undefined)
	
	TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	
	If ResultType <> Undefined Then
		OperationParametersList.Insert("TransformTheResult", New Structure("ResultType", ResultType));
	EndIf;
	
	Certificate = New Structure("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(Context.DataDetails.SelectedCertificate.Thumbprint));
	CloudSignatureProperties = GetThePropertiesOfACloudSignature(Context.DataDetails);
	
	TheDSSCryptographyServiceModuleClient.Decrypt(
				Notification,
				CloudSignatureProperties.Account,
				Data,
				"CMS",
				Certificate,
				OperationParametersList);
	
EndProcedure

Async Procedure RunALoopOnTheSideAfterSigningThePackage(SignaturesArray, Context)
	
	ErrorAtClient = Undefined;
	
	For Counter = 0 To SignaturesArray.Count() - 1 Do
		
		BinaryData = SignaturesArray[Counter];
		
		SignatureProperties = Await SignaturePropertiesFromBinaryData(BinaryData, False);
		SignatureProperties = GetSignaturePropertiesAfterSigning(BinaryData, Context, SignatureProperties);

		DataElement = Context.DataDetails.DataSet[Counter];
		DataElement.Insert("SignatureProperties", SignatureProperties);
		
		If Not DataElement.Property("Object") Then
			DigitalSignatureInternalServerCall.RegisterDataSigningInLog(
				CurrentDataItemProperties(Context, SignatureProperties));
			Continue;
		EndIf;
		
		If TypeOf(DataElement.Object) <> Type("CallbackDescription") Then
			ObjectVersion = Undefined;
			DataElement.Property("ObjectVersion", ObjectVersion);
			SignatureProperties.Insert("SignatureID", New UUID);
			ErrorPresentation = DigitalSignatureInternalServerCall.AddSignature(
				DataElement.Object, SignatureProperties, Context.FormIdentifier, ObjectVersion);
			If ValueIsFilled(ErrorPresentation) Then
				ErrorAtClient = New Structure("ErrorDescription", ErrorPresentation);
				DataElement.Delete("SignatureProperties");
				Continue;
			EndIf;
			NotifyChanged(DataElement.Object);
			
		Else // Create a branch to return to the loop by counter.
			DigitalSignatureInternalServerCall.RegisterDataSigningInLog(
				CurrentDataItemProperties(Context, SignatureProperties));
				
			Context.DataDetails.Insert("CurrentDataSetItem", DataElement);

			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("DataDetails", Context.DataDetails);
			ExecutionParameters.Insert("Notification", New CallbackDescription(
				"RunLoopOnSideAfterBatchSigningWritten", ThisObject, Context));
			
			Try
				RunCallback(DataElement.Object, ExecutionParameters);
			Except
				ErrorInfo = ErrorInfo();
				ErrorAtClient = New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
			EndTry;
			
		EndIf;
		
	EndDo;
	
	If ErrorAtClient <> Undefined Then
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
	Else
		Context.IndexOf = 0;
		ExecuteAtSideAfterLoop(Undefined, Context);
	EndIf;	

EndProcedure

Procedure RunLoopOnSideAfterBatchSigningWritten(Result, Context) Export
	
	// It's a stub for the batch mode. Do not run the cycle of operations.
	Context.IndexOf = 0;
	
EndProcedure

Function VerifyCertificatesWithACloudSignature()
	
	Result = UseCloudSignatureService()
				And DigitalSignatureInternalServerCall.TheCloudSignatureServiceIsConfigured();
	
	Return Result;
	
EndFunction

Function EncryptDataWithACloudSignature()
	
	Result = UseCloudSignatureService()
				And DigitalSignatureInternalServerCall.TheCloudSignatureServiceIsConfigured();
	Result = False;
	
	Return Result;
	
EndFunction

// Continues the CheckCertificate procedure.
Procedure VerifyTheCloudSignatureCertificate(Context, ShouldRegisterErrors = True)
	
	Context.Insert("RegisterCloudServiceErrors", ShouldRegisterErrors);
	
	If TypeOf(Context.Certificate) = Type("CryptoCertificate") Then
		Context.Certificate.BeginUnloading(New CallbackDescription(
			"VerifyTheCloudSignatureCertificateAfterUploadingTheCertificate", ThisObject, Context));
	ElsIf TypeOf(Context.Certificate) = Type("Structure") Then
		VerifyTheCloudSignatureCertificateAfterUploadingTheCertificate(Context.Certificate.Certificate, Context);
	Else
		VerifyTheCloudSignatureCertificateAfterUploadingTheCertificate(Context.Certificate, Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure VerifyTheCloudSignatureCertificateAfterUploadingTheCertificate(Certificate, Context) Export
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateData = Certificate;
	Else
		CertificateData = GetFromTempStorage(Certificate);
	EndIf;
	
	If Not Context.RegisterCloudServiceErrors Then
		OperationParametersList = New Structure("ShouldRegisterError", False);
	Else
		OperationParametersList = Undefined;
	EndIf;
	
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	TheDSSCryptographyServiceModuleClient.CheckCertificate(
		New CallbackDescription("VerifyTheCertificateAfterVerifyingTheCloudSignature", ThisObject, Context),
		Undefined,
		CertificateData,
		OperationParametersList);
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure VerifyTheCertificateAfterVerifyingTheCloudSignature(CallResult, Context) Export
	
	If Not CallResult.Completed2 Then
		Context.ErrorDescriptionAtServer = 
			ErrorTextCloudSignature("CertificateCheck", CallResult, True);
		CheckCertificateAfterFailedCheck(Context);
		Return;
	EndIf;
	
	If Not CallResult.Result Then
		Context.ErrorDescriptionAtServer = ErrorTextCloudSignature("CertificateCheck", CallResult, False);
		ProcessErrorByClassifier(Context.ErrorDescriptionAtServer, Context.IsCheckRequiredAtServer, Context);
		CheckCertificateAfterFailedCheck(Context);
		Return;
	EndIf;
	
	AdditionalVerificationCertificate(Context.CryptoCertificate, True, Context);
	
EndProcedure

Procedure ProcessErrorByClassifier(ErrorText, IsCheckRequired, Context, ClassifierError = Undefined)
	
	If ClassifierError = Undefined And ValueIsFilled(ErrorText) Then
		ClassifierError = DigitalSignatureInternalClientCached.ClassifierError(ErrorText);
	EndIf;
	
	If ClassifierError = Undefined Then
		Return;
	EndIf;

	If ClassifierError.CertificateRevoked Then
		Context.CertificateRevoked = True;
		Try
			CertificateRef = DigitalSignatureInternalServerCall.DoWriteCertificateRevocationMark(
				Base64String(Context.CryptoCertificate.Thumbprint));
			If ValueIsFilled(CertificateRef) Then
				AdditionalParameters = ParametersNotificationWhenWritingCertificate();
				AdditionalParameters.Revoked = True;
				Notify("Write_DigitalSignatureAndEncryptionKeysCertificates", AdditionalParameters,
					CertificateRef);
			EndIf;
		Except
			Error = Error + Chars.LF
				+ ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
	Else
		IsCheckRequired = ClassifierError.IsCheckRequired;
	EndIf;
		
EndProcedure

// Continues the VerifySignature procedure.
Procedure VerifySignatureCloudSignature(Context)
	
	If TypeOf(Context.RawData) = Type("String")
		And IsTempStorageURL(Context.RawData) Then
		Context.RawData = GetFromTempStorage(Context.RawData);
	EndIf;
	
	Context.Insert("CryptoManager", "CloudSignature");
	Context.Insert("CheckCertificateAtClient");
	
	VerifyTheSignatureOnTheCloudSignatureClient(Context);
	
EndProcedure

// Continues the VerifySignature procedure.
Procedure VerifyTheSignatureOnTheCloudSignatureClient(Context)
	
	Signature = Context.Signature;
	RawData = Context.RawData;
	
	If TypeOf(Signature) = Type("String") And IsTempStorageURL(Signature) Then
		Signature = GetFromTempStorage(Signature);
	EndIf;
	
	If TypeOf(RawData) = Type("String") And IsTempStorageURL(RawData) Then
		RawData = GetFromTempStorage(RawData);
	EndIf;
	
	Context.Insert("SignatureData", Signature);
	Context.Insert("CryptoManager", "CloudSignature");
	
	HandlerNext = New CallbackDescription(
		"VerifyTheSignatureOnTheClientAfterVerifyingTheSignatureCloudSignature", ThisObject, Context,
		"CheckSignatureAtClientAfterCheckSignatureError", ThisObject);
	
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	TheDSSCryptographyServiceModuleClient.VerifySignature(
		HandlerNext,
		Undefined,
		Context.SignatureData,
		RawData,
		"CMS");
		
EndProcedure

// Continues the VerifySignature procedure.
Procedure VerifyTheSignatureOnTheClientAfterVerifyingTheSignatureCloudSignature(CallResult, Context) Export
	
	If Not CallResult.Completed2 Then
		ErrorText = ErrorTextCloudSignature("CheckSignature", CallResult, True);
		CheckSignatureAtClientAfterCheckSignatureError(ErrorText, False, Context);
		Return;
	EndIf;
	
	If Not CallResult.Result Then
		ErrorText = ErrorTextCloudSignature("CheckSignature", CallResult, False);
		CheckSignatureAtClientAfterCheckSignatureError(ErrorText, False, Context);
		Return;
	EndIf;
	
	CheckSignatureAtClientAfterCheckSignature(Undefined, Context);
	
EndProcedure

Function UseCloudSignatureService() Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		Return TheDSSCryptographyServiceModuleClient.UseCloudSignatureService();
	EndIf;
	
	Return False;
	
EndFunction

Function ServiceProgramTypeSignatures() Export
	
	Result = Undefined;
	
	If CommonClient.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		Result = TheDSSCryptographyServiceModuleClientServer.GetTheTypeOfCloudSignature();
	EndIf;
	
	Return Result;
	
EndFunction

Function ThisIsACloudSignatureOperation(TheFormContext) Export
	
	Result = False;
	
	If UseCloudSignatureService() Then
		CurrentData = GetDataCloudSignature(TheFormContext, "CertificateData");
		If TypeOf(CurrentData) = Type("Structure") Then
			Result = CurrentData.Cloud;
		EndIf;		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ResetThePasswordInMemory(CertificateReference) Export
	
	PassParametersForm().ResetTheCertificatePassword(CertificateReference);

EndProcedure

Function SetThePropertiesOfTheCloudSignature(DataDetails, NewValues) Export
	
	CloudSignatureData = GetThePropertiesOfACloudSignature(DataDetails);
	
	FillPropertyValues(CloudSignatureData, NewValues);
	
	Return CloudSignatureData;
	
EndFunction

Function GetThePropertiesOfACloudSignature(DataDetails) Export
	
	KeyName = "CloudSignatureProperties";
	CloudSignatureData = CommonClientServer.StructureProperty(DataDetails, KeyName);
	
	If CloudSignatureData = Undefined Then
		Result = New Structure();
		Result.Insert("Account", Undefined);
		Result.Insert("NotificationOnConfirmation", Undefined);
		Result.Insert("PackageData", Undefined);
		Result.Insert("ConfirmationData", Undefined);
		DataDetails.Insert(KeyName, Result);
	Else
		Result = CloudSignatureData;
	EndIf;	
	
	Return Result;
	
EndFunction

Procedure GetDataForACloudSignature(Notification, Form, DataDetails, DataSource, ForClientSide) Export
	
	GetDataFromDataDetails(Notification, Form, DataDetails, DataSource, ForClientSide);
	
EndProcedure

Function GetDataCloudSignature(TheFormContext, AttributeName) Export
	
	Result = Undefined;
	
	If UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		RegistryNames = ModuleCryptographyServiceDSSConfirmationClient.BaseRegisterDetails(TheFormContext, True);
		If RegistryNames <> Undefined Then
			FormAttributes = New Structure(RegistryNames[AttributeName], Undefined);
			FillPropertyValues(FormAttributes, TheFormContext);
			Result = FormAttributes[RegistryNames[AttributeName]];
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the adjusted text of the DDS error.
// 
// Parameters:
//  Operation - String - SignatureCheck, CertificateCheck, CertificateSearch, Signing, Encryption, Decryption.
//                      
//  CallResult - Undefined, Structure, String - Passes the error string for the built-in cryptographic provider.
//  ThisIsAnExecutionError - Boolean - This is a runtime error.
//  IsBuiltInCryptoProvider - Boolean - The built-in CSP
// 
// Returns:
//  String - Text of the cloud signature error.
//
Function ErrorTextCloudSignature(Operation, CallResult = Undefined, ThisIsAnExecutionError = False, IsBuiltInCryptoProvider = False) Export
	
	ServerAddress = "";
	SourceText = "";
	
	If Not IsBuiltInCryptoProvider Then
		If TypeOf(CallResult) = Type("Structure") Then
			If CallResult.Property("UserSettings") Then
				ServerAddress = CommonClientServer.StructureProperty(CallResult.UserSettings, "Server", "");
			EndIf;
			If CallResult.Property("ErrorStatus") Then
				SourceText = CommonClientServer.StructureProperty(CallResult.ErrorStatus, "SourceText", "");
			EndIf;
		EndIf;
	EndIf;
		
	If ValueIsFilled(SourceText) Then
		ErrorText = SourceText;
		If ThisIsAnExecutionError And ValueIsFilled(ServerAddress) Then
			ErrorText = ErrorText + " " + NStr("vi = 'trên máy chủ';
												|ru = 'на сервере';
												|en = 'on server'; fa = 'on server';
												|it = 'sul server';
												|pl = 'na serwerze';
												|tr = 'sunucuda'") + " " + TrimAll(ServerAddress);
		EndIf;
		
	ElsIf Operation = "CheckSignature" Then
		If ThisIsAnExecutionError Then
			ErrorText = NStr("vi = 'Không thể kiểm tra chữ ký.';
							|ru = 'Не удалось проверить подпись.';
							|en = 'Cannot verify the signature.'; fa = 'Cannot verify the signature.';
							|it = 'Impossibile verificare la firma.';
							|pl = 'Nie udało się sprawdzić podpisu.';
							|tr = 'İmza denetlenemedi.'");
		Else
			ErrorText = NStr("vi = 'Chữ ký không có hiệu lực.';
							|ru = 'Подпись недействительна.';
							|en = 'Invalid signature.'; fa = 'Invalid signature.';
							|it = 'Firma non valida.';
							|pl = 'Podpis jest nieważny.';
							|tr = 'İmza geçersiz.'");
		EndIf;
		
	ElsIf Operation = "CertificateCheck" Then
		If ThisIsAnExecutionError Then
			ErrorText = NStr("vi = 'Không thể kiểm tra chứng thư.';
							|ru = 'Не удалось проверить сертификат.';
							|en = 'Cannot verify the certificate.'; fa = 'Cannot verify the certificate.';
							|it = 'Impossibile verificare il certificato.';
							|pl = 'Nie udało się sprawdzić certyfikatu.';
							|tr = 'Sertifika denetlenemedi.'");
		Else
			ErrorText = NStr("vi = 'Chứng thư không có hiệu lực.';
							|ru = 'Сертификат недействителен.';
							|en = 'Invalid certificate.'; fa = 'Invalid certificate.';
							|it = 'Certificato non valido.';
							|pl = 'Certyfikat jest nieważny.';
							|tr = 'Sertifika geçersiz.'");
		EndIf;
		
	ElsIf Operation = "CertificateSearch" Then
		ErrorText = NStr("vi = 'Không thể tìm thấy chứng thư (có thể là đã bị xóa).';
						|ru = 'Не удалось найти сертификат (возможно удален).';
						|en = 'Couldn''t find the certificate. It might have been deleted.'; fa = 'Couldn''t find the certificate. It might have been deleted.';
						|it = 'Impossibile trovare il certificato (probabilmente eliminato).';
						|pl = 'Nie udało się znaleźć certyfikatu (możliwe, jest usunięty).';
						|tr = 'Sertifika bulunamadı (muhtemelen silindi).'");
		
	ElsIf Operation = "Signing" Then
		ErrorText = NStr("vi = 'Không thể tạo mới chữ ký.';
						|ru = 'Не удалось создать подпись.';
						|en = 'Failed to generate a signature.'; fa = 'Failed to generate a signature.';
						|it = 'Impossibile generare la firma.';
						|pl = 'Nie udało się utworzyć podpisu.';
						|tr = 'İmza oluşturulamadı.'");
		
	ElsIf Operation = "Encryption" Then
		ErrorText = NStr("vi = 'Không thể mã hóa dữ liệu.';
						|ru = 'Не удалось зашифровать данные.';
						|en = 'Cannot encrypt data.'; fa = 'Cannot encrypt data.';
						|it = 'Impossibile crittografare i dati.';
						|pl = 'Szyfrowanie danych nie powiodło się.';
						|tr = 'Veriler şifrelenemedi.'");
		
	ElsIf Operation = "Details" Then
		ErrorText = NStr("vi = 'Không thể giải mã dữ liệu.';
						|ru = 'Не удалось расшифровать данные.';
						|en = 'Cannot decrypt data.'; fa = 'Cannot decrypt data.';
						|it = 'Non è stato possibile decriptare i dati.';
						|pl = 'Deszyfracja danych nie powiodła się.';
						|tr = 'Veriler detaylandırılamadı.'");
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giao dịch không xác định ""%1"".';
				|ru = 'Неизвестная операция ""%1"".';
				|en = 'Unknown operation ""%1"".'; fa = 'Unknown operation ""%1"".';
				|it = 'Operazione sconosciuta ""%1"".';
				|pl = 'Nieznana operacja ""%1"".';
				|tr = 'Bilinmeyen işlem ""%1"".'"), Operation);
	EndIf;
	
	If IsBuiltInCryptoProvider Then
		
		If Not CommonClient.DataSeparationEnabled() Then
			RecommendationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hãy vô hiệu hóa hằng ""%1"".';
					|ru = 'Отключите константу ""%1"".';
					|en = 'Disable the constant ""%1"".'; fa = 'Disable the constant ""%1"".';
					|it = 'Отключите константу ""%1"".';
					|pl = 'Disable the constant ""%1"".';
					|tr = '""%1"" sabitini kapatın.'"), NStr("vi = 'Sử dụng chữ ký điện tử trong mô hình dịch vụ đám mây';
																	|ru = 'Использовать электронную подпись в модели сервиса';
																	|en = 'Use digital signature in SaaS'; fa = 'استفاده از امضای دیجیتال در SaaS';
																	|it = 'Использовать электронную подпись в модели сервиса';
																	|pl = 'Używaj podpisu elektronicznego w modelu serwisu';
																	|tr = 'Hizmet modelinde elektronik imza kullanma'"));
		Else
			RecommendationText = CallResult;
		EndIf;
		
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhà cung cấp mã hóa tích hợp: %1 %2';
				|ru = 'Встроенный криптопровайдер: %1 %2';
				|en = 'Built-in cryptographic service provider: %1 %2'; fa = 'Built-in cryptographic service provider: %1 %2';
				|it = 'Встроенный криптопровайдер: %1 %2';
				|pl = 'Built-in cryptographic service provider: %1 %2';
				|tr = 'Yerleşik kripto sağlayıcı'"), ErrorText, RecommendationText);
	Else
		Return NStr("vi = 'Dịch vụ DSS';
					|ru = 'Сервис DSS';
					|en = 'DSS service'; fa = 'DSS service';
					|it = 'Servizio DSS';
					|pl = 'Serwis DSS';
					|tr = 'DSS hizmeti'") + ": " + ErrorText;
	EndIf;
	
EndFunction

#EndRegion

#Region DigitalSignatureDiagnostics

// Creates an archive containing technical information and prompts the user to save it to the computer.
// Alternatively, it initiates a redirect to the support service website, where the technical information will be sent.
//
// Parameters:
//  Cause				 - String - the reason for collecting technical information.
//  MessageParameters	 - Undefined - If "Undefined", the technical information file will be downloaded.
//                    	 - Structure - If "Structure", redirect to the support service website, where the technical information will be sent.:
//                * Subject    - String - Message title.
//                * Message - String - Message body.
//  CompletionHandler - Undefined,
//                       - CallbackDescription - Contains details of the procedure that will be called
//  							after saving an archive to the computer with the following parameters:
//                ArchiveSaved - Boolean - Result of saving the archive to the hard drive.
//                AdditionalParameters - Arbitrary - Value specified when creating the NotifyDescription object.
//  							
//  AdditionalFiles	 - Undefined,
//                     	 - Structure - Additional data to be added in the archive.:
//                * Name    - String - File name with the extension.
//                * Data - BinaryData
//  					 - Array - Array of the above-mentioned structures.
//
Procedure GenerateTechnicalInformation(Cause,
	MessageParameters = Undefined, 
	CompletionHandler = Undefined,
	AdditionalFiles = Undefined) Export
	
	AccompanyingText = TrimL(TrimR(Cause) + Chars.LF + Chars.LF)
		+ NStr("vi = 'Thông tin máy tính:';
				|ru = 'Информация о компьютере:';
				|en = 'Computer information:'; fa = 'Computer information:';
				|it = 'Informazione sul computer:';
				|pl = 'Informacje o komputerze:';
				|tr = 'Bilgisayar bilgileri:'") + Chars.LF + Chars.LF
		+ DiagnosticsInformationOnComputer() + Chars.LF;
	
	Context = New Structure;
	Context.Insert("ExportArchive", MessageParameters = Undefined);
	If MessageParameters <> Undefined Then
		Context.Insert("Subject", MessageParameters.Subject);
		Context.Insert("Message");
		If ValueIsFilled(MessageParameters.Message) Then
			Context.Message = MessageParameters.Message;
		Else
			Context.Message = TechnicalSupportRequestText();
		EndIf;
	EndIf;
	
	If AdditionalFiles = Undefined Then
		Files = New Array;
	ElsIf TypeOf(AdditionalFiles) = Type("Structure") Then
		Files = New Array;
		Files.Add(AdditionalFiles);
	Else
		Files = AdditionalFiles;
	EndIf;
	
	Context.Insert("AdditionalFiles", Files);
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("AccompanyingText", AccompanyingText);
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		GenerateTechnicalInfoWithScreenshot(Context);
		Return;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
	Notification = New CallbackDescription("AfterCollectingTechnicalInformationAboutTheComponent", ThisObject, Context);
	GetTheComponentVersion(Notification);
	
EndProcedure

Procedure GenerateTechnicalInfoWithScreenshot(Context)
	
	ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
		"SupportRequestsInternalClient");
	
	If Not ModuleSupportRequestsInternalClient.IsScreenshotAppAvailable() Then
		Notification = New CallbackDescription("AfterCollectingTechnicalInformationAboutTheComponent", ThisObject, Context);
		GetTheComponentVersion(Notification);
		Return;
	EndIf;
	
	IsMessagesToTechSupportServiceAvailable =
		ModuleSupportRequestsInternalClient.IsMessagesToTechSupportServiceAvailable();
	
	// JPG and PNG files cannot be attached to support tickets.
	If Not Context.ExportArchive And IsMessagesToTechSupportServiceAvailable Then
		Notification = New CallbackDescription("AfterCollectingTechnicalInformationAboutTheComponent", ThisObject, Context);
		GetTheComponentVersion(Notification);
		Return;
	EndIf;
	
	CompletionHandler = New CallbackDescription(
		"ContinueGenerateTechnicalInfoWithScreenshot",
		ThisObject,
		Context);
	
	ModuleSupportRequestsInternalClient.RequestTakeScreenshot(CompletionHandler);
	
EndProcedure

Procedure ContinueGenerateTechnicalInfoWithScreenshot(Result, Context) Export
	
	If Result <> Undefined Then
		FileData = New Structure("Name, Data", Result.FullFileName, Result.FileAddress);
		Context.AdditionalFiles.Add(FileData);
	EndIf;
	
	Notification = New CallbackDescription("AfterCollectingTechnicalInformationAboutTheComponent", ThisObject, Context);
	GetTheComponentVersion(Notification);
	
EndProcedure

Function DiagnosticsInformationOnComputer()
	
	Return NStr("vi = 'Khách hàng:';
				|ru = 'Клиент:';
				|en = 'Client:'; fa = 'Client:';
				|it = 'Cliente:';
				|pl = 'Client:';
				|tr = 'İstemci:'") + Chars.LF
		+ StandardSubsystemsClient.SupportInformation();
	
EndFunction

Async Procedure DiagnosticInfoAboutAutoDefinedApps(Notification)
	
	UsedAppsResult = Await InstalledCryptoProviders(, False);
	
	If Not UsedAppsResult.CheckCompleted Then
		RunCallback(Notification, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa trên máy tính: %1';
				|ru = 'Не удалось автоматически определить приложение электронной подписи и шифрования на компьютере: %1';
				|en = 'Couldn''t determine the local digital signing and encryption app: %1'; fa = 'Couldn''t determine the local digital signing and encryption app: %1';
				|it = 'Не удалось автоматически определить приложение электронной подписи и шифрования на компьютере: %1';
				|pl = 'Couldn''t determine the local digital signing and encryption app: %1';
				|tr = '%1 Bilgisayarınızdaki elektronik imza ve şifreleme uygulaması otomatik olarak algılanamadı'"),
			UsedAppsResult.Error));
		Return;
	EndIf;
	
	Tokens = DigitalSignatureInternalClientServer.TokensTechnicalInfo(UsedAppsResult.Tokens, True);
	
	If UsedAppsResult.Cryptoproviders.Count() = 0 Then
		RunCallback(Notification, Tokens + Chars.LF + Chars.LF + NStr("vi = 'Trên máy tính không có ứng dụng chữ ký điện tử và mã hóa.';
																		|ru = 'На компьютере нет приложений электронной подписи и шифрования.';
																		|en = 'No installed digital signing and encryption apps are found.'; fa = 'No installed digital signing and encryption apps are found.';
																		|it = 'На компьютере нет приложений электронной подписи и шифрования.';
																		|pl = 'No installed digital signing and encryption apps are found.';
																		|tr = 'Bilgisayarda herhangi bir elektronik imza veya şifreleme uygulaması bulunmamaktadır.'"));
		Return;
	EndIf;
	
	Title = Chars.LF + Tokens + Chars.LF + Chars.LF + NStr("vi = 'Các ứng dụng chữ ký điện tử và mã hóa được tự động xác định trên máy tính:';
															|ru = 'Автоматически определенные приложения электронной подписи и шифрования на компьютере:';
															|en = 'Digital signing and encryption apps automatically detected on your computer:'; fa = 'Digital signing and encryption apps automatically detected on your computer:';
															|it = 'Автоматически определенные приложения электронной подписи и шифрования на компьютере:';
															|pl = 'Digital signing and encryption apps automatically detected on your computer:';
															|tr = 'Bilgisayarınızda otomatik olarak algılanan elektronik imza ve şifreleme uygulamaları:'") + Chars.LF;
	
	Context = New Structure;
	Context.Insert("IndexOf", 0);
	Context.Insert("Notification", Notification);
	Context.Insert("UsedApplications", UsedAppsResult.Cryptoproviders);
	Context.Insert("DiagnosticsInformation", Title);
	
	ApplicationsInfoCycleStart(Context);
	
EndProcedure

Procedure DiagnosticsInformationOnApplications(Notification)
	
	UsedApplications = DigitalSignatureInternalServerCall.UsedApplications();
	If UsedApplications.Count() = 0 Then
		RunCallback(Notification, "");
		Return;
	EndIf;
	Title = Chars.LF + NStr("vi = 'Ứng dụng trên client từ danh mục:';
							|ru = 'Приложения на клиенте из справочника:';
							|en = 'Client application from the catalog:'; fa = 'Client application from the catalog:';
							|it = 'Client application from the catalog:';
							|pl = 'Client application from the catalog:';
							|tr = 'Katalog üzerinden istemcideki uygulamalar:'") + Chars.LF;
	
	Context = New Structure;
	Context.Insert("IndexOf", 0);
	Context.Insert("Notification", Notification);
	Context.Insert("UsedApplications", UsedApplications);
	Context.Insert("DiagnosticsInformation", Title);
	
	ApplicationsInfoCycleStart(Context);
	
EndProcedure

Procedure ApplicationsInfoCycleStart(Context)
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ShowError = Undefined;
	CreationParameters.AutoDetect = False;
	CreationParameters.Application = Context.UsedApplications[Context.IndexOf];
	
	Notification = New CallbackDescription(
		"ApplicationsInfoAfterCreateCryptoManager",
		ThisObject, Context);
		
	CreateCryptoManager(Notification, "", CreationParameters);
	
EndProcedure

// Details
// 
// Parameters:
//   CryptoManager - CryptoManager
//   Context - Structure:
//   * IndexOf - Number
//
Procedure ApplicationsInfoAfterCreateCryptoManager(CryptoManager, Context) Export
	
	Context.DiagnosticsInformation = Context.DiagnosticsInformation
		+ DigitalSignatureInternalClientServer.DiagnosticInformationAboutTheProgram(
			Context.UsedApplications[Context.IndexOf],
			CryptoManager,
			CryptoManager);
	
	If Context.IndexOf = Context.UsedApplications.Count() - 1 Then
		RunCallback(Context.Notification, Context.DiagnosticsInformation);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationsInfoCycleStart(Context);
	
EndProcedure

Procedure AfterCollectingTechnicalInformationAboutTheComponent(AddInInformation, Context) Export
	
	Context.AccompanyingText = Context.AccompanyingText + Chars.LF 
	 + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Phiên bản cấu phần %1 trên client - %2';
																	|ru = 'Версия компоненты %1 на клиенте - %2';
																	|en = 'Add-in ""%1"" version on server: %2'; fa = 'Add-in ""%1"" version on server: %2';
																	|it = 'Versione della componente %1 su client - %2';
																	|pl = 'Wersja komponentu %1 na kliencie - %2';
																	|tr = 'İstemcide %1 bileşen sürümü - %2'"),
		"ExtraCryptoAPI", AddInInformation) + Chars.LF;
	
	DiagnosticInfoAboutAutoDefinedApps(
		New CallbackDescription("AfterCollectTechInfoAboutAutoDefiledApps",
		ThisObject, Context));
	
EndProcedure

Async Procedure AfterCollectTechInfoAboutAutoDefiledApps(ApplicationsInfo, Context) Export

	Context.AccompanyingText = Context.AccompanyingText + Chars.LF + ApplicationsInfo + Chars.LF;
	Notification = New CallbackDescription("AfterCollectingTechnicalInformationAboutThePrograms", ThisObject, Context);
	
	IsInstallingAddIns = Await InstallAddInsAfter1CEnterpriseExtensionChecked(Notification);
	If IsInstallingAddIns Then
		Return;
	EndIf;
	
	DiagnosticsInformationOnApplications(Notification);
	
EndProcedure

Async Procedure AfterCollectingTechnicalInformationAboutThePrograms(ApplicationsInfo, Context) Export
	
	Context.AccompanyingText = Context.AccompanyingText + ApplicationsInfo + Chars.LF
		+ TimestampServersDiagnosticsResult() + Chars.LF;
	
	SystemInfo = New SystemInfo;
	AddInLogDirectory = DigitalSignatureClient.PersonalSettings().PathToDiagnosticsDirectory.Get(
		SystemInfo.ClientID);
		
	If ValueIsFilled(AddInLogDirectory) Then
		
		AddInLog = "";
#If MobileClient Or MobileAppClient Then
		ObjectName = "";
		DigitalSignatureClientLocalization.OnReceivingMobileComponentID(ObjectName);
		If ValueIsFilled(ObjectName) Then
			AddInLog = CommonClientServer.AddLastPathSeparator(AddInLogDirectory)
				+ ObjectName +".log";
		EndIf;
#Else
		AddInLog = CommonClientServer.AddLastPathSeparator(AddInLogDirectory)
			+ DigitalSignatureInternalClientServer.ComponentDetails().ObjectName + ".log";
#EndIf
		
		If ValueIsFilled(AddInLog) Then
			File = New File(AddInLog);
			If Await File.ExistsAsync() Then
				FileBinaryData = Await CreateBinaryDataFromFileAsync(AddInLog);
				If ValueIsFilled(FileBinaryData) Then
					Context.AdditionalFiles.Add(
						New Structure("Name, Data", File.BaseName + ".txt", FileBinaryData));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If Context.ExportArchive Then
		Context.Insert("ArchiveAddress", DigitalSignatureInternalServerCall.TechnicalInformationArchiveAddress(
			Context.AdditionalFiles, Context.AccompanyingText, VerifiedPathsToProgramModules()));
		FileSystemClient.SaveFile(
			New CallbackDescription("GenerateTechnicalInformationAfterSaveFile", ThisObject, Context),
			Context.ArchiveAddress, "service_info.zip");
		Return;
	EndIf;
	
	TechnicalInfoFilesAddresses = DigitalSignatureInternalServerCall.TechnicalInfoFilesAddresses(
		Context.AccompanyingText, VerifiedPathsToProgramModules());
	
	Context.AdditionalFiles.Add(
		New Structure("Name, Data", TechnicalInfoFileName() + ".txt", TechnicalInfoFilesAddresses.TechnicalInformation));
	Context.AdditionalFiles.Add(
		New Structure("Name, Data", LogFileNameRegistration() + ".xml", TechnicalInfoFilesAddresses.EventLog));
	
	TechnicalSupportRequestParameters = TechnicalSupportRequestParameters();
	TechnicalSupportRequestParameters.Attachments = Context.AdditionalFiles;
	TechnicalSupportRequestParameters.Subject = Context.Subject;
	TechnicalSupportRequestParameters.Message = Context.Message;
	TechnicalSupportRequestParameters.CompletionHandler = Context.CompletionHandler;
	
	SendMessageToTechSupport(TechnicalSupportRequestParameters);
	
EndProcedure

Function TechnicalInfoFileName()
	Return NStr("vi = 'Tùy chỉnh chữ ký điện tử';
				|ru = 'Настройки электронной подписи';
				|en = 'Digital signature settings'; fa = 'Digital signature settings';
				|it = 'Настройки электронной подписи';
				|pl = 'Digital signature settings';
				|tr = 'Dijital imza ayarları'");
EndFunction

Function LogFileNameRegistration()
	Return NStr("vi = 'Nhật ký sự kiện';
				|ru = 'Журнал регистрации';
				|en = 'Event log'; fa = 'گزارش رویدادها';
				|it = 'Журнал регистрации';
				|pl = 'Informacja techniczna o rezultatach przetwarzania danych';
				|tr = 'Olay günlüğü'");
EndFunction

Procedure GetTheComponentVersion(Notification)
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để nhận phiên bản, cần cài đặt cấu phần %1';
			|ru = 'Для получения версии требуется установка компоненты %1';
			|en = 'To get the version, install add-in ""%1""'; fa = 'To get the version, install add-in ""%1""';
			|it = 'Per ricevere la versione è richiesta l''installazione della componente %1';
			|pl = 'Aby pobrać wersję wymagana jest instalacja komponentu %1';
			|tr = 'Sürümü almak için %1 bileşen kurulmalı'"), "ExtraCryptoAPI");
	ConnectionParameters.SuggestToImport = False;
	ConnectionParameters.SuggestInstall = False;
	
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	
	CommonClient.AttachAddInFromTemplate(
		New CallbackDescription("GetTheVersionAfterConnectingTheComponents", ThisObject, Notification),
		ComponentDetails.ObjectName,
		ComponentDetails.FullTemplateName,
		ConnectionParameters);
	
EndProcedure

// Continues the GetAddInVersion procedure.
Async Procedure GetTheVersionAfterConnectingTheComponents(Result, Notification) Export
	
	VersionComponents = "";
	
	If Result.Attached Then
		Try
			NotificationAfterReceivingTheVersion = New CallbackDescription("AfterReceivingTheComponentVersion", ThisObject, Notification);
			Result.Attachable_Module.BeginCallingGetVersion(NotificationAfterReceivingTheVersion);
			Return;
		Except
			VersionComponents = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định phiên bản cấu phần. %1';
					|ru = 'Не удалось определить версию компоненты. %1';
					|en = 'Couldn''t determine the add-in version. %1'; fa = 'Couldn''t determine the add-in version. %1';
					|it = 'Non è stato possibile definire la versione della componente. %1';
					|pl = 'Nie udało się określić wersji komponentu. %1';
					|tr = 'Bileşen sürümü tanımlanamadı. %1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	Else
		If IsBlankString(Result.ErrorDescription) Then
			// A user canceled the installation.
			VersionComponents = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa cài đặt cấu phần %1.';
					|ru = 'Компонента %1 не установлена.';
					|en = 'Add-in ""%1"" is not installed.'; fa = 'Add-in ""%1"" is not installed.';
					|it = 'Componente %1 non impostata.';
					|pl = 'Komponent %1 nie jest zainstalowany.';
					|tr = '%1bileşeni kurulmadı.'"), "ExtraCryptoAPI");
		Else
			// Installation failed. The error description is in Result.ErrorDetails.
			VersionComponents = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa cài đặt cấu phần %1 (%2).';
					|ru = 'Компонента %1 не установлена (%2).';
					|en = 'Add-in ""%1"" is not installed (%2).'; fa = 'Add-in ""%1"" is not installed (%2).';
					|it = 'Componente %1 non impostata (%2).';
					|pl = 'Komponent %1 nie jest zainstalowany (%2).';
					|tr = '%1bileşeni kurulmadı (%2).'"), "ExtraCryptoAPI", Result.ErrorDescription);
		EndIf;
		
#If WebClient Then
		If IsBlankString(Result.ErrorDescription) Then
			Components = NewCryptoManagementAddIns();
			Components.IsExtraCryptoAPIAddInInstalled = False;
			
			IsAdditionalAddInsInstallationRequired = Await IsAdditionalAddInsInstallationRequired(Components);
			If IsAdditionalAddInsInstallationRequired Then
				FormParameters = New Structure;
				FormParameters.Insert("Components", Components);
				FormParameters.Insert("RequiredAddInName", "ComponentExtraCryptoAPI");
				OpenForm("CommonForm.StartWorkWithDigitalSignature", FormParameters,
					, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
				Return;
			EndIf;
		EndIf;
#EndIf
		
	EndIf;
	
	RunCallback(Notification, VersionComponents);
	
EndProcedure

Procedure AfterReceivingTheComponentVersion(VersionComponents, Parameters, Notification) Export

	RunCallback(Notification, VersionComponents);
	
EndProcedure

Procedure RunAfterExtensionAndAddInChecked(Notification, Parameters = Undefined)
	
	Context = New Structure;
	Context.Insert("ShouldInstallExtension", True);
	Context.Insert("SetComponent", True);
	Context.Insert("ExplanationText");
	
	If TypeOf(Parameters) = Type("Structure") Then
		FillPropertyValues(Context, Parameters);
	EndIf;
	
	If Context.ExplanationText = Undefined Then
		Context.ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để thực hiện, cần cài đặt cấu phần %1';
				|ru = 'Для выполнения требуется установка компоненты %1';
				|en = 'To perform the action, install the %1 add-in'; fa = 'To perform the action, install the %1 add-in';
				|it = 'Per l''esecuzione è richiesta l''installazione della componente %1';
				|pl = 'W celu wykonania wymagana jest instalacja komponentu %1';
				|tr = 'Tamamlanması için %1 bileşeni kurulmalı'"), "ExtraCryptoAPI")
	EndIf;
		
	Context.Insert("Notification", Notification);
		
	BeginAttachingCryptoExtension(New CallbackDescription(
		"RunAfterAttachCryptoAddIn", ThisObject, Context));

EndProcedure

Procedure RunAfterAttachCryptoAddIn(Attached, Context) Export
	
	If Not Attached Then
		If Context.ShouldInstallExtension Then
			DigitalSignatureClient.InstallExtension(True,
				New CallbackDescription("RunAfterExtensionInstalled", ThisObject, Context));
			Return;
		Else
			ShouldContinueWithoutInstallingExtention = CommonClientServer.StructureProperty(
				Context, "ShouldContinueWithoutInstallingExtention", False);
			RunAfterExtensionInstalled(ShouldContinueWithoutInstallingExtention, Context);
			Return;
		EndIf;
	EndIf;
	
	RunAfterExtensionInstalled(True, Context);
	
EndProcedure

Procedure RunAfterExtensionInstalled(IsSet, Context) Export
	
	If IsSet <> True Then
		RunCallback(Context.Notification, ErrorTextExtensionNotInstalled());
		Return;
	EndIf;
	
	If Not CommonClient.IsWindowsClient()
	   And Not CommonClient.IsLinuxClient()
	   And Not CommonClient.IsMacOSClient() Then
		
		RunCallback(Context.Notification, ErrorTextDeviceNotSupported());
		Return;
	EndIf;
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = Context.ExplanationText;
	ConnectionParameters.SuggestInstall = Context.SetComponent;
	ConnectionParameters.SuggestToImport = Context.SetComponent;
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	CommonClient.AttachAddInFromTemplate(
		New CallbackDescription("RunAfterAddInAttached",
			ThisObject, Context),
		ComponentDetails.ObjectName, ComponentDetails.FullTemplateName, ConnectionParameters);
	
EndProcedure

Function ErrorTextExtensionNotInstalled()
	
	Return NStr("vi = 'Chưa cài đặt tiện ích mở rộng để làm việc với 1C:Enterprise.';
				|ru = 'Не установлено расширение для работы с 1С:Предприятием.';
				|en = '1C:Enterprise Extension is not installed.'; fa = '1C:Enterprise Extension is not installed.';
				|it = 'Не установлено расширение для работы с 1С:Предприятием.';
				|pl = 'Nie zainstalowano rozszerzenia do pracy z 1С:Enterprise.';
				|tr = '1C:Enterprise ile çalışma için uzantı yüklenmedi.'");
	
EndFunction

Procedure RunAfterAddInAttached(Result, Context) Export
	
	If Result.Attached Then
		
		RunCallback(Context.Notification, Result.Attachable_Module);
		
	Else

		If IsBlankString(Result.ErrorDescription) Then 
				
			// A user canceled the installation.
			RunCallback(Context.Notification, StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Thao tác không khả thi. Cần cài đặt cấu phần %1.';
							|ru = 'Операция невозможна. Требуется установка компоненты %1.';
							|en = 'Operation failed. Add-in is required: %1.'; fa = 'Operation failed. Add-in is required: %1.';
							|it = 'Impossibile eseguire l''operazione. È richiesta l''installazione della componente %1.';
							|pl = 'Operacja jest niemożliwa. Wymagana jest instalacja komponentu %1.';
							|tr = 'İşlem yapılamaz. %1 bileşeni kurulmalı.'"), "ExtraCryptoAPI"));

		Else
				
			// Installation failed. The error description is in Result.ErrorDetails.
			RunCallback(Context.Notification, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thao tác không khả thi. %1';
						|ru = 'Операция невозможна. %1';
						|en = 'Operation is not allowed. %1'; fa = 'Operation is not allowed. %1';
						|it = 'Impossibile eseguire l''operazione. %1';
						|pl = 'Operacja jest niemożliwa. %1';
						|tr = 'İşlem yapılamaz. %1'"), Result.ErrorDescription));

		EndIf;

	EndIf;
	
EndProcedure

Procedure NotifyOfSuccessfulAddInAttachement(Result, Context) Export
	
	If TypeOf(Result) = Type("String") Then
		ShowMessageBox(, Result);
		Return;
	EndIf;
	
	ClearInstalledCryptoProvidersCache();
	Notify("Installation_AddInExtraCryptoAPI");
	
EndProcedure

Async Function GetCertificatePropertiesAsync(Certificate, ComponentObject) Export
		
	CertificateBase64String = Await CertificateBase64String(Certificate);
	
	Result = New Structure("Error, CertificateProperties, CertificateBase64String", "");
	Result.CertificateBase64String = CertificateBase64String;
	
	Try
		
		Await ComponentObject.GetErrorListAsync();
		CertificatePropertiesResult = Await ComponentObject.GetCertificatePropertiesAsync(CertificateBase64String);
		
		Error = Await ComponentObject.GetErrorListAsync();
		If ValueIsFilled(Error) Then
			Raise Error;
		EndIf;
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificatePropertiesFromAddInResponse(
			CertificatePropertiesResult.Value);
	
		Result.CertificateProperties = CertificateProperties;
		
	Except
		
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận thuộc tính mở rộng của chứng thư: %1';
				|ru = 'Невозможно получить расширенные свойства сертификата: %1';
				|en = 'Unable to retrieve extended certificate properties: %1'; fa = 'Unable to retrieve extended certificate properties: %1';
				|it = 'Unable to retrieve extended certificate properties: %1';
				|pl = 'Unable to retrieve extended certificate properties: %1';
				|tr = 'Detaylandırılmış sertifika özellikleri alınamıyor: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Base64String certificate.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Base64String certificate
//             - CryptoCertificate
// 
// Returns:
//  Promise - Base64String certificate
//
Async Function CertificateBase64String(Certificate)
	
	If TypeOf(Certificate) = Type("String") And IsTempStorageURL(Certificate) Then
		Certificate = GetFromTempStorage(Certificate);
	EndIf;

	If TypeOf(Certificate) = Type("String") Then
		Return Certificate;
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Certificate = Await Certificate.UnloadAsync();
	ElsIf TypeOf(Certificate) = Type("BinaryData") Then
		CryptoCertificate = New CryptoCertificate;
		Await CryptoCertificate.InitializeAsync(Certificate);
		Certificate = Await CryptoCertificate.UnloadAsync();
	EndIf;
	
	Certificate = Base64String(Certificate);
	Certificate = StrReplace(Certificate, Chars.CR, "");
	Certificate = StrReplace(Certificate, Chars.LF, "");

	Return Certificate;
	
EndFunction 

Async Function CertificateFromString(TheCertificateIsAString) Export
	
	Certificate = StrReplace(TheCertificateIsAString, "-----BEGIN CERTIFICATE-----", "");
	Certificate = StrReplace(Certificate, "-----END CERTIFICATE-----", "");
	Certificate = StrReplace(Certificate, Chars.LF, "");
	
	Try
		CertificateData = Base64Value(Certificate);
	Except
		Return ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return NStr("vi = 'Không thể nhận chứng thư';
					|ru = 'Не удалось получить сертификат';
					|en = 'Cannot get the certificate'; fa = 'Cannot get the certificate';
					|it = 'Cannot get the certificate';
					|pl = 'Cannot get the certificate';
					|tr = 'Sertifika alınamadı'");
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate;
		Await CryptoCertificate.InitializeAsync(CertificateData);
	Except
		Return ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;

	Return CryptoCertificate;
	
EndFunction


#Region SettingRevocationList

// Parameters:
//   Context - Structure:
//   * Certificate - BinaryData
//               - String - Address in the temp storage.
//               - String - Base64String certificate
//               - CryptoCertificate
//
Async Procedure InstallCertificateRevocationListAfterAddInAttached(ComponentObject, Context) Export
	
	If TypeOf(ComponentObject) = Type("String") Then
		HandlerErrorOfSettingRevocationList(ComponentObject, Context);
		Return;
	EndIf;
	
	If ValueIsFilled(Context.Addresses) Then
		If TypeOf(Context.Addresses) = Type("String") Then
			Addresses = StrSplit(Context.Addresses, ";");
		EndIf;
	Else
		Addresses = New Array;
	EndIf;
	
	If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
		
		If TypeOf(Context.Certificate) = Type("CryptoCertificate") Then
			Certificate = Context.Certificate;
		ElsIf TypeOf(Context.Certificate) = Type("BinaryData") Then
			Certificate = New CryptoCertificate;
			Await Certificate.InitializeAsync(Context.Certificate);
		ElsIf IsTempStorageURL(Context.Certificate) Then
			CertificateBinaryData = GetFromTempStorage(Context.Certificate);
			Certificate = New CryptoCertificate;
			Await Certificate.InitializeAsync(CertificateBinaryData);
		Else
			CertificateBinaryData = Base64Value(Context.Certificate);
			Certificate = New CryptoCertificate;
			Await Certificate.InitializeAsync(CertificateBinaryData);
		EndIf;
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
			Certificate, UTCOffset());
		AddressesOfRevocationLists = CertificateProperties.AddressesOfRevocationLists;
		If AddressesOfRevocationLists.Count() = 0 And Not ValueIsFilled(Addresses) Then
			HandlerErrorOfSettingRevocationList(NStr("vi = 'Trong chứng thư chưa chỉ ra địa chỉ danh sách thu hồi.';
													|ru = 'В сертификате не указаны адреса списков отзыва.';
													|en = 'Revocation list addresses are not specified in the certificate.'; fa = 'Revocation list addresses are not specified in the certificate.';
													|it = 'Nel certificato non sono indicati gli indirizzi degli elenchi di chiamata.';
													|pl = 'W certyfikacie nie są podane adresy list odwołania.';
													|tr = 'İptal listesi adresleri sertifikada belirtilmemiştir.'"),
				Context);
			Return;
		EndIf;
		
	Else

		If TypeOf(Context.Certificate) = Type("BinaryData") Then
			CertificateBinaryData = Context.Certificate;
		ElsIf TypeOf(Context.Certificate) = Type("CryptoCertificate") Then
			CertificateBinaryData = Await Context.Certificate.UnloadAsync();
		ElsIf IsTempStorageURL(Context.Certificate) Then
			CertificateBinaryData = GetFromTempStorage(Context.Certificate);
		Else
			CertificateBinaryData = Base64Value(Context.Certificate);
		EndIf;

		CertificateProperties = DigitalSignatureInternalClientServer.CertificateAdditionalProperties(
			CertificateBinaryData);

		AddressesOfRevocationLists = Await AddressesOfRevocationLists(CertificateBinaryData, ComponentObject);
		If TypeOf(AddressesOfRevocationLists) = Type("String") And Not ValueIsFilled(Addresses) Then
			HandlerErrorOfSettingRevocationList(AddressesOfRevocationLists, Context);
			Return;
		EndIf;

	EndIf;
		
	For Each Address In AddressesOfRevocationLists Do
		If Addresses.Find(Address) = Undefined Then
			Addresses.Add(Address);
		EndIf;
	EndDo;

	Parameters = New Structure("ResourceAddress, NameOfTheOperation, InternalAddress");
	Parameters.ResourceAddress = Addresses;
	Parameters.InternalAddress = Context.InternalAddress;
	Parameters.NameOfTheOperation = NStr("vi = 'Kết nhập danh sách thu hồi chứng thư';
										|ru = 'Загрузка списка отзыва сертификата';
										|en = 'Import a certificate revocation list'; fa = 'Import a certificate revocation list';
										|it = 'Importazione dell''elenco di chiamata del buono';
										|pl = 'Przesyłanie listy odwołania certyfikatu';
										|tr = 'Sertifika geri bildirim listesinin indirilmesi'");

	Context.Insert("ComponentObject", ComponentObject);
	Context.Insert("ResourceAddress", Parameters.ResourceAddress);
	Context.Insert("CertificateAuthorityKeyID",
		CertificateProperties.CertificateAuthorityKeyID);
	
	TimeConsumingOperation = DigitalSignatureInternalServerCall.StartDownloadFileAtServer(Parameters);
	
	If Not TimeConsumingOperation.Property("ResultAddress") Then
		ResumeSettingRevocationListAfterDownloaded(TimeConsumingOperation, Context);
		Return;
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	IdleParameters.Title = Parameters.NameOfTheOperation;
	IdleParameters.OutputIdleWindow = True;
	
	CallbackOnCompletion = New CallbackDescription("ResumeSettingRevocationListAfterDownloaded",
		ThisObject, Context);
		
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

Async Function AddressesOfRevocationLists(CertificateBinaryData, ComponentObject)
	
	CertificatePropertiesExtended = Await GetCertificatePropertiesAsync(CertificateBinaryData, ComponentObject);

	If ValueIsFilled(CertificatePropertiesExtended.Error) Then
		Return CertificatePropertiesExtended.Error;
	EndIf;

	AddressesOfRevocationLists = CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists;
	If AddressesOfRevocationLists.Count() = 0 Then

		Return NStr("vi = 'Trong chứng thư chưa chỉ ra địa chỉ danh sách thu hồi.';
					|ru = 'В сертификате не указаны адреса списков отзыва.';
					|en = 'Revocation list addresses are not specified in the certificate.'; fa = 'Revocation list addresses are not specified in the certificate.';
					|it = 'В сертификате не указаны адреса списков отзыва.';
					|pl = 'W certyfikacie nie są podane adresy list odwołania.';
					|tr = 'Geri çekme listesi adresleri sertifikada belirtilmemiştir.'");
	EndIf;
	
	Return AddressesOfRevocationLists;
	
EndFunction

// Parameters:
//  ExecutionResult - See TimeConsumingOperationsClient.NewResultLongOperation
//  Context - Structure
//
Procedure ResumeSettingRevocationListAfterDownloaded(ExecutionResult, Context) Export
	
	If ExecutionResult = Undefined Then
		HandlerErrorOfSettingRevocationList(NStr("vi = 'Chưa hoàn tất kết nhập danh sách thu hồi như thông thường';
												|ru = 'Загрузка списка отзыва не была завершена штатно';
												|en = 'Abnormal end of certificate revocation list import'; fa = 'Abnormal end of certificate revocation list import';
												|it = 'Загрузка списка отзыва не была завершена штатно';
												|pl = 'Abnormal end of certificate revocation list import';
												|tr = 'İptal listesinin yüklenmesi normal şekilde tamamlanmadı'"), Context);
		Return;
	EndIf;
	
	If ExecutionResult.Status = "Error" Then
		HandlerErrorOfSettingRevocationList(ExecutionResult.ErrorInfo, Context);
		Return;
	EndIf;
	
	// Background job result.
	Try
		Result = GetFromTempStorage(ExecutionResult.ResultAddress);
	Except
		HandlerErrorOfSettingRevocationList(ErrorInfo(), Context);
		Return;
	EndTry;
	
	DeleteFromTempStorage(ExecutionResult.ResultAddress);
	
	If ValueIsFilled(Result.ErrorMessage) And Not ValueIsFilled(Result.FileData) Then
		HandlerErrorOfSettingRevocationList(Result.ErrorMessage, Context);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Result.FileData) Then
		HandlerErrorOfSettingRevocationList(
			NStr("vi = 'Không thể kết nhập danh sách thu hồi. Chi tiết xem trong nhật ký sự kiện.';
				|ru = 'Не удалось загрузить список отзыва. Подробнее см. в журнале регистрации.';
				|en = 'Cannot import the revocation list. For more information, see the event log.'; fa = 'Cannot import the revocation list. For more information, see the event log.';
				|it = 'Не удалось загрузить список отзыва. Подробнее см. в журнале регистрации.';
				|pl = 'Cannot import the revocation list. For more information, see the event log.';
				|tr = 'Geri bildirim listesi indirilemedi. Daha fazla bilgi için kayıt günlüklerine bakın.'"), Context);
		Return;
	EndIf;
	
	CommonClientServer.SupplementStructure(Result, Context);
	
	RevocationListProperties = DigitalSignatureInternalClientServer.RevocationListProperties(Result.FileData);
	
	If RevocationListProperties = Undefined Then
		HandlerErrorOfSettingRevocationList(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp %1 không phải là danh sách thu hồi.';
				|ru = 'Файл %1 не является списком отзыва.';
				|en = 'This file is not a revocation list: %1.'; fa = 'This file is not a revocation list: %1.';
				|it = 'Файл %1 не является списком отзыва.';
				|pl = 'Plik %1 nie jest listą odwołania.';
				|tr = '%1 dosyası bir geri çekme listesi değildir.'"), Result.FileAddress), Result, True);
		Return;
	EndIf;
	
	If ValueIsFilled(RevocationListProperties.EndDate) And RevocationListProperties.EndDate < CommonClient.UniversalDate() Then
		HandlerErrorOfSettingRevocationList(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Danh sách thu hồi %1 đã quá hạn. Hãy liên hệ với trung tâm chứng thực cấp chứng chỉ.';
				|ru = 'Список отзыва %1 просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
				|en = 'The certificate revocation list %1 is expired. Contact the certificate issuer.'; fa = 'The certificate revocation list %1 is expired. Contact the certificate issuer.';
				|it = 'Список отзыва %1 просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
				|pl = 'The certificate revocation list %1 is expired. Contact the certificate issuer.';
				|tr = 'Geri çekme listesinin süresi doldu. Sertifikayı veren sertifika yetkilisine başvurun.'"), Result.FileAddress), Result, True);
		Return;
	EndIf;
	
	If ValueIsFilled(Result.CertificateAuthorityKeyID)
		And ValueIsFilled(RevocationListProperties.CertificateAuthorityKeyID)
		And Result.CertificateAuthorityKeyID <> RevocationListProperties.CertificateAuthorityKeyID Then
		Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên khóa của trung tâm chứng thực của danh sách thu hồi đã nhận (%1) và chứng thư (%2) không khớp.
			|Hãy liên hệ với trung tâm chứng thực đã cấp chứng thư.';
			|ru = 'Не совпадают идентификаторы ключа удостоверяющего центра полученного списка отзыва (%1) и сертификата (%2).
			|Обратитесь в удостоверяющий центр, выдавший сертификат.';
			|en = 'CA key IDs mismatch in revocation list (%1) and in certificate (%2).
			|Contact the certificate issuer.'; fa = 'CA key IDs mismatch in revocation list (%1) and in certificate (%2).
			|Contact the certificate issuer.';
			|it = 'Не совпадают идентификаторы ключа удостоверяющего центра полученного списка отзыва (%1) и сертификата (%2).
			|Обратитесь в удостоверяющий центр, выдавший сертификат.';
			|pl = 'CA key IDs mismatch in revocation list (%1) and in certificate (%2).
			|Contact the certificate issuer.';
			|tr = 'Alınan geri çekme listesindeki (%1) ve sertifikanın (%2) sertifika yetkilisi anahtarının anahtar tanımlayıcıları eşleşmiyor.
			|Sertifikayı veren sertifika yetkilisiyle iletişime geçin.'"),
				RevocationListProperties.CertificateAuthorityKeyID, Result.CertificateAuthorityKeyID);
		HandlerErrorOfSettingRevocationList(Error, Result, True);
		Return;
	EndIf;
	
	FileSystemClient.CreateTemporaryDirectory(
		New CallbackDescription("InstallRevocationListAfterTempDirCreated", ThisObject, Result));
		
EndProcedure

// Install a revocation list after creating a temp directory.
// 
// Parameters:
//  TempDirectoryName - String
//  Context - Structure:
//               * FileName - String
//               * FileData - BinaryData
//
Async Procedure InstallRevocationListAfterTempDirCreated(TempDirectoryName, Context) Export
	
	If Not ValueIsFilled(TempDirectoryName) Then
		HandlerErrorOfSettingRevocationList(
			NStr("vi = 'Không thể tạo thư mục tạm thời để kết nhập danh sách thu hồi.';
				|ru = 'Не удалось создать временный каталог для загрузки списка отзыва.';
				|en = 'Cannot create a temporary directory to import a revocation list.'; fa = 'Cannot create a temporary directory to import a revocation list.';
				|it = 'Non è stato possibile creare una directory temporanea per l''importazione dell''elenco di chiamata.';
				|pl = 'Nie udało się utworzyć katalogu tymczasowego do przesyłania listy odwołania.';
				|tr = 'Geri bildirim listesinin indirilmesi için zamanlı katalog oluşturulamadı.'"), Context);
		Return;
	EndIf;
		
	RevocationListFilename = CommonClientServer.AddLastPathSeparator(TempDirectoryName)
	 + Context.FileName;
	
	Try
		Await Context.FileData.WriteAsync(RevocationListFilename);
	Except
		Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại danh sách thu hồi vào tệp ""%1"": %2. Hãy kiểm tra dung lượng trống, quyền truy cập và cài đặt phần mềm diệt vi-rút.';
				|ru = 'Не удалось записать список отзыва в файл ""%1"": %2. Проверьте наличие свободного места, права доступа и настройки антивируса.';
				|en = 'Failed to write the revocation list to file %1: %2. Please check available disk space, access permissions, and antivirus settings.'; fa = 'Failed to write the revocation list to file %1: %2. Please check available disk space, access permissions, and antivirus settings.';
				|it = 'Не удалось записать список отзыва в файл ""%1"": %2. Проверьте наличие свободного места, права доступа и настройки антивируса.';
				|pl = 'Failed to write the revocation list to file %1: %2. Please check available disk space, access permissions, and antivirus settings.';
				|tr = 'Не удалось записать список отзыва в файл ""%1"": %2. Проверьте наличие свободного места, права доступа и настройки антивируса.'"),
			RevocationListFilename, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		HandlerErrorOfSettingRevocationList(Error, Context);
		Return;
	EndTry;
	
	File = New File(RevocationListFilename);
	If Await File.ExistsAsync() Then
		FileSize = Await File.SizeAsync();
	Else
		Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại danh sách thu hồi vào tệp ""%1"": %2. Hãy kiểm tra dung lượng trống, quyền truy cập và cài đặt phần mềm diệt vi-rút.';
				|ru = 'Не удалось записать список отзыва в файл ""%1"". Проверьте наличие свободного места, права доступа и настройки антивируса.';
				|en = 'Failed to write the revocation list to file %1. Please check available disk space, access permissions, and antivirus settings.'; fa = 'Failed to write the revocation list to file %1. Please check available disk space, access permissions, and antivirus settings.';
				|it = 'Не удалось записать список отзыва в файл ""%1"". Проверьте наличие свободного места, права доступа и настройки антивируса.';
				|pl = 'Failed to write the revocation list to file %1. Please check available disk space, access permissions, and antivirus settings.';
				|tr = 'Не удалось записать список отзыва в файл ""%1"". Проверьте наличие свободного места, права доступа и настройки антивируса.'"),
			RevocationListFilename);
		HandlerErrorOfSettingRevocationList(Error, Context);
		Return;
	EndIf;
	
	Context.Insert("RevocationListFilename", RevocationListFilename);
	Context.Insert("TempDirectoryName", TempDirectoryName);

	StorageName = "CA";
	InstallResult = Await Context.ComponentObject.ImportCRuAsync(
		Context.RevocationListFilename, StorageName);
	
	If InstallResult.Value <> True Then
		
		Error = Await Context.ComponentObject.GetErrorListAsync();
		Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập danh sách thu hồi trong kho chứa ""%1"" từ tệp ""%2"" (%3 byte) do:
				 |%4';
				 |ru = 'Не удалось установить список отзыва в хранилище ""%1"" из файла ""%2"" (%3 байт) по причине:
				 |%4';
				 |en = 'Cannot install the revocation list to the ""%1"" store from file %2 (%3 byte) due to:
				 |%4'; fa = 'Cannot install the revocation list to the ""%1"" store from file %2 (%3 byte) due to:
				 |%4';
				 |it = 'Не удалось установить список отзыва в хранилище ""%1"" из файла ""%2"" (%3 байт) по причине:
				 |%4';
				 |pl = 'Cannot install the revocation list to the ""%1"" store from file %2 (%3 byte) due to:
				 |%4';
				 |tr = 'Не удалось установить список отзыва в хранилище ""%1"" из файла ""%2"" (%3 байт) по причине:
				 |%4'"), StorageName, RevocationListFilename, FileSize, Error);
		HandlerErrorOfSettingRevocationList(Error, Context);
		Return;
	Else
		
		Message = NStr("vi = 'Đã cài đặt thành công danh sách thu hồi.';
						|ru = 'Установка списка отзыва выполнена успешно.';
						|en = 'The revocation list is installed.'; fa = 'The revocation list is installed.';
						|it = 'Impostazione dell''elenco di chiamata eseguita con successo.';
						|pl = 'Ustawienie listy odwołania zostało wykonane pomyślnie.';
						|tr = 'Geri bildirim listesi başarıyla kuruldu.'");

		If Context.CallbackOnCompletion <> Undefined Then
			Result = CertificateInstallationResult();
			Result.IsInstalledSuccessfully = True;
			Result.Message = Message;
			RunCallback(Context.CallbackOnCompletion, Result);
		Else
			ShowMessageBox(, Message);
		EndIf;
		
	EndIf;
	
	Await DeleteFilesAsync(Context.TempDirectoryName);
	
EndProcedure

Procedure HandlerErrorOfSettingRevocationList(Error, Context, IsIssuerError = False)
	
	If TypeOf(Error) = Type(ErrorInfo()) Then
		If Context.CallbackOnCompletion = Undefined Then 
			StandardSubsystemsClient.OutputErrorInfo(Error);
			Return;
		EndIf;
		Error = ErrorProcessing.BriefErrorDescription(Error);
	EndIf;
	
	ResourceAddress = CommonClientServer.StructureProperty(Context, "ResourceAddress", Undefined);
	
	If ValueIsFilled(ResourceAddress) Then
		If IsIssuerError Then
			
			Error = Error + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Địa chỉ danh sách thu hồi mà được chỉ ra trong chứng thư: %1';
					|ru = 'Адрес списка отзыва, указанный в сертификате: %1';
					|en = 'Revocation list''s address in certificate: %1'; fa = 'Revocation list''s address in certificate: %1';
					|it = 'Адрес списка отзыва, указанный в сертификате: %1';
					|pl = 'Revocation list''s address in certificate: %1';
					|tr = 'Sertifikada belirtilen geri çekme listesi adresi: %1'"), StrConcat(ResourceAddress, Chars.LF));
			
		Else
			
			Error = Error + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hãy kết nhập thủ công và thiết lập danh sách thu hồi từ:
				|%1';
				|ru = 'Загрузите вручную и установите список отзыва с:
				|%1';
				|en = 'Manually import and install the revocation list from:
				|%1'; fa = 'Manually import and install the revocation list from:
				|%1';
				|it = 'Importare manualmente e impostare l''elenco di chiamata con:
				|%1';
				|pl = 'Prześlij ręcznie i ustaw listę odwołania od:
				|%1';
				|tr = 'Manuel olarak indirin ve geri bildirim listesini şöyle kurun:
				|%1'"), StrConcat(ResourceAddress, Chars.LF));
			
		EndIf;
	EndIf;
	
	If Context.CallbackOnCompletion <> Undefined Then
		
		Result = CertificateInstallationResult();
		Result.Message = Error;
		RunCallback(Context.CallbackOnCompletion, Result);
		
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể thiết lập danh sách thu hồi';
													|ru = 'Не удалось установить список отзыва';
													|en = 'Cannot install the revocation list.'; fa = 'Cannot install the revocation list.';
													|it = 'Не удалось установить список отзыва';
													|pl = 'Cannot install the revocation list.';
													|tr = 'Geri çekme listesi kurulamıyor'"));
		FormParameters.Insert("ErrorTextClient", Error);
		
		OpenExtendedErrorPresentationForm(FormParameters, Context.Form);
		
	EndIf;

EndProcedure

#EndRegion

#Region InstallingTheCertificate

// Install the root certificate after attaching the add-in.
// 
// Parameters:
//  ComponentObject - AddInObject  - Instance of the add-in object
//  InstallationParameters - See CertificateInstallationParameters
//
Async Procedure InstallRootCertificateAfterAddInAttached(ComponentObject, InstallationParameters) Export
	
	If TypeOf(ComponentObject) = Type("String") Then
		HandleCertificateInstallationError(ComponentObject, InstallationParameters);
		Return;
	EndIf;
	
	Result = Await CertificatesChainAsync(InstallationParameters.Certificate, ComponentObject);
		
	If ValueIsFilled(Result.Error) Then
		HandleCertificateInstallationError(Result.Error, InstallationParameters);
		Return;
	EndIf;
	
	If Result.Certificates.Count() = 0 Then
		HandleCertificateInstallationError(NStr("vi = 'Vòng lặp chứng thư không chứa chứng thư.';
												|ru = 'Цепочка сертификатов не содержит сертификатов.';
												|en = 'The certificate chain does not contain any certificates.'; fa = 'The certificate chain does not contain any certificates.';
												|it = 'Цепочка сертификатов не содержит сертификатов.';
												|pl = 'The certificate chain does not contain any certificates.';
												|tr = 'Sertifika zinciri sertifika içermiyor.'"), InstallationParameters);
		Return;
	EndIf;
	
	ValueList = New ValueList;
	If Not ValueIsFilled(InstallationParameters.Storage) Then
		ValueList.Add("ROOT", NStr("vi = 'Chứng thư gốc tin cậy';
									|ru = 'Доверенные корневые сертификаты';
									|en = 'Trusted root certificates'; fa = 'گواهی‌های ریشه مورد اعتماد';
									|it = 'Доверенные корневые сертификаты';
									|pl = 'Trusted root certificates';
									|tr = 'Güvenilir kök sertifikaları'"));
	Else
		ValueList.Add(InstallationParameters.Storage.Value,
			InstallationParameters.Storage.Presentation);
	EndIf;
	
	Certificate = Result.Certificates[Result.Certificates.UBound()];
	CertificateInstallationParameters = CertificateInstallationParameters(Certificate.CertificateData);
	CertificateInstallationParameters.InstallationOptions = ValueList;
	InstallCertificateAfterAddInAttached(ComponentObject, CertificateInstallationParameters);
	
EndProcedure

Procedure InstallCertificateAfterAddInAttached(ComponentObject, CertificateInstallationParameters) Export
	
	If TypeOf(ComponentObject) = Type("String") Then
		HandleCertificateInstallationError(ComponentObject, CertificateInstallationParameters);
		Return;
	EndIf;
	
	If CertificateInstallationParameters.InstallationOptions = Undefined
		Or TypeOf(CertificateInstallationParameters.InstallationOptions) = Type("ValueList")
		Or CertificateInstallationParameters.InstallationOptions = "Container"
		And CertificateInstallationParameters.ContainerProperties = Undefined Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Certificate", CertificateInstallationParameters.Certificate);
		FormParameters.Insert("InstallationOptions", CertificateInstallationParameters.InstallationOptions);
		
		FormClosingNotification = New CallbackDescription("RunAfterCertificateInstalled",
			ThisObject, CertificateInstallationParameters);
		
		OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.InstallingTheCertificate",
			FormParameters, CertificateInstallationParameters.Form,,,,
			FormClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;

	InstallCertificateAfterInstallationOptionSelected(CertificateInstallationParameters, ComponentObject);
	
EndProcedure

Async Procedure InstallCertificateAfterInstallationOptionSelected(CertificateInstallationParameters, ComponentObject = Undefined) Export
	
	Storage = CertificateInstallationParameters.Storage;
	StoragePresentation = "";
	If TypeOf(Storage) = Type("Structure") Then
		Storage = CertificateInstallationParameters.Storage.Value;
		StoragePresentation = CertificateInstallationParameters.Storage.Presentation;
	EndIf;
	
	If Not ValueIsFilled(StoragePresentation) Then
		StoragePresentation = Storage;
	EndIf;
	
	TheCertificateIsAString = Await CertificateBase64String(CertificateInstallationParameters.Certificate);
	If ComponentObject = Undefined Then
		Try
			ComponentObject = Await AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		Except
			Error = ErrorTextAddInNotInstalled();
			HandleCertificateInstallationError(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể thiết lập chứng thư trong %1.
					|%2';
					|ru = 'Не удалось установить сертификат в %1.
					|%2';
					|en = 'Cannot install the certificate in %1.
					|%2'; fa = 'Cannot install the certificate in %1.
					|%2';
					|it = 'Не удалось установить сертификат в %1.
					|%2';
					|pl = 'Cannot install the certificate in %1.
					|%2';
					|tr = 'Sertifika %1 hedefine kurulamıyor.
					|%2'"), StoragePresentation, Error), CertificateInstallationParameters);
		EndTry
	EndIf;
	
	Await ComponentObject.GetErrorListAsync();

	If ValueIsFilled(CertificateInstallationParameters.ContainerProperties) Then
		
		ContainerProperties = CertificateInstallationParameters.ContainerProperties;
		Result = Await ComponentObject.InstallCertificateToContainerAsync(
			ContainerProperties.ApplicationType, ContainerProperties.ApplicationName, ContainerProperties.Name, TheCertificateIsAString);
		If Result.Value <> True Then
			Error = Await ComponentObject.GetErrorListAsync();
			HandleCertificateInstallationError(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể liên kết chứng thư với nơi chứa %1.
						|%2';
						|ru = 'Не удалось связать сертификат с контейнером %1.
						|%2';
						|en = 'Cannot link the certificate with the %1 container.
						|%2'; fa = 'Cannot link the certificate with the %1 container.
						|%2';
						|it = 'Не удалось связать сертификат с контейнером %1.
						|%2';
						|pl = 'Cannot link the certificate with the %1 container.
						|%2';
						|tr = 'Sertifika %1 konteynerine bağlanamıyor.
						|%2'"), ContainerProperties.Name, Error), CertificateInstallationParameters);
			Return;
		EndIf;
		
		StoragePresentation = ContainerProperties.Name;
		
	Else
		
		Result = Await ComponentObject.BindCertToStoreAsync(TheCertificateIsAString, Storage);
	
		If Result.Value <> True Then
			Error = Await ComponentObject.GetErrorListAsync();
			HandleCertificateInstallationError(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể thiết lập chứng thư trong %1.
						|%2';
						|ru = 'Не удалось установить сертификат в %1.
						|%2';
						|en = 'Cannot install the certificate in %1.
						|%2'; fa = 'Cannot install the certificate in %1.
						|%2';
						|it = 'Не удалось установить сертификат в %1.
						|%2';
						|pl = 'Cannot install the certificate in %1.
						|%2';
						|tr = 'Sertifika %1 hedefine kurulamıyor.
						|%2'"), StoragePresentation, Error), CertificateInstallationParameters);
			Return;
		EndIf;
		
	EndIf;
	
	Result = CertificateInstallationResult();
	Result.IsInstalledSuccessfully = True;
	Result.Certificate = CertificateInstallationParameters.Certificate;
	Result.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thiết lập thành công chứng thư trong %1.';
				|ru = 'Сертификат успешно установлен в %1.';
				|en = 'The certificate is installed in %1.'; fa = 'The certificate is installed in %1.';
				|it = 'Сертификат успешно установлен в %1.';
				|pl = 'The certificate is installed in %1.';
				|tr = 'Sertifika başarıyla %1 konumuna kuruldu.'"), StoragePresentation);
	
	RunAfterCertificateInstalled(Result,
		New Structure("CallbackOnCompletion", CertificateInstallationParameters.CallbackOnCompletion));
	
EndProcedure

Procedure HandleCertificateInstallationError(Error, Context)
	
	If Context.CallbackOnCompletion <> Undefined Then
		
		Result = CertificateInstallationResult();
		Result.Message = Error;
		RunCallback(Context.CallbackOnCompletion, Result);
		
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể thiết lập chứng thư.';
													|ru = 'Не удалось установить сертификат.';
													|en = 'Cannot install the certificate.'; fa = 'Cannot install the certificate.';
													|it = 'Не удалось установить сертификат.';
													|pl = 'Cannot install the certificate.';
													|tr = 'Sertifika kurulamadı.'"));
		FormParameters.Insert("ErrorTextClient", Error);
		
		OpenExtendedErrorPresentationForm(FormParameters, Context.Form);
		
	EndIf;

EndProcedure

Procedure RunAfterCertificateInstalled(Result, Context) Export
	
	If Result = Undefined Then
		Result = CertificateInstallationResult();
		Result.IsInstalledSuccessfully = False;
		Result.Message = NStr("vi = 'Chưa thiết lập chứng thư.';
								|ru = 'Установка сертификата не выполнена.';
								|en = 'The certificate is not installed.'; fa = 'The certificate is not installed.';
								|it = 'Установка сертификата не выполнена.';
								|pl = 'The certificate is not installed.';
								|tr = 'Sertifikanın kurulumu gerçekleştirilemedi.'");
	EndIf;
	
	If Context.CallbackOnCompletion <> Undefined Then
		RunCallback(Context.CallbackOnCompletion, Result);
	Else
		ShowMessageBox(, Result.Message);
	EndIf;
	
EndProcedure

Function CertificateInstallationResult()
	
	Return New Structure("IsInstalledSuccessfully, Message, Certificate", False, "", "");
	
EndFunction

#EndRegion

#Region CertificatesChainRetrieval

// Gets the root certificate chain from a certificate
//
Procedure GetCertificateChain(Notification, Certificate, FormIdentifier = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Certificate", Certificate);
	Context.Insert("FormIdentifier", FormIdentifier);
		
	Notification = New CallbackDescription("GetCertificatesChainAfterAddInAttached",
		ThisObject, Context);
	RunAfterExtensionAndAddInChecked(Notification);
	
EndProcedure

Async Procedure GetCertificatesChainAfterAddInAttached(ComponentObject, Context) Export
	
	Result = New Structure("Certificates, Error", New Array, "");
	
	If TypeOf(ComponentObject) = Type("String") Then
		Result.Error = ComponentObject;
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	Result = Await CertificatesChainAsync(Context.Certificate, ComponentObject, Context.FormIdentifier);
	RunCallback(Context.Notification, Result);
	
EndProcedure

Async Function CertificatesChainAsync(Certificate, ComponentObject = Undefined, FormIdentifier = Undefined)
	
	Result = New Structure("Certificates, Error", New Array, "");
	Certificate = Await CertificateBase64String(Certificate);
	
	If ComponentObject = Undefined Then
		Try
			ComponentObject = Await AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(True);
		Except
			Result.Error = ErrorTextAddInNotInstalled();
			Return Result;
		EndTry;
	EndIf;
	
	Try
		Await ComponentObject.GetErrorListAsync();
		CertificatesResult = Await ComponentObject.GetCertificateChainAsync(Certificate);
		
		Error = Await ComponentObject.GetErrorListAsync();
		If ValueIsFilled(Error) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận vòng lặp chứng thư trên máy tính: %1';
					|ru = 'Не удалось получить цепочку сертификатов на компьютере: %1';
					|en = 'Cannot receive the certificate chain on the computer: %1'; fa = 'Cannot receive the certificate chain on the computer: %1';
					|it = 'Не удалось получить цепочку сертификатов на компьютере: %1';
					|pl = 'Cannot receive the certificate chain on the computer: %1';
					|tr = 'Bilgisayardaki sertifika zinciri alınamadı: %1'"),
				Error); 
		EndIf;
			
		If CertificatesResult = Undefined Then
			Raise NStr("vi = 'Không thể nhận vòng lặp chứng thư.';
						|ru = 'Не удалось получить цепочку сертификатов.';
						|en = 'Cannot receive the certificate chain.'; fa = 'Cannot receive the certificate chain.';
						|it = 'Не удалось получить цепочку сертификатов.';
						|pl = 'Cannot receive the certificate chain.';
						|tr = 'Sertifika zinciri alınamıyor.'");
		EndIf;
		
		Result = DigitalSignatureInternalClientServer.CertificatesChainFromAddInResponse(
			CertificatesResult.Value, FormIdentifier);

	Except
		Result.Insert("Error", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#Region InstallAndCheckCryptographyApps

// Result of obtaining installed CSP.
// 
// Returns:
//  Structure - Result of obtaining installed CSP:
//   * CheckCompleted - Boolean
//   * AddInInstalled - Boolean
//   * ExtensionInstalled - Boolean
//   * Cryptoproviders - Array
//   * CryptoProvidersAtServer - Array
//   * Error - String
//
Function InstalledCryptoProvidersGettingResult()
	
	Result = New Structure;
	Result.Insert("CheckCompleted",         False);
	Result.Insert("AddInInstalled",     False);
	Result.Insert("Cryptoproviders",          New Array);
	Result.Insert("Tokens",                    New Array);
	Result.Insert("CryptoProvidersAtServer", New Array);
	Result.Insert("Error", "");
	Return Result;
	
EndFunction

// Continues the GetInstalledCryptoProviders procedure
Async Procedure GetInstalledCryptoProvidersAfterAddInAttached(ComponentObject, Context) Export
	
	Result = Context.Result;
	
	If TypeOf(ComponentObject) = Type("String") Then
		Result.Error = ComponentObject;
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	Result.AddInInstalled = True;
	CryptoProvidersResult = Await InstalledCryptoProvidersFromCache(Context.SetComponent);
	If CryptoProvidersResult.CheckCompleted Then
		Result.Cryptoproviders = CryptoProvidersResult.Cryptoproviders;
		Result.Tokens = CryptoProvidersResult.Tokens;
		Result.CheckCompleted = True;
	Else
		Result.Error = CryptoProvidersResult.Error;
	EndIf;
	
	RunCallback(Context.Notification, Result);

EndProcedure

Async Function InstalledCryptoProviders(ComponentObject = Undefined, SuggestInstall = False) Export
	
	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Cryptoproviders", New Array);
	Result.Insert("Tokens", New Array);
	Result.Insert("Error", "");
	
#If MobileClient Or MobileAppClient Then
		Result.Insert("CheckCompleted", True);
		WriteInstalledCryptoProvidersToCache(Result);
		Return Result;
#EndIf

	If ComponentObject = Undefined Then
		
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để có được danh sách các ứng dụng chữ ký và mã hóa điện tử cài đặt trên máy tính, bạn cần cài đặt thành phần %1.';
				|ru = 'Для получения списка приложений электронной подписи и шифрования, установленных на компьютере, требуется установить компоненту %1.';
				|en = 'To import a list of installed digital signing and encryption apps, install the add-in %1.'; fa = 'To import a list of installed digital signing and encryption apps, install the add-in %1.';
				|it = 'Для получения списка приложений электронной подписи и шифрования, установленных на компьютере, требуется установить компоненту %1.';
				|pl = 'To import a list of installed digital signing and encryption apps, install the add-in %1.';
				|tr = 'Bilgisayarınızda yüklü elektronik imza ve şifreleme uygulamalarının bir listesini edinmek için %1bileşeni yüklemeniz gerekir.'"),
			"ExtraCryptoAPI");
		
		Try
			ComponentObject = Await AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(SuggestInstall, ExplanationText);
		Except
			Result.Error = ErrorTextAddInNotInstalled();
			WriteInstalledCryptoProvidersToCache(Result);
			Return Result;
		EndTry;
	EndIf;
		
	ErrorText = "";
	Try
		Await ComponentObject.GetErrorListAsync();
		ResultList = Await ComponentObject.GetListCryptoProvidersAsync();
		
		Error = Await ComponentObject.GetErrorListAsync();
		If ValueIsFilled(Error) Then
			Raise Error;
		EndIf;
		
		ApplicationsByNamesWithType = DigitalSignatureClient.CommonSettings().ApplicationsByNamesWithType;
		Cryptoproviders = DigitalSignatureInternalClientServer.InstalledCryptoProvidersFromAddInResponse(
			ResultList.Value, ApplicationsByNamesWithType);
		Result.CheckCompleted = True;
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If ValueIsFilled(ErrorText) Then
		Result.Error = ErrorText;
	Else
		Result.Cryptoproviders = Cryptoproviders;
	EndIf;
	
	TokensResult = Await DigitalSignatureClientLocalization.InstalledTokens(ComponentObject, SuggestInstall);
	Result.Tokens = TokensResult.Tokens;
	
	WriteInstalledCryptoProvidersToCache(Result);
	
	Return Result; 
	
EndFunction

Function TokenNewProperties() Export
	
	TokenProperties = New Structure;
	TokenProperties.Insert("Presentation", NStr("vi = 'Token';
												|ru = 'Токен';
												|en = 'Token'; fa = 'توکن';
												|it = 'Токен';
												|pl = 'Token';
												|tr = 'Token'"));
	TokenProperties.Insert("Model", "");
	TokenProperties.Insert("SerialNumber");
	TokenProperties.Insert("Slot");
	TokenProperties.Insert("Token");
	TokenProperties.Insert("Mechanisms");
	TokenProperties.Insert("Error");
	TokenProperties.Insert("Certificates");
	TokenProperties.Insert("Libraries", New Map);
	
	Return TokenProperties;
	
EndFunction

// Returns the result of checking CSP from the cache. Repeats every 20 minutes.
Async Function InstalledCryptoProvidersFromCache(SuggestInstall = False) Export
	
	ParameterName = "DigitalSignature.InstalledCryptoProviders";
	
	TimeAddition = 1200;
	
#If MobileClient Or MobileAppClient Then
		IsMobileClient = True;
#Else
		IsMobileClient = False;
#EndIf

	If ApplicationParameters[ParameterName] = Undefined 
		Or Not IsMobileClient And ApplicationParameters[ParameterName].CheckTime + TimeAddition < CurrentDate() // ACC:143 - CurrentDate() must be used.
		Or Not IsMobileClient And ApplicationParameters[ParameterName].Error = ErrorTextAddInNotInstalled() And SuggestInstall Then
		
		CheckResult = Await InstalledCryptoProviders(Undefined, SuggestInstall);
		Return CheckResult;
		
	Else
		
		ResultFromCache = ApplicationParameters[ParameterName];
		
		ArrayCryptoProviders = New Array;
		For Each Cryptoprovider In ResultFromCache.Cryptoproviders Do
			ArrayCryptoProviders.Add(New Structure(Cryptoprovider));
		EndDo;
		
		ArrayTokens = New Array;
		For Each Token In ResultFromCache.Tokens Do
			ArrayTokens.Add(New Structure(Token));
		EndDo;
		
		Result = New Structure;
		Result.Insert("CheckCompleted", ResultFromCache.CheckCompleted);
		Result.Insert("Cryptoproviders", ArrayCryptoProviders);
		Result.Insert("Tokens", ArrayTokens);
		Result.Insert("Error", ResultFromCache.Error);
		
		Return Result;
		
	EndIf;
	
EndFunction

Procedure ClearInstalledCryptoProvidersCache() Export
	
	ParameterName = "DigitalSignature.InstalledCryptoProviders";
	
	If ApplicationParameters[ParameterName] <> Undefined Then
		ApplicationParameters[ParameterName] = Undefined;
	EndIf;
	
EndProcedure

Procedure WriteInstalledCryptoProvidersToCache(Result) Export
	
	ResultForCache = New Structure;
	ResultForCache.Insert("CheckCompleted", Result.CheckCompleted);
	
	ArrayCryptoProviders = New Array;
	For Each Cryptoprovider In Result.Cryptoproviders Do
		ArrayCryptoProviders.Add(New FixedStructure(Cryptoprovider));
	EndDo;
	
	ResultForCache.Insert("Cryptoproviders", New FixedArray(ArrayCryptoProviders));
	
	TokensArray = New Array;
	For Each Token In Result.Tokens Do
		TokensArray.Add(New FixedStructure(Token));
	EndDo;
	
	ResultForCache.Insert("Tokens", New FixedArray(TokensArray));
	
	ResultForCache.Insert("Error", Result.Error);
	ResultForCache.Insert("CheckTime", CurrentDate()); // ACC:143 - CurrentDate() must be used.
	
	ParameterName = "DigitalSignature.InstalledCryptoProviders";
	ApplicationParameters.Insert(ParameterName, New FixedStructure(ResultForCache));
	
EndProcedure

Function ErrorTextAddInNotInstalled()
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa thiết lập cấu phần %1';
					|ru = 'Не установлена компонента %1';
					|en = 'The %1 add-in is not installed'; fa = 'The %1 add-in is not installed';
					|it = 'Не установлена компонента %1';
					|pl = 'The %1 add-in is not installed';
					|tr = '%1 bileşeni kurulamadı'"), "ExtraCryptoAPI");
	
EndFunction

// Continues the CheckCryptographyAppsInstallation procedure.
Async Procedure CheckCryptographyAppsInstallationAfterInstalledObtained(Result, Context) Export
	
	CheckResult = New Structure("AddInInstalled, Error, CheckCompleted");
	FillPropertyValues(CheckResult, Result);
	CheckResult.Insert("Programs", New Array);
	CheckResult.Insert("Tokens", Result.Tokens);
	CheckResult.Insert("ServerApplications", New Array);
	CheckResult.Insert("IsConflictPossible", False);
	CheckResult.Insert("IsConflictPossibleAtServer", False);
	
	If Not CheckResult.CheckCompleted Then
		RunCallback(Context.Notification, CheckResult);
		Return;
	EndIf;
	
	ProcessingParameters = New Structure("SignAlgorithms, AppsToCheck, DataType, ExtendedDescription");
	FillPropertyValues(ProcessingParameters, Context);
	ProcessingParameters.Insert("IsServer", False);
	
	HasAppsToCheck = False;
	
	DigitalSignatureInternalClientServer.DoProcessAppsCheckResult(Result.Cryptoproviders,
		CheckResult.Programs, CheckResult.IsConflictPossible, ProcessingParameters, HasAppsToCheck);
		
	ProcessingParameters.Insert("IsServer", True);
	DigitalSignatureInternalClientServer.DoProcessAppsCheckResult(Result.CryptoProvidersAtServer,
		CheckResult.ServerApplications, CheckResult.IsConflictPossibleAtServer, ProcessingParameters, HasAppsToCheck);
	
	StandardProcessing = Await DigitalSignatureClientLocalization.OnContinueCheckInstalledCryptoApps(
		Context, CheckResult, HasAppsToCheck);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	RunCallback(Context.Notification, CheckResult);

EndProcedure

// Returns:
//  Structure:
//   * CallbackOnCompletion - CallbackDescription
//   * Programs  - See DigitalSignatureInternalServerCall.
//   * IndexOf - Number
//
Function InstalledApplicationsSearchContext()
	
	Context = New Structure;
	Context.Insert("IndexOf");
	Context.Insert("Programs");
	Context.Insert("CallbackOnCompletion");
	
	Return Context;
	
EndFunction



#EndRegion

#EndRegion

#Region SendingTechnicalSupportRequest

Function TechnicalSupportRequestParameters()
	
	TechnicalSupportRequestParameters = New Structure;
	TechnicalSupportRequestParameters.Insert("Attachments", New Array);
	TechnicalSupportRequestParameters.Insert("Subject");
	TechnicalSupportRequestParameters.Insert("Message");
	TechnicalSupportRequestParameters.Insert("CompletionHandler");
	TechnicalSupportRequestParameters.Insert("Recipient", TechnicalSupportRequestRecipient());
	
	Return TechnicalSupportRequestParameters;
	
EndFunction

Procedure SendMessageToTechSupport(TechnicalSupportRequestParameters)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") Then
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient = CommonClient.CommonModule("MessagesToTechSupportServiceClient");
		TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer = CommonClient.CommonModule("MessagesToTechSupportServiceClientServer");
			
			MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
			MessageData.Subject = TechnicalSupportRequestParameters.Subject;
			MessageData.Recipient = TechnicalSupportRequestParameters.Recipient;
			MessageData.Message = TechnicalSupportRequestParameters.Message;
			
			Attachments = New Array;
			For Each Attachment In TechnicalSupportRequestParameters.Attachments Do
				If TypeOf(Attachment.Data) = Type("BinaryData") Then
					Attachment.Data = PutToTempStorage(Attachment.Data, New UUID);
				EndIf;
				Attachments.Add(New Structure("Presentation, Data, DataKind", Attachment.Name, Attachment.Data, "Address"));
			EndDo;
			
			CallbackOnCompletion = New CallbackDescription("AfterSupportRequestChecked", ThisObject, TechnicalSupportRequestParameters);
			TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(MessageData, Attachments, Undefined, CallbackOnCompletion);
		Return;
	EndIf;
	
	AfterSupportRequestChecked(Undefined, TechnicalSupportRequestParameters);
	
EndProcedure

Procedure AfterSupportRequestChecked(Result, Context) Export
	
	If Result <> Undefined And ValueIsFilled(Result.ErrorCode) Then
		EventLogClient.AddMessageForEventLog(
				NStr("vi = 'Chữ ký điện tử.Gửi thông báo đến bộ phận hỗ trợ kỹ thuật';
					|ru = 'Электронная подпись.Отправка сообщения в техподдержку';
					|en = 'Digital signature.Send request to technical support'; fa = 'Digital signature.Send request to technical support';
					|it = 'Электронная подпись.Отправка сообщения в техподдержку';
					|pl = 'Digital signature.Send request to technical support';
					|tr = 'Dijital imza. Teknik desteğe mesaj gönder.'", CommonClient.DefaultLanguageCode()),
				"Error", Result.ErrorCode + " " + Result.ErrorMessage,, True);
	ElsIf Result <> Undefined Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		CallbackOnCompletion = New CallbackDescription("AfterEmailAccountVerified", ThisObject, Context);
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackOnCompletion); 
		Return;
	EndIf;

	AfterEmailAccountVerified(Undefined, Context);
	
EndProcedure

// Generates a support ticket text.
//
// Parameters:
//  Message - String - A user message
//
// Returns:
//  String - A message created from a template.
//
Function MessageTextTemplate(Message)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xin chào.
			|
			|%1';
			|ru = 'Здравствуйте.
			|
			|%1';
			|en = 'Hello.
			|
			|%1'; fa = 'Hello.
			|
			|%1';
			|it = 'Здравствуйте.
			|
			|%1';
			|pl = 'Hello.
			|
			|%1';
			|tr = 'Merhaba.
			|
			|%1'"),
		Message);
	
EndFunction

Function TechnicalSupportRequestText() Export
	Return NStr("vi = '<Mô tả sự cố xảy ra, đính kèm ảnh chụp màn hình lỗi và phiên bản của ứng dụng chữ ký điện tử và mã hóa (nhà cung cấp mã hóa).>';
				|ru = '<Опишите возникшую проблему, приложите скриншоты ошибки и версии приложения электронной подписи и шифрования (криптопровайдера).>';
				|en = '<Describe your issue and attach screenshots of the error and the version of your digital signing and encryption app>'; fa = '<Describe your issue and attach screenshots of the error and the version of your digital signing and encryption app>';
				|it = '<Опишите возникшую проблему, приложите скриншоты ошибки и версии приложения электронной подписи и шифрования (криптопровайдера).>';
				|pl = '<Describe your issue and attach screenshots of the error and the version of your digital signing and encryption app>';
				|tr = '<Karşılaştığınız sorunu açıklayın, hatanın ekran görüntülerini ve elektronik imza ve şifreleme uygulamasının (kripto sağlayıcı) sürümünü ekleyin.>'");
EndFunction

Function TechnicalSupportRequestTextUponCertificateCheck() Export
	Return NStr("vi = '<Mô tả sự cố xảy ra, đính kèm ảnh chụp màn hình lỗi và phiên bản của ứng dụng chữ ký điện tử và mã hóa (nhà cung cấp mã hóa), cũng như
		|kết quả kiểm tra chứng thư bằng các công cụ của nhà cung cấp mã hóa.>';
		|ru = '<Опишите возникшую проблему, приложите скриншоты ошибки и версии приложения электронной подписи и шифрования (криптопровайдера), а также
		|результаты тестирования сертификата средствами криптопровайдера.>';
		|en = '<Describe your issue and attach the following: screenshots of the error, digital signing and encryption app,
		|and the results of certificate validation by app tools.>'; fa = '<Describe your issue and attach the following: screenshots of the error, digital signing and encryption app,
		|and the results of certificate validation by app tools.>';
		|it = '<Опишите возникшую проблему, приложите скриншоты ошибки и версии приложения электронной подписи и шифрования (криптопровайдера), а также
		|результаты тестирования сертификата средствами криптопровайдера.>';
		|pl = '<Describe your issue and attach the following: screenshots of the error, digital signing and encryption app,
		|and the results of certificate validation by app tools.>';
		|tr = '<Ortaya çıkan sorunu açıklayın, hatanın ekran görüntülerini ve elektronik imza ve şifreleme uygulamasının (kripto sağlayıcı) sürümünün yanı sıra
		|kript sağlayıcının araçlarını kullanarak sertifikayı test etme sonuçlarını ekleyin.>'");
EndFunction

Function TechnicalSupportRequestRecipient()
	Recipient = "v8";
	DigitalSignatureClientLocalization.OnDefineTechnicalSupportRequestRecipient(Recipient);
	Return Recipient;
EndFunction

Function TechnicalSupportRequestRecipientAddress()
	Return "v8@1c.ru";
EndFunction
	
Procedure AfterEmailAccountVerified(Result, Context) Export
	
	If Result = True Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		EmailSendOptions = ModuleEmailOperationsClient.EmailSendOptions();
		EmailSendOptions.Subject = Context.Subject;
		EmailSendOptions.Text = MessageTextTemplate(Context.Message);
		EmailSendOptions.Recipient = TechnicalSupportRequestRecipientAddress();
		
		CompletionHandler = New CallbackDescription("AfterEmailMessageSentToSupport", ThisObject,
			Context);
		
		Attachments = New Array;
		For Each Attachment In Context.Attachments Do
			If TypeOf(Attachment.Data) = Type("BinaryData") Then
				Attachment.Data = PutToTempStorage(Attachment.Data, New UUID);
			EndIf;
			Attachments.Add(New Structure("Presentation, AddressInTempStorage", Attachment.Name, Attachment.Data));
		EndDo;
		
		EmailSendOptions.Attachments = Attachments;
		ModuleEmailOperationsClient.CreateNewEmailMessage(EmailSendOptions, CompletionHandler);
		Return;
	EndIf;
	
	Context.Insert("ArchiveAddress", DigitalSignatureInternalServerCall.TechnicalInformationArchiveAddress(
		Context.Attachments));
	FileSystemClient.SaveFile(
		New CallbackDescription("GenerateTechnicalInformationAfterSaveFile", ThisObject, Context),
		Context.ArchiveAddress, "service_info.zip");
EndProcedure

Procedure AfterEmailMessageSentToSupport(Result, Context) Export
	
	For Each Attachment In Context.Attachments Do
		DeleteFromTempStorage(Attachment.Data);
	EndDo;
	
EndProcedure

Procedure GenerateTechnicalInformationAfterSaveFile(SavedFiles, Context) Export
	
	If ValueIsFilled(SavedFiles) Then
		FileSystemClient.OpenExplorer(SavedFiles[0].FullName);
	EndIf;
	
	DeleteFromTempStorage(Context.ArchiveAddress);
	If Context.CompletionHandler <> Undefined Then
		RunCallback(Context.CompletionHandler, SavedFiles <> Undefined);
	EndIf;
	
EndProcedure

#EndRegion


Procedure ShowCertificateCheckResult(Certificate, Result, FormOwner,
	Title = "", MergeResults = "DontMerge", CompletionProcessing = Undefined) Export
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("FormCaption", Title);
	ServerParameters1.Insert("CheckOnSelection");
	ServerParameters1.Insert("AdditionalChecksParameters");
	ServerParameters1.Insert("Certificate", Certificate);
	ServerParameters1.Insert("CheckResult", Result);
	ServerParameters1.Insert("MergeResults", MergeResults);
	
	PassParametersForm().OpenNewForm("CertificateCheck",
		ServerParameters1, New Structure, CompletionProcessing, FormOwner);
	
EndProcedure

Procedure HandleNaviLinkClassifier(Item, FormattedStringURL, StandardProcessing, AdditionalData = Undefined) Export
	
	StandardProcessing = False;
	ContinueHandleClassifierURL(Item, FormattedStringURL, AdditionalData);
	
EndProcedure

Async Procedure ContinueHandleClassifierURL(Item, FormattedStringURL, AdditionalData) 
	
	Parameters = AdditionalDataForErrorClassifier();
	If TypeOf(AdditionalData) = Type("Structure") Then
		FillPropertyValues(Parameters, AdditionalData);
	EndIf;
	
	ContinueProcessing = Await DigitalSignatureClientLocalization.OnHandleClassifierURL(Item, 
		FormattedStringURL, Parameters);
	
	If Not ContinueProcessing Then
		Return;
	EndIf;
	
	If FormattedStringURL = "OpenCertificate" Then
		If ValueIsFilled(Parameters.Certificate)
			And TypeOf(Parameters.Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
			ShowValue( , Parameters.Certificate);
		ElsIf ValueIsFilled(Parameters.CertificateData) Then
			FormParameters = New Structure;
			FormParameters.Insert("CertificateAddress", Parameters.CertificateData);
			OpenCertificateForm(FormParameters);
		EndIf;
	ElsIf FormattedStringURL = "OpenProgramList" Then
		
		DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Programs");
		
	ElsIf FormattedStringURL = "ApplyforCertificate" Then
		
		CreationParameters = New Structure;
		CreationParameters.Insert("CreateRequest", True);
		If ValueIsFilled(Parameters.Certificate) And TypeOf(Parameters.Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
			CreationParameters.Insert("CertificateBasis", Parameters.Certificate);
		EndIf;
		ToAddCertificate(CreationParameters);

	ElsIf FormattedStringURL = "SetListOfCertificateRevocation" Then
		
		If ValueIsFilled(Parameters.CertificateData) Then
			RevocationListInstallationParameters = RevocationListInstallationParameters(Parameters.CertificateData);
			RevocationListInstallationParameters.CallbackOnCompletion = NotificationAfterClassifierURLHandled(
				FormattedStringURL, Parameters.CertificateData);
			SetListOfCertificateRevocation(RevocationListInstallationParameters);
		EndIf;
	
	ElsIf FormattedStringURL = "InstallRootCertificate" Then
		
		If ValueIsFilled(Parameters.CertificateData) Then
			CertificateInstallationParameters = CertificateInstallationParameters(Parameters.CertificateData);
			CertificateInstallationParameters.CallbackOnCompletion = NotificationAfterClassifierURLHandled(
				FormattedStringURL, Parameters.CertificateData);
			InstallRootCertificate(CertificateInstallationParameters);
		EndIf;
	
	ElsIf FormattedStringURL = "InstallCertificate" Then
		
		If ValueIsFilled(Parameters.CertificateData) Then
			CertificateInstallationParameters = CertificateInstallationParameters(Parameters.CertificateData);
			CertificateInstallationParameters.CallbackOnCompletion = NotificationAfterClassifierURLHandled(
				FormattedStringURL, Parameters.CertificateData);
			InstallCertificate(CertificateInstallationParameters);
		EndIf;
		
	ElsIf FormattedStringURL = "InstallCertificateIntoContainer" Then
		
		If ValueIsFilled(Parameters.CertificateData) Then
			CertificateInstallationParameters = CertificateInstallationParameters(Parameters.CertificateData);
			CertificateInstallationParameters.CallbackOnCompletion = NotificationAfterClassifierURLHandled(
				FormattedStringURL, Parameters.CertificateData);
			CertificateInstallationParameters.InstallationOptions = "Container";
			InstallCertificate(CertificateInstallationParameters);
		EndIf;
		
	ElsIf FormattedStringURL = "TimestampServersDiagnosticsServer" Then
		
		TimestampServersDiagnostics("Server");
	
	ElsIf FormattedStringURL = "TimestampServersDiagnosticsClient" Then
		
		TimestampServersDiagnostics("Client");
		
	ElsIf FormattedStringURL = "OpenDigitalSignatureSettings" Then
		
		If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
			AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
			AppSettingsModuleClient.OpenCommonSettings();
		EndIf;
		
	ElsIf FormattedStringURL = "InstallAddInSSL" Then
		
		Notification = New CallbackDescription("NotifyOfSuccessfulAddInAttachement", ThisObject);
			RunAfterExtensionAndAddInChecked(Notification);
			
	ElsIf StrStartsWith(FormattedStringURL, DigitalSignatureInternalClientServer.ActionInstallLibrariesForTokens()) Then
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("TokenKind", Right(FormattedStringURL,
			StrLen(FormattedStringURL) - StrLen(DigitalSignatureInternalClientServer.ActionInstallLibrariesForTokens())));
			OpeningParameters.Insert("OnlyTokenInstallation", True);
		OpenCryptoProviderAppsInstallationForm(OpeningParameters);
			
	ElsIf StrFind(FormattedStringURL, "http") Then
		FileSystemClient.OpenURL(FormattedStringURL, );
	ElsIf StrStartsWith(FormattedStringURL, "e1cib") Then 
		FileSystemClient.OpenURL(FormattedStringURL);
	Else
		ShowMessageBox(, NStr("vi = 'Thao tác sẽ là khả dụng trong các bản cập nhật ứng dụng tiếp theo';
								|ru = 'Действие будет доступно в следующих обновлениях приложения';
								|en = 'The action will be available in the next application updates'; fa = 'The action will be available in the next application updates';
								|it = 'Действие будет доступно в следующих обновлениях приложения';
								|pl = 'The action will be available in the next application updates';
								|tr = 'Eylem gelecekteki uygulama güncellemelerinde mevcut olacak'"));
	EndIf;

EndProcedure

Function NotificationAfterClassifierURLHandled(URL, NotificationSubject)
	
	Return New CallbackDescription("AfterClassifierURLHandled", ThisObject,
		New Structure("URL, NotificationSubject", URL, NotificationSubject));

EndFunction

Procedure AfterClassifierURLHandled(Result, Context) Export
	
	URL = Context.URL;
	If URL = "InstallCertificate"
		Or URL = "InstallCertificateIntoContainer"
		Or URL = "InstallRootCertificate"
		Or URL = "SetListOfCertificateRevocation" Then
		
		If Result.IsInstalledSuccessfully <> True Then
				
			FormParameters = New Structure;
			If URL = "SetListOfCertificateRevocation" Then
				FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể thiết lập danh sách thu hồi';
															|ru = 'Не удалось установить список отзыва';
															|en = 'Cannot install the revocation list.'; fa = 'Cannot install the revocation list.';
															|it = 'Не удалось установить список отзыва';
															|pl = 'Cannot install the revocation list.';
															|tr = 'Geri çekme listesi kurulamıyor'"));
			Else
				FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể cài đặt chứng thư.';
															|ru = 'Не удалось установить сертификат';
															|en = 'Cannot install the certificate'; fa = 'Cannot install the certificate';
															|it = 'Не удалось установить сертификат';
															|pl = 'Cannot install the certificate';
															|tr = 'Sertifika kurulamadı'"));
			EndIf;

			FormParameters.Insert("ErrorTextClient", Result.Message);
			FormParameters.Insert("ShowNeedHelp", True);
			FormParameters.Insert("ShowInstruction", True);

			OpenExtendedErrorPresentationForm(FormParameters);

			Return;
		EndIf;
	EndIf;
	
	Notify("SSL_VerifyCertificate", Context.NotificationSubject);
	
EndProcedure

// Additional data for the error classifier.
// 
// Returns:
//  Structure - Additional data for the error classifier:
//   * Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//   * CertificateData - String - Certificate data address in a temporary storage.
//   * SignatureData - String - Signature data address in a temporary storage.
//   * AdditionalDataChecksOnClient - Structure
//   * AdditionalDataChecksOnServer - Structure
//   * AddInAttachmentParameters - See CommonClient.AddInAttachmentParameters
//
Function AdditionalDataForErrorClassifier() Export
	
	AdditionalData = New Structure;
	AdditionalData.Insert("Certificate");
	AdditionalData.Insert("CertificateData");
	AdditionalData.Insert("SignatureData");
	AdditionalData.Insert("AddInAttachmentParameters");
	AdditionalData.Insert("AdditionalDataChecksOnClient");
	AdditionalData.Insert("AdditionalDataChecksOnServer");
	Return AdditionalData;
	
EndFunction

// Intended for managing notifications from the certificate form, certificate request form, and CertificateAboutToExpireNotification form. 
// 
//
Procedure EditMarkONReminder(Certificate, Remind, OwnerForm) Export
	
	If OwnerForm.FormName = "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Form.Form" Then
		ReminderID = "AutoReminderAboutStateChangeStatement";
	Else	
		ReminderID = "AutomaticCertificateRenewalReminder";
	EndIf;	
	
	DigitalSignatureInternalServerCall.EditMarkONReminder(Certificate, Remind, ReminderID);
	
EndProcedure

// For internal use only
// Populates the "Individual" attribute with the value found by the description in the certificate's IssuedTo field
//
// Parameters:
//   Form - ClientApplicationForm
//   IssuedTo - String
//   Individual - DefinedType.Individual - Attribute for specifying the individual.
//
Procedure PickIndividualForCertificate(Form, IssuedTo, Individual) Export

	If ValueIsFilled(Individual) Then

		QueryText = NStr("vi = 'Đã điền trường ""Cá nhân"". Điền lại?';
						|ru = 'Поле ""Физическое лицо"" заполнено. Перезаполнить?';
						|en = 'The ""Individual"" field is filled. Do you want to refill it?'; fa = 'The ""Individual"" field is filled. Do you want to refill it?';
						|it = 'Поле ""Физическое лицо"" заполнено. Перезаполнить?';
						|pl = 'The ""Individual"" field is filled. Do you want to refill it?';
						|tr = '""Gerçek kişi"" alanı dolduruldu. Tamamlansın mı?'");
		Parameters = New Structure("Form, IssuedTo, Individual", Form, IssuedTo, Individual);
		NotificationAnswer = New CallbackDescription("AnswerSelectIndividual", ThisObject, Parameters);

		ShowQueryBox(NotificationAnswer, QueryText,
			QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Return;
	EndIf;
	
	IdentifyIndividual(Form, IssuedTo, Individual);

EndProcedure

Procedure AnswerSelectIndividual(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		IdentifyIndividual(Parameters.Form, Parameters.IssuedTo, Parameters.Individual);
	EndIf;
	
EndProcedure

Procedure IdentifyIndividual(Form, IssuedTo, Individual)
	
	Form.Modified = True;
	
	IssuedTo = DigitalSignatureInternalClientServer.ConvertIssuedToIntoFullName(IssuedTo);
	
	Result = DigitalSignatureInternalServerCall.GetIndividualsByCertificateFieldIssuedTo(IssuedTo);
	
	If Not Result.Property("Persons") Then
		Return;
	EndIf;
	
	IndividualsForFullName = Result.Persons.Get(IssuedTo);
	
	IndividualEmptyRef = New (TypeOf(Individual)); 
	IsItemForm = ?(Form.Items.Find("CertificateIndividual") = Undefined, True, False);
	
	If IsItemForm Then
		Form.Object.Individual = IndividualEmptyRef;
	Else
		Form.CertificateIndividual = IndividualEmptyRef;
	EndIf;
	
	If IndividualsForFullName = Undefined Then
		ChoiceProcessing = New CallbackDescription("OnCloseIndividualChoiceForm", Form);
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		OpenForm(Result.IndividualChoiceFormPath, FormParameters, Form, , , , ChoiceProcessing,
			FormWindowOpeningMode.LockOwnerWindow);	
		Return;
	EndIf;
	
	If IndividualsForFullName.Count() = 1 Then
		If IsItemForm Then
			Form.Object.Individual = IndividualsForFullName[0];
		Else
			Form.CertificateIndividual = IndividualsForFullName[0];
		EndIf;
		Return;
	EndIf;
	
	FixedSettings = New DataCompositionSettings;

	Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Ref");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = IndividualsForFullName;
	Filter.Use = True;

	FormParameters = New Structure;
	FormParameters.Insert("FixedSettings", FixedSettings);
	FormParameters.Insert("FilterByReference_", True);
	FormParameters.Insert("ChoiceMode", True);

	ChoiceProcessing = New CallbackDescription("OnCloseIndividualChoiceForm", Form);
	OpenForm(Result.IndividualChoiceFormPath, FormParameters, Form, , , , ChoiceProcessing,
		FormWindowOpeningMode.LockOwnerWindow);	

EndProcedure

// Read signature properties.
// 
// Parameters:
//  CallbackOnCompletion - CallbackDescription - Returns Structure or Array of Structure
//  Signature - BinaryData
//          - String - binary data address to temporary storage
//          - Array of String
//          - Array of BinaryData
//  ShouldReadCertificates - Boolean - Read signature certificate
//  UseCryptoManager - Boolean - Cryptographic manager usage flag.
//
Procedure ReadSignatureProperties(CallbackOnCompletion, Signature, ShouldReadCertificates = True, UseCryptoManager = True) Export
	
	If TypeOf(Signature) = Type("String") Or TypeOf(Signature) = Type("BinaryData") Then
		ReturnStructure = True;
		SignaturesArray = CommonClientServer.ValueInArray(Signature);
	Else
		ReturnStructure = False;
		SignaturesArray = Signature;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", CallbackOnCompletion);
	Context.Insert("SignaturesArray", SignaturesArray);
	Context.Insert("ProcessedSignatures", New Map);
	Context.Insert("ReturnStructure", ReturnStructure);
	
	Context.Insert("SignaturesProcessedAtServer");
	Context.Insert("ShouldReadCertificates", ShouldReadCertificates);
	Context.Insert("UseCryptoManager", UseCryptoManager);

	ReadSignaturesPropertiesLoop(Undefined, Context);
	
EndProcedure

Async Procedure ReadSignaturesPropertiesLoop(Result, Context) Export

	If Context.UseCryptoManager Then
		If Context.SignaturesArray.Count() > 0 Then
			
			Context.Insert("Signature", Context.SignaturesArray[0]);
			
			If Context.SignaturesProcessedAtServer <> Undefined Then
				Result = Context.SignaturesProcessedAtServer.Get(Context.Signature);
				If Result.Success <> Undefined Then
					AddResultOfSignatureRead(Result, Context);
					Return;
				EndIf;
			EndIf;
			
			Notification = New CallbackDescription("ReadSignaturePropertyAfterCryptoManagerCreated", ThisObject, Context);
			CryptoManagerCreationParameters = CryptoManagerCreationParameters();
			CryptoManagerCreationParameters.Application = Context.Signature;
			CryptoManagerCreationParameters.ShowError = False;
			CreateCryptoManager(Notification, "ReadSignature", CryptoManagerCreationParameters);
			Return;
		Else
			ResultOfReadingSignatures(Context);
		EndIf;
	Else
		Map = New Map;
		For Each Signature In Context.SignaturesArray Do
			SignaturePropertiesFromBinaryData = Await SignaturePropertiesFromBinaryData(Signature, Context.ShouldReadCertificates);
			Map.Insert(Signature, SignaturePropertiesFromBinaryData);
		EndDo;
		Context.ProcessedSignatures = Map;
		ResultOfReadingSignatures(Context);
	EndIf;

EndProcedure

Procedure ResultOfReadingSignatures(Context)
	
	If Context.ReturnStructure Then
		For Each KeyAndValue In Context.ProcessedSignatures Do
			Result = KeyAndValue.Value;
			Break;
		EndDo;
	Else
		Result = Context.ProcessedSignatures;
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

Procedure AddResultOfSignatureRead(Result, Context)
	
	Context.ProcessedSignatures.Insert(Context.Signature, Result);
	Context.SignaturesArray.Delete(0);
	Notification = New CallbackDescription("ReadSignaturesPropertiesLoop", ThisObject, Context);
	RunCallback(Notification, Undefined);

EndProcedure

Async Procedure ReadSignaturePropertyAfterCryptoManagerCreated(CryptoManager, Context) Export
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	If CryptoManager <> Undefined Then
		If TypeOf(CryptoManager) = Type("String") Then
			Result.ErrorText = CryptoManager;
		Else
			Result = Await SignaturePropertiesReadByCryptoManager(
				Context.Signature, CryptoManager, Context.ShouldReadCertificates);
			If Result.Success = True Then
				AddResultOfSignatureRead(Result, Context);
				Return;
			Else
				Result.Success = Undefined;
			EndIf;
		EndIf;
	ElsIf Context.UseCryptoManager And Context.SignaturesProcessedAtServer = Undefined
		And (DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
		Or DigitalSignatureClient.GenerateDigitalSignaturesAtServer()) Then
		
		Context.SignaturesProcessedAtServer = New Map;
		Address = PutToTempStorage(Context.SignaturesArray);
		ResultOfReadAtServer = DigitalSignatureInternalServerCall.SignatureProperties(
			Address, Context.ShouldReadCertificates);
		Context.SignaturesProcessedAtServer = GetFromTempStorage(ResultOfReadAtServer);
		
		AddResultOfSignatureRead(Context.SignaturesProcessedAtServer.Get(Context.Signature), Context);
		Return;
	EndIf;
	
	If Context.SignaturesProcessedAtServer <> Undefined Then
		AddResultOfSignatureRead(Context.SignaturesProcessedAtServer.Get(Context.Signature), Context);
		Return;
	EndIf;
	
	SignaturePropertiesFromBinaryData = Await SignaturePropertiesFromBinaryData(
		Context.Signature, Context.ShouldReadCertificates);
	FillPropertyValues(Result, SignaturePropertiesFromBinaryData,, "Success, ErrorText");
	
	If SignaturePropertiesFromBinaryData.Success = False Then
		Result.Success = False;
		Result.ErrorText = ?(IsBlankString(Result.ErrorText), "", Result.ErrorText + Chars.LF)
			+ SignaturePropertiesFromBinaryData.ErrorText;
	EndIf;
	
	AddResultOfSignatureRead(Result, Context);
	
EndProcedure

Async Function SignaturePropertiesReadByCryptoManager(Signature, CryptoManager, ShouldReadCertificates) Export
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	BinaryData = DigitalSignatureInternalClientServer.BinaryDataFromTheData(Signature,
		"DigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData");
	
	Try
		ContainerSignatures = Await CryptoManager.GetCryptoSignaturesContainerAsync(BinaryData);
	Except
		Result.Success = False;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi đọc dữ liệu chữ ký: %1';
						|ru = 'При чтении данных подписи: %1';
						|en = 'When reading the signature data: %1'; fa = 'When reading the signature data: %1';
						|it = 'Alla lettura dei dati di firma: %1';
						|pl = 'Podczas odczytu danych podpisu: %1';
						|tr = 'İmza verilerin okunması sırasında: %1'"), ErrorProcessing.BriefErrorDescription(
					ErrorInfo()));
		Return Result;
	EndTry;

	ParametersCryptoSignatures = Await ParametersCryptoSignatures(
		ContainerSignatures, UTCOffset(), CommonClient.SessionDate());

	Result.SignatureType = ParametersCryptoSignatures.SignatureType;
	Result.DateActionLastTimestamp = ParametersCryptoSignatures.DateActionLastTimestamp;
	Result.UnverifiedSignatureDate = ParametersCryptoSignatures.UnverifiedSignatureDate;
	Result.DateSignedFromLabels = ParametersCryptoSignatures.DateSignedFromLabels;
	
	If ParametersCryptoSignatures.CertificateDetails <> Undefined Then
		Result.Thumbprint = ParametersCryptoSignatures.CertificateDetails.Thumbprint;
		Result.CertificateOwner = ParametersCryptoSignatures.CertificateDetails.IssuedTo;
	EndIf;

	If ShouldReadCertificates Then
		SignatureRow = ContainerSignatures.Signatures[0];
		If DigitalSignatureInternalClientServer.IsCertificateExists( 
						SignatureRow.SignatureCertificate) Then
			Result.Certificate = Await SignatureRow.SignatureCertificate.UnloadAsync();
		EndIf;
		For Each Certificate In SignatureRow.SignatureVerificationCertificates Do
			If DigitalSignatureInternalClientServer.IsCertificateExists(Certificate) Then
				Result.Certificates.Add(Await Certificate.UnloadAsync());
			EndIf;
		EndDo;
	EndIf;

	Result.Success = True;
	Return Result;
	
EndFunction

Async Function SignaturePropertiesFromBinaryData(Signature, ShouldReadCertificates)
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	Try
		SignaturePropertiesFromBinaryData = DigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData(
			Signature, UTCOffset(), ShouldReadCertificates);
		If Not ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureType) Then
			Result.ErrorText = NStr("vi = 'Dữ liệu không phải là chữ ký';
									|ru = 'Данные не являются подписью';
									|en = 'The data is not a signature.'; fa = 'The data is not a signature.';
									|it = 'Данные не являются подписью';
									|pl = 'The data is not a signature.';
									|tr = 'Veriler imza değildir'");
			Result.Success = False;
			Return Result;
		EndIf;
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đọc thuộc tính chữ ký: %1';
				|ru = 'Не удалось прочитать свойства подписи: %1';
				|en = 'Cannot read the signature properties: %1'; fa = 'Cannot read the signature properties: %1';
				|it = 'Не удалось прочитать свойства подписи: %1';
				|pl = 'Cannot read the signature properties: %1';
				|tr = 'İmza özellikleri okunamadı: %1'"), ErrorProcessing.BriefErrorDescription(
			ErrorInfo()));
		Result.Success = False;
		Return Result;
	EndTry;

	Result.SignatureType = SignaturePropertiesFromBinaryData.SignatureType;

	If ValueIsFilled(SignaturePropertiesFromBinaryData.SigningDate) Then
		Result.UnverifiedSignatureDate = SignaturePropertiesFromBinaryData.SigningDate;
	EndIf;
	If ValueIsFilled(SignaturePropertiesFromBinaryData.DateOfTimeStamp) Then
		Result.DateSignedFromLabels = SignaturePropertiesFromBinaryData.DateOfTimeStamp;
	EndIf;

	If SignaturePropertiesFromBinaryData.Certificates.Count() > 0 Then
		
		If SignaturePropertiesFromBinaryData.Certificates.Count() > 1 Then
			Try
				Result.Certificates = Await CertificatesInOrderToRoot(
					SignaturePropertiesFromBinaryData.Certificates);
				Result.Certificate = ?(ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureCertificate),
					SignaturePropertiesFromBinaryData.SignatureCertificate, Result.Certificates[0]);
			Except
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đọc thuộc tính chứng thư: %1';
						|ru = 'Не удалось прочитать свойства сертификатов: %1';
						|en = 'Cannot read the properties of the certificates: %1'; fa = 'Cannot read the properties of the certificates: %1';
						|it = 'Не удалось прочитать свойства сертификатов: %1';
						|pl = 'Cannot read the properties of the certificates: %1';
						|tr = 'Sertifikaların özellikleri okunamadı: %1'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
		Else
			Result.Certificate = ?(ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureCertificate),
				SignaturePropertiesFromBinaryData.SignatureCertificate, SignaturePropertiesFromBinaryData.Certificates[0]);
		EndIf;
		
		Try
			Certificate = New CryptoCertificate();
			Await Certificate.InitializeAsync(Result.Certificate);
			Result.Certificate = Await Certificate.UnloadAsync();
			CertificateProperties = Await CertificateProperties(Certificate);
			Result.Thumbprint = CertificateProperties.Thumbprint;
			Result.CertificateOwner = CertificateProperties.IssuedTo;
		Except
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đọc thuộc tính chứng thư: %1';
						|ru = 'Не удалось прочитать свойства сертификата: %1';
						|en = 'Cannot read the certificate properties: %1'; fa = 'Cannot read the certificate properties: %1';
						|it = 'Не удалось прочитать свойства сертификата: %1';
						|pl = 'Cannot read the certificate properties: %1';
						|tr = 'Sertifikanın özellikleri okunamadı: %1'"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;

	EndIf;

	Result.Success = IsBlankString(Result.ErrorText);
	
	Return Result;

EndFunction

// For the VerifySignature procedure.
// 
// Parameters:
//  Result  - See DigitalSignatureClientServer.SignatureVerificationResult.
//  ResultStructure - Undefined
//                     - See DigitalSignatureClientServer.SignatureVerificationResult
//  IsVerificationRequired  - Undefined, Boolean - True if determined that it failed to 
//                       verify the signature due to external reasons. 
//
// Returns:
//   See DigitalSignatureClientServer.SignatureVerificationResult
//   See DigitalSignatureClientServer.SignatureVerificationResult.
//
Function SignatureVerificationResult(Result, ResultStructure = Undefined, IsVerificationRequired = Undefined, InvalidHash = Undefined)
	
	If ResultStructure = Undefined Then
		Return Result;
	Else
		
		ResultStructure.Result = Result;
		
		If Result = True Then
			ResultStructure.SignatureCorrect = True;
			ResultStructure.IsVerificationRequired = False;
			ResultStructure.IsSignatureMathematicallyValid = True;
			Return ResultStructure;
		EndIf;
		
		If InvalidHash = True Then
			ResultStructure.SignatureCorrect = False;
			ResultStructure.IsVerificationRequired = False;
			ResultStructure.IsSignatureMathematicallyValid = False;
			ResultStructure.SignatureMathValidationError = Result;
			Return ResultStructure;
		Else
			ResultStructure.AdditionalAttributesCheckError = Result;
		EndIf;
		
		If IsVerificationRequired <> Undefined Then
			ResultStructure.IsVerificationRequired = IsVerificationRequired;
		EndIf;
		
		If ResultStructure.IsVerificationRequired = False Then
			ResultStructure.SignatureCorrect = False;
		EndIf;
		
		If ResultStructure.IsVerificationRequired = Undefined Then
			ResultStructure.IsVerificationRequired = False;
			ResultStructure.SignatureCorrect = False;
		EndIf;
		
		ResultStructure.IsSignatureMathematicallyValid = Not ResultStructure.IsVerificationRequired Or InvalidHash = False;
		
		Return ResultStructure;
	EndIf;
	
EndFunction

Procedure AfterSignatureAuthenticityJustificationEntered(Result, Notification) Export
	
	If Not ValueIsFilled(Result) Then
		RunCallback(Notification, Undefined);
	EndIf;
	
	CheckResult = New Structure;
	CheckResult.Insert("AdditionalAttributesManualCheckAuthor", UsersClient.CurrentUser());
	CheckResult.Insert("AdditionalAttributesManualCheckJustification", Result);
	CheckResult.Insert("IsAdditionalAttributesCheckedManually", True);
	CheckResult.Insert("CheckDate", CommonClient.SessionDate());
	CheckResult.Insert("SignatureCorrect", True);
	CheckResult.Insert("IsVerificationRequired", False);
	
	RunCallback(Notification, CheckResult);

EndProcedure

// For internal use only.
// 
// Parameters:
//  CertificatesData - Array of BinaryData
// 
// Returns:
//  Array of BinaryData - Certificates up to the root one.
//
Async Function CertificatesInOrderToRoot(CertificatesData) Export
	
	By_Order = New Array;
	CertificatesDetails = New Map;
	CertificatesBySubjects = New Map;
	
	For Each CertificateData In CertificatesData Do
		Certificate = New CryptoCertificate;
		Await Certificate.InitializeAsync(CertificateData);
		By_Order.Add(CertificateData);
		CertificatesDetails.Insert(Certificate, CertificateData);
		CertificatesBySubjects.Insert(
			DigitalSignatureInternalClientServer.IssuerKey(Certificate.Subject),
			CertificateData);
	EndDo;
	
	For Counter = 1 To By_Order.Count() Do
		HasChanges = False;
		DigitalSignatureInternalClientServer.SortCertificates(
			By_Order, CertificatesDetails, CertificatesBySubjects, HasChanges); 
		If Not HasChanges Then
			Break;
		EndIf;
	EndDo;
	
	Return By_Order;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  ContainerSignatures - CryptoSignaturesContainer
//  UTCOffset - Number
//  SessionDate - Date
// 
// Returns:
//  Structure - Cryptographic signature parameters:
//   * SignatureType          - EnumRef.CryptographySignatureTypes
//   * DateActionLastTimestamp - Date, Undefined - Filled only using the cryptographic manager.
//   * DateSignedFromLabels - Date, Undefined - Date of the earliest timestamp.
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                 - Undefined - Unconfirmed signature data is missing from the signature data.
//   * DateLastTimestamp - Date - Date of the latest timestamp.
//   * Certificate   - CryptoCertificate - Signatory's certificate.
//   * CertificateDetails - See DigitalSignatureClient.CertificateProperties.
//
Async Function ParametersCryptoSignatures(ContainerSignatures, UTCOffset, SessionDate) Export

	SignatureParameters = DigitalSignatureInternalClientServer.NewSettingsSignaturesCryptography();
		
	Signature = ContainerSignatures.Signatures[0];
	
	IsCertificateExists = DigitalSignatureInternalClientServer.IsCertificateExists(Signature.SignatureCertificate);
	
	If IsCertificateExists Then
		SignatureParameters.CertificateDetails = Await CertificateProperties(Signature.SignatureCertificate);
	EndIf;
	
	Return DigitalSignatureInternalClientServer.ParametersCryptoSignatures(SignatureParameters, Signature, IsCertificateExists, UTCOffset, SessionDate);
	
EndFunction

Function TimestampServersDiagnosticsResult()

	TimestampServersAddresses = DigitalSignatureClient.CommonSettings().TimestampServersAddresses;

	If TimestampServersAddresses.Count() = 0 Then

		Return NStr("vi = 'Chưa điền địa chỉ máy chủ dấu thời gian trong tùy chỉnh chữ ký điện tử.';
					|ru = 'Адреса серверов меток времени не заполнены в настройках электронной подписи.';
					|en = 'The addresses of timestamp servers are unfilled in digital signature settings.'; fa = 'The addresses of timestamp servers are unfilled in digital signature settings.';
					|it = 'Адреса серверов меток времени не заполнены в настройках электронной подписи.';
					|pl = 'The addresses of timestamp servers are unfilled in digital signature settings.';
					|tr = 'Elektronik imza ayarlarında zaman damgası sunucu adresleri doldurulmuyor.'");
		
	Else
#If WebClient Then
		Return StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Không cho phép chẩn đoán khi làm việc trong web-client. Trong trình duyệt, hãy thử tải tệp theo liên kết.
			|%1';
			|ru = 'Диагностика серверов меток времени недоступна при работе в веб-клиенте. Попробуйте в браузере скачать файл по ссылке.
			|%1';
			|en = 'Web client doesn''t support testing the availability of timestamp servers. Try to download the file by URL.
			|%1'; fa = 'Web client doesn''t support testing the availability of timestamp servers. Try to download the file by URL.
			|%1';
			|it = 'Диагностика серверов меток времени недоступна при работе в веб-клиенте. Попробуйте в браузере скачать файл по ссылке.
			|%1';
			|pl = 'Web client doesn''t support testing the availability of timestamp servers. Try to download the file by URL.
			|%1';
			|tr = 'Web istemcisinde çalışırken zaman damgası sunucusu tanılaması kullanılamaz. Dosyayı tarayıcınızdaki bağlantıdan indirmeyi deneyin.
			|%1'"), StrConcat(TimestampServersAddresses, Chars.LF));
	
#Else
		StringForConnection = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Kết nối đến máy chủ dấu thời gian trong máy tính <%1>.';
					|ru = 'Подключение к серверам меток времени на компьютере <%1>.';
					|en = 'Accessing timestamp servers on computer <%1>.'; fa = 'Accessing timestamp servers on computer <%1>.';
					|it = 'Подключение к серверам меток времени на компьютере <%1>.';
					|pl = 'Accessing timestamp servers on computer <%1>.';
					|tr = '<%1> Sunucudaki zaman damgası sunucusunun kullanılabilirliğini kontrol edin.'"), ComputerName());
		Return DigitalSignatureInternalClientServer.TimestampServersDiagnostics(TimestampServersAddresses, StringForConnection);
#EndIf
	EndIf;
	
EndFunction

Procedure HandleDecryptionError(Error, Context)
	
	ErrorText = Error.ErrorDescription;
	ClassifierError = DigitalSignatureInternalServerCall.ClassifierError(ErrorText);
	If ClassifierError = Undefined Or Not ClassifierError.UnknownCryptoAlgorithm Then
		// Processing is not required.
		Return;
	EndIf;
	
	UndecryptedData = Context.DataElement.Data;
	Application = CommonClientServer.StructureProperty(Context, "Application", Undefined);
	ApplicationPresentation = ?(ValueIsFilled(Application), Application.Presentation, "");
	
	EncryptAlgorithmInfo = DigitalSignatureInternalClientServer.EncryptedFileEncryptAlgorithm(UndecryptedData);
	Additional_DataChecks = DrillDownErrorAdditionalParameters(EncryptAlgorithmInfo, ApplicationPresentation);
	
	Error.Insert("AdditionalDataChecksOnClient", Additional_DataChecks);
	Error.Insert("ApplicationsSetUp", True);
	If Not IsBlankString(EncryptAlgorithmInfo.Id) Then
		Error.ErrorDescription = TrimL(ErrorText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'OID thuật toán: %1';
				|ru = 'OID алгоритма: %1';
				|en = 'Algorithm OID: %1'; fa = 'Algorithm OID: %1';
				|it = 'OID алгоритма: %1';
				|pl = 'Algorithm OID: %1';
				|tr = 'Algoritmanın OID''si: %1'"), EncryptAlgorithmInfo.Id));
	EndIf;
		
EndProcedure

Function DrillDownErrorAdditionalParameters(EncryptAlgorithmInfo, ApplicationPresentation)
	
	Result = New Structure("AdditionalDataChecksOnClient");
	ErrorPresentation = New Structure("Cause, Decision");
	AlgorithmID = EncryptAlgorithmInfo.Id;
	AlgorithmPresentation = ?(ValueIsFilled(EncryptAlgorithmInfo.Presentation),
								EncryptAlgorithmInfo.Presentation,
								EncryptAlgorithmInfo.Id);
	
	DecisionText = "";
	If StrFind(AlgorithmID, "1.2.643.7.1.1.5.2") <> 0
		Or StrFind(AlgorithmID, "1.2.643.7.1.1.5.1") <> 0 Then
		DecisionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '• Cài đặt ứng dụng chữ ký điện tử, ứng dụng này sẽ giải mã các tài liệu được mã hóa bằng thuật toán ""%1"", ví dụ như Cryptopro CSP phiên bản 5.0.12000 trở lên hoặc Signal-COM CSP.';
				|ru = '• Установите приложение электронной подписи, которое расшифрует документы, зашифрованные алгоритмом ""%1"", например КриптоПро CSP версии 5.0.12000 и выше или Сигнал-КОМ CSP.';
				|en = '• To decrypt the documents encrypted with the ""%1"" algorithm, install a suitable application. For example, Signal-COM CSP or CryptoPro CSP v.5.0.12000 or later.'; fa = '• To decrypt the documents encrypted with the ""%1"" algorithm, install a suitable application. For example, Signal-COM CSP or CryptoPro CSP v.5.0.12000 or later.';
				|it = '• Установите приложение электронной подписи, которое расшифрует документы, зашифрованные алгоритмом ""%1"", например КриптоПро CSP версии 5.0.12000 и выше или Сигнал-КОМ CSP.';
				|pl = '• To decrypt the documents encrypted with the ""%1"" algorithm, install a suitable application. For example, Signal-COM CSP or CryptoPro CSP v.5.0.12000 or later.';
				|tr = '• CryptoPro CSP sürüm 5.0.12000 veya üzerinde ya da Signal-COM CSP gibi ""%1"" algoritması ile şifrelenmiş belgelerin şifresini çözecek bir elektronik imza uygulaması yükleyin.'"),
			AlgorithmPresentation);
	Else
		DecisionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '• Cài đặt ứng dụng chữ ký điện tử, ứng dụng này sẽ giải mã các tài liệu được mã hóa bằng thuật toán %1.';
				|ru = '• Установите приложение электронной подписи, которое расшифрует документы, зашифрованные алгоритмом%1.';
				|en = '• Install a digital signing application that supports the %1 encryption algorithm.'; fa = '• Install a digital signing application that supports the %1 encryption algorithm.';
				|it = '• Установите приложение электронной подписи, которое расшифрует документы, зашифрованные алгоритмом%1.';
				|pl = '• Install a digital signing application that supports the %1 encryption algorithm.';
				|tr = '- %1 algoritması ile şifrelenen belgeleri deşifre eden bir elektronik imza uygulaması yükleyin.'"),
			" """ + AlgorithmPresentation + """");
	EndIf;
		
	ErrorPresentation.Cause = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '• Ứng dụng chữ ký điện tử %1 không hoạt động với thuật toán mã hóa này.
		|• Đã cài đặt sai ứng dụng chữ ký điện tử.';
		|ru = '• Приложение электронной подписи %1 не работает с данным алгоритмом шифрования.
		|• Приложение электронной подписи установлено некорректно.';
		|en = '• %1 doesn''t support this encryption algorithm.
		|• Errors occurred during the installation of the application.'; fa = '• %1 doesn''t support this encryption algorithm.
		|• Errors occurred during the installation of the application.';
		|it = '• Приложение электронной подписи %1 не работает с данным алгоритмом шифрования.
		|• Приложение электронной подписи установлено некорректно.';
		|pl = '• %1 doesn''t support this encryption algorithm.
		|• Errors occurred during the installation of the application.';
		|tr = '• Elektronik İmza Uygulaması %1, bu şifreleme algoritması ile çalışmamaktadır. 
		|•  E-imza uygulaması doğru yüklenmemiş.'"),
		ApplicationPresentation);
	ErrorPresentation.Decision = DecisionText + NStr("vi = '• Hãy gỡ bỏ tất cả các ứng dụng chữ ký điện tử và chỉ cài đặt một ứng dụng trong số chúng, vì việc cài đặt nhiều ứng dụng chữ ký điện tử trên cùng một máy tính có thể gây ra lỗi này.';
													|ru = '• Удалите все приложения электронной подписи и установите только одно из них, так как установка нескольких приложений электронной подписи на одном компьютере может вызвать эту ошибку.';
													|en = '• This error may be caused by a conflict between digital signing applications. Uninstall all digital signing applications. Then, re-install only one of them.'; fa = '• This error may be caused by a conflict between digital signing applications. Uninstall all digital signing applications. Then, re-install only one of them.';
													|it = '• Удалите все приложения электронной подписи и установите только одно из них, так как установка нескольких приложений электронной подписи на одном компьютере может вызвать эту ошибку.';
													|pl = '• This error may be caused by a conflict between digital signing applications. Uninstall all digital signing applications. Then, re-install only one of them.';
													|tr = '• Aynı bilgisayara çok sayıda e-imza uygulaması kurmak bu hataya yol açabileceği için tüm e-imza uygulamalarını kaldırın ve sadece birini yükleyin.'");
	
	Result.AdditionalDataChecksOnClient = ErrorPresentation;
	
	Return Result;
	
EndFunction

// For internal use only.
// 
// Returns:
//  Structure
//
Function NewCryptoManagementAddIns() Export
	
	Result = New Structure;
	Result.Insert("IsCryptoProviderInstalled", True);
	Result.Insert("Is1CEnterpriseExtensionInstalled", True);
	Result.Insert("IsCryptographicExtensionInstalled", True);
	Result.Insert("IsExtraCryptoAPIAddInInstalled", True);
	
	Return Result;
	
EndFunction

// For internal use only.
//
// Parameters:
//  Components - See NewCryptoManagementAddIns
// 
// Returns:
//  Boolean
//
Async Function IsAdditionalAddInsInstallationRequired(Components) Export
	
	Result = False;
	
	// Check if 1C:Enterprise Extension is installed.
	If Components.Is1CEnterpriseExtensionInstalled Then
		Components.Is1CEnterpriseExtensionInstalled = Await AttachFileSystemExtensionAsync();
		Result = Result Or Not Components.Is1CEnterpriseExtensionInstalled;
	EndIf;
	
	// Check if the cryptography extension is installed
	If Components.IsCryptographicExtensionInstalled Then
		Components.IsCryptographicExtensionInstalled = Await AttachCryptoExtensionAsync();
		Result = Result Or Not Components.IsCryptographicExtensionInstalled;
	EndIf;
	
	// Check if the extension for managing the ExtraCryptoAPI add-in is installed.
	If Components.IsExtraCryptoAPIAddInInstalled Then
		
		ConnectionParameters = CommonClient.AddInAttachmentParameters();
		ConnectionParameters.SuggestInstall = False;
		ConnectionParameters.SuggestToImport = False;
		ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
		
		AddInAttachmentResult = Await CommonClient.AttachAddInFromTemplateAsync(
			ComponentDetails.ObjectName,
			ComponentDetails.FullTemplateName,
			ConnectionParameters);
		Components.IsExtraCryptoAPIAddInInstalled = AddInAttachmentResult.Attached;
		Result = Result Or Not Components.IsExtraCryptoAPIAddInInstalled;
		
	EndIf;
	
	DigitalSignatureClientLocalization.OnCheckCryptoAppsInstallation(Result, Components);
	
	Return Result;
	
EndFunction

// For internal use only.
//  Checks the installation of add-ins for managing digital signatures in the web client,
//  starting with 1C:Enterprise Extension.
//  If 1C:Enterprise Extension is not installed, the system checks for other required add-ins.
//  If at least two add-ins are missing, the StartWorkWithDigitalSignature
//  form opens to install the missing add-ins.
// If only one add-in is missing, all add-ins are installed, or the call was made not from a web client,
// the execution continues according to the calling code's algorithm.
//
// Parameters:
//  Notification - CallbackDescription, Undefined - Notification about closing the StartWorkWithDigitalSignature form.
// 
// Returns:
//  Boolean - If additional add-ins need to be installed, returns "True".
//
Async Function InstallAddInsAfter1CEnterpriseExtensionChecked(Notification = Undefined) Export
	
#If WebClient Then
	Is1CEnterpriseExtensionInstalled = Await AttachFileSystemExtensionAsync();
	If Not Is1CEnterpriseExtensionInstalled Then
		InstallationIsRequired = True;
		IsAdditionalAddInsInstallationRequired = False;
		Components = NewCryptoManagementAddIns();
		Components.Is1CEnterpriseExtensionInstalled = False;
		
		IsAdditionalAddInsInstallationRequired = Await IsAdditionalAddInsInstallationRequired(Components);
		
		If IsAdditionalAddInsInstallationRequired Then
			FormParameters = New Structure;
			FormParameters.Insert("Components", Components);
			FormParameters.Insert("RequiredAddInName", "ExtensionFor1CEnterprise");
			OpenForm("CommonForm.StartWorkWithDigitalSignature", FormParameters, ThisObject, 
				, , , Notification, FormWindowOpeningMode.LockOwnerWindow);
			Return True;
		EndIf;
	EndIf;
#Else
	Return False;
#EndIf
	
	Return False;
	
EndFunction

Procedure AfterCryptoAppsInstallationChecked(Result, Components) Export
	
	If Result.CheckCompleted Then
		
		Components.IsCryptoProviderInstalled = Result.Tokens.Count() > 0;
		
		If Not Components.IsCryptoProviderInstalled Then
			For Each Cryptoprovider In Result.Programs Do
				If ValueIsFilled(Cryptoprovider.Application) And Not Components.IsCryptoProviderInstalled Then
					Components.IsCryptoProviderInstalled = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion