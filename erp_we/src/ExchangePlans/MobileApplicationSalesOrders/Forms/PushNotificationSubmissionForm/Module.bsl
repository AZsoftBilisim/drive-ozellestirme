
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_SymbolsUsed", 1, False);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("PushNotificationText", PushNotificationText);
	Parameters.Property("RecipientsAreSpecified", RecipientsAreSpecified);
	NotificationRecipients = Undefined;
	If Parameters.Property("Recipients", NotificationRecipients) Then
		For Each Recipient In NotificationRecipients Do
			AddNotificationRecipient(Recipient);
		EndDo;
		ForDispatch = PushRecipients.FindRows(New Structure("RecipientIsSelected", True));
		If ForDispatch.Count() = 0 Then
			RecipientsAreSpecified = False;
		EndIf;
	EndIf;
	
	If RecipientsAreSpecified Then
		Items.PushNotificationText.Title = NStr("vi = 'Hãy nhập nội dung thông báo đẩy';
												|ru = 'Введите текст push-уведомления';
												|en = 'Enter push notification text'; fa = 'Enter push notification text';
												|it = 'Inserire testo notifiche push';
												|pl = 'Wpisz tekst powiadomienia push';
												|tr = 'Anlık bildirim metni girin'");
	Else
		Items.PushNotificationText.Title = NStr("vi = 'Bước 1/2. Nhập nội dung của thông báo đẩy';
												|ru = 'Шаг 1 из 2. Введите текст push-уведомления';
												|en = 'Step 1 of 2. Enter a push notification text'; fa = 'مرحله 1 از 2. متن اعلان پوش را وارد کنید';
												|it = 'Passaggio 1 di 2. Inserire il testo della notifica push';
												|pl = 'Krok 1 z 2. Wpisz tekst powiadomienia push';
												|tr = 'Adım 1 / 2. Anlık bildirim metnini girin'");
		If PushRecipients.Count() = 0 Then
			FillInNotificationRecipients();
		EndIf;
	EndIf;
	PushNotificationTextChangeText(ThisObject, PushNotificationText);
	Title = NStr("vi = 'Thông báo đẩy';
				|ru = 'Push - уведомление';
				|en = 'Push notification'; fa = 'Push notification';
				|it = 'Notifica push';
				|pl = 'Powiadomienie push';
				|tr = 'Anlık bildirim'");
	FormCommandHeaders();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_SymbolsUsed()
	
	PushNotificationTextChangeText(ThisObject, Items.PushNotificationText.EditText);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipients

&AtClient
Procedure RecipientsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Field.Name = "RecipientsRecipientIsSelected" Then
		StandardProcessing = False;
		CurrentData = Items.Recipients.CurrentData;
		If Not CurrentData = Undefined Then
			ShowValue(, CurrentData.Recipient);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure RecipientsRecipientIsSelectedOnChange(Item)
	
	If Not Item.Parent.CurrentData.SendingIsPossible And Item.Parent.CurrentData.RecipientIsSelected Then
		
		QuestionTitle = NStr("vi = 'Người nhận thông báo đẩy';
							|ru = 'Получатель push-уведомления';
							|en = 'Push notification recipient'; fa = 'Push notification recipient';
							|it = 'Destinatario notifica push';
							|pl = 'Odbiorca powiadomienia push';
							|tr = 'Anlık bildirim alıcısı'");
		QueryText = NStr("vi = 'Không thể gửi thông báo đẩy trên thiết bị này. Không có thông tin về định danh thiết bị.
			|Vẫn đưa thiết bị này vào danh sách nhận thông báo?';
			|ru = 'Отправка push-уведомления на данное устройство не возможна. Отсутствует информация об идентификаторе устройства.
			|Все равно включить это устройство в список получателей уведомления?';
			|en = 'Unable to send push notifications to this device. Device ID information is missing.
			|Add this device to the notification recipient list anyway?'; fa = 'Unable to send push notifications to this device. Device ID information is missing.
			|Add this device to the notification recipient list anyway?';
			|it = 'L''invio di notifiche push a questo dispositivo non è possibile. Non ci sono informazioni sull''ID del dispositivo.
			| Includere comunque questo dispositivo nell''elenco dei destinatari della notifica?';
			|pl = 'Wysyłanie powiadomień push do tego urządzenia nie jest możliwe. Brak jest informacji o identyfikatorze urządzenia.
			|Czy chcesz nadal włączyć to urządzenie do listy odbiorców powiadomienia?';
			|tr = 'Bu cihaza anlık bildirim göndermek mümkün değildir. Cihaz kimliği hakkında bilgi yok.
			| Bu cihaz yine de bildirim alıcı listesine dahil edilsin mi?'");
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Không đưa vào';
														|ru = 'Не включать';
														|en = 'Do not add'; fa = 'افزوده نشود';
														|it = 'Non includere';
														|pl = 'Nie włączaj';
														|tr = 'Etkinleştirme'"));
		ButtonsList.Add(DialogReturnCode.OK, NStr("vi = 'Đưa vào';
													|ru = 'Включить';
													|en = 'Add'; fa = 'افزودن';
													|it = 'Includere';
													|pl = 'Add';
													|tr = 'Etkinleştir'"));
		AdditionalParameters = New Structure("CurrentData", Item.Parent.CurrentData);
		CallbackDescription = New CallbackDescription("AfterAnsweringQuestionMark", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Fill(Command)
	
	FillInNotificationRecipients();
EndProcedure

&AtClient
Procedure Next(Command)
	
	NavigateThroughPages(Command);
EndProcedure

&AtClient
Procedure Back(Command)
	
	NavigateThroughPages(Command);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SelectOrClearAll(Command.Name);
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	SelectOrClearAll(Command.Name);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughPages(Command)
	
	If Items.Pages_Main.CurrentPage = Items.PageNotificationText Then
		If Command.Name = "Next" Then
			If RecipientsAreSpecified Then
				Success = False;
				SendNotification(Success);
				If Success Then
					Close();
				EndIf;
			Else
				Items.Pages_Main.CurrentPage = Items.PageNotificationRecipients;
				FormCommandHeaders();
			EndIf;
		EndIf;
	ElsIf Items.Pages_Main.CurrentPage = Items.PageNotificationRecipients Then
		If Command.Name = "Next" Then
			Success = False;
			SendNotification(Success);
			If Success Then
				Close();
			EndIf;
		ElsIf Command.Name = "Back" Then
			Items.Pages_Main.CurrentPage = Items.PageNotificationText;
			FormCommandHeaders();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure NavigateThroughPages(Command)

	Cancel = PageClickConditionsNotMet_(Command);
	
	If Not Cancel Then
		PerformNecessaryActionsWhenNavigatingThroughPages(Command)
	EndIf;
EndProcedure

&AtServer
Procedure AddNotificationRecipient(Recipient)
	
	If TypeOf(Recipient) = Type("ExchangePlanRef.MobileApplicationSalesOrders") Then
		UserStrings = PushRecipients.FindRows(New Structure("Recipient", Recipient));
		If UserStrings.Count()>0 Then
			Return;
		EndIf;
		RecipientRow = PushRecipients.Add();
		DetailsOfRecipient = Common.ObjectAttributesValues(Recipient, "Description, User");
		RecipientRow.Recipient = Recipient;
		RecipientRow.Device = DetailsOfRecipient.Description;
		RecipientRow.User = DetailsOfRecipient.User;
		RecipientRow.SendingIsPossible = MobileApplicationSalesOrders.SendingIsPossible(Recipient);
		RecipientRow.RecipientIsSelected = RecipientRow.SendingIsPossible;
	ElsIf TypeOf(Recipient) = Type("DynamicListGroupRow") Then
		NotificationRecipients = NotificationRecipients(Recipient.Key);
		If NotificationRecipients = Undefined Then
			Return;
		EndIf;
		While NotificationRecipients.Next() Do
			AddNotificationRecipient(NotificationRecipients);
		EndDo;
	Else
		UserStrings = PushRecipients.FindRows(New Structure("Recipient", Recipient.Recipient));
		If UserStrings.Count()>0 Then
			Return;
		EndIf;
		RecipientRow = PushRecipients.Add();
		FillPropertyValues(RecipientRow, Recipient);
		RecipientRow.SendingIsPossible = MobileApplicationSalesOrders.SendingIsPossible(RecipientRow.Recipient);
		RecipientRow.RecipientIsSelected = RecipientRow.SendingIsPossible;
	EndIf;
EndProcedure

&AtServer
Procedure FormCommandHeaders()
	
	If Items.Pages_Main.CurrentPage = Items.PageNotificationText Then
		If RecipientsAreSpecified Then
			Items.Next.Title = NStr("vi = 'Gửi';
									|ru = 'Отправить';
									|en = 'Send'; fa = 'ارسال';
									|it = 'Inviare';
									|pl = 'Send';
									|tr = 'Gönder'");
		Else
			Items.Next.Title = NStr("vi = 'Tiếp theo >>';
									|ru = 'Далее >>';
									|en = 'Next >>'; fa = 'بعدی >>';
									|it = 'Avanti >>';
									|pl = 'Dalej >>';
									|tr = 'İleri >>'");
		EndIf;
		Items.Back.Visible = False;
	ElsIf Items.Pages_Main.CurrentPage = Items.PageNotificationRecipients Then
		Items.Next.Title = NStr("vi = 'Gửi';
								|ru = 'Отправить';
								|en = 'Send'; fa = 'ارسال';
								|it = 'Inviare';
								|pl = 'Send';
								|tr = 'Gönder'");
		Items.Back.Visible = True;
	EndIf;
EndProcedure

&AtServer
Procedure FillInNotificationRecipients()
	
	PushRecipients.Clear();
	Recipients = NotificationRecipients("", False);
	If Not Recipients = Undefined Then
		While Recipients.Next() Do
			AddNotificationRecipient(Recipients);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure SendNotification(Success)
	
	SelectedRecipients = PushRecipients.FindRows(New Structure("RecipientIsSelected", True));
	Recipients = New Array;
	For Each Item In SelectedRecipients Do
		If Recipients.Find(Item.Recipient) = Undefined Then
			Recipients.Add(Item.Recipient);
		EndIf;
	EndDo;
	If Recipients.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Hãy chỉ ra người nhận thông báo đẩy';
												|ru = 'Укажите получателей push-уведомления';
												|en = 'Specify push-notification recipients'; fa = 'Specify push-notification recipients';
												|it = 'Indicare i destinatari delle notifiche push';
												|pl = 'Podaj odbiorców powiadomień push';
												|tr = 'Anlık bildirimin alıcılarını belirtin'"));
		Return;
	EndIf;
	RecipientsWithoutDelivery = New Array;
	MobileApplicationSalesOrders.SendNotification(PushNotificationText, Recipients, RecipientsWithoutDelivery);
	Success = True;
	If RecipientsWithoutDelivery.Count() > 0 Then
		Success = False;
		UserMessage = "";
		For Each RecipientWithoutDelivery In RecipientsWithoutDelivery Do
			MessageString = NStr("vi = 'Thông báo chưa được gửi đến thiết bị: %Device%';
								|ru = 'Уведомление не было отправлено на устройство: %Device%';
								|en = 'Notification was not sent to device: %Device%'; fa = 'Notification was not sent to device: %Device%';
								|it = 'La notifica non è stata inviata al dispositivo: %Device%';
								|pl = 'Powiadomienie nie zostało wysłane do urządzenia: %Device%';
								|tr = 'Cihaza bir bildirim gönderilmedi: %Device%'");
			MessageString = StrReplace(MessageString, "%Device%", TrimAll(RecipientWithoutDelivery));
			UserMessage = UserMessage + MessageString + Chars.LF;
		EndDo;
		CommonClientServer.MessageToUser(UserMessage);
	EndIf;
EndProcedure

&AtServer
Function NotificationRecipients(Recipient, UseRecipientSelection = True)
	
	NotificationRecipients = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT
	|	IntegrationWith1COrders.KindExchangeSettings AS KindExchangeSettings,
	|	COUNT(DISTINCT IntegrationWith1COrders.Ref) AS NumberOfItemsInGroup
	|INTO MessagingSettings
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS IntegrationWith1COrders
	|WHERE
	|	NOT IntegrationWith1COrders.KindExchangeSettings = VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|
	|GROUP BY
	|	IntegrationWith1COrders.KindExchangeSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MobileApplicationSalesOrders.Ref AS Recipient,
	|	MobileApplicationSalesOrders.User AS User,
	|	MobileApplicationSalesOrders.Description AS Device,
	|	CASE
	|		WHEN MobileApplicationSalesOrders.KindExchangeSettings = VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|			THEN CASE
	|					WHEN ISNULL(GroupSharingSettings.NumberOfItemsInGroup, 0) = 0
	|						THEN VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|					ELSE MobileApplicationSalesOrders.Ref
	|				END
	|		ELSE MobileApplicationSalesOrders.KindExchangeSettings
	|	END AS KindExchangeSettings
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|		LEFT JOIN MessagingSettings AS GroupSharingSettings
	|		ON (GroupSharingSettings.KindExchangeSettings = MobileApplicationSalesOrders.Ref)
	|WHERE
	|	NOT MobileApplicationSalesOrders.ThisNode
	|	AND CASE
	|			WHEN &UseRecipientSelection
	|				THEN CASE
	|						WHEN MobileApplicationSalesOrders.KindExchangeSettings = VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|							THEN CASE
	|									WHEN ISNULL(GroupSharingSettings.NumberOfItemsInGroup, 0) = 0
	|										THEN VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef) = &KindExchangeSettings
	|									ELSE MobileApplicationSalesOrders.Ref = &KindExchangeSettings
	|								END
	|						ELSE MobileApplicationSalesOrders.KindExchangeSettings = &KindExchangeSettings
	|					END
	|			ELSE TRUE
	|		END";
	
	If TypeOf(Recipient) = Type("String") Then
		KindExchangeSettings = ExchangePlans.MobileApplicationSalesOrders.EmptyRef();
	Else
		KindExchangeSettings = Recipient;
	EndIf;
	Query.SetParameter("KindExchangeSettings", KindExchangeSettings);
	Query.SetParameter("UseRecipientSelection", UseRecipientSelection);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return NotificationRecipients;
	EndIf;
	NotificationRecipients = Result.Select();
	
	Return NotificationRecipients;
EndFunction

&AtClient
Procedure AfterAnsweringQuestionMark(Val Result, Val AdditionalParameters) Export
	
	If Result = DialogReturnCode.Cancel Then
		AdditionalParameters.CurrentData.RecipientIsSelected = False;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure PushNotificationTextChangeText(Form, EditText)
	
	If Not Form.CharsCount = StrLen(EditText) Or Form.CharsCount = 0 Then
		
		Form.CharsCount = StrLen(EditText);
		DecorationTitleText = NStr("vi = '%Symbols% bao gồm 127 ký tự';
									|ru = '%Symbols% из 127 символов';
									|en = '%Symbols% out of 127 characters'; fa = '%Symbols% out of 127 characters';
									|it = '%Symbols% di 127 simboli';
									|pl = '%Symbols% z 127 znaków';
									|tr = '127 karakterden %Symbols%'");
		DecorationTitleText = StrReplace(DecorationTitleText, "%Symbols%", Form.CharsCount);
		Form.TextCharacters = DecorationTitleText;
	EndIf;
EndProcedure

&AtClient
Function PageClickConditionsNotMet_(Command)
	
	ClearMessages();
	
	If Items.Pages_Main.CurrentPage = Items.PageNotificationText Then
		If Not ValueIsFilled(PushNotificationText) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy nhập nội dung thông báo đẩy';
													|ru = 'Введите текст push-уведомления';
													|en = 'Enter push notification text'; fa = 'Enter push notification text';
													|it = 'Inserire testo notifiche push';
													|pl = 'Wpisz tekst powiadomienia push';
													|tr = 'Anlık bildirim metni girin'"),, "PushNotificationText", "PushNotificationText");
			Return True;
		EndIf;
	ElsIf Items.Pages_Main.CurrentPage = Items.PageNotificationRecipients Then
		If Not Command.Name = "Back" Then
			ForDispatch = PushRecipients.FindRows(New Structure("RecipientIsSelected", True));
			If ForDispatch.Count() = 0 Then
				CommonClientServer.MessageToUser(NStr("vi = 'Hãy chỉ ra người nhận thông báo đẩy';
														|ru = 'Укажите получателей push-уведомления';
														|en = 'Specify push-notification recipients'; fa = 'Specify push-notification recipients';
														|it = 'Indicare i destinatari delle notifiche push';
														|pl = 'Podaj odbiorców powiadomień push';
														|tr = 'Anlık bildirimin alıcılarını belirtin'"),, "Recipients", "PushRecipients");
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtClient
Procedure SelectOrClearAll(CommandName)
	
	For Each Addressee In PushRecipients Do
		If CommandName = "CheckAll" Then
			Addressee.RecipientIsSelected = True;
		Else
			Addressee.RecipientIsSelected = False;
		EndIf;
	EndDo;
EndProcedure

#EndRegion

