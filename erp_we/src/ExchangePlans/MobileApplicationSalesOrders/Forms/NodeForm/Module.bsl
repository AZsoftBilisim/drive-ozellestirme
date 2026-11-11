#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ExchangeSettings = Undefined;
	If Not ValueIsFilled(Object.Ref) Then
		Object.PrefixForMobileDeviceData = 
			MobileApplicationSalesOrdersOverridable.NewPrefixForMobileDeviceData();
		If Parameters.Property("KindExchangeSettings") Then
			Object.KindExchangeSettings = Parameters.KindExchangeSettings;
			UsingGeneralSettings = 1;
		EndIf;
		If Parameters.Property("User") Then
			Object.User = Parameters.User;
		EndIf;
		If Parameters.Property("ExchangeSettings") Then
			ExchangeSettings = Parameters.ExchangeSettings;
		EndIf;
		OnReadCreateAtServer(ExchangeSettings);
	EndIf;
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("ExchangePlanRef.MobileApplicationSalesOrders") Then
		Object.KindExchangeSettings = ValueSelected;
		KindExchangeSettingsOnChangeServer();
	EndIf;
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	MessageText = "";
	
	VerifyMobileAppUser(Cancel, MessageText);
	
	If Boolean(RegisterPaymentsByPaymentCards)
		And Not ValueIsFilled(POSTerminal) And Not UsingGeneralSettings = 1 Then
		MessageText =
			NStr("vi = 'Hãy chỉ ra thiết bị thanh toán thẻ để tạo chứng từ ""Giao dịch thẻ thanh toán"".';
				|ru = 'Укажите эквайринговый терминал для создания документов ""Эквайринговая операция"".';
				|en = 'Specify POS terminal for creation of documents ""Acquiring transaction"".'; fa = 'Specify POS terminal for creation of documents ""Acquiring transaction"".';
				|it = 'Specificare il terminale di acquisizione per la creazione di documenti ""Acquisizione operazione"".';
				|pl = 'Określ terminal płatniczy dla tworzenia dokumentów ""Operacja płatnicza"".';
				|tr = '""PoS İşlemi"" belgelerini oluşturmak için PoS terminalini belirtin.'");
		CommonClientServer.MessageToUser(
			MessageText, Object.Ref, "POSTerminal", "POSTerminal", Cancel);
	EndIf;
	
	If UseJobsToManageSalesRepresentatives
		And Not ValueIsFilled(Supervisor_) And Not UsingGeneralSettings = 1 Then
		MessageText =
			NStr("vi = 'Hãy chỉ ra người phụ trách của đại diện bán hàng.';
				|ru = 'Укажите куратора для торгового представителя.';
				|en = 'Specify a supervisor for the sales representative.'; fa = 'Specify a supervisor for the sales representative.';
				|it = 'Specificare il curatore per il rappresentante commerciale';
				|pl = 'Określ kuratora dla przedstawiciela handlowego.';
				|tr = 'Satış temsilcisi için bir süpervizör belirtin.'");
		CommonClientServer.MessageToUser(
			MessageText, Object.Ref, "Supervisor_", "Supervisor_", Cancel);
	EndIf;
	
	If Boolean(UseICOToRegisterPayment) And UseMultipleCashAccounts
		And Not ValueIsFilled(CashAccount) And Not UsingGeneralSettings = 1 Then
		MessageText =
			NStr("vi = 'Hãy chỉ ra quỹ tiền mặt để tạo chứng từ ""Phiếu thu"".';
				|ru = 'Укажите кассу для создания документов ""Приходный кассовый ордер"".';
				|en = 'Specify a cash account for creation of documents ""Incoming payment — Cash account"".'; fa = 'Specify a cash account for creation of documents ""Incoming payment — Cash account"".';
				|it = 'Specificare cassa per la creazione dei documenti ""Mandato di ricevimento di cassa"".';
				|pl = 'Podaj kasę, aby utworzyć dokumenty ""Pokwitowanie odbioru gotówki"".';
				|tr = '""Gelen ödeme - kasa hesabı"" belgelerini oluşturmak için kasiyer kasasını belirtin.'");
		CommonClientServer.MessageToUser(
			MessageText, Object.Ref, "CashAccount", "CashAccount", Cancel);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CompositionSetup = CurServerLayoutSettings();
	CurrentObject.ExchangeSettings = New ValueStorage(CompositionSetup, New Deflation(9));
	
	If ValueIsFilled(CurrentObject.Ref) And RegisterChangesForAllPartners Then
		ExchangeMessage = "";
		MobileApplicationSalesOrdersOverridable.RegisterCustomerChangesForExchangePlan(
			CurrentObject.Ref, True, "", Cancel, ExchangeMessage);
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Read();
EndProcedure

#EndRegion

#Region FormHeaderEventHandlers

&AtClient
Procedure KindExchangeSettingsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("Ref", Object.Ref);
	FormParameters.Insert("ChoiceMode", True);
	OpenForm("ExchangePlan.MobileApplicationSalesOrders.ChoiceForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure KindExchangeSettingsOnChange(Item)
	
	KindExchangeSettingsOnChangeServer();
EndProcedure

&AtClient
Procedure RemainingQuantityOnChange(Item)
	
	Modified = True;
	DoNotDisplayBalanceWhenSelecting = Not RemainingQuantity;
EndProcedure

&AtClient
Procedure UseWeightCharacteristicsOnChange(Item)
	
	Modified = True;
EndProcedure

&AtClient
Procedure UsingGeneralSettingsOnChange(Item)
	
	Modified = True;
	If UsingGeneralSettings = 0 And ValueIsFilled(Object.KindExchangeSettings) Then
		Object.KindExchangeSettings = "";
	EndIf;
	InitializeComposerServer();
EndProcedure

&AtClient
Procedure CashAccountOnChange(Item)
	
	Modified = True;
EndProcedure

&AtClient
Procedure Supervisor_OnChange(Item)
	
	Modified = True;
EndProcedure

&AtClient
Procedure TransmitProductImagesOnChange(Item)
	
	Modified = True;
EndProcedure

&AtClient
Procedure RegisterCashWhenChanging(Item)
	
	Modified = True;
	If Not Boolean(RegisterCashPayments) Then
		RegisterPaymentsByProxy = 0;
		UsePowerOfAttorneyToRegisterPayment = False;
		
		RegisterICOPayments = 0;
		CashAccount = "";
		ArticleDDSCash = "";
		UseICOToRegisterPayment = False;
	EndIf;
	SetVisibilityAvailability();
EndProcedure

&AtClient
Procedure RegisterICOPaymentsOnChange(Item)
	
	Modified = True;
	If Boolean(RegisterICOPayments) Then
		RegisterPaymentsByProxy = 0;
	EndIf;
	WhenChangingRegisterPayment();
EndProcedure

&AtClient
Procedure RegisterPaymentsByProxyOnChange(Item)
	
	Modified = True;
	If Boolean(RegisterPaymentsByProxy) Then
		CashAccount = "";
		ArticleDDSCash = "";
		RegisterICOPayments = 0;
	EndIf;
	WhenChangingRegisterPayment();
EndProcedure

&AtClient
Procedure RegisterPaymentsByPaymentCardsOnChange(Item)
	
	Modified = True;
	If Not Boolean(RegisterPaymentsByPaymentCards) Then
		POSTerminal = "";
		ArticleDDSAcquiring = "";
	EndIf;
	SetVisibilityAvailability();
EndProcedure

&AtClient
Procedure ExchangeStatusClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenLogBySettings();
EndProcedure

&AtClient
Procedure ExchangeStatusLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenLogBySettings();
EndProcedure

&AtClient
Procedure ArticleDDSCashOnChange(Item)
	
	Modified = True;
EndProcedure

&AtClient
Procedure ArticleDDSAcquiringOnChange(Item)
	
	Modified = True;
EndProcedure

&AtClient
Procedure CompositionSettingTableOnChange(Item)
	
	CurrentSetting = Items.CompositionSettingTable.CurrentData;
	If CurrentSetting = Undefined Then
		Return;
	EndIf;
	Modified = True;
	CurSettingSetting = CurrentSetting.Setting;
	If CurSettingSetting = NStr("vi = 'Phân khúc bạn hàng';
								|ru = 'Сегмент партнеров';
								|en = 'Partner segment'; fa = 'بخش شریک';
								|it = 'Il segmento dei partner';
								|pl = 'Segment partnerów';
								|tr = 'İş ortağı segmenti'")
		Or CurSettingSetting = NStr("vi = 'Doanh nghiệp';
									|ru = 'Организация';
									|en = 'Company'; fa = 'Company';
									|it = 'Azienda';
									|pl = 'Firma';
									|tr = 'İş yeri'")
		Or CurSettingSetting = NStr("vi = 'Thỏa thuận';
									|ru = 'Соглашение';
									|en = 'Agreement'; fa = 'توافق‌نامه';
									|it = 'Accordo';
									|pl = 'Porozumienie';
									|tr = 'Anlaşma'") Then
		RegisterChangesForAllPartners = True;
	EndIf;
EndProcedure

&AtClient
Procedure POSTerminalOnChange(Item)
	
	Modified = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UnbindDevice(Command)
	
	DetachDeviceOnServer();
EndProcedure

&AtClient
Procedure ExchangeDefaultSettings(Command)
	
	Modified = True;
	DownloadStandardSettings();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure KindExchangeSettingsOnChangeServer()
	
	If Not ValueIsFilled(Object.KindExchangeSettings) Then
		UsingGeneralSettings = 0;
	Else
		UsingGeneralSettings = 1;
	EndIf;
	InitializeComposerServer();
EndProcedure

&AtServer
Procedure AvailabilityOfGeneralSettings()
	
	SettingsAreUsed = SettingsAreUsed(Object.Ref);
	Items.GroupCommentDeviceUsage.Visible = SettingsAreUsed;
	Items.UsingGeneralSettings.Enabled = Not SettingsAreUsed;
	
	If UsingGeneralSettings = 1 Then
		Items.SettingsUsePages.CurrentPage = Items.PageOfUnchangeableSettings;
		Items.KindExchangeSettings.Enabled = Not SettingsAreUsed;
	Else
		Items.SettingsUsePages.CurrentPage = Items.EditableSettingsPage;
		Items.KindExchangeSettings.Enabled = False;
	EndIf;
EndProcedure

&AtServer
Procedure DownloadStandardSettings()
	
	InitializeComposerServer(, True);
EndProcedure

// Parameters:
//  ExchangeSettings - ValueStorage
//  InitialSettings1 - Boolean
//
&AtServer
Procedure InitializeComposerServer(ExchangeSettings = Undefined, InitialSettings1 = False)
	
	If ExchangeSettings = Undefined Then
		If InitialSettings1 Then
			CompositionSetup = Undefined;
		Else
			CompositionSetup = Undefined;
			If Not ValueIsFilled(Object.KindExchangeSettings) Then
				LayoutSettingsRepository = Common.ObjectAttributeValue(Object.Ref, "ExchangeSettings");
				If LayoutSettingsRepository <> Undefined Then
					CompositionSetup = LayoutSettingsRepository.Get();
				EndIf;
			Else
				LayoutSettingsRepository = Common.ObjectAttributeValue(Object.KindExchangeSettings, "ExchangeSettings");
				If LayoutSettingsRepository <> Undefined Then
					CompositionSetup = LayoutSettingsRepository.Get();
				EndIf;
			EndIf;
		EndIf;
	Else
		CompositionSetup = ExchangeSettings.Get();
	EndIf;
	MobileApplicationSalesOrders.FillInComposerSettings(DataCompositionSettingsComposer,
		ExchangePlans.MobileApplicationSalesOrders,, CompositionSetup);
	MatchesOfSelectionElements =
		ExchangePlans.MobileApplicationSalesOrders.MatchingSelectionElementsToFunctionalOptions();
	MobileApplicationSalesOrders.SetComposerSelectionsToCollectionProps(
		ThisForm, DataCompositionSettingsComposer, MatchesOfSelectionElements,
			ExchangePlans.MobileApplicationSalesOrders.FormHeaderDetails());
	If ValueIsFilled(Object.User) Then
		VerifyMobileAppUser();
	EndIf;
	DrawForm();
EndProcedure

&AtServer
Function SettingsAreUsed(KindExchangeSettings)
	
	Query = New Query("SELECT
	|	MobileApplicationSalesOrders.Ref
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	NOT MobileApplicationSalesOrders.ThisNode
	|	AND MobileApplicationSalesOrders.KindExchangeSettings = &KindExchangeSettings");
	Query.SetParameter("KindExchangeSettings", KindExchangeSettings);
	Result = Query.Execute();
	Return Not Result.IsEmpty();
EndFunction

&AtServer
Procedure DetachDeviceOnServer()
	
	Object.Code = TrimAll(Object.User.UUID());
	MobileApplicationSalesOrders.ClearExchangeHistory(Object.Ref);
	DataExchangeState();
	SetVisibilityAvailability();
EndProcedure

&AtClient
Procedure OpenLogBySettings()
	
	FormParameters = New Structure("User", Object.User);
	ApplicationName = New Array;
	ApplicationName.Add("WSConnection");
	FormParameters.Insert("ApplicationName", ApplicationName);
	FormParameters.Insert("StartDate", ExchangeDate);
	FormParameters.Insert("EndDate", ExchangeDate);
	EventLogClient.OpenEventLog(FormParameters, ThisForm);
EndProcedure

&AtServer
Procedure DrawForm()
	
	RegisterPaymentsByPaymentCards = Number(ValueIsFilled(POSTerminal));
	RegisterPaymentsByProxy = Number(UsePowerOfAttorneyToRegisterPayment);
	RegisterICOPayments = Number(UseICOToRegisterPayment);
	RegisterCashPayments = Not (RegisterPaymentsByProxy + RegisterICOPayments = 0);
	RemainingQuantity = Not DoNotDisplayBalanceWhenSelecting;
	
	SetVisibilityAvailability();
EndProcedure

&AtServer
Procedure WhenChangingRegisterPayment()
	
	UsePowerOfAttorneyToRegisterPayment = Boolean(RegisterPaymentsByProxy);
	UseICOToRegisterPayment = Boolean(RegisterICOPayments);
	SetVisibilityAvailability();
EndProcedure

&AtServer
Procedure OnReadCreateAtServer(ExchangeSettings = Undefined)
	
	Title = NStr("vi = 'Tùy chỉnh đồng bộ với thiết bị';
				|ru = 'Настройка синхронизации с устройством';
				|en = 'Set up synchronization with device'; fa = 'Set up synchronization with device';
				|it = 'Impostazione di sincronizzazione con il dispositivo';
				|pl = 'Konfigurowanie urządzenia do synchronizacji';
				|tr = 'Cihaz ile senkronizasyonun ayarlanması'");
	If Not ValueIsFilled(Object.KindExchangeSettings) Then
		UsingGeneralSettings = 0;
	Else
		UsingGeneralSettings = 1;
	EndIf;
	DataExchangeState();
	InitializeComposerServer(ExchangeSettings);
EndProcedure

&AtServer
Procedure VerifyMobileAppUser(Cancel = False, MessageText = "")
	
	UserVerification =
		MobileApplicationSalesOrdersOverridable.MobileAppUserVerification(Object.User);
	
	If Not UserVerification.MobileAppUser Then
		MessageText = MessageText
		+ NStr("vi = 'Người sử dụng không thuộc nhóm người sử dụng ứng dụng di động.';
				|ru = 'Пользователь не входит в группу пользователей мобильного приложения.';
				|en = 'The user is not included in the group of mobile application users.'; fa = 'The user is not included in the group of mobile application users.';
				|it = 'L''utente non rientra nel gruppo utenti dell''app mobile.';
				|pl = 'Użytkownik nie jest wpisany do grupy użytkowników aplikacji mobilnej.';
				|tr = 'Kullanıcı, mobil uygulamanın kullanıcı grubunun bir parçası değildir.'") + Chars.LF;
		Cancel = True;
	EndIf;
	If UseICOToRegisterPayment And Not UserVerification.CashAccount Then
		MessageText = MessageText
		+ NStr("vi = 'Người sử dụng không đủ quyền để tạo chứng từ ""Phiếu thu"".';
				|ru = 'У пользователя недостаточно прав для создания документов ""Приходный кассовый ордер"".';
				|en = 'User has insufficient rights to create documents ""Incoming payment — Cash account"".'; fa = 'User has insufficient rights to create documents ""Incoming payment — Cash account"".';
				|it = 'L''utente non ha i diritti per la creazione dei documenti ""Mandato di ricevimento di cassa"".';
				|pl = 'Użytkownik ma niewystarczające uprawnienia do tworzenia dokumentów ""Pokwitowanie odbioru gotówki"".';
				|tr = 'Kullanıcı, ""Gelen ödeme - kasa hesabı"" belgesi oluşturmak için yeterli haklara sahip değil.'") + Chars.LF;
		Cancel = True;
	EndIf;
	If ValueIsFilled(POSTerminal) And Not UserVerification.PaymentCard Then
		MessageText = MessageText
		+ NStr("vi = 'Người sử dụng không đủ quyền để tạo chứng từ ""Giao dịch thẻ thanh toán"".';
				|ru = 'У пользователя недостаточно прав для создания документов ""Эквайринговая операция"".';
				|en = 'User has insufficient rights to create documents ""Acquiring transaction"".'; fa = 'User has insufficient rights to create documents ""Acquiring transaction"".';
				|it = 'L''utente non ha i diritti per la creazione dei documenti ""Operazione di acquisizione""';
				|pl = 'Użytkownik ma niewystarczające uprawnienia do tworzenia dokumentów ""Operacja płatnicza"".';
				|tr = 'Kullanıcı ""PoS İşlemi"" belgelerini oluşturmak için yeterli haklara sahip değil.'");
		Cancel = True;
	EndIf;
	If Cancel Then
		CommonClientServer.MessageToUser(
			MessageText, Object.Ref, "User", "User", Cancel);
	EndIf;
EndProcedure

&AtServer
Procedure DataExchangeState()
	
	If Not ValueIsFilled(Object.Ref) Then
		ExchangeStatus = 0;
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	MAX(DataExchangesStates.EndDate) AS EndDate
	|INTO DataExchangeStatesMaxDate
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|WHERE
	|	DataExchangesStates.InfobaseNode = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	DataExchangesStates.ExchangeExecutionResult AS ExchangeExecutionResult,
	|	DataExchangesStates.EndDate AS EndDate
	|INTO ExchangeExecutionResults
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|		INNER JOIN DataExchangeStatesMaxDate AS DataExchangeStatesMaxDate
	|		ON (DataExchangeStatesMaxDate.EndDate = DataExchangesStates.EndDate)
	|WHERE
	|	DataExchangesStates.InfobaseNode = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN DataExchangesStates.ExchangeExecutionResult IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|					THEN 1
	|				ELSE 2
	|			END
	|	END AS ExchangeStatus,
	|	ISNULL(DataExchangesStates.EndDate, DATETIME(1, 1, 1)) AS ExchangeDate
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|		LEFT JOIN ExchangeExecutionResults AS DataExchangesStates
	|		ON MobileApplicationSalesOrders.Ref = DataExchangesStates.InfobaseNode
	|WHERE
	|	MobileApplicationSalesOrders.Ref = &Ref";
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Query.Text = StrReplace(Query.Text, "InformationRegister.DataExchangesStates",
			"InformationRegister.DataAreaDataExchangeStates");
	EndIf;
		
	Query.SetParameter("Ref", Object.Ref);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		ExchangeStatus = 0;
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	ExchangeStatus = Selection.ExchangeStatus;
	ExchangeDate = Selection.ExchangeDate;
EndProcedure

&AtServer
Function CurServerLayoutSettings()
	
	MobileApplicationSalesOrders.SetFormPropsToComposerSelections_(ThisForm,
		DataCompositionSettingsComposer, ExchangePlans.MobileApplicationSalesOrders);
	Return DataCompositionSettingsComposer.GetSettings();
EndFunction

&AtServer
Procedure SetVisibilityAvailability()
	
	IsNew = Not ValueIsFilled(Object.Ref);
	
	Items.Supervisor_.AutoMarkIncomplete = UseJobsToManageSalesRepresentatives And Not UsingGeneralSettings = 1;
	Items.Supervisor_.Visible = Not UsingGeneralSettings = 1;
	
	Items.PaymentCardsGroup.Visible = UsePaymentByCards;
	Items.POSTerminal.Enabled = Boolean(RegisterPaymentsByPaymentCards);
	Items.POSTerminal.AutoMarkIncomplete = UsePaymentByCards 
		And Boolean(RegisterPaymentsByPaymentCards) And Not UsingGeneralSettings = 1;
	Items.POSTerminal.MarkIncomplete = ValueIsFilled(POSTerminal);
	Items.ArticleDDSAcquiring.Enabled = Boolean(RegisterPaymentsByPaymentCards);
	
	Items.RegisterPaymentsByProxy.Enabled = Boolean(RegisterCashPayments)
		And UseAuthorizationLettersForInventoryReceipt;
	Items.GroupCommentPaymentByProxy.Visible = Not UseAuthorizationLettersForInventoryReceipt;
	
	Items.RegisterICOPayments.Enabled = Boolean(RegisterCashPayments);
	Items.CashAccount.Visible = UseMultipleCashAccounts;
	Items.CashAccount.Enabled = Boolean(RegisterCashPayments) And Boolean(RegisterICOPayments);
	Items.CashAccount.AutoMarkIncomplete = Boolean(RegisterCashPayments) And Boolean(RegisterICOPayments) And Not UsingGeneralSettings = 1;
	Items.CashAccount.MarkIncomplete = ValueIsFilled(CashAccount);
	Items.ArticleDDSCash.Enabled = Boolean(RegisterCashPayments) And Boolean(RegisterICOPayments);
	
	VisibilityOfSelectionTable = DataCompositionSettingsComposer.UserSettings.Items.Count()>0;
	Items.GroupFilters.Visible = VisibilityOfSelectionTable;
	
	Items.FormUnbindDevice.Visible = Not IsNew;
	
	AvailabilityOfGeneralSettings();
	
	If ExchangeStatus = 0 Then
		ExchangeStatusLabel = NStr("vi = 'Đang chờ lần đồng bộ dữ liệu đầu tiên';
									|ru = 'Ожидается первая синхронизация данных';
									|en = 'The first data synchronization pending'; fa = 'The first data synchronization pending';
									|it = 'Si attende la prima sincronizzazione dati';
									|pl = 'Oczekiwano pierwszej synchronizacji danych';
									|tr = 'İlk veri senkronizasyonu bekleniyor'");
	ElsIf ExchangeStatus = 1 Then
		ExchangeStatusLabel = NStr("vi = 'Đã hoàn thành đồng bộ vào %ExchangeDate%';
									|ru = 'Синхронизация успешно завершена в %ExchangeDate%';
									|en = 'Synchronization is successfully completed on %ExchangeDate%'; fa = 'Synchronization is successfully completed on %ExchangeDate%';
									|it = 'La sincronizzazione è stata effettuata con successo su %ExchangeDate%';
									|pl = 'Synchronizacja została pomyślnie zakończona dnia %ExchangeDate%';
									|tr = '%ExchangeDate% senkronizasyon başarıyla tamamlandı'");
	ElsIf ExchangeStatus = 2 Then
		ExchangeStatusLabel = NStr("vi = 'Đã kết thúc đồng bộ bị lỗi trong %ExchangeDate%';
									|ru = 'Синхронизация завершена с ошибками в %ExchangeDate%';
									|en = 'Synchronization is completed with errors on %ExchangeDate%'; fa = 'Synchronization is completed with errors on %ExchangeDate%';
									|it = 'La sincronizzazione ha incontrato dei problemi su %ExchangeDate%';
									|pl = 'Synchronizacja została zakończona z błędami dnia %ExchangeDate%';
									|tr = '%ExchangeDate% senkronizasyon hatalarla tamamlandı'");
	EndIf;
	ExchangeStatusLabel = StrReplace(ExchangeStatusLabel, "%ExchangeDate%", Format(ExchangeDate, "DLF=DT"));
	Items.ExchangeStatus.Visible = Not IsNew;
	Items.ExchangeStatusLabel.Visible = Not IsNew;
	Items.Decoration2.Visible = Not IsNew;
	Items.ExchangeStatus.Hyperlink = Not ExchangeStatus = 0;
	Items.ExchangeStatusLabel.Hyperlink = Not ExchangeStatus = 0;
EndProcedure

#EndRegion