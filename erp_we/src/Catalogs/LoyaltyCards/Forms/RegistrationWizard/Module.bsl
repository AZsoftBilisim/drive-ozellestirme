#Region Variables

&AtClient
Var ClosingInProgress;

&AtClient
Var PageStack; // Array - The history of transitions to return to the back button

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SupportedPeripheralTypes = "BarcodeScanner,MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Mode = Parameters.Mode;
	Date = CurrentSessionDate();
	
	RequiredTypeOfCardToReplace = Parameters.RequiredTypeOfCardToReplace;
	RequiredNewCardKind      = Parameters.RequiredNewCardKind;
	
	If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
		ReplacedCard = Parameters.Basis;
	Else
		ReplacedCard = Parameters.ReplacedCard;
	EndIf;
	
	Partner    = Parameters.Partner;
	Counterparty = Parameters.Counterparty;
	Terms = Parameters.Terms;
	
	If ValueIsFilled(Partner) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Partners.Client AS Client
		|FROM
		|	Catalog.Partners AS Partners
		|WHERE
		|	Partners.Ref = &Ref";
		
		Query.SetParameter("Ref", Partner);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
			If Not Selection.Client Then
				Raise StrTemplate(NStr("vi = 'Bạn hàng ""%1"" không phải là khách hàng. Chỉ có thể ghi nhận thẻ khách hàng thân thiết đối với bạn hàng là khách hàng.';
										|ru = 'Партнер ""%1"" не является клиентом. Регистрация карт лояльности возможна только для партнеров, являющихся клиентами.';
										|en = 'Partner ""%1"" is not a customer. Loyalty cards can be registered only for partners who are customers.'; fa = 'Partner ""%1"" is not a customer. Loyalty cards can be registered only for partners who are customers.';
										|it = 'Il partner ""%1"" non è un cliente. La registrazione delle carte fedeltà è possibile solo per i partner clienti.';
										|pl = 'Partner ""%1"" nie jest klientem. Rejestracja kart lojalnościowych jest możliwa tylko dla partnerów, będących klientami.';
										|tr = '""%1"" İş ortağı istemci değildir. Sadakat kartlarının kaydı yalnızca istemci olan iş ortakları için mümkündür.'"), Partner);
			EndIf;
		EndIf;
		
	EndIf;
	
	Items.CreateANewPartner.Visible = AccessRight("Insert", Metadata.Catalogs.Partners);
	
	If Not ValueIsFilled(Partner) And ValueIsFilled(ReplacedCard) Then
		CardData = LoyaltyCardServerCall.GetLoyaltyCardDetails(ReplacedCard);
		Partner    = CardData.Partner;
		Counterparty = CardData.Counterparty;
		Terms = CardData.Terms;
		If ValueIsFilled(Partner) Then
			Items.EnterDataAboutTheCardHolder.Enabled = False;
			Items.Partner.Enabled                            = False;
			Items.CreateANewPartner.Enabled              = False;
		EndIf;
		If CardData.Status = Enums.LoyaltyCardStatuses.Cancelled__ Then
			Raise StrTemplate(NStr("vi = 'Thẻ khách hàng thân thiết %1 đã bị hủy.';
									|ru = 'Карта лояльности %1 уже аннулирована.';
									|en = 'Loyalty card %1 is already canceled.'; fa = 'Loyalty card %1 is already canceled.';
									|it = 'La carta fedeltà %1 è già annullata.';
									|pl = 'Karta lojalnościowa %1 została już anulowana.';
									|tr = 'Sadakat kartı %1 artık iptal edildi.'"), ReplacedCard);
		EndIf;
	ElsIf ValueIsFilled(Partner) And Not ValueIsFilled(ReplacedCard) And Mode = "ReplaceLoyaltyCard" Then
		ReplacedCard = GetPartnerSDefaultCard(Partner);
	EndIf;
	
	MainCodeType = LoyaltyCardsServer.GetMainTypeOfLoyaltyCardCode();
	
	If ValueIsFilled(MainCodeType) Then
		
		TypeOfTheFirstCodeOfTheNewMap = MainCodeType;
		If MainCodeType = Enums.CardCodeTypes.Barcode Then
			TypeOfTheSecondCodeForTheNewMap = Enums.CardCodeTypes.MagneticCode;
		Else
			TypeOfTheSecondCodeForTheNewMap = Enums.CardCodeTypes.Barcode;
		EndIf;
		
		Items.TypeOfTheFirstCodeOfTheNewMap.Visible = False;
		
	Else
		TypeOfTheFirstCodeOfTheNewMap = Enums.CardCodeTypes.Barcode;
		TypeOfTheSecondCodeForTheNewMap = Enums.CardCodeTypes.MagneticCode;
	EndIf;
	
	If Mode = "RegisterNewLoyaltyCard" Then
		Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard;
		Title = NStr("vi = 'Ghi nhận thẻ khách hàng thân thiết mới';
					|ru = 'Регистрация новой карты лояльности';
					|en = 'Register new loyalty card'; fa = 'ثبت کارت وفاداری جدید';
					|it = 'Registrazione di una nuova carta fedeltà';
					|pl = 'Rejestracja nowej karty lojalnościowej';
					|tr = 'Yeni sadakat kartının kaydı'");
	ElsIf Mode = "ReplaceLoyaltyCard" Then
		If ValueIsFilled(ReplacedCard) Then
			Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard;
		Else
			Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard;
		EndIf;
		Title = NStr("vi = 'Thay thế thẻ khách hàng thân thiết';
					|ru = 'Замена карты лояльности';
					|en = 'Replace loyalty card'; fa = 'جایگزینی کارت وفاداری';
					|it = 'Sostituzione della carta fedeltà';
					|pl = 'Wymiana karty lojalnościowej';
					|tr = 'Sadakat kartı değişimi'");
	Else
		Mode = "RegisterNewLoyaltyCard";
		Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupSelectTheLoyaltyCardRegistrationMode;
		Title = NStr("vi = 'Trợ giúp ghi nhận thẻ khách hàng thân thiết';
					|ru = 'Помощник регистрации карты лояльности';
					|en = 'Loyalty card registration wizard'; fa = 'ویزارد ثبت کارت وفاداری';
					|it = 'Assistente per la registrazione della carta fedeltà';
					|pl = 'Asystent rejestracji karty lojalnościowej';
					|tr = 'Sadakat kartı kayıt sihirbazı'");
	EndIf;
	
	EnterDataAboutTheCardHolder = "Now";
	
	Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.TheBackButtonIsMissing;
	Items.NextButtonPages.CurrentPage = Items.NextButtonPages.ChildItems.NextButton;
	
	If Not ValueIsFilled(MainCodeType) Then
		Text = NStr("vi = 'Hãy đọc thẻ khách hàng thân thiết mới thông qua máy quét mã vạch (đầu đọc thẻ từ) hoặc hãy nhập mã thủ công';
					|ru = 'Считайте новую карту лояльности при помощи сканера штрихкода (считывателя магнитных карт) или введите код вручную';
					|en = 'Read a new loyalty card using a barcode scanner (magnetic stripe card reader) or enter the code manually'; fa = 'Read a new loyalty card using a barcode scanner (magnetic stripe card reader) or enter the code manually';
					|it = 'Считайте новую карту лояльности при помощи сканера штрихкода (считывателя магнитных карт) или введите код вручную';
					|pl = 'Read a new loyalty card using a barcode scanner (magnetic stripe card reader) or enter the code manually';
					|tr = 'Barkod tarayıcı (manyetik kart okuyucu) kullanarak yeni sadakat kartını okutun veya kodu manuel olarak gir'");
	ElsIf MainCodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
		Text = NStr("vi = 'Hãy đọc thẻ khách hàng thân thiết mới thông qua đầu đọc thẻ từ hoặc nhập mã từ thủ công';
					|ru = 'Считайте новую карту лояльности при помощи считывателя магнитных карт или введите магнитный код вручную';
					|en = 'Read a new loyalty card using a magnetic stripe card reader or enter the code manually'; fa = 'Read a new loyalty card using a magnetic stripe card reader or enter the code manually';
					|it = 'Считайте новую карту лояльности при помощи считывателя магнитных карт или введите магнитный код вручную';
					|pl = 'Read a new loyalty card using a magnetic stripe card reader or enter the code manually';
					|tr = 'Manyetik kart okuyucu kullanarak yeni sadakat kartını okutun veya manyetik kodu manuel olarak gir'");
	ElsIf MainCodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
		Text = NStr("vi = 'Hãy đọc thẻ khách hàng thân thiết mới thông qua máy quét mã vạch hoặc nhập mã vạch thủ công';
					|ru = 'Считайте новую карту лояльности при помощи сканера штрихкода или введите штрихкод вручную';
					|en = 'Read a new loyalty card using a barcode scanner or enter the barcode manually'; fa = 'Read a new loyalty card using a barcode scanner or enter the barcode manually';
					|it = 'Считайте новую карту лояльности при помощи сканера штрихкода или введите штрихкод вручную';
					|pl = 'Read a new loyalty card using a barcode scanner or enter the barcode manually';
					|tr = 'Barkod tarayıcı kullanarak yeni sadakat kartını okutun veya barkodu manuel olarak gir'");
	EndIf;
	LabelNewLoyaltyCardReading = Text;
	
	AskBeforeClosing = False;
	
	// access groups
	PartnerAccessGroupsAreUsed = Catalogs.PartnerAccessGroups.AccessGroupsAreUsed();
	If Not PartnerAccessGroupsAreUsed Then
		Items.AccessGroup.Visible = False;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PageStack = New Array;
	
	If EnterDataAboutTheCardHolder = "Later_" Then
		Items.GroupInformationAboutTheOwnerOfTheCard.Enabled = False;
	Else
		Items.GroupAccessGroup.Enabled = False;
	EndIf;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
		
	If Not ClosingInProgress And Modified Then       		
		
		If Exit Then
			
			WarningText = NStr("vi = 'Đã thay đổi dữ liệu.
			|Trước khi kết thúc công việc, nên lưu lại thay đổi,
			|nếu không những dữ liệu đã thay đổi sẽ bị mất.';
			|ru = 'Данные были изменены.
			|Перед завершением работы рекомендуется сохранить изменения,
			|иначе измененные данные будут утеряны.';
			|en = 'Data has changed.
			|Save the changes before exiting, 
			|otherwise the changed data will be lost.'; fa = 'Data has changed.
			|Save the changes before exiting, 
			|otherwise the changed data will be lost.';
			|it = 'I dati sono stati modificati.
			|Prima di terminare il lavoro è consigliabile salvare le modifiche,
			|altrimenti i dati modificati verranno persi.';
			|pl = 'Dane zostały zmienione.
			|Zaleca się zapisanie zmian przed zakończeniem pracy,
			|w przeciwnym razie zmienione dane zostaną utracone.';
			|tr = 'Veriler değiştirilmiştir.
			| Çalışmayı tamamlamadan önce değişiklikleri kaydetmeniz tavsiye edilir,
			| aksi takdirde değiştirilen veriler kaybolacaktır.'");
			
			Cancel = True;
			Return;
			
		Else
			
			If AskBeforeClosing Then
				DeleteLoyaltyCard = Not Cancel;
				Cancel = True;
				QueryText = NStr("vi = 'Đóng biểu mẫu trợ giúp? Dữ liệu vừa nhập sẽ bị mất.';
								|ru = 'Закрыть форму помощника? Введенные данные будут потеряны.';
								|en = 'Close the wizard form? The data entered will be lost.'; fa = 'Close the wizard form? The data entered will be lost.';
								|it = 'Chiudere il modulo dell''assistente? I dati inseriti verranno persi.';
								|pl = 'Zamknąć formularz asystenta? Wprowadzone dane zostaną utracone.';
								|tr = 'Asistan formu kapatılsın mı? Girilen veriler kaybolacaktır.'");
				ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject,New Structure("DeleteLoyaltyCard", DeleteLoyaltyCard) ), 
				QueryText, QuestionDialogMode.YesNo);
			EndIf;
			
		EndIf; 	
	EndIf; 	

EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	DeleteLoyaltyCard = AdditionalParameters.DeleteLoyaltyCard;
	Result = QuestionResult;
	If Result = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		If DeleteLoyaltyCard And ValueIsFilled(NewCard) Then
			DeleteRegisteredLoyaltyCard();
		EndIf;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure OnClose()

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "ChoosingPartnerFound" Then
		Partner =  Parameter.Partner;
	EndIf;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	EnterDataAboutTheCardHolder = Settings.Get("EnterDataAboutTheCardHolder");
	If ValueIsFilled(Partner) And EnterDataAboutTheCardHolder = "Later_" Then
		EnterDataAboutTheCardHolder = "Now";
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EnterDataAboutTheCardHolderOnChange(Item)
	
	Items.GroupInformationAboutTheOwnerOfTheCard.Enabled = Not EnterDataAboutTheCardHolder = "Later_";
	Items.GroupAccessGroup.Enabled 		 	 = EnterDataAboutTheCardHolder = "Later_";	
	
EndProcedure

&AtClient
Procedure ReplacedCardOnChange(Item)
	
	If ValueIsFilled(ReplacedCard) Then
		AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure FirstCodeOfTheNewCardOnChange(Item)
	
	If ValueIsFilled(FirstCodeOfTheNewCard) Then
		AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure FoundLoyaltyCardsReadingReplacedLoyaltyCardSelection(Item, RowSelected, Field, StandardProcessing)
	
	AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure FoundLoyaltyCardsNewLoyaltyCardReadingSelection(Item, RowSelected, Field, StandardProcessing)
	
	AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure MagneticCodeOfANewCardOnChange(Item)
	
	If ValueIsFilled(SecondCodeOfTheNewCard) Then
		AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewCardBarcodeOnChange(Item)
	
	If ValueIsFilled(SecondCodeOfTheNewCard) Then
		AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerReadingAReplacementLoyaltyCardOnChange(Item)
	
	If Not ValueIsFilled(ReplacedCard) Then
		ReplacedCard = GetPartnerSDefaultCard(Partner);
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Partner;
	AgreementSelectionParameters.Document              = Terms;
	AgreementSelectionParameters.DocumentDate         = Date;
	AgreementSelectionParameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");

	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TypeOfTheFirstCodeOfTheNewMapClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#Region CommandHandlers

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If PageStack.Count() = 0 Then
		Return;
	EndIf;
	
	Items.Pages.CurrentPage = PageStack[PageStack.Count()-1];
	PageStack.Delete(PageStack.Count()-1);
	
	SetFormCaption(Items.Pages.CurrentPage);
	
	If PageStack.Count() = 0 Then
		Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.TheBackButtonIsMissing;
	EndIf;
	
	Items.Next.DefaultButton = True;
	Items.NextButtonPages.CurrentPage = Items.NextButtonPages.ChildItems.NextButton;
	
	AskBeforeClosing = True;
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	DetachIdleHandler("NextIsWaitHandler");
	
	ClearMessages();
	
	If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupSelectTheLoyaltyCardRegistrationMode Then
		
		If Mode = "RegisterNewLoyaltyCard" Then
			GoToPage3(Items.Pages.ChildItems.GroupReadNewLoyaltyCard);
		ElsIf Mode = "ReplaceLoyaltyCard" Then
			GoToPage3(Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard);
		EndIf;
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard Then
		
		If Not ValueIsFilled(ReplacedCard) Then
			
			MessageText = NStr("vi = 'Chưa điền trường ""Thẻ thay thế"".';
								|ru = 'Поле ""Заменяемая карта"" не заполнено.';
								|en = '""Replaced card"" is required.'; fa = '""Replaced card"" is required.';
								|it = 'Il campo ""Carta da sostituire"" non è compilato.';
								|pl = 'Nie wypełniono pola ""Wymieniana karta"".';
								|tr = '""Değişim kartı"" alanı doldurulmadı.'");
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				"ReplacedCard");
			
			Return;
			
		EndIf;
		
		GoToPage3(Items.Pages.ChildItems.GroupReadNewLoyaltyCard);
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.SelectAReplacementLoyaltyCardGroup Then
		
		CurrentData = Items.FoundLoyaltyCardsReadingReplacedLoyaltyCard.CurrentData;
		If CurrentData <> Undefined Then
			ProcessSelectionOfReplacementLoyaltyCard(CurrentData);
		EndIf;
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard Then
		
		If Not ValueIsFilled(FirstCodeOfTheNewCard) Then
			
			If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				MessageText = NStr("vi = 'Chưa điền trường ""Mã vạch"".';
									|ru = 'Поле ""Штрихкод"" не заполнено.';
									|en = '""Barcode"" is required.'; fa = '""Barcode"" is required.';
									|it = 'Il campo ""Codice a barre"" non è compilato.';
									|pl = 'Nie wypełniono pola ""Kod kreskowy"".';
									|tr = '""Barkod"" alanı doldurulmadı.'");
			Else
				MessageText = NStr("vi = 'Chưa điền trường ""Mã từ"".';
									|ru = 'Поле ""Магнитный код"" не заполнено.';
									|en = '""Magnetic code"" is required.'; fa = '""Magnetic code"" is required.';
									|it = 'Il campo ""Codice magnetico"" non è compilato.';
									|pl = 'Nie wypełniono pola ""Kod magnetyczny"".';
									|tr = '""Manyetik kod"" alanı doldurulmadı.'");
			EndIf;
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				"FirstCodeOfTheNewCard");
			
			Return;
			
		EndIf;
		
		ProcessFirstCodeOfNewCardOnClient(FirstCodeOfTheNewCard, TypeOfTheFirstCodeOfTheNewMap, False);
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupSelectingANewLoyaltyCard Then
		
		CurrentData = Items.FoundLoyaltyCardsNewLoyaltyCardReading.CurrentData;
		If CurrentData <> Undefined Then
			ProcessSelectionOfNewLoyaltyCard(CurrentData);
		EndIf;
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupRefinementOfTheSecondLoyaltyCardCode Then
		
		If TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode")
			And ValueIsFilled(NewCardBarcode) Then
			ProcessSecondCodeOfNewCardOnClient(NewCardBarcode, False);
		ElsIf TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode")
			And ValueIsFilled(MagneticCodeOfANewCard) Then
			ProcessSecondCodeOfNewCardOnClient(MagneticCodeOfANewCard, False);
		Else
			If TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền trường ""Mã vạch"".';
						|ru = 'Поле ""Штрихкод"" не заполнено.';
						|en = '""Barcode"" is required.'; fa = '""Barcode"" is required.';
						|it = 'Il campo ""Codice a barre"" non è compilato.';
						|pl = 'Nie wypełniono pola ""Kod kreskowy"".';
						|tr = '""Barkod"" alanı doldurulmadı.'"),
					,
					"NewCardBarcode");
			Else
				CommonClientServer.MessageToUser(
					NStr("vi = 'Chưa điền trường ""Mã từ"".';
						|ru = 'Поле ""Магнитный код"" не заполнено.';
						|en = '""Magnetic code"" is required.'; fa = '""Magnetic code"" is required.';
						|it = 'Il campo ""Codice magnetico"" non è compilato.';
						|pl = 'Nie wypełniono pola ""Kod magnetyczny"".';
						|tr = '""Manyetik kod"" alanı doldurulmadı.'"),
					,
					"MagneticCodeOfANewCard");
			EndIf;
		EndIf;
		
	EndIf;
	
	AskBeforeClosing = True;
	
EndProcedure

&AtClient
Procedure CreateANewPartner(Command)
	
	OpenForm("Catalog.Partners.Form.WizardOfNew",New Structure("IntroducingNewRetailBuyer",True), FormOwner);
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	ClearMessages();
	
	If NewCardIsCustomized Then
		If EnterDataAboutTheCardHolder = "Now" Then
			If Not ValueIsFilled(Partner) Then
				
				MessageText = NStr("vi = 'Trường ""Khách hàng"" trống.';
									|ru = 'Поле ""Клиент"" не заполнено.';
									|en = '""Customer"" is required.'; fa = '""Customer"" is required.';
									|it = 'Il campo ""Cliente"" non è compilato.';
									|pl = 'Pole „Klient” nie jest wypełnione.';
									|tr = '""Müşteri"" alanı doldurulmadı.'");
				
				CommonClientServer.MessageToUser(
					MessageText,
					,
					"Partner");
				
				Return;
				
			EndIf;
		Else
			If Items.AccessGroup.Visible And Not ValueIsFilled(AccessGroup) Then
				
				MessageText = NStr("vi = 'Chưa điền trường ""Nhóm truy cập"".';
									|ru = 'Поле ""Группа доступа"" не заполнено.';
									|en = '""Access group"" is required.'; fa = '""Access group"" is required.';
									|it = 'Campo ""Gruppa"" disponibile non è compilato.';
									|pl = 'Pole „Grupa dostępu” jest puste.';
									|tr = '""Erişim grubu"" alanı doldurulmadı.'");
				
				CommonClientServer.MessageToUser(
					MessageText,
					,
					"AccessGroup");
				
				Return;
				
			EndIf;      
		EndIf;
	EndIf;
	
	DoneOnServer();
	
	AskBeforeClosing = False;
	Close();
	
	If NewCardIsCustomized And ValueIsFilled(Partner) Then
		MessageText = StrTemplate(NStr("vi = 'Đã ghi nhận thẻ khách hàng thân thiết %1 đối với khách hàng %2.';
										|ru = 'Зарегистрирована карта лояльности %1 для клиента %2.';
										|en = 'Loyalty card %1 is registered for customer %2.'; fa = 'Loyalty card %1 is registered for customer %2.';
										|it = 'Carta fedeltà %1 registrata per il cliente %2.';
										|pl = 'Zarejestrowano kartę lojalnościową %1 dla klienta %2.';
										|tr = 'İstemci için %1 sadakat kartı kaydedildi %2.'"), NewCard, Partner);
	Else
		MessageText = StrTemplate(NStr("vi = 'Đã ghi nhận thẻ khách hàng thân thiết %1.';
										|ru = 'Зарегистрирована карта лояльности %1.';
										|en = 'Loyalty card %1 is registered.'; fa = 'Loyalty card %1 is registered.';
										|it = 'Carta fedeltà %1 registrata.';
										|pl = 'Zarejestrowano kartę lojalnościową %1.';
										|tr = 'Sadakat kartı kaydedildi %1.'"), NewCard);
	EndIf;
	
	Notify(
		"Write_LoyaltyCard",
		New Structure,
		NewCard);
	
	ShowUserNotification(
		NStr("vi = 'Đã ghi nhận thẻ khách hàng thân thiết';
			|ru = 'Зарегистрирована карта лояльности';
			|en = 'Registered loyalty card'; fa = 'Registered loyalty card';
			|it = 'Carta fedeltà registrata';
			|pl = 'Zarejestrowano kartę lojalnościową';
			|tr = 'Sadakat kartı kaydedildi'"),
		GetURL(NewCard),
		MessageText,
		PictureLib.Information32);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PrintingMicrosoftWordQuestionnaire(Command)
	
	If Not ValueIsFilled(NewCard) Then
		RegisterLoyaltyCard("Later_", False);
	EndIf;
	
	LoyaltyCardsClient.PrintingMicrosoftWordQuestionnaire(NewCard);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FoundLoyaltyCardsReadingReplacedLoyaltyCard.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FoundLoyaltyCardsReadingReplacedLoyaltyCard.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FoundLoyaltyCardsNewLoyaltyCardReading.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FoundLoyaltyCardsNewLoyaltyCardReading.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard Then
		
		ProcessFirstCodeOfNewCardOnClient(ArrayOfBarcodes[0].Barcode, PredefinedValue("Enum.CardCodeTypes.Barcode"), False);
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupRefinementOfTheSecondLoyaltyCardCode Then
		
		If TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			
			ProcessSecondCodeOfNewCardOnClient(ArrayOfBarcodes[0].Barcode, False);
			
		EndIf;
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard Then
		
		ProcessFirstReplacementCardCodeOnClient(ArrayOfBarcodes[0].Barcode, PredefinedValue("Enum.CardCodeTypes.Barcode"), False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard Then
		
		ProcessFirstCodeOfNewCardOnClient(Data, PredefinedValue("Enum.CardCodeTypes.MagneticCode"), True);
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupRefinementOfTheSecondLoyaltyCardCode Then
		
		If TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			
			ProcessSecondCodeOfNewCardOnClient(Data, True);
			
		EndIf;
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard Then
		
		ProcessFirstReplacementCardCodeOnClient(Data, PredefinedValue("Enum.CardCodeTypes.MagneticCode"), True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure SetFormCaption(Page)
	If Page = Items.Pages.ChildItems.GroupSelectTheLoyaltyCardRegistrationMode Then
		Title = NStr("vi = 'Trợ giúp ghi nhận thẻ khách hàng thân thiết';
					|ru = 'Помощник регистрации карт лояльности';
					|en = 'Loyalty card registration wizard'; fa = 'ویزارد ثبت کارت وفاداری';
					|it = 'Assistente per la registrazione delle carte fedeltà';
					|pl = 'Asystent rejestracji kart lojalnościowych';
					|tr = 'Sadakat kartı kayıt sihirbazı'");
	ElsIf Mode = "RegisterNewLoyaltyCard" Then
		Title = NStr("vi = 'Ghi nhận thẻ khách hàng thân thiết mới';
					|ru = 'Регистрация новой карты лояльности';
					|en = 'Register new loyalty card'; fa = 'ثبت کارت وفاداری جدید';
					|it = 'Registrazione di una nuova carta fedeltà';
					|pl = 'Rejestracja nowej karty lojalnościowej';
					|tr = 'Yeni sadakat kartının kaydı'");
	ElsIf Mode = "ReplaceLoyaltyCard" Then
		Title = NStr("vi = 'Thay thế thẻ khách hàng thân thiết';
					|ru = 'Замена карты лояльности';
					|en = 'Replace loyalty card'; fa = 'جایگزینی کارت وفاداری';
					|it = 'Sostituzione della carta fedeltà';
					|pl = 'Wymiana karty lojalnościowej';
					|tr = 'Sadakat kartı değişimi'");
	EndIf;
EndProcedure

&AtClient
Procedure GoToPage3(Page)
	
	PageStack.Add(Items.Pages.CurrentPage);
	Items.Pages.CurrentPage = Page;
	Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.BackButton;
	
	If Page = Items.Pages.ChildItems.GroupEnteringInformationAboutTheCardholder Then
		Items.NextButtonPages.CurrentPage = Items.NextButtonPages.ChildItems.ConfirmButton;
		Items.Done.DefaultButton = True;
	Else
		Items.Next.DefaultButton = True;
	EndIf;
	
	SetFormCaption(Page);
	
	If Page = Items.Pages.ChildItems.GroupSelectingANewLoyaltyCard Then
		If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			Text = NStr("vi = 'Đã tìm thấy nhiều thẻ khách hàng thân thiết với mã từ %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько карт лояльности с магнитным кодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several loyalty cards with magnetic code %1 were found.
			                   |Select an appropriate card.'; fa = 'Several loyalty cards with magnetic code %1 were found.
			                   |Select an appropriate card.';
			                   |it = 'Rilevate multiple carte fedeltà con il codice magnetico %1.
			                   |Selezionate la carta adatta.';
			                   |pl = 'Wykryto kilka kart lojalnościowych z kodem magnetycznym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Manyetik kodlu birkaç sadakat kartı bulundu %1.
			                   |Uygun kartı seç.'");
		Else
			Text = NStr("vi = 'Đã tìm thấy nhiều thẻ khách hàng thân thiết có mã vạch %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько карт лояльности со штрихкодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several loyalty cards with barcode %1 were found.
			                   |Select an appropriate card.'; fa = 'Several loyalty cards with barcode %1 were found.
			                   |Select an appropriate card.';
			                   |it = 'Rilevate multiple carte fedeltà con il codice a barre %1.
			                   |Selezionate la carta adatta.';
			                   |pl = 'Wykryto kilka kart lojalnościowych z kodem kreskowym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Birden çok barkodlu sadakat kartı bulundu %1.
			                   |Uygun kartı seç.'");
		EndIf;
		LabelLoyaltyCardSelection = StrTemplate(Text, FirstCodeOfTheNewCard);
	ElsIf Page = Items.Pages.ChildItems.SelectAReplacementLoyaltyCardGroup Then
		If TypeOfCodeForTheCardToReplace = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			Text = NStr("vi = 'Đã tìm thấy nhiều thẻ khách hàng thân thiết với mã từ %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько карт лояльности с магнитным кодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several loyalty cards with magnetic code %1 were found.
			                   |Select an appropriate card.'; fa = 'Several loyalty cards with magnetic code %1 were found.
			                   |Select an appropriate card.';
			                   |it = 'Rilevate multiple carte fedeltà con il codice magnetico %1.
			                   |Selezionate la carta adatta.';
			                   |pl = 'Wykryto kilka kart lojalnościowych z kodem magnetycznym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Manyetik kodlu birkaç sadakat kartı bulundu %1.
			                   |Uygun kartı seç.'");
		Else
			Text = NStr("vi = 'Đã tìm thấy nhiều thẻ khách hàng thân thiết có mã vạch %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько карт лояльности со штрихкодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several loyalty cards with barcode %1 were found.
			                   |Select an appropriate card.'; fa = 'Several loyalty cards with barcode %1 were found.
			                   |Select an appropriate card.';
			                   |it = 'Rilevate multiple carte fedeltà con il codice a barre %1.
			                   |Selezionate la carta adatta.';
			                   |pl = 'Wykryto kilka kart lojalnościowych z kodem kreskowym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Birden çok barkodlu sadakat kartı bulundu %1.
			                   |Uygun kartı seç.'");
		EndIf;
		LabelLoyaltyCardSelection = StrTemplate(Text, FirstCodeOfTheNewCard);
	ElsIf Page = Items.Pages.ChildItems.GroupReadNewLoyaltyCard Then
		CurrentItem = Items.FirstCodeOfTheNewCard;
	ElsIf Page = Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard Then
		CurrentItem = Items.ReplacedCard;
	ElsIf Page = Items.Pages.ChildItems.GroupRefinementOfTheSecondLoyaltyCardCode Then
		If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			CurrentItem = Items.NewCardBarcode;
			Text = NStr("vi = 'Thẻ khách hàng thân thiết ""%1"" (Mã từ: %2) là thẻ có kiểu hỗn hợp (có mã từ và mã vạch).
			                   |Hãy đọc thông qua máy quét mã vạch hoặc chỉ ra thủ công mã vạch của thẻ.';
			                   |ru = 'Карта лояльности ""%1"" (Магнитный код: %2) является картой смешанного типа (имеет магнитный и штриховой коды).
			                   |Считайте при помощи сканера штрихкода или укажите вручную штрихкод карты.';
			                   |en = 'Loyalty card ""%1"" (Magnetic code: %2) is a mixed kind of card (it has a magnetic code and a barcode).
			                   |Read it with a barcode scanner or specify the card barcode manually.'; fa = 'Loyalty card ""%1"" (Magnetic code: %2) is a mixed kind of card (it has a magnetic code and a barcode).
			                   |Read it with a barcode scanner or specify the card barcode manually.';
			                   |it = 'La carta fedeltà ""%1"" (Codice magnetico: %2) è una carta di tipo misto (possiede sia il codice a barre che quello magnetico).
			                   |Leggetela usando un lettore di codice a barre oppure indicate manualmente il codice a barre della carta.';
			                   |pl = 'Karta lojalnościowa ""%1"" (Kod magnetyczny: %2) jest kartą typu mieszanego (posiada kod magnetyczny i kreskowy).
			                   |Sczytaj przy pomocy skanera kodów kreskowych lub wskaż ręcznie kod kreskowy karty.';
			                   |tr = '""%1"" Sadakat kartı (Manyetik kod: %2) karışık tipte bir karttır (manyetik ve barkodludur).
			                   |Bir barkod tarayıcı ile okutun veya kartın barkodunu manuel olarak gir.'");
		Else
			CurrentItem = Items.MagneticCodeOfANewCard;
			Text = NStr("vi = 'Thẻ khách hàng thân thiết ""%1"" (Mã vạch: %2) là thẻ kiểu hỗn hợp (có mã từ và mã vạch).
			                   |Hãy đọc thông qua máy đọc thẻ từ hoặc chỉ ra thủ công mã từ của thẻ.';
			                   |ru = 'Карта лояльности ""%1"" (Штрихкод: %2) является картой смешанного типа (имеет магнитный и штриховой коды).
			                   |Считайте при помощи считывателя магнитных карт или укажите вручную магнитный код карты.';
			                   |en = 'Loyalty card ""%1"" (Barcode: %2) is a mixed kind of card (it has a magnetic code and a barcode).
			                   |Read it with a barcode scanner or specify the magnetic code manually.'; fa = 'Loyalty card ""%1"" (Barcode: %2) is a mixed kind of card (it has a magnetic code and a barcode).
			                   |Read it with a barcode scanner or specify the magnetic code manually.';
			                   |it = 'La carta fedeltà ""%1"" (Codice a barre: %2) è una carta di tipo misto (possiede sia il codice magnetico che quello a barre).
			                   |Leggetela usando un lettore di carte magnetiche oppure indicate manualmente il codice magnetico della carta.';
			                   |pl = 'Karta lojalnościowa ""%1"" (Kod kreskowy: %2) jest kartą typu mieszanego (posiada kod magnetyczny i kreskowy).
			                   |Sczytaj przy pomocy czytnika kart magnetycznych lub wskaż ręcznie kod magnetyczny karty.';
			                   |tr = 'Sadakat kartı ""%1"" (Barkod: %2) karışık tipte bir karttır (manyetik ve barkodludur).
			                   |Bir manyetik kart okuyucu ile okutun veya kartın manyetik kodunu manuel olarak gir.'");
		EndIf;
		LabelSpecifyingTheSecondLoyaltyCardCode = StrTemplate(Text, NewCardKind, FirstCodeOfTheNewCard);
	ElsIf Page = Items.Pages.ChildItems.GroupEnteringInformationAboutTheCardholder Then
		If NewCardType = PredefinedValue("Enum.CardTypes.Mixed") Then
			Text = NStr("vi = 'Thẻ khách hàng thân thiết ""%1"" (%2: %3, %4: %5) là cá nhân.
			                   |Để hoàn thành ghi nhận hãy chỉ ra thông tin về chủ sở hữu thẻ.';
			                   |ru = 'Карта лояльности ""%1"" (%2: %3, %4: %5) является персонализированной.
			                   |Для завершения регистрации уточните информацию о владельце карты.';
			                   |en = 'Loyalty card ""%1"" (%2: %3, %4: %5) is personalized.
			                   |To finish the registration, specify the information about the card holder.'; fa = 'Loyalty card ""%1"" (%2: %3, %4: %5) is personalized.
			                   |To finish the registration, specify the information about the card holder.';
			                   |it = 'La carta fedeltà ""%1"" (%2: %3, %4: %5) è personalizzata. 
			                   |Per completare la registrazione specificate le informazioni sul titolare della carta.';
			                   |pl = 'Karta lojalnościowa ""%1"" (%2: %3, %4: %5) jest kartą osobistą.
			                   |W celu zakończenia rejestracji uściślij informację o właścicielu karty.';
			                   |tr = 'Sadakat kartı  ""%1"" (%2: %3, %4: %5) kişiye özeldir.
			                   |Kaydı tamamlamak için kart sahibi hakkındaki bilgileri belirt.'");
			LabelEnteringInformationAboutTheCardholder = StrTemplate(Text, NewCardKind, TypeOfTheFirstCodeOfTheNewMap, FirstCodeOfTheNewCard, TypeOfTheSecondCodeForTheNewMap, SecondCodeOfTheNewCard);
		Else
			Text = NStr("vi = 'Thẻ khách hàng thân thiết ""%1"" (%2: %3) là cá nhân.
			                   |Để hoàn thành ghi nhận, hãy chỉ ra thông tin về chủ sở hữu thẻ.';
			                   |ru = 'Карта лояльности ""%1"" (%2: %3) является персонализированной.
			                   |Для завершения регистрации уточните информацию о владельце карты.';
			                   |en = 'Loyalty card ""%1"" (%2: %3) is personalized.
			                   |To finish the registration, specify the information about the card holder.'; fa = 'Loyalty card ""%1"" (%2: %3) is personalized.
			                   |To finish the registration, specify the information about the card holder.';
			                   |it = 'La carta fedeltà ""%1"" (%2: %3) è personalizzata.
			                   |Per completare la registrazione specificate le informazioni sul titolare della carta.';
			                   |pl = 'Karta lojalnościowa ""%1"" (%2: %3) jest kartą osobistą.
			                   |W celu zakończenia rejestracji uściślij informację o właścicielu karty.';
			                   |tr = 'Sadakat kartı kişiye özeldir ""%1"" (%2: %3).
			                   |Kaydı tamamlamak için kart sahibi hakkındaki bilgileri belirt.'");
			LabelEnteringInformationAboutTheCardholder = StrTemplate(Text, NewCardKind, TypeOfTheFirstCodeOfTheNewMap, FirstCodeOfTheNewCard);
		EndIf;
		If ValueIsFilled(ReplacedCard) Then
			LabelEnteringInformationAboutTheCardholder = StrTemplate(NStr("vi = 'Thẻ khách hàng thân thiết thay thế ""%1"" sẽ bị hủy.';
																			|ru = 'Заменяемая карта лояльности ""%1"" будет аннулирована.';
																			|en = 'Loyalty card ""%1"" being replaced will be canceled.'; fa = 'Loyalty card ""%1"" being replaced will be canceled.';
																			|it = 'La carta fedeltà in fase di sostituzione ""%1"" verrà annullata.';
																			|pl = 'Wymieniana karta lojalnościowa ""%1"" zostanie anulowana.';
																			|tr = '""%1"" Değiştirilen sadakat kartı iptal edilecek.'"), ReplacedCard)
			                                     + Chars.LF + LabelEnteringInformationAboutTheCardholder;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ProcessFirstCodeOfNewMapOnServer(Data, CodeType, Preprocessing)
	
	FoundLoyaltyCardsNewLoyaltyCardReading.Clear();
	
	SecondCodeOfTheNewCard = "";
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode");
		TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode");
		If Preprocessing Then
			FirstCodeOfTheNewCard = Data[0]; // Data of 3 tracks of the magnetic card. Used if the card is not found.
			MagneticCodeOfANewCard = Data[0];
			LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsBasedOnMagneticCardReaderData(Data);
		Else
			FirstCodeOfTheNewCard = Data;
			MagneticCodeOfANewCard = Data;
			LoyaltyCards = LoyaltyCardsServer.FindLoyaltyCardsByMagneticCode(FirstCodeOfTheNewCard);
		EndIf;
		NewCardBarcode = "";
	Else
		FirstCodeOfTheNewCard = Data;
		NewCardBarcode = Data;
		TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode");
		TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode");
		LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsByBarcode(FirstCodeOfTheNewCard);
		MagneticCodeOfANewCard = "";
	EndIf;
	
	For Each TSRow In LoyaltyCards.RegisteredLoyaltyCards Do
		
		If ValueIsFilled(RequiredNewCardKind) And RequiredNewCardKind <> TSRow.CardKind Then
			Continue;
		EndIf;
		
		NewRow = FoundLoyaltyCardsNewLoyaltyCardReading.Add();
		FillPropertyValues(NewRow, TSRow);
		
		NewRow.Description = String(TSRow.Ref) + ?(ValueIsFilled(TSRow.Partner) And ValueIsFilled(TSRow.Ref), " " + StrTemplate(NStr("vi = 'Bạn hàng: %1';
																																	|ru = 'Партнер: %1';
																																	|en = 'Partner: %1'; fa = 'Partner: %1';
																																	|it = 'Partner: %1';
																																	|pl = 'Partner: %1';
																																	|tr = 'Ortak: %1'"), String(TSRow.Partner)), "");
		
	EndDo;
	
	For Each TSRow In LoyaltyCards.NotRegisteredLoyaltyCards Do
		
		If ValueIsFilled(RequiredNewCardKind) And RequiredNewCardKind <> TSRow.CardKind Then
			Continue;
		EndIf;
		
		NewRow = FoundLoyaltyCardsNewLoyaltyCardReading.Add();
		FillPropertyValues(NewRow, TSRow);
		
		NewRow.Description = StrTemplate(NStr("vi = 'Thẻ chưa ghi nhận: %1';
												|ru = 'Незарегистрированная карта: %1';
												|en = 'Unregistered card: %1'; fa = 'Unregistered card: %1';
												|it = 'Carta non registrata: %1';
												|pl = 'Niezarejestrowana karta: %1';
												|tr = 'Kayıtsız kart: %1'"), String(TSRow.CardKind));
		
	EndDo;
	
	If FoundLoyaltyCardsNewLoyaltyCardReading.Count() = 0 Then
		
		If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			If ValueIsFilled(RequiredNewCardKind) Then
				MessageText = StrTemplate(NStr("vi = 'Mã vạch ""%1"" không tương ứng với dạng thẻ khách hàng thân thiết ""%2""';
												|ru = 'Штрихкод ""%1"" не соответствует виду карт лояльности ""%2""';
												|en = 'Barcode ""%1"" does not match loyalty card kind ""%2""'; fa = 'Barcode ""%1"" does not match loyalty card kind ""%2""';
												|it = 'Il codice a barre ""%1"" non corrisponde al tipo delle carte fedeltà ""%2""';
												|pl = 'Kod kreskowy ""%1"" nie odpowiada rodzajowi kart lojalnościowych ""%2""';
												|tr = 'Barkod ""%1"" sadakat kartlarının türüyle eşleşmiyor ""%2""'"), FirstCodeOfTheNewCard, RequiredNewCardKind);
			Else
				MessageText = StrTemplate(NStr("vi = 'Mã vạch ""%1"" không tương ứng với bất kỳ dạng thẻ khách hàng thân thiết nào.';
												|ru = 'Штрихкод ""%1"" не соответствует ни одному из видов карт лояльности.';
												|en = 'Barcode ""%1"" matches no loyalty card kinds.'; fa = 'Barcode ""%1"" matches no loyalty card kinds.';
												|it = 'Il codice a barre ""%1"" non corrisponde nemmeno ad uno dei tipi delle carte fedeltà.';
												|pl = 'Kod kreskowy ""%1"" nie odpowiada ani jednemu rodzajowi kart lojalnościowych.';
												|tr = 'Barkod ""%1"" herhangi bir sadakat kartıyla eşleşmiyor.'"), FirstCodeOfTheNewCard);
			EndIf;
		Else
			If ValueIsFilled(RequiredNewCardKind) Then
				MessageText = StrTemplate(NStr("vi = 'Mã từ ""%1"" không tương ứng với dạng thẻ khách hàng thân thiết ""%2""';
												|ru = 'Магнитный код ""%1"" не соответствует виду карт лояльности ""%2""';
												|en = 'Magnetic code ""%1"" does not correspond to loyalty card kind ""%2""'; fa = 'Magnetic code ""%1"" does not correspond to loyalty card kind ""%2""';
												|it = 'Il codice magnetico ""%1"" non corrisponde al tipo delle carte fedeltà ""%2""';
												|pl = 'Kod magnetyczny ""%1"" nie odpowiada rodzajowi kart lojalnościowych ""%2""';
												|tr = 'Manyetik kod ""%1"" sadakat kartlarının türüyle eşleşmiyor ""%2"" '"), FirstCodeOfTheNewCard, RequiredNewCardKind);
			Else
				MessageText = StrTemplate(NStr("vi = 'Mã từ ""%1"" không tương ứng với bất kỳ dạng thẻ khách hàng thân thiết nào.';
												|ru = 'Магнитный код ""%1"" не соответствует ни одному из видов карт лояльности.';
												|en = 'Magnetic code ""%1"" does not correspond to any loyalty card kinds.'; fa = 'Magnetic code ""%1"" does not correspond to any loyalty card kinds.';
												|it = 'Il codice magnetico ""%1"" non corrisponde nemmeno ad uno dei tipi delle carte fedeltà.';
												|pl = 'Kod magnetyczny ""%1"" nie odpowiada żadnemu rodzajowi kart lojalnościowych.';
												|tr = 'Manyetik kod ""%1"" sadakat kartı türlerinin hiçbiri ile eşleşmiyor.'"), FirstCodeOfTheNewCard);
			EndIf;
		EndIf;
		
		CommonClientServer.MessageToUser(
			MessageText,
			,
			"FirstCodeOfTheNewCard");
		
	EndIf;
	
	Return FoundLoyaltyCardsNewLoyaltyCardReading.Count() > 0;
	
EndFunction

&AtServer
Function ProcessSecondCodeOfNewMapOnServer(Data, Preprocessing)
	
	Result = False;
	
	If TypeOfTheSecondCodeForTheNewMap = Enums.CardCodeTypes.MagneticCode Then
		If Preprocessing Then
			SecondCodeOfTheNewCard = Data[0]; // Data of 3 tracks of the magnetic card. Used if the card is not found.
			MagneticCodeOfANewCard = Data[0];
			LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsBasedOnMagneticCardReaderData(Data);
		Else
			SecondCodeOfTheNewCard = Data;
			MagneticCodeOfANewCard = Data;
			LoyaltyCards = LoyaltyCardsServer.FindLoyaltyCardsByMagneticCode(SecondCodeOfTheNewCard);
		EndIf;
	Else
		NewCardBarcode = Data;
		SecondCodeOfTheNewCard = Data;
		LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsByBarcode(SecondCodeOfTheNewCard);
	EndIf;
	
	// If the required type of card with the specified code is found, the card is suitable
	For Each TSRow In LoyaltyCards.NotRegisteredLoyaltyCards Do
		If ValueIsFilled(NewCardKind) And NewCardKind = TSRow.CardKind Then
			
			Result = True;
			
			If TypeOfTheSecondCodeForTheNewMap = Enums.CardCodeTypes.MagneticCode Then
				MagneticCodeOfANewCard = TSRow.MagneticCode;
				SecondCodeOfTheNewCard = TSRow.MagneticCode;
			Else
				NewCardBarcode = TSRow.Barcode;
				SecondCodeOfTheNewCard = TSRow.Barcode;
			EndIf;
			
			Break;
			
		EndIf;
	EndDo;
	
	// We check that there are no registered cards with this code
	For Each TSRow In LoyaltyCards.RegisteredLoyaltyCards Do
		
		If ValueIsFilled(NewCardKind) And NewCardKind = TSRow.CardKind Then
			
			If TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				MessageText = NStr("vi = 'Mã vạch ""%1"" đã được ghi nhận đối với thẻ ""%2"".';
									|ru = 'Штрихкод ""%1"" уже зарегистрирован для карты ""%2"".';
									|en = 'Barcode ""%1"" has already been registered for card ""%2"".'; fa = 'Barcode ""%1"" has already been registered for card ""%2"".';
									|it = 'Il codice a barre ""%1"" è già registrato per la carta ""%2"".';
									|pl = 'Kod kreskowy ""%1"" jest już zarejestrowany dla karty ""%2"".';
									|tr = 'Barkod ""%1"" zaten karta kayıtlıdır ""%2"".'");
				Field = "NewCardBarcode";
				CardCode = TSRow.Barcode;
			Else
				MessageText = NStr("vi = 'Mã từ ""%1"" đã được ghi nhận đối với thẻ ""%2"".';
									|ru = 'Магнитный код ""%1"" уже зарегистрирован для карты ""%2"".';
									|en = 'Magnetic code ""%1"" has already been registered for card ""%2"".'; fa = 'Magnetic code ""%1"" has already been registered for card ""%2"".';
									|it = 'Il codice a barre ""%1"" è già registrato per la carta ""%2"".';
									|pl = 'Kod magnetyczny ""%1"" jest już zarejestrowany dla karty ""%2"".';
									|tr = 'Manyetik kod ""%1"" zaten ""%2"" kartı için kayıtlı.'");
				Field = "MagneticCodeOfANewCard";
				CardCode = TSRow.MagneticCode;
			EndIf;
			
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CardCode, TSRow.Ref),
				,
				Field);
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	// If nothing could be found.
	If Not Result Then
		
		If TypeOfTheSecondCodeForTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			If ValueIsFilled(RequiredNewCardKind) Then
				MessageText = StrTemplate(NStr("vi = 'Mã vạch ""%1"" không tương ứng với dạng thẻ khách hàng thân thiết ""%2""';
												|ru = 'Штрихкод ""%1"" не соответствует виду карт лояльности ""%2""';
												|en = 'Barcode ""%1"" does not match loyalty card kind ""%2""'; fa = 'Barcode ""%1"" does not match loyalty card kind ""%2""';
												|it = 'Il codice a barre ""%1"" non corrisponde al tipo delle carte fedeltà ""%2""';
												|pl = 'Kod kreskowy ""%1"" nie odpowiada rodzajowi kart lojalnościowych ""%2""';
												|tr = 'Barkod ""%1"" sadakat kartlarının türüyle eşleşmiyor ""%2""'"), SecondCodeOfTheNewCard, RequiredNewCardKind);
			Else
				MessageText = StrTemplate(NStr("vi = 'Mã vạch ""%1"" không tương ứng với bất kỳ dạng thẻ khách hàng thân thiết nào.';
												|ru = 'Штрихкод ""%1"" не соответствует ни одному из видов карт лояльности.';
												|en = 'Barcode ""%1"" matches no loyalty card kinds.'; fa = 'Barcode ""%1"" matches no loyalty card kinds.';
												|it = 'Il codice a barre ""%1"" non corrisponde nemmeno ad uno dei tipi delle carte fedeltà.';
												|pl = 'Kod kreskowy ""%1"" nie odpowiada ani jednemu rodzajowi kart lojalnościowych.';
												|tr = 'Barkod ""%1"" herhangi bir sadakat kartıyla eşleşmiyor.'"), SecondCodeOfTheNewCard);
			EndIf;
			Field = "NewCardBarcode";
		Else
			If ValueIsFilled(RequiredNewCardKind) Then
				MessageText = StrTemplate(NStr("vi = 'Mã từ ""%1"" không tương ứng với dạng thẻ khách hàng thân thiết ""%2""';
												|ru = 'Магнитный код ""%1"" не соответствует виду карт лояльности ""%2""';
												|en = 'Magnetic code ""%1"" does not correspond to loyalty card kind ""%2""'; fa = 'Magnetic code ""%1"" does not correspond to loyalty card kind ""%2""';
												|it = 'Il codice magnetico ""%1"" non corrisponde al tipo delle carte fedeltà ""%2""';
												|pl = 'Kod magnetyczny ""%1"" nie odpowiada rodzajowi kart lojalnościowych ""%2""';
												|tr = 'Manyetik kod ""%1"" sadakat kartlarının türüyle eşleşmiyor ""%2"" '"), SecondCodeOfTheNewCard, RequiredNewCardKind);
			Else
				MessageText = StrTemplate(NStr("vi = 'Mã từ ""%1"" không tương ứng với bất kỳ dạng thẻ khách hàng thân thiết nào.';
												|ru = 'Магнитный код ""%1"" не соответствует ни одному из видов карт лояльности.';
												|en = 'Magnetic code ""%1"" does not correspond to any loyalty card kinds.'; fa = 'Magnetic code ""%1"" does not correspond to any loyalty card kinds.';
												|it = 'Il codice magnetico ""%1"" non corrisponde nemmeno ad uno dei tipi delle carte fedeltà.';
												|pl = 'Kod magnetyczny ""%1"" nie odpowiada żadnemu rodzajowi kart lojalnościowych.';
												|tr = 'Manyetik kod ""%1"" sadakat kartı türlerinin hiçbiri ile eşleşmiyor.'"), SecondCodeOfTheNewCard);
			EndIf;
			Field = "MagneticCodeOfANewCard";
		EndIf;
		
		CommonClientServer.MessageToUser(
			MessageText,
			,
			Field);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ProcessFirstCodeOfNewCardOnClient(Data, CodeType, Preprocessing)
	
	ClearMessages();
	
	Result = ProcessFirstCodeOfNewMapOnServer(Data, CodeType, Preprocessing);
	If Not Result Then
		Return;
	EndIf;
	
	If FoundLoyaltyCardsNewLoyaltyCardReading.Count() > 1 Then
		GoToPage3(Items.Pages.ChildItems.GroupSelectingANewLoyaltyCard);
	ElsIf FoundLoyaltyCardsNewLoyaltyCardReading.Count() = 1 Then
		ProcessSelectionOfNewLoyaltyCard(FoundLoyaltyCardsNewLoyaltyCardReading[0]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSecondCodeOfNewCardOnClient(Data, Preprocessing)
	
	ClearMessages();
	
	Result = ProcessSecondCodeOfNewMapOnServer(Data, Preprocessing);
	If Not Result Then
		Return;
	EndIf;
	
	If NewCardIsCustomized Then
		GoToPage3(Items.Pages.ChildItems.GroupEnteringInformationAboutTheCardholder);
	Else
		Done(Commands["Done"]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSelectionOfNewLoyaltyCard(CurrentData)
	
	If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
		FirstCodeOfTheNewCard = CurrentData.Barcode;
		NewCardBarcode = CurrentData.Barcode;
	Else
		FirstCodeOfTheNewCard = CurrentData.MagneticCode;
		MagneticCodeOfANewCard = CurrentData.MagneticCode;
	EndIf;
	
	
	If ValueIsFilled(NewCard) And Not ObjectAttributeValue(NewCard, "Barcode") = FirstCodeOfTheNewCard Then
		DeleteRegisteredLoyaltyCard();
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) And CurrentData.Ref <> NewCard Then // The card is already registered.
		
		If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			MessageText = NStr("vi = 'Thẻ ""%1"" có mã vạch %2 đã được ghi nhận.';
								|ru = 'Карта ""%1"" со штрихкодом %2 уже зарегистрирована.';
								|en = 'Card ""%1"" with barcode %2 is already registered.'; fa = 'Card ""%1"" with barcode %2 is already registered.';
								|it = 'La carta ""%1"" con il codice a barre %2 è già registrata.';
								|pl = 'Karta ""%1"" z kodem kreskowym %2 jest już zarejestrowana.';
								|tr = '%2 barkodlu ""%1"" kart zaten kayıtlı.'");
		Else
			MessageText = NStr("vi = 'Thẻ ""%1"" có mã từ %2 đã được ghi nhận.';
								|ru = 'Карта ""%1"" с магнитным кодом %2 уже зарегистрирована.';
								|en = 'Card ""%1"" with magnetic code %2 is already registered.'; fa = 'Card ""%1"" with magnetic code %2 is already registered.';
								|it = 'La carta ""%1"" con il codice magnetico %2 è già registrata.';
								|pl = 'Karta ""%1"" z kodem magnetycznym %2 jest już zarejestrowana.';
								|tr = '%2 manyetik kodlu ""%1"" kartı zaten kayıtlı.'");
		EndIf;
		
		If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard Then
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, FirstCodeOfTheNewCard),
				,
				"FirstCodeOfTheNewCard",);
		ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupSelectingANewLoyaltyCard Then
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, FirstCodeOfTheNewCard),
				,
				StrTemplate("FoundLoyaltyCardsNewLoyaltyCardReading[%1].Description", FoundLoyaltyCardsNewLoyaltyCardReading.IndexOf(CurrentData)),);
		EndIf;
		
	ElsIf Not ValueIsFilled(CurrentData.Ref) // The card is not registered, is not valid
		And (CurrentData.CardKindStatus <> PredefinedValue("Enum.StatusesOfLoyaltyCardKinds.Valid")
		   Or (ValueIsFilled(CurrentData.ValidityEndDate) And EndOfDay(CurrentData.ValidityEndDate) < Date)) Then
		
		If CurrentData.CardKindStatus = PredefinedValue("Enum.StatusesOfLoyaltyCardKinds.Valid") Then
			If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				MessageText = NStr("vi = 'Thời hạn hiệu lực của thẻ ""%1"" có mã vạch %2 đã hết.';
									|ru = 'Срок действия карты ""%1"" со штрихкодом %2 истек.';
									|en = 'Card ""%1"" with barcode %2 has expired.'; fa = 'Card ""%1"" with barcode %2 has expired.';
									|it = 'La carta ""%1"" con il codice a barre %2 è scaduta.';
									|pl = 'Termin ważności karty ""%1"" z kodem kreskowym %2 minął.';
									|tr = '%2 barkodlu ""%1"" kartının süresi doldu.'");
			Else
				MessageText = NStr("vi = 'Thời hạn hiệu lực của thẻ ""%1"" có mã từ %2 đã hết.';
									|ru = 'Срок действия карты ""%1"" с магнитным кодом %2 истек.';
									|en = 'Card ""%1"" with magnetic code %2 has expired.'; fa = 'Card ""%1"" with magnetic code %2 has expired.';
									|it = 'La carta ""%1"" con il codice magnetico %2 è scaduta.';
									|pl = 'Termin ważności karty ""%1"" z kodem magnetycznym%2 minął.';
									|tr = '%2 manyetik kodlu ""%1"" kartının süresi doldu.'");
			EndIf;
		Else
			If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				MessageText = NStr("vi = 'Thẻ ""%1"" có mã vạch %2 đã bị hủy.';
									|ru = 'Карта ""%1"" со штрихкодом %2 аннулирована.';
									|en = 'Card ""%1"" with barcode %2 is canceled.'; fa = 'Card ""%1"" with barcode %2 is canceled.';
									|it = 'La carta ""%1"" con il codice a barre %2 è stata annullata.';
									|pl = 'Karta ""%1"" z kodem kreskowym %2 została anulowana.';
									|tr = '%2 barkodlu ""%1"" kartı iptal edildi.'");
			Else
				MessageText = NStr("vi = 'Thẻ ""%1"" có mã từ %2 đã bị hủy.';
									|ru = 'Карта ""%1"" с магнитным кодом %2 аннулирована.';
									|en = 'Card ""%1"" with magnetic code %2 is canceled.'; fa = 'Card ""%1"" with magnetic code %2 is canceled.';
									|it = 'La carta ""%1"" con il codice magnetico %2 è stata annullata.';
									|pl = 'Karta ""%1"" z kodem magnetycznym %2 została anulowana.';
									|tr = '%2 manyetik kodlu ""%1"" kartı iptal edildi.'");
			EndIf;
		EndIf;
		
		If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadNewLoyaltyCard Then
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, FirstCodeOfTheNewCard),
				,
				"FirstCodeOfTheNewCard",);
		ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupSelectingANewLoyaltyCard Then
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, FirstCodeOfTheNewCard),
				,
				StrTemplate("FoundLoyaltyCardsNewLoyaltyCardReading[%1].Description", FoundLoyaltyCardsNewLoyaltyCardReading.IndexOf(CurrentData)),);
		EndIf;
		
	Else // The card is not registered.
		
		NewCardKind             = CurrentData.CardKind;
		NewCardType             = CurrentData.CardType;
		NewCardIsCustomized = CurrentData.Personalized;
		
		If CurrentData.CardType = PredefinedValue("Enum.CardTypes.Mixed") Then
			GoToPage3(Items.Pages.ChildItems.GroupRefinementOfTheSecondLoyaltyCardCode);
			If TypeOfTheFirstCodeOfTheNewMap = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
				Items.PagesCodeClarification.CurrentPage = Items.PagesCodeClarification.ChildItems.GroupSpecificationOfTheBarcode;
			Else
				Items.PagesCodeClarification.CurrentPage = Items.PagesCodeClarification.ChildItems.GroupRefinementOfTheMagneticCode;
			EndIf;
		Else
			If NewCardIsCustomized Then
				GoToPage3(Items.Pages.ChildItems.GroupEnteringInformationAboutTheCardholder);
			Else
				Done(Commands["Done"]);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ProcessFirstReplacementCardCodeOnServer(Data, CodeType, Preprocessing)
	
	FoundLoyaltyCardsReadingReplacedLoyaltyCard.Clear();
	
	TypeOfCodeForTheCardToReplace = CodeType;
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		If Preprocessing Then
			ReplacedCardCode = Data[0]; // Data of 3 tracks of the magnetic card. Used if the card is not found.
			LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsBasedOnMagneticCardReaderData(Data);
		Else
			ReplacedCardCode = Data;
			LoyaltyCards = LoyaltyCardsServer.FindLoyaltyCardsByMagneticCode(ReplacedCardCode);
		EndIf;
	Else
		ReplacedCardCode = Data;
		LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsByBarcode(ReplacedCardCode);
	EndIf;
	
	For Each TSRow In LoyaltyCards.RegisteredLoyaltyCards Do
		
		If ValueIsFilled(RequiredTypeOfCardToReplace) And RequiredTypeOfCardToReplace <> TSRow.CardKind Then
			Continue;
		EndIf;
		
		NewRow = FoundLoyaltyCardsReadingReplacedLoyaltyCard.Add();
		FillPropertyValues(NewRow, TSRow);
		
		NewRow.Description = String(TSRow.Ref) + ?(ValueIsFilled(TSRow.Partner) And ValueIsFilled(TSRow.Ref), " " + StrTemplate(NStr("vi = 'Bạn hàng: %1';
																																	|ru = 'Партнер: %1';
																																	|en = 'Partner: %1'; fa = 'Partner: %1';
																																	|it = 'Partner: %1';
																																	|pl = 'Partner: %1';
																																	|tr = 'Ortak: %1'"), String(TSRow.Partner)), "");
		
	EndDo;
	
	For Each TSRow In LoyaltyCards.NotRegisteredLoyaltyCards Do
		
		If ValueIsFilled(RequiredTypeOfCardToReplace) And RequiredTypeOfCardToReplace <> TSRow.CardKind Then
			Continue;
		EndIf;
		
		NewRow = FoundLoyaltyCardsReadingReplacedLoyaltyCard.Add();
		FillPropertyValues(NewRow, TSRow);
		
		NewRow.Description = StrTemplate(NStr("vi = 'Thẻ chưa ghi nhận: %1';
												|ru = 'Незарегистрированная карта: %1';
												|en = 'Unregistered card: %1'; fa = 'Unregistered card: %1';
												|it = 'Carta non registrata: %1';
												|pl = 'Niezarejestrowana karta: %1';
												|tr = 'Kayıtsız kart: %1'"), String(TSRow.CardKind));
		
	EndDo;
	
	If FoundLoyaltyCardsReadingReplacedLoyaltyCard.Count() > 0 Then
		
		If TypeOfCodeForTheCardToReplace = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			If ValueIsFilled(RequiredNewCardKind) Then
				MessageText = StrTemplate(NStr("vi = 'Mã vạch ""%1"" không tương ứng với dạng thẻ khách hàng thân thiết ""%2""';
												|ru = 'Штрихкод ""%1"" не соответствует виду карт лояльности ""%2""';
												|en = 'Barcode ""%1"" does not match loyalty card kind ""%2""'; fa = 'Barcode ""%1"" does not match loyalty card kind ""%2""';
												|it = 'Il codice a barre ""%1"" non corrisponde al tipo delle carte fedeltà ""%2""';
												|pl = 'Kod kreskowy ""%1"" nie odpowiada rodzajowi kart lojalnościowych ""%2""';
												|tr = 'Barkod ""%1"" sadakat kartlarının türüyle eşleşmiyor ""%2""'"), ReplacedCardCode, RequiredNewCardKind);
			Else
				MessageText = StrTemplate(NStr("vi = 'Mã vạch ""%1"" không tương ứng với bất kỳ dạng thẻ khách hàng thân thiết nào.';
												|ru = 'Штрихкод ""%1"" не соответствует ни одному из видов карт лояльности.';
												|en = 'Barcode ""%1"" matches no loyalty card kinds.'; fa = 'Barcode ""%1"" matches no loyalty card kinds.';
												|it = 'Il codice a barre ""%1"" non corrisponde nemmeno ad uno dei tipi delle carte fedeltà.';
												|pl = 'Kod kreskowy ""%1"" nie odpowiada ani jednemu rodzajowi kart lojalnościowych.';
												|tr = 'Barkod ""%1"" herhangi bir sadakat kartıyla eşleşmiyor.'"), ReplacedCardCode);
			EndIf;
		Else
			If ValueIsFilled(RequiredNewCardKind) Then
				MessageText = StrTemplate(NStr("vi = 'Mã từ ""%1"" không tương ứng với dạng thẻ khách hàng thân thiết ""%2""';
												|ru = 'Магнитный код ""%1"" не соответствует виду карт лояльности ""%2""';
												|en = 'Magnetic code ""%1"" does not correspond to loyalty card kind ""%2""'; fa = 'Magnetic code ""%1"" does not correspond to loyalty card kind ""%2""';
												|it = 'Il codice magnetico ""%1"" non corrisponde al tipo delle carte fedeltà ""%2""';
												|pl = 'Kod magnetyczny ""%1"" nie odpowiada rodzajowi kart lojalnościowych ""%2""';
												|tr = 'Manyetik kod ""%1"" sadakat kartlarının türüyle eşleşmiyor ""%2"" '"), ReplacedCardCode, RequiredNewCardKind);
			Else
				MessageText = StrTemplate(NStr("vi = 'Mã từ ""%1"" không tương ứng với bất kỳ dạng thẻ khách hàng thân thiết nào.';
												|ru = 'Магнитный код ""%1"" не соответствует ни одному из видов карт лояльности.';
												|en = 'Magnetic code ""%1"" does not correspond to any loyalty card kinds.'; fa = 'Magnetic code ""%1"" does not correspond to any loyalty card kinds.';
												|it = 'Il codice magnetico ""%1"" non corrisponde nemmeno ad uno dei tipi delle carte fedeltà.';
												|pl = 'Kod magnetyczny ""%1"" nie odpowiada żadnemu rodzajowi kart lojalnościowych.';
												|tr = 'Manyetik kod ""%1"" sadakat kartı türlerinin hiçbiri ile eşleşmiyor.'"), ReplacedCardCode);
			EndIf;
		EndIf;
		
		CommonClientServer.MessageToUser(
			MessageText,
			,
			"FirstCodeOfTheNewCard");
		
	EndIf;
	
	Return FoundLoyaltyCardsReadingReplacedLoyaltyCard.Count() > 0;
	
EndFunction

&AtClient
Procedure ProcessFirstReplacementCardCodeOnClient(Data, CodeType, Preprocessing)
	
	ClearMessages();
	
	Result = ProcessFirstReplacementCardCodeOnServer(Data, CodeType, Preprocessing);
	If Not Result Then
		Return;
	EndIf;
	
	If FoundLoyaltyCardsReadingReplacedLoyaltyCard.Count() > 1 Then
		GoToPage3(Items.Pages.ChildItems.GroupSelectingANewLoyaltyCard);
	ElsIf FoundLoyaltyCardsReadingReplacedLoyaltyCard.Count() = 1 Then
		ProcessSelectionOfReplacementLoyaltyCard(FoundLoyaltyCardsReadingReplacedLoyaltyCard[0]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSelectionOfReplacementLoyaltyCard(CurrentData)
	
	If TypeOfCodeForTheCardToReplace = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
		ReplacedCardCode = CurrentData.MagneticCode;
	Else
		ReplacedCardCode = CurrentData.Barcode;
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) Then // The card is already registered.
		
		ReplacedCard = CurrentData.Ref;
		StructureOfData = LoyaltyCardServerCall.GetLoyaltyCardDetails(CurrentData.Ref);
		
		If ValueIsFilled(StructureOfData.Counterparty) And Not ValueIsFilled(Counterparty) Then
			Counterparty = StructureOfData.Counterparty;
		EndIf;
		
		If ValueIsFilled(StructureOfData.Terms) And Not ValueIsFilled(Terms) Then
			Terms = StructureOfData.Terms;
		EndIf;
		
		GoToPage3(Items.Pages.ChildItems.GroupReadNewLoyaltyCard);
		
	Else // The card is not registered.
		
		If TypeOfCodeForTheCardToReplace = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			MessageText = NStr("vi = 'Thẻ ""%1"" có mã vạch %2 vẫn chưa được ghi nhận và không thể thay thế.';
								|ru = 'Карта ""%1"" со штрихкодом %2 еще не зарегистрирована и не может быть заменена.';
								|en = 'Card ""%1"" with barcode %2 is not registered yet and cannot be replaced.'; fa = 'Card ""%1"" with barcode %2 is not registered yet and cannot be replaced.';
								|it = 'La carta ""%1"" con il codice a barre %2 non è ancora stata registrata e non può essere rimpiazzata.';
								|pl = 'Karta ""%1"" z kodem kreskowym %2 nie została jeszcze zarejestrowana i nie może być wymieniona.';
								|tr = '%2 barkodlu ""%1"" kartı henüz kaydedilmedi ve değiştirilemez.'");
		Else
			MessageText = NStr("vi = 'Thẻ ""%1"" có mã từ %2 vẫn chưa được ghi nhận và không thể thay thế.';
								|ru = 'Карта ""%1"" с магнитным кодом %2 еще не зарегистрирована и не может быть заменена.';
								|en = 'Card ""%1"" with magnetic code %2 is not registered yet and cannot be replaced.'; fa = 'Card ""%1"" with magnetic code %2 is not registered yet and cannot be replaced.';
								|it = 'La carta ""%1"" con il codice magnetico %2 non è ancora stata registrata e non può essere rimpiazzata.';
								|pl = 'Karta ""%1"" z kodem magnetycznym %2 nie została jeszcze zarejestrowana i nie może być wymieniona.';
								|tr = '%2 manyetik kodlu ""%1"" kartı henüz kaydedilmedi ve değiştirilemez.'");
		EndIf;
		
		If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAReplacementLoyaltyCard Then
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, ReplacedCardCode),
				,
				"ReplacedCard",);
		ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.SelectAReplacementLoyaltyCardGroup Then
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, ReplacedCardCode),
				,
				StrTemplate("FoundLoyaltyCardsReadingReplacedLoyaltyCard[%1].Description", FoundLoyaltyCardsReadingReplacedLoyaltyCard.IndexOf(CurrentData)),);
		EndIf;
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RegisterLoyaltyCard(EnterDataAboutTheCardHolder, RegisteringPartner)
	
	If NewCardIsCustomized And EnterDataAboutTheCardHolder = "Now" Then
		
		LoyaltyCardDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
		LoyaltyCardDataStructure.CardKind = NewCardKind;
		
		If TypeOfTheFirstCodeOfTheNewMap = Enums.CardCodeTypes.Barcode Then
			LoyaltyCardDataStructure.Barcode     = FirstCodeOfTheNewCard;
			LoyaltyCardDataStructure.MagneticCode = SecondCodeOfTheNewCard;
		Else
			LoyaltyCardDataStructure.Barcode     = SecondCodeOfTheNewCard;
			LoyaltyCardDataStructure.MagneticCode = FirstCodeOfTheNewCard;
		EndIf;
		
		LoyaltyCardDataStructure.Partner    = Partner;
		LoyaltyCardDataStructure.Counterparty = Counterparty;
		LoyaltyCardDataStructure.Terms = Terms;
		
		NewCard = LoyaltyCardsServer.RegisterLoyaltyCard(LoyaltyCardDataStructure);
		
	Else
		
		LoyaltyCardDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
		LoyaltyCardDataStructure.CardKind = NewCardKind;
		LoyaltyCardDataStructure.Insert("AccessGroup", AccessGroup);
		
		If TypeOfTheFirstCodeOfTheNewMap = Enums.CardCodeTypes.Barcode Then
			LoyaltyCardDataStructure.Barcode     = FirstCodeOfTheNewCard;
			LoyaltyCardDataStructure.MagneticCode = SecondCodeOfTheNewCard;
		Else
			LoyaltyCardDataStructure.Barcode     = SecondCodeOfTheNewCard;
			LoyaltyCardDataStructure.MagneticCode = FirstCodeOfTheNewCard;
		EndIf;
		                     
		If NewCardIsCustomized And RegisteringPartner Then
			NewCard = LoyaltyCardsServer.CreatePartnerAndRegisterLoyaltyCard(LoyaltyCardDataStructure);
		Else
			NewCard = LoyaltyCardsServer.RegisterLoyaltyCard(LoyaltyCardDataStructure);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeLoyaltyCardPartnerDetails()
	
	Map_Object = NewCard.GetObject();
	If NewCardIsCustomized Then
		If EnterDataAboutTheCardHolder = "Now" Then
			Map_Object.Partner    = Partner;
			Map_Object.Counterparty = Counterparty;
			Map_Object.Terms = Terms;
		Else
			
			If Not ValueIsFilled(Map_Object.Partner) Then
				
				LoyaltyCardDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
				LoyaltyCardDataStructure.CardKind = NewCardKind;
				
				If TypeOfTheFirstCodeOfTheNewMap = Enums.CardCodeTypes.Barcode Then
					LoyaltyCardDataStructure.Barcode     = FirstCodeOfTheNewCard;
					LoyaltyCardDataStructure.MagneticCode = SecondCodeOfTheNewCard;
				Else
					LoyaltyCardDataStructure.Barcode     = SecondCodeOfTheNewCard;
					LoyaltyCardDataStructure.MagneticCode = FirstCodeOfTheNewCard;
				EndIf;
				
				SetPrivilegedMode(True);			
				Map_Object.Partner = LoyaltyCardsServer.CreateLoyaltyCardHolderPartner(LoyaltyCardDataStructure);
				
			EndIf;
			
			Map_Object.Counterparty = Undefined;
			Map_Object.Terms = Undefined;
		EndIf;
	Else
		Map_Object.Partner    = Undefined;
		Map_Object.Counterparty = Undefined;
		Map_Object.Terms = Undefined;
	EndIf;
	
	Map_Object.Write();
	
EndProcedure

&AtServer
Procedure DeleteRegisteredLoyaltyCard()
	
	SetPrivilegedMode(True);
	Map_Object = NewCard.GetObject();
	Map_Object.Delete();
	
	NewCard = Catalogs.LoyaltyCards.EmptyRef();
	
EndProcedure

&AtServer
Procedure DoneOnServer()
	
	If Not ValueIsFilled(NewCard) Then
		RegisterLoyaltyCard(EnterDataAboutTheCardHolder, True);
	Else
		ChangeLoyaltyCardPartnerDetails();
	EndIf;
	
	If ValueIsFilled(ReplacedCard) Then
		LoyaltyCardsServer.CancelLoyaltyCard(ReplacedCard);
	EndIf;
	
EndProcedure

&AtClient
Procedure NextIsWaitHandler()
	
	Next(Commands["Next"]);
	
EndProcedure

&AtServerNoContext
Function GetPartnerSDefaultCard(Partner)
	Return LoyaltyCardsServer.GetPartnerSDefaultCard(Partner);
EndFunction

&AtServerNoContext
Function ObjectAttributeValue(Ref, AttributeName)
	
	Return Common.ObjectAttributeValue(Ref, AttributeName);
	
EndFunction

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
