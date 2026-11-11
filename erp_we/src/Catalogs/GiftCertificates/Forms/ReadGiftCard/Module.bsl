
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

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	MainCodeType = GiftCertificatesServer.GetBasicTypeOfGiftCertificateCode();
	
	If Not Parameters.Property("Filter", FilterStructure1) Or FilterStructure1 = Undefined Then
		FilterStructure1 = New Structure;	
	EndIf;
	
	If Not Parameters.Property("RegisterNewOnes", RegisterNewOnes) Then
		RegisterNewOnes = False;
	EndIf;
	
	If RegisterNewOnes And FilterStructure1.Property("Organization") Then
		If TypeOf(FilterStructure1.Organization) = Type("Array") And FilterStructure1.Organization.Count() > 1 Then
			Items.FoundGiftCertificatesOrganization.Visible = True;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Parameters.CardCode) Then
		
		// When reading in the form of a list, several cards with this code were found,
		// it is required to offer cards to the user to choose from.
		If Parameters.CodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			If TypeOf(Parameters.CardCode) = Type("Array") Then
				Text = NStr("vi = 'Đã tìm thấy nhiều phiếu quà tặng tương ứng với một mã từ đã đọc.
				                   |Hãy chọn thẻ phù hợp.';
				                   |ru = 'Обнаружено несколько подарочных сертификатов, соответствующих считанному магнитному коду.
				                   |Выберите подходящую карту.';
				                   |en = 'Several gift cards which correspond to the scanned magnetic code are detected.
				                   |Select a card.'; fa = 'Several gift cards which correspond to the scanned magnetic code are detected.
				                   |Select a card.';
				                   |it = 'Rilevati alcuni buoni regalo che corrispondono al codice magnetico letto.
				                   |Selezionare la carta appropriata.';
				                   |pl = 'Wykryto kilka certyfikatów podarunkowych, odpowiadających sczytanemu kodowi magnetycznemu.
				                   |Wybierz odpowiednią kartę.';
				                   |tr = 'Okunan manyetik kodla eşleşen bir dizi hediye kuponu bulundu.
				                   | Uygun kartı seçin.'");
			Else
				Text = NStr("vi = 'Đã tìm thấy nhiều phiếu quà tặng có mã từ %1.
				                   |Hãy chọn thẻ phù hợp.';
				                   |ru = 'Обнаружено несколько подарочных сертификатов с магнитным кодом %1.
				                   |Выберите подходящую карту.';
				                   |en = 'Several gift cards with magnetic code %1 are detected.
				                   |Select a card.'; fa = 'Several gift cards with magnetic code %1 are detected.
				                   |Select a card.';
				                   |it = 'Rilevati alcuni buoni regalo con il codice magnetico %1.
				                   |Selezionare la carta appropriata.';
				                   |pl = 'Wykryto kilka certyfikatów podarunkowych z kodem magnetycznym %1.
				                   |Wybierz odpowiednią kartę.';
				                   |tr = 'Okunan manyetik kodla eşleşen bir dizi hediye kuponu bulundu%1. 
				                   | Uygun kartı seçin.'");
			EndIf;
		Else
			Text = NStr("vi = 'Đã tìm thấy nhiều phiếu quà tặng có mã vạch %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько подарочных сертификатов со штрихкодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several gift cards with barcode %1 are detected.
			                   |Select a card.'; fa = 'Several gift cards with barcode %1 are detected.
			                   |Select a card.';
			                   |it = 'Rilevati alcuni buoni regalo con il codice a barre %1.
			                   |Selezionate la carta appropriata.';
			                   |pl = 'Wykryto kilka certyfikatów podarunkowych z kodem kreskowym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Okunan barkodla eşleşen bir dizi hediye kuponu bulundu%1.
			                   | Uygun kartı seçin.'");
		EndIf;
		CaptionChoosingAGiftCertificate = StringFunctionsClientServer.SubstituteParametersToString(Text, Parameters.CardCode);
		
		FillInFoundGiftCertificatesAtServer(Parameters.CardCode, Parameters.CodeType);
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.GiftCertificateSelectionGroup;
		
	Else
		
		If ValueIsFilled(MainCodeType) Then
			CodeType = MainCodeType;
			Items.CodeType.Visible = False;
		Else
			CodeType = Enums.CardCodeTypes.Barcode;
		EndIf;
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAGiftCertificate;
		
	EndIf;
	
	Items.BackButtonPages.CurrentPage = Items.BackButtonPages.ChildItems.TheBackButtonIsMissing;
	Items.NextButtonPages.CurrentPage = Items.NextButtonPages.ChildItems.ConfirmButton;
	
	If Not ValueIsFilled(MainCodeType) Then
		Text = NStr("vi = 'Hãy đọc phiếu quà tặng bằng máy quét mã vạch
		                   |(đầu đọc thẻ từ) hoặc nhập thủ công mã';
		                   |ru = 'Считайте подарочный сертификат при помощи сканера штрихкода
		                   |(считывателя магнитных карт) или введите код вручную';
		                   |en = 'Read a gift card using the barcode scanner
		                   |(magnetic stripe card reader) or enter the barcode manually'; fa = 'Read a gift card using the barcode scanner
		                   |(magnetic stripe card reader) or enter the barcode manually';
		                   |it = 'Leggere il nuovo buoni regalo usando un lettore di codici a barre
		                   |(lettore di carte magnetiche) oppure inserire il codice manualmente';
		                   |pl = 'Sczytaj certyfikat podarunkowy przy pomocy skanera kodów kreskowych
		                   |(czytnika kart magnetycznych) lub wprowadź kod ręcznie';
		                   |tr = 'Hediye kartını bir barkod tarayıcı
		                   | (manyetik kart okuyucu) kullanarak okutun veya kodu manuel olarak girin'");
	ElsIf MainCodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
		Text = NStr("vi = 'Hãy đọc phiếu quà tặng thông qua đầu đọc
		                   |thẻ từ hoặc nhập mã từ thủ công';
		                   |ru = 'Считайте подарочный сертификат при помощи считывателя
		                   |магнитных карт или введите магнитный код вручную';
		                   |en = 'Read a gift card using the
		                   |magnetic stripe card reader or enter the magnetic code manually'; fa = 'Read a gift card using the
		                   |magnetic stripe card reader or enter the magnetic code manually';
		                   |it = 'Leggere il buono regalo usando un lettore
		                   |di carte magnetiche oppure inserite il codice magnetico manualmente';
		                   |pl = 'Sczytaj certyfikat podarunkowy przy pomocy
		                   |czytnika kart magnetycznych lub wprowadź kod magnetyczny ręcznie';
		                   |tr = 'Hediye kartını bir manyetik kart okuyucu kullanarak
		                   | okutun veya manyetik kodu manuel olarak girin'");
	ElsIf MainCodeType = PredefinedValue("Enum.CardCodeTypes.Barcode") Then
		Text = NStr("vi = 'Hãy đọc phiếu quà tặng bằng quáy quét
		                   |mã vạch hoặc nhập thủ công mã vạch';
		                   |ru = 'Считайте подарочный сертификат при помощи сканера
		                   |штрихкода или введите штрихкод вручную';
		                   |en = 'Read a gift card using the barcode
		                   |scanner or enter the barcode manually'; fa = 'Read a gift card using the barcode
		                   |scanner or enter the barcode manually';
		                   |it = 'Leggere il buono regalo usando un lettore di codici
		                   |a barre oppure inserite il codice manualmente';
		                   |pl = 'Sczytaj certyfikat podarunkowy przy pomocy skanera
		                   |kodów kreskowych lub wprowadź kod kreskowy ręcznie';
		                   |tr = 'Hediye kartını bir barkod tarayıcı 
		                   |kullanarak okutun veya kodu manuel olarak girin'");
	EndIf;
	TheInscriptionReadingAGiftCertificate = Text;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PageStack = New Array;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner,MagneticStripeCardReaders");

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
Procedure FoundGiftCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
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
	
	If Items.Pages.CurrentPage = Items.Pages.ChildItems.GroupReadingAGiftCertificate Then
		
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
			
			CommonClient.MessageToUser(
				MessageText,
				,
				"CardCode");
			
			Return;
			
		EndIf;
		
		ProcessReceivedCodeOnClient(CardCode, CodeType);
		
	ElsIf Items.Pages.CurrentPage = Items.Pages.ChildItems.GiftCertificateSelectionGroup Then
		
		CurrentData = Items.FoundGiftCertificates.CurrentData;
		If CurrentData <> Undefined Then
			ProcessGiftCertificateSelection(CurrentData);
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
	ItemField.Field = New DataCompositionField(Items.FoundGiftCertificates.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FoundGiftCertificates.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FoundGiftCertificates.AllowAutoRegistrationAtFirstReading");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", New Color());
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If Items.Pages.CurrentPage <> Items.Pages.ChildItems.GroupReadingAGiftCertificate Then
		Return;
	EndIf;
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	ProcessReceivedCodeOnClient(ArrayOfBarcodes[0].Barcode, PredefinedValue("Enum.CardCodeTypes.Barcode"));
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	If Items.Pages.CurrentPage <> Items.Pages.ChildItems.GroupReadingAGiftCertificate Then
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
	
	If Page = Items.Pages.ChildItems.GiftCertificateSelectionGroup Then
		If CodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode") Then
			Text = NStr("vi = 'Đã tìm thấy nhiều phiếu quà tặng có mã từ %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько подарочных сертификатов с магнитным кодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several gift cards with magnetic code %1 are detected.
			                   |Select a card.'; fa = 'Several gift cards with magnetic code %1 are detected.
			                   |Select a card.';
			                   |it = 'Rilevati alcuni buoni regalo con il codice magnetico %1.
			                   |Selezionare la carta appropriata.';
			                   |pl = 'Wykryto kilka certyfikatów podarunkowych z kodem magnetycznym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Okunan manyetik kodla eşleşen bir dizi hediye kuponu bulundu%1.
			                   |Uygun kartı seçin.'");
		Else
			Text = NStr("vi = 'Đã tìm thấy nhiều phiếu quà tặng có mã vạch %1.
			                   |Hãy chọn thẻ phù hợp.';
			                   |ru = 'Обнаружено несколько подарочных сертификатов со штрихкодом %1.
			                   |Выберите подходящую карту.';
			                   |en = 'Several gift cards with barcode %1 are detected.
			                   |Select a card.'; fa = 'Several gift cards with barcode %1 are detected.
			                   |Select a card.';
			                   |it = 'Rilevati alcuni buoni regalo con il codice a barre %1.
			                   |Selezionate la carta appropriata.';
			                   |pl = 'Wykryto kilka certyfikatów podarunkowych z kodem kreskowym %1.
			                   |Wybierz odpowiednią kartę.';
			                   |tr = 'Okunan barkodla eşleşen bir dizi hediye kuponu bulundu%1.
			                   | Uygun kartı seçin.'");
		EndIf;
		CaptionChoosingAGiftCertificate = StringFunctionsClientServer.SubstituteParametersToString(Text, CardCode);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessReceivedCodeOnClient(Data, ReceivedCodeType)
	
	FillInFoundGiftCertificatesAtServer(Data, ReceivedCodeType);
	
	If FoundGiftCertificates.Count() = 0 Then
		GiftCertificatesClient.InformUserThatGiftCertificateWasNotFound(CardCode, CodeType, FilterStructure1);
		Return;
	ElsIf FoundGiftCertificates.Count() > 1 Then
		GoToPage3(Items.Pages.ChildItems.GiftCertificateSelectionGroup);
		Text = NStr("vi = 'Đã tìm thấy nhiều phiếu quà tặng có mã %1.
		                   |Hãy chọn phiếu quà tặng phù hợp.';
		                   |ru = 'Обнаружено несколько подарочных сертификатов с кодом %1.
		                   |Выберите подходящий подарочный сертификат.';
		                   |en = 'Several gift cards with code %1 are detected.
		                   |Select a card.'; fa = 'Several gift cards with code %1 are detected.
		                   |Select a card.';
		                   |it = 'Rilevati alcuni buoni regalo con il codice %1.
		                   |Selezionare il buono regalo appropriato.';
		                   |pl = 'Wykryto kilka certyfikatów podarunkowych z kodem %1.
		                   |Wybierz odpowiedni certyfikat podarunkowy.';
		                   |tr = 'Okunan kodla eşleşen bir dizi hediye kartı bulundu%1.
		                   | Uygun hediye kartını seçin.'");
		CaptionChoosingAGiftCertificate = StringFunctionsClientServer.SubstituteParametersToString(Text, CardCode);
	ElsIf FoundGiftCertificates.Count() = 1 Then
		ProcessGiftCertificateSelection(FoundGiftCertificates[0]);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInFoundGiftCertificatesAtServer(Data, ReceivedCodeType)
	
	FoundGiftCertificates.Clear();
	
	If GiftCertificatesClientServer.DataPreprocessingIsRequired(Data, ReceivedCodeType)
		And TypeOf(Data) = Type("Array") Then
		CardCode = Data[0];
	Else
		CardCode = Data;
	EndIf;
	
	AdditionalParameters = GiftCertificatesServerCall.ParametersForProcessingReceivedCode();
	AdditionalParameters.Filters = FilterStructure1;
	AdditionalParameters.RegisterNewOnes = RegisterNewOnes;
	
	Result = GiftCertificatesServerCall.ProcessReceivedCodeOnServer(Data, ReceivedCodeType, AdditionalParameters);
	For Each TSRow In Result Do
		FillPropertyValues(FoundGiftCertificates.Add(), TSRow);
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessGiftCertificateSelection(CurrentData)
	
	GiftCertificatesClient.ProcessGiftCertificateSelection(FormOwner, CurrentData, CodeType, RegisterNewOnes, False);
	If ValueIsFilled(CurrentData.Ref) Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessReceivedCodeOnClientInWaitProcessing()
	ProcessReceivedCodeOnClient(ReaderData, PredefinedValue("Enum.CardCodeTypes.MagneticCode"));
EndProcedure

&AtClient
Procedure NextIsWaitHandler()
	
	Next(Commands["Next"]);
	
EndProcedure

#EndRegion

#EndRegion
