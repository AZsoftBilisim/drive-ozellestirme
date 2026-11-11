///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var FormClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationDetails = Undefined;
	
	If Parameters.Id <> Undefined Then
	
		IntegrationDetails = CollaborationSystem.GetIntegration(Parameters.Id);
		If IntegrationDetails <> Undefined Then
			
			Description = IntegrationDetails.Presentation;
			EndpointURL = IntegrationDetails.EndpointURL;
			
			Attendees.Clear();
			For Each IBUser In Conversations.InfoBaseUsers(IntegrationDetails.Members) Do
				Attendees.Add().User = IBUser.Value;
			EndDo;
				
			IsIntegrationUsed = IntegrationDetails.Use;
			If IsIntegrationUsed Then
				Items.Close.Title = NStr("vi = 'Ghi lại và đóng';
										|ru = 'Записать и закрыть';
										|en = 'Save and close'; fa = 'ذخیره و بستن';
										|it = 'Salvare e chiudere';
										|pl = 'Zapisz i zamknij';
										|tr = 'Kaydet ve kapat'");
				Items.Disconnect.Visible = True;
			EndIf;

		EndIf;
		
	EndIf;
	
	ConversationsLocalization.OnFillInstructionOnIntegrationConnect(Items.Instruction.Title, 
	ConversationsInternalClientServer.ExternalSystemsTypes().WebChat);
	
	FillWebChatIntegrationParameters(IntegrationDetails);
	RefreshPreview();
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	For Each Parameter In DisplayParameters Do
		UpdatePreviewOrientationParameters(Parameter);
		UpdateParameterPresentationByValue(Parameter);		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If FormClosing = True And Not Exit Then
		Close(True);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PreviewDocumentComplete(Item)
	
	UpdatePreviewParameters();
	
	PageObject = Items.Preview.Document.defaultView;
	PageObject.initString("today", 				NStr("vi = 'Hôm nay';
														|ru = 'Сегодня';
														|en = 'Today'; fa = 'امروز';
														|it = 'Today';
														|pl = 'Today';
														|tr = 'Bugün'"));
	PageObject.initString("administrator",		NStr("vi = 'Người quản trị';
														|ru = 'Администратор';
														|en = 'Administrator'; fa = 'مدیر سیستم';
														|it = 'Administrator';
														|pl = 'Administrator';
														|tr = 'Yönetici'"));
	PageObject.initString("text1", 				NStr("vi = 'Ngày mới tốt lành. Tôi có thể giúp gì cho bạn?';
														|ru = 'Добрый день. Могу чем-то помочь?';
														|en = 'Hi, what can I do for you?'; fa = 'Hi, what can I do for you?';
														|it = 'Hi, what can I do for you?';
														|pl = 'Hi, what can I do for you?';
														|tr = 'İyi günler. Size nasıl yardımcı olabilirim?'"));
	PageObject.initString("text2", 				NStr("vi = 'Ngày mới tốt lành. Tôi quan tâm đến việc kết nối dịch vụ bên thứ ba của bạn vào trang web của mình.';
														|ru = 'Добрый день. Меня интересует подключение вашего стороннего сервиса на мой сайт.';
														|en = 'Hi, I would like to integrate your service into my website.'; fa = 'Hi, I would like to integrate your service into my website.';
														|it = 'Hi, I would like to integrate your service into my website.';
														|pl = 'Hi, I would like to integrate your service into my website.';
														|tr = 'İyi günler. Üçüncü taraf hizmetinizi siteme bağlamak istiyorum.'"));
	PageObject.initString("time", 				NStr("vi = '14:53';
														|ru = '14:53';
														|en = '14:53'; fa = '14:53';
														|it = '14:53';
														|pl = '14:53';
														|tr = '14:53'"));
	PageObject.initString("textareaTooltip", 	NStr("vi = 'Hãy nhập thông báo...';
														|ru = 'Введите сообщение...';
														|en = 'Enter your message…'; fa = 'Enter your message…';
														|it = 'Enter your message…';
														|pl = 'Enter your message…';
														|tr = 'Mesajınızı yazın...'"));
	PageObject.initString("attachFileTooltip", 	NStr("vi = 'Đính kèm tệp';
														|ru = 'Прикрепить файл';
														|en = 'Attach file'; fa = 'پیوست فایل';
														|it = 'Allegare il file';
														|pl = 'Dołącz plik';
														|tr = 'Dosya ekle'"));
	
	// ACC:1036-off - Domain-specific terminology.
	PageObject.initString("videoCallTooltip", 	NStr("vi = 'Cuộc gọi video';
														|ru = 'Видеозвонок';
														|en = 'Video call'; fa = 'Video call';
														|it = 'Video call';
														|pl = 'Video call';
														|tr = 'Görüntülü arama'"));
	// ACC:1036-on
	
	PageObject.initString("closeTooltip",		NStr("vi = 'Đóng';
														|ru = 'Закрыть';
														|en = 'Close'; fa = 'بستن';
														|it = 'Close';
														|pl = 'Close';
														|tr = 'Kapat'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttendees

&AtClient
Procedure ExternalParametersOnChange(Item)
	
	UpdatePreviewParameters();

	If FormClosing = True Then
		Items.Close.Title = NStr("vi = 'Ghi lại và đóng';
								|ru = 'Записать и закрыть';
								|en = 'Save and close'; fa = 'ذخیره و بستن';
								|it = 'Salvare e chiudere';
								|pl = 'Zapisz i zamknij';
								|tr = 'Kaydet ve kapat'");
		IsIntegrationUsed = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalParametersOnRowActivation(Item)
	
	UpdateCurrentDataPresentation();
	
EndProcedure

&AtClient
Procedure AttendeesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	For Each PickedUser In ValueSelected Do
		If Attendees.FindRows(New Structure("User", PickedUser)).Count() = 0 Then
			Attendees.Add().User = PickedUser;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ExternalParametersValuePresentationOnChange(Item)

	CurrentData = Items.ExternalParameters.CurrentData;
	
	If CurrentData.Type = "Color" Then
		CurrentData.ValuePresentation = CurrentData.ValuePresentation.GetAbsolute();
	EndIf;
	
	UpdateParameterValueByPresentation(CurrentData);

EndProcedure

&AtClient
Procedure ExternalParametersValuePresentationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.ExternalParameters.CurrentData;
	
	If CurrentData.Name = "signKey" Then
		
		StandardProcessing = False;                        
		
		CurrentData.ValuePresentation = GenerateRandomKey();
		UpdateParameterValueByPresentation(CurrentData); 
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	ConversationsInternalClient.StartPickingConversationParticipants(Items.Attendees);
EndProcedure

&AtClient
Procedure ActivateBot(Command)
	
	If FormClosing = True Then
		Close(True);
		Return;
	EndIf;
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Try
		SetAsActiveServer();
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("vi = 'Không thể kích hoạt chat bot do nguyên nhân:';
				|ru = 'Не удалось активировать чат-бот по причине:';
				|en = 'Cannot enable the chat bot due to:'; fa = 'Cannot enable the chat bot due to:';
				|it = 'Не удалось активировать чат-бот по причине:';
				|pl = 'Cannot enable the chat bot due to:';
				|tr = 'Konuşma botu şu sebeple aktive edilemedi:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	If IsIntegrationUsed Then
		Close(True);
		Return;		
	EndIf;
	
	Items.Close.Title = NStr("vi = 'Đóng';
							|ru = 'Закрыть';
							|en = 'Close'; fa = 'بستن';
							|it = 'Close';
							|pl = 'Close';
							|tr = 'Kapat'");
	FormClosing = True;
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	Try
		DisconnectServer();
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("vi = 'Không thể tắt chat bot do nguyên nhân:';
				|ru = 'Не удалось отключить чат-бот по причине:';
				|en = 'Cannot disable the chat bot due to:'; fa = 'Cannot disable the chat bot due to:';
				|it = 'Не удалось отключить чат-бот по причине:';
				|pl = 'Cannot disable the chat bot due to:';
				|tr = 'Konuşma botu şu sebeple devre dışı bırakılamadı:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	Close(True);
EndProcedure

&AtClient
Procedure SaveWebPageFile(Command)

	MessageText = NStr("vi = 'Để lưu tệp, cần cài đặt phần mở rộng đối với web-client ""1C:Enterprise"".';
						|ru = 'Для сохранения файла необходимо установить расширение для веб-клиента 1С:Предприятие.';
						|en = 'To save the file, install 1C:Enterprise Extension.'; fa = 'To save the file, install 1C:Enterprise Extension.';
						|it = 'To save the file, install 1C:Enterprise Extension.';
						|pl = 'To save the file, install 1C:Enterprise Extension.';
						|tr = 'Dosyayı kaydedebilmek için 1C:Enterprise web istemcisinin uzantısı yüklenmelidir.'");
	
	CallbackDescription = New CallbackDescription("SaveWebPageFileContinued", ThisObject);
	FileSystemClient.Attach1CEnterpriseExtension(CallbackDescription, MessageText);

EndProcedure

#EndRegion

#Region Private

&AtClient
Async Procedure SaveWebPageFileContinued(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	If Not FileSystemExtensionAttached1 Then
		Return;
	EndIf;  

	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Title = NStr("vi = 'Lưu tệp';
							|ru = 'Сохранение файла';
							|en = 'Save file'; fa = 'ذخیره فایل';
							|it = 'Salvataggio del file';
							|pl = 'Zapisywanie pliku';
							|tr = 'Dosyaların kaydedilmesi'");
	FileDialog.Filter = NStr("vi = 'Tệp HTML (*.html)|*.html|Tất cả tệp (*.*)|*.*';
							|ru = 'Файлы HTML (*.html)|*.html|Все файлы (*.*)|*.*';
							|en = 'HTML files (*.html)|*.html|All files  (*.*)|*.*'; fa = 'HTML files (*.html)|*.html|All files  (*.*)|*.*';
							|it = 'HTML files (*.html)|*.html|All files  (*.*)|*.*';
							|pl = 'HTML files (*.html)|*.html|All files  (*.*)|*.*';
							|tr = 'HTML dosyaları (*.html)|*.html|Tüm dosyalar (*.*)|*.*'");
	
	SelectedFiles = Await FileDialog.ChooseAsync();
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	TextDocument = New TextDocument;
	TextDocument.SetText(WebPageFileContent());
	
	Try
		RecordingResult =  Await TextDocument.WriteAsync(SelectedFiles[0]);	
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("vi = 'Không thể lưu lại tệp do nguyên nhân:';
				|ru = 'Не удалось сохранить файл по причине:';
				|en = 'Couldn''t save the file due to:'; fa = 'Couldn''t save the file due to:';
				|it = 'Couldn''t save the file due to:';
				|pl = 'Couldn''t save the file due to:';
				|tr = 'Dosya şu sebeple kaydedilemedi:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	If RecordingResult = True Then
		
		Explanation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã lưu tệp vào %1';
																					|ru = 'Файл сохранен в %1';
																					|en = 'File saved to %1'; fa = 'File saved to %1';
																					|it = 'File saved to %1';
																					|pl = 'File saved to %1';
																					|tr = 'Dosya %1 içinde kaydedildi'"), 
			SelectedFiles[0]);
		
		AdditionalParameters = New Structure("FileName", SelectedFiles[0]);
		CallbackDescription = New CallbackDescription("SaveWebPageFileOpenFileDirectory",
			ThisObject, AdditionalParameters);
		
		ShowUserNotification(NStr("vi = 'Lưu tệp';
									|ru = 'Сохранение файла';
									|en = 'Save file'; fa = 'ذخیره فایل';
									|it = 'Salvataggio del file';
									|pl = 'Zapisywanie pliku';
									|tr = 'Dosyaların kaydedilmesi'"), CallbackDescription, Explanation, 
			PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure SaveWebPageFileOpenFileDirectory(AdditionalParameters) Export

	FileSystemClient.OpenExplorer(AdditionalParameters.FileName);
	
EndProcedure

&AtClient
Function WebPageFileContent()
	
	FileContent = "<!doctype html>
		|<html lang=""ru"">
		|<head>
  		|	<meta charset=""utf-8"" />
  		|	<title></title>
		|</head>
		|<body>
    	|	<script src=""%1"" async></script> 
		|</body>
		|</html>";
	
	ConnectionPointPresentation = NStr("vi = 'Đặt điểm kết nối';
										|ru = 'Подставить точку подключения';
										|en = 'Insert connection point'; fa = 'Insert connection point';
										|it = 'Insert connection point';
										|pl = 'Insert connection point';
										|tr = 'Bağlantı noktası yedekleme'");
	
	ReplaceSubstring = ?(IsBlankString(EndpointURL), 
		ConnectionPointPresentation, EndpointURL);
		
	Return StrTemplate(FileContent, ReplaceSubstring);
		
EndFunction

&AtServer
Procedure SetAsActiveServer()
	
	IntegrationParameters = ConversationsInternal.IntegrationParameters();
	IntegrationParameters.Id = Parameters.Id;
	IntegrationParameters.Key = Description; 
	IntegrationParameters.Type = ConversationsInternalClientServer.ExternalSystemsTypes().WebChat;
	IntegrationParameters.Attendees = Attendees.Unload(, "User").UnloadColumn("User");
	
	For Each ExternalParameter In DisplayParameters Do
		IntegrationParameters.Insert(ExternalParameter.Name, ExternalParameter.Value);
	EndDo;
	
	Try
		IntegrationDetails = ConversationsInternal.CreateChangeIntegration(IntegrationParameters);
		// Collaboration System requires a secondary call.
		Integration = CollaborationSystem.GetIntegration(IntegrationDetails.ID)
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	If Integration <> Undefined Then
		EndpointURL = Integration.EndpointURL;
		Parameters.Id = Integration.ID;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisconnectServer()
	ConversationsInternal.DisableIntegration(Parameters.Id);
EndProcedure

#Region WebChatParameters

&AtServer
Procedure FillWebChatIntegrationParameters(IntegrationDetails = Undefined)
	
	If Not Conversations.ConversationsAvailable() Then
		Return;
	EndIf;
	
	ExternalSystemType = ConversationsInternalClientServer.ExternalSystemsTypes().WebChat;
	
	Try
		ExternalSystemDetails = CollaborationSystem.GetExternalSystemDescription(ExternalSystemType);	
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
		EventLogLevel.Error, , ,
		ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	DisplayParameters.Clear();

	For Each ExternalSystemParameter In ExternalSystemDetails.ParametersDescriptions Do
		WebChatParameter = DisplayParameters.Add();
		WebChatParameter.Name = ExternalSystemParameter.Name;
	EndDo;
	
	If IntegrationDetails <> Undefined Then

		For Each Parameter In IntegrationDetails.ExternalSystemParameters Do
			
			Filter = New Structure("Name", Parameter.Key);
			FoundRows = DisplayParameters.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				ExternalParameter = DisplayParameters.Add();
				ExternalParameter.Name = Parameter.Key;
			Else
				ExternalParameter = FoundRows[0];
			EndIf;
			
			ExternalParameter.Value = Parameter.Value;
			
		EndDo;
		
	EndIf;

	For Each WebChatParameter In DisplayParameters Do
		FillParameterData(WebChatParameter);
	EndDo;
		
EndProcedure

&AtClient
Procedure UpdatePreviewOrientationParameters(WebChatParameter)
	
	If WebChatParameter.Name = "orientation" Or WebChatParameter.Name = "orientationPadding" Then
		UpdateOrientationPadding();	
	EndIf;

EndProcedure

&AtClient
Procedure UpdateOrientationPadding()
	
	Filter = New Structure("Name", "orientation");
	FoundRows = DisplayParameters.FindRows(Filter);
	
	If Not FoundRows.Count() Then
		Return;
	EndIf;
	
	OrientationParameter = FoundRows[0];
	
	Filter = New Structure("Name", "orientationPadding");
	FoundRows = DisplayParameters.FindRows(Filter); 
	
	If Not FoundRows.Count() Then
		Return;
	EndIf;
	
	IndentParameter = FoundRows[0];
	
	If OrientationParameter.Value = "bottom" Then
		IndentParameter.ValueList.Clear();
		IndentParameter.ValueList.Insert("_0",	NStr("vi = 'Bên trái';
														|ru = 'Слева';
														|en = 'Left'; fa = 'چپ';
														|it = 'Left';
														|pl = 'Left';
														|tr = 'Sol'"));
		IndentParameter.ValueList.Insert("_50", 	NStr("vi = 'Ở giữa';
														|ru = 'По центру';
														|en = 'Center'; fa = 'وسط';
														|it = 'Nel centro';
														|pl = 'Względem środka';
														|tr = 'Merkez hizasında'"));
		IndentParameter.ValueList.Insert("_100", NStr("vi = 'Bên phải';
														|ru = 'Справа';
														|en = 'Right'; fa = 'راست';
														|it = 'Right';
														|pl = 'Right';
														|tr = 'Sağ'"));
	ElsIf OrientationParameter.Value = "left" Or OrientationParameter.Value = "right" Then
		IndentParameter.ValueList.Clear();
		IndentParameter.ValueList.Insert("_100", NStr("vi = 'Phía trên';
														|ru = 'Сверху';
														|en = 'Top'; fa = 'بالا';
														|it = 'Top';
														|pl = 'Top';
														|tr = 'Yukarı'"));
		IndentParameter.ValueList.Insert("_50", 	NStr("vi = 'Ở giữa';
														|ru = 'По центру';
														|en = 'Center'; fa = 'وسط';
														|it = 'Nel centro';
														|pl = 'Względem środka';
														|tr = 'Merkez hizasında'"));
		IndentParameter.ValueList.Insert("_0", 	NStr("vi = 'Bên dưới';
														|ru = 'Снизу';
														|en = 'Bottom'; fa = 'پایین';
														|it = 'Bottom';
														|pl = 'Bottom';
														|tr = 'Alt'"));
	EndIf;       
	
	UpdateParameterPresentationByValue(IndentParameter);
	
EndProcedure

&AtClient
Procedure UpdatePreviewParameters()
	
	WebPagePreviewWindow = Items.Preview.Document.defaultView;
	
	For Each DisplayParameter In DisplayParameters Do
		WebPagePreviewWindow.updatePreview(DisplayParameter.Name, DisplayParameter.Value);
	EndDo;  
	
EndProcedure

&AtClient
Procedure UpdateCurrentDataPresentation()
	
	CurrentData = Items.ExternalParameters.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;  
	
	ParameterValue = Items.ExternalParametersValuePresentation;
	ParameterValue.TypeRestriction = New TypeDescription(CurrentData.Type);
	
	If CurrentData.ChoiceButton <> Undefined Then
		ParameterValue.ChoiceButton = True;
		ParameterValue.ChoiceButtonPicture = CurrentData.ChoiceButton;
	Else
		ParameterValue.ChoiceButton = False;		
	EndIf;

	ParameterValue.ChoiceList.Clear();
	
	If CurrentData.ValueList <> Undefined Then
		ParameterValue.ListChoiceMode = True;
		For Each Value In CurrentData.ValueList Do
			ParameterValue.ChoiceList.Add(Value.Value);
		EndDo; 
	Else
		ParameterValue.ListChoiceMode = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ConvertHexToDec(Number)
	
	Dictionary = "0123456789ABCDEF";
	Result = 0;
	
	ItemCountInNumber = StrLen(Number);
	
	For Position = 1 To ItemCountInNumber Do
		Result = Result + ((StrFind(Dictionary, Mid(Number, Position, 1)) - 1) * Pow(16, ItemCountInNumber - Position));
	EndDo;
	
	Return Result; 
	
EndFunction

&AtClientAtServerNoContext
Function ConvertDecToHex(Number)
	
	Dictionary = "0123456789ABCDEF";
	
	Term1 = Int(Number / 16);
	Term2 = Number - (Term1 * 16);
	
	Return Mid(Dictionary, Term1 + 1, 1) + Mid(Dictionary, Term2 + 1, 1); 
	
EndFunction

&AtServer
Procedure FillParameterData(WebChatParameter)
	
	If WebChatParameter.Name = "allowVideoconferences" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Cuộc gọi video';
											|ru = 'Видеозвонки';
											|en = 'Video calls'; fa = 'Video calls';
											|it = 'Video calls';
											|pl = 'Video calls';
											|tr = 'Video görüşmeleri'");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "allowed";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("allowed", NStr("vi = 'Cho phép';
															|ru = 'Доступны';
															|en = 'Available'; fa = 'در دسترس';
															|it = 'Available';
															|pl = 'Available';
															|tr = 'Kullanılabilir olanlar'"));
		WebChatParameter.ValueList.Insert("allowedToWebChatOnly", NStr("vi = 'Chỉ có sẵn trong trò chuyện';
																		|ru = 'Доступны только в чат';
																		|en = 'Available for chat only'; fa = 'Available for chat only';
																		|it = 'Available for chat only';
																		|pl = 'Available for chat only';
																		|tr = 'Sadece sohbette erişilebilir'"));
		WebChatParameter.ValueList.Insert("disallowed", NStr("vi = 'Không được phép';
															|ru = 'Недоступны';
															|en = 'Unavailable'; fa = 'در دسترس نیست';
															|it = 'Unavailable';
															|pl = 'Unavailable';
															|tr = 'Kullanılamayanlar'"));  
			
	ElsIf WebChatParameter.Name = "defaultApplicationUserCameraState" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Trạng thái camera mặc định của người dùng ứng dụng';
											|ru = 'Состояние камеры пользователя приложения по умолчанию';
											|en = 'Default application camera status'; fa = 'Default application camera status';
											|it = 'Default application camera status';
											|pl = 'Default application camera status';
											|tr = 'Varsayılan uygulamanın kullanıcı kamera durumu'");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "on";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("on", NStr("vi = 'Bật';
													|ru = 'Включена';
													|en = 'Enabled'; fa = 'فعال';
													|it = 'Enabled';
													|pl = 'Enabled';
													|tr = 'Etkin'"));
		WebChatParameter.ValueList.Insert("off", NStr("vi = 'Tắt';
														|ru = 'Выключена';
														|en = 'Disabled'; fa = 'غیرفعال';
														|it = 'Disabled';
														|pl = 'Disabled';
														|tr = 'Devre dışı'"));
			
	ElsIf WebChatParameter.Name = "signKey" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Khóa chữ ký';
											|ru = 'Ключ подписи';
											|en = 'Signature key'; fa = 'Signature key';
											|it = 'Signature key';
											|pl = 'Signature key';
											|tr = 'İmza anahtarı'");
		WebChatParameter.Type = "String";
		WebChatParameter.ChoiceButton = PictureLib.Reread;
		
	ElsIf WebChatParameter.Name = "orientation" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Vị trí trò chuyện';
											|ru = 'Местоположение чата';
											|en = 'Chat position'; fa = 'Chat position';
											|it = 'Chat position';
											|pl = 'Chat position';
											|tr = 'Sohbetin konumu'");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "bottom";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("left", NStr("vi = 'Bên trái';
														|ru = 'Слева';
														|en = 'Left'; fa = 'چپ';
														|it = 'A sinistra';
														|pl = 'Z lewej';
														|tr = 'Sol'"));
		WebChatParameter.ValueList.Insert("bottom", NStr("vi = 'Bên dưới';
														|ru = 'Снизу';
														|en = 'Bottom'; fa = 'پایین';
														|it = 'Sotto';
														|pl = 'Na dole';
														|tr = 'Alt'"));
		WebChatParameter.ValueList.Insert("right", NStr("vi = 'Bên phải';
														|ru = 'Справа';
														|en = 'Right'; fa = 'راست';
														|it = 'A destra';
														|pl = 'Po prawej stronie';
														|tr = 'Sağ'"));
		
	ElsIf WebChatParameter.Name = "orientationPadding" Then 
		
		WebChatParameter.Presentation = NStr("vi = 'Căn chỉnh trò chuyện';
											|ru = 'Выравнивание чата';
											|en = 'Chat alignment'; fa = 'Chat alignment';
											|it = 'Chat alignment';
											|pl = 'Chat alignment';
											|tr = 'Sohbet hizalama'");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "100";
		
		WebChatParameter.ValueList = New Structure;
		
	ElsIf WebChatParameter.Name = "mobileButtonOrientation" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Hướng nút chat trong phiên bản di động';
											|ru = 'Ориентация кнопки чата в мобильной версии';
											|en = 'Chat button orientation in mobile version'; fa = 'Chat button orientation in mobile version';
											|it = 'Chat button orientation in mobile version';
											|pl = 'Chat button orientation in mobile version';
											|tr = 'Mobil sürümde sohbet düğmesinin yönü'");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "rightBottom";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("leftBottom", NStr("vi = 'Dưới cùng bên trái';
															|ru = 'Слева снизу';
															|en = 'Bottom left'; fa = 'Bottom left';
															|it = 'Sinistra giù';
															|pl = 'Po lewej u dołu';
															|tr = 'Aşağıda solda'"));
		WebChatParameter.ValueList.Insert("rightBottom", NStr("vi = 'Dưới cùng bên phải';
																|ru = 'Справа снизу';
																|en = 'Bottom right'; fa = 'Bottom right';
																|it = 'Destra giù';
																|pl = 'Z prawej u dołu';
																|tr = 'Aşağıda sağda'"));
		
	ElsIf WebChatParameter.Name = "colorTheme" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Chủ đề theo màu';
											|ru = 'Цветовая тема';
											|en = 'Color mode'; fa = 'Color mode';
											|it = 'Color mode';
											|pl = 'Color mode';
											|tr = 'Renkli tema'");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "auto";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("auto", NStr("vi = 'Tự động';
														|ru = 'Авто';
														|en = 'Auto'; fa = 'خودکار';
														|it = 'Auto';
														|pl = 'Auto';
														|tr = 'Otomatik'"));
		WebChatParameter.ValueList.Insert("light", NStr("vi = 'Sáng';
														|ru = 'Светлая';
														|en = 'Light'; fa = 'Light';
														|it = 'Light';
														|pl = 'Light';
														|tr = 'Renkli'"));
		WebChatParameter.ValueList.Insert("dark", NStr("vi = 'Tối';
														|ru = 'Темная';
														|en = 'Dark'; fa = 'Dark';
														|it = 'Dark';
														|pl = 'Dark';
														|tr = 'Renksiz'"));
			
	ElsIf WebChatParameter.Name = "titleText" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Nội dung tiêu đề chat';
											|ru = 'Текст заголовка чата';
											|en = 'Chat title'; fa = 'Chat title';
											|it = 'Chat title';
											|pl = 'Chat title';
											|tr = 'Sohbet başlığının metni'");
		WebChatParameter.Type = "String";
		
	ElsIf WebChatParameter.Name = "titleBackColor" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Màu nền tiêu đề chat';
											|ru = 'Цвет фона заголовка чата';
											|en = 'Chat background color'; fa = 'Chat background color';
											|it = 'Chat background color';
											|pl = 'Chat background color';
											|tr = 'Sohbet başlığının arka plan rengi'");
		WebChatParameter.Type = "Color";
		WebChatParameter.StandardValue = "#FBED9E";
		WebChatParameter.ChoiceButton = PictureLib.InputFieldSelect;
		
	ElsIf WebChatParameter.Name = "titleTextColor" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Màu nền tiêu đề chat';
											|ru = 'Цвет текста заголовка чата';
											|en = 'Chat title font color'; fa = 'Chat title font color';
											|it = 'Chat title font color';
											|pl = 'Chat title font color';
											|tr = 'Sohbet başlığının metin rengi'");
		WebChatParameter.Type = "Color";
		WebChatParameter.StandardValue = "#333333";
		WebChatParameter.ChoiceButton = PictureLib.InputFieldSelect;
		
	ElsIf WebChatParameter.Name = "displayUserPictures" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Hiển thị ảnh đại diện';
											|ru = 'Показывать аватары';
											|en = 'Show profile pictures'; fa = 'Show profile pictures';
											|it = 'Show profile pictures';
											|pl = 'Show profile pictures';
											|tr = 'Avatarları göster'");
		WebChatParameter.Type = "Boolean";
		WebChatParameter.StandardValue = "true";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("true", True);
		WebChatParameter.ValueList.Insert("false", False);
		
	ElsIf WebChatParameter.Name = "languageCode" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Mã ngôn ngữ chat';
											|ru = 'Код языка чата';
											|en = 'Chat language code'; fa = 'Chat language code';
											|it = 'Chat language code';
											|pl = 'Chat language code';
											|tr = 'Sohbet dili kodu'");
		WebChatParameter.Type = "String"; 
		
		LocalizationList = AvailableLocales();
		If LocalizationList.FindByValue(CurrentLocaleCode()) <> Undefined Then
			WebChatParameter.StandardValue = CurrentLocaleCode();
		ElsIf LocalizationList.FindByValue(CurrentSystemLanguage()) <> Undefined Then
			WebChatParameter.StandardValue = CurrentSystemLanguage();
		Else
			WebChatParameter.StandardValue = "en";
		EndIf;    

		WebChatParameter.ValueList = New Structure;
		For Each LocaleItem In LocalizationList Do
			WebChatParameter.ValueList.Insert(LocaleItem.Value, LocaleItem.Presentation);
		EndDo;
		
	ElsIf WebChatParameter.Name = "displayUnreadMessagesMark" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Hiển thị đánh dấu tin nhắn là chưa đọc';
											|ru = 'Отображать отметку непрочитанных сообщений';
											|en = 'Show unread message icon'; fa = 'Show unread message icon';
											|it = 'Show unread message icon';
											|pl = 'Show unread message icon';
											|tr = 'Okunmamış mesaj işaretini göster'");
		WebChatParameter.Type = "Boolean";
		WebChatParameter.StandardValue = "true";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("true", True);
		WebChatParameter.ValueList.Insert("false", False);
		
	ElsIf WebChatParameter.Name = "displayCollapsedState" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Hiển thị trạng thái thu gọn của cuộc trò chuyện';
											|ru = 'Отображать свернутое состояние чата';
											|en = 'Show collapsed chat state'; fa = 'Show collapsed chat state';
											|it = 'Show collapsed chat state';
											|pl = 'Show collapsed chat state';
											|tr = 'Küçültülmüş sohbet durumunu göster'");
		WebChatParameter.Type = "Boolean";
		WebChatParameter.StandardValue = "true";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("true", True);
		WebChatParameter.ValueList.Insert("false", False);
		
	ElsIf WebChatParameter.Name = "openChatOnNewMessage" Then
		
		WebChatParameter.Presentation = NStr("vi = 'Mở trò chuyện khi nhận tin nhắn mới';
											|ru = 'Открывать чат при получении нового сообщения';
											|en = 'Open chat when a new message arrives'; fa = 'Open chat when a new message arrives';
											|it = 'Open chat when a new message arrives';
											|pl = 'Open chat when a new message arrives';
											|tr = 'Yeni mesaj alındığında sohbeti aç'");
		WebChatParameter.Type = "Boolean";
		WebChatParameter.StandardValue = "true";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("true", True);
		WebChatParameter.ValueList.Insert("false", False);

	Else
		
		WebChatParameter.Presentation = WebChatParameter.Name;
		WebChatParameter.Type = "String";
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AvailableLocales()
	
	LocalizationList = New ValueList;
	For Each LocaleCode In GetAvailableLocaleCodes() Do
		LocalizationList.Add(LocaleCode, LocaleCodePresentation(LocaleCode));
	EndDo;
	LocalizationList.SortByPresentation(SortDirection.Asc);
	Return LocalizationList;
		
EndFunction

&AtServer
Procedure RefreshPreview()
	
	Preview = DataProcessors.EnableDiscussions.GetTemplate("WebChatDisplayTemplate").GetText()
	
EndProcedure

&AtClient
Procedure UpdateParameterPresentationByValue(WebChatParameter)
	
	If WebChatParameter.Value = "" And WebChatParameter.StandardValue <> "" Then
		WebChatParameter.Value = WebChatParameter.StandardValue;
	EndIf;
	
	Presentation = Undefined;
	
	If WebChatParameter.Value <> "" Then	
		
		If WebChatParameter.ValueList <> Undefined Then	
			
			FirstCharCode = CharCode(WebChatParameter.Value, 1);
			ValueKey = ?(48 <= FirstCharCode And FirstCharCode <= 57, "_" + WebChatParameter.Value, WebChatParameter.Value);
			
			Presentation = Undefined;
			WebChatParameter.ValueList.Property(ValueKey, Presentation);
			
			If Presentation <> Undefined Then	
				WebChatParameter.ValuePresentation = Presentation;
			EndIf;  
			
		EndIf; 
		
	EndIf;
	
	If Presentation = Undefined Then
		
		If WebChatParameter.Type = "String" Then
			WebChatParameter.ValuePresentation = WebChatParameter.Value;
		ElsIf WebChatParameter.Type = "Boolean" Then
			WebChatParameter.ValuePresentation = Boolean(WebChatParameter.Value);
		ElsIf WebChatParameter.Type = "Number" Then
			WebChatParameter.ValuePresentation = Number(WebChatParameter.Value);
		ElsIf WebChatParameter.Type = "Color" Then
			WebChatParameter.ValuePresentation = ColorFromText(WebChatParameter.Value);
		EndIf; 
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure UpdateParameterValueByPresentation(WebChatParameter)
	
	If WebChatParameter.ValueList <> Undefined Then		
		
		For Each ListItem In WebChatParameter.ValueList Do
			If ListItem.Value = WebChatParameter.ValuePresentation Then
				WebChatParameter.Value = ?(Mid(ListItem.Key, 1, 1) = "_", Mid(ListItem.Key, 2), ListItem.Key);	
			EndIf;
		EndDo;
		
	Else
		
		If WebChatParameter.Type = "String" Then
			WebChatParameter.Value = WebChatParameter.ValuePresentation;
		ElsIf WebChatParameter.Type = "Boolean" Or WebChatParameter.Type = "Number" Then
			WebChatParameter.Value = String(WebChatParameter.ValuePresentation);
		ElsIf WebChatParameter.Type = "Color" Then
			RGBColor = WebChatParameter.ValuePresentation.GetAbsolute();
			WebChatParameter.Value = "#" + ConvertDecToHex(RGBColor.R) 
				+ ConvertDecToHex(RGBColor.G) + ConvertDecToHex(RGBColor.B);
		EndIf;  
		
	EndIf;
	
	UpdatePreviewOrientationParameters(WebChatParameter); 
	
EndProcedure

&AtClientAtServerNoContext
Function ColorFromText(Text)
	
	Red = 0;
	Green = 0;
	B 	= 0;
	
	If Mid(Text, 1, 1) = "#" Then
		Red = ConvertHexToDec(Upper(Mid(Text, 2, 2)));
		Green = ConvertHexToDec(Upper(Mid(Text, 4, 2)));
		B 	= ConvertHexToDec(Upper(Mid(Text, 6, 2)));
	EndIf; 
	
	Return New Color(Red, Green, B);
	
EndFunction

&AtServerNoContext
Function GenerateRandomKey()
	
	NewKey = "";
	RNG = New RandomNumberGenerator(); 
	
	For Cnt = 1 To 32 Do
		RandomNumber = RNG.RandomNumber(0, 255);
		NewKey = NewKey + ConvertDecToHex(RandomNumber);
	EndDo;

	Return NewKey;
	
EndFunction

#EndRegion

#EndRegion
