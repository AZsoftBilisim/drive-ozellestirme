#Region Variables

&AtClient
Var YouCanCloseForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Values of form details
	CompositionOfSetOfConstantsOfForm = CompositionOfSetOfConstants(ConstantsSet);
	
	WorkMode = New Structure;
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm", New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode = New FixedStructure(WorkMode);
	
	ServerAddress = DataProcessors.ConfigureIntegrationWith1CAnalytics.ServerAddress();
	SavedServerAddress = ServerAddress;
	AnalyticsSystemServerIsAvailable = SetAddressOfAnalyticsServer(ServerAddress);
	SetVisibilityOf1CAnalyticsServerUnavailability(ThisObject);
	
	IsFileInfobase = Common.FileInfobase();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Updating the state of the elements
	SetAvailability();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		
		StandardProcessing = False;
		
		QueryText = "";
		If ConstantsSet.UseIntegrationWith1CAnalytics And IsBlankString(ServerAddress) And YouCanCloseForm = Undefined Then
			AdditionalParameter = "EmptyAddress";
			QueryText =	NStr("vi = 'Khi bật sử dụng tích hợp với 1C:Analytics, địa chỉ server không thể trống. Sẽ tắt tích hợp. Tiếp tục?';
								|ru = 'При включенной интеграции с 1С:Аналитикой адрес сервера не может быть пустым. Интеграция будет выключена. Продолжить?';
								|en = 'With enabled integration with 1C:Analytics, the server address cannot be empty. The integration will be disabled. Continue?'; fa = 'With enabled integration with 1C:Analytics, the server address cannot be empty. The integration will be disabled. Continue?';
								|it = 'При включенной интеграции с 1С:Аналитикой адрес сервера не может быть пустым. Интеграция будет выключена. Продолжить?';
								|pl = 'With enabled integration with 1C:Analytics, the server address cannot be empty. The integration will be disabled. Continue?';
								|tr = '1C:Analytics ile entegrasyon etkinleştirildiğinde, sunucu adresi boş olamaz. Entegrasyon kapatılacaktır. Devam edilsin mi?'");
		ElsIf ConstantsSet.UseIntegrationWith1CAnalytics And SavedServerAddress <> ServerAddress And YouCanCloseForm = Undefined Then
			AdditionalParameter = "AddressChanged";
			QueryText = NStr("vi = 'Đã thay đổi địa chỉ server hệ thống phân tích. Lưu các thay đổi?';
							|ru = 'Адрес сервера системы аналитики изменен. Сохранить изменения?';
							|en = 'The address of the analytics system server is changed. Do you want to save the changes?'; fa = 'The address of the analytics system server is changed. Do you want to save the changes?';
							|it = 'Адрес сервера системы аналитики изменен. Сохранить изменения?';
							|pl = 'The address of the analytics system server is changed. Do you want to save the changes?';
							|tr = 'Boyut sistem sunucusunun adresi değiştirildi. Değişiklikler kaydedilsin mi?'");
		EndIf;
			
		If Not IsBlankString(QueryText) Then 
			ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject, AdditionalParameter), QueryText, QuestionDialogMode.YesNoCancel);
			Cancel = True;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseIntegration1CAnalyticsOnChange(Item)
	
	If ConstantsSet.UseIntegrationWith1CAnalytics = False And Not IsBlankString(ServerAddress) Then
		QueryText = NStr("vi = 'Khi tắt sử dụng tích hợp, sẽ xóa địa chỉ server của hệ thống phân tích. Tiếp tục?';
						|ru = 'При выключении интеграции будет очишен адрес сервера системы аналитики. Продолжить?';
						|en = 'If you disable the integration, the address of the analytics system server will be cleared. Continue?'; fa = 'If you disable the integration, the address of the analytics system server will be cleared. Continue?';
						|it = 'При выключении интеграции будет очишен адрес сервера системы аналитики. Продолжить?';
						|pl = 'If you disable the integration, the address of the analytics system server will be cleared. Continue?';
						|tr = 'Entegrasyon kapatıldığında, boyut sistem sunucusunun adresi silinecektir. Devam edilsin mi?'");

		Notification = New CallbackDescription("AfterConfirmingThatIntegrationIsTurnedOff", ThisObject, Item);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure ServerAddressOnChange(Item)
	ServerAddressWhenChangedOnServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAddress(Command)
	
	AnalyticsSystemServerIsAvailable = SetAddressOfAnalyticsServer(ServerAddress);
	SetVisibilityOf1CAnalyticsServerUnavailability(ThisObject);
	If AnalyticsSystemServerIsAvailable Then
		SavedServerAddress = ServerAddress;
		Items.SetAddress.Enabled = False;
	Else
		NotifyAboutServerUnavailability();
	EndIf;
	
	SetAvailability();
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure MoreAboutService(Command)
	
	InformationLink = "https://v8.1c.ru/platforma/1s-analitika/";
	FileSystemClient.OpenURL(InformationLink);
	
EndProcedure

&AtClient
Procedure DownloadAnalyticsServer(Command)
	InformationLink = "https://releases.1c.ru/project/Analytics";
	FileSystemClient.OpenURL(InformationLink);
EndProcedure

&AtClient
Procedure OpenAnalyticsSystemManagement(Command)
	FormParameters = New Structure;
	FormParameters.Insert("ShowCopyingPanels", True);
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.CopyPanels", FormParameters);
EndProcedure

&AtClient
Procedure OpenAdditionalSourceManagement(Command)
	FormParameters = New Structure;
	FormParameters.Insert("ShowAdditionalSources", True);
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.AdditionalSources", FormParameters);
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetVisibilityOf1CAnalyticsServerUnavailability(Form)
	
	ConstantValue = Form.ConstantsSet.UseIntegrationWith1CAnalytics;
	Form.Items.AnalyticsSystemGroupIsUnavailable.Visible = ConstantValue And Not Form.AnalyticsSystemServerIsAvailable;
	
EndProcedure

&AtClient
Procedure SetAvailability(DataPathAttribute = "")
	
	If IsFileInfobase Then
		
		ReadOnly = IsFileInfobase;
		For Each Item In Items Do
			If Item.Type = FormDecorationType.Label Then
				Continue;
			EndIf;
			
			Item.Enabled = False;
		EndDo;

		Items.GroupDecorationAnalyticsSystemIsNotAvailableInFileVersion.Visible = True;
		
	Else
	
		If DataPathAttribute = "ConstantsSet.UseIntegrationWith1CAnalytics" Or DataPathAttribute = "" Then
			ConstantValue = ConstantsSet.UseIntegrationWith1CAnalytics;
			Items.ServerAddress.Enabled = ConstantValue;
			Items.AnalyticsSystemManagementGroup.Enabled = ConstantValue And AnalyticsSystemServerIsAvailable;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	If ConstantName <> "" Then
		If ShouldRefreshInterface Then
			RefreshApplicationInterface();
		Else
			SetAvailability();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	RefreshInterface();
	SetAvailability();
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServerNoContext
Function SetAddressOfAnalyticsServer(ServerAddress)
	
	Return DataProcessors.ConfigureIntegrationWith1CAnalytics.SetServerAddress(ServerAddress);
	
EndFunction

&AtClient
Procedure NotifyAboutServerUnavailability()
	
	ErrorMessage = NStr("vi = 'Chưa tìm thấy server 1C:Analytics.';
						|ru = 'Сервер 1С:Аналитика не обнаружен.';
						|en = 'The 1C:Analytics server is not found.'; fa = 'The 1C:Analytics server is not found.';
						|it = 'Сервер 1С:Аналитика не обнаружен.';
						|pl = 'The 1C:Analytics server is not found.';
						|tr = '1C:Analytics sunucusu bulunmadı.'");

	If ValueIsFilled(ServerAddress) Then
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa tìm thấy server 1C:Analytics theo địa chỉ ""%1"".';
				|ru = 'Сервер 1С:Аналитика по адресу ""%1"" не обнаружен.';
				|en = 'The 1C:Analytics server is not found at %1.'; fa = 'The 1C:Analytics server is not found at %1.';
				|it = 'Сервер 1С:Аналитика по адресу ""%1"" не обнаружен.';
				|pl = 'The 1C:Analytics server is not found at %1.';
				|tr = '""%1"" adresi kapsamında 1C:Analytics sunucusu bulunmadı.'"), ServerAddress);
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Thanh lệnh được cung cấp 1C:Analytics';
								|ru = 'Поставляемые панели 1С:Аналитика';
								|en = 'Built-in 1C:Analytics panels'; fa = 'Built-in 1C:Analytics panels';
								|it = 'Поставляемые панели 1С:Аналитика';
								|pl = 'Built-in 1C:Analytics panels';
								|tr = 'Yerleşik 1C:Analytics panelleri'"),,
		ErrorMessage,
		PictureLib.DialogExclamation);
	
EndProcedure

&AtServer
Function SaveAttributeValue(DataPathAttribute, RereadForm = True)
	
	// Storing the values of the details that are not directly related to the constants (in a one-to-one relationship).
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	// Definition of the constant name.
	ArrayOfPartsPropsDataPath = StrSplit(DataPathAttribute, ".");
	ConstantName = "";
	If ArrayOfPartsPropsDataPath.Count() = 2
			And Lower(ArrayOfPartsPropsDataPath[0]) = Lower("ConstantsSet") Then
		// If the path to the data of the props is specified through the "Setconstant".
		ConstantName = ArrayOfPartsPropsDataPath[1];
	EndIf;
	
	// Saving the value of a constant.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Function CompositionOfSetOfConstants(Set)
	
	Result = New Structure;
		
	For Each MetaConstant In Metadata.Constants Do
		If CommonClientServer.HasAttributeOrObjectProperty(Set, MetaConstant.Name) Then
			Result.Insert(MetaConstant.Name);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ServerAddressWhenChangedOnServer()
	AnalyticsSystemServerIsAvailable = CheckAvailabilityOfAnalyticsServerAt(ServerAddress);
	Items.AnalyticsSystemGroupIsUnavailable.Visible = Not AnalyticsSystemServerIsAvailable;
	Items.SetAddress.Enabled = AnalyticsSystemServerIsAvailable And ServerAddress <> SavedServerAddress;
EndProcedure

&AtServerNoContext
Function CheckAvailabilityOfAnalyticsServerAt(ServerAddress)
	
	Return DataProcessors.ConfigureIntegrationWith1CAnalytics.CheckAvailabilityOfAnalyticsServerAt(ServerAddress);
	
EndFunction

&AtClient
Procedure BeforeCloseCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		If AdditionalParameters = "EmptyAddress" Then
			ConstantsSet.UseIntegrationWith1CAnalytics = False;
			Item = Items.UseIntegration1CAnalytics;
			OnChangeAttribute(Item);
			ClearAddressServer();
		ElsIf AdditionalParameters = "AddressChanged" Then
			AnalyticsSystemServerIsAvailable = SetAddressOfAnalyticsServer(ServerAddress);
			SetVisibilityOf1CAnalyticsServerUnavailability(ThisObject);
			If Not AnalyticsSystemServerIsAvailable Then
				NotifyAboutServerUnavailability();
				Return;
			EndIf;
		EndIf;
		
		RefreshApplicationInterface();
		
		YouCanCloseForm = True;
		Close();
		
	ElsIf Result = DialogReturnCode.No Then
		
		If AdditionalParameters = "AddressChanged" Then
			
			YouCanCloseForm = True;
			Close();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterConfirmingThatIntegrationIsTurnedOff(Response, AdditionalParameters1) Export 
	
	If Response = DialogReturnCode.Yes Then
		ServerAddress = "";
		ClearAddressServer();
		OnChangeAttribute(AdditionalParameters1);
	Else 
		ConstantsSet.UseIntegrationWith1CAnalytics = Not ConstantsSet.UseIntegrationWith1CAnalytics;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ClearAddressServer()
	DataProcessors.ConfigureIntegrationWith1CAnalytics.ClearServerAddress();
EndProcedure

#EndRegion