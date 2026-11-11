
#Region Variables

&AtClient
Var PageStack; // Array - The history of transitions to return to the back button

&AtClient
Var ReaderData; // Magnetic Card Reader Data Cache

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
	
	DoNotConnectTheEquipment = Parameters.DoNotConnectTheEquipment;
	Partner                  = Parameters.Partner;
	Date                     = CurrentSessionDate();
	Organization              = Parameters.Organization;
	
	MainCodeType = LoyaltyCardsServer.GetMainTypeOfLoyaltyCardCode();
	
	DoNotUseManualInput = Parameters.DoNotUseManualInput;
	If DoNotUseManualInput Then
		Items.CardCodeGroup.Visible = False;
		ThisForm.CurrentItem = Items.ConfirmButton;
	EndIf;
	
	If ValueIsFilled(Parameters.CardCode) Then
		
		// When reading in the form of a list, several cards with this code were found,
		// it is required to offer cards to the user to choose from.
		ProcessReceivedCodeOnServer(Parameters.CardCode, Parameters.CodeType, True);
		Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardSelectionGroup;
		
	Else
		
		If ValueIsFilled(MainCodeType) Then
			CodeType = MainCodeType;
			Items.CodeType.Visible = False;
		Else
			CodeType = Enums.CardCodeTypes.Barcode;
		EndIf;
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardReadingGroup;
		
	EndIf;
	
	Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.TheBackButtonIsMissing;
	Items.NextButtonPages.CurrentPage = Items.NextButtonPages.ChildItems.ConfirmButton;
	
	If Not DoNotUseManualInput Then
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
	Else
		If Not ValueIsFilled(MainCodeType) Then
			Text = NStr("vi = 'Hãy đọc thẻ khách hàng thân thiết mới bằng máy quét mã vạch (đầu đọc thẻ từ)';
						|ru = 'Считайте новую карту лояльности при помощи сканера штрихкода (считывателя магнитных карт)';
						|en = 'Read a new loyalty card using a barcode scanner (magnetic stripe card reader)'; fa = 'Read a new loyalty card using a barcode scanner (magnetic stripe card reader)';
						|it = 'Считайте новую карту лояльности при помощи сканера штрихкода (считывателя магнитных карт)';
						|pl = 'Read a new loyalty card using a barcode scanner (magnetic stripe card reader)';
						|tr = 'Barkod tarayıcı (manyetik kart okuyucu) kullanarak yeni sadakat kartını okut'");
		ElsIf MainCodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			Text = NStr("vi = 'Hãy đọc thẻ khách hàng thân thiết mới bằng đầu đọc thẻ từ';
						|ru = 'Считайте новую карту лояльности при помощи считывателя магнитных карт';
						|en = 'Read a new loyalty card using a magnetic stripe card reader'; fa = 'Read a new loyalty card using a magnetic stripe card reader';
						|it = 'Считайте новую карту лояльности при помощи считывателя магнитных карт';
						|pl = 'Read a new loyalty card using a magnetic stripe card reader';
						|tr = 'Barkod tarayıcı (manyetik kart okuyucu) kullanarak yeni sadakat kartını okutun'");
		ElsIf MainCodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			Text = NStr("vi = 'Hãy đọc thẻ khách hàng thân thiết mới thông qua máy quét mã vạch';
						|ru = 'Считайте новую карту лояльности при помощи сканера штрихкода';
						|en = 'Read a new loyalty card using a barcode scanner'; fa = 'Read a new loyalty card using a barcode scanner';
						|it = 'Считайте новую карту лояльности при помощи сканера штрихкода';
						|pl = 'Read a new loyalty card using a barcode scanner';
						|tr = 'Barkod tarayıcı ile yeni sadakat kartını okutun'");
		EndIf;
	EndIf;
	LabelLoyaltyCardReading = Text;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PageStack = New Array;
	
	If DoNotConnectTheEquipment Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);

EndProcedure

&AtClient
Procedure OnClose()
	
	If DoNotConnectTheEquipment Then
		Return;
	EndIf;
	
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
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CodeTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CardCodeOnChange(Item)
	
	If ValueIsFilled(CardCode) Then
		AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure FoundLoyaltyCardsSelection(Item, RowSelected, Field, StandardProcessing)
	
	AttachIdleHandler("NextIsWaitHandler", 0.1, True);
	
EndProcedure

#Region CommandHandlers

&AtClient
Procedure Back(Command)
	
	If PageStack.Count() = 0 Then
		Return;
	EndIf;
	
	Items.Pages.CurrentPage = PageStack[PageStack.Count()-1];
	PageStack.Delete(PageStack.Count()-1);
	
	If PageStack.Count() = 0 Then
		Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.TheBackButtonIsMissing;
	EndIf;
	
	Items.NextButtonPages.CurrentPage = Items.NextButtonPages.ChildItems.ConfirmButton;
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	DetachIdleHandler("NextIsWaitHandler");
	
	ClearMessages();
	
	If Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardReadingGroup Then
		
		If Not ValueIsFilled(CardCode) Then
			
			If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				MessageText = NStr("vi = 'Chưa điền mã vạch.';
									|ru = 'Штрихкод не заполнен.';
									|en = 'Barcode is required.'; fa = 'Barcode is required.';
									|it = 'Codice a barre non compilato.';
									|pl = 'Nie wypełniono kodu kreskowego.';
									|tr = 'Barkod doldurulmamış.'");
			Else
				MessageText = NStr("vi = 'Chưa điền mã từ.';
									|ru = 'Магнитный код не заполнен.';
									|en = 'Magnetic code is required.'; fa = 'Magnetic code is required.';
									|it = 'Codice magnetico non compilato.';
									|pl = 'Nie wypełniono kodu magnetycznego.';
									|tr = 'Manyetik kod doldurulmamış.'");
			EndIf;
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				"CardCode");
			
			Return;
			
		EndIf;
		
		ProcessReceivedCodeOnClient(CardCode, CodeType, False);
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardSelectionGroup Then
		
		CurrentData = Items.FoundLoyaltyCards.CurrentData;
		If CurrentData <> Undefined Then
			ProcessLoyaltyCardSelection(CurrentData);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FoundLoyaltyCards.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FoundLoyaltyCards.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FoundLoyaltyCards.AllowAutoRegistrationAtFirstReading");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", New Color());
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If Items.Pages.CurrentPage <> Items.Pages.ChildItems.LoyaltyCardReadingGroup Then
		Return;
	EndIf;
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	ProcessReceivedCodeOnClient(ArrayOfBarcodes[0].Barcode, PredefinedValue("Enum.CardCodeTypes.Barcode"), False);
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	If Items.Pages.CurrentPage <> Items.Pages.ChildItems.LoyaltyCardReadingGroup Then
		Return;
	EndIf;
	
	ReaderData = Data;
	AttachIdleHandler("ProcessReceivedCodeOnClientInWaitProcessing", 0.1, True);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure GoToPage3(Page)
	
	PageStack.Add(Items.Pages.CurrentPage);
	Items.Pages.CurrentPage = Page;
	Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.BackButton;
	
	If Page = Items.Pages.ChildItems.LoyaltyCardSelectionGroup Then
		If CodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			Text = NStr("vi = 'Đã tìm thấy nhiều thẻ khách hàng thân thiết có mã từ %1.
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
		LabelLoyaltyCardSelection = StrTemplate(Text, CardCode);
	EndIf;
	
EndProcedure

&AtServer
Function ProcessReceivedCodeOnServer(Data, CardCodeType, Preprocessing)
	
	SetPrivilegedMode(True);
	
	FoundLoyaltyCards.Clear();
	
	CodeType = CardCodeType;
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		If Preprocessing Then
			CardCode = Data[0]; // Data of 3 tracks of the magnetic card. Used if the card is not found.
			LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsBasedOnMagneticCardReaderData(Data);
		Else
			CardCode = Data;
			LoyaltyCards = LoyaltyCardsServer.FindLoyaltyCardsByMagneticCode(CardCode);
		EndIf;
	Else
		CardCode = Data;
		LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsByBarcode(CardCode);
	EndIf;
	
	For Each TSRow In LoyaltyCards.RegisteredLoyaltyCards Do
		
		NewRow = FoundLoyaltyCards.Add();
		FillPropertyValues(NewRow, TSRow);
		
		NewRow.Description = String(TSRow.Ref) + ?(ValueIsFilled(TSRow.Partner) And ValueIsFilled(TSRow.Ref), " " + StrTemplate(NStr("vi = 'Khách hàng: %1';
																																	|ru = 'Клиент: %1';
																																	|en = 'Customer: %1'; fa = 'Customer: %1';
																																	|it = 'Cliente: %1';
																																	|pl = 'Klient: %1';
																																	|tr = 'İstemci: %1'"), String(TSRow.Partner)), "");
		
	EndDo;
	
	For Each TSRow In LoyaltyCards.NotRegisteredLoyaltyCards Do
		
		NewRow = FoundLoyaltyCards.Add();
		FillPropertyValues(NewRow, TSRow);
		
		NewRow.Description = StrTemplate(NStr("vi = 'Thẻ chưa ghi nhận: %1';
												|ru = 'Незарегистрированная карта: %1';
												|en = 'Unregistered card: %1'; fa = 'Unregistered card: %1';
												|it = 'Carta non registrata: %1';
												|pl = 'Niezarejestrowana karta: %1';
												|tr = 'Kayıtsız kart: %1'"), String(TSRow.CardKind));
		
	EndDo;
	
	Return FoundLoyaltyCards.Count() > 0;
	
EndFunction

&AtClient
Procedure ProcessReceivedCodeOnClient(Data, ReceivedCodeType, Preprocessing)
	
	Result = ProcessReceivedCodeOnServer(Data, ReceivedCodeType, Preprocessing);
	If Not Result Then
		
		If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
			MessageText = NStr("vi = 'Thẻ có mã vạch ""%1"" chưa được ghi nhận.';
								|ru = 'Карта со штрихкодом ""%1"" не зарегистрирована.';
								|en = 'Card with barcode ""%1"" is not registered.'; fa = 'Card with barcode ""%1"" is not registered.';
								|it = 'La carta con il codice a barre ""%1"" non è registrata.';
								|pl = 'Karta z kodem kreskowym ""%1"" nie jest zarejestrowana.';
								|tr = '""%1"" barkodlu kart kayıtlı değil.'");
		Else
			MessageText = NStr("vi = 'Thẻ có mã từ ""%1"" chưa được ghi nhận.';
								|ru = 'Карта с магнитным кодом ""%1"" не зарегистрирована.';
								|en = 'Card with magnetic code ""%1"" is not registered.'; fa = 'Card with magnetic code ""%1"" is not registered.';
								|it = 'La carta con il codice magnetico ""%1"" non è registrata.';
								|pl = 'Karta z kodem magnetycznym ""%1"" nie jest zarejestrowana.';
								|tr = '""%1"" manyetik kodlu kart kayıtlı değil.'");
		EndIf;
		
		CommonClientServer.MessageToUser(
			StrTemplate(MessageText, CardCode),
			,
			"CardCode");
		
		Return;
		
	EndIf;
	
	If FoundLoyaltyCards.Count() > 1 Then
		GoToPage3(Items.Pages.ChildItems.LoyaltyCardSelectionGroup);
		Text = NStr("vi = 'Đã tìm thấy nhiều thẻ khách hàng thân thiết có mã vạch %1.
		                   |Hãy chọn thẻ phù hợp.';
		                   |ru = 'Обнаружено несколько карт лояльности с кодом %1.
		                   |Выберите подходящую карту.';
		                   |en = 'Several loyalty cards with code %1 were found.
		                   |Select an appropriate card.'; fa = 'Several loyalty cards with code %1 were found.
		                   |Select an appropriate card.';
		                   |it = 'Rilevate multiple carte fedeltà con il codice %1.
		                   |Scegliete la carta adatta.';
		                   |pl = 'Wykryto kilka kart lojalnościowych z kodem %1.
		                   |Wybierz odpowiednią kartę.';
		                   |tr = 'Kod içeren birden çok bağlılık kartı bulundu%1.
		                   |Doğru kartı seç.'");
		LabelLoyaltyCardSelection = StrTemplate(Text, CardCode);
	ElsIf FoundLoyaltyCards.Count() = 1 Then
		ProcessLoyaltyCardSelection(FoundLoyaltyCards[0]);
	EndIf;
	
EndProcedure

&AtServer
Function RegisterLoyaltyCard(CardKind, MagneticCode, Barcode)
	
	MapDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
	MapDataStructure.CardKind = CardKind;
	If CodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
		MapDataStructure.MagneticCode = MagneticCode;
	ElsIf CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
		MapDataStructure.Barcode = Barcode;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	LoyaltyCardKinds.Personalized AS Personalized
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
	|WHERE
	|	LoyaltyCardKinds.Ref = &Ref");
	
	Query.SetParameter("Ref", CardKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	If Selection.Personalized Then
		If Not ValueIsFilled(Partner) Then
			Return LoyaltyCardsServer.CreatePartnerAndRegisterLoyaltyCard(MapDataStructure);
		Else
			MapDataStructure.Partner    = Partner;
			Return LoyaltyCardsServer.RegisterLoyaltyCard(MapDataStructure);
		EndIf;
	Else
		Return LoyaltyCardsServer.RegisterLoyaltyCard(MapDataStructure);
	EndIf;
	
EndFunction

&AtClient
Procedure ProcessLoyaltyCardSelection(CurrentData)
	
	If ValueIsFilled(CurrentData.Ref) Then
		
		If CurrentData.Status = PredefinedValue("Enum.LoyaltyCardStatuses.Valid")
			And CurrentData.ValidityStartDate <= Date
			And (Not ValueIsFilled(CurrentData.ValidityEndDate) Or EndOfDay(CurrentData.ValidityEndDate) >= Date) Then
			
			Close();
			Notify(
				"LoyaltyCardIsRead",
				New Structure("LoyaltyCard, OwnerForm", CurrentData.Ref, FormOwner.UUID),
				Undefined);
		
			ShowUserNotification(
				NStr("vi = 'Đã đọc thẻ khách hàng thân thiết';
					|ru = 'Считана карта лояльности';
					|en = 'Loyalty card is read'; fa = 'Loyalty card is read';
					|it = 'Carta fedeltà letta';
					|pl = 'Sczytana karta lojalnościowa';
					|tr = 'Sadakat kartı okundu'"),
				GetURL(CurrentData.Ref),
				StrTemplate(NStr("vi = 'Đã đọc thẻ khách hàng thân thiết %1';
								|ru = 'Считана карта лояльности %1';
								|en = 'Loyalty card %1 has been read'; fa = 'Loyalty card %1 has been read';
								|it = 'Carta fedeltà letta %1';
								|pl = 'Sczytana karta lojalnościowa %1';
								|tr = 'Sadakat kartı okundu %1'"), CurrentData.Ref),
				PictureLib.Information32);
		Else
			
			If CurrentData.Status = PredefinedValue("Enum.LoyaltyCardStatuses.Valid") Then
				
				If CurrentData.ValidityStartDate <= Date Then
					If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
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
					If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
						MessageText = NStr("vi = 'Thời hạn hiệu lực của thẻ ""%1"" có mã vạch %2 vẫn chưa bắt đầu.';
											|ru = 'Срок действия карты ""%1"" со штрихкодом %2 еще не наступил.';
											|en = 'Validity period of card ""%1"" with barcode %2 has not started yet.'; fa = 'Validity period of card ""%1"" with barcode %2 has not started yet.';
											|it = 'La validità della carta ""%1"" con il codice a barre ""%2"" non è ancora arrivata.';
											|pl = 'Okres ważności karty ""%1"" z kodem kreskowym %2 jeszcze się nie rozpoczął.';
											|tr = '%2 barkodlu ""%1"" kartının süresi henüz dolmadı.'");
					Else
						MessageText = NStr("vi = 'Thời hạn hiệu lực của thẻ ""%1"" có mã từ %2 vẫn chưa bắt đầu.';
											|ru = 'Срок действия карты ""%1"" с магнитным кодом %2 еще не наступил.';
											|en = 'Validity period of card ""%1"" with magnetic code %2 has not started yet.'; fa = 'Validity period of card ""%1"" with magnetic code %2 has not started yet.';
											|it = 'La validità della carta ""%1"" con il codice magnetico ""%2"" non è ancora arrivata.';
											|pl = 'Okres ważności karty ""%1"" z kodem magnetycznym%2 jeszcze się nie rozpoczął.';
											|tr = '%2 manyetik kodlu ""%1"" kartının süresi henüz dolmadı.'");
					EndIf;
				EndIf;
				
			Else
				
				If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
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
		
			If Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardReadingGroup Then
				Field = "CardCode";
			Else
				Field = StrTemplate("FoundLoyaltyCards[%1].Description", FoundLoyaltyCards.IndexOf(CurrentData));
			EndIf;
			
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, CardCode),
				,
				Field);
			
		EndIf;
		
	Else // The card is not registered.
		
		If CurrentData.AllowAutoRegistrationAtFirstReading Then
			
			If CurrentData.CardKindStatus = PredefinedValue("Enum.StatusesOfLoyaltyCardKinds.Valid")
				And CurrentData.ValidityStartDate <= Date
				And (Not ValueIsFilled(CurrentData.ValidityEndDate) Or EndOfDay(CurrentData.ValidityEndDate) >= Date) Then
			
				CurrentData.Ref = RegisterLoyaltyCard(CurrentData.CardKind, CurrentData.MagneticCode, CurrentData.Barcode);
				
				Close();
				
				Notify(
					"Write_LoyaltyCard",
					New Structure,
					CurrentData.Ref);
				
				Notify(
					"LoyaltyCardIsRead",
					New Structure("LoyaltyCard, OwnerForm", CurrentData.Ref, FormOwner.UUID),
					Undefined);
				
				ShowUserNotification(
					NStr("vi = 'Đã đọc thẻ khách hàng thân thiết';
						|ru = 'Считана карта лояльности';
						|en = 'Loyalty card is read'; fa = 'Loyalty card is read';
						|it = 'Carta fedeltà letta';
						|pl = 'Sczytana karta lojalnościowa';
						|tr = 'Sadakat kartı okundu'"),
					GetURL(CurrentData.Ref),
					StrTemplate(NStr("vi = 'Đã đọc thẻ khách hàng thân thiết %1';
									|ru = 'Считана карта лояльности %1';
									|en = 'Loyalty card %1 has been read'; fa = 'Loyalty card %1 has been read';
									|it = 'Carta fedeltà letta %1';
									|pl = 'Sczytana karta lojalnościowa %1';
									|tr = 'Sadakat kartı okundu %1'"), CurrentData.Ref),
					PictureLib.Information32);
				
			Else
				
				If CurrentData.CardKindStatus = PredefinedValue("Enum.StatusesOfLoyaltyCardKinds.Valid") Then
					
					If CurrentData.ValidityStartDate <= Date Then
						If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
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
						If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
							MessageText = NStr("vi = 'Thời hạn hiệu lực của thẻ ""%1"" có mã vạch %2 vẫn chưa bắt đầu.';
												|ru = 'Срок действия карты ""%1"" со штрихкодом %2 еще не наступил.';
												|en = 'Validity period of card ""%1"" with barcode %2 has not started yet.'; fa = 'Validity period of card ""%1"" with barcode %2 has not started yet.';
												|it = 'La validità della carta ""%1"" con il codice a barre ""%2"" non è ancora arrivata.';
												|pl = 'Okres ważności karty ""%1"" z kodem kreskowym %2 jeszcze się nie rozpoczął.';
												|tr = '%2 barkodlu ""%1"" kartının süresi henüz dolmadı.'");
						Else
							MessageText = NStr("vi = 'Thời hạn hiệu lực của thẻ ""%1"" có mã từ %2 vẫn chưa bắt đầu.';
												|ru = 'Срок действия карты ""%1"" с магнитным кодом %2 еще не наступил.';
												|en = 'Validity period of card ""%1"" with magnetic code %2 has not started yet.'; fa = 'Validity period of card ""%1"" with magnetic code %2 has not started yet.';
												|it = 'La validità della carta ""%1"" con il codice magnetico ""%2"" non è ancora arrivata.';
												|pl = 'Okres ważności karty ""%1"" z kodem magnetycznym%2 jeszcze się nie rozpoczął.';
												|tr = '%2 manyetik kodlu ""%1"" kartının süresi henüz dolmadı.'");
						EndIf;
					EndIf;
					
				Else
					
					If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
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
				
				If Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardReadingGroup Then
					Field = "CardCode";
				Else
					Field = StrTemplate("FoundLoyaltyCards[%1].Description", FoundLoyaltyCards.IndexOf(CurrentData));
				EndIf;
				
				CommonClientServer.MessageToUser(
					StrTemplate(MessageText, CurrentData.CardKind, CardCode),
					,
					Field);
				
			EndIf;
			
		Else
			
			If CodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
				MessageText = NStr("vi = 'Thẻ ""%1"" có mã vạch %2 chưa được ghi nhận. Thẻ dạng ""%1"" chỉ được ghi nhận bằng trợ giúp đăng ký thẻ khách hàng thân thiết';
									|ru = 'Карта ""%1"" со штрихкодом %2 не зарегистрирована. Карты вида ""%1"" регистрируются только с помощью помощника регистрации карт лояльности';
									|en = 'Card ""%1"" with barcode %2 is not registered yet. Cards of the ""%1"" kind are registered only using the loyalty card registration wizard'; fa = 'Card ""%1"" with barcode %2 is not registered yet. Cards of the ""%1"" kind are registered only using the loyalty card registration wizard';
									|it = 'La carta ""%1"" con il codice a barre %2 non è registrata. Le carte del tipo ""%1"" possono essere registrate solamente con l''aiuto dell''assistente di registrazione delle carte fedeltà';
									|pl = 'Karta ""%1"" z kodem kreskowym %2 nie jest zarejestrowana. Karty rodzaju ""%1"" są rejestrowane tylko przy pomocy asystenta rejestracji kart lojalnościowych';
									|tr = '%2 barkodlu ""%1"" kartı kayıtlı değil. ""%1"" gibi kartlar yalnızca sadakat kartı kayıt sihirbazına kaydedilir'");
			Else
				MessageText = NStr("vi = 'Thẻ ""%1"" có mã từ %2 chưa được ghi nhận. Thẻ có dạng ""%1"" chỉ được ghi nhận bằng trợ giúp ghi nhận thẻ khách hàng thân thiết';
									|ru = 'Карта ""%1"" с магнитным кодом %2 не зарегистрирована. Карты вида ""%1"" регистрируются только с помощью помощника регистрации карт лояльности';
									|en = 'Card ""%1"" with magnetic code %2 is not registered. The ""%1"" kind of cards are registered only using the loyalty card registration wizard'; fa = 'Card ""%1"" with magnetic code %2 is not registered. The ""%1"" kind of cards are registered only using the loyalty card registration wizard';
									|it = 'La carta ""%1"" con il codice magnetico %2 non è registrata. Le carte del tipo ""%1"" possono essere registrate solamente con l''aiuto dell''assistente di registrazione delle carte fedeltà';
									|pl = 'Karta ""%1"" z kodem magnetycznym %2 nie jest zarejestrowana. Karty rodzaju ""%1"" są rejestrowane tylko przy pomocy asystenta rejestracji kart lojalnościowych';
									|tr = '%2 manyetik kodlu ""%1"" kartı kayıtlı değil. ""%1"" gibi kartlar yalnızca sadakat kartı kayıt sihirbazına kaydedilir'");
			EndIf;
			
			If Items.Pages.CurrentPage = Items.Pages.ChildItems.LoyaltyCardReadingGroup Then
				Field = "CardCode";
			Else
				Field = StrTemplate("FoundLoyaltyCards[%1].Description", FoundLoyaltyCards.IndexOf(CurrentData));
			EndIf;
			
			CommonClientServer.MessageToUser(
				StrTemplate(MessageText, CurrentData.CardKind, CardCode),
				,
				Field);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessReceivedCodeOnClientInWaitProcessing()
	ProcessReceivedCodeOnClient(ReaderData, PredefinedValue("Enum.CardCodeTypes.MagneticCode"), True);
EndProcedure

&AtClient
Procedure NextIsWaitHandler()
	
	Next(Commands["Next"]);
	
EndProcedure

#EndRegion

#EndRegion
