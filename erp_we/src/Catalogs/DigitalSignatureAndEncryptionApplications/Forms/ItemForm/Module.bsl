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
Var SelectedApplicationDescription;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.IsSubordinateDIBNode() Then
		ReadOnly = True;
	Else
		Items.SettingInCentralNodeLabel.Visible = False;
	EndIf;
	
	Items.Description.ChoiceList.Add("", NStr("vi = '<Ứng dụng khác>';
												|ru = '<Другое приложение>';
												|en = '<Another app>'; fa = '<Another app>';
												|it = '<Другое приложение>';
												|pl = '<Another app>';
												|tr = '<Diğer Uygulama>'"));
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	For Each SettingToSupply In SettingsToSupply Do
		If ThereIsAClientOrServerVOS(SettingToSupply) And Not SettingToSupply.Irrelevant Then
			Items.Description.ChoiceList.Add(SettingToSupply.Presentation);
		EndIf;
	EndDo;
	
	// Populates a new object by a built-in setting.
	If Not ValueIsFilled(Object.Ref) Then
		
		If ValueIsFilled(Parameters.SuppliedSettingID) Then
		
			Filter = New Structure("Id", Parameters.SuppliedSettingID);
			Rows = SettingsToSupply.FindRows(Filter);
			If Rows.Count() > 0 Then
				FillPropertyValues(Object, Rows[0]);
				Object.Description = Rows[0].Presentation;
				Items.Description.ReadOnly = True;
				Items.ApplicationName.ReadOnly = True;
				Items.ApplicationType.ReadOnly = True;
			EndIf;
			
		ElsIf ValueIsFilled(Parameters.Application) Then
			
			AppAuto = Parameters.Application; // See DigitalSignatureInternalClientServer.ExtendedApplicationDetails
			
			FillPropertyValues(Object, AppAuto,,"Ref");
			Object.Description = AppAuto.Presentation;
			Items.Description.ReadOnly = True;
			Items.ApplicationName.ReadOnly = True;
			Items.ApplicationType.ReadOnly = True;
			If ValueIsFilled(Parameters.UsageMode) Then
				Object.UsageMode = Parameters.UsageMode;
			EndIf;
		EndIf;
	EndIf;
	
	// Populate algorithm lists.
	Filter = New Structure("ApplicationName, ApplicationType", Object.ApplicationName, Object.ApplicationType);
	Rows = SettingsToSupply.FindRows(Filter);
	SettingToSupply = ?(Rows.Count() = 0, Undefined, Rows[0]);
	FillAlgorithmsChoiceLists(SettingToSupply);
	SetTitleAutoSettings(SettingToSupply);
	SetVisibilityAndAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillSelectedApplicationAlgorithms(True);
	
	If ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.ApplicationName) Then
		Return;
	EndIf;
	
	AttachIdleHandler("HandlerWaitingToStartTheProgramAfterOpening", 0.1, True);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Intended for updating the list of apps and their
	// parameters on the client side and server side.
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_DigitalSignatureAndEncryptionApplications", New Structure, Object.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Query = New Query;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("ApplicationName", Object.ApplicationName);
	Query.SetParameter("ApplicationType", Object.ApplicationType);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	DigitalSignatureAndEncryptionApplications.Ref <> &Ref
	|	AND DigitalSignatureAndEncryptionApplications.ApplicationName = &ApplicationName
	|	AND DigitalSignatureAndEncryptionApplications.ApplicationType = &ApplicationType";
	
	If Not Query.Execute().IsEmpty() Then
		Cancel = True;
		Common.MessageToUser(
			NStr("vi = 'Ứng dụng có tên và kiểu như vậy đã được thêm vào danh sách.';
				|ru = 'Приложение с указанным именем и типом уже есть в списке.';
				|en = 'An application with this name and type is already on the list.'; fa = 'An application with this name and type is already on the list.';
				|it = 'An application with this name and type is already on the list.';
				|pl = 'An application with this name and type is already on the list.';
				|tr = 'Belirtili ada ve türe sahip olan bir uygulama hali hazırda listede bulunmaktadır.'"),
			, "Object.ApplicationName");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	FillSelectedApplicationSettings(Object.Description);
	FillSelectedApplicationAlgorithms();
	
EndProcedure

&AtClient
Procedure DescriptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = "" Then
		Object.Description = "";
		Object.ApplicationName = "";
		Object.ApplicationType = 0;
		Object.SignAlgorithm = "";
		Object.HashAlgorithm = "";
		Object.EncryptAlgorithm = "";
	EndIf;
	
	SelectedApplicationDescription = ValueSelected;
	
	AttachIdleHandler("IdleHandlerDescriptionChoiceProcessing", 0.1, True);
	
EndProcedure

&AtClient
Procedure ApplicationNameOnChange(Item)
	
	AttachIdleHandler("WaitHandlerNameAndTypeOnChange", 0.1, True);
	
EndProcedure

&AtClient
Procedure ApplicationTypeOnChange(Item)
	
	AttachIdleHandler("WaitHandlerNameAndTypeOnChange", 0.1, True);
	
EndProcedure

&AtClient
Procedure UsageModeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.Automatically") Then
		
		ApplicationsByNamesWithType = DigitalSignatureClient.CommonSettings().ApplicationsByNamesWithType;
		Var_Key = DigitalSignatureInternalClientServer.ApplicationSearchKeyByNameWithType(Object.ApplicationName, Object.ApplicationType);
		ApplicationToSupply = ApplicationsByNamesWithType.Get(Var_Key);
		If ApplicationToSupply = Undefined Then
			StandardProcessing = False;
			ShowMessageBox(, NStr("vi = 'Không thể tự động xác định ứng dụng có tên và kiểu chỉ định.';
									|ru = 'Приложение с указанными именем и типом не может быть определено автоматически.';
									|en = 'An app with the specified name and type cannot be detected automatically.'; fa = 'An app with the specified name and type cannot be detected automatically.';
									|it = 'Приложение с указанными именем и типом не может быть определено автоматически.';
									|pl = 'An app with the specified name and type cannot be detected automatically.';
									|tr = 'Belirtilen ad ve türdeki uygulama otomatik olarak belirlenemiyor.'"));
			Return;
		EndIf;
		
		FillPropertyValues(Object, ApplicationToSupply);
		Object.UsageMode = ValueSelected;
		UsageModeOnChange(Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UsageModeOnChange(Item)
	
	SetVisibilityAndAvailability(ThisObject);
	FillSelectedApplicationAlgorithms();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDeletionMark(Command)
	
	If Not Modified Then
		SetDeletionMarkCompletion();
		Return;
	EndIf;
	
	ShowQueryBox(
		New CallbackDescription("SetDeletionMarksAfterAnswerQuestion", ThisObject),
		NStr("vi = 'Để đặt dấu xóa, hãy ghi lại những thay đổi đã thực hiện.
		           |Ghi lại dữ liệu?';
		           |ru = 'Для установки отметки удаления запишите сделанные изменения.
		           |Записать данные?';
		           |en = 'To set the deletion mark, write the changes you have made.
		           |Write the data?'; fa = 'To set the deletion mark, write the changes you have made.
		           |Write the data?';
		           |it = 'Per impostare il contrassegno per l''eliminazione, registrare le modifiche fatte.
		           |Registrare dati?';
		           |pl = 'Aby ustawić zaznaczenie do usunięcia zapisz wykonane zmiany.
		           |Zapisać dane?';
		           |tr = 'Silme işaretinin ayarlanması için yapılan değişiklikleri kaydedin.
		           |Veriler kaydedilsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSelectedApplicationSettings(Presentation)
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	If TypeOf(Presentation) = Type("Structure") Then
		Rows = SettingsToSupply.FindRows(Presentation);
		SettingToSupply = ?(Rows.Count() = 0, Undefined, Rows[0]);
	Else
		SettingToSupply = SettingsToSupply.Find(Presentation, "Presentation");
	EndIf;
	
	If SettingToSupply <> Undefined Then
		FillPropertyValues(Object, SettingToSupply);
		Object.Description = SettingToSupply.Presentation;
	EndIf;
	
	SetTitleAutoSettings(SettingToSupply);
	FillAlgorithmsChoiceLists(SettingToSupply);
	
EndProcedure

&AtServer
Procedure SetTitleAutoSettings(SettingToSupply)
	
	If SettingToSupply = Undefined Then
		Items.DecorationLabelAutoSettings.Title = NStr("vi = 'Không thể tự động xác định ứng dụng này';
														|ru = 'Это приложение не может быть определено автоматически';
														|en = 'This app cannot be detected automatically'; fa = 'This app cannot be detected automatically';
														|it = 'Это приложение не может быть определено автоматически';
														|pl = 'This app cannot be detected automatically';
														|tr = 'Bu uygulama otomatik olarak tespit edilemez.'");
		Return;
	EndIf;
	
	Items.DecorationLabelAutoSettings.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi làm việc với ứng dụng này, sử dụng các thuật toán:
			|Thuật toán chữ ký: %1
			|Thuật toán hàm băm: %2
			|Thuật toán mã hóa: %3';
			|ru = 'При работе с этим приложением используются алгоритмы:
			|Для подписи: %1
			|Для хеширования: %2
			|Для шифрования: %3';
			|en = 'Algorithms used in this app:
			|Signature algorithm: %1
			|Hashing algorithm: %2
			|Encryption algorithm: %3'; fa = 'Algorithms used in this app:
			|Signature algorithm: %1
			|Hashing algorithm: %2
			|Encryption algorithm: %3';
			|it = 'При работе с этим приложением используются алгоритмы:
			|Для подписи: %1
			|Для хеширования: %2
			|Для шифрования: %3';
			|pl = 'Algorithms used in this app:
			|Signature algorithm: %1
			|Hashing algorithm: %2
			|Encryption algorithm: %3';
			|tr = 'Bu uygulamada çalışırken şu algoritmalar kullanılmaktadır:
			|İmza için: %1
			|Karma işlevi için: %2
			|Şifreleme algoritması: %3'"), SettingToSupply.SignAlgorithm, SettingToSupply.HashAlgorithm,
			SettingToSupply.EncryptAlgorithm);
			
EndProcedure

&AtServer
Procedure FillAlgorithmsChoiceLists(SettingToSupply)
	
	SuppliedSignatureAlgorithms.Clear();
	SuppliedHashAlgorithms.Clear();
	SuppliedEncryptionAlgorithms.Clear();
	
	If SettingToSupply = Undefined Then
		Return;
	EndIf;
	
	SuppliedSignatureAlgorithms.LoadValues(SettingToSupply.SignAlgorithms);
	SuppliedHashAlgorithms.LoadValues(SettingToSupply.HashAlgorithms);
	SuppliedEncryptionAlgorithms.LoadValues(SettingToSupply.EncryptAlgorithms);
	
EndProcedure

&AtClient
Procedure FillSelectedApplicationAlgorithms(OnOpen = False)
	
	If Object.UsageMode = PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.Automatically") Then
		Return;
	EndIf;
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"FillAlgorithmsForSelectedApplicationAfterAttachCryptographyExtension", ThisObject));
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillAlgorithmsForSelectedApplicationAfterAttachCryptographyExtension(Attached, Context) Export
	
	If Not Attached Then
		FillSelectedApplicationAlgorithmsAfterGetInformation(Undefined, Context);
		Return;
	EndIf;
	
	DigitalSignatureInternalClient.ToObtainThePathToTheProgram(
		New CallbackDescription("FillInTheAlgorithmsOfTheSelectedProgramAfterGettingTheProgramPath",
			ThisObject, Context), Object.Ref);
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillInTheAlgorithmsOfTheSelectedProgramAfterGettingTheProgramPath(DescriptionOfWay, Context) Export
	
	CryptoTools.BeginGettingCryptoModuleInformation(New CallbackDescription(
			"FillSelectedApplicationAlgorithmsAfterGetInformation", ThisObject, ,
			"FillAlgorithmsForSelectedApplicationAfterGetDataError", ThisObject),
		Object.ApplicationName, DescriptionOfWay.ApplicationPath, Object.ApplicationType);
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillAlgorithmsForSelectedApplicationAfterGetDataError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	FillSelectedApplicationAlgorithmsAfterGetInformation(Undefined, Context);
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillSelectedApplicationAlgorithmsAfterGetInformation(ModuleInfo, Context) Export
	
	// If the cryptography manager is unavailable and in not 1C-supplied,
	// then the algorithm names should be entered manually.
	
	If ModuleInfo <> Undefined
	   And Object.ApplicationName <> ModuleInfo.Name
	   And Not DigitalSignatureInternalClient.RequiresThePathToTheProgram() Then
		
		ModuleInfo = Undefined;
	EndIf;
	
	If ModuleInfo = Undefined Then
		Items.SignAlgorithm.ChoiceList.LoadValues(
			SuppliedSignatureAlgorithms.UnloadValues());
		
		Items.HashAlgorithm.ChoiceList.LoadValues(
			SuppliedHashAlgorithms.UnloadValues());
		
		Items.EncryptAlgorithm.ChoiceList.LoadValues(
			SuppliedEncryptionAlgorithms.UnloadValues());
	Else
		Items.SignAlgorithm.ChoiceList.LoadValues(
			New Array(ModuleInfo.SignAlgorithms));
		
		Items.HashAlgorithm.ChoiceList.LoadValues(
			New Array(ModuleInfo.HashAlgorithms));
		
		Items.EncryptAlgorithm.ChoiceList.LoadValues(
			New Array(ModuleInfo.EncryptAlgorithms));
	EndIf;
	
	Items.SignAlgorithm.DropListButton =
		Items.SignAlgorithm.ChoiceList.Count() <> 0;
	
	Items.HashAlgorithm.DropListButton =
		Items.HashAlgorithm.ChoiceList.Count() <> 0;
	
	Items.EncryptAlgorithm.DropListButton =
		Items.EncryptAlgorithm.ChoiceList.Count() <> 0;
	
EndProcedure

&AtClient
Procedure SetDeletionMarksAfterAnswerQuestion(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Not Write() Then
		Return;
	EndIf;
	
	SetDeletionMarkCompletion();
	
EndProcedure
	
&AtClient
Procedure SetDeletionMarkCompletion()
	
	Object.DeletionMark = Not Object.DeletionMark;
	Write();
	
	Notify("Write_DigitalSignatureAndEncryptionApplications", New Structure, Object.Ref);
	
EndProcedure

&AtClient
Procedure HandlerWaitingToStartTheProgramAfterOpening()
	
	ShowChooseFromMenu(New CallbackDescription("AfterApplicationChoice", ThisObject),
		Items.Description.ChoiceList, Items.Description);
	
EndProcedure

&AtClient
Procedure AfterApplicationChoice(SelectedElement, Context) Export
	
	If SelectedElement = Undefined Then
		Return
	EndIf;
	
	DescriptionChoiceProcessing(Items.Description, SelectedElement.Value, False);
	
EndProcedure

// Continues the DescriptionChoiceProcessing procedure.
&AtClient
Procedure IdleHandlerDescriptionChoiceProcessing()
	
	FillSelectedApplicationSettings(SelectedApplicationDescription);
	FillSelectedApplicationAlgorithms();
	
EndProcedure

&AtClient
Procedure WaitHandlerNameAndTypeOnChange()
	
	If ValueIsFilled(Object.ApplicationName) And ValueIsFilled(Object.ApplicationType) Then
		FillSelectedApplicationSettings(New Structure("ApplicationName, ApplicationType",
			Object.ApplicationName, Object.ApplicationType));
	EndIf;
	
	FillSelectedApplicationAlgorithms();
	
EndProcedure

&AtServer
Function ThereIsAClientOrServerVOS(Setting)
	
	Return Not Setting.NotInWindows
	      And (Common.IsWindowsClient() Or Common.IsWindowsServer())
	    Or Not Setting.NotOnLinux
	      And (Common.IsLinuxClient() Or Common.IsLinuxServer())
	    Or Not Setting.NotInMacOS
	      And Common.IsMacOSClient();
	
EndFunction

&AtClientAtServerNoContext
Procedure SetVisibilityAndAvailability(Form)
	
	SettingsAvailability = Not DigitalSignatureInternalClientServer.AreAutomaticSettingsUsed(
		Form.Object.UsageMode);
	
	Form.Items.SignAlgorithm.Visible = SettingsAvailability;
	Form.Items.HashAlgorithm.Visible = SettingsAvailability;
	Form.Items.EncryptAlgorithm.Visible = SettingsAvailability;
	Form.Items.SignAlgorithm.Visible = SettingsAvailability;
	Form.Items.DecorationLabelAutoSettings.Visible = Not SettingsAvailability;
	
	If Not SettingsAvailability Then
		Form.Items.Description.ReadOnly = True;
		Form.Items.ApplicationName.ReadOnly = True;
		Form.Items.ApplicationType.ReadOnly = True;
	EndIf;
		
EndProcedure

#EndRegion
