#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	MapTypes = TMCommonUse.MatchingArraysByObjectType(Parameters.Objects);
	If MapTypes.Count() > 1 Then
		Raise NStr("vi = 'Cấm in bộ chứng từ có dạng khác nhau.';
					|ru = 'Запрещено печатать комплект документов различного вида.';
					|en = 'It is prohibited to print a set of documents of different kinds.'; fa = 'It is prohibited to print a set of documents of different kinds.';
					|it = 'Non è consentito stampare una serie di diversi tipi di documenti.';
					|pl = 'Zabronione jest drukowanie kompletu dokumentów różnego rodzaju.';
					|tr = 'Farklı türde belge seti yazdırmak yasaktır.'");
	Else
		
		For Each CurObjectType In MapTypes Do
			ObjectType = CurObjectType.Key;
			Break;
		EndDo;
		
		ObjectsTable = InformationRegisters.ObjectPrintSettings.TableOfObjectsForCompletePrinting();
		If ObjectsTable.Find(ObjectType, "ObjectType") = Undefined Then
			MessageText = NStr("vi = 'Không hỗ trợ in bộ cho chứng từ ""%Document%"".';
								|ru = 'Печать комплектов для документов ""%Document%"" не поддерживается.';
								|en = 'Printing sets for documents ""%Document%"" is not supported.'; fa = 'Printing sets for documents ""%Document%"" is not supported.';
								|it = 'La stampa delle serie per i documenti ""%Document%"" non è supportata.';
								|pl = 'Druk zestawów dokumentów ""%Document%"" nie jest obsługiwany.';
								|tr = '""%Document%"" belge setlerinin yazdırılması desteklenmez.'");
			MessageText = StrReplace(MessageText, "%Document%", Metadata.FindByFullName(ObjectType).Synonym);
			Raise MessageText;
		EndIf;
		
	EndIf;
	
	Objects.LoadValues(Parameters.Objects);
	
	If Objects.Count() = 1 Then
		
		ObjectParameters = InformationRegisters.ObjectPrintSettings.ObjectParametersForCompletePrinting(ObjectType);
		ThereIsACompany = ObjectParameters.ThereIsACompany;
		ThereIsAPartner = ObjectParameters.ThereIsAPartner;
		
		If ThereIsACompany And ThereIsAPartner Then
			Attributes = Common.ObjectAttributesValues(Parameters.Objects[0], "Partner,Organization");
			Organization = Attributes.Organization;
			Partner = Attributes.Partner;
		ElsIf ObjectParameters.ThereIsACompany Then
			Attributes = Common.ObjectAttributesValues(Parameters.Objects[0], "Organization");
			Organization = Attributes.Organization;
		ElsIf ObjectParameters.ThereIsAPartner Then
			Attributes = Common.ObjectAttributesValues(Parameters.Objects[0], "Partner");
			Partner = Attributes.Partner;
		EndIf;
		
	EndIf;
	
	PrintFormsCollection = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
		ObjectType,
		?(Objects.Count() = 1, Objects[0].Value, Undefined),
		UseVariant);
	
	GenerateOptionsForSavingSettings();
	UpdateUseCaseText();
	UpdateDeleteSettingsCommand();
	
	If PrintFormsCollection <> Undefined Then
	
		For Each CurRow In PrintFormsCollection Do
			
			NewRow = PrintFormsSet.Add();
			FillPropertyValues(NewRow, CurRow);
			
		EndDo;
		
	EndIf;
	
	// Print
	RequestConfirmation = Common.CommonSettingsStorageLoad("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments");
	If RequestConfirmation <> Undefined Then
		RequestConfirmationWhenPrintingASetOfDocuments = RequestConfirmation;
	Else
		RequestConfirmationWhenPrintingASetOfDocuments = True;
		Common.CommonSettingsStorageSave("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments", True);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	InformationRegisters.ObjectPrintSettings.KitOfPrintingPlatesIsSet(PrintFormsSet, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClosingInProgress Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Đã thay đổi tập hợp các hình thức in ấn. Đóng biểu mẫu mà không lưu cài đặt?';
																						|ru = 'Комплект печатных форм был изменен. Закрыть форму без сохранения настроек?';
																						|en = 'Set of print forms was changed. Close the form without saving the settings?'; fa = 'Set of print forms was changed. Close the form without saving the settings?';
																						|it = 'La serie di moduli di stampa è stata modificata. Chiudere il modulo senza salvare le impostazioni?';
																						|pl = 'Zestaw formularzy do druku został zmieniony. Zamknij formularz bez zapisywania ustawień?';
																						|tr = 'Yazdırma formu seti değiştirildi. Ayarları kaydetmeden formu kapat?'"), ButtonsList);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Print(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If PrintFormsSet.FindRows(New Structure("Print", True)).Count() > 0 Then
		
		CallbackDescription = New CallbackDescription("AfterFormationOfPrintedForms", ThisObject);
		PrintCommand = PrintManagementClient.CreatePrintCommand();
		ObjectPrintCommands = ObjectPrintCommands(PrintCommand);
		PrintManagementClient.RunPrintCommands(Objects.UnloadValues(), ObjectPrintCommands, CallbackDescription, , True);
		
	Else
		
		ClearMessages();
		MessageText = NStr("vi = 'Chọn ít nhất một hình thức in để in.';
							|ru = 'Выберите хотя бы одну печатную форму для печати.';
							|en = 'Select at least one print form for printing.'; fa = 'Select at least one print form for printing.';
							|it = 'Seleziona almeno un modulo di stampa per la stampa.';
							|pl = 'Wybierz co najmniej jeden formularz do druku.';
							|tr = 'Yazdırmak için en az bir yazdırma formu seç.'");
		CommonClientServer.MessageToUser(MessageText, , "PrintFormsSet");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintToPrinter(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	PrintList = New ValueList;
	For Each Template In PrintFormsSet Do
		If Template.Print Then
			PrintList.Add(Template.Name, Template.Presentation);
		EndIf;
	EndDo;
	
	If PrintFormsSet.FindRows(New Structure("Print", True)).Count() > 0 Then	
		PrintCommand = PrintManagementClient.CreatePrintCommand();
		ObjectPrintCommands = ObjectPrintCommands(PrintCommand);
		CallbackDescription = New CallbackDescription("AfterFormationOfPrintedForms", ThisObject);
		PrintManagementClient.RunPrintCommands(Objects.UnloadValues(), ObjectPrintCommands, CallbackDescription, True);
	Else
		ClearMessages();
		MessageText = NStr("vi = 'Chọn ít nhất một hình thức in để in.';
							|ru = 'Выберите хотя бы одну печатную форму для печати.';
							|en = 'Select at least one print form for printing.'; fa = 'Select at least one print form for printing.';
							|it = 'Seleziona almeno un modulo di stampa per la stampa.';
							|pl = 'Wybierz co najmniej jeden formularz do druku.';
							|tr = 'Yazdırmak için en az bir yazdırma formu seç.'");
		CommonClientServer.MessageToUser(MessageText, , "PrintFormsSet");
	EndIf;
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	For Each CurRow In PrintFormsSet Do
		CurRow.Print = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	For Each CurRow In PrintFormsSet Do
		CurRow.Print = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	CustomizeStandardSettingsServer();
	
EndProcedure

&AtClient
Procedure ShouldSaveSettings(Command)
	
	ShouldSaveSettingsClient();
	
EndProcedure

&AtClient
Procedure SaveCompanySettings(Command)
	
	ShouldSaveSettingsClient(True);
	
EndProcedure

&AtClient
Procedure SaveSettingsForThePartnerOrganization(Command)
	
	ShouldSaveSettingsClient(True, True);
	
EndProcedure

&AtClient
Procedure DeleteSettings(Command)
	
	DeleteSettingsServer();
	
	ShowUserNotification(
		NStr("vi = 'Đã xóa tùy chỉnh mẫu in';
			|ru = 'Настройки печати удалены';
			|en = 'Print settings are removed'; fa = 'Print settings are removed';
			|it = 'Impostazioni di stampa eliminate';
			|pl = 'Ustawienia drukowania zostały usunięte';
			|tr = 'Yazdırma ayarları silindi'"),
		,
		,
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure RequestConfirmationWhenPrintingASetOfDocumentsOnChange(Item)
	
	CommonServerCall.CommonSettingsStorageSave("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments", RequestConfirmationWhenPrintingASetOfDocuments);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSetCopies2.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrintFormsSet.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSetPresentation.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSetCopies2.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrintFormsSet.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Procedure GenerateOptionsForSavingSettings()
	
	TextObjectType = NStr("vi = 'Lưu tùy chỉnh đối với chứng từ ""%ObjectType%""';
							|ru = 'Сохранить настройки для документов ""%ObjectType%""';
							|en = 'Save settings for documents ""%ObjectType%""'; fa = 'Save settings for documents ""%ObjectType%""';
							|it = 'Salvare le impostazioni per i documenti ""%ObjectType%""';
							|pl = 'Zapisz ustawienia dla dokumentów ""%ObjectType%""';
							|tr = '""%ObjectType%"" belgeleri için ayarları kaydet'");
	TextObjectType = StrReplace(TextObjectType, "%ObjectType%", Metadata.FindByFullName(ObjectType).Presentation());
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ShouldSaveSettings", "Title", TextObjectType);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ShouldSaveSettings", "Visible", UserRightsCached.SaveObjectPrintSettingsByDefault());
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "SaveCompanySettings", "Visible", False);
	TMCommonUseClientServer.SetFormItemProperty(Items, "SaveSettingsForThePartnerOrganization", "Visible", False);
	
	If ThereIsACompany And UserRightsCached.SaveObjectPrintSettingsByDefault() Then
		TextObjectType = TextObjectType + " " + NStr("vi = 'theo doanh nghiệp ""%Organization%""';
													|ru = 'по организации ""%Organization%""';
													|en = 'for ""%Organization%"" company'; fa = 'for ""%Organization%"" company';
													|it = 'per azienda ""%Organization%""';
													|pl = 'wg firmy ""%Organization%""';
													|tr = '""%Organization%"" iş yerlerine göre'");
		TextObjectType = StrReplace(TextObjectType, "%Organization%", Organization);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SaveCompanySettings", "Title", TextObjectType);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SaveCompanySettings", "Visible", True);
	EndIf;
	
	If ThereIsAPartner And UserRightsCached.AddEditObjectPrintSettings() And
	 (Not ThereIsACompany Or UserRightsCached.SaveObjectPrintSettingsByDefault()) Then
		TextObjectType = TextObjectType + " " + NStr("vi = 'theo bạn hàng ""%Partner%""';
													|ru = 'по партнеру ""%Partner%""';
													|en = 'by ""%Partner%"" partner'; fa = 'by ""%Partner%"" partner';
													|it = 'per partner ""%Partner%""';
													|pl = 'wg partnera ""%Partner%""';
													|tr = '""%Partner%"" iş ortağına göre'");
		TextObjectType = StrReplace(TextObjectType, "%Partner%", Partner);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SaveSettingsForThePartnerOrganization", "Title", TextObjectType);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SaveSettingsForThePartnerOrganization", "Visible", True);
	EndIf;

EndProcedure

&AtServer
Procedure UpdateDeleteSettingsCommand()
	
	If UseVariant > 0 Then
	
		TextObjectType = NStr("vi = 'Xóa bỏ tùy chỉnh đối với chứng từ ""%ObjectType%""';
								|ru = 'Удалить настройки для документов ""%ObjectType%""';
								|en = 'Delete settings for the ""%ObjectType%"" documents'; fa = 'Delete settings for the ""%ObjectType%"" documents';
								|it = 'Eliminare le impostazioni per i documenti ""%ObjectType%""';
								|pl = 'Usuń ustawienia dla dokumentów ""%ObjectType%""';
								|tr = '""%ObjectType%"" belgeleri için ayarları sil'");
		TextObjectType = StrReplace(TextObjectType, "%ObjectType%", Metadata.FindByFullName(ObjectType).Presentation());
		
		If UseVariant > 1 Then
			TextObjectType = TextObjectType + " " + NStr("vi = 'theo doanh nghiệp ""%Organization%""';
														|ru = 'по организации ""%Organization%""';
														|en = 'for ""%Organization%"" company'; fa = 'for ""%Organization%"" company';
														|it = 'per azienda ""%Organization%""';
														|pl = 'wg firmy ""%Organization%""';
														|tr = '""%Organization%"" iş yerlerine göre'");
			TextObjectType = StrReplace(TextObjectType, "%Organization%", Organization);
		EndIf;
		
		If UseVariant > 2 Then
			TextObjectType = TextObjectType + " " + NStr("vi = 'theo bạn hàng ""%Partner%""';
														|ru = 'по партнеру ""%Partner%""';
														|en = 'by ""%Partner%"" partner'; fa = 'by ""%Partner%"" partner';
														|it = 'per partner ""%Partner%""';
														|pl = 'wg partnera ""%Partner%""';
														|tr = '""%Partner%"" iş ortağına göre'");
			TextObjectType = StrReplace(TextObjectType, "%Partner%", Partner);
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "DeleteSettings", "Title", TextObjectType);
		
		If Users.IsFullUser() Or
			((UseVariant = 2 Or (UseVariant = 3 And UserRightsCached.AddEditObjectPrintSettings()))
				And UserRightsCached.SaveObjectPrintSettingsByDefault()) Then
			
			TMCommonUseClientServer.SetFormItemProperty(Items, "DeleteSettings", "Visible", True);
			
		EndIf;
		
	Else
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "DeleteSettings", "Visible", False);
		
	EndIf;

EndProcedure

&AtServer
Procedure UpdateUseCaseText()
	
	If UseVariant > 0 Then
		TextObjectType = NStr("vi = 'Áp dụng tùy chỉnh đối với chứng từ ""%ObjectType%""';
								|ru = 'Применяется настройка для документов ""%ObjectType%""';
								|en = 'The setting is applied to documents ""%ObjectType%""'; fa = 'The setting is applied to documents ""%ObjectType%""';
								|it = 'Vengono applicate le impostazioni per i documenti ""%ObjectType%""';
								|pl = 'Stosuje się ustawienie dla dokumentów ""%ObjectType%""';
								|tr = '""%ObjectType%"" belgeleri için ayarlar uygulanıyor'");
		TextObjectType = StrReplace(TextObjectType, "%ObjectType%", Metadata.FindByFullName(ObjectType).Presentation());
		
		If UseVariant = 2 Or UseVariant = 3 Then
			TextObjectType = TextObjectType + " " + NStr("vi = 'theo doanh nghiệp ""%Organization%""';
														|ru = 'по организации ""%Organization%""';
														|en = 'for ""%Organization%"" company'; fa = 'for ""%Organization%"" company';
														|it = 'per azienda ""%Organization%""';
														|pl = 'wg firmy ""%Organization%""';
														|tr = '""%Organization%"" iş yerlerine göre'");
			TextObjectType = StrReplace(TextObjectType, "%Organization%", Organization);
		EndIf;
		
		If UseVariant = 3 Then
			TextObjectType = TextObjectType + " " + NStr("vi = 'bởi khách hàng ""%Partner%""';
														|ru = 'по клиенту ""%Partner%""';
														|en = 'by the ""%Partner%"" customer'; fa = 'by the ""%Partner%"" customer';
														|it = 'per cliente ""%Partner%""';
														|pl = 'wg klienta ""%Partner%""';
														|tr = '""%Partner%"" müşterisine göre'");
			TextObjectType = StrReplace(TextObjectType, "%Partner%", Partner);
		EndIf;
	Else
		TextObjectType = NStr("vi = 'Áp dụng tùy chỉnh theo mặc định đối với chứng từ ""%ObjectType%""';
								|ru = 'Применяется настройка по умолчанию для документов ""%ObjectType%""';
								|en = 'The default setting is applied to documents ""%ObjectType%""'; fa = 'The default setting is applied to documents ""%ObjectType%""';
								|it = 'Viene applicata la impostazione default per i documenti ""%ObjectType%""';
								|pl = 'Stosuje się domyślne ustawienie dla dokumentów ""%ObjectType%""';
								|tr = '""%ObjectType%"" belgeleri için varsayılan ayar uygulanır'");
		TextObjectType = StrReplace(TextObjectType, "%ObjectType%", Metadata.FindByFullName(ObjectType).Presentation());
	EndIf;
	
	UsageOptionText = TextObjectType;
	
EndProcedure

&AtClient
Procedure ShouldSaveSettingsClient(RecordOrganization = False, RecordingPartner = False)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	RecordPrintSettings(RecordOrganization, RecordingPartner);
	
	ShowUserNotification(
		NStr("vi = 'Đã lưu tùy chỉnh mẫu in';
			|ru = 'Настройки печати сохранены';
			|en = 'Print settings are saved'; fa = 'Print settings are saved';
			|it = 'Impostazioni di stampa salvate';
			|pl = 'Ustawienia drukowania zostały zapisane';
			|tr = 'Yazdırma ayarları kaydedildi'"),
		,
		,
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure DeleteSettingsServer()
	
	If UseVariant = 1 Then
		InformationRegisters.ObjectPrintSettings.DeleteObjectPrintingSettings(ObjectType, Catalogs.Companies.EmptyRef(), Catalogs.Partners.EmptyRef());
	ElsIf UseVariant = 2 Then
		InformationRegisters.ObjectPrintSettings.DeleteObjectPrintingSettings(ObjectType, Organization, Catalogs.Partners.EmptyRef());
	ElsIf UseVariant = 3 Then
		InformationRegisters.ObjectPrintSettings.DeleteObjectPrintingSettings(ObjectType, Organization, Partner);
	EndIf;
	
	InformationRegisters.ObjectPrintSettings.PrintFormsSet(
		ObjectType,
		?(Objects.Count() = 1, Objects[0].Value, Undefined),
		UseVariant);
	
	UpdateDeleteSettingsCommand();
	UpdateUseCaseText();
	
EndProcedure

&AtServer
Procedure RecordPrintSettings(RecordOrganization = False, RecordingPartner = False)
	
	Modified = False;
	InformationRegisters.ObjectPrintSettings.RecordObjectPrintSettings(
		ObjectType,
		PrintFormsSet.Unload(),
		RecordOrganization,
		RecordingPartner,
		?(Objects.Count() = 1, Objects[0].Value, Undefined));
	
	InformationRegisters.ObjectPrintSettings.PrintFormsSet(
		ObjectType,
		?(Objects.Count() = 1, Objects[0].Value, Undefined),
		UseVariant);
	
	UpdateUseCaseText();
	UpdateDeleteSettingsCommand();
	
EndProcedure

&AtServer
Procedure CustomizeStandardSettingsServer()
	
	UseVariant = 0;
	PrintFormsSet.Clear();
	ObjectManager = Common.ObjectManagerByFullName(ObjectType);
	PrintFormsCollection = ObjectManager.PrintFormsSet();
	InformationRegisters.ObjectPrintSettings.AddExternalPrintFormsToSet(ObjectType, PrintFormsCollection);
	UpdateUseCaseText();
	
	For Each CurRow In PrintFormsCollection Do
		
		NewRow = PrintFormsSet.Add();
		FillPropertyValues(NewRow, CurRow);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "Close" Then
		ClosingInProgress = True;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure AfterFormationOfPrintedForms(Result, AdditionalParameters) Export
	
	If Result = True Then
		SaveParameters = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Function ObjectPrintCommands(PrintCommand)
	
	Result = New Array();
	
	ObjectPrintCommands = PrintManagement.ObjectPrintCommands(Objects[0].Value.Metadata());
	
	For Each ObjectPrintingCommands In ObjectPrintCommands Do
		If ObjectPrintingCommands.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" Then
			ExternalPrintFormsPrefix = "ExternalPrintForm.";
		Else
			ExternalPrintFormsPrefix = "";
		EndIf;
		
		Filter = New Structure("Name", ExternalPrintFormsPrefix + ObjectPrintingCommands.Id);
		FoundCommands = PrintFormsSet.FindRows(Filter);
		
		If FoundCommands.Count() And FoundCommands[0].Print Then
			KitIncludedCommand = CommonClientServer.CopyRecursive(PrintCommand);
			FillPropertyValues(KitIncludedCommand, ObjectPrintingCommands);
			
			If CommonClientServer.StructureProperty(ObjectPrintingCommands.AdditionalParameters, "PrintManager", "") <> "" Then
				KitIncludedCommand.PrintManager = ObjectPrintingCommands.AdditionalParameters.PrintManager;
			EndIf;
			
			If KitIncludedCommand.AdditionalParameters.Property("UseSynonymForKit") Then
				KitIncludedCommand.AdditionalParameters.UseSynonymForKit = True;
			EndIf;
			
			IdentificatorAsKit = New Array;
			For Cnt = 1 To FoundCommands[0].Copies2 Do
				IdentificatorAsKit.Add(KitIncludedCommand.Id);
			EndDo;
			KitIncludedCommand.Id = StrConcat(IdentificatorAsKit, ",");
			
			Result.Add(KitIncludedCommand);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
