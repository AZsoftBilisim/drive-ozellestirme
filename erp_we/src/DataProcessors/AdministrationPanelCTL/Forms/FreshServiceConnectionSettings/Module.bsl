#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInAuthorizationData();
	
	Items.Fresh1CAuthorizationSettingsGroup.Visible = Not SaaSOperations.DataSeparationEnabled();	
	Items.ServicePaymentSettings.Enabled = ConstantsSet.UseServicePayment;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		MessageTemplate = NStr("vi = 'Chưa điền trường ""%1"".';
								|ru = 'Поле ""%1"" не заполнено.';
								|en = 'The ""%1"" field is required.'; fa = 'The ""%1"" field is required.';
								|it = 'Il campo ""%1"" non è compilato.';
								|pl = 'Nie wypełniono pola ""%1"".';
								|tr = '""%1"" alanı doldurulmadı.'");
		CheckedConstants = New Array;
		CheckedConstants.Add("Fresh1CServiceAddress");
		For Each Item In CheckedConstants Do
			If Not ValueIsFilled(Constants.Fresh1CServiceAddress.Get()) Then
				Common.MessageToUser(
					StrTemplate(MessageTemplate, Metadata.Constants[Item].Presentation()), , Item, "ConstantsSet", Cancel);
			EndIf;
		EndDo; 
	EndIf;
	AuthorizationData = InformationRegisters.AuthorizationIn1cFresh.Read(Users.CurrentUser());
	If Not ValueIsFilled(AuthorizationData.Login) Then
		Common.MessageToUser(
			NStr("vi = 'Chưa thiết lập dữ liệu đăng nhập vào dịch vụ.';
				|ru = 'Не установлены данные авторизации в сервисе.';
				|en = 'Authorization data in the service is not specified.'; fa = 'Authorization data in the service is not specified.';
				|it = 'I dati di autorizzazione non sono impostati nel servizio.';
				|pl = 'Nie ustawiono danych uwierzytelniania w serwisie.';
				|tr = 'Serviste kimlik doğrulama verileri belirtilmedi.'"), , , , Cancel);
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Fresh1CServiceAddressOnChange(Item)
	
	OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAuthorizationData(Command)
	
	Notification = New CallbackDescription("AfterSettingAuthorizationData", ThisObject);
	
	FormParameters = Undefined;
	If AuthorizationSet Then
		KeyConstructor = New Array;
		KeyConstructor.Add(New Structure("User", UsersClient.CurrentUser()));
		RecordKey = New("InformationRegisterRecordKey.AuthorizationIn1cFresh", KeyConstructor);
		FormParameters = New Structure("Key", RecordKey);
	EndIf;

	OpenForm("InformationRegister.AuthorizationIn1cFresh.RecordForm", FormParameters, , , , , Notification);
	
EndProcedure

&AtClient
Procedure ServicePaymentSettings(Command)
	
	FormParameters = New Structure;
	OpenForm(
		"DataProcessor.AdministrationPanelCTL.Form.ServicePaymentSettings", FormParameters,ThisObject);
		
EndProcedure

&AtClient
Procedure DownloadServiceRates(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf; 
	
	TimeConsumingOperation = StartLoadingServiceRates();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	Notification = New CallbackDescription("WhenLoadingTariffsIsComplete", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification, IdleParameters);
	
EndProcedure

&AtClient
Procedure UseServicePaymentOnChange(Item)
	
	OnChangeAttribute(Item);
	Items.ServicePaymentSettings.Enabled = ConstantsSet.UseServicePayment;
	RefreshInterface();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterSettingAuthorizationData(Result, AdditionalParameters) Export
	
	FillInAuthorizationData();
	
EndProcedure

&AtServer
Procedure FillInAuthorizationData()
	
	AuthorizationData = InformationRegisters.AuthorizationIn1cFresh.Read(Users.CurrentUser());
	If Not ValueIsFilled(AuthorizationData.Login) Then
		Items.SetAuthorizationData.Title = NStr("vi = 'Thiết lập dữ liệu ủy quyền';
												|ru = 'Установить данные авторизации';
												|en = 'Set authorization data'; fa = 'تنظیم داده‌های احراز هویت';
												|it = 'Impostare dati autorizzazione';
												|pl = 'Ustaw dane uwierzytelniania';
												|tr = 'Kimlik doğrulama verilerini ayarlamak'")
	Else
		AuthorizationSet = True;
		Items.SetAuthorizationData.Title = StrTemplate(
			NStr("vi = 'Tên đăng nhập: %1, mã thuê bao: %2';
				|ru = 'Логин: %1, код абонента: %2';
				|en = 'Username: %1, subscriber code: %2'; fa = 'Username: %1, subscriber code: %2';
				|it = 'Nome utente: %1, codice abbonato: %2';
				|pl = 'Login: %1, kod subskrybenta: %2';
				|tr = 'Kullanıcı adı: %1, abone kodu: %2'"), AuthorizationData.Login, Format(AuthorizationData.SubscriberCode, "NG=0"));
	EndIf; 
	
EndProcedure

&AtServer
Function StartLoadingServiceRates()
	
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "ServicePayment.DownloadServiceRates");
	
EndFunction

&AtClient
Procedure WhenLoadingTariffsIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then // The user canceled the task.
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã thực hiện kết nhập';
								|ru = 'Загрузка выполнена';
								|en = 'Import completed'; fa = 'ورود اطلاعات تکمیل شد';
								|it = 'Download eseguito';
								|pl = 'Pobieranie wykonano';
								|tr = 'İçe aktarma tamamlandı'"), , 
		NStr("vi = 'Đã thực hiện kết nhập biểu phí dịch vụ.';
			|ru = 'Загрузка тарифов сервиса выполнена.';
			|en = 'Service plans are imported.'; fa = 'Service plans are imported.';
			|it = 'Download tariffe del servizio completato.';
			|pl = 'Pobieranie taryf usługi zostało zakończone.';
			|tr = 'Servis planı içe aktarımı tamamlandı'"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item)
	
	ConstantsNames = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	For Each ConstantName In ConstantsNames Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	ConstantsNames = New Array;
	DataPathAttribute = Items[TagName].DataPath;
	
	BeginTransaction();
	Try
		
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNames.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	Return ConstantsNames;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue  = ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	
	Return ConstantName;
	
EndFunction

#EndRegion
